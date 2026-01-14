USE [Pizza DB];

/*
*****************************************
Data Overview
*****************************************
*/

SELECT * 
FROM dbo.pizza_sales

/*
*****************************************
Metrics 
*****************************************
*/

--1.Total Revenue

SELECT
	ROUND(SUM(total_price),2) AS Total_Revenue
FROM dbo.pizza_sales 

--2.Average Total Value

SELECT 
	ROUND(SUM(total_price) / COUNT(DISTINCT order_id),2) AS Avg_Total_Value
FROM dbo.pizza_sales

--3.Total Pizza Sold

SELECT 
	SUM(quantity) AS Total_Pizza_Sold
FROM dbo.pizza_sales

--4.Total Orders

SELECT 
	COUNT(DISTINCT order_id) AS Total_Orders
FROM dbo.pizza_sales

--5.Average Numbers Of pizza Per Order

SELECT 
    CAST(
        CAST(SUM(quantity) AS DECIMAL(10,2)) 
        / 
        CAST(COUNT(DISTINCT order_id) AS DECIMAL(10,2))
    AS DECIMAL(10,2)
) AS Avg_pizza_per_order
FROM dbo.pizza_sales;

/*
*****************************************
Descriptive analysis
*****************************************
*/

-- 1- Calculating the number of times each pizza is ordered

SELECT pizza_name,pizza_category,COUNT(*) AS total_orders
FROM pizza_sales
GROUP BY pizza_name,pizza_category
ORDER BY total_orders DESC

-- 2- Know Any Size Is Ordered More.

SELECT pizza_size,COUNT(*) total_orders 
FROM pizza_sales
GROUP BY pizza_size
ORDER BY total_orders DESC

-- 3- Calculating the quantities sold of each pizza
SELECT 
    pizza_name,
    pizza_category,
    SUM(quantity) AS total_quantities_sold
FROM pizza_sales
GROUP BY pizza_name, pizza_category
ORDER BY total_quantities_sold DESC;

-- 4- Calculating The Average cost Of Each Pizza Name

SELECT
    pizza_name,
    pizza_size,
    SUM(quantity) AS total_orders_per_size,
    ROUND(AVG(unit_price), 2) AS avg_price_per_size,
    ROUND(SUM(unit_price * quantity) / SUM(quantity), 2) AS weighted_avg_price_per_pizza
FROM pizza_sales
GROUP BY pizza_name, pizza_size
ORDER BY pizza_name, total_orders_per_size DESC;

-- 5- Which pizza brought in the highest sales
SELECT 
    pizza_name, 
    SUM(total_price) AS total_sales
FROM pizza_sales 
GROUP BY pizza_name 
ORDER BY total_sales DESC

-- 6- Wivh Category brought in the highest sales
SELECT 
    pizza_category, 
    SUM(total_price) AS total_sales
FROM pizza_sales 
GROUP BY pizza_category

-- 7- Wich Size Get better sales
SELECT 
    pizza_size,
    SUM(total_price) AS total_sales
FROM pizza_sales 
GROUP BY pizza_size
ORDER BY total_sales

-- 8- percentage of sales by pizza category.

SELECT 
    pizza_category,
    ROUND(SUM(total_price),2) AS total_sales,
    CAST(ROUND(SUM(total_price) * 100/(SELECT SUM(total_price) FROM pizza_sales),2) AS varchar(50)) + '%' AS percentage_sales
FROM pizza_sales
GROUP BY pizza_category
ORDER BY ROUND(SUM(total_price) * 100/(SELECT SUM(total_price) FROM pizza_sales),2) DESC 


-- 9- Percentage of sales by pizza size.

SELECT 
    pizza_size,
    ROUND(SUM(total_price), 2) AS total_sales,
    CAST(ROUND(
        SUM(total_price) * 100.0 / (SELECT SUM(total_price) FROM pizza_sales), 
        2
    ) AS varchar(50)) + '%' AS percentage_sales
FROM pizza_sales
GROUP BY pizza_size
ORDER BY 
    ROUND(
        SUM(total_price) * 100.0 / (SELECT SUM(total_price) FROM pizza_sales), 
        2
    ) DESC;


-- 10- Top 5 pizza_ name Sold
SELECT TOP 5
    pizza_name,
    SUM(quantity) As total_quantity
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_quantity DESC

-- 11- Bottom 5 pizza_name Sold

SELECT TOP 5
    pizza_name,
    SUM(quantity) As total_quantity
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_quantity ASC



/*
*****************************************
Time Series Analysis
*****************************************
*/


-- 1- Monthly Sales Trend by Month Name

SELECT
DATENAME(MONTH,Order_date) AS month_name,
ROUND(SUM(total_price),2) total_sales 
FROM pizza_sales 
GROUP BY  DATENAME(MONTH,Order_date)
ORDER BY total_sales DESC

-- 2 Monthly trend for total orders
SELECT 
    DATENAME(MONTH,order_date) AS month_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales
GROUP BY DATENAME(MONTH,order_date)
ORDER BY total_orders DESC

-- 3- Daily trend for total orderes
SELECT
    DATENAME(WEEKDAY,Order_date) AS day_name,
    COUNT(DISTINCT Order_id) AS total_orders
FROM pizza_sales
GROUP BY DATENAME(WEEKDAY,Order_date)
ORDER BY total_orders DESC

-- 4- Sales Distribution by Day of Week

SELECT
DATENAME(WEEKDAY, Order_date) AS month_name,
ROUND(SUM(total_price),2) total_sales 
FROM pizza_sales 
GROUP BY  DATENAME(WEEKDAY, Order_date)
ORDER BY total_sales DESC



-- 5- Which hour of the day is the best-selling

SELECT 
    DATEPART(HOUR, order_time) AS order_hour, 
    SUM(total_price) total_sales 
FROM pizza_sales 
GROUP BY DATEPART(HOUR, order_time) 
ORDER BY total_sales DESC


-- 6- Highest catgeory sales in each month.

SELECT
    pizza_category,
    month_num,
    total_sales
FROM 
(
SELECT 
    pizza_category,
    MONTH(order_date) AS month_num, 
    SUM(total_price) As Total_sales,
    ROW_NUMBER() OVER(partition BY MONTH(order_date) ORDER BY(SUM(total_price))) AS rn

FROM pizza_sales
GROUP BY pizza_category,MONTH(order_date)
) T
WHERE rn=1
ORDER BY Total_sales DESC



-- 7- Watching the pizza price over time:

/*This analysis aims to verify the stability of pizza prices over time, and to determine whether there are price changes associated with specific time periods.*/

SELECT
    pizza_name,
    pizza_size,
    MONTH(order_date) AS month_num,
    DATENAME(MONTH, order_date) AS month_name,
    AVG(unit_price) AS avg_price
FROM pizza_sales
GROUP BY
    pizza_name,
    pizza_size,
    MONTH(order_date),
    DATENAME(MONTH, order_date)
ORDER BY
    pizza_name,
    pizza_size,
    month_num;


--- 8-  MoM For Total Order (growth)
WITH MonthlyOrders AS (
    SELECT
        MONTH(order_date) AS month_num,
        DATENAME(MONTH, order_date) AS month_name,
        COUNT(DISTINCT order_id) AS total_orders
    FROM pizza_sales
    GROUP BY 
        MONTH(order_date),
        DATENAME(MONTH, order_date)
)

SELECT
    month_name,
    total_orders,
    LAG(total_orders) OVER (ORDER BY month_num) AS previous_month_orders,
    ROUND((total_orders - LAG(total_orders) OVER (ORDER BY month_num)) * 100.0 / LAG(total_orders) OVER (ORDER BY month_num),2) AS growth_percentage
FROM MonthlyOrders
ORDER BY month_num;


--- 9- MoM For revenue (growth)

WITH MonthlyRevenue AS (
    SELECT
        MONTH(order_date) AS month_num,
        DATENAME(MONTH, order_date) AS month_name,
        SUM(total_price) AS total_revenue
    FROM pizza_sales
    GROUP BY 
        MONTH(order_date),
        DATENAME(MONTH, order_date)
)

SELECT
    month_name,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month_num))
        * 100.0
        / LAG(total_revenue) OVER (ORDER BY month_num),
    2) AS revenue_growth_percentage
FROM MonthlyRevenue
ORDER BY month_num;



-- Making A Sample From This Data

SELECT *
FROM pizza_sales
WHERE order_date >= '2015-01-01'
  AND order_date <  '2015-01-11';




