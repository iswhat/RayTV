// ErrorService.ets - 错误处理服务
// 提供统一的错误处理机制，包括错误分类、错误码管理、错误日志记录等

import Logger from '../../common/util/Logger';

/**
 * 错误类型枚举
 */
export enum ErrorType {
  /** 网络错误 */
  NETWORK = 'NETWORK',
  /** 认证错误 */
  AUTHENTICATION = 'AUTHENTICATION',
  /** 权限错误 */
  PERMISSION = 'PERMISSION',
  /** 文件操作错误 */
  FILE = 'FILE',
  /** 解析错误 */
  PARSING = 'PARSING',
  /** 业务逻辑错误 */
  BUSINESS = 'BUSINESS',
  /** 系统错误 */
  SYSTEM = 'SYSTEM',
  /** 未知错误 */
  UNKNOWN = 'UNKNOWN'
}

/**
 * 错误码枚举
 */
export enum ErrorCode {
  // 网络错误 (1000-1999)
  NETWORK_TIMEOUT = 1000,
  NETWORK_CONNECTION = 1001,
  NETWORK_RESPONSE = 1002,
  NETWORK_SSL = 1003,
  
  // 认证错误 (2000-2999)
  AUTH_INVALID_CREDENTIALS = 2000,
  AUTH_TOKEN_EXPIRED = 2001,
  AUTH_FORBIDDEN = 2002,
  
  // 权限错误 (3000-3999)
  PERMISSION_DENIED = 3000,
  PERMISSION_MISSING = 3001,
  
  // 文件操作错误 (4000-4999)
  FILE_NOT_FOUND = 4000,
  FILE_ACCESS_DENIED = 4001,
  FILE_READ_ERROR = 4002,
  FILE_WRITE_ERROR = 4003,
  
  // 解析错误 (5000-5999)
  PARSING_JSON = 5000,
  PARSING_XML = 5001,
  PARSING_URL = 5002,
  
  // 业务逻辑错误 (6000-6999)
  BUSINESS_VALIDATION = 6000,
  BUSINESS_LOGIC = 6001,
  BUSINESS_NOT_FOUND = 6002,
  
  // 系统错误 (7000-7999)
  SYSTEM_OUT_OF_MEMORY = 7000,
  SYSTEM_RESOURCE = 7001,
  SYSTEM_CONFIG = 7002,
  
  // 未知错误 (9000+)
  UNKNOWN_ERROR = 9000
}

/**
 * 错误信息接口
 */
export interface ErrorInfo {
  /** 错误类型 */
  type: ErrorType;
  /** 错误码 */
  code: ErrorCode;
  /** 错误消息 */
  message: string;
  /** 错误详情 */
  details?: any;
  /** 错误发生的时间 */
  timestamp: number;
  /** 错误发生的位置 */
  location?: string;
  /** 错误堆栈 */
  stack?: string;
}

/**
 * 错误处理服务类
 */
export class ErrorService {
  private static instance: ErrorService | null = null;
  private logger: Logger;
  private errorCache: Map<string, ErrorInfo[]> = new Map();
  private maxErrorCacheSize: number = 100;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): ErrorService {
    if (!ErrorService.instance) {
      ErrorService.instance = new ErrorService();
    }
    return ErrorService.instance;
  }
  
  /**
   * 构造函数
   */
  private constructor() {
    this.logger = new Logger('ErrorService');
  }
  
  /**
   * 初始化错误服务
   */
  public initialize(): void {
    this.logger.info('初始化错误处理服务...');
    // 可以在这里添加初始化逻辑
  }
  
  /**
   * 捕获并处理错误
   * @param error 错误对象
   * @param options 错误处理选项
   */
  public captureError(error: any, options?: {
    type?: ErrorType;
    code?: ErrorCode;
    message?: string;
    location?: string;
    details?: any;
  }): ErrorInfo {
    const errorInfo: ErrorInfo = {
      type: options?.type || this.determineErrorType(error),
      code: options?.code || this.determineErrorCode(error),
      message: options?.message || this.getErrorMessage(error),
      details: options?.details || this.getErrorDetails(error),
      timestamp: Date.now(),
      location: options?.location,
      stack: error instanceof Error ? error.stack : undefined
    };
    
    // 记录错误日志
    this.logError(errorInfo);
    
    // 缓存错误信息
    this.cacheError(errorInfo);
    
    return errorInfo;
  }
  
  /**
   * 确定错误类型
   * @param error 错误对象
   */
  private determineErrorType(error: any): ErrorType {
    if (error instanceof Error) {
      const message = error.message.toLowerCase();
      
      if (message.includes('network') || message.includes('timeout') || message.includes('connection')) {
        return ErrorType.NETWORK;
      }
      
      if (message.includes('auth') || message.includes('token') || message.includes('login')) {
        return ErrorType.AUTHENTICATION;
      }
      
      if (message.includes('permission') || message.includes('denied')) {
        return ErrorType.PERMISSION;
      }
      
      if (message.includes('file') || message.includes('path')) {
        return ErrorType.FILE;
      }
      
      if (message.includes('parse') || message.includes('json') || message.includes('xml')) {
        return ErrorType.PARSING;
      }
      
      if (message.includes('business') || message.includes('validation')) {
        return ErrorType.BUSINESS;
      }
      
      if (message.includes('system') || message.includes('memory') || message.includes('resource')) {
        return ErrorType.SYSTEM;
      }
    }
    
    return ErrorType.UNKNOWN;
  }
  
  /**
   * 确定错误码
   * @param error 错误对象
   */
  private determineErrorCode(error: any): ErrorCode {
    if (error instanceof Error) {
      const message = error.message.toLowerCase();
      
      // 网络错误
      if (message.includes('timeout')) return ErrorCode.NETWORK_TIMEOUT;
      if (message.includes('connection')) return ErrorCode.NETWORK_CONNECTION;
      if (message.includes('response')) return ErrorCode.NETWORK_RESPONSE;
      if (message.includes('ssl') || message.includes('certificate')) return ErrorCode.NETWORK_SSL;
      
      // 认证错误
      if (message.includes('invalid') && message.includes('credential')) return ErrorCode.AUTH_INVALID_CREDENTIALS;
      if (message.includes('token') && message.includes('expired')) return ErrorCode.AUTH_TOKEN_EXPIRED;
      if (message.includes('forbidden')) return ErrorCode.AUTH_FORBIDDEN;
      
      // 权限错误
      if (message.includes('permission') && message.includes('denied')) return ErrorCode.PERMISSION_DENIED;
      if (message.includes('permission') && message.includes('missing')) return ErrorCode.PERMISSION_MISSING;
      
      // 文件操作错误
      if (message.includes('not found')) return ErrorCode.FILE_NOT_FOUND;
      if (message.includes('access denied')) return ErrorCode.FILE_ACCESS_DENIED;
      if (message.includes('read error')) return ErrorCode.FILE_READ_ERROR;
      if (message.includes('write error')) return ErrorCode.FILE_WRITE_ERROR;
      
      // 解析错误
      if (message.includes('json')) return ErrorCode.PARSING_JSON;
      if (message.includes('xml')) return ErrorCode.PARSING_XML;
      if (message.includes('url')) return ErrorCode.PARSING_URL;
    }
    
    return ErrorCode.UNKNOWN_ERROR;
  }
  
  /**
   * 获取错误消息
   * @param error 错误对象
   */
  private getErrorMessage(error: any): string {
    if (error instanceof Error) {
      return error.message;
    }
    if (typeof error === 'string') {
      return error;
    }
    if (error && typeof error === 'object' && 'message' in error) {
      return String(error.message);
    }
    return 'Unknown error';
  }
  
  /**
   * 获取错误详情
   * @param error 错误对象
   */
  private getErrorDetails(error: any): any {
    if (error instanceof Error) {
      return {
        name: error.name,
        message: error.message,
        stack: error.stack
      };
    }
    if (typeof error === 'object' && error !== null) {
      return error;
    }
    return { value: error };
  }
  
  /**
   * 记录错误日志
   * @param errorInfo 错误信息
   */
  private logError(errorInfo: ErrorInfo): void {
    const { type, code, message, location, details } = errorInfo;
    const logMessage = `[${type}] [${code}] ${message}${location ? ` (${location})` : ''}`;
    
    switch (type) {
      case ErrorType.NETWORK:
      case ErrorType.AUTHENTICATION:
      case ErrorType.PERMISSION:
        this.logger.warn(logMessage, details);
        break;
      case ErrorType.FILE:
      case ErrorType.PARSING:
      case ErrorType.BUSINESS:
        this.logger.error(logMessage, details);
        break;
      case ErrorType.SYSTEM:
      case ErrorType.UNKNOWN:
        this.logger.error(logMessage, details);
        break;
    }
  }
  
  /**
   * 缓存错误信息
   * @param errorInfo 错误信息
   */
  private cacheError(errorInfo: ErrorInfo): void {
    const key = errorInfo.type;
    if (!this.errorCache.has(key)) {
      this.errorCache.set(key, []);
    }
    
    const errorList = this.errorCache.get(key)!;
    errorList.push(errorInfo);
    
    // 限制缓存大小
    if (errorList.length > this.maxErrorCacheSize) {
      errorList.shift();
    }
  }
  
  /**
   * 获取错误统计
   */
  public getErrorStats(): Record<ErrorType, number> {
    const stats: Record<ErrorType, number> = {
      [ErrorType.NETWORK]: 0,
      [ErrorType.AUTHENTICATION]: 0,
      [ErrorType.PERMISSION]: 0,
      [ErrorType.FILE]: 0,
      [ErrorType.PARSING]: 0,
      [ErrorType.BUSINESS]: 0,
      [ErrorType.SYSTEM]: 0,
      [ErrorType.UNKNOWN]: 0
    };
    
    this.errorCache.forEach((errors, type) => {
      stats[type as ErrorType] = errors.length;
    });
    
    return stats;
  }
  
  /**
   * 获取最近的错误
   * @param type 错误类型
   * @param limit 限制数量
   */
  public getRecentErrors(type?: ErrorType, limit: number = 10): ErrorInfo[] {
    if (type) {
      const errors = this.errorCache.get(type) || [];
      return errors.slice(-limit);
    } else {
      // 获取所有类型的错误
      const allErrors: ErrorInfo[] = [];
      this.errorCache.forEach(errors => {
        allErrors.push(...errors);
      });
      // 按时间排序
      allErrors.sort((a, b) => b.timestamp - a.timestamp);
      return allErrors.slice(0, limit);
    }
  }
  
  /**
   * 清除错误缓存
   * @param type 错误类型
   */
  public clearErrorCache(type?: ErrorType): void {
    if (type) {
      this.errorCache.delete(type);
    } else {
      this.errorCache.clear();
    }
    this.logger.info(`Error cache cleared${type ? ` for ${type}` : ''}`);
  }
  
  /**
   * 处理网络错误
   * @param error 错误对象
   * @param url 请求URL
   */
  public handleNetworkError(error: any, url: string): ErrorInfo {
    return this.captureError(error, {
      type: ErrorType.NETWORK,
      location: `Network request to ${url}`,
      details: { url }
    });
  }
  
  /**
   * 处理认证错误
   * @param error 错误对象
   * @param provider 认证提供者
   */
  public handleAuthError(error: any, provider: string): ErrorInfo {
    return this.captureError(error, {
      type: ErrorType.AUTHENTICATION,
      location: `Authentication with ${provider}`,
      details: { provider }
    });
  }
  
  /**
   * 处理文件错误
   * @param error 错误对象
   * @param filePath 文件路径
   */
  public handleFileError(error: any, filePath: string): ErrorInfo {
    return this.captureError(error, {
      type: ErrorType.FILE,
      location: `File operation on ${filePath}`,
      details: { filePath }
    });
  }
  
  /**
   * 处理解析错误
   * @param error 错误对象
   * @param dataType 数据类型
   */
  public handleParsingError(error: any, dataType: string): ErrorInfo {
    return this.captureError(error, {
      type: ErrorType.PARSING,
      location: `Parsing ${dataType} data`,
      details: { dataType }
    });
  }
  
  /**
   * 处理业务逻辑错误
   * @param error 错误对象
   * @param operation 操作名称
   */
  public handleBusinessError(error: any, operation: string): ErrorInfo {
    return this.captureError(error, {
      type: ErrorType.BUSINESS,
      location: `Business operation: ${operation}`,
      details: { operation }
    });
  }
  
  /**
   * 处理系统错误
   * @param error 错误对象
   * @param component 组件名称
   */
  public handleSystemError(error: any, component: string): ErrorInfo {
    return this.captureError(error, {
      type: ErrorType.SYSTEM,
      location: `System component: ${component}`,
      details: { component }
    });
  }
  
  /**
   * 生成用户友好的错误消息
   * @param errorInfo 错误信息
   */
  public getUserFriendlyMessage(errorInfo: ErrorInfo): string {
    switch (errorInfo.type) {
      case ErrorType.NETWORK:
        return '网络连接失败，请检查您的网络设置后重试';
      case ErrorType.AUTHENTICATION:
        return '认证失败，请重新登录后重试';
      case ErrorType.PERMISSION:
        return '权限不足，请检查应用权限设置';
      case ErrorType.FILE:
        return '文件操作失败，请检查文件权限';
      case ErrorType.PARSING:
        return '数据解析失败，请稍后重试';
      case ErrorType.BUSINESS:
        return '操作失败，请稍后重试';
      case ErrorType.SYSTEM:
        return '系统错误，请重启应用后重试';
      default:
        return '发生未知错误，请稍后重试';
    }
  }
  
  /**
   * 检查是否是可恢复的错误
   * @param errorInfo 错误信息
   */
  public isRecoverable(errorInfo: ErrorInfo): boolean {
    return [
      ErrorType.NETWORK,
      ErrorType.AUTHENTICATION,
      ErrorType.PERMISSION,
      ErrorType.FILE,
      ErrorType.PARSING,
      ErrorType.BUSINESS
    ].includes(errorInfo.type);
  }
  
  /**
   * 获取错误恢复建议
   * @param errorInfo 错误信息
   */
  public getRecoverySuggestion(errorInfo: ErrorInfo): string {
    switch (errorInfo.type) {
      case ErrorType.NETWORK:
        return '请检查网络连接，确保设备已连接到互联网';
      case ErrorType.AUTHENTICATION:
        return '请重新登录，确保您的账号信息正确';
      case ErrorType.PERMISSION:
        return '请在系统设置中授予应用所需的权限';
      case ErrorType.FILE:
        return '请检查文件路径是否正确，确保您有访问权限';
      case ErrorType.PARSING:
        return '请检查数据格式是否正确，或稍后重试';
      case ErrorType.BUSINESS:
        return '请检查输入参数是否正确，或稍后重试';
      case ErrorType.SYSTEM:
        return '请重启应用，或检查设备存储空间是否充足';
      default:
        return '请稍后重试，或联系客服寻求帮助';
    }
  }
  
  /**
   * 销毁服务
   */
  public destroy(): void {
    this.clearErrorCache();
    this.logger.info('错误处理服务已销毁');
  }
}

// 导出单例实例
export default ErrorService.getInstance();
