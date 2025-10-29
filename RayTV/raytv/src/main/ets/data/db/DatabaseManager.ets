// DatabaseManager.ets - 数据库管理器
// 实现基于HarmonyOS RelationalStore的数据库连接和管理

import relationalStore from '@kit.RelationalStore';
import { getAllTables, INDEXES, DATABASE_INFO } from './TableSchema';
import Logger from '../../common/util/Logger';

const TAG = 'DatabaseManager';

export class DatabaseManager {
  private static instance: DatabaseManager;
  private database: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;
  private initializationPromise: Promise<void> | null = null;
  
  private constructor() {}
  
  /**
   * 获取数据库管理器单例实例
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
   */
  public async initDatabase(context: Context): Promise<void> {
    // 如果已经初始化或正在初始化，返回现有Promise
    if (this.isInitialized) {
      return;
    }
    
    if (this.initializationPromise) {
      return this.initializationPromise;
    }
    
    // 创建新的初始化Promise以避免重复初始化
    this.initializationPromise = this.doInitialize(context);
    return this.initializationPromise;
  }
  
  /**
   * 实际的初始化逻辑
   */
  private async doInitialize(context: Context): Promise<void> {
    try {
      Logger.info(TAG, 'Starting database initialization');
      
      const config: relationalStore.StoreConfig = {
        name: DATABASE_INFO.NAME,
        securityLevel: relationalStore.SecurityLevel[DATABASE_INFO.SECURITY_LEVEL as keyof typeof relationalStore.SecurityLevel]
      };
      
      // 获取数据库连接
      this.database = await relationalStore.getRdbStore(context, config);
      
      // 创建表和索引
      await this.createTables();
      await this.createIndexes();
      
      // 检查数据库版本
      await this.checkDatabaseVersion();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Database initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize database: ${JSON.stringify(error)}`);
      this.isInitialized = false;
      throw error;
    } finally {
      this.initializationPromise = null;
    }
  }
  
  /**
   * 创建数据库表
   */
  private async createTables(): Promise<void> {
    if (!this.database) {
      throw new Error('Database not initialized');
    }
    
    try {
      const tables = getAllTables();
      Logger.info(TAG, `Creating ${tables.length} tables`);
      
      for (const sql of tables) {
        await this.database.executeSql(sql);
        Logger.debug(TAG, `Created table with SQL: ${sql.substring(0, 100)}...`);
      }
      
      Logger.info(TAG, 'All tables created successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to create tables: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 创建索引
   */
  private async createIndexes(): Promise<void> {
    if (!this.database) {
      throw new Error('Database not initialized');
    }
    
    try {
      Logger.info(TAG, `Creating ${INDEXES.CREATE_INDEXES.length} indexes`);
      
      for (const indexSql of INDEXES.CREATE_INDEXES) {
        await this.database.executeSql(indexSql);
        Logger.debug(TAG, `Created index: ${indexSql.substring(0, 80)}...`);
      }
      
      Logger.info(TAG, 'All indexes created successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to create indexes: ${JSON.stringify(error)}`);
      // 索引创建失败不影响应用运行，记录错误但不抛出异常
    }
  }
  
  /**
   * 检查数据库版本
   */
  private async checkDatabaseVersion(): Promise<void> {
    try {
      // TODO: 实现数据库版本管理和迁移逻辑
      Logger.info(TAG, `Database version: ${DATABASE_INFO.VERSION}`);
    } catch (error) {
      Logger.error(TAG, `Failed to check database version: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 获取数据库实例
   * @returns RdbStore实例
   */
  public getDatabase(): relationalStore.RdbStore {
    if (!this.database) {
      throw new Error('Database not initialized. Call initDatabase() first.');
    }
    return this.database;
  }
  
  /**
   * 执行SQL查询
   * @param sql SQL语句
   * @param bindArgs 绑定参数
   */
  public async executeSql(sql: string, bindArgs?: Array<ValueType>): Promise<void> {
    if (!this.database) {
      throw new Error('Database not initialized');
    }
    
    try {
      Logger.debug(TAG, `Executing SQL: ${sql} with args: ${bindArgs?.toString()}`);
      await this.database.executeSql(sql, bindArgs);
    } catch (error) {
      Logger.error(TAG, `Failed to execute SQL: ${sql}, error: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 执行事务
   * @param transactionFunc 事务回调函数
   */
  public async executeTransaction(transactionFunc: (connection: relationalStore.RdbStore) => Promise<void>): Promise<void> {
    if (!this.database) {
      throw new Error('Database not initialized');
    }
    
    try {
      Logger.debug(TAG, 'Starting database transaction');
      await transactionFunc(this.database);
      Logger.debug(TAG, 'Transaction completed successfully');
    } catch (error) {
      Logger.error(TAG, `Transaction failed: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 关闭数据库
   */
  public closeDatabase(): void {
    if (this.database) {
      // 在HarmonyOS中，RdbStore会自动管理连接关闭
      // 这里主要是重置状态
      this.database = null;
      this.isInitialized = false;
      Logger.info(TAG, 'Database connection closed');
    }
  }
  
  /**
   * 检查数据库是否已初始化
   * @returns 是否已初始化
   */
  public isDatabaseInitialized(): boolean {
    return this.isInitialized && this.database !== null;
  }
  
  /**
   * 获取数据库信息
   * @returns 数据库信息
   */
  public getDatabaseInfo(): { name: string; version: number } {
    return {
      name: DATABASE_INFO.NAME,
      version: DATABASE_INFO.VERSION
    };
  }
  
  /**
   * 清空数据库（删除所有表并重建）
   * @param context 应用上下文
   */
  public async resetDatabase(context: Context): Promise<void> {
    try {
      Logger.warning(TAG, 'Resetting database - this will delete all data!');
      
      // 关闭现有连接
      this.closeDatabase();
      
      // 删除数据库文件
      await context.deleteDatabase(DATABASE_INFO.NAME);
      Logger.info(TAG, 'Database file deleted');
      
      // 重新初始化
      await this.initDatabase(context);
      Logger.info(TAG, 'Database reset completed successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to reset database: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 获取数据库大小信息
   * @returns 数据库大小（字节）
   */
  public async getDatabaseSize(): Promise<number> {
    try {
      // TODO: 实现获取数据库文件大小的逻辑
      return 0;
    } catch (error) {
      Logger.error(TAG, `Failed to get database size: ${JSON.stringify(error)}`);
      return 0;
    }
  }
  
  /**
   * 优化数据库
   */
  public async optimizeDatabase(): Promise<void> {
    try {
      // 在SQLite中，VACUUM命令可以优化数据库
      await this.executeSql('VACUUM');
      Logger.info(TAG, 'Database optimized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to optimize database: ${JSON.stringify(error)}`);
    }
  }
}