USE practice;

-- A. 每个月是否完整：看每个月的最早/最晚日期
SELECT DATE_FORMAT(invoice_date,'%Y-%m') AS 年月,
       MIN(DATE(invoice_date)) AS 最早日,
       MAX(DATE(invoice_date)) AS 最晚日,
       COUNT(DISTINCT DATE(invoice_date)) AS 有数据天数,
       ROUND(SUM(amount),2) AS GMV,
       COUNT(DISTINCT invoice) AS 订单数
FROM retail_clean
WHERE invoice_date >= '2010-11-01'
GROUP BY 1 ORDER BY 1;

-- B. 两个 12 月的逐日明细（验证同口径对比）
SELECT DATE(invoice_date) AS 日期, ROUND(SUM(amount),2) AS GMV, COUNT(DISTINCT invoice) AS 订单数
FROM retail_clean
WHERE invoice_date >= '2010-12-01' AND invoice_date < '2010-12-10'
GROUP BY 1 ORDER BY 1;

SELECT DATE(invoice_date) AS 日期, ROUND(SUM(amount),2) AS GMV, COUNT(DISTINCT invoice) AS 订单数
FROM retail_clean
WHERE invoice_date >= '2011-12-01' AND invoice_date < '2011-12-10'
GROUP BY 1 ORDER BY 1;

-- C. 同口径增长率（12 月 1-9 日）
SELECT ROUND(SUM(CASE WHEN invoice_date>='2010-12-01' AND invoice_date<'2010-12-10' THEN amount END),2) AS 十二月上旬_2010,
       ROUND(SUM(CASE WHEN invoice_date>='2011-12-01' AND invoice_date<'2011-12-10' THEN amount END),2) AS 十二月上旬_2011,
       ROUND((SUM(CASE WHEN invoice_date>='2011-12-01' AND invoice_date<'2011-12-10' THEN amount END)
             /SUM(CASE WHEN invoice_date>='2010-12-01' AND invoice_date<'2010-12-10' THEN amount END)-1)*100,2) AS 同口径同比增长率
FROM retail_clean;
