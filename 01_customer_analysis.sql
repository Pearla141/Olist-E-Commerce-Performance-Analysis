--Who are the top 10 customers by total lifetime value?
--What percentage of customers are repeat customers?
--How does average order value differ between one-time and repeat customers?

--Who are the top 10 customers by total lifetime value?
WITH delivered_orders AS (
SELECT
c.customer_unique_id,
COUNT(DISTINCT o.order_id) AS total_orders,
MAX(c.customer_city) AS customer_city,
SUM(oi.price + oi.freight_value) AS total_lifetime_value
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
)
SELECT TOP 10
customer_unique_id,
customer_city,
total_orders,
total_lifetime_value
FROM delivered_orders
ORDER BY total_lifetime_value DESC;

--What percentage of customers are repeat customers?
WITH total_customer_orders AS (
SELECT
c.customer_unique_id,
COUNT(DISTINCT o.order_id) AS total_counts
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
)
SELECT 
COUNT(CASE WHEN total_counts > 1 THEN customer_unique_id END) AS repeat_customers,
COUNT(*) AS total_customers,
CAST(ROUND(COUNT(CASE WHEN total_counts > 1 THEN customer_unique_id END) * 100.0 / COUNT(*), 2) AS DECIMAL(10,2)) AS pct_of_total_customers
FROM total_customer_orders;

--How does average order value differ between one-time and repeat customers?
WITH order_value AS (
SELECT
c.customer_unique_id,
COUNT(o.order_id) OVER (PARTITION BY c.customer_unique_id) AS total_counts,
SUM(oi.price + oi.freight_value) AS order_value
FROM orders o
JOIN customers c
ON O.customer_id = C.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id,
			o.order_id
)
SELECT
CASE WHEN total_counts = 1 THEN 'one-time customer' 
	 ELSE 'repeat customer' 
END AS  segment,
ROUND(AVG(order_value),2) AS avg_order_value
FROM order_value
GROUP BY CASE WHEN total_counts = 1 THEN 'one-time customer' 
	 ELSE 'repeat customer' 
END;