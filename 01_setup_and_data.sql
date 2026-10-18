-- Northstar Logistics: Supply Chain Delivery Performance Analysis
-- Dataset: fictional and created for portfolio practice.
-- Database: PostgreSQL
-- Run this file first.

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    product_id INT NOT NULL REFERENCES products(product_id),
    order_date DATE NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    promised_date DATE NOT NULL,
    delivered_date DATE,
    shipping_cost NUMERIC(10,2) NOT NULL CHECK (shipping_cost >= 0)
);

INSERT INTO customers (customer_id, customer_name, region) VALUES
(1, 'Apex Retail', 'Northeast'),
(2, 'Bright Stores', 'South'),
(3, 'City Market', 'West'),
(4, 'Delta Supplies', 'Northeast'),
(5, 'Evergreen Shop', 'Midwest');

INSERT INTO products (product_id, product_name, category) VALUES
(101, 'Laptop', 'Electronics'),
(102, 'Office Chair', 'Furniture'),
(103, 'Monitor', 'Electronics'),
(104, 'Desk', 'Furniture');

INSERT INTO orders
(order_id, customer_id, product_id, order_date, quantity, unit_price,
 promised_date, delivered_date, shipping_cost)
VALUES
(1001, 1, 101, '2026-01-03', 2, 800.00, '2026-01-08', '2026-01-07', 30.00),
(1002, 2, 102, '2026-01-04', 5, 120.00, '2026-01-09', '2026-01-12', 25.00),
(1003, 3, 103, '2026-01-05', 3, 250.00, '2026-01-10', '2026-01-09', 20.00),
(1004, 1, 104, '2026-01-06', 2, 300.00, '2026-01-11', '2026-01-15', 35.00),
(1005, 4, 101, '2026-01-07', 1, 800.00, '2026-01-12', '2026-01-11', 18.00),
(1006, 5, 102, '2026-01-08', 4, 120.00, '2026-01-13', '2026-01-16', 22.00),
(1007, 2, 103, '2026-01-09', 6, 250.00, '2026-01-14', '2026-01-13', 28.00),
(1008, 3, 104, '2026-01-10', 1, 300.00, '2026-01-15', '2026-01-18', 15.00),
(1009, 4, 102, '2026-01-11', 3, 120.00, '2026-01-16', '2026-01-16', 20.00),
(1010, 5, 101, '2026-01-12', 2, 800.00, '2026-01-17', '2026-01-21', 32.00),
(1011, 1, 103, '2026-01-13', 4, 250.00, '2026-01-18', NULL, 24.00),
(1012, 2, 104, '2026-01-14', 2, 300.00, '2026-01-19', '2026-01-18', 19.00);
