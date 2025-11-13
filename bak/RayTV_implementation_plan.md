# RayTV 鸿蒙OS应用移植技术执行计划

## 1. 项目概述

### 1.1 移植原则
本文档基于《RayTV - 鸿蒙OS应用移植规划文档》(RayTV_dev.md)制定，旨在提供一个详细的、可执行的技术实施路径，细化到最小的模块和关键变量。执行过程中严格遵循以下原则：
- Android版Fongmi仅作为需求实现的逻辑参考，不作为代码实现的参考
- 所有功能模块将完全基于HarmonyOS原生API和技术栈进行设计和实现
- 充分利用鸿蒙系统特性，确保应用在不同设备上的一致体验
- 遵循模块化、可扩展的设计理念

### 1.2 目标与范围
- 实现Android版RayTV功能的完整移植到HarmonyOS 5/6平台
- 支持多设备（手机、平板、电视）适配
- 集成鸿蒙特有功能：小艺语音助手、设备流转、手势操作
- 基于HarmonyOS SDK API 19开发

### 1.3 技术栈确认

#### 1.3.1 核心开发语言
- **ArkTS**：HarmonyOS原生开发语言，基于TypeScript并针对性能进行了优化和约束
- **TypeScript**：仅在ArkTS无法实现时使用

#### 1.3.2 关键框架与API
- **UI框架**：ArkUI (声明式UI)
- **媒体播放**：AVPlayer (HarmonyOS原生)
- **数据库**：RelationalStore (关系型数据库)
- **网络请求**：@ohos.net.http (API 19)
- **并发处理**：TaskPool (API 19)
- **安全沙箱**：@ohos.sandbox (API 19)
- **分布式能力**：@ohos.distributedHardware.deviceManager (API 19)
- **手势识别**：@ohos.multimodalInput.gesture (API 19)
## 1.4 ArkTS开发规范与约束

ArkTS的设计理念是在保持TypeScript开发体验的同时，通过静态类型和明确的装饰器来提升运行时性能。以下是ArkTS开发中的关键规范与约束：

### 1.4.1 静态类型要求
- 禁止使用any和unknown类型，所有变量必须显式指定具体类型
- 强制使用静态类型，ArkTS要求所有类型在编译时已知
- 禁止在运行时变更对象布局，不能向对象动态添加或删除属性
- 运算符的语义受到限制，例如一元运算符+只能作用于数值类型

### 1.4.2 类型系统调整
- 不支持structural typing（结构类型系统），需严格依赖接口或类定义对象结构
- 不支持Symbol() API
- 必须使用let而非var来声明变量
- 交叉类型（&）不支持，需改用extends实现类型扩展
- 不支持可选链操作符（?.）和空值合并操作符（??），需使用条件判断替代

### 1.4.3 类与接口规范
- 使用class而非具有call signature（调用签名）的类型
- 私有字段不支持以#开头的语法，应改用private关键字
- 接口中不支持构造签名
- 不支持类的实例化，所有类均需定义为静态类（static class），禁止使用new关键字创建实例
- protected全场景禁用，因ArkTS组件无继承机制

### 1.4.4 泛型与高级类型
- 调用泛型函数时，需要显式标注泛型类型实参
- 不支持TypeScript中的高级类型特性，如条件类型、this类型和索引访问类型

### 1.4.5 字面量与函数
- 对象字面量不能用于类型声明
- 数组字面量必须仅包含可推断类型的元素
- 推荐使用箭头函数而非函数表达式
- 禁止在函数内修改参数值

### 1.4.6 状态管理与装饰器规范
- **初始化要求**：@State装饰器标记的变量必须初始化，不能为空值
- **装饰器唯一性**：同一个变量不能被多个状态管理装饰器（如@State、@Link等）同时装饰
- **@Watch回调要求**：在struct内定义了@Watch装饰器装饰的变量后，必须定义对应名称的监听函数
- **@BuilderParam限制**：@BuilderParam装饰的变量只能被@Builder装饰的函数初始化
- **类型一致性**：装饰器变量的类型必须与初始化值的类型一致
- **private修饰符约束**：@State/@Prop等装饰变量用private修饰时，禁止在构造函数外赋值
- **存储类装饰器**：@StorageLink/@LocalStorageProp等变量使用public会触发编译警告
- **Link类装饰器**：@Link/@ObjectLink不可与private共用
- **状态更新建议**：对于复杂对象状态更新，推荐使用不可变数据模式，创建新对象而非修改原有对象

### 1.4.7 异步处理和事件监听
- **资源清理**：事件监听器需要正确移除，特别是在组件销毁时，否则可能导致内存泄漏
- **错误处理**：异步操作中的错误需要被有效捕获和处理，确保应用稳定性
- **异步流程**：优先使用async/await语法处理异步操作，提高代码可读性
- **Promise规范**：创建Promise时必须处理reject情况，避免未处理的Promise拒绝
- **异步状态**：异步操作期间应提供加载状态提示，提升用户体验

### 1.4.8 类型系统最佳实践
#### 1.4.8.1 替代any/unknown类型的方案
当需要替代any或unknown类型时，可根据具体情况选择以下更具体的类型：
- 使用具体的基础类型：boolean、number、string
- 使用Object或object类型：当值的类型不确定，但可以确定它是一个对象时
- 使用自定义类或接口：对于具有特定结构的复杂对象
- 处理特定场景：如try-catch语句中捕获错误时，可使用内置的Error类型
- 使用联合类型：对于可能有多种类型的值，使用联合类型（如string | number）

#### 1.4.8.2 类型安全保障
- 使用类型断言时要谨慎，确保断言的类型与实际类型兼容
- 为函数参数和返回值明确标注类型
- 使用Type Guard进行类型窄化，提高代码健壮性
- 对关键数据结构使用只读修饰符，防止意外修改

### 1.4.9 性能优化建议
- 避免频繁的状态更新，特别是在渲染循环中
- 使用@Builder和@BuilderParam实现组件复用
- 合理使用缓存机制，避免重复计算
- 大列表使用虚拟化渲染，减少内存占用
- 图片资源按需加载，避免一次性加载大量资源

### 1.4.10 代码质量与可维护性
- 遵循单一职责原则，每个类/函数只负责一个功能
- 使用清晰、描述性的命名，避免缩写和模糊命名
- 添加适当的注释，特别是复杂逻辑和业务规则
- 编写单元测试，确保代码质量和功能正确性
- 定期进行代码重构，保持代码结构清晰

### 1.4.11 配置文件格式规范
- **JSON/JSON5格式**：所有配置文件必须严格遵守JSON/JSON5语法规范，确保格式正确
- **字符串资源引用**：配置文件中的文本内容（如reason、description等）必须使用字符串资源引用格式（$string:resource_name）
- **权限配置**：requestPermissions中的reason字段必须引用字符串资源，不能直接使用文本
- **usedScene字段要求**：所有user_grant类型的权限（如DISTRIBUTED_DATASYNC、ACCESS_DISTRIBUTED_SERVICE等）必须添加usedScene字段，指定权限使用的场景
- **usedScene配置规范**：
  - abilities字段必须明确指定使用该权限的Ability名称
  - when字段必须设置为"inuse"，表示仅在应用使用中时才请求权限
- **definePermissions要求**：对于非SDK预定义的自定义权限，必须在module.json5的definePermissions部分进行明确定义
- **definePermissions配置规范**：
  - 必须包含name、grantMode、availableLevel、label和description字段
  - grantMode根据权限性质设置为"user_grant"或"system_grant"
  - availableLevel必须是以下枚举值之一："system_core"（系统核心）、"system_basic"（系统基础）或"normal"（普通）
  - 分布式相关权限建议使用"system_basic"级别
  - label和description必须使用字符串资源引用格式（$string:resource_name），不能直接使用文本内容
- **权限一致性原则**：
  - module.json5中requestPermissions声明的权限必须是SDK预定义权限或在definePermissions中定义的自定义权限
  - app.json5中MainAbility的permissions数组应包含所有模块需要的权限
  - 所有相关配置文件中的权限名称必须保持一致
- **资源引用完整性检查规范**：
  - **定义完整性**：所有配置文件中的资源引用（$string:、$media:、$color:等）必须在对应的资源文件中正确定义
  - **命名一致性**：资源引用名称必须与资源文件中的定义名称完全匹配，包括大小写
  - **权限字符串完整性**：definePermissions中的label和description引用必须在string.json中定义对应的字符串资源
  - **应用级资源**：AppScope/app.json5中引用的资源必须在AppScope/resources/base/element/string.json中定义
  - **模块级资源**：module.json5中引用的资源必须在raytv/src/main/resources/base/element/string.json中定义
  - **构建前验证**：在构建前必须验证所有资源引用的完整性，避免构建失败
  - **错误排查**：构建失败时优先检查资源引用是否正确定义，特别是权限相关的字符串资源
- **模块配置对齐**：确保module.json5和app.json5中的配置保持一致，特别是权限声明部分
- **版本兼容性**：配置文件中的API版本必须与项目使用的SDK版本兼容
- **JSON语法**：确保对象属性之间使用逗号分隔，避免语法错误

## 2. 详细项目结构（已更新为实际代码结构）

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
│   │   ├── Logger.ets               # 日志工具（单例模式实现，支持多级别日志、格式化输出、持久化存储和静态方法兼容）
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

### 2.1 项目架构与模块职责

#### 2.1.1 核心模块分层
- **表示层**：包括pages/（主页面）和presentation/（表现层组件），负责用户界面展示和交互
- **领域层**：domain/目录包含业务逻辑、用例和仓库接口，实现核心业务功能
- **数据层**：data/目录负责数据访问、存储和网络交互，包含仓库实现、数据模型和数据库操作
- **服务层**：service/目录提供各种功能服务，如配置、媒体、播放器等
- **通用层**：common/目录包含工具类、常量定义和通用组件

#### 2.1.2 主要模块职责说明
- **common/util/**：提供日志、网络、存储等基础工具类，支持应用各模块功能
- **data/bean/**：定义应用核心数据模型，包括配置、媒体内容、设备信息等
- **data/repository/**：实现数据访问逻辑，封装数据源操作细节
- **domain/usecase/**：实现具体业务用例，协调不同服务完成业务流程
- **service/**：提供各种功能服务，按功能模块组织（配置、媒体、爬虫等）
- **presentation/viewmodel/**：实现MVVM架构中的视图模型，连接视图和数据

### 2.2 实际结构与规划差异说明

1. **工具类目录**：实际项目中存在两个工具类目录（common/util/ 和 utils/），最终Logger工具已统一到common/util/Logger.ets中
2. **Repository层**：实际实现了更丰富的仓库类，包括认证、缓存、分类等多个仓库
3. **Service层**：服务分布在多个位置（data/service/、domain/service/、service/、services/）
4. **页面组织**：主要页面位于pages/目录，部分页面在presentation/page/
5. **数据库实现**：增加了SQLiteHelper.ets辅助类
6. **应用能力**：使用RaytvAbility.ets作为主应用能力，而非常规划的MainAbility.ets

### 2.3 避免重复开发的规划与规范

#### 2.3.1 代码组织与目录结构规范
- **工具类统一**：所有工具类必须放在`common/util/`目录下，移除`utils/`目录，避免功能重复
- **服务层统一**：所有服务类必须放在`service/`目录下，按功能模块子目录组织，移除`data/service/`和`services/`目录
- **命名规范**：遵循统一的命名规则，工具类使用`XXXUtil.ets`，服务类使用`XXXService.ets`，管理器类使用`XXXManager.ets`
- **职责划分**：明确每个模块的职责边界，避免功能重叠

#### 2.3.2 重复代码处理策略
- **功能重复类**：优先保留功能更完整、使用更广泛的实现，将其他实现的独特功能合并到保留版本中
- **代码复用机制**：建立统一的工具类和服务接口，强制使用单例模式避免重复实例化
- **依赖管理**：明确模块间依赖关系，避免循环依赖，提倡依赖注入模式

#### 2.3.3 开发流程规范
- **代码审查**：提交前必须进行代码审查，检查是否存在重复实现
- **文档同步**：代码结构变更必须同步更新实现计划文档
- **接口优先**：采用接口优先的开发方式，先定义接口再实现，确保一致性
- **统一规范**：团队成员必须严格遵守项目结构和命名规范，确保代码风格一致
- **版本控制**：使用分支管理功能开发，合并前进行冲突解决和功能验证

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

- **分类与筛选模型**：支持内容分类、标签、筛选条件等数据结构，便于内容发现和管理

#### 3.1.2 数据库实现 (data/db/)

数据库层基于HarmonyOS的RelationalStore实现，提供本地数据持久化和高效的数据访问。采用单例模式管理数据库连接，支持异步事务和数据同步。

- **TableSchema.ets**：定义数据库表结构
  包含四个核心表：站点表(site)、历史记录表(history)、收藏表(keep)和配置表(config)。每个表都有完整的字段定义、SQL创建语句和列名常量映射。

- **DatabaseManager.ets**：数据库管理器
  实现单例模式，负责数据库的初始化、表创建和连接管理。提供异步初始化方法，支持数据库关闭和SQL执行功能。

- **Dao层**：数据访问对象层
  - SiteDao.ets：站点数据访问对象，提供站点增删改查功能
  - HistoryDao.ets：历史记录数据访问对象，提供历史记录管理功能
  - ConfigDao.ets：配置数据访问对象，提供配置读写功能
  - KeepDao.ets：收藏数据访问对象，提供收藏管理功能

#### 3.1.3 Repository层 (data/repository/)

Repository层实现了数据访问逻辑，封装了数据源操作细节，为上层业务提供统一的数据访问接口。

- **AuthRepository.ets**：认证仓库，处理用户认证和授权相关操作
- **ConfigRepository.ets**：配置仓库，负责应用配置的读写和管理
- **HistoryRepository.ets**：历史记录仓库，管理用户观看历史
- **LiveRepository.ets**：直播内容仓库，提供直播内容获取和管理功能
- **SiteRepository.ets**：站点仓库，管理爬虫源配置和状态
- **VodRepository.ets**：点播内容仓库，提供点播内容获取和搜索功能
- **KeepRepository.ets**：收藏仓库，管理用户收藏内容

### 3.2 领域层实现

#### 3.2.1 业务用例 (domain/usecase/)

业务用例层实现了核心业务逻辑，协调不同服务完成业务流程，是连接表示层和数据层的桥梁。

- **认证用例**：处理用户登录、注册、授权等认证流程
- **内容获取用例**：实现点播和直播内容的获取、搜索、分类功能
- **播放用例**：处理媒体播放、进度管理、播放历史记录等功能
- **配置管理用例**：管理应用各种配置项的读写和应用
- **站点管理用例**：处理爬虫站点的添加、更新、删除和启用/禁用
- **收藏管理用例**：实现内容收藏的添加、删除和查询功能

#### 3.2.2 业务服务 (domain/service/)

业务服务层提供业务相关的服务功能，被用例层调用，实现特定的业务逻辑。

- **内容解析服务**：解析不同格式的内容数据，转换为统一的数据模型
- **搜索服务**：实现内容搜索功能，支持多条件筛选
- **播放控制服务**：提供媒体播放控制功能
- **用户行为服务**：记录和分析用户行为数据

### 3.3 服务层实现

服务层提供各种功能服务，支持应用的核心功能实现，包括但不限于：

- **ConfigService.ets**：配置服务，管理应用全局配置
- **MediaService.ets**：媒体服务，处理媒体内容的获取和管理
- **PlayerService.ets**：播放器服务，提供播放控制功能
- **NetworkService.ets**：网络服务，处理网络请求和响应
- **CrawlerService.ets**：爬虫服务，负责从站点获取内容
- **CacheService.ets**：缓存服务，管理应用缓存
- **SecurityService.ets**：安全服务，处理安全相关功能
- **DeviceService.ets**：设备服务，管理设备信息和功能

### 3.4 表示层实现

#### 3.4.1 视图模型 (presentation/viewmodel/)

视图模型层实现MVVM架构中的视图模型，连接视图和数据，处理视图状态和用户交互。

- **HomeViewModel.ets**：主页视图模型，管理主页数据和状态
- **DetailViewModel.ets**：详情页视图模型，管理内容详情数据
- **PlayerViewModel.ets**：播放器视图模型，管理播放状态和控制
- **SearchViewModel.ets**：搜索视图模型，处理搜索功能
- **SettingViewModel.ets**：设置视图模型，管理设置页面状态

#### 3.4.2 页面组件 (pages/ & presentation/page/)

页面组件层实现用户界面，负责展示数据和处理用户交互，包括但不限于：

- 主页：展示推荐内容和分类导航
- 内容详情页：展示内容详细信息和剧集列表
- 播放器页面：播放媒体内容和控制界面
- 搜索页面：提供内容搜索功能
- 设置页面：管理应用配置
- 历史记录页面：查看和管理观看历史
- 收藏页面：管理收藏内容
- 站点管理页面：添加和管理爬虫站点

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


