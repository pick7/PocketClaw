#!/usr/bin/env bash
# ============================================================
# encrypt-secrets.sh  —— 加密 .env 文件 (AES-256-CBC)
# 用法: bash scripts/encrypt-secrets.sh
#   密码仅通过交互式输入，不接受命令行参数（避免 ps aux 泄露）
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="$PROJECT_DIR/.env"
ENC_FILE="$PROJECT_DIR/secrets/.env.encrypted"
SECRETS_DIR="$PROJECT_DIR/secrets"

# ── 无论正常退出还是异常退出，都清理密码变量 ──
trap 'unset MASTER_PASS MASTER_PASS_CONFIRM 2>/dev/null' EXIT

# --------------- 检查依赖 ---------------
if ! command -v openssl &>/dev/null; then
    red "[错误] 未找到 openssl, 请先安装 OpenSSL."
    exit 1
fi

# --------------- 检查 .env 是否存在 ---------------
if [ ! -f "$ENV_FILE" ]; then
    red "[错误] 未找到 .env 文件: $ENV_FILE"
    echo "请先运行 setup-env 脚本创建 .env, 或手动从 .env.example 复制."
    exit 1
fi

# --------------- 获取密码（仅交互式，不接受命令行参数） ---------------
if [ $# -ge 1 ]; then
    yellow "[警告] 不再支持通过命令行参数传入密码（安全风险: 密码会显示在进程列表中）"
    yellow "       密码将通过交互式输入"
fi

echo ""
yellow "=== PocketClaw .env 加密工具 ==="
echo ""

while true; do
    read -rsp "请输入加密密码 (Master Password): " MASTER_PASS
    echo ""

    if [ -z "$MASTER_PASS" ]; then
        red "[错误] 密码不能为空, 请重新输入."
        echo ""
        continue
    fi

    read -rsp "请再次确认密码: " MASTER_PASS_CONFIRM
    echo ""

    if [ "$MASTER_PASS" != "$MASTER_PASS_CONFIRM" ]; then
        red "[错误] 两次密码不一致, 请重新输入."
        echo ""
        unset MASTER_PASS MASTER_PASS_CONFIRM 2>/dev/null
        continue
    fi

    break
done

# --------------- 确保 secrets 目录存在 ---------------
mkdir -p "$SECRETS_DIR"

# --------------- 执行加密 ---------------
echo ""
yellow "[信息] 正在加密 .env → secrets/.env.encrypted ..."

if encrypt_env_file "$ENV_FILE" "$ENC_FILE" "$MASTER_PASS"; then
    # 验证: 用同一密码试解密, 确保密文正确
    if decrypt_env_file "$ENC_FILE" "/dev/stdout" "$MASTER_PASS" | diff -q - "$ENV_FILE" &>/dev/null; then
        green "[OK] 加密成功! (已验证密文完整性)"
    else
        red "[错误] 加密验证失败! 密文可能损坏, 请重试."
        rm -f "$ENC_FILE"
        exit 1
    fi
    echo "  加密文件: $ENC_FILE"
    echo ""
    yellow "[建议] 加密完成后, 建议删除明文 .env 文件以提高安全性:"
    echo "  rm \"$ENV_FILE\""
    echo ""
    yellow "[重要] 请牢记您的 Master Password, 丢失将无法恢复!"
else
    red "[错误] 加密失败, 请检查 OpenSSL 版本."
    exit 1
fi
