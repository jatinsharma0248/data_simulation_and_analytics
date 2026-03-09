
/*
	=============================================================================================

	STORED PROCEUDRES : 'create_policy_sales' & 'create_claims'

	PURPOSE : These stored procedures are used to create the tables policy_sales
			  and claims. Both the tables are first removed from the database
			  and then are re-created. 

	WARNING : Running these block of code will restructure your policy_sales &
			  claims table. If data is important make sure to take backup first.
			
	STEPS :	  Step - 1 -> Run this code first to create policy_sales : EXEC create_policy_sales 
			  Step - 2 -> Run this code after step 1 to create claims table : EXEC create_claims

	=============================================================================================
*/


CREATE OR ALTER PROCEDURE create_policy_sales AS 
BEGIN 
	DECLARE @start_time DATETIME , @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME
	SET @batch_start_time = GETDATE()
	SET @start_time = GETDATE();
	PRINT 'Removing customers Table'
	-- Removing Customers table if it exits 
	IF OBJECT_ID ('customers') IS NOT NULL
		DROP TABLE customers

	PRINT 'Creating Table Customers & Inserting Data into customers Table';
	-- Using Cte it took around 60+ seconds on an average 
	/*WITH cte_customers AS (
		SELECT 1 AS id
		UNION ALL 
		SELECT id + 1 
		FROM cte_customers
		WHERE id < 1000000
		)*/

	
	-- Inserting Data into Customers
	
	SELECT TOP 1000000
	ROW_NUMBER() OVER(ORDER BY (SELECT NULL))  AS customer_id
	INTO customers
	FROM sys.objects AS a 
	CROSS JOIN sys.objects AS b
	CROSS JOIN sys.objects AS c 

	SET @end_time = GETDATE();
	PRINT 'Time Taken to create customer Table : ' + CAST(DATEDIFF(SECOND , @start_time , @end_time) AS NVARCHAR) + 's.'
	SET @start_time = GETDATE();

	PRINT 'Removing Sales Policy Table'
	-- Removing policy_sales if already Exists
	IF OBJECT_ID ('policy_sales') IS NOT NULL
		DROP TABLE policy_sales
	
	PRINT 'Creating & Inserting Data into Sales Policy Table';
	-- Creating policy_sales Table
	SELECT 
		customer_id,
		vehicle_id,
		vehicle_value,
		100 * policy_tenure AS premium,
		policy_purchase_date,
		DATEADD(DAY , 365 , policy_purchase_date) AS policy_start_date,
		DATEADD(YEAR , policy_tenure , DATEADD(DAY , 365 ,policy_purchase_date)) AS policy_end_date,
		policy_tenure
	INTO policy_sales
	FROM (
	SELECT 
		customer_id,
		customer_id AS vehicle_id ,
		100000 AS vehicle_value,
		DATEADD(DAY , (customer_id - 1) % 366 , '2024-01-01') AS policy_purchase_date,
		CASE 
			WHEN customer_id % 10 IN (0 ,1) THEN 1
			WHEN customer_id % 10 IN (2,3,4) THEN 2
			WHEN customer_id % 10 IN (5,6,7,8) THEN 3
			ELSE 4 
		END AS policy_tenure
	FROM customers AS C 
	)T 
	SET @end_time = GETDATE();
	PRINT 'Time Taken to create policy sales Table : ' + CAST(DATEDIFF(SECOND , @start_time , @end_time) AS NVARCHAR) + 's.'
	PRINT '';

	CREATE INDEX idx_policy_sales_vehicle
	ON policy_sales(vehicle_id);
	SET @batch_end_time = GETDATE();
	PRINT '---------------------------------------------------'
	PRINT 'Total Time for completing the batch  : ' + CAST(DATEDIFF(SECOND , @batch_start_time ,@batch_end_time) AS NVARCHAR) +'s.'
	PRINT '---------------------------------------------------'
END
GO

CREATE OR ALTER PROCEDURE create_claims AS 
BEGIN
	DECLARE @start_time DATETIME , @end_time DATETIME 
	SET @start_time = GETDATE()
	PRINT'Removing Claims Table'
	IF OBJECT_ID('claims') IS NOT NULL 
		DROP TABLE claims

	PRINT 'Creating & Inserting Data Into Claims Table';
	WITH cte_eligibility_2025 AS (
		SELECT 
			*,
			ROW_NUMBER() OVER(ORDER BY customer_id) AS rn,
			COUNT(*) OVER() AS total_rows 
			FROM policy_sales
			WHERE policy_start_date >= '2025-01-01' AND policy_start_date < '2026-01-01'	
					AND DAY(policy_purchase_date) IN (7,14,21,28) 
	), cte_claims_2025 AS ( 
			SELECT 
				rn AS claim_id,
				customer_id,
				vehicle_id,
				vehicle_value * 0.10 AS claim_amount,
				policy_start_date AS claim_date,
				1 AS claim_type
			FROM cte_eligibility_2025
			WHERE rn <= CAST (total_rows * 0.30 AS INT) 
	)	
	SELECT * INTO claims FROM cte_claims_2025;

	DECLARE @base_claim_count INT;
	SELECT @base_claim_count = COUNT(*) FROM claims;

	WITH cte_eligibility_2026 AS (
		SELECT *,
			   ROW_NUMBER() OVER(ORDER BY customer_id) AS rn,
			   COUNT(*) OVER() AS total_rows
		FROM policy_sales
		WHERE policy_tenure = 4
		AND policy_start_date <= '2026-02-28'
		AND policy_end_date > '2026-01-01'
	),
	cte_claims_2026 AS (
		SELECT
			rn + @base_claim_count AS claim_id,
			e_2026.customer_id,
			e_2026.vehicle_id,
			vehicle_value * 0.10 AS claim_amount,
			DATEADD(DAY,(rn-1)%59,'2026-01-01') AS claim_date,
			CASE
				WHEN c_2025.vehicle_id IS NOT NULL THEN 2
				ELSE 1
			END AS claim_type
		FROM cte_eligibility_2026 e_2026
		LEFT JOIN claims c_2025
		ON e_2026.vehicle_id = c_2025.vehicle_id
		WHERE rn <= CAST(total_rows * 0.10 AS INT)
	)

	INSERT INTO claims
	SELECT * FROM cte_claims_2026;
	CREATE INDEX idx_claims_vehicle
	ON claims(vehicle_id);
	SET @end_time = GETDATE();
	PRINT '---------------------------------------------------'
	PRINT 'Total Time for creating Sales Policy Table : ' + CAST(DATEDIFF(SECOND , @start_time ,@end_time) AS NVARCHAR) +'s.'
	PRINT '---------------------------------------------------'
END



