-- Identifying which policy tenure appears most profitable 
 
SELECT 
	ps.policy_tenure , 
	SUM(COALESCE(c.claim_amount , 0)) * 1.0 / SUM(ps.premium)  AS claim_to_premium,
	RANK() OVER(ORDER BY SUM(COALESCE(c.claim_amount , 0)) * 1.0 / SUM(ps.premium)) AS tenure_rnk
FROM policy_sales as ps
LEFT JOIN claims as c 
on c.vehicle_id = ps.vehicle_id
GROUP BY policy_tenure

-- Policy tenure with the lowest claim-to-premium ratio is considered
-- the most profitable since it generates more premium revenue relative
-- to claims paid.

-- identify the loss ratio 

SELECT 
	SUM(c.claim_amount) * 1.0 / SUM(ps.premium) AS loss_ratio
FROM policy_sales AS ps
LEFT JOIN claims AS c 
ON ps.vehicle_id = c.vehicle_id

