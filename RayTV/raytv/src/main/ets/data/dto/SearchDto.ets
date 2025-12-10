// SearchDto - 搜索相关数据传输对象
import { VideoType } from '../model/Movie';
import ApiResponse from './ApiResponse';

/**
 * 搜索类型枚举
 */
export enum SearchType {
  ALL = 'all',          // 全部类型
  MOVIE = 'movie',      // 电影
  TV_SERIES = 'tv_series', // 电视�?  LIVE = 'live',        // 直播
  ANIME = 'anime',      // 动漫
  VARIETY = 'variety',  // 综艺
  DOCUMENTARY = 'documentary', // 纪录�?  SPORTS = 'sports',    // 体育
  MUSIC = 'music',      // 音乐
  KIDS = 'kids'         // 少儿
}

/**
 * 搜索排序枚举
 */
export enum SearchSort {
  DEFAULT = 'default',           // 默认排序
  LATEST = 'latest',             // 最�?  HOTTEST = 'hottest',           // 最�?  RATING_DESC = 'rating_desc',   // 评分从高到低
  RATING_ASC = 'rating_asc',     // 评分从低到高
  RELEASE_DATE_DESC = 'release_date_desc', // 发行日期从新到旧
  RELEASE_DATE_ASC = 'release_date_asc'    // 发行日期从旧到新
}

/**
 * 搜索筛选条件接�? */
export interface SearchFilter {
  year?: number | null;              // 年份
  country?: string | null;           // 国家/地区
  genre?: string | null;             // 类型
  language?: string | null;          // 语言
  minRating?: number | null;         // 最低评�?  maxRating?: number | null;         // 最高评�?  durationMin?: number | null;       // 最短时长（分钟�?  durationMax?: number | null;       // 最长时长（分钟�?  studio?: string | null;            // 制作公司
  director?: string | null;          // 导演
  actor?: string | null;             // 演员
  keywords?: string[] | null;        // 关键词列�?  subtitle?: boolean | null;         // 是否有字�?  hd?: boolean | null;               // 是否高清
  premium?: boolean | null;          // 是否付费内容
}

/**
 * 搜索请求参数接口
 */
export interface SearchRequest {
  keyword: string;                  // 搜索关键�?  type: SearchType;                 // 搜索类型
  page: number;                     // 页码
  pageSize: number;                 // 每页大小
  sort: SearchSort;                 // 排序方式
  filter?: SearchFilter;            // 筛选条�?  includeSuggestions?: boolean;     // 是否包含搜索建议
  autoCorrect?: boolean;            // 是否自动纠正拼写
  language?: string;                // 搜索语言
}

/**
 * 搜索建议接口
 */
export interface SearchSuggestion {
  text: string;                     // 建议文本
  type?: SearchType;                // 建议类型
  count?: number;                   // 相关结果数量
  tags?: string[];                  // 相关标签
  highlight?: boolean;              // 是否高亮显示
  source?: string;                  // 来源
}

/**
 * 搜索历史记录接口
 */
export interface SearchHistory {
  id: string;                       // 历史记录ID
  keyword: string;                  // 搜索关键�?  type: SearchType;                 // 搜索类型
  timestamp: number;                // 搜索时间�?  count: number;                    // 搜索次数
  lastSearchAt: number;             // 最后搜索时�?}

/**
 * 搜索结果项接�? */
export interface SearchResultItem {
  id: string;                       // 内容ID
  title: string;                    // 标题
  originalTitle?: string;           // 原始标题
  subtitle?: string;                // 副标�?  description?: string;             // 简�?  type: VideoType;                  // 视频类型
  coverUrl?: string;                // 封面图片URL
  posterUrl?: string;               // 海报图片URL
  backdropUrl?: string;             // 背景图片URL
  rating?: number;                  // 评分
  releaseYear?: number;             // 发行年份
  genres?: string[];                // 类型标签
  countries?: string[];             // 国家/地区
  duration?: number;                // 时长（秒�?  isNew?: boolean;                  // 是否新内�?  isHot?: boolean;                  // 是否热门
  isVip?: boolean;                  // 是否VIP内容
  hasSubtitle?: boolean;            // 是否有字�?  totalEpisodes?: number;           // 总集数（电视剧）
  airedEpisodes?: number;           // 已更新集数（电视剧）
  directors?: string[];             // 导演列表
  actors?: string[];                // 演员列表
  provider?: string;                // 内容提供�?  providerId?: string;              // 提供商ID
  searchScore?: number;             // 搜索匹配分数
  highlightTerms?: string[];        // 需要高亮的关键�?  source?: string;                  // 来源
  metadata?: Record<string, unknown>;   // 额外元数�?}

/**
 * 搜索结果响应接口
 */
export interface SearchResponseData {
  items: SearchResultItem[];        // 搜索结果列表
  total: number;                    // 总结果数
  page: number;                     // 当前页码
  pageSize: number;                 // 每页大小
  totalPages: number;               // 总页�?  hasMore: boolean;                 // 是否有更�?  suggestions?: SearchSuggestion[]; // 搜索建议（如果请求了�?  correctedKeyword?: string;        // 纠正后的关键词（如果自动纠正了）
  searchTime: number;               // 搜索耗时（毫秒）
  filters?: SearchFilter;           // 应用的筛选条�?  typeDistribution?: Record<string, number>; // 类型分布统计
}

/**
 * 搜索结果API响应
 */
export type SearchApiResponse = ApiResponse<SearchResponseData>;

/**
 * 搜索建议响应接口
 */
export interface SearchSuggestionsResponseData {
  suggestions: SearchSuggestion[];  // 搜索建议列表
  keyword: string;                  // 搜索关键�?  totalSuggestions: number;         // 建议总数
}

/**
 * 搜索建议API响应
 */
export type SearchSuggestionsApiResponse = ApiResponse<SearchSuggestionsResponseData>;

/**
 * 搜索历史响应接口
 */
export interface SearchHistoryResponseData {
  histories: SearchHistory[];       // 搜索历史列表
  total: number;                    // 总数
}

/**
 * 搜索历史API响应
 */
export type SearchHistoryApiResponse = ApiResponse<SearchHistoryResponseData>;

/**
 * 热门搜索关键词接�? */
export interface HotKeyword {
  id: string;                       // 关键词ID
  keyword: string;                  // 关键词文�?  count: number;                    // 搜索次数
  trend: 'up' | 'down' | 'stable';  // 趋势
  isNew?: boolean;                  // 是否新关键词
  tags?: string[];                  // 标签
  rank?: number;                    // 排名
}

/**
 * 热门搜索响应接口
 */
export interface HotSearchResponseData {
  keywords: HotKeyword[];           // 热门关键词列�?  updatedAt: number;                // 更新时间
}

/**
 * 热门搜索API响应
 */
export type HotSearchApiResponse = ApiResponse<HotSearchResponseData>;

/**
 * 搜索配置接口
 */
export interface SearchConfig {
  enabled: boolean;                 // 是否启用搜索
  maxResults: number;               // 最大结果数
  minKeywordLength: number;         // 最小关键词长度
  suggestionEnabled: boolean;       // 是否启用搜索建议
  historyEnabled: boolean;          // 是否启用搜索历史
  maxHistoryItems: number;          // 最大历史记录数
  autoCorrectEnabled: boolean;      // 是否启用自动纠正
  cacheEnabled: boolean;            // 是否启用搜索缓存
  cacheExpiry: number;              // 缓存过期时间（毫秒）
  supportedTypes: SearchType[];     // 支持的搜索类�?  defaultType: SearchType;          // 默认搜索类型
  supportedSorts: SearchSort[];     // 支持的排序方�?  defaultSort: SearchSort;          // 默认排序方式
}

/**
 * 搜索结果分组接口
 */
export interface SearchResultGroup {
  type: SearchType;                 // 分组类型
  title: string;                    // 分组标题
  items: SearchResultItem[];        // 分组内的结果
  total: number;                    // 分组内总结果数
  hasMore: boolean;                 // 分组内是否有更多
}

/**
 * 分组搜索结果响应接口
 */
export interface GroupedSearchResponseData {
  groups: SearchResultGroup[];      // 分组搜索结果
  total: number;                    // 总结果数
  searchTime: number;               // 搜索耗时（毫秒）
  keyword: string;                  // 搜索关键�?}

/**
 * 分组搜索结果API响应
 */
export type GroupedSearchApiResponse = ApiResponse<GroupedSearchResponseData>;

/**
 * 高级搜索参数接口
 */
export interface AdvancedSearchParams {
  title?: string;                   // 标题
  originalTitle?: string;           // 原始标题
  actor?: string;                   // 演员
  director?: string;                // 导演
  writer?: string;                  // 编剧
  year?: number | [number, number]; // 年份或年份范�?  genre?: string[];                 // 类型列表
  country?: string[];               // 国家/地区列表
  language?: string[];              // 语言列表
  rating?: [number, number];        // 评分范围
  duration?: [number, number];      // 时长范围（分钟）
  releaseDate?: [string, string];   // 发行日期范围
  sort?: SearchSort;                // 排序方式
  page?: number;                    // 页码
  pageSize?: number;                // 每页大小
}

/**
 * 搜索统计信息接口
 */
export interface SearchStats {
  totalResults: number;             // 总结果数
  timeTaken: number;                // 耗时（毫秒）
  cached: boolean;                  // 是否来自缓存
  hitRate?: number;                 // 命中�?  facets?: Record<string, Record<string, number>>; // 分面统计
}

/**
 * 搜索记录接口
 */
export interface SearchRecord {
  id: string;                       // 记录ID
  userId?: string;                  // 用户ID（如果已登录�?  keyword: string;                  // 搜索关键�?  type: SearchType;                 // 搜索类型
  filters?: SearchFilter;           // 筛选条�?  sort: SearchSort;                 // 排序方式
  resultsCount: number;             // 结果数量
  selectedResultId?: string;        // 选择的结果ID
  timestamp: number;                // 搜索时间
  ipAddress?: string;               // IP地址（用于统计）
  userAgent?: string;               // 用户代理（用于统计）
}

/**
 * 搜索相关的工具方�? */
export class SearchUtils {
  /**
   * 转换SearchType到VideoType
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
   * 获取SearchType的显示名�?   */
  static getSearchTypeDisplayName(type: SearchType): string {
    const typeMap: Record<SearchType, string> = {
      [SearchType.ALL]: '全部',
      [SearchType.MOVIE]: '电影',
      [SearchType.TV_SERIES]: '电视�?,
      [SearchType.LIVE]: '直播',
      [SearchType.ANIME]: '动漫',
      [SearchType.VARIETY]: '综艺',
      [SearchType.DOCUMENTARY]: '纪录�?,
      [SearchType.SPORTS]: '体育',
      [SearchType.MUSIC]: '音乐',
      [SearchType.KIDS]: '少儿'
    };
    return typeMap[type] || '未知';
  }

  /**
   * 获取SearchSort的显示名�?   */
  static getSearchSortDisplayName(sort: SearchSort): string {
    const sortMap: Record<SearchSort, string> = {
      [SearchSort.DEFAULT]: '默认排序',
      [SearchSort.LATEST]: '最�?,
      [SearchSort.HOTTEST]: '最�?,
      [SearchSort.RATING_DESC]: '评分从高到低',
      [SearchSort.RATING_ASC]: '评分从低到高',
      [SearchSort.RELEASE_DATE_DESC]: '发行日期从新到旧',
      [SearchSort.RELEASE_DATE_ASC]: '发行日期从旧到新'
    };
    return sortMap[sort] || '默认排序';
  }

  /**
   * 验证搜索关键�?   */
  static validateKeyword(keyword: string, minLength: number = 1): boolean {
    if (!keyword || typeof keyword !== 'string') {
      return false;
    }
    const trimmedKeyword = keyword.trim();
    return trimmedKeyword.length >= minLength;
  }

  /**
   * 清理搜索关键�?   */
  static sanitizeKeyword(keyword: string): string {
    if (!keyword || typeof keyword !== 'string') {
      return '';
    }
    // 移除多余空格和特殊字符，保留基本标点
    return keyword.trim()
      .replace(/\s+/g, ' ')  // 替换多个空格为单个空�?      .replace(/[<>"'&]/g, ''); // 移除潜在的危险字�?  }

  /**
   * 创建默认的搜索请�?   */
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
