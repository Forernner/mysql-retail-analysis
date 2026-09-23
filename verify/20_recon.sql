-- ================================================================
-- Power BI 对账用基准值（在你的 MySQL 上实测）
-- 用途：让王自强在 Power BI 里做完度量值后，能自己判断「做对了没有」
-- ================================================================
USE practice;

SELECT '① GMV 总金额' AS 项目, CAST(ROUND(SUM(amount),2) AS CHAR) AS 基准值 FROM retail_clean
UNION ALL SELECT '② 订单数(去重发票)', CAST(COUNT(DISTINCT invoice) AS CHAR) FROM retail_clean
UNION ALL SELECT '③ 客户数(去重客户)', CAST(COUNT(DISTINCT customer_id) AS CHAR) FROM retail_clean
UNION ALL SELECT '④ 商品数(默认排序规则)', CAST(COUNT(DISTINCT stock_code) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑤ 客单价', CAST(ROUND(SUM(amount)/COUNT(DISTINCT invoice),2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑥ 平均件数', CAST(ROUND(SUM(quantity)/COUNT(DISTINCT invoice),2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑦ 整体复购客户数', CAST((SELECT COUNT(*) FROM (SELECT customer_id FROM retail_clean GROUP BY customer_id HAVING COUNT(DISTINCT invoice)>=2) t) AS CHAR)
UNION ALL SELECT '⑧ 整体复购率', CAST(ROUND((SELECT COUNT(*) FROM (SELECT customer_id FROM retail_clean GROUP BY customer_id HAVING COUNT(DISTINCT invoice)>=2) t) / COUNT(DISTINCT customer_id) * 100, 2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑨ 2009年GMV', CAST(ROUND(SUM(CASE WHEN YEAR(invoice_date)=2009 THEN amount END),2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑩ 2010年GMV', CAST(ROUND(SUM(CASE WHEN YEAR(invoice_date)=2010 THEN amount END),2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑪ 2011年GMV', CAST(ROUND(SUM(CASE WHEN YEAR(invoice_date)=2011 THEN amount END),2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑫ 英国(United Kingdom)GMV', CAST(ROUND(SUM(CASE WHEN country='United Kingdom' THEN amount END),2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑬ 英国占比%', CAST(ROUND(SUM(CASE WHEN country='United Kingdom' THEN amount END)/SUM(amount)*100,2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑭ 2010-12-01~09 GMV', CAST(ROUND(SUM(CASE WHEN invoice_date>='2010-12-01' AND invoice_date<'2010-12-10' THEN amount END),2) AS CHAR) FROM retail_clean
UNION ALL SELECT '⑮ 2011-12-01~09 GMV', CAST(ROUND(SUM(CASE WHEN invoice_date>='2011-12-01' AND invoice_date<'2011-12-10' THEN amount END),2) AS CHAR) FROM retail_clean;

-- 月度流水全表（验证折线图）
SELECT DATE_FORMAT(invoice_date,'%Y-%m') AS 年月,
       ROUND(SUM(amount),2) AS GMV,
       COUNT(DISTINCT invoice) AS 订单数
FROM retail_clean
GROUP BY 1 ORDER BY 1;

-- 国家 Top5
SELECT country AS 国家, ROUND(SUM(amount),2) AS GMV
FROM retail_clean GROUP BY 1 ORDER BY GMV DESC LIMIT 5;

-- 商品 Top5
SELECT stock_code AS 商品编码, ROUND(SUM(amount),2) AS GMV
FROM retail_clean GROUP BY 1 ORDER BY GMV DESC LIMIT 5;
