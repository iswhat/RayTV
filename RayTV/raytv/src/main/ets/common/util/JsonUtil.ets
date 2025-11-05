// JsonUtil - JSON数据处理工具类
import { Logger, LogLevel } from './Logger';

const TAG = 'JsonUtil';

/**
 * JSON工具类
 * 提供JSON数据的序列化和反序列化功能，包含异常处理和格式化
 */
export default class JsonUtil {
  /**
   * 将对象序列化为JSON字符串
   * @param obj 要序列化的对象
   * @param pretty 是否格式化输出
   * @returns JSON字符串
   */
  public static stringify(obj: object, pretty: boolean = false): string {
    try {
      if (pretty) {
        return JSON.stringify(obj, null, 2);
      }
      return JSON.stringify(obj);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to stringify object: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 将JSON字符串反序列化为对象
   * @param jsonStr JSON字符串
   * @returns 反序列化后的对象
   */
  public static parse<T>(jsonStr: string): T | null {
    try {
      if (!jsonStr || typeof jsonStr !== 'string') {
        throw new Error('Invalid JSON string');
      }
      return JSON.parse(jsonStr) as T;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to parse JSON: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 安全的JSON解析，解析失败时返回默认值
   * @param jsonStr JSON字符串
   * @param defaultValue 默认值
   * @returns 解析结果或默认值
   */
  public static safeParse<T>(jsonStr: string, defaultValue: T): T | null {
    try {
      return JsonUtil.parse<T>(jsonStr);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().warn(`${TAG} - Safe parse fallback to default value: ${errorMessage}`);
      return defaultValue;
    }
  }

  /**
   * 检查字符串是否为有效的JSON格式
   * @param jsonStr 待检查的字符串
   * @returns 是否为有效JSON
   */
  public static isValidJson(jsonStr: string): boolean {
    if (!jsonStr || typeof jsonStr !== 'string') {
      return false;
    }
    
    try {
      JSON.parse(jsonStr);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 深拷贝对象（通过JSON序列化）
   * @param obj 要拷贝的对象
   * @returns 拷贝后的新对象
   */
  public static deepClone<T>(obj: T): T {
    try {
      // 处理循环引用和特殊类型
      if (obj === null || typeof obj !== 'object') {
        return obj;
      }
      
      if (obj instanceof Date) {
        return new Date(obj.getTime()) as T;
      }
      
      if (Array.isArray(obj)) {
        const cloneArr: unknown[] = [];
        for (let i = 0; i < obj.length; i++) {
          cloneArr[i] = JsonUtil.deepClone(obj[i]);
        }
        return cloneArr as T;
      }
      
      if (typeof obj === 'object' && obj !== null) {
        const cloneObj: Record<string, unknown> = {};
        // 使用Object.keys替代for..in循环
        const keys = Object.keys(obj as Record<string, unknown>);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          cloneObj[key] = JsonUtil.deepClone((obj as Record<string, unknown>)[key]);
        }
        return cloneObj as T;
      }
      
      return obj;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to deep clone object: ${errorMessage}`);
      return obj;
    }
  }

  /**
   * 合并两个JSON对象
   * @param target 目标对象
   * @param source 源对象
   * @returns 合并后的对象
   */
  public static merge<T>(target: T, source: Record<string, unknown>): T {
    try {
      const result = JsonUtil.deepClone(target);
      
      // 安全地转换result为可索引对象
      const resultObj = result as Record<string, unknown>;
      
      // 使用Object.keys替代for..in循环
      const sourceKeys = Object.keys(source);
      for (let i = 0; i < sourceKeys.length; i++) {
        const key = sourceKeys[i];
        const sourceValue = source[key];
        const targetValue = resultObj[key];
        
        // 递归合并对象属性
        if (sourceValue !== null && typeof sourceValue === 'object' &&
            targetValue !== null && typeof targetValue === 'object') {
          resultObj[key] = JsonUtil.merge(targetValue, sourceValue as Record<string, unknown>);
        } else {
          resultObj[key] = sourceValue;
        }
      }
      
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to merge JSON objects: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从对象中提取指定的属性
   * @param obj 源对象
   * @param keys 要提取的属性名数组
   * @returns 提取后的新对象
   */
  public static pick<T extends Record<string, unknown>>(obj: unknown, keys: string[]): T {
    try {
      const result: Record<string, unknown> = {};
      
      // 使用标准for循环替代forEach
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (obj && typeof obj === 'object' && Object.prototype.hasOwnProperty.call(obj, key)) {
          result[key] = (obj as Record<string, unknown>)[key];
        }
      }
      
      return result as T;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to pick properties: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 从对象中排除指定的属性
   * @param obj 源对象
   * @param keys 要排除的属性名数组
   * @returns 排除后的新对象
   */
  public static omit<T extends Record<string, unknown>>(obj: unknown, keys: string[]): T {
    try {
      const result: Record<string, unknown> = {};
      
      if (obj && typeof obj === 'object') {
        // 使用Object.keys替代for..in循环
        const objKeys = Object.keys(obj as Record<string, unknown>);
        for (let i = 0; i < objKeys.length; i++) {
          const key = objKeys[i];
          // 检查key是否在排除列表中
          let shouldExclude = false;
          for (let j = 0; j < keys.length; j++) {
            if (keys[j] === key) {
              shouldExclude = true;
              break;
            }
          }
          if (!shouldExclude) {
            result[key] = (obj as Record<string, unknown>)[key];
          }
        }
      }
      
      return result as T;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to omit properties: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 压缩JSON字符串（去除空格和换行）
   * @param jsonStr 原始JSON字符串
   * @returns 压缩后的JSON字符串
   */
  public static compress(jsonStr: string): string {
    try {
      const parsed = this.parse<object>(jsonStr);
      if (parsed) {
        return this.stringify(parsed);
      }
      return jsonStr;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to compress JSON: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }

  /**
   * 格式化JSON字符串
   * @param jsonStr 原始JSON字符串
   * @returns 格式化后的JSON字符串
   */
  public static format(jsonStr: string): string {
    try {
      const parsed = this.parse<object>(jsonStr);
      if (parsed) {
        return this.stringify(parsed, true);
      }
      return jsonStr;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.getInstance().error(`${TAG} - Failed to format JSON: ${errorMessage}`);
      throw new Error(errorMessage);
    }
  }
}