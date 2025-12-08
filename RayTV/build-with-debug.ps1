# 使用调试模式构建项目的PowerShell脚本
Write-Host "开始使用调试模式构建项目..."

# 设置工作目录
Set-Location -Path "d:\tv\RayTV"

# 使用完整的DevEco Studio路径执行构建命令
try {
    Write-Host "执行命令: node ""C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js"" --mode module -p module=raytv@default assembleHap --debug"
    node "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=raytv@default assembleHap --debug
    Write-Host "构建完成"
} catch {
    Write-Host "构建失败: $_"
}

Write-Host "构建过程结束"