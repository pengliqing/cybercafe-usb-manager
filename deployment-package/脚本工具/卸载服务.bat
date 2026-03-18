@echo off
chcp 65001 >nul
echo ========================================
echo 网吧USB管理软件 - 服务卸载工具
echo ========================================
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ 请以管理员身份运行此脚本
    pause
    exit /b 1
)

echo ✅ 管理员权限确认
echo.

REM 停止服务
echo 正在停止服务...
sc stop CyberCafeUsbManager 2>nul
if %errorLevel% equ 0 (
    echo ✅ 服务已停止
) else (
    echo ℹ️  服务未运行或不存在
)

timeout /t 2 /nobreak >nul

REM 卸载服务
echo.
echo 正在卸载服务...
where installutil >nul 2>&1
if %errorLevel% equ 0 (
    echo 使用installutil卸载...
    installutil /u "%~dp0..\主程序\CyberCafeUsbManager.exe" 2>nul
    if %errorLevel% equ 0 (
        echo ✅ 服务卸载成功
    ) else (
        echo ⚠️  installutil卸载失败，尝试SC命令...
        goto :method2
    )
) else (
    goto :method2
)

goto :cleanup

:method2
echo 使用SC命令删除服务...
sc delete CyberCafeUsbManager 2>nul
if %errorLevel% equ 0 (
    echo ✅ 服务删除成功
) else (
    echo ℹ️  服务不存在或已被删除
)

:cleanup
echo.
echo 清理文件和目录...

REM 清理日志目录
if exist "%ProgramData%\CyberCafeUsbManager" (
    rmdir /s /q "%ProgramData%\CyberCafeUsbManager" 2>nul
    if %errorLevel% equ 0 (
        echo ✅ 清理日志目录: %ProgramData%\CyberCafeUsbManager
    )
)

REM 清理事件日志
echo 清理事件日志..."
wevtutil cl "CyberCafeUsbManager" 2>nul

echo.
echo ========================================
echo 卸载完成！
echo ========================================
echo.
echo 已移除:
echo 1. Windows服务 (CyberCafeUsbManager)
echo 2. 日志目录 (%ProgramData%\CyberCafeUsbManager)
echo 3. 事件日志 (CyberCafeUsbManager)
echo.
echo 注意: 程序文件仍保留在安装目录，如需完全移除请手动删除。
echo.
echo 按任意键退出...
pause >nul
exit /b 0