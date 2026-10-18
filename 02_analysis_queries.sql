-- Northstar Logistics: Analysis Queries
-- Run after sql/01_setup_and_data.sql.
-- Review each result and record verified findings in README.md.

-- Q1. Basic data quality checks
SELECT COUNT(*) AS order_rows,
       COUNT(DISTINCT order_id) AS unique_order_ids,
       COUNT(*) FILTER (WHERE delivered_date IS NULL) AS undelivered_orders
FROM orders;

-- Q2. Overall order and product revenue summary
-- Revenue is quantity * unit_price; this is NOT profit.
SELECT COUNT(*) AS total_orders,
       SUM(quantity * unit_price)::NUMERIC(12,2) AS product_revenue,
       SUM(shipping_cost)::NUMERIC(12,2) AS total_shipping_cost
FROM orders;

-- Q3. Identify late delivered orders; exclude orders not yet delivered.
SELECT order_id, promised_date, delivered_date,
       (delivered_date - promised_date) AS days_late
FROM orders
WHERE delivered_date IS NOT NULL
  AND delivered_date > promised_date
ORDER BY days_late DESC, order_id;

-- Q4. Delivery performance summary
-- Denominator includes delivered orders only.
SELECT COUNT(*) FILTER (WHERE delivered_date IS NOT NULL) AS delivered_orders,
       COUNT(*) FILTER (
           WHERE delivered_date IS NOT NULL
             AND delivered_date > promised_date
       ) AS late_delivered_orders,
       ROUND(
           100.0 * COUNT(*) FILTER (
               WHERE delivered_date IS NOT NULL
                 AND delivered_date > promised_date
           ) / NULLIF(COUNT(*) FILTER (WHERE delivered_date IS NOT NULL), 0),
           2
       ) AS late_delivery_rate_pct
FROM orders;

-- Q5. Regional delivery performance
SELECT c.region,
       COUNT(*) FILTER (WHERE o.delivered_date IS NOT NULL) AS delivered_orders,
       COUNT(*) FILTER (
           WHERE o.delivered_date IS NOT NULL
             AND o.delivered_date > o.promised_date
       ) AS late_delivered_orders,
       ROUND(
           100.0 * COUNT(*) FILTER (
               WHERE o.delivered_date IS NOT NULL
                 AND o.delivered_date > o.promised_date
           ) / NULLIF(COUNT(*) FILTER (WHERE o.delivered_date IS NOT NULL), 0),
           2
       ) AS late_delivery_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.region
ORDER BY late_delivery_rate_pct DESC NULLS LAST, c.region;

-- Q6. Revenue by product category
SELECT p.category,
       SUM(o.quantity) AS units_sold,
       SUM(o.quantity * o.unit_price)::NUMERIC(12,2) AS product_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY product_revenue DESC;

-- Q7. Customer-level order and revenue summary
SELECT c.customer_name,
       c.region,
       COUNT(o.order_id) AS order_count,
       SUM(o.quantity * o.unit_price)::NUMERIC(12,2) AS product_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.region
ORDER BY product_revenue DESC;

-- Q8. Rank products by revenue using a window function
WITH product_sales AS (
    SELECT p.product_id, p.product_name, p.category,
           SUM(o.quantity * o.unit_price) AS product_revenue
    FROM products p
    JOIN orders o ON p.product_id = o.product_id
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT product_name, category,
       product_revenue::NUMERIC(12,2) AS product_revenue,
       DENSE_RANK() OVER (ORDER BY product_revenue DESC) AS revenue_rank
FROM product_sales
ORDER BY revenue_rank, product_name;

-- Q9. Order-level delivery status, including undelivered orders
SELECT order_id, promised_date, delivered_date,
       CASE
           WHEN delivered_date IS NULL THEN 'Not yet delivered'
           WHEN delivered_date > promised_date THEN 'Late'
           WHEN delivered_date = promised_date THEN 'On time'
           ELSE 'Early'
       END AS delivery_status
FROM orders
ORDER BY order_id;

-- Q10. Average days early/late for completed deliveries
-- Negative = early; zero = exactly on promised date; positive = late.
SELECT ROUND(AVG(delivered_date - promised_date), 2) AS avg_days_vs_promise
FROM orders
WHERE delivered_date IS NOT NULL;

-- Q11. Optional: product revenue by region
SELECT c.region,
       p.category,
       SUM(o.quantity * o.unit_price)::NUMERIC(12,2) AS product_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.region, p.category
ORDER BY c.region, product_revenue DESC;
