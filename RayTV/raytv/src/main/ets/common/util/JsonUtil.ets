/**
 * JSON工具类，提供安全的JSON序列化和反序列化功能
 */
export default class JsonUtil {
  /**
   * 安全地解析JSON字符串
   * @param jsonStr JSON字符串
   * @returns 解析后的对象，解析失败返回null
   */
  public static parse(jsonStr: string): Record<string, string | number | boolean | null> | null {
    try {
      const parsed = JSON.parse(jsonStr) as Record<string, string | number | boolean | null>;
      if (typeof parsed === 'object' && parsed !== null && !Array.isArray(parsed)) {
        return parsed;
      }
      return null;
    } catch (error) {
      console.error('JsonUtil: Failed to parse JSON string:', error);
      return null;
    }
  }

  /**
   * 安全地序列化对象为JSON字符串
   * @param obj 要序列化的对象
   * @param space 缩进空格数，默认不缩进
   * @returns JSON字符串，序列化失败返回空字符串
   */
  public static stringify(obj: Record<string, string | number | boolean | null | undefined> | null | undefined, space?: number): string {
    try {
      if (obj === null || obj === undefined) {
        return 'null';
      }
      return JSON.stringify(obj, null, space);
    } catch (error) {
      console.error('JsonUtil: Failed to stringify object:', error);
      return '';
    }
  }

  /**
   * 深拷贝对象
   * @param obj 要拷贝的对象
   * @returns 拷贝后的对象
   */
  public static deepClone<T extends Record<string, string | number | boolean | null | undefined> | Array<string | number | boolean | null | undefined>>(obj: T): T {
    if (obj === null || typeof obj !== 'object') {
      return obj;
    }
    
    const clone: T = Array.isArray(obj) ? [] as T : {} as T;
    const keys = Object.keys(obj);
    keys.forEach((key: string) => {
      const value = obj[key as keyof T];
      if (value !== null && typeof value === 'object') {
        clone[key as keyof T] = JsonUtil.deepClone(value as T[keyof T] & (Record<string, string | number | boolean | null | undefined> | Array<string | number | boolean | null | undefined>)) as T[keyof T];
      } else {
        clone[key as keyof T] = value;
      }
    });
    
    return clone;
  }

  /**
   * 合并两个对象
   * @param target 目标对象
   * @param source 源对象
   * @returns 合并后的对象
   */
  public static merge<T extends Record<string, string | number | boolean | null | undefined>, U extends Record<string, string | number | boolean | null | undefined>>(target: T, source: U): Record<string, string | number | boolean | null | undefined> {
    const result: Record<string, string | number | boolean | null | undefined> = {};
    
    // 复制target属性
    const targetKeys = Object.keys(target);
    targetKeys.forEach((key: string) => {
      result[key] = target[key as keyof T];
    });
    
    // 复制source属性，覆盖target中的同名属性
    const sourceKeys = Object.keys(source);
    sourceKeys.forEach((key: string) => {
      result[key] = source[key as keyof U];
    });
    
    return result;
  }

  /**
   * 检查字符串是否为有效的JSON
   * @param str 要检查的字符串
   * @returns 是否为有效JSON
   */
  public static isValidJSON(str: string): boolean {
    try {
      JSON.parse(str);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 美化JSON字符串
   * @param jsonStr JSON字符串
   * @param indent 缩进空格数，默认2
   * @returns 美化后的JSON字符串
   */
  public static prettyPrint(jsonStr: string, indent: number = 2): string {
    try {
      const parsed = JSON.parse(jsonStr) as Record<string, string | number | boolean | null>;
      return JSON.stringify(parsed, null, indent);
    } catch {
      return jsonStr;
    }
  }

  /**
   * 过滤对象中的null和undefined值
   * @param obj 要过滤的对象
   * @returns 过滤后的对象
   */
  public static filterNullUndefined<T extends Record<string, string | number | boolean | null | undefined>>(obj: T): Record<string, string | number | boolean> {
    const result: Record<string, string | number | boolean> = {};
    const keys = Object.keys(obj);
    keys.forEach((key: string) => {
      const value = obj[key as keyof T];
      if (value !== null && value !== undefined) {
        result[key] = value as string | number | boolean;
      }
    });
    return result;
  }

  /**
   * 安全解析JSON字符串，返回指定类型
   * @param jsonStr JSON字符串
   * @returns 解析后的对象，解析失败返回null
   */
  public static safeParse<T extends Record<string, string | number | boolean | null>>(jsonStr: string): T | null {
    try {
      const parsed = JSON.parse(jsonStr) as T;
      return parsed;
    } catch (error) {
      console.error('JsonUtil: Failed to safe parse JSON string:', error);
      return null;
    }
  }
}

/**
 * 安全的JSON序列化函数
 * @param value 要序列化的对象
 * @returns JSON字符串
 */
export function safeStringify(value: Record<string, string | number | boolean | null>): string {
  return JsonUtil.stringify(value);
}

/**
 * 快速解析JSON字符串
 * @param jsonStr JSON字符串
 * @returns 解析后的对象
 */
export function quickParse(jsonStr: string): Record<string, string | number | boolean | null> {
  const result = JsonUtil.parse(jsonStr);
  return result || {};
}

/**
 * 检查JSON字符串是否有效
 * @param str 要检查的字符串
 * @returns 是否为有效JSON
 */
export function isValidJSON(str: string): boolean {
  return JsonUtil.isValidJSON(str);
}
