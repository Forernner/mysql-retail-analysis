# -*- coding: utf-8 -*-
"""重测：用 EXPLAIN ANALYZE 读 MySQL 自报的实际执行时间（避开客户端启动开销）"""
import subprocess, re
MYSQL = r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
BASE = [MYSQL, "-h127.0.0.1", "-uroot", "-p<YOUR_PASSWORD>",
        "--default-character-set=utf8mb4", "-B", "-N", "practice"]

def q(sql, show_err=True):
    r = subprocess.run(BASE + ["-e", sql], capture_output=True, text=True,
                       encoding="utf-8", errors="ignore", timeout=1800)
    if show_err and r.stderr.strip():
        for l in r.stderr.splitlines():
            if "Warning" not in l:
                print("   [stderr]", l)
    return r.stdout.strip()

print("=== 1. 建无索引副本（LIKE + 删索引 + INSERT SELECT，更可靠）===")
q("DROP TABLE IF EXISTS retail_clean_noidx;")
q("CREATE TABLE retail_clean_noidx LIKE retail_clean;")
q("ALTER TABLE retail_clean_noidx DROP INDEX ix_date, DROP INDEX ix_cust;")
q("INSERT INTO retail_clean_noidx SELECT * FROM retail_clean;")
print("原表行数 :", q("SELECT COUNT(*) FROM retail_clean;"))
print("副本行数 :", q("SELECT COUNT(*) FROM retail_clean_noidx;"))
print("副本索引 :", q("SHOW INDEX FROM retail_clean_noidx;") or "（无索引 ✓）")

CASES = [
    ("① 按客户查（ix_cust 命中）",
     "SELECT COUNT(*), ROUND(SUM(amount),2) FROM {t} WHERE customer_id = 16446;"),
    ("② 按月份查（ix_date 命中）",
     "SELECT COUNT(*), ROUND(SUM(amount),2) FROM {t} WHERE invoice_date >= '2011-12-01' AND invoice_date < '2012-01-01';"),
    ("③ 按国家查（两个表都没索引，对照用）",
     "SELECT COUNT(*) FROM {t} WHERE country = 'United Kingdom';"),
]

def actual_ms(plan_text):
    """从 EXPLAIN ANALYZE 输出里取最大 actual time"""
    vals = []
    for m in re.finditer(r"actual time=([\d.]+)\.\.([\d.]+)", plan_text):
        vals.append(float(m.group(2)))
    return max(vals) if vals else None

print("\n=== 2. EXPLAIN ANALYZE 实测（单位 ms，取执行路径上的最大 actual time）===")
print(f"{'场景':<38}{'有索引':>12}{'无索引':>12}")
for name, tpl in CASES:
    # 先各跑一次预热
    q("EXPLAIN ANALYZE " + tpl.format(t="retail_clean"), show_err=False)
    q("EXPLAIN ANALYZE " + tpl.format(t="retail_clean_noidx"), show_err=False)
    p1 = q("EXPLAIN ANALYZE " + tpl.format(t="retail_clean"))
    p2 = q("EXPLAIN ANALYZE " + tpl.format(t="retail_clean_noidx"))
    a, b = actual_ms(p1), actual_ms(p2)
    fa = f"{a:.1f}" if a else "?"
    fb = f"{b:.1f}" if b else "?"
    print(f"{name:<38}{fa:>12}{fb:>12}")

print("\n=== 3. 完整计划对照（前两个场景）===")
for name, tpl in CASES[:2]:
    print(f"\n----- {name} -----")
    print("[有索引]", q("EXPLAIN ANALYZE " + tpl.format(t="retail_clean")).replace("\n", " | "))
    print("[无索引]", q("EXPLAIN ANALYZE " + tpl.format(t="retail_clean_noidx")).replace("\n", " | "))

print("\n=== 4. 清理 ===")
q("DROP TABLE retail_clean_noidx;")
print("剩余表:", q("SHOW TABLES;").replace("\n", ", "))
