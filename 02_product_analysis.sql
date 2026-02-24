--What are the top 10 product categories bt total revenue?
--Which products generate high revenue but low volume order?
--How does monthly revenue trend over time

--What are the top 10 product categories bt total revenue?
WITH revenue_by_categories AS (
SELECT
pcnt.product_category_name_english,
oi.price + oi.freight_value AS revenue
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
JOIN product_category_name_translation pcnt
ON p.product_category_name = pcnt.product_category_name
WHERE o.order_status = 'delivered'
)
SELECT TOP 10
product_category_name_english,
SUM(revenue) AS total_revenue,
RANK() OVER (ORDER BY SUM(revenue) DESC) AS product_rank
FROM revenue_by_categories
GROUP BY product_category_name_english
ORDER BY total_revenue DESC;

--Which products generate high revenue but low volume order?
WITH product_metrics AS (
SELECT
p.product_id,
COUNT(DISTINCT o.order_id) AS total_order,
SUM(oi.price + oi.freight_value) AS total_revenue
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id
), 
averages AS (
SELECT
AVG(total_order) AS avg_order,
AVG(total_revenue) AS avg_revenue
FROM product_metrics
)
SELECT
pm.product_id,
pm.total_order,
pm.total_revenue
FROM product_metrics pm
CROSS JOIN averages a
WHERE pm.total_revenue > a.avg_revenue 
AND pm.total_order < a.avg_order
ORDER BY pm.total_revenue DESC;


 --How does monthly revenue trend over time

WITH monthly_revenue AS 
( 
SELECT 
DATEADD(MONTH,DATEDIFF(MONTH,0,o.order_purchase_timestamp),0) AS purchase_month, 
SUM(oi.price + oi.freight_value) AS revenue 
FROM orders o 
JOIN order_items oi 
ON o.order_id = oi.order_id WHERE o.order_status = 'delivered' 
GROUP BY DATEADD(MONTH,DATEDIFF(MONTH,0,o.order_purchase_timestamp),0) ),
revenue_with_lag AS (
    SELECT
        purchase_month,
        revenue,
        LAG(revenue) OVER (ORDER BY purchase_month) AS previous_revenue
    FROM monthly_revenue
)
SELECT
    purchase_month,
    revenue,
    previous_revenue,
    (revenue - previous_revenue) * 100.0 
    / NULLIF(previous_revenue, 0) AS month_over_month_growth
FROM revenue_with_lag
ORDER BY purchase_month;
