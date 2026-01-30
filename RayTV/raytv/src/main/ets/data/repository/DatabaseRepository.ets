/**
 * DatabaseRepository - 数据库仓储接口 | Database repository interface
 */
import Movie from '../model/Movie';
import User from '../model/User';
import History from '../model/History';
import SearchResult from '../model/SearchResult';

const TAG = 'DatabaseRepository';

/**
 * 数据库操作结果接口 | Database operation result interface
 */
export interface DatabaseResult<T> {
  success: boolean; // 是否成功 | Whether successful
  data?: T; // 数据 | Data
  error?: Error; // 错误 | Error
  message?: string; // 消息 | Message
}

/**
 * 分页参数接口 | Pagination parameters interface
 */
export interface PaginationParams {
  page: number; // 页码，从1开始 | Page number, starting from 1
  pageSize: number; // 每页数量 | Items per page
  sortBy?: string; // 排序字段 | Sort column
  sortOrder?: 'asc' | 'desc'; // 排序顺序 | Sort order
}

/**
 * 分页结果接口 | Paginated result interface
 */
export interface PaginatedResult<T> {
  items: T[]; // 当前页数据项 | Current page items
  totalCount: number; // 总数量 | Total count
  page: number; // 当前页码 | Current page number
  pageSize: number; // 每页数量 | Items per page
  totalPages: number; // 总页数 | Total pages
  hasNextPage: boolean; // 是否有下一页 | Whether has next page
  hasPrevPage: boolean; // 是否有上一页 | Whether has previous page
}

/**
 * 范围过滤接口 | Range filter interface
 */
export interface RangeFilter {
  min?: number; // 最小值 | Minimum value
  max?: number; // 最大值 | Maximum value
}

/**
 * 电影过滤接口 | Movie filter interface
 */
export interface MovieFilter {
  genres?: string[]; // 类型过滤 | Genre filter
  yearRange?: RangeFilter; // 年份范围 | Year range
  ratingRange?: RangeFilter; // 评分范围 | Rating range
  country?: string[]; // 国家/地区 | Country/region
  language?: string[]; // 语言 | Language
  isVip?: boolean; // 是否VIP内容 | Whether VIP content
  hasSubtitle?: boolean; // 是否有字幕 | Whether has subtitle
  sortBy?: 'year' | 'rating' | 'popularity' | 'releaseDate'; // 排序字段 | Sort column
  sortOrder?: 'asc' | 'desc'; // 排序顺序 | Sort order
}

/**
 * 配置值类型 | Config value type
 */
export type ConfigValue = string | number | boolean | Record<string, string | number | boolean | string[] | number[] | boolean[]> | string[] | number[] | boolean[];

/**
 * 数据库操作状态枚举 | Database operation status enum
 */
export enum DatabaseStatus {
  INITIALIZING = 'initializing', // 初始化中 | Initializing
  READY = 'ready', // 就绪 | Ready
  ERROR = 'error', // 错误 | Error
  CLOSING = 'closing', // 关闭中 | Closing
  CLOSED = 'closed' // 已关闭 | Closed
}

/**
 * 数据库仓储接口 | Database repository interface
 * 定义数据持久化操作的抽象方法 | Define abstract methods for data persistence operations
 */
export default interface DatabaseRepository {
  /**
   * 初始化数据库 | Initialize database
   * @returns 初始化结果 | Initialization result
   */
  initialize(): Promise<DatabaseResult<void>>;

  /**
   * 获取数据库状态 | Get database status
   * @returns 数据库状态 | Database status
   */
  getStatus(): DatabaseStatus;

  /**
   * 关闭数据库 | Close database
   * @returns 关闭结果 | Close result
   */
  close(): Promise<DatabaseResult<void>>;

  // ========== 电影/视频相关操作 ==========
  
  /**
   * 添加电影 | Add movie
   * @param movie 电影对象 | Movie object
   * @returns 操作结果 | Operation result
   */
  addMovie(movie: Movie): Promise<DatabaseResult<string>>;

  /**
   * 更新电影 | Update movie
   * @param movie 电影对象 | Movie object
   * @returns 操作结果 | Operation result
   */
  updateMovie(movie: Movie): Promise<DatabaseResult<boolean>>;

  /**
   * 删除电影 | Delete movie
   * @param movieId 电影ID | Movie ID
   * @returns 操作结果 | Operation result
   */
  deleteMovie(movieId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 根据ID获取电影 | Get movie by ID
   * @param movieId 电影ID | Movie ID
   * @returns 电影对象或null | Movie object or null
   */
  getMovieById(movieId: string): Promise<DatabaseResult<Movie | null>>;

  /**
   * 批量获取电影 | Batch get movies
   * @param movieIds 电影ID数组 | Movie ID array
   * @returns 电影对象数组 | Movie object array
   */
  getMoviesByIds(movieIds: string[]): Promise<DatabaseResult<Movie[]>>;

  /**
   * 分页获取电影列表 | Paginated get movie list
   * @param params 分页参数 | Pagination parameters
   * @param filters 过滤条件 | Filter conditions
   * @returns 分页结果 | Paginated result
   */
  getMoviesPaginated(
    params: PaginationParams,
    filters?: MovieFilter
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  /**
   * 搜索电影 | Search movies
   * @param keyword 搜索关键词 | Search keyword
   * @param params 分页参数 | Pagination parameters
   * @param filters 过滤条件 | Filter conditions
   * @returns 分页搜索结果 | Paginated search result
   */
  searchMovies(
    keyword: string,
    params: PaginationParams,
    filters?: MovieFilter
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  // ========== 用户相关操作 ==========
  
  /**
   * 添加用户 | Add user
   * @param user 用户对象 | User object
   * @returns 操作结果 | Operation result
   */
  addUser(user: User): Promise<DatabaseResult<string>>;

  /**
   * 更新用户 | Update user
   * @param user 用户对象 | User object
   * @returns 操作结果 | Operation result
   */
  updateUser(user: User): Promise<DatabaseResult<boolean>>;

  /**
   * 删除用户 | Delete user
   * @param userId 用户ID | User ID
   * @returns 操作结果 | Operation result
   */
  deleteUser(userId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 根据ID获取用户 | Get user by ID
   * @param userId 用户ID | User ID
   * @returns 用户对象或null | User object or null
   */
  getUserById(userId: string): Promise<DatabaseResult<User | null>>;

  /**
   * 获取所有用户 | Get all users
   * @returns 用户列表 | User list
   */
  getAllUsers(): Promise<DatabaseResult<User[]>>;

  /**
   * 根据用户名获取用户 | Get user by username
   * @param username 用户名 | Username
   * @returns 用户对象或null | User object or null
   */
  getUserByUsername(username: string): Promise<DatabaseResult<User | null>>;

  // ========== 观看历史相关操作 ==========
  
  /**
   * 添加或更新观看历史 | Add or update view history
   * @param history 历史记录对象 | History record object
   * @returns 操作结果 | Operation result
   */
  saveHistory(history: History): Promise<DatabaseResult<boolean>>;

  /**
   * 删除观看历史 | Delete view history
   * @param historyId 历史记录ID | History record ID
   * @returns 操作结果 | Operation result
   */
  deleteHistory(historyId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 根据用户ID删除所有历史记录 | Delete all history records by user ID
   * @param userId 用户ID | User ID
   * @returns 操作结果 | Operation result
   */
  deleteAllHistoryByUserId(userId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 根据ID获取历史记录 | Get history record by ID
   * @param historyId 历史记录ID | History record ID
   * @returns 历史记录对象或null | History record object or null
   */
  getHistoryById(historyId: string): Promise<DatabaseResult<History | null>>;

  /**
   * 获取用户的观看历史 | Get user's view history
   * @param userId 用户ID | User ID
   * @param params 分页参数 | Pagination parameters
   * @returns 分页历史记录结果 | Paginated history record result
   */
  getUserHistory(
    userId: string,
    params: PaginationParams
  ): Promise<DatabaseResult<PaginatedResult<History>>>;

  /**
   * 获取用户对特定内容的观看历史 | Get user's view history for specific content
   * @param userId 用户ID | User ID
   * @param contentId 内容ID | Content ID
   * @param contentType 内容类型 | Content type
   * @returns 历史记录对象或null | History record object or null
   */
  getUserContentHistory(
    userId: string,
    contentId: string,
    contentType: string
  ): Promise<DatabaseResult<History | null>>;

  /**
   * 获取最近观看的内容 | Get recently viewed content
   * @param userId 用户ID | User ID
   * @param limit 限制数量 | Limit count
   * @returns 历史记录列表 | History record list
   */
  getRecentHistory(
    userId: string,
    limit: number
  ): Promise<DatabaseResult<History[]>>;

  // ========== 收藏相关操作 ==========
  
  /**
   * 添加收藏 | Add favorite
   * @param userId 用户ID | User ID
   * @param movieId 电影ID | Movie ID
   * @param collectionName 收藏夹名称 | Collection name
   * @returns 操作结果 | Operation result
   */
  addFavorite(
    userId: string,
    movieId: string,
    collectionName?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 移除收藏 | Remove favorite
   * @param userId 用户ID | User ID
   * @param movieId 电影ID | Movie ID
   * @returns 操作结果 | Operation result
   */
  removeFavorite(
    userId: string,
    movieId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 检查是否已收藏 | Check if favorited
   * @param userId 用户ID | User ID
   * @param movieId 电影ID | Movie ID
   * @returns 是否已收藏 | Whether favorited
   */
  isFavorited(
    userId: string,
    movieId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取用户的收藏列表 | Get user's favorite list
   * @param userId 用户ID | User ID
   * @param params 分页参数 | Pagination parameters
   * @param collectionName 收藏夹名称（可选） | Collection name (optional)
   * @returns 分页收藏结果 | Paginated favorite result
   */
  getUserFavorites(
    userId: string,
    params: PaginationParams,
    collectionName?: string
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  /**
   * 获取用户的收藏夹列表 | Get user's collection list
   * @param userId 用户ID | User ID
   * @returns 收藏夹名称列表 | Collection name list
   */
  getUserCollections(
    userId: string
  ): Promise<DatabaseResult<string[]>>;

  // ========== 搜索历史相关操作 ==========
  
  /**
   * 添加搜索历史 | Add search history
   * @param userId 用户ID | User ID
   * @param keyword 搜索关键词 | Search keyword
   * @returns 操作结果 | Operation result
   */
  addSearchHistory(
    userId: string,
    keyword: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 删除搜索历史 | Delete search history
   * @param userId 用户ID | User ID
   * @param keyword 搜索关键词 | Search keyword
   * @returns 操作结果 | Operation result
   */
  deleteSearchHistory(
    userId: string,
    keyword: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 清除用户搜索历史 | Clear user's search history
   * @param userId 用户ID | User ID
   * @returns 操作结果 | Operation result
   */
  clearSearchHistory(
    userId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取用户搜索历史 | Get user's search history
   * @param userId 用户ID | User ID
   * @param limit 限制数量 | Limit count
   * @returns 搜索关键词列表 | Search keyword list
   */
  getUserSearchHistory(
    userId: string,
    limit: number
  ): Promise<DatabaseResult<string[]>>;

  // ========== 缓存相关操作 ==========
  
  /**
   * 缓存搜索结果 | Cache search results
   * @param keyword 搜索关键词 | Search keyword
   * @param results 搜索结果 | Search results
   * @param expirationTime 过期时间（分钟） | Expiration time (minutes)
   * @returns 操作结果 | Operation result
   */
  cacheSearchResults(
    keyword: string,
    results: SearchResult[],
    expirationTime?: number
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取缓存的搜索结果 | Get cached search results
   * @param keyword 搜索关键词 | Search keyword
   * @returns 缓存的搜索结果或null | Cached search results or null
   */
  getCachedSearchResults(
    keyword: string
  ): Promise<DatabaseResult<SearchResult[] | null>>;

  /**
   * 清除过期缓存 | Clear expired cache
   * @returns 清除的缓存项数量 | Number of cleared cache items
   */
  clearExpiredCache(): Promise<DatabaseResult<number>>;

  /**
   * 获取缓存大小 | Get cache size
   * @returns 缓存大小（字节） | Cache size (bytes)
   */
  getCacheSize(): Promise<DatabaseResult<number>>;

  /**
   * 清除所有缓存 | Clear all cache
   * @returns 操作结果 | Operation result
   */
  clearAllCache(): Promise<DatabaseResult<boolean>>;

  // ========== 配置相关操作 ==========
  
  /**
   * 保存配置值 | Save config value
   * @param key 配置键 | Config key
   * @param value 配置值 | Config value
   * @param group 配置分组 | Config group
   * @returns 操作结果 | Operation result
   */
  saveConfig(
    key: string,
    value: ConfigValue,
    group?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取配置值 | Get config value
   * @param key 配置键 | Config key
   * @param group 配置分组 | Config group
   * @returns 配置值 | Config value
   */
  getConfig(
    key: string,
    group?: string
  ): Promise<DatabaseResult<ConfigValue | null>>;

  /**
   * 删除配置值 | Delete config value
   * @param key 配置键 | Config key
   * @param group 配置分组 | Config group
   * @returns 操作结果 | Operation result
   */
  deleteConfig(
    key: string,
    group?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取配置分组 | Get config group
   * @param group 配置分组 | Config group
   * @returns 配置分组对象 | Config group object
   */
  getConfigGroup(
    group: string
  ): Promise<DatabaseResult<Record<string, ConfigValue>>>;

  /**
   * 清除配置分组 | Clear config group
   * @param group 配置分组 | Config group
   * @returns 操作结果 | Operation result
   */
  clearConfigGroup(
    group: string
  ): Promise<DatabaseResult<boolean>>;
}
