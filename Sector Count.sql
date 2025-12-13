-- Analysing dataset by sectors and categorising companies where the price is 0 or less than 0.

SELECT  
Sector,
COUNT(*) AS n,
COUNTIF(price IS NULL OR price <= 0) AS bad_price_rows
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`
GROUP BY sector
ORDER BY n DESC;