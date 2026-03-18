# 网吧USB驱动安装示例脚本
# 适用于Windows 10系统
# 需要管理员权限运行

param(
    [string]$DriverPath = "",
    [string]$DeviceID = ""
)

function Test-Administrator {
    # 检查是否以管理员身份运行
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-USBDeviceInfo {
    # 获取USB设备信息
    Write-Host "扫描USB设备..." -ForegroundColor Cyan
    
    $devices = Get-PnpDevice -PresentOnly | Where-Object {
        $_.InstanceId -like "*USB*" -or $_.InstanceId -like "*HID*"
    }
    
    Write-Host "找到 $($devices.Count) 个USB设备" -ForegroundColor Green
    
    $keyboardMice = @()
    foreach ($device in $devices) {
        $desc = $device.FriendlyName
        if ($desc -match "键盘|鼠标|Keyboard|Mouse|Razer|Logitech|SteelSeries|Corsair") {
            $deviceInfo = @{
                FriendlyName = $device.FriendlyName
                InstanceId = $device.InstanceId
                Status = $device.Status
                Class = $device.Class
            }
            $keyboardMice += New-Object PSObject -Property $deviceInfo
        }
    }
    
    return $keyboardMice
}

function Install-Driver {
    param(
        [string]$InfPath,
        [string]$DeviceInstanceId
    )
    
    Write-Host "正在安装驱动: $InfPath" -ForegroundColor Yellow
    
    # 方法1: 使用pnputil（推荐）
    try {
        $result = pnputil /add-driver $InfPath /install
        Write-Host "pnputil执行结果:" -ForegroundColor Cyan
        $result | ForEach-Object { Write-Host "  $_" }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "驱动安装成功" -ForegroundColor Green
            return $true
        } else {
            Write-Host "驱动安装失败，错误码: $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "pnputil执行异常: $_" -ForegroundColor Red
        return $false
    }
}

function Get-DriverByVendor {
    param(
        [string]$VendorId
    )
    
    # 根据VID查找驱动路径（示例映射）
    $driverMap = @{
        "046D" = "Drivers\Logitech"  # 罗技
        "1532" = "Drivers\Razer"     # 雷蛇
        "1038" = "Drivers\SteelSeries" # 赛睿
        "1B1C" = "Drivers\Corsair"   # 海盗船
        "045E" = "Drivers\Microsoft" # 微软
    }
    
    if ($driverMap.ContainsKey($VendorId)) {
        $driverFolder = $driverMap[$VendorId]
        # 在实际应用中，这里应该搜索文件夹中的inf文件
        return "$driverFolder\driver.inf"
    }
    
    return $null
}

function Extract-VID-PID {
    param(
        [string]$InstanceId
    )
    
    # 从设备实例ID中提取VID和PID
    # 格式示例: USB\VID_046D&PID_C08B\...
    
    $vidPattern = "VID_([0-9A-F]{4})"
    $pidPattern = "PID_([0-9A-F]{4})"
    
    $vidMatch = [regex]::Match($InstanceId, $vidPattern)
    $pidMatch = [regex]::Match($InstanceId, $pidPattern)
    
    $result = @{
        VID = if ($vidMatch.Success) { $vidMatch.Groups[1].Value } else { $null }
        PID = if ($pidMatch.Success) { $pidMatch.Groups[1].Value } else { $null }
    }
    
    return $result
}

function Start-BrandSoftware {
    param(
        [string]$VendorId
    )
    
    # 根据厂商ID启动对应的品牌软件
    $softwareMap = @{
        "046D" = @{  # 罗技
            Name = "Logitech G Hub";
            Path = "C:\Program Files\Logitech Gaming Software\LGS.exe";
            AlternativePath = "C:\Program Files\Logitech\Gaming Software\LGS.exe"
        }
        "1532" = @{  # 雷蛇
            Name = "Razer Synapse";
            Path = "C:\Program Files (x86)\Razer\Synapse\Razer Synapse.exe";
            AlternativePath = "C:\Program Files\Razer\Synapse\Razer Synapse.exe"
        }
        "1038" = @{  # 赛睿
            Name = "SteelSeries Engine";
            Path = "C:\Program Files\SteelSeries\Engine\SteelSeriesEngine.exe"
        }
        "1B1C" = @{  # 海盗船
            Name = "Corsair iCUE";
            Path = "C:\Program Files (x86)\Corsair\Corsair iCUE Software\iCUE.exe"
        }
    }
    
    if ($softwareMap.ContainsKey($VendorId)) {
        $software = $softwareMap[$VendorId]
        
        Write-Host "尝试启动 $($software.Name)..." -ForegroundColor Cyan
        
        # 尝试主要路径
        if (Test-Path $software.Path) {
            Start-Process -FilePath $software.Path -WindowStyle Minimized
            Write-Host "$($software.Name) 已启动" -ForegroundColor Green
            return $true
        }
        # 尝试备用路径
        elseif ($software.AlternativePath -and (Test-Path $software.AlternativePath)) {
            Start-Process -FilePath $software.AlternativePath -WindowStyle Minimized
            Write-Host "$($software.Name) 已启动（备用路径）" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "$($software.Name) 未找到，请检查是否已安装" -ForegroundColor Yellow
            return $false
        }
    }
    
    Write-Host "未找到厂商 $VendorId 对应的软件配置" -ForegroundColor Yellow
    return $false
}

# 主程序
Write-Host "`n网吧USB设备管理脚本 v0.1" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta

# 检查管理员权限
if (-not (Test-Administrator)) {
    Write-Host "错误: 请以管理员身份运行此脚本" -ForegroundColor Red
    Write-Host "右键点击PowerShell，选择'以管理员身份运行'" -ForegroundColor Yellow
    exit 1
}

Write-Host "管理员权限确认" -ForegroundColor Green

# 扫描USB设备
$devices = Get-USBDeviceInfo

if ($devices.Count -eq 0) {
    Write-Host "未找到键盘或鼠标设备" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n找到以下键盘/鼠标设备:" -ForegroundColor Cyan
foreach ($device in $devices) {
    Write-Host "  - $($device.FriendlyName)" -ForegroundColor White
    Write-Host "    状态: $($device.Status)" -ForegroundColor Gray
    Write-Host "    实例ID: $($device.InstanceId)" -ForegroundColor Gray
    
    # 提取VID/PID
    $ids = Extract-VID-PID -InstanceId $device.InstanceId
    if ($ids.VID) {
        Write-Host "    VID: $($ids.VID)" -ForegroundColor Gray
    }
    if ($ids.PID) {
        Write-Host "    PID: $($ids.PID)" -ForegroundColor Gray
    }
    Write-Host ""
}

# 示例：为每个设备尝试安装驱动和启动软件
foreach ($device in $devices) {
    $ids = Extract-VID-PID -InstanceId $device.InstanceId
    
    if ($ids.VID) {
        Write-Host "`n处理设备: $($device.FriendlyName)" -ForegroundColor Cyan
        Write-Host "厂商ID: $($ids.VID)" -ForegroundColor Cyan
        
        # 1. 尝试安装驱动
        $driverPath = Get-DriverByVendor -VendorId $ids.VID
        if ($driverPath -and (Test-Path $driverPath)) {
            Write-Host "找到驱动: $driverPath" -ForegroundColor Yellow
            $installResult = Install-Driver -InfPath $driverPath -DeviceInstanceId $device.InstanceId
        }
        else {
            Write-Host "未找到预置驱动，可能需要在线下载" -ForegroundColor Yellow
        }
        
        # 2. 尝试启动品牌软件
        $startResult = Start-BrandSoftware -VendorId $ids.VID
        
        Write-Host "处理完成" -ForegroundColor Green
        Write-Host "-" * 40
    }
}

Write-Host "`n脚本执行完成" -ForegroundColor Green
Write-Host "建议: 在实际应用中，需要建立完整的驱动库和软件路径数据库" -ForegroundColor Yellow
Write-Host "      并处理Windows驱动签名验证等安全要求" -ForegroundColor Yellow