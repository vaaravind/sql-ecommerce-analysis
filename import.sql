-- ================================================================
-- import.sql
-- The Fulfillment Gap: Olist E-Commerce SQL Analysis
-- BULK INSERT all 8 CSV files into OlistDB
-- Data source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
--
-- Before running:
--   1. Replace C:\YOUR_PATH\ with your actual download folder
--   2. Make sure OlistDB exists and schema.sql has been run
-- ================================================================

USE OlistDB;
GO

BULK INSERT customers
FROM 'C:\YOUR_PATH\olist_customers_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT orders
FROM 'C:\YOUR_PATH\olist_orders_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT products
FROM 'C:\YOUR_PATH\olist_products_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT sellers
FROM 'C:\YOUR_PATH\olist_sellers_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT order_items
FROM 'C:\YOUR_PATH\olist_order_items_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT order_payments
FROM 'C:\YOUR_PATH\olist_order_payments_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT order_reviews
FROM 'C:\YOUR_PATH\olist_order_reviews_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT category_translation
FROM 'C:\YOUR_PATH\product_category_name_translation.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);
GO
