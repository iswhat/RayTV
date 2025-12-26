// Logger - 简化的日志工具
// 提供统一的日志记录功能，只接受字符串参数以避免类型检查错误

export enum LogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARN = 'warn',
  ERROR = 'error',
  FATAL = 'fatal',
  OFF = 'off'
}

export interface LoggerExtraData {
  message?: string;
  code?: number;
  detail?: Record<string, string | number | boolean | null> | string | number | boolean | null;
  tag?: string;
  error?: Error;
}

/**
 * 日志工具类
 */
export class Logger {
  private static level: LogLevel = LogLevel.INFO;

  private constructor() {
    // 初始化
  }

  // 静态方法
  public static debug(message: string): void {
    if (Logger.shouldLog(LogLevel.DEBUG)) {
      console.debug(message);
    }
  }

  public static info(message: string): void {
    if (Logger.shouldLog(LogLevel.INFO)) {
      console.info(message);
    }
  }

  public static warn(message: string): void {
    if (Logger.shouldLog(LogLevel.WARN)) {
      console.warn(message);
    }
  }

  public static error(message: string, error?: Error): void {
    if (Logger.shouldLog(LogLevel.ERROR)) {
      console.error(message);
      if (error) {
        console.error(error.message || JSON.stringify(error));
      }
    }
  }

  public static fatal(message: string, error?: Error): void {
    if (Logger.shouldLog(LogLevel.FATAL)) {
      console.error(message);
      if (error) {
        console.error(error.message || JSON.stringify(error));
      }
    }
  }

  private static shouldLog(level: LogLevel): boolean {
    const levelOrder = [LogLevel.DEBUG, LogLevel.INFO, LogLevel.WARN, LogLevel.ERROR, LogLevel.FATAL];
    const currentLevelIndex = levelOrder.indexOf(Logger.level);
    const targetLevelIndex = levelOrder.indexOf(level);
    return targetLevelIndex >= currentLevelIndex;
  }

  public static setLevel(level: LogLevel): void {
    Logger.level = level;
  }

  public static getLevel(): LogLevel {
    return Logger.level;
  }
}

// 静态方法包装器 - 直接导出Logger类作为默认导出，因为它已经是静态方法了
// 保留StaticLogger类以保持向后兼容性
class StaticLogger {
  private constructor() {
    // 私有构造函数，防止外部实例化
  }

  public static debug(tag: string, message: string): void {
    const formatted = `[${tag}] ${message}`;
    Logger.debug(formatted);
  }

  public static info(tag: string, message: string): void {
    const formatted = `[${tag}] ${message}`;
    Logger.info(formatted);
  }

  public static warn(tag: string, message: string): void {
    const formatted = `[${tag}] ${message}`;
    Logger.warn(formatted);
  }

  public static error(tag: string, message: string, error?: Error): void {
    const formatted = `[${tag}] ${message}`;
    Logger.error(formatted, error);
  }

  public static exception(tag: string, error: Error): void {
    const formatted = `[${tag}] ${error.message}`;
    Logger.error(formatted, error);
  }

  public static format(tag: string, format: string, ...args: (string | number | boolean | null | undefined)[]): void {
    let message = format;
    for (let i = 0; i < args.length; i++) {
      message = message.replace(`{${i}}`, String(args[i]));
    }
    StaticLogger.info(tag, message);
  }
}

// 导出StaticLogger作为默认导出，因为它提供了静态方法
export default StaticLogger;
export { Logger, StaticLogger }; // 保留原类导出，供需要时使用