-- Lotus Group Retail Analysis
-- Section 6.3: Customer & Product Performance
-- DuckDB

-- 6.3.1 Customer performance by loyalty tier
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.loyalty_tier,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(od.line_total_revenue) AS revenue
    FROM lotus.main.dim_customers_clean c
    JOIN lotus.main.fact_orders_all o ON c.customer_id = o.customer_id
    JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id, c.loyalty_tier
)
SELECT
    loyalty_tier,
    COUNT(DISTINCT customer_id) AS customers,
    SUM(revenue) AS revenue,
    SUM(orders) AS orders,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer,
    ROUND(SUM(orders) * 1.0 / COUNT(DISTINCT customer_id), 2) AS orders_per_customer,
    ROUND(SUM(revenue) / SUM(orders), 2) AS average_order_value
FROM customer_metrics
GROUP BY loyalty_tier
ORDER BY revenue DESC;

-- 6.3.2 Customer performance by region
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.region,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(od.line_total_revenue) AS revenue
    FROM lotus.main.dim_customers_clean c
    JOIN lotus.main.fact_orders_all o ON c.customer_id = o.customer_id
    JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id, c.region
)
SELECT
    region,
    COUNT(DISTINCT customer_id) AS customers,
    SUM(revenue) AS revenue,
    SUM(orders) AS orders,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer,
    ROUND(SUM(orders) * 1.0 / COUNT(DISTINCT customer_id), 2) AS orders_per_customer,
    ROUND(SUM(revenue) / SUM(orders), 2) AS average_order_value
FROM customer_metrics
GROUP BY region
ORDER BY revenue DESC;

-- 6.3.3 Top 10 customers by revenue
SELECT
    c.full_name,
    c.loyalty_tier,
    c.region,
    SUM(od.line_total_revenue) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(od.quantity) AS units_purchased,
    ROUND(
        SUM(od.line_total_revenue) / COUNT(DISTINCT o.order_id), 2
    ) AS average_order_value
FROM lotus.main.dim_customers_clean c
JOIN lotus.main.fact_orders_all o ON c.customer_id = o.customer_id
JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
GROUP BY c.full_name, c.loyalty_tier, c.region
ORDER BY total_revenue DESC
LIMIT 10;

-- 6.3.4 Customer performance by product category
WITH category_customer_metrics AS (
    SELECT
        p.category,
        c.customer_id,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(od.line_total_revenue) AS revenue
    FROM lotus.main.dim_customers_clean c
    JOIN lotus.main.fact_orders_all o ON c.customer_id = o.customer_id
    JOIN lotus.main.fact_order_details od ON o.order_id = od.order_id
    JOIN lotus.main.dim_products p ON od.product_id = p.product_id
    GROUP BY p.category, c.customer_id
)
SELECT
    category,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(orders) AS total_orders,
    SUM(revenue) AS total_revenue,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer,
    ROUND(SUM(orders) * 1.0 / COUNT(DISTINCT customer_id), 2) AS orders_per_customer
FROM category_customer_metrics
GROUP BY category
ORDER BY total_revenue DESC;
