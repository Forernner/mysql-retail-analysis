# -*- coding: utf-8 -*-
"""实测：retail_clean 有索引 vs 无索引，同一批查询差多少。测完删掉临时表。"""
import subprocess, time, statistics
from pathlib import Path

MYSQL = r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
BASE = [MYSQL, "-h127.0.0.1", "-uroot", "-p<YOUR_PASSWORD>",
        "--default-character-set=utf8mb4", "-B", "-N", "practice"]

def q(sql, timeout=600):
    r = subprocess.run(BASE + ["-e", sql], capture_output=True, text=True,
                       encoding="utf-8", errors="ignore", timeout=timeout)
    out = "\n".join(l for l in r.stdout.splitlines() if "Warning" not in l)
    return out.strip(), r.stderr.strip()

def timed(sql, n=5):
    ts = []
    for _ in range(n):
        t0 = time.perf_counter()
        q(sql)
        ts.append((time.perf_counter() - t0) * 1000)
    return min(ts), statistics.median(ts)

print("=== 准备无索引副本 ===")
q("DROP TABLE IF EXISTS retail_clean_noidx;")
print(q("CREATE TABLE retail_clean_noidx AS SELECT * FROM retail_clean;")[0] or "(CTAS 完成)")
print("副本行数:", q("SELECT COUNT(*) FROM retail_clean_noidx;")[0])
print("副本索引（应为空）:", q("SHOW INDEX FROM retail_clean_noidx;")[0] or "（无索引 ✓）")
print("原表索引:", q("SHOW INDEX FROM retail_clean;")[0].replace("\n", " | ")[:200])

TESTS = [
    ("① 按客户查", "SELECT COUNT(*), ROUND(SUM(amount),2) FROM retail_clean WHERE customer_id = 16446;",
                   "SELECT COUNT(*), ROUND(SUM(amount),2) FROM retail_clean_noidx WHERE customer_id = 16446;"),
    ("② 按月份查", "SELECT COUNT(*), ROUND(SUM(amount),2) FROM retail_clean WHERE invoice_date >= '2011-12-01' AND invoice_date < '2012-01-01';",
                   "SELECT COUNT(*), ROUND(SUM(amount),2) FROM retail_clean_noidx WHERE invoice_date >= '2011-12-01' AND invoice_date < '2012-01-01';"),
    ("③ 按国家查（没索引）", "SELECT COUNT(*) FROM retail_clean WHERE country = 'United Kingdom';",
                             "SELECT COUNT(*) FROM retail_clean_noidx WHERE country = 'United Kingdom';"),
]

print("\n=== 计时对比（各跑 5 次，取最小值）===")
print(f"{'场景':<24}{'有索引 ms':>12}{'无索引 ms':>12}{'倍数':>10}")
for name, s_idx, s_no in TESTS:
    a, _ = timed(s_idx)
    b, _ = timed(s_no)
    ratio = f"{b/a:.0f}×" if a > 0 else "-"
    print(f"{name:<24}{a:>12.1f}{b:>12.1f}{ratio:>10}")

print("\n=== EXPLAIN：看有没有用上索引 ===")
for name, s_idx, s_no in TESTS[:2]:
    print(f"\n[{name}] 有索引")
    print(q("EXPLAIN " + s_idx)[0])
    print(f"[{name}] 无索引")
    print(q("EXPLAIN " + s_no)[0])

print("\n=== 清理临时表 ===")
print(q("DROP TABLE retail_clean_noidx;")[0] or "(已删除 retail_clean_noidx)")
print("剩余表:", q("SHOW TABLES;")[0].replace("\n", ", "))
