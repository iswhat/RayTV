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
class Logger {
  private static _instance: Logger | null = null;
  private level: LogLevel = LogLevel.INFO;

  private constructor() {
    // 初始化
  }

  public static getInstance(): Logger {
    if (!Logger._instance) {
      Logger._instance = new Logger();
    }
    return Logger._instance;
  }

  // 实例方法
  public debug(message: string): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      console.debug(message);
    }
  }

  public info(message: string): void {
    if (this.shouldLog(LogLevel.INFO)) {
      console.info(message);
    }
  }

  public warn(message: string): void {
    if (this.shouldLog(LogLevel.WARN)) {
      console.warn(message);
    }
  }

  public error(message: string, error?: Error): void {
    if (this.shouldLog(LogLevel.ERROR)) {
      console.error(message);
      if (error) {
        console.error(error.message || JSON.stringify(error));
      }
    }
  }

  public fatal(message: string, error?: Error): void {
    if (this.shouldLog(LogLevel.FATAL)) {
      console.error(message);
      if (error) {
        console.error(error.message || JSON.stringify(error));
      }
    }
  }

  private shouldLog(level: LogLevel): boolean {
    const levelOrder = [LogLevel.DEBUG, LogLevel.INFO, LogLevel.WARN, LogLevel.ERROR, LogLevel.FATAL];
    const currentLevelIndex = levelOrder.indexOf(this.level);
    const targetLevelIndex = levelOrder.indexOf(level);
    return targetLevelIndex >= currentLevelIndex;
  }

  public setLevel(level: LogLevel): void {
    this.level = level;
  }

  public getLevel(): LogLevel {
    return this.level;
  }
}

// 静态方法包装器
class StaticLogger {
  public static debug(tag: string, message: string): void {
    const formatted = `[${tag}] ${message}`;
    Logger.getInstance().debug(formatted);
  }

  public static info(tag: string, message: string): void {
    const formatted = `[${tag}] ${message}`;
    Logger.getInstance().info(formatted);
  }

  public static warn(tag: string, message: string): void {
    const formatted = `[${tag}] ${message}`;
    Logger.getInstance().warn(formatted);
  }

  public static error(tag: string, message: string, error?: Error): void {
    const formatted = `[${tag}] ${message}`;
    Logger.getInstance().error(formatted, error);
  }

  public static exception(tag: string, error: Error): void {
    const formatted = `[${tag}] ${error.message}`;
    Logger.getInstance().error(formatted, error);
  }

  public static format(tag: string, format: string, ...args: (string | number | boolean | null | undefined)[]): void {
    let message = format;
    for (let i = 0; i < args.length; i++) {
      message = message.replace(`{${i}}`, String(args[i]));
    }
    StaticLogger.info(tag, message);
  }
}

// 导出简化版Logger
export default StaticLogger;
export { Logger }; // 保留原类导出，供需要时使用