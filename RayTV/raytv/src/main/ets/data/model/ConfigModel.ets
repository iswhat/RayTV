// ConfigModel - 配置相关模型定义
// 定义应用配置、用户设置等相关的数据模�?
/**
 * 配置类型枚举
 */
export enum ConfigType {
  /**
   * 应用配置
   */
  APP = 'app',
  
  /**
   * 用户配置
   */
  USER = 'user',
  
  /**
   * 播放器配�?   */
  PLAYER = 'player',
  
  /**
   * 网络配置
   */
  NETWORK = 'network',
  
  /**
   * 下载配置
   */
  DOWNLOAD = 'download',
  
  /**
   * 字幕配置
   */
  SUBTITLE = 'subtitle',
  
  /**
   * 直播配置
   */
  LIVE = 'live',
  
  /**
   * 界面配置
   */
  UI = 'ui',
  
  /**
   * 高级配置
   */
  ADVANCED = 'advanced',
  
  /**
   * 开发配�?   */
  DEV = 'dev'
}

/**
 * 配置项接�? */
export interface ConfigItem {
  /**
   * 配置键名
   */
  key: string;
  
  /**
   * 配置�?   */
  value: Record<string, string | number | boolean | null>;
  
  /**
   * 配置类型
   */
  type: ConfigType;
  
  /**
   * 配置描述
   */
  description?: string;
  
  /**
   * 默认�?   */
  defaultValue: Record<string, string | number | boolean | null>;
  
  /**
   * 数据类型
   */
  dataType: 'string' | 'number' | 'boolean' | 'object' | 'array';
  
  /**
   * 是否可编�?   */
  editable: boolean;
  
  /**
   * 是否加密存储
   */
  encrypted: boolean;
  
  /**
   * 最后更新时�?   */
  lastUpdatedAt: number;
  
  /**
   * 创建时间
   */
  createdAt?: number;
  
  /**
   * 版本�?   */
  version?: string;
  
  /**
   * 是否需要重启应用生�?   */
  requiresRestart: boolean;
}

/**
 * 配置分组接口
 */
export interface ConfigGroup {
  /**
   * 分组名称
   */
  name: string;
  
  /**
   * 分组类型
   */
  type: ConfigType;
  
  /**
   * 分组描述
   */
  description?: string;
  
  /**
   * 配置项列�?   */
  items: ConfigItem[];
  
  /**
   * 是否可折�?   */
  collapsible: boolean;
  
  /**
   * 优先�?   */
  priority: number;
  
  /**
   * 是否隐藏
   */
  hidden: boolean;
}

/**
 * 配置元数据接�? */
export interface ConfigMetadata {
  /**
   * 配置版本
   */
  version: string;
  
  /**
   * 最后同步时�?   */
  lastSyncTime: number;
  
  /**
   * 创建时间
   */
  createdAt: number;
  
  /**
   * 最后更新时�?   */
  updatedAt: number;
  
  /**
   * 是否自动备份
   */
  autoBackupEnabled: boolean;
  
  /**
   * 备份频率（天�?   */
  backupFrequencyDays: number;
  
  /**
   * 配置来源
   */
  source: 'default' | 'user' | 'import' | 'cloud' | 'preset';
}

/**
 * 应用配置接口
 */
export interface AppConfig {
  /**
   * 是否首次启动
   */
  isFirstLaunch: boolean;
  
  /**
   * 当前语言
   */
  language: string;
  
  /**
   * 主题模式
   */
  themeMode: 'light' | 'dark' | 'auto';
  
  /**
   * 是否启用通知
   */
  notificationsEnabled: boolean;
  
  /**
   * 是否启用数据收集
   */
  dataCollectionEnabled: boolean;
  
  /**
   * 启动时恢复上次播�?   */
  resumePlaybackOnStart: boolean;
  
  /**
   * 自动检查更�?   */
  autoCheckUpdates: boolean;
  
  /**
   * 应用版本
   */
  appVersion: string;
  
  /**
   * 构建版本
   */
  buildVersion: string;
}

/**
 * 播放器配置接�? */
export interface PlayerConfig {
  /**
   * 默认播放引擎
   */
  defaultEngine: 'system' | 'exo' | 'custom';
  
  /**
   * 硬件加�?   */
  hardwareAcceleration: boolean;
  
  /**
   * 默认音量
   */
  defaultVolume: number;
  
  /**
   * 默认亮度
   */
  defaultBrightness: number;
  
  /**
   * 自动播放下一�?   */
  autoPlayNextEpisode: boolean;
  
  /**
   * 播放速度
   */
  playbackSpeed: number;
  
  /**
   * 视频比例
   */
  aspectRatio: 'original' | 'fit' | 'fill' | '16:9' | '4:3';
  
  /**
   * 字幕自动加载
   */
  autoLoadSubtitles: boolean;
  
  /**
   * 音频延迟调整（毫秒）
   */
  audioDelay: number;
  
  /**
   * 字幕延迟调整（毫秒）
   */
  subtitleDelay: number;
  
  /**
   * 预加载时间（秒）
   */
  preloadTime: number;
}

/**
 * 网络配置接口
 */
export interface NetworkConfig {
  /**
   * 超时设置（毫秒）
   */
  timeout: number;
  
  /**
   * 重试次数
   */
  retryCount: number;
  
  /**
   * 代理设置
   */
  proxySettings: ProxyConfig;
  
  /**
   * 缓存大小（MB�?   */
  cacheSize: number;
  
  /**
   * 最大并发连接数
   */
  maxConcurrentConnections: number;
  
  /**
   * 启用HTTP/2
   */
  enableHttp2: boolean;
  
  /**
   * 启用DNS缓存
   */
  enableDnsCache: boolean;
  
  /**
   * DNS服务器地址
   */
  dnsServer?: string;
  
  /**
   * 自定义User-Agent
   */
  customUserAgent?: string;
}

/**
 * 代理配置接口
 */
export interface ProxyConfig {
  /**
   * 是否启用代理
   */
  enabled: boolean;
  
  /**
   * 代理类型
   */
  type: 'http' | 'https' | 'socks5' | 'none';
  
  /**
   * 代理服务器地址
   */
  host?: string;
  
  /**
   * 代理端口
   */
  port?: number;
  
  /**
   * 需要认�?   */
  requiresAuth: boolean;
  
  /**
   * 用户�?   */
  username?: string;
  
  /**
   * 密码
   */
  password?: string;
  
  /**
   * 不使用代理的主机列表
   */
  bypassList?: string[];
}

/**
 * 下载配置接口
 */
export interface DownloadConfig {
  /**
   * 下载目录
   */
  downloadDir: string;
  
  /**
   * 最大并发下载数
   */
  maxConcurrentDownloads: number;
  
  /**
   * 最大下载速度（KB/s�?表示不限�?   */
  maxDownloadSpeed: number;
  
  /**
   * 是否允许移动网络下载
   */
  allowMobileDownload: boolean;
  
  /**
   * 下载前确�?   */
  confirmBeforeDownload: boolean;
  
  /**
   * 下载完成后通知
   */
  notifyOnCompletion: boolean;
  
  /**
   * 是否自动管理存储空间
   */
  autoManageStorage: boolean;
  
  /**
   * 最大存储空间（GB�?   */
  maxStorageSize: number;
  
  /**
   * 清理策略
   */
  cleanupStrategy: 'oldest_first' | 'largest_first' | 'never';
}

/**
 * 字幕配置接口
 */
export interface SubtitleConfig {
  /**
   * 默认字幕语言
   */
  defaultLanguage: string;
  
  /**
   * 字幕样式
   */
  style: SubtitleStyle;
  
  /**
   * 字幕编码
   */
  encoding: string;
  
  /**
   * 字幕延迟调整（毫秒）
   */
  delay: number;
  
  /**
   * 自动加载字幕
   */
  autoLoad: boolean;
  
  /**
   * 字幕字体
   */
  fontFamily: string;
  
  /**
   * 字幕目录
   */
  subtitleDir: string;
  
  /**
   * 字幕扩展名映�?   */
  extensionMapping?: Record<string, string>;
}

/**
 * 字幕样式接口
 */
export interface SubtitleStyle {
  /**
   * 字体大小
   */
  fontSize: number;
  
  /**
   * 字体颜色
   */
  fontColor: string;
  
  /**
   * 背景颜色
   */
  backgroundColor: string;
  
  /**
   * 文字描边颜色
   */
  strokeColor: string;
  
  /**
   * 文字描边宽度
   */
  strokeWidth: number;
  
  /**
   * 透明�?   */
  opacity: number;
  
  /**
   * 文字阴影
   */
  shadow: boolean;
  
  /**
   * 位置
   */
  position: 'top' | 'bottom' | 'center';
  
  /**
   * 对齐方式
   */
  alignment: 'left' | 'center' | 'right';
}

/**
 * 界面配置接口
 */
export interface UiConfig {
  /**
   * 主题颜色
   */
  themeColor: string;
  
  /**
   * 强调颜色
   */
  accentColor: string;
  
  /**
   * 字体大小
   */
  fontSize: 'small' | 'medium' | 'large';
  
  /**
   * 界面缩放
   */
  uiScale: number;
  
  /**
   * 动画效果
   */
  animationsEnabled: boolean;
  
  /**
   * 过渡动画时长
   */
  transitionDuration: number;
  
  /**
   * 是否显示缩略�?   */
  showThumbnails: boolean;
  
  /**
   * 缩略图质�?   */
  thumbnailQuality: 'low' | 'medium' | 'high';
  
  /**
   * 首页布局
   */
  homeLayout: 'grid' | 'list' | 'mixed';
  
  /**
   * 内容网格列数
   */
  gridColumns: number;
}

/**
 * 高级配置接口
 */
export interface AdvancedConfig {
  /**
   * 启用日志
   */
  enableLogging: boolean;
  
  /**
   * 日志级别
   */
  logLevel: 'debug' | 'info' | 'warn' | 'error';
  
  /**
   * 启用调试模式
   */
  debugMode: boolean;
  
  /**
   * 启用性能监控
   */
  performanceMonitoring: boolean;
  
  /**
   * 自定义渲染器
   */
  customRendererEnabled: boolean;
  
  /**
   * 渲染器路�?   */
  rendererPath?: string;
  
  /**
   * 后台缓存
   */
  backgroundCaching: boolean;
  
  /**
   * 最大后台任务数
   */
  maxBackgroundTasks: number;
}

/**
 * 预设配置接口
 */
export interface PresetConfig {
  /**
   * 预设名称
   */
  name: string;
  
  /**
   * 预设描述
   */
  description?: string;
  
  /**
   * 预设配置�?   */
  config: Record<string, unknown>;
  
  /**
   * 是否为默认预�?   */
  isDefault: boolean;
  
  /**
   * 是否可编�?   */
  editable: boolean;
  
  /**
   * 创建时间
   */
  createdAt: number;
}

/**
 * 配置导入导出选项接口
 */
export interface ConfigImportExportOptions {
  /**
   * 包含的配置类�?   */
  includeTypes: ConfigType[];
  
  /**
   * 排除的配置键
   */
  excludeKeys?: string[];
  
  /**
   * 是否加密
   */
  encrypted: boolean;
  
  /**
   * 密码
   */
  password?: string;
  
  /**
   * 是否压缩
   */
  compressed: boolean;
  
  /**
   * 导出格式
   */
  format: 'json' | 'xml' | 'binary';
}

/**
 * 配置变更事件接口
 */
export interface ConfigChangeEvent {
  /**
   * 配置�?   */
  key: string;
  
  /**
   * 旧�?   */
  oldValue: Record<string, string | number | boolean | null>;
  
  /**
   * 新�?   */
  newValue: Record<string, string | number | boolean | null>;
  
  /**
   * 变更时间
   */
  timestamp: number;
  
  /**
   * 变更类型
   */
  type: ConfigType;
}

/**
 * 配置验证结果接口
 */
export interface ConfigValidationResult {
  /**
   * 是否有效
   */
  isValid: boolean;
  
  /**
   * 错误信息
   */
  errorMessage?: string;
  
  /**
   * 无效的配置键
   */
  invalidKeys: string[];
  
  /**
   * 警告信息
   */
  warnings: string[];
}

