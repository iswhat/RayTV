// SearchDto - 搜索相关数据传输对象
import { VideoType } from '../model/Movie';
import ApiResponse from './ApiResponse';

/**
 * 搜索类型枚举
 */
export enum SearchType {
  ALL = 'all',          // 全部类型 | All types
  MOVIE = 'movie',      // 电影 | Movie
  TV_SERIES = 'tv_series', // 电视剧 | TV series
  LIVE = 'live',        // 直播 | Live
  ANIME = 'anime',      // 动漫 | Anime
  VARIETY = 'variety',  // 综艺 | Variety
  DOCUMENTARY = 'documentary', // 纪录片 | Documentary
  SPORTS = 'sports',    // 体育 | Sports
  MUSIC = 'music',      // 音乐 | Music
  KIDS = 'kids'         // 儿童 | Kids
}

/**
 * 搜索排序枚举
 */
export enum SearchSort {
  DEFAULT = 'default',           // 默认排序 | Default sort
  LATEST = 'latest',             // 最新 | Latest
  HOTTEST = 'hottest',           // 最热 | Hottest
  RATING_DESC = 'rating_desc',   // 评分从高到低 | Rating from high to low
  RATING_ASC = 'rating_asc',     // 评分从低到高 | Rating from low to high
  RELEASE_DATE_DESC = 'release_date_desc', // 发布日期从新到旧 | Release date from new to old
  RELEASE_DATE_ASC = 'release_date_asc'    // 发布日期从旧到新 | Release date from old to new
}

/**
 * 搜索筛选条件接口
 */
export interface SearchFilter {
  year?: number | null;              // 年份 | Year
  country?: string | null;           // 国家/地区 | Country/Region
  genre?: string | null;             // 类型 | Genre
  language?: string | null;          // 语言 | Language
  minRating?: number | null;         // 最低评分 | Minimum rating
  maxRating?: number | null;         // 最高评分 | Maximum rating
  durationMin?: number | null;       // 最短时长(分钟) | Minimum duration (minutes)
  durationMax?: number | null;       // 最长时长(分钟) | Maximum duration (minutes)
  studio?: string | null;            // 制作公司 | Studio
  director?: string | null;          // 导演 | Director
  actor?: string | null;             // 演员 | Actor
  keywords?: string[] | null;        // 关键词列表 | Keyword list
  subtitle?: boolean | null;         // 是否有字幕 | Has subtitle
  hd?: boolean | null;               // 是否高清 | Is HD
  premium?: boolean | null;          // 是否付费内容 | Is premium content
}

/**
 * 搜索请求参数接口
 */
export interface SearchRequest {
  keyword: string;                  // 搜索关键词 | Search keyword
  type: SearchType;                 // 搜索类型 | Search type
  page: number;                     // 页码 | Page number
  pageSize: number;                 // 每页大小 | Page size
  sort: SearchSort;                 // 排序方式 | Sort method
  filter?: SearchFilter;            // 筛选条件 | Filter conditions
  includeSuggestions?: boolean;     // 是否包含搜索建议 | Include search suggestions
  autoCorrect?: boolean;            // 是否自动纠正拼写 | Auto correct spelling
  language?: string;                // 搜索语言 | Search language
}

/**
 * 搜索建议接口
 */
export interface SearchSuggestion {
  text: string;                     // 建议文本 | Suggestion text
  type?: SearchType;                // 建议类型 | Suggestion type
  count?: number;                   // 相关结果数量 | Related result count
  tags?: string[];                  // 相关标签 | Related tags
  highlight?: boolean;              // 是否高亮显示 | Highlight display
  source?: string;                  // 来源 | Source
}

/**
 * 搜索历史记录接口
 */
export interface SearchHistory {
  id: string;                       // 历史记录ID | History record ID
  keyword: string;                  // 搜索关键词 | Search keyword
  type: SearchType;                 // 搜索类型 | Search type
  timestamp: number;                // 搜索时间戳 | Search timestamp
  count: number;                    // 搜索次数 | Search count
  lastSearchAt: number;             // 最后搜索时间 | Last search time
}

/**
 * 搜索结果项接口
 */
export interface SearchResultItem {
  id: string;                       // 内容ID | Content ID
  title: string;                    // 标题 | Title
  originalTitle?: string;           // 原始标题 | Original title
  subtitle?: string;                // 副标题 | Subtitle
  description?: string;             // 简介 | Description
  type: VideoType;                  // 视频类型 | Video type
  coverUrl?: string;                // 封面图片URL | Cover image URL
  posterUrl?: string;               // 海报图片URL | Poster image URL
  backdropUrl?: string;             // 背景图片URL | Backdrop image URL
  rating?: number;                  // 评分 | Rating
  releaseYear?: number;             // 发布年份 | Release year
  genres?: string[];                // 类型标签 | Genre tags
  countries?: string[];             // 国家/地区 | Countries/Regions
  duration?: number;                // 时长(秒) | Duration (seconds)
  isNew?: boolean;                  // 是否新内容 | Is new content
  isHot?: boolean;                  // 是否热门 | Is hot
  isVip?: boolean;                  // 是否VIP内容 | Is VIP content
  hasSubtitle?: boolean;            // 是否有字幕 | Has subtitle
  totalEpisodes?: number;           // 总集数(电视剧) | Total episodes (TV series)
  airedEpisodes?: number;           // 已更新集数(电视剧) | Aired episodes (TV series)
  directors?: string[];             // 导演列表 | Director list
  actors?: string[];                // 演员列表 | Actor list
  provider?: string;                // 内容提供商 | Content provider
  providerId?: string;              // 提供商ID | Provider ID
  searchScore?: number;             // 搜索匹配分数 | Search match score
  highlightTerms?: string[];        // 需要高亮的关键词 | Keywords to highlight
  source?: string;                  // 来源 | Source
  metadata?: Record<string, unknown>;   // 额外参数 | Extra parameters
}

/**
 * 搜索结果响应接口
 */
export interface SearchResponseData {
  items: SearchResultItem[];        // 搜索结果列表 | Search result list
  total: number;                    // 总结果数 | Total result count
  page: number;                     // 当前页码 | Current page number
  pageSize: number;                 // 每页大小 | Page size
  totalPages: number;               // 总页数 | Total page count
  hasMore: boolean;                 // 是否有更多 | Has more
  suggestions?: SearchSuggestion[]; // 搜索建议(如果请求了) | Search suggestions (if requested)
  correctedKeyword?: string;        // 纠正后的关键词(如果自动纠正了) | Corrected keyword (if auto corrected)
  searchTime: number;               // 搜索耗时(毫秒) | Search time (milliseconds)
  filters?: SearchFilter;           // 应用的筛选条件 | Applied filter conditions
  typeDistribution?: Record<string, number>; // 类型分布统计 | Type distribution statistics
}

/**
 * 搜索结果API响应
 */
export type SearchApiResponse = ApiResponse<SearchResponseData>;

/**
 * 搜索建议响应接口
 */
export interface SearchSuggestionsResponseData {
  suggestions: SearchSuggestion[];  // 搜索建议列表 | Search suggestion list
  keyword: string;                  // 搜索关键词 | Search keyword
  totalSuggestions: number;         // 建议总数 | Total suggestion count
}

/**
 * 搜索建议API响应
 */
export type SearchSuggestionsApiResponse = ApiResponse<SearchSuggestionsResponseData>;

/**
 * 搜索历史响应接口
 */
export interface SearchHistoryResponseData {
  histories: SearchHistory[];       // 搜索历史列表 | Search history list
  total: number;                    // 总数 | Total count
}

/**
 * 搜索历史API响应
 */
export type SearchHistoryApiResponse = ApiResponse<SearchHistoryResponseData>;

/**
 * 热门搜索关键词接口
 */
export interface HotKeyword {
  id: string;                       // 关键词ID | Keyword ID
  keyword: string;                  // 关键词文本 | Keyword text
  count: number;                    // 搜索次数 | Search count
  trend: 'up' | 'down' | 'stable';  // 趋势 | Trend
  isNew?: boolean;                  // 是否新关键词 | Is new keyword
  tags?: string[];                  // 标签 | Tags
  rank?: number;                    // 排名 | Rank
}

/**
 * 热门搜索响应接口
 */
export interface HotSearchResponseData {
  keywords: HotKeyword[];           // 热门关键词列表 | Hot keyword list
  updatedAt: number;                // 更新时间 | Update time
}

/**
 * 热门搜索API响应
 */
export type HotSearchApiResponse = ApiResponse<HotSearchResponseData>;

/**
 * 搜索配置接口
 */
export interface SearchConfig {
  enabled: boolean;                 // 是否启用搜索 | Enable search
  maxResults: number;               // 最大结果数 | Maximum result count
  minKeywordLength: number;         // 最小关键词长度 | Minimum keyword length
  suggestionEnabled: boolean;       // 是否启用搜索建议 | Enable search suggestions
  historyEnabled: boolean;          // 是否启用搜索历史 | Enable search history
  maxHistoryItems: number;          // 最大历史记录数 | Maximum history item count
  autoCorrectEnabled: boolean;      // 是否启用自动纠正 | Enable auto correction
  cacheEnabled: boolean;            // 是否启用搜索缓存 | Enable search cache
  cacheExpiry: number;              // 缓存过期时间(秒) | Cache expiry time (seconds)
  supportedTypes: SearchType[];     // 支持的搜索类型 | Supported search types
  defaultType: SearchType;          // 默认搜索类型 | Default search type
  supportedSorts: SearchSort[];     // 支持的排序方式 | Supported sort methods
  defaultSort: SearchSort;          // 默认排序方式 | Default sort method
}

/**
 * 搜索结果分组接口
 */
export interface SearchResultGroup {
  type: SearchType;                 // 分组类型 | Group type
  title: string;                    // 分组标题 | Group title
  items: SearchResultItem[];        // 分组内的结果 | Results in group
  total: number;                    // 分组内总结果数 | Total results in group
  hasMore: boolean;                 // 分组内是否有更多 | Has more in group
}

/**
 * 分组搜索结果响应接口
 */
export interface GroupedSearchResponseData {
  groups: SearchResultGroup[];      // 分组搜索结果 | Grouped search results
  total: number;                    // 总结果数 | Total result count
  searchTime: number;               // 搜索耗时(毫秒) | Search time (milliseconds)
  keyword: string;                  // 搜索关键词 | Search keyword
}

/**
 * 分组搜索结果API响应
 */
export type GroupedSearchApiResponse = ApiResponse<GroupedSearchResponseData>;

/**
 * 高级搜索参数接口
 */
export interface AdvancedSearchParams {
  title?: string;                   // 标题 | Title
  originalTitle?: string;           // 原始标题 | Original title
  actor?: string;                   // 演员 | Actor
  director?: string;                // 导演 | Director
  writer?: string;                  // 编剧 | Writer
  year?: number | [number, number]; // 年份或年份范围 | Year or year range
  genre?: string[];                 // 类型列表 | Genre list
  country?: string[];               // 国家/地区列表 | Country/Region list
  language?: string[];              // 语言列表 | Language list
  rating?: [number, number];        // 评分范围 | Rating range
  duration?: [number, number];      // 时长范围(分钟) | Duration range (minutes)
  releaseDate?: [string, string];   // 发布日期范围 | Release date range
  sort?: SearchSort;                // 排序方式 | Sort method
  page?: number;                    // 页码 | Page number
  pageSize?: number;                // 每页大小 | Page size
}

/**
 * 搜索统计信息接口
 */
export interface SearchStats {
  totalResults: number;             // 总结果数 | Total result count
  timeTaken: number;                // 耗时(毫秒) | Time taken (milliseconds)
  cached: boolean;                  // 是否来自缓存 | From cache
  hitRate?: number;                 // 命中率 | Hit rate
  facets?: Record<string, Record<string, number>>; // 分面统计 | Facet statistics
}

/**
 * 搜索记录接口
 */
export interface SearchRecord {
  id: string;                       // 记录ID | Record ID
  userId?: string;                  // 用户ID(如果已登录) | User ID (if logged in)
  keyword: string;                  // 搜索关键词 | Search keyword
  type: SearchType;                 // 搜索类型 | Search type
  filters?: SearchFilter;           // 筛选条件 | Filter conditions
  sort: SearchSort;                 // 排序方式 | Sort method
  resultsCount: number;             // 结果数量 | Result count
  timestamp: number;                // 搜索时间 | Search time
  ipAddress?: string;               // IP地址(用于统计) | IP address (for statistics)
  userAgent?: string;               // 用户代理(用于统计) | User agent (for statistics)
}

/**
 * 搜索相关的工具方法
 */
export class SearchUtils {
  /**
   * 转换SearchType为VideoType
   */
  static searchTypeToVideoType(searchType: SearchType): VideoType {
    switch (searchType) {
      case SearchType.MOVIE:
        return VideoType.MOVIE;
      case SearchType.TV_SERIES:
        return VideoType.TV_SERIES;
      case SearchType.LIVE:
        return VideoType.LIVE;
      case SearchType.ANIME:
        return VideoType.ANIME;
      case SearchType.VARIETY:
        return VideoType.VARIETY;
      case SearchType.DOCUMENTARY:
        return VideoType.DOCUMENTARY;
      case SearchType.SPORTS:
        return VideoType.SPORTS;
      case SearchType.MUSIC:
        return VideoType.MUSIC;
      case SearchType.KIDS:
        return VideoType.KIDS;
      default:
        return VideoType.UNKNOWN;
    }
  }

  /**
   * 获取SearchType的显示名称
   */
  static getSearchTypeDisplayName(type: SearchType): string {
    const typeMap: Record<SearchType, string> = {
      [SearchType.ALL]: '全部',
      [SearchType.MOVIE]: '电影',
      [SearchType.TV_SERIES]: '电视剧',
      [SearchType.LIVE]: '直播',
      [SearchType.ANIME]: '动漫',
      [SearchType.VARIETY]: '综艺',
      [SearchType.DOCUMENTARY]: '纪录片',
      [SearchType.SPORTS]: '体育',
      [SearchType.MUSIC]: '音乐',
      [SearchType.KIDS]: '儿童'
    };
    return typeMap[type] || '未知';
  }

  /**
   * 验证搜索关键词
   */
  static validateKeyword(keyword: string, minLength: number = 1): boolean {
    if (!keyword || typeof keyword !== 'string') {
      return false;
    }
    const trimmedKeyword = keyword.trim();
    return trimmedKeyword.length >= minLength;
  }

  /**
   * 处理搜索关键词
   */
  static sanitizeKeyword(keyword: string): string {
    if (!keyword || typeof keyword !== 'string') {
      return '';
    }
    // 移除多余空格和特殊字符，保留基本标点
    return keyword.trim()
      .replace(/\s+/g, ' ')  // 替换多个空格为单个空格
      .replace(/[<>'"&]/g, ''); // 移除潜在的危险字符
  }

  /**
   * 创建默认的搜索请求
   */
  static createDefaultSearchRequest(keyword: string): SearchRequest {
    return {
      keyword: this.sanitizeKeyword(keyword),
      type: SearchType.ALL,
      page: 1,
      pageSize: 20,
      sort: SearchSort.DEFAULT,
      includeSuggestions: false,
      autoCorrect: false
    };
  }
}
