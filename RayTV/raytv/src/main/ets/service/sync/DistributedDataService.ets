// DistributedDataService.ets - 分布式数据服�?
// 基于HarmonyOS分布式能力实现多设备数据同步

import Logger from '../../common/util/Logger';
import distributedKVStore from '@ohos.data.distributedKVStore';
import BusinessError from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';
import common from '@ohos.app.ability.common';
import { SyncData, DataChangeListener } from '../../types/common';

// 常量定义
const TAG = 'DistributedDataService';
const STORE_ID = 'raytv_distributed_data';

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

// 同步状态枚�?
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
  syncInterval: number; // �?
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

// 同步状态接�?
export interface SyncState {
  status: SyncStatus;
  lastSyncTime?: number;
  lastSyncResult?: boolean;
  error?: string;
  conflictCount?: number;
  syncedDevices?: string[];
  syncDataSize?: number;
}

// 分布式数据监听回调类型已从common.d.ts导入

export default class DistributedDataService {
  static instance: DistributedDataService;
  kvManager: distributedKVStore.KVManager | null = null;
  kvStore: distributedKVStore.SingleKVStore | null = null;
  configService: ConfigService;
  syncConfig: SyncConfig = DEFAULT_SYNC_CONFIG;
  syncState: SyncState = { status: SyncStatus.IDLE };
  dataListeners: Map<string, DataChangeListener[]> = new Map();
  syncTimerId: number | null = null;
  deviceIds: string[] = [];
  isInitialized: boolean = false;
  private context: common.Context | null = null;

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
   * 构造函�?
   */
  constructor() {
  }

  /**
   * 初始化分布式数据服务
   * @param context 应用上下�?
   */
  async initialize(context: common.Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Distributed data service already initialized');
      return;
    }

    this.context = context;

    try {
      Logger.info(TAG, 'Initializing distributed data service...');

      // 创建KVManager
      const managerConfig: distributedKVStore.KVManagerConfig = {
        context: context,
        bundleName: 'com.example.raytv'
      };
      
      try {
        this.kvManager = await distributedKVStore.createKVManager(managerConfig);
      } catch (error: Error) {
        Logger.error(TAG, `Failed to create KVManager: ${JSON.stringify(error)}`);
        throw new Error(`KVManager creation failed: ${error instanceof Error ? error.message : String(error)}`);
      }

      if (!this.kvManager) {
        throw new Error('Failed to create KVManager instance');
      }

      // 获取KVStore
      const options: distributedKVStore.Options = {
        createIfMissing: true, encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options instanceof Error ? encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options : new Error(String(encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options)))))));
      } catch (error: Error) {
        Logger.error(TAG, `Failed to get KVStore: ${JSON.stringify(error)}`);
        throw new Error(`KVStore initialization failed: ${error instanceof Error ? error.message : String(error)}`);
      }
      
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
      Logger.info(TAG, 'Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully' instanceof Error ? 'Distributed data service initialized successfully' : new Error(String('Distributed data service initialized successfully')))))));
    } catch (error: Error) {
      Logger.error(TAG, `Failed to initialize distributed data service: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * 加载同步配置
   */
  async loadSyncConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('syncConfig', DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG instanceof Error ? DEFAULT_SYNC_CONFIG : new Error(String(DEFAULT_SYNC_CONFIG)))))));
      if (savedConfig) {
        this.syncConfig = { ...DEFAULT_SYNC_CONFIG, ...savedConfig };
      }
    } catch (error: Error) {
      Logger.error(TAG, `Failed to load sync config: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 保存同步配置
   */
  async saveSyncConfig(config: Partial<SyncConfig>): Promise<void> {
    try {
      this.syncConfig = { ...this.syncConfig, ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig instanceof Error ? ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig : new Error(String(...config };
      await this.configService.setConfig('syncConfig', this.syncConfig)))))));
      
      // 根据配置调整自动同步
      if (this.syncConfig.autoSync && this.syncConfig.enabled) {
        this.startAutoSync();
      } else {
        this.stopAutoSync();
      }
    } catch (error: Error) {
      Logger.error(TAG, `Failed to save sync config: ${error instanceof Error ? error.message : String(error)}`);
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
      const subscriptionCallback = async (data: distributedKVStore.SubscribeResult) => {
        try {
          Logger.debug(TAG, `Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data instanceof Error ? `Data change detected: ${JSON.stringify(data : new Error(String(`Data change detected: ${JSON.stringify(data)))))))}`);
          
          if (data && data.insertEntries && data.insertEntries.length > 0) {
            for (const entry of data.insertEntries) {
              const key = entry.key;
              const deviceId = entry.deviceId || 'local';
              
              try {
                // 获取数据并通知监听�?
                let value;
                if (this.kvStore !== null && this.kvStore !== undefined) {
                  value = await this.kvStore.get(key);
                }
                if (value && this.dataListeners.size > 0) {
                  // 查找所有匹配的监听�?
                  this.notifyRelevantListeners(key, value, deviceId);
                }
              } catch (error: Error) {
                Logger.error(TAG, `Failed to process changed data for key ${key}: ${error instanceof Error ? error.message : String(error)}`);
              }
            }
          }
        } catch (error: Error) {
          Logger.error(TAG, `Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error in data change callback: ${error instanceof Error ? error.message : String(error : new Error(String(`Error in data change callback: ${error instanceof Error ? error.message : String(error)))))))}`);
        }
      };
      
      await this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, subscriptionCallback);
    } catch (error: Error) {
      Logger.error(TAG, `Failed to register data change listener: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 通知相关的监听器
   */
  private notifyRelevantListeners<T>(key: string, value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string instanceof Error ? value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string : new Error(String(value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string instanceof Error ? value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string instanceof Error ? value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string : new Error(String(value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string : new Error(String(value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string instanceof Error ? value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string : new Error(String(value: T, deviceId: string instanceof Error ? value: T, deviceId: string : new Error(String(value: T, deviceId: string))))))): void {
    for (const [prefix, listeners] of this.dataListeners.entries()) {
      if (key.startsWith(prefix)) {
        for (const listener of listeners) {
          try {
            listener(key, value, deviceId);
          } catch (error: Error) {
            Logger.error(TAG, `Error in data listener for prefix ${prefix}: ${error instanceof Error ? error.message : String(error)}`);
          }
        }
      }
    }
  }

  /**
   * 监听特定类型的数据变�?
   * @param dataType 数据类型
   * @param listener 监听回调
   */
  addDataChangeListener(dataType: SyncDataType, listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener instanceof Error ? listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener : new Error(String(listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener instanceof Error ? listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener instanceof Error ? listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener : new Error(String(listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener : new Error(String(listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener instanceof Error ? listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener : new Error(String(listener: DataChangeListener instanceof Error ? listener: DataChangeListener : new Error(String(listener: DataChangeListener))))))): void {
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
        // 如果没有监听器了，移除这个前缀
        if (listeners.length === 0) {
          this.dataListeners.delete(keyPrefix);
        }
      }
    }
  }

  /**
   * 保存同步数据
   * @param dataType 数据类型
   * @param key 数据�?
   * @param data 数据内容
   */
  async saveSyncData<T>(dataType: SyncDataType, key: string, data: T): Promise<void> {
    if (!this.kvStore || !this.syncConfig.enabled) {
      return;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      const syncData: Record<string, string | number | boolean | null> = { ... };

      // 保存数据到KVStore
      await this.kvStore.put(fullKey, syncData);
      Logger.debug(TAG, `Saved sync data: ${fullKey}`);
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get sync data for key ${key}: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * 获取同步数据
   * @param dataType 数据类型
   * @param key 数据�?
   */
  async getSyncData<T>(dataType: SyncDataType, key: string instanceof Error ? key: string : new Error(String(key: string instanceof Error ? key: string instanceof Error ? key: string : new Error(String(key: string : new Error(String(key: string instanceof Error ? key: string : new Error(String(key: string instanceof Error ? key: string instanceof Error ? key: string : new Error(String(key: string instanceof Error ? key: string instanceof Error ? key: string : new Error(String(key: string : new Error(String(key: string instanceof Error ? key: string : new Error(String(key: string : new Error(String(key: string instanceof Error ? key: string : new Error(String(key: string instanceof Error ? key: string instanceof Error ? key: string : new Error(String(key: string : new Error(String(key: string instanceof Error ? key: string : new Error(String(key: string))))))): Promise<T | null> {
    if (!this.kvStore) {
      return null;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      const value = await this.kvStore.get(fullKey);

      if (value && typeof value === 'object' && 'data' in value) {
        Logger.debug(TAG, `Retrieved sync data: ${fullKey}`);
        return value.data;
      }
      
      return null;
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get sync data: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }

  /**
   * 删除同步数据
   * @param dataType 数据类型
   * @param key 数据�?
   */
  async deleteSyncData(dataType: SyncDataType, key: string instanceof Error ? key: string : new Error(String(key: string instanceof Error ? key: string instanceof Error ? key: string : new Error(String(key: string : new Error(String(key: string instanceof Error ? key: string : new Error(String(key: string instanceof Error ? key: string instanceof Error ? key: string : new Error(String(key: string instanceof Error ? key: string instanceof Error ? key: string : new Error(String(key: string : new Error(String(key: string instanceof Error ? key: string : new Error(String(key: string : new Error(String(key: string instanceof Error ? key: string : new Error(String(key: string instanceof Error ? key: string instanceof Error ? key: string : new Error(String(key: string : new Error(String(key: string instanceof Error ? key: string : new Error(String(key: string))))))): Promise<void> {
    if (!this.kvStore || !this.syncConfig.enabled) {
      return;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      await this.kvStore.delete(fullKey);
      Logger.debug(TAG, `Deleted sync data: ${fullKey}`);
    } catch (error: Error) {
      Logger.error(TAG, `Failed to delete sync data: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * 启动自动同步
   */
  private startAutoSync(): void {
    this.stopAutoSync(); // 先停止现有的定时�?
    
    try {
      this.syncTimerId = setInterval(async () => {
        try {
          await this.synchronizeData();
        } catch (error: Error) {
          Logger.error(TAG, `Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error instanceof Error ? `Auto sync failed: ${error instanceof Error ? error.message : String(error : new Error(String(`Auto sync failed: ${error instanceof Error ? error.message : String(error)))))))}`);
        }
      }, this.syncConfig.syncInterval * 1000);
    } catch (error: Error) {
      Logger.error(TAG, `Failed to start auto sync: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 停止自动同步
   */
  private stopAutoSync(): void {
    if (this.syncTimerId !== null) {
      clearInterval(this.syncTimerId);
      this.syncTimerId = null;
      Logger.info(TAG, 'Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped' instanceof Error ? 'Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped' : new Error(String('Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped' instanceof Error ? 'Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped' instanceof Error ? 'Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped' : new Error(String('Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped' : new Error(String('Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped' instanceof Error ? 'Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped' : new Error(String('Auto sync stopped' instanceof Error ? 'Auto sync stopped' : new Error(String('Auto sync stopped')))))));
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
      Logger.error(TAG, `Data synchronization failed: ${error instanceof Error ? error.message : String(error)}`);
      this.syncState = {
        status: SyncStatus.FAILED, error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error instanceof Error ? error: error instanceof Error ? error.message : String(error : new Error(String(error: error instanceof Error ? error.message : String(error))))))),
      };
      throw error;
    }
  }

  /**
   * 获取可用设备列表
   */
  private async getAvailableDevices(): Promise<string[]> {
    try {
      if (!this.kvManager) {
        return [];
      }
      
      const deviceInfoList = await this.kvManager.getConnectedDevicesInfo();
      this.deviceIds = deviceInfoList.map(device => device.deviceId).filter(id => id);
      return this.deviceIds;
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get available devices: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 获取本地设备ID
   */
  private async getLocalDeviceId(): Promise<string> {
    try {
      if (!this.kvManager) {
        return 'unknown';
      }
      
      const deviceInfo = await this.kvManager.getLocalDeviceInfo();
      return deviceInfo?.deviceId || 'unknown';
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to get local device ID: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to get local device ID: ${error instanceof Error ? error.message : String(error)))))))}`);
      return 'unknown';
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
        try {
          // 获取本地数据
          const localData = await this.kvStore.get(fullKey);
          if (localData) {
            Logger.debug(TAG, `Data ${fullKey} will be automatically synced to other devices`);
          }
        } catch (error: Error) {
          Logger.error(TAG, `Error processing key ${fullKey}: ${error instanceof Error ? error.message : String(error)}`);
          // 继续处理下一个键，不中断整个同步流程
          continue;
        }
      }
    } catch (error: Error) {
      Logger.error(TAG, `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error instanceof Error ? `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error : new Error(String(`Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error)))))))}`);
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
      const allEntries = await this.kvStore.getEntries('');
      const keys: string[] = [];
      
      if (Array.isArray(allEntries)) {
        for (let i = 0; i < allEntries.length; i++) {
          const entry = allEntries[i];
          if (entry && entry.key && entry.key.startsWith(prefix)) {
            keys.push(entry.key);
          }
        }
      }
      
      return keys;
    } catch (error: Error) {
      Logger.error(TAG, `Failed to get keys with prefix ${prefix}: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 处理同步冲突
   */
  private async resolveConflict<T>(localData: T, remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T))))))): Promise<T> {
    try {
      switch (this.syncConfig.conflictStrategy) {
        case ConflictResolutionStrategy.LOCAL_WIN:
          return localData;
        case ConflictResolutionStrategy.REMOTE_WIN:
          return remoteData;
        case ConflictResolutionStrategy.LATEST_WIN:
          const localTime = localData?.timestamp || 0;
          const remoteTime = remoteData?.timestamp || 0;
          return localTime >= remoteTime ? localData : remoteData;
        case ConflictResolutionStrategy.MERGE:
          // 实现合并策略
          return await this.mergeData(localData, remoteData);
        default:
          return localData;
      }
    } catch (error: Error) {
      Logger.error(TAG, `Error resolving conflict: ${error instanceof Error ? error.message : String(error)}`);
      return localData; // 出错时默认保留本地数�?
    }
  }

  /**
   * 合并数据（根据不同数据类型实现智能合并策略）
   */
  private async mergeData<T>(localData: T, remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T : new Error(String(remoteData: T instanceof Error ? remoteData: T : new Error(String(remoteData: T))))))): Promise<T> {
    try {
      // 确保输入是对�?
      if (typeof localData !== 'object' || localData === null) {
        return remoteData;
      }
      if (typeof remoteData !== 'object' || remoteData === null) {
        return localData;
      }

      // 创建合并结果对象
      const merged: Record<string, string | number | boolean | null> = { ... };
      
      // 根据数据类型实现不同的合并策�?
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
                  // 但使用最新的时间�?
                  lastWatched: Math.max(
                    remoteData[key].lastWatched || 0, 
                    localData[key].lastWatched || 0
                  )
                };
              } else {
                merged[key] = remoteData[key] || localData[key];
              }
              break;
              
            case SyncDataType.FAVORITES:
              // 收藏合并：合并两个列�?
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
                merged[key] = await this.mergeData(localData[key], remoteData[key]);
              } else {
                // 对于数组和基本类型，使用远程数据
                merged[key] = remoteData[key];
              }
        }
      }
      
      // 更新合并后的时间戳和设备ID
      merged.timestamp = Date.now();
      merged.deviceId = await this.getLocalDeviceId();
      
      return merged;
    } catch (error: Error) {
      Logger.error(TAG, `Error merging data: ${error instanceof Error ? error.message : String(error)}`);
      return localData; // 出错时默认保留本地数�?
    }
  }

  /**
   * 获取同步状�?
   */
  getSyncState(): SyncState {
    return { ...this.syncState };
  }

  /**
   * 关闭分布式数据服�?
   */
  close(): void {
    try {
      this.stopAutoSync();
      // 清理监听�?
      this.dataListeners.clear();
      // KVStore会由系统自动管理生命周期，但可以进行明确的资源释�?
      this.kvStore = null;
      this.kvManager = null;
      this.isInitialized = false;
      Logger.info(TAG, 'Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released' instanceof Error ? 'Distributed data service closed and resources released' : new Error(String('Distributed data service closed and resources released')))))));
    } catch (error: Error) {
      Logger.error(TAG, `Error closing distributed data service: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}


