// SearchRepository - 搜索仓库类
// 负责管理搜索相关数据，包括搜索历史、热门搜索、搜索结果缓存等

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import { SearchType, SearchSort, SearchRequest, SearchResult, SearchResultItem } from '../dto/SearchDto';
import { VideoInfo, VideoType } from '../dto/VideoDto';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';

/**
 * 搜索事件类型
 */
export const SearchEventType = {
  SEARCH_PERFORMED: 'search:performed',
  SEARCH_COMPLETED: 'search:completed',
  SEARCH_CACHED: 'search:cached',
  SEARCH_ERROR: 'search:error',
  SEARCH_HISTORY_ADDED: 'search:historyAdded',
  SEARCH_HISTORY_CLEARED: 'search:historyCleared',
  SEARCH_SUGGESTIONS_LOADED: 'search:suggestionsLoaded',
  TRENDING_SEARCHES_LOADED: 'search:trendingLoaded'
} as const;

/**
 * 搜索事件数据
 */
export interface SearchEvent {
  query: string;
  type: SearchType;
  sort: SearchSort;
  timestamp: number;
  results?: SearchResult;
  error?: Error;
}

/**
 * 搜索历史记录项
 */
export interface SearchHistoryItem {
  query: string;
  type: SearchType;
  timestamp: number;
  resultCount?: number;
}

/**
 * 搜索建议项
 */
export interface SearchSuggestion {
  text: string;
  type: SearchType;
  popularity: number;
  recent?: boolean;
}

/**
 * 热门搜索项
 */
export interface TrendingSearch {
  query: string;
  type: SearchType;
  count: number;
  change: number; // 相对于前一周期的变化，正值表示上升，负值表示下降
  period: string; // 统计周期 (day, week, month)
}

/**
 * 搜索仓库类
 */
export class SearchRepository {
  private static instance: SearchRepository;

  /**
   * 获取SearchType枚举的所有有效值（ArkTS兼容方法）
   */
  private getSearchTypeValues(): string[] {
    return [
      SearchType.ALL,
      SearchType.MOVIE,
      SearchType.TV_SERIES,
      SearchType.LIVE,
      SearchType.ANIME,
      SearchType.VARIETY,
      SearchType.DOCUMENTARY,
      SearchType.SPORTS,
      SearchType.MUSIC,
      SearchType.KIDS
    ];
  }

  /**
   * 获取SearchSort枚举的所有有效值（ArkTS兼容方法）
   */
  private getSearchSortValues(): string[] {
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
  
  // API端点配置
  private apiEndpoints = {
    baseUrl: 'https://api.raytv.example.com',
    search: '/search',
    suggestions: '/search/suggestions',
    trending: '/search/trending',
    popular: '/search/popular'
  };
  
  // 存储和缓存键配置
  private storageKeys = {
    searchHistory: 'search:history',
    searchPreferences: 'search:preferences',
    searchResults: 'search:results:',
    trendingSearches: 'search:trending',
    popularSearches: 'search:popular'
  };
  
  // 搜索配置
  private searchConfig = {
    maxHistoryItems: 50, // 最大历史记录数
    historyExpiryDays: 30, // 历史记录过期天数
    resultCacheDuration: 3600, // 搜索结果缓存时间（秒）
    suggestionsCacheDuration: 300, // 搜索建议缓存时间（秒）
    trendingCacheDuration: 3600, // 热门搜索缓存时间（秒）
    minSearchLength: 1, // 最小搜索长度
    debounceTime: 300 // 搜索防抖时间（毫秒）
  };
  
  // 搜索防抖定时器
  private searchDebounceTimer: number | null = null;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('SearchRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取SearchRepository单例实例
   */
  public static getInstance(): SearchRepository {
    if (!SearchRepository.instance) {
      SearchRepository.instance = new SearchRepository();
    }
    return SearchRepository.instance;
  }

  /**
   * 初始化搜索仓库
   */
  private async initialize(): Promise<void> {
    try {
      // 清理过期的搜索历史
      await this.cleanupExpiredHistory();
      
      // 预加载热门搜索（异步）
      this.loadTrendingSearches().catch(err => {
        this.logger.warn('Failed to preload trending searches', err);
      });
      
      this.logger.info('SearchRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize SearchRepository', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用退出事件，确保数据持久化
    this.eventBus.on('app:exit', async () => {
      // 清理过期历史记录
      await this.cleanupExpiredHistory();
    });
    
    // 监听网络状态变化
    this.eventBus.on('network:statusChanged', async (status: { isOnline: boolean }) => {
      if (status.isOnline) {
        // 在线时刷新热门搜索
        await this.loadTrendingSearches();
      }
    });
  }

  /**
   * 执行搜索
   * @param request 搜索请求
   * @param useCache 是否使用缓存
   */
  public async performSearch(request: SearchRequest, useCache: boolean = true): Promise<SearchResult> {
    try {
      // 验证搜索请求
      this.validateSearchRequest(request);
      
      const searchId = this.generateSearchId(request);
      
      // 发布搜索开始事件
      this.eventBus.emit(SearchEventType.SEARCH_PERFORMED, {
        query: request.query,
        type: request.type,
        sort: request.sort,
        timestamp: Date.now()
      } as SearchEvent);
      
      // 尝试从缓存获取结果
      if (useCache) {
        const cachedResult = await this.getCachedSearchResult(searchId);
        if (cachedResult) {
          this.logger.debug(`Search result loaded from cache for: ${request.query}`);
          
          // 发布缓存命中事件
          this.eventBus.emit(SearchEventType.SEARCH_CACHED, {
            query: request.query,
            type: request.type,
            sort: request.sort,
            timestamp: Date.now(),
            results: cachedResult
          } as SearchEvent);
          
          // 更新搜索历史
          this.addToSearchHistory(request, cachedResult.items.length);
          
          return cachedResult;
        }
      }
      
      // 构建搜索参数
      const searchParams = this.buildSearchParams(request);
      
      // 调用API进行搜索
      const response = await this.networkUtil.get<SearchResult>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.search}`,
        {
          params: searchParams
        }
      );
      
      const searchResult = response.data;
      
      // 缓存搜索结果
      await this.cacheSearchResult(searchId, searchResult);
      
      // 更新搜索历史
      this.addToSearchHistory(request, searchResult.items.length);
      
      // 记录用户搜索行为（异步）
      this.trackSearch(request, searchResult.items.length);
      
      // 发布搜索完成事件
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
      
      // 发布搜索错误事件
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
   * 执行防抖搜索
   * @param request 搜索请求
   * @param callback 回调函数
   */
  public debouncedSearch(
    request: SearchRequest,
    callback: (result: SearchResult | null, error?: Error) => void
  ): void {
    // 清除之前的定时器
    if (this.searchDebounceTimer !== null) {
      clearTimeout(this.searchDebounceTimer);
    }
    
    // 设置新的定时器
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
   * 获取搜索建议
   * @param query 搜索查询
   * @param type 搜索类型
   */
  public async getSearchSuggestions(query: string, type?: SearchType): Promise<SearchSuggestion[]> {
    try {
      // 验证查询长度
      if (query.trim().length < this.searchConfig.minSearchLength) {
        return [];
      }
      
      // 生成缓存键
      const cacheKey = `search:suggestions:${query}:${type || 'all'}`;
      
      // 尝试从缓存获取
      const cachedSuggestions = await this.cacheService.getCache<SearchSuggestion[]>(cacheKey);
      if (cachedSuggestions) {
        return cachedSuggestions;
      }
      
      // 构建建议参数
      const params: Record<string, unknown> = {
        q: query.trim(),
        limit: 10
      };
      
      if (type) {
        params.type = type;
      }
      
      // 调用API获取建议
      const response = await this.networkUtil.get<SearchSuggestion[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.suggestions}`,
        {
          params
        }
      );
      
      const suggestions = response.data;
      
      // 获取用户搜索历史，标记最近搜索
      const history = await this.getSearchHistory();
      suggestions.forEach(suggestion => {
        const recent = history.find(h => 
          h.query.toLowerCase() === suggestion.text.toLowerCase() && 
          (!type || h.type === type)
        );
        suggestion.recent = !!recent;
      });
      
      // 缓存建议结果
      await this.cacheService.setCache(
        cacheKey,
        suggestions,
        {
          type: CacheType.MEMORY,
          expiry: this.searchConfig.suggestionsCacheDuration * 1000
        }
      );
      
      // 发布建议加载事件
      this.eventBus.emit(SearchEventType.SEARCH_SUGGESTIONS_LOADED, {
        query,
        type,
        suggestions
      });
      
      return suggestions;
    } catch (error) {
      this.logger.warn('Failed to get search suggestions', error as Error);
      
      // 失败时尝试从本地历史生成建议
      return this.generateLocalSuggestions(query, type);
    }
  }

  /**
   * 获取热门搜索
   */
  public async getTrendingSearches(): Promise<TrendingSearch[]> {
    // 首先尝试从缓存或内存获取
    const cached = await this.cacheService.getCache<TrendingSearch[]>(this.storageKeys.trendingSearches);
    if (cached) {
      return cached;
    }
    
    // 缓存未命中，加载新数据
    return this.loadTrendingSearches();
  }

  /**
   * 加载热门搜索
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
      
      // 缓存热门搜索
      await this.cacheService.setCache(
        this.storageKeys.trendingSearches,
        trendingSearches,
        {
          type: CacheType.MEMORY_DISK,
          expiry: this.searchConfig.trendingCacheDuration * 1000
        }
      );
      
      // 发布热门搜索加载事件
      this.eventBus.emit(SearchEventType.TRENDING_SEARCHES_LOADED, trendingSearches);
      
      return trendingSearches;
    } catch (error) {
      this.logger.warn('Failed to load trending searches', error as Error);
      
      // 尝试从本地存储获取缓存的热门搜索
      return await this.cacheService.getCache<TrendingSearch[]>(this.storageKeys.trendingSearches) || [];
    }
  }

  /**
   * 获取搜索历史
   * @param limit 限制数量
   * @param type 筛选类型
   */
  public async getSearchHistory(limit?: number, type?: SearchType): Promise<SearchHistoryItem[]> {
    try {
      const history = await this.storageUtil.getObject<SearchHistoryItem[]>(
        this.storageKeys.searchHistory,
        LocalStorageType.DEFAULT
      ) || [];
      
      // 筛选类型
      let filtered = history;
      if (type) {
        filtered = history.filter(item => item.type === type);
      }
      
      // 排序（最新的在前）
      filtered.sort((a, b) => b.timestamp - a.timestamp);
      
      // 限制数量
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
   * 清除搜索历史
   * @param type 可选的类型筛选
   */
  public async clearSearchHistory(type?: SearchType): Promise<void> {
    try {
      if (type) {
        // 清除特定类型的历史
        const history = await this.getSearchHistory();
        const filteredHistory = history.filter(item => item.type !== type);
        await this.storageUtil.setObject(
          this.storageKeys.searchHistory,
          filteredHistory,
          LocalStorageType.DEFAULT
        );
      } else {
        // 清除所有历史
        await this.storageUtil.remove(this.storageKeys.searchHistory, LocalStorageType.DEFAULT);
      }
      
      // 发布历史清除事件
      this.eventBus.emit(SearchEventType.SEARCH_HISTORY_CLEARED, { type });
      
      this.logger.info(`Search history cleared${type ? ` for type ${type}` : ''}`);
    } catch (error) {
      this.logger.error('Failed to clear search history', error as Error);
      throw error;
    }
  }

  /**
   * 从搜索历史中移除特定项
   * @param query 搜索查询
   * @param type 搜索类型
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
   * 根据ID获取搜索结果项详情
   * @param id 搜索结果项ID
   * @param type 搜索结果项类型
   */
  public async getSearchResultItemById(id: string, type: SearchType): Promise<SearchResultItem | null> {
    try {
      // 构建缓存键
      const cacheKey = `search:item:${type}:${id}`;
      
      // 尝试从缓存获取
      let item = await this.cacheService.getCache<SearchResultItem>(cacheKey);
      if (item) {
        return item;
      }
      
      // 缓存未命中，根据类型获取详情
      switch (type) {
        case SearchType.VIDEO:
          // 调用视频详情API
          const response = await this.networkUtil.get<VideoInfo>(
            `${this.apiEndpoints.baseUrl}/videos/${id}`
          );
          
          // 转换为搜索结果项格式
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
          // 调用直播详情API
          const liveResponse = await this.networkUtil.get(
            `${this.apiEndpoints.baseUrl}/live/${id}`
          );
          
          // 转换为搜索结果项格式
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
      
      // 缓存结果项
      if (item) {
        await this.cacheService.setCache(
          cacheKey,
          item,
          {
            type: CacheType.MEMORY,
            expiry: 3600 * 1000 // 1小时
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
   * 验证搜索请求
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
   * 构建搜索参数
   */
  private buildSearchParams(request: SearchRequest): any {
    const params: any = {
      q: request.query.trim(),
      type: request.type,
      sort: request.sort,
      page: request.page,
      pageSize: request.pageSize
    };
    
    // 添加过滤条件
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
   * 生成搜索ID（用于缓存）
   */
  private generateSearchId(request: SearchRequest): string {
    const filtersString = request.filters ? 
      JSON.stringify(request.filters) : '';
    
    return `search:${request.query.toLowerCase()}:${request.type}:${request.sort}:${request.page}:${request.pageSize}:${filtersString}`;
  }

  /**
   * 获取缓存的搜索结果
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
   * 缓存搜索结果
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
   * 添加到搜索历史
   */
  private async addToSearchHistory(request: SearchRequest, resultCount: number): Promise<void> {
    try {
      // 生成历史记录项
      const historyItem: SearchHistoryItem = {
        query: request.query.trim(),
        type: request.type,
        timestamp: Date.now(),
        resultCount
      };
      
      // 获取现有历史
      const history = await this.getSearchHistory();
      
      // 移除重复项（如果存在相同的查询和类型）
      const filteredHistory = history.filter(
        item => !(item.query.toLowerCase() === historyItem.query.toLowerCase() && item.type === historyItem.type)
      );
      
      // 添加新项到开头
      filteredHistory.unshift(historyItem);
      
      // 限制历史记录数量
      const limitedHistory = filteredHistory.slice(0, this.searchConfig.maxHistoryItems);
      
      // 保存历史记录
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        limitedHistory,
        LocalStorageType.DEFAULT
      );
      
      // 发布历史添加事件
      this.eventBus.emit(SearchEventType.SEARCH_HISTORY_ADDED, historyItem);
    } catch (error) {
      this.logger.warn('Failed to add to search history', error as Error);
    }
  }

  /**
   * 清理过期的搜索历史
   */
  private async cleanupExpiredHistory(): Promise<void> {
    try {
      const history = await this.getSearchHistory();
      const expiryTime = Date.now() - (this.searchConfig.historyExpiryDays * 24 * 60 * 60 * 1000);
      
      // 过滤掉过期的历史记录
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
   * 生成本地搜索建议（当API失败时）
   */
  private async generateLocalSuggestions(query: string, type?: SearchType): Promise<SearchSuggestion[]> {
    try {
      const history = await this.getSearchHistory(20, type);
      const lowerQuery = query.toLowerCase();
      
      // 从历史记录中匹配建议
      const suggestions: SearchSuggestion[] = history
        .filter(item => item.query.toLowerCase().includes(lowerQuery))
        .map(item => ({
          text: item.query,
          type: item.type,
          popularity: 1,
          recent: true
        }));
      
      // 去重并限制数量
      const uniqueSuggestions = this.deduplicateSuggestions(suggestions).slice(0, 5);
      
      return uniqueSuggestions;
    } catch (error) {
      this.logger.warn('Failed to generate local suggestions', error as Error);
      return [];
    }
  }

  /**
   * 去重搜索建议
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
   * 跟踪搜索行为（用于分析）
   */
  private trackSearch(request: SearchRequest, resultCount: number): void {
    try {
      // 这里可以添加搜索行为分析逻辑
      // 例如发送搜索统计信息到分析服务器
      
      this.logger.debug(`Tracking search: ${request.query}, results: ${resultCount}`);
    } catch (error) {
      // 分析失败不影响搜索功能
      this.logger.warn('Failed to track search', error as Error);
    }
  }

  /**
   * 获取搜索统计信息
   */
  public async getSearchStatistics(): Promise<{
    totalSearches: number;
    recentSearches: number;
    mostSearchedType: SearchType | null;
    averageResults: number;
  }> {
    try {
      const history = await this.getSearchHistory();
      
      // 计算统计信息
      const totalSearches = history.length;
      
      // 最近7天的搜索数
      const weekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
      const recentSearches = history.filter(item => item.timestamp > weekAgo).length;
      
      // 最常搜索的类型
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
      
      // 平均结果数
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
      
      // 返回默认统计信息
      return {
        totalSearches: 0,
        recentSearches: 0,
        mostSearchedType: null,
        averageResults: 0
      };
    }
  }
}

// 导出默认实例
export default SearchRepository.getInstance();