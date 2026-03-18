@echo off
REM ========================================
REM 网吧USB管理软件 - 简化测试脚本
REM 专为网吧环境设计，无需编译工具
REM ========================================

REM 1. 设置UTF-8编码，解决中文乱码问题
chcp 65001 >nul
echo 编码已设置为UTF-8

REM 2. 显示基本信息
echo ========================================
echo 网吧USB管理软件 - 环境检查
echo ========================================
echo 当前目录: %cd%
echo 日期: %date%
echo 时间: %time%
echo.

REM 3. 检查Python环境
echo 3. 检查Python环境...
where python >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%i in ('where python') do set PYTHON_PATH=%%i
    echo ✅ Python已安装: !PYTHON_PATH!
    
    REM 检查Python版本
    python --version
) else (
    echo ❌ 未找到Python，请安装Python 3.6+
    echo 下载地址: https://www.python.org/downloads/
    goto :end_with_pause
)

echo.

REM 4. 检查项目文件结构
echo 4. 检查项目文件结构...
set FILE_CHECK=passed

if not exist "CyberCafeUsbManager.sln" (
    echo ⚠️  缺少解决方案文件: CyberCafeUsbManager.sln
    set FILE_CHECK=warning
)

if not exist "CyberCafeUsbManager\CyberCafeUsbManager.csproj" (
    echo ⚠️  缺少项目文件: CyberCafeUsbManager\CyberCafeUsbManager.csproj
    set FILE_CHECK=warning
)

if not exist "usb_device_database.json" (
    echo ⚠️  缺少USB设备数据库: usb_device_database.json
    set FILE_CHECK=warning
)

if not exist "usb_device_scanner.py" (
    echo ⚠️  缺少Python扫描脚本: usb_device_scanner.py
    set FILE_CHECK=warning
)

echo 文件检查: !FILE_CHECK!
echo.

REM 5. 运行Python验证脚本
echo 5. 运行Python验证脚本...
if exist "validate_csharp.py" (
    echo 执行: python validate_csharp.py
    python validate_csharp.py
) else (
    echo ⚠️  缺少validate_csharp.py，跳过验证
)

echo.

REM 6. 运行USB设备扫描测试
echo 6. 运行USB设备扫描测试...
if exist "usb_device_scanner.py" (
    echo 执行: python usb_device_scanner.py
    python usb_device_scanner.py
) else (
    echo ⚠️  缺少usb_device_scanner.py，跳过扫描测试
)

echo.

REM 7. 检查编译工具（可选）
echo 7. 检查编译工具（可选）...
echo 注意：网吧环境可能没有安装编译工具

where msbuild >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%i in ('where msbuild') do (
        echo ✅ 找到MSBuild: %%i
    )
) else (
    echo ℹ️  未找到MSBuild (正常，网吧环境通常不安装)
)

where dotnet >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%i in ('where dotnet') do (
        echo ✅ 找到dotnet CLI: %%i
    )
) else (
    echo ℹ️  未找到dotnet CLI (正常，网吧环境通常不安装)
)

echo.

REM 8. 提供预编译方案
echo 8. 预编译方案...
echo 如果需要在网吧部署，建议：
echo   1. 在开发机器上编译好程序
echo   2. 将整个"CyberCafeUsbManager\bin\Release"目录复制到网吧
echo   3. 运行"CyberCafeUsbManager.exe"进行测试
echo.
echo 如果已有编译好的程序，请将其放在以下目录：
echo   "CyberCafeUsbManager\bin\Release\"
echo.

REM 9. 生成测试报告
echo 9. 生成测试报告...
set REPORT_FILE=netcafe_test_report_%date:~0,4%%date:~5,2%%date:~8,2%.txt

(
    echo ========================================
    echo 网吧USB管理软件 - 简化测试报告
    echo 生成时间: %date% %time%
    echo 测试环境: 网吧机器
    echo ========================================
    echo.
    echo 1. Python环境: 
    if defined PYTHON_PATH (
        echo   路径: !PYTHON_PATH!
        python --version 2>&1
    ) else (
        echo   未安装
    )
    echo.
    echo 2. 文件结构检查: !FILE_CHECK!
    echo.
    echo 3. 编译工具状态:
    echo   MSBuild: 未检查
    echo   dotnet: 未检查
    echo.
    echo 4. 测试建议:
    echo   - 使用Python脚本验证项目结构
    echo   - 在开发机器上编译程序
    echo   - 将编译好的程序复制到网吧测试
    echo   - 测试USB设备识别功能
    echo.
    echo 5. 常见问题:
    echo   - 乱码问题: 脚本已设置chcp 65001
    echo   - 权限问题: 可能需要管理员权限
    echo   - 依赖缺失: 网吧可能缺少.NET运行时
) > "!REPORT_FILE!"

echo ✅ 测试报告已生成: !REPORT_FILE!

:end_with_pause
echo.
echo ========================================
echo 测试完成
echo ========================================
echo.
echo 下一步操作:
echo 1. 检查上面的测试输出
echo 2. 查看生成的测试报告: !REPORT_FILE!
echo 3. 如有编译好的程序，可以运行测试
echo 4. 联系开发人员获取预编译版本
echo.
echo 按任意键退出...
pause >nul
exit /b 0