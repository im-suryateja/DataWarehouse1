CREATE OR ALTER PROCEDURE silver.load_silver as
BEGIN

	PRINT '>>LOADING CRM TABLES'
	PRINT '_______________________________________________________________________________________________'
	PRINT '>>CRM Product Info Table'

	TRUNCATE TABLE silver.crm_prd_info;
	PRINT '>> Table Truncated and Now Inserting'
	INSERT INTO silver.crm_prd_info(
		prd_id,
		cat_id, 
		prd_key,
		prd_nm, 
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	select 
	prd_id,
	REPLACE(SUBSTRING(prd_key, 1,5), '-','_') as cat_id, --Extract Category ID
	SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key, --Extract Product Key
	prd_nm, 
	ISNULL(prd_cost, 0) as prd_cost, -- Replace Nulls with 0s
	CASE 
			WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
			WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
			WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			ELSE 'n/a'
	END AS prd_line, --Data Normalisation
	CAST(prd_start_dt as DATE) as prd_start_dt, --Type Casting
	CAST(LEAD(prd_start_dt) OVER(partition by prd_key order by prd_start_dt)-1 as DATE) as prd_end_dt
	from bronze.crm_prd_info

	PRINT '_______________________________________________________________________________________________'
	PRINT '>>CRM Customer Info Table'

	TRUNCATE TABLE silver.crm_cust_info;
	PRINT '>> Table Truncated and Now Inserting'
	INSERT INTO silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_material_status,
		cst_gndr,
		cst_create_date
	)
	SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname, --Remove Unnecessary spaces
		TRIM(cst_lastname) AS cst_lastname,
		CASE 
			WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
			WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
			ELSE 'n/a'
		END AS cst_marital_status, --Normalize marital status
		CASE 
			WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			ELSE 'n/a'
		END AS cst_gndr, --Normalize Gender 
		cst_create_date
	FROM (
		SELECT *, 
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		FROM bronze.crm_cust_info
	) t 
	WHERE flag_last = 1; -- Removing Duplicates and holding on to only the recent data

	PRINT '_______________________________________________________________________________________________'

	PRINT '>>CRM Sales Details Table'

	TRUNCATE TABLE silver.crm_sales_details;
	PRINT '>> Table Truncated and Now Inserting'

	INSERT INTO silver.crm_sales_details(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_price,
	sls_quantity
	)
	SELECT 
	  sls_ord_num,
	  sls_prd_key,
	  sls_cust_id,

	  CASE 
		WHEN sls_order_id = 0 OR LEN(sls_order_id) != 8 THEN NULL
		ELSE CAST(CONVERT(VARCHAR(8), sls_order_id) AS DATE)
	  END AS sls_order_dt,

	  CASE 
		WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
		ELSE CAST(CONVERT(VARCHAR(8), sls_ship_dt) AS DATE)
	  END AS sls_ship_dt,

	  CASE 
		WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
		ELSE CAST(CONVERT(VARCHAR(8), sls_due_dt) AS DATE)
	  END AS sls_due_dt,

	  CASE 
		WHEN sls_sales_dt IS NULL OR sls_sales_dt <= 0 OR sls_sales_dt != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales_dt
	  END AS sls_sales,

	  CASE 
		WHEN sls_price IS NULL OR sls_price <= 0 
		THEN sls_sales_dt / NULLIF(sls_quantity, 0)
		ELSE sls_price
	  END AS sls_price,

	  sls_quantity

	FROM bronze.crm_sales_details;

	PRINT '_______________________________________________________________________________________________'
	PRINT '>>LOADING ERP TABLES'
	PRINT '_______________________________________________________________________________________________'

	PRINT '>>ERP Category Info Table'

	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	PRINT '>> Table Truncated and Now Inserting'
	INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat, maintanance)
	select 
	id,
	cat,
	subcat,
	maintanance
	FROM bronze.erp_px_cat_g1v2
	PRINT '_______________________________________________________________________________________________'
	PRINT '>> ERP Customer Info Table'

	TRUNCATE TABLE silver.erp_cust_az12;
	PRINT '>> Table Truncated and Now Inserting'

	INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen
	)

	select
	case when cid LIKE 'NAS%' THEN SUBSTRING(cid, 4,LEN(cid)) --Remove NAS Prefix If present
		ELSE cid
	END cid,
	CASE WHEN bdate> GETDATE() THEN NULL
		ELSE bdate
	END AS bdate, -- Removed dates that are in future
	CASE WHEN TRIM(upper(gen)) IN ('F', 'FEMALE') THEN 'Female'
		 WHEN TRIM(upper(gen)) IN ('M', 'MALE') THEN 'Male'
		 ELSE 'n/a'
	END AS gen --Standardized the data
	FROM bronze.erp_cust_az12
	PRINT '_______________________________________________________________________________________________'
	PRINT '>> ERP Location Table'

	TRUNCATE TABLE silver.erp_loc_a101;
	PRINT '>> Table Truncated and Now Inserting'

	INSERT INTO silver.erp_loc_a101(cid,cntry)

	select REPLACE(cid, '-', '') cid,
	CASE WHEN cntry ='DE' THEN 'Germany'
		 WHEN TRIM(UPPER(cntry)) IN ('USA', 'UNITED STATES', 'US') THEN 'United States'
		 WHEN cntry IS NULL or cntry = '' THEN 'n/a'
		 ELSE cntry
	END AS cntry
	from bronze.erp_loc_a101
END
