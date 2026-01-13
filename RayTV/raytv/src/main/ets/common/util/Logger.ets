/**
 * Logger - Logger utility class | 日志工具类
 * Provides unified logging functionality | 提供统一的日志记录功能
 */
import { hilog } from '@kit.ArkTS';

/**
 * Log level enum | 日志级别枚举
 */
export enum LogLevel {
  DEBUG = 3, // Debug | 调试
  INFO = 4, // Info | 信息
  WARN = 5, // Warn | 警告
  ERROR = 6 // Error | 错误
}

/**
 * Logger utility class | 日志工具类
 */
export default class Logger {
  private static readonly DEFAULT_TAG: string = 'RayTV';
  private static logLevel: LogLevel = LogLevel.DEBUG;
  private static isInitialized: boolean = false;

  /**
   * Initialize log configuration | 初始化日志配置
   * @param level Log level | 日志级别
   */
  public static initialize(level: LogLevel = LogLevel.DEBUG): void {
    Logger.logLevel = level;
    Logger.isInitialized = true;
    Logger.info(Logger.DEFAULT_TAG, 'Logger initialized with level:', LogLevel[level]);
  }

  /**
   * Set log level | 设置日志级别
   * @param level Log level | 日志级别
   */
  public static setLogLevel(level: LogLevel): void {
    Logger.logLevel = level;
    Logger.info(Logger.DEFAULT_TAG, 'Log level changed to:', LogLevel[level]);
  }

  /**
   * Get current log level | 获取当前日志级别
   * @returns Current log level | 当前日志级别
   */
  public static getLogLevel(): LogLevel {
    return Logger.logLevel;
  }

  /**
   * Debug log | 调试日志
   * @param tag Log tag | 日志标签
   * @param message Log message | 日志消息
   * @param error Error object (optional) | 错误对象（可选）
   */
  public static debug(tag: string, message: string, error?: Error): void {
    if (Logger.logLevel <= LogLevel.DEBUG) {
      Logger.log(LogLevel.DEBUG, tag, message, error);
    }
  }

  /**
   * Info log | 信息日志
   * @param tag Log tag | 日志标签
   * @param message Log message | 日志消息
   * @param error Error object (optional) | 错误对象（可选）
   */
  public static info(tag: string, message: string, error?: Error): void {
    if (Logger.logLevel <= LogLevel.INFO) {
      Logger.log(LogLevel.INFO, tag, message, error);
    }
  }

  /**
   * Warn log | 警告日志
   * @param tag Log tag | 日志标签
   * @param message Log message | 日志消息
   * @param error Error object (optional) | 错误对象（可选）
   */
  public static warn(tag: string, message: string, error?: Error): void {
    if (Logger.logLevel <= LogLevel.WARN) {
      Logger.log(LogLevel.WARN, tag, message, error);
    }
  }

  /**
   * Error log | 错误日志
   * @param tag Log tag | 日志标签
   * @param message Log message | 日志消息
   * @param error Error object (optional) | 错误对象（可选）
   */
  public static error(tag: string, message: string, error?: Error): void {
    if (Logger.logLevel <= LogLevel.ERROR) {
      Logger.log(LogLevel.ERROR, tag, message, error);
    }
  }

  /**
   * Format log message | 格式化日志消息
   * @param message Original message | 原始消息
   * @param error Error object (optional) | 错误对象（可选）
   * @returns Formatted message | 格式化后的消息
   */
  private static formatMessage(message: string, error?: Error): string {
    let formattedMessage = message;
    
    if (error) {
      formattedMessage += ` | Error: ${error.message}`;
      if (error.stack) {
        formattedMessage += ` | Stack: ${error.stack}`;
      }
    }
    
    return formattedMessage;
  }

  /**
   * Log message | 记录日志
   * @param level Log level | 日志级别
   * @param tag Log tag | 日志标签
   * @param message Log message | 日志消息
   * @param error Error object (optional) | 错误对象（可选）
   */
  private static log(level: LogLevel, tag: string, message: string, error?: Error): void {
    try {
      const finalTag = tag || Logger.DEFAULT_TAG;
      const formattedMessage = Logger.formatMessage(message, error);
      
      // Use system log service | 使用系统日志服务
      hilog.log(level, finalTag, 0x0000, formattedMessage);
      
      // In development mode, also output to console | 在开发模式下，同时输出到控制台
      if (process.env.NODE_ENV === 'development') {
        const consoleMethod = Logger.getConsoleMethod(level);
        consoleMethod(`${finalTag} [${LogLevel[level]}]: ${formattedMessage}`);
      }
    } catch (logError) {
      // Prevent log recording itself from error | 防止日志记录本身出错
      console.error(`Failed to log message: ${logError instanceof Error ? logError.message : String(logError)}`);
    }
  }

  /**
   * Get corresponding console method | 获取对应的控制台方法
   * @param level Log level | 日志级别
   * @returns Console method | 控制台方法
   */
  private static getConsoleMethod(level: LogLevel): Function {
    switch (level) {
      case LogLevel.DEBUG:
        return console.debug;
      case LogLevel.INFO:
        return console.info;
      case LogLevel.WARN:
        return console.warn;
      case LogLevel.ERROR:
        return console.error;
      default:
        return console.log;
    }
  }

  /**
   * Log performance | 记录性能日志
   * @param tag Log tag | 日志标签
   * @param operation Operation name | 操作名称
   * @param startTime Start time | 开始时间
   * @param endTime End time | 结束时间
   */
  public static performance(tag: string, operation: string, startTime: number, endTime: number): void {
    const duration = endTime - startTime;
    Logger.info(tag, `${operation} took ${duration}ms`);
  }

  /**
   * Log object | 记录对象日志
   * @param tag Log tag | 日志标签
   * @param message Log message | 日志消息
   * @param obj Object to log | 要记录的对象
   */
  public static object(tag: string, message: string, obj: Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>>): void {
    try {
      const objString = JSON.stringify(obj, null, 2);
      Logger.debug(tag, `${message}: ${objString}`);
    } catch (error) {
      Logger.error(tag, `Failed to stringify object for logging`, error instanceof Error ? error : new Error(String(error)));
    }
  }
}
