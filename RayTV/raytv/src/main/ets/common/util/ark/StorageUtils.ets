// StorageUtils.ets - ArkTS兼容的存储工具函数

/**
 * 存储工具函数
 * 提供ArkTS环境中安全的数据持久化操作功能
 */
import { Optional, SafeAny } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';
import StringUtils from './StringUtils';

/**
 * 存储工具函数集合
 */
export const StorageUtils = {
  /**
   * 检查是否支持本地存储
   */
  isSupported(): boolean {
    try {
      // 检查是否存在localStorage对象
      return typeof localStorage !== 'undefined';
    } catch (e) {
      return false;
    }
  },

  /**
   * 设置存储项
   */
  setItem(key: string, value: SafeAny): boolean {
    if (!StorageUtils.isSupported() || StringUtils.isEmpty(key)) {
      return false;
    }
    
    try {
      const stringValue = TypeUtils.isString(value) ? value : JSON.stringify(value);
      localStorage.setItem(key, stringValue);
      return true;
    } catch (e) {
      console.error('StorageUtils.setItem error:', e);
      return false;
    }
  },

  /**
   * 获取存储项
   */
  getItem<T = string>(key: string): T | null {
    if (!StorageUtils.isSupported() || StringUtils.isEmpty(key)) {
      return null;
    }
    
    try {
      const value = localStorage.getItem(key);
      
      if (value === null) {
        return null;
      }
      
      // 尝试解析JSON，如果失败则返回原始字符串
      try {
        return JSON.parse(value) as T;
      } catch {
        return value as unknown as T;
      }
    } catch (e) {
      console.error('StorageUtils.getItem error:', e);
      return null;
    }
  },

  /**
   * 获取字符串类型存储项
   */
  getString(key: string): string | null {
    return StorageUtils.getItem<string>(key);
  },

  /**
   * 获取数字类型存储项
   */
  getNumber(key: string): number | null {
    const value = StorageUtils.getItem(key);
    return TypeUtils.isNumber(value) ? value : null;
  },

  /**
   * 获取布尔类型存储项
   */
  getBoolean(key: string): boolean | null {
    const value = StorageUtils.getItem(key);
    return TypeUtils.isBoolean(value) ? value : null;
  },

  /**
   * 获取对象类型存储项
   */
  getObject<T>(key: string): T | null {
    const value = StorageUtils.getItem<T>(key);
    return TypeUtils.isObject(value) ? value : null;
  },

  /**
   * 获取数组类型存储项
   */
  getArray<T>(key: string): T[] | null {
    const value = StorageUtils.getItem<T[]>(key);
    return Array.isArray(value) ? value : null;
  },

  /**
   * 移除存储项
   */
  removeItem(key: string): boolean {
    if (!StorageUtils.isSupported() || StringUtils.isEmpty(key)) {
      return false;
    }
    
    try {
      localStorage.removeItem(key);
      return true;
    } catch (e) {
      console.error('StorageUtils.removeItem error:', e);
      return false;
    }
  },

  /**
   * 清空所有存储项
   */
  clear(): boolean {
    if (!StorageUtils.isSupported()) {
      return false;
    }
    
    try {
      localStorage.clear();
      return true;
    } catch (e) {
      console.error('StorageUtils.clear error:', e);
      return false;
    }
  },

  /**
   * 检查是否存在指定的存储项
   */
  hasItem(key: string): boolean {
    if (!StorageUtils.isSupported() || StringUtils.isEmpty(key)) {
      return false;
    }
    
    try {
      return localStorage.getItem(key) !== null;
    } catch (e) {
      console.error('StorageUtils.hasItem error:', e);
      return false;
    }
  },

  /**
   * 获取存储项数量
   */
  getLength(): number {
    if (!StorageUtils.isSupported()) {
      return 0;
    }
    
    try {
      return localStorage.length;
    } catch (e) {
      console.error('StorageUtils.getLength error:', e);
      return 0;
    }
  },

  /**
   * 获取指定索引位置的存储项键名
   */
  getKey(index: number): string | null {
    if (!StorageUtils.isSupported() || !TypeUtils.isNumber(index) || index < 0) {
      return null;
    }
    
    try {
      return localStorage.key(index);
    } catch (e) {
      console.error('StorageUtils.getKey error:', e);
      return null;
    }
  },

  /**
   * 获取所有存储项的键名列表
   */
  getAllKeys(): string[] {
    const keys: string[] = [];
    
    if (!StorageUtils.isSupported()) {
      return keys;
    }
    
    try {
      const length = localStorage.length;
      
      for (let i = 0; i < length; i++) {
        const key = localStorage.key(i);
        if (key) {
          keys.push(key);
        }
      }
    } catch (e) {
      console.error('StorageUtils.getAllKeys error:', e);
    }
    
    return keys;
  },

  /**
   * 获取所有存储项
   */
  getAllItems(): Record<string, SafeAny> {
    const items: Record<string, SafeAny> = {};
    
    if (!StorageUtils.isSupported()) {
      return items;
    }
    
    try {
      const keys = StorageUtils.getAllKeys();
      
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        items[key] = StorageUtils.getItem(key);
      }
    } catch (e) {
      console.error('StorageUtils.getAllItems error:', e);
    }
    
    return items;
  },

  /**
   * 批量设置存储项
   */
  setMultiple(items: Record<string, SafeAny>): boolean {
    if (!StorageUtils.isSupported() || !TypeUtils.isObject(items)) {
      return false;
    }
    
    try {
      const keys = Object.keys(items);
      let success = true;
      
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = items[key];
        
        if (!StorageUtils.setItem(key, value)) {
          success = false;
        }
      }
      
      return success;
    } catch (e) {
      console.error('StorageUtils.setMultiple error:', e);
      return false;
    }
  },

  /**
   * 批量获取存储项
   */
  getMultiple(keys: string[]): Record<string, SafeAny> {
    const items: Record<string, SafeAny> = {};
    
    if (!StorageUtils.isSupported() || !Array.isArray(keys)) {
      return items;
    }
    
    try {
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (StringUtils.isNotEmpty(key)) {
          items[key] = StorageUtils.getItem(key);
        }
      }
    } catch (e) {
      console.error('StorageUtils.getMultiple error:', e);
    }
    
    return items;
  },

  /**
   * 批量移除存储项
   */
  removeMultiple(keys: string[]): boolean {
    if (!StorageUtils.isSupported() || !Array.isArray(keys)) {
      return false;
    }
    
    try {
      let success = true;
      
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (!StorageUtils.removeItem(key)) {
          success = false;
        }
      }
      
      return success;
    } catch (e) {
      console.error('StorageUtils.removeMultiple error:', e);
      return false;
    }
  },

  /**
   * 获取存储使用情况（近似值）
   */
  getStorageUsage(): number {
    if (!StorageUtils.isSupported()) {
      return 0;
    }
    
    try {
      let size = 0;
      const keys = StorageUtils.getAllKeys();
      
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = localStorage.getItem(key);
        
        if (value) {
          // 估算字符串大小（UTF-16编码，每个字符2字节）
          size += (key.length + value.length) * 2;
        }
      }
      
      return size; // 返回字节数
    } catch (e) {
      console.error('StorageUtils.getStorageUsage error:', e);
      return 0;
    }
  },

  /**
   * 创建带命名空间的存储键
   */
  createNamespacedKey(namespace: string, key: string): string {
    if (StringUtils.isEmpty(namespace)) {
      return key;
    }
    
    return `${namespace}.${key}`;
  },

  /**
   * 创建命名空间存储
   */
  createNamespacedStorage(namespace: string): typeof StorageUtils {
    if (StringUtils.isEmpty(namespace)) {
      return StorageUtils;
    }
    
    const createNamespacedMethod = (originalMethod: Function) => {
      return function(this: typeof StorageUtils, ...args: SafeAny[]) {
        // 如果第一个参数是字符串键名，则添加命名空间
        if (args.length > 0 && TypeUtils.isString(args[0])) {
          args[0] = StorageUtils.createNamespacedKey(namespace, args[0]);
        }
        
        return originalMethod.apply(this, args);
      };
    };
    
    return {
      ...StorageUtils,
      setItem: createNamespacedMethod(StorageUtils.setItem),
      getItem: createNamespacedMethod(StorageUtils.getItem),
      getString: createNamespacedMethod(StorageUtils.getString),
      getNumber: createNamespacedMethod(StorageUtils.getNumber),
      getBoolean: createNamespacedMethod(StorageUtils.getBoolean),
      getObject: createNamespacedMethod(StorageUtils.getObject),
      getArray: createNamespacedMethod(StorageUtils.getArray),
      removeItem: createNamespacedMethod(StorageUtils.removeItem),
      hasItem: createNamespacedMethod(StorageUtils.hasItem)
    };
  }
};

export default StorageUtils;
