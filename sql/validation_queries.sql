-- =====================================================================
-- ABC HUB ANALYTICAL DATABASE - VALIDATION QUERIES
-- These queries reproduce the validation evidence used in the final report.
-- Run them against the abc_hub_analytics database.
-- =====================================================================

-- 1. Final row counts for all seven analytical tables
SELECT 'dim_date' AS table_name, COUNT(*) AS row_count
FROM analytics.dim_date
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM analytics.dim_customer
UNION ALL
SELECT 'dim_content', COUNT(*) FROM analytics.dim_content
UNION ALL
SELECT 'dim_inventory', COUNT(*) FROM analytics.dim_inventory
UNION ALL
SELECT 'fact_customer_daily_activity', COUNT(*) FROM analytics.fact_customer_daily_activity
UNION ALL
SELECT 'fact_content_monthly_performance', COUNT(*) FROM analytics.fact_content_monthly_performance
UNION ALL
SELECT 'fact_inventory_daily_utilisation', COUNT(*) FROM analytics.fact_inventory_daily_utilisation;


-- 2. Duplicate-grain validation for the three fact tables
SELECT
    (SELECT COUNT(*)
     FROM (
         SELECT customer_key, date_key
         FROM analytics.fact_customer_daily_activity
         GROUP BY customer_key, date_key
         HAVING COUNT(*) > 1
     ) a) AS customer_daily_duplicates,

    (SELECT COUNT(*)
     FROM (
         SELECT content_key, date_key
         FROM analytics.fact_content_monthly_performance
         GROUP BY content_key, date_key
         HAVING COUNT(*) > 1
     ) b) AS content_monthly_duplicates,

    (SELECT COUNT(*)
     FROM (
         SELECT inventory_key, date_key
         FROM analytics.fact_inventory_daily_utilisation
         GROUP BY inventory_key, date_key
         HAVING COUNT(*) > 1
     ) c) AS inventory_daily_duplicates;


-- 3. Inventory Daily Utilisation business-rule validation
SELECT
    MIN(utilisation_percentage) AS min_utilisation,
    MAX(utilisation_percentage) AS max_utilisation,
    MIN(available_days) AS min_available_days,
    MAX(available_days) AS max_available_days
FROM analytics.fact_inventory_daily_utilisation;


-- 4. Null surrogate-key validation
SELECT
    (SELECT COUNT(*)
     FROM analytics.fact_customer_daily_activity
     WHERE customer_key IS NULL OR date_key IS NULL) AS customer_fact_null_keys,

    (SELECT COUNT(*)
     FROM analytics.fact_content_monthly_performance
     WHERE content_key IS NULL OR date_key IS NULL) AS content_fact_null_keys,

    (SELECT COUNT(*)
     FROM analytics.fact_inventory_daily_utilisation
     WHERE inventory_key IS NULL OR date_key IS NULL) AS inventory_fact_null_keys;


-- 5. Idempotence / row-count check for inventory daily utilisation
-- Run before and after reprocessing the same business-grain FlowFile.
SELECT COUNT(*) AS inventory_daily_row_count
FROM analytics.fact_inventory_daily_utilisation;
