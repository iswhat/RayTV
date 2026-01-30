/**
 * JSON utility class | JSON工具类
 * Provides safe JSON serialization and deserialization functionality | 提供安全的JSON序列化和反序列化功能
 */
import Logger from './Logger';

class JsonUtil {
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
      Logger.error('JsonUtil', 'Failed to parse JSON string: ' + error);
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
      Logger.error('JsonUtil', 'Failed to stringify object: ' + error);
      return '';
    }
  }

  /**
   * Safely parses JSON array | 安全地解析JSON数组
   * @param jsonStr JSON string | JSON字符串
   * @returns Parsed array, empty array if parsing fails | 解析后的数组，解析失败返回空数组
   */
  public static parseArray(jsonStr: string): Array<Record<string, string | number | boolean | null>> {
    try {
      const parsed = JSON.parse(jsonStr) as Array<Record<string, string | number | boolean | null>>;
      if (Array.isArray(parsed)) {
        return parsed;
      }
      return [];
    } catch (error) {
      Logger.error('JsonUtil', 'Failed to parse JSON array: ' + error);
      return [];
    }
  }

  /**
   * Deep clones object | 深克隆对象
   * @param obj Object to clone | 要克隆的对象
   * @returns Cloned object | 克隆后的对象
   */
  public static deepClone(obj: Record<string, string | number | boolean | null | undefined> | null): Record<string, string | number | boolean | null> | null {
    try {
      if (obj === null) {
        return null;
      }
      // 创建一个安全对象，排除undefined值
      const safeObj: Record<string, string | number | boolean | null> = {};
      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = obj[key];
        if (value !== undefined) {
          safeObj[key] = value as string | number | boolean | null;
        }
      }
      const cloned = JSON.parse(JSON.stringify(safeObj)) as Record<string, string | number | boolean | null>;
      return cloned;
    } catch (error) {
      Logger.error('JsonUtil', 'Failed to deep clone object: ' + error);
      // 创建一个新对象，排除undefined值
      const safeObj: Record<string, string | number | boolean | null> = {};
      if (typeof obj === 'object' && obj !== null) {
        const keys = Object.keys(obj);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          const value = obj[key];
          if (value !== undefined) {
            safeObj[key] = value as string | number | boolean | null;
          }
        }
      }
      return safeObj;
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
      const merged: Record<string, string | number | boolean | null> = {};
      // 复制target对象
      const targetKeys = JsonUtil.getObjectKeys(target);
      for (let i = 0; i < targetKeys.length; i++) {
        const key = targetKeys[i];
        merged[key] = target[key];
      }
      // 复制source对象，覆盖target中的相同键
      const sourceKeys = JsonUtil.getObjectKeys(source);
      for (let i = 0; i < sourceKeys.length; i++) {
        const key = sourceKeys[i];
        merged[key] = source[key];
      }
      return merged;
    } catch (error) {
      Logger.error('JsonUtil', 'Failed to merge objects: ' + error);
      return target;
    }
  }

  /**
   * Gets object keys | 获取对象键
   * @param obj Object | 对象
   * @returns Array of keys | 键数组
   */
  private static getObjectKeys(obj: Record<string, string | number | boolean | null>): string[] {
    // 使用Object.keys替代for...in循环
    return Object.keys(obj);
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
    } catch (error) {
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
      const parsed: Record<string, string | number | boolean | null> | null = JSON.parse(jsonStr) as Record<string, string | number | boolean | null> | null;
      return JSON.stringify(parsed, null, indent);
    } catch (error) {
      Logger.error('JsonUtil', 'Failed to format JSON string: ' + error);
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
      const parsed: Record<string, string | number | boolean | null> | null = JSON.parse(jsonStr) as Record<string, string | number | boolean | null> | null;
      return JSON.stringify(parsed);
    } catch (error) {
      Logger.error('JsonUtil', 'Failed to compress JSON string: ' + error);
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
      Logger.error('JsonUtil', 'Failed to extract field from JSON string: ' + error);
      return undefined;
    }
  }
}

export default JsonUtil;

