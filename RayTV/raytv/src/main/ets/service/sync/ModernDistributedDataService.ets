// ModernDistributedDataService.ets - 现代化分布式数据服务
// 基于HarmonyOS 5.0+分布式KVStore API实现多设备数据同步

import Logger from '../../common/util/Logger';
import distributedKVStore from '@ohos.data.distributedKVStore';
import deviceManager from '@ohos.distributedDeviceManager';
import { BusinessError } from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';
import common from '@ohos.app.ability.common';

// 常量定义
const TAG = 'ModernDistributedDataService';
const STORE_ID = 'raytv_distributed_kvstore';

// 数据同步类型枚举
export enum SyncDataType {
  HISTORY = 'history',
  FAVORITES = 'favorites',
  CONFIG = 'config',
  PLAYBACK_PROGRESS = 'playback_progress',
  DEVICE_INFO = 'device_info'
}

// 同步冲突解决策略枚举
export enum ConflictResolutionStrategy {
  LATEST_WIN = 'latest_win', // 最新时间戳优先
  LOCAL_WIN = 'local_win',   // 本地数据优先
  REMOTE_WIN = 'remote_win', // 远程数据优先
  MERGE = 'merge'            // 合并数据
}

// 同步状态枚举
export enum SyncStatus {
  IDLE = 'idle',
  SYNCHRONIZING = 'synchronizing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CONFLICT = 'conflict'
}

// 同步配置接口
export interface SyncConfig {
  enabled: boolean;
  autoSync: boolean;
  syncInterval: number; // 秒
  conflictStrategy: ConflictResolutionStrategy;
  syncTypes: SyncDataType[];
  allowCellularSync: boolean;
  showSyncNotifications: boolean;
}

// 默认同步配置
const DEFAULT_SYNC_CONFIG: SyncConfig = {
  enabled: true,
  autoSync: true,
  syncInterval: 300, // 5分钟
  conflictStrategy: ConflictResolutionStrategy.LATEST_WIN,
  syncTypes: [SyncDataType.HISTORY, SyncDataType.FAVORITES],
  allowCellularSync: false,
  showSyncNotifications: true
};

// 同步状态接口
export interface SyncState {
  status: SyncStatus;
  lastSyncTime?: number;
  lastSyncResult?: boolean;
  error?: string;
  conflictCount?: number;
  syncedDevices?: string[];
  syncDataSize?: number;
}

// 同步数据接口
export interface SyncData<T = any> {
  data: T;
  timestamp: number;
  deviceId: string;
}

// 分布式数据监听回调类型
type DataChangeListener = <T = any>(key: string, data: T, deviceId: string) => void;

export default class ModernDistributedDataService {
  static instance: ModernDistributedDataService;
  kvManager: distributedKVStore.KVManager | null = null;
  kvStore: distributedKVStore.SingleKVStore | null = null;
  configService: ConfigService;
  syncConfig: SyncConfig = DEFAULT_SYNC_CONFIG;
  syncState: SyncState = { status: SyncStatus.IDLE };
  dataListeners: Map<string, DataChangeListener[]> = new Map();
  syncTimerId: number | null = null;
  deviceIds: string[] = [];
  isInitialized: boolean = false;
  context: common.Context | null = null;

  /**
   * 获取单例实例
   */
  static getInstance(): ModernDistributedDataService {
    if (!ModernDistributedDataService.instance) {
      ModernDistributedDataService.instance = new ModernDistributedDataService();
    }
    return ModernDistributedDataService.instance;
  }

  /**
   * 构造函数
   */
  constructor() {
    this.configService = ConfigService.getInstance();
  }

  /**
   * 设置应用上下文
   * @param ctx 应用上下文
   */
  public setContext(ctx: common.Context): void {
    this.context = ctx;
  }

  /**
   * 获取应用上下文
   * @returns 应用上下文
   */
  private getContext(): common.Context {
    if (!this.context) {
      throw new Error('ModernDistributedDataService context not set. Please call setContext() first.');
    }
    return this.context;
  }

  /**
   * 初始化分布式数据服务
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Modern distributed data service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing modern distributed data service...');

      // 创建KVManager
      const kvManagerConfig: distributedKVStore.KVManagerConfig = {
        context: this.getContext(),
        bundleName: 'com.example.raytv'
      };

      this.kvManager = distributedKVStore.createKVManager(kvManagerConfig);
      if (!this.kvManager) {
        throw new Error('Failed to create KVManager instance');
      }

      // 创建KVStore
      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options);
      if (!this.kvStore) {
        throw new Error('Failed to get KVStore instance');
      }

      // 加载同步配置
      await this.loadSyncConfig();

      // 注册数据变化监听
      await this.registerDataChangeListener();

      // 启动自动同步
      if (this.syncConfig.autoSync && this.syncConfig.enabled) {
        this.startAutoSync();
      }

      this.isInitialized = true;
      Logger.info(TAG, 'Modern distributed data service initialized successfully');
    } catch (error: Error) {
      Logger.error(TAG, `Failed to initialize modern distributed data service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 加载同步配置
   */
  async loadSyncConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('syncConfig', DEFAULT_SYNC_CONFIG);
      if (savedConfig) {
        this.syncConfig = { ...DEFAULT_SYNC_CONFIG, ...savedConfig };
      }
    } catch (error: Error) {
      Logger.error(TAG, `Failed to load sync config: ${error}`);
    }
  }

  /**
   * 保存同步配置
   */
  async saveSyncConfig(config: Partial<SyncConfig>): Promise<void> {
    try {
      this.syncConfig = { ...this.syncConfig, ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig);
      
      // 根据配置调整自动同步
      if (this.syncConfig.autoSync && this.syncConfig.enabled) {
        this.startAutoSync();
      } else {
        this.stopAutoSync();
      }
    } catch (error: Error) {
      Logger.error(TAG, `Failed to save sync config: ${error}`);
      throw error;
    }
  }

  /**
   * 获取同步配置
   */
  getSyncConfig(): SyncConfig {
    return { ...this.syncConfig };
  }

  /**
   * 注册数据变化监听
   */
  async registerDataChangeListener(): Promise<void> {
    if (!this.kvStore) {
      throw new Error('KVStore not initialized');
    }

    try {
      // 使用新的数据变化监听API
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, (data) => {
        Logger.debug(TAG, `Data change detected: ${JSON.stringify(data)}`);
        
        if (data && data.insertEntries && data.insertEntries.length > 0) {
          data.insertEntries.forEach(entry => {
            const key = entry.key.toString();
            const deviceId = entry.deviceId || 'local';
            
            // 获取数据并通知监听器
            this.kvStore?.get(key).then((value) => {
              if (this.dataListeners.has(key)) {
                const listeners = this.dataListeners.get(key)!;
                for (const listener of listeners) {
                  try {
                    listener(key, value, deviceId);
                  } catch (error: Error) {
                    Logger.error(TAG, `Error in data listener: ${error}`);
                  }
                }
              }
            }).catch((error: Error) => {
              Logger.error(TAG, `Failed to get changed data: ${error}`);
            });
          });
        }
      });
    } catch (error: Error) {
      Logger.error(TAG, `Failed to register data change listener: ${error}`);
    }
  }

  /**
   * 监听特定类型的数据变化
   * @param dataType 数据类型
   * @param listener 监听回调
   */
  addDataChangeListener(dataType: SyncDataType, listener: DataChangeListener): void {
    const keyPrefix = `${dataType}_`;
    
    if (!this.dataListeners.has(keyPrefix)) {
      this.dataListeners.set(keyPrefix, []);
    }
    
    this.dataListeners.get(keyPrefix)!.push(listener);
    Logger.debug(TAG, `Added data change listener for ${dataType}`);
  }

  /**
   * 移除数据变化监听
   * @param dataType 数据类型
   * @param listener 监听回调
   */
  removeDataChangeListener(dataType: SyncDataType, listener: DataChangeListener): void {
    const keyPrefix = `${dataType}_`;
    
    if (this.dataListeners.has(keyPrefix)) {
      const listeners = this.dataListeners.get(keyPrefix)!;
      const index = listeners.indexOf(listener);
      
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 保存同步数据
   * @param dataType 数据类型
   * @param key 数据键
   * @param data 数据内容
   */
  async saveSyncData<T = any>(dataType: SyncDataType, key: string, data: T): Promise<void> {
    if (!this.kvStore || !this.syncConfig.enabled) {
      return;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      const syncData = {
        data,
        timestamp: Date.now(),
        deviceId: await this.getLocalDeviceId()
      };

      await this.kvStore.put(fullKey, syncData);
      Logger.debug(TAG, `Saved sync data: ${fullKey}`);
    } catch (error: Error) {
      Logger.error(TAG, `Failed to save sync data: ${error}`);
      throw error;
    }
  }

  /**
   * 获取同步数据
   * @param dataType 数据类型
   * @param key 数据键
   */
  async getSyncData<T = any>(dataType: SyncDataType, key: string): Promise<T | null> {
    if (!this.kvStore) {
      return null;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      const value = await this.kvStore.get(fullKey) as SyncData<T> | undefined;

      if (value && typeof value === 'object' && 'data' in value) {
        Logger.debug(TAG, `Retrieved sync data: ${fullKey}`);
        return value.data;
      }
      
      return null;
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get sync data: ${error}`);
      return null;
    }
  }

  /**
   * 删除同步数据
   * @param dataType 数据类型
   * @param key 数据键
   */
  async deleteSyncData(dataType: SyncDataType, key: string): Promise<void> {
    if (!this.kvStore || !this.syncConfig.enabled) {
      return;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      await this.kvStore.delete(fullKey);
      Logger.debug(TAG, `Deleted sync data: ${fullKey}`);
    } catch (error: Error) {
      Logger.error(TAG, `Failed to delete sync data: ${error}`);
      throw error;
    }
  }

  /**
   * 获取本地设备ID
   */
  private async getLocalDeviceId(): Promise<string> {
    try {
      const deviceInfo = await deviceManager.getLocalDeviceInfo();
      return deviceInfo.deviceId;
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get local device ID: ${error}`);
      return 'unknown';
    }
  }

  /**
   * 获取可用设备列表
   */
  private async getAvailableDevices(): Promise<string[]> {
    try {
      const devices = await deviceManager.getAvailableDeviceListSync();
      this.deviceIds = devices.map(device => device.deviceId);
      return this.deviceIds;
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get available devices: ${error}`);
      return [];
    }
  }

  /**
   * 启动自动同步
   */
  private startAutoSync(): void {
    this.stopAutoSync(); // 先停止现有的定时器
    
    this.syncTimerId = setInterval(async () => {
      try {
        await this.synchronizeData();
      } catch (error: Error) {
        Logger.error(TAG, `Auto sync failed: ${error}`);
      }
    }, this.syncConfig.syncInterval * 1000);
    
    Logger.info(TAG, 'Auto sync started');
  }

  /**
   * 停止自动同步
   */
  private stopAutoSync(): void {
    if (this.syncTimerId !== null) {
      clearInterval(this.syncTimerId);
      this.syncTimerId = null;
      Logger.info(TAG, 'Auto sync stopped');
    }
  }

  /**
   * 手动触发数据同步
   */
  async synchronizeData(): Promise<void> {
    if (!this.kvStore || !this.syncConfig.enabled || this.syncState.status === SyncStatus.SYNCHRONIZING) {
      return;
    }

    this.syncState = {
      status: SyncStatus.SYNCHRONIZING,
      syncedDevices: []
    };

    try {
      Logger.info(TAG, 'Starting data synchronization...');
      
      // 获取在线设备列表
      const devices = await this.getAvailableDevices();
      Logger.debug(TAG, `Available devices: ${JSON.stringify(devices)}`);
      
      // 同步每种数据类型
      for (const dataType of this.syncConfig.syncTypes) {
        await this.syncDataType(dataType, devices);
      }
      
      this.syncState = {
        status: SyncStatus.COMPLETED,
        lastSyncTime: Date.now(),
        lastSyncResult: true,
        syncedDevices: devices
      };
      
      Logger.info(TAG, 'Data synchronization completed successfully');
    } catch (error: Error) {
      Logger.error(TAG, `Data synchronization failed: ${error}`);
      this.syncState = {
        status: SyncStatus.FAILED,
        error: String(error),
      };
      throw error;
    }
  }

  /**
   * 同步特定数据类型
   */
  private async syncDataType(dataType: SyncDataType, deviceIds: string[]): Promise<void> {
    if (!this.kvStore) {
      return;
    }

    Logger.debug(TAG, `Syncing data type: ${dataType} with ${deviceIds.length} devices`);
    const keyPrefix = `${dataType}_`;

    try {
      // 获取所有匹配前缀的键
      const keys = await this.getAllKeysWithPrefix(keyPrefix);
      Logger.debug(TAG, `Found ${keys.length} keys for data type ${dataType}`);

      for (const fullKey of keys) {
        // 获取本地数据
        const localData = await this.kvStore.get(fullKey);
        if (!localData) continue;

        // 数据会自动同步到其他设备，无需手动处理
        Logger.debug(TAG, `Auto-synced ${fullKey}`);
      }
    } catch (error: Error) {
      Logger.error(TAG, `Failed to sync data type ${dataType}: ${error}`);
      throw error;
    }
  }

  /**
   * 获取所有匹配前缀的键
   */
  private async getAllKeysWithPrefix(prefix: string): Promise<string[]> {
    if (!this.kvStore) {
      return [];
    }

    try {
      const allKeys = await this.kvStore.getEntries('');
      return allKeys.result.filter((entry: distributedKVStore.Entry) => 
        entry.key.toString().startsWith(prefix)
      ).map((entry: distributedKVStore.Entry) => entry.key.toString());
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get keys with prefix ${prefix}: ${error}`);
      return [];
    }
  }

  /**
   * 获取同步状态
   */
  getSyncState(): SyncState {
    return { ...this.syncState };
  }

  /**
   * 关闭分布式数据服务
   */
  close(): void {
    this.stopAutoSync();
    if (this.kvManager) {
      // KVStore会由系统自动管理生命周期，不需要手动关闭
    }
    Logger.info(TAG, 'Modern distributed data service closed');
  }
}