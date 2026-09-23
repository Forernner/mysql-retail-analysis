USE practice;
SELECT 'DUP_MONTH' AS q;
SELECT LEFT(invoice_date,7) AS 月份, SUM(c - 1) AS 被去掉的重复行数 FROM (
  SELECT invoice_date, COUNT(*) AS c FROM retail_raw
  GROUP BY invoice, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
  HAVING COUNT(*) > 1) t
GROUP BY 月份 ORDER BY 被去掉的重复行数 DESC LIMIT 5;

SELECT 'SKU_BIN' AS q;
SELECT COUNT(DISTINCT stock_code COLLATE utf8mb4_bin) AS 区分大小写,
       COUNT(DISTINCT stock_code) AS 默认ci,
       COUNT(DISTINCT TRIM(stock_code) COLLATE utf8mb4_bin) AS 区分大小写且TRIM
FROM retail_raw;
SELECT 'SKU_BIN_CLEAN' AS q;
SELECT COUNT(DISTINCT stock_code COLLATE utf8mb4_bin) AS 区分大小写, COUNT(DISTINCT stock_code) AS 默认ci
FROM retail_clean;

SELECT 'SKU_47503J' AS q;
SELECT stock_code, COUNT(*) AS c FROM retail_raw WHERE TRIM(stock_code) = '47503J' GROUP BY stock_code;

SELECT 'INV_489464' AS q;
SELECT invoice, stock_code, description, quantity, unit_price FROM retail_raw WHERE invoice = '489464' LIMIT 5;
