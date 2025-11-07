// JsonUtil.ets - JSON工具类
// 提供JSON序列化、反序列化、深拷贝、对象合并等功能

import Logger from './Logger';

const TAG = 'JsonUtil';

/**
 * 安全的JSON解析
 * @param jsonString JSON字符串
 * @param defaultValue 默认值
 */
export function safeParseJson<T>(jsonString: string, defaultValue: T): T {
  if (!jsonString) {
    Logger.warn(TAG, 'Empty JSON string provided');
    return defaultValue;
  }

  try {
    const parsed = JSON.parse(jsonString) as T;
    return parsed;
  } catch (error) {
    Logger.error(TAG, `Failed to parse JSON: ${error instanceof Error ? error.message : String(error)}`);
    Logger.debug(TAG, `JSON string: ${jsonString}`);
    return defaultValue;
  }
}

/**
 * 安全的JSON字符串化
 * @param obj 要序列化的对象
 * @param indent 缩进空格数
 */
export function safeStringify(obj: object, indent: number = 0): string {
  try {
    if (obj === null || typeof obj === 'undefined') {
      return 'null';
    }
    return JSON.stringify(obj, null, indent);
  } catch (error) {
    Logger.error(TAG, `Failed to stringify object: ${error instanceof Error ? error.message : String(error)}`);
    return '{}';
  }
}

/**
 * 深拷贝对象
 * @param source 源对象
 */
export function deepClone<T>(source: T): T {
  if (source === null || typeof source !== 'object') {
    return source;
  }

  try {
    // 对于循环引用，使用JSON方法处理会失败
    // 这里使用简单的实现，对于复杂对象可能需要更复杂的深拷贝算法
    const serialized = JSON.stringify(source);
    return JSON.parse(serialized) as T;
  } catch (error) {
    Logger.error(TAG, `Failed to deep clone object: ${error instanceof Error ? error.message : String(error)}`);
    // 如果克隆失败，返回原始对象
    return source;
  }
}

/**
 * 合并两个对象
 * @param target 目标对象
 * @param source 源对象
 */
export function merge<T extends object, U extends object>(target: T, source: U): object {
  const result = { ...target } as object;
  
  // 遍历源对象的属性
  for (const key in source) {
    if (source.hasOwnProperty(key)) {
      const sourceValue = source[key];
      const targetValue = (result as any)[key];
      
      if (sourceValue !== null && typeof sourceValue === 'object' && 
          !Array.isArray(sourceValue) && 
          targetValue !== null && 
          typeof targetValue === 'object' && 
          !Array.isArray(targetValue)) {
        // 递归合并对象
        (result as any)[key] = merge(targetValue, sourceValue);
      } else {
        // 对于基本类型、数组和null，直接赋值
        (result as any)[key] = sourceValue;
      }
    }
  }
  
  return result;
}

/**
 * 从对象中提取指定属性
 * @param obj 源对象
 * @param keys 要提取的属性键数组
 */
export function pick<T extends object>(obj: T, keys: string[]): object {
  const result: Record<string, any> = {};
  
  // 使用循环处理属性提取
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    if (key in obj) {
      result[key] = obj[key];
    }
  }
  
  return result;
}

/**
 * 从对象中排除指定属性
 * @param obj 源对象
 * @param keys 要排除的属性键数组
 */
export function omit<T extends object>(obj: T, keys: string[]): object {
  const result: Record<string, any> = { ...obj };
  
  // 使用循环处理属性排除
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    if (key in result) {
      delete result[key];
    }
  }
  
  return result;
}

/**
 * 检查对象是否为空
 * @param obj 要检查的对象
 */
export function isEmptyObject(obj: object): boolean {
  if (obj === null || typeof obj !== 'object') {
    return true;
  }
  
  for (const key in obj) {
    if (obj.hasOwnProperty(key)) {
      return false;
    }
  }
  
  return true;
}

/**
 * 比较两个对象是否深度相等
 * @param obj1 第一个对象
 * @param obj2 第二个对象
 */
export function deepEqual(obj1: any, obj2: any): boolean {
  if (obj1 === obj2) {
    return true;
  }
  
  if (obj1 === null || obj2 === null || typeof obj1 !== 'object' || typeof obj2 !== 'object') {
    return false;
  }
  
  try {
    // 使用JSON序列化进行比较（不处理循环引用）
    return JSON.stringify(obj1) === JSON.stringify(obj2);
  } catch (error) {
    Logger.warn(TAG, `Failed to compare objects deeply: ${error instanceof Error ? error.message : String(error)}`);
    return false;
  }
}

/**
 * 将对象的键值对转换为URL查询参数
 * @param params 参数对象
 */
export function toQueryString(params: Record<string, string | number | boolean>): string {
  const queryParts: string[] = [];
  
  for (const key in params) {
    if (params.hasOwnProperty(key)) {
      const value = params[key];
      const encodedKey = encodeURIComponent(key);
      const encodedValue = encodeURIComponent(String(value));
      queryParts.push(`${encodedKey}=${encodedValue}`);
    }
  }
  
  return queryParts.join('&');
}

/**
 * 从URL查询参数解析为对象
 * @param queryString 查询参数字符串
 */
export function parseQueryString(queryString: string): Record<string, string> {
  const result: Record<string, string> = {};
  
  if (!queryString) {
    return result;
  }
  
  // 移除开头的问号
  const cleanQuery = queryString.startsWith('?') ? queryString.substring(1) : queryString;
  
  const pairs = cleanQuery.split('&');
  
  for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];
    const [key, value] = pair.split('=');
    
    if (key) {
      const decodedKey = decodeURIComponent(key);
      const decodedValue = value ? decodeURIComponent(value) : '';
      result[decodedKey] = decodedValue;
    }
  }
  
  return result;
}