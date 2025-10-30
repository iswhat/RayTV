// Logger - 日志工具类
// 提供统一的日志记录功能，支持不同级别、格式化输出和持久化存储

/**
 * 日志级别枚举
 */
export enum LogLevel {
  /**
   * 调试级别
   */
  DEBUG = 'debug',
  
  /**
   * 信息级别
   */
  INFO = 'info',
  
  /**
   * 警告级别
   */
  WARN = 'warn',
  
  /**
   * 错误级别
   */
  ERROR = 'error',
  
  /**
   * 致命错误级别
   */
  FATAL = 'fatal',
  
  /**
   * 关闭日志
   */
  OFF = 'off'
}

/**
 * 日志配置接口
 */
export interface LoggerConfig {
  /**
   * 日志级别
   */
  level: LogLevel;
  
  /**
   * 是否启用控制台日志
   */
  consoleEnabled: boolean;
  
  /**
   * 是否启用文件日志
   */
  fileEnabled: boolean;
  
  /**
   * 日志文件路径
   */
  logFilePath?: string;
  
  /**
   * 日志文件最大大小（字节）
   */
  maxFileSize?: number;
  
  /**
   * 日志文件最大数量
   */
  maxFileCount?: number;
  
  /**
   * 是否启用格式化
   */
  formatEnabled: boolean;
  
  /**
   * 是否显示时间戳
   */
  showTimestamp: boolean;
  
  /**
   * 是否显示日志级别
   */
  showLevel: boolean;
  
  /**
   * 是否显示调用者信息
   */
  showCaller: boolean;
  
  /**
   * 是否显示进程ID
   */
  showProcessId: boolean;
  
  /**
   * 是否显示线程ID
   */
  showThreadId: boolean;
  
  /**
   * 是否记录堆栈跟踪
   */
  enableStackTrace: boolean;
}

/**
 * 日志条目接口
 */
export interface LogEntry {
  /**
   * 日志级别
   */
  level: LogLevel;
  
  /**
   * 消息内容
   */
  message: string;
  
  /**
   * 时间戳
   */
  timestamp: number;
  
  /**
   * 调用者信息
   */
  caller?: string;
  
  /**
   * 进程ID
   */
  processId?: string;
  
  /**
   * 线程ID
   */
  threadId?: string;
  
  /**
   * 堆栈跟踪
   */
  stackTrace?: string;
  
  /**
   * 额外数据
   */
  extra?: Record<string, unknown>;
}

/**
 * 日志工具类
 */
export class Logger {
  private static instance: Logger;
  private config: LoggerConfig;
  private logs: LogEntry[] = [];
  private logFile?: string;
  private logFileHandle?: any; // 临时使用any，后续需要定义具体类型
  private logQueue: LogEntry[] = [];
  private isWriting: boolean = false;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.config = {
      level: LogLevel.INFO,
      consoleEnabled: true,
      fileEnabled: false,
      formatEnabled: true,
      showTimestamp: true,
      showLevel: true,
      showCaller: false,
      showProcessId: false,
      showThreadId: false,
      enableStackTrace: true,
    };
  }

  /**
   * 获取Logger单例实例
   */
  public static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  /**
   * 初始化Logger
   * @param config 日志配置
   */
  public initialize(config: Partial<LoggerConfig>): void {
    // 替换Object.assign为展开运算符
    this.config = {
      ...this.config,
      ...config
    };
    
    if (this.config.fileEnabled && this.config.logFilePath) {
      this.logFile = this.config.logFilePath;
      this.ensureLogFileExists();
    }
    
    this.log(LogLevel.INFO, 'Logger initialized with level: ' + this.config.level);
  }

  /**
   * 设置日志级别
   * @param level 日志级别
   */
  public setLevel(level: LogLevel): void {
    this.config.level = level;
    this.log(LogLevel.INFO, 'Log level changed to: ' + level);
  }

  /**
   * 获取当前日志级别
   */
  public getLevel(): LogLevel {
    return this.config.level;
  }

  /**
   * 调试日志 - 兼容静态调用方式
   * @param tag 日志标签
   * @param message 日志消息
   * @param extra 额外数据
   */
  public static debug(tag: string, message: string, extra?: Record<string, unknown>): void {
    const instance = Logger.getInstance();
    const formattedMessage = `[${tag}] ${message}`;
    instance.debug(formattedMessage, extra);
  }

  /**
   * 信息日志 - 兼容静态调用方式
   * @param tag 日志标签
   * @param message 日志消息
   * @param extra 额外数据
   */
  public static info(tag: string, message: string, extra?: Record<string, unknown>): void {
    const instance = Logger.getInstance();
    const formattedMessage = `[${tag}] ${message}`;
    instance.info(formattedMessage, extra);
  }

  /**
   * 警告日志 - 兼容静态调用方式
   * @param tag 日志标签
   * @param message 日志消息
   * @param extra 额外数据
   */
  public static warn(tag: string, message: string, extra?: Record<string, unknown>): void {
    const instance = Logger.getInstance();
    const formattedMessage = `[${tag}] ${message}`;
    instance.warn(formattedMessage, extra);
  }

  /**
   * 错误日志 - 兼容静态调用方式
   * @param tag 日志标签
   * @param message 日志消息
   * @param error 错误对象
   * @param extra 额外数据
   */
  public static error(tag: string, message: string, error?: Error, extra?: Record<string, unknown>): void {
    const instance = Logger.getInstance();
    const formattedMessage = `[${tag}] ${message}`;
    instance.error(formattedMessage, error, extra);
  }

  /**
   * 输出异常信息 - 兼容静态调用方式
   * @param tag 日志标签
   * @param error 错误对象或错误消息
   * @param extra 额外数据
   */
  public static exception(tag: string, error: string | Error, extra?: Record<string, unknown>): void {
    const instance = Logger.getInstance();
    if (error instanceof Error) {
      instance.logException(error, `[${tag}] ${error.message}`, extra);
    } else {
      instance.error(`[${tag}] ${String(error)}`, undefined, extra);
    }
  }

  /**
   * 输出带格式化参数的日志 - 兼容静态调用方式
   * @param tag 日志标签
   * @param format 格式化字符串
   * @param args 格式化参数
   */
  public static format(tag: string, format: string, ...args: unknown[]): void {
    const message = format.replace(/\{\}/g, () => args.shift() || '');
    Logger.getInstance().logInternal(LogLevel.INFO, tag, message);
  }

  /**
   * 调试日志 - 实例方法
   * @param message 日志消息
   * @param extra 额外数据
   */
  public debug(message: string, extra?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      this.log(LogLevel.DEBUG, message, extra);
    }
  }

  /**
   * 信息日志 - 实例方法
   * @param message 日志消息
   * @param extra 额外数据
   */
  public info(message: string, extra?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.INFO)) {
      this.log(LogLevel.INFO, message, extra);
    }
  }

  /**
   * 警告日志 - 实例方法
   * @param message 日志消息
   * @param extra 额外数据
   */
  public warn(message: string, extra?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.WARN)) {
      this.log(LogLevel.WARN, message, extra);
    }
  }

  /**
   * 错误日志 - 实例方法
   * @param message 日志消息
   * @param error 错误对象
   * @param extra 额外数据
   */
  public error(message: string, error?: Error, extra?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.ERROR)) {
      let stackTrace = '';
      if (error && error.stack) {
        stackTrace = error.stack;
      } else if (this.config.enableStackTrace) {
        stackTrace = this.getStackTrace();
      }
      this.log(LogLevel.ERROR, message, extra, stackTrace);
    }
  }

  /**
   * 致命错误日志 - 实例方法
   * @param message 日志消息
   * @param error 错误对象
   * @param extra 额外数据
   */
  public fatal(message: string, error?: Error, extra?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.FATAL)) {
      let stackTrace = '';
      if (error && error.stack) {
        stackTrace = error.stack;
      } else if (this.config.enableStackTrace) {
        stackTrace = this.getStackTrace();
      }
      this.log(LogLevel.FATAL, message, extra, stackTrace);
    }
  }

  /**
   * 记录对象
   * @param obj 要记录的对象
   * @param message 日志消息
   */
  public logObject(obj: Record<string, unknown>, message?: string): void {
    const objString = this.serializeObject(obj);
    const finalMessage = message ? `${message}: ${objString}` : objString;
    this.debug(finalMessage);
  }

  /**
   * 记录异常
   * @param error 错误对象
   * @param message 日志消息
   */
  public logException(error: Error, message?: string): void {
    const errorMessage = error.message || 'Unknown error';
    const stackTrace = error.stack || this.getStackTrace();
    const finalMessage = message ? `${message}: ${errorMessage}` : errorMessage;
    this.error(finalMessage, undefined, { stackTrace });
  }

  /**
   * 清空日志
   */
  public clearLogs(): void {
    this.logs = [];
    this.log(LogLevel.INFO, 'Logs cleared');
  }

  /**
   * 获取日志列表
   * @param level 日志级别过滤
   * @param limit 限制数量
   */
  public getLogs(level?: LogLevel, limit?: number): LogEntry[] {
    let filteredLogs = this.logs;
    
    if (level) {
      filteredLogs = filteredLogs.filter(log => log.level === level);
    }
    
    if (limit) {
      filteredLogs = filteredLogs.slice(-limit);
    }
    
    return filteredLogs;
  }

  /**
   * 导出日志到文件
   * @param filePath 导出文件路径
   */
  public async exportLogs(filePath: string): Promise<boolean> {
    try {
      // 这里需要实现文件写入功能
      this.info(`Logs exported to: ${filePath}`);
      return true;
    } catch (error) {
      this.error('Failed to export logs', error as Error);
      return false;
    }
  }

  /**
   * 刷新日志到文件
   */
  public async flushLogs(): Promise<void> {
    if (this.config.fileEnabled && this.logQueue.length > 0) {
      await this.writeLogsToFile();
    }
  }

  /**
   * 关闭Logger
   */
  public async shutdown(): Promise<void> {
    await this.flushLogs();
    if (this.logFileHandle) {
      // 关闭文件句柄
      this.logFileHandle = undefined;
    }
    this.log(LogLevel.INFO, 'Logger shutdown');
  }

  /**
   * 内部日志记录方法 - 用于兼容静态调用
   */
  private logInternal(level: LogLevel, tag: string, message: string): void {
    if (this.shouldLog(level)) {
      const formattedMessage = `[${tag}] ${message}`;
      this.log(level, formattedMessage);
    }
  }

  /**
   * 检查是否应该记录指定级别的日志
   * @param level 日志级别
   */
  private shouldLog(level: LogLevel): boolean {
    if (this.config.level === LogLevel.OFF) {
      return false;
    }
    
    const levelOrder = [LogLevel.DEBUG, LogLevel.INFO, LogLevel.WARN, LogLevel.ERROR, LogLevel.FATAL];
    const currentLevelIndex = levelOrder.indexOf(this.config.level);
    const targetLevelIndex = levelOrder.indexOf(level);
    
    return targetLevelIndex >= currentLevelIndex;
  }

  /**
   * 记录日志
   * @param level 日志级别
   * @param message 日志消息
   * @param extra 额外数据
   * @param stackTrace 堆栈跟踪
   */
  private log(level: LogLevel, message: string, extra?: Record<string, unknown>, stackTrace?: string): void {
    const entry: LogEntry = {
      level,
      message,
      timestamp: Date.now(),
      extra,
      stackTrace
    };
    
    if (this.config.showCaller) {
      entry.caller = this.getCallerInfo();
    }
    
    if (this.config.showProcessId) {
      entry.processId = this.getProcessId();
    }
    
    if (this.config.showThreadId) {
      entry.threadId = this.getThreadId();
    }
    
    this.logs.push(entry);
    
    // 限制日志数量
    if (this.logs.length > 10000) {
      this.logs = this.logs.slice(-10000);
    }
    
    // 输出到控制台
    if (this.config.consoleEnabled) {
      this.outputToConsole(entry);
    }
    
    // 添加到文件写入队列
    if (this.config.fileEnabled) {
      this.logQueue.push(entry);
      if (!this.isWriting) {
        this.writeLogsToFile().catch(err => {
          console.error('Failed to write logs to file:', err);
        });
      }
    }
  }

  /**
   * 输出日志到控制台
   * @param entry 日志条目
   */
  private outputToConsole(entry: LogEntry): void {
    const formattedMessage = this.formatLogEntry(entry);
    
    switch (entry.level) {
      case LogLevel.DEBUG:
        console.debug(formattedMessage);
        break;
      case LogLevel.INFO:
        console.info(formattedMessage);
        break;
      case LogLevel.WARN:
        console.warn(formattedMessage);
        break;
      case LogLevel.ERROR:
      case LogLevel.FATAL:
        console.error(formattedMessage);
        if (entry.stackTrace) {
          console.error(entry.stackTrace);
        }
        break;
    }
  }

  /**
   * 格式化日志条目
   * @param entry 日志条目
   */
  private formatLogEntry(entry: LogEntry): string {
    if (!this.config.formatEnabled) {
      return entry.message;
    }
    
    let parts: string[] = [];
    
    if (this.config.showTimestamp) {
      parts.push(this.formatTimestamp(entry.timestamp));
    }
    
    if (this.config.showLevel) {
      parts.push(`[${entry.level.toUpperCase()}]`);
    }
    
    if (entry.caller) {
      parts.push(`[${entry.caller}]`);
    }
    
    if (this.config.showProcessId && entry.processId) {
      parts.push(`[PID:${entry.processId}]`);
    }
    
    if (this.config.showThreadId && entry.threadId) {
      parts.push(`[TID:${entry.threadId}]`);
    }
    
    parts.push(entry.message);
    
    if (entry.extra) {
      parts.push(JSON.stringify(entry.extra));
    }
    
    return parts.join(' ');
  }

  /**
   * 格式化时间戳
   */
  private formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    const milliseconds = String(date.getMilliseconds()).padStart(3, '0');
    
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${milliseconds}`;
  }

  /**
   * 获取调用者信息
   */
  private getCallerInfo(): string {
    try {
      const stack = new Error().stack?.split('\n') || [];
      // 查找调用Logger方法的位置
      for (let i = 3; i < stack.length; i++) {
        const line = stack[i];
        if (line && !line.includes('Logger.ts')) {
          const match = line.match(/at\s+(\S+)\s+/);
          return match ? match[1] : 'unknown';
        }
      }
    } catch (error) {
      // 忽略错误
    }
    return 'unknown';
  }

  /**
   * 获取堆栈跟踪
   */
  private getStackTrace(): string {
    try {
      return new Error().stack || '';
    } catch (error) {
      return '';
    }
  }

  /**
   * 获取进程ID
   */
  private getProcessId(): string {
    // 在不同环境中获取进程ID的方式可能不同
    return 'process-' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * 获取线程ID
   */
  private getThreadId(): string {
    // 在前端环境中模拟线程ID
    return 'thread-' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * 序列化对象
   * @param obj 要序列化的对象
   */
  private serializeObject(obj: Record<string, unknown>): string {
    try {
      return JSON.stringify(obj, null, 2);
    } catch (error) {
      return String(obj);
    }
  }

  /**
   * 确保日志文件存在
   */
  private ensureLogFileExists(): void {
    // 这里需要实现文件系统操作
    this.info(`Log file configured: ${this.logFile}`);
  }

  /**
   * 写入日志到文件
   */
  private async writeLogsToFile(): Promise<void> {
    if (this.isWriting || this.logQueue.length === 0) {
      return;
    }
    
    this.isWriting = true;
    const entriesToWrite = [...this.logQueue];
    this.logQueue = [];
    
    try {
      // 这里需要实现异步文件写入
      for (const entry of entriesToWrite) {
        const formattedLine = this.formatLogEntry(entry) + '\n';
        // 写入到文件
      }
      
      // 检查日志文件大小
      this.checkLogFileSize();
    } catch (error) {
      console.error('Failed to write logs to file:', error);
      // 重新加入队列
      this.logQueue = [...entriesToWrite, ...this.logQueue];
    } finally {
      this.isWriting = false;
    }
  }

  /**
   * 检查日志文件大小
   */
  private checkLogFileSize(): void {
    // 这里需要实现文件大小检查和日志轮转
  }
}

// 导出默认Logger实例
export default Logger.getInstance();