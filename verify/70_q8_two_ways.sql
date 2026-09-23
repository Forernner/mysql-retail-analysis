-- A) CTE 写法（试卷 Q8 原答案）
WITH first_order AS (
  SELECT customer_id, MIN(invoice_date) AS first_dt
  FROM retail_clean
  GROUP BY customer_id
),
second_order AS (
  SELECT c.customer_id, MIN(c.invoice_date) AS second_dt
  FROM retail_clean c
  JOIN first_order f ON c.customer_id = f.customer_id
  WHERE c.invoice_date > f.first_dt
  GROUP BY c.customer_id
)
SELECT COUNT(*) AS repeat_30d,
       (SELECT COUNT(*) FROM first_order) AS total_customers,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM first_order), 2) AS repeat_rate_pct
FROM first_order f
JOIN second_order s ON f.customer_id = s.customer_id
WHERE DATEDIFF(s.second_dt, f.first_dt) <= 30;

-- B) 派生表写法（完全不用 CTE，Day 2 就能做；first_order 那段被迫抄两遍）
SELECT COUNT(*) AS repeat_30d,
       (SELECT COUNT(*) FROM (
            SELECT customer_id, MIN(invoice_date) AS first_dt
            FROM retail_clean GROUP BY customer_id) f0) AS total_customers,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM (
            SELECT customer_id, MIN(invoice_date) AS first_dt
            FROM retail_clean GROUP BY customer_id) f1), 2) AS repeat_rate_pct
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
WHERE DATEDIFF(s.second_dt, f.first_dt) <= 30;
