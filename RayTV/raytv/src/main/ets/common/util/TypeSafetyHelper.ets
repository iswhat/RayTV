/**
 * TypeSafetyHelper - 类型安全辅助工具类 Type safety helper class
 * 提供类型安全检查和转换的辅助方法 Provides helper methods for type safety checking and conversion
 */

/**
 * 类型安全辅助工具类 Type safety helper class
 */
export class TypeSafetyHelper {
  private static readonly TAG: string = 'TypeSafetyHelper';

  /**
   * 安全地将值转换为字符串 Safely converts value to string
   * @param value 要转换的值 Value to convert
   * @param defaultValue 默认值 Default value
   * @returns 转换后的字符串 Converted string
   */
  public static safeString(value: any, defaultValue: string = ''): string {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return String(value);
  }

  /**
   * 安全地将值转换为数字 Safely converts value to number
   * @param value 要转换的值 Value to convert
   * @param defaultValue 默认值 Default value
   * @returns 转换后的数字 Converted number
   */
  public static safeNumber(value: any, defaultValue: number = 0): number {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    const num = Number(value);
    return isNaN(num) ? defaultValue : num;
  }

  /**
   * 安全地将值转换为布尔值 Safely converts value to boolean
   * @param value 要转换的值 Value to convert
   * @param defaultValue 默认值 Default value
   * @returns 转换后的布尔值 Converted boolean
   */
  public static safeBoolean(value: any, defaultValue: boolean = false): boolean {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Boolean(value);
  }

  /**
   * 安全地将值转换为数组 Safely converts value to array
   * @param value 要转换的值 Value to convert
   * @param defaultValue 默认值 Default value
   * @returns 转换后的数组 Converted array
   */
  public static safeArray<T>(value: any, defaultValue: T[] = []): T[] {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Array.isArray(value) ? value : defaultValue;
  }

  /**
   * 安全地将值转换为对象 Safely converts value to object
   * @param value 要转换的值 Value to convert
   * @param defaultValue 默认值 Default value
   * @returns 转换后的对象 Converted object
   */
  public static safeObject<T extends Record<string, any>>(value: any, defaultValue: T = {} as T): T {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    if (typeof value === 'object' && !Array.isArray(value)) {
      return value as T;
    }
    return defaultValue;
  }

  /**
   * 安全地获取对象属性 Safely gets object property
   * @param obj 目标对象 Target object
   * @param path 属性路径 Property path
   * @param defaultValue 默认值 Default value
   * @returns 属性值或默认值 Property value or default value
   */
  public static safeGet<T = any>(obj: Record<string, any>, path: string | string[], defaultValue?: T): T | undefined {
    if (!obj || typeof obj !== 'object') {
      return defaultValue;
    }

    const keys: string[] = Array.isArray(path) ? path : path.split('.');
    let current: any = obj;

    for (const key of keys) {
      if (current === null || current === undefined || !Reflect.has(current, key)) {
        return defaultValue;
      }
      current = current[key];
    }

    return current;
  }

  /**
   * 安全地设置对象属性 Safely sets object property
   * @param obj 目标对象 Target object
   * @param path 属性路径 Property path
   * @param value 属性值 Property value
   * @returns 是否设置成功 Whether set successfully
   */
  public static safeSet(obj: Record<string, any>, path: string | string[], value: any): boolean {
    if (!obj || typeof obj !== 'object') {
      return false;
    }

    const keys: string[] = Array.isArray(path) ? path : path.split('.');
    let current: any = obj;

    for (let i = 0; i < keys.length - 1; i++) {
      const key = keys[i];
      if (!current[key]) {
        current[key] = {};
      }
      if (typeof current[key] !== 'object') {
        return false;
      }
      current = current[key];
    }

    const lastKey = keys[keys.length - 1];
    current[lastKey] = value;
    return true;
  }

  /**
   * 安全地调用函数 Safely calls function
   * @param fn 要调用的函数 Function to call
   * @param thisArg this上下文 This context
   * @param args 函数参数 Function arguments
   * @param defaultValue 默认返回值 Default return value
   * @returns 函数返回值或默认值 Function return value or default value
   */
  public static safeCall<T = any>(fn: any, thisArg: any, args: any[], defaultValue?: T): T | undefined {
    if (typeof fn !== 'function') {
      return defaultValue;
    }
    return fn.apply(thisArg, args);
  }

  /**
   * 安全地创建错误对象 Safely creates error object
   * @param message 错误消息 Error message
   * @param cause 错误原因 Error cause
   * @returns 错误对象 Error object
   */
  public static safeError(message: string, cause?: unknown): Error {
    const error = new Error(message);
    if (cause) {
      (error as any).cause = cause;
    }
    return error;
  }

  /**
   * 安全地获取枚举值 Safely gets enum value
   * @param enumObj 枚举对象 Enum object
   * @param value 枚举值 Enum value
   * @param defaultValue 默认值 Default value
   * @returns 有效的枚举值或默认值 Valid enum value or default value
   */
  public static safeEnum<T extends Record<string, any>>(enumObj: T, value: any, defaultValue: T[keyof T]): T[keyof T] {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Object.values(enumObj).includes(value) ? value : defaultValue;
  }

  /**
   * 安全地转换为日期对象 Safely converts to date object
   * @param value 要转换的值 Value to convert
   * @param defaultValue 默认值 Default value
   * @returns 转换后的日期对象或默认值 Converted date object or default value
   */
  public static safeDate(value: any, defaultValue: Date = new Date()): Date {
    if (value instanceof Date) {
      return value;
    }
    const date = new Date(value);
    return isNaN(date.getTime()) ? defaultValue : date;
  }

  /**
   * 安全地检查值是否为指定类型 Safely checks if value is of specified type
   * @param value 要检查的值 Value to check
   * @param type 类型字符串 Type string
   * @returns 是否为指定类型 Whether it is of specified type
   */
  public static isType(value: any, type: string): boolean {
    if (type === 'null') {
      return value === null;
    }
    if (type === 'undefined') {
      return value === undefined;
    }
    if (type === 'array') {
      return Array.isArray(value);
    }
    if (type === 'date') {
      return value instanceof Date && !isNaN(value.getTime());
    }
    if (type === 'error') {
      return value instanceof Error;
    }
    return typeof value === type;
  }

  /**
   * 安全地获取数组元素 Safely gets array element
   * @param array 数组 Array
   * @param index 索引 Index
   * @param defaultValue 默认值 Default value
   * @returns 数组元素或默认值 Array element or default value
   */
  public static safeArrayElement<T>(array: T[], index: number, defaultValue?: T): T | undefined {
    if (!Array.isArray(array) || index < 0 || index >= array.length) {
      return defaultValue;
    }
    return array[index];
  }

  /**
   * 安全地获取Map值 Safely gets Map value
   * @param map Map对象 Map object
   * @param key 键 Key
   * @param defaultValue 默认值 Default value
   * @returns Map值或默认值 Map value or default value
   */
  public static safeMapGet<K, V>(map: Map<K, V>, key: K, defaultValue?: V): V | undefined {
    if (!(map instanceof Map)) {
      return defaultValue;
    }
    return map.has(key) ? map.get(key) : defaultValue;
  }

  /**
   * 安全地获取Set元素是否存在 Safely checks if Set contains element
   * @param set Set对象 Set object
   * @param value 值 Value
   * @returns 是否存在 Whether it exists
   */
  public static safeSetHas<T>(set: Set<T>, value: T): boolean {
    if (!(set instanceof Set)) {
      return false;
    }
    return set.has(value);
  }

  /**
   * 安全地将值转换为指定类型 Safely converts value to specified type
   * @param value 要转换的值 Value to convert
   * @param type 类型字符串 Type string
   * @param defaultValue 默认值 Default value
   * @returns 转换后的类型或默认值 Converted type or default value
   */
  public static safeConvert<T>(value: any, type: string, defaultValue: T): T {
    switch (type) {
      case 'string':
        return this.safeString(value, defaultValue as unknown as string) as unknown as T;
      case 'number':
        return this.safeNumber(value, defaultValue as unknown as number) as unknown as T;
      case 'boolean':
        return this.safeBoolean(value, defaultValue as unknown as boolean) as unknown as T;
      case 'array':
        return this.safeArray(value, defaultValue as unknown as any[]) as unknown as T;
      case 'object':
        return this.safeObject(value, defaultValue as unknown as Record<string, any>) as unknown as T;
      case 'date':
        return this.safeDate(value, defaultValue as unknown as Date) as unknown as T;
      default:
        return defaultValue;
    }
  }

  /**
   * 安全地执行异步函数 Safely executes async function
   * @param fn 异步函数 Async function
   * @param args 函数参数 Function arguments
   * @param options 选项 Options
   * @returns 执行结果 Execution result
   */
  public static async safeAsyncExecute<T>(
    fn: (...args: any[]) => Promise<T>,
    args: any[],
    options: {
      onError?: (error: Error) => void;
      defaultValue?: T;
    } = {}
  ): Promise<T | undefined> {
    try {
      return await fn(...args);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      if (options.onError) {
        options.onError(err);
      }
      return options.defaultValue;
    }
  }

  /**
   * 安全地访问可选链属性 Safely accesses optional chaining property
   * @param obj 目标对象 Target object
   * @param path 属性路径 Property path
   * @param defaultValue 默认值 Default value
   * @returns 属性值或默认值 Property value or default value
   */
  public static optionalChain<T = any>(obj: Record<string, any>, path: string, defaultValue?: T): T | undefined {
    if (!obj || typeof obj !== 'object') {
      return defaultValue;
    }
    return path.split('.').reduce((acc, key) => {
      return acc && acc[key] !== undefined ? acc[key] : defaultValue;
    }, obj) as T | undefined;
  }

  /**
   * 安全地合并对象 Safely merges objects
   * @param target 目标对象 Target object
   * @param sources 源对象 Source objects
   * @returns 合并后的对象 Merged object
   */
  public static safeMerge<T extends Record<string, any>>(
    target: T,
    ...sources: Record<string, any>[]
  ): T {
    if (!sources.length) {
      return target;
    }
    const merged = { ...target };
    for (const source of sources) {
      if (source && typeof source === 'object') {
        for (const key in source) {
          if (source.hasOwnProperty(key)) {
            const sourceValue = source[key];
            const targetValue = merged[key];
            if (typeof targetValue === 'object' && targetValue !== null && typeof sourceValue === 'object' && sourceValue !== null) {
              merged[key] = this.safeMerge(targetValue as Record<string, any>, sourceValue as Record<string, any>);
            } else {
              merged[key] = sourceValue;
            }
          }
        }
      }
    }
    return merged as T;
  }

  /**
   * 安全地克隆对象 Safely clones object
   * @param obj 要克隆的对象 Object to clone
   * @returns 克隆后的对象 Cloned object
   */
  public static safeClone<T>(obj: T): T {
    if (obj === null || obj === undefined) {
      return obj;
    }
    if (obj instanceof Date) {
      return new Date(obj.getTime()) as unknown as T;
    }
    if (Array.isArray(obj)) {
      return [...obj.map(item => this.safeClone(item))] as unknown as T;
    }
    if (typeof obj === 'object') {
      const clonedObj: any = {};
      for (const key in obj) {
        if (obj.hasOwnProperty(key)) {
          clonedObj[key] = this.safeClone(obj[key]);
        }
      }
      return clonedObj as T;
    }
    return obj;
  }
}

export default TypeSafetyHelper;
