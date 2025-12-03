// JsonUtils.ets - ArkTS兼容的JSON工具函数

/**
 * JSON工具函数
 * 提供ArkTS环境中安全的JSON操作功能
 */
import { Optional, SafeAny } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';
import StringUtils from './StringUtils';

/**
 * JSON工具函数集合
 */
export const JsonUtils = {
  /**
   * 检查值是否可以被序列�?   */
  isSerializable(value: Record<string, string | number | boolean | null>): boolean {
    try {
      JSON.stringify(value);
      return true;
    } catch {
      return false;
    }
  },

  /**
   * 安全的JSON序列化函�?   * 替代JSON.stringify
   */
  stringify(value: Record<string, string | number | boolean | null>, replacer?: (key: string, value: SafeAny) => SafeAny | Array<number | string>, space?: string | number): string | null {
    try {
      return JSON.stringify(value, replacer, space);
    } catch (e) {
      console.error('JsonUtils.stringify error:', e);
      return null;
    }
  },

  /**
   * 安全的JSON反序列化函数
   * 替代JSON.parse
   */
  parse<T = SafeAny>(jsonString: Optional<string>): T | null {
    if (StringUtils.isEmpty(jsonString)) {
      return null;
    }
    
    try {
      return JSON.parse(jsonString) as T;
    } catch (e) {
      console.error('JsonUtils.parse error:', e);
      return null;
    }
  },

  /**
   * 美化JSON字符�?   */
  prettify(jsonString: Optional<string>, indent: number = 2): string | null {
    const parsed = JsonUtils.parse(jsonString);
    
    if (parsed === null) {
      return null;
    }
    
    return JsonUtils.stringify(parsed, null, indent);
  },

  /**
   * 压缩JSON字符串（移除多余的空白字符）
   */
  compress(jsonString: Optional<string>): string | null {
    if (StringUtils.isEmpty(jsonString)) {
      return null;
    }
    
    try {
      // 先解析再序列化，移除所有空白字�?      const parsed = JSON.parse(jsonString);
      return JSON.stringify(parsed);
    } catch (e) {
      console.error('JsonUtils.compress error:', e);
      return null;
    }
  },

  /**
   * 深拷贝对象（使用JSON序列�?反序列化�?   */
  deepClone<T>(obj: T): T | null {
    if (obj === null || typeof obj !== 'object') {
      // 对于原始类型，直接返�?      return obj;
    }
    
    try {
      return JSON.parse(JSON.stringify(obj)) as T;
    } catch (e) {
      console.error('JsonUtils.deepClone error:', e);
      return null;
    }
  },

  /**
   * 合并两个对象（浅合并�?   */
  merge<T extends Record<string, SafeAny>, U extends Record<string, SafeAny>>(target: T, source: U): T & U {
    if (!TypeUtils.isObject(target) || !TypeUtils.isObject(source)) {
      return target as T & U;
    }
    
    const result: Record<string, string | number | boolean | null> = { ... };
    
    for (const key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        // 使用类型安全的属性访问方�?        const propertyValue = JsonUtils.getPropertyValue(source, key);
        (result as Record<string, SafeAny>)[key] = propertyValue;
      }
    }
    
    return result as T & U;
  },

  /**
   * 合并两个对象（深合并�?   */
  deepMerge<T extends Record<string, SafeAny>, U extends Record<string, SafeAny>>(target: T, source: U): T & U {
    if (!TypeUtils.isObject(target) || !TypeUtils.isObject(source)) {
      return source !== undefined && source !== null ? source as T & U : target as T & U;
    }
    
    const result: Record<string, string | number | boolean | null> = { ... };
    
    for (const key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        // 使用类型安全的属性访问方�?        const targetValue = JsonUtils.getPropertyValue(target, key);
        const sourceValue = JsonUtils.getPropertyValue(source, key);
        
        if (TypeUtils.isObject(targetValue) && TypeUtils.isObject(sourceValue) && !Array.isArray(targetValue) && !Array.isArray(sourceValue)) {
          // 递归合并嵌套对象
          (result as Record<string, SafeAny>)[key] = JsonUtils.deepMerge(targetValue as Record<string, SafeAny>, sourceValue as Record<string, SafeAny>);
        } else {
          (result as Record<string, SafeAny>)[key] = sourceValue;
        }
      }
    }
    
    return result as T & U;
  },

  /**
   * 比较两个对象是否相等（使用JSON序列化）
   */
  equals(obj1: Record<string, string | number | boolean | null>, obj2: Record<string, string | number | boolean | null>): boolean {
    try {
      return JsonUtils.stringify(obj1) === JsonUtils.stringify(obj2);
    } catch (e) {
      console.error('JsonUtils.equals error:', e);
      return false;
    }
  },

  /**
   * 提取JSON对象的特定路径�?   */
  getValueByPath<T = SafeAny>(obj: Record<string, SafeAny>, path: string, defaultValue?: T): T | null {
    if (!TypeUtils.isObject(obj) || StringUtils.isEmpty(path)) {
      return defaultValue !== undefined ? defaultValue : null;
    }
    
    // 处理点号分隔的路�?    const pathParts = path.split('.');
    let current: SafeAny = obj;
    
    for (let i = 0; i < pathParts.length; i++) {
      const part = pathParts[i];
      
      if (TypeUtils.isObject(current) && part in current) {
        current = current[part];
      } else {
        return defaultValue !== undefined ? defaultValue : null;
      }
    }
    
    return current as T;
  },

  /**
   * 设置JSON对象的特定路径�?   */
  setValueByPath(obj: Record<string, SafeAny>, path: string, value: SafeAny): boolean {
    if (!TypeUtils.isObject(obj) || StringUtils.isEmpty(path)) {
      return false;
    }
    
    // 处理点号分隔的路�?    const pathParts = path.split('.');
    let current: Record<string, SafeAny> = obj;
    
    // 遍历路径部分，除了最后一�?    for (let i = 0; i < pathParts.length - 1; i++) {
      const part = pathParts[i];
      
      if (!(part in current) || !TypeUtils.isObject(current[part])) {
        current[part] = {};
      }
      
      current = current[part] as Record<string, SafeAny>;
    }
    
    // 设置最后一个路径部分的�?    const lastPart = pathParts[pathParts.length - 1];
    current[lastPart] = value;
    
    return true;
  },

  /**
   * 移除JSON对象的特定路径�?   */
  removeValueByPath(obj: Record<string, SafeAny>, path: string): boolean {
    if (!TypeUtils.isObject(obj) || StringUtils.isEmpty(path)) {
      return false;
    }
    
    // 处理点号分隔的路�?    const pathParts = path.split('.');
    let current: Record<string, SafeAny> = obj;
    let parent: Record<string, SafeAny> | null = null;
    let lastKey: string = '';
    
    // 遍历路径部分，除了最后一�?    for (let i = 0; i < pathParts.length; i++) {
      const part = pathParts[i];
      
      if (!(part in current)) {
        return false; // 路径不存�?      }
      
      if (i === pathParts.length - 1) {
        // 最后一个部分，从父对象中删�?        lastKey = part;
      } else {
        parent = current;
        current = current[part] as Record<string, SafeAny>;
        
        if (!TypeUtils.isObject(current)) {
          return false;
        }
      }
    }
    
    if (parent && lastKey in parent) {
      delete parent[lastKey];
      return true;
    }
    
    return false;
  },

  /**
   * 安全地获取对象属性�?   * @param obj - 要获取属性的对象
   * @param key - 属性键�?   * @returns 属性值，如果属性不存在则返回undefined
   */
  getPropertyValue(obj: Record<string, SafeAny>, key: string): Record<string, string | number | boolean | null> {
    if (!TypeUtils.isObject(obj)) {
      return undefined;
    }
    
    if (!(key in obj)) {
      return undefined;
    }
    
    // 使用类型安全的属性访问方�?    return obj[key];
  },

  /**
   * 检查JSON对象是否包含特定路径
   */
  hasPath(obj: Record<string, SafeAny>, path: string): boolean {
    if (!TypeUtils.isObject(obj) || StringUtils.isEmpty(path)) {
      return false;
    }
    
    // 处理点号分隔的路�?    const pathParts = path.split('.');
    let current: SafeAny = obj;
    
    for (let i = 0; i < pathParts.length; i++) {
      const part = pathParts[i];
      
      if (TypeUtils.isObject(current) && part in current) {
        current = current[part];
      } else {
        return false;
      }
    }
    
    return true;
  },

  /**
   * 过滤JSON对象，只保留指定的属�?   */
  pick<T extends Record<string, SafeAny>>(obj: T, keys: string[]): Partial<T> {
    if (!TypeUtils.isObject(obj) || !Array.isArray(keys)) {
      return {};
    }
    
    const result: Partial<T> = {};
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key in obj) {
        result[key] = obj[key];
      }
    }
    
    return result;
  },

  /**
   * 过滤JSON对象，排除指定的属�?   */
  omit<T extends Record<string, SafeAny>>(obj: T, keys: string[]): Partial<T> {
    if (!TypeUtils.isObject(obj) || !Array.isArray(keys)) {
      return { ...obj };
    }
    
    const result: Partial<T> = {};
    const keySet = new Set(keys);
    
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key) && !keySet.has(key)) {
        result[key] = obj[key];
      }
    }
    
    return result;
  },

  /**
   * 清理JSON对象，移除undefined和null�?   */
  clean(obj: Record<string, SafeAny>, removeEmpty: boolean = false): Record<string, SafeAny> {
    if (!TypeUtils.isObject(obj)) {
      return {};
    }
    
    const result: Record<string, SafeAny> = {};
    
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        const value = obj[key];
        
        if (value !== undefined && value !== null) {
          if (TypeUtils.isObject(value) && !Array.isArray(value)) {
            // 递归清理嵌套对象
            const cleanedValue = JsonUtils.clean(value as Record<string, SafeAny>, removeEmpty);
            
            // 如果需要移除空对象，并且清理后的对象为空，则跳�?            if (!removeEmpty || Object.keys(cleanedValue).length > 0) {
              result[key] = cleanedValue;
            }
          } else if (!removeEmpty || (Array.isArray(value) && value.length > 0) || (!Array.isArray(value))) {
            result[key] = value;
          }
        }
      }
    }
    
    return result;
  },

  /**
   * 将对象转换为查询字符�?   */
  toQueryString(obj: Record<string, SafeAny>): string {
    if (!TypeUtils.isObject(obj)) {
      return '';
    }
    
    const parts: string[] = [];
    
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        const value = obj[key];
        
        if (value !== undefined && value !== null) {
          const encodedKey = encodeURIComponent(key);
          const encodedValue = encodeURIComponent(String(value));
          parts.push(`${encodedKey}=${encodedValue}`);
        }
      }
    }
    
    return parts.join('&');
  },

  /**
   * 将查询字符串转换为对�?   */
  fromQueryString(queryString: Optional<string>): Record<string, string> {
    if (StringUtils.isEmpty(queryString)) {
      return {};
    }
    
    // 移除可能的问号前缀
    const cleanQuery = queryString.startsWith('?') ? queryString.slice(1) : queryString;
    
    const result: Record<string, string> = {};
    const pairs = cleanQuery.split('&');
    
    for (let i = 0; i < pairs.length; i++) {
      const pair = pairs[i];
      const [key, value] = pair.split('=');
      
      if (key) {
        try {
          result[decodeURIComponent(key)] = value ? decodeURIComponent(value) : '';
        } catch (e) {
          console.error('JsonUtils.fromQueryString error decoding pair:', pair, e);
        }
      }
    }
    
    return result;
  }
};

export default JsonUtils;

