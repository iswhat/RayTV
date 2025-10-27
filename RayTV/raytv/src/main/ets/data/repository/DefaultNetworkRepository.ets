// DefaultNetworkRepository - 网络服务默认实现类
import Logger from '../../common/util/Logger';
import JsonUtil from '../../common/util/JsonUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import StorageUtil from '../../common/util/StorageUtil';
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
import { RequestConfig, Response } from '../../common/util/NetworkUtil';

const TAG = 'DefaultNetworkRepository';
const DEFAULT_CACHE_KEY_PREFIX = 'network_cache_';
const DEFAULT_CACHE_EXPIRY = 3600000; // 默认缓存1小时

/**
 * 网络仓库默认实现类
 * 实现了NetworkRepository接口，提供基于HTTP请求的网络服务功能
 */
export default class DefaultNetworkRepository implements NetworkRepository {
  private config: NetworkConfig;
  private requestMap: Map<string, AbortController> = new Map();

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
   */
  async initialize(config: NetworkConfig): Promise<NetworkResult<void>> {
    try {
      Logger.info(TAG, 'Initializing network repository...');
      
      // 合并配置
      this.config = { ...this.config, ...config };
      
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
      Logger.error(TAG, `Failed to initialize network repository: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Network repository initialization failed'
      };
    }
  }

  /**
   * 设置网络配置
   */
  setConfig(config: Partial<NetworkConfig>): void {
    this.config = { ...this.config, ...config };
    Logger.info(TAG, 'Network config updated');
  }

  /**
   * 获取当前网络配置
   */
  getConfig(): NetworkConfig {
    return { ...this.config };
  }

  /**
   * 测试连接
   */
  private async testConnection(): Promise<void> {
    try {
      // 发送一个简单的GET请求来测试连接
      const testUrl = `${this.config.baseUrl}/api/test`;
      const response = await NetworkUtil.request(testUrl, {
        method: 'GET',
        timeout: this.config.timeout,
        retryCount: 1
      });
      
      if (!response.success) {
        throw new Error(`Connection test failed: ${response.error?.message || 'Unknown error'}`);
      }
    } catch (error) {
      Logger.warn(TAG, `Connection test failed, continuing anyway: ${error instanceof Error ? error.message : String(error)}`);
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
    method: string,
    data?: Record<string, any>,
    params?: Record<string, any>,
    customHeaders?: Record<string, string>
  ): RequestConfig {
    const requestUrl = url.startsWith('http') ? url : `${this.config.baseUrl}${url}`;
    const headers = { ...this.config.headers, ...customHeaders };
    
    // 处理请求体类型
    if (data && headers['Content-Type'] === 'application/json') {
      data = JsonUtil.stringify(data);
    }

    return {
      url: requestUrl,
      method,
      data,
      params,
      headers,
      timeout: this.config.timeout,
      retryCount: this.config.retryCount
    };
  }

  /**
   * 处理网络响应
   */
  private processNetworkResponse<T>(response: Response<any>): NetworkResult<T> {
    if (response.success) {
      return {
        success: true,
        data: response.data as T,
        headers: response.headers,
        statusCode: response.status
      };
    } else {
      return {
        success: false,
        error: response.error,
        message: response.error?.message || 'Request failed',
        statusCode: response.status
      };
    }
  }

  /**
   * 生成缓存键
   */
  private generateCacheKey(url: string, method: string, params?: Record<string, any>): string {
    const paramsStr = params ? JsonUtil.stringify(params) : '';
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
      if (cached && typeof cached === 'object' && 'data' in cached && 'timestamp' in cached) {
        const now = Date.now();
        const expiry = (cached as any).timestamp + (this.config.cacheExpiry || DEFAULT_CACHE_EXPIRY);
        
        if (now < expiry) {
          Logger.debug(TAG, `Cache hit for key: ${key}`);
          return (cached as any).data;
        } else {
          Logger.debug(TAG, `Cache expired for key: ${key}`);
          await StorageUtil.remove(key);
        }
      }
    } catch (error) {
      Logger.warn(TAG, `Failed to get cache: ${error instanceof Error ? error.message : String(error)}`);
    }
    
    return null;
  }

  /**
   * 设置缓存数据
   */
  private async setCachedData(key: string, data: any): Promise<void> {
    if (!this.config.cacheEnabled) {
      return;
    }

    try {
      const cacheItem = {
        data,
        timestamp: Date.now()
      };
      await StorageUtil.set(key, cacheItem);
      Logger.debug(TAG, `Cache set for key: ${key}`);
    } catch (error) {
      Logger.warn(TAG, `Failed to set cache: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // ========== 搜索相关实现 ==========

  async searchContent(params: SearchParams): Promise<NetworkResult<PaginatedResponse<SearchResult>>> {
    try {
      const requestUrl = '/api/search';
      const requestId = this.generateRequestId(requestUrl, 'GET');
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<PaginatedResponse<SearchResult>>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      // 创建AbortController
      const controller = new AbortController();
      this.requestMap.set(requestId, controller);

      // 发送请求
      const response = await NetworkUtil.request(requestUrl, {
        ...this.createRequestConfig(requestUrl, 'GET', undefined, params),
        signal: controller.signal
      });

      // 从请求映射中移除
      this.requestMap.delete(requestId);

      const result = this.processNetworkResponse<PaginatedResponse<SearchResult>>(response);
      
      // 缓存成功的响应
      if (result.success && result.data) {
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to search content: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Search failed'
      };
    }
  }

  async getHotSearchKeywords(limit: number = 20): Promise<NetworkResult<string[]>> {
    try {
      const requestUrl = '/api/search/hot';
      const params = { limit };
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<string[]>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const response = await NetworkUtil.request(requestUrl, this.createRequestConfig(requestUrl, 'GET', undefined, params));
      const result = this.processNetworkResponse<string[]>(response);
      
      // 缓存成功的响应
      if (result.success && result.data) {
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get hot search keywords: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get hot search keywords'
      };
    }
  }

  async getSearchSuggestions(keyword: string, limit: number = 10): Promise<NetworkResult<string[]>> {
    try {
      const requestUrl = '/api/search/suggestions';
      const params = { keyword, limit };
      
      const response = await NetworkUtil.request(requestUrl, this.createRequestConfig(requestUrl, 'GET', undefined, params));
      return this.processNetworkResponse<string[]>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to get search suggestions: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
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

      const response = await NetworkUtil.request(requestUrl, this.createRequestConfig(requestUrl, 'GET'));
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
      Logger.error(TAG, `Failed to get movie detail: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get movie detail'
      };
    }
  }

  async getMovieList(params: SearchParams): Promise<NetworkResult<PaginatedResponse<Movie>>> {
    try {
      const requestUrl = '/api/movies';
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<PaginatedResponse<Movie>>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const response = await NetworkUtil.request(requestUrl, this.createRequestConfig(requestUrl, 'GET', undefined, params));
      const result = this.processNetworkResponse<PaginatedResponse<Movie>>(response);
      
      // 缓存成功的响应并转换数据
      if (result.success && result.data) {
        // 转换API响应数据为Movie对象数组
        result.data.items = result.data.items.map(item => new Movie(item));
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get movie list: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get movie list'
      };
    }
  }

  // ========== 通用网络方法实现 ==========

  async get<T>(url: string, params?: Record<string, any>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const response = await NetworkUtil.request(url, this.createRequestConfig(url, 'GET', undefined, params, headers));
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send GET request: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'GET request failed'
      };
    }
  }

  async post<T>(url: string, data?: Record<string, any>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const response = await NetworkUtil.request(url, this.createRequestConfig(url, 'POST', data, undefined, headers));
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send POST request: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'POST request failed'
      };
    }
  }

  async put<T>(url: string, data?: Record<string, any>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const response = await NetworkUtil.request(url, this.createRequestConfig(url, 'PUT', data, undefined, headers));
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send PUT request: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'PUT request failed'
      };
    }
  }

  async delete<T>(url: string, params?: Record<string, any>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const response = await NetworkUtil.request(url, this.createRequestConfig(url, 'DELETE', undefined, params, headers));
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send DELETE request: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'DELETE request failed'
      };
    }
  }

  async upload<T>(url: string, file: any, params?: Record<string, any>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      // 上传文件时需要特殊处理Content-Type
      const uploadHeaders = { ...headers };
      delete uploadHeaders['Content-Type']; // 让浏览器自动设置multipart/form-data

      const formData = new FormData();
      formData.append('file', file);
      
      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          formData.append(key, value);
        });
      }

      const response = await NetworkUtil.request(url, {
        ...this.createRequestConfig(url, 'POST', undefined, undefined, uploadHeaders),
        data: formData
      });
      
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to upload file: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'File upload failed'
      };
    }
  }

  async download(url: string, savePath: string, headers?: Record<string, string>): Promise<NetworkResult<boolean>> {
    try {
      const response = await NetworkUtil.downloadFile(url, savePath, {
        headers: { ...this.config.headers, ...headers },
        timeout: this.config.timeout
      });
      
      if (response.success) {
        return {
          success: true,
          data: true
        };
      } else {
        return {
          success: false,
          error: response.error,
          message: 'Download failed'
        };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to download file: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'File download failed'
      };
    }
  }

  cancelAllRequests(): void {
    try {
      this.requestMap.forEach((controller) => {
        controller.abort();
      });
      this.requestMap.clear();
      Logger.info(TAG, 'All requests cancelled');
    } catch (error) {
      Logger.error(TAG, `Failed to cancel all requests: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  cancelRequest(requestId: string): void {
    try {
      const controller = this.requestMap.get(requestId);
      if (controller) {
        controller.abort();
        this.requestMap.delete(requestId);
        Logger.info(TAG, `Request cancelled: ${requestId}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to cancel request: ${error instanceof Error ? error.message : String(error)}`);
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
  
  async getMovieRating(movieId: string): Promise<NetworkResult<Record<string, any>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getVideoSources(contentId: string, contentType: string): Promise<NetworkResult<VideoSourceInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async parseVideoSource(sourceUrl: string, parserId?: string): Promise<NetworkResult<VideoSourceInfo>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getVideoChapters(contentId: string, season: number = 1): Promise<NetworkResult<ChapterInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getVideoDanmaku(contentId: string, startTime: number, endTime: number): Promise<NetworkResult<any[]>> { 
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
  
  async getRankings(type: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getWeeklyHot(limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getMonthlyNew(limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getLiveChannels(category?: string): Promise<NetworkResult<LiveChannelInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getLiveEpg(channelId: string): Promise<NetworkResult<Record<string, any>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async searchLiveChannels(keyword: string): Promise<NetworkResult<LiveChannelInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getParsers(): Promise<NetworkResult<ParserInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async checkParserAvailability(parserId: string): Promise<NetworkResult<boolean>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async submitFeedback(feedback: string, contact?: string): Promise<NetworkResult<boolean>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async checkUpdate(currentVersion: string): Promise<NetworkResult<Record<string, any>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getAppConfig(): Promise<NetworkResult<Record<string, any>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getAnnouncements(): Promise<NetworkResult<string[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
}