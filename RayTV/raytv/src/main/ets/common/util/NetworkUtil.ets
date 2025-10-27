// NetworkUtil - 网络请求和连接管理工具类
import Logger from './Logger';
import AppConstant from '../constant/AppConstant';

const TAG = 'NetworkUtil';

/**
 * 网络请求配置接口
 */
export interface RequestConfig {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  params?: Record<string, any>;
  data?: any;
  timeout?: number;
  responseType?: 'text' | 'json' | 'arraybuffer';
}

/**
 * 网络响应接口
 */
export interface Response<T = any> {
  status: number;
  statusText: string;
  data: T;
  headers: Record<string, string>;
}

/**
 * 网络工具类
 * 提供网络请求、连接状态检查等功能
 */
export default class NetworkUtil {
  private static readonly DEFAULT_TIMEOUT = 30000;
  private static readonly MAX_RETRY_COUNT = 3;

  /**
   * 发送HTTP请求
   * @param config 请求配置
   * @param retryCount 当前重试次数
   * @returns Promise<Response>
   */
  public static async request<T = any>(config: RequestConfig, retryCount: number = 0): Promise<Response<T>> {
    const { 
      url, 
      method = 'GET', 
      headers = {}, 
      params = {}, 
      data,
      timeout = this.DEFAULT_TIMEOUT,
      responseType = 'json'
    } = config;

    try {
      // 构建完整URL（添加查询参数）
      let fullUrl = url;
      if (Object.keys(params).length > 0) {
        const queryString = this.buildQueryString(params);
        fullUrl = `${url}${url.includes('?') ? '&' : '?'}${queryString}`;
      }

      // 构建请求选项
      const requestOptions: RequestInit = {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers
        },
        timeout
      };

      // 添加请求体
      if (data && ['POST', 'PUT', 'PATCH'].includes(method)) {
        requestOptions.body = JSON.stringify(data);
      }

      Logger.info(TAG, `Sending ${method} request to ${fullUrl}`);

      // 发送请求
      const controller = new AbortController();
      requestOptions.signal = controller.signal;
      
      // 设置超时
      const timeoutId = setTimeout(() => controller.abort(), timeout);
      
      try {
        const response = await fetch(fullUrl, requestOptions);
        clearTimeout(timeoutId);

        // 读取响应数据
        let responseData: any;
        switch (responseType) {
          case 'json':
            responseData = await response.json();
            break;
          case 'arraybuffer':
            responseData = await response.arrayBuffer();
            break;
          default:
            responseData = await response.text();
        }

        // 提取响应头
        const responseHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => {
          responseHeaders[key] = value;
        });

        const result: Response<T> = {
          status: response.status,
          statusText: response.statusText,
          data: responseData,
          headers: responseHeaders
        };

        // 检查响应状态
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        Logger.info(TAG, `Request to ${fullUrl} succeeded with status ${response.status}`);
        return result;
      } catch (error) {
        clearTimeout(timeoutId);
        throw error;
      }
    } catch (error) {
      Logger.error(TAG, `Request failed: ${error}`);
      
      // 重试逻辑
      if (retryCount < this.MAX_RETRY_COUNT && this.isRetryableError(error)) {
        const delay = Math.pow(2, retryCount) * 1000; // 指数退避
        Logger.info(TAG, `Retrying request in ${delay}ms (${retryCount + 1}/${this.MAX_RETRY_COUNT})`);
        
        await this.sleep(delay);
        return this.request<T>(config, retryCount + 1);
      }
      
      throw error;
    }
  }

  /**
   * 发送GET请求
   * @param url 请求URL
   * @param params 查询参数
   * @param headers 请求头
   * @returns Promise<Response>
   */
  public static async get<T = any>(url: string, params?: Record<string, any>, headers?: Record<string, string>): Promise<Response<T>> {
    return this.request<T>({
      url,
      method: 'GET',
      params,
      headers
    });
  }

  /**
   * 发送POST请求
   * @param url 请求URL
   * @param data 请求数据
   * @param headers 请求头
   * @returns Promise<Response>
   */
  public static async post<T = any>(url: string, data?: any, headers?: Record<string, string>): Promise<Response<T>> {
    return this.request<T>({
      url,
      method: 'POST',
      data,
      headers
    });
  }

  /**
   * 发送PUT请求
   * @param url 请求URL
   * @param data 请求数据
   * @param headers 请求头
   * @returns Promise<Response>
   */
  public static async put<T = any>(url: string, data?: any, headers?: Record<string, string>): Promise<Response<T>> {
    return this.request<T>({
      url,
      method: 'PUT',
      data,
      headers
    });
  }

  /**
   * 发送DELETE请求
   * @param url 请求URL
   * @param headers 请求头
   * @returns Promise<Response>
   */
  public static async delete<T = any>(url: string, headers?: Record<string, string>): Promise<Response<T>> {
    return this.request<T>({
      url,
      method: 'DELETE',
      headers
    });
  }

  /**
   * 构建查询字符串
   * @param params 查询参数对象
   * @returns 查询字符串
   */
  private static buildQueryString(params: Record<string, any>): string {
    return Object.entries(params)
      .filter(([_, value]) => value !== undefined && value !== null)
      .map(([key, value]) => {
        if (Array.isArray(value)) {
          return value.map(v => `${encodeURIComponent(key)}=${encodeURIComponent(v)}`).join('&');
        }
        return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
      })
      .join('&');
  }

  /**
   * 判断错误是否可重试
   * @param error 错误对象
   * @returns 是否可重试
   */
  private static isRetryableError(error: any): boolean {
    // 网络错误、超时、服务器错误(5xx)可重试
    return error.name === 'AbortError' || 
           error.message.includes('Network') ||
           error.message.includes('timeout');
  }

  /**
   * 延时函数
   * @param ms 延时毫秒数
   * @returns Promise
   */
  private static sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 检查网络连接状态
   * @returns Promise<boolean>
   */
  public static async checkNetworkStatus(): Promise<boolean> {
    try {
      // 使用navigator.onLine检查网络连接
      if (typeof navigator !== 'undefined' && 'onLine' in navigator) {
        return navigator.onLine;
      }
      
      // 备用检查方法：尝试访问可靠的域名
      const response = await fetch(AppConstant.NETWORK_CHECK_URL, {
        method: 'HEAD',
        cache: 'no-cache',
        timeout: 3000
      });
      return response.ok;
    } catch (error) {
      Logger.warn(TAG, 'Network check failed:', error);
      return false;
    }
  }

  /**
   * 下载文件
   * @param url 文件URL
   * @param filename 文件名
   * @returns Promise<void>
   */
  public static async downloadFile(url: string, filename?: string): Promise<void> {
    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Download failed with status ${response.status}`);
      }

      const blob = await response.blob();
      const objectUrl = URL.createObjectURL(blob);
      
      // 创建下载链接
      const link = document.createElement('a');
      link.href = objectUrl;
      link.download = filename || url.split('/').pop() || 'download';
      
      // 模拟点击下载
      document.body.appendChild(link);
      link.click();
      
      // 清理
      setTimeout(() => {
        document.body.removeChild(link);
        URL.revokeObjectURL(objectUrl);
      }, 100);

      Logger.info(TAG, `File downloaded successfully: ${link.download}`);
    } catch (error) {
      Logger.error(TAG, `Failed to download file: ${error}`);
      throw error;
    }
  }

  /**
   * 获取网络类型
   * @returns 网络类型
   */
  public static async getNetworkType(): Promise<string> {
    try {
      // 在浏览器环境中，navigator.connection提供网络信息
      if (typeof navigator !== 'undefined' && 'connection' in navigator) {
        const connection = (navigator as any).connection || (navigator as any).mozConnection || (navigator as any).webkitConnection;
        if (connection) {
          return connection.effectiveType || 'unknown';
        }
      }
      
      // 备用方法：通过请求响应时间估计网络类型
      const startTime = performance.now();
      await fetch(AppConstant.NETWORK_CHECK_URL, { method: 'HEAD' });
      const endTime = performance.now();
      const responseTime = endTime - startTime;
      
      if (responseTime < 100) return '4g';
      if (responseTime < 300) return '3g';
      if (responseTime < 1000) return '2g';
      return 'slow';
    } catch (error) {
      Logger.warn(TAG, 'Failed to detect network type:', error);
      return 'unknown';
    }
  }

  /**
   * 创建带缓存的请求
   * @param url 请求URL
   * @param cacheTime 缓存时间（毫秒）
   * @returns Promise<any>
   */
  public static async cachedRequest<T = any>(url: string, cacheTime: number = 5 * 60 * 1000): Promise<T> {
    try {
      const cacheKey = `cache_${url}`;
      const cacheInfo = localStorage.getItem(cacheKey);
      
      if (cacheInfo) {
        const { data, timestamp } = JSON.parse(cacheInfo);
        const now = Date.now();
        
        // 检查缓存是否有效
        if (now - timestamp < cacheTime) {
          Logger.info(TAG, `Using cached data for ${url}`);
          return data as T;
        }
      }
      
      // 缓存无效，发送新请求
      const response = await this.get<T>(url);
      
      // 保存新缓存
      const cacheData = {
        data: response.data,
        timestamp: Date.now()
      };
      localStorage.setItem(cacheKey, JSON.stringify(cacheData));
      
      return response.data;
    } catch (error) {
      Logger.error(TAG, `Cached request failed: ${error}`);
      throw error;
    }
  }
}