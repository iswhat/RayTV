# RayTV壳应用 - 硬编码数据清理方案

## 项目定位

这是一个TVBox/影视仓/Fongmi兼容的影视壳应用:
- ✅ 所有内容来自网络源配置
- ✅ 用户可在设置中配置网络源
- ✅ 支持导入网络库(包含多个源)
- ✅ 支持切换网络源切换内容
- ✅ 包含点播、直播IPTV、解析jar等功能
- ❌ **不应该有任何硬编码的测试数据、demo URL或示例内容**

## 网络源配置示例

合法的网络源配置:
- `https://www.eoeoo.com/base2/a.json` - 点播源
- `http://www.饭太硬.com/tv` - 点播源
- `https://q.uoouo.com/dianshi.json` - 点播源
- `https://www.eoeoo.com/list.json` - 网络库(多源)

## 必须清理的硬编码内容

### 1. 测试数据文件 (必须移除)

#### MediaDetailPage.ets
```typescript
// ❌ 错误 - 硬编码测试电影
this.media = {
  id: mediaId,
  name: '测试电影',
  cover: 'https://via.placeholder.com/300x450?text=Test+Movie',
  url: 'https://example.com/test-movie',
  // ...
};

// ❌ 错误 - 硬编码测试剧集
this.episodes = [
  { id: '1', name: '第1集', url: 'https://example.com/episode1' },
  { id: '2', name: '第2集', url: 'https://example.com/episode2' },
  // ...
];

// ❌ 错误 - 硬编码相关推荐
this.relatedMedia = [
  { title: '相关电影1', cover: 'https://via.placeholder.com/150x225', url: 'https://example.com/related1' },
  // ...
];
```

**正确做法**:
```typescript
// ✅ 正确 - 从网络源加载
try {
  const configService = ConfigSourceService.getInstance();
  const media = await configService.getVodDetail(mediaId);
  if (media) {
    this.media = media;
  } else {
    this.isError = true;
    this.errorMessage = '未找到媒体详情';
  }
} catch (error) {
  this.isError = true;
  this.errorMessage = '加载失败';
}
```

#### LivePage.ets
```typescript
// ❌ 错误 - 硬编码测试频道
this.channels = [
  { id: '1', name: 'CCTV-1', url: 'http://example.com/live/cctv1' },
  { id: '2', name: 'CCTV-2', url: 'http://example.com/live/cctv2' },
  // ...
];
```

**正确做法**:
```typescript
// ✅ 正确 - 从网络源的直播部分加载
try {
  const configService = ConfigSourceService.getInstance();
  const liveData = await configService.getLiveData();
  this.channels = liveData.channels || [];
} catch (error) {
  this.isError = true;
  this.errorMessage = '加载直播失败';
}
```

#### HomePage, MainPage, SearchPage等
```typescript
// ❌ 错误 - 硬编码占位符图片
Image(media.coverUrl || 'https://via.placeholder.com/300x450?text=No+Image')

// ❌ 错误 - 硬编码占位符URL
cover: 'https://via.placeholder.com/300x450?text=Test+Movie'
```

**正确做法**:
```typescript
// ✅ 正确 - 使用本地资源或动态加载
Image(media.coverUrl || $r('app.media.default_cover'))

// ✅ 正确 - 如果没有封面则显示文字
Column() {
  if (media.coverUrl) {
    Image(media.coverUrl)
  } else {
    Text('无封面')
  }
}
```

### 2. 测试API端点 (必须移除)

#### SearchRepository.ets
```typescript
// ❌ 错误 - 硬编码测试API
baseUrl: 'https://api.raytv.example.com',
```

**正确做法**:
```typescript
// ✅ 正确 - 使用ConfigSourceService从网络源搜索
const configService = ConfigSourceService.getInstance();
const results = await configService.searchVod(keyword);
```

#### RecommendationRepository.ets, LiveStreamRepository.ets
```typescript
// ❌ 错误 - 硬编码API
baseUrl: 'https://api.raytv.example.com',
```

**正确做法**:
```typescript
// ✅ 正确 - 使用ConfigSourceService
const configService = ConfigSourceService.getInstance();
const recommendations = await configService.getRecommendations();
```

### 3. 需要保留的URL类型

#### ✅ 合法的URL (必须保留)

1. **默认网络源配置** (用于初始引导)
```typescript
const DEFAULT_SOURCES = [
  {
    id: 'default_a',
    name: '默认配置源A',
    url: 'https://www.eoeoo.com/base2/a.json',
    type: 'json',
    isActive: true
  },
  {
    id: 'default_b',
    name: '默认配置源B',
    url: 'https://q.uoouo.com/dianshi.json',
    type: 'json',
    isActive: false
  }
];
```

2. **网络库配置** (用于批量导入)
```typescript
const DEFAULT_LIBRARIES = [
  {
    id: 'default_lib',
    name: '默认网络库',
    url: 'https://www.eoeoo.com/list.json',
    type: 'json'
  }
];
```

3. **文档注释中的示例URL** (可保留)
```typescript
/**
 * 示例: 从网络源加载配置
 * @example
 * await ConfigSourceService.loadSource('https://example.com/config.json');
 */
```

#### ❌ 不合法的URL (必须移除)

1. 占位符图片服务 (via.placeholder.com)
2. 测试API端点 (api.raytv.example.com)
3. 示例视频URL (example.com/video.mp4)
4. 示例图片URL (example.com/avatar.jpg)
5. 测试直播流 (example.com/live/*)
6. 本地IP (127.0.0.1, 192.168.*)

## 清理检查清单

### 必须清理 (P0 - 阻碍发布)

- [ ] MediaDetailPage.ets - 移除所有测试数据
- [ ] LivePage.ets - 移除所有测试频道
- [ ] SearchRepository.ets - 移除硬编码API
- [ ] RecommendationRepository.ets - 移除硬编码API
- [ ] LiveStreamRepository.ets - 移除硬编码API
- [ ] 所有页面 - 移除via.placeholder.com占位符
- [ ] MainPage/HomePage - 移除默认测试内容

### 应该清理 (P1 - 影响质量)

- [ ] SettingsPage.ets - 移除测试壁纸配置
- [ ] HistoryPage.ets - 确保无硬编码历史数据
- [ ] CategoryPage.ets - 确保分类来自网络源
- [ ] SearchResultPage.ets - 确保搜索结果来自网络源
- [ ] SearchPage.ets - 确保热词/建议来自网络源

### 可选清理 (P2 - 优化体验)

- [ ] 文档注释中的example.com URL (可以保留作为示例)
- [ ] 测试文件 (InfrastructureIntegrationTest.ts) - 可以保留

## 架构要求

### 数据流设计

```
用户配置 (存储)
    ↓
ConfigSourceService (加载网络源)
    ↓
┌───────────┬───────────┬───────────┐
│           │           │           │
点播源      直播源      解析jar    网络库
│           │           │           │
└───────────┴───────────┴───────────┘
    ↓           ↓           ↓
VodList    LiveList   ParserList
    ↓           ↓           ↓
HomePage    LivePage   SearchPage
    ↓           ↓           ↓
MediaDetail  LivePlay   ...
```

### 关键服务

#### ConfigSourceService
- 加载/切换网络源
- 解析点播/直播数据
- 管理解析jar
- 导入网络库

#### CacheService
- 缓存网络源数据
- 缓存搜索结果
- 离线支持

#### StorageService
- 保存用户配置
- 保存历史记录
- 保存收藏

## 测试验证

### 测试用例

1. **首次启动测试**
   - 不显示任何测试内容
   - 提示用户添加网络源
   - 显示默认源选项

2. **切换网络源测试**
   - 切换后内容完全变化
   - 缓存正确清除

3. **无网络测试**
   - 显示离线状态
   - 不显示任何硬编码数据

4. **导入网络库测试**
   - 成功导入多个源
   - 源列表正确显示

## TVBox兼容性

### 必须支持的特性

1. ✅ JSON格式网络源
2. ✅ 直播IPTV (m3u/json)
3. ✅ 点播数据 (VOD)
4. ✅ 解析jar支持
5. ✅ 搜索功能
6. ✅ 分类筛选
7. ✅ 历史记录
8. ✅ 收藏功能

### 网络源格式示例

```json
{
  "sites": [
    {
      "key": "site1",
      "name": "源名称",
      "type": 1,
      "api": "http://xxx.com/api",
      "searchable": 1,
      "quickSearch": 1,
      "filterable": 1,
      "ext": {
        "flag": ["qq", "qiyi"],
        "flags": [
          {
            "name": "QQ",
            "value": "qq"
          },
          {
            "name": "爱奇艺",
            "value": "qiyi"
          }
        ]
      },
      "jar": "http://xxx.com/spider.jar",
      "style": {
        "type": "list",
        "ratio": 1.78
      }
    }
  ],
  "lives": [
    {
      "name": "直播",
      "type": 0,
      "url": "http://xxx.com/live.m3u",
      "epg": "http://xxx.com/epg.xml"
    }
  ],
  "spider": "http://xxx.com/spider.jar"
}
```

## 实施步骤

1. **第一阶段: 移除所有硬编码测试数据**
   - 清理MediaDetailPage.ets
   - 清理LivePage.ets
   - 清理所有占位符URL

2. **第二阶段: 重构数据加载逻辑**
   - 确保所有数据来自ConfigSourceService
   - 移除自定义的Repository测试API

3. **第三阶段: 完善网络源管理**
   - 添加/删除/编辑网络源
   - 网络库导入功能
   - 网络源切换功能

4. **第四阶段: 测试验证**
   - 首次启动测试
   - 网络源切换测试
   - 无网络测试

## 预期效果

清理完成后:
- ✅ 零硬编码数据
- ✅ 所有内容来自网络源
- ✅ 用户完全自主配置
- ✅ 支持TVBox格式
- ✅ 符合壳应用定位
