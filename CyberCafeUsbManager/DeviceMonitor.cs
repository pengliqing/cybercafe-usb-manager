using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Management;
using System.Threading;
using System.Threading.Tasks;

namespace CyberCafeUsbManager
{
    /// <summary>
    /// USB设备监控器
    /// 使用WMI监控USB设备连接和断开
    /// </summary>
    public class DeviceMonitor : IDisposable
    {
        private readonly ConfigManager _configManager;
        private ManagementEventWatcher _deviceConnectedWatcher;
        private ManagementEventWatcher _deviceDisconnectedWatcher;
        private readonly HashSet<string> _currentDevices = new HashSet<string>();
        private readonly object _devicesLock = new object();
        private bool _disposed;

        /// <summary>
        /// 设备连接事件
        /// </summary>
        public event EventHandler<DeviceEventArgs> DeviceConnected;

        /// <summary>
        /// 设备断开事件
        /// </summary>
        public event EventHandler<DeviceEventArgs> DeviceDisconnected;

        /// <summary>
        /// 构造函数
        /// </summary>
        public DeviceMonitor(ConfigManager configManager)
        {
            _configManager = configManager ?? throw new ArgumentNullException(nameof(configManager));
        }

        /// <summary>
        /// 开始监控USB设备
        /// </summary>
        public async Task StartMonitoringAsync(CancellationToken cancellationToken)
        {
            try
            {
                // 初始化当前设备列表
                await InitializeCurrentDevicesAsync();
                
                // 设置设备连接监控
                SetupDeviceConnectedWatcher();
                
                // 设置设备断开监控
                SetupDeviceDisconnectedWatcher();
                
                // 开始监控
                _deviceConnectedWatcher.Start();
                _deviceDisconnectedWatcher.Start();
                
                LogInfo("USB设备监控已启动");
            }
            catch (Exception ex)
            {
                LogError($"启动设备监控失败: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// 停止监控
        /// </summary>
        public void StopMonitoring()
        {
            try
            {
                _deviceConnectedWatcher?.Stop();
                _deviceDisconnectedWatcher?.Stop();
                
                LogInfo("USB设备监控已停止");
            }
            catch (Exception ex)
            {
                LogError($"停止设备监控失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 初始化当前已连接的设备列表
        /// </summary>
        private async Task InitializeCurrentDevicesAsync()
        {
            try
            {
                await Task.Run(() =>
                {
                    lock (_devicesLock)
                    {
                        _currentDevices.Clear();
                        
                        using (var searcher = new ManagementObjectSearcher(
                            "SELECT * FROM Win32_PnPEntity WHERE ConfigManagerErrorCode = 0"))
                        {
                            foreach (ManagementObject device in searcher.Get())
                            {
                                try
                                {
                                    var deviceId = device["DeviceID"]?.ToString();
                                    if (IsUsbDevice(deviceId))
                                    {
                                        _currentDevices.Add(deviceId);
                                    }
                                }
                                catch (ManagementException)
                                {
                                    // 忽略无法访问的设备
                                }
                                finally
                                {
                                    device.Dispose();
                                }
                            }
                        }
                        
                        LogInfo($"初始化完成，当前已连接 {_currentDevices.Count} 个USB设备");
                    }
                });
            }
            catch (Exception ex)
            {
                LogError($"初始化设备列表失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 设置设备连接监控
        /// </summary>
        private void SetupDeviceConnectedWatcher()
        {
            try
            {
                var query = new WqlEventQuery(
                    "SELECT * FROM __InstanceCreationEvent WITHIN 2 " +
                    "WHERE TargetInstance ISA 'Win32_PnPEntity'");
                
                _deviceConnectedWatcher = new ManagementEventWatcher(query);
                _deviceConnectedWatcher.EventArrived += OnDeviceConnected;
                
                LogInfo("设备连接监控器已设置");
            }
            catch (Exception ex)
            {
                LogError($"设置设备连接监控器失败: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// 设置设备断开监控
        /// </summary>
        private void SetupDeviceDisconnectedWatcher()
        {
            try
            {
                var query = new WqlEventQuery(
                    "SELECT * FROM __InstanceDeletionEvent WITHIN 2 " +
                    "WHERE TargetInstance ISA 'Win32_PnPEntity'");
                
                _deviceDisconnectedWatcher = new ManagementEventWatcher(query);
                _deviceDisconnectedWatcher.EventArrived += OnDeviceDisconnected;
                
                LogInfo("设备断开监控器已设置");
            }
            catch (Exception ex)
            {
                LogError($"设置设备断开监控器失败: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// 设备连接事件处理
        /// </summary>
        private void OnDeviceConnected(object sender, EventArrivedEventArgs e)
        {
            try
            {
                var device = (ManagementBaseObject)e.NewEvent["TargetInstance"];
                var deviceId = device["DeviceID"]?.ToString();
                
                if (string.IsNullOrEmpty(deviceId) || !IsUsbDevice(deviceId))
                    return;
                
                lock (_devicesLock)
                {
                    if (_currentDevices.Contains(deviceId))
                        return; // 设备已存在
                    
                    _currentDevices.Add(deviceId);
                }
                
                // 解析设备信息
                var deviceInfo = ParseDeviceInfo(device);
                if (deviceInfo != null)
                {
                    LogInfo($"设备已连接: {deviceInfo.DeviceName} (VID:{deviceInfo.VendorId}, PID:{deviceInfo.ProductId})");
                    
                    // 触发设备连接事件
                    DeviceConnected?.Invoke(this, deviceInfo);
                }
            }
            catch (Exception ex)
            {
                LogError($"处理设备连接事件失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 设备断开事件处理
        /// </summary>
        private void OnDeviceDisconnected(object sender, EventArrivedEventArgs e)
        {
            try
            {
                var device = (ManagementBaseObject)e.NewEvent["TargetInstance"];
                var deviceId = device["DeviceID"]?.ToString();
                
                if (string.IsNullOrEmpty(deviceId) || !IsUsbDevice(deviceId))
                    return;
                
                lock (_devicesLock)
                {
                    if (!_currentDevices.Contains(deviceId))
                        return; // 设备不存在
                    
                    _currentDevices.Remove(deviceId);
                }
                
                // 解析设备信息
                var deviceInfo = ParseDeviceInfo(device);
                if (deviceInfo != null)
                {
                    LogInfo($"设备已断开: {deviceInfo.DeviceName}");
                    
                    // 触发设备断开事件
                    DeviceDisconnected?.Invoke(this, deviceInfo);
                }
            }
            catch (Exception ex)
            {
                LogError($"处理设备断开事件失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 解析设备信息
        /// </summary>
        private DeviceEventArgs ParseDeviceInfo(ManagementBaseObject device)
        {
            try
            {
                var deviceId = device["DeviceID"]?.ToString();
                if (string.IsNullOrEmpty(deviceId))
                    return null;

                // 提取VID和PID
                var vidPidInfo = ExtractVidPid(deviceId);
                if (string.IsNullOrEmpty(vidPidInfo.Vid))
                    return null;

                // 获取设备名称
                var deviceName = device["Name"]?.ToString() ?? 
                               device["Description"]?.ToString() ?? 
                               "未知设备";

                // 获取厂商信息
                var vendorInfo = _configManager.GetVendorInfo(vidPidInfo.Vid);
                var brandName = vendorInfo?.Name ?? "未知品牌";
                
                // 获取设备型号信息
                var deviceModel = "未知型号";
                if (vendorInfo != null && !string.IsNullOrEmpty(vidPidInfo.Pid))
                {
                    var deviceInfo = _configManager.GetDeviceInfo(vidPidInfo.Vid, vidPidInfo.Pid);
                    if (deviceInfo != null)
                    {
                        deviceModel = deviceInfo.Model ?? deviceInfo.Name;
                    }
                }

                // 判断设备类型
                var deviceType = DetermineDeviceType(deviceName);

                return new DeviceEventArgs
                {
                    DeviceName = deviceName,
                    VendorId = vidPidInfo.Vid,
                    ProductId = vidPidInfo.Pid,
                    BrandName = brandName,
                    ModelName = deviceModel,
                    DeviceType = deviceType
                };
            }
            catch (Exception ex)
            {
                LogError($"解析设备信息失败: {ex.Message}");
                return null;
            }
        }

        /// <summary>
        /// 提取VID和PID
        /// </summary>
        private (string Vid, string Pid) ExtractVidPid(string deviceId)
        {
            if (string.IsNullOrEmpty(deviceId))
                return (null, null);

            // 格式示例: USB\VID_046D&PID_C08B\...
            var vidIndex = deviceId.IndexOf("VID_", StringComparison.OrdinalIgnoreCase);
            var pidIndex = deviceId.IndexOf("PID_", StringComparison.OrdinalIgnoreCase);
            
            if (vidIndex < 0 || pidIndex < 0)
                return (null, null);

            // 提取VID (4位十六进制)
            var vidStart = vidIndex + 4;
            var vid = deviceId.Length >= vidStart + 4 ? 
                     deviceId.Substring(vidStart, 4).ToUpper() : null;

            // 提取PID (4位十六进制)
            var pidStart = pidIndex + 4;
            var pid = deviceId.Length >= pidStart + 4 ? 
                     deviceId.Substring(pidStart, 4).ToUpper() : null;

            return (vid, pid);
        }

        /// <summary>
        /// 判断设备类型
        /// </summary>
        private string DetermineDeviceType(string deviceName)
        {
            if (string.IsNullOrEmpty(deviceName))
                return "Unknown";

            var name = deviceName.ToLowerInvariant();
            
            if (name.Contains("keyboard") || name.Contains("键盘"))
                return "Keyboard";
            
            if (name.Contains("mouse") || name.Contains("鼠标") || 
                name.Contains("rat") || name.Contains("deathadder") || name.Contains("g502"))
                return "Mouse";
            
            if (name.Contains("headset") || name.Contains("headphone") || name.Contains("耳机"))
                return "Headset";
            
            if (name.Contains("gamepad") || name.Contains("controller") || name.Contains("手柄"))
                return "Gamepad";
            
            return "Other";
        }

        /// <summary>
        /// 检查是否为USB设备
        /// </summary>
        private bool IsUsbDevice(string deviceId)
        {
            if (string.IsNullOrEmpty(deviceId))
                return false;

            return deviceId.IndexOf("USB\\", StringComparison.OrdinalIgnoreCase) >= 0 ||
                   deviceId.IndexOf("HID\\", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        /// <summary>
        /// 获取当前已连接的设备列表
        /// </summary>
        public List<string> GetCurrentDevices()
        {
            lock (_devicesLock)
            {
                return new List<string>(_currentDevices);
            }
        }

        /// <summary>
        /// 记录信息日志
        /// </summary>
        private void LogInfo(string message)
        {
            try
            {
                EventLog.WriteEntry("CyberCafeUsbManager", message, EventLogEntryType.Information);
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
                EventLog.WriteEntry("CyberCafeUsbManager", message, EventLogEntryType.Error);
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
                _deviceConnectedWatcher?.Stop();
                _deviceDisconnectedWatcher?.Stop();
                
                _deviceConnectedWatcher?.Dispose();
                _deviceDisconnectedWatcher?.Dispose();
            }

            _disposed = true;
        }

        ~DeviceMonitor()
        {
            Dispose(false);
        }
    }
}