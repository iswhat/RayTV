# RayTV HarmonyOS 项目开发指南

## 项目概述

RayTV是一个基于HarmonyOS平台开发的电视应用。本指南提供了项目的基本信息、开发环境配置、构建流程以及常见问题解决方案。

## 项目结构

```
RayTV/
├── .hvigor/          # Hvigor构建工具缓存目录
├── .idea/            # IDE配置目录
├── AppScope/         # 应用全局配置和资源
├── hvigor/           # Hvigor构建配置
├── raytv/            # 主应用模块
│   ├── .hvigor/      # 模块构建缓存
│   ├── .preview/     # 预览相关文件
│   ├── assets/       # 静态资源文件
│   ├── build/        # 构建输出目录
│   ├── docs/         # 模块文档
│   ├── hvigor/       # 模块构建配置
│   ├── scripts/      # 辅助脚本
│   ├── src/          # 源代码目录
│   ├── app.json5     # 应用配置
│   ├── build-profile.json5 # 构建配置
│   ├── code-linter.json5   # 代码检查配置
│   ├── hvigorfile.ts # 构建脚本
│   ├── oh-package.json5    # HarmonyOS依赖配置
│   └── package.json  # 标准npm依赖配置
├── build-no-hotreload.ps1  # 非热重载构建脚本
├── build-profile.json5     # 项目构建配置
├── check-build-env.ps1     # 构建环境检查脚本
├── code-linter.json5       # 项目代码检查配置
├── hvigorfile.ts           # 项目构建脚本
├── oh-package.json5        # 项目级HarmonyOS依赖配置
└── package.json            # 项目级npm依赖配置
```

## 开发环境配置

### 系统要求
- Windows 10/11 64位操作系统
- DevEco Studio 4.0及以上版本
- Node.js 16.x或更高版本
- JDK 11（DevEco Studio内置）

### 环境检查

执行以下命令检查构建环境：

```powershell
.\check-build-env.ps1
```

该脚本将检查：
- DevEco Studio SDK路径
- Hvigor构建工具
- Node.js环境
- 项目配置文件
- 依赖配置

## 构建流程

### 注意事项

由于网络限制，项目依赖的华为内部npm仓库（如`@ohos/hvigor-ohos-plugin`）可能无法自动下载，导致构建任务（如`assembleHap`）无法正常识别。

### 构建方法

#### 方法1：使用构建脚本（推荐）

```powershell
.uild-no-hotreload.ps1
```

该脚本使用DevEco Studio内置的Hvigor工具进行构建，避免了一些常见的编译错误。

#### 方法2：使用DevEco Studio IDE

打开DevEco Studio，导入项目后使用IDE的构建功能。IDE通常能够正确处理依赖关系。

#### 方法3：手动执行Hvigor命令

```powershell
node "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=raytv@default -p product=default assembleHap
```

## 常见问题解决方案

### 问题1：无法找到构建任务（如assembleHap）

**原因**：缺少必要的依赖包`@ohos/hvigor-ohos-plugin`。

**解决方案**：
1. 使用VPN/代理访问华为内部npm仓库
2. 在可访问内部仓库的环境中执行：`npm install`
3. 或通过DevEco Studio IDE进行构建
4. 或手动获取依赖包并安装到node_modules目录

### 问题2：构建失败，提示缺少某个包

**解决方案**：
- 检查oh-package.json5文件中的依赖配置
- 确保网络可以访问相应的npm仓库
- 或手动安装缺失的依赖

### 问题3：运行时崩溃或功能异常

**解决方案**：
- 检查应用配置文件（app.json5）中的权限和能力声明
- 查看日志中的具体错误信息
- 确保使用的API与目标HarmonyOS版本兼容

## 代码规范

项目遵循华为官方ArkTS开发规范，主要包括：

- 类型系统规范
- 命名规范
- 代码风格指南
- 组件开发最佳实践

详细规范请参考项目文档目录下的相关文档。

## 版本控制

- 使用Git进行版本控制
- 遵循标准的分支管理策略
- 代码提交前请执行lint检查

## 维护与更新

- 定期检查DevEco Studio和SDK更新
- 关注HarmonyOS官方API变化
- 保持依赖包版本更新

## 联系与支持

如有任何问题，请联系项目维护者或参考华为开发者论坛获取帮助。

---

*最后更新时间：$(Get-Date -Format 'yyyy-MM-dd')*
