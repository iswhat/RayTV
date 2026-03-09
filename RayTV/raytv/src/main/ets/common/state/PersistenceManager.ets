/**
 * 状态持久化管理 | State Persistence Manager
 * 负责应用状态的持久化和恢复
 */
import StorageUtil from '../util/StorageUtil';
import Logger from '../util/Logger';
import { AppState } from './AppState';

// 持久化配置接口 | Persistence config interface
export interface PersistenceConfig {
  /**
   * 存储键前缀 | Storage key prefix
   */
  keyPrefix: string;
  /**
   * 自动保存间隔（毫秒） | Auto save interval (ms)
   */
  autoSaveInterval: number;
  /**
   * 是否启用自动保存 | Whether to enable auto save
   */
  enableAutoSave: boolean;
  /**
   * 需要持久化的状态键 | State keys to persist
   */
  persistedKeys: string[];
}

// 状态变更监听器 | State change listener
type StateChangeListener = (key: string, value: any) => void;

/**
 * 持久化管理器类 | Persistence manager class
 */
export class PersistenceManager {
  private static instance: PersistenceManager | null = null;
  private config: PersistenceConfig;
  private listeners: Set<StateChangeListener> = new Set();
  private autoSaveTimer: number | null = null;
  private logger: Logger;
  private isInitialized: boolean = false;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): PersistenceManager {
    if (!PersistenceManager.instance) {
      PersistenceManager.instance = new PersistenceManager();
    }
    return PersistenceManager.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.logger = new Logger('PersistenceManager');
    this.config = this.getDefaultConfig();
  }

  /**
   * 获取默认配置 | Get default config
   */
  private getDefaultConfig(): PersistenceConfig {
    return {
      keyPrefix: 'raytv_state_',
      autoSaveInterval: 30000, // 30秒
      enableAutoSave: true,
      persistedKeys: [
        'user',
        'theme',
        'language',
        'favorites',
        'recentlyViewed',
        'appSettings',
        'navigationHistory'
      ]
    };
  }

  /**
   * 初始化 | Initialize
   */
  public async initialize(): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      // 这里需要传入应用上下文，实际使用时需要从外部获取
      // 暂时返回true，模拟初始化成功
      this.isInitialized = true;
      
      // 启动自动保存 | Start auto save
      if (this.config.enableAutoSave) {
        this.startAutoSave();
      }

      this.logger.info('PersistenceManager initialized successfully');
      return true;
    } catch (error) {
      this.logger.error('Failed to initialize PersistenceManager:', error);
      return false;
    }
  }

  /**
   * 启动自动保存 | Start auto save
   */
  private startAutoSave(): void {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
    }

    this.autoSaveTimer = setInterval(async () => {
      await this.saveState();
    }, this.config.autoSaveInterval) as unknown as number;

    this.logger.info(`Auto save started with interval: ${this.config.autoSaveInterval}ms`);
  }

  /**
   * 停止自动保存 | Stop auto save
   */
  public stopAutoSave(): void {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = null;
      this.logger.info('Auto save stopped');
    }
  }

  /**
   * 保存状态 | Save state
   * @param key 状态键 | State key
   * @param value 状态值 | State value
   */
  public async saveState(key?: string, value?: any): Promise<void> {
    try {
      if (key && value !== undefined) {
        // 保存单个状态 | Save single state
        const storageKey = this.getStorageKey(key);
        await this.saveValue(storageKey, value);
        this.notifyListeners(key, value);
        this.logger.info(`Saved state: ${key}`);
      } else {
        // 保存所有状态 | Save all states
        await this.saveAllStates();
      }
    } catch (error) {
      this.logger.error('Failed to save state:', error);
    }
  }

  /**
   * 保存所有状态 | Save all states
   */
  private async saveAllStates(): Promise<void> {
    const stateSnapshot = AppState.getStateSnapshot();

    for (const key of this.config.persistedKeys) {
      try {
        const value = stateSnapshot[key as keyof typeof stateSnapshot];
        if (value !== undefined) {
          const storageKey = this.getStorageKey(key);
          await this.saveValue(storageKey, value);
          this.notifyListeners(key, value);
        }
      } catch (error) {
        this.logger.error(`Failed to save state ${key}:`, error);
      }
    }

    this.logger.info('Saved all states');
  }

  /**
   * 保存值 | Save value
   * @param key 存储键 | Storage key
   * @param value 值 | Value
   */
  private async saveValue(key: string, value: any): Promise<void> {
    if (typeof value === 'string') {
      await StorageUtil.putString(key, value);
    } else if (typeof value === 'number') {
      await StorageUtil.putNumber(key, value);
    } else if (typeof value === 'boolean') {
      await StorageUtil.putBoolean(key, value);
    } else if (value === null || value === undefined) {
      await StorageUtil.remove(key);
    } else {
      // 对于对象和数组，使用JSON序列化 | For objects and arrays, use JSON serialization
      const jsonStr = JSON.stringify(value);
      await StorageUtil.putString(key, jsonStr);
    }
  }

  /**
   * 加载状态 | Load state
   * @param key 状态键 | State key
   * @returns 状态值 | State value
   */
  public async loadState(key?: string): Promise<any> {
    try {
      if (key) {
        // 加载单个状态 | Load single state
        const storageKey = this.getStorageKey(key);
        return await this.loadValue(storageKey);
      } else {
        // 加载所有状态 | Load all states
        return await this.loadAllStates();
      }
    } catch (error) {
      this.logger.error('Failed to load state:', error);
      return null;
    }
  }

  /**
   * 加载所有状态 | Load all states
   */
  private async loadAllStates(): Promise<Record<string, any>> {
    const states: Record<string, any> = {};

    for (const key of this.config.persistedKeys) {
      try {
        const storageKey = this.getStorageKey(key);
        const value = await this.loadValue(storageKey);
        if (value !== null && value !== undefined) {
          states[key] = value;
        }
      } catch (error) {
        this.logger.error(`Failed to load state ${key}:`, error);
      }
    }

    // 加载到AppState | Load to AppState
    if (Object.keys(states).length > 0) {
      AppState.loadStateSnapshot(states);
      this.logger.info('Loaded all states into AppState');
    }

    return states;
  }

  /**
   * 加载值 | Load value
   * @param key 存储键 | Storage key
   * @returns 值 | Value
   */
  private async loadValue(key: string): Promise<any> {
    try {
      // 尝试以不同类型加载 | Try to load as different types
      const stringValue = await StorageUtil.getString(key, '');
      
      if (stringValue === '') {
        return null;
      }

      // 尝试解析为JSON | Try to parse as JSON
      try {
        return JSON.parse(stringValue);
      } catch {
        // 如果不是JSON，返回原始字符串 | If not JSON, return original string
        return stringValue;
      }
    } catch (error) {
      this.logger.error(`Failed to load value for key ${key}:`, error);
      return null;
    }
  }

  /**
   * 清除状态 | Clear state
   * @param key 状态键 | State key
   */
  public async clearState(key?: string): Promise<void> {
    try {
      if (key) {
        // 清除单个状态 | Clear single state
        const storageKey = this.getStorageKey(key);
        await StorageUtil.remove(storageKey);
        this.logger.info(`Cleared state: ${key}`);
      } else {
        // 清除所有状态 | Clear all states
        for (const key of this.config.persistedKeys) {
          const storageKey = this.getStorageKey(key);
          await StorageUtil.remove(storageKey);
        }
        this.logger.info('Cleared all states');
      }
    } catch (error) {
      this.logger.error('Failed to clear state:', error);
    }
  }

  /**
   * 注册状态变更监听器 | Register state change listener
   * @param listener 监听器函数 | Listener function
   * @returns 取消注册函数 | Unregister function
   */
  public onStateChange(listener: StateChangeListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  /**
   * 通知监听器 | Notify listeners
   * @param key 状态键 | State key
   * @param value 状态值 | State value
   */
  private notifyListeners(key: string, value: any): void {
    this.listeners.forEach(listener => {
      try {
        listener(key, value);
      } catch (error) {
        this.logger.error('Error in state change listener:', error);
      }
    });
  }

  /**
   * 获取存储键 | Get storage key
   * @param key 状态键 | State key
   * @returns 存储键 | Storage key
   */
  private getStorageKey(key: string): string {
    return `${this.config.keyPrefix}${key}`;
  }

  /**
   * 更新配置 | Update config
   * @param config 配置 | Config
   */
  public updateConfig(config: Partial<PersistenceConfig>): void {
    this.config = {
      ...this.config,
      ...config
    };

    // 如果启用了自动保存，重启自动保存 | If auto save is enabled, restart auto save
    if (this.config.enableAutoSave) {
      this.startAutoSave();
    } else {
      this.stopAutoSave();
    }

    this.logger.info('PersistenceManager config updated');
  }

  /**
   * 获取配置 | Get config
   * @returns 配置 | Config
   */
  public getConfig(): PersistenceConfig {
    return { ...this.config };
  }

  /**
   * 销毁 | Destroy
   */
  public destroy(): void {
    this.stopAutoSave();
    this.listeners.clear();
    this.isInitialized = false;
    this.logger.info('PersistenceManager destroyed');
  }

  /**
   * 检查状态是否存在 | Check if state exists
   * @param key 状态键 | State key
   * @returns 是否存在 | Whether exists
   */
  public async hasState(key: string): Promise<boolean> {
    try {
      const storageKey = this.getStorageKey(key);
      return await StorageUtil.contains(storageKey);
    } catch (error) {
      this.logger.error(`Failed to check if state exists ${key}:`, error);
      return false;
    }
  }

  /**
   * 获取状态大小 | Get state size
   * @param key 状态键 | State key
   * @returns 大小（字节） | Size (bytes)
   */
  public async getStateSize(key: string): Promise<number> {
    try {
      const storageKey = this.getStorageKey(key);
      const value = await this.loadValue(storageKey);
      if (value === null || value === undefined) {
        return 0;
      }
      const jsonStr = typeof value === 'string' ? value : JSON.stringify(value);
      return new TextEncoder().encode(jsonStr).length;
    } catch (error) {
      this.logger.error(`Failed to get state size ${key}:`, error);
      return 0;
    }
  }

  /**
   * 批量保存状态 | Batch save states
   * @param states 状态对象 | State object
   */
  public async batchSaveStates(states: Record<string, any>): Promise<void> {
    try {
      for (const [key, value] of Object.entries(states)) {
        if (this.config.persistedKeys.includes(key)) {
          await this.saveState(key, value);
        }
      }
      this.logger.info(`Batch saved ${Object.keys(states).length} states`);
    } catch (error) {
      this.logger.error('Failed to batch save states:', error);
    }
  }

  /**
   * 批量加载状态 | Batch load states
   * @param keys 状态键数组 | State key array
   * @returns 状态对象 | State object
   */
  public async batchLoadStates(keys: string[]): Promise<Record<string, any>> {
    const states: Record<string, any> = {};

    try {
      for (const key of keys) {
        if (this.config.persistedKeys.includes(key)) {
          const value = await this.loadState(key);
          if (value !== null && value !== undefined) {
            states[key] = value;
          }
        }
      }
      this.logger.info(`Batch loaded ${Object.keys(states).length} states`);
    } catch (error) {
      this.logger.error('Failed to batch load states:', error);
    }

    return states;
  }
}

// 导出单例实例 | Export singleton instance
export const persistenceManager = PersistenceManager.getInstance();

export default persistenceManager;
