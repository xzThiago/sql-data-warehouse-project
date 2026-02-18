# Catálogo de Dados da Camada Gold

## Visão Geral
A Camada Gold é a representação de dados em nível de negócio, estruturada para suportar casos de uso analíticos e de relatórios. Ela é composta por **tabelas de dimensão** e **tabelas de fato** para métricas específicas do negócio.

---

### 1. **gold.dim_customers**
- **Propósito:** Armazena detalhes dos clientes enriquecidos com dados demográficos e geográficos.
- **Colunas:**

| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| customer_key     | INT           | Chave substituta que identifica exclusivamente cada registro de cliente na tabela de dimensão. |
| customer_id      | INT           | Identificador numérico exclusivo atribuído a cada cliente.                                   |
| customer_number  | NVARCHAR(50)  | Identificador alfanumérico que representa o cliente, utilizado para rastreamento e referência. |
| first_name       | NVARCHAR(50)  | Primeiro nome do cliente, conforme registrado no sistema.                                    |
| last_name        | NVARCHAR(50)  | Sobrenome do cliente.                                                                         |
| country          | NVARCHAR(50)  | País de residência do cliente (ex: 'Australia').                                             |
| marital_status   | NVARCHAR(50)  | Estado civil do cliente (ex: 'Married', 'Single').                                           |
| gender           | NVARCHAR(50)  | Gênero do cliente (ex: 'Male', 'Female', 'n/a').                                             |
| birthdate        | DATE          | Data de nascimento do cliente, formatada como YYYY-MM-DD (ex: 1971-10-06).                   |
| create_date      | DATE          | Data e hora em que o registro do cliente foi criado no sistema.                              |

---

### 2. **gold.dim_products**
- **Propósito:** Fornece informações sobre os produtos e seus atributos.
- **Colunas:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| product_key         | INT           | Chave substituta que identifica exclusivamente cada registro de produto na tabela de dimensão de produtos. |
| product_id          | INT           | Identificador exclusivo atribuído ao produto para rastreamento e referência internos.        |
| product_number      | NVARCHAR(50)  | Código alfanumérico estruturado que representa o produto, frequentemente usado para categorização ou inventário. |
| product_name        | NVARCHAR(50)  | Nome descritivo do produto, incluindo detalhes principais como tipo, cor e tamanho.          |
| category_id         | NVARCHAR(50)  | Identificador exclusivo da categoria do produto, vinculando-o à sua classificação de alto nível. |
| category            | NVARCHAR(50)  | Classificação mais ampla do produto (ex: Bikes, Components) para agrupar itens relacionados. |
| subcategory         | NVARCHAR(50)  | Classificação mais detalhada do produto dentro da categoria, como o tipo de produto.         |
| maintenance_required| NVARCHAR(50)  | Indica se o produto requer manutenção (ex: 'Yes', 'No').                                     |
| cost                | INT           | Custo ou preço base do produto, medido em unidades monetárias.                               |
| product_line        | NVARCHAR(50)  | Linha ou série específica à qual o produto pertence (ex: Road, Mountain).                    |
| start_date          | DATE          | Data em que o produto se tornou disponível para venda ou uso, armazenada no sistema.         |

---

### 3. **gold.fact_sales**
- **Propósito:** Armazena dados transacionais de vendas para fins analíticos.
- **Colunas:**

| Column Name     | Data Type     | Description                                                                                   |
|-----------------|---------------|-----------------------------------------------------------------------------------------------|
| order_number    | NVARCHAR(50)  | Identificador alfanumérico exclusivo para cada pedido de venda (ex: 'SO54496').              |
| product_key     | INT           | Chave substituta que vincula o pedido à tabela de dimensão de produtos.                      |
| customer_key    | INT           | Chave substituta que vincula o pedido à tabela de dimensão de clientes.                      |
| order_date      | DATE          | Data em que o pedido foi realizado.                                                           |
| shipping_date   | DATE          | Data em que o pedido foi enviado ao cliente.                                                  |
| due_date        | DATE          | Data de vencimento do pagamento do pedido.                                                    |
| sales_amount    | INT           | Valor monetário total da venda para o item da linha, em unidades inteiras de moeda (ex: 25). |
| quantity        | INT           | Número de unidades do produto solicitadas para o item da linha (ex: 1).                      |
| price           | INT           | Preço por unidade do produto para o item da linha, em unidades inteiras de moeda (ex: 25).   |
