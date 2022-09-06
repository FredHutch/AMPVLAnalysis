# AMPVLAnalysis

A [workflowr][] project.

[workflowr]: https://github.com/workflowr/workflowr


How to download the data with access:

 - Run `data-scripts/pull-shared-data.R`
 - Main neut files are downloaded from [atlas](https://atlas.scharp.org/cpas/project/HVTN/Collaborators/AMP%20Data%20for%20Modeling/begin.view?).
   - Download all together and store the folder in `data/raw-data/`
 - Knit `analysis/data-processing/01_neut-vl-processing.Rmd`
 - Knit `analysis/data-processing/02_data-processing.Rmd`
 - Knit `analysis/data-processing/03_create-mlx-data.Rmd`
 
 
 