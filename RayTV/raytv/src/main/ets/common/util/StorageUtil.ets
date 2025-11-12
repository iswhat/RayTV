// StorageUtil - 本地存储管理工具类
import Logger from './Logger';
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
  value: string | number | boolean | Record<string, string | number | boolean> | null;
  timestamp: number;
  expireTime: number;
}

/**
 * 内存缓存项结构
 */
export interface MemoryCacheItem {
  value: string | number | boolean | Record<string, string | number | boolean> | null;
  expireTime: number;
}

/**
 * JSON数据类型 - 替代any类型
 * 使用Record类型避免索引签名
 */
export type JsonData = Record<string, string | number | boolean | null>;

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
  public static async save(key: string, value: string | number | boolean | JsonData | null, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    if (!key || typeof key !== 'string') {
      throw new Error('Invalid key');
    }

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

      Logger.info(TAG, `Saved data for key: ${key}, type: ${type}`);
    } catch (error) {
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to save data for key ${key}: ${errorMessage}`);
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
  public static async get(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue?: string | number | boolean | JsonData | null): Promise<string | number | boolean | JsonData | null> {
    if (!key || typeof key !== 'string') {
      return defaultValue !== undefined ? defaultValue : null;
    }

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
        Logger.warn(TAG, `Data expired for key: ${key}`);
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
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to get data for key ${key}: ${errorMessage}`);
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
    if (!key) {
      return;
    }

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
          const cacheKeys = Object.keys(StorageUtil.memoryCache);
          for (let i = 0; i < cacheKeys.length; i++) {
            const cacheKey = cacheKeys[i];
            // 使用简单的检查方式
            if (cacheKey !== key && StorageUtil.memoryCache[cacheKey] !== undefined) {
              newCache[cacheKey] = StorageUtil.memoryCache[cacheKey];
            }
          }
          StorageUtil.memoryCache = newCache;
          break;
        default:
          throw new Error(`Unsupported storage type: ${type}`);
      }

      Logger.info(TAG, `Removed data for key: ${key}, type: ${type}`);
    } catch (error) {
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to remove data for key ${key}: ${errorMessage}`);
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

      Logger.info(TAG, `Cleared all data for type: ${type}`);
    } catch (error) {
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to clear data for type ${type}: ${errorMessage}`);
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
      try {
        const now = Date.now();
        const newCache: Record<string, MemoryCacheItem> = {};

        // 过滤过期的缓存项
        const cacheKeys = Object.keys(StorageUtil.memoryCache);
        for (let i = 0; i < cacheKeys.length; i++) {
          const key = cacheKeys[i];
          // 使用简单的检查方式
          const item = StorageUtil.memoryCache[key];
          if (item !== undefined && (item.expireTime === 0 || now < item.expireTime)) {
            newCache[key] = item;
          } else {
            Logger.info(TAG, `Removed expired memory cache item: ${key}`);
          }
        }

        StorageUtil.memoryCache = newCache;
      } catch (error) {
        // 直接使用String()转换错误信息
        const errorMessage = String(error);
        Logger.error(TAG, `Failed to clean memory cache: ${errorMessage}`);
      }
    }, StorageUtil.MEMORY_CACHE_CLEAN_INTERVAL);
  }

  /**
   * 保存到偏好设置
   */
  private static async saveToPreferences(key: string, data: StorageData): Promise<void> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const jsonData = JSON.stringify(data);
      await pref.putString(key, jsonData);
      await pref.flush();
    } catch (error) {
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to save to preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从偏好设置读取
   */
  private static async getFromPreferences(key: string): Promise<StorageData | null> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const jsonData = await pref.getString(key, '');
      
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
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to get from preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从偏好设置移除
   */
  private static async removeFromPreferences(key: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      await pref.delete(key);
      await pref.flush();
    } catch (error) {
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to remove from preferences for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 清除所有偏好设置
   */
  private static async clearPreferences(): Promise<void> {
    try {
      const pref = await preferences.getPreferences(AppConstant.APP_PACKAGE_NAME, AppConstant.PREFERENCES_NAME);
      const keys = await pref.getAllKeys();
      
      // 检查keys是否为数组
      if (Array.isArray(keys)) {
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          // 确保key是字符串类型
          if (typeof key === 'string') {
            await pref.delete(key);
          }
        }
      }
      
      await pref.flush();
    } catch (error) {
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to clear preferences: ${errorMessage}`);
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
      const jsonData = JSON.stringify(data);
      await FileUtil.writeFile(filePath, jsonData);
    } catch (error) {
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to save to file for key ${key}: ${errorMessage}`);
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
      
      // 确保FileUtil.readFile返回字符串类型
      const readResult = await FileUtil.readFile(filePath);
      let jsonData: string = '';
      if (typeof readResult === 'string') {
        jsonData = readResult;
      } else {
        // 如果返回的不是字符串，转换为字符串
        jsonData = String(readResult);
      }
      
      // 确保jsonData是字符串
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
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to get from file for key ${key}: ${errorMessage}`);
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
      // 直接使用String()转换错误信息
      const errorMessage = String(error);
      Logger.error(TAG, `Failed to remove from file for key ${key}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 清除所有文件
   */
  private static async clearFiles(): Promise<void> {
    try {
      const dirPath = await FileUtil.getApplicationDataDir();
      const files = await FileUtil.listFiles(dirPath);
      
      // 检查files是否为数组
      if (Array.isArray(files)) {
        for (let i = 0; i < files.length; i++) {
          const file = files[i];
          // 确保file是字符串类型
          if (typeof file === 'string' && file.endsWith('.json')) {
            await FileUtil.deleteFile(dirPath + '/' + file);
          }
        }
      }
    } catch (error) {
      // 安全处理错误信息，避免使用String()函数
      const errorMessage = error.message || 'Unknown error';
      Logger.error(TAG, `Failed to clear files: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 安全解析JSON字符串
   */
  private static safeParseJSON(jsonStr: string): JsonData | null {
    if (!jsonStr || typeof jsonStr !== 'string') {
      return null;
    }
    try {
      const parsed = JSON.parse(jsonStr);
      // 确保解析结果是对象且不是数组
      if (parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed)) {
        const safeData: JsonData = {};
        // 获取对象的所有自有属性键
        const keys = Object.keys(parsed);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          const value = (parsed as Record<string, string | number | boolean | null>)[key];
          // 类型安全地设置值
          if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
            safeData[key] = value;
          } else if (typeof value === 'object' && value !== null) {
            safeData[key] = {} as JsonData;
          }
        }
        return safeData;
      }
      return null;
    } catch (error) {
      const errorMessage = error.message || 'Unknown error';
      Logger.error(TAG, `Failed to parse JSON string: ${errorMessage}`);
      return null;
    }
  }

  /**
   * 构建并验证StorageData对象
   */
  private static buildStorageData(data: JsonData): StorageData {
    const result: StorageData = {
      value: null,
      timestamp: 0,
      expireTime: 0
    };
    
    // 安全地处理所有属性，避免使用索引访问和任何原型方法
    try {
      // 获取对象的所有自有属性键，避免使用in操作符
      const keys = Object.keys(data);
      
      // 处理value属性
      if (keys.includes('value')) {
        const valueData = data['value'];
        if (typeof valueData === 'string' || typeof valueData === 'number' || 
            typeof valueData === 'boolean' || valueData === null) {
          result.value = valueData;
        } else if (typeof valueData === 'object' && valueData !== null) {
          // 创建新的安全对象
          const safeObject: Record<string, string | number | boolean> = {};
          result.value = safeObject;
        }
      }
      
      // 处理timestamp属性
      if (keys.includes('timestamp')) {
        const tsValue = data['timestamp'];
        if (typeof tsValue === 'number') {
          result.timestamp = tsValue;
        } else if (typeof tsValue === 'string') {
          const numValue = Number(tsValue);
          if (!isNaN(numValue)) {
            result.timestamp = numValue;
          }
        }
      }
      
      // 处理expireTime属性
      if (keys.includes('expireTime')) {
        const expValue = data['expireTime'];
        if (typeof expValue === 'number') {
          result.expireTime = expValue;
        } else if (typeof expValue === 'string') {
          const numValue = Number(expValue);
          if (!isNaN(numValue)) {
            result.expireTime = numValue;
          }
        }
      }
    } catch (error) {
      const errorMessage = error.message || 'Unknown error';
      Logger.error(TAG, `Failed to build StorageData: ${errorMessage}`);
    }
    
    return result;
  }

  /**
   * 验证值的类型安全性
   */
  private static validateValue(value: string | number | boolean | JsonData | null): string | number | boolean | JsonData | null {
    if (value === null) {
      return null;
    }
    
    switch (typeof value) {
      case 'string':
      case 'number':
      case 'boolean':
        return value;
      case 'object':
        // 创建新对象确保类型安全
        const safeObj: JsonData = {};
        // 获取对象的所有自有属性键
        const keys = Object.keys(value);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          const propValue = (value as Record<string, string | number | boolean | null>)[key];
          // 类型安全地处理每个属性值
          if (typeof propValue === 'string' || typeof propValue === 'number' || 
              typeof propValue === 'boolean' || propValue === null) {
            safeObj[key] = propValue;
          } else if (typeof propValue === 'object' && propValue !== null) {
            safeObj[key] = {} as JsonData;
          }
        }
        return safeObj;
      default:
        // 对于不支持的类型，转换为字符串
        return String(value);
    }
  }

  /**
   * 安全获取数字值
   */
  private static safeNumber(value: string | number | boolean, defaultValue: number = 0): number {
    // 类型安全检查
    if (value === null || value === undefined) {
      return defaultValue;
    }
    
    // 直接处理不同类型
    if (typeof value === 'number') {
      // 检查是否为有效数字
      if (!Number.isNaN(value)) {
        return value;
      }
    } else if (typeof value === 'string') {
      // 对于字符串，安全转换为数字
      const num = Number(value);
      if (!Number.isNaN(num)) {
        return num;
      }
    } else if (typeof value === 'boolean') {
      // 对于布尔值，转换为数字
      return value ? 1 : 0;
    }
    
    return defaultValue;
  }
}
