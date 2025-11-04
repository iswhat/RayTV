# 模块导入导出规范指南

## 概述

本文档定义了RayTV项目中模块导入导出的最佳实践和规范，确保代码的一致性和可维护性。

## 导入规范

### 1. 文件扩展名
- **禁止**在导入语句中包含文件扩展名（`.ets`、`.ts`）
- **正确示例**: `import Logger from '../../common/util/Logger'`
- **错误示例**: `import Logger from '../../common/util/Logger.ets'`

### 2. 相对路径导入
- 使用相对路径导入时，确保路径正确且一致
- 避免使用过多的`../`层级，保持路径简洁
- 对于跨目录导入，建议使用别名或绝对路径配置

### 3. 默认导入 vs 命名导入

#### 默认导入（Default Import）
- 适用于默认导出的模块（使用`export default`）
- **语法**: `import ModuleName from './path/to/module'`
- **适用场景**:
  - 单例类
  - 主要功能模块
  - 工厂类
  - 服务类

#### 命名导入（Named Import）
- 适用于命名导出的模块（使用`export`）
- **语法**: `import { ModuleName1, ModuleName2 } from './path/to/module'`
- **适用场景**:
  - 接口定义
  - 枚举类型
  - 工具函数
  - 常量定义

## 导出规范

### 1. 默认导出（Default Export）
- 每个文件应该只有一个默认导出
- 适用于主要的类、函数或对象
- **示例**:
```typescript
// NetworkRepository.ets
export default interface NetworkRepository {
  // 接口定义
}
```

### 2. 命名导出（Named Export）
- 适用于导出多个相关的接口、类型或常量
- 保持导出的命名清晰且具有描述性
- **示例**:
```typescript
// Vod.ets
export interface Vod {
  // 接口定义
}

export interface VodSearchResult {
  // 接口定义
}
```

### 3. 混合导出
- 允许同时使用默认导出和命名导出
- 确保导出的结构清晰，避免混乱
- **示例**:
```typescript
// Logger.ets
export enum LogLevel {
  DEBUG,
  INFO,
  WARN,
  ERROR
}

export default class Logger {
  // 类实现
}
```

## 常见问题与解决方案

### 问题1：导入导出不匹配
**症状**: 默认导出的模块被命名导入，或反之
**解决方案**: 确保导入方式与导出方式一致

### 问题2：循环依赖
**症状**: 模块A导入模块B，模块B又导入模块A
**解决方案**: 
- 重构代码结构，提取公共依赖
- 使用依赖注入模式
- 将共享逻辑提取到第三方模块

### 问题3：路径错误
**症状**: 导入路径不存在或指向错误文件
**解决方案**: 
- 使用IDE的路径自动补全功能
- 检查文件路径大小写
- 验证相对路径的正确性

## 最佳实践

### 1. 导入顺序
建议按照以下顺序组织导入语句：
1. 第三方库导入
2. 项目内部模块导入
3. 相对路径导入
4. 样式文件导入

### 2. 导入分组
使用空行将不同类型的导入分组：
```typescript
// 第三方库
import { Component } from '@ohos/arkui';

// 项目内部模块
import Logger from '../../common/util/Logger';

// 相对路径导入
import { Vod } from '../bean/Vod';
```

### 3. 避免通配符导入
**不推荐**: `import * as Utils from './utils'`
**推荐**: 明确导入需要的模块

### 4. 使用类型导入
对于TypeScript类型，使用类型导入：
```typescript
import type { Vod } from '../bean/Vod';
```

## 代码示例

### 正确的导入示例
```typescript
// 默认导入（适用于默认导出的类）
import Logger from '../../common/util/Logger';
import ConfigService from '../config/ConfigService';

// 命名导入（适用于接口、枚举等）
import { Vod, Episode } from '../../data/bean/Vod';
import { MediaType, PlayOptions } from '../media/MediaService';

// 混合导入
import DatabaseRepository, { RepositoryType } from '../repository/DatabaseRepository';
```

### 正确的导出示例
```typescript
// 默认导出（主要类）
export default class MediaService {
  // 类实现
}

// 命名导出（接口和类型）
export interface MediaMetadata {
  // 接口定义
}

export enum MediaType {
  // 枚举定义
}

// 工具函数导出
export function formatDuration(seconds: number): string {
  // 函数实现
}
```

## 工具支持

### 1. ESLint规则
配置以下ESLint规则确保导入导出规范：
- `import/no-default-export`: 控制默认导出的使用
- `import/order`: 控制导入顺序
- `import/no-cycle`: 检测循环依赖

### 2. TypeScript配置
在`tsconfig.json`中配置路径映射：
```json
{
  "compilerOptions": {
    "baseUrl": "./src",
    "paths": {
      "@common/*": ["common/*"],
      "@data/*": ["data/*"],
      "@service/*": ["service/*"]
    }
  }
}
```

## 总结

遵循这些导入导出规范可以：
- 提高代码的可读性和可维护性
- 减少导入导出相关的错误
- 确保团队协作的一致性
- 便于代码重构和模块化开发

定期检查项目中的导入导出模式，确保符合规范要求。