-- ============================================================
-- 修复：两张源表的 invoice_date 被 TIME 化污染（日期=2026-09-20）
-- 做法：旧表改名留底 → 新建结构一致的干净表 → 服务端 LOAD DATA 重灌
-- ============================================================
USE practice;

DROP TABLE IF EXISTS bak_online_retail_year_2009_2010;
DROP TABLE IF EXISTS bak_online_retail_year_2010_2011;
DROP TABLE IF EXISTS online_retail_year_2009_2010_new;
DROP TABLE IF EXISTS online_retail_year_2010_2011_new;

CREATE TABLE online_retail_year_2009_2010_new (
  invoice      VARCHAR(20)   DEFAULT NULL,
  stock_code   VARCHAR(20)   DEFAULT NULL,
  description  VARCHAR(200)  DEFAULT NULL,
  quantity     INT           DEFAULT NULL,
  invoice_date DATETIME      DEFAULT NULL,
  unit_price   DECIMAL(10,4) DEFAULT NULL,
  customer_id  INT           DEFAULT NULL,
  country      VARCHAR(60)   DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE online_retail_year_2010_2011_new (
  invoice      VARCHAR(20)   DEFAULT NULL,
  stock_code   VARCHAR(20)   DEFAULT NULL,
  description  VARCHAR(200)  DEFAULT NULL,
  quantity     INT           DEFAULT NULL,
  invoice_date DATETIME      DEFAULT NULL,
  unit_price   DECIMAL(10,4) DEFAULT NULL,
  customer_id  INT           DEFAULT NULL,
  country      VARCHAR(60)   DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/t_2009_2010.tsv'
INTO TABLE online_retail_year_2009_2010_new
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
(invoice, stock_code, description, quantity, invoice_date, unit_price, customer_id, country);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/t_2010_2011.tsv'
INTO TABLE online_retail_year_2010_2011_new
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t' ESCAPED BY '\\'
LINES TERMINATED BY '\n'
(invoice, stock_code, description, quantity, invoice_date, unit_price, customer_id, country);

SELECT '=== 导入后校验 ===' AS s;
SELECT (SELECT COUNT(*) FROM online_retail_year_2009_2010_new) AS s1_2009_2010,
       (SELECT COUNT(*) FROM online_retail_year_2010_2011_new) AS s2_2010_2011,
       (SELECT COUNT(*) FROM online_retail_year_2009_2010_new) + (SELECT COUNT(*) FROM online_retail_year_2010_2011_new) AS total;
SELECT '=== 日期范围（应为 2009-12-01 / 2011-12-09） ===' AS s;
SELECT MIN(invoice_date) dmin, MAX(invoice_date) dmax FROM online_retail_year_2009_2010_new;
SELECT MIN(invoice_date) dmin, MAX(invoice_date) dmax FROM online_retail_year_2010_2011_new;
SELECT '=== 空值形态（应与旧表一致） ===' AS s;
SELECT SUM(description IS NULL) desc_null, SUM(customer_id IS NULL) cust_null,
       SUM(unit_price IS NULL) price_null, SUM(quantity IS NULL) qty_null,
       SUM(invoice_date IS NULL) dt_null
FROM online_retail_year_2009_2010_new
UNION ALL
SELECT SUM(description IS NULL), SUM(customer_id IS NULL), SUM(unit_price IS NULL),
       SUM(quantity IS NULL), SUM(invoice_date IS NULL)
FROM online_retail_year_2010_2011_new;
SELECT '=== 反斜杠与尾随空格是否保留 ===' AS s;
SELECT SUM(description LIKE '%\\%') desc_bs, SUM(description <> TRIM(description)) desc_space,
       SUM(stock_code <> TRIM(stock_code)) sku_space
FROM online_retail_year_2009_2010_new;
SELECT '=== 样本 ===' AS s;
SELECT invoice, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
FROM online_retail_year_2009_2010_new LIMIT 3;
