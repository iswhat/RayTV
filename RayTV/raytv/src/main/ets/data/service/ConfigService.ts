// ConfigService - 配置管理服务
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import { Config } from '../bean/Config';
import ConfigRepository from '../repository/ConfigRepository';

const TAG = 'ConfigService';
const CONFIG_STORAGE_KEY = 'app_config';
const DEFAULT_CONFIG: Config = {
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

export default class ConfigService {
  private static instance: ConfigService;
  private configRepository: ConfigRepository;
  private currentConfig: Config = { ...DEFAULT_CONFIG };
  private configListeners: Array<(config: Config) => void> = [];
  private isInitialized: boolean = false;

  private constructor() {
    this.configRepository = ConfigRepository.getInstance();
    this.initialize();
  }

  public static getInstance(): ConfigService {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
    }
    return ConfigService.instance;
  }

  /**
   * 初始化配置服务
   */
  private async initialize(): Promise<void> {
    try {
      // 从存储加载配置
      const storedConfig = await this.configRepository.getConfig();
      if (storedConfig) {
        this.currentConfig = this.mergeConfig(DEFAULT_CONFIG, storedConfig);
      }
      
      // 确保必要的配置存在
      this.ensureDefaultConfig();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Configuration service initialized');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize configuration service', error);
      // 使用默认配置
      this.currentConfig = { ...DEFAULT_CONFIG };
      this.isInitialized = true;
    }
  }

  /**
   * 合并配置
   */
  private mergeConfig(defaultConfig: Config, customConfig: Partial<Config>): Config {
    const merged = { ...defaultConfig };
    
    Object.keys(customConfig).forEach(key => {
      const configKey = key as keyof Config;
      if (typeof customConfig[configKey] === 'object' && customConfig[configKey] !== null) {
        merged[configKey] = {
          ...merged[configKey],
          ...customConfig[configKey]
        };
      } else if (customConfig[configKey] !== undefined) {
        merged[configKey] = customConfig[configKey] as any;
      }
    });
    
    return merged;
  }

  /**
   * 确保默认配置存在
   */
  private ensureDefaultConfig(): void {
    // 更新最后更新时间
    this.currentConfig.general.lastUpdated = Date.now();
    
    // 验证必要的配置项
    if (!this.currentConfig.player) {
      this.currentConfig.player = DEFAULT_CONFIG.player;
    }
    if (!this.currentConfig.display) {
      this.currentConfig.display = DEFAULT_CONFIG.display;
    }
    if (!this.currentConfig.network) {
      this.currentConfig.network = DEFAULT_CONFIG.network;
    }
  }

  /**
   * 获取完整配置
   */
  public async getConfig(): Promise<Config> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    return { ...this.currentConfig };
  }

  /**
   * 获取播放器配置
   */
  public async getPlayerConfig(): Promise<Config['player']> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    return { ...this.currentConfig.player };
  }

  /**
   * 获取显示配置
   */
  public async getDisplayConfig(): Promise<Config['display']> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    return { ...this.currentConfig.display };
  }

  /**
   * 获取网络配置
   */
  public async getNetworkConfig(): Promise<Config['network']> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    return { ...this.currentConfig.network };
  }

  /**
   * 获取存储配置
   */
  public async getStorageConfig(): Promise<Config['storage']> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    return { ...this.currentConfig.storage };
  }

  /**
   * 更新配置
   */
  public async updateConfig(updates: Partial<Config>): Promise<Config> {
    try {
      // 合并配置
      const updatedConfig = this.mergeConfig(this.currentConfig, updates);
      
      // 保存到存储
      await this.configRepository.saveConfig(updatedConfig);
      
      // 更新当前配置
      this.currentConfig = updatedConfig;
      
      // 通知监听器
      this.notifyConfigChanged();
      
      Logger.info(TAG, 'Configuration updated successfully');
      return { ...this.currentConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to update configuration', error);
      throw error;
    }
  }

  /**
   * 更新播放器配置
   */
  public async updatePlayerConfig(updates: Partial<Config['player']>): Promise<Config> {
    return this.updateConfig({ player: { ...this.currentConfig.player, ...updates } });
  }

  /**
   * 更新显示配置
   */
  public async updateDisplayConfig(updates: Partial<Config['display']>): Promise<Config> {
    return this.updateConfig({ display: { ...this.currentConfig.display, ...updates } });
  }

  /**
   * 更新网络配置
   */
  public async updateNetworkConfig(updates: Partial<Config['network']>): Promise<Config> {
    return this.updateConfig({ network: { ...this.currentConfig.network, ...updates } });
  }

  /**
   * 重置配置到默认值
   */
  public async resetConfig(): Promise<Config> {
    try {
      this.currentConfig = { ...DEFAULT_CONFIG };
      await this.configRepository.saveConfig(this.currentConfig);
      this.notifyConfigChanged();
      Logger.info(TAG, 'Configuration reset to default values');
      return { ...this.currentConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to reset configuration', error);
      throw error;
    }
  }

  /**
   * 保存配置到持久化存储
   */
  public async saveConfig(): Promise<void> {
    try {
      await this.configRepository.saveConfig(this.currentConfig);
      Logger.info(TAG, 'Configuration saved to storage');
    } catch (error) {
      Logger.error(TAG, 'Failed to save configuration to storage', error);
      throw error;
    }
  }

  /**
   * 注册配置变更监听器
   */
  public addConfigListener(listener: (config: Config) => void): void {
    this.configListeners.push(listener);
  }

  /**
   * 移除配置变更监听器
   */
  public removeConfigListener(listener: (config: Config) => void): void {
    this.configListeners = this.configListeners.filter(l => l !== listener);
  }

  /**
   * 通知配置变更
   */
  private notifyConfigChanged(): void {
    const configCopy = { ...this.currentConfig };
    this.configListeners.forEach(listener => {
      try {
        listener(configCopy);
      } catch (error) {
        Logger.error(TAG, 'Error in config listener', error);
      }
    });
  }

  /**
   * 获取特定配置项
   */
  public async getConfigValue<T>(keyPath: string, defaultValue?: T): Promise<T> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    const keys = keyPath.split('.');
    let value: any = this.currentConfig;
    
    for (const key of keys) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        return defaultValue as T;
      }
    }
    
    return value as T;
  }

  /**
   * 设置特定配置项
   */
  public async setConfigValue(keyPath: string, value: any): Promise<Config> {
    const keys = keyPath.split('.');
    const updates: any = {};
    let current: any = updates;
    
    // 构建嵌套对象
    for (let i = 0; i < keys.length - 1; i++) {
      current[keys[i]] = {};
      current = current[keys[i]];
    }
    
    current[keys[keys.length - 1]] = value;
    
    return this.updateConfig(updates);
  }
}