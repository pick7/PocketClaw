@echo off
setlocal EnableDelayedExpansion
title PocketClaw 停止

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."
set "PROJECT_DIR=%CD%"

echo ============================================
echo   PocketClaw 停止中...
echo ============================================
echo.

:: 停止容器（兼容 docker compose v1/v2）
docker compose -f "%PROJECT_DIR%\docker-compose.yml" down 2>nul || docker-compose -f "%PROJECT_DIR%\docker-compose.yml" down 2>nul

if !ERRORLEVEL! neq 0 (
    echo [警告] 容器停止出现问题，可能已经停止。
)

:: 安全擦除明文 .env（覆写后删除，ExFAT 最佳努力）
if exist "%PROJECT_DIR%\.env" (
    powershell -NoProfile -Command "$f='%PROJECT_DIR%\.env'; $s=(Get-Item $f).Length; $r=New-Object byte[] $s; [Security.Cryptography.RandomNumberGenerator]::Fill($r); [IO.File]::WriteAllBytes($f,$r)" 2>nul
    del /q "%PROJECT_DIR%\.env"
    echo [OK] 明文配置已安全擦除
)

echo.
echo [OK] PocketClaw 已停止
echo.
echo ============================================
echo   现在可以安全弹出U盘
echo   Windows: 右键托盘安全删除硬件
echo   macOS:   右键推出磁盘
echo ============================================
echo.
pause
