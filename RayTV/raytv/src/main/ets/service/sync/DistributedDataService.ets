// DistributedDataService.ets - 分布式数据服务
// 基于HarmonyOS分布式能力实现多设备数据同步

import Logger from '../../common/util/Logger';
import distributedData from '@ohos.data.distributedData';
import { BusinessError } from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';

// 常量定义
const TAG = 'DistributedDataService';
const STORE_ID = 'raytv_distributed_data';
const STORE_CONFIG = {
  name: STORE_ID,
  securityLevel: distributedData.SecurityLevel.S1
};

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

// 分布式数据监听回调类型
type DataChangeListener = (key: string, data: any, deviceId: string) => void;

export default class DistributedDataService {
  static instance: DistributedDataService;
  kvStore: distributedData.KVStore | null = null;
  configService: ConfigService;
  syncConfig: SyncConfig = DEFAULT_SYNC_CONFIG;
  syncState: SyncState = { status: SyncStatus.IDLE };
  dataListeners: Map<string, DataChangeListener[]> = new Map();
  syncTimerId: number | null = null;
  deviceIds: string[] = [];
  isInitialized: boolean = false;

  /**
   * 获取单例实例
   */
  static getInstance(): DistributedDataService {
    if (!DistributedDataService.instance) {
      DistributedDataService.instance = new DistributedDataService();
    }
    return DistributedDataService.instance;
  }

  /**
   * 构造函数
   */
  constructor() {
  }

  /**
   * 初始化分布式数据服务
   * @param context 应用上下文
   */
  async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Distributed data service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing distributed data service...');

      // 初始化KVStore
      this.kvStore = await distributedData.getKVStore(context, STORE_CONFIG);
      if (!this.kvStore) {
        throw new Error('Failed to get KVStore instance');
      }

      // 初始化ConfigService
      this.configService = ConfigService.getInstance();
      
      // 加载同步配置
      await this.loadSyncConfig();

      // 注册数据变化监听
      await this.registerDataChangeListener();

      // 启动自动同步
      if (this.syncConfig.autoSync && this.syncConfig.enabled) {
        this.startAutoSync();
      }

      this.isInitialized = true;
      Logger.info(TAG, 'Distributed data service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize distributed data service: ${JSON.stringify(error)}`);
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
    } catch (error) {
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
    } catch (error) {
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
      await this.kvStore.on('dataChange', (changeData) => {
        Logger.debug(TAG, `Data change detected: ${JSON.stringify(changeData)}`);
        
        if (changeData.changeType === distributedData.DataChangeType.SET) {
          const key = changeData.key;
          const deviceId = changeData.deviceId;
          
          // 获取数据并通知监听器
          this.kvStore?.get(key).then((value) => {
            if (this.dataListeners.has(key)) {
              const listeners = this.dataListeners.get(key)!;
              for (const listener of listeners) {
                try {
                  listener(key, value, deviceId);
                } catch (error) {
                  Logger.error(TAG, `Error in data listener: ${error}`);
                }
              }
            }
          }).catch(error => {
            Logger.error(TAG, `Failed to get changed data: ${error}`);
          });
        }
      });
    } catch (error) {
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
   * @param deviceId 目标设备ID（可选，不指定则同步到所有设备）
   */
  async saveSyncData(dataType: SyncDataType, key: string, data: any, deviceId?: string): Promise<void> {
    if (!this.kvStore || !this.syncConfig.enabled) {
      return;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      const syncData = {
        data,
        timestamp: Date.now(),
        deviceId: distributedData.getLocalDeviceId()
      };

      if (deviceId) {
        // 同步到指定设备
        await this.kvStore.set(fullKey, syncData, deviceId);
        Logger.debug(TAG, `Saved sync data to device ${deviceId}: ${fullKey}`);
      } else {
        // 同步到所有设备
        await this.kvStore.set(fullKey, syncData);
        Logger.debug(TAG, `Saved sync data to all devices: ${fullKey}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save sync data: ${error}`);
      throw error;
    }
  }

  /**
   * 获取同步数据
   * @param dataType 数据类型
   * @param key 数据键
   * @param deviceId 设备ID（可选，不指定则获取本地数据）
   */
  async getSyncData(dataType: SyncDataType, key: string, deviceId?: string): Promise<any | null> {
    if (!this.kvStore) {
      return null;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      let value: any = null;

      if (deviceId) {
        // 从指定设备获取数据
        value = await this.kvStore.get(fullKey, deviceId);
      } else {
        // 获取本地数据
        value = await this.kvStore.get(fullKey);
      }

      if (value) {
        Logger.debug(TAG, `Retrieved sync data: ${fullKey}`);
        return value.data;
      }
      
      return null;
    } catch (error) {
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
    } catch (error) {
      Logger.error(TAG, `Failed to delete sync data: ${error}`);
      throw error;
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
      } catch (error) {
        Logger.error(TAG, `Auto sync failed: ${error}`);
      }
    }, this.syncConfig.syncInterval * 1000);
    
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
    } catch (error) {
      Logger.error(TAG, `Data synchronization failed: ${error}`);
      this.syncState = {
        status: SyncStatus.FAILED,
        error: String(error),
      };
      throw error;
    }
  }

  /**
   * 获取可用设备列表
   */
  private async getAvailableDevices(): Promise<string[]> {
    try {
      const devices = await distributedData.getConnectedDevices();
      this.deviceIds = devices.map(device => device.deviceId);
      return this.deviceIds;
    } catch (error) {
      Logger.error(TAG, `Failed to get available devices: ${error}`);
      return [];
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

        // 与每个设备的数据进行同步
        for (const deviceId of deviceIds) {
          try {
            // 获取远程设备的数据
            const remoteData = await this.kvStore.get(fullKey, deviceId);

            if (!remoteData) {
              // 远程没有数据，直接同步过去
              Logger.debug(TAG, `Synced ${fullKey} to device ${deviceId}`);
            } else if (remoteData.timestamp !== localData.timestamp) {
              // 数据不同，需要解决冲突
              const resolvedData = this.resolveConflict(localData, remoteData);
              
              // 更新本地和远程数据
              if (JSON.stringify(resolvedData) !== JSON.stringify(localData)) {
                await this.kvStore.set(fullKey, resolvedData);
              }
              
              if (JSON.stringify(resolvedData) !== JSON.stringify(remoteData)) {
                await this.kvStore.set(fullKey, resolvedData, deviceId);
              }
              
              Logger.debug(TAG, `Resolved conflict for ${fullKey} with device ${deviceId}`);
            }
          } catch (error) {
            Logger.error(TAG, `Failed to sync ${fullKey} with device ${deviceId}: ${error}`);
            // 继续处理其他设备
          }
        }
      }
    } catch (error) {
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
      const allKeys = await this.kvStore.getAllKeys();
      return allKeys.filter(key => key.startsWith(prefix));
    } catch (error) {
      Logger.error(TAG, `Failed to get keys with prefix ${prefix}: ${error}`);
      return [];
    }
  }

  /**
   * 处理同步冲突
   */
  private resolveConflict(localData: any, remoteData: any): any {
    switch (this.syncConfig.conflictStrategy) {
      case ConflictResolutionStrategy.LOCAL_WIN:
        return localData;
      case ConflictResolutionStrategy.REMOTE_WIN:
        return remoteData;
      case ConflictResolutionStrategy.LATEST_WIN:
        return localData.timestamp >= remoteData.timestamp ? localData : remoteData;
      case ConflictResolutionStrategy.MERGE:
        // TODO: 实现合并策略
        return this.mergeData(localData, remoteData);
      default:
        return localData;
    }
  }

  /**
   * 合并数据（根据不同数据类型实现智能合并策略）
   */
  private mergeData(localData: any, remoteData: any): any {
    // 确保输入是对象
    if (typeof localData !== 'object' || localData === null) {
      return remoteData;
    }
    if (typeof remoteData !== 'object' || remoteData === null) {
      return localData;
    }

    // 创建合并结果对象
    const merged = { ...localData };
    
    // 根据数据类型实现不同的合并策略
    for (const key in remoteData) {
      if (remoteData.hasOwnProperty(key)) {
        // 跳过时间戳和设备ID，这些不应被合并
        if (key === 'timestamp' || key === 'deviceId') {
          continue;
        }

        const keyPrefix = key.split('_')[0];
        
        switch (keyPrefix) {
          case SyncDataType.HISTORY:
            // 历史记录合并：保留最新的观看记录
            if (remoteData[key] && localData[key]) {
              merged[key] = {
                ...remoteData[key],
                // 保留本地数据中可能存在的额外字段
                ...localData[key],
                // 但使用最新的时间戳
                lastWatched: Math.max(remoteData[key].lastWatched || 0, localData[key].lastWatched || 0)
              };
            } else {
              merged[key] = remoteData[key] || localData[key];
            }
            break;
            
          case SyncDataType.FAVORITES:
            // 收藏合并：合并两个列表
            if (Array.isArray(localData[key]) && Array.isArray(remoteData[key])) {
              // 创建一个集合以避免重复
              const mergedSet = new Set([...localData[key], ...remoteData[key]]);
              merged[key] = Array.from(mergedSet);
            } else {
              merged[key] = remoteData[key] || localData[key];
            }
            break;
            
          case SyncDataType.PLAYBACK_PROGRESS:
            // 播放进度合并：保留最新的进度
            if (remoteData[key] && localData[key]) {
              const remoteProgress = remoteData[key].progress || 0;
              const localProgress = localData[key].progress || 0;
              
              if (remoteProgress > localProgress) {
                merged[key] = remoteData[key];
              } else {
                merged[key] = localData[key];
              }
            } else {
              merged[key] = remoteData[key] || localData[key];
            }
            break;
            
          default:
            // 默认策略：如果两个都是对象，递归合并
            if (typeof localData[key] === 'object' && 
                typeof remoteData[key] === 'object' && 
                !Array.isArray(localData[key]) && 
                !Array.isArray(remoteData[key])) {
              merged[key] = this.mergeData(localData[key], remoteData[key]);
            } else {
              // 对于数组和基本类型，使用远程数据
              merged[key] = remoteData[key];
            }
        }
      }
    }
    
    // 更新合并后的时间戳和设备ID
    merged.timestamp = Date.now();
    merged.deviceId = distributedData.getLocalDeviceId();
    
    return merged;
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
    // KVStore会由系统自动管理生命周期，不需要手动关闭
    Logger.info(TAG, 'Distributed data service closed');
  }
}