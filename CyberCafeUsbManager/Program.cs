using System;
using System.ServiceProcess;

namespace CyberCafeUsbManager
{
    static class Program
    {
        /// <summary>
        /// 应用程序的主入口点。
        /// </summary>
        static void Main()
        {
            ServiceBase[] ServicesToRun;
            ServicesToRun = new ServiceBase[]
            {
                new UsbMonitorService()
            };
            
            // 根据环境决定运行方式
            if (Environment.UserInteractive)
            {
                // 控制台模式运行，用于调试
                Console.WriteLine("CyberCafe USB Manager - 调试模式");
                Console.WriteLine("按任意键开始服务，按ESC退出...");
                
                var key = Console.ReadKey();
                if (key.Key != ConsoleKey.Escape)
                {
                    Console.WriteLine("启动服务...");
                    RunServiceDebug(ServicesToRun);
                }
                Console.WriteLine("退出调试模式");
            }
            else
            {
                // 服务模式运行
                ServiceBase.Run(ServicesToRun);
            }
        }
        
        /// <summary>
        /// 调试模式下运行服务
        /// </summary>
        private static void RunServiceDebug(ServiceBase[] services)
        {
            Console.WriteLine("初始化服务...");
            
            foreach (var service in services)
            {
                Console.WriteLine($"启动服务: {service.ServiceName}");
                
                // 调用OnStart方法（通过反射）
                var onStartMethod = service.GetType().GetMethod("OnStart", 
                    System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
                
                try
                {
                    onStartMethod?.Invoke(service, new object[] { new string[] { } });
                    Console.WriteLine($"服务 {service.ServiceName} 已启动");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"启动服务失败: {ex.Message}");
                }
            }
            
            Console.WriteLine("所有服务已启动。按任意键停止服务...");
            Console.ReadKey();
            
            // 停止服务
            foreach (var service in services)
            {
                Console.WriteLine($"停止服务: {service.ServiceName}");
                
                var onStopMethod = service.GetType().GetMethod("OnStop", 
                    System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
                
                try
                {
                    onStopMethod?.Invoke(service, null);
                    Console.WriteLine($"服务 {service.ServiceName} 已停止");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"停止服务失败: {ex.Message}");
                }
            }
            
            Console.WriteLine("调试模式结束");
        }
    }
}