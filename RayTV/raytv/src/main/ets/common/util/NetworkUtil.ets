// NetworkUtil - 网络请求和连接管理工具类
import Logger from './Logger';
import { AppConstant } from '../constant/AppConstant';
import http from '@ohos.net.http';
import connection from '@ohos.net.connection';
import BusinessError from '@ohos.base';
import fs from '@ohos.file.fs';
import fileIO from '@ohos.file.fileIO';
import { CacheManager } from '../../service/spider/CacheManager';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';

const TAG = 'NetworkUtil';

/**
 * 网络请求配置接口
 */
export interface RequestConfig {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  params?: Record<string, string | number | boolean | string[]>;
  data?: string | number | boolean | Record<string, string | number | boolean | null>;
  timeout?: number;
  responseType?: 'text' | 'json' | 'arraybuffer';
}

/**
 * 网络响应接口
 */
export interface Response<T> {
  status: number;
  statusText: string;
  data: T;
  headers: Record<string, string>;
}

/**
 * 文件下载选项接口
 */
export interface DownloadOptions {
  headers?: Record<string, string>;
  timeout?: number;
  onProgress?: (receivedSize: number, totalSize: number) => void;
}

/**
 * 文本下载选项接口
 */
export interface DownloadTextOptions {
  headers?: Record<string, string>;
  timeout?: number;
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
  private static context: common.Context | null = null;

  /**
   * 获取对象的所有键
   * 替代Object.keys，兼容ArkTS语法
   */
  private static getObjectKeys<T extends object>(obj: T): string[] {
    const keys: string[] = [];
    // 直接使用Object.keys获取键，避免for-in循环中的原型链问题
    const objectKeys = Object.keys(obj);
    for (let i = 0; i < objectKeys.length; i++) {
      keys.push(objectKeys[i]);
    }
    return keys;
  }

  /**
   * 设置应用上下文
   * @param ctx 应用上下文
   */
  public static setContext(ctx: common.Context): void {
    NetworkUtil.context = ctx;
  }

  /**
   * 获取应用上下文
   * @returns 应用上下文
   */
  private static getContext(): common.Context {
    if (!NetworkUtil.context) {
      throw new Error('NetworkUtil context not set. Please call NetworkUtil.setContext() first.');
    }
    return NetworkUtil.context;
  }

  /**
   * 检查并请求网络权限
   * 只在需要时请求权限，避免重复申请
   */
  private static async checkAndRequestNetworkPermission(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = NetworkUtil.getContext();
      
      // 先检查权限状态，避免重复申请
      const permissionResult: abilityAccessCtrl.GrantStatus = await atManager.checkPermission(context, 'ohos.permission.INTERNET');
      
      // 只有当权限未授权时才请求
      if (permissionResult !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        await atManager.requestPermissionsFromUser(context, ['ohos.permission.INTERNET']);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error(TAG, `Failed to check or request INTERNET permission: ${errorMessage}`);
      // 不抛出错误，允许应用继续尝试网络操作
    }
  }

  /**
   * 初始化网络工具，在应用启动时调用
   */
  public static async initialize(): Promise<void> {
    if (!NetworkUtil.isInitialized) {
      // 初始化时检查权限
      await NetworkUtil.checkAndRequestNetworkPermission();
      NetworkUtil.isInitialized = true;
    }
  }

  /**
   * GET请求便捷方法
   * @param url 请求URL
   * @param config 请求配置（可选）
   * @returns Promise<Response<T>>
   */
  public static async get<T>(url: string, config?: Partial<RequestConfig>): Promise<Response<T>> {
    const requestConfig: RequestConfig = {
      url,
      method: 'GET'
    };
    
    // 手动复制配置属性，避免使用扩展运算符
    if (config) {
      if (config.headers) requestConfig.headers = config.headers;
      if (config.params) requestConfig.params = config.params;
      if (config.timeout !== undefined) requestConfig.timeout = config.timeout;
      if (config.responseType) requestConfig.responseType = config.responseType;
    }
    
    return NetworkUtil.request<T>(requestConfig);
  }

  /**
   * POST请求便捷方法
   * @param url 请求URL
   * @param data 请求数据
   * @param config 请求配置（可选）
   * @returns Promise<Response<T>>
   */
  public static async post<T>(url: string, data?: string | number | boolean | object, config?: Partial<RequestConfig>): Promise<Response<T>> {
    const requestConfig: RequestConfig = {
      url,
      method: 'POST',
      data
    };
    
    // 手动复制配置属性，避免使用扩展运算符
    if (config) {
      if (config.headers) requestConfig.headers = config.headers;
      if (config.params) requestConfig.params = config.params;
      if (config.timeout !== undefined) requestConfig.timeout = config.timeout;
      if (config.responseType) requestConfig.responseType = config.responseType;
    }
    
    return NetworkUtil.request<T>(requestConfig);
  }

  /**
   * PUT请求便捷方法
   * @param url 请求URL
   * @param data 请求数据
   * @param config 请求配置（可选）
   * @returns Promise<Response<T>>
   */
  public static async put<T>(url: string, data?: string | number | boolean | object, config?: Partial<RequestConfig>): Promise<Response<T>> {
    const requestConfig: RequestConfig = {
      url,
      method: 'PUT',
      data
    };
    
    // 手动复制配置属性，避免使用扩展运算符
    if (config) {
      if (config.headers) requestConfig.headers = config.headers;
      if (config.params) requestConfig.params = config.params;
      if (config.timeout !== undefined) requestConfig.timeout = config.timeout;
      if (config.responseType) requestConfig.responseType = config.responseType;
    }
    
    return NetworkUtil.request<T>(requestConfig);
  }

  /**
   * DELETE请求便捷方法
   * @param url 请求URL
   * @param config 请求配置（可选）
   * @returns Promise<Response<T>>
   */
  public static async delete<T>(url: string, config?: Partial<RequestConfig>): Promise<Response<T>> {
    const requestConfig: RequestConfig = {
      url,
      method: 'DELETE'
    };
    
    // 手动复制配置属性，避免使用扩展运算符
    if (config) {
      if (config.headers) requestConfig.headers = config.headers;
      if (config.params) requestConfig.params = config.params;
      if (config.timeout !== undefined) requestConfig.timeout = config.timeout;
      if (config.responseType) requestConfig.responseType = config.responseType;
    }
    
    return NetworkUtil.request<T>(requestConfig);
  }

  /**
   * 发送HTTP请求
   * @param config 请求配置
   * @param retryCount 当前重试次数
   * @returns Promise<Response>
   */
  public static async request<T>(config: RequestConfig, retryCount: number = 0): Promise<Response<T>> {
    const url = config.url;
    const method = config.method || 'GET';
    const headers = config.headers || {};
    const params = config.params || {};
    const data = config.data;
    const timeout = config.timeout || NetworkUtil.DEFAULT_TIMEOUT;
    const responseType = config.responseType || 'json';

    try {
      // 确保已初始化（如果未初始化，会自动检查权限）
      if (!NetworkUtil.isInitialized) {
        await NetworkUtil.initialize();
      }

      // 构建完整URL（添加查询参数）
      let fullUrl = url;
      if (NetworkUtil.getObjectKeys(params).length > 0) {
        const queryString = NetworkUtil.buildQueryString(params);
        fullUrl = `${url}${url.includes('?') ? '&' : '?'}${queryString}`;
      }

      Logger.info(TAG, `Sending ${method} request to ${fullUrl}`);

      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 设置请求选项
      const httpOptions: http.HttpRequestOptions = {
        method,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: timeout,
        readTimeout: timeout
      };
      
      // 手动合并headers，避免数组展开操作
      if (headers) {
        const headerKeys = NetworkUtil.getObjectKeys(headers);
        if (!httpOptions.header) {
          httpOptions.header = {};
        }
        for (let i = 0; i < headerKeys.length; i++) {
          const key = headerKeys[i];
          httpOptions.header[key] = headers[key];
        }
      }

      // 添加请求体
      if (data && ['POST', 'PUT', 'PATCH'].includes(method)) {
        httpOptions.extraData = typeof data === 'string' ? data : JSON.stringify(data);
      }

      try {
        // 发送请求
        const response = await httpRequest.request(fullUrl, httpOptions);
        
        // 读取响应数据
        let responseData: string | object | null = response.result;
        
        // 处理不同响应类型
        if (responseType === 'json' && typeof responseData === 'string') {
          try {
            responseData = JSON.parse(responseData);
          } catch (parseError) {
            const errorMessage = parseError instanceof Error ? parseError.message : String(parseError);
            Logger.error(TAG, `Failed to parse JSON response: ${errorMessage}`);
          }
        }

        // 构建响应头
        const responseHeaders: Record<string, string> = {};
        if (response.header) {
          const headerKeys = Object.keys(response.header);
          for (let i = 0; i < headerKeys.length; i++) {
            const key = headerKeys[i];
            responseHeaders[key] = String(response.header[key]);
          }
        }

        // 检查状态码
        if (response.responseCode < 200 || response.responseCode >= 300) {
          throw new Error(`HTTP error! status: ${response.responseCode}`);
        }

        return {
          status: response.responseCode,
          statusText: String(response.responseCode),
          data: responseData as T,
          headers: responseHeaders
        };
      } catch (error) {
        // 重试逻辑
        if (retryCount < NetworkUtil.MAX_RETRY_COUNT && NetworkUtil.isRetryableError(error)) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          Logger.warn(TAG, `Request failed, retrying (${retryCount + 1}/${NetworkUtil.MAX_RETRY_COUNT}): ${errorMessage}`);
          // 指数退避策略
          const delay = Math.pow(2, retryCount) * 1000;
          await NetworkUtil.sleep(delay);
          return NetworkUtil.request(config, retryCount + 1);
        }
        const errorMessage = error instanceof Error ? error.message : String(error);
        Logger.error(TAG, `Request error: ${errorMessage}`);
        throw error instanceof Error ? error : new Error(errorMessage);
      } finally {
        // 销毁HTTP请求
        httpRequest.destroy();
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error(TAG, `Request failed with error: ${errorMessage}`);
      throw error instanceof Error ? error : new Error(errorMessage);
    }
  }

  /**
   * 判断错误是否可重试
   * @param error 错误对象
   * @returns 是否可重试
   */
  private static isRetryableError(error: Error | string): boolean {
    // 网络错误、超时、服务器错误(5xx)可重试
    if (error instanceof Error) {
      const errorName = error.name;
      const errorMessage = error.message;
      return errorName === 'AbortError' || 
             errorMessage.includes('Network') ||
             errorMessage.includes('timeout');
    }
    return false;
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
      const netStatus: connection.NetworkStatus = await connection.getStatus();
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
  public static async downloadFile(url: string, savePath: string, options?: DownloadOptions): Promise<void> {
    try {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 初始化header对象
      const headers = options?.headers || {};
      
      const downloadOptions: http.HttpRequestOptions = {
        method: 'GET',
        header: headers,
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
      const file: fileIO.File = await fileIO.open(savePath, fileIO.OpenMode.READ_WRITE | fileIO.OpenMode.CREATE);
      
      try {
        // 将ArrayBuffer写入文件
        const writeResult: fileIO.WriteResult = await fileIO.write(file.fd, response.result);
        
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
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error(TAG, `Failed to download file: ${errorMessage}`);
      throw error instanceof Error ? error : new Error(errorMessage);
    }
  }
  
  /**
   * 初始化网络状态监听
   */
  private static async initializeNetworkListener(): Promise<void> {
    if (NetworkUtil.isInitialized) return;
    
    try {
      // 订阅网络状态变化
      await connection.on('netStatusChange', async (data: connection.NetworkStatus | null) => {
        const isOnline = data !== null && data.isInternetAvailable !== false;
        const networkType = isOnline ? await NetworkUtil.getNetworkType() : 'NONE';
        
        Logger.info(TAG, `Network status changed: online=${isOnline}, type=${networkType}`);
        
        // 通知所有监听器
        NetworkUtil.notifyNetworkStatusChanged(isOnline, networkType);
      });
      
      // 获取初始网络状态
      const status: connection.NetworkStatus = await connection.getStatus();
      const isOnline = status.isInternetAvailable !== false;
      const networkType = isOnline ? await NetworkUtil.getNetworkType() : 'NONE';
      
      Logger.info(TAG, `Initial network status: online=${isOnline}, type=${networkType}`);
      
      NetworkUtil.isInitialized = true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error(TAG, `Failed to initialize network listener: ${errorMessage}`);
    }
  }

  /**
   * 通知所有监听器网络状态变化
   * @param isOnline 是否在线
   * @param networkType 网络类型
   */
  private static notifyNetworkStatusChanged(isOnline: boolean, networkType: string): void {
    NetworkUtil.networkStatusListeners.forEach((listener) => {
      try {
        listener(isOnline, networkType);
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        Logger.error(TAG, `Error in network status listener: ${errorMessage}`);
      }
    });
  }

  /**
   * 添加网络状态监听器
   * @param listener 监听器回调函数
   * @returns 取消监听的函数
   */
  public static addNetworkStatusListener(listener: (isOnline: boolean, networkType: string) => void): () => void {
    NetworkUtil.networkStatusListeners.add(listener);
    
    // 自动初始化监听
    NetworkUtil.initializeNetworkListener().catch((error) => {
      Logger.error(TAG, `Failed to initialize network listener after adding: ${error}`);
    });
    
    // 返回取消监听的函数
    return () => {
      NetworkUtil.removeNetworkStatusListener(listener);
    };
  }

  /**
   * 移除网络状态监听器
   * @param listener 要移除的监听器
   */
  public static removeNetworkStatusListener(listener: (isOnline: boolean, networkType: string) => void): void {
    NetworkUtil.networkStatusListeners.delete(listener);
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
  public static async downloadText(url: string, options?: DownloadTextOptions): Promise<string> {
    try {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 初始化header对象
      const headers = options?.headers || {};
      
      const downloadOptions: http.HttpRequestOptions = {
        method: 'GET',
        header: headers,
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
      throw new Error(String(error));
    }
  }

  /**
   * 构建查询字符串
   * @param params 查询参数对象
   * @returns 构建好的查询字符串
   */
  private static buildQueryString(params: Record<string, string | number | boolean | string[]>): string {
    const parts: string[] = [];
    const keys = NetworkUtil.getObjectKeys(params);
    
    for (const key of keys) {
      const value = params[key];
      if (Array.isArray(value)) {
        // 处理数组参数
        for (const item of value) {
          const encodedKey = encodeURIComponent(key);
          const encodedValue = encodeURIComponent(String(item));
          parts.push(`${encodedKey}=${encodedValue}`);
        }
      } else {
        const encodedKey = encodeURIComponent(key);
        const encodedValue = encodeURIComponent(String(value));
        parts.push(`${encodedKey}=${encodedValue}`);
      }
    }
    
    return parts.join('&');
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
   * @returns Promise<T>
   */
  public static async cachedRequest<T>(url: string, cacheTime: number = 5 * 60 * 1000): Promise<T> {
    try {
      const cacheKey = `network_cache_${url.replace(/[^a-zA-Z0-9]/g, '_')}`;
      
      // 尝试从缓存获取数据
      const cacheManager = CacheManager.getInstance();
      
      if (cacheManager) {
        try {
          const cachedData = cacheManager.get(cacheKey);
          if (cachedData && typeof cachedData === 'string') {
            const parsedData = JSON.parse(cachedData);
            const cacheData = parsedData.data;
            const timestamp = parsedData.timestamp;
            const now = Date.now();
            
            // 检查缓存是否有效
            if (now - timestamp < cacheTime) {
              Logger.info(TAG, `Using cached data for ${url}`);
              // 明确指定返回类型
              return cacheData as T;
            }
          }
        } catch (cacheError) {
          Logger.warn(TAG, `Cache read error: ${cacheError}`);
          // 缓存读取失败，继续发送网络请求
        }
      }
      
      // 检查网络状态
      const isNetworkAvailable = await NetworkUtil.checkNetworkStatus();
      if (!isNetworkAvailable) {
        // 离线模式，尝试返回旧缓存（即使过期）
        if (cacheManager) {
          try {
            const oldCachedData = cacheManager.get(cacheKey);
            if (oldCachedData && typeof oldCachedData === 'string') {
              Logger.warn(TAG, `Offline mode: using expired cache for ${url}`);
              const parsedData = JSON.parse(oldCachedData);
              const cacheData = parsedData.data;
              // 明确指定返回类型
              return cacheData as T;
            }
          } catch (offlineCacheError) {
            Logger.error(TAG, `Offline cache error: ${offlineCacheError}`);
          }
        }
        throw new Error('Network unavailable and no cached data available');
      }
      
      // 缓存无效或不存在，发送新请求
      const response = await NetworkUtil.get<T>(url);
      
      // 保存新缓存
      const cacheData = {
        data: response.data,
        timestamp: Date.now()
      };
      
      // 尝试保存到缓存
      if (cacheManager) {
        try {
          cacheManager.set(cacheKey, JSON.stringify(cacheData));
          Logger.info(TAG, `Cached response for ${url}`);
        } catch (cacheWriteError) {
          Logger.warn(TAG, `Cache write error: ${cacheWriteError}`);
          // 缓存写入失败，继续返回数据
        }
      }
      
      return response.data;
    } catch (error) {
      Logger.error(TAG, `Cached request failed: ${error}`);
      // 确保错误是Error类型
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(String(error));
      }
    }
  }
}

// 定义接口以替代对象字面量作为类型
export interface CacheData {
  data: string;
  timestamp: number;
  expirationTime?: number;
}

export interface NetworkCacheItem {
  key: string;
  data: string;
  timestamp: number;
  expirationTime?: number;
}

// 修复throw语句不能接受任意类型的问题
export function createNetworkError(message: string, code?: number): Error {
  const error = new Error(message);
  // 避免使用Object.assign，直接设置属性
  if (code) {
    // 使用类型断言为Error添加code属性
    Object.defineProperty(error, 'code', {
      value: code,
      writable: false,
      enumerable: true,
      configurable: true
    });
  }
  return error;
}