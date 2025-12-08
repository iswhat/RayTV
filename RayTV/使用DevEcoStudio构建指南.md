# 使用DevEco Studio构建RayTV项目的指南

## 问题概述

当前在命令行环境下无法构建RayTV项目，主要原因是：
1. 缺少必要的构建插件`@ohos/hvigor-ohos-plugin`
2. 网络限制导致无法从华为内部仓库安装该插件
3. 因此`assembleHap`构建任务不可用

## 推荐解决方案：使用DevEco Studio IDE构建

由于命令行构建遇到问题，推荐使用DevEco Studio IDE来构建项目，步骤如下：

### 步骤1：打开项目
1. 启动DevEco Studio
2. 选择"Open HarmonyOS Project"
3. 导航到`d:\tv\RayTV`目录并打开项目

### 步骤2：同步项目
1. 在菜单栏选择"File" -> "Sync Project"
2. 等待项目同步完成，DevEco Studio会自动处理依赖项

### 步骤3：构建项目
1. 在菜单栏选择"Build" -> "Build HAP(s)/APP(s)"
2. 或者使用快捷键Ctrl+F9
3. 选择要构建的模块（raytv）

### 步骤4：运行项目
1. 连接设备或启动模拟器
2. 在菜单栏选择"Run" -> "Run 'entry'"
3. 或者使用快捷键Shift+F10

## 备选方案：如果必须使用命令行

如果您必须使用命令行构建，可以尝试以下步骤：

### 方法1：检查DevEco Studio的环境变量
确保DevEco Studio的环境变量已正确设置，包括：
- HVIGOR_HOME
- DEV_ECO_HOME

### 方法2：使用DevEco Studio自带的Node.js环境
```
# 使用DevEco Studio的Node.js环境执行构建
"C:\Program Files\Huawei\DevEco Studio\tools\nodejs\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=raytv@default assembleHap
```

### 方法3：清理并重新构建
```
# 清理项目
"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" clean

# 重新构建
"C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" --mode module -p module=raytv@default build
```

## 注意事项

1. 请确保DevEco Studio已更新到最新版本
2. 确保已安装HarmonyOS SDK
3. 如果仍然遇到问题，请检查防火墙设置，确保DevEco Studio可以访问必要的网络资源

## 联系支持

如果以上方法都无法解决问题，请联系华为开发者支持团队获取进一步帮助。