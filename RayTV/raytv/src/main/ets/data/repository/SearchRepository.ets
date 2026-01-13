/*
 * Copyright (c) 2024 RayTV. All rights reserved.
 */

import Logger from '@ohos:raytv/src/main/ets/utils/Logger';
import StorageUtil from '@ohos:raytv/src/main/ets/utils/StorageUtil';
import NetworkUtil from '@ohos:raytv/src/main/ets/utils/NetworkUtil';
import EventBusUtil from '@ohos:raytv/src/main/ets/utils/EventBusUtil';
import CacheService from '@ohos:raytv/src/main/ets/service/CacheService';
import ConfigRepository from './ConfigRepository';
import { CacheType } from '@ohos:raytv/src/main/ets/service/CacheService';
import { LocalStorageType } from '@ohos:raytv/src/main/ets/utils/StorageUtil';

/**
 * 鎼滅储绫诲瀷鏋氫妇
 */
export enum SearchType {
  ALL = 'all',
  VIDEO = 'video',
  LIVE = 'live',
  USER = 'user',
  CHANNEL = 'channel'
}

/**
 * 鎼滅储鎺掑簭鏋氫妇
 */
export enum SearchSort {
  DEFAULT = 'default',
  LATEST = 'latest',
  HOTTEST = 'hottest',
  RATING_DESC = 'rating_desc',
  RATING_ASC = 'rating_asc',
  RELEASE_DATE_DESC = 'release_date_desc',
  RELEASE_DATE_ASC = 'release_date_asc'
}

/**
 * 鎼滅储浜嬩欢绫诲瀷甯搁噺
 */
export const SearchEventType = {
  SEARCH_PERFORMED: 'search:performed',
  SEARCH_COMPLETED: 'search:completed',
  SEARCH_ERROR: 'search:error',
  SEARCH_CACHED: 'search:cached',
  SEARCH_SUGGESTIONS_LOADED: 'search:suggestions:loaded',
  TRENDING_SEARCHES_LOADED: 'search:trending:loaded',
  SEARCH_HISTORY_ADDED: 'search:history:added',
  SEARCH_HISTORY_CLEARED: 'search:history:cleared'
} as const;

/**
 * 鎼滅储浜嬩欢鎺ュ彛
 */
export interface SearchEvent {
  query: string;
  type: SearchType;
  sort?: SearchSort;
  timestamp: number;
  results?: SearchResult;
  error?: Error;
  suggestions?: SearchSuggestion[];
}

/**
 * 鎼滅储璇锋眰鎺ュ彛
 */
export interface SearchRequest {
  query: string;
  type: SearchType;
  sort: SearchSort;
  page: number;
  pageSize: number;
  filters?: Record<string, Serializable>;
}

/**
 * 鎼滅储缁撴灉鎺ュ彛
 */
export interface SearchResult {
  items: SearchResultItem[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

/**
 * 鎼滅储缁撴灉椤规帴鍙?
 */
export interface SearchResultItem {
  id: string;
  title: string;
  description?: string;
  type: SearchType;
  thumbnailUrl?: string;
  duration?: number;
  metadata?: Record<string, unknown>;
}

/**
 * 鎼滅储寤鸿鎺ュ彛
 */
export interface SearchSuggestion {
  text: string;
  type: SearchType;
  popularity: number;
  recent?: boolean;
}

/**
 * 鐑棬鎼滅储鎺ュ彛
 */
export interface TrendingSearch {
  query: string;
  type: SearchType;
  count: number;
  trend: 'up' | 'down' | 'stable';
}

/**
 * 鎼滅储鍘嗗彶椤规帴鍙?
 */
export interface SearchHistoryItem {
  query: string;
  type: SearchType;
  timestamp: number;
  resultCount?: number;
}

/**
 * 瑙嗛淇℃伅鎺ュ彛锛堢敤浜庢悳绱㈢粨鏋滈」璇︽儏锛?
 */
export interface VideoInfo {
  id: string;
  title: string;
  description: string;
  coverUrl: string;
  duration: number;
  videoType: string;
  quality: string;
  viewCount: number;
  uploadTime: number;
}

/**
 * 鎼滅储浠撳簱
 */
export class SearchRepository {
  private static instance: SearchRepository | null = null;
  
  // 鎼滅储绫诲瀷鏋氫妇鍊?
  private getSearchTypeValues(): SearchType[] {
    return [
      SearchType.ALL,
      SearchType.VIDEO,
      SearchType.LIVE,
      SearchType.USER,
      SearchType.CHANNEL
    ];
  }
  
  // 鎼滅储鎺掑簭鏋氫妇鍊?
  private getSearchSortValues(): SearchSort[] {
    return [
      SearchSort.DEFAULT,
      SearchSort.LATEST,
      SearchSort.HOTTEST,
      SearchSort.RATING_DESC,
      SearchSort.RATING_ASC,
      SearchSort.RELEASE_DATE_DESC,
      SearchSort.RELEASE_DATE_ASC
    ];
  }
  
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  
  // API绔偣閰嶇疆锛屼粠閰嶇疆绯荤粺鑾峰彇
  private apiEndpoints: any;
  private configRepository: ConfigRepository;
  
  // 瀛樺偍鍜岀紦瀛橀敭閰嶇疆
  private storageKeys = {
    searchHistory: 'search:history',
    searchPreferences: 'search:preferences',
    searchResults: 'search:results:',
    trendingSearches: 'search:trending',
    popularSearches: 'search:popular'
  };
  
  // 鎼滅储閰嶇疆
  private searchConfig = {
    maxHistoryItems: 50, // 鏈€澶у巻鍙茶褰曟暟
    historyExpiryDays: 30, // 鍘嗗彶璁板綍杩囨湡澶╂暟
    resultCacheDuration: 3600, // 鎼滅储缁撴灉缂撳瓨鏃堕棿锛堢锛?
    suggestionsCacheDuration: 300, // 鎼滅储寤鸿缂撳瓨鏃堕棿锛堢锛?
    trendingCacheDuration: 3600, // 鐑棬鎼滅储缂撳瓨鏃堕棿锛堢锛?
    minSearchLength: 1, // 鏈€灏忔悳绱㈤暱搴?
    debounceTime: 300 // 鎼滅储闃叉姈鏃堕棿锛堟绉掞級
  };
  
  // 鎼滅储闃叉姈瀹氭椂鍣?
  private searchDebounceTimer: number | null = null;

  /**
   * 绉佹湁鏋勯€犲嚱鏁?   */
  private constructor() {
    this.logger.info('SearchRepository initialized');
    this.configRepository = ConfigRepository.getInstance();
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 鑾峰彇SearchRepository鍗曚緥瀹炰緥
   */
  public static getInstance(): SearchRepository {
    if (!SearchRepository.instance) {
      SearchRepository.instance = new SearchRepository();
    }
    return SearchRepository.instance;
  }

  /**
   * 鍒濆鍖朅PI绔偣閰嶇疆
   */
  private async initializeApiEndpoints(): Promise<void> {
    try {
      // 浠庨厤缃郴缁熻幏鍙朅PI绔偣閰嶇疆
      const apiConfig = await this.configRepository.getConfig<any>('api_endpoints', {
        baseUrl: 'https://api.raytv.example.com',
        search: '/search',
        suggestions: '/search/suggestions',
        trending: '/search/trending',
        popular: '/search/popular'
      });
      this.apiEndpoints = apiConfig;
    } catch (error) {
      this.logger.error('Failed to initialize API endpoints', error as Error);
      // 浣跨敤榛樿閰嶇疆
      this.apiEndpoints = {
        baseUrl: 'https://api.raytv.example.com',
        search: '/search',
        suggestions: '/search/suggestions',
        trending: '/search/trending',
        popular: '/search/popular'
      };
    }
  }

  /**
   * 鍒濆鍖栨悳绱粨搴?   */
  public async initialize(): Promise<void> {
    try {
      // 鍒濆鍖朅PI绔偣閰嶇疆
      await this.initializeApiEndpoints();
      
      // 娓呯悊杩囨湡鐨勬悳绱㈠巻鍙?      await this.cleanupExpiredHistory();
      
      // 棰勫姞杞界儹闂ㄦ悳绱紙寮傛锛?      this.loadTrendingSearches().catch(err => {
        this.logger.warn('Failed to preload trending searches', err);
      });
      
      this.logger.info('SearchRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize SearchRepository', error as Error);
    }
  }

  /**
   * 璁剧疆浜嬩欢鐩戝惉鍣?
   */
  private setupEventListeners(): void {
    // 鐩戝惉搴旂敤閫€鍑轰簨浠讹紝纭繚鏁版嵁鎸佷箙鍖?
    this.eventBus.on('app:exit', async () => {
      // 娓呯悊杩囨湡鍘嗗彶璁板綍
      await this.cleanupExpiredHistory();
    });
    
    // 鐩戝惉缃戠粶鐘舵€佸彉鍖?
    this.eventBus.on('network:statusChanged', async (status: { isOnline: boolean }) => {
      if (status.isOnline) {
        // 鍦ㄧ嚎鏃跺埛鏂扮儹闂ㄦ悳绱?
        await this.loadTrendingSearches();
      }
    });
  }

  /**
   * 鎵ц鎼滅储
   * @param request 鎼滅储璇锋眰
   * @param useCache 鏄惁浣跨敤缂撳瓨
   */
  public async performSearch(request: SearchRequest, useCache: boolean = true): Promise<SearchResult> {
    try {
      // 楠岃瘉鎼滅储璇锋眰
      this.validateSearchRequest(request);
      
      const searchId = this.generateSearchId(request);
      
      // 鍙戝竷鎼滅储寮€濮嬩簨浠?
      this.eventBus.emit(SearchEventType.SEARCH_PERFORMED, {
        query: request.query,
        type: request.type,
        sort: request.sort,
        timestamp: Date.now()
      } as SearchEvent);
      
      // 灏濊瘯浠庣紦瀛樿幏鍙栫粨鏋?
      if (useCache) {
        const cachedResult = await this.getCachedSearchResult(searchId);
        if (cachedResult) {
          this.logger.debug(`Search result loaded from cache for: ${request.query}`);
          
          // 鍙戝竷缂撳瓨鍛戒腑浜嬩欢
          this.eventBus.emit(SearchEventType.SEARCH_CACHED, {
            query: request.query,
            type: request.type,
            sort: request.sort,
            timestamp: Date.now(),
            results: cachedResult
          } as SearchEvent);
          
          // 鏇存柊鎼滅储鍘嗗彶
          this.addToSearchHistory(request, cachedResult.items.length);
          
          return cachedResult;
        }
      }
      
      // 鏋勫缓鎼滅储鍙傛暟
      const searchParams = this.buildSearchParams(request);
      
      // 璋冪敤API杩涜鎼滅储
      const response = await this.networkUtil.get<SearchResult>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.search}`,
        {
          params: searchParams
        }
      );
      
      const searchResult = response.data;
      
      // 缂撳瓨鎼滅储缁撴灉
      await this.cacheSearchResult(searchId, searchResult);
      
      // 鏇存柊鎼滅储鍘嗗彶
      this.addToSearchHistory(request, searchResult.items.length);
      
      // 璁板綍鐢ㄦ埛鎼滅储琛屼负锛堝紓姝ワ級
      this.trackSearch(request, searchResult.items.length);
      
      // 鍙戝竷鎼滅储瀹屾垚浜嬩欢
      this.eventBus.emit(SearchEventType.SEARCH_COMPLETED, {
        query: request.query,
        type: request.type,
        sort: request.sort,
        timestamp: Date.now(),
        results: searchResult
      } as SearchEvent);
      
      this.logger.info(`Search completed for: ${request.query}, found ${searchResult.items.length} items`);
      
      return searchResult;
    } catch (error) {
      this.logger.error('Search failed', error as Error);
      
      // 鍙戝竷鎼滅储閿欒浜嬩欢
      this.eventBus.emit(SearchEventType.SEARCH_ERROR, {
        query: request.query,
        type: request.type,
        sort: request.sort,
        timestamp: Date.now(),
        error: error as Error
      } as SearchEvent);
      
      throw error;
    }
  }

  /**
   * 鎵ц闃叉姈鎼滅储
   * @param request 鎼滅储璇锋眰
   * @param callback 鍥炶皟鍑芥暟
   */
  public debouncedSearch(
    request: SearchRequest,
    callback: (result: SearchResult | null, error?: Error) => void
  ): void {
    // 娓呴櫎涔嬪墠鐨勫畾鏃跺櫒
    if (this.searchDebounceTimer !== null) {
      clearTimeout(this.searchDebounceTimer);
    }
    
    // 璁剧疆鏂扮殑瀹氭椂鍣?
    this.searchDebounceTimer = setTimeout(async () => {
      try {
        const result = await this.performSearch(request);
        callback(result);
      } catch (error) {
        callback(null, error as Error);
      } finally {
        this.searchDebounceTimer = null;
      }
    }, this.searchConfig.debounceTime) as unknown as number;
  }

  /**
   * 鑾峰彇鎼滅储寤鸿
   * @param query 鎼滅储鏌ヨ
   * @param type 鎼滅储绫诲瀷
   */
  public async getSearchSuggestions(query: string, type?: SearchType): Promise<SearchSuggestion[]> {
    try {
      // 楠岃瘉鏌ヨ闀垮害
      if (query.trim().length < this.searchConfig.minSearchLength) {
        return [];
      }
      
      // 鐢熸垚缂撳瓨閿?
      const cacheKey = `search:suggestions:${query}:${type || 'all'}`;
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?
      const cachedSuggestions = await this.cacheService.getCache<SearchSuggestion[]>(cacheKey);
      if (cachedSuggestions) {
        return cachedSuggestions;
      }
      
      // 鏋勫缓寤鸿鍙傛暟
      const params: Record<string, unknown> = {
        q: query.trim(),
        limit: 10
      };
      
      if (type) {
        params.type = type;
      }
      
      // 璋冪敤API鑾峰彇寤鸿
      const response = await this.networkUtil.get<SearchSuggestion[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.suggestions}`,
        {
          params
        }
      );
      
      const suggestions = response.data;
      
      // 鑾峰彇鐢ㄦ埛鎼滅储鍘嗗彶锛屾爣璁版渶杩戞悳绱?
      const history = await this.getSearchHistory();
      suggestions.forEach(suggestion => {
        const recent = history.find(h => 
          h.query.toLowerCase() === suggestion.text.toLowerCase() && 
          (!type || h.type === type)
        );
        suggestion.recent = !!recent;
      });
      
      // 缂撳瓨寤鸿缁撴灉
      await this.cacheService.setCache(
        cacheKey,
        suggestions,
        {
          type: CacheType.MEMORY,
          expiry: this.searchConfig.suggestionsCacheDuration * 1000
        }
      );
      
      // 鍙戝竷寤鸿鍔犺浇浜嬩欢
      this.eventBus.emit(SearchEventType.SEARCH_SUGGESTIONS_LOADED, {
        query,
        type,
        suggestions
      });
      
      return suggestions;
    } catch (error) {
      this.logger.warn('Failed to get search suggestions', error as Error);
      
      // 澶辫触鏃跺皾璇曚粠鏈湴鍘嗗彶鐢熸垚寤鸿
      return this.generateLocalSuggestions(query, type);
    }
  }

  /**
   * 鑾峰彇鐑棬鎼滅储
   */
  public async getTrendingSearches(): Promise<TrendingSearch[]> {
    // 棣栧厛灏濊瘯浠庣紦瀛樻垨鍐呭瓨鑾峰彇
    const cached = await this.cacheService.getCache<TrendingSearch[]>(this.storageKeys.trendingSearches);
    if (cached) {
      return cached;
    }
    
    // 缂撳瓨鏈懡涓紝鍔犺浇鏂版暟鎹?
    return this.loadTrendingSearches();
  }

  /**
   * 鍔犺浇鐑棬鎼滅储
   */
  private async loadTrendingSearches(): Promise<TrendingSearch[]> {
    try {
      const response = await this.networkUtil.get<TrendingSearch[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.trending}`,
        {
          params: {
            limit: 15,
            period: 'week'
          }
        }
      );
      
      const trendingSearches = response.data;
      
      // 缂撳瓨鐑棬鎼滅储
      await this.cacheService.setCache(
        this.storageKeys.trendingSearches,
        trendingSearches,
        {
          type: CacheType.MEMORY_DISK,
          expiry: this.searchConfig.trendingCacheDuration * 1000
        }
      );
      
      // 鍙戝竷鐑棬鎼滅储鍔犺浇浜嬩欢
      this.eventBus.emit(SearchEventType.TRENDING_SEARCHES_LOADED, trendingSearches);
      
      return trendingSearches;
    } catch (error) {
      this.logger.warn('Failed to load trending searches', error as Error);
      
      // 灏濊瘯浠庢湰鍦板瓨鍌ㄨ幏鍙栫紦瀛樼殑鐑棬鎼滅储
      return await this.cacheService.getCache<TrendingSearch[]>(this.storageKeys.trendingSearches) || [];
    }
  }

  /**
   * 鑾峰彇鎼滅储鍘嗗彶
   * @param limit 闄愬埗鏁伴噺
   * @param type 绛涢€夌被鍨?
   */
  public async getSearchHistory(limit?: number, type?: SearchType): Promise<SearchHistoryItem[]> {
    try {
      const history = await this.storageUtil.getObject<SearchHistoryItem[]>(
        this.storageKeys.searchHistory,
        LocalStorageType.DEFAULT
      ) || [];
      
      // 绛涢€夌被鍨?
      let filtered = history;
      if (type) {
        filtered = history.filter(item => item.type === type);
      }
      
      // 鎺掑簭锛堟渶鏂扮殑鍦ㄥ墠锛?
      filtered.sort((a, b) => b.timestamp - a.timestamp);
      
      // 闄愬埗鏁伴噺
      if (limit && limit > 0) {
        filtered = filtered.slice(0, limit);
      }
      
      return filtered;
    } catch (error) {
      this.logger.error('Failed to get search history', error as Error);
      return [];
    }
  }

  /**
   * 娓呴櫎鎼滅储鍘嗗彶
   * @param type 鍙€夌殑绫诲瀷绛涢€?
   */
  public async clearSearchHistory(type?: SearchType): Promise<void> {
    try {
      if (type) {
        // 娓呴櫎鐗瑰畾绫诲瀷鐨勫巻鍙?
        const history = await this.getSearchHistory();
        const filteredHistory = history.filter(item => item.type !== type);
        await this.storageUtil.setObject(
          this.storageKeys.searchHistory, 
          filteredHistory,
          LocalStorageType.DEFAULT
        );
      } else {
        // 娓呴櫎鎵€鏈夊巻鍙?
        await this.storageUtil.remove(this.storageKeys.searchHistory, LocalStorageType.DEFAULT);
      }
      
      // 鍙戝竷鍘嗗彶娓呴櫎浜嬩欢
      this.eventBus.emit(SearchEventType.SEARCH_HISTORY_CLEARED, { type });
      
      this.logger.info(`Search history cleared${type ? ` for type ${type}` : ''}`);
    } catch (error) {
      this.logger.error('Failed to clear search history', error as Error);
      throw error;
    }
  }

  /**
   * 浠庢悳绱㈠巻鍙蹭腑绉婚櫎鐗瑰畾椤?
   * @param query 鎼滅储鏌ヨ
   * @param type 鎼滅储绫诲瀷
   */
  public async removeFromSearchHistory(query: string, type: SearchType): Promise<void> {
    try {
      const history = await this.getSearchHistory();
      const filteredHistory = history.filter(
        item => !(item.query.toLowerCase() === query.toLowerCase() && item.type === type)
      );
      
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        filteredHistory,
        LocalStorageType.DEFAULT
      );
      
      this.logger.info(`Removed item from search history: ${query}`);
    } catch (error) {
      this.logger.error('Failed to remove item from search history', error as Error);
    }
  }

  /**
   * 鏍规嵁ID鑾峰彇鎼滅储缁撴灉椤硅鎯?
   * @param id 鎼滅储缁撴灉椤笽D
   * @param type 鎼滅储缁撴灉椤圭被鍨?
   */
  public async getSearchResultItemById(id: string, type: SearchType): Promise<SearchResultItem | null> {
    try {
      // 鏋勫缓缂撳瓨閿?
      const cacheKey = `search:item:${type}:${id}`;
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?
      let item = await this.cacheService.getCache<SearchResultItem>(cacheKey);
      if (item) {
        return item;
      }
      
      // 缂撳瓨鏈懡涓紝鏍规嵁绫诲瀷鑾峰彇璇︽儏
      switch (type) {
        case SearchType.VIDEO:
          // 璋冪敤瑙嗛璇︽儏API
          const response = await this.networkUtil.get<VideoInfo>(
            `${this.apiEndpoints.baseUrl}/videos/${id}`
          );
          
          // 杞崲涓烘悳绱㈢粨鏋滈」鏍煎紡
          item = {
            id: response.data.id,
            title: response.data.title,
            description: response.data.description,
            type: SearchType.VIDEO,
            thumbnailUrl: response.data.coverUrl,
            duration: response.data.duration,
            metadata: {
              videoType: response.data.videoType,
              quality: response.data.quality,
              viewCount: response.data.viewCount,
              uploadTime: response.data.uploadTime
            }
          };
          break;
          
        case SearchType.LIVE:
          // 璋冪敤鐩存挱璇︽儏API
          const liveResponse = await this.networkUtil.get(
            `${this.apiEndpoints.baseUrl}/live/${id}`
          );
          
          // 杞崲涓烘悳绱㈢粨鏋滈」鏍煎紡
          item = {
            id: liveResponse.data.id,
            title: liveResponse.data.title,
            description: liveResponse.data.description,
            type: SearchType.LIVE,
            thumbnailUrl: liveResponse.data.coverUrl,
            metadata: {
              status: liveResponse.data.status,
              viewerCount: liveResponse.data.viewerCount,
              startTime: liveResponse.data.startTime
            }
          };
          break;
          
        default:
          return null;
      }
      
      // 缂撳瓨缁撴灉椤?
      if (item) {
        await this.cacheService.setCache(
          cacheKey,
          item,
          {
            type: CacheType.MEMORY,
            expiry: 3600 * 1000 // 1灏忔椂
          }
        );
      }
      
      return item;
    } catch (error) {
      this.logger.error(`Failed to get search result item by ID: ${id}`, error as Error);
      return null;
    }
  }

  /**
   * 楠岃瘉鎼滅储璇锋眰
   */
  private validateSearchRequest(request: SearchRequest): void {
    const errors: string[] = [];
    
    if (!request.query || request.query.trim().length < this.searchConfig.minSearchLength) {
      errors.push(`Search query must be at least ${this.searchConfig.minSearchLength} characters`);
    }
    
    if (!this.getSearchTypeValues().includes(request.type)) {
      errors.push('Invalid search type');
    }
    
    if (!this.getSearchSortValues().includes(request.sort)) {
      errors.push('Invalid sort option');
    }
    
    if (request.page < 1) {
      errors.push('Page number must be at least 1');
    }
    
    if (request.pageSize < 1 || request.pageSize > 100) {
      errors.push('Page size must be between 1 and 100');
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 鏋勫缓鎼滅储鍙傛暟
   */
  private buildSearchParams(request: SearchRequest): Record<string, unknown> {
    const params: Record<string, unknown> = {
      q: request.query.trim(),
      type: request.type,
      sort: request.sort,
      page: request.page,
      pageSize: request.pageSize
    };
    
    // 娣诲姞杩囨护鏉′欢
    if (request.filters) {
      Object.entries(request.filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          params[`filter[${key}]`] = value;
        }
      });
    }
    
    return params;
  }

  /**
   * 鐢熸垚鎼滅储ID锛堢敤浜庣紦瀛橈級
   */
  private generateSearchId(request: SearchRequest): string {
    const filtersString = request.filters ? 
      JSON.stringify(request.filters) : '';
    
    return `search:${request.query.toLowerCase()}:${request.type}:${request.sort}:${request.page}:${request.pageSize}:${filtersString}`;
  }

  /**
   * 鑾峰彇缂撳瓨鐨勬悳绱㈢粨鏋?
   */
  private async getCachedSearchResult(searchId: string): Promise<SearchResult | null> {
    try {
      return await this.cacheService.getCache<SearchResult>(searchId);
    } catch (error) {
      this.logger.warn('Failed to get cached search result', error as Error);
      return null;
    }
  }

  /**
   * 缂撳瓨鎼滅储缁撴灉
   */
  private async cacheSearchResult(searchId: string, result: SearchResult): Promise<void> {
    try {
      await this.cacheService.setCache(
        searchId,
        result,
        {
          type: CacheType.MEMORY,
          expiry: this.searchConfig.resultCacheDuration * 1000
        }
      );
    } catch (error) {
      this.logger.warn('Failed to cache search result', error as Error);
    }
  }

  /**
   * 娣诲姞鍒版悳绱㈠巻鍙?
   */
  private async addToSearchHistory(request: SearchRequest, resultCount: number): Promise<void> {
    try {
      // 鐢熸垚鍘嗗彶璁板綍椤?
      const historyItem: SearchHistoryItem = {
        query: request.query.trim(),
        type: request.type,
        timestamp: Date.now(),
        resultCount
      };
      
      // 鑾峰彇鐜版湁鍘嗗彶
      const history = await this.getSearchHistory();
      
      // 绉婚櫎閲嶅椤癸紙濡傛灉瀛樺湪鐩稿悓鐨勬煡璇㈠拰绫诲瀷锛?
      const filteredHistory = history.filter(
        item => !(item.query.toLowerCase() === historyItem.query.toLowerCase() && item.type === historyItem.type)
      );
      
      // 娣诲姞鏂伴」鍒板紑澶?
      filteredHistory.unshift(historyItem);
      
      // 闄愬埗鍘嗗彶璁板綍鏁伴噺
      const limitedHistory = filteredHistory.slice(0, this.searchConfig.maxHistoryItems);
      
      // 淇濆瓨鍘嗗彶璁板綍
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        limitedHistory,
        LocalStorageType.DEFAULT
      );
      
      // 鍙戝竷鍘嗗彶娣诲姞浜嬩欢
      this.eventBus.emit(SearchEventType.SEARCH_HISTORY_ADDED, historyItem);
    } catch (error) {
      this.logger.warn('Failed to add to search history', error as Error);
    }
  }

  /**
   * 娓呯悊杩囨湡鐨勬悳绱㈠巻鍙?
   */
  private async cleanupExpiredHistory(): Promise<void> {
    try {
      const history = await this.getSearchHistory();
      const expiryTime = Date.now() - (this.searchConfig.historyExpiryDays * 24 * 60 * 60 * 1000);
      
      // 杩囨护鎺夎繃鏈熺殑鍘嗗彶璁板綍
      const validHistory = history.filter(item => item.timestamp > expiryTime);
      
      if (validHistory.length !== history.length) {
        await this.storageUtil.setObject(
          this.storageKeys.searchHistory,
          validHistory,
          LocalStorageType.DEFAULT
        );
        
        this.logger.debug(`Cleaned up ${history.length - validHistory.length} expired search history items`);
      }
    } catch (error) {
      this.logger.warn('Failed to cleanup expired search history', error as Error);
    }
  }

  /**
   * 鐢熸垚鏈湴鎼滅储寤鸿锛堝綋API澶辫触鏃讹級
   */
  private async generateLocalSuggestions(query: string, type?: SearchType): Promise<SearchSuggestion[]> {
    try {
      const history = await this.getSearchHistory(20, type);
      const lowerQuery = query.toLowerCase();
      
      // 浠庡巻鍙茶褰曚腑鍖归厤寤鸿
      const suggestions: SearchSuggestion[] = history
        .filter(item => item.query.toLowerCase().includes(lowerQuery))
        .map(item => ({
          text: item.query,
          type: item.type,
          popularity: 1,
          recent: true
        }));
      
      // 鍘婚噸骞堕檺鍒舵暟閲?
      const uniqueSuggestions = this.deduplicateSuggestions(suggestions).slice(0, 5);
      
      return uniqueSuggestions;
    } catch (error) {
      this.logger.warn('Failed to generate local suggestions', error as Error);
      return [];
    }
  }

  /**
   * 鍘婚噸鎼滅储寤鸿
   */
  private deduplicateSuggestions(suggestions: SearchSuggestion[]): SearchSuggestion[] {
    const seen = new Set<string>();
    return suggestions.filter(suggestion => {
      const key = `${suggestion.text.toLowerCase()}:${suggestion.type}`;
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    });
  }

  /**
   * 璺熻釜鎼滅储琛屼负锛堢敤浜庡垎鏋愶級
   */
  private trackSearch(request: SearchRequest, resultCount: number): void {
    try {
      // 杩欓噷鍙互娣诲姞鎼滅储琛屼负鍒嗘瀽閫昏緫
      // 渚嬪鍙戦€佹悳绱㈢粺璁′俊鎭埌鍒嗘瀽鏈嶅姟
      this.logger.debug(`Tracking search: ${request.query}, results: ${resultCount}`);
    } catch (error) {
      // 鍒嗘瀽澶辫触涓嶅奖鍝嶆悳绱㈠姛鑳?
      this.logger.warn('Failed to track search', error as Error);
    }
  }

  /**
   * 鑾峰彇鎼滅储缁熻淇℃伅
   */
  public async getSearchStatistics(): Promise<{
    totalSearches: number;
    recentSearches: number;
    mostSearchedType: SearchType | null;
    averageResults: number;
  }> {
    try {
      const history = await this.getSearchHistory();
      
      // 璁＄畻缁熻淇℃伅
      const totalSearches = history.length;
      
      // 鏈€杩?澶╃殑鎼滅储
      const weekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
      const recentSearches = history.filter(item => item.timestamp > weekAgo).length;
      
      // 鏈€甯告悳绱㈢殑绫诲瀷
      const typeCount: Record<string, number> = {};
      history.forEach(item => {
        typeCount[item.type] = (typeCount[item.type] || 0) + 1;
      });
      
      let mostSearchedType: SearchType | null = null;
      let maxCount = 0;
      
      Object.entries(typeCount).forEach(([type, count]) => {
        if (count > maxCount) {
          maxCount = count;
          mostSearchedType = type as SearchType;
        }
      });
      
      // 骞冲潎缁撴灉鏁?
      const resultsSum = history.reduce((sum, item) => sum + (item.resultCount || 0), 0);
      const averageResults = history.length > 0 ? resultsSum / history.length : 0;
      
      return {
        totalSearches,
        recentSearches,
        mostSearchedType,
        averageResults
      };
    } catch (error) {
      this.logger.error('Failed to get search statistics', error as Error);
      
      // 杩斿洖榛樿缁熻淇℃伅
      return {
        totalSearches: 0,
        recentSearches: 0,
        mostSearchedType: null,
        averageResults: 0
      };
    }
  }
}

// 瀵煎嚭榛樿瀹炰緥
export default SearchRepository.getInstance();



