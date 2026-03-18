@echo off
chcp 65001 >nul
echo ========================================
echo 网吧USB管理软件 - 服务安装工具
echo ========================================
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ 请以管理员身份运行此脚本
    echo 右键点击 -> "以管理员身份运行"
    pause
    exit /b 1
)

echo ✅ 管理员权限确认
echo.

REM 切换到脚本所在目录
cd /d "%~dp0"

REM 检查主程序是否存在
if not exist "..\主程序\CyberCafeUsbManager.exe" (
    echo ❌ 找不到主程序: ..\主程序\CyberCafeUsbManager.exe
    echo 请确保已正确编译程序并放置在"主程序"目录
    echo.
    echo 预期文件结构:
    echo   部署包\
    echo   ├── 主程序\
    echo   │   ├── CyberCafeUsbManager.exe
    echo   │   ├── CyberCafeUsbManager.exe.config
    echo   │   ├── Newtonsoft.Json.dll
    echo   │   ├── log4net.dll
    echo   │   └── TaskScheduler.dll
    echo   └── 脚本工具\ (当前目录)
    echo.
    pause
    exit /b 1
)

echo 正在安装服务...
echo.

REM 方法一：使用installutil（如果可用）
where installutil >nul 2>&1
if %errorLevel% equ 0 (
    echo 使用installutil安装服务...
    installutil "..\主程序\CyberCafeUsbManager.exe"
    
    if %errorLevel% equ 0 (
        echo ✅ 服务安装成功
    ) else (
        echo ⚠️  installutil安装失败，尝试方法二...
        goto :method2
    )
) else (
    echo ⚠️  未找到installutil，使用方法二...
    goto :method2
)

goto :start_service

:method2
echo.
echo 使用方法二：SC命令创建服务...
sc create CyberCafeUsbManager binPath= "%~dp0..\主程序\CyberCafeUsbManager.exe" start= auto DisplayName= "CyberCafe USB Manager"

if %errorLevel% equ 0 (
    echo ✅ 服务创建成功
) else (
    echo ❌ 服务创建失败
    echo 可能原因:
    echo 1. 服务已存在
    echo 2. 路径包含特殊字符
    echo 3. 权限不足
    echo.
    echo 尝试手动安装:
    echo 1. 以管理员打开CMD
    echo 2. 运行: sc create CyberCafeUsbManager binPath= "完整路径\CyberCafeUsbManager.exe" start= auto
    pause
    exit /b 1
)

:start_service
echo.
echo 启动服务...
sc start CyberCafeUsbManager
timeout /t 5 /nobreak >nul

echo.
echo 检查服务状态...
sc query CyberCafeUsbManager | findstr /C:"STATE"

echo.
echo 配置日志目录...
if not exist "%ProgramData%\CyberCafeUsbManager\logs" (
    mkdir "%ProgramData%\CyberCafeUsbManager\logs" 2>nul
    if %errorLevel% equ 0 (
        echo ✅ 日志目录创建成功: %ProgramData%\CyberCafeUsbManager\logs
    )
)

echo.
echo ========================================
echo 安装完成！
echo ========================================
echo.
echo 重要信息:
echo 1. 服务名称: CyberCafeUsbManager
echo 2. 显示名称: CyberCafe USB Manager
echo 3. 启动类型: 自动
echo 4. 日志位置: 事件查看器 → 应用程序和服务日志 → CyberCafeUsbManager
echo.
echo 下一步操作:
echo 1. 插入USB键盘/鼠标测试识别功能
echo 2. 查看事件查看器确认安装成功
echo 3. 如有问题，运行"控制台测试.bat"调试
echo.
echo 按任意键退出...
pause >nul
exit /b 0