// ModernDistributedDataService.ets - Modern distributed data service | 现代化分布式数据服务
// Based on HarmonyOS 5.0+ distributed KVStore API to implement multi-device data synchronization | 基于HarmonyOS 5.0+分布式KVStore API实现多设备数据同步

import distributedKVStore from '@ohos.data.distributedKVStore';
// 移除deviceManager直接导入，因为需要通过上下文获取
import BusinessError from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';
import common from '@ohos.app.ability.common';


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

// Serializable type | 可序列化类型
export type Serializable = string | number | boolean | object | null;

// Sync data interface | 同步数据接口
export interface SyncData<T extends Serializable> {
  data: T; // Sync data | 同步数据
  timestamp: number; // Timestamp | 时间戳
  deviceId: string; // Device ID | 设备ID
}

// Sync item interface | 同步项接口
export interface SyncItem {
  key: string; // Item key | 项键
  value: Serializable; // Item value | 项值
}

// Distributed data change listener type | 分布式数据变更监听器类型
type DataChangeListener = <T extends Serializable>(key: string, data: T, deviceId: string) => void;

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
      console.info(TAG, '现代化分布式数据服务已初始化 | Modern distributed data service already initialized');
      return;
    }

    try {
      console.info(TAG, '正在初始化现代化分布式数据服务... | Initializing modern distributed data service...');

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
      console.info(TAG, '现代化分布式数据服务初始化成功 | Modern distributed data service initialized successfully');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG, '现代化分布式数据服务初始化失败 | Failed to initialize modern distributed data service', error instanceof Error ? error : new Error(String(error)));
      throw new Error(`现代化分布式数据服务初始化失败 | Failed to initialize modern distributed data service: ${errorMsg}`);
    }
  }

  /**
   * Load sync configuration | 加载同步配置
   */
  async loadSyncConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('syncConfig');
      if (savedConfig) {
        // 手动构建同步配置对象 | Manually construct sync config object
        this.syncConfig = this.createSyncConfig(DEFAULT_SYNC_CONFIG, savedConfig);
      }
    } catch (error) {
      console.error(TAG, '加载同步配置失败 | Failed to load sync config', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * Create sync config object | 创建同步配置对象
   */
  private createSyncConfig(base: SyncConfig, updates: Partial<SyncConfig>): SyncConfig {
    return {
      enabled: updates.enabled !== undefined ? updates.enabled : base.enabled,
      autoSync: updates.autoSync !== undefined ? updates.autoSync : base.autoSync,
      syncInterval: updates.syncInterval !== undefined ? updates.syncInterval : base.syncInterval,
      conflictStrategy: updates.conflictStrategy !== undefined ? updates.conflictStrategy : base.conflictStrategy,
      syncTypes: updates.syncTypes !== undefined ? updates.syncTypes : base.syncTypes,
      allowCellularSync: updates.allowCellularSync !== undefined ? updates.allowCellularSync : base.allowCellularSync,
      showSyncNotifications: updates.showSyncNotifications !== undefined ? updates.showSyncNotifications : base.showSyncNotifications
    };
  }

  /**
   * Save sync configuration | 保存同步配置
   * @param config Partial sync configuration | 部分同步配置
   */
  async saveSyncConfig(config: Partial<SyncConfig>): Promise<void> {
    try {
      this.syncConfig = this.createSyncConfig(this.syncConfig, config);
      await this.configService.setConfig('syncConfig', this.syncConfig);
      
      // Adjust auto sync based on configuration | 根据配置调整自动同步
      if (this.syncConfig.autoSync && this.syncConfig.enabled) {
        this.startAutoSync();
      } else {
        this.stopAutoSync();
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG, '保存同步配置失败 | Failed to save sync config', error instanceof Error ? error : new Error(String(error)));
      throw new Error(`保存同步配置失败 | Failed to save sync config: ${errorMsg}`);
    }
  }

  /**
   * Get sync configuration | 获取同步配置
   * @returns Sync configuration | 同步配置
   */
  getSyncConfig(): SyncConfig {
    // 手动复制同步配置对象 | Manually copy sync config object
    return {
      enabled: this.syncConfig.enabled,
      autoSync: this.syncConfig.autoSync,
      syncInterval: this.syncConfig.syncInterval,
      conflictStrategy: this.syncConfig.conflictStrategy,
      syncTypes: this.syncConfig.syncTypes,
      allowCellularSync: this.syncConfig.allowCellularSync,
      showSyncNotifications: this.syncConfig.showSyncNotifications
    };
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
        console.debug(TAG, `检测到数据变更: ${JSON.stringify(data)} | Data change detected: ${JSON.stringify(data)}`);
        
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
                      console.error(TAG, '数据监听器出错 | Error in data listener', error instanceof Error ? error : new Error(String(error)));
                    }
                  }
                }
              }).catch((error) => {
                console.error(TAG, '获取变更数据失败 | Failed to get changed data', error instanceof Error ? error : new Error(String(error)));
              });
            }
          });
        }
      });
    } catch (error) {
      console.error(TAG, '注册数据变更监听器失败 | Failed to register data change listener', error instanceof Error ? error : new Error(String(error)));
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
    console.debug(TAG, `已添加数据变更监听器，类型: ${dataType} | Added data change listener for ${dataType}`);
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
  async saveSyncData<T extends Serializable>(dataType: SyncDataType, key: string, data: T): Promise<void> {
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
      console.debug(TAG, `已保存同步数据: ${fullKey} | Saved sync data: ${fullKey}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG, '保存同步数据失败 | Failed to save sync data', error instanceof Error ? error : new Error(String(error)));
      throw new Error(`保存同步数据失败 | Failed to save sync data: ${errorMsg}`);
    }
  }

  /**
   * Get sync data | 获取同步数据
   * @param dataType Data type | 数据类型
   * @param key Data key | 数据键
   * @returns Sync data or null if not found | 同步数据，未找到则返回null
   */
  async getSyncData<T extends Serializable>(dataType: SyncDataType, key: string): Promise<T | null> {
    if (!this.kvStore) {
      return null;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      const value = await this.kvStore.get(fullKey) as SyncData<T> | undefined;

      if (value && typeof value === 'object' && value.data !== undefined) {
        console.debug(TAG, `已获取同步数据: ${fullKey} | Retrieved sync data: ${fullKey}`);
        return value.data;
      }
      
      return null;
    } catch (error) {
      console.error(TAG, '获取同步数据失败 | Failed to get sync data', error instanceof Error ? error : new Error(String(error)));
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
      console.debug(TAG, `已删除同步数据: ${fullKey} | Deleted sync data: ${fullKey}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG, '删除同步数据失败 | Failed to delete sync data', error instanceof Error ? error : new Error(String(error)));
      throw new Error(`删除同步数据失败 | Failed to delete sync data: ${errorMsg}`);
    }
  }

  /**
   * Get all sync data by type | 获取特定类型的所有同步数据
   * @param dataType Data type | 数据类型
   * @returns All sync data of the specified type | 指定类型的所有同步数据
   */
  async getAllDataByType(dataType: string): Promise<SyncItem[]> {
    if (!this.kvStore) {
      return [];
    }

    try {
      const prefix = `${dataType}_`;
      const entries = await this.kvStore.getEntries('');
      const result: SyncItem[] = [];

      for (const entry of entries) {
        const key = entry.key.toString();
        if (key.startsWith(prefix)) {
          const syncData = entry.value as SyncData<Serializable>;
          if (syncData && typeof syncData === 'object' && syncData.data !== undefined) {
            const actualKey = key.substring(prefix.length);
            result.push({
              key: actualKey,
              value: syncData.data
            });
          }
        }
      }

      console.debug(TAG, `已获取类型为 ${dataType} 的所有同步数据，共 ${result.length} 项 | Retrieved all sync data of type ${dataType}, total ${result.length} items`);
      return result;
    } catch (error) {
      console.error(TAG, `获取特定类型的所有同步数据失败 | Failed to get all sync data by type`, error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * Get local device ID | 获取本地设备ID
   * @returns Local device ID | 本地设备ID
   */
  private getLocalDeviceId(): string {
    try {
      // 使用固定的本地设备ID，因为deviceManager需要上下文才能正确获取
      return 'local_device';
    } catch (error) {
      console.error(TAG, '获取本地设备ID失败 | Failed to get local device ID', error instanceof Error ? error : new Error(String(error)));
      return 'unknown';
    }
  }

  /**
   * Get available devices | 获取可用设备列表
   * @returns List of available device IDs | 可用设备ID列表
   */
  private async getAvailableDevices(): Promise<string[]> {
    try {
      // 简化实现，返回空数组，因为deviceManager需要上下文才能正确获取
      this.deviceIds = [];
      return this.deviceIds;
    } catch (error) {
      console.error(TAG, '获取可用设备失败 | Failed to get available devices', error instanceof Error ? error : new Error(String(error)));
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
        console.error(TAG, '自动同步失败 | Auto sync failed', error instanceof Error ? error : new Error(String(error)));
      }
    }, this.syncConfig.syncInterval * 1000);
    
    console.info(TAG, '自动同步已启动 | Auto sync started');
  }

  /**
   * Stop auto sync | 停止自动同步
   */
  private stopAutoSync(): void {
    if (this.syncTimerId !== null) {
      clearInterval(this.syncTimerId);
      this.syncTimerId = null;
      console.info(TAG, '自动同步已停止 | Auto sync stopped');
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
      console.info(TAG, '正在开始数据同步... | Starting data synchronization...');
      
      // Get online device list | 获取在线设备列表
      const devices = await this.getAvailableDevices();
      console.debug(TAG, `可用设备: ${JSON.stringify(devices)} | Available devices: ${JSON.stringify(devices)}`);
      
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
      
      console.info(TAG, '数据同步成功完成 | Data synchronization completed successfully');
    } catch (error) {
      console.error(TAG, '数据同步失败 | Data synchronization failed', error instanceof Error ? error : new Error(String(error)));
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

    console.debug(TAG, `正在同步数据类型: ${dataType}，设备数量: ${deviceIds.length} | Syncing data type: ${dataType} with ${deviceIds.length} devices`);
    const keyPrefix = `${dataType}_`;

    try {
      // Get all keys with prefix | 获取所有带前缀的键
      const keys = await this.getAllKeysWithPrefix(keyPrefix);
      console.debug(TAG, `找到 ${keys.length} 个键，数据类型: ${dataType} | Found ${keys.length} keys for data type ${dataType}`);

      for (const fullKey of keys) {
        // Get local data | 获取本地数据
        const localData = await this.kvStore.get(fullKey) as SyncData<Serializable> | null;
        if (!localData) continue;

        // Data will be auto-synced to other devices, no manual handling needed | 数据会自动同步到其他设备，无需手动处理
        console.debug(TAG, `已自动同步: ${fullKey} | Auto-synced ${fullKey}`);
      }
    } catch (error) {
      console.error(TAG, `同步数据类型 ${dataType} 失败 | Failed to sync data type ${dataType}`, error instanceof Error ? error : new Error(String(error)));
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
      console.error(TAG, `获取带前缀 ${prefix} 的键失败 | Failed to get keys with prefix ${prefix}`, error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * Get sync state | 获取同步状态
   * @returns Current sync state | 当前同步状态
   */
  getSyncState(): SyncState {
    // 手动复制同步状态对象 | Manually copy sync state object
    return {
      status: this.syncState.status,
      lastSyncTime: this.syncState.lastSyncTime,
      lastSyncResult: this.syncState.lastSyncResult,
      error: this.syncState.error,
      conflictCount: this.syncState.conflictCount,
      syncedDevices: this.syncState.syncedDevices,
      syncDataSize: this.syncState.syncDataSize
    };
  }

  /**
   * Close distributed data service | 关闭分布式数据服务
   */
  close(): void {
    this.stopAutoSync();
    if (this.kvManager) {
      // KVStore will be automatically managed by system lifecycle, no need to manually close | KVStore会由系统生命周期自动管理，不需要手动关闭
    }
    console.info(TAG, '现代化分布式数据服务已关闭 | Modern distributed data service closed');
  }
}


