-- Q6 追问：哪些行"看着像商品、其实不是商品"？
-- 1) 非标准商品编码清单（真实数据）
SELECT stock_code, COUNT(*) AS 行数, ROUND(SUM(quantity*unit_price),2) AS 金额
FROM retail_raw
WHERE stock_code NOT REGEXP '^[0-9]{5}[A-Za-z]?$'
GROUP BY stock_code
ORDER BY 行数 DESC
LIMIT 25;

-- 2) 这些非商品码一共多少行、多少流水
SELECT COUNT(*) AS 非商品码行数, ROUND(SUM(quantity*unit_price),2) AS 金额
FROM retail_raw
WHERE stock_code NOT REGEXP '^[0-9]{5}[A-Za-z]?$';

-- 3) ★ 关键：其中有多少"活"过了清洗、进了 retail_clean（会污染商品榜）
SELECT COUNT(*) AS 进clean的行数, COUNT(DISTINCT stock_code) AS 编码数,
       ROUND(SUM(amount),2) AS 金额
FROM retail_clean
WHERE stock_code NOT REGEXP '^[0-9]{5}[A-Za-z]?$';

-- 4) 这些进 clean 的是哪些
SELECT stock_code, COUNT(*) AS 行数, ROUND(SUM(amount),2) AS 金额
FROM retail_clean
WHERE stock_code NOT REGEXP '^[0-9]{5}[A-Za-z]?$'
GROUP BY stock_code
ORDER BY 金额 DESC
LIMIT 12;

-- 5) Q23 的"金额榜 Top 10 / 数量榜 Top 10"里有没有非商品码
SELECT '金额榜' AS 榜, stock_code, description, ROUND(SUM(amount),2) AS v
FROM retail_clean GROUP BY stock_code, description ORDER BY v DESC LIMIT 10;
SELECT '数量榜' AS 榜, stock_code, description, SUM(quantity) AS q
FROM retail_clean GROUP BY stock_code, description ORDER BY q DESC LIMIT 10;
