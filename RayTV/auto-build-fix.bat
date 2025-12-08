@echo off
echo 正在尝试构建RayTV项目...

echo.
echo 步骤1: 检查Node.js环境
node --version > nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到Node.js，请先安装Node.js
    pause
    exit /b 1
)
echo Node.js环境正常

echo.
echo 步骤2: 检查DevEco Studio hvigor工具
if exist "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" (
    echo DevEco Studio hvigor工具存在
) else (
    echo 错误: 未找到DevEco Studio hvigor工具
    echo 请确保已安装DevEco Studio
    pause
    exit /b 1
)

echo.
echo 步骤3: 尝试安装依赖项
echo 正在运行npm install...
call npm install
if %errorlevel% neq 0 (
    echo 警告: npm install失败，但将继续尝试构建
)

echo.
echo 步骤4: 尝试构建HAP
echo 正在运行hvigor assembleHap...
cd /d "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin"
call hvigorw.bat --mode module -p module=raytv@default assembleHap
if %errorlevel% neq 0 (
    echo 构建失败，尝试另一种方式...
    cd /d "%~dp0"
    call "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap
    if %errorlevel% neq 0 (
        echo 构建仍然失败，请检查错误信息
        pause
        exit /b 1
    )
)

echo.
echo 构建成功完成！
pause