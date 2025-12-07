--LOGICAL TEST ON PRICE 

-- 1. Price — should be between 52w low/high when they both exist

SELECT
COUNTIF(WeekLow52 IS NOT NULL AND WeekHigh52 IS NOT NULL
AND (price < WeekLow52 OR price > WeekHigh52)) AS price_outside_52w,
COUNTIF(WeekLow52 IS NOT NULL AND WeekHigh52 IS NOT NULL
AND WeekLow52 > WeekHigh52) AS inverted_52w_range
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`; 

-- 2. (P/E — price / EPS) ≈ reported P/E (less than 2)

SELECT
COUNT(*) AS rows_checked,
COUNTIF(ABS((price / NULLIF(EarningPerShare,0)) - priceToEarnings) > 2) AS pe_mismatch_gt2
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`; 


