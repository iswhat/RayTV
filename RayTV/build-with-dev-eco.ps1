# 使用DevEco Studio工具构建项目的PowerShell脚本
Write-Host "开始使用DevEco Studio工具构建项目..."

# 设置工作目录
Set-Location -Path "d:\tv\RayTV"

# 检查DevEco Studio hvigor工具是否存在
$hvigorPath = "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat"
if (Test-Path $hvigorPath) {
    Write-Host "找到hvigor工具: $hvigorPath"
    
    # 尝试使用DevEco Studio的hvigor工具构建项目
    try {
        Write-Host "执行命令: & `"$hvigorPath`" --mode module -p module=raytv@default assembleHap"
        & "$hvigorPath" --mode module -p module=raytv@default assembleHap
        Write-Host "构建完成"
    } catch {
        Write-Host "构建失败: $_"
    }
} else {
    Write-Host "未找到hvigor工具，请检查DevEco Studio安装路径"
}

Write-Host "构建过程结束"