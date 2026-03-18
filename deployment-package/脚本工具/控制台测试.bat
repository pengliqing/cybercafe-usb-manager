@echo off
chcp 65001 >nul
echo ========================================
echo 网吧USB管理软件 - 控制台测试模式
echo ========================================
echo.

cd /d "%~dp0..\主程序"

if not exist "CyberCafeUsbManager.exe" (
    echo ❌ 找不到主程序
    echo 请确保已正确编译程序并放置在"主程序"目录
    echo.
    echo 当前目录: %cd%
    dir
    pause
    exit /b 1
)

echo 程序信息:
echo - 名称: CyberCafeUsbManager.exe
echo - 目录: %cd%
echo.
echo 启动控制台测试模式...
echo.
echo 重要提示:
echo 1. 按 ESC 键可退出程序
echo 2. 程序将以调试模式运行
echo 3. 可以观察实时设备识别日志
echo 4. 此模式不会安装Windows服务
echo.
echo 正在启动...

CyberCafeUsbManager.exe

echo.
echo ========================================
echo 测试结束
echo ========================================
echo.
echo 下一步操作:
echo 1. 如需安装为服务，运行"安装服务.bat"
echo 2. 如需卸载，运行"卸载服务.bat"
echo 3. 查看测试日志: 事件查看器 → CyberCafeUsbManager
echo.
echo 按任意键退出...
pause >nul
exit /b 0