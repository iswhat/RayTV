// DefaultNetworkRepository - 网络服务默认实现类
import Logger from '../../common/util/Logger';
import NetworkUtil from '../../common/util/NetworkUtil';
import StorageUtil, { JsonDataClass } from '../../common/util/StorageUtil';
import http from '@ohos.net.http';
import NetworkRepository, {
  NetworkResult,
  NetworkConfig,
  SearchParams,
  PaginatedResponse,
  VideoSourceInfo,
  ChapterInfo,
  LiveChannelInfo,
  ParserInfo
} from './NetworkRepository';
import Movie from '../model/Movie';
import SearchResult, { ResultType } from '../model/SearchResult';

const TAG = 'DefaultNetworkRepository';
const DEFAULT_CACHE_KEY_PREFIX = 'network_cache_';
const DEFAULT_CACHE_EXPIRY = 3600000; // 默认缓存1小时

/**
 * 网络仓库默认实现类
 * 实现了NetworkRepository接口，提供基于HTTP请求的网络服务功能
 */
export default class DefaultNetworkRepository implements NetworkRepository {
  private config: NetworkConfig;
  private requestMap: Map<string, http.HttpRequest> = new Map();

  /**
   * 构造函数
   */
  constructor() {
    // 默认配置
    this.config = {
      baseUrl: '',
      timeout: 30000,
      retryCount: 3,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'RayTV/1.0 HarmonyOS'
      },
      cacheEnabled: true,
      cacheExpiry: DEFAULT_CACHE_EXPIRY
    };
  }

  /**
   * 初始化网络服务
   * @param config 网络配置对象，包含基础URL、超时时间、重试次数等
   * @returns 初始化结果，成功或失败信息
   */
  async initialize(config: NetworkConfig): Promise<NetworkResult<void>> {
    try {
      Logger.info(TAG, 'Initializing network repository...');
      
      // 合并配置
      this.config = {
        baseUrl: config.baseUrl !== undefined ? config.baseUrl : this.config.baseUrl,
        timeout: config.timeout !== undefined ? config.timeout : this.config.timeout,
        retryCount: config.retryCount !== undefined ? config.retryCount : this.config.retryCount,
        headers: config.headers !== undefined ? config.headers : this.config.headers,
        cacheEnabled: config.cacheEnabled !== undefined ? config.cacheEnabled : this.config.cacheEnabled,
        cacheExpiry: config.cacheExpiry !== undefined ? config.cacheExpiry : this.config.cacheExpiry
      };
      
      // 验证必要配置
      if (!this.config.baseUrl) {
        throw new Error('Base URL is required');
      }

      // 测试连接
      await this.testConnection();
      
      Logger.info(TAG, 'Network repository initialized successfully');
      return {
        success: true
      };
    } catch (error) {
      Logger.error(TAG, `Failed to initialize network repository: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'Network repository initialization failed'
      };
    }
  }

  /**
   * 设置网络配置
   */
  setConfig(config: Partial<NetworkConfig>): void {
    this.config = {
      baseUrl: config.baseUrl !== undefined ? config.baseUrl : this.config.baseUrl,
      timeout: config.timeout !== undefined ? config.timeout : this.config.timeout,
      retryCount: config.retryCount !== undefined ? config.retryCount : this.config.retryCount,
      headers: config.headers !== undefined ? config.headers : this.config.headers,
      cacheEnabled: config.cacheEnabled !== undefined ? config.cacheEnabled : this.config.cacheEnabled,
      cacheExpiry: config.cacheExpiry !== undefined ? config.cacheExpiry : this.config.cacheExpiry
    };
    Logger.info(TAG, 'Network config updated');
  }

  /**
   * 获取当前网络配置
   */
  getConfig(): NetworkConfig {
    return {
      baseUrl: this.config.baseUrl,
      timeout: this.config.timeout,
      retryCount: this.config.retryCount,
      headers: this.config.headers,
      cacheEnabled: this.config.cacheEnabled,
      cacheExpiry: this.config.cacheExpiry
    };
  }

  /**
   * 测试连接
   */
  private async testConnection(): Promise<void> {
    try {
      // 发送一个简单的GET请求来测试连接
      const testUrl = `${this.config.baseUrl}/api/test`;
      const response = await NetworkUtil.request({
        url: testUrl,
        method: 'GET',
        timeout: this.config.timeout
      });
      
      // 检查响应状态码
      if (response.status < 200 || response.status >= 300) {
        throw new Error(`Connection test failed: HTTP ${response.status}`);
      }
    } catch (error) {
      Logger.warn(TAG, `Connection test failed, continuing anyway: ${(error as Error).message}`);
      // 即使测试失败也继续初始化，因为某些API可能不提供测试端点
    }
  }

  /**
   * 生成请求ID
   */
  private generateRequestId(url: string, method: string): string {
    return `${method}_${url}_${Date.now()}`;
  }

  /**
   * 创建请求配置
   */
  private createRequestConfig(
    url: string,
    method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD',
    data?: Record<string, string | number | boolean | null>,
    params?: Record<string, string | number | boolean | null>,
    customHeaders?: Record<string, string>
  ): any {
    const requestUrl = url.startsWith('http') ? url : `${this.config.baseUrl}${url}`;
    // 合并headers
    const headers: Record<string, string> = {};
    
    // 复制默认headers
    if (this.config.headers) {
      for (const [key, value] of Object.entries(this.config.headers)) {
        headers[key] = value;
      }
    }
    
    // 复制自定义headers（覆盖默认值）
    if (customHeaders) {
      for (const [key, value] of Object.entries(customHeaders)) {
        headers[key] = value;
      }
    }

    // 过滤掉params中的null值
    const filteredParams: Record<string, string | number | boolean> = {};
    if (params) {
      for (const [key, value] of Object.entries(params)) {
        if (value !== null) {
          filteredParams[key] = value;
        }
      }
    }

    return {
      url: requestUrl,
      method,
      data,
      params: filteredParams,
      headers,
      timeout: this.config.timeout,
      retryCount: this.config.retryCount
    };
  }

  /**
   * 处理网络响应
   */
  private processNetworkResponse<T>(response: any): NetworkResult<T> {
    return {
      success: true,
      data: response.data,
      headers: response.headers,
      statusCode: response.status
    };
  }

  /**
   * 生成缓存键
   */
  private generateCacheKey(url: string, method: string, params?: Record<string, string | number | boolean | null>): string {
    const paramsStr = params ? JSON.stringify(params) : '';
    return `${DEFAULT_CACHE_KEY_PREFIX}${method}_${url}_${paramsStr}`;
  }

  /**
   * 获取缓存数据
   */
  private async getCachedData<T>(key: string): Promise<T | null> {
    if (!this.config.cacheEnabled) {
      return null;
    }

    try {
      const cached = await StorageUtil.get(key);
      if (cached && typeof cached === 'object') {
        // 将JsonDataClass转换为普通对象
        let cacheObj: any;
        if (cached instanceof JsonDataClass) {
          cacheObj = cached.toObject();
        } else {
          cacheObj = cached;
        }
        
        // 使用Object.keys检查属性存在性，替代in操作符
        const cacheKeys = Object.keys(cacheObj);
        if (cacheKeys.includes('data') && cacheKeys.includes('timestamp')) {
          const cacheItem = cacheObj as { data: T; timestamp: number };
          const now = Date.now();
          const expiry = cacheItem.timestamp + (this.config.cacheExpiry || DEFAULT_CACHE_EXPIRY);
          
          if (now < expiry) {
            Logger.debug(TAG, `Cache hit for key: ${key}`);
            return cacheItem.data;
          } else {
            Logger.debug(TAG, `Cache expired for key: ${key}`);
            await StorageUtil.remove(key);
          }
        }
      }
    } catch (error) {
      Logger.warn(TAG, `Failed to get cache: ${(error as Error).message}`);
    }
    
    return null;
  }

  /**
   * 设置缓存数据
   */
  private async setCachedData<T>(key: string, data: T): Promise<void> {
    if (!this.config.cacheEnabled) {
      return;
    }

    try {
      const cacheItem: Record<string, unknown> = {
        data,
        timestamp: Date.now()
      };
      // 将普通对象转换为JsonDataClass实例，使用类型断言确保类型安全
      const jsonData = JsonDataClass.fromObject(cacheItem as Record<string, string | number | boolean | object | null>);
      await StorageUtil.set(key, jsonData);
      Logger.debug(TAG, `Cache set for key: ${key}`);
    } catch (error) {
      Logger.warn(TAG, `Failed to set cache: ${(error as Error).message}`);
    }
  }

  // ========== 搜索相关实现 ==========

  async searchContent(params: SearchParams): Promise<NetworkResult<PaginatedResponse<SearchResult>>> {
    try {
      const requestUrl = '/api/search';
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params as unknown as Record<string, string | number | boolean | null>);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<PaginatedResponse<SearchResult>>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      // 发送请求
      const requestConfig = this.createRequestConfig(requestUrl, 'GET', undefined, params as unknown as Record<string, string | number | boolean | null>);
      const response = await NetworkUtil.request(requestConfig);

      const result = this.processNetworkResponse<PaginatedResponse<SearchResult>>(response);
      
      // 缓存成功的响应
      if (result.success && result.data) {
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to search content: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'Search failed'
      };
    }
  }

  async getHotSearchKeywords(limit: number = 20): Promise<NetworkResult<string[]>> {
    try {
      const requestUrl = '/api/search/hot';
      const params: Record<string, string | number | boolean | null> = { limit };
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<string[]>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const requestConfig = this.createRequestConfig(requestUrl, 'GET', undefined, params);
      const response = await NetworkUtil.request(requestConfig);
      const result = this.processNetworkResponse<string[]>(response);
      
      // 缓存成功的响应
      if (result.success && result.data) {
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get hot search keywords: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'Failed to get hot search keywords'
      };
    }
  }

  async getSearchSuggestions(keyword: string, limit: number = 10): Promise<NetworkResult<string[]>> {
    try {
      const requestUrl = '/api/search/suggestions';
      const params: Record<string, string | number> = { keyword, limit };
      
      const requestConfig = this.createRequestConfig(requestUrl, 'GET', undefined, params);
      const response = await NetworkUtil.request(requestConfig);
      return this.processNetworkResponse<string[]>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to get search suggestions: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'Failed to get search suggestions'
      };
    }
  }

  // ========== 电影/视频相关实现 ==========

  async getMovieDetail(movieId: string): Promise<NetworkResult<Movie>> {
    try {
      const requestUrl = `/api/movies/${movieId}`;
      const cacheKey = this.generateCacheKey(requestUrl, 'GET');
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<Movie>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const requestConfig = this.createRequestConfig(requestUrl, 'GET');
      const response = await NetworkUtil.request(requestConfig);
      const result = this.processNetworkResponse<Movie>(response);
      
      // 缓存成功的响应
      if (result.success && result.data) {
        // 转换API响应数据为Movie对象
        const movie = new Movie(result.data);
        result.data = movie;
        await this.setCachedData(cacheKey, movie);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get movie detail: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'Failed to get movie detail'
      };
    }
  }

  async getMovieList(params: SearchParams): Promise<NetworkResult<PaginatedResponse<Movie>>> {
    try {
      const requestUrl = '/api/movies';
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params as unknown as Record<string, string | number | boolean | null>);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<PaginatedResponse<Movie>>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const requestConfig = this.createRequestConfig(requestUrl, 'GET', undefined, params as unknown as Record<string, string | number | boolean | null>);
      const response = await NetworkUtil.request(requestConfig);
      const result = this.processNetworkResponse<PaginatedResponse<Movie>>(response);
      
      // 缓存成功的响应并转换数据
      if (result.success && result.data) {
        // 转换API响应数据为Movie对象数组
        result.data.items = result.data.items.map(item => new Movie(item));
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get movie list: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'Failed to get movie list'
      };
    }
  }

  // ========== 通用网络方法实现 ==========

  async get<T>(url: string, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, 'GET', undefined, params as Record<string, string | number | boolean | null>, headers);
      const response = await NetworkUtil.request(requestConfig);
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send GET request: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'GET request failed'
      };
    }
  }

  async post<T>(url: string, data?: Record<string, unknown>, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, 'POST', data as Record<string, string | number | boolean | null>, params as Record<string, string | number | boolean | null>, headers);
      const response = await NetworkUtil.request(requestConfig);
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send POST request: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'POST request failed'
      };
    }
  }

  async put<T>(url: string, data?: Record<string, unknown>, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, 'PUT', data as Record<string, string | number | boolean | null>, params as Record<string, string | number | boolean | null>, headers);
      const response = await NetworkUtil.request(requestConfig);
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send PUT request: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'PUT request failed'
      };
    }
  }

  async delete<T>(url: string, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, 'DELETE', undefined, params as Record<string, string | number | boolean | null>, headers);
      const response = await NetworkUtil.request(requestConfig);
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send DELETE request: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'DELETE request failed'
      };
    }
  }

  async upload<T>(url: string, file: any, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      Logger.warn(TAG, 'Upload functionality is not fully implemented');
      // 简单实现，返回失败
      return {
        success: false,
        message: 'Upload not implemented'
      };
    } catch (error) {
      Logger.error(TAG, `Failed to upload file: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'File upload failed'
      };
    }
  }

  async download(url: string, savePath: string, headers?: Record<string, string>): Promise<NetworkResult<boolean>> {
    try {
      Logger.warn(TAG, 'File download functionality is not fully implemented');
      // 简化实现，返回失败，因为NetworkUtil没有提供downloadFile方法
      return {
        success: false,
        message: 'File download not implemented'
      };
    } catch (error) {
      Logger.error(TAG, `Failed to download file: ${(error as Error).message}`);
      return {
        success: false,
        error: error as Error,
        message: 'File download failed'
      };
    }
  }

  cancelAllRequests(): void {
    try {
      this.requestMap.forEach((request) => {
        try {
          request.destroy();
        } catch (e) {
          Logger.warn(TAG, `Failed to destroy request: ${(e as Error).message}`);
        }
      });
      this.requestMap.clear();
      Logger.info(TAG, 'All requests cancelled');
    } catch (error) {
      Logger.error(TAG, `Failed to cancel all requests: ${(error as Error).message}`);
      return;
    }
  }

  cancelRequest(requestId: string): void {
    try {
      const request = this.requestMap.get(requestId);
      if (request) {
        try {
          request.destroy();
        } catch (e) {
          Logger.warn(TAG, `Failed to destroy request: ${(e as Error).message}`);
        }
        this.requestMap.delete(requestId);
        Logger.info(TAG, `Request cancelled: ${requestId}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to cancel request: ${(error as Error).message}`);
      return;
    }
  }

  // ========== 占位实现 ==========
  // 为了代码能编译通过，提供基础的占位实现
  async getRecommendedMovies(movieId: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getRelatedMovies(movieId: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getMovieRating(movieId: string): Promise<NetworkResult<Record<string, string | number | boolean>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getVideoSources(contentId: string, contentType: string): Promise<NetworkResult<VideoSourceInfo[]>> { 
    try {
      Logger.info(TAG, `Getting video sources for contentId: ${contentId}, contentType: ${contentType}`);
      
      return { success: false, message: 'Not implemented' };
    } catch (error) {
      Logger.error(TAG, `Failed to get video sources: ${(error as Error).message}`);
      return { 
        success: false, 
        error: error as Error,
        message: 'Failed to get video sources' 
      };
    }
  }
  
  async parseVideoSource(sourceUrl: string, parserId?: string): Promise<NetworkResult<VideoSourceInfo>> { 
    try {
      Logger.info(TAG, `Parsing video source: ${sourceUrl}, parserId: ${parserId}`);
      
      return { success: false, message: 'Not implemented' };
    } catch (error) {
      Logger.error(TAG, `Failed to parse video source: ${(error as Error).message}`);
      return { 
        success: false, 
        error: error as Error,
        message: 'Failed to parse video source' 
      };
    }
  }
  
  async getVideoChapters(contentId: string, season: number = 1): Promise<NetworkResult<ChapterInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getVideoDanmaku(contentId: string, startTime: number, endTime: number): Promise<NetworkResult<Record<string, string | number | boolean>[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async submitDanmaku(contentId: string, danmaku: string, timestamp: number): Promise<NetworkResult<boolean>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getCategories(): Promise<NetworkResult<Record<string, string[]>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getGenres(): Promise<NetworkResult<string[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getRegions(): Promise<NetworkResult<string[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getYears(): Promise<NetworkResult<number[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  // ========== 排行榜相关实现 ==========
  async getRankings(type: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getWeeklyHot(limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getMonthlyNew(limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  // ========== 直播相关实现 ==========
  async getLiveChannels(category?: string): Promise<NetworkResult<LiveChannelInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getLiveEpg(channelId: string): Promise<NetworkResult<Record<string, string | number | boolean>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async searchLiveChannels(keyword: string): Promise<NetworkResult<LiveChannelInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  // ========== 解析器相关实现 ==========
  async getParsers(): Promise<NetworkResult<ParserInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async checkParserAvailability(parserId: string): Promise<NetworkResult<boolean>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  // ========== 设置相关实现 ==========
  async submitFeedback(feedback: string, contact?: string): Promise<NetworkResult<boolean>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async checkUpdate(currentVersion: string): Promise<NetworkResult<Record<string, string | number | boolean>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getAppConfig(): Promise<NetworkResult<Record<string, string | number | boolean>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getAnnouncements(): Promise<NetworkResult<string[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
}