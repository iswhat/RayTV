# 简化版构建脚本
# 使用DevEco Studio的工具来构建项目

Write-Host "=== RayTV项目构建脚本 ==="
Write-Host "开始构建项目..."

# 设置工作目录
Set-Location -Path "d:\tv\RayTV"

# 检查必要的文件和目录
Write-Host "检查项目结构..."
if (!(Test-Path "d:\tv\RayTV\raytv")) {
    Write-Host "错误: 未找到raytv模块目录"
    exit 1
}

if (!(Test-Path "d:\tv\RayTV\AppScope")) {
    Write-Host "错误: 未找到AppScope目录"
    exit 1
}

Write-Host "项目结构检查通过"

# 使用DevEco Studio的hvigor工具构建
$devEcoPath = "C:\Program Files\Huawei\DevEco Studio"
$hvigorPath = "$devEcoPath\tools\hvigor\bin\hvigorw.bat"

if (Test-Path $hvigorPath) {
    Write-Host "找到hvigor工具: $hvigorPath"
    
    # 尝试不同的构建命令
    Write-Host "尝试构建命令1: 模块级构建"
    try {
        & "$hvigorPath" --mode module -p module=raytv@default assembleHap
        if ($LASTEXITCODE -eq 0) {
            Write-Host "构建成功完成!"
            exit 0
        } else {
            Write-Host "模块级构建失败，尝试项目级构建..."
        }
    } catch {
        Write-Host "模块级构建出错: $_"
    }
    
    Write-Host "尝试构建命令2: 项目级构建"
    try {
        & "$hvigorPath" assembleHap
        if ($LASTEXITCODE -eq 0) {
            Write-Host "构建成功完成!"
            exit 0
        } else {
            Write-Host "项目级构建失败"
        }
    } catch {
        Write-Host "项目级构建出错: $_"
    }
    
    Write-Host "尝试构建命令3: 使用build任务"
    try {
        & "$hvigorPath" build
        if ($LASTEXITCODE -eq 0) {
            Write-Host "构建成功完成!"
            exit 0
        } else {
            Write-Host "build任务执行失败"
        }
    } catch {
        Write-Host "build任务执行出错: $_"
    }
} else {
    Write-Host "错误: 未找到hvigor工具，请检查DevEco Studio安装"
    exit 1
}

Write-Host "所有构建尝试均失败"
Write-Host "建议使用DevEco Studio IDE打开项目并构建"
exit 1