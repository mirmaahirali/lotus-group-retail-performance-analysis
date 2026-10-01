-- ============================================================
-- LOTUS GROUP RETAIL ANALYSIS
-- SQL DATA PREPARATION
-- ============================================================
--
-- Purpose:
-- Prepare the retail dataset for downstream SQL analysis
-- and Power BI reporting.
--
-- Preparation workflow:
-- 1. Data Validation
-- 2. Data Cleaning & Standardization
-- 3. Data Transformation
-- 4. Final Validation
--
-- Database: DuckDB
-- ============================================================


-- ============================================================
-- 5.1 DATA VALIDATION
-- ============================================================

-- ------------------------------------------------------------
-- Validate customer uniqueness
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_rows
FROM lotus.main.dim_customers;


-- ------------------------------------------------------------
-- Validate exact duplicate customer records
-- ------------------------------------------------------------

SELECT
    (SELECT COUNT(*)
     FROM lotus.main.dim_customers) AS total_rows,

    (SELECT COUNT(*)
     FROM (
         SELECT DISTINCT *
         FROM lotus.main.dim_customers
     )) AS unique_full_rows,

    (SELECT COUNT(*)
     FROM lotus.main.dim_customers)
    -
    (SELECT COUNT(*)
     FROM (
         SELECT DISTINCT *
         FROM lotus.main.dim_customers
     )) AS exact_duplicate_rows;


-- ------------------------------------------------------------
-- Validate order uniqueness across source tables
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM (
    SELECT order_id
    FROM lotus.main.fact_orders

    UNION ALL

    SELECT order_id
    FROM lotus.main.fact_orders_24
) AS combined_orders;


-- ============================================================
-- 5.2 DATA CLEANING & STANDARDIZATION
-- ============================================================

-- ------------------------------------------------------------
-- Remove exact duplicate customer records
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE lotus.main.dim_customers_clean AS
SELECT DISTINCT *
FROM lotus.main.dim_customers;


-- ------------------------------------------------------------
-- Standardize customer date fields
--
-- birth_date contains both:
--   YYYY-MM-DD
--   DD/MM/YYYY
--
-- registration_date uses:
--   YYYY-MM-DD
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE lotus.main.dim_customers_clean AS
SELECT
    * EXCLUDE (birth_date, registration_date),

    CAST(
        try_strptime(
            birth_date,
            ['%Y-%m-%d', '%d/%m/%Y']
        ) AS DATE
    ) AS birth_date,

    CAST(
        try_strptime(
            registration_date,
            '%Y-%m-%d'
        ) AS DATE
    ) AS registration_date

FROM lotus.main.dim_customers_clean;


-- ------------------------------------------------------------
-- Standardize gender values
-- ------------------------------------------------------------

UPDATE lotus.main.dim_customers_clean
SET gender =
    CASE
        WHEN LOWER(TRIM(gender)) = 'male' THEN 'Male'
        WHEN LOWER(TRIM(gender)) = 'female' THEN 'Female'
        ELSE gender
    END
WHERE LOWER(TRIM(gender)) IN ('male', 'female');


-- ============================================================
-- 5.3 DATA TRANSFORMATION
-- ============================================================

-- ------------------------------------------------------------
-- Combine 2022–2023 and 2024 order tables
-- into a single analytical view
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW lotus.main.fact_orders_all AS
SELECT *
FROM lotus.main.fact_orders

UNION ALL

SELECT *
FROM lotus.main.fact_orders_24;


-- ============================================================
-- 5.4 FINAL VALIDATION
-- ============================================================

-- ------------------------------------------------------------
-- Validate cleaned customer dimension
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_rows
FROM lotus.main.dim_customers_clean;


-- ------------------------------------------------------------
-- Validate unified order dataset
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM lotus.main.fact_orders_all;


-- ------------------------------------------------------------
-- Validate order-detail relationships
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS unmatched_detail_rows
FROM lotus.main.fact_order_details AS d
LEFT JOIN lotus.main.fact_orders_all AS o
    ON d.order_id = o.order_id
WHERE o.order_id IS NULL;