
# models are stored in models/rxode-models

create_theta = function(parm_tibble){
  parm_tibble %>%
    dplyr::select(parameter, value) %>%
    mutate(parameter = str_remove_all(parameter, "_pop")) %>%
    spread(parameter, value) 
}

prep_vl_model_parms = function(mlx_project, mode_parms = NULL){
  if(is.null(mode_parms))  {
    out_parms = get_pop_ests(mlx_project) %>%
      dplyr::filter(str_detect(parameter, "_pop")) %>%
      create_theta()
  } else{
    out_parms = mode_parms %>%
      select(contains("_mode")) %>%
      rename_with(~ str_replace(., "_mode", ""))
  }
  out_parms %>%
    mutate(Bt0 = 10^lBt0, p = 10 ^ lp)
}

run_vl_model = function(mtime, model_obj, mlx_project, theta = NULL){
  ev = eventTable(time.units = "days")
  ev$add.sampling(mtime)
  
  if(is.null(theta)) theta = prep_vl_model_parms(mlx_project)
  
  init = model_obj$init_setup(theta)
  
  as.data.frame(model_obj$model$solve(theta, event = ev, inits = init)) %>%
    mutate(
      Vout = V * 1000,
      log10V = log10(Vout)
    )
}

#' PKPD Model Simulator
#'
#' @param mtime simulation times
#' @param model_obj a list that contains an 'init_setup'() method and RXODE 'model' object
#' @param theta_pk pk parameters for model_obj ODEs, expects V1 scaling
#' @param theta_vl vl parameters for model_obj ODEs, not strictly required (could put parameters in pk or pd)
#' @param theta_pd pd parameters for model_obj, assumes IC50 input for model_obj so expects IC80 and hill slope
#' @param initial_pk_dose for simple pk, bolus dosing at time 0
#' @param infection_time initial time for VL kinetics, default is high for no infection
#' @param infusion_pk_dosing expects NONMEM-like format data.frame(DOSENO, TIME, AMT, RATE) of numeric types
#'
#' @return
#' @export
#'
#' @examples
run_pkpd_models = function(mtime, model_obj, theta_pk, theta_vl, theta_pd, initial_pk_dose = 0,
                           infection_time = 1e4, infusion_pk_dosing = NULL){
  
  theta_pk$initial_dose = initial_pk_dose
  theta_pd$IC50 = theta_pd$IC80 * 4 ^(-1/theta_pd$h)
  stopifnot(theta_pd$IC50 < theta_pd$IC80)
  
  # bind_cols will cause a failure (and generate a message) with redundant naming
  theta = bind_cols(theta_pk, theta_vl, theta_pd)
  init = model_obj$init_setup(theta)
  
  stopifnot(infection_time >= min(mtime))
  
  ev = eventTable(time.units = "days") %>%
    add.sampling(mtime) %>%
    add.dosing(
      start.time = infection_time, dose = 23 * 0.01/1e3/(theta$p), cmt = "I",
      nbr.doses = 1, dosing.interval = 0,
    ) %>%
    add.dosing(
      start.time = infection_time, dose = 0.01/1e3, cmt = "V",
      nbr.doses = 1, dosing.interval = 0,
    ) 
  
  if(!is.null(infusion_pk_dosing)){
    if(theta$initial_dose != 0) warning("initial_pk_dose set to 0 by default when pk dosing used")
    theta$initial_dose = 0
    
    for(i in infusion_pk_dosing$DOSENO){
      dose_iteration = dplyr::filter(infusion_pk_dosing, DOSENO == i)
      ev = ev %>%
        add.dosing(
          dose = dose_iteration$AMT,
          rate = dose_iteration$RATE,
          nbr.doses = 1,
          cmt = "centr",
          start.time = dose_iteration$TIME
        )
    }
    
  }
  
  as.data.frame(model_obj$model$solve(theta, event = ev, inits = init)) %>%
    mutate(
      centr_conc = centr/theta$V1,
      IC50 = theta_pd$IC50,
      Vout = V * 1000,
      log10V = log10(Vout)
    )
  
}
