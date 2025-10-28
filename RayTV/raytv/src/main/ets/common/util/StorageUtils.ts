/**
 * 存储工具类
 * 提供本地数据存储、读取、删除等功能，支持不同存储类型
 */
import Logger from './Logger';

// 存储键前缀
const STORAGE_PREFIX = 'RayTV_';

/**
 * 存储类型枚举
 */
export enum StorageType {
  /** 内存存储（应用运行时） */
  MEMORY,
  /** 本地存储（持久化） */
  LOCAL,
  /** 会话存储（会话期间） */
  SESSION,
}

/**
 * 存储工具类
 */
export class StorageUtils {
  private static readonly TAG = 'StorageUtils';
  private static memoryStorage: Map<string, any> = new Map();
  
  /**
   * 获取带前缀的键名
   */
  private static getPrefixedKey(key: string): string {
    return `${STORAGE_PREFIX}${key}`;
  }
  
  /**
   * 设置数据到指定类型的存储
   */
  public static setItem<T>(key: string, value: T, type: StorageType = StorageType.LOCAL): boolean {
    try {
      const prefixedKey = this.getPrefixedKey(key);
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
      
      switch (type) {
        case StorageType.MEMORY:
          this.memoryStorage.set(prefixedKey, value);
          Logger.debug(this.TAG, `Set memory item: ${key}`);
          break;
        case StorageType.LOCAL:
          localStorage.setItem(prefixedKey, stringValue);
          Logger.debug(this.TAG, `Set local storage item: ${key}`);
          break;
        case StorageType.SESSION:
          sessionStorage.setItem(prefixedKey, stringValue);
          Logger.debug(this.TAG, `Set session storage item: ${key}`);
          break;
      }
      
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to set item ${key}: ${error}`);
      return false;
    }
  }
  
  /**
   * 从指定类型的存储获取数据
   */
  public static getItem<T>(key: string, type: StorageType = StorageType.LOCAL): T | null {
    try {
      const prefixedKey = this.getPrefixedKey(key);
      let value: string | T | null = null;
      
      switch (type) {
        case StorageType.MEMORY:
          value = this.memoryStorage.get(prefixedKey);
          Logger.debug(this.TAG, `Get memory item: ${key} ${value ? 'found' : 'not found'}`);
          return value !== undefined ? value as T : null;
        case StorageType.LOCAL:
          value = localStorage.getItem(prefixedKey);
          Logger.debug(this.TAG, `Get local storage item: ${key} ${value ? 'found' : 'not found'}`);
          break;
        case StorageType.SESSION:
          value = sessionStorage.getItem(prefixedKey);
          Logger.debug(this.TAG, `Get session storage item: ${key} ${value ? 'found' : 'not found'}`);
          break;
      }
      
      if (value === null) {
        return null;
      }
      
      // 尝试解析JSON
      try {
        return JSON.parse(value) as T;
      } catch {
        // 如果解析失败，返回原始字符串
        return value as unknown as T;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to get item ${key}: ${error}`);
      return null;
    }
  }
  
  /**
   * 从指定类型的存储删除数据
   */
  public static removeItem(key: string, type: StorageType = StorageType.LOCAL): boolean {
    try {
      const prefixedKey = this.getPrefixedKey(key);
      
      switch (type) {
        case StorageType.MEMORY:
          this.memoryStorage.delete(prefixedKey);
          Logger.debug(this.TAG, `Remove memory item: ${key}`);
          break;
        case StorageType.LOCAL:
          localStorage.removeItem(prefixedKey);
          Logger.debug(this.TAG, `Remove local storage item: ${key}`);
          break;
        case StorageType.SESSION:
          sessionStorage.removeItem(prefixedKey);
          Logger.debug(this.TAG, `Remove session storage item: ${key}`);
          break;
      }
      
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to remove item ${key}: ${error}`);
      return false;
    }
  }
  
  /**
   * 清空指定类型的存储
   */
  public static clear(type: StorageType = StorageType.LOCAL): boolean {
    try {
      switch (type) {
        case StorageType.MEMORY:
          this.memoryStorage.clear();
          Logger.debug(this.TAG, 'Cleared memory storage');
          break;
        case StorageType.LOCAL:
          // 只清空带前缀的键，避免影响其他应用数据
          this.clearPrefixedStorage(localStorage);
          Logger.debug(this.TAG, 'Cleared prefixed local storage');
          break;
        case StorageType.SESSION:
          // 只清空带前缀的键
          this.clearPrefixedStorage(sessionStorage);
          Logger.debug(this.TAG, 'Cleared prefixed session storage');
          break;
      }
      
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear storage: ${error}`);
      return false;
    }
  }
  
  /**
   * 清空带前缀的存储
   */
  private static clearPrefixedStorage(storage: Storage): void {
    const keysToRemove: string[] = [];
    
    // 收集所有带前缀的键
    for (let i = 0; i < storage.length; i++) {
      const key = storage.key(i);
      if (key && key.startsWith(STORAGE_PREFIX)) {
        keysToRemove.push(key);
      }
    }
    
    // 删除收集到的键
    keysToRemove.forEach(key => {
      storage.removeItem(key);
    });
  }
  
  /**
   * 获取存储中的所有键（带前缀）
   */
  public static getAllKeys(type: StorageType = StorageType.LOCAL): string[] {
    try {
      const keys: string[] = [];
      
      switch (type) {
        case StorageType.MEMORY:
          this.memoryStorage.forEach((_, key) => {
            if (key.startsWith(STORAGE_PREFIX)) {
              // 移除前缀返回原始键名
              keys.push(key.replace(STORAGE_PREFIX, ''));
            }
          });
          break;
        case StorageType.LOCAL:
          this.collectPrefixedKeys(localStorage, keys);
          break;
        case StorageType.SESSION:
          this.collectPrefixedKeys(sessionStorage, keys);
          break;
      }
      
      Logger.debug(this.TAG, `Get all keys (type: ${StorageType[type]}): ${keys.length} items`);
      return keys;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all keys: ${error}`);
      return [];
    }
  }
  
  /**
   * 收集带前缀的键
   */
  private static collectPrefixedKeys(storage: Storage, keys: string[]): void {
    for (let i = 0; i < storage.length; i++) {
      const key = storage.key(i);
      if (key && key.startsWith(STORAGE_PREFIX)) {
        // 移除前缀返回原始键名
        keys.push(key.replace(STORAGE_PREFIX, ''));
      }
    }
  }
  
  /**
   * 检查存储中是否存在指定键
   */
  public static hasItem(key: string, type: StorageType = StorageType.LOCAL): boolean {
    try {
      const prefixedKey = this.getPrefixedKey(key);
      
      switch (type) {
        case StorageType.MEMORY:
          return this.memoryStorage.has(prefixedKey);
        case StorageType.LOCAL:
          return localStorage.getItem(prefixedKey) !== null;
        case StorageType.SESSION:
          return sessionStorage.getItem(prefixedKey) !== null;
        default:
          return false;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to check item existence ${key}: ${error}`);
      return false;
    }
  }
  
  /**
   * 批量设置数据
   */
  public static setItems(items: Record<string, any>, type: StorageType = StorageType.LOCAL): boolean {
    try {
      Object.entries(items).forEach(([key, value]) => {
        this.setItem(key, value, type);
      });
      
      Logger.debug(this.TAG, `Set ${Object.keys(items).length} items in batch`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to set items in batch: ${error}`);
      return false;
    }
  }
  
  /**
   * 批量获取数据
   */
  public static getItems<T>(keys: string[], type: StorageType = StorageType.LOCAL): Record<string, T | null> {
    const result: Record<string, T | null> = {};
    
    try {
      keys.forEach(key => {
        result[key] = this.getItem<T>(key, type);
      });
      
      Logger.debug(this.TAG, `Get ${keys.length} items in batch`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get items in batch: ${error}`);
    }
    
    return result;
  }
  
  /**
   * 批量删除数据
   */
  public static removeItems(keys: string[], type: StorageType = StorageType.LOCAL): boolean {
    try {
      keys.forEach(key => {
        this.removeItem(key, type);
      });
      
      Logger.debug(this.TAG, `Remove ${keys.length} items in batch`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to remove items in batch: ${error}`);
      return false;
    }
  }
  
  /**
   * 获取存储大小（仅适用于LOCAL和SESSION类型）
   */
  public static getStorageSize(type: StorageType): number {
    try {
      let size = 0;
      const storage = type === StorageType.LOCAL ? localStorage : 
                      type === StorageType.SESSION ? sessionStorage : null;
      
      if (storage) {
        for (let i = 0; i < storage.length; i++) {
          const key = storage.key(i);
          const value = storage.getItem(key!);
          if (key && value) {
            size += key.length + value.length;
          }
        }
      } else if (type === StorageType.MEMORY) {
        // 估算内存存储大小
        this.memoryStorage.forEach((value, key) => {
          if (typeof value === 'object') {
            try {
              size += key.length + JSON.stringify(value).length;
            } catch {
              // 如果无法序列化，使用默认值
              size += key.length + 100; // 估算值
            }
          } else {
            size += key.length + String(value).length;
          }
        });
      }
      
      Logger.debug(this.TAG, `Storage size (type: ${StorageType[type]}): ${size} bytes`);
      return size;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get storage size: ${error}`);
      return 0;
    }
  }
  
  /**
   * 将内存数据持久化到本地存储
   */
  public static persistMemoryData(): boolean {
    try {
      const memoryKeys = this.getAllKeys(StorageType.MEMORY);
      
      memoryKeys.forEach(key => {
        const value = this.getItem(key, StorageType.MEMORY);
        if (value !== null) {
          this.setItem(key, value, StorageType.LOCAL);
        }
      });
      
      Logger.debug(this.TAG, `Persisted ${memoryKeys.length} memory items to local storage`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to persist memory data: ${error}`);
      return false;
    }
  }
}

export default StorageUtils;