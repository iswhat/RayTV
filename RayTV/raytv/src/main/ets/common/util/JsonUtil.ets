/**
 * JSON数据类，用于安全地处理JSON对象
 */
export class JsonData {
  private data: Record<string, string | number | boolean | null> = {};

  /**
   * 设置属性值
   * @param key - 属性名
   * @param value - 属性值
   */
  set(key: string, value: string | number | boolean | null): void {
    this.data[key] = value;
  }

  /**
   * 获取属性值
   * @param key - 属性名
   * @returns 属性值
   */
  get(key: string): string | number | boolean | null | undefined {
    return this.data[key];
  }

  /**
   * 检查属性是否存在
   * @param key - 属性名
   * @returns 是否存在
   */
  has(key: string): boolean {
    // 使用Object.keys和includes替代Object.prototype.hasOwnProperty.call
    return Object.keys(this.data).includes(key);
  }

  /**
   * 获取所有属性名
   * @returns 属性名数组
   */
  keys(): string[] {
    return Object.keys(this.data);
  }

  /**
   * 转换为普通对象
   * @returns 转换后的对象
   */
  toObject(): Record<string, string | number | boolean | null> {
    // 直接返回this.data的副本，避免递归调用
    const result: Record<string, string | number | boolean | null> = {};
    const keys = Object.keys(this.data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      result[key] = this.data[key];
    }
    return result;
  }
}

/**
 * JSON工具类 - 全功能版本
 * 提供安全的JSON序列化和反序列化功能
 */
export default class JsonUtil {
  /**
   * 检查对象是否包含指定属性
   * 使用Object.keys和includes替代Object.prototype.hasOwnProperty.call
   */
  private static hasOwnProperty<T extends object>(obj: T, key: string | number): boolean {
    // 使用Object.keys和includes替代Object.prototype.hasOwnProperty.call
    if (typeof obj !== 'object' || obj === null) {
      return false;
    }
    const keys = Object.keys(obj);
    return keys.includes(String(key));
  }

  /**
   * 安全地获取对象属性值，避免字段索引访问错误
   * @param obj - 要访问的对象
   * @param key - 属性名
   * @returns 属性值
   */
  private static getPropertyValue<T extends object>(obj: T, key: string): string | number | boolean | null | undefined {
    if (typeof obj !== 'object' || obj === null) {
      return undefined;
    }
    
    // 使用类型安全的属性访问方式
    const recordObj = obj as Record<string, string | number | boolean | null>;
    if (JsonUtil.hasOwnProperty(recordObj, key)) {
      return recordObj[key];
    }
    
    return undefined;
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
      console.error('JSON stringify failed:', error instanceof Error ? error.message : String(error));
      return "{}";
    }
  }

  /**
   * 将JSON字符串解析为对象
   * @param jsonStr JSON字符串
   * @returns 解析后的对象
   */
  static parse<T>(jsonStr: string): T {
    try {
      if (typeof jsonStr !== 'string') {
        // 参数类型不匹配时抛出明确的类型错误
        throw new TypeError('Expected string as input to parse method');
      }
      // 使用明确的类型断言以兼容ArkTS
      return JSON.parse(jsonStr) as T;
    } catch (error) {
      // 使用更明确的错误类型处理以兼容ArkTS
      console.error('JSON parse failed:', error instanceof Error ? error.message : String(error));
      // 返回空对象并进行适当的类型断言
      const emptyResult: Record<string, string | number | boolean | null> = {};
      return emptyResult as T;
    }
  }

  /**
   * 安全地解析JSON字符串，出错时返回默认值
   * @param jsonStr JSON字符串
   * @param defaultValue 默认值
   * @returns 解析后的对象或默认值
   */
  static safeParse<T>(jsonStr: string, defaultValue?: T): T | null {
    try {
      if (!jsonStr || typeof jsonStr !== 'string') {
        return defaultValue || null;
      }
      // 使用明确的类型断言以兼容ArkTS
      return JSON.parse(jsonStr) as T;
    } catch (error) {
      // 使用明确的错误类型处理以兼容ArkTS
      console.error('JSON parse failed:', error instanceof Error ? error.message : String(error));
      return defaultValue || null;
    }
  }

  /**
   * 深度克隆对象
   * @param obj - 要克隆的对象
   * @returns 克隆后的新对象
   */
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
        // 使用具体的数组类型替代unknown[]
        const clonedArray: (string | number | boolean | null)[] = [];
        for (let i = 0; i < obj.length; i++) {
          // 确保索引有效，安全访问数组元素
          if (i >= 0 && i < obj.length) {
            // 使用类型安全的数组访问方式，避免any/unknown类型
            const arrayItem = (obj as (string | number | boolean | null)[])[i];
            clonedArray[i] = JsonUtil.deepClone(arrayItem);
          }
        }
        return clonedArray as T;
      }
      
      // 处理对象字面量
      const clone: Record<string, string | number | boolean | null> = {};
      
      // 使用Object.getOwnPropertyNames获取属性名
      const keys = Object.getOwnPropertyNames(obj);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const safeKey = String(key);
        // 使用类型安全的属性访问方式，避免字段索引访问
        const propertyValue = JsonUtil.getPropertyValue(obj, safeKey);
        // 修复类型错误：确保deepClone返回正确的类型
        const clonedValue = JsonUtil.deepClone<string | number | boolean | null>(propertyValue as string | number | boolean | null);
        if (clonedValue !== undefined) {
          clone[safeKey] = clonedValue as string | number | boolean | null;
        }
      }
      
      return clone as T;
    } catch (error) {
      console.error('Deep clone failed:', error instanceof Error ? error.message : String(error));
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
      const parsed: Record<string, string | number | boolean | null> = JSON.parse(jsonStr) as Record<string, string | number | boolean | null>;
      
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
  static merge<T extends Record<string, string | number | boolean | null>>(...objects: T[]): T {
    // 使用JsonData类替代对象字面量
    const jsonData = new JsonData();
    
    // 替换外层for..of循环
    for (let i = 0; i < objects.length; i++) {
      const current = objects[i];
      if (!current || typeof current !== 'object') {
        continue;
      }
      
      const keys = Object.getOwnPropertyNames(current);
      // 替换内层for..of循环
      for (let j = 0; j < keys.length; j++) {
        const key = keys[j];
        if (JsonUtil.hasOwnProperty(current, key)) {
          // 使用类型安全的属性访问方式，避免字段索引访问
          const propertyValue = JsonUtil.getPropertyValue(current, key);
          // 修复类型错误：确保属性值类型正确
          if (propertyValue !== undefined) {
            jsonData.set(key, propertyValue as string | number | boolean | null);
          }
        }
      }
    }
    
    return jsonData.toObject() as T;
  }

  /**
   * 过滤对象中的null和undefined值
   * @param obj - 要过滤的对象
   * @returns 过滤后的对象
   */
  static filterNullUndefined<T extends Record<string, string | number | boolean | null>>(
    obj: T
  ): Record<string, string | number | boolean | null> {
    // 类型安全检查
    if (!obj || typeof obj !== 'object') {
      const emptyResult: Record<string, string | number | boolean | null> = {};
      return emptyResult;
    }
    
    // 使用JsonData类替代对象字面量
    const jsonData = new JsonData();
    const keys = Object.getOwnPropertyNames(obj);
    
    // 替换for..of循环为标准for循环
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (JsonUtil.hasOwnProperty(obj, key)) {
        // 使用类型安全的属性访问方式，避免字段索引访问
        const value = JsonUtil.getPropertyValue(obj, key);
        // 确保值不为null且不为undefined
        if (value !== null && value !== undefined) {
          // 修复类型错误：确保值类型正确
          jsonData.set(key, value as string | number | boolean | null);
        }
      }
    }
    
    // 直接返回明确的类型
    return jsonData.toObject();
  }
}

/**
 * 安全的JSON序列化函数
 * @param value - 要序列化的对象
 * @returns JSON字符串
 */
export function safeStringify(value: Record<string, string | number | boolean | null>): string {
  return JsonUtil.stringify(value);
}

/**
 * 快速解析JSON字符串（别名）
 * @param jsonStr - JSON字符串
 * @returns 解析后的对象
 */
export function quickParse(jsonStr: string): Record<string, string | number | boolean | null> {
  return JsonUtil.parse<Record<string, string | number | boolean | null>>(jsonStr);
}

/**
 * 检查JSON字符串是否有效
 * @param str - 要检查的字符串
 * @returns 是否为有效JSON
 */
export function isValidJSON(str: string): boolean {
  return JsonUtil.isValidJSON(str);
}