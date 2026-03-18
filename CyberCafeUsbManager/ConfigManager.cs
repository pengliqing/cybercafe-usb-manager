using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;

namespace CyberCafeUsbManager
{
    /// <summary>
    /// 配置管理器
    /// </summary>
    public class ConfigManager
    {
        private const string ConfigFileName = "config.json";
        private const string DatabaseFileName = "device_database.json";
        private static readonly string AppDataPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),
            "CyberCafeUsbManager");
        
        private Config _config;
        private DeviceDatabase _deviceDatabase;
        private DateTime _lastConfigUpdateTime;
        private readonly object _lockObject = new object();

        /// <summary>
        /// 是否自动安装驱动
        /// </summary>
        public bool AutoInstallDrivers => _config?.AutoInstallDrivers ?? true;

        /// <summary>
        /// 是否自动启动软件
        /// </summary>
        public bool AutoLaunchSoftware => _config?.AutoLaunchSoftware ?? true;

        /// <summary>
        /// 监控间隔（毫秒）
        /// </summary>
        public int MonitorInterval => _config?.MonitorInterval ?? 5000;

        /// <summary>
        /// 支持的品牌列表
        /// </summary>
        public HashSet<string> SupportedBrands => new HashSet<string>(
            _config?.Brands ?? new[] { "Logitech", "Razer", "SteelSeries", "Corsair" });

        /// <summary>
        /// 构造函数
        /// </summary>
        public ConfigManager()
        {
            EnsureAppDataDirectory();
            LoadConfig();
            LoadDeviceDatabase();
        }

        /// <summary>
        /// 确保应用程序数据目录存在
        /// </summary>
        private void EnsureAppDataDirectory()
        {
            try
            {
                if (!Directory.Exists(AppDataPath))
                {
                    Directory.CreateDirectory(AppDataPath);
                }
                
                // 创建子目录
                var logsPath = Path.Combine(AppDataPath, "logs");
                var driversPath = Path.Combine(AppDataPath, "drivers");
                
                if (!Directory.Exists(logsPath))
                    Directory.CreateDirectory(logsPath);
                
                if (!Directory.Exists(driversPath))
                    Directory.CreateDirectory(driversPath);
            }
            catch (Exception ex)
            {
                // 如果无法创建目录，使用当前目录
                AppDataPath = Directory.GetCurrentDirectory();
            }
        }

        /// <summary>
        /// 加载配置
        /// </summary>
        public void LoadConfig()
        {
            lock (_lockObject)
            {
                try
                {
                    var configPath = Path.Combine(AppDataPath, ConfigFileName);
                    
                    if (File.Exists(configPath))
                    {
                        var json = File.ReadAllText(configPath);
                        _config = JsonConvert.DeserializeObject<Config>(json);
                        _lastConfigUpdateTime = File.GetLastWriteTime(configPath);
                    }
                    else
                    {
                        // 创建默认配置
                        _config = CreateDefaultConfig();
                        SaveConfig();
                    }
                }
                catch (Exception)
                {
                    // 如果配置文件损坏，使用默认配置
                    _config = CreateDefaultConfig();
                }
            }
        }

        /// <summary>
        /// 保存配置
        /// </summary>
        public void SaveConfig()
        {
            lock (_lockObject)
            {
                try
                {
                    var configPath = Path.Combine(AppDataPath, ConfigFileName);
                    var json = JsonConvert.SerializeObject(_config, Formatting.Indented);
                    File.WriteAllText(configPath, json);
                    _lastConfigUpdateTime = File.GetLastWriteTime(configPath);
                }
                catch (Exception)
                {
                    // 保存失败，忽略
                }
            }
        }

        /// <summary>
        /// 检查配置更新
        /// </summary>
        public void CheckForConfigUpdates()
        {
            lock (_lockObject)
            {
                try
                {
                    var configPath = Path.Combine(AppDataPath, ConfigFileName);
                    if (File.Exists(configPath))
                    {
                        var lastWriteTime = File.GetLastWriteTime(configPath);
                        if (lastWriteTime > _lastConfigUpdateTime)
                        {
                            LoadConfig();
                        }
                    }
                }
                catch (Exception)
                {
                    // 忽略检查错误
                }
            }
        }

        /// <summary>
        /// 加载设备数据库
        /// </summary>
        public void LoadDeviceDatabase()
        {
            lock (_lockObject)
            {
                try
                {
                    // 首先尝试加载内置数据库
                    var builtInDb = LoadEmbeddedDatabase();
                    _deviceDatabase = builtInDb;

                    // 然后尝试加载用户自定义数据库（如果存在）
                    var userDbPath = Path.Combine(AppDataPath, DatabaseFileName);
                    if (File.Exists(userDbPath))
                    {
                        var userJson = File.ReadAllText(userDbPath);
                        var userDb = JsonConvert.DeserializeObject<DeviceDatabase>(userJson);
                        
                        // 合并数据库（用户定义优先）
                        MergeDatabases(userDb);
                    }
                }
                catch (Exception)
                {
                    // 如果数据库加载失败，使用内置数据库
                    _deviceDatabase = LoadEmbeddedDatabase();
                }
            }
        }

        /// <summary>
        /// 加载内置设备数据库
        /// </summary>
        private DeviceDatabase LoadEmbeddedDatabase()
        {
            // 在实际项目中，这里可以从嵌入式资源加载
            // 这里使用硬编码的常见设备数据
            
            return new DeviceDatabase
            {
                Version = "1.0",
                UpdateDate = "2026-03-16",
                Vendors = new List<VendorInfo>
                {
                    new VendorInfo
                    {
                        Vid = "046D",
                        Name = "Logitech",
                        Software = "Logitech G Hub",
                        SoftwarePaths = new List<string>
                        {
                            @"C:\Program Files\Logitech Gaming Software\LGS.exe",
                            @"C:\Program Files\Logitech\Gaming Software\LGS.exe",
                            @"C:\Program Files\Logitech G Hub\lghub.exe"
                        }
                    },
                    new VendorInfo
                    {
                        Vid = "1532",
                        Name = "Razer",
                        Software = "Razer Synapse",
                        SoftwarePaths = new List<string>
                        {
                            @"C:\Program Files (x86)\Razer\Synapse\Razer Synapse.exe",
                            @"C:\Program Files\Razer\Synapse\Razer Synapse.exe"
                        }
                    },
                    new VendorInfo
                    {
                        Vid = "1038",
                        Name = "SteelSeries",
                        Software = "SteelSeries Engine",
                        SoftwarePaths = new List<string>
                        {
                            @"C:\Program Files\SteelSeries\Engine\SteelSeriesEngine.exe",
                            @"C:\Program Files\SteelSeries\GG\SteelSeriesGG.exe"
                        }
                    },
                    new VendorInfo
                    {
                        Vid = "1B1C",
                        Name = "Corsair",
                        Software = "Corsair iCUE",
                        SoftwarePaths = new List<string>
                        {
                            @"C:\Program Files (x86)\Corsair\Corsair iCUE Software\iCUE.exe",
                            @"C:\Program Files\Corsair\Corsair iCUE Software\iCUE.exe"
                        }
                    }
                }
            };
        }

        /// <summary>
        /// 合并数据库
        /// </summary>
        private void MergeDatabases(DeviceDatabase userDb)
        {
            if (userDb == null || userDb.Vendors == null)
                return;

            foreach (var userVendor in userDb.Vendors)
            {
                var existingVendor = _deviceDatabase.Vendors.FirstOrDefault(v => v.Vid == userVendor.Vid);
                if (existingVendor != null)
                {
                    // 更新现有厂商信息
                    existingVendor.Name = userVendor.Name ?? existingVendor.Name;
                    existingVendor.Software = userVendor.Software ?? existingVendor.Software;
                    
                    // 合并软件路径
                    if (userVendor.SoftwarePaths != null)
                    {
                        existingVendor.SoftwarePaths = existingVendor.SoftwarePaths
                            .Concat(userVendor.SoftwarePaths)
                            .Distinct()
                            .ToList();
                    }
                    
                    // 合并设备列表
                    if (userVendor.Devices != null)
                    {
                        existingVendor.Devices = existingVendor.Devices
                            .Concat(userVendor.Devices)
                            .GroupBy(d => d.Pid)
                            .Select(g => g.First())
                            .ToList();
                    }
                }
                else
                {
                    // 添加新厂商
                    _deviceDatabase.Vendors.Add(userVendor);
                }
            }
        }

        /// <summary>
        /// 检查是否为支持的品牌
        /// </summary>
        public bool IsSupportedBrand(string vendorId)
        {
            if (string.IsNullOrEmpty(vendorId))
                return false;

            // 检查是否在支持的品牌列表中
            var vendor = _deviceDatabase.Vendors.FirstOrDefault(v => v.Vid == vendorId.ToUpper());
            if (vendor == null)
                return false;

            // 检查是否在配置的品牌白名单中
            return SupportedBrands.Contains(vendor.Name, StringComparer.OrdinalIgnoreCase);
        }

        /// <summary>
        /// 根据VID获取厂商信息
        /// </summary>
        public VendorInfo GetVendorInfo(string vendorId)
        {
            return _deviceDatabase.Vendors.FirstOrDefault(v => v.Vid == vendorId.ToUpper());
        }

        /// <summary>
        /// 根据VID和PID获取设备信息
        /// </summary>
        public DeviceInfo GetDeviceInfo(string vendorId, string productId)
        {
            var vendor = GetVendorInfo(vendorId);
            if (vendor?.Devices == null)
                return null;

            return vendor.Devices.FirstOrDefault(d => d.Pid == productId.ToUpper());
        }

        /// <summary>
        /// 获取驱动程序路径
        /// </summary>
        public string GetDriverPath(string vendorId, string productId)
        {
            var driversPath = Path.Combine(AppDataPath, "drivers");
            var vendorPath = Path.Combine(driversPath, vendorId);
            
            // 查找inf文件
            if (Directory.Exists(vendorPath))
            {
                var infFiles = Directory.GetFiles(vendorPath, "*.inf", SearchOption.AllDirectories);
                if (infFiles.Length > 0)
                {
                    // 可以根据PID选择特定的驱动文件
                    // 这里简化处理，返回第一个inf文件
                    return infFiles[0];
                }
            }
            
            return null;
        }

        /// <summary>
        /// 创建默认配置
        /// </summary>
        private Config CreateDefaultConfig()
        {
            return new Config
            {
                MonitorInterval = 5000,
                LogLevel = "Info",
                Brands = new List<string> { "Logitech", "Razer", "SteelSeries", "Corsair" },
                AutoInstallDrivers = true,
                AutoLaunchSoftware = true,
                DriverRepositoryPath = Path.Combine(AppDataPath, "drivers"),
                Whitelist = new List<string>(),
                Blacklist = new List<string>(),
                EnableDebugLogging = false
            };
        }

        /// <summary>
        /// 配置类
        /// </summary>
        public class Config
        {
            public int MonitorInterval { get; set; }
            public string LogLevel { get; set; }
            public List<string> Brands { get; set; }
            public bool AutoInstallDrivers { get; set; }
            public bool AutoLaunchSoftware { get; set; }
            public string DriverRepositoryPath { get; set; }
            public List<string> Whitelist { get; set; }
            public List<string> Blacklist { get; set; }
            public bool EnableDebugLogging { get; set; }
        }

        /// <summary>
        /// 设备数据库
        /// </summary>
        public class DeviceDatabase
        {
            public string Version { get; set; }
            public string UpdateDate { get; set; }
            public List<VendorInfo> Vendors { get; set; }
        }

        /// <summary>
        /// 厂商信息
        /// </summary>
        public class VendorInfo
        {
            public string Vid { get; set; }
            public string Name { get; set; }
            public string Software { get; set; }
            public List<string> SoftwarePaths { get; set; }
            public List<DeviceInfo> Devices { get; set; }
        }

        /// <summary>
        /// 设备信息
        /// </summary>
        public class DeviceInfo
        {
            public string Pid { get; set; }
            public string Name { get; set; }
            public string Type { get; set; }
            public string Model { get; set; }
        }
    }
}