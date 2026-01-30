/**
 * ErrorHandler - Error handling utility class | 错误处理工具类
 * Provides unified error handling, error parsing and error message generation functionality | 提供统一的错误处理、错误解析和错误信息生成功能
 */


// Error type enum | 错误类型枚举
export enum ErrorType {
  NETWORK_ERROR = 'network_error',
  STORAGE_ERROR = 'storage_error',
  SERVICE_ERROR = 'service_error',
  PERMISSION_ERROR = 'permission_error',
  VALIDATION_ERROR = 'validation_error',
  UNKNOWN_ERROR = 'unknown_error'
}

// Error details interface | 错误详情接口
export interface ErrorData {
  message?: string;
  code?: string;
  stack?: string;
}

// Error details class | 错误详情类
export class ErrorDetails {
  private data: Map<string, string | number | boolean | null> = new Map();
  
  constructor() {
    this.data = new Map();
  }
  
  set(key: string, value: string | number | boolean | null): void {
    this.data.set(key, value);
  }
  
  get(key: string): string | number | boolean | null | undefined {
    return this.data.get(key);
  }
  
  has(key: string): boolean {
    return this.data.has(key);
  }
  
  toObject(): Record<string, string | number | boolean | null> {
    const result: Record<string, string | number | boolean | null> = {};
    this.data.forEach((value, key) => {
      result[key] = value;
    });
    return result;
  }
}

// Error information interface | 错误信息接口
export interface ErrorInfo {
  type: ErrorType;
  code: string;
  message: string;
  details?: ErrorDetails;
  stack?: string;
}

/**
 * Error handling utility class | 错误处理工具类
 */
export class ErrorHandler {
  private static instance: ErrorHandler | null = null;
  private errorListeners: Array<(error: ErrorInfo) => void> = [];

  /**
   * Get error handler instance | 获取错误处理实例
   * @returns ErrorHandler instance | ErrorHandler实例
   */
  public static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler();
    }
    return ErrorHandler.instance;
  }

  /**
   * Constructor | 构造函数
   */
  private constructor() {
    this.setupGlobalErrorHandling();
  }

  /**
   * Setup global error handling | 设置全局错误处理
   */
  private setupGlobalErrorHandling(): void {
    try {
      // Note: Global error handling in ArkTS environment may be different
      // 注意：ArkTS环境下的全局错误处理可能有所不同
      // A simplified implementation is provided here | 这里提供一个简化的实现
      console.info('ErrorHandler: Global error handling setup completed');
    } catch (error) {
      console.error('ErrorHandler: Failed to setup global error handling', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * Handle error | 处理错误
   * @param error Error object | 错误对象
   * @param code Error code | 错误代码
   * @returns Error information | 错误信息
   */
  public handleError(error: Error | object | string | number | boolean | null | undefined, code: string = 'UNKNOWN'): ErrorInfo {
    try {
      const errorInfo = this.parseError(error, code);
      this.logError(errorInfo);
      this.notifyErrorListeners(errorInfo);
      return errorInfo;
    } catch (handlerError) {
      const details = new ErrorDetails();
      details.set('originalError', String(error));
      details.set('handlerError', String(handlerError));
      const fallbackError: ErrorInfo = {
        type: ErrorType.UNKNOWN_ERROR,
        code: 'ERROR_HANDLER_FAILURE',
        message: 'Error handler failed to process error',
        details: details
      };
      console.error('ErrorHandler: Error handler failed', handlerError instanceof Error ? handlerError : new Error(String(handlerError)));
      return fallbackError;
    }
  }

  /**
   * Parse error | 解析错误
   * @param error Error object | 错误对象
   * @param code Error code | 错误代码
   * @returns Error information | 错误信息
   */
  private parseError(error: Error | object | string | number | boolean | null | undefined, code: string): ErrorInfo {
    if (error instanceof Error) {
      return this.parseNativeError(error, code);
    } else if (typeof error === 'object' && error !== null) {
      return this.parseObjectError(error, code);
    } else {
      return this.parsePrimitiveError(error, code);
    }
  }

  /**
   * Parse native error | 解析原生错误
   * @param error Native Error object | 原生Error对象
   * @param code Error code | 错误代码
   * @returns Error information | 错误信息
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
   * Parse object error | 解析对象错误
   * @param error Error object | 错误对象
   * @param code Error code | 错误代码
   * @returns Error information | 错误信息
   */
  private parseObjectError(error: object, code: string): ErrorInfo {
    const errorObj = error as any;
    const message = (errorObj.message || errorObj.msg || errorObj.error || 'An unknown error occurred') as string;
    const errorType = this.detectErrorType(message);
    
    return {
      type: errorType,
      code: (errorObj.code as string) || code,
      message: String(message),
      details: this.sanitizeErrorDetails(errorObj),
      stack: errorObj.stack as string
    };
  }

  /**
   * Parse primitive error | 解析原始类型错误
   * @param error Error value | 错误值
   * @param code Error code | 错误代码
   * @returns Error information | 错误信息
   */
  private parsePrimitiveError(error: string | number | boolean | null | undefined, code: string): ErrorInfo {
    const message = String(error);
    const errorType = this.detectErrorType(message);
    
    return {
      type: errorType,
      code: code,
      message: message
    };
  }

  /**
   * Detect error type | 检测错误类型
   * @param message Error message | 错误信息
   * @returns Error type | 错误类型
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
   * Sanitize error details | 清理错误详情
   * @param error Error object | 错误对象
   * @returns Sanitized error details | 清理后的错误详情
   */
  private sanitizeErrorDetails(error: any): ErrorDetails | undefined {
    try {
      const details = new ErrorDetails();
      let hasDetails = false;
      
      // Extract useful error information | 提取有用的错误信息
      const keys = Object.keys(error);
      for (const key of keys) {
        if (key !== 'message' && key !== 'code' && key !== 'stack') {
          const value = error[key];
          if (value !== undefined && value !== null && typeof value !== 'object') {
            details.set(key, value as string | number | boolean | null);
            hasDetails = true;
          }
        }
      }
      
      return hasDetails ? details : undefined;
    } catch {
      return undefined;
    }
  }

  /**
   * Log error | 记录错误
   * @param errorInfo Error information | 错误信息
   */
  private logError(errorInfo: ErrorInfo): void {
    const errorMessage = 'Error occurred: ' + errorInfo.type + ' - ' + errorInfo.message;
    
    // Log error details separately if available | 如果有错误详情，单独记录
    if (errorInfo.details) {
      try {
        const detailsObj = errorInfo.details.toObject();
        const detailsString = JSON.stringify(detailsObj);
        console.error('ErrorHandler: ' + errorMessage + ' | Details: ' + detailsString);
      } catch {
        console.error('ErrorHandler: ' + errorMessage);
      }
    } else {
      console.error('ErrorHandler: ' + errorMessage);
    }
    
    // Log stack if available | 如果有堆栈信息，记录堆栈
    if (errorInfo.stack) {
      console.error('ErrorHandler: Error stack: ' + errorInfo.stack);
    }
  }

  /**
   * Notify error listeners | 通知错误监听器
   * @param errorInfo Error information | 错误信息
   */
  private notifyErrorListeners(errorInfo: ErrorInfo): void {
    for (const listener of this.errorListeners) {
      try {
        listener(errorInfo);
      } catch (listenerError) {
        console.error('ErrorHandler: Error listener failed', listenerError instanceof Error ? listenerError : new Error(String(listenerError)));
      }
    }
  }

  /**
   * Add error listener | 添加错误监听器
   * @param listener Error listener | 错误监听器
   */
  public addErrorListener(listener: (error: ErrorInfo) => void): void {
    this.errorListeners.push(listener);
  }

  /**
   * Remove error listener | 移除错误监听器
   * @param listener Error listener | 错误监听器
   */
  public removeErrorListener(listener: (error: ErrorInfo) => void): void {
    const index = this.errorListeners.indexOf(listener);
    if (index > -1) {
      this.errorListeners.splice(index, 1);
    }
  }

  /**
   * Generate user-friendly error message | 生成用户友好的错误信息
   * @param error Error object | 错误对象
   * @returns User-friendly error message | 用户友好的错误信息
   */
  public getFriendlyErrorMessage(error: Error | object | string | number | boolean | null | undefined): string {
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
   * Check if it is a network error | 检查是否是网络错误
   * @param error Error object | 错误对象
   * @returns Whether it is a network error | 是否是网络错误
   */
  public isNetworkError(error: Error | object | string | number | boolean | null | undefined): boolean {
    const errorInfo = this.parseError(error, 'NETWORK_ERROR_CHECK');
    return errorInfo.type === ErrorType.NETWORK_ERROR;
  }

  /**
   * Check if it is a storage error | 检查是否是存储错误
   * @param error Error object | 错误对象
   * @returns Whether it is a storage error | 是否是存储错误
   */
  public isStorageError(error: Error | object | string | number | boolean | null | undefined): boolean {
    const errorInfo = this.parseError(error, 'STORAGE_ERROR_CHECK');
    return errorInfo.type === ErrorType.STORAGE_ERROR;
  }

  /**
   * Check if it is a permission error | 检查是否是权限错误
   * @param error Error object | 错误对象
   * @returns Whether it is a permission error | 是否是权限错误
   */
  public isPermissionError(error: Error | object | string | number | boolean | null | undefined): boolean {
    const errorInfo = this.parseError(error, 'PERMISSION_ERROR_CHECK');
    return errorInfo.type === ErrorType.PERMISSION_ERROR;
  }
}

/**
 * Global error handling function | 全局错误处理函数
 * @param error Error object | 错误对象
 * @param code Error code | 错误代码
 * @returns Error information | 错误信息
 */
export function handleError(error: Error | object | string | number | boolean | null | undefined, code: string = 'UNKNOWN'): ErrorInfo {
  return ErrorHandler.getInstance().handleError(error, code);
}

/**
 * Generate user-friendly error message | 生成用户友好的错误信息
 * @param error Error object | 错误对象
 * @returns User-friendly error message | 用户友好的错误信息
 */
export function getFriendlyErrorMessage(error: Error | object | string | number | boolean | null | undefined): string {
  return ErrorHandler.getInstance().getFriendlyErrorMessage(error);
}

/**
 * Setup global error handler | 设置全局错误处理
 */
export function setupGlobalErrorHandler(): void {
  ErrorHandler.getInstance();
}

export default ErrorHandler;