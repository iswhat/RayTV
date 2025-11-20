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
  // 替换any类型为具体的支持类型
  value: string | number | boolean | JsonData | null;
  timestamp: number;
  expireTime: number;
}

/**
 * 内存缓存项结构
 */
export interface MemoryCacheItem {
  // 替换any类型为具体的支持类型
  value: string | number | boolean | JsonData | null;
  expireTime: number;
}

/**
 * JSON数据类型 - 替代索引签名，使用类实现
 */
export class JsonDataClass {
  private data: Record<string, string | number | boolean | JsonDataClass | null> = {};

  set(key: string, value: string | number | boolean | JsonDataClass | null): void {
    if (typeof key === 'string') {
      this.data[key] = value;
    }
  }

  get(key: string): string | number | boolean | JsonDataClass | null {
    return this.data[key] || null;
  }

  has(key: string): boolean {
    // 使用Object.keys获取属性列表并检查，避免使用hasOwnProperty
    return Object.keys(this.data).includes(key);
  }

  keys(): string[] {
    return Object.keys(this.data);
  }

  // 移除any类型，使用更具体的类型定义
  toObject(): Record<string, string | number | boolean | JsonDataClass | null> {
    const result: Record<string, string | number | boolean | JsonDataClass | null> = {};
    
    for (const key of this.keys()) {
      const value = this.get(key);
      if (value instanceof JsonDataClass) {
        result[key] = value.toObject();
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  // 使用更具体的类型替代any
  static fromObject(obj: Record<string, string | number | boolean | object | null>): JsonDataClass | null {
    if (typeof obj !== 'object' || obj === null || Array.isArray(obj)) {
      return null;
    }
    const jsonData = new JsonDataClass();
    for (const key of Object.keys(obj)) {
      const value = obj[key];
      if (typeof value === 'string' || typeof value === 'number' || 
          typeof value === 'boolean' || value === null) {
        jsonData.set(key, value);
      } else if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        const nestedData = JsonDataClass.fromObject(value);
        if (nestedData) {
          jsonData.set(key, nestedData);
        }
      }
    }
    return jsonData;
  }
}

// 为了向后兼容，保留JsonData类型别名
export type JsonData = JsonDataClass;

/**
 * 存储工具类
 * 提供多种存储方式的统一接口，包括偏好设置、文件存储等
 */
export default class StorageUtil {
  // 使用局部变量存储单例实例，避免使用类作为对象
  private static _instance: StorageUtil | null = null;

  /**
   * 获取单例实例
   * @returns StorageUtil实例
   */
  public static getInstance(): StorageUtil {
    if (!StorageUtil._instance) {
      StorageUtil._instance = new StorageUtil();
    }
    return StorageUtil._instance;
  }

  /**
   * 私有构造函数，确保单例模式
   */
  private constructor() {
    // 初始化操作
  }
  private static memoryCache: Record<string, MemoryCacheItem> = {};
  private static readonly MEMORY_CACHE_CLEAN_INTERVAL = 5 * 60 * 1000; // 5分钟清理一次
  // 内存缓存清理定时器
  private static cleanupTimer: number | undefined = undefined;

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
  public static async save(key: string, value: string | number | boolean | JsonData | null | undefined, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    if (!key || typeof key !== 'string') {
      throw new Error('Invalid key');
    }

    try {
      // 确保value的类型安全
      const safeValue: string | number | boolean | JsonData | null = StorageUtil.validateValue(value);
      
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
          throw new Error(`Unsupported storage type: ${String(type)}`);
      }

      Logger.info(TAG, `Saved data for key: ${key}, type: ${type}`);
    } catch (error) {
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
  public static async get<T extends string | number | boolean | JsonData | null>(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue?: T): Promise<T | null> {
    // 严格的null安全检查
    if (!key || typeof key !== 'string' || key.trim() === '') {
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
          throw new Error(`Unsupported storage type: ${String(type)}`);
      }

      // 检查数据是否存在
      if (data === null) {
        return defaultValue !== undefined ? defaultValue : null;
      }

      // 检查是否过期
      const now = Date.now();
      if (data.expireTime > 0 && now > data.expireTime) {
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
        // 使用更安全的类型转换方式
        return safeValue as T;
      }

      // 没有数据时返回默认值
      if (defaultValue !== undefined) {
        return defaultValue;
      }
      return null;
    } catch (error) {
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get data for key ${key}: ${errorMessage}`);
      // 出错时返回默认值
      if (defaultValue !== undefined) {
        return defaultValue;
      }
      return null;
    }
  }

  /**
   * 设置字符串值（set方法的别名）
   * @param key 键名
   * @param value 字符串值
   * @param type 存储类型
   * @param expireTime 过期时间（毫秒，0表示永不过期）
   */
  public static async set(key: string, value: string | number | boolean | JsonData | null | undefined, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    await StorageUtil.save(key, value, type, expireTime);
  }

  /**
   * 设置字符串值
   * @param key 键名
   * @param value 字符串值
   * @param type 存储类型
   * @param expireTime 过期时间（毫秒，0表示永不过期）
   */
  public static async setString(key: string, value: string | null | undefined, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    await StorageUtil.save(key, value, type, expireTime);
  }

  /**
   * 设置数字值
   * @param key 键名
   * @param value 数字值
   * @param type 存储类型
   * @param expireTime 过期时间（毫秒，0表示永不过期）
   */
  public static async setNumber(key: string, value: number | null | undefined, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    await StorageUtil.save(key, value, type, expireTime);
  }

  /**
   * 设置布尔值
   * @param key 键名
   * @param value 布尔值
   * @param type 存储类型
   * @param expireTime 过期时间（毫秒，0表示永不过期）
   */
  public static async setBoolean(key: string, value: boolean | null | undefined, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    await StorageUtil.save(key, value, type, expireTime);
  }

  /**
   * 设置对象值
   * @param key 键名
   * @param value 对象值
   * @param type 存储类型
   * @param expireTime 过期时间（毫秒，0表示永不过期）
   */
  public static async setObject<T extends JsonData>(key: string, value: T | null | undefined, type: StorageType = StorageType.PREFERENCES, expireTime: number = 0): Promise<void> {
    await StorageUtil.save(key, value, type, expireTime);
  }

  /**
   * 获取对象值
   * @param key 键名
   * @param type 存储类型
   * @param defaultValue 默认值
   * @returns 读取的对象或默认值
   */
  public static async getObject<T extends JsonData>(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue?: T): Promise<T | null> {
    return await StorageUtil.get<T>(key, type, defaultValue);
  }

  /**
   * 获取字符串值
   * @param key 键名
   * @param type 存储类型
   * @param defaultValue 默认值
   * @returns 读取的字符串或默认值
   */
  public static async getString(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue?: string): Promise<string | null> {
    return await StorageUtil.get<string>(key, type, defaultValue);
  }

  /**
   * 获取数字值
   * @param key 键名
   * @param type 存储类型
   * @param defaultValue 默认值
   * @returns 读取的数字或默认值（确保返回number类型）
   */
  public static async getNumber(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue: number = 0): Promise<number> {
    const value = await StorageUtil.get<number>(key, type, defaultValue);
    // 确保返回值是数字类型
    return typeof value === 'number' ? value : defaultValue;
  }

  /**
   * 获取布尔值
   * @param key 键名
   * @param type 存储类型
   * @param defaultValue 默认值
   * @returns 读取的布尔值或默认值
   */
  public static async getBoolean(key: string, type: StorageType = StorageType.PREFERENCES, defaultValue?: boolean): Promise<boolean | null> {
    return await StorageUtil.get<boolean>(key, type, defaultValue);
  }

  /**
   * 从存储中移除数据
   * @param key 键名
   * @param type 存储类型
   */
  public static async remove(key: string, type: StorageType = StorageType.PREFERENCES): Promise<void> {
    if (!key || typeof key !== 'string') {
      Logger.error(TAG, 'remove: key is empty or invalid');
      return;
    }

    try {
      // 从内存缓存中删除
      if (type !== StorageType.MEMORY) {
        // 创建新对象，不包含要删除的键
        const newCache: Record<string, MemoryCacheItem> = {};
        const cacheKeys = Object.keys(StorageUtil.memoryCache);
        for (let i = 0; i < cacheKeys.length; i++) {
          const cacheKey = cacheKeys[i];
          if (cacheKey !== key && StorageUtil.memoryCache[cacheKey] !== undefined) {
            newCache[cacheKey] = StorageUtil.memoryCache[cacheKey];
          }
        }
        StorageUtil.memoryCache = newCache;
      }

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
          throw new Error(`Unsupported storage type: ${String(type)}`);
      }

      Logger.info(TAG, `Removed data for key: ${key}, type: ${type}`);
    } catch (error) {
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
          throw new Error(`Unsupported storage type: ${String(type)}`);
      }

      Logger.info(TAG, `Cleared all data for type: ${type}`);
    } catch (error) {
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to clear data for type ${type}: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 保存到内存缓存
   */
  private static saveToMemory(key: string, data: StorageData): void {
    // 确保存储的是经过验证的类型
    const safeValue: string | number | boolean | JsonData | null = StorageUtil.validateValue(data.value);
    StorageUtil.memoryCache[key] = {
      value: safeValue,
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

    // 检查是否过期
    const now = Date.now();
    if (cachedItem.expireTime !== 0 && now > cachedItem.expireTime) {
      // 过期则删除并返回null
      const newCache: Record<string, MemoryCacheItem> = {};
      const cacheKeys = Object.keys(StorageUtil.memoryCache);
      for (let i = 0; i < cacheKeys.length; i++) {
        const cacheKey = cacheKeys[i];
        if (cacheKey !== key && StorageUtil.memoryCache[cacheKey] !== undefined) {
          newCache[cacheKey] = StorageUtil.memoryCache[cacheKey];
        }
      }
      StorageUtil.memoryCache = newCache;
      return null;
    }

    // 确保返回的是类型安全的值
    const safeValue: string | number | boolean | JsonData | null = StorageUtil.validateValue(cachedItem.value);
    return {
      value: safeValue,
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
        // 安全处理错误信息
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      // 创建JsonData实例并设置属性
      const jsonData = new JsonData();
      if (typeof parsed === 'object' && parsed !== null && !Array.isArray(parsed)) {
        const keys = Object.keys(parsed);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          const value = parsed[key];
          if (typeof value === 'string' || typeof value === 'number' || 
              typeof value === 'boolean' || value === null) {
            jsonData.set(key, value);
          }
        }
      }
      return jsonData;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to parse JSON string: ${errorMessage}`);
      return null;
    }
  }

  /**
   * 构建并验证StorageData对象
   */
  private static buildStorageData(parsedData: JsonData): StorageData {
    const result: StorageData = {
      value: null,
      timestamp: 0,
      expireTime: 0
    };
    
    // 安全地处理所有属性，避免使用索引访问和任何原型方法
    try {
      // 获取对象的所有自有属性键，避免使用in操作符
      const keys = Object.keys(parsedData);
      
      // 处理value属性 - 避免使用索引访问
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key === 'value') {
          const valueData = parsedData.get('value');
          if (typeof valueData === 'string' || typeof valueData === 'number' || 
              typeof valueData === 'boolean' || valueData === null) {
            result.value = valueData;
          } else if (valueData instanceof JsonDataClass) {
            // 递归验证嵌套对象
            result.value = StorageUtil.validateValue(valueData);
          }
        } else if (key === 'timestamp') {
          const tsValue = parsedData.get('timestamp');
          if (typeof tsValue === 'number') {
            result.timestamp = tsValue;
          } else if (typeof tsValue === 'string') {
            const numValue = Number(tsValue);
            // 使用更基础的NaN检查方式，避免使用Number.isNaN
            if (typeof numValue === 'number' && numValue === numValue) {
              result.timestamp = numValue;
            }
          }
        } else if (key === 'expireTime') {
          const expValue = parsedData.get('expireTime');
          if (typeof expValue === 'number') {
            // 使用更基础的NaN检查方式，避免使用Number.isNaN
            if (expValue === expValue) {
              result.expireTime = expValue;
            }
          } else if (typeof expValue === 'string') {
            const numValue = Number(expValue);
            // 使用更基础的NaN检查方式，避免使用Number.isNaN
            if (typeof numValue === 'number' && numValue === numValue) {
              result.expireTime = numValue;
            }
          }
        }
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to build StorageData: ${errorMessage}`);
    }
    
    return result;
  }

  /**
   * 验证值的类型安全性
   */
  private static validateValue(value: string | number | boolean | JsonData | null | undefined): string | number | boolean | JsonData | null {
    // 显式处理null和undefined
    if (value === null || value === undefined) {
      return null;
    }
    
    switch (typeof value) {
      case 'string':
      case 'number':
      case 'boolean':
        return value;
      case 'object':
        // 确保是纯对象而非数组
        if (!Array.isArray(value)) {
          if (value instanceof JsonDataClass) {
            return value;
          }
          // 创建新对象确保类型安全
          const safeObj = new JsonDataClass();
          // 获取对象的所有自有属性键
          const keys = Object.keys(value);
          // 由于使用Object.keys获取的都是自有属性，不需要额外的hasOwnProperty检查
          for (let i = 0; i < keys.length; i++) {
            const key = keys[i];
            if (key !== undefined) {
              const safeKey = String(key); // 确保key是字符串
              // 检查属性是否存在并访问
              // 使用Object.keys和includes替代Object.prototype.hasOwnProperty.call
              if (Object.keys(value).includes(safeKey)) {
                const propValue = value[safeKey];
                
                // 类型安全地处理每个属性值
                if (typeof propValue === 'string' || 
                    typeof propValue === 'number' || 
                    typeof propValue === 'boolean' || 
                    propValue === null) {
                  safeObj.set(safeKey, propValue);
                } else if (typeof propValue === 'object' && propValue !== null && !Array.isArray(propValue)) {
                  // 处理嵌套对象
                  const validatedObj = new JsonData();
                  const nestedKeys = Object.keys(propValue);
                  for (let j = 0; j < nestedKeys.length; j++) {
                    const nestedKey = nestedKeys[j];
                    // 使用get方法替代索引访问
                const nestedValue = validatedObj.get(nestedKey);
                    if (typeof nestedValue === 'string' || typeof nestedValue === 'number' || 
                        typeof nestedValue === 'boolean' || nestedValue === null) {
                      validatedObj.set(nestedKey, nestedValue);
                    }
                  }
                  // 转换为普通对象后再设置
                  const objValue = validatedObj.toObject();
                  safeObj.set(safeKey, JSON.stringify(objValue) as string | number | boolean | null);
                }
              }
            }
          }
          return safeObj;
        }
        // 对于数组，返回null，因为存储结构不支持数组
        return null;
      default:
        // 对于不支持的类型，返回null
        return null;
    }
  }

  /**
   * 安全的数字转换，避免NaN
   */
  // 移除any类型，使用更具体的类型定义
  private static safeNumber(value: string | number | boolean | null | undefined): number {
    if (value === null || value === undefined) {
      return 0;
    }
    const num = Number(value);
    // 使用更基础的NaN检查方式，避免使用isNaN函数
    // NaN是唯一不等于自身的值
    return typeof num === 'number' && num === num ? num : 0;
  }
}

// 导出单例实例函数而不是直接导出实例
export function getStorageUtil(): StorageUtil {
  return StorageUtil.getInstance();
}
