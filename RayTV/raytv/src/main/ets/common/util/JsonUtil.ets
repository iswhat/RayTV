// JsonUtil.ets - 简化版JSON工具类

import Logger from './Logger';

const TAG = 'JsonUtil';

/**
 * 基本JSON值类型
 */
export type JsonValue = string | number | boolean | null | object;

/**
 * 安全的JSON解析
 * @param jsonString JSON字符串
 * @param defaultValue 默认值
 */
export function safeParseJson(jsonString: string, defaultValue: object): object {
  if (!jsonString || jsonString.trim() === '') {
    Logger.warn(TAG, 'Empty JSON string provided');
    return defaultValue;
  }

  try {
    const parsed = JSON.parse(jsonString);
    return parsed ?? defaultValue;
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    Logger.error(TAG, `Failed to parse JSON: ${errorMessage}`);
    return defaultValue;
  }
}

/**
 * 安全的JSON字符串化
 * @param obj 要序列化的对象
 */
export function safeStringify(obj: object): string {
  try {
    if (obj === null || typeof obj === 'undefined') {
      return 'null';
    }
    return JSON.stringify(obj);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    Logger.error(TAG, `Failed to stringify object: ${errorMessage}`);
    return 'null';
  }
}

/**
 * 检查对象是否具有指定的自有属性
 * @param obj 要检查的对象
 * @param key 属性名
 */
export function hasKey(obj: object, key: string): boolean {
  if (obj === null || typeof obj !== 'object') {
    return false;
  }
  return Object.prototype.hasOwnProperty.call(obj, key);
}

/**
 * 获取对象的所有自有属性键
 * @param obj 要获取键的对象
 */
export function getObjectKeys(obj: object): string[] {
  if (obj === null || typeof obj !== 'object') {
    return [];
  }
  return Object.keys(obj);
}

/**
 * 安全获取对象属性值
 * @param obj 要获取属性的对象
 * @param key 属性名
 */
export function getValue(obj: object, key: string): JsonValue {
  try {
    if (obj === null || typeof obj !== 'object') {
      return null;
    }
    
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      const descriptor = Object.getOwnPropertyDescriptor(obj, key);
      if (descriptor && descriptor.value !== undefined) {
        return descriptor.value;
      }
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * 创建一个新的空对象
 */
export function createObject(): object {
  return Object.create(null);
}

/**
 * 设置对象属性
 * @param obj 对象
 * @param key 属性名
 * @param value 属性值
 */
export function setValue(obj: object, key: string, value: JsonValue): void {
  if (obj === null || typeof obj !== 'object') {
    return;
  }
  
  Object.defineProperty(obj, key, {
    value: value,
    writable: true,
    enumerable: true,
    configurable: true
  });
}

/**
 * 深度克隆简单对象
 * @param obj 要克隆的对象
 */
export function deepClone(obj: JsonValue): JsonValue {
  if (obj === null || typeof obj !== 'object') {
    return obj;
  }
  
  if (Array.isArray(obj)) {
    const result = [];
    const length = obj.length;
    for (let i = 0; i < length; i++) {
      const item = obj[i];
      result.push(deepClone(item));
    }
    return result;
  }
  
  const result = createObject();
  const keys = getObjectKeys(obj);
  const keysLength = keys.length;
  
  for (let i = 0; i < keysLength; i++) {
    const key = keys[i];
    const value = getValue(obj, key);
    setValue(result, key, deepClone(value));
  }
  
  return result;
}