# RayTV 项目构建指南

## 项目状态分析

在尝试构建RayTV项目时，我们发现了以下问题：

1. **缺少构建任务**：执行`hvigorw tasks`命令只显示了基本的帮助任务(tasks, taskTree)和prune清理任务，没有找到标准的构建任务如`clean`或`assembleHap`。
2. **clean任务缺失**：尝试执行`clean`任务时出现错误：`Task [ 'clean' ] was not found in the project RayTV`，说明项目中没有配置标准的clean任务。

2. **构建插件依赖问题**：无法从OHPM注册表安装`@ohos/hvigor-ohos-plugin`插件，但该插件在DevEco Studio工具链中是内置的。

3. **项目结构验证**：项目结构符合HarmonyOS应用的标准结构，`raytv`是一个entry类型的入口模块。

## 推荐的构建方法

### 方法1：使用DevEco Studio IDE（推荐）

最可靠的构建方法是使用DevEco Studio IDE：

1. 打开DevEco Studio
2. 导入RayTV项目（选择`d:\tv\RayTV`目录）
3. 等待项目同步完成
4. 点击工具栏上的运行/调试按钮构建并运行应用
5. 或使用构建菜单中的构建选项

### 方法2：命令行构建与清理

#### 清理构建产物

由于项目中缺少标准的`clean`任务，我们创建了一个清理脚本：

```bash
# 在项目根目录执行清理脚本
.\clean-build.ps1
```

该脚本会：
- 清理项目根目录和raytv子目录的build目录
- 清理.hvigor缓存目录
- 尝试执行prune任务清理hvigor缓存

### 方法2：命令行构建（尝试）

如果需要使用命令行，有以下几种可能的方式：

#### 选项A：使用项目自带的npm scripts

项目的`oh-package.json5`文件中定义了构建脚本：

```bash
# 在raytv目录下执行
hvigor assembleHap
```

#### 选项B：使用DevEco Studio的工具链

```bash
# 在项目根目录执行
"C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" build --mode debug
```

## 修复建议

要解决当前的构建问题，建议进行以下修改：

### 1. 修复hvigor配置

我们已经尝试修改了两个`hvigorfile.ts`文件，将导入方式改为动态require：

```javascript
// 修改导入方式为：
apply: require('@ohos/hvigor-ohos-plugin').hapTasks
```

### 2. 项目根目录添加oh-package.json5

在项目根目录创建或更新`oh-package.json5`文件，添加正确的构建配置：

```json5
{
  "name": "RayTV",
  "version": "1.0.0",
  "description": "RayTV主项目",
  "scripts": {
    "build": "hvigor build --mode debug"
  }
}
```

### 3. 确保hvigor构建配置正确

在项目根目录添加或更新`hvigorfile.ts`文件：

```javascript
const config = {
  system: [
    {
      name: 'project',
      apply: require('@ohos/hvigor').projectTasks
    }
  ],
  plugins: []
};

export default config;
```

## 重要注意事项

1. **HarmonyOS版本兼容性**：项目使用的是HarmonyOS 5.1.1 API版本。

2. **系统API依赖**：不要在`oh-package.json5`的`dependencies`中声明HarmonyOS系统API（以@kit和@ohos开头的包），这些会在编译时自动从SDK加载。

3. **清理任务**：当前项目没有`clean`任务，如果需要清理构建产物，可以手动删除`build`目录。

4. **OHPM依赖安装**：已成功执行`ohpm install --all`命令，依赖已安装在根目录的`oh_modules`文件夹中。
5. **清理构建产物**：使用提供的`clean-build.ps1`脚本替代标准的clean任务。

## 故障排除

如果构建仍然失败：

1. **使用清理脚本**：在重新构建前先运行`clean-build.ps1`脚本清理旧的构建产物


1. 确保DevEco Studio已正确安装并配置
2. 检查HarmonyOS SDK是否完整
3. 尝试删除`build`、`.hvigor`和`oh_modules`目录，然后重新构建
4. 在DevEco Studio中打开项目，使用IDE的构建功能

如果问题持续存在，建议查阅华为开发者文档或在HarmonyOS开发者社区寻求帮助。

## clean-build.ps1脚本使用说明

我们创建的`clean-build.ps1`脚本是一个PowerShell脚本，用于替代缺失的clean任务：

- **功能**：清理所有构建产物和缓存目录
- **使用方法**：
  - 在PowerShell中导航到项目根目录
  - 执行命令：`.\clean-build.ps1`
  - 或右键点击脚本文件，选择"使用PowerShell运行"
- **清理范围**：
  - `build`目录（根目录和raytv子目录）
  - `.hvigor`缓存目录
  - 尝试执行prune任务清理额外的hvigor缓存

此脚本提供了完整的构建清理功能，可以在构建前使用，确保使用最新的代码进行构建。