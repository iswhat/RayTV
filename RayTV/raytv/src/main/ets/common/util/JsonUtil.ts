/**
 * JsonUtil - JSON工具类
 * 提供JSON数据的解析、生成和操作工具函数
 */
import Logger from './Logger';
import StringUtils from './StringUtils';

export class JsonUtil {
  private static readonly TAG: string = 'JsonUtil';

  /**
   * 将对象序列化为JSON字符串
   * @param obj 要序列化的对象
   * @param replacer 替换函数或数组
   * @param space 缩进空格数
   * @returns 序列化后的JSON字符串
   */
  public static stringify(obj: any, replacer?: (key: string, value: any) => any | Array<string | number>, space?: string | number): string | null {
    try {
      return JSON.stringify(obj, replacer, space);
    } catch (error) {
      Logger.error(JsonUtil.TAG, 'Failed to stringify object', error);
      return null;
    }
  }

  /**
   * 解析JSON字符串为对象
   * @param jsonStr JSON字符串
   * @param reviver 恢复函数
   * @returns 解析后的对象或null
   */
  public static parse<T = any>(jsonStr: string | null | undefined, reviver?: (key: any, value: any) => any): T | null {
    if (StringUtils.isEmpty(jsonStr)) return null;
    
    try {
      return JSON.parse(jsonStr as string, reviver) as T;
    } catch (error) {
      Logger.error(JsonUtil.TAG, 'Failed to parse JSON string', error);
      return null;
    }
  }

  /**
   * 深拷贝对象（使用JSON序列化/反序列化）
   * @param obj 要拷贝的对象
   * @returns 拷贝后的新对象
   */
  public static deepClone<T = any>(obj: T): T | null {
    if (obj === null || typeof obj !== 'object') return obj;
    
    try {
      return JsonUtil.parse<T>(JsonUtil.stringify(obj));
    } catch (error) {
      Logger.error(JsonUtil.TAG, 'Failed to deep clone object', error);
      return null;
    }
  }

  /**
   * 安全地获取嵌套属性
   * @param obj 对象
   * @param path 属性路径，支持dot notation (e.g., 'a.b.c')
   * @param defaultValue 默认值
   * @returns 属性值或默认值
   */
  public static getNestedProperty<T = any>(obj: any, path: string, defaultValue: T | null = null): T | null {
    if (obj === null || typeof obj !== 'object' || StringUtils.isEmpty(path)) {
      return defaultValue;
    }
    
    try {
      const properties = path.split('.');
      let result: any = obj;
      
      for (const prop of properties) {
        if (result === null || result === undefined) {
          return defaultValue;
        }
        result = result[prop];
      }
      
      return (result !== undefined) ? result : defaultValue;
    } catch (error) {
      Logger.error(JsonUtil.TAG, `Failed to get nested property: ${path}`, error);
      return defaultValue;
    }
  }

  /**
   * 安全地设置嵌套属性
   * @param obj 对象
   * @param path 属性路径，支持dot notation (e.g., 'a.b.c')
   * @param value 要设置的值
   * @returns 是否设置成功
   */
  public static setNestedProperty(obj: any, path: string, value: any): boolean {
    if (obj === null || typeof obj !== 'object' || StringUtils.isEmpty(path)) {
      return false;
    }
    
    try {
      const properties = path.split('.');
      let current: any = obj;
      
      // 遍历到倒数第二个属性
      for (let i = 0; i < properties.length - 1; i++) {
        const prop = properties[i];
        if (current[prop] === undefined) {
          // 判断下一个属性是否为数字（数组索引）
          const nextIsNumber = !isNaN(Number(properties[i + 1]));
          current[prop] = nextIsNumber ? [] : {};
        } else if (typeof current[prop] !== 'object') {
          // 如果已有值但不是对象，覆盖为对象
          const nextIsNumber = !isNaN(Number(properties[i + 1]));
          current[prop] = nextIsNumber ? [] : {};
        }
        current = current[prop];
      }
      
      // 设置最后一个属性
      current[properties[properties.length - 1]] = value;
      return true;
    } catch (error) {
      Logger.error(JsonUtil.TAG, `Failed to set nested property: ${path}`, error);
      return false;
    }
  }

  /**
   * 检查JSON字符串是否有效
   * @param jsonStr 要检查的字符串
   * @returns 是否为有效JSON
   */
  public static isValidJson(jsonStr: string | null | undefined): boolean {
    if (StringUtils.isEmpty(jsonStr)) return false;
    
    try {
      JSON.parse(jsonStr as string);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 合并两个对象
   * @param target 目标对象
   * @param source 源对象
   * @param deep 是否深度合并
   * @returns 合并后的对象
   */
  public static mergeObjects(target: any, source: any, deep: boolean = true): any {
    if (source === null || typeof source !== 'object') return target;
    if (target === null || typeof target !== 'object') return JsonUtil.deepClone(source);
    
    try {
      const result = { ...target };
      
      for (const key in source) {
        if (Object.prototype.hasOwnProperty.call(source, key)) {
          if (deep && typeof source[key] === 'object' && source[key] !== null && 
              typeof result[key] === 'object' && result[key] !== null) {
            // 递归合并嵌套对象
            result[key] = JsonUtil.mergeObjects(result[key], source[key], true);
          } else {
            // 直接覆盖
            result[key] = source[key];
          }
        }
      }
      
      return result;
    } catch (error) {
      Logger.error(JsonUtil.TAG, 'Failed to merge objects', error);
      return target;
    }
  }

  /**
   * 从对象中提取指定属性
   * @param obj 源对象
   * @param keys 要提取的属性名数组
   * @returns 包含指定属性的新对象
   */
  public static pick<T = any>(obj: any, keys: string[]): Partial<T> {
    if (obj === null || typeof obj !== 'object') return {};
    
    const result: any = {};
    
    try {
      keys.forEach(key => {
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
          result[key] = obj[key];
        }
      });
      
      return result;
    } catch (error) {
      Logger.error(JsonUtil.TAG, 'Failed to pick properties', error);
      return {};
    }
  }

  /**
   * 从对象中排除指定属性
   * @param obj 源对象
   * @param keys 要排除的属性名数组
   * @returns 排除指定属性后的新对象
   */
  public static omit<T = any>(obj: any, keys: string[]): Partial<T> {
    if (obj === null || typeof obj !== 'object') return {};
    
    const result: any = {};
    const keySet = new Set(keys);
    
    try {
      for (const key in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, key) && !keySet.has(key)) {
          result[key] = obj[key];
        }
      }
      
      return result;
    } catch (error) {
      Logger.error(JsonUtil.TAG, 'Failed to omit properties', error);
      return {};
    }
  }

  /**
   * 将对象转换为URL查询字符串
   * @param params 参数对象
   * @returns URL查询字符串
   */
  public static toQueryString(params: Record<string, any>): string {
    if (!params || typeof params !== 'object') return '';
    
    try {
      const searchParams = new URLSearchParams();
      
      Object.entries(params).forEach(([key, value]) => {
        if (value !== null && value !== undefined) {
          if (Array.isArray(value)) {
            value.forEach(item => searchParams.append(key, item.toString()));
          } else if (typeof value === 'object') {
            searchParams.append(key, JsonUtil.stringify(value) || '');
          } else {
            searchParams.append(key, value.toString());
          }
        }
      });
      
      return searchParams.toString();
    } catch (error) {
      Logger.error(JsonUtil.TAG, 'Failed to convert to query string', error);
      return '';
    }
  }

  /**
   * 从URL查询字符串转换为对象
   * @param queryString 查询字符串
   * @returns 参数对象
   */
  public static fromQueryString(queryString: string): Record<string, any> {
    if (StringUtils.isEmpty(queryString)) return {};
    
    try {
      const params = new URLSearchParams(queryString);
      const result: Record<string, any> = {};
      
      params.forEach((value, key) => {
        if (key in result) {
          // 处理重复键
          if (!Array.isArray(result[key])) {
            result[key] = [result[key]];
          }
          result[key].push(value);
        } else {
          // 尝试解析JSON值
          if (JsonUtil.isValidJson(value)) {
            result[key] = JsonUtil.parse(value);
          } else {
            result[key] = value;
          }
        }
      });
      
      return result;
    } catch (error) {
      Logger.error(JsonUtil.TAG, 'Failed to parse query string', error);
      return {};
    }
  }
}

export default JsonUtil;