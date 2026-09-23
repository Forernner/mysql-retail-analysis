-- 把你截图那段拆成 3 步跑，看每一步到底吐出什么
-- ---------- 第 1 步：内层 —— 找出"出现超过 1 次"的行组 ----------
SELECT invoice, stock_code, quantity, invoice_date, unit_price, customer_id, country, COUNT(*) AS c
FROM retail_raw
GROUP BY invoice, stock_code, description, quantity, invoice_date,
         unit_price, customer_id, country
HAVING COUNT(*) > 1
ORDER BY c DESC, invoice
LIMIT 8;

-- ---------- 第 2 步：内层一共多少组、SUM(c-1) 是不是 34,335 ----------
SELECT COUNT(*) AS 重复组数, SUM(c - 1) AS 多出来的行数
FROM (
  SELECT COUNT(*) AS c
  FROM retail_raw
  GROUP BY invoice, stock_code, description, quantity, invoice_date,
           unit_price, customer_id, country
  HAVING COUNT(*) > 1
) t;

-- ---------- 第 3 步：外层 —— 按月份归类（你截图那段） ----------
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS 月份, SUM(c - 1) AS 被去掉的重复行数
FROM (
  SELECT invoice_date, COUNT(*) AS c
  FROM retail_raw
  GROUP BY invoice, stock_code, description, quantity, invoice_date,
           unit_price, customer_id, country
  HAVING COUNT(*) > 1
) t
GROUP BY 月份 ORDER BY 被去掉的重复行数 DESC
LIMIT 8;

-- ---------- 第 4 步：验证 DATE_FORMAT 到底吐出什么 ----------
SELECT invoice_date,
       DATE_FORMAT(invoice_date, '%Y-%m')  AS 年月文本,
       DATE(invoice_date)                  AS 只留日期,
       YEAR(invoice_date)                  AS 年,
       MONTH(invoice_date)                 AS 月,
       DATEDIFF('2011-12-09', invoice_date) AS 距截止天数
FROM retail_raw
ORDER BY invoice_date
LIMIT 3;
