# Skill: 数据分析

## 描述
使用 pandas 和 matplotlib 分析数据、生成图表。容器内已安装 `pandas`、`matplotlib`、`openpyxl`。

## 操作

### 读取 CSV/Excel 数据
当用户说"帮我分析这个表格"、"看看这份数据"：

```python
import pandas as pd

# CSV
df = pd.read_csv("workspace/数据.csv")

# Excel
df = pd.read_excel("workspace/数据.xlsx")

# 快速概览
print(f"形状: {df.shape[0]}行 x {df.shape[1]}列")
print(f"列名: {list(df.columns)}")
print(df.describe())  # 数值统计
print(df.head(10))    # 前10行
```

### 数据筛选与统计
当用户说"筛选出XX"、"XX有多少"、"按XX分组统计"：

```python
import pandas as pd

df = pd.read_excel("workspace/数据.xlsx")

# 筛选
result = df[df["列名"] > 100]

# 分组统计
grouped = df.groupby("类别")["金额"].agg(["count", "sum", "mean"])

# 透视表
pivot = pd.pivot_table(df, values="金额", index="部门", columns="月份", aggfunc="sum")

# 排序
top10 = df.nlargest(10, "金额")
```

### 生成图表
当用户说"画个图"、"做个柱状图"、"趋势图"：

```python
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib

# 设置中文字体
matplotlib.rcParams["font.sans-serif"] = ["Noto Sans CJK SC"]
matplotlib.rcParams["axes.unicode_minus"] = False

df = pd.read_excel("workspace/数据.xlsx")

# 柱状图
fig, ax = plt.subplots(figsize=(10, 6))
df.groupby("类别")["金额"].sum().plot(kind="bar", ax=ax)
ax.set_title("各类别金额汇总")
ax.set_ylabel("金额")
plt.tight_layout()
fig.savefig("workspace/图表.png", dpi=150)
plt.close()
```

### 常用图表类型
| 类型 | plot kind | 场景 |
|------|-----------|------|
| 柱状图 | `bar` | 分类对比 |
| 折线图 | `line` | 趋势变化 |
| 饼图 | `pie` | 占比分布 |
| 散点图 | `scatter` | 相关性分析 |
| 水平柱状图 | `barh` | 类别名较长时 |

### 数据导出
当用户说"导出结果"、"保存为 Excel"：

```python
# 导出 Excel
result.to_excel("workspace/分析结果.xlsx", index=False)

# 导出 CSV
result.to_csv("workspace/分析结果.csv", index=False, encoding="utf-8-sig")
```

## 注意事项
- 中文图表必须设置 `rcParams["font.sans-serif"]`，否则显示方块
- 大数据集（>10万行）注意内存限制（2GB），可分块读取: `pd.read_csv(..., chunksize=10000)`
- 图表保存用 `dpi=150`，兼顾清晰度和文件大小
- 保存后用 `plt.close()` 释放内存
- 输出到 `workspace/` 目录
