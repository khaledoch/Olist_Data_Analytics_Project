-- Category Performance

/*
Question answered:
  Which product categories contribute the most completed sales and customer
  order value?

Assumptions:
  - The cleaning script has already been executed and created the cleaned schema.
  - Only delivered orders represent completed sales.
  - Product revenue and freight value are shown separately. Total order value
	is product revenue plus freight value.
  - Category names use the English translation when available; otherwise, the
	original category name is retained.
  - Products without a category are grouped as 'Unknown'.
*/

WITH category_sales AS (
	SELECT
		COALESCE(
			NULLIF(TRIM(category_translation.product_category_name_english), ''),
			NULLIF(TRIM(products.product_category_name), ''),
			'Unknown'
		) AS product_category,
		COUNT(*) AS items_sold,
		COUNT(DISTINCT order_items.order_id) AS delivered_orders,
		SUM(order_items.price) AS product_revenue,
		SUM(order_items.freight_value) AS freight_value,
		SUM(order_items.price + order_items.freight_value) AS total_order_value
	FROM cleaned.olist_order_items_dataset AS order_items
	INNER JOIN cleaned.olist_orders_dataset AS orders
		ON orders.order_id = order_items.order_id
	LEFT JOIN cleaned.olist_products_dataset AS products
		ON products.product_id = order_items.product_id
	LEFT JOIN cleaned.product_category_name_translation AS category_translation
		ON category_translation.product_category_name = products.product_category_name
	WHERE orders.order_status = 'delivered'
	GROUP BY
		COALESCE(
			NULLIF(TRIM(category_translation.product_category_name_english), ''),
			NULLIF(TRIM(products.product_category_name), ''),
			'Unknown'
		)
)
SELECT
	product_category,
	delivered_orders,
	items_sold,
	product_revenue::numeric(14, 2) AS product_revenue,
	freight_value::numeric(14, 2) AS freight_value,
	total_order_value::numeric(14, 2) AS total_order_value,
	(
		total_order_value / NULLIF(delivered_orders, 0)
	)::numeric(14, 2) AS average_category_order_value
FROM category_sales
ORDER BY total_order_value DESC;
