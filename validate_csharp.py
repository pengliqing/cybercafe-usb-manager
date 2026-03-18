#!/usr/bin/env python3
"""
C#代码验证脚本
检查基本语法错误和常见问题
"""

import os
import re
import sys

class CSharpValidator:
    def __init__(self, project_dir):
        self.project_dir = project_dir
        self.cs_files = []
        self.issues = []
        
    def find_cs_files(self):
        """查找所有.cs文件"""
        for root, dirs, files in os.walk(self.project_dir):
            for file in files:
                if file.endswith('.cs'):
                    self.cs_files.append(os.path.join(root, file))
        print(f"找到 {len(self.cs_files)} 个C#文件")
        return self.cs_files
    
    def check_file(self, filepath):
        """检查单个文件"""
        issues = []
        
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                lines = content.split('\n')
                
            # 检查UTF-8 BOM（可选）
            # 检查文件编码问题
            
            # 检查命名空间
            if 'namespace' not in content:
                issues.append("缺少namespace声明")
            
            # 检查类定义
            class_pattern = r'class\s+\w+'
            if not re.search(class_pattern, content):
                issues.append("未找到类定义")
            
            # 检查using语句
            using_count = len(re.findall(r'^\s*using\s+', content, re.MULTILINE))
            if using_count == 0:
                issues.append("缺少using语句")
            
            # 检查常见语法错误
            # 1. 未闭合的括号
            open_braces = content.count('{')
            close_braces = content.count('}')
            if open_braces != close_braces:
                issues.append(f"括号不匹配: {{={open_braces}, }}={close_braces}")
            
            # 2. 未闭合的字符串
            double_quotes = content.count('"')
            if double_quotes % 2 != 0:
                issues.append('双引号不匹配')
            
            single_quotes = content.count("'")
            if single_quotes % 2 != 0:
                issues.append("单引号不匹配")
            
            # 3. 检查常见编译错误模式
            # 未闭合的注释
            comment_blocks = len(re.findall(r'/\*', content))
            comment_end_blocks = len(re.findall(r'\*/', content))
            if comment_blocks != comment_end_blocks:
                issues.append("多行注释未闭合")
            
            # 4. 检查TODO注释
            todo_count = len(re.findall(r'//\s*TODO', content, re.IGNORECASE))
            if todo_count > 0:
                issues.append(f"发现{todo_count}个TODO注释")
            
            # 5. 检查空的catch块
            empty_catch = len(re.findall(r'catch\s*\([^)]*\)\s*\{?\s*\}', content))
            if empty_catch > 0:
                issues.append("发现空的catch块")
                
        except Exception as e:
            issues.append(f"读取文件失败: {str(e)}")
        
        return issues
    
    def check_project_structure(self):
        """检查项目结构"""
        issues = []
        
        # 检查必要的文件
        required_files = [
            'CyberCafeUsbManager.csproj',
            'Program.cs',
            'UsbMonitorService.cs',
            'ProjectInstaller.cs'
        ]
        
        for file in required_files:
            path = os.path.join(self.project_dir, 'CyberCafeUsbManager', file)
            if not os.path.exists(path):
                issues.append(f"缺少必要文件: {file}")
        
        # 检查.csproj文件
        csproj_path = os.path.join(self.project_dir, 'CyberCafeUsbManager', 'CyberCafeUsbManager.csproj')
        if os.path.exists(csproj_path):
            try:
                with open(csproj_path, 'r') as f:
                    csproj_content = f.read()
                
                # 检查目标框架
                if 'TargetFramework' not in csproj_content:
                    issues.append("csproj文件中缺少TargetFramework设置")
                
                # 检查输出类型
                if 'OutputType' not in csproj_content:
                    issues.append("csproj文件中缺少OutputType设置")
                    
            except Exception as e:
                issues.append(f"无法读取csproj文件: {str(e)}")
        
        return issues
    
    def run(self):
        """运行验证"""
        print("=" * 60)
        print("C#代码验证报告")
        print("=" * 60)
        
        # 检查项目结构
        print("\n1. 项目结构检查:")
        structure_issues = self.check_project_structure()
        if structure_issues:
            for issue in structure_issues:
                print(f"  ❌ {issue}")
                self.issues.append(f"结构: {issue}")
        else:
            print("  ✅ 项目结构完整")
        
        # 检查所有CS文件
        print(f"\n2. C#文件语法检查 ({len(self.cs_files)} 个文件):")
        self.find_cs_files()
        
        total_issues = 0
        for cs_file in self.cs_files:
            relative_path = os.path.relpath(cs_file, self.project_dir)
            file_issues = self.check_file(cs_file)
            
            if file_issues:
                print(f"\n  📄 {relative_path}:")
                for issue in file_issues:
                    print(f"    ❌ {issue}")
                    self.issues.append(f"{relative_path}: {issue}")
                    total_issues += 1
            else:
                print(f"  ✅ {relative_path}")
        
        # 生成总结报告
        print("\n" + "=" * 60)
        print("验证总结:")
        print(f"总文件数: {len(self.cs_files)}")
        print(f"发现问题: {total_issues} 个")
        
        if total_issues == 0:
            print("✅ 代码验证通过！未发现明显语法问题。")
            print("注意：这仅是基本语法检查，仍需在实际环境中编译测试。")
            return True
        else:
            print("⚠️  发现一些问题，建议修复后再编译。")
            return False

def main():
    # 项目目录
    project_dir = os.path.dirname(os.path.abspath(__file__))
    validator = CSharpValidator(project_dir)
    
    success = validator.run()
    
    # 生成建议
    print("\n" + "=" * 60)
    print("后续步骤建议:")
    print("1. 在Windows环境中使用Visual Studio编译")
    print("2. 或使用以下命令编译:")
    print("   - msbuild CyberCafeUsbManager.sln /p:Configuration=Release")
    print("   - dotnet build CyberCafeUsbManager.sln -c Release")
    print("3. 测试服务安装和基本功能")
    print("4. 在网吧环境中部署测试")
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()