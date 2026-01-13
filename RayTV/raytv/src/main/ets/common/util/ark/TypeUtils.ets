// TypeUtils.ets - ArkTS兼容的类型工具函数 ArkTS compatible type utility functions
/**
 * 类型工具函数 Type utility functions
 * 提供ArkTS环境中安全的类型检测和转换功能 Provides safe type detection and conversion functionality in ArkTS environment
 */
import { SafeAny, SafeObject, isNonNull, Optional } from './types/ArkTSBaseTypes';

/**
 * 类型工具函数集合 Type utility functions collection
 */
export const TypeUtils = {
  /**
   * 检查值是否为字符串类型 Check if value is string type
   */
  isString(value: SafeAny): boolean {
    return typeof value === 'string';
  },

  /**
   * 检查值是否为数字类型 Check if value is number type
   */
  isNumber(value: SafeAny): boolean {
    return typeof value === 'number' && !isNaN(value) && isFinite(value);
  },

  /**
   * 检查值是否为布尔类型 Check if value is boolean type
   */
  isBoolean(value: SafeAny): boolean {
    return typeof value === 'boolean';
  },

  /**
   * 检查值是否为undefined Check if value is undefined
   */
  isUndefined(value: SafeAny): boolean {
    return value === undefined;
  },

  /**
   * 检查值是否为null Check if value is null
   */
  isNull(value: SafeAny): boolean {
    return value === null;
  },

  /**
   * 检查值是否为null或undefined Check if value is null or undefined
   */
  isNullOrUndefined(value: SafeAny): boolean {
    return value === null || value === undefined;
  },

  /**
   * 检查值是否为对象类型 Check if value is object type
   */
  isObject(value: SafeAny): boolean {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  },

  /**
   * 检查值是否为数组类型 Check if value is array type
   */
  isArray(value: SafeAny): boolean {
    return Array.isArray(value);
  },

  /**
   * 检查值是否为函数类型 Check if value is function type
   */
  isFunction(value: SafeAny): boolean {
    return typeof value === 'function';
  },

  /**
   * 检查值是否为Date类型 Check if value is Date type
   */
  isDate(value: SafeAny): boolean {
    return value instanceof Date && !isNaN(value.getTime());
  },

  /**
   * 检查值是否为空(包括null、undefined、空字符串、空数组、空对象) Check if value is empty (null, undefined, empty string, empty array, empty object)
   */
  isEmpty(value: SafeAny): boolean {
    if (value === null || value === undefined) {
      return true;
    }
    
    if (typeof value === 'string') {
      return value.trim().length === 0;
    }
    
    if (Array.isArray(value)) {
      return value.length === 0;
    }
    
    if (typeof value === 'object') {
      // 使用Object.keys获取属性数量，避免使用hasOwnProperty Use Object.keys to get property count, avoid using hasOwnProperty
      return Object.keys(value).length === 0;
    }
    
    return false;
  },

  /**
   * 安全地将值转换为字符串 Safely convert value to string
   */
  toString(value: SafeAny, defaultValue: string = ''): string {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    
    return String(value);
  },

  /**
   * 安全地将值转换为数字 Safely convert value to number
   */
  toNumber(value: SafeAny, defaultValue: number = 0): number {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    
    // 直接数字类型检查 Direct number type check
    if (typeof value === 'number') {
      return isFinite(value) ? value : defaultValue;
    }
    
    // 字符串类型转换 String type conversion
    if (typeof value === 'string') {
      const num = parseFloat(value);
      return isFinite(num) ? num : defaultValue;
    }
    
    return defaultValue;
  },

  /**
   * 安全地将值转换为布尔值 Safely convert value to boolean
   */
  toBoolean(value: SafeAny): boolean {
    if (value === null || value === undefined) {
      return false;
    }
    
    // 直接布尔类型检查 Direct boolean type check
    if (typeof value === 'boolean') {
      return value;
    }
    
    // 数字类型转换 Number type conversion
    if (typeof value === 'number') {
      return value !== 0;
    }
    
    // 字符串类型转换 String type conversion
    if (typeof value === 'string') {
      const lowerValue = value.toLowerCase();
      return lowerValue === 'true' || lowerValue === '1';
    }
    
    return true;
  },

  /**
   * 安全地将值转换为数组 Safely convert value to array
   */
  toArray<T>(value: Optional<T | T[]>, defaultValue: T[] = []): T[] {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    
    if (Array.isArray(value)) {
      return value as T[];
    }
    
    return [value as T];
  },

  /**
   * 安全地将值转换为对象 Safely convert value to object
   */
  toObject(value: SafeAny): SafeObject {
    if (value === null || value === undefined || typeof value !== 'object' || Array.isArray(value)) {
      return {};
    }
    
    return value as SafeObject;
  },

  /**
   * 安全地获取对象属性值 Safely get object property value
   * @param obj - 要获取属性的对象 Object to get property from
   * @param key - 属性键名 Property key name
   * @returns 属性值，如果属性不存在则返回undefined Property value, undefined if property doesn't exist
   */
  getPropertyValue(obj: SafeAny, key: string): SafeAny {
    if (!TypeUtils.isObject(obj)) {
      return undefined;
    }
    
    // 使用类型安全的属性查询方式 Use type-safe property query method
    const safeObj = obj as Record<string, SafeAny>;
    if (Object.prototype.hasOwnProperty.call(safeObj, key)) {
      return safeObj[key];
    }
    
    return undefined;
  },

  /**
   * 创建类型保护函数 Create type guard function
   */
  createTypeGuard<T extends SafeObject>(
    schema: Record<string, (value: SafeAny) => boolean>
  ): (obj: SafeAny) => boolean {
    return (obj: SafeAny): boolean => {
      if (!TypeUtils.isObject(obj)) {
        return false;
      }
      
      // 验证所有必需的属性都存在且符合类型 Validate all required properties exist and match type
      for (const [key, validator] of Object.entries(schema)) {
        // 使用类型安全的属性查询方式，避免索引签名访问 Use type-safe property query method, avoid index signature access
        const value = TypeUtils.getPropertyValue(obj, key);
        if (!validator(value)) {
          return false;
        }
      }
      
      return true;
    };
  }
};

export default TypeUtils;



