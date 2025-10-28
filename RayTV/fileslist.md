# RayTV 已实现代码文件索引

## 1. 工具类 (common/util/)

| 文件名 | 路径 | 功能描述 | 存在于规划文档 | 存在于计划文档 | 备注 |
|-------|------|---------|-------------|-------------|------|
| Logger.ets | common/util/Logger.ets | 日志工具类，支持多级别日志、格式化输出、持久化存储和静态方法兼容 | ✓ | ✓ | 单例模式实现 |
| StorageUtil.ets | common/util/StorageUtil.ets | 存储工具类，处理本地数据存储 | ✓ | ✓ | |
| DateUtil.ets | common/util/DateUtil.ets | 日期时间工具类 | ✓ | ✓ | |
| FileUtil.ets | common/util/FileUtil.ets | 文件操作工具类 | ✓ | ✓ | |
| NetworkUtil.ets | common/util/NetworkUtil.ets | 网络工具类 | ✓ | ✓ | |

## 2. 数据服务 (data/service/)

| 文件名 | 路径 | 功能描述 | 存在于规划文档 | 存在于计划文档 | 备注 |
|-------|------|---------|-------------|-------------|------|
| SettingService.ets | data/service/SettingService.ets | 设置服务，管理应用配置、主题设置等 | ✓ | ✓ | 单例模式 |
| AppService.ets | data/service/AppService.ets | 应用服务，应用级别的服务管理 | ✓ | ✓ | |
| AuthService.ets | data/service/AuthService.ets | 认证服务，处理用户认证 | ✓ | ✓ | |
| CollectionService.ets | data/service/CollectionService.ets | 收藏服务，管理用户收藏 | ✓ | ✓ | |
| DataSyncService.ets | data/service/DataSyncService.ets | 数据同步服务 | ✓ | ✓ | |
| DeviceManager.ets | data/service/DeviceManager.ets | 设备管理器 | ✓ | ✓ | |
| DeviceService.ets | data/service/DeviceService.ets | 设备服务 | ✓ | ✓ | |
| DistributedDataService.ets | data/service/DistributedDataService.ets | 分布式数据服务 | ✓ | ✓ | |
| FileService.ets | data/service/FileService.ets | 文件服务 | ✓ | ✓ | |
| HistoryManager.ets | data/service/HistoryManager.ets | 历史记录管理器 | ✓ | ✓ | 与HistoryService功能重复，待移除 |
| MediaCacheService.ets | data/service/MediaCacheService.ets | 媒体缓存服务 | ✓ | ✓ | |
| MediaService.ets | data/service/MediaService.ets | 媒体服务 | ✓ | ✓ | |
| MovieService.ets | data/service/MovieService.ets | 电影服务 | ✓ | ✓ | |
| NetworkService.ets | data/service/NetworkService.ets | 网络服务 | ✓ | ✓ | |
| PlaybackService.ets | data/service/PlaybackService.ets | 播放服务 | ✓ | ✓ | |
| PlayerService.ets | data/service/PlayerService.ets | 播放器服务 | ✓ | ✓ | |
| SearchService.ets | data/service/SearchService.ets | 搜索服务 | ✓ | ✓ | |
| ServiceFactory.ets | data/service/ServiceFactory.ets | 服务工厂，创建和管理服务实例 | ✓ | ✓ | 已更新服务创建逻辑 |
| SiteService.ets | data/service/SiteService.ets | 站点服务 | ✓ | ✓ | |
| SubtitleService.ets | data/service/SubtitleService.ets | 字幕服务 | ✓ | ✓ | |

## 3. 服务层 (service/)

| 文件名 | 路径 | 功能描述 | 存在于规划文档 | 存在于计划文档 | 备注 |
|-------|------|---------|-------------|-------------|------|
| ConfigLoader.ets | service/config/ConfigLoader.ets | 配置加载器 | ✓ | ✓ | |
| ConfigParser.ets | service/config/ConfigParser.ets | 配置解析器 | ✓ | ✓ | |
| ConfigService.ets | service/config/ConfigService.ets | 配置服务，管理应用配置 | ✓ | ✓ | 单例模式，已从data/service/移动 |
| CacheService.ets | service/cache/CacheService.ets | 缓存服务，管理应用缓存 | ✓ | ✓ | 单例模式，已从data/service/移动 |
| DownloadService.ets | service/download/DownloadService.ets | 下载服务类，管理视频下载任务和下载队列 | ✓ | ✓ | 单例模式，支持多任务管理，已从data/service/移动 |
| HistoryService.ets | service/media/HistoryService.ets | 历史记录服务，管理观看历史记录 | ✓ | ✓ | 单例模式，已从data/service/移动 |
| LiveStreamService.ets | service/live/LiveStreamService.ets | 直播流服务 | ✓ | ✓ | 已从data/service/移动 |
| NotificationService.ets | service/notification/NotificationService.ets | 通知服务，管理应用通知 | ✓ | ✓ | 基于HarmonyOS通知API，已从data/service/移动 |
| UserService.ets | service/user/UserService.ets | 用户服务，负责用户账户管理、认证授权和用户数据同步 | ✓ | ✓ | 单例模式，支持多种登录方式，已从data/service/移动 |
| CrawlerService.ts | service/spider/CrawlerService.ts | 爬虫服务 | ✓ | ✓ | |
| LoaderFactory.ts | service/spider/LoaderFactory.ts | 加载器工厂 | ✓ | ✓ | |
| SiteManager.ts | service/spider/SiteManager.ts | 站点管理器 | ✓ | ✓ | |

## 4. 额外服务 (services/)

| 文件名 | 路径 | 功能描述 | 存在于规划文档 | 存在于计划文档 | 备注 |
|-------|------|---------|-------------|-------------|------|
| DownloadService.ts | services/DownloadService.ts | 下载服务（重复实现） | ✓ | ✓ | 与service/download/DownloadService.ets功能重复，待移除 |
| LiveStreamService.ts | services/LiveStreamService.ts | 直播流服务（重复实现） | ✓ | ✓ | 与service/live/LiveStreamService.ets功能重复，待移除 |
| PlaybackService.ts | services/PlaybackService.ts | 播放服务（重复实现） | ✓ | ✓ | 与data/service/PlaybackService.ets功能重复 |
| UserService.ts | services/UserService.ts | 用户服务（重复实现） | ✓ | ✓ | 与service/user/UserService.ets功能重复，待移除 |

## 5. 工具类（额外） (utils/)

| 文件名 | 路径 | 功能描述 | 存在于规划文档 | 存在于计划文档 | 备注 |
|-------|------|---------|-------------|-------------|------|
| CacheService.ts | utils/CacheService.ts | 缓存服务（重复实现） | ✓ | ✓ | 与service/cache/CacheService.ets功能重复，待移除 |
| DateUtils.ts | utils/DateUtils.ts | 日期工具（重复实现） | ✓ | ✓ | 与common/util/DateUtil.ets功能重复 |
| EventBusUtil.ts | utils/EventBusUtil.ts | 事件总线工具 | ✓ | ✓ | |
| FileUtil.ts | utils/FileUtil.ts | 文件工具（重复实现） | ✓ | ✓ | 与common/util/FileUtil.ets功能重复 |
| FormatUtil.ts | utils/FormatUtil.ts | 格式化工具 | ✓ | ✓ | |
| NetworkUtil.ts | utils/NetworkUtil.ts | 网络工具（重复实现） | ✓ | ✓ | 与common/util/NetworkUtil.ets功能重复 |
| NetworkUtils.ts | utils/NetworkUtils.ts | 网络工具（重复实现） | ✓ | ✓ | 与common/util/NetworkUtil.ets功能重复 |
| StorageUtil.ts | utils/StorageUtil.ts | 存储工具（重复实现） | ✓ | ✓ | 与common/util/StorageUtil.ets功能重复 |
| StorageUtils.ts | utils/StorageUtils.ts | 存储工具（重复实现） | ✓ | ✓ | 与common/util/StorageUtil.ets功能重复 |
| StringUtils.ts | utils/StringUtils.ts | 字符串工具 | ✓ | ✓ | |
| ValidatorUtil.ts | utils/ValidatorUtil.ts | 验证工具 | ✓ | ✓ | |

## 6. 页面 (pages/)

| 文件名 | 路径 | 功能描述 | 存在于规划文档 | 存在于计划文档 | 备注 |
|-------|------|---------|-------------|-------------|------|
| CategoryPage.ets | pages/CategoryPage.ets | 分类页面 | ✓ | ✓ | |
| FavoritesPage.ets | pages/FavoritesPage.ets | 收藏页面 | ✓ | ✓ | |
| HistoryPage.ets | pages/HistoryPage.ets | 历史页面 | ✓ | ✓ | |
| HomePage.ets | pages/HomePage.ets | 首页 | ✓ | ✓ | |
| Index.ets | pages/Index.ets | 索引页面 | ✓ | ✓ | |
| MediaDetailPage.ets | pages/MediaDetailPage.ets | 媒体详情页面 | ✓ | ✓ | |
| PlaybackPage.ets | pages/PlaybackPage.ets | 播放页面 | ✓ | ✓ | |
| SearchPage.ets | pages/SearchPage.ets | 搜索页面 | ✓ | ✓ | |
| SettingsPage.ets | pages/SettingsPage.ets | 设置页面 | ✓ | ✓ | |

## 7. 应用能力

| 文件名 | 路径 | 功能描述 | 存在于规划文档 | 存在于计划文档 | 备注 |
|-------|------|---------|-------------|-------------|------|
| RaytvAbility.ets | raytvability/RaytvAbility.ets | 主应用能力 | ✓ | ✓ | |
| RaytvBackupAbility.ets | raytvbackupability/RaytvBackupAbility.ets | 备份应用能力 | ✓ | ✓ | |

## 8. 示例代码

| 文件名 | 路径 | 功能描述 | 存在于规划文档 | 存在于计划文档 | 备注 |
|-------|------|---------|-------------|-------------|------|
| ServiceUsageExample.ets | example/ServiceUsageExample.ets | 服务使用示例 | ✓ | ✓ | |

## 重复开发问题记录

### 1. 工具类重复
- common/util/ 下的工具类与 utils/ 下的工具类存在大量重复
- 已开始重构，Logger工具已合并到common/util/目录
- 下一步计划：统一使用 common/util/ 作为工具类的标准目录，移除 utils/ 中的重复实现

### 2. 服务层重复
- 已完成主要服务的重组，将核心服务统一到service/目录下
- services/目录下的重复服务已标记为待移除
- data/service/目录下的服务将逐步迁移到service/对应子目录

### 3. 功能职责重复
- HistoryService.ets 和 HistoryManager.ets 功能重叠，计划保留HistoryService作为主要实现
- 其他功能重复的服务将在后续重构中合并或移除

### 4. 命名不统一
- 部分工具类命名不一致（如 DateUtil vs DateUtils）
- 已制定规范：工具类使用驼峰命名法，统一为XXXUtil格式

### 5. 目录结构优化
- 已完成服务层初步重构，按功能域组织到service/子目录
- 后续计划：完全按照领域驱动设计原则重新组织目录结构，明确各层职责
