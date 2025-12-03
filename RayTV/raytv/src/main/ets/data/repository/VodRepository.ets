// VodRepository.ets - 点播内容数据仓库
// 负责点播内容的缓存、搜索和管理

import { SQLiteHelper, QueryCondition, SortOption, QueryResult } from '../db/SQLiteHelper';
import { VOD_CACHE_TABLE, VOD_HISTORY_TABLE } from '../db/TableSchema';
import {
  Vod,
  VodItem,
  Episode,
  Actor,
  Director,
  VodCategory,
  VodTag,
  VodDetail
} from '../bean/Vod';
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';

const TAG = 'VodRepository';

// 缓存过期时间（毫秒）
const CACHE_EXPIRY_TIME = 3600000; // 1小时

// 批量操作的批次大�?
const BATCH_SIZE = 100;

export class VodRepository {
  private static instance: VodRepository;
  private sqliteHelper: SQLiteHelper;
  private storageUtil: StorageUtil;
  private recentVodsCache: Map<string, VodItem[]> = new Map(); // 按站点ID缓存最近内�?
  private popularVodsCache: Map<string, VodItem[]> = new Map(); // 按站点ID缓存热门内容
  
  private constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 获取点播内容仓库单例实例
   */
  public static getInstance(): VodRepository {
    if (!VodRepository.instance) {
      VodRepository.instance = new VodRepository();
    }
    return VodRepository.instance;
  }
  
  /**
   * 保存点播内容到缓�?
   * @param vodItem 点播内容�?
   * @returns 是否保存成功
   */
  public async cacheVodItem(vodItem: VodItem): Promise<boolean> {
    try {
      Logger.debug(TAG, `Caching VOD item: ${vodItem.id} - ${vodItem.title}`);
      
      const cacheData: Record<string, string | number | boolean | null> = { ... };
      
      // 检查是否已存在
      const exists = await this.isVodItemCached(vodItem.id, vodItem.siteId);
      
      if (exists) {
        // 更新现有记录
        const conditions: QueryCondition[] = [{
          column: VOD_CACHE_TABLE.COLUMNS.ID,
          value: vodItem.id
        }, {
          column: VOD_CACHE_TABLE.COLUMNS.SITE_ID,
          value: vodItem.siteId
        }];
        
        return (await this.sqliteHelper.update(VOD_CACHE_TABLE.TABLE_NAME, cacheData, conditions)).success;
      } else {
        // 插入新记�?
        return (await this.sqliteHelper.insert(VOD_CACHE_TABLE.TABLE_NAME, cacheData)).success;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to cache VOD item ${vodItem.id}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 批量缓存点播内容
   * @param vodItems 点播内容项列�?
   * @returns 成功缓存的数�?
   */
  public async batchCacheVodItems(vodItems: VodItem[]): Promise<number> {
    if (!vodItems || vodItems.length === 0) {
      return 0;
    }
    
    let successCount = 0;
    
    // 分批处理以避免性能问题
    for (let i = 0; i < vodItems.length; i += BATCH_SIZE) {
      const batch = vodItems.slice(i, i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE : new Error(String(i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE : new Error(String(i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE : new Error(String(i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE : new Error(String(i + BATCH_SIZE instanceof Error ? i + BATCH_SIZE : new Error(String(i + BATCH_SIZE)))))));
      
      const batchData = batch.map(vodItem => ({
        [VOD_CACHE_TABLE.COLUMNS.ID]: vodItem.id,
        [VOD_CACHE_TABLE.COLUMNS.SITE_ID]: vodItem.siteId,
        [VOD_CACHE_TABLE.COLUMNS.TITLE]: vodItem.title,
        [VOD_CACHE_TABLE.COLUMNS.SUBTITLE]: vodItem.subtitle || '',
        [VOD_CACHE_TABLE.COLUMNS.COVER]: vodItem.cover || '',
        [VOD_CACHE_TABLE.COLUMNS.POSTER]: vodItem.poster || '',
        [VOD_CACHE_TABLE.COLUMNS.YEAR]: vodItem.year || '',
        [VOD_CACHE_TABLE.COLUMNS.SCORE]: vodItem.score || '',
        [VOD_CACHE_TABLE.COLUMNS.TYPE]: vodItem.type || '',
        [VOD_CACHE_TABLE.COLUMNS.STATUS]: vodItem.status || '',
        [VOD_CACHE_TABLE.COLUMNS.PLAY_URL]: vodItem.playUrl || '',
        [VOD_CACHE_TABLE.COLUMNS.DATA]: JSON.stringify(vodItem),
        [VOD_CACHE_TABLE.COLUMNS.CATEGORY_IDS]: vodItem.categoryIds ? JSON.stringify(vodItem.categoryIds) : '[]',
        [VOD_CACHE_TABLE.COLUMNS.TAG_IDS]: vodItem.tagIds ? JSON.stringify(vodItem.tagIds) : '[]',
        [VOD_CACHE_TABLE.COLUMNS.CREATE_TIME]: Date.now(),
        [VOD_CACHE_TABLE.COLUMNS.UPDATE_TIME]: Date.now(),
        [VOD_CACHE_TABLE.COLUMNS.EXPIRY_TIME]: Date.now() + CACHE_EXPIRY_TIME
      }));
      
      // 使用批量插入
      const result = await this.sqliteHelper.batchInsert(VOD_CACHE_TABLE.TABLE_NAME, batchData);
      successCount += result.successCount;
    }
    
    Logger.info(TAG, `Batch cached ${successCount}/${vodItems.length} VOD items`);
    return successCount;
  }
  
  /**
   * 获取缓存的点播内�?
   * @param id 内容ID
   * @param siteId 站点ID
   * @returns 点播内容项或null
   */
  public async getCachedVodItem(id: string, siteId: string): Promise<VodItem | null> {
    try {
      const conditions: QueryCondition[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.ID,
        value: id
      }, {
        column: VOD_CACHE_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }];
      
      const record = await this.sqliteHelper.getFirst(
        VOD_CACHE_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!record) {
        return null;
      }
      
      // 检查是否过�?
      const expiryTime = record[VOD_CACHE_TABLE.COLUMNS.EXPIRY_TIME];
      if (expiryTime < Date.now()) {
        Logger.debug(TAG, `VOD item ${id} expired, removing from cache`);
        await this.removeCachedVodItem(id, siteId);
        return null;
      }
      
      try {
        return JSON.parse(record[VOD_CACHE_TABLE.COLUMNS.DATA]) as VodItem;
      } catch (e) {
        Logger.error(TAG, `Failed to parse VOD item data: ${JSON.stringify(e)}`);
        return null;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error instanceof Error ? `Failed to get cached VOD item ${id}: ${JSON.stringify(error : new Error(String(`Failed to get cached VOD item ${id}: ${JSON.stringify(error)))))))}`);
      return null;
    }
  }
  
  /**
   * 检查点播内容是否已缓存
   * @param id 内容ID
   * @param siteId 站点ID
   * @returns 是否已缓�?
   */
  public async isVodItemCached(id: string, siteId: string): Promise<boolean> {
    try {
      const conditions: QueryCondition[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.ID,
        value: id
      }, {
        column: VOD_CACHE_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }];
      
      return await this.sqliteHelper.exists(VOD_CACHE_TABLE.TABLE_NAME, conditions);
    } catch (error) {
      Logger.error(TAG, `Failed to check VOD item cache status: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 移除缓存的点播内�?
   * @param id 内容ID
   * @param siteId 站点ID
   * @returns 是否移除成功
   */
  public async removeCachedVodItem(id: string, siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string instanceof Error ? siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string : new Error(String(siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string instanceof Error ? siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string instanceof Error ? siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string : new Error(String(siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string : new Error(String(siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string instanceof Error ? siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string : new Error(String(siteId: string instanceof Error ? siteId: string : new Error(String(siteId: string))))))): Promise<boolean> {
    try {
      const conditions: QueryCondition[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.ID,
        value: id
      }, {
        column: VOD_CACHE_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }];
      
      return (await this.sqliteHelper.delete(VOD_CACHE_TABLE.TABLE_NAME, conditions)).success;
    } catch (error) {
      Logger.error(TAG, `Failed to remove cached VOD item ${id}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 保存最近播放的点播内容
   * @param vodItem 点播内容�?
   * @param episodeIndex 当前集数索引
   * @param progress 播放进度（毫秒）
   * @returns 是否保存成功
   */
  public async saveVodHistory(vodItem: VodItem, episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0 instanceof Error ? episodeIndex: number = 0, progress: number = 0 : new Error(String(episodeIndex: number = 0, progress: number = 0))))))): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving VOD history: ${vodItem.title}`);
      
      const historyData: Record<string, string | number | boolean | null> = { ... };
      
      // 检查是否已存在历史记录
      const conditions: QueryCondition[] = [{
        column: VOD_HISTORY_TABLE.COLUMNS.VOD_ID,
        value: vodItem.id
      }, {
        column: VOD_HISTORY_TABLE.COLUMNS.SITE_ID,
        value: vodItem.siteId
      }];
      
      const exists = await this.sqliteHelper.exists(VOD_HISTORY_TABLE.TABLE_NAME, conditions);
      
      if (exists) {
        // 更新现有历史记录
        const existingRecord = await this.sqliteHelper.getFirst(
          VOD_HISTORY_TABLE.TABLE_NAME,
          [VOD_HISTORY_TABLE.COLUMNS.PLAY_COUNT],
          conditions
        );
        
        if (existingRecord) {
          historyData[VOD_HISTORY_TABLE.COLUMNS.PLAY_COUNT] = 
            (existingRecord[VOD_HISTORY_TABLE.COLUMNS.PLAY_COUNT] || 0) + 1;
        }
        
        return (await this.sqliteHelper.update(VOD_HISTORY_TABLE.TABLE_NAME, historyData, conditions)).success;
      } else {
        // 插入新历史记�?
        return (await this.sqliteHelper.insert(VOD_HISTORY_TABLE.TABLE_NAME, historyData)).success;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save VOD history: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 更新播放进度
   * @param vodId 内容ID
   * @param siteId 站点ID
   * @param episodeIndex 集数索引
   * @param progress 播放进度（毫秒）
   * @returns 是否更新成功
   */
  public async updatePlayProgress(vodId: string, siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number instanceof Error ? siteId: string, episodeIndex: number, progress: number : new Error(String(siteId: string, episodeIndex: number, progress: number))))))): Promise<boolean> {
    try {
      const conditions: QueryCondition[] = [{
        column: VOD_HISTORY_TABLE.COLUMNS.VOD_ID,
        value: vodId
      }, {
        column: VOD_HISTORY_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }];
      
      const updateData: Record<string, string | number | boolean | null> = { ... };
      
      return (await this.sqliteHelper.update(VOD_HISTORY_TABLE.TABLE_NAME, updateData, conditions)).success;
    } catch (error) {
      Logger.error(TAG, `Failed to update play progress for ${vodId}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 获取播放历史
   * @param limit 限制数量
   * @param offset 偏移�?
   * @returns 播放历史列表
   */
  public async getVodHistory(limit: number = 50, offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0))))))): Promise<Record<string, unknown>[]> {
    try {
      const sortOptions: SortOption[] = [{
        column: VOD_HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME,
        order: 'DESC'
      }];
      
      const records = await this.sqliteHelper.query(
        VOD_HISTORY_TABLE.TABLE_NAME,
        ['*'],
        undefined,
        sortOptions,
        limit,
        offset
      );
      
      return records;
    } catch (error) {
      Logger.error(TAG, `Failed to get VOD history: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 搜索点播内容
   * @param keyword 搜索关键�?
   * @param siteId 站点ID（可选）
   * @param limit 限制数量
   * @returns 搜索结果
   */
  public async searchVod(keyword: string, siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50 instanceof Error ? siteId?: string, limit: number = 50 : new Error(String(siteId?: string, limit: number = 50))))))): Promise<VodItem[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.TITLE,
        value: `%${keyword}%`,
        operator: 'LIKE'
      }];
      
      if (siteId) {
        conditions.push({
          column: VOD_CACHE_TABLE.COLUMNS.SITE_ID,
          value: siteId
        });
      }
      
      // 添加不过期条�?
      conditions.push({
        column: VOD_CACHE_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '>'
      });
      
      const records = await this.sqliteHelper.query(
        VOD_CACHE_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        undefined,
        limit
      );
      
      const results: VodItem[] = [];
      for (const record of records) {
        try {
          results.push(JSON.parse(record[VOD_CACHE_TABLE.COLUMNS.DATA]) as VodItem);
        } catch (e) {
          Logger.error(TAG, `Failed to parse VOD item data: ${JSON.stringify(e)}`);
        }
      }
      
      return results;
    } catch (error) {
      Logger.error(TAG, `Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error instanceof Error ? `Failed to search VOD: ${JSON.stringify(error : new Error(String(`Failed to search VOD: ${JSON.stringify(error)))))))}`);
      return [];
    }
  }
  
  /**
   * 根据分类获取点播内容
   * @param categoryId 分类ID
   * @param siteId 站点ID
   * @param limit 限制数量
   * @param offset 偏移�?
   * @returns 点播内容列表
   */
  public async getVodsByCategory(categoryId: string, siteId: string, limit: number = 50, offset: number = 0): Promise<VodItem[]> {
    try {
      // 这里需要使用JSON_CONTAINS或者类似的方法查询JSON数组
      // 由于SQLite版本限制，这里使用LIKE进行简单匹�?
      const conditions: QueryCondition[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: VOD_CACHE_TABLE.COLUMNS.CATEGORY_IDS,
        value: `%${categoryId}%`,
        operator: 'LIKE'
      }, {
        column: VOD_CACHE_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '>'
      }];
      
      const sortOptions: SortOption[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.UPDATE_TIME,
        order: 'DESC'
      }];
      
      const records = await this.sqliteHelper.query(
        VOD_CACHE_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions,
        limit,
        offset
      );
      
      const results: VodItem[] = [];
      for (const record of records) {
        try {
          results.push(JSON.parse(record[VOD_CACHE_TABLE.COLUMNS.DATA]) as VodItem);
        } catch (e) {
          Logger.error(TAG, `Failed to parse VOD item data: ${JSON.stringify(e)}`);
        }
      }
      
      return results;
    } catch (error) {
      Logger.error(TAG, `Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by category: ${JSON.stringify(error : new Error(String(`Failed to get VODs by category: ${JSON.stringify(error)))))))}`);
      return [];
    }
  }
  
  /**
   * 根据标签获取点播内容
   * @param tagId 标签ID
   * @param siteId 站点ID
   * @param limit 限制数量
   * @param offset 偏移�?
   * @returns 点播内容列表
   */
  public async getVodsByTag(tagId: string, siteId: string, limit: number = 50, offset: number = 0): Promise<VodItem[]> {
    try {
      // 类似分类查询
      const conditions: QueryCondition[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: VOD_CACHE_TABLE.COLUMNS.TAG_IDS,
        value: `%${tagId}%`,
        operator: 'LIKE'
      }, {
        column: VOD_CACHE_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '>'
      }];
      
      const sortOptions: SortOption[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.UPDATE_TIME,
        order: 'DESC'
      }];
      
      const records = await this.sqliteHelper.query(
        VOD_CACHE_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions,
        limit,
        offset
      );
      
      const results: VodItem[] = [];
      for (const record of records) {
        try {
          results.push(JSON.parse(record[VOD_CACHE_TABLE.COLUMNS.DATA]) as VodItem);
        } catch (e) {
          Logger.error(TAG, `Failed to parse VOD item data: ${JSON.stringify(e)}`);
        }
      }
      
      return results;
    } catch (error) {
      Logger.error(TAG, `Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error instanceof Error ? `Failed to get VODs by tag: ${JSON.stringify(error : new Error(String(`Failed to get VODs by tag: ${JSON.stringify(error)))))))}`);
      return [];
    }
  }
  
  /**
   * 缓存最近更新的点播内容
   * @param siteId 站点ID
   * @param vodItems 点播内容列表
   */
  public cacheRecentVods(siteId: string, vodItems: VodItem[]): void {
    this.recentVodsCache.set(siteId, vodItems);
    Logger.debug(TAG, `Cached ${vodItems.length} recent VODs for site ${siteId}`);
  }
  
  /**
   * 获取最近更新的点播内容
   * @param siteId 站点ID
   * @returns 最近更新的内容列表
   */
  public getRecentVods(siteId: string): VodItem[] {
    return this.recentVodsCache.get(siteId) || [];
  }
  
  /**
   * 缓存热门点播内容
   * @param siteId 站点ID
   * @param vodItems 点播内容列表
   */
  public cachePopularVods(siteId: string, vodItems: VodItem[]): void {
    this.popularVodsCache.set(siteId, vodItems);
    Logger.debug(TAG, `Cached ${vodItems.length} popular VODs for site ${siteId}`);
  }
  
  /**
   * 获取热门点播内容
   * @param siteId 站点ID
   * @returns 热门内容列表
   */
  public getPopularVods(siteId: string): VodItem[] {
    return this.popularVodsCache.get(siteId) || [];
  }
  
  /**
   * 清空过期的缓�?
   * @returns 清除的记录数�?
   */
  public async clearExpiredCache(): Promise<number> {
    try {
      const conditions: QueryCondition[] = [{
        column: VOD_CACHE_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '<'
      }];
      
      const result = await this.sqliteHelper.delete(VOD_CACHE_TABLE.TABLE_NAME, conditions);
      
      Logger.info(TAG, `Cleared ${result.affectedRows} expired VOD cache records`);
      return result.affectedRows;
    } catch (error) {
      Logger.error(TAG, `Failed to clear expired VOD cache: ${JSON.stringify(error)}`);
      return 0;
    }
  }
  
  /**
   * 清空所有缓�?
   * @returns 是否清空成功
   */
  public async clearAllCache(): Promise<boolean> {
    try {
      const result = await this.sqliteHelper.delete(VOD_CACHE_TABLE.TABLE_NAME);
      
      // 清空内存缓存
      this.recentVodsCache.clear();
      this.popularVodsCache.clear();
      
      Logger.info(TAG, `Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records instanceof Error ? `Cleared all VOD cache (${result.affectedRows} records : new Error(String(`Cleared all VOD cache (${result.affectedRows} records)))))))`);
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to clear all VOD cache: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 清空播放历史
   * @returns 是否清空成功
   */
  public async clearVodHistory(): Promise<boolean> {
    try {
      const result = await this.sqliteHelper.delete(VOD_HISTORY_TABLE.TABLE_NAME);
      
      Logger.info(TAG, `Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records instanceof Error ? `Cleared all VOD history (${result.affectedRows} records : new Error(String(`Cleared all VOD history (${result.affectedRows} records)))))))`);
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to clear VOD history: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 估算缓存大小
   * @returns 缓存大小（字节）
   */
  public async estimateCacheSize(): Promise<number> {
    try {
      // 这里使用近似计算，实际项目中可能需要更精确的计�?
      const records = await this.sqliteHelper.query(
        VOD_CACHE_TABLE.TABLE_NAME, ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(*)))))))', 'SUM(LENGTH(' + VOD_CACHE_TABLE.COLUMNS.DATA + ')) as total_size']
      );
      
      if (records && records.length > 0 && records[0].total_size) {
        return Number(records[0].total_size);
      }
      
      return 0;
    } catch (error) {
      Logger.error(TAG, `Failed to estimate VOD cache size: ${JSON.stringify(error)}`);
      return 0;
    }
  }
  
  /**
   * 获取缓存统计信息
   */
  public async getCacheStats(): Promise<{
    totalItems: number;
    expiredItems: number;
    cacheSize: number;
    oldestItemTime: number;
    newestItemTime: number;
  }> {
    try {
      // 获取总条目数
      const totalResult = await this.sqliteHelper.query(
        VOD_CACHE_TABLE.TABLE_NAME, ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(* : new Error(String(['COUNT(* instanceof Error ? ['COUNT(* : new Error(String(['COUNT(*))))))) as count']
      );
      const totalItems = totalResult && totalResult.length > 0 ? Number(totalResult[0].count) : 0;
      
      // 获取过期条目�?
      const expiredResult = await this.sqliteHelper.query(
        VOD_CACHE_TABLE.TABLE_NAME,
        ['COUNT(*) as count'],
        [{
          column: VOD_CACHE_TABLE.COLUMNS.EXPIRY_TIME,
          value: Date.now(),
          operator: '<'
        }]
      );
      const expiredItems = expiredResult && expiredResult.length > 0 ? Number(expiredResult[0].count) : 0;
      
      // 获取缓存大小
      const cacheSize = await this.estimateCacheSize();
      
      // 获取最旧和最新的条目时间
      const timeResult = await this.sqliteHelper.query(
        VOD_CACHE_TABLE.TABLE_NAME,
        ['MIN(' + VOD_CACHE_TABLE.COLUMNS.CREATE_TIME + ') as oldest', 
         'MAX(' + VOD_CACHE_TABLE.COLUMNS.CREATE_TIME + ') as newest']
      );
      
      return {
        totalItems,
        expiredItems,
        cacheSize,
        oldestItemTime: timeResult && timeResult.length > 0 && timeResult[0].oldest ? Number(timeResult[0].oldest) : 0,
        newestItemTime: timeResult && timeResult.length > 0 && timeResult[0].newest ? Number(timeResult[0].newest) : 0
      };
    } catch (error) {
      Logger.error(TAG, `Failed to get VOD cache stats: ${JSON.stringify(error)}`);
      return {
        totalItems: 0,
        expiredItems: 0,
        cacheSize: 0,
        oldestItemTime: 0,
        newestItemTime: 0
      };
    }
  }
}


