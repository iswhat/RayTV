@echo off
echo === RayTV项目构建脚本 ===
echo 开始构建项目...

cd /d "d:\tv\RayTV"

echo 当前目录: %cd%

echo 检查必要的文件和目录...
if not exist "d:\tv\RayTV\raytv" (
    echo 错误: 未找到raytv模块目录
    exit /b 1
)

if not exist "d:\tv\RayTV\AppScope" (
    echo 错误: 未找到AppScope目录
    exit /b 1
)

echo 项目结构检查通过

echo 检查DevEco Studio工具...
set devEcoPath=C:\Program Files\Huawei\DevEco Studio
set hvigorPath=%devEcoPath%\tools\hvigor\bin\hvigorw.bat

if not exist "%hvigorPath%" (
    echo 错误: 未找到hvigor工具，请检查DevEco Studio安装
    echo 路径: %hvigorPath%
    exit /b 1
)

echo 找到hvigor工具: %hvigorPath%

echo 尝试不同的构建命令...

echo 1. 尝试基本的assembleHap命令...
call "%hvigorPath%" assembleHap
if %errorlevel% == 0 (
    echo.
    echo ========== 构建成功完成! ==========
    exit /b 0
)

echo.
echo 2. 尝试模块级构建命令...
call "%hvigorPath%" --mode module -p module=raytv@default
if %errorlevel% == 0 (
    echo.
    echo ========== 构建成功完成! ==========
    exit /b 0
)

echo.
echo 3. 尝试使用build命令...
call "%hvigorPath%" build
if %errorlevel% == 0 (
    echo.
    echo ========== 构建成功完成! ==========
    exit /b 0
)

echo.
echo 4. 查看可用任务...
call "%hvigorPath%" tasks

echo.
echo ========== 所有构建尝试均失败 ==========
echo 建议:
echo 1. 使用DevEco Studio IDE打开项目并构建
echo 2. 检查网络连接，确保可以访问华为仓库
echo 3. 手动安装缺失的依赖项
exit /b 1