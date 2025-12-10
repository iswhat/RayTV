// Config.ets - 配置信息数据模型
// 定义应用全局配置的数据结�?
/**
 * 播放器配置接�? */
export interface PlayerConfig {
  defaultPlayer: 'system' | 'custom'; // 默认播放�?  enableHardwareDecode: boolean;     // 启用硬件解码
  autoContinuePlay: boolean;         // 自动续播
  rememberPosition: boolean;         // 记住播放位置
  speedList: number[];               // 播放速度列表
  defaultSpeed: number;              // 默认播放速度
  enableHDR: boolean;                // 启用HDR
  enableDolby: boolean;              // 启用杜比音效
  autoPlayNext: boolean;             // 自动播放下一�?  defaultResolution?: string;        // 默认分辨�?  aspectRatio: 'auto' | '16:9' | '4:3' | 'custom'; // 画面比例
  subtitlesEnabled: boolean;         // 启用字幕
  defaultSubtitleLanguage?: string;  // 默认字幕语言
  defaultAudioTrack?: string;        // 默认音轨
  backgroundPlay: boolean;           // 后台播放
  playMode: 'single' | 'loop' | 'shuffle'; // 播放模式
  networkBufferSize?: number;        // 网络缓冲大小（MB�?  localBufferSize?: number;          // 本地缓冲大小（MB�?  seekStepForward: number;           // 快进步长（秒�?  seekStepBackward: number;          // 快退步长（秒�?}

/**
 * 显示配置接口
 */
export interface DisplayConfig {
  theme: 'light' | 'dark' | 'system'; // 主题
  fontSize: number;                  // 字体大小
  autoFullScreen: boolean;           // 自动全屏
  enableGestures: boolean;           // 启用手势
  animationEnabled: boolean;         // 启用动画
  transitionSpeed: 'slow' | 'normal' | 'fast'; // 过渡速度
  showFPS: boolean;                  // 显示FPS
  showNetworkSpeed: boolean;         // 显示网�?  showTimeCode: boolean;             // 显示时间�?  maxColumns: number;                // 最大列�?  posterAspectRatio: 'auto' | '2:3' | '3:4' | '16:9'; // 海报比例
  hideNavOnPlay: boolean;            // 播放时隐藏导航栏
  screenSaverDelay?: number;         // 屏幕保护延迟（分钟）
  colorPrimary?: string;             // 主题�?  colorAccent?: string;              // 强调�?  customStyles?: Map<string, string | number | boolean>;   // 自定义样�?  tvMode: boolean;                   // TV模式
  tabletMode: boolean;               // 平板模式
  phoneMode: boolean;                // 手机模式
}

/**
 * 网络配置接口
 */
export interface NetworkConfig {
  timeout: number;                   // 超时时间（秒�?  retryCount: number;                // 重试次数
  enableCache: boolean;              // 启用缓存
  cacheSize: number;                 // 缓存大小（MB�?  maxConcurrentRequests: number;     // 最大并发请求数
  connectionTimeout: number;         // 连接超时（秒�?  readTimeout: number;               // 读取超时（秒�?  writeTimeout: number;              // 写入超时（秒�?  enableProxy: boolean;              // 启用代理
  proxyServer?: string;              // 代理服务�?  proxyPort?: number;                // 代理端口
  userAgent?: string;                // 自定义User-Agent
  enableDNSCache: boolean;           // 启用DNS缓存
  dnsCacheTime?: number;             // DNS缓存时间（分钟）
  enableHttp2: boolean;              // 启用HTTP/2
  enableCompression: boolean;        // 启用压缩
  allowInsecureConnections: boolean; // 允许不安全连�?  certificate?: string;              // 自定义证�?}

/**
 * 内容限制配置接口
 */
export interface ContentRestrictions {
  enabled: boolean;
  rating?: string;
  password?: string;
}

/**
 * 安全配置接口
 */
export interface SecurityConfig {
  enableSandbox: boolean;            // 启用沙箱
  allowThirdParty: boolean;          // 允许第三方JAR加载
  dataEncryption: boolean;           // 数据加密
  requireBiometricAuth: boolean;     // 生物识别认证
  appLockEnabled: boolean;           // 应用�?  appLockTimeout?: number;           // 应用锁超时（分钟�?  autoClearCacheOnExit: boolean;     // 退出时自动清除缓存
  privateMode: boolean;              // 隐私模式
  hideSensitiveInfo: boolean;        // 隐藏敏感信息
  enableAntiCheat: boolean;          // 启用反作�?  safeBrowsingEnabled: boolean;      // 安全浏览
  contentRestrictions?: ContentRestrictions;
}

/**
 * 广告屏蔽配置接口
 */
export interface AdBlockConfig {
  enabled: boolean;                  // 启用广告屏蔽
  rules: string[];                   // 屏蔽规则
  updateInterval: number;            // 更新间隔（小时）
  blockVideoAds: boolean;            // 屏蔽视频广告
  blockPopupAds: boolean;            // 屏蔽弹窗广告
  customFilters?: string[];          // 自定义过滤规�?  filterLists?: string[];            // 过滤规则列表URL
  whitelist?: string[];              // 白名�?  lastUpdateTime?: number;           // 最后更新时�?}

/**
 * 鸿蒙特有配置接口
 */
export interface HarmonyConfig {
  enableVoiceAssistant: boolean;     // 启用语音助手
  enableDeviceFlow: boolean;         // 启用设备流转
  enableGestureControl: boolean;     // 启用手势控制
  enableWidget: boolean;             // 启用桌面小组�?  enableNotification: boolean;       // 启用通知
  enableAutoStart: boolean;          // 启用自启�?  enableBackgroundSync: boolean;     // 启用后台同步
  enableMultiWindow: boolean;        // 启用多窗�?  enableHiAI: boolean;               // 启用HiAI加�?  enableSuperDevice: boolean;        // 启用超级终端
  deviceSharingEnabled: boolean;     // 设备共享
  notificationChannels?: string[];   // 通知渠道
  quickActions?: string[];           // 快捷操作
}

/**
 * 搜索配置接口
 */
export interface SearchConfig {
  enableAutoSuggest: boolean;        // 启用自动建议
  searchHistoryLimit: number;        // 搜索历史限制
  enableGlobalSearch: boolean;       // 启用全局搜索
  searchTimeout: number;             // 搜索超时（秒�?  searchDelay: number;               // 搜索延迟（毫秒）
  defaultSearchFilter?: string;      // 默认搜索筛�?  searchHighlight: boolean;          // 搜索结果高亮
  enableSearchAnalytics: boolean;    // 启用搜索分析
}

/**
 * 下载配置接口
 */
export interface DownloadConfig {
  enableDownload: boolean;           // 启用下载
  maxConcurrentDownloads: number;    // 最大并发下载数
  downloadPath?: string;             // 下载路径
  autoDownloadNextEpisode: boolean;  // 自动下载下一�?  downloadOnWifiOnly: boolean;       // 仅WiFi下载
  downloadQuality?: string;          // 下载质量
  enableDownloadQueue: boolean;      // 启用下载队列
  downloadTimeout: number;           // 下载超时（秒�?  enableBackgroundDownload: boolean; // 启用后台下载
}

/**
 * 云账户配置接�? */
export interface CloudAccount {
  type: string;
  username?: string;
  token?: string;
  lastSyncTime?: number;
}

/**
 * 同步配置接口
 */
export interface SyncConfig {
  enableCloudSync: boolean;          // 启用云同�?  syncInterval: number;              // 同步间隔（分钟）
  syncOnWifiOnly: boolean;           // 仅WiFi同步
  syncHistory: boolean;              // 同步历史记录
  syncFavorites: boolean;            // 同步收藏
  syncSettings: boolean;             // 同步设置
  autoBackup: boolean;               // 自动备份
  backupInterval?: number;           // 备份间隔（天�?  cloudAccount?: CloudAccount;
}

/**
 * 日志配置接口
 */
export interface LogConfig {
  enableLogging: boolean;            // 启用日志
  logLevel: 'debug' | 'info' | 'warn' | 'error'; // 日志级别
  logToFile: boolean;                // 记录到文�?  maxLogSize?: number;               // 最大日志大小（MB�?  logRetentionDays?: number;         // 日志保留天数
  enableAnalytics: boolean;          // 启用分析
  crashReporting: boolean;           // 崩溃报告
}

/**
 * 应用配置主接�? */
export interface AppConfig {
  player: PlayerConfig;              // 播放器配�?  display: DisplayConfig;            // 显示配置
  network: NetworkConfig;            // 网络配置
  security: SecurityConfig;          // 安全配置
  adBlock: AdBlockConfig;            // 广告屏蔽配置
  harmony: HarmonyConfig;            // 鸿蒙特有配置
  search: SearchConfig;              // 搜索配置
  download: DownloadConfig;          // 下载配置
  sync: SyncConfig;                  // 同步配置
  log: LogConfig;                    // 日志配置
  version: string;                   // 配置版本
  lastUpdated: number;               // 最后更新时�?  migrationVersion?: string;         // 迁移版本
  customSettings?: Map<string, string | number | boolean>; // 自定义设�?}

/**
 * 配置版本信息接口
 */
export interface ConfigVersion {
  version: string;                   // 版本�?  buildTime: number;                 // 构建时间
  minAppVersion: string;             // 最低应用版�?  changelog?: string;                // 更新日志
}

/**
 * 配置变更记录接口
 */
export interface ConfigChange {
  keyPath: string;                   // 配置路径
  oldValue: string | number | boolean | null; // 旧�?  newValue: string | number | boolean | null; // 新�?  changedAt: number;                 // 变更时间
  changedBy: 'user' | 'system' | 'sync'; // 变更来源
}

/**
 * 配置预设接口
 */
export interface ConfigPreset {
  id: string;                        // 预设ID
  name: string;                      // 预设名称
  description?: string;              // 描述
  config: Partial<AppConfig>;        // 预设配置
  isDefault?: boolean;               // 是否默认预设
  deviceType?: string;               // 适用设备类型
  tags?: string[];                   // 标签
}

/**
 * 配置导入导出选项接口
 */
export interface ConfigImportExportOptions {
  includeCredentials?: boolean;      // 包含凭证
  includeHistory?: boolean;          // 包含历史记录
  includeFavorites?: boolean;        // 包含收藏
  format: 'json' | 'encrypted';      // 格式
  password?: string;                 // 密码
  description?: string;              // 描述
}

/**
 * 站点配置集合接口
 */
export interface SiteCollection {
  sites: SiteInfo[];           // 站点列表
  version: string;             // 版本�?  updatedAt: number;           // 更新时间
}

/**
 * 站点配置验证结果接口
 */
export interface SiteValidationResult {
  isValid: boolean;            // 是否有效
  errors?: string[];           // 错误列表
  warnings?: string[];         // 警告列表
}

/**
 * 测试结果接口
 */
export interface TestResult {
  success: boolean;          // 测试是否成功
  message?: string;          // 测试消息
  timestamp: number;         // 测试时间
}

/**
 * 站点信息接口
 */
export interface SiteInfo {
  id: string;                  // 站点唯一标识
  key: string;                 // 站点键名
  name: string;                // 站点名称
  logo?: string;               // 站点Logo
  description?: string;        // 站点描述
  type: SiteType;              // 站点类型
  status: SiteStatus;          // 站点状�?  url: string;                 // 站点URL
  scriptUrl?: string;          // 脚本URL
  jarPath?: string;            // JAR文件路径
  pyPath?: string;             // Python脚本路径
  requestConfig: RequestConfig; // 请求配置
  searchRule: SearchRule;      // 搜索规则
  detailRule: DetailRule;      // 详情页规�?  playRule: PlayRule;          // 播放规则
  categories?: string[];       // 分类列表
  userAgent?: string;          // 用户代理
  referer?: string;            // 引用�?  homepage?: string;           // 首页URL
  supportedFeatures?: string[]; // 支持的特�?  updatedAt: number;           // 更新时间
  lastTestResult?: TestResult;
  errorCount: number;          // 错误计数
  isFavorite: boolean;         // 是否收藏
}

/**
 * 站点类型枚举
 */
export enum SiteType {
  JS = 'JS',
  PY = 'PY',
  JAR = 'JAR'
}

/**
 * 站点状态枚�? */
export enum SiteStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  ERROR = 'ERROR',
  LOADING = 'LOADING'
}

/**
 * 请求配置
 */
export interface RequestConfig {
  timeout: number;             // 超时时间（秒�?  retryCount: number;          // 重试次数
  headers: Record<string, string>; // 请求�?  userAgent: string;           // User-Agent
  referer?: string;            // Referer
  cookies?: string;            // Cookies
}

/**
 * 搜索规则
 */
export interface SearchRule {
  url: string;                 // 搜索URL
  keywordField: string;        // 关键词字段名
  method: string;              // 请求方法
  dataFormat?: string;         // 数据格式
}

/**
 * 详情页规�? */
export interface DetailRule {
  urlPattern: string;          // URL模式
  titleSelector?: string;      // 标题选择�?  coverSelector?: string;      // 封面选择�?  descSelector?: string;       // 描述选择�?  playListSelector?: string;   // 播放列表选择�?}

/**
 * 播放规则
 */
export interface PlayRule {
  urlPattern: string;          // URL模式
  playUrlExtractor?: string;   // 播放地址提取�?  headers?: Record<string, string>; // 播放请求�?}

/**
 * 配置错误信息接口
 */
export interface ConfigError {
  field: string;
  message: string;
}

/**
 * 配置警告信息接口
 */
export interface ConfigWarning {
  field: string;
  message: string;
}

/**
 * 配置建议信息接口
 */
export interface ConfigSuggestion {
  field: string;
  value: string | number | boolean | null;
  reason: string;
}

/**
 * 配置验证结果接口
 */
export interface ConfigValidationResult {
  valid: boolean;                    // 是否有效
  errors?: ConfigError[];
  warnings?: ConfigWarning[];
  suggestions?: ConfigSuggestion[];
}
