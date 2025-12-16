# Banking Customer Feature Engineering (SQL)

## Project Description
Banking Intelligence aims to develop a **supervised machine learning model** to predict future customer behavior based on transactional data and product ownership.

The purpose of this project is to build a **denormalized, customer-level feature table** by engineering behavioral indicators from a normalized banking database using SQL.

This table is designed to be directly used for **training machine learning models** and performing advanced customer analytics.

---

## Project Objective
The main objective is to create a **feature dataset at customer level (`id_cliente`)**, enriched with quantitative and qualitative indicators derived from:
- customer demographics
- owned bank accounts
- transactional behavior

The final output is a persistent table containing one row per customer and multiple engineered features.

---

## Business Value
The denormalized feature table enables several high-impact business applications:

### Customer Behavior Prediction
By analyzing transaction patterns and product ownership, the company can identify behavioral trends and predict future actions such as product adoption or account closure.

### Churn Reduction
Behavioral indicators can be used to identify customers at risk of churn, allowing proactive interventions by marketing and retention teams.

### Risk Management Improvement
Behavior-based segmentation helps identify high-risk customers and optimize credit and risk strategies.

### Offer Personalization
Extracted features allow personalized product and service recommendations based on individual customer habits and preferences, increasing customer satisfaction.

### Fraud Detection
Analyzing transaction volumes and amounts by account type enables the detection of anomalous behaviors that may indicate fraudulent activity.

Overall, this approach improves operational efficiency and supports sustainable business growth.

---

## Database Structure
The relational database includes the following tables:

- `cliente` – customer demographic information
- `conto` – bank accounts owned by customers
- `tipo_conto` – account types
- `transazioni` – financial transactions
- `tipo_transazione` – transaction types and direction (incoming / outgoing)

---

## Engineered Features

### Basic Indicators
- Customer age (derived from date of birth)

### Transaction Indicators (All Accounts)
- Number of outgoing transactions
- Number of incoming transactions
- Total outgoing transaction amount
- Total incoming transaction amount

### Account Indicators
- Total number of owned accounts
- Number of accounts by account type

### Transaction Indicators by Account Type
- Number of outgoing transactions by account type
- Number of incoming transactions by account type
- Total outgoing amount by account type
- Total incoming amount by account type

All indicators are computed at **customer level**.

---

## Feature Engineering Pipeline
The entire pipeline is implemented in SQL and follows these steps:

1. Join normalized tables (`cliente`, `conto`, `transazioni`, `tipo_transazione`)
2. Compute intermediate aggregations using temporary tables
3. Apply conditional aggregations with `CASE WHEN`
4. Handle missing values using `COALESCE`
5. Create a persistent denormalized table

---

## SQL Techniques Used
- Multiple `LEFT JOIN`s
- Temporary tables
- Conditional aggregation (`CASE WHEN`)
- `COUNT` and `SUM`
- `GROUP BY`
- Handling missing values with `COALESCE`
- Denormalization strategy for analytics and ML

---

## Final Output
The final result is a persistent table banca.feature_cliente

