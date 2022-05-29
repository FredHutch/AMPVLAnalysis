# Bryan Mayer
# April 2022

#--------------------- mlx wrappers -----------

turn_on_all_re = function(){
  setIndividualParameterVariability(
    map_lgl(getIndividualParameterModel()$variability$id, ~(. = T))
  )
}

set_project_settings <- function(initial_estimates = FALSE, model_seed = 815) {
  
  setProjectSettings(seed = model_seed)
  setGeneralSettings(autochains = TRUE) # this is a default setting
  
  setPopulationParameterEstimationSettings(simulatedAnnealing = initial_estimates)
  
  scenario <- getScenario()
  
  scenario$tasks[["standardErrorEstimation"]] <- !initial_estimates
  scenario$tasks[["logLikelihoodEstimation"]] <- !initial_estimates
  
  scenario$plotList <- c(scenario$plotList, "predictiondistribution", "vpc")
  scenario$tasks[["logLikelihoodEstimation"]] <- !initial_estimates
  
  setScenario(scenario)
  
}

save_project <- function(project_name) {
  project_path <- mlx_model_here(project_name)
  saveProject(glue("{project_path}.mlxtran"))
  computeChartsData()
}


# ----------- setup for single outcome models -------------

new_project <- function(structural_model_path, data_file_path, variable_types) {

  newProject(
    data = list(
      dataFile = data_file_path,
      headerTypes = variable_types$type,
      observationTypes = "continuous"
    ),
    modelFile = structural_model_path
  )

  setPopulationParameterEstimationSettings(nbexploratoryiterations = 1000)
}

amp_recipe <- function(model_text_file, data_file, variable_types,
                       error_model = "constant", obs_dist = "lognormal",
                       ...) {

  structural_model_path <- structural_model_here(file = model_text_file)

  data_file_path <- mlx_data_here(file = data_file)

  new_project(structural_model_path, data_file_path, variable_types)

  set_project_settings(...)

  if("DV" %in% subset(log10vl_pool_types, type!="ignore")$var_name){
    setErrorModel(DV = error_model)
    setObservationDistribution(DV = obs_dist)
  } else{
    print("error model set to default")
    # getObservationmodel?
  }
}


# ----------- setup for PKPD models -------------

.new_pkpd_project <- function(structural_model_path, data_file_path, variable_types) {
  obs_types <- list(conc = "continuous", vl = "continuous")
  obs_mapping <- list("1" = "conc", "2" = "vl")
  newProject(
    data = list(
      dataFile = data_file_path,
      headerTypes = variable_types$type,
      observationTypes = obs_types,
      mapping = obs_mapping
    ),
    modelFile = structural_model_path
  )
  
  setPopulationParameterEstimationSettings(nbexploratoryiterations = 1000)
}

.pkpd_recipe <- function(model_text_file, data_file, variable_types,
                       ...) {

  structural_model_path <- structural_model_here(file = model_text_file)

  data_file_path <- mlx_data_here(file = data_file)

  new_pkpd_project(structural_model_path, data_file_path, variable_types)

  set_project_settings(...)

  setErrorModel(conc = "proportional", vl = "constant")
  setObservationDistribution(conc = "normal", vl = "logNormal")

}

