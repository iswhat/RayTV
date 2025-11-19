/**
 * JSON工具类 - 全功能版本
 * 提供安全的JSON序列化和反序列化功能
 */
export default class JsonUtil {
  /**
   * 检查对象是否包含指定属性
   * 使用标准的Object.prototype.hasOwnProperty.call方式确保类型安全
   */
  private static hasOwnProperty<T extends object>(obj: T, key: string | number): boolean {
    // 使用Object.prototype.hasOwnProperty.call替代in操作符
    return typeof obj === 'object' && obj !== null && Object.prototype.hasOwnProperty.call(obj, key);
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
        // 参数类型不匹配时抛出明确的类型错误
        throw new TypeError('Expected string as input to parse method');
      }
      const result = JSON.parse(jsonStr);
      return result as T;
    } catch (error) {
      console.error('JSON parse failed:', error);
      // 移除条件类型，使用简单的默认返回值
      // ArkTS不支持条件类型，直接返回空对象并进行适当的类型断言
      return {} as T;
    }
  }

  /**
   * 安全的JSON解析，不会抛出异常
   * @param jsonStr - JSON字符串
   * @returns 解析后的对象，解析失败返回适当的默认值
   */
  // 移除类型参数的默认值unknown，ArkTS可能不支持这种语法
  static safeParse<T>(jsonStr: string): T {
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
        return obj.map(item => JsonUtil.deepClone(item)) as T;
      }
      
      // 处理对象字面量
      if (typeof obj === 'object') {
        // 创建与原始对象相同类型的新对象
        const clone = Array.isArray(obj) ? [] : {};
        
        // 复制所有可枚举属性
        for (const key in obj) {
          if (JsonUtil.hasOwnProperty(obj, key)) {
            clone[key] = JsonUtil.deepClone(obj[key]);
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
      // 使用明确的序列化值类型进行解析
      const parsed = JSON.parse(jsonStr);
      
      // 检查是否为有效的对象或数组
      if (parsed === null || (typeof parsed !== 'object')) {
        return jsonStr;
      }
      
      return JSON.stringify(parsed, null, indent);
    } catch {
      return jsonStr;
    }
  }

  /**
   * 合并多个JSON对象
   * @param objects - 要合并的对象数组
   * @returns 合并后的对象
   */
  static merge<T extends Record<string, unknown>>(...objects: T[]): T {
    const result: Record<string, unknown> = {};
    
    for (const current of objects) {
      if (!current || typeof current !== 'object') {
        continue;
      }
      
      const keys = Object.getOwnPropertyNames(current);
      for (const key of keys) {
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
  static filterNullUndefined<T extends Record<string, unknown>>(obj: T): Partial<T> {
    // 类型安全检查
    if (!obj || typeof obj !== 'object') {
      return {} as Partial<T>;
    }
    
    // 创建明确类型的结果对象
    const result: Record<string, unknown> = {};
    const keys = Object.getOwnPropertyNames(obj);
    
    for (const key of keys) {
      if (JsonUtil.hasOwnProperty(obj, key)) {
        const value = obj[key];
        // 确保值不为null且不为undefined
        if (value !== null && value !== undefined) {
          result[key] = value;
        }
      }
    }
    
    return result as Partial<T>;
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
export function quickParse<T extends Record<string, unknown>>(jsonStr: string): T {
  return JsonUtil.parse<T>(jsonStr);
}

/**
 * 检查JSON字符串是否有效
 * @param str - 要检查的字符串
 * @returns 是否为有效JSON
 */
export function isValidJSON(str: string): boolean {
  return JsonUtil.isValidJSON(str);
}