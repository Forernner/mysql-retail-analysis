-- 用「明确清单」而不是正则，避免把 15056BL / 79323LP 这类真商品码误判
SET @cond := "stock_code IN ('POST','DOT','M','C2','D','S','B','BANK CHARGES',
   'ADJUST','ADJUST2','AMAZONFEE','CRUK','PADS','TEST001','TEST002','SP1002')
   OR stock_code LIKE 'DCGS%' OR stock_code LIKE 'gift\_%'";

-- 1) 裸清单：这些编码各自多少行、多少钱（raw）
SELECT stock_code, COUNT(*) AS 行数, ROUND(SUM(quantity*unit_price),2) AS 金额
FROM retail_raw
WHERE stock_code IN ('POST','DOT','M','C2','D','S','B','BANK CHARGES',
   'ADJUST','ADJUST2','AMAZONFEE','CRUK','PADS','TEST001','TEST002','SP1002')
   OR stock_code LIKE 'DCGS%' OR stock_code LIKE 'gift\_%'
GROUP BY stock_code ORDER BY 行数 DESC;

-- 2) 合计：raw 侧
SELECT COUNT(*) AS raw非商品行数, ROUND(SUM(quantity*unit_price),2) AS raw金额
FROM retail_raw
WHERE stock_code IN ('POST','DOT','M','C2','D','S','B','BANK CHARGES',
   'ADJUST','ADJUST2','AMAZONFEE','CRUK','PADS','TEST001','TEST002','SP1002')
   OR stock_code LIKE 'DCGS%' OR stock_code LIKE 'gift\_%';

-- 3) ★ 有多少"活"过了清洗、进 retail_clean（污染商品榜）
SELECT COUNT(*) AS 进clean行数, COUNT(DISTINCT stock_code) AS 编码数,
       ROUND(SUM(amount),2) AS 金额,
       ROUND(SUM(amount)*100.0/(SELECT SUM(amount) FROM retail_clean),3) AS 占clean流水pct
FROM retail_clean
WHERE stock_code IN ('POST','DOT','M','C2','D','S','B','BANK CHARGES',
   'ADJUST','ADJUST2','AMAZONFEE','CRUK','PADS','TEST001','TEST002','SP1002')
   OR stock_code LIKE 'DCGS%' OR stock_code LIKE 'gift\_%';

-- 4) 进 clean 的明细
SELECT stock_code, COUNT(*) AS 行数, ROUND(SUM(amount),2) AS 金额
FROM retail_clean
WHERE stock_code IN ('POST','DOT','M','C2','D','S','B','BANK CHARGES',
   'ADJUST','ADJUST2','AMAZONFEE','CRUK','PADS','TEST001','TEST002','SP1002')
   OR stock_code LIKE 'DCGS%' OR stock_code LIKE 'gift\_%'
GROUP BY stock_code ORDER BY 金额 DESC;

-- 5) 真商品码里有没有"5 位数字 + 2 个以上字母"的（验证我的旧正则误判了多少）
SELECT COUNT(DISTINCT stock_code) AS 多字母后缀编码数
FROM retail_clean WHERE stock_code REGEXP '^[0-9]{5}[A-Za-z]{2,}$';
SELECT DISTINCT stock_code FROM retail_clean
WHERE stock_code REGEXP '^[0-9]{5}[A-Za-z]{2,}$' ORDER BY stock_code LIMIT 15;

-- 6) 商品榜：剔掉非商品码之后，金额榜前 10 变成什么
SELECT stock_code, description, ROUND(SUM(amount),2) AS v
FROM retail_clean
WHERE stock_code NOT IN ('POST','DOT','M','C2','D','S','B','BANK CHARGES',
   'ADJUST','ADJUST2','AMAZONFEE','CRUK','PADS','TEST001','TEST002','SP1002')
  AND stock_code NOT LIKE 'DCGS%' AND stock_code NOT LIKE 'gift\_%'
GROUP BY stock_code, description ORDER BY v DESC LIMIT 10;
