/*
=====================================================================================
DDL Script: Criando Views Camada Gold
=====================================================================================
Objetivo do Script:
  Este script cria views para a Gold Layer no data warehouse.
  A camada Gold representa as tabelas finais de dimensão e fato (Star Schema - Esquema Estrela).

  Cada view realiza transformações e combina dados da camada Silver
  para produzir um conjunto de dados limpo, enriquecido e pronto para uso no negócio.

Uso:
  - As views podem ser consultadas diretamente para análises e relatórios.
=====================================================================================

*/

USE DataWarehouse;
-- =====================================================
-- Cria a tabela de dimensão: gold.dim_customers
-- =====================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
  DROP VIEW gold.dim_customers;
GO
  
CREATE VIEW gold.dim_customers AS
	SELECT
		ROW_NUMBER() OVER(ORDER BY ci.cst_id ASC) customer_key, -- Criando uma chave substituta
		ci.cst_id				AS customer_id,
		ci.cst_key				AS customer_number,
		ci.cst_firstname		AS first_name,
		ci.cst_lastname			AS last_name,
		ea1.cntry				AS country,
		ci.cst_marital_status	AS marital_status, 
		CASE	
			WHEN ci.cst_gndr = 'n/a' THEN ea.gen
			WHEN ea.gen = 'n/a' THEN ci.cst_gndr
			ELSE ci.cst_gndr
		END						AS gender,
		ea.bdate				AS birthdate,
		ci.cst_create_date		AS create_date
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ea
		ON ci.cst_key = ea.cid
	LEFT JOIN silver.erp_loc_a101 ea1
		ON ci.cst_key = ea1.cid;

-- =====================================================
-- Cria a tabela de dimensão: gold.dim_products
-- =====================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
  DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT	
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key ASC) AS product_key, -- Criando uma chave substituta
	pn.prd_id		AS product_id,
	pn.prd_key		AS product_number,
	pn.prd_nm		AS product_name,
	pn.cat_id		AS category_id,
	eg1.cat			AS category,
	eg1.subcat		AS subcategory,
	eg1.maintenance,
	pn.prd_cost		AS cost,
	pn.prd_line		AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 eg1
	ON pn.cat_id = eg1.id
WHERE pn.prd_end_dt IS NULL; -- Filtra todos os dados históricos

-- =====================================================
-- Cria a tabela de fatos: gold.fact_sales
-- =====================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
  DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num		AS order_number,
	pr.product_key,                     -- Chave substituta da tabela: gold.dim_products
	cus.customer_key,                   -- Chave substituta da tabela: gold.dim_customers
	sd.sls_order_dt		AS order_date,
	sd.sls_ship_dt		AS shipping_date,
	sd.sls_due_dt		AS due_date,
	sd.sls_sales		AS sales_amount,
	sd.sls_quantity		AS quantity,
	sd.sls_price		AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
	ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cus
	ON sd.sls_cust_id = cus.customer_id;
GO
