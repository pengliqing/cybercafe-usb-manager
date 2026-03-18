using System;
using System.Collections;
using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace CyberCafeUsbManager
{
    /// <summary>
    /// Windows服务安装器
    /// </summary>
    [RunInstaller(true)]
    public partial class ProjectInstaller : Installer
    {
        private ServiceProcessInstaller serviceProcessInstaller;
        private ServiceInstaller serviceInstaller;

        public ProjectInstaller()
        {
            InitializeComponent();
        }

        /// <summary>
        /// 初始化安装组件
        /// </summary>
        private void InitializeComponent()
        {
            // 创建服务进程安装器
            serviceProcessInstaller = new ServiceProcessInstaller();
            serviceProcessInstaller.Account = ServiceAccount.LocalSystem;
            serviceProcessInstaller.Username = null;
            serviceProcessInstaller.Password = null;

            // 创建服务安装器
            serviceInstaller = new ServiceInstaller();
            serviceInstaller.ServiceName = "CyberCafeUsbManager";
            serviceInstaller.DisplayName = "CyberCafe USB Manager";
            serviceInstaller.Description = "网吧USB设备管理服务，自动识别键盘鼠标并安装驱动";
            serviceInstaller.StartType = ServiceStartMode.Automatic;
            
            // 设置服务恢复选项
            serviceInstaller.ServicesDependedOn = new string[] { };
            serviceInstaller.DelayedAutoStart = true;

            // 添加安装器到集合
            Installers.AddRange(new Installer[] 
            {
                serviceProcessInstaller,
                serviceInstaller
            });
            
            // 添加安装事件处理
            this.AfterInstall += new InstallEventHandler(ProjectInstaller_AfterInstall);
            this.AfterUninstall += new InstallEventHandler(ProjectInstaller_AfterUninstall);
            this.BeforeUninstall += new InstallEventHandler(ProjectInstaller_BeforeUninstall);
        }

        /// <summary>
        /// 安装后事件
        /// </summary>
        private void ProjectInstaller_AfterInstall(object sender, InstallEventArgs e)
        {
            try
            {
                // 尝试启动服务
                using (ServiceController sc = new ServiceController(serviceInstaller.ServiceName))
                {
                    if (sc.Status == ServiceControllerStatus.Stopped)
                    {
                        sc.Start();
                        sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(30));
                    }
                }
            }
            catch (Exception ex)
            {
                // 记录但不抛出异常，安装仍算成功
                Context.LogMessage($"安装后启动服务失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 卸载前事件
        /// </summary>
        private void ProjectInstaller_BeforeUninstall(object sender, InstallEventArgs e)
        {
            try
            {
                // 停止服务
                using (ServiceController sc = new ServiceController(serviceInstaller.ServiceName))
                {
                    if (sc.Status == ServiceControllerStatus.Running)
                    {
                        sc.Stop();
                        sc.WaitForStatus(ServiceControllerStatus.Stopped, TimeSpan.FromSeconds(30));
                    }
                }
            }
            catch (Exception ex)
            {
                // 记录但不抛出异常
                Context.LogMessage($"卸载前停止服务失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 卸载后事件
        /// </summary>
        private void ProjectInstaller_AfterUninstall(object sender, InstallEventArgs e)
        {
            // 卸载后清理临时文件等
            try
            {
                // 这里可以添加清理逻辑，比如删除配置文件等
                Context.LogMessage("服务已成功卸载");
            }
            catch (Exception ex)
            {
                Context.LogMessage($"卸载后清理失败: {ex.Message}");
            }
        }

        /// <summary>
        /// 重写安装方法以添加自定义逻辑
        /// </summary>
        public override void Install(IDictionary stateSaver)
        {
            Context.LogMessage("正在安装 CyberCafe USB Manager 服务...");
            base.Install(stateSaver);
        }

        /// <summary>
        /// 重写提交方法
        /// </summary>
        public override void Commit(IDictionary savedState)
        {
            base.Commit(savedState);
            Context.LogMessage("CyberCafe USB Manager 服务安装完成");
        }

        /// <summary>
        /// 重写回滚方法
        /// </summary>
        public override void Rollback(IDictionary savedState)
        {
            base.Rollback(savedState);
            Context.LogMessage("CyberCafe USB Manager 服务安装已回滚");
        }

        /// <summary>
        /// 重写卸载方法
        /// </summary>
        public override void Uninstall(IDictionary savedState)
        {
            Context.LogMessage("正在卸载 CyberCafe USB Manager 服务...");
            base.Uninstall(savedState);
        }
    }
}