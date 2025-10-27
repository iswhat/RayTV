// NetworkUtil - 网络工具类
// 提供网络相关的工具函数，包括请求处理、URL处理、网络状态检测等

import { Logger } from './Logger';
import { RequestMethod, NetworkStatus, NetworkType, RequestOptions, HttpResponse } from '../data/model/NetworkModel';

/**
 * 网络工具类
 */
export class NetworkUtil {
  private static instance: NetworkUtil;
  private logger = Logger.getInstance();
  private retryDelay = 1000; // 默认重试延迟时间（毫秒）
  private maxRetries = 3; // 默认最大重试次数
  private timeout = 30000; // 默认超时时间（毫秒）

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('NetworkUtil initialized');
  }

  /**
   * 获取NetworkUtil单例实例
   */
  public static getInstance(): NetworkUtil {
    if (!NetworkUtil.instance) {
      NetworkUtil.instance = new NetworkUtil();
    }
    return NetworkUtil.instance;
  }

  /**
   * 设置默认配置
   * @param config 配置对象
   */
  public setConfig(config: { retryDelay?: number; maxRetries?: number; timeout?: number }): void {
    if (config.retryDelay !== undefined) {
      this.retryDelay = config.retryDelay;
    }
    if (config.maxRetries !== undefined) {
      this.maxRetries = config.maxRetries;
    }
    if (config.timeout !== undefined) {
      this.timeout = config.timeout;
    }
    this.logger.debug(`NetworkUtil config updated: retryDelay=${this.retryDelay}, maxRetries=${this.maxRetries}, timeout=${this.timeout}`);
  }

  /**
   * 发送HTTP请求
   * @param url 请求URL
   * @param options 请求选项
   */
  public async request<T>(url: string, options: RequestOptions = {}): Promise<HttpResponse<T>> {
    const finalOptions = this.prepareRequestOptions(options);
    const retries = finalOptions.retries ?? this.maxRetries;
    const retryDelay = finalOptions.retryDelay ?? this.retryDelay;
    
    this.logger.debug(`Preparing HTTP request to ${url}, method: ${finalOptions.method}`);
    
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        if (attempt > 0) {
          this.logger.info(`Retrying request (${attempt}/${retries}) to ${url}`);
          await this.delay(retryDelay * Math.pow(2, attempt - 1)); // 指数退避
        }
        
        const response = await this.executeRequest<T>(url, finalOptions);
        return response;
      } catch (error) {
        const isLastAttempt = attempt === retries;
        const errorMessage = error instanceof Error ? error.message : String(error);
        
        if (isLastAttempt) {
          this.logger.error(`Request failed after ${retries + 1} attempts: ${url}`, error as Error);
          throw error;
        } else {
          this.logger.warn(`Request attempt ${attempt + 1} failed, will retry: ${errorMessage}`);
        }
      }
    }
    
    throw new Error(`Unexpected error: request to ${url} failed`);
  }

  /**
   * 发送GET请求
   * @param url 请求URL
   * @param options 请求选项
   */
  public async get<T>(url: string, options: RequestOptions = {}): Promise<HttpResponse<T>> {
    return this.request<T>(url, { ...options, method: RequestMethod.GET });
  }

  /**
   * 发送POST请求
   * @param url 请求URL
   * @param data 请求数据
   * @param options 请求选项
   */
  public async post<T>(url: string, data?: any, options: RequestOptions = {}): Promise<HttpResponse<T>> {
    return this.request<T>(url, { ...options, method: RequestMethod.POST, body: data });
  }

  /**
   * 发送PUT请求
   * @param url 请求URL
   * @param data 请求数据
   * @param options 请求选项
   */
  public async put<T>(url: string, data?: any, options: RequestOptions = {}): Promise<HttpResponse<T>> {
    return this.request<T>(url, { ...options, method: RequestMethod.PUT, body: data });
  }

  /**
   * 发送DELETE请求
   * @param url 请求URL
   * @param options 请求选项
   */
  public async delete<T>(url: string, options: RequestOptions = {}): Promise<HttpResponse<T>> {
    return this.request<T>(url, { ...options, method: RequestMethod.DELETE });
  }

  /**
   * 发送PATCH请求
   * @param url 请求URL
   * @param data 请求数据
   * @param options 请求选项
   */
  public async patch<T>(url: string, data?: any, options: RequestOptions = {}): Promise<HttpResponse<T>> {
    return this.request<T>(url, { ...options, method: RequestMethod.PATCH, body: data });
  }

  /**
   * 上传文件
   * @param url 上传URL
   * @param formData 表单数据
   * @param options 请求选项
   * @param onProgress 进度回调
   */
  public async upload<T>(url: string, formData: FormData, options: RequestOptions = {}, onProgress?: (progress: number) => void): Promise<HttpResponse<T>> {
    this.logger.debug(`Uploading file to ${url}`);
    
    // 这里需要实现文件上传逻辑，包括进度监听
    // 在实际环境中，可能需要使用XMLHttpRequest或特殊的上传API
    
    return this.request<T>(url, {
      ...options,
      method: RequestMethod.POST,
      body: formData,
      headers: {
        ...options.headers,
        'Content-Type': undefined, // 让浏览器自动设置multipart/form-data
      },
    });
  }

  /**
   * 下载文件
   * @param url 下载URL
   * @param options 请求选项
   * @param onProgress 进度回调
   */
  public async download(url: string, options: RequestOptions = {}, onProgress?: (progress: number) => void): Promise<Blob> {
    this.logger.debug(`Downloading file from ${url}`);
    
    const response = await fetch(url, {
      ...this.prepareRequestHeaders(options.headers || {}),
      signal: this.createAbortSignal(options.timeout || this.timeout),
    });
    
    if (!response.ok) {
      throw new Error(`Download failed with status ${response.status}`);
    }
    
    return await response.blob();
  }

  /**
   * 获取网络状态
   */
  public async getNetworkStatus(): Promise<{ type: NetworkType; status: NetworkStatus }> {
    try {
      // 在实际环境中，这里需要使用系统API来获取网络状态
      this.logger.debug('Checking network status');
      
      // 模拟网络状态检查
      const online = navigator.onLine;
      return {
        type: NetworkType.UNKNOWN,
        status: online ? NetworkStatus.CONNECTED : NetworkStatus.DISCONNECTED
      };
    } catch (error) {
      this.logger.error('Failed to check network status', error as Error);
      return {
        type: NetworkType.UNKNOWN,
        status: NetworkStatus.UNKNOWN
      };
    }
  }

  /**
   * 检查URL是否有效
   * @param url 要检查的URL
   */
  public isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 构建查询字符串
   * @param params 查询参数对象
   */
  public buildQueryString(params: Record<string, any>): string {
    const searchParams = new URLSearchParams();
    
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        searchParams.append(key, String(value));
      }
    });
    
    return searchParams.toString();
  }

  /**
   * 解析URL参数
   * @param url URL字符串
   */
  public parseUrlParams(url: string): Record<string, string> {
    try {
      const urlObj = new URL(url);
      const params: Record<string, string> = {};
      
      urlObj.searchParams.forEach((value, key) => {
        params[key] = value;
      });
      
      return params;
    } catch (error) {
      this.logger.error('Failed to parse URL params', error as Error);
      return {};
    }
  }

  /**
   * 添加URL参数
   * @param url 基础URL
   * @param params 要添加的参数
   */
  public addUrlParams(url: string, params: Record<string, any>): string {
    try {
      const urlObj = new URL(url);
      
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          urlObj.searchParams.append(key, String(value));
        }
      });
      
      return urlObj.toString();
    } catch (error) {
      this.logger.error('Failed to add URL params', error as Error);
      return url;
    }
  }

  /**
   * 创建WebSocket连接
   * @param url WebSocket URL
   * @param protocols 协议列表
   */
  public createWebSocket(url: string, protocols?: string | string[]): WebSocket {
    this.logger.debug(`Creating WebSocket connection to ${url}`);
    return new WebSocket(url, protocols);
  }

  /**
   * 检查响应是否成功
   * @param status 状态码
   */
  public isSuccessResponse(status: number): boolean {
    return status >= 200 && status < 300;
  }

  /**
   * 准备请求选项
   * @param options 原始选项
   */
  private prepareRequestOptions(options: RequestOptions): RequestOptions {
    const defaultOptions: RequestOptions = {
      method: RequestMethod.GET,
      headers: {},
      timeout: this.timeout,
      retries: this.maxRetries,
      retryDelay: this.retryDelay,
    };
    
    return {
      ...defaultOptions,
      ...options,
      headers: this.prepareRequestHeaders(options.headers || {}),
    };
  }

  /**
   * 准备请求头
   * @param headers 原始请求头
   */
  private prepareRequestHeaders(headers: Record<string, string>): Record<string, string> {
    const defaultHeaders: Record<string, string> = {
      'Accept': 'application/json',
    };
    
    // 如果没有明确指定Content-Type且有body数据，默认设置为json
    if (!headers['Content-Type']) {
      defaultHeaders['Content-Type'] = 'application/json';
    }
    
    return {
      ...defaultHeaders,
      ...headers,
    };
  }

  /**
   * 执行HTTP请求
   * @param url 请求URL
   * @param options 请求选项
   */
  private async executeRequest<T>(url: string, options: RequestOptions): Promise<HttpResponse<T>> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), options.timeout || this.timeout);
    
    try {
      const requestBody = this.prepareRequestBody(options.body, options.headers?.['Content-Type']);
      
      const response = await fetch(url, {
        method: options.method,
        headers: options.headers,
        body: requestBody,
        signal: controller.signal,
        ...options.fetchOptions,
      });
      
      clearTimeout(timeoutId);
      
      let data: any;
      const contentType = response.headers.get('content-type');
      
      if (contentType && contentType.includes('application/json')) {
        data = await response.json();
      } else {
        data = await response.text();
      }
      
      const httpResponse: HttpResponse<T> = {
        ok: response.ok,
        status: response.status,
        statusText: response.statusText,
        headers: this.headersToObject(response.headers),
        data: data as T,
      };
      
      this.logger.debug(`Request to ${url} completed with status ${response.status}`);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}, message: ${data?.message || response.statusText}`);
      }
      
      return httpResponse;
    } catch (error) {
      clearTimeout(timeoutId);
      
      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          throw new Error(`Request timeout after ${options.timeout || this.timeout}ms`);
        }
      }
      
      throw error;
    }
  }

  /**
   * 准备请求体
   * @param body 请求体数据
   * @param contentType 内容类型
   */
  private prepareRequestBody(body: any, contentType?: string): BodyInit | null {
    if (body === undefined || body === null) {
      return null;
    }
    
    if (contentType && contentType.includes('application/json')) {
      return JSON.stringify(body);
    }
    
    // 对于FormData、Blob等，直接返回
    if (body instanceof FormData || body instanceof Blob || body instanceof URLSearchParams) {
      return body;
    }
    
    return String(body);
  }

  /**
   * 将Headers对象转换为普通对象
   * @param headers Headers对象
   */
  private headersToObject(headers: Headers): Record<string, string> {
    const headersObj: Record<string, string> = {};
    
    headers.forEach((value, key) => {
      headersObj[key] = value;
    });
    
    return headersObj;
  }

  /**
   * 创建中止信号
   * @param timeout 超时时间（毫秒）
   */
  private createAbortSignal(timeout: number): AbortSignal | undefined {
    const controller = new AbortController();
    setTimeout(() => controller.abort(), timeout);
    return controller.signal;
  }

  /**
   * 延迟函数
   * @param ms 延迟毫秒数
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 防抖函数
   * @param func 要防抖的函数
   * @param delay 延迟时间（毫秒）
   */
  public debounce<T extends (...args: any[]) => any>(func: T, delay: number): (...args: Parameters<T>) => void {
    let timeoutId: NodeJS.Timeout;
    
    return (...args: Parameters<T>) => {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => func(...args), delay);
    };
  }

  /**
   * 节流函数
   * @param func 要节流的函数
   * @param limit 时间限制（毫秒）
   */
  public throttle<T extends (...args: any[]) => any>(func: T, limit: number): (...args: Parameters<T>) => void {
    let inThrottle: boolean;
    
    return (...args: Parameters<T>) => {
      if (!inThrottle) {
        func(...args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  }

  /**
   * 生成唯一请求ID
   */
  public generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * 验证响应数据
   * @param data 响应数据
   * @param schema 验证模式
   */
  public validateResponseData(data: any, schema?: any): boolean {
    // 这里可以实现响应数据验证逻辑
    // 可以集成Joi、Yup等验证库
    return true;
  }
}

// 导出默认实例
export default NetworkUtil.getInstance();