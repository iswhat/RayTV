// HTTP服务类
// 提供网络请求的统一接口，支持GET、POST等方法，处理请求头、响应拦截等

import http from '@ohos.net.http';
import { ConfigService } from './config/ConfigService';
import { AdBlockManager } from './adblock/AdBlockManager';

export class HttpService {
  private static instance: HttpService;
  private httpConfig: any;
  private adBlockManager: AdBlockManager;

  private constructor() {
    this.httpConfig = ConfigService.getInstance().getConfig('network') || {
      timeout: 30,
      retryCount: 3
    };
    this.adBlockManager = AdBlockManager.getInstance();
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
    return this.request<T>(url, {
      method: 'GET',
      ...options
    });
  }

  /**
   * 发送POST请求
   * @param url 请求URL
   * @param data 请求数据
   * @param options 请求选项
   */
  public async post<T>(url: string, data?: any, options?: HttpOptions): Promise<HttpResponse<T>> {
    return this.request<T>(url, {
      method: 'POST',
      data,
      ...options
    });
  }

  /**
   * 发送网络请求
   * @param url 请求URL
   * @param options 请求选项
   */
  public async request<T>(url: string, options: HttpRequestOptions): Promise<HttpResponse<T>> {
    try {
      // 检查URL是否在广告屏蔽列表中
      if (this.adBlockManager.isEnabled() && this.adBlockManager.shouldBlockUrl(url)) {
        throw new Error(`URL blocked by ad blocker: ${url}`);
      }

      const { method = 'GET', headers = {}, data = null, timeout = this.httpConfig.timeout * 1000 } = options;

      // 创建HTTP请求对象
      const httpRequest = http.createHttp();
      
      // 构建请求配置
      const requestConfig: http.HttpRequestOptions = {
        method,
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': this.httpConfig.userAgent || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          'Content-Type': 'application/json',
          ...headers
        }
      };

      // 添加请求数据
      if (data) {
        if (requestConfig.header['Content-Type']?.includes('json')) {
          requestConfig.extraData = JSON.stringify(data);
        } else {
          requestConfig.extraData = data;
        }
      }

      // 发送请求
      let response: http.HttpResponse;
      let retryCount = 0;
      let lastError: Error | null = null;

      while (retryCount <= (options.retryCount || this.httpConfig.retryCount)) {
        try {
          response = await httpRequest.request(url, requestConfig);
          break;
        } catch (error) {
          lastError = error as Error;
          retryCount++;
          
          if (retryCount > (options.retryCount || this.httpConfig.retryCount)) {
            throw lastError;
          }
          
          // 重试前等待
          await this.sleep(1000 * retryCount);
        }
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
        throw new Error(`HTTP Error: ${result.status} - ${url}`);
      }

      return result;
    } catch (error) {
      console.error(`HTTP request failed: ${url}`, error);
      throw error;
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
      // 检查URL是否在广告屏蔽列表中
      if (this.adBlockManager.isEnabled() && this.adBlockManager.shouldBlockUrl(url)) {
        throw new Error(`URL blocked by ad blocker: ${url}`);
      }

      const { headers = {}, timeout = this.httpConfig.timeout * 1000 } = options || {};
      
      // 创建HTTP请求对象
      const httpRequest = http.createHttp();
      
      // 构建请求配置
      const requestConfig: http.HttpRequestOptions = {
        method: 'GET',
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': this.httpConfig.userAgent || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          ...headers
        }
      };

      // 发送请求
      const response = await httpRequest.downloadFile(url, {
        filePath,
        ...requestConfig
      });

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
      throw error;
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
  data?: any;
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