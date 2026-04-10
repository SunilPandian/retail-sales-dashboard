-- ============================================
-- RETAIL SALES DATA ANALYSIS PROJECT
-- ============================================

-- Dataset already has clean column names
-- invoice_no, stock_code, description, quantity,
-- invoice_date, unit_price, customer_id, country

-- ============================================
-- 1. DATA BACKUP
-- ============================================

CREATE TABLE retail_backup AS
SELECT * FROM retail_sales;

-- ============================================
-- 2. DATA TYPE FIXING
-- ============================================

-- Convert invoice_date from TEXT to DATETIME
UPDATE retail_sales
SET invoice_date = STR_TO_DATE(invoice_date, '%d-%m-%Y %H:%i');

ALTER TABLE retail_sales
MODIFY invoice_date DATETIME;

-- Fix numeric columns
ALTER TABLE retail_sales
MODIFY quantity INT,
MODIFY unit_price DECIMAL(10,2);

-- ============================================
-- 3. DATA CLEANING
-- ============================================

-- Handle NULL customer_id
UPDATE retail_sales
SET customer_id = 'Guest'
WHERE customer_id IS NULL;

-- Handle empty customer_id
UPDATE retail_sales
SET customer_id = 'Guest'
WHERE TRIM(customer_id) = '';

-- Remove extra spaces
UPDATE retail_sales
SET 
    description = NULLIF(TRIM(description), ''),
    country = NULLIF(TRIM(country), '');

-- Remove invalid records
DELETE FROM retail_sales
WHERE description IS NULL
   OR quantity <= 0
   OR unit_price <= 0;

-- Remove duplicates (safe approach)
CREATE TABLE retail_clean AS
SELECT DISTINCT * FROM retail_sales;

DROP TABLE retail_sales;

RENAME TABLE retail_clean TO retail_sales;

-- ============================================
-- 4. EXPLORATORY ANALYSIS
-- ============================================

-- Total records
SELECT COUNT(*) AS total_rows FROM retail_sales;

-- Date range
SELECT MIN(invoice_date) AS start_date,
       MAX(invoice_date) AS end_date
FROM retail_sales;

-- Monthly orders
SELECT 
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    COUNT(DISTINCT invoice_no) AS total_orders
FROM retail_sales
GROUP BY month
ORDER BY month;

-- Monthly revenue
SELECT 
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    ROUND(SUM(quantity * unit_price), 2) AS revenue
FROM retail_sales
GROUP BY month
ORDER BY month;

-- Monthly Average Order Value (AOV)
SELECT 
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    ROUND(SUM(quantity * unit_price) / COUNT(DISTINCT invoice_no), 2) AS avg_order_value
FROM retail_sales
GROUP BY month
ORDER BY month;

-- ============================================
-- 5. BUSINESS METRICS
-- ============================================

-- Total Revenue
SELECT ROUND(SUM(quantity * unit_price), 2) AS total_revenue
FROM retail_sales;

-- Total Orders
SELECT COUNT(DISTINCT invoice_no) AS total_orders
FROM retail_sales;

-- Total Customers
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM retail_sales;

-- Overall AOV
SELECT 
    ROUND(SUM(quantity * unit_price) / COUNT(DISTINCT invoice_no), 2) AS avg_order_value
FROM retail_sales;

-- ============================================
-- 6. PRODUCT ANALYSIS
-- ============================================

-- Top 10 Products by Revenue
SELECT 
    description,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(quantity * unit_price), 2) AS revenue
FROM retail_sales
GROUP BY description
ORDER BY revenue DESC
LIMIT 10;

-- ============================================
-- 7. CUSTOMER ANALYSIS
-- ============================================

-- Top Customers
SELECT 
    customer_id,
    ROUND(SUM(quantity * unit_price), 2) AS total_spent
FROM retail_sales
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- ============================================
-- 8. GEOGRAPHIC ANALYSIS
-- ============================================

-- Revenue by Country
SELECT 
    country,
    ROUND(SUM(quantity * unit_price), 2) AS revenue
FROM retail_sales
GROUP BY country
ORDER BY revenue DESC;

-- ============================================
-- 9. ADVANCED ANALYSIS (RFM SEGMENTATION)
-- ============================================

SELECT *,
    CASE 
        WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champions'
        WHEN r_score >= 2 AND f_score >= 2 THEN 'Loyal Customers'
        WHEN r_score = 3 AND f_score = 1 THEN 'New Customers'
        WHEN r_score = 1 AND f_score >= 2 THEN 'At Risk'
        ELSE 'Others'
    END AS segment
FROM (
    SELECT *,
        NTILE(3) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(3) OVER (ORDER BY frequency) AS f_score,
        NTILE(3) OVER (ORDER BY monetary) AS m_score
    FROM (
        SELECT 
            customer_id,
            DATEDIFF((SELECT MAX(invoice_date) FROM retail_sales), MAX(invoice_date)) AS recency,
            COUNT(DISTINCT invoice_no) AS frequency,
            ROUND(SUM(quantity * unit_price), 2) AS monetary
        FROM retail_sales
        GROUP BY customer_id
    ) base
) scored;

-- ============================================
-- END OF PROJECT
-- ============================================
