// 搜索服务
// 提供全面的搜索功能，包括跨站点搜索、高级过滤、历史记录管理、热门搜索等

import { StorageUtil } from '../../common/util/StorageUtil';
import { SiteManager } from '../spider/SiteManager';
import { VideoItem } from '../../data/bean/Vod';
import { LiveChannel } from '../../data/bean/Live';
import { AnalyticsService } from '../analytics/AnalyticsService';
import Logger from '../../common/util/Logger';
import ConfigService from '../config/ConfigService';
import pinyinUtil from '../../common/util/PinyinUtil';
import { VodRepository } from '../../data/repository/VodRepository';

// 常量定义
const TAG = 'SearchService';
const MAX_HISTORY_ITEMS = 100;
const MIN_SEARCH_LENGTH = 1;
const HOT_SEARCH_UPDATE_INTERVAL = 3600000; // 1小时

// 搜索类型枚举
export enum SearchType {
  ALL = 'all',             // 全部搜索
  TITLE = 'title',         // 标题搜索
  ACTOR = 'actor',         // 演员搜索
  DIRECTOR = 'director',   // 导演搜索
  GENRE = 'genre',         // 类型搜索
  TAG = 'tag'              // 标签搜索
}

// 搜索结果类型枚举
export enum SearchResultType {
  MOVIE = 'movie',         // 电影
  TV_SERIES = 'tv_series', // 电视�?  LIVE = 'live',           // 直播
  CHANNEL = 'channel',     // 频道
  ACTOR = 'actor',         // 演员
  DIRECTOR = 'director',   // 导演
  GENRE = 'genre',         // 类型
  TAG = 'tag'              // 标签
}

// 搜索过滤选项接口
export interface SearchFilter {
  types?: SearchResultType[]; // 结果类型过滤
  yearFrom?: number;         // 起始年份
  yearTo?: number;           // 结束年份
  genres?: string[];         // 类型过滤
  countries?: string[];      // 国家过滤
  languages?: string[];      // 语言过滤
  minRating?: number;        // 最低评�?  maxDuration?: number;      // 最大时长（分钟�?  sortBy?: 'relevance' | 'date' | 'rating' | 'popularity'; // 排序方式
  sortOrder?: 'asc' | 'desc'; // 排序顺序
}

// 搜索结果项接�?export interface SearchResultItem {
  id: string;               // 结果ID
  type: SearchResultType;   // 结果类型
  title: string;            // 标题
  subtitle?: string;        // 副标�?  description?: string;     // 描述
  posterUrl?: string;       // 海报URL
  coverUrl?: string;        // 封面URL
  year?: number;            // 年份
  rating?: number;          // 评分
  genre?: string[];         // 类型
  country?: string;         // 国家
  language?: string;        // 语言
  duration?: number;        // 时长（分钟）
  matchScore?: number;      // 匹配得分
  highlight?: {
    title?: string[];       // 标题高亮位置
    description?: string[]; // 描述高亮位置
  };
  meta?: { viewCount?: number; extraData?: Record<string, unknown> }; // 额外元数�?  siteKey?: string;         // 站点�?  siteName?: string;        // 站点名称
}

// 搜索结果接口
export interface SearchResponse {
  query: string;            // 搜索�?  total: number;            // 总结果数
  items: SearchResultItem[]; // 结果项列�?  page: number;             // 当前页码
  pageSize: number;         // 每页大小
  filters: SearchFilter;    // 应用的过滤条�?  searchType: SearchType;   // 搜索类型
  searchTime: number;       // 搜索耗时（毫秒）
  successSites?: number;    // 成功的站点数�?  totalSites?: number;      // 总站点数�?}

// 搜索历史项接�?export interface SearchHistoryItem {
  id: string;               // 历史记录ID
  keyword: string;          // 搜索�?  timestamp: number;        // 搜索时间
  resultCount: number;      // 结果数量
  clickCount: number;       // 点击次数
  lastClickTime?: number;   // 最后点击时�?  searchType: SearchType;   // 搜索类型
  type?: 'vod' | 'live';    // 兼容旧接�?  filters?: SearchFilter;   // 使用的过滤条�?}

// 热门搜索项接�?export interface HotSearchItem {
  id: string;               // 热门搜索ID
  keyword: string;          // 关键�?  rank: number;             // 排名
  searchCount: number;      // 搜索次数
  trend: 'up' | 'down' | 'stable'; // 趋势
  changeCount?: number;     // 变化数量
  isNew?: boolean;          // 是否新上�?  category?: string;        // 分类
  imageUrl?: string;        // 图片URL
  tag?: string;             // 标签
}

// 搜索建议项接�?export interface SearchSuggestionItem {
  text: string;             // 建议文本
  type: 'query' | 'tag' | 'actor' | 'director'; // 建议类型
  count?: number;           // 相关结果数量
  highlight?: boolean;      // 是否高亮显示
  icon?: string;            // 图标
}

// 搜索配置接口
export interface SearchConfig {
  enableHistory: boolean;   // 是否启用历史记录
  enableSuggestions: boolean; // 是否启用搜索建议
  enableHotSearches: boolean; // 是否启用热门搜索
  maxHistoryItems: number;  // 最大历史记录数�?  minSearchLength: number;  // 最小搜索长�?  autoSearchDelay: number;  // 自动搜索延迟（毫秒）
  saveHistoryOnEnter: boolean; // 按Enter时保存历�?  saveHistoryOnClick: boolean; // 点击建议时保存历�?  highlightResults: boolean; // 是否高亮搜索结果
  searchInDescription: boolean; // 是否在描述中搜索
}

// 默认搜索配置
export const DEFAULT_SEARCH_CONFIG: SearchConfig = {
  enableHistory: true,
  enableSuggestions: true,
  enableHotSearches: true,
  maxHistoryItems: MAX_HISTORY_ITEMS,
  minSearchLength: MIN_SEARCH_LENGTH,
  autoSearchDelay: 500,
  saveHistoryOnEnter: true,
  saveHistoryOnClick: true,
  highlightResults: true,
  searchInDescription: true
};

// 搜索监听器回调类�?type SearchListener = (response: SearchResponse) => void;

// 搜索建议监听器回调类�?type SuggestionListener = (suggestions: SearchSuggestionItem[]) => void;

export class SearchService {
  static instance: SearchService;
  storageUtil: StorageUtil;
  siteManager: SiteManager;
  analyticsService: AnalyticsService;
  configService: ConfigService;
  searchHistory: SearchHistoryItem[] = [];
  searchCache: Map<string, SearchResponse> = new Map();
  hotSearches: HotSearchItem[] = [];
  lastHotSearchUpdate: number = 0;
  activeSearches: Map<string, SearchResponse> = new Map();
  searchListeners: SearchListener[] = [];
  suggestionListeners: SuggestionListener[] = [];
  isInitialized: boolean = false;
  debounceTimerId: number | null = null;
  lastSearchQuery: string = '';
  config: SearchConfig = DEFAULT_SEARCH_CONFIG;
  maxHistoryCount = 50;
  maxCacheSize = 20;

  constructor() {
    this.storageUtil = StorageUtil.getInstance();
    this.siteManager = SiteManager.getInstance();
    this.analyticsService = AnalyticsService.getInstance();
    this.configService = ConfigService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): SearchService {
    if (!SearchService.instance) {
      SearchService.instance = new SearchService();
    }
    return SearchService.instance;
  }

  /**
   * 初始化搜索服�?   */
  async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing search service...');

      // 加载配置
      await this.loadConfig();
      
      // 加载搜索历史
      await this.loadSearchHistory();
      
      // 加载热门搜索
      if (this.config.enableHotSearches) {
        await this.loadHotSearches();
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'Search service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize search service: ${error}`);
    }
  }

  /**
   * 搜索视频（高级搜索，支持多种过滤条件�?   */
  async search(options: {
    query: string;
    type?: SearchType;
    page?: number;
    pageSize?: number;
    filters?: SearchFilter;
    siteKeys?: string[];
    limitPerSite?: number;
    timeout?: number;
  }): Promise<SearchResponse> {
    const { 
      query = '', type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength instanceof Error ? type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength : new Error(String(type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {},
      siteKeys = [],
      limitPerSite = 20,
      timeout = 10000
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength))))))) {
      throw new Error(`搜索关键词必须至�?{this.config.minSearchLength}个字符`);
    }
    
    const startTime = Date.now();
    
    try {
      Logger.info(TAG, `执行搜索: query=${query}, type=${type}, page=${page}, filters=${JSON.stringify(filters)}`);
      
      // 记录搜索事件
      this.analyticsService.trackSearch(query);

      // 检查缓�?      const cacheKey = this.getCacheKey(query, type, filters, siteKeys, limitPerSite);
      if (this.searchCache.has(cacheKey)) {
        const cachedResult = this.searchCache.get(cacheKey)!;
        await this.addToSearchHistory({
          query,
          resultCount: cachedResult.total,
          searchType: type,
          filters
        });
        this.notifySearchCompleted(cachedResult);
        return cachedResult;
      }

      // 获取要搜索的站点
      const sites = await this.getSearchableSites(siteKeys);
      
      // 执行跨站点搜�?      const searchResults = await this.searchInSites(query, sites, limitPerSite, timeout);
      
      // 合并和转换结�?      const mergedResults = this.mergeAndTransformSearchResults(searchResults, filters, type);
      
      const searchTime = Date.now() - startTime;
      const response: SearchResponse = {
        query,
        total: mergedResults.total,
        items: mergedResults.items,
        page,
        pageSize,
        filters,
        searchType: type,
        searchTime,
        successSites: mergedResults.successSites,
        totalSites: mergedResults.totalSites
      };
      
      // 保存活跃搜索结果
      this.activeSearches.set(cacheKey, response);
      
      // 通知监听�?      this.notifySearchCompleted(response);
      
      // 保存到搜索历�?      if (this.config.enableHistory && this.config.saveHistoryOnEnter) {
        await this.addToSearchHistory({
          query,
          resultCount: mergedResults.total,
          searchType: type,
          filters
        });
      }
      
      // 缓存结果
      this.cacheResult(cacheKey, response);
      
      // 更新最后搜索记�?      this.lastSearchQuery = query;
      
      return response;
    } catch (error) {
      Logger.error(TAG, `搜索失败: ${error}`);
      throw error;
    }
  }

  /**
   * 兼容旧版搜索接口
   */
  async searchVod(keyword: string, options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions))))))): Promise<SearchResult> {
    try {
      const response = await this.search({
        query: keyword,
        type: SearchType.ALL,
        filters: {},
        ...options
      });
      
      // 转换为旧版结果格�?      return {
        results: response.items.map(item => ({
          id: item.id,
          title: item.title,
          cover: item.coverUrl || item.posterUrl || '',
          rating: item.rating || 0,
          updateInfo: item.description || '',
          tags: item.genre || [],
          category: '',
          siteKey: item.siteKey,
          originalUrl: '',
          isFavorite: false,
          siteName: item.siteName
        })),
        total: response.total,
        successSites: response.successSites || 0,
        totalSites: response.totalSites || 0
      };
    } catch (error) {
      Logger.error(TAG, `VOD搜索失败: ${error}`);
      throw error;
    }
  }

  /**
   * 搜索直播频道
   * @param keyword 搜索关键�?   * @param options 搜索选项
   */
  public async searchLiveChannels(keyword: string, options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions : new Error(String(options?: SearchOptions instanceof Error ? options?: SearchOptions : new Error(String(options?: SearchOptions))))))): Promise<LiveSearchResult> {
    try {
      if (!keyword.trim()) {
        throw new Error('搜索关键词不能为�?);
      }

      // 记录搜索事件
      this.analyticsService.trackSearch(keyword, undefined, 0);

      // 获取所有活跃的直播站点
      const sites = await this.siteManager.getActiveSites();
      const liveSites = sites.filter(site => site.type === 'LIVE' || site.supportedFeatures?.includes('live'));
      
      // 执行搜索
      const results: LiveChannel[] = [];
      
      for (const site of liveSites) {
        try {
          const channelResults = await this.siteManager.callSiteMethod<LiveChannel[]>(
            site.key,
            'searchLiveChannels',
            [keyword],
            { timeout: 5000 }
          );
          
          if (channelResults && Array.isArray(channelResults)) {
            channelResults.forEach(channel => {
              if (channel) {
                channel.siteKey = site.key;
                channel.siteName = site.name;
                results.push(channel);
              }
            });
          }
        } catch (error) {
          Logger.warn(TAG, `在站�?${site.name} 搜索失败:`, error);
        }
      }

      // 保存到历�?      await this.addToSearchHistory({
        query: keyword,
        resultCount: results.length,
        searchType: SearchType.ALL,
        type: 'live',
        filters: { types: [SearchResultType.LIVE, SearchResultType.CHANNEL] }
      });
      
      return {
        channels: results,
        total: results.length,
        keyword
      };
    } catch (error) {
      Logger.error(TAG, `直播频道搜索失败: ${error}`);
      throw error;
    }
  }

  /**
   * 按类型搜索内�?   */
  public async searchByType(
    query: string, resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   instanceof Error ? resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
   : new Error(String(resultTypes: SearchResultType[],
    options?: Partial<{filters: SearchFilter, page: number, pageSize: number}> 
  ))))))): Promise<SearchResponse> {
    const filters: Record<string, string | number | boolean | null> = { ... };
    return this.search({
      query,
      type: SearchType.ALL,
      filters,
      page: options?.page || 1,
      pageSize: options?.pageSize || 20
    });
  }

  /**
   * 在多个站点中执行搜索
   */
  private async searchInSites(keyword: string, sites: Record<string, unknown>[], limitPerSite: number, timeout: number): Promise<SiteSearchResult[]> {
    const promises: Promise<SiteSearchResult>[] = sites.map(async (site) => {
      try {
        const results = await Promise.race([
          this.siteManager.callSiteMethod<Record<string, unknown>[]>(
            site.key,
            'search',
            [keyword, { limit: limitPerSite }],
            { timeout }
          ),
          new Promise((_, reject) => setTimeout(() => reject(new Error('Search timeout')), timeout))
        ]);

        // 转换结果格式
        const videoItems = this.convertToVideoItems(results, site);
        
        return {
          siteKey: site.key,
          siteName: site.name,
          results: videoItems,
          success: true
        };
      } catch (error) {
        Logger.warn(TAG, `在站�?${site.name} 搜索失败:`, error);
        return {
          siteKey: site.key,
          siteName: site.name,
          results: [],
          success: false,
          error: error instanceof Error ? error.message : 'Unknown error'
        };
      }
    });

    return Promise.all(promises);
  }

  /**
   * 搜索项接口定�?   */
  interface SearchItem {
    id?: string;
    vodId?: string;
    title?: string;
    name?: string;
    cover?: string;
    img?: string;
    pic?: string;
    rating?: number;
    score?: number;
    updateInfo?: string;
    desc?: string;
    tags?: string[];
    category?: string;
    type?: string;
    url?: string;
  }

  /**
   * 转换为统一的视频项格式
   */
  private convertToVideoItems(results: SearchItem[], site: { key: string; name: string }): VideoItem[] {
    if (!results || !Array.isArray(results)) {
      return [];
    }
    
    return results.map((item: SearchItem) => ({
      id: item.id || item.vodId || `unknown_${Date.now()}_${Math.random()}`,
      title: item.title || item.name || '未知标题',
      cover: item.cover || item.img || item.pic || '',
      rating: item.rating || item.score || 0,
      updateInfo: item.updateInfo || item.desc || '',
      tags: item.tags || [],
      category: item.category || item.type || '',
      siteKey: site.key,
      originalUrl: item.url || '',
      isFavorite: false
    }));
  }

  /**
   * 合并并转换搜索结�?   */
  private mergeAndTransformSearchResults(siteResults: SiteSearchResult[], filters: SearchFilter, searchType: SearchType): { 
    items: SearchResultItem[], 
    total: number, 
    successSites: number, 
    totalSites: number 
  } {
    let allItems: SearchResultItem[] = [];
    let totalCount = 0;
    let successSites = 0;

    siteResults.forEach(siteResult => {
      if (siteResult.success) {
        successSites++;
        siteResult.results.forEach(item => {
          // 转换为SearchResultItem格式
          const searchItem: SearchResultItem = {
            id: item.id,
            type: this.determineResultType(item.category),
            title: item.title,
            description: item.updateInfo,
            coverUrl: item.cover,
            rating: item.rating,
            genre: item.tags,
            siteKey: item.siteKey,
            siteName: siteResult.siteName,
            matchScore: this.calculateMatchScore(item, searchType)
          };
          
          allItems.push(searchItem);
        });
      }
      totalCount += siteResult.results.length;
    });

    // 应用过滤条件
    allItems = this.applyFilters(allItems, filters);
    
    // 应用排序
    allItems = this.sortResults(allItems, filters);
    
    // 添加高亮
    if (this.config.highlightResults) {
      allItems = this.addHighlightToResults(allItems);
    }

    return {
      items: allItems,
      total: allItems.length,
      successSites,
      totalSites: siteResults.length
    };
  }

  /**
   * 根据分类确定结果类型
   */
  private determineResultType(category: string): SearchResultType {
    const categoryLower = category.toLowerCase();
    if (categoryLower.includes('电影')) return SearchResultType.MOVIE;
    if (categoryLower.includes('电视�?) || categoryLower.includes('剧集')) return SearchResultType.TV_SERIES;
    return SearchResultType.MOVIE; // 默认类型
  }

  /**
   * 计算匹配得分
   */
  private calculateMatchScore(item: VideoItem, searchType: SearchType): number {
    let score = 50; // 基础�?    
    // 根据类型调整分数
    switch (searchType) {
      case SearchType.TITLE:
        score += 30;
        break;
      case SearchType.GENRE:
        if (item.tags && item.tags.length > 0) score += 20;
        break;
      case SearchType.ALL:
      default:
        break;
    }
    
    // 根据评分调整
    if (item.rating > 8) score += 20;
    else if (item.rating > 6) score += 10;
    
    return score;
  }

  /**
   * 应用过滤条件
   */
  private applyFilters(items: SearchResultItem[], filters: SearchFilter): SearchResultItem[] {
    return items.filter(item => {
      // 类型过滤
      if (filters.types && filters.types.length > 0 && !filters.types.includes(item.type)) {
        return false;
      }
      
      // 评分过滤
      if (filters.minRating && (item.rating || 0) < filters.minRating) {
        return false;
      }
      
      // 其他过滤条件可以在这里添�?      
      return true;
    });
  }

  /**
   * 排序结果
   */
  private sortResults(items: SearchResultItem[], filters: SearchFilter): SearchResultItem[] {
    const { sortBy = 'relevance', sortOrder = 'desc' } = filters;
    
    return [...items].sort((a, b) => {
      let comparison = 0;
      
      switch (sortBy) {
        case 'rating':
          comparison = (b.rating || 0) - (a.rating || 0);
          break;
        case 'popularity':
          // 这里可以使用viewCount等指标，如果有的�?          comparison = (b.meta?.viewCount || 0) - (a.meta?.viewCount || 0);
          break;
        case 'relevance':
        default:
          comparison = (b.matchScore || 0) - (a.matchScore || 0);
          break;
      }
      
      return sortOrder === 'asc' ? comparison : -comparison;
    });
  }

  /**
   * 添加高亮到结�?   */
  private addHighlightToResults(items: SearchResultItem[]): SearchResultItem[] {
    // 注意：这里需要知道当前搜索词才能添加高亮
    // 在实际使用时，可以从缓存或参数中获取搜索�?    return items;
  }

  /**
   * 获取可搜索的站点
   */
  private async getSearchableSites(siteKeys: string[]): Promise<{ key: string; supportedFeatures?: string[]; }[]> {
    const allSites = await this.siteManager.getActiveSites();
    
    if (siteKeys.length > 0) {
      return allSites.filter(site => siteKeys.includes(site.key));
    }
    
    // 返回所有支持搜索的站点
    return allSites.filter(site => site.supportedFeatures?.includes('search') || true);
  }

  /**
   * 添加到搜索历史（新版�?   */
  private async addToSearchHistory(data: {
    query: string;
    resultCount: number;
    searchType: SearchType;
    filters?: SearchFilter;
    type?: 'vod' | 'live';
  }): Promise<void> {
    const { query, resultCount, searchType, filters, type = 'vod' } = data;
    
    // 检查是否已存在相同的搜索记�?    const existingIndex = this.searchHistory.findIndex(
      item => item.keyword === query && item.searchType === searchType
    );
    
    const now = Date.now();
    
    if (existingIndex >= 0) {
      // 更新现有记录
      this.searchHistory[existingIndex] = {
        ...this.searchHistory[existingIndex],
        resultCount,
        clickCount: this.searchHistory[existingIndex].clickCount + 1,
        lastClickTime: now,
        timestamp: now,
        filters
      };
      // 移到前面
      const [updatedItem] = this.searchHistory.splice(existingIndex, 1);
      this.searchHistory.unshift(updatedItem);
    } else {
      // 添加新记�?      const historyItem: SearchHistoryItem = {
        id: `history_${now}_${Math.random().toString(36).substr(2, 9)}`,
        keyword: query,
        timestamp: now,
        resultCount,
        clickCount: 1,
        searchType,
        type,
        filters
      };
      this.searchHistory.unshift(historyItem);
    }

    // 限制数量
    const maxItems = Math.max(this.config.maxHistoryItems, this.maxHistoryCount);
    if (this.searchHistory.length > maxItems) {
      this.searchHistory = this.searchHistory.slice(0, maxItems);
    }

    await this.saveSearchHistory();
  }

  /**
   * 获取搜索历史
   */
  public async getSearchHistory(): Promise<SearchHistoryItem[]> {
    await this.loadSearchHistory();
    return [...this.searchHistory];
  }

  /**
   * 清除搜索历史
   */
  public async clearSearchHistory(): Promise<void> {
    this.searchHistory = [];
    await this.saveSearchHistory();
    Logger.info(TAG, '搜索历史已清�?);
  }

  /**
   * 删除指定搜索历史
   */
  public async deleteSearchHistory(keyword: string): Promise<void> {
    this.searchHistory = this.searchHistory.filter(item => item.keyword !== keyword);
    await this.saveSearchHistory();
    Logger.info(TAG, `已删除搜索历史关键词: ${keyword}`);
  }

  /**
   * 通过ID删除搜索历史�?   */
  public async removeSearchHistoryItem(historyId: string): Promise<void> {
    const index = this.searchHistory.findIndex(item => item.id === historyId);
    if (index >= 0) {
      this.searchHistory.splice(index, 1);
      await this.saveSearchHistory();
      Logger.info(TAG, `已删除搜索历史项: ${historyId}`);
    }
  }

  /**
   * 加载搜索历史
   */
  private async loadSearchHistory(): Promise<void> {
    try {
      const history = await this.storageUtil.get<SearchHistoryItem[]>('searchHistory', []);
      // 兼容旧格式，转换为新格式
      this.searchHistory = history.map(item => {
        // 如果是旧格式，转换为新格�?        if (!item.id && 'keyword' in item) {
          return {
            id: `history_${item.timestamp}_${Math.random().toString(36).substr(2, 9)}`,
            keyword: item.keyword,
            timestamp: item.timestamp,
            resultCount: 0,
            clickCount: 1,
            searchType: SearchType.ALL,
            type: item.type || 'vod'
          };
        }
        return item;
      }).filter(item => item);
      
      Logger.info(TAG, `已加�?${this.searchHistory.length} 条搜索历史`);
    } catch (error) {
      Logger.error(TAG, `加载搜索历史失败: ${error}`);
      this.searchHistory = [];
    }
  }

  /**
   * 保存搜索历史
   */
  private async saveSearchHistory(): Promise<void> {
    try {
      await this.storageUtil.save('searchHistory', this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory instanceof Error ? this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory : new Error(String(this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory instanceof Error ? this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory instanceof Error ? this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory : new Error(String(this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory : new Error(String(this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory instanceof Error ? this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory : new Error(String(this.searchHistory instanceof Error ? this.searchHistory : new Error(String(this.searchHistory)))))));
    } catch (error) {
      Logger.error(TAG, `保存搜索历史失败: ${error}`);
    }
  }

  /**
   * 获取最近的搜索
   */
  public getRecentSearches(limit: number = 10): SearchHistoryItem[] {
    return [...this.searchHistory]
      .sort((a, b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b))))))) => b.timestamp - a.timestamp)
      .slice(0, limit);
  }

  /**
   * 获取最常搜�?   */
  public getFrequentSearches(limit: number = 10): SearchHistoryItem[] {
    return [...this.searchHistory]
      .sort((a, b) => b.clickCount - a.clickCount)
      .slice(0, limit);
  }

  /**
   * 获取缓存�?   */
  private getCacheKey(query: string, type: SearchType, filters: SearchFilter, siteKeys: string[], limitPerSite: number): string {
    const siteKeysStr = siteKeys.join(',') || 'all';
    const filtersStr = JSON.stringify(filters);
    return `${query}_${type}_${siteKeysStr}_${limitPerSite}_${filtersStr}`;
  }

  /**
   * 缓存搜索结果
   */
  private cacheResult(key: string, result: SearchResponse): void {
    // 限制缓存大小
    if (this.searchCache.size >= this.maxCacheSize) {
      // 删除最早的缓存
      const firstKey = this.searchCache.keys().next().value;
      this.searchCache.delete(firstKey);
    }
    this.searchCache.set(key, result);
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('searchConfig', DEFAULT_SEARCH_CONFIG);
      if (savedConfig) {
        this.config = { ...DEFAULT_SEARCH_CONFIG, ...savedConfig };
      }
    } catch (error) {
      Logger.error(TAG, `加载搜索配置失败: ${error}`);
    }
  }

  /**
   * 保存配置
   */
  public async saveConfig(config: Partial<SearchConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('searchConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('searchConfig', this.config)))))));
      
      // 如果历史记录数量配置变化，清理超出限制的历史
      if (config.maxHistoryItems && this.searchHistory.length > config.maxHistoryItems) {
        this.searchHistory = this.searchHistory.slice(0, config.maxHistoryItems);
        await this.saveSearchHistory();
      }
    } catch (error) {
      Logger.error(TAG, `保存搜索配置失败: ${error}`);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public getConfig(): SearchConfig {
    return { ...this.config };
  }

  /**
   * 加载热门搜索
   */
  private async loadHotSearches(): Promise<void> {
    try {
      // 检查是否需要更�?      const now = Date.now();
      if (now - this.lastHotSearchUpdate < HOT_SEARCH_UPDATE_INTERVAL && this.hotSearches.length > 0) {
        Logger.info(TAG, '使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�? instanceof Error ? '使用缓存的热门搜�? : new Error(String('使用缓存的热门搜�?)))))));
        return;
      }
      
      // 在实际应用中，这里应该从API获取热门搜索
      // 这里使用模拟数据
      this.hotSearches = this.generateMockHotSearches();
      this.lastHotSearchUpdate = now;
      
      Logger.info(TAG, `已加�?${this.hotSearches.length} 条热门搜索`);
    } catch (error) {
      Logger.error(TAG, `加载热门搜索失败: ${error}`);
    }
  }

  /**
   * 生成模拟热门搜索数据
   */
  private generateMockHotSearches(): HotSearchItem[] {
    const mockData = [
      { keyword: '流浪地球3', rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index instanceof Error ? rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index : new Error(String(rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播�? },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上�? },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬�?, rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺�?, rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联�?', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index))))))) => ({
      id: `hot_${index + 1}`,
      ...item,
      imageUrl: item.rank <= 3 ? `https://example.com/hot${item.rank}.jpg` : undefined
    }));
  }

  /**
   * 获取热门搜索词（兼容旧接口）
   */
  public async getHotSearches(): Promise<string[]> {
    const hotSearchItems = await this.getHotSearchItems();
    return hotSearchItems.map(item => item.keyword);
  }

  /**
   * 获取热门搜索项（新版，返回更详细的信息）
   */
  public async getHotSearchItems(limit: number = 20): Promise<HotSearchItem[]> {
    if (!this.config.enableHotSearches) {
      return [];
    }
    
    // 确保数据是最新的
    await this.loadHotSearches();
    
    return this.hotSearches.slice(0, limit).map(item => ({ ...item }));
  }

  /**
   * 刷新热门搜索
   */
  public async refreshHotSearches(): Promise<HotSearchItem[]> {
    this.lastHotSearchUpdate = 0; // 强制更新
    await this.loadHotSearches();
    return this.hotSearches;
  }

  /**
   * 获取搜索建议（新版，返回更丰富的建议信息�?   */
  public async getSearchSuggestions(query: string, maxResults: number = 10): Promise<SearchSuggestionItem[]> {
    if (!this.config.enableSuggestions || query.length < this.config.minSearchLength) {
      return [];
    }
    
    try {
      Logger.debug(TAG, `获取搜索建议: ${query}`);
      
      const suggestions: SearchSuggestionItem[] = [];
      const lowerQuery = query.toLowerCase();
      
      // 1. 从搜索历史中获取建议
      const historySuggestions = this.searchHistory
        .filter(item => item.keyword.toLowerCase().includes(lowerQuery))
        .map(item => ({
          text: item.keyword,
          type: 'query' as const,
          count: item.resultCount,
          highlight: true
        }));
      
      // 添加到建议列�?      suggestions.push(...historySuggestions);
      
      // 2. 尝试从VodRepository获取建议
      try {
        const vodRepository = VodRepository.getInstance();
        let vodResults = await vodRepository.searchVod(query, undefined, maxResults * 3);
        
        if (vodResults && Array.isArray(vodResults)) {
          // 过滤并转换为建议格式
          const vodSuggestions = vodResults
            .filter(item => item && item.title)
            .map(item => ({
              text: item.title,
              type: 'query' as const,
              count: item.viewCount || 0
            }));
          
          // 合并建议，去�?          const existingTexts = new Set(suggestions.map(s => s.text));
          vodSuggestions.forEach(suggestion => {
            if (!existingTexts.has(suggestion.text)) {
              suggestions.push(suggestion);
              existingTexts.add(suggestion.text);
            }
          });
        }
      } catch (error) {
        Logger.warn(TAG, '从VodRepository获取建议失败:', error);
      }
      
      // 排序和限制数�?      suggestions.sort((a, b) => {
        // 高亮项优�?        if (a.highlight && !b.highlight) return -1;
        if (!a.highlight && b.highlight) return 1;
        // 然后按相关度排序
        return (b.count || 0) - (a.count || 0);
      });
      
      return suggestions.slice(0, maxResults);
    } catch (error) {
      Logger.error(TAG, `获取搜索建议失败: ${error}`);
      return [];
    }
  }

  /**
   * 获取搜索建议（兼容旧接口，只返回字符串数组）
   */
  public async getSearchSuggestionTexts(keyword: string): Promise<string[]> {
    const suggestions = await this.getSearchSuggestions(keyword);
    return suggestions.map(item => item.text);
  }

  /**
   * 通知搜索完成
   */
  private notifySearchCompleted(response: SearchResponse): void {
    for (const listener of this.searchListeners) {
      try {
        listener({ ...response });
      } catch (error) {
        Logger.error(TAG, `搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}` instanceof Error ? `搜索监听器错�? ${error}` : new Error(String(`搜索监听器错�? ${error}`)))))));
      }
    }
  }

  /**
   * 通知建议更新
   */
  private notifySuggestionsUpdated(suggestions: SearchSuggestionItem[]): void {
    for (const listener of this.suggestionListeners) {
      try {
        listener([...suggestions]);
      } catch (error) {
        Logger.error(TAG, `建议监听器错�? ${error}`);
      }
    }
  }

  /**
   * 添加搜索监听�?   */
  public addSearchListener(listener: SearchListener): void {
    this.searchListeners.push(listener);
  }

  /**
   * 移除搜索监听�?   */
  public removeSearchListener(listener: SearchListener): void {
    const index = this.searchListeners.indexOf(listener);
    if (index > -1) {
      this.searchListeners.splice(index, 1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1)))))));
    }
  }

  /**
   * 添加搜索建议监听�?   */
  public addSuggestionListener(listener: SuggestionListener): void {
    this.suggestionListeners.push(listener);
  }

  /**
   * 移除搜索建议监听�?   */
  public removeSuggestionListener(listener: SuggestionListener): void {
    const index = this.suggestionListeners.indexOf(listener);
    if (index > -1) {
      this.suggestionListeners.splice(index, 1);
    }
  }

  /**
   * 获取最后一次搜索查�?   */
  public getLastSearchQuery(): string {
    return this.lastSearchQuery;
  }

  /**
   * 关闭搜索服务
   */
  public async close(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    // 清除定时�?    if (this.debounceTimerId !== null) {
      clearTimeout(this.debounceTimerId);
    }
    
    // 保存数据
    await this.saveSearchHistory();

    this.isInitialized = false;
    Logger.info(TAG, '搜索服务已关�?);
  }
}

/**
 * 搜索选项
 */
export interface SearchOptions {
  siteKeys?: string[];
  limitPerSite?: number;
  timeout?: number;
  type?: 'vod' | 'live';
}

/**
 * 搜索结果
 */
export interface SearchResult {
  results: SearchItem[];
  total: number;
  successSites: number;
  totalSites: number;
}

/**
 * 搜索�? */
export interface SearchItem extends VideoItem {
  siteName?: string;
}

/**
 * 站点搜索结果
 */
export interface SiteSearchResult {
  siteKey: string;
  siteName: string;
  results: VideoItem[];
  success: boolean;
  error?: string;
}

/**
 * 直播搜索结果
 */
export interface LiveSearchResult {
  channels: LiveChannel[];
  total: number;
  keyword?: string;
  category?: string;
}

/**
 * 搜索历史�? */
export interface SearchHistoryItem {
  keyword: string;
  type: 'vod' | 'live';
  timestamp: number;
}


