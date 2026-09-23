-- 第 4 步拼完之后长什么样（真实数据，取前 8 行）
SELECT f.customer_id,
       f.first_dt,
       s.second_dt,
       DATEDIFF(s.second_dt, f.first_dt) AS 相隔天数,
       IF(DATEDIFF(s.second_dt, f.first_dt) <= 30, '算复购', '不算') AS 判定
FROM (
  SELECT customer_id, MIN(invoice_date) AS first_dt
  FROM retail_clean GROUP BY customer_id) f
JOIN (
  SELECT c.customer_id, MIN(c.invoice_date) AS second_dt
  FROM retail_clean c
  JOIN (SELECT customer_id, MIN(invoice_date) AS first_dt
        FROM retail_clean GROUP BY customer_id) f2
    ON c.customer_id = f2.customer_id
  WHERE c.invoice_date > f2.first_dt
  GROUP BY c.customer_id) s
  ON f.customer_id = s.customer_id
ORDER BY f.customer_id
LIMIT 8;

-- 只有一单、被 INNER JOIN 自动剔掉的客户有多少
SELECT 5878 - 4256 AS 只有一单的客户数_被JOIN自动剔除;
