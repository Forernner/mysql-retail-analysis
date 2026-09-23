-- 变体扫描：找出哪种写法会报 1064 near 'FROM retail_raw)'
SELECT 'A 无别名' AS 变体;
SELECT COUNT(*) AS n FROM (SELECT DISTINCT * FROM retail_raw);

SELECT 'B 少了型号 *' AS 变体;
SELECT COUNT(*) AS n FROM (SELECT DISTINCT FROM retail_raw);

SELECT 'C 多一个左括号' AS 变体;
SELECT COUNT(*) AS n FROM ((SELECT DISTINCT * FROM retail_raw);

SELECT 'D 多一个右括号' AS 变体;
SELECT COUNT(*) AS n FROM (SELECT DISTINCT * FROM retail_raw));

SELECT 'E FROM 与括号间无空格' AS 变体;
SELECT COUNT(*) AS n FROM(SELECT DISTINCT * FROM retail_raw);

SELECT 'F 全角左括号' AS 变体;
SELECT COUNT(*) AS n FROM （SELECT DISTINCT * FROM retail_raw);

SELECT 'G 内层少了 SELECT' AS 变体;
SELECT COUNT(*) AS n FROM (DISTINCT * FROM retail_raw);

SELECT 'H 正确写法' AS 变体;
SELECT COUNT(*) AS n FROM (SELECT DISTINCT * FROM retail_raw) x;
