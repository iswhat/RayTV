/**
 * DatabaseManager - Database Manager | 数据库管理器
 * Implement database connection and management based on HarmonyOS RelationalStore | 实现基于HarmonyOS RelationalStore的数据库连接和管理
 */
import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { getAllTables, INDEXES, DATABASE_INFO } from './TableSchema';

/**
 * Database information interface | 数据库信息接口
 */
export interface DatabaseInfo {
  name: string; // Database name | 数据库名称
  version: number; // Database version | 数据库版本
}

/**
 * Migration result interface | 迁移结果接口
 */
export interface MigrationResult {
  success: boolean; // Whether successful | 是否成功
  message?: string; // Message | 消息
}

/**
 * Transaction result interface | 事务结果接口
 */
export interface TransactionResult {
  success: boolean; // Whether successful | 是否成功
  affectedRows?: number; // Affected rows | 受影响的行数
}

/**
 * Database size information interface | 数据库大小信息接口
 */
export interface DatabaseSizeInfo {
  pageCount: number; // Page count | 页数
  pageSize: number; // Page size | 页大小
  totalSize: number; // Total size | 总大小
}

const TAG = 'DatabaseManager';

/**
 * DatabaseManager - Database Manager | 数据库管理器
 * Implement database connection and management based on HarmonyOS RelationalStore | 实现基于HarmonyOS RelationalStore的数据库连接和管理
 */
export class DatabaseManager {
  private static instance: DatabaseManager | null = null;
  private database: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;
  private initializationPromise: Promise<void> | null = null;
  
  private constructor() {}
  
  /**
   * Get database manager singleton instance | 获取数据库管理器单例实例
   * @returns Database manager instance | 数据库管理器实例
   */
  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }
  
  /**
   * Initialize database | 初始化数据库
   * @param context Application context | 应用上下文
   */
  public async initDatabase(context: common.Context): Promise<void> {
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
   * Actual initialization logic | 实际的初始化逻辑
   * @param context Application context | 应用上下文
   */
  private async doInitialize(context: common.Context): Promise<void> {
    try {
      console.info(TAG + ': Starting database initialization');
      
      // 使用默认安全级别
      const config: relationalStore.StoreConfig = {
        name: DATABASE_INFO.NAME,
        securityLevel: relationalStore.SecurityLevel.S2
      };
      
      // 获取数据库连接
      this.database = await relationalStore.getRdbStore(context, config);
      
      // 创建表和索引
      await this.createTables();
      await this.createIndexes();
      
      // 检查数据库版本
      await this.checkDatabaseVersion();
      
      this.isInitialized = true;
      console.info(TAG + ': Database initialized successfully');
    } catch (error) {
      console.error(TAG + ': Failed to initialize database: ' + error.message);
      this.isInitialized = false;
      throw error;
    } finally {
      this.initializationPromise = null;
    }
  }
  
  /**
   * Create database tables | 创建数据库表
   */
  private async createTables(): Promise<void> {
    const db = this.database;
    if (!db) {
      throw new Error('Database not initialized');
    }
    
    try {
      const tables = getAllTables();
      console.info(TAG + `: Creating ${tables.length} tables`);
      
      for (const sql of tables) {
        await db.executeSql(sql);
        console.debug(TAG + `: Created table with SQL: ${sql.substring(0, 100)}...`);
      }
      
      console.info(TAG + ': All tables created successfully');
    } catch (error) {
      console.error(TAG + ': Failed to create tables: ' + error.message);
      throw error;
    }
  }
  
  /**
   * Create indexes | 创建索引
   */
  private async createIndexes(): Promise<void> {
    const db = this.database;
    if (!db) {
      throw new Error('Database not initialized');
    }
    
    try {
      console.info(TAG + `: Creating ${INDEXES.CREATE_INDEXES.length} indexes`);
      
      for (const indexSql of INDEXES.CREATE_INDEXES) {
        await db.executeSql(indexSql);
        console.debug(TAG + `: Created index: ${indexSql.substring(0, 80)}...`);
      }
      
      console.info(TAG + ': All indexes created successfully');
    } catch (error) {
      console.error(TAG + ': Failed to create indexes: ' + error.message);
      // 索引创建失败不影响应用运行，记录错误但不抛出异常
    }
  }
  
  /**
   * Check database version and execute migration | 检查数据库版本并执行迁移
   */
  private async checkDatabaseVersion(): Promise<void> {
    const db = this.database;
    if (!db) {
      throw new Error('Database not initialized');
    }
    
    try {
      console.info(TAG + `: Checking database version: ${DATABASE_INFO.VERSION}`);
      
      // 从数据库元数据表中获取当前版本
      let currentVersion = 0;
      const resultSet = await db.querySql(
        'SELECT version FROM database_meta WHERE id = 1',
        []
      );
      
      if (resultSet.goToFirstRow()) {
        currentVersion = resultSet.getLong(0) || 0;
      }
      resultSet.close();
      
      console.info(TAG + `: Current database version: ${currentVersion}, Target version: ${DATABASE_INFO.VERSION}`);
      
      // 如果需要升级 If upgrade is needed
      if (currentVersion < DATABASE_INFO.VERSION) {
        await this.migrateDatabase(currentVersion, DATABASE_INFO.VERSION);
        // 更新版本信息 Update version information
        await db.executeSql(
          'INSERT OR REPLACE INTO database_meta (id, version, last_updated) VALUES (1, ?, ?)',
          [DATABASE_INFO.VERSION, Date.now()]
        );
        console.info(TAG + `: Database version updated to: ${DATABASE_INFO.VERSION}`);
      }
      
      console.info(TAG + `: Database version: ${DATABASE_INFO.VERSION}`);
    } catch (error) {
      console.error(TAG + ': Failed to check database version: ' + error.message);
      throw error; // 版本检查失败应该抛出异常，因为这是关键功能
    }
  }
  
  /**
   * Execute database migration | 执行数据库迁移
   * @param fromVersion Source version | 源版本
   * @param toVersion Target version | 目标版本
   */
  private async migrateDatabase(fromVersion: number, toVersion: number): Promise<void> {
    const database = this.database;
    if (!database) {
      throw new Error('Database not initialized');
    }
    
    try {
      console.info(TAG + `: Migrating database from version ${fromVersion} to ${toVersion}`);
      
      // 开始事务
      await this.executeTransaction(async (db) => {
        // 根据版本逐步执行迁移脚本
        for (let version = fromVersion + 1; version <= toVersion; version++) {
          console.info(TAG + `: Applying migration for version ${version}`);
          // 这里可以根据不同的版本执行不同的迁移脚本
          // 例如：执行ALTER TABLE语句、数据转换等
          
          // 示例：如果需要创建元数据表(第一次迁移时)
          if (version === 1) {
            await db.executeSql(
              'CREATE TABLE IF NOT EXISTS database_meta (id INTEGER PRIMARY KEY, version INTEGER NOT NULL, last_updated INTEGER NOT NULL)',
              []
            );
          }
          
          // 可以在这里添加其他版本的迁移逻辑
        }
      });
      
      console.info(TAG + `: Database migration completed successfully`);
    } catch (error) {
      console.error(TAG + ': Database migration failed: ' + error.message);
      throw error;
    }
  }
  
  /**
   * Get database instance | 获取数据库实例
   * @returns RdbStore instance | RdbStore实例
   */
  public getDatabase(): relationalStore.RdbStore {
    if (!this.database) {
      throw new Error('Database not initialized. Call initDatabase() first.');
    }
    return this.database;
  }
  
  /**
   * Execute SQL query | 执行SQL查询
   * @param sql SQL statement | SQL语句
   * @param bindArgs Bind parameters | 绑定参数
   */
  public async executeSql(sql: string, bindArgs?: Array<number | string | boolean | null>): Promise<void> {
    if (!this.database) {
      throw new Error('Database not initialized');
    }
    
    try {
      console.debug(TAG + `: Executing SQL: ${sql} with args: ${bindArgs?.toString()}`);
      await this.database.executeSql(sql, bindArgs);
    } catch (error) {
      console.error(TAG + ': Failed to execute SQL: ' + sql + ', error: ' + error.message);
      throw error;
    }
  }
  
  /**
   * Execute transaction | 执行事务
   * @param transactionFunc Transaction callback function | 事务回调函数
   */
  public async executeTransaction(transactionFunc: (connection: relationalStore.RdbStore) => Promise<void>): Promise<void> {
    if (!this.database) {
      throw new Error('Database not initialized');
    }
    
    try {
      console.debug(TAG + ': Starting database transaction');
      await transactionFunc(this.database);
      console.debug(TAG + ': Transaction completed successfully');
    } catch (error) {
      console.error(TAG + `: Transaction failed: ${error.message}`);
      throw error;
    }
  }
  
  /**
   * Close database | 关闭数据库
   */
  public closeDatabase(): void {
    if (this.database) {
      // 在HarmonyOS中，RdbStore会自动管理连接生命周期
      // 这里主要是重置状态
      this.database = null;
      this.isInitialized = false;
      console.info(TAG + ': Database connection closed');
    }
  }
  
  /**
   * Check if database is initialized | 检查数据库是否已初始化
   * @returns Whether initialized | 是否已初始化
   */
  public isDatabaseInitialized(): boolean {
    return this.isInitialized && this.database !== null;
  }
  
  /**
   * Get database information | 获取数据库信息
   * @returns Database information | 数据库信息
   */
  public getDatabaseInfo(): DatabaseInfo {
    return {
      name: DATABASE_INFO.NAME,
      version: DATABASE_INFO.VERSION
    };
  }
  
  /**
   * Reset database (delete all tables and rebuild) | 重置数据库(删除所有表并重建)
   * @param context Application context | 应用上下文
   */
  public async resetDatabase(context: common.Context): Promise<void> {
    try {
      console.info(TAG + ': Resetting database - this will delete all data!');
      
      // 关闭现有连接 Close existing connection
      this.closeDatabase();
      
      // 删除数据库文件 Delete database file
      await context.deleteDatabase(DATABASE_INFO.NAME);
      console.info(TAG + ': Database file deleted');
      
      // 重新初始化 Reinitialize
      await this.initDatabase(context);
      console.info(TAG + ': Database reset completed successfully');
    } catch (error: Error) {
      console.error(TAG + `: Failed to reset database: ${error.message}`);
      throw error;
    }
  }
  
  /**
   * Get database size information | 获取数据库大小信息
   * @returns Database size (bytes) | 数据库大小(字节数)
   */
  public async getDatabaseSize(): Promise<number> {
    if (!this.database) {
      console.error(TAG + ': Failed to get database size: Database not initialized');
      return 0;
    }
    
    try {
      console.debug(TAG + ': Getting database size');
      
      // 使用PRAGMA page_count和page_size查询数据库大小 Query database size using PRAGMA page_count and page_size
      const pageCountResult: relationalStore.ResultSet = await this.database.querySql('PRAGMA page_count', []);
      let pageCount = 0;
      if (pageCountResult.goToFirstRow()) {
        pageCount = pageCountResult.getLong(0) || 0;
      }
      pageCountResult.close();
      
      const pageSizeResult: relationalStore.ResultSet = await this.database.querySql('PRAGMA page_size', []);
      let pageSize = 0;
      if (pageSizeResult.goToFirstRow()) {
        pageSize = pageSizeResult.getLong(0) || 0;
      }
      pageSizeResult.close();
      
      const databaseSize = pageCount * pageSize;
      console.info(TAG + `: Database size: ${databaseSize} bytes`);
      
      return databaseSize;
    } catch (error: Error) {
      console.error(TAG + `: Failed to get database size: ${error.message}`);
      return 0;
    }
  }
  
  /**
   * 优化数据库
   */
  public async optimizeDatabase(): Promise<void> {
    if (!this.database) {
      console.error(TAG + ': Failed to optimize database: Database not initialized');
      return;
    }
    
    try {
      // 在SQLite中，VACUUM命令可以优化数据库 In SQLite, VACUUM command can optimize database
      await this.executeSql('VACUUM');
      console.info(TAG + ': Database optimized successfully');
    } catch (error: Error) {
      console.error(TAG + `: Failed to optimize database: ${error.message}`);
    }
  }
}

export default DatabaseManager;
