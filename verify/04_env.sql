SELECT '=== local_infile ===' AS s;
SHOW VARIABLES LIKE 'local_infile';
SELECT '=== secure_file_priv ===' AS s;
SHOW VARIABLES LIKE 'secure_file_priv';
SELECT '=== retail 库里的表 ===' AS s;
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('retail','practice') ORDER BY table_schema, table_name;
SELECT '=== exact counts ===' AS s;
SELECT (SELECT COUNT(*) FROM practice.online_retail_year_2009_2010) s1,
       (SELECT COUNT(*) FROM practice.online_retail_year_2010_2011) s2,
       (SELECT COUNT(*) FROM practice.retail_raw) raw;
SELECT '=== 源表 customer_id 为空的写法 ===' AS s;
SELECT SUM(customer_id IS NULL) FROM practice.online_retail_year_2009_2010;
