/**
 * JSON工具类 - 全功能版本
 * 提供安全的JSON序列化和反序列化功能
 */
export default class JsonUtil {
  /**
   * 检查对象是否包含指定属性
   */
  private static hasOwnProperty(obj: Object, key: string): boolean {
    return Object.getOwnPropertyNames(obj).includes(key);
  }
  /**
   * 将对象序列化为JSON字符串
   * @param value - 要序列化的对象
   * @returns JSON字符串
   */
  static stringify(value: string | number | boolean | Record<string, string | number | boolean> | null): string {
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
  static parse(jsonStr: string): Record<string, string | number | boolean | null> {
    try {
      const result = JSON.parse(jsonStr);
      // 确保返回类型安全
      if (typeof result === 'object' && result !== null && !Array.isArray(result)) {
        return result as Record<string, string | number | boolean | null>;
      }
      return {};
    } catch {
      return {};
    }
  }

  /**
   * 安全的JSON解析，不会抛出异常
   * @param jsonStr - JSON字符串
   * @returns 解析后的对象，解析失败返回空对象
   */
  static safeParse(jsonStr: string): Record<string, string | number | boolean | null> {
    return JsonUtil.parse(jsonStr);
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
      return JSON.parse(JSON.stringify(obj)) as T;
    } catch {
      // 克隆失败时返回原始对象的安全副本
      if (obj === null) {
        return null as T;
      }
      // 返回空对象，保持类型一致性
      return {} as T;
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
      const obj = JSON.parse(jsonStr);
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
  static merge(...objects: Record<string, string | number | boolean | null>[]): Record<string, string | number | boolean | null> {
    const result: Record<string, string | number | boolean | null> = {};
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
    return result;
  }

  /**
   * 过滤对象中的null和undefined值
   * @param obj - 要过滤的对象
   * @returns 过滤后的对象
   */
  static filterNullUndefined(obj: Record<string, string | number | boolean | null>): Record<string, string | number | boolean | null> {
    // 创建明确类型的结果对象
    const result: Record<string, string | number | boolean | null> = {};
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
    return result;
  }
}

/**
 * 安全的JSON序列化函数
 * @param value - 要序列化的对象
 * @returns JSON字符串
 */
export function safeStringify(value: string | number | boolean | Record<string, string | number | boolean> | null): string {
  return JsonUtil.stringify(value);
}

/**
 * 快速解析JSON字符串（别名）
 * @param jsonStr - JSON字符串
 * @returns 解析后的对象
 */
export function quickParse(jsonStr: string): Record<string, string | number | boolean | null> {
  return JsonUtil.parse(jsonStr);
}

/**
 * 类型安全的JSON工具类
 */
export class JSONUtils {
  /**
   * 序列化对象为JSON字符串
   */
  static stringify(value: string | number | boolean | Record<string, string | number | boolean> | null): string {
    return JsonUtil.stringify(value);
  }
  
  /**
   * 解析JSON字符串为对象
   */
  static parse(jsonStr: string): Record<string, string | number | boolean | null> {
    return JsonUtil.parse(jsonStr);
  }
  
  /**
   * 安全的JSON解析
   */
  static safeParse(jsonStr: string): Record<string, string | number | boolean | null> {
    return JsonUtil.safeParse(jsonStr);
  }
  
  /**
   * 深度克隆对象
   */
  static deepClone<T>(obj: T): T {
    return JsonUtil.deepClone(obj);
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
  static merge(...objects: Record<string, string | number | boolean | null>[]): Record<string, string | number | boolean | null> {
    return JsonUtil.merge(...objects);
  }
  
  /**
   * 过滤null/undefined值
   */
  static filterNull(obj: Record<string, string | number | boolean | null>): Record<string, string | number | boolean | null> {
    return JsonUtil.filterNullUndefined(obj);
  }
}