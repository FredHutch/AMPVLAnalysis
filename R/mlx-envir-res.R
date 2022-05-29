
active_mlx_dir = function() {
  if(!dir.exists(file.path( getProjectSettings()$directory, "ChartsData"))) computeChartsData()
  getProjectSettings()$directory
}

dump_indiv_plots = function(file = "ipreds.pdf", id_per_row = 5, id_per_col = 2, 
                            outcome_name = "DV"){
  ipreds = active_ipreds(outcome_name = outcome_name)
  ipreds$obs_data = ipreds[[outcome_name]]
  fits = active_fits(outcome_name = outcome_name)
  cutoff = min(ipreds$obs_data)
  ylimits = log10(c(cutoff, max(c(fits$indivPredMode, ipreds$obs_data))))
  id_sets = split(unique(ipreds$ID),
                  ceiling(seq_along(unique(ipreds$ID))/(id_per_row * id_per_col)))
  plots = map(id_sets, function(id_set){
    fits %>%
      dplyr::filter(ID %in% id_set) %>%
      ggplot(aes(x = time, y = log10(pmax(cutoff, indivPredMode)))) +
      geom_line() +
      geom_point(data = dplyr::filter(ipreds, ID %in% id_set),
        aes(y = log10(obs_data), colour = censored!=0)
        ) +
      scale_x_continuous("Days post first positive", limits = c(-50, NA)) +
      scale_y_continuous(limits = c(ylimits[1], ylimits[2])) +
      scale_color_manual("Below LLoQ", breaks = c(F, T), values = c("black", "red")) +
      facet_wrap( ~ ID, nrow = id_per_row, ncol = id_per_col)
  })

  ggsave(here(file), gridExtra::marrangeGrob(plots, nrow=1, ncol=1))

}

quick_spaghetti = function(dem_dat, start_time = 0, final_time = 60, outcome_name = "DV", plot_obs = T, plot_trans = log10, cutoff = 15){
  pts = active_ipreds(outcome_name = outcome_name) %>%
    left_join(dem_dat, by = c("ID" = "pub_id")) %>%
    mutate(infection_days = time + holte_est)  %>%
    dplyr::filter(infection_days >= start_time & infection_days < final_time)
  
  pl = active_fits(outcome_name = outcome_name) %>%
    left_join(dem_dat, by = c("ID" = "pub_id")) %>%
    mutate(infection_days = time + holte_est) %>%
    dplyr::filter(infection_days >= start_time & infection_days < final_time) %>%
    ggplot(aes(x = infection_days, y = plot_trans(pmax(cutoff, indivPredMode)))) +
    scale_y_continuous(limits = c(1, 8.5), breaks = 1:8) +
    geom_line(aes(group = ID), alpha = 0.25) 
  if (plot_obs) pl = pl + geom_point(data = pts, aes(y = plot_trans(DV)), alpha = 0.1) 
  pl
}

active_ipreds = function(outcome_name = "DV"){
  read_csv(file.path(active_mlx_dir(),
                     paste0("ChartsData/ObservationsVsPredictions/", outcome_name,"_obsVsPred.txt")),
           col_types = cols())

}

active_fits = function(outcome_name = "DV"){
  read_csv(file.path(active_mlx_dir(),
                     paste0("ChartsData/IndividualFits/", outcome_name,"_fits.txt")),
           col_types = cols())
}

get_pop_parms <- function(project_name = NULL){

  estimates <- getEstimatedPopulationParameters() %>%
    data.frame() %>%
    rownames_to_column("parameter") %>%
    set_names("parameter", "estimate")

  if(is.null(getEstimatedStandardErrors())) return(estimates)
  if(!is.null(getEstimatedLogLikelihood())) {
    log_lik = getEstimatedLogLikelihood()$importanceSampling %>%
      as_tibble() %>%
      gather() %>%
      rename(parameter = key, estimate = value)
  } else log_lik = NULL

  standard_errors <- getEstimatedStandardErrors()$stochasticApproximation %>%
    dplyr::select(-rse) %>%
    mutate(se = as.numeric(se))

  full_join(estimates, standard_errors, by = "parameter") %>%
    mutate(rse = se/estimate * 100) %>%
    bind_rows(log_lik)
}


active_indiv_parms = function(type = "_mode"){
  read_csv(file.path(active_mlx_dir(),
                     paste0("/IndividualParameters/estimatedIndividualParameters.txt")),
           col_types = cols()) %>%
    dplyr::select(id, contains(type)) %>%
    rename_with(~str_remove(., "_mode"))
}
