# RayTV项目开发进度记录

## 代码诊断问题修复

### 1. 导入路径修复
- **MediaService.ts**
  - 修复Logger导入路径：从`../utils/Logger`改为`../../common/util/Logger`
  - 修复SiteInfo导入路径：从`../site/SiteManager`改为`../spider/SiteManager`
  
- **CrawlerService.ts**
  - 修复Logger导入路径：从`@ohos/base/Logger`改为`../../common/util/Logger`
  - 移除不存在的导入：`TaskPoolManager`和`NetworkManager`
  - 添加正确的导入：`NetworkService`

### 2. 方法调用修复
- **MediaService.ts**
  - 修复站点状态判断：从`site.status === 'enabled' || site.status === 1`改为`site.status === 'normal' || site.enabled`
  
- **CrawlerService.ts**
  - 修复网络连接检查：从`networkManager.isConnected()`改为`networkService.isConnected`
  - 修复获取站点列表方法名：从`siteManager.getSites()`改为`siteManager.getAllSites()`
  - 修复更新站点状态方法签名：返回类型从`boolean`改为`void`，移除返回值

### 3. 类属性修复
- **CrawlerService.ts**
  - 移除不存在的属性：`networkManager`和`taskPoolManager`
  - 添加正确的属性：`networkService`

## 已完成内容

### 1. 数据存储层
- **StorageUtil工具类** (已添加getObject和setObject方法)
  - 实现了本地存储、临时存储、持久化存储和安全存储等多种存储方式
  - 添加了对象和字符串的序列化与反序列化支持

### 2. 数据模型层
- 完成了数据模型层的开发，创建了以下数据模型文件：
  - `Vod.ets` - 点播内容数据模型
  - `Live.ets` - 直播内容数据模型
  - `Site.ets` - 站点数据模型
  - `History.ets` - 历史记录数据模型
  - `Config.ets` - 配置信息数据模型
  - `DeviceInfo.ets` - 设备信息数据模型

### 3. 数据库层
- **TableSchema.ets** - 定义了数据库表结构
  - 包含站点表、历史记录表、收藏表等8个核心表的结构定义
  - 定义了表创建SQL语句和列名常量
  
- **DatabaseManager.ets** - 实现数据库管理器
  - 负责数据库的初始化和连接管理
  - 基于HarmonyOS RelationalStore实现
  
- **SQLiteHelper.ets** - 提供数据库操作辅助方法
  - 实现了基本的CRUD操作
  - 支持查询条件构建和排序

### 4. 数据仓库层
- **SiteRepository.ets** - 站点数据仓库
  - 实现站点数据的CRUD操作
  - 支持站点分组管理和缓存机制
  
- **HistoryRepository.ets** - 历史记录数据仓库
  - 管理用户观看历史
  - 支持进度记录和历史查询
  
- **CollectionRepository.ets** - 收藏数据仓库
  - 管理用户收藏内容
  - 支持文件夹管理和收藏项分类
  
- **DeviceInfoRepository.ets** - 设备信息数据仓库
  - 负责设备信息的收集、存储和管理
  - 支持设备能力检测和使用统计
  
- **VodRepository.ets** - 点播内容数据仓库
  - 管理点播内容的缓存、搜索和播放历史
  - 支持分类和标签查询
  
- **LiveRepository.ets** - 直播内容数据仓库
  - 管理直播频道、分组和EPG数据
  - 支持频道搜索和播放记录

### 5. 网络服务层
- **NetworkService.ets** - 网络请求服务
  - 修复了导入和接口定义问题
  - 实现了HTTP请求、重试机制、缓存管理
  - 支持请求/响应拦截器和网络状态监控
  
- **DeviceService.ts** - 设备服务
  - 收集和管理设备信息
  - 检测设备能力和特性
  - 提供设备状态监控和使用统计

## 6. 配置服务层
- **ConfigLoader.ets**: 实现了多源配置加载器，支持从HTTP/HTTPS URL和本地文件系统加载配置，具备配置缓存功能和格式转换能力。
- **ConfigParser.ets**: 实现了配置解析器，负责解析和验证站点配置，支持Fongmi格式转换，提供站点类型自动识别和配置优化功能。
- **ConfigService.ets**: 实现了配置管理核心服务，提供配置导入、站点管理、健康检查等功能，支持URL和文件两种导入方式。

## 7. 爬虫服务层
- **BaseLoader.ets**: 实现了爬虫加载器基类，定义了统一的加载器接口和生命周期管理，提供错误处理和安全验证机制。
- **ArkJsLoader.ets**: 实现了JavaScript代码加载器，支持多源JS代码加载，具备安全沙箱隔离和危险代码过滤功能。
- **ArkPyLoader.ets**: 实现了Python代码加载器，提供安全的Python执行环境，支持异步任务执行和类型转换。
- **ArkJarLoader.ets**: 实现了JAR文件加载器，基于HarmonyOS ArkNative能力，提供安全沙箱管理和资源隔离。

## 8. 爬虫管理服务
- **SiteManager.ts**: 站点管理器，负责站点的注册、更新、删除和查询
- **LoaderFactory.ts**: 加载器工厂，根据站点配置创建对应的爬虫加载器
- **CacheManager.ts**: 缓存管理器，实现爬虫结果的本地缓存功能
- **CrawlerService.ts**: 爬虫服务核心，协调各组件完成爬虫任务

## 9. 业务逻辑层
  - **MediaService.ts** - 媒体业务逻辑服务
    - 管理点播和直播内容的播放控制
    - 实现媒体搜索、分类、详情获取、剧集列表、播放源获取等功能
  - **HistoryService.ts** - 历史记录服务
    - 管理用户播放历史记录
    - 支持历史记录的添加、更新、查询和删除操作
  - **FavoriteService.ts** - 收藏服务
    - 管理用户收藏的媒体内容
    - 支持收藏的添加、查询、更新和删除功能
  - 实现收藏、历史记录、搜索功能
  - 提供推荐内容和播放进度管理
  
- **PlayerService.ets** - 播放器服务
  - 实现了Android版Fongmi的所有播放控制功能
  - 支持自定义时间范围播放（结束时间自动跳转下一集）
  - 实现剧集控制（播放上一集/下一集）
  - 支持播放速度控制（设置/获取/切换）
  - 提供快进快退功能
  - 包含参数验证、错误处理和日志记录
  
- **PlaybackService.ts** - 播放服务
  - 实现视频播放控制、状态管理、播放信息获取、进度保存等功能

## 10. 配置服务层
- **ConfigService.ts** - 配置服务
  - 管理应用配置，包括主题、语言、缓存策略、播放设置等多方面配置的存取和监听

### 11. 页面组件层

11.1. HomePage.ets：首页组件，实现轮播图、分类导航、精选媒体列表、最新媒体列表、热门媒体列表和最近播放记录等功能。

11.2. MediaDetailPage.ets：媒体详情页组件，实现媒体信息展示、剧集列表、播放源选择、收藏管理和相关推荐等功能。

11.3. PlaybackPage.ets：播放页面组件，实现视频播放控制、进度管理、音量调节、播放速度调整和全屏切换等功能。

11.4. SearchPage.ets：搜索页面组件，实现搜索输入、热门搜索、搜索历史、搜索结果展示和分页加载等功能。

11.5. CategoryPage.ets：分类页面组件，实现媒体分类浏览、地区筛选、年份筛选、排序选择和媒体列表展示等功能。

11.6. FavoritesPage.ets：收藏页面组件，实现收藏媒体的展示、管理、编辑、删除和排序等功能。

11.7. HistoryPage.ets：历史记录页面组件，实现播放历史的展示、管理、编辑、删除、清空和自动续播设置等功能。

11.8. SettingsPage.ets：设置页面组件，实现应用配置管理，包括主题、语言、缓存、播放、通知和更新检查等功能。

### 12. 应用入口层

12.1. App.ets：应用主入口文件，实现应用初始化、路由配置、全局状态管理、生命周期管理（前台/后台切换）等功能。

### 13. 工具类层

13.1. Logger.ts：日志工具类，提供统一的日志记录功能，支持不同日志级别、标签分类和格式化输出。

13.2. NetworkUtils.ts：网络工具类，提供网络请求、响应处理、错误重试、网络连接检查等功能。

13.3. StorageUtils.ts：存储工具类，提供本地数据存储、读取、删除等功能，支持内存、本地和会话三种存储类型。

13.4. StringUtils.ts：字符串工具类，提供字符串处理、格式化、验证、相似度计算等功能。

13.5. DateUtils.ts：日期时间工具类，提供日期时间的格式化、解析、计算、相对时间显示等功能。 8. 用例层
- **SearchVodUseCase.ets** - 搜索点播用例
  - 实现搜索点播内容功能
  - 支持按分类搜索
  - 提供热门搜索关键词和搜索历史管理
  - 包含搜索缓存和智能搜索建议
  
- **PlayVodUseCase.ets** - 播放点播用例
  - 实现加载点播内容详情功能
  - 支持准备播放和保存播放进度
  - 提供切换视频源和收藏管理
  - 包含错误处理和结果缓存
  
- **PlayLiveUseCase.ets** - 播放直播用例
  - 实现获取直播频道分组和频道列表功能
  - 支持直播播放准备和EPG获取
  - 提供频道收藏和直播源刷新
  - 包含观看历史记录
  
- **SearchLiveUseCase.ets** - 搜索直播用例
  - 实现直播频道搜索功能
  - 支持搜索历史管理和热门关键词
  - 提供搜索建议和结果缓存
  
- **LoadConfigUseCase.ets** - 加载配置用例
  - 实现应用配置的加载、保存和重置功能
  - 支持配置缓存和设备优化
  - 提供配置更新方法（播放器、显示、网络等）
  - 包含配置验证和错误处理

### 9. UI界面层
- **VideoCard.ets**: 创建了通用视频卡片组件，支持显示封面、标题、评分、年份等信息，实现了悬停效果和收藏功能
- **PlayerController.ets**: 实现了完整的播放器控制界面，包含播放/暂停、进度条、音量控制、全屏切换等功能
- **CategoryNavigation.ets**: 开发了分类导航组件，支持水平滚动和分类切换，包含滚动指示器
- **HomePage.ets**: 创建了主页面，整合了视频卡片、分类导航和播放器控制器，实现了基本的内容展示和交互
- **Index.ets**: 更新了应用入口，集成了HomePage组件

### 10. ViewModel层
- **MainViewModel.ets**: 实现了首页视图模型，包括初始化首页数据、切换标签页、加载最近观看、热门点播、直播分组等功能，支持数据刷新和状态管理
- **DetailViewModel.ets**: 实现了详情页视图模型，包括加载内容详情、切换收藏状态、选择视频源和剧集、准备播放、分享内容等功能
- **SearchViewModel.ets**: 实现了搜索页视图模型，包括搜索功能、热门关键词展示、搜索历史管理、搜索建议、结果分类展示等功能，支持多类型内容（点播/直播）的搜索
- **PlayerViewModel.ets**: 实现了播放器视图模型，包括播放器状态管理、进度控制、音量控制、全屏切换、视频源切换、收藏管理、直播源刷新等功能，支持点播和直播两种播放模式