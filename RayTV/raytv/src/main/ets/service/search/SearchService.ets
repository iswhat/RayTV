// 搜索服务 | Search service
// 提供全面的搜索功能，包括网站点搜索、高级过滤、历史记录管理、热门搜索等 | Provides comprehensive search functionality, including site search, advanced filtering, history management, hot searches, etc.

import StorageUtil, { StorageType } from '../../common/util/StorageUtil';
import { SiteManager, CallSiteMethodOptions } from '../spider/SiteManager';
import { Vod } from '../../data/bean/Vod';
import { LiveChannel } from '../../data/bean/Live';

import { HttpService, HttpOptions, HttpResponse } from '../HttpService';

import ConfigService from '../config/ConfigService';
import pinyinUtil from '../../common/util/PinyinUtil';
import { VodRepository } from '../../data/repository/VodRepository';
import { SiteInfo } from '../../data/bean/Config';

// 常量定义 | Constants definition
const TAG = 'SearchService';
const MAX_HISTORY_ITEMS = 100;
const MIN_SEARCH_LENGTH = 1;
const HOT_SEARCH_UPDATE_INTERVAL = 3600000; // 1小时 | 1 hour

// 搜索类型枚举 | Search type enum
export enum SearchType {
  ALL = 'all',             // 全部搜索 | All search
  TITLE = 'title',         // 标题搜索 | Title search
  ACTOR = 'actor',         // 演员搜索 | Actor search
  DIRECTOR = 'director',   // 导演搜索 | Director search
  GENRE = 'genre',         // 类型搜索 | Genre search
  TAG = 'tag'              // 标签搜索 | Tag search
}

// 搜索结果类型枚举 | Search result type enum
export enum SearchResultType {
  MOVIE = 'movie',         // 电影 | Movie
  TV_SERIES = 'tv_series', // 电视剧 | TV series
  LIVE = 'live',           // 直播 | Live
  CHANNEL = 'channel',     // 频道 | Channel
  ACTOR = 'actor',         // 演员 | Actor
  DIRECTOR = 'director',   // 导演 | Director
  GENRE = 'genre',         // 类型 | Genre
  TAG = 'tag'              // 标签 | Tag
}

// 站点键值对接口 | Site key-value interface
export interface SiteKeyName {
  key: string;     // 站点键 | Site key
  name: string;    // 站点名称 | Site name
}

// 搜索参数接口 | Search params interface
export interface SearchParams {
  limit: number;    // 搜索限制 | Search limit
}



// 搜索结果摘要接口 | Search result summary interface
export interface SearchResultSummary {
  items: SearchResultItem[];     // 结果项 | Result items
  total: number;                 // 总数量 | Total count
  successSites: number;          // 成功站点数 | Success sites count
  totalSites: number;            // 总站点数 | Total sites count
}

// 搜索过滤选项接口 | Search filter options interface
export interface SearchFilter {
  types?: SearchResultType[]; // 结果类型过滤 | Result type filter
  yearFrom?: number;         // 起始年份 | Start year
  yearTo?: number;           // 结束年份 | End year
  years?: number[];          // 年份过滤（数组形式）| Year filter (array form)
  genres?: string[];         // 类型过滤 | Genre filter
  categories?: string[];     // 分类过滤 | Category filter
  countries?: string[];      // 国家过滤 | Country filter
  regions?: string[];        // 地区过滤 | Region filter
  languages?: string[];      // 语言过滤 | Language filter
  minRating?: number;        // 最低评分 | Minimum rating
  maxDuration?: number;      // 最大时长（分钟）| Maximum duration (minutes)
  sortBy?: 'relevance' | 'date' | 'rating' | 'popularity'; // 排序方式 | Sort method
  sortOrder?: 'asc' | 'desc'; // 排序顺序 | Sort order
}

// 搜索结果高亮接口 | Search result highlight interface
export interface SearchResultHighlight {
  title?: string[];       // 标题高亮位置 | Title highlight positions
  description?: string[]; // 描述高亮位置 | Description highlight positions
}

// 搜索结果元数据接口 | Search result meta data interface
export interface SearchResultMeta {
  viewCount?: number;      // 查看次数 | View count
  extraData?: { [key: string]: string | number | boolean | null | undefined }; // 额外数据 | Extra data
}

// 搜索结果项接口 | Search result item interface
export interface SearchResultItem {
  id: string;               // 结果ID | Result ID
  type: SearchResultType;   // 结果类型 | Result type
  title: string;            // 标题 | Title
  subtitle?: string;        // 副标题 | Subtitle
  description?: string;     // 描述 | Description
  posterUrl?: string;       // 海报URL | Poster URL
  coverUrl?: string;        // 封面URL | Cover URL
  year?: number;            // 年份 | Year
  rating?: number;          // 评分 | Rating
  genre?: string[];         // 类型 | Genre
  country?: string;         // 国家 | Country
  language?: string;        // 语言 | Language
  duration?: number;        // 时长（分钟）| Duration (minutes)
  matchScore?: number;      // 匹配得分 | Match score
  highlight?: SearchResultHighlight; // 高亮信息 | Highlight information
  meta?: SearchResultMeta; // 额外元数据 | Extra meta data
  siteKey?: string;         // 站点Key | Site Key
  siteName?: string;        // 站点名称 | Site name
}

// 搜索响应接口 | Search response interface
export interface SearchResponse {
  query: string;            // 搜索词 | Search query
  total: number;            // 总结果数 | Total result count
  items: SearchResultItem[]; // 结果项列表 | Result items list
  page: number;             // 当前页码 | Current page number
  pageSize: number;         // 每页大小 | Page size
  filters: SearchFilter;    // 应用的过滤条件 | Applied filters
  searchType: SearchType;   // 搜索类型 | Search type
  searchTime: number;       // 搜索耗时（毫秒）| Search time (milliseconds)
  successSites?: number;    // 成功的站点数量 | Successful sites count
  totalSites?: number;      // 总站点数量 | Total sites count
}

// 搜索历史项接口 | Search history item interface
export interface SearchHistoryItem {
  id: string;               // 历史记录ID | History record ID
  keyword: string;          // 搜索词 | Search keyword
  timestamp: number;        // 搜索时间 | Search timestamp
  resultCount: number;      // 结果数量 | Result count
  clickCount: number;       // 点击次数 | Click count
  lastClickTime?: number;   // 最后点击时间 | Last click time
  searchType: SearchType;   // 搜索类型 | Search type
  type?: 'vod' | 'live';    // 兼容字段 | Compatible field
  filters?: SearchFilter;   // 使用的过滤条件 | Used filters
}

// 添加搜索历史参数接口 | Add search history params interface
export interface AddSearchHistoryParams {
  query: string;            // 搜索词 | Search query
  resultCount: number;      // 结果数量 | Result count
  searchType: SearchType;   // 搜索类型 | Search type
  filters?: SearchFilter;   // 使用的过滤条件 | Used filters
  type?: 'vod' | 'live';    // 兼容字段 | Compatible field
}

// 热门搜索项接口 | Hot search item interface
export interface HotSearchItem {
  id: string;               // 热门搜索ID | Hot search ID
  keyword: string;          // 关键词 | Keyword
  rank: number;             // 排名 | Rank
  searchCount: number;      // 搜索次数 | Search count
  trend: 'up' | 'down' | 'stable'; // 趋势 | Trend
  changeCount?: number;     // 变化数量 | Change count
  isNew?: boolean;          // 是否新上榜 | Whether new
  category?: string;        // 分类 | Category
  imageUrl?: string;        // 图片URL | Image URL
  tag?: string;             // 标签 | Tag
}

// 搜索建议项接口 | Search suggestion item interface
export interface SearchSuggestionItem {
  keyword: string;          // 建议关键词 | Suggestion keyword
  type: SearchType;         // 搜索类型 | Search type
  searchCount?: number;     // 搜索次数 | Search count
  isHistory?: boolean;      // 是否为历史记录 | Whether history
  isHot?: boolean;          // 是否为热门搜索 | Whether hot
  highlight?: string[];     // 高亮位置 | Highlight positions
  icon?: string;            // 图标URL | Icon URL
  category?: string;        // 分类 | Category
}

// 搜索配置接口 | Search config interface
export interface SearchConfig {
  enableHistory: boolean;   // 是否启用历史记录 | Whether to enable history
  enableSuggestions: boolean; // 是否启用搜索建议 | Whether to enable suggestions
  enableHotSearches: boolean; // 是否启用热门搜索 | Whether to enable hot searches
  maxHistoryItems: number;  // 最大历史记录数 | Max history items
  minSearchLength: number;  // 最小搜索长度 | Min search length
  autoSearchDelay: number;  // 自动搜索延迟（毫秒）| Auto search delay (milliseconds)
  saveHistoryOnEnter: boolean; // 按Enter时保存历史 | Save history on Enter
  saveHistoryOnClick: boolean; // 点击建议时保存历史 | Save history on click
  highlightResults: boolean; // 是否高亮搜索结果 | Whether to highlight results
  searchInDescription: boolean; // 是否在描述中搜索 | Whether to search in description
  timeout: number;          // 搜索超时时间 | Search timeout
  concurrentSites: number;  // 并发站点数 | Concurrent sites
  maxResultsPerSite: number; // 每个站点最大结果数 | Max results per site
  enableCache: boolean;     // 是否启用缓存 | Whether to enable cache
  cacheExpiry: number;      // 缓存过期时间 | Cache expiry
  siteBlacklist: string[];  // 站点黑名单 | Site blacklist
  sortBy: string;           // 排序字段 | Sort field
  sortOrder: string;        // 排序顺序 | Sort order
  autoScrollToTop: boolean; // 是否自动滚动到顶部 | Whether to auto scroll to top
}

// 默认搜索配置 | Default search config
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

// 搜索监听器类型 | Search listener type
type SearchListener = (response: SearchResponse) => void;

// 搜索建议监听器类型 | Search suggestion listener type
type SuggestionListener = (suggestions: SearchSuggestionItem[]) => void;

// 站点搜索结果接口 | Site search result interface
export interface SiteSearchResult {
  siteKey: string;     // 站点键 | Site key
  siteName: string;    // 站点名称 | Site name
  results: VideoItem[]; // 搜索结果 | Search results
  success: boolean;     // 是否成功 | Whether success
  error?: string;       // 错误信息 | Error message
}

// 搜索选项接口 | Search options interface
export interface SearchOptions {
  query?: string;         // 搜索词 | Search query
  type?: SearchType;       // 搜索类型 | Search type
  page?: number;           // 页码 | Page number
  pageSize?: number;       // 每页大小 | Page size
  filters?: SearchFilter;  // 过滤条件 | Filters
  siteKeys?: string[];     // 站点键列表 | Site keys list
  limitPerSite?: number;   // 每个站点限制 | Limit per site
  timeout?: number;        // 超时时间 | Timeout
}

// 旧版搜索结果项接口 | Legacy search result item interface
export interface LegacySearchResultItem {
  id: string;           // 结果ID | Result ID
  title: string;        // 标题 | Title
  cover: string;        // 封面 | Cover
  rating: number;       // 评分 | Rating
  updateInfo: string;   // 更新信息 | Update info
  tags: string[];       // 标签 | Tags
  category: string;     // 分类 | Category
  siteKey: string;      // 站点键 | Site key
  originalUrl: string;  // 原始URL | Original URL
  isFavorite: boolean;  // 是否收藏 | Whether favorite
  siteName: string;     // 站点名称 | Site name
}

// 旧版搜索结果接口 | Legacy search result interface
export interface SearchResult {
  results: LegacySearchResultItem[]; // 结果列表 | Result list
  total: number;                 // 总数量 | Total count
  successSites: number;          // 成功站点数 | Success sites count
  totalSites: number;            // 总站点数 | Total sites count
}

// 直播搜索结果接口 | Live search result interface
export interface LiveSearchResult {
  channels: LiveChannel[]; // 频道列表 | Channel list
  total: number;         // 总数量 | Total count
  keyword: string;       // 搜索词 | Search keyword
}

// 搜索项接口 | Search item interface
export interface SearchItem {
    id?: string;           // 结果ID | Result ID
    vodId?: string;        // 视频ID | Video ID
    title?: string;        // 标题 | Title
    name?: string;         // 名称 | Name
    cover?: string;        // 封面 | Cover
    img?: string;          // 图片 | Image
    pic?: string;          // 图片 | Picture
    rating?: number;       // 评分 | Rating
    score?: number;        // 分数 | Score
    updateInfo?: string;   // 更新信息 | Update info
    desc?: string;         // 描述 | Description
    tags?: string[];       // 标签 | Tags
    category?: string;     // 分类 | Category
    type?: string;         // 类型 | Type
    url?: string;          // URL
}

// 搜索结果合并返回接口 | Merged search result interface
export interface MergedSearchResult {
  items: SearchResultItem[];     // 结果项 | Result items
  total: number;                 // 总数量 | Total count
  successSites: number;          // 成功站点数 | Success sites count
  totalSites: number;            // 总站点数 | Total sites count
}

// 视频项接口 | Video item interface
export interface VideoItem {
  id: string;           // 视频ID | Video ID
  title: string;        // 标题 | Title
  cover: string;        // 封面 | Cover
  rating: number;       // 评分 | Rating
  updateInfo: string;   // 更新信息 | Update info
  tags: string[];       // 标签 | Tags
  category: string;     // 分类 | Category
  siteKey: string;      // 站点键 | Site key
  originalUrl: string;  // 原始URL | Original URL
  isFavorite: boolean;  // 是否收藏 | Whether favorite
  siteName: string;     // 站点名称 | Site name
}

// 搜索统计信息接口 | Search stats interface
export interface SearchStats {
  totalSearches: number;    // 总搜索次数 | Total searches
  averageResults: number;   // 平均结果数 | Average results
  topSearches: HotSearchItem[]; // 热门搜索 | Top searches
}

// 搜索服务类 | Search service class
export default class SearchService {
  private static instance: SearchService | null = null;
  // 服务实例将在需要时直接调用 | Service instances will be called directly when needed
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

  /**
   * 构造函数 Constructor
   */
  constructor() {
    this.initialize();
  }

  /**
   * 获取单例实例 Get singleton instance
   */
  static getInstance(): SearchService {
    if (!SearchService.instance) {
      SearchService.instance = new SearchService();
    }
    return SearchService.instance;
  }

  /**
   * 初始化搜索服务 Initialize search service
   */
  async initialize(): Promise<void> {
    try {
      console.info('Initializing search service...');

      // 加载配置 Load config
      await this.loadConfig();
      
      // 加载搜索历史 Load search history
      await this.loadSearchHistory();
      
      // 加载热门搜索 Load hot searches
      if (this.config.enableHotSearches) {
        await this.getHotSearches();
      }
      
      this.isInitialized = true;
      console.info('Search service initialized successfully');
    } catch (error) {
      console.error("Failed to initialize search service: " + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 加载搜索配置 Load search config
   */
  private async loadConfig(): Promise<void> {
    try {
      // 使用getString方法获取JSON字符串，然后手动解析
      // Use getString method to get JSON string, then manually parse
      const savedConfigStr = await StorageUtil.getString('search_config');
      const configObject = savedConfigStr ? JSON.parse(savedConfigStr) as Partial<SearchConfig> : {} as Partial<SearchConfig>;
      // 合并默认配置和保存的配置
      // Merge default config and saved config
      const mergedConfig: SearchConfig = {
        enableHistory: configObject.enableHistory ?? DEFAULT_SEARCH_CONFIG.enableHistory,
        enableSuggestions: configObject.enableSuggestions ?? DEFAULT_SEARCH_CONFIG.enableSuggestions,
        enableHotSearches: configObject.enableHotSearches ?? DEFAULT_SEARCH_CONFIG.enableHotSearches,
        maxHistoryItems: configObject.maxHistoryItems || DEFAULT_SEARCH_CONFIG.maxHistoryItems,
        minSearchLength: configObject.minSearchLength || DEFAULT_SEARCH_CONFIG.minSearchLength,
        autoSearchDelay: configObject.autoSearchDelay || DEFAULT_SEARCH_CONFIG.autoSearchDelay,
        saveHistoryOnEnter: configObject.saveHistoryOnEnter ?? DEFAULT_SEARCH_CONFIG.saveHistoryOnEnter,
        saveHistoryOnClick: configObject.saveHistoryOnClick ?? DEFAULT_SEARCH_CONFIG.saveHistoryOnClick,
        highlightResults: configObject.highlightResults ?? DEFAULT_SEARCH_CONFIG.highlightResults,
        searchInDescription: configObject.searchInDescription ?? DEFAULT_SEARCH_CONFIG.searchInDescription,
        timeout: configObject.timeout || DEFAULT_SEARCH_CONFIG.timeout,
        concurrentSites: configObject.concurrentSites || DEFAULT_SEARCH_CONFIG.concurrentSites,
        maxResultsPerSite: configObject.maxResultsPerSite || DEFAULT_SEARCH_CONFIG.maxResultsPerSite,
        enableCache: configObject.enableCache ?? DEFAULT_SEARCH_CONFIG.enableCache,
        cacheExpiry: configObject.cacheExpiry || DEFAULT_SEARCH_CONFIG.cacheExpiry,
        siteBlacklist: configObject.siteBlacklist || DEFAULT_SEARCH_CONFIG.siteBlacklist,
        sortBy: configObject.sortBy || DEFAULT_SEARCH_CONFIG.sortBy,
        sortOrder: configObject.sortOrder || DEFAULT_SEARCH_CONFIG.sortOrder,
        autoScrollToTop: configObject.autoScrollToTop ?? DEFAULT_SEARCH_CONFIG.autoScrollToTop
      };
      this.config = mergedConfig;
    } catch (error) {
      console.error("Failed to load search config: " + (error instanceof Error ? error.message : String(error)));
      this.config = DEFAULT_SEARCH_CONFIG;
    }
  }

  /**
   * 保存搜索配置 Save search config
   */
  private async saveConfig(): Promise<void> {
    try {
      // 将对象转换为JSON字符串后保存
      // Convert object to JSON string and save
      await StorageUtil.putString('search_config', JSON.stringify(this.config));
    } catch (error) {
      console.error(TAG + ": Failed to save search config: " + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 验证搜索关键词，防止注入攻击 Validate search keyword to prevent injection attacks
   */
  private validateSearchKeyword(keyword: string): void {
    if (!keyword) {
      return;
    }
    
    // 防止SQL注入 Prevent SQL injection
    const sqlInjectionPatterns = [
      /\b(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|EXEC)\b/i,
      /\b(OR|AND)\s+1=1\b/i,
      /'OR'1'='1/,
      /"OR"1"="1/
    ];
    
    for (const pattern of sqlInjectionPatterns) {
      if (pattern.test(keyword)) {
        throw new Error('搜索关键词包含非法字符');
      }
    }
    
    // 防止XSS攻击 Prevent XSS attack
    const xssPatterns = [
      /<script[^>]*>.*?<\/script>/gi,
      /<iframe[^>]*>.*?<\/iframe>/gi,
      /javascript:/gi,
      /on\w+\s*=/gi
    ];
    
    for (const pattern of xssPatterns) {
      if (pattern.test(keyword)) {
        throw new Error('搜索关键词包含非法字符');
      }
    }
    
    // 防止命令注入 Prevent command injection
    const commandInjectionPatterns = [
      /;\s*[a-z]+/i,
      /\|\s*[a-z]+/i,
      /\$\(.*?\)/,
      /`.*?`/
    ];
    
    for (const pattern of commandInjectionPatterns) {
      if (pattern.test(keyword)) {
        throw new Error('搜索关键词包含非法字符');
      }
    }
  }
  
  /**
   * 搜索视频（高级搜索，支持多种过滤条件）Search videos (advanced search, supports multiple filters)
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
    
    // 验证搜索条件 Validate search conditions
      if (query.length < this.config.minSearchLength) {
        throw new Error(`搜索关键词至少需要${this.config.minSearchLength}个字符`);
      }
    
    // 验证搜索关键词，防止注入攻击 Validate search keyword to prevent injection attacks
    this.validateSearchKeyword(query);
    
    const startTime = Date.now();
    
    try {
      console.info("执行搜索: query=" + query + ", type=" + type + ", page=" + page + ", filters=" + JSON.stringify(filters));
      


      // 检查缓存 Check cache
      const cacheKey = this.getCacheKey(query, type, filters, siteKeys, limitPerSite);
      if (this.searchCache.has(cacheKey)) {
        const cachedResult = this.searchCache.get(cacheKey)!;
        const historyParams: AddSearchHistoryParams = {
          query: query,
          resultCount: cachedResult.total,
          searchType: type,
          filters: filters
        };
        await this.addToSearchHistory(historyParams);
        this.notifySearchCompleted(cachedResult);
        return cachedResult;
      }

      // 获取可搜索的站点 Get searchable sites
      const searchableSites = await this.getSearchableSites(siteKeys);
      
      // 执行搜索 Execute search
      const searchResults = await this.searchInSites(query, searchableSites, limitPerSite, timeout);
      
      // 合并结果 Merge results
      const mergedResult = this.mergeSearchResults(searchResults, page, pageSize, filters);
      
      // 高亮搜索结果 Highlight search results
      const highlightedResult = this.addHighlightToResults(mergedResult);
      
      // 创建响应对象 Create response object
      const response: SearchResponse = {
        query: query,
        total: highlightedResult.total,
        items: highlightedResult.items,
        page: page,
        pageSize: pageSize,
        filters: filters,
        searchType: type,
        searchTime: Date.now() - startTime,
        successSites: highlightedResult.successSites,
        totalSites: highlightedResult.totalSites
      };
      
      // 缓存结果 Cache result
      this.cacheResult(cacheKey, response);
      
      // 记录搜索历史 Record search history
      const historyParams: AddSearchHistoryParams = {
        query: query,
        resultCount: response.total,
        searchType: type,
        filters: filters
      };
      await this.addToSearchHistory(historyParams);
      
      // 通知搜索完成 Notify search completed
      this.notifySearchCompleted(response);
      
      return response;
    } catch (error) {
      console.error("搜索失败: " + (error instanceof Error ? error.message : String(error)));
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 按类型搜索内容 Search content by type
   */
  public async searchByType(
    query: string, 
    resultTypes: SearchResultType[],
    options?: SearchOptions
  ): Promise<SearchResponse> {
    // 验证搜索关键词，防止注入攻击 Validate search keyword to prevent injection attacks
    this.validateSearchKeyword(query);
    
    // 创建过滤条件，直接使用完整的属性初始化
    // Create filter conditions, directly use complete property initialization
      // 明确初始化所有属性，避免undefined
      // Explicitly initialize all properties, avoid undefined
      const filters: SearchFilter = {
        types: resultTypes || [],
        categories: options?.filters?.categories || [],
        years: options?.filters?.years || [],
        regions: options?.filters?.regions || [],
        languages: options?.filters?.languages || [],
        sortBy: options?.filters?.sortBy || 'relevance',
        sortOrder: options?.filters?.sortOrder || 'desc'
      };
    
    return this.search({
      query: query,
      type: SearchType.ALL,
      filters: filters,
      page: options?.page || 1,
      pageSize: options?.pageSize || 20
    });
  }

  /**
   * 在多个站点中执行搜索 Execute search in multiple sites
   */
  private async searchInSites(keyword: string, sites: SiteKeyName[], limitPerSite: number, timeout: number): Promise<SiteSearchResult[]> {
    const promises: Promise<SiteSearchResult>[] = [];
    
    for (let i = 0; i < sites.length; i++) {
      const site = sites[i];
      const promise = (async (site: SiteKeyName) => {
        try {
          // 创建超时Promise Create timeout Promise
          const timeoutPromise = new Promise<SearchItem[]>((_, reject) => {
            setTimeout(() => reject(new Error('Search timeout')), timeout);
          });
          
          // 创建搜索Promise Create search Promise
          const searchParams: SearchParams = { limit: limitPerSite };
          const callOptions: CallSiteMethodOptions = { timeout };
          // 为数组添加明确的类型声明 Add explicit type declaration for array
          const methodParams: Array<string | SearchParams> = [keyword, searchParams];
          const searchPromise = SiteManager.getInstance().callSiteMethod<SearchItem[]>(
            site.key,
            'search',
            methodParams,
            callOptions
          );
          
          const results = await Promise.race([searchPromise, timeoutPromise]);

          // 转换结果格式 Convert result format
          const videoItems = this.convertToVideoItems(results, site);
          
          const siteResult: SiteSearchResult = {
            siteKey: site.key,
            siteName: site.name,
            results: videoItems,
            success: true
          };
          return siteResult;
        } catch (error) {
          console.warn("在站点 " + site.name + " 搜索失败: " + (error instanceof Error ? error.message : String(error)));
          const siteResult: SiteSearchResult = {
            siteKey: site.key,
            siteName: site.name,
            results: [],
            success: false,
            error: error instanceof Error ? error.message : String(error)
          };
          return siteResult;
        }
      })(site);
      
      promises.push(promise);
    }
    
    // 等待所有搜索完成 Wait for all searches to complete
    return Promise.all(promises);
  }

  /**
   * 转换搜索结果为视频项 Convert search results to video items
   */
  private convertToVideoItems(results: SearchItem[], site: SiteKeyName): VideoItem[] {
    const videoItems: VideoItem[] = [];
    
    for (let i = 0; i < results.length; i++) {
      const result = results[i];
      // 确保必要字段存在 Ensure required fields exist
      if (!result.id && !result.vodId) continue;
      if (!result.title && !result.name) continue;
      
      const videoItem: VideoItem = {
        id: result.id || result.vodId || `temp_${i}`,
        title: result.title || result.name || '',
        cover: result.cover || result.img || result.pic || '',
        rating: result.rating || result.score || 0,
        updateInfo: result.updateInfo || '',
        tags: result.tags || [],
        category: result.category || '',
        siteKey: site.key,
        originalUrl: result.url || '',
        isFavorite: false,
        siteName: site.name
      };
      videoItems.push(videoItem);
    }
    
    return videoItems;
  }

  /**
   * 合并搜索结果 Merge search results
   */
  private mergeSearchResults(results: SiteSearchResult[], page: number, pageSize: number, filters: SearchFilter): MergedSearchResult {
    // 合并所有结果 Merge all results
    let allItems: VideoItem[] = [];
    let successSites = 0;
    
    for (let i = 0; i < results.length; i++) {
      const result = results[i];
      if (result.success) {
        successSites++;
        allItems = allItems.concat(result.results);
      }
    }
    
    // 应用过滤条件 Apply filter conditions
    let filteredItems = allItems;
    
    // 应用分页 Apply pagination
    const startIndex = (page - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const paginatedItems = filteredItems.slice(startIndex, endIndex);
    
    // 转换为SearchResultItem Convert to SearchResultItem
    const searchResultItems: SearchResultItem[] = paginatedItems.map(item => {
      const resultItem: SearchResultItem = {
        id: item.id,
        type: SearchResultType.MOVIE, // 默认类型，实际应该根据item.category或其他字段确定 Default type, should actually be determined by item.category or other fields
        title: item.title,
        coverUrl: item.cover,
        rating: item.rating,
        genre: item.tags,
        siteKey: item.siteKey,
        siteName: item.siteName
      };
      return resultItem;
    });
    
    const mergedResult: MergedSearchResult = {
      items: searchResultItems,
      total: filteredItems.length,
      successSites: successSites,
      totalSites: results.length
    };
    return mergedResult;
  }

  /**
   * 添加高亮到结果 Add highlight to results
   */
  private addHighlightToResults(items: MergedSearchResult): MergedSearchResult {
    // 注意：这里需要知道当前搜索词才能添加高亮
    // 在实际使用时，可以从缓存或参数中获取搜索词
    // Note: Need to know the current search term to add highlight
    // In actual use, can get search term from cache or parameters
    return items;
  }

  /**
   * 获取可搜索的站点 Get searchable sites
   */
  private async getSearchableSites(siteKeys: string[]): Promise<SiteKeyName[]> {
    const allSites = await SiteManager.getInstance().getActiveSites();
    
    if (siteKeys.length > 0) {
      const filteredSites: SiteKeyName[] = [];
      for (let i = 0; i < allSites.length; i++) {
        const site = allSites[i];
        if (siteKeys.includes(site.key)) {
          filteredSites.push({ key: site.key, name: site.name });
        }
      }
      return filteredSites;
    }
    
    // 返回所有活跃站点 Return all active sites
    const searchableSites: SiteKeyName[] = [];
    for (let i = 0; i < allSites.length; i++) {
      const site = allSites[i];
      searchableSites.push({ key: site.key, name: site.name });
    }
    return searchableSites;
  }

  /**
   * 检查数组是否包含指定元素 Check if array includes specified element
   */
  private arrayIncludes<T>(array: T[], value: T): boolean {
    for (let i = 0; i < array.length; i++) {
      if (array[i] === value) {
        return true;
      }
    }
    return false;
  }

  /**
   * 获取热门搜索列表 Get hot search list
   */
  public async getHotSearches(forceUpdate: boolean = false): Promise<HotSearchItem[]> {
    // 确保 hotSearches 已初始化 Ensure hotSearches is initialized
    if (!this.hotSearches) {
      this.hotSearches = [];
    }
    
    // 如果距离上次更新时间不超过1小时，且不是强制更新，则返回缓存
    // If time since last update is less than 1 hour and not forced update, return cache
    if (!forceUpdate && Date.now() - this.lastHotSearchUpdate < HOT_SEARCH_UPDATE_INTERVAL) {
      return this.hotSearches;
    }

    try {
      // 从API获取热门搜索 Get hot searches from API
      const httpService: HttpService = HttpService.getInstance();
      const requestOptions: HttpOptions = { timeout: 5000 };
      const response: HttpResponse<HotSearchItem[]> = await httpService.get<HotSearchItem[]>('/api/hot-searches', requestOptions);

      if (response && response.status === 200 && response.data) {
        this.hotSearches = response.data;
        this.lastHotSearchUpdate = Date.now();
      }
    } catch (error) {
      console.error("Failed to get hot searches: " + (error instanceof Error ? error.message : String(error)));
      // 如果获取失败，使用默认热门搜索 If failed to get, use default hot searches
      this.hotSearches = [
        { id: '1', keyword: '热门电影', rank: 1, searchCount: 1000, trend: 'up' },
        { id: '2', keyword: '最新电视剧', rank: 2, searchCount: 950, trend: 'up' },
        { id: '3', keyword: '动漫', rank: 3, searchCount: 900, trend: 'stable' },
        { id: '4', keyword: '动作', rank: 4, searchCount: 850, trend: 'down' },
        { id: '5', keyword: '科幻', rank: 5, searchCount: 800, trend: 'up' }
      ];
    }

    return this.hotSearches;
  }

  /**
   * 获取搜索建议 Get search suggestions
   * @param keyword 搜索关键词 Search keyword
   * @param limit 建议数量 Suggestion count
   */
  public async getSearchSuggestions(keyword: string, limit: number = 10): Promise<SearchSuggestionItem[]> {
    if (!keyword.trim()) {
      return [];
    }
    
    // 验证搜索关键词，防止注入攻击 Validate search keyword to prevent injection attacks
    this.validateSearchKeyword(keyword);

    try {
      // 从API获取搜索建议 Get search suggestions from API
      const httpService: HttpService = HttpService.getInstance();
      const requestOptions: HttpOptions = { timeout: 5000 };
      const response: HttpResponse<SearchSuggestionItem[]> = await httpService.get<SearchSuggestionItem[]>(`/api/search-suggestions?keyword=${encodeURIComponent(keyword)}&limit=${limit}`, requestOptions);

      if (response.status === 200 && response.data) {
        return response.data;
      }
    } catch (error) {
      console.error("Failed to get search suggestions: " + (error instanceof Error ? error.message : String(error)));
    }

    // 如果API调用失败，返回空数组 If API call fails, return empty array
    return [];
  }

  /**
   * 注册搜索监听器 Register search listener
   */
  public registerSearchListener(listener: SearchListener): void {
    this.searchListeners.push(listener);
  }

  /**
   * 注销搜索监听器 Unregister search listener
   */
  public unregisterSearchListener(listener: SearchListener): void {
    const index = this.searchListeners.indexOf(listener);
    if (index >= 0) {
      this.searchListeners.splice(index, 1);
    }
  }

  /**
   * 注册搜索建议监听器 Register suggestion listener
   */
  public registerSuggestionListener(listener: SuggestionListener): void {
    this.suggestionListeners.push(listener);
  }

  /**
   * 注销搜索建议监听器 Unregister suggestion listener
   */
  public unregisterSuggestionListener(listener: SuggestionListener): void {
    const index = this.suggestionListeners.indexOf(listener);
    if (index >= 0) {
      this.suggestionListeners.splice(index, 1);
    }
  }

  /**
   * 通知搜索完成 Notify search completed
   */
  private notifySearchCompleted(response: SearchResponse): void {
    for (let i = 0; i < this.searchListeners.length; i++) {
      const listener = this.searchListeners[i];
      try {
        listener(response);
      } catch (error) {
        console.error("Failed to notify search listener: " + (error instanceof Error ? error.message : String(error)));
      }
    }
  }

  /**
   * 通知搜索建议更新 Notify suggestions updated
   */
  private notifySuggestionsUpdated(suggestions: SearchSuggestionItem[]): void {
    for (let i = 0; i < this.suggestionListeners.length; i++) {
      const listener = this.suggestionListeners[i];
      try {
        listener(suggestions);
      } catch (error) {
        console.error("Failed to notify suggestion listener: " + (error instanceof Error ? error.message : String(error)));
      }
    }
  }

  /**
   * 获取缓存键 Get cache key
   */
  private getCacheKey(query: string, type: SearchType, filters: SearchFilter, siteKeys: string[], limitPerSite: number): string {
    // 使用传统方式构建缓存键，避免使用模板字符串
    // Use traditional method to build cache key, avoid using template string
    const filtersStr = JSON.stringify(filters || {});
    const siteKeysStr = siteKeys.join(',') || 'all';
    return `${query}_${type}_${filtersStr}_${siteKeysStr}_${limitPerSite}`;
  }

  /**
   * 缓存搜索结果 Cache search result
   */
  private cacheResult(key: string, result: SearchResponse): void {
    // 检查缓存大小，如果超过限制则删除最早的缓存
    // Check cache size, if exceeds limit delete oldest cache
    if (this.searchCache.size >= this.maxCacheSize) {
      // 获取最早的缓存键 Get oldest cache key
      const iterator = this.searchCache.keys();
      const nextResult = iterator.next();
      const oldestKey = nextResult.value as string;
      if (oldestKey && !nextResult.done) {
        this.searchCache.delete(oldestKey);
      }
    }
    // 添加新缓存 Add new cache
    this.searchCache.set(key, result);
  }

  /**
   * 清除搜索缓存 Clear search cache
   */
  public clearSearchCache(): void {
    this.searchCache.clear();
  }

  /**
   * 获取搜索统计信息 Get search stats
   */
  public async getSearchStats(): Promise<SearchStats> {
    // 从API获取搜索统计信息 Get search stats from API
    try {
      const httpService: HttpService = HttpService.getInstance();
      const requestOptions: HttpOptions = { timeout: 5000 };
      const response: HttpResponse<SearchStats> = await httpService.get<SearchStats>('/api/search-stats', requestOptions);

      if (response.status === 200 && response.data) {
        return response.data;
      }
    } catch (error) {
      console.error(`Failed to get search stats: ${error instanceof Error ? error.message : String(error)}`);
    }

    // 返回默认统计信息 Return default stats
    return {
      totalSearches: 0,
      averageResults: 0,
      topSearches: []
    } as SearchStats;
  }

  /**
   * 更新站点信息 Update site info
   */
  public async updateSiteInfo(siteKey: string, siteInfo: SiteInfo): Promise<void> {
    // 这里可以实现站点信息的更新逻辑
    // Here can implement site info update logic
    console.info("更新站点信息: " + siteKey);
  }

  /**
   * 加载搜索历史 Load search history
   */
  private async loadSearchHistory(): Promise<void> {
    try {
      const historyStr = await StorageUtil.getString('search_history');
      if (historyStr) {
        this.searchHistory = JSON.parse(historyStr) as SearchHistoryItem[];
      }
    } catch (error) {
      console.error(TAG + ": Failed to load search history: " + (error instanceof Error ? error.message : String(error)));
      this.searchHistory = [];
    }
  }

  /**
   * 保存搜索历史 Save search history
   */
  private async saveSearchHistory(): Promise<void> {
    try {
      await StorageUtil.putString('search_history', JSON.stringify(this.searchHistory));
    } catch (error) {
      console.error(TAG + ": Failed to save search history: " + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 添加搜索历史项 Add search history item
   */
  private async addToSearchHistory(params: AddSearchHistoryParams): Promise<void> {
    if (!this.config.enableHistory) {
      return;
    }

    try {
      // 检查是否已存在相同查询的历史记录 Check if history item with same query already exists
      const existingIndex = this.searchHistory.findIndex(item => item.keyword === params.query);
      if (existingIndex >= 0) {
          // 更新已存在项的时间戳和结果数 Update timestamp and result count of existing item
          this.searchHistory[existingIndex].timestamp = Date.now();
          this.searchHistory[existingIndex].resultCount = params.resultCount;
          this.searchHistory[existingIndex].searchType = params.searchType;
          if (params.filters) {
            this.searchHistory[existingIndex].filters = params.filters;
          }
          // 将已存在项移动到开头 Move existing item to front of array
          const existingItemArray = this.searchHistory.splice(existingIndex, 1);
          if (existingItemArray.length > 0) {
            const existingItem = existingItemArray[0];
            this.searchHistory.unshift(existingItem);
          }
        } else {
        // 添加新历史项 Add new history item
        const newHistory: SearchHistoryItem = {
          id: `history_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          keyword: params.query,
          timestamp: Date.now(),
          resultCount: params.resultCount,
          clickCount: 0,
          searchType: params.searchType,
          filters: params.filters,
          type: params.type
        };
        this.searchHistory.unshift(newHistory);
      }

      // 保持历史记录数量不超过最大限制 Keep history items within max limit
      if (this.searchHistory.length > this.config.maxHistoryItems) {
        this.searchHistory = this.searchHistory.slice(0, this.config.maxHistoryItems);
      }

      // 保存更新后的历史记录 Save updated history
      await this.saveSearchHistory();
    } catch (error) {
      console.error("Failed to add to search history: " + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 清空搜索历史 Clear search history
   */
  public async clearSearchHistory(): Promise<void> {
    try {
      this.searchHistory = [];
      await this.saveSearchHistory();
    } catch (error) {
      console.error("Failed to clear search history: " + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 删除搜索历史项 Delete search history item
   */
  public async deleteSearchHistory(id: string): Promise<void> {
    try {
      const index = this.searchHistory.findIndex(item => item.id === id);
      if (index >= 0) {
        this.searchHistory.splice(index, 1);
        await this.saveSearchHistory();
      }
    } catch (error) {
      console.error("Failed to delete search history: " + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 获取搜索历史 Get search history
   */
  public getSearchHistory(): SearchHistoryItem[] {
    return this.searchHistory;
  }

  /**
   * 设置搜索配置 Set search configuration
   */
  public async setConfig(config: Partial<SearchConfig>): Promise<void> {
    try {
      // 合并配置 Merge configuration with existing values
      const mergedConfig: SearchConfig = {
        enableHistory: config.enableHistory ?? this.config.enableHistory,
        enableSuggestions: config.enableSuggestions ?? this.config.enableSuggestions,
        enableHotSearches: config.enableHotSearches ?? this.config.enableHotSearches,
        maxHistoryItems: config.maxHistoryItems || this.config.maxHistoryItems,
        minSearchLength: config.minSearchLength || this.config.minSearchLength,
        autoSearchDelay: config.autoSearchDelay || this.config.autoSearchDelay,
        saveHistoryOnEnter: config.saveHistoryOnEnter ?? this.config.saveHistoryOnEnter,
        saveHistoryOnClick: config.saveHistoryOnClick ?? this.config.saveHistoryOnClick,
        highlightResults: config.highlightResults ?? this.config.highlightResults,
        searchInDescription: config.searchInDescription ?? this.config.searchInDescription,
        timeout: config.timeout || this.config.timeout,
        concurrentSites: config.concurrentSites || this.config.concurrentSites,
        maxResultsPerSite: config.maxResultsPerSite || this.config.maxResultsPerSite,
        enableCache: config.enableCache ?? this.config.enableCache,
        cacheExpiry: config.cacheExpiry || this.config.cacheExpiry,
        siteBlacklist: config.siteBlacklist || this.config.siteBlacklist,
        sortBy: config.sortBy || this.config.sortBy,
        sortOrder: config.sortOrder || this.config.sortOrder,
        autoScrollToTop: config.autoScrollToTop ?? this.config.autoScrollToTop
      };
      this.config = mergedConfig;
      await this.saveConfig();
    } catch (error) {
      console.error("Failed to set search config: " + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 获取搜索配置 Get search configuration
   */
  public getConfig(): SearchConfig {
    return this.config;
  }
}



