-- Lotus Group Retail Analysis
-- Section 6.4: Operational Performance
-- DuckDB

-- 6.4.1 Returns validation
SELECT
    COUNT(*) AS return_rows,
    COUNT(DISTINCT return_id) AS unique_return_ids,
    COUNT(DISTINCT order_id) AS unique_orders_with_returns,
    COUNT(*) - COUNT(DISTINCT return_id) AS duplicate_return_rows
FROM lotus.main.fact_returns;

-- Overall return rate and returned value
SELECT
    COUNT(DISTINCT r.order_id) AS returned_orders,
    SUM(r.return_amount) AS returned_value,
    o.total_orders,
    ROUND(
        COUNT(DISTINCT r.order_id) * 100.0 / o.total_orders,
        2
    ) AS return_rate_pct
FROM lotus.main.fact_returns r
CROSS JOIN (
    SELECT COUNT(DISTINCT order_id) AS total_orders
    FROM lotus.main.fact_orders_all
) o
GROUP BY o.total_orders;

-- Return status
SELECT
    return_status,
    COUNT(*) AS returned_orders,
    SUM(return_amount) AS returned_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS share_of_returns_pct
FROM lotus.main.fact_returns
GROUP BY return_status
ORDER BY returned_orders DESC;

-- Return performance by store
SELECT
    s.store_name,
    s.region,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT r.order_id) AS returned_orders,
    ROUND(
        COUNT(DISTINCT r.order_id) * 100.0
        / COUNT(DISTINCT o.order_id), 2
    ) AS return_rate_pct,
    SUM(r.return_amount) AS returned_value
FROM lotus.main.fact_orders_all o
JOIN lotus.main.dim_stores s ON o.store_id = s.store_id
LEFT JOIN lotus.main.fact_returns r ON o.order_id = r.order_id
GROUP BY s.store_name, s.region
ORDER BY return_rate_pct DESC;

-- Return performance by year
SELECT
    d.year,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT r.order_id) AS returned_orders,
    SUM(r.return_amount) AS returned_value,
    ROUND(
        COUNT(DISTINCT r.order_id) * 100.0
        / COUNT(DISTINCT o.order_id), 2
    ) AS return_rate_pct
FROM lotus.main.fact_orders_all o
JOIN lotus.main.dim_date d ON o.date_id = d.date_id
LEFT JOIN lotus.main.fact_returns r ON o.order_id = r.order_id
GROUP BY d.year
ORDER BY d.year;

-- Return reasons
SELECT
    return_reason,
    COUNT(*) AS returned_orders,
    SUM(return_amount) AS returned_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS share_of_returns_pct
FROM lotus.main.fact_returns
GROUP BY return_reason
ORDER BY returned_orders DESC;

-- 6.4.2 Revenue per employee
-- Aggregate store revenue and employee counts separately to avoid
-- multiplying revenue through a one-to-many employee relationship.
WITH store_revenue AS (
    SELECT
        store_id,
        SUM(total_revenue) AS total_revenue,
        COUNT(DISTINCT order_id) AS total_orders
    FROM lotus.main.fact_orders_all
    GROUP BY store_id
),
store_employees AS (
    SELECT
        store_id,
        COUNT(DISTINCT employee_id) AS total_employees
    FROM lotus.main.dim_employees
    GROUP BY store_id
)
SELECT
    s.store_name,
    s.region,
    se.total_employees,
    sr.total_revenue,
    sr.total_orders,
    ROUND(sr.total_revenue / se.total_employees, 2) AS revenue_per_employee
FROM lotus.main.dim_stores s
JOIN store_revenue sr ON s.store_id = sr.store_id
JOIN store_employees se ON s.store_id = se.store_id
ORDER BY revenue_per_employee DESC;

-- 6.4.3 Ramadan vs non-Ramadan
SELECT
    CASE WHEN d.is_ramadan = 1 THEN 'Ramadan' ELSE 'Non-Ramadan' END AS period,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_sold,
    SUM(od.line_total_revenue) AS total_revenue,
    ROUND(
        SUM(od.line_total_revenue) / COUNT(DISTINCT o.order_id), 2
    ) AS average_order_value
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_date d ON o.date_id = d.date_id
GROUP BY period
ORDER BY period;

-- Ramadan/non-Ramadan results describe an observed association and should
-- not be interpreted as proof that Ramadan caused the sales difference.
