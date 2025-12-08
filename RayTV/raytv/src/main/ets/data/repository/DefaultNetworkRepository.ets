// DefaultNetworkRepository - 缃戠粶鏈嶅姟榛樿瀹炵幇绫?import Logger from '../../common/util/Logger';
import JsonUtil from '../../common/util/JsonUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
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
import { RequestConfig, Response } from '../../common/util/NetworkUtil';
import { getParserService } from '../../service/parser';

const TAG = 'DefaultNetworkRepository';
const DEFAULT_CACHE_KEY_PREFIX = 'network_cache_';
const DEFAULT_CACHE_EXPIRY = 3600000; // 榛樿缂撳瓨1灏忔椂

/**
 * 缃戠粶浠撳簱榛樿瀹炵幇绫? * 瀹炵幇浜哊etworkRepository鎺ュ彛锛屾彁渚涘熀浜嶩TTP璇锋眰鐨勭綉缁滄湇鍔″姛鑳? */
export default class DefaultNetworkRepository implements NetworkRepository {
  private config: NetworkConfig;
  private requestMap: Map<string, http.HttpRequest> = new Map();

  /**
   * 鏋勯€犲嚱鏁?   */
  constructor() {
    // 榛樿閰嶇疆
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
 * 鍒濆鍖栫綉缁滄湇鍔? * @param config 缃戠粶閰嶇疆瀵硅薄锛屽寘鍚熀纭€URL銆佽秴鏃舵椂闂淬€侀噸璇曟鏁扮瓑
 * @returns 鍒濆鍖栫粨鏋滐紝鎴愬姛鎴栧け璐ヤ俊鎭? */
async initialize(config: NetworkConfig): Promise<NetworkResult<void>> {
    try {
      Logger.info(TAG, 'Initializing network repository...');
      
      // 鍚堝苟閰嶇疆
      this.config = {
        baseUrl: config.baseUrl !== undefined ? config.baseUrl : this.config.baseUrl,
        timeout: config.timeout !== undefined ? config.timeout : this.config.timeout,
        retryCount: config.retryCount !== undefined ? config.retryCount : this.config.retryCount,
        headers: config.headers !== undefined ? config.headers : this.config.headers,
        cacheEnabled: config.cacheEnabled !== undefined ? config.cacheEnabled : this.config.cacheEnabled,
        cacheExpiry: config.cacheExpiry !== undefined ? config.cacheExpiry : this.config.cacheExpiry
      };
      
      // 楠岃瘉蹇呰閰嶇疆
      if (!this.config.baseUrl) {
        throw new Error('Base URL is required');
      }

      // 娴嬭瘯杩炴帴
      await this.testConnection();
      
      Logger.info(TAG, 'Network repository initialized successfully');
      return {
        success: true
      };
    } catch (error) {
      Logger.error(TAG, `Failed to initialize network repository`, error instanceof Error ? error : new Error(String(error)));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Network repository initialization failed'
      };
    }
  }

  /**
   * 璁剧疆缃戠粶閰嶇疆
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
   * 鑾峰彇褰撳墠缃戠粶閰嶇疆
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
   * 娴嬭瘯杩炴帴
   */
  private async testConnection(): Promise<void> {
    try {
      // 鍙戦€佷竴涓畝鍗曠殑GET璇锋眰鏉ユ祴璇曡繛鎺?      const testUrl = `${this.config.baseUrl}/api/test`;
      const response = await NetworkUtil.request<Record<string, string | number | boolean | null>>({ 
        url: testUrl,
        method: 'GET',
        timeout: this.config.timeout
      });
      
      // 妫€鏌ュ搷搴旂姸鎬佺爜
      if (response.status < 200 || response.status >= 300) {
        throw new Error(`Connection test failed: HTTP ${response.status}`);
      }
    } catch (error) {
      Logger.warn(TAG, `Connection test failed, continuing anyway: ${error instanceof Error ? error.message : String(error)}`);
      // 鍗充娇娴嬭瘯澶辫触涔熺户缁垵濮嬪寲锛屽洜涓烘煇浜汚PI鍙兘涓嶆彁渚涙祴璇曠鐐?    }
  }

  /**
   * 鐢熸垚璇锋眰ID
   */
  private generateRequestId(url: string, method: string): string {
    return `${method}_${url}_${Date.now()}`;
  }

  /**
 * 鍒涘缓璇锋眰閰嶇疆
 * @param url 璇锋眰URL锛屽彲浠ユ槸鐩稿璺緞鎴栫粷瀵筓RL
 * @param method HTTP鏂规硶 (GET, POST, PUT, DELETE绛?
 * @param data 璇锋眰浣撴暟鎹? * @param params URL鏌ヨ鍙傛暟
 * @param customHeaders 鑷畾涔夎姹傚ご
 * @returns 鏋勫缓濂界殑璇锋眰閰嶇疆瀵硅薄
 */
private createRequestConfig(
    url: string,
    method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD',
    data?: Record<string, string | number | boolean | null>,
    params?: Record<string, string | number | boolean | null>,
    customHeaders?: Record<string, string>
  ): RequestConfig {
    const requestUrl = url.startsWith('http') ? url : `${this.config.baseUrl}${url}`;
    // 鍚堝苟headers
    const headers: Record<string, string> = {};
    
    // 澶嶅埗榛樿headers
    if (this.config.headers) {
      for (const [key, value] of Object.entries(this.config.headers)) {
        headers[key] = value;
      }
    }
    
    // 澶嶅埗鑷畾涔塰eaders锛堣鐩栭粯璁ゅ€硷級
    if (customHeaders) {
      for (const [key, value] of Object.entries(customHeaders)) {
        headers[key] = value;
      }
    }
    
    // 澶勭悊璇锋眰浣撶被鍨?    if (data && headers['Content-Type'] === 'application/json') {
      data = JsonUtil.stringify(data);
    }

    // 杩囨护鎺塸arams涓殑null鍊硷紝纭繚绗﹀悎RequestConfig鐨勭被鍨嬭姹?    const filteredParams: Record<string, string | number | boolean | string[]> = {};
    if (params) {
      for (const [key, value] of Object.entries(params)) {
        if (value !== null) {
          filteredParams[key] = value as string | number | boolean | string[];
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
   * 澶勭悊缃戠粶鍝嶅簲
   */
  private processNetworkResponse<T>(response: Response<T>): NetworkResult<T> {
    return {
      success: true,
      data: response.data,
      headers: response.headers,
      statusCode: response.status
    };
  }

  /**
   * 鐢熸垚缂撳瓨閿?   */
  private generateCacheKey(url: string, method: string, params?: Record<string, string | number | boolean | null>): string {
    const paramsStr = params ? JsonUtil.stringify(params) : '';
    return `${DEFAULT_CACHE_KEY_PREFIX}${method}_${url}_${paramsStr}`;
  }

  /**
   * 鑾峰彇缂撳瓨鏁版嵁
   */
  private async getCachedData<T>(key: string): Promise<T | null> {
    if (!this.config.cacheEnabled) {
      return null;
    }

    try {
      const cached = await StorageUtil.get(key);
      if (cached && typeof cached === 'object') {
        // 浣跨敤Object.keys妫€鏌ュ睘鎬у瓨鍦ㄦ€э紝鏇夸唬in鎿嶄綔绗?        const cacheKeys = Object.keys(cached);
        if (cacheKeys.includes('data') && cacheKeys.includes('timestamp')) {
          const cacheItem = cached as { data: T; timestamp: number };
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
   * 璁剧疆缂撳瓨鏁版嵁
   */
  private async setCachedData<T>(key: string, data: T): Promise<void> {
    if (!this.config.cacheEnabled) {
      return;
    }

    try {
      const cacheItem: Record<string, string | number | boolean | null> = { ... };
      await StorageUtil.set(key, cacheItem);
      Logger.debug(TAG, `Cache set for key: ${key}`);
    } catch (error) {
      Logger.warn(TAG, `Failed to set cache: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // ========== 鎼滅储鐩稿叧瀹炵幇 ==========

  async searchContent(params: SearchParams): Promise<NetworkResult<PaginatedResponse<SearchResult>>> {
    try {
      const requestUrl = '/api/search';
      const requestId = this.generateRequestId(requestUrl, 'GET');
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params);
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.getCachedData<PaginatedResponse<SearchResult>>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      // 鍒涘缓AbortController
      const controller = new AbortController();
      this.requestMap.set(requestId, controller);

      // 鍙戦€佽姹?      const requestConfig = this.createRequestConfig(requestUrl, 'GET', undefined, params);
      // 鎵嬪姩娣诲姞signal灞炴€э紝涓嶄娇鐢ㄥ睍寮€杩愮畻绗?      (requestConfig as any).signal = controller.signal;
      const response = await NetworkUtil.request(requestUrl, requestConfig);

      // 浠庤姹傛槧灏勪腑绉婚櫎
      this.requestMap.delete(requestId);

      const result = this.processNetworkResponse<PaginatedResponse<SearchResult>>(response);
      
      // 缂撳瓨鎴愬姛鐨勫搷搴?      if (result.success && result.data) {
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to search content`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
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
      const params: Record<string, string | number | boolean | null> = { ... };
      const cacheKey = this.generateCacheKey(requestUrl, 'GET', params);
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.getCachedData<string[]>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const response = await NetworkUtil.request(requestUrl, this.createRequestConfig(requestUrl, 'GET', undefined, params));
      const result = this.processNetworkResponse<string[]>(response);
      
      // 缂撳瓨鎴愬姛鐨勫搷搴?      if (result.success && result.data) {
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get hot search keywords`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
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
      const params: Record<string, string | number> = { keyword, limit };
      
      const requestConfig = this.createRequestConfig(requestUrl, 'GET', undefined, params);
      const response = await NetworkUtil.request(requestUrl, requestConfig);
      return this.processNetworkResponse<string[]>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to get search suggestions`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get search suggestions'
      };
    }
  }

  // ========== 鐢靛奖/瑙嗛鐩稿叧瀹炵幇 ==========

  async getMovieDetail(movieId: string): Promise<NetworkResult<Movie>> {
    try {
      const requestUrl = `/api/movies/${movieId}`;
      const cacheKey = this.generateCacheKey(requestUrl, 'GET');
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.getCachedData<Movie>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const requestConfig = this.createRequestConfig(requestUrl, 'GET');
      const response = await NetworkUtil.request(requestUrl, requestConfig);
      const result = this.processNetworkResponse<Movie>(response);
      
      // 缂撳瓨鎴愬姛鐨勫搷搴?      if (result.success && result.data) {
        // 杞崲API鍝嶅簲鏁版嵁涓篗ovie瀵硅薄
        const movie = new Movie(result.data);
        result.data = movie;
        await this.setCachedData(cacheKey, movie);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get movie detail`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
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
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.getCachedData<PaginatedResponse<Movie>>(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData
        };
      }

      const requestConfig = this.createRequestConfig(requestUrl, 'GET', undefined, params);
      const response = await NetworkUtil.request(requestUrl, requestConfig);
      const result = this.processNetworkResponse<PaginatedResponse<Movie>>(response);
      
      // 缂撳瓨鎴愬姛鐨勫搷搴斿苟杞崲鏁版嵁
      if (result.success && result.data) {
        // 杞崲API鍝嶅簲鏁版嵁涓篗ovie瀵硅薄鏁扮粍
        result.data.items = result.data.items.map(item => new Movie(item));
        await this.setCachedData(cacheKey, result.data);
      }

      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get movie list`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get movie list'
      };
    }
  }

  // ========== 閫氱敤缃戠粶鏂规硶瀹炵幇 ==========

  async get<T>(url: string, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, 'GET', undefined, params, headers);
      const response = await NetworkUtil.request(url, requestConfig);
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send GET request`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'GET request failed'
      };
    }
  }

  async post<T>(url: string, data?: Record<string, unknown>, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, 'POST', data, params, headers);
      const response = await NetworkUtil.request(url, requestConfig);
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send POST request`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'POST request failed'
      };
    }
  }

  async put<T>(url: string, data?: Record<string, unknown>, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, 'PUT', data, params, headers);
      const response = await NetworkUtil.request(url, requestConfig);
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send PUT request`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'PUT request failed'
      };
    }
  }

  async delete<T>(url: string, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      const requestConfig = this.createRequestConfig(url, 'DELETE', undefined, params, headers);
      const response = await NetworkUtil.request(url, requestConfig);
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to send DELETE request`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'DELETE request failed'
      };
    }
  }

  async upload<T>(url: string, file: File, params?: Record<string, unknown>, headers?: Record<string, string>): Promise<NetworkResult<T>> {
    try {
      // 涓婁紶鏂囦欢鏃堕渶瑕佺壒娈婂鐞咰ontent-Type
      const uploadHeaders: Record<string, string> = {};
      
      // 鎵嬪姩澶嶅埗headers锛屾帓闄ontent-Type
      if (headers) {
        for (const [key, value] of Object.entries(headers)) {
          if (key.toLowerCase() !== 'content-type') {
            uploadHeaders[key] = value;
          }
        }
      }

      const formData = new FormData();
      formData.append('file', file);
      
      if (params) {
        // 浣跨敤for寰幆鏇夸唬forEach
        const entries = Object.entries(params);
        for (let i = 0; i < entries.length; i++) {
          const [key, value] = entries[i];
          formData.append(key, String(value));
        }
      }

      // 鍒涘缓璇锋眰閰嶇疆
      const requestConfig = this.createRequestConfig(url, 'POST', undefined, undefined, uploadHeaders);
      // 璁剧疆璇锋眰鏁版嵁
      requestConfig.data = formData;
      
      const response = await NetworkUtil.request(url, requestConfig);
      
      return this.processNetworkResponse<T>(response);
    } catch (error) {
      Logger.error(TAG, `Failed to upload file`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'File upload failed'
      };
    }
  }

  async download(url: string, savePath: string, headers?: Record<string, string>): Promise<NetworkResult<boolean>> {
    try {
      // 鎵嬪姩鍚堝苟headers
      const mergedHeaders: Record<string, string> = {};
      
      // 澶嶅埗榛樿headers
      if (this.config.headers) {
        for (const [key, value] of Object.entries(this.config.headers)) {
          mergedHeaders[key] = value;
        }
      }
      
      // 澶嶅埗鑷畾涔塰eaders锛堣鐩栭粯璁ゅ€硷級
      if (headers) {
        for (const [key, value] of Object.entries(headers)) {
          mergedHeaders[key] = value;
        }
      }
      
      const response = await NetworkUtil.downloadFile(url, savePath, {
        headers: mergedHeaders,
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
      Logger.error(TAG, `Failed to download file`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'File download failed'
      };
    }
  }

  cancelAllRequests(): void {
    try {
      this.requestMap.forEach((request) => {
        request.destroy();
      });
      this.requestMap.clear();
      Logger.info(TAG, 'All requests cancelled');
    } catch (error) {
      Logger.error(TAG, `Failed to cancel all requests`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
    }
  }

  cancelRequest(requestId: string): void {
    try {
      const request = this.requestMap.get(requestId);
      if (request) {
        request.destroy();
        this.requestMap.delete(requestId);
        Logger.info(TAG, `Request cancelled: ${requestId}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to cancel request`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
    }
  }

  // ========== 鍗犱綅瀹炵幇 ==========
  // 涓轰簡浠ｇ爜鑳界紪璇戦€氳繃锛屾彁渚涘熀纭€鐨勫崰浣嶅疄鐜?  async getRecommendedMovies(movieId: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getRelatedMovies(movieId: string, limit: number = 20): Promise<NetworkResult<Movie[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getMovieRating(movieId: string): Promise<NetworkResult<Record<string, unknown>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getVideoSources(contentId: string, contentType: string): Promise<NetworkResult<VideoSourceInfo[]>> { 
    try {
      Logger.info(TAG, `Getting video sources for contentId: ${contentId}, contentType: ${contentType}`);
      
      // 浣跨敤瑙ｆ瀽鍣ㄦ湇鍔¤幏鍙栬棰戞簮
      return await getParserService().getVideoSources(contentId, contentType);
    } catch (error) {
      Logger.error(TAG, `Failed to get video sources`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return { 
        success: false, 
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get video sources' 
      };
    }
  }
  
  async parseVideoSource(sourceUrl: string, parserId?: string): Promise<NetworkResult<VideoSourceInfo>> { 
    try {
      Logger.info(TAG, `Parsing video source: ${sourceUrl}, parserId: ${parserId}`);
      
      // 浣跨敤瑙ｆ瀽鍣ㄦ湇鍔¤В鏋愯棰戞簮
      return await getParserService().parseVideoSource(sourceUrl, parserId);
    } catch (error) {
      Logger.error(TAG, `Failed to parse video source`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return { 
        success: false, 
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to parse video source' 
      };
    }
  }
  
  async getVideoChapters(contentId: string, season: number = 1): Promise<NetworkResult<ChapterInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getVideoDanmaku(contentId: string, startTime: number, endTime: number): Promise<NetworkResult<Record<string, unknown>[]>> { 
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
  
  async getLiveEpg(channelId: string): Promise<NetworkResult<Record<string, unknown>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async searchLiveChannels(keyword: string): Promise<NetworkResult<LiveChannelInfo[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getParsers(): Promise<NetworkResult<ParserInfo[]>> { 
    try {
      Logger.info(TAG, 'Getting available parsers');
      
      // 浣跨敤瑙ｆ瀽鍣ㄦ湇鍔¤幏鍙栨墍鏈夎В鏋愬櫒
      return await getParserService().getParsers();
    } catch (error) {
      Logger.error(TAG, `Failed to get parsers`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return { 
        success: false, 
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get parsers' 
      };
    }
  }
  
  async checkParserAvailability(parserId: string): Promise<NetworkResult<boolean>> { 
    try {
      Logger.info(TAG, `Checking parser availability: ${parserId}`);
      
      // 浣跨敤瑙ｆ瀽鍣ㄦ湇鍔℃鏌ヨВ鏋愬櫒鍙敤鎬?      return await getParserService().checkParserAvailability(parserId);
    } catch (error) {
      Logger.error(TAG, `Failed to check parser availability`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return { 
        success: false, 
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to check parser availability' 
      };
    }
  }
  
  async submitFeedback(feedback: string, contact?: string): Promise<NetworkResult<boolean>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async checkUpdate(currentVersion: string): Promise<NetworkResult<Record<string, unknown>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getAppConfig(): Promise<NetworkResult<Record<string, unknown>>> { 
    return { success: false, message: 'Not implemented' }; 
  }
  
  async getAnnouncements(): Promise<NetworkResult<string[]>> { 
    return { success: false, message: 'Not implemented' }; 
  }
}



