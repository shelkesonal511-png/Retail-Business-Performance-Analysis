-- =====================================================
-- RETAIL BUSINESS PERFORMANCE & PROFITABILITY ANALYSIS
-- Tools: MySQL
-- Dataset: Superstore
-- =====================================================
CREATE DATABASE RetailBusinessAnalysis;

-- =====================================================
-- 01. DATABASE & TABLE SETUP
-- =====================================================
USE RetailBusinessAnalysis;

SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

USE RetailBusinessAnalysis;

LOAD DATA LOCAL INFILE 'C:/Users/Sonal/OneDrive/Desktop/Retail Business Performance Analysis/Orders.csv'
INTO TABLE Orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Row_ID, Order_ID, Order_Date, Ship_Date, Ship_Mode,
 Customer_ID, Customer_Name, Segment, Country, City,
 State, Postal_Code, Region, Product_ID, Category,
 Sub_Category, Product_Name, Sales, Quantity, Discount, Profit);
 
 -- =====================================================
-- 02. DATA QUALITY CHECKS
-- =====================================================
 -- Check total rows
 SELECT COUNT(*) AS Total_Rows
FROM Orders;

-- Check for NULL values
SELECT
    SUM(CASE WHEN Row_ID IS NULL THEN 1 ELSE 0 END) AS Row_ID_Null,
    SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS Order_ID_Null,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS Order_Date_Null,
    SUM(CASE WHEN Ship_Date IS NULL THEN 1 ELSE 0 END) AS Ship_Date_Null,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Category_Null,
    SUM(CASE WHEN Sub_Category IS NULL THEN 1 ELSE 0 END) AS SubCategory_Null,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS Sales_Null,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Quantity_Null,
    SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS Discount_Null,
    SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS Profit_Null
FROM Orders;

-- Check duplicate Row IDs
SELECT Row_ID, COUNT(*) AS Duplicate_Count FROM Orders GROUP BY Row_ID HAVING COUNT(*) > 1;

-- Check duplicate Order IDs
SELECT
    Order_ID,
    COUNT(*) AS Number_of_Items
FROM Orders
GROUP BY Order_ID
HAVING COUNT(*) > 1
LIMIT 10;

-- =====================================================
-- 03. DATA PREPARATION
-- =====================================================

-- Add Shipping_Days
ALTER TABLE Orders
MODIFY Order_Date VARCHAR(20),
MODIFY Ship_Date VARCHAR(20);

SET SQL_SAFE_UPDATES = 0;

TRUNCATE TABLE Orders;

LOAD DATA LOCAL INFILE 'C:/Users/Sonal/OneDrive/Desktop/Retail Business Performance Analysis/Orders.csv'
INTO TABLE Orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Row_ID, Order_ID, Order_Date, Ship_Date, Ship_Mode,
 Customer_ID, Customer_Name, Segment, Country, City,
 State, Postal_Code, Region, Product_ID, Category,
 Sub_Category, Product_Name, Sales, Quantity, Discount, Profit);

SET SQL_SAFE_UPDATES = 1;

-- Convert the dates correctly
ALTER TABLE Orders
ADD COLUMN New_Order_Date DATE,
ADD COLUMN New_Ship_Date DATE;

-- Convert the text dates
UPDATE Orders
SET
    New_Order_Date = STR_TO_DATE(Order_Date, '%d-%m-%Y'),
    New_Ship_Date = STR_TO_DATE(Ship_Date, '%d-%m-%Y');

-- verifying table again
SELECT
    Order_ID,
    Order_Date,
    New_Order_Date,
    Ship_Date,
    New_Ship_Date
FROM Orders
LIMIT 10;

-- Remove the old text columns
ALTER TABLE Orders
DROP COLUMN Order_Date,
DROP COLUMN Ship_Date;

-- Rename the new date columns
ALTER TABLE Orders
RENAME COLUMN New_Order_Date TO Order_Date,
RENAME COLUMN New_Ship_Date TO Ship_Date;

SET SQL_SAFE_UPDATES = 0;

-- Create Shipping Days
UPDATE Orders
SET Shipping_Days = DATEDIFF(Ship_Date, Order_Date);

SET SQL_SAFE_UPDATES = 1;

-- verifying again
SELECT
    Order_ID,
    Order_Date,
    Ship_Date,
    Shipping_Days
FROM Orders
LIMIT 10;

-- final date-quality check
SELECT
    MIN(Order_Date) AS First_Order,
    MAX(Order_Date) AS Last_Order,
    MIN(Shipping_Days) AS Min_Shipping_Days,
    MAX(Shipping_Days) AS Max_Shipping_Days
FROM Orders;

-- Create Season
ALTER TABLE Orders
ADD COLUMN Season VARCHAR(20);

SET SQL_SAFE_UPDATES = 0;

UPDATE Orders
SET Season =
    CASE
        WHEN MONTH(Order_Date) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(Order_Date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(Order_Date) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(Order_Date) IN (9, 10, 11) THEN 'Autumn'
    END;

SET SQL_SAFE_UPDATES = 1;

-- verify
SELECT
    Order_Date,
    Season
FROM Orders
LIMIT 15;

-- Profit Margin
ALTER TABLE Orders
ADD COLUMN Profit_Margin DECIMAL(10,4);

SET SQL_SAFE_UPDATES = 0;

UPDATE Orders
SET Profit_Margin =
    CASE
        WHEN Sales = 0 THEN 0
        ELSE Profit / Sales
    END;

SET SQL_SAFE_UPDATES = 1;

-- verify
SELECT
    Category,
    Sub_Category,
    Sales,
    Profit,
    Profit_Margin
FROM Orders
LIMIT 10;

-- =====================================================
-- 04. CATEGORY PROFITABILITY ANALYSIS
-- =====================================================
SELECT
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS Profit_Margin_Percent
FROM Orders
GROUP BY Category
ORDER BY Total_Profit DESC;

-- =====================================================
-- 05. SUB-CATEGORY PROFITABILITY ANALYSIS
-- =====================================================
SELECT
    Sub_Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS Profit_Margin_Percent
FROM Orders
GROUP BY Sub_Category
ORDER BY Total_Profit ASC;

-- =====================================================
-- 06. REGIONAL PERFORMANCE ANALYSIS
-- =====================================================
-- Which regions are generating the most sales and profit?
SELECT
    Region,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Percent,
    SUM(Quantity) AS Total_Quantity
FROM Orders
GROUP BY Region
ORDER BY Total_Profit DESC;

-- =====================================================
-- 07. DISCOUNT VS PROFIT ANALYSIS
-- =====================================================
-- Does higher discounting lead to lower profitability?
SELECT
    ROUND(Discount * 100, 0) AS Discount_Percent,
    COUNT(*) AS Number_of_Orders,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(AVG(Profit_Margin) * 100, 2) AS Avg_Profit_Margin
FROM Orders
GROUP BY Discount
ORDER BY Discount;

-- =====================================================
-- 08. SEASONAL PERFORMANCE ANALYSIS
-- =====================================================
-- Seasonal Performance 
-- Which seasons generate the most sales and profit?
SELECT
    Season,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent,
    SUM(Quantity) AS Total_Quantity
FROM Orders
GROUP BY Season
ORDER BY Total_Profit DESC;


-- analyzing seasonal performance by category
SELECT
    Season,
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Season, Category
ORDER BY Season, Total_Profit DESC;

-- =====================================================
-- 09. FULFILLMENT TIME ANALYSIS
-- =====================================================
-- Shipping Days vs Profit
SELECT
    Shipping_Days,
    COUNT(*) AS Number_of_Orders,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(AVG(Profit_Margin) * 100, 2) AS Avg_Profit_Margin
FROM Orders
GROUP BY Shipping_Days
ORDER BY Shipping_Days;

-- =====================================================
-- 10. PRODUCT PERFORMANCE ANALYSIS
-- =====================================================
-- Top 10 most profitable products
SELECT
    Product_Name,
    Category,
    Sub_Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Product_Name, Category, Sub_Category
ORDER BY Total_Profit DESC
LIMIT 10;

-- Bottom 10 products
SELECT
    Product_Name,
    Category,
    Sub_Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Product_Name, Category, Sub_Category
ORDER BY Total_Profit ASC
LIMIT 10;

-- =====================================================
-- 11. OVERALL BUSINESS KPIs
-- =====================================================
SELECT
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    SUM(Quantity) AS Total_Units_Sold,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Overall_Profit_Margin,
    ROUND(AVG(Discount) * 100, 2) AS Average_Discount,
    ROUND(AVG(Shipping_Days), 2) AS Average_Shipping_Days
FROM Orders;

-- =====================================================
-- 12. MONTHLY PERFORMANCE TREND
-- =====================================================
SELECT
    YEAR(Order_Date) AS Order_Year,
    MONTH(Order_Date) AS Order_Month,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM Orders
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Order_Year, Order_Month;