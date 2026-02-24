--What payment types are most commonly used?
--Do installment payments correlate with higher order values?
--Which payment methods are associated with lower review scores?

--What payment types are most commonly used?
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) * 100.0 
        / SUM(COUNT(DISTINCT order_id)) OVER () AS percentage_of_orders
FROM order_payments
GROUP BY payment_type
ORDER BY total_orders DESC;

--Do installment payments correlate with higher order values?
WITH order_total AS (
SELECT
order_id,
SUM(payment_value) AS order_total_value,
MAX(payment_installments) AS installments
FROM order_payments
GROUP BY order_id)
SELECT
installments,
AVG(order_total_value) AS avg_order_value,
COUNT(order_id) AS total_orders
FROM order_total
GROUP BY installments
ORDER BY installments DESC;

--Which payment methods are associated with lower review scores?
WITH order_payment_type AS (
    SELECT
        order_id,
        MAX(payment_type) AS payment_type
    FROM order_payments
    GROUP BY order_id
)

SELECT
    opt.payment_type,
    COUNT(opt.order_id) AS total_orders,
    SUM(CASE WHEN ors.review_score <= 3 THEN 1 ELSE 0 END) AS low_rated_orders,
    ROUND(
        SUM(CASE WHEN ors.review_score <= 3 THEN 1 ELSE 0 END) * 100.0 
        / COUNT(opt.order_id),
        2
    ) AS pct_low_rated,
    AVG(CAST(ors.review_score AS FLOAT)) AS avg_review_score
FROM order_payment_type opt
LEFT JOIN order_reviews ors
    ON opt.order_id = ors.order_id
GROUP BY opt.payment_type
ORDER BY pct_low_rated DESC;
