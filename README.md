IFRS 9 Credit Risk Model Development

One-Year Probability of Default (PD) Model
Logistic Regression with Weight of Evidence Transformation
 

📊 One-Year PD Model (IFRS 9)
📝 Description

This repository contains the development and validation of a one-year Probability of Default (PD) model for retail credit portfolios. The model is built using logistic regression and aligned with IFRS 9 requirements for expected credit loss (ECL) estimation.

The modelling approach leverages behavioural and financial risk drivers, including credit utilisation, arrears history, income, credit bureau score, employment stability, and delinquency patterns. Variables were transformed and selected using statistical techniques (WoE, Information Value, and multicollinearity checks) to ensure robustness, interpretability, and regulatory compliance.

The model demonstrates strong predictive performance and stability, making it suitable for credit risk assessment, IFRS 9 staging (SICR), and portfolio monitoring.

🔹 Model Overview
Model type: Logistic Regression
Target: 1-year default probability
Transformation: Weight of Evidence (WoE)
Variable selection: Information Value (IV) + multicollinearity checks

🔹 Final Variables
cc_util – Credit card utilisation
max_arrears_12m – Maximum arrears in last 12 months
annual_income – Annual income
bureau_score – Credit bureau score
emp_length – Employment length
months_since_recent_cc_delinq – Time since last delinquency

📈 Model Performance
AUC: 0.9223
Gini: 0.8445
KS Statistic: 0.7100
Calibration (RMSE): 0.0374

Cross-validation results show:

Stable performance across folds
AUC consistently in the 0.91 – 0.93 range

📊 Validation Highlights
Strong discriminatory power (high AUC/Gini/KS)
Good calibration: predicted PD aligns closely with observed defaults
Score-band analysis confirms monotonic relationship between score and risk

✅ Use Cases
IFRS 9 Expected Credit Loss (ECL) computation
Significant Increase in Credit Risk (SICR) assessment
Credit risk decisioning and portfolio monitoring
⚙️ Status

✔ Model validated and considered fit for purpose, subject to ongoing monitoring and governance.
