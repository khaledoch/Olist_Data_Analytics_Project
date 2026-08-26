-- Clean Olist Dataset

/*
Question answered:
  How can the nine loaded Olist tables be made consistent and analysis-ready?

Assumptions:
  - The loader created the raw tables in the public schema using the CSV names.
  - Blank strings represent missing values and should become NULL.
  - ZIP prefixes are identifiers, so they stay as text to preserve leading zeroes.
  - Exact duplicate rows are removed; otherwise, the source grain is preserved.
  - The raw tables are not modified. Cleaned copies are recreated in schema cleaned.
*/

CREATE SCHEMA IF NOT EXISTS cleaned;

DROP TABLE IF EXISTS cleaned.olist_customers_dataset CASCADE;
CREATE TABLE cleaned.olist_customers_dataset AS
SELECT DISTINCT
	NULLIF(TRIM(customer_id::text), '') AS customer_id,
	NULLIF(TRIM(customer_unique_id::text), '') AS customer_unique_id,
	NULLIF(TRIM(customer_zip_code_prefix::text), '') AS customer_zip_code_prefix,
	NULLIF(TRIM(customer_city::text), '') AS customer_city,
	NULLIF(TRIM(customer_state::text), '') AS customer_state
FROM public.olist_customers_dataset;

DROP TABLE IF EXISTS cleaned.olist_geolocation_dataset CASCADE;
CREATE TABLE cleaned.olist_geolocation_dataset AS
SELECT DISTINCT
	NULLIF(TRIM(geolocation_zip_code_prefix::text), '') AS geolocation_zip_code_prefix,
	geolocation_lat::numeric AS geolocation_lat,
	geolocation_lng::numeric AS geolocation_lng,
	NULLIF(TRIM(geolocation_city::text), '') AS geolocation_city,
	NULLIF(TRIM(geolocation_state::text), '') AS geolocation_state
FROM public.olist_geolocation_dataset;

DROP TABLE IF EXISTS cleaned.olist_orders_dataset CASCADE;
CREATE TABLE cleaned.olist_orders_dataset AS
SELECT DISTINCT
	NULLIF(TRIM(order_id::text), '') AS order_id,
	NULLIF(TRIM(customer_id::text), '') AS customer_id,
	NULLIF(TRIM(order_status::text), '') AS order_status,
	NULLIF(TRIM(order_purchase_timestamp::text), '')::timestamp AS order_purchase_timestamp,
	NULLIF(TRIM(order_approved_at::text), '')::timestamp AS order_approved_at,
	NULLIF(TRIM(order_delivered_carrier_date::text), '')::timestamp AS order_delivered_carrier_date,
	NULLIF(TRIM(order_delivered_customer_date::text), '')::timestamp AS order_delivered_customer_date,
	NULLIF(TRIM(order_estimated_delivery_date::text), '')::timestamp AS order_estimated_delivery_date
FROM public.olist_orders_dataset;

DROP TABLE IF EXISTS cleaned.olist_order_items_dataset CASCADE;
CREATE TABLE cleaned.olist_order_items_dataset AS
SELECT DISTINCT
	NULLIF(TRIM(order_id::text), '') AS order_id,
	order_item_id::integer AS order_item_id,
	NULLIF(TRIM(product_id::text), '') AS product_id,
	NULLIF(TRIM(seller_id::text), '') AS seller_id,
	NULLIF(TRIM(shipping_limit_date::text), '')::timestamp AS shipping_limit_date,
	price::numeric(12, 2) AS price,
	freight_value::numeric(12, 2) AS freight_value
FROM public.olist_order_items_dataset;

DROP TABLE IF EXISTS cleaned.olist_order_payments_dataset CASCADE;
CREATE TABLE cleaned.olist_order_payments_dataset AS
SELECT DISTINCT
	NULLIF(TRIM(order_id::text), '') AS order_id,
	payment_sequential::integer AS payment_sequential,
	NULLIF(TRIM(payment_type::text), '') AS payment_type,
	payment_installments::integer AS payment_installments,
	payment_value::numeric(12, 2) AS payment_value
FROM public.olist_order_payments_dataset;

DROP TABLE IF EXISTS cleaned.olist_order_reviews_dataset CASCADE;
CREATE TABLE cleaned.olist_order_reviews_dataset AS
SELECT DISTINCT
	NULLIF(TRIM(review_id::text), '') AS review_id,
	NULLIF(TRIM(order_id::text), '') AS order_id,
	review_score::integer AS review_score,
	NULLIF(TRIM(review_comment_title::text), '') AS review_comment_title,
	NULLIF(TRIM(review_comment_message::text), '') AS review_comment_message,
	NULLIF(TRIM(review_creation_date::text), '')::timestamp AS review_creation_date,
	NULLIF(TRIM(review_answer_timestamp::text), '')::timestamp AS review_answer_timestamp
FROM public.olist_order_reviews_dataset;

DROP TABLE IF EXISTS cleaned.olist_products_dataset CASCADE;
CREATE TABLE cleaned.olist_products_dataset AS
SELECT DISTINCT
	NULLIF(TRIM(product_id::text), '') AS product_id,
	NULLIF(TRIM(product_category_name::text), '') AS product_category_name,
	product_name_lenght::integer AS product_name_lenght,
	product_description_lenght::integer AS product_description_lenght,
	product_photos_qty::integer AS product_photos_qty,
	product_weight_g::numeric AS product_weight_g,
	product_length_cm::numeric AS product_length_cm,
	product_height_cm::numeric AS product_height_cm,
	product_width_cm::numeric AS product_width_cm
FROM public.olist_products_dataset;

DROP TABLE IF EXISTS cleaned.olist_sellers_dataset CASCADE;
CREATE TABLE cleaned.olist_sellers_dataset AS
SELECT DISTINCT
	NULLIF(TRIM(seller_id::text), '') AS seller_id,
	NULLIF(TRIM(seller_zip_code_prefix::text), '') AS seller_zip_code_prefix,
	NULLIF(TRIM(seller_city::text), '') AS seller_city,
	NULLIF(TRIM(seller_state::text), '') AS seller_state
FROM public.olist_sellers_dataset;

DROP TABLE IF EXISTS cleaned.product_category_name_translation CASCADE;
CREATE TABLE cleaned.product_category_name_translation AS
SELECT DISTINCT
	NULLIF(TRIM(product_category_name::text), '') AS product_category_name,
	NULLIF(TRIM(product_category_name_english::text), '') AS product_category_name_english
FROM public.product_category_name_translation;

/* Recheck: table row counts and the main identifier NULL checks. */
SELECT table_name, row_count
FROM (
	SELECT 'olist_customers_dataset' AS table_name, COUNT(*) AS row_count FROM cleaned.olist_customers_dataset
	UNION ALL SELECT 'olist_geolocation_dataset', COUNT(*) FROM cleaned.olist_geolocation_dataset
	UNION ALL SELECT 'olist_orders_dataset', COUNT(*) FROM cleaned.olist_orders_dataset
	UNION ALL SELECT 'olist_order_items_dataset', COUNT(*) FROM cleaned.olist_order_items_dataset
	UNION ALL SELECT 'olist_order_payments_dataset', COUNT(*) FROM cleaned.olist_order_payments_dataset
	UNION ALL SELECT 'olist_order_reviews_dataset', COUNT(*) FROM cleaned.olist_order_reviews_dataset
	UNION ALL SELECT 'olist_products_dataset', COUNT(*) FROM cleaned.olist_products_dataset
	UNION ALL SELECT 'olist_sellers_dataset', COUNT(*) FROM cleaned.olist_sellers_dataset
	UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM cleaned.product_category_name_translation
) AS table_counts
ORDER BY table_name;

SELECT
	COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_ids,
	COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_ids,
	COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_timestamps
FROM cleaned.olist_orders_dataset;
