@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM change-api.bat  —— 快速更换 GLM API Key [Windows]
REM 自动解密 → 修改 → 重新加密 → 重启容器
REM 用法: scripts\change-api.bat
REM ============================================================

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%.."
set "PROJECT_DIR=%CD%"

set "ENV_FILE=%PROJECT_DIR%\.env"
set "ENC_FILE=%PROJECT_DIR%\secrets\.env.encrypted"

REM --------------- 确保 openssl 可用（Git for Windows 自带） ---------------
where openssl >nul 2>&1
if errorlevel 1 (
    if exist "C:\Program Files\Git\usr\bin\openssl.exe" (
        set "PATH=C:\Program Files\Git\usr\bin;%PATH%"
    )
)

echo.
echo ======================================
echo    快速更换 GLM API Key
echo ======================================
echo.

REM --------------- 如果 .env 不存在, 尝试解密 ---------------
if not exist "%ENV_FILE%" (
    if exist "%ENC_FILE%" (
        echo [信息] 正在解密 .env ...
        for /f "delims=" %%p in ('powershell -NoProfile -Command "$p = Read-Host -Prompt '  Master Password' -AsSecureString; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p))"') do set "MASTER_PASS=%%p"
        <nul set /p ="!MASTER_PASS!"| openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 100000 ^
            -in "%ENC_FILE%" -out "%ENV_FILE%" -pass stdin 2>nul
        if errorlevel 1 (
            echo [错误] 解密失败, 密码错误.
            popd & pause & exit /b 1
        )
        set "NEED_REENCRYPT=1"
        echo [OK] 解密成功.
    ) else (
        echo [错误] 未找到 .env 或 .env.encrypted
        echo 请先运行 setup-env.bat
        popd & pause & exit /b 1
    )
) else (
    set "NEED_REENCRYPT=0"
    set "MASTER_PASS="
)

REM 读取当前值
for /f "tokens=1,* delims==" %%a in ('findstr /i "ZHIPU_API_KEY" "%ENV_FILE%" 2^>nul') do set "CUR_KEY=%%b"

echo.
if defined CUR_KEY echo   当前 API Key: !CUR_KEY:~0,8!****
echo.
echo   获取新的 API Key: https://open.bigmodel.cn/usercenter/apikeys
echo.

set "NEW_KEY="
set /p "NEW_KEY=新的 GLM API Key (留空保持不变): "

if "!NEW_KEY!"=="" (
    echo   未修改.
    goto :cleanup
)

echo.
echo [信息] 正在更新 .env ...
powershell -Command "(Get-Content '%ENV_FILE%') -replace '^ZHIPU_API_KEY=.*', 'ZHIPU_API_KEY=!NEW_KEY!' | Set-Content '%ENV_FILE%'"
echo   [OK] GLM API Key 已更新

REM --------------- 重新加密 ---------------
if "!NEED_REENCRYPT!"=="1" (
    echo.
    echo [信息] 重新加密 .env ...
    <nul set /p ="!MASTER_PASS!"| openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 ^
        -in "%ENV_FILE%" -out "%ENC_FILE%" -pass stdin
    if errorlevel 1 (
        echo [错误] 重新加密失败! 明文 .env 已保留, 请手动处理.
        popd & pause & exit /b 1
    )
    echo [OK] 已重新加密.
)

REM --------------- 询问是否重启 ---------------
echo.
set /p "RESTART=是否重启 PocketClaw 使配置生效? (y/N): "
if /i "!RESTART!"=="y" (
    echo [信息] 重启容器...
    docker compose -f "%PROJECT_DIR%\docker-compose.yml" up -d --force-recreate 2>nul || docker-compose -f "%PROJECT_DIR%\docker-compose.yml" up -d --force-recreate 2>nul
    echo [OK] 重启完成.
)

:cleanup
REM 如果是从加密文件解密的, 安全擦除明文
if "!NEED_REENCRYPT!"=="1" (
    powershell -NoProfile -Command "$f='%ENV_FILE%'; if(Test-Path $f){$s=(Get-Item $f).Length; $r=New-Object byte[] $s; [Security.Cryptography.RandomNumberGenerator]::Fill($r); [IO.File]::WriteAllBytes($f,$r)}" 2>nul
    del "%ENV_FILE%" 2>nul
    echo [安全] 已安全擦除明文 .env
)

echo.
echo [完成] API Key 更换完成!

popd
pause
exit /b 0
