library(RxODE)
#source(here("R", "directory-funs.R"))

# ---------------- holte -------------

holte_rxode <- RxODE({
  g = 23
  
  d/dt(S)  = aS - dS*S - Bt0*S*V	
  
  d/dt(P)  = Bt0*S*V - dI*P*P^n
  d/dt(V) = p*P - g*V - Bt0*S*V  
  
})

holte_model = list(
  model = holte_rxode,
  init_setup = function(theta) {
    c(S = theta$aS/theta$dS,
      V = 0.01/1e3,
      P = 23 * 0.01/1e3/(theta$p)
    )
  }
)

# ---------------- effector -------------

effector_rxode <- RxODE({
  g = 23
  aE = 1e-5	
  lam = 1e-4
  thL = 5.2e-4
  
  d/dt(S)  = aS - dS*S - Bt0*S*V
  
  d/dt(IP)  = tau * (1-lam) * Bt0*S*V - dI*IP - k*E*IP
  d/dt(IUP) = (1-tau)*(1-lam)*Bt0*S*V - dI*IUP - k*E*IUP
  d/dt(L) = lam*Bt0*S*V - thL*L
  
  d/dt(E)  = aE + w * (IP+IUP) * E/(E + E50) - dE*E
  
  d/dt(V) = p*IP - g*V - Bt0*S*V
  
})

effector_model = list(
  model = effector_rxode,
  init_setup = function(theta) {
    c(S = theta$aS/theta$dS,
      V = 0.01/1e3,
      IP = 23 * 0.01/1e3/(theta$p),
      IUP = 23 * 0.01/1e3/(theta$p) * (1-theta$tau) / theta$tau,
      L = 23 * 0.01/1e3/(theta$p) * 1e-4 / theta$tau / (1-1e-4),
      E = 1e-5/theta$dE
    )
  }
)

# ---------------- precursor effector -------------

precursor_effector_rxode <- RxODE({
  g = 23
  aP = 1e-5
  
  d/dt(S)  = aS - dS*S - Bt0*S*V
  
  d/dt(I)  = Bt0*S*V - dI*I - k*E*I
  
  d/dt(P)  = aP + w * (1-f) * P * I/(1 + I/NP)  - dP*P
  
  d/dt(E)  = w * f * P * I/(1 + I/NP) - dE*E
  
  d/dt(V) = p*I - g*V - Bt0*S*V
  
})

precursor_effector_model = list(
  model = precursor_effector_rxode,
  init_setup = function(theta) {
    c(S = theta$aS/theta$dS,
      V = 0.01/1e3,
      I = 23 * 0.01/1e3/(theta$p),
      P = 1e-5/theta$dP,
      E = 0
    )
  }
)



