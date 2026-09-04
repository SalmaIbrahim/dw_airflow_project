# Data Warehouse Airflow Project

A pipeline designed to orchestrate data ingestion, transformation, and storage into a Data Warehouse using the **Medallion Architecture** (Bronze, Silver, and Gold layers).

---

## 📌 Architecture Overview

This project implements a multi-stage data ingestion and transformation workflow managed by **[Apache Airflow](https://airflow.apache.org/)**:

```
Source Systems (CRM / ERP)
│
▼
[ Bronze Layer ]   ─── Raw ingestion & source-specific staging (PostgreSQL)
│
▼
[ Silver Layer ]   ─── Cleaned, deduplicated, & standardized data
│
▼
[ Gold Layer ]     ─── Business-ready metrics & reporting data models

```

1. **Bronze Layer (Raw Data):** Ingests raw CRM CSV files and downloads ERP datasets directly into staging tables via Airflow DAG tasks (`bronze_layer.py`).
2. **Silver Layer (Cleaned Data):** Standardizes, cleans, and merges raw datasets.
3. **Gold Layer (Analytical Models):** Aggregates data into final analytics-ready tables for reporting and business intelligence.

---

## 🛠️ Tech Stack & Tools

* **Orchestration:** [Apache Airflow](https://airflow.apache.org/) (Taskflow API, Hooks, & SQL Operators)
* **Database:** PostgreSQL
* **Languages & Libraries:** Python (`pendulum`, `requests`, `psycopg2`), SQL, Shell
* **Data Sources:** CRM (Local CSVs), ERP (Downloaded datasets)

---

## 📂 Project Structure

```
dw_airflow_project/
├── dags/
│   ├── datasets/
│   │   ├── links/
│   │   │   └── get_erp_datasets.txt   # Target URLs for ERP datasets
│   │   ├── source_crm/               # Local CSV files for CRM ingestion
│   │   └── source_erp/               # Downloaded ERP CSV files
│   ├── sql/
│   │   ├── 1_db_init/
│   │   │   └── create_schemas.sql    # Data Warehouse schema initializations
│   │   └── 2_bronze/
│   │       ├── ddl_bronze.sql        # DDL for Bronze layer target tables
│   │       ├── ddl_tmp_bronze.sql    # DDL for temporary staging tables
│   │       ├── merge_crm.sql         # SQL query to merge CRM temp data
│   │       └── merge_erp.sql         # SQL query to merge ERP temp data
│   └── bronze_layer.py               # Main Bronze Layer DAG definition
├── README.md
└── requirements.txt

```

---

## ⚙️ DAG Pipeline Breakdown (`bronze_layer`)

The main workflow in `dags/bronze_layer.py` executes the following sequence:

1. **Database Initialization:** Executes SQL scripts to set up schemas (`1_db_init/create_schemas.sql`).
2. **Table Creation:** Prepares permanent DDL structure for the Bronze layer (`ddl_bronze.sql`) and temporary tables (`ddl_tmp_bronze.sql`).
3. **CRM Ingestion:** Dynamically scans `/source_crm/`, ingests CSV files using PostgreSQL `COPY FROM`, and merges them into Bronze tables.
4. **ERP Ingestion:** Reads dataset URLs from `get_erp_datasets.txt`, downloads files dynamically via `requests`, ingests CSVs, and merges them into Bronze tables.

---

## 🚀 Getting Started

### Prerequisites

* Docker & Docker Compose (or a local Apache Airflow installation)
* PostgreSQL Instance

### Configuration

1. **Airflow Connection:** Ensure a PostgreSQL connection named `dwh_postgres_conn` is defined in Airflow:
* **Conn ID:** `dwh_postgres_conn`
* **Conn Type:** `Postgres`
* Set the Host, Schema, Login, Password, and Port corresponding to your database.


2. **Datasets Setup:**
* Place CRM CSV files in `dags/datasets/source_crm/`.
* Add valid dataset download URLs to `dags/datasets/links/get_erp_datasets.txt`.



### Running the DAG

Trigger the `bronze_layer` DAG from the Apache Airflow UI or via CLI:

```bash
docker compose exec airflow-worker airflow dags trigger bronze_layer

```
