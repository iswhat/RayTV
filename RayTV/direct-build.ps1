# 直接构建脚本
Write-Host "Starting build process..."

# 设置工作目录
Set-Location -Path "d:\tv\RayTV"

# 尝试运行assembleApp命令
try {
    Write-Host "Running: node `"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js`" assembleApp"
    node "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" assembleApp
    Write-Host "Build completed successfully"
} catch {
    Write-Host "Build failed with error: $_"
}

Write-Host "Build process finished"