# RayTV 技术实现与开发指南

## 1. 开发环境与配置

### 1.1 环境要求
- **开发工具**：DevEco Studio最新版本
- **SDK版本**：HarmonyOS SDK API 19及以上
- **Node.js环境**：支持HarmonyOS开发
- **构建工具**：hvigor构建系统

### 1.2 项目配置
```bash
# 构建命令
cd /d d:\tv\RayTV
"C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=raytv -p product=default assembleHap
```

## 2. 项目结构详解

### 2.1 实际项目结构
```
raytv/
├── App.ets                          # 应用入口
├── common/                          # 通用组件和工具
│   ├── constant/                    # 常量定义
│   │   ├── AppConstant.ets          # 应用常量
│   │   ├── ConfigConstant.ets       # 配置常量
│   │   ├── PlayerConstant.ets       # 播放器常量
│   │   └── RemoteKeyConstant.ets    # 遥控器按键常量
│   ├── security/                    # 安全工具
│   ├── util/                        # 工具类
│   │   ├── DateUtil.ets             # 日期工具
│   │   ├── FileUtil.ets             # 文件工具
│   │   ├── JsonUtil.ets             # JSON工具
│   │   ├── Logger.ets               # 日志工具（单例模式实现）
│   │   ├── MemoryManager.ets        # 内存管理工具
│   │   ├── NetworkUtil.ets          # 网络工具
│   │   ├── StorageUtil.ets          # 存储工具
│   │   └── TimeoutManager.ets       # 超时管理工具
│   └── widget/                      # 自定义组件
├── components/                      # 组件目录
│   └── ImageComponent.ets           # 图片组件
├── data/                            # 数据层
│   ├── bean/                        # 数据模型
│   │   ├── Config.ets               # 配置信息模型
│   │   ├── DeviceInfo.ets           # 设备信息模型
│   │   ├── History.ets              # 历史记录模型
│   │   ├── Live.ets                 # 直播内容模型
│   │   ├── Site.ets                 # 站点模型
│   │   └── Vod.ets                  # 点播内容模型
│   ├── db/                          # 数据库相关
│   │   ├── DatabaseManager.ets      # 数据库管理器
│   │   ├── SQLiteHelper.ets         # SQLite助手类
│   │   ├── TableSchema.ets          # 表结构定义
│   │   └── dao/                     # 数据访问对象
│   ├── distributed/                 # 分布式数据管理
│   ├── dto/                         # 数据传输对象
│   ├── model/                       # 数据模型
│   ├── parser/                      # 数据解析器
│   ├── repository/                  # 数据仓库实现
│   │   ├── AuthRepository.ts        # 认证仓库
│   │   ├── CacheRepository.ts       # 缓存仓库
│   │   ├── CategoryRepository.ts    # 分类仓库
│   │   ├── CollectionRepository.ets # 收藏仓库
│   │   ├── ConfigRepository.ets     # 配置仓库
│   │   ├── HistoryRepository.ets    # 历史记录仓库
│   │   ├── LiveRepository.ets       # 直播仓库
│   │   ├── LiveStreamRepository.ts  # 直播流仓库
│   │   ├── LocalRepository.ets      # 本地仓库
│   │   ├── NetworkRepository.ets    # 网络仓库
│   │   ├── SiteRepository.ets       # 站点仓库
│   │   ├── UserRepository.ts        # 用户仓库
│   │   ├── VideoRepository.ts       # 视频仓库
│   │   └── VodRepository.ets        # 点播仓库
│   ├── service/                     # 数据服务
│   └── source/                      # 数据源
├── domain/                          # 业务逻辑层
│   ├── repository/                  # 仓库接口
│   ├── sandbox/                     # 沙箱隔离环境
│   ├── service/                     # 业务服务
│   │   └── MediaService.ts          # 媒体服务
│   └── usecase/                     # 用例
│       ├── LoadConfigUseCase.ets    # 加载配置用例
│       ├── PlayLiveUseCase.ets      # 播放直播用例
│       ├── PlayVodUseCase.ets       # 播放点播用例
│       ├── SearchLiveUseCase.ets    # 搜索直播用例
│       └── SearchVodUseCase.ets     # 搜索点播用例
├── pages/                           # 页面（主页面目录）
│   ├── CategoryPage.ets             # 分类页面
│   ├── FavoritesPage.ets            # 收藏页面
│   ├── HistoryPage.ets              # 历史页面
│   ├── HomePage.ets                 # 首页
│   ├── Index.ets                    # 索引页面
│   ├── MediaDetailPage.ets          # 媒体详情页面
│   ├── PlaybackPage.ets             # 播放页面
│   ├── SearchPage.ets               # 搜索页面
│   └── SettingsPage.ets             # 设置页面
├── presentation/                    # 表现层
│   ├── ability/                     # 应用能力
│   ├── harmony/                     # 鸿蒙特有组件
│   ├── page/                        # 表现层页面
│   ├── state/                       # 状态管理
│   ├── view/                        # 视图组件
│   └── viewmodel/                   # 视图模型
│       ├── DetailViewModel.ets      # 详情视图模型
│       ├── MainViewModel.ets        # 首页视图模型
│       ├── PlayerViewModel.ets      # 播放器视图模型
│       └── SearchViewModel.ets      # 搜索视图模型
├── raytvability/                    # 应用能力
│   └── RaytvAbility.ets             # 主应用能力
├── raytvbackupability/              # 备份能力
│   └── RaytvBackupAbility.ets       # 备份应用能力
├── service/                         # 服务层
│   ├── config/                      # 配置服务
│   │   ├── ConfigLoader.ets         # 配置加载器
│   │   ├── ConfigParser.ets         # 配置解析器
│   │   └── ConfigService.ets        # 配置服务
│   ├── flow/                        # 设备流转服务
│   ├── gesture/                     # 手势操作服务
│   ├── media/                       # 媒体服务
│   │   ├── FavoriteService.ts       # 收藏服务
│   │   ├── HistoryService.ts        # 历史记录服务
│   │   ├── MediaService.ts          # 媒体服务
│   │   └── PlaybackService.ts       # 播放服务
│   ├── player/                      # 播放器服务
│   ├── security/                    # 安全服务
│   ├── spider/                      # 爬虫服务
│   │   ├── CrawlerService.ts        # 爬虫服务
│   │   ├── LoaderFactory.ts         # 加载器工厂
│   │   ├── SiteManager.ts           # 站点管理器
│   │   ├── adapter/                 # 适配器
│   │   └── loader/                  # 加载器
│   └── voice/                       # 语音助手服务
├── services/                        # 额外服务目录
│   ├── DownloadService.ts           # 下载服务
│   ├── LiveStreamService.ts         # 直播流服务
│   ├── PlaybackService.ts           # 播放服务
│   └── UserService.ts               # 用户服务
├── task/                            # 任务调度
│   ├── pool/                        # 任务池
│   │   └── TaskPoolManager.ets      # 任务池管理器
│   └── scheduler/                   # 调度器
├── utils/                           # 工具类（额外工具目录）
│   ├── CacheService.ts              # 缓存服务
│   ├── DateUtils.ts                 # 日期工具
│   ├── EventBusUtil.ts              # 事件总线工具
│   ├── FileUtil.ts                  # 文件工具
│   ├── FormatUtil.ts                # 格式化工具
│   ├── NetworkUtil.ts               # 网络工具
│   ├── StorageUtil.ts               # 存储工具
│   ├── StringUtils.ts               # 字符串工具
│   └── ValidatorUtil.ts             # 验证工具
└── resources/                       # 资源文件
```

### 2.2 模块职责说明

#### 2.2.1 核心模块分层
- **表示层**：包括pages/（主页面）和presentation/（表现层组件），负责用户界面展示和交互
- **领域层**：domain/目录包含业务逻辑、用例和仓库接口，实现核心业务功能
- **数据层**：data/目录负责数据访问、存储和网络交互，包含仓库实现、数据模型和数据库操作
- **服务层**：service/目录提供各种功能服务，如配置、媒体、播放器等
- **通用层**：common/目录包含工具类、常量定义和通用组件

#### 2.2.2 主要模块职责
- **common/util/**：提供日志、网络、存储等基础工具类，支持应用各模块功能
- **data/bean/**：定义应用核心数据模型，包括配置、媒体内容、设备信息等
- **data/repository/**：实现数据访问逻辑，封装数据源操作细节
- **domain/usecase/**：实现具体业务用例，协调不同服务完成业务流程
- **service/**：提供各种功能服务，按功能模块组织（配置、媒体、爬虫等）
- **presentation/viewmodel/**：实现MVVM架构中的视图模型，连接视图和数据

## 3. 核心功能实现

### 3.1 配置服务实现

#### 3.1.1 配置文件加载
- 支持远程JSON配置文件，如`https://www.eoeoo.com/base2/a.json`或`https://q.uoouo.com/dianshi.json`
- 配置包含spider（爬虫）、sites（站点）、lives（直播源）、ads（广告屏蔽规则）、wallpaper（壁纸）等信息

#### 3.1.2 配置解析器
- **ConfigLoader.ets**：配置加载器，异步下载和解析配置文件
- **ConfigParser.ets**：配置解析器，实现错误处理和重试机制
- **LiveConfig.ets**：直播配置处理，支持spider配置和广告规则
- **VodConfig.ets**：点播配置处理，管理解析器、代理、规则等配置

### 3.2 爬虫服务实现

#### 3.2.1 爬虫加载机制
- **BaseLoader.ets**：爬虫加载基类，提供统一的爬虫获取接口
- **ArkJarLoader.ets**：基于ArkCompiler的JAR加载器，使用NativeAPI接口与JVM进行交互
- **ArkJsLoader.ets**：基于ArkTS引擎的JavaScript加载器
- **ArkPyLoader.ets**：基于HarmonyOS Python运行时的Python加载器

#### 3.2.2 爬虫执行流程
1. 从配置文件中解析spider字段，获取爬虫jar地址
2. 通过BaseLoader.parseJar方法加载爬虫jar
3. 当需要执行搜索或播放操作时，通过Site.spider()获取爬虫实例
4. 调用爬虫的相应方法（如searchContent、playerContent等）执行具体操作

### 3.3 播放器服务实现

#### 3.3.1 播放器架构
- **PlayerManager.ets**：播放器管理器，基于AVPlayer实现视频播放控制
- **VideoPlayer.ets**：自定义播放器组件，支持播放状态监听和事件回调
- **SourceManager.ets**：视频源管理器，支持多格式视频源处理

#### 3.3.2 播放流程
1. 用户选择要播放的视频
2. 应用调用SiteViewModel.playerContent方法
3. 获取视频的播放地址
4. 通过Source类进行视频源处理
5. 将处理后的地址传递给播放器进行播放

### 3.4 数据库实现

#### 3.4.1 数据库设计
- 使用RelationalStore替代Room
- 定义数据表结构和索引
- 实现数据访问接口

#### 3.4.2 主要数据表
- site：存储站点信息
- live：存储直播源信息
- history：存储播放历史
- keep：存储收藏信息
- config：存储配置信息
- device：存储设备信息（用于流转）

#### 3.4.3 数据库管理
- **DatabaseManager.ets**：采用单例模式管理数据库连接
- **SQLiteHelper.ets**：实现异步初始化和事务管理
- 提供统一的数据访问接口
- 实现数据库迁移和升级机制

## 4. 鸿蒙特有功能实现

### 4.1 语音助手服务
- 集成小艺语音助手API
- 开发语音命令解析和执行
- 实现语音反馈生成
- 添加自定义语音命令支持

### 4.2 设备流转服务
- 集成分布式硬件设备管理API
- 实现设备发现和连接管理
- 开发应用状态序列化和恢复机制
- 添加跨设备传输协议
- 实现流转状态监控和反馈

### 4.3 手势操作服务
- 集成手势识别API
- 实现NFC和星闪技术支持
- 开发设备能力检测逻辑
- 实现手势抓取投送功能
- 添加可视化反馈机制

## 5. 开发规范与最佳实践

### 5.1 代码组织规范
- **工具类统一**：所有工具类必须放在`common/util/`目录下，移除`utils/`目录，避免功能重复
- **服务层统一**：所有服务类必须放在`service/`目录下，按功能模块子目录组织，移除`data/service/`和`services/`目录
- **命名规范**：遵循统一的命名规则，工具类使用`XXXUtil.ets`，服务类使用`XXXService.ets`，管理器类使用`XXXManager.ets`

### 5.2 性能优化建议
- 避免频繁的状态更新，特别是在渲染循环中
- 使用@Builder和@BuilderParam实现组件复用
- 合理使用缓存机制，避免重复计算
- 大列表使用虚拟化渲染，减少内存占用
- 图片资源按需加载，避免一次性加载大量资源

### 5.3 安全开发规范
- 实现应用沙箱管理
- 开发权限控制和验证机制
- 添加网络访问安全监控
- 实现代码执行安全审计

## 6. 测试与部署

### 6.1 测试策略
- **单元测试**：开发核心功能单元测试用例
- **集成测试**：开发模块间交互测试
- **性能测试**：内存管理优化、启动优化、播放优化
- **兼容性测试**：在不同尺寸设备上测试适配效果

### 6.2 部署流程
- 使用hvigor构建系统进行应用打包
- 配置多设备兼容性支持
- 实现应用签名和安全验证
- 支持应用分发和更新机制