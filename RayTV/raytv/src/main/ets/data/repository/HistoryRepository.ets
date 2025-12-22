// HistoryRepository.ets - 历史记录数据仓库
// 负责历史记录相关数据的存储、读取和管理

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { History, HistoryGroup, HistoryType, ContentType } from '../bean/History';
import { HISTORY_TABLE } from '../db/TableSchema';
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';

const TAG = 'HistoryRepository';
const HISTORY_CACHE_PREFIX = 'history_item_';
const HISTORY_LIST_CACHE = 'history_list_cache';
const MAX_HISTORY_ITEMS = 1000; // 最大历史记录数

export class HistoryRepository {
  private static instance: HistoryRepository;
  private sqliteHelper: SQLiteHelper;
  private storageUtil: StorageUtil;
  
  private constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 获取历史记录仓库单例实例
   */
  public static getInstance(): HistoryRepository {
    if (!HistoryRepository.instance) {
      HistoryRepository.instance = new HistoryRepository();
    }
    return HistoryRepository.instance;
  }
  
  /**
   * 保存或更新历史记录
   * @param history 历史记录信息
   * @returns 是否保存成功
   */
  public async saveHistory(history: History): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving history for: ${history.title}`);
      
      // 检查是否已存在相同内容的历史记录
      const existingHistory = await this.findExistingHistory(history);
      
      const historyData = {
        [HISTORY_TABLE.COLUMNS.ID]: existingHistory?.id || null,
        [HISTORY_TABLE.COLUMNS.TITLE]: history.title,
        [HISTORY_TABLE.COLUMNS.SUBTITLE]: history.subtitle || '',
        [HISTORY_TABLE.COLUMNS.COVER_URL]: history.coverUrl || '',
        [HISTORY_TABLE.COLUMNS.CONTENT_TYPE]: history.contentType,
        [HISTORY_TABLE.COLUMNS.HISTORY_TYPE]: history.historyType,
        [HISTORY_TABLE.COLUMNS.SITE_ID]: history.siteId || '',
        [HISTORY_TABLE.COLUMNS.CONTENT_ID]: history.contentId,
        [HISTORY_TABLE.COLUMNS.EPISODE_ID]: history.episodeId || '',
        [HISTORY_TABLE.COLUMNS.PLAY_URL]: history.playUrl || '',
        [HISTORY_TABLE.COLUMNS.PLAY_POSITION]: history.playPosition || 0,
        [HISTORY_TABLE.COLUMNS.TOTAL_DURATION]: history.totalDuration || 0,
        [HISTORY_TABLE.COLUMNS.PROGRESS]: history.progress || 0,
        [HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME]: Date.now(),
        [HISTORY_TABLE.COLUMNS.CREATE_TIME]: existingHistory?.createTime || Date.now(),
        [HISTORY_TABLE.COLUMNS.EXTRA_DATA]: JSON.stringify(history.extraData || {})
      };
      
      let result;
      if (existingHistory?.id) {
        // 更新现有历史记录
        const conditions: QueryCondition[] = [{
          column: HISTORY_TABLE.COLUMNS.ID,
          value: existingHistory.id
        }];
        result = await this.sqliteHelper.update(HISTORY_TABLE.TABLE_NAME, historyData, conditions);
        if (result.success) {
          history.id = existingHistory.id.toString();
        }
      } else {
        // 插入新历史记录
        result = await this.sqliteHelper.insert(HISTORY_TABLE.TABLE_NAME, historyData);
        if (result.success && result.lastInsertRowId) {
          history.id = result.lastInsertRowId.toString();
        }
      }
      
      if (result.success) {
        // 更新缓存
        await this.cacheHistoryItem(history);
        await this.invalidateHistoryListCache();
        
        // 检查是否需要清理旧记录
        await this.cleanupOldHistory();
        
        Logger.info(TAG, `History saved successfully: ${history.title}`);
      }
      
      return result.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to save history: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 查找是否存在相同内容的历史记录
   */
  private async findExistingHistory(history: History): Promise<Record<string, Serializable> | null> {
    const conditions: QueryCondition[] = [{
      column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE, 
      value: history.contentType
    }, {
      column: HISTORY_TABLE.COLUMNS.CONTENT_ID,
      value: history.contentId
    }];
    
    // 对于剧集内容，还需要匹配集数ID
    if (history.episodeId && history.contentType === ContentType.EPISODE) {
      conditions.push({
        column: HISTORY_TABLE.COLUMNS.EPISODE_ID,
        value: history.episodeId
      });
    }
    
    return await this.sqliteHelper.getFirst(HISTORY_TABLE.TABLE_NAME, ['*'], conditions);
  }
  
  /**
   * 获取历史记录列表
   * @param limit 限制数量
   * @param offset 偏移量
   * @returns 历史记录列表
   */
  public async getHistoryList(limit: number, offset: number = 0): Promise<History[]> {
    try {
      // 构建排序选项 - 按最后播放时间降序
      const sortOptions = [{
        column: HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME,
        order: 'DESC'
      }];
      
      // 查询数据库
      const historyRecords = await this.sqliteHelper.query(
        HISTORY_TABLE.TABLE_NAME,
        ['*'],
        undefined,
        sortOptions,
        limit,
        offset
      );
      
      // 转换为History对象
      const histories = this.convertToHistoryObjects(historyRecords);
      
      Logger.info(TAG, `Retrieved ${histories.length} history items`);
      return histories;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get history list: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 按内容类型获取历史记录
   * @param contentType 内容类型
   * @param limit 限制数量
   * @returns 历史记录列表
   */
  public async getHistoryByContentType(contentType: ContentType, limit: number): Promise<History[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE,
        value: contentType
      }];
      
      const sortOptions = [{
        column: HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME,
        order: 'DESC'
      }];
      
      const historyRecords = await this.sqliteHelper.query(
        HISTORY_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions,
        limit
      );
      
      const histories = this.convertToHistoryObjects(historyRecords);
      Logger.info(TAG, `Retrieved ${histories.length} history items for type ${contentType}`);
      return histories;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get history by content type: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 按站点获取历史记录
   * @param siteId 站点ID
   * @param limit 限制数量
   * @returns 历史记录列表
   */
  public async getHistoryBySite(siteId: string, limit: number): Promise<History[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }];
      
      const sortOptions = [{
        column: HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME,
        order: 'DESC'
      }];
      
      const historyRecords = await this.sqliteHelper.query(
        HISTORY_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions,
        limit
      );
      
      const histories = this.convertToHistoryObjects(historyRecords);
      Logger.info(TAG, `Retrieved ${histories.length} history items for site ${siteId}`);
      return histories;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get history by site: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 获取单条历史记录
   * @param historyId 历史记录ID
   * @returns 历史记录或null
   */
  public async getHistoryById(historyId: string): Promise<History | null> {
    try {
      // 尝试从缓存获取
      const cachedHistory = await this.getCachedHistoryItem(historyId);
      if (cachedHistory) {
        Logger.debug(TAG, `Returning history ${historyId} from cache`);
        return cachedHistory;
      }
      
      // 查询数据库
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.ID,
        value: historyId
      }];
      
      const historyRecord = await this.sqliteHelper.getFirst(
        HISTORY_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!historyRecord) {
        return null;
      }
      
      // 转换为History对象
      const history = this.convertToHistoryObject(historyRecord);
      
      // 更新缓存
      await this.cacheHistoryItem(history);
      
      return history;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get history by ID: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 根据内容ID获取历史记录
   * @param contentType 内容类型
   * @param contentId 内容ID
   * @param episodeId 集数ID（可选）
   * @returns 历史记录或null
   */
  public async getHistoryByContent(contentType: ContentType, contentId: string, episodeId?: string): Promise<History | null> {
    try {
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE,
        value: contentType
      }, {
        column: HISTORY_TABLE.COLUMNS.CONTENT_ID,
        value: contentId
      }];
      
      if (episodeId && contentType === ContentType.EPISODE) {
        conditions.push({
          column: HISTORY_TABLE.COLUMNS.EPISODE_ID,
          value: episodeId
        });
      }
      
      const historyRecord = await this.sqliteHelper.getFirst(
        HISTORY_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!historyRecord) {
        return null;
      }
      
      return this.convertToHistoryObject(historyRecord);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get history by content: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 删除历史记录
   * @param historyId 历史记录ID
   * @returns 是否删除成功
   */
  public async deleteHistory(historyId: string): Promise<boolean> {
    try {
      Logger.debug(TAG, `Deleting history with ID: ${historyId}`);
      
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.ID,
        value: historyId
      }];
      
      const result = await this.sqliteHelper.delete(HISTORY_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 清除缓存
        await this.removeCachedHistoryItem(historyId);
        await this.invalidateHistoryListCache();
        Logger.info(TAG, `History ${historyId} deleted successfully`);
      }
      
      return result.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to delete history: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 批量删除历史记录
   * @param historyIds 历史记录ID列表
   * @returns 删除成功的数量
   */
  public async deleteHistories(historyIds: string[]): Promise<number> {
    if (!historyIds || historyIds.length === 0) {
      return 0;
    }
    
    try {
      Logger.debug(TAG, `Deleting ${historyIds.length} history items`);
      
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.ID,
        operator: 'IN',
        value: historyIds
      }];
      
      const result = await this.sqliteHelper.delete(HISTORY_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 清除缓存
        for (const id of historyIds) {
          await this.removeCachedHistoryItem(id);
        }
        await this.invalidateHistoryListCache();
        Logger.info(TAG, `Deleted ${result.affectedRows} history items`);
      }
      
      return result.affectedRows || 0;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to batch delete histories: ${errorMsg}`);
      return 0;
    }
  }
  
  /**
   * 清空所有历史记录
   * @returns 是否清空成功
   */
  public async clearAllHistory(): Promise<boolean> {
    try {
      Logger.warning(TAG, 'Clearing all history records');
      
      const result = await this.sqliteHelper.delete(HISTORY_TABLE.TABLE_NAME);
      
      if (result.success) {
        // 清除所有缓存
        await this.clearHistoryCache();
        Logger.info(TAG, `All history cleared, deleted ${result.affectedRows} records`);
      }
      
      return result.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to clear all history: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 清空指定类型的历史记录
   * @param contentType 内容类型
   * @returns 删除成功的数量
   */
  public async clearHistoryByType(contentType: ContentType): Promise<number> {
    try {
      Logger.debug(TAG, `Clearing history for type: ${contentType}`);
      
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE,
        value: contentType
      }];
      
      const result = await this.sqliteHelper.delete(HISTORY_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        await this.invalidateHistoryListCache();
        Logger.info(TAG, `Cleared ${result.affectedRows} history items for type ${contentType}`);
      }
      
      return result.affectedRows || 0;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to clear history by type: ${errorMsg}`);
      return 0;
    }
  }
  
  /**
   * 获取历史记录总数
   * @returns 历史记录总数
   */
  public async getHistoryCount(): Promise<number> {
    try {
      return await this.sqliteHelper.count(HISTORY_TABLE.TABLE_NAME);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get history count: ${errorMsg}`);
      return 0;
    }
  }
  
  /**
   * 按内容类型获取历史记录总数
   * @param contentType 内容类型
   * @returns 历史记录总数
   */
  public async getHistoryCountByType(contentType: ContentType): Promise<number> {
    try {
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE,
        value: contentType
      }];
      
      return await this.sqliteHelper.count(HISTORY_TABLE.TABLE_NAME, conditions);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get history count by type: ${errorMsg}`);
      return 0;
    }
  }
  
  /**
   * 更新播放进度
   * @param historyId 历史记录ID
   * @param playPosition 播放位置（毫秒）
   * @param totalDuration 总时长（毫秒）
   * @returns 是否更新成功
   */
  public async updatePlayProgress(historyId: string, playPosition: number, totalDuration: number): Promise<boolean> {
    try {
      const progress = totalDuration > 0 ? (playPosition / totalDuration) * 100 : 0;
      
      const data: Record<string, string | number | boolean | null> = {
        [HISTORY_TABLE.COLUMNS.PLAY_POSITION]: playPosition,
        [HISTORY_TABLE.COLUMNS.TOTAL_DURATION]: totalDuration,
        [HISTORY_TABLE.COLUMNS.PROGRESS]: progress,
        [HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME]: Date.now()
      };
      
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.ID,
        value: historyId
      }];
      
      const result = await this.sqliteHelper.update(HISTORY_TABLE.TABLE_NAME, data, conditions);
      
      if (result.success) {
        // 清除缓存
        await this.removeCachedHistoryItem(historyId);
        await this.invalidateHistoryListCache();
        Logger.info(TAG, `Updated play progress for history ${historyId}`);
      }
      
      return result.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to update play progress: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 获取最近观看的历史记录分组
   * @param limit 每个类型的限制数量
   * @returns 分组后的历史记录
   */
  public async getRecentHistoryGroups(limit: number): Promise<HistoryGroup[]> {
    try {
      const groups: HistoryGroup[] = [];
      
      // 按内容类型分组获取
      const contentTypes = [ContentType.MOVIE, ContentType.SERIES, ContentType.LIVE, ContentType.EPISODE];
      
      for (const type of contentTypes) {
        const histories = await this.getHistoryByContentType(type, limit);
        if (histories.length > 0) {
          groups.push({
            type,
            title: this.getContentTypeTitle(type),
            items: histories
          });
        }
      }
      
      Logger.info(TAG, `Retrieved ${groups.length} history groups`);
      return groups;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get recent history groups: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 清理超出限制的旧历史记录
   */
  private async cleanupOldHistory(): Promise<void> {
    try {
      const totalCount = await this.getHistoryCount();
      
      if (totalCount > MAX_HISTORY_ITEMS) {
        const excessCount = totalCount - MAX_HISTORY_ITEMS;
        
        // 获取需要删除的旧记录ID
        const oldestRecords = await this.sqliteHelper.query(
          HISTORY_TABLE.TABLE_NAME, 
          [HISTORY_TABLE.COLUMNS.ID],
          undefined,
          [{
            column: HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME,
            order: 'ASC'
          }],
          excessCount
        );
        
        if (oldestRecords && oldestRecords.length > 0) {
          // 构建删除条件
          const idsToDelete = oldestRecords.map(record => record[HISTORY_TABLE.COLUMNS.ID].toString());
          
          // 删除旧记录
          await this.deleteHistories(idsToDelete);
          Logger.info(TAG, `Cleaned up ${idsToDelete.length} old history records`);
        }
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to cleanup old history: ${errorMsg}`);
    }
  }
  
  /**
   * 缓存历史记录项
   */
  private async cacheHistoryItem(history: History): Promise<void> {
    try {
      await this.storageUtil.setObject(`${HISTORY_CACHE_PREFIX}${history.id}`, history);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Failed to cache history item: ${errorMsg}`);
    }
  }
  
  /**
   * 获取缓存的历史记录项
   */
  private async getCachedHistoryItem(historyId: string): Promise<History | null> {
    try {
      return await this.storageUtil.getObject<History>(`${HISTORY_CACHE_PREFIX}${historyId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Failed to get cached history item: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 移除缓存的历史记录项
   */
  private async removeCachedHistoryItem(historyId: string): Promise<void> {
    try {
      await this.storageUtil.remove(`${HISTORY_CACHE_PREFIX}${historyId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Failed to remove cached history item: ${errorMsg}`);
    }
  }
  
  /**
   * 使历史记录列表缓存失效
   */
  private async invalidateHistoryListCache(): Promise<void> {
    try {
      await this.storageUtil.remove(HISTORY_LIST_CACHE);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Failed to invalidate history list cache: ${errorMsg}`);
    }
  }
  
  /**
   * 清除所有历史记录缓存
   */
  private async clearHistoryCache(): Promise<void> {
    try {
      // 这里简化处理，实际应用中可能需要更复杂的缓存清理逻辑
      await this.storageUtil.remove(HISTORY_LIST_CACHE);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Failed to clear history cache: ${errorMsg}`);
    }
  }
  
  /**
   * 获取内容类型的标题
   */
  private getContentTypeTitle(contentType: ContentType): string {
    const titles: Record<string, string> = {
      [ContentType.MOVIE]: '电影',
      [ContentType.SERIES]: '电视剧',
      [ContentType.LIVE]: '直播',
      [ContentType.EPISODE]: '剧集'
    };
    return titles[contentType] || '其他';
  }
  
  /**
   * 将数据库记录转换为History对象
   */
  private convertToHistoryObject(record: Record<string, Serializable>): History {
    return {
      id: record[HISTORY_TABLE.COLUMNS.ID]?.toString(),
      title: record[HISTORY_TABLE.COLUMNS.TITLE],
      subtitle: record[HISTORY_TABLE.COLUMNS.SUBTITLE],
      coverUrl: record[HISTORY_TABLE.COLUMNS.COVER_URL],
      contentType: record[HISTORY_TABLE.COLUMNS.CONTENT_TYPE],
      historyType: record[HISTORY_TABLE.COLUMNS.HISTORY_TYPE],
      siteId: record[HISTORY_TABLE.COLUMNS.SITE_ID],
      contentId: record[HISTORY_TABLE.COLUMNS.CONTENT_ID],
      episodeId: record[HISTORY_TABLE.COLUMNS.EPISODE_ID],
      playUrl: record[HISTORY_TABLE.COLUMNS.PLAY_URL],
      playPosition: record[HISTORY_TABLE.COLUMNS.PLAY_POSITION],
      totalDuration: record[HISTORY_TABLE.COLUMNS.TOTAL_DURATION],
      progress: record[HISTORY_TABLE.COLUMNS.PROGRESS],
      lastPlayTime: record[HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME],
      createTime: record[HISTORY_TABLE.COLUMNS.CREATE_TIME],
      extraData: record[HISTORY_TABLE.COLUMNS.EXTRA_DATA] ? JSON.parse(record[HISTORY_TABLE.COLUMNS.EXTRA_DATA]) : {}
    };
  }
  
  /**
   * 将数据库记录数组转换为History对象数组
   */
  private convertToHistoryObjects(records: Record<string, Serializable>[]): History[] {
    return records.map(record => this.convertToHistoryObject(record));
  }
}