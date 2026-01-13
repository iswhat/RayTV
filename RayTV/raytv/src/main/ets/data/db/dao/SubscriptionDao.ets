import Logger from '../../../common/util/Logger';
import { DatabaseManager } from '../DatabaseManager';
import { TableSchema } from '../TableSchema';
import { ValuesBucket, RdbPredicates as RelationalPredicates, ResultSet } from '@ohos.data.relationalStore';

/**
 * 订阅数据结构 | Subscription data structure
 */
export interface SubscriptionItem {
  id: string;
  name: string;
  url: string;
  description?: string;
  updateTime: number;
  createTime: number;
  siteCount: number;
  enabled: boolean;
  current: boolean;
}

/**
 * 订阅数据访问对象 | Subscription data access object
 * 实现订阅相关的数据库操作 | Implements subscription-related database operations
 */
export class SubscriptionDao {
  private readonly TAG: string = 'SubscriptionDao';
  private databaseManager: DatabaseManager;

  constructor() {
    this.databaseManager = DatabaseManager.getInstance();
  }

  /**
   * 初始化订阅表 | Initialize subscription table
   * @param context 应用上下文 | Application context
   */
  public async initTable(context: Record<string, string | number | boolean | null>): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      Logger.info(this.TAG, 'Subscription table initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize subscription table: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 保存订阅项 | Save subscription item
   * @param subscription 订阅项 | Subscription item
   */
  public async save(subscription: SubscriptionItem): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.subscriptionToValuesBucket(subscription);
      
      await db.insert(TableSchema.SUBSCRIPTION_TABLE, valuesBucket);
      Logger.info(this.TAG, `Subscription saved: ${subscription.name}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save subscription: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 更新订阅项 | Update subscription item
   * @param subscription 订阅项 | Subscription item
   */
  public async update(subscription: SubscriptionItem): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.subscriptionToValuesBucket(subscription);
      const predicates = new RelationalPredicates(TableSchema.SUBSCRIPTION_TABLE);
      predicates.equalTo(TableSchema.SUBSCRIPTION_ID, subscription.id);
      
      const rowsAffected = await db.update(valuesBucket, predicates);
      Logger.info(this.TAG, `Subscription updated: ${subscription.name}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update subscription: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 保存或更新订阅项 | Save or update subscription item
   * @param subscription 订阅项 | Subscription item
   */
  public async saveOrUpdate(subscription: SubscriptionItem): Promise<void> {
    try {
      const existingSubscription = await this.getById(subscription.id);
      if (existingSubscription) {
        await this.update(subscription);
      } else {
        await this.save(subscription);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to save or update subscription: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 删除订阅项 | Delete subscription item
   * @param subscriptionId 订阅ID | Subscription ID
   */
  public async delete(subscriptionId: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.SUBSCRIPTION_TABLE);
      predicates.equalTo(TableSchema.SUBSCRIPTION_ID, subscriptionId);
      
      const rowsAffected = await db.delete(predicates);
      Logger.info(this.TAG, `Subscription deleted: ${subscriptionId}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete subscription: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取所有订阅项 | Get all subscription items
   * @returns 订阅项列表 | Subscription item list
   */
  public async getAll(): Promise<SubscriptionItem[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.SUBSCRIPTION_TABLE);
      const resultSet = await db.query(predicates);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all subscriptions: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 根据ID获取订阅项 | Get subscription item by ID
   * @param subscriptionId 订阅ID | Subscription ID
   * @returns 订阅项或undefined | Subscription item or undefined
   */
  public async getById(subscriptionId: string): Promise<SubscriptionItem | undefined> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.SUBSCRIPTION_TABLE);
      predicates.equalTo(TableSchema.SUBSCRIPTION_ID, subscriptionId);
      const resultSet = await db.query(predicates);
      
      const subscriptions = this.parseResultSet(resultSet);
      return subscriptions.length > 0 ? subscriptions[0] : undefined;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get subscription by id: ${error instanceof Error ? error.message : String(error)}`);
      return undefined;
    }
  }

  /**
   * 获取当前使用的订阅项 | Get current subscription item
   * @returns 当前订阅项或undefined | Current subscription item or undefined
   */
  public async getCurrent(): Promise<SubscriptionItem | undefined> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.SUBSCRIPTION_TABLE);
      predicates.equalTo(TableSchema.SUBSCRIPTION_CURRENT, 1);
      const resultSet = await db.query(predicates);
      
      const subscriptions = this.parseResultSet(resultSet);
      return subscriptions.length > 0 ? subscriptions[0] : undefined;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get current subscription: ${error instanceof Error ? error.message : String(error)}`);
      return undefined;
    }
  }

  /**
   * 获取已启用的订阅项 | Get enabled subscription items
   * @returns 已启用的订阅项列表 | Enabled subscription item list
   */
  public async getEnabled(): Promise<SubscriptionItem[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.SUBSCRIPTION_TABLE);
      predicates.equalTo(TableSchema.SUBSCRIPTION_ENABLED, 1);
      const resultSet = await db.query(predicates);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get enabled subscriptions: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 批量保存订阅项 | Batch save subscription items
   * @param subscriptions 订阅项列表 | Subscription item list
   */
  public async saveAll(subscriptions: SubscriptionItem[]): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      
      // 使用事务批量保存 | Use transaction for batch saving
      await db.beginTransaction();
      
      try {
        for (const subscription of subscriptions) {
          await this.saveOrUpdate(subscription);
        }
        await db.commit();
        Logger.info(this.TAG, `Batch saved ${subscriptions.length} subscriptions`);
      } catch (error) {
        await db.rollback();
        throw error;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch save subscriptions: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 将订阅项转换为ValuesBucket | Convert subscription item to ValuesBucket
   * @param subscription 订阅项 | Subscription item
   * @returns ValuesBucket
   */
  private subscriptionToValuesBucket(subscription: SubscriptionItem): ValuesBucket {
    return {
      [TableSchema.SUBSCRIPTION_ID]: subscription.id,
      [TableSchema.SUBSCRIPTION_NAME]: subscription.name,
      [TableSchema.SUBSCRIPTION_URL]: subscription.url,
      [TableSchema.SUBSCRIPTION_DESCRIPTION]: subscription.description || '',
      [TableSchema.SUBSCRIPTION_UPDATE_TIME]: subscription.updateTime,
      [TableSchema.SUBSCRIPTION_CREATE_TIME]: subscription.createTime,
      [TableSchema.SUBSCRIPTION_SITE_COUNT]: subscription.siteCount,
      [TableSchema.SUBSCRIPTION_ENABLED]: subscription.enabled ? 1 : 0,
      [TableSchema.SUBSCRIPTION_CURRENT]: subscription.current ? 1 : 0
    };
  }

  /**
   * 解析ResultSet为订阅项列表 | Parse ResultSet to subscription item list
   * @param resultSet 查询结果集 | Query result set
   * @returns 订阅项列表 | Subscription item list
   */
  private parseResultSet(resultSet: ResultSet): SubscriptionItem[] {
    const subscriptions: SubscriptionItem[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const subscription: SubscriptionItem = {
            id: resultSet.getString(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_ID)),
            name: resultSet.getString(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_NAME)),
            url: resultSet.getString(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_URL)),
            description: resultSet.getString(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_DESCRIPTION)),
            updateTime: resultSet.getLong(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_UPDATE_TIME)),
            createTime: resultSet.getLong(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_CREATE_TIME)),
            siteCount: resultSet.getLong(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_SITE_COUNT)),
            enabled: resultSet.getLong(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_ENABLED)) === 1,
            current: resultSet.getLong(resultSet.getColumnIndex(TableSchema.SUBSCRIPTION_CURRENT)) === 1
          };
          
          subscriptions.push(subscription);
        } while (resultSet.goToNextRow());
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse result set: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      resultSet.close();
    }
    
    return subscriptions;
  }
}

export const subscriptionDao = new SubscriptionDao();
