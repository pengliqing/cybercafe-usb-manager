@echo off
REM CyberCafe USB Manager - Build and Test Script (English)
REM Compatible with all Windows code pages

setlocal enabledelayedexpansion

echo ========================================
echo CyberCafe USB Manager - Build Test Script
echo ========================================
echo.

REM Set variables
set PROJECT_NAME=CyberCafeUsbManager
set SOLUTION_FILE=CyberCafeUsbManager.sln
set CONFIGURATION=Release
set OUTPUT_DIR=CyberCafeUsbManager\bin\Release
set SERVICE_NAME=CyberCafeUsbManager

REM Check administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run as Administrator
    echo Right-click -> "Run as administrator"
    pause
    exit /b 1
)

echo [OK] Administrator privileges confirmed

REM Check required files
echo.
echo 1. Checking project files...
if not exist "%SOLUTION_FILE%" (
    echo [ERROR] Solution file not found: %SOLUTION_FILE%
    pause
    exit /b 1
)

if not exist "CyberCafeUsbManager\CyberCafeUsbManager.csproj" (
    echo [ERROR] Project file not found: CyberCafeUsbManager\CyberCafeUsbManager.csproj
    pause
    exit /b 1
)

echo [OK] Project files check passed

REM Check build tools
echo.
echo 2. Checking build tools...
where msbuild >nul 2>&1
if %errorLevel% equ 0 (
    set BUILD_TOOL=msbuild
    for /f "tokens=*" %%i in ('where msbuild') do set MSBUILD_PATH=%%i
    echo [OK] Found MSBuild: !MSBUILD_PATH!
) else (
    where dotnet >nul 2>&1
    if %errorLevel% equ 0 (
        set BUILD_TOOL=dotnet
        for /f "tokens=*" %%i in ('where dotnet') do set DOTNET_PATH=%%i
        echo [OK] Found dotnet CLI: !DOTNET_PATH!
    ) else (
        echo [ERROR] No build tools found (MSBuild or dotnet)
        echo Please install one of:
        echo   - Visual Studio Build Tools
        echo   - .NET SDK
        pause
        exit /b 1
    )
)

REM Build project
echo.
echo 3. Building project (%CONFIGURATION%)...
echo Using tool: !BUILD_TOOL!

if "!BUILD_TOOL!"=="msbuild" (
    echo Executing: msbuild "%SOLUTION_FILE%" /p:Configuration=%CONFIGURATION% /p:Platform="Any CPU" /v:minimal
    msbuild "%SOLUTION_FILE%" /p:Configuration=%CONFIGURATION% /p:Platform="Any CPU" /v:minimal
) else (
    echo Executing: dotnet build "%SOLUTION_FILE%" -c %CONFIGURATION% --no-restore
    dotnet build "%SOLUTION_FILE%" -c %CONFIGURATION% --no-restore
)

if %errorLevel% neq 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

echo [OK] Build successful

REM Check output file
echo.
echo 4. Checking output file...
if not exist "%OUTPUT_DIR%\%PROJECT_NAME%.exe" (
    echo [ERROR] Output file not found: %OUTPUT_DIR%\%PROJECT_NAME%.exe
    pause
    exit /b 1
)

for %%F in ("%OUTPUT_DIR%\%PROJECT_NAME%.exe") do set EXE_SIZE=%%~zF
echo [OK] Output file: %OUTPUT_DIR%\%PROJECT_NAME%.exe (!EXE_SIZE! bytes)

REM Test console mode
echo.
echo 5. Testing console mode...
echo Note: Press Ctrl+C to exit test
timeout /t 2 /nobreak >nul

echo.
echo Starting console test in new window...
start "CyberCafe USB Manager Test" cmd /k "cd /d "%cd%\%OUTPUT_DIR%" && echo Running console test... && echo Press any key to exit && %PROJECT_NAME%.exe && pause"

echo.
echo [INFO] Check the new console window for test output
echo If program runs normally, you should see service start information
echo Press any key to continue...
pause >nul

REM Optional service installation test
echo.
echo 6. Optional service installation test...
set /p INSTALL_SERVICE="Install service for test? (Y/N): "
if /i "!INSTALL_SERVICE!"=="Y" (
    echo.
    echo Installing service...
    
    REM Check installutil
    where installutil >nul 2>&1
    if %errorLevel% equ 0 (
        echo Using installutil to install service...
        installutil "%OUTPUT_DIR%\%PROJECT_NAME%.exe"
        
        if %errorLevel% equ 0 (
            echo [OK] Service installed successfully
            
            echo.
            echo Starting service...
            sc start %SERVICE_NAME%
            timeout /t 5 /nobreak >nul
            
            echo.
            echo Checking service status...
            sc query %SERVICE_NAME%
            
            echo.
            set /p UNINSTALL_SERVICE="Stop and uninstall service? (Y/N): "
            if /i "!UNINSTALL_SERVICE!"=="Y" (
                echo.
                echo Stopping service...
                sc stop %SERVICE_NAME%
                timeout /t 3 /nobreak >nul
                
                echo Uninstalling service...
                installutil /u "%OUTPUT_DIR%\%PROJECT_NAME%.exe"
                echo [OK] Service uninstalled
            )
        ) else (
            echo [ERROR] Service installation failed
        )
    ) else (
        echo [INFO] installutil not found, using sc command...
        echo Creating service...
        sc create %SERVICE_NAME% binPath= "%cd%\%OUTPUT_DIR%\%PROJECT_NAME%.exe" start= auto DisplayName= "CyberCafe USB Manager"
        
        if %errorLevel% equ 0 (
            echo [OK] Service created successfully
            
            echo Starting service...
            sc start %SERVICE_NAME%
            timeout /t 5 /nobreak >nul
            
            echo Checking service status...
            sc query %SERVICE_NAME%
            
            echo.
            set /p DELETE_SERVICE="Stop and delete service? (Y/N): "
            if /i "!DELETE_SERVICE!"=="Y" (
                echo.
                echo Stopping service...
                sc stop %SERVICE_NAME%
                timeout /t 3 /nobreak >nul
                
                echo Deleting service...
                sc delete %SERVICE_NAME%
                echo [OK] Service deleted
            )
        ) else (
            echo [ERROR] Service creation failed
        )
    )
) else (
    echo Skipping service installation test
)

REM Generate test report
echo.
echo 7. Generating test report...
set REPORT_FILE=test_report_%date:~0,4%%date:~5,2%%date:~8,2%.txt
(
    echo ========================================
    echo CyberCafe USB Manager Test Report
    echo Generated: %date% %time%
    echo ========================================
    echo.
    echo 1. Build tool: !BUILD_TOOL!
    if "!BUILD_TOOL!"=="msbuild" (
        echo   Path: !MSBUILD_PATH!
    ) else (
        echo   Path: !DOTNET_PATH!
    )
    echo.
    echo 2. Build result: SUCCESS
    echo   Configuration: %CONFIGURATION%
    echo   Output file: %PROJECT_NAME%.exe (!EXE_SIZE! bytes)
    echo.
    echo 3. Next steps:
    echo   - Test in actual cybercafe environment
    echo   - Test USB device recognition
    echo   - Test driver installation
    echo   - Test brand software auto-launch
) > "%REPORT_FILE%"

echo [OK] Test report generated: %REPORT_FILE%

REM Show next steps
echo.
echo ========================================
echo Test Complete - Next Steps
echo ========================================
echo.
echo 1. Check output files:
echo    Directory: %cd%\%OUTPUT_DIR%
echo    Main program: %PROJECT_NAME%.exe
echo.
echo 2. Manual testing suggestions:
echo   - Run program in console mode
echo   - Install service for background testing
echo   - Check Event Viewer logs
echo.
echo 3. Real environment testing:
echo   - Deploy on cybercafe test machine
echo   - Test real USB device recognition
echo   - Test with Shunwang system
echo.
echo 4. View detailed test report: %REPORT_FILE%
echo.

pause
exit /b 0