# CyberCafe USB Manager - C# Windows服务版本

## 项目结构
```
CyberCafeUsbManager/
├── CyberCafeUsbManager.sln          # 解决方案文件
├── CyberCafeUsbManager/              # 主服务项目
│   ├── Program.cs                   # 程序入口
│   ├── UsbMonitorService.cs         # Windows服务主类
│   ├── ProjectInstaller.cs          # 服务安装程序
│   ├── DeviceMonitor.cs             # USB设备监控
│   ├── DriverManager.cs             # 驱动管理
│   ├── SoftwareLauncher.cs          # 软件启动器
│   └── ConfigManager.cs             # 配置管理
├── CyberCafeUsbManager.Tests/       # 单元测试项目
├── Setup/                           # 安装包项目
└── Docs/                            # 文档
```

## 技术栈
- **.NET Framework 4.7.2** (Windows服务兼容性最好)
- **Windows API Code Pack** (USB设备监控)
- **Log4Net** (日志记录)
- **Newtonsoft.Json** (配置管理)

## 编译要求
- Visual Studio 2019+ 或 .NET SDK
- Windows 10 SDK
- 管理员权限（安装服务需要）

## 快速开始
1. 使用Visual Studio打开 `CyberCafeUsbManager.sln`
2. 编译解决方案（Release模式）
3. 以管理员身份运行CMD：`installutil.exe CyberCafeUsbManager.exe`
4. 启动服务：`net start CyberCafeUsbManager`

## 配置说明
服务配置文件：`C:\ProgramData\CyberCafeUsbManager\config.json`
```json
{
  "MonitorInterval": 5000,
  "LogLevel": "Info",
  "Brands": ["Logitech", "Razer", "SteelSeries", "Corsair"],
  "AutoInstallDrivers": true,
  "AutoLaunchSoftware": true,
  "DriverRepositoryPath": "C:\\Drivers\\USB",
  "Whitelist": [],
  "Blacklist": []
}
```

## 日志位置
- 事件查看器：应用程序和服务日志 → CyberCafeUsbManager
- 文件日志：`C:\ProgramData\CyberCafeUsbManager\logs\`

## 开发说明
1. 服务账户：建议使用LocalSystem账户
2. 权限：需要管理员权限安装驱动
3. 测试：使用服务管理器或`sc`命令控制服务
4. 调试：附加到进程`CyberCafeUsbManager.exe`

---
*项目状态：开发中*