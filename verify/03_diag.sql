SELECT '=== 1 retail_raw 前 5 行 ===' AS s;
SELECT invoice, stock_code, LEFT(description,16) AS desc16, quantity, invoice_date, unit_price, customer_id, country
FROM retail_raw LIMIT 5;
SELECT '=== 2 retail_raw 日期分布（前 10 天） ===' AS s;
SELECT DATE(invoice_date) AS d, COUNT(*) AS c FROM retail_raw GROUP BY d ORDER BY d LIMIT 10;
SELECT '=== 3 源表 2009_2010 前 5 行 ===' AS s;
SELECT invoice, stock_code, LEFT(description,16) AS desc16, quantity, invoice_date, unit_price, customer_id, country
FROM online_retail_year_2009_2010 LIMIT 5;
SELECT '=== 4 源表 2009_2010 日期范围 ===' AS s;
SELECT MIN(invoice_date) dmin, MAX(invoice_date) dmax FROM online_retail_year_2009_2010;
SELECT '=== 5 源表 2010_2011 日期范围 ===' AS s;
SELECT MIN(invoice_date) dmin, MAX(invoice_date) dmax FROM online_retail_year_2010_2011;
SELECT '=== 6 源表建表语句 ===' AS s;
SHOW CREATE TABLE online_retail_year_2009_2010;
SELECT '=== 7 retail_raw 建表语句 ===' AS s;
SHOW CREATE TABLE retail_raw;
SELECT '=== 8 源表 invoice_date 是否有默认值生效（同一天内不同时间说明是插入时间） ===' AS s;
SELECT COUNT(*) total, COUNT(DISTINCT invoice_date) uniq_dt, MIN(invoice_date) a, MAX(invoice_date) b
FROM online_retail_year_2009_2010;
