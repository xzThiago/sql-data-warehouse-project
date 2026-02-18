/*
================================================================================
Stored Procedure: Carregando dados na Camada Silver (Bronze -> Silver)
================================================================================
Objetivo do Script:
    Esta stored procedure executa o processo de ETL (Extract, Transform, Load) 
    para popular as tabelas da camada 'silver' a partir do schema 'bronze'.

Ações Executadas:
    - Limpa (TRUNCATE) as tabelas da camada Silver.
    - Insere dados transformados e tratados da camada Bronze nas tabelas Silver.

Parâmetros:
    Nenhum.
    Esta stored procedure não aceita parâmetros nem retorna valores.

Exemplo de Uso:
    EXEC silver.load_silver;
================================================================================
*/

*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    -- =====================================================
	-- CONTROLE DE TEMPO - PROCESSAMENTO POR TABELA
	-- Armazena horário de início, fim e duração do ETL
	-- =====================================================
    DECLARE @data_inicio   DATETIME; -- Momento em que inicia o processamento dos dados
    DECLARE @data_fim      DATETIME; -- Momento em que finaliza o processamento dos dados
    DECLARE @total_segundos INT;     -- Duração total em segundos
    DECLARE @total_minutos INT;      -- Duração total convertida para minutos

    -- =====================================================
	-- CONTROLE DE TEMPO - PROCESSAMENTO GERAL DO ETL
	-- Armazena a duração total do processo completo
	-- =====================================================
    DECLARE @data_inicio_etl DATETIME; -- Início do processo ETL
    DECLARE @data_fim_etl    DATETIME; -- Fim do processo ETL

    BEGIN TRY
        /*
        ============== CRM ===============
        */
        SET @data_inicio_etl = GETDATE();
        PRINT '=====================================';
		PRINT 'Carregando Dados para a Camada Silver';
        PRINT '=====================================';

        PRINT '-------------------------------------';
        PRINT 'Carregando Tabelas do CRM';
		PRINT '-------------------------------------';

        PRINT ' ';
        PRINT '-------------------------------------------------';
        SET @data_inicio = GETDATE();
        PRINT 'De bronze.crm_cust_info Para silver.crm_cust_info';
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Inserting Data Into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT 
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        FROM (
           SELECT
                cst_id,
                cst_key,
                TRIM(cst_firstname) AS cst_firstname,
                TRIM(cst_lastname) AS cst_lastname,
                CASE 
                    WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                    WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                    ELSE 'n/a'
                END AS cst_marital_status,  -- Normaliza os valores do estado civil para um formato legível
                CASE 
                    WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                    ELSE 'n/a'
                END AS cst_gndr,     -- Normaliza os valores de gênero para um formato legível
                cst_create_date,
                ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t 
        WHERE flag_last = 1; -- Seleciona o registro mais recente por cliente.
        
        SET @data_fim = GETDATE();
        SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim); -- Retorna a diferença em segundos
        PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
        SET @total_minutos = @total_segundos / 60.0;
        PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
        PRINT ' ';

        PRINT '-------------------------------------------------';
        SET @data_inicio = GETDATE();
        PRINT 'De bronze.crm_prd_info Para silver.crm_prd_info';
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Inserting Data Into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Extrair Category ID
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,        -- Extrair Product Key
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line, -- Mapeia códigos de linha de produto para valores descritivos
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
                AS DATE
             ) AS prd_end_dt -- Calcula a data de término como um dia antes da próxima data de início.
        FROM bronze.crm_prd_info;

        SET @data_fim = GETDATE();
        SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim); -- Retorna a diferença em segundos
        PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
        SET @total_minutos = @total_segundos / 60.0;
        PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
        PRINT ' ';

        PRINT '-------------------------------------------------';
        SET @data_inicio = GETDATE();
        PRINT 'De bronze.crm_sales_details Para silver.crm_sales_details';
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Inserting Data Into: silver.crm_sales_details'
        INSERT INTO silver.crm_sales_details (
	        sls_ord_num,
	        sls_prd_key,
	        sls_cust_id,
	        sls_order_dt,
	        sls_ship_dt,
	        sls_due_dt,
	        sls_sales,
	        sls_quantity,
	        sls_price
        )
        SELECT
	        sls_ord_num,
	        sls_prd_key,
	        sls_cust_id,
	        CASE
		        WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	        END AS sls_order_dt, -- Converte INT -> STRING -> DATE
	        CASE
		        WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	        END AS sls_ship_dt, -- Converte INT -> STRING -> DATE
	        CASE
		        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	        END AS sls_due_dt, -- Converte INT -> STRING -> DATE
	        CASE
                WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales, -- Recalcula as vendas se o valor original estiver ausente ou incorreto.
	        sls_quantity,
            CASE
                WHEN sls_price IS NULL OR sls_price <=0 
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price -- Calcula o preço se o valor original for inválido.
        FROM bronze.crm_sales_details;

        SET @data_fim = GETDATE();
        SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim); -- Retorna a diferença em segundos
        PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
        SET @total_minutos = @total_segundos / 60.0;
        PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
        PRINT ' ';



        PRINT '-------------------------------------';
        PRINT 'Carregando Tabelas do ERP';
		PRINT '-------------------------------------';
        PRINT ' ';

        PRINT '-------------------------------------------------';
        SET @data_inicio = GETDATE();
        PRINT 'De bronze.erp_cust_az12 Para silver.erp_cust_az12';
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Inserting Data Into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
	        CASE
		        WHEN cid LIKE '%NAS%' THEN SUBSTRING(cid,4, LEN(cid)) -- Remove o prefixo 'NAS' se presente.
		        ELSE cid
	        END AS cid,
	        CASE
		        WHEN bdate > GETDATE() THEN NULL
		        ELSE bdate
	        END AS bdate, -- Define as datas de nascimento futuras como NULL.
	         CASE 
               WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
               WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
               ELSE 'n/a'
            END AS gen -- Normaliza os valores de gênero e lida com casos desconhecidos.
        FROM bronze.erp_cust_az12;

        SET @data_fim = GETDATE();
        SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim); -- Retorna a diferença em segundos
        PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
        SET @total_minutos = @total_segundos / 60.0;
        PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
        PRINT ' ';
        
        PRINT '-------------------------------------------------';
        SET @data_inicio = GETDATE();
        PRINT 'De bronze.erp_loc_a101 Para silver.erp_loc_a101';
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Inserting Data Into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
	        REPLACE(UPPER(cid), '-', '') AS cid,
            CASE
                WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
                WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry -- Normaliza e trata códigos de país ausentes ou em branco.
        FROM bronze.erp_loc_a101;

        SET @data_fim = GETDATE();
        SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim); -- Retorna a diferença em segundos
        PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
        SET @total_minutos = @total_segundos / 60.0;
        PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
        PRINT ' ';
        
        PRINT '-------------------------------------------------';
        SET @data_inicio = GETDATE();
        PRINT 'De bronze.erp_px_cat_g1v2 Para silver.erp_px_cat_g1v2';
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 
        (id, cat, subcat, maintenance)
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2

        SET @data_fim = GETDATE();
        SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim); -- Retorna a diferença em segundos
        PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
        SET @total_minutos = @total_segundos / 60.0;
        PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
        PRINT ' ';

        PRINT '############################################';
        SET @data_fim_etl = GETDATE();
        PRINT '============================================';
		PRINT 'ETL Finalizado com Sucesso!';
        PRINT '- Duração total do Processo ETL: ' + CAST(DATEDIFF(SECOND, @data_inicio_etl, @data_fim_etl) AS NVARCHAR) + ' segundos';
        PRINT '============================================';
    END TRY
    BEGIN CATCH
        PRINT '========================================================';
        PRINT 'Ocorrência(s) de Erro(s) Durante o Proceddo de ETL';
        PRINT 'Menssagem de Erro: ' + ERROR_MESSAGE();
        PRINT 'Menssagem de Erro: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Menssagem de Erro: ' + CAST (ERROR_STATE() AS NVARCHAR);
        PRINT '========================================================';
    END CATCH
END
