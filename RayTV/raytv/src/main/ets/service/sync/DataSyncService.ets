// DataSyncService.ets - 数据同步服务
// 负责协调本地数据库、网络数据和分布式数据之间的同步

import Logger from '../../common/util/Logger';
import ConfigService from '../../service/config/ConfigService';
import ModernDistributedDataService from './ModernDistributedDataService';
import { SyncDataType } from './ModernDistributedDataService';

// 常量定义
const TAG = 'DataSyncService';

// 同步方向枚举
export enum SyncDirection {
  UPLOAD = 'upload',         // 上传（本�?>远程�?
  DOWNLOAD = 'download',     // 下载（远�?>本地�?
  BIDIRECTIONAL = 'bidirectional' // 双向同步
}

// 同步状态枚�?
export enum SyncState {
  IDLE = 'idle',
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  PARTIAL = 'partial',
  CONFLICT = 'conflict'
}

// 同步策略枚举
export enum SyncStrategy {
  TIMESTAMP_BASED = 'timestamp_based', // 基于时间�?
  VERSION_BASED = 'version_based',     // 基于版本�?
  CHECKSUM_BASED = 'checksum_based',   // 基于校验�?
  FULL_SYNC = 'full_sync'             // 全量同步
}

// 数据同步配置接口
export interface DataSyncConfig {
  enabled: boolean;               // 是否启用同步
  autoSync: boolean;              // 是否自动同步
  syncInterval: number;           // 同步间隔（秒�?
  syncStrategy: SyncStrategy;     // 同步策略
  syncDirection: SyncDirection;   // 同步方向
  syncOnStart: boolean;           // 应用启动时同�?
  syncOnNetworkChange: boolean;   // 网络变化时同�?
  syncOnAppBackground: boolean;   // 应用后台时同�?
  allowCellularSync: boolean;     // 允许蜂窝网络同步
  maxSyncRetry: number;           // 最大重试次�?
  retryInterval: number;          // 重试间隔（秒�?
  batchSize: number;              // 批量同步大小
}

// 默认数据同步配置
export const DEFAULT_DATA_SYNC_CONFIG: DataSyncConfig = {
  enabled: true,
  autoSync: true,
  syncInterval: 300, // 5分钟
  syncStrategy: SyncStrategy.TIMESTAMP_BASED,
  syncDirection: SyncDirection.BIDIRECTIONAL,
  syncOnStart: true,
  syncOnNetworkChange: true,
  syncOnAppBackground: true,
  allowCellularSync: false,
  maxSyncRetry: 3,
  retryInterval: 60, // 1分钟
  batchSize: 100
};

// 同步任务接口
export interface SyncTask {
  id: string;                     // 任务ID
  dataType: string;               // 数据类型
  direction: SyncDirection;       // 同步方向
  priority: number;               // 优先级（0-100�?
  startTime?: number;             // 开始时�?
  endTime?: number;               // 结束时间
  state: SyncState;               // 状�?
  progress: number;               // 进度�?-100�?
  totalCount?: number;            // 总数�?
  successCount?: number;          // 成功数量
  failedCount?: number;           // 失败数量
  error?: string;                 // 错误信息
  retryCount: number;             // 重试次数
}

// 通用同步实体接口
export interface SyncEntity {
  id: string;                     // 实体ID
  timestamp?: number;             // 时间�?
  version?: number;               // 版本�?
  checksum?: string;              // 校验�?
  extraData?: Record<string, unknown>; // 其他属�?
}

// 同步记录接口
export interface SyncRecord {
  id: string;                     // 记录ID
  syncTime: number;               // 同步时间
  duration: number;               // 持续时间（毫秒）
  direction: SyncDirection;       // 同步方向
  totalRecords: number;           // 总记录数
  syncedRecords: number;          // 同步成功记录�?
  failedRecords: number;          // 失败记录�?
  conflictRecords: number;        // 冲突记录�?
  networkType?: string;           // 网络类型
  batteryLevel?: number;          // 电池电量
  success: boolean;               // 是否成功
  errorMessage?: string;          // 错误信息
}

// 数据变更记录接口
export interface DataChange {
  entityId: string;               // 实体ID
  entityType: string;             // 实体类型
  operation: 'create' | 'update' | 'delete'; // 操作类型
  timestamp: number;              // 时间�?
  data?: Record<string, unknown>; // 数据内容
  version?: number;               // 版本�?
  checksum?: string;              // 校验�?
}

// 同步冲突接口
export interface SyncConflict {
  entityId: string;               // 实体ID
  entityType: string;             // 实体类型
  localData: Record<string, unknown>;                 // 本地数据
  remoteData: Record<string, unknown>;                // 远程数据
  resolved: boolean;              // 是否已解�?
  resolution?: 'local' | 'remote' | 'merged'; // 解决方式
}

// 同步监听器回调类�?
type SyncListener = (task: SyncTask) => void;

// 数据提供者接口（适配器模式）
export interface DataProvider {
  getDataType(): string;
  fetchData(params?: Record<string, unknown>): Promise<Record<string, unknown>[]>;
  saveData(data: Record<string, unknown>[]): Promise<boolean>;
  updateData(data: Record<string, unknown>[]): Promise<boolean>;
  deleteData(ids: string[]): Promise<boolean>;
  getLastSyncTime(): Promise<number>;
  setLastSyncTime(timestamp: number): Promise<void>;
  getChanges(sinceTime: number): Promise<DataChange[]>;
  getEntityById(id: string): Promise<Record<string, unknown> | null>;
  getSyncVersion(): Promise<string>;
}

// 同步事件枚举
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

// 同步事件监听回调类型
type SyncEventListener = (event: SyncEvent, data: Record<string, string | number | boolean | null>) => void;

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
   */
  public static getInstance(): DataSyncService {
    if (!DataSyncService.instance) {
      DataSyncService.instance = new DataSyncService();
    }
    return DataSyncService.instance;
  }
  
  /**
   * 获取对象的所有�?
   * 替代Object.values，兼容ArkTS语法
   */
  private getObjectValues<T extends object>(obj: T): string[] {
    const values: string[] = [];
    for (const key in obj) {
      if (Object.getOwnPropertyNames(obj).includes(key)) {
        values.push(obj[key] as string);
      }
    }
    return values;
  }

  /**
   * 构造函�?
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.distributedDataService = ModernDistributedDataService.getInstance();
  }

  /**
   * 初始化数据同步服�?
   * @param context 应用上下�?
   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Data sync service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing data sync service...');

      // 加载配置
      await this.loadConfig();
      
      // 加载同步记录
      await this.loadSyncRecords();
      
      // 如果启用了自动同步，启动定时同步
      if (this.config.autoSync && this.config.enabled) {
        this.startAutoSync();
      }
      
      // 如果启用了启动时同步，执行同�?
      if (this.config.syncOnStart && this.config.enabled) {
        this.synchronizeAll().catch(error => {
          Logger.error(TAG, `Failed to sync on start: ${error}`);
        });
      }
      
      // 注册分布式数据监�?
      this.registerDistributedDataListeners();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully' instanceof Error ? 'Data sync service initialized successfully' : new Error(String('Data sync service initialized successfully')))))));
    } catch (error: Error) {
      Logger.error(TAG, `Failed to initialize data sync service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('dataSyncConfig', DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG instanceof Error ? DEFAULT_DATA_SYNC_CONFIG : new Error(String(DEFAULT_DATA_SYNC_CONFIG)))))));
      if (savedConfig) {
        this.config = { ...DEFAULT_DATA_SYNC_CONFIG, ...savedConfig };
      }
    } catch (error: Error) {
      Logger.error(TAG, `Failed to load data sync config: ${error}`);
    }
  }

  /**
   * 保存配置
   */
  public async saveConfig(config: Partial<DataSyncConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('dataSyncConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('dataSyncConfig', this.config)))))));
      
      // 根据配置调整自动同步
      if (this.config.autoSync && this.config.enabled) {
        this.startAutoSync();
      } else {
        this.stopAutoSync();
      }
    } catch (error: Error) {
      Logger.error(TAG, `Failed to save data sync config: ${error}`);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public getConfig(): DataSyncConfig {
    return { ...this.config };
  }

  /**
   * 加载同步记录
   */
  private async loadSyncRecords(): Promise<void> {
    try {
      const records = await this.configService.getConfig<SyncRecord[]>('syncRecords', [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([])))))));
      this.syncRecords = records;
      Logger.info(TAG, `Loaded ${this.syncRecords.length} sync records`);
    } catch (error: Error) {
      Logger.error(TAG, `Failed to load sync records: ${error}`);
    }
  }

  /**
   * 保存同步记录
   */
  private async saveSyncRecords(): Promise<void> {
    try {
      // 只保留最�?00条记�?
      const recentRecords = this.syncRecords.slice(-100);
      await this.configService.setConfig('syncRecords', recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords instanceof Error ? recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords : new Error(String(recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords instanceof Error ? recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords instanceof Error ? recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords : new Error(String(recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords : new Error(String(recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords instanceof Error ? recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords : new Error(String(recentRecords instanceof Error ? recentRecords : new Error(String(recentRecords)))))));
    } catch (error: Error) {
      Logger.error(TAG, `Failed to save sync records: ${error}`);
    }
  }

  /**
   * 注册分布式数据监�?
   */
  private registerDistributedDataListeners(): void {
    // 监听所有数据类型的变化
    const syncDataTypes = this.getObjectValues(SyncDataType);
    
    syncDataTypes.forEach(dataType => {
      this.distributedDataService.addDataChangeListener(
        dataType, (key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId instanceof Error ? (key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId : new Error(String((key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId instanceof Error ? (key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId instanceof Error ? (key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId : new Error(String((key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId : new Error(String((key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId instanceof Error ? (key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId : new Error(String((key, data, deviceId instanceof Error ? (key, data, deviceId : new Error(String((key, data, deviceId))))))) => {
          // 当接收到分布式数据变化时，更新本地数�?
          this.handleRemoteDataChange(dataType, key, data, deviceId).catch(error => {
            Logger.error(TAG, `Failed to handle remote data change: ${error}`);
          });
        }
      );
    });
  }

  /**
   * 处理远程数据变化
   */
  private async handleRemoteDataChange(dataType: SyncDataType, key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string instanceof Error ? key: string, data: Record<string, unknown>, deviceId: string : new Error(String(key: string, data: Record<string, unknown>, deviceId: string))))))): Promise<void> {
    // 获取对应的本地数据提供�?
    const provider = this.dataProviders.get(dataType);
    if (!provider) {
      Logger.warn(TAG, `No data provider for type: ${dataType}`);
      return;
    }

    // 检查是否需要同�?
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
    } catch (error: Error) {
      Logger.error(TAG, `Failed to sync remote data: ${error}`);
    }
  }

  /**
   * 基于时间戳同�?
   */
  private async syncByTimestamp(provider: DataProvider, remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string instanceof Error ? remoteData: Record<string, unknown>, deviceId: string : new Error(String(remoteData: Record<string, unknown>, deviceId: string))))))): Promise<void> {
    const entityId = remoteData.id as string;
    const remoteTimestamp = (remoteData.timestamp as number) || Date.now();
    
    // 获取本地数据
    const localData = await provider.getEntityById(entityId);
    
    if (!localData) {
      // 本地不存在，直接保存
      await provider.saveData([remoteData]);
    } else {
      const localTimestamp = localData.timestamp || 0;
      
      if (remoteTimestamp > localTimestamp) {
        // 远程数据更新，覆盖本�?
        await provider.updateData([remoteData]);
      } else if (remoteTimestamp < localTimestamp) {
        // 本地数据更新，同步到远程
        if (this.config.syncDirection !== SyncDirection.DOWNLOAD) {
          await this.distributedDataService.saveSyncData(
            provider.getDataType() as SyncDataType,
            entityId,
            localData,
            deviceId
          );
        }
      } else {
        // 时间戳相同，检查是否存在冲�?
        const isConflict = this.checkConflict(localData, remoteData);
        if (isConflict) {
          await this.handleConflict(entityId, provider.getDataType(), localData, remoteData);
        }
      }
    }
  }

  /**
   * 基于版本号同�?
   */
  private async syncByVersion(provider: DataProvider, remoteData: SyncEntity, deviceId: string): Promise<void> {
    const entityId = remoteData.id as string;
    const remoteVersion = (remoteData.version as number) || 0;
    
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
            localData,
            deviceId
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
   * 基于校验和同�?
   */
  private async syncByChecksum(provider: DataProvider, remoteData: SyncEntity, deviceId: string): Promise<void> {
    const entityId = remoteData.id as string;
    
    const localData = await provider.getEntityById(entityId);
    
    if (!localData) {
      await provider.saveData([remoteData]);
    } else {
      const localChecksum = this.calculateChecksum(localData);
      const remoteChecksum = remoteData.checksum || this.calculateChecksum(remoteData);
      
      if (localChecksum !== remoteChecksum) {
        // 数据不匹配，处理冲突
        await this.handleConflict(entityId, provider.getDataType(), localData, remoteData);
      }
    }
  }

  /**
   * 检查冲�?
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
    
    // 添加到冲突队�?
    this.conflictQueue.push(conflict);
    
    // 通知冲突检测事�?
    this.notifyEvent(SyncEvent.CONFLICT_DETECTED, conflict);
    
    // 默认使用时间戳解决冲�?
    const localTimestamp = (localData.timestamp as number) || 0;
    const remoteTimestamp = (remoteData.timestamp as number) || 0;
    
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
          // 合并数据（简单实现，实际需要更复杂的合并逻辑�?
          const mergedData = this.mergeData(conflict.localData, conflict.remoteData);
          await provider.updateData([mergedData]);
          break;
      }
      
      // 通知冲突解决事件
      this.notifyEvent(SyncEvent.CONFLICT_RESOLVED, conflict);
    } catch (error: Error) {
      Logger.error(TAG, `Failed to resolve conflict: ${error}`);
    }
  }

  /**
   * 合并数据
   */
  private mergeData(localData: SyncEntity, remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity : new Error(String(remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity : new Error(String(remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity : new Error(String(remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity : new Error(String(remoteData: SyncEntity instanceof Error ? remoteData: SyncEntity : new Error(String(remoteData: SyncEntity))))))): SyncEntity {
    // 简单合并：优先保留本地数据，补充远程数据的新字�?
    const merged: Record<string, string | number | boolean | null> = { ... };
    
    // 保留更新时间�?
    const localTimestamp = (localData.timestamp as number) || 0;
    const remoteTimestamp = (remoteData.timestamp as number) || 0;
    merged.timestamp = Math.max(localTimestamp, remoteTimestamp);
    
    return merged;
  }

  /**
   * 计算校验�?
   */
  private calculateChecksum(data: SyncEntity): string {
    // 简单实现：使用JSON字符串的长度作为校验�?
    // 实际应用中应该使用更安全的哈希算�?
    const dataStr = JSON.stringify(data);
    let checksum = 0;
    for (let i = 0; i < dataStr.length; i++) {
      checksum += dataStr.charCodeAt(i);
    }
    return checksum.toString(16);
  }

  /**
   * 注册数据提供�?
   */
  public registerDataProvider(provider: DataProvider): void {
    const dataType = provider.getDataType();
    this.dataProviders.set(dataType, provider);
    
    // 初始化变更队�?
    if (!this.pendingChanges.has(dataType)) {
      this.pendingChanges.set(dataType, []);
    }
    
    Logger.info(TAG, `Registered data provider for type: ${dataType}`);
  }

  /**
   * 注销数据提供�?
   */
  public unregisterDataProvider(dataType: string): void {
    this.dataProviders.delete(dataType);
    this.pendingChanges.delete(dataType);
    Logger.info(TAG, `Unregistered data provider for type: ${dataType}`);
  }

  /**
   * 开始自动同�?
   */
  private startAutoSync(): void {
    this.stopAutoSync();
    
    this.syncTimerId = setInterval(async () => {
      try {
        this.notifyEvent(SyncEvent.AUTO_SYNC_STARTED, null);
        await this.synchronizeAll();
      } catch (error: Error) {
        Logger.error(TAG, `Auto sync failed: ${error}`);
      } finally {
        this.notifyEvent(SyncEvent.AUTO_SYNC_STOPPED, null instanceof Error ? null : new Error(String(null instanceof Error ? null instanceof Error ? null : new Error(String(null : new Error(String(null instanceof Error ? null : new Error(String(null instanceof Error ? null instanceof Error ? null : new Error(String(null instanceof Error ? null instanceof Error ? null : new Error(String(null : new Error(String(null instanceof Error ? null : new Error(String(null : new Error(String(null instanceof Error ? null : new Error(String(null instanceof Error ? null instanceof Error ? null : new Error(String(null : new Error(String(null instanceof Error ? null : new Error(String(null)))))));
      }
    }, this.config.syncInterval * 1000);
    
    Logger.info(TAG, `Auto sync started with interval: ${this.config.syncInterval}s`);
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
   * 同步所有数据类�?
   */
  public async synchronizeAll(): Promise<void> {
    if (!this.config.enabled || this.isRunning) {
      return;
    }

    this.isRunning = true;
    const startTime = Date.now();
    
    try {
      Logger.info(TAG, 'Starting full data synchronization...');
      
      // 遍历所有注册的数据提供�?
      const tasks = Array.from(this.dataProviders.keys()).map(dataType => 
        this.synchronizeDataType(dataType)
      );
      
      // 并行执行所有同步任�?
      await Promise.all(tasks);
      
      // 记录同步结果
      const duration = Date.now() - startTime;
      await this.saveSyncRecord({
        syncTime: startTime,
        duration,
        direction: this.config.syncDirection,
        totalRecords: 0, // 需要根据实际同步情况统�?
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: true
      });
      
      Logger.info(TAG, `Full data synchronization completed in ${duration}ms`);
    } catch (error: Error) {
      Logger.error(TAG, `Full data synchronization failed: ${error}`);
      
      // 记录失败的同�?
      const duration = Date.now() - startTime;
      await this.saveSyncRecord({
        syncTime: startTime, duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error instanceof Error ? duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error : new Error(String(duration,
        direction: this.config.syncDirection,
        totalRecords: 0,
        syncedRecords: 0,
        failedRecords: 0,
        conflictRecords: 0,
        success: false,
        errorMessage: String(error)))))))
      });
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * 同步特定数据类型
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
      
      // 更新任务状�?
      task.state = SyncState.COMPLETED;
      task.progress = 100;
      task.endTime = Date.now();
      
      this.notifyTaskUpdate(task);
      this.notifyEvent(SyncEvent.SYNC_COMPLETED, task);
      
    } catch (error: Error) {
      Logger.error(TAG, `Failed to sync data type ${dataType}: ${error}`);
      
      task.state = SyncState.FAILED;
      task.error = String(error);
      task.endTime = Date.now();
      
      this.notifyTaskUpdate(task);
      this.notifyEvent(SyncEvent.SYNC_FAILED, task instanceof Error ? task : new Error(String(task instanceof Error ? task instanceof Error ? task : new Error(String(task : new Error(String(task instanceof Error ? task : new Error(String(task instanceof Error ? task instanceof Error ? task : new Error(String(task instanceof Error ? task instanceof Error ? task : new Error(String(task : new Error(String(task instanceof Error ? task : new Error(String(task : new Error(String(task instanceof Error ? task : new Error(String(task instanceof Error ? task instanceof Error ? task : new Error(String(task : new Error(String(task instanceof Error ? task : new Error(String(task)))))));
      
      // 处理重试
      if (task.retryCount < this.config.maxSyncRetry) {
        task.retryCount++;
        await this.retrySync(task);
      }
    } finally {
      // 从活跃任务中移除
      setTimeout(() => {
        this.syncTasks.delete(task.id);
      }, 60000); // 1分钟后移�?
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
        await this.distributedDataService.saveSyncData(
          provider.getDataType() as SyncDataType,
          change.entityId,
          change.data
        );
        successCount++;
      } catch (error: Error) {
        Logger.error(TAG, `Failed to upload change for ${change.entityId}: ${error}`);
        failedCount++;
      }
      
      // 更新进度
      task.progress = Math.round(((i + 1) / changes.length) * 100);
      task.successCount = successCount;
      task.failedCount = failedCount;
      this.notifyTaskUpdate(task);
    }
    
    // 更新最后同步时�?
    await provider.setLastSyncTime(Date.now());
  }

  /**
   * 下载数据
   */
  private async downloadData(provider: DataProvider, task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask instanceof Error ? task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask : new Error(String(task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask instanceof Error ? task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask instanceof Error ? task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask : new Error(String(task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask : new Error(String(task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask instanceof Error ? task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask : new Error(String(task: SyncTask instanceof Error ? task: SyncTask : new Error(String(task: SyncTask))))))): Promise<void> {
    // TODO: 从分布式存储下载数据
    // 这里需要实现从分布式数据服务获取数据并保存到本地的逻辑
    Logger.debug(TAG, `Downloading data for type: ${provider.getDataType()}`);
    
    // 模拟进度更新
    for (let progress = 10; progress <= 90; progress += 10) {
      task.progress = progress;
      this.notifyTaskUpdate(task);
      // 短暂延迟模拟同步过程
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }

  /**
   * 重试同步
   */
  private async retrySync(task: SyncTask): Promise<void> {
    Logger.info(TAG, `Retrying sync task ${task.id} (attempt ${task.retryCount}/${this.config.maxSyncRetry})`);
    
    // 等待重试间隔
    await new Promise(resolve => setTimeout(resolve, this.config.retryInterval * 1000));
    
    try {
      await this.synchronizeDataType(task.dataType);
    } catch (error: Error) {
      Logger.error(TAG, `Retry failed for task ${task.id}: ${error}`);
    }
  }

  /**
   * 记录数据变更
   */
  public async recordDataChange(change: DataChange): Promise<void> {
    const { entityType } = change;
    
    if (!this.pendingChanges.has(entityType)) {
      this.pendingChanges.set(entityType, [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([])))))));
    }
    
    this.pendingChanges.get(entityType)!.push(change);
    
    // 如果启用了自动同步，可以考虑立即同步重要变更
    if (this.config.enabled && this.config.autoSync) {
      // TODO: 实现立即同步重要变更的逻辑
    }
  }

  /**
   * 保存同步记录
   */
  private async saveSyncRecord(record: Omit<SyncRecord, 'id'>): Promise<void> {
    const syncRecord: SyncRecord = {
      id: `record_${Date.now()}`,
      ...record
    };
    
    this.syncRecords.push(syncRecord);
    await this.saveSyncRecords();
  }

  /**
   * 获取同步记录
   */
  public getSyncRecords(limit: number = 20): SyncRecord[] {
    return [...this.syncRecords]
      .sort((a, b) => b.syncTime - a.syncTime)
      .slice(0, limit);
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
    return [...this.conflictQueue];
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
    for (const listener of listeners) {
      try {
        listener({ ...task });
      } catch (error: Error) {
        Logger.error(TAG, `Error in sync listener: ${error}`);
      }
    }
    
    // 通知进度事件
    this.notifyEvent(SyncEvent.SYNC_PROGRESS, task instanceof Error ? task : new Error(String(task instanceof Error ? task instanceof Error ? task : new Error(String(task : new Error(String(task instanceof Error ? task : new Error(String(task instanceof Error ? task instanceof Error ? task : new Error(String(task instanceof Error ? task instanceof Error ? task : new Error(String(task : new Error(String(task instanceof Error ? task : new Error(String(task : new Error(String(task instanceof Error ? task : new Error(String(task instanceof Error ? task instanceof Error ? task : new Error(String(task : new Error(String(task instanceof Error ? task : new Error(String(task)))))));
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
   * 通知事件
   */
  private notifyEvent(event: SyncEvent, data: Record<string, unknown> | null): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
      for (const listener of listeners) {
        try {
          listener(event, data);
        } catch (error: Error) {
          Logger.error(TAG, `Error in sync event listener: ${error}`);
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
    
    // 保存所有数�?
    this.saveSyncRecords().catch(error => {
      Logger.error(TAG, `Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}` instanceof Error ? `Error saving sync records on close: ${error}` : new Error(String(`Error saving sync records on close: ${error}`)))))));
    });

    this.isInitialized = false;
    Logger.info(TAG, 'Data sync service closed');
  }
}


