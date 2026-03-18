using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Threading;
using System.Threading.Tasks;

namespace CyberCafeUsbManager
{
    /// <summary>
    /// Windows服务主类 - USB设备监控服务
    /// </summary>
    public partial class UsbMonitorService : ServiceBase
    {
        private readonly DeviceMonitor _deviceMonitor;
        private readonly DriverManager _driverManager;
        private readonly SoftwareLauncher _softwareLauncher;
        private readonly ConfigManager _configManager;
        
        private CancellationTokenSource _cancellationTokenSource;
        private Task _monitoringTask;

        /// <summary>
        /// 服务构造函数
        /// </summary>
        public UsbMonitorService()
        {
            InitializeComponent();
            
            // 初始化组件
            ServiceName = "CyberCafeUsbManager";
            CanStop = true;
            CanPauseAndContinue = true;
            AutoLog = true;
            
            // 创建实例
            _configManager = new ConfigManager();
            _deviceMonitor = new DeviceMonitor(_configManager);
            _driverManager = new DriverManager(_configManager);
            _softwareLauncher = new SoftwareLauncher(_configManager);
            
            // 设置事件处理器
            _deviceMonitor.DeviceConnected += OnDeviceConnected;
            _deviceMonitor.DeviceDisconnected += OnDeviceDisconnected;
            
            EventLog.Source = ServiceName;
        }

        /// <summary>
        /// 服务启动时调用
        /// </summary>
        protected override void OnStart(string[] args)
        {
            try
            {
                EventLog.WriteEntry("CyberCafe USB Manager服务正在启动...", EventLogEntryType.Information);
                
                // 加载配置
                _configManager.LoadConfig();
                
                // 启动监控任务
                _cancellationTokenSource = new CancellationTokenSource();
                _monitoringTask = Task.Run(() => StartMonitoringAsync(_cancellationTokenSource.Token));
                
                EventLog.WriteEntry("CyberCafe USB Manager服务已成功启动", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"服务启动失败: {ex.Message}\n{ex.StackTrace}", EventLogEntryType.Error);
                throw;
            }
        }

        /// <summary>
        /// 服务停止时调用
        /// </summary>
        protected override void OnStop()
        {
            try
            {
                EventLog.WriteEntry("CyberCafe USB Manager服务正在停止...", EventLogEntryType.Information);
                
                // 取消监控任务
                _cancellationTokenSource?.Cancel();
                
                // 等待任务完成
                if (_monitoringTask != null && !_monitoringTask.IsCompleted)
                {
                    Task.WaitAny(_monitoringTask, Task.Delay(5000));
                }
                
                // 释放资源
                _deviceMonitor?.Dispose();
                
                EventLog.WriteEntry("CyberCafe USB Manager服务已成功停止", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"服务停止失败: {ex.Message}", EventLogEntryType.Warning);
            }
        }

        /// <summary>
        /// 服务暂停时调用
        /// </summary>
        protected override void OnPause()
        {
            _cancellationTokenSource?.Cancel();
            EventLog.WriteEntry("服务已暂停", EventLogEntryType.Information);
        }

        /// <summary>
        /// 服务继续时调用
        /// </summary>
        protected override void OnContinue()
        {
            _cancellationTokenSource = new CancellationTokenSource();
            _monitoringTask = Task.Run(() => StartMonitoringAsync(_cancellationTokenSource.Token));
            EventLog.WriteEntry("服务已恢复", EventLogEntryType.Information);
        }

        /// <summary>
        /// 启动设备监控（异步）
        /// </summary>
        private async Task StartMonitoringAsync(CancellationToken cancellationToken)
        {
            try
            {
                EventLog.WriteEntry("开始监控USB设备...", EventLogEntryType.Information);
                
                // 启动设备监控
                await _deviceMonitor.StartMonitoringAsync(cancellationToken);
                
                while (!cancellationToken.IsCancellationRequested)
                {
                    try
                    {
                        // 定期检查配置更新
                        _configManager.CheckForConfigUpdates();
                        
                        // 休眠一段时间再继续
                        await Task.Delay(5000, cancellationToken);
                    }
                    catch (TaskCanceledException)
                    {
                        // 任务被取消，正常退出
                        break;
                    }
                    catch (Exception ex)
                    {
                        EventLog.WriteEntry($"监控循环出错: {ex.Message}", EventLogEntryType.Warning);
                        await Task.Delay(10000, cancellationToken);
                    }
                }
                
                EventLog.WriteEntry("USB设备监控已停止", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"监控任务失败: {ex.Message}\n{ex.StackTrace}", EventLogEntryType.Error);
            }
        }

        /// <summary>
        /// 设备连接事件处理
        /// </summary>
        private void OnDeviceConnected(object sender, DeviceEventArgs e)
        {
            try
            {
                EventLog.WriteEntry($"检测到新设备: {e.DeviceName} (VID:{e.VendorId}, PID:{e.ProductId})", 
                                  EventLogEntryType.Information);
                
                // 检查是否为支持的主流品牌
                if (_configManager.IsSupportedBrand(e.VendorId))
                {
                    EventLog.WriteEntry($"检测到主流品牌设备: {e.BrandName} {e.ModelName}", 
                                      EventLogEntryType.Information);
                    
                    // 自动安装驱动（如果配置开启）
                    if (_configManager.AutoInstallDrivers)
                    {
                        var driverResult = _driverManager.InstallDriver(e.VendorId, e.ProductId);
                        if (driverResult.Success)
                        {
                            EventLog.WriteEntry($"驱动安装成功: {driverResult.Message}", 
                                              EventLogEntryType.Information);
                        }
                        else
                        {
                            EventLog.WriteEntry($"驱动安装失败: {driverResult.Message}", 
                                              EventLogEntryType.Warning);
                        }
                    }
                    
                    // 自动启动软件（如果配置开启）
                    if (_configManager.AutoLaunchSoftware)
                    {
                        var launchResult = _softwareLauncher.LaunchSoftware(e.VendorId);
                        if (launchResult.Success)
                        {
                            EventLog.WriteEntry($"软件启动成功: {launchResult.Message}", 
                                              EventLogEntryType.Information);
                        }
                        else
                        {
                            EventLog.WriteEntry($"软件启动失败: {launchResult.Message}", 
                                              EventLogEntryType.Warning);
                        }
                    }
                }
                else
                {
                    EventLog.WriteEntry($"非主流品牌设备，跳过处理: {e.BrandName}", 
                                      EventLogEntryType.Information);
                }
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"处理设备连接事件失败: {ex.Message}", EventLogEntryType.Error);
            }
        }

        /// <summary>
        /// 设备断开事件处理
        /// </summary>
        private void OnDeviceDisconnected(object sender, DeviceEventArgs e)
        {
            EventLog.WriteEntry($"设备已断开: {e.DeviceName}", EventLogEntryType.Information);
            
            // 可以在这里添加设备断开后的清理逻辑
            // 例如：停止相关进程、释放资源等
        }

        /// <summary>
        /// 初始化组件
        /// </summary>
        private void InitializeComponent()
        {
            // Windows服务设计器生成的代码
            // 实际项目中这部分由Visual Studio自动生成
        }
    }

    /// <summary>
    /// 设备事件参数
    /// </summary>
    public class DeviceEventArgs : EventArgs
    {
        public string DeviceName { get; set; }
        public string VendorId { get; set; }
        public string ProductId { get; set; }
        public string BrandName { get; set; }
        public string ModelName { get; set; }
        public string DeviceType { get; set; } // Keyboard, Mouse等
        public DateTime Timestamp { get; set; }
        
        public DeviceEventArgs()
        {
            Timestamp = DateTime.Now;
        }
    }
}