-- A) 正确做法：按 8 列分组（= 整行相同才算重复）
SELECT 'A 按 8 列分组' AS 分组方式, COUNT(*) AS 重复组数, SUM(c - 1) AS 多出来的行数
FROM (SELECT COUNT(*) AS c FROM retail_raw
      GROUP BY invoice, stock_code, description, quantity, invoice_date,
               unit_price, customer_id, country
      HAVING COUNT(*) > 1) t;

-- B) 如果只按 customer_id 分组，会算出多少"重复"
SELECT 'B 只按 customer_id' AS 分组方式, COUNT(*) AS 重复组数, SUM(c - 1) AS 多出来的行数
FROM (SELECT COUNT(*) AS c FROM retail_raw
      GROUP BY customer_id
      HAVING COUNT(*) > 1) t;

-- C) 只按 invoice 分组
SELECT 'C 只按 invoice' AS 分组方式, COUNT(*) AS 重复组数, SUM(c - 1) AS 多出来的行数
FROM (SELECT COUNT(*) AS c FROM retail_raw
      GROUP BY invoice
      HAVING COUNT(*) > 1) t;

-- D) 真实答案（拿去重后行数自检）
SELECT (SELECT COUNT(*) FROM retail_raw) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM retail_raw) a) AS 真实重复行数;

-- E) 客户 12346 的全部明细行（看它为什么不可能是"重复行"）
SELECT invoice, stock_code, description, quantity, invoice_date, unit_price, country
FROM retail_raw WHERE customer_id = 12346
ORDER BY invoice_date, invoice
LIMIT 8;
