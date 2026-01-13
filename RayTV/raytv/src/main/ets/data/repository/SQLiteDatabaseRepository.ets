// SQLiteDatabaseRepository - SQLite数据库实现类 | SQLite database implementation class
import LoggerUtil from '../../common/util/Logger';
import JsonUtil from '../../common/util/JsonUtil';
import DatabaseRepository, {
  DatabaseResult,
  DatabaseStatus,
  PaginationParams,
  PaginatedResult,
  ConfigValue,
  MovieFilter
} from './DatabaseRepository';
import Movie, { MovieConstructorParams, VideoType, VideoSource, Episode, RatingInfo } from '../model/Movie';
import User from '../model/User';
import History from '../model/History';
import SearchResult from '../model/SearchResult';
import relationalStore from '@ohos.data.relationalStore';
import BusinessError from '@ohos.base';
import common from '@ohos.app.ability.common';

const TAG = 'SQLiteDatabaseRepository';
const DATABASE_NAME = 'raytv.db';
const DATABASE_VERSION = 1;

// 配置值类型接口 | Config value type interface
export interface ConfigValueObject {
  value: string;
}

// 网站信息接口定义 | Site information interface definition
export interface SiteInfo {
  siteId: string;
  name: string;
  baseUrl: string;
  icon?: string;
  description?: string;
  enabled?: boolean;
  weight?: number;
  extraInfo?: Record<string, string | number | boolean | null | undefined>;
}

// 网站数据接口定义 | Site data interface definition
export interface Site {
  siteId: string;
  name: string;
  baseUrl: string;
  icon: string | null;
  description: string | null;
  enabled: boolean;
  weight: number;
  createTime: number;
  updateTime: number;
  extraInfo: Record<string, string | number | boolean | null | undefined> | null;
}

/**
 * SQLite数据库实现类 | SQLite database implementation class
 * 实现DatabaseRepository接口，提供基于SQLite的数据库操作能力 | Implements DatabaseRepository interface, provides SQLite-based database operation capabilities
 */
export default class SQLiteDatabaseRepository implements DatabaseRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private status: DatabaseStatus = DatabaseStatus.INITIALIZING;
  private configMap: Map<string, ConfigValueObject | Record<string, string | number | boolean | Record<string, string | number | boolean>>> = new Map(); // 用于缓存配置 | Used for caching configs
  private context: common.UIAbilityContext | null = null;

  /**
 * 设置上下文 | Set context
 */
  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
 * 创建RdbPredicates实例 | Create RdbPredicates instance
 */
  private createPredicates(table: string): relationalStore.RdbPredicates {
    return new relationalStore.RdbPredicates(table);
  }

  /**
 * 初始化数据库 | Initialize database
 */
  async initialize(): Promise<DatabaseResult<void>> {
    try {
      if (!this.context) {
        throw new Error('Context not set');
      }

      const storeConfig: relationalStore.StoreConfig = {
        name: DATABASE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };

      // 打开数据库连接 | Open database connection
      this.rdbStore = await relationalStore.getRdbStore(this.context, storeConfig);
      this.status = DatabaseStatus.READY;
      
      // 加载配置缓存 | Load config cache
      await this.loadConfigCache();

      LoggerUtil.info(TAG, 'Database initialized successfully');
      const result: DatabaseResult<void> = {
        success: true,
        data: undefined
      };
      return result;
    } catch (error) {
      this.status = DatabaseStatus.ERROR;
      LoggerUtil.error(TAG, `Failed to initialize database: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<void> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to initialize database'
      };
      return result;
    }
  }

  /**
 * 获取数据库状态 | Get database status
 */
  getStatus(): DatabaseStatus {
    return this.status;
  }

  /**
 * 关闭数据库连接 | Close database connection
 */
  async close(): Promise<DatabaseResult<void>> {
    try {
      if (this.rdbStore) {
        // 关闭数据库连接 | Close database connection
        // ArkTS没有直接的rdbStore关闭方法，由系统管理 | ArkTS has no direct close method for rdbStore, managed by system
        this.rdbStore = null;
        this.status = DatabaseStatus.CLOSED;
        LoggerUtil.info(TAG, 'Database connection closed successfully');
      }

      const result: DatabaseResult<void> = {
        success: true,
        data: undefined
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to close database connection: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<void> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to close database connection'
      };
      return result;
    }
  }

  /**
 * 加载配置缓存 | Load config cache
 */
  private async loadConfigCache(): Promise<void> {
    try {
      if (!this.rdbStore) {
        return;
      }

      const predicates = new relationalStore.RdbPredicates('config');
      const resultSet = await this.rdbStore.query(predicates);
      
      if (resultSet && resultSet.goToFirstRow()) {
        do {
          const key = resultSet.getString(resultSet.getColumnIndex('key'));
          const value = resultSet.getString(resultSet.getColumnIndex('value'));
          const config_group = resultSet.getString(resultSet.getColumnIndex('config_group')) || 'default';
          
          if (key) {
            try {
              if (!value) {
                const configValue = { value: '' } as ConfigValueObject;
                this.configMap.set(`${config_group}:${key}`, configValue);
              } else {
                const parsedValue = JSON.parse(value) as Record<string, string | number | boolean | Record<string, string | number | boolean>>;
                if (parsedValue && typeof parsedValue === 'object') {
                  this.configMap.set(`${config_group}:${key}`, parsedValue);
                } else {
                  const configValue = { value: value } as ConfigValueObject;
                  this.configMap.set(`${config_group}:${key}`, configValue);
                }
              }
            } catch (e) {
              LoggerUtil.warn(TAG, `Failed to parse config value for key ${key}: ${e instanceof Error ? e.message : String(e)}`);
              const configValue = { value: value || '' } as ConfigValueObject;
              this.configMap.set(`${config_group}:${key}`, configValue);
            }
          }
        } while (resultSet.goToNextRow());
        resultSet.close();
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to load config cache: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // ========== 电影相关实现 | Movie-related implementation ==========

  async addMovie(movie: Movie): Promise<DatabaseResult<string>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      // 确保movie对象不为null，防止null安全错误 | Ensure movie object is not null, prevent null safety error
      if (!movie) {
        throw new Error('Movie object cannot be null');
      }
      
      // 使用明确的ValuesBucket类型，确保所有属性都是支持的类型 | Use explicit ValuesBucket type, ensure all properties are supported types
      const valuesBucket: relationalStore.ValuesBucket = {
        id: movie.id,
        title: movie.title,
        originalTitle: movie.originalTitle || null,
        type: movie.type,
        coverUrl: movie.coverUrl || null,
        backdropUrl: movie.backdropUrl || null,
        description: movie.overview || null,
        releaseDate: movie.releaseDate || null,
        year: movie.year || null,
        genres: JSON.stringify(movie.genres || []),
        tags: JSON.stringify(movie.tags || []),
        duration: movie.duration || null,
        totalEpisodes: movie.totalEpisodes || null,
        currentSeason: movie.currentSeason || null,
        score: movie.score || null,
        directors: JSON.stringify(movie.directors || []),
        actors: JSON.stringify(movie.actors || []),
        country: movie.countries ? movie.countries.join(',') : null,
        language: movie.languages ? movie.languages.join(',') : null,
        plot: movie.overview || null,
        createTime: Date.now(),
        updateTime: Date.now(),
        videoSources: JSON.stringify(movie.sources || []),
        episodes: JSON.stringify(movie.episodes || []),
        ratingInfo: movie.ratings ? JSON.stringify(movie.ratings) : null
      };

      const rowsInserted = await this.rdbStore.insert('movies', valuesBucket);
      
      if (rowsInserted > 0) {
        LoggerUtil.info(TAG, `Movie added successfully: ${movie.id}`);
        const result: DatabaseResult<string> = {
          success: true,
          data: movie.id
        };
        return result;
      } else {
        throw new Error('Failed to insert movie');
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to add movie: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<string> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to add movie'
      };
      return result;
    }
  }

  async updateMovie(movie: Movie): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const valuesBucket: relationalStore.ValuesBucket = {
        'title': movie.title,
        'originalTitle': movie.originalTitle || null,
        'type': movie.type,
        'coverUrl': movie.coverUrl || null,
        'backdropUrl': movie.backdropUrl || null,
        'description': movie.overview || null,
        'releaseDate': movie.releaseDate || null,
        'year': movie.year || null,
        'genres': JSON.stringify(movie.genres || []),
        'tags': JSON.stringify(movie.tags || []),
        'duration': movie.duration || null,
        'totalEpisodes': movie.totalEpisodes || null,
        'currentSeason': movie.currentSeason || null,
        'score': movie.score || null,
        'directors': JSON.stringify(movie.directors || []),
        'actors': JSON.stringify(movie.actors || []),
        'country': movie.countries ? movie.countries.join(',') : null,
        'language': movie.languages ? movie.languages.join(',') : null,
        'plot': movie.overview || null,
        'updateTime': Date.now(),
        'videoSources': JSON.stringify(movie.sources || []),
        'episodes': JSON.stringify(movie.episodes || []),
        'ratingInfo': movie.ratings ? JSON.stringify(movie.ratings) : null
      };

      const predicates = new relationalStore.RdbPredicates('movies');
      predicates.equalTo('id', movie.id);
      
      const rowsUpdated = await this.rdbStore.update(valuesBucket, predicates);
      
      if (rowsUpdated > 0) {
        LoggerUtil.info(TAG, `Movie updated successfully: ${movie.id}`);
        const result: DatabaseResult<boolean> = {
          success: true,
          data: true
        };
        return result;
      } else {
        const result: DatabaseResult<boolean> = {
          success: true,
          data: false,
          message: 'Movie not found'
        };
        return result;
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to update movie: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to update movie'
      };
      return result;
    }
  }

  async deleteMovie(movieId: string): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('movies');
      predicates.equalTo('id', movieId);
      
      const rowsDeleted = await this.rdbStore.delete(predicates);
      
      if (rowsDeleted > 0) {
        LoggerUtil.info(TAG, `Movie deleted successfully: ${movieId}`);
        // 同时删除相关的收藏记录 | Also delete related favorite records
        const favPredicates = new relationalStore.RdbPredicates('favorites');
        favPredicates.equalTo('movieId', movieId);
        await this.rdbStore.delete(favPredicates);
        // 同时删除相关的历史记录 | Also delete related history records
        const historyPredicates = new relationalStore.RdbPredicates('history');
        historyPredicates.equalTo('contentId', movieId);
        await this.rdbStore.delete(historyPredicates);
        
        const result: DatabaseResult<boolean> = {
          success: true,
          data: true
        };
        return result;
      } else {
        const result: DatabaseResult<boolean> = {
          success: true,
          data: false,
          message: 'Movie not found'
        };
        return result;
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to delete movie: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to delete movie'
      };
      return result;
    }
  }

  async getMovieById(movieId: string): Promise<DatabaseResult<Movie | null>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('movies');
      predicates.equalTo('id', movieId);
      
      const resultSet = await this.rdbStore.query(predicates);
      let movie: Movie | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        const movieData = this.extractMovieFromResultSet(resultSet);
        if (movieData) {
          movie = new Movie(movieData);
        }
        resultSet.close();
      }
      
      LoggerUtil.info(TAG, `Retrieved movie by ID: ${movieId}`);
      const result: DatabaseResult<Movie | null> = {
        success: true,
        data: movie
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get movie by ID ${movieId}: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<Movie | null> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get movie by ID'
      };
      return result;
    }
  }

  async getMoviesByIds(movieIds: string[]): Promise<DatabaseResult<Movie[]>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const movies: Movie[] = [];
      
      for (let i = 0; i < movieIds.length; i++) {
        const movieId = movieIds[i];
        const movieResult = await this.getMovieById(movieId);
        if (movieResult.success && movieResult.data) {
          movies.push(movieResult.data);
        }
      }
      
      const result: DatabaseResult<Movie[]> = {
        success: true,
        data: movies
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get movies by IDs: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<Movie[]> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get movies by IDs'
      };
      return result;
    }
  }

  async getMoviesPaginated(params: PaginationParams, filters?: MovieFilter): Promise<DatabaseResult<PaginatedResult<Movie>>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const pageSize = params.pageSize || 20;
      const page = params.page || 1;
      const offset = (page - 1) * pageSize;
      
      // Build query conditions | 鏋勫缓鏌ヨ鏉′欢
      const predicates = new relationalStore.RdbPredicates('movies');
      
      // Apply filter conditions | 搴旂敤杩囨护鏉′欢
      if (filters) {
        // Various filter conditions can be added here | 杩欓噷鍙互娣诲姞鍚勭杩囨护鏉′欢
      }
      
      // Apply sorting | 搴旂敤鎺掑簭
      if (params.sortBy) {
        if (params.sortOrder === 'asc') {
          predicates.orderByAsc(params.sortBy);
        } else {
          predicates.orderByDesc(params.sortBy);
        }
      } else {
        predicates.orderByDesc('createTime');
      }
      
      // Apply pagination | 搴旂敤鍒嗛〉
      predicates.limitAs(pageSize);
      predicates.offsetAs(offset);
      
      // Get data | 鑾峰彇鏁版嵁
      const resultSet = await this.rdbStore.query(predicates);
      const movies: Movie[] = [];
      let total = 0;
      
      if (resultSet) {
        if (resultSet.goToFirstRow()) {
          do {
            const movieData = this.extractMovieFromResultSet(resultSet);
            if (movieData) {
              movies.push(new Movie(movieData));
            }
          } while (resultSet.goToNextRow());
        }
        // Get total count | 鑾峰彇鎬昏褰曟暟
        total = resultSet.rowCount;
        resultSet.close();
      }
      
      const totalPages = Math.ceil(total / pageSize);
      const hasNextPage = page < totalPages;
      const hasPrevPage = page > 1;
      
      const result: DatabaseResult<PaginatedResult<Movie>> = {
        success: true,
        data: {
          items: movies,
          totalCount: total,
          page,
          pageSize,
          totalPages,
          hasNextPage,
          hasPrevPage
        }
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get movies paginated: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<PaginatedResult<Movie>> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get movies paginated'
      };
      return result;
    }
  }

  async searchMovies(keyword: string, params: PaginationParams, filters?: MovieFilter): Promise<DatabaseResult<PaginatedResult<Movie>>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const pageSize = params.pageSize || 20;
      const page = params.page || 1;
      const offset = (page - 1) * pageSize;
      
      // Build search query | 鏋勫缓鎼滅储鏌ヨ
      const predicates = new relationalStore.RdbPredicates('movies');
      predicates.contains('title', keyword)
        .or()
        .contains('originalTitle', keyword)
        .or()
        .contains('description', keyword)
        .or()
        .contains('actors', keyword)
        .or()
        .contains('directors', keyword)
        .limitAs(pageSize)
        .offsetAs(offset)
        .orderByDesc('createTime');
      
      // Get data | 鑾峰彇鏁版嵁
      const resultSet = await this.rdbStore.query(predicates);
      const movies: Movie[] = [];
      let total = 0;
      
      if (resultSet) {
        if (resultSet.goToFirstRow()) {
          do {
            const movieData = this.extractMovieFromResultSet(resultSet);
            if (movieData) {
              movies.push(new Movie(movieData));
            }
          } while (resultSet.goToNextRow());
        }
        // Get total count | 鑾峰彇鎬昏褰曟暟
        total = resultSet.rowCount;
        resultSet.close();
      }
      
      const totalPages = Math.ceil(total / pageSize);
      const hasNextPage = page < totalPages;
      const hasPrevPage = page > 1;
      
      LoggerUtil.info(TAG, `Searched movies with keyword "${keyword}": found ${movies.length} results`);
      const result: DatabaseResult<PaginatedResult<Movie>> = {
        success: true,
        data: {
          items: movies,
          totalCount: total,
          page,
          pageSize,
          totalPages,
          hasNextPage,
          hasPrevPage
        }
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to search movies with keyword "${keyword}": ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<PaginatedResult<Movie>> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to search movies'
      };
      return result;
    }
  }

  /**
 * 从结果集中提取电影数据 | Extract movie data from result set
 */
  private extractMovieFromResultSet(resultSet: relationalStore.ResultSet): MovieConstructorParams | null {
    try {
      const id = resultSet.getString(resultSet.getColumnIndex('id'));
      if (!id) {
        return null;
      }

      const title = resultSet.getString(resultSet.getColumnIndex('title'));
      if (!title) {
        return null;
      }

      const genresStr = resultSet.getString(resultSet.getColumnIndex('genres'));
      const genres = genresStr ? JSON.parse(genresStr) as string[] : [];
      
      const tagsStr = resultSet.getString(resultSet.getColumnIndex('tags'));
      const tags = tagsStr ? JSON.parse(tagsStr) as string[] : [];
      
      const directorsStr = resultSet.getString(resultSet.getColumnIndex('directors'));
      const directors = directorsStr ? JSON.parse(directorsStr) as string[] : [];
      
      const actorsStr = resultSet.getString(resultSet.getColumnIndex('actors'));
      const actors = actorsStr ? JSON.parse(actorsStr) as string[] : [];
      
      const countryStr = resultSet.getString(resultSet.getColumnIndex('country'));
      const countries = countryStr ? countryStr.split(',') : [];
      
      const languageStr = resultSet.getString(resultSet.getColumnIndex('language'));
      const languages = languageStr ? languageStr.split(',') : [];
      
      const sourcesStr = resultSet.getString(resultSet.getColumnIndex('videoSources'));
      const sources: VideoSource[] = sourcesStr ? JSON.parse(sourcesStr) as VideoSource[] : [];
      
      const episodesStr = resultSet.getString(resultSet.getColumnIndex('episodes'));
      const episodes: Episode[] = episodesStr ? JSON.parse(episodesStr) as Episode[] : [];
      
      const ratingsStr = resultSet.getString(resultSet.getColumnIndex('ratingInfo'));
      const ratings: RatingInfo[] = ratingsStr ? JSON.parse(ratingsStr) as RatingInfo[] : [];

      const typeStr = resultSet.getString(resultSet.getColumnIndex('type')) || 'movie';
      let videoType: VideoType = VideoType.MOVIE;
      if (typeStr === 'tv_series') {
        videoType = VideoType.TV_SERIES;
      } else if (typeStr === 'anime') {
        videoType = VideoType.ANIME;
      } else if (typeStr === 'documentary') {
        videoType = VideoType.DOCUMENTARY;
      } else if (typeStr === 'variety') {
        videoType = VideoType.VARIETY;
      } else if (typeStr === 'live') {
        videoType = VideoType.LIVE;
      } else {
        videoType = VideoType.OTHER;
      }

      const movieParams: MovieConstructorParams = {
        id,
        title,
        originalTitle: resultSet.getString(resultSet.getColumnIndex('originalTitle')) || '',
        type: videoType,
        coverUrl: resultSet.getString(resultSet.getColumnIndex('coverUrl')) || '',
        backdropUrl: resultSet.getString(resultSet.getColumnIndex('backdropUrl')) || '',
        overview: resultSet.getString(resultSet.getColumnIndex('description')) || '',
        releaseDate: resultSet.getString(resultSet.getColumnIndex('releaseDate')) || '',
        year: resultSet.getLong(resultSet.getColumnIndex('year')) || 0,
        genres,
        tags,
        duration: resultSet.getLong(resultSet.getColumnIndex('duration')) || 0,
        totalEpisodes: resultSet.getLong(resultSet.getColumnIndex('totalEpisodes')) || 0,
        currentSeason: resultSet.getLong(resultSet.getColumnIndex('currentSeason')) || 0,
        score: resultSet.getDouble(resultSet.getColumnIndex('score')) || 0,
        directors,
        actors,
        countries,
        languages,
        sources,
        episodes,
        ratings,
        updateTime: String(resultSet.getLong(resultSet.getColumnIndex('updateTime')) || Date.now())
      };
      return movieParams;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to extract movie from result set: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }

  // ========== 历史记录相关实现 | History record-related implementation ==========

  async saveHistory(history: History): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const valuesBucket: relationalStore.ValuesBucket = {
        'id': history.id,
        'userId': history.userId,
        'contentId': history.contentId,
        'contentTitle': history.contentTitle,
        'contentType': history.contentType,
        'coverUrl': history.coverUrl || '',
        'progress': history.progress,
        'totalDuration': history.totalDuration,
        'lastWatchTime': history.lastWatchTime,
        'playCount': history.playCount,
        'isFinished': history.isFinished,
        'episodeId': history.episodeId || '',
        'season': history.season || 0,
        'episode': history.episode || 0
      };

      // 首先检查记录是否已存在 | First check if record already exists
      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('contentId', history.contentId)
        .and()
        .equalTo('userId', history.userId);
      
      // 使用查询来检查记录是否存在 | Use query to check if record exists
      const resultSet = await this.rdbStore.query(predicates);
      let existingCount = 0;
      if (resultSet) {
        if (resultSet.goToFirstRow()) {
          existingCount = 1;
        }
        resultSet.close();
      }
      
      let rowsAffected = 0;
      if (existingCount > 0) {
        // 更新现有记录 | Update existing record
        rowsAffected = await this.rdbStore.update(valuesBucket, predicates);
      } else {
        // 插入新记录 | Insert new record
        rowsAffected = await this.rdbStore.insert('history', valuesBucket);
      }
      
      if (rowsAffected > 0) {
        LoggerUtil.info(TAG, `History item ${existingCount > 0 ? 'updated' : 'added'} successfully: ${history.contentId}`);
        const result: DatabaseResult<boolean> = {
          success: true,
          data: true
        };
        return result;
      } else {
        throw new Error('Failed to add or update history item');
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to save history: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to save history'
      };
      return result;
    }
  }

  async deleteHistory(historyId: string): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('id', historyId);
      
      const rowsDeleted = await this.rdbStore.delete(predicates);
      
      if (rowsDeleted > 0) {
        LoggerUtil.info(TAG, `History item deleted successfully: ${historyId}`);
        const result: DatabaseResult<boolean> = {
          success: true,
          data: true
        };
        return result;
      } else {
        const result: DatabaseResult<boolean> = {
          success: true,
          data: false,
          message: 'History item not found'
        };
        return result;
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to delete history: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to delete history'
      };
      return result;
    }
  }

  async deleteAllHistoryByUserId(userId: string): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('userId', userId);
      
      const rowsDeleted = await this.rdbStore.delete(predicates);
      
      LoggerUtil.info(TAG, `All history items deleted for user ${userId}: ${rowsDeleted} items`);
      const result: DatabaseResult<boolean> = {
        success: true,
        data: true
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to delete all history for user ${userId}: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to delete all history'
      };
      return result;
    }
  }

  async getHistoryById(historyId: string): Promise<DatabaseResult<History | null>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('id', historyId);
      
      const resultSet = await this.rdbStore.query(predicates);
      let history: History | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        history = this.extractHistoryFromResultSet(resultSet);
        resultSet.close();
      }
      
      const result: DatabaseResult<History | null> = {
        success: true,
        data: history
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get history by ID ${historyId}: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<History | null> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get history by ID'
      };
      return result;
    }
  }

  async getUserHistory(userId: string, params: PaginationParams): Promise<DatabaseResult<PaginatedResult<History>>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const pageSize = params.pageSize || 20;
      const pageIndex = params.page || 1;
      const offset = (pageIndex - 1) * pageSize;
      
      // Get paginated data | 鑾峰彇鍒嗛〉鏁版嵁
      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('userId', userId)
        .orderByDesc('lastWatchTime')
        .limitAs(pageSize)
        .offsetAs(offset);
      
      const resultSet = await this.rdbStore.query(predicates);
      const historyItems: History[] = [];
      let total = 0;
      
      if (resultSet) {
        if (resultSet.goToFirstRow()) {
          do {
            const historyItem = this.extractHistoryFromResultSet(resultSet);
            if (historyItem) {
              historyItems.push(historyItem);
            }
          } while (resultSet.goToNextRow());
        }
        // Use getRowCount to get total count | 浣跨敤getRowCount鑾峰彇鎬昏褰曟暟
        total = resultSet.rowCount;
        resultSet.close();
      }
      
      const totalPages = Math.ceil(total / pageSize);
      const hasNextPage = pageIndex < totalPages;
      const hasPrevPage = pageIndex > 1;
      
      LoggerUtil.info(TAG, `Retrieved history items for user ${userId}: found ${historyItems.length} results`);
      const result: DatabaseResult<PaginatedResult<History>> = {
        success: true,
        data: {
          items: historyItems,
          totalCount: total,
          page: pageIndex,
          pageSize,
          totalPages,
          hasNextPage,
          hasPrevPage
        }
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get history items for user ${userId}: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<PaginatedResult<History>> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get history items'
      };
      return result;
    }
  }

  async getUserContentHistory(userId: string, contentId: string, contentType: string): Promise<DatabaseResult<History | null>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('userId', userId)
        .and()
        .equalTo('contentId', contentId)
        .and()
        .equalTo('contentType', contentType);
      
      const resultSet = await this.rdbStore.query(predicates);
      let history: History | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        history = this.extractHistoryFromResultSet(resultSet);
        resultSet.close();
      }
      
      const result: DatabaseResult<History | null> = {
        success: true,
        data: history
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get user content history: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<History | null> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get user content history'
      };
      return result;
    }
  }

  async getRecentHistory(userId: string, limit: number): Promise<DatabaseResult<History[]>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('userId', userId)
        .orderByDesc('lastWatchTime')
        .limitAs(limit);
      predicates.offsetAs(0);
      
      const resultSet = await this.rdbStore.query(predicates);
      const historyItems: History[] = [];
      
      if (resultSet && resultSet.goToFirstRow()) {
        do {
          const historyItem = this.extractHistoryFromResultSet(resultSet);
          if (historyItem) {
            historyItems.push(historyItem);
          }
        } while (resultSet.goToNextRow());
        resultSet.close();
      }
      
      const result: DatabaseResult<History[]> = {
        success: true,
        data: historyItems
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get recent history: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<History[]> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get recent history'
      };
      return result;
    }
  }

  /**
 * 从结果集中提取历史记录数据 | Extract history data from result set
 */
  private extractHistoryFromResultSet(resultSet: relationalStore.ResultSet): History {
    // 使用对象字面量创建History实例，确保参数类型正确 | Create History instance using object literal, ensure parameter types are correct
    try {
      return new History({
        id: resultSet.getString(resultSet.getColumnIndex('id')) || `history_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`,
        userId: resultSet.getString(resultSet.getColumnIndex('userId')) || '',
        contentId: resultSet.getString(resultSet.getColumnIndex('contentId')) || '',
        contentTitle: resultSet.getString(resultSet.getColumnIndex('contentTitle')) || '',
        contentType: resultSet.getLong(resultSet.getColumnIndex('contentType')) as VideoType,
        coverUrl: resultSet.getString(resultSet.getColumnIndex('coverUrl')) || '',
        progress: resultSet.getLong(resultSet.getColumnIndex('progress')) || 0,
        totalDuration: resultSet.getLong(resultSet.getColumnIndex('totalDuration')) || 0,
        lastWatchTime: resultSet.getString(resultSet.getColumnIndex('lastWatchTime')) || new Date().toISOString(),
        playCount: resultSet.getLong(resultSet.getColumnIndex('playCount')) || 0,
        isFinished: resultSet.getLong(resultSet.getColumnIndex('isFinished')) === 1,
        episodeId: resultSet.getString(resultSet.getColumnIndex('episodeId')) || '',
        season: resultSet.getLong(resultSet.getColumnIndex('season')) || 0,
        episode: resultSet.getLong(resultSet.getColumnIndex('episode')) || 0
      });
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to extract history from result set: ${error instanceof Error ? error.message : String(error)}`);
      // 返回默认的History对象，确保函数不会抛出异常 | Return default History object, ensure function won't throw exception
      return new History({
        id: `history_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`,
        userId: '',
        contentId: '',
        contentTitle: '',
        contentType: VideoType.MOVIE,
        coverUrl: '',
        progress: 0,
        totalDuration: 0,
        lastWatchTime: new Date().toISOString(),
        playCount: 0,
        isFinished: false,
        episodeId: '',
        season: 0,
        episode: 0
      });
    }
  }

  // ========== User-related implementation | 鐢ㄦ埛鐩稿叧瀹炵幇 ==========

  async addUser(user: User): Promise<DatabaseResult<string>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const valuesBucket: relationalStore.ValuesBucket = {
        'id': user.id,
        'username': user.username,
        'email': user.email || null,
        'nickname': user.nickname || null,
        'avatarUrl': user.avatarUrl || null,
        'role': user.role,
        'lastLoginTime': user.lastLoginTime || null,
        'registrationDate': user.registrationDate || Date.now().toString(),
        'status': String(user.status || 'active'),
        'isVerified': user.isVerified ? 1 : 0,
        'subscriptionEndDate': user.subscriptionEndDate || null,
        'watchHistoryEnabled': user.watchHistoryEnabled ? 1 : 0,
        'favoritesEnabled': user.favoritesEnabled ? 1 : 0,
        'totalWatchTime': user.totalWatchTime || 0
      };

      const rowsInserted = await this.rdbStore.insert('users', valuesBucket);
      
      if (rowsInserted > 0) {
        LoggerUtil.info(TAG, `User added successfully: ${user.id}`);
        const result: DatabaseResult<string> = {
          success: true,
          data: user.id
        };
        return result;
      } else {
        throw new Error('Failed to insert user');
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to add user: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<string> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to add user'
      };
      return result;
    }
  }

  async updateUser(user: User): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const valuesBucket: relationalStore.ValuesBucket = {
        'username': user.username,
        'email': user.email || null,
        'nickname': user.nickname || null,
        'avatarUrl': user.avatarUrl || null,
        'role': user.role,
        'lastLoginTime': user.lastLoginTime || null,
        'registrationDate': user.registrationDate || Date.now().toString(),
        'status': String(user.status || 'active'),
        'isVerified': user.isVerified ? 1 : 0,
        'subscriptionEndDate': user.subscriptionEndDate || null,
        'watchHistoryEnabled': user.watchHistoryEnabled ? 1 : 0,
        'favoritesEnabled': user.favoritesEnabled ? 1 : 0,
        'totalWatchTime': user.totalWatchTime || 0
      };

      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('id', user.id);
      
      const rowsUpdated = await this.rdbStore.update(valuesBucket, predicates);
      
      if (rowsUpdated > 0) {
        LoggerUtil.info(TAG, `User updated successfully: ${user.id}`);
        const result: DatabaseResult<boolean> = {
          success: true,
          data: true
        };
        return result;
      } else {
        const result: DatabaseResult<boolean> = {
          success: true,
          data: false,
          message: 'User not found'
        };
        return result;
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to update user: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to update user'
      };
      return result;
    }
  }

  async deleteUser(userId: string): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('id', userId);
      
      const rowsDeleted = await this.rdbStore.delete(predicates);
      
      if (rowsDeleted > 0) {
        LoggerUtil.info(TAG, `User deleted successfully: ${userId}`);
        const result: DatabaseResult<boolean> = {
          success: true,
          data: true
        };
        return result;
      } else {
        const result: DatabaseResult<boolean> = {
          success: true,
          data: false,
          message: 'User not found'
        };
        return result;
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to delete user: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to delete user'
      };
      return result;
    }
  }

  async getUserById(userId: string): Promise<DatabaseResult<User | null>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('id', userId);
      
      const resultSet = await this.rdbStore.query(predicates);
      let user: User | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        try {
          user = new User({
            id: resultSet.getString(resultSet.getColumnIndex('id')) || '',
            username: resultSet.getString(resultSet.getColumnIndex('username')) || '',
            email: resultSet.getString(resultSet.getColumnIndex('email')) || undefined,
            nickname: resultSet.getString(resultSet.getColumnIndex('nickname')) || undefined,
            avatarUrl: resultSet.getString(resultSet.getColumnIndex('avatarUrl')) || undefined,
            role: resultSet.getString(resultSet.getColumnIndex('role')) || 'user',
            lastLoginTime: resultSet.getString(resultSet.getColumnIndex('lastLoginTime')) || undefined,
            registrationDate: resultSet.getString(resultSet.getColumnIndex('registrationDate')) || Date.now().toString(),
            status: resultSet.getString(resultSet.getColumnIndex('status')) || 'active',
            isVerified: resultSet.getLong(resultSet.getColumnIndex('isVerified')) === 1,
            subscriptionEndDate: resultSet.getString(resultSet.getColumnIndex('subscriptionEndDate')) || undefined,
            watchHistoryEnabled: resultSet.getLong(resultSet.getColumnIndex('watchHistoryEnabled')) === 1,
            favoritesEnabled: resultSet.getLong(resultSet.getColumnIndex('favoritesEnabled')) === 1,
            totalWatchTime: resultSet.getLong(resultSet.getColumnIndex('totalWatchTime')) || 0
          });
        } catch (innerError) {
          LoggerUtil.error(TAG, `Failed to create user from result set: ${innerError instanceof Error ? innerError.message : String(innerError)}`);
        } finally {
          resultSet.close();
        }
      } else if (resultSet) {
        resultSet.close();
      }
      
      const result: DatabaseResult<User | null> = {
        success: true,
        data: user
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get user by ID ${userId}: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<User | null> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get user by ID'
      };
      return result;
    }
  }

  async getAllUsers(): Promise<DatabaseResult<User[]>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('users');
      const resultSet = await this.rdbStore.query(predicates);
      const users: User[] = [];
      
      if (resultSet && resultSet.goToFirstRow()) {
        do {
          try {
            const user = new User({
              id: resultSet.getString(resultSet.getColumnIndex('id')) || '',
              username: resultSet.getString(resultSet.getColumnIndex('username')) || '',
              email: resultSet.getString(resultSet.getColumnIndex('email')) || undefined,
              nickname: resultSet.getString(resultSet.getColumnIndex('nickname')) || undefined,
              avatarUrl: resultSet.getString(resultSet.getColumnIndex('avatarUrl')) || undefined,
              role: resultSet.getString(resultSet.getColumnIndex('role')) || 'user',
              lastLoginTime: resultSet.getString(resultSet.getColumnIndex('lastLoginTime')) || undefined,
              registrationDate: resultSet.getString(resultSet.getColumnIndex('registrationDate')) || Date.now().toString(),
              status: resultSet.getString(resultSet.getColumnIndex('status')) || 'active',
              isVerified: resultSet.getLong(resultSet.getColumnIndex('isVerified')) === 1,
              subscriptionEndDate: resultSet.getString(resultSet.getColumnIndex('subscriptionEndDate')) || undefined,
              watchHistoryEnabled: resultSet.getLong(resultSet.getColumnIndex('watchHistoryEnabled')) === 1,
              favoritesEnabled: resultSet.getLong(resultSet.getColumnIndex('favoritesEnabled')) === 1,
              totalWatchTime: resultSet.getLong(resultSet.getColumnIndex('totalWatchTime')) || 0
            });
            users.push(user);
          } catch (innerError) {
            LoggerUtil.error(TAG, `Failed to create user from result set: ${innerError instanceof Error ? innerError.message : String(innerError)}`);
          }
        } while (resultSet.goToNextRow());
        resultSet.close();
      } else if (resultSet) {
        resultSet.close();
      }
      
      const result: DatabaseResult<User[]> = {
        success: true,
        data: users
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get all users: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<User[]> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get all users'
      };
      return result;
    }
  }

  async getUserByUsername(username: string): Promise<DatabaseResult<User | null>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('users');
      predicates.equalTo('username', username);
      
      const resultSet = await this.rdbStore.query(predicates);
      let user: User | null = null;
      
      if (resultSet && resultSet.goToFirstRow()) {
        try {
          user = new User({
            id: resultSet.getString(resultSet.getColumnIndex('id')) || '',
            username: resultSet.getString(resultSet.getColumnIndex('username')) || '',
            email: resultSet.getString(resultSet.getColumnIndex('email')) || undefined,
            nickname: resultSet.getString(resultSet.getColumnIndex('nickname')) || undefined,
            avatarUrl: resultSet.getString(resultSet.getColumnIndex('avatarUrl')) || undefined,
            role: resultSet.getString(resultSet.getColumnIndex('role')) || 'user',
            lastLoginTime: resultSet.getString(resultSet.getColumnIndex('lastLoginTime')) || undefined,
            registrationDate: resultSet.getString(resultSet.getColumnIndex('registrationDate')) || Date.now().toString(),
            status: resultSet.getString(resultSet.getColumnIndex('status')) || 'active',
            isVerified: resultSet.getLong(resultSet.getColumnIndex('isVerified')) === 1,
            subscriptionEndDate: resultSet.getString(resultSet.getColumnIndex('subscriptionEndDate')) || undefined,
            watchHistoryEnabled: resultSet.getLong(resultSet.getColumnIndex('watchHistoryEnabled')) === 1,
            favoritesEnabled: resultSet.getLong(resultSet.getColumnIndex('favoritesEnabled')) === 1,
            totalWatchTime: resultSet.getLong(resultSet.getColumnIndex('totalWatchTime')) || 0
          });
        } catch (innerError) {
          LoggerUtil.error(TAG, `Failed to create user from result set: ${innerError instanceof Error ? innerError.message : String(innerError)}`);
        } finally {
          resultSet.close();
        }
      } else if (resultSet) {
        resultSet.close();
      }
      
      const result: DatabaseResult<User | null> = {
        success: true,
        data: user
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get user by username ${username}: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<User | null> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get user by username'
      };
      return result;
    }
  }

  // ========== Favorite-related implementation | 鏀惰棌鐩稿叧瀹炰緥 ==========

  async addFavorite(userId: string, movieId: string, collectionName?: string): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const valuesBucket: relationalStore.ValuesBucket = {
        'userId': userId,
        'movieId': movieId,
        'collectionName': collectionName || 'default',
        'createTime': Date.now()
      };

      const rowsInserted = await this.rdbStore.insert('favorites', valuesBucket);
      
      if (rowsInserted > 0) {
        LoggerUtil.info(TAG, `Favorite added successfully: user ${userId}, movie ${movieId}`);
        const result: DatabaseResult<boolean> = {
          success: true,
          data: true
        };
        return result;
      } else {
        throw new Error('Failed to insert favorite');
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to add favorite: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to add favorite'
      };
      return result;
    }
  }

  async removeFavorite(userId: string, movieId: string): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('favorites');
      predicates.equalTo('userId', userId)
        .and()
        .equalTo('movieId', movieId);
      
      const rowsDeleted = await this.rdbStore.delete(predicates);
      
      if (rowsDeleted > 0) {
        LoggerUtil.info(TAG, `Favorite removed successfully: user ${userId}, movie ${movieId}`);
        const result: DatabaseResult<boolean> = {
          success: true,
          data: true
        };
        return result;
      } else {
        const result: DatabaseResult<boolean> = {
          success: true,
          data: false,
          message: 'Favorite not found'
        };
        return result;
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to remove favorite: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to remove favorite'
      };
      return result;
    }
  }

  async isFavorited(userId: string, movieId: string): Promise<DatabaseResult<boolean>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('favorites');
      predicates.equalTo('userId', userId)
        .and()
        .equalTo('movieId', movieId);
      
      const resultSet = await this.rdbStore.query(predicates);
      let isFavorited = false;
      
      if (resultSet && resultSet.goToFirstRow()) {
        isFavorited = true;
        resultSet.close();
      }
      
      const result: DatabaseResult<boolean> = {
        success: true,
        data: isFavorited
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to check if favorited: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<boolean> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to check if favorited'
      };
      return result;
    }
  }

  async getUserFavorites(userId: string, params: PaginationParams, collectionName?: string): Promise<DatabaseResult<PaginatedResult<Movie>>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      // Need to implement join query here to get user's favorite movies | 杩欓噷闇€瑕佸疄鐜拌仈鍚堟煡璇紝鑾峰彇鐢ㄦ埛鏀惰棌鐨勭數褰?
      // Temporarily return empty result | 鏆傛椂杩斿洖绌虹粨鏋?
      const result: DatabaseResult<PaginatedResult<Movie>> = {
        success: true,
        data: {
          items: [],
          totalCount: 0,
          page: params.page || 1,
          pageSize: params.pageSize || 20,
          totalPages: 0,
          hasNextPage: false,
          hasPrevPage: false
        }
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get user favorites: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<PaginatedResult<Movie>> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get user favorites'
      };
      return result;
    }
  }

  async getUserCollections(userId: string): Promise<DatabaseResult<string[]>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }

      const predicates = new relationalStore.RdbPredicates('favorites');
      predicates.equalTo('userId', userId);
      
      const resultSet = await this.rdbStore.query(predicates);
      const collections: string[] = [];
      const collectionMap: Record<string, boolean> = {};
      
      if (resultSet && resultSet.goToFirstRow()) {
        do {
          const collectionName = resultSet.getString(resultSet.getColumnIndex('collectionName')) || 'default';
          if (!collectionMap[collectionName]) {
            collectionMap[collectionName] = true;
            collections.push(collectionName);
          }
        } while (resultSet.goToNextRow());
        resultSet.close();
      }
      
      const result: DatabaseResult<string[]> = {
        success: true,
        data: collections
      };
      return result;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get user collections: ${error instanceof Error ? error.message : String(error)}`);
      const result: DatabaseResult<string[]> = {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get user collections'
      };
      return result;
    }
  }

  // ========== Search history-related implementation | 鎼滅储鍘嗗彶鐩稿叧瀹炵幇 ==========
}