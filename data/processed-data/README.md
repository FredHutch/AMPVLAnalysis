Processed analysis data
=======================

Data processing essentially has two steps (more details below):

* 1. Cleaning the raw data from source and summary datasets
* 2. Producing analysis datasets 

## 0. Datasets (listed alphabetically)

These datasets are not stored remotely and will only appear if the data processing pipeline is run. A * denotes datasets that should not be accessed outside of intended context.

- **adata-pk.csv**: cleaned nonmem data with neut information merged on (`data-processing/02_data-processing.Rmd`)
- **adata-time-summary.csv**: summary time variables (e.g., fp_day, final infusion) for each ptid (one row per person) (`data-processing/02_data-processing.Rmd`)
- **adata-vl-stats.csv**: full pre-ART cleaned viral load data with time and neut data merged on (`data-processing/02_data-processing.Rmd`)
- **adata-vl.csv**: 4 ptids with only 1 VL measurement prior to ART removed from adata-vl-stats.csv (`data-processing/02_data-processing.Rmd`)
- **adjusted_placebo_vl_popparms.csv**: VL model pop parms trained to placebo with indirect effects (`vl-modeling/03_placebo-pkpd-model.Rmd`)
- **adjusted_vrc01_vl_parms.csv**: indirect effect VL model applied to VRC01 group (for infection times)  (`vl-modeling/03_placebo-pkpd-model.Rmd`)
- **amp-individual-vrc01-sims.csv**: simulated individual trajectories from final PKPD Vl model (`vl-modeling/06_amp-sim-analysis.Rmd`)
- **amp-neut-blinded.csv**: rawish neut data, processed survival data among ptids with >= 1 isolate (`data-processing/01_neut-vl-processing.Rmd`)
- **dosing-data.csv**: cleaned full infusion time info for vrc01 and placebo (`data-processing/02_data-processing.Rmd`)
- **final_model_popparms.csv**: final pkpd vl model pop parms (`vl-modeling/05_amp-model-analysis.Rmd`)
- **final_vl_summary.csv**: summarized vl endpoints from data and final model sims (`vl-modeling/05_amp-model-analysis.Rmd`)
- **full-vl-data.csv**: blinded proto-clean vl data, includes post-ART, extra ptids, no neut/time info, input for adata (`data-processing/01_neut-vl-processing.Rmd`)
- **pk-nm-data.csv**: PK nonmem data pulled from shared remote source (`data-scripts/pull-shared-data.R`)
- **ptid-measurement-counts.csv**: summary measurement sample sizes for viral loads after first positive (`data-processing/02_data-processing.Rmd`)
- **ptid-time-data.csv***: upstream key time variables for data processing, cleaned into adata-time-summary.csv (`data-processing/01_neut-vl-processing.Rmd`)
- **rv217-vl.csv**: RV217 data for use in model training (deprecated approach)  (`data-scripts/process-RV217.R`)
- **unadjusted_model_vl_popparms.csv**: pop parms from VL model without PKPD (`vl-modeling/02_analysis-vl-model-holte.Rmd`)
- **unadjusted_model_vl_summary.csv**: summarized vl endpoints from data and VL model (no PKPD) sims (`vl-modeling/02_analysis-vl-model-holte.Rmd`)

## 1. Cleaning the raw data from source and summary datasets

These datasets have basic sanitizing but are not filtered/QCed for final analysis

See scripts in `data-scripts/`

- pk-nm-data.csv: Monolix/NM PK data from Lily's work with minimal processing, still in NM format

See `analysis/data-processing/01_neut-vl-processing.html`

- amp-neut-blinded.csv: neutralization data
- dosing-data.csv: infusion times, rates, and doses for the participants
- ptid-measurement-counts.csv: summarized VL measurements by participant (does this belong in here?)
- ptid-time-data.csv: just the time variables by pubid
- full-vl-data.csv: all viral load data with computed time variables (first positive, PF infection time, etc.), not subset for ART or missing neut data

## 2. Creating analysis data

These datasets are subset to the final analysis cohort: pre-ART, at least 2 VL measurements, have neutralization data. Generated via `analysis/data-processing/02_data-processing.html`. There is a viral load dataset `adata-vl.csv` and a pk dataset `adata-vl.csv`. 

The `adata-vl.csv` removes 4 ptids with only 1 VL measurement prior to ART, while `adata-vl-stats.csv` keeps those participants. The reason to keep separate data is for simplicity of mlx downstream processing.

The `adata-time-summary.csv` dataset summarizes time endpoints for the participants. As this is for statistical analyses, every HIV-acquisition is included (similar to `adata-vl-stats.csv`).

## 3. Other

rv217-vl.csv is the RV217 data for model training.
