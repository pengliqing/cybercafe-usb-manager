# 网吧USB管理软件 - GitHub仓库设置脚本
# 使用说明: 在PowerShell中运行此脚本，按照提示操作

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "网吧USB管理软件 - GitHub云编译设置" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查Git是否安装
$gitInstalled = $false
try {
    git --version 2>&1 | Out-Null
    $gitInstalled = $true
    Write-Host "✅ Git已安装: $(git --version)" -ForegroundColor Green
} catch {
    Write-Host "❌ Git未安装" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先安装Git:"
    Write-Host "1. 下载地址: https://git-scm.com/download/win"
    Write-Host "2. 安装时选择'Git Bash Here'和'Git GUI Here'"
    Write-Host "3. 安装完成后重新运行此脚本"
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Host "步骤1: 创建GitHub仓库" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "请按以下步骤操作:"
Write-Host "1. 打开浏览器访问: https://github.com"
Write-Host "2. 登录您的GitHub账号"
Write-Host "3. 点击右上角'+' → 'New repository'"
Write-Host "4. 输入仓库名称: cybercafe-usb-manager"
Write-Host "5. 描述: 网吧USB设备管理软件"
Write-Host "6. 选择: Public (公开，免费无限构建)"
Write-Host "7. 不要勾选'Initialize this repository with README'"
Write-Host "8. 点击'Create repository'"
Write-Host ""
Write-Host "创建完成后，您将看到仓库地址，类似:"
Write-Host "https://github.com/您的用户名/cybercafe-usb-manager.git"
Write-Host ""

$repoUrl = Read-Host "请输入您的GitHub仓库URL (例如: https://github.com/username/cybercafe-usb-manager.git)"

Write-Host ""
Write-Host "步骤2: 初始化本地Git仓库" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host ""

# 检查当前目录
$currentDir = Get-Location
Write-Host "当前目录: $currentDir" -ForegroundColor Gray

# 检查是否在项目目录
$slnFile = "CyberCafeUsbManager.sln"
if (-not (Test-Path $slnFile)) {
    Write-Host "❌ 错误: 请在cybercafe-usb-manager目录中运行此脚本" -ForegroundColor Red
    Write-Host "请进入项目目录后重新运行" -ForegroundColor Yellow
    Write-Host "示例: cd C:\Users\您的用户名\Desktop\cybercafe-usb-manager" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# 初始化Git仓库
Write-Host "正在初始化Git仓库..." -ForegroundColor Gray
try {
    git init 2>&1 | Out-Null
    git add . 2>&1 | Out-Null
    git commit -m "初始提交: 网吧USB管理软件V1.0" 2>&1 | Out-Null
    git branch -M main 2>&1 | Out-Null
    
    Write-Host "✅ 本地Git仓库初始化成功" -ForegroundColor Green
} catch {
    Write-Host "❌ Git操作失败: $_" -ForegroundColor Red
    Write-Host "请检查Git配置或手动执行命令" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Host "步骤3: 连接到GitHub远程仓库" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host ""

try {
    git remote add origin $repoUrl 2>&1 | Out-Null
    Write-Host "✅ 远程仓库配置成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 远程仓库配置失败: $_" -ForegroundColor Red
    Write-Host "请检查仓库URL是否正确" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Host "步骤4: 推送代码到GitHub" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host ""

Write-Host "正在推送代码到GitHub..." -ForegroundColor Gray
try {
    git push -u origin main 2>&1 | Out-Null
    Write-Host "✅ 代码推送成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 推送失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "可能原因和解决方案:" -ForegroundColor Yellow
    Write-Host "1. 网络问题: 检查网络连接" -ForegroundColor Yellow
    Write-Host "2. 认证问题: 需要配置GitHub Personal Access Token" -ForegroundColor Yellow
    Write-Host "3. 权限问题: 确保您有仓库写入权限" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请手动执行: git push -u origin main" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Host "步骤5: 触发首次构建" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host ""

Write-Host "代码推送后，GitHub Actions将自动开始构建。" -ForegroundColor Gray
Write-Host ""
Write-Host "查看构建进度:" -ForegroundColor Cyan
Write-Host "1. 访问您的仓库页面: $repoUrl" -ForegroundColor Cyan
Write-Host "2. 点击'Actions'选项卡" -ForegroundColor Cyan
Write-Host "3. 查看构建状态和日志" -ForegroundColor Cyan
Write-Host ""
Write-Host "构建完成后下载结果:" -ForegroundColor Cyan
Write-Host "1. 进入'Actions'页面" -ForegroundColor Cyan
Write-Host "2. 点击最新的构建运行" -ForegroundColor Cyan
Write-Host "3. 在'Artifacts'部分下载:" -ForegroundColor Cyan
Write-Host "   - '网吧USB管理软件_完整部署包' (ZIP文件)" -ForegroundColor Cyan
Write-Host "   - 'CyberCafeUsbManager-编译结果' (原始文件)" -ForegroundColor Cyan
Write-Host ""

Write-Host "步骤6: 下载和部署" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host ""

Write-Host "下载后的部署步骤:" -ForegroundColor Gray
Write-Host "1. 解压ZIP文件到网吧机器" -ForegroundColor Gray
Write-Host "2. 进入'脚本工具'目录" -ForegroundColor Gray
Write-Host "3. 右键'安装服务.bat' → '以管理员身份运行'" -ForegroundColor Gray
Write-Host "4. 插入USB设备测试识别功能" -ForegroundColor Gray
Write-Host "5. 查看事件查看器日志确认成功" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "设置完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "重要提示:" -ForegroundColor Yellow
Write-Host "1. 首次构建可能需要5-10分钟" -ForegroundColor Yellow
Write-Host "2. 如果构建失败，请查看构建日志" -ForegroundColor Yellow
Write-Host "3. 需要技术支持请提供错误信息" -ForegroundColor Yellow
Write-Host ""

Write-Host "下一步操作:" -ForegroundColor Cyan
Write-Host "1. 等待构建完成" -ForegroundColor Cyan
Write-Host "2. 下载构建产物" -ForegroundColor Cyan
Write-Host "3. 在网吧环境测试" -ForegroundColor Cyan
Write-Host "4. 反馈测试结果" -ForegroundColor Cyan
Write-Host ""

pause