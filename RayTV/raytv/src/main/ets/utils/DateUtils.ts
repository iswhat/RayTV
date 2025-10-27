/**
 * 日期时间工具类
 * 提供日期时间的格式化、解析、计算等功能
 */
import Logger from './Logger';

export class DateUtils {
  private static readonly TAG = 'DateUtils';
  
  /**
   * 获取当前时间戳（毫秒）
   * @returns 当前时间戳
   */
  public static getCurrentTimestamp(): number {
    return Date.now();
  }
  
  /**
   * 获取当前日期对象
   * @returns 当前日期对象
   */
  public static getCurrentDate(): Date {
    return new Date();
  }
  
  /**
   * 格式化日期时间
   * @param date 日期对象或时间戳
   * @param format 格式字符串，默认为'YYYY-MM-DD HH:mm:ss'
   * @returns 格式化后的日期时间字符串
   */
  public static format(date: Date | number | string | null | undefined, format: string = 'YYYY-MM-DD HH:mm:ss'): string {
    try {
      let dateObj: Date;
      
      if (!date) {
        dateObj = new Date();
      } else if (date instanceof Date) {
        dateObj = date;
      } else {
        dateObj = new Date(date);
      }
      
      if (isNaN(dateObj.getTime())) {
        Logger.error(this.TAG, 'Invalid date input');
        return '';
      }
      
      const year = dateObj.getFullYear();
      const month = dateObj.getMonth() + 1;
      const day = dateObj.getDate();
      const hours = dateObj.getHours();
      const minutes = dateObj.getMinutes();
      const seconds = dateObj.getSeconds();
      const milliseconds = dateObj.getMilliseconds();
      
      const monthStr = String(month).padStart(2, '0');
      const dayStr = String(day).padStart(2, '0');
      const hoursStr = String(hours).padStart(2, '0');
      const minutesStr = String(minutes).padStart(2, '0');
      const secondsStr = String(seconds).padStart(2, '0');
      const millisecondsStr = String(milliseconds).padStart(3, '0');
      
      return format
        .replace('YYYY', String(year))
        .replace('YY', String(year).slice(-2))
        .replace('MM', monthStr)
        .replace('M', String(month))
        .replace('DD', dayStr)
        .replace('D', String(day))
        .replace('HH', hoursStr)
        .replace('H', String(hours))
        .replace('mm', minutesStr)
        .replace('m', String(minutes))
        .replace('ss', secondsStr)
        .replace('s', String(seconds))
        .replace('SSS', millisecondsStr);
    } catch (error) {
      Logger.error(this.TAG, `Date format error: ${error}`);
      return '';
    }
  }
  
  /**
   * 解析日期字符串
   * @param dateStr 日期字符串
   * @returns 日期对象或null（解析失败时）
   */
  public static parse(dateStr: string | null | undefined): Date | null {
    if (!dateStr) return null;
    
    try {
      const date = new Date(dateStr);
      return isNaN(date.getTime()) ? null : date;
    } catch (error) {
      Logger.error(this.TAG, `Date parse error: ${error}`);
      return null;
    }
  }
  
  /**
   * 格式化相对时间（如：3分钟前）
   * @param date 日期对象或时间戳
   * @returns 相对时间字符串
   */
  public static formatRelativeTime(date: Date | number | string | null | undefined): string {
    try {
      const now = Date.now();
      let dateObj: Date;
      
      if (!date) {
        return '';
      } else if (date instanceof Date) {
        dateObj = date;
      } else {
        dateObj = new Date(date);
      }
      
      if (isNaN(dateObj.getTime())) {
        return '';
      }
      
      const diff = now - dateObj.getTime();
      
      // 转换为不同时间单位
      const minute = 60 * 1000;
      const hour = 60 * minute;
      const day = 24 * hour;
      const week = 7 * day;
      const month = 30 * day;
      const year = 365 * day;
      
      if (diff < 0) {
        return '未来';
      } else if (diff < minute) {
        return '刚刚';
      } else if (diff < hour) {
        const minutes = Math.floor(diff / minute);
        return `${minutes}分钟前`;
      } else if (diff < day) {
        const hours = Math.floor(diff / hour);
        return `${hours}小时前`;
      } else if (diff < week) {
        const days = Math.floor(diff / day);
        return `${days}天前`;
      } else if (diff < month) {
        const weeks = Math.floor(diff / week);
        return `${weeks}周前`;
      } else if (diff < year) {
        const months = Math.floor(diff / month);
        return `${months}个月前`;
      } else {
        const years = Math.floor(diff / year);
        return `${years}年前`;
      }
    } catch (error) {
      Logger.error(this.TAG, `Relative time format error: ${error}`);
      return '';
    }
  }
  
  /**
   * 计算两个日期之间的差值（天数）
   * @param date1 第一个日期
   * @param date2 第二个日期，默认为当前日期
   * @returns 天数差值
   */
  public static daysBetween(date1: Date | number | string, date2: Date | number | string = new Date()): number {
    try {
      const d1 = date1 instanceof Date ? date1 : new Date(date1);
      const d2 = date2 instanceof Date ? date2 : new Date(date2);
      
      if (isNaN(d1.getTime()) || isNaN(d2.getTime())) {
        Logger.error(this.TAG, 'Invalid date inputs for daysBetween');
        return 0;
      }
      
      // 转换为当天的0点0分0秒，避免时分秒的影响
      const start = new Date(d1);
      start.setHours(0, 0, 0, 0);
      
      const end = new Date(d2);
      end.setHours(0, 0, 0, 0);
      
      // 计算毫秒差并转换为天数
      const diffTime = Math.abs(end.getTime() - start.getTime());
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
      
      return diffDays;
    } catch (error) {
      Logger.error(this.TAG, `Days between calculation error: ${error}`);
      return 0;
    }
  }
  
  /**
   * 添加天数
   * @param date 基础日期
   * @param days 要添加的天数
   * @returns 新的日期对象
   */
  public static addDays(date: Date | number | string, days: number): Date {
    try {
      const dateObj = date instanceof Date ? date : new Date(date);
      
      if (isNaN(dateObj.getTime())) {
        throw new Error('Invalid date');
      }
      
      const result = new Date(dateObj);
      result.setDate(result.getDate() + days);
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `Add days error: ${error}`);
      return new Date();
    }
  }
  
  /**
   * 添加月份
   * @param date 基础日期
   * @param months 要添加的月份数
   * @returns 新的日期对象
   */
  public static addMonths(date: Date | number | string, months: number): Date {
    try {
      const dateObj = date instanceof Date ? date : new Date(date);
      
      if (isNaN(dateObj.getTime())) {
        throw new Error('Invalid date');
      }
      
      const result = new Date(dateObj);
      result.setMonth(result.getMonth() + months);
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `Add months error: ${error}`);
      return new Date();
    }
  }
  
  /**
   * 添加年份
   * @param date 基础日期
   * @param years 要添加的年份数
   * @returns 新的日期对象
   */
  public static addYears(date: Date | number | string, years: number): Date {
    try {
      const dateObj = date instanceof Date ? date : new Date(date);
      
      if (isNaN(dateObj.getTime())) {
        throw new Error('Invalid date');
      }
      
      const result = new Date(dateObj);
      result.setFullYear(result.getFullYear() + years);
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `Add years error: ${error}`);
      return new Date();
    }
  }
  
  /**
   * 获取指定日期的开始时间（00:00:00）
   * @param date 日期对象
   * @returns 当天开始时间的日期对象
   */
  public static getStartOfDay(date: Date | number | string): Date {
    try {
      const dateObj = date instanceof Date ? date : new Date(date);
      
      if (isNaN(dateObj.getTime())) {
        throw new Error('Invalid date');
      }
      
      const result = new Date(dateObj);
      result.setHours(0, 0, 0, 0);
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `Get start of day error: ${error}`);
      return new Date();
    }
  }
  
  /**
   * 获取指定日期的结束时间（23:59:59）
   * @param date 日期对象
   * @returns 当天结束时间的日期对象
   */
  public static getEndOfDay(date: Date | number | string): Date {
    try {
      const dateObj = date instanceof Date ? date : new Date(date);
      
      if (isNaN(dateObj.getTime())) {
        throw new Error('Invalid date');
      }
      
      const result = new Date(dateObj);
      result.setHours(23, 59, 59, 999);
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `Get end of day error: ${error}`);
      return new Date();
    }
  }
  
  /**
   * 获取指定月份的第一天
   * @param date 日期对象
   * @returns 当月第一天的日期对象
   */
  public static getFirstDayOfMonth(date: Date | number | string): Date {
    try {
      const dateObj = date instanceof Date ? date : new Date(date);
      
      if (isNaN(dateObj.getTime())) {
        throw new Error('Invalid date');
      }
      
      return new Date(dateObj.getFullYear(), dateObj.getMonth(), 1);
    } catch (error) {
      Logger.error(this.TAG, `Get first day of month error: ${error}`);
      return new Date();
    }
  }
  
  /**
   * 获取指定月份的最后一天
   * @param date 日期对象
   * @returns 当月最后一天的日期对象
   */
  public static getLastDayOfMonth(date: Date | number | string): Date {
    try {
      const dateObj = date instanceof Date ? date : new Date(date);
      
      if (isNaN(dateObj.getTime())) {
        throw new Error('Invalid date');
      }
      
      return new Date(dateObj.getFullYear(), dateObj.getMonth() + 1, 0);
    } catch (error) {
      Logger.error(this.TAG, `Get last day of month error: ${error}`);
      return new Date();
    }
  }
  
  /**
   * 判断是否为闰年
   * @param year 年份或日期对象
   * @returns 是否为闰年
   */
  public static isLeapYear(year: number | Date): boolean {
    try {
      const y = typeof year === 'number' ? year : year.getFullYear();
      return (y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0);
    } catch (error) {
      Logger.error(this.TAG, `Is leap year error: ${error}`);
      return false;
    }
  }
  
  /**
   * 判断两个日期是否为同一天
   * @param date1 第一个日期
   * @param date2 第二个日期，默认为当前日期
   * @returns 是否为同一天
   */
  public static isSameDay(date1: Date | number | string, date2: Date | number | string = new Date()): boolean {
    try {
      const d1 = date1 instanceof Date ? date1 : new Date(date1);
      const d2 = date2 instanceof Date ? date2 : new Date(date2);
      
      if (isNaN(d1.getTime()) || isNaN(d2.getTime())) {
        return false;
      }
      
      return (
        d1.getFullYear() === d2.getFullYear() &&
        d1.getMonth() === d2.getMonth() &&
        d1.getDate() === d2.getDate()
      );
    } catch (error) {
      Logger.error(this.TAG, `Is same day error: ${error}`);
      return false;
    }
  }
  
  /**
   * 获取日期所在的星期几
   * @param date 日期对象
   * @param short 是否返回短格式
   * @returns 星期几的中文名称
   */
  public static getWeekdayName(date: Date | number | string, short: boolean = false): string {
    try {
      const dateObj = date instanceof Date ? date : new Date(date);
      
      if (isNaN(dateObj.getTime())) {
        return '';
      }
      
      const weekdays = short
        ? ['日', '一', '二', '三', '四', '五', '六']
        : ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
      
      const index = dateObj.getDay();
      return weekdays[index];
    } catch (error) {
      Logger.error(this.TAG, `Get weekday name error: ${error}`);
      return '';
    }
  }
  
  /**
   * 获取月份的名称
   * @param month 月份（0-11）或日期对象
   * @param short 是否返回短格式
   * @returns 月份的中文名称
   */
  public static getMonthName(month: number | Date, short: boolean = false): string {
    try {
      const m = typeof month === 'number' ? month : month.getMonth();
      
      const months = short
        ? ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']
        : ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
      
      if (m < 0 || m > 11) {
        return '';
      }
      
      return months[m];
    } catch (error) {
      Logger.error(this.TAG, `Get month name error: ${error}`);
      return '';
    }
  }
  
  /**
   * 格式化持续时间（毫秒）为可读字符串
   * @param milliseconds 毫秒数
   * @returns 格式化的持续时间字符串
   */
  public static formatDuration(milliseconds: number | null | undefined): string {
    if (milliseconds === null || milliseconds === undefined || milliseconds < 0) {
      return '00:00';
    }
    
    try {
      const totalSeconds = Math.floor(milliseconds / 1000);
      const hours = Math.floor(totalSeconds / 3600);
      const minutes = Math.floor((totalSeconds % 3600) / 60);
      const seconds = totalSeconds % 60;
      
      const hoursStr = hours.toString().padStart(2, '0');
      const minutesStr = minutes.toString().padStart(2, '0');
      const secondsStr = seconds.toString().padStart(2, '0');
      
      if (hours > 0) {
        return `${hoursStr}:${minutesStr}:${secondsStr}`;
      } else {
        return `${minutesStr}:${secondsStr}`;
      }
    } catch (error) {
      Logger.error(this.TAG, `Format duration error: ${error}`);
      return '00:00';
    }
  }
}

export default DateUtils;