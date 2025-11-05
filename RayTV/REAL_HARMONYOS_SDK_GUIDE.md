# 真实HarmonyOS SDK环境使用指南

## 概述

本指南将帮助您在DevEco Studio中使用真实的HarmonyOS SDK环境进行RayTV项目的调试和构建。项目已完全从模拟环境转换为真实SDK环境，移除了所有模拟构建脚本。

## 环境要求

1. **DevEco Studio 4.0或更高版本**
   - 确保已安装完整的HarmonyOS SDK
   - 推荐使用最新稳定版本

2. **HarmonyOS SDK**
   - API版本：5.1.1(19)或更高
   - 包含完整的工具链，包括es2abc编译器

3. **Node.js**
   - 版本：16.x或更高
   - 用于支持hvigor构建工具

## 项目配置变更

### 1. 移除的文件
以下模拟构建脚本已被移除：
- `ohos.cmd`
- `ohos.ps1`
- `ohos-no-hotreload.cmd`
- `ohos-no-hotreload.ps1`

### 2. 更新的配置文件

#### package.json
- 移除了模拟构建命令
- 添加了真实的hvigor构建命令：
  ```json
  "scripts": {
    "build": "hvigorw assembleHap --mode module -p module=raytv@default",
    "build-debug": "hvigorw assembleHap --mode module -p module=raytv@default -p debug=true",
    "build-release": "hvigorw assembleHap --mode module -p module=raytv@default -p release=true",
    "clean": "hvigorw clean",
    "install": "hvigorw installHsp",
    "version": "hvigorw --version"
  }
  ```

#### hvigor-config.json5
- 启用了并行编译和类型检查
- 优化了构建性能
- 添加了真实SDK配置：
  ```json5
  "sdk": {
    "useRealSdk": true,
    "hotReload": true
  }
  ```

#### build-profile.json5
- 项目级和模块级配置都已更新
- 添加了AOT编译支持
- 配置了调试和发布模式的不同选项

## 在DevEco Studio中使用项目

### 1. 打开项目
1. 启动DevEco Studio
2. 选择"Open"或"Import Project"
3. 导航到`d:\tv\RayTV`目录并打开

### 2. 配置SDK
1. 打开File > Settings > HarmonyOS SDK
2. 确保SDK路径正确指向您的HarmonyOS SDK安装目录
3. 验证API版本兼容性（需要5.1.1(19)或更高）

### 3. 同步项目
1. 点击工具栏中的"Sync Project"按钮
2. 等待Gradle同步完成
3. 如果提示安装依赖，请确认安装

### 4. 构建项目
#### 使用DevEco Studio界面
1. 选择Build > Build Hap(s) / APP(s) > Build Debug Hap(s)
2. 或使用快捷键Ctrl+F9

#### 使用命令行
在项目根目录下执行：
```bash
# 构建调试版本
npm run build-debug

# 构建发布版本
npm run build-release

# 清理构建
npm run clean
```

### 5. 运行和调试
1. 连接HarmonyOS设备或启动模拟器
2. 点击运行按钮（绿色三角形）
3. 选择目标设备
4. 等待应用安装和启动

## 热重载功能

项目已配置支持热重载功能，在DevEco Studio中：

1. 确保使用调试模式构建
2. 在代码编辑器中修改代码
3. 保存文件后，热重载将自动应用更改
4. 无需重新安装应用

## 常见问题解决

### 1. es2abc编译错误
如果仍然遇到es2abc错误：
1. 检查SDK安装完整性
2. 在DevEco Studio中：File > Settings > HarmonyOS SDK > SDK Tools
3. 确保所有必需工具已安装，特别是编译器工具链

### 2. 构建失败
1. 清理项目：Build > Clean Project
2. 重新同步：File > Sync Project with Gradle Files
3. 检查依赖项是否正确安装

### 3. 热重载不工作
1. 确保使用调试模式
2. 检查hvigor-config.json5中的hotReload设置
3. 重启DevEco Studio

## 最佳实践

1. **定期更新SDK**：保持HarmonyOS SDK为最新版本
2. **使用版本控制**：定期提交代码变更
3. **定期清理**：使用`npm run clean`清理构建缓存
4. **监控日志**：使用DevEco Studio的Logcat查看应用日志
5. **性能分析**：使用DevEco Studio的性能分析工具优化应用

## 联系支持

如果遇到无法解决的问题：
1. 查看DevEco Studio的官方文档
2. 访问HarmonyOS开发者社区
3. 提交问题到项目仓库

---

**注意**：本指南基于HarmonyOS 5.1.1(19)和DevEco Studio 4.0编写。不同版本可能存在差异。