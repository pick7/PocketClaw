#!/usr/bin/env bash
# ============================================================
# stop.sh  —— PocketClaw 停止器 (macOS/Linux)
# 停止容器 → 安全擦除 .env → 关闭 Docker Desktop → 可安全拔U盘
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================"
echo "  PocketClaw 停止中..."
echo "============================================"
echo ""

# 1. 停止容器
run_compose -f "$PROJECT_DIR/docker-compose.yml" down 2>/dev/null || true

# 2. 安全擦除明文 .env
if [ -f "$PROJECT_DIR/.env" ]; then
    secure_wipe "$PROJECT_DIR/.env"
    echo "[OK] 明文配置已安全擦除"
fi

# 3. 关闭 Docker Desktop（释放U盘文件锁定）
echo ""
echo "[信息] 正在关闭 Docker Desktop（以便安全弹出U盘）..."
if [[ "$(uname)" == "Darwin" ]]; then
    osascript -e 'quit app "Docker"' 2>/dev/null || true
else
    echo "[信息] Linux 系统不自动停止 Docker 服务"
fi

sleep 2

# 4. 清理 macOS 在 NTFS U盘上生成的隐藏文件（防止 Windows 端显示）
if [[ "$(uname)" == "Darwin" ]]; then
    USB_ROOT=""
    # 检测 PROJECT_DIR 是否在外部卷上
    case "$PROJECT_DIR" in
        /Volumes/*)
            USB_ROOT=$(echo "$PROJECT_DIR" | sed 's|^\(/Volumes/[^/]*\).*|\1|')
            ;;
    esac
    if [ -n "$USB_ROOT" ]; then
        echo "[信息] 正在清理 macOS 隐藏文件..."
        find "$USB_ROOT" -maxdepth 1 -name ".DS_Store" -delete 2>/dev/null || true
        find "$USB_ROOT" -name ".DS_Store" -delete 2>/dev/null || true
        find "$USB_ROOT" -name "._*" -delete 2>/dev/null || true
        rm -rf "$USB_ROOT/.fseventsd" 2>/dev/null || true
        rm -rf "$USB_ROOT/.Spotlight-V100" 2>/dev/null || true
        rm -rf "$USB_ROOT/.Trashes" 2>/dev/null || true
        rm -f "$USB_ROOT/.metadata_never_index" 2>/dev/null || true
        echo "[OK] macOS 隐藏文件已清理"
    fi
fi

echo ""
echo "[OK] PocketClaw 已停止"
echo ""
echo "============================================"
echo "  现在可以安全弹出U盘"
echo "  macOS: 右键推出 / 拖到废纸篓"
echo "  Linux: umount /path/to/usb"
echo "============================================"
