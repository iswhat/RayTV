// HistoryDao.ts - 历史记录数据访问对象
// 负责历史记录的增删改查操作

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { HISTORY_TABLE } from '../TableSchema';
import { History } from '../../bean/History';
import Logger from '../../../common/util/Logger';

/**
 * 历史记录数据访问对象
 */
export class HistoryDao {
  private readonly TAG: string = 'HistoryDao';
  private dbManager: DatabaseManager;
  
  /**
   * 构造函数
   */
  constructor() {
    this.dbManager = DatabaseManager.getInstance();
  }
  
  /**
   * 保存或更新历史记录
   * @param history 历史记录信息
   * @returns Promise<void>
   */
  public async saveOrUpdate(history: History): Promise<void> {
    try {
      // 检查是否已存在
      const existing = await this.getByContentId(history.contentId, history.sourceKey);
      
      const valuesBucket: relationalStore.ValuesBucket = {
        [HISTORY_TABLE.COLUMNS.CONTENT_ID]: history.contentId,
        [HISTORY_TABLE.COLUMNS.CONTENT_NAME]: history.contentName,
        [HISTORY_TABLE.COLUMNS.TYPE]: history.type,
        [HISTORY_TABLE.COLUMNS.COVER]: history.cover || null,
        [HISTORY_TABLE.COLUMNS.EPISODE_NAME]: history.episodeName || null,
        [HISTORY_TABLE.COLUMNS.SOURCE_KEY]: history.sourceKey,
        [HISTORY_TABLE.COLUMNS.POSITION]: history.position,
        [HISTORY_TABLE.COLUMNS.DURATION]: history.duration,
        [HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT]: history.lastPlayedAt,
        [HISTORY_TABLE.COLUMNS.CREATED_AT]: history.createdAt
      };
      
      if (existing) {
        // 更新
        valuesBucket[HISTORY_TABLE.COLUMNS.ID] = existing.id;
        const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
        predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, existing.id);
        await this.dbManager.update(valuesBucket, predicates);
        Logger.info(this.TAG, `Updated history: ${history.contentName}`);
      } else {
        // 插入
        valuesBucket[HISTORY_TABLE.COLUMNS.ID] = history.id;
        await this.dbManager.insert(HISTORY_TABLE.TABLE_NAME, valuesBucket);
        Logger.info(this.TAG, `Inserted new history: ${history.contentName}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to save or update history: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }
  
  /**
   * 获取所有历史记录
   * @param limit 限制数量
   * @param offset 偏移量
   * @returns Promise<History[]> 历史记录列表
   */
  public async getAll(limit: number = 50, offset: number = 0): Promise<History[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.orderByDesc(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT);
      predicates.limit(limit, offset);
      
      const resultSet = await this.dbManager.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 根据内容ID和来源获取历史记录
   * @param contentId 内容ID
   * @param sourceKey 来源key
   * @returns Promise<History | null> 历史记录，不存在则返回null
   */
  public async getByContentId(contentId: string, sourceKey: string): Promise<History | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.CONTENT_ID, contentId);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
      
      const resultSet = await this.dbManager.query(predicates);
      const histories = this.parseResultSet(resultSet);
      return histories.length > 0 ? histories[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history by contentId: ${error}`);
      throw error;
    }
  }
  
  /**
   * 根据ID获取历史记录
   * @param id 历史记录ID
   * @returns Promise<History | null> 历史记录，不存在则返回null
   */
  public async getById(id: string): Promise<History | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, id);
      
      const resultSet = await this.dbManager.query(predicates);
      const histories = this.parseResultSet(resultSet);
      return histories.length > 0 ? histories[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history by id: ${error}`);
      throw error;
    }
  }
  
  /**
   * 删除历史记录
   * @param id 历史记录ID
   * @returns Promise<void>
   */
  public async delete(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, id);
      
      const count = await this.dbManager.delete(predicates);
      if (count > 0) {
        Logger.info(this.TAG, `Deleted history: ${id}`);
      } else {
        Logger.warn(this.TAG, `History not found for deletion: ${id}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 批量删除历史记录
   * @param ids 历史记录ID列表
   * @returns Promise<void>
   */
  public async batchDelete(ids: string[]): Promise<void> {
    try {
      if (ids.length === 0) {
        return;
      }
      
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.in(HISTORY_TABLE.COLUMNS.ID, ids);
      
      const count = await this.dbManager.delete(predicates);
      Logger.info(this.TAG, `Batch deleted ${count} history records`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch delete history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 清空所有历史记录
   * @returns Promise<void>
   */
  public async clearAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      const count = await this.dbManager.delete(predicates);
      Logger.info(this.TAG, `Cleared all ${count} history records`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 根据内容ID和来源删除历史记录
   * @param contentId 内容ID
   * @param sourceKey 来源key
   * @returns Promise<void>
   */
  public async deleteByContentId(contentId: string, sourceKey: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.CONTENT_ID, contentId);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
      
      const count = await this.dbManager.delete(predicates);
      Logger.info(this.TAG, `Deleted history for content: ${contentId}, source: ${sourceKey}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete history by contentId: ${error}`);
      throw error;
    }
  }
  
  /**
   * 根据类型获取历史记录
   * @param type 内容类型
   * @param limit 限制数量
   * @returns Promise<History[]> 历史记录列表
   */
  public async getByType(type: string, limit: number = 50): Promise<History[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.TYPE, type);
      predicates.orderByDesc(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT);
      predicates.limit(limit);
      
      const resultSet = await this.dbManager.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history by type: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取历史记录数量
   * @returns Promise<number> 历史记录数量
   */
  public async getCount(): Promise<number> {
    try {
      const sql = `SELECT COUNT(*) FROM ${HISTORY_TABLE.TABLE_NAME}`;
      const resultSet = await this.dbManager.getDatabase().querySql(sql);
      
      let count = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = resultSet.getLong(resultSet.getColumnIndex(0));
      }
      
      resultSet.close();
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get history count: ${error}`);
      return 0;
    }
  }
  
  /**
   * 搜索历史记录
   * @param keyword 搜索关键词
   * @returns Promise<History[]> 匹配的历史记录列表
   */
  public async search(keyword: string): Promise<History[]> {
    try {
      const sql = `
        SELECT * FROM ${HISTORY_TABLE.TABLE_NAME}
        WHERE ${HISTORY_TABLE.COLUMNS.CONTENT_NAME} LIKE ? OR ${HISTORY_TABLE.COLUMNS.EPISODE_NAME} LIKE ?
        ORDER BY ${HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT} DESC
      `;
      
      const bindArgs = [`%${keyword}%`, `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase().querySql(sql, bindArgs);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to search history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 清理旧的历史记录
   * @param keepCount 保留的数量
   * @returns Promise<void>
   */
  public async cleanupOldHistory(keepCount: number = 100): Promise<void> {
    try {
      // 获取总数量
      const totalCount = await this.getCount();
      
      if (totalCount <= keepCount) {
        Logger.info(this.TAG, `No cleanup needed. Current count: ${totalCount}, keep count: ${keepCount}`);
        return;
      }
      
      // 删除超过保留数量的记录
      const sql = `
        DELETE FROM ${HISTORY_TABLE.TABLE_NAME}
        WHERE ${HISTORY_TABLE.COLUMNS.ID} NOT IN (
          SELECT ${HISTORY_TABLE.COLUMNS.ID}
          FROM ${HISTORY_TABLE.TABLE_NAME}
          ORDER BY ${HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT} DESC
          LIMIT ?
        )
      `;
      
      await this.dbManager.executeSql(sql, [keepCount]);
      const deletedCount = totalCount - keepCount;
      Logger.info(this.TAG, `Cleaned up ${deletedCount} old history records`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to cleanup old history: ${error}`);
      throw error;
    }
  }
  
  /**
   * 更新播放位置
   * @param id 历史记录ID
   * @param position 播放位置
   * @param duration 总时长
   * @returns Promise<void>
   */
  public async updatePlayPosition(id: string, position: number, duration: number): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [HISTORY_TABLE.COLUMNS.POSITION]: position,
        [HISTORY_TABLE.COLUMNS.DURATION]: duration,
        [HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT]: Date.now()
      };
      
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, id);
      
      await this.dbManager.update(valuesBucket, predicates);
      Logger.debug(this.TAG, `Updated play position for history: ${id}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update play position: ${error}`);
      throw error;
    }
  }
  
  /**
   * 解析结果集
   * @param resultSet 查询结果集
   * @returns History[] 历史记录列表
   * @private
   */
  private parseResultSet(resultSet: relationalStore.ResultSet): History[] {
    const histories: History[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          histories.push({
            id: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.ID)),
            contentId: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CONTENT_ID)),
            contentName: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CONTENT_NAME)),
            type: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.TYPE)),
            cover: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.COVER)),
            episodeName: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.EPISODE_NAME)),
            sourceKey: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.SOURCE_KEY)),
            position: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.POSITION)),
            duration: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.DURATION)),
            lastPlayedAt: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT)),
            createdAt: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CREATED_AT))
          });
        } while (resultSet.goToNextRow());
      }
    } finally {
      resultSet.close();
    }
    
    return histories;
  }
}