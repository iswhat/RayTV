# RayTV - HarmonyOS视频应用

## 1. 项目概述

RayTV是一款基于HarmonyOS开发的视频应用，提供电影、电视剧、综艺、直播等多种视频内容的浏览、搜索、播放和下载功能。应用采用HarmonyOS推荐的架构设计，支持多设备协同和分布式能力。

### 主要功能

- **视频浏览**：分类浏览电影、电视剧、综艺等内容
- **智能搜索**：快速搜索视频内容
- **高清播放**：支持多种清晰度播放
- **下载管理**：离线下载与本地播放
- **观看历史**：记录和管理观看进度
- **个性化推荐**：根据观影偏好推荐内容
- **直播功能**：实时观看电视直播
- **用户中心**：账户管理与收藏功能

## 2. 项目结构

RayTV项目采用HarmonyOS推荐的分层架构设计，遵循领域驱动设计原则，主要包括以下几层：

- **表现层**：负责用户界面展示，使用HarmonyOS组件化开发
- **领域层**：包含业务逻辑和领域模型
- **服务层**：提供核心业务服务，按功能域组织
- **数据层**：负责数据存取和外部交互
- **工具层**：提供通用工具和辅助功能

主要目录结构如下：

```
raytv/
├── src/main/ets/
│   ├── common/              # 公共资源和工具（推荐使用）
│   │   └── util/            # 工具类
│   ├── components/          # 可复用组件
│   ├── data/                # 数据相关代码
│   │   ├── model/           # 数据模型
│   │   ├── repository/      # 数据仓库
│   │   ├── service/         # 传统数据服务（逐步迁移）
│   │   └── storage/         # 存储相关
│   ├── domain/              # 领域层
│   │   ├── model/           # 领域模型
│   │   └── service/         # 领域服务
│   ├── entryability/        # HarmonyOS入口能力
│   ├── pages/               # 页面
│   ├── resources/           # 资源文件
│   ├── service/             # 核心服务层（按功能域组织）
│   │   ├── cache/           # 缓存服务
│   │   ├── config/          # 配置服务
│   │   ├── download/        # 下载服务
│   │   ├── live/            # 直播服务
│   │   ├── media/           # 媒体服务
│   │   ├── notification/    # 通知服务
│   │   ├── spider/          # 爬虫服务
│   │   └── user/            # 用户服务
│   └── utils/               # 额外工具类（待整合）
├── hvigor/                  # HarmonyOS构建工具
└── resources/               # 全局资源
```

### 服务重组说明

近期对项目服务层进行了重构，将核心服务按功能域重新组织：

- 从`data/service/`和`services/`目录迁移核心服务到`service/`对应子目录
- 统一使用单例模式管理服务实例
- 优化ServiceFactory创建和管理服务的逻辑
- 标记重复服务实现，计划后续清理
- 遵循HarmonyOS系统接口规范，使用推荐的API调用方式

## 3. 核心功能模块

### 3.1 视频播放

- 支持多种格式视频播放
- 提供高清、标清等多种清晰度选择
- 支持播放进度记忆
- 提供倍速播放、音量调节等功能

### 3.2 内容搜索与推荐

- 关键词搜索功能
- 分类筛选功能
- 智能推荐算法
- 热门内容展示

### 3.3 数据服务

数据服务层提供各种业务功能支持，已按功能域重新组织：

#### 用户相关服务
- **UserService**：用户账户管理、认证授权、数据同步

#### 媒体相关服务
- **MediaService**：媒体内容管理
- **HistoryService**：观看历史记录管理
- **LiveStreamService**：直播流服务

#### 功能服务
- **DownloadService**：视频下载任务和队列管理
- **CacheService**：应用缓存管理
- **ConfigService**：应用配置管理
- **NotificationService**：基于HarmonyOS通知API的通知管理
- **SettingService**：应用设置管理

#### 基础服务
- **NetworkService**：网络连接与请求管理
- **FileService**：文件操作服务
- **DataSyncService**：数据同步服务
- 等其他辅助服务

所有核心服务均采用HarmonyOS推荐的单例模式实现，通过ServiceFactory统一管理实例生命周期。

## 4. 技术栈

- **开发语言**：ArkTS (HarmonyOS TypeScript方言)
- **开发框架**：HarmonyOS
- **UI框架**：HarmonyOS原生组件（ArkUI）
- **状态管理**：自定义状态管理
- **网络请求**：ohos.net.http API
- **本地存储**：Preferences、fileio
- **构建工具**：npm、hvigor
- **组件系统**：基于HarmonyOS组件化开发

## 5. 开发规范

### HarmonyOS开发规范
- **代码风格**：遵循ArkTS官方编码规范
- **命名规范**：使用驼峰命名法，文件使用PascalCase
- **注释规范**：为类、方法、重要变量添加JSDoc格式注释
- **异常处理**：统一使用try-catch-finally，遵循HarmonyOS错误码规范
- **日志记录**：使用统一Logger工具，遵循日志级别规范
- **资源访问**：遵循HarmonyOS权限申请和资源访问规范

### 项目特有规范
- **目录结构**：按领域驱动设计组织代码结构
- **服务管理**：核心服务使用单例模式，通过ServiceFactory统一管理
- **工具类命名**：统一为XXXUtil格式
- **接口设计**：遵循HarmonyOS接口定义规范，提供明确的参数验证
- **性能优化**：遵循HarmonyOS应用性能优化建议

## 6. 服务重构计划

### 已完成工作
- 将核心服务从data/service/迁移到service/对应功能域子目录
- 统一服务导入路径，更新ServiceFactory创建逻辑
- 优化Logger工具，合并到common/util/目录
- 标记重复服务实现，制定清理计划

### 待完成工作
- 完成data/service/剩余服务的迁移
- 移除重复服务实现（services/目录下的重复服务）
- 合并功能重叠的服务（如HistoryService和HistoryManager）
- 统一工具类到common/util/目录
- 全面优化服务层接口，确保符合HarmonyOS最佳实践
- 完善服务层单元测试

## 7. 构建与运行

### 环境要求
- HarmonyOS SDK
- Node.js环境
- DevEco Studio

### 构建命令
```bash
# 使用hvigor构建项目
npx hvigor build

# 或使用npm脚本
npm run build
```

### 运行应用
1. 连接HarmonyOS设备或模拟器
2. 执行构建命令
3. 安装并运行应用

## 8. 注意事项

- 应用需要网络权限才能访问视频内容
- 下载功能需要存储权限
- 直播功能可能受到网络状况影响
- 建议在稳定的网络环境下使用以获得最佳体验