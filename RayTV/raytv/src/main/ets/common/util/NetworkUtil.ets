// NetworkUtil - 网络请求和连接管理工具类
import Logger from './Logger';
import AppConstant from '../constant/AppConstant';
import http from '@ohos.net.http';
import connection from '@ohos.net.connection';
import { BusinessError } from '@ohos.base';
import { fileIO } from '@ohos.file.fs';
import { CacheManager } from '../../service/spider/CacheManager';

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
  private static networkStatusListeners: Set<(isOnline: boolean, networkType: string) => void> = new Set();
  private static isInitialized: boolean = false;

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

      Logger.info(TAG, `Sending ${method} request to ${fullUrl}`);

      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 设置请求选项
      const httpOptions: http.HttpRequestOptions = {
        method,
        header: {
          'Content-Type': 'application/json',
          ...headers
        },
        connectTimeout: timeout,
        readTimeout: timeout
      };

      // 添加请求体
      if (data && ['POST', 'PUT', 'PATCH'].includes(method)) {
        httpOptions.extraData = JSON.stringify(data);
      }

      try {
        // 发送请求
        const response = await httpRequest.request(fullUrl, httpOptions);
        
        // 读取响应数据
        let responseData: any = response.result;
        
        // 处理不同响应类型
        if (responseType === 'json' && typeof responseData === 'string') {
          try {
            responseData = JSON.parse(responseData);
          } catch (parseError) {
            Logger.error(TAG, 'Failed to parse JSON response', parseError);
          }
        }

        // 构建响应头
        const responseHeaders: Record<string, string> = {};
        if (response.header) {
          Object.keys(response.header).forEach(key => {
            responseHeaders[key] = String(response.header![key]);
          });
        }

        // 检查状态码
        if (response.responseCode < 200 || response.responseCode >= 300) {
          throw new Error(`HTTP error! status: ${response.responseCode}`);
        }

        return {
          status: response.responseCode,
          statusText: String(response.responseCode),
          data: responseData,
          headers: responseHeaders
        };
      } catch (error) {
        // 重试逻辑
        if (retryCount < this.MAX_RETRY_COUNT && this.isRetryableError(error)) {
          Logger.warn(TAG, `Request failed, retrying (${retryCount + 1}/${this.MAX_RETRY_COUNT})`, error);
          // 指数退避策略
          const delay = Math.pow(2, retryCount) * 1000;
          await this.sleep(delay);
          return this.request(config, retryCount + 1);
        }
        throw error;
      } finally {
        // 销毁HTTP请求
        httpRequest.destroy();
      }
    } catch (error) {
      Logger.error(TAG, `Request error: ${error}`, error);
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
   * @returns Promise<void>
   */
  private static sleep(ms: number): Promise<void> {
    // 使用Promise包装setTimeout，这在HarmonyOS中是兼容的
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  /**
   * 检查网络连接状态
   * @returns Promise<boolean>
   */
  public static async checkNetworkStatus(): Promise<boolean> {
    try {
      // 使用HarmonyOS原生API检查网络状态
      const netStatus = await connection.getStatus();
      return netStatus.isInternetAvailable;
    } catch (error) {
      Logger.warn(TAG, 'Network check failed:', error);
      // 备用方法：使用HTTP请求检查
      try {
        const httpRequest = http.createHttp();
        const response = await httpRequest.request(AppConstant.NETWORK_CHECK_URL, {
          method: 'HEAD',
          connectTimeout: 3000,
          readTimeout: 3000
        });
        httpRequest.destroy();
        return response.responseCode >= 200 && response.responseCode < 300;
      } catch (httpError) {
        Logger.warn(TAG, 'HTTP network check failed:', httpError);
        return false;
      }
    }
  }

  /**
   * 下载文件
   * @param url 文件URL
   * @param savePath 保存路径
   * @param options 下载选项
   * @returns Promise<void>
   */
  public static async downloadFile(url: string, savePath: string, options?: {
    headers?: Record<string, string>;
    timeout?: number;
    onProgress?: (receivedSize: number, totalSize: number) => void;
  }): Promise<void> {
    try {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      const downloadOptions: http.HttpRequestOptions = {
        method: 'GET',
        header: options?.headers || {},
        responseType: http.HttpResponseType.ARRAY_BUFFER,
        connectTimeout: options?.timeout || 60000,
        readTimeout: options?.timeout || 60000
      };

      // 发送下载请求
      const response = await httpRequest.request(url, downloadOptions);
      
      // 检查响应状态
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`Download failed with status ${response.responseCode}`);
      }
      
      // 确保响应是ArrayBuffer类型
      if (typeof response.result !== 'object' || !(response.result instanceof ArrayBuffer)) {
        throw new Error('Invalid response data type');
      }
      
      // 获取文件总大小
      const totalSize = response.result.byteLength;
      
      // 写入文件
      const file = await fileIO.open(savePath, fileIO.OpenMode.READ_WRITE | fileIO.OpenMode.CREATE);
      
      try {
        // 将ArrayBuffer写入文件
        const writeResult = await fileIO.write(file.fd, response.result);
        
        // 通知进度完成
        if (options?.onProgress) {
          options.onProgress(totalSize, totalSize);
        }
        
        Logger.info(TAG, `File downloaded successfully: ${savePath}, size: ${writeResult.bytesWritten} bytes`);
      } finally {
        // 关闭文件
        await fileIO.close(file.fd);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to download file: ${error}`);
      throw error;
    }
  }
  
  /**
   * 初始化网络状态监听
   */
  private static async initializeNetworkListener(): Promise<void> {
    if (this.isInitialized) return;
    
    try {
      // 订阅网络状态变化
      await connection.on('netStatusChange', async (data) => {
        const isOnline = data !== null && data.isInternetAvailable !== false;
        const networkType = isOnline ? await this.getNetworkType() : 'NONE';
        
        Logger.info(TAG, `Network status changed: online=${isOnline}, type=${networkType}`);
        
        // 通知所有监听器
        this.notifyNetworkStatusChanged(isOnline, networkType);
      });
      
      // 获取初始网络状态
      const status = await connection.getStatus();
      const isOnline = status !== null && status.isInternetAvailable !== false;
      const initialNetworkType = isOnline ? await this.getNetworkType() : 'NONE';
      
      Logger.info(TAG, `Initial network status: online=${isOnline}, type=${initialNetworkType}`);
      
      this.isInitialized = true;
    } catch (error) {
      Logger.error(TAG, `Failed to initialize network listener: ${error}`);
    }
  }

  /**
   * 通知所有监听器网络状态变化
   * @param isOnline 是否在线
   * @param networkType 网络类型
   */
  private static notifyNetworkStatusChanged(isOnline: boolean, networkType: string): void {
    this.networkStatusListeners.forEach((listener) => {
      try {
        listener(isOnline, networkType);
      } catch (error) {
        Logger.error(TAG, `Error in network status listener: ${error}`);
      }
    });
  }

  /**
   * 添加网络状态监听器
   * @param listener 监听器回调函数
   * @returns 取消监听的函数
   */
  public static addNetworkStatusListener(listener: (isOnline: boolean, networkType: string) => void): () => void {
    this.networkStatusListeners.add(listener);
    
    // 自动初始化监听
    this.initializeNetworkListener().catch((error) => {
      Logger.error(TAG, `Failed to initialize network listener after adding: ${error}`);
    });
    
    // 返回取消监听的函数
    return () => {
      this.removeNetworkStatusListener(listener);
    };
  }

  /**
   * 移除网络状态监听器
   * @param listener 要移除的监听器
   */
  public static removeNetworkStatusListener(listener: (isOnline: boolean, networkType: string) => void): void {
    this.networkStatusListeners.delete(listener);
  }

  /**
   * 获取当前是否在线
   * @returns 是否在线的Promise
   */
  public static async isOnline(): Promise<boolean> {
    try {
      const status = await connection.getStatus();
      return status !== null && status.isInternetAvailable !== false;
    } catch (error) {
      Logger.warn(TAG, `Failed to check online status: ${error}`);
      return false;
    }
  }

  /**
   * 下载文本内容
   * @param url 文本URL
   * @param options 下载选项
   * @returns Promise<string>
   */
  public static async downloadText(url: string, options?: {
    headers?: Record<string, string>;
    timeout?: number;
  }): Promise<string> {
    try {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      const downloadOptions: http.HttpRequestOptions = {
        method: 'GET',
        header: options?.headers || {},
        connectTimeout: options?.timeout || 30000,
        readTimeout: options?.timeout || 30000
      };

      // 发送请求
      const response = await httpRequest.request(url, downloadOptions);
      httpRequest.destroy();
      
      // 检查响应状态
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`Download failed with status ${response.responseCode}`);
      }
      
      // 返回文本内容
      return response.result as string;
    } catch (error) {
      Logger.error(TAG, `Failed to download text: ${error}`);
      throw error;
    }
  }

  /**
   * 获取网络类型
   * @returns 网络类型
   */
  public static async getNetworkType(): Promise<string> {
    try {
      // 使用HarmonyOS原生API获取网络类型
      const netStatus = await connection.getStatus();
      
      // 根据网络类型返回标准化的结果
      switch (netStatus.type) {
        case connection.NetConnectType.NONE:
          return 'none';
        case connection.NetConnectType.WIFI:
          return 'wifi';
        case connection.NetConnectType.MOBILE:
          // 进一步区分移动网络类型
          if (netStatus.subtype) {
            if (netStatus.subtype >= connection.NetConnectSubtype.NR_5G && netStatus.subtype <= connection.NetConnectSubtype.NR_5G_E) {
              return '5g';
            } else if (netStatus.subtype >= connection.NetConnectSubtype.LTE && netStatus.subtype <= connection.NetConnectSubtype.LTE_ADVANCED_PRO) {
              return '4g';
            } else if (netStatus.subtype >= connection.NetConnectSubtype.UMTS && netStatus.subtype <= connection.NetConnectSubtype.HSPA_PLUS) {
              return '3g';
            } else if (netStatus.subtype >= connection.NetConnectSubtype.GPRS && netStatus.subtype <= connection.NetConnectSubtype.EDGE) {
              return '2g';
            }
          }
          return 'mobile';
        case connection.NetConnectType.ETHERNET:
          return 'ethernet';
        default:
          return 'unknown';
      }
    } catch (error) {
      Logger.warn(TAG, 'Failed to detect network type:', error);
      // 备用方法：通过HTTP请求响应时间估计
      try {
        const startTime = Date.now();
        const httpRequest = http.createHttp();
        await httpRequest.request(AppConstant.NETWORK_CHECK_URL, {
          method: 'HEAD',
          connectTimeout: 3000
        });
        httpRequest.destroy();
        const endTime = Date.now();
        const responseTime = endTime - startTime;
        
        if (responseTime < 100) return '4g';
        if (responseTime < 300) return '3g';
        if (responseTime < 1000) return '2g';
        return 'slow';
      } catch (fallbackError) {
        Logger.warn(TAG, 'Fallback network type detection failed:', fallbackError);
        return 'unknown';
      }
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
      const cacheKey = `network_cache_${url.replace(/[^a-zA-Z0-9]/g, '_')}`;
      
      // 尝试从缓存获取数据
      const cacheManager = CacheManager.getInstance();
      
      if (cacheManager) {
        try {
          const cachedData = await cacheManager.get(cacheKey);
          if (cachedData) {
            const { data, timestamp } = JSON.parse(cachedData);
            const now = Date.now();
            
            // 检查缓存是否有效
            if (now - timestamp < cacheTime) {
              Logger.info(TAG, `Using cached data for ${url}`);
              return data as T;
            }
          }
        } catch (cacheError) {
          Logger.warn(TAG, `Cache read error: ${cacheError}`);
          // 缓存读取失败，继续发送网络请求
        }
      }
      
      // 检查网络状态
      const isNetworkAvailable = await this.checkNetworkStatus();
      if (!isNetworkAvailable) {
        // 离线模式，尝试返回旧缓存（即使过期）
        if (cacheManager) {
          try {
            const oldCachedData = await cacheManager.get(cacheKey);
            if (oldCachedData) {
              Logger.warn(TAG, `Offline mode: using expired cache for ${url}`);
              const { data } = JSON.parse(oldCachedData);
              return data as T;
            }
          } catch (offlineCacheError) {
            Logger.error(TAG, `Offline cache error: ${offlineCacheError}`);
          }
        }
        throw new Error('Network unavailable and no cached data available');
      }
      
      // 缓存无效或不存在，发送新请求
      const response = await this.get<T>(url);
      
      // 保存新缓存
      const cacheData = {
        data: response.data,
        timestamp: Date.now()
      };
      
      // 尝试保存到缓存
      if (cacheManager) {
        try {
          await cacheManager.set(cacheKey, JSON.stringify(cacheData));
          Logger.info(TAG, `Cached response for ${url}`);
        } catch (cacheWriteError) {
          Logger.warn(TAG, `Cache write error: ${cacheWriteError}`);
          // 缓存写入失败，继续返回数据
        }
      }
      
      return response.data;
    } catch (error) {
      Logger.error(TAG, `Cached request failed: ${error}`);
      throw error;
    }
  }
}