# RayTV 项目规划与架构设计文档

## 1. 项目概述

### 1.1 项目背景
本项目旨在将基于Android的影视播放应用移植到华为Harmony OS 5和Harmony OS 6平台，打造一款支持多设备（直板手机、折叠屏手机、三折叠屏手机、阔折叠屏手机、平板和电视）的纯血鸿蒙应用。

### 1.2 项目目标
- 实现Android版功能的1:1复刻，**注：Android版Fongmi仅作为需求实现的逻辑参考，不作为代码实现的参考**
- 采用纯鸿蒙开发语言和技术栈，完全基于HarmonyOS原生API开发
- 确保在所有支持的鸿蒙设备上提供一致的用户体验
- 优化应用性能，充分利用鸿蒙系统特性

### 1.3 功能范围
- 视频点播(VOD)和直播(Live)播放功能
- 配置文件加载与解析，支持远程JSON配置
- 多源爬虫支持
- 广告屏蔽功能
- 自定义壁纸支持
- 多格式视频源解析
- 播放历史记录管理
- 数据库本地存储与备份恢复
- 电视遥控器操作适配（优先考虑）
- 鸿蒙系统特有功能：
  - 小艺语音助手集成（直接进入应用搜索内容）
  - 跨设备应用流转
  - 手势操作支持（手势抓取投送、碰一碰）
  - 鸿蒙系统动画效果增强

## 2. 技术选型

### 2.1 开发语言
- **主要语言**：ArkTS (HarmonyOS的主要开发语言)
- **辅助语言**：TypeScript

### 2.2 核心技术框架
- **UI框架**：ArkUI (声明式UI框架)
- **多媒体**：MediaPlayer、AVPlayer (HarmonyOS原生媒体播放)
- **数据库**：RelationalStore (HarmonyOS关系型数据库)
- **网络请求**：Fetch API / httpClient、@ohos.net.http (高级网络请求)
- **JSON解析**：内置JSON API、@ohos.data.distributedData (分布式数据管理)
- **跨设备适配**：WindowStage、AbilityContext
- **并发处理**：TaskPool、Worker、WorkScheduler
- **安全沙箱**：@ohos.security.sandbox (应用沙箱)
- **内存管理**：@ohos.memory (内存优化)
- **数据共享**：DataAbility、@ohos.data.resultSet

### 2.3 鸿蒙特有功能集成
- **小艺语音助手**：@ohos.ai.speech (语音识别)、@ohos.ai.model (语义理解)
- **设备流转**：@ohos.distributedHardware.deviceManager、@ohos.app.ability.abilityRouter
- **手势操作**：@ohos.multimodalInput.gesture (手势识别)、@ohos.nfc (碰一碰)、@ohos.starflash (星闪)
- **动画效果**：@ohos.animator (属性动画)、@ohos.transition (转场动画)
- **启动优化**：AppStartup API

## 3. 项目架构设计

### 3.1 整体架构
```
raytv/
├── common/               # 通用组件和工具
│   ├── constant/         # 常量定义
│   ├── util/             # 工具类
│   ├── widget/           # 自定义组件
│   └── security/         # 安全工具
├── data/                 # 数据层
│   ├── bean/             # 数据模型
│   ├── db/               # 数据库相关
│   ├── distributed/      # 分布式数据管理
│   ├── parser/           # 数据解析器
│   └── source/           # 数据源
├── domain/               # 业务逻辑层
│   ├── repository/       # 数据仓库
│   ├── usecase/          # 用例
│   └── sandbox/          # 沙箱隔离环境
├── presentation/         # 表现层
│   ├── ability/          # 应用能力
│   ├── page/             # 页面
│   ├── viewmodel/        # 视图模型
│   ├── state/            # 状态管理
│   └── harmony/          # 鸿蒙特有UI组件
├── service/              # 服务层
│   ├── player/           # 播放器服务
│   ├── spider/           # 爬虫服务（增强版）
│   │   ├── loader/       # 多语言加载器
│   │   │   ├── jar/      # JAR加载器
│   │   │   ├── js/       # JavaScript加载器
│   │   │   └── py/       # Python加载器
│   │   └── adapter/      # Fongmi配置适配器
│   ├── config/           # 配置服务
│   ├── security/         # 安全服务
│   ├── voice/            # 语音助手服务
│   ├── flow/             # 设备流转服务
│   └── gesture/          # 手势操作服务
├── task/                 # 任务调度
│   ├── scheduler/        # WorkScheduler管理
│   └── pool/             # TaskPool优化
└── App.ets               # 应用入口
```

### 3.2 核心模块职责

#### 3.2.1 应用入口模块
- **App.ets**：RayTV应用生命周期管理，全局配置初始化，鸿蒙服务注册
- **RaytvAbility.ets**：RayTV主应用能力，处理UI初始化和窗口管理，设备流转支持
- **ServiceManager.ets**：统一服务管理，负责各服务的初始化和生命周期控制

#### 3.2.2 数据层模块
- **数据模型**：Vod.ets、Live.ets、Site.ets、History.ets、Config.ets、DeviceInfo.ets
- **数据库**：基于RelationalStore实现本地数据持久化，分布式数据同步支持
- **解析器**：配置解析、内容解析、视频源解析

#### 3.2.3 业务逻辑层
- **配置服务**：配置文件加载、解析和管理，支持远程配置和增量更新
- **爬虫服务**：基于ArkCompiler的JAR加载器、ArkTS引擎的JavaScript加载器、HarmonyOS Python运行时的Python加载器
- **播放服务**：基于AVPlayer的播放器管理，播放状态同步，多格式视频源支持

#### 3.2.4 鸿蒙特有服务
- **语音助手服务**：小艺语音助手接入，语音命令解析和执行
- **设备流转服务**：设备发现和连接管理，应用状态序列化和恢复
- **手势操作服务**：手势识别和处理，NFC和星闪技术支持

## 4. 移植原则与策略

### 4.1 核心原则
- **功能参考而非代码参考**：Android版Fongmi仅作为需求实现的逻辑参考，不作为代码实现的参考
- **纯鸿蒙技术栈**：所有功能模块将完全基于HarmonyOS原生API和技术栈进行设计和实现
- **模块化设计**：遵循模块化、可扩展的设计理念，避免功能重叠和代码重复

### 4.2 避免重复开发策略

#### 4.2.1 架构层面的防重复措施
- **统一的目录结构**：严格遵循规划文档中的目录结构，所有工具类放在`common/util/`，所有服务类按功能分类放在`service/`目录下
- **依赖倒置原则**：高层模块依赖于抽象接口，不依赖于具体实现，减少代码耦合
- **单一职责原则**：每个类只负责一个功能领域，避免功能重叠
- **接口隔离原则**：为客户端提供尽可能小的专用接口，而不是提供大的总接口

#### 4.2.2 开发规范与最佳实践
- **命名一致性**：所有类、方法、变量遵循统一的命名规范，提高代码可读性和一致性
- **文档先行**：在实现功能前，先完善设计文档，明确接口定义和功能边界
- **代码复用优先**：优先使用已有的工具类和服务，避免重复开发
- **统一异常处理**：建立全局异常处理机制，避免在每个模块中重复实现异常处理逻辑
- **统一的日志系统**：使用集中式日志系统，避免每个模块单独实现日志功能

#### 4.2.3 重复代码识别与重构
- **定期代码审查**：团队成员之间进行交叉代码审查，识别潜在的重复代码
- **静态代码分析**：使用代码分析工具检测重复代码和代码异味
- **渐进式重构**：识别到重复代码后，采用渐进式重构策略，确保功能稳定的同时优化代码结构
- **模块化改造**：将重复的功能抽取为独立的模块或服务，供其他组件复用

## 5. 项目信息

### 5.1 应用信息
- **Bundle Name**: com.raytv.app
- **Version**: 1.0.0 (Build: 1000000)

### 5.2 开发环境
- **Target SDK Version**: 6.0.0(20)
- **Compatible SDK Version**: 5.1.1(19)
- **Runtime OS**: HarmonyOS
- **Model Version**: 6.0.0

### 5.3 开发依赖
- **@ohos/hypium**: 1.0.24
- **@ohos/hamock**: 1.0.0

## 6. 免责声明

1. 本项目**仅作为技术学习和IDE测试用途**，不提供任何内容服务
2. 项目中所有代码均为学习目的编写，不涉及任何侵权内容
3. 使用本项目时，请确保遵守所在国家和地区的法律法规
4. 如有任何问题或侵权疑虑，请立即联系项目维护者
5. 本项目不对任何基于此项目进行的二次开发或内容使用承担责任