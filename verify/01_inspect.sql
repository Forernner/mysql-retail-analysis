SELECT '=== 库列表 ===' AS s;
SHOW DATABASES;
SELECT '=== practice 里的表 ===' AS s;
SELECT table_name, table_rows
FROM information_schema.tables WHERE table_schema='practice' ORDER BY table_name;
SELECT '=== 列信息 ===' AS s;
SELECT table_name, ordinal_position AS pos, column_name, column_type, is_nullable
FROM information_schema.columns
WHERE table_schema='practice'
  AND table_name IN ('online_retail_year_2009_2010','online_retail_year_2010_2011','retail_raw','retail_clean')
ORDER BY table_name, ordinal_position;
