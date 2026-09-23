# -*- coding: utf-8 -*-
"""① 重建 retail_clean（消除重复插入）② 用干净数据重算 Q6 的非商品码数字"""
import subprocess, re
from pathlib import Path

MYSQL = r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
BASE = [MYSQL, "-h127.0.0.1", "-uroot", "-p<YOUR_PASSWORD>",
        "--default-character-set=utf8mb4", "-B", "-N", "practice"]
SQL00 = Path(r"G:\workbuddy\2026-09-20-17-28-49\output\SQL_00_两表合并与建表_王自强.sql")

def run(sql, timeout=2400):
    r = subprocess.run(BASE, input=sql, capture_output=True, text=True,
                       encoding="utf-8", errors="ignore", timeout=timeout)
    return r.stdout.strip(), [l for l in r.stderr.splitlines() if "Warning" not in l and l.strip()]

def q(sql, timeout=1200):
    r = subprocess.run(BASE + ["-e", sql], capture_output=True, text=True,
                       encoding="utf-8", errors="ignore", timeout=timeout)
    return r.stdout.strip()

print("=== 修复前 ===")
print("retail_clean:", q("SELECT COUNT(*) FROM retail_clean;"), "行 /",
      q("SELECT ROUND(SUM(amount),2) FROM retail_clean;"), "元")

# 从 SQL_00 原样抽取第 2 段重跑
s = SQL00.read_text(encoding="utf-8")
i = s.find("第 2 段 · 建 retail_clean"); j = s.find("第 3 段 · 总校验")
seg = s[s.rfind("/*", 0, i):j].rstrip()
if seg.endswith("/*"): seg = seg[:-2]
out, errs = run(seg)
print("\n=== 重跑第 2 段 ===")
print("错误:", errs if errs else "（无）")

print("\n=== 修复后校验 ===")
for label, sql in [
    ("行数", "SELECT COUNT(*) FROM retail_clean;"),
    ("总金额", "SELECT ROUND(SUM(amount),2) FROM retail_clean;"),
    ("唯一发票/商品/客户", "SELECT CONCAT(COUNT(DISTINCT invoice),' / ',COUNT(DISTINCT stock_code),' / ',COUNT(DISTINCT customer_id)) FROM retail_clean;"),
    ("时间范围", "SELECT CONCAT(MIN(invoice_date),' ~ ',MAX(invoice_date)) FROM retail_clean;"),
]:
    print(f"  {label}: {q(sql)}")

print("\n=== 品牌榜 Top10 复核（应 22423 = 277,656.25）===")
print(q("SELECT stock_code, ROUND(SUM(amount),2) FROM retail_clean WHERE stock_code IN ('22423','M','POST') GROUP BY stock_code;"))

print("\n=== 重算 Q6：非商品码（干净数据）===")
COND = ("stock_code IN ('POST','DOT','M','C2','D','S','B','BANK CHARGES','ADJUST','ADJUST2',"
        "'AMAZONFEE','CRUK','PADS','TEST001','TEST002','SP1002') "
        "OR stock_code LIKE 'DCGS%' OR stock_code LIKE 'gift\\_%'")
print("[raw 侧]")
print(q(f"SELECT COUNT(*), ROUND(SUM(quantity*unit_price),2) FROM retail_raw WHERE {COND};"))
print("[clean 侧：行数 / 编码数 / 金额 / 占比%]")
print(q(f"SELECT COUNT(*), COUNT(DISTINCT stock_code), ROUND(SUM(amount),2), "
        f"ROUND(SUM(amount)*100.0/(SELECT SUM(amount) FROM retail_clean),3) "
        f"FROM retail_clean WHERE {COND};"))
print("[clean 侧逐码]")
print(q(f"SELECT stock_code, COUNT(*), ROUND(SUM(amount),2) FROM retail_clean WHERE {COND} "
        f"GROUP BY stock_code ORDER BY SUM(amount) DESC;"))
print("[剔非商品码后的金额榜 Top10]")
print(q(f"SELECT stock_code, ROUND(SUM(amount),2) FROM retail_clean WHERE NOT ({COND}) "
        f"GROUP BY stock_code ORDER BY SUM(amount) DESC LIMIT 10;"))
