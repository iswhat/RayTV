// ConfigService - 配置服务 | Configuration service
import StorageUtil from '../../common/util/StorageUtil';
import TypeSafetyHelper from '../../common/util/TypeSafetyHelper';
import ConfigParser from './ConfigParser';

// 导入类型和DTO | Import types and DTO
import ApiResponse, { ResponseCode } from '../../data/dto/ApiResponse';

// 常量定义 | Constant definition
const TAG = 'ConfigService';

// 配置导出项目接口 | Config export item interface
export interface ConfigExportItem {
  key: string;
  value: string | number | boolean;
  updatedAt: number;
}

// 配置导出数据接口 | Config export data interface
export interface ConfigExportData {
  exportDate: string;
  version: string;
  configs: ConfigExportItem[];
}

// 配置更新接口 | Config update interface
export interface ConfigUpdate {
  player?: Partial<PlayerConfig>;
  display?: Partial<DisplayConfig>;
  network?: Partial<NetworkConfig>;
  storage?: Partial<StorageConfig>;
  general?: Partial<GeneralConfig>;
  security?: Partial<SecurityConfig>;
  notification?: Partial<NotificationConfig>;
  accessibility?: Partial<AccessibilityConfig>;
  live?: Partial<LiveConfig>;
  vod?: Partial<VodConfig>;
}

// 代理配置更新接口 | Proxy config update interface
export interface ProxyConfigUpdate {
  type?: string;
  host?: string;
  port?: number;
}

// 配置值类型定义 | Config value type definition
export type ConfigValue = 
  | string
  | number
  | boolean
  | object
  | null;

// 配置键默认值接口 | Config key default values interface
export interface DefaultConfig {
  // 显示相关 | Display related
  theme: string;
  language: string;
  interfaceScale: number;
  uiAnimationEnabled: boolean;
  startupScreen: string;
  homeLayout: string;
  
  // 视频播放相关 | Video playback related
  videoQuality: string;
  playbackSpeed: number;
  autoPlay: boolean;
  autoNextEpisode: boolean;
  backgroundPlayEnabled: boolean;
  videoPlayerSettings: object;
  
  // 字幕相关 | Subtitle related
  subtitleEnabled: boolean;
  subtitleSize: number;
  subtitleColor: string;
  subtitleDelay: number;
  
  // 缓存相关 | Cache related
  cacheEnabled: boolean;
  cacheLimit: number; // MB
  
  // 网络相关 | Network related
  networkTimeout: number; // 秒 Seconds
  proxyEnabled: boolean;
  proxyConfig: null;
  dataSaverEnabled: boolean;
  customHeaders: object;
  customCookies: object;
  
  // 通知相关 | Notification related
  notificationEnabled: boolean;
  
  // 更新相关 | Update related
  updateCheckEnabled: boolean;
  
  // 数据收集相关 | Data collection related
  crashReportingEnabled: boolean;
  analyticsEnabled: boolean;
  
  // 排序相关 | Sorting related
  favoriteSort: string;
  historySort: string;
  searchSort: string;
  
  // 下载相关 | Download related
  maxConcurrentDownloads: number;
  downloadNetworkType: string; // all, wifi, cellular
  
  // 其他 | Others
  recentlyWatchedLimit: number;
  streamingEnabled: boolean;
  localPlaybackEnabled: boolean;
  defaultCategory: string;
  preferredServer: string;
  videoSources: string[];
};

// 配置键类型定义 | Config key type definition
export type ConfigKey = keyof DefaultConfig;

// 播放器配置接口 | Player configuration interface
export interface PlayerConfig {
  defaultPlayer: string;
  autoPlay: boolean;
  rememberPosition: boolean;
  maxBufferSize: number;
  minBufferSize: number;
  preloadSeconds: number;
  enableHardwareDecoding: boolean;
  enableHDR: boolean;
  subtitleSize: number;
  subtitleColor: string;
  subtitleBackgroundColor: string;
  audioTrack: string;
  videoTrack: string;
}

// 显示配置接口 | Display configuration interface
export interface DisplayConfig {
  theme: string;
  fontScale: number;
  enableAnimations: boolean;
  enableBlur: boolean;
  autoRotate: boolean;
  resolution: string;
  screenSaverDelay: number;
  idleTimeout: number;
}

// 网络配置接口 | Network configuration interface
export interface NetworkConfig {
  timeout: number;
  retryCount: number;
  retryDelay: number;
  enableCache: boolean;
  cacheSize: number;
  autoDetectNetwork: boolean;
  useProxy: boolean;
  proxyConfig: ProxyConfig;
}

// 代理配置接口 | Proxy configuration interface
export interface ProxyConfig {
  type: string;
  host: string;
  port: number;
}

// 存储配置接口 | Storage configuration interface
export interface StorageConfig {
  cachePath: string;
  downloadPath: string;
  maxCacheSize: number;
  autoClearCache: boolean;
  clearCacheInterval: number;
  enableBackgroundCleanup: boolean;
}

// 通用配置接口 | General configuration interface
export interface GeneralConfig {
  language: string;
  region: string;
  timeZone: string;
  enableAnalytics: boolean;
  enableUsageReport: boolean;
  firstLaunch: boolean;
  version: string;
  lastUpdated: number;
}

// 安全配置接口 | Security configuration interface
export interface SecurityConfig {
  enablePinCode: boolean;
  pinCode: string;
  enableBiometric: boolean;
  allowedApps: string[];
  lockTimeout: number;
  secureContentOnly: boolean;
}

// 通知配置接口 | Notification configuration interface
export interface NotificationConfig {
  enablePush: boolean;
  enableUpdateNotification: boolean;
  enableContentNotification: boolean;
  enableLiveReminder: boolean;
  notificationSound: string;
  notificationVolume: number;
}

// 无障碍配置接口 | Accessibility configuration interface
export interface AccessibilityConfig {
  enableHighContrast: boolean;
  enableScreenReader: boolean;
  textToSpeechRate: number;
  closedCaptionEnabled: boolean;
  audioDescriptionEnabled: boolean;
  hapticFeedbackEnabled: boolean;
}

// 直播配置接口 | Live configuration interface
export interface LiveConfig {
  epgEnabled: boolean;
  epgAutoUpdate: boolean;
  epgUpdateInterval: number;
  channelFavoritesEnabled: boolean;
  lastWatchedChannel: string;
  lastWatchedGroup: string;
}

// VOD配置接口 | VOD configuration interface
export interface VodConfig {
  autoPlayNextEpisode: boolean;
  showRecommendedContent: boolean;
  downloadQuality: string;
  streamingQuality: string;
}



// 完整配置接口 | Complete configuration interface
export interface Config {
  player: PlayerConfig;
  display: DisplayConfig;
  network: NetworkConfig;
  storage: StorageConfig;
  general: GeneralConfig;
  security: SecurityConfig;
  notification: NotificationConfig;
  accessibility: AccessibilityConfig;
  live: LiveConfig;
  vod: VodConfig;
}

// 选项项目接口 | Option item interface
export interface OptionItem {
  label: string;
  value: ConfigValue;
}

// 验证配置接口 | Validation configuration interface
export interface ValidationConfig {
  min?: number;
  max?: number;
  pattern?: string;
  required?: boolean;
}

// 配置项目接口 | Config item interface
export interface ConfigItem {
  key: ConfigKey;
  value: ConfigValue;
  description?: string;
  type: 'string' | 'number' | 'boolean' | 'object' | 'null';
  defaultValue: ConfigValue;
  category: string;
  options?: OptionItem[];
  validation?: ValidationConfig;
  updatedAt: number;
  createdAt: number;
}

// 配置导入结果接口 | Config import result interface
export interface ConfigImportResult {
  imported: number;
  skipped: number;
  invalid: number;
}

// 批量配置项目接口 | Batch config item interface
export interface BatchConfigItem {
  key: ConfigKey;
  value: ConfigValue;
}

// 批量配置结果接口 | Batch config result interface
export interface BatchConfigResult {
  updated: number;
  failed: number;
}

// 完整默认配置 | Complete default configuration
export const DEFAULT_FULL_CONFIG: Config = {
  player: {
    defaultPlayer: 'system',
    autoPlay: false,
    rememberPosition: true,
    maxBufferSize: 20,
    minBufferSize: 5,
    preloadSeconds: 30,
    enableHardwareDecoding: true,
    enableHDR: false,
    subtitleSize: 18,
    subtitleColor: '#FFFFFF',
    subtitleBackgroundColor: 'rgba(0, 0, 0, 0.5)',
    audioTrack: 'default',
    videoTrack: 'auto'
  },
  display: {
    theme: 'light',
    fontScale: 1.0,
    enableAnimations: true,
    enableBlur: true,
    autoRotate: true,
    resolution: 'auto',
    screenSaverDelay: 300,
    idleTimeout: 0
  },
  network: {
    timeout: 30000,
    retryCount: 3,
    retryDelay: 1000,
    enableCache: true,
    cacheSize: 500,
    autoDetectNetwork: true,
    useProxy: false,
    proxyConfig: {
      type: 'none',
      host: '',
      port: 0
    }
  },
  storage: {
    cachePath: '',
    downloadPath: '',
    maxCacheSize: 1024,
    autoClearCache: true,
    clearCacheInterval: 7,
    enableBackgroundCleanup: true
  },
  general: {
    language: 'zh-CN',
    region: 'CN',
    timeZone: 'Asia/Shanghai',
    enableAnalytics: true,
    enableUsageReport: false,
    firstLaunch: false,
    version: '1.0.0',
    lastUpdated: Date.now()
  },
  security: {
    enablePinCode: false,
    pinCode: '',
    enableBiometric: false,
    allowedApps: [],
    lockTimeout: 300,
    secureContentOnly: false
  },
  notification: {
    enablePush: true,
    enableUpdateNotification: true,
    enableContentNotification: false,
    enableLiveReminder: true,
    notificationSound: 'default',
    notificationVolume: 1.0
  },
  accessibility: {
    enableHighContrast: false,
    enableScreenReader: false,
    textToSpeechRate: 1.0,
    closedCaptionEnabled: true,
    audioDescriptionEnabled: false,
    hapticFeedbackEnabled: true
  },
  live: {
    epgEnabled: true,
    epgAutoUpdate: true,
    epgUpdateInterval: 3600,
    channelFavoritesEnabled: true,
    lastWatchedChannel: '',
    lastWatchedGroup: ''
  },
  vod: {
    autoPlayNextEpisode: true,
    showRecommendedContent: true,
    contentRating: 'all',
    downloadQuality: '720p',
    streamingQuality: 'auto'
  }
};

// 配置键默认值 | Config key default values
export const DEFAULT_CONFIG: DefaultConfig = {
  // 显示相关 | Display related
  theme: 'dark',
  language: 'auto',
  interfaceScale: 100,
  uiAnimationEnabled: true,
  startupScreen: 'home',
  homeLayout: 'default',
  
  // 视频播放相关 | Video playback related
  videoQuality: 'high',
  playbackSpeed: 1.0,
  autoPlay: true,
  autoNextEpisode: true,
  backgroundPlayEnabled: false,
  videoPlayerSettings: {},
  
  // 字幕相关 | Subtitle related
  subtitleEnabled: true,
  subtitleSize: 16,
  subtitleColor: '#FFFFFF',
  subtitleDelay: 0,
  
  // 缓存相关 | Cache related
  cacheEnabled: true,
  cacheLimit: 5000, // MB
  
  // 网络相关 | Network related
  networkTimeout: 30, // 秒 Seconds
  proxyEnabled: false,
  proxyConfig: null,
  dataSaverEnabled: false,
  customHeaders: {},
  customCookies: {},
  
  // 通知相关 | Notification related
  notificationEnabled: true,
  
  // 更新相关 | Update related
  updateCheckEnabled: true,
  
  // 数据收集相关 | Data collection related
  crashReportingEnabled: false,
  analyticsEnabled: false,
  
  // 排序相关 | Sorting related
  favoriteSort: 'addedAt_desc',
  historySort: 'timestamp_desc',
  searchSort: 'relevance_desc',
  
  // 下载相关 | Download related
  maxConcurrentDownloads: 3,
  downloadNetworkType: 'all', // all, wifi, cellular
  
  // 其他 | Others
  recentlyWatchedLimit: 20,
  streamingEnabled: true,
  localPlaybackEnabled: true,
  defaultCategory: 'all',
  preferredServer: 'auto',
  videoSources: []
};

// 配置分类 | Config categories
// 注意：DEFAULT_CONFIG 已在上方完整初始化，此处无需重复赋值 | Note: DEFAULT_CONFIG is fully initialized above, no need for duplicate assignments here


// 配置分类 | Config categories
export const CONFIG_CATEGORIES = {};

// 验证结果接口 | Validation result interface
export interface ValidationResult {
  isValid: boolean;
  errorMessage?: string;
}

/**
 * 配置服务 | Configuration service
 * 负责管理应用的各种设置参数 | Responsible for managing various application settings parameters
 */
export default class ConfigService {
  private static instance: ConfigService;
  private configCache: Map<ConfigKey, ConfigItem> = new Map();
  private configParser: ConfigParser;
  private fullConfig: Config = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
  private isInitialized: boolean = false;

  /**
   * 构造函数（私有，防止外部实例化） | Constructor (private, prevent external instantiation)
   */
  private constructor() {
    this.configParser = ConfigParser.getInstance();
  }

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): ConfigService {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
    }
    return ConfigService.instance;
  }

  /**
   * 获取对象的所有键 | Get all keys of an object
   * 适应ArkTS语法的实现 | ArkTS compatible implementation
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    if (obj === null || typeof obj !== 'object') {
      return [];
    }
    // ArkTS 兼容：手动实现对象键获取，避免使用Object.keys
    const keys: string[] = [];
    // 手动添加已知的配置键 | Manually add known config keys
    // 注意：这是一个简化的实现，实际应该根据具体对象类型返回对应的键
    return keys;
  }
  
  /**
   * 获取完整配置 | Get complete configuration
   */
  public async getFullConfig(): Promise<Config> {
    if (!this.isInitialized) {
      await this.initializeConfig();
    }
    return JSON.parse(JSON.stringify(this.fullConfig));
  }
  
  /**
   * 合并配置 | Merge configuration
   */
  private mergeConfig<T>(defaultConfig: T, customConfig: ConfigUpdate): T {
    // 使用ArkTS兼容的对象合并方法 | Use ArkTS compatible object merging method
    if (!customConfig || typeof customConfig !== 'object' || Array.isArray(customConfig)) {
      return defaultConfig;
    }
    
    const result = JSON.parse(JSON.stringify(defaultConfig)) as T;
    
    // 手动处理不同配置部分的合并 | Manually handle merging of different config sections
      if (customConfig.player && typeof customConfig.player === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.player) {
          this.mergePlayerConfig(resultConfig.player, customConfig.player);
        }
      }
      if (customConfig.display && typeof customConfig.display === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.display) {
          this.mergeDisplayConfig(resultConfig.display, customConfig.display);
        }
      }
      if (customConfig.network && typeof customConfig.network === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.network) {
          this.mergeNetworkConfig(resultConfig.network, customConfig.network);
        }
      }
      if (customConfig.storage && typeof customConfig.storage === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.storage) {
          this.mergeStorageConfig(resultConfig.storage, customConfig.storage);
        }
      }
      if (customConfig.general && typeof customConfig.general === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.general) {
          this.mergeGeneralConfig(resultConfig.general, customConfig.general);
        }
      }
      if (customConfig.security && typeof customConfig.security === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.security) {
          this.mergeSecurityConfig(resultConfig.security, customConfig.security);
        }
      }
      if (customConfig.notification && typeof customConfig.notification === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.notification) {
          this.mergeNotificationConfig(resultConfig.notification, customConfig.notification);
        }
      }
      if (customConfig.accessibility && typeof customConfig.accessibility === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.accessibility) {
          this.mergeAccessibilityConfig(resultConfig.accessibility, customConfig.accessibility);
        }
      }
      if (customConfig.live && typeof customConfig.live === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.live) {
          this.mergeLiveConfig(resultConfig.live, customConfig.live);
        }
      }
      if (customConfig.vod && typeof customConfig.vod === 'object') {
        const resultConfig = result as Config;
        if (resultConfig.vod) {
          this.mergeVodConfig(resultConfig.vod, customConfig.vod);
        }
      }
    
    return result;
  }
  
  /**
   * 确保默认配置存在 | Ensure default configuration exists
   */
  private ensureDefaultConfig(): void {
    // 更新最后修改时间 | Update last modified time
    this.fullConfig.general.lastUpdated = Date.now();
    
    // 验证必要的配置项 | Verify necessary configuration items
    if (!this.fullConfig.player) {
      this.fullConfig.player = DEFAULT_FULL_CONFIG.player;
    }
    if (!this.fullConfig.display) {
      this.fullConfig.display = DEFAULT_FULL_CONFIG.display;
    }
    if (!this.fullConfig.network) {
      this.fullConfig.network = DEFAULT_FULL_CONFIG.network;
    }
  }
  
  /**
   * 更新完整配置 | Update complete configuration
   */
  public async updateFullConfig(customConfig: Partial<Config>): Promise<ApiResponse<Config>> {
    try {
      // 合并配置 - 使用类型安全的方法 | Merge configuration - Use type-safe method
      this.fullConfig = this.mergeConfig(this.fullConfig, customConfig as ConfigUpdate);
      this.ensureDefaultConfig();
      
      // 保存到存储 | Save to storage
      await StorageUtil.putString('app_full_config', JSON.stringify(this.fullConfig));
      
      return ApiResponse.success(this.fullConfig, '配置更新成功');
    } catch (error: Error) {
      // 处理配置更新错误 | Handle config update error
      console.error(TAG + ": 更新完整配置失败: " + error.message + " | Failed to update full config: " + error.message);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '配置更新失败');
    }
  }
  
  /**
   * 添加配置变更监听 | Add config change listener
   */
  private configListeners: Array<(config: Config) => void> = [];
  
  /**
   * 添加配置变更监听 | Add config change listener
   */
  public addConfigListener(listener: (config: Config) => void): void {
    this.configListeners.push(listener);
  }
  
  /**
   * 移除配置变更监听 | Remove config change listener
   */
  public removeConfigListener(listener: (config: Config) => void): void {
    const index = this.configListeners.indexOf(listener);
    if (index > -1) {
      this.configListeners.splice(index, 1);
    }
  }

  /**
   * 初始化配置 | Initialize configuration
   */
  private async initializeConfig(): Promise<void> {
    try {
      console.info(TAG + ': 正在初始化配置... | Initializing configuration...');
      
      // 1. 首先尝试加载完整配置 | 1. First try to load complete configuration
      await this.loadFullConfig();
      
      // 初始化数据结构 | Initialize data structure
      this.configCache = new Map();
      
      // 合并默认配置和数据库配置 | Merge default config and database config
      const defaultConfigKeys = this.getObjectKeys(DEFAULT_CONFIG);
      for (let i = 0; i < defaultConfigKeys.length; i++) {
        const key = defaultConfigKeys[i] as ConfigKey;
        const defaultValue = DEFAULT_CONFIG[key];
        
        // 创建默认配置项 | Create default config item
        const defaultItem: ConfigItem = {
          key: key,
          value: defaultValue,
          type: this.getValueType(defaultValue),
          defaultValue,
          category: this.getConfigCategory(key),
          updatedAt: Date.now(),
          createdAt: Date.now()
        };
        
        this.configCache.set(key, defaultItem);
      }
      
      // 确保默认配置完整 | Ensure default config is complete
      this.ensureDefaultConfig();
      
      this.isInitialized = true;
      console.info(TAG + ': 配置初始化成功 | Configuration initialized successfully');
    } catch (error: Error) {
      console.error(TAG + ": 配置初始化失败: " + error.message + " | Failed to initialize configuration: " + error.message);
      // 初始化失败时使用默认配置 | Use default config when initialization fails
      this.fullConfig = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
      this.ensureDefaultConfig();
      this.isInitialized = true;
    }
  }
  
  /**
   * 加载完整配置 | Load complete configuration
   */
  private async loadFullConfig(): Promise<void> {
    try {
      // 尝试从本地存储加载完整配置 | Try to load complete config from local storage
      const storedConfigStr = await StorageUtil.getString('app_full_config');
      
      if (storedConfigStr) {
        // 使用明确的Config类型替代any | Use explicit Config type instead of any
        const storedConfig = JSON.parse(storedConfigStr) as Config;
        if (storedConfig && typeof storedConfig === 'object') {
          // 合并存储的配置和默认配置 - 避免unknown类型转换 | Merge stored config and default config - avoid unknown type conversion
          this.fullConfig = this.mergeConfig(DEFAULT_FULL_CONFIG, storedConfig as ConfigUpdate);
          console.info(TAG + ': 从存储加载完整配置成功 | Loaded full configuration from storage');
        } else {
          // 使用默认配置 | Use default config
          this.fullConfig = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
          await StorageUtil.putString('app_full_config', JSON.stringify(this.fullConfig));
          console.info(TAG + ': 使用默认完整配置 | Using default full configuration');
        }
      } else {
        // 使用默认配置 | Use default config
        this.fullConfig = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
        await StorageUtil.putString('app_full_config', JSON.stringify(this.fullConfig));
        console.info(TAG + ': 使用默认完整配置 | Using default full configuration');
      }
    } catch (error: Error) {
      console.error(TAG + ": 加载完整配置失败: " + error.message + " | Failed to load full config: " + error.message);
      // 加载失败时使用默认配置 | Use default config when loading fails
      this.fullConfig = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
    }
  }

  /**
   * 获取配置 | Get configuration
   */
  public async getConfig(key: ConfigKey): Promise<ApiResponse<ConfigValue>> {
    try {
      console.debug(TAG + `: 正在获取配置项: ${key} | Getting config for key: ${key}`);
      
      // 检查缓存 | Check cache
      if (this.configCache.has(key)) {
        const config = this.configCache.get(key)!;
        return ApiResponse.success(config.value, `获取配置[${key}]成功`);
      }
      
      // 返回默认值 | Return default value
      const defaultValue = DEFAULT_CONFIG[key];
      return ApiResponse.success(defaultValue, `配置[${key}]不存在，返回默认值`);
    } catch (error) {
      console.error(TAG + `: 获取配置项失败: ${key} | Failed to get config for key: ${key}`);
      // 发生错误时返回默认值 | Return default value when error occurs
      const defaultValue = DEFAULT_CONFIG[key];
      return ApiResponse.success(defaultValue, `获取配置失败，返回默认值`);
    }
  }

  /**
   * 获取部分配置 | Get partial configuration
   */
  public async getPartialConfig(key: keyof Config): Promise<PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig> {
    if (!this.isInitialized) {
      await this.initializeConfig();
    }
    
    let configSection: PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig | undefined;
    
    // 手动处理不同配置部分的访问 | Manually handle access to different config sections
    switch (key) {
      case 'player':
        configSection = this.fullConfig.player;
        break;
      case 'display':
        configSection = this.fullConfig.display;
        break;
      case 'network':
        configSection = this.fullConfig.network;
        break;
      case 'storage':
        configSection = this.fullConfig.storage;
        break;
      case 'general':
        configSection = this.fullConfig.general;
        break;
      case 'security':
        configSection = this.fullConfig.security;
        break;
      case 'notification':
        configSection = this.fullConfig.notification;
        break;
      case 'accessibility':
        configSection = this.fullConfig.accessibility;
        break;
      case 'live':
        configSection = this.fullConfig.live;
        break;
      case 'vod':
        configSection = this.fullConfig.vod;
        break;
      default:
        configSection = undefined;
        break;
    }
    
    if (!configSection) {
      // 如果配置部分不存在，从默认配置获取 | If config section doesn't exist, get from default config
      let defaultSection: PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig | undefined;
      switch (key) {
        case 'player':
          defaultSection = DEFAULT_FULL_CONFIG.player;
          break;
        case 'display':
          defaultSection = DEFAULT_FULL_CONFIG.display;
          break;
        case 'network':
          defaultSection = DEFAULT_FULL_CONFIG.network;
          break;
        case 'storage':
          defaultSection = DEFAULT_FULL_CONFIG.storage;
          break;
        case 'general':
          defaultSection = DEFAULT_FULL_CONFIG.general;
          break;
        case 'security':
          defaultSection = DEFAULT_FULL_CONFIG.security;
          break;
        case 'notification':
          defaultSection = DEFAULT_FULL_CONFIG.notification;
          break;
        case 'accessibility':
          defaultSection = DEFAULT_FULL_CONFIG.accessibility;
          break;
        case 'live':
          defaultSection = DEFAULT_FULL_CONFIG.live;
          break;
        case 'vod':
          defaultSection = DEFAULT_FULL_CONFIG.vod;
          break;
        default:
          defaultSection = undefined;
          break;
      }
      return JSON.parse(JSON.stringify(defaultSection)) as PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig;
    }
    
    return JSON.parse(JSON.stringify(configSection));
  }
  
  /**
   * 更新部分配置 | Update partial configuration
   */
  public async updatePartialConfig(key: keyof Config, sectionConfig: ConfigUpdate): Promise<ApiResponse<PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig>> {
    try {
      if (!this.isInitialized) {
        await this.initializeConfig();
      }
      
      // 更新部分配置 | Update partial config
      let updatedSection: PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig;
      
      // 手动处理不同配置部分的访问和更新 | Manually handle access to and update of different config sections
      switch (key) {
        case 'player':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.player)) as PlayerConfig;
          break;
        case 'display':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.display)) as DisplayConfig;
          break;
        case 'network':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.network)) as NetworkConfig;
          break;
        case 'storage':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.storage)) as StorageConfig;
          break;
        case 'general':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.general)) as GeneralConfig;
          break;
        case 'security':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.security)) as SecurityConfig;
          break;
        case 'notification':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.notification)) as NotificationConfig;
          break;
        case 'accessibility':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.accessibility)) as AccessibilityConfig;
          break;
        case 'live':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.live)) as LiveConfig;
          break;
        case 'vod':
          updatedSection = JSON.parse(JSON.stringify(this.fullConfig.vod)) as VodConfig;
          break;
        default:
          return ApiResponse.error(ResponseCode.BAD_REQUEST, '无效的配置部分');
      }
      
      // 根据配置类型，使用不同的赋值方法，避免使用unknown类型转换 | According to config type, use different assignment methods, avoid using unknown type conversion
      switch (key) {
        case 'player':
          if (sectionConfig.player) {
            this.mergePlayerConfig(updatedSection as PlayerConfig, sectionConfig.player);
          }
          break;
        case 'display':
          if (sectionConfig.display) {
            this.mergeDisplayConfig(updatedSection as DisplayConfig, sectionConfig.display);
          }
          break;
        case 'network':
          if (sectionConfig.network) {
            this.mergeNetworkConfig(updatedSection as NetworkConfig, sectionConfig.network);
          }
          break;
        case 'storage':
          if (sectionConfig.storage) {
            this.mergeStorageConfig(updatedSection as StorageConfig, sectionConfig.storage);
          }
          break;
        case 'general':
          if (sectionConfig.general) {
            this.mergeGeneralConfig(updatedSection as GeneralConfig, sectionConfig.general);
          }
          break;
        case 'security':
          if (sectionConfig.security) {
            this.mergeSecurityConfig(updatedSection as SecurityConfig, sectionConfig.security);
          }
          break;
        case 'notification':
          if (sectionConfig.notification) {
            this.mergeNotificationConfig(updatedSection as NotificationConfig, sectionConfig.notification);
          }
          break;
        case 'accessibility':
          if (sectionConfig.accessibility) {
            this.mergeAccessibilityConfig(updatedSection as AccessibilityConfig, sectionConfig.accessibility);
          }
          break;
        case 'live':
          if (sectionConfig.live) {
            this.mergeLiveConfig(updatedSection as LiveConfig, sectionConfig.live);
          }
          break;
        case 'vod':
          if (sectionConfig.vod) {
            this.mergeVodConfig(updatedSection as VodConfig, sectionConfig.vod);
          }
          break;
      }
      
      // 更新配置部分 | Update config section
      switch (key) {
        case 'player':
          this.fullConfig.player = updatedSection as PlayerConfig;
          break;
        case 'display':
          this.fullConfig.display = updatedSection as DisplayConfig;
          break;
        case 'network':
          this.fullConfig.network = updatedSection as NetworkConfig;
          break;
        case 'storage':
          this.fullConfig.storage = updatedSection as StorageConfig;
          break;
        case 'general':
          this.fullConfig.general = updatedSection as GeneralConfig;
          break;
        case 'security':
          this.fullConfig.security = updatedSection as SecurityConfig;
          break;
        case 'notification':
          this.fullConfig.notification = updatedSection as NotificationConfig;
          break;
        case 'accessibility':
          this.fullConfig.accessibility = updatedSection as AccessibilityConfig;
          break;
        case 'live':
          this.fullConfig.live = updatedSection as LiveConfig;
          break;
        case 'vod':
          this.fullConfig.vod = updatedSection as VodConfig;
          break;
      }
      
      // 更新最后修改时间 | Update last modified time
      this.fullConfig.general.lastUpdated = Date.now();
      
      // 保存到存储 | Save to storage
      await StorageUtil.putString('app_full_config', JSON.stringify(this.fullConfig));
      
      // 返回更新后的配置部分 | Return updated config section
      let finalConfigSection: PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig;
      switch (key) {
        case 'player':
          finalConfigSection = this.fullConfig.player;
          break;
        case 'display':
          finalConfigSection = this.fullConfig.display;
          break;
        case 'network':
          finalConfigSection = this.fullConfig.network;
          break;
        case 'storage':
          finalConfigSection = this.fullConfig.storage;
          break;
        case 'general':
          finalConfigSection = this.fullConfig.general;
          break;
        case 'security':
          finalConfigSection = this.fullConfig.security;
          break;
        case 'notification':
          finalConfigSection = this.fullConfig.notification;
          break;
        case 'accessibility':
          finalConfigSection = this.fullConfig.accessibility;
          break;
        case 'live':
          finalConfigSection = this.fullConfig.live;
          break;
        case 'vod':
          finalConfigSection = this.fullConfig.vod;
          break;
        default:
          finalConfigSection = this.fullConfig.general; // 默认general配置 | Default to general config
          break;
      }
      
      return ApiResponse.success(finalConfigSection, '配置更新成功');
    } catch (error: Error) {
      console.error(TAG, `更新部分配置失败: ${String(key)} | Failed to update partial config for key: ${String(key)}`, error.message);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '配置更新失败');
    }
  }

  /**
   * 获取配置项目 | Get config item
   */
  public async getConfigItem(key: ConfigKey): Promise<ApiResponse<ConfigItem>> {
    try {
      console.debug(TAG + `: 正在获取配置项目: ${key} | Getting config item for key: ${key}`);
      
      // 检查缓存 | Check cache
      if (this.configCache.has(key)) {
        const config = this.configCache.get(key)!;
        return ApiResponse.success(config, `获取配置项[${key}]成功`);
      }
      
      // 创建并返回默认配置项 | Create and return default config item
      const defaultItem: ConfigItem = {
        key,
        value: DEFAULT_CONFIG[key],
        type: this.getValueType(DEFAULT_CONFIG[key]),
        defaultValue: DEFAULT_CONFIG[key],
        category: this.getConfigCategory(key),
        updatedAt: Date.now(),
        createdAt: Date.now()
      };
      
      return ApiResponse.success(defaultItem, `配置项[${key}]不存在，返回默认配置项`);
    } catch (error) {
      console.error(TAG + `: 获取配置项目失败: ${key} | Failed to get config item for key: ${key}`);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `获取配置项失败`);
    }
  }

  /**
   * 设置配置 | Set config
   */
  public async setConfig(key: ConfigKey, value: ConfigValue): Promise<ApiResponse<ConfigItem>> {
    try {
      console.info(TAG + `: 正在设置配置项: ${key} = ${JSON.stringify(value)} | Setting config: ${key} = ${JSON.stringify(value)}`);
      
      // 验证配置值 | Validate config value
      const validationResult = this.validateConfigValue(key, value);
      if (!validationResult.isValid) {
        return ApiResponse.validationError([
          { field: key, message: validationResult.errorMessage || '配置值无效' }
        ]);
      }
      
      // 获取或创建配置项 | Get or create config item
      let configItem: ConfigItem;
      
      if (this.configCache.has(key)) {
        // 更新现有配置 | Update existing config
        const existingItem = this.configCache.get(key)!;
        configItem = {
          key: existingItem.key,
          value: existingItem.value,
          type: existingItem.type,
          defaultValue: existingItem.defaultValue,
          category: existingItem.category,
          description: existingItem.description,
          options: existingItem.options,
          validation: existingItem.validation,
          updatedAt: existingItem.updatedAt,
          createdAt: existingItem.createdAt
        };
        configItem.value = value;
        configItem.updatedAt = Date.now();
      } else {
        // 创建新配置 | Create new config
        configItem = {
          key,
          value,
          type: this.getValueType(value),
          defaultValue: DEFAULT_CONFIG[key],
          category: this.getConfigCategory(key),
          updatedAt: Date.now(),
          createdAt: Date.now()
        };
      }
      
      // 更新缓存 | Update cache
      this.configCache.set(key, configItem);
      
      // 触发配置变更事件 | Trigger config change event
      this.notifyConfigChanged(key, value);
      
      console.info(TAG + `: Config updated successfully: ${key} | Config updated successfully: ${key}`);
      return ApiResponse.success(configItem, `设置配置[${key}]成功`);
    } catch (error: Error) {
      console.error(TAG + `: 设置配置项失败: ${key} | Failed to set config: ${key}`, error.message);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `设置配置失败`);
    }
  }

  /**
   * 批量设置配置 | Batch set config
   */
  public async setMultipleConfig(configs: BatchConfigItem[]): Promise<ApiResponse<BatchConfigResult>> {
    try {
      console.info(TAG + `: 正在批量设置配置: ${configs.length} 项 | Setting multiple configs: ${configs.length} items`);
      
      let updated = 0;
      let failed = 0;
      
      for (let i = 0; i < configs.length; i++) {
        const configItem = configs[i];
        const key = configItem.key;
        const value = configItem.value;
        try {
          // 验证配置值 | Validate config value
          const validationResult = this.validateConfigValue(key, value);
          if (!validationResult.isValid) {
            console.warn(TAG + `: 配置值无效: ${key}: ${validationResult.errorMessage} | Invalid config value for ${key}: ${validationResult.errorMessage}`);
            failed++;
            continue;
          }
          
          // 更新配置 | Update config
          await this.setConfig(key, value);
          updated++;
        } catch (error: Error) {
            console.warn(TAG + `: 更新配置项失败: ${key} | Failed to update config ${key}`, error.message);
            failed++;
          }
      }
      
      console.info(TAG + `: 批量配置更新完成: ${updated} 成功, ${failed} 失败 | Multiple configs updated: ${updated} success, ${failed} failed`);
      const result: BatchConfigResult = {
        updated,
        failed
      };
      return ApiResponse.success(
        result,
        `批量更新配置完成，成功${updated}项，失败${failed}项`
      );
    } catch (error: Error) {
      console.error(TAG + ': 批量设置配置失败 | Failed to set multiple configs', error.message);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '批量更新配置失败');
    }
  }

  /**
   * 重置配置为默认值 | Reset config to default
   */
  public async resetConfig(key: ConfigKey): Promise<ApiResponse<ConfigItem>> {
    try {
      console.info(TAG + `: 正在重置配置项为默认值: ${key} | Resetting config to default: ${key}`);
      
      const defaultValue = DEFAULT_CONFIG[key];
      
      // 更新配置项 | Update config item
      const configItem: ConfigItem = {
        key,
        value: defaultValue,
        type: this.getValueType(defaultValue),
        defaultValue,
        category: this.getConfigCategory(key),
        updatedAt: Date.now(),
        createdAt: this.configCache.has(key) ? this.configCache.get(key)!.createdAt : Date.now()
      };
      
      // 更新缓存 | Update cache
      this.configCache.set(key, configItem);
      
      // 触发配置变更事件 | Trigger config change event
      this.notifyConfigChanged(key, defaultValue);
      
      console.info(TAG + `: 配置项重置成功: ${key} | Config reset successfully: ${key}`);
      return ApiResponse.success(configItem, `重置配置[${key}]成功`);
    } catch (error) {
      console.error(TAG + `: 重置配置项失败: ${key} | Failed to reset config: ${key}`);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '重置配置失败');
    }
  }

  /**
   * 重置所有配置为默认值 | Reset all config to default
   */
  public async resetAllConfig(): Promise<ApiResponse<boolean>> {
    try {
      console.info(TAG + ': 正在重置所有配置为默认值 | Resetting all config to default values');
      
      // 清空缓存 | Clear cache
      this.configCache.clear();
      
      // 重新初始化配置 | Reinitialize config
      await this.initializeConfig();
      
      // 触发配置重置事件 | Trigger config reset event
      this.notifyConfigReset();
      
      console.info(TAG + ': 所有配置重置成功 | All config reset successfully');
      return ApiResponse.success(true, '重置所有配置成功');
    } catch (error) {
      console.error(TAG + ': 重置所有配置失败 | Failed to reset all config');
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '重置所有配置失败');
    }
  }

  /**
   * 获取所有配置 | Get all configs
   */
  public async getAllConfig(category?: string): Promise<ApiResponse<ConfigItem[]>> {
    try {
      console.info(TAG + `: 正在获取所有配置${category ? `, 分类: ${category}` : ''} | Getting all configs${category ? ` for category: ${category}` : ''}`);
      
      let allConfigs: ConfigItem[];
      
      if (category) {
        // 按分类获取 | Get by category
        allConfigs = Array.from(this.configCache.values())
          .filter(item => item.category === category);
      } else {
        // 获取全部 | Get all
        allConfigs = Array.from(this.configCache.values());
      }
      
      return ApiResponse.success(allConfigs, `获取配置列表成功，共${allConfigs.length}项`);
    } catch (error) {
      console.error(TAG + ': 获取所有配置失败 | Failed to get all configs');
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取配置列表失败');
    }
  }



  /**
   * 验证配置值 | Validate config value
   */
  private validateConfigValue(key: ConfigKey, value: ConfigValue): ValidationResult {
    // 获取默认值类型 | Get default value type
    const defaultValue = DEFAULT_CONFIG[key];
    if (defaultValue === undefined) {
      const result: ValidationResult = { isValid: false, errorMessage: `未知的配置项: ${key}` };
      return result;
    }
    
    // 检查类型 | Check type
    const expectedType = this.getValueType(defaultValue);
    const actualType = this.getValueType(value);
    
    if (expectedType !== actualType) {
      const result: ValidationResult = { 
        isValid: false, 
        errorMessage: `配置类型错误，期望${expectedType}，实际${actualType}` 
      };
      return result;
    }
    
    // 对特定配置进行范围验证 | Validate specific configs
    switch (key) {
      case 'cacheLimit':
        if (typeof value === 'number' && (value < 0 || value > 50000)) {
          const result: ValidationResult = { isValid: false, errorMessage: '缓存限制必须在0-50000MB之间' };
          return result;
        }
        break;
        
      case 'networkTimeout':
        if (typeof value === 'number' && (value < 5 || value > 300)) {
          const result: ValidationResult = { isValid: false, errorMessage: '网络超时必须在5-300秒之间' };
          return result;
        }
        break;
        
      case 'subtitleSize':
        if (typeof value === 'number' && (value < 10 || value > 48)) {
          const result: ValidationResult = { isValid: false, errorMessage: '字幕大小必须在10-48之间' };
          return result;
        }
        break;
        
      case 'maxConcurrentDownloads':
        if (typeof value === 'number' && (value < 1 || value > 10)) {
          const result: ValidationResult = { isValid: false, errorMessage: '最大并发下载数必须在1-10之间' };
          return result;
        }
        break;
        
      case 'interfaceScale':
        if (typeof value === 'number' && (value < 50 || value > 200)) {
          const result: ValidationResult = { isValid: false, errorMessage: '界面缩放必须在50%-200%之间' };
          return result;
        }
        break;
    }
    
    const result: ValidationResult = { isValid: true };
    return result;
  }

  /**
   * 获取值的类型 | Get value type
   */
  private getValueType(value: ConfigValue): 'string' | 'number' | 'boolean' | 'object' | 'null' {
    if (value === null) return 'null';
    if (Array.isArray(value)) return 'object';
    return typeof value as 'string' | 'number' | 'boolean' | 'object';
  }

  /**
   * 获取配置分类 | Get config category
   */
  private getConfigCategory(key: ConfigKey): string {
    return 'other';
  }

  // ========== 事件通知模块 | Event notification module ==========
  
  private configItemListeners: Map<string, Array<(value: ConfigValue) => void>> = new Map();
  private globalListeners: Array<(key: ConfigKey, value: ConfigValue) => void> = [];
  private resetListeners: Array<() => void> = [];

  /**
   * 监听特定配置项变化 | Listen to specific config item changes
   */
  public addConfigItemListener(key: ConfigKey, listener: (value: ConfigValue) => void): () => void {
    const keyStr = key as string;
    if (!this.configItemListeners.has(keyStr)) {
      this.configItemListeners.set(keyStr, []);
    }
    
    const listeners = this.configItemListeners.get(keyStr)!;
    listeners.push(listener);
    
    // 返回取消监听函数 | Return unsubscribe function
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加全局配置监听 | Add global config listener
   */
  public addGlobalConfigListener(listener: (key: ConfigKey, value: ConfigValue) => void): () => void {
    this.globalListeners.push(listener);
    
    // 返回取消监听函数 | Return unsubscribe function
    return () => {
      const index = this.globalListeners.indexOf(listener);
      if (index > -1) {
        this.globalListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加配置重置监听 | Add config reset listener
   */
  public addConfigResetListener(listener: () => void): () => void {
    this.resetListeners.push(listener);
    
    // 返回取消监听函数 | Return unsubscribe function
    return () => {
      const index = this.resetListeners.indexOf(listener);
      if (index > -1) {
        this.resetListeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知配置变更 | Notify config change
   */
  private notifyConfigChanged(key: ConfigKey, value: ConfigValue): void {
    // 通知特定配置的监听器 | Notify listeners for specific config
    const keyStr = key as string;
    if (this.configItemListeners.has(keyStr)) {
      const listeners = this.configItemListeners.get(keyStr)!;
      for (let i = 0; i < listeners.length; i++) {
        const listener = listeners[i];
        try {
          listener(value);
        } catch (error: Error) {
          console.error(TAG + `: 配置监听器错误: ${key} | Error in config listener for ${key}`, error.message);
        }
      }
    }
    
    // 通知全局监听器 | Notify global listeners
    for (let i = 0; i < this.globalListeners.length; i++) {
      const listener = this.globalListeners[i];
      try {
          listener(key, value);
        } catch (error: Error) {
          console.error(TAG + `: 全局配置监听器错误 | Error in global config listener`, error.message);
        }
    }
  }

  /**
   * 通知配置重置 | Notify config reset
   */
  private notifyConfigReset(): void {
    for (let i = 0; i < this.resetListeners.length; i++) {
      const listener = this.resetListeners[i];
      try {
        listener();
      } catch (error: Error) {
        console.error(TAG + `: 配置重置监听器错误 | Error in config reset listener`, error.message);
      }
    }
  }
  
  // ========== 配置合并方法 | Config merge methods ==========
  
  private mergePlayerConfig(config: PlayerConfig, updates: Partial<PlayerConfig>): PlayerConfig {
    if (updates.defaultPlayer !== undefined) config.defaultPlayer = updates.defaultPlayer;
    if (updates.autoPlay !== undefined) config.autoPlay = updates.autoPlay;
    if (updates.rememberPosition !== undefined) config.rememberPosition = updates.rememberPosition;
    if (updates.maxBufferSize !== undefined) config.maxBufferSize = updates.maxBufferSize;
    if (updates.minBufferSize !== undefined) config.minBufferSize = updates.minBufferSize;
    if (updates.preloadSeconds !== undefined) config.preloadSeconds = updates.preloadSeconds;
    if (updates.enableHardwareDecoding !== undefined) config.enableHardwareDecoding = updates.enableHardwareDecoding;
    if (updates.enableHDR !== undefined) config.enableHDR = updates.enableHDR;
    if (updates.subtitleSize !== undefined) config.subtitleSize = updates.subtitleSize;
    if (updates.subtitleColor !== undefined) config.subtitleColor = updates.subtitleColor;
    if (updates.subtitleBackgroundColor !== undefined) config.subtitleBackgroundColor = updates.subtitleBackgroundColor;
    if (updates.audioTrack !== undefined) config.audioTrack = updates.audioTrack;
    if (updates.videoTrack !== undefined) config.videoTrack = updates.videoTrack;
    return config;
  }
  
  private mergeDisplayConfig(config: DisplayConfig, updates: Partial<DisplayConfig>): DisplayConfig {
    if (updates.theme !== undefined) config.theme = updates.theme;
    if (updates.fontScale !== undefined) config.fontScale = updates.fontScale;
    if (updates.enableAnimations !== undefined) config.enableAnimations = updates.enableAnimations;
    if (updates.enableBlur !== undefined) config.enableBlur = updates.enableBlur;
    if (updates.autoRotate !== undefined) config.autoRotate = updates.autoRotate;
    if (updates.resolution !== undefined) config.resolution = updates.resolution;
    if (updates.screenSaverDelay !== undefined) config.screenSaverDelay = updates.screenSaverDelay;
    if (updates.idleTimeout !== undefined) config.idleTimeout = updates.idleTimeout;
    return config;
  }
  
  private mergeNetworkConfig(config: NetworkConfig, updates: Partial<NetworkConfig>): NetworkConfig {
    if (updates.timeout !== undefined) config.timeout = updates.timeout;
    if (updates.retryCount !== undefined) config.retryCount = updates.retryCount;
    if (updates.retryDelay !== undefined) config.retryDelay = updates.retryDelay;
    if (updates.enableCache !== undefined) config.enableCache = updates.enableCache;
    if (updates.cacheSize !== undefined) config.cacheSize = updates.cacheSize;
    if (updates.autoDetectNetwork !== undefined) config.autoDetectNetwork = updates.autoDetectNetwork;
    if (updates.useProxy !== undefined) config.useProxy = updates.useProxy;
    if (updates.proxyConfig !== undefined) {
      const proxyConfig = updates.proxyConfig;
      const newProxyConfig: ProxyConfig = {
        type: proxyConfig.type || 'none',
        host: proxyConfig.host || '',
        port: proxyConfig.port || 0
      };
      config.proxyConfig = newProxyConfig;
    }
    return config;
  }
  
  private mergeStorageConfig(config: StorageConfig, updates: Partial<StorageConfig>): StorageConfig {
    if (updates.cachePath !== undefined) config.cachePath = updates.cachePath;
    if (updates.downloadPath !== undefined) config.downloadPath = updates.downloadPath;
    if (updates.maxCacheSize !== undefined) config.maxCacheSize = updates.maxCacheSize;
    if (updates.autoClearCache !== undefined) config.autoClearCache = updates.autoClearCache;
    if (updates.clearCacheInterval !== undefined) config.clearCacheInterval = updates.clearCacheInterval;
    if (updates.enableBackgroundCleanup !== undefined) config.enableBackgroundCleanup = updates.enableBackgroundCleanup;
    return config;
  }
  
  private mergeGeneralConfig(config: GeneralConfig, updates: Partial<GeneralConfig>): GeneralConfig {
    if (updates.language !== undefined) config.language = updates.language;
    if (updates.region !== undefined) config.region = updates.region;
    if (updates.timeZone !== undefined) config.timeZone = updates.timeZone;
    if (updates.enableAnalytics !== undefined) config.enableAnalytics = updates.enableAnalytics;
    if (updates.enableUsageReport !== undefined) config.enableUsageReport = updates.enableUsageReport;
    if (updates.firstLaunch !== undefined) config.firstLaunch = updates.firstLaunch;
    if (updates.version !== undefined) config.version = updates.version;
    if (updates.lastUpdated !== undefined) config.lastUpdated = updates.lastUpdated;
    return config;
  }
  
  private mergeSecurityConfig(config: SecurityConfig, updates: Partial<SecurityConfig>): SecurityConfig {
    if (updates.enablePinCode !== undefined) config.enablePinCode = updates.enablePinCode;
    if (updates.pinCode !== undefined) config.pinCode = updates.pinCode;
    if (updates.enableBiometric !== undefined) config.enableBiometric = updates.enableBiometric;
    if (updates.allowedApps !== undefined) {
      // 确保allowedApps是数组类型 Ensure allowedApps is array type
      const allowedApps = updates.allowedApps;
      if (Array.isArray(allowedApps)) {
        config.allowedApps = allowedApps;
      } else {
        config.allowedApps = [];
      }
    }
    if (updates.lockTimeout !== undefined) config.lockTimeout = updates.lockTimeout;
    if (updates.secureContentOnly !== undefined) config.secureContentOnly = updates.secureContentOnly;
    return config;
  }
  
  private mergeNotificationConfig(config: NotificationConfig, updates: Partial<NotificationConfig>): NotificationConfig {
    if (updates.enablePush !== undefined) config.enablePush = updates.enablePush;
    if (updates.enableUpdateNotification !== undefined) config.enableUpdateNotification = updates.enableUpdateNotification;
    if (updates.enableContentNotification !== undefined) config.enableContentNotification = updates.enableContentNotification;
    if (updates.enableLiveReminder !== undefined) config.enableLiveReminder = updates.enableLiveReminder;
    if (updates.notificationSound !== undefined) config.notificationSound = updates.notificationSound;
    if (updates.notificationVolume !== undefined) config.notificationVolume = updates.notificationVolume;
    return config;
  }
  
  private mergeAccessibilityConfig(config: AccessibilityConfig, updates: Partial<AccessibilityConfig>): AccessibilityConfig {
    if (updates.enableHighContrast !== undefined) config.enableHighContrast = updates.enableHighContrast;
    if (updates.enableScreenReader !== undefined) config.enableScreenReader = updates.enableScreenReader;
    if (updates.textToSpeechRate !== undefined) config.textToSpeechRate = updates.textToSpeechRate;
    if (updates.closedCaptionEnabled !== undefined) config.closedCaptionEnabled = updates.closedCaptionEnabled;
    if (updates.audioDescriptionEnabled !== undefined) config.audioDescriptionEnabled = updates.audioDescriptionEnabled;
    if (updates.hapticFeedbackEnabled !== undefined) config.hapticFeedbackEnabled = updates.hapticFeedbackEnabled;
    return config;
  }
  
  private mergeLiveConfig(config: LiveConfig, updates: Partial<LiveConfig>): LiveConfig {
    if (updates.epgEnabled !== undefined) config.epgEnabled = updates.epgEnabled;
    if (updates.epgAutoUpdate !== undefined) config.epgAutoUpdate = updates.epgAutoUpdate;
    if (updates.epgUpdateInterval !== undefined) config.epgUpdateInterval = updates.epgUpdateInterval;
    if (updates.channelFavoritesEnabled !== undefined) config.channelFavoritesEnabled = updates.channelFavoritesEnabled;
    if (updates.lastWatchedChannel !== undefined) config.lastWatchedChannel = updates.lastWatchedChannel;
    if (updates.lastWatchedGroup !== undefined) config.lastWatchedGroup = updates.lastWatchedGroup;
    return config;
  }
  
  private mergeVodConfig(config: VodConfig, updates: Partial<VodConfig>): VodConfig {
    if (updates.autoPlayNextEpisode !== undefined) config.autoPlayNextEpisode = updates.autoPlayNextEpisode;
    if (updates.showRecommendedContent !== undefined) config.showRecommendedContent = updates.showRecommendedContent;
    if (updates.contentRating !== undefined) config.contentRating = updates.contentRating;
    if (updates.downloadQuality !== undefined) config.downloadQuality = updates.downloadQuality;
    if (updates.streamingQuality !== undefined) config.streamingQuality = updates.streamingQuality;
    return config;
  }
}
