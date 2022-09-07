calc_max_upslope = function(log10V, time, time_range = c(3, 21)){
  mod_data = data.frame(y = log10V, x = time)
  
  betas = map_dbl(time_range[1]:time_range[2], function(i){
    mod = lm(y ~ x, data = subset(mod_data, time <= i))
    coef(mod)[['x']]
  })
  
  max(betas)
  
}

summarize_sim_holte_vl = function(vl_sims_dat, 
                                  vl_parms,
                                  setpt_end = 90,
                                  auc_end = 90, 
                                  max_uplope_time = c(3, 21)){
  vl_sims_dat %>%
    group_by(pub_id) %>%
    summarize(
      model_log10peak = max(log10V),
      model_peak_day = round(time[which.max(log10V)]),
      model_setpt = mean(log10V[time>= setpt_end & time <= setpt_end+10]),
      log10_auc_3mo = log10(
        tail(
          pkr::AUC(time[time <= auc_end], 10^log10V[time <= auc_end], down = "Log")[,1], 
          1)/auc_end
      ),
      geo_auc_3mo = tail(pkr::AUC(time[time <= auc_end], log10V[time <= auc_end])[,1], 1)/auc_end,
      #geo_auc_3mo_check = pracma::trapz(time[time <= 90], log10V[time <= 90]),
      max_upslope = calc_max_upslope(log10V, time, time_range = max_uplope_time),
      .groups = "drop"
    )  %>%
    left_join(vl_parms, by = "pub_id") %>%
    mutate(
      upslope_r0 = 1+max_upslope/dI_mode,
      unadjusted_r0 = 10^lBt0_mode * 10^lp_mode * aS_mode / (dS_mode * dI_mode * 23)
    )
  
  
}

