Data Processing
=================


- 1. Clean up the raw neut and viral load data (01)
- 2. Basic diagnostics, combine the neutralization and viral load data (02)
- 3. Create mlx data
  - a. mlx formatted data for the viral load models without VRC01 adjustment for basic model setup and infection time estimation (03)
  - b. mlx formatted data for pkpd models: includes PK parameters, vrc01 dosing times, infection time from models based on 03 (04)
      - This also generates the hill slope figure for the supplement while imputing hill slope for censored IC value.

The first two scripts save data in data/processed-data or in the output/data-processing/ folders. Monolix (mlx) data is saved in the data/mlx-data/ folder.

Processing details are in the rendered html files.