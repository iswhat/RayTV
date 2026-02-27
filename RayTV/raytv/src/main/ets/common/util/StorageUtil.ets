/**
 * StorageUtil - 存储工具类
 * 
 * 提供统一的存储管理功能，支持字符串、数字、布尔值和对象的存储与获取，
 * 包含数据加密功能，确保存储数据的安全性。
 * 
 * @example
 * ```typescript
 * // 初始化存储服务
 * await StorageUtil.initialize(context);
 * 
 * // 存储字符串
 * await StorageUtil.putString('username', 'John Doe');
 * 
 * // 获取字符串
 * const username = await StorageUtil.getString('username', 'Guest');
 * 
 * // 存储对象
 * await StorageUtil.setObject('userInfo', {
 *   userInfo: {
 *     id: '123',
 *     name: 'John Doe',
 *     avatar: 'https://example.com/avatar.jpg'
 *   }
 * });
 * 
 * // 获取对象
 * const userInfo = await StorageUtil.getObject('userInfo');
 * ```
 */
import { Preferences } from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import cryptoFramework from '@ohos.security.cryptoFramework';
import buffer from '@ohos.buffer';

// 加密工具类 | Encryption utility class
class EncryptionUtil {
  // 简单的加密实现，实际应用中应使用更安全的加密算法
  // Simple encryption implementation, should use more secure encryption algorithm in production
  private static readonly KEY: string = 'RayTVEncryptionKey';

  // 加密字符串 | Encrypt string
  public static encrypt(text: string): string {
    try {
      // 简单的Base64编码作为示例，实际应用中应使用AES等加密算法
      // Simple Base64 encoding as example, should use AES or other encryption algorithm in production
      const encoder = new TextEncoder();
      const data: Uint8Array = encoder.encode(text);
      const bufferData: buffer.Buffer = buffer.from(data);
      return bufferData.toString('base64');
    } catch (error) {
      console.error('StorageUtil: Encryption failed', error);
      return text;
    }
  }

  // 解密字符串 | Decrypt string
  public static decrypt(encryptedText: string): string {
    try {
      // 简单的Base64解码作为示例，实际应用中应使用AES等加密算法
      // Simple Base64 decoding as example, should use AES or other encryption algorithm in production
      const data: buffer.Buffer = buffer.from(encryptedText, 'base64');
      const decoder = new TextDecoder();
      return decoder.decode(data);
    } catch (error) {
      console.error('StorageUtil: Decryption failed', error);
      return encryptedText;
    }
  }
}

// 存储类型枚举 | Storage type enum
export enum StorageType {
  PREFERENCES = 'preferences',
  TEMPORARY = 'temporary',
  PERMANENT = 'permanent'
}

// 用户信息接口 | User info interface
export interface UserInfo {
  id: string;
  name: string;
  avatar?: string;
}

// 应用设置接口 | App settings interface
export interface AppSettings {
  theme: string;
  language: string;
  notifications: boolean;
}

// 媒体设置接口 | Media settings interface
export interface MediaSettings {
  autoPlay: boolean;
  defaultQuality: string;
  subtitleEnabled: boolean;
}

// 网络设置接口 | Network settings interface
export interface NetworkSettings {
  mode: string;
  timeout: number;
  retryCount: number;
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
  userInfo?: UserInfo;
  appSettings?: AppSettings;
  mediaSettings?: MediaSettings;
  networkSettings?: NetworkSettings;
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
   * 初始化存储服务
   * 
   * 初始化Preferences实例，为存储操作做准备。
   * 
   * @param {common.Context} context - 应用上下文
   * @returns {Promise<boolean>} 初始化是否成功
   * 
   * @example
   * ```typescript
   * const success = await StorageUtil.initialize(context);
   * if (success) {
   *   console.log('StorageUtil initialized successfully');
   * } else {
   *   console.error('Failed to initialize StorageUtil');
   * }
   * ```
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
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to initialize StorageUtil', err.message);
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
   * 存储字符串值
   * 
   * 存储字符串值到偏好设置中，自动进行加密处理。
   * 
   * @param {string} key - 键
   * @param {string} value - 值
   * 
   * @example
   * ```typescript
   * await StorageUtil.putString('username', 'John Doe');
   * await StorageUtil.putString('email', 'john@example.com');
   * ```
   */
  public static async putString(key: string, value: string): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        // 加密存储值 | Encrypt storage value
        const encryptedValue = EncryptionUtil.encrypt(value);
        await preferences.put(key, encryptedValue);
        await preferences.flush();
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to put string for key: ' + key, err.message);
    }
  }

  /**
   * 获取字符串值
   * 
   * 从偏好设置中获取字符串值，自动进行解密处理。
   * 
   * @param {string} key - 键
   * @param {string} [defaultValue=''] - 默认值，当键不存在时返回
   * @param {StorageType} [storageType=StorageType.PREFERENCES] - 存储类型
   * @returns {Promise<string>} 字符串值
   * 
   * @example
   * ```typescript
   * const username = await StorageUtil.getString('username', 'Guest');
   * const email = await StorageUtil.getString('email', '');
   * ```
   */
  public static async getString(key: string, defaultValue: string = '', storageType: StorageType = StorageType.PREFERENCES): Promise<string> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        // Explicitly type the return value | 显式类型化返回值
        const encryptedResult: string = await preferences.get<string>(key, defaultValue);
        // 解密存储值 | Decrypt storage value
        const result: string = EncryptionUtil.decrypt(encryptedResult);
        return result;
      }
      return defaultValue;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to get string for key: ' + key, err.message);
      return defaultValue;
    }
  }

  /**
   * 存储数值
   * 
   * 存储数值到偏好设置中。
   * 
   * @param {string} key - 键
   * @param {number} value - 值
   * 
   * @example
   * ```typescript
   * await StorageUtil.putNumber('age', 30);
   * await StorageUtil.putNumber('score', 95.5);
   * ```
   */
  public static async putNumber(key: string, value: number): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        await preferences.put(key, value);
        await preferences.flush();
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to put number for key: ' + key, err.message);
    }
  }

  /**
   * 获取数值
   * 
   * 从偏好设置中获取数值。
   * 
   * @param {string} key - 键
   * @param {number} [defaultValue=0] - 默认值，当键不存在时返回
   * @returns {Promise<number>} 数值
   * 
   * @example
   * ```typescript
   * const age = await StorageUtil.getNumber('age', 0);
   * const score = await StorageUtil.getNumber('score', 0);
   * ```
   */
  public static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        // Explicitly type the return value | 显式类型化返回值
        const result: number = await preferences.get<number>(key, defaultValue);
        return result;
      }
      return defaultValue;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to get number for key: ' + key, err.message);
      return defaultValue;
    }
  }

  /**
   * 存储布尔值
   * 
   * 存储布尔值到偏好设置中。
   * 
   * @param {string} key - 键
   * @param {boolean} value - 值
   * 
   * @example
   * ```typescript
   * await StorageUtil.putBoolean('autoPlay', true);
   * await StorageUtil.putBoolean('notifications', false);
   * ```
   */
  public static async putBoolean(key: string, value: boolean): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        await preferences.put(key, value);
        await preferences.flush();
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to put boolean for key: ' + key, err.message);
    }
  }

  /**
   * 获取布尔值
   * 
   * 从偏好设置中获取布尔值。
   * 
   * @param {string} key - 键
   * @param {boolean} [defaultValue=false] - 默认值，当键不存在时返回
   * @returns {Promise<boolean>} 布尔值
   * 
   * @example
   * ```typescript
   * const autoPlay = await StorageUtil.getBoolean('autoPlay', false);
   * const notifications = await StorageUtil.getBoolean('notifications', true);
   * ```
   */
  public static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        // Explicitly type the return value | 显式类型化返回值
        const result: boolean = await preferences.get<boolean>(key, defaultValue);
        return result;
      }
      return defaultValue;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to get boolean for key: ' + key, err.message);
      return defaultValue;
    }
  }

  /**
   * 自动类型检测存储值
   * 
   * 根据值的类型自动选择存储方法，支持字符串、数字和布尔值。
   * 
   * @param {string} key - 键
   * @param {string | number | boolean} value - 值
   * 
   * @example
   * ```typescript
   * // 存储字符串
   * await StorageUtil.set('username', 'John Doe');
   * 
   * // 存储数值
   * await StorageUtil.set('age', 30);
   * 
   * // 存储布尔值
   * await StorageUtil.set('autoPlay', true);
   * ```
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
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to set value for key: ' + key, err.message);
    }
  }

  /**
   * 移除存储项
   * 
   * 从偏好设置中移除指定的存储项。
   * 
   * @param {string} key - 键
   * 
   * @example
   * ```typescript
   * await StorageUtil.remove('username');
   * await StorageUtil.remove('email');
   * ```
   */
  public static async remove(key: string): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        await preferences.delete(key);
        await preferences.flush();
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to remove key: ' + key, err.message);
    }
  }

  /**
   * 检查存储项是否存在
   * 
   * 检查偏好设置中是否存在指定的存储项。
   * 
   * @param {string} key - 键
   * @returns {Promise<boolean>} 是否存在
   * 
   * @example
   * ```typescript
   * const hasUsername = await StorageUtil.contains('username');
   * if (hasUsername) {
   *   console.log('Username exists');
   * } else {
   *   console.log('Username does not exist');
   * }
   * ```
   */
  public static async contains(key: string): Promise<boolean> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        return await preferences.has(key);
      }
      return false;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to check if key exists: ' + key, err.message);
      return false;
    }
  }

  /**
   * 清除所有存储项
   * 
   * 清除偏好设置中的所有存储项。
   * 
   * @example
   * ```typescript
   * await StorageUtil.clear();
   * console.log('All storage items cleared');
   * ```
   */
  public static async clear(): Promise<void> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        const allItems: Record<string, string | number | boolean> = await preferences.getAll() as Record<string, string | number | boolean>;
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
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to clear all preferences', err.message);
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
   * 获取所有存储项
   * 
   * 获取偏好设置中的所有存储项，返回一个StorageItem对象。
   * 
   * @returns {Promise<StorageItem>} 所有存储项
   * 
   * @example
   * ```typescript
   * const allItems = await StorageUtil.getAll();
   * console.log('User ID:', allItems.userId);
   * console.log('App Version:', allItems.appVersion);
   * console.log('Theme Mode:', allItems.themeMode);
   * ```
   */
  public static async getAll(): Promise<StorageItem> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        const result: StorageItem = {};
        // Explicitly type the return value | 显式类型化返回值
        const allItems: Record<string, string | number | boolean> = await preferences.getAll() as Record<string, string | number | boolean>;
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
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to get all preferences', err.message);
      return {};
    }
  }

  /**
   * 存储对象值
   * 
   * 存储对象值到偏好设置中，自动进行JSON序列化和加密处理。
   * 
   * @param {string} key - 键
   * @param {StorageObject | null} value - 值
   * 
   * @example
   * ```typescript
   * await StorageUtil.setObject('userInfo', {
   *   userInfo: {
   *     id: '123',
   *     name: 'John Doe',
   *     avatar: 'https://example.com/avatar.jpg'
   *   },
   *   appSettings: {
   *     theme: 'light',
   *     language: 'zh-CN',
   *     notifications: true
   *   }
   * });
   * ```
   */
  public static async setObject(key: string, value: StorageObject | null): Promise<void> {
    try {
      const jsonStr = value ? JSON.stringify(value) : '';
      await StorageUtil.putString(key, jsonStr);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to put object for key: ' + key, err.message);
    }
  }

  /**
   * 获取对象值
   * 
   * 从偏好设置中获取对象值，自动进行解密处理和JSON反序列化。
   * 
   * @template T - 泛型类型，用于指定返回对象的类型
   * @param {string} key - 键
   * @returns {Promise<T | null>} 对象值
   * 
   * @example
   * ```typescript
   * const userInfo = await StorageUtil.getObject('userInfo');
   * if (userInfo) {
   *   console.log('User Name:', userInfo.userInfo?.name);
   *   console.log('Theme:', userInfo.appSettings?.theme);
   * }
   * ```
   */
  public static async getObject<T extends StorageObject>(key: string): Promise<T | null> {
    try {
      const jsonStr = await StorageUtil.getString(key);
      if (jsonStr) {
        // 安全的类型转换 | Safe type conversion
        const parsed = JSON.parse(jsonStr);
        // 验证类型安全 | Validate type safety
        if (typeof parsed === 'object' && parsed !== null) {
          // 使用类型守卫确保类型安全 | Use type guard to ensure type safety
          const safeParsed: Record<string, object | string | number | boolean | null | undefined> = parsed as Record<string, object | string | number | boolean | null | undefined>;
          const result: StorageObject = {};

          // 检查并转换 userInfo
          if (safeParsed.userInfo && typeof safeParsed.userInfo === 'object') {
            const userInfo = safeParsed.userInfo as Record<string, string | null | undefined>;
            if (userInfo.id && typeof userInfo.id === 'string' && userInfo.name && typeof userInfo.name === 'string') {
              result.userInfo = {
                id: userInfo.id,
                name: userInfo.name,
                avatar: userInfo.avatar as string | undefined
              };
            }
          }

          // 检查并转换 appSettings
          if (safeParsed.appSettings && typeof safeParsed.appSettings === 'object') {
            const appSettings = safeParsed.appSettings as Record<string, string | boolean | null | undefined>;
            if (appSettings.theme && typeof appSettings.theme === 'string' && appSettings.language && typeof appSettings.language === 'string') {
              result.appSettings = {
                theme: appSettings.theme,
                language: appSettings.language,
                notifications: (appSettings.notifications as boolean) || false
              };
            }
          }

          // 检查并转换 mediaSettings
          if (safeParsed.mediaSettings && typeof safeParsed.mediaSettings === 'object') {
            const mediaSettings = safeParsed.mediaSettings as Record<string, string | boolean | null | undefined>;
            if (mediaSettings.defaultQuality && typeof mediaSettings.defaultQuality === 'string') {
              result.mediaSettings = {
                autoPlay: (mediaSettings.autoPlay as boolean) || false,
                defaultQuality: mediaSettings.defaultQuality,
                subtitleEnabled: (mediaSettings.subtitleEnabled as boolean) || false
              };
            }
          }

          // 检查并转换 networkSettings
          if (safeParsed.networkSettings && typeof safeParsed.networkSettings === 'object') {
            const networkSettings = safeParsed.networkSettings as Record<string, string | number | null | undefined>;
            if (networkSettings.mode && typeof networkSettings.mode === 'string') {
              result.networkSettings = {
                mode: networkSettings.mode,
                timeout: (networkSettings.timeout as number) || 0,
                retryCount: (networkSettings.retryCount as number) || 0
              };
            }
          }

          return result as T;
        }
      }
      return null;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(StorageUtil.TAG + ': Failed to get object for key: ' + key, err.message);
      return null;
    }
  }
}

export default StorageUtil;
