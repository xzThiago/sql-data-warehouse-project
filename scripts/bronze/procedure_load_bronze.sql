/*
===================================================================================
Stored Procedure: Carga da Camada Bronze (Origem -> Bronze)
===================================================================================
Objetivo do Script:
  Esta procedure realiza a carga de dados no schema "bronze" a partir de arquivos CSV externos.
  As seguintes ações são executadas:
  - Remove os dados das tabelas bronze antes do carregamento.
  - Utiliza o comando BULK INSERT para importar os dados dos arquivos CSV
    para as tabelas da camada bronze.

Parâmetros:
  Nenhum.
  Esta stored procedure não recebe parâmetros e não retorna valores.

Para executá-la:
  EXEC bronze.load_bronze;
===================================================================================
*/


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	-- =====================================================
	-- CONTROLE DE TEMPO - PROCESSAMENTO POR ARQUIVO
	-- Armazena horário de início, fim e duração da carga
	-- =====================================================
	DECLARE @data_inicio	DATETIME; -- Momento em que inicia o processamento do arquivo
	DECLARE @data_fim		DATETIME; -- Momento em que finaliza o processamento do arquivo
	DECLARE @total_segundos INT;      -- Duração total em segundos
	DECLARE @total_minutos  INT;      -- Duração total convertida para minutos

	-- =====================================================
	-- CONTROLE DE TEMPO - PROCESSAMENTO GERAL DA EXTRAÇÃO
	-- Armazena a duração total do processo completo
	-- =====================================================
	DECLARE @data_inicio_extracao DATETIME;  -- Início da execução geral
	DECLARE @data_fim_extracao    DATETIME;  -- Fim da execução geral

	BEGIN TRY
		SET @data_inicio_extracao = GETDATE();
		PRINT '====================================';
		PRINT 'Carregando Dados para Camada Bronze';
		PRINT '====================================';

		PRINT '------------------------------------';
		PRINT 'Carregando tabelas CRM';
		PRINT '------------------------------------';

		PRINT ' ';
		SET @data_inicio = GETDATE();
		PRINT '>> Apagando dados da Tabela: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info; -- APAGA OS DADOS DA TABELA

		PRINT '<< Inserindo dados na Tabela: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info -- IMPORTAR GRANDES VOLUMES DE DADOS DE ARQUIVOS EXTERNOS
		FROM 'C:\Users\thiag\OneDrive\Área de Trabalho\Learning\Projetos_SQL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv' -- ESPECIFICAR O CAMINHO CORRETO DO ARQUIVO
		WITH (
			FIRSTROW = 2, -- IGNORA A PRIMEIRA LINHA (NOME DAS COLUNAS)
			FIELDTERMINATOR = ',', -- INFORMA QUE OS CAMPOS É SEPARADOS POR VIRGULA
			TABLOCK  -- A TABELA 'bronze.crm_cust_info' VAI SER BLOQUEADA DURANTE O CARREGAMENTO DO DADOS
		);

		SET @data_fim = GETDATE();
		SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim);  -- RETORNA A DIFERENÇA EM SEGUNDOS
		PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
		SET @total_minutos = @total_segundos / 60.0;
		PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
		PRINT ' ';

		SET @data_inicio = GETDATE();
		PRINT '>> Apagando dados da Tabela: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '<< Inserindo dados na Tabela: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\thiag\OneDrive\Área de Trabalho\Learning\Projetos_SQL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @data_fim = GETDATE();
		SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim);
		PRINT 'Tempo total em Segundos: ' + CAST (@total_segundos AS NVARCHAR);
		SET @total_minutos = @total_segundos / 60.0;
		PRINT 'Tempo total em Minutos: ' + CAST (@total_minutos AS NVARCHAR);
		PRINT ' ';

		SET @data_inicio = GETDATE();
		PRINT '>> Apagando dados da Tabela: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '<< Inserindo dados na Tabela: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\thiag\OneDrive\Área de Trabalho\Learning\Projetos_SQL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		
		SET @data_fim = GETDATE();
		SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim);
		PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
		SET @total_minutos = @total_segundos / 60.0;
		PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
		PRINT ' ';

		PRINT '------------------------------------';
		PRINT 'Carregando tabelas ERP';
		PRINT '------------------------------------';

		PRINT ' ';

		SET @data_inicio = GETDATE();
		PRINT '>> Apagando dados da Tabela: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '<< Inserindo dados na Tabela: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\thiag\OneDrive\Área de Trabalho\Learning\Projetos_SQL\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @data_fim = GETDATE();
		SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim);
		PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
		SET @total_minutos = @total_segundos / 60.0;
		PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
		PRINT ' ';

		SET @data_inicio = GETDATE();
		PRINT '>> Apagando dados da Tabela: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '<< Inserindo dados na Tabela: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\thiag\OneDrive\Área de Trabalho\Learning\Projetos_SQL\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @data_fim = GETDATE();
		SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim);
		PRINT 'Tempo total em Segundos: ' + CAST(@total_segundos AS NVARCHAR);
		SET @total_minutos = @total_segundos / 60.0;
		PRINT 'Tempo total em Minutos: ' + CAST(@total_minutos AS NVARCHAR);
		PRINT ' ';

		SET @data_inicio = GETDATE();
		PRINT '>> Apagando dados da Tabela: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '<< Inserindo dados na Tabela: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\thiag\OneDrive\Área de Trabalho\Learning\Projetos_SQL\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @data_fim = GETDATE();
		SET @total_segundos = DATEDIFF(SECOND, @data_inicio, @data_fim);
		PRINT 'Tempo total em Segundos: ' + CAST (@total_segundos AS NVARCHAR);
		SET @total_minutos = @total_segundos / 60.0;
		PRINT 'Tempo tota em Minutos: ' + CAST (@total_minutos AS NVARCHAR);

		PRINT ' ';
		SET @data_fim_extracao = GETDATE();
		PRINT '====================================';
		PRINT 'Carregamento efetuado com Sucesso!';
		PRINT '- Duração total da Carga: ' + CAST(DATEDIFF(SECOND, @data_inicio_extracao, @data_fim_extracao) AS NVARCHAR) + ' segundos';
		PRINT '====================================';
	END TRY
	BEGIN CATCH
		PRINT '==================================================================';
		PRINT 'Ocorrência(s) de Erro(s) Durante o Carregamento na Camada Bronze';
		PRINT 'Menssagem de Erro: ' + ERROR_MESSAGE();
		PRINT 'Menssagem de Erro: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Menssagem de Erro: ' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '==================================================================';
	END CATCH
END

