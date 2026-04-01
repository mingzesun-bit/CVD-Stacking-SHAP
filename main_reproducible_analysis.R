# Reproducible R script: CVD Stacking Ensemble + SHAP

library(tidyverse)
library(caret)
library(caretEnsemble)
library(gbm)
library(pROC)
library(yardstick)
library(tableone)
library(fastshap)

set.seed(100)

if (requireNamespace("rstudioapi", quietly = TRUE)) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

data_raw <- read.csv("cardio_train.csv", sep = ";")

data <- data_raw %>%
  select(-id) %>%
  mutate(
    age_years = round(age / 365.25),
    cardio = factor(cardio, levels = c(0, 1), labels = c("Healthy", "Disease")),
    gender = factor(gender, levels = c(1, 2), labels = c("Women", "Men")),
    cholesterol = factor(cholesterol, levels = c(1, 2, 3), labels = c("Normal", "Above_Normal", "Well_Above_Normal")),
    gluc = factor(gluc, levels = c(1, 2, 3), labels = c("Normal", "Above_Normal", "Well_Above_Normal")),
    smoke = factor(smoke, levels = c(0, 1), labels = c("No", "Yes")),
    alco = factor(alco, levels = c(0, 1), labels = c("No", "Yes")),
    active = factor(active, levels = c(0, 1), labels = c("No", "Yes"))
  ) %>%
  select(-age) %>%
  filter(ap_hi >= 60 & ap_hi <= 250,
         ap_lo >= 40 & ap_lo <= 150,
         ap_hi > ap_lo)

# Train/test split
set.seed(42)
trainIndex <- createDataPartition(data$cardio, p = 0.7, list = FALSE)
train_raw <- data[trainIndex, ]
test_raw  <- data[-trainIndex, ]

# Baseline Table 1
myVars <- c("age_years", "gender", "height", "weight", "ap_hi", "ap_lo",
            "cholesterol", "gluc", "smoke", "alco", "active")
catVars <- c("gender", "cholesterol", "gluc", "smoke", "alco", "active")
tab1 <- CreateTableOne(vars = myVars, strata = "cardio", data = data, factorVars = catVars)
write.csv(print(tab1, quote = FALSE, noSpaces = TRUE, printToggle = FALSE, showAllLevels = TRUE),
          "results/Table1_Baseline.csv", row.names = FALSE)

# Model training
ctrl <- trainControl(method = "cv", number = 5, savePredictions = "final",
                     classProbs = TRUE, summaryFunction = twoClassSummary)

grid_rf <- data.frame(
  mtry = 3,
  splitrule = "gini",
  min.node.size = 10
)
grid_gbm <- expand.grid(n.trees = 100, interaction.depth = 3,
                        shrinkage = 0.1, n.minobsinnode = 10)

models <- caretList(
  cardio ~ ., data = train_raw, trControl = ctrl, metric = "ROC",
  tuneList = list(
    glm = caretModelSpec(method = "glm", family = "binomial"),
    rf  = caretModelSpec(method = "ranger", tuneGrid = grid_rf),
    gbm = caretModelSpec(method = "gbm", tuneGrid = grid_gbm, verbose = FALSE)
  )
)

stack_model <- caretStack(models, method = "glm",
                          trControl = trainControl(method = "none", classProbs = TRUE))

# Predictions on test set
prob_lr  <- predict(models$glm, newdata = test_raw, type = "prob")[, "Disease"]
prob_rf  <- predict(models$rf,  newdata = test_raw, type = "prob")[, "Disease"]
prob_gbm <- predict(models$gbm, newdata = test_raw, type = "prob")[, "Disease"]
prob_stack <- predict(stack_model, newdata = test_raw)$Disease

# Performance metrics
roc_stack <- roc(test_raw$cardio, prob_stack, levels = c("Healthy", "Disease"))
pr_res <- pr_auc(data.frame(truth = test_raw$cardio, prob = prob_stack),
                 truth, prob, event_level = "second")

metrics <- data.frame(
  Model   = "Stacking",
  AUC     = round(as.numeric(auc(roc_stack)), 3),
  PR_AUC  = round(pr_res$.estimate, 3),
  DeLong_p = round(roc.test(roc_stack, roc(test_raw$cardio, prob_lr))$p.value, 6)
)
write.table(metrics, "results/performance_metrics.txt", row.names = FALSE, sep = "\t")

# Save predictions
write.csv(data.frame(truth = test_raw$cardio, Stacking = prob_stack),
          "results/predictions.csv", row.names = FALSE)

# SHAP values (2000 samples)
set.seed(888)
explain_data <- train_raw[sample(nrow(train_raw), 2000), ]
X_features   <- explain_data[, !names(explain_data) %in% "cardio"]

pfun <- function(object, newdata) {
  predict(object, newdata = newdata, type = "prob")[, "Disease"]
}

shap_calc <- fastshap::explain(models$gbm, X = X_features,
                               pred_wrapper = pfun, nsim = 50)

write.csv(shap_calc, "results/shap_values.csv", row.names = FALSE)
