/**
 * 网络工具类
 * 提供网络请求、响应处理、错误重试等网络相关功能
 */
import Logger from './Logger';
import http from '@ohos.net.http';
import connection from '@ohos.net.connection';
import fs from '@ohos.file.fs';
import promptAction from '@ohos.promptAction';

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
  params?: Record<string, unknown>;
  data?: unknown;
  timeout?: number;
  retryCount?: number;
  baseURL?: string;
}

/**
 * 响应接口
 */
export interface ApiResponse<T = unknown> {
  code: number;
  message: string;
  data: T;
}

/**
 * 错误类型
 */
export class NetworkError extends Error {
  code: string;
  response?: unknown;
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
  private static checkResponseStatus(response: http.HttpResponse): boolean {
    return response.responseCode >= 200 && response.responseCode < 300;
  }
  
  /**
   * 处理网络错误
   */
  private static handleNetworkError(error: unknown): never {
    if (typeof error === 'object' && error !== null && 'code' in error) {
        const errorObj = error as { code?: unknown; message?: string };
        if (errorObj.code === 19 || errorObj.code === 28) {
          throw new NetworkError('Request timeout', 'TIMEOUT', error);
        }
        throw new NetworkError(
          errorObj.message || 'Unknown network error',
          'NETWORK_ERROR',
          error
        );
      }
      
      throw new NetworkError(
        String(error),
        'NETWORK_ERROR',
        error
      );
  }
  
  /**
   * 带重试机制的请求
   */
  private static async requestWithRetry<T = unknown>(
    config: RequestConfig,
    retryCount: number = 0
  ): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    const timeout = config.timeout || REQUEST_TIMEOUT;
    
    try {
      // 设置超时
      httpRequest.setTimeout({ connectTimeout: timeout });
      
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
      
      // 转换请求方法
      let method: http.RequestMethod = http.RequestMethod.GET;
      switch (config.method) {
        case 'POST':
          method = http.RequestMethod.POST;
          break;
        case 'PUT':
          method = http.RequestMethod.PUT;
          break;
        case 'DELETE':
          method = http.RequestMethod.DELETE;
          break;
        case 'PATCH':
          method = http.RequestMethod.PATCH;
          break;
        default:
          method = http.RequestMethod.GET;
      }
      
      const response = await httpRequest.request(url, {
        method,
        header: headers,
        extraData: config.data ? JSON.stringify(config.data) : undefined,
      });
      
      const endTime = Date.now();
      Logger.debug(this.TAG, `Response received in ${endTime - startTime}ms`);
      
      // 释放资源
      httpRequest.destroy();
      
      if (!this.checkResponseStatus(response)) {
        Logger.error(this.TAG, `HTTP Error: ${response.responseCode}`);
        
        // 对于5xx错误，尝试重试
        if (response.responseCode >= 500 && retryCount < (config.retryCount || MAX_RETRY_COUNT)) {
          Logger.warn(this.TAG, `Retrying request (${retryCount + 1}/${config.retryCount || MAX_RETRY_COUNT})`);
          // 指数退避
          await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, retryCount)));
          return NetworkUtils.requestWithRetry(config, retryCount + 1);
        }
        
        throw new NetworkError(
          `HTTP error ${response.responseCode}`,
          'HTTP_ERROR',
          response,
          response.responseCode
        );
      }
      
      // 解析响应数据
      let data: ApiResponse<T>;
      try {
        data = JSON.parse(response.result.toString());
      } catch (parseError) {
        // 如果不是JSON，直接返回结果
        data = { code: 200, message: 'Success', data: response.result } as ApiResponse<T>;
      }
      
      Logger.debug(this.TAG, `Response data: ${JSON.stringify(data)}`);
      
      return data;
    } catch (error) {
      // 释放资源
      try {
        httpRequest.destroy();
      } catch (e) {
        // 忽略销毁时的错误
      }
      
      // 对于网络错误，尝试重试
      if (retryCount < (config.retryCount || MAX_RETRY_COUNT) && 
          !(error instanceof NetworkError && error.code === 'TIMEOUT')) {
        Logger.warn(this.TAG, `Retrying request due to network error (${retryCount + 1}/${config.retryCount || MAX_RETRY_COUNT})`);
        await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, retryCount)));
        return NetworkUtils.requestWithRetry(config, retryCount + 1);
      }
      
      NetworkUtils.handleNetworkError(error);
    }
  }
  
  /**
   * GET请求
   */
  public static async get<T = unknown>(url: string, config?: Omit<RequestConfig, 'url' | 'method'>): Promise<ApiResponse<T>> {
    return NetworkUtils.requestWithRetry<T>({
      ...config,
      url,
      method: 'GET',
    });
  }
  
  /**
   * POST请求
   */
  public static async post<T = unknown>(url: string, data?: unknown, config?: Omit<RequestConfig, 'url' | 'method' | 'data'>): Promise<ApiResponse<T>> {
    return NetworkUtils.requestWithRetry<T>({
      ...config,
      url,
      method: 'POST',
      data,
    });
  }
  
  /**
   * PUT请求
   */
  public static async put<T = unknown>(url: string, data?: unknown, config?: Omit<RequestConfig, 'url' | 'method' | 'data'>): Promise<ApiResponse<T>> {
    return NetworkUtils.requestWithRetry<T>({
      ...config,
      url,
      method: 'PUT',
      data,
    });
  }
  
  /**
   * DELETE请求
   */
  public static async delete<T = unknown>(url: string, config?: Omit<RequestConfig, 'url' | 'method'>): Promise<ApiResponse<T>> {
    return NetworkUtils.requestWithRetry<T>({
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
      // 使用HarmonyOS原生网络连接API检查
      const netCap = await connection.getDefaultNetCapabilities();
      const isConnected = netCap && netCap.netBearerType !== connection.NetBearType.NONE;
      
      Logger.info(this.TAG, `Connectivity check: ${isConnected ? 'connected' : 'disconnected'}`);
      
      // 如果检测到连接，进行简单的请求验证
      if (isConnected) {
        try {
          const httpRequest = http.createHttp();
          httpRequest.setTimeout({ connectTimeout: 5000 });
          const response = await httpRequest.request('https://www.baidu.com', {
            method: http.RequestMethod.HEAD
          });
          httpRequest.destroy();
          return response.responseCode >= 200 && response.responseCode < 300;
        } catch (reqError) {
          Logger.warn(this.TAG, `Connection test failed despite network being available: ${reqError}`);
          return false;
        }
      }
      
      return false;
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
      
      // 获取应用的文件目录
      const context = getContext();
      const filesDir = context.filesDir;
      const filePath = `${filesDir}/${filename}`;
      
      // 使用HTTP请求下载文件
      const httpRequest = http.createHttp();
      try {
        const response = await httpRequest.downloadFile(url, {
          filePath: filePath,
          enableCache: false
        });
        
        if (response.responseCode !== 200) {
          throw new NetworkError(
            `Download failed with status ${response.responseCode}`,
            'DOWNLOAD_ERROR',
            response,
            response.responseCode
          );
        }
        
        Logger.info(this.TAG, `File downloaded successfully: ${filename}`);
        
        // 通知用户下载完成
        try {
          await promptAction.showToast({
            message: `文件下载完成: ${filename}`,
            duration: 2000
          });
        } catch (toastError) {
          // 忽略toast错误
          Logger.warn(this.TAG, `Failed to show toast: ${toastError}`);
        }
        
        return true;
      } finally {
        // 释放资源
        httpRequest.destroy();
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to download file: ${error}`);
      return false;
    }
  }
}

export default NetworkUtils;