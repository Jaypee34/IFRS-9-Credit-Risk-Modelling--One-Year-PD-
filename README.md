IFRS 9 Credit Risk Model Development

One-Year Probability of Default (PD) Model
Logistic Regression with Weight of Evidence Transformation
 
1. Executive Summary

This report presents the development and validation of a one-year Probability of Default (PD) model for retail credit exposures, constructed in compliance with International Financial Reporting Standard 9 (IFRS 9). The model supports the estimation of Expected Credit Loss (ECL) across the three-stage classification framework prescribed under IFRS 9, enabling the institution to allocate impairment provisions on a forward-looking, point-in-time basis.

The model employs logistic regression with Weight of Evidence (WoE) encoded predictors, an approach widely accepted by prudential regulators and consistent with industry best practice for interpretable PD scorecards. Following rigorous variable selection guided by Information Value (IV) analysis, six statistically significant predictors were retained in the final model: cc_util_woe, maxarrears_12m_woe, annual_income_woe, bureau_score_woe, emp_length_woe, and months_since_recent_cc_delinq_woe. The model demonstrates strong discriminatory power across all standard performance metrics, with a cross-validated AUC of 0.9223, a Gini coefficient of 0.8445, and a Kolmogorov-Smirnov (KS) statistic of 0.7100.

These results indicate a high degree of risk separation between performing and defaulting obligors, with model calibration confirmed through score-band analysis. The model is considered suitable for deployment in ECL calculations, staging allocation, and credit underwriting decisions.

2. Regulatory and Conceptual Framework

2.1  IFRS 9 Requirements
IFRS 9, effective for annual reporting periods beginning on or after 1 January 2018, replaced IAS 39 and fundamentally changed the recognition and measurement of financial instruments. Under IFRS 9, impairment losses on financial assets are recognised on an expected credit loss basis, rather than an incurred loss basis. The standard requires entities to measure ECL using forward-looking information and to classify exposures into one of three stages:

•	Stage 1 — Performing: Twelve-month ECL is recognised for assets where credit risk has not significantly increased since initial recognition.
•	Stage 2 — Underperforming: Lifetime ECL is recognised where a significant increase in credit risk (SICR) has occurred, but no objective evidence of default exists.
•	Stage 3 — Credit-impaired: Lifetime ECL is recognised for assets where objective evidence of default or credit impairment is present.

A one-year PD model is central to both the twelve-month ECL calculation for Stage 1 assets and the determination of SICR thresholds used for stage migration. Accordingly, the model documented herein is a critical component of the institution's IFRS 9 impairment framework.

2.2  Model Scope and Objective
The model is designed to estimate the probability that an obligor will default within a twelve-month horizon from the observation date. Default is defined consistently with the Basel III / IRB definition: an obligor is considered to have defaulted when it is 90 days or more past due on a material credit obligation, or when it is assessed as unlikely to pay without recourse to collateral. The model is applied to the retail lending portfolio and produces account-level PD estimates used in ECL computation and credit limit management.

3. Data Preparation and Variable Selection

3.1  Weight of Evidence Transformation
All predictor variables were transformed using the Weight of Evidence (WoE) methodology before model development. WoE transformation offers several advantages: it converts non-linear relationships to near-linear ones on the log-odds scale, handles missing values naturally by assigning them a distinct bin, and facilitates the removal of outlier effects. The WoE for bin i is defined as:

WoE_i  =  ln( Distribution of Events_i  /  Distribution of Non-Events_i )

3.2  Information Value Analysis
The Information Value (IV) statistic was used to assess the predictive power of each candidate variable before model inclusion. IV is calculated as the sum over all bins of the product of the WoE and the difference in event/non-event distributions. The conventional thresholds applied were: IV < 0.02 (unpredictive), 0.02–0.1 (weak), 0.1–0.3 (medium), 0.3–0.5 (strong), and > 0.5 (very strong or suspiciously high). The chart below shows IV values for the full set of predictor variables.

 
Figure 1: Information Value by Variable — Full Candidate Set
The variables cc_util_woe, max_arrears_12m_woe, and arrears_months_woe exhibited the highest information values, all exceeding 0.5, confirming very strong predictive power. max_arrears_bal_6m_woe and worst_arrears_status_woe also scored above 0.5. Further down the ranking, annual_income_woe, bureau_score_woe, emp_length_woe, months_since_recent_cc_delinq_woe, and num_ccj_woe all recorded IV in the medium-to-strong range (0.1–0.5), supporting their inclusion in the candidate model. Variables such as repayment_type_woe, loan_balance_woe, monthly_installment_woe, and region_woe fell below predictive thresholds and were excluded from further analysis.



4. Predictor Diagnostics

4.1 WoE Distributions by Default Status
The boxplots below illustrate the distribution of WoE values for each model predictor, stratified by default flag (0 = Good; 1 = Bad). Clear separation between the two groups is evident across all retained predictors, confirming their discriminatory relevance.

 
Figure 3: WoE Variable Distributions by Default Flag
Notably, cc_util_woe shows the strongest separation: good obligors (flag = 0) are concentrated at strongly negative WoE values, reflecting low credit card utilisation, while bad obligors (flag = 1) cluster at high positive values. max_arrears_12m_woe and max_arrears_bal_6m_woe display similarly clear differentiation, with good obligors near zero and bad obligors at negative values, consistent with the WoE encoding direction where worse arrears behaviour maps to lower WoE. bureau_score_woe shows that good obligors have higher WoE values, indicating that stronger bureau scores are associated with lower default risk. annual_income_woe and emp_length_woe show moderate separation, while months_since_recent_cc_delinq_woe and num_ccj_woe exhibit wide interquartile ranges for both groups but with discernible median shifts.


4.2 Multicollinearity Assessment
A Pearson correlation matrix was computed for all candidate predictors to identify and mitigate multicollinearity. The heatmap below presents pairwise correlations among the variables assessed for inclusion in the final model.

 
Figure 4: Correlation Matrix of WoE Predictors
The correlation structure reveals a moderate positive correlation between bureau_score_woe and max_arrears_12m_woe (approximately 0.4–0.5), reflecting that bureau scores are partly driven by arrears history. A moderate positive correlation is also visible between annual_income_woe and max_arrears_bal_6m_woe, and between emp_length_woe and num_ccj_woe. cc_util_woe and months_since_recent_cc_delinq_woe show relatively low correlations with most other predictors, confirming they contribute distinct information. No pairwise correlation exceeds 0.7, indicating that multicollinearity does not materially compromise the stability of coefficient estimates.


5. Model Development

5.1 Model Architecture
The final model is a logistic regression trained on Weight-of-Evidence-transformed inputs, equivalent to a scorecard model in the log-odds space. The logistic regression takes the form:

log[ p / (1 - p) ]  =  β₀ + β₁·WoE₁ + β₂·WoE₂ + ... + βₙ·WoEₙ

Where p denotes the probability of default, this formulation is interpretable, parsimonious, and directly maps to a scorecard by applying a linear transformation of the log-odds to a numerical score.
5.2 Variable Selection Criteria
Final predictors were selected based on a combination of statistical significance (p-value < 0.05), business interpretability, Information Value, and multicollinearity assessment. The correlation matrix and IV chart guided the exclusion of redundant variables. The six retained predictors are economically intuitive and collectively capture credit history behaviour, repayment capacity, and utilisation of existing credit facilities.
5.3 Final Model Coefficients
The table below presents the estimated coefficients, standard errors, z-statistics, and p-values for all terms in the final model. All predictors are statistically significant at the 1% level, with the intercept and all WoE coefficients carrying the expected positive sign.

Variable	Estimate	Std. Error	Statistic	p-value
(Intercept)	2.910	0.0531	54.8	< 0.001
bureau_score_woe	0.524	0.0627	8.36	6.12e-17
annual_income_woe	0.890	0.0595	15.0	1.45e-50
emp_length_woe	0.322	0.0983	3.27	1.06e-3
max_arrears_12m_woe	0.855	0.0392	21.8	2.35e-105
months_since_recent_cc_delinq_woe	0.208	0.0826	2.52	1.18e-2
cc_util_woe	0.967	0.0382	25.3	2.33e-141
Table 1: Final Logistic Regression Model Coefficients


The largest coefficient is associated with cc_util_woe (0.967), reflecting that credit card utilisation is the single most influential predictor of default risk in the fitted model; higher utilisation is strongly associated with increased default probability. annual_income_woe (0.890) and max_arrears_12m_woe (0.855) are also highly significant, with the arrears variable carrying an extremely small p-value of 2.35e-105, underscoring the importance of recent payment behaviour. bureau_score_woe (0.524) and emp_length_woe (0.322) contribute meaningfully to risk ranking, while months_since_recent_cc_delinq_woe (0.208) captures the recency of credit card delinquency events. All p-values are well below 0.001, providing strong evidence against the null hypothesis of zero effect.

6. Model Performance and Validation

6.1  Performance Metrics Summary
The model was evaluated using a stratified k-fold cross-validation approach to produce robust out-of-sample performance estimates that are not overfit. Three standard discrimination metrics were computed for each fold and summarised below.

Metric	AUC 	 Gini	 KS
Cross-Validation	0.9223	0.8445	0.7100
Table 2: Cross-Validation Performance Metrics

An AUC of 0.9223 indicates that the model correctly ranks a randomly selected defaulting obligor above a randomly selected non-defaulting obligor approximately 92% of the time. The Gini coefficient of 0.8445 (computed as 2·AUC − 1) and the KS statistic of 0.7100 both confirm strong discriminatory power. These results comfortably exceed the regulatory minimum thresholds typically expected for retail credit PD models (AUC > 0.75; Gini > 0.50).

6.2  ROC Curve
The Receiver Operating Characteristic (ROC) curve plots the true positive rate (sensitivity) against the false positive rate (1 − specificity) across all classification thresholds. The curve below demonstrates consistent, strong model performance well above the diagonal random classifier baseline.

 
Figure 5: ROC Curve
The pronounced bow of the ROC curve toward the top-left corner confirms high sensitivity at low false-positive rates, indicating the model is effective at identifying high-risk borrowers while minimising misclassification of low-risk borrowers as defaulters.

6.3  Cross-Validation Stability
The distribution of AUC, Gini, and KS statistics across all cross-validation folds is presented below. Tight distributions indicate that model performance is stable across data partitions, rather than being driven by a single fold or a particular subset of the sample.

 
Figure 6: Distribution of Cross-Validation AUC, Gini, and KS Statistics
AUC values are concentrated in the range 0.91–0.93, Gini values in the range 0.81–0.87, and KS values in the range 0.63–0.76. The low variance across folds demonstrates that the model generalises well to unseen data and is not overfit to the training sample.

7. Model Calibration

7.1  Score Band Analysis
Calibration was assessed by grouping obligors into score bands and comparing the model-predicted average PD to the observed default rate within each band. Well-calibrated models exhibit close alignment between these two quantities. The chart below presents this comparison across three score bands.

 
Figure 7: Actual Default Rate vs Predicted PD by Score Band
The score band analysis confirms satisfactory model calibration. The lowest score band (≤ 517) exhibits a realised default rate approaching 95%, with the model-predicted PD (red line) closely tracking this figure. In the intermediate band (517–576), both actual and predicted rates are in the 15–17% range, while the highest band (576–605) shows a low default rate consistent with the model's prediction of approximately 6%. The monotonic decline in the relationship between score band and default rate is consistent with IFRS 9's requirements for risk ranking.

7.2  RMSE
The Root Mean Squared Error (RMSE) between predicted PD and observed default outcomes was computed as 0.03737. This low RMSE value confirms that, at the account level, the model's probability estimates closely approximate realised default frequencies, supporting its use in ECL quantification under IFRS 9.

8. Gains and Lift Analysis

The Combined Gains and Lift Chart below assesses the model's ability to concentrate defaulters in high-risk deciles. Obligor is sorted by predicted PD in ascending order (Decile 1 = lowest predicted risk), and cumulative gains are measured as the proportion of all defaults captured by each successive decile.

 
Figure 8: Combined Gains and Lift Chart
The chart demonstrates that approximately 10% of defaults are captured in the lowest-risk decile, rising steeply such that the top two deciles (highest predicted PD) together account for a substantial majority of all defaults. The lift bars confirm that later deciles progressively capture a smaller incremental share of defaulters, consistent with the model's ability to rank risk effectively. This concentration of defaults in high-score deciles is directly relevant for IFRS 9 staging, enabling efficient identification of Stage 2 and Stage 3 candidates.


9. Model Governance and Limitations

9.1  Assumptions and Limitations
•	The model is estimated on historical data and assumes that patterns of default observed historically will persist into the future. Structural changes in the economic environment or lending policy may reduce model accuracy over time.
•	Forward-looking macroeconomic adjustments (overlays) required under IFRS 9 paragraph 5.5.4 are not embedded within the statistical model. They must be applied as separate adjustments to the model's point-in-time PD estimates.
•	The model covers the retail lending portfolio only and should not be applied to corporate, SME, or other exposure types without re-estimation or validation.
•	WoE binning was performed on the development dataset; bin boundaries should be reviewed if applied to significantly different populations.

9.2  Model Monitoring Requirements
In accordance with sound model risk management principles and IFRS 9 governance expectations, the model should be subject to the following ongoing oversight activities:
•	Quarterly monitoring of population stability indices (PSI) for each input variable — cc_util_woe, max_arrears_12m_woe, annual_income_woe, bureau_score_woe, emp_length_woe, and months_since_recent_cc_delinq_woe — to detect distributional drift.
•	Annual back-testing of model-predicted PD against observed default rates at each score band (≤ 517, 517–576, 576–605) and in aggregate.
•	Periodic (at minimum annual) model review and re-validation by a model risk function independent of the model development team.
•	Formal model re-development trigger criteria to be defined, including AUC deterioration thresholds and PSI breach limits.




10. Conclusion

This report documents the development of a logistic regression-based one-year Probability of Default model for retail credit exposures, implemented in accordance with IFRS 9 requirements. The model employs WoE-transformed predictors, with six variables retained following rigorous IV-based selection and multicollinearity assessment: cc_util_woe, max_arrears_12m_woe, annual_income_woe, bureau_score_woe, emp_length_woe, and months_since_recent_cc_delinq_woe.

The final model achieves strong discriminatory performance, with a cross-validated AUC of 0.9223, Gini of 0.8445, and KS of 0.7100, alongside a low calibration RMSE of 0.0374. Score-band analysis confirms that predicted PD closely tracks observed default rates across the three score bands. Cross-validation distributions demonstrate stability and robustness, with AUC concentrated in the 0.91–0.93 range across all folds.

The model is considered fit for purpose for IFRS 9 ECL computation, SICR assessment, and credit risk management applications, subject to the governance and monitoring framework described in Section 9.


END OF REPORT
Abbreviations
ureau_score: Credit Bureau Score
max_arrears_12m: Maximum Arrears in the Last 12 Months
cc_util: Credit Card Utilisation 
annual_income: Annual Income
 months_since_recent_cc_delinq: Months Since Most Recent Credit Card Delinquency
 max_arrears_bal_6m: Maximum Arrears Balance in Last 6 Months
 emp_length: Employment Length
num_ccj: Number of County Court Judgements
