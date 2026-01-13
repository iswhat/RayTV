// HistoryDao.ets - 历史记录数据访问对象 | History data access object
import Logger from '../../../common/util/Logger';
import { History } from '../../bean/History';
import { DatabaseManager } from '../DatabaseManager';
import { TableSchema } from '../TableSchema';
import { ValuesBucket, RdbPredicates as RelationalPredicates, ResultSet } from '@ohos.data.relationalStore';

/**
 * 历史记录数据访问对象 | History data access object
 * 实现历史记录相关的数据库操作 | Implements history-related database operations
 */
export class HistoryDao {
  private readonly TAG: string = 'HistoryDao';
  private databaseManager: DatabaseManager;

  constructor() {
    this.databaseManager = DatabaseManager.getInstance();
  }

  /**
   * 保存或更新历史记录 | Save or update history
   * @param history 历史记录信息 | History information
   */
  public async saveOrUpdate(history: History): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.historyToValuesBucket(history);
      
      // 检查是否已存在 | Check if already exists
      const existingHistory = await this.getByContentId(history.contentId);
      
      if (existingHistory) {
        // 更新已有记录 | Update existing record
        const predicates = new RelationalPredicates(TableSchema.HISTORY_TABLE);
        predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, history.contentId);
        const rowsAffected = await db.update(valuesBucket, predicates);
        Logger.info(this.TAG, `History updated: ${history.title}, rows affected: ${rowsAffected}`);
      } else {
        // 保存新记录 | Save new record
        await db.insert(TableSchema.HISTORY_TABLE, valuesBucket);
        Logger.info(this.TAG, `History saved: ${history.title}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to save or update history: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 根据内容ID获取历史记录 | Get history by content ID
   * @param contentId 内容ID | Content ID
   */
  public async getByContentId(contentId: string): Promise<History | null> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.HISTORY_TABLE);
      predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, contentId);
      
      const resultSet = await db.query(predicates);
      const histories = this.parseResultSet(resultSet);
      
      return histories.length > 0 ? histories[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history by contentId: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }

  /**
   * 获取所有历史记录 | Get all histories
   * @param limit 限制数量 | Limit count
   * @param offset 偏移量 | Offset
   */
  public async getAll(limit: number = 50, offset: number = 0): Promise<History[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.HISTORY_TABLE);
      predicates.orderByDesc(TableSchema.HISTORY_LAST_WATCH_TIME);
      predicates.limit(limit, offset);
      
      const resultSet = await db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all histories: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 删除历史记录 | Delete history
   * @param contentId 内容ID | Content ID
   */
  public async deleteByContentId(contentId: string): Promise<boolean> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.HISTORY_TABLE);
      predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, contentId);
      
      const rowsAffected = await db.delete(predicates);
      Logger.info(this.TAG, `History deleted: ${contentId}, rows affected: ${rowsAffected}`);
      return rowsAffected > 0;
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete history: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 清空所有历史记录 | Clear all histories
   */
  public async clearAll(): Promise<boolean> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.HISTORY_TABLE);
      
      const rowsAffected = await db.delete(predicates);
      Logger.info(this.TAG, `All histories cleared, rows affected: ${rowsAffected}`);
      return rowsAffected > 0;
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all histories: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 获取历史记录数量 | Get history count
   */
  public async getCount(): Promise<number> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.HISTORY_TABLE);
      
      const resultSet = await db.query(predicates);
      const count = resultSet.rowCount;
      resultSet.close();
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history count: ${error instanceof Error ? error.message : String(error)}`);
      return 0;
    }
  }

  /**
   * 根据时间范围删除历史记录 | Delete histories before time
   * @param beforeTime 时间点 | Time point
   */
  public async deleteBeforeTime(beforeTime: number): Promise<boolean> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.HISTORY_TABLE);
      predicates.lessThan(TableSchema.HISTORY_LAST_WATCH_TIME, beforeTime);
      
      const rowsAffected = await db.delete(predicates);
      Logger.info(this.TAG, `Histories deleted before ${beforeTime}, rows affected: ${rowsAffected}`);
      return rowsAffected > 0;
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete histories before time: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 批量删除历史记录 | Batch delete histories
   * @param contentIds 内容ID列表 | Content ID list
   */
  public async deleteBatch(contentIds: string[]): Promise<boolean> {
    try {
      const db = await this.databaseManager.getDatabase();
      
      for (const contentId of contentIds) {
        const predicates = new RelationalPredicates(TableSchema.HISTORY_TABLE);
        predicates.equalTo(TableSchema.HISTORY_CONTENT_ID, contentId);
        await db.delete(predicates);
      }
      
      Logger.info(this.TAG, `Batch deleted ${contentIds.length} histories`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch delete histories: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 将History对象转换为ValuesBucket | Convert History object to ValuesBucket
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
   * 解析结果集为History对象列表 | Parse result set to History object list
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
            episodeName: resultSet.getString(resultSet.getColumnIndex(TableSchema.HISTORY_EPISODE_NAME)),
            otherInfo: {}
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
      Logger.error(this.TAG, `Failed to parse result set: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      resultSet.close();
    }
    
    return histories;
  }
}
