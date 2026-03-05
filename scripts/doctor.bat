@echo off
setlocal EnableDelayedExpansion
title PocketClaw Doctor
color 0B

REM 项目目录
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."
set "PROJECT_DIR=%CD%"

REM 版本
set "PC_VERSION=unknown"
if exist "%PROJECT_DIR%\VERSION" (
    set /p PC_VERSION=<"%PROJECT_DIR%\VERSION"
)

REM 诊断计数器
set "TOTAL=0"
set "PASSED=0"
set "FAILED=0"
set "WARNINGS=0"
set "SKIP_REST=0"
set "PROBLEMS="
set "CAN_FIX=0"
set "DISK_FREE_MB=9999"

echo.
echo ============================================
echo   PocketClaw Doctor v%PC_VERSION%
echo   自诊断修复工具
echo ============================================
echo.
echo   正在检查 10 个诊断项...
echo.

REM ============================================
REM [1/10] Docker 安装
REM ============================================
set /a TOTAL+=1
set /p "=  [1/10] Docker 安装..." <nul
docker --version >nul 2>&1
if !ERRORLEVEL! equ 0 (
    set /a PASSED+=1
    echo  [OK]
) else (
    set /a FAILED+=1
    echo  [失败] 未安装
    echo.
    echo   Docker 未安装，后续检查无法继续。
    echo   请先运行 PocketClaw 启动器安装 Docker。
    set "PROBLEMS=!PROBLEMS![FAIL] Docker 安装: 未检测到 docker 命令 & "
    set /a TOTAL=10
    set /a FAILED+=9
    goto :summary
)

REM ============================================
REM [2/10] Docker 引擎运行
REM ============================================
set /a TOTAL+=1
set /p "=  [2/10] Docker 引擎..." <nul
docker info >nul 2>&1
if !ERRORLEVEL! equ 0 (
    set /a PASSED+=1
    echo  [OK]
) else (
    set /a FAILED+=1
    echo  [失败] 未运行
    set "PROBLEMS=!PROBLEMS![FAIL] Docker 引擎: 已安装但未运行，请启动 Docker Desktop & "
)

REM ============================================
REM [3/10] Docker 镜像
REM ============================================
set /a TOTAL+=1
set /p "=  [3/10] Docker 镜像..." <nul
docker image inspect pocketclaw-pocketclaw:latest >nul 2>&1
if !ERRORLEVEL! equ 0 (
    set /a PASSED+=1
    echo  [OK]
) else (
    set /a FAILED+=1
    echo  [失败] 不存在
    set "PROBLEMS=!PROBLEMS![FAIL] Docker 镜像: 镜像不存在，需运行启动器构建 & "
)

REM ============================================
REM [4/10] 容器状态
REM ============================================
set /a TOTAL+=1
set /p "=  [4/10] 容器状态..." <nul
set "C_STATUS="
for /f "tokens=*" %%i in ('docker ps -a --filter "name=pocketclaw" --format "{{.Status}}" 2^>nul') do set "C_STATUS=%%i"
if "!C_STATUS!"=="" (
    set /a FAILED+=1
    echo  [失败] 不存在
    set "PROBLEMS=!PROBLEMS![FAIL] 容器状态: pocketclaw 容器不存在 & "
) else (
    echo !C_STATUS! | findstr /i "Up" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo !C_STATUS! | findstr /i "unhealthy" >nul 2>&1
        if !ERRORLEVEL! equ 0 (
            set /a WARNINGS+=1
            echo  [警告] unhealthy
            set "PROBLEMS=!PROBLEMS![WARN] 容器状态: 运行中但不健康 & "
        ) else (
            set /a PASSED+=1
            echo  [OK] !C_STATUS!
        )
    ) else (
        set /a FAILED+=1
        echo  [失败] 已停止
        set "PROBLEMS=!PROBLEMS![FAIL] 容器状态: 容器已停止 !C_STATUS! & "
    )
)

REM ============================================
REM [5/10] 端口与健康检查
REM ============================================
set /a TOTAL+=1
set /p "=  [5/10] 服务端口..." <nul
curl.exe -sf --connect-timeout 3 http://127.0.0.1:18789/health >nul 2>&1
if !ERRORLEVEL! equ 0 (
    set /a PASSED+=1
    echo  [OK]
) else (
    set /a FAILED+=1
    echo  [失败] 无响应
    set "PROBLEMS=!PROBLEMS![FAIL] 服务端口: 18789 无响应 & "
)

REM ============================================
REM [6/10] .provider 配置文件
REM ============================================
set /a TOTAL+=1
set /p "=  [6/10] .provider 配置..." <nul
set "PROV_FILE=%PROJECT_DIR%\config\workspace\.provider"
if exist "!PROV_FILE!" (
    findstr /b "PROVIDER_NAME=" "!PROV_FILE!" >nul 2>&1
    set "HAS_PROV=!ERRORLEVEL!"
    findstr /b "API_KEY=" "!PROV_FILE!" >nul 2>&1
    set "HAS_AKEY=!ERRORLEVEL!"
    if !HAS_PROV! equ 0 if !HAS_AKEY! equ 0 (
        set /a PASSED+=1
        echo  [OK]
    ) else (
        set /a WARNINGS+=1
        echo  [警告] 字段不全
        set "PROBLEMS=!PROBLEMS![WARN] .provider 配置: 缺少必要字段 & "
    )
) else (
    set /a WARNINGS+=1
    echo  [警告] 不存在
    set "PROBLEMS=!PROBLEMS![WARN] .provider 配置: 文件不存在 & "
)

REM ============================================
REM [7/10] API Key 配置
REM ============================================
set /a TOTAL+=1
set /p "=  [7/10] API Key..." <nul
set "API_KEY_FOUND="
if exist "!PROV_FILE!" (
    for /f "tokens=1,* delims==" %%a in ('findstr /b "API_KEY=" "!PROV_FILE!" 2^>nul') do set "API_KEY_FOUND=%%b"
)
if "!API_KEY_FOUND!"=="" (
    for /f "tokens=*" %%k in ('docker exec pocketclaw sh -c "echo $OPENAI_API_KEY" 2^>nul') do set "API_KEY_FOUND=%%k"
)
if "!API_KEY_FOUND!"=="" (
    set /a FAILED+=1
    echo  [失败] 未配置
    set "PROBLEMS=!PROBLEMS![FAIL] API Key: 未配置或为空 & "
) else if "!API_KEY_FOUND!"=="not-configured-yet" (
    set /a FAILED+=1
    echo  [失败] 未配置
    set "PROBLEMS=!PROBLEMS![FAIL] API Key: 未配置 & "
) else (
    set /a PASSED+=1
    echo  [OK]
)

REM ============================================
REM [8/10] .env 加密状态
REM ============================================
set /a TOTAL+=1
set /p "=  [8/10] 配置加密..." <nul
set "ENC_FILE=%PROJECT_DIR%\secrets\.env.encrypted"
set "ENV_FILE=%PROJECT_DIR%\.env"
if exist "!ENC_FILE!" (
    if exist "!ENV_FILE!" (
        set /a WARNINGS+=1
        echo  [警告] 明文残留
        set "PROBLEMS=!PROBLEMS![WARN] 加密: 存在加密文件但明文 .env 也存在 & "
    ) else (
        set /a PASSED+=1
        echo  [OK] 已加密
    )
) else if exist "!ENV_FILE!" (
    set /a WARNINGS+=1
    echo  [警告] 未加密
    set "PROBLEMS=!PROBLEMS![WARN] 加密: 配置未加密，建议运行 encrypt & "
) else (
    set /a WARNINGS+=1
    echo  [警告]
    set "PROBLEMS=!PROBLEMS![WARN] 加密: 无 .env 也无加密文件 & "
)

REM ============================================
REM [9/10] 磁盘空间
REM ============================================
set /a TOTAL+=1
set /p "=  [9/10] 磁盘空间..." <nul
set "DRIVE_LETTER=%PROJECT_DIR:~0,1%"
set "DISK_FREE_MB=0"
for /f %%f in ('powershell -NoProfile -Command "[math]::Floor((Get-PSDrive !DRIVE_LETTER!).Free / 1MB)" 2^>nul') do set "DISK_FREE_MB=%%f"
if !DISK_FREE_MB! lss 500 (
    set /a FAILED+=1
    echo  [失败] 仅剩 !DISK_FREE_MB!MB
    set "PROBLEMS=!PROBLEMS![FAIL] 磁盘空间: 仅剩 !DISK_FREE_MB!MB，低于 500MB & "
) else if !DISK_FREE_MB! lss 2000 (
    set /a WARNINGS+=1
    echo  [警告] !DISK_FREE_MB!MB
    set "PROBLEMS=!PROBLEMS![WARN] 磁盘空间: 剩余 !DISK_FREE_MB!MB，建议清理 & "
) else (
    set /a PASSED+=1
    echo  [OK]
)

REM ============================================
REM [10/10] 容器日志分析
REM ============================================
set /a TOTAL+=1
set /p "=  [10/10] 容器日志..." <nul
set "LOG_ERRS=0"
docker ps --filter "name=pocketclaw" --format "{{.ID}}" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    for /f %%n in ('docker logs pocketclaw --tail 50 2^>^&1 ^| findstr /i /c:"error" /c:"fatal" /c:"crash" /c:"panic" 2^>nul ^| find /c /v ""') do set "LOG_ERRS=%%n"
    if !LOG_ERRS! gtr 5 (
        set /a WARNINGS+=1
        echo  [警告] !LOG_ERRS! 条错误
        set "PROBLEMS=!PROBLEMS![WARN] 容器日志: 发现 !LOG_ERRS! 条错误记录 & "
    ) else (
        set /a PASSED+=1
        echo  [OK]
    )
) else (
    set /a WARNINGS+=1
    echo  [警告] 无容器
    set "PROBLEMS=!PROBLEMS![WARN] 容器日志: 容器未运行，无法检查 & "
)

:summary
echo.
echo ============================================
echo   诊断完成: !TOTAL! 项检查
echo   通过: !PASSED!  失败: !FAILED!  警告: !WARNINGS!
echo ============================================
echo.

if "!PROBLEMS!"=="" (
    echo   所有检查通过，PocketClaw 运行正常。
    goto :export_report
)

REM ============================================
REM AI 智能分析
REM ============================================
echo --------------------------------------------
echo   AI 智能分析
echo --------------------------------------------
echo.

set "AI_API_KEY="
if exist "!PROV_FILE!" (
    for /f "tokens=1,* delims==" %%a in ('findstr /b "API_KEY=" "!PROV_FILE!" 2^>nul') do set "AI_API_KEY=%%b"
)
if "!AI_API_KEY!"=="" (
    for /f "tokens=*" %%k in ('docker exec pocketclaw sh -c "echo $OPENAI_API_KEY" 2^>nul') do set "AI_API_KEY=%%k"
)
if "!AI_API_KEY!"=="" (
    echo   [跳过] 未找到 API Key，无法调用 AI 分析
    goto :auto_fix
)
if "!AI_API_KEY!"=="not-configured-yet" (
    echo   [跳过] API Key 未配置
    goto :auto_fix
)

echo   正在调用 AI 分析...
set "SYS_INFO=OS: Windows"
for /f "tokens=*" %%v in ('docker --version 2^>nul') do set "SYS_INFO=!SYS_INFO!, Docker: %%v"
if exist "%PROJECT_DIR%\VERSION" (
    set /p PC_VER=<"%PROJECT_DIR%\VERSION"
    set "SYS_INFO=!SYS_INFO!, Version: !PC_VER!"
)

REM 获取容器日志
set "CONTAINER_LOGS="
for /f "tokens=*" %%l in ('docker logs pocketclaw --tail 20 2^>^&1') do (
    set "CONTAINER_LOGS=!CONTAINER_LOGS!%%l\n"
)

REM 调用 AI 分析（通过 Python 脚本）
call :run_ai_analysis
echo.

:auto_fix
REM ============================================
REM 自动修复
REM ============================================
if !FAILED! equ 0 goto :export_report

echo.
echo --------------------------------------------
echo   自动修复
echo --------------------------------------------
echo.

set "CAN_FIX=0"

REM 检查可修复项: 容器已停止
for /f "tokens=*" %%c in ('docker ps -a --filter "name=pocketclaw" --filter "status=exited" --format "{{.ID}}" 2^>nul') do (
    if not "%%c"=="" (
        set /a CAN_FIX+=1
        echo   [可修复] 容器已停止，可尝试重启
    )
)

REM 检查可修复项: 磁盘空间不足
if !DISK_FREE_MB! lss 500 (
    set /a CAN_FIX+=1
    echo   [可修复] 磁盘空间不足，可清理 Docker 缓存
)

if !CAN_FIX! equ 0 (
    echo   当前问题需要手动处理，请参考上方分析建议。
    goto :export_report
)

echo.
set /p "FIX_CHOICE=  是否尝试自动修复？(y/N): "
if /i not "!FIX_CHOICE!"=="y" (
    echo   [跳过] 已跳过自动修复
    goto :export_report
)

echo.

REM 执行修复: 重启容器
for /f "tokens=*" %%c in ('docker ps -a --filter "name=pocketclaw" --filter "status=exited" --format "{{.ID}}" 2^>nul') do (
    if not "%%c"=="" (
        echo   [修复] 正在重启容器...
        docker restart pocketclaw >nul 2>&1
        timeout /t 5 /nobreak >nul
        curl.exe -sf --connect-timeout 5 http://127.0.0.1:18789/health >nul 2>&1
        if !ERRORLEVEL! equ 0 (
            echo   [OK] 容器重启成功，服务已恢复
        ) else (
            echo   [警告] 容器已重启，请等待 30 秒后重新运行 doctor
        )
    )
)

REM 执行修复: 清理 Docker 缓存
if !DISK_FREE_MB! lss 500 (
    echo   [修复] 正在清理 Docker 缓存...
    docker system prune -f >nul 2>&1
    echo   [OK] Docker 缓存已清理
)

echo.
echo   修复完成。建议重新运行 doctor 确认结果。

:export_report
REM ============================================
REM 导出诊断报告
REM ============================================
echo.
echo --------------------------------------------
echo   导出诊断报告
echo --------------------------------------------

if not exist "%PROJECT_DIR%\data\logs" mkdir "%PROJECT_DIR%\data\logs"

call :write_report
if !ERRORLEVEL! neq 0 (
    echo   [警告] 报告保存失败
)

echo.
echo ============================================
echo   诊断结束
echo ============================================
echo.
pause
endlocal
exit /b 0

REM ============================================================
REM  子程序区（在主流程 exit /b 之后，防止 fall-through）
REM ============================================================

:run_ai_analysis
REM 用 Python 调用 iFlow API 进行 AI 分析
python3 -c "import json,sys,subprocess;key='!AI_API_KEY!';problems=r'!PROBLEMS!';sysinfo=r'!SYS_INFO!';logs=r'!CONTAINER_LOGS!';prompt='你是 PocketClaw 技术支持。诊断发现:\n'+problems.replace(' & ','\n')+'\n系统: '+sysinfo+('\n日志:\n'+logs if logs else '')+'\n请用中文简要分析原因并给出修复步骤。纯文本格式。';payload=json.dumps({'model':'qwen3-coder-plus','messages':[{'role':'user','content':prompt}],'max_tokens':800,'temperature':0.3});r=subprocess.run(['curl.exe','-s','--max-time','30','-X','POST','https://apis.iflow.cn/v1/chat/completions','-H','Content-Type: application/json','-H','Authorization: Bearer '+key,'-d',payload],capture_output=True,text=True);d=json.loads(r.stdout);reply=d['choices'][0]['message']['content'];print('\n  --- AI 分析结果 ---\n');[print('  '+l) for l in reply.split('\n')];print('\n  ------------------')" 2>nul
goto :eof

:write_report
REM 生成诊断报告文件
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "RPT_DATE=%%a%%b%%c"
for /f "tokens=1-2 delims=:. " %%a in ('echo %TIME%') do set "RPT_TIME=%%a%%b"
set "RPT_TIME=!RPT_TIME: =0!"
set "REPORT_FILE=%PROJECT_DIR%\data\logs\doctor-!RPT_DATE!-!RPT_TIME!.txt"

(
    echo PocketClaw Doctor 诊断报告
    echo ==========================
    echo 时间: !RPT_DATE! !RPT_TIME!
    echo 版本: !PC_VERSION!
    echo 系统: Windows
    echo.
    echo 诊断结果: !TOTAL! 项检查, 通过 !PASSED!, 失败 !FAILED!, 警告 !WARNINGS!
    echo.
    if not "!PROBLEMS!"=="" (
        echo 问题详情:
        set "TMP_PROB=!PROBLEMS!"
        REM 按 & 分隔输出每条问题
        :prob_loop
        for /f "tokens=1* delims=&" %%a in ("!TMP_PROB!") do (
            set "ONE=%%a"
            if not "!ONE!"=="" if not "!ONE!"==" " echo !ONE!
            set "TMP_PROB=%%b"
        )
        if defined TMP_PROB goto :prob_loop
        echo.
    )
) > "!REPORT_FILE!" 2>nul

echo.
echo   报告已保存: !REPORT_FILE!
goto :eof
