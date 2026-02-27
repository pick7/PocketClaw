#!/usr/bin/env bash
# ============================================================
# create-update.sh  —— 生成更新包（维护者工具）
# 用法: bash scripts/create-update.sh
#
# 此脚本从当前项目目录（或本地备份目录）打包一个更新包，
# 发送给朋友后，朋友解压并双击 install-update.bat 即可一键安装。
#
# 更新包包含:
#   - _payload/        更新文件（不含用户私有数据）
#   - install-update.bat   Windows 安装器
#   - install-update.sh    macOS/Linux 安装器
#   - UPDATE_INFO.txt      更新说明
#
# 更新包 **不包含** 以下内容（保护朋友的个人数据）:
#   - secrets/              加密的密钥文件
#   - data/                 会话、日志、凭证
#   - .env                  明文配置
#   - openclaw-src/         PocketClaw 源码（朋友本地已有）
#   - config/workspace/     Agent 个性化配置（AGENTS.md, SOUL.md, skills/）
# ============================================================
set -euo pipefail

# ── 颜色 ──
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
cyan()  { printf "\033[36m%s\033[0m\n" "$*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── 检查 zip 命令 ──
if ! command -v zip &>/dev/null; then
    red "[错误] 未找到 zip 命令。"
    echo "  macOS: brew install zip (通常已自带)"
    echo "  Linux: sudo apt install zip"
    exit 1
fi

# ── 读取当前版本 ──
CUR_VERSION=$(cat "$PROJECT_DIR/VERSION" 2>/dev/null || echo "unknown")

echo ""
cyan "╔══════════════════════════════════════╗"
cyan "║   PocketClaw 更新包生成工具        ║"
cyan "╚══════════════════════════════════════╝"
echo ""
echo "  当前版本: v${CUR_VERSION}"
echo ""

# ── 输入新版本号 ──
read -rp "新版本号 (如 1.0.1, 留空使用当前版本 $CUR_VERSION): " NEW_VERSION
NEW_VERSION="${NEW_VERSION:-$CUR_VERSION}"

# ── 输入更新说明 ──
echo ""
echo "请输入更新说明（可多行，输入空行结束）:"
CHANGELOG=""
while IFS= read -r line; do
    [ -z "$line" ] && break
    CHANGELOG="${CHANGELOG}${line}\n"
done
if [ -z "$CHANGELOG" ]; then
    CHANGELOG="常规更新"
fi

# ── 创建临时目录 ──
TEMP_DIR=$(mktemp -d)
PKG_NAME="PocketClaw_Update_v${NEW_VERSION}"
PKG_DIR="$TEMP_DIR/$PKG_NAME"
PAYLOAD_DIR="$PKG_DIR/_payload"
mkdir -p "$PAYLOAD_DIR"

# ── 复制可更新文件到 _payload ──
yellow "[信息] 正在收集更新文件..."

rsync -a \
    --exclude='secrets/' \
    --exclude='data/' \
    --exclude='.env' \
    --exclude='openclaw-src/' \
    --exclude='config/workspace/' \
    --exclude='.DS_Store' \
    --exclude='Thumbs.db' \
    --exclude='*.zip' \
    --exclude='._*' \
    "$PROJECT_DIR/" "$PAYLOAD_DIR/"

# ── 更新 payload 中的 VERSION ──
echo "$NEW_VERSION" > "$PAYLOAD_DIR/VERSION"

# ── 复制安装器脚本到包根目录 ──
cp "$PROJECT_DIR/scripts/install-update.sh" "$PKG_DIR/install-update.sh"
cp "$PROJECT_DIR/scripts/install-update.bat" "$PKG_DIR/install-update.bat"
chmod +x "$PKG_DIR/install-update.sh"

# ── 生成 UPDATE_INFO.txt ──
cat > "$PKG_DIR/UPDATE_INFO.txt" << EOF
╔══════════════════════════════════════╗
║   PocketClaw 更新包               ║
╚══════════════════════════════════════╝

  版本:     v${NEW_VERSION}
  生成日期: $(date '+%Y-%m-%d %H:%M:%S')

─── 更新说明 ───
$(printf '%b' "$CHANGELOG")

─── 安装方法 ───
  Windows:     双击 install-update.bat
  macOS/Linux: bash install-update.sh

─── 注意事项 ───
  • 更新不会影响你的加密配置 (secrets/)
  • 更新不会影响你的会话数据 (data/)
  • 更新不会影响你的 Agent 人设 (config/workspace/)
  • 安装前会自动创建回滚备份
  • 如遇问题，可从 data/_rollback_vX.X.X/ 恢复

EOF

# ── 打包为 zip ──
OUTPUT_DIR="${OUTPUT_DIR:-$HOME}"
OUTPUT_FILE="$OUTPUT_DIR/${PKG_NAME}.zip"

yellow "[信息] 正在打包..."
cd "$TEMP_DIR"
zip -rq "$OUTPUT_FILE" "$PKG_NAME"

# ── 统计信息 ──
FILE_COUNT=$(find "$PAYLOAD_DIR" -type f | wc -l | tr -d ' ')
ZIP_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

# ── 清理临时目录 ──
rm -rf "$TEMP_DIR"

# ── 完成 ──
echo ""
green "╔══════════════════════════════════════╗"
green "║   [OK] 更新包生成完成!               ║"
green "╚══════════════════════════════════════╝"
echo ""
echo "  文件位置: $OUTPUT_FILE"
echo "  包含文件: ${FILE_COUNT} 个"
echo "  包大小:   ${ZIP_SIZE}"
echo ""
echo "  版本:     v${CUR_VERSION} → v${NEW_VERSION}"
echo ""
yellow "  下一步: 将 ${PKG_NAME}.zip 发送给朋友"
yellow "  朋友操作: 解压 → 双击 install-update.bat"
echo ""
