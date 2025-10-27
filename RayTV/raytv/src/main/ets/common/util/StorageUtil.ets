// StorageUtil - 本地存储管理工具类
import Logger from './Logger';
import JsonUtil from './JsonUtil';
import AppConstant from '../constant/AppConstant';
import FileUtil from './FileUtil';
import preferences from '@ohos.data.preferences';

const TAG = 'StorageUtil';

/**
 * 存储类型枚举
 */
export enum StorageType {
  PREFERENCES,  // 偏好设置存储
  DATABASE,     // 数据库存储
  FILE,         // 文件存储
  MEMORY        // 内存存储
}

/**
 * 存储工具类
 * 提供多种存储方式的统一接口，包括偏好设置、文件存储等
 */
export default class StorageUtil {
  private static memoryCache: Record<string, { value: any; expireTime: number }> = {};
  private static readonly MEMORY_CACHE_CLEAN_INTERVAL = 5 * 60 * 1000; // 5分钟清理一次

  static {
    // 启动内存缓存自动清理
    this.startMemoryCacheCleanup();
  }

  /**
   * 保存数据到存储
   * @param key 键名
   * @param value 数据值
   * @param type 存储类型
   * @param expireTime 过期时间（毫秒，0表示永不过期）
   */
  public static async save(key: string, value: any, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    try {
      const dataToSave = {
        value,
        timestamp: Date.now(),
        expireTime: expireTime > 0 ? Date.now() + expireTime : 0
      };

      switch (type) {
        case StorageType.PREFERENCES:
          await this.saveToPreferences(key, dataToSave);
          break;
        case StorageType.FILE:
          await this.saveToFile(key, dataToSave);
          break;
        case StorageType.MEMORY:
          this.saveToMemory(key, dataToSave);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.info(TAG, `Saved data for key: ${key}, type: ${type}`);
    } catch (error) {
      Logger.error(TAG, `Failed to save data for key ${key}: ${error}`);
      throw error;
    }
  }

  /**
   * 从存储中读取数据
   * @param key 键名
   * @param type 存储类型
   * @param defaultValue 默认值
   * @returns 读取的数据或默认值
   */
  public static async get<T = any>(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue?: T): Promise<T> {
    try {
      let data: any;

      switch (type) {
        case StorageType.PREFERENCES:
          data = await this.getFromPreferences(key);
          break;
        case StorageType.FILE:
          data = await this.getFromFile(key);
          break;
        case StorageType.MEMORY:
          data = this.getFromMemory(key);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      // 检查是否过期
      if (data && data.expireTime > 0 && Date.now() > data.expireTime) {
        Logger.warn(TAG, `Data expired for key: ${key}`);
        await this.remove(key, type);
        return defaultValue as T;
      }

      return data ? data.value as T : (defaultValue as T);
    } catch (error) {
      Logger.error(TAG, `Failed to get data for key ${key}: ${error}`);
      return defaultValue as T;
    }
  }

  /**
   * 从存储中移除数据
   * @param key 键名
   * @param type 存储类型
   */
  public static async remove(key: string, type: StorageType = StorageType.PREFERENCES): Promise<void> {
    try {
      switch (type) {
        case StorageType.PREFERENCES:
          await this.removeFromPreferences(key);
          break;
        case StorageType.FILE:
          await this.removeFromFile(key);
          break;
        case StorageType.MEMORY:
          this.removeFromMemory(key);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.info(TAG, `Removed data for key: ${key}, type: ${type}`);
    } catch (error) {
      Logger.error(TAG, `Failed to remove data for key ${key}: ${error}`);
      throw error;
    }
  }

  /**
   * 清空指定类型的所有存储数据
   * @param type 存储类型
   */
  public static async clear(type: StorageType = StorageType.PREFERENCES): Promise<void> {
    try {
      switch (type) {
        case StorageType.PREFERENCES:
          await this.clearPreferences();
          break;
        case StorageType.FILE:
          await this.clearFiles();
          break;
        case StorageType.MEMORY:
          this.clearMemory();
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.info(TAG, `Cleared all data for type: ${type}`);
    } catch (error) {
      Logger.error(TAG, `Failed to clear data for type ${type}: ${error}`);
      throw error;
    }
  }

  /**
   * 检查键是否存在
   * @param key 键名
   * @param type 存储类型
   * @returns 是否存在
   */
  public static async has(key: string, type: StorageType = StorageType.PREFERENCES): Promise<boolean> {
    try {
      let exists = false;

      switch (type) {
        case StorageType.PREFERENCES:
          exists = await this.hasInPreferences(key);
          break;
        case StorageType.FILE:
          exists = await this.hasInFile(key);
          break;
        case StorageType.MEMORY:
          exists = this.hasInMemory(key);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      return exists;
    } catch (error) {
      Logger.error(TAG, `Failed to check existence for key ${key}: ${error}`);
      return false;
    }
  }

  /**
   * 获取存储中所有的键
   * @param type 存储类型
   * @returns 键名数组
   */
  public static async getAllKeys(type: StorageType = StorageType.PREFERENCES): Promise<string[]> {
    try {
      let keys: string[] = [];

      switch (type) {
        case StorageType.PREFERENCES:
          keys = await this.getAllKeysFromPreferences();
          break;
        case StorageType.FILE:
          keys = await this.getAllKeysFromFiles();
          break;
        case StorageType.MEMORY:
          keys = Object.keys(this.memoryCache);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      return keys;
    } catch (error) {
      Logger.error(TAG, `Failed to get all keys for type ${type}: ${error}`);
      return [];
    }
  }

  // ===== Preferences 相关方法 =====
  private static async saveToPreferences(key: string, data: any): Promise<void> {
    const jsonData = JsonUtil.stringify(data);
    // 在HarmonyOS中使用Preferences API
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      await pref.putString(key, jsonData);
      await pref.flush();
    } catch (error) {
      Logger.warn(TAG, `Preferences save failed, falling back to localStorage: ${error}`);
      // 降级到localStorage（如果可用）
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem(key, jsonData);
      } else {
        throw error;
      }
    }
  }

  private static async getFromPreferences(key: string): Promise<any> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const jsonData = await pref.getString(key, null);
      return jsonData ? JsonUtil.parse(jsonData) : null;
    } catch (error) {
      Logger.warn(TAG, `Preferences get failed, falling back to localStorage: ${error}`);
      // 降级到localStorage（如果可用）
      if (typeof localStorage !== 'undefined') {
        const jsonData = localStorage.getItem(key);
        return jsonData ? JsonUtil.parse(jsonData) : null;
      }
      throw error;
    }
  }

  private static async removeFromPreferences(key: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      await pref.delete(key);
      await pref.flush();
    } catch (error) {
      Logger.warn(TAG, `Preferences remove failed, falling back to localStorage: ${error}`);
      if (typeof localStorage !== 'undefined') {
        localStorage.removeItem(key);
      } else {
        throw error;
      }
    }
  }

  private static async clearPreferences(): Promise<void> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const keys = await this.getAllKeysFromPreferences();
      for (const key of keys) {
        await pref.delete(key);
      }
      await pref.flush();
    } catch (error) {
      Logger.warn(TAG, `Preferences clear failed, falling back to localStorage: ${error}`);
      if (typeof localStorage !== 'undefined') {
        localStorage.clear();
      } else {
        throw error;
      }
    }
  }

  private static async hasInPreferences(key: string): Promise<boolean> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      return await pref.has(key);
    } catch (error) {
      Logger.warn(TAG, `Preferences has check failed, falling back to localStorage: ${error}`);
      if (typeof localStorage !== 'undefined') {
        return localStorage.getItem(key) !== null;
      }
      throw error;
    }
  }

  private static async getAllKeysFromPreferences(): Promise<string[]> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      return await pref.keys();
    } catch (error) {
      Logger.warn(TAG, `Preferences keys get failed, falling back to localStorage: ${error}`);
      if (typeof localStorage !== 'undefined') {
        return Object.keys(localStorage);
      }
      return [];
    }
  }

  // ===== File 相关方法 =====
  private static async saveToFile(key: string, data: any): Promise<void> {
    const filePath = `${AppConstant.FILE_STORAGE_PATH}/${key}.json`;
    const jsonData = JsonUtil.stringify(data);
    await FileUtil.writeFile(filePath, jsonData);
  }

  private static async getFromFile(key: string): Promise<any> {
    const filePath = `${AppConstant.FILE_STORAGE_PATH}/${key}.json`;
    if (await FileUtil.exists(filePath)) {
      const jsonData = await FileUtil.readFile(filePath);
      return JsonUtil.parse(jsonData);
    }
    return null;
  }

  private static async removeFromFile(key: string): Promise<void> {
    const filePath = `${AppConstant.FILE_STORAGE_PATH}/${key}.json`;
    if (await FileUtil.exists(filePath)) {
      await FileUtil.deleteFile(filePath);
    }
  }

  private static async clearFiles(): Promise<void> {
    if (await FileUtil.exists(AppConstant.FILE_STORAGE_PATH)) {
      const files = await FileUtil.readDir(AppConstant.FILE_STORAGE_PATH);
      for (const file of files) {
        if (file.endsWith('.json')) {
          await FileUtil.deleteFile(`${AppConstant.FILE_STORAGE_PATH}/${file}`);
        }
      }
    }
  }

  private static async hasInFile(key: string): Promise<boolean> {
    const filePath = `${AppConstant.FILE_STORAGE_PATH}/${key}.json`;
    return await FileUtil.exists(filePath);
  }

  private static async getAllKeysFromFiles(): Promise<string[]> {
    const keys: string[] = [];
    if (await FileUtil.exists(AppConstant.FILE_STORAGE_PATH)) {
      const files = await FileUtil.readDir(AppConstant.FILE_STORAGE_PATH);
      for (const file of files) {
        if (file.endsWith('.json')) {
          keys.push(file.replace('.json', ''));
        }
      }
    }
    return keys;
  }

  // ===== Memory 相关方法 =====
  private static saveToMemory(key: string, data: any): void {
    this.memoryCache[key] = {
      value: data.value,
      expireTime: data.expireTime
    };
  }

  private static getFromMemory(key: string): any {
    const item = this.memoryCache[key];
    if (!item) return null;
    
    if (item.expireTime > 0 && Date.now() > item.expireTime) {
      delete this.memoryCache[key];
      return null;
    }
    
    return { value: item.value, expireTime: item.expireTime };
  }

  private static removeFromMemory(key: string): void {
    delete this.memoryCache[key];
  }

  private static clearMemory(): void {
    this.memoryCache = {};
  }

  private static hasInMemory(key: string): boolean {
    return key in this.memoryCache && 
           (!this.memoryCache[key].expireTime || Date.now() <= this.memoryCache[key].expireTime);
  }

  // ===== 内存缓存清理 =====
  private static startMemoryCacheCleanup(): void {
    setInterval(() => {
      this.cleanupExpiredMemoryCache();
    }, this.MEMORY_CACHE_CLEAN_INTERVAL);
  }

  private static cleanupExpiredMemoryCache(): void {
    const now = Date.now();
    let removedCount = 0;
    
    for (const key in this.memoryCache) {
      const item = this.memoryCache[key];
      if (item.expireTime > 0 && now > item.expireTime) {
        delete this.memoryCache[key];
        removedCount++;
      }
    }
    
    if (removedCount > 0) {
      Logger.info(TAG, `Cleaned up ${removedCount} expired items from memory cache`);
    }
  }
}