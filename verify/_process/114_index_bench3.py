# -*- coding: utf-8 -*-
"""索引实测（表已有数据）：EXPLAIN ANALYZE 读数据库自报执行时间 + 索引占用空间"""
import subprocess, re
MYSQL = r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
BASE = [MYSQL, "-h127.0.0.1", "-uroot", "-p<YOUR_PASSWORD>",
        "--default-character-set=utf8mb4", "-B", "-N", "practice"]

def q(sql, timeout=1800, err=True):
    r = subprocess.run(BASE + ["-e", sql], capture_output=True, text=True,
                       encoding="utf-8", errors="ignore", timeout=timeout)
    if err and r.stderr.strip():
        for l in r.stderr.splitlines():
            if "Warning" not in l and l.strip():
                print("   [err]", l)
    return r.stdout.strip()

print("=== 1. 建无索引副本 ===")
q("DROP TABLE IF EXISTS retail_clean_noidx;")
q("CREATE TABLE retail_clean_noidx LIKE retail_clean;")
q("ALTER TABLE retail_clean_noidx DROP INDEX ix_date, DROP INDEX ix_cust;")
q("INSERT INTO retail_clean_noidx SELECT * FROM retail_clean;")
print("原表行数:", q("SELECT COUNT(*) FROM retail_clean;"))
print("副本行数:", q("SELECT COUNT(*) FROM retail_clean_noidx;"))

CASES = [
    ("① 查单个客户（ix_cust）",
     "SELECT COUNT(*) c, ROUND(SUM(amount),2) s FROM {t} WHERE customer_id = 16446;"),
    ("② 查一个月的流水（ix_date）",
     "SELECT COUNT(*) c, ROUND(SUM(amount),2) s FROM {t} WHERE invoice_date >= '2011-12-01' AND invoice_date < '2012-01-01';"),
    ("③ 按国家查（两表都无索引，对照）",
     "SELECT COUNT(*) c FROM {t} WHERE country = 'United Kingdom';"),
]

def ms(plan):
    v = [float(m.group(2)) for m in re.finditer(r"actual time=([\d.]+)\.\.([\d.]+)", plan)]
    return max(v) if v else None

def best(tpl, t, n=3):
    vals = []
    for _ in range(n):
        p = q("EXPLAIN ANALYZE " + tpl.format(t=t), err=False)
        m = ms(p)
        if m is not None:
            vals.append(m)
    return min(vals) if vals else None, p

print("\n=== 2. 实测执行时间（ms，跑 3 次取最快）===")
print(f"{'场景':<36}{'有索引':>10}{'无索引':>10}{'倍数':>9}")
results = []
for name, tpl in CASES:
    a, _ = best(tpl, "retail_clean")
    b, pb = best(tpl, "retail_clean_noidx")
    ratio = f"{b/a:.0f}×" if a and b and a > 0 else "-"
    results.append((name, a, b, ratio))
    print(f"{name:<36}{a:>10.2f}{b:>10.2f}{ratio:>9}")

print("\n=== 3. 执行计划关键行 ===")
for name, tpl in CASES[:2]:
    p1 = q("EXPLAIN ANALYZE " + tpl.format(t="retail_clean"), err=False)
    p2 = q("EXPLAIN ANALYZE " + tpl.format(t="retail_clean_noidx"), err=False)
    def key(p):
        for pat in [r"Index lookup on \w+ using (\w+)", r"Index range scan on \w+ using (\w+)",
                    r"Table scan on (\w+)"]:
            m = re.search(pat, p)
            if m:
                return m.group(0)
        return "?"
    print(f"\n{name}")
    print("   有索引:", key(p1))
    print("   无索引:", key(p2))

print("\n=== 4. 索引的代价：占用空间 ===")
print("表 /          数据大小 /   索引大小")
for t in ["retail_clean", "retail_clean_noidx"]:
    r = q(f"SELECT table_name, ROUND(data_length/1048576,1), ROUND(index_length/1048576,1) FROM information_schema.tables WHERE table_schema='practice' AND table_name='{t}';")
    print("  ", r.replace("\t", "  /  "), "MB")

print("\n=== 5. 清理 ===")
q("DROP TABLE retail_clean_noidx;")
print("剩余表:", q("SHOW TABLES;").replace("\n", ", "))
print("retail_clean 行数复核:", q("SELECT COUNT(*) FROM retail_clean;"))
