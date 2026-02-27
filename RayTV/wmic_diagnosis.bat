@echo off
echo ========== WMIC 诊断工具 ==========
echo.

echo 1. 检查WMIC是否可用:
wmic os get caption 2>nul
if %errorlevel% equ 0 (
    echo ✓ WMIC命令正常工作
) else (
    echo ✗ WMIC命令无法执行
)

echo.
echo 2. 检查系统信息:
systeminfo | findstr "OS Name" 2>nul
if %errorlevel% neq 0 (
    echo 系统信息获取失败
)

echo.
echo 3. 检查Windows版本:
ver

echo.
echo 4. 检查PATH环境变量:
echo %PATH%

echo.
echo 5. 检查WMIC文件位置:
where wmic 2>nul
if %errorlevel% neq 0 (
    echo WMIC可执行文件未找到
    echo 尝试在系统目录查找...
    dir "C:\Windows\System32\wbem\wmic.exe" 2>nul
)

echo.
echo 6. 检查WMIC功能状态:
powershell "Get-WindowsOptionalFeature -Online -FeatureName WMIC" 2>nul

pause