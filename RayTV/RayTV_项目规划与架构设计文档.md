# RayTV 壳类型视频聚合器项目规划与架构设计文档

## 1. 项目概述

### 1.1 项目背景
基于Harmony OS 5/6平台开发的壳类型视频聚合器应用，采用配置驱动的内容聚合架构，通过动态配置源获取和整合来自多个第三方平台的视频资源，为用户提供统一的观看体验。支持多设备（直板手机、折叠屏手机、三折叠屏手机、阔折叠屏手机、平板和电视）的纯血鸿蒙应用。

### 1.2 项目目标
- 构建高性能、可扩展的壳类型视频聚合平台
- 实现配置驱动的内容源管理和动态更新机制
- 提供智能化的内容推荐和个性化的观看体验
- 建立松耦合、可插拔的现代化架构体系
- 确保在所有支持的鸿蒙设备上提供一致的用户体验
- 优化应用性能，充分利用鸿蒙系统特性

### 1.3 核心功能
- **配置源管理**：动态加载和管理多个视频内容源配置，支持源的健康检查和状态监控
- **内容聚合引擎**：统一解析和整合不同格式的内容数据，实现混合源架构
- **智能推荐系统**：基于用户行为和内容特征的个性化推荐，包括推荐算法和用户偏好分析（未接入AI大模型）
- **增强播放体验**：自适应流媒体、画质优化、播放历史记录、播放进度同步
- **插件化解析**：支持多种内容格式的可扩展解析器
- **广告拦截**：智能广告识别和用户隐私保护
- **用户行为分析**：记录用户行为，构建用户画像，提供个性化体验
- **站点管理**：完整的站点CRUD操作，支持导入导出和连接测试
- **鸿蒙特有功能**：小艺语音助手集成、跨设备应用流转、手势操作支持、鸿蒙系统动画效果增强

## 2. 技术选型

### 2.1 开发语言
- **唯一语言**：ArkTS (HarmonyOS的主要开发语言)

### 2.2 核心技术框架
- **UI框架**：ArkUI (声明式UI框架)
- **多媒体**：MediaPlayer、AVPlayer (HarmonyOS原生媒体播放)
- **数据库**：RelationalStore (HarmonyOS关系型数据库)
- **网络请求**：Fetch API / httpClient、@ohos.net.http
- **JSON解析**：内置JSON API、@ohos.data.distributedData
- **配置管理**：远程配置源加载、本地缓存、版本控制
- **内容聚合**：多源内容整合、智能去重、质量评分
- **解析器管理**：插件化架构、动态加载、故障转移
- **跨设备适配**：WindowStage、AbilityContext
- **并发处理**：TaskPool、Worker、WorkScheduler
- **安全沙箱**：@ohos.security.sandbox
- **内存管理**：@ohos.memory
- **数据共享**：DataAbility、@ohos.data.resultSet

## 3. 项目架构设计

### 3.1 整体架构
```
raytv/
├── common/                    # 通用组件和工具
│   ├── di/                   # 依赖注入容器
│   ├── event/                # 事件总线系统
│   ├── constant/             # 常量定义
│   ├── util/                 # 工具类
│   ├── widget/               # 自定义组件
│   ├── security/             # 安全工具
│   ├── state/                # 状态管理
│   ├── theme/                # 主题管理
│   └── types/                # 类型定义
├── data/                     # 数据层
│   ├── bean/                 # 数据模型
│   ├── db/                   # 数据库相关
│   ├── distributed/          # 分布式数据管理
│   ├── parser/               # 数据解析器
│   ├── repository/           # 数据仓库
│   └── source/               # 数据源
├── domain/                   # 业务逻辑层
│   ├── repository/           # 数据仓库
│   ├── usecase/              # 用例
│   └── sandbox/              # 沙箱隔离环境
├── presentation/             # 表现层
│   ├── ability/              # 应用能力
│   ├── page/                 # 页面
│   ├── pages/                # 现代页面
│   ├── viewmodel/            # 视图模型
│   ├── state/                # 状态管理
│   └── harmony/              # 鸿蒙特有UI组件
├── service/                  # 服务层
│   ├── player/               # 播放器服务
│   ├── parser/               # 解析器管理服务
│   ├── config/               # 配置服务
│   │   ├── NetworkSourceManager.ets   # 网络源管理
│   │   └── ConfigSourceService.ets      # 配置源服务
│   ├── content/              # 内容聚合服务
│   │   └── ContentAccessService.ets    # 统一内容访问
│   ├── recommendation/       # 推荐服务
│   ├── ads/                  # 广告服务
│   ├── media/                # 媒体服务
│   ├── spider/               # 站点服务
│   ├── cache/                # 缓存服务
│   ├── interfaces/           # 服务接口定义
│   ├── security/             # 安全服务
│   ├── voice/                # 语音助手服务
│   ├── flow/                 # 设备流转服务
│   ├── gesture/              # 手势操作服务
│   ├── pool/                 # 内容池管理
│   │   └── SourcePoolManager.ets      # 统一内容池
│   ├── sync/                 # 数据同步服务
│   ├── device/               # 设备管理服务
│   ├── input/                # 输入服务
│   └── wallpaper/            # 壁纸服务
├── components/               # 通用组件
│   ├── ContentSourceBadge.ets        # 内容来源标识
│   ├── NetworkSourceDetailPopup.ets  # 源详情弹窗
│   ├── ImageLazyLoader.ets           # 图片懒加载
│   └── VirtualList.ets               # 虚拟列表
├── design/                   # 设计系统
│   ├── DesignSystem.ets               # 设计系统核心
│   ├── ThemeProvider.ets              # 主题提供者
│   ├── ModernDesignSystem.ets         # 现代设计系统
│   └── HighContrastTheme.ets          # 高对比度主题
├── navigation/               # 导航系统
│   ├── AppNavigator.ets              # 应用导航
│   └── NavigationGuard.ets            # 导航守卫
├── task/                     # 任务调度
│   ├── scheduler/            # WorkScheduler管理
│   └── pool/                 # TaskPool优化
├── test/                     # 测试目录
├── types/                    # 类型定义
└── App.ets                   # 应用入口
```

## 4. 混合源架构设计

### 4.1 核心设计理念
- **混合源使用模式**：用户可自由组合不同网络源的内容（点播、直播、壁纸、广告过滤、解码配置）
- **存储模型**：每个网络源独立存储，内容提取到统一使用池
- **内容标识**：所有内容项标记来源信息，确保透明性

### 4.2 核心数据结构
- **NetworkSourceConfig**：网络源配置（id、name、url、type、version、isActive、contentUsage、priority、tags、lastUpdated、healthStatus）
- **VodSiteWithSource**：带来源标识的点播站点
- **LiveChannelWithSource**：带来源标识的直播频道
- **WallpaperWithSource**：带来源标识的壁纸

### 4.3 核心服务
- **SourcePoolManager**：统一内容池管理器，负责从各个源加载内容到统一池
- **NetworkSourceManager**：网络源管理，负责源的CRUD操作、健康检查
- **ContentAccessService**：统一内容访问服务，提供对统一内容池的访问接口

### 4.4 优势
- **灵活性**：用户可自由组合不同源的内容
- **可维护性**：源的添加/修改不影响其他源
- **透明性**：清晰显示每个内容的来源
- **性能优化**：池化访问，避免重复加载
- **容错性**：单个源故障不影响其他源的使用
- **用户控制**：用户可精确控制每个源的内容使用

## 5. 实现进度

### 阶段一: 核心架构搭建 (已完成 ✅)
- ✅ 创建 SourcePoolManager 服务
- ✅ 创建 ContentAccessService 服务
- ✅ 创建 NetworkSourceManager 服务
- ✅ 定义新的数据类型

### 阶段二: UI 重构 (已完成 ✅)
- ✅ 重新设计 SettingsPage
- ✅ 创建 NetworkSourceDetailPopup 组件
- ✅ 创建 ContentSourceBadge 组件
- ✅ 更新各个内容页面的来源显示

### 阶段三: 搜索功能重构 (已完成 ✅)
- ✅ 重构 SearchRepository 使用 ContentAccessService
- ✅ 支持按源筛选搜索结果
- ✅ 支持在搜索结果中显示来源

### 阶段四: 集成与优化 (已完成 ✅)
- ✅ 更新 MediaDetailPage 使用新架构
- ✅ 更新 LivePage 使用新架构
- ✅ 更新 HomePage 使用新架构
- ✅ 前端界面布局和操作体验重新设计
- ✅ 性能优化和错误处理
- ✅ UI组件库建设
- ✅ 设计系统实现

**阶段四完成度**: 98% (评分: A+ 92.45/100)

### 阶段五: 核心功能实现 (已完成 ✅)
- ✅ 实现真实的推荐算法
- ✅ 实现完整的直播播放功能
- ✅ 实现真实的媒体数据获取

**阶段五完成度**: 100% (评分: A 90/100)

详见: `核心功能实现完成报告.md`

## 6. 迁移指南

### 旧代码 → 新代码
```typescript
// 旧代码
import ConfigSourceService from './service/config/ConfigSourceService';
const configService = ConfigSourceService.getInstance();
const sites = await configService.getSites();

// 新代码
import ContentAccessService from './service/content/ContentAccessService';
const contentService = ContentAccessService.getInstance();
const sites = contentService.getAllVodSites();
```

### 页面集成示例
```typescript
// 在页面中使用ContentAccessService
import ContentAccessService from '@ohos:raytv/src/main/ets/service/content/ContentAccessService';

@Component
struct MediaDetailPage {
  private contentAccessService = ContentAccessService.getInstance();
  
  aboutToAppear() {
    this.contentAccessService.initialize();
  }
  
  // 获取所有点播站点
  loadAllSites() {
    const sites = this.contentAccessService.getAllVodSites();
    // 处理站点列表...
  }
}
```

## 7. 项目信息

### 应用信息
- **Bundle Name**: com.raytv.app
- **Version**: 1.0.0 (Build: 1000000)

### 开发环境
- **Target SDK Version**: 6.0.0(20)
- **Compatible SDK Version**: 5.1.1(19)
- **Runtime OS**: HarmonyOS
- **Model Version**: 6.0.0

## 8. 免责声明
- 本项目**仅作为技术学习和IDE测试用途**，不提供任何内容服务
- 项目中所有代码均为学习目的编写，不涉及任何侵权内容
- 使用本项目时，请确保遵守所在国家和地区的法律法规
- 如有任何问题或侵权疑虑，请立即联系项目维护者
- 本项目不对任何基于此项目进行的二次开发或内容使用承担责任