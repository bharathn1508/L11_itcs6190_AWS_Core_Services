-- 1) Cumulative Sales Over Time
WITH daily_sales AS (
  SELECT
    date_parse("Date", '%m-%d-%y') AS order_date,
    SUM(CAST("Amount" AS double)) AS total_sales
  FROM "ecomm_db"."raw_bharathraw"
  WHERE lower("Status") LIKE '%shipped%'
  GROUP BY date_parse("Date", '%m-%d-%y')
)
SELECT
  order_date,
  total_sales,
  SUM(total_sales) OVER (
    ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_sales
FROM daily_sales
ORDER BY order_date
LIMIT 10;

-- 2) Geographic Hotspot of Cancelled Orders
SELECT
  "ship-state" AS state,
  COUNT(*) AS cancelled_orders,
  SUM(CAST("Amount" AS double)) AS cancelled_value
FROM "ecomm_db"."raw_bharathraw"
WHERE lower("Status") LIKE '%cancel%'
GROUP BY "ship-state"
ORDER BY cancelled_value DESC
LIMIT 10;

-- 3) Impact of Quantity on Revenue by Category
SELECT
  "Category",
  SUM(CAST("Amount" AS double)) AS total_sales,
  SUM(CAST("Qty" AS integer)) AS total_qty,
  SUM(CAST("Amount" AS double)) / NULLIF(SUM(CAST("Qty" AS integer)), 0) AS avg_sale_per_item
FROM "ecomm_db"."raw_bharathraw"
GROUP BY "Category"
ORDER BY avg_sale_per_item DESC
LIMIT 10;

-- 4) Top 3 Highest Revenue Products per Category
WITH product_sales AS (
  SELECT
    "Category",
    "SKU",
    SUM(CAST("Amount" AS double)) AS total_sales
  FROM "ecomm_db"."raw_bharathraw"
  GROUP BY "Category", "SKU"
),
ranked AS (
  SELECT
    "Category",
    "SKU",
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY "Category" ORDER BY total_sales DESC) AS rank
  FROM product_sales
)
SELECT
  "Category",
  "SKU",
  total_sales
FROM ranked
WHERE rank <= 3
ORDER BY "Category", total_sales DESC
LIMIT 10;

-- 5) Monthly Sales Growth Trend
WITH monthly_sales AS (
  SELECT
    date_trunc('month', date_parse("Date", '%m-%d-%y')) AS month,
    SUM(CAST("Amount" AS double)) AS total_sales
  FROM "ecomm_db"."raw_bharathraw"
  WHERE lower("Status") LIKE '%shipped%'
  GROUP BY date_trunc('month', date_parse("Date", '%m-%d-%y'))
),
growth AS (
  SELECT
    month,
    total_sales,
    (total_sales - LAG(total_sales) OVER (ORDER BY month)) /
    NULLIF(LAG(total_sales) OVER (ORDER BY month), 0) AS month_growth
  FROM monthly_sales
)
SELECT *
FROM growth
ORDER BY month
LIMIT 10;
