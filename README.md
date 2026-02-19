# Data Warehouse e Projeto Analítico

Bem-vindo ao repositório do **Projeto de Data Warehouse e Analytics**! 🚀  
Este projeto demonstra uma solução completa de *data warehousing* e análise de dados, desde a construção do data warehouse até a geração de insights acionáveis. Desenvolvido como um projeto de portfólio, ele destaca boas práticas amplamente utilizadas na indústria de **Engenharia de Dados** e **Analytics**.

---

## 🏗️ Arquitetura de Dados

A arquitetura de dados deste projeto segue o padrão **Medallion Architecture**, composta pelas camadas **Bronze, Silver e Gold**.
![](https://github.com/xzThiago/sql-data-warehouse-project/blob/main/docs/arquitetura_datawarehouse.png)

### 🔹 Camada Bronze
- Armazena os dados brutos exatamente como são recebidos das fontes de origem.
- Os dados são ingeridos a partir de arquivos **CSV** para um banco de dados **SQL Server**.

### 🔹 Camada Silver
- Responsável pelos processos de **limpeza**, **padronização** e **normalização** dos dados.
- Prepara os dados para análise, garantindo maior qualidade e consistência.

### 🔹 Camada Gold
- Contém dados prontos para o negócio (*business-ready*).
- Os dados são modelados em um **Esquema Estrela (Star Schema)**, otimizado para relatórios e análises.

---

## 📖 Visão Geral do Projeto

Este projeto envolve:

- **Arquitetura de Dados:** Design de um Data Warehouse moderno utilizando Arquitetura Medalhão (Bronze, Silver e Gold).
- **Pipelines de ETL:** Extração, transformação e carregamento de dados das fontes para o data warehouse.
- **Modelagem de Dados:** Desenvolvimento de tabelas fato e dimensão otimizadas para consultas analíticas.
- **Analytics e Relatórios:** Criação de relatórios e dashboards baseados em SQL para geração de insights acionáveis.

---

## 🎯 Público-Alvo e Competências Demonstradas

Este repositório é um excelente recurso para profissionais e estudantes que desejam demonstrar conhecimento em:

- SQL Development  
- Data Architecture  
- Data Engineering  
- ETL Pipeline Development  
- Data Modeling  
- Data Analytics  

---

## 🛠️ Ferramentas e Recursos Utilizados

> **Tudo utilizado neste projeto é gratuito**

- **Datasets:** Conjunto de dados do projeto (arquivos CSV).
- **SQL Server Express:** Servidor leve para hospedagem do banco de dados SQL.
- **SQL Server Management Studio (SSMS):** Interface gráfica para gerenciamento e interação com o banco de dados.
- **GitHub:** Versionamento de código e colaboração.
- **DrawIO:** Criação de diagramas de arquitetura, modelos e fluxos de dados.
---

## 🚀 Requisitos do Projeto

### 🏗️ Construção do Data Warehouse (Data Engineering)

#### 🎯 Objetivo
Desenvolver um data warehouse moderno utilizando **SQL Server** para consolidar dados de vendas, permitindo análises e suporte à tomada de decisão.

#### 📌 Especificações
- **Fontes de Dados:** Importação de dados de dois sistemas de origem (**ERP** e **CRM**) fornecidos em arquivos CSV.
- **Qualidade dos Dados:** Limpeza, padronização e tratamento de inconsistências antes da análise.
- **Integração:** Consolidação das fontes em um único modelo de dados otimizado para consultas analíticas.
- **Escopo:** Utilização apenas do dataset mais recente; não há necessidade de historização dos dados.
- **Documentação:** Documentação clara e acessível para usuários de negócio e equipes técnicas.

---

### 📊 BI: Analytics e Relatórios (Data Analysis)

#### 🎯 Objetivo
Desenvolver análises baseadas em **SQL** para fornecer insights detalhados sobre:

- **Comportamento dos Clientes**
- **Performance de Produtos**  
- **Tendências de Vendas**  

Esses insights capacitam os stakeholders com métricas-chave do negócio, apoiando decisões estratégicas.
