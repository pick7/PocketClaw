@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM logs.bat  —— 查看 PocketClaw 容器日志 [Windows]
REM 用法: scripts\logs.bat [行数]
REM   默认显示最近 100 行, 可传参指定行数
REM ============================================================

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%.."

set "LINES=%~1"
if "!LINES!"=="" set "LINES=100"

echo.
echo ======================================
echo    PocketClaw 日志 (最近 !LINES! 行)
echo ======================================
echo.
echo  提示: 按 Ctrl+C 退出实时日志
echo.

REM 先检查容器是否在运行
docker compose ps -q 2>nul >nul
if errorlevel 1 (
    echo [警告] 容器未运行, 尝试显示历史日志...
    docker compose logs --tail=!LINES! 2>nul || docker-compose logs --tail=!LINES! 2>nul
) else (
    echo [选择查看模式]
    echo   [1] 查看最近日志 (静态)
    echo   [2] 实时跟踪日志 (follow)
    echo.
    set /p "MODE=请选择 (1/2): "
    
    if "!MODE!"=="2" (
        echo.
        echo  --- 实时日志 (Ctrl+C 退出) ---
        echo.
        docker compose logs -f --tail=!LINES! 2>nul || docker-compose logs -f --tail=!LINES! 2>nul
    ) else (
        echo.
        docker compose logs --tail=!LINES! 2>nul || docker-compose logs --tail=!LINES! 2>nul
    )
)

echo.
popd
pause
exit /b 0

