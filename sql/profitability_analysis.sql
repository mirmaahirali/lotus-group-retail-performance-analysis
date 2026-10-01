-- Lotus Group Retail Analysis
-- Section 6.2: Profitability
-- DuckDB

-- 6.2.1 Overall profitability
SELECT
    SUM(od.line_total_revenue) AS total_revenue,
    SUM(od.line_total_cost) AS total_cost,
    SUM(od.line_total_revenue) - SUM(od.line_total_cost) AS gross_profit,
    ROUND(
        (SUM(od.line_total_revenue) - SUM(od.line_total_cost))
        / SUM(od.line_total_revenue) * 100, 2
    ) AS profit_margin_pct,
    ROUND(
        (SUM(od.line_total_revenue) - SUM(od.line_total_cost))
        / COUNT(DISTINCT o.order_id), 2
    ) AS profit_per_order
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id;

-- 6.2.2 Profitability by product category
SELECT
    p.category,
    SUM(od.line_total_revenue) AS total_revenue,
    SUM(od.line_total_cost) AS total_cost,
    SUM(od.line_total_revenue) - SUM(od.line_total_cost) AS gross_profit,
    ROUND(
        (SUM(od.line_total_revenue) - SUM(od.line_total_cost))
        / SUM(od.line_total_revenue) * 100, 2
    ) AS profit_margin_pct,
    SUM(od.quantity) AS units_sold
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_products p ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY gross_profit DESC;

-- 6.2.3 Profitability by store
SELECT
    s.store_name,
    s.region,
    SUM(od.line_total_revenue) AS total_revenue,
    SUM(od.line_total_cost) AS total_cost,
    SUM(od.line_total_revenue) - SUM(od.line_total_cost) AS gross_profit,
    ROUND(
        (SUM(od.line_total_revenue) - SUM(od.line_total_cost))
        / SUM(od.line_total_revenue) * 100, 2
    ) AS profit_margin_pct,
    ROUND(
        (SUM(od.line_total_revenue) - SUM(od.line_total_cost))
        / COUNT(DISTINCT o.order_id), 2
    ) AS profit_per_order
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_stores s ON o.store_id = s.store_id
GROUP BY s.store_name, s.region
ORDER BY gross_profit DESC;

-- 6.2.4 Top 10 products by gross profit
SELECT
    p.product_name_raw AS product_name,
    SUM(od.line_total_revenue) AS total_revenue,
    SUM(od.line_total_cost) AS total_cost,
    SUM(od.line_total_revenue) - SUM(od.line_total_cost) AS gross_profit,
    ROUND(
        (SUM(od.line_total_revenue) - SUM(od.line_total_cost))
        / SUM(od.line_total_revenue) * 100, 2
    ) AS profit_margin_pct,
    SUM(od.quantity) AS units_sold
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_products p ON od.product_id = p.product_id
GROUP BY p.product_name_raw
ORDER BY gross_profit DESC
LIMIT 10;

-- 6.2.5 Revenue vs profitability: top revenue products
SELECT
    p.product_name_raw AS product_name,
    SUM(od.line_total_revenue) AS total_revenue,
    SUM(od.line_total_revenue) - SUM(od.line_total_cost) AS gross_profit,
    ROUND(
        (SUM(od.line_total_revenue) - SUM(od.line_total_cost))
        / SUM(od.line_total_revenue) * 100, 2
    ) AS profit_margin_pct
FROM lotus.main.fact_orders_all o
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
JOIN lotus.main.dim_products p ON od.product_id = p.product_id
GROUP BY p.product_name_raw
ORDER BY total_revenue DESC
LIMIT 10;

-- Gross profit is Revenue - Product Cost, not net profit.
