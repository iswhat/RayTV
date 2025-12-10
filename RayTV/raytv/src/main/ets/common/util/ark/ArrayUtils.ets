// ArrayUtils.ets - ArkTS兼容的数组工具函�?
/**
 * 数组工具函数
 * 提供ArkTS环境中安全的数组操作功能
 */
import { SafeAny, Optional } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';

/**
 * 数组工具函数集合
 */
export const ArrayUtils = {
  /**
   * 检查值是否为数组
   */
  isArray(value: SafeAny): boolean {
    return Array.isArray(value);
  },

  /**
   * 获取数组长度
   */
  length(array: Optional<ArrayLike<SafeAny>>): number {
    if (array === null || array === undefined) {
      return 0;
    }
    
    return array.length;
  },

  /**
   * 检查数组是否为�?   */
  isEmpty(array: Optional<ArrayLike<SafeAny>>): boolean {
    return ArrayUtils.length(array) === 0;
  },

  /**
   * 安全地访问数组元�?   */
  get<T>(array: Optional<T[]>, index: number, defaultValue: T): T {
    if (!Array.isArray(array) || index < 0 || index >= array.length) {
      return defaultValue;
    }
    
    return array[index];
  },

  /**
   * 安全地设置数组元�?   */
  set<T>(array: Optional<T[]>, index: number, value: T): boolean {
    if (!Array.isArray(array) || index < 0 || index >= array.length) {
      return false;
    }
    
    array[index] = value;
    return true;
  },

  /**
   * 安全地在数组末尾添加元素
   */
  push<T>(array: Optional<T[]>, ...elements: T[]): number {
    if (!Array.isArray(array)) {
      return 0;
    }
    
    return array.push(...elements);
  },

  /**
   * 安全地从数组末尾移除元素
   */
  pop<T>(array: Optional<T[]>): T | undefined {
    if (!Array.isArray(array) || array.length === 0) {
      return undefined;
    }
    
    return array.pop();
  },

  /**
   * 安全地在数组开头添加元�?   */
  unshift<T>(array: Optional<T[]>, ...elements: T[]): number {
    if (!Array.isArray(array)) {
      return 0;
    }
    
    return array.unshift(...elements);
  },

  /**
   * 安全地从数组开头移除元�?   */
  shift<T>(array: Optional<T[]>): T | undefined {
    if (!Array.isArray(array) || array.length === 0) {
      return undefined;
    }
    
    return array.shift();
  },

  /**
   * 数组过滤函数
   * 替代Array.prototype.filter
   */
  filter<T>(array: Optional<T[]>, predicate: (element: T, index: number) => boolean): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    const result: T[] = [];
    
    for (let i = 0; i < array.length; i++) {
      if (predicate(array[i], i)) {
        result.push(array[i]);
      }
    }
    
    return result;
  },

  /**
   * 数组映射函数
   * 替代Array.prototype.map
   */
  map<T, R>(array: Optional<T[]>, transform: (element: T, index: number) => R): R[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    const result: R[] = [];
    
    for (let i = 0; i < array.length; i++) {
      result.push(transform(array[i], i));
    }
    
    return result;
  },

  /**
   * 数组归约函数
   * 替代Array.prototype.reduce
   */
  reduce<T, R>(
    array: Optional<T[]>, 
    reducer: (accumulator: R, element: T, index: number) => R, 
    initialValue: R
  ): R {
    if (!Array.isArray(array)) {
      return initialValue;
    }
    
    let accumulator = initialValue;
    
    for (let i = 0; i < array.length; i++) {
      accumulator = reducer(accumulator, array[i], i);
    }
    
    return accumulator;
  },

  /**
   * 数组查找函数
   * 替代Array.prototype.find
   */
  find<T>(array: Optional<T[]>, predicate: (element: T, index: number) => boolean): T | undefined {
    if (!Array.isArray(array)) {
      return undefined;
    }
    
    for (let i = 0; i < array.length; i++) {
      if (predicate(array[i], i)) {
        return array[i];
      }
    }
    
    return undefined;
  },

  /**
   * 数组查找索引函数
   * 替代Array.prototype.findIndex
   */
  findIndex<T>(array: Optional<T[]>, predicate: (element: T, index: number) => boolean): number {
    if (!Array.isArray(array)) {
      return -1;
    }
    
    for (let i = 0; i < array.length; i++) {
      if (predicate(array[i], i)) {
        return i;
      }
    }
    
    return -1;
  },

  /**
   * 数组包含检查函�?   * 替代Array.prototype.includes
   */
  includes<T>(array: Optional<T[]>, searchElement: T): boolean {
    if (!Array.isArray(array)) {
      return false;
    }
    
    for (let i = 0; i < array.length; i++) {
      if (array[i] === searchElement) {
        return true;
      }
    }
    
    return false;
  },

  /**
   * 数组索引检查函�?   * 替代Array.prototype.indexOf
   */
  indexOf<T>(array: Optional<T[]>, searchElement: T): number {
    if (!Array.isArray(array)) {
      return -1;
    }
    
    for (let i = 0; i < array.length; i++) {
      if (array[i] === searchElement) {
        return i;
      }
    }
    
    return -1;
  },

  /**
   * 数组最后索引检查函�?   * 替代Array.prototype.lastIndexOf
   */
  lastIndexOf<T>(array: Optional<T[]>, searchElement: T): number {
    if (!Array.isArray(array)) {
      return -1;
    }
    
    for (let i = array.length - 1; i >= 0; i--) {
      if (array[i] === searchElement) {
        return i;
      }
    }
    
    return -1;
  },

  /**
   * 数组连接函数
   * 替代Array.prototype.concat
   */
  concat<T>(array: Optional<T[]>, ...values: (Optional<T | T[]>)[]): T[] {
    const result: T[] = Array.isArray(array) ? [...array] : [];
    
    for (let i = 0; i < values.length; i++) {
      const value = values[i];
      if (Array.isArray(value)) {
        // 安全地遍历数组并添加每个元素
        for (let j = 0; j < value.length; j++) {
          result.push(value[j]);
        }
      } else if (value !== null && value !== undefined) {
        result.push(value as T);
      }
    }
    
    return result;
  },

  /**
   * 数组切片函数
   * 替代Array.prototype.slice
   */
  slice<T>(array: Optional<T[]>, start?: number, end?: number): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    const startIndex = start !== undefined ? Math.max(0, Math.min(start, array.length)) : 0;
    const endIndex = end !== undefined ? Math.max(0, Math.min(end, array.length)) : array.length;
    
    const result: T[] = [];
    
    for (let i = startIndex; i < endIndex; i++) {
      result.push(array[i]);
    }
    
    return result;
  },

  /**
   * 数组排序函数
   * 替代Array.prototype.sort
   */
  sort<T>(array: Optional<T[]>, compareFn?: (a: T, b: T) => number): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    // 创建副本以避免修改原始数�?    const result = [...array];
    
    if (compareFn) {
      // 使用冒泡排序实现自定义排�?      for (let i = 0; i < result.length - 1; i++) {
        for (let j = 0; j < result.length - 1 - i; j++) {
          if (compareFn(result[j], result[j + 1]) > 0) {
            // 交换元素
            const temp = result[j];
            result[j] = result[j + 1];
            result[j + 1] = temp;
          }
        }
      }
    } else {
      // 默认排序（转换为字符串后按字母顺序排序）
      for (let i = 0; i < result.length - 1; i++) {
        for (let j = 0; j < result.length - 1 - i; j++) {
          if (String(result[j]) > String(result[j + 1])) {
            // 交换元素
            const temp = result[j];
            result[j] = result[j + 1];
            result[j + 1] = temp;
          }
        }
      }
    }
    
    return result;
  },

  /**
   * 数组去重函数
   */
  unique<T>(array: Optional<T[]>): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    const result: T[] = [];
    const seen = new Set<T>();
    
    for (let i = 0; i < array.length; i++) {
      const item = array[i];
      if (!seen.has(item)) {
        seen.add(item);
        result.push(item);
      }
    }
    
    return result;
  },

  /**
   * 数组扁平化函�?   */
  flatten<T>(array: Optional<(T | T[])[]>): T[] {
    if (!Array.isArray(array)) {
      return [];
    }
    
    const result: T[] = [];
    
    function flattenHelper(arr: (T | T[])[]): void {
      for (let i = 0; i < arr.length; i++) {
        const item = arr[i];
        if (Array.isArray(item)) {
          flattenHelper(item);
        } else {
          result.push(item);
        }
      }
    }
    
    flattenHelper(array);
    return result;
  }
};

export default ArrayUtils;
