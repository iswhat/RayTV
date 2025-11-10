// StorageUtil - 本地存储管理工具类
import Logger from './Logger';
import AppConstant from '../constant/AppConstant';
import FileUtil from './FileUtil';
import preferences from '@ohos.data.preferences';
import { JsonValue } from './JsonUtil';

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
      // 确保value的类型安全
      const safeValue = StorageUtil.validateValue(value);
      
      const dataToSave: StorageData = {
        value: safeValue,
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
      const errorMessage = StorageUtil.getErrorMessage(error);
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
  public static async get(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue?: string | number | boolean | object | null): Promise<string | number | boolean | object | null> {
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
      if (data !== null && data.expireTime > 0 && Date.now() > data.expireTime) {
        Logger.getInstance().warn(`${TAG} - Data expired for key: ${key}`);
        await StorageUtil.remove(key, type);
        // 直接返回默认值
        if (defaultValue !== undefined) {
          return defaultValue;
        }
        return null;
      }

      // 如果有数据且没有过期，返回数据值
      if (data !== null) {
        // 确保返回值类型安全
        const safeValue = StorageUtil.validateValue(data.value);
        return safeValue;
      }

      // 没有数据时返回默认值
      if (defaultValue !== undefined) {
        return defaultValue;
      }
      return null;
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to get data for key ${key}: ${errorMessage}`);
      // 出错时返回默认值
      if (defaultValue !== undefined) {
        return defaultValue;
      }
      return null;
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
          // 创建新对象，不包含要删除的键
          const newCache: Record<string, MemoryCacheItem> = {};
          const keys = Object.keys(StorageUtil.memoryCache);
          for (let i = 0; i < keys.length; i++) {
            const k = keys[i];
            if (k !== key) {
              newCache[k] = StorageUtil.memoryCache[k];
            }
          }
          StorageUtil.memoryCache = newCache;
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.getInstance().info(`${TAG} - Removed data for key: ${key}, type: ${type}`);
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to remove data for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 清除所有存储数据
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
          StorageUtil.memoryCache = {};
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.getInstance().info(`${TAG} - Cleared all data for type: ${type}`);
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to clear data for type ${type}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 保存到内存缓存
   */
  private static saveToMemory(key: string, data: StorageData): void {
    StorageUtil.memoryCache[key] = {
      value: data.value,
      expireTime: data.expireTime
    };
  }

  /**
   * 从内存缓存读取
   */
  private static getFromMemory(key: string): StorageData | null {
    const cachedItem = StorageUtil.memoryCache[key];
    if (!cachedItem) {
      return null;
    }

    return {
      value: cachedItem.value,
      timestamp: Date.now(),
      expireTime: cachedItem.expireTime
    };
  }

  /**
   * 启动内存缓存自动清理
   */
  private static startMemoryCacheCleanup(): void {
    // 设置定时清理任务
    setInterval(() => {
      const now = Date.now();
      const keys = Object.keys(StorageUtil.memoryCache);
      const newCache: Record<string, MemoryCacheItem> = {};
      
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const item = StorageUtil.memoryCache[key];
        if (item.expireTime > 0 && now > item.expireTime) {
          Logger.getInstance().info(`${TAG} - Removed expired memory cache item: ${key}`);
        } else {
          // 保留未过期的项
          newCache[key] = item;
        }
      }
      
      StorageUtil.memoryCache = newCache;
    }, StorageUtil.MEMORY_CACHE_CLEAN_INTERVAL);
  }

  /**
   * 保存到偏好设置
   */
  private static async saveToPreferences(key: string, data: StorageData): Promise<void> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const jsonData = JSON.stringify(data) as string;
      await pref.putString(key, jsonData);
      await pref.flush();
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to save to preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从偏好设置读取
   */
  private static async getFromPreferences(key: string): Promise<StorageData | null> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const jsonData = await pref.getString(key, '') as string;
      
      if (jsonData === '') {
        return null;
      }
      
      // 安全解析JSON
      const parsedData = StorageUtil.safeParseJSON(jsonData);
      if (!parsedData) {
        return null;
      }
      
      // 构建安全的返回对象
      return StorageUtil.buildStorageData(parsedData);
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to get from preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从偏好设置移除
   */
  private static async removeFromPreferences(key: string): Promise<void> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      await pref.delete(key);
      await pref.flush();
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to remove from preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 清除所有偏好设置
   */
  private static async clearPreferences(): Promise<void> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const keys = await pref.getAllKeys() as string[];
      if (Array.isArray(keys)) {
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          await pref.delete(key);
        }
      }
      await pref.flush();
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to clear preferences: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 保存到文件
   */
  private static async saveToFile(key: string, data: StorageData): Promise<void> {
    try {
      const fileName = `${key}.json`;
      const filePath = await FileUtil.getApplicationDataDir() + '/' + fileName;
      const jsonData = JSON.stringify(data) as string;
      await FileUtil.writeFile(filePath, jsonData);
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to save to file for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从文件读取
   */
  private static async getFromFile(key: string): Promise<StorageData | null> {
    try {
      const fileName = `${key}.json`;
      const filePath = await FileUtil.getApplicationDataDir() + '/' + fileName;
      const exists = await FileUtil.isFileExists(filePath);
      
      if (!exists) {
        return null;
      }
      
      const jsonData = await FileUtil.readFile(filePath) as string;
      if (jsonData === '') {
        return null;
      }
      
      // 安全解析JSON
      const parsedData = StorageUtil.safeParseJSON(jsonData);
      if (!parsedData) {
        return null;
      }
      
      // 构建安全的返回对象
      return StorageUtil.buildStorageData(parsedData);
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to get from file for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从文件移除
   */
  private static async removeFromFile(key: string): Promise<void> {
    try {
      const fileName = `${key}.json`;
      const filePath = await FileUtil.getApplicationDataDir() + '/' + fileName;
      await FileUtil.deleteFile(filePath);
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to remove from file for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 清除所有文件
   */
  private static async clearFiles(): Promise<void> {
    try {
      const dirPath = await FileUtil.getApplicationDataDir();
      const files = await FileUtil.listFiles(dirPath) as string[];
      
      if (Array.isArray(files)) {
        for (let i = 0; i < files.length; i++) {
          const file = files[i];
          if (file.endsWith('.json')) {
            await FileUtil.deleteFile(dirPath + '/' + file);
          }
        }
      }
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error);
      Logger.getInstance().error(`${TAG} - Failed to clear files: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 安全解析JSON字符串
   */
  private static safeParseJSON(jsonStr: string): Record<string, unknown> | null {
    try {
      // JSON.parse可能返回各种类型，我们需要确保返回的是对象类型
      const result = JSON.parse(jsonStr);
      // 严格检查是否为对象且不是null
      if (typeof result === 'object' && result !== null && !Array.isArray(result)) {
        // 转换为Record类型以提供更好的类型提示
        return result as Record<string, unknown>;
      }
      return null;
    } catch (parseError) {
      const errorMessage = StorageUtil.getErrorMessage(parseError);
      Logger.getInstance().error(`${TAG} - Failed to parse JSON string: ${errorMessage}`);
      return null;
    }
  }

  /**
   * 构建并验证StorageData对象
   */
  private static buildStorageData(data: object): StorageData {
    const result: StorageData = {
      value: null,
      timestamp: 0,
      expireTime: 0
    };
    
    try {
      // 安全获取value属性
      if (Object.prototype.hasOwnProperty.call(data, 'value')) {
        const valueProp = Object.getOwnPropertyDescriptor(data, 'value')?.value;
        if (valueProp !== undefined) {
          if (typeof valueProp === 'string' || typeof valueProp === 'number' || typeof valueProp === 'boolean' || valueProp === null) {
            result.value = valueProp;
          } else if (typeof valueProp === 'object') {
            result.value = valueProp;
          }
        }
      }
      
      // 安全获取timestamp属性
      if (Object.prototype.hasOwnProperty.call(data, 'timestamp')) {
        const timestampProp = Object.getOwnPropertyDescriptor(data, 'timestamp')?.value;
        if (timestampProp !== undefined) {
          if (typeof timestampProp === 'number') {
            result.timestamp = timestampProp;
          } else if (typeof timestampProp === 'string') {
            result.timestamp = Number(timestampProp) || 0;
          }
        }
      }
      
      // 安全获取expireTime属性
      if (Object.prototype.hasOwnProperty.call(data, 'expireTime')) {
        const expireTimeProp = Object.getOwnPropertyDescriptor(data, 'expireTime')?.value;
        if (expireTimeProp !== undefined) {
          if (typeof expireTimeProp === 'number') {
            result.expireTime = expireTimeProp;
          } else if (typeof expireTimeProp === 'string') {
            result.expireTime = Number(expireTimeProp) || 0;
          }
        }
      }
    } catch (error) {
      const errorMessage = StorageUtil.getErrorMessage(error as Error | string);
      Logger.getInstance().error(`${TAG} - Failed to build StorageData: ${errorMessage}`);
    }
    
    return result;
  }

  /**
   * 验证值的类型安全性
   */
  private static validateValue(value: string | number | boolean | object | null): string | number | boolean | object | null {
    if (value === null) {
      return null;
    }
    
    switch (typeof value) {
      case 'string':
        return value;
      case 'number':
        return value;
      case 'boolean':
        return value;
      case 'object':
        return value;
      default:
        // 对于不支持的类型，转换为字符串
        return String(value);
    }
  }

  /**
   * 安全获取数字值
   */
  private static safeNumber(value: string | number): number {
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      return Number(value) || 0;
    }
    return 0;
  }

  /**
   * 安全获取错误消息
   */
  private static getErrorMessage(error: Error | string): string {
    if (error instanceof Error) {
      return error.message;
    }
    if (typeof error === 'string') {
      return error;
    }
    return 'Unknown error';
  }
}