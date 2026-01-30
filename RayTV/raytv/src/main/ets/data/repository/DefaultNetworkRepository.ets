// DefaultNetworkRepository - 网络服务默认实现类 | Default network service implementation class
import StorageUtil from '../../common/util/StorageUtil';
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

// 定义请求参数接口 | Define request params interface
export interface RequestParams {
  keyword?: string;
  page?: number;
  pageSize?: number;
  type?: number;
  genre?: string;
  year?: number;
  region?: string;
  sortBy?: string;
  sortOrder?: string;
  limit?: number;
}

// 定义请求头接口 | Define request headers interface
export interface RequestHeaders {
  'Content-Type'?: string;
  'User-Agent'?: string;
  'Authorization'?: string;
}

// 定义请求数据接口 | Define request data interface
export interface RequestData {
  keyword?: string;
  page?: number;
  pageSize?: number;
  type?: number;
  genre?: string;
  year?: number;
  region?: string;
  sortBy?: string;
  sortOrder?: string;
  limit?: number;
}

// 定义请求配置类型 | Define request configuration type
interface RepositoryRequestConfig {
  url: string;
  method: http.RequestMethod;
  data?: string | number | boolean | RequestData;
  params: RequestParams;
  headers: RequestHeaders;
  timeout: number;
  retryCount: number;
}

// 定义缓存项类型 | Define cache item type
class CacheItem<T> {
  data: T;
  timestamp: number;
  constructor(data: T, timestamp: number) {
    this.data = data;
    this.timestamp = timestamp;
  }
}



// 定义HTTP请求选项类型 | Define HTTP request options type
interface HttpRequestOptions {
  method: http.RequestMethod;
  header: RequestHeaders;
  extraData?: string | number | boolean | RequestData;
  connectTimeout: number;
  readTimeout: number;
}

// 定义搜索参数转换结果接口 | Define search params conversion result interface
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

// 定义缓存记录接口 - 去除引用别名 | Define cache record interface - remove reference alias
interface CacheRecord {
  data: string;
  timestamp: number;
}

const TAG = 'DefaultNetworkRepository';
const DEFAULT_CACHE_KEY_PREFIX = 'network_cache_';
const DEFAULT_CACHE_EXPIRY = 3600000; // 默认缓存1小时 | Default cache 1 hour

/**
 * 网络仓库默认实现类 | Default network repository implementation class
 * 实现了NetworkRepository接口，提供基于HTTP请求的网络服务功能 | Implements NetworkRepository interface, provides HTTP-based network service functionality
 */
export default class DefaultNetworkRepository implements NetworkRepository {
  private config: NetworkConfig;
  private requestMap: Map<string, http.HttpRequest> = new Map();

  /**
   * 构造函数 | Constructor
   */
  constructor() {
    // 默认配置 | Default configuration
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
   * 初始化网络服务 | Initialize network service
   * @param config 网络配置对象，包含默认URL、超时时间、重试次数等 | Network configuration object, including default URL, timeout, retry count, etc.
   * @returns 初始化结果，成功或失败信息 | Initialization result, success or failure information
   */
  async initialize(config: NetworkConfig): Promise<NetworkResult<void>> {
    try {
      console.info(TAG + ': 正在初始化网络仓库... | Initializing network repository...');
      
      // 合并配置 | Merge configuration
      this.config = {
        baseUrl: config.baseUrl !== undefined ? config.baseUrl : this.config.baseUrl,
        timeout: config.timeout !== undefined ? config.timeout : this.config.timeout,
        retryCount: config.retryCount !== undefined ? config.retryCount : this.config.retryCount,
        headers: config.headers !== undefined ? config.headers : this.config.headers,
        cacheEnabled: config.cacheEnabled !== undefined ? config.cacheEnabled : this.config.cacheEnabled,
        cacheExpiry: config.cacheExpiry !== undefined ? config.cacheExpiry : this.config.cacheExpiry
      };
      
      // 验证必要配置 | Validate required configuration 
      if (!this.config.baseUrl) {
        throw new Error('Base URL is required');
      }

      // 测试连接 | Test connection
      await this.testConnection();
      
      console.info(TAG + ': 网络仓库初始化成功 | Network repository initialized successfully');
      return {
        success: true
      };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': 网络仓库初始化失败 | Failed to initialize network repository: ' + (error instanceof Error ? error.message : String(error)));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Network repository initialization failed'
      };
    }
  }

  /**
   * 设置网络配置 | Set network configuration
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
    console.info(TAG + ': 网络配置已更新 | Network config updated');
  }

  /**
   * 获取当前网络配置 | Get current network configuration
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
   * 测试连接 | Test connection
   */
  private async testConnection(): Promise<void> {
    try {
      // 发送请求 | Send request
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
      
      // 检查响应状态码 | Check response status code
      if (responseStatus < 200 || responseStatus >= 300) {
        throw new Error(`Connection test failed: HTTP ${responseStatus}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.warn(TAG + ': 连接测试失败，仍继续初始化 | Connection test failed, continuing anyway: ' + (error instanceof Error ? error.message : String(error)));
      // 即使测试失败也继续初始化，因为某些API可能不提供测试端点
    }
  }

  /**
   * 生成请求ID | Generate request ID
   */
  private generateRequestId(url: string, method: string): string {
    return `${method}_${url}_${Date.now()}`;
  }

  /**
   * 将SearchParams转换为Record类型的辅助函数 | Helper function to convert SearchParams to Record type
   */
  private searchParamsToRecord(params: SearchParams): RequestData {
    // 创建空对象并逐个添加属性，避免对象字面量类型问题
    const result: RequestData = {};
    result.keyword = params.keyword;
    result.page = params.page;
    result.pageSize = params.pageSize;
    
    // 只添加存在的可选属性，确保类型安全 | Only add existing optional properties to ensure type safety
    if (params.type !== undefined) result.type = params.type;
    if (params.genre !== undefined) result.genre = params.genre;
    if (params.year !== undefined) result.year = params.year;
    if (params.region !== undefined) result.region = params.region;
    if (params.sortBy !== undefined) result.sortBy = params.sortBy;
    if (params.sortOrder !== undefined) result.sortOrder = params.sortOrder;
    
    return result;
  }

  /**
   * 创建请求配置 | Create request configuration
   */
  private createRequestConfig(
    url: string,
    method: http.RequestMethod,
    data?: RequestData,
    params?: RequestParams,
    customHeaders?: RequestHeaders
  ): RepositoryRequestConfig {
    const requestUrl = url.startsWith('http') ? url : `${this.config.baseUrl}${url}`;
    // 合并headers | Merge headers
    const headers: RequestHeaders = {};
    
    // 复制默认headers | Copy default headers
    if (this.config.headers) {
      const configHeadersKeys = this.getObjectKeys(this.config.headers);
      for (let i = 0; i < configHeadersKeys.length; i++) {
        const key = configHeadersKeys[i];
        const value = this.config.headers[key];
        if (key === 'Content-Type' || key === 'User-Agent' || key === 'Authorization') {
          headers[key] = value;
        }
      }
    }
    
    // 复制自定义headers（覆盖默认值） | Copy custom headers (override defaults)
    if (customHeaders) {
      const customHeadersKeys = this.getObjectKeys(customHeaders);
      for (let i = 0; i < customHeadersKeys.length; i++) {
        const key = customHeadersKeys[i];
        const value = customHeaders[key];
        if (key === 'Content-Type' || key === 'User-Agent' || key === 'Authorization') {
          headers[key] = value;
        }
      }
    }

    // 过滤掉params中的null值 | Filter out null values in params
    const filteredParams: RequestParams = {};
    if (params) {
      if (params.keyword !== null) filteredParams.keyword = params.keyword;
      if (params.page !== null) filteredParams.page = params.page;
      if (params.pageSize !== null) filteredParams.pageSize = params.pageSize;
      if (params.type !== null) filteredParams.type = params.type;
      if (params.genre !== null) filteredParams.genre = params.genre;
      if (params.year !== null) filteredParams.year = params.year;
      if (params.region !== null) filteredParams.region = params.region;
      if (params.sortBy !== null) filteredParams.sortBy = params.sortBy;
      if (params.sortOrder !== null) filteredParams.sortOrder = params.sortOrder;
      if (params.limit !== null) filteredParams.limit = params.limit;
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
   * 获取对象键 | Get object keys
   */
  private getObjectKeys(obj: object): string[] {
    // 使用Object.keys替代for...in循环
    return Object.keys(obj);
  }

  /**
   * 处理网络响应 | Process network response
   */
  // 移除processNetworkResponse和processNetworkResponseDirect方法，直接构建NetworkResult对象


  /**
   * 生成缓存键 | Generate cache key
   */
  private generateCacheKey(url: string, method: string, params?: RequestData): string {
    const paramsStr = params ? JSON.stringify(params) : '';
    return `${DEFAULT_CACHE_KEY_PREFIX}${method}_${url}_${paramsStr}`;
  }

  /**
   * 获取缓存数据 | Get cached data
   */
  private async getCachedData<T>(key: string): Promise<T | null> {
    if (!this.config.cacheEnabled) {
      return null;
    }

    try {
      const cachedStr = await StorageUtil.getString(key);
      if (cachedStr) {
        const cached = JSON.parse(cachedStr);
        if (cached && typeof cached === 'object') {
          
          if (cached.data !== undefined && cached.timestamp !== undefined) {
            const cacheItem: CacheItem<T> = new CacheItem<T>(
              JSON.parse(String(cached.data)) as T,
              Number(cached.timestamp)
            );
            const now = Date.now();
            const expiry = cacheItem.timestamp + (this.config.cacheExpiry || DEFAULT_CACHE_EXPIRY);
            
            if (now < expiry) {
              console.debug(TAG + `: 缓存命中，键: ${key} | Cache hit for key: ${key}`);
              return cacheItem.data;
            } else {
              console.debug(TAG + `: 缓存已过期，键: ${key} | Cache expired for key: ${key}`);
              await StorageUtil.remove(key);
            }
          }
        }
      }
    } catch (error) {
      console.warn(TAG + ': 获取缓存失败 | Failed to get cache: ' + (error instanceof Error ? error.message : String(error)));
    }
    
    return null;
  }

  /**
   * 设置缓存数据 | Set cached data
   */
  private async setCachedData<T>(key: string, data: T): Promise<void> {
    if (!this.config.cacheEnabled) {
      return;
    }

    try {
      // 创建符合CacheItem接口的对象 | Create object matching CacheItem interface
      const cacheItem = new CacheItem(data, Date.now());
      // 直接构建缓存数据并存储，避免使用未类型化对象字面量 | Build cache data directly and store, avoid untyped object literals
      await StorageUtil.putString(key, JSON.stringify({
        data: JSON.stringify(cacheItem.data),
        timestamp: cacheItem.timestamp
      }));
      console.debug(TAG + `: 缓存已设置，键: ${key} | Cache set for key: ${key}`);
    } catch (error) {
      console.warn(TAG + ': 设置缓存失败 | Failed to set cache: ' + (error instanceof Error ? error.message : String(error)));
    }
  }

  // ========== 搜索相关实现 ========== | ========== Search related implementation ==========

  async searchContent(params: SearchParams): Promise<NetworkResult<PaginatedResponse<SearchResult>>> {
    try {
      const requestUrl = '/api/search';
      // 使用辅助函数转换SearchParams类型
      const paramsRecord = this.searchParamsToRecord(params);
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', paramsRecord);
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedData = await this.getCachedData<PaginatedResponse<SearchResult>>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      // 发送请求 | Send request
      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET, undefined, paramsRecord);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const result: NetworkResult<PaginatedResponse<SearchResult>> = {
          success: true,
          data: JSON.parse(response.result as string) as PaginatedResponse<SearchResult>,
          headers: responseHeaders,
          statusCode: responseStatus
        };
        
        // 缓存成功的响应 | Cache successful response
        if (result.success && result.data) {
          await this.setCachedData(cacheKey, result.data);
        }

        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 搜索内容失败 | Failed to search content: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'Search failed'
      };
    }
  }

  async getHotSearchKeywords(limit: number = 20): Promise<NetworkResult<string[]>> {
    try {
      const requestUrl = '/api/search/hot';
      // 创建params对象，避免对象字面量类型问题
      const params: Record<string, number> = {};
      params.limit = limit;
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params);
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedData = await this.getCachedData<string[]>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET, undefined, params);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string);
        const result: NetworkResult<string[]> = {
          success: true,
          data: parsedResult.data as string[],
          headers: responseHeaders,
          statusCode: responseStatus
        };
        
        // 缓存成功的响应 | Cache successful response
        if (result.success && result.data) {
          await this.setCachedData(cacheKey, result.data);
        }

        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 获取热门搜索关键词失败 | Failed to get hot search keywords: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'Failed to get hot search keywords'
      };
    }
  }

  async getSearchSuggestions(keyword: string, limit: number = 10): Promise<NetworkResult<string[]>> {
    try {
      const requestUrl = '/api/search/suggestions';
      // 创建params对象，避免对象字面量类型问题
      const params: Record<string, string | number> = {};
      params.keyword = keyword;
      params.limit = limit;
      
      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET, undefined, params);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as string[];
        const result: NetworkResult<string[]> = {
          success: true,
          data: parsedResult,
          headers: responseHeaders,
          statusCode: responseStatus
        };
        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 获取搜索建议失败 | Failed to get search suggestions: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'Failed to get search suggestions'
      };
    }
  }

  // ========== 影视/视频相关实现 ========== | ========== Movie/Video related implementation ==========

  async getMovieDetail(movieId: string): Promise<NetworkResult<Movie>> {
    try {
      const requestUrl = `/api/movies/${movieId}`;
      const cacheKey = this.generateCacheKey(requestUrl, 'GET');
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedData = await this.getCachedData<Movie>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const responseResult = JSON.parse(response.result as string) as Movie;
        const result: NetworkResult<Movie> = {
          success: true,
          data: responseResult,
          headers: responseHeaders,
          statusCode: responseStatus
        };
        
        // 缓存成功的响应 | Cache successful response
        if (result.success && result.data) {
          // 转换API响应数据为Movie对象 - 避免类型转换问题
          const movie = result.data;
          await this.setCachedData(cacheKey, movie);
        }

        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 获取影视详情失败 | Failed to get movie detail: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'Failed to get movie detail'
      };
    }
  }

  async getMovieList(params: SearchParams): Promise<NetworkResult<PaginatedResponse<Movie>>> {
    try {
      const requestUrl = '/api/movies';
      // 使用辅助函数转换SearchParams类型
      const paramsRecord = this.searchParamsToRecord(params);
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', paramsRecord);
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedData = await this.getCachedData<PaginatedResponse<Movie>>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      // 发送请求 | Send request
      const requestConfig = this.createRequestConfig(requestUrl, http.RequestMethod.GET, undefined, paramsRecord);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string) as PaginatedResponse<Movie>;
        const result: NetworkResult<PaginatedResponse<Movie>> = {
          success: true,
          data: parsedResult,
          headers: responseHeaders,
          statusCode: responseStatus
        };
        
        // 缓存成功的响应并转换数据 | Cache successful response and convert data
        if (result.success && result.data) {
          // 直接使用Movie对象，不需要重新转换
          await this.setCachedData(cacheKey, result.data);
        }

        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 获取影视列表失败 | Failed to get movie list: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'Failed to get movie list'
      };
    }
  }

  // ========== 通用网络方法实现 ========== | ========== Common network method implementation ==========

  async get<T>(url: string, params?: RequestParams, headers?: RequestHeaders): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, http.RequestMethod.GET, undefined, params, headers);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string);
        const result: NetworkResult<T> = {
          success: true,
          data: parsedResult.data as T,
          headers: responseHeaders,
          statusCode: responseStatus
        };
        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 发送GET请求失败 | Failed to send GET request: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'GET request failed'
      };
    }
  }

  async post<T>(url: string, data?: RequestData, headers?: RequestHeaders): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, http.RequestMethod.POST, data, undefined, headers);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string);
        const result: NetworkResult<T> = {
          success: true,
          data: parsedResult.data as T,
          headers: responseHeaders,
          statusCode: responseStatus
        };
        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 发送POST请求失败 | Failed to send POST request: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'POST request failed'
      };
    }
  }

  async put<T>(url: string, data?: RequestData, headers?: RequestHeaders): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, http.RequestMethod.PUT, data, undefined, headers);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string);
        const result: NetworkResult<T> = {
          success: true,
          data: parsedResult.data as T,
          headers: responseHeaders,
          statusCode: responseStatus
        };
        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 发送PUT请求失败 | Failed to send PUT request: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'PUT request failed'
      };
    }
  }

  async delete<T>(url: string, params?: RequestParams, headers?: RequestHeaders): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, http.RequestMethod.DELETE, undefined, params, headers);
      // 使用http模块直接发送请求，避免NetworkUtil的类型问题
      const httpRequest = http.createHttp();
      let responseHeaders: RequestHeaders = {};
      let responseStatus: number = 0;

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
        const headerObj = response.header;
        if (headerObj && typeof headerObj === 'object') {
          if (headerObj['Content-Type']) responseHeaders['Content-Type'] = String(headerObj['Content-Type']);
          if (headerObj['User-Agent']) responseHeaders['User-Agent'] = String(headerObj['User-Agent']);
          if (headerObj['Authorization']) responseHeaders['Authorization'] = String(headerObj['Authorization']);
        }
        // 直接将响应结果转换为NetworkResult对象，避免中间类型转换
        const parsedResult = JSON.parse(response.result as string);
        const result: NetworkResult<T> = {
          success: true,
          data: parsedResult.data as T,
          headers: responseHeaders,
          statusCode: responseStatus
        };
        return result;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 发送DELETE请求失败 | Failed to send DELETE request: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'DELETE request failed'
      };
    }
  }

  /**
   * 上传文件 | Upload file
   * @param url 上传地址 | Upload URL
   * @param file 文件数据 | File data
   * @param params 请求参数 | Request parameters
   * @param headers 自定义头部 | Custom headers
   * @returns 上传结果 | Upload result
   */
  async upload<T>(url: string, file: ArrayBuffer, params?: RequestParams, headers?: RequestHeaders): Promise<NetworkResult<T>> {
    try {
      console.warn(TAG + ': 上传功能未完全实现 | Upload functionality is not fully implemented');
      // 简单实现，返回失败
      const result: NetworkResult<T> = {
        success: false,
        message: 'Upload not implemented'
      };
      return result;
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 上传文件失败 | Failed to upload file: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
        message: 'File upload failed'
      };
    }
  }

  /**
   * 下载文件 | Download file
   * @param url 下载地址 | Download URL
   * @param savePath 保存路径 | Save path
   * @param headers 自定义头部 | Custom headers
   * @returns 下载结果 | Download result
   */
  async download(url: string, savePath: string, headers?: RequestHeaders): Promise<NetworkResult<boolean>> {
    try {
      console.warn(TAG + ': 文件下载功能未完全实现 | File download functionality is not fully implemented');
      // 简化实现，返回失败，因为NetworkUtil没有提供downloadFile方法
      const result: NetworkResult<boolean> = {
        success: false,
        message: 'File download not implemented'
      };
      return result;
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + ': 下载文件失败 | Failed to download file: ' + errorObj.message);
      return {
        success: false,
        error: errorObj,
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
          const errorMsg = e instanceof Error ? e.message : String(e);
          console.warn(TAG + ': 销毁请求失败 | Failed to destroy request: ' + (e instanceof Error ? e.message : String(e)));
        }
      });
      this.requestMap.clear();
      console.info(TAG + ': 所有请求已取消 | All requests cancelled');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': 取消所有请求失败 | Failed to cancel all requests: ' + (error instanceof Error ? error.message : String(error)));
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
          const errorMsg = e instanceof Error ? e.message : String(e);
          console.warn(TAG + ': 销毁请求失败 | Failed to destroy request: ' + (e instanceof Error ? e.message : String(e)));
        }
        this.requestMap.delete(requestId);
        console.info(TAG + `: 请求已取消: ${requestId} | Request cancelled: ${requestId}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': 取消请求失败 | Failed to cancel request: ' + (error instanceof Error ? error.message : String(error)));
      return;
    }
  }

  // ========== 占位实现 ========== | ========== Placeholder implementation ==========
  // 为了代码能编译通过，提供基本的占位实现
  async getRecommendedMovies(movieId: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getRelatedMovies(movieId: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getMovieRating(movieId: string): Promise<NetworkResult<RequestData>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getVideoSources(contentId: string, contentType: string): Promise<NetworkResult<VideoSourceInfo[]>> { 
    try {
      console.info(TAG + `: 正在获取视频源，内容ID: ${contentId}, 内容类型: ${contentType} | Getting video sources for contentId: ${contentId}, contentType: ${contentType}`);
      
      return { success: false, message: 'Not implemented' };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': 获取视频源失败 | Failed to get video sources: ' + (error instanceof Error ? error.message : String(error)));
      return { 
        success: false, 
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to get video sources' 
      };
    }
  }
  
  async parseVideoSource(sourceUrl: string, parserId?: string): Promise<NetworkResult<VideoSourceInfo>> { 
    try {
      console.info(TAG + `: 正在解析视频源: ${sourceUrl}, 解析器ID: ${parserId} | Parsing video source: ${sourceUrl}, parserId: ${parserId}`);
      
      return { success: false, message: 'Not implemented' };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': 解析视频源失败 | Failed to parse video source: ' + (error instanceof Error ? error.message : String(error)));
      return { 
        success: false, 
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to parse video source' 
      };
    }
  }
  
  async getVideoChapters(contentId: string, season: number = 1): Promise<NetworkResult<ChapterInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getCategories(): Promise<NetworkResult<RequestData>> { 
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
  
  // ========== 排行榜相关实现 ========== | ========== Ranking related implementation ==========
  async getRankings(type: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getWeeklyHot(limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getMonthlyNew(limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  // ========== 直播相关实现 ========== | ========== Live related implementation ==========
  async getLiveChannels(category?: string): Promise<NetworkResult<LiveChannelInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getLiveEpg(channelId: string): Promise<NetworkResult<RequestData>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async searchLiveChannels(keyword: string): Promise<NetworkResult<LiveChannelInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  // ========== 解析器相关实现 ========== | ========== Parser related implementation ==========
  async getParsers(): Promise<NetworkResult<ParserInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async checkParserAvailability(parserId: string): Promise<NetworkResult<boolean>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  // ========== 设置相关实现 ========== | ========== Settings related implementation ==========
  async submitFeedback(feedback: string, contact?: string): Promise<NetworkResult<boolean>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async checkUpdate(currentVersion: string): Promise<NetworkResult<RequestData>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getAppConfig(): Promise<NetworkResult<RequestData>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getAnnouncements(): Promise<NetworkResult<string[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
}



