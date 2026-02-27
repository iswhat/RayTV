// NetworkUtil - 网络请求和连接管理工具类 Network Request and Connection Management Utility Class
import Logger from './Logger';
import http from '@ohos.net.http';
import connection from '@ohos.net.connection';

const TAG = 'NetworkUtil';

/**
 * 网络请求配置接口 Network Request Configuration Interface
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
 * 网络响应接口 Network Response Interface
 */
export interface Response<T> {
  status: number;
  statusText: string;
  data: T;
  headers: Record<string, string>;
}

/**
 * 文件下载选项接口 File Download Options Interface
 */
export interface DownloadOptions {
  headers?: Record<string, string>;
  timeout?: number;
  onProgress?: (receivedSize: number, totalSize: number) => void;
}

/**
 * 文本下载选项接口 Text Download Options Interface
 */
export interface DownloadTextOptions {
  headers?: Record<string, string>;
  timeout?: number;
}

/**
 * GET请求配置接口 GET Request Configuration Interface
 */
export interface GetRequestConfig {
  headers?: Record<string, string>;
  params?: Record<string, string | number | boolean | string[]>;
  timeout?: number;
  responseType?: 'text' | 'json' | 'arraybuffer';
}

/**
 * POST请求配置接口 POST Request Configuration Interface
 */
export interface PostRequestConfig {
  headers?: Record<string, string>;
  params?: Record<string, string | number | boolean | string[]>;
  timeout?: number;
  responseType?: 'text' | 'json' | 'arraybuffer';
}

/**
 * NetworkUtil - 网络工具类 Network Utility Class
 * 提供网络请求和连接管理功能 Provides network request and connection management functionality
 */
export class NetworkUtil {
  /**
   * 网络状态监听器集合 Network Status Listeners Collection
   */
  private static networkStatusListeners: Set<(isOnline: boolean, networkType: string) => void> = new Set();

  /**
   * 清理敏感信息 | Clean sensitive info
   * @param headers Headers object | 头部对象
   * @returns Cleaned headers object | 清理后的头部对象
   */
  private static cleanSensitiveInfo(headers: Record<string, string>): Record<string, string> {
    const sensitiveHeaders = ['Authorization', 'token', 'password', 'apiKey', 'secret'];
    const cleanedHeaders: Record<string, string> = {};
    
    for (const [key, value] of Object.entries(headers)) {
      if (sensitiveHeaders.some(sensitiveKey => 
        key.toLowerCase().includes(sensitiveKey.toLowerCase())
      )) {
        cleanedHeaders[key] = '***';
      } else {
        cleanedHeaders[key] = value;
      }
    }
    
    return cleanedHeaders;
  }

  /**
   * 发送网络请求 Send Network Request
   * @param config 请求配置 Request Configuration
   * @returns Promise<Response<T>>
   */
  public static request<T>(config: RequestConfig): Promise<Response<T>> {
    return new Promise((resolve: (value: Response<T>) => void, reject: (reason: Error) => void) => {
      try {
        // 创建HTTP请求 Create HTTP Request
        const httpRequest = http.createHttp();
        
        // 构建请求选项 Build Request Options
        const headers: Record<string, string> = config.headers || {};
        const requestOptions: http.HttpRequestOptions = {
          method: (config.method as http.RequestMethod) || http.RequestMethod.GET,
          header: headers,
          connectTimeout: config.timeout || 30000,
          readTimeout: config.timeout || 30000
        };
        
        // 发送请求 Send Request
        httpRequest.request(config.url, requestOptions)
          .then((response: http.HttpResponse) => {
            httpRequest.destroy();
            
            // 处理响应 Handle Response
            const result: Response<T> = {
              status: response.responseCode,
              statusText: response.responseCode.toString(),
              data: response.result as T,
              headers: (response.header || {}) as Record<string, string>
            };
            
            resolve(result);
          })
          .catch((error: Error) => {
            httpRequest.destroy();
            const errorMessage = error instanceof Error ? error.message : String(error);
            // 清理敏感信息后记录日志 | Log after cleaning sensitive info
            const cleanedHeaders = this.cleanSensitiveInfo(headers);
            Logger.error(TAG, `Request failed: ${errorMessage}, URL: ${config.url}, Headers: ${JSON.stringify(cleanedHeaders)}`);
            reject(error instanceof Error ? error : new Error(errorMessage));
          });
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        Logger.error(TAG, `Request initialization failed: ${errorMessage}`);
        reject(error instanceof Error ? error : new Error(errorMessage));
      }
    });
  }

  /**
   * 发送GET请求 Send GET Request
   * @param url 请求URL Request URL
   * @param config 请求配置 Request Configuration
   * @returns Promise<Response<T>>
   */
  public static get<T>(url: string, config?: GetRequestConfig): Promise<Response<T>> {
    // 手动合并配置对象，避免使用扩展运算符 Manually merge configuration objects, avoid using spread operator
    const requestConfig: RequestConfig = {
      url,
      method: 'GET',
      headers: config?.headers,
      params: config?.params,
      timeout: config?.timeout,
      responseType: config?.responseType
    };
    return NetworkUtil.request<T>(requestConfig);
  }

  /**
   * 发送POST请求 Send POST Request
   * @param url 请求URL Request URL
   * @param data 请求数据 Request Data
   * @param config 请求配置 Request Configuration
   * @returns Promise<Response<T>>
   */
  public static post<T>(url: string, data?: string | number | boolean | Record<string, string | number | boolean | null>, config?: PostRequestConfig): Promise<Response<T>> {
    // 手动合并配置对象，避免使用扩展运算符 Manually merge configuration objects, avoid using spread operator
    const requestConfig: RequestConfig = {
      url,
      method: 'POST',
      data,
      headers: config?.headers,
      params: config?.params,
      timeout: config?.timeout,
      responseType: config?.responseType
    };
    return NetworkUtil.request<T>(requestConfig);
  }

  /**
   * 下载文本内容 Download Text Content
   * @param url 文本URL Text URL
   * @param options 下载选项 Download Options
   * @returns Promise<string>
   */
  public static downloadText(url: string, options?: DownloadTextOptions): Promise<string> {
    return new Promise((resolve: (value: string) => void, reject: (reason: Error) => void) => {
      try {
        // 创建HTTP请求 Create HTTP Request
        const httpRequest = http.createHttp();
        
        // 初始化header对象 Initialize header object
        const headers: Record<string, string> = options?.headers || {};
        
        const downloadOptions: http.HttpRequestOptions = {
          method: http.RequestMethod.GET,
          header: headers,
          connectTimeout: options?.timeout || 30000,
          readTimeout: options?.timeout || 30000
        };

        // 发送请求 Send Request
        httpRequest.request(url, downloadOptions)
          .then((response: http.HttpResponse) => {
            httpRequest.destroy();
            
            // 检查响应状态 Check response status
            if (response.responseCode < 200 || response.responseCode >= 300) {
              reject(new Error(`Download failed with status ${response.responseCode}`));
              return;
            }
            
            // 返回文本内容 Return text content
            resolve(response.result as string);
          })
          .catch((error: Error) => {
            httpRequest.destroy();
            const errorMessage = error instanceof Error ? error.message : String(error);
            Logger.error(TAG, `Failed to download text: ${errorMessage}`);
            reject(error instanceof Error ? error : new Error(errorMessage));
          });
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        Logger.error(TAG, `Failed to download text: ${errorMessage}`);
        reject(error instanceof Error ? error : new Error(errorMessage));
      }
    });
  }

  /**
   * 获取当前是否在线 Get Current Online Status
   * @returns 是否在线的Promise Promise of online status
   */
  public static isOnline(): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        // 尝试使用HarmonyOS网络连接API
        try {
          // 导入网络连接模块
          const connection = require('@ohos.net.connection');
          
          // 获取网络连接状态
          const netInfo = connection.getDefaultNetInfoSync();
          if (netInfo && netInfo.isAvailable) {
            resolve(true);
          } else {
            resolve(false);
          }
        } catch (harmonyError) {
          // HarmonyOS API不可用，使用备选方案
          Logger.warn(TAG, `HarmonyOS network API not available: ${harmonyError instanceof Error ? harmonyError.message : String(harmonyError)}`);
          
          // 尝试使用navigator.onLine（如果在Web环境中）
          if (typeof navigator !== 'undefined' && 'onLine' in navigator) {
            resolve(navigator.onLine);
          } else {
            // 无法检测，默认返回在线
            resolve(true);
          }
        }
      } catch (error) {
        Logger.warn(TAG, `Failed to check online status: ${error instanceof Error ? error.message : String(error)}`);
        resolve(false);
      }
    });
  }

  /**
   * 获取网络类型 Get Network Type
   * @returns 网络类型 Network Type
   */
  public static getNetworkType(): Promise<string> {
    return new Promise((resolve) => {
      try {
        // 尝试使用HarmonyOS网络连接API
        try {
          // 导入网络连接模块
          const connection = require('@ohos.net.connection');
          
          // 获取网络连接状态
          const netInfo = connection.getDefaultNetInfoSync();
          if (netInfo) {
            switch (netInfo.type) {
              case connection.NetBearType.BEARER_CELLULAR:
                resolve('cellular');
                break;
              case connection.NetBearType.BEARER_WIFI:
                resolve('wifi');
                break;
              case connection.NetBearType.BEARER_BLUETOOTH:
                resolve('bluetooth');
                break;
              case connection.NetBearType.BEARER_ETHERNET:
                resolve('ethernet');
                break;
              default:
                resolve('unknown');
                break;
            }
          } else {
            resolve('unknown');
          }
        } catch (harmonyError) {
          // HarmonyOS API不可用，使用备选方案
          Logger.warn(TAG, `HarmonyOS network API not available: ${harmonyError instanceof Error ? harmonyError.message : String(harmonyError)}`);
          
          // 尝试使用navigator.connection（如果在Web环境中）
          if (typeof navigator !== 'undefined' && 'connection' in navigator) {
            const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
            if (connection && connection.type) {
              resolve(connection.type);
            } else {
              resolve('unknown');
            }
          } else {
            // 无法检测，默认返回unknown
            resolve('unknown');
          }
        }
      } catch (error) {
        Logger.warn(TAG, `Failed to detect network type: ${error instanceof Error ? error.message : String(error)}`);
        resolve('unknown');
      }
    });
  }

  /**
   * 创建带缓存的请求 Create Cached Request
   * @param url 请求URL Request URL
   * @param cacheTime 缓存时间(毫秒) Cache Time (milliseconds)
   * @returns Promise<T>
   */
  public static cachedRequest<T>(url: string, cacheTime: number = 5 * 60 * 1000): Promise<T> {
    return new Promise((resolve: (value: T) => void, reject: (reason: Error) => void) => {
      try {
        // 简化实现，直接发送网络请求，不使用缓存 Simplified implementation, directly send network request, no cache used
        NetworkUtil.downloadText(url)
          .then((response: string) => {
            const parsedData: T = JSON.parse(response) as T;
            resolve(parsedData);
          })
          .catch((error: Error) => {
            const errorMessage = error instanceof Error ? error.message : String(error);
            Logger.error(TAG, `Cached request failed: ${errorMessage}`);
            reject(error instanceof Error ? error : new Error(errorMessage));
          });
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        Logger.error(TAG, `Cached request failed: ${errorMessage}`);
        reject(error instanceof Error ? error : new Error(errorMessage));
      }
    });
  }
}

export default NetworkUtil;



