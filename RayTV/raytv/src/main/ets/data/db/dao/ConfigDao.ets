import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { CONFIG_TABLE } from '../TableSchema';
import { AppConfig, PlayerConfig, DisplayConfig, NetworkConfig, SecurityConfig, AdBlockConfig, HarmonyConfig, SearchConfig, DownloadConfig, SyncConfig, LogConfig } from '../../bean/Config';
import Logger from '../../../common/util/Logger';
import JsonUtil from '../../../common/util/JsonUtil';

const TAG = 'ConfigDao';

// 配置分组常量
export const CONFIG_GROUPS = {
  PLAYER: 'player',
  DISPLAY: 'display',
  NETWORK: 'network',
  SECURITY: 'security',
  ADBLOCK: 'adblock',
  HARMONY: 'harmony',
  SEARCH: 'search',
  DOWNLOAD: 'download',
  SYNC: 'sync',
  LOG: 'log',
  APP: 'app'
};

// 配置类型常量
export const CONFIG_TYPES = {
  OBJECT: 'object',
  STRING: 'string',
  NUMBER: 'number',
  BOOLEAN: 'boolean',
  ARRAY: 'array'
};

// 内部配置项接口
interface InternalConfig {
  key: string;
  value: any;
  type: string;
  group: string;
  updatedAt: number;
}

export class ConfigDao {
  private db: relationalStore.RdbStore;
  
  constructor() {
    this.db = DatabaseManager.getInstance().getDatabase();
  }
  
  // 保存配置项
  public async saveConfig(key: string, value: any, type: string, group: string): Promise<void> {
    try {
      const config: InternalConfig = {
        key,
        value,
        type,
        group,
        updatedAt: Date.now()
      };
      await this.saveInternal(config);
    } catch (error) {
      Logger.error(TAG, `Failed to save config ${key}: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 内部保存方法
  private async saveInternal(config: InternalConfig): Promise<void> {
    try {
      // 检查是否已存在
      const existing = await this.getByKeyInternal(config.key);
      
      const valuesBucket: relationalStore.ValuesBucket = {
        [CONFIG_TABLE.COLUMNS.KEY]: config.key,
        [CONFIG_TABLE.COLUMNS.VALUE]: JsonUtil.stringify(config.value),
        [CONFIG_TABLE.COLUMNS.TYPE]: config.type,
        [CONFIG_TABLE.COLUMNS.GROUP]: config.group,
        [CONFIG_TABLE.COLUMNS.UPDATED_AT]: config.updatedAt
      };
      
      if (existing) {
        // 更新
        const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.NAME);
        predicates.equalTo(CONFIG_TABLE.COLUMNS.KEY, config.key);
        await this.db.update(valuesBucket, predicates);
      } else {
        // 插入
        await this.db.insert(CONFIG_TABLE.NAME, valuesBucket);
      }
      
      Logger.debug(TAG, `Saved config: ${config.key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to save internal config: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 批量保存配置
  public async saveBatch(configs: InternalConfig[]): Promise<void> {
    try {
      for (const config of configs) {
        await this.saveInternal(config);
      }
      Logger.debug(TAG, `Saved ${configs.length} config items`);
    } catch (error) {
      Logger.error(TAG, `Failed to save batch configs: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据key获取配置
  private async getByKeyInternal(key: string): Promise<InternalConfig | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.NAME);
      predicates.equalTo(CONFIG_TABLE.COLUMNS.KEY, key);
      
      const resultSet = await this.db.query(predicates);
      const configs = this.parseResultSetInternal(resultSet);
      return configs.length > 0 ? configs[0] : null;
    } catch (error) {
      Logger.error(TAG, `Failed to get config by key: ${JSON.stringify(error)}`);
      return null;
    }
  }
  
  // 获取配置值
  public async getConfigValue<T>(key: string, defaultValue: T): Promise<T> {
    try {
      const config = await this.getByKeyInternal(key);
      return config ? config.value : defaultValue;
    } catch (error) {
      Logger.error(TAG, `Failed to get config value ${key}: ${JSON.stringify(error)}`);
      return defaultValue;
    }
  }
  
  // 获取指定分组的配置
  public async getByGroup(group: string): Promise<Record<string, any>> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.NAME);
      predicates.equalTo(CONFIG_TABLE.COLUMNS.GROUP, group);
      
      const resultSet = await this.db.query(predicates);
      const configs = this.parseResultSetInternal(resultSet);
      
      const result: Record<string, any> = {};
      configs.forEach(config => {
        result[config.key] = config.value;
      });
      
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get configs by group: ${JSON.stringify(error)}`);
      return {};
    }
  }
  
  // 获取所有配置
  public async getAllConfigs(): Promise<Record<string, any>> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.NAME);
      
      const resultSet = await this.db.query(predicates);
      const configs = this.parseResultSetInternal(resultSet);
      
      const result: Record<string, any> = {};
      configs.forEach(config => {
        result[config.key] = config.value;
      });
      
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get all configs: ${JSON.stringify(error)}`);
      return {};
    }
  }
  
  // 保存播放器配置
  public async savePlayerConfig(config: PlayerConfig): Promise<void> {
    await this.saveConfig('player', config, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.PLAYER);
  }
  
  // 获取播放器配置
  public async getPlayerConfig(): Promise<PlayerConfig> {
    const defaultValue: PlayerConfig = {
      defaultResolution: 'auto',
      autoplay: true,
      rememberPosition: true,
      volume: 80,
      brightness: 100,
      speed: 1.0,
      subtitles: {
        enabled: false,
        fontSize: 16,
        fontFamily: 'sans-serif',
        color: '#FFFFFF',
        backgroundColor: 'rgba(0, 0, 0, 0.5)'
      },
      audioTrack: 'default',
      aspectRatio: 'auto'
    };
    return await this.getConfigValue('player', defaultValue);
  }
  
  // 保存显示配置
  public async saveDisplayConfig(config: DisplayConfig): Promise<void> {
    await this.saveConfig('display', config, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.DISPLAY);
  }
  
  // 获取显示配置
  public async getDisplayConfig(): Promise<DisplayConfig> {
    const defaultValue: DisplayConfig = {
      theme: 'light',
      language: 'zh-CN',
      fontSize: 16,
      autoRotate: true,
      showAds: false,
      splashScreenTime: 3000
    };
    return await this.getConfigValue('display', defaultValue);
  }
  
  // 保存应用完整配置
  public async saveAppConfig(appConfig: AppConfig): Promise<void> {
    try {
      await this.savePlayerConfig(appConfig.player);
      await this.saveDisplayConfig(appConfig.display);
      await this.saveConfig('network', appConfig.network, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.NETWORK);
      await this.saveConfig('security', appConfig.security, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.SECURITY);
      await this.saveConfig('adblock', appConfig.adBlock, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.ADBLOCK);
      await this.saveConfig('harmony', appConfig.harmony, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.HARMONY);
      await this.saveConfig('search', appConfig.search, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.SEARCH);
      await this.saveConfig('download', appConfig.download, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.DOWNLOAD);
      await this.saveConfig('sync', appConfig.sync, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.SYNC);
      await this.saveConfig('log', appConfig.log, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.LOG);
      await this.saveConfig('appMetadata', {
        version: appConfig.version,
        lastUpdated: appConfig.lastUpdated
      }, CONFIG_TYPES.OBJECT, CONFIG_GROUPS.APP);
      Logger.debug(TAG, 'App config saved successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to save app config: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 获取应用完整配置
  public async getAppConfig(): Promise<AppConfig> {
    try {
      const player = await this.getPlayerConfig();
      const display = await this.getDisplayConfig();
      const network = await this.getConfigValue('network', {
        timeout: 30000,
        retryCount: 3,
        useProxy: false,
        proxyUrl: '',
        userAgent: ''
      } as NetworkConfig);
      const security = await this.getConfigValue('security', {
        enableBiometric: false,
        requireAuth: false,
        autoLockTime: 300000
      } as SecurityConfig);
      const adBlock = await this.getConfigValue('adblock', {
        enabled: true,
        filters: []
      } as AdBlockConfig);
      const harmony = await this.getConfigValue('harmony', {
        enableFullscreenGesture: true,
        enableSystemUi: true,
        enableHwAcceleration: true
      } as HarmonyConfig);
      const search = await this.getConfigValue('search', {
        enableHistory: true,
        maxHistoryItems: 50,
        defaultSearchEngine: 'internal'
      } as SearchConfig);
      const download = await this.getConfigValue('download', {
        enabled: true,
        maxConcurrent: 3,
        savePath: '',
        useMobileData: false
      } as DownloadConfig);
      const sync = await this.getConfigValue('sync', {
        enabled: false,
        syncInterval: 3600000,
        lastSyncTime: 0
      } as SyncConfig);
      const log = await this.getConfigValue('log', {
        enabled: true,
        level: 'info',
        maxFileSize: 10485760
      } as LogConfig);
      const appMetadata = await this.getConfigValue('appMetadata', {
        version: '1.0.0',
        lastUpdated: Date.now()
      });
      
      return {
        player,
        display,
        network,
        security,
        adBlock,
        harmony,
        search,
        download,
        sync,
        log,
        version: appMetadata.version,
        lastUpdated: appMetadata.lastUpdated
      };
    } catch (error) {
      Logger.error(TAG, `Failed to get app config: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 删除配置
  public async delete(key: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.NAME);
      predicates.equalTo(CONFIG_TABLE.COLUMNS.KEY, key);
      
      await this.db.delete(predicates);
      Logger.debug(TAG, `Deleted config: ${key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete config: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 清空指定分组的配置
  public async clearByGroup(group: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.NAME);
      predicates.equalTo(CONFIG_TABLE.COLUMNS.GROUP, group);
      
      await this.db.delete(predicates);
      Logger.debug(TAG, `Cleared configs for group: ${group}`);
    } catch (error) {
      Logger.error(TAG, `Failed to clear configs by group: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 清空所有配置
  public async clearAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.NAME);
      await this.db.delete(predicates);
      Logger.debug(TAG, 'Cleared all configs');
    } catch (error) {
      Logger.error(TAG, `Failed to clear all configs: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 解析结果集
  private parseResultSetInternal(resultSet: relationalStore.ResultSet): InternalConfig[] {
    const configs: InternalConfig[] = [];
    
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      do {
        try {
          const valueStr = resultSet.getString(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.VALUE));
          let value = null;
          if (valueStr) {
            value = JsonUtil.parse(valueStr);
          }
          
          configs.push({
            key: resultSet.getString(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.KEY)),
            value,
            type: resultSet.getString(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.TYPE)),
            group: resultSet.getString(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.GROUP)),
            updatedAt: resultSet.getLong(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.UPDATED_AT))
          });
        } catch (parseError) {
          Logger.error(TAG, `Failed to parse config value: ${JSON.stringify(parseError)}`);
        }
      } while (resultSet.goToNextRow());
    }
    
    resultSet.close();
    return configs;
  }
}