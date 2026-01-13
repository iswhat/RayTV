// ObjectUtils.ets - ArkTS兼容的对象工具函数 ArkTS compatible object utility functions

/**
 * 对象工具函数 Object utility functions
 * 提供ArkTS环境中安全的对象操作功能 Provides safe object operation functionality in ArkTS environment
 */
import { SafeAny, SafeObject, Optional } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';

/**
 * 对象工具函数集合 Object utility functions collection
 */
export const ObjectUtils = {
  /**
   * 安全地检查对象是否包含指定属性 Safely checks if object contains specified property
   * 替代Object.prototype.hasOwnProperty.call Replaces Object.prototype.hasOwnProperty.call
   */
  hasProperty(obj: SafeAny, key: string | number): boolean {
    if (!TypeUtils.isObject(obj)) {
      return false;
    }
    
    const keyStr = String(key);
    // 使用Object.getOwnPropertyNames获取所有自有属性并检查，避免使用in操作符和hasOwnProperty Uses Object.getOwnPropertyNames to get all own properties and check, avoiding in operator and hasOwnProperty
    return Object.getOwnPropertyNames(obj).includes(keyStr);
  },

  /**
   * 获取对象的所有键 Gets all keys of object
   * 替代Object.keys Replaces Object.keys
   */
  getKeys(obj: SafeAny): string[] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
    
    return Object.getOwnPropertyNames(obj);
  },

  /**
   * 获取对象的所有值 Gets all values of object
   * 替代Object.values Replaces Object.values
   */
  getValues<T>(obj: SafeAny): T[] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
    
    const values: T[] = [];
    const keys = ObjectUtils.getKeys(obj);
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // 使用类型安全的属性访问方式 Uses type-safe property access method
      const propertyValue = ObjectUtils.getPropertyValue(obj, key);
      values.push(propertyValue as T);
    }
    
    return values;
  },

  /**
   * 获取对象的所有键值对 Gets all key-value pairs of object
   * 替代Object.entries Replaces Object.entries
   */
  getEntries<T>(obj: SafeAny): [string, T][] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
    
    const entries: [string, T][] = [];
    const keys = ObjectUtils.getKeys(obj);
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // 使用类型安全的属性访问方式 Uses type-safe property access method
      const propertyValue = ObjectUtils.getPropertyValue(obj, key);
      entries.push([key, propertyValue as T]);
    }
    
    return entries;
  },

  /**
   * 从对象中获取属性值，如果属性不存在则返回默认值 Gets property value from object, returns default value if property doesn't exist
   */
  getProperty<T>(obj: SafeAny, key: string | number, defaultValue: T): T {
    if (!TypeUtils.isObject(obj) || !ObjectUtils.hasProperty(obj, key)) {
      return defaultValue;
    }
    
    const keyStr = String(key);
    // 使用类型安全的属性访问方式 Uses type-safe property access method
    const propertyValue = ObjectUtils.getPropertyValue(obj, keyStr);
    return propertyValue as T;
  },

  /**
   * 安全地设置对象属性 Safely sets object property
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
   * 安全地删除对象属性 Safely deletes object property
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
   * 安全地获取对象属性值 Safely gets object property value
   * @param obj - Object to get property from
   * @param key - Property key
   * @returns Property value, undefined if property doesn't exist
   */
  getPropertyValue(obj: SafeAny, key: string | number): SafeAny {
    if (!TypeUtils.isObject(obj)) {
      return undefined;
    }
    
    const keyStr = String(key);
    if (!ObjectUtils.hasProperty(obj, keyStr)) {
      return undefined;
    }
    
    // 使用类型安全的属性访问方式 Uses type-safe property access method
    const safeObj = obj as Record<string, SafeAny>;
    return safeObj[keyStr];
  },

  /**
   * 合并多个对象 Merges multiple objects
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
   * 深度克隆对象 Deep clones object
   */
  deepClone<T>(value: T): T {
    // 处理null和undefined Handles null and undefined
    if (value === null || value === undefined) {
      return value;
    }
    
    // 处理基本类型 Handles basic types
    if (typeof value !== 'object') {
      return value;
    }
    
    // 处理日期 Handles Date
    if (value instanceof Date) {
      return new Date(value.getTime()) as T;
    }
    
    // 处理数组 Handles array
    if (Array.isArray(value)) {
      const clonedArray: Record<string, string | number | boolean | null>[] = [];
      for (let i = 0; i < value.length; i++) {
        clonedArray.push(ObjectUtils.deepClone(value[i]));
      }
      return clonedArray as T;
    }
    
    // 处理普通对象 Handles regular object
    const cloned: Record<string, unknown> = {};
    const entries = ObjectUtils.getEntries(value as Record<string, unknown>);
    
    for (let i = 0; i < entries.length; i++) {
      const [key, val] = entries[i];
      cloned[key] = ObjectUtils.deepClone(val);
    }
    
    return cloned as T;
  },

  /**
   * 创建对象的浅克隆 Creates shallow clone of object
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
   * 过滤对象的属性 Filters object properties
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
   * 转换对象的属性 Transforms object properties
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





