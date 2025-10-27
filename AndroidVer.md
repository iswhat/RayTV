# Android 影视应用技术文档

## 项目概述

这是一个基于Android平台的影视播放应用，具有以下核心功能：
- 视频点播(VOD)和直播(Live)播放功能
- 配置文件加载与解析，支持远程JSON配置
- 多源爬虫支持，可通过jar、js、py等方式加载爬虫模块
- 广告屏蔽功能
- 自定义壁纸支持
- 多格式视频源解析
- 弹幕功能支持
- 播放历史记录管理
- 数据库本地存储与备份恢复

## 项目结构

```
app/src/main/java/com/fongmi/android/tv/
├── api/                  # API模块，包含配置解析、爬虫加载等
│   ├── config/           # 配置文件处理
│   ├── loader/           # 爬虫加载器
│   └── parser/           # 解析器
├── bean/                 # 数据模型
├── db/                   # 数据库相关
│   └── dao/              # 数据访问对象
├── player/               # 播放器相关
│   ├── danmaku/          # 弹幕功能
│   ├── exo/              # ExoPlayer相关
│   └── extractor/        # 视频提取器
├── server/               # 服务端实现
├── service/              # 后台服务
├── ui/                   # 用户界面
├── utils/                # 工具类
└── App.java              # 应用入口
```

## 核心模块详解

### 1. 应用入口与基础配置

**App.java**
- 应用程序入口点，继承自Application类
- 初始化全局配置，如Gson实例、网络配置等
- 管理应用生命周期

### 2. 配置文件加载与解析

**配置文件结构**：
- 支持远程JSON配置文件，如`https://www.eoeoo.com/base2/a.json`或`https://q.uoouo.com/dianshi.json`
- 配置包含spider（爬虫）、sites（站点）、lives（直播源）、ads（广告屏蔽规则）、wallpaper（壁纸）等信息

**主要配置处理类**：

**LiveConfig.java**
- 负责直播配置的加载与解析
- 处理lives数组中的直播源信息
- 支持spider配置，加载爬虫模块
- 实现广告规则、主机规则等配置项的处理

**VodConfig.java**
- 负责点播配置的加载与解析
- 处理sites数组中的站点信息
- 支持spider配置，加载爬虫模块
- 管理解析器、代理、规则等配置

**WallConfig.java**
- 负责壁纸配置的加载与处理
- 支持图片、GIF、视频等多种壁纸格式
- 实现壁纸下载、缓存和快照生成

### 3. 爬虫功能实现

**爬虫加载机制**：

**BaseLoader.java**
- 爬虫加载的基类，提供统一的爬虫获取接口
- 支持jar、js、py三种类型的爬虫加载

**JarLoader.java**
- 负责加载和管理jar类型的爬虫
- 使用DexClassLoader动态加载jar文件
- 支持远程jar下载和本地jar加载
- 实现爬虫实例的缓存和管理

**JsLoader.java**
- 负责加载和管理JavaScript类型的爬虫
- 基于QuickJS引擎实现

**PyLoader.java**
- 负责加载和管理Python类型的爬虫
- 基于Chaquo库实现Python代码的执行

**爬虫执行流程**：
1. 从配置文件中解析spider字段，获取爬虫jar地址
2. 通过BaseLoader.parseJar方法加载爬虫jar
3. 当需要执行搜索或播放操作时，通过Site.spider()获取爬虫实例
4. 调用爬虫的相应方法（如searchContent、playerContent等）执行具体操作

### 4. 站点搜索与播放

**站点数据结构**：

**Site.java**
- 表示一个视频站点的数据模型
- 包含key、name、api、ext、jar等字段
- 提供spider()方法获取对应的爬虫实例

**搜索与播放功能**：

**SiteViewModel.java**
- 处理站点相关的业务逻辑，如首页内容、分类内容、详情内容、播放内容等
- 实现搜索功能，支持关键词搜索和快速搜索
- 调用相应的爬虫方法执行具体操作

**搜索流程**：
1. 用户输入关键词
2. 应用调用SiteViewModel.searchContent方法
3. 根据站点类型选择不同的搜索实现
4. 对于type=3的站点，直接调用爬虫的searchContent方法
5. 对于其他类型站点，通过HTTP请求获取搜索结果

**播放流程**：
1. 用户选择要播放的视频
2. 应用调用SiteViewModel.playerContent方法
3. 获取视频的播放地址
4. 通过Source类进行视频源处理
5. 将处理后的地址传递给播放器进行播放

### 5. 广告屏蔽功能

**广告屏蔽实现**：

**CustomWebView.java**
- 实现isAd方法，用于检测URL是否为广告
- 从VodConfig和LiveConfig中获取广告规则列表
- 使用Util.containOrMatch方法进行规则匹配

**广告规则配置**：
- 在配置文件中通过ads数组定义广告规则
- 规则可以是域名、关键词或正则表达式
- 应用启动时加载这些规则到内存中

### 6. 壁纸功能

**壁纸类型支持**：
- 静态图片
- GIF动画
- 视频壁纸

**壁纸处理类**：

**CustomWallView.java**
- 自定义壁纸视图，支持不同类型壁纸的加载和显示
- 实现生命周期管理，在适当时机加载和释放资源
- 支持动态切换壁纸类型

**WallConfig.java**
- 处理壁纸的下载和缓存
- 自动检测壁纸类型并设置相应的显示模式
- 为视频壁纸创建快照，作为加载时的预览

### 7. 播放器实现

**Players.java**
- 基于ExoPlayer的播放器实现
- 支持软硬解码切换
- 实现播放控制、状态管理、事件处理等功能
- 集成弹幕功能

**Source.java**
- 负责视频源的处理和解析
- 支持多种视频格式

**视频提取器**：
- Youtube.java：YouTube视频解析
- Thunder.java：迅雷链接解析
- JianPian.java：片片视频解析

### 8. 数据库实现

**AppDatabase.java**
- 基于Room的数据库实现
- 管理Keep、Site、Live、History等实体
- 提供数据库备份和恢复功能
- 支持数据库迁移

**数据访问对象**：
- SiteDao：站点数据访问
- LiveDao：直播数据访问
- HistoryDao：历史记录数据访问
- KeepDao：收藏数据访问

### 9. 数据模型

**主要数据模型**：

**Vod.java**
- 点播内容的数据模型
- 包含vodId、vodName、vodPic等信息
- 支持播放源解析和标志位处理

**Live.java**
- 直播内容的数据模型
- 包含name、url、api等信息
- 支持爬虫关联和头信息设置

**Config.java**
- 配置信息的数据模型
- 支持本地存储和管理

## 应用流程

### 1. 启动流程
1. 应用启动，初始化App实例
2. 加载保存的配置信息
3. 根据配置加载对应的spider爬虫
4. 初始化UI界面，显示首页内容

### 2. 配置文件加载流程
1. 用户输入或选择配置文件URL
2. 应用通过HTTP请求获取配置文件内容
3. 根据配置类型（VOD或Live）解析配置
4. 加载spider爬虫模块
5. 初始化站点或直播源数据
6. 更新UI显示加载结果

### 3. 视频搜索与播放流程
1. 用户选择站点并输入搜索关键词
2. 应用调用对应站点的爬虫执行搜索
3. 显示搜索结果列表
4. 用户选择视频，查看详情
5. 应用加载视频播放源
6. 调用播放器播放视频

### 4. 广告屏蔽流程
1. 应用启动时加载配置中的广告规则
2. 在WebView加载URL前检查是否为广告
3. 如果匹配到广告规则，阻止加载

### 5. 壁纸设置流程
1. 用户选择或配置壁纸URL
2. 应用下载壁纸文件
3. 检测壁纸类型（图片、GIF或视频）
4. 为视频壁纸创建快照
5. 应用壁纸并设置相应的显示模式

## 技术栈

- **开发语言**：Java
- **播放器框架**：ExoPlayer
- **数据库**：Room
- **网络请求**：OkHttp
- **JSON解析**：Gson
- **爬虫支持**：
  - Java爬虫：自定义ClassLoader加载
  - JavaScript爬虫：QuickJS引擎
  - Python爬虫：Chaquo库
- **依赖注入**：GreenRobot EventBus
- **图片加载**：Glide
- **UI框架**：AndroidX，Material Design

## 关键特性

1. **多源爬虫支持**：通过jar、js、py等多种方式支持不同的爬虫实现
2. **动态配置加载**：支持远程JSON配置，便于更新数据源
3. **广告屏蔽**：基于规则的广告识别和屏蔽
4. **多样化壁纸**：支持图片、GIF和视频壁纸
5. **强大的视频解析**：支持多种视频格式和来源
6. **本地数据管理**：完善的数据库支持和备份恢复功能
7. **用户体验优化**：流畅的播放体验和响应式界面