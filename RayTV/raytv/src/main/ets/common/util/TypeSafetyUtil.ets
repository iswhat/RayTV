/**
 * Type safety utility class | 类型安全工具类
 * Provides type safety checking and conversion functions | 提供类型安全检查和转换功能
 */

/**
 * Type safety utility class | 类型安全工具类
 */
export class TypeSafetyUtil {
  private static readonly TAG: string = 'TypeSafetyUtil';

  /**
   * Safely converts value to string | 安全地将值转换为字符串
   * @param value Value to convert | 要转换的值
   * @param defaultValue Default value | 默认值
   * @returns Converted string | 转换后的字符串
   */
  public static safeString(value: string | number | boolean | null | undefined | object, defaultValue: string = ''): string {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return String(value);
  }

  /**
   * Safely converts value to number | 安全地将值转换为数字
   * @param value Value to convert | 要转换的值
   * @param defaultValue Default value | 默认值
   * @returns Converted number | 转换后的数字
   */
  public static safeNumber(value: string | number | boolean | null | undefined | object, defaultValue: number = 0): number {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    const num = Number(value);
    return isNaN(num) ? defaultValue : num;
  }

  /**
   * Safely converts value to boolean | 安全地将值转换为布尔值
   * @param value Value to convert | 要转换的值
   * @param defaultValue Default value | 默认值
   * @returns Converted boolean | 转换后的布尔值
   */
  public static safeBoolean(value: string | number | boolean | null | undefined | object, defaultValue: boolean = false): boolean {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Boolean(value);
  }

  /**
   * Safely creates error object | 安全地创建错误对象
   * @param error Error value | 错误值
   * @param message Error message | 错误消息
   * @returns Error object | 错误对象
   */
  public static safeError(error: Error | string | number | boolean | null | undefined, message?: string): Error {
    if (error instanceof Error) {
      return error;
    }
    const errorStr = String(error);
    return message ? new Error(message + ': ' + errorStr) : new Error(errorStr);
  }

  /**
   * Safely accesses object property | 安全地访问对象属性
   * @param obj Target object | 目标对象
   * @param path Property path | 属性路径
   * @param defaultValue Default value | 默认值
   * @returns Property value or default value | 属性值或默认值
   */
  public static safeAccess<T = string | number | boolean | null>(
    obj: Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>>, 
    path: string | string[], 
    defaultValue?: T
  ): T | undefined {
    if (!obj || typeof obj !== 'object') {
      return defaultValue;
    }

    const keys: string[] = Array.isArray(path) ? path : path.split('.');
    let current: Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>> | string | number | boolean | null = obj;

    for (const key of keys) {
      if (current === null || current === undefined || typeof current !== 'object') {
        return defaultValue;
      }
      const currentObj = current as Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>>;
      // 安全检查对象属性存在性，使用Object.prototype.hasOwnProperty.call
      if (!Object.prototype.hasOwnProperty.call(currentObj, key)) {
        return defaultValue;
      }
      current = currentObj[key];
    }

    return current !== undefined ? (current as T) : defaultValue;
  }

  /**
   * Safely checks if array contains element | 安全地检查数组是否包含元素
   * @param array Target array | 目标数组
   * @param element Element to check | 要检查的元素
   * @returns Whether array contains element | 是否包含元素
   */
  public static safeIncludes<T>(array: T[], element: T): boolean {
    if (!Array.isArray(array)) {
      return false;
    }
    return array.includes(element);
  }

  /**
   * Safely gets array length | 安全地获取数组长度
   * @param array Target array | 目标数组
   * @returns Array length | 数组长度
   */
  public static safeLength(array: Array<string | number | boolean | null> | string): number {
    if (array === null || array === undefined) {
      return 0;
    }
    return array.length || 0;
  }

  /**
   * Safely checks if object has property | 安全地检查对象是否有指定属性
   * @param obj Target object | 目标对象
   * @param property Property name | 属性名
   * @returns Whether object has property | 是否有指定属性
   */
  public static safeHasProperty(obj: Record<string, string | number | boolean | null>, property: string): boolean {
    if (!obj || typeof obj !== 'object') {
      return false;
    }
    // 安全检查对象属性存在性，使用Object.prototype.hasOwnProperty.call
    return Object.prototype.hasOwnProperty.call(obj, property);
  }

  /**
   * Safely calls function | 安全地调用函数
   * @param fn Function to call | 要调用的函数
   * @param args Function arguments | 函数参数
   * @returns Function return value | 函数返回值
   */
  public static safeCall<T>(fn: (...args: Array<string | number | boolean | null>) => T | undefined | null, ...args: Array<string | number | boolean | null>): T | undefined | null {
    if (typeof fn !== 'function') {
      return undefined;
    }
    return fn(...args);
  }

  /**
   * Safely checks if value is of specific type | 安全地检查值是否为指定类型
   * @param value Value to check | 要检查的值
   * @param type Type string | 类型字符串
   * @returns Whether value is of specific type | 是否为特定类型
   */
  public static isType(value: string | number | boolean | null | undefined | object, type: string): boolean {
    return typeof value === type;
  }
}

export default TypeSafetyUtil;

