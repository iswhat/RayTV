# HarmonyOS 构建环境检查脚本
# 用于验证RayTV项目构建所需的环境组件

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RayTV 构建环境检查脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 检查DevEco Studio SDK目录
$devecoSdkPath = "C:\Program Files\Huawei\DevEco Studio\sdk"
Write-Host "\n检查DevEco Studio SDK..."
if (Test-Path $devecoSdkPath) {
    Write-Host "✅ DevEco SDK 路径存在: $devecoSdkPath" -ForegroundColor Green
    
    # 检查SDK版本信息
    $configJsonPath = "$devecoSdkPath\config.json"
    if (Test-Path $configJsonPath) {
        Write-Host "✅ SDK配置文件存在" -ForegroundColor Green
    } else {
        Write-Host "⚠️ SDK配置文件不存在" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ DevEco SDK 路径不存在: $devecoSdkPath" -ForegroundColor Red
    Write-Host "   请安装DevEco Studio并配置正确的SDK路径" -ForegroundColor Yellow
}

# 检查hvigor工具
$hvigorPath = "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js"
Write-Host "\n检查Hvigor构建工具..."
if (Test-Path $hvigorPath) {
    Write-Host "✅ Hvigor 工具存在: $hvigorPath" -ForegroundColor Green
    
    # 尝试获取hvigor版本信息
    try {
        Write-Host "正在检查Hvigor版本..."
        $hvigorVersion = node "$hvigorPath" --version 2>$null
        if ($hvigorVersion) {
            Write-Host "✅ Hvigor 版本: $hvigorVersion" -ForegroundColor Green
        } else {
            Write-Host "⚠️ 无法获取Hvigor版本信息" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ 获取Hvigor版本信息失败: $_" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Hvigor 工具不存在: $hvigorPath" -ForegroundColor Red
    Write-Host "   请安装最新版本的DevEco Studio" -ForegroundColor Yellow
}

# 检查Node.js环境
Write-Host "\n检查Node.js环境..."
try {
    $nodeVersion = node -v 2>$null
    if ($nodeVersion) {
        Write-Host "✅ Node.js 版本: $nodeVersion" -ForegroundColor Green
        
        # 检查npm
        $npmVersion = npm -v 2>$null
        if ($npmVersion) {
            Write-Host "✅ npm 版本: $npmVersion" -ForegroundColor Green
        } else {
            Write-Host "❌ npm 未找到" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Node.js 未找到" -ForegroundColor Red
        Write-Host "   请安装Node.js 16.x或更高版本" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ 检查Node.js环境失败: $_" -ForegroundColor Red
}

# 检查项目配置文件
Write-Host "\n检查项目配置文件..."
$projectFiles = @(
    "D:\tv\RayTV\hvigorfile.ts",
    "D:\tv\RayTV\build-profile.json5",
    "D:\tv\RayTV\raytv\hvigorfile.ts",
    "D:\tv\RayTV\raytv\build-profile.json5",
    "D:\tv\RayTV\raytv\app.json5"
)

foreach ($file in $projectFiles) {
    if (Test-Path $file) {
        Write-Host "✅ 项目文件存在: $file" -ForegroundColor Green
    } else {
        Write-Host "❌ 项目文件不存在: $file" -ForegroundColor Red
    }
}

# 检查oh-package.json5文件
Write-Host "\n检查依赖配置..."
$ohPackagePath = "D:\tv\RayTV\raytv\oh-package.json5"
if (Test-Path $ohPackagePath) {
    Write-Host "✅ 依赖配置文件存在: $ohPackagePath" -ForegroundColor Green
    Write-Host "   注意: 由于网络限制，依赖可能无法自动下载" -ForegroundColor Yellow
    Write-Host "   建议: 在可访问华为内部仓库时执行 'npm install'" -ForegroundColor Cyan
} else {
    Write-Host "❌ 依赖配置文件不存在: $ohPackagePath" -ForegroundColor Red
}

# 检查构建脚本
Write-Host "\n检查构建脚本..."
$buildScriptPath = "D:\tv\RayTV\build-no-hotreload.ps1"
if (Test-Path $buildScriptPath) {
    Write-Host "✅ 构建脚本存在: $buildScriptPath" -ForegroundColor Green
    Write-Host "   执行命令: .\build-no-hotreload.ps1" -ForegroundColor Cyan
} else {
    Write-Host "❌ 构建脚本不存在: $buildScriptPath" -ForegroundColor Red
}

Write-Host "\n========================================" -ForegroundColor Cyan
Write-Host "环境检查完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "\n注意事项:" -ForegroundColor Yellow
Write-Host "1. 由于网络限制，缺少@ohos/hvigor-ohos-plugin等关键依赖包" -ForegroundColor Yellow
Write-Host "2. 建议使用VPN/代理访问华为内部npm仓库" -ForegroundColor Yellow
Write-Host "3. 或通过DevEco Studio IDE进行构建" -ForegroundColor Yellow
Write-Host "4. 或手动获取依赖包并安装" -ForegroundColor Yellow
