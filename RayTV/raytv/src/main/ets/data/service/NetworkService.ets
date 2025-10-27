// NetworkService - 网络服务类
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil, { RequestConfig, Response } from '../../common/util/NetworkUtil';

// 网络错误类
export class NetworkError extends Error {
  constructor(message: string, public options?: { code?: string; status?: number; data?: any }) {
    super(message);
    this.name = 'NetworkError';
  }
}

// 网络选项接口
export interface NetworkOptions extends RequestConfig {
  useCache?: boolean;
  cacheExpiry?: number;
  enableCompression?: boolean;
  enableGzip?: boolean;
  verifySSL?: boolean;
  fetchOptions?: any;
}

// 网络响应接口
export interface NetworkResponse<T = any> extends Response<T> {
  success: boolean;
  fromCache?: boolean;
  error?: { message: string; code?: string };
}

// 常量定义
const TAG = 'NetworkService';
const NETWORK_CACHE_KEY = 'network_cache';
const NETWORK_CONFIG_KEY = 'network_config';
const MAX_RETRY_COUNT = 3;
const DEFAULT_TIMEOUT = 30000;
const DEFAULT_RETRY_DELAY = 1000;
const CACHE_EXPIRY_DEFAULT = 300000; // 5分钟

// 网络连接状态枚举
export enum NetworkStatus {
  IDLE = 'idle',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  DISCONNECTED = 'disconnected',
  ERROR = 'error'
}

// 网络类型枚举
export enum NetworkType {
  UNKNOWN = 'unknown',
  WIFI = 'wifi',
  CELLULAR = 'cellular',
  ETHERNET = 'ethernet',
  NONE = 'none'
}

// 网络代理类型枚举
export enum ProxyType {
  NONE = 'none',
  HTTP = 'http',
  HTTPS = 'https',
  SOCKS5 = 'socks5',
  AUTO = 'auto'
}

// 代理配置接口
export interface ProxyConfig {
  type: ProxyType;
  host: string;
  port: number;
  username?: string;
  password?: string;
  bypass?: string[];
}

// 网络配置接口
export interface NetworkConfig {
  enableCache: boolean;
  cacheExpiry: number;
  timeout: number;
  retryCount: number;
  retryDelay: number;
  enableCompression: boolean;
  enableGzip: boolean;
  keepAlive: boolean;
  keepAliveTimeout: number;
  proxy: ProxyConfig;
  userAgent?: string;
  defaultHeaders?: Record<string, string>;
  maxConcurrentRequests: number;
  enableDNSCache: boolean;
  dnsCacheExpiry: number;
  verifySSL: boolean;
}

// 网络统计信息接口
export interface NetworkStats {
  totalRequests: number;
  successfulRequests: number;
  failedRequests: number;
  totalBytesSent: number;
  totalBytesReceived: number;
  averageResponseTime: number;
  errorRates: Record<string, number>;
  lastRequestTime: number;
  lastErrorTime?: number;
  lastError?: string;
}

// 网络监控选项接口
export interface NetworkMonitorOptions {
  enableReachabilityCheck: boolean;
  reachabilityCheckInterval: number;
  enableBandwidthTest: boolean;
  bandwidthTestInterval: number;
  enableResponseTimeMonitor: boolean;
  responseTimeThreshold: number;
}

// 带宽测试结果接口
export interface BandwidthTestResult {
  uploadSpeed: number; // bytes per second
  downloadSpeed: number; // bytes per second
  ping: number; // milliseconds
  timestamp: number;
  serverUrl: string;
  error?: string;
}

// 缓存项接口
export interface NetworkCacheItem {
  url: string;
  method: string;
  params?: any;
  headers?: Record<string, string>;
  response: any;
  status: number;
  timestamp: number;
  expiry: number;
}

// 请求拦截器接口
export interface RequestInterceptor {
  (options: NetworkOptions): Promise<NetworkOptions>;
}

// 响应拦截器接口
export interface ResponseInterceptor {
  (response: NetworkResponse<any>): Promise<NetworkResponse<any>>;
}

// 错误拦截器接口
export interface ErrorInterceptor {
  (error: NetworkError): Promise<NetworkError>;
}

// 默认网络配置
const DEFAULT_NETWORK_CONFIG: NetworkConfig = {
  enableCache: true,
  cacheExpiry: CACHE_EXPIRY_DEFAULT,
  timeout: DEFAULT_TIMEOUT,
  retryCount: MAX_RETRY_COUNT,
  retryDelay: DEFAULT_RETRY_DELAY,
  enableCompression: true,
  enableGzip: true,
  keepAlive: true,
  keepAliveTimeout: 60000,
  proxy: {
    type: ProxyType.NONE,
    host: '',
    port: 0
  },
  maxConcurrentRequests: 10,
  enableDNSCache: true,
  dnsCacheExpiry: 300000,
  verifySSL: true
};

/**
 * 网络服务类
 * 负责管理网络连接、请求重试、网络状态监控等功能
 */
export default class NetworkService {
  private static instance: NetworkService;
  
  private networkConfig: NetworkConfig = { ...DEFAULT_NETWORK_CONFIG };
  private networkStatus: NetworkStatus = NetworkStatus.IDLE;
  private networkType: NetworkType = NetworkType.UNKNOWN;
  private networkStats: NetworkStats = this.createDefaultStats();
  private cache: Map<string, NetworkCacheItem> = new Map();
  private activeRequests: Set<string> = new Set();
  
  /**
   * 获取当前网络连接状态
   */
  public get isConnected(): boolean {
    return this.networkStatus === NetworkStatus.CONNECTED;
  }
  
  // 拦截器
  private requestInterceptors: RequestInterceptor[] = [];
  private responseInterceptors: ResponseInterceptor[] = [];
  private errorInterceptors: ErrorInterceptor[] = [];
  
  // 监听器
  private statusListeners: Array<(status: NetworkStatus, type: NetworkType) => void> = [];
  private statsListeners: Array<(stats: NetworkStats) => void> = [];
  private bandwidthListeners: Array<(result: BandwidthTestResult) => void> = [];
  
  // 监控配置
  private monitorOptions: NetworkMonitorOptions = {
    enableReachabilityCheck: true,
    reachabilityCheckInterval: 60000,
    enableBandwidthTest: false,
    bandwidthTestInterval: 300000,
    enableResponseTimeMonitor: true,
    responseTimeThreshold: 5000
  };
  
  private reachabilityTimer?: number;
  private bandwidthTestTimer?: number;
  private isInitialized: boolean = false;
  private lastConnectTime: number = 0;
  
  /**
   * 构造函数（私有，防止外部实例化）
   */
  private constructor() {
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): NetworkService {
    if (!NetworkService.instance) {
      NetworkService.instance = new NetworkService();
    }
    return NetworkService.instance;
  }

  /**
   * 创建默认统计信息
   */
  private createDefaultStats(): NetworkStats {
    return {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      totalBytesSent: 0,
      totalBytesReceived: 0,
      averageResponseTime: 0,
      errorRates: {},
      lastRequestTime: 0
    };
  }

  /**
   * 初始化网络服务
   */
  private async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing network service...');
      
      // 加载网络配置
      const savedConfig = await StorageUtil.getObject<NetworkConfig>(NETWORK_CONFIG_KEY);
      if (savedConfig) {
        this.networkConfig = { ...DEFAULT_NETWORK_CONFIG, ...savedConfig };
      }
      
      // 加载缓存数据
      const savedCache = await StorageUtil.getObject<Record<string, NetworkCacheItem>>(NETWORK_CACHE_KEY);
      if (savedCache) {
        const now = Date.now();
        // 过滤过期缓存
        for (const [key, item] of Object.entries(savedCache)) {
          if (item.expiry > now) {
            this.cache.set(key, item);
          }
        }
      }
      
      // 初始化网络状态
      await this.checkNetworkStatus();
      
      // 启动网络监控
      this.startMonitoring();
      
      // 应用网络配置到NetworkUtil
      this.applyNetworkConfig();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Network service initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize network service', error);
    }
  }

  /**
   * 应用网络配置到NetworkUtil
   */
  private applyNetworkConfig(): void {
    try {
      // 这里应该设置NetworkUtil的全局配置
      // 例如设置代理、超时时间等
      Logger.debug(TAG, 'Applied network config to NetworkUtil');
    } catch (error) {
      Logger.error(TAG, 'Failed to apply network config', error);
    }
  }

  /**
   * 保存网络配置
   */
  private async saveNetworkConfig(): Promise<void> {
    try {
      await StorageUtil.setObject(NETWORK_CONFIG_KEY, this.networkConfig);
      Logger.debug(TAG, 'Saved network config');
    } catch (error) {
      Logger.error(TAG, 'Failed to save network config', error);
    }
  }

  /**
   * 保存缓存数据
   */
  private async saveCache(): Promise<void> {
    try {
      const cacheObj: Record<string, NetworkCacheItem> = {};
      this.cache.forEach((item, key) => {
        cacheObj[key] = item;
      });
      await StorageUtil.setObject(NETWORK_CACHE_KEY, cacheObj);
      Logger.debug(TAG, `Saved ${this.cache.size} cache items`);
    } catch (error) {
      Logger.error(TAG, 'Failed to save cache', error);
    }
  }

  /**
   * 设置网络配置
   */
  public async setNetworkConfig(config: Partial<NetworkConfig>): Promise<NetworkConfig> {
    try {
      // 更新配置
      this.networkConfig = {
        ...this.networkConfig,
        ...config
      };
      
      // 保存配置
      await this.saveNetworkConfig();
      
      // 应用配置
      this.applyNetworkConfig();
      
      Logger.info(TAG, 'Updated network config');
      return { ...this.networkConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to update network config', error);
      return { ...this.networkConfig };
    }
  }

  /**
   * 获取网络配置
   */
  public getNetworkConfig(): NetworkConfig {
    return { ...this.networkConfig };
  }

  /**
   * 重置网络配置为默认值
   */
  public async resetNetworkConfig(): Promise<NetworkConfig> {
    try {
      this.networkConfig = { ...DEFAULT_NETWORK_CONFIG };
      
      // 保存配置
      await this.saveNetworkConfig();
      
      // 应用配置
      this.applyNetworkConfig();
      
      Logger.info(TAG, 'Reset network config to default');
      return { ...this.networkConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to reset network config', error);
      return { ...this.networkConfig };
    }
  }

  /**
   * 检查网络状态
   */
  public async checkNetworkStatus(): Promise<{ status: NetworkStatus; type: NetworkType }> {
    try {
      // 实际应用中，这里应该使用系统API检查网络状态
      // 这里简化为模拟实现
      const isConnected = await NetworkUtil.checkNetworkStatus();
      const networkTypeStr = await NetworkUtil.getNetworkType();
      
      // 将string类型的网络类型转换为NetworkType枚举
      let networkType: NetworkType = NetworkType.UNKNOWN;
      if (networkTypeStr.includes('wifi') || networkTypeStr.includes('ethernet')) {
        networkType = NetworkType.WIFI;
      } else if (networkTypeStr.includes('4g') || networkTypeStr.includes('5g') || networkTypeStr.includes('3g') || networkTypeStr.includes('cellular')) {
        networkType = NetworkType.CELLULAR;
      }
      
      let newStatus: NetworkStatus;
      if (isConnected) {
        newStatus = NetworkStatus.CONNECTED;
        this.lastConnectTime = Date.now();
      } else {
        newStatus = NetworkStatus.DISCONNECTED;
      }
      
      // 如果状态或类型发生变化，通知监听器
      if (this.networkStatus !== newStatus || this.networkType !== networkType) {
        this.networkStatus = newStatus;
        this.networkType = networkType;
        this.notifyStatusChanged();
      }
      
      Logger.debug(TAG, `Network status: ${this.networkStatus}, type: ${this.networkType}`);
      return { status: this.networkStatus, type: this.networkType };
    } catch (error) {
      Logger.error(TAG, 'Failed to check network status', error);
      this.networkStatus = NetworkStatus.ERROR;
      this.notifyStatusChanged();
      return { status: NetworkStatus.ERROR, type: NetworkType.UNKNOWN };
    }
  }

  /**
   * 获取当前网络状态
   */
  public getNetworkStatus(): { status: NetworkStatus; type: NetworkType } {
    return { status: this.networkStatus, type: this.networkType };
  }

  /**
   * 开始网络监控
   */
  private startMonitoring(): void {
    try {
      // 停止之前的监控
      this.stopMonitoring();
      
      // 开始可达性检查
      if (this.monitorOptions.enableReachabilityCheck) {
        this.reachabilityTimer = setInterval(() => {
          this.checkNetworkStatus();
        }, this.monitorOptions.reachabilityCheckInterval);
        Logger.debug(TAG, 'Started reachability monitoring');
      }
      
      // 开始带宽测试
      if (this.monitorOptions.enableBandwidthTest) {
        this.bandwidthTestTimer = setInterval(() => {
          this.testBandwidth();
        }, this.monitorOptions.bandwidthTestInterval);
        Logger.debug(TAG, 'Started bandwidth monitoring');
      }
      
      Logger.info(TAG, 'Network monitoring started');
    } catch (error) {
      Logger.error(TAG, 'Failed to start network monitoring', error);
    }
  }

  /**
   * 停止网络监控
   */
  private stopMonitoring(): void {
    try {
      if (this.reachabilityTimer) {
        clearInterval(this.reachabilityTimer);
        this.reachabilityTimer = undefined;
      }
      
      if (this.bandwidthTestTimer) {
        clearInterval(this.bandwidthTestTimer);
        this.bandwidthTestTimer = undefined;
      }
      
      Logger.info(TAG, 'Network monitoring stopped');
    } catch (error) {
      Logger.error(TAG, 'Failed to stop network monitoring', error);
    }
  }

  /**
   * 设置网络监控选项
   */
  public setMonitorOptions(options: Partial<NetworkMonitorOptions>): void {
    try {
      this.monitorOptions = {
        ...this.monitorOptions,
        ...options
      };
      
      // 重新启动监控
      this.startMonitoring();
      
      Logger.info(TAG, 'Updated network monitor options');
    } catch (error) {
      Logger.error(TAG, 'Failed to update monitor options', error);
    }
  }

  /**
   * 测试带宽
   */
  public async testBandwidth(
    uploadSize: number = 1024 * 1024, // 1MB
    downloadUrl?: string
  ): Promise<BandwidthTestResult> {
    try {
      const result: BandwidthTestResult = {
        uploadSpeed: 0,
        downloadSpeed: 0,
        ping: 0,
        timestamp: Date.now(),
        serverUrl: downloadUrl || 'https://www.example.com/1mb.bin'
      };
      
      // 测量延迟
      const startTime = Date.now();
      await NetworkUtil.ping('https://www.example.com');
      result.ping = Date.now() - startTime;
      
      // 测量下载速度
      const downloadStartTime = Date.now();
      const downloadResult = await NetworkUtil.downloadFile(
        result.serverUrl,
        `${Date.now()}_test.bin`,
        {
          timeout: 10000,
          onProgress: (progress) => {
            Logger.debug(TAG, `Bandwidth test download progress: ${progress}%`);
          }
        }
      );
      
      if (downloadResult.success) {
        const downloadDuration = (Date.now() - downloadStartTime) / 1000;
        result.downloadSpeed = downloadResult.size / downloadDuration;
      }
      
      // 通知监听器
      this.notifyBandwidthTestCompleted(result);
      
      Logger.info(TAG, `Bandwidth test completed - Download: ${this.formatSpeed(result.downloadSpeed)}, Ping: ${result.ping}ms`);
      return result;
    } catch (error) {
      Logger.error(TAG, 'Failed to test bandwidth', error);
      const result: BandwidthTestResult = {
        uploadSpeed: 0,
        downloadSpeed: 0,
        ping: 0,
        timestamp: Date.now(),
        serverUrl: downloadUrl || 'https://www.example.com/1mb.bin',
        error: String(error)
      };
      
      // 通知监听器
      this.notifyBandwidthTestCompleted(result);
      
      return result;
    }
  }

  /**
   * 格式化速度显示
   */
  private formatSpeed(bytesPerSecond: number): string {
    if (bytesPerSecond < 1024) {
      return `${bytesPerSecond.toFixed(2)} B/s`;
    } else if (bytesPerSecond < 1024 * 1024) {
      return `${(bytesPerSecond / 1024).toFixed(2)} KB/s`;
    } else {
      return `${(bytesPerSecond / (1024 * 1024)).toFixed(2)} MB/s`;
    }
  }

  /**
   * 构建缓存键
   */
  private buildCacheKey(url: string, method: string, params?: any): string {
    const paramsStr = params ? JSON.stringify(params) : '';
    return `${method}_${url}_${paramsStr}`;
  }

  /**
   * 检查缓存是否有效
   */
  private isCacheValid(cacheItem: NetworkCacheItem): boolean {
    return Date.now() < cacheItem.expiry;
  }

  /**
   * 获取缓存
   */
  private getCache(url: string, method: string, params?: any): NetworkCacheItem | null {
    const cacheKey = this.buildCacheKey(url, method, params);
    const cacheItem = this.cache.get(cacheKey);
    
    if (cacheItem && this.isCacheValid(cacheItem)) {
      Logger.debug(TAG, `Cache hit for ${url}`);
      return cacheItem;
    }
    
    // 移除过期缓存
    if (cacheItem) {
      this.cache.delete(cacheKey);
    }
    
    Logger.debug(TAG, `Cache miss for ${url}`);
    return null;
  }

  /**
   * 设置缓存
   */
  private setCache(
    url: string,
    method: string,
    params: any,
    response: any,
    status: number,
    expiry?: number
  ): void {
    const cacheKey = this.buildCacheKey(url, method, params);
    const actualExpiry = expiry || Date.now() + this.networkConfig.cacheExpiry;
    
    const cacheItem: NetworkCacheItem = {
      url,
      method,
      params,
      response,
      status,
      timestamp: Date.now(),
      expiry: actualExpiry
    };
    
    this.cache.set(cacheKey, cacheItem);
    
    // 限制缓存大小（最多1000个条目）
    if (this.cache.size > 1000) {
      // 移除最旧的缓存
      const oldestKey = this.cache.keys().next().value;
      if (oldestKey) {
        this.cache.delete(oldestKey);
      }
    }
    
    // 异步保存缓存
    this.saveCache().catch(error => {
      Logger.error(TAG, 'Failed to save cache after setting', error);
    });
    
    Logger.debug(TAG, `Cache set for ${url}, expiry: ${new Date(actualExpiry).toISOString()}`);
  }

  /**
   * 执行HTTP请求
   */
  public async request<T = any>(
    url: string,
    method: string = 'GET',
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<T>> {
    // 检查初始化状态
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    // 检查网络连接
    const { status } = await this.checkNetworkStatus();
    if (status !== NetworkStatus.CONNECTED) {
      throw new NetworkError('Network not connected', { code: 'NETWORK_DISCONNECTED' });
    }
    
    // 生成请求ID
    const requestId = `${method}_${url}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const startTime = Date.now();
    
    // 记录活动请求
    this.activeRequests.add(requestId);
    
    // 更新请求统计
    this.updateRequestStats('start');
    
    try {
      // 合并选项与默认配置
      const requestOptions: NetworkOptions = {
        ...options,
        method,
        timeout: options.timeout || this.networkConfig.timeout,
        headers: {
          ...this.networkConfig.defaultHeaders,
          ...options.headers
        },
        enableCompression: options.enableCompression !== undefined ? options.enableCompression : this.networkConfig.enableCompression,
        enableGzip: options.enableGzip !== undefined ? options.enableGzip : this.networkConfig.enableGzip,
        verifySSL: options.verifySSL !== undefined ? options.verifySSL : this.networkConfig.verifySSL
      };
      
      // 处理缓存
      let useCache = this.networkConfig.enableCache && 
                    method === 'GET' && 
                    options.useCache !== false;
      
      if (useCache) {
        const cacheItem = this.getCache(url, method, options.params);
        if (cacheItem) {
          this.updateRequestStats('success', Date.now() - startTime);
          this.activeRequests.delete(requestId);
          
          return {
            success: true,
            data: cacheItem.response as T,
            status: cacheItem.status,
            headers: {},
            fromCache: true
          };
        }
      }
      
      // 应用请求拦截器
      let interceptedOptions = { ...requestOptions };
      for (const interceptor of this.requestInterceptors) {
        interceptedOptions = await interceptor(interceptedOptions);
      }
      
      // 重试机制
      let lastError: any;
      for (let attempt = 0; attempt <= this.networkConfig.retryCount; attempt++) {
        try {
          // 执行请求
          const response = await NetworkUtil.request<T>(url, interceptedOptions);
          
          // 应用响应拦截器
          let interceptedResponse = response;
          for (const interceptor of this.responseInterceptors) {
            interceptedResponse = await interceptor(interceptedResponse);
          }
          
          // 保存到缓存
          if (useCache && interceptedResponse.success) {
            this.setCache(
              url, 
              method, 
              options.params,
              interceptedResponse.data,
              interceptedResponse.status,
              options.cacheExpiry
            );
          }
          
          // 更新统计信息
          this.updateRequestStats('success', Date.now() - startTime);
          
          // 检查响应时间阈值
          const responseTime = Date.now() - startTime;
          if (this.monitorOptions.enableResponseTimeMonitor && 
              responseTime > this.monitorOptions.responseTimeThreshold) {
            Logger.warn(TAG, `Slow response detected: ${responseTime}ms for ${url}`);
          }
          
          this.activeRequests.delete(requestId);
          return interceptedResponse;
        } catch (error) {
          lastError = error;
          
          // 最后一次尝试失败，不再重试
          if (attempt === this.networkConfig.retryCount) {
            break;
          }
          
          // 计算重试延迟（指数退避）
          const delay = this.networkConfig.retryDelay * Math.pow(2, attempt);
          Logger.warn(TAG, `Request failed, retrying in ${delay}ms... (attempt ${attempt + 1}/${this.networkConfig.retryCount})`, error);
          
          // 等待重试延迟
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
      
      // 处理错误
      let errorToThrow = lastError as NetworkError;
      
      // 应用错误拦截器
      for (const interceptor of this.errorInterceptors) {
        errorToThrow = await interceptor(errorToThrow);
      }
      
      // 更新统计信息
      this.updateRequestStats('error', Date.now() - startTime, errorToThrow.message || 'Unknown error');
      
      this.activeRequests.delete(requestId);
      throw errorToThrow;
    } catch (error) {
      // 确保统计信息更新
      this.updateRequestStats('error', Date.now() - startTime, error instanceof Error ? error.message : 'Unknown error');
      this.activeRequests.delete(requestId);
      throw error;
    }
  }

  /**
   * GET请求
   */
  public async get<T = any>(
    url: string,
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<T>> {
    return this.request<T>(url, 'GET', {
      ...options
    });
  }

  /**
   * POST请求
   */
  public async post<T = any>(
    url: string,
    data?: any,
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<T>> {
    return this.request<T>(url, 'POST', {
      ...options,
      data
    });
  }

  /**
   * PUT请求
   */
  public async put<T = any>(
    url: string,
    data?: any,
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<T>> {
    return this.request<T>(url, 'PUT', {
      ...options,
      data
    });
  }

  /**
   * DELETE请求
   */
  public async delete<T = any>(
    url: string,
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<T>> {
    return this.request<T>(url, 'DELETE', options);
  }

  /**
   * PATCH请求
   */
  public async patch<T = any>(
    url: string,
    data?: any,
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<T>> {
    return this.request<T>(url, 'PATCH', {
      ...options,
      data
    });
  }

  /**
   * HEAD请求
   */
  public async head<T = any>(
    url: string,
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<T>> {
    return this.request<T>(url, 'HEAD', options);
  }

  /**
   * 下载文件
   */
  public async downloadFile(
    url: string,
    destination: string,
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<{ path: string; size?: number }>> {
    // 检查初始化状态
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    // 检查网络连接
    const { status } = await this.checkNetworkStatus();
    if (status !== NetworkStatus.CONNECTED) {
      throw new NetworkError('Network not connected', { code: 'NETWORK_DISCONNECTED' });
    }
    
    const requestId = `DOWNLOAD_${url}_${Date.now()}`;
    const startTime = Date.now();
    
    this.activeRequests.add(requestId);
    this.updateRequestStats('start');
    
    try {
      // 合并选项
      const downloadOptions: NetworkOptions = {
        ...options,
        method: 'GET',
        timeout: options.timeout || this.networkConfig.timeout * 2, // 下载超时更长
        verifySSL: options.verifySSL !== undefined ? options.verifySSL : this.networkConfig.verifySSL
      };
      
      // 执行下载（使用fetch API实现简单的文件下载）
      const response = await fetch(url, {
        method: 'GET',
        headers: downloadOptions.headers,
        signal: downloadOptions.fetchOptions?.signal
      });
      
      if (!response.ok) {
        throw new NetworkError(`Download failed: ${response.status}`, { status: response.status });
      }
      
      const blob = await response.blob();
      const buffer = await blob.arrayBuffer();
      const size = buffer.byteLength;
      
      // 这里简化处理，实际应用中需要使用文件系统API写入文件
      // const fileStream = await fs.createWriteStream(destination);
      // await fileStream.write(buffer);
      // await fileStream.close();
      
      // 更新统计信息
      this.updateRequestStats('success', Date.now() - startTime);
      this.networkStats.totalBytesReceived += size;
      this.notifyStatsChanged();
      
      this.activeRequests.delete(requestId);
      return {
        success: true,
        data: { path: destination, size },
        status: 200,
        headers: {}
      };
    } catch (error) {
      this.updateRequestStats('error', Date.now() - startTime, error instanceof Error ? error.message : 'Unknown error');
      this.activeRequests.delete(requestId);
      throw error;
    }
  }

  /**
   * 上传文件
   */
  public async uploadFile(
    url: string,
    filePath: string,
    options: Partial<NetworkOptions> = {}
  ): Promise<NetworkResponse<any>> {
    // 检查初始化状态
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    // 检查网络连接
    const { status } = await this.checkNetworkStatus();
    if (status !== NetworkStatus.CONNECTED) {
      throw new NetworkError('Network not connected', { code: 'NETWORK_DISCONNECTED' });
    }
    
    const requestId = `UPLOAD_${url}_${Date.now()}`;
    const startTime = Date.now();
    
    this.activeRequests.add(requestId);
    this.updateRequestStats('start');
    
    try {
      // 合并选项
      const uploadOptions: NetworkOptions = {
        ...options,
        method: 'POST',
        timeout: options.timeout || this.networkConfig.timeout * 3, // 上传超时更长
        verifySSL: options.verifySSL !== undefined ? options.verifySSL : this.networkConfig.verifySSL
      };
      
      // 执行上传
      const result = await NetworkUtil.uploadFile(url, filePath, uploadOptions);
      
      // 更新统计信息
      this.updateRequestStats('success', Date.now() - startTime);
      this.notifyStatsChanged();
      
      this.activeRequests.delete(requestId);
      return result;
    } catch (error) {
      this.updateRequestStats('error', Date.now() - startTime, error instanceof Error ? error.message : 'Unknown error');
      this.activeRequests.delete(requestId);
      throw error;
    }
  }

  /**
   * 更新请求统计信息
   */
  private updateRequestStats(
    type: 'start' | 'success' | 'error',
    duration?: number,
    errorMessage?: string
  ): void {
    switch (type) {
      case 'start':
        this.networkStats.totalRequests++;
        this.networkStats.lastRequestTime = Date.now();
        break;
      case 'success':
        this.networkStats.successfulRequests++;
        if (duration !== undefined) {
          // 更新平均响应时间
          const totalTime = this.networkStats.averageResponseTime * (this.networkStats.successfulRequests - 1);
          this.networkStats.averageResponseTime = (totalTime + duration) / this.networkStats.successfulRequests;
        }
        break;
      case 'error':
        this.networkStats.failedRequests++;
        this.networkStats.lastErrorTime = Date.now();
        this.networkStats.lastError = errorMessage;
        
        // 更新错误率统计
        if (errorMessage) {
          const errorKey = errorMessage.substring(0, 50); // 限制错误消息长度
          this.networkStats.errorRates[errorKey] = (this.networkStats.errorRates[errorKey] || 0) + 1;
        }
        break;
    }
    
    this.notifyStatsChanged();
  }

  /**
   * 获取网络统计信息
   */
  public getNetworkStats(): NetworkStats {
    return { ...this.networkStats };
  }

  /**
   * 重置网络统计信息
   */
  public resetNetworkStats(): void {
    this.networkStats = this.createDefaultStats();
    this.notifyStatsChanged();
    Logger.info(TAG, 'Reset network statistics');
  }

  /**
   * 获取活动请求数量
   */
  public getActiveRequestCount(): number {
    return this.activeRequests.size;
  }

  /**
   * 取消所有活动请求
   */
  public async cancelAllRequests(): Promise<void> {
    try {
      // 这里应该调用NetworkUtil的取消方法
      Logger.info(TAG, `Canceling ${this.activeRequests.size} active requests`);
      
      // 清空活动请求集合
      this.activeRequests.clear();
    } catch (error) {
      Logger.error(TAG, 'Failed to cancel all requests', error);
    }
  }

  /**
   * 清除缓存
   */
  public async clearCache(): Promise<void> {
    try {
      this.cache.clear();
      await StorageUtil.remove(NETWORK_CACHE_KEY);
      Logger.info(TAG, 'Cleared network cache');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear network cache', error);
    }
  }

  /**
   * 按URL清除缓存
   */
  public async clearCacheByUrl(url: string): Promise<void> {
    try {
      let cleared = 0;
      for (const [key, item] of this.cache.entries()) {
        if (item.url === url) {
          this.cache.delete(key);
          cleared++;
        }
      }
      
      if (cleared > 0) {
        await this.saveCache();
        Logger.info(TAG, `Cleared ${cleared} cache items for URL: ${url}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to clear cache for URL: ${url}`, error);
    }
  }

  /**
   * 添加请求拦截器
   */
  public addRequestInterceptor(interceptor: RequestInterceptor): () => void {
    this.requestInterceptors.push(interceptor);
    
    // 返回取消拦截器函数
    return () => {
      const index = this.requestInterceptors.indexOf(interceptor);
      if (index > -1) {
        this.requestInterceptors.splice(index, 1);
      }
    };
  }

  /**
   * 添加响应拦截器
   */
  public addResponseInterceptor(interceptor: ResponseInterceptor): () => void {
    this.responseInterceptors.push(interceptor);
    
    // 返回取消拦截器函数
    return () => {
      const index = this.responseInterceptors.indexOf(interceptor);
      if (index > -1) {
        this.responseInterceptors.splice(index, 1);
      }
    };
  }

  /**
   * 添加错误拦截器
   */
  public addErrorInterceptor(interceptor: ErrorInterceptor): () => void {
    this.errorInterceptors.push(interceptor);
    
    // 返回取消拦截器函数
    return () => {
      const index = this.errorInterceptors.indexOf(interceptor);
      if (index > -1) {
        this.errorInterceptors.splice(index, 1);
      }
    };
  }

  /**
   * 添加网络状态监听器
   */
  public addStatusListener(listener: (status: NetworkStatus, type: NetworkType) => void): () => void {
    this.statusListeners.push(listener);
    
    // 立即回调当前状态
    listener(this.networkStatus, this.networkType);
    
    // 返回取消监听函数
    return () => {
      const index = this.statusListeners.indexOf(listener);
      if (index > -1) {
        this.statusListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加统计信息监听器
   */
  public addStatsListener(listener: (stats: NetworkStats) => void): () => void {
    this.statsListeners.push(listener);
    
    // 立即回调当前统计信息
    listener({ ...this.networkStats });
    
    // 返回取消监听函数
    return () => {
      const index = this.statsListeners.indexOf(listener);
      if (index > -1) {
        this.statsListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加带宽测试监听器
   */
  public addBandwidthListener(listener: (result: BandwidthTestResult) => void): () => void {
    this.bandwidthListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.bandwidthListeners.indexOf(listener);
      if (index > -1) {
        this.bandwidthListeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知网络状态变更
   */
  private notifyStatusChanged(): void {
    for (const listener of this.statusListeners) {
      try {
        listener(this.networkStatus, this.networkType);
      } catch (error) {
        Logger.error(TAG, 'Error in status listener', error);
      }
    }
  }

  /**
   * 通知统计信息变更
   */
  private notifyStatsChanged(): void {
    for (const listener of this.statsListeners) {
      try {
        listener({ ...this.networkStats });
      } catch (error) {
        Logger.error(TAG, 'Error in stats listener', error);
      }
    }
  }

  /**
   * 通知带宽测试完成
   */
  private notifyBandwidthTestCompleted(result: BandwidthTestResult): void {
    for (const listener of this.bandwidthListeners) {
      try {
        listener({ ...result });
      } catch (error) {
        Logger.error(TAG, 'Error in bandwidth listener', error);
      }
    }
  }

  /**
   * 销毁网络服务
   */
  public async destroy(): Promise<void> {
    try {
      Logger.info(TAG, 'Destroying network service...');
      
      // 停止监控
      this.stopMonitoring();
      
      // 取消所有请求
      await this.cancelAllRequests();
      
      // 保存缓存
      await this.saveCache();
      
      // 清除监听器
      this.statusListeners = [];
      this.statsListeners = [];
      this.bandwidthListeners = [];
      this.requestInterceptors = [];
      this.responseInterceptors = [];
      this.errorInterceptors = [];
      
      Logger.info(TAG, 'Network service destroyed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to destroy network service', error);
    }
  }
}