USE practice;

-- ---------- 1. 换名：旧污染表留底 bak_，干净表顶上正式名 ----------
RENAME TABLE online_retail_year_2009_2010     TO bak_online_retail_year_2009_2010,
             online_retail_year_2010_2011     TO bak_online_retail_year_2010_2011,
             online_retail_year_2009_2010_new TO online_retail_year_2009_2010,
             online_retail_year_2010_2011_new TO online_retail_year_2010_2011;

-- ---------- 2. 重建 retail_raw（两表 UNION ALL）----------
DROP TABLE IF EXISTS retail_raw;

CREATE TABLE retail_raw (
  invoice      VARCHAR(20)   NULL COMMENT '发票号；C 开头=退货冲销，A 开头=坏账调整',
  stock_code   VARCHAR(20)   NULL COMMENT '商品编码；含 POST/DOT/M/B 等非商品码',
  description  VARCHAR(200)  NULL COMMENT '商品名；20% 带前导空格，4,382 行为空',
  quantity     INT           NULL COMMENT '数量；负数=退货',
  invoice_date DATETIME      NULL COMMENT '开票时间',
  unit_price   DECIMAL(10,4) NULL COMMENT '单价；有 0 与负数',
  customer_id  INT           NULL COMMENT '客户ID；22.77% 为空（散客）',
  country      VARCHAR(60)   NULL COMMENT '国家',
  KEY ix_date (invoice_date),
  KEY ix_cust (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO retail_raw
SELECT invoice, stock_code, description, quantity, invoice_date, unit_price,
       NULLIF(customer_id, 0),
       country
FROM online_retail_year_2009_2010
UNION ALL
SELECT invoice, stock_code, description, quantity, invoice_date, unit_price,
       NULLIF(customer_id, 0),
       country
FROM online_retail_year_2010_2011;

-- ---------- 3. 重建 retail_clean（4 条件清洗 + 完全去重 + TRIM）----------
DROP TABLE IF EXISTS retail_clean;

CREATE TABLE retail_clean (
  invoice      VARCHAR(20)   NOT NULL,
  stock_code   VARCHAR(20)   NOT NULL,
  description  VARCHAR(200)  NULL,
  quantity     INT           NOT NULL,
  invoice_date DATETIME      NOT NULL,
  unit_price   DECIMAL(10,4) NOT NULL,
  customer_id  INT           NOT NULL,
  country      VARCHAR(60)   NOT NULL,
  amount       DECIMAL(16,4) NOT NULL COMMENT '派生列 = quantity * unit_price',
  KEY ix_date (invoice_date),
  KEY ix_cust (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO retail_clean
SELECT DISTINCT
  invoice,
  TRIM(stock_code),
  TRIM(description),
  quantity,
  invoice_date,
  unit_price,
  customer_id,
  TRIM(country),
  quantity * unit_price
FROM retail_raw
WHERE invoice NOT LIKE 'C%'
  AND quantity > 0
  AND customer_id IS NOT NULL
  AND unit_price > 0;

-- ---------- 4. 十项总校验 ----------
SELECT '1  retail_raw 行数'          AS 校验项, CAST((SELECT COUNT(*) FROM retail_raw) AS CHAR) AS 结果
UNION ALL SELECT '2  raw 完全去重后',        CAST((SELECT COUNT(*) FROM (SELECT DISTINCT * FROM retail_raw) x) AS CHAR)
UNION ALL SELECT '3  retail_clean 行数',     CAST((SELECT COUNT(*) FROM retail_clean) AS CHAR)
UNION ALL SELECT '4  clean 总金额',          CAST((SELECT ROUND(SUM(amount),2) FROM retail_clean) AS CHAR)
UNION ALL SELECT '5  clean 唯一发票',        CAST((SELECT COUNT(DISTINCT invoice) FROM retail_clean) AS CHAR)
UNION ALL SELECT '6  clean 唯一商品',        CAST((SELECT COUNT(DISTINCT stock_code) FROM retail_clean) AS CHAR)
UNION ALL SELECT '7  clean 唯一客户',        CAST((SELECT COUNT(DISTINCT customer_id) FROM retail_clean) AS CHAR)
UNION ALL SELECT '8  clean 时间下限',        CAST((SELECT MIN(invoice_date) FROM retail_clean) AS CHAR)
UNION ALL SELECT '9  clean 时间上限',        CAST((SELECT MAX(invoice_date) FROM retail_clean) AS CHAR)
UNION ALL SELECT '10 raw 时间下限→上限',     CAST((SELECT CONCAT(MIN(invoice_date),' ~ ',MAX(invoice_date)) FROM retail_raw) AS CHAR);
