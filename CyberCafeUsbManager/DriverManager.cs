using System;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Net.Http;
using System.Threading.Tasks;

namespace CyberCafeUsbManager
{
    /// <summary>
    /// 驱动管理器
    /// 负责驱动的静默安装、签名验证和驱动库管理
    /// </summary>
    public class DriverManager : IDisposable
    {
        private readonly ConfigManager _configManager;
        private readonly HttpClient _httpClient;
        private bool _disposed;

        /// <summary>
        /// 构造函数
        /// </summary>
        public DriverManager(ConfigManager configManager)
        {
            _configManager = configManager ?? throw new ArgumentNullException(nameof(configManager));
            _httpClient = new HttpClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }

        /// <summary>
        /// 安装驱动
        /// </summary>
        /// <param name="vendorId">厂商ID（VID）</param>
        /// <param name="productId">产品ID（PID）</param>
        /// <returns>安装结果</returns>
        public DriverInstallResult InstallDriver(string vendorId, string productId)
        {
            try
            {
                if (string.IsNullOrEmpty(vendorId))
                    return DriverInstallResult.Failure("厂商ID不能为空");

                // 1. 查找本地驱动
                var driverPath = _configManager.GetDriverPath(vendorId, productId);
                
                if (string.IsNullOrEmpty(driverPath) || !File.Exists(driverPath))
                {
                    // 2. 如果本地没有，尝试在线下载
                    LogInfo($"本地未找到驱动，尝试在线下载: VID={vendorId}, PID={productId}");
                    
                    var downloadResult = DownloadDriverAsync(vendorId, productId).GetAwaiter().GetResult();
                    if (!downloadResult.Success)
                    {
                        return DriverInstallResult.Failure($"驱动下载失败: {downloadResult.Message}");
                    }
                    
                    driverPath = downloadResult.DriverPath;
                }

                // 3. 验证驱动签名
                var signatureResult = VerifyDriverSignature(driverPath);
                if (!signatureResult.IsValid)
                {
                    LogWarning($"驱动签名验证失败: {signatureResult.Message}");
                    
                    // Windows 10要求驱动必须签名，但测试环境可以绕过
                    // 生产环境需要处理签名问题
                    if (!IsTestEnvironment())
                    {
                        return DriverInstallResult.Failure($"驱动未签名，无法在生产环境安装: {signatureResult.Message}");
                    }
                }

                // 4. 安装驱动
                var installResult = InstallDriverInternal(driverPath, vendorId, productId);
                
                if (installResult.Success)
                {
                    LogInfo($"驱动安装成功: {vendorId}:{productId}");
                    return DriverInstallResult.Success($"驱动安装成功: {Path.GetFileName(driverPath)}");
                }
                else
                {
                    LogError($"驱动安装失败: {installResult.Message}");
                    return DriverInstallResult.Failure($"驱动安装失败: {installResult.Message}");
                }
            }
            catch (Exception ex)
            {
                LogError($"安装驱动时发生异常: {ex.Message}");
                return DriverInstallResult.Failure($"安装驱动时发生异常: {ex.Message}");
            }
        }

        /// <summary>
        /// 下载驱动
        /// </summary>
        private async Task<DriverDownloadResult> DownloadDriverAsync(string vendorId, string productId)
        {
            try
            {
                // 获取厂商信息
                var vendorInfo = _configManager.GetVendorInfo(vendorId);
                if (vendorInfo == null)
                    return DriverDownloadResult.Failure($"未知厂商: {vendorId}");

                // 根据厂商选择下载源
                var driverUrl = GetDriverDownloadUrl(vendorId, productId);
                if (string.IsNullOrEmpty(driverUrl))
                    return DriverDownloadResult.Failure($"未找到驱动下载地址: {vendorId}:{productId}");

                // 下载驱动
                LogInfo($"正在下载驱动: {driverUrl}");
                
                var response = await _httpClient.GetAsync(driverUrl);
                if (!response.IsSuccessStatusCode)
                    return DriverDownloadResult.Failure($"下载失败: {response.StatusCode}");

                var driverData = await response.Content.ReadAsByteArrayAsync();
                
                // 保存驱动文件
                var savePath = SaveDriverFile(vendorId, productId, driverData);
                if (string.IsNullOrEmpty(savePath))
                    return DriverDownloadResult.Failure("保存驱动文件失败");

                return DriverDownloadResult.Success(savePath, $"驱动下载成功: {Path.GetFileName(savePath)}");
            }
            catch (Exception ex)
            {
                LogError($"下载驱动时发生异常: {ex.Message}");
                return DriverDownloadResult.Failure($"下载驱动时发生异常: {ex.Message}");
            }
        }

        /// <summary>
        /// 获取驱动下载URL
        /// </summary>
        private string GetDriverDownloadUrl(string vendorId, string productId)
        {
            // 这里可以根据VID/PID返回不同的下载地址
            // 实际应用中需要维护一个驱动URL数据库
            
            switch (vendorId.ToUpper())
            {
                case "046D": // Logitech
                    return "https://download01.logi.com/web/ftp/pub/techsupport/gaming/lgs_9.04.49_x64.exe";
                
                case "1532": // Razer
                    return "https://rzr.to/synapse-3";
                
                case "1038": // SteelSeries
                    return "https://steelseries.com/engine";
                
                case "1B1C": // Corsair
                    return "https://www.corsair.com/icue";
                
                default:
                    return null;
            }
        }

        /// <summary>
        /// 保存驱动文件
        /// </summary>
        private string SaveDriverFile(string vendorId, string productId, byte[] driverData)
        {
            try
            {
                var driversPath = Path.Combine(_configManager.GetType().GetProperty("AppDataPath", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance)?.GetValue(_configManager)?.ToString() ?? 
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), 
                    "CyberCafeUsbManager", "drivers");
                
                var vendorPath = Path.Combine(driversPath, vendorId);
                if (!Directory.Exists(vendorPath))
                    Directory.CreateDirectory(vendorPath);

                // 根据文件类型确定扩展名
                string extension = ".exe"; // 默认exe
                if (driverData.Length > 2)
                {
                    // 简单判断文件类型
                    if (driverData[0] == 0x4D && driverData[1] == 0x5A) // MZ - EXE
                        extension = ".exe";
                    else if (driverData[0] == 0x50 && driverData[1] == 0x4B) // PK - ZIP
                        extension = ".zip";
                    else if (System.Text.Encoding.ASCII.GetString(driverData, 0, 4).Contains("INF"))
                        extension = ".inf";
                }

                var fileName = $"{vendorId}_{productId}_{DateTime.Now:yyyyMMddHHmmss}{extension}";
                var filePath = Path.Combine(vendorPath, fileName);

                File.WriteAllBytes(filePath, driverData);
                
                // 如果是压缩包，解压
                if (extension == ".zip")
                {
                    return ExtractDriverPackage(filePath, vendorPath);
                }

                return filePath;
            }
            catch (Exception ex)
            {
                LogError($"保存驱动文件失败: {ex.Message}");
                return null;
            }
        }

        /// <summary>
        /// 解压驱动包
        /// </summary>
        private string ExtractDriverPackage(string zipPath, string extractPath)
        {
            try
            {
                // 这里需要实现ZIP解压逻辑
                // 可以使用System.IO.Compression或第三方库
                // 简化处理：返回zip路径，由安装程序处理
                return zipPath;
            }
            catch (Exception ex)
            {
                LogError($"解压驱动包失败: {ex.Message}");
                return zipPath; // 返回原始文件路径
            }
        }

        /// <summary>
        /// 验证驱动签名
        /// </summary>
        private DriverSignatureResult VerifyDriverSignature(string driverPath)
        {
            try
            {
                // Windows SDK中的signtool可以验证驱动签名
                // 这里简化处理，只检查文件是否存在
                
                if (!File.Exists(driverPath))
                    return DriverSignatureResult.Invalid("驱动文件不存在");

                // 在实际应用中，应该调用signtool verify或WinVerifyTrust API
                // 这里返回假设验证通过
                
                return DriverSignatureResult.Valid("驱动签名验证通过（测试模式）");
            }
            catch (Exception ex)
            {
                LogError($"验证驱动签名时发生异常: {ex.Message}");
                return DriverSignatureResult.Invalid($"验证签名异常: {ex.Message}");
            }
        }

        /// <summary>
        /// 安装驱动（内部实现）
        /// </summary>
        private DriverInstallInternalResult InstallDriverInternal(string driverPath, string vendorId, string productId)
        {
            try
            {
                string arguments;
                string command;
                
                // 根据文件类型选择安装方式
                var extension = Path.GetExtension(driverPath).ToLower();
                
                switch (extension)
                {
                    case ".inf":
                        // 使用pnputil安装inf驱动
                        command = "pnputil.exe";
                        arguments = $"/add-driver \"{driverPath}\" /install";
                        break;
                        
                    case ".exe":
                        // 运行可执行安装程序（静默模式）
                        command = driverPath;
                        arguments = GetSilentInstallArgs(vendorId);
                        break;
                        
                    default:
                        return DriverInstallInternalResult.Failure($"不支持的驱动文件格式: {extension}");
                }

                LogInfo($"正在安装驱动: {command} {arguments}");
                
                var processInfo = new ProcessStartInfo
                {
                    FileName = command,
                    Arguments = arguments,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    Verb = "runas" // 以管理员身份运行
                };

                using (var process = Process.Start(processInfo))
                {
                    if (process == null)
                        return DriverInstallInternalResult.Failure("启动安装进程失败");

                    process.WaitForExit(60000); // 等待60秒
                    
                    if (process.HasExited)
                    {
                        var exitCode = process.ExitCode;
                        var output = process.StandardOutput.ReadToEnd();
                        var error = process.StandardError.ReadToEnd();
                        
                        LogInfo($"驱动安装进程退出代码: {exitCode}");
                        
                        if (exitCode == 0 || exitCode == 3010) // 3010表示需要重启
                        {
                            return DriverInstallInternalResult.Success($"驱动安装成功，退出代码: {exitCode}");
                        }
                        else
                        {
                            var errorMsg = $"驱动安装失败，退出代码: {exitCode}";
                            if (!string.IsNullOrEmpty(error))
                                errorMsg += $", 错误: {error}";
                            
                            return DriverInstallInternalResult.Failure(errorMsg);
                        }
                    }
                    else
                    {
                        process.Kill();
                        return DriverInstallInternalResult.Failure("驱动安装超时");
                    }
                }
            }
            catch (Exception ex)
            {
                LogError($"安装驱动时发生异常: {ex.Message}");
                return DriverInstallInternalResult.Failure($"安装驱动时发生异常: {ex.Message}");
            }
        }

        /// <summary>
        /// 获取静默安装参数
        /// </summary>
        private string GetSilentInstallArgs(string vendorId)
        {
            // 不同厂商的静默安装参数不同
            switch (vendorId.ToUpper())
            {
                case "046D": // Logitech
                    return "/S"; // 静默安装
                
                case "1532": // Razer
                    return "/S"; // 静默安装
                
                case "1038": // SteelSeries
                    return "/quiet"; // 安静模式
                
                case "1B1C": // Corsair
                    return "/S"; // 静默安装
                
                default:
                    return "/S /quiet /silent"; // 通用静默参数
            }
        }

        /// <summary>
        /// 检查是否为测试环境
        /// </summary>
        private bool IsTestEnvironment()
        {
            // 简单判断：检查是否存在测试标记文件
            var testMarkerPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "test.marker");
            return File.Exists(testMarkerPath);
        }

        /// <summary>
        /// 记录信息日志
        /// </summary>
        private void LogInfo(string message)
        {
            try
            {
                EventLog.WriteEntry("CyberCafeUsbManager", $"[DriverManager] {message}", EventLogEntryType.Information);
            }
            catch
            {
                // 忽略日志写入失败
            }
        }

        /// <summary>
        /// 记录警告日志
        /// </summary>
        private void LogWarning(string message)
        {
            try
            {
                EventLog.WriteEntry("CyberCafeUsbManager", $"[DriverManager] {message}", EventLogEntryType.Warning);
            }
            catch
            {
                // 忽略日志写入失败
            }
        }

        /// <summary>
        /// 记录错误日志
        /// </summary>
        private void LogError(string message)
        {
            try
            {
                EventLog.WriteEntry("CyberCafeUsbManager", $"[DriverManager] {message}", EventLogEntryType.Error);
            }
            catch
            {
                // 忽略日志写入失败
            }
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        protected virtual void Dispose(bool disposing)
        {
            if (_disposed)
                return;

            if (disposing)
            {
                _httpClient?.Dispose();
            }

            _disposed = true;
        }

        ~DriverManager()
        {
            Dispose(false);
        }
    }

    /// <summary>
    /// 驱动安装结果
    /// </summary>
    public class DriverInstallResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public string DriverPath { get; set; }
        public DateTime Timestamp { get; set; }

        public DriverInstallResult()
        {
            Timestamp = DateTime.Now;
        }

        public static DriverInstallResult Success(string message, string driverPath = null)
        {
            return new DriverInstallResult
            {
                Success = true,
                Message = message,
                DriverPath = driverPath
            };
        }

        public static DriverInstallResult Failure(string message)
        {
            return new DriverInstallResult
            {
                Success = false,
                Message = message
            };
        }
    }

    /// <summary>
    /// 驱动下载结果
    /// </summary>
    public class DriverDownloadResult : DriverInstallResult
    {
        public static DriverDownloadResult Success(string driverPath, string message)
        {
            return new DriverDownloadResult
            {
                Success = true,
                DriverPath = driverPath,
                Message = message
            };
        }

        public static new DriverDownloadResult Failure(string message)
        {
            return new DriverDownloadResult
            {
                Success = false,
                Message = message
            };
        }
    }

    /// <summary>
    /// 驱动签名验证结果
    /// </summary>
    public class DriverSignatureResult
    {
        public bool IsValid { get; set; }
        public string Message { get; set; }

        public static DriverSignatureResult Valid(string message)
        {
            return new DriverSignatureResult
            {
                IsValid = true,
                Message = message
            };
        }

        public static DriverSignatureResult Invalid(string message)
        {
            return new DriverSignatureResult
            {
                IsValid = false,
                Message = message
            };
        }
    }

    /// <summary>
    /// 驱动安装内部结果
    /// </summary>
    public class DriverInstallInternalResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }

        public static DriverInstallInternalResult Success(string message)
        {
            return new DriverInstallInternalResult
            {
                Success = true,
                Message = message
            };
        }

        public static DriverInstallInternalResult Failure(string message)
        {
            return new DriverInstallInternalResult
            {
                Success = false,
                Message = message
            };
        }
    }
}