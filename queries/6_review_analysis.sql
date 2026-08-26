-- Review and Delivery Analysis

/*
Question answered:
  Did delivery performance affect customer review scores, especially during
  the late-2017 to early-2018 operational stress period?

Assumptions:
  - Only delivered orders with complete delivery dates are evaluated.
  - Delivery status uses calendar dates: early, on time, or late.
  - Multiple reviews for one order are averaged before joining to orders so
    review rows do not duplicate delivery results.
  - A low review is a score of 1 or 2.
*/

WITH order_reviews AS (
	SELECT
		order_id,
		AVG(review_score) AS average_review_score
	FROM cleaned.olist_order_reviews_dataset
	WHERE review_score IS NOT NULL
	GROUP BY order_id
),
delivered_orders_with_reviews AS (
	SELECT
		DATE_TRUNC('month', orders.order_purchase_timestamp)::date AS review_month,
		CASE
			WHEN orders.order_delivered_customer_date::date < orders.order_estimated_delivery_date::date
				THEN 'early'
			WHEN orders.order_delivered_customer_date::date = orders.order_estimated_delivery_date::date
				THEN 'on_time'
			ELSE 'late'
		END AS delivery_performance,
		reviews.average_review_score
	FROM cleaned.olist_orders_dataset AS orders
	INNER JOIN order_reviews AS reviews
		ON orders.order_id = reviews.order_id
	WHERE orders.order_status = 'delivered'
		AND orders.order_purchase_timestamp IS NOT NULL
		AND orders.order_delivered_customer_date IS NOT NULL
		AND orders.order_estimated_delivery_date IS NOT NULL
)
SELECT
	delivery_performance,
	COUNT(*) AS reviewed_delivered_orders,
	ROUND(AVG(average_review_score)::numeric, 2) AS average_review_score,
	COUNT(*) FILTER (WHERE average_review_score <= 2) AS low_review_orders,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE average_review_score <= 2) / COUNT(*),
		2
	) AS low_review_rate_percent
FROM delivered_orders_with_reviews
GROUP BY delivery_performance
ORDER BY
	CASE delivery_performance
		WHEN 'early' THEN 1
		WHEN 'on_time' THEN 2
		WHEN 'late' THEN 3
	END;

WITH order_reviews AS (
	SELECT
		order_id,
		AVG(review_score) AS average_review_score
	FROM cleaned.olist_order_reviews_dataset
	WHERE review_score IS NOT NULL
	GROUP BY order_id
),
delivered_orders_with_reviews AS (
	SELECT
		DATE_TRUNC('month', orders.order_purchase_timestamp)::date AS review_month,
		reviews.average_review_score
	FROM cleaned.olist_orders_dataset AS orders
	INNER JOIN order_reviews AS reviews
		ON orders.order_id = reviews.order_id
	WHERE orders.order_status = 'delivered'
		AND orders.order_purchase_timestamp IS NOT NULL
		AND orders.order_delivered_customer_date IS NOT NULL
		AND orders.order_estimated_delivery_date IS NOT NULL
)

SELECT
	review_month,
	COUNT(*) AS reviewed_delivered_orders,
	ROUND(AVG(average_review_score)::numeric, 2) AS average_review_score,
	COUNT(*) FILTER (WHERE average_review_score <= 2) AS low_review_orders,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE average_review_score <= 2) / COUNT(*),
		2
	) AS low_review_rate_percent
FROM delivered_orders_with_reviews
GROUP BY review_month
ORDER BY review_month;
