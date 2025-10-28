// ConfigService - 配置服务类
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import RepositoryFactory from '../repository/RepositoryFactory';
import { DatabaseRepository } from '../repository/DatabaseRepository';
import ConfigParser from './ConfigParser';

// 导入模型和DTO
import ApiResponse, { ResponseCode } from '../dto/ApiResponse';

// 常量定义
const TAG = 'ConfigService';

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

// 配置项接口
export interface ConfigItem {
  key: ConfigKey;
  value: ConfigValue;
  description?: string;
  type: 'string' | 'number' | 'boolean' | 'object' | 'null';
  defaultValue: ConfigValue;
  category: string;
  options?: Array<{ label: string; value: ConfigValue }>;
  validation?: {
    min?: number;
    max?: number;
    pattern?: string;
    required?: boolean;
  };
  updatedAt: number;
  createdAt: number;
}

// 默认配置
export const DEFAULT_CONFIG: Record<ConfigKey, ConfigValue> = {
  // 界面相关
  theme: 'dark',
  language: 'auto',
  interfaceScale: 100,
  uiAnimationEnabled: true,
  startupScreen: 'home',
  homeLayout: 'default',
  
  // 视频播放相关
  videoQuality: 'high',
  playbackSpeed: 1.0,
  autoPlay: true,
  autoNextEpisode: true,
  backgroundPlayEnabled: false,
  videoPlayerSettings: {},
  
  // 字幕相关
  subtitleEnabled: true,
  subtitleSize: 16,
  subtitleColor: '#FFFFFF',
  subtitleDelay: 0,
  
  // 缓存相关
  cacheEnabled: true,
  cacheLimit: 5000, // MB
  
  // 网络相关
  networkTimeout: 30, // 秒
  proxyEnabled: false,
  proxyConfig: null,
  dataSaverEnabled: false,
  customHeaders: {},
  customCookies: {},
  
  // 通知相关
  notificationEnabled: true,
  
  // 更新相关
  updateCheckEnabled: true,
  
  // 数据收集相关
  crashReportingEnabled: false,
  analyticsEnabled: false,
  
  // 排序相关
  favoriteSort: 'addedAt_desc',
  historySort: 'timestamp_desc',
  searchSort: 'relevance_desc',
  
  // 下载相关
  maxConcurrentDownloads: 3,
  downloadNetworkType: 'all', // all, wifi, cellular
  
  // 家长控制
  parentalControlEnabled: false,
  parentalControlPin: null,
  showAdultContent: false,
  
  // 其他
  recentlyWatchedLimit: 20,
  streamingEnabled: true,
  localPlaybackEnabled: true,
  defaultCategory: 'all',
  preferredServer: 'auto'
};

// 配置分类
export const CONFIG_CATEGORIES = {
  UI: '界面设置',
  VIDEO: '视频播放',
  SUBTITLE: '字幕设置',
  CACHE: '缓存设置',
  NETWORK: '网络设置',
  NOTIFICATION: '通知设置',
  PRIVACY: '隐私设置',
  SORTING: '排序设置',
  DOWNLOAD: '下载设置',
  PARENTAL: '家长控制',
  OTHER: '其他设置'
};

/**
   * 配置服务类
   * 负责管理应用的各种配置设置
   */
export default class ConfigService {
  private static instance: ConfigService;
  private databaseRepo: DatabaseRepository;
  private configCache: Map<ConfigKey, ConfigItem> = new Map();
  private configParser: ConfigParser;

  /**
   * 构造函数（私有，防止外部实例化）
   */
  private constructor() {
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
    this.configParser = new ConfigParser();
    this.initializeConfig();
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
   * 初始化配置
   */
  private async initializeConfig(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing configuration...');
      
      // 加载配置到缓存
      const allConfig = await this.databaseRepo.getAllConfig();
      
      // 合并默认配置和数据库配置
      for (const [key, defaultValue] of Object.entries(DEFAULT_CONFIG)) {
        const configKey = key as ConfigKey;
        const dbConfig = allConfig.find(c => c.key === configKey);
        
        if (dbConfig) {
          this.configCache.set(configKey, dbConfig);
        } else {
          // 创建默认配置项
          const defaultItem: ConfigItem = {
            key: configKey,
            value: defaultValue,
            type: this.getValueType(defaultValue),
            defaultValue,
            category: this.getConfigCategory(configKey),
            updatedAt: Date.now(),
            createdAt: Date.now()
          };
          
          this.configCache.set(configKey, defaultItem);
          // 保存到数据库
          await this.databaseRepo.saveConfig(defaultItem);
        }
      }
      
      Logger.info(TAG, 'Configuration initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize configuration', error);
    }
  }

  /**
   * 获取配置值
   */
  public async getConfig(key: ConfigKey): Promise<ApiResponse<ConfigValue>> {
    try {
      Logger.debug(TAG, `Getting config for key: ${key}`);
      
      // 检查缓存
      if (this.configCache.has(key)) {
        const config = this.configCache.get(key)!;
        return ApiResponse.success(config.value, `获取配置[${key}]成功`);
      }
      
      // 从数据库获取
      const config = await this.databaseRepo.getConfig(key);
      
      if (config) {
        this.configCache.set(key, config);
        return ApiResponse.success(config.value, `获取配置[${key}]成功`);
      }
      
      // 返回默认值
      const defaultValue = DEFAULT_CONFIG[key];
      return ApiResponse.success(defaultValue, `配置[${key}]不存在，返回默认值`);
    } catch (error) {
      Logger.error(TAG, `Failed to get config for key: ${key}`, error);
      // 发生错误时返回默认值
      const defaultValue = DEFAULT_CONFIG[key];
      return ApiResponse.success(defaultValue, `获取配置失败，返回默认值`);
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
      
      // 从数据库获取
      const config = await this.databaseRepo.getConfig(key);
      
      if (config) {
        this.configCache.set(key, config);
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
      Logger.error(TAG, `Failed to get config item for key: ${key}`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `获取配置项失败`);
    }
  }

  /**
   * 设置配置值
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
        configItem = { ...this.configCache.get(key)! };
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
      
      // 保存到数据库
      await this.databaseRepo.saveConfig(configItem);
      
      // 更新缓存
      this.configCache.set(key, configItem);
      
      // 触发配置更改事件
      this.notifyConfigChanged(key, value);
      
      Logger.info(TAG, `Config updated successfully: ${key}`);
      return ApiResponse.success(configItem, `设置配置[${key}]成功`);
    } catch (error) {
      Logger.error(TAG, `Failed to set config: ${key}`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `设置配置失败`);
    }
  }

  /**
   * 批量设置配置
   */
  public async setMultipleConfig(configs: Array<{ key: ConfigKey; value: ConfigValue }>): Promise<ApiResponse<{ updated: number; failed: number }>> {
    try {
      Logger.info(TAG, `Setting multiple configs: ${configs.length} items`);
      
      let updated = 0;
      let failed = 0;
      
      for (const { key, value } of configs) {
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
          Logger.warn(TAG, `Failed to update config ${key}`, error);
          failed++;
        }
      }
      
      Logger.info(TAG, `Multiple configs updated: ${updated} success, ${failed} failed`);
      return ApiResponse.success(
        { updated, failed },
        `批量更新配置完成，成功${updated}项，失败${failed}项`
      );
    } catch (error) {
      Logger.error(TAG, 'Failed to set multiple configs', error);
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
      
      // 保存到数据库
      await this.databaseRepo.saveConfig(configItem);
      
      // 更新缓存
      this.configCache.set(key, configItem);
      
      // 触发配置更改事件
      this.notifyConfigChanged(key, defaultValue);
      
      Logger.info(TAG, `Config reset successfully: ${key}`);
      return ApiResponse.success(configItem, `重置配置[${key}]成功`);
    } catch (error) {
      Logger.error(TAG, `Failed to reset config: ${key}`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '重置配置失败');
    }
  }

  /**
   * 重置所有配置为默认值
   */
  public async resetAllConfig(): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Resetting all config to default values');
      
      // 清空数据库中的配置
      await this.databaseRepo.clearAllConfig();
      
      // 清空缓存
      this.configCache.clear();
      
      // 重新初始化配置
      await this.initializeConfig();
      
      // 触发配置重置事件
      this.notifyConfigReset();
      
      Logger.info(TAG, 'All config reset successfully');
      return ApiResponse.success(true, '重置所有配置成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to reset all config', error);
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
      Logger.error(TAG, 'Failed to get all configs', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取配置列表失败');
    }
  }

  /**
   * 验证配置值
   */
  private validateConfigValue(key: ConfigKey, value: ConfigValue): { isValid: boolean; errorMessage?: string } {
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
    const categoryMap: Record<ConfigKey, string> = {
      // 界面相关
      theme: CONFIG_CATEGORIES.UI,
      language: CONFIG_CATEGORIES.UI,
      interfaceScale: CONFIG_CATEGORIES.UI,
      uiAnimationEnabled: CONFIG_CATEGORIES.UI,
      startupScreen: CONFIG_CATEGORIES.UI,
      homeLayout: CONFIG_CATEGORIES.UI,
      
      // 视频播放相关
      videoQuality: CONFIG_CATEGORIES.VIDEO,
      playbackSpeed: CONFIG_CATEGORIES.VIDEO,
      autoPlay: CONFIG_CATEGORIES.VIDEO,
      autoNextEpisode: CONFIG_CATEGORIES.VIDEO,
      backgroundPlayEnabled: CONFIG_CATEGORIES.VIDEO,
      videoPlayerSettings: CONFIG_CATEGORIES.VIDEO,
      
      // 字幕相关
      subtitleEnabled: CONFIG_CATEGORIES.SUBTITLE,
      subtitleSize: CONFIG_CATEGORIES.SUBTITLE,
      subtitleColor: CONFIG_CATEGORIES.SUBTITLE,
      subtitleDelay: CONFIG_CATEGORIES.SUBTITLE,
      
      // 缓存相关
      cacheEnabled: CONFIG_CATEGORIES.CACHE,
      cacheLimit: CONFIG_CATEGORIES.CACHE,
      
      // 网络相关
      networkTimeout: CONFIG_CATEGORIES.NETWORK,
      proxyEnabled: CONFIG_CATEGORIES.NETWORK,
      proxyConfig: CONFIG_CATEGORIES.NETWORK,
      dataSaverEnabled: CONFIG_CATEGORIES.NETWORK,
      customHeaders: CONFIG_CATEGORIES.NETWORK,
      customCookies: CONFIG_CATEGORIES.NETWORK,
      
      // 通知相关
      notificationEnabled: CONFIG_CATEGORIES.NOTIFICATION,
      
      // 隐私相关
      updateCheckEnabled: CONFIG_CATEGORIES.PRIVACY,
      crashReportingEnabled: CONFIG_CATEGORIES.PRIVACY,
      analyticsEnabled: CONFIG_CATEGORIES.PRIVACY,
      
      // 排序相关
      favoriteSort: CONFIG_CATEGORIES.SORTING,
      historySort: CONFIG_CATEGORIES.SORTING,
      searchSort: CONFIG_CATEGORIES.SORTING,
      
      // 下载相关
      maxConcurrentDownloads: CONFIG_CATEGORIES.DOWNLOAD,
      downloadNetworkType: CONFIG_CATEGORIES.DOWNLOAD,
      
      // 家长控制
      parentalControlEnabled: CONFIG_CATEGORIES.PARENTAL,
      parentalControlPin: CONFIG_CATEGORIES.PARENTAL,
      showAdultContent: CONFIG_CATEGORIES.PARENTAL,
      
      // 其他
      recentlyWatchedLimit: CONFIG_CATEGORIES.OTHER,
      streamingEnabled: CONFIG_CATEGORIES.OTHER,
      localPlaybackEnabled: CONFIG_CATEGORIES.OTHER,
      defaultCategory: CONFIG_CATEGORIES.OTHER,
      preferredServer: CONFIG_CATEGORIES.OTHER
    };
    
    return categoryMap[key] || CONFIG_CATEGORIES.OTHER;
  }

  // ========== 事件通知机制 ==========
  
  private configListeners: Map<ConfigKey, Array<(value: ConfigValue) => void>> = new Map();
  private globalListeners: Array<(key: ConfigKey, value: ConfigValue) => void> = [];
  private resetListeners: Array<() => void> = [];

  /**
   * 监听配置更改
   */
  public addConfigListener(key: ConfigKey, listener: (value: ConfigValue) => void): () => void {
    if (!this.configListeners.has(key)) {
      this.configListeners.set(key, []);
    }
    
    const listeners = this.configListeners.get(key)!;
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
    if (this.configListeners.has(key)) {
      const listeners = this.configListeners.get(key)!;
      for (const listener of listeners) {
        try {
          listener(value);
        } catch (error) {
          Logger.error(TAG, `Error in config listener for ${key}`, error);
        }
      }
    }
    
    // 通知全局监听器
    for (const listener of this.globalListeners) {
      try {
        listener(key, value);
      } catch (error) {
        Logger.error(TAG, `Error in global config listener`, error);
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
        Logger.error(TAG, `Error in config reset listener`, error);
      }
    }
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
      
      const exportData = {
        exportDate: new Date().toISOString(),
        version: '1.0',
        configs: allConfigs.data.map(item => ({
          key: item.key,
          value: item.value,
          updatedAt: item.updatedAt
        }))
      };
      
      // 使用ConfigParser格式化导出数据
      const jsonStr = this.configParser.formatExportConfig(exportData);
      return ApiResponse.success(jsonStr, '导出配置成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to export config', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导出配置失败');
    }
  }

  /**
   * 导入配置
   */
  public async importConfig(jsonData: string, merge: boolean = true): Promise<ApiResponse<{
    imported: number;
    skipped: number;
    invalid: number;
  }>> {
    try {
      Logger.info(TAG, 'Importing configuration...', { merge });
      
      // 使用ConfigParser解析配置数据
      const importData = this.configParser.parseImportConfig(jsonData);
      const configs = importData.configs || [];
      
      let imported = 0;
      let skipped = 0;
      let invalid = 0;
      
      for (const configData of configs) {
        const { key, value } = configData;
        
        // 验证配置键
        if (!key || !DEFAULT_CONFIG.hasOwnProperty(key)) {
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
        
        // 如果不合并且配置已存在，跳过
        if (!merge && this.configCache.has(configKey)) {
          skipped++;
          continue;
        }
        
        // 导入配置
        await this.setConfig(configKey, value);
        imported++;
      }
      
      Logger.info(TAG, 'Configuration import completed', { imported, skipped, invalid });
      return ApiResponse.success(
        { imported, skipped, invalid },
        `导入配置完成，成功${imported}项，跳过${skipped}项，无效${invalid}项`
      );
    } catch (error) {
      Logger.error(TAG, 'Failed to import config', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导入配置失败，请检查数据格式');
    }
  }
}