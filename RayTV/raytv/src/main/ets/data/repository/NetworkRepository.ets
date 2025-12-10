// NetworkRepository - 网络服务接口
import Logger from '../../common/util/Logger';
import Movie from '../model/Movie';
import SearchResult from '../model/SearchResult';

const TAG = 'NetworkRepository';

/**
 * 网络请求结果接口
 */
export interface NetworkResult<T> {
  success: boolean;
  data?: T;
  error?: Error;
  message?: string;
  code?: number;
  headers?: Record<string, string>;
  statusCode?: number;
}

/**
 * 网络请求配置接口
 */
export interface NetworkConfig {
  baseUrl: string;
  timeout: number;      // 超时时间（毫秒）
  retryCount: number;   // 重试次数
  headers?: Record<string, string>;  // 默认请求�?  params?: Record<string, string>;    // 默认参数
  cacheEnabled?: boolean;  // 是否启用缓存
  cacheExpiry?: number;    // 缓存过期时间（毫秒）
}

/**
 * 搜索参数接口
 */
export interface SearchParams {
  keyword: string;        // 搜索关键�?  page: number;           // 页码
  pageSize: number;       // 每页数量
  type?: string;          // 内容类型筛�?  genre?: string;         // 类型筛�?  year?: number;          // 年份筛�?  region?: string;        // 地区筛�?  sortBy?: string;        // 排序字段
  sortOrder?: 'asc' | 'desc'; // 排序顺序
  filters?: Record<string, string | number | boolean | string[]>; // 额外筛选条�?}

/**
 * 分页响应接口
 */
export interface PaginatedResponse<T> {
  items: T[];             // 当前页数�?  total: number;          // 总数据量
  page: number;           // 当前页码
  pageSize: number;       // 每页数量
  totalPages: number;     // 总页�?  hasMore: boolean;       // 是否有更�?  extra?: Record<string, string | number | boolean | string[]>; // 额外信息
}

/**
 * 视频源接�? */
export interface VideoSourceInfo {
  id: string;             // 源ID
  name: string;           // 源名�?  url: string;            // 源URL
  quality: string;        // 画质
  format: string;         // 格式
  size?: number;          // 文件大小
  duration?: number;      // 时长
  isDefault?: boolean;    // 是否默认
  headers?: Record<string, string>; // 请求�?  cookies?: string;       // Cookies
  extra?: Record<string, Record<string, string | number | boolean>>; // 额外信息
}

/**
 * 章节信息接口
 */
export interface ChapterInfo {
  id: string;             // 章节ID
  title: string;          // 章节标题
  index: number;          // 章节索引
  duration?: number;      // 章节时长
  startTime?: number;     // 开始时间点
  endTime?: number;       // 结束时间�?  previewUrl?: string;    // 预览图URL
  description?: string;   // 章节描述
}

/**
 * 直播频道信息接口
 */
export interface LiveChannelInfo {
  id: string;             // 频道ID
  name: string;           // 频道名称
  logo?: string;          // 频道Logo
  url: string;            // 播放URL
  category?: string;      // 频道分类
  country?: string;       // 所属国�?  language?: string;      // 语言
  description?: string;   // 频道描述
  epgUrl?: string;        // EPG指南URL
  nowPlaying?: string;    // 当前播放节目
  nextPlaying?: string;   // 下一个节�?  isFavorite?: boolean;   // 是否收藏
  sortOrder?: number;     // 排序顺序
  extra?: Record<string, Record<string, string | number | boolean>>; // 额外信息
}

/**
 * 解析器接�? */
export interface ParserInfo {
  id: string;             // 解析器ID
  name: string;           // 解析器名�?  description?: string;   // 解析器描�?  supports?: string[];    // 支持的网�?协议
  version?: string;       // 版本
  isEnabled?: boolean;    // 是否启用
  config?: Record<string, Record<string, string | number | boolean>>; // 解析器配�?}

/**
 * 网络仓库接口
 * 定义与外部数据源交互的抽象方�? */
export default interface NetworkRepository {
  /**
   * 初始化网络服�?   * @param config 网络配置
   * @returns 初始化结�?   */
  initialize(config: NetworkConfig): Promise<NetworkResult<void>>;

  /**
   * 设置网络配置
   * @param config 网络配置
   */
  setConfig(config: Partial<NetworkConfig>): void;

  /**
   * 获取当前网络配置
   * @returns 网络配置
   */
  getConfig(): NetworkConfig;

  // ========== 搜索相关接口 ==========
  
  /**
   * 搜索内容
   * @param params 搜索参数
   * @returns 搜索结果
   */
  searchContent(params: SearchParams): Promise<NetworkResult<PaginatedResponse<SearchResult>>>;

  /**
   * 获取热门搜索关键�?   * @param limit 限制数量
   * @returns 热门搜索关键词列�?   */
  getHotSearchKeywords(limit: number = 20): Promise<NetworkResult<string[]>>;

  /**
   * 获取搜索建议
   * @param keyword 搜索关键�?   * @param limit 限制数量
   * @returns 搜索建议列表
   */
  getSearchSuggestions(keyword: string, limit: number = 10): Promise<NetworkResult<string[]>>;

  // ========== 电影/视频相关接口 ==========
  
  /**
   * 获取电影详情
   * @param movieId 电影ID
   * @returns 电影详情
   */
  getMovieDetail(movieId: string): Promise<NetworkResult<Movie>>;

  /**
   * 获取电影列表
   * @param params 分页参数
   * @returns 电影列表
   */
  getMovieList(params: SearchParams): Promise<NetworkResult<PaginatedResponse<Movie>>>;

  /**
   * 获取推荐电影
   * @param movieId 当前电影ID
   * @param limit 限制数量
   * @returns 推荐电影列表
   */
  getRecommendedMovies(movieId: string, limit: number = 20): Promise<NetworkResult<Movie[]>>;

  /**
   * 获取相关电影
   * @param movieId 当前电影ID
   * @param limit 限制数量
   * @returns 相关电影列表
   */
  getRelatedMovies(movieId: string, limit: number = 20): Promise<NetworkResult<Movie[]>>;

  /**
   * 获取电影评分
   * @param movieId 电影ID
   * @returns 评分信息
   */
  getMovieRating(movieId: string): Promise<NetworkResult<Record<string, string | number | boolean>>>;

  // ========== 视频播放相关接口 ==========
  
  /**
   * 获取视频源列�?   * @param contentId 内容ID
   * @param contentType 内容类型
   * @returns 视频源列�?   */
  getVideoSources(contentId: string, contentType: string): Promise<NetworkResult<VideoSourceInfo[]>>;

  /**
   * 解析视频�?   * @param sourceUrl 视频源URL
   * @param parserId 解析器ID（可选）
   * @returns 解析后的视频信息
   */
  parseVideoSource(sourceUrl: string, parserId?: string): Promise<NetworkResult<VideoSourceInfo>>;

  /**
   * 获取视频章节列表
   * @param contentId 内容ID
   * @param season 季数
   * @returns 章节列表
   */
  getVideoChapters(contentId: string, season: number = 1): Promise<NetworkResult<ChapterInfo[]>>;

  /**
   * 获取视频弹幕
   * @param contentId 内容ID
   * @param startTime 开始时�?   * @param endTime 结束时间
   * @returns 弹幕列表
   */
  getVideoDanmaku(contentId: string, startTime: number, endTime: number): Promise<NetworkResult<Record<string, string | number | boolean>[]>>;

  /**
   * 提交视频弹幕
   * @param contentId 内容ID
   * @param danmaku 弹幕内容
   * @param timestamp 时间�?   * @returns 提交结果
   */
  submitDanmaku(contentId: string, danmaku: string, timestamp: number): Promise<NetworkResult<boolean>>;

  // ========== 分类相关接口 ==========
  
  /**
   * 获取所有分�?   * @returns 分类列表
   */
  getCategories(): Promise<NetworkResult<Record<string, string[]>>>;

  /**
   * 获取类型列表
   * @returns 类型列表
   */
  getGenres(): Promise<NetworkResult<string[]>>;

  /**
   * 获取地区列表
   * @returns 地区列表
   */
  getRegions(): Promise<NetworkResult<string[]>>;

  /**
   * 获取年份列表
   * @returns 年份列表
   */
  getYears(): Promise<NetworkResult<number[]>>;

  // ========== 排行榜相关接�?==========
  
  /**
   * 获取排行�?   * @param type 排行榜类�?   * @param limit 限制数量
   * @returns 排行榜数�?   */
  getRankings(type: string, limit: number = 20): Promise<NetworkResult<Movie[]>>;

  /**
   * 获取本周热榜
   * @param limit 限制数量
   * @returns 热榜数据
   */
  getWeeklyHot(limit: number = 20): Promise<NetworkResult<Movie[]>>;

  /**
   * 获取本月新片
   * @param limit 限制数量
   * @returns 新片数据
   */
  getMonthlyNew(limit: number = 20): Promise<NetworkResult<Movie[]>>;

  // ========== 直播相关接口 ==========
  
  /**
   * 获取直播频道列表
   * @param category 频道分类
   * @returns 频道列表
   */
  getLiveChannels(category?: string): Promise<NetworkResult<LiveChannelInfo[]>>;

  /**
   * 获取直播EPG
   * @param channelId 频道ID
   * @returns EPG数据
   */
  getLiveEpg(channelId: string): Promise<NetworkResult<Record<string, string | number | boolean>>>;

  /**
   * 搜索直播频道
   * @param keyword 搜索关键�?   * @returns 匹配的频道列�?   */
  searchLiveChannels(keyword: string): Promise<NetworkResult<LiveChannelInfo[]>>;

  // ========== 解析器相关接�?==========
  
  /**
   * 获取所有解析器
   * @returns 解析器列�?   */
  getParsers(): Promise<NetworkResult<ParserInfo[]>>;

  /**
   * 检测解析器是否可用
   * @param parserId 解析器ID
   * @returns 可用性检测结�?   */
  checkParserAvailability(parserId: string): Promise<NetworkResult<boolean>>;

  // ========== 设置相关接口 ==========
  
  /**
   * 提交反馈
   * @param feedback 反馈内容
   * @param contact 联系方式
   * @returns 提交结果
   */
  submitFeedback(feedback: string, contact?: string): Promise<NetworkResult<boolean>>;

  /**
   * 检查更�?   * @param currentVersion 当前版本
   * @returns 更新信息
   */
  checkUpdate(currentVersion: string): Promise<NetworkResult<Record<string, string | number | boolean>>>;

  /**
   * 获取应用配置
   * @returns 应用配置
   */
  getAppConfig(): Promise<NetworkResult<Record<string, string | number | boolean>>>;

  /**
   * 获取公告信息
   * @returns 公告信息
   */
  getAnnouncements(): Promise<NetworkResult<string[]>>;

  // ========== 通用网络方法 ==========
  
  /**
   * 发送GET请求
   * @param url 请求URL
   * @param params 请求参数
   * @param headers 请求�?   * @returns 请求结果
   */
  get<T>(url: string, params?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 发送POST请求
   * @param url 请求URL
   * @param data 请求数据
   * @param headers 请求�?   * @returns 请求结果
   */
  post<T>(url: string, data?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 发送PUT请求
   * @param url 请求URL
   * @param data 请求数据
   * @param headers 请求�?   * @returns 请求结果
   */
  put<T>(url: string, data?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 发送DELETE请求
   * @param url 请求URL
   * @param params 请求参数
   * @param headers 请求�?   * @returns 请求结果
   */
  delete<T>(url: string, params?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 上传文件
   * @param url 上传URL
   * @param file 文件数据
   * @param params 其他参数
   * @param headers 请求�?   * @returns 上传结果
   */
  upload<T>(url: string, file: File, params?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 下载文件
   * @param url 下载URL
   * @param savePath 保存路径
   * @param headers 请求�?   * @returns 下载结果
   */
  download(url: string, savePath: string, headers?: Record<string, string>): Promise<NetworkResult<boolean>>;

  /**
   * 取消所有请�?   */
  cancelAllRequests(): void;

  /**
   * 取消指定请求
   * @param requestId 请求ID
   */
  cancelRequest(requestId: string): void;
}
