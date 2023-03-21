AMP HIV Viral Load Modeling
============================

The general goal of these scripts is to fit the models and save key results datasets for further analysis.

### Analysis order

The model fitting procedure is as follows:
- 01\) fit-vl-model-holte -- Holte models naively fit without VRC01 sensitivity adjustments
  - This script just fits all of the potential unadjusted models.
  - Uses RV217 Holte model fits for main parameters (Reeves et al. RSIF 2021)
  - Models re-fitting correlation and/or variance (omega) parameters
  - Models fit to full AMP cohort
  - Models trained to placebo, then used to draw VRC01 participant parameters
  - MLX model output stored in `/models/VL/`
- 02\) analysis-vl-model-holte 
  - Analyzes the unadjusted models results
  - Selects final model: refitting correlations in placebo population
  - **Saves key output for downstream analysis (creating PKPD datasets and fitting models)**
    - `unadjusted_model_vl_summary.csv` - individual model summary and metrics
    - `unadjusted_model_vl_popparms.csv` - final unadjusted population parameters
- 03\) placebo-pkpd-model
  - Start with final model from 2)
  - Viral parameters are adjusted by IC80 to determine indirect effects
    - model applied to VRC01 group in here
  - Saves final pop parameters: `adjusted_placebo_vl_popparms.csv`
  - Save infection times for vrc01: `adjusted_vrc01_parms.csv`
  - MLX model output stored in `/models/VL-adjusted-placebo/`
- 04\) vrc01-pkpd-model
  - Use basis model from 2) (no indirect effects) and final model from 3) (indirect effects)
  - Model with PKPD (VRCR01 direct) effects on beta parameter using potency reduction (w/ and w/o omega)
  - No results datasets saved from here directly.
  - MLX model output stored in `/models/PKPD/`
- 05\) amp-model-analysis
  - Simulate individual VL from key models to compare trajectories
  - Generate the final AIC supplementary tables describing model building
  - Save vl summary with all key endpoints for statistical analysis
    - `final_vl_summary.csv`
  - Save final pop pkpd parameters:
    - `final_model_popparms.csv`
- 06\) amp-sim-analysis
  - This generates key manuscripts figures
  - Individual simulations with different VRC01 settings
  - Population-level simulations to illustrate dose-response, direct/indirect effects
  - Simulations of future regimens
  - Save individual trajectories
     - `amp-individual-placebo-sims.csv`
     - `amp-individual-vrc01-sims.csv`
 
### VL models

All models use a form of the Holte Model stored in `/models/structural-model/`
 - Holte_Model.txt -- VL model with infection time parameters
 - 2_Holte_Model.txt --  Holte_Model with log10VL as the outcome
 - PKPD_Holte.txt -- VL Model with PKPD, PK parameters are fixed regressors, infection time is "dosed"
 
TBD: RxODE models for simulations

