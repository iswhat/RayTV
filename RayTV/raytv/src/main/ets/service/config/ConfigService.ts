import Logger from '../../common/util/Logger';
import { Preferences } from '@ohos.data.preferences';
import fileio from '@ohos.fileio';
import featureAbility from '@ohos.ability.featureAbility';
import { Context } from '@ohos.ability.baseContext';

/**
 * 配置类型枚举
 */
export enum ConfigType {
  STRING = 'string',
  NUMBER = 'number',
  BOOLEAN = 'boolean',
  OBJECT = 'object',
  ARRAY = 'array'
}

/**
 * 配置项接口
 */
export interface ConfigItem {
  key: string;
  defaultValue: any;
  type: ConfigType;
  description?: string;
  isPrivate?: boolean; // 是否为私有配置
}

/**
 * 主题模式枚举
 */
export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  AUTO = 'auto'
}

/**
 * 缓存策略枚举
 */
export enum CacheStrategy {
  OFF = 0,           // 不使用缓存
  MINIMAL = 1,       // 最小缓存（基本信息）
  NORMAL = 2,        // 正常缓存
  AGGRESSIVE = 3     // 激进缓存（所有内容）
}

/**
 * 配置服务
 * 管理应用的各种配置选项
 */
export class ConfigService {
  private readonly TAG: string = 'ConfigService';
  private static instance: ConfigService | null = null;
  private preferences: Preferences | null = null;
  private preferencesKey: string = 'RayTV_Config';
  private configItems: Map<string, ConfigItem> = new Map();
  private isInitialized: boolean = false;
  private context: Context | null = null;
  private configChangeListeners: Map<string, ((value: any) => void)[]> = new Map();

  /**
   * 默认配置项
   */
  private readonly DEFAULT_CONFIG_ITEMS: ConfigItem[] = [
    {
      key: 'themeMode',
      defaultValue: ThemeMode.AUTO,
      type: ConfigType.STRING,
      description: '应用主题模式'
    },
    {
      key: 'language',
      defaultValue: 'auto',
      type: ConfigType.STRING,
      description: '应用语言'
    },
    {
      key: 'homePageLayout',
      defaultValue: 'grid',
      type: ConfigType.STRING,
      description: '首页布局模式'
    },
    {
      key: 'pageSize',
      defaultValue: 20,
      type: ConfigType.NUMBER,
      description: '分页大小'
    },
    {
      key: 'enableAutoPlay',
      defaultValue: true,
      type: ConfigType.BOOLEAN,
      description: '是否启用自动播放'
    },
    {
      key: 'enableBackgroundPlay',
      defaultValue: false,
      type: ConfigType.BOOLEAN,
      description: '是否启用后台播放'
    },
    {
      key: 'cacheStrategy',
      defaultValue: CacheStrategy.NORMAL,
      type: ConfigType.NUMBER,
      description: '缓存策略'
    },
    {
      key: 'maxCacheSize',
      defaultValue: 512, // 512MB
      type: ConfigType.NUMBER,
      description: '最大缓存大小（MB）'
    },
    {
      key: 'cacheExpiryTime',
      defaultValue: 7, // 7天
      type: ConfigType.NUMBER,
      description: '缓存过期时间（天）'
    },
    {
      key: 'networkTimeout',
      defaultValue: 30,
      type: ConfigType.NUMBER,
      description: '网络请求超时时间（秒）'
    },
    {
      key: 'userAgent',
      defaultValue: 'Mozilla/5.0 RayTV-HarmonyOS',
      type: ConfigType.STRING,
      description: '自定义User-Agent',
      isPrivate: true
    },
    {
      key: 'customHeaders',
      defaultValue: {},
      type: ConfigType.OBJECT,
      description: '自定义请求头',
      isPrivate: true
    },
    {
      key: 'recentlyUsedSites',
      defaultValue: [],
      type: ConfigType.ARRAY,
      description: '最近使用的站点'
    },
    {
      key: 'disabledSites',
      defaultValue: [],
      type: ConfigType.ARRAY,
      description: '禁用的站点'
    },
    {
      key: 'playerVolume',
      defaultValue: 1.0,
      type: ConfigType.NUMBER,
      description: '播放器默认音量'
    },
    {
      key: 'playbackSpeed',
      defaultValue: 1.0,
      type: ConfigType.NUMBER,
      description: '默认播放速度'
    },
    {
      key: 'subtitleEnabled',
      defaultValue: true,
      type: ConfigType.BOOLEAN,
      description: '是否启用字幕'
    },
    {
      key: 'subtitleSize',
      defaultValue: 16,
      type: ConfigType.NUMBER,
      description: '字幕大小'
    },
    {
      key: 'subtitleColor',
      defaultValue: '#FFFFFF',
      type: ConfigType.STRING,
      description: '字幕颜色'
    },
    {
      key: 'subtitleBackgroundColor',
      defaultValue: 'rgba(0,0,0,0.5)',
      type: ConfigType.STRING,
      description: '字幕背景色'
    },
    {
      key: 'enableHardwareAcceleration',
      defaultValue: true,
      type: ConfigType.BOOLEAN,
      description: '是否启用硬件加速'
    },
    {
      key: 'videoQuality',
      defaultValue: 'auto',
      type: ConfigType.STRING,
      description: '默认视频质量'
    },
    {
      key: 'enableAutoRotate',
      defaultValue: true,
      type: ConfigType.BOOLEAN,
      description: '是否启用自动旋转'
    },
    {
      key: 'enableGestures',
      defaultValue: true,
      type: ConfigType.BOOLEAN,
      description: '是否启用手势控制'
    },
    {
      key: 'showRecentPlays',
      defaultValue: true,
      type: ConfigType.BOOLEAN,
      description: '显示最近播放'
    },
    {
      key: 'maxRecentPlays',
      defaultValue: 50,
      type: ConfigType.NUMBER,
      description: '最大最近播放数量'
    },
    {
      key: 'enableCrashReporting',
      defaultValue: true,
      type: ConfigType.BOOLEAN,
      description: '是否启用崩溃报告'
    },
    {
      key: 'enableUsageStatistics',
      defaultValue: true,
      type: ConfigType.BOOLEAN,
      description: '是否启用使用统计'
    },
    {
      key: 'lastUpdateCheck',
      defaultValue: 0,
      type: ConfigType.NUMBER,
      description: '上次检查更新时间戳'
    },
    {
      key: 'updateCheckInterval',
      defaultValue: 24, // 24小时
      type: ConfigType.NUMBER,
      description: '更新检查间隔（小时）'
    }
  ];

  /**
   * 获取单例实例
   * @returns ConfigService
   */
  public static getInstance(): ConfigService {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
    }
    return ConfigService.instance;
  }

  /**
   * 构造函数
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    Logger.info(this.TAG, 'ConfigService initialized');
    this.registerDefaultConfigItems();
  }

  /**
   * 初始化配置服务
   * @param context 应用上下文
   * @returns Promise<boolean>
   */
  public async initialize(context?: Context): Promise<boolean> {
    try {
      if (this.isInitialized) {
        return true;
      }

      // 获取或使用传入的上下文
      this.context = context || await featureAbility.getContext();
      
      // 初始化Preferences
      this.preferences = await Preferences.getPreferences(this.context, this.preferencesKey);
      Logger.info(this.TAG, 'Preferences initialized');

      // 确保所有默认配置项都已设置
      await this.ensureDefaultValues();

      this.isInitialized = true;
      Logger.info(this.TAG, 'ConfigService initialized successfully');
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize ConfigService: ${error}`);
      return false;
    }
  }

  /**
   * 注册默认配置项
   * @private
   */
  private registerDefaultConfigItems(): void {
    this.DEFAULT_CONFIG_ITEMS.forEach(item => {
      this.registerConfigItem(item);
    });
  }

  /**
   * 注册配置项
   * @param item 配置项
   */
  public registerConfigItem(item: ConfigItem): void {
    this.configItems.set(item.key, item);
    // 初始化监听器数组
    if (!this.configChangeListeners.has(item.key)) {
      this.configChangeListeners.set(item.key, []);
    }
    Logger.debug(this.TAG, `Registered config item: ${item.key}`);
  }

  /**
   * 确保所有默认配置值都已设置
   * @private
   */
  private async ensureDefaultValues(): Promise<void> {
    for (const [key, item] of this.configItems.entries()) {
      // 检查配置是否存在，不存在则设置默认值
      const exists = await this.preferences!.has(key);
      if (!exists) {
        await this.setConfigValue(key, item.defaultValue);
      }
    }
  }

  /**
   * 获取配置值
   * @param key 配置键
   * @returns Promise<any>
   */
  public async getConfig(key: string): Promise<any> {
    try {
      if (!this.isInitialized) {
        await this.initialize();
      }

      // 检查配置项是否已注册
      const configItem = this.configItems.get(key);
      if (!configItem) {
        Logger.warn(this.TAG, `Config item not registered: ${key}`);
        return null;
      }

      // 从Preferences获取值
      const value = await this.preferences!.get(key, configItem.defaultValue);
      
      // 验证并转换类型
      return this.validateAndConvertType(value, configItem.type, configItem.defaultValue);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get config: ${key}, error: ${error}`);
      // 返回默认值
      const configItem = this.configItems.get(key);
      return configItem ? configItem.defaultValue : null;
    }
  }

  /**
   * 设置配置值
   * @param key 配置键
   * @param value 配置值
   * @returns Promise<boolean>
   */
  public async setConfig(key: string, value: any): Promise<boolean> {
    try {
      if (!this.isInitialized) {
        await this.initialize();
      }

      // 检查配置项是否已注册
      const configItem = this.configItems.get(key);
      if (!configItem) {
        Logger.warn(this.TAG, `Config item not registered: ${key}`);
        return false;
      }

      // 验证并转换类型
      const validatedValue = this.validateAndConvertType(value, configItem.type, configItem.defaultValue);
      
      // 保存到Preferences
      await this.setConfigValue(key, validatedValue);
      
      // 通知监听器
      this.notifyConfigChanged(key, validatedValue);
      
      Logger.info(this.TAG, `Config set: ${key} = ${JSON.stringify(validatedValue)}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to set config: ${key}, error: ${error}`);
      return false;
    }
  }

  /**
   * 批量设置配置
   * @param configs 配置对象
   * @returns Promise<boolean>
   */
  public async setConfigs(configs: Record<string, any>): Promise<boolean> {
    try {
      if (!this.isInitialized) {
        await this.initialize();
      }

      const changes: Record<string, any> = {};
      
      // 验证所有配置值
      for (const [key, value] of Object.entries(configs)) {
        const configItem = this.configItems.get(key);
        if (configItem) {
          changes[key] = this.validateAndConvertType(value, configItem.type, configItem.defaultValue);
        }
      }

      // 批量保存
      for (const [key, value] of Object.entries(changes)) {
        await this.setConfigValue(key, value);
      }

      // 通知所有变更
      for (const [key, value] of Object.entries(changes)) {
        this.notifyConfigChanged(key, value);
        Logger.info(this.TAG, `Batch config set: ${key} = ${JSON.stringify(value)}`);
      }

      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch set configs: ${error}`);
      return false;
    }
  }

  /**
   * 重置配置到默认值
   * @param key 配置键，不传则重置所有配置
   * @returns Promise<boolean>
   */
  public async resetConfig(key?: string): Promise<boolean> {
    try {
      if (!this.isInitialized) {
        await this.initialize();
      }

      if (key) {
        // 重置单个配置
        const configItem = this.configItems.get(key);
        if (configItem) {
          await this.setConfigValue(key, configItem.defaultValue);
          this.notifyConfigChanged(key, configItem.defaultValue);
          Logger.info(this.TAG, `Config reset to default: ${key}`);
          return true;
        }
        return false;
      } else {
        // 重置所有配置
        for (const [key, item] of this.configItems.entries()) {
          await this.setConfigValue(key, item.defaultValue);
          this.notifyConfigChanged(key, item.defaultValue);
        }
        Logger.info(this.TAG, 'All configs reset to default');
        return true;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to reset config: ${error}`);
      return false;
    }
  }

  /**
   * 获取所有配置
   * @param includePrivate 是否包含私有配置
   * @returns Promise<Record<string, any>>
   */
  public async getAllConfigs(includePrivate: boolean = false): Promise<Record<string, any>> {
    try {
      if (!this.isInitialized) {
        await this.initialize();
      }

      const configs: Record<string, any> = {};
      
      for (const [key, item] of this.configItems.entries()) {
        // 跳过私有配置（如果不包含）
        if (!includePrivate && item.isPrivate) {
          continue;
        }
        
        configs[key] = await this.getConfig(key);
      }
      
      return configs;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all configs: ${error}`);
      return {};
    }
  }

  /**
   * 添加配置变更监听器
   * @param key 配置键
   * @param listener 监听器函数
   */
  public addConfigChangeListener(key: string, listener: (value: any) => void): void {
    if (!this.configChangeListeners.has(key)) {
      this.configChangeListeners.set(key, []);
    }
    
    const listeners = this.configChangeListeners.get(key)!;
    if (!listeners.includes(listener)) {
      listeners.push(listener);
    }
  }

  /**
   * 移除配置变更监听器
   * @param key 配置键
   * @param listener 监听器函数
   */
  public removeConfigChangeListener(key: string, listener: (value: any) => void): void {
    const listeners = this.configChangeListeners.get(key);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 清除所有监听器
   * @param key 配置键，不传则清除所有配置的监听器
   */
  public clearConfigChangeListeners(key?: string): void {
    if (key) {
      this.configChangeListeners.set(key, []);
    } else {
      for (const key of this.configChangeListeners.keys()) {
        this.configChangeListeners.set(key, []);
      }
    }
  }

  /**
   * 获取配置项的描述信息
   * @param key 配置键
   * @returns string | undefined
   */
  public getConfigDescription(key: string): string | undefined {
    const configItem = this.configItems.get(key);
    return configItem?.description;
  }

  /**
   * 获取配置项的类型
   * @param key 配置键
   * @returns ConfigType | undefined
   */
  public getConfigType(key: string): ConfigType | undefined {
    const configItem = this.configItems.get(key);
    return configItem?.type;
  }

  /**
   * 设置配置值到Preferences
   * @param key 配置键
   * @param value 配置值
   * @private
   */
  private async setConfigValue(key: string, value: any): Promise<void> {
    // 根据值的类型选择合适的存储方法
    if (typeof value === 'string') {
      await this.preferences!.putString(key, value);
    } else if (typeof value === 'number') {
      await this.preferences!.putNumber(key, value);
    } else if (typeof value === 'boolean') {
      await this.preferences!.putBoolean(key, value);
    } else if (typeof value === 'object' || Array.isArray(value)) {
      // 对象和数组转换为JSON字符串存储
      await this.preferences!.putString(key, JSON.stringify(value));
    } else {
      // 其他类型也转换为字符串
      await this.preferences!.putString(key, String(value));
    }
    
    // 确保数据持久化
    await this.preferences!.flushSync();
  }

  /**
   * 验证并转换配置值类型
   * @param value 原始值
   * @param type 目标类型
   * @param defaultValue 默认值
   * @returns 转换后的值
   * @private
   */
  private validateAndConvertType(value: any, type: ConfigType, defaultValue: any): any {
    try {
      switch (type) {
        case ConfigType.STRING:
          return String(value);
        case ConfigType.NUMBER:
          const numValue = Number(value);
          return isNaN(numValue) ? defaultValue : numValue;
        case ConfigType.BOOLEAN:
          return Boolean(value);
        case ConfigType.OBJECT:
          if (typeof value === 'string') {
            try {
              return JSON.parse(value);
            } catch {
              return defaultValue;
            }
          }
          return typeof value === 'object' && !Array.isArray(value) ? value : defaultValue;
        case ConfigType.ARRAY:
          if (typeof value === 'string') {
            try {
              const parsed = JSON.parse(value);
              return Array.isArray(parsed) ? parsed : defaultValue;
            } catch {
              return defaultValue;
            }
          }
          return Array.isArray(value) ? value : defaultValue;
        default:
          return defaultValue;
      }
    } catch (error) {
      Logger.warn(this.TAG, `Failed to validate and convert type: ${error}`);
      return defaultValue;
    }
  }

  /**
   * 通知配置变更
   * @param key 配置键
   * @param value 新值
   * @private
   */
  private notifyConfigChanged(key: string, value: any): void {
    const listeners = this.configChangeListeners.get(key);
    if (listeners) {
      listeners.forEach(listener => {
        try {
          listener(value);
        } catch (error) {
          Logger.error(this.TAG, `Error in config change listener for ${key}: ${error}`);
        }
      });
    }
  }

  /**
   * 导出配置到文件
   * @param filePath 文件路径
   * @returns Promise<boolean>
   */
  public async exportConfig(filePath: string): Promise<boolean> {
    try {
      const configs = await this.getAllConfigs(true);
      const configJson = JSON.stringify(configs, null, 2);
      
      // 使用HarmonyOS的文件API写入文件
      const fd = fileio.openSync(filePath, 0o2 | 0o100, 0o666);
      try {
        fileio.writeSync(fd, configJson);
      } finally {
        fileio.closeSync(fd);
      }
      
      Logger.info(this.TAG, `Config exported to ${filePath}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to export config: ${error}`);
      return false;
    }
  }

  /**
   * 从文件导入配置
   * @param filePath 文件路径
   * @returns Promise<boolean>
   */
  public async importConfig(filePath: string): Promise<boolean> {
    try {
      // 使用HarmonyOS的文件API读取文件
      const fd = fileio.openSync(filePath, 0o00, 0o666);
      let configJson: string;
      try {
        const fileStats = fileio.statSync(filePath);
        const buffer = new ArrayBuffer(fileStats.size);
        fileio.readSync(fd, buffer);
        configJson = String.fromCharCode(...new Uint8Array(buffer));
      } finally {
        fileio.closeSync(fd);
      }
      
      // 解析配置并应用
      const configs = JSON.parse(configJson);
      await this.setConfigs(configs);
      
      Logger.info(this.TAG, `Config imported from ${filePath}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to import config: ${error}`);
      return false;
    }
  }

  /**
   * 检查配置值是否有效
   * @param key 配置键
   * @param value 值
   * @returns boolean
   */
  public isValidConfigValue(key: string, value: any): boolean {
    const configItem = this.configItems.get(key);
    if (!configItem) {
      return false;
    }

    try {
      // 尝试转换类型，如果成功则认为有效
      this.validateAndConvertType(value, configItem.type, configItem.defaultValue);
      return true;
    } catch {
      return false;
    }
  }
}

// 导出配置服务单例
export const configService = ConfigService.getInstance();