/**
 * ErrorHandler - 错误处理工具类
 * 提供统一的错误处理、错误解析和错误信息生成功能
 */
import Logger from './Logger';

// 错误类型枚举
export enum ErrorType {
  NETWORK_ERROR = 'network_error',
  STORAGE_ERROR = 'storage_error',
  SERVICE_ERROR = 'service_error',
  PERMISSION_ERROR = 'permission_error',
  VALIDATION_ERROR = 'validation_error',
  UNKNOWN_ERROR = 'unknown_error'
}

// 错误信息接口
export interface ErrorInfo {
  type: ErrorType;
  code: string;
  message: string;
  details?: any;
  stack?: string;
}

/**
 * 错误处理工具类
 */
export class ErrorHandler {
  private static instance: ErrorHandler | null = null;
  private errorListeners: Array<(error: ErrorInfo) => void> = [];

  /**
   * 获取错误处理实例
   * @returns ErrorHandler实例
   */
  public static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler();
    }
    return ErrorHandler.instance;
  }

  /**
   * 构造函数
   */
  private constructor() {
    this.setupGlobalErrorHandling();
  }

  /**
   * 设置全局错误处理
   */
  private setupGlobalErrorHandling(): void {
    try {
      // 捕获未处理的Promise拒绝
      Promise.prototype.catch = function<T = any>(onRejected?: ((reason: any) => T | PromiseLike<T>) | undefined | null): Promise<T | any> {
        return (this as Promise<any>).then(undefined, (reason) => {
          if (onRejected) {
            return onRejected(reason);
          } else {
            // 处理未捕获的Promise拒绝
            ErrorHandler.getInstance().handleError(reason, 'UNHANDLED_PROMISE_REJECTION');
            return Promise.reject(reason);
          }
        });
      };

      // 捕获全局错误
      if (globalThis) {
        // 注意：ArkTS环境下的全局错误处理可能有所不同
        // 这里提供一个通用的实现
        const originalOnError = globalThis.onerror;
        globalThis.onerror = (message, source, lineno, colno, error) => {
          if (error) {
            ErrorHandler.getInstance().handleError(error, 'GLOBAL_ERROR');
          } else {
            ErrorHandler.getInstance().handleError(new Error(String(message)), 'GLOBAL_ERROR');
          }
          return originalOnError?.(message, source, lineno, colno, error);
        };
      }

      Logger.info('ErrorHandler', 'Global error handling setup completed');
    } catch (error) {
      Logger.error('ErrorHandler', 'Failed to setup global error handling', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 处理错误
   * @param error 错误对象
   * @param code 错误代码
   * @returns 错误信息
   */
  public handleError(error: any, code: string = 'UNKNOWN'): ErrorInfo {
    try {
      const errorInfo = this.parseError(error, code);
      this.logError(errorInfo);
      this.notifyErrorListeners(errorInfo);
      return errorInfo;
    } catch (handlerError) {
      const fallbackError: ErrorInfo = {
        type: ErrorType.UNKNOWN_ERROR,
        code: 'ERROR_HANDLER_FAILURE',
        message: 'Error handler failed to process error',
        details: { originalError: error, handlerError: handlerError }
      };
      Logger.error('ErrorHandler', 'Error handler failed', handlerError instanceof Error ? handlerError : new Error(String(handlerError)));
      return fallbackError;
    }
  }

  /**
   * 解析错误
   * @param error 错误对象
   * @param code 错误代码
   * @returns 错误信息
   */
  private parseError(error: any, code: string): ErrorInfo {
    if (error instanceof Error) {
      return this.parseNativeError(error, code);
    } else if (typeof error === 'object' && error !== null) {
      return this.parseObjectError(error, code);
    } else {
      return this.parsePrimitiveError(error, code);
    }
  }

  /**
   * 解析原生错误
   * @param error 原生Error对象
   * @param code 错误代码
   * @returns 错误信息
   */
  private parseNativeError(error: Error, code: string): ErrorInfo {
    const errorType = this.detectErrorType(error.message);
    
    return {
      type: errorType,
      code: code,
      message: error.message || 'An unknown error occurred',
      stack: error.stack
    };
  }

  /**
   * 解析对象错误
   * @param error 错误对象
   * @param code 错误代码
   * @returns 错误信息
   */
  private parseObjectError(error: any, code: string): ErrorInfo {
    const message = error.message || error.msg || error.error || 'An unknown error occurred';
    const errorType = this.detectErrorType(message);
    
    return {
      type: errorType,
      code: error.code || code,
      message: String(message),
      details: this.sanitizeErrorDetails(error),
      stack: error.stack
    };
  }

  /**
   * 解析原始类型错误
   * @param error 错误值
   * @param code 错误代码
   * @returns 错误信息
   */
  private parsePrimitiveError(error: any, code: string): ErrorInfo {
    const message = String(error);
    const errorType = this.detectErrorType(message);
    
    return {
      type: errorType,
      code: code,
      message: message
    };
  }

  /**
   * 检测错误类型
   * @param message 错误信息
   * @returns 错误类型
   */
  private detectErrorType(message: string): ErrorType {
    const lowerMessage = message.toLowerCase();
    
    if (lowerMessage.includes('network') || lowerMessage.includes('connection') || lowerMessage.includes('timeout')) {
      return ErrorType.NETWORK_ERROR;
    } else if (lowerMessage.includes('storage') || lowerMessage.includes('cache') || lowerMessage.includes('disk')) {
      return ErrorType.STORAGE_ERROR;
    } else if (lowerMessage.includes('permission') || lowerMessage.includes('denied')) {
      return ErrorType.PERMISSION_ERROR;
    } else if (lowerMessage.includes('validation') || lowerMessage.includes('invalid') || lowerMessage.includes('required')) {
      return ErrorType.VALIDATION_ERROR;
    } else if (lowerMessage.includes('service') || lowerMessage.includes('api')) {
      return ErrorType.SERVICE_ERROR;
    } else {
      return ErrorType.UNKNOWN_ERROR;
    }
  }

  /**
   * 清理错误详情
   * @param error 错误对象
   * @returns 清理后的错误详情
   */
  private sanitizeErrorDetails(error: any): any {
    try {
      const details: any = {};
      
      // 提取有用的错误信息
      for (const key in error) {
        if (error.hasOwnProperty(key) && key !== 'message' && key !== 'code' && key !== 'stack') {
          details[key] = error[key];
        }
      }
      
      return Object.keys(details).length > 0 ? details : undefined;
    } catch {
      return undefined;
    }
  }

  /**
   * 记录错误
   * @param errorInfo 错误信息
   */
  private logError(errorInfo: ErrorInfo): void {
    const errorDetails = {
      type: errorInfo.type,
      code: errorInfo.code,
      message: errorInfo.message,
      details: errorInfo.details,
      stack: errorInfo.stack
    };
    
    Logger.error('ErrorHandler', `Error occurred: ${errorInfo.type} - ${errorInfo.message}`, errorDetails);
  }

  /**
   * 通知错误监听器
   * @param errorInfo 错误信息
   */
  private notifyErrorListeners(errorInfo: ErrorInfo): void {
    for (const listener of this.errorListeners) {
      try {
        listener(errorInfo);
      } catch (listenerError) {
        Logger.error('ErrorHandler', 'Error listener failed', listenerError instanceof Error ? listenerError : new Error(String(listenerError)));
      }
    }
  }

  /**
   * 添加错误监听器
   * @param listener 错误监听器
   */
  public addErrorListener(listener: (error: ErrorInfo) => void): void {
    this.errorListeners.push(listener);
  }

  /**
   * 移除错误监听器
   * @param listener 错误监听器
   */
  public removeErrorListener(listener: (error: ErrorInfo) => void): void {
    const index = this.errorListeners.indexOf(listener);
    if (index > -1) {
      this.errorListeners.splice(index, 1);
    }
  }

  /**
   * 生成用户友好的错误信息
   * @param error 错误对象
   * @returns 用户友好的错误信息
   */
  public getFriendlyErrorMessage(error: any): string {
    try {
      const errorInfo = this.parseError(error, 'USER_FRIENDLY_MESSAGE');
      
      switch (errorInfo.type) {
        case ErrorType.NETWORK_ERROR:
          return '网络连接失败，请检查网络设置后重试';
        case ErrorType.STORAGE_ERROR:
          return '存储操作失败，请检查存储空间后重试';
        case ErrorType.SERVICE_ERROR:
          return '服务暂时不可用，请稍后再试';
        case ErrorType.PERMISSION_ERROR:
          return '权限不足，请检查应用权限设置';
        case ErrorType.VALIDATION_ERROR:
          return errorInfo.message || '输入数据有误，请检查后重试';
        case ErrorType.UNKNOWN_ERROR:
        default:
          return '操作失败，请稍后再试';
      }
    } catch {
      return '操作失败，请稍后再试';
    }
  }

  /**
   * 检查是否是网络错误
   * @param error 错误对象
   * @returns 是否是网络错误
   */
  public isNetworkError(error: any): boolean {
    const errorInfo = this.parseError(error, 'NETWORK_ERROR_CHECK');
    return errorInfo.type === ErrorType.NETWORK_ERROR;
  }

  /**
   * 检查是否是存储错误
   * @param error 错误对象
   * @returns 是否是存储错误
   */
  public isStorageError(error: any): boolean {
    const errorInfo = this.parseError(error, 'STORAGE_ERROR_CHECK');
    return errorInfo.type === ErrorType.STORAGE_ERROR;
  }

  /**
   * 检查是否是权限错误
   * @param error 错误对象
   * @returns 是否是权限错误
   */
  public isPermissionError(error: any): boolean {
    const errorInfo = this.parseError(error, 'PERMISSION_ERROR_CHECK');
    return errorInfo.type === ErrorType.PERMISSION_ERROR;
  }
}

/**
 * 全局错误处理函数
 * @param error 错误对象
 * @param code 错误代码
 * @returns 错误信息
 */
export function handleError(error: any, code: string = 'UNKNOWN'): ErrorInfo {
  return ErrorHandler.getInstance().handleError(error, code);
}

/**
 * 生成用户友好的错误信息
 * @param error 错误对象
 * @returns 用户友好的错误信息
 */
export function getFriendlyErrorMessage(error: any): string {
  return ErrorHandler.getInstance().getFriendlyErrorMessage(error);
}

/**
 * 设置全局错误处理
 */
export function setupGlobalErrorHandler(): void {
  ErrorHandler.getInstance();
}

export default ErrorHandler;