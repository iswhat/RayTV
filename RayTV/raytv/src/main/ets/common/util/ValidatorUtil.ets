/**
 * ValidatorUtil - 验证工具类 Validation utility class
 * 提供数据验证相关的工具函数，包括邮箱、手机号、URL等验证 Provides data validation utility functions, including email, phone number, URL validation
 */

import Logger from './Logger';
import ObjectUtils from './ark/ObjectUtils';

/**
 * 验证工具类 Validation utility class
 */
export class ValidatorUtil {
  private static readonly TAG: string = 'ValidatorUtil';

  /**
   * 验证邮箱是否有效 Validates if email is valid
   * @param email 邮箱地址 Email address
   * @returns 是否有效 Is valid
   */
  public static isValidEmail(email: string): boolean {
    if (!email) {
      return false;
    }
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
  }

  /**
   * 验证手机号是否有效 Validates if phone number is valid
   * @param phone 手机号 Phone number
   * @returns 是否有效 Is valid
   */
  public static isValidPhone(phone: string): boolean {
    if (!phone) {
      return false;
    }
    const phoneRegex = /^1[3-9]\d{9}$/;
    return phoneRegex.test(phone);
  }

  /**
   * 验证URL是否有效 Validates if URL is valid
   * @param url URL地址 URL address
   * @returns 是否有效 Is valid
   */
  public static isValidUrl(url: string): boolean {
    if (!url) {
      return false;
    }
    const urlRegex = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$/;
    return urlRegex.test(url);
  }

  /**
   * 验证IP地址是否有效 Validates if IP address is valid
   * @param ip IP地址 IP address
   * @returns 是否有效 Is valid
   */
  public static isValidIp(ip: string): boolean {
    if (!ip) {
      return false;
    }
    const ipv4Regex = /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    return ipv4Regex.test(ip);
  }

  /**
   * 验证数字是否有效 Validates if number is valid
   * @param value 值 Value
   * @param options 验证选项 Validation options
   * @returns 是否有效 Is valid
   */
  public static isValidNumber(value: string, options: { min?: number; max?: number; integer?: boolean } = {}): boolean {
    const num = Number(value);
    if (isNaN(num)) {
      return false;
    }

    if (options.integer && !Number.isInteger(num)) {
      return false;
    }

    if (options.min !== undefined && num < options.min) {
      return false;
    }

    if (options.max !== undefined && num > options.max) {
      return false;
    }

    return true;
  }

  /**
   * 验证字符串长度是否有效 Validates if string length is valid
   * @param value 字符串 String
   * @param options 验证选项 Validation options
   * @returns 是否有效 Is valid
   */
  public static isValidLength(value: string, options: { min?: number; max?: number } = {}): boolean {
    if (value === null || value === undefined) {
      return false;
    }

    const length = value.length;

    if (options.min !== undefined && length < options.min) {
      return false;
    }

    if (options.max !== undefined && length > options.max) {
      return false;
    }

    return true;
  }

  /**
   * 验证密码是否符合要求 Validates if password meets requirements
   * @param password 密码 Password
   * @param options 验证选项 Validation options
   * @returns 是否有效 Is valid
   */
  public static isValidPassword(password: string, options: {
    minLength?: number;
    requireUppercase?: boolean;
    requireLowercase?: boolean;
    requireNumber?: boolean;
    requireSpecial?: boolean;
  } = {}): boolean {
    if (!password) {
      return false;
    }

    const minLength = options.minLength ?? 8;
    const requireUppercase = options.requireUppercase ?? true;
    const requireLowercase = options.requireLowercase ?? true;
    const requireNumber = options.requireNumber ?? true;
    const requireSpecial = options.requireSpecial ?? true;

    if (password.length < minLength) {
      return false;
    }

    if (requireUppercase && !/[A-Z]/.test(password)) {
      return false;
    }

    if (requireLowercase && !/[a-z]/.test(password)) {
      return false;
    }

    if (requireNumber && !/\d/.test(password)) {
      return false;
    }

    if (requireSpecial && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      return false;
    }

    return true;
  }

  /**
   * 验证用户名是否有效 Validates if username is valid
   * @param username 用户名 Username
   * @param options 验证选项 Validation options
   * @returns 是否有效 Is valid
   */
  public static isValidUsername(username: string, options: {
    minLength?: number;
    maxLength?: number;
    allowUnderscore?: boolean;
    allowHyphen?: boolean;
  } = {}): boolean {
    if (!username) {
      return false;
    }

    const minLength = options.minLength ?? 3;
    const maxLength = options.maxLength ?? 20;
    const allowUnderscore = options.allowUnderscore ?? true;
    const allowHyphen = options.allowHyphen ?? true;

    if (username.length < minLength || username.length > maxLength) {
      return false;
    }

    // 构建正则表达式 Build regular expression
    let regexPattern = '^[a-zA-Z0-9';
    if (allowUnderscore) regexPattern += '_';
    if (allowHyphen) regexPattern += '-';
    regexPattern += ']+$';

    const usernameRegex = new RegExp(regexPattern);
    return usernameRegex.test(username);
  }

  /**
   * 验证日期是否有效 Validates if date is valid
   * @param date 日期 Date
   * @returns 是否有效 Is valid
   */
  public static isValidDate(date: Date | string): boolean {
    const d = typeof date === 'string' ? new Date(date) : date;
    return d instanceof Date && !isNaN(d.getTime());
  }

  /**
   * 验证图片URL是否有效 Validates if image URL is valid
   * @param url 图片URL Image URL
   * @returns 是否有效 Is valid
   */
  public static isValidImageUrl(url: string): boolean {
    if (!this.isValidUrl(url)) {
      return false;
    }

    // 支持的图片格式 Supported image formats
    const imageExtensions = /\.(jpg|jpeg|png|gif|bmp|webp|svg)$/i;
    return imageExtensions.test(url);
  }

  /**
   * 验证视频URL是否有效 Validates if video URL is valid
   * @param url 视频URL Video URL
   * @returns 是否有效 Is valid
   */
  public static isValidVideoUrl(url: string): boolean {
    if (!this.isValidUrl(url)) {
      return false;
    }

    // 支持的视频格式 Supported video formats
    const videoExtensions = /\.(mp4|avi|mov|wmv|flv|mkv|webm)$/i;
    return videoExtensions.test(url);
  }

  /**
   * 验证音频URL是否有效 Validates if audio URL is valid
   * @param url 音频URL Audio URL
   * @returns 是否有效 Is valid
   */
  public static isValidAudioUrl(url: string): boolean {
    if (!this.isValidUrl(url)) {
      return false;
    }

    // 支持的音频格式 Supported audio formats
    const audioExtensions = /\.(mp3|wav|ogg|flac|aac|m4a)$/i;
    return audioExtensions.test(url);
  }

  /**
   * 获取文件扩展名 Gets file extension
   * @param fileName 文件名 File name
   * @returns 文件扩展名 File extension
   */
  public static getFileExtension(fileName: string): string {
    if (!fileName) {
      return '';
    }

    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return '';
    }

    return fileName.substring(lastDotIndex + 1).toLowerCase();
  }

  /**
   * 验证文件大小是否符合要求 Validates if file size meets requirements
   * @param size 文件大小（字节） File size in bytes
   * @param options 验证选项 Validation options
   * @returns 是否有效 Is valid
   */
  public static isValidFileSize(size: number, options: { maxSize?: number } = {}): boolean {
    if (size < 0) {
      return false;
    }

    if (options.maxSize !== undefined && size > options.maxSize) {
      return false;
    }

    return true;
  }

  /**
   * 验证数组是否有效 Validates if array is valid
   * @param arr 数组 Array
   * @param options 验证选项 Validation options
   * @returns 是否有效 Is valid
   */
  public static isValidArray<T>(arr: T[], options: { minLength?: number; maxLength?: number } = {}): boolean {
    if (!Array.isArray(arr)) {
      return false;
    }

    const length = arr.length;

    if (options.minLength !== undefined && length < options.minLength) {
      return false;
    }

    if (options.maxLength !== undefined && length > options.maxLength) {
      return false;
    }

    return true;
  }

  /**
   * 验证对象是否为空 Validates if object is empty
   * @param obj 对象 Object
   * @returns 是否为空 Is empty
   */
  public static isEmptyObject(obj: string): boolean {
    if (obj === null || obj === undefined) {
      return true;
    }

    if (typeof obj !== 'object') {
      return false;
    }

    if (Array.isArray(obj)) {
      return obj.length === 0;
    }

    return ObjectUtils.getKeys(obj).length === 0;
  }

  /**
   * 验证字符串是否为纯数字 Validates if string is pure number
   * @param str 字符串 String
   * @returns 是否为纯数字 Is pure number
   */
  public static isPureNumber(str: string): boolean {
    if (!str) {
      return false;
    }
    return /^\d+$/.test(str);
  }

  /**
   * 验证字符串是否为纯字母 Validates if string is pure letter
   * @param str 字符串 String
   * @returns 是否为纯字母 Is pure letter
   */
  public static isPureLetter(str: string): boolean {
    if (!str) {
      return false;
    }
    return /^[a-zA-Z]+$/.test(str);
  }

  /**
   * 验证字符串是否为字母数字组合 Validates if string is alphanumeric
   * @param str 字符串 String
   * @returns 是否为字母数字组合 Is alphanumeric
   */
  public static isAlphanumeric(str: string): boolean {
    if (!str) {
      return false;
    }
    return /^[a-zA-Z0-9]+$/.test(str);
  }

  /**
   * 验证字符串是否包含SQL注入攻击字符 Validates if string contains SQL injection attack characters
   * @param str 字符串 String
   * @returns 是否包含SQL注入攻击字符 Whether it contains SQL injection attack characters
   */
  public static containsSqlInjection(str: string): boolean {
    if (!str) {
      return false;
    }
    const sqlInjectionPatterns = [
      /\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|EXEC)\b/i,
      /\b(OR|AND)\s+1=1\b/i,
      /'OR'1'='1/,
      /"OR"1"="1/,
      /\bUNION\b.*\bSELECT\b/i,
      /\bDROP\b.*\bTABLE\b/i,
      /\bDROP\b.*\bDATABASE\b/i,
      /\bEXEC\b.*\bxp_\w+\b/i
    ];
    return sqlInjectionPatterns.some(pattern => pattern.test(str));
  }

  /**
   * 验证字符串是否包含XSS攻击字符 Validates if string contains XSS attack characters
   * @param str 字符串 String
   * @returns 是否包含XSS攻击字符 Whether it contains XSS attack characters
   */
  public static containsXssAttack(str: string): boolean {
    if (!str) {
      return false;
    }
    const xssPatterns = [
      /<script[^>]*>.*?<\/script>/gi,
      /<iframe[^>]*>.*?<\/iframe>/gi,
      /javascript:/gi,
      /on\w+\s*=/gi,
      /<img[^>]*src\s*=\s*["']?javascript:/gi,
      /<link[^>]*href\s*=\s*["']?javascript:/gi,
      /<object[^>]*data\s*=\s*["']?javascript:/gi
    ];
    return xssPatterns.some(pattern => pattern.test(str));
  }

  /**
   * 验证字符串是否包含路径遍历攻击字符 Validates if string contains path traversal attack characters
   * @param str 字符串 String
   * @returns 是否包含路径遍历攻击字符 Whether it contains path traversal attack characters
   */
  public static containsPathTraversal(str: string): boolean {
    if (!str) {
      return false;
    }
    const pathTraversalPatterns = [
      /\.\./,
      /\.\\/,
      /\/\.\./,
      /\\\.\.\\/,
      /^\.\./,
      /^\.\\/,
      /\/\.\.$/,
      /\\\.\.$/
    ];
    return pathTraversalPatterns.some(pattern => pattern.test(str));
  }

  /**
   * 验证字符串是否包含命令注入攻击字符 Validates if string contains command injection attack characters
   * @param str 字符串 String
   * @returns 是否包含命令注入攻击字符 Whether it contains command injection attack characters
   */
  public static containsCommandInjection(str: string): boolean {
    if (!str) {
      return false;
    }
    const commandInjectionPatterns = [
      /\|/,
      /&/,
      /;/,
      /\$\(/,
      /`/,
      /\/bin\/sh/,
      /\/bin\/bash/,
      /cmd\.exe/,
      /powershell/,
      /exec\(/,
      /system\(/,
      /eval\(/
    ];
    return commandInjectionPatterns.some(pattern => pattern.test(str));
  }

  /**
   * 清理字符串中的危险字符 Sanitizes dangerous characters in string
   * @param str 字符串 String
   * @returns 清理后的字符串 Sanitized string
   */
  public static sanitizeString(str: string): string {
    if (!str) {
      return str;
    }
    // 清理SQL注入字符
    let sanitized = str
      .replace(/\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|EXEC)\b/gi, '')
      .replace(/\b(OR|AND)\s+1=1\b/gi, '')
      .replace(/'OR'1'='1/g, '')
      .replace(/"OR"1"="1/g, '');
    
    // 清理XSS字符
    sanitized = sanitized
      .replace(/<script[^>]*>.*?<\/script>/gi, '')
      .replace(/<iframe[^>]*>.*?<\/iframe>/gi, '')
      .replace(/javascript:/gi, '')
      .replace(/on\w+\s*=/gi, '');
    
    // 清理路径遍历字符
    sanitized = sanitized
      .replace(/\.\./g, '')
      .replace(/\.\\/g, '');
    
    // 清理命令注入字符
    sanitized = sanitized
      .replace(/\|/g, '')
      .replace(/&/g, '')
      .replace(/;/g, '')
      .replace(/\$\(/g, '')
      .replace(/`/g, '')
      .replace(/\/bin\/sh/g, '')
      .replace(/\/bin\/bash/g, '')
      .replace(/cmd\.exe/g, '')
      .replace(/powershell/g, '');
    
    return sanitized;
  }

  /**
   * 验证输入是否安全 Validates if input is safe
   * @param input 输入值 Input value
   * @returns 是否安全 Is safe
   */
  public static isSafeInput(input: string): boolean {
    if (!input) {
      return true;
    }
    return !(
      this.containsSqlInjection(input) ||
      this.containsXssAttack(input) ||
      this.containsPathTraversal(input) ||
      this.containsCommandInjection(input)
    );
  }
}


export default ValidatorUtil;
