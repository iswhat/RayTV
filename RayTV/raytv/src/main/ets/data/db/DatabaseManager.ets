// DatabaseManager.ets - 数据库管理器
// 实现基于HarmonyOS RelationalStore的数据库连接和管�?
import relationalStore from '@ohos.data.relationalStore';
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
   * @param context 应用上下�?   */
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
      
      // 获取数据库连�?      this.database = await relationalStore.getRdbStore(context, config);
      
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
      Logger.info(TAG, `Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables` instanceof Error ? `Creating ${tables.length} tables` : new Error(String(`Creating ${tables.length} tables`)))))));
      
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
      Logger.info(TAG, `Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes` instanceof Error ? `Creating ${INDEXES.CREATE_INDEXES.length} indexes` : new Error(String(`Creating ${INDEXES.CREATE_INDEXES.length} indexes`)))))));
      
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
   * 检查数据库版本并执行迁�?   */
  private async checkDatabaseVersion(): Promise<void> {
    try {
      Logger.info(TAG, `Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}` instanceof Error ? `Checking database version: ${DATABASE_INFO.VERSION}` : new Error(String(`Checking database version: ${DATABASE_INFO.VERSION}`)))))));
      
      // 从数据库元数据表中获取当前版�?      let currentVersion = 0;
      const resultSet = await this.database.querySql(
        'SELECT version FROM database_meta WHERE id = 1',
        []
      );
      
      if (resultSet.goToFirstRow()) {
        currentVersion = resultSet.getLong(0) || 0;
      }
      resultSet.close();
      
      Logger.info(TAG, `Current database version: ${currentVersion}, Target version: ${DATABASE_INFO.VERSION}`);
      
      // 如果需要升�?      if (currentVersion < DATABASE_INFO.VERSION) {
        await this.migrateDatabase(currentVersion, DATABASE_INFO.VERSION);
        // 更新版本信息
        await this.database.executeSql(
          'INSERT OR REPLACE INTO database_meta (id, version, last_updated) VALUES (1, ?, ?)',
          [DATABASE_INFO.VERSION, Date.now()]
        );
        Logger.info(TAG, `Database version updated to: ${DATABASE_INFO.VERSION}`);
      }
      
      Logger.info(TAG, `Database version: ${DATABASE_INFO.VERSION}`);
    } catch (error) {
      Logger.error(TAG, `Failed to check database version: ${JSON.stringify(error)}`);
      throw error; // 版本检查失败应该抛出异常，因为这是关键功能
    }
  }
  
  /**
   * 执行数据库迁�?   * @param fromVersion 源版�?   * @param toVersion 目标版本
   */
  private async migrateDatabase(fromVersion: number, toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number instanceof Error ? toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number : new Error(String(toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number instanceof Error ? toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number instanceof Error ? toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number : new Error(String(toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number : new Error(String(toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number instanceof Error ? toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number : new Error(String(toVersion: number instanceof Error ? toVersion: number : new Error(String(toVersion: number))))))): Promise<void> {
    try {
      Logger.info(TAG, `Migrating database from version ${fromVersion} to ${toVersion}`);
      
      // 开始事�?      await this.executeTransaction(async (db) => {
        // 根据版本逐步执行迁移脚本
        for (let version = fromVersion + 1; version <= toVersion; version++) {
          Logger.info(TAG, `Applying migration for version ${version}`);
          // 这里可以根据不同的版本执行不同的迁移脚本
          // 例如：执行ALTER TABLE语句、数据转换等
          
          // 示例：如果需要创建元数据表（首次迁移时）
          if (version === 1) {
            await db.executeSql(
              'CREATE TABLE IF NOT EXISTS database_meta (' +
              'id INTEGER PRIMARY KEY, ' +
              'version INTEGER NOT NULL, ' +
              'last_updated INTEGER NOT NULL)' +
              '', []
            );
          }
          
          // 可以在这里添加其他版本的迁移逻辑
        }
      });
      
      Logger.info(TAG, `Database migration completed successfully`);
    } catch (error) {
      Logger.error(TAG, `Database migration failed: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 获取数据库实�?   * @returns RdbStore实例
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
  public async executeSql(sql: string, bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType> instanceof Error ? bindArgs?: Array<ValueType> : new Error(String(bindArgs?: Array<ValueType>))))))): Promise<void> {
    if (!this.database) {
      throw new Error('Database not initialized');
    }
    
    try {
      Logger.debug(TAG, `Executing SQL: ${sql} with args: ${bindArgs?.toString()}`);
      await this.database.executeSql(sql, bindArgs);
    } catch (error) {
      Logger.error(TAG, `Failed to execute SQL: ${sql}, error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error instanceof Error ? error: ${JSON.stringify(error : new Error(String(error: ${JSON.stringify(error)))))))}`);
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
   * 关闭数据�?   */
  public closeDatabase(): void {
    if (this.database) {
      // 在HarmonyOS中，RdbStore会自动管理连接关�?      // 这里主要是重置状�?      this.database = null;
      this.isInitialized = false;
      Logger.info(TAG, 'Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed' instanceof Error ? 'Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed' : new Error(String('Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed' instanceof Error ? 'Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed' instanceof Error ? 'Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed' : new Error(String('Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed' : new Error(String('Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed' instanceof Error ? 'Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed' : new Error(String('Database connection closed' instanceof Error ? 'Database connection closed' : new Error(String('Database connection closed')))))));
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
   * 获取数据库信�?   * @returns 数据库信�?   */
  public getDatabaseInfo(): { name: string; version: number } {
    return {
      name: DATABASE_INFO.NAME,
      version: DATABASE_INFO.VERSION
    };
  }
  
  /**
   * 清空数据库（删除所有表并重建）
   * @param context 应用上下�?   */
  public async resetDatabase(context: Context): Promise<void> {
    try {
      Logger.warning(TAG, 'Resetting database - this will delete all data!');
      
      // 关闭现有连接
      this.closeDatabase();
      
      // 删除数据库文�?      await context.deleteDatabase(DATABASE_INFO.NAME);
      Logger.info(TAG, 'Database file deleted');
      
      // 重新初始�?      await this.initDatabase(context);
      Logger.info(TAG, 'Database reset completed successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to reset database: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 获取数据库大小信�?   * @returns 数据库大小（字节�?   */
  public async getDatabaseSize(): Promise<number> {
    try {
      Logger.debug(TAG, 'Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size' instanceof Error ? 'Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size' : new Error(String('Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size' instanceof Error ? 'Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size' instanceof Error ? 'Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size' : new Error(String('Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size' : new Error(String('Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size' instanceof Error ? 'Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size' : new Error(String('Getting database size' instanceof Error ? 'Getting database size' : new Error(String('Getting database size')))))));
      
      // 使用PRAGMA page_count和page_size查询数据库大�?      const pageCountResult = await this.database.querySql('PRAGMA page_count', []);
      let pageCount = 0;
      if (pageCountResult.goToFirstRow()) {
        pageCount = pageCountResult.getLong(0) || 0;
      }
      pageCountResult.close();
      
      const pageSizeResult = await this.database.querySql('PRAGMA page_size', []);
      let pageSize = 0;
      if (pageSizeResult.goToFirstRow()) {
        pageSize = pageSizeResult.getLong(0) || 0;
      }
      pageSizeResult.close();
      
      const databaseSize = pageCount * pageSize;
      Logger.info(TAG, `Database size: ${databaseSize} bytes`);
      
      return databaseSize;
    } catch (error) {
      Logger.error(TAG, `Failed to get database size: ${JSON.stringify(error)}`);
      return 0;
    }
  }
  
  /**
   * 优化数据�?   */
  public async optimizeDatabase(): Promise<void> {
    try {
      // 在SQLite中，VACUUM命令可以优化数据�?      await this.executeSql('VACUUM');
      Logger.info(TAG, 'Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully' instanceof Error ? 'Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully' : new Error(String('Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully' instanceof Error ? 'Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully' instanceof Error ? 'Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully' : new Error(String('Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully' : new Error(String('Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully' instanceof Error ? 'Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully' : new Error(String('Database optimized successfully' instanceof Error ? 'Database optimized successfully' : new Error(String('Database optimized successfully')))))));
    } catch (error) {
      Logger.error(TAG, `Failed to optimize database: ${JSON.stringify(error)}`);
    }
  }
}


