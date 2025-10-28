/**
 * 搜索相关的数据传输对象
 */

/**
 * 搜索类型枚举
 */
export enum SearchType {
  All = 'all',
  Movie = 'movie',
  Tv = 'tv',
  Anime = 'anime',
  Variety = 'variety'
}

/**
 * 搜索排序方式
 */
export enum SearchSort {
  Time = 'time', // 按时间排序
  Score = 'score', // 按评分排序
  Hot = 'hot' // 按热度排序
}

/**
 * 搜索筛选条件
 */
export interface SearchFilter {
  /** 媒体类型筛选 */
  types?: string[];
  /** 排序方式 */
  sortBy?: SearchSort | string;
  /** 年份筛选 */
  year?: number;
  /** 地区筛选 */
  region?: string[];
  /** 语言筛选 */
  language?: string[];
  /** 标签筛选 */
  tags?: string[];
  /** 最低评分 */
  minScore?: number;
  /** 最高评分 */
  maxScore?: number;
}

/**
 * 搜索请求参数
 */
export interface SearchRequest {
  /** 搜索关键词 */
  keyword: string;
  /** 搜索类型 */
  type: SearchType;
  /** 页码 */
  page: number;
  /** 每页数量 */
  pageSize: number;
  /** 筛选条件 */
  filters?: SearchFilter;
}

/**
 * 搜索结果响应
 */
export interface SearchResponse {
  /** 搜索结果列表 */
  items: any[];
  /** 总页数 */
  totalPages: number;
  /** 总数量 */
  totalCount: number;
  /** 当前页码 */
  currentPage: number;
  /** 每页数量 */
  pageSize: number;
}
