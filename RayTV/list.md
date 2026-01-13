# RayTV代码文件列表

## 主项目代码文件

### 配置文件
- raytv/package.json
- raytv/tsconfig.json
- raytv/build-profile.json5
- raytv/oh-package.json5

### 主入口和能力文件
- raytv/src/main/ets/MainAbility.ets
- raytv/src/main/ets/raytvbackupability/RayTVBackupAbility.ets

### 公共基础类
- raytv/src/main/ets/common/base/FactoryBase.ets

### 常量定义
- raytv/src/main/ets/common/constant/AppConstant.ets
- raytv/src/main/ets/common/constant/ConfigConstant.ets
- raytv/src/main/ets/common/constant/PlayerConstant.ets
- raytv/src/main/ets/common/constant/RemoteKeyConstant.ets

### 工具类
- raytv/src/main/ets/common/util/CommonUtil.ets
- raytv/src/main/ets/common/util/DateUtil.ets
- raytv/src/main/ets/common/util/EventBusUtil.ets
- raytv/src/main/ets/common/util/EventEmitter.ets
- raytv/src/main/ets/common/util/FileUtil.ets
- raytv/src/main/ets/common/util/FormatUtil.ets
- raytv/src/main/ets/common/util/JsonUtil.ets
- raytv/src/main/ets/common/util/Logger.ets
- raytv/src/main/ets/common/util/MemoryManager.ets
- raytv/src/main/ets/common/util/NetworkUtil.ets
- raytv/src/main/ets/common/util/PinyinUtil.ets
- raytv/src/main/ets/common/util/StorageUtil.ets
- raytv/src/main/ets/common/util/StringUtils.ets
- raytv/src/main/ets/common/util/TimeoutManager.ets
- raytv/src/main/ets/common/util/TypeSafetyHelper.ets
- raytv/src/main/ets/common/util/TypeSafetyUtil.ets
- raytv/src/main/ets/common/util/ValidatorUtil.ets

### ArkTS工具类
- raytv/src/main/ets/common/util/ark/ArkTSUtils.ets
- raytv/src/main/ets/common/util/ark/ArrayUtils.ets
- raytv/src/main/ets/common/util/ark/DateUtils.ets
- raytv/src/main/ets/common/util/ark/JsonUtils.ets
- raytv/src/main/ets/common/util/ark/ObjectUtils.ets
- raytv/src/main/ets/common/util/ark/StorageUtils.ets
- raytv/src/main/ets/common/util/ark/StringUtils.ets
- raytv/src/main/ets/common/util/ark/TypeUtils.ets
- raytv/src/main/ets/common/util/ark/UtilityFunctions.ets

### ArkTS类型定义
- raytv/src/main/ets/common/util/ark/types/ArkTSBaseTypes.ets
- raytv/src/main/ets/common/util/ark/types/ArkTSUtilityTypes.ets

### 组件
- raytv/src/main/ets/components/BestPractices.ets
- raytv/src/main/ets/components/ImageComponent.ets
- raytv/src/main/ets/components/styles/HomePageStyles.ets

### 数据模型
- raytv/src/main/ets/data/bean/Config.ets
- raytv/src/main/ets/data/bean/DeviceInfo.ets
- raytv/src/main/ets/data/bean/History.ets
- raytv/src/main/ets/data/bean/Live.ets
- raytv/src/main/ets/data/bean/MediaItem.ets
- raytv/src/main/ets/data/bean/Site.ets
- raytv/src/main/ets/data/bean/Vod.ets

### 数据库相关
- raytv/src/main/ets/data/db/DatabaseManager.ets
- raytv/src/main/ets/data/db/SQLiteHelper.ets
- raytv/src/main/ets/data/db/TableSchema.ets
- raytv/src/main/ets/data/db/dao/CollectionDao.ets
- raytv/src/main/ets/data/db/dao/HistoryDao.ets
- raytv/src/main/ets/data/db/dao/LineDao.ets
- raytv/src/main/ets/data/db/dao/SiteDao.ets
- raytv/src/main/ets/data/db/dao/SubscriptionDao.ets

### 数据传输对象
- raytv/src/main/ets/data/dto/ApiResponse.ets
- raytv/src/main/ets/data/dto/MovieDetailDto.ets
- raytv/src/main/ets/data/dto/SearchDto.ets
- raytv/src/main/ets/data/dto/UserDto.ets
- raytv/src/main/ets/data/dto/VideoDto.ets

### 数据模型
- raytv/src/main/ets/data/model/CacheModel.ets
- raytv/src/main/ets/data/model/ConfigModel.ets
- raytv/src/main/ets/data/model/DatabaseModel.ets
- raytv/src/main/ets/data/model/History.ets
- raytv/src/main/ets/data/model/LocalModel.ets
- raytv/src/main/ets/data/model/Movie.ets
- raytv/src/main/ets/data/model/NetworkModel.ets
- raytv/src/main/ets/data/model/SearchResult.ets
- raytv/src/main/ets/data/model/User.ets

### 仓库
- raytv/src/main/ets/data/repository/AuthRepository.ets
- raytv/src/main/ets/data/repository/CacheRepository.ets
- raytv/src/main/ets/data/repository/CategoryRepository.ets
- raytv/src/main/ets/data/repository/CollectionRepository.ets
- raytv/src/main/ets/data/repository/ConfigRepository.ets
- raytv/src/main/ets/data/repository/DatabaseRepository.ets
- raytv/src/main/ets/data/repository/DefaultNetworkRepository.ets
- raytv/src/main/ets/data/repository/DeviceInfoRepository.ets
- raytv/src/main/ets/data/repository/HistoryRepository.ets
- raytv/src/main/ets/data/repository/LiveRepository.ets
- raytv/src/main/ets/data/repository/LiveStreamRepository.ets
- raytv/src/main/ets/data/repository/LocalRepository.ets
- raytv/src/main/ets/data/repository/ModernDatabaseRepository.ets
- raytv/src/main/ets/data/repository/NetworkRepository.ets
- raytv/src/main/ets/data/repository/NotificationRepository.ets
- raytv/src/main/ets/data/repository/PlaybackRepository.ets
- raytv/src/main/ets/data/repository/RecommendationRepository.ets
- raytv/src/main/ets/data/repository/RepositoryFactory.ets
- raytv/src/main/ets/data/repository/SQLiteDatabaseRepository.ets
- raytv/src/main/ets/data/repository/SearchHistoryRepository.ets
- raytv/src/main/ets/data/repository/SearchRepository.ets
- raytv/src/main/ets/data/repository/SiteRepository.ets
- raytv/src/main/ets/data/repository/UserRepository.ets
- raytv/src/main/ets/data/repository/VideoRepository.ets
- raytv/src/main/ets/data/repository/VodRepository.ets

### 导航
- raytv/src/main/ets/navigation/AppNavigator.ets

### 页面
- raytv/src/main/ets/pages/CategoryPage.ets
- raytv/src/main/ets/pages/FavoritesPage.ets
- raytv/src/main/ets/pages/HistoryPage.ets
- raytv/src/main/ets/pages/HomePage.ets
- raytv/src/main/ets/pages/Index.ets
- raytv/src/main/ets/pages/LineManagerPage.ets
- raytv/src/main/ets/pages/LineManagerPageStyles.ets
- raytv/src/main/ets/pages/MainPage.ets
- raytv/src/main/ets/pages/MediaDetailPage.ets
- raytv/src/main/ets/pages/PlaybackPage.ets
- raytv/src/main/ets/pages/SearchPage.ets
- raytv/src/main/ets/pages/SettingsPage.ets

### 服务
- raytv/src/main/ets/service/AppService.ets
- raytv/src/main/ets/service/HttpService.ets
- raytv/src/main/ets/service/ServiceFactory.ets

#### 广告拦截服务
- raytv/src/main/ets/service/adblock/AdBlockManager.ets

#### 分析服务
- raytv/src/main/ets/service/analytics/AnalyticsService.ets

#### 缓存服务
- raytv/src/main/ets/service/cache/CacheService.ets

#### 收藏服务
- raytv/src/main/ets/service/collection/CollectionService.ets

#### 配置服务
- raytv/src/main/ets/service/config/ConfigLoader.ets
- raytv/src/main/ets/service/config/ConfigParser.ets
- raytv/src/main/ets/service/config/ConfigService.ets
- raytv/src/main/ets/service/config/LineManager.ets
- raytv/src/main/ets/service/config/SettingService.ets
- raytv/src/main/ets/service/config/SubscriptionManager.ets

#### 弹幕服务
- raytv/src/main/ets/service/danmaku/DanmakuService.ets

#### 设备服务
- raytv/src/main/ets/service/device/DeviceFlowManager.ets
- raytv/src/main/ets/service/device/DeviceManager.ets
- raytv/src/main/ets/service/device/DeviceService.ets

#### 下载服务
- raytv/src/main/ets/service/download/DownloadService.ets

#### 输入服务
- raytv/src/main/ets/service/input/GestureService.ets

#### 直播服务
- raytv/src/main/ets/service/live/LiveStreamService.ets

#### 媒体服务
- raytv/src/main/ets/service/media/FavoriteService.ets
- raytv/src/main/ets/service/media/HistoryService.ets
- raytv/src/main/ets/service/media/MediaCacheService.ets
- raytv/src/main/ets/service/media/MediaCacheServiceFixed.ets
- raytv/src/main/ets/service/media/MediaService.ets
- raytv/src/main/ets/service/media/MovieService.ets
- raytv/src/main/ets/service/media/SubtitleService.ets

#### 解析服务
- raytv/src/main/ets/service/parser/ParserService.ets
- raytv/src/main/ets/service/parser/index.ets

#### 播放服务
- raytv/src/main/ets/service/playback/AVPlayerService.ets
- raytv/src/main/ets/service/playback/HistoryManager.ets
- raytv/src/main/ets/service/playback/PlaybackService.ets

#### 播放器服务
- raytv/src/main/ets/service/player/PlayerService.ets

#### 搜索服务
- raytv/src/main/ets/service/search/SearchService.ets

#### 爬虫服务
- raytv/src/main/ets/service/spider/CacheManager.ets
- raytv/src/main/ets/service/spider/CrawlerService.ets
- raytv/src/main/ets/service/spider/LoaderFactory.ets
- raytv/src/main/ets/service/spider/SiteManager.ets
- raytv/src/main/ets/service/spider/SiteService.ets

##### 爬虫加载器
- raytv/src/main/ets/service/spider/loader/ArkJarLoader.ets
- raytv/src/main/ets/service/spider/loader/ArkJsLoader.ets
- raytv/src/main/ets/service/spider/loader/ArkPyLoader.ets
- raytv/src/main/ets/service/spider/loader/BaseLoader.ets
- raytv/src/main/ets/service/spider/loader/index.ets

#### 存储服务
- raytv/src/main/ets/service/storage/FileService.ets

#### 同步服务
- raytv/src/main/ets/service/sync/DataSyncService.ets
- raytv/src/main/ets/service/sync/DistributedDataService.ets
- raytv/src/main/ets/service/sync/ModernDistributedDataService.ets

#### 用户服务
- raytv/src/main/ets/service/user/UserService.ets

#### 语音服务
- raytv/src/main/ets/service/voice/VoiceAssistantManager.ets

#### 壁纸服务
- raytv/src/main/ets/service/wallpaper/WallManager.ets

### 类型定义
- raytv/src/main/ets/types/common.ets
- raytv/src/main/ets/types/commonTypes.ets
- raytv/src/main/ets/types/module-declarations.ets

## 测试文件
- raytv/src/test/ConfigParser.test.ets
- raytv/src/test/List.test.ets
- raytv/src/test/LocalUnit.test.ets
- raytv/src/ohosTest/ets/test/Ability.test.ets
- raytv/src/ohosTest/ets/test/List.test.ets

## 脚本文件
- raytv/simple_test.js
- raytv/test_config_parser_integration.js
- raytv/test_site_parse.js
- raytv/test_site_parse.ets

## 接口检查文件
- raytv/check_interface.ts
