-- Power BI Fact Order Items

/*
Question answered:
  What item-level dataset can support Power BI relationships, filtering, and
  detailed visuals?

Assumptions:
  - Delivered and non-delivered orders are retained so Power BI can analyze
    order status as well as completed sales.
  - Price and freight remain at item level to preserve the fact-table grain.
  - Multiple reviews for one order are averaged before joining.
  - Delivery status is classified only when both delivery dates exist.
  - This is a read-only export for Power BI; it does not create a database table.
*/

WITH order_reviews AS (
	SELECT
		order_id,
		AVG(review_score) AS average_review_score
	FROM cleaned.olist_order_reviews_dataset
	GROUP BY order_id
),
fact_order_items AS (
	SELECT
		order_items.order_id,
		order_items.order_item_id,
		orders.customer_id,
		customers.customer_unique_id,
		order_items.product_id,
		order_items.seller_id,
		orders.order_status,
		orders.order_purchase_timestamp,
		orders.order_delivered_customer_date,
		orders.order_estimated_delivery_date,
		CASE
			WHEN orders.order_delivered_customer_date IS NULL
				OR orders.order_estimated_delivery_date IS NULL
				THEN 'Not classified'
			WHEN orders.order_delivered_customer_date::date < orders.order_estimated_delivery_date::date
				THEN 'Early'
			WHEN orders.order_delivered_customer_date::date = orders.order_estimated_delivery_date::date
				THEN 'On time'
			ELSE 'Late'
		END AS delivery_performance,
		COALESCE(
			NULLIF(TRIM(category_translation.product_category_name_english), ''),
			NULLIF(TRIM(products.product_category_name), ''),
			'Unknown'
		) AS product_category,
		order_items.price,
		order_items.freight_value,
		order_items.price + order_items.freight_value AS total_item_value,
		reviews.average_review_score
	FROM cleaned.olist_order_items_dataset AS order_items
	INNER JOIN cleaned.olist_orders_dataset AS orders
		ON order_items.order_id = orders.order_id
	LEFT JOIN cleaned.olist_customers_dataset AS customers
		ON orders.customer_id = customers.customer_id
	LEFT JOIN cleaned.olist_products_dataset AS products
		ON order_items.product_id = products.product_id
	LEFT JOIN cleaned.product_category_name_translation AS category_translation
		ON products.product_category_name = category_translation.product_category_name
	LEFT JOIN order_reviews AS reviews
		ON orders.order_id = reviews.order_id
)
SELECT
	order_id,
	order_item_id,
	customer_id,
	customer_unique_id,
	product_id,
	seller_id,
	order_status,
	order_purchase_timestamp,
	order_delivered_customer_date,
	order_estimated_delivery_date,
	delivery_performance,
	product_category,
	price,
	freight_value,
	total_item_value,
	average_review_score
FROM fact_order_items
ORDER BY order_purchase_timestamp, order_id, order_item_id;
