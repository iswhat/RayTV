/**
 * HTTP服务类
 * 
 * 提供网络请求的统一接口，支持GET、POST等方法，处理请求头、响应拦截、缓存管理等功能。
 * 实现了并发控制、请求合并、批处理等高级特性，确保网络请求的高效执行。
 * 
 * @example
 * ```typescript
 * // 获取HttpService实例
 * const httpService = HttpService.getInstance();
 * 
 * // 设置上下文
 * httpService.setContext(this.context);
 * 
 * // 发送GET请求
 * const response = await httpService.get<{ data: any }>('https://api.example.com/data');
 * 
 * // 发送POST请求
 * const postResponse = await httpService.post<{ result: any }>('https://api.example.com/submit', { name: 'test' });
 * ```
 */
// HTTP服务类 | HTTP service class
// 提供网络请求的统一接口，支持GET、POST等方法，处理请求头、响应拦截等 | Provides unified interface for network requests, supports GET, POST methods, handles request headers, response interception, etc.

import http from '@ohos.net.http';
import ConfigService from './config/ConfigService';
import CacheService from './cache/CacheService';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import URLValidator from '../common/util/URLValidator';
import Logger from '../common/util/Logger';

/**
 * HTTP请求选项接口
 * 
 * 定义HTTP请求的配置选项，包括请求头、超时时间、重试次数等。
 */
export interface HttpOptions {
  /** 请求头 | Request headers */
  headers?: Record<string, string>;
  /** 超时时间（秒）| Timeout (seconds) */
  timeout?: number;
  /** 重试次数 | Retry count */
  retryCount?: number;
  /** 响应类型 | Response type */
  responseType?: 'json' | 'text' | 'arraybuffer';
  /** 是否启用缓存 | Enable cache */
  cache?: boolean;
  /** 自定义缓存键 | Custom cache key */
  cacheKey?: string;
  /** 缓存过期时间（毫秒）| Cache expiry time (milliseconds) */
  cacheExpiry?: number;
}

/**
 * HTTP响应接口
 * 
 * 定义HTTP请求的响应结构，包含状态码、响应数据、响应头和请求URL。
 * 
 * @typeParam T - 响应数据的类型
 */
export interface HttpResponse<T> {
  /** 状态码 | Status code */
  status: number;
  /** 响应数据 | Response data */
  data: T;
  /** 响应头 | Response headers */
  headers: Record<string, string>;
  /** 请求URL | Request URL */
  url: string;
}

/**
 * HTTP请求选项接口
 * 
 * 扩展自HttpOptions，添加了请求方法和请求数据字段。
 */
export interface HttpRequestOptions extends HttpOptions {
  /** 请求方法 | Request method */
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  /** 请求数据 | Request data */
  data?: Record<string, string | number | boolean | null> | string;
}

/**
 * 下载选项接口
 * 
 * 扩展自HttpOptions，添加了下载进度回调功能。
 */
export interface DownloadOptions extends HttpOptions {
  /** 进度回调 | Progress callback */
  onProgress?: (receivedSize: number, totalSize: number) => void;
}

/**
 * 下载结果接口
 * 
 * 定义文件下载的结果结构，包含状态码、文件路径、响应头和文件大小。
 */
export interface DownloadResult {
  /** 状态码 | Status code */
  status: number;
  /** 文件路径 | File path */
  filePath: string;
  /** 响应头 | Response headers */
  headers: Record<string, string>;
  /** 文件大小 | File size */
  fileSize?: number;
}

/**
 * HTTP配置接口
 * 
 * 定义HTTP服务的全局配置，包括超时时间、重试次数、用户代理等。
 */
export interface HttpConfig {
  /** 超时时间（秒）| Timeout (seconds) */
  timeout: number;
  /** 重试次数 | Retry count */
  retryCount: number;
  /** 用户代理 | User agent */
  userAgent: string;
  /** 是否启用HTTPS证书验证 | Enable HTTPS certificate verification */
  enableHttpsVerification: boolean;
  /** 是否启用CORS | Enable CORS */
  enableCors: boolean;
  /** 是否启用内容安全策略 | Enable content security policy */
  enableContentSecurityPolicy: boolean;
}

export class HttpService {
  private static instance: HttpService;
  private httpConfig: HttpConfig;
  private context: common.Context | null = null;
  private cacheService: CacheService;
  private static readonly TAG: string = 'HttpService';
  
  /**
   * HTTP连接池
   * HTTP connection pool
   */
  private connectionPool: Map<string, { httpRequest: http.HttpRequest, lastUsed: number }> = new Map();
  
  /**
   * 连接池最大大小
   * Connection pool maximum size
   */
  private readonly MAX_POOL_SIZE: number = 10;
  
  /**
   * 连接最大空闲时间（毫秒）
   * Connection maximum idle time (milliseconds)
   */
  private readonly MAX_IDLE_TIME: number = 60000; // 60秒

  /**
   * 缓存策略配置
   * Cache strategy configuration
   */
  private cacheStrategies: Record<string, {
    defaultExpiry: number;
    maxAge: number;
    staleWhileRevalidate: boolean;
    priority: 'low' | 'medium' | 'high';
    slidingExpiry: boolean; // 滑动过期
    backgroundRefresh: boolean; // 后台自动刷新
  }> = {
    // 静态资源
    'static': {
      defaultExpiry: 24 * 60 * 60 * 1000, // 24小时
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7天
      staleWhileRevalidate: true,
      priority: 'high',
      slidingExpiry: true,
      backgroundRefresh: true
    },
    // API响应
    'api': {
      defaultExpiry: 5 * 60 * 1000, // 5分钟
      maxAge: 30 * 60 * 1000, // 30分钟
      staleWhileRevalidate: true,
      priority: 'medium',
      slidingExpiry: true,
      backgroundRefresh: true
    },
    // 动态内容
    'dynamic': {
      defaultExpiry: 30 * 1000, // 30秒
      maxAge: 5 * 60 * 1000, // 5分钟
      staleWhileRevalidate: false,
      priority: 'low',
      slidingExpiry: false,
      backgroundRefresh: false
    },
    // 实时数据
    'realtime': {
      defaultExpiry: 5 * 1000, // 5秒
      maxAge: 30 * 1000, // 30秒
      staleWhileRevalidate: false,
      priority: 'low',
      slidingExpiry: false,
      backgroundRefresh: false
    }
  };

  /**
   * 缓存统计
   * Cache statistics
   */
  private cacheStats: {
    hits: number;
    misses: number;
    requests: number;
    lastReset: number;
  } = {
    hits: 0,
    misses: 0,
    requests: 0,
    lastReset: Date.now()
  };

  /**
   * 预加载队列
   * Preload queue
   */
  private preloadQueue: Set<string> = new Set();

  /**
   * 批量请求队列
   * Batch request queue
   */
  private batchRequestQueue: Map<string, Promise<HttpResponse<Record<string, any>>>> = new Map();

  /**
   * 请求合并队列
   * Request merge queue
   */
  private mergedRequestQueue: Map<string, { promise: Promise<HttpResponse<Record<string, any>>>, timestamp: number }> = new Map();

  /**
   * 并发请求限制
   * Concurrent request limit
   */
  private readonly MAX_CONCURRENT_REQUESTS: number = 6;

  /**
   * 当前并发请求数
   * Current concurrent request count
   */
  private currentConcurrentRequests: number = 0;

  private constructor() {
    // 初始化默认配置 Initialize default config
    const defaultTimeout = 30;
    const defaultRetryCount = 3;

    // 手动初始化配置，避免使用对象字面量语法
    // Manually initialize config, avoid using object literal syntax
    this.httpConfig = {
      timeout: defaultTimeout,
      retryCount: defaultRetryCount,
      userAgent: '',
      enableHttpsVerification: true,
      enableCors: true,
      enableContentSecurityPolicy: true
    };

    // 初始化缓存服务 Initialize cache service
    this.cacheService = CacheService.getInstance();

    Logger.debug(HttpService.TAG, 'HttpService initialized');
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
   * 获取单例实例
   * 
   * 实现了单例模式，确保全局只有一个HttpService实例。
   * 
   * @returns HttpService单例实例
   * @example
   * ```typescript
   * const httpService = HttpService.getInstance();
   * ```
   */
  public static getInstance(): HttpService {
    if (!HttpService.instance) {
      HttpService.instance = new HttpService();
    }
    return HttpService.instance;
  }

  /**
   * 设置上下文
   * 
   * 设置应用上下文，用于请求网络权限等操作。
   * 
   * @param ctx 应用上下文
   * @example
   * ```typescript
   * httpService.setContext(this.context);
   * ```
   */
  public setContext(ctx: common.Context): void {
    this.context = ctx;
    Logger.debug(HttpService.TAG, 'Context set');
  }

  /**
   * 初始化HTTP服务
   * 
   * 空实现，用于AppService的初始化流程。
   * HTTP服务在构造函数中已经初始化完成。
   * 
   * @returns Promise<void>
   */
  public async initialize(): Promise<void> {
    // HTTP服务在构造函数中已经初始化完成
    // HTTP service already initialized in constructor
    // 这里提供一个空实现以适配AppService的初始化流程
    // Empty implementation to adapt to AppService initialization process
  }

  /**
   * 发送GET请求
   * 
   * 发送HTTP GET请求，支持自定义请求选项。
   * 
   * @typeParam T - 响应数据的类型
   * @param url 请求URL
   * @param options 请求选项
   * @returns Promise<HttpResponse<T>> - 包含响应数据的Promise
   * @example
   * ```typescript
   * const response = await httpService.get<{ data: any }>('https://api.example.com/data');
   * console.log(response.data);
   * ```
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
   * 发送POST请求
   * 
   * 发送HTTP POST请求，支持自定义请求数据和请求选项。
   * 
   * @typeParam T - 响应数据的类型
   * @param url 请求URL
   * @param data 请求数据
   * @param options 请求选项
   * @returns Promise<HttpResponse<T>> - 包含响应数据的Promise
   * @example
   * ```typescript
   * const response = await httpService.post<{ result: any }>('https://api.example.com/submit', { name: 'test' });
   * console.log(response.data);
   * ```
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
   * 验证URL Validate URL
   * @param url URL字符串
   * @throws {Error} 如果URL无效
   */
  private validateURL(url: string): void {
    URLValidator.validateURL(url);
  }
  
  /**
   * 验证请求数据 Validate request data
   * @param data 请求数据
   * @throws {Error} 如果数据无效
   */
  private validateRequestData(data: string | number | boolean | object | null | undefined): void {
    if (data === null || data === undefined) {
      return;
    }
    
    // 检查是否为恶意数据 Check for malicious data
    if (typeof data === 'string') {
      // 防止SQL注入 Prevent SQL injection
      const sqlInjectionPatterns = [
        /\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|EXEC)\b/i,
        /\b(OR|AND)\s+1=1\b/i,
        /'OR'1'='1/,
        /"OR"1"="1/
      ];
      
      for (const pattern of sqlInjectionPatterns) {
        if (pattern.test(data)) {
          throw new Error('Invalid request data: potential SQL injection detected');
        }
      }
      
      // 防止XSS攻击 Prevent XSS attack
      const xssPatterns = [
        /<script[^>]*>.*?<\/script>/gi,
        /<iframe[^>]*>.*?<\/iframe>/gi,
        /javascript:/gi,
        /on\w+\s*=/gi
      ];
      
      for (const pattern of xssPatterns) {
        if (pattern.test(data)) {
          throw new Error('Invalid request data: potential XSS attack detected');
        }
      }
    } else if (typeof data === 'object') {
      // 递归验证对象 Recursively validate object
      const objectKeys = Object.keys(data);
      for (let i = 0; i < objectKeys.length; i++) {
        const key = objectKeys[i];
        this.validateRequestData(data[key] as string | number | boolean | object | null | undefined);
      }
    }
  }
  
  /**
   * 验证请求头部 Validate request headers
   * @param headers 请求头部
   * @returns 清理后的头部 Sanitized headers
   */
  private validateAndSanitizeHeaders(headers: Record<string, string>): Record<string, string> {
    const sanitizedHeaders: Record<string, string> = {};
    
    if (!headers) {
      return sanitizedHeaders;
    }
    
    // 允许的头部列表 Allowed headers list
    const allowedHeaders = [
      'Content-Type', 'Content-Length', 'Accept', 'Accept-Encoding',
      'Authorization', 'User-Agent', 'Referer', 'Origin',
      'Cache-Control', 'Pragma', 'Expires', 'If-Modified-Since',
      'If-None-Match', 'X-Requested-With'
    ];
    
    const headerEntries = Object.entries(headers);
    for (let i = 0; i < headerEntries.length; i++) {
      const [key, value] = headerEntries[i];
      // 检查头部名称是否合法 Check if header name is valid
      if (!/^[a-zA-Z0-9!#$%&'*+-.^_`|~]+$/.test(key)) {
        Logger.warn(HttpService.TAG, `Invalid header name: ${key}`);
        continue;
      }
      
      // 检查头部值是否合法 Check if header value is valid
      if (typeof value !== 'string') {
        Logger.warn(HttpService.TAG, `Invalid header value type for ${key}`);
        continue;
      }
      
      // 防止头部注入 Prevent header injection
      if (value.includes('\r') || value.includes('\n')) {
        Logger.warn(HttpService.TAG, `Invalid header value for ${key}: contains line breaks`);
        continue;
      }
      
      // 只允许安全的头部 Only allow safe headers
      if (allowedHeaders.includes(key) || key.toLowerCase().startsWith('x-')) {
        sanitizedHeaders[key] = value;
      } else {
        Logger.warn(HttpService.TAG, `Header not allowed: ${key}`);
      }
    }
    
    return sanitizedHeaders;
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
      Logger.error(HttpService.TAG, 'Failed to request INTERNET permission');
      // 不抛出错误，允许应用继续尝试网络操作
      // Don't throw error, allow app to continue trying network operations
    }
  }

  /**
   * 确定内容类型
   * Determine content type
   * @param url URL
   * @param headers 响应头
   * @returns 内容类型
   */
  private determineContentType(url: string, headers?: Record<string, string>): string {
    // 基于URL路径和响应头确定内容类型
    if (headers?.['content-type']?.includes('application/json')) {
      return 'api';
    }
    if (url.includes('/api/') || url.includes('/v1/') || url.includes('/v2/')) {
      return 'api';
    }
    if (url.match(/\.(jpg|jpeg|png|gif|webp|css|js|json|svg|woff|woff2|ttf|eot)$/i)) {
      return 'static';
    }
    return 'dynamic';
  }

  /**
   * 获取缓存策略
   * Get cache strategy
   * @param contentType 内容类型
   * @returns 缓存策略
   */
  private getCacheStrategy(contentType: string) {
    return this.cacheStrategies[contentType] || this.cacheStrategies.dynamic;
  }

  /**
   * 生成缓存键 Generate cache key
   * @param url 请求URL Request URL
   * @param options 请求选项 Request options
   * @returns 缓存键 Cache key
   */
  private generateCacheKey(url: string, options: HttpRequestOptions): string {
    if (options.cacheKey) {
      return options.cacheKey;
    }
    // 基于URL和请求参数生成缓存键 Generate cache key based on URL and request parameters
    const method = options.method || 'GET';
    const data = options.data ? JSON.stringify(options.data) : '';
    const headers = options.headers ? JSON.stringify(options.headers) : '';
    return `${method}:${url}:${data}:${headers}`;
  }

  /**
   * 发送网络请求
   * 
   * 发送HTTP请求，支持各种请求方法，处理缓存、重试、并发控制等。
   * 
   * @typeParam T - 响应数据的类型
   * @param url 请求URL
   * @param options 请求选项
   * @returns Promise<HttpResponse<T>> - 包含响应数据的Promise
   * @throws Error - 当请求失败时抛出错误
   * @example
   * ```typescript
   * const response = await httpService.request<{ data: any }>('https://api.example.com/data', {
   *   method: 'GET',
   *   headers: { 'Content-Type': 'application/json' },
   *   timeout: 30,
   *   retryCount: 3,
   *   cache: true
   * });
   * ```
   */
  public async request<T>(url: string, options: HttpRequestOptions): Promise<HttpResponse<T>> {
    // 验证URL，防止SSRF攻击
    this.validateURL(url);

    // 验证请求数据，防止注入攻击
    if (options.data) {
      this.validateRequestData(options.data);
    }

    // 增加请求计数
    this.cacheStats.requests++;

    // 检查缓存 Check cache
    let cachedResponse: HttpResponse<T> | null = null;
    if (options.cache !== false) {
      const cacheKey = this.generateCacheKey(url, options);
      cachedResponse = await this.getCachedResponse<T>(cacheKey);
      if (cachedResponse) {
        this.cacheStats.hits++;
        Logger.debug(HttpService.TAG, `Cache hit for ${url}`);
        
        // 如果启用了 stale-while-revalidate，后台刷新缓存
        const contentType = this.determineContentType(url, cachedResponse.headers);
        const strategy = this.getCacheStrategy(contentType);
        if (strategy.staleWhileRevalidate) {
          this.backgroundRefreshCache(cacheKey, url, options);
        }
        
        return cachedResponse;
      }
      this.cacheStats.misses++;
      Logger.debug(HttpService.TAG, `Cache miss for ${url}, sending network request`);
    }

    // 从连接池获取HTTP请求对象
    const httpRequest = this.getHttpRequestFromPool(url);

    try {
      // 检查网络权限（只在需要时请求）
      // Check network permission (only request when needed)
      await this.checkAndRequestNetworkPermission();

      const method = options.method || 'GET';
      const headers = options.headers || {};
      const requestData = options.data || null;
      const timeout = options.timeout !== undefined ? options.timeout : this.httpConfig.timeout * 1000;

      // 验证并清理头部 Validate and sanitize headers
      const sanitizedHeaders = this.validateAndSanitizeHeaders(headers);

      // 构建请求配置 Build request config
      const requestConfig: http.HttpRequestOptions = {
        method: method as http.RequestMethod,
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': this.httpConfig.userAgent || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          'Content-Type': 'application/json',
          // 添加安全头部
          'X-Content-Security-Policy': this.httpConfig.enableContentSecurityPolicy ? 'default-src https:; script-src https: \'self\'; style-src https: \'self\'; img-src https: data:; connect-src https:' : '',
          'X-Frame-Options': 'DENY',
          'X-XSS-Protection': '1; mode=block',
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
          'X-Content-Type-Options': 'nosniff',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
          'Content-Security-Policy': this.httpConfig.enableContentSecurityPolicy ? 'default-src https:; script-src https: \'self\'; style-src https: \'self\'; img-src https: data:; connect-src https:' : ''
        },
        // 添加HTTPS证书验证
        usingProxy: false,
        // 安全配置
        enableHttpsVerification: this.httpConfig.enableHttpsVerification,
        // 强制使用HTTPS
        protocol: 'https'
      };

      // 手动合并headers Manually merge headers
      if (sanitizedHeaders) {
        // 确保header对象存在 Ensure header object exists
        if (!requestConfig.header) {
          requestConfig.header = {};
        }
        // 使用传统for循环遍历键值对变量声明 Use traditional for loop to iterate key-value pairs variable declaration
        const entries = Object.entries(sanitizedHeaders);
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

      // 发送请求 Send request - 修复资源泄漏问题
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

      // 确保response有值 Ensure response has value - 增强错误信息
      if (!response) {
        const errorDetails = {
          url: url,
          retryCount: retryCount,
          maxRetryCount: maxRetryCount,
          lastError: lastError?.message
        };
        throw new Error(`HTTP request failed after ${retryCount} retries: ${JSON.stringify(errorDetails)}`);
      }

      // 处理响应 Process response
      const result: HttpResponse<T> = {
        status: response.responseCode,
        data: this.parseResponseData<T>(response.result as string),
        headers: this.sanitizeHeaders(response.header as Record<string, string | number | boolean | null>),
        url: url
      };

      // 检查状态码 Check status code
      if (result.status < 200 || result.status >= 300) {
        const error = new Error(`HTTP Error: ${result.status} - ${url}`);
        throw error;
      }

      // 缓存响应 Cache response
      if (options.cache !== false) {
        const cacheKey = this.generateCacheKey(url, options);
        const contentType = this.determineContentType(url, result.headers);
        const strategy = this.getCacheStrategy(contentType);
        const cacheExpiry = options.cacheExpiry || strategy.defaultExpiry;
        await this.cacheResponse(cacheKey, result, cacheExpiry, contentType, strategy.priority);
        Logger.debug(HttpService.TAG, `Response cached for ${url} with ${contentType} strategy`);
      }

      return result;
    } catch (error) {
      Logger.error(HttpService.TAG, `HTTP request failed: ${url}`);
      throw error instanceof Error ? error : new Error(String(error));
    } finally {
      // 将HTTP请求对象返回连接池
      this.returnHttpRequestToPool(url, httpRequest);
    }
  }

  /**
   * 后台刷新缓存
   * Background refresh cache
   * @param cacheKey 缓存键
   * @param url URL
   * @param options 请求选项
   */
  private async backgroundRefreshCache<T>(cacheKey: string, url: string, options: HttpRequestOptions): Promise<void> {
    // 避免重复刷新
    if (this.preloadQueue.has(cacheKey)) {
      return;
    }

    this.preloadQueue.add(cacheKey);
    let httpRequest: http.HttpRequest | null = null;

    try {
      // 从连接池获取HTTP请求对象
      httpRequest = this.getHttpRequestFromPool(url);
      
      const method = options.method || 'GET';
      const headers = options.headers || {};
      const requestData = options.data || null;
      const timeout = options.timeout !== undefined ? options.timeout : this.httpConfig.timeout * 1000;

      const sanitizedHeaders = this.validateAndSanitizeHeaders(headers);

      const requestConfig: http.HttpRequestOptions = {
        method: method as http.RequestMethod,
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': this.httpConfig.userAgent || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          'Content-Type': 'application/json',
          ...sanitizedHeaders
        },
        enableHttpsVerification: this.httpConfig.enableHttpsVerification
      };

      if (requestData !== null && requestData !== undefined) {
        const contentType = requestConfig.header['Content-Type'] || 'application/json';
        if (contentType.includes('json')) {
          requestConfig.extraData = JSON.stringify(requestData);
        } else {
          requestConfig.extraData = requestData;
        }
      }

      const response = await httpRequest.request(url, requestConfig);

      if (response.responseCode >= 200 && response.responseCode < 300) {
        const result: HttpResponse<T> = {
          status: response.responseCode,
          data: this.parseResponseData<T>(response.result as string),
          headers: this.sanitizeHeaders(response.header as Record<string, string | number | boolean | null>),
          url: url
        };

        const contentType = this.determineContentType(url, result.headers);
        const strategy = this.getCacheStrategy(contentType);
        await this.cacheResponse(cacheKey, result, strategy.defaultExpiry, contentType, strategy.priority);
        Logger.debug(HttpService.TAG, `Cache refreshed for ${url}`);
      }
    } catch (error) {
      Logger.warn(HttpService.TAG, `Failed to refresh cache for ${url}: ${error}`);
    } finally {
      // 将HTTP请求对象返回连接池
      try {
        if (httpRequest) {
          this.returnHttpRequestToPool(url, httpRequest);
        }
      } catch (error) {
        Logger.warn(HttpService.TAG, `Failed to return HTTP request to pool: ${error}`);
      }
      this.preloadQueue.delete(cacheKey);
    }
  }

  /**
   * 获取缓存的响应 Get cached response
   * @param cacheKey 缓存键 Cache key
   * @returns 缓存的响应 Cached response
   */
  private async getCachedResponse<T>(cacheKey: string): Promise<HttpResponse<T> | null> {
    try {
      const cachedData = await this.cacheService.get<HttpResponse<T>>(cacheKey);
      if (cachedData) {
        // 检查缓存是否过期 Check if cache is expired
        const now = Date.now();
        const cacheTime = cachedData.headers['x-cache-time'] ? parseInt(cachedData.headers['x-cache-time']) : 0;
        const cacheExpiry = cachedData.headers['x-cache-expiry'] ? parseInt(cachedData.headers['x-cache-expiry']) : 0;
        const maxAge = cachedData.headers['x-cache-max-age'] ? parseInt(cachedData.headers['x-cache-max-age']) : 0;
        const contentType = cachedData.headers['x-cache-content-type'] || 'dynamic';
        const strategy = this.getCacheStrategy(contentType);
        
        // 检查是否在最大有效期内
        if (now - cacheTime < maxAge || maxAge === 0) {
          // 实现滑动过期机制
          if (strategy.slidingExpiry) {
            // 更新缓存时间，实现滑动过期
            const updatedResponse = {
              ...cachedData,
              headers: {
                ...cachedData.headers,
                'x-cache-time': now.toString()
              }
            };
            await this.cacheService.set(cacheKey, updatedResponse, strategy.defaultExpiry);
          }
          return cachedData;
        }
        
        // 缓存已过期，删除缓存 Cache expired, delete cache
        await this.cacheService.remove(cacheKey);
        Logger.debug(HttpService.TAG, `Cache expired for key ${cacheKey}`);
      }
      return null;
    } catch (error) {
      Logger.warn(HttpService.TAG, `Failed to get cached response: ${error}`);
      return null;
    }
  }

  /**
   * 缓存响应 Cache response
   * @param cacheKey 缓存键 Cache key
   * @param response 响应 Response
   * @param expiry 过期时间（毫秒）Expiry time (milliseconds)
   * @param contentType 内容类型 Content type
   * @param priority 优先级 Priority
   */
  private async cacheResponse<T>(cacheKey: string, response: HttpResponse<T>, expiry: number, contentType: string, priority: 'low' | 'medium' | 'high'): Promise<void> {
    try {
      const strategy = this.getCacheStrategy(contentType);
      
      // 添加缓存时间和过期时间到响应头 Add cache time and expiry time to response headers
      const cacheResponse = {
        ...response,
        headers: {
          ...response.headers,
          'x-cache-time': Date.now().toString(),
          'x-cache-expiry': expiry.toString(),
          'x-cache-max-age': strategy.maxAge.toString(),
          'x-cache-content-type': contentType,
          'x-cache-priority': priority,
          'x-cache-sliding-expiry': strategy.slidingExpiry.toString(),
          'x-cache-background-refresh': strategy.backgroundRefresh.toString()
        }
      };
      
      await this.cacheService.set(cacheKey, cacheResponse, expiry);
      
      // 检查缓存大小并清理低优先级缓存
      await this.checkAndCleanCache();
      
      // 启动后台刷新（如果启用）
      if (strategy.backgroundRefresh) {
        // 延迟一段时间后后台刷新缓存
        setTimeout(() => {
          this.backgroundRefreshCache(cacheKey, response.url, {
            method: 'GET',
            cache: true,
            cacheKey: cacheKey
          });
        }, expiry * 0.8); // 在过期前20%的时间刷新
      }
    } catch (error) {
      Logger.warn(HttpService.TAG, `Failed to cache response: ${error}`);
    }
  }

  /**
   * 检查并清理缓存
   * Check and clean cache
   */
  private async checkAndCleanCache(): Promise<void> {
    try {
      // 获取缓存大小
      const cacheSize = await this.cacheService.getSize();
      const maxCacheSize = 50 * 1024 * 1024; // 50MB
      
      if (cacheSize > maxCacheSize) {
        Logger.info(HttpService.TAG, `Cache size ${cacheSize} exceeds limit ${maxCacheSize}, cleaning low priority cache`);
        // 清理低优先级缓存
        await this.cacheService.cleanLowPriority();
      }
    } catch (error) {
      Logger.warn(HttpService.TAG, `Failed to check and clean cache: ${error}`);
    }
  }

  /**
   * 清除缓存
   * 
   * 清除指定URL的缓存或所有缓存。
   * 
   * @param url 可选的URL，清除特定URL的缓存
   * @returns Promise<void>
   * @example
   * ```typescript
   * // 清除特定URL的缓存
   * await httpService.clearCache('https://api.example.com/data');
   * 
   * // 清除所有缓存
   * await httpService.clearCache();
   * ```
   */
  public async clearCache(url?: string): Promise<void> {
    try {
      if (url) {
        // 清除特定URL的缓存 Clear cache for specific URL
        const cacheKey = this.generateCacheKey(url, { method: 'GET' });
        await this.cacheService.remove(cacheKey);
        Logger.info(HttpService.TAG, `Cache cleared for ${url}`);
      } else {
        // 清除所有缓存 Clear all cache
        await this.cacheService.clear();
        Logger.info(HttpService.TAG, 'All caches cleared');
        // 重置缓存统计
        this.resetCacheStats();
      }
    } catch (error) {
      Logger.error(HttpService.TAG, `Failed to clear cache: ${error}`);
    }
  }

  /**
   * 获取缓存统计
   * 
   * 获取缓存的使用统计信息，包括命中次数、未命中次数、总请求数、命中率等。
   * 
   * @returns 缓存统计信息
   * @example
   * ```typescript
   * const stats = httpService.getCacheStats();
   * console.log(`Cache hit rate: ${stats.hitRate}%`);
   * ```
   */
  public getCacheStats(): {
    hits: number;
    misses: number;
    requests: number;
    hitRate: number;
    lastReset: number;
  } {
    const hitRate = this.cacheStats.requests > 0 
      ? (this.cacheStats.hits / this.cacheStats.requests) * 100 
      : 0;
    
    return {
      ...this.cacheStats,
      hitRate
    };
  }

  /**
   * 重置缓存统计
   * 
   * 重置缓存的统计信息，包括命中次数、未命中次数、总请求数等。
   * 
   * @returns void
   * @example
   * ```typescript
   * httpService.resetCacheStats();
   * console.log('Cache stats reset');
   * ```
   */
  public resetCacheStats(): void {
    this.cacheStats = {
      hits: 0,
      misses: 0,
      requests: 0,
      lastReset: Date.now()
    };
  }

  /**
   * 预加载URL
   * 
   * 预加载指定URL的内容，提前缓存到本地，提高后续请求的响应速度。
   * 
   * @param url 要预加载的URL
   * @param options 请求选项
   * @returns Promise<void>
   * @example
   * ```typescript
   * // 预加载图片
   * await httpService.preload('https://example.com/image.jpg');
   * 
   * // 预加载API数据
   * await httpService.preload('https://api.example.com/data');
   * ```
   */
  public async preload(url: string, options?: HttpOptions): Promise<void> {
    if (this.preloadQueue.has(url)) {
      return;
    }

    this.preloadQueue.add(url);

    try {
      await this.get(url, options);
      Logger.debug(HttpService.TAG, `Preloaded ${url}`);
    } catch (error) {
      Logger.warn(HttpService.TAG, `Failed to preload ${url}: ${error}`);
    } finally {
      this.preloadQueue.delete(url);
    }
  }

  /**
   * 下载文件
   * 
   * 下载指定URL的文件并保存到本地路径。
   * 
   * @param url 文件URL
   * @param filePath 保存路径
   * @param options 下载选项
   * @returns Promise<DownloadResult> - 包含下载结果的Promise
   * @throws Error - 当下载失败时抛出错误
   * @example
   * ```typescript
   * const result = await httpService.downloadFile(
   *   'https://example.com/file.mp4',
   *   '/data/storage/el2/base/haps/entry/files/file.mp4',
   *   {
   *     onProgress: (receivedSize, totalSize) => {
   *       console.log(`Download progress: ${(receivedSize / totalSize * 100).toFixed(2)}%`);
   *     }
   *   }
   * );
   * console.log(`File downloaded to: ${result.filePath}`);
   * ```
   */
  public async downloadFile(url: string, filePath: string, options?: DownloadOptions): Promise<DownloadResult> {
    // 验证URL，防止SSRF攻击
    this.validateURL(url);

    // 验证文件路径，防止路径遍历攻击
    if (filePath.includes('..') || filePath.includes('\\') || filePath.includes('/')) {
      throw new Error('Invalid file path: potential path traversal detected');
    }

    // 从连接池获取HTTP请求对象
    const httpRequest = this.getHttpRequestFromPool(url);

    try {
      // 检查网络权限 Check network permission
      try {
        const atManager = abilityAccessCtrl.createAtManager();
        await atManager.requestPermissionsFromUser(this.getContext(), ['ohos.permission.INTERNET']);
      } catch (permissionError) {
        Logger.error(HttpService.TAG, 'Failed to request INTERNET permission');
        throw new Error('Network permission denied');
      }

      const headers = options?.headers || {};
      const timeout = options?.timeout !== undefined ? options.timeout : this.httpConfig.timeout * 1000;

      // 验证并清理头部 Validate and sanitize headers
      const sanitizedHeaders = this.validateAndSanitizeHeaders(headers);

      // 构建请求配置 Build request config
      const requestConfig: http.HttpRequestOptions = {
        method: 'GET' as http.RequestMethod,
        connectTimeout: timeout,
        readTimeout: timeout,
        header: {
          'User-Agent': this.httpConfig.userAgent || 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
          // 添加安全头部
          'X-Content-Security-Policy': this.httpConfig.enableContentSecurityPolicy ? 'default-src https:' : '',
          'X-Frame-Options': 'DENY',
          'X-XSS-Protection': '1; mode=block',
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
        },
        // 添加HTTPS证书验证
        usingProxy: false,
        // 安全配置
        enableHttpsVerification: this.httpConfig.enableHttpsVerification
      };

      // 手动合并headers Manually merge headers
      if (sanitizedHeaders) {
        // 确保requestConfig.header存在 Ensure requestConfig.header exists
        if (!requestConfig.header) {
          requestConfig.header = {};
        }
        // 使用传统for循环遍历键值对变量声明 Use traditional for loop to iterate key-value pairs variable declaration
        const entries = Object.entries(sanitizedHeaders);
        for (let i = 0; i < entries.length; i++) {
          const key = entries[i][0];
          const value = entries[i][1];
          requestConfig.header[key] = value;
        }
      }

      // 确保所有属性都有正确的类型 Ensure all properties have correct types
      const method: string = typeof requestConfig.method === 'string' ? requestConfig.method : 'GET';
      const connectTimeout: number = typeof requestConfig.connectTimeout === 'number' ? requestConfig.connectTimeout : 30000;
      const readTimeout: number = typeof requestConfig.readTimeout === 'number' ? requestConfig.readTimeout : 30000;
      const header: Record<string, string> = (requestConfig.header || {}) as Record<string, string>;

      // 发送请求获取文件数据 Send request to get file data
      const response: http.HttpResponse = await httpRequest.request(url, {
        method: method as http.RequestMethod,
        connectTimeout: connectTimeout,
        readTimeout: readTimeout,
        header: header,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      });

      // 计算文件大小 Calculate file size
      let fileSize = 0;
      if (response.result instanceof ArrayBuffer) {
        fileSize = response.result.byteLength;
      }

      // 写入文件 Write file
      try {
        // 导入文件系统模块 Import file system module
        const fs = require('fs');
        
        // 确保目录存在 Ensure directory exists
        const path = require('path');
        const dirPath = path.dirname(filePath);
        if (!fs.existsSync(dirPath)) {
          fs.mkdirSync(dirPath, { recursive: true });
        }
        
        // 写入文件内容 Write file content
        if (response.result instanceof ArrayBuffer) {
          const buffer = Buffer.from(response.result);
          fs.writeFileSync(filePath, buffer);
        } else if (typeof response.result === 'string') {
          fs.writeFileSync(filePath, response.result);
        }
        
        Logger.debug(HttpService.TAG, `Downloaded file: ${url} to ${filePath}, size: ${fileSize} bytes`);
      } catch (fileError) {
        Logger.error(HttpService.TAG, `Failed to write file: ${filePath}`, fileError);
        throw new Error(`Failed to write file: ${fileError instanceof Error ? fileError.message : 'Unknown error'}`);
      }

      const downloadResult: DownloadResult = {
        status: response.responseCode,
        filePath,
        headers: this.sanitizeHeaders(response.header as Record<string, string | number | boolean | null>),
        fileSize: fileSize
      };

      return downloadResult;
    } catch (error) {
      Logger.error(HttpService.TAG, `File download failed: ${url}`);
      throw error instanceof Error ? error : new Error(String(error));
    } finally {
      // 将HTTP请求对象返回连接池
      this.returnHttpRequestToPool(url, httpRequest);
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
    const headerKeys = Object.keys(headers);
    for (let i = 0; i < headerKeys.length; i++) {
      const key = headerKeys[i];
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

  /**
   * 从连接池获取HTTP请求对象
   * Get HTTP request object from connection pool
   * @param url 请求URL Request URL
   * @returns HTTP请求对象 HTTP request object
   */
  private getHttpRequestFromPool(url: string): http.HttpRequest {
    // 清理空闲连接
    this.cleanupIdleConnections();
    
    // 生成连接键（基于主机名）
    const host = this.getHostFromUrl(url);
    const poolKey = `conn_${host}`;
    
    // 检查连接池是否有可用连接
    const pooledConnection = this.connectionPool.get(poolKey);
    if (pooledConnection) {
      // 更新最后使用时间
      pooledConnection.lastUsed = Date.now();
      Logger.debug(HttpService.TAG, `Using pooled connection for ${host}`);
      return pooledConnection.httpRequest;
    }
    
    // 创建新连接
    const newHttpRequest = http.createHttp();
    
    // 如果连接池未满，添加到池
    if (this.connectionPool.size < this.MAX_POOL_SIZE) {
      this.connectionPool.set(poolKey, {
        httpRequest: newHttpRequest,
        lastUsed: Date.now()
      });
      Logger.debug(HttpService.TAG, `Created new connection for ${host}, pool size: ${this.connectionPool.size}`);
    }
    
    return newHttpRequest;
  }

  /**
   * 将HTTP请求对象返回连接池
   * Return HTTP request object to connection pool
   * @param url 请求URL Request URL
   * @param httpRequest HTTP请求对象 HTTP request object
   */
  private returnHttpRequestToPool(url: string, httpRequest: http.HttpRequest): void {
    const host = this.getHostFromUrl(url);
    const poolKey = `conn_${host}`;
    
    // 检查连接池是否已满
    if (this.connectionPool.size < this.MAX_POOL_SIZE) {
      // 更新或添加到连接池
      this.connectionPool.set(poolKey, {
        httpRequest,
        lastUsed: Date.now()
      });
      Logger.debug(HttpService.TAG, `Returned connection to pool for ${host}, pool size: ${this.connectionPool.size}`);
    } else {
      // 连接池已满，销毁连接
      try {
        httpRequest.destroy();
        Logger.debug(HttpService.TAG, `Destroyed connection for ${host} (pool full)`);
      } catch (error) {
        Logger.warn(HttpService.TAG, `Failed to destroy connection: ${error}`);
      }
    }
  }

  /**
   * 清理空闲连接
   * Clean up idle connections
   */
  private cleanupIdleConnections(): void {
    const now = Date.now();
    const keysToRemove: string[] = [];
    
    for (const [key, connection] of this.connectionPool.entries()) {
      if (now - connection.lastUsed > this.MAX_IDLE_TIME) {
        keysToRemove.push(key);
        try {
          connection.httpRequest.destroy();
          Logger.debug(HttpService.TAG, `Cleaned up idle connection: ${key}`);
        } catch (error) {
          Logger.warn(HttpService.TAG, `Failed to destroy idle connection: ${error}`);
        }
      }
    }
    
    // 从连接池移除已清理的连接
    for (const key of keysToRemove) {
      this.connectionPool.delete(key);
    }
  }

  /**
   * 从URL中提取主机名
   * Extract host from URL
   * @param url URL
   * @returns 主机名 Hostname
   */
  private getHostFromUrl(url: string): string {
    try {
      // 简单的主机名提取逻辑
      const match = url.match(/^https?:\/\/([^/]+)/);
      return match ? match[1] : 'default';
    } catch {
      return 'default';
    }
  }

  /**
   * 清理所有连接
   * Clean up all connections
   */
  private cleanupAllConnections(): void {
    for (const [key, connection] of this.connectionPool.entries()) {
      try {
        connection.httpRequest.destroy();
        Logger.debug(HttpService.TAG, `Cleaned up connection: ${key}`);
      } catch (error) {
        Logger.warn(HttpService.TAG, `Failed to destroy connection: ${error}`);
      }
    }
    this.connectionPool.clear();
  }

  /**
   * 生成请求键 Generate request key
   * @param url 请求URL Request URL
   * @param options 请求选项 Request options
   * @returns 请求键 Request key
   */
  private generateRequestKey(url: string, options?: HttpRequestOptions): string {
    const method = options?.method || 'GET';
    const data = options?.data ? JSON.stringify(options.data) : '';
    return `${method}:${url}:${data}`;
  }

  /**
   * 合并请求
   * 
   * 合并相同的请求，避免重复发送，提高网络请求效率。
   * 
   * @typeParam T - 响应数据的类型
   * @param url 请求URL
   * @param options 请求选项
   * @returns Promise<HttpResponse<T>> - 包含响应数据的Promise
   * @example
   * ```typescript
   * // 多个地方同时请求相同的URL
   * const response1 = await httpService.mergeRequest<{ data: any }>('https://api.example.com/data');
   * const response2 = await httpService.mergeRequest<{ data: any }>('https://api.example.com/data');
   * // 实际上只发送了一次网络请求
   * ```
   */
  public async mergeRequest<T>(url: string, options?: HttpRequestOptions): Promise<HttpResponse<T>> {
    const requestKey = this.generateRequestKey(url, options);
    const now = Date.now();

    // 检查是否已有相同的请求在处理中
    const existingRequest = this.mergedRequestQueue.get(requestKey);
    if (existingRequest && (now - existingRequest.timestamp) < 1000) { // 1秒内的相同请求合并
      Logger.debug(HttpService.TAG, `Merging request for ${url}`);
      return existingRequest.promise as Promise<HttpResponse<T>>;
    }

    // 创建新的请求
    const requestPromise = this.executeRequestWithConcurrencyControl<T>(url, options);

    // 存储请求信息
    this.mergedRequestQueue.set(requestKey, {
      promise: requestPromise,
      timestamp: now
    });

    // 请求完成后清理
    requestPromise.finally(() => {
      setTimeout(() => {
        this.mergedRequestQueue.delete(requestKey);
      }, 1000);
    });

    return requestPromise;
  }

  /**
 * 批量执行请求
 * 
 * 批量执行多个HTTP请求，支持并发控制、优先级排序、超时控制和进度跟踪，提高请求效率。
 * 
 * @typeParam T - 响应数据的类型
 * @param requests 请求列表
 * @param options 批量请求选项
 * @returns Promise<Array<HttpResponse<T>>> - 包含所有请求结果的Promise
 * @example
 * ```typescript
 * const requests = [
 *   { url: 'https://api.example.com/data1', priority: 1 },
 *   { url: 'https://api.example.com/data2', priority: 2 },
 *   { url: 'https://api.example.com/data3', priority: 1 }
 * ];
 * 
 * const results = await httpService.batchRequests<{ data: any }>(requests, {
 *   batchSize: 5,
 *   timeout: 30000,
 *   strategy: 'parallel',
 *   onProgress: (completed, total) => {
 *     console.log(`Progress: ${completed}/${total}`);
 *   }
 * });
 * 
 * results.forEach((result, index) => {
 *   console.log(`Request ${index + 1} result:`, result.data);
 * });
 * ```
 */
  public async batchRequests<T>(
    requests: Array<{ url: string, options?: HttpRequestOptions, priority?: number }>,
    options?: {
      batchSize?: number;
      timeout?: number;
      strategy?: 'sequential' | 'parallel' | 'prioritized';
      onProgress?: (completed: number, total: number) => void;
      retryCount?: number;
    }
  ): Promise<Array<HttpResponse<T>>> {
    const results: Array<HttpResponse<T>> = [];
    const batchSize = options?.batchSize || 4;
    const timeout = options?.timeout || 30000;
    const strategy = options?.strategy || 'parallel';
    const onProgress = options?.onProgress;
    const retryCount = options?.retryCount || 3;
    const totalRequests = requests.length;
    let completedRequests = 0;

    // 根据策略处理请求
    let processedRequests = [...requests];
    
    if (strategy === 'prioritized') {
      // 按优先级排序（优先级数字越小，优先级越高）
      processedRequests.sort((a, b) => (a.priority || 0) - (b.priority || 0));
    }

    // 执行请求的函数
    const executeRequest = async (req: { url: string, options?: HttpRequestOptions }): Promise<HttpResponse<T>> => {
      let retries = 0;
      let lastError: Error | null = null;
      
      while (retries <= retryCount) {
        try {
          // 使用Promise.race实现超时控制
          const requestPromise = this.mergeRequest<T>(req.url, req.options);
          const timeoutPromise = new Promise<never>((_, reject) => {
            setTimeout(() => reject(new Error(`Request timeout for ${req.url}`)), timeout);
          });
          
          try {
            // 竞态条件：请求完成或超时
            const result = await Promise.race([requestPromise, timeoutPromise]);
            
            // 更新进度
            completedRequests++;
            onProgress?.(completedRequests, totalRequests);
            
            return result;
          } catch (error) {
            lastError = error instanceof Error ? error : new Error(String(error));
            retries++;
            
            if (retries > retryCount) {
              throw lastError;
            }
            
            // 重试前等待
            await this.sleep(1000 * retries);
          }
        } catch (error) {
          // 更新进度
          completedRequests++;
          onProgress?.(completedRequests, totalRequests);
          throw error;
        }
      }
      
      throw lastError || new Error(`Request failed after ${retryCount} retries`);
    };

    if (strategy === 'sequential') {
      // 顺序执行请求
      for (const req of processedRequests) {
        const result = await executeRequest(req);
        results.push(result);
      }
    } else {
      // 并行分批执行请求
      for (let i = 0; i < processedRequests.length; i += batchSize) {
        const batch = processedRequests.slice(i, i + batchSize);
        const batchPromises = batch.map(executeRequest);
        const batchResults = await Promise.all(batchPromises);
        results.push(...batchResults);
      }
    }

    return results;
  }

  /**
   * 带并发控制的请求执行 Execute request with concurrency control
   * @param url 请求URL Request URL
   * @param options 请求选项 Request options
   * @returns 请求结果 Request result
   */
  private async executeRequestWithConcurrencyControl<T>(url: string, options?: HttpRequestOptions): Promise<HttpResponse<T>> {
    // 等待并发数低于限制
    while (this.currentConcurrentRequests >= this.MAX_CONCURRENT_REQUESTS) {
      await this.sleep(50);
    }

    try {
      this.currentConcurrentRequests++;
      return await this.request<T>(url, options || { method: 'GET' });
    } finally {
      this.currentConcurrentRequests--;
    }
  }

  /**
   * 获取当前并发请求数
   * 
   * 获取当前正在执行的并发请求数量。
   * 
   * @returns 并发请求数
   * @example
   * ```typescript
   * const count = httpService.getConcurrentRequestCount();
   * console.log(`Current concurrent requests: ${count}`);
   * ```
   */
  public getConcurrentRequestCount(): number {
    return this.currentConcurrentRequests;
  }

  /**
   * 清理过期的请求缓存
   * 
   * 清理过期的请求缓存，释放内存资源。
   * 
   * @returns void
   * @example
   * ```typescript
   * httpService.cleanExpiredRequestCache();
   * console.log('Expired request cache cleaned');
   * ```
   */
  public cleanExpiredRequestCache(): void {
    const now = Date.now();
    for (const [key, value] of this.mergedRequestQueue.entries()) {
      if (now - value.timestamp > 5000) { // 清理5秒前的请求缓存
        this.mergedRequestQueue.delete(key);
      }
    }
  }
}


