# RayTV 项目构建指南

## 项目状态分析

在尝试构建RayTV项目时，我们发现了以下问题：

1. **缺少构建任务**：执行`hvigorw tasks`命令只显示了基本的帮助任务(tasks, taskTree)和prune清理任务，没有找到标准的构建任务如`clean`或`assembleHap`。
2. **clean任务缺失**：尝试执行`clean`任务时出现错误：`Task [ 'clean' ] was not found in the project RayTV`，说明项目中没有配置标准的clean任务。
3. **构建插件依赖问题**：无法从OHPM注册表安装`@ohos/hvigor-ohos-plugin`插件，但该插件在DevEco Studio工具链中是内置的。
4. **网络访问限制**：`@ohos/hvigor-ohos-plugin`插件托管在华为内部仓库(cmc.centralrepo.rnd.huawei.com)，当前环境无法访问。
5. **项目结构验证**：项目结构符合HarmonyOS应用的标准结构，`raytv`是一个entry类型的入口模块。

## 自动修复措施

我们已经自动修复了以下配置文件以解决构建问题：

1. 修改了`raytv/oh-package.json5`文件，恢复了`@ohos/hvigor-ohos-plugin`依赖项声明
2. 更新了`raytv/hvigorfile.ts`文件，正确导入并使用了hvigor任务系统
3. 创建了`auto-build-fix.bat`脚本，可以自动执行构建过程

## 推荐的构建方法

### 方法1：使用DevEco Studio IDE（推荐）

最可靠的构建方法是使用DevEco Studio IDE：

1. 打开DevEco Studio
2. 导入RayTV项目（选择`d:\tv\RayTV`目录）
3. 等待项目同步完成
4. 点击工具栏上的运行/调试按钮构建并运行应用
5. 或使用构建菜单中的构建选项

### 方法2：使用自动修复脚本构建

双击运行`auto-build-fix.bat`脚本，它将自动执行以下步骤：
1. 检查环境配置
2. 尝试安装依赖项
3. 执行构建命令

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

## 最新修复方案

根据最新的分析，我们制定了以下修复方案来解决构建问题：

### 方案1：使用DevEco Studio IDE构建（推荐）

这是最简单且最可能成功的解决方案：

1. 打开DevEco Studio
2. 选择"Open HarmonyOS Project"
3. 导航到`d:\tv\RayTV`目录并打开项目
4. 等待项目同步完成
5. 点击菜单栏的"Build" -> "Build HAP(s)/App(s)"

DevEco Studio通常已预装必要的依赖项，可以绕过网络访问问题。

### 方案2：手动安装缺失的依赖项

如果可以配置网络访问华为内部仓库：

1. 配置VPN或代理以访问华为内部仓库
2. 执行以下命令安装依赖项：
   ```bash
   npm install @ohos/hvigor-ohos-plugin --save-dev
   ```
3. 恢复`raytv/oh-package.json5`中被注释掉的依赖项：
   ```json
   "devDependencies": {
     "@ohos/hvigor-ohos-plugin": "6.0.6"
   }
   ```
4. 重新尝试构建项目

### 方案3：修复hvigor配置文件

根据hvigor的帮助信息，我们需要正确配置hvigorfile.ts文件：

1. 修改`raytv/hvigorfile.ts`文件内容为：
   ```typescript
   // Script for compiling and building Hvigor.
   import { hapTasks } from '@ohos/hvigor-ohos-plugin';
   
   export default {
     system: hapTasks,  /* Defines the task script of the module. */
     plugins: []        /* Custom plugin list. */
   }
   ```

2. 确保`raytv/oh-package.json5`中包含正确的依赖项：
   ```json
   {
     "devDependencies": {
       "@ohos/hvigor-ohos-plugin": "6.0.6"
     }
   }
   ```

## 故障排除

如果构建仍然失败：

1. **使用清理脚本**：在重新构建前先运行`clean-build.ps1`脚本清理旧的构建产物

2. 确保DevEco Studio已正确安装并配置
3. 检查HarmonyOS SDK是否完整
4. 尝试删除`build`、`.hvigor`和`oh_modules`目录，然后重新构建
5. 在DevEco Studio中打开项目，使用IDE的构建功能

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