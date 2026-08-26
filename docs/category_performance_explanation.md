# Category Performance SQL Explanation

This query answers which product categories generate the most completed sales and customer order value. It uses delivered orders and keeps product revenue separate from freight value.

## 1. Build the category summary

```sql
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
```

- `COALESCE` prefers the English category name, then the original name, then `Unknown`.
- `NULLIF` and `TRIM` treat blank category values as missing.
- `COUNT(*)` counts item rows sold in each category.
- `COUNT(DISTINCT order_id)` counts delivered orders once within each category.
- The three `SUM` expressions calculate product revenue, freight, and total customer order value.

## 2. Join products, orders, and categories

```sql
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
```

- The item table is the starting point because it contains price, freight, and product IDs.
- The inner join keeps only items attached to known orders.
- The product join adds the category name without removing items that lack product details.
- The translation join adds readable English category names when available.
- The delivered filter limits the analysis to completed transactions.
- `GROUP BY` creates one summary row per final category label.

## 3. Format and rank the result

```sql
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
```

- The selected columns show category volume, revenue, freight, and average order value.
- `NULLIF` prevents division by zero for the category average.
- Numeric casting formats financial values to two decimal places.
- Ordering by total order value ranks categories by their contribution to completed customer value.

## 4. Main interpretation

The result identifies which categories matter most commercially, rather than treating every category equally. A category can lead because it has many items, high-priced products, or both, so total order value should be read together with item volume and average category order value. The output also provides a strong foundation for a later top-category chart in Excel, Python, or Power BI.
