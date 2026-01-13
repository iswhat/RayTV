/**
 * ModernDatabaseRepository - 现代化数据库实现类 Modern database implementation class
 * 使用最新的HarmonyOS relationalStore API替代旧版的dataRdb API Uses latest HarmonyOS relationalStore API instead of old dataRdb API
 */

import Logger from '../../common/util/Logger';
import JsonUtil from '../../common/util/JsonUtil';
import DatabaseRepository, {
  DatabaseResult,
  DatabaseStatus,
  PaginationParams,
  PaginatedResult
} from './DatabaseRepository';
import Movie from '../model/Movie';
import User from '../model/User';
import History from '../model/History';
import SearchResult, { ResultType } from '../model/SearchResult';
import relationalStore from '@ohos.data.relationalStore';
import BusinessError from '@ohos.base';
import common from '@ohos.app.ability.common';

const TAG = 'ModernDatabaseRepository';
const DATABASE_NAME = 'raytv.db';
const DATABASE_VERSION = 1;

/**
 * 现代化数据库实现类 Modern database implementation class
 * 使用最新的relationalStore API，替换已弃用的dataRdb API Uses latest relationalStore API, replacing deprecated dataRdb API
 */
export default class ModernDatabaseRepository implements DatabaseRepository {
  private rdbStore: relationalStore.RdbStore | null = null;
  private status: DatabaseStatus = DatabaseStatus.INITIALIZING;
  private configMap: Map<string, string | number | boolean | null> = new Map();
  private context: common.UIAbilityContext | null = null;

  /**
   * 初始化数据库 Initialize database
   * @returns 初始化结果 Initialization result
   */
  async initialize(): Promise<DatabaseResult<void>> {
    try {
      Logger.info(TAG, 'Initializing database...');
      
      const config: relationalStore.StoreConfig = {
        name: DATABASE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };

      // 创建或打开数据库 Create or open database
      const context = this.getContext();
      if (!context) {
        throw new Error('Context not available');
      }
      const rdbStore = await relationalStore.getRdbStore(context, config);
      
      // 设置数据库版本 Set database version
      await rdbStore.setVersion(DATABASE_VERSION);
      
      // 检查是否需要创建或升级数据库 Check if need to create or upgrade database
      const currentVersion = await rdbStore.getVersion();
      if (currentVersion === 0) {
        await this.onCreateDatabase(rdbStore);
      }
      
      this.rdbStore = rdbStore;
      this.status = DatabaseStatus.READY;
      Logger.info(TAG, 'Database initialized successfully');
      
      return {
        success: true
      };
    } catch (error) {
      Logger.error(TAG, `Failed to initialize database: ${error instanceof Error ? error.message : String(error)}`);
      this.status = DatabaseStatus.ERROR;
      return {
        success: false, error: error instanceof Error ? error : new Error(String(error)),
        message: 'Database initialization failed'
      };
    }
  }

  /**
   * 关闭数据库 Close database
   * @returns 关闭结果 Close result
   */
  async close(): Promise<DatabaseResult<void>> {
    try {
      if (this.rdbStore) {
        await this.rdbStore.close();
        this.rdbStore = null;
        this.status = DatabaseStatus.CLOSED;
        Logger.info(TAG, 'Database closed successfully');
      }
      return { success: true };
    } catch (error) {
      Logger.error(TAG, `Failed to close database: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false, error: error instanceof Error ? error : new Error(String(error)),
        message: 'Database closing failed'
      };
    }
  }

  /**
   * 获取数据库状态 Get database status
   * @returns 数据库状态 Database status
   */
  getStatus(): DatabaseStatus {
    return this.status;
  }

  /**
   * 设置上下文 Set context
   * @param context 应用上下文 Application context
   */
  setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * 获取上下文 Get context
   * @returns 应用上下文 Application context
   */
  private getContext(): common.UIAbilityContext | null {
    return this.context;
  }

  /**
   * 创建数据库 Create database
   * @param rdbStore 数据库存储实例 Database store instance
   */
  private async onCreateDatabase(rdbStore: relationalStore.RdbStore): Promise<void> {
    try {
      Logger.info(TAG, 'Creating database tables...');
      
      // 创建表的SQL语句 SQL statements for creating tables
      const createTablesSQL: string[] = [
        // 电影表 Movie table
        `CREATE TABLE IF NOT EXISTS movies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT,
          cover TEXT,
          url TEXT,
          update_time TEXT,
          create_time TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )`,
        
        // 用户表 User table
        `CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          email TEXT,
          avatar TEXT,
          create_time TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )`,
        
        // 历史记录表 History table
        `CREATE TABLE IF NOT EXISTS history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          media_id INTEGER,
          media_type TEXT NOT NULL,
          watched_time INTEGER NOT NULL,
          create_time TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )`,
        
        // 搜索结果表 Search result table
        `CREATE TABLE IF NOT EXISTS search_results (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          keyword TEXT NOT NULL,
          result_type TEXT NOT NULL,
          result_data TEXT NOT NULL,
          create_time TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )`
      ];
      
      // 执行SQL语句 Execute SQL statements
      for (const sql of createTablesSQL) {
        await rdbStore.executeSql(sql);
      }
      
      Logger.info(TAG, 'Database tables created successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to create database tables: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * 保存电影数据 Save movie data
   * @param movie 电影数据 Movie data
   * @returns 保存结果 Save result
   */
  async saveMovie(movie: Movie): Promise<DatabaseResult<Movie>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }
      
      const valuesBucket = {
        name: movie.name,
        type: movie.type,
        cover: movie.cover,
        url: movie.url,
        update_time: movie.updateTime
      };
      
      const id = await this.rdbStore.insert('movies', valuesBucket);
      movie.id = id;
      
      Logger.info(TAG, `Movie saved successfully: ${movie.name}`);
      
      return {
        success: true,
        data: movie
      };
    } catch (error) {
      Logger.error(TAG, `Failed to save movie: ${movie.name}`, error instanceof Error ? error : new Error(String(error)));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to save movie'
      };
    }
  }

  /**
   * 获取电影列表 Get movie list
   * @param params 分页参数 Pagination parameters
   * @returns 电影列表 Movie list
   */
  async getMovies(params: PaginationParams = {}): Promise<DatabaseResult<PaginatedResult<Movie>>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }
      
      const page = params.page || 1;
      const pageSize = params.pageSize || 20;
      const offset = (page - 1) * pageSize;
      
      // 查询总数 Query total count
      const totalResult = await this.rdbStore.querySql(`SELECT COUNT(*) as total FROM movies`);
      let total = 0;
      if (await totalResult.goToFirstRow()) {
        total = totalResult.getLong(0) || 0;
      }
      await totalResult.close();
      
      // 查询数据 Query data
      const querySql = `SELECT * FROM movies ORDER BY create_time DESC LIMIT ? OFFSET ?`;
      const resultSet = await this.rdbStore.querySql(querySql, [pageSize, offset]);
      
      const movies: Movie[] = [];
      while (await resultSet.goToNextRow()) {
        const movie: Movie = {
          id: resultSet.getLong(0),
          name: resultSet.getString(1),
          type: resultSet.getString(2),
          cover: resultSet.getString(3),
          url: resultSet.getString(4),
          updateTime: resultSet.getString(5),
          createTime: resultSet.getString(6)
        };
        movies.push(movie);
      }
      
      await resultSet.close();
      
      const paginatedResult: PaginatedResult<Movie> = {
        items: movies,
        total,
        page,
        pageSize,
        totalPages: Math.ceil(total / pageSize)
      };
      
      return {
        success: true,
        data: paginatedResult
      };
    } catch (error) {
      Logger.error(TAG, 'Failed to get movies', error instanceof Error ? error : new Error(String(error)));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get movies'
      };
    }
  }

  /**
   * 保存搜索结果 Save search result
   * @param keyword 搜索关键词 Search keyword
   * @param result 搜索结果 Search result
   * @returns 保存结果 Save result
   */
  async saveSearchResult(keyword: string, result: SearchResult): Promise<DatabaseResult<void>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }
      
      const valuesBucket = {
        keyword,
        result_type: result.type,
        result_data: JSON.stringify(result)
      };
      
      await this.rdbStore.insert('search_results', valuesBucket);
      
      Logger.info(TAG, `Search result saved for keyword: ${keyword}`);
      
      return {
        success: true
      };
    } catch (error) {
      Logger.error(TAG, `Failed to save search result for keyword: ${keyword}`, error instanceof Error ? error : new Error(String(error)));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to save search result'
      };
    }
  }

  /**
   * 保存用户数据 Save user data
   * @param user 用户数据 User data
   * @returns 保存结果 Save result
   */
  async saveUser(user: User): Promise<DatabaseResult<User>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }
      
      const valuesBucket = {
        username: user.username,
        email: user.email,
        avatar: user.avatar
      };
      
      const id = await this.rdbStore.insert('users', valuesBucket);
      user.id = id;
      
      Logger.info(TAG, `User saved successfully: ${user.username}`);
      
      return {
        success: true,
        data: user
      };
    } catch (error) {
      Logger.error(TAG, `Failed to save user: ${user.username}`, error instanceof Error ? error : new Error(String(error)));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to save user'
      };
    }
  }

  /**
   * 保存历史记录 Save history record
   * @param history 历史记录 History record
   * @returns 保存结果 Save result
   */
  async saveHistory(history: History): Promise<DatabaseResult<History>> {
    try {
      if (!this.rdbStore) {
        throw new Error('Database not initialized');
      }
      
      const valuesBucket = {
        user_id: history.userId,
        media_id: history.mediaId,
        media_type: history.mediaType,
        watched_time: history.watchedTime
      };
      
      const id = await this.rdbStore.insert('history', valuesBucket);
      history.id = id;
      
      Logger.info(TAG, `History record saved successfully: ${history.mediaId}`);
      
      return {
        success: true,
        data: history
      };
    } catch (error) {
      Logger.error(TAG, `Failed to save history record: ${history.mediaId}`, error instanceof Error ? error : new Error(String(error)));
      return {
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to save history record'
      };
    }
  }
}
