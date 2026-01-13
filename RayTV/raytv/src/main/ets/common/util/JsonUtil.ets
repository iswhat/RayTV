/**
 * JSON utility class | JSON工具类
 * Provides safe JSON serialization and deserialization functionality | 提供安全的JSON序列化和反序列化功能
 */
export default class JsonUtil {
  /**
   * Safely parses JSON string | 安全地解析JSON字符串
   * @param jsonStr JSON string | JSON字符串
   * @returns Parsed object, null if parsing fails | 解析后的对象，解析失败返回null
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
   * Safely serializes object to JSON string | 安全地序列化对象为JSON字符串
   * @param obj Object to serialize | 要序列化的对象
   * @param space Indentation spaces, default no indentation | 缩进格式数，默认不缩进
   * @returns JSON string, empty string if serialization fails | JSON字符串，序列化失败返回空字符串
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
   * Safely parses JSON array | 安全地解析JSON数组
   * @param jsonStr JSON string | JSON字符串
   * @returns Parsed array, empty array if parsing fails | 解析后的数组，解析失败返回空数组
   */
  public static parseArray<T>(jsonStr: string): T[] {
    try {
      const parsed = JSON.parse(jsonStr) as unknown;
      if (Array.isArray(parsed)) {
        return parsed as T[];
      }
      return [];
    } catch (error) {
      console.error('JsonUtil: Failed to parse JSON array:', error);
      return [];
    }
  }

  /**
   * Deep clones object | 深克隆对象
   * @param obj Object to clone | 要克隆的对象
   * @returns Cloned object | 克隆后的对象
   */
  public static deepClone<T>(obj: T): T {
    try {
      return JSON.parse(JSON.stringify(obj)) as T;
    } catch (error) {
      console.error('JsonUtil: Failed to deep clone object:', error);
      return obj;
    }
  }

  /**
   * Merges two JSON objects | 合并两个JSON对象
   * @param target Target object | 目标对象
   * @param source Source object | 源对象
   * @returns Merged object | 合并后的对象
   */
  public static merge(target: Record<string, string | number | boolean | null>, source: Record<string, string | number | boolean | null>): Record<string, string | number | boolean | null> {
    try {
      const merged = { ...target };
      for (const key in source) {
        if (Object.prototype.hasOwnProperty.call(source, key)) {
          merged[key] = source[key];
        }
      }
      return merged;
    } catch (error) {
      console.error('JsonUtil: Failed to merge objects:', error);
      return target;
    }
  }

  /**
   * Checks if string is valid JSON | 检查字符串是否为有效的JSON
   * @param jsonStr String to check | 要检查的字符串
   * @returns Is valid JSON | 是否为有效的JSON
   */
  public static isValidJson(jsonStr: string): boolean {
    try {
      JSON.parse(jsonStr);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Formats JSON string | 格式化JSON字符串
   * @param jsonStr JSON string | JSON字符串
   * @param indent Indentation spaces, default 2 | 缩进空格数，默认2
   * @returns Formatted JSON string | 格式化后的JSON字符串
   */
  public static format(jsonStr: string, indent: number = 2): string {
    try {
      const parsed = JSON.parse(jsonStr) as unknown;
      return JSON.stringify(parsed, null, indent);
    } catch (error) {
      console.error('JsonUtil: Failed to format JSON string:', error);
      return jsonStr;
    }
  }

  /**
   * Compresses JSON string | 压缩JSON字符串
   * @param jsonStr JSON string | JSON字符串
   * @returns Compressed JSON string | 压缩后的JSON字符串
   */
  public static compress(jsonStr: string): string {
    try {
      const parsed = JSON.parse(jsonStr) as unknown;
      return JSON.stringify(parsed);
    } catch (error) {
      console.error('JsonUtil: Failed to compress JSON string:', error);
      return jsonStr;
    }
  }

  /**
   * Extracts specific field from JSON string | 从JSON字符串中提取指定字段
   * @param jsonStr JSON string | JSON字符串
   * @param field Field name to extract | 要提取的字段名
   * @returns Extracted field value, undefined if extraction fails | 提取的字段值，提取失败返回undefined
   */
  public static extractField(jsonStr: string, field: string): string | number | boolean | null | undefined {
    try {
      const parsed = JSON.parse(jsonStr) as Record<string, string | number | boolean | null>;
      return parsed[field];
    } catch (error) {
      console.error('JsonUtil: Failed to extract field from JSON string:', error);
      return undefined;
    }
  }
}

