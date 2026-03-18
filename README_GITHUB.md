# 网吧USB管理软件 - GitHub云编译指南

## 🚀 快速开始（5分钟完成设置）

### 前提条件
1. **GitHub账号**（免费注册：https://github.com）
2. **Git客户端**（下载：https://git-scm.com/download/win）
3. **5-10分钟时间**

## 方法一：使用自动脚本（推荐）

### Windows用户
1. **下载项目文件**（确保有`cybercafe-usb-manager`文件夹）
2. **打开PowerShell**：
   - 右键点击`cybercafe-usb-manager`文件夹
   - 选择"在终端中打开"或"Open PowerShell here"
3. **运行设置脚本**：
   ```powershell
   .\setup_github.ps1
   ```
4. **按照脚本提示操作**

## 方法二：手动设置（分步指南）

### 步骤1：创建GitHub仓库
1. 访问 https://github.com
2. 登录/注册账号
3. 点击右上角"+" → "New repository"
4. 填写信息：
   - **Repository name**: `cybercafe-usb-manager`
   - **Description**: `网吧USB设备管理软件`
   - **Visibility**: **Public**（重要！公开仓库免费无限构建）
   - **不要勾选** "Initialize this repository with README"
5. 点击"Create repository"

### 步骤2：上传代码到GitHub
```bash
# 打开命令行，进入项目目录
cd C:\Users\您的用户名\Desktop\cybercafe-usb-manager

# 初始化Git仓库
git init
git add .
git commit -m "初始提交: 网吧USB管理软件V1.0"
git branch -M main

# 连接到GitHub
git remote add origin https://github.com/您的用户名/cybercafe-usb-manager.git

# 推送代码
git push -u origin main
```

### 步骤3：触发构建
1. 代码推送后，GitHub Actions自动开始构建
2. 访问您的仓库页面
3. 点击"Actions"选项卡查看构建状态

### 步骤4：下载编译结果
1. 构建完成后（约5-10分钟）
2. 进入"Actions"页面
3. 点击最新的构建运行
4. 在"Artifacts"部分下载：
   - **网吧USB管理软件_完整部署包.zip** - 完整部署包
   - **CyberCafeUsbManager-编译结果** - 原始编译文件

## 📁 文件说明

### GitHub Actions配置
```
.github/workflows/build.yml  # 自动构建配置
```

### 构建过程
1. **环境准备**: Windows Server 2022 + .NET Framework
2. **工具安装**: MSBuild, NuGet
3. **编译项目**: 生成Release版本
4. **打包**: 创建完整部署包
5. **上传**: 生成可下载的Artifacts

### 输出文件结构
```
部署包/
├── 主程序/           # 编译好的EXE和DLL
├── 配置文件/         # USB设备数据库和配置
├── 脚本工具/         # 安装和管理脚本
├── 驱动程序/         # 品牌驱动目录（空）
└── 说明文档/         # 使用指南
```

## ⚙️ 构建配置详情

### 构建环境
- **操作系统**: Windows Server 2022 (windows-latest)
- **.NET Framework**: 4.7.2+ (系统自带)
- **构建工具**: MSBuild + NuGet
- **构建时间**: 5-10分钟

### 构建触发条件
- 推送到main/master分支
- 创建Pull Request
- 手动触发（Workflow Dispatch）

## 🔧 故障排除

### 常见问题1：构建失败 "NuGet包恢复失败"
**解决方案**:
1. 检查网络连接
2. 确保NuGet源配置正确
3. 手动恢复包：
   ```bash
   nuget restore CyberCafeUsbManager.sln
   ```

### 常见问题2：构建成功但程序无法运行
**解决方案**:
1. 确保Windows 10/11系统
2. 安装.NET Framework 4.7.2运行时
3. 以管理员身份运行程序

### 常见问题3：Git推送失败
**解决方案**:
1. 检查GitHub Personal Access Token
2. 配置Git认证：
   ```bash
   git config --global user.name "您的用户名"
   git config --global user.email "您的邮箱"
   ```

### 常见问题4：私有仓库构建时间不足
**解决方案**:
1. **推荐**: 转为公开仓库（免费无限构建）
2. 升级到GitHub Pro
3. 使用Azure DevOps免费套餐

## 📊 构建状态徽章

添加构建状态到README：
```markdown
![构建状态](https://github.com/您的用户名/cybercafe-usb-manager/workflows/.NET%20Framework%204.7.2%20Build/badge.svg)
```

## 🔄 更新代码并重新构建

### 代码更新流程
1. 修改代码文件
2. 提交更改：
   ```bash
   git add .
   git commit -m "更新: 修复XXX问题"
   git push origin main
   ```
3. GitHub Actions自动重新构建
4. 下载新的构建结果

### 手动触发构建
1. 访问仓库"Actions"页面
2. 选择".NET Framework 4.7.2 Build"工作流
3. 点击"Run workflow"
4. 选择分支并运行

## 📞 技术支持

### 问题反馈渠道
请提供以下信息：
```
1. GitHub仓库URL
2. 构建运行ID
3. 错误日志截图
4. 重现步骤
```

### 紧急联系方式
- **开发者**: 络络 (OpenClaw AI助手)
- **支持范围**: 云编译配置、构建错误、部署问题

### 预计时间表
- **首次设置**: 10-15分钟
- **首次构建**: 5-10分钟
- **后续构建**: 3-5分钟
- **下载部署**: 2-3分钟

## 🎯 成功标准

### 构建成功标志
1. ✅ GitHub Actions显示绿色对勾
2. ✅ Artifacts中有ZIP文件可下载
3. ✅ ZIP文件大小 > 1MB（包含所有文件）
4. ✅ 解压后包含完整的目录结构

### 部署成功标志
1. ✅ 服务可安装（installutil/sc成功）
2. ✅ 服务可启动（状态为RUNNING）
3. ✅ USB设备可识别（事件查看器有日志）
4. ✅ 驱动可安装（设备管理器无感叹号）

## 📝 注意事项

### 重要提醒
1. **仓库必须设为Public**（免费无限构建时间）
2. **确保.NET Framework 4.7.2**（Windows 10自带）
3. **管理员权限**（安装服务时需要）
4. **网吧环境测试**（建议先在单机测试）

### 文件保留
- 构建产物保留30天
- 可随时重新触发构建
- 建议下载后本地备份

## 🚀 下一步操作

### 立即开始
1. [ ] 注册GitHub账号（如无）
2. [ ] 安装Git客户端
3. [ ] 创建公开仓库
4. [ ] 上传代码
5. [ ] 等待构建完成
6. [ ] 下载部署包
7. [ ] 网吧测试

### 长期维护
1. 代码更新 → 自动构建
2. 版本发布 → 创建Release
3. 问题修复 → 提交PR
4. 功能扩展 → 分支开发

---
**最后更新**: 2026-03-18  
**版本**: GitHub云编译指南 V1.0  
**状态**: 就绪，等待执行