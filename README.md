# Credit Card Customer Intelligence & Churn Analytics

## Business Problem
A credit card company has observed increasing customer attrition and wants to better understand its customer base: which segments generate the most value, what drives churn, how spending behavior differs across customers, and which actions could improve retention and profitability.

## Dataset
[BankChurners](https://www.kaggle.com/datasets/sakshigoyal7/credit-card-customers) — 10,127 credit card customers, 21 features (demographics, product usage, transaction behavior) + churn label. Two leaked Naive-Bayes score columns are dropped during cleaning.

## Project Structure
```
churn-analytics/
├── data/
│   ├── raw/                  # original BankChurners.csv
│   └── processed/            # cleaned + feature-engineered dataset
├── notebooks/
│   ├── 01_data_cleaning.ipynb
│   ├── 02_eda.ipynb                 (next)
│   ├── 03_kpi_analysis.ipynb        (next)
│   ├── 04_customer_segmentation.ipynb  (next)
│   ├── 05_sql_analysis.sql          (next)
│   └── 06_churn_prediction.ipynb    (optional, later)
├── dashboard/                # Power BI file
├── reports/                  # executive summary PDF
├── images/plots/
└── requirements.txt
```

## Status
- [x] Phase 1 — Data cleaning & feature engineering
- [ ] Phase 2 — KPI analysis
- [ ] Phase 3 — EDA (demographics, spending, churn drivers)
- [ ] Phase 4 — Customer segmentation
- [ ] Phase 5 — Power BI dashboard
- [ ] Phase 6 — SQL analysis
- [ ] Phase 7 (optional) — Churn prediction model

## Key engineered features
- `Avg_Monthly_Spend` — transaction volume normalized by tenure
- `Utilization_Bucket` — binned utilization ratio for segmentation
- `Inactivity_Rate` — inactive months as a share of the year
- `High_Value_Customer` — rule-based flag (top-quartile spend, controlled utilization)
- `Engagement_Score` — composite of relationship depth, transaction frequency, and inactivity (0-100)

## Baseline numbers (post-cleaning)
- 10,127 customers, 0 nulls, 0 duplicate CLIENTNUMs
- Churn rate: **16.07%** (1,627 attrited / 8,500 existing)