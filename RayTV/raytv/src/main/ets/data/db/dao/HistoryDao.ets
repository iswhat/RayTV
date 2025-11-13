import Logger from '../../common/util/Logger';
import { History } from '../bean/History';
import { DatabaseManager } from '../db/DatabaseManager';
import { TableSchema } from '../db/TableSchema';
import ValuesBucket from '@ohos.data.relationalStore';
import RelationalPredicates from '@ohos.data.relationalStore';
import ResultSet from '@ohos.data.relationalStore';
import Order from '@ohos.data.relationalStore';
import OrderDirection from '@ohos.data.relationalStore';

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
   */
  public async getByContentId(contentId: string): Promise<History | null> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, contentId);
      
      const resultSet = await db.query(TableSchema.HISTORY_TABLE, predicates);
      const histories = this.parseResultSet(resultSet);
      
      return histories.length > 0 ? histories[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history by contentId: ${error}`);
      return null;
    }
  }

  /**
   * 获取所有历史记录
   * @param limit 限制数量
   * @param offset 偏移量
   */
  public async getAll(limit: number = 50, offset: number = 0): Promise<History[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.orderByDesc(TableSchema.HISTORY_LAST_WATCH_TIME);
      predicates.limit(limit, offset);
      
      const resultSet = await db.query(TableSchema.HISTORY_TABLE, predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all histories: ${error}`);
      return [];
    }
  }

  /**
   * 删除历史记录
   * @param contentId 内容ID
   */
  public async deleteByContentId(contentId: string): Promise<boolean> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, contentId);
      
      const rowsAffected = await db.delete(TableSchema.HISTORY_TABLE, predicates);
      Logger.info(this.TAG, `History deleted: ${contentId}, rows affected: ${rowsAffected}`);
      return rowsAffected > 0;
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete history: ${error}`);
      return false;
    }
  }

  /**
   * 清空所有历史记录
   */
  public async clearAll(): Promise<boolean> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      
      const rowsAffected = await db.delete(TableSchema.HISTORY_TABLE, predicates);
      Logger.info(this.TAG, `All histories cleared, rows affected: ${rowsAffected}`);
      return rowsAffected > 0;
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all histories: ${error}`);
      return false;
    }
  }

  /**
   * 获取历史记录数量
   */
  public async getCount(): Promise<number> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      
      const resultSet = await db.query(TableSchema.HISTORY_TABLE, predicates);
      return resultSet.rowCount;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history count: ${error}`);
      return 0;
    }
  }

  /**
   * 根据时间范围删除历史记录
   * @param beforeTime 时间戳
   */
  public async deleteBeforeTime(beforeTime: number): Promise<boolean> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.lessThan(TableSchema.HISTORY_LAST_WATCH_TIME, beforeTime);
      
      const rowsAffected = await db.delete(TableSchema.HISTORY_TABLE, predicates);
      Logger.info(this.TAG, `Histories deleted before ${beforeTime}, rows affected: ${rowsAffected}`);
      return rowsAffected > 0;
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete histories before time: ${error}`);
      return false;
    }
  }

  /**
   * 批量删除历史记录
   * @param contentIds 内容ID列表
   */
  public async deleteBatch(contentIds: string[]): Promise<boolean> {
    try {
      const db = await this.databaseManager.getDatabase();
      
      for (const contentId of contentIds) {
        const predicates = new RelationalPredicates();
        predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, contentId);
        await db.delete(TableSchema.HISTORY_TABLE, predicates);
      }
      
      Logger.info(this.TAG, `Batch deleted ${contentIds.length} histories`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch delete histories: ${error}`);
      return false;
    }
  }

  /**
   * 将History对象转换为ValuesBucket
   */
  private historyToValuesBucket(history: History): ValuesBucket {
    const bucket: ValuesBucket = {
      [TableSchema.HISTORY_CONTENT_ID]: history.contentId,
      [TableSchema.HISTORY_TITLE]: history.title,
      [TableSchema.HISTORY_COVER]: history.cover || '',
      [TableSchema.HISTORY_CURRENT_POSITION]: history.currentPosition || 0,
      [TableSchema.HISTORY_TOTAL_DURATION]: history.totalDuration || 0,
      [TableSchema.HISTORY_LAST_WATCH_TIME]: history.lastWatchTime || Date.now(),
      [TableSchema.HISTORY_SITE_KEY]: history.siteKey || '',
      [TableSchema.HISTORY_EPISODE_NAME]: history.episodeName || '',
      [TableSchema.HISTORY_OTHER_INFO]: JSON.stringify(history.otherInfo || {})
    };
    
    return bucket;
  }

  /**
   * 解析结果集为History对象列表
   */
  private parseResultSet(resultSet: ResultSet): History[] {
    const histories: History[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        
        do {
          const history: History = {
            contentId: resultSet.getString(resultSet.getColumnIndex(TableSchema.HISTORY_CONTENT_ID)),
            title: resultSet.getString(resultSet.getColumnIndex(TableSchema.HISTORY_TITLE)),
            cover: resultSet.getString(resultSet.getColumnIndex(TableSchema.HISTORY_COVER)),
            currentPosition: resultSet.getLong(resultSet.getColumnIndex(TableSchema.HISTORY_CURRENT_POSITION)),
            totalDuration: resultSet.getLong(resultSet.getColumnIndex(TableSchema.HISTORY_TOTAL_DURATION)),
            lastWatchTime: resultSet.getLong(resultSet.getColumnIndex(TableSchema.HISTORY_LAST_WATCH_TIME)),
            siteKey: resultSet.getString(resultSet.getColumnIndex(TableSchema.HISTORY_SITE_KEY)),
            episodeName: resultSet.getString(resultSet.getColumnIndex(TableSchema.HISTORY_EPISODE_NAME))
          };
          
          const otherInfoStr = resultSet.getString(resultSet.getColumnIndex(TableSchema.HISTORY_OTHER_INFO));
          if (otherInfoStr) {
            try {
              history.otherInfo = JSON.parse(otherInfoStr);
            } catch (e) {
              history.otherInfo = {};
            }
          }
          
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
}