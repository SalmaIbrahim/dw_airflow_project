-- Merging cust_info table
-- (UPSERT - UPDATE/INSERT) & (SCD - TYPE 1)
-- INSERT INTO bronze.crm_cust_info ( -- Needs a PK
-- cst_id 
-- , cst_key
-- , cst_firstname
-- , cst_lastname
-- , cst_marital_status
-- , cst_gndr
-- , cst_create_date )
-- SELECT 
-- cst_id 
-- , cst_key
-- , cst_firstname
-- , cst_lastname
-- , cst_marital_status
-- , cst_gndr
-- , cst_create_date 
-- FROM ( SELECT DISTINCT * FROM bronze.crm_cust_info_tmp) tmp
-- ON CONFLICT (cst_key) DO UPDATE 
-- SET 
--     cst_id = EXCLUDED.cst_id
--   , cst_firstname = EXCLUDED.cst_firstname
--   , cst_lastname = EXCLUDED.cst_lastname
--   , cst_marital_status = EXCLUDED.cst_marital_status
--   , cst_gndr = EXCLUDED.cst_gndr
--   , cst_create_date = EXCLUDED.cst_create_date
-- ;
WITH upsert AS (
    UPDATE bronze.crm_cust_info t
    SET
        cst_key           = s.cst_key,
        cst_firstname     = s.cst_firstname,
        cst_lastname      = s.cst_lastname,
        cst_marital_status = s.cst_marital_status,
        cst_gndr          = s.cst_gndr,
        cst_create_date   = s.cst_create_date
    FROM bronze.crm_cust_info_tmp s
    WHERE t.cst_key = s.cst_key

    RETURNING t.cst_key
)
INSERT INTO bronze.crm_cust_info
SELECT * FROM bronze.crm_cust_info_tmp
WHERE NOT EXISTS (
    SELECT 1 FROM upsert u WHERE u.cst_key = crm_cust_info_tmp.cst_key
);
------------------------------------------------------------------------
-- Merging prd_info table
-- UPSERT & (SCD - Type 2)
-- UPDATE
UPDATE bronze.crm_prd_info 
  SET 
    prd_end_dt = (s.prd_start_dt - INTERVAL '1 day')
FROM bronze.crm_prd_info t
JOIN bronze.crm_prd_info_tmp s
  ON t.prd_key = s.prd_key
WHERE t.prd_end_dt IS NULL -- Active record
AND t.prd_start_dt < s.prd_start_dt; -- New record has later start date

---
-- INSERT (new record for new product or changed product)
WITH tmp_prod_info as (
    SELECT DISTINCT 
        prd_id 
        , prd_key 
        , prd_nm 
        , prd_cost 
        , prd_line 
        , prd_start_dt 
        , prd_end_dt 
    FROM bronze.crm_prd_info_tmp
)
INSERT INTO bronze.crm_prd_info (
  prd_id 
  , prd_key 
  , prd_nm 
  , prd_cost 
  , prd_line 
  , prd_start_dt 
  , prd_end_dt
)
SELECT 
  s.prd_id 
  , s.prd_key 
  , s.prd_nm 
  , s.prd_cost 
  , s.prd_line 
  , s.prd_start_dt 
  , s.prd_end_dt
FROM tmp_prod_info s
LEFT JOIN bronze.crm_prd_info t
  ON s.prd_key = t.prd_key
WHERE t.prd_key IS NULL; -- New record, insert
------------------------------------------------------------------------
-- Sales Details
-- Insert only new records, no updates (SCD - Type 1)
WITH tmp_sales_details as (
    SELECT DISTINCT 
       sls_ord_num      
        ,sls_prd_key    
        ,sls_cust_id    
        ,sls_order_dt   
        ,sls_ship_dt    
        ,sls_due_dt     
        ,sls_sales      
        ,sls_quantity   
        ,sls_price      
    FROM bronze.crm_sales_details_tmp
)
INSERT INTO bronze.crm_sales_details (
     sls_ord_num      
    ,sls_prd_key    
    ,sls_cust_id    
    ,sls_order_dt   
    ,sls_ship_dt    
    ,sls_due_dt     
    ,sls_sales      
    ,sls_quantity   
    ,sls_price  
)
SELECT 
  	s.sls_ord_num      
    , s.sls_prd_key    
    , s.sls_cust_id    
    , s.sls_order_dt   
    , s.sls_ship_dt    
    , s.sls_due_dt     
    , s.sls_sales      
    , s.sls_quantity   
    , s.sls_price  
FROM tmp_sales_details s
LEFT JOIN bronze.crm_sales_details t
  ON s.sls_ord_num = t.sls_ord_num
WHERE t.sls_ord_num IS NULL; -- New record, insert
