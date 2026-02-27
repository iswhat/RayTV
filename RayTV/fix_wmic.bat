@echo off
title WMIC 修复工具
color 0A

echo ========================================
echo        WMIC 功能修复工具
echo ========================================
echo.

echo 正在检查 WMIC 状态...
echo.

REM 检查当前 WMIC 状态
powershell "Get-WindowsOptionalFeature -Online -FeatureName WMIC" > temp_wmic_check.txt 2>&1

findstr /i "Enabled" temp_wmic_check.txt >nul
if %errorlevel% equ 0 (
    echo ✓ WMIC 功能已启用
    goto :test_wmic
)

findstr /i "Disabled" temp_wmic_check.txt >nul
if %errorlevel% equ 0 (
    echo ✗ WMIC 功能未启用
    echo 正在尝试启用 WMIC...
    
    REM 尝试启用 WMIC（需要管理员权限）
    powershell "Start-Process powershell -ArgumentList 'Enable-WindowsOptionalFeature -Online -FeatureName WMIC -NoRestart' -Verb RunAs" 2>nul
    
    if %errorlevel% equ 0 (
        echo ✓ 已发送启用请求（可能需要管理员权限）
        echo 请以管理员身份重新运行此脚本
    ) else (
        echo ✗ 启用失败，请手动以管理员身份运行以下命令：
        echo   Enable-WindowsOptionalFeature -Online -FeatureName WMIC
    )
    goto :cleanup
)

:test_wmic
echo.
echo 正在测试 WMIC 功能...
wmic os get caption >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ WMIC 测试通过
) else (
    echo ✗ WMIC 测试失败
    echo 可能需要重启系统或检查权限
)

:cleanup
echo.
echo 清理临时文件...
del temp_wmic_check.txt 2>nul

echo.
echo 修复完成！
echo 如果问题仍然存在，请：
echo 1. 以管理员身份重启 DevEco Studio
echo 2. 重启计算机
echo 3. 检查 Windows 功能中是否启用了 WMI
pause