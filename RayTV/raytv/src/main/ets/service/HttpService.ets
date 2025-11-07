// HTTP服务类
// 提供网络请求的统一接口，支持GET、POST等方法，处理请求头、响应拦截等

import http from '@ohos.net.http';
import { ConfigService } from './config/ConfigService';
import { AdBlockManager } from './adblock/AdBlockManager';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';

export class HttpService {
  private static instance: HttpService;
  private httpConfig: Record<string, string | number>;
  private adBlockManager: AdBlockManager;
  private context: common.Context | null = null;

  private constructor() {
    // 初始化默认配置
    const defaultConfig = {
      timeout: 30,
      retryCount: 3
    };
    const networkConfig = ConfigService.getInstance().getConfig('network');
    
    // 手动合并配置，避免使用对象字面量作为类型
    this.httpConfig = {
      timeout: networkConfig?.timeout !== undefined ? networkConfig.timeout as number : defaultConfig.timeout,
      retryCount: networkConfig?.retryCount !== undefined ? networkConfig.retryCount as number : defaultConfig.retryCount,
      userAgent: networkConfig?.userAgent as string
    };
    
    this.adBlockManager = AdBlockManager.getInstance();
  }

  /**
   * 设置应用上下文
   * @param ctx 应用上下文
   */
  public setContext(ctx: common.Context): void {
    this.context = ctx;
  }

  /**
   * 获取应用上下文
   * @returns 应用上下文
   */
  private getContext(): common.Context {
    if (!this.context) {
      throw new Error('HttpService context not set. Please call setContext() first.');
    }
    return this.context;
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): HttpService {
    if (!HttpService.instance) {
      HttpService.instance = new HttpService();
    }
    return HttpService.instance;
  }

  /**
   * 发送GET请求
   * @param url 请求URL
   * @param options 请求选项
   */
  public async get<T>(url: string, options?: HttpOptions): Promise<HttpResponse<T>> {
    const requestOptions: HttpRequestOptions = {
      method: 'GET'
    };
    
    // 手动合并选项
    if (options) {
      if (options.headers) requestOptions.headers = options.headers;
      if (options.timeout !== undefined) requestOptions.timeout = options.timeout;
      if (options.retryCount !== undefined) requestOptions.retryCount = options.retryCount;
      if (options.responseType) requestOptions.responseType = options.responseType;
    }
    
    return this.request<T>(url, requestOptions);
  }

  /**
   * 发送POST请求
   * @param url 请求URL
   * @param data 请求数据
   * @param options 请求选项
   */
  public async post<T>(url: string, data?: unknown, options?: HttpOptions): Promise<HttpResponse<T>> {
    const requestOptions: HttpRequestOptions = {
      method: 'POST',
      data: data
    };
    
    // 手动合并选项
    if (options) {
      if (options.headers) requestOptions.headers = options.headers;
      if (options.timeout !== undefined) requestOptions.timeout = options.timeout;
      if (options.retryCount !== undefined) requestOptions.retryCount = options.retryCount;
      if (options.responseType) requestOptions.responseType = options.responseType;
    }
    
    return this.request<T>(url, requestOptions);
  }

  /**
   * 发送网络请求
   * @param url 请求URL
   * @param options 请求选项
   */
  public async request<T>(url: string, options: HttpRequestOptions): Promise<HttpResponse<T>> {
    try {
      // 检查网络权限
      try {
        const atManager = abilityAccessCtrl.createAtManager();
        await atManager.requestPermissionsFromUser(this.getContext(), ['ohos.permission.INTERNET']);
      } catch (permissionError) {
        console.error('Failed to request INTERNET permission', permissionError);
        throw new Error('Network permission denied');
      }

      // 检查URL是否在广告屏蔽列表中
      if (this.adBlockManager.isEnabled() && this.adBlockManager.shouldBlockUrl(url)) {
        throw new Error(`URL blocked by ad blocker: ${url}`);
      }

      const method = options.method || 'GET';
      const headers = options.headers || {};
      const requestData = options.data || null;
      const timeout = options.timeout !== undefined ? options.timeout : (this.httpConfig.timeout as number) * 1000;

      // 创建HTTP请求对象
      const httpRequest = http.createHttp();
      
      // 构建请求配置
      const requestConfig: http.HttpRequestOptions = {
        method,
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': (this.httpConfig.userAgent as string) || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          'Content-Type': 'application/json'
        }
      };
      
      // 手动合并headers
      if (headers) {
        const headerKeys = Object.keys(headers);
        for (let i = 0; i < headerKeys.length; i++) {
          const key = headerKeys[i];
          requestConfig.header[key] = headers[key];
        }
      }

      // 添加请求数据
      if (requestData !== null && requestData !== undefined) {
        if (requestConfig.header['Content-Type']?.includes('json')) {
          requestConfig.extraData = JSON.stringify(requestData);
        } else {
          requestConfig.extraData = requestData;
        }
      }

      // 发送请求
      let response: http.HttpResponse | null = null;
      let retryCount = 0;
      let lastError: Error | null = null;
      const maxRetryCount = options.retryCount !== undefined ? options.retryCount : (this.httpConfig.retryCount as number);

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
          
          // 重试前等待
          await this.sleep(1000 * retryCount);
        }
      }

      // 确保response有值
      if (!response) {
        throw new Error('Failed to get HTTP response');
      }

      // 处理响应
      const result: HttpResponse<T> = {
        status: response.responseCode,
        data: this.parseResponseData<T>(response.result as string),
        headers: response.header as Record<string, string>,
        url: response.requestURL
      };

      // 关闭请求对象
      httpRequest.destroy();

      // 检查状态码
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
   * 下载文件
   * @param url 文件URL
   * @param filePath 保存路径
   * @param options 下载选项
   */
  public async downloadFile(url: string, filePath: string, options?: DownloadOptions): Promise<DownloadResult> {
    try {
      // 检查网络权限
      try {
        const atManager = abilityAccessCtrl.createAtManager();
        await atManager.requestPermissionsFromUser(this.getContext(), ['ohos.permission.INTERNET']);
      } catch (permissionError) {
        console.error('Failed to request INTERNET permission', permissionError);
        throw new Error('Network permission denied');
      }

      // 检查URL是否在广告屏蔽列表中
      if (this.adBlockManager.isEnabled() && this.adBlockManager.shouldBlockUrl(url)) {
        throw new Error(`URL blocked by ad blocker: ${url}`);
      }

      const headers = options?.headers || {};
      const timeout = options?.timeout !== undefined ? options.timeout : (this.httpConfig.timeout as number) * 1000;
      
      // 创建HTTP请求对象
      const httpRequest = http.createHttp();
      
      // 构建请求配置
      const requestConfig: http.HttpRequestOptions = {
        method: 'GET',
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': (this.httpConfig.userAgent as string) || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36'
        }
      };
      
      // 手动合并headers
      if (headers) {
        const headerKeys = Object.keys(headers);
        for (let i = 0; i < headerKeys.length; i++) {
          const key = headerKeys[i];
          requestConfig.header[key] = headers[key];
        }
      }

      // 为下载配置创建明确的类型
      interface DownloadConfig {
        filePath: string;
        method: string;
        connectTimeout: number;
        readTimeout: number;
        header: Record<string, string>;
        extraData?: string | Record<string, string | number | boolean>;
        expectDataType?: http.HttpDataType;
      }
      
      // 发送请求
      const downloadConfig: DownloadConfig = {
        filePath: filePath,
        method: requestConfig.method,
        connectTimeout: requestConfig.connectTimeout,
        readTimeout: requestConfig.readTimeout,
        header: requestConfig.header,
        extraData: requestConfig.extraData,
        expectDataType: requestConfig.expectDataType
      };
      
      const response = await httpRequest.downloadFile(url, downloadConfig);

      // 关闭请求对象
      httpRequest.destroy();

      const result: DownloadResult = {
        status: response.responseCode,
        filePath,
        headers: response.header as Record<string, string>,
        fileSize: response.fileSize
      };

      return result;
    } catch (error) {
      console.error(`File download failed: ${url}`, error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 解析响应数据
   * @param data 原始响应数据
   */
  private parseResponseData<T>(data: string): T {
    try {
      return JSON.parse(data) as T;
    } catch {
      // 如果不是JSON格式，直接返回
      return data as unknown as T;
    }
  }

  /**
   * 延迟函数
   * @param ms 延迟毫秒数
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * HTTP请求选项
 */
export interface HttpOptions {
  headers?: Record<string, string>;
  timeout?: number;
  retryCount?: number;
  responseType?: 'json' | 'text' | 'arraybuffer';
}

/**
   * HTTP请求配置
   */
export interface HttpRequestOptions extends HttpOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  data?: string | Record<string, string | number | boolean>;
}

/**
 * HTTP响应
 */
export interface HttpResponse<T> {
  status: number;
  data: T;
  headers: Record<string, string>;
  url: string;
}

/**
 * 下载选项
 */
export interface DownloadOptions extends HttpOptions {
  onProgress?: (receivedSize: number, totalSize: number) => void;
}

/**
 * 下载结果
 */
export interface DownloadResult {
  status: number;
  filePath: string;
  headers: Record<string, string>;
  fileSize?: number;
}