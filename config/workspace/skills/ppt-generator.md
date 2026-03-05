# Skill: PPT 生成

## 描述
使用 python-pptx 库为用户生成 PowerPoint 演示文稿。容器内已安装 `python-pptx`。

## 操作

### 根据大纲生成 PPT
当用户说"帮我做个 PPT"、"生成演示文稿"、"做个幻灯片"：

1. 先和用户确认主题和大纲（如果用户没给大纲，帮忙拟一个让用户确认）
2. 生成 PPT 后保存到 workspace 目录

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN

prs = Presentation()

# 封面页
slide = prs.slides.add_slide(prs.slide_layouts[0])  # 标题布局
slide.shapes.title.text = "演示标题"
slide.placeholders[1].text = "副标题 / 日期"

# 内容页（标题+正文）
slide = prs.slides.add_slide(prs.slide_layouts[1])  # 标题+正文布局
slide.shapes.title.text = "第一章 概述"
body = slide.placeholders[1]
tf = body.text_frame
tf.text = "要点一"
tf.add_paragraph().text = "要点二"
tf.add_paragraph().text = "要点三"

# 保存
prs.save("workspace/演示文稿.pptx")
```

### 带图片的 PPT
当用户说"PPT 里加张图"：

```python
from pptx import Presentation
from pptx.util import Inches

prs = Presentation()
slide = prs.slides.add_slide(prs.slide_layouts[5])  # 空白布局
slide.shapes.add_picture("workspace/图片.jpg", Inches(1), Inches(1), width=Inches(5))
prs.save("workspace/带图PPT.pptx")
```

### 常用布局索引
| 索引 | 布局名称 | 用途 |
|------|----------|------|
| 0 | 标题幻灯片 | 封面页 |
| 1 | 标题和内容 | 常规内容页 |
| 2 | 节标题 | 章节分隔页 |
| 5 | 空白 | 自由排版/放图片 |
| 6 | 仅标题 | 标题+自定义内容 |

### PPT 字体设置
```python
from pptx.util import Pt

for paragraph in tf.paragraphs:
    for run in paragraph.runs:
        run.font.size = Pt(18)
        run.font.name = "微软雅黑"  # 或 "Noto Sans CJK SC"
```

## 注意事项
- 默认使用 python-pptx 内置模板，样式简洁
- 中文字体用 "Noto Sans CJK SC"（容器已安装）
- 生成后告知用户文件位置，用户可下载后用 PowerPoint/WPS 打开美化
- 建议先和用户确认大纲再生成，避免返工
- 输出到 `workspace/` 目录
