
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME
	BEGIN TRY
		PRINT '__________________________________________________________________';
		PRINT 'Loading Bronze Layer';
		PRINT '__________________________________________________________________';
		
		
		PRINT '__________________________________________________________________';
		PRINT 'Loading CRM Tables';
		PRINT '__________________________________________________________________';
		
		SET @start_time =GETDATE(); 
		TRUNCATE TABLE bronze.crm_cust_info;

		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\surya\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time =GETDATE();
		PRINT ' >> Load Duration : ' + Cast(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		TRUNCATE TABLE bronze.crm_prd_info;

		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\surya\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SELECT * from bronze.crm_prd_info


		TRUNCATE TABLE bronze.crm_sales_details;

		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\surya\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT '__________________________________________________________________';
		PRINT 'Loading ERP Tables';
		PRINT '__________________________________________________________________';
		TRUNCATE TABLE bronze.erp_cust_az12;

		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\surya\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);


		TRUNCATE TABLE bronze.erp_loc_a101;

		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\surya\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);


		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\surya\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
	END TRY
	BEGIN CATCH
		PRINT '_________________________________________________________________________'
		print 'ERROR OCCURRED DURING LOADING BRONZE LAYER'
		print '_________________________________________________________________________'
	END CATCH
END
