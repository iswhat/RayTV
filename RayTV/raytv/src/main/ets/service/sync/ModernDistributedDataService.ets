// ModernDistributedDataService.ets - Modern distributed data service | 现代化分布式数据服务
// Based on HarmonyOS 5.0+ distributed KVStore API to implement multi-device data synchronization | 基于HarmonyOS 5.0+分布式KVStore API实现多设备数据同步
import Logger from '../../common/util/Logger';
import distributedKVStore from '@ohos.data.distributedKVStore';
import deviceManager from '@ohos.distributedDeviceManager';
import BusinessError from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';
import common from '@ohos.app.ability.common';
import { Serializable } from '../../types/commonTypes';

// Constant definitions | 常量定义
const TAG = 'ModernDistributedDataService';
const STORE_ID = 'raytv_distributed_kvstore';

// Sync data type enumeration | 数据同步类型枚举
export enum SyncDataType {
  HISTORY = 'history', // Browsing history | 浏览历史
  FAVORITES = 'favorites', // Favorite items | 收藏项目
  CONFIG = 'config', // Configuration data | 配置数据
  PLAYBACK_PROGRESS = 'playback_progress', // Playback progress | 播放进度
  DEVICE_INFO = 'device_info' // Device information | 设备信息
}

// Conflict resolution strategy enumeration | 同步冲突解决策略枚举
export enum ConflictResolutionStrategy {
  LATEST_WIN = 'latest_win', // Latest timestamp wins | 最新时间戳优先
  LOCAL_WIN = 'local_win',   // Local data wins | 本地数据优先
  REMOTE_WIN = 'remote_win', // Remote data wins | 远端数据优先
  MERGE = 'merge'            // Merge data | 合并数据
}

// Sync status enumeration | 同步状态枚举
export enum SyncStatus {
  IDLE = 'idle', // Idle state | 空闲状态
  SYNCHRONIZING = 'synchronizing', // Synchronizing | 同步中
  COMPLETED = 'completed', // Synchronization completed | 同步完成
  FAILED = 'failed', // Synchronization failed | 同步失败
  CONFLICT = 'conflict' // Synchronization conflict | 同步冲突
}

// Sync configuration interface | 同步配置接口
export interface SyncConfig {
  enabled: boolean; // Whether sync is enabled | 是否启用同步
  autoSync: boolean; // Whether to auto sync | 是否自动同步
  syncInterval: number; // Sync interval in seconds | 同步间隔（秒）
  conflictStrategy: ConflictResolutionStrategy; // Conflict resolution strategy | 冲突解决策略
  syncTypes: SyncDataType[]; // Types of data to sync | 需要同步的数据类型
  allowCellularSync: boolean; // Whether to allow sync over cellular | 是否允许通过蜂窝网络同步
  showSyncNotifications: boolean; // Whether to show sync notifications | 是否显示同步通知
}

// Default sync configuration | 默认同步配置
const DEFAULT_SYNC_CONFIG: SyncConfig = {
  enabled: true,
  autoSync: true,
  syncInterval: 300, // 5 minutes | 5分钟
  conflictStrategy: ConflictResolutionStrategy.LATEST_WIN,
  syncTypes: [SyncDataType.HISTORY, SyncDataType.FAVORITES],
  allowCellularSync: false,
  showSyncNotifications: true
};

// Sync state interface | 同步状态接口
export interface SyncState {
  status: SyncStatus; // Current sync status | 当前同步状态
  lastSyncTime?: number; // Last sync timestamp | 上次同步时间戳
  lastSyncResult?: boolean; // Last sync result | 上次同步结果
  error?: string; // Error message if sync failed | 同步失败的错误信息
  conflictCount?: number; // Number of conflicts | 冲突数量
  syncedDevices?: string[]; // List of synced devices | 已同步设备列表
  syncDataSize?: number; // Size of synced data | 同步数据大小
}

// Sync data interface | 同步数据接口
export interface SyncData<T = unknown> {
  data: T; // Sync data | 同步数据
  timestamp: number; // Timestamp | 时间戳
  deviceId: string; // Device ID | 设备ID
}

// Distributed data change listener type | 分布式数据变更监听器类型
type DataChangeListener = <T = unknown>(key: string, data: T, deviceId: string) => void;

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
   * Get singleton instance | 获取单例实例
   * @returns ModernDistributedDataService instance | ModernDistributedDataService实例
   */
  static getInstance(): ModernDistributedDataService {
    if (!ModernDistributedDataService.instance) {
      ModernDistributedDataService.instance = new ModernDistributedDataService();
    }
    return ModernDistributedDataService.instance;
  }

  /**
   * Constructor | 构造函数
   */
  constructor() {
    this.configService = ConfigService.getInstance();
  }

  /**
   * Set application context | 设置应用上下文
   * @param ctx Application context | 应用上下文
   */
  public setContext(ctx: common.Context): void {
    this.context = ctx;
  }

  /**
   * Get application context | 获取应用上下文
   * @returns Application context | 应用上下文
   */
  private getContext(): common.Context {
    if (!this.context) {
      throw new Error('ModernDistributedDataService context not set. Please call setContext() first.');
    }
    return this.context;
  }

  /**
   * Initialize distributed data service | 初始化分布式数据服务
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Modern distributed data service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing modern distributed data service...');

      // Create KVManager | 创建KVManager
      const kvManagerConfig: distributedKVStore.KVManagerConfig = {
        context: this.getContext(),
        bundleName: 'com.example.raytv'
      };

      this.kvManager = distributedKVStore.createKVManager(kvManagerConfig);
      if (!this.kvManager) {
        throw new Error('Failed to create KVManager instance');
      }

      // Create KVStore | 创建KVStore
      const options: distributedKVStore.Options = {
        createIfMissing: true, // Create store if missing | 如果不存在则创建
        encrypt: false, // No encryption | 不加密
        backup: false, // No backup | 不备份
        autoSync: true, // Enable auto sync | 启用自动同步
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION, // Single version store | 单版本存储
        securityLevel: distributedKVStore.SecurityLevel.S1 // Security level | 安全级别
      };

      this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options);
      if (!this.kvStore) {
        throw new Error('Failed to get KVStore instance');
      }

      // Load sync configuration | 加载同步配置
      await this.loadSyncConfig();

      // Register data change listener | 注册数据变更监听
      await this.registerDataChangeListener();

      // Start auto sync | 启动自动同步
      if (this.syncConfig.autoSync && this.syncConfig.enabled) {
        this.startAutoSync();
      }

      this.isInitialized = true;
      Logger.info(TAG, 'Modern distributed data service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize modern distributed data service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * Load sync configuration | 加载同步配置
   */
  async loadSyncConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('syncConfig');
      if (savedConfig) {
        this.syncConfig = { ...DEFAULT_SYNC_CONFIG, ...savedConfig };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load sync config: ${error}`);
    }
  }

  /**
   * Save sync configuration | 保存同步配置
   * @param config Partial sync configuration | 部分同步配置
   */
  async saveSyncConfig(config: Partial<SyncConfig>): Promise<void> {
    try {
      this.syncConfig = { ...this.syncConfig, ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig);
      
      // Adjust auto sync based on configuration | 根据配置调整自动同步
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
   * Get sync configuration | 获取同步配置
   * @returns Sync configuration | 同步配置
   */
  getSyncConfig(): SyncConfig {
    return { ...this.syncConfig };
  }

  /**
   * Register data change listener | 注册数据变更监听
   */
  async registerDataChangeListener(): Promise<void> {
    if (!this.kvStore) {
      throw new Error('KVStore not initialized');
    }

    try {
      // Use new data change listener API | 使用新的数据变更监听API
      this.kvStore.on('dataChange', (data) => {
        Logger.debug(TAG, `Data change detected: ${JSON.stringify(data)}`);
        
        if (data && data.insertEntries && data.insertEntries.length > 0) {
          data.insertEntries.forEach(entry => {
            const key = entry.key.toString();
            const deviceId = entry.deviceId || 'local';
            
            // Get data and notify listeners | 获取数据并通知监听器
            if (this.kvStore !== null && this.kvStore !== undefined) {
              this.kvStore.get(key).then((value) => {
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
              }).catch((error) => {
                Logger.error(TAG, `Failed to get changed data: ${error}`);
              });
            }
          });
        }
      });
    } catch (error) {
      Logger.error(TAG, `Failed to register data change listener: ${error}`);
    }
  }

  /**
   * Listen for data changes of specific type | 监听特定类型的数据变更
   * @param dataType Data type | 数据类型
   * @param listener Change listener | 变更监听器
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
   * Remove data change listener | 移除数据变更监听
   * @param dataType Data type | 数据类型
   * @param listener Change listener | 变更监听器
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
   * Save sync data | 保存同步数据
   * @param dataType Data type | 数据类型
   * @param key Data key | 数据键
   * @param data Data content | 数据内容
   */
  async saveSyncData<T = Serializable>(dataType: SyncDataType, key: string, data: T): Promise<void> {
    if (!this.kvStore || !this.syncConfig.enabled) {
      return;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      const syncData: SyncData<T> = {
        data,
        timestamp: Date.now(),
        deviceId: await this.getLocalDeviceId()
      };

      await this.kvStore.put(fullKey, syncData);
      Logger.debug(TAG, `Saved sync data: ${fullKey}`);
    } catch (error) {
      Logger.error(TAG, `Failed to save sync data: ${error}`);
      throw error;
    }
  }

  /**
   * Get sync data | 获取同步数据
   * @param dataType Data type | 数据类型
   * @param key Data key | 数据键
   * @returns Sync data or null if not found | 同步数据，未找到则返回null
   */
  async getSyncData<T = Serializable>(dataType: SyncDataType, key: string): Promise<T | null> {
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
    } catch (error) {
      Logger.error(TAG, `Failed to get sync data: ${error}`);
      return null;
    }
  }

  /**
   * Delete sync data | 删除同步数据
   * @param dataType Data type | 数据类型
   * @param key Data key | 数据键
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
   * Get local device ID | 获取本地设备ID
   * @returns Local device ID | 本地设备ID
   */
  private getLocalDeviceId(): string {
    try {
      const deviceInfo = deviceManager.getLocalDeviceInfo();
      return deviceInfo.deviceId;
    } catch (error) {
      Logger.error(TAG, `Failed to get local device ID: ${error}`);
      return 'unknown';
    }
  }

  /**
   * Get available devices | 获取可用设备列表
   * @returns List of available device IDs | 可用设备ID列表
   */
  private async getAvailableDevices(): Promise<string[]> {
    try {
      const devices = await deviceManager.getAvailableDeviceList();
      this.deviceIds = devices.map(device => device.deviceId);
      return this.deviceIds;
    } catch (error) {
      Logger.error(TAG, `Failed to get available devices: ${error}`);
      return [];
    }
  }

  /**
   * Start auto sync | 启动自动同步
   */
  private startAutoSync(): void {
    this.stopAutoSync(); // First stop existing timer | 先停止现有的定时器
    this.syncTimerId = setInterval(async () => {
      try {
        await this.synchronizeData();
      } catch (error) {
        Logger.error(TAG, `Auto sync failed: ${error}`);
      }
    }, this.syncConfig.syncInterval * 1000);
    
    Logger.info(TAG, 'Auto sync started');
  }

  /**
   * Stop auto sync | 停止自动同步
   */
  private stopAutoSync(): void {
    if (this.syncTimerId !== null) {
      clearInterval(this.syncTimerId);
      this.syncTimerId = null;
      Logger.info(TAG, 'Auto sync stopped');
    }
  }

  /**
   * Manually trigger data synchronization | 手动触发数据同步
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
      
      // Get online device list | 获取在线设备列表
      const devices = await this.getAvailableDevices();
      Logger.debug(TAG, `Available devices: ${JSON.stringify(devices)}`);
      
      // Sync each data type | 同步每种数据类型
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
        error: String(error)
      };
      throw error;
    }
  }

  /**
   * Sync specific data type | 同步特定数据类型
   * @param dataType Data type to sync | 需要同步的数据类型
   * @param deviceIds List of device IDs | 设备ID列表
   */
  private async syncDataType(dataType: SyncDataType, deviceIds: string[]): Promise<void> {
    if (!this.kvStore) {
      return;
    }

    Logger.debug(TAG, `Syncing data type: ${dataType} with ${deviceIds.length} devices`);
    const keyPrefix = `${dataType}_`;

    try {
      // Get all keys with prefix | 获取所有带前缀的键
      const keys = await this.getAllKeysWithPrefix(keyPrefix);
      Logger.debug(TAG, `Found ${keys.length} keys for data type ${dataType}`);

      for (const fullKey of keys) {
        // Get local data | 获取本地数据
        const localData = await this.kvStore.get(fullKey);
        if (!localData) continue;

        // Data will be auto-synced to other devices, no manual handling needed | 数据会自动同步到其他设备，无需手动处理
        Logger.debug(TAG, `Auto-synced ${fullKey}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to sync data type ${dataType}: ${error}`);
      throw error;
    }
  }

  /**
   * Get all keys with prefix | 获取所有带前缀的键
   * @param prefix Key prefix | 键前缀
   * @returns List of matching keys | 匹配的键列表
   */
  private async getAllKeysWithPrefix(prefix: string): Promise<string[]> {
    if (!this.kvStore) {
      return [];
    }

    try {
      const entries = await this.kvStore.getEntries('');
      return entries.filter((entry: distributedKVStore.Entry) => 
        entry.key.toString().startsWith(prefix)
      ).map((entry: distributedKVStore.Entry) => entry.key.toString());
    } catch (error) {
      Logger.error(TAG, `Failed to get keys with prefix ${prefix}: ${error}`);
      return [];
    }
  }

  /**
   * Get sync state | 获取同步状态
   * @returns Current sync state | 当前同步状态
   */
  getSyncState(): SyncState {
    return { ...this.syncState };
  }

  /**
   * Close distributed data service | 关闭分布式数据服务
   */
  close(): void {
    this.stopAutoSync();
    if (this.kvManager) {
      // KVStore will be automatically managed by system lifecycle, no need to manually close | KVStore会由系统生命周期自动管理，不需要手动关闭
    }
    Logger.info(TAG, 'Modern distributed data service closed');
  }
}


