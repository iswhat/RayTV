/**
 * StringUtils - 字符串工具类 String utility class
 * 提供字符串处理相关的工具函数 Provides string processing utility functions
 */
import Logger from './Logger';

export class StringUtils {
  private static readonly TAG: string = 'StringUtils';

  /**
   * 判断字符串是否为空 Checks if string is empty
   * @param str 要检查的字符串 String to check
   * @returns 是否为空 Is empty
   */
  public static isEmpty(str: string | null | undefined): boolean {
    return str === null || str === undefined || str.trim().length === 0;
  }

  /**
   * 判断字符串是否非空 Checks if string is not empty
   * @param str 要检查的字符串 String to check
   * @returns 是否非空 Is not empty
   */
  public static isNotEmpty(str: string | null | undefined): boolean {
    return !StringUtils.isEmpty(str);
  }

  /**
   * 字符串转字节数组 Converts string to byte array
   * @param str 要转换的字符串 String to convert
   * @returns 字节数组 Byte array
   */
  public static stringToBytes(str: string): number[] {
    const bytes: number[] = [];
    for (let i = 0; i < str.length; i++) {
      bytes.push(str.charCodeAt(i));
    }
    return bytes;
  }

  /**
   * 字节数组转字符串 Converts byte array to string
   * @param bytes 字节数组 Byte array
   * @returns 转换后的字符串 Converted string
   */
  public static bytesToString(bytes: number[]): string {
    return String.fromCharCode(...bytes);
  }

  /**
   * 格式化时间（秒）为可读格式 Formats time (seconds) to readable format
   * @param seconds 秒数 Seconds
   * @returns 格式化后的时间字符串 Formatted time string (HH:MM:SS or MM:SS)
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
   * 从URL获取文件名 Extracts filename from URL
   * @param url URL字符串 URL string
   * @returns 文件名 Filename
   */
  public static getFilenameFromUrl(url: string): string {
    try {
      const urlObj = new URL(url);
      const pathname = urlObj.pathname;
      const fileName = pathname.substring(pathname.lastIndexOf('/') + 1);
      return fileName || 'unknown';
    } catch (error) {
      Logger.error(StringUtils.TAG, 'Failed to get filename from URL', error instanceof Error ? error : new Error(String(error)));
      return 'unknown';
    }
  }

  /**
   * 转义HTML特殊字符 Escapes HTML special characters
   * @param html HTML字符串 HTML string
   * @returns 转义后的字符串 Escaped string
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
   * 生成随机字符串 Generates random string
   * @param length 字符串长度 String length
   * @returns 随机字符串 Random string
   */
  public static generateRandomString(length: number = 8): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * 移除字符串中的所有空格 Removes all spaces from string
   * @param str 原始字符串 Original string
   * @returns 移除空格后的字符串 String with spaces removed
   */
  public static removeAllSpaces(str: string): string {
    return str.replace(/\s+/g, '');
  }

  /**
   * 首字母大写 Capitalizes first letter
   * @param str 原始字符串 Original string
   * @returns 首字母大写的字符串 String with first letter capitalized
   */
  public static capitalizeFirstLetter(str: string): string {
    if (StringUtils.isEmpty(str)) {
      return str;
    }
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  /**
   * 计算两个字符串的相似度（Levenshtein距离） Calculates similarity between two strings (Levenshtein distance)
   * @param str1 第一个字符串 First string
   * @param str2 第二个字符串 Second string
   * @returns 相似度分数 Similarity score (0-1, 1 means identical)
   */
  public static getSimilarity(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;

    // 初始化距离矩阵 Initialize distance matrix
    const matrix: number[][] = Array(len1 + 1).fill(null).map(() => Array(len2 + 1).fill(0));

    // 初始化第一行和第一列 Initialize first row and column
    for (let i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (let j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // 填充矩阵 Fill matrix
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,     // 删除 Delete
          matrix[i][j - 1] + 1,     // 插入 Insert
          matrix[i - 1][j - 1] + cost  // 替换 Replace
        );
      }
    }

    // 计算相似度 Calculate similarity
    const maxLen = Math.max(len1, len2);
    return maxLen === 0 ? 1 : 1 - matrix[len1][len2] / maxLen;
  }

  /**
   * 截断字符串 Truncates string
   * @param str 原始字符串 Original string
   * @param maxLength 最大长度 Maximum length
   * @param suffix 后缀（默认省略号）Suffix (default: ellipsis)
   * @returns 截断后的字符串 Truncated string
   */
  public static truncate(str: string, maxLength: number, suffix: string = '...'): string {
    if (StringUtils.isEmpty(str) || str.length <= maxLength) {
      return str;
    }
    return str.substring(0, maxLength - suffix.length) + suffix;
  }

  /**
   * 驼峰式转下划线 Converts camelCase to snake_case
   * @param str 驼峰式字符串 Camel case string
   * @returns 下划线字符串 Snake case string
   */
  public static camelToSnake(str: string): string {
    return str.replace(/[A-Z]/g, (match) => `_${match.toLowerCase()}`);
  }

  /**
   * 下划线转驼峰式 Converts snake_case to camelCase
   * @param str 下划线字符串 Snake case string
   * @returns 驼峰式字符串 Camel case string
   */
  public static snakeToCamel(str: string): string {
    return str.replace(/_([a-z])/g, (match, letter) => letter.toUpperCase());
  }

  /**
   * 验证字符串是否为有效的URL Validates if string is a valid URL
   * @param url 要验证的URL URL to validate
   * @returns 是否为有效URL Is valid URL
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
