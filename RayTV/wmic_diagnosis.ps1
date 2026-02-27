# WMIC 诊断 PowerShell 脚本
Write-Host "========== WMIC 诊断工具 ==========" -ForegroundColor Green
Write-Host ""

# 检查 Windows 版本
Write-Host "1. Windows 版本信息:" -ForegroundColor Yellow
$os = Get-WmiObject -Class Win32_OperatingSystem
Write-Host "  $($os.Caption) ($($os.Version))" -ForegroundColor White

# 检查 WMIC 可选功能状态
Write-Host "`n2. WMIC 可选功能状态:" -ForegroundColor Yellow
try {
    $wmicFeature = Get-WindowsOptionalFeature -Online -FeatureName WMIC -ErrorAction Stop
    Write-Host "  状态: $($wmicFeature.State)" -ForegroundColor White
    if ($wmicFeature.State -ne "Enabled") {
        Write-Host "  需要启用 WMIC 功能" -ForegroundColor Red
    }
} catch {
    Write-Host "  无法查询 WMIC 功能状态: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查 WMIC 可执行文件
Write-Host "`n3. WMIC 可执行文件检查:" -ForegroundColor Yellow
$wmicPaths = @(
    "C:\Windows\System32\wbem\wmic.exe",
    "C:\Windows\SysWOW64\wbem\wmic.exe"
)

foreach ($path in $wmicPaths) {
    if (Test-Path $path) {
        Write-Host "  找到: $path" -ForegroundColor Green
        try {
            $versionInfo = (Get-Item $path).VersionInfo
            Write-Host "    版本: $($versionInfo.FileVersion)" -ForegroundColor White
        } catch {
            Write-Host "    无法获取版本信息" -ForegroundColor Gray
        }
    } else {
        Write-Host "  未找到: $path" -ForegroundColor Red
    }
}

# 测试 WMIC 命令
Write-Host "`n4. WMIC 命令测试:" -ForegroundColor Yellow
try {
    $result = wmic os get Caption /value 2>$null
    if ($LASTEXITCODE -eq 0 -and $result) {
        Write-Host "  ✓ WMIC 命令执行成功" -ForegroundColor Green
        Write-Host "  结果: $result" -ForegroundColor White
    } else {
        Write-Host "  ✗ WMIC 命令执行失败" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ WMIC 命令无法执行: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查环境变量
Write-Host "`n5. 环境变量检查:" -ForegroundColor Yellow
$system32Path = "C:\Windows\System32\wbem"
if ($env:PATH -like "*$system32Path*") {
    Write-Host "  PATH 包含 WBEM 目录: ✓" -ForegroundColor Green
} else {
    Write-Host "  PATH 不包含 WBEM 目录: ✗" -ForegroundColor Red
    Write-Host "  建议添加: $system32Path" -ForegroundColor Yellow
}

Write-Host "`n========== 诊断完成 ==========" -ForegroundColor Green

# 提供修复建议
Write-Host "`n修复建议:" -ForegroundColor Cyan
Write-Host "1. 如果 WMIC 功能未启用，请以管理员身份运行:" -ForegroundColor White
Write-Host "   Enable-WindowsOptionalFeature -Online -FeatureName WMIC" -ForegroundColor Yellow
Write-Host "2. 重启计算机后再次测试" -ForegroundColor White
Write-Host "3. 确保 DevEco Studio 以管理员权限运行" -ForegroundColor White