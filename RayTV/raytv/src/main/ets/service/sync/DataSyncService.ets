// DataSyncService.ets - 数据同步服务 | Data sync service
// 负责协调本地数据库、网络数据和分布式数据之间的同步 | Responsible for coordinating synchronization between local database, network data, and distributed data


import ConfigService from '../../service/config/ConfigService';
import ModernDistributedDataService from './ModernDistributedDataService';
import { SyncDataType } from './ModernDistributedDataService';
import { Serializable } from '../../types/commonTypes';
import common from '@ohos.app.ability.common';

// 常量定义 | Constant definition
const TAG = 'DataSyncService';

// 同步方向枚举 | Sync direction enum
export enum SyncDirection {
  UPLOAD = 'upload',         // 上传（本地→远程） | Upload (local → remote)
  DOWNLOAD = 'download',     // 下载（远程→本地） | Download (remote → local)
  BIDIRECTIONAL = 'bidirectional' // 双向同步 | Bidirectional sync
}

// 同步状态枚举 | Sync state enum
export enum SyncState {
  IDLE = 'idle',
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  PARTIAL = 'partial',
  CONFLICT = 'conflict'
}

// 同步策略枚举 | Sync strategy enum
export enum SyncStrategy {
  TIMESTAMP_BASED = 'timestamp_based', // 基于时间戳 | Based on timestamp
  VERSION_BASED = 'version_based',     // 基于版本号 | Based on version
  CHECKSUM_BASED = 'checksum_based',   // 基于校验和 | Based on checksum
  FULL_SYNC = 'full_sync'             // 全量同步 | Full sync
}

// 数据同步配置接口 | Data sync config interface
export interface DataSyncConfig {
  enabled: boolean;               // 是否启用同步 | Whether to enable sync
  autoSync: boolean;              // 是否自动同步 | Whether to enable auto sync
  syncInterval: number;           // 同步间隔（秒） | Sync interval (seconds)
  syncStrategy: SyncStrategy;     // 同步策略 | Sync strategy
  syncDirection: SyncDirection;   // 同步方向 | Sync direction
  syncOnStart: boolean;           // 应用启动时同步 | Sync on app start
  syncOnNetworkChange: boolean;   // 网络变化时同步 | Sync on network change
  syncOnAppBackground: boolean;   // 应用后台时同步 | Sync on app background
  allowCellularSync: boolean;     // 允许蜂窝网络同步 | Allow cellular network sync
  maxSyncRetry: number;           // 最大重试次数 | Maximum retry count
  retryInterval: number;          // 重试间隔（秒） | Retry interval (seconds)
  batchSize: number;              // 批量同步大小 | Batch sync size
}

// 默认数据同步配置 | Default data sync config
export const DEFAULT_DATA_SYNC_CONFIG: DataSyncConfig = {
  enabled: true,
  autoSync: true,
  syncInterval: 300, // 5分钟 | 5 minutes
  syncStrategy: SyncStrategy.TIMESTAMP_BASED,
  syncDirection: SyncDirection.BIDIRECTIONAL,
  syncOnStart: true,
  syncOnNetworkChange: true,
  syncOnAppBackground: true,
  allowCellularSync: false,
  maxSyncRetry: 3,
  retryInterval: 60, // 1分钟 | 1 minute
  batchSize: 100
};

// 同步任务接口 | Sync task interface
export interface SyncTask {
  id: string;                     // 任务ID | Task ID
  dataType: string;               // 数据类型 | Data type
  direction: SyncDirection;       // 同步方向 | Sync direction
  priority: number;               // 优先级（0-100） | Priority (0-100)
  startTime?: number;             // 开始时间 | Start time
  endTime?: number;               // 结束时间 | End time
  state: SyncState;               // 状态 | State
  progress: number;               // 进度（0-100） | Progress (0-100)
  totalCount?: number;            // 总数量 | Total count
  successCount?: number;          // 成功数量 | Success count
  failedCount?: number;           // 失败数量 | Failed count
  error?: string;                 // 错误信息 | Error message
  retryCount: number;             // 重试次数 | Retry count
}

// 额外数据接口 | Extra data interface
export interface ExtraData {
  // 添加具体属性 | Add specific properties
}

// 通用同步实体接口 | Common sync entity interface
export interface SyncEntity {
  id: string;                     // 实体ID | Entity ID
  timestamp?: number;             // 时间戳 | Timestamp
  version?: number;               // 版本号 | Version
  checksum?: string;              // 校验和 | Checksum
  extraData?: ExtraData;          // 其他属性 | Other properties
  data?: Serializable;            // 数据内容 | Data content
}

// 同步记录接口 | Sync record interface
export interface SyncRecord {
  id: string;                     // 记录ID | Record ID
  syncTime: number;               // 同步时间 | Sync time
  duration: number;               // 持续时间（毫秒） | Duration (milliseconds)
  direction: SyncDirection;       // 同步方向 | Sync direction
  totalRecords: number;           // 总记录数 | Total records
  syncedRecords: number;          // 同步成功记录数 | Synced records count
  failedRecords: number;          // 失败记录数 | Failed records count
  conflictRecords: number;        // 冲突记录数 | Conflict records count
  networkType?: string;           // 网络类型 | Network type
  batteryLevel?: number;          // 电池电量 | Battery level
  success: boolean;               // 是否成功 | Whether successful
  errorMessage?: string;          // 错误信息 | Error message
}

// 数据变更记录接口 | Data change record interface
export interface DataChange {
  entityId: string;               // 实体ID | Entity ID
  entityType: string;             // 实体类型 | Entity type
  operation: 'create' | 'update' | 'delete'; // 操作类型 | Operation type
  timestamp: number;              // 时间戳 | Timestamp
  data?: SyncEntity; // 数据内容 | Data content
  version?: number;               // 版本号 | Version
  checksum?: string;              // 校验和 | Checksum
}

// 同步冲突接口 | Sync conflict interface
export interface SyncConflict {
  entityId: string;               // 实体ID | Entity ID
  entityType: string;             // 实体类型 | Entity type
  localData: SyncEntity;                 // 本地数据 | Local data
  remoteData: SyncEntity;                // 远程数据 | Remote data
  resolved: boolean;              // 是否已解决 | Whether resolved
  resolution?: 'local' | 'remote' | 'merged'; // 解决方式 | Resolution method
}

// 同步监听器回调类型 | Sync listener callback type
type SyncListener = (task: SyncTask) => void;

// 冲突解决数据接口 | Conflict resolution data interface
export interface ConflictResolutionData {
  entityId: string;
  entityType: string;
  resolved: boolean;
  resolution: string;
}

// 同步事件数据接口 | Sync event data interface
export interface SyncEventData {
  id: string;
  timestamp: number;
  // 使用Map替代索引签名 | Use Map instead of indexed signature
  additionalData?: Map<string, string | number | boolean | null>;
}

// 数据提供器接口（适配器模式） | Data provider interface (adapter pattern)
export interface DataProvider {
  getDataType(): string;
  fetchData(params?: SyncEntity): Promise<SyncEntity[]>;
  saveData(data: SyncEntity[]): Promise<boolean>;
  updateData(data: SyncEntity[]): Promise<boolean>;
  deleteData(ids: string[]): Promise<boolean>;
  getLastSyncTime(): Promise<number>;
  setLastSyncTime(timestamp: number): Promise<void>;
  getChanges(sinceTime: number): Promise<DataChange[]>;
  getEntityById(id: string): Promise<SyncEntity | null>;
  getSyncVersion(): Promise<string>;
}

// 同步事件枚举 | Sync event enum
export enum SyncEvent {
  SYNC_STARTED = 'sync_started',
  SYNC_PROGRESS = 'sync_progress',
  SYNC_COMPLETED = 'sync_completed',
  SYNC_FAILED = 'sync_failed',
  CONFLICT_DETECTED = 'conflict_detected',
  CONFLICT_RESOLVED = 'conflict_resolved',
  AUTO_SYNC_STARTED = 'auto_sync_started',
  AUTO_SYNC_STOPPED = 'auto_sync_stopped'
}

// 同步事件监听回调类型 | Sync event listener callback type
export type SyncEventListener = (event: SyncEvent, data: SyncEntity) => void;

export default class DataSyncService {
  private static instance: DataSyncService;
  private configService: ConfigService;
  private distributedDataService: ModernDistributedDataService;
  private config: DataSyncConfig = DEFAULT_DATA_SYNC_CONFIG;
  private syncTasks: Map<string, SyncTask> = new Map();
  private syncRecords: SyncRecord[] = [];
  private dataProviders: Map<string, DataProvider> = new Map();
  private conflictQueue: SyncConflict[] = [];
  private pendingChanges: Map<string, DataChange[]> = new Map();
  private syncTimerId: number | null = null;
  private listeners: Map<string, SyncListener[]> = new Map();
  private eventListeners: Map<SyncEvent, SyncEventListener[]> = new Map();
  private isInitialized: boolean = false;
  private isRunning: boolean = false;

  /**
   * 获取单例实例
   * Get singleton instance
   */
  public static getInstance(): DataSyncService {
    if (!DataSyncService.instance) {
      DataSyncService.instance = new DataSyncService();
    }
    return DataSyncService.instance;
  }
  
  /**
   * 获取对象的所有值 | Get all values of object
   * 替代Object.values，适配ArkTS语法 | Alternative to Object.values, adapted for ArkTS syntax
   */
  private getObjectValues<T extends object>(obj: T): string[] {
    const values: string[] = [];
    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      values.push(obj[key as keyof T] as string);
    }
    return values;
  }

  /**
   * 构造函数
   * Constructor
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.distributedDataService = ModernDistributedDataService.getInstance();
  }

  /**
   * 初始化数据同步服务
   * @param context 应用上下文
   * Initialize data sync service
   * @param context Application context
   */
  public async initialize(context: common.Context): Promise<void> {
    if (this.isInitialized) {
      console.info(TAG + ': Data sync service already initialized');
      return;
    }

    try {
      console.info(TAG + ': Initializing data sync service...');

      // 加载配置
      await this.loadConfig();
      
      // 加载同步记录
      await this.loadSyncRecords();
      
      // 如果启用了自动同步，启动定时同步
      if (this.config.autoSync && this.config.enabled) {
        this.startAutoSync();
      }
      
      // 如果启用了启动时同步，执行同步
      if (this.config.syncOnStart && this.config.enabled) {
        this.synchronizeAll().catch(error => {
          console.error(TAG + `: Failed to sync on start: ${error}`);
        });
      }
      
      // 注册分布式数据监听
      this.registerDistributedDataListeners();
      
      this.isInitialized = true;
      console.info(TAG + ': Data sync service initialized successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ": Failed to initialize data sync service: " + err.message);
      throw new Error("Failed to initialize data sync service: " + err.message);
    }
  }

  /**
   * 加载配置
   * Load config
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig<DataSyncConfig>('dataSyncConfig', DEFAULT_DATA_SYNC_CONFIG);
      if (savedConfig) {
        // 手动合并配置 | Manually merge config
      this.config = {
        enabled: savedConfig.enabled ?? DEFAULT_DATA_SYNC_CONFIG.enabled,
        autoSync: savedConfig.autoSync ?? DEFAULT_DATA_SYNC_CONFIG.autoSync,
        syncInterval: savedConfig.syncInterval ?? DEFAULT_DATA_SYNC_CONFIG.syncInterval,
        syncStrategy: savedConfig.syncStrategy ?? DEFAULT_DATA_SYNC_CONFIG.syncStrategy,
        syncDirection: savedConfig.syncDirection ?? DEFAULT_DATA_SYNC_CONFIG.syncDirection,
        syncOnStart: savedConfig.syncOnStart ?? DEFAULT_DATA_SYNC_CONFIG.syncOnStart,
        syncOnNetworkChange: savedConfig.syncOnNetworkChange ?? DEFAULT_DATA_SYNC_CONFIG.syncOnNetworkChange,
        syncOnAppBackground: savedConfig.syncOnAppBackground ?? DEFAULT_DATA_SYNC_CONFIG.syncOnAppBackground,
        allowCellularSync: savedConfig.allowCellularSync ?? DEFAULT_DATA_SYNC_CONFIG.allowCellularSync,
        maxSyncRetry: savedConfig.maxSyncRetry ?? DEFAULT_DATA_SYNC_CONFIG.maxSyncRetry,
        retryInterval: savedConfig.retryInterval ?? DEFAULT_DATA_SYNC_CONFIG.retryInterval,
        batchSize: savedConfig.batchSize ?? DEFAULT_DATA_SYNC_CONFIG.batchSize
      };
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to load data sync config: ${err.message}`);
    }
  }

  /**
   * 保存配置
   * Save config
   */
  public async saveConfig(config: Partial<DataSyncConfig>): Promise<void> {
    try {
      // 手动合并配置 | Manually merge config
      this.config = {
        enabled: config.enabled ?? this.config.enabled,
        autoSync: config.autoSync ?? this.config.autoSync,
        syncInterval: config.syncInterval ?? this.config.syncInterval,
        syncStrategy: config.syncStrategy ?? this.config.syncStrategy,
        syncDirection: config.syncDirection ?? this.config.syncDirection,
        syncOnStart: config.syncOnStart ?? this.config.syncOnStart,
        syncOnNetworkChange: config.syncOnNetworkChange ?? this.config.syncOnNetworkChange,
        syncOnAppBackground: config.syncOnAppBackground ?? this.config.syncOnAppBackground,
        allowCellularSync: config.allowCellularSync ?? this.config.allowCellularSync,
        maxSyncRetry: config.maxSyncRetry ?? this.config.maxSyncRetry,
        retryInterval: config.retryInterval ?? this.config.retryInterval,
        batchSize: config.batchSize ?? this.config.batchSize
      };
      await this.configService.setConfig('dataSyncConfig', this.config);
      
      // 根据配置调整自动同步
      if (this.config.autoSync && this.config.enabled) {
        this.startAutoSync();
      } else {
        this.stopAutoSync();
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ": Failed to save data sync config: " + err.message);
      throw new Error(err.message);
    }
  }

  /**
   * 获取配置
   * Get config
   */
  public getConfig(): DataSyncConfig {
    // 手动复制配置 | Manually copy config
    return {
      enabled: this.config.enabled,
      autoSync: this.config.autoSync,
      syncInterval: this.config.syncInterval,
      syncStrategy: this.config.syncStrategy,
      syncDirection: this.config.syncDirection,
      syncOnStart: this.config.syncOnStart,
      syncOnNetworkChange: this.config.syncOnNetworkChange,
      syncOnAppBackground: this.config.syncOnAppBackground,
      allowCellularSync: this.config.allowCellularSync,
      maxSyncRetry: this.config.maxSyncRetry,
      retryInterval: this.config.retryInterval,
      batchSize: this.config.batchSize
    };
  }

  /**
   * 加载同步记录
   * Load sync records
   */
  private async loadSyncRecords(): Promise<void> {
    try {
      const records = await this.configService.getConfig<SyncRecord[]>('syncRecords', []);
      this.syncRecords = records;
      console.info(TAG + `: Loaded ${this.syncRecords.length} sync records`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to load sync records: ${err.message}`);
    }
  }

  /**
   * 保存同步记录
   * Save sync records
   */
  private async saveSyncRecords(): Promise<void> {
    try {
      // 只保留最新100条记录
      const recentRecords = this.syncRecords.slice(-100);
      await this.configService.setConfig('syncRecords', recentRecords);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to save sync records: ${err.message}`);
    }
  }

  /**
   * 注册分布式数据监听器
   * Register distributed data listeners
   */
  private registerDistributedDataListeners(): void {
    // 监听所有数据类型的变化
    const syncDataTypes = [
      SyncDataType.HISTORY,
      SyncDataType.FAVORITES,
      SyncDataType.CONFIG,
      SyncDataType.PLAYBACK_PROGRESS,
      SyncDataType.DEVICE_INFO
    ];
    
    syncDataTypes.forEach(dataType => {
      this.distributedDataService.addDataChangeListener(
        dataType, (key, data, deviceId) => {
          // 当接收到分布式数据变化时，更新本地数据
          this.handleRemoteDataChange(dataType, key, data as SyncEntity, deviceId).catch(error => {
            const err = error instanceof Error ? error : new Error(String(error));
            console.error(TAG + ": Failed to handle remote data change: " + err.message);
          });
        }
      );
    });
  }

  /**
   * 处理远程数据变化
   */
  private async handleRemoteDataChange(dataType: SyncDataType, key: string, data: SyncEntity, deviceId: string): Promise<void> {
    // 获取对应的本地数据提供器
    const provider = this.dataProviders.get(dataType);
    if (!provider) {
      console.warn(TAG + `: No data provider for type: ${dataType}`);
      return;
    }

    // 检查是否需要同步
    if (!this.config.enabled) {
      return;
    }

    try {
      // 根据同步策略处理数据
      switch (this.config.syncStrategy) {
        case SyncStrategy.TIMESTAMP_BASED:
          await this.syncByTimestamp(provider, data, deviceId);
          break;
        case SyncStrategy.VERSION_BASED:
          await this.syncByVersion(provider, data, deviceId);
          break;
        case SyncStrategy.CHECKSUM_BASED:
          await this.syncByChecksum(provider, data, deviceId);
          break;
        default:
          // 直接保存数据
          await provider.saveData([data]);
          break;
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ": Failed to sync remote data: " + err.message);
    }
  }

  /**
   * 基于时间戳同步
   */
  private async syncByTimestamp(provider: DataProvider, remoteData: SyncEntity, deviceId: string): Promise<void> {
    const entityId = remoteData.id;
    const remoteTimestamp = remoteData.timestamp || Date.now();
    
    // 获取本地数据
    const localData = await provider.getEntityById(entityId);
    
    if (!localData) {
      // 本地不存在，直接保存
      await provider.saveData([remoteData]);
    } else {
      const localTimestamp = localData.timestamp || 0;
      
      if (remoteTimestamp > localTimestamp) {
        // 远程数据更新，覆盖本地
        await provider.updateData([remoteData]);
      } else if (remoteTimestamp < localTimestamp) {
        // 本地数据更新，同步到远程
        if (this.config.syncDirection !== SyncDirection.DOWNLOAD) {
          await this.distributedDataService.saveSyncData(
            provider.getDataType() as SyncDataType,
            entityId,
            localData
          );
        }
      } else {
        // 时间戳相同，检查是否存在冲突
        const isConflict = this.checkConflict(localData, remoteData);
        if (isConflict) {
          await this.handleConflict(entityId, provider.getDataType(), localData, remoteData);
        }
      }
    }
  }

  /**
   * 基于版本号同步
   */
  private async syncByVersion(provider: DataProvider, remoteData: SyncEntity, deviceId: string): Promise<void> {
    const entityId = remoteData.id;
    const remoteVersion = remoteData.version || 0;
    
    const localData = await provider.getEntityById(entityId);
    
    if (!localData) {
      await provider.saveData([remoteData]);
    } else {
      const localVersion = localData.version || 0;
      
      if (remoteVersion > localVersion) {
        await provider.updateData([remoteData]);
      } else if (remoteVersion < localVersion) {
        if (this.config.syncDirection !== SyncDirection.DOWNLOAD) {
          await this.distributedDataService.saveSyncData(
            provider.getDataType() as SyncDataType,
            entityId,
            localData
          );
        }
      } else {
        const isConflict = this.checkConflict(localData, remoteData);
        if (isConflict) {
          await this.handleConflict(entityId, provider.getDataType(), localData, remoteData);
        }
      }
    }
  }

  /**
   * 基于校验和同步
   */
  private async syncByChecksum(provider: DataProvider, remoteData: SyncEntity, deviceId: string): Promise<void> {
    const entityId = remoteData.id;
    
    const localData = await provider.getEntityById(entityId);
    
    if (!localData) {
      await provider.saveData([remoteData]);
    } else {
      const localChecksum = this.calculateChecksum(localData);
      const remoteChecksum = remoteData.checksum || this.calculateChecksum(remoteData);
      
      if (localChecksum !== remoteChecksum) {
        // 数据不一致，处理冲突
        await this.handleConflict(entityId, provider.getDataType(), localData, remoteData);
      }
    }
  }

  /**
   * 检查冲突
   */
  private checkConflict(localData: SyncEntity, remoteData: SyncEntity): boolean {
    // 简单比较：如果数据字符串表示不同，则认为有冲突
    return JSON.stringify(localData) !== JSON.stringify(remoteData);
  }

  /**
   * 处理冲突
   */
  private async handleConflict(entityId: string, entityType: string, localData: SyncEntity, remoteData: SyncEntity): Promise<void> {
    const conflict: SyncConflict = {
      entityId,
      entityType,
      localData,
      remoteData,
      resolved: false
    };
    
    // 添加到冲突队列
    this.conflictQueue.push(conflict);
    
    // 通知冲突检测事件，转换为SyncEntity类型
      const conflictData: SyncEntity = {
        id: conflict.entityId,
        // 使用时间戳作为额外信息
        timestamp: Date.now()
      };
      this.notifyEvent(SyncEvent.CONFLICT_DETECTED, conflictData);
    
    // 默认使用时间戳解决冲突
    const localTimestamp = localData.timestamp || 0;
    const remoteTimestamp = remoteData.timestamp || 0;
    
    if (localTimestamp > remoteTimestamp) {
      conflict.resolution = 'local';
    } else {
      conflict.resolution = 'remote';
    }
    
    conflict.resolved = true;
    await this.resolveConflict(conflict);
  }

  /**
   * 解决冲突
   */
  private async resolveConflict(conflict: SyncConflict): Promise<void> {
    const provider = this.dataProviders.get(conflict.entityType);
    if (!provider) {
      return;
    }
    
    try {
      switch (conflict.resolution) {
        case 'local':
          // 保留本地数据
          await provider.updateData([conflict.localData]);
          break;
        case 'remote':
          // 使用远程数据
          await provider.updateData([conflict.remoteData]);
          break;
        case 'merged':
          // 合并数据（简单实现，实际需要更复杂的合并逻辑）
          const mergedData = this.mergeData(conflict.localData, conflict.remoteData);
          await provider.updateData([mergedData]);
          break;
      }
      
      // 通知冲突解决事件，使用明确的接口类型 | Notify conflict resolved event, use explicit interface type
      const resolvedData: SyncEntity = {
        id: conflict.entityId,
        timestamp: Date.now()
      };
      this.notifyEvent(SyncEvent.CONFLICT_RESOLVED, resolvedData);
    } catch (error: Error) {
      console.error(TAG + ": Failed to resolve conflict: " + error.message);
    }
  }

  /**
   * 合并数据
   */
  private mergeData(localData: SyncEntity, remoteData: SyncEntity): SyncEntity {
    // 简单合并：优先保留本地数据，填充远程数据的空字段
    const merged: SyncEntity = {
      id: localData.id,
      timestamp: localData.timestamp,
      version: localData.version,
      checksum: localData.checksum,
      extraData: localData.extraData
    };
    
    // 保留最新时间戳
    const localTimestamp = (localData.timestamp as number) || 0;
    const remoteTimestamp = (remoteData.timestamp as number) || 0;
    merged.timestamp = Math.max(localTimestamp, remoteTimestamp);
    
    return merged;
  }

  /**
   * 计算校验和
   */
  private calculateChecksum(data: SyncEntity): string {
    // 简单实现：使用JSON字符串的长度作为校验和
    // 实际应用中应该使用更安全的哈希计算方法
    const dataStr = JSON.stringify(data);
    let checksum = 0;
    for (let i = 0; i < dataStr.length; i++) {
      checksum += dataStr.charCodeAt(i);
    }
    return checksum.toString(16);
  }

  /**
   * 注册数据提供器
   */
  public registerDataProvider(provider: DataProvider): void {
    const dataType = provider.getDataType();
    this.dataProviders.set(dataType, provider);
    
    // 初始化变更队列
    if (!this.pendingChanges.has(dataType)) {
      this.pendingChanges.set(dataType, []);
    }
    
    console.info(TAG + `: Registered data provider for type: ${dataType}`);
  }

  /**
   * 注销数据提供器
   */
  public unregisterDataProvider(dataType: string): void {
    this.dataProviders.delete(dataType);
    this.pendingChanges.delete(dataType);
    console.info(TAG + `: Unregistered data provider for type: ${dataType}`);
  }

  /**
   * 开始自动同步
   */
  private startAutoSync(): void {
    this.stopAutoSync();
    
    this.syncTimerId = setInterval(async () => {
      try {
        // 通知自动同步开始事件，使用SyncEntity类型
        this.notifyEvent(SyncEvent.AUTO_SYNC_STARTED, { id: "auto_sync", timestamp: Date.now() });
        await this.synchronizeAll();
      } catch (error: Error) {
          console.error(TAG + ": Auto sync failed: " + error.message);
        } finally {
        // 通知自动同步停止事件，使用SyncEntity类型
        this.notifyEvent(SyncEvent.AUTO_SYNC_STOPPED, { id: "auto_sync", timestamp: Date.now() });
      }
    }, this.config.syncInterval * 1000);
    
    console.info(TAG + `: Auto sync started with interval: ${this.config.syncInterval}s`);
  }

  /**
   * 停止自动同步
   */
  private stopAutoSync(): void {
    if (this.syncTimerId !== null) {
      clearInterval(this.syncTimerId);
      this.syncTimerId = null;
      console.info(TAG + ': Auto sync stopped');
    }
  }

  /**
   * 同步所有数据类型
   */
  public async synchronizeAll(): Promise<void> {
    if (!this.config.enabled || this.isRunning) {
      return;
    }

    this.isRunning = true;
    const startTime = Date.now();
    
    try {
      console.info(TAG + ': Starting full data synchronization...');
      
      // 遍历所有注册的数据提供器
      const tasks = Array.from(this.dataProviders.keys()).map(dataType => 
        this.synchronizeDataType(dataType)
      );
      
      // 串行执行所有同步任务，避免并行导致的问题
      for (let i = 0; i < tasks.length; i++) {
        await tasks[i];
      }
      
      // 记录同步结果
      const duration = Date.now() - startTime;
      await this.saveSyncRecord({
        syncTime: startTime,
        duration,
        direction: this.config.syncDirection,
        totalRecords: 0, // 需要根据实际同步情况统计
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: true
      });
      
      console.info(TAG + `: Full data synchronization completed in ${duration}ms`);
    } catch (error: Error) {
      console.error(TAG + ": Full data synchronization failed: " + error.message);
      
      // 记录失败的同步
      const duration = Date.now() - startTime;
      await this.saveSyncRecord({
        syncTime: startTime,
        duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: error.message
      });
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * 同步指定数据类型
   */
  public async synchronizeDataType(dataType: string): Promise<void> {
    const provider = this.dataProviders.get(dataType);
    if (!provider) {
      throw new Error(`No data provider registered for type: ${dataType}`);
    }

    // 创建同步任务
    const task: SyncTask = {
      id: `sync_${dataType}_${Date.now()}`,
      dataType,
      direction: this.config.syncDirection,
      priority: 50,
      state: SyncState.PENDING,
      progress: 0,
      retryCount: 0
    };
    
    this.syncTasks.set(task.id, task);
    this.notifyTaskUpdate(task);
    
    try {
      task.state = SyncState.RUNNING;
      task.startTime = Date.now();
      this.notifyTaskUpdate(task);
      
      // 执行同步
      if (this.config.syncDirection === SyncDirection.UPLOAD || 
          this.config.syncDirection === SyncDirection.BIDIRECTIONAL) {
        await this.uploadData(provider, task);
      }
      
      if (this.config.syncDirection === SyncDirection.DOWNLOAD || 
          this.config.syncDirection === SyncDirection.BIDIRECTIONAL) {
        await this.downloadData(provider, task);
      }
      
      // 更新任务状态
      task.state = SyncState.COMPLETED;
      task.progress = 100;
      task.endTime = Date.now();
      
      this.notifyTaskUpdate(task);
      // 通知同步完成事件，使用SyncEntity类型
      const completedData: SyncEntity = {
        id: task.id,
        timestamp: Date.now()
      };
      this.notifyEvent(SyncEvent.SYNC_COMPLETED, completedData);
      
    } catch (error: Error) {
      console.error(TAG + ": Failed to sync data type " + dataType + ": " + error.message);
      
      task.state = SyncState.FAILED;
      task.error = error.message;
      task.endTime = Date.now();
      
      this.notifyTaskUpdate(task);
      // 通知同步失败事件，使用SyncEntity类型
      const failedData: SyncEntity = {
        id: task.id,
        timestamp: Date.now()
      };
      this.notifyEvent(SyncEvent.SYNC_FAILED, failedData);
      
      // 处理重试
      if (task.retryCount < this.config.maxSyncRetry) {
        task.retryCount++;
        await this.retrySync(task);
      }
    } finally {
      // 从活动任务中删除
      setTimeout(() => {
        this.syncTasks.delete(task.id);
      }, 60000); // 1分钟后删除
    }
  }

  /**
   * 上传数据
   */
  private async uploadData(provider: DataProvider, task: SyncTask): Promise<void> {
    const lastSyncTime = await provider.getLastSyncTime();
    const changes = await provider.getChanges(lastSyncTime);
    
    task.totalCount = changes.length;
    this.notifyTaskUpdate(task);
    
    let successCount = 0;
    let failedCount = 0;
    
    for (let i = 0; i < changes.length; i++) {
      const change = changes[i];
      
      try {
        // 上传数据到分布式存储
        if (change.data) {
          await this.distributedDataService.saveSyncData(
            provider.getDataType() as SyncDataType,
            change.entityId,
            change.data
          );
          successCount++;
        }
      } catch (error: Error) {
        console.error(TAG + ": Failed to upload change for " + change.entityId + ": " + error.message);
        failedCount++;
      }
      
      // 更新进度
      task.progress = Math.round(((i + 1) / changes.length) * 100);
      task.successCount = successCount;
      task.failedCount = failedCount;
      this.notifyTaskUpdate(task);
    }
    
    // 更新最后同步时间
    await provider.setLastSyncTime(Date.now());
  }

  /**
   * 下载数据
   */
  private async downloadData(provider: DataProvider, task: SyncTask): Promise<void> {
    console.debug(TAG + `: Downloading data for type: ${provider.getDataType()}`);
    
    // 从分布式数据服务下载数据
    const dataType = provider.getDataType();
    
    // 1. 获取分布式存储中的数据
    const distributedData = await this.distributedDataService.getAllDataByType(dataType);
    
    // 2. 计算总数据量，用于更新进度
    const totalItems = distributedData.length;
    let processedItems = 0;
    
    // 3. 遍历下载的数据并保存到本地
    for (let i = 0; i < distributedData.length; i++) {
      const dataItem = distributedData[i];
      // 更新进度
      processedItems++;
      task.progress = Math.round((processedItems / totalItems) * 80) + 10; // 10-90%
      this.notifyTaskUpdate(task);
      
      // 4. 保存数据到本地，将SyncItem转换为SyncEntity
      const syncEntity: SyncEntity = {
        id: dataItem.key,
        data: dataItem.value
      };
      await provider.saveData([syncEntity]);
    }
  }

  /**
   * 重试同步
   */
  private async retrySync(task: SyncTask): Promise<void> {
    console.info(TAG + `: Retrying sync task ${task.id} (attempt ${task.retryCount}/${this.config.maxSyncRetry})`);
    
    // 等待重试间隔
    await new Promise(resolve => setTimeout(resolve, this.config.retryInterval * 1000));
    
    try {
      await this.synchronizeDataType(task.dataType);
    } catch (error: Error) {
      console.error(TAG + `: Retry failed for task ${task.id}: ${error.message}`);
    }
  }

  /**
   * 记录数据变更
   */
  public async recordDataChange(change: DataChange): Promise<void> {
    const entityType = change.entityType;
    
    if (!this.pendingChanges.has(entityType)) {
      this.pendingChanges.set(entityType, []);
    }
    
    this.pendingChanges.get(entityType)!.push(change);
    
    // 如果启用了自动同步，可以考虑立即同步重要变更
    if (this.config.enabled && this.config.autoSync) {
      // 实现立即同步重要变更的逻辑
      await this.syncImportantChange(change);
    }
  }
  
  /**
   * 同步重要变更
   */
  private async syncImportantChange(change: DataChange): Promise<void> {
    try {
      // 定义重要的数据类型
      const importantDataTypes = [
        'config',
        'favorites',
        'history',
        'playback_progress'
      ];
      
      // 检查是否为重要数据类型
      if (importantDataTypes.includes(change.entityType)) {
        console.info(TAG + `: Syncing important change for type: ${change.entityType}`);
        
        // 立即同步该数据类型
        await this.synchronizeDataType(change.entityType);
        
        // 从待处理变更中移除已同步的变更
        if (this.pendingChanges.has(change.entityType)) {
          const changes = this.pendingChanges.get(change.entityType)!;
          const filteredChanges = changes.filter(c => c.entityId !== change.entityId || c.timestamp !== change.timestamp);
          this.pendingChanges.set(change.entityType, filteredChanges);
        }
      }
    } catch (error: Error) {
      console.error(TAG + `: Failed to sync important change: ${error.message}`);
    }
  }

  /**
   * 保存同步记录
   */
  private async saveSyncRecord(record: Partial<SyncRecord>): Promise<void> {
    const syncRecord: SyncRecord = {
      id: "record_" + Date.now(),
      syncTime: record.syncTime || Date.now(),
      duration: record.duration || 0,
      direction: record.direction || this.config.syncDirection,
      totalRecords: record.totalRecords || 0,
      syncedRecords: record.syncedRecords || 0,
      failedRecords: record.failedRecords || 0,
      conflictRecords: record.conflictRecords || 0,
      success: record.success || false,
      errorMessage: record.errorMessage,
      networkType: record.networkType,
      batteryLevel: record.batteryLevel
    };
    
    this.syncRecords.push(syncRecord);
    await this.saveSyncRecords();
  }

  /**
   * 获取同步记录
   */
  public getSyncRecords(limit: number = 20): SyncRecord[] {
    // 手动复制数组，避免使用spread操作符
    const sortedRecords = this.syncRecords.slice().sort((a, b) => b.syncTime - a.syncTime);
    return sortedRecords.slice(0, limit);
  }

  /**
   * 获取同步任务
   */
  public getSyncTasks(): SyncTask[] {
    return Array.from(this.syncTasks.values());
  }

  /**
   * 获取冲突队列
   */
  public getConflicts(): SyncConflict[] {
    // 手动复制数组，避免使用spread操作符
    return this.conflictQueue.slice();
  }

  /**
   * 手动解决冲突
   */
  public async resolveConflictManually(conflictId: string, resolution: 'local' | 'remote' | 'merged'): Promise<void> {
    const conflict = this.conflictQueue.find(c => c.entityId === conflictId);
    if (!conflict || conflict.resolved) {
      throw new Error('Conflict not found or already resolved');
    }
    
    conflict.resolution = resolution;
    conflict.resolved = true;
    
    await this.resolveConflict(conflict);
  }

  /**
   * 通知任务更新
   */
  private notifyTaskUpdate(task: SyncTask): void {
    const listeners = this.listeners.get(task.dataType) || [];
    for (let i = 0; i < listeners.length; i++) {
      const listener = listeners[i];
      try {
        // 手动复制task对象，避免使用扩展操作符
        const taskCopy: SyncTask = {
          id: task.id,
          dataType: task.dataType,
          direction: task.direction,
          priority: task.priority,
          startTime: task.startTime,
          endTime: task.endTime,
          state: task.state,
          progress: task.progress,
          totalCount: task.totalCount,
          successCount: task.successCount,
          failedCount: task.failedCount,
          error: task.error,
          retryCount: task.retryCount
        };
        listener(taskCopy);
      } catch (error: Error) {
          console.error(TAG + ": Error in sync listener: " + error.message);
        }
    }
    
    // 通知进度事件，使用SyncEntity类型
    const progressData: SyncEntity = {
      id: task.id,
      timestamp: Date.now()
    };
    this.notifyEvent(SyncEvent.SYNC_PROGRESS, progressData);
  }

  /**
   * 添加同步监听
   */
  public addSyncListener(dataType: string, listener: SyncListener): void {
    if (!this.listeners.has(dataType)) {
      this.listeners.set(dataType, []);
    }
    
    this.listeners.get(dataType)!.push(listener);
  }

  /**
   * 移除同步监听
   */
  public removeSyncListener(dataType: string, listener: SyncListener): void {
    if (this.listeners.has(dataType)) {
      const listeners = this.listeners.get(dataType)!;
      const index = listeners.indexOf(listener);
      
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 添加同步事件监听
   */
  public addSyncEventListener(event: SyncEvent, listener: SyncEventListener): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    
    this.eventListeners.get(event)!.push(listener);
  }

  /**
   * 移除同步事件监听
   */
  public removeSyncEventListener(event: SyncEvent, listener: SyncEventListener): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
      const index = listeners.indexOf(listener);
      
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 通知事件 | Notify event
   */
  private notifyEvent(event: SyncEvent, data: SyncEntity | null): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
      // 确保data不是null，使用空对象替代
      const safeData: SyncEntity = data || { id: "", timestamp: Date.now() };
      for (let i = 0; i < listeners.length; i++) {
        const listener = listeners[i];
        try {
          listener(event, safeData);
        } catch (error: Error) {
          console.error(TAG + ": Error in sync event listener: " + error.message);
        }
      }
    }
  }

  /**
   * 关闭数据同步服务
   */
  public close(): void {
    if (!this.isInitialized) {
      return;
    }

    this.stopAutoSync();
    
    // 保存所有数据
    this.saveSyncRecords().catch(error: Error => {
      console.error(TAG + ": Error saving sync records on close: " + error.message);
    });

    this.isInitialized = false;
    console.info(TAG + ': Data sync service closed');
  }
}
