library(RxODE)
#source(here("R", "directory-funs.R"))

# ---------------- precursor-pkpd -------------

# these models expect VL to be "dosed",
# PK may explicitly bolus at time zero, per initial condition
precursor_effector_pkpd_rxode <- RxODE({

  kel = Cl/V1
  k12 = Q/V1
  k21 = Q/V2
  g = 23
  aP = 1e-5 # remember to adjust this in the initial conditions
  
  Cc = centr/V1
  Bt0_adj = Bt0 * 1/(1+(Cc/(IC50 * rho))^h)
  
  d/dt(S)  = aS - dS*S - Bt0_adj*S*V
  
  d/dt(I)  = Bt0_adj*S*V - dI*I - k*E*I
  
  d/dt(P)  = aP + w * (1-f) * P * I/(1 + I/NP)  - dP*P
  
  d/dt(E)  = w * f * P * I/(1 + I/NP) - dE*E
  
  d/dt(V) = p*I - g*V - Bt0_adj*S*V
  
  d/dt(centr) = - (k12+kel)*centr + k21 * peri
  d/dt(peri) = k12*centr - k21*peri
  
})

precursor_effector_pkpd_model = list(
  model = precursor_effector_pkpd_rxode,
  init_setup = function(theta) {
    c(S = theta$aS/theta$dS,
      I = 0,
      P = 1e-5/theta$dP,
      E = 0,
      V = 0,
      centr = theta$initial_dose,
      peri = 0
    )
  }
)

# ---------------- holte-pkpd -------------

# these models expect VL to be "dosed",
# PK dosed in AMT
holte_pkpd_rxode <- RxODE({
  
  kel = Cl/V1
  k12 = Q/V1
  k21 = Q/V2
  g = 23

  Cc = centr/V1
  Bt0_adj = Bt0 * 1/(1+(Cc/(IC50 * rho))^h)
  
  d/dt(S)  = aS - dS*S - Bt0_adj*S*V
  
  d/dt(I)  = Bt0_adj*S*V - dI*I*I^n
  
  d/dt(V) = p*I - g*V - Bt0_adj*S*V
  
  d/dt(centr) = - (k12+kel)*centr + k21 * peri # mass-scale
  d/dt(peri) = k12*centr - k21*peri
  
})

holte_pkpd_model = list(
  model = holte_pkpd_rxode,
  init_setup = function(theta) {
    c(S = theta$aS/theta$dS,
      I = 0,
      V = 0,
      centr = theta$initial_dose,
      peri = 0
    )
  }
)



