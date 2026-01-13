// ConfigRepository - 配置仓库 | Config repository
// 负责处理应用配置的存储和管理 | Responsible for handling application configuration storage and management

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import { ConfigKey, ConfigValue, ConfigCategory } from '../model/ConfigModel';
import DatabaseRepository from './DatabaseRepository';

/**
 * 配置仓库 | Config repository
 * 管理应用的所有配置项，支持多层存储策�?| Manage all application configuration items, support multi-layer storage strategy
 */
class ConfigRepository {
  private static instance: ConfigRepository;
  private databaseRepository: DatabaseRepository;
  private configCache: Map<string, ConfigValue> = new Map();
  private defaultConfigs: Map<string, ConfigValue> = new Map();
  private initialized: boolean = false;

  // 私有构造函�?| Private constructor
  private constructor() {
    this.databaseRepository = DatabaseRepository.getInstance();
    this.initializeDefaultConfigs();
    this.initialize();
  }

  /**
   * 获取ConfigRepository实例 | Get ConfigRepository instance
   * @returns ConfigRepository单例实例 | ConfigRepository singleton instance
   */
  public static getInstance(): ConfigRepository {
    if (!ConfigRepository.instance) {
      ConfigRepository.instance = new ConfigRepository();
    }
    return ConfigRepository.instance;
  }

  /**
   * 初始化默认配�?| Initialize default configs
   */
  private initializeDefaultConfigs(): void {
    // 应用基础配置 | Application basic configuration
    this.defaultConfigs.set(ConfigKey.APP_VERSION, {
      value: '1.0.0',
      type: 'string',
      category: ConfigCategory.APPLICATION
    });
    
    this.defaultConfigs.set(ConfigKey.LANGUAGE, {
      value: 'zh-CN',
      type: 'string',
      category: ConfigCategory.APPLICATION
    });
    
    this.defaultConfigs.set(ConfigKey.THEME, {
      value: 'dark',
      type: 'string',
      category: ConfigCategory.UI
    });
    
    // 播放配置 | Playback configuration
    this.defaultConfigs.set(ConfigKey.DEFAULT_QUALITY, {
      value: 'auto',
      type: 'string',
      category: ConfigCategory.PLAYBACK
    });
    
    this.defaultConfigs.set(ConfigKey.AUTO_PLAY, {
      value: true,
      type: 'boolean',
      category: ConfigCategory.PLAYBACK
    });
    
    this.defaultConfigs.set(ConfigKey.REMEMBER_POSITION, {
      value: true,
      type: 'boolean',
      category: ConfigCategory.PLAYBACK
    });
    
    // 网络配置 | Network configuration
    this.defaultConfigs.set(ConfigKey.NETWORK_TIMEOUT, {
      value: 30000,
      type: 'number',
      category: ConfigCategory.NETWORK
    });
    
    this.defaultConfigs.set(ConfigKey.USE_PROXY, {
      value: false,
      type: 'boolean',
      category: ConfigCategory.NETWORK
    });
    
    this.defaultConfigs.set(ConfigKey.MAX_CONNECTIONS, {
      value: 5,
      type: 'number',
      category: ConfigCategory.NETWORK
    });
    
    // 下载配置 | Download configuration
    this.defaultConfigs.set(ConfigKey.DOWNLOAD_PATH, {
      value: '',
      type: 'string',
      category: ConfigCategory.DOWNLOAD
    });
    
    this.defaultConfigs.set(ConfigKey.MAX_DOWNLOAD_TASKS, {
      value: 2,
      type: 'number',
      category: ConfigCategory.DOWNLOAD
    });
    
    this.defaultConfigs.set(ConfigKey.DOWNLOAD_ONLY_WIFI, {
      value: true,
      type: 'boolean',
      category: ConfigCategory.DOWNLOAD
    });
    
    // 字幕配置 | Subtitle configuration
    this.defaultConfigs.set(ConfigKey.SUBTITLE_FONT_SIZE, {
      value: 16,
      type: 'number',
      category: ConfigCategory.SUBTITLE
    });
    
    this.defaultConfigs.set(ConfigKey.SUBTITLE_COLOR, {
      value: '#FFFFFF',
      type: 'string',
      category: ConfigCategory.SUBTITLE
    });
    
    this.defaultConfigs.set(ConfigKey.SUBTITLE_BACKGROUND, {
      value: 'rgba(0,0,0,0.5)',
      type: 'string',
      category: ConfigCategory.SUBTITLE
    });
  }

  /**
   * 初始化配置系�?| Initialize configuration system
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info('Initializing config repository');
      
      // 从数据库加载配置 | Load configs from database
      await this.loadConfigsFromDatabase();
      
      // 确保默认配置已设�?| Ensure default configs are set
      await this.ensureDefaultConfigs();
      
      this.initialized = true;
      Logger.info('Config repository initialized successfully');
    } catch (error) {
      Logger.error('Failed to initialize config repository', error);
      this.initialized = false;
    }
  }

  /**
   * 从数据库加载配置 | Load configs from database
   */
  private async loadConfigsFromDatabase(): Promise<void> {
    try {
      const configs = await this.databaseRepository.getAll('configs');
      
      for (const config of configs) {
        let parsedValue: unknown = config.value;
        
        // 根据类型解析�?| Parse value based on type
        switch (config.type) {
          case 'number':
            parsedValue = Number(config.value);
            break;
          case 'boolean':
            parsedValue = config.value === 'true' || config.value === true;
            break;
          case 'object':
            try {
              parsedValue = JSON.parse(config.value);
            } catch {
              parsedValue = config.value;
            }
            break;
        }
        
        this.configCache.set(config.key, {
          value: parsedValue,
          type: config.type,
          category: config.category || ConfigCategory.GENERAL
        });
      }
      
      Logger.debug(`Loaded ${configs.length} configs from database`);
    } catch (error) {
      Logger.error('Failed to load configs from database', error);
    }
  }

  /**
   * 确保默认配置已设�?| Ensure default configs are set
   */
  private async ensureDefaultConfigs(): Promise<void> {
    try {
      for (const [key, defaultConfig] of this.defaultConfigs.entries()) {
        if (!this.configCache.has(key)) {
          await this.setConfig(key, defaultConfig.value, defaultConfig.type, defaultConfig.category);
        }
      }
    } catch (error) {
      Logger.error('Failed to ensure default configs', error);
    }
  }

  /**
   * 获取配置�?| Get config value
   * @param key 配置�?| Config key
   * @param defaultValue 默认�?| Default value
   * @returns 配置值或默认�?| Config value or default value
   */
  public async getConfig<T>(key: string, defaultValue?: T): Promise<T> {
    try {
      const config = this.configCache.get(key);
      
      if (config !== undefined) {
        return config.value as T;
      }
      
      // 如果缓存中没有，尝试从数据库获取 | If not in cache, try to get from database
      const dbConfig = await this.databaseRepository.query('configs', [{ field: 'key', operator: '=', value: key }]);
      if (dbConfig.length > 0) {
        const configData = dbConfig[0];
        let parsedvalue: unknown = configData.value;
        
        // 解析值类�?| Parse value type
        switch (configData.type) {
          case 'number':
            parsedValue = Number(configData.value);
            break;
          case 'boolean':
            parsedValue = configData.value === 'true' || configData.value === true;
            break;
          case 'object':
            try {
              parsedValue = JSON.parse(configData.value);
            } catch {
              parsedValue = configData.value;
            }
            break;
        }
        
        this.configCache.set(key, {
          value: parsedValue,
          type: configData.type,
          category: configData.category || ConfigCategory.GENERAL
        });
        
        return parsedValue as T;
      }
      
      // 如果数据库中也没有，返回默认值或默认配置中的�?| If not in database, return default value or value from default config
      const defaultConfig = this.defaultConfigs.get(key);
      return (defaultConfig ? defaultConfig.value : defaultValue) as T;
    } catch (error) {
      Logger.error(`Failed to get config: ${key}`, error);
      return defaultValue as T;
    }
  }

  /**
   * 设置配置�?| Set config value
   * @param key 配置�?| Config key
   * @param value 配置�?| Config value
   * @param type 值类�?| Value type
   * @param category 配置分类 | Config category
   */
  public async setConfig(key: string, value: unknown, type: string = 'string', category: string = ConfigCategory.GENERAL): Promise<void> {
    try {
      // 更新缓存 | Update cache
      this.configCache.set(key, {
        value,
        type,
        category
      });
      
      // 准备存储�?| Prepare storage value
      let storageValue: string | unknown = value;
      if (type === 'object') {
        storageValue = JSON.stringify(value);
      } else if (type === 'boolean') {
        storageValue = value.toString();
      }
      
      // 检查配置是否已存在 | Check if config exists
      const existingConfigs = await this.databaseRepository.query('configs', [{ field: 'key', operator: '=', value: key }]);
      
      if (existingConfigs.length > 0) {
        // 更新现有配置 | Update existing config
        await this.databaseRepository.update('configs', existingConfigs[0].id, {
          value: storageValue,
          type,
          category,
          updated_at: Date.now()
        });
      } else {
        // 插入新配�?| Insert new config
        await this.databaseRepository.insert('configs', {
          key,
          value: storageValue,
          type,
          category,
          created_at: Date.now(),
          updated_at: Date.now()
        });
      }
      
      Logger.debug(`Config set: ${key} = ${String(value)}, type: ${type}, category: ${category}`);
    } catch (error) {
      Logger.error(`Failed to set config: ${key}`, error);
      throw error;
    }
  }

  /**
   * 删除配置 | Delete config
   * @param key 配置�?| Config key
   * @returns 是否删除成功 | Whether deletion succeeded
   */
  public async deleteConfig(key: string): Promise<boolean> {
    try {
      // 从缓存中删除 | Delete from cache
      this.configCache.delete(key);
      
      // 从数据库中删�?| Delete from database
      const configs = await this.databaseRepository.query('configs', [{ field: 'key', operator: '=', value: key }]);
      
      if (configs.length > 0) {
        await this.databaseRepository.delete('configs', configs[0].id);
        Logger.debug(`Config deleted: ${key}`);
        return true;
      }
      
      return false;
    } catch (error) {
      Logger.error(`Failed to delete config: ${key}`, error);
      return false;
    }
  }

  /**
   * 批量设置配置 | Batch set configs
   * @param configs 配置对象 | Config object
   */
  public async setConfigs(configs: Record<string, unknown>): Promise<void> {
    try {
      for (const [key, value] of Object.entries(configs)) {
        const type = this.getValueType(value);
        await this.setConfig(key, value, type);
      }
      Logger.debug(`Batch set ${Object.keys(configs).length} configs`);
    } catch (error) {
      Logger.error('Failed to set configs in batch', error);
      throw error;
    }
  }

  /**
   * 获取配置分类 | Get configs by category
   * @param category 配置分类 | Config category
   * @returns 该分类下的所有配�?| All configs under this category
   */
  public async getConfigsByCategory(category: string): Promise<Map<string, ConfigValue>> {
    try {
      const result = new Map<string, ConfigValue>();
      
      for (const [key, config] of this.configCache.entries()) {
        if (config.category === category) {
          result.set(key, config);
        }
      }
      
      return result;
    } catch (error) {
      Logger.error(`Failed to get configs by category: ${category}`, error);
      return new Map();
    }
  }

  /**
   * 重置配置到默认�?| Reset config to default value
   * @param key 配置键（可选，不提供则重置所有） | Config key (optional, reset all if not provided)
   */
  public async resetToDefault(key?: string): Promise<void> {
    try {
      if (key) {
        // 重置单个配置 | Reset single config
        const defaultConfig = this.defaultConfigs.get(key);
        if (defaultConfig) {
          await this.setConfig(key, defaultConfig.value, defaultConfig.type, defaultConfig.category);
          Logger.debug(`Config reset to default: ${key}`);
        }
      } else {
        // 重置所有配�?| Reset all configs
        for (const [defaultKey, defaultConfig] of this.defaultConfigs.entries()) {
          await this.setConfig(defaultKey, defaultConfig.value, defaultConfig.type, defaultConfig.category);
        }
        Logger.debug('All configs reset to default');
      }
    } catch (error) {
      Logger.error(`Failed to reset config to default${key ? `: ${key}` : ''}`, error);
      throw error;
    }
  }

  /**
   * 导出所有配�?| Export all configs
   * @returns 配置对象 | Config object
   */
  public async exportConfigs(): Promise<Record<string, unknown>> {
    try {
      const exportData: Record<string, unknown> = {};
      
      for (const [key, config] of this.configCache.entries()) {
        exportData[key] = {
          value: config.value,
          type: config.type,
          category: config.category
        };
      }
      
      Logger.info('Configs exported successfully');
      return exportData;
    } catch (error) {
      Logger.error('Failed to export configs', error);
      return {};
    }
  }

  /**
   * 导入配置 | Import configs
   * @param configs 配置对象 | Config object
   */
  public async importConfigs(configs: Record<string, unknown>): Promise<void> {
    try {
      for (const [key, config] of Object.entries(configs)) {
        if (typeof config === 'object' && config !== null) {
          await this.setConfig(key, (config as any).value, (config as any).type, (config as any).category);
        } else {
          // 兼容旧格�?| Compatible with old format
          const type = this.getValueType(config);
          await this.setConfig(key, config, type);
        }
      }
      
      Logger.info(`Imported ${Object.keys(configs).length} configs`);
    } catch (error) {
      Logger.error('Failed to import configs', error);
      throw error;
    }
  }

  /**
   * 获取值的类型 | Get value type
   * @param value �?| Value
   * @returns 类型字符�?| Type string
   */
  private getValueType(value: unknown): string {
    if (value === null) return 'null';
    if (Array.isArray(value)) return 'array';
    if (typeof value === 'object') return 'object';
    return typeof value;
  }

  /**
   * 检查配置是否存�?| Check if config exists
   * @param key 配置�?| Config key
   * @returns 是否存在 | Whether exists
   */
  public async hasConfig(key: string): Promise<boolean> {
    return this.configCache.has(key);
  }

  /**
   * 获取所有配置键 | Get all config keys
   * @returns 配置键数�?| Config key array
   */
  public getAllConfigKeys(): string[] {
    return Array.from(this.configCache.keys());
  }
  
  /**
   * 更新配置缓存 | Refresh config cache
   */
  public async refreshCache(): Promise<void> {
    try {
      this.configCache.clear();
      await this.loadConfigsFromDatabase();
      Logger.debug('Config cache refreshed');
    } catch (error) {
      Logger.error('Failed to refresh config cache', error);
    }
  }

  /**
   * 重置仓库 | Reset repository
   */
  public async reset(): Promise<void> {
    try {
      Logger.info('Resetting config repository');
      
      // 清空缓存 | Clear cache
      this.configCache.clear();
      
      // 清空数据库中的配�?| Clear configs in database
      await this.databaseRepository.clearTable('configs');
      
      // 重新初始化默认配�?| Reinitialize default configs
      this.initializeDefaultConfigs();
      await this.ensureDefaultConfigs();
      
      Logger.info('Config repository reset completed');
    } catch (error) {
      Logger.error('Failed to reset config repository', error);
      throw error;
    }
  }
}

export default ConfigRepository;
