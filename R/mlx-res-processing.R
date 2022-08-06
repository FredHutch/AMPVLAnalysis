# ----------- get functions for output data from mlx ----------

get_model_ests = function(project_name){
  pop_parm_res = get_pop_ests(project_name)

  loglik_res  = read_csv(here(mlx_model_here(project_name), "LogLikelihood", "logLikelihood.txt"),
                         col_types = cols()) %>%
    rename(
      parameter = criteria,
      value = importanceSampling
    )
  bind_rows(pop_parm_res, loglik_res)
}


get_pop_ests <- function(project_name){
    read_csv(here(mlx_model_here(project_name), "populationParameters.txt"),
             col_types = cols())
}

get_indiv_preds = function(project_name, outcome_name = "DV"){
  read_csv(file.path(mlx_model_here(project_name),
                     paste0("ChartsData/ObservationsVsPredictions/", outcome_name,"_obsVsPred.txt")),
           col_types = cols())
}

get_indiv_fits = function(project_name, outcome_name = "DV"){
  read_csv(file.path(mlx_model_here(project_name),
                     paste0("ChartsData/IndividualFits/", outcome_name,"_fits.txt")),
           col_types = cols())
}

get_indiv_parms = function(project_name){
  read_csv(file.path(mlx_model_here(project_name),
                     "IndividualParameters/estimatedIndividualParameters.txt"),
           col_types = cols()) %>%
    dplyr::select(id, contains("_")) # this handles issues with covariate typing
}

get_etas = function(project_name){
  read_csv(file.path(mlx_model_here(project_name),
                     "/IndividualParameters/estimatedRandomEffects.txt"),
           col_types = cols())
}

# ---------- wrappers for stacking data, works for single models too --------

stack_model_ests = function(project_names, project_labels = NULL){
  stopifnot(is.null(project_labels) | length(project_names) == length(project_labels))
  if(is.null(project_labels)) project_labels = basename(project_names)
  map2_df(project_names, project_labels, ~mutate(get_model_ests(.x), model = .y))
}

stack_indiv_ests = function(project_names, project_labels = NULL){
  stopifnot(is.null(project_labels) | length(project_names) == length(project_labels))
  if(is.null(project_labels)) project_labels = basename(project_names)
  map2_df(project_names, project_labels, ~mutate(get_indiv_preds(.x), model = .y))
}

stack_indiv_fits  = function(project_names, project_labels = NULL){
  stopifnot(is.null(project_labels) | length(project_names) == length(project_labels))
  if(is.null(project_labels)) project_labels = basename(project_names)
  map2_df(project_names, project_labels, ~mutate(get_indiv_fits(.x), model = .y))
}

stack_indiv_parms = function(project_names, project_labels = NULL){
  stopifnot(is.null(project_labels) | length(project_names) == length(project_labels))
  if(is.null(project_labels)) project_labels = basename(project_names)
  map2_df(project_names, project_labels, ~mutate(get_indiv_parms(.x), model = .y))
}

stack_etas = function(project_names, project_labels = NULL){
  stopifnot(is.null(project_labels) | length(project_names) == length(project_labels))
  if(is.null(project_labels)) project_labels = basename(project_names)
  map2_df(project_names, project_labels, ~mutate(get_etas(.x), model = .y))
}


.get_poppred_plots = function(project_name){
  pred_sim_fpath = file.path(project_name, "ChartsData", "PredictionDistribution", "DV_percentiles.txt")

  read_csv(here(cvd815_mlx_here(pred_sim_fpath)),
           col_types = cols())
}


.calc_shrinkage = function(project_name){

  # https://monolix.lixoft.com/faq/understanding-shrinkage-circumvent/

  # 1 - var(eta)/omega^2
  # nm = 1 - sqrt(1 - mlx)

  omegas = get_pop_parms(project_name) %>%
    dplyr::filter(str_detect(parameter, "omega")) %>%
    mutate(
      parameter = paste0(str_replace(parameter, "omega_", ""), "_pop"),
      omega_sq = value^2
    ) %>%
    select(parameter, omega_sq)

  #if no omegas, return empty tibble
  if(nrow(omegas) == 0) return(
    purrr::map_dfc(c("parameter", "shrinkage_pct_mode"), setNames, object = list(logical()))
  )

  read_csv(
    here(
      cvd815_mlx_here(project_name),
      "IndividualParameters/estimatedRandomEffects.txt"
    ),
    col_types = cols()
  ) %>%
    select(contains("mode")) %>%
    summarize_all(var) %>%
    gather(key = parameter, value = value) %>%
    dplyr::filter(value != 0) %>%
    mutate(parameter = str_replace(str_remove(parameter, "eta_"), "_mode", "_pop")) %>%
    left_join(omegas, by = "parameter") %>%
    mutate(
      shrinkage_pct_mode = 100 * (1 - value/omega_sq),
      shrinkage_pct_mode_nonmem = 100 - 100*sqrt(1 - shrinkage_pct_mode/100)
      ) %>%
    dplyr::select(parameter, shrinkage_pct_mode, shrinkage_pct_mode_nonmem)
}

# ----------- individual-level results ----------

.get_ind_pred = function(project_name){
  read_csv(here(cvd815_mlx_here(project_name), "predictions.txt"),
           col_types = cols())
}

.get_ind_parms = function(project_name, est_method = "_mode"){
  read_csv(here(cvd815_mlx_here(project_name),
                "IndividualParameters/estimatedIndividualParameters.txt"),
           col_types = cols()) %>%
    dplyr::select(id, contains(est_method)) %>%
    rename_at(vars(contains(est_method)), str_remove, pattern = est_method)
}


# ------------- simulx results processing functions ---------

.read_simulx_pop_pred = function(model_name){
  read_csv(file.path(cvd815_simulx_here(model_name), "pop-pred-intervals.csv"),
           col_types = cols())
}
