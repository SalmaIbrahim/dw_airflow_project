-- Customer birthdate data from ERP system.
WITH tmp_erp_cust_az12 as (
    SELECT DISTINCT 
       cid 
        , bdate 
        , gen      
    FROM bronze.erp_cust_az12_tmp
)
INSERT INTO bronze.erp_cust_az12(
     cid 
    , bdate
    , gen 
)
SELECT 
      s.cid 
    , s.bdate 
    , s.gen 
FROM tmp_erp_cust_az12 s
LEFT JOIN bronze.erp_cust_az12 t
  ON s.cid = t.cid
WHERE t.cid IS NULL; -- New record, insert
----------------------------------
-- cusomer location data from ERP system.
WITH
	TMP_ERP_LOC_A101 AS (
		SELECT DISTINCT
			CID,
			CNTRY
		FROM
			BRONZE.ERP_LOC_A101_TMP
	)
INSERT INTO
	BRONZE.ERP_LOC_A101 (CID, CNTRY)
SELECT
	S.CID,
	S.CNTRY
FROM
	TMP_ERP_LOC_A101 S
	LEFT JOIN BRONZE.ERP_LOC_A101 T ON S.CID = T.CID
WHERE
	T.CID IS NULL -- New record, insert
;
---------------------------
-- Category data from ERP system.
WITH tmp_px_cat_g1v2 as (
    SELECT DISTINCT 
       id  
        , cat 
        , subcat 
        , maintenance      
    FROM bronze.erp_px_cat_g1v2_tmp
)
INSERT INTO bronze.erp_px_cat_g1v2(
     id  
    , cat 
    , subcat 
    , maintenance
)
SELECT 
      s.id  
    , s.cat 
    , s.subcat 
    , s.maintenance
FROM tmp_px_cat_g1v2 s
LEFT JOIN bronze.erp_px_cat_g1v2 t
  ON s.id = t.id
WHERE t.id IS NULL; -- New record, insert
