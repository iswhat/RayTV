# HarmonyOS 配置文件验证和修复指南

## 概述

本文档总结了RayTV项目在从模拟环境迁移到真实HarmonyOS SDK环境过程中遇到的配置文件schema验证错误及其系统性解决方案。

## 主要问题分析

### 1. build-profile.json5 schema验证错误

**错误类型**: 非法字段配置

**具体问题**:
- 项目级build-profile.json5中使用了非法字段：`aot`、`debuggable`、`compileMode`、`runtimeOS`
- 模块级build-profile.json5中使用了非法字段：`strictMode`、`buildProfile`、`runtimeOS`

**修复方案**:
- 移除所有非法字段，仅保留schema允许的合法字段
- 项目级build-profile.json5合法字段：`packOptions`、`debuggable`、`resOptions`、`externalNativeOptions`、`sourceOption`、`napiLibFilterOption`、`arkOptions`、`nativeLib`、`strictMode`、`nativeCompiler`、`removePermissions`、`generateSharedTgz`、`preloadSystemSo`

### 2. hvigor-config.json5 schema验证错误

**错误类型**: 非法字段配置

**具体问题**:
- 使用了自定义的`sdk`字段，包含`useRealSdk`和`hotReload`配置

**修复方案**:
- 移除`sdk`字段，仅使用hvigor标准配置字段
- 保留合法的配置项：`execution`、`logging`、`debugging`、`nodeOptions`

### 3. oh-package.json5 依赖项配置问题

**错误类型**: 非法依赖项和脚本配置

**具体问题**:
- 使用了不存在的依赖项：`@kit.PerformanceAnalysisKit`、`@kit.CoreServicesKit`、`@kit.DistributedDataKit`、`@kit.Constants`
- 使用了模拟环境的构建脚本：`ohos build --product-type phone`、`ohos-dev-server`

**修复方案**:
- 移除不存在的依赖项，仅保留HarmonyOS官方支持的依赖项
- 将构建脚本更新为hvigor命令：`hvigor assembleHap`、`hvigor assembleHap --hot-reload-build`

## 配置文件修复总结

### 项目级build-profile.json5

**修复前**:
```json5
{
  "app": {
    "products": [
      {
        "buildOption": {
          "strictMode": { /* 合法 */ },
          "aot": { "enable": true } /* 非法 */
        }
      }
    ],
    "buildModeSet": [
      {
        "name": "debug",
        "debuggable": true, /* 非法 */
        "compileMode": "debug" /* 非法 */
      }
    ]
  },
  "modules": [
    {
      "targets": [
        {
          "runtimeOS": "HarmonyOS" /* 非法 */
        }
      ]
    }
  ]
}
```

**修复后**:
```json5
{
  "app": {
    "products": [
      {
        "buildOption": {
          "strictMode": { /* 仅保留合法字段 */ }
        }
      }
    ],
    "buildModeSet": [
      {
        "name": "debug" /* 仅保留name字段 */
      }
    ]
  },
  "modules": [
    {
      "targets": [
        {
          "name": "default",
          "applyToProducts": ["default"]
        }
      ]
    }
  ]
}
```

### 模块级build-profile.json5

**修复前**:
```json5
{
  "buildOption": {
    "strictMode": { /* 非法 */ }
  },
  "buildOptionSet": [
    {
      "buildProfile": { /* 非法 */ }
    }
  ],
  "targets": [
    {
      "runtimeOS": "HarmonyOS" /* 非法 */
    }
  ]
}
```

**修复后**:
```json5
{
  "buildOption": {
    "resOptions": { /* 仅保留合法字段 */ }
  },
  "buildOptionSet": [
    {
      "arkOptions": { /* 仅保留合法字段 */ }
    }
  ],
  "targets": [
    {
      "name": "default"
    }
  ]
}
```

### hvigor-config.json5

**修复前**:
```json5
{
  "sdk": { /* 非法字段 */
    "useRealSdk": true,
    "hotReload": true
  }
}
```

**修复后**:
```json5
{
  /* 移除非法sdk字段 */
}
```

## 验证方法

### 1. 使用hvigor验证
```bash
# 在项目根目录执行
hvigor assembleHap --dry-run
```

### 2. 使用DevEco Studio验证
- 在DevEco Studio中打开项目
- 检查"Build"面板是否有错误提示
- 使用"Sync Project"功能验证配置

### 3. 手动检查schema
- 参考HarmonyOS官方文档验证字段合法性
- 使用JSON schema验证工具检查配置文件

## 最佳实践

### 1. 配置文件管理
- 定期检查配置文件是否符合最新HarmonyOS规范
- 使用版本控制跟踪配置变更
- 创建配置模板供新项目使用

### 2. 依赖项管理
- 仅使用HarmonyOS官方支持的依赖项
- 定期检查依赖项版本兼容性
- 避免使用第三方未经验证的依赖项

### 3. 构建配置
- 使用hvigor作为标准构建工具
- 避免使用模拟环境的构建脚本
- 配置合理的构建优化选项

## 常见问题解决

### Q1: 如何确定字段是否合法？
A: 参考HarmonyOS官方文档，或使用DevEco Studio的配置验证功能。

### Q2: 配置修改后构建仍然失败？
A: 清除构建缓存：`hvigor clean`，然后重新构建。

### Q3: 如何避免类似问题？
A: 使用标准的HarmonyOS项目模板，避免自定义非法配置字段。

## 总结

通过系统性修复配置文件schema验证错误，RayTV项目已完全符合HarmonyOS开发规范。主要经验包括：

1. **严格遵守schema规范**：仅使用官方文档中定义的合法字段
2. **移除模拟环境残留**：彻底清理模拟环境特有的配置和脚本
3. **依赖项标准化**：仅使用HarmonyOS官方支持的依赖项
4. **构建工具统一**：使用hvigor作为标准构建工具

这些修复确保了项目在真实HarmonyOS SDK环境中的稳定运行和持续发展。