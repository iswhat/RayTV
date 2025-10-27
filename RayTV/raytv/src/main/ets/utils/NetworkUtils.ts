/**
 * 网络工具类
 * 提供网络请求、响应处理、错误重试等网络相关功能
 */
import Logger from './Logger';

// 网络请求超时时间
const REQUEST_TIMEOUT = 30000; // 30秒

// 最大重试次数
const MAX_RETRY_COUNT = 3;

// 默认请求头
const DEFAULT_HEADERS = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

/**
 * 请求配置接口
 */
export interface RequestConfig {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  params?: Record<string, any>;
  data?: any;
  timeout?: number;
  retryCount?: number;
  baseURL?: string;
}

/**
 * 响应接口
 */
export interface ApiResponse<T = any> {
  code: number;
  message: string;
  data: T;
}

/**
 * 错误类型
 */
export class NetworkError extends Error {
  code: string;
  response?: any;
  status?: number;

  constructor(message: string, code: string, response?: any, status?: number) {
    super(message);
    this.name = 'NetworkError';
    this.code = code;
    this.response = response;
    this.status = status;
  }
}

/**
 * 网络工具类
 */
export class NetworkUtils {
  private static readonly TAG = 'NetworkUtils';
  private static baseURL: string = '';
  
  /**
   * 设置基础URL
   */
  public static setBaseURL(url: string): void {
    this.baseURL = url;
    Logger.info(this.TAG, `Base URL set to: ${url}`);
  }
  
  /**
   * 构建完整URL
   */
  private static buildURL(config: RequestConfig): string {
    const baseURL = config.baseURL || this.baseURL;
    const url = config.url.startsWith('http') ? config.url : `${baseURL}${config.url}`;
    
    // 添加查询参数
    if (config.params) {
      const params = new URLSearchParams();
      Object.entries(config.params).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          params.append(key, String(value));
        }
      });
      
      const paramsString = params.toString();
      if (paramsString) {
        const separator = url.includes('?') ? '&' : '?';
        return `${url}${separator}${paramsString}`;
      }
    }
    
    return url;
  }
  
  /**
   * 合并请求头
   */
  private static mergeHeaders(config: RequestConfig): Record<string, string> {
    return {
      ...DEFAULT_HEADERS,
      ...config.headers,
    };
  }
  
  /**
   * 检查响应状态
   */
  private static checkResponseStatus(response: Response): boolean {
    return response.status >= 200 && response.status < 300;
  }
  
  /**
   * 处理网络错误
   */
  private static handleNetworkError(error: any): never {
    if (error.name === 'AbortError') {
      throw new NetworkError('Request timeout', 'TIMEOUT', error);
    }
    
    if (error.response) {
      throw new NetworkError(
        error.response.statusText || 'Network error',
        'HTTP_ERROR',
        error.response,
        error.response.status
      );
    }
    
    throw new NetworkError(
      error.message || 'Unknown network error',
      'NETWORK_ERROR',
      error
    );
  }
  
  /**
   * 带重试机制的请求
   */
  private static async requestWithRetry<T = any>(
    config: RequestConfig,
    retryCount: number = 0
  ): Promise<ApiResponse<T>> {
    const abortController = new AbortController();
    const timeout = config.timeout || REQUEST_TIMEOUT;
    
    // 设置超时
    const timeoutId = setTimeout(() => {
      abortController.abort();
    }, timeout);
    
    try {
      const url = this.buildURL(config);
      const headers = this.mergeHeaders(config);
      
      Logger.debug(this.TAG, `Request: ${config.method || 'GET'} ${url}`);
      if (config.params) {
        Logger.debug(this.TAG, `Request params: ${JSON.stringify(config.params)}`);
      }
      if (config.data) {
        Logger.debug(this.TAG, `Request data: ${JSON.stringify(config.data)}`);
      }
      
      const startTime = Date.now();
      
      const response = await fetch(url, {
        method: config.method || 'GET',
        headers,
        body: config.data ? JSON.stringify(config.data) : undefined,
        signal: abortController.signal,
      });
      
      const endTime = Date.now();
      Logger.debug(this.TAG, `Response received in ${endTime - startTime}ms`);
      
      clearTimeout(timeoutId);
      
      if (!this.checkResponseStatus(response)) {
        Logger.error(this.TAG, `HTTP Error: ${response.status} ${response.statusText}`);
        
        // 对于5xx错误，尝试重试
        if (response.status >= 500 && retryCount < (config.retryCount || MAX_RETRY_COUNT)) {
          Logger.warn(this.TAG, `Retrying request (${retryCount + 1}/${config.retryCount || MAX_RETRY_COUNT})`);
          // 指数退避
          await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, retryCount)));
          return this.requestWithRetry(config, retryCount + 1);
        }
        
        throw new NetworkError(
          response.statusText || 'HTTP error',
          'HTTP_ERROR',
          response,
          response.status
        );
      }
      
      const data = await response.json();
      Logger.debug(this.TAG, `Response data: ${JSON.stringify(data)}`);
      
      return data;
    } catch (error) {
      clearTimeout(timeoutId);
      
      // 对于网络错误，尝试重试
      if (retryCount < (config.retryCount || MAX_RETRY_COUNT) && 
          !(error instanceof NetworkError && error.code === 'TIMEOUT')) {
        Logger.warn(this.TAG, `Retrying request due to network error (${retryCount + 1}/${config.retryCount || MAX_RETRY_COUNT})`);
        await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, retryCount)));
        return this.requestWithRetry(config, retryCount + 1);
      }
      
      this.handleNetworkError(error);
    }
  }
  
  /**
   * GET请求
   */
  public static async get<T = any>(url: string, config?: Omit<RequestConfig, 'url' | 'method'>): Promise<ApiResponse<T>> {
    return this.requestWithRetry<T>({
      ...config,
      url,
      method: 'GET',
    });
  }
  
  /**
   * POST请求
   */
  public static async post<T = any>(url: string, data?: any, config?: Omit<RequestConfig, 'url' | 'method' | 'data'>): Promise<ApiResponse<T>> {
    return this.requestWithRetry<T>({
      ...config,
      url,
      method: 'POST',
      data,
    });
  }
  
  /**
   * PUT请求
   */
  public static async put<T = any>(url: string, data?: any, config?: Omit<RequestConfig, 'url' | 'method' | 'data'>): Promise<ApiResponse<T>> {
    return this.requestWithRetry<T>({
      ...config,
      url,
      method: 'PUT',
      data,
    });
  }
  
  /**
   * DELETE请求
   */
  public static async delete<T = any>(url: string, config?: Omit<RequestConfig, 'url' | 'method'>): Promise<ApiResponse<T>> {
    return this.requestWithRetry<T>({
      ...config,
      url,
      method: 'DELETE',
    });
  }
  
  /**
   * 检查网络连接
   */
  public static async checkConnectivity(): Promise<boolean> {
    try {
      // 使用navigator.onLine检查
      if (typeof navigator !== 'undefined' && 'onLine' in navigator) {
        if (!navigator.onLine) {
          Logger.warn(this.TAG, 'No internet connection detected by navigator.onLine');
          return false;
        }
      }
      
      // 尝试一个简单的请求验证
      const response = await fetch('https://www.google.com/generate_204', {
        method: 'HEAD',
        cache: 'no-cache',
      });
      
      const isConnected = response.ok;
      Logger.info(this.TAG, `Connectivity check: ${isConnected ? 'connected' : 'disconnected'}`);
      return isConnected;
    } catch (error) {
      Logger.error(this.TAG, `Connectivity check failed: ${error}`);
      return false;
    }
  }
  
  /**
   * 下载文件
   */
  public static async downloadFile(url: string, filename: string): Promise<boolean> {
    try {
      Logger.info(this.TAG, `Downloading file from ${url} to ${filename}`);
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new NetworkError(
          `Download failed with status ${response.status}`,
          'DOWNLOAD_ERROR',
          response,
          response.status
        );
      }
      
      const blob = await response.blob();
      
      // 创建下载链接
      const a = document.createElement('a');
      const urlBlob = URL.createObjectURL(blob);
      a.href = urlBlob;
      a.download = filename;
      
      // 触发下载
      document.body.appendChild(a);
      a.click();
      
      // 清理
      setTimeout(() => {
        document.body.removeChild(a);
        URL.revokeObjectURL(urlBlob);
      }, 100);
      
      Logger.info(this.TAG, `File downloaded successfully: ${filename}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to download file: ${error}`);
      return false;
    }
  }
}

export default NetworkUtils;