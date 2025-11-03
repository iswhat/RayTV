// DatabaseManager.ts - 数据库管理器
// 实现单例模式，负责数据库的初始化、表创建和连接管理

import relationalStore from '@ohos.data.relationalStore';
import { getAllTables, DATABASE_NAME, DATABASE_VERSION, MIGRATIONS } from './TableSchema';
import Logger from '../../common/util/Logger';
import type { Context } from '@ohos.ability.kits.context';

export type ValueType = number | string | boolean | Uint8Array;

/**
 * 数据库管理器
 * 负责数据库的初始化和管理
 */
export class DatabaseManager {
  private static instance: DatabaseManager;
  private database: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;
  private initializationPromise: Promise<void> | null = null;
  
  private readonly TAG: string = 'DatabaseManager';
  
  /**
   * 私有构造函数，防止外部实例化
   */
  private constructor() {}
  
  /**
   * 获取单例实例
   * @returns DatabaseManager 单例实例
   */
  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }
  
  /**
   * 初始化数据库
   * @param context 应用上下文
   * @returns Promise<void>
   */
  public async initDatabase(context: Context): Promise<void> {
    // 如果已经在初始化中，等待初始化完成
    if (this.initializationPromise) {
      return this.initializationPromise;
    }
    
    // 如果已经初始化完成，直接返回
    if (this.isInitialized && this.database) {
      Logger.info(this.TAG, 'Database already initialized');
      return;
    }
    
    try {
      // 创建初始化Promise
      this.initializationPromise = this.doInitDatabase(context);
      await this.initializationPromise;
    } finally {
      // 清除初始化Promise
      this.initializationPromise = null;
    }
  }
  
  /**
   * 实际执行数据库初始化
   * @param context 应用上下文
   * @returns Promise<void>
   * @private
   */
  private async doInitDatabase(context: Context): Promise<void> {
    try {
      Logger.info(this.TAG, 'Initializing database...');
      
      // 配置数据库
      const config: relationalStore.StoreConfig = {
        name: DATABASE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: false // 可以根据需要启用加密
      };
      
      // 获取或创建数据库
      this.database = await relationalStore.getRdbStore(context, config);
      
      // 创建表
      await this.createTables();
      
      // 设置为已初始化
      this.isInitialized = true;
      
      Logger.info(this.TAG, 'Database initialized successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize database: ${error instanceof Error ? error.message : String(error)}`);
      // 重置状态
      this.database = null;
      this.isInitialized = false;
      throw error;
    }
  }
  
  /**
   * 创建数据库表
   * @returns Promise<void>
   * @private
   */
  private async createTables(): Promise<void> {
    if (!this.database) {
      throw new Error('Database not available');
    }
    
    try {
      Logger.info(this.TAG, 'Creating database tables...');
      
      const tables = getAllTables();
      for (const sql of tables) {
        try {
          await this.database.executeSql(sql);
        } catch (error) {
          Logger.error(this.TAG, `Error executing SQL: ${sql}, error: ${error}`);
          // 继续执行其他SQL，不中断整个过程
        }
      }
      
      Logger.info(this.TAG, 'Database tables created successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to create tables: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取数据库实例
   * @returns relationalStore.RdbStore 数据库实例
   * @throws Error 如果数据库未初始化
   */
  public getDatabase(): relationalStore.RdbStore {
    if (!this.database || !this.isInitialized) {
      throw new Error('Database not initialized');
    }
    return this.database;
  }
  
  /**
   * 执行SQL查询
   * @param sql SQL语句
   * @param bindArgs 绑定参数
   * @returns Promise<void>
   */
  public async executeSql(sql: string, bindArgs?: ValueType[]): Promise<void> {
    try {
      const db = this.getDatabase();
      await db.executeSql(sql, bindArgs);
      Logger.debug(this.TAG, `SQL executed: ${sql}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to execute SQL: ${sql}, error: ${error}`);
      throw error;
    }
  }
  
  /**
   * 查询数据
   * @param predicates 查询条件
   * @returns Promise<relationalStore.ResultSet> 查询结果集
   */
  public async query(predicates: relationalStore.RdbPredicates): Promise<relationalStore.ResultSet> {
    try {
      const db = this.getDatabase();
      return await db.query(predicates);
    } catch (error) {
      Logger.error(this.TAG, `Failed to query data: ${error}`);
      throw error;
    }
  }
  
  /**
   * 插入数据
   * @param tableName 表名
   * @param valuesBucket 值桶
   * @returns Promise<number> 插入的行ID
   */
  public async insert(tableName: string, valuesBucket: relationalStore.ValuesBucket): Promise<number> {
    try {
      const db = this.getDatabase();
      const rowId = await db.insert(tableName, valuesBucket);
      Logger.debug(this.TAG, `Inserted data into ${tableName}, rowId: ${rowId}`);
      return rowId;
    } catch (error) {
      Logger.error(this.TAG, `Failed to insert data into ${tableName}: ${error}`);
      throw error;
    }
  }
  
  /**
   * 更新数据
   * @param valuesBucket 值桶
   * @param predicates 查询条件
   * @returns Promise<number> 更新的行数
   */
  public async update(valuesBucket: relationalStore.ValuesBucket, predicates: relationalStore.RdbPredicates): Promise<number> {
    try {
      const db = this.getDatabase();
      const count = await db.update(valuesBucket, predicates);
      Logger.debug(this.TAG, `Updated ${count} rows in ${predicates.getTableName()}`);
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to update data: ${error}`);
      throw error;
    }
  }
  
  /**
   * 删除数据
   * @param predicates 查询条件
   * @returns Promise<number> 删除的行数
   */
  public async delete(predicates: relationalStore.RdbPredicates): Promise<number> {
    try {
      const db = this.getDatabase();
      const count = await db.delete(predicates);
      Logger.debug(this.TAG, `Deleted ${count} rows from ${predicates.getTableName()}`);
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete data: ${error}`);
      throw error;
    }
  }
  
  /**
   * 执行事务
   * @param transactionCallback 事务回调函数
   * @returns Promise<T> 事务执行结果
   */
  public async executeTransaction<T>(transactionCallback: (connection: relationalStore.RdbStore) => Promise<T>): Promise<T> {
    try {
      const db = this.getDatabase();
      return await db.executeTransaction(transactionCallback);
    } catch (error) {
      Logger.error(this.TAG, `Transaction failed: ${error}`);
      throw error;
    }
  }
  
  /**
   * 检查表是否存在
   * @param tableName 表名
   * @returns Promise<boolean> 表是否存在
   */
  public async isTableExists(tableName: string): Promise<boolean> {
    try {
      const db = this.getDatabase();
      const resultSet = await db.querySql(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?", 
        [tableName]
      );
      
      const exists = resultSet.rowCount > 0;
      resultSet.close();
      return exists;
    } catch (error) {
      Logger.error(this.TAG, `Failed to check if table exists: ${error}`);
      return false;
    }
  }
  
  /**
   * 关闭数据库
   */
  public closeDatabase(): void {
    if (this.database) {
      // 在HarmonyOS中，RdbStore没有显式的close方法，由系统管理
      this.database = null;
      this.isInitialized = false;
      Logger.info(this.TAG, 'Database closed');
    }
  }
  
  /**
   * 检查数据库是否已初始化
   * @returns boolean 是否已初始化
   */
  public isDatabaseInitialized(): boolean {
    return this.isInitialized && this.database !== null;
  }
  
  /**
   * 重新初始化数据库（谨慎使用）
   * @param context 应用上下文
   * @returns Promise<void>
   */
  public async reInitializeDatabase(context: Context): Promise<void> {
    try {
      // 先关闭现有数据库
      this.closeDatabase();
      
      // 重新初始化
      await this.initDatabase(context);
      
      Logger.info(this.TAG, 'Database reinitialized successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to reinitialize database: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取数据库版本
   * @returns Promise<number> 数据库版本
   */
  public async getDatabaseVersion(): Promise<number> {
    try {
      const db = this.getDatabase();
      const resultSet = await db.querySql("PRAGMA user_version");
      
      let version = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        version = resultSet.getLong(resultSet.getColumnIndex(0));
      }
      
      resultSet.close();
      return version;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get database version: ${error}`);
      return 0;
    }
  }
  
  /**
   * 设置数据库版本
   * @param version 版本号
   * @returns Promise<void>
   */
  public async setDatabaseVersion(version: number): Promise<void> {
    try {
      await this.executeSql(`PRAGMA user_version = ${version}`);
      Logger.info(this.TAG, `Database version set to ${version}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set database version: ${error}`);
      throw error;
    }
  }
  
  /**
   * 执行数据库迁移
   * @param targetVersion 目标版本
   * @returns Promise<void>
   */
  public async migrateDatabase(targetVersion: number): Promise<void> {
    try {
      const currentVersion = await this.getDatabaseVersion();
      
      if (currentVersion >= targetVersion) {
        Logger.info(this.TAG, `No migration needed. Current version: ${currentVersion}, Target version: ${targetVersion}`);
        return;
      }
      
      Logger.info(this.TAG, `Starting database migration from version ${currentVersion} to ${targetVersion}`);
      
      // 执行每个版本的迁移
      for (let version = currentVersion + 1; version <= targetVersion; version++) {
        if (MIGRATIONS[version]) {
          Logger.info(this.TAG, `Migrating to version ${version}`);
          
          for (const sql of MIGRATIONS[version]) {
            try {
              await this.executeSql(sql);
            } catch (error) {
              Logger.error(this.TAG, `Error executing migration SQL for version ${version}: ${sql}, error: ${error}`);
            }
          }
          
          await this.setDatabaseVersion(version);
        }
      }
      
      Logger.info(this.TAG, `Database migration completed successfully to version ${targetVersion}`);
    } catch (error) {
      Logger.error(this.TAG, `Database migration failed: ${error}`);
      throw error;
    }
  }
}