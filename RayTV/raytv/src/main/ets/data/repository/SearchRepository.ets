/**
 * Search Repository - 搜索仓库 (重构版)
 * 
 * 已重构为使用ContentAccessService,不再依赖硬编码的API端点
 * 支持按源筛选和搜索结果
 */

import Logger from '@ohos:raytv/src/main/ets/utils/Logger';
import StorageUtil from '@ohos:raytv/src/main/ets/utils/StorageUtil';
import EventBusUtil from '@ohos:raytv/src/main/ets/utils/EventBusUtil';
import CacheService from '@ohos:raytv/src/main/ets/service/CacheService';
import ContentAccessService from '@ohos:raytv/src/main/ets/service/content/ContentAccessService';
import { VodSiteWithSource, LiveChannelWithSource } from '@ohos:raytv/src/main/ets/service/pool/SourcePoolManager';
import { CacheType } from '@ohos:raytv/src/main/ets/service/CacheService';
import { LocalStorageType } from '@ohos:raytv/src/main/ets/utils/StorageUtil';

/**
 * 搜索类型枚举
 */
export enum SearchType {
  ALL = 'all',
  VOD = 'vod',
  LIVE = 'live',
  USER = 'user',
  CHANNEL = 'channel'
}

/**
 * 搜索排序枚举
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
 * 搜索事件类型常量
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
 * 搜索事件接口
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
 * 搜索请求接口
 */
export interface SearchRequest {
  query: string;
  type: SearchType;
  sort: SearchSort;
  page: number;
  pageSize: number;
  filters?: SearchFilters;
}

/**
 * 搜索过滤器接口
 */
export interface SearchFilters {
  sourceIds?: string[];
  categories?: string[];
  tags?: string[];
  minPriority?: number;
}

/**
 * 搜索结果接口
 */
export interface SearchResult {
  items: SearchResultItem[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

/**
 * 搜索结果项接口
 */
export interface SearchResultItem {
  id: string;
  title: string;
  description?: string;
  type: SearchType;
  thumbnailUrl?: string;
  sourceId?: string;
  sourceName?: string;
  metadata?: Record<string, unknown>;
}

/**
 * 搜索建议接口
 */
export interface SearchSuggestion {
  text: string;
  type: SearchType;
  popularity: number;
  recent?: boolean;
}

/**
 * 热门搜索接口
 */
export interface TrendingSearch {
  query: string;
  type: SearchType;
  count: number;
  trend: 'up' | 'down' | 'stable';
}

/**
 * 搜索历史项接口
 */
export interface SearchHistoryItem {
  query: string;
  type: SearchType;
  timestamp: number;
  resultCount?: number;
}

/**
 * 搜索仓库 (重构版)
 */
export class SearchRepository {
  private static instance: SearchRepository | null = null;
  
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  private contentAccessService: ContentAccessService;
  
  // 存储键配置
  private storageKeys = {
    searchHistory: 'search:history',
    searchPreferences: 'search:preferences',
    searchResults: 'search:results:',
    trendingSearches: 'search:trending',
    popularSearches: 'search:popular'
  };
  
  // 搜索配置
  private searchConfig = {
    maxHistoryItems: 50,
    historyExpiryDays: 30,
    resultCacheDuration: 3600,
    suggestionsCacheDuration: 300,
    trendingCacheDuration: 3600,
    minSearchLength: 1,
    debounceTime: 300
  };
  
  // 搜索防抖定时器
  private searchDebounceTimer: number | null = null;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('SearchRepository initialized (refactored)');
    this.contentAccessService = ContentAccessService.getInstance();
    this.setupEventListeners();
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
   * 初始化
   */
  public async initialize(): Promise<void> {
    try {
      await this.contentAccessService.initialize();
      
      // 清理过期的搜索历史
      await this.cleanupExpiredHistory();
      
      // 预加载热门搜索(异步)
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
    this.eventBus.on('app:exit', async () => {
      await this.cleanupExpiredHistory();
    });
  }

  /**
   * 执行搜索
   */
  public async performSearch(request: SearchRequest, useCache: boolean = true): Promise<SearchResult> {
    try {
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
          
          this.eventBus.emit(SearchEventType.SEARCH_CACHED, {
            query: request.query,
            type: request.type,
            sort: request.sort,
            timestamp: Date.now(),
            results: cachedResult
          } as SearchEvent);
          
          this.addToSearchHistory(request, cachedResult.items.length);
          return cachedResult;
        }
      }
      
      // 执行搜索
      const searchResult = await this.executeSearch(request);
      
      // 缓存搜索结果
      await this.cacheSearchResult(searchId, searchResult);
      
      // 更新搜索历史
      this.addToSearchHistory(request, searchResult.items.length);
      
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
   * 执行搜索 (使用ContentAccessService)
   */
  private async executeSearch(request: SearchRequest): Promise<SearchResult> {
    const items: SearchResultItem[] = [];
    
    // 构建筛选选项
    const filterOptions = request.filters ? {
      sourceIds: request.filters.sourceIds,
      categories: request.filters.categories,
      tags: request.filters.tags,
      minPriority: request.filters.minPriority
    } : undefined;
    
    // 根据搜索类型执行搜索
    switch (request.type) {
      case SearchType.ALL:
      case SearchType.VOD:
        // 搜索点播站点
        const vodSites = this.contentAccessService.searchVodSites(request.query, filterOptions);
        const vodItems = vodSites.map(site => ({
          id: site.siteKey,
          title: site.name,
          description: `优先级: ${site.sourcePriority}`,
          type: SearchType.VOD,
          thumbnailUrl: '',
          sourceId: site.sourceId,
          sourceName: site.sourceName,
          metadata: {
            url: site.url,
            categories: site.categories,
            flags: site.flags,
            tags: site.sourceTags
          }
        } as SearchResultItem));
        items.push(...vodItems);
        
        if (request.type === SearchType.ALL) {
          // 同时搜索直播频道
          const liveChannels = this.contentAccessService.searchLiveChannels(request.query, filterOptions);
          const liveItems = liveChannels.map(channel => ({
            id: channel.id,
            title: channel.name,
            description: `分类: ${channel.group}`,
            type: SearchType.LIVE,
            thumbnailUrl: channel.logo || '',
            sourceId: channel.sourceId,
            sourceName: channel.sourceName,
            metadata: {
              url: channel.url,
              group: channel.group
            }
          } as SearchResultItem));
          items.push(...liveItems);
        }
        break;
        
      case SearchType.LIVE:
        // 搜索直播频道
        const liveChannels = this.contentAccessService.searchLiveChannels(request.query, filterOptions);
        const liveItems = liveChannels.map(channel => ({
          id: channel.id,
          title: channel.name,
          description: `分类: ${channel.group}`,
          type: SearchType.LIVE,
          thumbnailUrl: channel.logo || '',
          sourceId: channel.sourceId,
          sourceName: channel.sourceName,
          metadata: {
            url: channel.url,
            group: channel.group
          }
        } as SearchResultItem));
        items.push(...liveItems);
        break;
        
      default:
        this.logger.warn(`Unsupported search type: ${request.type}`);
    }
    
    // 应用排序
    const sortedItems = this.applySort(items, request.sort);
    
    // 应用分页
    const startIndex = (request.page - 1) * request.pageSize;
    const endIndex = startIndex + request.pageSize;
    const pagedItems = sortedItems.slice(startIndex, endIndex);
    
    return {
      items: pagedItems,
      total: sortedItems.length,
      page: request.page,
      pageSize: request.pageSize,
      hasMore: endIndex < sortedItems.length
    };
  }
  
  /**
   * 应用排序
   */
  private applySort(items: SearchResultItem[], sort: SearchSort): SearchResultItem[] {
    switch (sort) {
      case SearchSort.DEFAULT:
        return items;
      case SearchSort.LATEST:
        return items.sort((a, b) => b.id.localeCompare(a.id));
      case SearchSort.HOTTEST:
        return items.sort((a, b) => (b.title.length - a.title.length));
      default:
        return items;
    }
  }

  /**
   * 获取搜索建议
   */
  public async getSearchSuggestions(query: string, type?: SearchType): Promise<SearchSuggestion[]> {
    try {
      if (query.trim().length < this.searchConfig.minSearchLength) {
        return [];
      }
      
      const cacheKey = `search:suggestions:${query}:${type || 'all'}`;
      
      // 尝试从缓存获取
      const cachedSuggestions = await this.cacheService.getCache<SearchSuggestion[]>(cacheKey);
      if (cachedSuggestions) {
        return cachedSuggestions;
      }
      
      // 从本地历史生成建议
      const suggestions = await this.generateLocalSuggestions(query, type);
      
      // 缓存建议结果
      await this.cacheService.setCache(
        cacheKey,
        suggestions,
        {
          type: CacheType.MEMORY,
          expiry: this.searchConfig.suggestionsCacheDuration * 1000
        }
      );
      
      return suggestions;
    } catch (error) {
      this.logger.warn('Failed to get search suggestions', error as Error);
      return [];
    }
  }

  /**
   * 获取热门搜索
   */
  public async getTrendingSearches(): Promise<TrendingSearch[]> {
    const cached = await this.cacheService.getCache<TrendingSearch[]>(this.storageKeys.trendingSearches);
    if (cached) {
      return cached;
    }
    
    return this.loadTrendingSearches();
  }

  /**
   * 加载热门搜索
   */
  private async loadTrendingSearches(): Promise<TrendingSearch[]> {
    try {
      // 从搜索历史生成热门搜索
      const history = await this.getSearchHistory();
      const queryCount = new Map<string, number>();
      
      history.forEach(item => {
        const count = queryCount.get(item.query) || 0;
        queryCount.set(item.query, count + 1);
      });
      
      const trendingSearches: TrendingSearch[] = Array.from(queryCount.entries())
        .slice(0, 15)
        .map(([query, count], index) => ({
          query,
          type: SearchType.ALL,
          count,
          trend: index < 3 ? 'up' : 'stable'
        }));
      
      await this.cacheService.setCache(
        this.storageKeys.trendingSearches,
        trendingSearches,
        {
          type: CacheType.MEMORY_DISK,
          expiry: this.searchConfig.trendingCacheDuration * 1000
        }
      );
      
      return trendingSearches;
    } catch (error) {
      this.logger.warn('Failed to load trending searches', error as Error);
      return [];
    }
  }

  /**
   * 获取搜索历史
   */
  public async getSearchHistory(limit?: number, type?: SearchType): Promise<SearchHistoryItem[]> {
    try {
      const history = await this.storageUtil.getObject<SearchHistoryItem[]>(
        this.storageKeys.searchHistory,
        LocalStorageType.DEFAULT
      ) || [];
      
      let filtered = history;
      if (type) {
        filtered = history.filter(item => item.type === type);
      }
      
      filtered.sort((a, b) => b.timestamp - a.timestamp);
      
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
   */
  public async clearSearchHistory(type?: SearchType): Promise<void> {
    try {
      if (type) {
        const history = await this.getSearchHistory();
        const filteredHistory = history.filter(item => item.type !== type);
        await this.storageUtil.setObject(
          this.storageKeys.searchHistory,
          filteredHistory,
          LocalStorageType.DEFAULT
        );
      } else {
        await this.storageUtil.remove(this.storageKeys.searchHistory, LocalStorageType.DEFAULT);
      }
      
      this.eventBus.emit(SearchEventType.SEARCH_HISTORY_CLEARED, { type });
      this.logger.info(`Search history cleared${type ? ` for type ${type}` : ''}`);
    } catch (error) {
      this.logger.error('Failed to clear search history', error as Error);
      throw error;
    }
  }

  /**
   * 生成搜索ID (用于缓存)
   */
  private generateSearchId(request: SearchRequest): string {
    const filtersString = request.filters ? JSON.stringify(request.filters) : '';
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
      const historyItem: SearchHistoryItem = {
        query: request.query.trim(),
        type: request.type,
        timestamp: Date.now(),
        resultCount
      };
      
      const history = await this.getSearchHistory();
      
      const filteredHistory = history.filter(
        item => !(item.query.toLowerCase() === historyItem.query.toLowerCase() && item.type === historyItem.type)
      );
      
      filteredHistory.unshift(historyItem);
      
      const limitedHistory = filteredHistory.slice(0, this.searchConfig.maxHistoryItems);
      
      await this.storageUtil.setObject(
        this.storageKeys.searchHistory,
        limitedHistory,
        LocalStorageType.DEFAULT
      );
      
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
   * 生成本地搜索建议
   */
  private async generateLocalSuggestions(query: string, type?: SearchType): Promise<SearchSuggestion[]> {
    try {
      const history = await this.getSearchHistory(20, type);
      const lowerQuery = query.toLowerCase();
      
      const suggestions: SearchSuggestion[] = history
        .filter(item => item.query.toLowerCase().includes(lowerQuery))
        .map(item => ({
          text: item.query,
          type: item.type,
          popularity: 1,
          recent: true
        }));
      
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
      
      const totalSearches = history.length;
      const weekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
      const recentSearches = history.filter(item => item.timestamp > weekAgo).length;
      
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
