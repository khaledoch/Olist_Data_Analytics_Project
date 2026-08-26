# Review and Delivery Analysis SQL Explanation

This query checks whether delivery performance is related to customer satisfaction. It returns one comparison by delivery category and one monthly review trend.

## 1. Aggregate reviews at order level

```sql
WITH order_reviews AS (
	SELECT
		order_id,
		AVG(review_score) AS average_review_score
	FROM cleaned.olist_order_reviews_dataset
	WHERE review_score IS NOT NULL
	GROUP BY order_id
),
```

- `order_id` identifies the reviewed order.
- `AVG(review_score)` creates one score per order when multiple review rows exist.
- Missing scores are excluded.
- Grouping before the order join prevents review rows from duplicating delivery results.

## 2. Join reviews to delivery outcomes

```sql
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
```

- The join connects each order-level review score to its delivery result.
- `DATE_TRUNC` creates the month used in the trend output.
- The `CASE` expression classifies delivery by calendar date as early, on time, or late.
- Only delivered orders with complete dates are evaluated.

## 3. Compare scores by delivery performance

```sql
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
```

- `COUNT(*)` gives the number of reviewed delivered orders in each group.
- `AVG` calculates the average customer score.
- Scores of `1` or `2` are treated as low reviews.
- The filtered count and percentage measure dissatisfaction within each delivery group.
- The custom `ORDER BY` presents the groups as early, on time, and late.

## 4. Track the monthly review trend

```sql
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
```

- The second statement repeats the CTE definitions because a PostgreSQL CTE exists only for the statement immediately following it.
- Reviews are grouped by purchase month.
- The output tracks average satisfaction and the low-review rate over time.
- The monthly sample count helps distinguish broad trends from very small samples.

## 5. Main interpretation

Late deliveries averaged 2.27 out of 5, compared with 4.29 for early deliveries, and their low-review rate was 62.36% compared with 9.19% for early deliveries. The monthly trend also weakened around late 2017 and early 2018 before improving later. This supports a strong association between delivery reliability and customer satisfaction, but it does not prove that delivery delays were the only cause of poor reviews; product quality, seller performance, and order mix may also contribute.
