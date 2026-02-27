#!/usr/bin/env bash
# ============================================================
# stop.sh  —— PocketClaw 停止器 (macOS/Linux)
# 用法: bash scripts/stop.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "PocketClaw 停止中..."
echo ""

# 停止容器
run_compose -f "$PROJECT_DIR/docker-compose.yml" down

# 安全擦除明文 .env
if [ -f "$PROJECT_DIR/.env" ]; then
    secure_wipe "$PROJECT_DIR/.env"
    echo "[OK] 明文配置已安全擦除"
fi

echo ""
echo "[OK] PocketClaw 已停止"
echo "     现在可以安全弹出U盘"
