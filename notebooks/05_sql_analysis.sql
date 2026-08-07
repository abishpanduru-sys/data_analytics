-- ============================================================
-- 05 — SQL Analysis
-- Credit Card Customer Intelligence & Churn Analytics
--
-- Table: customers  (loaded from data/processed/bankchurners_segmented.csv)
-- Engine used to build/verify this file: SQLite (see data/processed/churn_analytics.db)
-- Note: SQLite has no stored procedures — that section is included as
-- commented pseudo-code showing how it would look in Postgres/SQL Server,
-- since stored procs aren't part of SQLite's feature set.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Top 10 customers by transaction amount
-- ------------------------------------------------------------
SELECT
    CLIENTNUM,
    Attrition_Flag,
    Card_Category,
    Total_Trans_Amt,
    Total_Trans_Ct,
    Customer_Segment
FROM customers
ORDER BY Total_Trans_Amt DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 2. Average utilization ratio by card type
-- ------------------------------------------------------------
SELECT
    Card_Category,
    COUNT(*)                           AS customer_count,
    ROUND(AVG(Avg_Utilization_Ratio), 4) AS avg_utilization,
    ROUND(AVG(Credit_Limit), 2)          AS avg_credit_limit
FROM customers
GROUP BY Card_Category
ORDER BY avg_utilization DESC;


-- ------------------------------------------------------------
-- 3. Ranking customers by spend (dense rank + percentile via NTILE)
-- ------------------------------------------------------------
SELECT
    CLIENTNUM,
    Total_Trans_Amt,
    DENSE_RANK() OVER (ORDER BY Total_Trans_Amt DESC) AS spend_rank,
    NTILE(100) OVER (ORDER BY Total_Trans_Amt)         AS spend_percentile
FROM customers
ORDER BY spend_rank
LIMIT 20;


-- ------------------------------------------------------------
-- 4. Monthly inactivity analysis — churn rate by inactivity level
-- ------------------------------------------------------------
SELECT
    Months_Inactive_12_mon,
    COUNT(*)                                                  AS customer_count,
    SUM(Churn_Flag)                                           AS churned_count,
    ROUND(1.0 * SUM(Churn_Flag) / COUNT(*), 4)                AS churn_rate
FROM customers
GROUP BY Months_Inactive_12_mon
ORDER BY Months_Inactive_12_mon;


-- ------------------------------------------------------------
-- 5. Window function: running average of transaction amount,
--    customers ordered by tenure (Months_on_book)
-- ------------------------------------------------------------
SELECT
    CLIENTNUM,
    Months_on_book,
    Total_Trans_Amt,
    ROUND(AVG(Total_Trans_Amt) OVER (
        ORDER BY Months_on_book
        ROWS BETWEEN 500 PRECEDING AND CURRENT ROW
    ), 2) AS running_avg_trans_amt
FROM customers
ORDER BY Months_on_book
LIMIT 20;


-- ------------------------------------------------------------
-- 6. Percentile customers: top 1% and bottom 1% by revolving balance
--    (a business proxy for revenue, since this dataset has no
--    direct fee/interest column)
-- ------------------------------------------------------------
WITH ranked AS (
    SELECT
        CLIENTNUM,
        Total_Revolving_Bal,
        NTILE(100) OVER (ORDER BY Total_Revolving_Bal) AS pctile
    FROM customers
)
SELECT
    CASE WHEN pctile = 100 THEN 'Top 1%' ELSE 'Bottom 1%' END AS bucket,
    COUNT(*)                                                  AS customer_count,
    ROUND(AVG(Total_Revolving_Bal), 2)                        AS avg_revolving_bal
FROM ranked
WHERE pctile IN (1, 100)
GROUP BY bucket;


-- ------------------------------------------------------------
-- 7. CTE: segment-level churn summary (mirrors notebook 04, in pure SQL)
-- ------------------------------------------------------------
WITH segment_stats AS (
    SELECT
        Customer_Segment,
        COUNT(*)                                   AS customer_count,
        SUM(Churn_Flag)                             AS churned_count,
        ROUND(1.0 * SUM(Churn_Flag) / COUNT(*), 4)  AS churn_rate,
        ROUND(AVG(Total_Trans_Amt), 2)              AS avg_trans_amt,
        ROUND(AVG(Avg_Utilization_Ratio), 4)        AS avg_utilization
    FROM customers
    GROUP BY Customer_Segment
)
SELECT *
FROM segment_stats
ORDER BY churn_rate DESC;


-- ------------------------------------------------------------
-- 8. CTE + window: rank each income bracket's average spend
--    against the overall average (over/under-indexing)
-- ------------------------------------------------------------
WITH income_avg AS (
    SELECT
        Income_Category,
        AVG(Total_Trans_Amt) AS avg_spend
    FROM customers
    GROUP BY Income_Category
),
overall_avg AS (
    SELECT AVG(Total_Trans_Amt) AS overall_avg_spend FROM customers
)
SELECT
    i.Income_Category,
    ROUND(i.avg_spend, 2)                                        AS avg_spend,
    ROUND(o.overall_avg_spend, 2)                                AS overall_avg_spend,
    ROUND(100.0 * (i.avg_spend - o.overall_avg_spend) / o.overall_avg_spend, 1) AS pct_vs_overall
FROM income_avg i, overall_avg o
ORDER BY avg_spend DESC;


-- ------------------------------------------------------------
-- 9. View: a reusable "at-risk watchlist" for the retention team
-- ------------------------------------------------------------
CREATE VIEW IF NOT EXISTS vw_retention_watchlist AS
SELECT
    CLIENTNUM,
    Customer_Segment,
    Months_Inactive_12_mon,
    Contacts_Count_12_mon,
    Avg_Utilization_Ratio,
    Total_Trans_Ct,
    Engagement_Score
FROM customers
WHERE Customer_Segment IN ('Dormant', 'At Risk')
  AND Attrition_Flag = 'Existing Customer';   -- exclude customers who already left

-- Usage:
SELECT * FROM vw_retention_watchlist ORDER BY Engagement_Score ASC LIMIT 15;


-- ------------------------------------------------------------
-- 10. (SQLite has no stored procedures — Postgres/SQL Server equivalent shown
--      as reference for how this would be packaged in a production DB)
-- ------------------------------------------------------------
-- CREATE OR REPLACE PROCEDURE get_segment_churn_summary()
-- LANGUAGE plpgsql AS $$
-- BEGIN
--     -- same logic as query 7 above, callable as CALL get_segment_churn_summary();
-- END;
-- $$;
