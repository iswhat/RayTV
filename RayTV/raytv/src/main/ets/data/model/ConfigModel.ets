// ConfigModel - 配置相关类型定义 | Config-related type definitions
// 定义应用配置、用户设置等相关的数据类型 | Define data types related to app configuration and user settings

/**
 * 配置类型枚举 | Config type enum
 */
export enum ConfigType {
  /**
   * 应用配置 | App configuration
   */
  APP = 'app',
  
  /**
   * 用户配置 | User configuration
   */
  USER = 'user',
  
  /**
   * 播放器配置 | Player configuration
   */
  PLAYER = 'player',
  
  /**
   * 网络配置 | Network configuration
   */
  NETWORK = 'network',
  
  /**
   * 下载配置 | Download configuration
   */
  DOWNLOAD = 'download',
  
  /**
   * 字幕配置 | Subtitle configuration
   */
  SUBTITLE = 'subtitle',
  
  /**
   * 直播配置 | Live configuration
   */
  LIVE = 'live',
  
  /**
   * 界面配置 | UI configuration
   */
  UI = 'ui',
  
  /**
   * 高级配置 | Advanced configuration
   */
  ADVANCED = 'advanced',
  
  /**
   * 开发配置 | Development configuration
   */
  DEV = 'dev'
}

/**
 * 配置项接口 | Config item interface
 */
export interface ConfigItem {
  /**
   * 配置键名 | Config key
   */
  key: string;
  
  /**
   * 配置值 | Config value
   */
  value: Record<string, string | number | boolean | null>;
  
  /**
   * 配置类型 | Config type
   */
  type: ConfigType;
  
  /**
   * 配置描述 | Config description
   */
  description?: string;
  
  /**
   * 默认值 | Default value
   */
  defaultValue: Record<string, string | number | boolean | null>;
  
  /**
   * 数据类型 | Data type
   */
  dataType: 'string' | 'number' | 'boolean' | 'object' | 'array';
  
  /**
   * 是否可编辑 | Whether editable
   */
  editable: boolean;
  
  /**
   * 是否加密存储 | Whether encrypted storage
   */
  encrypted: boolean;
  
  /**
   * 最后更新时间 | Last updated time
   */
  lastUpdatedAt: number;
  
  /**
   * 创建时间 | Creation time
   */
  createdAt?: number;
  
  /**
   * 版本号 | Version number
   */
  version?: string;
  
  /**
   * 是否需要重启应用生效 | Whether requires app restart to take effect
   */
  requiresRestart: boolean;
}

/**
 * 配置分组接口 | Config group interface
 */
export interface ConfigGroup {
  /**
   * 分组名称 | Group name
   */
  name: string;
  
  /**
   * 分组类型 | Group type
   */
  type: ConfigType;
  
  /**
   * 分组描述 | Group description
   */
  description?: string;
  
  /**
   * 配置项列表 | Config item list
   */
  items: ConfigItem[];
  
  /**
   * 是否可折叠 | Whether collapsible
   */
  collapsible: boolean;
  
  /**
   * 优先级 | Priority
   */
  priority: number;
  
  /**
   * 是否隐藏 | Whether hidden
   */
  hidden: boolean;
}

/**
 * 配置元数据接口 | Config metadata interface
 */
export interface ConfigMetadata {
  /**
   * 配置版本 | Config version
   */
  version: string;
  
  /**
   * 最后同步时间 | Last sync time
   */
  lastSyncTime: number;
  
  /**
   * 创建时间 | Creation time
   */
  createdAt: number;
  
  /**
   * 最后更新时间 | Last updated time
   */
  updatedAt: number;
  
  /**
   * 是否自动备份 | Whether auto backup enabled
   */
  autoBackupEnabled: boolean;
  
  /**
   * 备份频率（天） | Backup frequency (days)
   */
  backupFrequencyDays: number;
  
  /**
   * 配置来源 | Config source
   */
  source: 'default' | 'user' | 'import' | 'cloud' | 'preset';
}

/**
 * 应用配置接口 | App configuration interface
 */
export interface AppConfig {
  /**
   * 是否首次启动 | Whether first launch
   */
  isFirstLaunch: boolean;
  
  /**
   * 当前语言 | Current language
   */
  language: string;
  
  /**
   * 主题模式 | Theme mode
   */
  themeMode: 'light' | 'dark' | 'auto';
  
  /**
   * 是否启用通知 | Whether notifications enabled
   */
  notificationsEnabled: boolean;
  
  /**
   * 是否启用数据收集 | Whether data collection enabled
   */
  dataCollectionEnabled: boolean;
  
  /**
   * 启动时恢复上次播放 | Resume playback on start
   */
  resumePlaybackOnStart: boolean;
  
  /**
   * 自动检查更新 | Auto check updates
   */
  autoCheckUpdates: boolean;
  
  /**
   * 应用版本 | App version
   */
  appVersion: string;
  
  /**
   * 构建版本 | Build version
   */
  buildVersion: string;
}

/**
 * 播放器配置接口 | Player configuration interface
 */
export interface PlayerConfig {
  /**
   * 默认播放引擎 | Default playback engine
   */
  defaultEngine: 'system' | 'exo' | 'custom';
  
  /**
   * 硬件加速 | Hardware acceleration
   */
  hardwareAcceleration: boolean;
  
  /**
   * 默认音量 | Default volume
   */
  defaultVolume: number;
  
  /**
   * 默认亮度 | Default brightness
   */
  defaultBrightness: number;
  
  /**
   * 自动播放下一集 | Auto play next episode
   */
  autoPlayNextEpisode: boolean;
  
  /**
   * 播放速度 | Playback speed
   */
  playbackSpeed: number;
  
  /**
   * 视频比例 | Aspect ratio
   */
  aspectRatio: 'original' | 'fit' | 'fill' | '16:9' | '4:3';
  
  /**
   * 字幕自动加载 | Auto load subtitles
   */
  autoLoadSubtitles: boolean;
  
  /**
   * 音频延迟调整（毫秒） | Audio delay adjustment (milliseconds)
   */
  audioDelay: number;
  
  /**
   * 字幕延迟调整（毫秒） | Subtitle delay adjustment (milliseconds)
   */
  subtitleDelay: number;
  
  /**
   * 预加载时间（秒） | Preload time (seconds)
   */
  preloadTime: number;
}

/**
 * 网络配置接口 | Network configuration interface
 */
export interface NetworkConfig {
  /**
   * 超时设置（秒） | Timeout setting (seconds)
   */
  timeout: number;
  
  /**
   * 重试次数 | Retry count
   */
  retryCount: number;
  
  /**
   * 代理设置 | Proxy settings
   */
  proxySettings: ProxyConfig;
  
  /**
   * 缓存大小（MB） | Cache size (MB)
   */
  cacheSize: number;
  
  /**
   * 最大并发连接数 | Maximum concurrent connections
   */
  maxConcurrentConnections: number;
  
  /**
   * 启用HTTP/2 | Enable HTTP/2
   */
  enableHttp2: boolean;
  
  /**
   * 启用DNS缓存 | Enable DNS cache
   */
  enableDnsCache: boolean;
  
  /**
   * DNS服务器地址 | DNS server address
   */
  dnsServer?: string;
  
  /**
   * 自定义User-Agent | Custom User-Agent
   */
  customUserAgent?: string;
}

/**
 * 代理配置接口 | Proxy configuration interface
 */
export interface ProxyConfig {
  /**
   * 是否启用代理 | Whether proxy enabled
   */
  enabled: boolean;
  
  /**
   * 代理类型 | Proxy type
   */
  type: 'http' | 'https' | 'socks5' | 'none';
  
  /**
   * 代理服务器地址 | Proxy server address
   */
  host?: string;
  
  /**
   * 代理端口 | Proxy port
   */
  port?: number;
  
  /**
   * 需要认证 | Whether authentication required
   */
  requiresAuth: boolean;
  
  /**
   * 用户名 | Username
   */
  username?: string;
  
  /**
   * 密码 | Password
   */
  password?: string;
  
  /**
   * 不使用代理的域名列表 | Domain list to bypass proxy
   */
  bypassList?: string[];
}

/**
 * 下载配置接口 | Download configuration interface
 */
export interface DownloadConfig {
  /**
   * 下载目录 | Download directory
   */
  downloadDir: string;
  
  /**
   * 最大并发下载数 | Maximum concurrent downloads
   */
  maxConcurrentDownloads: number;
  
  /**
   * 最大下载速度（KB/s，0表示不限） | Maximum download speed (KB/s, 0 for unlimited)
   */
  maxDownloadSpeed: number;
  
  /**
   * 是否允许移动网络下载 | Whether allow mobile network download
   */
  allowMobileDownload: boolean;
  
  /**
   * 下载前确认 | Confirm before download
   */
  confirmBeforeDownload: boolean;
  
  /**
   * 下载完成后通知 | Notify on completion
   */
  notifyOnCompletion: boolean;
  
  /**
   * 是否自动管理存储空间 | Whether auto manage storage
   */
  autoManageStorage: boolean;
  
  /**
   * 最大存储空间（GB） | Maximum storage size (GB)
   */
  maxStorageSize: number;
  
  /**
   * 清理策略 | Cleanup strategy
   */
  cleanupStrategy: 'oldest_first' | 'largest_first' | 'never';
}

/**
 * 字幕配置接口 | Subtitle configuration interface
 */
export interface SubtitleConfig {
  /**
   * 默认字幕语言 | Default subtitle language
   */
  defaultLanguage: string;
  
  /**
   * 字幕样式 | Subtitle style
   */
  style: SubtitleStyle;
  
  /**
   * 字幕编码 | Subtitle encoding
   */
  encoding: string;
  
  /**
   * 字幕延迟调整（毫秒） | Subtitle delay adjustment (milliseconds)
   */
  delay: number;
  
  /**
   * 自动加载字幕 | Auto load subtitles
   */
  autoLoad: boolean;
  
  /**
   * 字幕字体 | Subtitle font family
   */
  fontFamily: string;
  
  /**
   * 字幕目录 | Subtitle directory
   */
  subtitleDir: string;
  
  /**
   * 字幕扩展名映射 | Subtitle extension mapping
   */
  extensionMapping?: Record<string, string>;
}

/**
 * 字幕样式接口 | Subtitle style interface
 */
export interface SubtitleStyle {
  /**
   * 字体大小 | Font size
   */
  fontSize: number;
  
  /**
   * 字体颜色 | Font color
   */
  fontColor: string;
  
  /**
   * 背景颜色 | Background color
   */
  backgroundColor: string;
  
  /**
   * 文字描边颜色 | Text stroke color
   */
  strokeColor: string;
  
  /**
   * 文字描边宽度 | Text stroke width
   */
  strokeWidth: number;
  
  /**
   * 透明度 | Opacity
   */
  opacity: number;
  
  /**
   * 文字阴影 | Text shadow
   */
  shadow: boolean;
  
  /**
   * 位置 | Position
   */
  position: 'top' | 'bottom' | 'center';
  
  /**
   * 对齐方式 | Alignment
   */
  alignment: 'left' | 'center' | 'right';
}

/**
 * 界面配置接口 | UI configuration interface
 */
export interface UiConfig {
  /**
   * 主题颜色 | Theme color
   */
  themeColor: string;
  
  /**
   * 强调颜色 | Accent color
   */
  accentColor: string;
  
  /**
   * 字体大小 | Font size
   */
  fontSize: 'small' | 'medium' | 'large';
  
  /**
   * 界面缩放 | UI scale
   */
  uiScale: number;
  
  /**
   * 动画效果 | Animations enabled
   */
  animationsEnabled: boolean;
  
  /**
   * 过渡动画时长 | Transition duration
   */
  transitionDuration: number;
  
  /**
   * 是否显示缩略图 | Whether show thumbnails
   */
  showThumbnails: boolean;
  
  /**
   * 缩略图质量 | Thumbnail quality
   */
  thumbnailQuality: 'low' | 'medium' | 'high';
  
  /**
   * 首页布局 | Home layout
   */
  homeLayout: 'grid' | 'list' | 'mixed';
  
  /**
   * 内容网格列数 | Content grid columns
   */
  gridColumns: number;
}

/**
 * 高级配置接口 | Advanced configuration interface
 */
export interface AdvancedConfig {
  /**
   * 启用日志 | Enable logging
   */
  enableLogging: boolean;
  
  /**
   * 日志级别 | Log level
   */
  logLevel: 'debug' | 'info' | 'warn' | 'error';
  
  /**
   * 启用调试模式 | Enable debug mode
   */
  debugMode: boolean;
  
  /**
   * 启用性能监控 | Enable performance monitoring
   */
  performanceMonitoring: boolean;
  
  /**
   * 自定义渲染器 | Custom renderer enabled
   */
  customRendererEnabled: boolean;
  
  /**
   * 渲染器路径 | Renderer path
   */
  rendererPath?: string;
  
  /**
   * 后台缓存 | Background caching
   */
  backgroundCaching: boolean;
  
  /**
   * 最大后台任务数 | Maximum background tasks
   */
  maxBackgroundTasks: number;
}

/**
 * 预设配置接口 | Preset configuration interface
 */
export interface PresetConfig {
  /**
   * 预设名称 | Preset name
   */
  name: string;
  
  /**
   * 预设描述 | Preset description
   */
  description?: string;
  
  /**
   * 预设配置项 | Preset config items
   */
  config: Record<string, unknown>;
  
  /**
   * 是否为默认预设 | Whether default preset
   */
  isDefault: boolean;
  
  /**
   * 是否可编辑 | Whether editable
   */
  editable: boolean;
  
  /**
   * 创建时间 | Creation time
   */
  createdAt: number;
}

/**
 * 配置导入导出选项接口 | Config import/export options interface
 */
export interface ConfigImportExportOptions {
  /**
   * 包含的配置类型 | Included config types
   */
  includeTypes: ConfigType[];
  
  /**
   * 排除的配置键 | Excluded config keys
   */
  excludeKeys?: string[];
  
  /**
   * 是否加密 | Whether encrypted
   */
  encrypted: boolean;
  
  /**
   * 密码 | Password
   */
  password?: string;
  
  /**
   * 是否压缩 | Whether compressed
   */
  compressed: boolean;
  
  /**
   * 导出格式 | Export format
   */
  format: 'json' | 'xml' | 'binary';
}

/**
 * 配置变更事件接口 | Config change event interface
 */
export interface ConfigChangeEvent {
  /**
   * 配置键 | Config key
   */
  key: string;
  
  /**
   * 旧值 | Old value
   */
  oldValue: Record<string, string | number | boolean | null>;
  
  /**
   * 新值 | New value
   */
  newValue: Record<string, string | number | boolean | null>;
  
  /**
   * 变更时间 | Change time
   */
  timestamp: number;
  
  /**
   * 变更类型 | Change type
   */
  type: ConfigType;
}

/**
 * 配置验证结果接口 | Config validation result interface
 */
export interface ConfigValidationResult {
  /**
   * 是否有效 | Whether valid
   */
  isValid: boolean;
  
  /**
   * 错误信息 | Error message
   */
  errorMessage?: string;
  
  /**
   * 无效的配置键 | Invalid config keys
   */
  invalidKeys: string[];
  
  /**
   * 警告信息 | Warnings
   */
  warnings: string[];
}
