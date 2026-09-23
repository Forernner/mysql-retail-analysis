-- Q8 拆成 4 步，每一步都能单独跑、都能看到结果

-- ── 第 1 步：每个客户的「首单时间」 ───────────────────────────
SELECT customer_id, MIN(invoice_date) AS first_dt
FROM retail_clean
GROUP BY customer_id
ORDER BY customer_id
LIMIT 6;

-- ── 第 2 步：每个客户「首单之后的那一单」＝ 第二单 ───────────────
-- 关键：同一张表用两次，一次当「明细」(c)，一次当「首单表」(f)
SELECT c.customer_id, MIN(c.invoice_date) AS second_dt
FROM retail_clean c
JOIN (
  SELECT customer_id, MIN(invoice_date) AS first_dt
  FROM retail_clean GROUP BY customer_id
) f ON c.customer_id = f.customer_id
WHERE c.invoice_date > f.first_dt
GROUP BY c.customer_id
ORDER BY c.customer_id
LIMIT 6;

-- ── 第 2.5 步：证明 WHERE 那句是必须的 ──────────────────────────
-- 去掉 WHERE，MIN 会把首单自己算回来（second_dt 变成和 first_dt 一样）
SELECT '去掉 WHERE' AS 情形, COUNT(*) AS 行数,
       SUM(second_dt = first_dt) AS 第二单等于首单的行数
FROM (
  SELECT c.customer_id, MIN(c.invoice_date) AS second_dt, MAX(f.first_dt) AS first_dt
  FROM retail_clean c
  JOIN (
    SELECT customer_id, MIN(invoice_date) AS first_dt
    FROM retail_clean GROUP BY customer_id
  ) f ON c.customer_id = f.customer_id
  GROUP BY c.customer_id
) x;

-- ── 第 3 步：分母（总客户数）其实可以很简单 ──────────────────────
SELECT COUNT(DISTINCT customer_id) AS total_customers FROM retail_clean;

-- ── 第 4 步：拼起来 —— 首单和第二单相差 ≤30 天的，就是复购客户 ───
SELECT COUNT(*) AS repeat_30d,
       (SELECT COUNT(DISTINCT customer_id) FROM retail_clean) AS total_customers,
       ROUND(COUNT(*) * 100.0 /
             (SELECT COUNT(DISTINCT customer_id) FROM retail_clean), 2) AS repeat_rate_pct
FROM (
  SELECT customer_id, MIN(invoice_date) AS first_dt
  FROM retail_clean GROUP BY customer_id
) f
JOIN (
  SELECT c.customer_id, MIN(c.invoice_date) AS second_dt
  FROM retail_clean c
  JOIN (SELECT customer_id, MIN(invoice_date) AS first_dt
        FROM retail_clean GROUP BY customer_id) f2
    ON c.customer_id = f2.customer_id
  WHERE c.invoice_date > f2.first_dt
  GROUP BY c.customer_id
) s ON f.customer_id = s.customer_id
WHERE DATEDIFF(s.second_dt, f.first_dt) <= 30;
