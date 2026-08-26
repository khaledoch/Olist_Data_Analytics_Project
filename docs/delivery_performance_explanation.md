# Delivery Performance SQL Explanation

This query answers how reliable delivery was and whether delivery performance changed over time. It evaluates delivered orders with complete purchase, actual-delivery, and estimated-delivery dates.

## 1. Prepare delivered-order timing data

```sql
WITH delivered_orders AS (
	SELECT
		DATE_TRUNC('month', order_purchase_timestamp)::date AS sales_month,
		order_purchase_timestamp,
		order_delivered_customer_date,
		order_estimated_delivery_date,
		EXTRACT(
			EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)
		) / 86400.0 AS delivery_days,
		EXTRACT(
			EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date)
		) / 86400.0 AS delay_days
	FROM cleaned.olist_orders_dataset
	WHERE order_status = 'delivered'
		AND order_purchase_timestamp IS NOT NULL
		AND order_delivered_customer_date IS NOT NULL
		AND order_estimated_delivery_date IS NOT NULL
)
```

- `DATE_TRUNC` assigns each order to its purchase month.
- `delivery_days` measures the time between purchase and customer delivery.
- `delay_days` compares actual delivery with the estimated delivery timestamp.
- `EXTRACT(EPOCH)` converts an interval into seconds; dividing by `86400.0` converts seconds into days.
- Only delivered orders with all required dates are included.

## 2. Summarize monthly delivery performance

```sql
SELECT
	sales_month,
	COUNT(*) AS delivered_orders_with_valid_dates,
	ROUND(AVG(delivery_days)::numeric, 2) AS average_delivery_days,
	ROUND(AVG(delay_days) FILTER (
		WHERE order_delivered_customer_date::date < order_estimated_delivery_date::date
	) * -1, 2) AS average_days_early,
	ROUND(AVG(delay_days) FILTER (
		WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date
	), 2) AS average_days_late
```

- `COUNT(*)` is the valid-order denominator for the monthly metrics.
- `AVG(delivery_days)` gives the average customer waiting time.
- The early average filters to deliveries before the estimated calendar date and multiplies by `-1` so it displays as a positive number.
- The late average filters to deliveries after the estimated calendar date and remains positive.
- Early and late averages are calculated only within their relevant groups.

## 3. Count delivery categories and rates

```sql
	COUNT(*) FILTER (WHERE order_delivered_customer_date::date < order_estimated_delivery_date::date) AS early_orders,
	COUNT(*) FILTER (WHERE order_delivered_customer_date::date = order_estimated_delivery_date::date) AS on_time_orders,
	COUNT(*) FILTER (WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date) AS late_orders,
	ROUND(100.0 * COUNT(*) FILTER (
		WHERE order_delivered_customer_date::date < order_estimated_delivery_date::date
	) / COUNT(*), 2) AS early_rate_percent,
	ROUND(100.0 * COUNT(*) FILTER (
		WHERE order_delivered_customer_date::date = order_estimated_delivery_date::date
	) / COUNT(*), 2) AS on_time_rate_percent,
	ROUND(100.0 * COUNT(*) FILTER (
		WHERE order_delivered_customer_date::date > order_estimated_delivery_date::date
	) / COUNT(*), 2) AS late_rate_percent
FROM delivered_orders
GROUP BY sales_month
ORDER BY sales_month;
```

- The three filtered counts classify orders as early, on time, or late.
- The rate expressions divide each category by all valid delivered orders in that month.
- Calendar dates are used deliberately because estimated timestamps are often stored at midnight; comparing full timestamps could incorrectly mark same-day deliveries as late.
- The three counts should equal the valid delivered-order count, while the rates should total approximately 100% after rounding.
- `GROUP BY` and `ORDER BY` produce one chronological row per month.

## 4. Main interpretation

The result measures delivery reliability, not freight cost, carrier cost, profit, or delay-related financial loss. September 2016 is an unreliable benchmark because it contains only one valid delivered order. Among higher-volume periods, March 2018 stands out as a weak delivery month, while the broader project can compare that operational weakness with the financial volatility seen in late 2017.
