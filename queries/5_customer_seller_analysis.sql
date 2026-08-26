-- Customer and Seller Performance

/*
Question answered:
  Which customer cohorts are the most valuable and repeat-buying, and which
  sellers are driving the most delivered revenue?

Assumptions:
  - Delivered orders are used to measure real customer value and seller impact.
  - A customer cohort is defined by the month of the customer's first purchase.
  - Revenue is based on product price plus freight, matching the revenue logic used
    in the earlier monthly sales analysis.
  - A repeat customer is someone who made more than one delivered order.
  - Seller contribution is measured by delivered revenue generated from items sold.
*/

WITH customer_order_value AS (
	SELECT
		customers.customer_unique_id,
		DATE_TRUNC('month', orders.order_purchase_timestamp)::date AS cohort_month,
		orders.order_id,
		SUM(order_items.price + order_items.freight_value) AS order_value
	FROM cleaned.olist_orders_dataset AS orders
	INNER JOIN cleaned.olist_customers_dataset AS customers
		ON orders.customer_id = customers.customer_id
	INNER JOIN cleaned.olist_order_items_dataset AS order_items
		ON orders.order_id = order_items.order_id
	WHERE orders.order_status = 'delivered'
		AND orders.order_purchase_timestamp IS NOT NULL
		AND customers.customer_unique_id IS NOT NULL
	GROUP BY
		customers.customer_unique_id,
		DATE_TRUNC('month', orders.order_purchase_timestamp)::date,
		orders.order_id
),
customer_cohort_base AS (
	SELECT
		customer_unique_id,
		MIN(cohort_month) AS first_purchase_month,
		COUNT(DISTINCT order_id) AS total_orders,
		SUM(order_value) AS total_customer_revenue
	FROM customer_order_value
	GROUP BY customer_unique_id
),
customer_cohort_summary AS (
	SELECT
		first_purchase_month AS cohort_month,
		COUNT(*) AS cohort_customers,
		COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
		ROUND(AVG(total_orders)::numeric, 2) AS avg_orders_per_customer,
		ROUND(AVG(total_customer_revenue)::numeric, 2) AS avg_revenue_per_customer,
		ROUND(SUM(total_customer_revenue)::numeric, 2) AS total_cohort_revenue,
		ROUND(
			100.0 * COUNT(*) FILTER (WHERE total_orders > 1) / COUNT(*),
			2
		) AS repeat_customer_rate_percent
	FROM customer_cohort_base
	GROUP BY first_purchase_month
)
SELECT
	cohort_month,
	cohort_customers,
	repeat_customers,
	avg_orders_per_customer,
	avg_revenue_per_customer,
	total_cohort_revenue,
	repeat_customer_rate_percent
FROM customer_cohort_summary
ORDER BY cohort_month;

WITH seller_order_value AS (
	SELECT
		order_items.seller_id,
		orders.order_id,
		SUM(order_items.price + order_items.freight_value) AS order_value
	FROM cleaned.olist_order_items_dataset AS order_items
	INNER JOIN cleaned.olist_orders_dataset AS orders
		ON order_items.order_id = orders.order_id
	WHERE orders.order_status = 'delivered'
	GROUP BY order_items.seller_id, orders.order_id
),
seller_summary AS (
	SELECT
		seller_id,
		COUNT(DISTINCT order_id) AS delivered_orders,
		ROUND(SUM(order_value)::numeric, 2) AS total_seller_revenue,
		ROUND(AVG(order_value)::numeric, 2) AS avg_order_value
	FROM seller_order_value
	GROUP BY seller_id
)
SELECT
	seller_id,
	delivered_orders,
	total_seller_revenue,
	avg_order_value
FROM seller_summary
ORDER BY total_seller_revenue DESC, delivered_orders DESC
LIMIT 15;
