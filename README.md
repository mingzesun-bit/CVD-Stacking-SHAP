# CVD Stacking Ensemble + SHAP (PeerJ Computer Science 2026)

Reproducible R code for the paper:  
**Empirical study on cardiovascular disease risk stratification based on stacking ensemble framework combined with SHAP explanation**

## Dataset Information
- **Raw dataset**: Original Kaggle Cardiovascular Disease Dataset (`cardio_train.csv`, 70,000 records, **no preprocessing applied**)
- After cleaning (performed entirely in code): 68,667 records
- Target: Binary cardiovascular disease (0 = Healthy, 1 = Disease)

## Code Information
- Language: R 4.x
- Main script: `main_reproducible_analysis.R`
- Models: Random Forest + GBM (base learners) + Logistic Regression (meta-learner)
- Interpretability: SHAP (fastshap + shapviz)
- Clinical utility: Decision Curve Analysis (dcurves)

## Usage Instructions
1. Place the **original** `cardio_train.csv` (downloaded from Kaggle) in the `data/` folder
2. Run: `source("main_reproducible_analysis.R")`

## Requirements
- R version 4.3+
- Packages: `tidyverse`, `caret`, `caretEnsemble`, `gbm`, `pROC`, `yardstick`, `tableone`, `fastshap`

## Data Cleaning Steps (in main_reproducible_analysis.R)
- Remove ID column
- Convert age from days to years
- Convert categorical variables to factors
- Remove physiologically impossible blood pressure values

## License
MIT License
