USE RiskAnalysis;

/*
Scenario 1: The Collections Bottleneck (Demographic Risk & Data Gaps)
Business Case: The Chief Risk Officer (CRO) has noticed that regional economic indicators are shifting, 
and the loan portfolio needs to be hardened against potential delinquencies. The collections and customer
outreach teams are preparing an early-warning communication strategy.
However, a major operational risk is missing contact data. If a high-risk borrower 
goes delinquent and has no phone number on file, our collections team 
cannot execute outbound call strategies, which delays our time-to-resolution and increases credit losses.

Objective: Generate a proactive outreach list of borrowers who meet a specific high-vulnerability profile:
1) They reside in the state of Florida, Illinois or California.
2) They have an annual income of less than $120,000.
3) They are missing a phone number in our master system records.
*/

SELECT b.borrower_id, CONCAT(b.first_name, ' ', b.last_name) AS FullName, b.city, ep.annual_income
FROM BORROWERS b 
JOIN EMPLOYMENT_PROFILES ep
ON b.borrower_id = ep.borrower_id
WHERE b.state IN ("FL","IL","CA") AND ep.annual_income < 120000 AND (b.phone IS NULL OR b.phone = '');

/*
Scenario 2: The Leading Indicator (Credit Score Drift)
Business Case: The underwriting team knows that a consumer's credit score doesn't just plummet overnight without 
warning. Before a borrower defaults on a loan, they typically show signs of financial distress—like maxing out credit 
cards or falling behind on other obligations—which causes their FICO score to drift downward over time.
To catch this early, the risk team wants an early-warning report identifying "High-Drift" borrowers. 
Specifically, we need to find individuals whose FICO scores dropped by more than 20 points 
between their 2025 evaluation and their 2026 evaluation.

Objective: Write a query that compares each borrower's 2025 FICO score against their 
2026 FICO score and filters for those whose scores dropped by more than 20 points.
*/

-- New column - score_drop (The absolute point difference showing the decline)
WITH HIGH_DRIFT_BORROWERS AS (
SELECT borrower_id, MAX( -- WE ARE USING MAX HERE SO THAT WE CAN GROUP BY
CASE
WHEN EXTRACT(year FROM evaluation_date) = '2025' THEN fico_score END) AS `2025_Fico_Score`,
MAX(CASE
WHEN EXTRACT(year FROM evaluation_date) = '2026' THEN fico_score END) AS `2026_Fico_Score`
FROM CREDIT_SCORES_HISTORY
GROUP BY borrower_id
)
SELECT*,
CASE
WHEN (`2026_Fico_Score` < `2025_Fico_Score`) THEN (`2025_Fico_Score` - `2026_Fico_Score`) 
ELSE 0 END AS "SCORE_DROP"
FROM HIGH_DRIFT_BORROWERS
HAVING SCORE_DROP > 20;

/*
Scenario 3: The Collateral Cushion (Loan-to-Value / LTV Risk)
Business Case: When a bank issues a secured loan (such as an automobile or property loan), it secures a 
physical asset as collateral. If a borrower stops paying, the bank can repossess and sell that asset 
to recover its capital. However, if the market value of the asset drops below the outstanding loan balance, 
the bank faces Negative Equity, —a high-risk state where the Loan-to-Value (LTV) ratio exceeds 100%. 
If these borrowers default, the bank will suffer an immediate financial loss because the asset won't cover the debt.
The Asset-Liability Management (ALM) team wants to run a structural risk test to flag every single secured 
loan that is currently under-collateralized.
Objective: Write a query that identifies all secured loans where the loan_amount is greater 
than the asset's current_market_value (LTV > 100%).
-- ltv_ratio (Calculated as: (loan_amount / current_market_value) * 100)
*/

SELECT l.loan_id, cv.asset_type, l.loan_amount, cv.current_market_value AS "Collateral Current Valuation", 
ROUND(((l.loan_amount/cv.current_market_value) * 100),2) AS "Loan_Value_Ratio"
FROM LOANS l
JOIN COLLATERAL_VALUATIONS cv
ON l.loan_id = cv.loan_id
WHERE ((l.loan_amount/cv.current_market_value) * 100) > 100;

/*
Scenario 4: The Delinquency Trigger (Chronic Arrears)
Business Case: The collections department operates on a tier system. A borrower who misses a single payment 
might just be forgetful, but a borrower who repeatedly breaks their contract by failing to make payments 
requires aggressive intervention. In risk management, tracking the frequency of missed payments is an essential 
metric for predicting a loan's ultimate transition into "Default" or "Charged-Off" status.
\The VP of Account Strategy wants a list of "Chronic Delinquency" loans to assign to senior collection agents. 
Specifically, we need to flag any loan where the borrower has completely missed their 
payment (meaning the amount_paid is exactly 0) on more than one occasion across their history.
Objective: Write a query that scans the transaction history to identify individual loans that have 
recorded a completely missed payment (amount_paid = 0) multiple times.
*/

SELECT COUNT(*) FROM PAYMENT_LEDGER;
-- Data Ingestion Audit & Silent Row Deletion (Case 4 Notes)
/*
During the portfolio ingestion phase, a data quality audit revealed a discrepancy where the 
PAYMENT_LEDGER row count dropped from 441 to 432 rows. Investigations showed that MySQL Workbench's 
Import Wizard operates under strict SQL parsing modes, resulting in the silent deletion of 9 
critical transaction records containing blank cells for amount_paid. This real-world ETL (Extract, Transform, Load) 
failure highlights the necessity of pre-validating raw CSV data inputs, as strict type constraints can lead to 
silent data loss, inadvertently wiping out the very delinquency records targeted for risk analysis.
*/

/*
Scenario 5: The Safety Net (Guarantor Exposure)
Business Case: When a loan goes into a dangerous state like Delinquent or Default, the bank's next step 
is to protect its capital. For high-risk loans, underwriters often require a Guarantor (a co-signer) 
to legally back the debt. If the primary borrower stops paying, the bank legal team shifts collection 
efforts directly to the guarantor.
The Legal and Recovery team needs a priority list of all co-signed loans that are currently in jeopardy so they can prepare outbound legal notices.
Objective: Write a query that finds all loans with a status of either Delinquent or Default that 
have an associated guarantor on file.
*/
SELECT l.loan_id, l.loan_amount, l.loan_status, CONCAT(g.first_name, " ", g.last_name) AS "GuarantorCode"
FROM LOANS l
JOIN GUARANTORS g
ON l.loan_id = g.loan_id
WHERE l.loan_status IN ("Delinquent", "Default");

/*
Scenario 6: The Liquidity Forecast (Running Debt Accumulation)
Business Case: The Asset-Liability Management (ALM) team models cash flows to predict bank liquidity. 
They want to analyze how aggressively debt obligations accumulate for our borrowers month-over-month.
To do this, they need a report that looks at the PAYMENT_LEDGER and calculates a cumulative running 
total of the amount due for each loan over time. Unlike a standard GROUP BY which squashes our 
transactions into a single row, we need a window function that keeps every individual transaction row 
visible while calculating a running sum side-by-side.

Objective: Write a query that pulls every payment record and adds a dynamic analytical column calculating 
the cumulative running total of amount_due for each specific loan_id, sorted chronologically by the due_date.
*/

SELECT loan_id, due_date, amount_due, 
SUM(amount_due) OVER (PARTITION BY loan_id ORDER BY due_date ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS "cumulative_billed_to_date"
FROM PAYMENT_LEDGER;

/*
 Business Case: In credit analytics, banks monitor Vintage Risk—the performance of loans based on the month and 
 year they were issued. Sometimes, external factors (like holiday spending seasons or end-of-quarter sales targets) 
 cause underwriting standards to shift, leading to a concentration of unusually large loans in a short timeframe.
The Risk Management Committee wants to identify the single largest loan issued for every month in our records. 
This helps them determine if specific months are "heavy-hitting" months that require higher capital reserves.
Objective: Write a query that extracts the month and identifies the absolute largest loan issued within each month.
*/


WITH LOAN_RANKING AS (
SELECT EXTRACT(month FROM issue_date) AS "issuance_month", loan_id, borrower_id, ROUND(loan_amount,2) AS "LoanIssued",
ROW_NUMBER() OVER (PARTITION BY EXTRACT(month FROM issue_date) ORDER BY loan_amount) AS "Loan_Ranking"
FROM LOANS
)
SELECT issuance_month, MAX(Loan_Ranking) AS "Top_Monthly_Amount", MAX(LoanIssued) AS "Amount"
FROM LOAN_RANKING
GROUP BY issuance_month;

-- Another way to do this

WITH LOAN_RANKING AS (
SELECT EXTRACT(month FROM issue_date) AS "issuance_month", loan_id, borrower_id, ROUND(loan_amount,2) AS "LoanIssued",
ROW_NUMBER() OVER (PARTITION BY EXTRACT(month FROM issue_date) ORDER BY loan_amount DESC) AS "Loan_Ranking"
FROM LOANS
)
SELECT*
FROM LOAN_RANKING
WHERE Loan_Ranking = 1;

/*
Scenario 8: In consumer lending, monitoring how a borrower's credit profile transitions from one year 
to the next is key to adjusting risk classifications. Instead of using static column-pivoting techniques, t
he risk team wants to leverage analytical window functions to calculate sequential year-over-year transitions. 
By looking backward to the previous year's snapshot, the bank can dynamically isolate expanding or 
contracting credit profiles across the entire portfolio.
*/
WITH CREDIT_CHANGE_RECORDS AS(
SELECT borrower_id, evaluation_date, fico_score, 
LAG(fico_score,1,fico_score) OVER(PARTITION BY borrower_id ORDER BY evaluation_date) AS "Previous_Year_Score"
FROM CREDIT_SCORES_HISTORY
)
SELECT*, (fico_score - Previous_Year_Score) AS "Credit_Change"
FROM CREDIT_CHANGE_RECORDS









