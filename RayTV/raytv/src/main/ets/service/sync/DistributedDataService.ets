// DistributedDataService.ets - �ֲ�ʽ���ݷ��� | Distributed data service
// ����HarmonyOS�ֲ�ʽ����ʵ�ֶ��豸����ͬ�� | Based on HarmonyOS distributed capabilities toʵ�� multi-device data synchronization


import distributedKVStore from '@ohos.data.distributedKVStore';
import BusinessError from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';
import common from '@ohos.app.ability.common';
import { SyncData, DataChangeListener } from '../../types/common';

// �������� | Constant definition
const TAG = 'DistributedDataService';
const STORE_ID = 'raytv_distributed_data';

// ����ͬ������ö�� | Data synchronization type enumeration
export enum SyncDataType {
  HISTORY = 'history',
  FAVORITES = 'favorites',
  CONFIG = 'config',
  PLAYBACK_PROGRESS = 'playback_progress',
  DEVICE_INFO = 'device_info'
}

// ͬ����ͻ�������ö�� | Synchronization conflict resolution strategy enumeration
export enum ConflictResolutionStrategy {
  LATEST_WIN = 'latest_win', // ����ʱ������� | Latest timestamp priority
  LOCAL_WIN = 'local_win',   // ������������ | Local data priority
  REMOTE_WIN = 'remote_win', // Զ���������� | Remote data priority
  MERGE = 'merge'            // �ϲ����� | Merge data
}

// ͬ��״̬ö�� | Synchronization status enumeration
export enum SyncStatus {
  IDLE = 'idle',
  SYNCHRONIZING = 'synchronizing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CONFLICT = 'conflict'
}

// ͬ�����ýӿ� | Synchronization configuration interface
export interface SyncConfig {
  enabled: boolean;
  autoSync: boolean;
  syncInterval: number; // �� | Seconds
  conflictStrategy: ConflictResolutionStrategy;
  syncTypes: SyncDataType[];
  allowCellularSync: boolean;
  showSyncNotifications: boolean;
}

// Ĭ��ͬ������ | Default synchronization configuration
const DEFAULT_SYNC_CONFIG: SyncConfig = {
  enabled: true,
  autoSync: true,
  syncInterval: 300, // 5���� | 5 minutes
  conflictStrategy: ConflictResolutionStrategy.LATEST_WIN,
  syncTypes: [SyncDataType.HISTORY, SyncDataType.FAVORITES],
  allowCellularSync: false,
  showSyncNotifications: true
};

// ͬ��״̬�ӿ� | Synchronization status interface
export interface SyncState {
  status: SyncStatus;
  lastSyncTime?: number;
  lastSyncResult?: boolean;
  error?: string;
  conflictCount?: number;
  syncedDevices?: string[];
  syncDataSize?: number;
}

// �ֲ�ʽ���ݷ����� | Distributed data service class
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
   * ��ȡ����ʵ�� | Get singleton instance
   */
  static getInstance(): DistributedDataService {
    if (!DistributedDataService.instance) {
      DistributedDataService.instance = new DistributedDataService();
    }
    return DistributedDataService.instance;
  }

  /**
   * ���캯�� | Constructor
   */
  constructor() {
    this.configService = ConfigService.getInstance();
  }

  /**
   * ��ʼ���ֲ�ʽ���ݷ��� | Initialize distributed data service
   * @param context Ӧ�������� | Application context
   */
  async initialize(context: common.Context): Promise<void> {
    if (this.isInitialized) {
      console.info(TAG, 'Distributed data service already initialized');
      return;
    }

    this.context = context;

    try {
      console.info(TAG, 'Initializing distributed data service...');

      // ����KVManager
      const managerConfig: distributedKVStore.KVManagerConfig = {
        context: context,
        bundleName: 'com.example.raytv'
      };
      
      try {
        this.kvManager = await distributedKVStore.createKVManager(managerConfig);
      } catch (error) {
        console.error(TAG, `Failed to create KVManager: ${JSON.stringify(error)}`);
        throw new Error(`KVManager creation failed: ${error instanceof Error ? error.message : String(error)}`);
      }

      if (!this.kvManager) {
        throw new Error('Failed to create KVManager instance');
      }

      // ��ȡKVStore
      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      try {
        this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options);
      } catch (error) {
        console.error(TAG, `Failed to get KVStore: ${JSON.stringify(error)}`);
        throw new Error(`KVStore initialization failed: ${error instanceof Error ? error.message : String(error)}`);
      }
      
      if (!this.kvStore) {
        throw new Error('Failed to get KVStore instance');
      }

      // ����ͬ������
      await this.loadSyncConfig();

      // ע�����ݱ仯����
      await this.registerDataChangeListener();

      // �����Զ�ͬ��
      if (this.syncConfig.autoSync && this.syncConfig.enabled) {
        this.startAutoSync();
      }

      this.isInitialized = true;
      console.info(TAG, 'Distributed data service initialized successfully');
    } catch (error) {
      console.error(TAG, `Failed to initialize distributed data service: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * ����ͬ������ | Load synchronization configuration
   */
  async loadSyncConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('syncConfig', DEFAULT_SYNC_CONFIG);
      if (savedConfig) {
        this.syncConfig = { ...DEFAULT_SYNC_CONFIG, ...savedConfig };
      }
    } catch (error) {
      console.error(TAG, `Failed to load sync config: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * ����ͬ������ | Save synchronization configuration
   */
  async saveSyncConfig(config: Partial<SyncConfig>): Promise<void> {
    try {
      this.syncConfig = { ...this.syncConfig, ...config };
      await this.configService.setConfig('syncConfig', this.syncConfig);
      
      // �������õ����Զ�ͬ��
      if (this.syncConfig.autoSync && this.syncConfig.enabled) {
        this.startAutoSync();
      } else {
        this.stopAutoSync();
      }
    } catch (error) {
      console.error(TAG, `Failed to save sync config: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * ��ȡͬ������ | Get synchronization configuration
   */
  getSyncConfig(): SyncConfig {
    return { ...this.syncConfig };
  }

  /**
   * ע�����ݱ仯���� | Register data change listener
   */
  async registerDataChangeListener(): Promise<void> {
    if (!this.kvStore) {
      throw new Error('KVStore not initialized');
    }

    try {
      const subscriptionCallback = async (data: distributedKVStore.SubscribeResult) => {
        try {
          console.debug(TAG, `Data change detected: ${JSON.stringify(data)}`);
          
          if (data && data.insertEntries && data.insertEntries.length > 0) {
            for (const entry of data.insertEntries) {
              const key = entry.key;
              const deviceId = entry.deviceId || 'local';
              
              try {
                // ��ȡ���ݲ�֪ͨ������
                let value: any = null;
                if (this.kvStore) {
                  value = await this.kvStore.get(key);
                }
                if (value && this.dataListeners.size > 0) {
                  // ��������ƥ��ļ�����
                  this.notifyRelevantListeners(key, value, deviceId);
                }
              } catch (error) {
                console.error(TAG, `Failed to process changed data for key ${key}: ${error instanceof Error ? error.message : String(error)}`);
              }
            }
          }
        } catch (error) {
          console.error(TAG, `Error in data change callback: ${error instanceof Error ? error.message : String(error)}`);
        }
      };
      
      await this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, subscriptionCallback);
    } catch (error) {
      console.error(TAG, `Failed to register data change listener: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * ֪ͨ��صļ����� | Notify relevant listeners
   */
  private notifyRelevantListeners<T>(key: string, value: T, deviceId: string): void {
    for (const [prefix, listeners] of this.dataListeners.entries()) {
      if (key.startsWith(prefix)) {
        for (const listener of listeners) {
          try {
            listener(key, value, deviceId);
          } catch (error) {
            console.error(TAG, `Error in data listener for prefix ${prefix}: ${error instanceof Error ? error.message : String(error)}`);
          }
        }
      }
    }
  }

  /**
   * ����ָ�����͵����ݱ仯 | Listen for data changes of specified type
   * @param dataType �������� | Data type
   * @param listener �����ص� | Listener callback
   */
  addDataChangeListener(dataType: SyncDataType, listener: DataChangeListener): void {
    const keyPrefix = `${dataType}_`;
    
    if (!this.dataListeners.has(keyPrefix)) {
      this.dataListeners.set(keyPrefix, []);
    }
    
    this.dataListeners.get(keyPrefix)!.push(listener);
    console.debug(TAG, `Added data change listener for ${dataType}`);
  }

  /**
   * �Ƴ����ݱ仯���� | Remove data change listener
   * @param dataType �������� | Data type
   * @param listener �����ص� | Listener callback
   */
  removeDataChangeListener(dataType: SyncDataType, listener: DataChangeListener): void {
    const keyPrefix = `${dataType}_`;
    
    if (this.dataListeners.has(keyPrefix)) {
      const listeners = this.dataListeners.get(keyPrefix)!;
      const index = listeners.indexOf(listener);
      
      if (index > -1) {
        listeners.splice(index, 1);
        // ���û�м������ˣ��Ƴ����ǰ׺
        if (listeners.length === 0) {
          this.dataListeners.delete(keyPrefix);
        }
      }
    }
  }

  /**
   * ����ͬ������ | Save synchronization data
   * @param dataType �������� | Data type
   * @param key ���ݼ� | Data key
   * @param data �������� | Data content
   */
  async saveSyncData<T>(dataType: SyncDataType, key: string, data: T): Promise<void> {
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

      // �������ݵ�KVStore
      await this.kvStore.put(fullKey, syncData);
      console.debug(TAG, `Saved sync data: ${fullKey}`);
    } catch (error) {
      console.error(TAG, `Failed to save sync data for key ${key}: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * ��ȡͬ������ | Get synchronization data
   * @param dataType �������� | Data type
   * @param key ���ݼ� | Data key
   */
  async getSyncData<T>(dataType: SyncDataType, key: string): Promise<T | null> {
    if (!this.kvStore) {
      return null;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      const value = await this.kvStore.get(fullKey);

      if (value && typeof value === 'object' && 'data' in value) {
        console.debug(TAG, `Retrieved sync data: ${fullKey}`);
        return value.data;
      }
      
      return null;
    } catch (error) {
      console.error(TAG, `Failed to get sync data: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }

  /**
   * ɾ��ͬ������ | Delete synchronization data
   * @param dataType �������� | Data type
   * @param key ���ݼ� | Data key
   */
  async deleteSyncData(dataType: SyncDataType, key: string): Promise<void> {
    if (!this.kvStore || !this.syncConfig.enabled) {
      return;
    }

    try {
      const fullKey = `${dataType}_${key}`;
      await this.kvStore.delete(fullKey);
      console.debug(TAG, `Deleted sync data: ${fullKey}`);
    } catch (error) {
      console.error(TAG, `Failed to delete sync data: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * �����Զ�ͬ�� | Start auto synchronization
   */
  private startAutoSync(): void {
    this.stopAutoSync(); // ��ֹͣ���еĶ�ʱ��
    
    try {
      this.syncTimerId = setInterval(async () => {
        try {
          await this.synchronizeData();
        } catch (error) {
          console.error(TAG, `Auto sync failed: ${error instanceof Error ? error.message : String(error)}`);
        }
      }, this.syncConfig.syncInterval * 1000);
    } catch (error) {
      console.error(TAG, `Failed to start auto sync: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * ֹͣ�Զ�ͬ�� | Stop auto synchronization
   */
  private stopAutoSync(): void {
    if (this.syncTimerId !== null) {
      clearInterval(this.syncTimerId);
      this.syncTimerId = null;
      console.info(TAG, 'Auto sync stopped');
    }
  }

  /**
   * �ֶ���������ͬ�� | Manually trigger data synchronization
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
      console.info(TAG, 'Starting data synchronization...');
      
      // ��ȡ�����豸�б�
      const devices = await this.getAvailableDevices();
      console.debug(TAG, `Available devices: ${JSON.stringify(devices)}`);
      
      // ͬ��ÿ����������
      for (const dataType of this.syncConfig.syncTypes) {
        await this.syncDataType(dataType, devices);
      }
      
      this.syncState = {
        status: SyncStatus.COMPLETED,
        lastSyncTime: Date.now(),
        lastSyncResult: true,
        syncedDevices: devices
      };
      
      console.info(TAG, 'Data synchronization completed successfully');
    } catch (error) {
      console.error(TAG, `Data synchronization failed: ${error instanceof Error ? error.message : String(error)}`);
      this.syncState = {
        status: SyncStatus.FAILED,
        error: error instanceof Error ? error.message : String(error)
      };
      throw error;
    }
  }

  /**
   * ��ȡ�����豸 | Get available devices
   */
  private async getAvailableDevices(): Promise<string[]> {
    try {
      if (!this.kvManager) {
        return [];
      }
      
      const deviceInfoList = await this.kvManager.getConnectedDevicesInfo();
      this.deviceIds = deviceInfoList.map(device => device.deviceId).filter(id => id);
      return this.deviceIds;
    } catch (error) {
      console.error(TAG, `Failed to get available devices: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * ��ȡ�����豸ID | Get local device ID
   */
  private async getLocalDeviceId(): Promise<string> {
    try {
      if (!this.kvManager) {
        return 'unknown';
      }
      
      const deviceInfo = await this.kvManager.getLocalDeviceInfo();
      return deviceInfo?.deviceId || 'unknown';
    } catch (error) {
      console.error(TAG, `Failed to get local device ID: ${error instanceof Error ? error.message : String(error)}`);
      return 'unknown';
    }
  }

  /**
   * ͬ��ָ���������� | Synchronize specified data type
   */
  private async syncDataType(dataType: SyncDataType, deviceIds: string[]): Promise<void> {
    if (!this.kvStore) {
      return;
    }

    console.debug(TAG, `Syncing data type: ${dataType} with ${deviceIds.length} devices`);
    const keyPrefix = `${dataType}_`;

    try {
      // ��ȡ����ƥ��ǰ׺�ļ�
      const keys = await this.getAllKeysWithPrefix(keyPrefix);
      console.debug(TAG, `Found ${keys.length} keys for data type ${dataType}`);

      for (const fullKey of keys) {
        try {
          // ��ȡ��������
          const localData = await this.kvStore.get(fullKey);
          if (localData) {
            console.debug(TAG, `Data ${fullKey} will be automatically synced to other devices`);
          }
        } catch (error) {
          console.error(TAG, `Error processing key ${fullKey}: ${error instanceof Error ? error.message : String(error)}`);
          // ����������һ���������ж�����ͬ������
          continue;
        }
      }
    } catch (error) {
      console.error(TAG, `Failed to sync data type ${dataType}: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * ��ȡ����ƥ��ǰ׺�ļ� | Get all keys with prefix
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
    } catch (error) {
      console.error(TAG, `Failed to get keys with prefix ${prefix}: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * ����ͬ����ͻ | Handle synchronization conflict
   */
  private async resolveConflict<T>(localData: T, remoteData: T): Promise<T> {
    try {
      switch (this.syncConfig.conflictStrategy) {
        case ConflictResolutionStrategy.LOCAL_WIN:
          return localData;
        case ConflictResolutionStrategy.REMOTE_WIN:
          return remoteData;
        case ConflictResolutionStrategy.LATEST_WIN:
          const localTime = (localData as { timestamp?: number })?.timestamp || 0;
          const remoteTime = (remoteData as { timestamp?: number })?.timestamp || 0;
          return localTime >= remoteTime ? localData : remoteData;
        case ConflictResolutionStrategy.MERGE:
          // ʵ�ֺϲ�����
          return await this.mergeData(localData, remoteData);
        default:
          return localData;
      }
    } catch (error) {
      console.error(TAG, `Error resolving conflict: ${error instanceof Error ? error.message : String(error)}`);
      return localData; // ����ʱĬ�ϱ�����������
    }
  }

  /**
   * �ϲ����ݣ����ݲ�ͬ��������ʵ�����ܺϲ����ԣ� | Merge data (implement intelligent merge strategy based on different data types)
   */
  private async mergeData<T>(localData: T, remoteData: T): Promise<T> {
    // ������Ը��ݲ�ͬ����������ʵ�ֲ�ͬ�ĺϲ�����
    // ���磬������ʷ��¼���Ժϲ�ȥ�أ��������ÿ��Ի���ʱ���ѡ��
    try {
      // Ĭ��ʵ�֣�����ʹ�ñ�������
      return localData;
    } catch (error) {
      console.error(TAG, `Error merging data: ${error instanceof Error ? error.message : String(error)}`);
      return localData;
    }
  }

  /**
   * ��ȡͬ��״̬ | Get synchronization status
   */
  getSyncState(): SyncState {
    return { ...this.syncState };
  }

  /**
   * ������Դ | Clean up resources
   */
  async cleanup(): Promise<void> {
    this.stopAutoSync();
    this.dataListeners.clear();
    this.isInitialized = false;
  }
}
