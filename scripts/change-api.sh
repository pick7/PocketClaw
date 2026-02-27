#!/usr/bin/env bash
# ============================================================
# change-api.sh  —— 快速更换 GLM API Key (macOS/Linux)
# 自动解密 → 修改 → 重新加密 → 重启容器
# 用法: bash scripts/change-api.sh
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="$PROJECT_DIR/.env"
ENC_FILE="$PROJECT_DIR/secrets/.env.encrypted"
NEED_REENCRYPT=0
MASTER_PASS=""

trap 'unset MASTER_PASS 2>/dev/null' EXIT

echo ""
echo "======================================"
echo "   快速更换 GLM API Key"
echo "======================================"
echo ""

# ── 如果 .env 不存在，尝试解密 ──
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENC_FILE" ]; then
        echo "[信息] 正在解密 .env ..."
        read -s -p "  Master Password: " MASTER_PASS
        echo ""
        if [ -z "$MASTER_PASS" ]; then
            echo "[错误] 密码不能为空。"
            exit 1
        fi
        if ! printf '%s' "$MASTER_PASS" | openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 \
            -in "$ENC_FILE" -out "$ENV_FILE" -pass stdin 2>/dev/null; then
            echo "[错误] 解密失败，密码可能不正确。"
            rm -f "$ENV_FILE"
            exit 1
        fi
        NEED_REENCRYPT=1
        echo "[OK] 解密成功"
    else
        echo "[错误] 未找到 .env 或 .env.encrypted"
        echo "请先运行 setup-env.sh"
        exit 1
    fi
fi

# ── 读取当前 Key ──
CUR_KEY=$(grep -i "^ZHIPU_API_KEY=" "$ENV_FILE" 2>/dev/null | cut -d= -f2-)
echo ""
if [ -n "$CUR_KEY" ]; then
    echo "  当前 API Key: ${CUR_KEY:0:8}****"
fi
echo ""
echo "  获取新的 API Key: https://open.bigmodel.cn/usercenter/apikeys"
echo ""

read -p "新的 GLM API Key (留空保持不变): " NEW_KEY

if [ -z "$NEW_KEY" ]; then
    echo "  未修改。"
else
    echo ""
    echo "[信息] 正在更新 .env ..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^ZHIPU_API_KEY=.*|ZHIPU_API_KEY=$NEW_KEY|" "$ENV_FILE"
    else
        sed -i "s|^ZHIPU_API_KEY=.*|ZHIPU_API_KEY=$NEW_KEY|" "$ENV_FILE"
    fi
    echo "  [OK] GLM API Key 已更新"

    # ── 重新加密 ──
    if [ "$NEED_REENCRYPT" -eq 1 ]; then
        echo ""
        echo "[信息] 重新加密 .env ..."
        if printf '%s' "$MASTER_PASS" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
            -in "$ENV_FILE" -out "$ENC_FILE" -pass stdin 2>/dev/null; then
            echo "[OK] 已重新加密"
        else
            echo "[错误] 重新加密失败！明文 .env 已保留，请手动处理。"
        fi
    fi

    # ── 重启容器 ──
    echo ""
    read -p "是否重启 PocketClaw 使配置生效？(y/N): " RESTART
    if [[ "$RESTART" =~ ^[Yy]$ ]]; then
        echo "[信息] 重启容器..."
        run_compose -f "$PROJECT_DIR/docker-compose.yml" up -d --force-recreate
        echo "[OK] 重启完成"
    fi
fi

# ── 清理明文 ──
if [ "$NEED_REENCRYPT" -eq 1 ]; then
    secure_wipe "$ENV_FILE"
    echo "[安全] 已安全擦除明文 .env"
fi

echo ""
echo "[完成] API Key 更换完成！"
