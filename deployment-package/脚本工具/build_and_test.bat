@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo CyberCafe USB Manager - 编译测试脚本
echo ========================================
echo.

REM 设置变量
set PROJECT_NAME=CyberCafeUsbManager
set SOLUTION_FILE=CyberCafeUsbManager.sln
set CONFIGURATION=Release
set OUTPUT_DIR=CyberCafeUsbManager\bin\Release
set SERVICE_NAME=CyberCafeUsbManager
set LOG_FILE=build_test_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%.log

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ 请以管理员身份运行此脚本
    echo 右键点击 -> "以管理员身份运行"
    pause
    exit /b 1
)

echo ✅ 管理员权限确认

REM 检查必要文件
echo.
echo 1. 检查项目文件...
if not exist "%SOLUTION_FILE%" (
    echo ❌ 找不到解决方案文件: %SOLUTION_FILE%
    pause
    exit /b 1
)

if not exist "CyberCafeUsbManager\CyberCafeUsbManager.csproj" (
    echo ❌ 找不到项目文件: CyberCafeUsbManager\CyberCafeUsbManager.csproj
    pause
    exit /b 1
)

echo ✅ 项目文件检查通过

REM 检查编译工具
echo.
echo 2. 检查编译工具...
where msbuild >nul 2>&1
if %errorLevel% equ 0 (
    set BUILD_TOOL=msbuild
    for /f "tokens=*" %%i in ('where msbuild') do set MSBUILD_PATH=%%i
    echo ✅ 找到 MSBuild: !MSBUILD_PATH!
) else (
    where dotnet >nul 2>&1
    if %errorLevel% equ 0 (
        set BUILD_TOOL=dotnet
        for /f "tokens=*" %%i in ('where dotnet') do set DOTNET_PATH=%%i
        echo ✅ 找到 dotnet CLI: !DOTNET_PATH!
    ) else (
        echo ❌ 未找到编译工具 (MSBuild 或 dotnet)
        echo 请安装以下之一:
        echo   - Visual Studio Build Tools
        echo   - .NET SDK
        pause
        exit /b 1
    )
)

REM 编译项目
echo.
echo 3. 编译项目 (%CONFIGURATION%)...
echo 使用工具: !BUILD_TOOL!

if "!BUILD_TOOL!"=="msbuild" (
    echo 执行: msbuild "%SOLUTION_FILE%" /p:Configuration=%CONFIGURATION% /p:Platform="Any CPU" /v:minimal
    msbuild "%SOLUTION_FILE%" /p:Configuration=%CONFIGURATION% /p:Platform="Any CPU" /v:minimal
) else (
    echo 执行: dotnet build "%SOLUTION_FILE%" -c %CONFIGURATION% --no-restore
    dotnet build "%SOLUTION_FILE%" -c %CONFIGURATION% --no-restore
)

if %errorLevel% neq 0 (
    echo ❌ 编译失败
    pause
    exit /b 1
)

echo ✅ 编译成功

REM 检查输出文件
echo.
echo 4. 检查输出文件...
if not exist "%OUTPUT_DIR%\%PROJECT_NAME%.exe" (
    echo ❌ 找不到输出文件: %OUTPUT_DIR%\%PROJECT_NAME%.exe
    pause
    exit /b 1
)

for %%F in ("%OUTPUT_DIR%\%PROJECT_NAME%.exe") do set EXE_SIZE=%%~zF
echo ✅ 输出文件: %OUTPUT_DIR%\%PROJECT_NAME%.exe (!EXE_SIZE! 字节)

REM 检查依赖文件
echo.
echo 5. 检查依赖文件...
set DEPENDENCY_CHECK=passed
if not exist "%OUTPUT_DIR%\Newtonsoft.Json.dll" (
    echo ⚠️  缺少 Newtonsoft.Json.dll
    set DEPENDENCY_CHECK=warning
)

dir "%OUTPUT_DIR%\*.dll" | findstr /i "dll" >nul
if %errorLevel% neq 0 (
    echo ⚠️  未找到任何DLL依赖文件
    set DEPENDENCY_CHECK=warning
)

echo 依赖检查: !DEPENDENCY_CHECK!

REM 测试控制台模式
echo.
echo 6. 测试控制台模式...
echo 注意: 按 Ctrl+C 退出测试
timeout /t 3 /nobreak >nul

start "CyberCafe USB Manager 测试" cmd /k "cd /d "%cd%\%OUTPUT_DIR%" && echo 运行控制台测试模式... && echo 按任意键退出 && %PROJECT_NAME%.exe && pause"

echo.
echo ⚠️  请在弹出的控制台窗口中观察测试输出
echo 如果程序正常运行，应该能看到服务启动信息
echo 按任意键继续测试...
pause >nul

REM 服务安装测试（可选）
echo.
echo 7. 服务安装测试（可选）...
choice /c YN /n /m "是否安装服务进行测试? (Y/N)"
if %errorLevel% equ 1 (
    echo.
    echo 安装服务...
    
    REM 检查installutil
    where installutil >nul 2>&1
    if %errorLevel% equ 0 (
        echo 使用 installutil 安装服务...
        installutil "%OUTPUT_DIR%\%PROJECT_NAME%.exe"
        
        if %errorLevel% equ 0 (
            echo ✅ 服务安装成功
            
            echo.
            echo 启动服务...
            sc start %SERVICE_NAME%
            timeout /t 5 /nobreak >nul
            
            echo.
            echo 检查服务状态...
            sc query %SERVICE_NAME%
            
            echo.
            choice /c YN /n /m "是否停止并卸载服务? (Y/N)"
            if %errorLevel% equ 1 (
                echo.
                echo 停止服务...
                sc stop %SERVICE_NAME%
                timeout /t 3 /nobreak >nul
                
                echo 卸载服务...
                installutil /u "%OUTPUT_DIR%\%PROJECT_NAME%.exe"
                echo ✅ 服务卸载完成
            )
        ) else (
            echo ❌ 服务安装失败
        )
    ) else (
        echo ⚠️  找不到 installutil，使用 sc 命令...
        echo 创建服务...
        sc create %SERVICE_NAME% binPath= "%cd%\%OUTPUT_DIR%\%PROJECT_NAME%.exe" start= auto DisplayName= "CyberCafe USB Manager"
        
        if %errorLevel% equ 0 (
            echo ✅ 服务创建成功
            
            echo 启动服务...
            sc start %SERVICE_NAME%
            timeout /t 5 /nobreak >nul
            
            echo 检查服务状态...
            sc query %SERVICE_NAME%
            
            echo.
            choice /c YN /n /m "是否停止并删除服务? (Y/N)"
            if %errorLevel% equ 1 (
                echo.
                echo 停止服务...
                sc stop %SERVICE_NAME%
                timeout /t 3 /nobreak >nul
                
                echo 删除服务...
                sc delete %SERVICE_NAME%
                echo ✅ 服务删除完成
            )
        ) else (
            echo ❌ 服务创建失败
        )
    )
) else (
    echo 跳过服务安装测试
)

REM 生成测试报告
echo.
echo 8. 生成测试报告...
set REPORT_FILE=test_report_%date:~0,4%%date:~5,2%%date:~8,2%.txt
(
    echo ========================================
    echo CyberCafe USB Manager 测试报告
    echo 生成时间: %date% %time%
    echo ========================================
    echo.
    echo 1. 编译工具: !BUILD_TOOL!
    if "!BUILD_TOOL!"=="msbuild" (
        echo   路径: !MSBUILD_PATH!
    ) else (
        echo   路径: !DOTNET_PATH!
    )
    echo.
    echo 2. 编译结果: 成功
    echo   配置文件: %CONFIGURATION%
    echo   输出文件: %PROJECT_NAME%.exe (!EXE_SIZE! 字节)
    echo.
    echo 3. 依赖检查: !DEPENDENCY_CHECK!
    echo.
    echo 4. 控制台测试: 已执行
    echo.
    echo 5. 服务测试: 
    if exist "%OUTPUT_DIR%\%PROJECT_NAME%.InstallLog" (
        echo   安装日志存在
    ) else (
        echo   未执行完整服务测试
    )
    echo.
    echo 6. 建议:
    echo   - 在实际网吧环境中进一步测试
    echo   - 测试USB设备识别功能
    echo   - 验证驱动安装功能
    echo   - 测试品牌软件自动启动
) > "%REPORT_FILE%"

echo ✅ 测试报告已生成: %REPORT_FILE%

REM 显示下一步建议
echo.
echo ========================================
echo 测试完成 - 下一步建议
echo ========================================
echo.
echo 1. 查看输出文件:
echo   目录: %cd%\%OUTPUT_DIR%
echo   主程序: %PROJECT_NAME%.exe
echo.
echo 2. 手动测试建议:
echo   - 运行程序测试控制台模式
echo   - 安装服务测试后台运行
echo   - 检查事件查看器日志
echo.
echo 3. 实际环境测试:
echo   - 在网吧测试机上部署
echo   - 测试真实USB设备识别
echo   - 验证顺网系统集成
echo.
echo 4. 查看详细测试报告: %REPORT_FILE%
echo.

pause
exit /b 0