
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

run_pkpd_models = function(mtime, model_obj, theta_pk, theta_vl, theta_pd, initial_pk_dose = 0,
                           infection_time = 1e4, pk_dosing = NULL){
  
  theta_pk$initial_dose = initial_pk_dose
  theta_pd$IC50 = theta_pd$IC80 * 4 ^(-1/theta_pd$h)
  stopifnot(theta_pd$IC50 < theta_pd$IC80)
  
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
  
  as.data.frame(model_obj$model$solve(theta, event = ev, inits = init)) %>%
    mutate(
      Vout = V * 1000,
      log10V = log10(Vout)
    )
  
}
