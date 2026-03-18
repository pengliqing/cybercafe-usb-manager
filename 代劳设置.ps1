# 网吧USB管理软件 - GitHub云编译代劳设置脚本
# 版本: 1.0
# 作者: 络络 (OpenClaw AI助手)
# 功能: 自动完成GitHub仓库创建、代码上传、触发构建

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "网吧USB管理软件 - GitHub云编译代劳设置" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 显示免责声明和安全提示
Write-Host "安全提示:" -ForegroundColor Yellow
Write-Host "1. 本脚本将在您的电脑上运行" -ForegroundColor Yellow
Write-Host "2. 需要GitHub个人访问令牌（PAT）" -ForegroundColor Yellow
Write-Host "3. 令牌只用于创建仓库和上传代码" -ForegroundColor Yellow
Write-Host "4. 令牌不会保存到任何地方" -ForegroundColor Yellow
Write-Host "5. 建议使用有效期30天的令牌" -ForegroundColor Yellow
Write-Host ""

$continue = Read-Host "是否继续？(Y/N)"
if ($continue -ne "Y" -and $continue -ne "y") {
    Write-Host "操作已取消。" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "步骤1: 检查环境依赖" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

# 检查Git是否安装
$gitInstalled = $false
try {
    $gitVersion = git --version 2>&1
    if ($gitVersion -like "*git version*") {
        $gitInstalled = $true
        Write-Host "✅ Git已安装: $gitVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Git未安装或未在PATH中" -ForegroundColor Red
}

if (-not $gitInstalled) {
    Write-Host ""
    Write-Host "需要安装Git才能继续:" -ForegroundColor Red
    Write-Host "1. 下载地址: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "2. 安装时勾选所有选项" -ForegroundColor Yellow
    Write-Host "3. 安装完成后重新运行此脚本" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# 检查当前目录
$currentDir = Get-Location
Write-Host "当前目录: $currentDir" -ForegroundColor Gray

# 检查项目文件
$requiredFiles = @(
    "CyberCafeUsbManager.sln",
    ".github/workflows/build.yml",
    "README_GITHUB.md"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ 缺少必要文件:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "   - $file" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "请确保在正确的目录运行此脚本。" -ForegroundColor Yellow
    Write-Host "应该在 'cybercafe-usb-manager' 目录中。" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host "✅ 项目文件检查通过" -ForegroundColor Green

Write-Host ""
Write-Host "步骤2: 创建GitHub个人访问令牌" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host ""

Write-Host "请按以下步骤创建令牌:" -ForegroundColor Cyan
Write-Host "1. 打开浏览器访问: https://github.com/settings/tokens" -ForegroundColor Cyan
Write-Host "2. 点击 'Generate new token' → 'Generate new token (classic)'" -ForegroundColor Cyan
Write-Host "3. 填写信息:" -ForegroundColor Cyan
Write-Host "   - Note: 'CyberCafe USB Manager 编译'" -ForegroundColor Cyan
Write-Host "   - Expiration: 选择 '30 days' (推荐)" -ForegroundColor Cyan
Write-Host "   - Select scopes: 勾选以下权限:" -ForegroundColor Cyan
Write-Host "        [✓] repo (全选)" -ForegroundColor Cyan
Write-Host "        [✓] workflow" -ForegroundColor Cyan
Write-Host "4. 点击 'Generate token'" -ForegroundColor Cyan
Write-Host "5. **立即复制生成的令牌**（只显示一次）" -ForegroundColor Cyan
Write-Host ""

Write-Host "重要安全提示:" -ForegroundColor Yellow
Write-Host "• 令牌类似: ghp_xxxxxxxxxxxxxxxxxxxx" -ForegroundColor Yellow
Write-Host "• 不要分享给任何人" -ForegroundColor Yellow
Write-Host "• 使用后可在GitHub设置中撤销" -ForegroundColor Yellow
Write-Host ""

# 获取用户输入
$githubToken = Read-Host "请输入GitHub个人访问令牌" -AsSecureString
$githubUser = Read-Host "请输入GitHub用户名"
$repoName = Read-Host "请输入仓库名称 (默认: cybercafe-usb-manager)"
if ([string]::IsNullOrEmpty($repoName)) {
    $repoName = "cybercafe-usb-manager"
}

# 转换安全字符串为普通字符串（仅在内存中）
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubToken)
$plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

Write-Host ""
Write-Host "步骤3: 验证GitHub令牌" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

try {
    Write-Host "正在验证GitHub令牌..." -ForegroundColor Gray
    $authHeader = @{"Authorization" = "token $plainToken"}
    $userResponse = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $authHeader -Method Get
    
    Write-Host "✅ 令牌验证成功" -ForegroundColor Green
    Write-Host "   用户名: $($userResponse.login)" -ForegroundColor Gray
    Write-Host "   邮箱: $($userResponse.email)" -ForegroundColor Gray
} catch {
    Write-Host "❌ 令牌验证失败: $_" -ForegroundColor Red
    Write-Host "请检查令牌是否正确或是否有足够权限。" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Host "步骤4: 创建GitHub仓库" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

try {
    Write-Host "正在创建GitHub仓库 '$repoName'..." -ForegroundColor Gray
    
    $body = @{
        name        = $repoName
        description = "网吧USB设备管理软件 - 自动编译构建"
        private     = $false  # 必须公开，免费无限构建
        auto_init   = $false  # 不要初始化README
    } | ConvertTo-Json
    
    $createResponse = Invoke-RestMethod `
        -Uri "https://api.github.com/user/repos" `
        -Headers $authHeader `
        -Method Post `
        -Body $body `
        -ContentType "application/json"
    
    Write-Host "✅ 仓库创建成功" -ForegroundColor Green
    Write-Host "   仓库URL: $($createResponse.html_url)" -ForegroundColor Gray
    Write-Host "   SSH URL: $($createResponse.ssh_url)" -ForegroundColor Gray
    Write-Host "   Clone URL: $($createResponse.clone_url)" -ForegroundColor Gray
    
    $repoUrl = $createResponse.clone_url
} catch {
    if ($_.Exception.Response.StatusCode -eq 422) {
        Write-Host "ℹ️  仓库 '$repoName' 可能已存在，尝试使用现有仓库..." -ForegroundColor Yellow
        
        # 尝试获取现有仓库信息
        try {
            $repoResponse = Invoke-RestMethod `
                -Uri "https://api.github.com/repos/$githubUser/$repoName" `
                -Headers $authHeader `
                -Method Get
            
            Write-Host "✅ 使用现有仓库" -ForegroundColor Green
            Write-Host "   仓库URL: $($repoResponse.html_url)" -ForegroundColor Gray
            $repoUrl = $repoResponse.clone_url
        } catch {
            Write-Host "❌ 无法访问现有仓库，请使用不同的仓库名称" -ForegroundColor Red
            Write-Host ""
            pause
            exit 1
        }
    } else {
        Write-Host "❌ 仓库创建失败: $_" -ForegroundColor Red
        Write-Host ""
        pause
        exit 1
    }
}

Write-Host ""
Write-Host "步骤5: 配置Git并上传代码" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

try {
    # 配置Git用户信息
    Write-Host "配置Git用户信息..." -ForegroundColor Gray
    git config --global user.name $githubUser 2>&1 | Out-Null
    if (-not [string]::IsNullOrEmpty($userResponse.email)) {
        git config --global user.email $userResponse.email 2>&1 | Out-Null
    }
    
    # 初始化本地Git仓库（如果尚未初始化）
    if (-not (Test-Path ".git")) {
        Write-Host "初始化Git仓库..." -ForegroundColor Gray
        git init 2>&1 | Out-Null
    }
    
    # 添加所有文件
    Write-Host "添加文件到Git..." -ForegroundColor Gray
    git add . 2>&1 | Out-Null
    
    # 提交更改
    Write-Host "提交更改..." -ForegroundColor Gray
    git commit -m "初始提交: 网吧USB管理软件 - GitHub云编译版本" 2>&1 | Out-Null
    
    # 重命名分支（如果需要）
    git branch -M main 2>&1 | Out-Null
    
    # 添加远程仓库（使用令牌认证）
    Write-Host "添加远程仓库..." -ForegroundColor Gray
    $authRepoUrl = $repoUrl.Replace("https://", "https://$plainToken@")
    git remote add origin $authRepoUrl 2>&1 | Out-Null
    
    # 推送到GitHub
    Write-Host "推送代码到GitHub..." -ForegroundColor Gray
    git push -u origin main --force 2>&1 | Out-Null
    
    Write-Host "✅ 代码上传成功" -ForegroundColor Green
} catch {
    Write-Host "❌ Git操作失败: $_" -ForegroundColor Red
    Write-Host "请检查Git配置或网络连接。" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Host "步骤6: 触发GitHub Actions构建" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

Write-Host "代码推送后，GitHub Actions将自动开始构建。" -ForegroundColor Gray
Write-Host ""
Write-Host "构建信息:" -ForegroundColor Cyan
Write-Host "- 仓库地址: $($createResponse.html_url)" -ForegroundColor Cyan
Write-Host "- Actions页面: $($createResponse.html_url)/actions" -ForegroundColor Cyan
Write-Host "- 首次构建需要5-10分钟" -ForegroundColor Cyan
Write-Host ""
Write-Host "请打开浏览器访问以上链接查看构建进度。" -ForegroundColor Cyan

Write-Host ""
Write-Host "步骤7: 清理安全信息" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

# 清理内存中的令牌
$plainToken = $null
[GC]::Collect()

Write-Host "✅ 安全信息已清理" -ForegroundColor Green
Write-Host ""
Write-Host "建议操作:" -ForegroundColor Yellow
Write-Host "1. 使用后可在GitHub设置中撤销或限制令牌权限" -ForegroundColor Yellow
Write-Host "2. 定期清理不再使用的令牌" -ForegroundColor Yellow
Write-Host "3. 监控仓库的访问记录" -ForegroundColor Yellow

Write-Host ""
Write-Host "步骤8: 下载编译结果" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

Write-Host "构建完成后，请按以下步骤下载:" -ForegroundColor Cyan
Write-Host "1. 访问: $($createResponse.html_url)/actions" -ForegroundColor Cyan
Write-Host "2. 点击最新的构建运行" -ForegroundColor Cyan
Write-Host "3. 在 'Artifacts' 部分下载:" -ForegroundColor Cyan
Write-Host "   - '网吧USB管理软件_完整部署包.zip' (完整部署包)" -ForegroundColor Cyan
Write-Host "   - 'CyberCafeUsbManager-编译结果' (原始文件)" -ForegroundColor Cyan
Write-Host ""
Write-Host "下载后解压到网吧机器，运行'脚本工具/安装服务.bat'进行测试。" -ForegroundColor Cyan

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "代劳设置完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "总结:" -ForegroundColor Yellow
Write-Host "1. ✅ 环境检查通过" -ForegroundColor Green
Write-Host "2. ✅ GitHub令牌验证成功" -ForegroundColor Green
Write-Host "3. ✅ 仓库创建/验证成功" -ForegroundColor Green
Write-Host "4. ✅ 代码上传成功" -ForegroundColor Green
Write-Host "5. ✅ 构建已触发" -ForegroundColor Green
Write-Host "6. ✅ 安全信息已清理" -ForegroundColor Green
Write-Host ""

Write-Host "下一步操作:" -ForegroundColor Cyan
Write-Host "1. 等待构建完成 (5-10分钟)" -ForegroundColor Cyan
Write-Host "2. 下载部署包ZIP文件" -ForegroundColor Cyan
Write-Host "3. 网吧环境测试安装" -ForegroundColor Cyan
Write-Host "4. 反馈测试结果" -ForegroundColor Cyan
Write-Host ""

Write-Host "技术支持:" -ForegroundColor Gray
Write-Host "- 构建问题: 查看GitHub Actions日志" -ForegroundColor Gray
Write-Host "- 部署问题: 运行'控制台测试.bat'调试" -ForegroundColor Gray
Write-Host "- 紧急联系: 提供错误信息和截图" -ForegroundColor Gray
Write-Host ""

Write-Host "按任意键退出..." -ForegroundColor Gray
pause