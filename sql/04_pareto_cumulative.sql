-- =====================================================================
-- Q24 · 帕累托 80/20 —— 从 6 行小表到 77 万行的完整拆解
-- 王自强 · 2026-09-23 · 库：practice
-- =====================================================================
-- ⚠️ 第 0 段含 CREATE / TRUNCATE / INSERT —— 请【整段跑】，不要只选中中间几行。
--    跑完自带自查语句（应为 6 行 / 总额 260）。其余各段都是 SELECT。
-- =====================================================================


-- ─────────────────────────────────────────────────────────────────────
-- 第 0 段 · 建教学小表（6 个 SKU，总流水刚好 260，方便手算）
-- ⚠️ 含破坏性语句：TRUNCATE 会清空 wf_pareto，【整段跑】
-- 自查：行数 = 6，总额 = 260
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wf_pareto (
    sku VARCHAR(10) PRIMARY KEY,
    rev DECIMAL(10,2)
);
TRUNCATE TABLE wf_pareto;
INSERT INTO wf_pareto (sku, rev) VALUES
 ('A',100), ('B',60), ('C',40), ('D',30), ('E',20), ('F',10);

-- ★ 自查（必须跑，确认上一步真的插进去了）
SELECT COUNT(*) AS 行数, SUM(rev) AS 总额 FROM wf_pareto;


-- ─────────────────────────────────────────────────────────────────────
-- 实验 1 · 新东西①：SUM(rev) OVER () —— 不折叠的 SUM
-- 预期：6 行，每行的「全表总额」列都是 260
--
-- ★ 对照你刚问的 Q22：
--   GROUP BY   → 把 6 行折叠成 1 行，总数只剩一个（所以要靠子查询搬回来）
--   OVER ()    → 6 行还是 6 行，只是每行都盖上了总数 260
--   这是同一件事的两种解法。
-- ─────────────────────────────────────────────────────────────────────
SELECT sku, rev,
       SUM(rev) OVER () AS 全表总额
FROM wf_pareto
ORDER BY rev DESC;


-- ─────────────────────────────────────────────────────────────────────
-- 实验 2 · 新东西②：SUM(rev) OVER (ORDER BY rev DESC) —— 累计
-- 预期：100 / 160 / 200 / 230 / 250 / 260  （逐行往下累加）
--
-- ★ 和实验 1 的区别只有「括号里写没写 ORDER BY」：
--   空括号 ()          → 整个窗口都算一遍 → 每行都一样（总数）
--   带 ORDER BY        → 窗口从第一行"滚"到当前行 → 每行都更长一点（累计）
-- ─────────────────────────────────────────────────────────────────────
SELECT sku, rev,
       SUM(rev) OVER (ORDER BY rev DESC) AS 累计
FROM wf_pareto;


-- ─────────────────────────────────────────────────────────────────────
-- 实验 3 · 新东西③：那个 ROWS BETWEEN 到底管什么
--   3a 用 6 行小表（金额都不重复）跑，看到 ROWS 版和默认版结果一样
--   3b 用一张【金额全相同】的小表跑，两条路立刻分叉 ← 这就是坑的现场
--
-- 预期 3b：
--   ROWS 版  → 50 / 100 / 150 / 200   （一行一行累加）
--   默认版   → 200 / 200 / 200 / 200   （金额相同的行被"一起"累加）
-- ─────────────────────────────────────────────────────────────────────
-- 3a（在 wf_pareto 上）
SELECT sku, rev,
       SUM(rev) OVER (ORDER BY rev DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 显式ROWS版,
       SUM(rev) OVER (ORDER BY rev DESC)                                                 AS 省略默认版
FROM wf_pareto;

-- 3b（造一张金额全相同的表）
-- ⚠️ 含 INSERT，整段跑
-- 💡 不想建新表的话，也可以用教程《窗口函数从零开始》里的 wf_demo 演示：
--    它有两行 amount 都是 80.00，跑 ROWS 版得 680/760，跑默认版得 760/760，
--    效果一样，而且不用建表。
CREATE TABLE IF NOT EXISTS wf_same (
    sku CHAR(1) PRIMARY KEY,
    rev DECIMAL(10,2)
);
TRUNCATE TABLE wf_same;
INSERT INTO wf_same (sku, rev) VALUES ('A',50),('B',50),('C',50),('D',50);
SELECT COUNT(*) AS 行数, SUM(rev) AS 总额 FROM wf_same;   -- 自查 4 行 / 200

SELECT sku, rev,
       SUM(rev) OVER (ORDER BY rev DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 显式ROWS版,
       SUM(rev) OVER (ORDER BY rev DESC)                                                 AS 省略默认版
FROM wf_same;

-- ★ 结论：省略 ROWS 时默认是 RANGE 模式，它把「金额相同」的行视为同一档，
--   在累加到这一档时会把它们【一起】加进来。
--   所以真实数据里只要有一批 SKU 流水相同，累计就会"跳"一下，
--   首次越过 80% 的排名会偏前 → 算出来的 SKU 数【偏小】。
--   Q24 的答案里坚持写 ROWS BETWEEN，就是为了消除这个不确定性。


-- ─────────────────────────────────────────────────────────────────────
-- 实验 4 · 把三块拼起来，先在小表上验证（这才是你的第一步）
-- 预期：sku_for_80 = 4 ｜ pct_for_80 = 66.67 ｜ sku_for_50 = 2 ｜ pct_for_50 = 33.33 ｜ sku_total = 6
--
-- 手算核对：80% 阈值 = 260 × 0.8 = 208 → 累计 200 不够、230 够了 → 第 4 行
--           50% 阈值 = 260 × 0.5 = 130 → 累计 100 不够、160 够了 → 第 2 行
-- ─────────────────────────────────────────────────────────────────────
WITH p AS (
    SELECT sku AS stock_code, rev FROM wf_pareto
),
r AS (
    SELECT stock_code, rev,
           ROW_NUMBER() OVER (ORDER BY rev DESC) AS rn,
           COUNT(*)     OVER ()                  AS n,
           SUM(rev)     OVER ()                  AS total,
           SUM(rev)     OVER (ORDER BY rev DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum
    FROM p
)
SELECT
    (SELECT MIN(rn) FROM r WHERE cum >= 0.8 * total)                        AS sku_for_80,
    (SELECT ROUND(MIN(rn) * 100.0 / n, 2) FROM r WHERE cum >= 0.8 * total)  AS pct_for_80,
    (SELECT MIN(rn) FROM r WHERE cum >= 0.5 * total)                        AS sku_for_50,
    (SELECT ROUND(MIN(rn) * 100.0 / n, 2) FROM r WHERE cum >= 0.5 * total)  AS pct_for_50,
    (SELECT COUNT(*) FROM p)                                                AS sku_total;


-- ─────────────────────────────────────────────────────────────────────
-- 实验 5 · 换成 77 万行真表（Q24 原题）
-- 预期：992 ｜ 21.42 ｜ 272 ｜ 5.87 ｜ 4631
-- ─────────────────────────────────────────────────────────────────────
WITH p AS (
    SELECT stock_code, SUM(amount) AS rev
    FROM retail_clean
    GROUP BY stock_code
),
r AS (
    SELECT stock_code, rev,
           ROW_NUMBER() OVER (ORDER BY rev DESC) AS rn,
           COUNT(*)     OVER ()                  AS n,
           SUM(rev)     OVER ()                  AS total,
           SUM(rev)     OVER (ORDER BY rev DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum
    FROM p
)
SELECT
    (SELECT MIN(rn) FROM r WHERE cum >= 0.8 * total)                        AS sku_for_80,
    (SELECT ROUND(MIN(rn) * 100.0 / n, 2) FROM r WHERE cum >= 0.8 * total)  AS pct_for_80,
    (SELECT MIN(rn) FROM r WHERE cum >= 0.5 * total)                        AS sku_for_50,
    (SELECT ROUND(MIN(rn) * 100.0 / n, 2) FROM r WHERE cum >= 0.5 * total)  AS pct_for_50,
    (SELECT COUNT(*) FROM p)                                                AS sku_total;


-- ─────────────────────────────────────────────────────────────────────
-- 实验 6 · ⏸ 等价替代写法（不用窗口函数，用你已学的自连接）
--
-- 思路：把表跟自己连一次，b.rev >= a.rev —— 于是每一行 a 都配上
--       "排在它前面的所有行"，SUM(b.rev) 就是累计值。
--
-- ⚠️ 慢！中间结果约 4631 × 4631 ÷ 2 ≈ 1000 万行组合，
--    在小表上跑没问题，在 retail_clean 上可能要等十几秒到几十秒。
-- ⚠️ 它对「金额并列」的处理等价于 RANGE 模式（同值一起累加），
--    所以结果【可能与实验 5 差 1~2 个 SKU】—— 这不是错，是另一种口径。
--    跑出来对比一下，你会更明白实验 3 那个坑有多大。
-- ─────────────────────────────────────────────────────────────────────
-- 6a 先在小表上验证思路（预期：A 100 / B 160 / C 200 / D 230 / E 250 / F 260）
WITH p AS (
    SELECT sku AS stock_code, rev FROM wf_pareto
)
SELECT a.stock_code, a.rev, SUM(b.rev) AS cum
FROM p AS a
JOIN p AS b ON b.rev >= a.rev
GROUP BY a.stock_code, a.rev
ORDER BY cum;

-- 6b 真表版（⚠️ 慢，跑之前想清楚）
WITH p AS (
    SELECT stock_code, SUM(amount) AS rev
    FROM retail_clean GROUP BY stock_code
),
c AS (
    SELECT a.stock_code, a.rev, SUM(b.rev) AS cum
    FROM p AS a JOIN p AS b ON b.rev >= a.rev
    GROUP BY a.stock_code, a.rev
)
SELECT COUNT(*) AS 累计到80pct的SKU数
FROM c
WHERE cum >= 0.8 * (SELECT SUM(rev) FROM p);
