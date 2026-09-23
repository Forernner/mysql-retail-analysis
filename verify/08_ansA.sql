USE practice;

SELECT 'C.S1.rows',        CAST(COUNT(*) AS CHAR) FROM online_retail_year_2009_2010
UNION ALL SELECT 'C.S1.uniq_rows',   CAST(COUNT(*) AS CHAR) FROM (SELECT DISTINCT * FROM online_retail_year_2009_2010) x
UNION ALL SELECT 'C.S1.inv',         CAST(COUNT(DISTINCT invoice) AS CHAR) FROM online_retail_year_2009_2010
UNION ALL SELECT 'C.S1.item',        CAST(COUNT(DISTINCT stock_code) AS CHAR) FROM online_retail_year_2009_2010
UNION ALL SELECT 'C.S1.cust',        CAST(COUNT(DISTINCT customer_id) AS CHAR) FROM online_retail_year_2009_2010
UNION ALL SELECT 'C.S1.country',     CAST(COUNT(DISTINCT country) AS CHAR) FROM online_retail_year_2009_2010
UNION ALL SELECT 'C.S1.dmin',        CAST(MIN(invoice_date) AS CHAR) FROM online_retail_year_2009_2010
UNION ALL SELECT 'C.S1.dmax',        CAST(MAX(invoice_date) AS CHAR) FROM online_retail_year_2009_2010

UNION ALL SELECT 'C.S2.rows',        CAST(COUNT(*) AS CHAR) FROM online_retail_year_2010_2011
UNION ALL SELECT 'C.S2.uniq_rows',   CAST(COUNT(*) AS CHAR) FROM (SELECT DISTINCT * FROM online_retail_year_2010_2011) x
UNION ALL SELECT 'C.S2.inv',         CAST(COUNT(DISTINCT invoice) AS CHAR) FROM online_retail_year_2010_2011
UNION ALL SELECT 'C.S2.item',        CAST(COUNT(DISTINCT stock_code) AS CHAR) FROM online_retail_year_2010_2011
UNION ALL SELECT 'C.S2.cust',        CAST(COUNT(DISTINCT customer_id) AS CHAR) FROM online_retail_year_2010_2011
UNION ALL SELECT 'C.S2.country',     CAST(COUNT(DISTINCT country) AS CHAR) FROM online_retail_year_2010_2011
UNION ALL SELECT 'C.S2.dmin',        CAST(MIN(invoice_date) AS CHAR) FROM online_retail_year_2010_2011
UNION ALL SELECT 'C.S2.dmax',        CAST(MAX(invoice_date) AS CHAR) FROM online_retail_year_2010_2011

UNION ALL SELECT 'C.raw.rows',       CAST(COUNT(*) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.raw.uniq_rows',  CAST(COUNT(*) AS CHAR) FROM (SELECT DISTINCT * FROM retail_raw) x
UNION ALL SELECT 'C.raw.uniq_inv',   CAST(COUNT(DISTINCT invoice) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.raw.uniq_item',  CAST(COUNT(DISTINCT stock_code) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.raw.uniq_cust',  CAST(COUNT(DISTINCT customer_id) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.raw.uniq_country', CAST(COUNT(DISTINCT country) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.raw.dup_total',  CAST(COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM retail_raw) y) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.dup_sheet1',     CAST((SELECT COUNT(*) FROM online_retail_year_2009_2010) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM online_retail_year_2009_2010) y) AS CHAR)
UNION ALL SELECT 'C.dup_sheet2',     CAST((SELECT COUNT(*) FROM online_retail_year_2010_2011) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM online_retail_year_2010_2011) y) AS CHAR)
UNION ALL SELECT 'C.dup_groups',     CAST((SELECT COUNT(*) FROM (SELECT 1 FROM retail_raw GROUP BY invoice,stock_code,description,quantity,invoice_date,unit_price,customer_id,country HAVING COUNT(*)>1) y) AS CHAR)
UNION ALL SELECT 'C.inv_both',       CAST((SELECT COUNT(*) FROM (SELECT invoice FROM online_retail_year_2009_2010 INTERSECT SELECT invoice FROM online_retail_year_2010_2011) y) AS CHAR)
;

SELECT 'C.neg_qty',       CAST(SUM(quantity<0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.zero_qty',     CAST(SUM(quantity=0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.price_le0',    CAST(SUM(unit_price<=0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.price_eq0',    CAST(SUM(unit_price=0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.price_lt0',    CAST(SUM(unit_price<0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.cancel',       CAST(SUM(invoice LIKE 'C%') AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.cancel_neg',   CAST(SUM(invoice LIKE 'C%' AND quantity<0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.cancel_pos',   CAST(SUM(invoice LIKE 'C%' AND quantity>0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.cancel_zero',  CAST(SUM(invoice LIKE 'C%' AND quantity=0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.cancel_nocust',CAST(SUM(invoice LIKE 'C%' AND customer_id IS NULL) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.noncancel_neg',CAST(SUM(invoice NOT LIKE 'C%' AND quantity<0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.a_inv',        CAST(SUM(invoice LIKE 'A%') AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.no_cust',      CAST(SUM(customer_id IS NULL) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.bad_union',    CAST(SUM(invoice LIKE 'C%' OR quantity<=0 OR customer_id IS NULL OR unit_price<=0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.bad_sum_simple',CAST(SUM(invoice LIKE 'C%') + SUM(quantity<0) + SUM(customer_id IS NULL) + SUM(unit_price<=0) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.amount_raw_all',      CAST(ROUND(SUM(quantity*unit_price),2) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.amount_filtered_nodup',CAST(ROUND(SUM(quantity*unit_price),2) AS CHAR) FROM retail_raw
      WHERE invoice NOT LIKE 'C%' AND quantity>0 AND customer_id IS NOT NULL AND unit_price>0
UNION ALL SELECT 'C.amount_guest',CAST(ROUND(SUM(quantity*unit_price),2) AS CHAR) FROM retail_raw
      WHERE invoice NOT LIKE 'C%' AND quantity>0 AND customer_id IS NULL AND unit_price>0
UNION ALL SELECT 'C.amount_cancel',CAST(ROUND(SUM(quantity*unit_price),2) AS CHAR) FROM retail_raw WHERE invoice LIKE 'C%'
UNION ALL SELECT 'C.q16s0',CAST(COUNT(*) AS CHAR) FROM retail_raw
UNION ALL SELECT 'C.q16s1',CAST(COUNT(*) AS CHAR) FROM retail_raw WHERE invoice NOT LIKE 'C%'
UNION ALL SELECT 'C.q16s2',CAST(COUNT(*) AS CHAR) FROM retail_raw WHERE invoice NOT LIKE 'C%' AND quantity>0
UNION ALL SELECT 'C.q16s3',CAST(COUNT(*) AS CHAR) FROM retail_raw WHERE invoice NOT LIKE 'C%' AND quantity>0 AND customer_id IS NOT NULL
UNION ALL SELECT 'C.q16s4',CAST(COUNT(*) AS CHAR) FROM retail_raw WHERE invoice NOT LIKE 'C%' AND quantity>0 AND customer_id IS NOT NULL AND unit_price>0
UNION ALL SELECT 'C.q16s5',CAST(COUNT(*) AS CHAR) FROM (SELECT DISTINCT * FROM retail_raw WHERE invoice NOT LIKE 'C%' AND quantity>0 AND customer_id IS NOT NULL AND unit_price>0) y
UNION ALL SELECT 'C.clean.rows',    CAST(COUNT(*) AS CHAR) FROM retail_clean
UNION ALL SELECT 'C.clean.amount',  CAST(ROUND(SUM(amount),2) AS CHAR) FROM retail_clean
UNION ALL SELECT 'C.clean.inv',     CAST(COUNT(DISTINCT invoice) AS CHAR) FROM retail_clean
UNION ALL SELECT 'C.clean.item',    CAST(COUNT(DISTINCT stock_code) AS CHAR) FROM retail_clean
UNION ALL SELECT 'C.clean.cust',    CAST(COUNT(DISTINCT customer_id) AS CHAR) FROM retail_clean
UNION ALL SELECT 'C.clean.country', CAST(COUNT(DISTINCT country) AS CHAR) FROM retail_clean
;

-- 商品名空格差异排查
SELECT 'D.desc_ne_trim',        CAST(SUM(description <> TRIM(description)) AS CHAR) FROM retail_raw
UNION ALL SELECT 'D.desc_lead_space',  CAST(SUM(description LIKE ' %') AS CHAR) FROM retail_raw
UNION ALL SELECT 'D.desc_trail_space', CAST(SUM(description LIKE '% ' AND description NOT LIKE ' %' AND description = TRIM(description)) AS CHAR) FROM retail_raw
UNION ALL SELECT 'D.desc_pad_eq',      CAST(SUM(description LIKE '% ' AND description = TRIM(description)) AS CHAR) FROM retail_raw
UNION ALL SELECT 'D.collation_test',   IF('X ' = 'X', 'PAD(=)', 'NO PAD(<>)')
UNION ALL SELECT 'D.desc_null',        CAST(SUM(description IS NULL) AS CHAR) FROM retail_raw
;
SELECT 'D.collation_of_col', COLLATION(description) FROM retail_raw LIMIT 1;
