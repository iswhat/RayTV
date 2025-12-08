@echo off
echo === RayTV项目构建脚本 ===
echo 开始构建项目...

cd /d "d:\tv\RayTV"

echo 当前目录: %cd%

echo 检查必要的工具...
set devEcoPath=C:\Program Files\Huawei\DevEco Studio
set hvigorPath=%devEcoPath%\tools\hvigor\bin\hvigorw.bat

if not exist "%hvigorPath%" (
    echo 错误: 未找到hvigor工具，请检查DevEco Studio安装
    echo 路径: %hvigorPath%
    exit /b 1
)

echo 找到hvigor工具: %hvigorPath%

echo 尝试构建项目...
call "%hvigorPath%" --mode module -p module=raytv@default assembleHap

if %errorlevel% == 0 (
    echo.
    echo ========== 构建成功完成! ==========
    exit /b 0
) else (
    echo.
    echo ========== 构建失败 ==========
    echo 错误代码: %errorlevel%
    exit /b 1
)