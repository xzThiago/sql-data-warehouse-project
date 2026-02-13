/*
===========================
Criar Banco de Dados e Schemas
===========================
Objetivo do Script:
  Este script cria um novo banco de dados chamado "DataWarehouse" após verificar se ele já existe.
  Caso o banco exista, ele será excluído e recriado. Além disso, o script configura três schemas
  dentro do banco de dados: 'bronze', 'silver' e 'gold'.

ATENÇÃO:
  A execução deste script irá excluir completamente o banco de dados "DataWarehouse" caso ele exista.
  Todos os dados contidos no banco serão permanentemente apagados.
  Prossiga com cautela e certifique-se de possuir backups adequados antes de executar este script.
*/

USE master;
GO

-- Verifica se o banco de dados "DataWarehouse" existe e o remove 
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN 
  ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE DataWarehouse;
END;
GO

-- Criar o banco de dados "DataWarehouse"
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Criar os Schemas (bronze, silver, gold)
CREATE SCHEMA bronze;
GO
  
CREATE SCHEMA silver;
GO
  
CREATE SCHEMA gold;
GO
