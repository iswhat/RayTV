/**
 * Logger工具类
 * 提供分级日志记录功能，支持日志格式化和过滤
 */
export class Logger {
  private static readonly LOG_LEVEL: {
    [key: string]: number;
  } = {
    'VERBOSE': 0,
    'DEBUG': 1,
    'INFO': 2,
    'WARN': 3,
    'ERROR': 4
  };

  private static currentLevel: number = Logger.LOG_LEVEL.INFO;
  private static isEnabled: boolean = true;
  private static maxLogLength: number = 4000;

  /**
   * 设置日志级别
   * @param level 日志级别字符串
   */
  public static setLevel(level: string): void {
    if (Logger.LOG_LEVEL[level] !== undefined) {
      Logger.currentLevel = Logger.LOG_LEVEL[level];
    }
  }

  /**
   * 启用或禁用日志
   * @param enabled 是否启用
   */
  public static enable(enabled: boolean): void {
    Logger.isEnabled = enabled;
  }

  /**
   * Verbose级别日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  public static verbose(tag: string, message: string): void {
    if (Logger.canLog(Logger.LOG_LEVEL.VERBOSE)) {
      console.log(`[V] [${tag}] ${message}`);
    }
  }

  /**
   * Debug级别日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  public static debug(tag: string, message: string): void {
    if (Logger.canLog(Logger.LOG_LEVEL.DEBUG)) {
      console.debug(`[D] [${tag}] ${message}`);
    }
  }

  /**
   * Info级别日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  public static info(tag: string, message: string): void {
    if (Logger.canLog(Logger.LOG_LEVEL.INFO)) {
      console.info(`[I] [${tag}] ${message}`);
    }
  }

  /**
   * Warning级别日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  public static warn(tag: string, message: string): void {
    if (Logger.canLog(Logger.LOG_LEVEL.WARN)) {
      console.warn(`[W] [${tag}] ${message}`);
    }
  }

  /**
   * Error级别日志
   * @param tag 日志标签
   * @param message 日志消息
   * @param error 错误对象
   */
  public static error(tag: string, message: string, error?: Error): void {
    if (Logger.canLog(Logger.LOG_LEVEL.ERROR)) {
      let logMessage = `[E] [${tag}] ${message}`;
      if (error) {
        logMessage += `\nError: ${error.message}\nStack: ${error.stack}`;
      }
      console.error(logMessage);
    }
  }

  /**
   * 记录对象
   * @param tag 日志标签
   * @param obj 要记录的对象
   */
  public static object(tag: string, obj: any): void {
    if (Logger.canLog(Logger.LOG_LEVEL.DEBUG)) {
      try {
        const jsonString = JSON.stringify(obj, null, 2);
        Logger.logLargeMessage(tag, jsonString, Logger.LOG_LEVEL.DEBUG);
      } catch (error) {
        Logger.error(tag, 'Failed to stringify object', error);
      }
    }
  }

  /**
   * 记录异常
   * @param tag 日志标签
   * @param error 错误对象
   */
  public static exception(tag: string, error: Error): void {
    if (Logger.canLog(Logger.LOG_LEVEL.ERROR)) {
      Logger.error(tag, 'Exception occurred', error);
    }
  }

  /**
   * 检查是否应该记录该级别的日志
   * @param level 日志级别
   * @returns 是否应该记录
   */
  private static canLog(level: number): boolean {
    return Logger.isEnabled && level >= Logger.currentLevel;
  }

  /**
   * 处理长日志消息，防止控制台截断
   * @param tag 日志标签
   * @param message 日志消息
   * @param level 日志级别
   */
  private static logLargeMessage(tag: string, message: string, level: number): void {
    if (message.length <= Logger.maxLogLength) {
      switch (level) {
        case Logger.LOG_LEVEL.VERBOSE:
          Logger.verbose(tag, message);
          break;
        case Logger.LOG_LEVEL.DEBUG:
          Logger.debug(tag, message);
          break;
        case Logger.LOG_LEVEL.INFO:
          Logger.info(tag, message);
          break;
        case Logger.LOG_LEVEL.WARN:
          Logger.warn(tag, message);
          break;
        case Logger.LOG_LEVEL.ERROR:
          Logger.error(tag, message);
          break;
      }
      return;
    }

    // 分段输出长日志
    const chunks = message.match(new RegExp(`.{1,${Logger.maxLogLength}}`, 'g'));
    if (chunks) {
      chunks.forEach((chunk, index) => {
        const chunkMessage = `[Part ${index + 1}/${chunks.length}] ${chunk}`;
        switch (level) {
          case Logger.LOG_LEVEL.VERBOSE:
            Logger.verbose(tag, chunkMessage);
            break;
          case Logger.LOG_LEVEL.DEBUG:
            Logger.debug(tag, chunkMessage);
            break;
          case Logger.LOG_LEVEL.INFO:
            Logger.info(tag, chunkMessage);
            break;
          case Logger.LOG_LEVEL.WARN:
            Logger.warn(tag, chunkMessage);
            break;
          case Logger.LOG_LEVEL.ERROR:
            Logger.error(tag, chunkMessage);
            break;
        }
      });
    }
  }
}

export default Logger;