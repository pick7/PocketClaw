@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM status.bat  —— 查看 PocketClaw 运行状态 [Windows]
REM 用法: scripts\status.bat
REM ============================================================

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%.."
set "PROJECT_DIR=%CD%"

echo.
echo ======================================
echo    PocketClaw 运行状态
echo ======================================
echo.

REM --------------- Docker 状态 ---------------
echo [Docker 环境]
where docker >nul 2>&1
if errorlevel 1 (
    echo   Docker: 未安装
    goto :config_check
)

docker info >nul 2>&1
if errorlevel 1 (
    echo   Docker: 已安装但未运行
    goto :config_check
) else (
    echo   Docker: 运行中
)

echo.
echo [容器状态]
docker compose ps 2>nul || docker-compose ps 2>nul
if errorlevel 1 (
    echo   (无法获取容器状态)
)

echo.
echo [资源使用]
docker compose ps -q 2>nul >nul
if not errorlevel 1 (
    for /f "tokens=*" %%i in ('docker compose ps -q 2^>nul') do (
        if not "%%i"=="" (
            docker stats --no-stream --format "  CPU: {{.CPUPerc}}  内存: {{.MemUsage}}  网络: {{.NetIO}}" %%i 2>nul
        )
    )
) else (
    echo   (容器未运行)
)

:config_check
echo.
echo [配置文件]

if exist "%PROJECT_DIR%\.env" (
    echo   .env:            存在 (明文)
) else (
    echo   .env:            不存在
)

if exist "%PROJECT_DIR%\secrets\.env.encrypted" (
    echo   .env.encrypted:  存在 (加密)
) else (
    echo   .env.encrypted:  不存在
)

if exist "%PROJECT_DIR%\config\openclaw.json" (
    echo   openclaw.json:   存在
) else (
    echo   openclaw.json:   不存在
)

if exist "%PROJECT_DIR%\docker-compose.yml" (
    echo   docker-compose:  存在
) else (
    echo   docker-compose:  不存在
)

echo.
echo [数据目录]
for %%D in (data\credentials data\sessions data\logs) do (
    if exist "%PROJECT_DIR%\%%D" (
        set "FC=0"
        for /f %%n in ('dir /b /a-d "%PROJECT_DIR%\%%D" 2^>nul ^| find /c /v ""') do set "FC=%%n"
        echo   %%D:  !FC! 个文件
    ) else (
        echo   %%D:  不存在
    )
)

echo.
echo [网络端口]
netstat -an 2>nul | findstr ":18789" >nul 2>&1
if not errorlevel 1 (
    echo   Gateway (18789): 已监听
    echo   访问地址: http://localhost:18789
) else (
    echo   Gateway (18789): 未监听
)

echo.
popd
pause
exit /b 0
