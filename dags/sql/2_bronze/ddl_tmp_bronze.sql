/*
	=======================================================
	DDL Script: Create Bronze Layer Tables
	=======================================================
	Script Purpose:
		This script creates tables for the Bronze layer.
		The Bronze layer stores raw data exactly as it comes from source systems.

		Using the naming convension (snake_case):
			- table name -->   <soyurce system>_<entity_name>
			- column name --> the name in the source system

	Actions Performed:
		- Drops bronze tables.
		- Creates the tables defination for Bronze layer tables.
	=======================================================
*/

-- Create the bronze shcema if it does not exist
CREATE SCHEMA IF NOT EXISTS bronze;


-- CRM - CSV files
-- datasets\source_crm\cust_info.csv
DROP TABLE IF EXISTS bronze.crm_cust_info_tmp;
CREATE TABLE bronze.crm_cust_info_tmp
(
cst_id INT 
, cst_key VARCHAR(50)
, cst_firstname VARCHAR(50)
, cst_lastname VARCHAR(50)
, cst_marital_status VARCHAR(50)
, cst_gndr VARCHAR(50)
, cst_create_date TIMESTAMP
, ingest_dt TIMESTAMP default NOW()
);

-- datasets\source_crm\prd_info.csv
DROP TABLE IF EXISTS bronze.crm_prd_info_tmp;
CREATE TABLE bronze.crm_prd_info_tmp
(
prd_id iNT
, prd_key VARCHAR(50)
, prd_nm VARCHAR(50)
, prd_cost INT
, prd_line VARCHAR(50)
, prd_start_dt TIMESTAMP
, prd_end_dt TIMESTAMP
, ingest_dt TIMESTAMP default NOW()
);

-- datasets\source_crm\sales_details.csv
DROP TABLE IF EXISTS bronze.crm_sales_details_tmp;
CREATE TABLE bronze.crm_sales_details_tmp 
(
sls_ord_num VARCHAR(50)
,sls_prd_key VARCHAR(50)
,sls_cust_id INT
,sls_order_dt INT
,sls_ship_dt INT
,sls_due_dt INT
,sls_sales INT
,sls_quantity INT
,sls_price INT
, ingest_dt TIMESTAMP default NOW()
);


-- ERP - CSV files
-- datasets\source_erp\CUST_AZ12.csv
DROP TABLE IF EXISTS bronze.erp_cust_az12_tmp;
CREATE TABLE bronze.erp_cust_az12_tmp (
cid VARCHAR(50)
, bdate DATE
, gen VARCHAR(50)
, ingest_dt TIMESTAMP default NOW()
);

-- datasets\source_erp\LOC_A101.csv
DROP TABLE IF EXISTS bronze.erp_loc_a101_tmp;
CREATE TABLE bronze.erp_loc_a101_tmp 
(
cid VARCHAR(50)
, cntry VARCHAR(50) 
, ingest_dt TIMESTAMP default NOW()
);


-- datasets\source_erp\PX_CAT_G1V2.csv
DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2_tmp;
CREATE TABLE bronze.erp_px_cat_g1v2_tmp 
(
id  VARCHAR(50)
, cat VARCHAR(50)
, subcat VARCHAR(50)
, maintenance VARCHAR(50)
, ingest_dt TIMESTAMP default NOW()
);

-------------------------------------------------------