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