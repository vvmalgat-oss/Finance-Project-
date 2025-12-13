--DATA CLEANSING USING SQL--

--PERFORMING SENSE CHECKS--

--1. Sample rows

SELECT *
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data` 
LIMIT 5; 


--2. Row and symbol counts

SELECT
COUNT(*) AS row_count,
COUNT(DISTINCT symbol) AS ticker_count
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`;

--503 rows and 503 unique symbols, indicating there are no duplicates. 

--3. Null values

SELECT
SUM(CASE WHEN symbol IS NULL THEN 1 ELSE 0 END) AS null_symbol,
SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS null_name,
SUM(CASE WHEN sector IS NULL THEN 1 ELSE 0 END) AS null_sector,
SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price,
SUM(CASE WHEN priceToEarnings IS NULL THEN 1 ELSE 0 END) AS null_pe,
SUM(CASE WHEN dividendYield IS NULL THEN 1 ELSE 0 END) AS null_div_yield,
SUM(CASE WHEN EarningPerShare IS NULL THEN 1 ELSE 0 END) AS null_eps,
SUM(CASE WHEN WeekLow52 IS NULL THEN 1 ELSE 0 END) AS null_wk_low,
SUM(CASE WHEN WeekHigh52 IS NULL THEN 1 ELSE 0 END) AS null_wk_high,
SUM(CASE WHEN marketCap IS NULL THEN 1 ELSE 0 END) AS null_mktcap,
SUM(CASE WHEN ebitda IS NULL THEN 1 ELSE 0 END) AS null_ebitda,
SUM(CASE WHEN PriceToSales IS NULL THEN 1 ELSE 0 END) AS null_ps,
SUM(CASE WHEN priceToBook IS NULL THEN 1 ELSE 0 END) AS null_pb,
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`;

-- Check number of null values for each field

---4. Range

SELECT
MIN(price) AS min_price,
MAX(price) AS max_price,
MIN(priceToEarnings) AS min_pe,
MAX(priceToEarnings) AS max_pe,
MIN(dividendYield) AS min_div_yield,
MAX(dividendYield) AS max_div_yield,
MIN(EarningPerShare) AS min_eps,
MAX(EarningPerShare) AS max_eps,
MIN(WeekLow52) AS min_wk_low,
MAX(WeekHigh52) AS max_wk_high,
MIN(marketCap) AS min_mktcap,
MAX(marketCap) AS max_mktcap,
MIN(ebitda) AS min_ebitda,
MAX(ebitda) AS max_ebitda,
MIN(PriceToSales) AS min_ps,
MAX(PriceToSales) AS max_ps,
MIN(priceToBook) AS min_pb,
MAX(priceToBook) AS max_pb

FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`;

--------------------------------------------------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------------------------------------------------

-- Analysing dataset by sectors and categorising companies where the price is 0 or less than 0.

SELECT  
Sector,
COUNT(*) AS n,
COUNTIF(price IS NULL OR price <= 0) AS bad_price_rows
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`
GROUP BY sector
ORDER BY n DESC;

--------------------------------------------------------------------------------------------------------------------------

-- Distribution Analysis using declies 

-- We get min and max values with each decile, however we notice that the maximum values skew the data. 

SELECT  
APPROX_QUANTILES(priceToEarnings, 10) AS pe_deciles,
APPROX_QUANTILES(ebitda, 10)          AS ebitda_deciles,
APPROX_QUANTILES(dividendYield, 10)   AS divy_deciles,
APPROX_QUANTILES(PriceToSales, 10)    AS ps_deciles,
APPROX_QUANTILES(priceToBook, 10)     AS pb_deciles,
APPROX_QUANTILES(marketCap, 10)       AS mktcap_deciles
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`;

--------------------------------------------------------------------------------------------------------------------------
