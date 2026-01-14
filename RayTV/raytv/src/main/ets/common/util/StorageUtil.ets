/**
 * StorageUtil - Storage utility class | 存储工具类
 * Provides unified storage management functionality | 提供统一的存储管理功能
 */
import { Preferences } from '@ohos.data.preferences';
import { GlobalContext } from '../base/GlobalContext';
import Logger from './Logger';
import common from '@ohos.app.ability.common';

export class StorageUtil {
  private static readonly TAG: string = 'StorageUtil';
  private static preferences: Preferences | null = null;
  private static readonly PREFERENCES_NAME: string = 'raytv_preferences';

  /**
   * Initialize storage service | 初始化存储服务
   */
  public static async initialize(): Promise<boolean> {
    try {
      const context: common.Context | null = GlobalContext.getInstance().getContext();
      if (!context) {
        Logger.error(StorageUtil.TAG, 'Failed to get context for preferences');
        return false;
      }

      StorageUtil.preferences = await Preferences.getPreferences(context, StorageUtil.PREFERENCES_NAME);
      Logger.info(StorageUtil.TAG, 'StorageUtil initialized successfully');
      return true;
    } catch (error) {
      Logger.error(StorageUtil.TAG, 'Failed to initialize StorageUtil', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * Get preferences instance | 获取偏好设置实例
   * @returns Preferences instance | 偏好设置实例
   */
  private static getPreferences(): Preferences | null {
    if (!StorageUtil.preferences) {
      Logger.warn(StorageUtil.TAG, 'StorageUtil not initialized');
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
    } catch (error) {
      Logger.error(StorageUtil.TAG, `Failed to put string for key: ${key}`, error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * Gets string value | 获取字符串值
   * @param key Key | 键
   * @param defaultValue Default value | 默认值
   * @returns String value | 字符串值
   */
  public static async getString(key: string, defaultValue: string = ''): Promise<string> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        const value = await preferences.get(key, defaultValue);
        return typeof value === 'string' ? value : defaultValue;
      }
      return defaultValue;
    } catch (error) {
      Logger.error(StorageUtil.TAG, `Failed to get string for key: ${key}`, error instanceof Error ? error : new Error(String(error)));
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
    } catch (error) {
      Logger.error(StorageUtil.TAG, `Failed to put number for key: ${key}`, error instanceof Error ? error : new Error(String(error)));
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
        return await preferences.get(key, defaultValue) as number;
      }
      return defaultValue;
    } catch (error) {
      Logger.error(StorageUtil.TAG, `Failed to get number for key: ${key}`, error instanceof Error ? error : new Error(String(error)));
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
    } catch (error) {
      Logger.error(StorageUtil.TAG, `Failed to put boolean for key: ${key}`, error instanceof Error ? error : new Error(String(error)));
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
        return await preferences.get(key, defaultValue) as boolean;
      }
      return defaultValue;
    } catch (error) {
      Logger.error(StorageUtil.TAG, `Failed to get boolean for key: ${key}`, error instanceof Error ? error : new Error(String(error)));
      return defaultValue;
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
    } catch (error) {
      Logger.error(StorageUtil.TAG, `Failed to remove key: ${key}`, error instanceof Error ? error : new Error(String(error)));
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
    } catch (error) {
      Logger.error(StorageUtil.TAG, `Failed to check if key exists: ${key}`, error instanceof Error ? error : new Error(String(error)));
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
        const keys = await preferences.getAll() as Record<string, string | number | boolean>;
        const keyArray = Object.keys(keys);
        for (let i = 0; i < keyArray.length; i++) {
          const key = keyArray[i];
          await preferences.delete(key);
        }
        await preferences.flush();
      }
    } catch (error) {
      Logger.error(StorageUtil.TAG, 'Failed to clear all preferences', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * Gets all storage items | 获取所有存储项
   * @returns All storage items | 所有存储项
   */
  public static async getAll(): Promise<Record<string, string | number | boolean>> {
    try {
      const preferences = StorageUtil.getPreferences();
      if (preferences) {
        return await preferences.getAll() as Record<string, string | number | boolean>;
      }
      return {};
    } catch (error) {
      Logger.error(StorageUtil.TAG, 'Failed to get all preferences', error instanceof Error ? error : new Error(String(error)));
      return {};
    }
  }
}

export default StorageUtil;
