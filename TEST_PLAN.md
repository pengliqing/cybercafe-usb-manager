# 网吧USB管理软件 - 测试计划

## 测试目标
1. 验证C#代码在Windows 10环境编译通过
2. 测试Windows服务安装、启动、停止、卸载
3. 验证USB设备识别逻辑（模拟）
4. 测试驱动安装功能（模拟）
5. 验证品牌软件自动启动功能
6. 测试顺网系统集成（基础）

## 测试环境需求
- **操作系统**: Windows 10 (64位)
- **.NET框架**: .NET Framework 4.7.2+
- **开发工具**: Visual Studio 2019+ 或 .NET SDK
- **管理员权限**: 需要（安装服务、驱动）
- **磁盘空间**: 至少10GB可用空间
- **内存**: 4GB+ 推荐

## 测试方案选择

### 方案A：云Windows实例（推荐）
**优点**: 快速、干净、无需本地资源
**成本**: 约2-5元（按量计费，测试完即删）

**步骤**:
1. 创建阿里云/腾讯云Windows Server 2022按量实例
   - 配置: 2核4GB，系统盘40GB
   - 区域: 选择最近的
   - 网络: 按需配置公网IP

2. 远程桌面连接
   - 使用RDP客户端连接
   - 用户名: Administrator
   - 密码: 实例创建时设置

3. 安装开发环境
   ```powershell
   # 安装 Chocolatey (Windows包管理器)
   Set-ExecutionPolicy Bypass -Scope Process -Force
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   
   # 安装 .NET SDK 和编译工具
   choco install dotnet-sdk visualstudio2019buildtools -y
   ```

4. 复制项目文件
   - 将 `cybercafe-usb-manager` 文件夹上传到云实例
   - 或使用git克隆

5. 执行测试套件

### 方案B：本地Windows虚拟机
**优点**: 完全控制，可重复测试
**要求**: 本地有虚拟化软件和Windows ISO

**步骤**:
1. 安装虚拟化软件
   - VirtualBox (免费)
   - VMware Workstation Player (免费个人版)
   - Hyper-V (Windows专业版内置)

2. 创建Windows 10虚拟机
   - 分配: 2核CPU, 4GB内存, 50GB磁盘
   - 安装Windows 10系统
   - 安装VirtualBox增强工具/VMware Tools

3. 安装开发环境（同方案A步骤3）

4. 执行测试套件

### 方案C：借用实体Windows电脑
**优点**: 性能最好，无需虚拟化开销
**要求**: 有可用的Windows 10电脑

**步骤**:
1. 确保电脑满足需求
2. 安装开发环境
3. 执行测试套件

## 详细测试步骤

### 阶段1：环境准备
```powershell
# 1. 验证Windows版本和.NET框架
systeminfo | findstr /B /C:"OS 名称" /C:"OS 版本"
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name version -EA 0 | Where version -Like "4.7*" | Select -ExpandProperty version

# 2. 安装必要工具（如果使用Chocolatey）
choco install git vscode 7zip -y

# 3. 获取项目代码
git clone <repository-url>
# 或手动复制项目文件夹
```

### 阶段2：编译测试
```powershell
# 进入项目目录
cd cybercafe-usb-manager

# 方法1: 使用Visual Studio（如果有）
# 双击 CyberCafeUsbManager.sln 打开，编译Release版本

# 方法2: 使用MSBuild（需要VS Build Tools）
msbuild CyberCafeUsbManager.sln /p:Configuration=Release /p:Platform="Any CPU"

# 方法3: 使用dotnet CLI
dotnet build CyberCafeUsbManager.sln -c Release

# 验证输出
dir "CyberCafeUsbManager\bin\Release\"
# 应该看到 CyberCafeUsbManager.exe (大小 > 50KB)
```

### 阶段3：服务功能测试
```powershell
# 1. 安装服务（需要管理员权限）
cd CyberCafeUsbManager\bin\Release
.\CyberCafeUsbManager.exe  # 控制台模式测试

# 2. 实际安装服务
# 使用 installutil（.NET框架工具）
installutil.exe CyberCafeUsbManager.exe

# 或使用sc命令
sc create CyberCafeUsbManager binPath= "C:\完整路径\CyberCafeUsbManager.exe" start= auto DisplayName= "CyberCafe USB Manager"

# 3. 启动服务
sc start CyberCafeUsbManager
sc query CyberCafeUsbManager  # 查看状态

# 4. 测试服务日志
# 查看事件查看器 → 应用程序和服务日志 → CyberCafeUsbManager

# 5. 停止和卸载服务
sc stop CyberCafeUsbManager
sc delete CyberCafeUsbManager
# 或使用 installutil /u
```

### 阶段4：功能模拟测试
```powershell
# 1. USB设备识别测试
# 创建测试脚本模拟USB设备插拔事件
# 检查服务是否能正确响应

# 2. 驱动安装测试（模拟）
# 创建虚拟驱动包，测试安装逻辑

# 3. 软件启动测试
# 安装一个测试品牌软件（如罗技G Hub测试版）
# 验证自动启动功能

# 4. 配置管理测试
# 修改config.json，测试热重载
```

### 阶段5：顺网集成测试
```powershell
# 1. 研究顺网启动机制
# 检查顺网启动项位置：
# - 注册表: HKCU\Software\Microsoft\Windows\CurrentVersion\Run
# - 系统服务
# - 计划任务

# 2. 测试与顺网共存
# 模拟顺网环境，测试服务稳定性

# 3. 还原系统测试
# 如果可能，测试在还原系统下的持久化方案
```

## 测试用例清单

### 基本功能测试
- [ ] 编译通过，无错误警告
- [ ] EXE文件可执行
- [ ] 服务可安装（installutil/sc）
- [ ] 服务可启动（sc start）
- [ ] 服务可停止（sc stop）
- [ ] 服务可卸载（installutil /u / sc delete）
- [ ] 事件查看器日志正常

### 核心功能测试
- [ ] 配置加载（config.json）
- [ ] USB监控服务启动
- [ ] 设备识别逻辑（模拟VID/PID）
- [ ] 品牌匹配（Logitech, Razer等）
- [ ] 驱动安装调用（模拟）
- [ ] 软件启动调用（模拟）
- [ ] 错误处理（无效设备、网络失败等）

### 集成测试
- [ ] 多设备同时插入模拟
- [ ] 长时间运行稳定性（24小时）
- [ ] 系统重启后服务自启动
- [ ] 与杀毒软件兼容性（Windows Defender）
- [ ] 管理员权限要求验证
- [ ] 网络依赖测试（离线/在线模式）

### 顺网专项测试
- [ ] 顺网环境下服务安装
- [ ] 顺网启动项添加测试
- [ ] 还原系统下的配置持久化
- [ ] 与顺网管理界面兼容性
- [ ] 性能影响评估（CPU/内存占用）

## 测试工具和脚本

### PowerShell测试脚本
```powershell
# test_basic.ps1 - 基础功能测试
Write-Host "=== CyberCafe USB Manager 基础测试 ==="

# 1. 环境检查
$os = (Get-WmiObject Win32_OperatingSystem).Caption
$netVersion = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name version -EA 0 | Where version -Like "4.7*" | Select -ExpandProperty version -First 1

Write-Host "操作系统: $os"
Write-Host ".NET框架: $netVersion"

# 2. 文件检查
$exePath = "CyberCafeUsbManager\bin\Release\CyberCafeUsbManager.exe"
if (Test-Path $exePath) {
    $fileInfo = Get-Item $exePath
    Write-Host "EXE文件大小: $($fileInfo.Length) bytes"
    Write-Host "✅ EXE文件存在"
} else {
    Write-Host "❌ EXE文件不存在"
    exit 1
}

# 3. 服务状态检查（如果已安装）
$service = Get-Service -Name CyberCafeUsbManager -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "服务状态: $($service.Status)"
} else {
    Write-Host "服务未安装"
}
```

### Python模拟测试脚本
```python
# simulate_usb.py - 模拟USB设备插拔
import time
import random

def simulate_device_connection():
    """模拟USB设备连接事件"""
    devices = [
        {"vid": "046D", "pid": "C332", "brand": "Logitech", "name": "G Pro Wireless"},
        {"vid": "1532", "pid": "0043", "brand": "Razer", "name": "DeathAdder V2"},
        {"vid": "1038", "pid": "1729", "brand": "SteelSeries", "name": "Rival 3"},
    ]
    
    # 模拟随机设备连接
    device = random.choice(devices)
    print(f"[模拟] USB设备连接: {device['brand']} {device['name']}")
    print(f"      VID: {device['vid']}, PID: {device['pid']}")
    return device
```

## 问题排查指南

### 常见问题
1. **编译失败**
   - 检查.NET Framework 4.7.2+ 已安装
   - 检查Visual Studio Build Tools
   - 检查项目文件完整性

2. **服务安装失败**
   - 确保以管理员身份运行
   - 检查杀毒软件拦截
   - 查看事件查看器错误日志

3. **服务启动失败**
   - 检查依赖的.NET框架
   - 检查配置文件权限
   - 查看服务详细错误信息

4. **设备识别失败**
   - 检查USB设备VID/PID数据库
   - 验证设备监控服务权限
   - 测试基础USB功能

### 日志位置
1. **Windows事件查看器**
   - 应用程序和服务日志 → CyberCafeUsbManager
2. **文件日志**
   - C:\ProgramData\CyberCafeUsbManager\logs\
3. **控制台输出**
   - 调试模式运行时的控制台输出

## 测试时间预估
- 环境准备: 1-2小时
- 基础测试: 1小时
- 功能测试: 2-3小时
- 集成测试: 2-4小时
- 顺网测试: 2-3小时
- **总计**: 8-13小时

## 测试报告模板
测试完成后，请填写以下报告：

```
测试环境:
- Windows版本: 
- .NET版本: 
- 测试时间: 
- 测试人员: 

测试结果:
- 编译: [通过/失败]
- 服务安装: [通过/失败]
- 基础功能: [通过/失败]
- 核心功能: [通过/失败]
- 集成测试: [通过/失败]
- 顺网兼容: [通过/失败]

发现的问题:
1. 
2. 
3. 

建议:
1. 
2. 
3. 

测试结论: [通过/有条件通过/失败]
```

---

**下一步**: 选择测试方案，准备测试环境，开始执行测试计划。