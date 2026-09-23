USE practice;

SELECT 'Q17' AS q;
SELECT customer_id, invoice, invoice_date, ROUND(amount,2) AS amount FROM (
  SELECT customer_id, invoice, invoice_date, amount,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY invoice_date, invoice) rn
  FROM retail_clean) r WHERE rn = 1 ORDER BY customer_id LIMIT 5;

SELECT 'Q18' AS q;
SELECT customer_id, ROUND(SUM(amount),2) AS revenue, COUNT(DISTINCT invoice) AS orders
FROM retail_clean GROUP BY customer_id ORDER BY revenue DESC LIMIT 20;

SELECT 'Q19' AS q;
SELECT LEFT(invoice_date,7) AS ym, ROUND(SUM(amount),2) AS revenue,
       ROUND(SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY LEFT(invoice_date,7)),2) AS diff_amt,
       ROUND((SUM(amount) - LAG(SUM(amount)) OVER (ORDER BY LEFT(invoice_date,7)))
             * 100.0 / LAG(SUM(amount)) OVER (ORDER BY LEFT(invoice_date,7)), 2) AS mom_pct
FROM retail_clean GROUP BY ym ORDER BY ym;

SELECT 'Q21' AS q;
SELECT LEFT(invoice_date,7) AS ym, ROUND(SUM(amount),2) AS revenue,
       COUNT(DISTINCT invoice) AS orders, COUNT(DISTINCT customer_id) AS customers,
       ROUND(SUM(amount)/COUNT(DISTINCT invoice),2) AS aov
FROM retail_clean GROUP BY ym ORDER BY ym;

SELECT 'Q22' AS q;
SELECT country, ROUND(SUM(amount),2) AS revenue, COUNT(DISTINCT customer_id) AS customers
FROM retail_clean GROUP BY country ORDER BY revenue DESC LIMIT 10;

SELECT 'Q23A' AS q;
SELECT stock_code, MAX(description) AS description, ROUND(SUM(amount),2) AS revenue, SUM(quantity) AS qty
FROM retail_clean GROUP BY stock_code ORDER BY revenue DESC LIMIT 10;

SELECT 'Q23Q' AS q;
SELECT stock_code, MAX(description) AS description, SUM(quantity) AS qty, ROUND(SUM(amount),2) AS revenue
FROM retail_clean GROUP BY stock_code ORDER BY qty DESC LIMIT 10;

SELECT 'Q25' AS q;
SELECT customer_id, DATEDIFF('2011-12-09', MAX(invoice_date)) AS recency_days,
       COUNT(DISTINCT invoice) AS frequency, ROUND(SUM(amount),2) AS monetary
FROM retail_clean GROUP BY customer_id ORDER BY monetary DESC LIMIT 10;

SELECT 'Q7' AS q;
SELECT COUNT(DISTINCT customer_id) AS same_day_multi FROM retail_clean
WHERE (customer_id, DATE(invoice_date)) IN (
  SELECT customer_id, DATE(invoice_date) FROM retail_clean
  GROUP BY customer_id, DATE(invoice_date) HAVING COUNT(DISTINCT invoice) >= 2);

SELECT 'Q8' AS q;
SELECT COUNT(*) AS repeat_within_30d FROM (
  SELECT c.customer_id, MIN(c.invoice_date) AS fd FROM retail_clean c GROUP BY c.customer_id) f
JOIN (SELECT c.customer_id, MIN(c.invoice_date) AS sd FROM retail_clean c
      JOIN (SELECT customer_id, MIN(invoice_date) AS fd FROM retail_clean GROUP BY customer_id) g
        ON g.customer_id = c.customer_id
      WHERE c.invoice_date > g.fd GROUP BY c.customer_id) s
  ON s.customer_id = f.customer_id
WHERE DATEDIFF(s.sd, f.fd) <= 30;
SELECT 'Q8b' AS q;
SELECT COUNT(*) AS repeat_customers_2plus FROM (
  SELECT customer_id FROM retail_clean GROUP BY customer_id HAVING COUNT(DISTINCT invoice) >= 2) y;

SELECT 'Q24' AS q;
SELECT (SELECT COUNT(*) FROM (SELECT stock_code FROM retail_clean GROUP BY stock_code) p) AS sku_total,
       (SELECT MIN(rn) FROM (SELECT ROW_NUMBER() OVER (ORDER BY rev DESC, stock_code) rn,
               SUM(rev) OVER (ORDER BY rev DESC, stock_code ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cum,
               SUM(rev) OVER () total
        FROM (SELECT stock_code, SUM(amount) rev FROM retail_clean GROUP BY stock_code) a) r
        WHERE cum >= 0.8*total) AS sku80,
       (SELECT MIN(rn) FROM (SELECT ROW_NUMBER() OVER (ORDER BY rev DESC, stock_code) rn,
               SUM(rev) OVER (ORDER BY rev DESC, stock_code ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cum,
               SUM(rev) OVER () total
        FROM (SELECT stock_code, SUM(amount) rev FROM retail_clean GROUP BY stock_code) a) r
        WHERE cum >= 0.5*total) AS sku50;

SELECT 'YEAR' AS q;
SELECT LEFT(invoice_date,4) AS y, ROUND(SUM(amount),2) AS revenue,
       COUNT(DISTINCT invoice) AS orders, COUNT(DISTINCT customer_id) AS customers
FROM retail_clean GROUP BY y ORDER BY y;
