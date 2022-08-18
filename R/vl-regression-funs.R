
#------------------- lm-wraps ------------------------------

.get_lm_contrasts = function(lm_obj, lm_trt_var){
  contrast_obj = emmeans(lm_obj, as.formula(paste("pairwise ~", lm_trt_var)), 
                         adjust = "none", parens = NULL)
  
  constrast_ci = confint(contrast_obj)$contrasts %>%
    as_tibble() %>%
    select(contrast, cil =  lower.CL,  ciu = upper.CL) 
  
  contrast_obj$contrasts %>%
    as_tibble() %>%
    rename(est = estimate) %>%
    left_join(constrast_ci, by = "contrast") %>%
    mutate(model = 'lm')
}

run_vl_lm = function(mdata, formula, lm_trt_var){
  
  mod_fit = lm(formula, data = mdata)
  mm = emmeans(mod_fit, as.formula(paste("~", lm_trt_var))) %>%
    as_tibble() %>%
    rename(est = emmean,  cil =  lower.CL,  ciu = upper.CL) %>%
    mutate(model = 'lm')
  
  contrast = .get_lm_contrasts(mod_fit, lm_trt_var)
  
  out_list = list(mod_fit, mm, contrast)
  names(out_list) = c("lm_mod", "mm", "contrast")
  out_list
}

#------------------- drtmle-wraps ------------------------------

.pairwise_contrast_wrap = function(n, loc1, loc2){
  x = rep(0, n)
  x[loc1] = 1
  x[loc2] = -1
  x
}

get_drtmle_contrasts = function(drtmle_obj){
  n_grps = length(drtmle_obj$drtmle$est)
  tibble(grps = combn(1:n_grps, 2, paste, collapse = '_')) %>%
    separate(grps, into = c("grp1", "grp2"), sep = "_", convert = T) %>%
    mutate(
      contrast_res = map2(grp1, grp2, ~as_tibble(
        ci(drtmle_obj, contrast = .pairwise_contrast_wrap(n_grps, .x, .y))$drtmle, 
        rownames = "contrast_raw")),
      p.value =  map2_dbl(grp1, grp2, ~wald_test(drtmle_obj, 
                                                 contrast = .pairwise_contrast_wrap(n_grps, .x, .y),
                                                 est = "drtmle")$drtmle[2]
      )
    ) %>%
    ungroup() %>%
    unnest(cols = contrast_res)
}


#' Runs drtmle assuming log10vl as outcome, region/protocol as covariate
#'
#' @param mdata input model data
#' @param A_var the treatment variable (must be numeric per drtmle)
#' @param trt_map a data.frame or tibble (for merging) linking numeric A_var to actual labels
#' @param ci_method methods for drtmle mm confidence intervals
#' @param inference_method methods for drtmle inference (fixed to drtmle currently)
#' @param run_lm flag, if T AND trt_map supplied, will run simple lm using actual label variable
#' and will stack on mm and constrasts. trt variable name MUST = names(trt_map)[1]
#' @return a list: the drtmle obj, a mm tibble, a contrast tibble, the lm obj if run
run_vl_drtmle_glm = function(mdata, A_var,
                             trt_map = NULL,
                             ci_method = c( "tmle", "drtmle"),
                             inference_method = "drtmle",
                             run_lm = F
){
  
  outcome = mdata$log10vl
  trt_groups = mdata[[A_var]]
  
  # South America/704  is biggest category
  cov = select(mdata, isSA703, isNSA703, isSwiss704) %>% 
    mutate(across(.fns = as.numeric))
  
  # TO DO; write a safely version and save the warnings
  suppressWarnings({
    drtmle_fit = drtmle(Y = outcome, A = trt_groups, W = cov,
                        stratify = FALSE,
                        glm_Q = "A + isSA703 + isNSA703 + isSwiss704",
                        glm_g = "isSA703 + isNSA703 + isSwiss704",
                        glm_Qr = "gn",
                        glm_gr = "Qn",
                        family = gaussian(), returnModels = F)
  })
  
  drtmle_mm_ci = ci(drtmle_fit, est = ci_method)
  drtmle_mm = map2_df(drtmle_mm_ci, names(drtmle_mm_ci),
                      ~mutate(as_tibble(.x, rownames = A_var), model = .y))
  
  drtmle_contrast = mutate(get_drtmle_contrasts(drtmle_fit), model = "drtmle")
  
  if(!is.null(trt_map)){
    drtmle_mm[[A_var]] = as.numeric(drtmle_mm[[A_var]])
    drtmle_mm = left_join(drtmle_mm, trt_map, by = A_var)
    
    drtmle_contrast = left_join(drtmle_contrast, trt_map, by = c("grp1" = A_var)) %>% 
      left_join(trt_map, by = c("grp2" = A_var), suffix = c("_grp1", "_grp2")) %>%
      unite("contrast", paste0(names(trt_map)[1], "_grp1"), paste0(names(trt_map)[1], "_grp2"), 
            sep = " - ")
    
    if(run_lm){
      lm_trt_var = names(trt_map)[1]
      lm_formula = as.formula(paste("log10vl ~ isSA703 + isNSA703 + isSwiss704 +", lm_trt_var))
      lm_output = run_vl_lm(mdata = mdata,
                            formula = lm_formula, 
                            lm_trt_var = lm_trt_var)
      drtmle_mm = bind_rows(drtmle_mm, lm_output[['mm']])
      drtmle_contrast = bind_rows(drtmle_contrast, lm_output[['contrast']])
    }
    
    drtmle_mm$trt_var = drtmle_mm[[names(trt_map)[1]]] # generic across models
  }
  
  if(exists('lm_output')){
    out_list = list(drtmle_fit, lm_output[['lm_mod']], drtmle_mm, drtmle_contrast)
    names(out_list) = c("fit", "lm_mod", "mm", "contrast")
  } else{
    out_list = list(drtmle_fit, drtmle_mm, drtmle_contrast)
    names(out_list) = c("fit", "mm", "contrast")
  }
  return(out_list)
  
}

#' Runs lm for average viral load, allows incorporation of infusions after first positive. log10vl as outcome, region/protocol as covariate
#'
#' @param mdata input model data
#' @param trt_map a data.frame or tibble (for merging) that has the trt covariate in the first position
#' @return a list: an mm tibble, a contrast tibble, the lm obj if run
run_adj_vl_lm = function(mdata, trt_map){
  
  lm_trt_var = names(trt_map)[1]
  lm_formula = as.formula(paste("log10vl ~ isSA703 + isNSA703 + isSwiss704 + post_fp_infusion_mod +", lm_trt_var))
  lm_output = run_vl_lm(mdata = mdata,
                        formula = lm_formula, 
                        lm_trt_var = lm_trt_var)
  
  lm_output[['mm']]$trt_var = lm_output[['mm']][[names(trt_map)[1]]]
      
  out_list = list(lm_output[['lm_mod']], lm_output[['mm']], lm_output[['contrast']])
  
  
  names(out_list) = c("fit", "mm", "contrast")

  return(out_list)
  
}


