# RayTV 鸿蒙OS应用移植技术执行计划

## 说明
本文档基于《RayTV - 鸿蒙OS应用移植规划文档》(RayTV_dev.md)制定，旨在提供一个详细的、可执行的技术实施路径，细化到最小的模块和关键变量。执行过程中严格遵循以下原则：
- Android版Fongmi仅作为需求实现的逻辑参考，不作为代码实现的参考
- 所有功能模块将完全基于HarmonyOS原生API和技术栈进行设计和实现
- 充分利用鸿蒙系统特性，确保应用在不同设备上的一致体验
- 遵循模块化、可扩展的设计理念

## 1. 项目概述

### 1.1 目标与范围
- 实现Android版RayTV功能的完整移植到HarmonyOS 5/6平台
- 支持多设备（手机、平板、电视）适配
- 集成鸿蒙特有功能：小艺语音助手、设备流转、手势操作
- 基于HarmonyOS SDK API 19开发

### 1.2 技术栈确认
- **开发语言**：ArkTS (主要)、TypeScript (辅助)
- **UI框架**：ArkUI (声明式UI)
- **媒体播放**：AVPlayer (HarmonyOS原生)
- **数据库**：RelationalStore (关系型数据库)
- **网络请求**：@ohos.net.http (API 19)
- **并发处理**：TaskPool (API 19)
- **安全沙箱**：@ohos.sandbox (API 19)
- **分布式能力**：@ohos.distributedHardware.deviceManager (API 19)
- **手势识别**：@ohos.multimodalInput.gesture (API 19)

## 2. 详细项目结构

```
raytv/
├── App.ets                          # 应用入口
├── MainAbility.ets                  # 主应用能力
├── common/                          # 通用组件和工具
│   ├── constant/                    # 常量定义
│   │   ├── AppConstant.ets          # 应用常量
│   │   ├── ConfigConstant.ets       # 配置常量
│   │   ├── PlayerConstant.ets       # 播放器常量
│   │   └── RemoteKeyConstant.ets    # 遥控器按键常量
│   ├── util/                        # 工具类
│   │   ├── Logger.ets               # 日志工具
│   │   ├── NetworkUtil.ets          # 网络工具
│   │   ├── FileUtil.ets             # 文件工具
│   │   ├── JsonUtil.ets             # JSON工具
│   │   ├── StringUtil.ets           # 字符串工具
│   │   └── DeviceUtil.ets           # 设备工具
│   ├── widget/                      # 自定义组件
│   │   ├── LoadingComponent.ets     # 加载组件
│   │   ├── ErrorComponent.ets       # 错误组件
│   │   └── EmptyComponent.ets       # 空状态组件
│   └── security/                    # 安全工具
│       ├── SecurityManager.ets      # 安全管理器
│       └── SandboxUtil.ets          # 沙箱工具
├── data/                            # 数据层
│   ├── bean/                        # 数据模型
│   │   ├── Vod.ets                  # 点播内容模型
│   │   ├── Live.ets                 # 直播内容模型
│   │   ├── Site.ets                 # 站点模型
│   │   ├── History.ets              # 历史记录模型
│   │   ├── Config.ets               # 配置信息模型
│   │   └── DeviceInfo.ets           # 设备信息模型
│   ├── db/                          # 数据库相关
│   │   ├── DatabaseManager.ets      # 数据库管理器
│   │   ├── TableSchema.ets          # 表结构定义
│   │   └── dao/                     # 数据访问对象
│   │       ├── SiteDao.ets          # 站点DAO
│   │       ├── LiveDao.ets          # 直播DAO
│   │       ├── HistoryDao.ets       # 历史记录DAO
│   │       ├── KeepDao.ets          # 收藏DAO
│   │       └── ConfigDao.ets        # 配置DAO
│   ├── distributed/                 # 分布式数据管理
│   │   └── DistributedDataManager.ets # 分布式数据管理器
│   ├── parser/                      # 数据解析器
│   │   ├── VodParser.ets            # 点播内容解析器
│   │   ├── LiveParser.ets           # 直播内容解析器
│   │   └── SourceParser.ets         # 视频源解析器
│   └── source/                      # 数据源
│       ├── RemoteDataSource.ets     # 远程数据源
│       └── LocalDataSource.ets      # 本地数据源
├── domain/                          # 业务逻辑层
│   ├── repository/                  # 数据仓库
│   │   ├── VodRepository.ets        # 点播内容仓库
│   │   ├── LiveRepository.ets       # 直播内容仓库
│   │   └── ConfigRepository.ets     # 配置仓库
│   ├── usecase/                     # 用例
│   │   ├── SearchVodUseCase.ets     # 搜索点播用例
│   │   ├── PlayVodUseCase.ets       # 播放点播用例
│   │   ├── PlayLiveUseCase.ets      # 播放直播用例
│   │   └── LoadConfigUseCase.ets    # 加载配置用例
│   └── sandbox/                     # 沙箱隔离环境
│       └── SandboxEnvironment.ets   # 沙箱环境管理
├── presentation/                    # 表现层
│   ├── ability/                     # 应用能力
│   │   ├── SearchAbility.ets        # 搜索能力
│   │   ├── DetailAbility.ets        # 详情能力
│   │   └── PlayAbility.ets          # 播放能力
│   ├── page/                        # 页面
│   │   ├── MainPage.ets             # 首页
│   │   ├── SearchPage.ets           # 搜索页
│   │   ├── DetailPage.ets           # 详情页
│   │   ├── PlayPage.ets             # 播放页
│   │   ├── SettingPage.ets          # 设置页
│   │   └── LivePage.ets             # 直播页
│   ├── viewmodel/                   # 视图模型
│   │   ├── MainViewModel.ets        # 首页视图模型
│   │   ├── SearchViewModel.ets      # 搜索视图模型
│   │   ├── DetailViewModel.ets      # 详情视图模型
│   │   └── PlayViewModel.ets        # 播放视图模型
│   ├── state/                       # 状态管理
│   │   └── AppState.ets             # 应用全局状态
│   └── harmony/                     # 鸿蒙特有UI组件
│       ├── VoiceAssistantComponent.ets # 语音助手组件
│       ├── DeviceFlowComponent.ets  # 设备流转组件
│       └── GestureControlComponent.ets # 手势控制组件
├── service/                         # 服务层
│   ├── player/                      # 播放器服务
│   │   ├── PlayerManager.ets        # 播放器管理器
│   │   ├── VideoPlayer.ets          # 自定义播放器组件
│   │   ├── SourceManager.ets        # 视频源管理器
│   │   └── PlayHistoryManager.ets   # 播放历史管理器
│   ├── spider/                      # 爬虫服务
│   │   ├── loader/                  # 多语言加载器
│   │   │   ├── BaseLoader.ets       # 爬虫加载基类
│   │   │   ├── jar/                 # JAR加载器
│   │   │   │   └── ArkJarLoader.ets # Ark JAR加载器
│   │   │   ├── js/                  # JavaScript加载器
│   │   │   │   └── ArkJsLoader.ets  # Ark JS加载器
│   │   │   └── py/                  # Python加载器
│   │   │       └── ArkPyLoader.ets  # Ark Python加载器
│   │   ├── adapter/                 # Fongmi配置适配器
│   │   │   └── ConfigAdapter.ets    # 配置适配器
│   │   └── SpiderService.ets        # 爬虫服务
│   ├── config/                      # 配置服务
│   │   ├── ConfigLoader.ets         # 配置加载器
│   │   ├── ConfigParser.ets         # 配置解析器
│   │   └── ConfigService.ets        # 配置服务
│   ├── security/                    # 安全服务
│   │   └── SecurityService.ets      # 安全服务
│   ├── voice/                       # 语音助手服务
│   │   └── VoiceAssistantService.ets # 语音助手服务
│   ├── flow/                        # 设备流转服务
│   │   └── DeviceFlowService.ets    # 设备流转服务
│   └── gesture/                     # 手势操作服务
│       └── GestureService.ets       # 手势操作服务
├── task/                            # 任务调度
│   ├── scheduler/                   # WorkScheduler管理
│   │   └── TaskScheduler.ets        # 任务调度器
│   └── pool/                        # TaskPool优化
│       └── TaskPoolManager.ets      # TaskPool管理器
├── resources/                       # 资源文件
└── etsconfig.json                   # ArkTS配置
```

## 3. 核心模块实现计划

### 3.1 数据层实现

#### 3.1.1 数据模型 (data/bean/)

数据模型层定义了应用中所有核心数据结构，采用TypeScript接口形式实现，支持@Observed装饰器以实现响应式更新。

- **Vod.ets**：点播内容数据模型
  包含影片ID、标题、封面、评分、简介、导演、演员、分类、年份、区域等基本信息。支持多集数、多来源数据结构，以及播放记录关联。

- **Live.ets**：直播内容数据模型
  包含频道ID、名称、封面、分组信息、观看次数等。支持多源直播流配置，以及节目单数据结构。

- **Site.ets**：站点数据模型
  定义爬虫站点的基本信息，包括ID、名称、类型（JAR/JS/PY）、图标、配置地址、状态等。支持站点版本控制和更新机制。

- **History.ets**：历史记录数据模型
  记录用户观看历史，包含内容ID、类型、标题、观看进度、最后观看时间、封面等信息。支持按时间排序和内容类型分类。

- **Config.ets**：配置信息数据模型
  管理应用全局配置，包括界面设置、播放设置、网络设置、安全设置等分类配置。支持配置版本管理和默认值设置。

- **DeviceInfo.ets**：设备信息数据模型
  定义设备基本信息和能力描述，用于设备流转功能，包含设备ID、名称、类型、支持的功能列表等。

1. **Vod.ets** - 点播内容模型
   ```typescript
   export interface Vod {
     id: string;          // 内容唯一ID
     name: string;        // 内容名称
     type: string;        // 类型（电影、电视剧等）
     area: string;        // 地区
     lang: string;        // 语言
     year: string;        // 年份
     score: string;       // 评分
     status: string;      // 状态（连载中、已完结）
     desc: string;        // 简介
     cover: string;       // 封面图URL
     tag: string;         // 标签
     url: string;         // 内容详情页URL
     sourceKey: string;   // 数据源标识
     episodeList?: Episode[]; // 剧集列表
     selectedEpisode?: number; // 当前选中剧集
     createdAt: number;   // 创建时间
     updatedAt: number;   // 更新时间
   }
   
   export interface Episode {
     name: string;        // 剧集名称
     url: string;         // 剧集播放页URL
     sourceList?: VideoSource[]; // 视频源列表
   }
   
   export interface VideoSource {
     name: string;        // 视频源名称
     url: string;         // 视频源URL
     headers?: Map<string, string>; // 请求头
   }
   ```

2. **Live.ets** - 直播内容模型
   ```typescript
   export interface Live {
     id: string;          // 频道唯一ID
     name: string;        // 频道名称
     logo: string;        // 频道Logo URL
     url: string;         // 直播流URL
     group: string;       // 频道分组
     type: string;        // 直播类型
     headers?: Map<string, string>; // 请求头
     sourceKey: string;   // 数据源标识
     createdAt: number;   // 创建时间
   }
   
   export interface LiveGroup {
     name: string;        // 分组名称
     channels: Live[];    // 该分组下的频道列表
   }
   ```

3. **Site.ets** - 站点模型
   ```typescript
   export interface Site {
     key: string;         // 站点唯一标识
     name: string;        // 站点名称
     type: string;        // 站点类型（vod/live）
     api: string;         // 站点API地址
     searchable: boolean; // 是否支持搜索
     filterable: boolean; // 是否支持筛选
     headers?: Map<string, string>; // 站点请求头
     cookie?: string;     // 站点Cookie
     ext?: Record<string, any>; // 扩展信息
     enabled: boolean;    // 是否启用
     order: number;       // 排序
     createdAt: number;   // 创建时间
     updatedAt: number;   // 更新时间
   }
   ```

4. **History.ets** - 历史记录模型
   ```typescript
   export interface History {
     id: string;          // 历史记录ID
     contentId: string;   // 内容ID
     contentName: string; // 内容名称
     type: string;        // 内容类型（vod/live）
     cover: string;       // 封面URL
     episodeName?: string;// 剧集名称
     sourceKey: string;   // 数据源标识
     position: number;    // 播放位置（毫秒）
     duration: number;    // 总时长（毫秒）
     lastPlayedAt: number;// 最后播放时间
     createdAt: number;   // 创建时间
   }
   ```

5. **Config.ets** - 配置信息模型
   ```typescript
   export interface AppConfig {
     player: PlayerConfig;        // 播放器配置
     display: DisplayConfig;      // 显示配置
     network: NetworkConfig;      // 网络配置
     security: SecurityConfig;    // 安全配置
     adBlock: AdBlockConfig;      // 广告屏蔽配置
     harmony: HarmonyConfig;      // 鸿蒙特有配置
   }
   
   export interface PlayerConfig {
     defaultPlayer: string;       // 默认播放器
     enableHardwareDecode: boolean; // 启用硬件解码
     autoContinuePlay: boolean;   // 自动续播
     rememberPosition: boolean;   // 记住播放位置
     speedList: number[];         // 播放速度列表
   }
   
   export interface DisplayConfig {
     theme: string;               // 主题
     fontSize: number;            // 字体大小
     autoFullScreen: boolean;     // 自动全屏
     enableGestures: boolean;     // 启用手势
   }
   
   export interface NetworkConfig {
     timeout: number;             // 超时时间（秒）
     retryCount: number;          // 重试次数
     enableCache: boolean;        // 启用缓存
     cacheSize: number;           // 缓存大小（MB）
   }
   
   export interface SecurityConfig {
     enableSandbox: boolean;      // 启用沙箱
     allowThirdParty: boolean;    // 允许第三方JAR加载
   }
   
   export interface AdBlockConfig {
     enabled: boolean;            // 启用广告屏蔽
     rules: string[];             // 屏蔽规则
     updateInterval: number;      // 更新间隔（小时）
   }
   
   export interface HarmonyConfig {
     enableVoiceAssistant: boolean; // 启用语音助手
     enableDeviceFlow: boolean;    // 启用设备流转
     enableGestureControl: boolean; // 启用手势控制
   }
   ```

6. **DeviceInfo.ets** - 设备信息模型
   ```typescript
   export interface DeviceInfo {
     deviceId: string;           // 设备唯一标识
     deviceName: string;         // 设备名称
     deviceType: string;         // 设备类型（phone/tablet/tv）
     osVersion: string;          // 系统版本
     appVersion: string;         // 应用版本
     screenWidth: number;        // 屏幕宽度
     screenHeight: number;       // 屏幕高度
     isTvMode: boolean;          // 是否为TV模式
     isRemoteControlAvailable: boolean; // 是否可用遥控器
   }
   ```

#### 3.1.2 数据库实现 (data/db/)

数据库层基于HarmonyOS的RelationalStore实现，提供本地数据持久化和高效的数据访问。采用单例模式管理数据库连接，支持异步事务和数据同步。

- **TableSchema.ets**：定义数据库表结构
  包含四个核心表：站点表(site)、历史记录表(history)、收藏表(keep)和配置表(config)。每个表都有完整的字段定义、SQL创建语句和列名常量映射。站点表存储爬虫源配置，历史记录表保存用户观看记录，收藏表管理用户收藏内容，配置表存储应用全局设置。

- **DatabaseManager.ets**：数据库管理器
  实现单例模式，负责数据库的初始化、表创建和连接管理。提供异步初始化方法，支持数据库关闭和SQL执行功能。使用RelationalStore的RdbStore接口进行数据库操作，确保线程安全。

2. **DatabaseManager.ets** - 数据库管理器
   ```typescript
   import relationalStore from '@ohos.data.relationalStore';
   import { getAllTables } from './TableSchema';
   import Logger from '../../common/util/Logger';
   
   const TAG = 'DatabaseManager';
   const DB_NAME = 'raytv.db';
   const DB_VERSION = 1;
   
   export class DatabaseManager {
     private static instance: DatabaseManager;
     private database: relationalStore.RdbStore | null = null;
     
     private constructor() {}
     
     // 获取单例实例
     public static getInstance(): DatabaseManager {
       if (!DatabaseManager.instance) {
         DatabaseManager.instance = new DatabaseManager();
       }
       return DatabaseManager.instance;
     }
     
     // 初始化数据库
     public async initDatabase(context: Context): Promise<void> {
       try {
         const config: relationalStore.StoreConfig = {
           name: DB_NAME,
           securityLevel: relationalStore.SecurityLevel.S1
         };
         
         this.database = await relationalStore.getRdbStore(context, config);
         await this.createTables();
         Logger.info(TAG, 'Database initialized successfully');
       } catch (error) {
         Logger.error(TAG, `Failed to initialize database: ${error}`);
         throw error;
       }
     }
     
     // 创建表
     private async createTables(): Promise<void> {
       if (!this.database) return;
       
       const tables = getAllTables();
       for (const sql of tables) {
         await this.database.executeSql(sql);
       }
     }
     
     // 获取数据库实例
     public getDatabase(): relationalStore.RdbStore {
       if (!this.database) {
         throw new Error('Database not initialized');
       }
       return this.database;
     }
     
     // 执行SQL查询
     public async executeSql(sql: string, bindArgs?: Array<ValueType>): Promise<void> {
       if (!this.database) {
         throw new Error('Database not initialized');
       }
       await this.database.executeSql(sql, bindArgs);
     }
     
     // 关闭数据库
     public closeDatabase(): void {
       if (this.database) {
         this.database = null;
         Logger.info(TAG, 'Database closed');
       }
     }
   }
   ```

3. **SiteDao.ets** - 站点数据访问对象
   ```typescript
   import relationalStore from '@ohos.data.relationalStore';
   import { DatabaseManager } from '../DatabaseManager';
   import { SITE_TABLE } from '../TableSchema';
   import { Site } from '../../bean/Site';
   import Logger from '../../../common/util/Logger';
   import JsonUtil from '../../../common/util/JsonUtil';
   
   const TAG = 'SiteDao';
   
   export class SiteDao {
     private db: relationalStore.RdbStore;
     
     constructor() {
       this.db = DatabaseManager.getInstance().getDatabase();
     }
     
     // 插入站点
     public async insert(site: Site): Promise<void> {
       try {
         const valuesBucket: relationalStore.ValuesBucket = {
           [SITE_TABLE.COLUMNS.KEY]: site.key,
           [SITE_TABLE.COLUMNS.NAME]: site.name,
           [SITE_TABLE.COLUMNS.TYPE]: site.type,
           [SITE_TABLE.COLUMNS.API]: site.api,
           [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
           [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
           [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries())) : null,
           [SITE_TABLE.COLUMNS.COOKIE]: site.cookie || null,
           [SITE_TABLE.COLUMNS.EXT]: site.ext ? JsonUtil.stringify(site.ext) : null,
           [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
           [SITE_TABLE.COLUMNS.ORDER]: site.order,
           [SITE_TABLE.COLUMNS.CREATED_AT]: site.createdAt,
           [SITE_TABLE.COLUMNS.UPDATED_AT]: site.updatedAt
         };
         
         await this.db.insert(SITE_TABLE.TABLE_NAME, valuesBucket);
       } catch (error) {
         Logger.error(TAG, `Failed to insert site: ${error}`);
         throw error;
       }
     }
     
     // 更新站点
     public async update(site: Site): Promise<void> {
       try {
         const valuesBucket: relationalStore.ValuesBucket = {
           [SITE_TABLE.COLUMNS.NAME]: site.name,
           [SITE_TABLE.COLUMNS.API]: site.api,
           [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
           [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
           [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries())) : null,
           [SITE_TABLE.COLUMNS.COOKIE]: site.cookie || null,
           [SITE_TABLE.COLUMNS.EXT]: site.ext ? JsonUtil.stringify(site.ext) : null,
           [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
           [SITE_TABLE.COLUMNS.ORDER]: site.order,
           [SITE_TABLE.COLUMNS.UPDATED_AT]: site.updatedAt
         };
         
         const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
         predicates.equalTo(SITE_TABLE.COLUMNS.KEY, site.key);
         
         await this.db.update(valuesBucket, predicates);
       } catch (error) {
         Logger.error(TAG, `Failed to update site: ${error}`);
         throw error;
       }
     }
     
     // 删除站点
     public async delete(key: string): Promise<void> {
       try {
         const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
         predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
         
         await this.db.delete(predicates);
       } catch (error) {
         Logger.error(TAG, `Failed to delete site: ${error}`);
         throw error;
       }
     }
     
     // 获取所有站点
     public async getAll(): Promise<Site[]> {
       try {
         const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
         predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
         
         const resultSet = await this.db.query(predicates);
         return this.parseResultSet(resultSet);
       } catch (error) {
         Logger.error(TAG, `Failed to get all sites: ${error}`);
         throw error;
       }
     }
     
     // 获取启用的站点
     public async getEnabled(): Promise<Site[]> {
       try {
         const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
         predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
         predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
         
         const resultSet = await this.db.query(predicates);
         return this.parseResultSet(resultSet);
       } catch (error) {
         Logger.error(TAG, `Failed to get enabled sites: ${error}`);
         throw error;
       }
     }
     
     // 获取指定类型的站点
     public async getByType(type: string): Promise<Site[]> {
       try {
         const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
         predicates.equalTo(SITE_TABLE.COLUMNS.TYPE, type);
         predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
         predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
         
         const resultSet = await this.db.query(predicates);
         return this.parseResultSet(resultSet);
       } catch (error) {
         Logger.error(TAG, `Failed to get sites by type: ${error}`);
         throw error;
       }
     }
     
     // 解析结果集
     private parseResultSet(resultSet: relationalStore.ResultSet): Site[] {
       const sites: Site[] = [];
       
       if (resultSet.rowCount > 0) {
         resultSet.goToFirstRow();
         do {
           const headersStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.HEADERS));
           const headers = headersStr ? new Map(JSON.parse(headersStr)) : undefined;
           
           const extStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.EXT));
           const ext = extStr ? JSON.parse(extStr) : undefined;
           
           sites.push({
             key: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.KEY)),
             name: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.NAME)),
             type: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TYPE)),
             api: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.API)),
             searchable: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SEARCHABLE)) === 1,
             filterable: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.FILTERABLE)) === 1,
             headers,
             cookie: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.COOKIE)),
             ext,
             enabled: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENABLED)) === 1,
             order: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ORDER)),
             createdAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CREATED_AT)),
             updatedAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.UPDATED_AT))
           });
         } while (resultSet.goToNextRow());
       }
       
       resultSet.close();
       return sites;
     }
   }
   ```

4. **HistoryDao.ets** - 历史记录数据访问对象
   ```typescript
   import relationalStore from '@ohos.data.relationalStore';
   import { DatabaseManager } from '../DatabaseManager';
   import { HISTORY_TABLE } from '../TableSchema';
   import { History } from '../../bean/History';
   import Logger from '../../../common/util/Logger';
   
   const TAG = 'HistoryDao';
   
   export class HistoryDao {
     private db: relationalStore.RdbStore;
     
     constructor() {
       this.db = DatabaseManager.getInstance().getDatabase();
     }
     
     // 插入或更新历史记录
     public async saveOrUpdate(history: History): Promise<void> {
       try {
         // 检查是否已存在
         const existing = await this.getByContentId(history.contentId, history.sourceKey);
         
         const valuesBucket: relationalStore.ValuesBucket = {
           [HISTORY_TABLE.COLUMNS.CONTENT_ID]: history.contentId,
           [HISTORY_TABLE.COLUMNS.CONTENT_NAME]: history.contentName,
           [HISTORY_TABLE.COLUMNS.TYPE]: history.type,
           [HISTORY_TABLE.COLUMNS.COVER]: history.cover || null,
           [HISTORY_TABLE.COLUMNS.EPISODE_NAME]: history.episodeName || null,
           [HISTORY_TABLE.COLUMNS.SOURCE_KEY]: history.sourceKey,
           [HISTORY_TABLE.COLUMNS.POSITION]: history.position,
           [HISTORY_TABLE.COLUMNS.DURATION]: history.duration,
           [HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT]: history.lastPlayedAt,
           [HISTORY_TABLE.COLUMNS.CREATED_AT]: history.createdAt
         };
         
         if (existing) {
           // 更新
           valuesBucket[HISTORY_TABLE.COLUMNS.ID] = existing.id;
           const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
           predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, existing.id);
           await this.db.update(valuesBucket, predicates);
         } else {
           // 插入
           valuesBucket[HISTORY_TABLE.COLUMNS.ID] = history.id;
           await this.db.insert(HISTORY_TABLE.TABLE_NAME, valuesBucket);
         }
       } catch (error) {
         Logger.error(TAG, `Failed to save or update history: ${error}`);
         throw error;
       }
     }
     
     // 获取历史记录列表
     public async getAll(limit: number = 50): Promise<History[]> {
       try {
         const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
         predicates.orderByDesc(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT);
         predicates.limit(limit);
         
         const resultSet = await this.db.query(predicates);
         return this.parseResultSet(resultSet);
       } catch (error) {
         Logger.error(TAG, `Failed to get all history: ${error}`);
         throw error;
       }
     }
     
     // 根据内容ID和来源获取历史记录
     public async getByContentId(contentId: string, sourceKey: string): Promise<History | null> {
       try {
         const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
         predicates.equalTo(HISTORY_TABLE.COLUMNS.CONTENT_ID, contentId);
         predicates.equalTo(HISTORY_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
         
         const resultSet = await this.db.query(predicates);
         const histories = this.parseResultSet(resultSet);
         return histories.length > 0 ? histories[0] : null;
       } catch (error) {
         Logger.error(TAG, `Failed to get history by contentId: ${error}`);
         throw error;
       }
     }
     
     // 删除历史记录
     public async delete(id: string): Promise<void> {
       try {
         const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
         predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, id);
         await this.db.delete(predicates);
       } catch (error) {
         Logger.error(TAG, `Failed to delete history: ${error}`);
         throw error;
       }
     }
     
     // 清空所有历史记录
     public async clearAll(): Promise<void> {
       try {
         const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
         await this.db.delete(predicates);
       } catch (error) {
         Logger.error(TAG, `Failed to clear all history: ${error}`);
         throw error;
       }
     }
     
     // 解析结果集
     private parseResultSet(resultSet: relationalStore.ResultSet): History[] {
       const histories: History[] = [];
       
       if (resultSet.rowCount > 0) {
         resultSet.goToFirstRow();
         do {
           histories.push({
             id: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.ID)),
             contentId: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CONTENT_ID)),
             contentName: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CONTENT_NAME)),
             type: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.TYPE)),
             cover: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.COVER)),
             episodeName: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.EPISODE_NAME)),
             sourceKey: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.SOURCE_KEY)),
             position: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.POSITION)),
             duration: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.DURATION)),
             lastPlayedAt: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT)),
             createdAt: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CREATED_AT))
           });
         } while (resultSet.goToNextRow());
       }
       
       resultSet.close();
       return histories;
     }
   }
   ```

### 3.2 配置服务实现 (service/config/)

**配置服务概述**：负责应用配置的加载、解析、验证和管理，支持从网络URL和本地文件导入配置，并提供站点配置的CRUD操作。

1. **ConfigLoader.ets** - 配置加载器
   提供多源配置加载能力，支持从HTTP/HTTPS URL和本地文件系统加载配置。实现了多种格式配置的解析，包括纯JSON格式和JavaScript格式（var config = {...}）。具备配置保存功能，可将站点配置导出为标准JSON格式文件。采用单例模式确保全局配置加载的一致性。

2. **ConfigParser.ets** - 配置解析器
   负责解析和验证站点配置信息，支持Fongmi格式配置的转换。实现站点类型自动识别（直播/点播）、请求头转换、扩展信息提取等功能。提供站点配置验证机制，确保API URL有效性和必要字段完整性，保障配置质量。

3. **ConfigService.ets** - 配置服务
   作为配置管理的核心服务，整合配置加载器和数据库访问层。提供配置导入功能，支持URL和本地文件两种导入方式，自动验证并保存有效站点。实现站点的增删改查操作，包括启用/禁用站点、调整站点顺序、批量操作等管理功能。采用单例模式设计，确保配置服务的全局一致性。
             validSites.push(site);
           } else {
             Logger.warn(TAG, `Invalid site config: ${site.name}`);
           }
         }
         
         Logger.info(TAG, `Successfully imported ${validSites.length} sites`);
         return validSites;
       } catch (error) {
         Logger.error(TAG, `Failed to import config: ${error}`);
         throw error;
       }
     }
     
     // 获取所有站点
     public async getAllSites(): Promise<Site[]> {
       try {
         return await this.siteDao.getAll();
       } catch (error) {
         Logger.error(TAG, `Failed to get all sites: ${error}`);
         throw error;
       }
     }
     
     // 获取启用的站点
     public async getEnabledSites(): Promise<Site[]> {
       try {
         return await this.siteDao.getEnabled();
       } catch (error) {
         Logger.error(TAG, `Failed to get enabled sites: ${error}`);
         throw error;
       }
     }
     
     // 获取指定类型的站点
     public async getSitesByType(type: string): Promise<Site[]> {
       try {
         return await this.siteDao.getByType(type);
       } catch (error) {
         Logger.error(TAG, `Failed to get sites by type: ${error}`);
         throw error;
       }
     }
     
     // 更新站点
     public async updateSite(site: Site): Promise<void> {
       try {
         if (!this.configParser.validateSite(site)) {
           throw new Error('Invalid site configuration');
         }
         
         site.updatedAt = Date.now();
         await this.siteDao.update(site);
         Logger.info(TAG, `Updated site: ${site.name}`);
       } catch (error) {
         Logger.error(TAG, `Failed to update site: ${error}`);
         throw error;
       }
     }
     
     // 删除站点
     public async deleteSite(key: string): Promise<void> {
       try {
         await this.siteDao.delete(key);
         Logger.info(TAG, `Deleted site: ${key}`);
       } catch (error) {
         Logger.error(TAG, `Failed to delete site: ${error}`);
         throw error;
       }
     }
     
     // 导出配置
     public async exportConfig(filePath: string): Promise<void> {
       try {
         const sites = await this.siteDao.getAll();
         await this.configLoader.saveConfigToFile(sites, filePath);
         Logger.info(TAG, `Config exported to: ${filePath}`);
       } catch (error) {
         Logger.error(TAG, `Failed to export config: ${error}`);
         throw error;
       }
     }
   }
   ```

### 3.3 爬虫服务实现 (service/spider/)

**爬虫服务概述**：提供内容源的解析和数据获取能力，支持多种加载器类型，实现站点数据的抓取、解析和转换。

#### 3.3.1 基础加载器 (service/spider/loader/)

1. **BaseLoader.ets** - 爬虫加载基类
   定义爬虫加载器的核心接口和抽象基类，规范加载器的初始化、方法调用和资源释放流程。提供统一的错误处理、日志记录和方法验证机制。通过抽象方法（onInit、onInvoke、onDestroy）允许子类实现特定的加载逻辑，支持标准爬虫方法（home、category、detail、search、play、live）的验证。

2. **ArkJarLoader.ets** - Ark JAR加载器
   实现基于HarmonyOS ArkNative能力的JAR文件加载器。核心功能包括：
   - 安全沙箱管理：为每个站点创建独立的安全沙箱环境，隔离不同站点的执行上下文
   - JAR资源管理：支持从远程URL下载JAR文件，并在沙箱中安全存储
   - 异步方法调用：通过TaskPoolManager在后台线程执行JAR方法，避免阻塞UI线程
   - 生命周期管理：提供完整的初始化、执行和销毁流程，确保资源正确释放
   - 异常处理：完善的错误捕获和日志记录机制，确保系统稳定性
   - 类型转换：处理JavaScript与Java类型之间的自动转换，简化接口调用

3. **ArkJsLoader.ets** - Ark JavaScript加载器
   实现基于HarmonyOS的JavaScript代码加载和执行器。核心功能包括：
   - 多源代码加载：支持从URL、本地文件或直接代码字符串加载JavaScript
   - 安全沙箱隔离：为每个JavaScript环境创建独立沙箱，确保执行安全
   - 安全过滤机制：内置危险代码检测和过滤，防止恶意代码执行
   - 标准API注入：提供http、crypto、regexp等基础API，满足爬虫开发需求
   - 上下文管理：创建和维护JavaScript执行上下文，确保方法正确调用
   - 资源清理：在加载器销毁时彻底清理执行环境和沙箱资源
   - 安全执行保障：使用安全的代码执行机制，避免eval等危险操作的安全风险

4. **ArkPyLoader.ets** - Ark Python加载器
     实现基于HarmonyOS的Python代码加载和执行器。核心功能包括：
     - 安全沙箱环境：为Python代码执行创建独立的安全沙箱
     - 多源Python代码加载：支持从URL或直接代码字符串加载
     - 异步任务执行：通过TaskPoolManager在后台线程安全执行Python代码
     - 类型转换机制：自动处理JavaScript与Python之间的数据类型转换
     - 完整生命周期管理：提供初始化、执行和资源清理的完整流程
     - 错误处理与日志记录：完善的异常捕获和日志系统，确保系统稳定性
     - 安全执行保障：严格的代码执行控制，防止恶意操作

## 5. 爬虫管理服务实现

爬虫管理服务负责统一管理各类爬虫加载器，提供站点注册、爬虫调用、缓存管理和性能监控等核心功能。主要组件包括：

1. **SiteManager** - 站点管理器
   - 负责站点信息的注册、更新、删除和查询
   - 维护站点与加载器的映射关系
   - 提供站点状态监控和错误统计

2. **LoaderFactory** - 加载器工厂
   - 根据站点配置创建对应的爬虫加载器
   - 管理加载器的实例化和缓存
   - 支持动态扩展新的加载器类型

3. **CrawlerService** - 爬虫服务核心
   - 统一的爬虫方法调用入口
   - 实现请求转发和结果处理
   - 提供请求限流和重试机制

4. **CacheManager** - 缓存管理器
   - 实现爬虫结果的本地缓存
   - 支持缓存过期策略和清理机制
   - 减少重复请求，提升性能

5. **MonitorService** - 监控服务
   - 收集爬虫执行性能指标
   - 记录错误日志和异常信息
   - 提供健康检查和报警机制

## 6. 网络请求模块实现

网络请求模块提供统一的HTTP/HTTPS请求接口，支持请求配置、响应处理、缓存管理和安全验证等功能。主要组件包括：

1. **HttpService** - HTTP服务核心
   - 提供GET、POST等基础请求方法
   - 支持请求参数配置（超时、重试、代理等）
   - 实现请求拦截和响应拦截机制

2. **RequestConfig** - 请求配置管理
   - 集中管理全局请求配置
   - 支持站点特定配置覆盖
   - 提供配置验证和默认值设置

3. **ResponseProcessor** - 响应处理器
   - 支持多种响应格式解析（JSON、HTML、文本等）
   - 实现统一的错误处理机制
   - 提供响应数据转换和提取功能

4. **NetworkCache** - 网络缓存管理
   - 实现基于时间的缓存策略
   - 支持缓存优先级和容量控制
   - 提供缓存预热和清理机制

5. **SecurityManager** - 安全管理器
   - 实现SSL证书验证和忽略选项
    - 提供请求签名和加密支持
    - 实现防止重放攻击的机制

## 7. 数据解析模块实现

数据解析模块负责从网络响应中提取和转换结构化数据，支持多种解析方式和数据格式。主要组件包括：

1. **ParserFactory** - 解析器工厂
   - 根据数据类型创建对应的解析器
   - 支持自定义解析器注册
   - 提供解析器缓存机制

2. **JsonParser** - JSON解析器
   - 实现JSON数据的解析和验证
   - 支持路径表达式提取数据
   - 提供错误处理和默认值支持

3. **HtmlParser** - HTML解析器
   - 基于CSS选择器提取数据
   - 支持XPath表达式查询
   - 提供HTML清理和规范化功能

4. **RegexParser** - 正则表达式解析器
   - 基于正则表达式提取数据
   - 支持多匹配结果处理
   - 提供预编译正则表达式优化

5. **DataTransformer** - 数据转换器
   - 实现数据格式的转换
   - 支持字段映射和重命名
   - 提供数据类型转换和验证

## 8. 媒体播放模块实现

媒体播放模块负责处理视频和音频资源的加载、解码和播放功能，支持多种播放协议和格式。主要组件包括：

1. **PlayerEngine** - 播放引擎
   - 基于HarmonyOS媒体框架实现
   - 支持本地和网络媒体资源播放
   - 提供播放控制（播放、暂停、跳转等）

2. **MediaSourceManager** - 媒体源管理
   - 处理媒体URL解析和预处理
   - 支持多种播放协议（HTTP、HLS、DASH等）
   - 提供媒体信息提取和缓存管理

3. **PlaybackController** - 播放控制器
   - 实现播放状态管理
   - 处理播放事件和回调
   - 提供播放统计和日志记录

4. **SubtitleManager** - 字幕管理器
   - 支持多种字幕格式解析
   - 实现字幕同步和显示
   - 提供字幕样式定制

5. **CodecManager** - 编解码器管理
   - 处理媒体格式的编解码
   - 支持硬件加速
   - 提供编解码器兼容性检查

## 9. 用户界面模块实现

用户界面模块基于HarmonyOS ArkUI框架实现，提供直观、流畅的用户交互体验。主要组件包括：

1. **HomePage** - 首页界面
   - 展示站点列表和推荐内容
   - 提供快速搜索入口
   - 支持个性化推荐

2. **CategoryPage** - 分类界面
   - 展示媒体分类信息
   - 支持分类筛选和排序
   - 提供分页加载和记忆位置

3. **DetailPage** - 详情界面
   - 展示媒体详细信息
   - 提供剧集/章节列表
   - 支持收藏和分享功能

4. **SearchPage** - 搜索界面
   - 提供关键词搜索功能
   - 支持搜索历史和热门搜索
   - 实现实时搜索建议

5. **SettingsPage** - 设置界面
   - 提供应用配置选项
   - 支持站点管理功能
   - 实现缓存清理和数据统计

## 10. 数据存储模块实现

数据存储模块负责应用数据的持久化和管理，支持多种存储方式和数据类型。主要组件包括：

1. **DatabaseManager** - 数据库管理器
   - 基于SQLite实现本地数据存储
   - 提供数据模型定义和迁移管理
   - 支持事务处理和并发控制

2. **SharedPreferences** - 偏好设置管理
   - 存储用户配置和应用状态
   - 支持多种数据类型的存取
   - 提供默认值和类型转换

3. **FileStorage** - 文件存储管理
   - 处理本地文件的读写操作
   - 支持文件压缩和加密
   - 提供文件清理和空间管理

4. **CacheStorage** - 缓存存储管理
   - 管理临时数据缓存
   - 实现LRU缓存策略
   - 支持缓存大小限制和自动清理

5. **DataMigration** - 数据迁移工具
   - 处理版本升级时的数据迁移
   - 提供数据备份和恢复功能
   - 支持数据导入和导出

## 11. 安全模块实现

安全模块负责保护应用数据和用户隐私，实现各种安全机制和防护措施。主要组件包括：

1. **SandboxUtil** - 沙箱工具
   - 创建隔离的执行环境
   - 限制代码执行权限
   - 防止恶意代码攻击

2. **EncryptionService** - 加密服务
   - 提供数据加密和解密功能
   - 支持多种加密算法
   - 管理加密密钥安全

3. **PermissionManager** - 权限管理器
   - 处理应用权限请求
   - 验证代码执行权限
   - 实现最小权限原则

4. **AntiMalware** - 反恶意软件
   - 检测危险代码模式
   - 阻止不安全操作
   - 提供安全审计日志

5. **PrivacyProtection** - 隐私保护
   - 处理敏感数据保护
   - 实现数据脱敏机制
   - 提供隐私合规配置

## 12. 工具模块实现

工具模块提供各种通用功能和辅助方法，为其他模块提供基础支持。主要组件包括：

1. **Logger** - 日志工具
   - 实现分级日志系统
   - 支持日志格式化和过滤
   - 提供日志文件存储和清理

2. **FileUtil** - 文件工具
   - 封装文件操作方法
   - 支持文件读写和复制
   - 提供文件信息获取和验证

3. **StringUtils** - 字符串工具
   - 提供字符串处理方法
   - 支持正则表达式操作
   - 实现字符串转换和验证

4. **JsonUtil** - JSON工具
   - 处理JSON数据转换
   - 提供JSON解析和生成
   - 支持JSON路径查询

5. **TaskPoolManager** - 任务池管理
   - 管理后台任务执行
   - 提供任务优先级和取消
   - 支持并发控制和资源限制

## 13. 构建与部署

### 13.1 开发环境配置
- HarmonyOS SDK 5.0+ 或更高版本
- DevEco Studio 5.0+ 开发工具
- Node.js 18.x 或更高版本
- TypeScript 5.0+ 开发环境

### 13.2 构建流程
1. **依赖安装**：执行 `npm install` 安装项目依赖
2. **代码编译**：使用 `npx tsc` 编译TypeScript代码
3. **资源打包**：执行 `npx ohos-package` 打包应用资源
4. **签名配置**：配置应用签名信息
5. **构建HAP**：执行 `npx ohos-build --mode release` 构建发布版本

### 13.3 调试模式
- 使用DevEco Studio的模拟器或真机调试功能
- 支持远程调试和热重载
- 提供性能分析和内存监控工具

### 13.4 发布部署
- 生成发布版本HAP包
- 配置应用权限声明
- 准备应用商店发布材料
- 遵循HarmonyOS应用发布规范

## 14. 总结与展望

### 14.1 项目总结
RayTV是一个基于HarmonyOS平台的高性能、安全可靠的电视直播和点播应用。本项目实现了完整的多媒体应用架构，包括：
- 模块化的架构设计，确保代码的可维护性和可扩展性
- 多语言爬虫支持，实现丰富的内容源接入
- 高性能的网络请求和数据解析机制
- 安全的沙箱执行环境，保护用户数据和设备安全
- 流畅的用户界面和播放体验

### 14.2 技术亮点
- **多语言支持**：同时支持JavaScript、Python等多种脚本语言的爬虫
- **安全沙箱**：实现了严格的代码隔离和权限控制机制
- **高性能设计**：通过缓存、异步处理和任务池优化应用性能
- **模块化架构**：采用清晰的模块划分和接口定义，便于功能扩展
- **HarmonyOS优化**：充分利用HarmonyOS的现代特性，提供原生级体验

### 14.3 未来展望
- **AI推荐功能**：引入机器学习算法，实现个性化内容推荐
- **跨端支持**：扩展到更多HarmonyOS设备类型
- **多账号系统**：支持用户账号和云同步功能
- **社区功能**：添加评论、收藏夹共享等社交元素
- **性能优化**：持续优化启动速度和内存占用
- **插件系统**：开发更灵活的插件扩展机制

## 15. 项目执行计划

### 15.1 项目阶段划分

#### 阶段一：准备与基础架构（4周）
1. **环境搭建与技术选型确认**
   - 配置HarmonyOS开发环境，安装必要的SDK和工具链
   - 确认ArkTS/TypeScript开发规范和代码风格指南
   - 搭建项目版本控制系统和CI/CD流程

2. **核心架构设计**
   - 制定详细的模块依赖关系图
   - 定义关键接口和数据流转流程
   - 设计统一的错误处理和日志系统
   - 建立安全机制和权限管理策略

3. **基础工具类开发**
   - 实现日志、网络、文件、JSON处理等通用工具
   - 开发数据库访问层和数据模型
   - 构建基础UI组件库

#### 阶段二：核心功能开发（8周）

1. **数据层实现**（2周）
   - 开发数据模型和实体类
   - 实现本地数据库和缓存机制
   - 构建远程数据源和API适配层
   - 开发数据解析器和格式化工具

2. **业务逻辑层实现**（2周）
   - 实现点播和直播内容的业务逻辑
   - 开发站点管理和爬虫服务
   - 构建配置管理和用户设置功能
   - 实现播放历史和收藏功能

3. **播放器服务实现**（2周）
   - 基于AVPlayer构建自定义播放器
   - 实现多格式视频源解析和播放
   - 开发播放控制和状态管理
   - 构建字幕支持和音视频同步机制

4. **UI层实现**（2周）
   - 开发主界面和导航系统
   - 实现搜索、详情、播放等核心页面
   - 构建设置界面和偏好配置
   - 实现响应式布局和设备适配

#### 阶段三：HarmonyOS特性集成

1. **分布式能力实现**
   - 集成设备管理和发现功能
   - 实现内容流转和跨设备播放
   - 开发分布式数据同步机制

2. **智能交互功能**
   - 集成小艺语音助手支持
   - 实现手势操作和遥控器适配
   - 开发快捷操作和全局搜索

3. **安全增强和优化**
   - 实现沙箱隔离和代码安全执行
   - 开发权限申请和用户隐私保护
   - 优化应用性能和资源使用

#### 阶段四：测试与优化

1. **性能优化和问题修复**
   - 优化应用启动速度和响应性能
   - 减少内存占用和资源消耗
   - 修复测试中发现的问题和缺陷

#### 阶段五：发布与运维

1. **应用打包和签名**
   - 准备应用发布配置
   - 进行应用签名和安全审查
   - 优化安装包大小

2. **文档完善和发布准备**
   - 编写用户手册和帮助文档
   - 准备应用发布材料
   - 制定版本发布计划



### 15.2 资源分配


#### 技术资源
- HarmonyOS SDK (API 19)
- ArkTS/TypeScript开发工具
- 测试设备（手机、平板、智能电视）
- 版本控制和协作平台
- 自动化测试工具



### 15.3 关键里程碑

1. **M1: 项目启动与架构设计完成**
   - 完成项目环境搭建
   - 确定技术架构和接口设计
   - 完成基础工具类开发

2. **M2: 核心功能实现完成**
   - 完成数据层和业务逻辑层实现
   - 实现播放器服务
   - 完成基础UI界面

3. **M3: HarmonyOS特性集成完成**
   - 完成分布式功能集成
   - 实现智能交互功能
   - 完成安全增强机制

4. **M5: 应用正式发布**
   - 应用通过审核并发布
   - 用户文档和支持渠道准备就绪
   - 监控系统正常运行

### 15.5 验收标准

#### 功能验收
- 所有核心功能（点播、直播、搜索、播放等）正常工作
- HarmonyOS特有功能（设备流转、语音控制等）按规格实现
- 支持所有目标设备类型和系统版本

#### 性能验收
- 应用启动时间不超过3秒（冷启动）
- 页面切换响应时间不超过1秒
- 播放流畅，无明显卡顿（网络良好情况下）
- 内存占用稳定，不出现内存泄漏

#### 质量验收
- 代码覆盖率达到80%以上
- 无严重和高优先级bug
- 通过所有安全测试和代码审查
- 符合HarmonyOS应用开发规范


