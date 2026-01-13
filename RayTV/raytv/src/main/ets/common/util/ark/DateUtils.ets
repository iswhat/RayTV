// DateUtils.ets - ArkTS兼容的日期时间工具函数 ArkTS compatible date and time utility functions
/**
 * 日期时间工具函数 Date and time utility functions
 * 提供ArkTS环境中安全的日期时间操作功能 Provides safe date and time operation functionality in ArkTS environment
 */
import { Optional } from './types/ArkTSBaseTypes';
import TypeUtils from './TypeUtils';
import StringUtils from './StringUtils';

/**
 * 日期时间工具函数集合 Date and time utility functions collection
 */
export const DateUtils = {
  /**
   * 检查值是否为Date对象 Checks if value is a Date object
   */
  isDate(value: any): boolean {
    return value instanceof Date && !isNaN(value.getTime());
  },

  /**
   * 获取当前日期时间 Gets current date and time
   */
  now(): Date {
    return new Date();
  },

  /**
   * 获取当前时间戳 Gets current timestamp
   */
  timestamp(): number {
    return Date.now();
  },

  /**
   * 创建日期对象 Creates date object
   */
  create(year: number, month: number, date: number = 1, hours: number = 0, minutes: number = 0, seconds: number = 0, milliseconds: number = 0): Date {
    // 注意：JavaScript中月份是从0开始的，这里也遵循同样的规则 Note: JavaScript months start from 0, following the same rule here
    return new Date(year, month, date, hours, minutes, seconds, milliseconds);
  },

  /**
   * 解析日期字符串 Parses date string
   */
  parse(dateString: Optional<string>): Date | null {
    if (StringUtils.isEmpty(dateString)) {
      return null;
    }
    
    const date = new Date(dateString);
    
    return DateUtils.isDate(date) ? date : null;
  },

  /**
   * 获取日期的年 Gets year of date
   */
  getFullYear(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getFullYear();
  },

  /**
   * 获取日期的月 Gets month of date (0-11)
   */
  getMonth(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getMonth();
  },

  /**
   * 获取日期的日 Gets day of date (1-31)
   */
  getDate(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getDate();
  },

  /**
   * 获取日期的小时 Gets hours of date (0-23)
   */
  getHours(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getHours();
  },

  /**
   * 获取日期的分钟 Gets minutes of date (0-59)
   */
  getMinutes(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getMinutes();
  },

  /**
   * 获取日期的秒 Gets seconds of date (0-59)
   */
  getSeconds(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getSeconds();
  },

  /**
   * 获取日期的毫秒 Gets milliseconds of date (0-999)
   */
  getMilliseconds(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getMilliseconds();
  },

  /**
   * 获取日期的星期 Gets day of week (0-6, 0 means Sunday)
   */
  getDay(date: Optional<Date>): number {
    if (!DateUtils.isDate(date)) {
      return 0;
    }
    
    return date.getDay();
  },

  /**
   * 格式化日期时间 Formats date and time
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
   * 计算两个日期之间的天数差 Calculates days difference between two dates
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
   * 检查日期是否是今天 Checks if date is today
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
   * 检查日期是否是昨天 Checks if date is yesterday
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
   * 添加天数 Adds days
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
   * 减去天数 Subtracts days
   */
  subDays(date: Optional<Date>, days: number): Date | null {
    return DateUtils.addDays(date, -days);
  },

  /**
   * 添加月数 Adds months
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
   * 减去月数 Subtracts months
   */
  subMonths(date: Optional<Date>, months: number): Date | null {
    return DateUtils.addMonths(date, -months);
  },

  /**
   * 添加年数 Adds years
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
   * 减去年数 Subtracts years
   */
  subYears(date: Optional<Date>, years: number): Date | null {
    return DateUtils.addYears(date, -years);
  },

  /**
   * 格式化时长（毫秒转可读时间）Formats duration (milliseconds to readable time)
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
   * 获取相对时间描述 Gets relative time description
   */
  getRelativeTimeString(date: Optional<Date>): string {
    if (!DateUtils.isDate(date)) {
      return '';
    }
    
    const now = DateUtils.timestamp();
    const targetTime = date.getTime();
    const diff = now - targetTime;
    
    // 转换为秒 Converts to seconds
    const diffSeconds = Math.floor(diff / 1000);
    
    // 转换为分钟 Converts to minutes
    const diffMinutes = Math.floor(diffSeconds / 60);
    
    // 转换为小时 Converts to hours
    const diffHours = Math.floor(diffMinutes / 60);
    
    // 转换为天 Converts to days
    const diffDays = Math.floor(diffHours / 24);
    
    // 转换为月（近似）Converts to months (approximate)
    const diffMonths = Math.floor(diffDays / 30);
    
    // 转换为年（近似）Converts to years (approximate)
    const diffYears = Math.floor(diffDays / 365);
    
    if (diffYears > 0) {
      return `${diffYears}年前 ${diffYears} years ago`;
    } else if (diffMonths > 0) {
      return `${diffMonths}个月前 ${diffMonths} months ago`;
    } else if (diffDays > 0) {
      return `${diffDays}天前 ${diffDays} days ago`;
    } else if (diffHours > 0) {
      return `${diffHours}小时前 ${diffHours} hours ago`;
    } else if (diffMinutes > 0) {
      return `${diffMinutes}分钟前 ${diffMinutes} minutes ago`;
    } else if (diffSeconds > 0) {
      return `${diffSeconds}秒前 ${diffSeconds} seconds ago`;
    } else {
      return '刚刚 just now';
    }
  }
};

export default DateUtils;




