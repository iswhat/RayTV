// ValidatorUtil - 验证工具类
// 提供数据验证相关的工具函数，包括邮箱、手机号、URL等验证

import { Logger } from './Logger';

/**
 * 验证工具类
 */
export class ValidatorUtil {
  private static instance: ValidatorUtil;
  private logger = Logger.getInstance();

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('ValidatorUtil initialized');
  }

  /**
   * 获取ValidatorUtil单例实例
   */
  public static getInstance(): ValidatorUtil {
    if (!ValidatorUtil.instance) {
      ValidatorUtil.instance = new ValidatorUtil();
    }
    return ValidatorUtil.instance;
  }

  /**
   * 验证邮箱格式
   * @param email 邮箱地址
   */
  public isValidEmail(email: string): boolean {
    try {
      if (!email || typeof email !== 'string') {
        return false;
      }

      // 标准邮箱格式验证正则表达式
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      return emailRegex.test(email);
    } catch (error) {
      this.logger.error('Failed to validate email', error as Error);
      return false;
    }
  }

  /**
   * 验证手机号格式（支持中国手机号）
   * @param phone 手机号
   * @param countryCode 国家代码
   */
  public isValidPhone(phone: string, countryCode: string = 'CN'): boolean {
    try {
      if (!phone || typeof phone !== 'string') {
        return false;
      }

      // 移除国家代码前缀和空格
      const cleanedPhone = phone.replace(/[+\s-]/g, '');

      // 中国手机号验证
      if (countryCode === 'CN') {
        const cnPhoneRegex = /^1[3-9]\d{9}$/;
        return cnPhoneRegex.test(cleanedPhone);
      }
      
      // 简单的国际手机号验证（10-15位数字）
      const generalPhoneRegex = /^\d{10,15}$/;
      return generalPhoneRegex.test(cleanedPhone);
    } catch (error) {
      this.logger.error('Failed to validate phone number', error as Error);
      return false;
    }
  }

  /**
   * 验证URL格式
   * @param url URL地址
   */
  public isValidUrl(url: string): boolean {
    try {
      if (!url || typeof url !== 'string') {
        return false;
      }

      // 简单的URL验证
      const urlRegex = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([/\w .-]*)*\/?$/;
      return urlRegex.test(url);
    } catch (error) {
      this.logger.error('Failed to validate URL', error as Error);
      return false;
    }
  }

  /**
   * 验证IPv4地址
   * @param ip IP地址
   */
  public isValidIpv4(ip: string): boolean {
    try {
      if (!ip || typeof ip !== 'string') {
        return false;
      }

      const ipv4Regex = /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
      return ipv4Regex.test(ip);
    } catch (error) {
      this.logger.error('Failed to validate IPv4 address', error as Error);
      return false;
    }
  }

  /**
   * 验证是否为有效数字
   * @param value 值
   * @param options 验证选项
   */
  public isValidNumber(value: unknown, options: { min?: number; max?: number; integer?: boolean } = {}): boolean {
    try {
      const num = Number(value);

      if (isNaN(num)) {
        return false;
      }

      // 检查是否为整数
      if (options.integer && !Number.isInteger(num)) {
        return false;
      }

      // 检查最小值
      if (options.min !== undefined && num < options.min) {
        return false;
      }

      // 检查最大值
      if (options.max !== undefined && num > options.max) {
        return false;
      }

      return true;
    } catch (error) {
      this.logger.error('Failed to validate number', error as Error);
      return false;
    }
  }

  /**
   * 验证字符串长度
   * @param str 字符串
   * @param min 最小长度
   * @param max 最大长度
   */
  public isValidLength(str: string, min: number = 0, max: number = Infinity): boolean {
    try {
      if (typeof str !== 'string') {
        return false;
      }

      const length = str.length;
      return length >= min && length <= max;
    } catch (error) {
      this.logger.error('Failed to validate string length', error as Error);
      return false;
    }
  }

  /**
   * 验证密码强度
   * @param password 密码
   * @param options 验证选项
   */
  public isValidPassword(password: string, options: {
    minLength?: number;
    requireUppercase?: boolean;
    requireLowercase?: boolean;
    requireNumber?: boolean;
    requireSpecial?: boolean;
  } = {}): boolean {
    try {
      if (!password || typeof password !== 'string') {
        return false;
      }

      const { minLength = 8, requireUppercase = true, requireLowercase = true, requireNumber = true, requireSpecial = true } = options;

      // 检查最小长度
      if (password.length < minLength) {
        return false;
      }

      // 检查大写字母
      if (requireUppercase && !/[A-Z]/.test(password)) {
        return false;
      }

      // 检查小写字母
      if (requireLowercase && !/[a-z]/.test(password)) {
        return false;
      }

      // 检查数字
      if (requireNumber && !/[0-9]/.test(password)) {
        return false;
      }

      // 检查特殊字符
      if (requireSpecial && !/[^A-Za-z0-9]/.test(password)) {
        return false;
      }

      return true;
    } catch (error) {
      this.logger.error('Failed to validate password strength', error as Error);
      return false;
    }
  }

  /**
   * 验证用户名
   * @param username 用户名
   * @param options 验证选项
   */
  public isValidUsername(username: string, options: {
    minLength?: number;
    maxLength?: number;
    allowUnderscore?: boolean;
    allowHyphen?: boolean;
  } = {}): boolean {
    try {
      if (!username || typeof username !== 'string') {
        return false;
      }

      const { minLength = 3, maxLength = 20, allowUnderscore = true, allowHyphen = true } = options;

      // 检查长度
      if (username.length < minLength || username.length > maxLength) {
        return false;
      }

      // 构建正则表达式
      let pattern = '^[a-zA-Z0-9';
      if (allowUnderscore) pattern += '_';
      if (allowHyphen) pattern += '-';
      pattern += ']+$';

      const usernameRegex = new RegExp(pattern);
      return usernameRegex.test(username);
    } catch (error) {
      this.logger.error('Failed to validate username', error as Error);
      return false;
    }
  }

  /**
   * 验证身份证号（支持中国大陆）
   * @param idNumber 身份证号
   */
  public isValidIdCard(idNumber: string): boolean {
    try {
      if (!idNumber || typeof idNumber !== 'string') {
        return false;
      }

      // 简单的18位身份证号格式验证
      const idCardRegex = /^[1-9]\d{5}(19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[0-9Xx]$/;
      if (!idCardRegex.test(idNumber)) {
        return false;
      }

      // 这里可以添加更复杂的校验码验证逻辑
      return true;
    } catch (error) {
      this.logger.error('Failed to validate ID card number', error as Error);
      return false;
    }
  }

  /**
   * 验证日期是否有效
   * @param date 日期
   */
  public isValidDate(date: unknown): boolean {
    try {
      const d = new Date(date);
      return !isNaN(d.getTime());
    } catch (error) {
      this.logger.error('Failed to validate date', error as Error);
      return false;
    }
  }

  /**
   * 验证是否为空值
   * @param value 值
   */
  public isEmpty(value: unknown): boolean {
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
      return Object.keys(value).length === 0;
    }

    return false;
  }

  /**
   * 验证是否为有效的JSON字符串
   * @param str 字符串
   */
  public isValidJSON(str: string): boolean {
    try {
      if (typeof str !== 'string') {
        return false;
      }

      JSON.parse(str);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 验证文件扩展名
   * @param fileName 文件名
   * @param allowedExtensions 允许的扩展名列表
   */
  public isValidFileExtension(fileName: string, allowedExtensions: string[]): boolean {
    try {
      if (!fileName || typeof fileName !== 'string') {
        return false;
      }

      const extension = fileName.split('.').pop()?.toLowerCase();
      if (!extension) {
        return false;
      }

      const normalizedExtensions = allowedExtensions.map(ext => ext.toLowerCase().replace(/^\./, ''));
      return normalizedExtensions.includes(extension);
    } catch (error) {
      this.logger.error('Failed to validate file extension', error as Error);
      return false;
    }
  }

  /**
   * 验证文件大小
   * @param size 文件大小（字节）
   * @param maxSize 最大大小（字节）
   */
  public isValidFileSize(size: number, maxSize: number): boolean {
    try {
      if (typeof size !== 'number' || typeof maxSize !== 'number') {
        return false;
      }

      return size <= maxSize && size >= 0;
    } catch (error) {
      this.logger.error('Failed to validate file size', error as Error);
      return false;
    }
  }

  /**
   * 验证是否为有效的时间戳
   * @param timestamp 时间戳
   */
  public isValidTimestamp(timestamp: number): boolean {
    try {
      if (typeof timestamp !== 'number') {
        return false;
      }

      return timestamp >= 0 && Number.isFinite(timestamp) && new Date(timestamp).getTime() === timestamp;
    } catch (error) {
      this.logger.error('Failed to validate timestamp', error as Error);
      return false;
    }
  }

  /**
   * 验证颜色格式（支持hex、rgb、rgba）
   * @param color 颜色值
   */
  public isValidColor(color: string): boolean {
    try {
      if (!color || typeof color !== 'string') {
        return false;
      }

      // 检查hex格式
      const hexRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|[A-Fa-f0-9]{8})$/;
      if (hexRegex.test(color)) {
        return true;
      }

      // 检查rgb格式
      const rgbRegex = /^rgb\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})\)$/;
      if (rgbRegex.test(color)) {
        return true;
      }

      // 检查rgba格式
      const rgbaRegex = /^rgba\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),\s*([01]\.?\d*)\)$/;
      if (rgbaRegex.test(color)) {
        return true;
      }

      return false;
    } catch (error) {
      this.logger.error('Failed to validate color', error as Error);
      return false;
    }
  }

  /**
   * 验证MAC地址
   * @param mac MAC地址
   */
  public isValidMacAddress(mac: string): boolean {
    try {
      if (!mac || typeof mac !== 'string') {
        return false;
      }

      const macRegex = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/;
      return macRegex.test(mac);
    } catch (error) {
      this.logger.error('Failed to validate MAC address', error as Error);
      return false;
    }
  }

  /**
   * 验证车牌号（中国）
   * @param plateNumber 车牌号
   */
  public isValidPlateNumber(plateNumber: string): boolean {
    try {
      if (!plateNumber || typeof plateNumber !== 'string') {
        return false;
      }

      // 简单的中国车牌号格式验证
      const plateRegex = /^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领A-Z]{1}[A-Z]{1}[A-Z0-9]{4}[A-Z0-9挂学警港澳]{1}$/;
      return plateRegex.test(plateNumber);
    } catch (error) {
      this.logger.error('Failed to validate plate number', error as Error);
      return false;
    }
  }

  /**
   * 验证邮政编码（中国）
   * @param postalCode 邮政编码
   */
  public isValidPostalCode(postalCode: string): boolean {
    try {
      if (!postalCode || typeof postalCode !== 'string') {
        return false;
      }

      const postalRegex = /^[1-9]\d{5}$/;
      return postalRegex.test(postalCode);
    } catch (error) {
      this.logger.error('Failed to validate postal code', error as Error);
      return false;
    }
  }

  /**
   * 验证银行卡号
   * @param cardNumber 银行卡号
   */
  public isValidBankCard(cardNumber: string): boolean {
    try {
      if (!cardNumber || typeof cardNumber !== 'string') {
        return false;
      }

      // 移除空格和连字符
      const cleanedNumber = cardNumber.replace(/[\s-]/g, '');

      // 检查是否为纯数字且长度在13-19位之间
      const bankCardRegex = /^\d{13,19}$/;
      if (!bankCardRegex.test(cleanedNumber)) {
        return false;
      }

      // Luhn算法验证
      return this.luhnCheck(cleanedNumber);
    } catch (error) {
      this.logger.error('Failed to validate bank card number', error as Error);
      return false;
    }
  }

  /**
   * Luhn算法验证函数
   * @param number 数字字符串
   */
  private luhnCheck(number: string): boolean {
    let sum = 0;
    let isEven = false;

    for (let i = number.length - 1; i >= 0; i--) {
      let digit = parseInt(number.charAt(i), 10);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 === 0;
  }

  /**
   * 验证是否为有效对象
   * @param obj 对象
   */
  public isValidObject(obj: unknown): boolean {
    try {
      return obj !== null && typeof obj === 'object' && !Array.isArray(obj);
    } catch (error) {
      this.logger.error('Failed to validate object', error as Error);
      return false;
    }
  }

  /**
   * 验证是否为有效数组
   * @param arr 数组
   * @param options 验证选项
   */
  public isValidArray(arr: unknown, options: { minLength?: number; maxLength?: number } = {}): boolean {
    try {
      if (!Array.isArray(arr)) {
        return false;
      }

      const { minLength = 0, maxLength = Infinity } = options;
      return arr.length >= minLength && arr.length <= maxLength;
    } catch (error) {
      this.logger.error('Failed to validate array', error as Error);
      return false;
    }
  }

  /**
   * 验证是否为有效函数
   * @param fn 函数
   */
  public isValidFunction(fn: unknown): boolean {
    try {
      return typeof fn === 'function';
    } catch (error) {
      this.logger.error('Failed to validate function', error as Error);
      return false;
    }
  }

  /**
   * 验证URL参数是否有效
   * @param params URL参数对象
   */
  public isValidUrlParams(params: Record<string, any>): boolean {
    try {
      if (!this.isValidObject(params)) {
        return false;
      }

      // 检查参数值是否有效
      for (const value of Object.values(params)) {
        if (value === undefined || typeof value === 'function' || this.isValidObject(value) || Array.isArray(value)) {
          return false;
        }
      }

      return true;
    } catch (error) {
      this.logger.error('Failed to validate URL params', error as Error);
      return false;
    }
  }

  /**
   * 综合验证对象
   * @param obj 要验证的对象
   * @param schema 验证模式
   */
  public validateObject(obj: unknown, schema: Record<string, (value: unknown) => boolean>): { isValid: boolean; errors: string[] } {
    try {
      if (!this.isValidObject(obj)) {
        return { isValid: false, errors: ['Invalid object'] };
      }

      const errors: string[] = [];

      for (const [key, validator] of Object.entries(schema)) {
        if (!validator(obj[key])) {
          errors.push(`Invalid value for field: ${key}`);
        }
      }

      return { isValid: errors.length === 0, errors };
    } catch (error) {
      this.logger.error('Failed to validate object', error as Error);
      return { isValid: false, errors: ['Validation error'] };
    }
  }

  /**
   * 验证两个值是否相等（深度比较）
   * @param value1 值1
   * @param value2 值2
   */
  public isEqual(value1: unknown, value2: unknown): boolean {
    try {
      // 处理基本类型和null/undefined
      if (value1 === value2) {
        return true;
      }

      // 处理对象类型
      if (this.isValidObject(value1) && this.isValidObject(value2)) {
        const keys1 = Object.keys(value1);
        const keys2 = Object.keys(value2);

        if (keys1.length !== keys2.length) {
          return false;
        }

        for (const key of keys1) {
          if (!keys2.includes(key) || !this.isEqual(value1[key], value2[key])) {
            return false;
          }
        }

        return true;
      }

      // 处理数组类型
      if (Array.isArray(value1) && Array.isArray(value2)) {
        if (value1.length !== value2.length) {
          return false;
        }

        for (let i = 0; i < value1.length; i++) {
          if (!this.isEqual(value1[i], value2[i])) {
            return false;
          }
        }

        return true;
      }

      return false;
    } catch (error) {
      this.logger.error('Failed to compare values', error as Error);
      return false;
    }
  }
}

// 导出默认实例
export default ValidatorUtil.getInstance();