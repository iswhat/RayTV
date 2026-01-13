// NetworkRepository - 网络服务接口 | Network service interface
import Logger from '../../common/util/Logger';
import Movie from '../model/Movie';
import SearchResult from '../model/SearchResult';

const TAG = 'NetworkRepository';

/**
 * 网络请求结果接口 | Network request result interface
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
 * 网络请求配置接口 | Network request configuration interface
 */
export interface NetworkConfig {
  baseUrl: string;
  timeout: number;      // 超时时间（秒） | Timeout time (seconds)
  retryCount: number;   // 重试次数 | Retry count
  headers?: Record<string, string>;  // 默认请求头 | Default request headers
  params?: Record<string, string>;    // 默认参数 | Default parameters
  cacheEnabled?: boolean;  // 是否启用缓存 | Whether to enable cache
  cacheExpiry?: number;    // 缓存过期时间（秒） | Cache expiry time (seconds)
}

/**
 * 搜索参数接口 | Search parameters interface
 */
export interface SearchParams {
  keyword: string;        // 搜索关键词 | Search keyword
  page: number;           // 页码 | Page number
  pageSize: number;       // 每页数量 | Page size
  type?: string;          // 内容类型筛选 | Content type filter
  genre?: string;         // 类型筛选 | Genre filter
  year?: number;          // 年份筛选 | Year filter
  region?: string;        // 地区筛选 | Region filter
  sortBy?: string;        // 排序字段 | Sort field
  sortOrder?: 'asc' | 'desc'; // 排序顺序 | Sort order
  filters?: Record<string, string | number | boolean | string[]>; // 额外筛选条件 | Additional filter conditions
}

/**
 * 分页响应接口 | Paginated response interface
 */
export interface PaginatedResponse<T> {
  items: T[];             // 当前页数据 | Current page data
  total: number;          // 总数据量 | Total data count
  page: number;           // 当前页码 | Current page number
  pageSize: number;       // 每页数量 | Page size
  totalPages: number;     // 总页数 | Total pages
  hasMore: boolean;       // 是否有更多 | Whether there are more results
  extra?: Record<string, string | number | boolean | string[]>; // 额外信息 | Additional information
}

/**
 * 视频源接口 | Video source interface
 */
export interface VideoSourceInfo {
  id: string;             // 源ID | Source ID
  name: string;           // 源名称 | Source name
  url: string;            // 源URL | Source URL
  quality: string;        // 质量 | Quality
  format: string;         // 格式 | Format
  size?: number;          // 文件大小 | File size
  duration?: number;      // 时长 | Duration
  isDefault?: boolean;    // 是否默认 | Whether default
  headers?: Record<string, string>; // 请求头 | Request headers
  cookies?: string;       // Cookies
  extra?: Record<string, Record<string, string | number | boolean>>; // 额外信息 | Additional information
}

/**
 * 章节信息接口 | Chapter information interface
 */
export interface ChapterInfo {
  id: string;             // 章节ID | Chapter ID
  title: string;          // 章节标题 | Chapter title
  index: number;          // 章节索引 | Chapter index
  duration?: number;      // 章节时长 | Chapter duration
  startTime?: number;     // 开始时间点 | Start time point
  endTime?: number;       // 结束时间点 | End time point
  previewUrl?: string;    // 预览图URL | Preview image URL
  description?: string;   // 章节描述 | Chapter description
}

/**
 * 直播频道信息接口 | Live channel information interface
 */
export interface LiveChannelInfo {
  id: string;             // 频道ID | Channel ID
  name: string;           // 频道名称 | Channel name
  logo?: string;          // 频道Logo | Channel logo
  url: string;            // 播放URL | Playback URL
  category?: string;      // 频道分类 | Channel category
  country?: string;       // 所属国家 | Country
  language?: string;      // 语言 | Language
  description?: string;   // 频道描述 | Channel description
  epgUrl?: string;        // EPG节目单URL | EPG program guide URL
  nowPlaying?: string;    // 当前播放节目 | Currently playing program
  nextPlaying?: string;   // 下一个节目 | Next program
  isFavorite?: boolean;   // 是否收藏 | Whether favorite
  sortOrder?: number;     // 排序顺序 | Sort order
  extra?: Record<string, Record<string, string | number | boolean>>; // 额外信息 | Additional information
}

/**
 * 解析器接口 | Parser interface
 */
export interface ParserInfo {
  id: string;             // 解析器ID | Parser ID
  name: string;           // 解析器名称 | Parser name
  description?: string;   // 解析器描述 | Parser description
  supports?: string[];    // 支持的网站列表 | Supported websites
  version?: string;       // 版本 | Version
  isEnabled?: boolean;    // 是否启用 | Whether enabled
  config?: Record<string, Record<string, string | number | boolean>>; // 解析器配置 | Parser configuration
}

/**
 * 网络仓库接口 | Network repository interface
 * 定义与外部数据源交互的合作方式 | Define cooperation methods for interacting with external data sources
 */
export default interface NetworkRepository {
  /**
   * 初始化网络服务 | Initialize network service
   * @param config 网络配置 | Network configuration
   * @returns 初始化结果 | Initialization result
   */
  initialize(config: NetworkConfig): Promise<NetworkResult<void>>;

  /**
   * 设置网络配置 | Set network configuration
   * @param config 网络配置 | Network configuration
   */
  setConfig(config: Partial<NetworkConfig>): void;

  /**
   * 获取当前网络配置 | Get current network configuration
   * @returns 网络配置 | Network configuration
   */
  getConfig(): NetworkConfig;

  // ========== 搜索相关接口 ========== | ========== Search related interfaces ==========
  
  /**
   * 搜索内容 | Search content
   * @param params 搜索参数 | Search parameters
   * @returns 搜索结果 | Search result
   */
  searchContent(params: SearchParams): Promise<NetworkResult<PaginatedResponse<SearchResult>>>;

  /**
   * 获取热门搜索关键词 | Get hot search keywords
   * @param limit 限制数量 | Limit count
   * @returns 热门搜索关键词列表 | Hot search keywords list
   */
  getHotSearchKeywords(limit: number): Promise<NetworkResult<string[]>>;

  /**
   * 获取搜索建议 | Get search suggestions
   * @param keyword 搜索关键词 | Search keyword
   * @param limit 限制数量 | Limit count
   * @returns 搜索建议列表 | Search suggestions list
   */
  getSearchSuggestions(keyword: string, limit: number): Promise<NetworkResult<string[]>>;

  // ========== 影视/视频相关接口 ========== | ========== Movie/Video related interfaces ==========
  
  /**
   * 获取电影详情 | Get movie detail
   * @param movieId 电影ID | Movie ID
   * @returns 电影详情 | Movie detail
   */
  getMovieDetail(movieId: string): Promise<NetworkResult<Movie>>;

  /**
   * 获取电影列表 | Get movie list
   * @param params 分页参数 | Pagination parameters
   * @returns 电影列表 | Movie list
   */
  getMovieList(params: SearchParams): Promise<NetworkResult<PaginatedResponse<Movie>>>;

  /**
   * 获取推荐电影 | Get recommended movies
   * @param movieId 当前电影ID | Current movie ID
   * @param limit 限制数量 | Limit count
   * @returns 推荐电影列表 | Recommended movies list
   */
  getRecommendedMovies(movieId: string, limit: number): Promise<NetworkResult<Movie[]>>;

  /**
   * 获取相关电影 | Get related movies
   * @param movieId 当前电影ID | Current movie ID
   * @param limit 限制数量 | Limit count
   * @returns 相关电影列表 | Related movies list
   */
  getRelatedMovies(movieId: string, limit: number): Promise<NetworkResult<Movie[]>>;

  /**
   * 获取电影评分 | Get movie rating
   * @param movieId 电影ID | Movie ID
   * @returns 评分信息 | Rating information
   */
  getMovieRating(movieId: string): Promise<NetworkResult<Record<string, string | number | boolean>>>;

  // ========== 视频播放相关接口 ========== | ========== Video playback related interfaces ==========
  
  /**
   * 获取视频源列表 | Get video sources list
   * @param contentId 内容ID | Content ID
   * @param contentType 内容类型 | Content type
   * @returns 视频源列表 | Video sources list
   */
  getVideoSources(contentId: string, contentType: string): Promise<NetworkResult<VideoSourceInfo[]>>;

  /**
   * 解析视频源 | Parse video source
   * @param sourceUrl 视频源URL | Video source URL
   * @param parserId 解析器ID（可选） | Parser ID (optional)
   * @returns 解析后的视频信息 | Parsed video information
   */
  parseVideoSource(sourceUrl: string, parserId?: string): Promise<NetworkResult<VideoSourceInfo>>;

  /**
   * 获取视频章节列表 | Get video chapters list
   * @param contentId 内容ID | Content ID
   * @param season 季数 | Season number
   * @returns 章节列表 | Chapters list
   */
  getVideoChapters(contentId: string, season: number): Promise<NetworkResult<ChapterInfo[]>>;

  /**
   * 获取视频弹幕 | Get video danmaku
   * @param contentId 内容ID | Content ID
   * @param startTime 开始时间 | Start time
   * @param endTime 结束时间 | End time
   * @returns 弹幕列表 | Danmaku list
   */
  getVideoDanmaku(contentId: string, startTime: number, endTime: number): Promise<NetworkResult<Record<string, string | number | boolean>[]>>;

  /**
   * 鎻愪氦瑙嗛寮瑰箷
   * @param contentId 鍐呭ID
   * @param danmaku 寮瑰箷鍐呭
   * @param timestamp 鏃堕棿鎴?
   * @returns 鎻愪氦缁撴灉
   */
  submitDanmaku(contentId: string, danmaku: string, timestamp: number): Promise<NetworkResult<boolean>>;

  // ========== 鍒嗙被鐩稿叧鎺ュ彛 ==========
  
  /**
   * 鑾峰彇鎵€鏈夊垎绫?
   * @returns 鍒嗙被鍒楄〃
   */
  getCategories(): Promise<NetworkResult<Record<string, string[]>>>;

  /**
   * 鑾峰彇绫诲瀷鍒楄〃
   * @returns 绫诲瀷鍒楄〃
   */
  getGenres(): Promise<NetworkResult<string[]>>;

  /**
   * 鑾峰彇鍦板尯鍒楄〃
   * @returns 鍦板尯鍒楄〃
   */
  getRegions(): Promise<NetworkResult<string[]>>;

  /**
   * 鑾峰彇骞翠唤鍒楄〃
   * @returns 骞翠唤鍒楄〃
   */
  getYears(): Promise<NetworkResult<number[]>>;

  // ========== 鎺掕姒滅浉鍏虫帴鍙?==========
  
  /**
   * 鑾峰彇鎺掕姒?
   * @param type 鎺掕姒滅被鍨?
   * @param limit 闄愬埗鏁伴噺
   * @returns 鎺掕姒滄暟鎹?
   */
  getRankings(type: string, limit: number): Promise<NetworkResult<Movie[]>>;

  /**
   * 鑾峰彇鏈懆鐑
   * @param limit 闄愬埗鏁伴噺
   * @returns 鐑鏁版嵁
   */
  getWeeklyHot(limit: number): Promise<NetworkResult<Movie[]>>;

  /**
   * 鑾峰彇鏈湀鏂扮墖
   * @param limit 闄愬埗鏁伴噺
   * @returns 鏂扮墖鏁版嵁
   */
  getMonthlyNew(limit: number): Promise<NetworkResult<Movie[]>>;

  // ========== 鐩存挱鐩稿叧鎺ュ彛 ==========
  
  /**
   * 鑾峰彇鐩存挱棰戦亾鍒楄〃
   * @param category 棰戦亾鍒嗙被
   * @returns 棰戦亾鍒楄〃
   */
  getLiveChannels(category?: string): Promise<NetworkResult<LiveChannelInfo[]>>;

  /**
   * 鑾峰彇鐩存挱EPG
   * @param channelId 棰戦亾ID
   * @returns EPG鏁版嵁
   */
  getLiveEpg(channelId: string): Promise<NetworkResult<Record<string, string | number | boolean>>>;

  /**
   * 鎼滅储鐩存挱棰戦亾
   * @param keyword 鎼滅储鍏抽敭璇?  * @returns 鍖归厤鐨勯閬撳垪琛?
   */
  searchLiveChannels(keyword: string): Promise<NetworkResult<LiveChannelInfo[]>>;

  // ========== 瑙ｆ瀽鍣ㄧ浉鍏虫帴鍙?==========
  
  /**
   * 鑾峰彇鎵€鏈夎В鏋愬櫒
   * @returns 瑙ｆ瀽鍣ㄥ垪琛?
   */
  getParsers(): Promise<NetworkResult<ParserInfo[]>>;

  /**
   * 妫€娴嬭В鏋愬櫒鏄惁鍙敤
   * @param parserId 瑙ｆ瀽鍣↖D
   * @returns 鍙敤鎬ф娴嬬粨鏋?
   */
  checkParserAvailability(parserId: string): Promise<NetworkResult<boolean>>;

  // ========== 璁剧疆鐩稿叧鎺ュ彛 ==========
  
  /**
   * 鎻愪氦鍙嶉
   * @param feedback 鍙嶉鍐呭
   * @param contact 鑱旂郴鏂瑰紡
   * @returns 鎻愪氦缁撴灉
   */
  submitFeedback(feedback: string, contact?: string): Promise<NetworkResult<boolean>>;

  /**
   * 妫€鏌ユ洿鏂?
   * @param currentVersion 褰撳墠鐗堟湰
   * @returns 鏇存柊淇℃伅
   */
  checkUpdate(currentVersion: string): Promise<NetworkResult<Record<string, string | number | boolean>>>;

  /**
   * 鑾峰彇搴旂敤閰嶇疆
   * @returns 搴旂敤閰嶇疆
   */
  getAppConfig(): Promise<NetworkResult<Record<string, string | number | boolean>>>;

  /**
   * 鑾峰彇鍏憡淇℃伅
   * @returns 鍏憡淇℃伅
   */
  getAnnouncements(): Promise<NetworkResult<string[]>>;

  // ========== 閫氱敤缃戠粶鏂规硶 ==========
  
  /**
   * 鍙戦€丟ET璇锋眰
   * @param url 璇锋眰URL
   * @param params 璇锋眰鍙傛暟
   * @param headers 璇锋眰澶?
   * @returns 璇锋眰缁撴灉
   */
  get<T>(url: string, params?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 鍙戦€丳OST璇锋眰
   * @param url 璇锋眰URL
   * @param data 璇锋眰鏁版嵁
   * @param headers 璇锋眰澶?
   * @returns 璇锋眰缁撴灉
   */
  post<T>(url: string, data?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 鍙戦€丳UT璇锋眰
   * @param url 璇锋眰URL
   * @param data 璇锋眰鏁版嵁
   * @param headers 璇锋眰澶?
   * @returns 璇锋眰缁撴灉
   */
  put<T>(url: string, data?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 鍙戦€丏ELETE璇锋眰
   * @param url 璇锋眰URL
   * @param params 璇锋眰鍙傛暟
   * @param headers 璇锋眰澶?
   * @returns 璇锋眰缁撴灉
   */
  delete<T>(url: string, params?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 涓婁紶鏂囦欢
   * @param url 涓婁紶URL
   * @param file 鏂囦欢鏁版嵁
   * @param params 鍏朵粬鍙傛暟
   * @param headers 璇锋眰澶?
   * @returns 涓婁紶缁撴灉
   */
  upload<T>(url: string, file: ArrayBuffer, params?: Record<string, string | number | boolean | string[]>, headers?: Record<string, string>): Promise<NetworkResult<T>>;

  /**
   * 涓嬭浇鏂囦欢
   * @param url 涓嬭浇URL
   * @param savePath 淇濆瓨璺緞
   * @param headers 璇锋眰澶?
   * @returns 涓嬭浇缁撴灉
   */
  download(url: string, savePath: string, headers?: Record<string, string>): Promise<NetworkResult<boolean>>;

  /**
   * 鍙栨秷鎵€鏈夎姹?
   */
  cancelAllRequests(): void;

  /**
   * 鍙栨秷鎸囧畾璇锋眰
   * @param requestId 璇锋眰ID
   */
  cancelRequest(requestId: string): void;
}



