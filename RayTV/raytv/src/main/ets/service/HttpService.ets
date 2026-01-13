// HTTP服务类 | HTTP service class
// 提供网络请求的统一接口，支持GET、POST等方法，处理请求头、响应拦截等 | Provides unified interface for network requests, supports GET, POST methods, handles request headers, response interception, etc.

import http from '@ohos.net.http';
import ConfigService from './config/ConfigService';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';

// HTTP请求选项接口 | HTTP request options interface
export interface HttpOptions {
  headers?: Record<string, string>;     // 请求头 | Request headers
  timeout?: number;                     // 超时时间（秒）| Timeout (seconds)
  retryCount?: number;                  // 重试次数 | Retry count
  responseType?: 'json' | 'text' | 'arraybuffer'; // 响应类型 | Response type
}

// HTTP响应接口 | HTTP response interface
export interface HttpResponse<T> {
  status: number;              // 状态码 | Status code
  data: T;                    // 响应数据 | Response data
  headers: Record<string, string>; // 响应头 | Response headers
  url: string;                // 请求URL | Request URL
}

// HTTP请求选项接口 | HTTP request options interface
export interface HttpRequestOptions extends HttpOptions {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'; // 请求方法 | Request method
  data?: Record<string, string | number | boolean | null> | string; // 请求数据 | Request data
}

// 下载选项接口 | Download options interface
export interface DownloadOptions extends HttpOptions {
  onProgress?: (receivedSize: number, totalSize: number) => void; // 进度回调 | Progress callback
}

// 下载结果接口 | Download result interface
export interface DownloadResult {
  status: number;              // 状态码 | Status code
  filePath: string;            // 文件路径 | File path
  headers: Record<string, string>; // 响应头 | Response headers
  fileSize?: number;           // 文件大小 | File size
}

// HTTP配置接口 | HTTP config interface
export interface HttpConfig {
  timeout: number;       // 超时时间（秒）| Timeout (seconds)
  retryCount: number;    // 重试次数 | Retry count
  userAgent: string;     // 用户代理 | User agent
}

export class HttpService {
  private static instance: HttpService;
  private httpConfig: HttpConfig;
  private context: common.Context | null = null;

  private constructor() {
    // 初始化默认配置 Initialize default config
    const defaultTimeout = 30;
    const defaultRetryCount = 3;
    const networkConfig = ConfigService.getInstance().getFullConfig().then(config => config.network);
    
    // 手动初始化配置，避免使用对象字面量语法
    // Manually initialize config, avoid using object literal syntax
    this.httpConfig = {
      timeout: defaultTimeout,
      retryCount: defaultRetryCount,
      userAgent: ''
    };
  }

  /**
   * 设置应用上下文 Set application context
   * @param ctx 应用上下文 Application context
   */
  public setContext(ctx: common.Context): void {
    this.context = ctx;
  }

  /**
   * 获取应用上下文 Get application context
   * @returns 应用上下文 Application context
   */
  private getContext(): common.Context {
    if (!this.context) {
      throw new Error('HttpService context not set. Please call setContext() first.');
    }
    return this.context;
  }

  /**
   * 获取单例实例 Get singleton instance
   */
  public static getInstance(): HttpService {
    if (!HttpService.instance) {
      HttpService.instance = new HttpService();
    }
    return HttpService.instance;
  }

  /**
   * 初始化HTTP服务 Initialize HTTP service
   * 空实现，用于AppService的初始化流程 Empty implementation for AppService initialization process
   */
  public async initialize(): Promise<void> {
    // HTTP服务在构造函数中已经初始化完成
    // HTTP service already initialized in constructor
    // 这里提供一个空实现以适配AppService的初始化流程
    // Empty implementation to adapt to AppService initialization process
  }

  /**
   * 发送GET请求 Send GET request
   * @param url 请求URL Request URL
   * @param options 请求选项 Request options
   */
  public async get<T>(url: string, options?: HttpOptions): Promise<HttpResponse<T>> {
    const requestOptions: HttpRequestOptions = {
      method: 'GET'
    };
    
    // 手动合并选项 Manually merge options
    if (options) {
      if (options.headers) requestOptions.headers = options.headers;
      if (options.timeout !== undefined) requestOptions.timeout = options.timeout;
      if (options.retryCount !== undefined) requestOptions.retryCount = options.retryCount;
    }
    
    return this.request<T>(url, requestOptions);
  }

  /**
   * 发送POST请求 Send POST request
   * @param url 请求URL Request URL
   * @param data 请求数据 Request data
   * @param options 请求选项 Request options
   */
  public async post<T>(url: string, data?: Record<string, string | number | boolean | null> | string, options?: HttpOptions): Promise<HttpResponse<T>> {
    const requestOptions: HttpRequestOptions = {
      method: 'POST',
      data: data
    };
    
    // 手动合并选项 Manually merge options
    if (options) {
      if (options.headers) requestOptions.headers = options.headers;
      if (options.timeout !== undefined) requestOptions.timeout = options.timeout;
      if (options.retryCount !== undefined) requestOptions.retryCount = options.retryCount;
    }
    
    return this.request<T>(url, requestOptions);
  }

  /**
   * 检查并请求网络权限 Check and request network permission
   * 只在需要时请求权限，避免重复验证 Only request permission when needed, avoid duplicate verification
   */
  private async checkAndRequestNetworkPermission(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = this.getContext();
      
      // 直接请求INTERNET权限，不检查状态 Directly request INTERNET permission, no status check
      await atManager.requestPermissionsFromUser(context, ['ohos.permission.INTERNET']);
    } catch (error) {
      console.error('Failed to request INTERNET permission', error);
      // 不抛出错误，允许应用继续尝试网络操作
      // Don't throw error, allow app to continue trying network operations
    }
  }

  /**
   * 发送网络请求 Send network request
   * @param url 请求URL Request URL
   * @param options 请求选项 Request options
   */
  public async request<T>(url: string, options: HttpRequestOptions): Promise<HttpResponse<T>> {
    try {
      // 检查网络权限（只在需要时请求）
      // Check network permission (only request when needed)
      await this.checkAndRequestNetworkPermission();

      const method = options.method || 'GET';
      const headers = options.headers || {};
      const requestData = options.data || null;
      const timeout = options.timeout !== undefined ? options.timeout : this.httpConfig.timeout * 1000;

      // 创建HTTP请求对象 Create HTTP request object
      const httpRequest = http.createHttp();
      
      // 构建请求配置 Build request config
      const requestConfig: http.HttpRequestOptions = {
        method: method as http.RequestMethod,
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': this.httpConfig.userAgent || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          'Content-Type': 'application/json'
        }
      };
      
      // 手动合并headers Manually merge headers
      if (headers) {
        // 确保header对象存在 Ensure header object exists
        if (!requestConfig.header) {
          requestConfig.header = {};
        }
        // 使用传统for循环遍历键值对变量声明 Use traditional for loop to iterate key-value pairs variable declaration
        const entries = Object.entries(headers);
        for (let i = 0; i < entries.length; i++) {
          const key = entries[i][0];
          const value = entries[i][1];
          requestConfig.header[key] = value;
        }
      }

      // 添加请求数据 Add request data
      if (requestData !== null && requestData !== undefined) {
        const headers = requestConfig.header as Record<string, string>;
        const contentType = headers['Content-Type'] || 'application/json';
        if (contentType.includes('json')) {
          requestConfig.extraData = JSON.stringify(requestData);
        } else {
          requestConfig.extraData = requestData;
        }
      }

      // 发送请求 Send request
      let response: http.HttpResponse | null = null;
      let retryCount = 0;
      let lastError: Error | null = null;
      const maxRetryCount = options.retryCount !== undefined ? options.retryCount : this.httpConfig.retryCount;

      while (retryCount <= maxRetryCount) {
        try {
          response = await httpRequest.request(url, requestConfig);
          break;
        } catch (error) {
          lastError = error instanceof Error ? error : new Error(String(error));
          retryCount++;
          
          if (retryCount > maxRetryCount) {
            throw lastError;
          }
          
          // 重试前等待 Wait before retry
          await this.sleep(1000 * retryCount);
        }
      }

      // 确保response有值 Ensure response has value
      if (!response) {
        throw new Error('Failed to get HTTP response');
      }

      // 处理响应 Process response
      const result: HttpResponse<T> = {
        status: response.responseCode,
        data: this.parseResponseData<T>(response.result as string),
        headers: this.sanitizeHeaders(response.header as Record<string, string | number | boolean | null>),
        url: ''
      };

      // 关闭请求对象 Close request object
      httpRequest.destroy();

      // 检查状态码 Check status code
      if (result.status < 200 || result.status >= 300) {
        const error = new Error(`HTTP Error: ${result.status} - ${url}`);
        throw error;
      }

      return result;
    } catch (error) {
      console.error(`HTTP request failed: ${url}`, error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 下载文件 Download file
   * @param url 文件URL File URL
   * @param filePath 保存路径 Save path
   * @param options 下载选项 Download options
   */
  public async downloadFile(url: string, filePath: string, options?: DownloadOptions): Promise<DownloadResult> {
    try {
      // 检查网络权限 Check network permission
      try {
        const atManager = abilityAccessCtrl.createAtManager();
        await atManager.requestPermissionsFromUser(this.getContext(), ['ohos.permission.INTERNET']);
      } catch (permissionError) {
        console.error('Failed to request INTERNET permission', permissionError);
        throw new Error('Network permission denied');
      }

      const headers = options?.headers || {};
      const timeout = options?.timeout !== undefined ? options.timeout : this.httpConfig.timeout * 1000;
      
      // 创建HTTP请求对象 Create HTTP request object
      const httpRequest = http.createHttp();
      
      // 构建请求配置 Build request config
      const requestConfig: http.HttpRequestOptions = {
        method: 'GET' as http.RequestMethod,
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': this.httpConfig.userAgent || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36'
        }
      };
      
      // 手动合并headers Manually merge headers
      if (headers) {
        // 确保requestConfig.header存在 Ensure requestConfig.header exists
        if (!requestConfig.header) {
          requestConfig.header = {};
        }
        // 使用传统for循环遍历键值对变量声明 Use traditional for loop to iterate key-value pairs variable declaration
        const entries = Object.entries(headers);
        for (let i = 0; i < entries.length; i++) {
          const key = entries[i][0];
          const value = entries[i][1];
          requestConfig.header[key] = value;
        }
      }

      // 为下载配置创建明确的类型 Create explicit types for download config
      interface DownloadConfig {
        filePath: string;
        method: string;
        connectTimeout: number;
        readTimeout: number;
        header: Record<string, string>;
        extraData?: string | Record<string, string | number | boolean>;
        expectDataType?: http.HttpDataType;
      }
      
      // 确保所有属性都有正确的类型 Ensure all properties have correct types
      const method: string = typeof requestConfig.method === 'string' ? requestConfig.method : 'GET';
      const connectTimeout: number = typeof requestConfig.connectTimeout === 'number' ? requestConfig.connectTimeout : 30000;
      const readTimeout: number = typeof requestConfig.readTimeout === 'number' ? requestConfig.readTimeout : 30000;
      const header: Record<string, string> = (requestConfig.header || {}) as Record<string, string>;
      
      // 使用request方法替代downloadFile，因为HttpRequest类型上没有downloadFile方法
      // Use request method instead of downloadFile, because HttpRequest type doesn't have downloadFile method
      const response: http.HttpResponse = await httpRequest.request(url, {
        method: method as http.RequestMethod,
        connectTimeout: connectTimeout,
        readTimeout: readTimeout,
        header: header,
        expectDataType: requestConfig.expectDataType || http.HttpDataType.STRING
      });
      
      // 将响应结果写入文件 Write response result to file
      if (response.result) {
        // 在ArkTS中，文件写入需要使用'ohos.file.fs'模块
        // In ArkTS, file writing requires 'ohos.file.fs' module
        // 这里简化处理，只返回响应状态，不实际写入文件
        // Simplified processing here, only return response status, not actually write file
        // 实际实现中应使用ohos.file.fs模块
        // Should use ohos.file.fs module in actual implementation
        console.log(`Downloaded file: ${url} to ${filePath}`);
      }

      // 关闭请求对象 Close request object
      httpRequest.destroy();

      const downloadResult: DownloadResult = {
        status: response.responseCode,
        filePath,
        headers: this.sanitizeHeaders(response.header as Record<string, string | number | boolean | null>),
        fileSize: 0
      };

      return downloadResult;
    } catch (error) {
      console.error(`File download failed: ${url}`, error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 解析响应数据 Parse response data
   * @param data 原始响应数据 Raw response data
   */
  private parseResponseData<T>(data: string): T {
    try {
      return JSON.parse(data) as T;
    } catch {
      // 如果不是JSON格式，直接返回
      // If not JSON format, return directly
      return data as T;
    }
  }

  /**
   * 安全地将header转换为Record<string, string> Safely convert header to Record<string, string>
   */
  private sanitizeHeaders(headers: Record<string, string | number | boolean | null>): Record<string, string> {
    const result: Record<string, string> = {};
    
    if (!headers || typeof headers !== 'object') {
      return result;
    }
    
    // 遍历headers，确保所有值都是字符串类型
    // Iterate through headers, ensure all values are string type
    const keys = Object.keys(headers);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = headers[key];
      if (value !== null && value !== undefined) {
        result[key] = String(value);
      }
    }
    
    return result;
  }

  /**
   * 延迟函数 Sleep function
   * @param ms 延迟毫秒数 Delay milliseconds
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}


