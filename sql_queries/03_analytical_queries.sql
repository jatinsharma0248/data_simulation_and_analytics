
-- calculating the total_premium of the year 2024 
SELECT SUM(premium) AS total_premium
FROM policy_sales

-- Calculate the total claim cost for each year (2025 and 2026) with a monthly breakdown
SELECT 
	YEAR(claim_date) AS year,
	MONTH(claim_date) AS month,
	SUM(claim_amount) AS claim_amount
FROM claims
GROUP BY YEAR(claim_date) , MONTH(claim_date)
ORDER BY year , month 




--Calculate the claim cost to premium ratio for each policy tenure (1, 2, 3, and 4 years).
SELECT 
	ps.policy_tenure,
	SUM(c.claim_amount) * 1.0 / SUM(ps.premium) AS cost_to_premium
FROM policy_sales AS ps 
LEFT JOIN claims AS c 
ON ps.vehicle_id = c.vehicle_id
GROUP BY ps.policy_tenure

-- Calculate the claim cost to premium ratio by the month in which the policy was sold (January–December 2024).
SELECT 
	YEAR(policy_purchase_date) AS year,
	MONTH(policy_purchase_date) AS month,
	SUM(c.claim_amount) * 1.0 / SUM(ps.premium) AS cost_to_premium
FROM policy_sales AS ps
LEFT JOIN claims AS c 
ON ps.vehicle_id = c.vehicle_id
GROUP BY YEAR(policy_purchase_date) , MONTH(policy_purchase_date)
ORDER BY year , month 


--If every vehicle that has not yet made a claim eventually files exactly one claim during the
-- remaining policy tenure, estimate the total potential claim liability.
SELECT
SUM(vehicle_value * 0.1) AS claim_amount
FROM policy_sales AS ps
LEFT JOIN claims AS c 
ON c.vehicle_id = ps.vehicle_id
WHERE c.vehicle_id IS NULL ;

-- Assume daily premium = Total Premium ÷ Total Policy Tenure Days. Based on this:
--• Calculate the premium already earned by the company up to February 28, 2026.
--• Estimate the premium expected to be earned monthly for the remaining policy period
-- (assume 46 months remaining).

WITH cte_premium_daily AS (
	SELECT 
		premium,
		policy_start_date ,
		policy_end_date,
		DATEDIFF(DAY , policy_start_date , policy_end_date) AS total_days,
		CAST(premium * 1.0 / DATEDIFF(DAY , policy_start_date , policy_end_date) AS decimal (10 , 2)) AS daily_premium
	FROM policy_sales
)
SELECT 
	SUM(daily_premium * 
	CASE 
		WHEN policy_start_date > '2026-02-28' THEN 0 
		WHEN policy_end_date < '2026-02-28' THEN DATEDIFF(DAY , policy_start_date , policy_end_date)
		ELSE DATEDIFF(DAY , policy_start_date , '2026-02-28' )
	END )AS daily_premium
FROM cte_premium_daily;

WITH cte_premium_daily AS (
	SELECT 
		premium,
		policy_start_date ,
		policy_end_date,
		DATEDIFF(DAY , policy_start_date , policy_end_date) AS total_days,
		CAST(premium * 1.0 / DATEDIFF(DAY , policy_start_date , policy_end_date) AS decimal (10 , 2)) AS daily_premium
	FROM policy_sales
)
select 
	sum(daily_premium * 
	DATEDIFF(DAY , '2026-02-28',policy_end_date)) / 46 AS expected_monthly_premium
from cte_premium_daily
WHERE policy_end_date > '2026-02-28'


	

