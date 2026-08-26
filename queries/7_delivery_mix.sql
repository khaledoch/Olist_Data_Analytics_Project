-- Delivery Mix

/*
Question answered:
  What is the overall split between early, on-time, and late deliveries?

Assumptions:
  - Only delivered orders with complete delivery dates are included.
  - Delivery status is based on calendar dates, matching the delivery analysis.
  - This is a supporting export for a Power BI delivery-mix visual.
*/

WITH classified_orders AS (
	SELECT
		CASE
			WHEN order_delivered_customer_date::date < order_estimated_delivery_date::date
				THEN 'Early'
			WHEN order_delivered_customer_date::date = order_estimated_delivery_date::date
				THEN 'On time'
			ELSE 'Late'
		END AS delivery_performance
	FROM cleaned.olist_orders_dataset
	WHERE order_status = 'delivered'
		AND order_purchase_timestamp IS NOT NULL
		AND order_delivered_customer_date IS NOT NULL
		AND order_estimated_delivery_date IS NOT NULL
)
SELECT
	delivery_performance,
	COUNT(*) AS delivered_orders,
	ROUND(
		100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
		2
	) AS delivery_share_percent
FROM classified_orders
GROUP BY delivery_performance
ORDER BY
	CASE delivery_performance
		WHEN 'Early' THEN 1
		WHEN 'On time' THEN 2
		WHEN 'Late' THEN 3
	END;