--Who are the top performing sellers based on revenue?
--Which sellers have high order volume but low average review scores?
--What is the revenue contribution of the top 20% of sellers?

--Who are the top performing sellers based on revenue?
WITH total_revenue_by_sellers AS (
    SELECT
        oi.seller_id,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),
ranked_sellers AS (
    SELECT
        seller_id,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS seller_rank
    FROM total_revenue_by_sellers
)
SELECT
    seller_id,
    total_revenue
FROM ranked_sellers
WHERE seller_rank <= 50
ORDER BY total_revenue DESC;


--Which sellers have high order volume but low average review scores?
WITH seller_orders AS (
SELECT
oi.seller_id,
o.order_id
FROM order_items oi
JOIN orders o
ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
),
seller_performance AS (
SELECT
so.seller_id,
COUNT(DISTINCT so.order_id) AS total_orders,
AVG(TRY_CAST(review_score AS INT)) AS avg_review_score
FROM seller_orders so
LEFT JOIN order_reviews orv
ON so.order_id = orv.order_id
GROUP BY so.seller_id
)
SELECT
*
FROM seller_performance
WHERE total_orders > 100
AND avg_review_score < 3.5
ORDER BY total_orders DESC;

--What is the revenue contribution of the top 20% of sellers?
WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        MAX(s.seller_city) AS seller_city,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),
top_sellers AS (
    SELECT TOP 20 PERCENT
        seller_id,
        seller_city,
        total_revenue
    FROM seller_revenue
    ORDER BY total_revenue DESC
),
total_platform_revenue AS (
    SELECT SUM(total_revenue) AS total_revenue
    FROM seller_revenue
)
SELECT
    SUM(ts.total_revenue) AS top_20_pct_revenue,
    MAX(tpr.total_revenue) AS total_revenue,
    SUM(ts.total_revenue) * 100.0 / MAX(tpr.total_revenue) AS percentage_contribution
FROM top_sellers ts
CROSS JOIN total_platform_revenue tpr;
