USE practice;
SELECT 'COHORT' AS q;
WITH f AS (SELECT customer_id, LEFT(MIN(invoice_date),7) AS cm FROM retail_clean GROUP BY customer_id),
     act AS (SELECT DISTINCT customer_id, LEFT(invoice_date,7) AS am FROM retail_clean),
     j AS (SELECT f.customer_id, f.cm,
             (CAST(LEFT(am,4) AS SIGNED) - CAST(LEFT(cm,4) AS SIGNED)) * 12
             + (CAST(SUBSTRING(am,6,2) AS SIGNED) - CAST(SUBSTRING(cm,6,2) AS SIGNED)) AS mi
           FROM f JOIN act ON f.customer_id = act.customer_id)
SELECT cm,
       COUNT(DISTINCT CASE WHEN mi=0 THEN customer_id END) m0,
       COUNT(DISTINCT CASE WHEN mi=1 THEN customer_id END) m1,
       COUNT(DISTINCT CASE WHEN mi=2 THEN customer_id END) m2,
       COUNT(DISTINCT CASE WHEN mi=3 THEN customer_id END) m3,
       COUNT(DISTINCT CASE WHEN mi=4 THEN customer_id END) m4,
       COUNT(DISTINCT CASE WHEN mi=5 THEN customer_id END) m5,
       COUNT(DISTINCT CASE WHEN mi=6 THEN customer_id END) m6
FROM j GROUP BY cm ORDER BY cm;
