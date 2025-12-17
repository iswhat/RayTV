// DefaultNetworkRepository - 网络服务默认实现类
import Logger from '../../common/util/Logger';
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

// 定义请求配置类型
interface RepositoryRequestConfig {
  url: string;
  method: http.RequestMethod;
  data?: string | number | boolean | Record<string, string | number | boolean>;
  params: Record<string, string | number | boolean | string[]>;
  headers: Record<string, string>;
  timeout: number;
  retryCount: number;
}

// 定义缓存项类型
class CacheItem<T> {
  data: T;
  timestamp: number;
  constructor(data: T, timestamp: number) {
    this.data = data;
    this.timestamp = timestamp;
  }
}

// 定义HTTP响应接口 - 使用泛型，移除any类型
class Response<T> {
  data: T;
  headers: Record<string, string>;
  status: number;
  constructor(data: T, headers: Record<string, string>, status: number) {
    this.data = data;
    this.headers = headers;
    this.status = status;
  }
}

// 定义响应数据类型 - 使用泛型，移除any类型
class ResponseData<T> {
  data: T;
  headers: Record<string, string>;
  status: number;
  constructor(data: T, headers: Record<string, string>, status: number) {
    this.data = data;
    this.headers = headers;
    this.status = status;
  }
}

// 定义HTTP请求选项类型
interface HttpRequestOptions {
  method: http.RequestMethod;
  header: Record<string, string>;
  extraData?: string | number | boolean | Record<string, string | number | boolean>;
  connectTimeout: number;
  readTimeout: number;
}

// 定义搜索参数转换结果接口 - 移除索引签名
interface SearchParamsRecord {
  keyword: string;
  page: number;
  pageSize: number;
  type?: number;
  genre?: string;
  year?: number;
  region?: string;
  sortBy?: string;
  sortOrder?: string;
}

// 定义缓存记录接口 - 移除索引签名
interface CacheRecord {
  data: string;
  timestamp: number;
}

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
  setConfig(config: NetworkConfig): void {
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
      // 发送请求
      const testUrl = `${this.config.baseUrl}/api/test`;
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseStatus: number;

      try {
        const options: HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: this.config.headers || {},
        connectTimeout: this.config.timeout,
        readTimeout: this.config.timeout
      };
      const response = await httpRequest.request(testUrl, options) as http.HttpResponse;
      responseStatus = response.responseCode;
      } finally {
        httpRequest.destroy();
      }
      
      // 检查响应状态码
      if (responseStatus < 200 || responseStatus >= 300) {
        throw new Error(`Connection test failed: HTTP ${responseStatus}`);
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
   * 将SearchParams转换为Record类型的辅助函数
   */
  private searchParamsToRecord(params: SearchParams): Record<string, string | number | boolean> {
    // 创建空对象并逐个添加属性，避免对象字面量类型问题
    const result: Record<string, string | number | boolean> = {} as Record<string, string | number | boolean>;
    result.keyword = params.keyword;
    result.page = params.page;
    result.pageSize = params.pageSize;
    
    // 只添加存在的可选属性，确保类型安全
    if (params.type !== undefined) result.type = params.type;
    if (params.genre !== undefined) result.genre = params.genre;
    if (params.year !== undefined) result.year = params.year;
    if (params.region !== undefined) result.region = params.region;
    if (params.sortBy !== undefined) result.sortBy = params.sortBy;
    if (params.sortOrder !== undefined) result.sortOrder = params.sortOrder;
    // 包含filters属性，处理非数组类型
    if (params.filters !== undefined) {
      const entries = Object.entries(params.filters);
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        const key = entry[0];
        const value = entry[1];
        // 只处理非数组类型，避免类型错误
        if (!Array.isArray(value)) {
          result[key] = value as string | number | boolean;
        }
      }
    }
    
    return result;
  }

  /**
   * 创建请求配置
   */
  private createRequestConfig(
    url: string,
    method: http.RequestMethod,
    data?: Record<string, string | number | boolean>,
    params?: Record<string, string | number | boolean>,
    customHeaders?: Record<string, string>
  ): RepositoryRequestConfig {
    const requestUrl = url.startsWith('http') ? url : `${this.config.baseUrl}${url}`;
    // 合并headers
    const headers: Record<string, string> = {};
    
    // 复制默认headers
    if (this.config.headers) {
      const configHeadersKeys = Object.keys(this.config.headers);
      for (let i = 0; i < configHeadersKeys.length; i++) {
        const key = configHeadersKeys[i];
        const value = this.config.headers[key];
        headers[key] = value;
      }
    }
    
    // 复制自定义headers（覆盖默认值）
    if (customHeaders) {
      const customHeadersKeys = Object.keys(customHeaders);
      for (let i = 0; i < customHeadersKeys.length; i++) {
        const key = customHeadersKeys[i];
        const value = customHeaders[key];
        headers[key] = value;
      }
    }

    // 过滤掉params中的null值
    const filteredParams: Record<string, string | number | boolean | string[]> = {};
    if (params) {
      const paramsKeys = Object.keys(params);
      for (let i = 0; i < paramsKeys.length; i++) {
        const key = paramsKeys[i];
        const value = params[key];
        if (value !== null) {
          filteredParams[key] = value;
        }
      }
    }

    const config: RepositoryRequestConfig = {
      url: requestUrl,
      method,
      data,
      params: filteredParams,
      headers,
      timeout: this.config.timeout,
      retryCount: this.config.retryCount
    };

    return config;
  }

  /**
   * 处理网络响应 - 针对Response<ResponseData<T>>类型
   */
  // 移除processNetworkResponse和processNetworkResponseDirect方法，直接构建NetworkResult对象


  /**
   * 生成缓存键
   */
  private generateCacheKey(url: string, method: string, params?: Record<string, string | number | boolean>): string {
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
        let cacheObj = cached instanceof JsonDataClass ? cached.toObject() : cached;
        
        // 使用Object.keys检查属性存在性，替代in操作符
        const cacheKeys = Object.keys(cacheObj);
        if (cacheKeys.includes('data') && cacheKeys.includes('timestamp')) {
          // 手动构建CacheItem对象，避免类型转换错误
          const cacheItem: CacheItem<T> = new CacheItem<T>(
            JSON.parse(cacheObj.data as string) as T,
            cacheObj.timestamp as number
          );
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
      Logger.warn(TAG, `Failed to get cache: ${error instanceof Error ? error.message : String(error)}`);
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
      // 创建符合CacheItem接口的对象
      const cacheItem = new CacheItem(data, Date.now());
      // 使用明确的类型初始化对象
      const cacheRecord: CacheRecord = {
        data: JSON.stringify(cacheItem.data),
        timestamp: cacheItem.timestamp
      };
      // 将CacheRecord转换为Record类型，兼容JsonDataClass.fromObject方法
      const cacheRecordObj: Record<string, string | number> = {} as Record<string, string | number>;
      cacheRecordObj.data = cacheRecord.data;
      cacheRecordObj.timestamp = cacheRecord.timestamp;
      const jsonData = JsonDataClass.fromObject(cacheRecordObj);
      await StorageUtil.set(key, jsonData);
      Logger.debug(TAG, `Cache set for key: ${key}`);
    } catch (error) {
      Logger.warn(TAG, `Failed to set cache: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // ========== 搜索相关实现 ==========

  async searchContent(params: SearchParams): Promise<NetworkResult<PaginatedResponse<SearchResult>>> {
    try {
      const requestUrl = '/api/search';
      // 使用辅助函数转换SearchParams类型
      const paramsRecord = this.searchParamsToRecord(params);
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', paramsRecord);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<PaginatedResponse<SearchResult>>(cacheKey);
      if (cachedData) {
        const result: NetworkResult<PaginatedResponse<SearchResult>> = {
          success: true,
          data: cachedData
        };
        return result;
      }

      // 发送请求
      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET, undefined, paramsRecord);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;
      let result: NetworkResult<PaginatedResponse<SearchResult>>;

      try {
        const options: HttpRequestOptions = {
        method: requestConfig.method as http.RequestMethod,
        header: requestConfig.headers,
        extraData: requestConfig.data,
        connectTimeout: requestConfig.timeout,
        readTimeout: requestConfig.timeout
      };
      const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
      responseStatus = response.responseCode;
      responseHeaders = response.header as Record<string, string>;
      // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
      result = {
        success: true,
        data: JSON.parse(response.result as string) as PaginatedResponse<SearchResult>,
        headers: responseHeaders,
        statusCode: responseStatus
      };
      } finally {
        httpRequest.destroy();
      }
      
      // 缓存成功的响应
      if (result.success && result.data) {
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to search content: ${errorObj.message}`);
      const result: NetworkResult<PaginatedResponse<SearchResult>> = {
        success: false,
        error: errorObj,
        message: 'Search failed'
      };
      return result;
    }
  }

  async getHotSearchKeywords(limit: number = 20): Promise<NetworkResult<string[]>> {
    try {
      const requestUrl = '/api/search/hot';
      // 创建params对象，避免对象字面量类型问题
      const params: Record<string, number> = {} as Record<string, number>;
      params.limit = limit;
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<string[]>(cacheKey);
      if (cachedData) {
        const result: NetworkResult<string[]> = {
          success: true,
          data: cachedData
        };
        return result;
      }

      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET, undefined, params);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;
      let result: NetworkResult<string[]>;

      try {
        const options: HttpRequestOptions = {
          method: requestConfig.method as http.RequestMethod,
          header: requestConfig.headers,
          extraData: requestConfig.data,
          connectTimeout: requestConfig.timeout,
          readTimeout: requestConfig.timeout
        } as HttpRequestOptions;
        const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
        responseStatus = response.responseCode;
        responseHeaders = response.header as Record<string, string>;
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as Record<string, string | number | boolean | string[]>;
        result = {
          success: true,
          data: parsedResult.data as string[],
          headers: responseHeaders,
          statusCode: responseStatus
        };
      } finally {
        httpRequest.destroy();
      }
      
      // 缓存成功的响应
      if (result.success && result.data) {
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to get hot search keywords: ${errorObj.message}`);
      const result: NetworkResult<string[]> = {
        success: false,
        error: errorObj,
        message: 'Failed to get hot search keywords'
      };
      return result;
    }
  }

  async getSearchSuggestions(keyword: string, limit: number = 10): Promise<NetworkResult<string[]>> {
    try {
      const requestUrl = '/api/search/suggestions';
      // 创建params对象，避免对象字面量类型问题
      const params: Record<string, string | number> = {} as Record<string, string | number>;
      params.keyword = keyword;
      params.limit = limit;
      
      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET, undefined, params);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;
      let result: NetworkResult<string[]>;

      try {
        const options: HttpRequestOptions = {
          method: requestConfig.method as http.RequestMethod,
          header: requestConfig.headers,
          extraData: requestConfig.data,
          connectTimeout: requestConfig.timeout,
          readTimeout: requestConfig.timeout
        };
        const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
        responseStatus = response.responseCode;
        responseHeaders = response.header as Record<string, string>;
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as string[];
        result = {
          success: true,
          data: parsedResult,
          headers: responseHeaders,
          statusCode: responseStatus
        };
      } finally {
        httpRequest.destroy();
      }
      return result;
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to get search suggestions: ${errorObj.message}`);
      const result: NetworkResult<string[]> = {
        success: false,
        error: errorObj,
        message: 'Failed to get search suggestions'
      };
      return result;
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
        const result: NetworkResult<Movie> = {
          success: true,
          data: cachedData
        };
        return result;
      }

      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;
      let result: NetworkResult<Movie>;

      try {
        const options: HttpRequestOptions = {
          method: requestConfig.method as http.RequestMethod,
          header: requestConfig.headers,
          extraData: requestConfig.data,
          connectTimeout: requestConfig.timeout,
          readTimeout: requestConfig.timeout
        };
        const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
        responseStatus = response.responseCode;
        responseHeaders = response.header as Record<string, string>;
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const responseResult = JSON.parse(response.result as string) as Movie;
        result = {
          success: true,
          data: responseResult,
          headers: responseHeaders,
          statusCode: responseStatus
        };
      } finally {
        httpRequest.destroy();
      }
      
      // 缓存成功的响应
      if (result.success && result.data) {
        // 转换API响应数据为Movie对象 - 避免类型转换问题
        const movie = result.data;
        await this.setCachedData(cacheKey, movie);
      }

      return result;
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to get movie detail: ${errorObj.message}`);
      const result: NetworkResult<Movie> = {
        success: false,
        error: errorObj,
        message: 'Failed to get movie detail'
      };
      return result;
    }
  }

  async getMovieList(params: SearchParams): Promise<NetworkResult<PaginatedResponse<Movie>>> {
    try {
      const requestUrl = '/api/movies';
      // 使用辅助函数转换SearchParams类型
      const paramsRecord = this.searchParamsToRecord(params);
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', paramsRecord);
      
      // 尝试从缓存获取
      const cachedData = await this.getCachedData<PaginatedResponse<Movie>>(cacheKey);
      if (cachedData) {
        const result: NetworkResult<PaginatedResponse<Movie>> = {
          success: true,
          data: cachedData
        };
        return result;
      }

      // 发送请求
      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET, undefined, paramsRecord);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;
      let result: NetworkResult<PaginatedResponse<Movie>>;

      try {
        const options: HttpRequestOptions = {
          method: requestConfig.method as http.RequestMethod,
          header: requestConfig.headers,
          extraData: requestConfig.data,
          connectTimeout: requestConfig.timeout,
          readTimeout: requestConfig.timeout
        };
        const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
        responseStatus = response.responseCode;
        responseHeaders = response.header as Record<string, string>;
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as PaginatedResponse<Movie>;
        result = {
          success: true,
          data: parsedResult,
          headers: responseHeaders,
          statusCode: responseStatus
        };
      } finally {
        httpRequest.destroy();
      }
      
      // 缓存成功的响应并转换数据
      if (result.success && result.data) {
        // 直接使用Movie对象，不需要重新转换
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to get movie list: ${errorObj.message}`);
      const result: NetworkResult<PaginatedResponse<Movie>> = {
        success: false,
        error: errorObj,
        message: 'Failed to get movie list'
      };
      return result;
    }
  }

  // ========== 通用网络方法实现 ==========

  async get<T>(url: string, params?: Record<string, string | number | boolean>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, http.RequestMethod.GET, undefined, params, headers);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;

      try {
        const options: HttpRequestOptions = {
          method: requestConfig.method as http.RequestMethod,
          header: requestConfig.headers,
          extraData: requestConfig.data,
          connectTimeout: requestConfig.timeout,
          readTimeout: requestConfig.timeout
        };
        const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
        responseStatus = response.responseCode;
        responseHeaders = response.header as Record<string, string>;
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as Record<string, string | number | boolean | Record<string, string | number | boolean>>;
        return {
          success: true,
          data: parsedResult.data as T,
          headers: responseHeaders,
          statusCode: responseStatus
        } as NetworkResult<T>;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to send GET request: ${errorObj.message}`);
      const result: NetworkResult<T> = {
        success: false,
        error: errorObj,
        message: 'GET request failed'
      };
      return result;
    }
  }

  async post<T>(url: string, data?: Record<string, string | number | boolean>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, http.RequestMethod.POST, data, undefined, headers);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;

      try {
        const options: HttpRequestOptions = {
          method: requestConfig.method as http.RequestMethod,
          header: requestConfig.headers,
          extraData: requestConfig.data,
          connectTimeout: requestConfig.timeout,
          readTimeout: requestConfig.timeout
        };
        const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
        responseStatus = response.responseCode;
        responseHeaders = response.header as Record<string, string>;
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as Record<string, string | number | boolean | Record<string, string | number | boolean>>;
        return {
          success: true,
          data: parsedResult.data as T,
          headers: responseHeaders,
          statusCode: responseStatus
        } as NetworkResult<T>;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to send POST request: ${errorObj.message}`);
      const result: NetworkResult<T> = {
        success: false,
        error: errorObj,
        message: 'POST request failed'
      };
      return result;
    }
  }

  async put<T>(url: string, data?: Record<string, string | number | boolean>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, http.RequestMethod.PUT, data, undefined, headers);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;

      try {
        const options: HttpRequestOptions = {
          method: requestConfig.method as http.RequestMethod,
          header: requestConfig.headers,
          extraData: requestConfig.data,
          connectTimeout: requestConfig.timeout,
          readTimeout: requestConfig.timeout
        };
        const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
        responseStatus = response.responseCode;
        responseHeaders = response.header as Record<string, string>;
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as Record<string, string | number | boolean | Record<string, string | number | boolean>>;
        return {
          success: true,
          data: parsedResult.data as T,
          headers: responseHeaders,
          statusCode: responseStatus
        } as NetworkResult<T>;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to send PUT request: ${errorObj.message}`);
      const result: NetworkResult<T> = {
        success: false,
        error: errorObj,
        message: 'PUT request failed'
      };
      return result;
    }
  }

  async delete<T>(url: string, params?: Record<string, string | number | boolean>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, http.RequestMethod.DELETE, undefined, params, headers);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: Record<string, string>;
      let responseStatus: number;

      try {
        const options: HttpRequestOptions = {
          method: requestConfig.method,
          header: requestConfig.headers,
          extraData: requestConfig.data,
          connectTimeout: requestConfig.timeout,
          readTimeout: requestConfig.timeout
        };
        const response = await httpRequest.request(requestConfig.url, options) as http.HttpResponse;
        responseStatus = response.responseCode;
        responseHeaders = response.header as Record<string, string>;
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as Record<string, string | number | boolean | Record<string, string | number | boolean>>;
        return {
          success: true,
          data: parsedResult.data as T,
          headers: responseHeaders,
          statusCode: responseStatus
        } as NetworkResult<T>;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to send DELETE request: ${errorObj.message}`);
      const result: NetworkResult<T> = {
        success: false,
        error: errorObj,
        message: 'DELETE request failed'
      };
      return result;
    }
  }

  async upload<T>(url: string, file: ArrayBuffer, params?: Record<string, string | number | boolean>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      Logger.warn(TAG, 'Upload functionality is not fully implemented');
      // 简单实现，返回失败
      return {
        success: false,
        message: 'Upload not implemented'
      };
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to upload file: ${errorObj.message}`);
      return {
        success: false,
        error: errorObj,
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