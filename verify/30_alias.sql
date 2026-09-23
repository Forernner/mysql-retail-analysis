-- 复现你截图里那条报错，并验证「加别名」是否就是根因
-- A) 你截图里的写法（先确认它是否真的报错）
SELECT COUNT(*) AS 完全去重后行数 FROM (SELECT DISTINCT * FROM retail_raw) ;
-- ↑ 预期：报错。把这一行单独跑，看错误码到底是 1064 还是 1248

-- B) 只把计数换成一个数，验证除别名外没有别的问题
SET @n = (SELECT COUNT(*) FROM retail_raw);
SELECT @n AS 合并行数;

-- C) 正确写法（带别名 x）
SELECT COUNT(*) AS 完全去重后行数 FROM (SELECT DISTINCT * FROM retail_raw) x;

-- D) 别名写成 AS x 也一样（更不容易看漏）
SELECT COUNT(*) AS 完全去重后行数 FROM (SELECT DISTINCT * FROM retail_raw) AS x;
