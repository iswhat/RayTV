// StorageUtil - 本地存储管理工具类
import Logger from './Logger';
import { safeParseJson, safeStringify } from './JsonUtil';
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
 * 存储数据结构
 */
export interface StorageData {
  value: string | number | boolean | object | null;
  timestamp: number;
  expireTime: number;
}

/**
 * 内存缓存项结构
 */
export interface MemoryCacheItem {
  value: string | number | boolean | object | null;
  expireTime: number;
}

/**
 * 存储工具类
 * 提供多种存储方式的统一接口，包括偏好设置、文件存储等
 */
export default class StorageUtil {
  private static memoryCache: Record<string, MemoryCacheItem> = {};
  private static readonly MEMORY_CACHE_CLEAN_INTERVAL = 5 * 60 * 1000; // 5分钟清理一次

  static {
    // 启动内存缓存自动清理
    StorageUtil.startMemoryCacheCleanup();
  }

  /**
   * 保存数据到存储
   * @param key 键名
   * @param value 数据值
   * @param type 存储类型
   * @param expireTime 过期时间（毫秒，0表示永不过期）
   */
  public static async save(key: string, value: string | number | boolean | object | null, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    try {
      const dataToSave: StorageData = {
        value,
        timestamp: Date.now(),
        expireTime: expireTime > 0 ? Date.now() + expireTime : 0
      };

      switch (type) {
        case StorageType.PREFERENCES:
          await StorageUtil.saveToPreferences(key, dataToSave);
          break;
        case StorageType.FILE:
          await StorageUtil.saveToFile(key, dataToSave);
          break;
        case StorageType.MEMORY:
          StorageUtil.saveToMemory(key, dataToSave);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.getInstance().info(`${TAG} - Saved data for key: ${key}, type: ${type}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to save data for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从存储中读取数据
   * @param key 键名
   * @param type 存储类型
   * @param defaultValue 默认值
   * @returns 读取的数据或默认值
   */
  public static async get<T = string | number | boolean | object | null>(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue?: T): Promise<T> {
    try {
      let data: StorageData | null = null;

      switch (type) {
        case StorageType.PREFERENCES:
          data = await StorageUtil.getFromPreferences(key);
          break;
        case StorageType.FILE:
          data = await StorageUtil.getFromFile(key);
          break;
        case StorageType.MEMORY:
          data = StorageUtil.getFromMemory(key);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      // 检查是否过期
      if (data && data.expireTime > 0 && Date.now() > data.expireTime) {
        Logger.getInstance().warn(`${TAG} - Data expired for key: ${key}`);
        await StorageUtil.remove(key, type);
        return defaultValue as T;
      }

      return data ? (data.value as unknown as T) : (defaultValue as T);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to get data for key ${key}: ${errorMessage}`);
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
          await StorageUtil.removeFromPreferences(key);
          break;
        case StorageType.FILE:
          await StorageUtil.removeFromFile(key);
          break;
        case StorageType.MEMORY:
          StorageUtil.removeFromMemory(key);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.getInstance().info(`${TAG} - Removed data for key: ${key}, type: ${type}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to remove data for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
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
          await StorageUtil.clearPreferences();
          break;
        case StorageType.FILE:
          await StorageUtil.clearFiles();
          break;
        case StorageType.MEMORY:
          StorageUtil.clearMemory();
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.getInstance().info(`${TAG} - Cleared all data for type: ${type}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to clear storage of type ${type}: ${errorMessage}`);
      throw new Error(errorMessage);
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
          exists = await StorageUtil.hasInPreferences(key);
          break;
        case StorageType.FILE:
          exists = await StorageUtil.hasInFile(key);
          break;
        case StorageType.MEMORY:
          exists = StorageUtil.hasInMemory(key);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      return exists;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to check existence for key ${key}: ${errorMessage}`);
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
          keys = await StorageUtil.getAllKeysFromPreferences();
          break;
        case StorageType.FILE:
          keys = await StorageUtil.getAllKeysFromFiles();
          break;
        case StorageType.MEMORY:
          keys = Object.keys(StorageUtil.memoryCache);
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      return keys;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to get all keys for type ${type}: ${errorMessage}`);
      return [];
    }
  }

  // ===== Preferences 相关方法 =====
  private static async saveToPreferences(key: string, data: StorageData): Promise<void> {
    const jsonData = safeStringify(data);
    // 在HarmonyOS中使用Preferences API
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      await pref.putString(key, jsonData);
      await pref.flush();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to save to preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  private static async getFromPreferences(key: string): Promise<StorageData | null> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const jsonData = await pref.getString(key, null);
      return jsonData ? safeParseJson<StorageData>(jsonData, null) : null;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to get from preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  private static async removeFromPreferences(key: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      await pref.delete(key);
      await pref.flush();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to remove from preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  private static async clearPreferences(): Promise<void> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const keys = await StorageUtil.getAllKeysFromPreferences();
      for (let i = 0; i < keys.length; i++) {
        await pref.delete(keys[i]);
      }
      await pref.flush();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to clear preferences: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  private static async hasInPreferences(key: string): Promise<boolean> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      return await pref.has(key);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to check existence in preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  private static async getAllKeysFromPreferences(): Promise<string[]> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      return await pref.keys();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to get all keys from preferences: ${errorMessage}`);
      return [];
    }
  }

  // ===== File 相关方法 =====
  private static async saveToFile(key: string, data: StorageData): Promise<void> {
    const filePath = `${AppConstant.FILE_STORAGE_PATH}/${key}.json`;
    const jsonData = safeStringify(data);
    await FileUtil.writeFile(filePath, jsonData);
  }

  private static async getFromFile(key: string): Promise<StorageData | null> {
    const filePath = `${AppConstant.FILE_STORAGE_PATH}/${key}.json`;
    if (await FileUtil.exists(filePath)) {
      const jsonData = await FileUtil.readFile(filePath);
      return safeParseJson<StorageData>(jsonData, null);
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
      // 这里使用listFiles方法替代不存在的readDir方法
      const files = await FileUtil.listFiles(AppConstant.FILE_STORAGE_PATH);
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
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
      // 这里使用listFiles方法替代不存在的readDir方法
      const files = await FileUtil.listFiles(AppConstant.FILE_STORAGE_PATH);
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        if (file.endsWith('.json')) {
          keys.push(file.replace('.json', ''));
        }
      }
    }
    return keys;
  }

  // ===== Memory 相关方法 =====
  private static saveToMemory(key: string, data: StorageData): void {
    StorageUtil.memoryCache[key] = {
      value: data.value,
      expireTime: data.expireTime
    };
  }

  private static getFromMemory(key: string): StorageData | null {
    const item = StorageUtil.memoryCache[key];
    if (!item) return null;
    
    if (item.expireTime > 0 && Date.now() > item.expireTime) {
      // 使用创建新对象的方式替代delete操作符
      const newCache = {} as Record<string, MemoryCacheItem>;
      const keys = Object.keys(StorageUtil.memoryCache);
      for (let i = 0; i < keys.length; i++) {
        if (keys[i] !== key) {
          newCache[keys[i]] = StorageUtil.memoryCache[keys[i]];
        }
      }
      StorageUtil.memoryCache = newCache;
      return null;
    }
    
    return { value: item.value, expireTime: item.expireTime, timestamp: Date.now() };
  }

  private static removeFromMemory(key: string): void {
    // 使用创建新对象的方式替代delete操作符
    const newCache = {} as Record<string, MemoryCacheItem>;
    const keys = Object.keys(StorageUtil.memoryCache);
    for (let i = 0; i < keys.length; i++) {
      if (keys[i] !== key) {
        newCache[keys[i]] = StorageUtil.memoryCache[keys[i]];
      }
    }
    StorageUtil.memoryCache = newCache;
  }

  private static clearMemory(): void {
    StorageUtil.memoryCache = {};
  }

  private static hasInMemory(key: string): boolean {
    const item = StorageUtil.memoryCache[key];
    return !!item && 
           (item.expireTime === 0 || Date.now() <= item.expireTime);
  }

  // ===== 内存缓存清理 =====
  private static startMemoryCacheCleanup(): void {
    setInterval(() => {
      StorageUtil.cleanupExpiredMemoryCache();
    }, StorageUtil.MEMORY_CACHE_CLEAN_INTERVAL);
  }

  private static cleanupExpiredMemoryCache(): void {
    const now = Date.now();
    let removedCount = 0;
    
    // 使用Object.keys替代for..in循环
    const keys = Object.keys(StorageUtil.memoryCache);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const item = StorageUtil.memoryCache[key];
      if (item.expireTime > 0 && now > item.expireTime) {
        // 使用创建新对象的方式替代delete操作符
        const newCache = {} as Record<string, MemoryCacheItem>;
        const allKeys = Object.keys(StorageUtil.memoryCache);
        for (let j = 0; j < allKeys.length; j++) {
          if (allKeys[j] !== key) {
            newCache[allKeys[j]] = StorageUtil.memoryCache[allKeys[j]];
          }
        }
        StorageUtil.memoryCache = newCache;
        removedCount++;
      }
    }
    
    if (removedCount > 0) {
      Logger.getInstance().info(`${TAG} - Cleaned up ${removedCount} expired items from memory cache`);
    }
  }
}