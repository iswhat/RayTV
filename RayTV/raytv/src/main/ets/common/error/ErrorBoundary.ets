/**
 * 错误边界类
 * 用于捕获和处理组件渲染过程中的错误
 */

// 错误信息详情接口 | Error information detail interface
export interface ErrorInfoDetail {
  componentStack?: string;
  componentName?: string;
  timestamp?: number;
  [key: string]: string | number | boolean | null | undefined;
}

export interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfoDetail | null;
}

export class ErrorBoundary {
  private static instance: ErrorBoundary;
  private errorState: ErrorBoundaryState = {
    hasError: false,
    error: null,
    errorInfo: null
  };
  private errorHandlers: Map<string, (error: Error, errorInfo: ErrorInfoDetail) => void> = new Map();

  private constructor() {}

  static getInstance(): ErrorBoundary {
    if (!ErrorBoundary.instance) {
      ErrorBoundary.instance = new ErrorBoundary();
    }
    return ErrorBoundary.instance;
  }

  /**
   * 捕获错误
   */
  catchError(error: Error, errorInfo: ErrorInfoDetail, componentName?: string): void {
    console.error(`Error in ${componentName || 'unknown component'}:`, error);
    console.error('Error info:', errorInfo);

    this.errorState = {
      hasError: true,
      error,
      errorInfo
    };

    // 调用对应组件的错误处理器
    if (componentName && this.errorHandlers.has(componentName)) {
      try {
        this.errorHandlers.get(componentName)?.(error, errorInfo);
      } catch (handlerError) {
        console.error('Error in error handler:', handlerError);
      }
    }

    // 全局错误处理
    this.handleGlobalError(error, errorInfo, componentName);
  }

  /**
   * 注册组件错误处理器
   */
  registerErrorHandler(componentName: string, handler: (error: Error, errorInfo: ErrorInfoDetail) => void): void {
    this.errorHandlers.set(componentName, handler);
  }

  /**
   * 移除组件错误处理器
   */
  unregisterErrorHandler(componentName: string): void {
    this.errorHandlers.delete(componentName);
  }

  /**
   * 全局错误处理
   */
  private handleGlobalError(error: Error, errorInfo: ErrorInfoDetail, componentName?: string): void {
    // 这里可以添加全局错误处理逻辑
    // 例如：发送错误日志到服务器，显示全局错误提示等
    console.error(`Global error handling for ${componentName || 'unknown component'}:`, error);
  }

  /**
   * 重置错误状态
   */
  resetErrorState(): void {
    this.errorState = {
      hasError: false,
      error: null,
      errorInfo: null
    };
  }

  /**
   * 获取错误状态
   */
  getErrorState(): ErrorBoundaryState {
    return { ...this.errorState };
  }

  /**
   * 检查是否有错误
   */
  hasError(): boolean {
    return this.errorState.hasError;
  }

  /**
   * 包装可能抛出错误的函数
   */
  wrap<T extends (...args: any[]) => any>(func: T, componentName?: string): (...args: Parameters<T>) => ReturnType<T> | undefined {
    return (...args: Parameters<T>) => {
      try {
        return func(...args);
      } catch (error) {
        this.catchError(error as Error, { args }, componentName);
        return undefined;
      }
    };
  }

  /**
   * 异步函数错误包装
   */
  async wrapAsync<T extends (...args: any[]) => Promise<any>>(func: T, componentName?: string): Promise<ReturnType<T> | undefined> {
    try {
      return await func();
    } catch (error) {
      this.catchError(error as Error, {}, componentName);
      return undefined;
    }
  }
}

/**
 * 错误处理工具函数
 */
export const ErrorUtils = {
  /**
   * 安全执行函数
   */
  safeExecute<T extends (...args: any[]) => any>(func: T, fallback?: ReturnType<T>): ReturnType<T> | undefined {
    try {
      return func();
    } catch (error) {
      console.error('Safe execute error:', error);
      return fallback;
    }
  },

  /**
   * 安全执行异步函数
   */
  async safeExecuteAsync<T extends (...args: any[]) => Promise<any>>(func: T, fallback?: Awaited<ReturnType<T>>): Promise<Awaited<ReturnType<T>> | undefined> {
    try {
      return await func();
    } catch (error) {
      console.error('Safe execute async error:', error);
      return fallback;
    }
  },

  /**
   * 格式化错误信息
   */
  formatError(error: Error): string {
    return `${error.name}: ${error.message}\n${error.stack || 'No stack trace'}`;
  },

  /**
   * 检查错误类型
   */
  isNetworkError(error: Error): boolean {
    return error.message.includes('network') || 
           error.message.includes('fetch') || 
           error.message.includes('HTTP') ||
           error.message.includes('timeout');
  },

  /**
   * 检查是否为权限错误
   */
  isPermissionError(error: Error): boolean {
    return error.message.includes('permission') || 
           error.message.includes('denied');
  },

  /**
   * 检查是否为资源不存在错误
   */
  isNotFoundError(error: Error): boolean {
    return error.message.includes('not found') || 
           error.message.includes('404');
  }
};