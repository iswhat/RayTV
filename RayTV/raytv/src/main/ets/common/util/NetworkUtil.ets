// NetworkUtil - 网络请求和连接管理工具类
import Logger from './Logger';
import http from '@ohos.net.http';
import connection from '@ohos.net.connection';

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
 * 网络工具类，提供网络请求和连接管理功能
 */
export class NetworkUtil {
  /**
   * 网络状态监听器集合
   */
  private static networkStatusListeners: Set<(isOnline: boolean, networkType: string) => void> = new Set();

  /**
   * 发送网络请求
   * @param config 请求配置
   * @returns Promise<Response<T>>
   */
  public static request<T>(config: RequestConfig): Promise<Response<T>> {
    return new Promise((resolve, reject) => {
      try {
        // 创建HTTP请求
        const httpRequest = http.createHttp();
        
        // 构建请求选项
        const requestOptions: http.HttpRequestOptions = {
          method: config.method as http.RequestMethod || http.RequestMethod.GET,
          header: config.headers || {},
          connectTimeout: config.timeout || 30000,
          readTimeout: config.timeout || 30000
        };
        
        // 发送请求
        httpRequest.request(config.url, requestOptions)
          .then((response) => {
            httpRequest.destroy();
            
            // 处理响应
            const result: Response<T> = {
              status: response.responseCode,
              statusText: response.responseCode.toString(),
              data: response.result as T,
              headers: response.header as Record<string, string> || {}
            };
            
            resolve(result);
          })
          .catch((error) => {
            httpRequest.destroy();
            Logger.error(TAG, `Request failed: ${error instanceof Error ? error.message : String(error)}`);
            reject(error instanceof Error ? error : new Error(String(error)));
          });
      } catch (error) {
        Logger.error(TAG, `Request initialization failed: ${error instanceof Error ? error.message : String(error)}`);
        reject(error instanceof Error ? error : new Error(String(error)));
      }
    });
  }

  /**
   * GET请求配置接口
   */
  export interface GetRequestConfig {
    headers?: Record<string, string>;
    params?: Record<string, string | number | boolean | string[]>;
    timeout?: number;
    responseType?: 'text' | 'json' | 'arraybuffer';
  }

  /**
   * POST请求配置接口
   */
  export interface PostRequestConfig {
    headers?: Record<string, string>;
    params?: Record<string, string | number | boolean | string[]>;
    timeout?: number;
    responseType?: 'text' | 'json' | 'arraybuffer';
  }

  /**
   * 发送GET请求
   * @param url 请求URL
   * @param config 请求配置
   * @returns Promise<Response<T>>
   */
  public static get<T>(url: string, config?: GetRequestConfig): Promise<Response<T>> {
    // 手动合并配置对象，避免使用扩展运算符
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
   * 发送POST请求
   * @param url 请求URL
   * @param data 请求数据
   * @param config 请求配置
   * @returns Promise<Response<T>>
   */
  public static post<T>(url: string, data?: RequestConfig['data'], config?: PostRequestConfig): Promise<Response<T>> {
    // 手动合并配置对象，避免使用扩展运算符
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
   * 下载文本内容
   * @param url 文本URL
   * @param options 下载选项
   * @returns Promise<string>
   */
  public static downloadText(url: string, options?: DownloadTextOptions): Promise<string> {
    return new Promise((resolve, reject) => {
      try {
        // 创建HTTP请求
        const httpRequest = http.createHttp();
        
        // 初始化header对象
        const headers = options?.headers || {};
        
        const downloadOptions: http.HttpRequestOptions = {
          method: 'GET' as http.RequestMethod,
          header: headers,
          connectTimeout: options?.timeout || 30000,
          readTimeout: options?.timeout || 30000
        };

        // 发送请求
        httpRequest.request(url, downloadOptions)
          .then((response) => {
            httpRequest.destroy();
            
            // 检查响应状态
            if (response.responseCode < 200 || response.responseCode >= 300) {
              reject(new Error(`Download failed with status ${response.responseCode}`));
              return;
            }
            
            // 返回文本内容
            resolve(response.result as string);
          })
          .catch((error) => {
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
   * 获取当前是否在线
   * @returns 是否在线的Promise
   */
  public static isOnline(): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        // 使用简化的网络状态检查
        resolve(true); // 暂时总是返回在线，实际项目中需要根据具体API调整
      } catch (error) {
        Logger.warn(TAG, `Failed to check online status: ${error instanceof Error ? error.message : String(error)}`);
        resolve(false);
      }
    });
  }

  /**
   * 获取网络类型
   * @returns 网络类型
   */
  public static getNetworkType(): Promise<string> {
    return new Promise((resolve) => {
      try {
        // 使用简化的网络类型检测
        resolve('unknown'); // 暂时返回unknown，实际项目中需要根据具体API调整
      } catch (error) {
        Logger.warn(TAG, `Failed to detect network type: ${error instanceof Error ? error.message : String(error)}`);
        resolve('unknown');
      }
    });
  }

  /**
   * 创建带缓存的请求
   * @param url 请求URL
   * @param cacheTime 缓存时间（毫秒）
   * @returns Promise<T>
   */
  public static cachedRequest<T>(url: string, cacheTime: number = 5 * 60 * 1000): Promise<T> {
    return new Promise((resolve, reject) => {
      try {
        // 简化实现，直接发送网络请求，不使用缓存
        NetworkUtil.downloadText(url)
          .then((response) => {
            const data: T = JSON.parse(response) as T;
            resolve(data);
          })
          .catch((error) => {
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
