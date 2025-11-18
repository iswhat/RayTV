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
    } catch (error) {
      console.error('JSON stringify failed:', error);
      return "{}";
    }
  }

  /**
   * 将JSON字符串解析为对象
   * @param jsonStr - JSON字符串
   * @returns 解析后的对象
   */
  static parse<T = unknown>(jsonStr: string): T {
    try {
      if (typeof jsonStr !== 'string') {
        // 确保参数类型正确
        return {} as T;
      }
      const result = JSON.parse(jsonStr);
      return result as T;
    } catch (error) {
      console.error('JSON parse failed:', error);
      // 根据泛型类型返回适当的默认值
      return (typeof ({} as T) === 'object' && ({} as T) !== null) ? {} as T : (undefined as unknown) as T;
    }
  }

  /**
   * 安全的JSON解析，不会抛出异常
   * @param jsonStr - JSON字符串
   * @returns 解析后的对象，解析失败返回适当的默认值
   */
  static safeParse<T = unknown>(jsonStr: string): T {
    return JsonUtil.parse<T>(jsonStr);
  }

  /**
   * 深度克隆对象
   * @param obj - 要克隆的对象
   * @returns 克隆后的新对象
   */
  static deepClone<T>(obj: T): T {
    try {
      // 处理基本类型和null
      if (obj === null || typeof obj !== 'object') {
        return obj;
      }
      
      // 特殊处理Date对象
      if (obj instanceof Date) {
        return new Date(obj.getTime()) as T;
      }
      
      // 特殊处理Array对象
      if (Array.isArray(obj)) {
        return obj.map(item => this.deepClone(item)) as T;
      }
      
      // 处理对象字面量
      if (typeof obj === 'object') {
        // 创建与原始对象相同类型的新对象
        const clone = Array.isArray(obj) ? [] : {};
        
        // 复制所有可枚举属性
        for (const key in obj) {
          if (Object.prototype.hasOwnProperty.call(obj, key)) {
            clone[key] = this.deepClone(obj[key]);
          }
        }
        
        return clone as T;
      }
      
      return obj;
    } catch (error) {
      console.error('Deep clone failed:', error);
      // 在克隆失败时，尝试使用JSON序列化作为备选方案
      try {
        return JSON.parse(JSON.stringify(obj)) as T;
      } catch {
        // 最后回退到返回原始对象
        return obj;
      }
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