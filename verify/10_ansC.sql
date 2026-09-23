USE practice;

SELECT 'Q7' AS q;
SELECT COUNT(*) AS same_day_multi FROM (
  SELECT customer_id, DATE(invoice_date) AS d
  FROM retail_clean GROUP BY customer_id, d HAVING COUNT(DISTINCT invoice) >= 2) y;

SELECT 'Q8' AS q;
WITH f AS (SELECT customer_id, MIN(invoice_date) AS fd FROM retail_clean GROUP BY customer_id),
     s AS (SELECT c.customer_id, MIN(c.invoice_date) AS sd
           FROM retail_clean c JOIN f ON c.customer_id = f.customer_id
           WHERE c.invoice_date > f.fd GROUP BY c.customer_id)
SELECT COUNT(*) AS repeat_within_30d FROM f JOIN s ON f.customer_id = s.customer_id
WHERE DATEDIFF(s.sd, f.fd) <= 30;
SELECT 'Q8b' AS q;
SELECT COUNT(*) AS repeat_customers_2plus FROM (
  SELECT customer_id FROM retail_clean GROUP BY customer_id HAVING COUNT(DISTINCT invoice) >= 2) y;

SELECT 'Q17tot' AS q;
SELECT customer_id, invoice, invoice_date, ROUND(inv_total,2) AS inv_total FROM (
  SELECT customer_id, invoice, MIN(invoice_date) AS invoice_date, SUM(amount) AS inv_total,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY MIN(invoice_date), invoice) rn
  FROM retail_clean GROUP BY customer_id, invoice) r WHERE rn = 1 ORDER BY customer_id LIMIT 5;

SELECT 'Q24sku' AS q;
SELECT COUNT(*) AS sku_total,
       SUM(cum < 0.8*total) + 1 AS sku80,
       ROUND((SUM(cum < 0.8*total) + 1) * 100.0 / COUNT(*), 2) AS pct80,
       SUM(cum < 0.5*total) + 1 AS sku50,
       ROUND((SUM(cum < 0.5*total) + 1) * 100.0 / COUNT(*), 2) AS pct50
FROM (
  SELECT rev, SUM(rev) OVER (ORDER BY rev DESC, stock_code ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cum,
         SUM(rev) OVER () total
  FROM (SELECT stock_code, SUM(amount) AS rev FROM retail_clean GROUP BY stock_code) a
) r;

SELECT 'Q24cust' AS q;
SELECT COUNT(*) AS n_cust,
       ROUND((SUM(cum < 0.5*total) + 1) * 100.0 / COUNT(*), 1) AS pct50,
       ROUND((SUM(cum < 0.8*total) + 1) * 100.0 / COUNT(*), 1) AS pct80
FROM (
  SELECT rev, SUM(rev) OVER (ORDER BY rev DESC, customer_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cum,
         SUM(rev) OVER () total
  FROM (SELECT customer_id, SUM(amount) AS rev FROM retail_clean GROUP BY customer_id) a
) r;

SELECT 'YEAR' AS q;
SELECT LEFT(invoice_date,4) AS y, ROUND(SUM(amount),2) AS revenue,
       COUNT(DISTINCT invoice) AS orders, COUNT(DISTINCT customer_id) AS customers
FROM retail_clean GROUP BY y ORDER BY y;

SELECT 'YOY' AS q;
SELECT SUBSTRING(invoice_date,6,2) AS m,
       ROUND(SUM(CASE WHEN LEFT(invoice_date,4)='2010' THEN amount END),2) AS y2010,
       ROUND(SUM(CASE WHEN LEFT(invoice_date,4)='2011' THEN amount END),2) AS y2011
FROM retail_clean GROUP BY m ORDER BY m;

SELECT 'OVERLAP' AS q;
SELECT DATEDIFF((SELECT MAX(invoice_date) FROM online_retail_year_2009_2010),
                (SELECT MIN(invoice_date) FROM online_retail_year_2010_2011)) + 1 AS 重叠天数;
