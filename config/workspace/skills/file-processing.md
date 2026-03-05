# Skill: 文件处理

## 描述
读取和处理用户上传的 Word、PDF、Excel 文件。容器内已安装 `python-docx`、`pdfplumber`、`openpyxl`、`xlrd`、`antiword`。

### 支持格式
| 格式 | 读取 | 创建 | 库/工具 |
|------|------|------|----------|
| .docx | ✅ | ✅ | python-docx |
| .doc | ✅ | ❌ | antiword |
| .xlsx | ✅ | ✅ | openpyxl |
| .xls | ✅ | ❌ | xlrd |
| .pdf | ✅ | ❌ | pdfplumber |
| .pptx | ❌ | ✅ | python-pptx（见 skills/ppt-generator.md）|
| .csv | ✅ | ✅ | pandas（见 skills/data-analysis.md）|
| 图片 | ✅ | ✅ | Pillow（见 skills/image-tools.md）|

## 前提
- 用户通过聊天界面上传文件（OpenClaw 会将文件保存到 workspace 目录）
- 处理完成后保持原文件不变，输出结果到新文件或直接回复

## 操作

### 读取 PDF
当用户说"帮我看看这个 PDF"、"总结这份 PDF"、"PDF 里写了什么"：

```python
import pdfplumber

with pdfplumber.open("workspace/上传的文件.pdf") as pdf:
    text = ""
    for page in pdf.pages:
        text += page.extract_text() or ""
    # 也可提取表格
    # tables = page.extract_tables()
```

### 读取 Word (.docx)
当用户说“帮我看看这个 Word”、“读一下这个 docx”：

```python
from docx import Document

doc = Document("workspace/上传的文件.docx")
text = "\n".join([p.text for p in doc.paragraphs])
# 也可读取表格
# for table in doc.tables: ...
```

### 读取旧版 Word (.doc)
当用户上传 `.doc` 格式文件时，用 antiword 命令行工具：

```bash
antiword workspace/上传的文件.doc
```

如果需要在 Python 中处理：
```python
import subprocess
result = subprocess.run(["antiword", "workspace/上传的文件.doc"], capture_output=True, text=True)
text = result.stdout
```

### 读取 Excel (.xlsx)
当用户说“帮我看看这个 Excel”、“分析这个表格”：

```python
import openpyxl

wb = openpyxl.load_workbook("workspace/上传的文件.xlsx")
ws = wb.active
data = []
for row in ws.iter_rows(values_only=True):
    data.append(list(row))
```

### 读取旧版 Excel (.xls)
当用户上传 `.xls` 格式文件时：

```python
import xlrd

wb = xlrd.open_workbook("workspace/上传的文件.xls")
ws = wb.sheet_by_index(0)
data = []
for row_idx in range(ws.nrows):
    data.append(ws.row_values(row_idx))
```

### 创建 Word 文档
当用户说"帮我写个 Word"、"生成一份文档"：

```python
from docx import Document

doc = Document()
doc.add_heading("标题", level=1)
doc.add_paragraph("内容...")
doc.save("workspace/输出文件.docx")
```

### 创建 Excel 表格
当用户说"帮我做个表格"、"生成 Excel"：

```python
import openpyxl

wb = openpyxl.Workbook()
ws = wb.active
ws.title = "数据"
ws.append(["列1", "列2", "列3"])
ws.append(["数据1", "数据2", "数据3"])
wb.save("workspace/输出文件.xlsx")
```

## 注意事项
- 文件路径在容器内以 `workspace/` 开头
- 处理大文件时分页/分块处理，避免内存溢出
- PDF 如果是扫描件（图片），`pdfplumber` 无法提取文字，需告知用户
- 输出文件保存到 `workspace/` 目录，用户可通过聊天界面下载
