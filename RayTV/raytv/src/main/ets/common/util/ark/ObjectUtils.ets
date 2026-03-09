// ObjectUtils.ets - ArkTS兼容的对象工具函数 ArkTS compatible object utility functions

/**
 * 对象工具函数 Object utility functions
 * 提供ArkTS环境中安全的对象操作功能 Provides safe object operation functionality in ArkTS environment
 */
import { SafeAny, SafeObject, Optional } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';

/**
 * ObjectUtils接口 - 定义对象工具函数的类型
 * ObjectUtils interface - defines types for object utility functions
 */
export interface ObjectUtilsInterface {
  hasProperty(obj: SafeAny, key: string | number): boolean;
  getKeys(obj: SafeAny): string[];
  getValues<T>(obj: SafeAny): T[];
  getEntries<T>(obj: SafeAny): [string, T][];
  getProperty<T>(obj: SafeAny, key: string | number, defaultValue: T): T;
  setProperty(obj: SafeAny, key: string | number, value: SafeAny): boolean;
  deleteProperty(obj: SafeAny, key: string | number): boolean;
  getPropertyValue(obj: SafeAny, key: string | number): SafeAny;
  merge<T extends SafeObject>(...objects: Optional<T>[]): T;
  deepClone<T>(value: T): T;
  shallowClone<T extends SafeObject>(obj: Optional<T>): T;
  filter<T extends SafeObject>(obj: Optional<T>, predicate: (key: string, value: SafeAny) => boolean): Partial<T>;
  map<T extends SafeObject, R extends SafeObject>(obj: Optional<T>, transform: (key: string, value: SafeAny) => [string, SafeAny]): R;
}

/**
 * 对象工具函数集合 Object utility functions collection
 */
export class ObjectUtilsClass implements ObjectUtilsInterface {
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
  }

  /**
   * 获取对象的所有键 Gets all keys of object
   * 替代Object.keys Replaces Object.keys
   */
  getKeys(obj: SafeAny): string[] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
    
    return Object.getOwnPropertyNames(obj);
  }

  /**
   * 获取对象的所有值 Gets all values of object
   * 替代 Object.values Replaces Object.values
   */
  getValues<T>(obj: SafeAny): T[] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
      
    const values: T[] = [];
    const keys = this.getKeys(obj);
      
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // 使用类型安全的属性访问方式 Uses type-safe property access method
      const propertyValue = this.getPropertyValue(obj, key);
      values.push(propertyValue as T);
    }
      
    return values;
  }

  /**
   * 获取对象的所有键值对 Gets all key-value pairs of object
   * 替代 Object.entries Replaces Object.entries
   */
  getEntries<T>(obj: SafeAny): [string, T][] {
    if (!TypeUtils.isObject(obj)) {
      return [];
    }
      
    const entries: [string, T][] = [];
    const keys = this.getKeys(obj);
      
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // 使用类型安全的属性访问方式 Uses type-safe property access method
      const propertyValue = this.getPropertyValue(obj, key);
      entries.push([key, propertyValue as T]);
    }
      
    return entries;
  }

  /**
   * 从对象中获取属性值，如果属性不存在则返回默认值 Gets property value from object, returns default value if property doesn't exist
   */
  getProperty<T>(obj: SafeAny, key: string | number, defaultValue: T): T {
    if (!TypeUtils.isObject(obj) || !this.hasProperty(obj, key)) {
      return defaultValue;
    }
    
    const keyStr = String(key);
    // 使用类型安全的属性访问方式 Uses type-safe property access method
    const propertyValue = this.getPropertyValue(obj, keyStr);
    return propertyValue as T;
  }

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
  }

  /**
   * 安全地删除对象属性 Safely deletes object property
   */
  deleteProperty(obj: SafeAny, key: string | number): boolean {
    if (!TypeUtils.isObject(obj) || !this.hasProperty(obj, key)) {
      return false;
    }
    
    try {
      const keyStr = String(key);
      // ArkTS 不支持 delete 操作符，使用 undefined 赋值替代
      // ArkTS doesn't support delete operator, use undefined assignment instead
      (obj as Record<string, SafeAny>)[keyStr] = undefined as unknown as SafeAny;
      return true;
    } catch {
      return false;
    }
  }

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
    if (!this.hasProperty(obj, keyStr)) {
      return undefined;
    }
    
    // 使用类型安全的属性访问方式 Uses type-safe property access method
    const safeObj = obj as Record<string, SafeAny>;
    return safeObj[keyStr];
  }

  /**
   * 合并多个对象 Merges multiple objects
   */
  merge<T extends SafeObject>(...objects: Optional<T>[]): T {
    const result: T = {} as T;
    
    for (let i = 0; i < objects.length; i++) {
      const obj = objects[i];
      if (TypeUtils.isObject(obj)) {
        const entries = this.getEntries(obj);
        
        for (let j = 0; j < entries.length; j++) {
          const entry = entries[j];
          const key = entry[0];
          const value = entry[1];
          this.setProperty(result, key, value);
        }
      }
    }
    
    return result;
  }

  /**
   * 深度克隆对象 Deep clones object
   */
  deepClone<T>(value: T): T {
    // 处理 null 和 undefined Handles null and undefined
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
      const clonedArray: Array<string | number | boolean | null> = [];
      const arrayValue = value as unknown as Array<any>;
      for (let i = 0; i < arrayValue.length; i++) {
        clonedArray.push(this.deepClone(arrayValue[i]));
      }
      return clonedArray as T;
    }
      
    // 处理普通对象 Handles regular object
    const cloned: Record<string, unknown> = {};
    const entries = this.getEntries(value as Record<string, unknown>);
      
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const key = entry[0];
      const val = entry[1];
      cloned[key] = this.deepClone(val);
    }
      
    return cloned as T;
  }

  /**
   * 创建对象的浅克隆 Creates shallow clone of object
   */
  shallowClone<T extends SafeObject>(obj: Optional<T>): T {
    if (!TypeUtils.isObject(obj)) {
      return {} as T;
    }
    
    const cloned: T = {} as T;
    const entries = this.getEntries(obj);
    
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const key = entry[0];
      const value = entry[1];
      this.setProperty(cloned, key, value);
    }
    
    return cloned;
  }

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
    const entries = this.getEntries(obj);
    
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const key = entry[0];
      const value = entry[1];
      if (predicate(key, value)) {
        this.setProperty(filtered, key, value);
      }
    }
    
    return filtered;
  }

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
    const entries = this.getEntries(obj);
    
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const key = entry[0];
      const value = entry[1];
      const transformed = transform(key, value);
      const newKey = transformed[0];
      const newValue = transformed[1];
      this.setProperty(result, newKey, newValue);
    }
    
    return result;
  }
}

// 创建单例实例 Create singleton instance
export const ObjectUtils: ObjectUtilsInterface = new ObjectUtilsClass();

export default ObjectUtils;





