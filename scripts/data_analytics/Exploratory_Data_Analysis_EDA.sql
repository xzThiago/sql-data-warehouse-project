-- Data Exploratory

-- Explore all objects in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Explore all columns in the databse
SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'dim_customers';

-- Dimensions Exploration
/*
Identifying the unique values (or categories) in each dimension.

Recognizing how data might be grouped or segmented, 
which is useful for late analysis.
-----------------------------------------------------------------
Identificar os valores únicos (ou categorias) em cada dimensão.

Reconhecer como os dados podem ser agrupados ou segmentados, 
o que é útil para análises posteriores.
*/

-- Explore all countries our customers come from
-- Explorar todos os paises ou de onde vem nossos clientes
SELECT DISTINCT 
	country 
FROM gold.dim_customers;

-- Explore All Categories "The major Divisions"
-- Explorar todas as cartegorias "as principais divisões"
SELECT DISTINCT
	category, -- 4 categorias
	subcategory, -- 36 subcategorias
	product_name -- 295 produtos
FROM gold.dim_products
ORDER BY 1,2,3;



--- Data Exploration
/*
Identify the earliest and latest dates (boundaries)

Understand the scope of data and the timespan.
-------------------------------------------
Identificar as datas (limites) mais antigas e mais recentes.

Compreender o escopo dos dados e o período de tempo abrangido.
*/
-- Find the data of the first and last order
-- How many years of sale are available

SELECT
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS Last_order_date,
	DATEDIFF(YEAR, MIN(order_date),MAX(order_date)) AS order_range_years,
	DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS order_range_month
FROM gold.fact_sales;

-- Find the youngest and oldest customer
SELECT 
	MIN(birthdate) AS oldest_bithdate,
	DATEDIFF(YEAR,MIN(birthdate), GETDATE()) AS oldest_age,
	MAX(birthdate) AS youngest_bithdate,
	DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;

-- Measures Exploration
/*
Calculate the key metric of the business (Big Numbers)

Highest Level of Aggregation | Lowest Level of Details
*/
SELECT
	top 5 *
FROM gold.fact_sales;

-- Find the Total Sales
SELECT
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

-- Find how many items are sold
SELECT
	SUM(quantity) as total_sales_products
FROM gold.fact_sales;

-- Find the average selling price
SELECT
	CAST(AVG(price) AS DECIMAL(10,2)) AS avg_price_sales
FROM gold.fact_sales;

-- Find the Total number of Orders
SELECT
	COUNT(order_number) as total_order
FROM gold.fact_sales

SELECT
	COUNT(DISTINCT order_number) as total_order
FROM gold.fact_sales

SELECT * FROM gold.fact_sales;

-- Find the Total number of Products
SELECT
	COUNT(product_key) as total_product
FROM gold.fact_sales

SELECT
	COUNT(DISTINCT product_key) as total_product
FROM gold.fact_sales


-- Find the Total number of Customers
SELECT
	COUNT(customer_key) as total_customers
FROM gold.fact_sales;


-- Find the Total number of Customers that has placed an order

SELECT
	COUNT(DISTINCT customer_key) as total_customers
FROM gold.fact_sales;

-- Generate Report that shows all key metrics of the business


SELECT
	'Total Sales' as measure_name,
	SUM(sales_amount) AS measure_value
FROM gold.fact_sales
UNION ALL 
SELECT
	'Total Quantity',
	SUM(quantity)
FROM gold.fact_sales
UNION ALL
SELECT
	'Average Price',
	CAST(AVG(price) AS DECIMAL(10,2))
FROM gold.fact_sales
UNION ALL
SELECT
	'Total N.Orders',
	COUNT(DISTINCT order_number) 
FROM gold.fact_sales
UNION ALL
SELECT
	'Total N.Produtcs',
	COUNT(DISTINCT product_key)
FROM gold.fact_sales
UNION ALL
SELECT
	'Total N.Customers',
	COUNT(DISTINCT customer_key)
FROM gold.fact_sales;

-- Magnitude Analysis
/*
Compare the measure values by categories

It helps us understand the importance of different categories
*/


-- Find total customers by countries
SELECT
	country,
	COUNT(customer_key) as total_customer_by_countries
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customer_by_countries DESC;

-- Find total customers by gender

SELECT
	gender,
	COUNT(customer_key) as total_customer_by_gender
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customer_by_gender DESC;

-- Find total products by category

SELECT
	category,
	COUNT(product_key) as total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- What is the average costs in each category?
SELECT
	category,
	cast(AVG(cost) AS DECIMAL(10,2)) as avg_cost
FROM gold.dim_products
WHERE category IS NOT NULL
GROUP BY category
ORDER BY avg_cost DESC;


-- What is the total revenue generated for each category?
SELECT
	b.category,
	SUM(a.sales_amount) AS Total_sales
FROM gold.fact_sales a
LEFT JOIN gold.dim_products b
	ON a.product_key = b.product_key
GROUP BY b.category
ORDER BY Total_sales DESC;

-- Find total revenue is generated by each customer
SELECT
	b.customer_key,
	CONCAT(b.first_name, ' ', b.last_name) as full_name,
	SUM(a.sales_amount) AS Total_sales
FROM gold.fact_sales a
LEFT JOIN gold.dim_customers b
	ON a.customer_key = b.customer_key
GROUP BY b.customer_key, CONCAT(b.first_name, ' ', b.last_name)
ORDER BY Total_sales DESC;

-- What is the distribution of sold items across countries?
SELECT
	b.country,
	SUM(a.quantity) as total_items_sold
FROM gold.fact_sales a
LEFT JOIN gold.dim_customers b
	ON a.customer_key = b.customer_key
GROUP BY b.country
ORDER BY total_items_sold DESC;

-- Total Sales by Country
SELECT 
	b.country, 
	SUM(sales_amount) total_sales
FROM gold.fact_sales a 
INNER JOIN gold.dim_customers b
	ON a.customer_key = b.customer_key
GROUP BY b.country
ORDER BY total_sales DESC;

-- Total Orders by Customer
SELECT
	customer_key,
	COUNT(order_number) as total_order
FROM gold.fact_sales
GROUP BY customer_key
ORDER BY total_order DESC;


-- Ranking Analysis
/*
Order the values of dimensions by measure.

Top N performers | Bottom N Performers
*/


SELECT 
	b.country, 
	SUM(sales_amount) total_sales,
	RANK() OVER(ORDER BY SUM(sales_amount) DESC) as ranking
FROM gold.fact_sales a 
INNER JOIN gold.dim_customers b
	ON a.customer_key = b.customer_key
GROUP BY b.country;

-- Wich 5 products generate the highest revenue
WITH cte as (
	SELECT
		f.product_key,
		p.product_name,
		SUM(f.sales_amount) as total_sales,
		RANK() OVER(ORDER BY SUM(f.sales_amount) DESC) as ranking_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY f.product_key, p.product_name
)
SELECT
	*
FROM cte
WHERE ranking_sales <= 5;
----------------------------------------------------------------
SELECT
	*
FROM (
		SELECT
		f.product_key,
		p.product_name,
		SUM(f.sales_amount) as total_sales,
		RANK() OVER(ORDER BY SUM(f.sales_amount) DESC) as ranking_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY f.product_key, p.product_name
) AS A
WHERE ranking_sales <= 5;

--- MAIS RÁPIDO
SELECT TOP 5
	f.product_key,
	p.product_name,
	SUM(f.sales_amount) as total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY 
	f.product_key,
	p.product_name
ORDER BY total_sales DESC

-- What are the 5 worst-performing products in terms of sales

SELECT TOP 5
	f.product_key,
	p.product_name,
	SUM(f.sales_amount) as total_sales_worst_performing
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY 
	f.product_key,
	p.product_name
ORDER BY total_sales_worst_performing ASC;

--------------------------------------------------
WITH cte as (
	SELECT
		f.product_key,
		p.product_name,
		SUM(f.sales_amount) as total_sales_worst_performing,
		RANK() OVER(ORDER BY SUM(f.sales_amount) ASC) as ranking_sales_worst_performing
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY f.product_key, p.product_name
)
SELECT
	*
FROM cte
WHERE ranking_sales_worst_performing <= 5;


-- Find the top 10  customers who have generated the highest revenue
WITH cte as (
SELECT
		b.customer_key,
		CONCAT(b.first_name, ' ', b.last_name) as full_name,
		SUM(a.sales_amount) AS Total_sales,
		ROW_NUMBER() OVER(ORDER BY SUM(a.sales_amount) DESC) AS ranking_customers
	FROM gold.fact_sales a
	LEFT JOIN gold.dim_customers b
		ON a.customer_key = b.customer_key
	GROUP BY b.customer_key, CONCAT(b.first_name, ' ', b.last_name)
)
SELECT 
	*
FROM cte
WHERE ranking_customers <= 10;

----------------

SELECT TOP 10
	b.customer_key,
	CONCAT(b.first_name, ' ', b.last_name) as full_name,
	SUM(a.sales_amount) AS Total_sales
FROM gold.fact_sales a
LEFT JOIN gold.dim_customers b
	ON a.customer_key = b.customer_key
GROUP BY b.customer_key, CONCAT(b.first_name, ' ', b.last_name)
ORDER BY Total_sales DESC;

-- The total customers with fewest orders placed
SELECT -- TOP 3
	b.customer_key,
	CONCAT(b.first_name, ' ', b.last_name) as full_name,
	COUNT(DISTINCT a.order_number) AS total_orders
FROM gold.fact_sales a
LEFT JOIN gold.dim_customers b
	ON a.customer_key = b.customer_key
GROUP BY b.customer_key, CONCAT(b.first_name, ' ', b.last_name)
HAVING COUNT(DISTINCT a.order_number) = 1
ORDER BY full_name ASC;