-- ================================================================
-- verify.sql
-- Post-import row count check
-- Run after import.sql to confirm all tables loaded correctly
-- ================================================================

USE OlistDB;
GO

SELECT COUNT(*) AS customers         FROM customers;         -- expected:  99,441
SELECT COUNT(*) AS orders            FROM orders;            -- expected:  99,441
SELECT COUNT(*) AS products          FROM products;          -- expected:  32,951
SELECT COUNT(*) AS sellers           FROM sellers;           -- expected:   3,095
SELECT COUNT(*) AS order_items       FROM order_items;       -- expected: 112,650
SELECT COUNT(*) AS order_payments    FROM order_payments;    -- expected: 103,886
SELECT COUNT(*) AS order_reviews     FROM order_reviews;     -- expected:  99,224
SELECT COUNT(*) AS category_trans    FROM category_translation; -- expected:     71
GO
