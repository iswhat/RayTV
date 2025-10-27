// JsonUtil - JSON数据处理工具类
import Logger from './Logger';

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
  public static stringify(obj: any, pretty: boolean = false): string {
    try {
      if (pretty) {
        return JSON.stringify(obj, null, 2);
      }
      return JSON.stringify(obj);
    } catch (error) {
      Logger.error(TAG, `Failed to stringify object: ${error}`);
      throw error;
    }
  }

  /**
   * 将JSON字符串反序列化为对象
   * @param jsonStr JSON字符串
   * @returns 反序列化后的对象
   */
  public static parse<T = any>(jsonStr: string): T {
    try {
      if (!jsonStr || typeof jsonStr !== 'string') {
        throw new Error('Invalid JSON string');
      }
      return JSON.parse(jsonStr) as T;
    } catch (error) {
      Logger.error(TAG, `Failed to parse JSON: ${error}`);
      throw error;
    }
  }

  /**
   * 安全的JSON解析，解析失败时返回默认值
   * @param jsonStr JSON字符串
   * @param defaultValue 默认值
   * @returns 解析结果或默认值
   */
  public static safeParse<T = any>(jsonStr: string, defaultValue: T): T {
    try {
      return this.parse<T>(jsonStr);
    } catch (error) {
      Logger.warn(TAG, `Safe parse fallback to default value: ${error}`);
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
  public static deepClone<T = any>(obj: T): T {
    try {
      // 处理循环引用和特殊类型
      if (obj === null || typeof obj !== 'object') {
        return obj;
      }
      
      if (obj instanceof Date) {
        return new Date(obj.getTime()) as unknown as T;
      }
      
      if (obj instanceof Array) {
        const cloneArr: any[] = [];
        for (let i = 0; i < obj.length; i++) {
          cloneArr[i] = this.deepClone(obj[i]);
        }
        return cloneArr as unknown as T;
      }
      
      if (typeof obj === 'object') {
        const cloneObj: Record<string, any> = {};
        for (const key in obj) {
          if (obj.hasOwnProperty(key)) {
            cloneObj[key] = this.deepClone(obj[key]);
          }
        }
        return cloneObj as T;
      }
      
      return obj;
    } catch (error) {
      Logger.error(TAG, `Failed to deep clone object: ${error}`);
      throw error;
    }
  }

  /**
   * 合并两个JSON对象
   * @param target 目标对象
   * @param source 源对象
   * @returns 合并后的对象
   */
  public static merge<T = any>(target: T, source: any): T {
    try {
      const result = this.deepClone(target);
      
      for (const key in source) {
        if (source.hasOwnProperty(key)) {
          if (typeof source[key] === 'object' && source[key] !== null && 
              typeof (result as any)[key] === 'object' && (result as any)[key] !== null) {
            (result as any)[key] = this.merge((result as any)[key], source[key]);
          } else {
            (result as any)[key] = source[key];
          }
        }
      }
      
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to merge JSON objects: ${error}`);
      throw error;
    }
  }

  /**
   * 从对象中提取指定的属性
   * @param obj 源对象
   * @param keys 要提取的属性名数组
   * @returns 提取后的新对象
   */
  public static pick<T = any>(obj: any, keys: string[]): T {
    try {
      const result: Record<string, any> = {};
      
      keys.forEach(key => {
        if (obj && obj.hasOwnProperty(key)) {
          result[key] = obj[key];
        }
      });
      
      return result as T;
    } catch (error) {
      Logger.error(TAG, `Failed to pick properties: ${error}`);
      throw error;
    }
  }

  /**
   * 从对象中排除指定的属性
   * @param obj 源对象
   * @param keys 要排除的属性名数组
   * @returns 排除后的新对象
   */
  public static omit<T = any>(obj: any, keys: string[]): T {
    try {
      const result: Record<string, any> = {};
      
      for (const key in obj) {
        if (obj.hasOwnProperty(key) && !keys.includes(key)) {
          result[key] = obj[key];
        }
      }
      
      return result as T;
    } catch (error) {
      Logger.error(TAG, `Failed to omit properties: ${error}`);
      throw error;
    }
  }

  /**
   * 压缩JSON字符串（去除空格和换行）
   * @param jsonStr 原始JSON字符串
   * @returns 压缩后的JSON字符串
   */
  public static compress(jsonStr: string): string {
    try {
      const parsed = this.parse(jsonStr);
      return this.stringify(parsed);
    } catch (error) {
      Logger.error(TAG, `Failed to compress JSON: ${error}`);
      throw error;
    }
  }

  /**
   * 格式化JSON字符串
   * @param jsonStr 原始JSON字符串
   * @returns 格式化后的JSON字符串
   */
  public static format(jsonStr: string): string {
    try {
      const parsed = this.parse(jsonStr);
      return this.stringify(parsed, true);
    } catch (error) {
      Logger.error(TAG, `Failed to format JSON: ${error}`);
      throw error;
    }
  }
}