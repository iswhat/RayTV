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
 * 日志额外数据接口
 */
export interface LoggerExtraData {
  /**
   * 额外消息
   */
  message?: string;
  /**
   * 错误代码
   */
  code?: number;
  /**
   * 详细数据
   */
  detail?: Record<string, unknown>;
  /**
   * 其他任意属性
   */
  [key: string]: unknown;
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
  extra?: LoggerExtraData;
}

/**
 * 日志工具类
 */
class Logger {
  // 使用局部变量存储单例实例，避免使用类作为对象
  private static _instance: Logger | null = null;
  private config: LoggerConfig;
  private logs: LogEntry[] = [];
  private logFile?: string;
  private logFileHandle?: object; // 使用object类型替代any，在使用时会添加类型断言
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
    } as LoggerConfig;
  }

  /**
   * 获取Logger单例实例
   */
  public static getInstance(): Logger {
    if (!Logger._instance) {
      const instance = new Logger(); // 使用局部变量
      Logger._instance = instance;
    }
    return Logger._instance!
  }

  /**
   * 初始化Logger
   * @param config 日志配置
   */
  public initialize(config: LoggerConfig): void {
    // 手动合并对象属性，避免使用Object.assign（ArkTS限制）
    this.config = this.mergeConfig(this.config, config);
    
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
  public static debug(tag: string, message: string, extra?: LoggerExtraData): void {
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
  public static info(tag: string, message: string, extra?: LoggerExtraData): void {
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
  public static warn(tag: string, message: string, extra?: LoggerExtraData): void {
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
  public static error(tag: string, message: string, error?: Error, extra?: LoggerExtraData): void {
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
  public static exception(tag: string, error: string | Error, extra?: LoggerExtraData): void {
    const instance = Logger.getInstance();
    const formattedMessage = `[${tag}] ${error instanceof Error ? error.message : error}`;
    instance.error(formattedMessage, error instanceof Error ? error : undefined, extra);
  }

  /**
   * 输出带格式化参数的日志 - 兼容静态调用方式
   * @param tag 日志标签
   * @param format 格式化字符串
   * @param args 格式化参数
   */
  public static format(tag: string, format: string, ...args: Array<string | number | boolean | object | undefined | null>): void {
    // 使用formatMessage方法进行字符串格式化
    const formattedMessage = Logger.formatMessage(format, args);
    
    // 不使用logInternal，直接调用log方法
    const instance = Logger.getInstance();
    if (instance.shouldLog(LogLevel.INFO)) {
      instance.log(LogLevel.INFO, `[${tag}] ${formattedMessage}`);
    }
  }

  /**
   * 格式化日志消息（手动实现字符串替换，避免使用正则表达式）
   * @param message 原始消息
   * @param args 替换参数
   * @returns 格式化后的消息
   */
  private static formatMessage(message: string, args: Array<string | number | boolean | object | undefined | null>): string {
    if (!args || args.length === 0) {
      return message;
    }
    
    let result = message;
    for (let i = 0; i < args.length; i++) {
      const placeholder = `{${i}}`;
      const value = String(args[i]);
      
      // 手动替换占位符，避免使用正则表达式
      let startIndex = 0;
      while (true) {
        const index = result.indexOf(placeholder, startIndex);
        if (index === -1) {
          break;
        }
        
        result = result.substring(0, index) + value + result.substring(index + placeholder.length);
        startIndex = index + value.length;
      }
    }
    
    return result;
  }

  /**
   * 调试日志 - 实例方法
   * @param message 日志消息
   * @param extra 额外数据
   */
  public debug(message: string, extra?: LoggerExtraData): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      this.log(LogLevel.DEBUG, message, extra);
    }
  }

  /**
   * 信息日志 - 实例方法
   * @param message 日志消息
   * @param extra 额外数据
   */
  public info(message: string, extra?: LoggerExtraData): void {
    if (this.shouldLog(LogLevel.INFO)) {
      this.log(LogLevel.INFO, message, extra);
    }
  }

  /**
   * 警告日志 - 实例方法
   * @param message 日志消息
   * @param extra 额外数据
   */
  public warn(message: string, extra?: LoggerExtraData): void {
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
  public error(message: string, error?: Error, extra?: LoggerExtraData): void {
    if (this.shouldLog(LogLevel.ERROR)) {
      let stackTrace = '';
      if (error && error.stack) {
        stackTrace = error.stack;
      } else {
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
  public fatal(message: string, error?: Error, extra?: LoggerExtraData): void {
    if (this.shouldLog(LogLevel.FATAL)) {
      // 简化实现，只传递必要的参数
      this.log(LogLevel.FATAL, message, extra);
    }
  }

  /**
   * 记录对象
   * @param obj 要记录的对象
   * @param message 日志消息
   */
  public logObject(obj: object, message?: string): void {
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
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    const finalMessage = message ? `${message}: ${errorMessage}` : errorMessage;
    this.error(finalMessage);
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
   * 注意：此方法当前未被使用，保留是为了向后兼容
   */
  private logInternal(level: LogLevel, message: string): void {
    if (this.shouldLog(level)) {
      this.log(level, message, undefined, undefined);
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
  private log(level: LogLevel, message: string, extra?: LoggerExtraData, stackTrace?: string): void {
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
      // 异步刷新日志到文件
      this.flushLogs().catch(err => {
        console.error('Failed to flush logs:', err);
      });
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
        if (line && !line.includes('Logger.ets')) {
          // 使用字符串操作替代正则表达式
          const atIndex = line.indexOf('at ');
          if (atIndex !== -1) {
            const start = atIndex + 3;
            // 查找空格或换行
            let end = line.indexOf(' ', start);
            if (end === -1) {
              end = line.length;
            }
            return line.substring(start, end) || 'unknown';
          }
          return 'unknown';
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
  private serializeObject(obj: object): string {
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
    // 使用slice替代spread操作符获取要写入的条目
    const entriesToWrite = this.logQueue.slice(0);
    this.logQueue = [];
    
    try {
      // 这里需要实现异步文件写入
      for (const entry of entriesToWrite) {
        const formattedLine = this.formatLogEntry(entry) + '\n';
        // 写入到文件 - 实际实现需要使用文件系统API
        console.log('Log would be written:', formattedLine);
      }
      
      // 检查日志文件大小
      this.checkLogFileSize();
    } catch (error) {
      console.error('Failed to write logs to file:', error);
      // 不使用展开运算符，而是使用循环添加元素
      for (const entry of entriesToWrite) {
        this.logQueue.push(entry);
      }
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

  /**
   * 手动合并配置对象，避免使用Object.assign
   * @param target 目标配置
   * @param source 源配置
   */
  private mergeConfig(target: LoggerConfig, source: LoggerConfig): LoggerConfig {
    const result: LoggerConfig = {
      level: source.level !== undefined ? source.level : target.level,
      consoleEnabled: source.consoleEnabled !== undefined ? source.consoleEnabled : target.consoleEnabled,
      fileEnabled: source.fileEnabled !== undefined ? source.fileEnabled : target.fileEnabled,
      formatEnabled: source.formatEnabled !== undefined ? source.formatEnabled : target.formatEnabled,
      showTimestamp: source.showTimestamp !== undefined ? source.showTimestamp : target.showTimestamp,
      showLevel: source.showLevel !== undefined ? source.showLevel : target.showLevel,
      showCaller: source.showCaller !== undefined ? source.showCaller : target.showCaller,
      showProcessId: source.showProcessId !== undefined ? source.showProcessId : target.showProcessId,
      showThreadId: source.showThreadId !== undefined ? source.showThreadId : target.showThreadId,
      enableStackTrace: source.enableStackTrace !== undefined ? source.enableStackTrace : target.enableStackTrace,
    };

    // 处理可选属性
    if (source.logFilePath !== undefined) {
      result.logFilePath = source.logFilePath;
    } else if (target.logFilePath !== undefined) {
      result.logFilePath = target.logFilePath;
    }

    if (source.maxFileSize !== undefined) {
      result.maxFileSize = source.maxFileSize;
    } else if (target.maxFileSize !== undefined) {
      result.maxFileSize = target.maxFileSize;
    }

    if (source.maxFileCount !== undefined) {
      result.maxFileCount = source.maxFileCount;
    } else if (target.maxFileCount !== undefined) {
      result.maxFileCount = target.maxFileCount;
    }

    return result;
  }
}

// 导出默认实例
export default Logger.getInstance();
// 导出Logger类，供需要创建自定义实例的场景使用
export { Logger };