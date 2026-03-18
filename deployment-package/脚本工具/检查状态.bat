@echo off
chcp 65001 >nul
echo ========================================
echo 网吧USB管理软件 - 服务状态检查
echo ========================================
echo.

echo 1. 检查Windows服务状态...
echo ---------------------------
sc query CyberCafeUsbManager 2>nul
if %errorLevel% equ 0 (
    echo ✅ 服务已安装
) else (
    echo ❌ 服务未安装或不存在
)

echo.
echo 2. 检查程序文件...
echo ---------------------------
cd /d "%~dp0..\主程序" 2>nul
if %errorLevel% equ 0 (
    if exist "CyberCafeUsbManager.exe" (
        echo ✅ 主程序存在
        for %%F in ("CyberCafeUsbManager.exe") do (
            echo    大小: %%~zF 字节
            echo    路径: %%~fF
        )
    ) else (
        echo ❌ 主程序不存在
    )
    
    echo.
    echo 检查依赖库:
    set FILE_COUNT=0
    if exist "Newtonsoft.Json.dll" (set /a FILE_COUNT+=1 & echo ✅ Newtonsoft.Json.dll)
    if exist "log4net.dll" (set /a FILE_COUNT+=1 & echo ✅ log4net.dll)
    if exist "TaskScheduler.dll" (set /a FILE_COUNT+=1 & echo ✅ TaskScheduler.dll)
    if exist "CyberCafeUsbManager.exe.config" (set /a FILE_COUNT+=1 & echo ✅ 配置文件存在)
    
    echo 依赖库总数: %FILE_COUNT%/4
) else (
    echo ❌ 无法访问主程序目录
)

echo.
echo 3. 检查日志目录...
echo ---------------------------
if exist "%ProgramData%\CyberCafeUsbManager\logs" (
    echo ✅ 日志目录存在: %ProgramData%\CyberCafeUsbManager\logs
    dir "%ProgramData%\CyberCafeUsbManager\logs" | findstr /c:"个文件" 2>nul
    if %errorLevel% equ 0 (
        echo    目录非空
    ) else (
        echo    目录为空或无日志文件
    )
) else (
    echo ℹ️  日志目录不存在（可能未创建或未记录文件日志）
)

echo.
echo 4. 检查事件日志...
echo ---------------------------
wevtutil qe "CyberCafeUsbManager" /c:1 /rd:true /f:text 2>nul | findstr /v "^$" >nul
if %errorLevel% equ 0 (
    echo ✅ 事件日志存在并有记录
    echo    最近一条日志:
    wevtutil qe "CyberCafeUsbManager" /c:1 /rd:true /f:text 2>nul | findstr /v "^$"
) else (
    echo ℹ️  事件日志为空或不存在
)

echo.
echo 5. 检查USB设备支持...
echo ---------------------------
if exist "%~dp0..\配置文件\usb_device_database.json" (
    echo ✅ USB设备数据库存在
    for /f "tokens=2 delims=:" %%i in ('type "%~dp0..\配置文件\usb_device_database.json" ^| find /c "brand"') do (
        echo    支持品牌数量: %%i
    )
) else (
    echo ⚠️  USB设备数据库不存在
)

echo.
echo ========================================
echo 状态总结
echo ========================================
echo.
echo 建议:
echo 1. 如果服务未安装 → 运行"安装服务.bat"
echo 2. 如果文件缺失 → 重新编译并复制文件
echo 3. 如果服务未运行 → 运行"安装服务.bat"重新安装
echo 4. 如果测试功能 → 插入USB设备并查看事件日志
echo.
echo 按任意键退出...
pause >nul
exit /b 0