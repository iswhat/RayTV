// ConfigRepository - 配置仓库类
// 负责管理应用程序的所有配置数据，提供统一的配置读写接口

import { Logger } from '../../utils/Logger';
import { StorageUtil } from '../../utils/StorageUtil';
import { EventBusUtil } from '../../utils/EventBusUtil';
import { FileUtil } from '../../utils/FileUtil';
import { ConfigType, ConfigItem, ConfigGroup } from '../model/ConfigModel';
import { LocalStorageType } from '../model/LocalModel';

/**
 * 配置变更事件类型
 */
export const ConfigEventType = {
  CONFIG_CHANGED: 'config:changed',
  CONFIG_RESET: 'config:reset',
  CONFIG_SAVED: 'config:saved',
  CONFIG_LOADED: 'config:loaded',
  CONFIG_ERROR: 'config:error'
} as const;

/**
 * 配置变更事件数据
 */
export interface ConfigChangeEvent<T = any> {
  key: string;          // 配置键
  oldValue?: T;         // 旧值
  newValue?: T;         // 新值
  type?: ConfigType;    // 配置类型
  group?: string;       // 配置组
}

/**
 * 配置仓库类
 */
export class ConfigRepository {
  private static instance: ConfigRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private fileUtil = FileUtil.getInstance();
  
  // 内存中的配置缓存
  private configCache: Map<string, any> = new Map();
  
  // 配置版本号
  private configVersion: string = '1.0.0';
  
  // 配置文件路径（用于持久化存储）
  private configFilePath: string | null = null;
  
  // 默认配置
  private defaultConfigs: Map<string, any> = new Map();
  
  // 配置项定义
  private configDefinitions: Map<string, ConfigItem<any>> = new Map();
  
  // 是否已初始化
  private initialized: boolean = false;
  
  // 批量更新模式（避免频繁触发事件）
  private batchUpdateMode: boolean = false;
  private pendingChanges: ConfigChangeEvent[] = [];

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('ConfigRepository initialized');
    this.initializeDefaultConfigs();
    this.setupEventListeners();
  }

  /**
   * 获取ConfigRepository单例实例
   */
  public static getInstance(): ConfigRepository {
    if (!ConfigRepository.instance) {
      ConfigRepository.instance = new ConfigRepository();
    }
    return ConfigRepository.instance;
  }

  /**
   * 初始化配置仓库
   * @param configPath 可选的配置文件路径
   */
  public async initialize(configPath?: string): Promise<void> {
    try {
      if (this.initialized) {
        this.logger.warn('ConfigRepository already initialized');
        return;
      }
      
      // 设置配置文件路径
      if (configPath) {
        this.configFilePath = configPath;
      }
      
      // 加载持久化配置
      await this.loadConfigs();
      
      // 注册默认配置
      await this.registerDefaultConfigs();
      
      this.initialized = true;
      this.logger.info('ConfigRepository initialized successfully');
      
      // 发布配置加载完成事件
      this.eventBus.emit(ConfigEventType.CONFIG_LOADED);
    } catch (error) {
      this.logger.error('Failed to initialize ConfigRepository', error as Error);
      
      // 发布配置错误事件
      this.eventBus.emit(ConfigEventType.CONFIG_ERROR, { error });
      
      // 使用默认配置作为后备
      await this.resetToDefaults();
    }
  }

  /**
   * 初始化默认配置定义
   */
  private initializeDefaultConfigs(): void {
    // 应用全局配置
    this.defineConfig('app_language', {
      type: ConfigType.STRING,
      defaultValue: 'zh-CN',
      description: '应用语言',
      group: 'app',
      validation: (value: string) => ['zh-CN', 'en-US', 'ja-JP', 'ko-KR'].includes(value)
    });
    
    this.defineConfig('app_theme', {
      type: ConfigType.ENUM,
      defaultValue: 'system',
      description: '应用主题',
      group: 'app',
      options: ['light', 'dark', 'system']
    });
    
    this.defineConfig('app_auto_start', {
      type: ConfigType.BOOLEAN,
      defaultValue: false,
      description: '开机自启动',
      group: 'app'
    });
    
    // 播放器配置
    this.defineConfig('player_default_quality', {
      type: ConfigType.STRING,
      defaultValue: 'auto',
      description: '默认播放质量',
      group: 'player',
      options: ['low', 'medium', 'high', 'ultra', 'auto']
    });
    
    this.defineConfig('player_auto_play', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '自动播放',
      group: 'player'
    });
    
    this.defineConfig('player_remember_position', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '记住播放位置',
      group: 'player'
    });
    
    this.defineConfig('player_volume', {
      type: ConfigType.NUMBER,
      defaultValue: 80,
      description: '默认音量',
      group: 'player',
      min: 0,
      max: 100
    });
    
    this.defineConfig('player_muted', {
      type: ConfigType.BOOLEAN,
      defaultValue: false,
      description: '是否静音',
      group: 'player'
    });
    
    this.defineConfig('player_hardware_acceleration', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '硬件加速',
      group: 'player'
    });
    
    // 网络配置
    this.defineConfig('network_timeout', {
      type: ConfigType.NUMBER,
      defaultValue: 30000,
      description: '网络超时时间（毫秒）',
      group: 'network',
      min: 5000,
      max: 60000
    });
    
    this.defineConfig('network_retry_count', {
      type: ConfigType.NUMBER,
      defaultValue: 3,
      description: '网络请求重试次数',
      group: 'network',
      min: 0,
      max: 10
    });
    
    this.defineConfig('network_auto_playback', {
      type: ConfigType.BOOLEAN,
      defaultValue: false,
      description: '移动网络自动播放',
      group: 'network'
    });
    
    // 下载配置
    this.defineConfig('download_max_concurrent', {
      type: ConfigType.NUMBER,
      defaultValue: 3,
      description: '最大并发下载数',
      group: 'download',
      min: 1,
      max: 10
    });
    
    this.defineConfig('download_dir', {
      type: ConfigType.STRING,
      defaultValue: '',
      description: '下载目录',
      group: 'download'
    });
    
    this.defineConfig('download_resume_support', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '支持断点续传',
      group: 'download'
    });
    
    // 字幕配置
    this.defineConfig('subtitle_auto_load', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '自动加载字幕',
      group: 'subtitle'
    });
    
    this.defineConfig('subtitle_font_size', {
      type: ConfigType.NUMBER,
      defaultValue: 16,
      description: '字幕字体大小',
      group: 'subtitle',
      min: 12,
      max: 36
    });
    
    this.defineConfig('subtitle_font_color', {
      type: ConfigType.STRING,
      defaultValue: '#FFFFFF',
      description: '字幕字体颜色',
      group: 'subtitle',
      validation: (value: string) => /^#[0-9A-Fa-f]{6}$/.test(value)
    });
    
    this.defineConfig('subtitle_background_color', {
      type: ConfigType.STRING,
      defaultValue: 'rgba(0, 0, 0, 0.5)',
      description: '字幕背景颜色',
      group: 'subtitle'
    });
    
    // 缓存配置
    this.defineConfig('cache_max_size', {
      type: ConfigType.NUMBER,
      defaultValue: 512, // 512MB
      description: '缓存最大大小（MB）',
      group: 'cache',
      min: 64,
      max: 4096
    });
    
    this.defineConfig('cache_expire_time', {
      type: ConfigType.NUMBER,
      defaultValue: 7, // 7天
      description: '缓存过期时间（天）',
      group: 'cache',
      min: 1,
      max: 30
    });
    
    // 通知配置
    this.defineConfig('notification_enable', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '启用通知',
      group: 'notification'
    });
    
    this.defineConfig('notification_live_reminder', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '直播提醒',
      group: 'notification'
    });
    
    this.defineConfig('notification_update_reminder', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '更新提醒',
      group: 'notification'
    });
    
    // 用户界面配置
    this.defineConfig('ui_show_guide', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '显示使用引导',
      group: 'ui'
    });
    
    this.defineConfig('ui_font_scale', {
      type: ConfigType.NUMBER,
      defaultValue: 1.0,
      description: '字体缩放比例',
      group: 'ui',
      min: 0.8,
      max: 1.5
    });
    
    this.defineConfig('ui_animation_enable', {
      type: ConfigType.BOOLEAN,
      defaultValue: true,
      description: '启用动画效果',
      group: 'ui'
    });
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用退出事件，保存配置
    this.eventBus.on('app:exit', async () => {
      await this.saveConfigs();
    });
  }

  /**
   * 定义配置项
   * @param key 配置键
   * @param config 配置项定义
   */
  public defineConfig<T>(key: string, config: ConfigItem<T>): void {
    this.configDefinitions.set(key, config as ConfigItem<any>);
    this.defaultConfigs.set(key, config.defaultValue);
    
    // 如果配置项已存在于缓存中，验证其值
    if (this.configCache.has(key)) {
      const currentValue = this.configCache.get(key);
      if (!this.validateConfigValue(key, currentValue)) {
        this.logger.warn(`Invalid value for config ${key}, using default: ${config.defaultValue}`);
        this.configCache.set(key, config.defaultValue);
      }
    }
    
    this.logger.debug(`Config defined: ${key} (${config.type})`);
  }

  /**
   * 获取配置值
   * @param key 配置键
   * @param defaultValue 默认值（如果配置不存在）
   */
  public getConfig<T>(key: string, defaultValue?: T): T {
    // 检查是否初始化
    if (!this.initialized) {
      this.logger.warn('ConfigRepository not initialized, returning default value');
      return defaultValue as T;
    }
    
    // 优先从缓存获取
    if (this.configCache.has(key)) {
      return this.configCache.get(key) as T;
    }
    
    // 尝试从默认配置获取
    if (this.defaultConfigs.has(key)) {
      return this.defaultConfigs.get(key) as T;
    }
    
    // 返回提供的默认值
    return defaultValue as T;
  }

  /**
   * 设置配置值
   * @param key 配置键
   * @param value 配置值
   */
  public async setConfig<T>(key: string, value: T): Promise<void> {
    // 检查是否初始化
    if (!this.initialized) {
      throw new Error('ConfigRepository not initialized');
    }
    
    // 验证配置值
    if (!this.validateConfigValue(key, value)) {
      const configDef = this.configDefinitions.get(key);
      throw new Error(`Invalid value for config ${key}, ${this.getValidationErrorMessage(key, value, configDef)}`);
    }
    
    // 获取旧值
    const oldValue = this.configCache.get(key);
    
    // 如果值未变化，不做处理
    if (oldValue === value) {
      return;
    }
    
    // 更新缓存
    this.configCache.set(key, value);
    
    // 构建变更事件
    const configDef = this.configDefinitions.get(key);
    const changeEvent: ConfigChangeEvent<T> = {
      key,
      oldValue,
      newValue: value,
      type: configDef?.type,
      group: configDef?.group
    };
    
    // 处理变更事件
    if (this.batchUpdateMode) {
      this.pendingChanges.push(changeEvent);
    } else {
      this.handleConfigChange(changeEvent);
      
      // 保存配置
      await this.saveConfig(key);
    }
  }

  /**
   * 批量设置配置
   * @param configs 配置键值对
   */
  public async batchSetConfigs(configs: Record<string, any>): Promise<void> {
    // 检查是否初始化
    if (!this.initialized) {
      throw new Error('ConfigRepository not initialized');
    }
    
    try {
      // 启用批量更新模式
      this.batchUpdateMode = true;
      
      // 验证并设置所有配置
      for (const [key, value] of Object.entries(configs)) {
        if (!this.validateConfigValue(key, value)) {
          const configDef = this.configDefinitions.get(key);
          throw new Error(`Invalid value for config ${key}, ${this.getValidationErrorMessage(key, value, configDef)}`);
        }
        
        const oldValue = this.configCache.get(key);
        if (oldValue !== value) {
          this.configCache.set(key, value);
          
          const configDef = this.configDefinitions.get(key);
          this.pendingChanges.push({
            key,
            oldValue,
            newValue: value,
            type: configDef?.type,
            group: configDef?.group
          });
        }
      }
      
      // 处理所有待处理的变更
      for (const changeEvent of this.pendingChanges) {
        this.handleConfigChange(changeEvent);
      }
      
      // 保存所有配置
      await this.saveConfigs();
    } finally {
      // 重置批量更新状态
      this.batchUpdateMode = false;
      this.pendingChanges = [];
    }
  }

  /**
   * 删除配置项
   * @param key 配置键
   */
  public async removeConfig(key: string): Promise<void> {
    // 检查是否初始化
    if (!this.initialized) {
      throw new Error('ConfigRepository not initialized');
    }
    
    if (this.configCache.has(key)) {
      const oldValue = this.configCache.get(key);
      this.configCache.delete(key);
      
      // 发布配置变更事件
      this.eventBus.emit(ConfigEventType.CONFIG_CHANGED, {
        key,
        oldValue,
        newValue: undefined
      });
      
      // 保存配置
      await this.saveConfigs();
    }
  }

  /**
   * 检查配置项是否存在
   * @param key 配置键
   */
  public hasConfig(key: string): boolean {
    return this.configCache.has(key) || this.defaultConfigs.has(key);
  }

  /**
   * 获取所有配置
   */
  public getAllConfigs(): Record<string, any> {
    const allConfigs: Record<string, any> = {};
    
    // 合并默认配置和当前配置
    this.defaultConfigs.forEach((value, key) => {
      allConfigs[key] = this.configCache.get(key) ?? value;
    });
    
    // 添加未在默认配置中的当前配置
    this.configCache.forEach((value, key) => {
      if (!this.defaultConfigs.has(key)) {
        allConfigs[key] = value;
      }
    });
    
    return allConfigs;
  }

  /**
   * 获取指定组的配置
   * @param group 配置组名
   */
  public getConfigsByGroup(group: string): Record<string, any> {
    const groupConfigs: Record<string, any> = {};
    
    this.configDefinitions.forEach((configDef, key) => {
      if (configDef.group === group) {
        groupConfigs[key] = this.getConfig(key, configDef.defaultValue);
      }
    });
    
    return groupConfigs;
  }

  /**
   * 重置单个配置项为默认值
   * @param key 配置键
   */
  public async resetConfig(key: string): Promise<void> {
    if (this.defaultConfigs.has(key)) {
      const defaultValue = this.defaultConfigs.get(key);
      await this.setConfig(key, defaultValue);
      
      this.logger.debug(`Config reset to default: ${key} = ${defaultValue}`);
    }
  }

  /**
   * 重置所有配置为默认值
   */
  public async resetToDefaults(): Promise<void> {
    try {
      // 清空缓存
      this.configCache.clear();
      
      // 发布配置重置事件
      this.eventBus.emit(ConfigEventType.CONFIG_RESET);
      
      // 保存配置
      await this.saveConfigs();
      
      this.logger.info('All configs reset to default values');
    } catch (error) {
      this.logger.error('Failed to reset configs to defaults', error as Error);
      throw error;
    }
  }

  /**
   * 加载配置
   */
  private async loadConfigs(): Promise<void> {
    try {
      // 从不同存储加载配置
      const storageConfig = await this.loadConfigsFromStorage();
      const fileConfig = this.configFilePath ? await this.loadConfigsFromFile() : {};
      
      // 合并配置（文件配置优先级高于存储配置）
      const mergedConfig = { ...storageConfig, ...fileConfig };
      
      // 更新配置缓存
      for (const [key, value] of Object.entries(mergedConfig)) {
        if (this.validateConfigValue(key, value)) {
          this.configCache.set(key, value);
        } else {
          this.logger.warn(`Invalid config value from storage: ${key} = ${value}, using default`);
        }
      }
      
      this.logger.info(`Loaded ${this.configCache.size} configs`);
    } catch (error) {
      this.logger.error('Failed to load configs', error as Error);
      // 加载失败时使用默认配置
      this.configCache.clear();
    }
  }

  /**
   * 从存储加载配置
   */
  private async loadConfigsFromStorage(): Promise<Record<string, any>> {
    try {
      const configs = await this.storageUtil.get<Record<string, any>>('app_configs', LocalStorageType.PERSISTENT);
      return configs || {};
    } catch (error) {
      this.logger.error('Failed to load configs from storage', error as Error);
      return {};
    }
  }

  /**
   * 从文件加载配置
   */
  private async loadConfigsFromFile(): Promise<Record<string, any>> {
    try {
      if (!this.configFilePath || !await this.fileUtil.exists(this.configFilePath)) {
        return {};
      }
      
      const content = await this.fileUtil.readTextFile(this.configFilePath);
      return JSON.parse(content) || {};
    } catch (error) {
      this.logger.error('Failed to load configs from file', error as Error);
      return {};
    }
  }

  /**
   * 保存所有配置
   */
  private async saveConfigs(): Promise<void> {
    try {
      const allConfigs = this.getAllConfigs();
      
      // 保存到存储
      await this.storageUtil.set('app_configs', allConfigs, LocalStorageType.PERSISTENT);
      
      // 保存到文件（如果指定了路径）
      if (this.configFilePath) {
        await this.fileUtil.writeTextFile(this.configFilePath, JSON.stringify(allConfigs, null, 2));
      }
      
      // 发布配置保存事件
      this.eventBus.emit(ConfigEventType.CONFIG_SAVED, allConfigs);
      
      this.logger.debug(`Saved ${Object.keys(allConfigs).length} configs`);
    } catch (error) {
      this.logger.error('Failed to save configs', error as Error);
      
      // 发布配置错误事件
      this.eventBus.emit(ConfigEventType.CONFIG_ERROR, { error });
      
      throw error;
    }
  }

  /**
   * 保存单个配置
   * @param key 配置键
   */
  private async saveConfig(key: string): Promise<void> {
    try {
      const value = this.configCache.get(key);
      const currentConfigs = await this.storageUtil.get<Record<string, any>>('app_configs', LocalStorageType.PERSISTENT) || {};
      
      currentConfigs[key] = value;
      
      // 保存到存储
      await this.storageUtil.set('app_configs', currentConfigs, LocalStorageType.PERSISTENT);
      
      // 如果指定了文件路径，也更新文件
      if (this.configFilePath) {
        try {
          const fileContent = await this.fileUtil.readTextFile(this.configFilePath);
          const fileConfigs = JSON.parse(fileContent) || {};
          fileConfigs[key] = value;
          await this.fileUtil.writeTextFile(this.configFilePath, JSON.stringify(fileConfigs, null, 2));
        } catch (fileError) {
          // 文件保存失败不影响主要功能
          this.logger.warn('Failed to update config file', fileError as Error);
        }
      }
    } catch (error) {
      this.logger.error(`Failed to save config: ${key}`, error as Error);
    }
  }

  /**
   * 注册默认配置
   */
  private async registerDefaultConfigs(): Promise<void> {
    // 确保所有默认配置都在缓存中
    this.defaultConfigs.forEach((value, key) => {
      if (!this.configCache.has(key)) {
        this.configCache.set(key, value);
      }
    });
  }

  /**
   * 验证配置值
   * @param key 配置键
   * @param value 配置值
   */
  private validateConfigValue(key: string, value: any): boolean {
    const configDef = this.configDefinitions.get(key);
    
    // 如果没有配置定义，允许任何值
    if (!configDef) {
      return true;
    }
    
    // 验证类型
    if (value !== null && value !== undefined) {
      const expectedType = configDef.type;
      const actualType = typeof value;
      
      switch (expectedType) {
        case ConfigType.STRING:
          if (actualType !== 'string') return false;
          break;
        case ConfigType.NUMBER:
          if (actualType !== 'number' || isNaN(value)) return false;
          // 验证范围
          if (configDef.min !== undefined && value < configDef.min) return false;
          if (configDef.max !== undefined && value > configDef.max) return false;
          break;
        case ConfigType.BOOLEAN:
          if (actualType !== 'boolean') return false;
          break;
        case ConfigType.OBJECT:
          if (actualType !== 'object' || Array.isArray(value)) return false;
          break;
        case ConfigType.ARRAY:
          if (!Array.isArray(value)) return false;
          break;
        case ConfigType.ENUM:
          if (!configDef.options?.includes(value)) return false;
          break;
      }
    }
    
    // 自定义验证函数
    if (configDef.validation && typeof configDef.validation === 'function') {
      try {
        return configDef.validation(value);
      } catch (error) {
        this.logger.warn(`Custom validation failed for config ${key}:`, error as Error);
        return false;
      }
    }
    
    return true;
  }

  /**
   * 获取验证错误消息
   * @param key 配置键
   * @param value 配置值
   * @param configDef 配置定义
   */
  private getValidationErrorMessage(key: string, value: any, configDef?: ConfigItem<any>): string {
    if (!configDef) {
      return 'Unknown validation error';
    }
    
    // 类型错误
    const expectedType = this.getConfigTypeName(configDef.type);
    const actualType = typeof value;
    if (value !== null && value !== undefined && actualType !== expectedType) {
      return `Expected type ${expectedType}, got ${actualType}`;
    }
    
    // 范围错误
    if (configDef.type === ConfigType.NUMBER) {
      if (configDef.min !== undefined && value < configDef.min) {
        return `Value must be greater than or equal to ${configDef.min}`;
      }
      if (configDef.max !== undefined && value > configDef.max) {
        return `Value must be less than or equal to ${configDef.max}`;
      }
    }
    
    // 枚举错误
    if (configDef.type === ConfigType.ENUM && configDef.options) {
      return `Value must be one of: ${configDef.options.join(', ')}`;
    }
    
    return 'Invalid value';
  }

  /**
   * 获取配置类型的字符串表示
   * @param type 配置类型
   */
  private getConfigTypeName(type: ConfigType): string {
    switch (type) {
      case ConfigType.STRING:
        return 'string';
      case ConfigType.NUMBER:
        return 'number';
      case ConfigType.BOOLEAN:
        return 'boolean';
      case ConfigType.OBJECT:
        return 'object';
      case ConfigType.ARRAY:
        return 'array';
      case ConfigType.ENUM:
        return 'string'; // ENUM也是字符串类型
      default:
        return 'any';
    }
  }

  /**
   * 处理配置变更
   * @param changeEvent 变更事件
   */
  private handleConfigChange(changeEvent: ConfigChangeEvent): void {
    // 发布配置变更事件
    this.eventBus.emit(ConfigEventType.CONFIG_CHANGED, changeEvent);
    
    this.logger.debug(`Config changed: ${changeEvent.key}`, {
      oldValue: changeEvent.oldValue,
      newValue: changeEvent.newValue
    });
  }

  /**
   * 获取配置项定义
   * @param key 配置键
   */
  public getConfigDefinition<T>(key: string): ConfigItem<T> | undefined {
    return this.configDefinitions.get(key) as ConfigItem<T>;
  }

  /**
   * 获取所有配置项定义
   */
  public getAllConfigDefinitions(): Record<string, ConfigItem<any>> {
    const definitions: Record<string, ConfigItem<any>> = {};
    this.configDefinitions.forEach((def, key) => {
      definitions[key] = def;
    });
    return definitions;
  }

  /**
   * 导出配置
   */
  public async exportConfigs(): Promise<string> {
    try {
      const allConfigs = this.getAllConfigs();
      return JSON.stringify({
        version: this.configVersion,
        exportTime: new Date().toISOString(),
        configs: allConfigs
      }, null, 2);
    } catch (error) {
      this.logger.error('Failed to export configs', error as Error);
      throw error;
    }
  }

  /**
   * 导入配置
   * @param configData 配置数据字符串
   */
  public async importConfigs(configData: string): Promise<void> {
    try {
      const importData = JSON.parse(configData);
      
      if (!importData.configs) {
        throw new Error('Invalid config import data format');
      }
      
      // 验证并应用导入的配置
      const validConfigs: Record<string, any> = {};
      
      for (const [key, value] of Object.entries(importData.configs)) {
        if (this.validateConfigValue(key, value)) {
          validConfigs[key] = value;
        } else {
          this.logger.warn(`Skipping invalid config during import: ${key}`);
        }
      }
      
      // 批量应用配置
      await this.batchSetConfigs(validConfigs);
      
      this.logger.info(`Successfully imported ${Object.keys(validConfigs).length} configs`);
    } catch (error) {
      this.logger.error('Failed to import configs', error as Error);
      
      // 发布配置错误事件
      this.eventBus.emit(ConfigEventType.CONFIG_ERROR, { error });
      
      throw error;
    }
  }

  /**
   * 获取配置版本
   */
  public getConfigVersion(): string {
    return this.configVersion;
  }

  /**
   * 更新配置版本
   * @param version 新版本号
   */
  public updateConfigVersion(version: string): void {
    this.configVersion = version;
    this.logger.info(`Config version updated to: ${version}`);
  }

  /**
   * 清理过期配置
   * 移除不再使用的配置项
   */
  public async cleanupObsoleteConfigs(): Promise<void> {
    const obsoleteKeys: string[] = [];
    
    // 找出不在定义中的配置项
    this.configCache.forEach((_, key) => {
      if (!this.configDefinitions.has(key) && !this.defaultConfigs.has(key)) {
        obsoleteKeys.push(key);
      }
    });
    
    if (obsoleteKeys.length > 0) {
      this.logger.info(`Cleaning up ${obsoleteKeys.length} obsolete configs: ${obsoleteKeys.join(', ')}`);
      
      // 移除过期配置
      for (const key of obsoleteKeys) {
        this.configCache.delete(key);
      }
      
      // 保存配置
      await this.saveConfigs();
    }
  }
}

// 导出默认实例
export default ConfigRepository.getInstance();