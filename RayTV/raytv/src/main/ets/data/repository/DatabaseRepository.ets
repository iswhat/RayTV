// DatabaseRepository - 数据库访问接口
import Logger from '../../common/util/Logger';
import Movie from '../model/Movie';
import User from '../model/User';
import History from '../model/History';
import SearchResult from '../model/SearchResult';

const TAG = 'DatabaseRepository';

/**
 * 数据库操作结果接口
 */
export interface DatabaseResult<T> {
  success: boolean;
  data?: T;
  error?: Error;
  message?: string;
}

/**
 * 分页参数接口
 */
export interface PaginationParams {
  page: number;           // 页码，从1开始
  pageSize: number;       // 每页数量
  sortBy?: string;        // 排序字段
  sortOrder?: 'asc' | 'desc'; // 排序顺序
}

/**
 * 分页结果接口
 */
export interface PaginatedResult<T> {
  items: T[];             // 当前页数据项
  totalCount: number;     // 总数量
  page: number;           // 当前页码
  pageSize: number;       // 每页数量
  totalPages: number;     // 总页数
  hasNextPage: boolean;   // 是否有下一页
  hasPrevPage: boolean;   // 是否有上一页
}

/**
 * 范围筛选接口
 */
export interface RangeFilter {
  min?: number;
  max?: number;
}

/**
 * 电影筛选条件接口
 */
export interface MovieFilter {
  genres?: string[];      // 类型筛选
  yearRange?: RangeFilter; // 年份范围
  ratingRange?: RangeFilter; // 评分范围
  country?: string[];     // 国家/地区
  language?: string[];    // 语言
  isVip?: boolean;       // 是否VIP内容
  hasSubtitle?: boolean; // 是否有字幕
  sortBy?: 'year' | 'rating' | 'popularity' | 'releaseDate'; // 排序字段
  sortOrder?: 'asc' | 'desc'; // 排序顺序
}

/**
 * 配置值类型
 */
export type ConfigValue = string | number | boolean | Record<string, string | number | boolean | null> | string[] | number[] | boolean[];

/**
 * 数据库操作状态枚举
 */
export enum DatabaseStatus {
  INITIALIZING = 'initializing',
  READY = 'ready',
  ERROR = 'error',
  CLOSING = 'closing',
  CLOSED = 'closed'
}

/**
 * 数据库仓库接口
 * 定义数据持久化操作的抽象方法
 */
export default interface DatabaseRepository {
  /**
   * 初始化数据库
   * @returns 初始化结果
   */
  initialize(): Promise<DatabaseResult<void>>;

  /**
   * 获取数据库状态
   * @returns 数据库状态
   */
  getStatus(): DatabaseStatus;

  /**
   * 关闭数据库
   * @returns 关闭结果
   */
  close(): Promise<DatabaseResult<void>>;

  // ========== 电影/视频相关操作 ==========
  
  /**
   * 添加电影
   * @param movie 电影对象
   * @returns 操作结果
   */
  addMovie(movie: Movie): Promise<DatabaseResult<string>>;

  /**
   * 更新电影
   * @param movie 电影对象
   * @returns 操作结果
   */
  updateMovie(movie: Movie): Promise<DatabaseResult<boolean>>;

  /**
   * 删除电影
   * @param movieId 电影ID
   * @returns 操作结果
   */
  deleteMovie(movieId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 根据ID获取电影
   * @param movieId 电影ID
   * @returns 电影对象或null
   */
  getMovieById(movieId: string): Promise<DatabaseResult<Movie | null>>;

  /**
   * 批量获取电影
   * @param movieIds 电影ID数组
   * @returns 电影对象数组
   */
  getMoviesByIds(movieIds: string[]): Promise<DatabaseResult<Movie[]>>;

  /**
   * 分页获取电影列表
   * @param params 分页参数
   * @param filters 筛选条件
   * @returns 分页结果
   */
  getMoviesPaginated(
    params: PaginationParams,
    filters?: MovieFilter
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  /**
   * 搜索电影
   * @param keyword 搜索关键词
   * @param params 分页参数
   * @param filters 筛选条件
   * @returns 分页搜索结果
   */
  searchMovies(
    keyword: string,
    params: PaginationParams,
    filters?: MovieFilter
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  // ========== 用户相关操作 ==========
  
  /**
   * 添加用户
   * @param user 用户对象
   * @returns 操作结果
   */
  addUser(user: User): Promise<DatabaseResult<string>>;

  /**
   * 更新用户
   * @param user 用户对象
   * @returns 操作结果
   */
  updateUser(user: User): Promise<DatabaseResult<boolean>>;

  /**
   * 删除用户
   * @param userId 用户ID
   * @returns 操作结果
   */
  deleteUser(userId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 根据ID获取用户
   * @param userId 用户ID
   * @returns 用户对象或null
   */
  getUserById(userId: string): Promise<DatabaseResult<User | null>>;

  /**
   * 获取所有用户
   * @returns 用户列表
   */
  getAllUsers(): Promise<DatabaseResult<User[]>>;

  /**
   * 根据用户名获取用户
   * @param username 用户名
   * @returns 用户对象或null
   */
  getUserByUsername(username: string): Promise<DatabaseResult<User | null>>;

  // ========== 观看历史相关操作 ==========
  
  /**
   * 添加或更新观看历史
   * @param history 历史记录对象
   * @returns 操作结果
   */
  saveHistory(history: History): Promise<DatabaseResult<boolean>>;

  /**
   * 删除观看历史
   * @param historyId 历史记录ID
   * @returns 操作结果
   */
  deleteHistory(historyId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 根据用户ID删除所有历史记录
   * @param userId 用户ID
   * @returns 操作结果
   */
  deleteAllHistoryByUserId(userId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 根据ID获取历史记录
   * @param historyId 历史记录ID
   * @returns 历史记录对象或null
   */
  getHistoryById(historyId: string): Promise<DatabaseResult<History | null>>;

  /**
   * 获取用户的观看历史
   * @param userId 用户ID
   * @param params 分页参数
   * @returns 分页历史记录结果
   */
  getUserHistory(
    userId: string,
    params: PaginationParams
  ): Promise<DatabaseResult<PaginatedResult<History>>>;

  /**
   * 获取用户对特定内容的观看历史
   * @param userId 用户ID
   * @param contentId 内容ID
   * @param contentType 内容类型
   * @returns 历史记录对象或null
   */
  getUserContentHistory(
    userId: string,
    contentId: string,
    contentType: string
  ): Promise<DatabaseResult<History | null>>;

  /**
   * 获取最近观看的内容
   * @param userId 用户ID
   * @param limit 限制数量
   * @returns 历史记录列表
   */
  getRecentHistory(
    userId: string,
    limit: number = 20
  ): Promise<DatabaseResult<History[]>>;

  // ========== 收藏相关操作 ==========
  
  /**
   * 添加收藏
   * @param userId 用户ID
   * @param movieId 电影ID
   * @param collectionName 收藏集名称
   * @returns 操作结果
   */
  addFavorite(
    userId: string,
    movieId: string,
    collectionName?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 移除收藏
   * @param userId 用户ID
   * @param movieId 电影ID
   * @returns 操作结果
   */
  removeFavorite(
    userId: string,
    movieId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 检查是否已收藏
   * @param userId 用户ID
   * @param movieId 电影ID
   * @returns 是否已收藏
   */
  isFavorited(
    userId: string,
    movieId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取用户的收藏列表
   * @param userId 用户ID
   * @param params 分页参数
   * @param collectionName 收藏集名称（可选）
   * @returns 分页收藏结果
   */
  getUserFavorites(
    userId: string,
    params: PaginationParams,
    collectionName?: string
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  /**
   * 获取用户的收藏集列表
   * @param userId 用户ID
   * @returns 收藏集名称列表
   */
  getUserCollections(
    userId: string
  ): Promise<DatabaseResult<string[]>>;

  // ========== 搜索历史相关操作 ==========
  
  /**
   * 添加搜索历史
   * @param userId 用户ID
   * @param keyword 搜索关键词
   * @returns 操作结果
   */
  addSearchHistory(
    userId: string,
    keyword: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 删除搜索历史
   * @param userId 用户ID
   * @param keyword 搜索关键词
   * @returns 操作结果
   */
  deleteSearchHistory(
    userId: string,
    keyword: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 清空用户搜索历史
   * @param userId 用户ID
   * @returns 操作结果
   */
  clearSearchHistory(
    userId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取用户搜索历史
   * @param userId 用户ID
   * @param limit 限制数量
   * @returns 搜索关键词列表
   */
  getUserSearchHistory(
    userId: string,
    limit: number = 50
  ): Promise<DatabaseResult<string[]>>;

  // ========== 缓存相关操作 ==========
  
  /**
   * 缓存搜索结果
   * @param keyword 搜索关键词
   * @param results 搜索结果
   * @param expirationTime 过期时间（毫秒）
   * @returns 操作结果
   */
  cacheSearchResults(
    keyword: string,
    results: SearchResult[],
    expirationTime?: number
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取缓存的搜索结果
   * @param keyword 搜索关键词
   * @returns 缓存的搜索结果或null
   */
  getCachedSearchResults(
    keyword: string
  ): Promise<DatabaseResult<SearchResult[] | null>>;

  /**
   * 清除过期缓存
   * @returns 清除的缓存项数量
   */
  clearExpiredCache(): Promise<DatabaseResult<number>>;

  /**
   * 获取缓存大小
   * @returns 缓存大小（字节）
   */
  getCacheSize(): Promise<DatabaseResult<number>>;

  /**
   * 清空所有缓存
   * @returns 操作结果
   */
  clearAllCache(): Promise<DatabaseResult<boolean>>;

  // ========== 配置相关操作 ==========
  
  /**
   * 保存配置项
   * @param key 配置键
   * @param value 配置值
   * @param group 配置分组
   * @returns 操作结果
   */
  saveConfig(
    key: string,
    value: ConfigValue,
    group?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取配置项
   * @param key 配置键
   * @param group 配置分组
   * @returns 配置值
   */
  getConfig(
    key: string,
    group?: string
  ): Promise<DatabaseResult<ConfigValue | null>>;

  /**
   * 删除配置项
   * @param key 配置键
   * @param group 配置分组
   * @returns 操作结果
   */
  deleteConfig(
    key: string,
    group?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 获取配置分组
   * @param group 配置分组
   * @returns 配置分组对象
   */
  getConfigGroup(
    group: string
  ): Promise<DatabaseResult<Record<string, ConfigValue>>>;

  /**
   * 清空配置分组
   * @param group 配置分组
   * @returns 操作结果
   */
  clearConfigGroup(
    group: string
  ): Promise<DatabaseResult<boolean>>;
}