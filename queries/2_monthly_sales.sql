-- Monthly Sales

/*
Question answered:
  How did completed sales, customer order value, and order activity change
  month by month?

Assumptions:
  - The cleaning script has already been executed and created the cleaned schema.
  - The purchase month is used because it represents when the customer ordered.
  - Delivered orders are used for completed-sales KPIs.
  - Product revenue and freight value are shown separately. Total order value
	is product revenue plus freight value.
  - All order statuses are counted separately for business context, but are not
	included in completed-sales revenue.
  - Payments are not joined here because multiple payment rows could duplicate
	order-item values.
*/

WITH monthly_order_activity AS (
	SELECT
		DATE_TRUNC('month', order_purchase_timestamp)::date AS sales_month,
		COUNT(*) AS all_orders,
		COUNT(*) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
		COUNT(*) FILTER (WHERE order_status = 'canceled') AS canceled_orders,
		COUNT(*) FILTER (WHERE order_status = 'unavailable') AS unavailable_orders,
		COUNT(*) FILTER (
			WHERE order_status NOT IN ('delivered', 'canceled', 'unavailable')
		) AS other_orders
	FROM cleaned.olist_orders_dataset
	GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::date
),
delivered_order_values AS (
	SELECT
		DATE_TRUNC('month', orders.order_purchase_timestamp)::date AS sales_month,
		COUNT(DISTINCT order_items.order_id) AS delivered_orders_with_items,
		COUNT(*) AS items_sold,
		SUM(order_items.price) AS product_revenue,
		SUM(order_items.freight_value) AS freight_value,
		SUM(order_items.price + order_items.freight_value) AS total_order_value
	FROM cleaned.olist_orders_dataset AS orders
	INNER JOIN cleaned.olist_order_items_dataset AS order_items
		ON orders.order_id = order_items.order_id
	WHERE orders.order_status = 'delivered'
	GROUP BY DATE_TRUNC('month', orders.order_purchase_timestamp)::date
)
SELECT
	activity.sales_month,
	activity.all_orders,
	activity.delivered_orders,
	activity.canceled_orders,
	activity.unavailable_orders,
	activity.other_orders,
	COALESCE(order_values.delivered_orders_with_items, 0) AS delivered_orders_with_items,
	COALESCE(order_values.items_sold, 0) AS items_sold,
	COALESCE(order_values.product_revenue, 0.00)::numeric(14, 2) AS product_revenue,
	COALESCE(order_values.freight_value, 0.00)::numeric(14, 2) AS freight_value,
	COALESCE(order_values.total_order_value, 0.00)::numeric(14, 2) AS total_order_value,
	COALESCE(
		order_values.total_order_value / NULLIF(order_values.delivered_orders_with_items, 0),
		0.00
	)::numeric(14, 2) AS average_order_value
FROM monthly_order_activity AS activity
LEFT JOIN delivered_order_values AS order_values
	ON activity.sales_month = order_values.sales_month
ORDER BY activity.sales_month;
