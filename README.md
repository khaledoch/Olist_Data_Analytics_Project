# 📊 Olist E-Commerce Analysis

An end-to-end analysis of the Brazilian Olist e-commerce marketplace, built from raw CSV files to PostgreSQL, Python, Excel, and Power BI.

The project focuses on one practical question:

> How did sales growth, delivery reliability, customer satisfaction, and repeat purchasing shape the marketplace over time?

## 🧭 Project Overview

This project combines data cleaning, SQL analysis, Python exploration, Excel reporting, and Power BI visualization into one connected workflow.

```text
Raw CSVs
   ↓
PostgreSQL cleaning
   ↓
SQL business analysis
   ↓
Python validation and exploration
   ↓
Excel reporting workbook
   ↓
Power BI dashboard
```

## 🔍 Main Findings

- **November 2017** was the strongest month by delivered customer order value, at approximately **$1.15M**.
- **March 2018** was one of the weakest higher-volume delivery months, with a high late-delivery rate.
- Late deliveries received an average review score of **2.27/5**, compared with **4.29/5** for early deliveries.
- Low reviews represented **62.36%** of late-delivery reviews, compared with **9.19%** of early-delivery reviews.
- Repeat customers represented a small share of the delivered-order customer base, suggesting the marketplace was more acquisition-driven than retention-driven.
- The top 10 sellers contributed approximately **12.93%** of delivered customer value, so value was spread across a broad seller base rather than dominated by a few sellers.

### 📌 Overall Story

The data shows two different periods of pressure:

- **Late 2017:** greater financial volatility and a strong sales peak followed by weaker performance.
- **Early 2018:** clearer operational pressure, including weaker delivery reliability, more cancellations, lower reviews, and weaker customer experience.

The results show meaningful associations, not definitive proof that delivery delays were the only cause of lower reviews or repeat purchasing.

## 📸 Project Preview

### 📊 Power BI Dashboard

The final dashboard brings the main findings together through KPI cards, sales trends, category performance, customer retention, delivery reliability, and review outcomes.

![Olist Power BI dashboard](docs/images%20and%20gifs/Animation.gif)

### 📗 Excel Reporting Layer

The Excel workbook provides the formatted tables and supporting views used before building the interactive dashboard.

![Excel headline summary](docs/images%20and%20gifs/2_major%20headlines_excel.png)

![Excel monthly sales report](docs/images%20and%20gifs/3_monthly_sales_excel.png)

### 🧪 SQL and Python Evidence

The results are supported by direct PostgreSQL queries and Python exploration. The examples below show the monthly sales query and the investigation of unusually long delivery times.

![Monthly sales SQL result](docs/images%20and%20gifs/sql_images/1_monthly_sales_sql.png)

![Python delivery-time outliers](docs/images%20and%20gifs/1_delivery_time_outliers_python.png)

<details>
<summary>More SQL, Python, and Excel evidence</summary>

![Category performance SQL result](docs/images%20and%20gifs/sql_images/2_category_performance_sql.png)

![Python seller concentration](docs/images%20and%20gifs/2_seller_concentration_python.png)

![Excel review analysis](docs/images%20and%20gifs/1_review_analysis_excel.png)

</details>

## 🛠️ Tools Used

- **PostgreSQL:** cleaning, joining, aggregating, and analyzing the marketplace data.
- **Python:** validating SQL results and exploring delays, reviews, outliers, repeat customers, and sellers.
- **Excel:** creating a clean supporting reporting workbook with formatted tables and small charts.
- **Power BI:** presenting the final interactive dashboard.

## 🗂️ Analysis Stages

### 1. 🧹 Data Cleaning

[1_cleaning_dataset.sql](queries/1_cleaning_dataset.sql)

- Creates analysis-ready copies in the `cleaned` schema.
- Keeps the raw `public` tables untouched.
- Normalizes missing values and converts timestamps and numeric fields.
- Preserves ZIP prefixes as text.

### 2. 💰 Monthly Sales

[2_monthly_sales.sql](queries/2_monthly_sales.sql)

- Tracks monthly order activity and order status.
- Separates delivered, canceled, unavailable, and other orders.
- Calculates product revenue, freight value, total customer order value, and average order value.

### 3. 🛍️ Category Performance

[3_category_performance.sql](queries/3_category_performance.sql)

- Ranks product categories by completed customer value.
- Uses English category names when available.
- Compares item volume, product revenue, freight, and average category order value.

### 4. 🚚 Delivery Performance

[4_delivery_performance.sql](queries/4_delivery_performance.sql)

- Measures average delivery time by purchase month.
- Classifies delivered orders as early, on time, or late.
- Calculates delivery counts, rates, and average early or late days.

### 5. 👥 Customer and Seller Performance

[5_customer_seller_analysis.sql](queries/5_customer_seller_analysis.sql)

- Groups customers by their first purchase month.
- Measures cohort size, repeat customers, average orders, and customer revenue.
- Ranks sellers by delivered customer value and delivered order volume.

### 6. ⭐ Review Analysis

[6_review_analysis.sql](queries/6_review_analysis.sql)

- Compares reviews across early, on-time, and late deliveries.
- Measures average review score and low-review rate.
- Tracks review performance over time.

### 7. 🍩 Delivery Mix Export

[7_delivery_mix.sql](queries/7_delivery_mix.sql)

- Returns the overall share of early, on-time, and late delivered orders.
- Provides a simple three-row source for the Power BI delivery donut chart.

### 8. 🧩 Power BI Fact Table

[8_fact_order_items.sql](queries/8_fact_order_items.sql)

- This is a Power BI support layer rather than a separate business analysis.
- It provides an item-level fact table for relationships, filtering, drill-through, and more detailed visuals.
- The main findings above come from the first seven numbered queries; this table supports the dashboard model.

## 🐍 Python Notebooks

Python is intentionally supplementary and avoids duplicating the full dashboard.

- [01_python_validation.ipynb](notebooks/01_python_validation.ipynb)
  - Checks cleaned-order counts and missing identifiers.
  - Validates monthly totals.
  - Reproduces the main delivery-review comparison.

- [02_python_deeper_analysis.ipynb](notebooks/02_python_deeper_analysis.ipynb)
  - Compares early, on-time, and late review results.
  - Identifies unusually long delivery times.
  - Measures repeat-customer behavior.
  - Checks seller value share.

## 📗 Excel Reporting

[olist_report_analysis.xlsx](excel/olist_report_analysis.xlsx)

The workbook contains:

- formatted presentation tabs,
- raw PostgreSQL export tabs,
- formula-linked reporting tables,
- small supporting charts,
- and a summary sheet.

Excel acts as a clear reporting layer. Power BI remains the main interactive visualization tool.

## 📊 Power BI Dashboard

The final dashboard presents the main findings in one interactive report.

Dashboard visuals include:

- KPI cards for sales, orders, delivery, and reviews.
- Monthly total order value trend.
- Early, on-time, and late delivery donut chart.
- Monthly late-delivery rate.
- Top product categories by customer order value.
- Category economics scatter plot.
- Optional review-score comparison by delivery performance.

The [Power BI report](powerbi/olist_dashboard.pbix) and dashboard preview are included in the repository. The report uses the prepared Excel tables and the delivery-mix export from `7_delivery_mix.sql`.

## 📚 Documentation

The [docs](docs) folder contains detailed explanations for the five main analytical SQL files. Each document includes:

- the purpose of the query,
- the important SQL blocks,
- the logic behind the joins and calculations,
- assumptions and caveats,
- and the main insight from the analysis.

## 📐 Business Rules

- Completed business metrics use **delivered orders only**.
- Product revenue is calculated as `price`.
- Total customer order value is `price + freight_value`.
- Freight is treated as the shipping amount recorded in the dataset, not as company cost or profit.
- Reviews are aggregated to the order level before comparing them with delivery performance.
- Repeat customers are customers with at least two distinct delivered orders, identified with `customer_unique_id`.
- Very small early-period samples and the final 2018 cutoff months are treated cautiously.

## 🚀 Reproducing the Project

1. Install the dependencies:

   ```text
   pip install -r requirements.txt
   ```

2. Create a local `.env` file with PostgreSQL connection settings. Do not publish it.
3. Load the raw CSV files with:

   ```text
   python load_csvs.py path\to\your_data.zip
   ```

4. Run the cleaning query first:

   ```text
   psql -U postgres -d olist_database -f queries/1_cleaning_dataset.sql
   ```

5. Run the numbered SQL files in the `queries` folder. Queries `1` through `7` produce the main analysis outputs; query `8` supports the Power BI data model.
6. Open the two notebooks with the project Python environment.
7. Review the Excel workbook.
8. Build the final Power BI dashboard from the presentation tables.

## ⚠️ Important Data Notes

- The dataset begins with very limited activity in late 2016. Extreme early averages can therefore come from only one or a few orders.
- September and October 2018 contain very few orders and no delivered sales. They should be treated as a dataset cutoff, not evidence of business collapse.
- The `on_time` delivery group is much smaller than the early and late groups, so it is useful for context but should be interpreted cautiously.

## 📁 Repository Structure

```text
queries/                         Main analysis and Power BI support SQL files
docs/                            Detailed SQL explanations
notebooks/                       Two Python notebooks
excel/                           Completed Excel reporting workbook
powerbi/                         Power BI plan and final dashboard files
data/raw/                        Local raw CSV files, excluded from GitHub
load_csvs.py                     CSV loading script
requirements.txt                 Python dependencies
```

## ✅ Project Status

- ✅ PostgreSQL cleaning
- ✅ SQL analysis
- ✅ SQL documentation
- ✅ Python validation and exploration
- ✅ Excel reporting workbook
- ✅ Power BI dashboard
- ✅ Power BI model support table
- ⏳ Final portfolio presentation and README refinement
