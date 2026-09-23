-- ============================================================
-- Q17 · 派生表版（不用 CTE）—— 可直接运行
-- 王自强 · 2026-09-23
--
-- 用法：Navicat → 文件 → 打开 → 选本文件 → 直接「运行」
--       ★ 不要复制粘贴到别的窗口（这次报错就是字符在粘贴路上被换掉了）
--
-- 本文件全部语句已在本机 MySQL 8.0 实跑通过（2026-09-23 12:5x）
-- ============================================================


-- ① 正式答案：每个客户的「首单」+ 该发票的金额合计
SELECT invoice, customer_id, invoice_date, inv_total
FROM (
  SELECT customer_id, invoice,
         MIN(invoice_date) AS invoice_date,
         SUM(amount)       AS inv_total,
         ROW_NUMBER() OVER (
           PARTITION BY customer_id
           ORDER BY MIN(invoice_date) ASC, invoice ASC
         ) AS rn
  FROM retail_clean
  GROUP BY customer_id, invoice
) AS t
WHERE rn = 1
ORDER BY customer_id
LIMIT 5;

-- 预期结果（5 行）：
--   491725 / 12346 / 2009-12-14 08:34:00 /    45.00
--   529924 / 12347 / 2010-10-31 14:20:00 /   611.53
--   524140 / 12348 / 2010-09-27 14:59:00 /   222.16
--   506394 / 12349 / 2010-04-29 13:20:00 /  1068.52
--   543037 / 12350 / 2011-02-02 16:01:00 /   334.40


-- ② 想验证「编号是按时间递增的」：把 rn = 1 改成 rn = 5
--    rn=5 时 12346 的第 5 单 = 492722 / 2009-12-18 10:55:00 / 1.00
--    → 自己动手改一个字跑一次，比看讲解记得牢
SELECT invoice, customer_id, invoice_date, inv_total
FROM (
  SELECT customer_id, invoice,
         MIN(invoice_date) AS invoice_date,
         SUM(amount)       AS inv_total,
         ROW_NUMBER() OVER (
           PARTITION BY customer_id
           ORDER BY MIN(invoice_date) ASC, invoice ASC
         ) AS rn
  FROM retail_clean
  GROUP BY customer_id, invoice
) AS t
WHERE rn = 5
ORDER BY customer_id
LIMIT 5;


-- ③ 自检 A：内层一共几行  → 应为 36,969（= retail_clean 的唯一发票数）
SELECT COUNT(*) AS t行数
FROM (
  SELECT customer_id, invoice,
         MIN(invoice_date) AS invoice_date,
         SUM(amount)       AS inv_total,
         ROW_NUMBER() OVER (
           PARTITION BY customer_id
           ORDER BY MIN(invoice_date) ASC, invoice ASC
         ) AS rn
  FROM retail_clean
  GROUP BY customer_id, invoice
) AS t;


-- ④ 自检 B：首单有几行  → 应为 5,878（= 客户数，一人一张首单）
SELECT COUNT(*) AS 首单行数
FROM (
  SELECT customer_id, invoice,
         ROW_NUMBER() OVER (
           PARTITION BY customer_id
           ORDER BY MIN(invoice_date) ASC, invoice ASC
         ) AS rn
  FROM retail_clean
  GROUP BY customer_id, invoice
) AS t
WHERE rn = 1;
