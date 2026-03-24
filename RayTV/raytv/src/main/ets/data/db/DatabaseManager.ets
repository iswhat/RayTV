// DatabaseManager.ets - 数据库管理器 | Database manager
import relationalStore from '@ohos.data.relationalStore';
import Logger from '../../common/util/Logger';

const TAG = 'DatabaseManager';

const DB_NAME = 'raytv.db';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

/**
 * 数据库管理器 | Database manager
 * 负责管理SQLite数据库连接 | Responsible for managing SQLite database connections
 */
export class DatabaseManager {
  private static instance: DatabaseManager;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {}

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  /**
   * 获取数据库实例 | Get database instance
   */
  public async getDatabase(): Promise<relationalStore.RdbStore> {
    if (this.rdbStore) {
      return this.rdbStore;
    }
    throw new Error('DatabaseManager: database not initialized. Call initialize() first.');
  }

  /**
   * 初始化数据库 | Initialize database
   */
  public async initialize(context: Object): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(context as never, STORE_CONFIG);
      Logger.info(TAG, 'Database initialized successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to initialize database', err);
      throw err;
    }
  }

  /**
   * 执行事务 | Execute transaction
   */
  public async executeTransaction<T>(operation: (db: relationalStore.RdbStore) => Promise<T>): Promise<T> {
    const db = await this.getDatabase();
    db.beginTransaction();
    try {
      const result = await operation(db);
      db.commit();
      return result;
    } catch (error) {
      db.rollBack();
      const err = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 关闭数据库 | Close database
   */
  public async close(): Promise<void> {
    if (this.rdbStore) {
      try {
        await this.rdbStore.close();
        this.rdbStore = null;
        Logger.info(TAG, 'Database closed successfully');
      } catch (error) {
        const err = error instanceof Error ? error : new Error(String(error));
        Logger.error(TAG, 'Failed to close database', err);
        throw err;
      }
    }
  }
}

export default DatabaseManager;
