// ObjectUtils.ets - ArkTS兼容的对象工具函�?

/**
 * 对象工具函数
 * 提供ArkTS环境中安全的对象操作功能
 */
import { SafeAny, SafeObject, Optional } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';

/**
 * 对象工具函数集合
 */
export const ObjectUtils = {
  /**
   * 安全地检查对象是否包含指定属�?
   * 替代Object.prototype.hasOwnProperty.call
   */
  hasProperty(obj: SafeAny, key: string | number): boolean {
    if (!TypeUtils.isObject(obj)) {
      return false;
    }
    
    const keyStr = String(key);
    // 使用Object.getOwnPropertyNames获取所有自有属性并检查，避免使用in操作符和hasOwnProperty
    return Object.getOwnPropertyNames(obj).includes(keyStr);
  },

  /**
   * 获取对象的所有键
   * 替代Object.keys
   */
  getKeys(obj: SafeAny): string[] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
    
    return Object.getOwnPropertyNames(obj);
  },

  /**
   * 获取对象的所有�?
   * 替代Object.values
   */
  getValues<T>(obj: SafeAny): T[] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
    
    const values: T[] = [];
    const keys = ObjectUtils.getKeys(obj);
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // 使用类型安全的属性访问方�?
      const propertyValue = ObjectUtils.getPropertyValue(obj, key);
      values.push(propertyValue as T);
    }
    
    return values;
  },

  /**
   * 获取对象的所有键值对
   * 替代Object.entries
   */
  getEntries<T>(obj: SafeAny): [string, T][] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
    
    const entries: [string, T][] = [];
    const keys = ObjectUtils.getKeys(obj);
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // 使用类型安全的属性访问方�?
      const propertyValue = ObjectUtils.getPropertyValue(obj, key);
      entries.push([key, propertyValue as T]);
    }
    
    return entries;
  },

  /**
   * 从对象中获取属性值，如果属性不存在则返回默认�?
   */
  getProperty<T>(obj: SafeAny, key: string | number, defaultValue: T): T {
    if (!TypeUtils.isObject(obj) || !ObjectUtils.hasProperty(obj, key)) {
      return defaultValue;
    }
    
    const keyStr = String(key);
    // 使用类型安全的属性访问方�?
    const propertyValue = ObjectUtils.getPropertyValue(obj, keyStr);
    return propertyValue as T;
  },

  /**
   * 安全地设置对象属�?
   */
  setProperty(obj: SafeAny, key: string | number, value: SafeAny): boolean {
    if (!TypeUtils.isObject(obj)) {
      return false;
    }
    
    try {
      const keyStr = String(key);
      (obj as Record<string, SafeAny>)[keyStr] = value;
      return true;
    } catch {
      return false;
    }
  },

  /**
   * 安全地删除对象属�?
   */
  deleteProperty(obj: SafeAny, key: string | number): boolean {
    if (!TypeUtils.isObject(obj) || !ObjectUtils.hasProperty(obj, key)) {
      return false;
    }
    
    try {
      const keyStr = String(key);
      delete (obj as Record<string, SafeAny>)[keyStr];
      return true;
    } catch {
      return false;
    }
  },

  /**
   * 安全地获取对象属性�?
   * @param obj - 要获取属性的对象
   * @param key - 属性键�?
   * @returns 属性值，如果属性不存在则返回undefined
   */
  getPropertyValue(obj: SafeAny, key: string | number): Record<string, string | number | boolean | null> {
    if (!TypeUtils.isObject(obj)) {
      return undefined;
    }
    
    const keyStr = String(key);
    if (!ObjectUtils.hasProperty(obj, keyStr)) {
      return undefined;
    }
    
    // 使用类型安全的属性访问方�?
    const safeObj = obj as Record<string, unknown>;
    return safeObj[keyStr];
  },

  /**
   * 合并多个对象
   */
  merge<T extends SafeObject>(...objects: Optional<T>[]): T {
    const result: T = {} as T;
    
    for (let i = 0; i < objects.length; i++) {
      const obj = objects[i];
      if (TypeUtils.isObject(obj)) {
        const entries = ObjectUtils.getEntries(obj);
        
        for (let j = 0; j < entries.length; j++) {
          const [key, value] = entries[j];
          ObjectUtils.setProperty(result, key, value);
        }
      }
    }
    
    return result;
  },

  /**
   * 深拷贝对�?
   */
  deepClone<T>(value: T): T {
    // 处理null和undefined
    if (value === null || value === undefined) {
      return value;
    }
    
    // 处理基本类型
    if (typeof value !== 'object') {
      return value;
    }
    
    // 处理日期
    if (value instanceof Date) {
      return new Date(value.getTime()) as T;
    }
    
    // 处理数组
    if (Array.isArray(value)) {
      const clonedArray: Record<string, string | number | boolean | null>[] = [];
      for (let i = 0; i < value.length; i++) {
        clonedArray.push(ObjectUtils.deepClone(value[i]));
      }
      return clonedArray as T;
    }
    
    // 处理普通对�?
    const cloned: Record<string, unknown> = {};
    const entries = ObjectUtils.getEntries(value as Record<string, unknown>);
    
    for (let i = 0; i < entries.length; i++) {
      const [key, val] = entries[i];
      cloned[key] = ObjectUtils.deepClone(val);
    }
    
    return cloned as T;
  },

  /**
   * 创建对象的浅拷贝
   */
  shallowClone<T extends SafeObject>(obj: Optional<T>): T {
    if (!TypeUtils.isObject(obj)) {
      return {} as T;
    }
    
    const cloned: T = {} as T;
    const entries = ObjectUtils.getEntries(obj);
    
    for (let i = 0; i < entries.length; i++) {
      const [key, value] = entries[i];
      ObjectUtils.setProperty(cloned, key, value);
    }
    
    return cloned;
  },

  /**
   * 过滤对象的属�?
   */
  filter<T extends SafeObject>(
    obj: Optional<T>, 
    predicate: (key: string, value: SafeAny) => boolean
  ): Partial<T> {
    if (!TypeUtils.isObject(obj)) {
      return {};
    }
    
    const filtered: Partial<T> = {};
    const entries = ObjectUtils.getEntries(obj);
    
    for (let i = 0; i < entries.length; i++) {
      const [key, value] = entries[i];
      if (predicate(key, value)) {
        ObjectUtils.setProperty(filtered, key, value);
      }
    }
    
    return filtered;
  },

  /**
   * 转换对象的属�?
   */
  map<T extends SafeObject, R extends SafeObject>(
    obj: Optional<T>, 
    transform: (key: string, value: SafeAny) => [string, SafeAny]
  ): R {
    if (!TypeUtils.isObject(obj)) {
      return {} as R;
    }
    
    const result: R = {} as R;
    const entries = ObjectUtils.getEntries(obj);
    
    for (let i = 0; i < entries.length; i++) {
      const [key, value] = entries[i];
      const [newKey, newValue] = transform(key, value);
      ObjectUtils.setProperty(result, newKey, newValue);
    }
    
    return result;
  }
};

export default ObjectUtils;

