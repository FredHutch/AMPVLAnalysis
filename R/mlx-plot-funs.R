
# fix output_name later with pkpd as needed, 
# dem_dat needs "holte_est" unless this function is made more generic
# this will automatically log "DV"
infection_time_spaghetti = function(mlx_project, dem_dat, output_name = "DV", 
                                    start_time = 0, final_time = 60, output_trans = identity){
  
  pred_fname = paste0(output_name, "_obsVsPred.txt")
  fit_fname = paste0(output_name, "_fits.txt")
  
  pts = read_csv(mlx_model_here(file.path(mlx_project, "ChartsData/ObservationsVsPredictions", pred_fname)),
                 col_types = cols()) %>%
    left_join(dem_dat, by = c("ID" = "pub_id")) %>%
    mutate(infection_days = time + holte_est)  %>%
    dplyr::filter(infection_days >= start_time & infection_days < final_time)
  
  fits = read_csv(mlx_model_here(file.path(mlx_project, "ChartsData/IndividualFits", fit_fname)),
           col_types = cols()) %>%
    left_join(dem_dat, by = c("ID" = "pub_id")) %>%
    mutate(infection_days = time + holte_est) %>%
    dplyr::filter(infection_days >= start_time & infection_days < final_time)
    
  if(output_name == "DV") {
    pts$output = output_trans(log10(pts[["DV"]]))
    fits$output = output_trans(log10(pmax(15, fits[["indivPredMode"]])))
  } else{
    pts$output = output_trans(pts[[output_name]])
    fits$output = output_trans(pmax(log10(15), fits[["indivPredMode"]]))
  }  
  
  ggplot(fits, aes(x = infection_days, y = output)) +
    scale_y_continuous(limits = c(1, 8.5), breaks = 1:8) +
    geom_line(aes(group = ID), alpha = 0.25) +
    geom_point(data = pts, aes(y = output), alpha = 0.1) 
  
}

.plot_indiv_subdir = function(mlx_sub_dir, outfile = NULL, cutoff = log10(20),
                          id_per_row = 5, id_per_col = 2, save_plot = T, print_plot = F){

  if(is.null(outfile)) outfile = paste0(basename(mlx_sub_dir), "_indiv_fits.pdf")

  fits = stack_indiv_fits(list_mlx_models(mlx_sub_dir)) %>%
    mutate(weeks = time/7)
  ipreds = stack_indiv_ests(list_mlx_models(mlx_sub_dir)) %>%
    mutate(weeks = time/7)

  id_sets = split(unique(ipreds$ID),
                  ceiling(seq_along(unique(ipreds$ID))/(id_per_row * id_per_col)))

  plots = map(id_sets, function(id_set){
    fits %>%
      dplyr::filter(ID %in% id_set) %>%
      ggplot(aes(x = time, y = log10(pmax(cutoff, indivPredMode)))) +
      geom_line(aes(colour = model)) +
      geom_point(data = dplyr::filter(ipreds, ID %in% id_set),
                 aes(y = log10(DV), shape = as.factor(censored != 0))
      ) +
      scale_shape_discrete("Below LLoQ") +
      facet_wrap( ~ ID, nrow = id_per_row, ncol = id_per_col)+
      labs(y = "log10 VL") +
      theme(legend.position = 'top')
  })

  if(save_plot){
    ggsave(here(file.path("figures", outfile)), gridExtra::marrangeGrob(plots, nrow=1, ncol=1))
  }
  if(print_plot){
    walk(1:length(id_sets), ~print(plots[[.]]))
  }

  invisible(plots)
}



