# Monthly Sales SQL Explanation

This query answers how completed sales and overall order activity changed month by month. It keeps all order statuses for business context, but calculates sales value from delivered orders only.

## 1. Summarize monthly order activity

```sql
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
```

- `DATE_TRUNC` groups orders by purchase month.
- `COUNT(*)` counts all orders placed in each month.
- The filtered counts separate delivered, canceled, unavailable, and other statuses.
- This section shows demand and order outcomes, not just completed revenue.
- `GROUP BY` creates one row per month.

## 2. Calculate delivered order value

```sql
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
```

- The join connects each delivered order to its item rows, where price and freight are stored.
- `COUNT(DISTINCT order_id)` counts an order once even when it contains several items.
- `COUNT(*)` counts the individual items sold.
- Product revenue and freight are calculated separately.
- Total customer order value combines product price and freight.
- Delivered orders are used because they represent completed business.

## 3. Combine activity and sales value

```sql
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
```

- The `LEFT JOIN` keeps months with order activity even if no delivered item value exists.
- `COALESCE` displays zero instead of `NULL` when a monthly value is missing.
- `NULLIF` prevents division by zero in the average order value calculation.
- Numeric casting formats financial results to two decimal places.
- The result is ordered chronologically.

## 4. Main interpretation

The query allows sales performance to be read together with cancellations and other order outcomes. Its main value is separating completed customer value from broader order activity, so a month with high order volume is not automatically treated as a successful month. It is also useful for comparing the financial instability of late 2017 with the operational and customer-experience changes seen in early 2018.

Payments are not joined because one order can contain multiple payment rows. Joining payments directly to item rows could multiply revenue values.
