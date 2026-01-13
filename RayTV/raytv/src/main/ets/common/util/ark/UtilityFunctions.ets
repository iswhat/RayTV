// UtilityFunctions.ets - ArkTS兼容的TypeScript Utility Types运行时实现 ArkTS compatible TypeScript Utility Types runtime implementation
/**
 * ArkTS兼容的TypeScript Utility Types运行时实现 ArkTS compatible TypeScript Utility Types runtime implementation
 * 提供与TypeScript标准库中类似功能的运行时函数 Provides runtime functions with similar functionality to TypeScript standard library
 */
import { SafeAny, SafeObject } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';
import ObjectUtils from './ObjectUtils';
import ArrayUtils from './ArrayUtils';

/**
 * Utility Types运行时实现函数集合 Utility Types Runtime Implementation Functions Collection
 */
export const UtilityFunctions = {
  /**
   * 从对象中选取指定的属性 Pick specified properties from object
   * 运行时实现Pick<T, K>的功能 Runtime implementation of Pick<T, K> functionality
   */
  pick<T extends Record<string, SafeAny>, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
    if (!TypeUtils.isObject(obj)) {
      return {} as Pick<T, K>;
    }
    
    const result: Partial<T> = {};
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key in obj) {
        // 使用类型安全的属性查询方式 Use type-safe property query method
        const propertyValue = UtilityFunctions.getPropertyValue(obj, key as string);
        result[key] = propertyValue as T[K];
      }
    }
    
    return result as Pick<T, K>;
  },

  /**
   * 从对象中排除指定的属性 Exclude specified properties from object
   * 运行时实现Omit<T, K>的功能 Runtime implementation of Omit<T, K> functionality
   */
  omit<T extends Record<string, SafeAny>, K extends keyof T>(obj: T, keys: K[]): Omit<T, K> {
    if (!TypeUtils.isObject(obj)) {
      return {} as Omit<T, K>;
    }
    
    const result: Partial<T> = {};
    const objKeys = Object.keys(obj);
    
    for (let i = 0; i < objKeys.length; i++) {
      const key = objKeys[i];
      if (!keys.includes(key as K)) {
        // 使用类型安全的属性查询方式 Use type-safe property query method
        const propertyValue = UtilityFunctions.getPropertyValue(obj, key);
        result[key] = propertyValue as T[Extract<keyof T, string>];
      }
    }
    
    return result as Omit<T, K>;
  },

  /**
   * 创建一个记录对象 Create a record object
   * 运行时实现Record<K, T>的功能 Runtime implementation of Record<K, T> functionality
   */
  createRecord<K extends string | number | symbol, V>(keys: K[], valueGenerator: (key: K) => V): Record<K, V> {
    const result: Record<string | number | symbol, V> = {};
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      result[key] = valueGenerator(key);
    }
    
    return result as Record<K, V>;
  },

  /**
   * 创建一个只读对象 Create a readonly object
   * 运行时近似实现Readonly<T>的功能 Runtime approximate implementation of Readonly<T> functionality
   */
  makeReadonly<T extends Record<string, SafeAny>>(obj: T): Readonly<T> {
    if (!TypeUtils.isObject(obj)) {
      return obj as Readonly<T>;
    }
    
    // 在JavaScript中，Object.freeze只是浅层冻结 In JavaScript, Object.freeze is only shallow freeze
    return Object.freeze({ ...obj }) as Readonly<T>;
  },

  /**
   * 创建一个深度只读对象 Create a deep readonly object
   * 运行时实现DeepReadonly<T>的功能 Runtime implementation of DeepReadonly<T> functionality
   */
  makeDeepReadonly<T extends Record<string, SafeAny>>(obj: T): Readonly<T> {
    if (!TypeUtils.isObject(obj)) {
      return obj as Readonly<T>;
    }
    
    const result: Record<string, SafeAny> = {};
    
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        const value = obj[key];
        
        if (TypeUtils.isObject(value) && !Array.isArray(value)) {
          // 递归处理嵌套对象 Recursively process nested objects
          result[key] = UtilityFunctions.makeDeepReadonly(value as Record<string, SafeAny>);
        } else if (Array.isArray(value)) {
          // 处理数组 Process arrays
          const frozenArray = value.map((item) => {
            if (TypeUtils.isObject(item)) {
              return UtilityFunctions.makeDeepReadonly(item as Record<string, SafeAny>);
            }
            return item;
          });
          result[key] = Object.freeze(frozenArray);
        } else {
          // 原始值 Primitive value
          result[key] = value;
        }
      }
    }
    
    return Object.freeze(result) as Readonly<T>;
  },

  /**
   * 深度克隆对象 Deep clone object
   * 用于处理DeepPartial等深度类型的辅助函数 Helper function for processing deep types like DeepPartial
   */
  deepClone<T>(obj: T): T {
    if (obj === null || obj === undefined) {
      return obj;
    }
    
    if (typeof obj !== 'object') {
      return obj;
    }
    
    if (obj instanceof Date) {
      return new Date(obj.getTime()) as unknown as T;
    }
    
    if (Array.isArray(obj)) {
      return obj.map(UtilityFunctions.deepClone) as unknown as T;
    }
    
    const result: Record<string, SafeAny> = {};
    
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        result[key] = UtilityFunctions.deepClone(obj[key]);
      }
    }
    
    return result as T;
  },

  /**
   * 安全地获取对象属性值 Safely get object property value
   * @param obj - 要获取属性的对象 Object to get property from
   * @param key - 属性键名 Property key name
   * @returns 属性值，如果属性不存在则返回undefined Property value, undefined if property doesn't exist
   */
  getPropertyValue(obj: Record<string, SafeAny>, key: string): SafeAny {
    if (!TypeUtils.isObject(obj)) {
      return undefined;
    }
    
    if (!(key in obj)) {
      return undefined;
    }
    
    // 使用类型安全的属性查询方式 Use type-safe property query method
    return obj[key];
  },

  /**
   * 创建一个深度部分对象 Create a deep partial object
   * 运行时实现DeepPartial<T>的功能 Runtime implementation of DeepPartial<T> functionality
   */
  createDeepPartial<T extends Record<string, SafeAny>>(obj: T, paths: string[]): Partial<T> {
    const result: Partial<T> = {};
    
    if (!TypeUtils.isObject(obj)) {
      return result;
    }
    
    for (let i = 0; i < paths.length; i++) {
      const path = paths[i];
      const pathParts = path.split('.');
      let currentObj: Record<string, SafeAny> = result as Record<string, SafeAny>;
      let sourceObj: Record<string, SafeAny> = obj;
      
      for (let j = 0; j < pathParts.length - 1; j++) {
        const part = pathParts[j];
        
        if (!(part in currentObj)) {
          currentObj[part] = {};
        }
        
        if (!(part in sourceObj) || !TypeUtils.isObject(sourceObj[part])) {
          break;
        }
        
        currentObj = currentObj[part] as Record<string, SafeAny>;
        sourceObj = sourceObj[part] as Record<string, SafeAny>;
      }
      
      const lastPart = pathParts[pathParts.length - 1];
      if (lastPart in sourceObj) {
        currentObj[lastPart] = sourceObj[lastPart];
      }
    }
    
    return result;
  },

  /**
   * 合并两个对象 Merge two objects
   * 运行时实现Merge<T, U>的功能 Runtime implementation of Merge<T, U> functionality
   */
  merge<T extends Record<string, SafeAny>, U extends Record<string, SafeAny>>(target: T, source: U): T & U {
    if (!TypeUtils.isObject(target)) {
      return source as T & U;
    }
    
    if (!TypeUtils.isObject(source)) {
      return target as T & U;
    }
    
    const result: Record<string, SafeAny> = { ...target };
    
    for (const key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        result[key] = source[key];
      }
    }
    
    return result as T & U;
  },

  /**
   * 深度合并两个对象 Deep merge two objects
   * 运行时实现深度Merge<T, U>的功能 Runtime implementation of deep Merge<T, U> functionality
   */
  deepMerge<T extends Record<string, SafeAny>, U extends Record<string, SafeAny>>(target: T, source: U): T & U {
    if (!TypeUtils.isObject(target)) {
      return source as T & U;
    }
    
    if (!TypeUtils.isObject(source)) {
      return target as T & U;
    }
    
    const result: Record<string, SafeAny> = { ...target };
    
    for (const key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        const targetValue = target[key];
        const sourceValue = source[key];
        
        if (TypeUtils.isObject(targetValue) && TypeUtils.isObject(sourceValue) && !Array.isArray(targetValue) && !Array.isArray(sourceValue)) {
          // 递归合并嵌套对象 Recursively merge nested objects
          result[key] = UtilityFunctions.deepMerge(targetValue as Record<string, SafeAny>, sourceValue as Record<string, SafeAny>);
        } else if (Array.isArray(targetValue) && Array.isArray(sourceValue)) {
          // 合并数组 Merge arrays
          result[key] = [...targetValue, ...sourceValue];
        } else {
          // 使用source的值覆盖target的值 Use source value to override target value
          result[key] = sourceValue;
        }
      }
    }
    
    return result as T & U;
  },

  /**
   * 检查值是否为指定类型 Check if value is of specified type
   * 运行时实现类型断言功能 Runtime implementation of type assertion functionality
   */
  isType<T>(value: SafeAny, typeGuard: (value: SafeAny) => boolean): value is T {
    return typeGuard(value);
  },

  /**
   * 安全地转换类型 Safely cast type
   * 运行时实现类型转换功能 Runtime implementation of type conversion functionality
   */
  safeCast<T>(value: SafeAny, typeGuard: (value: SafeAny) => boolean, defaultValue: T): T {
    return typeGuard(value) ? (value as T) : defaultValue;
  },

  /**
   * 获取函数的返回类型(运行时检查) Get function return type (runtime check)
   */
  getReturnType<T>(fn: (...args: SafeAny[]) => T, ...args: SafeAny[]): T | null {
    try {
      if (typeof fn === 'function') {
        return fn(...args);
      }
      return null;
    } catch {
      return null;
    }
  },

  /**
   * 创建类型保护函数 Create type guard function
   */
  createTypeGuard<T>(validator: (value: SafeAny) => boolean): (value: SafeAny) => value is T {
    return validator as (value: SafeAny) => value is T;
  },

  /**
   * 从联合类型中提取指定类型的元素 Extract elements of specified type from union type
   * 运行时实现Extract<T, U>的功能 Runtime implementation of Extract<T, U> functionality
   */
  extract<T>(array: T[], typeGuard: (value: T) => boolean): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    return array.filter(typeGuard);
  },

  /**
   * 从联合类型中排除指定类型的元素 Exclude elements of specified type from union type
   * 运行时实现Exclude<T, U>的功能 Runtime implementation of Exclude<T, U> functionality
   */
  exclude<T>(array: T[], typeGuard: (value: T) => boolean): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    return array.filter((value) => !typeGuard(value));
  },

  /**
   * 确保值不为null或undefined Ensure value is not null or undefined
   * 运行时实现NonNullable<T>的功能 Runtime implementation of NonNullable<T> functionality
   */
  ensureNotNull<T>(value: T | null | undefined, errorMessage: string = 'Value cannot be null or undefined'): T {
    if (value === null || value === undefined) {
      throw new Error(errorMessage);
    }
    
    return value;
  },

  /**
   * 异步等待Promise解析 Async wait for Promise resolution
   * 运行时实现Awaited<T>的功能 Runtime implementation of Awaited<T> functionality
   */
  async awaitPromise<T>(promise: Promise<T>): Promise<T> {
    if (!(promise instanceof Promise)) {
      throw new Error('Value is not a Promise');
    }
    
    return promise;
  },

  /**
   * 检查对象是否完全符合指定的类型定义 Check if object exactly matches specified type definition
   * 运行时实现Exact<T, U>的部分功能 Runtime implementation of part of Exact<T, U> functionality
   */
  isExactMatch<T extends Record<string, SafeAny>>(obj: Record<string, SafeAny>, expectedKeys: string[]): boolean {
    if (!TypeUtils.isObject(obj)) {
      return false;
    }
    
    const actualKeys = Object.keys(obj);
    
    if (actualKeys.length !== expectedKeys.length) {
      return false;
    }
    
    for (let i = 0; i < expectedKeys.length; i++) {
      if (!actualKeys.includes(expectedKeys[i])) {
        return false;
      }
    }
    
    return true;
  }
};

export default UtilityFunctions;