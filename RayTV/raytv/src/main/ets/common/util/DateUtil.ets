// DateUtil - 日期和时间处理工具类
import Logger from './Logger';

const TAG = 'DateUtil';

/**
 * 日期格式类型枚举
 */
export enum DateFormatType {
  FULL,        // 完整格式：YYYY-MM-DD HH:mm:ss
  DATE,        // 日期格式：YYYY-MM-DD
  TIME,        // 时间格式：HH:mm:ss
  TIME_SHORT,  // 短时间格式：HH:mm
  DATE_CHINESE,// 中文日期格式：YYYY年MM月DD日
  FULL_CHINESE // 完整中文格式：YYYY年MM月DD日 HH:mm:ss
}

/**
 * 日期工具类
 * 提供日期格式化、解析、比较等功能
 */
export default class DateUtil {
  /**
   * 格式化日期
   * @param date 日期对象或时间戳
   * @param format 格式化类型或自定义格式字符串
   * @returns 格式化后的日期字符串
   */
  public static format(date: Date | number | string, format: DateFormatType | string = DateFormatType.FULL): string {
    try {
      const dateObj = DateUtil.parseDate(date);
      if (!dateObj) {
        throw new Error('Invalid date');
      }

      // 根据格式类型获取对应的格式字符串
      let formatStr = format;
      if (typeof format !== 'string') {
        switch (format) {
          case DateFormatType.FULL:
            formatStr = 'YYYY-MM-DD HH:mm:ss';
            break;
          case DateFormatType.DATE:
            formatStr = 'YYYY-MM-DD';
            break;
          case DateFormatType.TIME:
            formatStr = 'HH:mm:ss';
            break;
          case DateFormatType.TIME_SHORT:
            formatStr = 'HH:mm';
            break;
          case DateFormatType.DATE_CHINESE:
            formatStr = 'YYYY年MM月DD日';
            break;
          case DateFormatType.FULL_CHINESE:
            formatStr = 'YYYY年MM月DD日 HH:mm:ss';
            break;
          default:
            formatStr = 'YYYY-MM-DD HH:mm:ss';
        }
      }

      // 格式化替换
      return formatStr
        .replace('YYYY', dateObj.getFullYear().toString())
        .replace('MM', DateUtil.padZero(dateObj.getMonth() + 1))
        .replace('DD', DateUtil.padZero(dateObj.getDate()))
        .replace('HH', DateUtil.padZero(dateObj.getHours()))
        .replace('mm', DateUtil.padZero(dateObj.getMinutes()))
        .replace('ss', DateUtil.padZero(dateObj.getSeconds()));
    } catch (error) {
      Logger.error(TAG, `Failed to format date: ${error}`);
      return '';
    }
  }

  /**
   * 解析日期字符串
   * @param dateStr 日期字符串
   * @param format 格式字符串（可选）
   * @returns 解析后的日期对象
   */
  public static parse(dateStr: string, format?: string): Date | null {
    try {
      if (!dateStr) return null;

      // 如果提供了格式，使用更精确的解析
      if (format) {
        return DateUtil.parseWithFormat(dateStr, format);
      }

      // 默认解析
      const date = new Date(dateStr);
      return isNaN(date.getTime()) ? null : date;
    } catch (error) {
      Logger.error(TAG, `Failed to parse date string: ${error}`);
      return null;
    }
  }

  /**
   * 根据格式解析日期字符串
   * @param dateStr 日期字符串
   * @param format 格式字符串
   * @returns 解析后的日期对象
   */
  private static parseWithFormat(dateStr: string, format: string): Date | null {
    try {
      // 提取格式中的年月日时分秒位置
      const yearMatch = format.match(/YYYY/g);
      const monthMatch = format.match(/MM/g);
      const dayMatch = format.match(/DD/g);
      const hourMatch = format.match(/HH/g);
      const minuteMatch = format.match(/mm/g);
      const secondMatch = format.match(/ss/g);

      let year = 1970, month = 0, day = 1;
      let hour = 0, minute = 0, second = 0;

      // 提取年月日
      if (yearMatch && yearMatch.index !== undefined) {
        year = parseInt(dateStr.substr(yearMatch.index, 4));
      }
      if (monthMatch && monthMatch.index !== undefined) {
        month = parseInt(dateStr.substr(monthMatch.index, 2)) - 1; // 月份从0开始
      }
      if (dayMatch && dayMatch.index !== undefined) {
        day = parseInt(dateStr.substr(dayMatch.index, 2));
      }

      // 提取时分秒
      if (hourMatch && hourMatch.index !== undefined) {
        hour = parseInt(dateStr.substr(hourMatch.index, 2));
      }
      if (minuteMatch && minuteMatch.index !== undefined) {
        minute = parseInt(dateStr.substr(minuteMatch.index, 2));
      }
      if (secondMatch && secondMatch.index !== undefined) {
        second = parseInt(dateStr.substr(secondMatch.index, 2));
      }

      const date = new Date(year, month, day, hour, minute, second);
      return isNaN(date.getTime()) ? null : date;
    } catch (error) {
      Logger.error(TAG, `Failed to parse date with format: ${error}`);
      return null;
    }
  }

  /**
   * 获取相对时间描述
   * @param date 日期对象或时间戳
   * @returns 相对时间描述
   */
  public static getRelativeTime(date: Date | number | string): string {
    try {
      const dateObj = DateUtil.parseDate(date);
      if (!dateObj) return '';

      const now = new Date();
      const diffMs = now.getTime() - dateObj.getTime();
      const diffSecs = Math.floor(diffMs / 1000);
      const diffMins = Math.floor(diffSecs / 60);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      if (diffSecs < 60) {
        return '刚刚';
      } else if (diffMins < 60) {
        return `${diffMins}分钟前`;
      } else if (diffHours < 24) {
        return `${diffHours}小时前`;
      } else if (diffDays < 7) {
        return `${diffDays}天前`;
      } else if (diffDays < 30) {
        const weeks = Math.floor(diffDays / 7);
        return `${weeks}周前`;
      } else if (diffDays < 365) {
        const months = Math.floor(diffDays / 30);
        return `${months}个月前`;
      } else {
        const years = Math.floor(diffDays / 365);
        return `${years}年前`;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get relative time: ${error}`);
      return '';
    }
  }

  /**
   * 添加时间间隔
   * @param date 日期对象或时间戳
   * @param amount 时间数量
   * @param unit 时间单位
   * @returns 新的日期对象
   */
  public static add(date: Date | number | string, amount: number, unit: 'year' | 'month' | 'day' | 'hour' | 'minute' | 'second'): Date {
    try {
      const dateObj = DateUtil.parseDate(date);
      if (!dateObj) throw new Error('Invalid date');

      const result = new Date(dateObj.getTime());

      switch (unit) {
        case 'year':
          result.setFullYear(result.getFullYear() + amount);
          break;
        case 'month':
          result.setMonth(result.getMonth() + amount);
          break;
        case 'day':
          result.setDate(result.getDate() + amount);
          break;
        case 'hour':
          result.setHours(result.getHours() + amount);
          break;
        case 'minute':
          result.setMinutes(result.getMinutes() + amount);
          break;
        case 'second':
          result.setSeconds(result.getSeconds() + amount);
          break;
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to add time: ${error}`);
      throw error;
    }
  }

  /**
   * 比较两个日期
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 1:date1>date2, -1:date1<date2, 0:相等
   */
  public static compare(date1: Date | number | string, date2: Date | number | string): number {
    try {
      const d1 = DateUtil.parseDate(date1);
      const d2 = DateUtil.parseDate(date2);

      if (!d1 || !d2) throw new Error('Invalid date');

      const time1 = d1.getTime();
      const time2 = d2.getTime();

      if (time1 > time2) return 1;
      if (time1 < time2) return -1;
      return 0;
    } catch (error) {
      Logger.error(TAG, `Failed to compare dates: ${error}`);
      throw error;
    }
  }

  /**
   * 获取两个日期之间的差值
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @param unit 时间单位
   * @returns 差值
   */
  public static diff(date1: Date | number | string, date2: Date | number | string, unit: 'year' | 'month' | 'day' | 'hour' | 'minute' | 'second'): number {
    try {
      const d1 = DateUtil.parseDate(date1);
      const d2 = DateUtil.parseDate(date2);

      if (!d1 || !d2) throw new Error('Invalid date');

      const diffMs = Math.abs(d1.getTime() - d2.getTime());

      switch (unit) {
        case 'year':
          return Math.floor(diffMs / (1000 * 60 * 60 * 24 * 365));
        case 'month':
          return Math.floor(diffMs / (1000 * 60 * 60 * 24 * 30));
        case 'day':
          return Math.floor(diffMs / (1000 * 60 * 60 * 24));
        case 'hour':
          return Math.floor(diffMs / (1000 * 60 * 60));
        case 'minute':
          return Math.floor(diffMs / (1000 * 60));
        case 'second':
          return Math.floor(diffMs / 1000);
        default:
          return 0;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to calculate date difference: ${error}`);
      throw error;
    }
  }

  /**
   * 判断日期是否为今天
   * @param date 日期对象或时间戳
   * @returns 是否为今天
   */
  public static isToday(date: Date | number | string): boolean {
    try {
      const dateObj = DateUtil.parseDate(date);
      if (!dateObj) return false;

      const today = new Date();
      return dateObj.toDateString() === today.toDateString();
    } catch (error) {
      Logger.error(TAG, `Failed to check if date is today: ${error}`);
      return false;
    }
  }

  /**
   * 判断日期是否为昨天
   * @param date 日期对象或时间戳
   * @returns 是否为昨天
   */
  public static isYesterday(date: Date | number | string): boolean {
    try {
      const dateObj = DateUtil.parseDate(date);
      if (!dateObj) return false;

      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      return dateObj.toDateString() === yesterday.toDateString();
    } catch (error) {
      Logger.error(TAG, `Failed to check if date is yesterday: ${error}`);
      return false;
    }
  }

  /**
   * 判断日期是否在指定范围内
   * @param date 要检查的日期
   * @param start 开始日期
   * @param end 结束日期
   * @returns 是否在范围内
   */
  public static isBetween(date: Date | number | string, start: Date | number | string, end: Date | number | string): boolean {
    try {
      const dateObj = DateUtil.parseDate(date);
      const startObj = DateUtil.parseDate(start);
      const endObj = DateUtil.parseDate(end);
      if (!dateObj || !startObj || !endObj) return false;

      return DateUtil.compare(dateObj, startObj) >= 0 && DateUtil.compare(dateObj, endObj) <= 0;
    } catch (error) {
      Logger.error(TAG, `Failed to check if date is between range: ${error}`);
      return false;
    }
  }

  /**
   * 获取指定月份的天数
   * @param year 年份
   * @param month 月份（1-12）
   * @returns 天数
   */
  public static getDaysInMonth(year: number, month: number): number {
    try {
      return new Date(year, month, 0).getDate();
    } catch (error) {
      Logger.error(TAG, `Failed to get days in month: ${error}`);
      return 0;
    }
  }

  /**
   * 获取时间戳（秒）
   * @param date 日期对象（可选）
   * @returns 时间戳（秒）
   */
  public static getTimestamp(date?: Date): number {
    return Math.floor((date ? date.getTime() : Date.now()) / 1000);
  }

  /**
   * 获取毫秒时间戳
   * @param date 日期对象（可选）
   * @returns 毫秒时间戳
   */
  public static getMillisecondTimestamp(date?: Date): number {
    return date ? date.getTime() : Date.now();
  }

  /**
   * 格式化持续时间（秒）
   * @param seconds 秒数
   * @returns 格式化的持续时间
   */
  public static formatDuration(seconds: number): string {
    try {
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const secs = Math.floor(seconds % 60);
      if (hours > 0) {
        return `${hours}:${DateUtil.padZero(minutes)}:${DateUtil.padZero(secs)}`;
      } else {
        return `${minutes}:${DateUtil.padZero(secs)}`;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to format duration: ${error}`);
      return '0:00';
    }
  }

  /**
   * 解析持续时间字符串
   * @param durationStr 持续时间字符串（如 "1:30:45" 或 "45:30"）
   * @returns 总秒数
   */
  public static parseDuration(durationStr: string): number {
    try {
      const parts = durationStr.split(':').map(p => parseInt(p));
      
      if (parts.length === 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
      } else if (parts.length === 2) {
        return parts[0] * 60 + parts[1];
      } else {
        throw new Error('Invalid duration format');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to parse duration: ${error}`);
      return 0;
    }
  }

  // 工具方法：数字补零
  private static padZero(num: number): string {
    return num < 10 ? `0${num}` : num.toString();
  }

  // 工具方法：解析日期
  private static parseDate(date: Date | number | string): Date | null {
    if (date instanceof Date) {
      return isNaN(date.getTime()) ? null : date;
    } else if (typeof date === 'number') {
      const d = new Date(date);
      return isNaN(d.getTime()) ? null : d;
    } else if (typeof date === 'string') {
      return this.parse(date);
    }
    return null;
  }
}