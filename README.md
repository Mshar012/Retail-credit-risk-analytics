# Retail Credit Risk Analytics & Data Quality Audit (SQL)

## Executive Summary
This repository showcases an advanced SQL analytical pipeline designed to audit, monitor, and model credit risk across a consumer lending portfolio. The project simulates a real-world enterprise environment, balancing complex data engineering adjustments with high-level credit risk strategy. 

Instead of basic queries, this portfolio applies **Window Functions, Common Table Expressions (CTEs), and Conditional Aggregations** to uncover portfolio vulnerabilities, evaluate collateral coverage, and diagnose a silent infrastructure-level ETL data loss event.

### 🛠️ Tech Stack & SQL Mastery
* **Language:** MySQL / ANSI SQL
* **Advanced Mechanics:** CTEs (`WITH`), Analytical Window Functions (`OVER`, `PARTITION BY`, `LAG`), Bounded Frames (`ROWS BETWEEN`), Conditional Aggregations (`MAX(CASE WHEN)`)
* **Data Sanitization:** Multi-tiered Boolean logic routing, type-coercion bypasses, and string extractions (`SUBSTR`, `EXTRACT`)

---

## Technical Highlights & Commercial Outcomes

### 1. The ETL Ingestion Audit (Data Infrastructure Loss)
* **The Complexity:** Programmatic integrity testing across transaction tables using runtime line-count verification filters.
* **The Catch:** Uncovered a silent ingestion failure where the import wizard operating under strict SQL parsing modes completely deleted critical historical records containing blank fields for `amount_paid`.
* **Business Decision Value:** Prevents credit provisioning and risk-tiering algorithms from operating on incomplete financial logs, driving the immediate setup of pre-validation data cleansing stages.

### 2. Credit Score Drift & Trajectory Modeling (`LAG()` & `CASE WHEN`)
* **The Complexity:** Deploying `LAG() OVER (PARTITION BY... ORDER BY...)` window lookbacks and conditional `MAX(CASE WHEN...)` matrices to track historical FICO trajectories row-by-row.
* **The Catch:** While monitoring for a baseline 20-point annual drop, the queries isolated severe credit collapse anomalies where individual borrower scores plummeted by over 200 points in a single 12-month window.
* **Business Decision Value:** Empowers risk teams to initiate preemptive defensive actions—automatically freezing revolving open lines of credit and restricting refinancing options before a material default occurs.

### 3. Under-Collateralized Asset Exposure (Loan-to-Value Risk)
* **The Complexity:** Bypassing database order-of-execution limits (the `SELECT` alias filter trap) by mirroring complex mathematical operations inside active `WHERE` filters.
* **The Catch:** Mapped the exact secured loans trapped in **Negative Equity** (LTV > 100%), calculating the precise dollar gap where current asset liquidation values fail to cover outstanding loan balances.
* **Business Decision Value:** Provides the Asset-Liability Management (ALM) team with a targeted baseline to adjust Loss-Given-Default (LGD) capital models and re-allocate minimum insurance reserves.

### 4. Portfolio Concentration & Liquidity Forecasting (`SUM` & `ROW_NUMBER`)
* **The Complexity:** Nesting chronological running totals with explicit window framing (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`) and ranking partitions (`ROW_NUMBER()`) inside multi-layered CTE blocks.
* **The Catch:** Isolated the single highest-exposure loan contract deployed within each monthly vintage, identifying seasonal concentration spikes and uncovering a testing placeholder pattern ("Sarah") inside secondary guarantor systems.
* **Business Decision Value:** Gives Treasury granular, transaction-level visibility to project peak funding vulnerabilities while allowing the Portfolio Risk Committee to enforce automated maximum concentration caps during volatile calendar blocks.

---

## Complete Database Setup & Dataset Ingestion Guide

> ⚠️ **Important:** The raw source datasets required for this project are fully posted and available inside the project directory. To reproduce the analytical findings, you must explicitly import these files into your local SQL engine before running the core analytical scripts.

Follow this complete step-by-step sequence to construct the target environment and ingest the tables properly without facing schema conflicts:

### Step 1: Initialize the Target Schema
Open your database management client (e.g., MySQL Workbench) and execute the setup directive to build the clean database footprint:
```sql
CREATE DATABASE RiskAnalysis;
USE RiskAnalysis;
```

### Step 2: Import the Posted CSV Datasets
Because the relational data schema relies on strict foreign key references and interconnected data types, use the **Table Data Import Wizard** in MySQL Workbench to explicitly import the files. 

Load the posted `.csv` source data files into your schema in this exact structural order:
1. `BORROWERS.csv`
2. `EMPLOYMENT_PROFILES.csv`
3. `LOAN_PRODUCTS.csv`
4. `LOANS.csv`
5. `CREDIT_SCORES_HISTORY.csv`
6. `COLLATERAL_VALUATIONS.csv`
7. `GUARANTORS.csv`
8. `PAYMENT_LEDGER.csv`

*Note on Data Ingestion Audit:* During the step-by-step import of `PAYMENT_LEDGER.csv`, strict SQL type-casting will intentionally exclude completely missed payment records to shield production decimal columns from blank space inputs. This results in an intentional row drop that mimics real-world enterprise infrastructure limits.

### Step 3: Run the Analytical Script Pipeline
Once all the posted datasets are successfully loaded into your local environment, open your script tool, navigate to **File > Open SQL Script...**, select `Analysis.sql`, and execute the file.

The production-ready script will automatically sequence through all business cases, instantly compiling the finalized, metrics-driven credit risk optimization grids directly inside your tool's output console.
