// FormatUtil - 格式化工具类
// 提供数据格式化相关的工具函数，包括时间、数字、字符串等的格式化

import Logger from '../common/util/Logger';

/**
 * 格式化工具类
 */
export class FormatUtil {
  private static instance: FormatUtil;
  private logger = Logger.getInstance();

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('FormatUtil initialized');
  }

  /**
   * 获取FormatUtil单例实例
   */
  public static getInstance(): FormatUtil {
    if (!FormatUtil.instance) {
      FormatUtil.instance = new FormatUtil();
    }
    return FormatUtil.instance;
  }

  /**
   * 格式化时间戳为日期字符串
   * @param timestamp 时间戳
   * @param format 格式化模式
   */
  public formatDate(timestamp: number | Date, format: string = 'YYYY-MM-DD'): string {
    try {
      const date = typeof timestamp === 'number' ? new Date(timestamp) : timestamp;
      
      if (isNaN(date.getTime())) {
        throw new Error('Invalid date');
      }

      const year = date.getFullYear().toString();
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');
      const hours = date.getHours().toString().padStart(2, '0');
      const minutes = date.getMinutes().toString().padStart(2, '0');
      const seconds = date.getSeconds().toString().padStart(2, '0');

      return format
        .replace('YYYY', year)
        .replace('YY', year.slice(2))
        .replace('MM', month)
        .replace('M', (date.getMonth() + 1).toString())
        .replace('DD', day)
        .replace('D', date.getDate().toString())
        .replace('HH', hours)
        .replace('H', date.getHours().toString())
        .replace('mm', minutes)
        .replace('m', date.getMinutes().toString())
        .replace('ss', seconds)
        .replace('s', date.getSeconds().toString());
    } catch (error) {
      this.logger.error('Failed to format date', error as Error);
      return '';
    }
  }

  /**
   * 格式化持续时间（秒）为可读字符串
   * @param seconds 秒数
   * @param format 格式化模式 (short/long)
   */
  public formatDuration(seconds: number, format: 'short' | 'long' = 'short'): string {
    try {
      if (seconds < 0 || isNaN(seconds)) {
        return '0:00';
      }

      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const remainingSeconds = Math.floor(seconds % 60);

      if (format === 'long') {
        const parts = [];
        if (hours > 0) {
          parts.push(`${hours} ${hours === 1 ? 'hour' : 'hours'}`);
        }
        if (minutes > 0) {
          parts.push(`${minutes} ${minutes === 1 ? 'minute' : 'minutes'}`);
        }
        if (remainingSeconds > 0 || parts.length === 0) {
          parts.push(`${remainingSeconds} ${remainingSeconds === 1 ? 'second' : 'seconds'}`);
        }
        return parts.join(' ');
      } else {
        // 短格式：00:00:00 或 00:00
        if (hours > 0) {
          return `${hours}:${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
        } else {
          return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
        }
      }
    } catch (error) {
      this.logger.error('Failed to format duration', error as Error);
      return '0:00';
    }
  }

  /**
   * 格式化数字（添加千位分隔符等）
   * @param number 数字
   * @param decimals 小数位数
   * @param useCommas 是否使用逗号分隔
   */
  public formatNumber(number: number, decimals: number = 0, useCommas: boolean = true): string {
    try {
      if (isNaN(number)) {
        return '0';
      }

      let formatted = number.toFixed(decimals);

      if (useCommas) {
        // 分离整数和小数部分
        const parts = formatted.split('.');
        // 为整数部分添加千位分隔符
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        // 重新组合
        formatted = parts.join('.');
      }

      return formatted;
    } catch (error) {
      this.logger.error('Failed to format number', error as Error);
      return '0';
    }
  }

  /**
   * 格式化大数字（转换为K、M、B等单位）
   * @param number 数字
   * @param decimals 小数位数
   */
  public formatLargeNumber(number: number, decimals: number = 1): string {
    try {
      if (isNaN(number)) {
        return '0';
      }

      const absNumber = Math.abs(number);
      const sign = number < 0 ? '-' : '';

      if (absNumber >= 1e12) {
        return sign + (number / 1e12).toFixed(decimals) + 'T';
      } else if (absNumber >= 1e9) {
        return sign + (number / 1e9).toFixed(decimals) + 'B';
      } else if (absNumber >= 1e6) {
        return sign + (number / 1e6).toFixed(decimals) + 'M';
      } else if (absNumber >= 1e3) {
        return sign + (number / 1e3).toFixed(decimals) + 'K';
      } else {
        return sign + number.toString();
      }
    } catch (error) {
      this.logger.error('Failed to format large number', error as Error);
      return '0';
    }
  }

  /**
   * 格式化文件大小
   * @param bytes 字节数
   * @param decimals 小数位数
   */
  public formatFileSize(bytes: number, decimals: number = 2): string {
    try {
      if (bytes === 0 || isNaN(bytes)) {
        return '0 Bytes';
      }

      const k = 1024;
      const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
      const i = Math.floor(Math.log(bytes) / Math.log(k));

      return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
    } catch (error) {
      this.logger.error('Failed to format file size', error as Error);
      return '0 Bytes';
    }
  }

  /**
   * 格式化百分比
   * @param value 值（0-1）
   * @param decimals 小数位数
   * @param includeSymbol 是否包含百分号
   */
  public formatPercentage(value: number, decimals: number = 0, includeSymbol: boolean = true): string {
    try {
      if (isNaN(value)) {
        return includeSymbol ? '0%' : '0';
      }

      const percentage = Math.max(0, Math.min(100, value * 100));
      const formatted = percentage.toFixed(decimals);

      return includeSymbol ? `${formatted}%` : formatted;
    } catch (error) {
      this.logger.error('Failed to format percentage', error as Error);
      return includeSymbol ? '0%' : '0';
    }
  }

  /**
   * 格式化视频分辨率
   * @param width 宽度
   * @param height 高度
   */
  public formatResolution(width: number, height: number): string {
    try {
      if (isNaN(width) || isNaN(height) || width <= 0 || height <= 0) {
        return 'Unknown';
      }

      // 定义常见分辨率名称
      const resolutions: Array<{ name: string; minWidth: number; minHeight: number }> = [
        { name: 'SD', minWidth: 0, minHeight: 0 },
        { name: 'HD', minWidth: 1280, minHeight: 720 },
        { name: 'Full HD', minWidth: 1920, minHeight: 1080 },
        { name: '2K', minWidth: 2048, minHeight: 1080 },
        { name: '4K', minWidth: 3840, minHeight: 2160 },
        { name: '8K', minWidth: 7680, minHeight: 4320 }
      ];

      // 找到匹配的分辨率名称
      let resolutionName = `${width}x${height}`;
      for (let i = resolutions.length - 1; i >= 0; i--) {
        const res = resolutions[i];
        if (width >= res.minWidth && height >= res.minHeight) {
          resolutionName = res.name;
          break;
        }
      }

      return resolutionName;
    } catch (error) {
      this.logger.error('Failed to format resolution', error as Error);
      return 'Unknown';
    }
  }

  /**
   * 格式化视频帧率
   * @param fps 帧率
   */
  public formatFrameRate(fps: number): string {
    try {
      if (isNaN(fps) || fps <= 0) {
        return 'Unknown';
      }

      // 常见帧率标准
      if (fps === 23.976 || fps === 24) {
        return '24 FPS';
      } else if (fps === 25) {
        return '25 FPS';
      } else if (fps === 29.97 || fps === 30) {
        return '30 FPS';
      } else if (fps === 50) {
        return '50 FPS';
      } else if (fps === 59.94 || fps === 60) {
        return '60 FPS';
      } else if (fps === 119.88 || fps === 120) {
        return '120 FPS';
      } else {
        return `${fps.toFixed(1)} FPS`;
      }
    } catch (error) {
      this.logger.error('Failed to format frame rate', error as Error);
      return 'Unknown';
    }
  }

  /**
   * 格式化比特率
   * @param bitrate 比特率（bps）
   */
  public formatBitrate(bitrate: number): string {
    try {
      if (isNaN(bitrate) || bitrate < 0) {
        return 'Unknown';
      }

      if (bitrate >= 1e9) {
        return (bitrate / 1e9).toFixed(2) + ' Gbps';
      } else if (bitrate >= 1e6) {
        return (bitrate / 1e6).toFixed(2) + ' Mbps';
      } else if (bitrate >= 1e3) {
        return (bitrate / 1e3).toFixed(2) + ' Kbps';
      } else {
        return bitrate + ' bps';
      }
    } catch (error) {
      this.logger.error('Failed to format bitrate', error as Error);
      return 'Unknown';
    }
  }

  /**
   * 格式化语言代码
   * @param languageCode 语言代码（如 en-US, zh-CN）
   */
  public formatLanguage(languageCode: string): string {
    try {
      const languageMap: Record<string, string> = {
        'en': 'English',
        'en-US': 'English (US)',
        'en-GB': 'English (UK)',
        'zh': 'Chinese',
        'zh-CN': 'Chinese (Simplified)',
        'zh-TW': 'Chinese (Traditional)',
        'ja': 'Japanese',
        'ko': 'Korean',
        'es': 'Spanish',
        'es-ES': 'Spanish (Spain)',
        'fr': 'French',
        'de': 'German',
        'it': 'Italian',
        'ru': 'Russian',
        'pt': 'Portuguese',
        'pt-BR': 'Portuguese (Brazil)',
        'ar': 'Arabic',
        'hi': 'Hindi',
        'th': 'Thai',
        'vi': 'Vietnamese'
      };

      return languageMap[languageCode] || languageCode;
    } catch (error) {
      this.logger.error('Failed to format language', error as Error);
      return languageCode;
    }
  }

  /**
   * 格式化日期范围
   * @param startDate 开始日期
   * @param endDate 结束日期
   */
  public formatDateRange(startDate: Date | string | number, endDate: Date | string | number): string {
    try {
      const start = new Date(startDate);
      const end = new Date(endDate);

      if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        return '';
      }

      const startYear = start.getFullYear();
      const endYear = end.getFullYear();

      if (startYear === endYear) {
        // 同一年
        return `${startYear}`;
      } else if (endYear === new Date().getFullYear()) {
        // 结束年份是当前年，显示至今
        return `${startYear} - Present`;
      } else {
        // 不同年份
        return `${startYear} - ${endYear}`;
      }
    } catch (error) {
      this.logger.error('Failed to format date range', error as Error);
      return '';
    }
  }

  /**
   * 格式化搜索关键词（高亮等）
   * @param text 原始文本
   * @param keyword 关键词
   * @param highlight 是否高亮
   */
  public formatSearchKeyword(text: string, keyword: string, highlight: boolean = true): string {
    try {
      if (!text || !keyword) {
        return text || '';
      }

      if (!highlight) {
        return text;
      }

      // 创建正则表达式，忽略大小写
      const regex = new RegExp(`(${keyword})`, 'gi');
      // 替换匹配的关键词为高亮版本
      return text.replace(regex, '<mark>$1</mark>');
    } catch (error) {
      this.logger.error('Failed to format search keyword', error as Error);
      return text || '';
    }
  }

  /**
   * 格式化文件扩展名（大写）
   * @param extension 扩展名
   */
  public formatExtension(extension: string): string {
    try {
      return extension ? extension.toUpperCase().replace(/^\./, '') : '';
    } catch (error) {
      this.logger.error('Failed to format extension', error as Error);
      return '';
    }
  }

  /**
   * 格式化评分
   * @param score 评分值
   * @param maxScore 最大评分值
   * @param decimals 小数位数
   */
  public formatRating(score: number, maxScore: number = 10, decimals: number = 1): string {
    try {
      if (isNaN(score) || score < 0) {
        return '0';
      }

      const normalizedScore = Math.min(score, maxScore);
      return normalizedScore.toFixed(decimals);
    } catch (error) {
      this.logger.error('Failed to format rating', error as Error);
      return '0';
    }
  }

  /**
   * 格式化国家/地区代码
   * @param countryCode 国家/地区代码
   */
  public formatCountry(countryCode: string): string {
    try {
      const countryMap: Record<string, string> = {
        'US': 'United States',
        'CN': 'China',
        'JP': 'Japan',
        'KR': 'South Korea',
        'UK': 'United Kingdom',
        'FR': 'France',
        'DE': 'Germany',
        'IT': 'Italy',
        'ES': 'Spain',
        'RU': 'Russia',
        'BR': 'Brazil',
        'IN': 'India',
        'AU': 'Australia',
        'CA': 'Canada',
        'MX': 'Mexico',
        'TH': 'Thailand',
        'VN': 'Vietnam',
        'SG': 'Singapore',
        'HK': 'Hong Kong',
        'TW': 'Taiwan'
      };

      return countryMap[countryCode] || countryCode;
    } catch (error) {
      this.logger.error('Failed to format country', error as Error);
      return countryCode;
    }
  }

  /**
   * 格式化字符串首字母大写
   * @param text 文本
   * @param allWords 是否所有单词都首字母大写
   */
  public capitalize(text: string, allWords: boolean = false): string {
    try {
      if (!text) {
        return '';
      }

      if (allWords) {
        return text.toLowerCase().replace(/\b\w/g, (char) => char.toUpperCase());
      } else {
        return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
      }
    } catch (error) {
      this.logger.error('Failed to capitalize text', error as Error);
      return text || '';
    }
  }

  /**
   * 格式化错误消息
   * @param error 错误对象或消息
   */
  public formatErrorMessage(error: unknown): string {
    try {
      if (!error) {
        return 'Unknown error';
      }

      if (error instanceof Error) {
        return error.message || 'Unknown error';
      } else if (typeof error === 'string') {
        return error;
      } else if (error.message) {
        return error.message;
      } else {
        return String(error);
      }
    } catch (error) {
      this.logger.error('Failed to format error message', error as Error);
      return 'Unknown error';
    }
  }

  /**
   * 格式化文件路径（短路径显示）
   * @param path 文件路径
   * @param maxLength 最大长度
   */
  public formatPath(path: string, maxLength: number = 40): string {
    try {
      if (!path) {
        return '';
      }

      if (path.length <= maxLength) {
        return path;
      }

      const ellipsis = '...';
      const availableLength = maxLength - ellipsis.length;
      const firstPartLength = Math.floor(availableLength * 0.3);
      const lastPartLength = Math.ceil(availableLength * 0.7);

      return path.slice(0, firstPartLength) + ellipsis + path.slice(-lastPartLength);
    } catch (error) {
      this.logger.error('Failed to format path', error as Error);
      return path || '';
    }
  }

  /**
   * 格式化JSON字符串（美化）
   * @param json JSON字符串或对象
   * @param indent 缩进空格数
   */
  public formatJSON(json: string | object, indent: number = 2): string {
    try {
      let obj;
      if (typeof json === 'string') {
        obj = JSON.parse(json);
      } else {
        obj = json;
      }

      return JSON.stringify(obj, null, indent);
    } catch (error) {
      this.logger.error('Failed to format JSON', error as Error);
      return typeof json === 'string' ? json : '';
    }
  }

  /**
   * 格式化版本号
   * @param version 版本号
   */
  public formatVersion(version: string): string {
    try {
      if (!version) {
        return '0.0.0';
      }

      // 确保版本号格式正确
      const parts = version.split('.').map(p => parseInt(p, 10) || 0);
      while (parts.length < 3) {
        parts.push(0);
      }

      return parts.slice(0, 3).join('.');
    } catch (error) {
      this.logger.error('Failed to format version', error as Error);
      return '0.0.0';
    }
  }

  /**
   * 格式化播放次数
   * @param count 播放次数
   */
  public formatPlayCount(count: number): string {
    try {
      if (isNaN(count) || count < 0) {
        return '0';
      }

      if (count === 0) {
        return 'Never played';
      } else if (count === 1) {
        return 'Played once';
      } else if (count < 1000) {
        return `${count} plays`;
      } else {
        return this.formatLargeNumber(count) + ' plays';
      }
    } catch (error) {
      this.logger.error('Failed to format play count', error as Error);
      return '0';
    }
  }

  /**
   * 格式化相对时间
   * @param date 日期
   */
  public formatRelativeTime(date: Date | number | string): string {
    try {
      const now = new Date();
      const target = new Date(date);
      
      if (isNaN(target.getTime())) {
        return '';
      }

      const seconds = Math.floor((now.getTime() - target.getTime()) / 1000);

      if (seconds < 60) {
        return seconds === 0 ? 'Just now' : `${seconds} second${seconds > 1 ? 's' : ''} ago`;
      } else if (seconds < 3600) {
        const minutes = Math.floor(seconds / 60);
        return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
      } else if (seconds < 86400) {
        const hours = Math.floor(seconds / 3600);
        return `${hours} hour${hours > 1 ? 's' : ''} ago`;
      } else if (seconds < 604800) {
        const days = Math.floor(seconds / 86400);
        return `${days} day${days > 1 ? 's' : ''} ago`;
      } else if (seconds < 2592000) {
        const weeks = Math.floor(seconds / 604800);
        return `${weeks} week${weeks > 1 ? 's' : ''} ago`;
      } else if (seconds < 31536000) {
        const months = Math.floor(seconds / 2592000);
        return `${months} month${months > 1 ? 's' : ''} ago`;
      } else {
        const years = Math.floor(seconds / 31536000);
        return `${years} year${years > 1 ? 's' : ''} ago`;
      }
    } catch (error) {
      this.logger.error('Failed to format relative time', error as Error);
      return '';
    }
  }
}

// 导出默认实例
export default FormatUtil.getInstance();