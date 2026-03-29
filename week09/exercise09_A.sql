USE ROLE GIRAFFE_DATA5035_ROLE;
USE DATABASE DATA5035;
USE SCHEMA GIRAFFE;

-- Exercise 09A: Retail Orders & Customers
-- Approach: SQL (Snowflake)


-- Setup tables

CREATE OR REPLACE TABLE customers (
    customer_id INTEGER,
    name        VARCHAR(50),
    state       VARCHAR(2)
);

INSERT INTO customers VALUES
    (1, 'Alice', 'MO'),
    (2, 'Bob',   'IL'),
    (3, 'Carol', 'TX');

CREATE OR REPLACE TABLE orders (
    order_id    INTEGER,
    customer_id INTEGER,
    order_date  DATE,
    amount      DECIMAL(10,2)
);

INSERT INTO orders VALUES
    (101, 1, '2024-01-01', 100),
    (102, 1, '2024-01-05', 50),
    (103, 2, '2024-01-03', 75);

CREATE OR REPLACE TABLE returns (
    return_id   INTEGER,
    order_id    INTEGER,
    return_date DATE
);

INSERT INTO returns VALUES
    (9001, 102, '2024-01-10');


-- Q1: Show all purchases with the customer who made them
-- Inner join — only customers who have orders
SELECT c.name, o.order_id, o.amount
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id;


-- Q2: Show all customers and any orders they may have placed
-- Left join — keeps Carol even though she has no orders
SELECT c.name, o.order_id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id;


-- Q3: Identify whether each order was returned
-- Left join orders to returns, flag with CASE
SELECT o.order_id,
       CASE WHEN r.return_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_returned
FROM orders o
LEFT JOIN returns r ON r.order_id = o.order_id;


-- Q4: Show only orders that were returned and who made them
-- Inner join across all three tables — only returned orders survive
SELECT c.name, o.order_id, r.return_date
FROM returns r
INNER JOIN orders o ON o.order_id = r.order_id
INNER JOIN customers c ON c.customer_id = o.customer_id;


-- Q5: Find customers who have never made a purchase
-- Anti-join using LEFT JOIN + WHERE NULL
SELECT c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;
