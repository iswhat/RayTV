// StringUtils.ets - ArkTS兼容的字符串工具函数

/**
 * 字符串工具函�? * 提供ArkTS环境中安全的字符串操作功�? */
import { Optional } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';
import ArrayUtils from './ArrayUtils';

/**
 * 字符串工具函数集�? */
export const StringUtils = {
  /**
   * 检查值是否为字符�?   */
  isString(value: Record<string, string | number | boolean | null>): boolean {
    return TypeUtils.isString(value);
  },

  /**
   * 获取字符串长�?   */
  length(str: Optional<string>): number {
    if (str === null || str === undefined) {
      return 0;
    }
    
    return str.length;
  },

  /**
   * 检查字符串是否为空
   */
  isEmpty(str: Optional<string>): boolean {
    return str === null || str === undefined || str.trim().length === 0;
  },

  /**
   * 检查字符串是否非空
   */
  isNotEmpty(str: Optional<string>): boolean {
    return !StringUtils.isEmpty(str);
  },

  /**
   * 字符串截取函�?   * 替代String.prototype.substring
   */
  substring(str: Optional<string>, start: number, end?: number): string {
    if (str === null || str === undefined) {
      return '';
    }
    
    const startIndex = Math.max(0, Math.min(start, str.length));
    const endIndex = end !== undefined ? Math.max(0, Math.min(end, str.length)) : str.length;
    
    return str.substring(startIndex, endIndex);
  },

  /**
   * 字符串截断函�?   */
  truncate(str: Optional<string>, maxLength: number, suffix: string = '...'): string {
    if (StringUtils.isEmpty(str)) {
      return str || '';
    }
    
    if (str.length <= maxLength) {
      return str;
    }
    
    const suffixLength = suffix.length;
    const availableLength = maxLength - suffixLength;
    
    if (availableLength <= 0) {
      return StringUtils.substring(suffix, 0, maxLength);
    }
    
    return StringUtils.substring(str, 0, availableLength) + suffix;
  },

  /**
   * 字符串转小写函数
   * 替代String.prototype.toLowerCase
   */
  toLowerCase(str: Optional<string>): string {
    if (str === null || str === undefined) {
      return '';
    }
    
    return str.toLowerCase();
  },

  /**
   * 字符串转大写函数
   * 替代String.prototype.toUpperCase
   */
  toUpperCase(str: Optional<string>): string {
    if (str === null || str === undefined) {
      return '';
    }
    
    return str.toUpperCase();
  },

  /**
   * 字符串去除首尾空格函�?   * 替代String.prototype.trim
   */
  trim(str: Optional<string>): string {
    if (str === null || str === undefined) {
      return '';
    }
    
    return str.trim();
  },

  /**
   * 字符串分割函�?   * 替代String.prototype.split
   */
  split(str: Optional<string>, separator: string | RegExp, limit?: number): string[] {
    if (str === null || str === undefined) {
      return [];
    }
    
    const parts = str.split(separator);
    
    if (limit !== undefined && limit > 0) {
      return ArrayUtils.slice(parts, 0, limit);
    }
    
    return parts;
  },

  /**
   * 字符串连接函�?   * 替代String.prototype.join
   */
  join(separator: string, ...parts: Optional<string>[]): string {
    const nonEmptyParts: string[] = [];
    
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i];
      if (part !== null && part !== undefined) {
        nonEmptyParts.push(part);
      }
    }
    
    return nonEmptyParts.join(separator);
  },

  /**
   * 字符串包含检查函�?   * 替代String.prototype.includes
   */
  includes(str: Optional<string>, searchString: string, position?: number): boolean {
    if (str === null || str === undefined) {
      return false;
    }
    
    return str.includes(searchString, position);
  },

  /**
   * 字符串包含检查函数（忽略大小写）
   */
  containsIgnoreCase(str: Optional<string>, searchStr: string): boolean {
    if (StringUtils.isEmpty(str) || StringUtils.isEmpty(searchStr)) {
      return false;
    }
    
    const lowerStr = StringUtils.toLowerCase(str);
    const lowerSearchStr = StringUtils.toLowerCase(searchStr);
    
    return StringUtils.includes(lowerStr, lowerSearchStr);
  },

  /**
   * 字符串开头检查函�?   * 替代String.prototype.startsWith
   */
  startsWith(str: Optional<string>, searchString: string, position?: number): boolean {
    if (str === null || str === undefined) {
      return false;
    }
    
    return str.startsWith(searchString, position);
  },

  /**
   * 字符串结尾检查函�?   * 替代String.prototype.endsWith
   */
  endsWith(str: Optional<string>, searchString: string, length?: number): boolean {
    if (str === null || str === undefined) {
      return false;
    }
    
    return str.endsWith(searchString, length);
  },

  /**
   * 字符串查找函�?   * 替代String.prototype.indexOf
   */
  indexOf(str: Optional<string>, searchValue: string, fromIndex?: number): number {
    if (str === null || str === undefined) {
      return -1;
    }
    
    return str.indexOf(searchValue, fromIndex);
  },

  /**
   * 字符串最后查找函�?   * 替代String.prototype.lastIndexOf
   */
  lastIndexOf(str: Optional<string>, searchValue: string, fromIndex?: number): number {
    if (str === null || str === undefined) {
      return -1;
    }
    
    return str.lastIndexOf(searchValue, fromIndex);
  },

  /**
   * 字符串替换函�?   * 替代String.prototype.replace
   */
  replace(str: Optional<string>, searchValue: string | RegExp, replaceValue: string): string {
    if (str === null || str === undefined) {
      return '';
    }
    
    return str.replace(searchValue, replaceValue);
  },

  /**
   * 字符串全部替换函�?   * 替代String.prototype.replaceAll
   */
  replaceAll(str: Optional<string>, searchValue: string, replaceValue: string): string {
    if (str === null || str === undefined) {
      return '';
    }
    
    // 使用正则表达式实现全部替�?    const regex = new RegExp(searchValue.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
    return str.replace(regex, replaceValue);
  },

  /**
   * 字符串填充函�?   * 替代String.prototype.padStart
   */
  padStart(str: Optional<string>, targetLength: number, padString: string = ' '): string {
    if (str === null || str === undefined) {
      return '';
    }
    
    return str.padStart(targetLength, padString);
  },

  /**
   * 字符串填充函�?   * 替代String.prototype.padEnd
   */
  padEnd(str: Optional<string>, targetLength: number, padString: string = ' '): string {
    if (str === null || str === undefined) {
      return '';
    }
    
    return str.padEnd(targetLength, padString);
  },

  /**
   * 字符串转数组函数
   * 替代String.prototype.split('')
   */
  toCharArray(str: Optional<string>): string[] {
    if (str === null || str === undefined) {
      return [];
    }
    
    const result: string[] = [];
    
    for (let i = 0; i < str.length; i++) {
      result.push(str.charAt(i));
    }
    
    return result;
  },

  /**
   * 首字母大写函�?   */
  capitalize(str: Optional<string>): string {
    if (StringUtils.isEmpty(str)) {
      return str || '';
    }
    
    return StringUtils.toUpperCase(StringUtils.substring(str, 0, 1)) + StringUtils.substring(str, 1);
  },

  /**
   * 驼峰命名转下划线命名函数
   */
  camelToSnake(str: Optional<string>): string {
    if (StringUtils.isEmpty(str)) {
      return str || '';
    }
    
    return StringUtils.toLowerCase(
      StringUtils.replace(str, /([a-z0-9])([A-Z])/g, '$1_$2')
    );
  },

  /**
   * 下划线命名转驼峰命名函数
   */
  snakeToCamel(str: Optional<string>): string {
    if (StringUtils.isEmpty(str)) {
      return str || '';
    }
    
    return StringUtils.replace(str, /_([a-z])/g, (_, group1) => StringUtils.toUpperCase(group1));
  },

  /**
   * 生成随机字符串函�?   */
  generateRandomString(length: number = 16): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    
    for (let i = 0; i < length; i++) {
      const randomIndex = Math.floor(Math.random() * chars.length);
      result += chars.charAt(randomIndex);
    }
    
    return result;
  },

  /**
   * 格式化文件大小函�?   */
  formatFileSize(bytes: number, decimals: number = 2): string {
    if (bytes === 0) {
      return '0 B';
    }
    
    const k = 1024;
    const sizes: string[] = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
  }
};

export default StringUtils;

