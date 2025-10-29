import relationalStore from '@kit.RelationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { KEEP_TABLE } from '../TableSchema';
import Logger from '../../../common/util/Logger';

const TAG = 'KeepDao';

export interface Keep {
  id: string;
  contentId: string;
  contentName: string;
  type: string;
  cover: string;
  sourceKey: string;
  createdAt: number;
}

export class KeepDao {
  private db: relationalStore.RdbStore;
  
  constructor() {
    this.db = DatabaseManager.getInstance().getDatabase();
  }
  
  // 添加收藏
  public async add(keep: Keep): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [KEEP_TABLE.COLUMNS.ID]: keep.id,
        [KEEP_TABLE.COLUMNS.CONTENT_ID]: keep.contentId,
        [KEEP_TABLE.COLUMNS.CONTENT_NAME]: keep.contentName,
        [KEEP_TABLE.COLUMNS.TYPE]: keep.type,
        [KEEP_TABLE.COLUMNS.COVER]: keep.cover || null,
        [KEEP_TABLE.COLUMNS.SOURCE_KEY]: keep.sourceKey,
        [KEEP_TABLE.COLUMNS.CREATED_AT]: keep.createdAt
      };
      
      await this.db.insert(KEEP_TABLE.TABLE_NAME, valuesBucket);
      Logger.info(TAG, `Added to keep: ${keep.contentName}`);
    } catch (error) {
      Logger.error(TAG, `Failed to add to keep: ${error}`);
      throw error;
    }
  }
  
  // 移除收藏
  public async remove(contentId: string, sourceKey: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(KEEP_TABLE.TABLE_NAME);
      predicates.equalTo(KEEP_TABLE.COLUMNS.CONTENT_ID, contentId);
      predicates.equalTo(KEEP_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
      
      await this.db.delete(predicates);
      Logger.info(TAG, `Removed from keep: ${contentId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to remove from keep: ${error}`);
      throw error;
    }
  }
  
  // 检查是否已收藏
  public async isKept(contentId: string, sourceKey: string): Promise<boolean> {
    try {
      const predicates = new relationalStore.RdbPredicates(KEEP_TABLE.TABLE_NAME);
      predicates.equalTo(KEEP_TABLE.COLUMNS.CONTENT_ID, contentId);
      predicates.equalTo(KEEP_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
      
      const resultSet = await this.db.query(predicates);
      const hasRow = resultSet.rowCount > 0;
      resultSet.close();
      return hasRow;
    } catch (error) {
      Logger.error(TAG, `Failed to check keep status: ${error}`);
      throw error;
    }
  }
  
  // 获取所有收藏
  public async getAll(): Promise<Keep[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(KEEP_TABLE.TABLE_NAME);
      predicates.orderByDesc(KEEP_TABLE.COLUMNS.CREATED_AT);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get all keeps: ${error}`);
      throw error;
    }
  }
  
  // 获取指定类型的收藏
  public async getByType(type: string): Promise<Keep[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(KEEP_TABLE.TABLE_NAME);
      predicates.equalTo(KEEP_TABLE.COLUMNS.TYPE, type);
      predicates.orderByDesc(KEEP_TABLE.COLUMNS.CREATED_AT);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get keeps by type: ${error}`);
      throw error;
    }
  }
  
  // 清空所有收藏
  public async clearAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(KEEP_TABLE.TABLE_NAME);
      await this.db.delete(predicates);
      Logger.info(TAG, 'Cleared all keeps');
    } catch (error) {
      Logger.error(TAG, `Failed to clear all keeps: ${error}`);
      throw error;
    }
  }
  
  // 解析结果集
  private parseResultSet(resultSet: relationalStore.ResultSet): Keep[] {
    const keeps: Keep[] = [];
    
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      do {
        keeps.push({
          id: resultSet.getString(resultSet.getColumnIndex(KEEP_TABLE.COLUMNS.ID)),
          contentId: resultSet.getString(resultSet.getColumnIndex(KEEP_TABLE.COLUMNS.CONTENT_ID)),
          contentName: resultSet.getString(resultSet.getColumnIndex(KEEP_TABLE.COLUMNS.CONTENT_NAME)),
          type: resultSet.getString(resultSet.getColumnIndex(KEEP_TABLE.COLUMNS.TYPE)),
          cover: resultSet.getString(resultSet.getColumnIndex(KEEP_TABLE.COLUMNS.COVER)),
          sourceKey: resultSet.getString(resultSet.getColumnIndex(KEEP_TABLE.COLUMNS.SOURCE_KEY)),
          createdAt: resultSet.getLong(resultSet.getColumnIndex(KEEP_TABLE.COLUMNS.CREATED_AT))
        });
      } while (resultSet.goToNextRow());
    }
    
    resultSet.close();
    return keeps;
  }
}