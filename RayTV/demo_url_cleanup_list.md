# RayTV项目中Demo和测试URL清理清单

## 发现的问题

项目中存在大量demo、simple、test、example性质的URL,这些不应该出现在正式项目中。

## 需要清理的URL分类

### 1. 示例API端点 (example.com / test.example.com)

#### 真实代码中的配置URL
- `SearchRepository.ets` - `https://api.raytv.example.com`
- `RecommendationRepository.ets` - `https://api.raytv.example.com`
- `LiveStreamRepository.ets` - `https://api.raytv.example.com`

#### 测试代码 (可以保留,因为是测试文件)
- `InfrastructureIntegrationTest.ts` - `https://test.example.com/config.json`
- `InfrastructureIntegrationTest.ts` - `https://integration-test.example.com/config.json`

### 2. 占位符图片 (via.placeholder.com)

这些应该替换为:
1. 使用本地的默认图片资源
2. 或者使用正式的CDN图片服务
3. 或者使用Base64编码的默认图片

#### 受影响的文件:
- `MediaDetailPage.ets` - 12处
- `SettingsPage.ets` - 3处
- `SearchResultPage.ets` - 1处
- `SearchPage.ets` - 1处
- `MediaInfoComponent.ets` - 1处
- `MainPage.ets` - 3处
- `HomePage.ets` - 1处
- `HistoryPage.ets` - 1处
- `CategoryPage.ets` - 1处

**总计: 24处占位符图片URL**

### 3. 示例视频URL (example.com)

#### 测试数据代码:
- `MediaDetailPage.ets` - 测试电影和剧集数据 (7处)
- `LivePage.ets` - 测试频道数据 (8处)

### 4. 文档注释中的示例URL (example.com)

这些应该保留,因为是文档注释:
- `HttpService.ets` - 文档注释中的示例URL (10+处)
- `ParserManager.ts` - 文档注释中的示例URL (5处)
- `ConfigSourceService.ts` - 文档注释中的示例URL (3处)
- `ContentAggregator.ts` - 文档注释中的示例URL (1处)
- `PlaybackService.ets` - 文档注释中的示例URL (1处)
- `StorageUtil.ets` - 文档注释中的示例URL (2处)

## 清理建议

### 高优先级 (必须清理)

1. **占位符图片URL** (24处)
   - 替换为本地资源或正式CDN
   - 创建默认图片资源文件

2. **测试数据中的URL** (15处)
   - `MediaDetailPage.ets` - 移除或改为空数据
   - `LivePage.ets` - 移除或改为空数据

3. **API配置URL** (3处)
   - `SearchRepository.ets` - 改为真实API
   - `RecommendationRepository.ets` - 改为真实API
   - `LiveStreamRepository.ets` - 改为真实API

### 中优先级 (建议清理)

1. **注释中的测试代码** - 移除或使用 `@ts-ignore`
2. **未使用的示例代码** - 移除

### 低优先级 (可选)

1. **文档注释中的示例URL** - 可以保留,这些是正常的文档

## 清理步骤

1. 创建默认图片资源
2. 批量替换占位符URL
3. 移除测试数据
4. 更新API配置为真实URL

## 注意事项

- 文档注释中的示例URL可以保留
- 测试文件中的URL可以保留
- 只清理运行时代码中的URL
