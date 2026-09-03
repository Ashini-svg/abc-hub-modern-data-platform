-- =====================================================================
-- ABC HUB ETL PIPELINE - NIFI PROCESSOR SQL AND DATABASE CONFIGURATION
-- Source: final exported NiFi flow definition
-- Apache NiFi version: 2.11.0
--
-- This file contains the user-authored SQL embedded in the NiFi flow.
-- Where a processor does not contain user-authored SQL (for example
-- PutDatabaseRecord, LogAttribute, or SimpleDatabaseLookupService), the
-- relevant configuration is documented as comments instead of inventing SQL.
-- =====================================================================

-- =====================================================================
-- 01 Extract - Customer Incremental
-- Processor: QueryDatabaseTableRecord
-- Source table: customer
-- Maximum-value / watermark column: updated_at
-- Scheduling: CRON_DRIVEN | 0 0 1 * * ? | PRIMARY
--
-- No Custom Query is configured in this processor.
-- NiFi reads from the customer table and performs incremental extraction
-- using the updated_at maximum-value column.
-- =====================================================================

-- =====================================================================
-- 03 Transform - Customer Clean & Deduplicate
-- Processor: QueryRecord
-- Dynamic relationship/property: clean_customer
-- NOTE: FLOWFILE is NiFi QueryRecord syntax, not a PostgreSQL table.
-- =====================================================================

SELECT
    customer_id,
    first_name,
    last_name,
    LOWER(TRIM(email)) AS email,
    registration_date,
    UPPER(TRIM(status)) AS status
FROM (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        registration_date,
        status,
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(email))
            ORDER BY customer_id
        ) AS rn
    FROM FLOWFILE
    WHERE email IS NOT NULL
      AND TRIM(email) <> ''
) t
WHERE rn = 1;


-- =====================================================================
-- 05 Extract - Content Incremental
-- Processor: QueryDatabaseTableRecord
-- Logical Table Name: content_enriched
-- Maximum-value / watermark column: updated_at
-- Scheduling: CRON_DRIVEN | 0 0 1 * * ? | PRIMARY
-- =====================================================================

SELECT
    c.content_id,
    c.title,
    ct.content_type,
    STRING_AGG(
        DISTINCT g.genre_name,
        ', ' ORDER BY g.genre_name
    ) AS genre,
    c.language,
    c.age_rating,
    c.release_date,

    GREATEST(
        c.updated_at,
        ct.updated_at,
        COALESCE(MAX(cg.updated_at), c.updated_at),
        COALESCE(MAX(g.updated_at), c.updated_at)
    ) AS updated_at

FROM content c

JOIN content_type ct
    ON ct.content_type_id = c.content_type_id

LEFT JOIN content_genre cg
    ON cg.content_id = c.content_id

LEFT JOIN genre g
    ON g.genre_id = cg.genre_id

GROUP BY
    c.content_id,
    c.title,
    ct.content_type,
    c.language,
    c.age_rating,
    c.release_date,
    c.updated_at,
    ct.updated_at;


-- =====================================================================
-- 08 Extract - Inventory Incremental
-- Processor: QueryDatabaseTableRecord
-- Logical Table Name: inventory_enriched
-- Maximum-value / watermark column: updated_at
-- Scheduling: CRON_DRIVEN | 0 0 1 * * ? | PRIMARY
-- =====================================================================

SELECT
    i.inventory_id,
    i.content_id,
    c.title AS content_title,
    i.warehouse_id,
    w.warehouse_name,
    i.item_condition,
    i.status,
    i.purchase_date,
    GREATEST(
        i.updated_at,
        c.updated_at,
        w.updated_at
    ) AS updated_at
FROM inventory_item i
JOIN content c
    ON c.content_id = i.content_id
JOIN warehouse w
    ON w.warehouse_id = i.warehouse_id;


-- =====================================================================
-- 11 Extract - Customer Daily Activity
-- Processor: QueryDatabaseTableRecord
-- Logical Table Name: customer_daily_activity_source
-- Maximum-value / watermark column: updated_at
-- Scheduling: CRON_DRIVEN | 0 0 2 * * ? | PRIMARY
-- =====================================================================

WITH customer_map AS (
    SELECT
        customer_id AS source_customer_id,
        MIN(customer_id) OVER (
            PARTITION BY LOWER(TRIM(email))
        ) AS customer_id
    FROM customer
),

activity_events AS (

    SELECT
        cm.customer_id,
        s.start_time::date AS activity_date,
        1 AS streaming_session_count,
        CASE
            WHEN s.watch_duration IS NOT NULL
                 AND s.watch_duration >= 0
                THEN s.watch_duration
            WHEN s.end_time IS NOT NULL
                 AND s.start_time IS NOT NULL
                 AND s.end_time >= s.start_time
                THEN FLOOR(
                    EXTRACT(EPOCH FROM (s.end_time - s.start_time)) / 60
                )::integer
            ELSE 0
        END AS total_streaming_duration,
        0 AS physical_rental_count,
        0 AS returned_item_count,
        0::numeric AS total_amount_spent,
        0 AS support_ticket_count,
        s.updated_at
    FROM streaming_session s
    JOIN customer_map cm
        ON cm.source_customer_id = s.customer_id

    UNION ALL

    SELECT
        cm.customer_id,
        r.rental_date,
        0, 0, 1, 0,
        0::numeric,
        0,
        r.updated_at
    FROM rental r
    JOIN customer_map cm
        ON cm.source_customer_id = r.customer_id

    UNION ALL

    SELECT
        cm.customer_id,
        r.return_date,
        0, 0, 0, 1,
        0::numeric,
        0,
        r.updated_at
    FROM rental r
    JOIN customer_map cm
        ON cm.source_customer_id = r.customer_id
    WHERE r.return_date IS NOT NULL

    UNION ALL

    SELECT
        cm.customer_id,
        p.payment_date::date,
        0, 0, 0, 0,
        p.amount,
        0,
        p.updated_at
    FROM payment p
    JOIN customer_map cm
        ON cm.source_customer_id = p.customer_id
    WHERE UPPER(TRIM(p.status)) = 'COMPLETED'

    UNION ALL

    SELECT
        cm.customer_id,
        st.opened_date::date,
        0, 0, 0, 0,
        0::numeric,
        1,
        st.updated_at
    FROM support_ticket st
    JOIN customer_map cm
        ON cm.source_customer_id = st.customer_id
)

SELECT
    customer_id,
    CAST(0 AS BIGINT) AS customer_key,
    TO_CHAR(activity_date, 'YYYYMMDD')::integer AS date_key,
    SUM(streaming_session_count)::integer AS streaming_session_count,
    SUM(total_streaming_duration)::integer AS total_streaming_duration,
    SUM(physical_rental_count)::integer AS physical_rental_count,
    SUM(returned_item_count)::integer AS returned_item_count,
    ROUND(SUM(total_amount_spent), 2) AS total_amount_spent,
    SUM(support_ticket_count)::integer AS support_ticket_count,
    MAX(updated_at) AS updated_at
FROM activity_events
WHERE customer_id IS NOT NULL
  AND activity_date IS NOT NULL
GROUP BY customer_id, activity_date;


-- =====================================================================
-- 15 Extract - Content Monthly Performance
-- Processor: QueryDatabaseTableRecord
-- Logical Table Name: content_monthly_performance_source
-- Maximum-value / watermark column: updated_at
-- Scheduling: CRON_DRIVEN | 0 0 2 * * ? | PRIMARY
-- =====================================================================

WITH activity_events AS (

    -- Streaming
    SELECT
        content_id,
        DATE_TRUNC('month', start_time)::date AS activity_month,
        1 AS total_streams,
        0 AS rental_count,
        0::numeric AS revenue_generated,
        NULL::numeric AS rating,
        0 AS wishlist_addition_count,
        updated_at
    FROM streaming_session

    UNION ALL

    -- Physical rentals
    SELECT
        i.content_id,
        DATE_TRUNC('month', r.rental_date)::date,
        0,
        1,
        0::numeric,
        NULL::numeric,
        0,
        r.updated_at
    FROM rental r
    JOIN inventory_item i
        ON i.inventory_id = r.inventory_id

    UNION ALL

    -- Revenue from completed rental payments
    SELECT
        i.content_id,
        DATE_TRUNC('month', p.payment_date)::date,
        0,
        0,
        CASE
            WHEN p.amount >= 0 THEN p.amount
            ELSE 0
        END,
        NULL::numeric,
        0,
        p.updated_at
    FROM payment p
    JOIN rental r
        ON r.rental_id = p.rental_id
    JOIN inventory_item i
        ON i.inventory_id = r.inventory_id
    WHERE p.rental_id IS NOT NULL
      AND UPPER(TRIM(p.status)) = 'COMPLETED'

    UNION ALL

    -- Ratings
    SELECT
        content_id,
        DATE_TRUNC('month', review_date)::date,
        0,
        0,
        0::numeric,
        rating::numeric,
        0,
        updated_at
    FROM review
    WHERE rating IS NOT NULL

    UNION ALL

    -- Wishlist additions
    SELECT
        content_id,
        DATE_TRUNC('month', added_date)::date,
        0,
        0,
        0::numeric,
        NULL::numeric,
        1,
        updated_at
    FROM wishlist
)

SELECT
    content_id,

    CAST(0 AS BIGINT) AS content_key,

    TO_CHAR(activity_month, 'YYYYMM01')::integer AS date_key,

    SUM(total_streams)::integer AS total_streams,

    SUM(rental_count)::integer AS rental_count,

    ROUND(SUM(revenue_generated), 2) AS revenue_generated,

    COALESCE(ROUND(AVG(rating), 2), 0.00) AS average_customer_rating,

    SUM(wishlist_addition_count)::integer
        AS wishlist_addition_count,

    MAX(updated_at) AS updated_at

FROM activity_events

WHERE content_id IS NOT NULL
  AND activity_month IS NOT NULL

GROUP BY
    content_id,
    activity_month;


-- =====================================================================
-- 19 Extract - Inventory Daily Utilisation
-- Processor: QueryDatabaseTableRecord
-- Logical Table Name: inventory_daily_utilisation_source
-- Maximum-value / watermark column: None (full recalculation)
-- Scheduling: CRON_DRIVEN | 0 0 2 * * ? | PRIMARY
-- =====================================================================

WITH bounds AS (
    SELECT
        DATE '2025-01-01' AS start_date,
        GREATEST(
            MAX(i.purchase_date),
            MAX(r.rental_date),
            MAX(r.return_date)
        ) AS end_date
    FROM inventory_item i
    CROSS JOIN rental r
),

calendar AS (
    SELECT
        generate_series(
            start_date,
            end_date,
            INTERVAL '1 day'
        )::date AS activity_date
    FROM bounds
),

inventory_days AS (
    SELECT
        i.inventory_id,
        d.activity_date
    FROM inventory_item i
    JOIN calendar d
      ON d.activity_date >= GREATEST(
            i.purchase_date,
            DATE '2025-01-01'
         )
),

rental_starts AS (
    SELECT
        inventory_id,
        rental_date AS activity_date,
        COUNT(*)::integer AS rental_count
    FROM rental
    GROUP BY inventory_id, rental_date
),

returns AS (
    SELECT
        inventory_id,
        return_date AS activity_date,
        COUNT(*)::integer AS return_count
    FROM rental
    WHERE return_date IS NOT NULL
    GROUP BY inventory_id, return_date
),

occupied_days AS (
    SELECT DISTINCT
        r.inventory_id,
        d::date AS activity_date
    FROM rental r
    CROSS JOIN bounds b
    CROSS JOIN LATERAL generate_series(
        r.rental_date::timestamp,
        (
            COALESCE(r.return_date, b.end_date + 1)
            - INTERVAL '1 day'
        )::timestamp,
        INTERVAL '1 day'
    ) d
)

SELECT
    id.inventory_id,

    CAST(0 AS BIGINT) AS inventory_key,

    TO_CHAR(id.activity_date, 'YYYYMMDD')::integer AS date_key,

    COALESCE(rs.rental_count, 0)::integer
        AS rental_count,

    COALESCE(rt.return_count, 0)::integer
        AS return_count,

    CASE
        WHEN od.inventory_id IS NULL THEN 1
        ELSE 0
    END::integer AS available_days,

    CASE
        WHEN od.inventory_id IS NULL THEN 0.00
        ELSE 100.00
    END::numeric AS utilisation_percentage

FROM inventory_days id

LEFT JOIN rental_starts rs
    ON rs.inventory_id = id.inventory_id
   AND rs.activity_date = id.activity_date

LEFT JOIN returns rt
    ON rt.inventory_id = id.inventory_id
   AND rt.activity_date = id.activity_date

LEFT JOIN occupied_days od
    ON od.inventory_id = id.inventory_id
   AND od.activity_date = id.activity_date;


-- =====================================================================
-- SURROGATE-KEY LOOKUP CONFIGURATION
-- These SimpleDatabaseLookupService controller services do not store
-- user-authored SELECT statements. NiFi generates the lookup internally
-- from the configured table, key column, and value column.
-- =====================================================================

-- ABC Hub - Customer Key Lookup
-- Table: analytics.dim_customer
-- Lookup key column: customer_id
-- Lookup value column: customer_key
-- Cache size: 1000


-- ABC Hub - Content Key Lookup
-- Table: analytics.dim_content
-- Lookup key column: content_id
-- Lookup value column: content_key
-- Cache size: 1000


-- ABC Hub - Inventory Key Lookup
-- Table: analytics.dim_inventory
-- Lookup key column: inventory_id
-- Lookup value column: inventory_key
-- Cache size: 2000


-- =====================================================================
-- LOAD PROCESSOR CONFIGURATION
-- PutDatabaseRecord does not contain standalone user-authored INSERT/UPSERT
-- SQL in this flow. NiFi generates the database statements from the record
-- schema and the configuration below.
-- =====================================================================

-- 04 Load - dim_customer
-- Schema: analytics
-- Table: dim_customer
-- Statement Type: UPSERT
-- Update Keys: customer_id
-- Maximum Batch Size: 1000


-- 06 Load - dim_content
-- Schema: analytics
-- Table: dim_content
-- Statement Type: UPSERT
-- Update Keys: content_id
-- Maximum Batch Size: 1000


-- 09 Load - dim_inventory
-- Schema: analytics
-- Table: dim_inventory
-- Statement Type: UPSERT
-- Update Keys: inventory_id
-- Maximum Batch Size: 1000


-- 13 Load - fact_customer_daily_activity
-- Schema: analytics
-- Table: fact_customer_daily_activity
-- Statement Type: UPSERT
-- Update Keys: customer_key,date_key
-- Maximum Batch Size: 1000


-- 17 Load - fact_content_monthly_performance
-- Schema: analytics
-- Table: fact_content_monthly_performance
-- Statement Type: UPSERT
-- Update Keys: content_key,date_key
-- Maximum Batch Size: 1000


-- 21 Load - fact_inventory_daily_utilisation
-- Schema: analytics
-- Table: fact_inventory_daily_utilisation
-- Statement Type: UPSERT
-- Update Keys: inventory_key,date_key
-- Maximum Batch Size: 1000


-- =====================================================================
-- VALIDATION / LOGGING PROCESSORS
-- The validation processors in the NiFi flow are LogAttribute processors.
-- They do not contain SQL. They log successful FlowFile attributes after
-- each load. Failure/retry paths are routed to:
--     99 Log - Failed Records
-- =====================================================================
