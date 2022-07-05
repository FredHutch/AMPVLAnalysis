Processed analysis data
=======================

Data processing essentially has two steps:

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


## 2. Analysis data

These datasets are subset to the final analysis cohort: pre-ART, at least 2 VL measurements, have neutralization data. Generated via `analysis/data-processing/02_data-processing.html`. There is a viral load dataset `adata-vl.csv` and a pk dataset `adata-vl.csv`. 


The `adata-vl.csv` removes 4 ptids with only 1 VL measurement prior to ART, while `adata-vl-stats.csv` keeps those participants. The reason to keep separate data is for simplicity of mlx downstream processing.

The `adata-time-summary.csv` dataset summarizes time endpoints for the participants. As this is for statistical analyses, every HIV-acquisition is included (similar to `adata-vl-stats.csv`).

## 3. Other

rv217-vl.csv is the RV217 data for model training.
