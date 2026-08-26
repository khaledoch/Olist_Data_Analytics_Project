-- Delivery Performance

/*
Question answered:
  How reliable was delivery, and did delivery delays change over time?

Assumptions:
  - The cleaning script has already been executed and created the cleaned schema.
  - Only delivered orders are evaluated for delivery performance.
  - The purchase month is used to stay consistent with the monthly sales analysis.
	- A delivery is early when its calendar date is before the estimated date,
		on time when the calendar dates match, and late when its calendar date is
		after the estimate.
  - Orders missing a purchase, actual delivery, or estimated delivery date are
	excluded from timing metrics rather than treated as on time.
*/

WITH delivered_orders AS (
	SELECT
		DATE_TRUNC('month', order_purchase_timestamp)::date AS sales_month,
		order_purchase_timestamp,
		order_delivered_customer_date,
		order_estimated_delivery_date,
		EXTRACT(
			EPOCH FROM (
				order_delivered_customer_date - order_purchase_timestamp
			)
		) / 86400.0 AS delivery_days,
		EXTRACT(
			EPOCH FROM (
				order_delivered_customer_date - order_estimated_delivery_date
			)
		) / 86400.0 AS delay_days
	FROM cleaned.olist_orders_dataset
	WHERE order_status = 'delivered'
		AND order_purchase_timestamp IS NOT NULL
		AND order_delivered_customer_date IS NOT NULL
		AND order_estimated_delivery_date IS NOT NULL
)
SELECT
	sales_month,
	COUNT(*) AS delivered_orders_with_valid_dates,
	ROUND(AVG(delivery_days)::numeric, 2) AS average_delivery_days,
	ROUND(
		AVG(delay_days) FILTER (
			WHERE order_delivered_customer_date::date < order_estimated_delivery_date::date
		) * -1,
		2
	) AS average_days_early,
	ROUND(
		AVG(delay_days) FILTER (
			WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date
		),
		2
	) AS average_days_late,
	COUNT(*) FILTER (
		WHERE order_delivered_customer_date::date < order_estimated_delivery_date::date
	) AS early_orders,
	COUNT(*) FILTER (
		WHERE order_delivered_customer_date::date = order_estimated_delivery_date::date
	) AS on_time_orders,
	COUNT(*) FILTER (
		WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date
	) AS late_orders,
	ROUND(
		100.0 * COUNT(*) FILTER (
			WHERE order_delivered_customer_date::date < order_estimated_delivery_date::date
		) / COUNT(*),
		2
	) AS early_rate_percent,
	ROUND(
		100.0 * COUNT(*) FILTER (
			WHERE order_delivered_customer_date::date = order_estimated_delivery_date::date
		) / COUNT(*),
		2
	) AS on_time_rate_percent,
	ROUND(
		100.0 * COUNT(*) FILTER (
			WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date
		) / COUNT(*),
		2
	) AS late_rate_percent
FROM delivered_orders
GROUP BY sales_month
ORDER BY sales_month;
