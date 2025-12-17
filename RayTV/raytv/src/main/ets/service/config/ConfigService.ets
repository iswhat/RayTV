// ConfigService - 配置服务
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import { TypeSafetyUtil } from '../../common/util/TypeSafetyUtil';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import DatabaseRepository from '../../data/repository/DatabaseRepository';
import { ConfigParser } from './ConfigParser';

// 导入模型和DTO
import ApiResponse, { ResponseCode } from '../../data/dto/ApiResponse';

// 常量定义
const TAG = 'ConfigService';

// 配置导出项接口
export interface ConfigExportItem {
  key: string;
  value: string | number | boolean;
  updatedAt: number;
}

// 配置导出数据接口
export interface ConfigExportData {
  exportDate: string;
  version: string;
  configs: ConfigExportItem[];
}

// 配置项类型定义
export type ConfigKey = 
  | 'theme'
  | 'language'
  | 'videoQuality'
  | 'playbackSpeed'
  | 'autoPlay'
  | 'autoNextEpisode'
  | 'subtitleEnabled'
  | 'subtitleSize'
  | 'subtitleColor'
  | 'subtitleDelay'
  | 'interfaceScale'
  | 'cacheEnabled'
  | 'cacheLimit'
  | 'networkTimeout'
  | 'proxyEnabled'
  | 'proxyConfig'
  | 'notificationEnabled'
  | 'updateCheckEnabled'
  | 'crashReportingEnabled'
  | 'analyticsEnabled'
  | 'startupScreen'
  | 'homeLayout'
  | 'favoriteSort'
  | 'historySort'
  | 'searchSort'
  | 'maxConcurrentDownloads'
  | 'downloadNetworkType'
  | 'parentalControlEnabled'
  | 'parentalControlPin'
  | 'recentlyWatchedLimit'
  | 'dataSaverEnabled'
  | 'streamingEnabled'
  | 'localPlaybackEnabled'
  | 'showAdultContent'
  | 'defaultCategory'
  | 'preferredServer'
  | 'videoPlayerSettings'
  | 'uiAnimationEnabled'
  | 'backgroundPlayEnabled'
  | 'customHeaders'
  | 'customCookies';

// 配置值类型定义
export type ConfigValue = 
  | string
  | number
  | boolean
  | object
  | null;

// 播放器配置接口
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

// 显示配置接口
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

// 网络配置接口
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

// 代理配置接口
export interface ProxyConfig {
  type: string;
  host: string;
  port: number;
}

// 存储配置接口
export interface StorageConfig {
  cachePath: string;
  downloadPath: string;
  maxCacheSize: number;
  autoClearCache: boolean;
  clearCacheInterval: number;
  enableBackgroundCleanup: boolean;
}

// 通用配置接口
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

// 安全配置接口
export interface SecurityConfig {
  enablePinCode: boolean;
  pinCode: string;
  enableBiometric: boolean;
  allowedApps: string[];
  lockTimeout: number;
  secureContentOnly: boolean;
}

// 通知配置接口
export interface NotificationConfig {
  enablePush: boolean;
  enableUpdateNotification: boolean;
  enableContentNotification: boolean;
  enableLiveReminder: boolean;
  notificationSound: string;
  notificationVolume: number;
}

// 无障碍配置接口
export interface AccessibilityConfig {
  enableHighContrast: boolean;
  enableScreenReader: boolean;
  textToSpeechRate: number;
  closedCaptionEnabled: boolean;
  audioDescriptionEnabled: boolean;
  hapticFeedbackEnabled: boolean;
}

// 直播配置接口
export interface LiveConfig {
  epgEnabled: boolean;
  epgAutoUpdate: boolean;
  epgUpdateInterval: number;
  channelFavoritesEnabled: boolean;
  lastWatchedChannel: string;
  lastWatchedGroup: string;
}

// VOD配置接口
export interface VodConfig {
  autoPlayNextEpisode: boolean;
  showRecommendedContent: boolean;
  contentRating: string;
  downloadQuality: string;
  streamingQuality: string;
}

// 完整配置接口
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

// 选项项接口
export interface OptionItem {
  label: string;
  value: ConfigValue;
}

// 验证配置接口
export interface ValidationConfig {
  min?: number;
  max?: number;
  pattern?: string;
  required?: boolean;
}

// 配置项接口
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

// 配置导入结果接口
export interface ConfigImportResult {
  imported: number;
  skipped: number;
  invalid: number;
}

// 批量配置项接口
export interface BatchConfigItem {
  key: ConfigKey;
  value: ConfigValue;
}

// 批量配置结果接口
export interface BatchConfigResult {
  updated: number;
  failed: number;
}

// 完整默认配置
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

// 配置项默认配置 - 使用更安全的方式创建，避免对象字面量类型问题
export const DEFAULT_CONFIG: Record<ConfigKey, ConfigValue> = {} as Record<ConfigKey, ConfigValue>;

// 逐个添加属性，避免对象字面量类型问题
// 界面相关
DEFAULT_CONFIG.theme = 'dark';
DEFAULT_CONFIG.language = 'auto';
DEFAULT_CONFIG.interfaceScale = 100;
DEFAULT_CONFIG.uiAnimationEnabled = true;
DEFAULT_CONFIG.startupScreen = 'home';
DEFAULT_CONFIG.homeLayout = 'default';

// 视频播放相关
DEFAULT_CONFIG.videoQuality = 'high';
DEFAULT_CONFIG.playbackSpeed = 1.0;
DEFAULT_CONFIG.autoPlay = true;
DEFAULT_CONFIG.autoNextEpisode = true;
DEFAULT_CONFIG.backgroundPlayEnabled = false;
DEFAULT_CONFIG.videoPlayerSettings = {} as Record<string, string | number | boolean>;

// 字幕相关
DEFAULT_CONFIG.subtitleEnabled = true;
DEFAULT_CONFIG.subtitleSize = 16;
DEFAULT_CONFIG.subtitleColor = '#FFFFFF';
DEFAULT_CONFIG.subtitleDelay = 0;

// 缓存相关
DEFAULT_CONFIG.cacheEnabled = true;
DEFAULT_CONFIG.cacheLimit = 5000; // MB

// 网络相关
DEFAULT_CONFIG.networkTimeout = 30; // 秒
DEFAULT_CONFIG.proxyEnabled = false;
DEFAULT_CONFIG.proxyConfig = null;
DEFAULT_CONFIG.dataSaverEnabled = false;
DEFAULT_CONFIG.customHeaders = {} as Record<string, string>;
DEFAULT_CONFIG.customCookies = {} as Record<string, string>;

// 通知相关
DEFAULT_CONFIG.notificationEnabled = true;

// 更新相关
DEFAULT_CONFIG.updateCheckEnabled = true;

// 数据收集相关
DEFAULT_CONFIG.crashReportingEnabled = false;
DEFAULT_CONFIG.analyticsEnabled = false;

// 排序相关
DEFAULT_CONFIG.favoriteSort = 'addedAt_desc';
DEFAULT_CONFIG.historySort = 'timestamp_desc';
DEFAULT_CONFIG.searchSort = 'relevance_desc';

// 下载相关
DEFAULT_CONFIG.maxConcurrentDownloads = 3;
DEFAULT_CONFIG.downloadNetworkType = 'all'; // all, wifi, cellular

// 家长控制
DEFAULT_CONFIG.parentalControlEnabled = false;
DEFAULT_CONFIG.parentalControlPin = null;
DEFAULT_CONFIG.showAdultContent = false;

// 其他
DEFAULT_CONFIG.recentlyWatchedLimit = 20;
DEFAULT_CONFIG.streamingEnabled = true;
DEFAULT_CONFIG.localPlaybackEnabled = true;
DEFAULT_CONFIG.defaultCategory = 'all';
DEFAULT_CONFIG.preferredServer = 'auto';

// 配置分类
export const CONFIG_CATEGORIES: Record<string, string> = {};

// 验证结果接口
export interface ValidationResult {
  isValid: boolean;
  errorMessage?: string;
}

/**
 * 配置服务
 * 负责管理应用的各种配置设置
 */
export default class ConfigService {
  private static instance: ConfigService;
  private configCache: Map<ConfigKey, ConfigItem> = new Map();
  private configParser: ConfigParser;
  private fullConfig: Config = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
  private isInitialized: boolean = false;

  /**
   * 构造函数（私有，防止外部实例化）
   */
  private constructor() {
    this.configParser = ConfigParser.getInstance();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): ConfigService {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
    }
    return ConfigService.instance;
  }

  /**
   * 获取对象的所有键
   * 替代Object.keys，兼容ArkTS语法
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    return Object.keys(obj);
  }
  
  /**
   * 获取完整配置
   */
  public async getFullConfig(): Promise<Config> {
    if (!this.isInitialized) {
      await this.initializeConfig();
    }
    return JSON.parse(JSON.stringify(this.fullConfig));
  }
  
  /**
   * 合并配置
   */
  private mergeConfig<T>(defaultConfig: T, customConfig: Record<string, string | number | boolean | Record<string, string | number | boolean>>): T {
    // 使用ArkTS兼容的对象合并方法
    if (!customConfig || typeof customConfig !== 'object' || Array.isArray(customConfig)) {
      return defaultConfig;
    }
    
    const result = JSON.parse(JSON.stringify(defaultConfig)) as T;
    
    const customKeys = Object.keys(customConfig);
    for (let i = 0; i < customKeys.length; i++) {
      const key = customKeys[i];
      const customValue = customConfig[key];
      const defaultValue = (defaultConfig as Record<string, string | number | boolean | Record<string, string | number | boolean>>)[key];
      
      // 递归合并嵌套对象
      if (customValue && typeof customValue === 'object' && !Array.isArray(customValue) && 
          defaultValue && typeof defaultValue === 'object' && !Array.isArray(defaultValue)) {
        (result as Record<string, string | number | boolean | Record<string, string | number | boolean>>)[key] = this.mergeConfig(defaultValue, customValue as Record<string, string | number | boolean | Record<string, string | number | boolean>>);
      } else if (customValue !== undefined) {
        (result as Record<string, string | number | boolean | Record<string, string | number | boolean>>)[key] = customValue;
      }
    }
    
    return result;
  }
  
  /**
   * 确保默认配置存在
   */
  private ensureDefaultConfig(): void {
    // 更新最后更新时间
    this.fullConfig.general.lastUpdated = Date.now();
    
    // 验证必要的配置项
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
   * 更新完整配置
   */
  public async updateFullConfig(customConfig: Partial<Config>): Promise<ApiResponse<Config>> {
    try {
      // 合并配置 - 使用类型安全的方式
      const safeConfig = JSON.parse(JSON.stringify(customConfig)) as Record<string, string | number | boolean | Record<string, string | number | boolean>>;
      this.fullConfig = this.mergeConfig(this.fullConfig, safeConfig);
      this.ensureDefaultConfig();
      
      // 保存到存储
      await StorageUtil.set('app_full_config', JSON.parse(JSON.stringify(this.fullConfig)));
      
      return ApiResponse.success(this.fullConfig, '配置更新成功');
    } catch (error) {
      Logger.error(TAG, `Failed to update full config`);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '配置更新失败');
    }
  }
  
  /**
   * 添加配置更改监听
   */
  private configListeners: Array<(config: Config) => void> = [];
  
  /**
   * 添加配置更改监听
   */
  public addConfigListener(listener: (config: Config) => void): void {
    this.configListeners.push(listener);
  }
  
  /**
   * 移除配置更改监听
   */
  public removeConfigListener(listener: (config: Config) => void): void {
    const index = this.configListeners.indexOf(listener);
    if (index > -1) {
      this.configListeners.splice(index, 1);
    }
  }

  /**
   * 初始化配置
   */
  private async initializeConfig(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing configuration...');
      
      // 1. 首先尝试加载完整配置
      await this.loadFullConfig();
      
      // 初始化数据结构
      this.configCache = new Map();
      
      // 合并默认配置和数据库配置
      const defaultConfigKeys = Object.keys(DEFAULT_CONFIG);
      for (let i = 0; i < defaultConfigKeys.length; i++) {
        const key = defaultConfigKeys[i] as ConfigKey;
        const defaultValue = DEFAULT_CONFIG[key];
        
        // 创建默认配置项
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
      
      // 确保默认配置完整
      this.ensureDefaultConfig();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Configuration initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize configuration: ${error instanceof Error ? error.message : String(error)}`);
      // 初始化失败时使用默认配置
      this.fullConfig = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
      this.ensureDefaultConfig();
      this.isInitialized = true;
    }
  }
  
  /**
   * 加载完整配置
   */
  private async loadFullConfig(): Promise<void> {
    try {
      // 尝试从本地存储加载完整配置
      const storedConfig = await StorageUtil.get('app_full_config');
      
      if (storedConfig && typeof storedConfig === 'object') {
        // 合并存储的配置和默认配置 - 避免unknown类型转换
        const safeStoredConfig = JSON.parse(JSON.stringify(storedConfig)) as Record<string, string | number | boolean | Record<string, string | number | boolean>>;
        this.fullConfig = this.mergeConfig(DEFAULT_FULL_CONFIG, safeStoredConfig);
        Logger.info(TAG, 'Loaded full configuration from storage');
      } else {
        // 使用默认配置
        this.fullConfig = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
        await StorageUtil.set('app_full_config', JSON.parse(JSON.stringify(this.fullConfig)));
        Logger.info(TAG, 'Using default full configuration');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load full configuration`);
      // 加载失败时使用默认配置
      this.fullConfig = JSON.parse(JSON.stringify(DEFAULT_FULL_CONFIG));
    }
  }

  /**
   * 获取配置
   */
  public async getConfig(key: ConfigKey): Promise<ApiResponse<ConfigValue>> {
    try {
      Logger.debug(TAG, `Getting config for key: ${key}`);
      
      // 检查缓存
      if (this.configCache.has(key)) {
        const config = this.configCache.get(key)!;
        return ApiResponse.success(config.value, `获取配置[${key}]成功`);
      }
      
      // 返回默认值
      const defaultValue = DEFAULT_CONFIG[key];
      return ApiResponse.success(defaultValue, `配置[${key}]不存在，返回默认值`);
    } catch (error) {
      Logger.error(TAG, `Failed to get config for key: ${key}`);
      // 发生错误时返回默认值
      const defaultValue = DEFAULT_CONFIG[key];
      return ApiResponse.success(defaultValue, `获取配置失败，返回默认值`);
    }
  }

  /**
   * 获取部分配置
   */
  public async getPartialConfig(key: keyof Config): Promise<PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig> {
    if (!this.isInitialized) {
      await this.initializeConfig();
    }
    
    let configSection: PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig | undefined;
    
    // 手动处理不同配置部分的访问
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
      // 如果配置部分不存在，从默认配置获取
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
   * 更新部分配置
   */
  public async updatePartialConfig(key: keyof Config, sectionConfig: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): Promise<ApiResponse<PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig>> {
    try {
      if (!this.isInitialized) {
        await this.initializeConfig();
      }
      
      // 更新部分配置
      let updatedSection: PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig;
      
      // 手动处理不同配置部分的访问和更新
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
      
      // 手动合并属性 - 使用类型安全的方式访问属性，避免使用unknown
      const sectionKeys = Object.keys(sectionConfig);
      const sectionConfigObj = sectionConfig as Record<string, string | number | boolean | object | null>;
      
      // 根据配置类型，使用不同的赋值方式，避免使用unknown类型转换
      // 将sectionConfigObj转换为正确的类型，避免object类型导致的索引签名问题
      const typedConfig = sectionConfigObj as Record<string, string | number | boolean | Record<string, string | number | boolean> | null>;
      switch (key) {
        case 'player':
          this.mergePlayerConfig(updatedSection as PlayerConfig, typedConfig);
          break;
        case 'display':
          this.mergeDisplayConfig(updatedSection as DisplayConfig, typedConfig);
          break;
        case 'network':
          this.mergeNetworkConfig(updatedSection as NetworkConfig, typedConfig);
          break;
        case 'storage':
          this.mergeStorageConfig(updatedSection as StorageConfig, typedConfig);
          break;
        case 'general':
          this.mergeGeneralConfig(updatedSection as GeneralConfig, typedConfig);
          break;
        case 'security':
          this.mergeSecurityConfig(updatedSection as SecurityConfig, typedConfig);
          break;
        case 'notification':
          this.mergeNotificationConfig(updatedSection as NotificationConfig, typedConfig);
          break;
        case 'accessibility':
          this.mergeAccessibilityConfig(updatedSection as AccessibilityConfig, typedConfig);
          break;
        case 'live':
          this.mergeLiveConfig(updatedSection as LiveConfig, typedConfig);
          break;
        case 'vod':
          this.mergeVodConfig(updatedSection as VodConfig, typedConfig);
          break;
      }
      
      // 更新配置部分
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
      
      // 更新最后修改时间
      this.fullConfig.general.lastUpdated = Date.now();
      
      // 保存到存储
      await StorageUtil.set('app_full_config', JSON.parse(JSON.stringify(this.fullConfig)));
      
      // 返回更新后的配置部分
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
          finalConfigSection = this.fullConfig.general; // 默认为general配置
          break;
      }
      
      return ApiResponse.success(finalConfigSection, '配置更新成功');
    } catch (error) {
      Logger.error(TAG, `Failed to update partial config for key: ${String(key)}`);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '配置更新失败');
    }
  }

  /**
   * 获取配置项详情
   */
  public async getConfigItem(key: ConfigKey): Promise<ApiResponse<ConfigItem>> {
    try {
      Logger.debug(TAG, `Getting config item for key: ${key}`);
      
      // 检查缓存
      if (this.configCache.has(key)) {
        const config = this.configCache.get(key)!;
        return ApiResponse.success(config, `获取配置项[${key}]成功`);
      }
      
      // 创建并返回默认配置项
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
      Logger.error(TAG, `Failed to get config item for key: ${key}`);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `获取配置项失败`);
    }
  }

  /**
   * 设置配置
   */
  public async setConfig(key: ConfigKey, value: ConfigValue): Promise<ApiResponse<ConfigItem>> {
    try {
      Logger.info(TAG, `Setting config: ${key} = ${JSON.stringify(value)}`);
      
      // 验证配置值
      const validationResult = this.validateConfigValue(key, value);
      if (!validationResult.isValid) {
        return ApiResponse.validationError([
          { field: key, message: validationResult.errorMessage || '配置值无效' }
        ]);
      }
      
      // 获取或创建配置项
      let configItem: ConfigItem;
      
      if (this.configCache.has(key)) {
        // 更新现有配置
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
        // 创建新配置
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
      
      // 更新缓存
      this.configCache.set(key, configItem);
      
      // 触发配置更改事件
      this.notifyConfigChanged(key, value);
      
      Logger.info(TAG, `Config updated successfully: ${key}`);
      return ApiResponse.success(configItem, `设置配置[${key}]成功`);
    } catch (error) {
      Logger.error(TAG, `Failed to set config: ${key}`);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `设置配置失败`);
    }
  }

  /**
   * 批量设置配置
   */
  public async setMultipleConfig(configs: BatchConfigItem[]): Promise<ApiResponse<BatchConfigResult>> {
    try {
      Logger.info(TAG, `Setting multiple configs: ${configs.length} items`);
      
      let updated = 0;
      let failed = 0;
      
      for (let i = 0; i < configs.length; i++) {
        const configItem = configs[i];
        const key = configItem.key;
        const value = configItem.value;
        try {
          // 验证配置值
          const validationResult = this.validateConfigValue(key, value);
          if (!validationResult.isValid) {
            Logger.warn(TAG, `Invalid config value for ${key}: ${validationResult.errorMessage}`);
            failed++;
            continue;
          }
          
          // 更新配置
          await this.setConfig(key, value);
          updated++;
        } catch (error) {
          Logger.warn(TAG, `Failed to update config ${key}`);
          failed++;
        }
      }
      
      Logger.info(TAG, `Multiple configs updated: ${updated} success, ${failed} failed`);
      const result: BatchConfigResult = {
        updated,
        failed
      };
      return ApiResponse.success(
        result,
        `批量更新配置完成，成功${updated}项，失败${failed}项`
      );
    } catch (error) {
      Logger.error(TAG, 'Failed to set multiple configs');
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '批量更新配置失败');
    }
  }

  /**
   * 重置配置为默认值
   */
  public async resetConfig(key: ConfigKey): Promise<ApiResponse<ConfigItem>> {
    try {
      Logger.info(TAG, `Resetting config to default: ${key}`);
      
      const defaultValue = DEFAULT_CONFIG[key];
      
      // 更新配置项
      const configItem: ConfigItem = {
        key,
        value: defaultValue,
        type: this.getValueType(defaultValue),
        defaultValue,
        category: this.getConfigCategory(key),
        updatedAt: Date.now(),
        createdAt: this.configCache.has(key) ? this.configCache.get(key)!.createdAt : Date.now()
      };
      
      // 更新缓存
      this.configCache.set(key, configItem);
      
      // 触发配置更改事件
      this.notifyConfigChanged(key, defaultValue);
      
      Logger.info(TAG, `Config reset successfully: ${key}`);
      return ApiResponse.success(configItem, `重置配置[${key}]成功`);
    } catch (error) {
      Logger.error(TAG, `Failed to reset config: ${key}`);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '重置配置失败');
    }
  }

  /**
   * 重置所有配置为默认值
   */
  public async resetAllConfig(): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Resetting all config to default values');
      
      // 清空缓存
      this.configCache.clear();
      
      // 重新初始化配置
      await this.initializeConfig();
      
      // 触发配置重置事件
      this.notifyConfigReset();
      
      Logger.info(TAG, 'All config reset successfully');
      return ApiResponse.success(true, '重置所有配置成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to reset all config');
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '重置所有配置失败');
    }
  }

  /**
   * 获取所有配置
   */
  public async getAllConfig(category?: string): Promise<ApiResponse<ConfigItem[]>> {
    try {
      Logger.info(TAG, `Getting all configs${category ? ` for category: ${category}` : ''}`);
      
      let allConfigs: ConfigItem[];
      
      if (category) {
        // 按分类获取
        allConfigs = Array.from(this.configCache.values())
          .filter(item => item.category === category);
      } else {
        // 获取所有
        allConfigs = Array.from(this.configCache.values());
      }
      
      return ApiResponse.success(allConfigs, `获取配置列表成功，共${allConfigs.length}项`);
    } catch (error) {
      Logger.error(TAG, 'Failed to get all configs');
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取配置列表失败');
    }
  }

  /**
   * 验证配置值
   */
  private validateConfigValue(key: ConfigKey, value: ConfigValue): ValidationResult {
    // 获取默认值类型
    const defaultValue = DEFAULT_CONFIG[key];
    if (defaultValue === undefined) {
      return { isValid: false, errorMessage: `未知的配置项: ${key}` };
    }
    
    // 检查类型
    const expectedType = this.getValueType(defaultValue);
    const actualType = this.getValueType(value);
    
    if (expectedType !== actualType) {
      return { 
        isValid: false, 
        errorMessage: `配置类型错误，期望${expectedType}，实际${actualType}` 
      };
    }
    
    // 对特定配置进行额外验证
    switch (key) {
      case 'cacheLimit':
        if (typeof value === 'number' && (value < 0 || value > 50000)) {
          return { isValid: false, errorMessage: '缓存限制必须在0-50000MB之间' };
        }
        break;
        
      case 'networkTimeout':
        if (typeof value === 'number' && (value < 5 || value > 300)) {
          return { isValid: false, errorMessage: '网络超时必须在5-300秒之间' };
        }
        break;
        
      case 'subtitleSize':
        if (typeof value === 'number' && (value < 10 || value > 48)) {
          return { isValid: false, errorMessage: '字幕大小必须在10-48之间' };
        }
        break;
        
      case 'maxConcurrentDownloads':
        if (typeof value === 'number' && (value < 1 || value > 10)) {
          return { isValid: false, errorMessage: '最大并发下载数必须在1-10之间' };
        }
        break;
        
      case 'interfaceScale':
        if (typeof value === 'number' && (value < 50 || value > 200)) {
          return { isValid: false, errorMessage: '界面缩放必须在50%-200%之间' };
        }
        break;
        
      case 'parentalControlPin':
        if (value && typeof value === 'string' && !/^\d{4,6}$/.test(value)) {
          return { isValid: false, errorMessage: '家长控制PIN码必须是4-6位数字' };
        }
        break;
    }
    
    return { isValid: true };
  }

  /**
   * 获取值的类型
   */
  private getValueType(value: ConfigValue): 'string' | 'number' | 'boolean' | 'object' | 'null' {
    if (value === null) return 'null';
    if (Array.isArray(value)) return 'object';
    return typeof value as 'string' | 'number' | 'boolean' | 'object';
  }

  /**
   * 获取配置分类
   */
  private getConfigCategory(key: ConfigKey): string {
    return 'other';
  }

  // ========== 事件通知机制 ==========
  
  private configItemListeners: Map<string, Array<(value: ConfigValue) => void>> = new Map();
  private globalListeners: Array<(key: ConfigKey, value: ConfigValue) => void> = [];
  private resetListeners: Array<() => void> = [];

  /**
   * 监听特定配置项更改
   */
  public addConfigItemListener(key: ConfigKey, listener: (value: ConfigValue) => void): () => void {
    const keyStr = key as string;
    if (!this.configItemListeners.has(keyStr)) {
      this.configItemListeners.set(keyStr, []);
    }
    
    const listeners = this.configItemListeners.get(keyStr)!;
    listeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加全局配置监听
   */
  public addGlobalConfigListener(listener: (key: ConfigKey, value: ConfigValue) => void): () => void {
    this.globalListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.globalListeners.indexOf(listener);
      if (index > -1) {
        this.globalListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加配置重置监听
   */
  public addConfigResetListener(listener: () => void): () => void {
    this.resetListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.resetListeners.indexOf(listener);
      if (index > -1) {
        this.resetListeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知配置更改
   */
  private notifyConfigChanged(key: ConfigKey, value: ConfigValue): void {
    // 通知特定配置的监听器
    const keyStr = key as string;
    if (this.configItemListeners.has(keyStr)) {
      const listeners = this.configItemListeners.get(keyStr)!;
      for (const listener of listeners) {
        try {
          listener(value);
        } catch (error) {
          Logger.error(TAG, `Error in config listener for ${key}`);
        }
      }
    }
    
    // 通知全局监听器
    for (const listener of this.globalListeners) {
      try {
        listener(key, value);
      } catch (error) {
        Logger.error(TAG, `Error in global config listener`);
      }
    }
  }

  /**
   * 通知配置重置
   */
  private notifyConfigReset(): void {
    for (const listener of this.resetListeners) {
      try {
        listener();
      } catch (error) {
        Logger.error(TAG, `Error in config reset listener`);
      }
    }
  }
  
  // ========== 配置合并方法 ==========
  
  private mergePlayerConfig(config: PlayerConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.defaultPlayer !== undefined) config.defaultPlayer = updates.defaultPlayer as string;
    if (updates.autoPlay !== undefined) config.autoPlay = updates.autoPlay as boolean;
    if (updates.rememberPosition !== undefined) config.rememberPosition = updates.rememberPosition as boolean;
    if (updates.maxBufferSize !== undefined) config.maxBufferSize = updates.maxBufferSize as number;
    if (updates.minBufferSize !== undefined) config.minBufferSize = updates.minBufferSize as number;
    if (updates.preloadSeconds !== undefined) config.preloadSeconds = updates.preloadSeconds as number;
    if (updates.enableHardwareDecoding !== undefined) config.enableHardwareDecoding = updates.enableHardwareDecoding as boolean;
    if (updates.enableHDR !== undefined) config.enableHDR = updates.enableHDR as boolean;
    if (updates.subtitleSize !== undefined) config.subtitleSize = updates.subtitleSize as number;
    if (updates.subtitleColor !== undefined) config.subtitleColor = updates.subtitleColor as string;
    if (updates.subtitleBackgroundColor !== undefined) config.subtitleBackgroundColor = updates.subtitleBackgroundColor as string;
    if (updates.audioTrack !== undefined) config.audioTrack = updates.audioTrack as string;
    if (updates.videoTrack !== undefined) config.videoTrack = updates.videoTrack as string;
  }
  
  private mergeDisplayConfig(config: DisplayConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.theme !== undefined) config.theme = updates.theme as string;
    if (updates.fontScale !== undefined) config.fontScale = updates.fontScale as number;
    if (updates.enableAnimations !== undefined) config.enableAnimations = updates.enableAnimations as boolean;
    if (updates.enableBlur !== undefined) config.enableBlur = updates.enableBlur as boolean;
    if (updates.autoRotate !== undefined) config.autoRotate = updates.autoRotate as boolean;
    if (updates.resolution !== undefined) config.resolution = updates.resolution as string;
    if (updates.screenSaverDelay !== undefined) config.screenSaverDelay = updates.screenSaverDelay as number;
    if (updates.idleTimeout !== undefined) config.idleTimeout = updates.idleTimeout as number;
  }
  
  private mergeNetworkConfig(config: NetworkConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.timeout !== undefined) config.timeout = updates.timeout as number;
    if (updates.retryCount !== undefined) config.retryCount = updates.retryCount as number;
    if (updates.retryDelay !== undefined) config.retryDelay = updates.retryDelay as number;
    if (updates.enableCache !== undefined) config.enableCache = updates.enableCache as boolean;
    if (updates.cacheSize !== undefined) config.cacheSize = updates.cacheSize as number;
    if (updates.autoDetectNetwork !== undefined) config.autoDetectNetwork = updates.autoDetectNetwork as boolean;
    if (updates.useProxy !== undefined) config.useProxy = updates.useProxy as boolean;
    if (updates.proxyConfig !== undefined) {
      const proxyConfig = updates.proxyConfig as Record<string, string | number | boolean>;
      config.proxyConfig = {
        type: (proxyConfig.type as string) || 'none',
        host: (proxyConfig.host as string) || '',
        port: (proxyConfig.port as number) || 0
      };
    }
  }
  
  private mergeStorageConfig(config: StorageConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.cachePath !== undefined) config.cachePath = updates.cachePath as string;
    if (updates.downloadPath !== undefined) config.downloadPath = updates.downloadPath as string;
    if (updates.maxCacheSize !== undefined) config.maxCacheSize = updates.maxCacheSize as number;
    if (updates.autoClearCache !== undefined) config.autoClearCache = updates.autoClearCache as boolean;
    if (updates.clearCacheInterval !== undefined) config.clearCacheInterval = updates.clearCacheInterval as number;
    if (updates.enableBackgroundCleanup !== undefined) config.enableBackgroundCleanup = updates.enableBackgroundCleanup as boolean;
  }
  
  private mergeGeneralConfig(config: GeneralConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.language !== undefined) config.language = updates.language as string;
    if (updates.region !== undefined) config.region = updates.region as string;
    if (updates.timeZone !== undefined) config.timeZone = updates.timeZone as string;
    if (updates.enableAnalytics !== undefined) config.enableAnalytics = updates.enableAnalytics as boolean;
    if (updates.enableUsageReport !== undefined) config.enableUsageReport = updates.enableUsageReport as boolean;
    if (updates.firstLaunch !== undefined) config.firstLaunch = updates.firstLaunch as boolean;
    if (updates.version !== undefined) config.version = updates.version as string;
    if (updates.lastUpdated !== undefined) config.lastUpdated = updates.lastUpdated as number;
  }
  
  private mergeSecurityConfig(config: SecurityConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.enablePinCode !== undefined) config.enablePinCode = updates.enablePinCode as boolean;
    if (updates.pinCode !== undefined) config.pinCode = updates.pinCode as string;
    if (updates.enableBiometric !== undefined) config.enableBiometric = updates.enableBiometric as boolean;
    if (updates.allowedApps !== undefined) {
      // 确保allowedApps是数组类型
      const allowedApps = updates.allowedApps;
      if (Array.isArray(allowedApps)) {
        config.allowedApps = allowedApps as string[];
      } else {
        config.allowedApps = [];
      }
    }
    if (updates.lockTimeout !== undefined) config.lockTimeout = updates.lockTimeout as number;
    if (updates.secureContentOnly !== undefined) config.secureContentOnly = updates.secureContentOnly as boolean;
  }
  
  private mergeNotificationConfig(config: NotificationConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.enablePush !== undefined) config.enablePush = updates.enablePush as boolean;
    if (updates.enableUpdateNotification !== undefined) config.enableUpdateNotification = updates.enableUpdateNotification as boolean;
    if (updates.enableContentNotification !== undefined) config.enableContentNotification = updates.enableContentNotification as boolean;
    if (updates.enableLiveReminder !== undefined) config.enableLiveReminder = updates.enableLiveReminder as boolean;
    if (updates.notificationSound !== undefined) config.notificationSound = updates.notificationSound as string;
    if (updates.notificationVolume !== undefined) config.notificationVolume = updates.notificationVolume as number;
  }
  
  private mergeAccessibilityConfig(config: AccessibilityConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.enableHighContrast !== undefined) config.enableHighContrast = updates.enableHighContrast as boolean;
    if (updates.enableScreenReader !== undefined) config.enableScreenReader = updates.enableScreenReader as boolean;
    if (updates.textToSpeechRate !== undefined) config.textToSpeechRate = updates.textToSpeechRate as number;
    if (updates.closedCaptionEnabled !== undefined) config.closedCaptionEnabled = updates.closedCaptionEnabled as boolean;
    if (updates.audioDescriptionEnabled !== undefined) config.audioDescriptionEnabled = updates.audioDescriptionEnabled as boolean;
    if (updates.hapticFeedbackEnabled !== undefined) config.hapticFeedbackEnabled = updates.hapticFeedbackEnabled as boolean;
  }
  
  private mergeLiveConfig(config: LiveConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.epgEnabled !== undefined) config.epgEnabled = updates.epgEnabled as boolean;
    if (updates.epgAutoUpdate !== undefined) config.epgAutoUpdate = updates.epgAutoUpdate as boolean;
    if (updates.epgUpdateInterval !== undefined) config.epgUpdateInterval = updates.epgUpdateInterval as number;
    if (updates.channelFavoritesEnabled !== undefined) config.channelFavoritesEnabled = updates.channelFavoritesEnabled as boolean;
    if (updates.lastWatchedChannel !== undefined) config.lastWatchedChannel = updates.lastWatchedChannel as string;
    if (updates.lastWatchedGroup !== undefined) config.lastWatchedGroup = updates.lastWatchedGroup as string;
  }
  
  private mergeVodConfig(config: VodConfig, updates: Record<string, string | number | boolean | Record<string, string | number | boolean> | null>): void {
    if (updates.autoPlayNextEpisode !== undefined) config.autoPlayNextEpisode = updates.autoPlayNextEpisode as boolean;
    if (updates.showRecommendedContent !== undefined) config.showRecommendedContent = updates.showRecommendedContent as boolean;
    if (updates.contentRating !== undefined) config.contentRating = updates.contentRating as string;
    if (updates.downloadQuality !== undefined) config.downloadQuality = updates.downloadQuality as string;
    if (updates.streamingQuality !== undefined) config.streamingQuality = updates.streamingQuality as string;
  }

  // ========== 配置导出/导入 ==========

  /**
   * 导出配置
   */
  public async exportConfig(): Promise<ApiResponse<string>> {
    try {
      Logger.info(TAG, 'Exporting configuration...');
      
      const allConfigs = await this.getAllConfig();
      
      if (!allConfigs.isSuccess() || !allConfigs.data) {
        return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取配置失败，无法导出');
      }
      
      const exportData: ConfigExportData = {
        exportDate: new Date().toISOString(),
        version: '1.0',
        configs: allConfigs.data.map(item => ({
          key: item.key,
          value: item.value,
          updatedAt: item.updatedAt
        } as ConfigExportItem))
      };
      
      // 使用ConfigParser格式化导出数据
      const jsonStr = JSON.stringify(exportData, null, 2);
      return ApiResponse.success(jsonStr, '导出配置成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to export config');
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导出配置失败');
    }
  }

  /**
   * 导入配置
   */
  public async importConfig(jsonData: string, merge: boolean = true): Promise<ApiResponse<ConfigImportResult>> {
    try {
      Logger.info(TAG, 'Importing configuration...');
      
      // 使用提前定义的接口，避免对象字面量作为类型声明
      interface ImportData {
        configs?: ConfigExportItem[];
      }
      const importData = JSON.parse(jsonData) as ImportData;
      const configs = importData.configs || [];
      
      let imported = 0;
      let skipped = 0;
      let invalid = 0;
      
      for (const configData of configs) {
        // 替换解构声明，直接访问属性
        const key = configData.key;
        const value = configData.value;
        
        // 验证配置项
        if (!key) {
          invalid++;
          continue;
        }
        
        // 使用数组includes替代hasOwnProperty
        const configKeys: string[] = Object.keys(DEFAULT_CONFIG);
        if (!configKeys.includes(key)) {
          invalid++;
          continue;
        }
        
        const configKey = key as ConfigKey;
        
        // 验证配置值
        const validationResult = this.validateConfigValue(configKey, value);
        if (!validationResult.isValid) {
          invalid++;
          continue;
        }
        
        // 导入配置
        await this.setConfig(configKey, value);
        imported++;
      }
      
      Logger.info(TAG, `Configuration import completed: imported=${imported}, skipped=${skipped}, invalid=${invalid}`);
      
      // 使用明确的接口类型
      const result: ConfigImportResult = {
        imported,
        skipped,
        invalid
      };
      
      return ApiResponse.success(
        result,
        `导入配置完成，成功${imported}项，跳过${skipped}项，无效${invalid}项`
      );
    } catch (error) {
      Logger.error(TAG, 'Failed to import config');
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导入配置失败，请检查数据格式');
    }
  }
}