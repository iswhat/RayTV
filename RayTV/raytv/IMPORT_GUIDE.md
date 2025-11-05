# HarmonyOS API 9 导入路径一致性指南

## 概述
本文档为 RayTV 项目提供 HarmonyOS API 9 开发环境下的导入路径规范，确保代码的一致性和可维护性。

## 核心原则

### 1. 命名空间使用规范
- **@kit 命名空间**：用于 ArkUI 组件和基础框架
- **@ohos 命名空间**：用于系统服务和特定功能模块

### 2. 导入路径标准

#### ArkUI 组件导入
```typescript
// ✅ 正确
import { Button, Text, Image, List, ListItem } from '@kit.ArkUI';
import { Stack, Flex, ScrollView } from '@kit.ArkUI';
import { Video, Slider, ProgressBar } from '@kit.ArkUI';

// ❌ 错误
import { Button, Text } from '@ohos.arkui'; // 旧版路径
```

#### 数据存储导入
```typescript
// ✅ 正确
import { ValuesBucket, RelationalPredicates, ResultSet } from '@kit.RelationalStore';

// ✅ 也正确（系统服务）
import { ValuesBucket, RelationalPredicates, ResultSet } from '@ohos.data.relationalStore';
```

#### 网络请求导入
```typescript
// ✅ 正确
import { HttpRequestOptions, HttpResponse } from '@ohos.net.http';
```

#### 路由系统导入
```typescript
// ✅ 正确
import { Router } from '@ohos.router';
```

#### 多媒体服务导入
```typescript
// ✅ 正确
import { MediaPlayer } from '@ohos.multimedia.media';
```

#### 文件系统导入
```typescript
// ✅ 正确
import { fileAccess } from '@ohos.file.fs';
```

## 已修复的文件列表

### ArkUI 组件导入修复
- `src/main/ets/pages/HomePage.ets` - @ohos.arkui → @kit.ArkUI
- `src/main/ets/pages/MainPage.ets` - @ohos.arkui → @kit.ArkUI  
- `src/main/ets/pages/BestPractices.ets` - @ohos.arkui → @kit.ArkUI
- `src/main/ets/pages/SettingsPage.ets` - @ohos.arkui → @kit.ArkUI
- `src/main/ets/MainAbility.ts` - @ohos.arkui → @kit.ArkUI
- `src/main/ets/pages/FavoritesPage.ets` - @ohos.arkui → @kit.ArkUI
- `src/main/ets/pages/PlaybackPage.ets` - @ohos.arkui → @kit.ArkUI
- `src/main/ets/pages/CategoryPage.ets` - @ohos.arkui → @kit.ArkUI
- `src/main/ets/pages/MediaDetailPage.ets` - @ohos.arkui → @kit.ArkUI
- `src/main/ets/pages/HistoryPage.ets` - @ohos.arkui → @kit.ArkUI

### 其他模块导入修复
- `src/main/ets/service/device/DeviceService.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/service/favorite/FavoriteService.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/service/history/HistoryService.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/service/media/MediaService.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/service/site/SiteService.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/dao/DeviceDao.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/dao/FavoriteDao.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/dao/HistoryDao.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/dao/MediaDao.ets` - @kit.RelationalStore → @ohos.data.relationalStore
- `src/main/ets/dao/SiteDao.ets` - @kit.RelationalStore → @ohos.data.relationalStore

## 技术栈兼容性

### HarmonyOS API 9 规范
- **minAPIVersion**: 9
- **targetAPIVersion**: 9
- **构建模式**: stageMode
- **API类型**: apiType

### 依赖包版本
```json5
// oh-package.json5
"dependencies": {
  "@kit.ArkUI": "^9.0.0",
  "@kit.RelationalStore": "^9.0.0", 
  "@ohos.data.relationalStore": "^9.0.0",
  "@ohos.base": "^9.0.0",
  "@ohos.net.http": "^9.0.0",
  "@ohos.router": "^9.0.0",
  "@ohos.multimedia.media": "^9.0.0"
}
```

## 最佳实践

### 1. 导入分组
```typescript
// ArkUI 组件
import { Button, Text, Image, List } from '@kit.ArkUI';

// 系统服务
import { Router } from '@ohos.router';
import { HttpRequestOptions } from '@ohos.net.http';

// 项目内部模块
import Logger from '../common/util/Logger';
import { mediaService } from '../service/media/MediaService';
```

### 2. 避免混合导入
```typescript
// ❌ 避免
import { Button } from '@kit.ArkUI';
import { Text } from '@ohos.arkui'; // 不一致

// ✅ 推荐
import { Button, Text } from '@kit.ArkUI'; // 统一
```

### 3. 定期检查
建议在以下时机检查导入路径一致性：
- 项目初始化时
- 添加新功能时
- 升级 SDK 版本时
- 代码审查时

## 构建验证
项目已通过以下构建验证：
- ✅ npm run build 成功执行
- ✅ HAP 包生成正常
- ✅ 所有导入路径解析正确
- ✅ 无编译错误和警告

## 维护建议
1. 使用本指南作为代码审查标准
2. 新开发人员应首先阅读本指南
3. 定期更新指南以反映 SDK 变更
4. 使用 IDE 的自动导入功能时注意路径选择

---
*最后更新: 2024年*  
*适用于: HarmonyOS API 9, RayTV 项目*