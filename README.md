# CVD Stacking Ensemble + SHAP (PeerJ 2026)

Reproducible R code for the paper:  
**Empirical Study on Cardiovascular Disease Risk Stratification Based on Stacking Ensemble Framework Combined with SHAP Explanation**

## 📋 Overview
- 5-fold stratified stacking ensemble (RF + GBM + LR meta-learner)
- SHAP (TreeExplainer) interpretability + dependence plots
- Decision Curve Analysis (DCA) + calibration plots
- Full reproduction of all tables and figures in the manuscript

## 🛠 Requirements
- R version 4.2.0 or higher
- Required packages (run once):
  ```r
  install.packages(c("randomForest", "gbm", "caret", "pROC", "PRROC", "rmda", "SHAPforxgboost", "ggplot2", "dplyr"))
