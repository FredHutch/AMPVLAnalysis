
# ---------- PK ----------------

fix_pk_parms_cc = function(){
  # from Lily
  
  addContinuousTransformedCovariate(tWT = 'log(weight/67.3)') # 67.3 comes from the original data
  setCovariateModel(Cl = c(study = T, tWT = T), V2 = c(study = T))
  
  setPopulationParameterInformation(
    Cl_pop = list(initialValue = 0.575, method = "FIXED"),
    beta_Cl_tWT = list(initialValue = 0.331, method = "FIXED"),
    beta_Cl_study_1 = list(initialValue = 0.111, method = "FIXED"),
    V1_pop = list(initialValue = 3.532, method = "FIXED"),
    Q_pop = list(initialValue = 0.676, method = "FIXED"),
    V2_pop = list(initialValue = 4.749, method = "FIXED"),
    beta_V2_study_1 = list(initialValue = 0.165, method = "FIXED"),
    omega_Cl = list(initialValue = 0.172, method = "FIXED"),
    omega_V1 = list(initialValue = 0.248, method = "FIXED"),
    omega_Q = list(initialValue = 0.064, method = "FIXED"),
    omega_V2 = list(initialValue = 0.145, method = "FIXED")
  )
  if("b1" %in% getPopulationParameterInformation()$name){ # this for PKPD
    setPopulationParameterInformation(b1 = list(initialValue = 0.188, method = "FIXED"))
  } else setPopulationParameterInformation(b = list(initialValue = 0.188, method = "FIXED"))
  
}


# ----------- VL ---------------

.fix_timing_parms = function(est = "FIXED", dose = F, tcl = F){
  if(!exists("timing_parms")) stop("RV217 timing not loaded: read_csv(mlx_data_here('rsif-timing-parms.csv')")

  setIndividualParameterDistribution(lBt0 = "normal", lp = "normal")
  if(dose) setIndividualParameterVariability(aS = F) else{
    setIndividualParameterVariability(V0 = F, aS = F)
    setPopulationParameterInformation(V0_pop = list(initialValue = timing_parms$V0_pop, method = "FIXED"))
  }
  setPopulationParameterInformation(
    aS_pop = list(initialValue = timing_parms$aS_pop, method = est),
    dS_pop = list(initialValue = timing_parms$dS_pop, method = est),
    lBt0_pop = list(initialValue = timing_parms$lBt0_pop, method = est),
    lp_pop = list(initialValue = timing_parms$lp_pop, method = est),
    dI_pop = list(initialValue = timing_parms$dI_pop, method = est),
    n_pop = list(initialValue = timing_parms$n_pop, method = est)
  )
  if(tcl){
    setIndividualParameterDistribution(n = "normal")
    setIndividualParameterVariability(n = F)
    setPopulationParameterInformation(n_pop = list(initialValue = 0, method = "FIXED"))
  }
}

.setup_tcl_parms = function(initial_vals, est = "MLE"){

  setIndividualParameterDistribution(lBt0 = "normal", lp = "normal")
  setPopulationParameterInformation(
    aS_pop = list(initialValue = initial_vals$aS_pop, method = est),
    dS_pop = list(initialValue = initial_vals$dS_pop, method = est),
    lBt0_pop = list(initialValue = initial_vals$lBt0_pop, method = est),
    lp_pop = list(initialValue = initial_vals$lp_pop, method = est),
    dI_pop = list(initialValue = initial_vals$dI_pop, method = est)
  )

}


.setup_effector_parms = function(initial_vals, est = "MLE", est_tau = "FIXED"){

  setPopulationParameterInformation(
    tau_pop = list(initialValue = initial_vals$tau_pop, method = est_tau)
  )
  setIndividualParameterVariability(k = F, tau = F)
  setIndividualParameterDistribution(lBt0 = "normal", lp = "normal", tau = "logitNormal")
  setIndividualLogitLimits(tau = c(0, 1))

  setPopulationParameterInformation(
    aS_pop = list(initialValue = initial_vals$aS_pop, method = est),
    dS_pop = list(initialValue = initial_vals$dS_pop, method = est),
    lBt0_pop = list(initialValue = initial_vals$lBt0_pop, method = est),
    dI_pop = list(initialValue = initial_vals$lBt0_pop, method = est),
    lp_pop = list(initialValue = initial_vals$lp_pop, method = est),
    k_pop = list(initialValue = 1, method = "FIXED"),
    w_pop = list(initialValue = initial_vals$w_pop, method = est),
    dE_pop = list(initialValue = initial_vals$dE_pop, method = est),
    E50_pop = list(initialValue = initial_vals$E50_pop, method = est)
    )

}

.fix_vl_error = function(input_parms){

  setPopulationParameterInformation(
    omega_dI = list(initialValue = input_parms$omega_dI, method = "FIXED"),
    omega_dS = list(initialValue = input_parms$omega_dS, method = "FIXED"),
    omega_lBt0 = list(initialValue = input_parms$omega_lBt0, method = "FIXED"),
    omega_lp = list(initialValue = input_parms$omega_lp, method = "FIXED")

  )

  if("a2" %in% getPopulationParameterInformation()$name){
    setPopulationParameterInformation(a2 = list(initialValue = input_parms$a, method = "FIXED"))
  } else setPopulationParameterInformation(a = list(initialValue = input_parms$a, method = "FIXED"))

  if("omega_n" %in% getPopulationParameterInformation()$name){
    setPopulationParameterInformation(
      omega_n = list(initialValue = input_parms$omega_n, method = "FIXED")
    )
  }

}

.fix_vl_parms = function(input_parms, est = "FIXED", dose = F, tcl = F, fix_error = F){

  setIndividualParameterDistribution(lBt0 = "normal", lp = "normal")
  if(dose) setIndividualParameterVariability(aS = F) else{
    setIndividualParameterVariability(V0 = F, aS = F)
    setPopulationParameterInformation(V0_pop = list(initialValue = input_parms$V0_pop, method = "FIXED"))
  }
  setPopulationParameterInformation(
    aS_pop = list(initialValue = input_parms$aS_pop, method = est),
    dS_pop = list(initialValue = input_parms$dS_pop, method = est),
    lBt0_pop = list(initialValue = input_parms$lBt0_pop, method = est),
    lp_pop = list(initialValue = input_parms$lp_pop, method = est),
    dI_pop = list(initialValue = input_parms$dI_pop, method = est)
  )
  if("n_pop" %in% getPopulationParameterInformation()$name){
    if(tcl){
      setIndividualParameterDistribution(n = "normal")
      setIndividualParameterVariability(n = F)
      setPopulationParameterInformation(n_pop = list(initialValue = 0, method = "FIXED"))
    } else setPopulationParameterInformation(n_pop = list(initialValue = input_parms$n_pop, method = est))
  }

  if(fix_error) fix_vl_error(input_parms)
  getPopulationParameterInformation()
}


