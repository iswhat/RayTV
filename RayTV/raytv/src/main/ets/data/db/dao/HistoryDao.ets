import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { HISTORY_TABLE } from '../TableSchema';
import { History } from '../../bean/History';
import Logger from '../../../common/util/Logger';

const TAG = 'HistoryDao';

export class HistoryDao {
  private db: relationalStore.RdbStore;
  
  constructor() {
    this.db = DatabaseManager.getInstance().getDatabase();
  }
  
  // 插入或更新历史记录
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
        await this.db.update(valuesBucket, predicates);
      } else {
        // 插入
        valuesBucket[HISTORY_TABLE.COLUMNS.ID] = history.id;
        await this.db.insert(HISTORY_TABLE.TABLE_NAME, valuesBucket);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save or update history: ${error}`);
      throw error;
    }
  }
  
  // 获取历史记录列表
  public async getAll(limit: number = 50): Promise<History[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.orderByDesc(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT);
      predicates.limit(limit);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get all history: ${error}`);
      throw error;
    }
  }
  
  // 根据内容ID和来源获取历史记录
  public async getByContentId(contentId: string, sourceKey: string): Promise<History | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.CONTENT_ID, contentId);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
      
      const resultSet = await this.db.query(predicates);
      const histories = this.parseResultSet(resultSet);
      return histories.length > 0 ? histories[0] : null;
    } catch (error) {
      Logger.error(TAG, `Failed to get history by contentId: ${error}`);
      throw error;
    }
  }
  
  // 删除历史记录
  public async delete(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, id);
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to delete history: ${error}`);
      throw error;
    }
  }
  
  // 清空所有历史记录
  public async clearAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.TABLE_NAME);
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to clear all history: ${error}`);
      throw error;
    }
  }
  
  // 解析结果集
  private parseResultSet(resultSet: relationalStore.ResultSet): History[] {
    const histories: History[] = [];
    
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
    
    resultSet.close();
    return histories;
  }
}