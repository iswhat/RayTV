import Logger from '../../common/util/Logger';
import { SQLiteHelper } from './SQLiteHelper';
import { SubscriptionItem } from '../../service/config/SubscriptionManager';

const TAG = 'SubscriptionDao';

/**
 * 订阅表定义
 */
export const SUBSCRIPTION_TABLE = {
  TABLE_NAME: 'subscriptions',
  COLUMNS: {
    ID: 'id',
    NAME: 'name',
    URL: 'url',
    DESCRIPTION: 'description',
    TYPE: 'type',
    UPDATE_TIME: 'update_time',
    CREATE_TIME: 'create_time',
    SITE_COUNT: 'site_count',
    ENABLED: 'enabled',
    CURRENT: 'current'
  }
};

/**
 * 订阅数据访问对象
 */
export class SubscriptionDao {
  private sqliteHelper: SQLiteHelper;

  /**
   * 构造函数
   */
  constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    Logger.info(TAG, 'SubscriptionDao initialized');
  }

  /**
   * 初始化订阅表
   */
  public async initialize(): Promise<void> {
    try {
      const createTableSQL = `
        CREATE TABLE IF NOT EXISTS ${SUBSCRIPTION_TABLE.TABLE_NAME} (
          ${SUBSCRIPTION_TABLE.COLUMNS.ID} TEXT PRIMARY KEY,
          ${SUBSCRIPTION_TABLE.COLUMNS.NAME} TEXT NOT NULL,
          ${SUBSCRIPTION_TABLE.COLUMNS.URL} TEXT NOT NULL UNIQUE,
          ${SUBSCRIPTION_TABLE.COLUMNS.DESCRIPTION} TEXT,
          ${SUBSCRIPTION_TABLE.COLUMNS.TYPE} TEXT DEFAULT 'all',
          ${SUBSCRIPTION_TABLE.COLUMNS.UPDATE_TIME} INTEGER DEFAULT 0,
          ${SUBSCRIPTION_TABLE.COLUMNS.CREATE_TIME} INTEGER DEFAULT 0,
          ${SUBSCRIPTION_TABLE.COLUMNS.SITE_COUNT} INTEGER DEFAULT 0,
          ${SUBSCRIPTION_TABLE.COLUMNS.ENABLED} INTEGER DEFAULT 1,
          ${SUBSCRIPTION_TABLE.COLUMNS.CURRENT} INTEGER DEFAULT 0
        );
      `;
      
      await this.sqliteHelper.execute(createTableSQL);
      Logger.info(TAG, 'Subscription table initialized');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize subscription table: ${error}`);
      throw error;
    }
  }

  /**
   * 保存订阅
   * @param subscription 订阅信息
   */
  public async save(subscription: SubscriptionItem): Promise<boolean> {
    try {
      const sql = `
        INSERT OR REPLACE INTO ${SUBSCRIPTION_TABLE.TABLE_NAME}
        (${SUBSCRIPTION_TABLE.COLUMNS.ID}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.NAME}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.URL}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.DESCRIPTION}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.TYPE}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.UPDATE_TIME}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.CREATE_TIME}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.SITE_COUNT}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.ENABLED}, 
         ${SUBSCRIPTION_TABLE.COLUMNS.CURRENT})
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      
      const params = [
        subscription.id,
        subscription.name,
        subscription.url,
        subscription.description || '',
        subscription.type || 'all',
        subscription.updateTime,
        subscription.createTime,
        subscription.siteCount,
        subscription.enabled ? 1 : 0,
        subscription.current ? 1 : 0
      ];
      
      const result = await this.sqliteHelper.execute(sql, params);
      Logger.info(TAG, `Saved subscription: ${subscription.name} (${subscription.id})`);
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to save subscription: ${error}`);
      return false;
    }
  }

  /**
   * 批量保存订阅
   * @param subscriptions 订阅列表
   */
  public async saveAll(subscriptions: SubscriptionItem[]): Promise<boolean> {
    try {
      // 开始事务
      await this.sqliteHelper.beginTransaction();
      
      try {
        for (const subscription of subscriptions) {
          await this.save(subscription);
        }
        
        // 提交事务
        await this.sqliteHelper.commitTransaction();
        Logger.info(TAG, `Saved ${subscriptions.length} subscriptions`);
        return true;
      } catch (error) {
        // 回滚事务
        await this.sqliteHelper.rollbackTransaction();
        throw error;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save all subscriptions: ${error}`);
      return false;
    }
  }

  /**
   * 获取所有订阅
   */
  public async getAll(): Promise<SubscriptionItem[]> {
    try {
      const sql = `
        SELECT * FROM ${SUBSCRIPTION_TABLE.TABLE_NAME}
        ORDER BY ${SUBSCRIPTION_TABLE.COLUMNS.CREATE_TIME} DESC
      `;
      
      const result = await this.sqliteHelper.query(sql);
      const subscriptions: SubscriptionItem[] = [];
      
      if (result.success && result.result && result.result.length > 0) {
        for (const row of result.result) {
          subscriptions.push(this.mapRowToSubscription(row));
        }
      }
      
      Logger.info(TAG, `Retrieved ${subscriptions.length} subscriptions`);
      return subscriptions;
    } catch (error) {
      Logger.error(TAG, `Failed to get all subscriptions: ${error}`);
      return [];
    }
  }

  /**
   * 根据ID获取订阅
   * @param id 订阅ID
   */
  public async getById(id: string): Promise<SubscriptionItem | null> {
    try {
      const sql = `
        SELECT * FROM ${SUBSCRIPTION_TABLE.TABLE_NAME}
        WHERE ${SUBSCRIPTION_TABLE.COLUMNS.ID} = ?
      `;
      
      const result = await this.sqliteHelper.query(sql, [id]);
      
      if (result.success && result.result && result.result.length > 0) {
        const subscription = this.mapRowToSubscription(result.result[0]);
        Logger.info(TAG, `Retrieved subscription by ID: ${id}`);
        return subscription;
      }
      
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get subscription by ID: ${error}`);
      return null;
    }
  }

  /**
   * 根据URL获取订阅
   * @param url 订阅URL
   */
  public async getByUrl(url: string): Promise<SubscriptionItem | null> {
    try {
      const sql = `
        SELECT * FROM ${SUBSCRIPTION_TABLE.TABLE_NAME}
        WHERE ${SUBSCRIPTION_TABLE.COLUMNS.URL} = ?
      `;
      
      const result = await this.sqliteHelper.query(sql, [url]);
      
      if (result.success && result.result && result.result.length > 0) {
        const subscription = this.mapRowToSubscription(result.result[0]);
        Logger.info(TAG, `Retrieved subscription by URL: ${url}`);
        return subscription;
      }
      
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get subscription by URL: ${error}`);
      return null;
    }
  }

  /**
   * 获取当前使用的订阅
   */
  public async getCurrent(): Promise<SubscriptionItem | null> {
    try {
      const sql = `
        SELECT * FROM ${SUBSCRIPTION_TABLE.TABLE_NAME}
        WHERE ${SUBSCRIPTION_TABLE.COLUMNS.CURRENT} = 1
      `;
      
      const result = await this.sqliteHelper.query(sql);
      
      if (result.success && result.result && result.result.length > 0) {
        const subscription = this.mapRowToSubscription(result.result[0]);
        Logger.info(TAG, `Retrieved current subscription`);
        return subscription;
      }
      
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get current subscription: ${error}`);
      return null;
    }
  }

  /**
   * 删除订阅
   * @param id 订阅ID
   */
  public async delete(id: string): Promise<boolean> {
    try {
      const sql = `
        DELETE FROM ${SUBSCRIPTION_TABLE.TABLE_NAME}
        WHERE ${SUBSCRIPTION_TABLE.COLUMNS.ID} = ?
      `;
      
      const result = await this.sqliteHelper.execute(sql, [id]);
      Logger.info(TAG, `Deleted subscription: ${id}`);
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to delete subscription: ${error}`);
      return false;
    }
  }

  /**
   * 清空所有订阅
   */
  public async clearAll(): Promise<boolean> {
    try {
      const sql = `DELETE FROM ${SUBSCRIPTION_TABLE.TABLE_NAME}`;
      const result = await this.sqliteHelper.execute(sql);
      Logger.info(TAG, 'Cleared all subscriptions');
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to clear all subscriptions: ${error}`);
      return false;
    }
  }

  /**
   * 设置订阅为当前使用
   * @param id 订阅ID
   */
  public async setCurrent(id: string): Promise<boolean> {
    try {
      // 开始事务
      await this.sqliteHelper.beginTransaction();
      
      try {
        // 先将所有订阅设置为非当前
        const resetSql = `
          UPDATE ${SUBSCRIPTION_TABLE.TABLE_NAME}
          SET ${SUBSCRIPTION_TABLE.COLUMNS.CURRENT} = 0
        `;
        await this.sqliteHelper.execute(resetSql);
        
        // 设置指定订阅为当前
        const setSql = `
          UPDATE ${SUBSCRIPTION_TABLE.TABLE_NAME}
          SET ${SUBSCRIPTION_TABLE.COLUMNS.CURRENT} = 1
          WHERE ${SUBSCRIPTION_TABLE.COLUMNS.ID} = ?
        `;
        await this.sqliteHelper.execute(setSql, [id]);
        
        // 提交事务
        await this.sqliteHelper.commitTransaction();
        
        Logger.info(TAG, `Set subscription ${id} as current`);
        return true;
      } catch (error) {
        // 回滚事务
        await this.sqliteHelper.rollbackTransaction();
        throw error;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to set subscription as current: ${error}`);
      return false;
    }
  }

  /**
   * 更新订阅启用状态
   * @param id 订阅ID
   * @param enabled 是否启用
   */
  public async updateEnabled(id: string, enabled: boolean): Promise<boolean> {
    try {
      const sql = `
        UPDATE ${SUBSCRIPTION_TABLE.TABLE_NAME}
        SET ${SUBSCRIPTION_TABLE.COLUMNS.ENABLED} = ?
        WHERE ${SUBSCRIPTION_TABLE.COLUMNS.ID} = ?
      `;
      
      const result = await this.sqliteHelper.execute(sql, [enabled ? 1 : 0, id]);
      
      // 如果禁用的是当前订阅，同时取消其当前状态
      if (!enabled) {
        const currentSql = `
          UPDATE ${SUBSCRIPTION_TABLE.TABLE_NAME}
          SET ${SUBSCRIPTION_TABLE.COLUMNS.CURRENT} = 0
          WHERE ${SUBSCRIPTION_TABLE.COLUMNS.ID} = ?
        `;
        await this.sqliteHelper.execute(currentSql, [id]);
      }
      
      Logger.info(TAG, `Updated subscription ${id} enabled: ${enabled}`);
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to update subscription enabled status: ${error}`);
      return false;
    }
  }

  /**
   * 更新订阅信息
   * @param subscription 订阅信息
   */
  public async update(subscription: SubscriptionItem): Promise<boolean> {
    try {
      const sql = `
        UPDATE ${SUBSCRIPTION_TABLE.TABLE_NAME}
        SET ${SUBSCRIPTION_TABLE.COLUMNS.NAME} = ?,
            ${SUBSCRIPTION_TABLE.COLUMNS.URL} = ?,
            ${SUBSCRIPTION_TABLE.COLUMNS.DESCRIPTION} = ?,
            ${SUBSCRIPTION_TABLE.COLUMNS.TYPE} = ?,
            ${SUBSCRIPTION_TABLE.COLUMNS.UPDATE_TIME} = ?,
            ${SUBSCRIPTION_TABLE.COLUMNS.SITE_COUNT} = ?,
            ${SUBSCRIPTION_TABLE.COLUMNS.ENABLED} = ?,
            ${SUBSCRIPTION_TABLE.COLUMNS.CURRENT} = ?
        WHERE ${SUBSCRIPTION_TABLE.COLUMNS.ID} = ?
      `;
      
      const params = [
        subscription.name,
        subscription.url,
        subscription.description || '',
        subscription.type || 'all',
        subscription.updateTime,
        subscription.siteCount,
        subscription.enabled ? 1 : 0,
        subscription.current ? 1 : 0,
        subscription.id
      ];
      
      const result = await this.sqliteHelper.execute(sql, params);
      Logger.info(TAG, `Updated subscription: ${subscription.id}`);
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to update subscription: ${error}`);
      return false;
    }
  }

  /**
   * 将数据库行映射为订阅对象
   * @param row 数据库行
   */
  private mapRowToSubscription(row: any): SubscriptionItem {
    return {
      id: row[SUBSCRIPTION_TABLE.COLUMNS.ID],
      name: row[SUBSCRIPTION_TABLE.COLUMNS.NAME],
      url: row[SUBSCRIPTION_TABLE.COLUMNS.URL],
      description: row[SUBSCRIPTION_TABLE.COLUMNS.DESCRIPTION] || undefined,
      type: row[SUBSCRIPTION_TABLE.COLUMNS.TYPE] || 'all',
      updateTime: row[SUBSCRIPTION_TABLE.COLUMNS.UPDATE_TIME] || 0,
      createTime: row[SUBSCRIPTION_TABLE.COLUMNS.CREATE_TIME] || 0,
      siteCount: row[SUBSCRIPTION_TABLE.COLUMNS.SITE_COUNT] || 0,
      enabled: row[SUBSCRIPTION_TABLE.COLUMNS.ENABLED] === 1,
      current: row[SUBSCRIPTION_TABLE.COLUMNS.CURRENT] === 1
    };
  }
}
