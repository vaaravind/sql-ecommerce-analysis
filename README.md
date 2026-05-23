# The Fulfillment Gap - SQL E-Commerce Analysis

SQL Server  |  Business Intelligence  |  Olist Brazilian E-Commerce Dataset

Key finding: Late deliveries score 2.57 out of 5 on average, compared to 4.29 for
on-time orders. That is a 40 percent satisfaction collapse affecting 8.1 percent of
all delivered orders - roughly 7,800 orders on a platform processing nearly 100,000.

This project runs a three-tier SQL analysis on the real Olist Brazilian e-commerce
dataset. It moves through three stages of questioning - what happened, why it happened,
and what the business should do about it - and follows each finding through to an
actionable recommendation rather than stopping at description.

---

DATASET
-------

Source   : https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
Database : SQL Server Management Studio (SSMS), OlistDB
Period   : 2016 to 2018

Table                    Rows       Description
----------------------------------------------------------------------
customers               99,441     Customer location and unique IDs
orders                  99,441     Full order lifecycle with timestamps
order_items            112,650     Product-level line items and freight
order_payments         103,886     Payment method and installment data
order_reviews           99,224     Star ratings and customer comments
products                32,951     Product dimensions and category names
sellers                  3,095     Seller location by state and city
category_translation        71     Portuguese to English category names

The geolocation dataset was downloaded but is not used in this analysis.
It contains zip-code-level coordinates, which are not required for any
of the queries below.

---

ANALYSIS STRUCTURE
------------------

The queries are organised into three sections inside analysis.sql.
Each section answers a distinct business question.

Section 1 - Descriptive Analysis: What happened?

  Q1   Top 5 product categories by total revenue
  Q2   Average delivery days by customer state, worst first
  Q3   Average order value by state, with a subquery fix for installment rows
  Q4   Monthly order volume trend across 2016 to 2018
  Q5   Sellers with a cancellation rate above 10 percent, minimum 20 orders
  Q6   Average review score grouped by delivery status
  Q7   Average delivery days by state, best first
  Q8   Late versus on-time delivery as a percentage of all delivered orders
  Q9   Late delivery impact on review score - the central finding
  Q10  Payment method breakdown with installment averages

Section 2 - Diagnostic Analysis: Why did it happen?

  D1   Product categories with the highest late delivery rate, with average
       product weight included as a potential predictor
  D2   Freight cost tier versus late delivery rate, using CASE WHEN bucketing
       to test whether low-cost shipping options fail more often

Section 3 - Prescriptive Analysis: What should be done?

  P1   Recommended delivery SLA per state, calculated at the 90th percentile
       of actual delivery time using PERCENTILE_CONT - no logistics change needed
  P2   Seller health score, a composite risk flag combining cancellation rate,
       late delivery rate, and review score into a weekly-runnable output
  P3   Executive KPI summary, a single-row marketplace snapshot covering
       total orders, customers, sellers, revenue, and late delivery rate

---

KEY FINDINGS
------------

Customer Experience

  Late deliveries reduced average review scores from 4.29 to 2.57. Nearly half
  of customer satisfaction disappears when a delivery promise is missed. This is
  not a fringe problem - 8.1 percent of delivered orders arrived late.

Geographic Performance

  Sao Paulo averages 8 delivery days. Roraima averages 29. That is a 3.6x gap
  across the same platform. The states that perform best cluster around the Sao
  Paulo distribution hub. Remote northern states are systematically disadvantaged
  by logistics geography, not by platform failures.

Revenue

  The top three revenue categories are health_beauty, watches_gifts, and
  bed_bath_table. Electronics does not appear in the top five - a counterintuitive
  result worth highlighting in any presentation of this data.

Payments

  Credit card accounts for 74 percent of transactions. Boleto, the Brazilian
  cash voucher system, accounts for 19 percent. The average order uses 3.4
  installments, which means payment_value cannot be averaged directly across
  rows without first aggregating per order - the bug fixed in Q3.

Logistics

  Heavier product categories cluster at the top of the late delivery rankings.
  Low freight tier orders show both the highest late rate and the lowest review
  scores. This points toward a minimum freight floor on high-risk routes as a
  more targeted fix than blanket logistics investment.

Prescriptive output

  Setting the delivery promise at the 90th percentile of actual delivery time
  per state would make roughly 90 percent of orders appear on time with no
  change to physical operations. The SLA correction requires a data update,
  not a logistics overhaul.

  The seller health score flags At Risk sellers for account manager follow-up.
  The formula is: 100 minus (cancellation rate x 2) minus (late rate x 1) plus
  ((average review minus 3) x 5). Run weekly, export where risk_flag = 'At Risk'.

---

EXECUTIVE KPI SNAPSHOT
----------------------

  Total Orders          99,441
  Total Customers       99,441
  Total Sellers          3,095
  Late Delivery Rate      8.1%
  Satisfaction Drop        40%   (from 4.29 to 2.57 on a 5-point scale)

These figures come from P3, the executive summary query at the end of analysis.sql.

---
## Repository Structure

```text
```text
sql-ecommerce-analysis/
│
├── README.md
├── schema.sql
├── import.sql
├── verify.sql
├── analysis.sql
├── cleanup.sql
│
├── 01-top-product-categories.png.jpg
├── 02-average-order-value-by-state.png.jpg
├── 03-monthly-order-trend.png.jpg
├── 04-seller-cancellation-rate.png.jpg
├── 05-average-delivery-time-by-state.png.jpg
├── 06-late-vs-on-time-delivery.png.jpg
├── 07-payment-method-distribution.png.jpg
├── 08-top-revenue-categories.png.jpg
├── 09-category-delivery-performance.png.jpg
├── 10-freight-cost-analysis.png.jpg
├── 11-late-delivery-by-category.png.jpg
├── 12-freight-tier-late-delivery.png.jpg
├── 13-recommended-sla-by-state.png.jpg
├── 14-seller-health-score.png.jpg
└── 15-executive-kpi-summary.png.jpg
```
```
---

SETUP INSTRUCTIONS
------------------

Step 1 - Download the dataset

  Go to: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
  Download all CSV files and save them to a single folder on your machine.
  The raw data files are not included in this repository due to the dataset
  licence (CC BY-NC-SA 4.0). All analysis was run on the original Kaggle files.

Step 2 - Create the database

  Open SSMS and run:

    CREATE DATABASE OlistDB;

Step 3 - Update the file paths in import.sql

  Open import.sql and replace every instance of C:\YOUR_PATH\ with the folder
  where you saved the CSV files. For example:

    C:\Users\YourName\Downloads\OlistData\

Step 4 - Run the SQL files in order

  1. schema.sql     Creates all 8 tables
  2. import.sql     Loads all 8 CSV files
  3. verify.sql     Confirms row counts match expected values
  4. analysis.sql   Runs all 15 analysis queries

  cleanup.sql is provided for a full database reset only. Do not run it as
  part of normal setup.

Step 5 - Verify before running P1

  PERCENTILE_CONT requires SQL Server 2012 or later. Right-click your server
  in SSMS, select Properties, and check the version number. If you are on
  2012 or above, P1 will run without modification.

---

SQL SKILLS DEMONSTRATED
------------------------

  Joins             INNER JOIN, LEFT JOIN across up to 5 tables
  Grouping          GROUP BY, HAVING with multiple conditions
  Logic             CASE WHEN for bucketing, conditional aggregation
  Subqueries        Inline aggregation to fix multi-row payment records
  CTEs              WITH clause for readable multi-step queries
  Window Functions  PERCENTILE_CONT, OVER with PARTITION BY
  Date Functions    DATEDIFF for delivery time calculations
  Null Handling     ISNULL, NULLIF for safe division and defaults
  Type Casting      CAST and CONVERT for score averaging
  Data Loading      BULK INSERT with format options

---

BUSINESS CONTEXT
----------------

The analysis is structured the way a business question is structured, not the way
a SQL tutorial is structured. Descriptive queries establish the baseline. Diagnostic
queries identify the root cause. Prescriptive queries produce an output the business
can act on the same week.

The central finding - that a delivery miss produces a 40 percent satisfaction drop -
is not a statistical footnote. It is a measurable operational failure with a known
fix. The SLA correction in P1 and the seller risk flag in P2 are ready to implement
without any additional data collection.

---

Dataset: Olist, CC BY-NC-SA 4.0
Analysis by V A Aravind
