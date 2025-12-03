// UtilityFunctions.ets - ArkTS兼容的TypeScript Utility Types运行时实�?
/**
 * ArkTS兼容的TypeScript Utility Types运行时实�? * 提供与TypeScript标准库中类似功能的运行时函数
 */
import { SafeAny, SafeObject } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';
import ObjectUtils from './ObjectUtils';
import ArrayUtils from './ArrayUtils';

/**
 * Utility Types运行时实现函数集�? */
export const UtilityFunctions: Record<string, string | number | boolean | null> = { ... };
    }
    
    const result: Partial<T> = {};
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key in obj) {
        // 使用类型安全的属性访问方�?        const propertyValue = UtilityFunctions.getPropertyValue(obj, key);
        result[key] = propertyValue as T[Extract<keyof T, string>];
      }
    }
    
    return result;
  },

  /**
   * 创建一个对象，确保所有指定的键都存在
   * 运行时实现Required<T>的部分功�?   */
  ensureRequired<T extends Record<string, SafeAny>>(obj: T, keys: string[]): T {
    if (!TypeUtils.isObject(obj)) {
      throw new Error('Object is required');
    }
    
    const missingKeys: string[] = [];
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // 使用类型安全的属性访问方�?      const propertyValue = UtilityFunctions.getPropertyValue(obj, key);
      if (!(key in obj) || propertyValue === undefined) {
        missingKeys.push(key);
      }
    }
    
    if (missingKeys.length > 0) {
      throw new Error(`Missing required properties: ${missingKeys.join(', ')}`);
    }
    
    return obj;
  },

  /**
   * 从对象中选取指定的属�?   * 运行时实现Pick<T, K>的功�?   */
  pick<T extends Record<string, SafeAny>, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
    if (!TypeUtils.isObject(obj)) {
      return {} as Pick<T, K>;
    }
    
    const result: Partial<T> = {};
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key in obj) {
        // 使用类型安全的属性访问方�?        const propertyValue = UtilityFunctions.getPropertyValue(obj, key as string);
        result[key] = propertyValue as T[K];
      }
    }
    
    return result as Pick<T, K>;
  },

  /**
   * 从对象中排除指定的属�?   * 运行时实现Omit<T, K>的功�?   */
  omit<T extends Record<string, SafeAny>, K extends keyof T>(obj: T, keys: K[]): Omit<T, K> {
    if (!TypeUtils.isObject(obj)) {
      return {} as Omit<T, K>;
    }
    
    const result: Partial<T> = {};
    const objKeys = Object.keys(obj);
    
    for (let i = 0; i < objKeys.length; i++) {
      const key = objKeys[i];
      if (!keys.includes(key as K)) {
        // 使用类型安全的属性访问方�?        const propertyValue = UtilityFunctions.getPropertyValue(obj, key);
        result[key] = propertyValue as T[Extract<keyof T, string>];
      }
    }
    
    return result as Omit<T, K>;
  },

  /**
   * 创建一个记录对�?   * 运行时实现Record<K, T>的功�?   */
  createRecord<K extends string | number | symbol, V>(keys: K[], valueGenerator: (key: K) => V): Record<K, V> {
    const result: Record<string | number | symbol, V> = {};
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      result[key] = valueGenerator(key);
    }
    
    return result as Record<K, V>;
  },

  /**
   * 创建一个只读对�?   * 运行时近似实现Readonly<T>的功�?   */
  makeReadonly<T extends Record<string, SafeAny>>(obj: T): Readonly<T> {
    if (!TypeUtils.isObject(obj)) {
      return obj as Readonly<T>;
    }
    
    // 在JavaScript中，Object.freeze只是浅冻�?    return Object.freeze({ ...obj }) as Readonly<T>;
  },

  /**
   * 创建一个深度只读对�?   * 运行时实现DeepReadonly<T>的功�?   */
  makeDeepReadonly<T extends Record<string, SafeAny>>(obj: T): Readonly<T> {
    if (!TypeUtils.isObject(obj)) {
      return obj as Readonly<T>;
    }
    
    const result: Record<string, SafeAny> = {};
    
    for (const key in obj) {
      if (Object.keys(obj).includes(key)) {
        const value = obj[key];
        
        if (TypeUtils.isObject(value) && !Array.isArray(value)) {
          // 递归处理嵌套对象
          result[key] = UtilityFunctions.makeDeepReadonly(value as Record<string, SafeAny>);
        } else if (Array.isArray(value)) {
          // 处理数组
          const frozenArray = value.map((item) => {
            if (TypeUtils.isObject(item)) {
              return UtilityFunctions.makeDeepReadonly(item as Record<string, SafeAny>);
            }
            return item;
          });
          result[key] = Object.freeze(frozenArray);
        } else {
          // 原始�?          result[key] = value;
        }
      }
    }
    
    return Object.freeze(result) as Readonly<T>;
  },

  /**
   * 深度复制对象
   * 用于处理DeepPartial等深度类型的辅助函数
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
      if (Object.keys(obj).includes(key)) {
        result[key] = UtilityFunctions.deepClone(obj[key]);
      }
    }
    
    return result as T;
  },

  /**
   * 安全地获取对象属性�?   * @param obj - 要获取属性的对象
   * @param key - 属性键�?   * @returns 属性值，如果属性不存在则返回undefined
   */
  getPropertyValue(obj: Record<string, SafeAny>, key: string): Record<string, string | number | boolean | null> {
    if (!TypeUtils.isObject(obj)) {
      return undefined;
    }
    
    if (!(key in obj)) {
      return undefined;
    }
    
    // 使用类型安全的属性访问方�?    return obj[key];
  },

  /**
   * 创建一个深度部分对�?   * 运行时实现DeepPartial<T>的功�?   */
  createDeepPartial<T extends Record<string, SafeAny>>(obj: T, paths: string[]): Partial<T> {
    const result: Partial<T> = {};
    
    if (!TypeUtils.isObject(obj)) {
      return result;
    }
    
    for (let i = 0; i < paths.length; i++) {
      const path = paths[i];
      const pathParts = path.split('.');
      let currentObj: Record<string, SafeAny> = result;
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
   * 合并两个对象
   * 运行时实现Merge<T, U>的功�?   */
  merge<T extends Record<string, SafeAny>, U extends Record<string, SafeAny>>(target: T, source: U): T & U {
    if (!TypeUtils.isObject(target)) {
      return source as T & U;
    }
    
    if (!TypeUtils.isObject(source)) {
      return target as T & U;
    }
    
    const result: Record<string, string | number | boolean | null> = { ... };
    
    for (const key in source) {
      if (Object.keys(source).includes(key)) {
        (result as Record<string, SafeAny>)[key] = source[key];
      }
    }
    
    return result as T & U;
  },

  /**
   * 深度合并两个对象
   * 运行时实现深度Merge<T, U>的功�?   */
  deepMerge<T extends Record<string, SafeAny>, U extends Record<string, SafeAny>>(target: T, source: U): T & U {
    if (!TypeUtils.isObject(target)) {
      return source as T & U;
    }
    
    if (!TypeUtils.isObject(source)) {
      return target as T & U;
    }
    
    const result: Record<string, string | number | boolean | null> = { ... };
    
    for (const key in source) {
      if (Object.keys(source).includes(key)) {
        const targetValue = target[key];
        const sourceValue = source[key];
        
        if (TypeUtils.isObject(targetValue) && TypeUtils.isObject(sourceValue) && !Array.isArray(targetValue) && !Array.isArray(sourceValue)) {
          // 递归合并嵌套对象
          (result as Record<string, SafeAny>)[key] = UtilityFunctions.deepMerge(targetValue as Record<string, SafeAny>, sourceValue as Record<string, SafeAny>);
        } else if (Array.isArray(targetValue) && Array.isArray(sourceValue)) {
          // 合并数组
          (result as Record<string, SafeAny>)[key] = [...targetValue, ...sourceValue];
        } else {
          // 使用source的值覆盖target的�?          (result as Record<string, SafeAny>)[key] = sourceValue;
        }
      }
    }
    
    return result as T & U;
  },

  /**
   * 检查值是否为指定类型
   * 运行时实现类型守卫功�?   */
  isType<T>(value: Record<string, string | number | boolean | null>, typeGuard: (value: Record<string, string | number | boolean | null>) => boolean): value is T {
    return typeGuard(value);
  },

  /**
   * 安全地转换类�?   * 运行时实现类型转换功�?   */
  safeCast<T>(value: Record<string, string | number | boolean | null>, typeGuard: (value: Record<string, string | number | boolean | null>) => boolean, defaultValue: T): T {
    return typeGuard(value) ? (value as T) : defaultValue;
  },

  /**
   * 获取函数的返回类型（运行时检查）
   */
  getReturnType<T>(fn: (...args: Record<string, string | number | boolean | null>[]) => T, ...args: Record<string, string | number | boolean | null>[]): T | null {
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
   * 创建类型保护函数
   */
  createTypeGuard<T>(validator: (value: Record<string, string | number | boolean | null>) => boolean): (value: Record<string, string | number | boolean | null>) => value is T {
    return validator as (value: Record<string, string | number | boolean | null>) => value is T;
  },

  /**
   * 从联合类型中提取特定类型的元�?   * 运行时实现Extract<T, U>的功�?   */
  extract<T>(array: T[], typeGuard: (value: T) => boolean): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    return array.filter(typeGuard);
  },

  /**
   * 从联合类型中排除特定类型的元�?   * 运行时实现Exclude<T, U>的功�?   */
  exclude<T>(array: T[], typeGuard: (value: T) => boolean): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    return array.filter((value) => !typeGuard(value));
  },

  /**
   * 确保值不为null或undefined
   * 运行时实现NonNullable<T>的功�?   */
  ensureNotNull<T>(value: T | null | undefined, errorMessage: string = 'Value cannot be null or undefined'): T {
    if (value === null || value === undefined) {
      throw new Error(errorMessage);
    }
    
    return value;
  },

  /**
   * 异步等待Promise解析
   * 运行时实现Awaited<T>的功�?   */
  async awaitPromise<T>(promise: Promise<T>): Promise<T> {
    if (!(promise instanceof Promise)) {
      throw new Error('Value is not a Promise');
    }
    
    return promise;
  },

  /**
   * 检查对象是否完全匹配指定的类型定义
   * 运行时实现Exact<T, U>的部分功�?   */
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

