// DateUtils.ets - ArkTS兼容的日期时间工具函数

/**
 * 日期时间工具函数
 * 提供ArkTS环境中安全的日期时间操作功能
 */
import { Optional } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';
import StringUtils from './StringUtils';

/**
 * 日期时间工具函数集合
 */
export const DateUtils = {
  /**
   * 检查值是否为Date对象
   */
  isDate(value: unknown): boolean {
    return value instanceof Date && !isNaN(value.getTime());
  },

  /**
   * 获取当前日期时间
   */
  now(): Date {
    return new Date();
  },

  /**
   * 获取当前时间戳
   */
  timestamp(): number {
    return Date.now();
  },

  /**
   * 创建日期对象
   */
  create(year: number, month: number, date: number = 1, hours: number = 0, minutes: number = 0, seconds: number = 0, milliseconds: number = 0): Date {
    // 注意：JavaScript中月份是从0开始的，这里也遵循相同的规则
    return new Date(year, month, date, hours, minutes, seconds, milliseconds);
  },

  /**
   * 解析日期字符串
   */
  parse(dateString: Optional<string>): Date | null {
    if (StringUtils.isEmpty(dateString)) {
      return null;
    }
    
    const date = new Date(dateString);
    
    return DateUtils.isDate(date) ? date : null;
  },

  /**
   * 获取日期的年
   */
  getFullYear(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getFullYear();
  },

  /**
   * 获取日期的月（0-11）
   */
  getMonth(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getMonth();
  },

  /**
   * 获取日期的日（1-31）
   */
  getDate(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getDate();
  },

  /**
   * 获取日期的小时（0-23）
   */
  getHours(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getHours();
  },

  /**
   * 获取日期的分钟（0-59）
   */
  getMinutes(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getMinutes();
  },

  /**
   * 获取日期的秒（0-59）
   */
  getSeconds(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getSeconds();
  },

  /**
   * 获取日期的毫秒（0-999）
   */
  getMilliseconds(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getMilliseconds();
  },

  /**
   * 获取日期的星期（0-6，0表示周日）
   */
  getDay(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getDay();
  },

  /**
   * 格式化日期时间
   */
  format(date: Optional<Date>, formatString: string = 'YYYY-MM-DD HH:mm:ss'): string {
    if (!DateUtils.isDate(date)) {
      return '';
    }
    
    const year = DateUtils.getFullYear(date).toString();
    const month = (DateUtils.getMonth(date) + 1).toString().padStart(2, '0');
    const day = DateUtils.getDate(date).toString().padStart(2, '0');
    const hours = DateUtils.getHours(date).toString().padStart(2, '0');
    const minutes = DateUtils.getMinutes(date).toString().padStart(2, '0');
    const seconds = DateUtils.getSeconds(date).toString().padStart(2, '0');
    const milliseconds = DateUtils.getMilliseconds(date).toString().padStart(3, '0');
    
    return formatString
      .replace('YYYY', year)
      .replace('YY', year.slice(-2))
      .replace('MM', month)
      .replace('DD', day)
      .replace('HH', hours)
      .replace('mm', minutes)
      .replace('ss', seconds)
      .replace('SSS', milliseconds);
  },

  /**
   * 计算两个日期之间的天数差
   */
  daysBetween(date1: Optional<Date>, date2: Optional<Date>): number {
    if (!DateUtils.isDate(date1) || !DateUtils.isDate(date2)) {
      return 0;
    }
    
    const oneDay = 24 * 60 * 60 * 1000;
    const diffTime = Math.abs(date2.getTime() - date1.getTime());
    
    return Math.floor(diffTime / oneDay);
  },

  /**
   * 检查日期是否是今天
   */
  isToday(date: Optional<Date>): boolean {
    if (!DateUtils.isDate(date)) {
      return false;
    }
    
    const today = DateUtils.now();
    
    return DateUtils.getFullYear(date) === DateUtils.getFullYear(today) &&
           DateUtils.getMonth(date) === DateUtils.getMonth(today) &&
           DateUtils.getDate(date) === DateUtils.getDate(today);
  },

  /**
   * 检查日期是否是昨天
   */
  isYesterday(date: Optional<Date>): boolean {
    if (!DateUtils.isDate(date)) {
      return false;
    }
    
    const yesterday = DateUtils.subDays(DateUtils.now(), 1);
    
    return DateUtils.getFullYear(date) === DateUtils.getFullYear(yesterday) &&
           DateUtils.getMonth(date) === DateUtils.getMonth(yesterday) &&
           DateUtils.getDate(date) === DateUtils.getDate(yesterday);
  },

  /**
   * 添加天数
   */
  addDays(date: Optional<Date>, days: number): Date | null {
    if (!DateUtils.isDate(date)) {
      return null;
    }
    
    const result = new Date(date.getTime());
    result.setDate(result.getDate() + days);
    
    return result;
  },

  /**
   * 减去天数
   */
  subDays(date: Optional<Date>, days: number): Date | null {
    return DateUtils.addDays(date, -days);
  },

  /**
   * 添加月数
   */
  addMonths(date: Optional<Date>, months: number): Date | null {
    if (!DateUtils.isDate(date)) {
      return null;
    }
    
    const result = new Date(date.getTime());
    result.setMonth(result.getMonth() + months);
    
    return result;
  },

  /**
   * 减去月数
   */
  subMonths(date: Optional<Date>, months: number): Date | null {
    return DateUtils.addMonths(date, -months);
  },

  /**
   * 添加年数
   */
  addYears(date: Optional<Date>, years: number): Date | null {
    if (!DateUtils.isDate(date)) {
      return null;
    }
    
    const result = new Date(date.getTime());
    result.setFullYear(result.getFullYear() + years);
    
    return result;
  },

  /**
   * 减去年数
   */
  subYears(date: Optional<Date>, years: number): Date | null {
    return DateUtils.addYears(date, -years);
  },

  /**
   * 格式化时长（毫秒转可读时间）
   */
  formatDuration(milliseconds: number): string {
    if (!TypeUtils.isNumber(milliseconds) || milliseconds < 0) {
      return '00:00';
    }
    
    const totalSeconds = Math.floor(milliseconds / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
    
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  },

  /**
   * 获取相对时间描述
   */
  getRelativeTimeString(date: Optional<Date>): string {
    if (!DateUtils.isDate(date)) {
      return '';
    }
    
    const now = DateUtils.timestamp();
    const targetTime = date.getTime();
    const diff = now - targetTime;
    
    // 转换为秒
    const diffSeconds = Math.floor(diff / 1000);
    
    // 转换为分钟
    const diffMinutes = Math.floor(diffSeconds / 60);
    
    // 转换为小时
    const diffHours = Math.floor(diffMinutes / 60);
    
    // 转换为天
    const diffDays = Math.floor(diffHours / 24);
    
    // 转换为月（近似）
    const diffMonths = Math.floor(diffDays / 30);
    
    // 转换为年（近似）
    const diffYears = Math.floor(diffDays / 365);
    
    if (diffYears > 0) {
      return `${diffYears}年前`;
    } else if (diffMonths > 0) {
      return `${diffMonths}个月前`;
    } else if (diffDays > 0) {
      return `${diffDays}天前`;
    } else if (diffHours > 0) {
      return `${diffHours}小时前`;
    } else if (diffMinutes > 0) {
      return `${diffMinutes}分钟前`;
    } else if (diffSeconds > 0) {
      return `${diffSeconds}秒前`;
    } else {
      return '刚刚';
    }
  }
};

export default DateUtils;
