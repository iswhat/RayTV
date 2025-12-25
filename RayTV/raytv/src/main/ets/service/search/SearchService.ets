// 搜索服务
// 提供全面的搜索功能，包括跨站点搜索、高级过滤、历史记录管理、热门搜索等

import StorageUtil from '../../common/util/StorageUtil';
import { SiteManager } from '../spider/SiteManager';
import { Vod } from '../../data/bean/Vod';
import { LiveChannel } from '../../data/bean/Live';
import { AnalyticsService } from '../analytics/AnalyticsService';
import Logger from '../../common/util/Logger';
import ConfigService from '../config/ConfigService';
import pinyinUtil from '../../common/util/PinyinUtil';
import { VodRepository } from '../../data/repository/VodRepository';
import { SiteInfo } from '../../data/bean/Config';

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
  TV_SERIES = 'tv_series', // 电视剧
  LIVE = 'live',           // 直播
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
  years?: number[];          // 年份过滤（数组形式）
  genres?: string[];         // 类型过滤
  categories?: string[];     // 分类过滤
  countries?: string[];      // 国家过滤
  regions?: string[];        // 地区过滤
  languages?: string[];      // 语言过滤
  minRating?: number;        // 最低评分
  maxDuration?: number;      // 最大时长（分钟）
  sortBy?: 'relevance' | 'date' | 'rating' | 'popularity'; // 排序方式
  sortOrder?: 'asc' | 'desc'; // 排序顺序
}

// 搜索结果高亮接口
export interface SearchResultHighlight {
  title?: string[];       // 标题高亮位置
  description?: string[]; // 描述高亮位置
}

// 搜索结果元数据接口
export interface SearchResultMeta {
  viewCount?: number;      // 查看次数
  extraData?: Record<string, string | number | boolean | object | undefined>; // 额外数据
}

// 搜索结果项接口
export interface SearchResultItem {
  id: string;               // 结果ID
  type: SearchResultType;   // 结果类型
  title: string;            // 标题
  subtitle?: string;        // 副标题
  description?: string;     // 描述
  posterUrl?: string;       // 海报URL
  coverUrl?: string;        // 封面URL
  year?: number;            // 年份
  rating?: number;          // 评分
  genre?: string[];         // 类型
  country?: string;         // 国家
  language?: string;        // 语言
  duration?: number;        // 时长（分钟）
  matchScore?: number;      // 匹配得分
  highlight?: SearchResultHighlight; // 高亮信息
  meta?: SearchResultMeta; // 额外元数据
  siteKey?: string;         // 站点Key
  siteName?: string;        // 站点名称
}

// 搜索结果接口
export interface SearchResponse {
  query: string;            // 搜索词
  total: number;            // 总结果数
  items: SearchResultItem[]; // 结果项列表
  page: number;             // 当前页码
  pageSize: number;         // 每页大小
  filters: SearchFilter;    // 应用的过滤条件
  searchType: SearchType;   // 搜索类型
  searchTime: number;       // 搜索耗时（毫秒）
  successSites?: number;    // 成功的站点数量
  totalSites?: number;      // 总站点数量
}

// 搜索历史项接口
export interface SearchHistoryItem {
  id: string;               // 历史记录ID
  keyword: string;          // 搜索词
  timestamp: number;        // 搜索时间
  resultCount: number;      // 结果数量
  clickCount: number;       // 点击次数
  lastClickTime?: number;   // 最后点击时间
  searchType: SearchType;   // 搜索类型
  type?: 'vod' | 'live';    // 兼容旧接口
  filters?: SearchFilter;   // 使用的过滤条件
}

// 热门搜索项接口
export interface HotSearchItem {
  id: string;               // 热门搜索ID
  keyword: string;          // 关键词
  rank: number;             // 排名
  searchCount: number;      // 搜索次数
  trend: 'up' | 'down' | 'stable'; // 趋势
  changeCount?: number;     // 变化数量
  isNew?: boolean;          // 是否新上线
  category?: string;        // 分类
  imageUrl?: string;        // 图片URL
  tag?: string;             // 标签
}

// 搜索建议项接口
export interface SearchSuggestionItem {
  keyword: string;          // 建议关键词
  type: SearchType;         // 搜索类型
  searchCount?: number;     // 搜索次数
  isHistory?: boolean;      // 是否为历史记录
  isHot?: boolean;          // 是否为热门搜索
  highlight?: string[];     // 高亮位置
  icon?: string;            // 图标URL
  category?: string;        // 分类
}

// 搜索配置接口
export interface SearchConfig {
  enableHistory: boolean;   // 是否启用历史记录
  enableSuggestions: boolean; // 是否启用搜索建议
  enableHotSearches: boolean; // 是否启用热门搜索
  maxHistoryItems: number;  // 最大历史记录数量
  minSearchLength: number;  // 最小搜索长度
  autoSearchDelay: number;  // 自动搜索延迟（毫秒）
  saveHistoryOnEnter: boolean; // 按Enter时保存历史
  saveHistoryOnClick: boolean; // 点击建议时保存历史
  highlightResults: boolean; // 是否高亮搜索结果
  searchInDescription: boolean; // 是否在描述中搜索
  timeout: number;          // 搜索超时时间
  concurrentSites: number;  // 并发站点数量
  maxResultsPerSite: number; // 每个站点最大结果数量
  enableCache: boolean;     // 是否启用缓存
  cacheExpiry: number;      // 缓存过期时间
  siteBlacklist: string[];  // 站点黑名单
  sortBy: string;           // 排序字段
  sortOrder: string;        // 排序顺序
  autoScrollToTop: boolean; // 是否自动滚动到顶部
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
  searchInDescription: true,
  timeout: 10000,
  concurrentSites: 5,
  maxResultsPerSite: 20,
  enableCache: true,
  cacheExpiry: 3600000,
  siteBlacklist: [],
  sortBy: 'relevance',
  sortOrder: 'desc',
  autoScrollToTop: true
};

// 搜索监听器回调类型
type SearchListener = (response: SearchResponse) => void;

// 搜索建议监听器回调类型
type SuggestionListener = (suggestions: SearchSuggestionItem[]) => void;

// 站点搜索结果接口
interface SiteSearchResult {
  siteKey: string;
  siteName: string;
  results: VideoItem[];
  success: boolean;
  error?: string;
}

// 搜索选项接口
interface SearchOptions {
  query?: string;
  type?: SearchType;
  page?: number;
  pageSize?: number;
  filters?: SearchFilter;
  siteKeys?: string[];
  limitPerSite?: number;
  timeout?: number;
}

// 旧版搜索结果接口
interface SearchResult {
  results: {
    id: string;
    title: string;
    cover: string;
    rating: number;
    updateInfo: string;
    tags: string[];
    category: string;
    siteKey: string;
    originalUrl: string;
    isFavorite: boolean;
    siteName: string;
  }[];
  total: number;
  successSites: number;
  totalSites: number;
}

// 直播搜索结果接口
interface LiveSearchResult {
  channels: LiveChannel[];
  total: number;
  keyword: string;
}

// 搜索项接口定义
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

// 视频项接口定义
interface VideoItem {
  id: string;
  title: string;
  cover: string;
  rating: number;
  updateInfo: string;
  tags: string[];
  category: string;
  siteKey: string;
  originalUrl: string;
  isFavorite: boolean;
}

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
   * 初始化搜索服务
   */
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
   * 加载搜索配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await StorageUtil.get('search_config') as Partial<SearchConfig> || {};
      // 合并默认配置和保存的配置
      const mergedConfig: SearchConfig = {
        enableHistory: savedConfig.enableHistory ?? DEFAULT_SEARCH_CONFIG.enableHistory,
        enableSuggestions: savedConfig.enableSuggestions ?? DEFAULT_SEARCH_CONFIG.enableSuggestions,
        enableHotSearches: savedConfig.enableHotSearches ?? DEFAULT_SEARCH_CONFIG.enableHotSearches,
        maxHistoryItems: savedConfig.maxHistoryItems || DEFAULT_SEARCH_CONFIG.maxHistoryItems,
        minSearchLength: savedConfig.minSearchLength || DEFAULT_SEARCH_CONFIG.minSearchLength,
        autoSearchDelay: savedConfig.autoSearchDelay || DEFAULT_SEARCH_CONFIG.autoSearchDelay,
        saveHistoryOnEnter: savedConfig.saveHistoryOnEnter ?? DEFAULT_SEARCH_CONFIG.saveHistoryOnEnter,
        saveHistoryOnClick: savedConfig.saveHistoryOnClick ?? DEFAULT_SEARCH_CONFIG.saveHistoryOnClick,
        highlightResults: savedConfig.highlightResults ?? DEFAULT_SEARCH_CONFIG.highlightResults,
        searchInDescription: savedConfig.searchInDescription ?? DEFAULT_SEARCH_CONFIG.searchInDescription,
        timeout: savedConfig.timeout || DEFAULT_SEARCH_CONFIG.timeout,
        concurrentSites: savedConfig.concurrentSites || DEFAULT_SEARCH_CONFIG.concurrentSites,
        maxResultsPerSite: savedConfig.maxResultsPerSite || DEFAULT_SEARCH_CONFIG.maxResultsPerSite,
        enableCache: savedConfig.enableCache ?? DEFAULT_SEARCH_CONFIG.enableCache,
        cacheExpiry: savedConfig.cacheExpiry || DEFAULT_SEARCH_CONFIG.cacheExpiry,
        siteBlacklist: savedConfig.siteBlacklist || DEFAULT_SEARCH_CONFIG.siteBlacklist,
        sortBy: savedConfig.sortBy || DEFAULT_SEARCH_CONFIG.sortBy,
        sortOrder: savedConfig.sortOrder || DEFAULT_SEARCH_CONFIG.sortOrder,
        autoScrollToTop: savedConfig.autoScrollToTop ?? DEFAULT_SEARCH_CONFIG.autoScrollToTop
      };
      this.config = mergedConfig;
    } catch (error) {
      Logger.error(TAG, `Failed to load search config: ${error}`);
      this.config = DEFAULT_SEARCH_CONFIG;
    }
  }

  /**
   * 保存搜索配置
   */
  private async saveConfig(): Promise<void> {
    try {
      await StorageUtil.set('search_config', this.config);
    } catch (error) {
      Logger.error(TAG, `Failed to save search config: ${error}`);
    }
  }

  /**
   * 搜索视频（高级搜索，支持多种过滤条件）
   */
  async search(options: SearchOptions): Promise<SearchResponse> {
    const query = options.query || '';
    const type = options.type || SearchType.ALL;
    const page = options.page || 1;
    const pageSize = options.pageSize || 20;
    const filters = options.filters || {};
    const siteKeys = options.siteKeys || [];
    const limitPerSite = options.limitPerSite || 20;
    const timeout = options.timeout || 10000;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength) {
      throw new Error(`搜索关键词必须至少${this.config.minSearchLength}个字符`);
    }
    
    const startTime = Date.now();
    
    try {
      Logger.info(TAG, `执行搜索: query=${query}, type=${type}, page=${page}, filters=${JSON.stringify(filters)}`);
      
      // 记录搜索事件
      this.analyticsService.trackSearch(query);

      // 检查缓存
      const cacheKey = this.getCacheKey(query, type, filters, siteKeys, limitPerSite);
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

      // 从真实API获取搜索结果
      const HttpService = (await import('../HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      // 构建API请求URL和参数
      const apiUrl = `/api/search?query=${encodeURIComponent(query)}&type=${type}&page=${page}&pageSize=${pageSize}`;
      
      const response = await httpService.get<SearchResponse>(apiUrl, {
        timeout,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      // 确保响应数据格式正确
      if (response.status !== 200 || !response.data) {
        throw new Error(`API请求失败，状态码: ${response.status}`);
      }
      
      const searchTime = Date.now() - startTime;
      const searchResponse: SearchResponse = {
        query: query,
        total: response.data.total,
        items: response.data.items,
        page: page,
        pageSize: pageSize,
        filters: filters,
        searchType: type,
        searchTime: searchTime,
        successSites: response.data.successSites,
        totalSites: response.data.totalSites
      };
      
      // 保存活跃搜索结果
      this.activeSearches.set(cacheKey, searchResponse);
      
      // 通知监听器
      this.notifySearchCompleted(searchResponse);
      
      // 保存到搜索历史
      if (this.config.enableHistory && this.config.saveHistoryOnEnter) {
        await this.addToSearchHistory({
          query,
          resultCount: searchResponse.total,
          searchType: type,
          filters
        });
      }
      
      // 缓存结果
      this.cacheResult(cacheKey, searchResponse);
      
      // 更新最后搜索记录
      this.lastSearchQuery = query;
      
      return searchResponse;
    } catch (error) {
      Logger.error(TAG, `搜索失败: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 兼容旧版搜索接口
   */
  async searchVod(keyword: string, options?: SearchOptions): Promise<SearchResult> {
    try {
      // 合并搜索选项
      const searchOptions = {
        query: keyword,
        type: SearchType.ALL,
        filters: {},
        page: options?.page,
        pageSize: options?.pageSize,
        siteKeys: options?.siteKeys,
        limitPerSite: options?.limitPerSite,
        timeout: options?.timeout
      };
      
      const response = await this.search(searchOptions);
      
      // 转换为旧版结果格式
      const results: Array<{
        id: string;
        title: string;
        cover: string;
        rating: number;
        updateInfo: string;
        tags: string[];
        category: string;
        siteKey: string;
        originalUrl: string;
        isFavorite: boolean;
        siteName: string;
      }> = [];
      
      for (let i = 0; i < response.items.length; i++) {
        const item = response.items[i];
        results.push({
          id: item.id,
          title: item.title,
          cover: item.coverUrl || item.posterUrl || '',
          rating: item.rating || 0,
          updateInfo: item.description || '',
          tags: item.genre || [],
          category: '',
          siteKey: item.siteKey || '',
          originalUrl: '',
          isFavorite: false,
          siteName: item.siteName || ''
        });
      }
      
      return {
        results: results,
        total: response.total,
        successSites: response.successSites || 0,
        totalSites: response.totalSites || 0
      };
    } catch (error) {
      Logger.error(TAG, `VOD搜索失败: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 搜索直播频道
   * @param keyword 搜索关键词
   * @param options 搜索选项
   */
  public async searchLiveChannels(keyword: string, options?: SearchOptions): Promise<LiveSearchResult> {
    try {
      if (!keyword.trim()) {
        throw new Error('搜索关键词不能为空');
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
          Logger.warn(TAG, `在站点${site.name} 搜索失败: ${error instanceof Error ? error.message : String(error)}`);
        }
      }

      // 保存到历史
      await this.addToSearchHistory({
        query: keyword,
        resultCount: results.length,
        searchType: SearchType.ALL,
        type: 'live',
        filters: { types: [SearchResultType.LIVE, SearchResultType.CHANNEL] }
      });
      
      const result: LiveSearchResult = {
        channels: results,
        total: results.length,
        keyword
      };
      return result;
    } catch (error) {
      Logger.error(TAG, `直播频道搜索失败: ${error}`);
      throw error;
    }
  }

  /**
   * 按类型搜索内容
   */
  public async searchByType(
    query: string, 
    resultTypes: SearchResultType[],
    options?: {
      filters?: SearchFilter;
      page?: number;
      pageSize?: number;
    }
  ): Promise<SearchResponse> {
    const filters: SearchFilter = {
      types: resultTypes,
      categories: options?.filters?.categories || [],
      years: options?.filters?.years || [],
      regions: options?.filters?.regions || [],
      languages: options?.filters?.languages || [],
      sortBy: options?.filters?.sortBy || 'relevance',
      sortOrder: options?.filters?.sortOrder || 'desc'
    };
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
  private async searchInSites(keyword: string, sites: {key: string, name: string, supportedFeatures?: string[]}[], limitPerSite: number, timeout: number): Promise<SiteSearchResult[]> {
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
          Logger.warn(TAG, `在站点${site.name} 搜索失败: ${error instanceof Error ? error.message : String(error)}`);
        }return {
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
   * 转换为统一的视频项格式
   */
  private convertToVideoItems(results: SearchItem[], site: { key: string; name: string }): VideoItem[] {
    if (!results || !Array.isArray(results)) {
      return [];
    }
    
    const videoItems: VideoItem[] = [];
    for (let i = 0; i < results.length; i++) {
      const item = results[i];
      videoItems.push({
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
      });
    }
    
    return videoItems;
  }

  /**
   * 合并并转换搜索结果
   */
  private mergeAndTransformSearchResults(siteResults: SiteSearchResult[], filters: SearchFilter, searchType: SearchType): { 
    items: SearchResultItem[], 
    total: number, 
    successSites: number, 
    totalSites: number 
  } {
    let allItems: SearchResultItem[] = [];
    let totalCount = 0;
    let successSites = 0;

    for (let i = 0; i < siteResults.length; i++) {
      const siteResult = siteResults[i];
      if (siteResult.success) {
        successSites++;
        for (let j = 0; j < siteResult.results.length; j++) {
          const item = siteResult.results[j];
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
        }
      }
      totalCount += siteResult.results.length;
    }

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
    if (categoryLower.includes('电视剧') || categoryLower.includes('剧集')) return SearchResultType.TV_SERIES;
    return SearchResultType.MOVIE; // 默认类型
  }

  /**
   * 计算匹配得分
   */
  private calculateMatchScore(item: VideoItem, searchType: SearchType): number {
    let score = 50; // 基础分
    
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
      
      // 其他过滤条件可以在这里添加
      
      return true;
    });
  }

  /**
   * 排序结果
   */
  private sortResults(items: SearchResultItem[], filters: SearchFilter): SearchResultItem[] {
    // 手动解构，避免使用解构赋值语法
    const sortBy = filters.sortBy || 'relevance';
    const sortOrder = filters.sortOrder || 'desc';
    
    // 使用传统方式复制数组，避免使用扩展运算符
    const itemsCopy: SearchResultItem[] = [];
    for (let i = 0; i < items.length; i++) {
      itemsCopy.push(items[i]);
    }
    
    // 实现自定义排序，避免使用数组的sort方法
    for (let i = 0; i < itemsCopy.length - 1; i++) {
      for (let j = 0; j < itemsCopy.length - i - 1; j++) {
        const a = itemsCopy[j];
        const b = itemsCopy[j + 1];
        let comparison = 0;
        
        switch (sortBy) {
          case 'rating':
            comparison = (b.rating || 0) - (a.rating || 0);
            break;
          case 'popularity':
            // 这里可以使用viewCount等指标，如果有的话
            comparison = (b.meta?.viewCount || 0) - (a.meta?.viewCount || 0);
            break;
          case 'relevance':
          default:
            comparison = (b.matchScore || 0) - (a.matchScore || 0);
            break;
        }
        
        // 根据排序顺序交换元素
        if (sortOrder === 'asc' ? comparison > 0 : comparison < 0) {
          // 交换元素
          const temp = itemsCopy[j];
          itemsCopy[j] = itemsCopy[j + 1];
          itemsCopy[j + 1] = temp;
        }
      }
    }
    
    return itemsCopy;
  }

  /**
   * 添加高亮到结果
   */
  private addHighlightToResults(items: SearchResultItem[]): SearchResultItem[] {
    // 注意：这里需要知道当前搜索词才能添加高亮
    // 在实际使用时，可以从缓存或参数中获取搜索词
    return items;
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
   * 添加到搜索历史（新版本）
   */
  private async addToSearchHistory(data: {
    query: string;
    resultCount: number;
    searchType: SearchType;
    filters?: SearchFilter;
    type?: 'vod' | 'live';
  }): Promise<void> {
    // 手动解构，避免使用解构赋值语法
    const query = data.query;
    const resultCount = data.resultCount;
    const searchType = data.searchType;
    const filters = data.filters;
    const type = data.type || 'vod';
    
    // 检查是否已存在相同的搜索记录
    const existingIndex = this.searchHistory.findIndex(
      item => item.keyword === query && item.searchType === searchType
    );
    
    const now = Date.now();
    
    if (existingIndex >= 0) {
      // 更新现有记录
      const existingItem = this.searchHistory[existingIndex];
      this.searchHistory[existingIndex] = {
        id: existingItem.id,
        keyword: existingItem.keyword,
        timestamp: now,
        resultCount: resultCount,
        clickCount: existingItem.clickCount + 1,
        searchType: existingItem.searchType,
        type: existingItem.type,
        lastClickTime: now,
        filters: filters
      };
      // 移到前面
      const updatedItem = this.searchHistory.splice(existingIndex, 1)[0];
      this.searchHistory.unshift(updatedItem);
    } else {
      // 添加新记录
      const historyItem: SearchHistoryItem = {
        id: `history_${now}_${Math.random().toString(36).substr(2, 9)}`,
        keyword: query,
        timestamp: now,
        resultCount: resultCount,
        clickCount: 1,
        searchType: searchType,
        type: type,
        filters: filters
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
    // 使用传统方式复制数组，避免使用扩展运算符
    const historyCopy: SearchHistoryItem[] = [];
    for (let i = 0; i < this.searchHistory.length; i++) {
      historyCopy.push(this.searchHistory[i]);
    }
    return historyCopy;
  }

  /**
   * 清除搜索历史
   */
  public async clearSearchHistory(): Promise<void> {
    this.searchHistory = [];
    await this.saveSearchHistory();
  }

  /**
   * 删除单个搜索历史
   */
  public async deleteSearchHistoryItem(id: string): Promise<void> {
    const index = this.searchHistory.findIndex(item => item.id === id);
    if (index >= 0) {
      this.searchHistory.splice(index, 1);
      await this.saveSearchHistory();
    }
  }

  /**
   * 加载搜索历史
   */
  private async loadSearchHistory(): Promise<void> {
    try {
      const history = await this.storageUtil.get('search_history') as SearchHistoryItem[] || [];
      // 确保历史记录格式正确
      this.searchHistory = history.filter(item => {
        return item && item.keyword && item.timestamp;
      });
    } catch (error) {
      Logger.error(TAG, `Failed to load search history: ${error}`);
      this.searchHistory = [];
    }
  }

  /**
   * 保存搜索历史
   */
  private async saveSearchHistory(): Promise<void> {
    try {
      await this.storageUtil.set('search_history', this.searchHistory);
    } catch (error) {
      Logger.error(TAG, `Failed to save search history: ${error}`);
    }
  }

  /**
   * 获取热门搜索
   */
  public async getHotSearches(forceUpdate: boolean = false): Promise<HotSearchItem[]> {
    // 如果距离上次更新时间不超过1小时，且不是强制更新，则返回缓存
    if (!forceUpdate && Date.now() - this.lastHotSearchUpdate < HOT_SEARCH_UPDATE_INTERVAL) {
      return this.hotSearches;
    }

    try {
      // 从API获取热门搜索
      const HttpService = (await import('../HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      const response = await httpService.get<HotSearchItem[]>('/api/hot-searches', {
        timeout: 5000
      });

      if (response.status === 200 && response.data) {
        this.hotSearches = response.data;
        this.lastHotSearchUpdate = Date.now();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get hot searches: ${error}`);
      // 如果获取失败，使用默认热门搜索
      this.hotSearches = this.getDefaultHotSearches();
    }

    return this.hotSearches;
  }

  /**
   * 获取默认热门搜索
   */
  private getDefaultHotSearches(): HotSearchItem[] {
    return [
      { id: '1', keyword: '热门电影', rank: 1, searchCount: 1000, trend: 'up' },
      { id: '2', keyword: '最新电视剧', rank: 2, searchCount: 950, trend: 'up' },
      { id: '3', keyword: '综艺', rank: 3, searchCount: 900, trend: 'stable' },
      { id: '4', keyword: '动漫', rank: 4, searchCount: 850, trend: 'down' },
      { id: '5', keyword: '纪录片', rank: 5, searchCount: 800, trend: 'up' }
    ];
  }

  /**
   * 获取搜索建议
   * @param keyword 搜索关键词
   * @param limit 建议数量
   */
  public async getSearchSuggestions(keyword: string, limit: number = 10): Promise<SearchSuggestionItem[]> {
    if (!keyword.trim()) {
      return [];
    }

    try {
      // 从API获取搜索建议
      const HttpService = (await import('../HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      const response = await httpService.get<SearchSuggestionItem[]>(`/api/search-suggestions?keyword=${encodeURIComponent(keyword)}&limit=${limit}`, {
        timeout: 5000
      });

      if (response.status === 200 && response.data) {
        return response.data;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get search suggestions: ${error}`);
    }

    // 如果API调用失败，返回空数组
    return [];
  }

  /**
   * 注册搜索监听器
   */
  public registerSearchListener(listener: SearchListener): void {
    this.searchListeners.push(listener);
  }

  /**
   * 注销搜索监听器
   */
  public unregisterSearchListener(listener: SearchListener): void {
    const index = this.searchListeners.indexOf(listener);
    if (index >= 0) {
      this.searchListeners.splice(index, 1);
    }
  }

  /**
   * 注册搜索建议监听器
   */
  public registerSuggestionListener(listener: SuggestionListener): void {
    this.suggestionListeners.push(listener);
  }

  /**
   * 注销搜索建议监听器
   */
  public unregisterSuggestionListener(listener: SuggestionListener): void {
    const index = this.suggestionListeners.indexOf(listener);
    if (index >= 0) {
      this.suggestionListeners.splice(index, 1);
    }
  }

  /**
   * 通知搜索完成
   */
  private notifySearchCompleted(response: SearchResponse): void {
    for (let i = 0; i < this.searchListeners.length; i++) {
      const listener = this.searchListeners[i];
      try {
        listener(response);
      } catch (error) {
        Logger.error(TAG, `Failed to notify search listener: ${error}`);
      }
    }
  }

  /**
   * 通知搜索建议更新
   */
  private notifySuggestionsUpdated(suggestions: SearchSuggestionItem[]): void {
    for (let i = 0; i < this.suggestionListeners.length; i++) {
      const listener = this.suggestionListeners[i];
      try {
        listener(suggestions);
      } catch (error) {
        Logger.error(TAG, `Failed to notify suggestion listener: ${error}`);
      }
    }
  }

  /**
   * 获取缓存键
   */
  private getCacheKey(query: string, type: SearchType, filters: SearchFilter, siteKeys: string[], limitPerSite: number): string {
    // 使用传统方式构建缓存键，避免使用解构赋值语法
    const filtersStr = JSON.stringify(filters || {});
    const siteKeysStr = siteKeys.join(',') || 'all';
    return `${query}_${type}_${filtersStr}_${siteKeysStr}_${limitPerSite}`;
  }

  /**
   * 缓存搜索结果
   */
  private cacheResult(key: string, result: SearchResponse): void {
    // 检查缓存大小，如果超过限制则删除最早的缓存
    if (this.searchCache.size >= this.maxCacheSize) {
      // 获取最早的缓存键
      const oldestKey = this.searchCache.keys().next().value;
      if (oldestKey) {
        this.searchCache.delete(oldestKey);
      }
    }
    // 添加新缓存
    this.searchCache.set(key, result);
  }

  /**
   * 清除搜索缓存
   */
  public clearSearchCache(): void {
    this.searchCache.clear();
  }

  /**
   * 更新站点信息
   */
  public async updateSiteInfo(siteKey: string, siteInfo: SiteInfo): Promise<void> {
    // 这里可以实现站点信息的更新逻辑
    Logger.info(TAG, `更新站点信息: ${siteKey}`);
  }

  /**
   * 获取搜索统计信息
   */
  public async getSearchStats(): Promise<{
    totalSearches: number;
    averageResults: number;
    topSearches: string[];
  }> {
    // 从API获取搜索统计信息
    try {
      const HttpService = (await import('../HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      const response = await httpService.get<{
        totalSearches: number;
        averageResults: number;
        topSearches: string[];
      }>('/api/search-stats', {
        timeout: 5000
      });

      if (response.status === 200 && response.data) {
        return response.data;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get search stats: ${error}`);
    }

    // 返回默认统计信息
    return {
      totalSearches: 0,
      averageResults: 0,
      topSearches: []
    };
  }
}
