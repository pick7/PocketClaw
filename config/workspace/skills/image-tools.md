# Skill: 图片处理

## 描述
使用 Pillow 库处理用户上传的图片。容器内已安装 `Pillow`。

### 支持格式
PNG、JPEG、GIF、BMP、WEBP、TIFF

## 前提
- 用户通过聊天界面上传图片到 workspace 目录
- 处理后输出到新文件，保持原文件不变

## 操作

### 调整尺寸
当用户说"帮我缩小这张图"、"把图片调整到 800x600"：

```python
from PIL import Image

img = Image.open("workspace/上传的图片.jpg")
img_resized = img.resize((800, 600), Image.LANCZOS)
img_resized.save("workspace/输出图片.jpg")
```

等比缩放：
```python
img.thumbnail((800, 800), Image.LANCZOS)
img.save("workspace/缩略图.jpg")
```

### 格式转换
当用户说"转成 PNG"、"把 JPG 转成 WEBP"：

```python
from PIL import Image

img = Image.open("workspace/原图.jpg")
img.save("workspace/转换后.png")
# WEBP: img.save("workspace/转换后.webp", quality=85)
```

### 添加文字水印
当用户说"加水印"、"加上我的名字"：

```python
from PIL import Image, ImageDraw, ImageFont

img = Image.open("workspace/原图.jpg")
draw = ImageDraw.Draw(img)
# 使用系统 CJK 字体（容器已安装）
try:
    font = ImageFont.truetype("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc", 36)
except:
    font = ImageFont.load_default()
draw.text((10, 10), "水印文字", fill=(255, 255, 255, 128), font=font)
img.save("workspace/加水印.jpg")
```

### 裁剪
当用户说"裁剪图片"、"截取中间部分"：

```python
from PIL import Image

img = Image.open("workspace/原图.jpg")
# 裁剪 (left, upper, right, lower)
cropped = img.crop((100, 100, 500, 400))
cropped.save("workspace/裁剪后.jpg")
```

### 拼图
当用户说"把这几张图拼在一起"、"横向拼接"：

```python
from PIL import Image

imgs = [Image.open(f"workspace/图{i}.jpg") for i in range(1, 4)]
# 横向拼接
total_w = sum(img.width for img in imgs)
max_h = max(img.height for img in imgs)
result = Image.new("RGB", (total_w, max_h), (255, 255, 255))
x = 0
for img in imgs:
    result.paste(img, (x, 0))
    x += img.width
result.save("workspace/拼图.jpg")
```

### 获取图片信息
当用户说"这张图多大"、"图片尺寸"：

```python
from PIL import Image
import os

img = Image.open("workspace/图片.jpg")
size_kb = os.path.getsize("workspace/图片.jpg") / 1024
print(f"尺寸: {img.width}x{img.height}, 格式: {img.format}, 文件大小: {size_kb:.1f}KB")
```

## 注意事项
- 处理大图片时注意内存（2GB 限制），超大图片先缩小再处理
- JPEG 不支持透明通道，转 PNG/WEBP 才行
- 保存 JPEG 时用 `quality=85` 平衡质量和体积
- 输出到 `workspace/` 目录，用户可下载
