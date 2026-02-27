#!/usr/bin/env bash
# ============================================================
# PocketClaw 公共函数库
# 用法: source "$(dirname "$0")/scripts/_common.sh"
#       或 source "$(dirname "$0")/_common.sh"
# ============================================================

# ── Docker Compose v1/v2 兼容封装 ──
# 用法: run_compose up -d --build
#       run_compose down
run_compose() {
    if docker compose version &>/dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

# ── 安全擦除文件（覆写 + 删除） ──
# 用法: secure_wipe "/path/to/file"
secure_wipe() {
    local file="$1"
    if [ -f "$file" ]; then
        local size
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        if [ "$size" -gt 0 ] 2>/dev/null; then
            dd if=/dev/urandom of="$file" bs=1 count="$size" conv=notrunc 2>/dev/null
        fi
        rm -f "$file"
    fi
}

# ── 项目目录检测 ──
# 用法: detect_project_dir
# 设置 PROJECT_DIR 变量
detect_project_dir() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
    # 如果在 scripts/ 子目录中，上移一级
    if [ "$(basename "$script_dir")" = "scripts" ]; then
        PROJECT_DIR="$(dirname "$script_dir")"
    else
        PROJECT_DIR="$script_dir"
    fi
    export PROJECT_DIR
}
