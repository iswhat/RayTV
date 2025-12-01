#!/usr/bin/env pwsh

# RayTV构建清理脚本
# 用于替代缺失的clean任务，清理项目构建产物

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RayTV 构建清理脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 设置清理目录列表
$directoriesToRemove = @(
    "$PSScriptRoot\build",
    "$PSScriptRoot\raytv\build",
    "$PSScriptRoot\.hvigor",
    "$PSScriptRoot\raytv\.hvigor"
)

# 清理构建目录
foreach ($dir in $directoriesToRemove) {
    if (Test-Path $dir) {
        Write-Host "清理目录: $dir" -ForegroundColor Yellow
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $dir)) {
            Write-Host "✓ 成功清理: $dir" -ForegroundColor Green
        } else {
            Write-Host "✗ 清理失败: $dir" -ForegroundColor Red
        }
    } else {
        Write-Host "目录不存在: $dir" -ForegroundColor Gray
    }
}

# 运行prune任务清理缓存（如果可用）
Write-Host "\n执行prune任务清理缓存..." -ForegroundColor Yellow
try {
    $nodePath = "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe"
    $hvigorPath = "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js"
    
    if (Test-Path $nodePath -and Test-Path $hvigorPath) {
        & $nodePath $hvigorPath prune
        Write-Host "✓ prune任务执行完成" -ForegroundColor Green
    } else {
        Write-Host "✗ 找不到DevEco Studio工具链，跳过prune任务" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ prune任务执行失败: $_" -ForegroundColor Red
}

Write-Host "\n========================================" -ForegroundColor Cyan
Write-Host "清理完成!" -ForegroundColor Green
Write-Host "注意：此脚本替代了缺失的clean任务" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "\n使用方法：" -ForegroundColor Gray
Write-Host "1. 构建前执行此脚本清理旧的构建产物" -ForegroundColor Gray
Write-Host "2. 然后使用DevEco Studio或其他构建命令进行构建" -ForegroundColor Gray
