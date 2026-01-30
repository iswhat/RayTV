/**
 * StorageUtil - Storage utility class | 存储工具类
 * Provides unified storage management functionality | 提供统一的存储管理功能
 */
import { Preferences } from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

// 存储类型枚举 | Storage type enum
export enum StorageType {
  PREFERENCES = 'preferences',
  TEMPORARY = 'temporary',
  PERMANENT = 'permanent'
}

// 存储项接口 | Storage item interface
export interface StorageItem {
  // 通用存储项 | Common storage items
  userId?: string;
  appVersion?: string;
  lastLaunchTime?: number;
  themeMode?: string;
  language?: string;
  autoPlay?: boolean;
  volumeLevel?: number;
  brightnessLevel?: number;
  networkMode?: string;
  cacheSize?: number;
}

// 存储对象接口 | Storage object interface
export interface StorageObject {
  // 通用存储对象 | Common storage objects
  userInfo?: {
    id: string;
    name: string;
    avatar?: string;
  };
  appSettings?: {
    theme: string;
    language: string;
    notifications: boolean;
  };
  mediaSettings?: {
    autoPlay: boolean;
    defaultQuality: string;
    subtitleEnabled: boolean;
  };
  networkSettings?: {
    mode: string;
    timeout: number;
    retryCount: number;
  };
}

/**
 * StorageUtil class
 * 存储工具类
 * Provides unified storage management functionality
 * 提供统一的存储管理功能
 */
export class StorageUtil {
  private static readonly TAG: string = 'StorageUtil';
  private static preferences: Preferences | null = null;
  private static readonly PREFERENCES_NAME: string = 'raytv_preferences';

  /**
   * Initialize storage service | 初始化存储服务
   */
  public static async initialize(context: common.Context): Promise<boolean> {
    try {
      if (!context) {
        console.error(StorageUtil.TAG + ': Failed to get context for preferences');
        return false;
      }

      StorageUtil.preferences = await Preferences.getPreferences(context, StorageUtil.PREFERENCES_NAME);
      console.info(StorageUtil.TAG + ': StorageUtil initialized successfully');
      return true;
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to initialize StorageUtil', error.message);
      return false;
    }
  }

  /**
   * Get preferences instance | 获取偏好设置实例
   * @returns Preferences instance | 偏好设置实例
   */
  private static getPreferences(): Preferences | null {
    if (!StorageUtil.preferences) {
      console.warn(StorageUtil.TAG + ': StorageUtil not initialized');
    }
    return StorageUtil.preferences;
  }

  /**
   * Stores string value | 存储字符串值
   * @param key Key | 键
   * @param value Value | 值
   */
  public static async putString(key: string, value: string): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        await preferences.put(key, value);
        await preferences.flush();
      }
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to put string for key: ' + key, error.message);
    }
  }

  /**
   * Gets string value | 获取字符串值
   * @param key Key | 键
   * @param defaultValue Default value | 默认值
   * @param storageType Storage type | 存储类型
   * @returns String value | 字符串值
   */
  public static async getString(key: string, defaultValue: string = '', storageType: StorageType = StorageType.PREFERENCES): Promise<string> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        // Explicitly type the return value | 显式类型化返回值
        const result = await preferences.get<string>(key, defaultValue);
        return result;
      }
      return defaultValue;
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to get string for key: ' + key, error.message);
      return defaultValue;
    }
  }

  /**
   * Stores number value | 存储数值
   * @param key Key | 键
   * @param value Value | 值
   */
  public static async putNumber(key: string, value: number): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        await preferences.put(key, value);
        await preferences.flush();
      }
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to put number for key: ' + key, error.message);
    }
  }

  /**
   * Gets number value | 获取数值
   * @param key Key | 键
   * @param defaultValue Default value | 默认值
   * @returns Number value | 数值
   */
  public static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        // Explicitly type the return value | 显式类型化返回值
        const result = await preferences.get<number>(key, defaultValue);
        return result;
      }
      return defaultValue;
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to get number for key: ' + key, error.message);
      return defaultValue;
    }
  }

  /**
   * Stores boolean value | 存储布尔值
   * @param key Key | 键
   * @param value Value | 值
   */
  public static async putBoolean(key: string, value: boolean): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        await preferences.put(key, value);
        await preferences.flush();
      }
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to put boolean for key: ' + key, error.message);
    }
  }

  /**
   * Gets boolean value | 获取布尔值
   * @param key Key | 键
   * @param defaultValue Default value | 默认值
   * @returns Boolean value | 布尔值
   */
  public static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        // Explicitly type the return value | 显式类型化返回值
        const result = await preferences.get<boolean>(key, defaultValue);
        return result;
      }
      return defaultValue;
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to get boolean for key: ' + key, error.message);
      return defaultValue;
    }
  }

  /**
   * Stores value with automatic type detection | 自动类型检测存储值
   * @param key Key | 键
   * @param value Value | 值
   */
  public static async set(key: string, value: string | number | boolean): Promise<void> {
    try {
      if (typeof value === 'string') {
        await StorageUtil.putString(key, value);
      } else if (typeof value === 'number') {
        await StorageUtil.putNumber(key, value);
      } else if (typeof value === 'boolean') {
        await StorageUtil.putBoolean(key, value);
      }
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to set value for key: ' + key, error.message);
    }
  }

  /**
   * Removes storage item | 移除存储项
   * @param key Key | 键
   */
  public static async remove(key: string): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        await preferences.delete(key);
        await preferences.flush();
      }
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to remove key: ' + key, error.message);
    }
  }

  /**
   * Checks if storage item exists | 检查存储项是否存在
   * @param key Key | 键
   * @returns Exists | 是否存在
   */
  public static async contains(key: string): Promise<boolean> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        return await preferences.has(key);
      }
      return false;
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to check if key exists: ' + key, error.message);
      return false;
    }
  }

  /**
   * Clears all storage items | 清除所有存储项
   */
  public static async clear(): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        const allItems = await preferences.getAll() as Record<string, string | number | boolean>;
        // 确保allItems是对象类型
        if (typeof allItems === 'object' && allItems !== null) {
          // 使用Object.keys获取所有键
          const keyArray = Object.keys(allItems);
          for (let i = 0; i < keyArray.length; i++) {
            const key = keyArray[i];
            await preferences.delete(key);
          }
        }
        await preferences.flush();
      }
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to clear all preferences', error.message);
    }
  }

  /**
   * Gets object keys | 获取对象键
   * @param obj Object | 对象
   * @returns Array of keys | 键数组
   */
  private static getObjectKeys(obj: Record<string, string | number | boolean>): string[] {
    // 使用Object.keys替代for...in循环
    return Object.keys(obj);
  }

  /**
   * Gets all storage items | 获取所有存储项
   * @returns All storage items | 所有存储项
   */
  public static async getAll(): Promise<StorageItem> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        const result: StorageItem = {};
        // Explicitly type the return value | 显式类型化返回值
        const allItems = await preferences.getAll() as Record<string, string | number | boolean>;
        if (typeof allItems === 'object' && allItems !== null) {
          const keyArray = Object.keys(allItems);
          for (let i = 0; i < keyArray.length; i++) {
            const key = keyArray[i];
            const value = allItems[key];
            // 只保留字符串、数字和布尔值类型
            if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
              // 根据键名映射到 StorageItem 的具体属性
              switch (key) {
                case 'userId':
                  result.userId = value as string;
                  break;
                case 'appVersion':
                  result.appVersion = value as string;
                  break;
                case 'lastLaunchTime':
                  result.lastLaunchTime = value as number;
                  break;
                case 'themeMode':
                  result.themeMode = value as string;
                  break;
                case 'language':
                  result.language = value as string;
                  break;
                case 'autoPlay':
                  result.autoPlay = value as boolean;
                  break;
                case 'volumeLevel':
                  result.volumeLevel = value as number;
                  break;
                case 'brightnessLevel':
                  result.brightnessLevel = value as number;
                  break;
                case 'networkMode':
                  result.networkMode = value as string;
                  break;
                case 'cacheSize':
                  result.cacheSize = value as number;
                  break;
              }
            }
          }
        }
        return result;
      }
      return {};
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to get all preferences', error.message);
      return {};
    }
  }

  /**
   * Stores object value | 存储对象值
   * @param key Key | 键
   * @param value Value | 值
   */
  public static async setObject(key: string, value: StorageObject | null): Promise<void> {
    try {
      const jsonStr = value ? JSON.stringify(value) : '';
      await StorageUtil.putString(key, jsonStr);
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to put object for key: ' + key, error.message);
    }
  }

  /**
   * Gets object value | 获取对象值
   * @param key Key | 键
   * @returns Object value | 对象值
   */
  public static async getObject<T extends StorageObject>(key: string): Promise<T | null> {
    try {
      const jsonStr = await StorageUtil.getString(key);
      if (jsonStr) {
        // 安全的类型转换 | Safe type conversion
        const parsed: unknown = JSON.parse(jsonStr);
        // 验证类型安全 | Validate type safety
        if (typeof parsed === 'object' && parsed !== null) {
          // 使用类型守卫确保类型安全 | Use type guard to ensure type safety
          const safeParsed = parsed as Record<string, unknown>;
          const result: StorageObject = {};
          
          // 检查并转换 userInfo
          if (safeParsed.userInfo && typeof safeParsed.userInfo === 'object') {
            const userInfo = safeParsed.userInfo as Record<string, unknown>;
            if (userInfo.id && typeof userInfo.id === 'string' && userInfo.name && typeof userInfo.name === 'string') {
              result.userInfo = {
                id: userInfo.id,
                name: userInfo.name,
                avatar: userInfo.avatar as string
              };
            }
          }
          
          // 检查并转换 appSettings
          if (safeParsed.appSettings && typeof safeParsed.appSettings === 'object') {
            const appSettings = safeParsed.appSettings as Record<string, unknown>;
            if (appSettings.theme && typeof appSettings.theme === 'string' && appSettings.language && typeof appSettings.language === 'string') {
              result.appSettings = {
                theme: appSettings.theme,
                language: appSettings.language,
                notifications: appSettings.notifications as boolean || false
              };
            }
          }
          
          // 检查并转换 mediaSettings
          if (safeParsed.mediaSettings && typeof safeParsed.mediaSettings === 'object') {
            const mediaSettings = safeParsed.mediaSettings as Record<string, unknown>;
            if (mediaSettings.defaultQuality && typeof mediaSettings.defaultQuality === 'string') {
              result.mediaSettings = {
                autoPlay: mediaSettings.autoPlay as boolean || false,
                defaultQuality: mediaSettings.defaultQuality,
                subtitleEnabled: mediaSettings.subtitleEnabled as boolean || false
              };
            }
          }
          
          // 检查并转换 networkSettings
          if (safeParsed.networkSettings && typeof safeParsed.networkSettings === 'object') {
            const networkSettings = safeParsed.networkSettings as Record<string, unknown>;
            if (networkSettings.mode && typeof networkSettings.mode === 'string') {
              result.networkSettings = {
                mode: networkSettings.mode,
                timeout: networkSettings.timeout as number || 0,
                retryCount: networkSettings.retryCount as number || 0
              };
            }
          }
          
          return result as T;
        }
      }
      return null;
    } catch (error: Error) {
      console.error(StorageUtil.TAG + ': Failed to get object for key: ' + key, error.message);
      return null;
    }
  }
}

export default StorageUtil;
