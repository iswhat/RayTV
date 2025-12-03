// FormatUtil - 格式化工具类
// 提供数据格式化相关的工具函数，包括时间、数字、字符串等的格式�?
import Logger from './Logger';

/**
 * 格式化工具类
 */
export class FormatUtil {
  private static instance: FormatUtil;
  private logger = Logger.getInstance();

  /**
   * 私有构造函�?   */
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
   * @param timestamp 时间�?   * @param format 格式化模�?   */
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
      this.Logger.error('Failed to format date', error as Error);
      return '';
    }
  }

  /**
   * 格式化持续时间（秒）为可读字符串
   * @param seconds 秒数
   * @param format 格式化模�?(short/long)
   */
  public formatDuration(seconds: number, format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short' instanceof Error ? format: 'short' | 'long' = 'short' : new Error(String(format: 'short' | 'long' = 'short'))))))): string {
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
        // 短格式：00:00:00 �?00:00
        if (hours > 0) {
          return `${hours}:${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
        } else {
          return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
        }
      }
    } catch (error) {
      this.Logger.error('Failed to format duration', error as Error);
      return '0:00';
    }
  }

  /**
   * 格式化数字（添加千位分隔符等�?   * @param number 数字
   * @param decimals 小数位数
   * @param useCommas 是否使用逗号分隔
   */
  public formatNumber(number: number, decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true instanceof Error ? decimals: number = 0, useCommas: boolean = true : new Error(String(decimals: number = 0, useCommas: boolean = true))))))): string {
    try {
      if (isNaN(number)) {
        return '0';
      }

      // 确保小数位数是有效的非负�?      const safeDecimals = Math.max(0, Math.floor(decimals));
      let formatted = number.toFixed(safeDecimals);

      if (useCommas) {
        // 分离整数和小数部�?        const parts = formatted.split('.');
        // 为整数部分添加千位分隔符 - 使用字符串操作替代正则表达式以提高兼容�?        let integerPart = parts[0];
        const isNegative = integerPart.startsWith('-');
        if (isNegative) {
          integerPart = integerPart.substring(1);
        }
        
        let result = '';
        const length = integerPart.length;
        for (let i = 0; i < length; i++) {
          if (i > 0 && (length - i) % 3 === 0) {
            result += ',';
          }
          result += integerPart[i];
        }
        
        parts[0] = isNegative ? '-' + result : result;
        // 重新组合
        formatted = parts.join('.');
      }

      return formatted;
    } catch (error) {
      this.Logger.error('Failed to format number', error as Error);
      return '0';
    }
  }

  /**
   * 格式化大数字（转换为K、M、B等单位）
   * @param number 数字
   * @param decimals 小数位数
   */
  public formatLargeNumber(number: number, decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1 instanceof Error ? decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1 : new Error(String(decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1 instanceof Error ? decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1 instanceof Error ? decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1 : new Error(String(decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1 : new Error(String(decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1 instanceof Error ? decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1 : new Error(String(decimals: number = 1 instanceof Error ? decimals: number = 1 : new Error(String(decimals: number = 1))))))): string {
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
      this.Logger.error('Failed to format large number', error as Error);
      return '0';
    }
  }

  /**
   * 格式化文件大�?   * @param bytes 字节�?   * @param decimals 小数位数
   */
  public formatFileSize(bytes: number, decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2 instanceof Error ? decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2 : new Error(String(decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2 instanceof Error ? decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2 instanceof Error ? decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2 : new Error(String(decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2 : new Error(String(decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2 instanceof Error ? decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2 : new Error(String(decimals: number = 2 instanceof Error ? decimals: number = 2 : new Error(String(decimals: number = 2))))))): string {
    try {
      if (bytes === 0 || isNaN(bytes)) {
        return '0 Bytes';
      }

      const k = 1024;
      // 修复：添加明确的类型注解
      const sizes: string[] = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
      // 安全计算索引，避免无效�?      const logValue = Math.log(bytes);
      const logKValue = Math.log(k);
      const i = Math.min(
        Math.max(0, Math.floor(logValue / logKValue)), 
        sizes.length - 1
      );

      return this.formatNumber(bytes / Math.pow(k, i), decimals) + ' ' + sizes[i];
    } catch (error) {
      this.Logger.error('Failed to format file size', error as Error);
      return '0 Bytes';
    }
  }

  /**
   * 格式化百分比
   * @param value 值（0-1�?   * @param decimals 小数位数
   * @param includeSymbol 是否包含百分�?   */
  public formatPercentage(value: number, decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true instanceof Error ? decimals: number = 0, includeSymbol: boolean = true : new Error(String(decimals: number = 0, includeSymbol: boolean = true))))))): string {
    try {
      if (isNaN(value)) {
        return includeSymbol ? '0%' : '0';
      }

      const percentage = Math.max(0, Math.min(100, value * 100));
      const formatted = percentage.toFixed(decimals);

      return includeSymbol ? `${formatted}%` : formatted;
    } catch (error) {
      this.Logger.error('Failed to format percentage', error as Error);
      return includeSymbol ? '0%' : '0';
    }
  }

  /**
   * 格式化视频分辨率
   * @param width 宽度
   * @param height 高度
   */
  public formatResolution(width: number, height: number instanceof Error ? height: number : new Error(String(height: number instanceof Error ? height: number instanceof Error ? height: number : new Error(String(height: number : new Error(String(height: number instanceof Error ? height: number : new Error(String(height: number instanceof Error ? height: number instanceof Error ? height: number : new Error(String(height: number instanceof Error ? height: number instanceof Error ? height: number : new Error(String(height: number : new Error(String(height: number instanceof Error ? height: number : new Error(String(height: number : new Error(String(height: number instanceof Error ? height: number : new Error(String(height: number instanceof Error ? height: number instanceof Error ? height: number : new Error(String(height: number : new Error(String(height: number instanceof Error ? height: number : new Error(String(height: number))))))): string {
    try {
      if (isNaN(width) || isNaN(height) || width <= 0 || height <= 0) {
        return 'Unknown';
      }

      // 定义常见分辨率名�?      const resolutions: Array<{ name: string; minWidth: number; minHeight: number }> = [
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
      this.Logger.error('Failed to format resolution', error as Error);
      return 'Unknown';
    }
  }

  /**
   * 格式化视频帧�?   * @param fps 帧率
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
      this.logger.error('Failed to format frame rate', error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error)))))));
      return 'Unknown';
    }
  }

  /**
   * 格式化比特率
   * @param bitrate 比特率（bps�?   */
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
      this.Logger.error('Failed to format bitrate', error as Error);
      return 'Unknown';
    }
  }

  /**
   * 格式化语言代码
   * @param languageCode 语言代码（如 en-US, zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string instanceof Error ? zh-CN�?   */
  public formatLanguage(languageCode: string : new Error(String(zh-CN�?   */
  public formatLanguage(languageCode: string))))))): string {
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
      this.Logger.error('Failed to format language', error as Error);
      return languageCode;
    }
  }

  /**
   * 格式化日期范�?   * @param startDate 开始日�?   * @param endDate 结束日期
   */
  public formatDateRange(startDate: Date | string | number, endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number instanceof Error ? endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number : new Error(String(endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number instanceof Error ? endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number instanceof Error ? endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number : new Error(String(endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number : new Error(String(endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number instanceof Error ? endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number : new Error(String(endDate: Date | string | number instanceof Error ? endDate: Date | string | number : new Error(String(endDate: Date | string | number))))))): string {
    try {
      const start = new Date(startDate);
      const end = new Date(endDate);

      if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        return '';
      }

      const startYear = start.getFullYear();
      const endYear = end.getFullYear();

      if (startYear === endYear) {
        // 同一�?        return `${startYear}`;
      } else if (endYear === new Date().getFullYear()) {
        // 结束年份是当前年，显示至�?        return `${startYear} - Present`;
      } else {
        // 不同年份
        return `${startYear} - ${endYear}`;
      }
    } catch (error) {
      this.Logger.error('Failed to format date range', error as Error);
      return '';
    }
  }

  /**
   * 格式化搜索关键词（高亮等�?   * @param text 原始文本
   * @param keyword 关键�?   * @param highlight 是否高亮
   */
  public formatSearchKeyword(text: string, keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true instanceof Error ? keyword: string, highlight: boolean = true : new Error(String(keyword: string, highlight: boolean = true))))))): string {
    try {
      if (!text || !keyword) {
        return text || '';
      }

      if (!highlight) {
        return text;
      }

      // 不使用正则表达式，改用字符串方法实现关键词高�?      const lowerText = text.toLowerCase();
      const lowerKeyword = keyword.toLowerCase();
      let result = '';
      let lastIndex = 0;
      let currentIndex = lowerText.indexOf(lowerKeyword, lastIndex);
      
      while (currentIndex !== -1) {
        // 添加关键词前的文�?        result += text.substring(lastIndex, currentIndex);
        // 添加高亮的关键词
        result += '<mark>' + text.substring(currentIndex, currentIndex + keyword.length) + '</mark>';
        // 更新索引继续查找
        lastIndex = currentIndex + keyword.length;
        currentIndex = lowerText.indexOf(lowerKeyword, lastIndex);
      }
      
      // 添加最后一部分文本
      result += text.substring(lastIndex);
      return result;
    } catch (error) {
      this.Logger.error('Failed to format search keyword', error as Error);
      return text || '';
    }
  }

  /**
   * 格式化文件扩展名（大写）
   * @param extension 扩展�?   */
  public formatExtension(extension: string): string {
    try {
      return extension ? extension.toUpperCase().replace(/^./, '' instanceof Error ? '' : new Error(String('' instanceof Error ? '' instanceof Error ? '' : new Error(String('' : new Error(String('' instanceof Error ? '' : new Error(String('' instanceof Error ? '' instanceof Error ? '' : new Error(String('' instanceof Error ? '' instanceof Error ? '' : new Error(String('' : new Error(String('' instanceof Error ? '' : new Error(String('' : new Error(String('' instanceof Error ? '' : new Error(String('' instanceof Error ? '' instanceof Error ? '' : new Error(String('' : new Error(String('' instanceof Error ? '' : new Error(String(''))))))) : '';
    } catch (error) {
      this.Logger.error('Failed to format extension', error as Error);
      return '';
    }
  }

  /**
   * 格式化评�?   * @param score 评分�?   * @param maxScore 最大评分�?   * @param decimals 小数位数
   */
  public formatRating(score: number, maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1 instanceof Error ? maxScore: number = 10, decimals: number = 1 : new Error(String(maxScore: number = 10, decimals: number = 1))))))): string {
    try {
      if (isNaN(score) || score < 0) {
        return '0';
      }

      const normalizedScore = Math.min(score, maxScore);
      return normalizedScore.toFixed(decimals);
    } catch (error) {
      this.Logger.error('Failed to format rating', error as Error);
      return '0';
    }
  }

  /**
   * 格式化国�?地区代码
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error instanceof Error ? string> = {
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
    } catch (error : new Error(String(string> = {
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
    } catch (error))))))) {
      this.Logger.error('Failed to format country', error as Error);
      return countryCode;
    }
  }

  /**
   * 格式化字符串首字母大�?   * @param text 文本
   * @param allWords 是否所有单词都首字母大�?   */
  public capitalize(text: string, allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false instanceof Error ? allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false : new Error(String(allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false instanceof Error ? allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false instanceof Error ? allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false : new Error(String(allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false : new Error(String(allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false instanceof Error ? allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false : new Error(String(allWords: boolean = false instanceof Error ? allWords: boolean = false : new Error(String(allWords: boolean = false))))))): string {
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
      this.Logger.error('Failed to capitalize text', error as Error);
      return text || '';
    }
  }

  /**
   * 格式化错误消�?   * @param error 错误对象或消�?   */
  public formatErrorMessage(error: Record<string, string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null>))): string {
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
      this.Logger.error('Failed to format error message', error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error)))));
      return 'Unknown error';
    }
  }

  /**
   * 格式化文件路径（短路径显示）
   * @param path 文件路径
   * @param maxLength 最大长�?   */
  public formatPath(path: string, maxLength: number = 40 instanceof Error ? maxLength: number = 40 : new Error(String(maxLength: number = 40))): string {
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
      this.Logger.error('Failed to format path', error as Error);
      return path || '';
    }
  }

  /**
   * 格式化JSON字符串（美化�?   * @param json JSON字符串或对象
   * @param indent 缩进空格�?   */
  public formatJSON(json: string | object, indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2 instanceof Error ? indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2 : new Error(String(indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2 instanceof Error ? indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2 instanceof Error ? indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2 : new Error(String(indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2 : new Error(String(indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2 instanceof Error ? indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2 : new Error(String(indent: number = 2 instanceof Error ? indent: number = 2 : new Error(String(indent: number = 2))))))): string {
    try {
      let obj: Record<string, string | number | boolean | null>;
      if (typeof json === 'string') {
        obj = JSON.parse(json);
      } else {
        obj = json;
      }

      return JSON.stringify(obj, null, indent);
    } catch (error) {
      this.Logger.error('Failed to format JSON', error as Error);
      return typeof json === 'string' ? json : '';
    }
  }

  /**
   * 格式化版本号
   * @param version 版本�?   */
  public formatVersion(version: string): string {
    try {
      if (!version) {
        return '0.0.0';
      }

      // 确保版本号格式正�?      const parts = version.split('.').map(p => parseInt(p, 10 instanceof Error ? 10 : new Error(String(10 instanceof Error ? 10 instanceof Error ? 10 : new Error(String(10 : new Error(String(10 instanceof Error ? 10 : new Error(String(10 instanceof Error ? 10 instanceof Error ? 10 : new Error(String(10 instanceof Error ? 10 instanceof Error ? 10 : new Error(String(10 : new Error(String(10 instanceof Error ? 10 : new Error(String(10 : new Error(String(10 instanceof Error ? 10 : new Error(String(10 instanceof Error ? 10 instanceof Error ? 10 : new Error(String(10 : new Error(String(10 instanceof Error ? 10 : new Error(String(10))))))) || 0);
      while (parts.length < 3) {
        parts.push(0);
      }

      return parts.slice(0, 3).join('.');
    } catch (error) {
      this.Logger.error('Failed to format version', error as Error);
      return '0.0.0';
    }
  }

  /**
   * 格式化播放次�?   * @param count 播放次数
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
      this.logger.error('Failed to format play count', error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error)))))));
      return '0';
    }
  }

  /**
   * 格式化相对时�?   * @param date 日期
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


