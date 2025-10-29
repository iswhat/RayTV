import Logger from '../../common/util/Logger';
import { History } from '../bean/History';
import { DatabaseManager } from '../db/DatabaseManager';
import { TableSchema } from '../db/TableSchema';

/**
 * 历史记录数据访问对象
 * 负责历史记录相关的数据库操作
 */
export class HistoryDao {
  private readonly TAG: string = 'HistoryDao';
  private databaseManager: DatabaseManager;

  constructor() {
    this.databaseManager = DatabaseManager.getInstance();
  }

  /**
   * 保存或更新历史记录
   * @param history 历史记录信息
   */
  public async saveOrUpdate(history: History): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.historyToValuesBucket(history);
      
      // 检查是否已存在
      const existingHistory = await this.getByContentId(history.contentId);
      
      if (existingHistory) {
        // 更新现有记录
        const predicates = new RelationalPredicates();
        predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, history.contentId);
        const rowsAffected = await db.update(TableSchema.HISTORY_TABLE, valuesBucket, predicates);
        Logger.info(this.TAG, `History updated: ${history.title}, rows affected: ${rowsAffected}`);
      } else {
        // 保存新记录
        await db.insert(TableSchema.HISTORY_TABLE, valuesBucket);
        Logger.info(this.TAG, `History saved: ${history.title}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to save or update history: ${error}`);
      throw error;
    }
  }

  /**
   * 根据内容ID获取历史记录
   * @param contentId 内容ID
   * @returns 历史记录或undefined
   */
  public async getByContentId(contentId: string): Promise<History | undefined> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, contentId);
      const resultSet = await db.query(TableSchema.HISTORY_TABLE, predicates);
      
      const histories = this.parseResultSet(resultSet);
      return histories.length > 0 ? histories[0] : undefined;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history by contentId: ${error}`);
      return undefined;
    }
  }

  /**
   * 获取所有历史记录
   * @param limit 限制数量
   * @param offset 偏移量
   * @returns 历史记录列表
   */
  public async getAll(limit: number = 100, offset: number = 0): Promise<History[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      const orderSpec = new Order(TableSchema.HISTORY_TIMESTAMP, OrderDirection.DESC);
      
      const resultSet = await db.query(
        TableSchema.HISTORY_TABLE,
        predicates,
        [orderSpec],
        limit,
        offset
      );
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all histories: ${error}`);
      return [];
    }
  }

  /**
   * 根据站点获取历史记录
   * @param siteKey 站点标识
   * @param limit 限制数量
   * @returns 历史记录列表
   */
  public async getBySite(siteKey: string, limit: number = 50): Promise<History[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.HISTORY_SITE_KEY, siteKey);
      const orderSpec = new Order(TableSchema.HISTORY_TIMESTAMP, OrderDirection.DESC);
      
      const resultSet = await db.query(
        TableSchema.HISTORY_TABLE,
        predicates,
        [orderSpec],
        limit
      );
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get histories by site: ${error}`);
      return [];
    }
  }

  /**
   * 根据类型获取历史记录
   * @param type 内容类型
   * @param limit 限制数量
   * @returns 历史记录列表
   */
  public async getByType(type: string, limit: number = 50): Promise<History[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.HISTORY_TYPE, type);
      const orderSpec = new Order(TableSchema.HISTORY_TIMESTAMP, OrderDirection.DESC);
      
      const resultSet = await db.query(
        TableSchema.HISTORY_TABLE,
        predicates,
        [orderSpec],
        limit
      );
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get histories by type: ${error}`);
      return [];
    }
  }

  /**
   * 删除历史记录
   * @param contentId 内容ID
   */
  public async delete(contentId: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, contentId);
      
      const rowsAffected = await db.delete(TableSchema.HISTORY_TABLE, predicates);
      Logger.info(this.TAG, `History deleted: ${contentId}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete history: ${error}`);
      throw error;
    }
  }

  /**
   * 根据站点删除历史记录
   * @param siteKey 站点标识
   */
  public async deleteBySite(siteKey: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.HISTORY_SITE_KEY, siteKey);
      
      const rowsAffected = await db.delete(TableSchema.HISTORY_TABLE, predicates);
      Logger.info(this.TAG, `Histories deleted by site: ${siteKey}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete histories by site: ${error}`);
      throw error;
    }
  }

  /**
   * 清空所有历史记录
   */
  public async clearAll(): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const rowsAffected = await db.delete(TableSchema.HISTORY_TABLE);
      Logger.info(this.TAG, `All histories cleared, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all histories: ${error}`);
      throw error;
    }
  }

  /**
   * 删除指定数量的旧历史记录
   * @param keepCount 保留的记录数
   */
  public async deleteOldRecords(keepCount: number = 100): Promise<void> {
    try {
      // 先获取所有记录的ID，然后删除超出保留数量的记录
      const allHistories = await this.getAll(1000);
      
      if (allHistories.length > keepCount) {
        const deleteHistories = allHistories.slice(keepCount);
        
        const db = await this.databaseManager.getDatabase();
        await db.beginTransaction();
        
        try {
          for (const history of deleteHistories) {
            const predicates = new RelationalPredicates();
            predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, history.contentId);
            await db.delete(TableSchema.HISTORY_TABLE, predicates);
          }
          
          await db.commit();
          Logger.info(this.TAG, `Deleted ${deleteHistories.length} old histories`);
        } catch (error) {
          await db.rollback();
          throw error;
        }
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete old records: ${error}`);
      throw error;
    }
  }

  /**
   * 获取历史记录总数
   * @returns 历史记录总数
   */
  public async getCount(): Promise<number> {
    try {
      const db = await this.databaseManager.getDatabase();
      const sql = `SELECT COUNT(*) FROM ${TableSchema.HISTORY_TABLE}`;
      const resultSet = await db.querySql(sql, []);
      
      let count = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = resultSet.getLong(0);
      }
      resultSet.close();
      
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history count: ${error}`);
      return 0;
    }
  }

  /**
   * 根据时间范围删除历史记录
   * @param startTime 开始时间戳
   * @param endTime 结束时间戳
   */
  public async deleteByTimeRange(startTime: number, endTime: number): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.greaterThanOrEqualTo(TableSchema.HISTORY_TIMESTAMP, startTime);
      predicates.lessThanOrEqualTo(TableSchema.HISTORY_TIMESTAMP, endTime);
      
      const rowsAffected = await db.delete(TableSchema.HISTORY_TABLE, predicates);
      Logger.info(this.TAG, `Histories deleted by time range, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete histories by time range: ${error}`);
      throw error;
    }
  }

  /**
   * 批量保存历史记录
   * @param histories 历史记录列表
   */
  public async batchSave(histories: History[]): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      await db.beginTransaction();
      
      try {
        for (const history of histories) {
          await this.saveOrUpdate(history);
        }
        await db.commit();
        Logger.info(this.TAG, `Batch saved ${histories.length} histories`);
      } catch (error) {
        await db.rollback();
        throw error;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch save histories: ${error}`);
      throw error;
    }
  }

  /**
   * 将ResultSet解析为History数组
   * @param resultSet 查询结果集
   * @returns History数组
   */
  private parseResultSet(resultSet: ResultSet): History[] {
    const histories: History[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const history: History = {
            contentId: resultSet.getString(TableSchema.HISTORY_CONTENT_ID),
            title: resultSet.getString(TableSchema.HISTORY_TITLE),
            cover: resultSet.getString(TableSchema.HISTORY_COVER),
            type: resultSet.getString(TableSchema.HISTORY_TYPE),
            siteKey: resultSet.getString(TableSchema.HISTORY_SITE_KEY),
            siteName: resultSet.getString(TableSchema.HISTORY_SITE_NAME),
            url: resultSet.getString(TableSchema.HISTORY_URL),
            currentPosition: resultSet.getLong(TableSchema.HISTORY_CURRENT_POSITION),
            totalDuration: resultSet.getLong(TableSchema.HISTORY_TOTAL_DURATION),
            progress: resultSet.getDouble(TableSchema.HISTORY_PROGRESS),
            timestamp: resultSet.getLong(TableSchema.HISTORY_TIMESTAMP),
            lastEpisode: resultSet.getString(TableSchema.HISTORY_LAST_EPISODE),
            playerType: resultSet.getString(TableSchema.HISTORY_PLAYER_TYPE),
            extraInfo: this.parseJsonString(resultSet.getString(TableSchema.HISTORY_EXTRA_INFO))
          };
          histories.push(history);
        } while (resultSet.goToNextRow());
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse result set: ${error}`);
    } finally {
      resultSet.close();
    }
    
    return histories;
  }

  /**
   * 将History对象转换为ValuesBucket
   * @param history 历史记录信息
   * @returns ValuesBucket
   */
  private historyToValuesBucket(history: History): ValuesBucket {
    const values: ValuesBucket = {
      [TableSchema.HISTORY_CONTENT_ID]: history.contentId,
      [TableSchema.HISTORY_TITLE]: history.title,
      [TableSchema.HISTORY_COVER]: history.cover || '',
      [TableSchema.HISTORY_TYPE]: history.type || 'vod',
      [TableSchema.HISTORY_SITE_KEY]: history.siteKey || '',
      [TableSchema.HISTORY_SITE_NAME]: history.siteName || '',
      [TableSchema.HISTORY_URL]: history.url || '',
      [TableSchema.HISTORY_CURRENT_POSITION]: history.currentPosition || 0,
      [TableSchema.HISTORY_TOTAL_DURATION]: history.totalDuration || 0,
      [TableSchema.HISTORY_PROGRESS]: history.progress || 0,
      [TableSchema.HISTORY_TIMESTAMP]: history.timestamp || Date.now(),
      [TableSchema.HISTORY_LAST_EPISODE]: history.lastEpisode || '',
      [TableSchema.HISTORY_PLAYER_TYPE]: history.playerType || 'default',
      [TableSchema.HISTORY_EXTRA_INFO]: this.stringifyJson(history.extraInfo || {})
    };
    
    return values;
  }

  /**
   * 解析JSON字符串
   * @param jsonString JSON字符串
   * @returns 解析后的对象
   */
  private parseJsonString(jsonString?: string): any {
    if (!jsonString) return {};
    try {
      return JSON.parse(jsonString);
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse JSON string: ${error}`);
      return {};
    }
  }

  /**
   * 将对象转换为JSON字符串
   * @param obj 要转换的对象
   * @returns JSON字符串
   */
  private stringifyJson(obj: any): string {
    try {
      return JSON.stringify(obj);
    } catch (error) {
      Logger.error(this.TAG, `Failed to stringify JSON: ${error}`);
      return '{}';
    }
  }
}

// 导入必要的鸿蒙数据库相关类
import {
  ValuesBucket,
  RelationalPredicates,
  ResultSet,
  Order,
  OrderDirection
} from '@ohos/data.relationalStore';