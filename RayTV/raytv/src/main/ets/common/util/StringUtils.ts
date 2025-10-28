/**
 * StringUtils - 字符串工具类
 * 提供字符串处理相关的工具函数
 */
import Logger from './Logger';

export class StringUtils {
  private static readonly TAG: string = 'StringUtils';

  /**
   * 判断字符串是否为空
   * @param str 要检查的字符串
   * @returns 是否为空字符串
   */
  public static isEmpty(str: string | null | undefined): boolean {
    return str === null || str === undefined || str.trim().length === 0;
  }

  /**
   * 判断字符串是否非空
   * @param str 要检查的字符串
   * @returns 是否非空字符串
   */
  public static isNotEmpty(str: string | null | undefined): boolean {
    return !StringUtils.isEmpty(str);
  }

  /**
   * 截断字符串
   * @param str 原始字符串
   * @param maxLength 最大长度
   * @param suffix 后缀（默认'...'）
   * @returns 截断后的字符串
   */
  public static truncate(str: string, maxLength: number, suffix: string = '...'): string {
    if (StringUtils.isEmpty(str)) return str || '';
    if (str.length <= maxLength) return str;
    
    const suffixLength = suffix.length;
    const availableLength = maxLength - suffixLength;
    
    if (availableLength <= 0) {
      return suffix.substring(0, maxLength);
    }
    
    return str.substring(0, availableLength) + suffix;
  }

  /**
   * 格式化文件大小
   * @param bytes 字节数
   * @param decimals 小数位数
   * @returns 格式化后的文件大小字符串
   */
  public static formatFileSize(bytes: number, decimals: number = 2): string {
    if (bytes === 0) return '0 B';
    
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
  }

  /**
   * 格式化时间（秒）为可读格式
   * @param seconds 秒数
   * @returns 格式化后的时间字符串（HH:MM:SS 或 MM:SS）
   */
  public static formatDuration(seconds: number): string {
    if (isNaN(seconds) || seconds < 0) return '00:00';
    
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    const pad = (num: number): string => num.toString().padStart(2, '0');
    
    if (hours > 0) {
      return `${pad(hours)}:${pad(minutes)}:${pad(secs)}`;
    } else {
      return `${pad(minutes)}:${pad(secs)}`;
    }
  }

  /**
   * 从URL中提取文件名
   * @param url URL字符串
   * @returns 文件名
   */
  public static getFileNameFromUrl(url: string): string {
    if (StringUtils.isEmpty(url)) return '';
    
    try {
      const urlObj = new URL(url);
      const pathname = urlObj.pathname;
      const fileName = pathname.substring(pathname.lastIndexOf('/') + 1);
      return fileName || 'unknown';
    } catch (error) {
      Logger.error(StringUtils.TAG, 'Failed to get filename from URL', error);
      return 'unknown';
    }
  }

  /**
   * 转义HTML特殊字符
   * @param html HTML字符串
   * @returns 转义后的字符串
   */
  public static escapeHtml(html: string): string {
    if (StringUtils.isEmpty(html)) return html || '';
    
    const entityMap: { [key: string]: string } = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;'
    };
    
    return html.replace(/[&<>"']/g, (char) => entityMap[char]);
  }

  /**
   * 生成随机字符串
   * @param length 字符串长度
   * @returns 随机字符串
   */
  public static generateRandomString(length: number = 16): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    
    return result;
  }

  /**
   * 移除字符串中的所有空格
   * @param str 原始字符串
   * @returns 无空格字符串
   */
  public static removeAllSpaces(str: string): string {
    if (StringUtils.isEmpty(str)) return str || '';
    return str.replace(/\s+/g, '');
  }

  /**
   * 首字母大写
   * @param str 原始字符串
   * @returns 首字母大写的字符串
   */
  public static capitalize(str: string): string {
    if (StringUtils.isEmpty(str)) return str || '';
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
  }

  /**
   * 判断字符串是否包含指定文本（忽略大小写）
   * @param str 原始字符串
   * @param searchStr 要查找的文本
   * @returns 是否包含
   */
  public static containsIgnoreCase(str: string, searchStr: string): boolean {
    if (StringUtils.isEmpty(str) || StringUtils.isEmpty(searchStr)) return false;
    return str.toLowerCase().includes(searchStr.toLowerCase());
  }

  /**
   * 计算两个字符串的相似度（Levenshtein距离）
   * @param str1 第一个字符串
   * @param str2 第二个字符串
   * @returns 相似度分数（0-1之间，1为完全相同）
   */
  public static calculateSimilarity(str1: string, str2: string): number {
    if (StringUtils.isEmpty(str1) || StringUtils.isEmpty(str2)) return 0;
    if (str1 === str2) return 1;
    
    const len1 = str1.length;
    const len2 = str2.length;
    
    // 初始化距离矩阵
    const matrix: number[][] = [];
    for (let i = 0; i <= len1; i++) {
      matrix[i] = [];
      matrix[i][0] = i;
    }
    
    for (let j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }
    
    // 计算编辑距离
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,     // 删除
          matrix[i][j - 1] + 1,     // 插入
          matrix[i - 1][j - 1] + cost // 替换
        );
      }
    }
    
    const distance = matrix[len1][len2];
    const maxLength = Math.max(len1, len2);
    return 1 - (distance / maxLength);
  }
}

export default StringUtils;