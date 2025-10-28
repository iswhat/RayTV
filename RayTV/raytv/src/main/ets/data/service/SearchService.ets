// SearchService.ets - 搜索服务
// 负责视频内容搜索、历史记录管理和热门推荐功能

import Logger from '../../common/util/Logger';
import ConfigService from '../../service/config/ConfigService';
import pinyinUtil from '../../common/util/PinyinUtil';
import VodRepository from '../repository/VodRepository';

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
  genres?: string[];         // 类型过滤
  countries?: string[];      // 国家过滤
  languages?: string[];      // 语言过滤
  minRating?: number;        // 最低评分
  maxDuration?: number;      // 最大时长（分钟）
  sortBy?: 'relevance' | 'date' | 'rating' | 'popularity'; // 排序方式
  sortOrder?: 'asc' | 'desc'; // 排序顺序
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
  highlight?: {
    title?: string[];       // 标题高亮位置
    description?: string[]; // 描述高亮位置
  };
  meta?: Record<string, any>; // 额外元数据
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
}

// 搜索历史项接口
export interface SearchHistoryItem {
  id: string;               // 历史记录ID
  query: string;            // 搜索词
  timestamp: number;        // 搜索时间
  resultCount: number;      // 结果数量
  clickCount: number;       // 点击次数
  lastClickTime?: number;   // 最后点击时间
  searchType: SearchType;   // 搜索类型
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
  isNew?: boolean;          // 是否新上榜
  category?: string;        // 分类
  imageUrl?: string;        // 图片URL
  tag?: string;             // 标签
}

// 搜索建议项接口
export interface SearchSuggestionItem {
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
  maxHistoryItems: number;  // 最大历史记录数量
  minSearchLength: number;  // 最小搜索长度
  autoSearchDelay: number;  // 自动搜索延迟（毫秒）
  saveHistoryOnEnter: boolean; // 按Enter时保存历史
  saveHistoryOnClick: boolean; // 点击建议时保存历史
  highlightResults: boolean; // 是否高亮搜索结果
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

// 搜索监听器回调类型
type SearchListener = (response: SearchResponse) => void;

// 搜索建议监听器回调类型
type SuggestionListener = (suggestions: SearchSuggestionItem[]) => void;

export default class SearchService {
  private static instance: SearchService;
  private configService: ConfigService;
  private config: SearchConfig = DEFAULT_SEARCH_CONFIG;
  private searchHistory: SearchHistoryItem[] = [];
  private hotSearches: HotSearchItem[] = [];
  private lastHotSearchUpdate: number = 0;
  private activeSearches: Map<string, SearchResponse> = new Map();
  private searchListeners: SearchListener[] = [];
  private suggestionListeners: SuggestionListener[] = [];
  private isInitialized: boolean = false;
  private debounceTimerId: number | null = null;
  private lastSearchQuery: string = '';

  /**
   * 获取单例实例
   */
  public static getInstance(): SearchService {
    if (!SearchService.instance) {
      SearchService.instance = new SearchService();
    }
    return SearchService.instance;
  }

  /**
   * 构造函数
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
  }

  /**
   * 初始化搜索服务
   * @param context 应用上下文
   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Search service already initialized');
      return;
    }

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
      Logger.info(TAG, `Config: ${JSON.stringify(this.config)}`);
    } catch (error) {
      Logger.error(TAG, `Failed to initialize search service: ${JSON.stringify(error)}`);
      throw error;
    }
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
      Logger.error(TAG, `Failed to load search config: ${error}`);
    }
  }

  /**
   * 保存配置
   */
  public async saveConfig(config: Partial<SearchConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('searchConfig', this.config);
      
      // 如果历史记录数量配置变化，清理超出限制的历史
      if (config.maxHistoryItems && this.searchHistory.length > config.maxHistoryItems) {
        this.searchHistory = this.searchHistory.slice(0, config.maxHistoryItems);
        await this.saveSearchHistory();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save search config: ${error}`);
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
   * 加载搜索历史
   */
  private async loadSearchHistory(): Promise<void> {
    try {
      const history = await this.configService.getConfig<SearchHistoryItem[]>('searchHistory', []);
      this.searchHistory = history.filter(item => item); // 过滤无效项
      Logger.info(TAG, `Loaded ${this.searchHistory.length} search history items`);
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
      // 确保不超过最大限制
      if (this.searchHistory.length > this.config.maxHistoryItems) {
        this.searchHistory = this.searchHistory.slice(0, this.config.maxHistoryItems);
      }
      
      await this.configService.setConfig('searchHistory', this.searchHistory);
    } catch (error) {
      Logger.error(TAG, `Failed to save search history: ${error}`);
    }
  }

  /**
   * 加载热门搜索
   */
  private async loadHotSearches(): Promise<void> {
    try {
      // 检查是否需要更新
      const now = Date.now();
      if (now - this.lastHotSearchUpdate < HOT_SEARCH_UPDATE_INTERVAL && this.hotSearches.length > 0) {
        Logger.info(TAG, 'Using cached hot searches');
        return;
      }
      
      // 在实际应用中，这里应该从API获取热门搜索
      // 这里使用模拟数据
      this.hotSearches = this.generateMockHotSearches();
      this.lastHotSearchUpdate = now;
      
      Logger.info(TAG, `Loaded ${this.hotSearches.length} hot search items`);
    } catch (error) {
      Logger.error(TAG, `Failed to load hot searches: ${error}`);
    }
  }

  /**
   * 生成模拟热门搜索数据
   */
  private generateMockHotSearches(): HotSearchItem[] {
    const mockData = [
      { keyword: '流浪地球3', rank: 1, searchCount: 1234567, trend: 'up', changeCount: 1567 },
      { keyword: '繁花', rank: 2, searchCount: 987654, trend: 'stable', tag: '热播剧' },
      { keyword: '功夫熊猫4', rank: 3, searchCount: 876543, trend: 'up', changeCount: 2345, tag: '新上映' },
      { keyword: '沙丘2', rank: 4, searchCount: 765432, trend: 'down', changeCount: 123 },
      { keyword: '周冬雨', rank: 5, searchCount: 654321, trend: 'up', changeCount: 456, isNew: true },
      { keyword: '张艺谋', rank: 6, searchCount: 543210, trend: 'stable' },
      { keyword: '狂飙', rank: 7, searchCount: 432109, trend: 'down', changeCount: 567 },
      { keyword: '复仇者联盟5', rank: 8, searchCount: 321098, trend: 'up', changeCount: 789, tag: '预告' },
      { keyword: '动画电影', rank: 9, searchCount: 210987, trend: 'stable', category: '类型' },
      { keyword: '红海行动2', rank: 10, searchCount: 109876, trend: 'up', changeCount: 345, isNew: true }
    ];
    
    return mockData.map((item, index) => ({
      id: `hot_${index + 1}`,
      ...item,
      imageUrl: item.rank <= 3 ? `https://example.com/hot${item.rank}.jpg` : undefined
    }));
  }

  /**
   * 执行搜索
   */
  public async search(options: {
    query: string;
    type?: SearchType;
    page?: number;
    pageSize?: number;
    filters?: SearchFilter;
  }): Promise<SearchResponse> {
    const { 
      query = '', 
      type = SearchType.ALL, 
      page = 1, 
      pageSize = 20, 
      filters = {} 
    } = options;
    
    // 验证搜索条件
    if (query.length < this.config.minSearchLength) {
      throw new Error(`Search query must be at least ${this.config.minSearchLength} characters`);
    }
    
    const startTime = Date.now();
    
    try {
      Logger.info(TAG, `Performing search: query=${query}, type=${type}, page=${page}, filters=${JSON.stringify(filters)}`);
      
      // 在实际应用中，这里应该调用API或本地数据库进行搜索
      // 这里使用模拟数据
      const searchResults = this.generateMockSearchResults(query, type, filters, page, pageSize);
      
      const searchTime = Date.now() - startTime;
      const response: SearchResponse = {
        query,
        total: searchResults.total,
        items: searchResults.items,
        page,
        pageSize,
        filters,
        searchType: type,
        searchTime
      };
      
      // 保存活跃搜索结果
      const searchId = this.generateSearchId(query, type, filters);
      this.activeSearches.set(searchId, response);
      
      // 通知监听器
      this.notifySearchCompleted(response);
      
      // 保存到搜索历史
      if (this.config.enableHistory && this.config.saveHistoryOnEnter) {
        await this.addToSearchHistory({
          query,
          resultCount: searchResults.total,
          searchType: type,
          filters
        });
      }
      
      // 更新最后搜索记录
      this.lastSearchQuery = query;
      
      return response;
    } catch (error) {
      Logger.error(TAG, `Search failed for query "${query}": ${error}`);
      throw error;
    }
  }

  /**
   * 生成搜索ID
   */
  private generateSearchId(query: string, type: SearchType, filters: SearchFilter): string {
    const filterStr = JSON.stringify(filters);
    return `search_${query}_${type}_${filterStr}`;
  }

  /**
   * 生成模拟搜索结果
   */
  private generateMockSearchResults(
    query: string, 
    type: SearchType, 
    filters: SearchFilter,
    page: number,
    pageSize: number
  ): { total: number; items: SearchResultItem[] } {
    // 模拟总结果数
    const total = 150;
    const start = (page - 1) * pageSize;
    const end = Math.min(start + pageSize, total);
    
    // 生成模拟结果项
    const items: SearchResultItem[] = [];
    const baseScore = 100 - page * 5; // 页码越大，匹配度越低
    
    for (let i = start; i < end; i++) {
      // 随机选择结果类型
      const resultTypes = filters.types && filters.types.length > 0 
        ? filters.types 
        : Object.values(SearchResultType);
      
      const randomType = resultTypes[Math.floor(Math.random() * resultTypes.length)];
      
      // 根据类型生成不同的标题前缀
      let titlePrefix = '';
      switch (randomType) {
        case SearchResultType.MOVIE:
          titlePrefix = '电影：';
          break;
        case SearchResultType.TV_SERIES:
          titlePrefix = '剧集：';
          break;
        case SearchResultType.LIVE:
          titlePrefix = '直播：';
          break;
        case SearchResultType.CHANNEL:
          titlePrefix = '频道：';
          break;
        case SearchResultType.ACTOR:
          titlePrefix = '演员：';
          break;
        case SearchResultType.DIRECTOR:
          titlePrefix = '导演：';
          break;
        case SearchResultType.GENRE:
          titlePrefix = '类型：';
          break;
        case SearchResultType.TAG:
          titlePrefix = '标签：';
          break;
      }
      
      // 生成模拟数据
      const item: SearchResultItem = {
        id: `result_${randomType}_${i}`,
        type: randomType,
        title: `${titlePrefix}${query} - ${i + 1}`,
        subtitle: randomType === SearchResultType.TV_SERIES ? '第1-12集' : undefined,
        description: `这是一部关于${query}的精彩${this.getTypeLabel(randomType)}。内容丰富，情节跌宕起伏，深受观众喜爱。`,
        posterUrl: `https://example.com/posters/${randomType}_${i % 20}.jpg`,
        coverUrl: `https://example.com/covers/${randomType}_${i % 10}.jpg`,
        year: 2010 + Math.floor(Math.random() * 14),
        rating: 5 + Math.random() * 5,
        genre: ['动作', '冒险', '科幻'].slice(0, Math.floor(Math.random() * 3) + 1),
        country: ['中国', '美国', '日本', '韩国'][Math.floor(Math.random() * 4)],
        language: ['中文', '英语', '日语', '韩语'][Math.floor(Math.random() * 4)],
        duration: 60 + Math.floor(Math.random() * 120),
        matchScore: baseScore - Math.random() * 20,
        meta: {
          viewCount: Math.floor(Math.random() * 1000000),
          commentCount: Math.floor(Math.random() * 10000)
        }
      };
      
      // 添加高亮
      if (this.config.highlightResults) {
        const queryLower = query.toLowerCase();
        const titleLower = item.title.toLowerCase();
        const descLower = item.description?.toLowerCase();
        
        item.highlight = {};
        
        // 简单的高亮实现：记录匹配位置
        if (titleLower.includes(queryLower)) {
          item.highlight.title = [
            titleLower.indexOf(queryLower).toString(),
            (titleLower.indexOf(queryLower) + query.length).toString()
          ];
        }
        
        if (descLower && descLower.includes(queryLower)) {
          item.highlight.description = [
            descLower.indexOf(queryLower).toString(),
            (descLower.indexOf(queryLower) + query.length).toString()
          ];
        }
      }
      
      items.push(item);
    }
    
    return { total, items };
  }

  /**
   * 获取类型标签
   */
  private getTypeLabel(type: SearchResultType): string {
    const labels: Record<SearchResultType, string> = {
      [SearchResultType.MOVIE]: '电影',
      [SearchResultType.TV_SERIES]: '电视剧',
      [SearchResultType.LIVE]: '直播',
      [SearchResultType.CHANNEL]: '频道',
      [SearchResultType.ACTOR]: '演员',
      [SearchResultType.DIRECTOR]: '导演',
      [SearchResultType.GENRE]: '类型',
      [SearchResultType.TAG]: '标签'
    };
    
    return labels[type] || type;
  }

  /**
   * 获取搜索建议
   */
  public async getSearchSuggestions(query: string, maxResults: number = 10): Promise<SearchSuggestionItem[]> {
    if (!this.config.enableSuggestions || query.length < this.config.minSearchLength) {
      return [];
    }
    
    try {
      Logger.debug(TAG, `Getting search suggestions for: ${query}`);
      
      const suggestions: SearchSuggestionItem[] = [];
      const lowerQuery = query.toLowerCase();
      const vodRepository = VodRepository.getInstance();
      
      // 1. 从实际影视作品数据中获取匹配的建议 - 支持拼音首字母匹配
      // 首先尝试通过关键词直接搜索
      let vodResults = await vodRepository.searchVod(query, undefined, maxResults * 3); // 获取更多结果以便过滤
      
      // 如果直接搜索结果不足，尝试模糊搜索获取更多候选数据
      if (vodResults.length < maxResults) {
        // 对于拼音输入，可以尝试搜索数据库中所有内容然后在内存中过滤
        const allVods = await vodRepository.searchVod('', undefined, 100);
        vodResults = [...new Set([...vodResults, ...allVods])];
      }
      
      // 过滤并排序建议：优化拼音首字母匹配逻辑
      const filteredVodSuggestions = vodResults
        .filter(item => {
          if (!item.title) return false;
          
          const title = item.title.toLowerCase();
          const firstLetters = pinyinUtil.getFirstLetter(item.title).toLowerCase();
          
          // 匹配规则优先级：
          // 1. 标题完全匹配
          // 2. 标题包含关键词
          // 3. 拼音首字母完全匹配
          // 4. 拼音首字母包含关键词
          // 5. 标题中任意词的拼音首字母匹配关键词
          
          // 直接文本匹配
          if (title === lowerQuery || title.includes(lowerQuery)) {
            return true;
          }
          
          // 拼音首字母匹配
          if (firstLetters.startsWith(lowerQuery) || firstLetters.includes(lowerQuery)) {
            return true;
          }
          
          // 检查标题中每个词的拼音首字母
          const words = item.title.split(/\s+/);
          return words.some(word => {
            const wordFirstLetters = pinyinUtil.getFirstLetter(word).toLowerCase();
            return wordFirstLetters.startsWith(lowerQuery) || wordFirstLetters.includes(lowerQuery);
          });
        })
        .sort((a, b) => {
          // 排序规则优化：
          // 1. 完全匹配优先
          // 2. 直接文本匹配优先于拼音首字母匹配
          // 3. 匹配位置越靠前优先级越高
          // 4. 标题长度短的优先
          const aTitle = a.title.toLowerCase();
          const bTitle = b.title.toLowerCase();
          const aFirstLetters = pinyinUtil.getFirstLetter(a.title).toLowerCase();
          const bFirstLetters = pinyinUtil.getFirstLetter(b.title).toLowerCase();
          
          // 完全匹配检查
          const aIsExactMatch = aTitle === lowerQuery;
          const bIsExactMatch = bTitle === lowerQuery;
          if (aIsExactMatch && !bIsExactMatch) return -1;
          if (!aIsExactMatch && bIsExactMatch) return 1;
          
          // 直接文本匹配检查
          const aHasTextMatch = aTitle.includes(lowerQuery);
          const bHasTextMatch = bTitle.includes(lowerQuery);
          if (aHasTextMatch && !bHasTextMatch) return -1;
          if (!aHasTextMatch && bHasTextMatch) return 1;
          
          // 拼音首字母匹配检查
          const aHasPinyinMatch = aFirstLetters.includes(lowerQuery);
          const bHasPinyinMatch = bFirstLetters.includes(lowerQuery);
          if (aHasPinyinMatch && !bHasPinyinMatch) return -1;
          if (!aHasPinyinMatch && bHasPinyinMatch) return 1;
          
          // 匹配位置检查
          if (aHasTextMatch && bHasTextMatch) {
            const aPos = aTitle.indexOf(lowerQuery);
            const bPos = bTitle.indexOf(lowerQuery);
            if (aPos !== bPos) return aPos - bPos;
          }
          
          // 标题长度排序
          return aTitle.length - bTitle.length;
        })
        .slice(0, maxResults)
        .map(item => ({
          text: item.title,
          type: 'movie' as const,
          icon: item.type === 'tv_series' ? 'tv' : 'movie',
          mediaType: item.type || 'unknown',
          year: item.year,
          count: 1 // 相关结果数量，实际应用中可以计算
        }));
      
      suggestions.push(...filteredVodSuggestions);
      
      // 2. 如果影视作品建议不足，从历史记录中补充
      if (suggestions.length < maxResults) {
        const historySuggestions = this.searchHistory
          .filter(item => {
            // 确保不与已添加的影视作品建议重复
            if (suggestions.some(s => s.text.toLowerCase() === item.query.toLowerCase())) {
              return false;
            }
            
            const itemQuery = item.query.toLowerCase();
            return itemQuery.includes(lowerQuery) || pinyinUtil.containsPinyin(item.query, query);
          })
          .slice(0, Math.min(3, maxResults - suggestions.length))
          .map(item => ({
            text: item.query,
            type: 'query' as const,
            count: item.resultCount,
            icon: 'history'
          }));
        
        suggestions.push(...historySuggestions);
      }
      
      // 通知监听器
      this.notifySuggestionsUpdated(suggestions);
      
      return suggestions;
    } catch (error) {
      Logger.error(TAG, `Failed to get search suggestions: ${error}`);
      return [];
    }
  }

  /**
   * 自动搜索（带防抖）
   */
  public async debouncedSearch(options: {
    query: string;
    type?: SearchType;
    filters?: SearchFilter;
  }): Promise<void> {
    // 清除之前的定时器
    if (this.debounceTimerId !== null) {
      clearTimeout(this.debounceTimerId);
    }
    
    // 设置新的定时器
    this.debounceTimerId = setTimeout(async () => {
      try {
        if (options.query.length >= this.config.minSearchLength) {
          await this.search({ ...options, page: 1, pageSize: 20 });
        }
      } catch (error) {
        Logger.error(TAG, `Debounced search failed: ${error}`);
      }
    }, this.config.autoSearchDelay);
  }

  /**
   * 添加到搜索历史
   */
  public async addToSearchHistory(data: {
    query: string;
    resultCount: number;
    searchType: SearchType;
    filters?: SearchFilter;
  }): Promise<void> {
    if (!this.config.enableHistory) {
      return;
    }
    
    // 检查是否已存在相同的搜索
    const existingIndex = this.searchHistory.findIndex(item => 
      item.query === data.query && item.searchType === data.searchType
    );
    
    const historyItem: SearchHistoryItem = {
      id: `history_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      query: data.query,
      timestamp: Date.now(),
      resultCount: data.resultCount,
      clickCount: 0,
      searchType: data.searchType,
      filters: data.filters
    };
    
    if (existingIndex >= 0) {
      // 更新现有记录
      const existing = this.searchHistory[existingIndex];
      historyItem.clickCount = existing.clickCount;
      historyItem.lastClickTime = existing.lastClickTime;
      
      // 移除旧记录
      this.searchHistory.splice(existingIndex, 1);
    }
    
    // 添加到历史记录开头
    this.searchHistory.unshift(historyItem);
    
    // 确保不超过最大限制
    if (this.searchHistory.length > this.config.maxHistoryItems) {
      this.searchHistory = this.searchHistory.slice(0, this.config.maxHistoryItems);
    }
    
    // 保存历史记录
    await this.saveSearchHistory();
  }

  /**
   * 记录搜索点击
   */
  public async recordSearchClick(historyId: string): Promise<void> {
    const historyItem = this.searchHistory.find(item => item.id === historyId);
    if (historyItem) {
      historyItem.clickCount++;
      historyItem.lastClickTime = Date.now();
      await this.saveSearchHistory();
    }
  }

  /**
   * 获取搜索历史
   */
  public getSearchHistory(limit: number = 50): SearchHistoryItem[] {
    return [...this.searchHistory].slice(0, limit);
  }

  /**
   * 清除搜索历史
   */
  public async clearSearchHistory(): Promise<void> {
    this.searchHistory = [];
    await this.saveSearchHistory();
    Logger.info(TAG, 'Search history cleared');
  }

  /**
   * 移除单条搜索历史
   */
  public async removeSearchHistoryItem(historyId: string): Promise<void> {
    const index = this.searchHistory.findIndex(item => item.id === historyId);
    if (index >= 0) {
      this.searchHistory.splice(index, 1);
      await this.saveSearchHistory();
      Logger.info(TAG, `Removed search history item: ${historyId}`);
    }
  }

  /**
   * 获取热门搜索
   */
  public async getHotSearches(limit: number = 20): Promise<HotSearchItem[]> {
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
   * 获取最近的搜索
   */
  public getRecentSearches(limit: number = 10): SearchHistoryItem[] {
    return [...this.searchHistory]
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice(0, limit);
  }

  /**
   * 获取最常搜索
   */
  public getFrequentSearches(limit: number = 10): SearchHistoryItem[] {
    return [...this.searchHistory]
      .sort((a, b) => b.clickCount - a.clickCount)
      .slice(0, limit);
  }

  /**
   * 搜索特定类型的内容
   */
  public async searchByType(
    query: string, 
    resultTypes: SearchResultType[],
    options?: Partial<{page: number; pageSize: number}>
  ): Promise<SearchResponse> {
    return this.search({
      query,
      type: SearchType.ALL,
      page: options?.page || 1,
      pageSize: options?.pageSize || 20,
      filters: { types: resultTypes }
    });
  }

  /**
   * 获取热门电影
   */
  public async getHotMovies(limit: number = 20): Promise<SearchResultItem[]> {
    // 在实际应用中，这里应该从API获取热门电影
    // 这里使用模拟搜索
    const response = await this.search({
      query: '',
      type: SearchType.ALL,
      page: 1,
      pageSize: limit,
      filters: {
        types: [SearchResultType.MOVIE],
        sortBy: 'popularity',
        sortOrder: 'desc'
      }
    });
    
    return response.items;
  }

  /**
   * 获取热门剧集
   */
  public async getHotTvSeries(limit: number = 20): Promise<SearchResultItem[]> {
    // 在实际应用中，这里应该从API获取热门剧集
    // 这里使用模拟搜索
    const response = await this.search({
      query: '',
      type: SearchType.ALL,
      page: 1,
      pageSize: limit,
      filters: {
        types: [SearchResultType.TV_SERIES],
        sortBy: 'popularity',
        sortOrder: 'desc'
      }
    });
    
    return response.items;
  }

  /**
   * 通知搜索完成
   */
  private notifySearchCompleted(response: SearchResponse): void {
    for (const listener of this.searchListeners) {
      try {
        listener({ ...response });
      } catch (error) {
        Logger.error(TAG, `Error in search listener: ${error}`);
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
        Logger.error(TAG, `Error in suggestion listener: ${error}`);
      }
    }
  }

  /**
   * 添加搜索监听器
   */
  public addSearchListener(listener: SearchListener): void {
    this.searchListeners.push(listener);
  }

  /**
   * 移除搜索监听器
   */
  public removeSearchListener(listener: SearchListener): void {
    const index = this.searchListeners.indexOf(listener);
    if (index > -1) {
      this.searchListeners.splice(index, 1);
    }
  }

  /**
   * 添加搜索建议监听器
   */
  public addSuggestionListener(listener: SuggestionListener): void {
    this.suggestionListeners.push(listener);
  }

  /**
   * 移除搜索建议监听器
   */
  public removeSuggestionListener(listener: SuggestionListener): void {
    const index = this.suggestionListeners.indexOf(listener);
    if (index > -1) {
      this.suggestionListeners.splice(index, 1);
    }
  }

  /**
   * 获取最后一次搜索查询
   */
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

    // 清除定时器
    if (this.debounceTimerId !== null) {
      clearTimeout(this.debounceTimerId);
    }
    
    // 保存数据
    await this.saveSearchHistory();

    this.isInitialized = false;
    Logger.info(TAG, 'Search service closed');
  }
}