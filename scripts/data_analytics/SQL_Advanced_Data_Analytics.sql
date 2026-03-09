USE DataWarehouse;

/*
======================
SQL - Análise de Dados
======================
*/

/*
1: Tendências de mudança ao longo do tempo.

Analise como uma métrica evolui ao longo do tempo. 
Ajuda a acompanhar tendências e a identificar a sazonalidade em seus dados.

Tarefa: Analisar o desempenho de vendas ao longo do tempo.
*/

SELECT
--  DATETRUNC(month, order_date) AS data_pedido, -- Exemplo de saída: 2010-12-01 | 2011-01-01...
	FORMAT(order_date, 'yyyy-MM') AS data_pedido,
	SUM(sales_amount) AS vendas_totais,
	COUNT(DISTINCT customer_key) AS clientes_totais,
	SUM(quantity) AS qtd_totais
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY FORMAT(order_date, 'yyyy-MM');

/*
2: Análise cumulativa

Agregar os dados progressivamente ao longo do tempo.
Ajuda a entender se nossa empresa está crescendo ou em declínio.

Tarefa: Calcular o total de vendas por mês e o total acumulado de vendas ao longo do tempo.
*/

/*
========
Por MÊS
========
*/
SELECT
	data_pedido,
	vendas_totais,
	SUM(vendas_totais) OVER(ORDER BY data_pedido) AS total_vendas_acumulado_por_mes
FROM (
	SELECT
		DATETRUNC(MONTH, order_date) AS data_pedido,
		SUM(sales_amount) AS vendas_totais	
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
) t
/*
========
Por ANO
========
*/
SELECT
	data_pedido,
	vendas_totais,
    SUM(vendas_totais) OVER(PARTITION BY data_pedido ORDER BY data_pedido) total_vendas_acumulado_por_ano
FROM (
	SELECT
        DATETRUNC(YEAR, order_date) AS data_pedido,
		SUM(sales_amount) AS vendas_totais	
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(YEAR, order_date)
) t
/*
============================
Outro Exemplo mais avançado
============================
*/

WITH analise_vendas_mes AS (
	SELECT
        DATETRUNC(MONTH, order_date) AS data_pedido,
		SUM(sales_amount) AS vendas_totais	
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
),
analise_vendas_mes_acumulado AS (
	SELECT
		data_pedido,
		vendas_totais,
		SUM(vendas_totais) OVER(ORDER BY data_pedido) AS total_vendas_acumulado_por_mes,
		LAG(vendas_totais) OVER(ORDER BY data_pedido) AS vendas_anterior -- Busca o valor do mês anterior para o cálculo
	FROM analise_vendas_mes
)
SELECT
	data_pedido,
	vendas_totais,
	-- Cálculo da variação percentual
	CASE 
		WHEN vendas_anterior IS NULL THEN NULL
		ELSE CAST(CAST(((vendas_totais - vendas_anterior) * 100.0 / vendas_anterior) AS DECIMAL(10,2)) AS NVARCHAR) + ' %'
	END AS percentual_variacao,

	-- Coluna descritiva de status
	CASE
		WHEN vendas_anterior IS NULL THEN 'Sem dados anteriores'
		WHEN vendas_totais > vendas_anterior THEN 'Crescimento'
		WHEN vendas_totais < vendas_anterior THEN 'Declinio'
		ELSE 'Estável'
	END AS status_desempenho,
	total_vendas_acumulado_por_mes
FROM analise_vendas_mes_acumulado;
/*
EXEMPLO DE SAÍDA ESPERADA:
| data_pedido | vendas_totais | percentual_variacao| status_desempenho   | total_vendas_acumulado_por_mes|
|-------------|---------------|--------------------|---------------------|-------------------------------|
| 2010-12-01  | 43419         | NULL               | Sem dados anteriores| 43419                         |
| 2011-01-01  | 469795        | 982.00 %           | Crescimento         | 513214                        |
| 2011-02-01  | 466307        | -0.74 %            | Declinio            | 979521                        |
*/


/*
3: Análise de Desempenho

Comparação do valor atual com um valor alvo.
Ajuda a medir o sucesso e comparar o desempenho.

Tarefa: Analise o desempenho anual dos produtos comparando suas vendas 
		com a média de vendas dos produtos e com as vendas do ano anterior.
*/
WITH vendas_anuais_por_produto AS (
	SELECT
		YEAR(f.order_date) AS data_pedido_anual,
		p.product_name,
		SUM(f.sales_amount) AS vendas_atuais
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY 
		YEAR(f.order_date), 
		p.product_name
),
analise_desempenho AS (
	SELECT
		data_pedido_anual,
		product_name,
		vendas_atuais,
		AVG(vendas_atuais) OVER(PARTITION BY product_name) AS media_venda,
		vendas_atuais - AVG(vendas_atuais) OVER(PARTITION BY product_name) AS diferenca_media,
		CASE	
			WHEN vendas_atuais - AVG(vendas_atuais) OVER(PARTITION BY product_name) > 0 THEN 'Acima da Média'
			WHEN vendas_atuais - AVG(vendas_atuais) OVER(PARTITION BY product_name) < 0 THEN 'Abaixo da Média'
			ELSE 'Sem alteração'
		END status_mudanca_media,
		LAG(vendas_atuais) OVER(PARTITION BY product_name ORDER BY data_pedido_anual) AS vendas_ano_anterior
	FROM vendas_anuais_por_produto
)
SELECT top 3
	data_pedido_anual,
	product_name,
	vendas_atuais,
	media_venda,
	diferenca_media,
	status_mudanca_media,
	-- Analise de vendas Ano apos Ano
	vendas_ano_anterior,
	vendas_atuais - vendas_ano_anterior AS diferenca_ano_anterior,
	CASE
		WHEN vendas_atuais - vendas_ano_anterior > 0 THEN 'Aumentou'
		WHEN vendas_atuais - vendas_ano_anterior < 0 THEN 'Diminuiu'
		ELSE 'Sem alteração'
	END AS variacao_ano_anteiror
FROM analise_desempenho
ORDER BY
	product_name,
	data_pedido_anual
/*
EXEMPLO DE SAÍDA
+--------------------+-------------------------+----------------+-------------+-----------------+----------------------+---------------------+------------------------+-----------------------+
| data_pedido_anual  | product_name            | vendas_atuais  | media_venda | diferenca_media | status_mudanca_media | vendas_ano_anterior | diferenca_ano_anterior | variacao_ano_anteiror |
+--------------------+-------------------------+----------------+-------------+-----------------+----------------------+---------------------+------------------------+-----------------------+
| 2012               | All-Purpose Bike Stand  | 159            | 13197       | -13038          | Abaixo da Média      | NULL                | NULL                   | Sem alteração         |
| 2013               | All-Purpose Bike Stand  | 37683          | 13197       | 24486           | Acima da Média       | 159                 | 37524                  | Aumentou              |
| 2014               | All-Purpose Bike Stand  | 1749           | 13197       | -11448          | Abaixo da Média      | 37683               | -35934                 | Diminuiu              |
+--------------------+-------------------------+----------------+-------------+-----------------+----------------------+---------------------+------------------------+-----------------------+
*/

/*
4: Análise Proporcional Parte-todo

Analisa o desempenho de uma parte individual em comparação com o todo, 
permitindo-nos entender qual categoria tem o maior impacto nos negócios.

Tarefa: Quais categorias contribuem mais para as vendas totais?
*/
WITH vendas_por_categoria AS (
	SELECT
		p.category, 
		SUM(f.sales_amount) AS vendas_totais
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON p.product_key = f.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY p.category
)
SELECT
	category,
	vendas_totais,
	SUM(vendas_totais) OVER() AS total_geral_vendas,
	CONCAT(ROUND((CAST(vendas_totais AS FLOAT) / SUM(vendas_totais) OVER()) * 100, 2), ' %') AS porcentagem_do_total_geral
FROM vendas_por_categoria
ORDER BY vendas_totais DESC;

/*
EXEMPLO DE SAÍDA
+-------------+---------------+--------------------+----------------------------+
| category    | vendas_totais | total_geral_vendas | porcentagem_do_total_geral |
+-------------+---------------+--------------------+----------------------------+
| Bikes       | 28311657      | 29351258           | 96.46 %                    |
| Accessories | 699909        | 29351258           | 2.38 %                     |
| Clothing    | 339692        | 29351258           | 1.16 %                     |
+-------------+---------------+--------------------+----------------------------+
*/


/*
5: Segmentação de Dados

Agrupando os dados com base em um intervalo específico.
Ajuda a compreender a correlação entre duas medidas.

Tarefa: Segmentar os produtos em faixas de custo e contar quantos produtos
		se enquadram em cada segmento.
*/
WITH segmentacao_produto AS (
	SELECT
		product_key,
		product_name,
		cost,
		CASE
			WHEN cost < 100 THEN 'Abaixo de 100'
			WHEN cost BETWEEN 100 AND 499 THEN '100-499'
			WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
			ELSE 'Acima de 1000'
		END faixa_custo
	FROM gold.dim_products
--	WHERE cost > 0
)
SELECT
	faixa_custo,
	COUNT(product_key) AS produtos_totais
FROM segmentacao_produto
GROUP BY faixa_custo
ORDER BY produtos_totais DESC;
/*
EXEMPLO DE SAÍDA

| faixa_custo    | produtos_totais |
| -------------- | --------------- |
| Abaixo de 100  | 108             |
| 100–499        | 101             |
| 500–1000       | 45              |
| Acima de 1000  | 39              |
*/

/*
5: Segmentação de Dados

Tarefa: 
Agrupe os clientes em três segmentos com base no comportamento de gastos:
	- VIP: Clientes com pelo menos 12 meses de histórico e gastos superiores a $5.000.
	- Regular: Clientes com pelo menos 12 meses de histórico, mas com gastos de até $5.000 ou menos.
	- Novo: Clientes com tempo de relacionamento inferior a 12 meses.
E encontre o número total de clientes em cada grupo.
*/
WITH gasto_do_cliente AS (
	SELECT
		c.customer_key,
		SUM(f.sales_amount) AS gasto_totais,
		MIN(f.order_date)   AS dt_primeiro_pedido,
		MAX(f.order_date)   AS dt_ultimo_pedido,
		DATEDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS tempo_relacionamento
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
		ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)

SELECT
	segmentacao_clientes,
	COUNT(customer_key) AS total_clientes
FROM (
	SELECT
		customer_key,
	--	gasto_totais,
	--	tempo_relacionamento,
		CASE 
			WHEN tempo_relacionamento >= 12 AND gasto_totais > 5000  THEN 'VIP'
			WHEN tempo_relacionamento >= 12 AND gasto_totais <= 5000 THEN 'Regular'
			ELSE 'Novo'
		END AS segmentacao_clientes
	FROM gasto_do_cliente
) t
GROUP BY segmentacao_clientes;
/*
EXEMPLO DE SÁIDA

| Segmentação de Clientes | Total de Clientes |
| ----------------------- | ----------------- |
| Novo                    | 14631             |
| Regular                 | 2198              |
| VIP                     | 1655              |
 */

 /*
 ====================================
 Construção do Relatório de Clientes
 ====================================

Objetivo:
	- Este relatório consolida métricas importantes e comportamentos dos clientes.

Destaques:
	1. Coleta informações essenciais como nome do cliente, idade e detalhes de transações.
	2. Agrega métricas no nível do cliente:
		- total de pedidos
		- valor total em vendas
		- quantidade total comprada
		- total de produtos diferentes
		- tempo de relacionamento (em meses)
	3. Segmenta os clientes em categorias (VIP, Regular, Novo) e também por faixa etária.
	4. Calcula KPIs importantes:
		- recência (meses desde o último pedido)
		- valor médio por pedido
		- gasto médio mensal
*/
IF OBJECT_ID('gold.vw_relatorio_clientes' , 'V') IS NOT NULL
	DROP VIEW gold.vw_relatorio_clientes;
GO

CREATE VIEW gold.vw_relatorio_clientes AS 
-- 1: Consulta Base: Recupera colunas principais das tabelas de vendas e clientes
WITH consulta_base AS (
	SELECT
		f.order_number		AS numero_pedido,
		f.product_key		AS id_produto,
		f.order_date		AS data_pedido,
		f.sales_amount	    AS valor_venda,
		f.quantity			AS quantidade_vendida,
		c.customer_key		AS id_cliente,
		c.customer_number	AS numero_cliente,
		CONCAT(c.first_name, ' ', c.last_name) AS nome_cliente,
		DATEDIFF(YEAR, c.birthdate, GETDATE()) AS idade
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
		ON f.customer_key = c.customer_key
	WHERE f.order_date IS NOT NULL
),
-- 2: Agregação de Clientes: Resume métricas principais no nível do cliente
agregacao_clientes AS (
	SELECT
		id_cliente,
		numero_cliente,
		nome_cliente,
		idade,
		COUNT(DISTINCT numero_pedido) AS total_pedidos,
		SUM(valor_venda)			  AS valor_total_vendas,
		SUM(quantidade_vendida)       AS quantidade_total_comprada,
		COUNT(DISTINCT id_produto)    AS total_produtos_diferentes,
		MAX(data_pedido)			  AS dt_ultimo_pedido,
		DATEDIFF(MONTH, MIN(data_pedido), MAX(data_pedido)) AS tempo_relacionamento_meses
	FROM consulta_base
	GROUP BY
		id_cliente,
		numero_cliente,
		nome_cliente,
		idade
)

SELECT
	id_cliente,
	numero_cliente,
	nome_cliente,
	idade,

	-- Classificação por faixa etária
	CASE
		WHEN idade < 20 THEN 'Menos de 20'
		WHEN idade BETWEEN 20 AND 29 THEN '20-29'
		WHEN idade BETWEEN 30 AND 39 THEN '30-39'
		WHEN idade BETWEEN 40 AND 49 THEN '40-49'
		WHEN idade BETWEEN 50 AND 59 THEN '50-59'
		ELSE '60+'
	END AS faixa_etaria,

	-- Segmentação de clientes baseada em valor gasto e tempo de relacionamento,
	CASE 
		WHEN tempo_relacionamento_meses >= 12 AND valor_total_vendas > 5000 THEN 'VIP'
		WHEN tempo_relacionamento_meses >= 12 AND valor_total_vendas <= 5000 THEN 'Regular'
		ELSE 'Novo'
	END AS segmento_cliente,

	dt_ultimo_pedido,

	-- Recência: meses desde a ultima compra
	DATEDIFF(MONTH, dt_ultimo_pedido, GETDATE()) AS meses_desde_ultima_compra,

	total_pedidos, 
	valor_total_vendas, 
	quantidade_total_comprada, 
	total_produtos_diferentes, 
	tempo_relacionamento_meses,

	-- Valor médio por pedido
	CASE
		WHEN valor_total_vendas = 0 THEN 0
		ELSE valor_total_vendas / total_pedidos
	END AS valor_medio_por_pedido,

	-- Gasto médio mensal
	CASE
		WHEN tempo_relacionamento_meses = 0 THEN valor_total_vendas
		ELSE valor_total_vendas / tempo_relacionamento_meses
	END AS gasto_medio_mensal

FROM agregacao_clientes;

SELECT * FROM gold.vw_relatorio_clientes;


/* 
===================================
Construção do Relatório de Produtos
===================================

Objetivo:
  - Este relatório consolida métricas e comportamentos importantes dos produtos.

Destaques:
  1. Coleta informações essenciais como nome do produto, categoria, subcategoria e custo.
  2. Agrega métricas no nível do produto:
     - total de pedidos
     - valor total de vendas
     - quantidade total vendida
     - total de clientes únicos
     - tempo de vida do produto (em meses)
  3. Segmenta produtos com base na receita gerada para identificar:
     - Produtos de Alto Desempenho
     - Produtos de Desempenho Médio
     - Produtos de Baixo Desempenho
  4. Calcula KPIs importantes:
     - recência (meses desde a última venda)
     - receita média por pedido
     - receita média mensal 
*/

IF OBJECT_ID('gold.vw_relatorio_produtos', 'V') IS NOT NULL
	DROP VIEW gold.vw_relatorio_produtos;
GO

CREATE VIEW gold.vw_relatorio_produtos AS 
-- 1. Consulta Base: Recupera colunas principais das tabelas de vendas e produtos
WITH consulta_base AS (
	SELECT
		f.order_number  AS numero_pedido,
		f.order_date    AS data_pedido,
		f.customer_key  AS id_cliente,
		f.sales_amount  AS valor_venda,
		f.quantity      AS quantidade_vendida,
		p.product_key   AS id_produto,
		p.product_name  AS nome_produto,
		p.category      AS categoria,
		p.subcategory   AS subcategoria,
		p.cost          AS custo_produto
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
),
-- 2. Agregação de Produtos: Resume métricas principais no nível do produto
agregacao_produtos AS (
	SELECT
		id_produto,
		nome_produto,
		categoria,
		subcategoria,
		custo_produto,
		DATEDIFF(MONTH, MIN(data_pedido), MAX(data_pedido)) AS tempo_vida_meses,
		MAX(data_pedido)				AS dt_ultima_venda,
		COUNT(DISTINCT numero_pedido)	AS total_pedidos,
		COUNT(DISTINCT id_cliente)		AS total_clientes_unicos,
		SUM(valor_venda)				AS valor_total_vendas,
		SUM(quantidade_vendida)			AS quantidade_total_vendida,
		ROUND(
			AVG(CAST(valor_venda AS FLOAT) / NULLIF(quantidade_vendida, 0)),
			2) AS preco_medio_venda

	FROM consulta_base
	GROUP BY
		id_produto,
		nome_produto,
		categoria,
		subcategoria,
		custo_produto
)
SELECT
	id_produto,
	nome_produto,
	categoria,
	subcategoria,
	custo_produto,
	dt_ultima_venda,

	-- Recência: meses desde a ultima venda
	DATEDIFF(MONTH, dt_ultima_venda, GETDATE()) AS meses_desde_ultima_venda,

	-- Segmentação de produtos por desempenho de vendas
	CASE
		WHEN valor_total_vendas > 50000 THEN 'Alto Desempenho'
		WHEN valor_total_vendas >= 10000 THEN 'Desempenho Médio'
		ELSE 'Baixo Desempenho'
	END AS segmento_produto,

	tempo_vida_meses,
	total_pedidos,
	valor_total_vendas,
	quantidade_total_vendida,
	total_clientes_unicos,
	preco_medio_venda,

	-- Receita média por pedido
	CASE 
		WHEN valor_total_vendas = 0 THEN 0
		ELSE valor_total_vendas / total_pedidos
	END AS receita_media_por_pedido,

	-- Receita média mensal
	CASE 
		WHEN tempo_vida_meses = 0 THEN valor_total_vendas
		ELSE valor_total_vendas / tempo_vida_meses
	END AS receita_media_mensal
FROM agregacao_produtos;

SELECT * FROM gold.vw_relatorio_produtos;