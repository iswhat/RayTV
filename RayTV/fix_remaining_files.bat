@echo off
echo ========================================
echo ArkTS批量修复工具 - Windows版
echo ========================================
echo.

cd /d d:\tv\RayTV

echo 正在修复console调用...
echo.

for /r "raytv\src\main\ets" %%f in (*.ets) do (
    powershell -Command "(Get-Content '%%f') -replace 'console\.info\(', 'Logger.info(' -replace 'console\.error\(', 'Logger.error(' -replace 'console\.warn\(', 'Logger.warn(' -replace 'console\.debug\(', 'Logger.debug(' -replace 'console\.log\(', 'Logger.info(' | Set-Content '%%f'"
    echo 已修复: %%f
)

echo.
echo ========================================
echo 批量修复完成!
echo ========================================
echo.
echo 注意: 此脚本只修复console调用
echo 其他类型的错误需要手动处理
echo.
pause
