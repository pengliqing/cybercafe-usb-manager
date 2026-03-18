using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

namespace CyberCafeUsbManager
{
    /// <summary>
    /// 软件启动器 - 根据设备品牌启动对应的配套程序
    /// </summary>
    public class SoftwareLauncher : IDisposable
    {
        private readonly ConfigManager _configManager;
        private readonly Dictionary<string, BrandSoftwareInfo> _brandSoftwareMap;
        private bool _disposed;

        /// <summary>
        /// 品牌软件信息
        /// </summary>
        private class BrandSoftwareInfo
        {
            public string BrandName { get; set; }
            public List<string> SoftwarePaths { get; set; }
            public List<string> ProcessNames { get; set; }
            public int LaunchDelayMs { get; set; }
            public bool RequireAdmin { get; set; }
        }

        /// <summary>
        /// 构造函数
        /// </summary>
        public SoftwareLauncher(ConfigManager configManager)
        {
            _configManager = configManager ?? throw new ArgumentNullException(nameof(configManager));
            _brandSoftwareMap = InitializeBrandSoftwareMap();
        }

        /// <summary>
        /// 初始化品牌软件映射
        /// </summary>
        private Dictionary<string, BrandSoftwareInfo> InitializeBrandSoftwareMap()
        {
            var map = new Dictionary<string, BrandSoftwareInfo>(StringComparer.OrdinalIgnoreCase)
            {
                // 罗技 (Logitech)
                ["Logitech"] = new BrandSoftwareInfo
                {
                    BrandName = "Logitech",
                    SoftwarePaths = new List<string>
                    {
                        @"C:\Program Files\Logitech Gaming Software\LCore.exe",
                        @"C:\Program Files\Logitech\G HUB\lghub.exe",
                        @"C:\Program Files\Logitech\Options\LogiOptions.exe"
                    },
                    ProcessNames = new List<string> { "lghub", "LCore", "LogiOptions" },
                    LaunchDelayMs = 3000,
                    RequireAdmin = false
                },

                // 雷蛇 (Razer)
                ["Razer"] = new BrandSoftwareInfo
                {
                    BrandName = "Razer",
                    SoftwarePaths = new List<string>
                    {
                        @"C:\Program Files (x86)\Razer\Synapse3\WPFUI\Framework\Razer Synapse 3 Host\Razer Synapse 3.exe",
                        @"C:\Program Files (x86)\Razer\Synapse\RzSynapse.exe"
                    },
                    ProcessNames = new List<string> { "Razer Synapse 3", "RzSynapse" },
                    LaunchDelayMs = 5000,
                    RequireAdmin = false
                },

                // 赛睿 (SteelSeries)
                ["SteelSeries"] = new BrandSoftwareInfo
                {
                    BrandName = "SteelSeries",
                    SoftwarePaths = new List<string>
                    {
                        @"C:\Program Files\SteelSeries\GG\SteelSeriesGG.exe",
                        @"C:\Program Files\SteelSeries\SteelSeries Engine 3\SteelSeriesEngine3.exe"
                    },
                    ProcessNames = new List<string> { "SteelSeriesGG", "SteelSeriesEngine3" },
                    LaunchDelayMs = 2000,
                    RequireAdmin = false
                },

                // 海盗船 (Corsair)
                ["Corsair"] = new BrandSoftwareInfo
                {
                    BrandName = "Corsair",
                    SoftwarePaths = new List<string>
                    {
                        @"C:\Program Files (x86)\Corsair\CORSAIR iCUE 4 Software\iCUE.exe",
                        @"C:\Program Files (x86)\Corsair\CORSAIR iCUE 3 Software\iCUE.exe"
                    },
                    ProcessNames = new List<string> { "iCUE" },
                    LaunchDelayMs = 4000,
                    RequireAdmin = false
                }
            };

            return map;
        }

        /// <summary>
        /// 启动品牌软件
        /// </summary>
        /// <param name="brandName">品牌名称</param>
        /// <returns>启动结果</returns>
        public SoftwareLaunchResult LaunchSoftware(string brandName)
        {
            if (string.IsNullOrEmpty(brandName))
                return SoftwareLaunchResult.Failure("品牌名称不能为空");

            try
            {
                // 检查配置是否允许自动启动软件
                if (!_configManager.AutoLaunchSoftware)
                {
                    return SoftwareLaunchResult.Skipped("配置禁用软件自动启动");
                }

                // 查找品牌信息
                if (!_brandSoftwareMap.TryGetValue(brandName, out var brandInfo))
                {
                    return SoftwareLaunchResult.Failure($"不支持的品牌: {brandName}");
                }

                // 检查软件是否已在运行
                if (IsSoftwareRunning(brandInfo))
                {
                    return SoftwareLaunchResult.Success($"品牌软件已在运行: {brandName}");
                }

                // 查找可执行文件
                string executablePath = FindSoftwareExecutable(brandInfo);
                if (string.IsNullOrEmpty(executablePath))
                {
                    return SoftwareLaunchResult.Failure($"未找到品牌软件: {brandName}");
                }

                // 启动软件
                return StartSoftwareProcess(executablePath, brandInfo);
            }
            catch (Exception ex)
            {
                return SoftwareLaunchResult.Failure($"启动软件失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 检查软件是否已在运行
        /// </summary>
        private bool IsSoftwareRunning(BrandSoftwareInfo brandInfo)
        {
            foreach (var processName in brandInfo.ProcessNames)
            {
                try
                {
                    var processes = Process.GetProcessesByName(processName);
                    if (processes.Length > 0)
                    {
                        return true;
                    }
                }
                catch
                {
                    // 忽略检查错误，继续检查下一个进程
                }
            }
            return false;
        }

        /// <summary>
        /// 查找软件可执行文件
        /// </summary>
        private string FindSoftwareExecutable(BrandSoftwareInfo brandInfo)
        {
            foreach (var path in brandInfo.SoftwarePaths)
            {
                if (File.Exists(path))
                {
                    return path;
                }
            }

            // 尝试在Program Files和Program Files (x86)中搜索
            var programFilesPaths = new[]
            {
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86)
            };

            foreach (var programFilesPath in programFilesPaths)
            {
                foreach (var processName in brandInfo.ProcessNames)
                {
                    var searchPattern = $"*{processName}*.exe";
                    try
                    {
                        var files = Directory.GetFiles(programFilesPath, searchPattern, SearchOption.AllDirectories);
                        if (files.Length > 0)
                        {
                            return files[0]; // 返回第一个找到的文件
                        }
                    }
                    catch
                    {
                        // 忽略搜索错误
                    }
                }
            }

            return null;
        }

        /// <summary>
        /// 启动软件进程
        /// </summary>
        private SoftwareLaunchResult StartSoftwareProcess(string executablePath, BrandSoftwareInfo brandInfo)
        {
            try
            {
                var startInfo = new ProcessStartInfo
                {
                    FileName = executablePath,
                    UseShellExecute = true,
                    WindowStyle = ProcessWindowStyle.Minimized
                };

                if (brandInfo.RequireAdmin)
                {
                    startInfo.Verb = "runas";
                }

                var process = Process.Start(startInfo);
                if (process == null)
                {
                    return SoftwareLaunchResult.Failure($"无法启动进程: {executablePath}");
                }

                // 等待软件初始化
                System.Threading.Thread.Sleep(brandInfo.LaunchDelayMs);

                // 检查进程是否仍在运行
                if (process.HasExited)
                {
                    return SoftwareLaunchResult.Failure($"进程已退出，退出代码: {process.ExitCode}");
                }

                return SoftwareLaunchResult.Success($"成功启动品牌软件: {brandInfo.BrandName}");
            }
            catch (System.ComponentModel.Win32Exception ex) when (ex.NativeErrorCode == 1223)
            {
                // 用户取消UAC提示
                return SoftwareLaunchResult.Failure("用户取消管理员权限请求");
            }
            catch (Exception ex)
            {
                return SoftwareLaunchResult.Failure($"启动进程失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 停止所有品牌软件
        /// </summary>
        public void StopAllSoftware()
        {
            foreach (var brandInfo in _brandSoftwareMap.Values)
            {
                foreach (var processName in brandInfo.ProcessNames)
                {
                    try
                    {
                        var processes = Process.GetProcessesByName(processName);
                        foreach (var process in processes)
                        {
                            try
                            {
                                if (!process.HasExited)
                                {
                                    process.Kill();
                                    process.WaitForExit(5000);
                                }
                            }
                            finally
                            {
                                process.Dispose();
                            }
                        }
                    }
                    catch
                    {
                        // 忽略停止错误
                    }
                }
            }
        }

        /// <summary>
        /// 添加自定义品牌软件
        /// </summary>
        public void AddCustomBrand(string brandName, List<string> softwarePaths, List<string> processNames, int launchDelayMs = 3000, bool requireAdmin = false)
        {
            if (string.IsNullOrEmpty(brandName))
                throw new ArgumentException("品牌名称不能为空", nameof(brandName));

            _brandSoftwareMap[brandName] = new BrandSoftwareInfo
            {
                BrandName = brandName,
                SoftwarePaths = softwarePaths ?? new List<string>(),
                ProcessNames = processNames ?? new List<string>(),
                LaunchDelayMs = launchDelayMs,
                RequireAdmin = requireAdmin
            };
        }

        /// <summary>
        /// 软件启动结果类
        /// </summary>
        public class SoftwareLaunchResult
        {
            public bool Success { get; }
            public string Message { get; }
            public bool Skipped { get; }

            private SoftwareLaunchResult(bool success, string message, bool skipped = false)
            {
                Success = success;
                Message = message;
                Skipped = skipped;
            }

            public static SoftwareLaunchResult Success(string message) => new SoftwareLaunchResult(true, message);
            public static SoftwareLaunchResult Failure(string message) => new SoftwareLaunchResult(false, message);
            public static SoftwareLaunchResult Skipped(string message) => new SoftwareLaunchResult(false, message, true);
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    // 释放托管资源
                }
                _disposed = true;
            }
        }

        ~SoftwareLauncher()
        {
            Dispose(false);
        }
    }
}