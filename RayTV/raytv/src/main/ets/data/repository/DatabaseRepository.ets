// DatabaseRepository - 鏁版嵁搴撹闂帴鍙?
import Logger from '../../common/util/Logger';
import Movie from '../model/Movie';
import User from '../model/User';
import History from '../model/History';
import SearchResult from '../model/SearchResult';

const TAG = 'DatabaseRepository';

/**
 * 鏁版嵁搴撴搷浣滅粨鏋滄帴鍙?
 */
export interface DatabaseResult<T> {
  success: boolean;
  data?: T;
  error?: Error;
  message?: string;
}

/**
 * 鍒嗛〉鍙傛暟鎺ュ彛
 */
export interface PaginationParams {
  page: number;           // 椤电爜锛屼粠1寮€濮?
  pageSize: number;       // 姣忛〉鏁伴噺
  sortBy?: string;        // 鎺掑簭瀛楁
  sortOrder?: 'asc' | 'desc'; // 鎺掑簭椤哄簭
}

/**
 * 鍒嗛〉缁撴灉鎺ュ彛
 */
export interface PaginatedResult<T> {
  items: T[];             // 褰撳墠椤垫暟鎹」
  totalCount: number;     // 鎬绘暟閲?
  page: number;           // 褰撳墠椤电爜
  pageSize: number;       // 姣忛〉鏁伴噺
  totalPages: number;     // 鎬婚〉鏁?
  hasNextPage: boolean;   // 鏄惁鏈変笅涓€椤?
  hasPrevPage: boolean;   // 鏄惁鏈変笂涓€椤?
}

/**
 * 鑼冨洿绛涢€夋帴鍙?
 */
export interface RangeFilter {
  min?: number;
  max?: number;
}

/**
 * 鐢靛奖绛涢€夋潯浠舵帴鍙?
 */
export interface MovieFilter {
  genres?: string[];      // 绫诲瀷绛涢€?
  yearRange?: RangeFilter; // 骞翠唤鑼冨洿
  ratingRange?: RangeFilter; // 璇勫垎鑼冨洿
  country?: string[];     // 鍥藉/鍦板尯
  language?: string[];    // 璇█
  isVip?: boolean;       // 鏄惁VIP鍐呭
  hasSubtitle?: boolean; // 鏄惁鏈夊瓧骞?
  sortBy?: 'year' | 'rating' | 'popularity' | 'releaseDate'; // 鎺掑簭瀛楁
  sortOrder?: 'asc' | 'desc'; // 鎺掑簭椤哄簭
}

/**
 * 閰嶇疆鍊肩被鍨?
 */
export type ConfigValue = string | number | boolean | Record<string, string | number | boolean | string[] | number[] | boolean[]> | string[] | number[] | boolean[];

/**
 * 鏁版嵁搴撴搷浣滅姸鎬佹灇涓?
 */
export enum DatabaseStatus {
  INITIALIZING = 'initializing',
  READY = 'ready',
  ERROR = 'error',
  CLOSING = 'closing',
  CLOSED = 'closed'
}

/**
 * 鏁版嵁搴撲粨搴撴帴鍙?
 * 瀹氫箟鏁版嵁鎸佷箙鍖栨搷浣滅殑鎶借薄鏂规硶
 */
export default interface DatabaseRepository {
  /**
   * 鍒濆鍖栨暟鎹簱
   * @returns 鍒濆鍖栫粨鏋?
   */
  initialize(): Promise<DatabaseResult<void>>;

  /**
   * 鑾峰彇鏁版嵁搴撶姸鎬?
   * @returns 鏁版嵁搴撶姸鎬?
   */
  getStatus(): DatabaseStatus;

  /**
   * 鍏抽棴鏁版嵁搴?
   * @returns 鍏抽棴缁撴灉
   */
  close(): Promise<DatabaseResult<void>>;

  // ========== 鐢靛奖/瑙嗛鐩稿叧鎿嶄綔 ==========
  
  /**
   * 娣诲姞鐢靛奖
   * @param movie 鐢靛奖瀵硅薄
   * @returns 鎿嶄綔缁撴灉
   */
  addMovie(movie: Movie): Promise<DatabaseResult<string>>;

  /**
   * 鏇存柊鐢靛奖
   * @param movie 鐢靛奖瀵硅薄
   * @returns 鎿嶄綔缁撴灉
   */
  updateMovie(movie: Movie): Promise<DatabaseResult<boolean>>;

  /**
   * 鍒犻櫎鐢靛奖
   * @param movieId 鐢靛奖ID
   * @returns 鎿嶄綔缁撴灉
   */
  deleteMovie(movieId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 鏍规嵁ID鑾峰彇鐢靛奖
   * @param movieId 鐢靛奖ID
   * @returns 鐢靛奖瀵硅薄鎴杗ull
   */
  getMovieById(movieId: string): Promise<DatabaseResult<Movie | null>>;

  /**
   * 鎵归噺鑾峰彇鐢靛奖
   * @param movieIds 鐢靛奖ID鏁扮粍
   * @returns 鐢靛奖瀵硅薄鏁扮粍
   */
  getMoviesByIds(movieIds: string[]): Promise<DatabaseResult<Movie[]>>;

  /**
   * 鍒嗛〉鑾峰彇鐢靛奖鍒楄〃
   * @param params 鍒嗛〉鍙傛暟
   * @param filters 绛涢€夋潯浠?
   * @returns 鍒嗛〉缁撴灉
   */
  getMoviesPaginated(
    params: PaginationParams,
    filters?: MovieFilter
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  /**
   * 鎼滅储鐢靛奖
   * @param keyword 鎼滅储鍏抽敭璇?
   * @param params 鍒嗛〉鍙傛暟
   * @param filters 绛涢€夋潯浠?
   * @returns 鍒嗛〉鎼滅储缁撴灉
   */
  searchMovies(
    keyword: string,
    params: PaginationParams,
    filters?: MovieFilter
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  // ========== 鐢ㄦ埛鐩稿叧鎿嶄綔 ==========
  
  /**
   * 娣诲姞鐢ㄦ埛
   * @param user 鐢ㄦ埛瀵硅薄
   * @returns 鎿嶄綔缁撴灉
   */
  addUser(user: User): Promise<DatabaseResult<string>>;

  /**
   * 鏇存柊鐢ㄦ埛
   * @param user 鐢ㄦ埛瀵硅薄
   * @returns 鎿嶄綔缁撴灉
   */
  updateUser(user: User): Promise<DatabaseResult<boolean>>;

  /**
   * 鍒犻櫎鐢ㄦ埛
   * @param userId 鐢ㄦ埛ID
   * @returns 鎿嶄綔缁撴灉
   */
  deleteUser(userId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 鏍规嵁ID鑾峰彇鐢ㄦ埛
   * @param userId 鐢ㄦ埛ID
   * @returns 鐢ㄦ埛瀵硅薄鎴杗ull
   */
  getUserById(userId: string): Promise<DatabaseResult<User | null>>;

  /**
   * 鑾峰彇鎵€鏈夌敤鎴?
   * @returns 鐢ㄦ埛鍒楄〃
   */
  getAllUsers(): Promise<DatabaseResult<User[]>>;

  /**
   * 鏍规嵁鐢ㄦ埛鍚嶈幏鍙栫敤鎴?
   * @param username 鐢ㄦ埛鍚?
   * @returns 鐢ㄦ埛瀵硅薄鎴杗ull
   */
  getUserByUsername(username: string): Promise<DatabaseResult<User | null>>;

  // ========== 瑙傜湅鍘嗗彶鐩稿叧鎿嶄綔 ==========
  
  /**
   * 娣诲姞鎴栨洿鏂拌鐪嬪巻鍙?
   * @param history 鍘嗗彶璁板綍瀵硅薄
   * @returns 鎿嶄綔缁撴灉
   */
  saveHistory(history: History): Promise<DatabaseResult<boolean>>;

  /**
   * 鍒犻櫎瑙傜湅鍘嗗彶
   * @param historyId 鍘嗗彶璁板綍ID
   * @returns 鎿嶄綔缁撴灉
   */
  deleteHistory(historyId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 鏍规嵁鐢ㄦ埛ID鍒犻櫎鎵€鏈夊巻鍙茶褰?
   * @param userId 鐢ㄦ埛ID
   * @returns 鎿嶄綔缁撴灉
   */
  deleteAllHistoryByUserId(userId: string): Promise<DatabaseResult<boolean>>;

  /**
   * 鏍规嵁ID鑾峰彇鍘嗗彶璁板綍
   * @param historyId 鍘嗗彶璁板綍ID
   * @returns 鍘嗗彶璁板綍瀵硅薄鎴杗ull
   */
  getHistoryById(historyId: string): Promise<DatabaseResult<History | null>>;

  /**
   * 鑾峰彇鐢ㄦ埛鐨勮鐪嬪巻鍙?
   * @param userId 鐢ㄦ埛ID
   * @param params 鍒嗛〉鍙傛暟
   * @returns 鍒嗛〉鍘嗗彶璁板綍缁撴灉
   */
  getUserHistory(
    userId: string,
    params: PaginationParams
  ): Promise<DatabaseResult<PaginatedResult<History>>>;

  /**
   * 鑾峰彇鐢ㄦ埛瀵圭壒瀹氬唴瀹圭殑瑙傜湅鍘嗗彶
   * @param userId 鐢ㄦ埛ID
   * @param contentId 鍐呭ID
   * @param contentType 鍐呭绫诲瀷
   * @returns 鍘嗗彶璁板綍瀵硅薄鎴杗ull
   */
  getUserContentHistory(
    userId: string,
    contentId: string,
    contentType: string
  ): Promise<DatabaseResult<History | null>>;

  /**
   * 鑾峰彇鏈€杩戣鐪嬬殑鍐呭
   * @param userId 鐢ㄦ埛ID
   * @param limit 闄愬埗鏁伴噺
   * @returns 鍘嗗彶璁板綍鍒楄〃
   */
  getRecentHistory(
    userId: string,
    limit: number
  ): Promise<DatabaseResult<History[]>>;

  // ========== 鏀惰棌鐩稿叧鎿嶄綔 ==========
  
  /**
   * 娣诲姞鏀惰棌
   * @param userId 鐢ㄦ埛ID
   * @param movieId 鐢靛奖ID
   * @param collectionName 鏀惰棌闆嗗悕绉?
   * @returns 鎿嶄綔缁撴灉
   */
  addFavorite(
    userId: string,
    movieId: string,
    collectionName?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 绉婚櫎鏀惰棌
   * @param userId 鐢ㄦ埛ID
   * @param movieId 鐢靛奖ID
   * @returns 鎿嶄綔缁撴灉
   */
  removeFavorite(
    userId: string,
    movieId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 妫€鏌ユ槸鍚﹀凡鏀惰棌
   * @param userId 鐢ㄦ埛ID
   * @param movieId 鐢靛奖ID
   * @returns 鏄惁宸叉敹钘?
   */
  isFavorited(
    userId: string,
    movieId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 鑾峰彇鐢ㄦ埛鐨勬敹钘忓垪琛?
   * @param userId 鐢ㄦ埛ID
   * @param params 鍒嗛〉鍙傛暟
   * @param collectionName 鏀惰棌闆嗗悕绉帮紙鍙€夛級
   * @returns 鍒嗛〉鏀惰棌缁撴灉
   */
  getUserFavorites(
    userId: string,
    params: PaginationParams,
    collectionName?: string
  ): Promise<DatabaseResult<PaginatedResult<Movie>>>;

  /**
   * 鑾峰彇鐢ㄦ埛鐨勬敹钘忛泦鍒楄〃
   * @param userId 鐢ㄦ埛ID
   * @returns 鏀惰棌闆嗗悕绉板垪琛?
   */
  getUserCollections(
    userId: string
  ): Promise<DatabaseResult<string[]>>;

  // ========== 鎼滅储鍘嗗彶鐩稿叧鎿嶄綔 ==========
  
  /**
   * 娣诲姞鎼滅储鍘嗗彶
   * @param userId 鐢ㄦ埛ID
   * @param keyword 鎼滅储鍏抽敭璇?
   * @returns 鎿嶄綔缁撴灉
   */
  addSearchHistory(
    userId: string,
    keyword: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 鍒犻櫎鎼滅储鍘嗗彶
   * @param userId 鐢ㄦ埛ID
   * @param keyword 鎼滅储鍏抽敭璇?
   * @returns 鎿嶄綔缁撴灉
   */
  deleteSearchHistory(
    userId: string,
    keyword: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 娓呯┖鐢ㄦ埛鎼滅储鍘嗗彶
   * @param userId 鐢ㄦ埛ID
   * @returns 鎿嶄綔缁撴灉
   */
  clearSearchHistory(
    userId: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 鑾峰彇鐢ㄦ埛鎼滅储鍘嗗彶
   * @param userId 鐢ㄦ埛ID
   * @param limit 闄愬埗鏁伴噺
   * @returns 鎼滅储鍏抽敭璇嶅垪琛?
   */
  getUserSearchHistory(
    userId: string,
    limit: number
  ): Promise<DatabaseResult<string[]>>;

  // ========== 缂撳瓨鐩稿叧鎿嶄綔 ==========
  
  /**
   * 缂撳瓨鎼滅储缁撴灉
   * @param keyword 鎼滅储鍏抽敭璇?
   * @param results 鎼滅储缁撴灉
   * @param expirationTime 杩囨湡鏃堕棿锛堟绉掞級
   * @returns 鎿嶄綔缁撴灉
   */
  cacheSearchResults(
    keyword: string,
    results: SearchResult[],
    expirationTime?: number
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 鑾峰彇缂撳瓨鐨勬悳绱㈢粨鏋?
   * @param keyword 鎼滅储鍏抽敭璇?
   * @returns 缂撳瓨鐨勬悳绱㈢粨鏋滄垨null
   */
  getCachedSearchResults(
    keyword: string
  ): Promise<DatabaseResult<SearchResult[] | null>>;

  /**
   * 娓呴櫎杩囨湡缂撳瓨
   * @returns 娓呴櫎鐨勭紦瀛橀」鏁伴噺
   */
  clearExpiredCache(): Promise<DatabaseResult<number>>;

  /**
   * 鑾峰彇缂撳瓨澶у皬
   * @returns 缂撳瓨澶у皬锛堝瓧鑺傦級
   */
  getCacheSize(): Promise<DatabaseResult<number>>;

  /**
   * 娓呯┖鎵€鏈夌紦瀛?
   * @returns 鎿嶄綔缁撴灉
   */
  clearAllCache(): Promise<DatabaseResult<boolean>>;

  // ========== 閰嶇疆鐩稿叧鎿嶄綔 ==========
  
  /**
   * 淇濆瓨閰嶇疆鍊?
   * @param key 閰嶇疆閿?
   * @param value 閰嶇疆鍊?
   * @param group 閰嶇疆鍒嗙粍
   * @returns 鎿嶄綔缁撴灉
   */
  saveConfig(
    key: string,
    value: ConfigValue,
    group?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 鑾峰彇閰嶇疆椤?
   * @param key 閰嶇疆椤?
   * @param group 閰嶇疆鍒嗙粍
   * @returns 閰嶇疆椤?
   */
  getConfig(
    key: string,
    group?: string
  ): Promise<DatabaseResult<ConfigValue | null>>;

  /**
   * 鍒犻櫎閰嶇疆椤?
   * @param key 閰嶇疆椤?
   * @param group 閰嶇疆鍒嗙粍
   * @returns 鎿嶄綔缁撴灉
   */
  deleteConfig(
    key: string,
    group?: string
  ): Promise<DatabaseResult<boolean>>;

  /**
   * 鑾峰彇閰嶇疆鍒嗙粍
   * @param group 閰嶇疆鍒嗙粍
   * @returns 閰嶇疆鍒嗙粍瀵硅薄
   */
  getConfigGroup(
    group: string
  ): Promise<DatabaseResult<Record<string, ConfigValue>>>;

  /**
   * 娓呯┖閰嶇疆鍒嗙粍
   * @param group 閰嶇疆鍒嗙粍
   * @returns 鎿嶄綔缁撴灉
   */
  clearConfigGroup(
    group: string
  ): Promise<DatabaseResult<boolean>>;
}



