# CyberCafe USB Manager - 环境测试脚本
# 在Windows PowerShell中运行（管理员权限）

Write-Host "========================================="
Write-Host "CyberCafe USB Manager 环境测试"
Write-Host "运行时间: $(Get-Date)"
Write-Host "========================================="

# 颜色定义
$success = "✅"
$warning = "⚠️ "
$error = "❌"
$info = "📋"

# 测试结果记录
$testResults = @()

function Test-System {
    Write-Host "`n$info 系统环境检查"
    
    $os = (Get-WmiObject Win32_OperatingSystem).Caption
    $osVersion = [System.Environment]::OSVersion.Version
    $architecture = [System.Environment]::Is64BitOperatingSystem ? "64位" : "32位"
    
    Write-Host "操作系统: $os ($architecture)"
    Write-Host "版本: $osVersion"
    
    # 检查是否为Windows 10或更高
    $isWindows10OrLater = $osVersion.Major -ge 10
    if ($isWindows10OrLater) {
        Write-Host "$success Windows版本符合要求"
        $testResults += @{ Test = "Windows版本"; Result = "通过"; Details = $os }
    } else {
        Write-Host "$error 需要Windows 10或更高版本"
        $testResults += @{ Test = "Windows版本"; Result = "失败"; Details = $os }
    }
}

function Test-DotNet {
    Write-Host "`n$info .NET Framework检查"
    
    $netVersions = @()
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\NET Framework Setup\NDP'
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $versions = Get-ChildItem $path -Recurse | 
                Get-ItemProperty -Name Version, Release -ErrorAction SilentlyContinue | 
                Where-Object { $_.Version } | 
                Select-Object Version, Release
            
            foreach ($ver in $versions) {
                if ($ver.Version -match '^4\.[5-9]|4\.[0-9]{2,}') {
                    $netVersions += $ver.Version
                }
            }
        }
    }
    
    if ($netVersions.Count -gt 0) {
        $latestNet = $netVersions | Sort-Object { [version]$_ } -Descending | Select-Object -First 1
        Write-Host "$success .NET Framework已安装: $latestNet"
        $testResults += @{ Test = ".NET Framework"; Result = "通过"; Details = $latestNet }
    } else {
        Write-Host "$error 未找到.NET Framework 4.5+"
        Write-Host "请安装 .NET Framework 4.7.2 或更高版本"
        $testResults += @{ Test = ".NET Framework"; Result = "失败"; Details = "未找到" }
    }
}

function Test-AdminPrivileges {
    Write-Host "`n$info 管理员权限检查"
    
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-Host "$success 当前以管理员身份运行"
        $testResults += @{ Test = "管理员权限"; Result = "通过"; Details = "是" }
    } else {
        Write-Host "$warning 当前不是管理员身份"
        Write-Host "安装服务和驱动需要管理员权限"
        $testResults += @{ Test = "管理员权限"; Result = "警告"; Details = "否" }
    }
}

function Test-Compiler {
    Write-Host "`n$info 编译工具检查"
    
    $toolsFound = @()
    
    # 检查MSBuild
    $msbuildPaths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe",
        "${env:windir}\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe",
        "${env:windir}\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
    )
    
    foreach ($path in $msbuildPaths) {
        if (Test-Path $path) {
            $toolsFound += "MSBuild: $path"
            break
        }
    }
    
    # 检查dotnet CLI
    $dotnetPath = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($dotnetPath) {
        $dotnetVersion = dotnet --version 2>$null
        if ($dotnetVersion) {
            $toolsFound += "dotnet CLI: $dotnetVersion"
        }
    }
    
    if ($toolsFound.Count -gt 0) {
        Write-Host "$success 找到编译工具:"
        foreach ($tool in $toolsFound) {
            Write-Host "  - $tool"
        }
        $testResults += @{ Test = "编译工具"; Result = "通过"; Details = ($toolsFound -join ", ") }
    } else {
        Write-Host "$warning 未找到编译工具"
        Write-Host "建议安装:"
        Write-Host "  - Visual Studio Build Tools"
        Write-Host "  - 或 .NET SDK"
        $testResults += @{ Test = "编译工具"; Result = "警告"; Details = "未找到" }
    }
}

function Test-USBSupport {
    Write-Host "`n$info USB支持检查"
    
    try {
        $usbControllers = Get-WmiObject Win32_USBController -ErrorAction Stop
        $usbDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Service -eq 'USB' } | Select-Object -First 5
        
        if ($usbControllers) {
            Write-Host "$success 系统支持USB: $($usbControllers.Count)个USB控制器"
            $usbDeviceCount = @($usbDevices).Count
            Write-Host "发现USB设备: $usbDeviceCount个"
            $testResults += @{ Test = "USB支持"; Result = "通过"; Details = "$($usbControllers.Count)控制器, $usbDeviceCount设备" }
        } else {
            Write-Host "$warning 未检测到USB控制器"
            $testResults += @{ Test = "USB支持"; Result = "警告"; Details = "未检测到控制器" }
        }
    } catch {
        Write-Host "$warning USB检查失败: $_"
        $testResults += @{ Test = "USB支持"; Result = "警告"; Details = "检查失败" }
    }
}

function Test-ProjectStructure {
    Write-Host "`n$info 项目结构检查"
    
    $requiredFiles = @(
        "CyberCafeUsbManager.sln",
        "CyberCafeUsbManager\CyberCafeUsbManager.csproj",
        "CyberCafeUsbManager\Program.cs",
        "CyberCafeUsbManager\UsbMonitorService.cs",
        "CyberCafeUsbManager\ProjectInstaller.cs"
    )
    
    $missingFiles = @()
    $presentFiles = @()
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            $presentFiles += $file
        } else {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-Host "$success 项目结构完整"
        foreach ($file in $presentFiles) {
            Write-Host "  ✅ $file"
        }
        $testResults += @{ Test = "项目结构"; Result = "通过"; Details = "完整" }
    } else {
        Write-Host "$error 缺少必要文件:"
        foreach ($file in $missingFiles) {
            Write-Host "  ❌ $file"
        }
        $testResults += @{ Test = "项目结构"; Result = "失败"; Details = "缺少文件" }
    }
}

function Show-Summary {
    Write-Host "`n========================================="
    Write-Host "测试摘要"
    Write-Host "========================================="
    
    $passed = ($testResults | Where-Object { $_.Result -eq "通过" }).Count
    $failed = ($testResults | Where-Object { $_.Result -eq "失败" }).Count
    $warnings = ($testResults | Where-Object { $_.Result -eq "警告" }).Count
    
    Write-Host "总共测试: $($testResults.Count)"
    Write-Host "通过: $passed"
    Write-Host "失败: $failed"
    Write-Host "警告: $warnings"
    
    Write-Host "`n详细结果:"
    foreach ($result in $testResults) {
        $icon = switch ($result.Result) {
            "通过" { $success }
            "失败" { $error }
            "警告" { $warning }
            default { $info }
        }
        Write-Host "$icon $($result.Test): $($result.Result) - $($result.Details)"
    }
    
    Write-Host "`n========================================="
    if ($failed -gt 0) {
        Write-Host "$error 环境检查失败，请修复上述问题"
        return $false
    } elseif ($warnings -gt 0) {
        Write-Host "$warning 环境检查通过，但有警告"
        Write-Host "建议修复警告后再进行编译测试"
        return $true
    } else {
        Write-Host "$success 环境检查全部通过"
        Write-Host "可以开始编译和测试"
        return $true
    }
}

function Show-NextSteps {
    Write-Host "`n========================================="
    Write-Host "后续步骤"
    Write-Host "========================================="
    
    Write-Host "`n1. 编译项目:"
    Write-Host "   # 使用MSBuild"
    Write-Host "   msbuild CyberCafeUsbManager.sln /p:Configuration=Release"
    Write-Host "   "
    Write-Host "   # 或使用dotnet"
    Write-Host "   dotnet build CyberCafeUsbManager.sln -c Release"
    
    Write-Host "`n2. 测试服务（管理员权限）:"
    Write-Host "   cd CyberCafeUsbManager\bin\Release"
    Write-Host "   # 控制台模式测试"
    Write-Host "   .\CyberCafeUsbManager.exe"
    Write-Host "   "
    Write-Host "   # 安装服务"
    Write-Host "   installutil.exe .\CyberCafeUsbManager.exe"
    Write-Host "   "
    Write-Host "   # 或使用sc命令"
    Write-Host "   sc create CyberCafeUsbManager binPath=`"完整路径\CyberCafeUsbManager.exe`" start=auto"
    
    Write-Host "`n3. 查看日志:"
    Write-Host "   - 事件查看器 → 应用程序和服务日志 → CyberCafeUsbManager"
    Write-Host "   - 文件日志: C:\ProgramData\CyberCafeUsbManager\logs\"
    
    Write-Host "`n4. 卸载服务:"
    Write-Host "   installutil.exe /u .\CyberCafeUsbManager.exe"
    Write-Host "   # 或使用sc命令"
    Write-Host "   sc delete CyberCafeUsbManager"
}

# 执行所有测试
Test-System
Test-DotNet
Test-AdminPrivileges
Test-Compiler
Test-USBSupport
Test-ProjectStructure

$envOk = Show-Summary
if ($envOk) {
    Show-NextSteps
}

# 返回退出代码
exit ($failed -gt 0 ? 1 : 0)