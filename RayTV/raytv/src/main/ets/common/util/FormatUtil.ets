// FormatUtil - 格式化工具类 // Format Utility Class
// 提供数据格式化相关的工具函数，包括时间、数字、字符串等的格式化 // Provides data formatting utility functions, including time, number, string formatting, etc.
import Logger from './Logger';

/**
 * 格式化工具类 // Format Utility Class
 */
export class FormatUtil {
  private static instance: FormatUtil;
  private logger = Logger.getInstance();

  /**
   * 私有构造函数 // Private constructor
   */
  private constructor() {
    this.logger.info('FormatUtil initialized');
  }

  /**
   * 获取FormatUtil单例实例 // Get FormatUtil singleton instance
   */
  public static getInstance(): FormatUtil {
    if (!FormatUtil.instance) {
      FormatUtil.instance = new FormatUtil();
    }
    return FormatUtil.instance;
  }

  /**
   * 格式化时间戳为日期字符串 // Format timestamp to date string
   * @param timestamp 时间戳 // Timestamp
   * @param format 格式化格式 // Format pattern
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
   * 格式化持续时间（秒）为可读字符串 // Format duration (seconds) to readable string
   * @param seconds 秒数 // Seconds
   * @param format 格式化格式(short/long) // Format pattern (short/long)
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
        // 短格式: 00:00:00 或 00:00 // Short format: 00:00:00 or 00:00
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
   * 格式化数字（添加单位分隔符等）// Format number (add unit separators, etc.)
   * @param number 数字 // Number
   * @param decimals 小数位数 // Decimal places
   * @param useCommas 是否使用逗号分隔 // Whether to use commas for separation
   */
  public formatNumber(number: number, decimals: number = 0, useCommas: boolean = true): string {
    try {
      if (isNaN(number)) {
        return '0';
      }

      // 确保小数位数是有效的非负数 // Ensure decimal places is a valid non-negative number
      const safeDecimals = Math.max(0, Math.floor(decimals));
      let formatted = number.toFixed(safeDecimals);

      if (useCommas) {
        // 分离整数和小数部分 // Separate integer and decimal parts
        const parts = formatted.split('.');
        // 为整数部分添加千位分隔符 // Add thousand separators to integer part
        let integerPart = parts[0];
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
        // 重新组合 // Recombine
        formatted = parts.join('.');
      }

      return formatted;
    } catch (error) {
      this.logger.error('Failed to format number', error as Error);
      return '0';
    }
  }

  /**
   * 格式化大数字（转换为K、M、T等单位）// Format large number (convert to K, M, T units)
   * @param number 数字 // Number
   * @param decimals 小数位数 // Decimal places
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
   * 格式化文件大小 // Format file size
   * @param bytes 字节数 // Byte count
   * @param decimals 小数位数 // Decimal places
   */
  public formatFileSize(bytes: number, decimals: number = 2): string {
    try {
      if (bytes === 0 || isNaN(bytes)) {
        return '0 Bytes';
      }

      const k = 1024;
      const sizes: string[] = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
      const i = Math.min(
        Math.max(0, Math.floor(Math.log(bytes) / Math.log(k))), 
        sizes.length - 1
      );

      return this.formatNumber(bytes / Math.pow(k, i), decimals) + ' ' + sizes[i];
    } catch (error) {
      this.logger.error('Failed to format file size', error as Error);
      return '0 Bytes';
    }
  }

  /**
   * 格式化百分比 // Format percentage
   * @param value 值（0-1）// Value (0-1)
   * @param decimals 小数位数 // Decimal places
   * @param includeSymbol 是否包含百分号 // Whether to include percentage symbol
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
   * 格式化视频分辨率 // Format video resolution
   * @param width 宽度 // Width
   * @param height 高度 // Height
   */
  public formatResolution(width: number, height: number): string {
    try {
      if (isNaN(width) || isNaN(height) || width <= 0 || height <= 0) {
        return 'Unknown';
      }

      // 定义常见分辨率标准名称 // Define common resolution standard names
      const resolutions: Array<{ name: string; minWidth: number; minHeight: number }> = [
        { name: 'SD', minWidth: 0, minHeight: 0 },
        { name: 'HD', minWidth: 1280, minHeight: 720 },
        { name: 'Full HD', minWidth: 1920, minHeight: 1080 },
        { name: '2K', minWidth: 2048, minHeight: 1080 },
        { name: '4K', minWidth: 3840, minHeight: 2160 },
        { name: '8K', minWidth: 7680, minHeight: 4320 }
      ];

      // 找到匹配的分辨率名称 // Find matching resolution name
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
   * 格式化视频帧率 // Format video frame rate
   * @param fps 帧率 // Frame rate
   */
  public formatFrameRate(fps: number): string {
    try {
      if (isNaN(fps) || fps <= 0) {
        return 'Unknown';
      }

      // 常见帧率标准 // Common frame rate standards
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
   * 格式化比特率 // Format bitrate
   * @param bitrate 比特率（bps）// Bitrate (bps)
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
   * 格式化语言代码 // Format language code
   * @param languageCode 语言代码（如 en-US, zh-CN）// Language code (e.g., en-US, zh-CN)
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
   * 格式化日期范围 // Format date range
   * @param startDate 开始日期 // Start date
   * @param endDate 结束日期 // End date
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
        // 同一年 // Same year
        return `${startYear}`;
      } else if (endYear === new Date().getFullYear()) {
        // 结束年份是当前年，显示到现在 // End year is current year, show to present
        return `${startYear} - Present`;
      } else {
        // 不同年份 // Different years
        return `${startYear} - ${endYear}`;
      }
    } catch (error) {
      this.logger.error('Failed to format date range', error as Error);
      return '';
    }
  }

  /**
   * 格式化搜索关键词（高亮等）// Format search keyword (highlight, etc.)
   * @param text 原始文本 // Original text
   * @param keyword 关键词 // Keyword
   * @param highlight 是否高亮 // Whether to highlight
   */
  public formatSearchKeyword(text: string, keyword: string, highlight: boolean = true): string {
    try {
      if (!text || !keyword) {
        return text || '';
      }

      if (!highlight) {
        return text;
      }

      // 不使用正则表达式，改用字符串方法实现关键词高亮 // Use string methods instead of regex for keyword highlighting
      const lowerText = text.toLowerCase();
      const lowerKeyword = keyword.toLowerCase();
      let result = '';
      let lastIndex = 0;
      let currentIndex = lowerText.indexOf(lowerKeyword, lastIndex);
      
      while (currentIndex !== -1) {
        // 添加关键词前的文本 // Add text before keyword
        result += text.substring(lastIndex, currentIndex);
        // 添加高亮的关键词 // Add highlighted keyword
        result += '<mark>' + text.substring(currentIndex, currentIndex + keyword.length) + '</mark>';
        // 更新索引继续查找 // Update index to continue searching
        lastIndex = currentIndex + keyword.length;
        currentIndex = lowerText.indexOf(lowerKeyword, lastIndex);
      }
      
      // 添加最后一部分文本 // Add last part of text
      result += text.substring(lastIndex);
      return result;
    } catch (error) {
      this.logger.error('Failed to format search keyword', error as Error);
      return text || '';
    }
  }

  /**
   * 格式化文件扩展名（大写）// Format file extension (uppercase)
   * @param extension 扩展名 // Extension
   */
  public formatExtension(extension: string): string {
    try {
      return extension ? extension.toUpperCase() : '';
    } catch (error) {
      this.logger.error('Failed to format extension', error as Error);
      return '';
    }
  }

  /**
   * 格式化评分 // Format rating
   * @param score 评分值 // Score value
   * @param maxScore 最大评分值 // Maximum score value
   * @param decimals 小数位数 // Decimal places
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
   * 格式化国家/地区代码 // Format country/region code
   * @param countryCode 国家/地区代码 // Country/region code
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
   * 格式化字符串首字母大写 // Format string with capitalized first letter
   * @param text 文本 // Text
   * @param allWords 是否所有单词都首字母大写 // Whether to capitalize all words
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
   * 格式化错误消息 // Format error message
   * @param error 错误对象或消息 // Error object or message
   */
  public formatErrorMessage(error: any): string {
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
   * 格式化文件路径（短路径显示）// Format file path (short path display)
   * @param path 文件路径 // File path
   * @param maxLength 最大长度 // Maximum length
   */
  public formatPath(path: string, maxLength: number = 40): string {
    try {
      if (!path) {
        return '';
      }

      if (path.length <= maxLength) {
        return path;
      }

      // 保留开头和结尾，中间用省略号 // Keep start and end, use ellipsis in middle
      const startLength = Math.floor(maxLength * 0.3);
      const endLength = Math.floor(maxLength * 0.6);
      const ellipsis = '...';

      return path.substring(0, startLength) + ellipsis + path.substring(path.length - endLength);
    } catch (error) {
      this.logger.error('Failed to format path', error as Error);
      return path;
    }
  }
}

// 导出单例实例 // Export singleton instance
export default FormatUtil.getInstance();
