/**
 * 字符串工具类
 * 提供字符串处理、格式化、验证等功能
 */
import Logger from './Logger';

export class StringUtils {
  private static readonly TAG = 'StringUtils';
  
  /**
   * 判断字符串是否为空
   * @param str 要检查的字符串
   * @returns 是否为空字符串
   */
  public static isEmpty(str: string | null | undefined): boolean {
    return str === null || str === undefined || str.trim() === '';
  }
  
  /**
   * 判断字符串是否不为空
   * @param str 要检查的字符串
   * @returns 是否不为空字符串
   */
  public static isNotEmpty(str: string | null | undefined): boolean {
    return !this.isEmpty(str);
  }
  
  /**
   * 去除字符串两端的空白字符
   * @param str 要处理的字符串
   * @returns 处理后的字符串
   */
  public static trim(str: string | null | undefined): string {
    return str ? str.trim() : '';
  }
  
  /**
   * 去除字符串左端的空白字符
   * @param str 要处理的字符串
   * @returns 处理后的字符串
   */
  public static trimLeft(str: string | null | undefined): string {
    return str ? str.trimStart() : '';
  }
  
  /**
   * 去除字符串右端的空白字符
   * @param str 要处理的字符串
   * @returns 处理后的字符串
   */
  public static trimRight(str: string | null | undefined): string {
    return str ? str.trimEnd() : '';
  }
  
  /**
   * 字符串转大写
   * @param str 要处理的字符串
   * @returns 大写字符串
   */
  public static toUpperCase(str: string | null | undefined): string {
    return str ? str.toUpperCase() : '';
  }
  
  /**
   * 字符串转小写
   * @param str 要处理的字符串
   * @returns 小写字符串
   */
  public static toLowerCase(str: string | null | undefined): string {
    return str ? str.toLowerCase() : '';
  }
  
  /**
   * 首字母大写
   * @param str 要处理的字符串
   * @returns 首字母大写的字符串
   */
  public static capitalize(str: string | null | undefined): string {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
  }
  
  /**
   * 截断字符串
   * @param str 要截断的字符串
   * @param maxLength 最大长度
   * @param suffix 后缀，默认为'...'
   * @returns 截断后的字符串
   */
  public static truncate(str: string | null | undefined, maxLength: number, suffix: string = '...'): string {
    if (!str) return '';
    if (str.length <= maxLength) return str;
    return str.substring(0, maxLength - suffix.length) + suffix;
  }
  
  /**
   * 格式化数字为千分位
   * @param num 要格式化的数字
   * @returns 千分位格式的字符串
   */
  public static formatNumber(num: number | string | null | undefined): string {
    if (num === null || num === undefined) return '0';
    const number = typeof num === 'string' ? parseFloat(num) : num;
    if (isNaN(number)) return '0';
    return number.toLocaleString();
  }
  
  /**
   * 格式化文件大小
   * @param bytes 字节数
   * @param decimals 小数位数
   * @returns 格式化后的大小字符串
   */
  public static formatFileSize(bytes: number | null | undefined, decimals: number = 2): string {
    if (bytes === null || bytes === undefined || bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }
  
  /**
   * 格式化时间秒数为时分秒
   * @param seconds 秒数
   * @returns 格式化后的时间字符串
   */
  public static formatTime(seconds: number | null | undefined): string {
    if (seconds === null || seconds === undefined || seconds < 0) return '00:00';
    
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    } else {
      return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
  }
  
  /**
   * 验证是否为有效的URL
   * @param str 要验证的字符串
   * @returns 是否为有效URL
   */
  public static isValidUrl(str: string | null | undefined): boolean {
    if (!str) return false;
    
    try {
      new URL(str);
      return true;
    } catch {
      return false;
    }
  }
  
  /**
   * 验证是否为有效的邮箱
   * @param str 要验证的字符串
   * @returns 是否为有效邮箱
   */
  public static isValidEmail(str: string | null | undefined): boolean {
    if (!str) return false;
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(str);
  }
  
  /**
   * 生成随机字符串
   * @param length 字符串长度
   * @param charset 字符集，默认为字母数字
   * @returns 随机字符串
   */
  public static generateRandomString(length: number, charset: string = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'): string {
    let result = '';
    const charsetLength = charset.length;
    
    for (let i = 0; i < length; i++) {
      result += charset.charAt(Math.floor(Math.random() * charsetLength));
    }
    
    return result;
  }
  
  /**
   * 安全地进行字符串替换
   * @param str 原始字符串
   * @param search 要查找的字符串或正则表达式
   * @param replace 替换的字符串
   * @returns 替换后的字符串
   */
  public static safeReplace(str: string | null | undefined, search: string | RegExp, replace: string): string {
    if (!str) return '';
    
    try {
      return str.replace(search, replace);
    } catch (error) {
      Logger.error(this.TAG, `Safe replace error: ${error}`);
      return str;
    }
  }
  
  /**
   * 多次替换字符串中的多个模式
   * @param str 原始字符串
   * @param replacements 替换规则对象
   * @returns 替换后的字符串
   */
  public static multiReplace(str: string | null | undefined, replacements: Record<string, string>): string {
    if (!str) return '';
    
    let result = str;
    
    Object.entries(replacements).forEach(([search, replace]) => {
      // 转义正则特殊字符
      const escapedSearch = search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(escapedSearch, 'g');
      result = result.replace(regex, replace);
    });
    
    return result;
  }
  
  /**
   * 计算字符串相似度（简单的编辑距离）
   * @param str1 第一个字符串
   * @param str2 第二个字符串
   * @returns 相似度百分比（0-100）
   */
  public static getSimilarity(str1: string | null | undefined, str2: string | null | undefined): number {
    if (!str1 && !str2) return 100;
    if (!str1 || !str2) return 0;
    
    const len1 = str1.length;
    const len2 = str2.length;
    
    // 创建编辑距离矩阵
    const dp: number[][] = Array(len1 + 1).fill(null).map(() => Array(len2 + 1).fill(0));
    
    // 初始化边界
    for (let i = 0; i <= len1; i++) {
      dp[i][0] = i;
    }
    for (let j = 0; j <= len2; j++) {
      dp[0][j] = j;
    }
    
    // 计算编辑距离
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        if (str1[i - 1] === str2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = Math.min(
            dp[i - 1][j] + 1,    // 删除
            dp[i][j - 1] + 1,    // 插入
            dp[i - 1][j - 1] + 1 // 替换
          );
        }
      }
    }
    
    const maxLen = Math.max(len1, len2);
    const similarity = ((maxLen - dp[len1][len2]) / maxLen) * 100;
    
    return Math.round(similarity);
  }
  
  /**
   * 移除字符串中的HTML标签
   * @param str 包含HTML标签的字符串
   * @returns 移除标签后的纯文本
   */
  public static stripHtmlTags(str: string | null | undefined): string {
    if (!str) return '';
    
    // 简单的HTML标签移除
    return str.replace(/<[^>]*>/g, '');
  }
  
  /**
   * 格式化字符串，替换占位符
   * @param str 包含占位符的字符串，如'Hello {name}'
   * @param params 替换参数对象，如{name: 'World'}
   * @returns 格式化后的字符串
   */
  public static format(str: string | null | undefined, params: Record<string, any>): string {
    if (!str) return '';
    
    let result = str;
    
    Object.entries(params).forEach(([key, value]) => {
      const regex = new RegExp(`\\{${key}\\}`, 'g');
      result = result.replace(regex, String(value));
    });
    
    return result;
  }
  
  /**
   * 验证是否为中文字符
   * @param str 要验证的字符串
   * @returns 是否包含中文
   */
  public static hasChineseChars(str: string | null | undefined): boolean {
    if (!str) return false;
    
    const chineseRegex = /[\u4e00-\u9fa5]/;
    return chineseRegex.test(str);
  }
  
  /**
   * 提取字符串中的所有数字
   * @param str 要处理的字符串
   * @returns 提取的数字
   */
  public static extractNumbers(str: string | null | undefined): number[] {
    if (!str) return [];
    
    const numberRegex = /\d+/g;
    const matches = str.match(numberRegex);
    
    return matches ? matches.map(match => parseInt(match, 10)) : [];
  }
  
  /**
   * 生成唯一ID
   * @returns 唯一ID字符串
   */
  public static generateUniqueId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }
}

export default StringUtils;