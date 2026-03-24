// HistoryRepository.ets - 鍘嗗彶璁板綍鏁版嵁浠撳簱
// 璐熻矗鍘嗗彶璁板綍鐩稿叧鏁版嵁鐨勫瓨鍌ㄣ€佽鍙栧拰绠＄悊

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { History, HistoryGroup, HistoryType, ContentType } from '../bean/History';
import { HISTORY_TABLE } from '../db/TableSchema';
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import BaseRepository from '../../common/util/BaseRepository';

const TAG = 'HistoryRepository';
const HISTORY_CACHE_PREFIX = 'history_item_';
const HISTORY_LIST_CACHE = 'history_list_cache';
const MAX_HISTORY_ITEMS = 1000; // 鏈€澶у巻鍙茶褰曟暟

export class HistoryRepository extends BaseRepository {
  private static instance: HistoryRepository;
  private sqliteHelper: SQLiteHelper;
  private storageUtil: StorageUtil;

  private constructor() {
    super();
    this.sqliteHelper = SQLiteHelper.getInstance();
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 鑾峰彇鍘嗗彶璁板綍浠撳簱鍗曚緥瀹炰緥
   */
  public static getInstance(): HistoryRepository {
    if (!HistoryRepository.instance) {
      HistoryRepository.instance = new HistoryRepository();
    }
    return HistoryRepository.instance;
  }
  
  /**
   * 淇濆瓨鎴栨洿鏂板巻鍙茶褰?   * @param history 鍘嗗彶璁板綍淇℃伅
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async saveHistory(history: History): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving history for: ${history.title}`);
      
      // 妫€鏌ユ槸鍚﹀凡瀛樺湪鐩稿悓鍐呭鐨勫巻鍙茶褰?      const existingHistory = await this.findExistingHistory(history);
      
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
      
      let result: { success: boolean; lastInsertRowId?: number };
      if (existingHistory?.id) {
        // 鏇存柊鐜版湁鍘嗗彶璁板綍
        const conditions: QueryCondition[] = [{
          column: HISTORY_TABLE.COLUMNS.ID,
          value: existingHistory.id
        }];
        result = await this.sqliteHelper.update(HISTORY_TABLE.TABLE_NAME, historyData, conditions);
        if (result.success) {
          history.id = existingHistory.id.toString();
        }
      } else {
        // 鎻掑叆鏂板巻鍙茶褰?        result = await this.sqliteHelper.insert(HISTORY_TABLE.TABLE_NAME, historyData);
        if (result.success && result.lastInsertRowId) {
          history.id = result.lastInsertRowId.toString();
        }
      }
      
      if (result.success) {
        // 鏇存柊缂撳瓨
        await this.cacheHistoryItem(history);
        await this.invalidateHistoryListCache();
        
        // 妫€鏌ユ槸鍚﹂渶瑕佹竻鐞嗘棫璁板綍
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
   * 鏌ユ壘鏄惁瀛樺湪鐩稿悓鍐呭鐨勫巻鍙茶褰?   */
  private async findExistingHistory(history: History): Promise<Record<string, Serializable> | null> {
    const conditions: QueryCondition[] = [{
      column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE, 
      value: history.contentType
    }, {
      column: HISTORY_TABLE.COLUMNS.CONTENT_ID,
      value: history.contentId
    }];
    
    // 瀵逛簬鍓ч泦鍐呭锛岃繕闇€瑕佸尮閰嶉泦鏁癐D
    if (history.episodeId && history.contentType === ContentType.EPISODE) {
      conditions.push({
        column: HISTORY_TABLE.COLUMNS.EPISODE_ID,
        value: history.episodeId
      });
    }
    
    return await this.sqliteHelper.getFirst(HISTORY_TABLE.TABLE_NAME, ['*'], conditions);
  }
  
  /**
   * 鑾峰彇鍘嗗彶璁板綍鍒楄〃
   * @param limit 闄愬埗鏁伴噺
   * @param offset 鍋忕Щ閲?   * @returns 鍘嗗彶璁板綍鍒楄〃
   */
  public async getHistoryList(limit: number, offset: number = 0): Promise<History[]> {
    try {
      // 鏋勫缓鎺掑簭閫夐」 - 鎸夋渶鍚庢挱鏀炬椂闂撮檷搴?      const sortOptions = [{
        column: HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME,
        order: 'DESC'
      }];
      
      // 鏌ヨ鏁版嵁搴?      const historyRecords = await this.sqliteHelper.query(
        HISTORY_TABLE.TABLE_NAME,
        ['*'],
        undefined,
        sortOptions,
        limit,
        offset
      );
      
      // 杞崲涓篐istory瀵硅薄
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
   * 鎸夊唴瀹圭被鍨嬭幏鍙栧巻鍙茶褰?   * @param contentType 鍐呭绫诲瀷
   * @param limit 闄愬埗鏁伴噺
   * @returns 鍘嗗彶璁板綍鍒楄〃
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
   * 鎸夌珯鐐硅幏鍙栧巻鍙茶褰?   * @param siteId 绔欑偣ID
   * @param limit 闄愬埗鏁伴噺
   * @returns 鍘嗗彶璁板綍鍒楄〃
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
   * 鑾峰彇鍗曟潯鍘嗗彶璁板綍
   * @param historyId 鍘嗗彶璁板綍ID
   * @returns 鍘嗗彶璁板綍鎴杗ull
   */
  public async getHistoryById(historyId: string): Promise<History | null> {
    try {
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedHistory = await this.getCachedHistoryItem(historyId);
      if (cachedHistory) {
        Logger.debug(TAG, `Returning history ${historyId} from cache`);
        return cachedHistory;
      }
      
      // 鏌ヨ鏁版嵁搴?      const conditions: QueryCondition[] = [{
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
      
      // 杞崲涓篐istory瀵硅薄
      const history = this.convertToHistoryObject(historyRecord);
      
      // 鏇存柊缂撳瓨
      await this.cacheHistoryItem(history);
      
      return history;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get history by ID: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 鏍规嵁鍐呭ID鑾峰彇鍘嗗彶璁板綍
   * @param contentType 鍐呭绫诲瀷
   * @param contentId 鍐呭ID
   * @param episodeId 闆嗘暟ID锛堝彲閫夛級
   * @returns 鍘嗗彶璁板綍鎴杗ull
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
   * 鍒犻櫎鍘嗗彶璁板綍
   * @param historyId 鍘嗗彶璁板綍ID
   * @returns 鏄惁鍒犻櫎鎴愬姛
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
        // 娓呴櫎缂撳瓨
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
   * 鎵归噺鍒犻櫎鍘嗗彶璁板綍
   * @param historyIds 鍘嗗彶璁板綍ID鍒楄〃
   * @returns 鍒犻櫎鎴愬姛鐨勬暟閲?   */
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
        // 娓呴櫎缂撳瓨
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
   * 娓呯┖鎵€鏈夊巻鍙茶褰?   * @returns 鏄惁娓呯┖鎴愬姛
   */
  public async clearAllHistory(): Promise<boolean> {
    try {
      Logger.warning(TAG, 'Clearing all history records');
      
      const result = await this.sqliteHelper.delete(HISTORY_TABLE.TABLE_NAME);
      
      if (result.success) {
        // 娓呴櫎鎵€鏈夌紦瀛?        await this.clearHistoryCache();
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
   * 娓呯┖鎸囧畾绫诲瀷鐨勫巻鍙茶褰?   * @param contentType 鍐呭绫诲瀷
   * @returns 鍒犻櫎鎴愬姛鐨勬暟閲?   */
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
   * 鑾峰彇鍘嗗彶璁板綍鎬绘暟
   * @returns 鍘嗗彶璁板綍鎬绘暟
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
   * 鎸夊唴瀹圭被鍨嬭幏鍙栧巻鍙茶褰曟€绘暟
   * @param contentType 鍐呭绫诲瀷
   * @returns 鍘嗗彶璁板綍鎬绘暟
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
   * 鏇存柊鎾斁杩涘害
   * @param historyId 鍘嗗彶璁板綍ID
   * @param playPosition 鎾斁浣嶇疆锛堟绉掞級
   * @param totalDuration 鎬绘椂闀匡紙姣锛?   * @returns 鏄惁鏇存柊鎴愬姛
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
        // 娓呴櫎缂撳瓨
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
   * 鑾峰彇鏈€杩戣鐪嬬殑鍘嗗彶璁板綍鍒嗙粍
   * @param limit 姣忎釜绫诲瀷鐨勯檺鍒舵暟閲?   * @returns 鍒嗙粍鍚庣殑鍘嗗彶璁板綍
   */
  public async getRecentHistoryGroups(limit: number): Promise<HistoryGroup[]> {
    try {
      const groups: HistoryGroup[] = [];
      
      // 鎸夊唴瀹圭被鍨嬪垎缁勮幏鍙?      const contentTypes = [ContentType.MOVIE, ContentType.SERIES, ContentType.LIVE, ContentType.EPISODE];
      
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
   * 娓呯悊瓒呭嚭闄愬埗鐨勬棫鍘嗗彶璁板綍
   */
  private async cleanupOldHistory(): Promise<void> {
    try {
      const totalCount = await this.getHistoryCount();
      
      if (totalCount > MAX_HISTORY_ITEMS) {
        const excessCount = totalCount - MAX_HISTORY_ITEMS;
        
        // 鑾峰彇闇€瑕佸垹闄ょ殑鏃ц褰旾D
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
          // 鏋勫缓鍒犻櫎鏉′欢
          const idsToDelete = oldestRecords.map(record => record[HISTORY_TABLE.COLUMNS.ID].toString());
          
          // 鍒犻櫎鏃ц褰?          await this.deleteHistories(idsToDelete);
          Logger.info(TAG, `Cleaned up ${idsToDelete.length} old history records`);
        }
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to cleanup old history: ${errorMsg}`);
    }
  }
  
  /**
   * 缂撳瓨鍘嗗彶璁板綍椤?   */
  private async cacheHistoryItem(history: History): Promise<void> {
    try {
      await this.storageUtil.setObject(`${HISTORY_CACHE_PREFIX}${history.id}`, history);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Failed to cache history item: ${errorMsg}`);
    }
  }
  
  /**
   * 鑾峰彇缂撳瓨鐨勫巻鍙茶褰曢」
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
   * 绉婚櫎缂撳瓨鐨勫巻鍙茶褰曢」
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
   * 浣垮巻鍙茶褰曞垪琛ㄧ紦瀛樺け鏁?   */
  private async invalidateHistoryListCache(): Promise<void> {
    try {
      await this.storageUtil.remove(HISTORY_LIST_CACHE);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Failed to invalidate history list cache: ${errorMsg}`);
    }
  }
  
  /**
   * 娓呴櫎鎵€鏈夊巻鍙茶褰曠紦瀛?   */
  private async clearHistoryCache(): Promise<void> {
    try {
      // 杩欓噷绠€鍖栧鐞嗭紝瀹為檯搴旂敤涓彲鑳介渶瑕佹洿澶嶆潅鐨勭紦瀛樻竻鐞嗛€昏緫
      await this.storageUtil.remove(HISTORY_LIST_CACHE);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Failed to clear history cache: ${errorMsg}`);
    }
  }
  
  /**
   * 鑾峰彇鍐呭绫诲瀷鐨勬爣棰?   */
  private getContentTypeTitle(contentType: ContentType): string {
    const titles: Record<string, string> = {
      [ContentType.MOVIE]: '鐢靛奖',
      [ContentType.SERIES]: '鐢佃鍓?,
      [ContentType.LIVE]: '鐩存挱',
      [ContentType.EPISODE]: '鍓ч泦'
    };
    return titles[contentType] || '鍏朵粬';
  }
  
  /**
   * 灏嗘暟鎹簱璁板綍杞崲涓篐istory瀵硅薄
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
   * 灏嗘暟鎹簱璁板綍鏁扮粍杞崲涓篐istory瀵硅薄鏁扮粍
   */
  private convertToHistoryObjects(records: Record<string, Serializable>[]): History[] {
    return records.map(record => this.convertToHistoryObject(record));
  }
}


