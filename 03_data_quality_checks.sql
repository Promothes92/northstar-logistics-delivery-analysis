-- NorthStar Logistics | Data Quality Checks
-- Run after sql/01_setup_and_data.sql.
-- Expected outcomes are documented in comments; investigate unexpected results.

-- Check 1: table row counts.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
ORDER BY table_name;
-- Expected: customers 5, products 4, orders 12.

-- Check 2: duplicate order identifiers (should return zero rows).
SELECT order_id, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Check 3: missing required values (constraints should prevent these).
SELECT *
FROM orders
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR product_id IS NULL
   OR order_date IS NULL
   OR promised_date IS NULL
   OR quantity IS NULL
   OR unit_price IS NULL;

-- Check 4: date anomalies.
SELECT order_id, order_date, promised_date, delivered_date
FROM orders
WHERE promised_date < order_date
   OR (delivered_date IS NOT NULL AND delivered_date < order_date);

-- Check 5: orphaned foreign keys (constraints should prevent these).
SELECT o.order_id
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN products p ON p.product_id = o.product_id
WHERE c.customer_id IS NULL OR p.product_id IS NULL;

-- Check 6: count of undelivered orders; expected = 1 for this sample.
SELECT COUNT(*) AS undelivered_orders
FROM orders
WHERE delivered_date IS NULL;
