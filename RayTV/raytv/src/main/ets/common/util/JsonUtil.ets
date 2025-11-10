// JsonUtil.ets - JSON工具类
// 提供JSON序列化、反序列化等基本功能

import Logger from './Logger';

const TAG = 'JsonUtil';

/**
 * 基本JSON值类型
 */
export type JsonValue = string | number | boolean | null | object;

/**
 * 定义一个简单的对象接口
 */
export interface SimpleObject {
  [key: string]: JsonValue;
}

/**
 * 安全的JSON解析
 * @param jsonString JSON字符串
 * @param defaultValue 默认值
 */
export function safeParseJson<T>(jsonString: string, defaultValue: T): T {
  if (!jsonString || jsonString.trim() === '') {
    Logger.warn(TAG, 'Empty JSON string provided');
    return defaultValue;
  }

  try {
    const parsed = JSON.parse(jsonString);
    return parsed as T;
  } catch (error) {
    Logger.error(TAG, `Failed to parse JSON: ${error instanceof Error ? error.message : String(error)}`);
    Logger.debug(TAG, `JSON string: ${jsonString}`);
    return defaultValue;
  }
}

/**
 * 安全的JSON字符串化
 * @param obj 要序列化的对象
 */
export function safeStringify(obj: JsonValue): string {
  try {
    if (obj === null || typeof obj === 'undefined') {
      return 'null';
    }
    return JSON.stringify(obj, null, 0);
  } catch (error) {
    Logger.error(TAG, `Failed to stringify object: ${error instanceof Error ? error.message : String(error)}`);
    return '{}';
  }
}

/**
 * 获取对象的所有键
 */
export function getObjectKeys(obj: object): string[] {
  const keys: string[] = [];
  
  try {
    const allKeys = Object.keys(obj);
    for (let i = 0; i < allKeys.length; i++) {
      keys.push(allKeys[i]);
    }
  } catch (error) {
    Logger.warn(TAG, `Failed to get object keys: ${error instanceof Error ? error.message : String(error)}`);
  }
  
  return keys;
}

/**
 * 检查对象是否包含指定键
 */
export function hasKey(obj: object, key: string): boolean {
  try {
    const keys = getObjectKeys(obj);
    for (let i = 0; i < keys.length; i++) {
      if (keys[i] === key) {
        return true;
      }
    }
    return false;
  } catch {
    return false;
  }
}

/**
 * 安全获取对象属性值
 */
export function getValue(obj: object, key: string): JsonValue {
  try {
    if (hasKey(obj, key)) {
      return (obj as SimpleObject)[key];
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * 简单的对象合并
 */
export function merge(target: object, source: object): SimpleObject {
  const result: SimpleObject = {} as SimpleObject;
  
  // 复制目标对象属性
  const targetKeys = getObjectKeys(target);
  for (let i = 0; i < targetKeys.length; i++) {
    const key = targetKeys[i];
    if (hasKey(target, key)) {
      result[key] = getValue(target, key);
    }
  }
  
  // 合并源对象的属性
  const sourceKeys = getObjectKeys(source);
  for (let i = 0; i < sourceKeys.length; i++) {
    const key = sourceKeys[i];
    if (hasKey(source, key)) {
      const sourceValue = getValue(source, key);
      const targetValue = getValue(target, key);
      
      // 判断是否需要递归合并
      if (sourceValue !== null && 
          typeof sourceValue === 'object' && 
          !Array.isArray(sourceValue) && 
          targetValue !== null && 
          typeof targetValue === 'object' && 
          !Array.isArray(targetValue)) {
        // 递归合并对象
        result[key] = merge(targetValue, sourceValue);
      } else {
        // 直接设置源对象的值
        result[key] = sourceValue;
      }
    }
  }
  
  return result;
}

/**
 * 从对象中提取指定属性
 */
export function pick(obj: object, keys: string[]): SimpleObject {
  const result: SimpleObject = {} as SimpleObject;
  
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    if (hasKey(obj, key)) {
      result[key] = getValue(obj, key);
    }
  }
  
  return result;
}

/**
 * 从对象中排除指定属性
 */
export function omit(obj: object, keys: string[]): SimpleObject {
  const result: SimpleObject = {} as SimpleObject;
  const allKeys = getObjectKeys(obj);
  
  for (let i = 0; i < allKeys.length; i++) {
    const key = allKeys[i];
    let shouldExclude = false;
    
    // 检查是否需要排除
    for (let j = 0; j < keys.length; j++) {
      if (keys[j] === key) {
        shouldExclude = true;
        break;
      }
    }
    
    if (!shouldExclude && hasKey(obj, key)) {
      result[key] = getValue(obj, key);
    }
  }
  
  return result;
}

/**
 * 检查对象是否为空
 */
export function isEmptyObject(obj: object): boolean {
  if (obj === null || typeof obj !== 'object') {
    return true;
  }
  
  try {
    const keys = getObjectKeys(obj);
    return keys.length === 0;
  } catch (error) {
    Logger.warn(TAG, `Failed to check if object is empty: ${error instanceof Error ? error.message : String(error)}`);
    return false;
  }
}

/**
 * 比较两个对象是否相等（浅比较）
 */
export function isEqual(obj1: JsonValue, obj2: JsonValue): boolean {
  if (obj1 === obj2) {
    return true;
  }
  
  if (obj1 === null || obj2 === null) {
    return false;
  }
  
  const type1 = typeof obj1;
  const type2 = typeof obj2;
  
  if (type1 !== type2) {
    return false;
  }
  
  if (type1 !== 'object') {
    return obj1 === obj2;
  }
  
  // 处理数组
  if (Array.isArray(obj1) && Array.isArray(obj2)) {
    const arr1 = obj1 as Array<JsonValue>;
    const arr2 = obj2 as Array<JsonValue>;
    
    if (arr1.length !== arr2.length) {
      return false;
    }
    
    for (let i = 0; i < arr1.length; i++) {
      if (!isEqual(arr1[i], arr2[i])) {
        return false;
      }
    }
    
    return true;
  }
  
  // 处理对象
  if (!Array.isArray(obj1) && !Array.isArray(obj2)) {
    const keys1 = getObjectKeys(obj1);
    const keys2 = getObjectKeys(obj2);
    
    if (keys1.length !== keys2.length) {
      return false;
    }
    
    for (let i = 0; i < keys1.length; i++) {
      const key = keys1[i];
      
      // 检查key是否存在于obj2
      let keyExists = false;
      for (let j = 0; j < keys2.length; j++) {
        if (keys2[j] === key) {
          keyExists = true;
          break;
        }
      }
      
      if (!keyExists) {
        return false;
      }
      
      // 比较值
      const val1 = getValue(obj1, key);
      const val2 = getValue(obj2, key);
      if (!isEqual(val1, val2)) {
        return false;
      }
    }
    
    return true;
  }
  
  return false;
}