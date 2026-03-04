#!/usr/bin/env bash
# ============================================================
# decrypt-secrets.sh  —— 解密 .env.encrypted → .env
# 用法: bash scripts/decrypt-secrets.sh
#   密码仅通过交互式输入，不接受命令行参数（避免 ps aux 泄露）
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="$PROJECT_DIR/.env"
ENC_FILE="$PROJECT_DIR/secrets/.env.encrypted"

# ── 无论正常退出还是异常退出，都清理密码变量 ──
trap 'unset MASTER_PASS 2>/dev/null' EXIT

# --------------- 检查依赖 ---------------
if ! command -v openssl &>/dev/null; then
    red "[错误] 未找到 openssl."
    exit 1
fi

# --------------- 检查加密文件 ---------------
if [ ! -f "$ENC_FILE" ]; then
    red "[错误] 未找到加密文件: $ENC_FILE"
    echo "请先运行 encrypt-secrets.sh 进行加密."
    exit 1
fi

# --------------- 获取密码（仅交互式，不接受命令行参数） ---------------
if [ $# -ge 1 ]; then
    yellow "[警告] 不再支持通过命令行参数传入密码（安全风险: 密码会显示在进程列表中）"
    yellow "       密码将通过交互式输入"
fi

echo ""
yellow "=== PocketClaw .env 解密工具 ==="
echo ""
read -rsp "请输入 Master Password: " MASTER_PASS
echo ""

if [ -z "$MASTER_PASS" ]; then
    red "[错误] 密码不能为空."
    exit 1
fi

# --------------- 如果 .env 已存在, 提示覆盖 ---------------
if [ -f "$ENV_FILE" ]; then
    yellow "[警告] .env 文件已存在, 解密将覆盖现有文件."
    read -rp "是否继续? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "已取消."
        exit 0
    fi
fi

# --------------- 执行解密 ---------------
yellow "[信息] 正在解密 secrets/.env.encrypted → .env ..."

if decrypt_env_file "$ENC_FILE" "$ENV_FILE" "$MASTER_PASS"; then
    green "[OK] 解密成功!"
    echo "  .env 文件已还原: $ENV_FILE"
    echo ""
    yellow "[安全提示] 使用完毕后, 建议删除明文 .env:"
    echo "  rm \"$ENV_FILE\""
else
    red "[错误] 解密失败, 密码可能不正确."
    rm -f "$ENV_FILE" 2>/dev/null
    exit 1
fi
