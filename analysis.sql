-- ================================================================
-- analysis.sql
-- The Fulfillment Gap: SQL Analysis of Olist Brazilian E-Commerce
-- Dataset  : 99,441 orders | 9 tables | 2016-2018
-- Database : SQL Server (SSMS) | OlistDB
--
-- Structure:
--   Section 1: Descriptive   (Q1-Q10)  What happened?
--   Section 2: Diagnostic    (D1-D2)   Why did it happen?
--   Section 3: Prescriptive  (P1-P2)   What should we do?
-- ================================================================

USE OlistDB;
GO

-- ================================================================
-- SECTION 1: DESCRIPTIVE ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- Q1: Top 5 Product Categories by Total Revenue
-- Source: SQLQuery8.sql
-- Skills: JOIN (3 tables), GROUP BY, SUM, TOP
-- ----------------------------------------------------------------
SELECT TOP 5
    ct.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2)          AS total_revenue,
    COUNT(DISTINCT oi.order_id)      AS total_orders
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY total_revenue DESC;
-- Finding: health_beauty leads at R$1.26M -- electronics is not top 5


-- ----------------------------------------------------------------
-- Q2: Average Delivery Days by Customer State
-- Source: SQLQuery16.sql
-- Skills: DATEDIFF, AVG, JOIN, WHERE IS NOT NULL
-- ----------------------------------------------------------------
SELECT
    c.customer_state,
    COUNT(o.order_id)                AS delivered_orders,
    AVG(DATEDIFF(DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date)) AS avg_delivery_days
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;
-- Finding: SP = 8 days (best) | RR = 29 days (worst) -- 3.6x gap


-- ----------------------------------------------------------------
-- Q3: Average Order Value (AOV) by Customer State
-- Source: SQLQuery22 (fixed version)
-- Skills: Subquery, SUM then AVG, HAVING
-- Fix note: raw AVG(payment_value) is wrong -- installment orders
-- have multiple rows each. Subquery aggregates per order first.
-- ----------------------------------------------------------------
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id)     AS total_orders,
    ROUND(AVG(pmt.order_total), 2) AS avg_order_value,
    ROUND(SUM(pmt.order_total), 2) AS total_revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN (
    SELECT order_id, SUM(payment_value) AS order_total
    FROM   order_payments
    GROUP BY order_id
) pmt ON o.order_id = pmt.order_id
GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) > 50
ORDER BY avg_order_value DESC;
-- Finding: remote northern states spend ~30% above national average


-- ----------------------------------------------------------------
-- Q4: Monthly Order Volume Trend (2016-2018)
-- Source: SQLQuery13.sql
-- Skills: YEAR(), MONTH(), GROUP BY time components
-- ----------------------------------------------------------------
SELECT
    YEAR(order_purchase_timestamp)  AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*)                        AS total_orders
FROM orders
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
ORDER BY
    order_year,
    order_month;
-- Finding: ~300% growth from Jan 2017 to Aug 2018 peak


-- ----------------------------------------------------------------
-- Q5: Sellers with High Cancellation Rate (above 10%, min 20 orders)
-- Source: SQLQuery15.sql
-- Skills: CASE WHEN inside COUNT, HAVING with two conditions
-- ----------------------------------------------------------------
SELECT TOP 20
    oi.seller_id,
    COUNT(*)                                                    AS total_orders,
    COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END)    AS canceled_orders,
    COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END)
        * 100.0 / COUNT(*)                                     AS cancellation_rate
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY oi.seller_id
HAVING COUNT(*) >= 20
   AND COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END)
       * 100.0 / COUNT(*) > 10
ORDER BY cancellation_rate DESC;
-- Finding: 18 sellers flagged | highest has 42.9% cancellation rate


-- ----------------------------------------------------------------
-- Q6: Average Review Score by Delivery Status
-- Source: SQLQuery18.sql
-- Skills: CASE WHEN grouping, CAST, AVG, JOIN
-- ----------------------------------------------------------------
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late Delivery'
        ELSE 'On Time Delivery'
    END                                   AS delivery_status,
    AVG(CAST(orv.review_score AS FLOAT))  AS avg_review_score,
    COUNT(*)                              AS total_reviews
FROM orders o
JOIN order_reviews orv
    ON o.order_id = orv.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late Delivery'
        ELSE 'On Time Delivery'
    END;
-- Finding: On Time = 4.29 avg | Late = 2.57 avg (-40% satisfaction drop)


-- ----------------------------------------------------------------
-- Q7: Average Delivery Days by State (repeat for screenshots)
-- Source: SQLQuery16.sql
-- ----------------------------------------------------------------
SELECT
    c.customer_state,
    AVG(DATEDIFF(DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date)) AS avg_delivery_days
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days ASC;
-- Finding: best states cluster around Sao Paulo distribution hub


-- ----------------------------------------------------------------
-- Q8: Late vs On-Time Delivery Percentage
-- Source: SQLQuery17.sql
-- Skills: CASE WHEN, scalar subquery for percentage
-- ----------------------------------------------------------------
SELECT
    CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    COUNT(*) AS order_count,
    COUNT(*) * 100.0 / (
        SELECT COUNT(*)
        FROM   orders
        WHERE  order_delivered_customer_date IS NOT NULL
    ) AS percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY
    CASE
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time'
    END;
-- Finding: 91.9% on time | 8.1% late (~7,800 orders)


-- ----------------------------------------------------------------
-- Q9: Late Delivery Impact on Review Score (Core Finding)
-- Source: SQLQuery18.sql
-- Skills: CASE WHEN, JOIN, CAST, AVG
-- ----------------------------------------------------------------
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late Delivery'
        ELSE 'On Time Delivery'
    END                                   AS delivery_status,
    AVG(CAST(orv.review_score AS FLOAT))  AS avg_review_score,
    COUNT(*)                              AS total_reviews
FROM orders o
JOIN order_reviews orv
    ON o.order_id = orv.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late Delivery'
        ELSE 'On Time Delivery'
    END;
-- Finding: On Time 4.29 | Late 2.57 -- 40% satisfaction collapse


-- ----------------------------------------------------------------
-- Q10: Payment Method Breakdown
-- Source: SQLQuery21.sql
-- Skills: GROUP BY, AVG, SUM, ORDER BY aggregate
-- ----------------------------------------------------------------
SELECT
    payment_type,
    COUNT(*)                                           AS total_transactions,
    ROUND(AVG(CAST(payment_installments AS FLOAT)), 1) AS avg_installments,
    ROUND(SUM(payment_value), 2)                       AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;
-- Finding: Credit card 74% | Boleto (cash voucher) 19% | avg 3.4 installments


-- ================================================================
-- SECTION 2: DIAGNOSTIC ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- D1: Which Product Categories Have the Highest Late Delivery Rate?
-- Source: SQLQuery23
-- Skills: Multi-table JOIN, conditional COUNT, HAVING, LEFT JOIN
-- Why: Q8 found 8.1% of orders are late. D1 finds which product
-- types are responsible and checks weight as a root cause.
-- ----------------------------------------------------------------
SELECT TOP 15
    ct.product_category_name_english                               AS category,
    COUNT(*)                                                       AS total_orders,
    COUNT(CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1 END)                                                AS late_orders,
    ROUND(
        COUNT(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 END) * 100.0 / COUNT(*),
    1)                                                             AS late_rate_pct,
    ROUND(AVG(p.product_weight_g) / 1000.0, 2)                   AS avg_weight_kg,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2)                  AS avg_review_score
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
LEFT JOIN order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY ct.product_category_name_english
HAVING COUNT(*) >= 100
ORDER BY late_rate_pct DESC;
-- Finding: heavier categories cluster at top -- weight predicts lateness


-- ----------------------------------------------------------------
-- D2: Does Freight Cost Tier Predict Late Delivery Rate?
-- Source: SQLQuery24
-- Skills: CASE WHEN bucketing, tier grouping, conditional COUNT
-- Why: If cheap shipping options fail more often, the fix is a
-- minimum freight floor for high-risk routes -- not faster trucks.
-- ----------------------------------------------------------------
SELECT
    CASE
        WHEN oi.freight_value < 15  THEN '1_Low     (under R$15)'
        WHEN oi.freight_value < 30  THEN '2_Mid     (R$15-30)'
        WHEN oi.freight_value < 50  THEN '3_High    (R$30-50)'
        ELSE                             '4_Premium (over R$50)'
    END                                                            AS freight_tier,
    COUNT(DISTINCT o.order_id)                                     AS total_orders,
    COUNT(CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1 END)                                                AS late_orders,
    ROUND(
        COUNT(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 END) * 100.0 / COUNT(DISTINCT o.order_id),
    1)                                                             AS late_rate_pct,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2)                  AS avg_review_score,
    ROUND(AVG(oi.freight_value), 2)                               AS avg_freight_brl
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN oi.freight_value < 15  THEN '1_Low     (under R$15)'
        WHEN oi.freight_value < 30  THEN '2_Mid     (R$15-30)'
        WHEN oi.freight_value < 50  THEN '3_High    (R$30-50)'
        ELSE                             '4_Premium (over R$50)'
    END
ORDER BY freight_tier;
-- Finding: low freight tier shows highest late rate and lowest review score


-- ================================================================
-- SECTION 3: PRESCRIPTIVE ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- P1: Recommended Delivery SLA per State (90th Percentile)
-- Source: SQLQuery25
-- Skills: CTE, PERCENTILE_CONT, window functions (SQL Server 2012+)
-- Action: Set recommended_sla_days as the delivery promise per state.
-- ~90% of orders will appear "on time" with no logistics change.
-- ----------------------------------------------------------------
WITH delivery_data AS (
    SELECT
        c.customer_state,
        DATEDIFF(DAY,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date)    AS days_to_deliver,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END                                     AS is_late
    FROM   orders    o
    JOIN   customers c ON o.customer_id = c.customer_id
    WHERE  o.order_status = 'delivered'
      AND  o.order_delivered_customer_date IS NOT NULL
)
SELECT DISTINCT
    customer_state,
    COUNT(*)
        OVER (PARTITION BY customer_state)                      AS delivered_orders,
    ROUND(AVG(days_to_deliver * 1.0)
        OVER (PARTITION BY customer_state), 1)                  AS avg_actual_days,
    ROUND(AVG(is_late * 100.0)
        OVER (PARTITION BY customer_state), 1)                  AS current_late_pct,
    CAST(PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY days_to_deliver)
        OVER  (PARTITION BY customer_state) AS INT)             AS median_days,
    -- Use this column as your new delivery promise per state
    CAST(PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY days_to_deliver)
        OVER  (PARTITION BY customer_state) AS INT)             AS recommended_sla_days
FROM  delivery_data
ORDER BY recommended_sla_days DESC;
-- Action: SP promise 12d (not 8) | RR promise 38d (not 29)
-- Setting 90th percentile as SLA reduces perceived lateness by ~80%


-- ----------------------------------------------------------------
-- P2: Seller Health Score -- Composite Risk Flag
-- Source: SQLQuery26
-- Skills: CTE, composite scoring, ISNULL null-safety, CASE WHEN flag
-- Formula: 100 - (cancel_rate x 2) - (late_rate x 1) + ((avg_review - 3) x 5)
-- Action: Run weekly. Export At Risk sellers to account manager list.
-- ----------------------------------------------------------------
WITH seller_metrics AS (
    SELECT
        oi.seller_id,
        s.seller_state,
        COUNT(DISTINCT o.order_id)                                      AS total_orders,
        ROUND(
            COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END)
            * 100.0 / COUNT(DISTINCT o.order_id),
        1)                                                              AS cancel_rate,
        ROUND(
            COUNT(CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1 END)
            * 100.0 / NULLIF(
                COUNT(CASE
                    WHEN o.order_delivered_customer_date IS NOT NULL
                     AND o.order_estimated_delivery_date IS NOT NULL
                    THEN 1 END),
            0),
        1)                                                              AS late_rate,
        ROUND(AVG(CAST(r.review_score AS FLOAT)), 2)                   AS avg_review
    FROM      order_items   oi
    JOIN      orders        o  ON oi.order_id  = o.order_id
    JOIN      sellers       s  ON oi.seller_id = s.seller_id
    LEFT JOIN order_reviews r  ON o.order_id   = r.order_id
    GROUP BY  oi.seller_id, s.seller_state
    HAVING    COUNT(DISTINCT o.order_id) >= 20
)
SELECT
    seller_id,
    seller_state,
    total_orders,
    cancel_rate,
    ISNULL(late_rate,  0)                                              AS late_rate,
    ISNULL(avg_review, 3)                                              AS avg_review,
    ROUND(
        100.0
        - (cancel_rate                       * 2.0)
        - (ISNULL(late_rate,  0)             * 1.0)
        + ((ISNULL(avg_review, 3.0) - 3.0)  * 5.0),
    1)                                                                 AS health_score,
    CASE
        WHEN ROUND(100.0 - (cancel_rate * 2.0)
                   - (ISNULL(late_rate, 0) * 1.0)
                   + ((ISNULL(avg_review, 3.0) - 3.0) * 5.0), 1) >= 80
             THEN 'Healthy'
        WHEN ROUND(100.0 - (cancel_rate * 2.0)
                   - (ISNULL(late_rate, 0) * 1.0)
                   + ((ISNULL(avg_review, 3.0) - 3.0) * 5.0), 1) >= 55
             THEN 'Monitor'
        ELSE 'At Risk'
    END                                                                AS risk_flag
FROM   seller_metrics
ORDER BY health_score ASC;
-- Action: Filter risk_flag = 'At Risk', assign to account managers


-- ----------------------------------------------------------------
-- P3: Executive KPI Summary Dashboard
-- Source: portfolio summary query
-- Skills: multi-table joins, aggregate KPIs, percentage calculation
-- Purpose: executive snapshot of marketplace performance
-- ----------------------------------------------------------------
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT oi.seller_id) AS total_sellers,
    ROUND(SUM(op.payment_value), 2) AS total_revenue,
    ROUND(AVG(op.payment_value), 2) AS avg_order_value,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_pct

FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN order_payments op
    ON o.order_id = op.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL;

-- Finding:
-- Executive snapshot of marketplace scale, revenue, and delivery performance