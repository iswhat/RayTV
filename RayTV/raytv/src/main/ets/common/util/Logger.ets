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
 * Logger接口定义
 */
export interface LoggerInterface {
  level: LogLevel;
  debug(message: string): void;
  info(message: string): void;
  warn(message: string): void;
  error(message: string, error?: Error): void;
  fatal(message: string, error?: Error): void;
  setLevel(level: LogLevel): void;
  getLevel(): LogLevel;
  shouldLog(level: LogLevel): boolean;
}

/**
 * LoggerUtil接口定义
 */
export interface LoggerUtilInterface {
  debug(tag: string, message: string): void;
  info(tag: string, message: string): void;
  warn(tag: string, message: string): void;
  error(tag: string, message: string, error?: Error): void;
  exception(tag: string, error: Error): void;
  format(tag: string, format: string, ...args: (string | number | boolean | null | undefined)[]): void;
}

/**
 * 日志工具对象
 */
const LoggerImpl: LoggerInterface = {
  level: LogLevel.INFO,
  
  shouldLog(level: LogLevel): boolean {
    const levelOrder = [LogLevel.DEBUG, LogLevel.INFO, LogLevel.WARN, LogLevel.ERROR, LogLevel.FATAL];
    const currentLevelIndex = levelOrder.indexOf(this.level);
    const targetLevelIndex = levelOrder.indexOf(level);
    return targetLevelIndex >= currentLevelIndex;
  },

  debug(message: string): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      console.debug(message);
    }
  },

  info(message: string): void {
    if (this.shouldLog(LogLevel.INFO)) {
      console.info(message);
    }
  },

  warn(message: string): void {
    if (this.shouldLog(LogLevel.WARN)) {
      console.warn(message);
    }
  },

  error(message: string, error?: Error): void {
    if (this.shouldLog(LogLevel.ERROR)) {
      console.error(message);
      if (error) {
        console.error(error.message || JSON.stringify(error));
      }
    }
  },

  fatal(message: string, error?: Error): void {
    if (this.shouldLog(LogLevel.FATAL)) {
      console.error(message);
      if (error) {
        console.error(error.message || JSON.stringify(error));
      }
    }
  },

  setLevel(level: LogLevel): void {
    this.level = level;
  },

  getLevel(): LogLevel {
    return this.level;
  }
};

// 日志工具对象，提供带tag的日志方法
const LoggerUtilImpl: LoggerUtilInterface = {
  debug: (tag: string, message: string): void => {
    const formatted = `[${tag}] ${message}`;
    LoggerImpl.debug(formatted);
  },

  info: (tag: string, message: string): void => {
    const formatted = `[${tag}] ${message}`;
    LoggerImpl.info(formatted);
  },

  warn: (tag: string, message: string): void => {
    const formatted = `[${tag}] ${message}`;
    LoggerImpl.warn(formatted);
  },

  error: (tag: string, message: string, error?: Error): void => {
    const formatted = `[${tag}] ${message}`;
    LoggerImpl.error(formatted, error);
  },

  exception: (tag: string, error: Error): void => {
    const formatted = `[${tag}] ${error.message}`;
    LoggerImpl.error(formatted, error);
  },

  format: (tag: string, format: string, ...args: (string | number | boolean | null | undefined)[]): void => {
    let message = format;
    for (let i = 0; i < args.length; i++) {
      message = message.replace(`{${i}}`, String(args[i]));
    }
    LoggerUtilImpl.info(tag, message);
  }
};

// 导出Logger和LoggerUtil
export const Logger = LoggerImpl;
export const LoggerUtil = LoggerUtilImpl;
export default LoggerUtil;