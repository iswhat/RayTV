import Logger from '../../common/util/Logger';
import { DatabaseManager } from '../db/DatabaseManager';
import { TableSchema } from '../db/TableSchema';
import { ValuesBucket, RelationalPredicates, ResultSet } from '@ohos.data.relationalStore';

/**
 * 订阅项数据结构
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
 * 订阅数据访问对象
 * 负责订阅相关的数据库操作
 */
export class SubscriptionDao {
  private readonly TAG: string = 'SubscriptionDao';
  private databaseManager: DatabaseManager;

  constructor() {
    this.databaseManager = DatabaseManager.getInstance();
  }

  /**
   * 初始化订阅表
   * @param context 应用上下文
   */
  public async initTable(context: any): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      Logger.info(this.TAG, 'Subscription table initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize subscription table: ${error}`);
      throw error;
    }
  }

  /**
   * 保存订阅项
   * @param subscription 订阅项
   */
  public async save(subscription: SubscriptionItem): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.subscriptionToValuesBucket(subscription);
      
      await db.insert(TableSchema.SUBSCRIPTION_TABLE, valuesBucket);
      Logger.info(this.TAG, `Subscription saved: ${subscription.name}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save subscription: ${error}`);
      throw error;
    }
  }

  /**
   * 更新订阅项
   * @param subscription 订阅项
   */
  public async update(subscription: SubscriptionItem): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.subscriptionToValuesBucket(subscription);
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SUBSCRIPTION_ID, subscription.id);
      
      const rowsAffected = await db.update(TableSchema.SUBSCRIPTION_TABLE, valuesBucket, predicates);
      Logger.info(this.TAG, `Subscription updated: ${subscription.name}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update subscription: ${error}`);
      throw error;
    }
  }

  /**
   * 保存或更新订阅项
   * @param subscription 订阅项
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
      Logger.error(this.TAG, `Failed to save or update subscription: ${error}`);
      throw error;
    }
  }

  /**
   * 删除订阅项
   * @param subscriptionId 订阅ID
   */
  public async delete(subscriptionId: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SUBSCRIPTION_ID, subscriptionId);
      
      const rowsAffected = await db.delete(TableSchema.SUBSCRIPTION_TABLE, predicates);
      Logger.info(this.TAG, `Subscription deleted: ${subscriptionId}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete subscription: ${error}`);
      throw error;
    }
  }

  /**
   * 获取所有订阅项
   * @returns 订阅项列表
   */
  public async getAll(): Promise<SubscriptionItem[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      const resultSet = await db.query(TableSchema.SUBSCRIPTION_TABLE, predicates);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all subscriptions: ${error}`);
      return [];
    }
  }

  /**
   * 根据ID获取订阅项
   * @param subscriptionId 订阅ID
   * @returns 订阅项或undefined
   */
  public async getById(subscriptionId: string): Promise<SubscriptionItem | undefined> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SUBSCRIPTION_ID, subscriptionId);
      const resultSet = await db.query(TableSchema.SUBSCRIPTION_TABLE, predicates);
      
      const subscriptions = this.parseResultSet(resultSet);
      return subscriptions.length > 0 ? subscriptions[0] : undefined;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get subscription by id: ${error}`);
      return undefined;
    }
  }

  /**
   * 获取当前使用的订阅项
   * @returns 当前订阅项或undefined
   */
  public async getCurrent(): Promise<SubscriptionItem | undefined> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SUBSCRIPTION_CURRENT, true);
      const resultSet = await db.query(TableSchema.SUBSCRIPTION_TABLE, predicates);
      
      const subscriptions = this.parseResultSet(resultSet);
      return subscriptions.length > 0 ? subscriptions[0] : undefined;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get current subscription: ${error}`);
      return undefined;
    }
  }

  /**
   * 获取已启用的订阅项
   * @returns 已启用的订阅项列表
   */
  public async getEnabled(): Promise<SubscriptionItem[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SUBSCRIPTION_ENABLED, true);
      const resultSet = await db.query(TableSchema.SUBSCRIPTION_TABLE, predicates);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get enabled subscriptions: ${error}`);
      return [];
    }
  }

  /**
   * 批量保存订阅项
   * @param subscriptions 订阅项列表
   */
  public async saveAll(subscriptions: SubscriptionItem[]): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      
      // 使用事务批量保存
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
      Logger.error(this.TAG, `Failed to batch save subscriptions: ${error}`);
      throw error;
    }
  }

  /**
   * 将订阅项转换为ValuesBucket
   * @param subscription 订阅项
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
      [TableSchema.SUBSCRIPTION_ENABLED]: subscription.enabled,
      [TableSchema.SUBSCRIPTION_CURRENT]: subscription.current
    };
  }

  /**
   * 解析ResultSet为订阅项列表
   * @param resultSet 查询结果集
   * @returns 订阅项列表
   */
  private parseResultSet(resultSet: ResultSet): SubscriptionItem[] {
    const subscriptions: SubscriptionItem[] = [];
    
    try {
      while (resultSet.goToNextRow()) {
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
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse result set: ${error}`);
    }
    
    return subscriptions;
  }
}

export const subscriptionDao = new SubscriptionDao();