SELECT '=== 现有表里 description / country 空值到底是 '' 还是 NULL ===' AS s;
SELECT SUM(description IS NULL) AS desc_null, SUM(description='') AS desc_empty,
       SUM(country IS NULL) AS ctry_null, SUM(country='') AS ctry_empty,
       SUM(stock_code IS NULL) AS sku_null, SUM(stock_code='') AS sku_empty,
       SUM(invoice IS NULL) AS inv_null, SUM(invoice='') AS inv_empty,
       SUM(quantity IS NULL) AS qty_null, SUM(unit_price IS NULL) AS price_null,
       SUM(invoice_date IS NULL) AS dt_null
FROM online_retail_year_2009_2010;
SELECT '=== 2010_2011 同上 ===' AS s;
SELECT SUM(description IS NULL) AS desc_null, SUM(description='') AS desc_empty,
       SUM(country IS NULL) AS ctry_null, SUM(country='') AS ctry_empty,
       SUM(stock_code IS NULL) AS sku_null, SUM(stock_code='') AS sku_empty,
       SUM(invoice IS NULL) AS inv_null, SUM(invoice='') AS inv_empty,
       SUM(quantity IS NULL) AS qty_null, SUM(unit_price IS NULL) AS price_null,
       SUM(invoice_date IS NULL) AS dt_null
FROM online_retail_year_2010_2011;
