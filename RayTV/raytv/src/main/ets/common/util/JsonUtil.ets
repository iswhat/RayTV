/**
 * JSON工具类 - 全功能版本
 * 提供安全的JSON序列化和反序列化功能
 */
export default class JsonUtil {
  /**
   * 检查对象是否包含指定属性
   */
  private static hasOwnProperty(obj: Record<string, string | number | boolean | object | null>, key: string): boolean {
    // 使用ArkTS兼容的方式检查属性存在性
    return Object.keys(obj).includes(key);
  }
  /**
   * 将对象序列化为JSON字符串
   * @param value - 要序列化的对象
   * @returns JSON字符串
   */
  static stringify<T>(value: T): string {
    try {
      return JSON.stringify(value);
    } catch {
      return "{}";
    }
  }

  /**
   * 将JSON字符串解析为对象
   * @param jsonStr - JSON字符串
   * @returns 解析后的对象
   */
  static parse<T extends Record<string, string | number | boolean | object | null>>(jsonStr: string): T {
    try {
      // 使用泛型确保类型安全
      const result: object = JSON.parse(jsonStr);
      // 确保返回类型安全
      if (typeof result === 'object' && result !== null) {
        return result as T;
      }
      // 使用明确的类型创建空对象
      const emptyObj: Record<string, string | number | boolean | object | null> = {};
      return emptyObj as T;
    } catch {
      // 使用明确的类型创建空对象
      const emptyObj: Record<string, string | number | boolean | object | null> = {};
      return emptyObj as T;
    }
  }

  /**
   * 安全的JSON解析，不会抛出异常
   * @param jsonStr - JSON字符串
   * @returns 解析后的对象，解析失败返回空对象
   */
  static safeParse<T extends Record<string, string | number | boolean | object | null>>(jsonStr: string): T {
    return JsonUtil.parse<T>(jsonStr);
  }

  /**
   * 深度克隆对象
   * @param obj - 要克隆的对象
   * @returns 克隆后的新对象
   */
  static deepClone<T extends object | null>(obj: T): T {
    try {
      // 处理null的情况
      if (obj === null) {
        return null as T;
      }
      // 对于对象类型，使用类型安全的方式克隆
      const cloned: Record<string, string | number | boolean | object | null> = JSON.parse(JSON.stringify(obj));
      return cloned as T;
    } catch {
      // 克隆失败时返回原始对象的安全副本
      if (obj === null) {
        return null as T;
      }
      // 返回空对象，保持类型一致性
      const emptyObj: Record<string, string | number | boolean | object | null> = {};
      return emptyObj as T;
    }
  }

  /**
   * 检查字符串是否为有效的JSON
   * @param str - 要检查的字符串
   * @returns 是否为有效JSON
   */
  static isValidJSON(str: string): boolean {
    try {
      JSON.parse(str);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 美化JSON字符串
   * @param jsonStr - JSON字符串
   * @param indent - 缩进空格数，默认2
   * @returns 美化后的JSON字符串
   */
  static prettyPrint(jsonStr: string, indent: number = 2): string {
    try {
      // 使用明确类型进行解析
      const parsed: object = JSON.parse(jsonStr);
      const obj: Record<string, string | number | boolean | object | null> = 
        typeof parsed === 'object' && parsed !== null ? parsed as Record<string, string | number | boolean | object | null> : {};
      return JSON.stringify(obj, null, indent);
    } catch {
      return jsonStr;
    }
  }

  /**
   * 合并多个JSON对象
   * @param objects - 要合并的对象数组
   * @returns 合并后的对象
   */
  static merge<T extends Record<string, string | number | boolean | object | null>>(...objects: T[]): T {
    const result: Record<string, string | number | boolean | object | null> = {};
    for (let i = 0; i < objects.length; i++) {
      const current = objects[i];
      const keys = Object.getOwnPropertyNames(current);
      for (let j = 0; j < keys.length; j++) {
        const key = keys[j];
        if (JsonUtil.hasOwnProperty(current, key)) {
          result[key] = current[key];
        }
      }
    }
    return result as T;
  }

  /**
   * 过滤对象中的null和undefined值
   * @param obj - 要过滤的对象
   * @returns 过滤后的对象
   */
  static filterNullUndefined<T extends Record<string, string | number | boolean | object | null>>(obj: T): T {
    // 创建明确类型的结果对象
    const result: Record<string, string | number | boolean | object | null> = {};
    const keys = Object.getOwnPropertyNames(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (JsonUtil.hasOwnProperty(obj, key)) {
        const value = obj[key];
        // 确保值不为null且不为undefined（ArkTS中undefined需要明确处理）
        if (value !== null && typeof value !== 'undefined') {
          result[key] = value;
        }
      }
    }
    return result as T;
  }
}

/**
 * 安全的JSON序列化函数
 * @param value - 要序列化的对象
 * @returns JSON字符串
 */
export function safeStringify<T>(value: T): string {
  return JsonUtil.stringify<T>(value);
}

/**
 * 快速解析JSON字符串（别名）
 * @param jsonStr - JSON字符串
 * @returns 解析后的对象
 */
export function quickParse<T extends Record<string, string | number | boolean | object | null>>(jsonStr: string): T {
  return JsonUtil.parse<T>(jsonStr);
}

/**
 * 类型安全的JSON工具类
 */
export class JSONUtils {
  /**
   * 序列化对象为JSON字符串
   */
  static stringify<T>(value: T): string {
    return JsonUtil.stringify<T>(value);
  }
  
  /**
   * 解析JSON字符串为对象
   */
  static parse<T extends Record<string, string | number | boolean | object | null>>(jsonStr: string): T {
    return JsonUtil.parse<T>(jsonStr);
  }
  
  /**
   * 安全的JSON解析
   */
  static safeParse<T extends Record<string, string | number | boolean | object | null>>(jsonStr: string): T {
    return JsonUtil.safeParse<T>(jsonStr);
  }
  
  /**
   * 深度克隆对象
   */
  static deepClone<T extends object | null>(obj: T): T {
    return JsonUtil.deepClone<T>(obj);
  }
  
  /**
   * 检查JSON有效性
   */
  static isValid(str: string): boolean {
    return JsonUtil.isValidJSON(str);
  }
  
  /**
   * 美化JSON输出
   */
  static pretty(jsonStr: string, indent: number = 2): string {
    return JsonUtil.prettyPrint(jsonStr, indent);
  }
  
  /**
   * 合并对象
   */
  static merge<T extends Record<string, string | number | boolean | object | null>>(...objects: T[]): T {
    return JsonUtil.merge<T>(...objects);
  }
  
  /**
   * 过滤null/undefined值
   */
  static filterNull<T extends Record<string, string | number | boolean | object | null>>(obj: T): T {
    return JsonUtil.filterNullUndefined<T>(obj);
  }
}