USE practice;

SELECT 'A_Q14_15' AS q;
SELECT '② 剔退货剔非正价(含散客含重复)' AS 口径, COUNT(*) AS 行数, ROUND(SUM(quantity*unit_price),2) AS 金额
FROM retail_raw WHERE invoice NOT LIKE 'C%' AND quantity>0 AND unit_price>0
UNION ALL
SELECT '③ ②再完全去重(含散客)', COUNT(*), ROUND(SUM(amount),2) FROM (
  SELECT DISTINCT invoice, stock_code, TRIM(description) AS description, quantity,
         invoice_date, unit_price, customer_id, TRIM(country) AS country,
         quantity * unit_price AS amount
  FROM retail_raw WHERE invoice NOT LIKE 'C%' AND quantity>0 AND unit_price>0) t
UNION ALL
SELECT '③剔散客前(去重含散客，行数)', COUNT(*), NULL FROM (
  SELECT DISTINCT invoice, stock_code, TRIM(description) AS description, quantity,
         invoice_date, unit_price, customer_id, TRIM(country) AS country
  FROM retail_raw WHERE invoice NOT LIKE 'C%' AND quantity>0 AND unit_price>0) t
UNION ALL
SELECT '④ 清洗后=retail_clean', COUNT(*), ROUND(SUM(amount),2) FROM retail_clean;

SELECT 'B_DESC' AS q;
SELECT COUNT(*) AS 清洗口径总行数,
       SUM(description <> TRIM(description)) AS 与TRIM不同,
       SUM(description LIKE ' %') AS 前导空格,
       SUM(description LIKE '% ') AS 尾随空格,
       ROUND(SUM(description <> TRIM(description)) * 100.0 / COUNT(*), 1) AS 占比pct
FROM retail_raw
WHERE invoice NOT LIKE 'C%' AND quantity>0 AND customer_id IS NOT NULL AND unit_price>0;

SELECT 'C_DEC12' AS q;
SELECT ROUND(SUM(quantity*unit_price),2) AS 去重前, (SELECT ROUND(SUM(amount),2) FROM retail_clean
        WHERE LEFT(invoice_date,7)='2010-12') AS 去重后,
       ROUND(SUM(quantity*unit_price),2) - (SELECT ROUND(SUM(amount),2) FROM retail_clean
        WHERE LEFT(invoice_date,7)='2010-12') AS 虚高额,
       ROUND((ROUND(SUM(quantity*unit_price),2) - (SELECT ROUND(SUM(amount),2) FROM retail_clean
        WHERE LEFT(invoice_date,7)='2010-12')) * 100.0 / (SELECT ROUND(SUM(amount),2) FROM retail_clean
        WHERE LEFT(invoice_date,7)='2010-12'), 2) AS 虚高pct
FROM retail_raw
WHERE invoice NOT LIKE 'C%' AND quantity>0 AND customer_id IS NOT NULL AND unit_price>0
  AND LEFT(invoice_date,7)='2010-12';

SELECT 'D_Q17det' AS q;
SELECT customer_id, invoice, invoice_date, stock_code, ROUND(amount,2) AS amount FROM (
  SELECT customer_id, invoice, invoice_date, stock_code, amount,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY invoice_date, invoice, stock_code) AS rn
  FROM retail_clean) r WHERE rn = 1 ORDER BY customer_id LIMIT 5;

SELECT 'E_SAMP_NEG' AS q;
SELECT invoice, stock_code, description, quantity, unit_price FROM retail_raw
WHERE quantity < 0 ORDER BY quantity ASC LIMIT 3;

SELECT 'F_SAMP_PRICE0' AS q;
SELECT invoice, stock_code, description, quantity, unit_price FROM retail_raw
WHERE unit_price = 0 ORDER BY quantity ASC LIMIT 3;

SELECT 'G_SAMP_LTPRICE' AS q;
SELECT invoice, stock_code, description, quantity, unit_price FROM retail_raw
WHERE unit_price < 0 ORDER BY unit_price ASC LIMIT 3;

SELECT 'H_COHORT' AS q;
WITH f AS (SELECT customer_id, LEFT(MIN(invoice_date),7) AS cm FROM retail_clean GROUP BY customer_id),
     act AS (SELECT DISTINCT customer_id, LEFT(invoice_date,7) AS am FROM retail_clean),
     j AS (SELECT f.customer_id, f.cm,
             (CAST(LEFT(am,4) AS SIGNED) - CAST(LEFT(cm,4) AS SIGNED)) * 12
             + (CAST(SUBSTRING(am,6,2) AS SIGNED) - CAST(SUBSTRING(cm,6,2) AS SIGNED)) AS mi
           FROM f JOIN act ON f.customer_id = act.customer_id)
SELECT cm, COUNT(DISTINCT CASE WHEN mi=0 THEN customer_id END) m0,
       COUNT(DISTINCT CASE WHEN mi=1 THEN customer_id END) m1,
       COUNT(DISTINCT CASE WHEN mi=2 THEN customer_id END) m2,
       COUNT(DISTINCT CASE WHEN mi=3 THEN customer_id END) m3,
       COUNT(DISTINCT CASE WHEN mi=4 THEN customer_id END) m4,
       COUNT(DISTINCT CASE WHEN mi=5 THEN customer_id END) m5,
       COUNT(DISTINCT CASE WHEN mi=6 THEN customer_id END) m6
FROM j GROUP BY cm ORDER BY cm LIMIT 6;
