--What is the average delivery time per state?
--Which states experience the highest delivery time?
--Is there a relationship between late deliveries and low review scores?

--What is the average delivery time per state?
SELECT
c.customer_state,
COUNT(o.order_id) AS total_orders,
AVG(DATEDIFF(DAY,o.order_purchase_timestamp,o.order_delivered_customer_date)) AS avg_delivery_days
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

--Which states experience the highest delivery time?
WITH state_delivery_metrics AS (
    SELECT
        c.customer_state,
        COUNT(o.order_id) AS total_orders,
        AVG(DATEDIFF(DAY, 
            o.order_purchase_timestamp, 
            o.order_delivered_customer_date
        )) AS avg_delivery_days
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY c.customer_state
),
ranked_states AS (
    SELECT
        customer_state,
        total_orders,
        avg_delivery_days,
        RANK() OVER (ORDER BY avg_delivery_days DESC) AS delivery_rank
    FROM state_delivery_metrics
)
SELECT
    customer_state,
    total_orders,
    avg_delivery_days
FROM ranked_states
WHERE delivery_rank <= 10
ORDER BY avg_delivery_days DESC;


--Is there a relationship between late deliveries and low review scores?
WITH delivery_performance AS (
    SELECT
        order_id,
        CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On_Time'
        END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered'
    AND order_estimated_delivery_date IS NOT NULL
    AND order_delivered_customer_date IS NOT NULL
)

SELECT
    dp.delivery_status,
    COUNT(DISTINCT dp.order_id) AS total_orders,
    AVG(CAST(orv.review_score AS INT)) AS avg_review_score,
    COUNT(CASE WHEN orv.review_score <= 3 THEN 1 END) AS low_reviews,
    COUNT(CASE WHEN orv.review_score >= 4 THEN 1 END) AS high_reviews
FROM delivery_performance dp
JOIN order_reviews orv
    ON dp.order_id = orv.order_id
GROUP BY dp.delivery_status
ORDER BY avg_review_score DESC;
