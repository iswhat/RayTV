@echo off
echo === RayTV项目构建脚本 ===
echo 开始构建项目...

cd /d "d:\tv\RayTV"

echo 检查项目结构...
if not exist "d:\tv\RayTV\raytv" (
    echo 错误: 未找到raytv模块目录
    exit /b 1
)

if not exist "d:\tv\RayTV\AppScope" (
    echo 错误: 未找到AppScope目录
    exit /b 1
)

echo 项目结构检查通过

set devEcoPath=C:\Program Files\Huawei\DevEco Studio
set hvigorPath=%devEcoPath%\tools\hvigor\bin\hvigorw.bat

if exist "%hvigorPath%" (
    echo 找到hvigor工具: %hvigorPath%
    
    echo 尝试构建命令: 模块级构建
    call "%hvigorPath%" --mode module -p module=raytv@default assembleHap
    if %errorlevel% == 0 (
        echo 构建成功完成!
        exit /b 0
    ) else (
        echo 模块级构建失败
    )
    
    echo 尝试构建命令: 项目级构建
    call "%hvigorPath%" assembleHap
    if %errorlevel% == 0 (
        echo 构建成功完成!
        exit /b 0
    ) else (
        echo 项目级构建失败
    )
    
    echo 尝试构建命令: 使用build任务
    call "%hvigorPath%" build
    if %errorlevel% == 0 (
        echo 构建成功完成!
        exit /b 0
    ) else (
        echo build任务执行失败
    )
) else (
    echo 错误: 未找到hvigor工具，请检查DevEco Studio安装
    exit /b 1
)

echo 所有构建尝试均失败
echo 建议使用DevEco Studio IDE打开项目并构建
exit /b 1