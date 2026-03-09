/**
 * UnifiedStringUtils - 统一的字符串工具类
 * 整合所有字符串处理相关的工具函数，避免代码重复
 */
import Logger from './Logger';
import TypeUtils from './ark/TypeUtils';
import ArrayUtils from './ark/ArrayUtils';

/**
 * 可选字符串类型
 */
export type OptionalString = string | null | undefined;

/**
 * 统一的字符串工具类
 */
export class UnifiedStringUtils {
  private static readonly TAG: string = 'UnifiedStringUtils';

  /**
   * 检查值是否为字符串
   */
  public static isString(value: unknown): boolean {
    return TypeUtils.isString(value);
  }

  /**
   * 获取字符串长度
   */
  public static length(str: OptionalString): number {
    if (str === null || str === undefined) {
      return 0;
    }
    return str.length;
  }

  /**
   * 检查字符串是否为空
   */
  public static isEmpty(str: OptionalString): boolean {
    return str === null || str === undefined || str.trim().length === 0;
  }

  /**
   * 检查字符串是否非空
   */
  public static isNotEmpty(str: OptionalString): boolean {
    return !UnifiedStringUtils.isEmpty(str);
  }

  /**
   * 字符串截取函数
   */
  public static substring(str: OptionalString, start: number, end?: number): string {
    if (str === null || str === undefined) {
      return '';
    }
    const startIndex = Math.max(0, Math.min(start, str.length));
    const endIndex = end !== undefined ? Math.max(0, Math.min(end, str.length)) : str.length;
    return str.substring(startIndex, endIndex);
  }

  /**
   * 字符串截断函数
   */
  public static truncate(str: OptionalString, maxLength: number, suffix: string = '...'): string {
    if (UnifiedStringUtils.isEmpty(str)) {
      return str || '';
    }
    if (str.length <= maxLength) {
      return str;
    }
    const suffixLength = suffix.length;
    const availableLength = maxLength - suffixLength;
    if (availableLength <= 0) {
      return UnifiedStringUtils.substring(suffix, 0, maxLength);
    }
    return UnifiedStringUtils.substring(str, 0, availableLength) + suffix;
  }

  /**
   * 字符串转小写函数
   */
  public static toLowerCase(str: OptionalString): string {
    if (str === null || str === undefined) {
      return '';
    }
    return str.toLowerCase();
  }

  /**
   * 字符串转大写函数
   */
  public static toUpperCase(str: OptionalString): string {
    if (str === null || str === undefined) {
      return '';
    }
    return str.toUpperCase();
  }

  /**
   * 字符串去除首尾空格函数
   */
  public static trim(str: OptionalString): string {
    if (str === null || str === undefined) {
      return '';
    }
    return str.trim();
  }

  /**
   * 字符串分割函数
   */
  public static split(str: OptionalString, separator: string | RegExp, limit?: number): string[] {
    if (str === null || str === undefined) {
      return [];
    }
    const parts = str.split(separator);
    if (limit !== undefined && limit > 0) {
      return ArrayUtils.slice(parts, 0, limit);
    }
    return parts;
  }

  /**
   * 字符串连接函数
   */
  public static join(separator: string, ...parts: OptionalString[]): string {
    const nonEmptyParts: string[] = [];
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i];
      if (part !== null && part !== undefined) {
        nonEmptyParts.push(part);
      }
    }
    return nonEmptyParts.join(separator);
  }

  /**
   * 字符串包含检查函数
   */
  public static includes(str: OptionalString, searchString: string, position?: number): boolean {
    if (str === null || str === undefined) {
      return false;
    }
    return str.includes(searchString, position);
  }

  /**
   * 字符串包含检查函数（忽略大小写）
   */
  public static containsIgnoreCase(str: OptionalString, searchStr: string): boolean {
    if (UnifiedStringUtils.isEmpty(str) || UnifiedStringUtils.isEmpty(searchStr)) {
      return false;
    }
    const lowerStr = UnifiedStringUtils.toLowerCase(str);
    const lowerSearchStr = UnifiedStringUtils.toLowerCase(searchStr);
    return UnifiedStringUtils.includes(lowerStr, lowerSearchStr);
  }

  /**
   * 字符串开始检查函数
   */
  public static startsWith(str: OptionalString, searchString: string, position?: number): boolean {
    if (str === null || str === undefined) {
      return false;
    }
    return str.startsWith(searchString, position);
  }

  /**
   * 字符串结束检查函数
   */
  public static endsWith(str: OptionalString, searchString: string, length?: number): boolean {
    if (str === null || str === undefined) {
      return false;
    }
    return str.endsWith(searchString, length);
  }

  /**
   * 字符串查找函数
   */
  public static indexOf(str: OptionalString, searchValue: string, fromIndex?: number): number {
    if (str === null || str === undefined) {
      return -1;
    }
    return str.indexOf(searchValue, fromIndex);
  }

  /**
   * 字符串最后查找函数
   */
  public static lastIndexOf(str: OptionalString, searchValue: string, fromIndex?: number): number {
    if (str === null || str === undefined) {
      return -1;
    }
    return str.lastIndexOf(searchValue, fromIndex);
  }

  /**
   * 字符串替换函数
   */
  public static replace(str: OptionalString, searchValue: string | RegExp, replaceValue: string): string {
    if (str === null || str === undefined) {
      return '';
    }
    return str.replace(searchValue, replaceValue);
  }

  /**
   * 字符串全部替换函数
   */
  public static replaceAll(str: OptionalString, searchValue: string, replaceValue: string): string {
    if (str === null || str === undefined) {
      return '';
    }
    // 使用正则表达式实现全部替换
    const regex = new RegExp(searchValue.replace(/[.*+?^${}()|[\]/g, '\\$&'), 'g');
    return str.replace(regex, replaceValue);
  }

  /**
   * 字符串前填充函数
   */
  public static padStart(str: OptionalString, targetLength: number, padString: string = ' '): string {
    if (str === null || str === undefined) {
      return '';
    }
    return str.padStart(targetLength, padString);
  }

  /**
   * 字符串后填充函数
   */
  public static padEnd(str: OptionalString, targetLength: number, padString: string = ' '): string {
    if (str === null || str === undefined) {
      return '';
    }
    return str.padEnd(targetLength, padString);
  }

  /**
   * 字符串转数组函数
   */
  public static toCharArray(str: OptionalString): string[] {
    if (str === null || str === undefined) {
      return [];
    }
    const result: string[] = [];
    for (let i = 0; i < str.length; i++) {
      result.push(str.charAt(i));
    }
    return result;
  }

  /**
   * 首字母大写函数
   */
  public static capitalize(str: OptionalString): string {
    if (UnifiedStringUtils.isEmpty(str)) {
      return str || '';
    }
    return UnifiedStringUtils.toUpperCase(UnifiedStringUtils.substring(str, 0, 1)) + UnifiedStringUtils.substring(str, 1);
  }

  /**
   * 驼峰命名转下划线命名函数
   */
  public static camelToSnake(str: OptionalString): string {
    if (UnifiedStringUtils.isEmpty(str)) {
      return str || '';
    }
    return UnifiedStringUtils.toLowerCase(
      UnifiedStringUtils.replace(str, /([a-z0-9])([A-Z])/g, '$1_$2')
    );
  }

  /**
   * 下划线命名转驼峰命名函数
   */
  public static snakeToCamel(str: OptionalString): string {
    if (UnifiedStringUtils.isEmpty(str)) {
      return str || '';
    }
    return UnifiedStringUtils.replace(str, /_([a-z])/g, (_, group1) => UnifiedStringUtils.toUpperCase(group1));
  }

  /**
   * 生成随机字符串函数
   */
  public static generateRandomString(length: number = 16): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      const randomIndex = Math.floor(Math.random() * chars.length);
      result += chars.charAt(randomIndex);
    }
    return result;
  }

  /**
   * 格式化文件大小函数
   */
  public static formatFileSize(bytes: number, decimals: number = 2): string {
    if (bytes === 0) {
      return '0 B';
    }
    const k = 1024;
    const sizes: string[] = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
  }

  /**
   * 字符串转字节数组
   */
  public static stringToBytes(str: string): number[] {
    const bytes: number[] = [];
    for (let i = 0; i < str.length; i++) {
      bytes.push(str.charCodeAt(i));
    }
    return bytes;
  }

  /**
   * 字节数组转字符串
   */
  public static bytesToString(bytes: number[]): string {
    return String.fromCharCode(...bytes);
  }

  /**
   * 格式化时间（秒）为可读格式
   */
  public static formatTime(seconds: number): string {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);

    if (h > 0) {
      return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    } else {
      return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    }
  }

  /**
   * 从URL获取文件名
   */
  public static getFilenameFromUrl(url: string): string {
    try {
      const urlObj = new URL(url);
      const pathname = urlObj.pathname;
      const fileName = pathname.substring(pathname.lastIndexOf('/') + 1);
      return fileName || 'unknown';
    } catch (error) {
      Logger.error(UnifiedStringUtils.TAG, 'Failed to get filename from URL', error instanceof Error ? error : new Error(String(error)));
      return 'unknown';
    }
  }

  /**
   * 转义HTML特殊字符
   */
  public static escapeHtml(html: string): string {
    return html
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  /**
   * 移除字符串中的所有空格
   */
  public static removeAllSpaces(str: string): string {
    return str.replace(/\s+/g, '');
  }

  /**
   * 计算两个字符串的相似度（Levenshtein距离）
   */
  public static getSimilarity(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;

    // 初始化距离矩阵
    const matrix: number[][] = Array(len1 + 1).fill(null).map(() => Array(len2 + 1).fill(0));

    // 初始化第一行和第一列
    for (let i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (let j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // 填充矩阵
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,     // 删除
          matrix[i][j - 1] + 1,     // 插入
          matrix[i - 1][j - 1] + cost  // 替换
        );
      }
    }

    // 计算相似度
    const maxLen = Math.max(len1, len2);
    return maxLen === 0 ? 1 : 1 - matrix[len1][len2] / maxLen;
  }

  /**
   * 验证字符串是否为有效的URL
   */
  public static isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }
}

export default UnifiedStringUtils;