-- ================================================================
-- cleanup.sql
-- WARNING: This permanently drops all data from OlistDB.
-- Use ONLY when resetting the database from scratch.
-- Run schema.sql + import.sql again after this to rebuild.
-- ================================================================

USE OlistDB;
GO

-- Full reset: drop all tables (from SQLQuery5)
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS category_translation;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

-- Individual reset: truncate + drop customers only (from SQLQuery4)
-- Uncomment the two lines below if you only need to reload customers
-- TRUNCATE TABLE customers;
-- DROP TABLE customers;
GO
