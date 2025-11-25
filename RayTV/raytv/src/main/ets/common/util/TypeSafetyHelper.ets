// TypeSafeUtil - 类型安全工具类
// 提供统一的类型检查、转换和错误处理方法

/**
 * 类型安全工具类
 */
export default class TypeSafeUtil {
  /**
   * 安全地将值转换为对象
   * @param value 要转换的值
   * @returns 转换后的对象，失败时返回空对象
   */
  public static asObject(value: unknown): Record<string, unknown> {
    if (value === null || value === undefined) {
      return {};
    }
    if (typeof value === 'object') {
      return value as Record<string, unknown>;
    }
    try {
      return JSON.parse(JSON.stringify(value)) as Record<string, unknown>;
    } catch {
      return {};
    }
  }

  /**
   * 安全地将值转换为数组
   * @param value 要转换的值
   * @returns 转换后的数组，失败时返回空数组
   */
  public static asArray<T>(value: unknown): T[] {
    if (Array.isArray(value)) {
      return value as T[];
    }
    if (value === null || value === undefined) {
      return [];
    }
    return [value as T];
  }

  /**
   * 安全地将值转换为字符串
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的字符串
   */
  public static asString(value: unknown, defaultValue: string = ''): string {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return String(value);
  }

  /**
   * 安全地将值转换为数字
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的数字
   */
  public static asNumber(value: unknown, defaultValue: number = 0): number {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    const num = Number(value);
    return isNaN(num) ? defaultValue : num;
  }

  /**
   * 安全地将值转换为布尔值
   * @param value 要转换的值
   * @returns 转换后的布尔值
   */
  public static asBoolean(value: unknown): boolean {
    if (value === null || value === undefined) {
      return false;
    }
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'string') {
      return value.toLowerCase() === 'true' || value === '1';
    }
    return Boolean(value);
  }

  /**
   * 安全地访问对象属性
   * @param obj 对象
   * @param key 属性名
   * @param defaultValue 默认值
   * @returns 属性值或默认值
   */
  public static safeGet<T>(
    obj: unknown,
    key: string | number,
    defaultValue: T
  ): T {
    const safeObj = TypeSafeUtil.asObject(obj);
    const value = safeObj[key];
    return value !== undefined ? (value as T) : defaultValue;
  }

  /**
   * 安全地设置对象属性
   * @param obj 对象
   * @param key 属性名
   * @param value 属性值
   * @returns 更新后的对象
   */
  public static safeSet<T>(
    obj: T,
    key: string | number,
    value: unknown
  ): T {
    const safeObj = TypeSafeUtil.asObject(obj);
    safeObj[key] = value;
    return safeObj as T;
  }

  /**
   * 创建安全的错误对象
   * @param message 错误消息
   * @param cause 错误原因
   * @returns Error对象
   */
  public static safeError(message: string, cause?: unknown): Error {
    const error = new Error(message);
    if (cause) {
      // 使用对象展开操作符安全地设置cause属性，避免使用any类型
      Object.assign(error, { cause });
    }
    return error;
  }

  /**
   * 安全地检查对象是否有指定属性
   * @param obj 对象
   * @param key 属性名
   * @returns 是否有该属性
   */
  public static hasProperty(obj: unknown, key: string | number): boolean {
    if (obj === null || obj === undefined) {
      return false;
    }
    if (typeof obj !== 'object') {
      return false;
    }
    return Object.hasOwnProperty.call(obj, key);
  }

  /**
   * 获取对象的所有键
   * @param obj 对象
   * @returns 键数组
   */
  public static getObjectKeys(obj: unknown): string[] {
    if (obj === null || obj === undefined || typeof obj !== 'object') {
      return [];
    }
    return Object.keys(obj);
  }

  /**
   * 获取对象的所有值
   * @param obj 对象
   * @returns 值数组
   */
  public static getObjectValues<T>(obj: unknown): T[] {
    if (obj === null || obj === undefined || typeof obj !== 'object') {
      return [];
    }
    return Object.values(obj) as T[];
  }

  /**
   * 获取对象的所有键值对
   * @param obj 对象
   * @returns 键值对数组
   */
  public static getObjectEntries<T>(
    obj: unknown
  ): [string, T][] {
    if (obj === null || obj === undefined || typeof obj !== 'object') {
      return [];
    }
    return Object.entries(obj) as [string, T][];
  }

  /**
   * 安全地合并多个对象
   * @param target 目标对象
   * @param sources 源对象
   * @returns 合并后的对象
   */
  public static mergeObjects<T extends Record<string, unknown>>(
    target: T,
    ...sources: Record<string, unknown>[]
  ): T {
    const result = { ...TypeSafeUtil.asObject(target) };
    
    sources.forEach(source => {
      const safeSource = TypeSafeUtil.asObject(source);
      Object.keys(safeSource).forEach(key => {
        const sourceValue = safeSource[key];
        const targetValue = result[key];
        
        // 如果两边都是对象，递归合并
        if (typeof sourceValue === 'object' && 
            sourceValue !== null && 
            !Array.isArray(sourceValue) &&
            typeof targetValue === 'object' &&
            targetValue !== null &&
            !Array.isArray(targetValue)) {
          result[key] = TypeSafeUtil.mergeObjects(
            targetValue as Record<string, unknown>,
            sourceValue as Record<string, unknown>
          );
        } else {
          result[key] = sourceValue;
        }
      });
    });
    
    return result as T;
  }

  /**
   * 安全地深拷贝对象
   * @param value 要拷贝的值
   * @returns 拷贝后的新值
   */
  public static deepClone<T>(value: T): T {
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
      return value.map(item => TypeSafeUtil.deepClone(item)) as T;
    }
    
    // 处理对象
    const cloned: Record<string, unknown> = {};
    Object.keys(value as Record<string, unknown>).forEach(key => {
      cloned[key] = TypeSafeUtil.deepClone(
        (value as Record<string, unknown>)[key]
      );
    });
    
    return cloned as T;
  }

  /**
   * 类型守卫：检查值是否为对象
   * @param value 要检查的值
   * @returns 是否为对象
   */
  public static isObject(value: unknown): value is Record<string, unknown> {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  }

  /**
   * 类型守卫：检查值是否为数组
   * @param value 要检查的值
   * @returns 是否为数组
   */
  public static isArray<T>(value: unknown): value is T[] {
    return Array.isArray(value);
  }

  /**
   * 类型守卫：检查值是否为函数
   * @param value 要检查的值
   * @returns 是否为函数
   */
  public static isFunction(value: unknown): value is Function {
    return typeof value === 'function';
  }

  /**
   * 安全地进行类型断言
   * @param value 要断言的值
   * @param typeGuard 类型守卫函数
   * @param defaultValue 默认值
   * @returns 断言后的值或默认值
   */
  public static safeAssert<T>(
    value: unknown,
    typeGuard: (v: unknown) => v is T,
    defaultValue: T
  ): T {
    return typeGuard(value) ? value : defaultValue;
  }

  /**
   * 安全地执行函数
   * @param fn 要执行的函数
   * @param defaultValue 默认值
   * @param args 函数参数
   * @returns 函数执行结果或默认值
   */
  public static safeExecute<T>(
    fn: (...args: Array<string | number | boolean | object | null>) => T,
    defaultValue: T,
    ...args: Array<string | number | boolean | object | null>
  ): T {
    try {
      return TypeSafeUtil.isFunction(fn) ? fn(...args) : defaultValue;
    } catch {
      return defaultValue;
    }
  }
}
