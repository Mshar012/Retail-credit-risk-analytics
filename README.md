# Enterprise Credit Risk Analytics & Data Quality Audit Portfolio (SQL)

## Project Overview
This repository contains an end-to-end analytical suite of relational database queries designed to audit, monitor, and model retail lending portfolios. Operating across consumer-lending relational data streams, this project addresses complex business cases including credit risk exposure, time-series velocity tracking, portfolio concentration, and collateral insulation. 

Crucially, this project documents and resolves real-world **ETL ingestion vulnerabilities and type-casting anomalies** that frequently cause silent data loss or bypass standard automation routines in production database pipelines.

---

## Core Analytical Architecture, Findings, & Business Decision Value

### 1. Demographic Risk & Data Gaps (The Collections Bottleneck)
* **Business Objective:** Identify high-vulnerability borrowers (low income) within high-exposure states (CA, IL, FL) who are missing crucial phone records, creating operational blocks for outbound automated dialing queues.
* **Technical Engineering Edge:** Resolved a critical parsing variation where front-end software ingested empty records as zero-length strings (`''`) rather than database literal `NULL` flags, hardening standard `IS NULL` filters.
* **Key Portfolio Findings:** The query successfully flagged vulnerable, low-income accounts completely missing contact records (including profiles like Bob Miller in CA and Grace Lee in IL), while verifying that the state of Florida maintained a flawless contact data integrity rate.
* **Strategic Business Decision:** Allows operations to route these specific high-vulnerability accounts to manual skip-tracing teams or alternative digital/postal outreach campaigns *before* they roll into active delinquency, preserving recovery rates and lowering time-to-resolution.

### 2. Credit Score Drift Trajectory (Conditional Aggregation)
* **Business Objective:** Build an early-warning reporting system identifying "High-Drift" profiles whose credit ratings dropped by more than 20 points year-over-year.
* **Technical Engineering Edge:** Utilized conditional aggregation (`MAX(CASE WHEN...)`) combined with integer year extractions to flatten vertical multi-year history matrices into clean, horizontal analytical grids while bypassing string parsing conflicts.
* **Key Portfolio Findings:** Isolated a distinct cohort of high-drift accounts experiencing severe credit deterioration. The analysis surfaced extreme credit collapse exceptions where individual borrower FICO scores plunged by over 200 points in a 12-month window.
* **Strategic Business Decision:** Empowers the Credit Risk Committee to take preemptive defensive action—such as automatically freezing open lines of credit, lowering revolving line limits, or restricting loan refinancing options on deteriorating accounts before a material default occurs.

### 3. Collateral Cushions & Negative Equity (Loan-to-Value Risk)
* **Business Objective:** Isolate secured credit streams exhibiting severe asset-backing erosion where the total outstanding principal outpaces real-time collateral value (LTV > 100%).
* **Technical Engineering Edge:** Bypassed database order-of-execution limits (the `SELECT` alias execution trap) by mirroring complex numeric operations natively inside the `WHERE` stream and refining outputs using the `ROUND()` function.
* **Key Portfolio Findings:** Successfully surfaced the exact secured accounts trapped in a state of **Negative Equity**, mapping the precise financial dollar gap where the liquidation value of the asset fails to cover the outstanding debt balance.
* **Strategic Business Decision:** Provides the Asset-Liability Management (ALM) team with the exact financial baseline needed to adjust Loss-Given-Default (LGD) capital models, re-evaluate insurance minimums, and implement targeted collateral preservation strategies.

### 4. Data Ingestion Auditing & Silent Row Deletion (ETL Exception Management)
* **Business Objective:** Investigate structural data omissions within transaction logging systems to ensure historical delinquency tracking models remain reliable.
* **Technical Engineering Edge:** Conducted programmatic line-count testing to reveal that MySQL’s strict-mode engine silently rejected invalid blank elements inside standard numeric configurations.
* **Key Portfolio Findings:** Discovered an ETL ingestion drop event where the database engine completely threw out critical ledger transaction records containing blank spaces instead of converting them to standard numeric values, masking active missed payments.
* **Strategic Business Decision:** Drives immediate engineering interventions to implement data normalization and staging pre-validation check pipelines, preventing executive committees from making major credit provisioning and risk-tiering decisions based on incomplete financial logs.

### 5. Guarantor Exposure Tracking (Relational Structural Audit)
* **Business Objective:** Isolate active non-performing loans (`Delinquent` / `Default`) that feature primary secondary signers (co-signers) for secondary legal collections.
* **Technical Engineering Edge:** Developed an inner join linking active contract default flags with co-signer metadata tables.
* **Key Portfolio Findings:** Successfully mapped and isolated all active contract defaults backed by co-signers. The query also uncovered a systemic data generation placeholder pattern where the database records utilized uniform first names ("Sarah") paired with systematic alphanumeric last names.
* **Strategic Business Decision:** Authorizes the Legal and Recovery team to immediately activate co-signer liability clauses for swift financial recourse, while simultaneously initiating an operational data remediation project to fix upstream UAT placeholder data remnants in the production environment.

### 6. Liquidity Forecasting (Chronological Window Accumulation)
* **Business Objective:** Model rolling debt accumulation velocities per asset stream to forecast bank liquidity requirements and asset-liability stress tiers.
* **Technical Engineering Edge:** Configured non-mutating analytical windows (`SUM() OVER`) combined with deterministic frame bounds (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`) to prevent calculating engine variance.
* **Key Portfolio Findings:** Generated an un-aggregated cash flow matrix detailing running liability totals side-by-side with individual entries, exposing how and when capital exposure scales chronologically.
* **Strategic Business Decision:** Gives Treasury precise, transaction-level visibility to project peak overnight funding vulnerabilities and stress-test liquid reserves without relying on lagging, compressed monthly summaries.

### 7. Monthly Vintage Concentration Risk (Analytical Window Ranking)
* **Business Objective:** Monitor underwriting performance stability month-over-month to expose macro-level seasonal concentration risks or systemic softening of underwriting criteria.
* **Technical Engineering Edge:** Nested advanced window functions (`ROW_NUMBER() OVER(PARTITION BY... ORDER BY... DESC)`) within Common Table Expressions (CTEs) to smoothly deduplicate and report out maximum capital deployment vectors per monthly tier.
* **Key Portfolio Findings:** Isolated and extracted the single highest-exposure loan contract deployed within each monthly calendar vintage, exposing seasonal concentration spikes across specific corporate fiscal windows.
* **Strategic Business Decision:** Enables the Portfolio Risk Committee to detect seasonal loosening of underwriting parameters, refine scorecard limits for historically volatile peak months, and enforce automated maximum concentration caps on loan originations during high-risk calendar blocks.

### 8. Sequential Year-over-Year Trajectory Analysis (Window Lookbacks)
* **Business Objective:** Map historical FICO migration pathways row-by-row to model directionality vectors (credit drops vs. credit improvements) directly from sequence logs.
* **Technical Engineering Edge:** Implemented logical window offsets (`LAG()`) partitioned across borrower streams, enabling smooth delta comparisons (`fico_score - Previous_Year_Score`) without launching expensive, non-scalable database self-joins.
* **Key Portfolio Findings:** Programmatically mapped the directional vector (`Credit_Change`) for every borrower across multi-year snapshots—automatically assigning clean baseline parameters to early records while calculating sequential trajectory shifts.
* **Strategic Business Decision:** Synthesizes clear credit-migration inputs for forward-looking credit loss provisioning models (such as CECL or IFRS 9), allowing quantitative risk teams to accurately forecast future credit degradation velocity trends.

---

## Technical Stack & SQL Patterns Exhibited
* **Database Engine Language:** MySQL (Structured for cross-compatibility with PostgreSQL/ANSI compliance)
* **Advanced Query Structures:** Common Table Expressions (CTEs), Subqueries, Self-contained Window Framing, Conditional Aggregations
* **Window Operations:** `SUM() OVER`, `ROW_NUMBER() OVER`, `LAG() OVER`
* **Data Cleansing Metrics:** Multi-conditional string extractions (`SUBSTR`, `EXTRACT`), data type coercion handling, multi-tiered boolean exception routing (`OR`, `IN`, `IS NULL`)

---

## Database Setup & Execution Guide

To reproduce these analytical findings and run the scripts locally, follow this production deployment sequence:

### 1. Schema Initialization
Open your database management tool (e.g., MySQL Workbench) and execute the following commands to construct the target environment:
```sql
CREATE DATABASE RiskAnalysis;
USE RiskAnalysis;
