-- NorthStar Logistics | Analysis Queries
-- Run after sql/01_setup_and_data.sql. Execute each SELECT separately.

-- Q1. Executive KPI summary. Revenue is not profit.
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE delivered_date IS NOT NULL) AS completed_deliveries,
    COUNT(*) FILTER (WHERE delivered_date IS NULL) AS undelivered_orders,
    COUNT(*) FILTER (
        WHERE delivered_date IS NOT NULL AND delivered_date > promised_date
    ) AS late_completed_deliveries,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivered_date IS NOT NULL AND delivered_date > promised_date
        ) / NULLIF(COUNT(*) FILTER (WHERE delivered_date IS NOT NULL), 0),
        2
    ) AS late_delivery_rate_pct,
    SUM(quantity * unit_price)::NUMERIC(12,2) AS product_revenue,
    SUM(shipping_cost)::NUMERIC(12,2) AS recorded_shipping_cost
FROM orders;

-- Q2. Delivery status distribution, including undelivered orders.
SELECT
    CASE
        WHEN delivered_date IS NULL THEN 'Not yet delivered'
        WHEN delivered_date > promised_date THEN 'Late'
        WHEN delivered_date = promised_date THEN 'On time'
        ELSE 'Early'
    END AS delivery_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY 1
ORDER BY order_count DESC, delivery_status;

-- Q3. Order-level delivery variance. Positive days_vs_promise means late.
SELECT
    order_id,
    order_date,
    promised_date,
    delivered_date,
    delivered_date - promised_date AS days_vs_promise,
    CASE
        WHEN delivered_date IS NULL THEN 'Not yet delivered'
        WHEN delivered_date > promised_date THEN 'Late'
        WHEN delivered_date = promised_date THEN 'On time'
        ELSE 'Early'
    END AS delivery_status
FROM orders
ORDER BY order_id;

-- Q4. Late completed deliveries only.
SELECT order_id, promised_date, delivered_date,
       delivered_date - promised_date AS days_late
FROM orders
WHERE delivered_date IS NOT NULL
  AND delivered_date > promised_date
ORDER BY days_late DESC, order_id;

-- Q5. Regional delivery performance. Review denominators before interpreting rates.
SELECT
    c.region,
    COUNT(*) FILTER (WHERE o.delivered_date IS NOT NULL) AS completed_deliveries,
    COUNT(*) FILTER (
        WHERE o.delivered_date IS NOT NULL
          AND o.delivered_date > o.promised_date
    ) AS late_deliveries,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.delivered_date IS NOT NULL
              AND o.delivered_date > o.promised_date
        ) / NULLIF(COUNT(*) FILTER (WHERE o.delivered_date IS NOT NULL), 0),
        2
    ) AS late_delivery_rate_pct
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.region
ORDER BY late_delivery_rate_pct DESC NULLS LAST, completed_deliveries DESC;

-- Q6. Revenue and units by product category.
SELECT
    p.category,
    SUM(o.quantity) AS units_sold,
    SUM(o.quantity * o.unit_price)::NUMERIC(12,2) AS product_revenue
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY p.category
ORDER BY product_revenue DESC;

-- Q7. Product ranking using a CTE and window function.
WITH product_sales AS (
    SELECT p.product_id, p.product_name, p.category,
           SUM(o.quantity * o.unit_price)::NUMERIC(12,2) AS product_revenue
    FROM products p
    JOIN orders o ON o.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT product_name, category, product_revenue,
       DENSE_RANK() OVER (ORDER BY product_revenue DESC) AS revenue_rank
FROM product_sales
ORDER BY revenue_rank, product_name;

-- Q8. Customer revenue and order volume.
SELECT
    c.customer_name,
    c.region,
    COUNT(o.order_id) AS order_count,
    SUM(o.quantity * o.unit_price)::NUMERIC(12,2) AS product_revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.region
ORDER BY product_revenue DESC;

-- Q9. Revenue by region and category.
SELECT
    c.region,
    p.category,
    SUM(o.quantity * o.unit_price)::NUMERIC(12,2) AS product_revenue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_id = o.product_id
GROUP BY c.region, p.category
ORDER BY c.region, product_revenue DESC;

-- Q10. Average completed-delivery variance. Negative = early, positive = late.
SELECT ROUND(AVG(delivered_date - promised_date), 2) AS avg_days_vs_promise
FROM orders
WHERE delivered_date IS NOT NULL;

-- Q11. Orders not yet delivered. These should be monitored separately from
-- the late-completed-delivery KPI; the dataset has no reporting/as-of date.
SELECT order_id, order_date, promised_date, quantity, shipping_cost
FROM orders
WHERE delivered_date IS NULL
ORDER BY promised_date, order_id;

-- Q12. Reconciliation: order-level revenue should equal category/product totals.
SELECT
    (SELECT SUM(quantity * unit_price) FROM orders)::NUMERIC(12,2)
        AS order_level_revenue,
    (SELECT SUM(product_revenue)
     FROM (
         SELECT SUM(o.quantity * o.unit_price) AS product_revenue
         FROM orders o
         JOIN products p ON p.product_id = o.product_id
         GROUP BY p.product_id
     ) AS product_totals)::NUMERIC(12,2) AS product_level_revenue;
