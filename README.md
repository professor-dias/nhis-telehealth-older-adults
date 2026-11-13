# Telehealth Use Among Adults Aged 65 Years and Older

R analysis of telehealth use among adults aged 65 years and older using pooled 2024 and 2025 National Health Interview Survey (NHIS) Sample Adult public-use data.

Maintained by **Professor Dias**. Copyright © 2026 **Noel Dias**.

## Data sources

All source data used in this project come from the Centers for Disease Control and Prevention (CDC), National Center for Health Statistics (NCHS):

- [2024 NHIS questionnaires, datasets, and documentation](https://www.cdc.gov/nchs/nhis/documentation/2024-nhis.html)
- [2025 NHIS questionnaires, datasets, and documentation](https://www.cdc.gov/nchs/nhis/documentation/2025-nhis.html)

On each page, use **Sample adult interview → Public-use data → CSV data file**. Extract the downloads and place `adult24.csv` and `adult25.csv` in the local `data/` folder. Consult each year's Sample Adult codebook and survey description for variable definitions and analytic guidance. Raw data are downloaded separately and are not included in this repository.

## Analysis

The script combines the two annual files and defines a survey design using `PPSU`, `PSTRAT`, and `WTFA_A / 2`. It then subsets the survey design to records with `AGEP_A >= 65`.

The outcome is `VIRAPP12M_A`, recoded as Yes/No. Covariates are age, race/ethnicity, survey year, sex, sexual orientation, urban/rural residence, education, disability, insurance coverage, and income-to-poverty category. The script contains the exact recoding rules and reference categories.

The analysis produces a survey-weighted descriptive table by telehealth use, separate unadjusted survey-weighted logistic regressions, and a multivariable survey-weighted logistic regression. Regression tables report exponentiated coefficients as odds ratios with 95% confidence intervals. Associations should not be interpreted as causal effects.

## Repository structure

```text
nhis-telehealth-older-adults/
├── README.md
├── .gitignore
├── telehealth_use_65plus.R
├── data/                         # local CSV files; excluded from Git
└── outputs/                      # generated HTML tables
```

The `data/` and `outputs/` folders include short README files so they are retained on GitHub.

## Requirements

Install R and, optionally, RStudio. The script installs the following packages when it runs. You can also install them in the R console:

```r
install.packages(c("dplyr", "survey", "gtsummary", "gt", "broom.helpers"))
```

Package versions are not currently pinned. Record `sessionInfo()` when reporting results.

## Run the analysis

Run the script with the repository root as the working directory.

1. Download or clone this repository.
2. Open R with the repository root as the working directory, or open its RStudio project.
3. Keep the included `data/` and `outputs/` folders in place.
4. Download and extract the two Sample Adult CSV files into `data/`.
5. Run:

   ```r
   source("telehealth_use_65plus.R")
   ```

Generated files:

- `outputs/Table1_NHIS_by_Outcome.html`: survey-weighted descriptive table by telehealth use.
- `outputs/Table2_NHIS_Regression.html`: unadjusted and adjusted odds ratios with 95% confidence intervals.

Model summaries are also printed in the R console.

## Status and limitations

This repository contains an analysis script, not a validated release of study findings. README preparation did not include executing the analysis or verifying all recodes against both annual codebooks. Before interpreting results, confirm cross-year variable comparability, pooled survey-design guidance, special missing-value handling (including age), category labels, and model sample sizes. The script maps unrecognized categorical values to missing; model samples can differ because of missing covariates.

## Attribution and reuse

Acknowledge CDC/NCHS as the source of the NHIS data and follow the citation guidance in the annual documentation. The project is an independent analysis. Copyright © 2026 Noel Dias. All rights reserved for original project code and documentation. No open-source license is granted. Contact Professor Dias for permission to reuse these materials. This notice does not apply to CDC/NCHS source data.
