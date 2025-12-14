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
-- CREATING A CLEAN VIEW WHERE PRICE, marketCap, PriceToSales, priceToBook AND priceToEarnings are greater than 0. 

CREATE OR REPLACE VIEW `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean` AS
SELECT
symbol,
name,
sector,
price,
priceToEarnings,
dividendYield,
EarningPerShare,
WeekLow52,
WeekHigh52,
marketCap,
ebitda,
PriceToSales,
priceToBook,
SecFillings
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data`
WHERE price > 0
AND marketCap > 0
AND PriceToSales > 0
AND priceToBook > 0
AND priceToEarnings > 0;

--------------------------------------------------------------------------------------------------------------------------

-- 1. Check counts (total rows, distinct symbols, distinct sectors)

SELECT 
COUNT(*) AS total_rows,
COUNT(DISTINCT symbol) AS unique_symbols,
COUNT(DISTINCT sector) AS sectors
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`;

-- 2. Distribution Profiling (Sectors)

SELECT
sector,
COUNT(*) AS n,
ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct -- (Percentage of companies in the sector over the total amount of companies)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
GROUP BY sector
ORDER BY n DESC;

-- 3. Summary stats (Min, Max, Avg)

SELECT
'price' AS metrics,
MIN(price) AS min,
MAX(price) AS max,
AVG(price) AS avg
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
UNION ALL
SELECT 
'priceToEarnings',
MIN(priceToEarnings), 
MAX(priceToEarnings), 
AVG(priceToEarnings)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
UNION ALL
SELECT 
'dividendYield',
MIN(dividendYield),
MAX(dividendYield),
AVG(dividendYield)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
UNION ALL
SELECT 'ebitda',
MIN(ebitda), 
MAX(ebitda), 
AVG(ebitda)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
UNION ALL
SELECT 
'PriceToSales', 
MIN(PriceToSales), 
MAX(PriceToSales), 
AVG(PriceToSales)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
UNION ALL
SELECT 
'priceToBook',
MIN(priceToBook),
MAX(priceToBook),
AVG(priceToBook)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`

--------------------------------------------------------------------------------------------------------------------------

-- Profiling Data - Checking null values 

SELECT
'price' AS metric,
COUNTIF(price IS NULL) AS missing
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean` UNION ALL
SELECT 
'priceToEarnings',
COUNTIF(priceToEarnings IS NULL)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean` UNION ALL
SELECT
'dividendYield',
COUNTIF(dividendYield IS NULL)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean` UNION ALL
SELECT
'EarningPerShare',
COUNTIF(EarningPerShare IS NULL)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean` UNION ALL
SELECT 
'ebitda',
COUNTIF(ebitda IS NULL)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean` UNION ALL
SELECT 
'PriceToSales',
COUNTIF(PriceToSales IS NULL)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean` UNION ALL
SELECT 
'priceToBook',
COUNTIF(priceToBook IS NULL)
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean` 

--------------------------------------------------------------------------------------------------------------------------

-- Profiling Data - Outlier detection using IQR

WITH bounds AS (
SELECT
metric,
Q1,
Q3,
(Q3 - Q1) AS iqr,
Q1 - 1.5 * (Q3 - Q1) AS lower_bound,
Q3 + 1.5 * (Q3 - Q1) AS upper_bound
FROM (
SELECT 
'priceToEarnings' AS metric,
APPROX_QUANTILES(priceToEarnings, 4)[OFFSET(1)] AS Q1,
APPROX_QUANTILES(priceToEarnings, 4)[OFFSET(3)] AS Q3
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
UNION ALL
SELECT 
'PriceToSales', 
APPROX_QUANTILES(PriceToSales, 4)[OFFSET(1)],
APPROX_QUANTILES(PriceToSales, 4)[OFFSET(3)]
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
)
)
SELECT 
metric, 
lower_bound, 
upper_bound
FROM bounds;

--------------------------------------------------------------------------------------------------------------------------

--Profiling Data - Sector Nulls 

SELECT
sector,
COUNT(*) AS n,
COUNTIF(priceToEarnings IS NULL) AS null_pe,
COUNTIF(dividendYield IS NULL) AS null_div,
COUNTIF(ebitda IS NULL) AS null_ebitda
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`
GROUP BY sector
ORDER BY n DESC;

--------------------------------------------------------------------------------------------------------------------------

-- Cleaning Data - Missing dividendYield and ebitda

CREATE OR REPLACE VIEW `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean_step1` AS
SELECT
symbol, 
name,
INITCAP(TRIM(sector)) AS sector,
price,
priceToEarnings,
IFNULL(dividendYield, 0) AS dividendYield,
EarningPerShare,
WeekLow52,
WeekHigh52,
marketCap,
IFNULL(ebitda, 0) AS ebitda,
PriceToSales,
priceToBook
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean`; 

--------------------------------------------------------------------------------------------------------------------------

-- Cleaning Data - Reducing Sector Variations and Dropping the Outliers that are above the upper bound

CREATE OR REPLACE VIEW `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean_step2` AS
WITH mapped AS (
SELECT
symbol,
name,
CASE
-- *GROUPING SECTORS*
WHEN sector IS NULL OR TRIM(sector) = '' THEN 'Unclassified'
-- Real Estate
WHEN UPPER(sector) LIKE '%REIT%' 
OR UPPER(sector) LIKE '%REAL ESTATE%' 
THEN 'Real Estate'
-- Financials
WHEN UPPER(sector) LIKE '%BANK%' 
OR UPPER(sector) LIKE '%INSUR%' 
OR UPPER(sector) LIKE '%CAPITAL MARKET%' 
OR UPPER(sector) LIKE '%FINAN%'
OR UPPER(sector) LIKE '%ASSET MANAGE%' 
OR UPPER(sector) LIKE '%BROKER%'
THEN 'Financials'
-- Information Technology
WHEN UPPER(sector) LIKE '%SOFTWARE%' OR UPPER(sector) LIKE '%SEMICON%'
OR UPPER(sector) LIKE '%TECH%' OR UPPER(sector) LIKE '%HARDWARE%'
OR UPPER(sector) LIKE '%IT %' OR UPPER(sector) = 'IT'
OR UPPER(sector) LIKE '%DATA%' OR UPPER(sector) LIKE '%ELECTRONIC%'
THEN 'Information Technology'
-- Communication Services
WHEN UPPER(sector) LIKE '%TELECOM%' 
OR UPPER(sector) LIKE '%COMMUNICAT%'
OR UPPER(sector) LIKE '%MEDIA%' 
OR UPPER(sector) LIKE '%ENTERTAIN%'
OR UPPER(sector) LIKE '%INTERACTIVE%'
THEN 'Communication Services'
-- Health Care
WHEN UPPER(sector) LIKE '%HEALTH%' OR UPPER(sector) LIKE '%PHARM%'
OR UPPER(sector) LIKE '%BIOTECH%' OR UPPER(sector) LIKE '%MEDICAL%'
OR UPPER(sector) LIKE '%LIFE SCIENCE%'
THEN 'Health Care'
-- Consumer Staples
WHEN UPPER(sector) LIKE '%CONSUMER STAPLES%' 
OR UPPER(sector) LIKE '%CONSUMER DEFENSIVE%'
OR UPPER(sector) LIKE '%FOOD%' 
OR UPPER(sector) LIKE '%BEVERAGE%'
OR UPPER(sector) LIKE '%TOBACCO%' 
OR UPPER(sector) LIKE '%HOUSEHOLD%'
OR UPPER(sector) LIKE '%PERSONAL PRODUCT%' 
OR UPPER(sector) LIKE '%STAPLES RETAIL%'
THEN 'Consumer Staples'
-- Consumer
WHEN UPPER(sector) LIKE '%CONSUMER DISCRETIONARY%' 
OR UPPER(sector) LIKE '%AUTOM%' 
OR UPPER(sector) LIKE '%RETAIL%'
OR UPPER(sector) LIKE '%TEXTILE%'
OR UPPER(sector) LIKE '%APPAREL%' 
OR UPPER(sector) LIKE '%LUXURY%'
OR UPPER(sector) LIKE '%HOTEL%' 
OR UPPER(sector) LIKE '%RESTAURANT%'
OR UPPER(sector) LIKE '%LEISURE%' 
OR UPPER(sector) LIKE '%E-COMMERCE%'
THEN 'Consumer'
-- Industrials
WHEN UPPER(sector) LIKE '%INDUSTR%' 
OR UPPER(sector) LIKE '%AEROSPACE%'
OR UPPER(sector) LIKE '%DEFENSE%'
OR UPPER(sector) LIKE '%MACHIN%'
OR UPPER(sector) LIKE '%CONSTRUCTION%' 
OR UPPER(sector) LIKE '%ENGINEER%'
OR UPPER(sector) LIKE '%TRANSPORT%' 
OR UPPER(sector) LIKE '%LOGISTIC%'
OR UPPER(sector) LIKE '%COMMERCIAL SERVICES%'
THEN 'Industrials'
-- Materials
WHEN UPPER(sector) LIKE '%MATERIAL%' 
OR UPPER(sector) LIKE '%CHEMIC%'
OR UPPER(sector) LIKE '%METAL%' 
OR UPPER(sector) LIKE '%MINING%'
OR UPPER(sector) LIKE '%PAPER%' 
OR UPPER(sector) LIKE '%FOREST%'
THEN 'Materials'
-- Energy
WHEN UPPER(sector) LIKE '%ENERGY%' 
OR UPPER(sector) LIKE '%OIL%'
OR UPPER(sector) LIKE '%GAS%' 
OR UPPER(sector) LIKE '%COAL%'
OR UPPER(sector) LIKE '%RENEWABLE%' 
OR UPPER(sector) LIKE '%SOLAR%'
THEN 'Energy'
-- Utilities
WHEN UPPER(sector) LIKE '%UTILITY%' 
OR UPPER(sector) LIKE '%ELECTRIC%'
OR UPPER(sector) LIKE '%WATER%' 
OR UPPER(sector) LIKE '%POWER%'
OR UPPER(sector) LIKE '%GAS UTIL%'
THEN 'Utilities'
ELSE sector
END AS sector_std,
price,
priceToEarnings,
dividendYield,
EarningPerShare,
WeekLow52,
WeekHigh52,
marketCap,
ebitda,
PriceToSales,
priceToBook
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean_step1`
)
SELECT
symbol,
name,
sector_std AS sector,
price,
priceToEarnings,
dividendYield,
EarningPerShare,
WeekLow52,
WeekHigh52,
marketCap,
ebitda,
PriceToSales,
priceToBook
FROM mapped
WHERE PriceToSales >= 0
AND PriceToSales <= 12.78
AND priceToEarnings >= 0
AND priceToEarnings <= 69.185; 

--------------------------------------------------------------------------------------------------------------------------

--Shaping Data - Normalisation

CREATE OR REPLACE VIEW `database-sp500dataanalysis.sp500dataanalysis.sp500data_norm` AS
SELECT
symbol, 
name, 
sector,
price, 
priceToEarnings, 
dividendYield, 
EarningPerShare,
WeekLow52, 
WeekHigh52, 
marketCap, 
ebitda, 
PriceToSales, 
priceToBook,
ROUND(
100 * (MAX(priceToEarnings) OVER() - priceToEarnings)
/ NULLIF(MAX(priceToEarnings) OVER() - MIN(priceToEarnings) OVER(), 0), 2
) AS pe_norm,
ROUND(
100 * (ebitda - MIN(ebitda) OVER())
/ NULLIF(MAX(ebitda) OVER() - MIN(ebitda) OVER(), 0), 2
) AS ebitda_norm,
ROUND(
100 * (dividendYield - MIN(dividendYield) OVER())
/ NULLIF(MAX(dividendYield) OVER() - MIN(dividendYield) OVER(), 0), 2
) AS divy_norm,
ROUND(
100 * (MAX(PriceToSales) OVER() - PriceToSales)
/ NULLIF(MAX(PriceToSales) OVER() - MIN(PriceToSales) OVER(), 0), 2
) AS ps_norm,
ROUND(
100 * (MAX(priceToBook) OVER() - priceToBook)
/ NULLIF(MAX(priceToBook) OVER() - MIN(priceToBook) OVER(), 0), 2
) AS pb_norm, 
 FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_clean_step2`

--------------------------------------------------------------------------------------------------------------------------

-- Shaping Data - Quality Score + ranks

CREATE OR REPLACE VIEW `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore` AS
SELECT
symbol, 
name, 
sector,
price, 
marketCap,
priceToEarnings,
Pe_norm,
ebitda,
ebitda_norm,
dividendYield, 
divy_norm,
PriceToSales, 
ps_norm,
priceToBook, 
pb_norm,
ROUND( (pe_norm + ebitda_norm + divy_norm + ps_norm + pb_norm) / 5, 2 ) AS quality_score,
ROW_NUMBER() OVER (ORDER BY (pe_norm + ebitda_norm + divy_norm + ps_norm + pb_norm) DESC) AS rank_overall,
DENSE_RANK() OVER (PARTITION BY sector ORDER BY (pe_norm + ebitda_norm + ps_norm + pb_norm + divy_norm) DESC) AS rank_in_sector
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_norm`;

SELECT
symbol,
name,
sector,
quality_score,
rank_overall,
rank_in_sector
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore`
ORDER BY rank_overall ASC 

--------------------------------------------------------------------------------------------------------------------------

-- Shaping Data - Sector Summary

CREATE OR REPLACE TABLE `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore_sector` AS
SELECT
sector,
ROUND(AVG(quality_score), 2) AS avg_quality_score,
COUNT(*) AS n_symbols
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore`
GROUP BY sector
ORDER BY avg_quality_score DESC; 

--------------------------------------------------------------------------------------------------------------------------

-- Analyzing Data - Top & Bottom Performers 

-- 1. Top Performers

SELECT
symbol, 
name, 
sector, 
quality_score,
pe_norm, 
ebitda_norm, 
divy_norm, 
ps_norm, 
pb_norm
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore`
ORDER BY quality_score DESC
LIMIT 10; 

-- 2. Bottom Performers

SELECT
symbol, 
name, 
sector, 
quality_score,
pe_norm, 
ebitda_norm, 
divy_norm, 
ps_norm, 
pb_norm
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore`
ORDER BY quality_score ASC
LIMIT 10; 

--------------------------------------------------------------------------------------------------------------------------

-- Analyzing Data - Sector Leaders and Drivers

-- 1. Sector Leaders

SELECT
sector, 
symbol, 
name, 
quality_score,
rank_in_sector
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore`
WHERE rank_in_sector = 1
ORDER BY quality_score DESC;

-- 2. Sector Aggregates

SELECT
sector,
ROUND(AVG(quality_score), 2) AS avg_quality_score,
MIN(quality_score) AS min_quality_score,
MAX(quality_score) AS max_quality_score,
COUNT(*) AS n_symbols
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore`
GROUP BY sector
ORDER BY avg_quality_score DESC;

-- 3. Drivers of Quality Score

SELECT
CORR(quality_score, pe_norm) AS corr_pe, --(PE Norm is the biggest driver)
CORR(quality_score, ebitda_norm) AS corr_ebitda,
CORR(quality_score, divy_norm) AS corr_divy,
CORR(quality_score, ps_norm) AS corr_ps,
CORR(quality_score, pb_norm) AS corr_pb
FROM `database-sp500dataanalysis.sp500dataanalysis.sp500data_qualityScore`;

--------------------------------------------------------------------------------------------------------------------------
-- *Insights and Recommendations*

-- Insights
-- Leaders sit in Communication Services, Materials, and Energy.

-- Verizon, LyondellBasell, AES, and Ford rank at the top. They score well on low P/E, steady yield, and fair profits.

-- The worst scores are in tech firms like Autodesk, Synopsys, Ansys, PTC, Intuit, and Netflix. High P/E and P/S destroy their scores, even when book value looks strong.

-- Small groups like Agricultural Products (Bunge) and Advertising (IPG) look best on paper. But with only 1–2 firms, this is not a broad truth.

-- Valuation rules the model. P/E, P/S, and yield drive most of the score. EBITDA adds little.

-- Recommendations
-- Overweight Communication Services (Verizon, AT&T). Yields are high, and P/E is low.

-- Be careful with growth tech. They look bad in this model, but if you scale by sector, some may rise.

-- Do not chase small sectors like Advertising or Agricultural. They are too thin to anchor a plan.

-- Re-test with tweaks. Split no-dividend vs. missing data. Cap ratios by sector. This will give fairer scores and less bias against growth

