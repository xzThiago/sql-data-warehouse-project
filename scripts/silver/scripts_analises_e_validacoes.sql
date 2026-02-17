/*
=============================================================================
Análises e Validações do Processo ETL (Bronze -> Silver)
=============================================================================
Objetivo:
  Garantir a qualidade, integridade e padronização dos dados durante a
  transformação da camada 'bronze' (dados brutos) para a camada 'silver'
  (dados tratados).

Validações Executadas na camada Bronze:
  - Identificação de chaves primárias nulas ou duplicadas.
  - Verificação de espaçõs em branco indesejados.
  - Tratamento de valores nulos, negativos ou inconsistentes.
  - Validação de regras de negócio (ex: Sales = Quantity * Price).
  - Verificação de datas inválidas ou fora de intervalo permitido.
  - Padronização de campos categóricos (gênero, país, status, categorias).

Validações Aplicadas na camada Silver:
  - Garantia de unicidade e integridade das chaves primárias.
  - Confirmação da remoção de inconsistências e valores invãlidos.
  - Validação final das regras de negócio.
  - Conferência de padronização e consistência dos dados transformados.

Resultado Esperado:
  Dados limpos, consistentes, padronizados e prontos para consumo analítico
  (BI, relatórios e modelagem dimensional).
=============================================================================
*/

-- =========CRM============
/*
============================
CAMADA BRONZE
Tabela: bronze.crm_cust_info
============================
*/
-- Verificar se há valores nulos ou duplicados na chave primária
SELECT
    cst_id,
    COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Verificar se há espaços indesejados
SELECT 
    cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT 
    cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Padronização e consistência de dados
SELECT DISTINCT
    cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT
    cst_material_status
FROM bronze.crm_cust_info;

-- Verificar se há valores nulos ou duplicados na chave primária
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

/*
============================
CAMADA SILVER - VALIDAÇÃO
tabela: silver.crm_cust_info
============================
*/

-- Verificar se há espaços indesejados
SELECT 
    cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT 
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Padronização e consistência de dados
SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;

SELECT DISTINCT
    cst_material_status
FROM silver.crm_cust_info;


SELECT * FROM silver.crm_cust_info;


/*
===========================
CAMADA BRONZE
Tabela: bronze.crm_prd_info
===========================
*/
-- Verificar se há valores nulos ou duplicados na chave primária
SELECT
    prd_id,
    COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Verificar se há espaços indesejados
SELECT 
    prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Verificar se há valores NULOS ou negativos
SELECT
    prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Padronização e consistência de dados
SELECT DISTINCT
    prd_line
FROM bronze.crm_prd_info;

-- Verificar pedidos com data inválida
SELECT 
    *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


/*
============================
CAMADA SILVER - VALIDAÇÃO
tabela: silver.crm_prd_info
============================
*/

-- Verificar se há valores nulos ou duplicados na chave primária
SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Verificar se há espaços indesejados
SELECT 
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Verificar se há valores NULOS ou negativos
SELECT
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Padronização e consistência de dados
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;

-- Verificar pedidos com data inválida
SELECT 
    *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


SELECT 
    *
FROM silver.crm_prd_info


/*
================================
CAMADA BRONZE
Tabela: bronze.crm_sales_details
================================
*/
-- Verificar datas inválidas
SELECT 
    NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
    OR LEN(sls_order_dt) != 8
    OR sls_order_dt > 20500101 -- Verificando se existe "data" Maior que 2050
    OR sls_order_dt < 19000101 -- Verificando se existe "data" Menor que 1900

SELECT 
    NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
    OR LEN(sls_ship_dt) != 8
    OR sls_ship_dt > 20500101
    OR sls_ship_dt < 19000101

SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
    OR LEN(sls_due_dt) != 8
    OR sls_due_dt > 20500101
    OR sls_due_dt < 19000101

-- Verificando se existe "data" do pedido Maior que a "data" da entrega
-- Ou a "data" do pedido Maior que a "data" de vencimento
SELECT
    *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
OR sls_order_dt > sls_due_dt

-- Verificar a consistência dos dados: entre Sales, Quantity e Price
-- >> Sales = Quantity * Price
-- >> O valor não pode ser NULO, zero ou negativo.
------- Regras --------
-- Se Sales for negativo, zero ou nulo, calcule-o usando Quantity e Price.
-- Se Price for zero ou nulo, calcule-o usando Sales e Quantity.
-- Se Price for negativo, converta-o para um valor positivo.
SELECT DISTINCT
    sls_sales as sls_sales_old,
    sls_quantity,
    sls_price as sls_price_old,
    CASE
        WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    CASE
        WHEN sls_price IS NULL OR sls_price <=0 
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL
OR sls_quantity IS NULL
OR sls_price IS NULL
OR sls_sales <= 0
OR sls_quantity <= 0
OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

/*
================================
CAMADA SILVER - VALIDAÇÃO
Tabela: silver.crm_sales_details
================================
*/
-- Verificar datas inválidas
SELECT 
    sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > '2050-01-01' -- Verificando se existe "data" Maior que 2050
    OR sls_order_dt < '1900-01-01' -- Verificando se existe "data" Menor que 1900


SELECT 
    sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt > '2050-01-01' 
    OR sls_ship_dt < '1900-01-01'


SELECT 
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt > '2050-01-01' 
    OR sls_due_dt < '1900-01-01'


-- Verificando se existe "data" do pedido Maior que a "data" da entrega
-- Ou a "data" do pedido Maior que a "data" de vencimento
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
OR sls_order_dt > sls_due_dt

-- Verificar a consistência dos dados: entre Sales, Quantity e Price
-- >> Sales = Quantity * Price
-- >> O valor não pode ser NULO, zero ou negativo.
------- Regras --------
-- Se Sales for negativo, zero ou nulo, calcule-o usando Quantity e Price.
-- Se Price for zero ou nulo, calcule-o usando Sales e Quantity.
-- Se Price for negativo, converta-o para um valor positivo.

SELECT DISTINCT
    sls_sales as sls_sales_old,
    sls_quantity,
    sls_price as sls_price_old,
    CASE
        WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    CASE
        WHEN sls_price IS NULL OR sls_price <=0 
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL
OR sls_quantity IS NULL
OR sls_price IS NULL
OR sls_sales <= 0
OR sls_quantity <= 0
OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

SELECT * FROM silver.crm_sales_details;


-- =========ERP============
/*
============================
CAMADA BRONZE
Tabela: bronze.erp_cust_az12
============================
*/
-- Identificar datas fora do intervalo
SELECT DISTINCT
    bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1926-01-01'
   OR bdate > GETDATE();

-- Padronização e consistência de dados
SELECT DISTINCT
    gen,
    CASE 
       WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
       WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
       ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12;

/*
============================
CAMADA SILVER - VALIDAÇÃO
Tabela: silver.erp_cust_az12
============================
*/
-- Identificar datas fora do intervalo
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1926-01-01'
   OR bdate > GETDATE();

-- Padronização e consistência de dados
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;

SELECT * FROM silver.erp_cust_az12;


/*
============================
CAMADA BRONZE
Tabela: bronze.erp_loc_a101
============================
*/
-- Verificar caracteres indesejados
SELECT
    cid,
	REPLACE(UPPER(cid), '-', '') AS cid
FROM bronze.erp_loc_a101

-- Padronização e consistência de dados

SELECT DISTINCT 
    cntry,
    CASE
        WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
        WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101;

/*
============================
CAMADA SILVER - VALIDAÇÃO
Tabela: silver.erp_loc_a101
============================
*/

-- Verificar caracteres indesejados
SELECT
    cid
FROM silver.erp_loc_a101

-- Padronização e consistência de dados

SELECT DISTINCT 
    cntry
FROM silver.erp_loc_a101;

SELECT * FROM silver.erp_loc_a101;


/*
==============================
CAMADA BRONZE
Tabela: bronze.erp_px_cat_g1v2
==============================
*/
-- Verificar se há espaços indesejados
SELECT DISTINCT
    *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
OR subcat != TRIM(subcat)
OR maintenance != TRIM(maintenance);

SELECT DISTINCT
    id
FROM bronze.erp_px_cat_g1v2
WHERE id != TRIM(id) OR id NOT LIKE '%_%';

-- Padronização e consistência de dados

SELECT DISTINCT
    cat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT
    subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT
    maintenance
FROM bronze.erp_px_cat_g1v2;

/*
==============================
CAMADA SILVER - VALIDAÇÃO
Tabela: silver.erp_px_cat_g1v2
==============================
*/

SELECT * FROM silver.erp_px_cat_g1v2;
