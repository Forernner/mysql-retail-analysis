SELECT '=== A 精确行数 ===' AS s;
SELECT COUNT(*) AS raw_rows FROM retail_raw;
SELECT '=== B 完全去重后（修正了别名） ===' AS s;
SELECT COUNT(*) AS raw_distinct_rows FROM (SELECT DISTINCT * FROM retail_raw) x;
SELECT '=== C 时间范围 ===' AS s;
SELECT MIN(invoice_date) AS dmin, MAX(invoice_date) AS dmax FROM retail_raw;
SELECT '=== D 字段长度/极值体检 ===' AS s;
SELECT MAX(CHAR_LENGTH(invoice)) AS inv_len, MAX(CHAR_LENGTH(stock_code)) AS sku_len,
       MAX(CHAR_LENGTH(description)) AS desc_len, MAX(CHAR_LENGTH(country)) AS ctry_len,
       MAX(unit_price) AS max_price, MIN(unit_price) AS min_price, MAX(quantity) AS max_qty
FROM retail_raw;
SELECT '=== E customer_id 空值分布 ===' AS s;
SELECT SUM(customer_id IS NULL) AS null_cust, SUM(quantity<0) AS neg_qty, SUM(quantity=0) AS zero_qty,
       SUM(unit_price<=0) AS bad_price, SUM(invoice LIKE 'C%') AS cancel_rows
FROM retail_raw;
SELECT '=== F 尾随空格 ===' AS s;
SELECT SUM(stock_code <> TRIM(stock_code)) AS sku_space,
       SUM(description <> TRIM(description)) AS desc_space,
       SUM(country <> TRIM(country)) AS ctry_space,
       SUM(invoice <> TRIM(invoice)) AS inv_space
FROM retail_raw;
