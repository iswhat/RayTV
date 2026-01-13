/**
 * Config - Configuration information data types | 配置信息数据类型
 * Define data structure for app global configuration | 定义应用全局配置的数据结构
 */

/**
 * Player configuration interface | 播放器配置接口
 */
export interface PlayerConfig {
  defaultPlayer: 'system' | 'custom'; // Default player | 默认播放器
  enableHardwareDecode: boolean;     // Enable hardware decoding | 启用硬件解码
  autoContinuePlay: boolean;         // Auto continue play | 自动续播
  rememberPosition: boolean;         // Remember play position | 记住播放位置
  speedList: number[];               // Playback speed list | 播放速度列表
  defaultSpeed: number;              // Default playback speed | 默认播放速度
  enableHDR: boolean;                // Enable HDR | 启用HDR
  enableDolby: boolean;              // Enable Dolby sound | 启用杜比音效
  autoPlayNext: boolean;             // Auto play next episode | 自动播放下一集
  defaultResolution?: string;        // Default resolution | 默认分辨率
  aspectRatio: 'auto' | '16:9' | '4:3' | 'custom'; // Aspect ratio | 画面比例
  subtitlesEnabled: boolean;         // Enable subtitles | 启用字幕
  defaultSubtitleLanguage?: string;  // Default subtitle language | 默认字幕语言
  defaultAudioTrack?: string;        // Default audio track | 默认音频
  backgroundPlay: boolean;           // Background play | 后台播放
  playMode: 'single' | 'loop' | 'shuffle'; // Playback mode | 播放模式
  networkBufferSize?: number;        // Network buffer size (MB) | 网络缓冲大小（MB）
  localBufferSize?: number;          // Local buffer size (MB) | 本地缓冲大小（MB）
  seekStepForward: number;           // Fast forward duration (seconds) | 快进时长（秒）
  seekStepBackward: number;          // Fast backward duration (seconds) | 快退时长（秒）
}

/**
 * Display configuration interface | 显示配置接口
 */
export interface DisplayConfig {
  theme: 'light' | 'dark' | 'system'; // Theme | 主题
  fontSize: number;                  // Font size | 字体大小
  autoFullScreen: boolean;           // Auto full screen | 自动全屏
  enableGestures: boolean;           // Enable gestures | 启用手势
  animationEnabled: boolean;         // Enable animations | 启用动画
  transitionSpeed: 'slow' | 'normal' | 'fast'; // Transition speed | 过渡速度
  showFPS: boolean;                  // Show FPS | 显示FPS
  showNetworkSpeed: boolean;         // Show network speed | 显示网速
  showTimeCode: boolean;             // Show time code | 显示时间码
  maxColumns: number;                // Max columns | 最大列数
  posterAspectRatio: 'auto' | '2:3' | '3:4' | '16:9'; // Poster aspect ratio | 海报比例
  hideNavOnPlay: boolean;            // Hide navigation bar during play | 播放时隐藏导航栏
  screenSaverDelay?: number;         // Screen saver delay (minutes) | 屏幕保护延迟（分钟）
  colorPrimary?: string;             // Primary color | 主题色
  colorAccent?: string;              // Accent color | 强调色
  customStyles?: Map<string, string | number | boolean>;   // Custom styles | 自定义样式
  tvMode: boolean;                   // TV mode | TV模式
  tabletMode: boolean;               // Tablet mode | 平板模式
  phoneMode: boolean;                // Phone mode | 手机模式
}

/**
 * Network configuration interface | 网络配置接口
 */
export interface NetworkConfig {
  timeout: number;                   // Timeout (seconds) | 超时时间（秒）
  retryCount: number;                // Retry count | 重试次数
  enableCache: boolean;              // Enable cache | 启用缓存
  cacheSize: number;                 // Cache size (MB) | 缓存大小（MB）
  maxConcurrentRequests: number;     // Max concurrent requests | 最大并发请求数
  connectionTimeout: number;         // Connection timeout (seconds) | 连接超时（秒）
  readTimeout: number;               // Read timeout (seconds) | 读取超时（秒）
  writeTimeout: number;              // Write timeout (seconds) | 写入超时（秒）
  enableProxy: boolean;              // Enable proxy | 启用代理
  proxyServer?: string;              // Proxy server | 代理服务器
  proxyPort?: number;                // Proxy port | 代理端口
  userAgent?: string;                // Custom User-Agent | 自定义User-Agent
  enableDNSCache: boolean;           // Enable DNS cache | 启用DNS缓存
  dnsCacheTime?: number;             // DNS cache time (minutes) | DNS缓存时间（分钟）
  enableHttp2: boolean;              // Enable HTTP/2 | 启用HTTP/2
  enableCompression: boolean;        // Enable compression | 启用压缩
  allowInsecureConnections: boolean; // Allow insecure connections | 允许不安全连接
  certificate?: string;              // Custom certificate | 自定义证书
}

/**
 * Content restrictions configuration interface | 内容限制配置接口
 */
export interface ContentRestrictions {
  enabled: boolean;
  rating?: string;
  password?: string;
}

/**
 * Security configuration interface | 安全配置接口
 */
export interface SecurityConfig {
  enableSandbox: boolean;            // Enable sandbox | 启用沙箱
  allowThirdParty: boolean;          // Allow third-party JAR loading | 允许第三方JAR加载
  dataEncryption: boolean;           // Data encryption | 数据加密
  requireBiometricAuth: boolean;     // Biometric authentication | 生物识别认证
  appLockEnabled: boolean;           // App lock | 应用锁
  appLockTimeout?: number;           // App lock timeout (minutes) | 应用锁超时（分钟）
  autoClearCacheOnExit: boolean;     // Auto clear cache on exit | 退出时自动清理缓存
  privateMode: boolean;              // Private mode | 隐私模式
  hideSensitiveInfo: boolean;        // Hide sensitive info | 隐藏敏感信息
  enableAntiCheat: boolean;          // Enable anti-cheat | 启用反作弊
  safeBrowsingEnabled: boolean;      // Safe browsing | 安全浏览
  contentRestrictions?: ContentRestrictions;
}

/**
 * Ad block configuration interface | 广告拦截配置接口
 */
export interface AdBlockConfig {
  enabled: boolean;                  // Enable ad block | 启用广告拦截
  rules: string[];                   // Block rules | 拦截规则
  updateInterval: number;            // Update interval (hours) | 更新间隔（小时）
  blockVideoAds: boolean;            // Block video ads | 拦截视频广告
  blockPopupAds: boolean;            // Block popup ads | 拦截弹窗广告
  customFilters?: string[];          // Custom filters | 自定义过滤规则
  filterLists?: string[];            // Filter list URLs | 过滤规则列表URL
  whitelist?: string[];              // Whitelist | 白名单
  lastUpdateTime?: number;           // Last update time | 最后更新时间
}

/**
 * HarmonyOS specific configuration interface | 鸿蒙特有配置接口
 */
export interface HarmonyConfig {
  enableVoiceAssistant: boolean;     // Enable voice assistant | 启用语音助手
  enableDeviceFlow: boolean;         // Enable device flow | 启用设备流转
  enableGestureControl: boolean;     // Enable gesture control | 启用手势控制
  enableWidget: boolean;             // Enable desktop widget | 启用桌面小组件
  enableNotification: boolean;       // Enable notification | 启用通知
  enableAutoStart: boolean;          // Enable auto start | 启用自启动
  enableBackgroundSync: boolean;     // Enable background sync | 启用后台同步
  enableMultiWindow: boolean;        // Enable multi-window | 启用多窗口
  enableHiAI: boolean;               // Enable HiAI acceleration | 启用HiAI加速
  enableSuperDevice: boolean;        // Enable super device | 启用超级终端
  deviceSharingEnabled: boolean;     // Device sharing | 设备共享
  notificationChannels?: string[];   // Notification channels | 通知渠道
  quickActions?: string[];           // Quick actions | 快捷操作
}

/**
 * Search configuration interface | 搜索配置接口
 */
export interface SearchConfig {
  enableAutoSuggest: boolean;        // Enable auto suggest | 启用自动建议
  searchHistoryLimit: number;        // Search history limit | 搜索历史限制
  enableGlobalSearch: boolean;       // Enable global search | 启用全局搜索
  searchTimeout: number;             // Search timeout (seconds) | 搜索超时（秒）
  searchDelay: number;               // Search delay (milliseconds) | 搜索延迟（毫秒）
  defaultSearchFilter?: string;      // Default search filter | 默认搜索过滤
  searchHighlight: boolean;          // Search result highlight | 搜索结果高亮
  enableSearchAnalytics: boolean;    // Enable search analytics | 启用搜索分析
}

/**
 * Download configuration interface | 下载配置接口
 */
export interface DownloadConfig {
  enableDownload: boolean;           // Enable download | 启用下载
  maxConcurrentDownloads: number;    // Max concurrent downloads | 最大并发下载数
  downloadPath?: string;             // Download path | 下载路径
  autoDownloadNextEpisode: boolean;  // Auto download next episode | 自动下载下一集
  downloadOnWifiOnly: boolean;       // Download on WiFi only | 仅WiFi下载
  downloadQuality?: string;          // Download quality | 下载质量
  enableDownloadQueue: boolean;      // Enable download queue | 启用下载队列
  downloadTimeout: number;           // Download timeout (seconds) | 下载超时（秒）
  enableBackgroundDownload: boolean; // Enable background download | 启用后台下载
}

/**
 * Cloud account configuration interface | 云账号配置接口
 */
export interface CloudAccount {
  type: string;
  username?: string;
  token?: string;
  lastSyncTime?: number;
}

/**
 * Sync configuration interface | 同步配置接口
 */
export interface SyncConfig {
  enableCloudSync: boolean;          // Enable cloud sync | 启用云同步
  syncInterval: number;              // Sync interval (minutes) | 同步间隔（分钟）
  syncOnWifiOnly: boolean;           // Sync on WiFi only | 仅WiFi同步
  syncHistory: boolean;              // Sync history | 同步历史记录
  syncFavorites: boolean;            // Sync favorites | 同步收藏
  syncSettings: boolean;             // Sync settings | 同步设置
  autoBackup: boolean;               // Auto backup | 自动备份
  backupInterval?: number;           // Backup interval (days) | 备份间隔（天）
  cloudAccount?: CloudAccount;
}

/**
 * Log configuration interface | 日志配置接口
 */
export interface LogConfig {
  enableLogging: boolean;            // Enable logging | 启用日志
  logLevel: 'debug' | 'info' | 'warn' | 'error'; // Log level | 日志级别
  logToFile: boolean;                // Log to file | 记录到文件
  maxLogSize?: number;               // Max log size (MB) | 最大日志大小（MB）
  logRetentionDays?: number;         // Log retention days | 日志保留天数
  enableAnalytics: boolean;          // Enable analytics | 启用分析
  crashReporting: boolean;           // Crash reporting | 崩溃报告
}

/**
 * App configuration main interface | 应用配置主接口
 */
export interface AppConfig {
  player: PlayerConfig;              // Player configuration | 播放器配置
  display: DisplayConfig;            // Display configuration | 显示配置
  network: NetworkConfig;            // Network configuration | 网络配置
  security: SecurityConfig;          // Security configuration | 安全配置
  adBlock: AdBlockConfig;            // Ad block configuration | 广告拦截配置
  harmony: HarmonyConfig;            // HarmonyOS specific configuration | 鸿蒙特有配置
  search: SearchConfig;              // Search configuration | 搜索配置
  download: DownloadConfig;          // Download configuration | 下载配置
  sync: SyncConfig;                  // Sync configuration | 同步配置
  log: LogConfig;                    // Log configuration | 日志配置
  version: string;                   // Config version | 配置版本
  lastUpdated: number;               // Last update time | 最后更新时间
  migrationVersion?: string;         // Migration version | 迁移版本
  customSettings?: Map<string, string | number | boolean>; // Custom settings | 自定义设置
}

/**
 * Config version information interface | 配置版本信息接口
 */
export interface ConfigVersion {
  version: string;                   // Version number | 版本号
  buildTime: number;                 // Build time | 构建时间
  minAppVersion: string;             // Minimum app version | 最低应用版本
  changelog?: string;                // Changelog | 更新日志
}

/**
 * Config change record interface | 配置变更记录接口
 */
export interface ConfigChange {
  keyPath: string;                   // Config path | 配置路径
  oldValue: string | number | boolean | null; // Old value | 旧值
  newValue: string | number | boolean | null; // New value | 新值
  changedAt: number;                 // Change time | 变更时间
  changedBy: 'user' | 'system' | 'sync'; // Change source | 变更来源
}

/**
 * Config preset interface | 配置预设接口
 */
export interface ConfigPreset {
  id: string;                        // Preset ID | 预设ID
  name: string;                      // Preset name | 预设名称
  description?: string;              // Description | 描述
  config: Partial<AppConfig>;        // Preset config | 预设配置
  isDefault?: boolean;               // Whether default preset | 是否默认预设
  deviceType?: string;               // Applicable device type | 适用设备类型
  tags?: string[];                   // Tags | 标签
}

/**
 * Config import/export options interface | 配置导入导出选项接口
 */
export interface ConfigImportExportOptions {
  includeCredentials?: boolean;      // Include credentials | 包含凭证
  includeHistory?: boolean;          // Include history | 包含历史记录
  includeFavorites?: boolean;        // Include favorites | 包含收藏
  format: 'json' | 'encrypted';      // Format | 格式
  password?: string;                 // Password | 密码
  description?: string;              // Description | 描述
}

/**
 * Live channel interface | Live频道接口
 */
export interface LiveChannel {
  name: string;              // Channel name | 频道名称
  url?: string;              // Live URL | 直播URL
  urls?: string[];           // Live URL list | 直播URL列表
  epg?: string;              // EPG configuration | EPG配置
  logo?: string;             // Channel logo | 频道Logo
}

/**
 * Live group interface | Live组接口
 */
export interface LiveGroup {
  group: string;             // Group name | 组名
  channels: LiveChannel[];   // Channel list | 频道列表
}

/**
 * Live configuration interface | Live配置接口
 */
export interface LiveConfigItem {
  name: string;              // Live source name | 直播源名称
  type: number;              // Type | 类型
  playerType?: number | string;  // Player type | 播放器类型
  url?: string;              // Live list URL | 直播列表URL
  epg?: string;              // EPG configuration | EPG配置
  logo?: string;             // Logo
}

/**
 * Live configuration collection interface | Live配置集合接口
 */
export interface LiveCollection {
  lives: (LiveConfigItem | LiveGroup)[];  // Live configuration list | 直播配置列表
  version?: string;          // Version | 版本
  updatedAt?: number;        // Update time | 更新时间
}

/**
 * Site configuration collection interface | 站点配置集合接口
 */
export interface SiteCollection {
  sites: SiteInfo[];           // Site list | 站点列表
  version: string;             // Version | 版本
  updatedAt: number;           // Update time | 更新时间
}

/**
 * Site configuration validation result interface | 站点配置验证结果接口
 */
export interface SiteValidationResult {
  isValid: boolean;            // Whether valid | 是否有效
  errors?: string[];           // Error list | 错误列表
  warnings?: string[];         // Warning list | 警告列表
}

/**
 * Test result interface | 测试结果接口
 */
export interface TestResult {
  success: boolean;          // Whether test succeeded | 测试是否成功
  message?: string;          // Test message | 测试消息
  timestamp: number;         // Test time | 测试时间
}

/**
 * Site information interface | 站点信息接口
 */
export interface SiteInfo {
  id: string;                  // Site unique ID | 站点唯一标识
  key: string;                 // Site key | 站点键名
  name: string;                // Site name | 站点名称
  logo?: string;               // Site logo | 站点Logo
  description?: string;        // Site description | 站点描述
  type: SiteType;              // Site type | 站点类型
  status: SiteStatus;          // Site status | 站点状态
  url: string;                 // Site URL | 站点URL
  scriptUrl?: string;          // Script URL | 脚本URL
  jarPath?: string;            // JAR file path | JAR文件路径
  pyPath?: string;             // Python script path | Python脚本路径
  requestConfig: RequestConfig; // Request configuration | 请求配置
  searchRule: SearchRule;      // Search rule | 搜索规则
  detailRule: DetailRule;      // Detail page rule | 详情页规则
  playRule: PlayRule;          // Play rule | 播放规则
  categories?: string[];       // Category list | 分类列表
  userAgent?: string;          // User agent | 用户代理
  referer?: string;            // Referer | 引用
  homepage?: string;           // Homepage URL | 主页URL
  supportedFeatures?: string[]; // Supported features | 支持的特性
  updatedAt: number;           // Update time | 更新时间
  lastTestResult?: TestResult;
  errorCount: number;          // Error count | 错误计数
  isFavorite: boolean;         // Whether favorite | 是否已收藏
}

/**
 * Site type enum | 站点类型枚举
 */
export enum SiteType {
  JS = 'JS',
  PY = 'PY',
  JAR = 'JAR'
}

/**
 * Site status enum | 站点状态枚举
 */
export enum SiteStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  ERROR = 'ERROR',
  LOADING = 'LOADING'
}

/**
 * Request configuration | 请求配置
 */
export interface RequestConfig {
  timeout: number;             // Timeout (seconds) | 超时时间（秒）
  retryCount: number;          // Retry count | 重试次数
  headers: Record<string, string>; // Request headers | 请求头
  userAgent: string;           // User-Agent
  referer?: string;            // Referer
  cookies?: string;            // Cookies
}

/**
 * Search rule | 搜索规则
 */
export interface SearchRule {
  url: string;                 // Search URL | 搜索URL
  keywordField: string;        // Keyword field name | 关键词字段名
  method: string;              // Request method | 请求方法
  dataFormat?: string;         // Data format | 数据格式
}

/**
 * Detail page rule | 详情页规则
 */
export interface DetailRule {
  urlPattern: string;          // URL pattern | URL模板
  titleSelector?: string;      // Title selector | 标题选择器
  coverSelector?: string;      // Cover selector | 封面选择器
  descSelector?: string;       // Description selector | 描述选择器
  playListSelector?: string;   // Playlist selector | 播放列表选择器
}

/**
 * Play rule | 播放规则
 */
export interface PlayRule {
  urlPattern: string;          // URL pattern | URL模板
  playUrlExtractor?: string;   // Play URL extractor | 播放地址提取器
  headers?: Record<string, string>; // Play request headers | 播放请求头
}

/**
 * Config error information interface | 配置错误信息接口
 */
export interface ConfigError {
  field: string;
  message: string;
}

/**
 * Config warning information interface | 配置警告信息接口
 */
export interface ConfigWarning {
  field: string;
  message: string;
}

/**
 * Config suggestion information interface | 配置建议信息接口
 */
export interface ConfigSuggestion {
  field: string;
  value: string | number | boolean | null;
  reason: string;
}

/**
 * Config validation result interface | 配置验证结果接口
 */
export interface ConfigValidationResult {
  valid: boolean;                    // Whether valid | 是否有效
  errors?: ConfigError[];
  warnings?: ConfigWarning[];
  suggestions?: ConfigSuggestion[];
}
