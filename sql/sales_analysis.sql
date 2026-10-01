-- Lotus Group Retail Analysis
-- Section 6.1: Sales Performance
-- DuckDB

-- 6.1.1 Overall sales
SELECT
    SUM(line_total_revenue) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(line_total_revenue) / COUNT(DISTINCT order_id), 2) AS average_order_value
FROM lotus.main.fact_order_details;

-- 6.1.2 Sales by year
SELECT
    d.year,
    SUM(od.line_total_revenue) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_sold,
    ROUND(SUM(od.line_total_revenue) / COUNT(DISTINCT o.order_id), 2) AS average_order_value
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_date d ON o.date_id = d.date_id
GROUP BY d.year
ORDER BY d.year;

-- 6.1.3 Year-over-year revenue growth
WITH yearly_sales AS (
    SELECT
        d.year,
        SUM(od.line_total_revenue) AS total_revenue
    FROM lotus.main.fact_orders_all o
    JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
    JOIN lotus.main.dim_date d ON o.date_id = d.date_id
    GROUP BY d.year
)
SELECT
    year,
    total_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY year))
        / LAG(total_revenue) OVER (ORDER BY year) * 100,
        2
    ) AS yoy_revenue_growth_pct
FROM yearly_sales
ORDER BY year;

-- 6.1.4 Sales by store
SELECT
    s.store_name,
    s.region,
    SUM(od.line_total_revenue) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_sold
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_stores s ON o.store_id = s.store_id
GROUP BY s.store_name, s.region
ORDER BY total_revenue DESC;

-- 6.1.5 Sales by region
SELECT
    s.region,
    SUM(od.line_total_revenue) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_sold
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_stores s ON o.store_id = s.store_id
GROUP BY s.region
ORDER BY total_revenue DESC;

-- 6.1.6 Sales by product category
SELECT
    p.category,
    SUM(od.line_total_revenue) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_sold
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_products p ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Note: category order counts are not additive because an order can
-- contain products from more than one category.

-- 6.1.7 Top 10 products by revenue
SELECT
    p.product_name_raw AS product_name,
    SUM(od.line_total_revenue) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_sold
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_products p ON od.product_id = p.product_id
GROUP BY p.product_name_raw
ORDER BY total_revenue DESC
LIMIT 10;
