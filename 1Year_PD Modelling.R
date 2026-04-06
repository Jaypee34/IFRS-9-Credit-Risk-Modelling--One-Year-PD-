
# ================================================================================
# IFRS 9 Credit Risk Modelling: 1-Year Probability of Default (PD) Modelling
# ================================================================================
# This R script demonstrates the process of building a one-year Probability 
# of Default (PD)
# model using a credit risk dataset. The script includes data preparation,
# univariate and multivariate analysis, logistic regression modelling, PD calibration
# and model validation steps. The script is designed to be reproducible and
# includes comments explaining each step in the context of credit risk modelling. 

# ================================================================================
# Import required libraries
# ===============================================================================
library(readxl)  # Used for reading Excel files into R
library(dplyr) # Data manipulation and transformation

library(vars)    
# Provides functions for vector autoregression (VAR) models
library(MASS)  
# Provides functions for statistical methods, 
# including stepwise regression (stepAIC)
library(caret)  
# Classification and Regression Training package
library(scorecard)  # Load the 'scorecard' package
library(corrplot)     # Load the corrplot package for visualizing correlation
library(broom) # Load the broom package
library(optiRum) # Used in lending, credit, and financial analytics.
library(pROC) # ROC/AUC evaluation for classification models to measure predictive performance of PD models
library(smbinning) # Used for optimal binning of continuous variables in credit
library(caret) # For data partitioning and model training
library(ROCR) # For performance evaluation of classification models (ROC, AUC, KS)
#===============================================================================
# Import data from Excel file
#===============================================================================
oneyr_pd <- read_xlsx("credit_data.xlsx")  
# Reads the Excel file "credit_data.xlsx" into R
# The dataset is stored as a dataframe named 'oneyr_pd'
# Typically used here for one-year Probability of Default (PD) modelling data

head(oneyr_pd)  
# Displays the first 6 rows of the dataset
# Useful for verifying:
# - Data imported correctly
# - Column names are as expected
# - Variable types look reasonable
# - No obvious data corruption issues

str(oneyr_pd)      # Check variable types (numeric, factor, date)
summary(oneyr_pd)  # Basic descriptive statistics
colSums(is.na(oneyr_pd))  # Check for missing values

# Data overview: Inspect data content and structure

dplyr::glimpse(oneyr_pd)  
# Provides a compact summary of the dataset structure
# Displays:
# - Number of rows (observations)
# - Number of columns (variables)
# - Column names
# - Data types (numeric, character, factor, date, etc.)
# - First few values of each variable

# Using dplyr::glimpse() instead of str() gives a cleaner,
# more readable overview, especially for large datasets.

# In PD modelling, this step helps to:
# - Confirm the default flag variable is correctly coded (e.g., 0/1)
# - Check that numerical risk drivers are not mistakenly imported as character
# - Identify categorical variables that may require encoding
# - Detect potential data quality issues early

#===============================================================================
# Default Flag Definition and Data Preparation
#===============================================================================
# Convert all columns containing "date" in their name to Date format

oneyr_pd <- oneyr_pd %>%
  dplyr::mutate(
    dplyr::across(
      contains("date"),  # Selects all columns whose names include the word "date"
      as.Date            # Converts selected columns to Date class
    )
  )

# Explanation:
# - %>% passes the dataset into the next function (pipe operator)
# - mutate() modifies existing columns
# - across() applies a function to multiple selected columns
# - contains("date") dynamically selects all date-related variables
# - as.Date converts values from character or numeric to Date format

# Why this is important in credit risk modelling:
# - Ensures proper time-based calculations (e.g., time-to-default)
# - Enables filtering by observation and performance windows
# - Prevents errors in survival models or lifetime PD estimation
# - Critical for IFRS 9 staging analysis and vintage reporting

# Round arrears count fields to 4 decimal places

oneyr_pd$max_arrears_12m <- round(oneyr_pd$max_arrears_12m, 4)
# Rounds the variable 'max_arrears_12m' to 4 decimal places
# This variable typically represents the maximum arrears level observed in the last 12 months

oneyr_pd$arrears_months <- round(oneyr_pd$arrears_months, 4)
# Rounds the variable 'arrears_months' to 4 decimal places
# This variable usually indicates the number of months a customer was in arrears

# Why this step may be performed:
# - Standardises numeric precision across variables
# - Avoids floating-point inconsistencies from Excel imports
# - Ensures consistency in reporting and model documentation
# - Prevents extremely small decimal noise from affecting modelling
# Default Flag Definition

# Create a binary default indicator 'default_event' based on multiple default triggers

oneyr_pd <- oneyr_pd %>%
  dplyr::mutate(
    default_event = if_else(
      arrears_event == 1 |       # Trigger default if the customer has arrears
        term_expiry_event == 1 |   # Trigger default if the loan term expired under loss conditions
        bankrupt_event == 1,       # Trigger default if the customer is bankrupt
      1,                         # Assign 1 for default
      0                          # Assign 0 for non-default
    )
  )

# Explanation:
# - %>% is the pipe operator, passing 'oneyr_pd' into mutate()
# - mutate() creates a new column or modifies existing ones
# - if_else() applies a conditional logic:
#       - TRUE → 1 (default)
#       - FALSE → 0 (non-default)
# - '|' is the OR operator: if any of the three conditions is TRUE, default_event = 1

# Why this is important in PD modelling:
# - Defines the target variable for the one-year Probability of Default model
# - Ensures all default-related events are captured consistently
# - Critical for IFRS 9, IRB, or regulatory credit risk models
# - Forms the basis for subsequent logistic regression or survival analysis


# Create an inverted default flag variable in the dataset

oneyr_pd <- oneyr_pd %>% 
  dplyr::mutate(
    default_flag = if_else(
      default_event == 1,  # If 'default_event' indicates default (1)
      0,                   # Assign 0 → non-performing
      1                    # Otherwise assign 1 → performing (good)
    )
  )

# Explanation:
# - %>% passes the dataset 'oneypd' into mutate()
# - mutate() creates a new column or modifies existing ones
# - if_else(condition, true_value, false_value) evaluates each row:
#       - TRUE → true_value
#       - FALSE → false_value
# - Here, default_flag is the inverted version of default_event:
#       - default_event = 1 → default_flag = 0
#       - default_event = 0 → default_flag = 1

# Why this is important in PD modelling:
# - Some scoring systems or logistic regression frameworks use 1 = good (performing)
# - Ensures consistency in calculations of metrics like Gini, KS, ROC
# - Helps with model validation and reporting under IFRS 9 or IRB requirements

set.seed(2122)  
# Set the random seed to 2122
# - Ensures reproducibility of results that involve randomness
# - Any operation using random number generation (e.g., data splitting, cross-validation, bootstrapping, sampling) 
#   will produce the same results every time the code is run
# - Critical in credit risk modelling for:
#     - Consistent train/validation splits for PD, LGD, or EAD models
#     - Reproducible model evaluation and reporting
# - Using a fixed seed is important for model governance and audit purposes

# Split Dataset into training and testing 
# sets (70/30 split) using Stratified Sampling


train.index <- caret::createDataPartition(
  oneyr_pd$default_event,  # Use the target variable 'default_event' to ensure stratified sampling
  p = 0.7,                  # Proportion of data to include in the training set (70%)
  list = FALSE              # Return row indices as a vector instead of a list
)

# Create the training dataset using the selected row indices
train <- oneyr_pd[train.index, ]  

# Create the testing/validation dataset using the remaining rows
test <- oneyr_pd[-train.index, ]  

# Explanation:
# - createDataPartition() performs **stratified sampling** to maintain the same proportion of defaults (1s) 
#   and non-defaults (0s) in the training set as in the original dataset.
# - train contains 70% of the data for model development
# - test contains 30% of the data for model validation
# - Ensures that model evaluation metrics (accuracy, Gini, KS) are reliable
# - Using stratified sampling is especially important in credit risk modelling, 
#   where the default rate is typically low (imbalanced dataset)


# Check the proportion of defaults in training and test sets

prop.table(table(train$default_event))
# - Creates a frequency table of 'default_event' in the training set
# - prop.table() converts counts into proportions
# - Helps verify that stratified sampling preserved the default/non-default ratio
# - Important to ensure the model sees a representative distribution during training

prop.table(table(test$default_event))
# - Performs the same check on the test (validation) set
# - Ensures the evaluation dataset has a similar default rate to the original dataset
# - Critical in PD modelling because defaults are usually rare (imbalanced dataset)
# - Prevents misleading performance metrics due to skewed sampling

# Univariate Analysis- WOE and IV Calculation

# Bin selected variables
bins <- woebin(train, y = "default_flag")
# Convert training data to WOE values
train_woe <- woebin_ply(train, bins)
# Convert test data to WOE values using the same bins
test_woe <- woebin_ply(test, bins)

# WOE plots
woebin_plot(bins)      # Visualize WOE binning results


# Calculate Information Value (IV) to identify predictive variables
iv_values <- iv(train_woe, y = "default_flag")
iv_values
# Select variables with IV > 0.02 (weak threshold)

# ============================================================================================
# STEP 9: Visualisation of IV values for selected variables to confirm variable importance ranking
# ============================================================================================

# IV ranking plot
ggplot(iv_values, aes(x = reorder(variable, info_value), y = info_value)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Information Value (IV) by Variable",
       x = "Variable",
       y = "Information Value") +
  scale_y_continuous(breaks = seq(0, max(iv_values$info_value, na.rm = TRUE), by = 0.2)) +
  geom_hline(yintercept = c(0.02, 0.1, 0.3, 0.5), linetype = "dashed", color = "red")
# Rationale: Visual checks ensure variable importance ranking and audit-ready reporting

# ================================================================================
# Select variables with IV > 0.02 for multivariate analysis
# ================================================================================
selected_vars <- dplyr::select(
  train_woe,
  bureau_score_woe,
  max_arrears_12m_woe,
  cc_util_woe,
  annual_income_woe,
  months_since_recent_cc_delinq_woe,
  max_arrears_bal_6m_woe,
  emp_length_woe,
  num_ccj_woe
)

# ==============================================================================
# Univariate Analysis
# ==============================================================================
# Univariate analysis for selected variables
# This step helps to understand the distribution of each variable and its 
# relationship with the target variable (default_flag). 
# It can reveal patterns, outliers, and potential issues

data_uni <- cbind(selected_vars, default_flag = train_woe$default_flag)


univariate_summary <- function(data, var, target) {
  data %>%
    group_by(.data[[var]]) %>%
    summarise(
      count = n(),
      good = sum(.data[[target]] == 0, na.rm = TRUE),
      bad = sum(.data[[target]] == 1, na.rm = TRUE),
      bad_rate = bad / count
    ) %>%
    arrange(.data[[var]])
}

vars <- names(selected_vars)

uni_results <- lapply(vars, function(v) {
  univariate_summary(data_uni, v, "default_flag")
})

names(uni_results) <- vars

uni_results$bureau_score_woe



plot_univariate <- function(data, var, target) {
  data %>%
    group_by(.data[[var]]) %>%
    summarise(bad_rate = mean(.data[[target]])) %>%
    ggplot(aes(x = .data[[var]], y = bad_rate)) +
    geom_line() +
    geom_point() +
    labs(title = paste("Bad Rate vs", var),
         x = var,
         y = "Bad Rate") +
    theme_minimal()
}

# =========================================================================================
# Multivariate Analysis to check for Multicollinearity
# ===========================================================================
# Remove rows with missing values
# Keep only numeric variables
selected_vars <- selected_vars %>%
  dplyr::select(where(is.numeric))

# Remove rows with missing values
selected_vars_clean <- na.omit(selected_vars)

# View cleaned dataset
print(selected_vars_clean)


# ==============================================================================
# Step 3: Convert to matrix (required for correlation)
# ==============================================================================
# Convert dataframe to matrix format
selected_matrix <- as.matrix(selected_vars_clean)


# Compute Spearman correlation matrix
corr_matrix <- cor(selected_matrix, method = "spearman")


# Visualise correlation matrix
corrplot(corr_matrix,
         method = "color",   # Use colored squares
         type = "upper",     # Show only upper triangle
         tl.col = "navy",    # Variable name color
         tl.cex = 0.5)       # Label size

# ===============================
# Step 6: Identify highly correlated variable pairs
# ===============================
high_corr_pairs <- which(abs(corr_matrix) > 0.7 & abs(corr_matrix) < 1, arr.ind = TRUE)
high_corr_pairs

# Logistics Regression model fitting

logit_full<- glm(default_flag~ bureau_score_woe+
                   annual_income_woe+ emp_length_woe+max_arrears_12m_woe
                 +months_since_recent_cc_delinq_woe+ num_ccj_woe+cc_util_woe,
                 family = binomial(link = "logit"), data = train_woe)
logit_stepwise<- stepAIC(logit_full, k=qchisq(0.05, 1,
                                              lower.tail=F), direction = "both")
summary(logit_stepwise)

logit_table <- tidy(logit_stepwise)
print(logit_table)

# Define the Scaling Function
scaled_score <- function(logit, odds, offset = 500, pdo = 20)
{
  b = pdo/log(2)
  a = offset - b*log(odds)
  round(a + b*log((1-logit)/logit))
}

#Score the entire dataset

predict_logit_test <- predict(logit_stepwise, newdata = test_woe, type = "response")
predict_logit_train <- predict(logit_stepwise, newdata = train_woe, type = "response")

#Merge predictions with train/test data

test_woe$predict_logit <- predict(logit_stepwise, newdata = test_woe, type = "response")
train_woe$predict_logit <- predict(logit_stepwise, newdata = train_woe, type = "response")
train_woe$sample = "train"
test_woe$sample = "test"
data_whole <- rbind(train_woe, test_woe)
data_score <- data_whole %>%
  dplyr::select(default_flag, bureau_score_woe,
                annual_income_woe,max_arrears_12m_woe,
                months_since_recent_cc_delinq_woe,
                cc_util_woe, sample, predict_logit)

# Define scoring parameters in line with objectives
data_score$score <- scaled_score(data_score$predict_logit, 72, 660, 40)

#=============================================================================
# PD Calibration
#=============================================================================

# Upload data
attach(data_score)

#Fit logistic regression

pd_model<- glm(default_flag~ score,
               family = binomial(link = "logit"), data = data_score)
summary(pd_model)

# Use model coefficients to obtain PDs

data_score$pd<- predict(pd_model, newdata = data_score,
                        type = "response")

#=============================================================================
# PD Model Validation
#=============================================================================

# Calculate Gini coefficient
# Generate predicted probabilities for training data
train$predict_logit <- predict(logit_full, train_woe, type = "response")
gini_train<- optiRum::giniCoef(train_woe$predict_logit,
                               train_woe$default_flag)
print(paste("Gini Coefficient for Training Set:", round(gini_train, 4)))
# Answer: Gini Coefficient for Training Set: 0.8467
# The result suggests that train and test Gini indices provides a strong
# discriminatory power of the model, with values close to 0.85 indicating excellent

# Plot ROC Curve
plot(roc(train$default_flag, train$predict_logit,
         direction = "<"),      # Higher score = higher default risk
     col = "red",               # Curve color
     lwd = 3,                   # Line thickness
     main = "ROC Curve")        # Title

#=============================================================================
# Create score bands, and
# Compare actual against fitted PDs
#=============================================================================

# Create score bands using the same cut points
data_score$score_band <- cut(
  data_score$score,
  breaks = c(-Inf, 517, 576, 605, 632, 667, 716, 746, 773, Inf),
  right = TRUE
)


# Compare actual against fitted PDs
# Compute mean values

data_pd<- data_score %>%
  dplyr::select(score, score_band, pd, default_flag) %>%
  dplyr::group_by(score_band) %>%
  dplyr::summarise(mean_dr = round(mean(default_flag),4),
                   mean_pd = round(mean(pd),4))

rmse<-sqrt(mean((data_pd$mean_dr - data_pd$mean_pd)^2))
rmse
# predicted probabilities are reasonably close to the observed default rates across score bands.
# The predicted PD differs from the observed default rate by about 3.7% points.
# This indicates that predicted probabilities are reasonably close to the 
# observed default rates across score bands.

#===# Select require================================================================
# Cross Validation
#===================================================================
# Select required variables
data_subset <- train_woe %>%
  dplyr::select(default_flag,
                bureau_score_woe,
                annual_income_woe,
                max_arrears_12m_woe,
                months_since_recent_cc_delinq_woe,
                cc_util_woe,
                sample)

set.seed(2122)

# Shuffle dataset to avoid class imbalance in folds
data_subset <- data_subset[sample(nrow(data_subset)), ]

# Initialise parameters
m <- 20
n <- floor(nrow(data_subset)/m)

auc_vector  <- rep(NA, m)
gini_vector <- rep(NA, m)
ks_vector   <- rep(NA, m)

for (j in 1:m) {
  
  s1 <- ((j-1)*n + 1)
  s2 <- (j*n)
  fold_index <- s1:s2
  
  train_cv <- data_subset[-fold_index, ]
  test_cv  <- data_subset[fold_index, ]
  
  # Skip fold if only one class present
  if(length(unique(test_cv$default_flag)) < 2) next
  
  # Logistic regression
  model <- glm(default_flag ~ bureau_score_woe +
                 annual_income_woe +
                 max_arrears_12m_woe +
                 months_since_recent_cc_delinq_woe +
                 cc_util_woe,
               family = binomial(link = "logit"),
               data = train_cv,
               control = glm.control(maxit = 50))
  
  # Predictions
  predict_cv <- predict(model,
                        newdata = test_cv,
                        type = "response")
  
  # ROCR prediction object
  pred_obj <- ROCR::prediction(predict_cv,
                               test_cv$default_flag)
  
  # AUC
  auc_perf <- ROCR::performance(pred_obj, "auc")
  auc_vector[j] <- auc_perf@y.values[[1]]
  
  # Gini
  gini_vector[j] <- optiRum::giniCoef(predict_cv,
                                      test_cv$default_flag)
  
  # KS
  ks_perf <- ROCR::performance(pred_obj, "tpr", "fpr")
  ks_vector[j] <- max(ks_perf@y.values[[1]] -
                        ks_perf@x.values[[1]])
}

# Final metrics
mean_auc  <- mean(auc_vector, na.rm = TRUE)
mean_gini <- mean(gini_vector, na.rm = TRUE)
mean_ks   <- mean(ks_vector, na.rm = TRUE)

mean_auc
mean_gini
mean_ks
