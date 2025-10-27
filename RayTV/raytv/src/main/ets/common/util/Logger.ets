// Logger工具类，用于应用日志记录

/**
 * 日志工具类
 * 提供不同级别的日志输出功能，支持条件输出和格式化
 */
export default class Logger {
  /**
   * 输出调试日志
   * @param tag 日志标签，通常为当前类名或模块名
   * @param message 日志消息
   */
  public static debug(tag: string, message: string): void {
    if (globalThis.isDebugMode || !globalThis.isRelease) {
      console.debug(`[${tag}] ${message}`);
    }
  }

  /**
   * 输出信息日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  public static info(tag: string, message: string): void {
    if (globalThis.isDebugMode || !globalThis.isRelease) {
      console.info(`[${tag}] ${message}`);
    }
  }

  /**
   * 输出警告日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  public static warn(tag: string, message: string): void {
    console.warn(`[${tag}] ${message}`);
  }

  /**
   * 输出错误日志
   * @param tag 日志标签
   * @param message 日志消息
   */
  public static error(tag: string, message: string): void {
    console.error(`[${tag}] ${message}`);
  }

  /**
   * 输出异常信息
   * @param tag 日志标签
   * @param error 错误对象或错误消息
   */
  public static exception(tag: string, error: any): void {
    if (error instanceof Error) {
      console.error(`[${tag}] ${error.message}\n${error.stack}`);
    } else {
      console.error(`[${tag}] ${String(error)}`);
    }
  }

  /**
   * 输出带格式化参数的日志
   * @param tag 日志标签
   * @param format 格式化字符串
   * @param args 格式化参数
   */
  public static format(tag: string, format: string, ...args: any[]): void {
    const message = format.replace(/\{\}/g, () => args.shift() || '');
    console.info(`[${tag}] ${message}`);
  }
}