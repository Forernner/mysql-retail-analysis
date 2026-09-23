# -*- coding: utf-8 -*-
"""紧急修复：retail_clean 被重建但没插数据（0 行）。
   从 SQL_00 里【原样抽取】第 2 段执行，避免手写导致与脚本不一致。"""
import subprocess, re
from pathlib import Path

MYSQL = r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
BASE = [MYSQL, "-h127.0.0.1", "-uroot", "-p<YOUR_PASSWORD>",
        "--default-character-set=utf8mb4", "-B", "-N", "practice"]
SQL00 = Path(r"G:\workbuddy\2026-09-20-17-28-49\output\SQL_00_两表合并与建表_王自强.sql")

def run(sql, timeout=2400):
    r = subprocess.run(BASE, input=sql, capture_output=True, text=True,
                       encoding="utf-8", errors="ignore", timeout=timeout)
    errs = [l for l in r.stderr.splitlines() if "Warning" not in l and l.strip()]
    return r.stdout.strip(), errs

s = SQL00.read_text(encoding="utf-8")
i = s.find("第 2 段 · 建 retail_clean")
j = s.find("第 3 段 · 总校验")
if i < 0 or j < 0:
    raise SystemExit(f"!! 找不到第 2 段边界 i={i} j={j}")
# 往前退到该段注释块开头
i = s.rfind("/*", 0, i)
seg = s[i:j]
# 去掉尾部未闭合的注释开头
seg = seg.rstrip()
if seg.endswith("/*"):
    seg = seg[:-2]
print("=== 抽取到的第 2 段（前 160 字）===")
print(seg[:160])
print("...共", len(seg), "字符\n")

out, errs = run(seg)
print("=== 执行结果 ===")
print("stdout:", out[:300] if out else "(空)")
print("错误:", errs if errs else "（无）")

print("\n=== 校验 ===")
def q(sql):
    r = subprocess.run(BASE + ["-e", sql], capture_output=True, text=True,
                       encoding="utf-8", errors="ignore", timeout=900)
    return r.stdout.strip()
print("retail_clean 行数 :", q("SELECT COUNT(*) FROM retail_clean;"), "（应为 779425）")
print("总金额           :", q("SELECT ROUND(SUM(amount),2) FROM retail_clean;"), "（应为 17374804.27）")
print("唯一发票/商品/客户 :", q("SELECT COUNT(DISTINCT invoice), COUNT(DISTINCT stock_code), COUNT(DISTINCT customer_id) FROM retail_clean;").replace("\t", " / "), "（应为 36969 / 4631 / 5878）")
print("时间范围         :", q("SELECT CONCAT(MIN(invoice_date),' ~ ',MAX(invoice_date)) FROM retail_clean;"))
print("索引             :", q("SHOW INDEX FROM retail_clean;").replace("\n", " | ")[:150])
