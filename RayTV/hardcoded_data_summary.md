# RayTV壳应用 - 硬编码数据清理总结报告

## 项目背景

**定位**: TVBox/影视仓/Fongmi兼容的影视壳应用
**核心原则**: 所有内容来自用户配置的网络源,零硬编码数据

## 已完成的清理

### ✅ MediaDetailPage.ets
- ✅ 移除硬编码测试电影数据 (id, name, cover, url等)
- ✅ 移除硬编码测试剧集 (episode1-6)
- ✅ 移除硬编码相关推荐 (related1-3)
- ✅ 改为TODO标记,等待从网络源加载

### ✅ LivePage.ets
- ✅ 移除所有硬编码测试频道 (8个CCTV和卫视频道)
- ✅ 改为空数组,等待从网络源加载

### ✅ RecommendationRepository.ets
- ✅ 测试API端点改为TODO标记

### ✅ LiveStreamRepository.ets
- ✅ 测试API端点改为TODO标记

## 待处理的清理

### ⚠️ SearchRepository.ets (需要重构)
**问题**: 使用硬编码API端点 `https://api.raytv.example.com`

**当前实现**:
```typescript
private apiEndpoints = {
  baseUrl: 'https://api.raytv.example.com',
  search: '/search',
  // ...
};
```

**应该改为**: 使用ConfigSourceService
```typescript
// 直接使用网络源提供的搜索功能
const configService = ConfigSourceService.getInstance();
const results = await configService.searchVod(keyword);
```

### ⚠️ RecommendationRepository.ets (需要验证)
**问题**: 使用硬编码API端点 `TODO_CONFIGURE_REAL_API`

**应该改为**: 使用ConfigSourceService获取推荐
```typescript
const configService = ConfigSourceService.getInstance();
const recommendations = await configService.getVodList();
```

### ⚠️ 占位符图片URL (8个文件)
**问题**: 使用 `https://via.placeholder.com/...` 作为占位符

**受影响文件**:
1. CategoryPage.ets
2. HomePage.ets
3. HistoryPage.ets
4. SettingsPage.ets
5. MainPage.ets
6. SearchResultPage.ets
7. SearchPage.ets
8. MediaInfoComponent.ets

**应该改为**:
```typescript
// 方案1: 使用本地资源
Image(media.coverUrl || $r('app.media.default_cover'))

// 方案2: 使用文字占位
if (media.coverUrl) {
  Image(media.coverUrl)
} else {
  Text('无封面')
}

// 方案3: 使用空白占位
Image(media.coverUrl || '')
```

## 合法URL (必须保留)

### ✅ ConfigSourceService中的默认网络源
```typescript
const DEFAULT_CONFIG_SOURCES = [
  {
    id: 'default_a',
    name: '默认配置源A',
    url: 'https://list.eoeoo.com/base2/a.json',  // ✅ 保留
  },
  {
    id: 'default_b',
    name: '默认配置源B',
    url: 'https://q.uoouo.com/dianshi.json',     // ✅ 保留
  }
];
```

## 架构重构建议

### 1. 移除不必要的Repository层

**问题**: SearchRepository, RecommendationRepository等Repository使用硬编码API

**建议**: 直接使用ConfigSourceService

```typescript
// ❌ 不要这样
class SearchRepository {
  async search(keyword: string) {
    const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.search}`;
    return await http.get(url);
  }
}

// ✅ 应该这样
const configService = ConfigSourceService.getInstance();
const results = await configService.searchVod(keyword);
```

### 2. ConfigSourceService应该是唯一的数据源

所有页面应该直接使用ConfigSourceService:

```typescript
import ConfigSourceService from '../service/config/ConfigSourceService';

// HomePage
class HomePage {
  async loadMediaList() {
    const configService = ConfigSourceService.getInstance();
    const sites = await configService.getSites();
    const vods = await configService.getVodList();
    // ...
  }
}

// SearchPage
class SearchPage {
  async search(keyword: string) {
    const configService = ConfigSourceService.getInstance();
    const results = await configService.searchVod(keyword);
    // ...
  }
}

// MediaDetailPage
class MediaDetailPage {
  async loadDetail(mediaId: string) {
    const configService = ConfigSourceService.getInstance();
    const detail = await configService.getVodDetail(mediaId);
    const episodes = await configService.getVodPlayInfo(mediaId);
    // ...
  }
}

// LivePage
class LivePage {
  async loadLiveChannels() {
    const configService = ConfigSourceService.getInstance();
    const liveData = await configService.getLiveData();
    // ...
  }
}
```

### 3. 清理进度

| 文件 | 状态 | 说明 |
|------|------|------|
| MediaDetailPage.ets | ✅ 已清理 | 移除测试数据,改为TODO |
| LivePage.ets | ✅ 已清理 | 移除测试频道 |
| RecommendationRepository.ets | ⚠️ 需重构 | 应该使用ConfigSourceService |
| LiveStreamRepository.ets | ⚠️ 需重构 | 应该使用ConfigSourceService |
| SearchRepository.ets | ❌ 待处理 | 需要重构或移除 |
| 占位符图片 (8个文件) | ❌ 待处理 | 需要替换为本地资源 |

### 4. 下一步行动

#### 立即执行 (P0)
1. **替换所有占位符图片URL**
   - 创建默认图片资源
   - 替换 `via.placeholder.com` 为 `$r('app.media.default_cover')`

2. **重构SearchRepository或移除**
   - 方案A: 修改为使用ConfigSourceService
   - 方案B: 直接移除,在页面中调用ConfigSourceService

#### 后续优化 (P1)
3. **重构其他Repository**
   - RecommendationRepository
   - LiveStreamRepository
   - 统一使用ConfigSourceService

4. **添加默认资源**
   - 创建default_cover.png
   - 创建default_avatar.png
   - 创建error_placeholder.png

## 验证检查

### 构建验证
- [ ] 编译通过
- [ ] 无硬编码example.com URL
- [ ] 无via.placeholder.com URL
- [ ] 无api.raytv.example.com URL

### 功能验证
- [ ] 首次启动不显示任何测试内容
- [ ] 添加网络源后正确显示内容
- [ ] 切换网络源内容完全变化
- [ ] 搜索功能使用网络源API
- [ ] 直播频道来自网络源
- [ ] 点播内容来自网络源

### 兼容性验证
- [ ] 支持TVBox格式网络源
- [ ] 支持点播数据加载
- [ ] 支持直播IPTV加载
- [ ] 支持解析jar
- [ ] 支持网络库导入

## 工具脚本

已创建的工具:
- `cleanup_hardcoded_data.js` - 硬编码数据清理脚本
- `hardcoded_data_cleanup_plan.md` - 清理计划文档
- `hardcoded_data_summary.md` - 本总结报告

使用方法:
```bash
# 预演清理
node cleanup_hardcoded_data.js --dry-run

# 显示详细信息
node cleanup_hardcoded_data.js --dry-run --verbose

# 只清理P0级别
node cleanup_hardcoded_data.js --dry-run --priority=P0

# 实际执行(谨慎!)
node cleanup_hardcoded_data.js
```

## 总结

**已清理**: 4个文件,移除了所有测试数据和测试频道
**待处理**: 
- 8个文件的占位符图片URL
- 3个Repository的重构

**关键原则**:
- ✅ 零硬编码数据
- ✅ 所有内容来自网络源
- ✅ ConfigSourceService作为唯一数据源
- ✅ 符合TVBox/影视仓壳应用定位
