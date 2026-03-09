/*
==================================================
Projeto SQL - Análise Exploratória de Dados (EDA)
==================================================
*/
USE DataWarehouse;

-- Explory ALL Objects in the Database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS;

-- Explory ALL Columns in the Database
SELECT
	TABLE_CATALOG,
	TABLE_SCHEMA,
	TABLE_NAME,
	COLUMN_NAME,
	DATA_TYPE,
	ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';

/*
=============================================
Exploração das Tabelas de Clientes e Produtos
=============================================

Identificar os valores únicos (ou categorias) em cada dimensão.

Reconhecer como os dados podem ser agrupados ou segmentados, 
o que é útil para análises posteriores.
*/

-- Explorar todos os paises ou de onde vem nossos clientes
SELECT DISTINCT
	country
FROM gold.dim_customers;
-- 6 Países distintos 

-- Explorar informações relevantes de clientes
SELECT
	COUNT(DISTINCT customer_id) AS total_cliente
FROM gold.dim_customers;
-- total_cliente 18.484

SELECT
	gender,
	COUNT(customer_id) AS total_cliente
FROM gold.dim_customers
GROUP BY gender;
-- Male 9341 | Female 9128 | 15 n/a

SELECT
	marital_status,
	COUNT(customer_id) AS total_cliente
FROM gold.dim_customers
GROUP BY marital_status;
-- Married 10011 | Sigle 8473

SELECT
	gender,
	marital_status,
	COUNT(customer_id) AS total_cliente
FROM gold.dim_customers
GROUP BY gender, marital_status;
-- Male   Single 4081 | Male   Married 5260
-- Female Single 4385 | Female Married 4743

-- Explorar todas as cartegorias "as principais divisões - subcategorias"
SELECT DISTINCT
	category,
	subcategory,
	product_name
FROM gold.dim_products
-- WHERE category IS NOT NULL AND subcategory IS NOT NULL
ORDER BY 1,2,3
-- 4 Categorias | 36 Subcategorias | 295 Produtos 


/*
=======================
Exploração das datas
=======================
Identificar as datas (limites) mais antigas e mais recentes.

Compreender o escopo dos dados e o período de tempo abrangido.
*/

-- Encontre os dados do primeiro e do último pedido
-- Quantos anos de venda estão disponíveis
SELECT
	MIN(order_date) AS data_primeiro_pedido,
	MAX(order_date) AS data_ultimo_pedido,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS intervalo_pedido_mes
FROM gold.fact_sales
-- data_primeiro_pedido 2010-12-29
-- data_ultimo_pedido   2014-01-28
-- intervalo_pedido_mes 37 | 3 anos e 1 mês

-- Encontre o cliente mais jovem e o mais velho
SELECT
	MIN(birthdate) AS dt_nascimento_antigo,
	DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS idade_mais_velha,
	MAX(birthdate) AS dt_nascimento_novo,
	DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS idade_mais_nova
FROM gold.dim_customers;
-- dt_nascimento_antigo 1916-02-10 | idade_mais_velha 110
-- dt_nascimento_novo   1986-06-25 | idade_mais_nova  40

/*
======================
Exploração de Métricas
======================
Calcular a métrica principal do negócio (big numbers)

Nível Mais Alto de Agregação | Nível Mais Baixo de Detalhes
*/

-- Descobrir o total de vendas
SELECT
	CAST(SUM(sales_amount) AS DECIMAL(10,2)) AS total_vendas
FROM gold.fact_sales;
-- total_vendas 29.356.250,00

-- Descobrir quantos itens foram vendidos
SELECT
	SUM(quantity) AS total_itens_vendidos
FROM gold.fact_sales;
-- total_itens_vendidos 60.423

-- Descobir o preço médio de venda
SELECT
	AVG(price) as preco_medio_venda
FROM gold.fact_sales;
-- preco_medio_venda 486

-- Encontrar a quantidade total de pedidos
SELECT 
	COUNT(DISTINCT order_number) AS total_pedidos
FROM gold.fact_sales;
-- total_pedidos 27.659

-- Encontrar a quantidade total de produtos vendidos
SELECT
	COUNT(DISTINCT product_key) AS total_prod_vendidos,
	SUM(quantity) AS total_qtde_vendidos
FROM gold.fact_sales;
-- total_prod_vendidos distintos 130
-- total_qtde_vendidos           60.423

-- Contar quantos clientes diferentes fizeram pelo menos um pedido.
SELECT 
	COUNT(DISTINCT customer_key) AS total_cliente
FROM gold.fact_sales;
-- total_cliente 18.484

-- Criando um relatório que mostre todas as principais métricas do negócio.
SELECT
	'Venta Total' as nome_metrica,
	CAST(SUM(sales_amount) AS DECIMAL(10,2)) AS valor_metrica
FROM gold.fact_sales
UNION ALL
SELECT
	'Quantidade Total',
	SUM(quantity)
FROM gold.fact_sales
UNION ALL
SELECT
	'Preço Médio',
	CAST(AVG(price) AS DECIMAL(10,2))
FROM gold.fact_sales
UNION ALL
SELECT
	'Pedidos Totais',
	COUNT(DISTINCT order_number)
FROM gold.fact_sales
UNION ALL
SELECT
	'Total Produtos Distintos',
	COUNT(DISTINCT product_key)
FROM gold.fact_sales
UNION ALL
SELECT
	'Total Clientes Distintos',
	COUNT(DISTINCT customer_key)
FROM gold.fact_sales;
/*
  nome_metrica             | valor_metrica
- Venda Total              | 29.356.250,00  
- Quantidade Total         | 60.423
- Preço Médio              | 486,00
- Pedidos Totais           | 27.659
- Total Produtos Distintos | 130
- Total Clientes Distintos | 18.484
--
*/

/*
========================
Análise de Magnitude
========================
Comparar os valores das medidas por categorias
Isso nos ajuda a entender a importância de diferentes categorias
*/

-- Encontre o total de clientes por país
SELECT
	ROW_NUMBER() OVER (ORDER BY COUNT(customer_id) DESC) AS classificacao,
	country,
	COUNT(customer_id) AS total_cliente
FROM gold.dim_customers
GROUP BY country
ORDER BY total_cliente DESC;
/* 
classificacao  | country		| total_cliente
	1		   |  United States	|	7482
	2		   |  Australia		|	3591
	3		   |  United Kingdom|	1913
	4		   |  France		|	1810
	5		   |  Germany		|	1780
	6		   |  Canada		|   1571
	7		   |  n/a			|	337
*/

-- Total de produtos por Categorias
SELECT
	ROW_NUMBER() OVER (ORDER BY COUNT(product_key) DESC) AS classificacao,
	category,
	COUNT(product_key) AS total_prod
FROM gold.dim_products
GROUP BY category
ORDER BY total_prod DESC
/*
classificacao  | category	| total_prod
	1		   | Components	|	127
	2	       | Bikes	    |	97
	3	       |Clothing	|	35
	4	       |Accessories	|	29
	5	       |NULL	    |	7
*/
-- Quais são os custos médios em cada categoria?
SELECT
	ROW_NUMBER() OVER(ORDER BY AVG(cost) DESC) AS classificacao,
	category,
	cast(AVG(cost) AS DECIMAL(10,2)) as custo_medio
FROM gold.dim_products
WHERE category IS NOT NULL
GROUP BY category
ORDER BY custo_medio DESC;
/*
classificacao |category		|custo_medio
	1		  | Bikes		| 949.00
	2		  | Components	| 264.00
	3		  | Clothing	| 24.00
	4		  | Accessories	| 13.00
*/

-- Qual é a receita total gerada para cada categoria?
SELECT
	RANK() OVER(ORDER BY SUM(a.sales_amount) DESC) AS ranking,
	b.category,
	CAST(SUM(a.sales_amount) AS DECIMAL(10,2)) AS total_receita
FROM gold.fact_sales a
LEFT JOIN gold.dim_products b
	ON a.product_key = b.product_key
GROUP BY b.category
ORDER BY total_receita DESC;
/*
ranking	| category	   | total_receita
	1	|  Bikes	   |  28.316.272,00
	2	|  Accessories |  700.262,00
	3	|  Clothing	   |  339.716,00
*/

-- Calcule a receita total gerada por cada cliente. Retorne os Top 10
SELECT 
	*
FROM (
	SELECT
		ROW_NUMBER() OVER(ORDER BY SUM(a.sales_amount) DESC) AS classificacao,
		b.customer_key,
		CONCAT(b.first_name, ' ', b.last_name) AS nome_cliente,
		CAST(SUM(a.sales_amount) AS DECIMAL(10,2)) AS total_receita
	FROM gold.fact_sales a
	LEFT JOIN gold.dim_customers b
		ON a.customer_key = b.customer_key
	GROUP BY b.customer_key , CONCAT(b.first_name, ' ', b.last_name)
) t
WHERE classificacao <= 10;
/*
classificacao | customer_key | nome_cliente			| total_receita 
	1		  |  1302		 |  Nichole Nara		|  13.294,00 
	2         |  1133		 |  Kaitlyn Henderson	|  13.294.00
	3		  |  1309		 |  Margaret He			|  13.268,00 
	4		  |  1132		 |  Randall Dominguez	|  13.265,00 
	5		  |  1301		 |  Adriana Gonzalez    |  13.242,00 
	6		  |  1322		 |  Rosa Hu				|  13.215,00 
	7		  |  1125		 |  Brandi Gill			|  13.195,00 
	8 		  |  1308		 |  Brad She			|  13.172,00 
	9		  |  1297		 |  Francisco Sara		|  13.164,00 
	10		  |  434		 |  Maurice Shan		|  12.914,00 
*/

-- Qual é a distribuição dos itens vendidos entre os países?
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(a.quantity) DESC) AS classificacao,
	b.country,
	CAST(SUM(a.quantity) AS DECIMAL(10,2)) AS total_receita
FROM gold.fact_sales a
LEFT JOIN gold.dim_customers b
	ON a.customer_key = b.customer_key
GROUP BY b.country;
/*
 classificacao  | country        | total_receita 
  1             | United States  | 20.481,00      
  2             | Australia      | 13.346,00      
  3             | Canada         | 7630,00       
  4             | United Kingdom | 6910,00       
  5             | Germany        | 5626,00       
  6             | France         | 5559,00       
  7             | n/a            | 871,00        
*/

-- Total de vendas por país
SELECT 
	ROW_NUMBER() OVER(ORDER BY SUM(a.sales_amount) DESC) AS classificacao,
	b.country, 
	CAST(SUM(a.sales_amount) AS DECIMAL(10,2)) AS total_venda
FROM gold.fact_sales a 
INNER JOIN gold.dim_customers b
	ON a.customer_key = b.customer_key
GROUP BY b.country
ORDER BY total_venda DESC;
/*
 classificacao | country         | total_sales
 1             | United States   | 9.162.327,00
 2             | Australia       | 9.060.172,00
 3             | United Kingdom  | 3.391.376,00
 4             | Germany         | 2.894.066,00
 5             | France          | 2.643.751,00
 6             | Canada          | 1.977.738,00
 7             | n/a             | 226.820,00
*/

-- Total de pedidos por cliente. Retorne os Top 3
WITH cte AS (
	SELECT
		ROW_NUMBER() OVER(
			ORDER BY 
				COUNT(DISTINCT a.order_number) DESC, 
				SUM(a.sales_amount) DESC -- A soma do sales_amount é calculada para usar no desempate.
				) AS classificacao, 
		b.customer_key,
		CONCAT(b.first_name, ' ', b.last_name) AS nome_cliente,
		COUNT(DISTINCT a.order_number) as total_pedido,
		CAST(SUM(a.sales_amount) AS DECIMAL(10,2)) as total_venda
	FROM gold.fact_sales a
	LEFT JOIN gold.dim_customers b
		ON a.customer_key = b.customer_key
	GROUP BY b.customer_key, CONCAT(b.first_name, ' ', b.last_name)
)
SELECT
	*
FROM cte	
WHERE classificacao <= 3;
/*
 classificacao | customer_key | nome_cliente     | total_pedido | total_venda
 1             | 177          | Mason Roberts    | 28           | 1.317,00
 2             | 92           | Dalton Perez     | 28           | 1.186,00
 3             | 186          | Ashley Henderson | 27           | 1.616,00
*/

-- Quais são os 5 produtos que geram a maior receita?
SELECT
	*
FROM (
	SELECT
		ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) DESC) as classificacao,
		f.product_key,
		p.product_name,
		CAST(SUM(f.sales_amount) AS DECIMAL(10,2)) as total_venda
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY f.product_key, p.product_name
) AS A
WHERE classificacao <= 5;
/*
 classificacao | product_key | product_name               | total_venda
 1             | 122         | Mountain-200 Black- 46     | 1.373.454,00
 2             | 121         | Mountain-200 Black- 42     | 1.363.128,00
 3             | 123         | Mountain-200 Silver- 38    | 1.339.394,00
 4             | 125         | Mountain-200 Silver- 46    | 1.301.029,00
 5             | 120         | Mountain-200 Black- 38     | 1.294.854,00
*/

-- Quais são os 5 produtos com pior desempenho em termos de vendas?
SELECT
	*
FROM (
	SELECT
		ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) ASC) as classificacao,
		f.product_key,
		p.product_name,
		CAST(SUM(f.sales_amount) AS DECIMAL(10,2)) as total_venda
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	GROUP BY f.product_key, p.product_name
) AS A
WHERE classificacao <= 5;
/*
 classificacao | product_key | product_name               | total_venda
 1             | 279         | Racing Socks- L            | 2.430,00
 2             | 280         | Racing Socks- M            | 2.682,00
 3             | 259         | Patch Kit/8 Patches        | 6.382,00
 4             | 168         | Bike Wash - Dissolver      | 7.272,00
 5             | 291         | Touring Tire Tube          | 7.440,00
*/

-- SEM FUNÇÃO DE JANELA (WINDOW FUNCTIONS)
-- Quais são as MELHORES 5 subcategorias que geram a MAIOR receita?
SELECT TOP 5
	p.subcategory,
	CAST(SUM(f.sales_amount) AS DECIMAL(10,2)) as total_venda
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY p.subcategory
ORDER BY total_venda DESC;
/*
 subcategory       | total_venda
 Road Bikes        | 14.519.438,00
 Mountain Bikes    | 9.952.254,00
 Touring Bikes     | 3.844.580,00
 Tires and Tubes   | 244.634,00
 Helmets           | 225.435,00
*/

-- Quais são as PIORES 5 subcategorias que geram a MENOR receita?
SELECT TOP 5
	p.subcategory,
	CAST(SUM(f.sales_amount) AS DECIMAL(10,2)) as total_venda
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
GROUP BY p.subcategory
ORDER BY total_venda ;
/*
 subcategory   | total_venda
 Socks         | 5.112,00
 Cleaners      | 7.272,00
 Caps          | 19.710,00
 Gloves        | 34.320,00
 Vests         | 36.160,00
*/