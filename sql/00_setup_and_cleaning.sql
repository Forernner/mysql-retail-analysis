/* ==========================================================================
   第 00 步 · 两表合并 → 建 retail_raw → 建 retail_clean   （可重复执行）
   --------------------------------------------------------------------------
   数据源：你本地已导入成功的这两张表（列名已是小写）
        online_retail_year_2009_2010   （525,461 行）
        online_retail_year_2010_2011   （541,910 行）
   产出：
        retail_raw     合并后的原始表（1,067,371 行，含重复行 —— 正常，见 Q2）
        retail_clean   清洗+去重后的分析底表（779,425 行）

   工具：Navicat 查询窗口。**从上往下按段运行**，每段跑完看结果对不对再往下。
   本脚本可整段重跑（DROP + 重建），跑错不用怕。

   ⚠️⚠️ 跑之前先看这条（2026-09-21 真实踩过一次）⚠️⚠️
   每一段都是「DROP TABLE → CREATE TABLE → INSERT ... SELECT」三句连在一起的。
   ★ 必须【整段一起跑】。如果只跑到 CREATE 就停手，你会得到一张**空表** ——
     屏幕上不报任何错，但后面所有题的查询结果全是 0，极难自查。
   ★ 自查方法：跑完第 2 段后立刻执行
        SELECT COUNT(*) FROM retail_clean;      -- 必须是 779,425
     或者直接跑第 3 段的 11 行总校验：11 个数字全对上，才算这一段跑完了。

   ★ v3 修正（2026-09-20 夜，全部在你本机 MySQL 8.0 实跑验证过）
     ① 上一版第 2 段有一句 `FROM (SELECT DISTINCT * FROM retail_raw)` 少了别名，
        MySQL 报 `1248 Every derived table must have its own alias` —— 已修（加 `) x`）。
        这是 MySQL 的硬规则：**每个派生表（FROM 后面的子查询）都必须有别名**。
     ② 上一版第 1 段的 `ALTER TABLE ... CHANGE COLUMN` 把日期列改坏了：
        你导入时 `InvoiceDate` 被建成了 TIME 型（只存了时间），
        `CHANGE COLUMN ... DATETIME` 会让 MySQL 用「执行当天」补齐日期部分，
        结果全表日期变成导入那天（2026-09-20），时间部分倒是对的。
        日期已重新灌好，本脚本**不再做任何 ALTER**。
     ③ 新增「第 0 段」的时间体检：这个坑以后必须靠这一步提前抓住。
   ========================================================================== */


/* ==========================================================================
   第 0 段 · 体检（先跑这一段，只读不改）
   ========================================================================== */

-- 0.1 这两张表现在有哪些列？
SELECT table_name, ordinal_position AS 序号, column_name AS 列名, column_type AS 类型
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name IN ('online_retail_year_2009_2010', 'online_retail_year_2010_2011')
ORDER BY table_name, ordinal_position;

-- 0.2 两张表各有多少行？（必须对上，对不上说明当初没导齐）
SELECT 'online_retail_year_2009_2010' AS 表名, COUNT(*) AS 行数 FROM online_retail_year_2009_2010
UNION ALL
SELECT 'online_retail_year_2010_2011',          COUNT(*)          FROM online_retail_year_2010_2011;
-- 基准：     525,461        /        541,910        / 合计 1,067,371

-- 0.3 ★时间列体检★ —— 这一步能提前抓住"日期被 TIME 化"那个坑
--     判据：全表日期如果挤在同一天 → 100% 是 TIME 转 DATETIME 被补了当天日期
SELECT MIN(invoice_date) AS 最早, MAX(invoice_date) AS 最晚,
       DATEDIFF(MAX(invoice_date), MIN(invoice_date)) AS 跨天数,
       IF(DATE(MIN(invoice_date)) = DATE(MAX(invoice_date)),
          '⚠️ 全表日期同一天 → 日期列已损坏（InvoiceDate 很可能被识别成 TIME 型）',
          '正常') AS 体检结论
FROM online_retail_year_2009_2010
UNION ALL
SELECT MIN(invoice_date), MAX(invoice_date),
       DATEDIFF(MAX(invoice_date), MIN(invoice_date)),
       IF(DATE(MIN(invoice_date)) = DATE(MAX(invoice_date)), '⚠️ 全表日期同一天 → 日期列已损坏', '正常')
FROM online_retail_year_2010_2011;
-- 基准：2009-12-01 07:45:00 ~ 2010-12-09 20:01:00（跨 373 天，结论"正常"）
--       2010-12-01 08:26:00 ~ 2011-12-09 12:50:00（跨 373 天，结论"正常"）
-- ⚠️ 判据是"最早和最晚是不是同一天"，不是"跨天数够不够大" —— 单张表本来就只跨 373 天。
-- 如果两条都得到 2026-xx-xx（同一天）→ 日期列坏了，别往下做，先重新导入。


/* ==========================================================================
   第 1 段 · 建 retail_raw：两张表 UNION ALL 合并（1,067,371 行）
   ========================================================================== */

DROP TABLE IF EXISTS retail_raw;

CREATE TABLE retail_raw (
  invoice      VARCHAR(20)   NULL COMMENT '发票号；C 开头=退货冲销，A 开头=坏账调整',
  stock_code   VARCHAR(20)   NULL COMMENT '商品编码；含 POST/DOT/M/B 等非商品码',
  description  VARCHAR(200)  NULL COMMENT '商品名；20% 带尾随空格，4,382 行为空',
  quantity     INT           NULL COMMENT '数量；负数=退货',
  invoice_date DATETIME      NULL COMMENT '开票时间',
  unit_price   DECIMAL(10,4) NULL COMMENT '单价；有 0 与负数',
  customer_id  INT           NULL COMMENT '客户ID；22.77% 为空（散客）',
  country      VARCHAR(60)   NULL COMMENT '国家',
  KEY ix_date (invoice_date),
  KEY ix_cust (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO retail_raw
SELECT invoice, stock_code, description, quantity, invoice_date, unit_price,
       NULLIF(customer_id, 0),   -- 0 统一成 NULL，只有一种空值口径
       country
FROM online_retail_year_2009_2010
UNION ALL
SELECT invoice, stock_code, description, quantity, invoice_date, unit_price,
       NULLIF(customer_id, 0),
       country
FROM online_retail_year_2010_2011;

-- 校验：两句话，两个数，必须全对
SELECT COUNT(*) AS 合并行数 FROM retail_raw;
-- = 1,067,371

SELECT COUNT(*) AS 完全去重后行数
FROM (SELECT DISTINCT * FROM retail_raw) AS t;
-- = 1,033,036
--
--   ★ AS t 这个别名是必须的（写 t / x / whatever 都行，但不能没有）
--     ❌ 少了它 → ERROR 1248 Every derived table must have its own alias
--   ★ 如果报 ERROR 1064 ... near 'FROM retail_raw)'
--     → 说明 DISTINCT 后面那个 * 丢了，或者被复制粘贴带进了不可见字符
--       MySQL 实际读到的是 "SELECT DISTINCT FROM retail_raw"，自然语法错
--     → 把 * 重新打成半角星号；不要手打、不要从渲染后的文档半截复制


/* ==========================================================================
   第 2 段 · 建 retail_clean：清洗（4 个条件）+ 完全去重 → 779,425 行
   ========================================================================== */

DROP TABLE IF EXISTS retail_clean;

CREATE TABLE retail_clean (
  invoice      VARCHAR(20)   NOT NULL,
  stock_code   VARCHAR(20)   NOT NULL,
  description  VARCHAR(200)  NULL,
  quantity     INT           NOT NULL,
  invoice_date DATETIME      NOT NULL,
  unit_price   DECIMAL(10,4) NOT NULL,
  customer_id  INT           NOT NULL,
  country      VARCHAR(60)   NOT NULL,
  amount       DECIMAL(16,4) NOT NULL COMMENT '派生列 = quantity * unit_price',
  KEY ix_date (invoice_date),
  KEY ix_cust (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO retail_clean
SELECT DISTINCT                       -- ← 第 5 件事：完全去重（原始数据里 34,335 行重复）
  invoice,
  TRIM(stock_code),                   -- 有 1 个编码是 '47503J '，尾部带空格
  TRIM(description),                  -- 20% 的商品名带尾随空格，不去掉会把同一商品算成两个
  quantity,
  invoice_date,
  unit_price,
  customer_id,
  TRIM(country),
  quantity * unit_price               -- 派生金额列
FROM retail_raw
WHERE invoice NOT LIKE 'C%'           -- ① 剔退货单：不是销售，是冲销
  AND quantity > 0                    -- ② 剔负数量：同上；顺带剔掉数量为 0 的行
  AND customer_id IS NOT NULL         -- ③ 剔散客：无 ID 无法做客户级留存/复购
  AND unit_price > 0;                 -- ④ 剔零价与负价：赠品无金额意义，负价是坏账调整

-- ★ 插完立刻自查（本段含 DROP，重复执行整段是安全的；但如果只重复跑了 INSERT，会变成 1,558,850）
SELECT COUNT(*) AS clean行数, ROUND(SUM(amount),2) AS 总金额 FROM retail_clean;
-- 必须是 779,425 / 17,374,804.27。若跑出 1,558,850 / 34,749,608.54 → 你重复插入了，整段重跑一次即可


/* ==========================================================================
   第 3 段 · 总校验（11 行结果全部对上，就能开始做题了）
   ========================================================================== */

SELECT '1  retail_raw 行数'          AS 校验项, CAST((SELECT COUNT(*) FROM retail_raw) AS CHAR) AS 结果
UNION ALL SELECT '2  raw 完全去重后',        CAST((SELECT COUNT(*) FROM (SELECT DISTINCT * FROM retail_raw) x) AS CHAR)
UNION ALL SELECT '3  retail_clean 行数',     CAST((SELECT COUNT(*) FROM retail_clean) AS CHAR)
UNION ALL SELECT '4  clean 总金额',          CAST((SELECT ROUND(SUM(amount),2) FROM retail_clean) AS CHAR)
UNION ALL SELECT '5  clean 唯一发票',        CAST((SELECT COUNT(DISTINCT invoice) FROM retail_clean) AS CHAR)
UNION ALL SELECT '6  clean 唯一商品',        CAST((SELECT COUNT(DISTINCT stock_code) FROM retail_clean) AS CHAR)
UNION ALL SELECT '7  clean 唯一客户',        CAST((SELECT COUNT(DISTINCT customer_id) FROM retail_clean) AS CHAR)
UNION ALL SELECT '8  clean 时间下限',        CAST((SELECT MIN(invoice_date) FROM retail_clean) AS CHAR)
UNION ALL SELECT '9  clean 时间上限',        CAST((SELECT MAX(invoice_date) FROM retail_clean) AS CHAR)
UNION ALL SELECT '10 两表时间是否重叠',
  IF((SELECT MAX(invoice_date) FROM online_retail_year_2009_2010)
     >= (SELECT MIN(invoice_date) FROM online_retail_year_2010_2011),
     '重叠，必须去重', '不重叠')
UNION ALL SELECT '11 日期是否落在 2009~2011',
  IF((SELECT MIN(invoice_date) FROM retail_raw) = '2009-12-01 07:45:00'
     AND (SELECT MAX(invoice_date) FROM retail_raw) = '2011-12-09 12:50:00',
     '正常', '⚠️ 日期异常，回第 0 段体检');

/*  ┌─────────────────────────── 基准值（在你本机 MySQL 8.0 实跑，2026-09-20）───────────────────────────┐
    │                                                                                                  │
    │   1  1,067,371            6  4,631              11 正常                                          │
    │   2  1,033,036            7  5,878                                                               │
    │   3  779,425              8  2009-12-01 07:45:00                                                 │
    │   4  17,374,804.27        9  2011-12-09 12:50:00                                                 │
    │   5  36,969               10 重叠，必须去重                                                       │
    │                                                                                                  │
    │   ※ 4 号金额允许 ±0.01 的差异                                                                    │
    │   ※ 6 号拿到 5,305 或 5,132 都是"对"的，看你用哪种排序规则（见下面 §5）                          │
    └──────────────────────────────────────────────────────────────────────────────────────────────────┘
*/


/* ==========================================================================
   第 4 段（可选）· 把这次发现的"重复行"单独看一遍 —— 作品集/面试会用到
   ========================================================================== */

-- 重复行长什么样（同 8 列完全相同、出现 ≥2 次）
SELECT invoice, stock_code, description, quantity, invoice_date, unit_price,
       customer_id, country, COUNT(*) AS 出现次数
FROM retail_raw
GROUP BY invoice, stock_code, description, quantity, invoice_date, unit_price,
         customer_id, country
HAVING COUNT(*) > 1
ORDER BY 出现次数 DESC, quantity DESC
LIMIT 20;

-- 重复行按月份分布（34,335 行到底从哪来）
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS 月份, SUM(c - 1) AS 被去掉的重复行数
FROM (
  SELECT invoice_date, COUNT(*) AS c
  FROM retail_raw
  GROUP BY invoice, stock_code, description, quantity, invoice_date,
           unit_price, customer_id, country
  HAVING COUNT(*) > 1
) t
GROUP BY 月份
ORDER BY 被去掉的重复行数 DESC;
/*  基准（前 5 名，MySQL 实跑）
    2010-12  23,023   ← 两表时间重叠造成（跨表重复 22,202 行全在这里）
    2010-11   1,431
    2011-11   1,368
    2010-10     849
    2011-10     773
    （剩下 12,133 行是单表内部的重复，散布在 25 个月里）

   ⚠️ 分组列必须是"全部 8 列"：只按 customer_id 分组会算出 1,061,428 行"重复"（虚高 31 倍）。
      自检：SUM(c-1) 必须等于 1,067,371 − 1,033,036 = 34,335，对不上就是分组列选错了。
*/

-- 两张表共同出现的发票有多少张？（答案：1,088）
SELECT COUNT(*) AS 两表共同发票数 FROM (
  SELECT invoice FROM online_retail_year_2009_2010
  INTERSECT
  SELECT invoice FROM online_retail_year_2010_2011
) x;
-- ※ INTERSECT 需要 MySQL 8.0.31+。老版本用下面这句：
--   SELECT COUNT(DISTINCT a.invoice) FROM online_retail_year_2009_2010 a
--   JOIN online_retail_year_2010_2011 b ON b.invoice = a.invoice;


/* ==========================================================================
   第 5 段（可选）· 一个能写进简历的发现：排序规则会改变"唯一商品数"
   ========================================================================== */

-- 同一列，三种排序规则，三个答案 —— 这就是"我做过数据质量核查"的证据
SELECT COUNT(DISTINCT stock_code)                              AS 默认_忽略大小写并忽略尾空格,  -- 5,132
       COUNT(DISTINCT stock_code COLLATE utf8mb4_bin)          AS 区分大小写_仍忽略尾空格,       -- 5,304
       COUNT(DISTINCT stock_code COLLATE utf8mb4_0900_bin)     AS 大小写和尾空格都区分          -- 5,305
FROM retail_raw;
/*  为什么：
    · 默认 utf8mb4_0900_ai_ci 是 NO PAD + 忽略大小写 → '15056BL' 和 '15056bl' 算一个 → 5,132
    · utf8mb4_bin 区分大小写，但它是 PAD SPACE → '47503J ' 和 '47503J' 算一个 → 5,304
    · utf8mb4_0900_bin 两者都区分 → 5,305（和 Python / CSV 侧的数一致）
    ★ 面试话术："唯一商品数报 5,132 还是 5,305，取决于排序规则 —— 我在报告里会写明口径。"
*/

/* ==========================================================================
   完事。接下来用 output/SQL练习卷-题目骨架-王自强-v3.sql 逐题做，
   答案对照 output/SQL实战试卷-Day2-4-王自强-v3-2026-09-20.md
   ========================================================================== */
