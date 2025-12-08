// LiveRepository.ets - 直播内容数据仓库
// 负责直播内容的缓存、管理和播放历史记录

import { SQLiteHelper, QueryCondition, SortOption } from '../db/SQLiteHelper';
import { LIVE_CHANNEL_TABLE, LIVE_GROUP_TABLE, LIVE_PLAY_HISTORY_TABLE, EPG_TABLE } from '../db/TableSchema';
import {
  LiveChannel,
  LiveGroup,
  EpgItem,
  LiveStream
} from '../bean/Live';
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';

const TAG = 'LiveRepository';

// 缓存过期时间（毫秒）
const CHANNEL_CACHE_EXPIRY = 7200000; // 2小时
const EPG_CACHE_EXPIRY = 3600000; // 1小时

// 批量操作的批次大�?
const BATCH_SIZE = 200;

export class LiveRepository {
  private static instance: LiveRepository;
  private sqliteHelper: SQLiteHelper;
  private storageUtil: StorageUtil;
  
  // 内存缓存
  private channelCache: Map<string, Map<string, LiveChannel>> = new Map(); // siteId -> channelId -> LiveChannel
  private groupCache: Map<string, LiveGroup[]> = new Map(); // siteId -> LiveGroup[]
  private epgCache: Map<string, Map<string, EpgItem[]>> = new Map(); // siteId -> channelId -> EpgItem[]
  
  private constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 获取直播仓库单例实例
   */
  public static getInstance(): LiveRepository {
    if (!LiveRepository.instance) {
      LiveRepository.instance = new LiveRepository();
    }
    return LiveRepository.instance;
  }
  
  /**
   * 初始化直播仓�?
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing live repository');
      
      // 预加载常用数据到内存缓存
      await this.preloadPopularSites();
      
      // 清理过期缓存
      await this.clearExpiredCache();
      
      Logger.info(TAG, 'Live repository initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize live repository: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 预加载常用站点数�?
   */
  private async preloadPopularSites(): Promise<void> {
    try {
      // 这里可以预加载用户常用的几个站点数据
      // 暂时为空实现，后续可以从配置或用户行为分析获取常用站�?
    } catch (error) {
      Logger.error(TAG, `Failed to preload popular sites: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 保存直播分组
   * @param siteId 站点ID
   * @param groups 分组列表
   * @returns 成功保存的数�?
   */
  public async saveLiveGroups(siteId: string, groups: LiveGroup[]): Promise<number> {
    if (!groups || groups.length === 0) {
      return 0;
    }
    
    try {
      Logger.debug(TAG, `Saving ${groups.length} live groups for site ${siteId}`);
      
      // 先删除该站点的所有分�?
      await this.sqliteHelper.delete(LIVE_GROUP_TABLE.TABLE_NAME, [{
        column: LIVE_GROUP_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }]);
      
      // 批量插入新分�?
      const groupData = groups.map(group => ({
        [LIVE_GROUP_TABLE.COLUMNS.ID]: group.id,
        [LIVE_GROUP_TABLE.COLUMNS.SITE_ID]: siteId,
        [LIVE_GROUP_TABLE.COLUMNS.NAME]: group.name,
        [LIVE_GROUP_TABLE.COLUMNS.ORDER_INDEX]: group.orderIndex || 0,
        [LIVE_GROUP_TABLE.COLUMNS.ICON]: group.icon || '',
        [LIVE_GROUP_TABLE.COLUMNS.DATA]: JSON.stringify(group),
        [LIVE_GROUP_TABLE.COLUMNS.UPDATE_TIME]: Date.now()
      }));
      
      const result = await this.sqliteHelper.batchInsert(LIVE_GROUP_TABLE.TABLE_NAME, groupData);
      
      if (result.success) {
        // 更新内存缓存
        this.groupCache.set(siteId, groups);
      }
      
      return result.successCount;
    } catch (error) {
      Logger.error(TAG, `Failed to save live groups for site ${siteId}: ${JSON.stringify(error)}`);
      return 0;
    }
  }
  
  /**
   * 获取站点的所有分�?
   * @param siteId 站点ID
   * @returns 分组列表
   */
  public async getLiveGroups(siteId: string): Promise<LiveGroup[]> {
    try {
      // 优先从内存缓存获�?
      if (this.groupCache.has(siteId)) {
        return this.groupCache.get(siteId)!;
      }
      
      // 从数据库查询
      const conditions: QueryCondition[] = [{
        column: LIVE_GROUP_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }];
      
      const sortOptions: SortOption[] = [{
        column: LIVE_GROUP_TABLE.COLUMNS.ORDER_INDEX,
        order: 'ASC'
      }];
      
      const records = await this.sqliteHelper.query(
        LIVE_GROUP_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      const groups: LiveGroup[] = [];
      for (const record of records) {
        try {
          groups.push(JSON.parse(record[LIVE_GROUP_TABLE.COLUMNS.DATA]) as LiveGroup);
        } catch (e) {
          Logger.error(TAG, `Failed to parse live group data: ${JSON.stringify(e)}`);
        }
      }
      
      // 更新内存缓存
      this.groupCache.set(siteId, groups);
      
      return groups;
    } catch (error) {
      Logger.error(TAG, `Failed to get live groups for site ${siteId}: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 保存直播频道
   * @param siteId 站点ID
   * @param channels 频道列表
   * @returns 成功保存的数�?
   */
  public async saveLiveChannels(siteId: string, channels: LiveChannel[]): Promise<number> {
    if (!channels || channels.length === 0) {
      return 0;
    }
    
    let successCount = 0;
    
    try {
      Logger.debug(TAG, `Saving ${channels.length} live channels for site ${siteId}`);
      
      // 分批处理以避免性能问题
      for (let i = 0; i < channels.length; i += BATCH_SIZE) {
        const batch = channels.slice(i, i + BATCH_SIZE);
        
        const channelData = batch.map(channel => ({
          [LIVE_CHANNEL_TABLE.COLUMNS.ID]: channel.id,
          [LIVE_CHANNEL_TABLE.COLUMNS.SITE_ID]: siteId,
          [LIVE_CHANNEL_TABLE.COLUMNS.GROUP_ID]: channel.groupId || '',
          [LIVE_CHANNEL_TABLE.COLUMNS.NAME]: channel.name,
          [LIVE_CHANNEL_TABLE.COLUMNS.NUMBER]: channel.number || '',
          [LIVE_CHANNEL_TABLE.COLUMNS.LOGO]: channel.logo || '',
          [LIVE_CHANNEL_TABLE.COLUMNS.PLAY_URL]: channel.playUrl || '',
          [LIVE_CHANNEL_TABLE.COLUMNS.STREAMS]: channel.streams ? JSON.stringify(channel.streams) : '[]',
          [LIVE_CHANNEL_TABLE.COLUMNS.TAGS]: channel.tags ? JSON.stringify(channel.tags) : '[]',
          [LIVE_CHANNEL_TABLE.COLUMNS.DATA]: JSON.stringify(channel),
          [LIVE_CHANNEL_TABLE.COLUMNS.ORDER_INDEX]: channel.orderIndex || 0,
          [LIVE_CHANNEL_TABLE.COLUMNS.UPDATE_TIME]: Date.now(),
          [LIVE_CHANNEL_TABLE.COLUMNS.EXPIRY_TIME]: Date.now() + CHANNEL_CACHE_EXPIRY
        }));
        
        const result = await this.sqliteHelper.batchInsert(LIVE_CHANNEL_TABLE.TABLE_NAME, channelData);
        successCount += result.successCount;
      }
      
      // 更新内存缓存
      if (!this.channelCache.has(siteId)) {
        this.channelCache.set(siteId, new Map());
      }
      
      const siteChannelCache = this.channelCache.get(siteId)!;
      channels.forEach(channel => {
        siteChannelCache.set(channel.id, channel);
      });
      
      Logger.info(TAG, `Successfully saved ${successCount}/${channels.length} live channels for site ${siteId}`);
      return successCount;
    } catch (error) {
      Logger.error(TAG, `Failed to save live channels for site ${siteId}: ${JSON.stringify(error)}`);
      return successCount;
    }
  }
  
  /**
   * 获取分组下的所有频�?
   * @param siteId 站点ID
   * @param groupId 分组ID
   * @returns 频道列表
   */
  public async getChannelsByGroup(siteId: string, groupId: string): Promise<LiveChannel[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: LIVE_CHANNEL_TABLE.COLUMNS.GROUP_ID,
        value: groupId
      }, {
        column: LIVE_CHANNEL_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '>'
      }];
      
      const sortOptions: SortOption[] = [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.ORDER_INDEX,
        order: 'ASC'
      }];
      
      const records = await this.sqliteHelper.query(
        LIVE_CHANNEL_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      const channels: LiveChannel[] = [];
      for (const record of records) {
        try {
          channels.push(JSON.parse(record[LIVE_CHANNEL_TABLE.COLUMNS.DATA]) as LiveChannel);
        } catch (e) {
          Logger.error(TAG, `Failed to parse live channel data: ${JSON.stringify(e)}`);
        }
      }
      
      return channels;
    } catch (error) {
      Logger.error(TAG, `Failed to get channels by group ${groupId}: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 获取站点的所有频�?
   * @param siteId 站点ID
   * @returns 频道列表
   */
  public async getAllChannels(siteId: string): Promise<LiveChannel[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: LIVE_CHANNEL_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '>'
      }];
      
      const sortOptions: SortOption[] = [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.GROUP_ID,
        order: 'ASC'
      }, {
        column: LIVE_CHANNEL_TABLE.COLUMNS.ORDER_INDEX,
        order: 'ASC'
      }];
      
      const records = await this.sqliteHelper.query(
        LIVE_CHANNEL_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      const channels: LiveChannel[] = [];
      for (const record of records) {
        try {
          channels.push(JSON.parse(record[LIVE_CHANNEL_TABLE.COLUMNS.DATA]) as LiveChannel);
        } catch (e) {
          Logger.error(TAG, `Failed to parse live channel data: ${JSON.stringify(e)}`);
        }
      }
      
      return channels;
    } catch (error) {
      Logger.error(TAG, `Failed to get all channels for site ${siteId}: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 获取单个频道信息
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @returns 频道信息或null
   */
  public async getChannelById(siteId: string, channelId: string): Promise<LiveChannel | null> {
    try {
      // 优先从内存缓存获�?
      if (this.channelCache.has(siteId)) {
        const siteChannelCache = this.channelCache.get(siteId)!;
        if (siteChannelCache.has(channelId)) {
          return siteChannelCache.get(channelId)!;
        }
      }
      
      // 从数据库查询
      const conditions: QueryCondition[] = [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: LIVE_CHANNEL_TABLE.COLUMNS.ID,
        value: channelId
      }];
      
      const record = await this.sqliteHelper.getFirst(
        LIVE_CHANNEL_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!record) {
        return null;
      }
      
      // 检查是否过�?
      const expiryTime = record[LIVE_CHANNEL_TABLE.COLUMNS.EXPIRY_TIME];
      if (expiryTime < Date.now()) {
        Logger.debug(TAG, `Live channel ${channelId} expired, removing from cache`);
        await this.removeChannel(siteId, channelId);
        return null;
      }
      
      try {
        const channel = JSON.parse(record[LIVE_CHANNEL_TABLE.COLUMNS.DATA]) as LiveChannel;
        
        // 更新内存缓存
        if (!this.channelCache.has(siteId)) {
          this.channelCache.set(siteId, new Map());
        }
        this.channelCache.get(siteId)!.set(channelId, channel);
        
        return channel;
      } catch (e) {
        Logger.error(TAG, `Failed to parse live channel data: ${JSON.stringify(e)}`);
        return null;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get channel by ID ${channelId}: ${JSON.stringify(error)}`);
      return null;
    }
  }
  
  /**
   * 搜索直播频道
   * @param keyword 搜索关键�?
   * @param siteId 站点ID（可选）
   * @returns 搜索结果
   */
  public async searchChannels(keyword: string, siteId?: string): Promise<LiveChannel[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.NAME,
        value: `%${keyword}%`,
        operator: 'LIKE'
      }, {
        column: LIVE_CHANNEL_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '>'
      }];
      
      if (siteId) {
        conditions.push({
          column: LIVE_CHANNEL_TABLE.COLUMNS.SITE_ID,
          value: siteId
        });
      }
      
      const records = await this.sqliteHelper.query(
        LIVE_CHANNEL_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      const channels: LiveChannel[] = [];
      for (const record of records) {
        try {
          channels.push(JSON.parse(record[LIVE_CHANNEL_TABLE.COLUMNS.DATA]) as LiveChannel);
        } catch (e) {
          Logger.error(TAG, `Failed to parse live channel data: ${JSON.stringify(e)}`);
        }
      }
      
      return channels;
    } catch (error) {
      Logger.error(TAG, `Failed to search channels: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 保存EPG数据
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @param epgItems EPG节目列表
   * @returns 是否保存成功
   */
  public async saveEpgData(siteId: string, channelId: string, epgItems: EpgItem[]): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving ${epgItems.length} EPG items for channel ${channelId}`);
      
      // 先删除该频道的所有EPG数据
      await this.sqliteHelper.delete(EPG_TABLE.TABLE_NAME, [{
        column: EPG_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: EPG_TABLE.COLUMNS.CHANNEL_ID,
        value: channelId
      }]);
      
      if (epgItems.length === 0) {
        return true;
      }
      
      // 批量插入EPG数据
      const epgData = epgItems.map(item => ({
        [EPG_TABLE.COLUMNS.ID]: `${siteId}_${channelId}_${item.startTime}`,
        [EPG_TABLE.COLUMNS.SITE_ID]: siteId,
        [EPG_TABLE.COLUMNS.CHANNEL_ID]: channelId,
        [EPG_TABLE.COLUMNS.TITLE]: item.title,
        [EPG_TABLE.COLUMNS.DESCRIPTION]: item.description || '',
        [EPG_TABLE.COLUMNS.START_TIME]: item.startTime,
        [EPG_TABLE.COLUMNS.END_TIME]: item.endTime,
        [EPG_TABLE.COLUMNS.POSTER]: item.poster || '',
        [EPG_TABLE.COLUMNS.CATEGORY]: item.category || '',
        [EPG_TABLE.COLUMNS.DATA]: JSON.stringify(item),
        [EPG_TABLE.COLUMNS.EXPIRY_TIME]: Date.now() + EPG_CACHE_EXPIRY
      }));
      
      const result = await this.sqliteHelper.batchInsert(EPG_TABLE.TABLE_NAME, epgData);
      
      if (result.success) {
        // 更新内存缓存
        if (!this.epgCache.has(siteId)) {
          this.epgCache.set(siteId, new Map());
        }
        this.epgCache.get(siteId)!.set(channelId, epgItems);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to save EPG data for channel ${channelId}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 获取频道的EPG数据
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @param startTime 开始时�?
   * @param endTime 结束时间
   * @returns EPG节目列表
   */
  public async getEpgData(siteId: string, channelId: string, startTime?: number, endTime?: number): Promise<EpgItem[]> {
    try {
      // 优先从内存缓存获�?
      if (this.epgCache.has(siteId) && this.epgCache.get(siteId)!.has(channelId)) {
        const cachedEpg = this.epgCache.get(siteId)!.get(channelId)!;
        
        // 如果指定了时间范围，进行过滤
        if (startTime !== undefined && endTime !== undefined) {
          return cachedEpg.filter(item => 
            item.startTime < endTime && item.endTime > startTime
          );
        }
        
        return cachedEpg;
      }
      
      // 从数据库查询
      const conditions: QueryCondition[] = [{
        column: EPG_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: EPG_TABLE.COLUMNS.CHANNEL_ID,
        value: channelId
      }, {
        column: EPG_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '>'
      }];
      
      // 添加时间范围过滤
      if (startTime !== undefined && endTime !== undefined) {
        conditions.push({
          column: EPG_TABLE.COLUMNS.START_TIME,
          value: endTime,
          operator: '<'
        });
        conditions.push({
          column: EPG_TABLE.COLUMNS.END_TIME,
          value: startTime,
          operator: '>'
        });
      }
      
      const sortOptions: SortOption[] = [{
        column: EPG_TABLE.COLUMNS.START_TIME,
        order: 'ASC'
      }];
      
      const records = await this.sqliteHelper.query(
        EPG_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      const epgItems: EpgItem[] = [];
      for (const record of records) {
        try {
          epgItems.push(JSON.parse(record[EPG_TABLE.COLUMNS.DATA]) as EpgItem);
        } catch (e) {
          Logger.error(TAG, `Failed to parse EPG item data: ${JSON.stringify(e)}`);
        }
      }
      
      // 更新内存缓存（只缓存完整列表，不缓存过滤后的�?
      if (startTime === undefined && endTime === undefined) {
        if (!this.epgCache.has(siteId)) {
          this.epgCache.set(siteId, new Map());
        }
        this.epgCache.get(siteId)!.set(channelId, epgItems);
      }
      
      return epgItems;
    } catch (error) {
      Logger.error(TAG, `Failed to get EPG data for channel ${channelId}: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 获取当前正在播放的EPG节目
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @returns 当前EPG节目或null
   */
  public async getCurrentEpgItem(siteId: string, channelId: string): Promise<EpgItem | null> {
    try {
      const now = Date.now();
      const epgItems = await this.getEpgData(siteId, channelId, now - 3600000, now + 3600000);
      
      // 查找当前时间在播放的节目
      return epgItems.find(item => 
        item.startTime <= now && item.endTime > now
      ) || null;
    } catch (error) {
      Logger.error(TAG, `Failed to get current EPG item for channel ${channelId}: ${JSON.stringify(error)}`);
      return null;
    }
  }
  
  /**
   * 保存播放历史
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @param channelName 频道名称
   * @param logo 频道Logo
   * @returns 是否保存成功
   */
  public async savePlayHistory(siteId: string, channelId: string, channelName: string, logo: string): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving play history for channel ${channelName}`);
      
      const historyData = {
        [LIVE_PLAY_HISTORY_TABLE.COLUMNS.SITE_ID]: siteId,
        [LIVE_PLAY_HISTORY_TABLE.COLUMNS.CHANNEL_ID]: channelId,
        [LIVE_PLAY_HISTORY_TABLE.COLUMNS.CHANNEL_NAME]: channelName,
        [LIVE_PLAY_HISTORY_TABLE.COLUMNS.LOGO]: logo,
        [LIVE_PLAY_HISTORY_TABLE.COLUMNS.PLAY_COUNT]: 1,
        [LIVE_PLAY_HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME]: Date.now()
      };
      
      // 检查是否已存在历史记录
      const conditions: QueryCondition[] = [{
        column: LIVE_PLAY_HISTORY_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: LIVE_PLAY_HISTORY_TABLE.COLUMNS.CHANNEL_ID,
        value: channelId
      }];
      
      const exists = await this.sqliteHelper.exists(LIVE_PLAY_HISTORY_TABLE.TABLE_NAME, conditions);
      
      if (exists) {
        // 更新现有历史记录
        const existingRecord = await this.sqliteHelper.getFirst(
          LIVE_PLAY_HISTORY_TABLE.TABLE_NAME,
          [LIVE_PLAY_HISTORY_TABLE.COLUMNS.PLAY_COUNT],
          conditions
        );
        
        if (existingRecord) {
          historyData[LIVE_PLAY_HISTORY_TABLE.COLUMNS.PLAY_COUNT] = 
            (existingRecord[LIVE_PLAY_HISTORY_TABLE.COLUMNS.PLAY_COUNT] || 0) + 1;
        }
        
        return (await this.sqliteHelper.update(LIVE_PLAY_HISTORY_TABLE.TABLE_NAME, historyData, conditions)).success;
      } else {
        // 插入新历史记�?
        return (await this.sqliteHelper.insert(LIVE_PLAY_HISTORY_TABLE.TABLE_NAME, historyData)).success;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save play history`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 获取播放历史
   * @param limit 限制数量
   * @returns 播放历史列表
   */
  public async getPlayHistory(limit: number = 50): Promise<Record<string, unknown>[]> {
    try {
      const sortOptions: SortOption[] = [{
        column: LIVE_PLAY_HISTORY_TABLE.COLUMNS.LAST_PLAY_TIME,
        order: 'DESC'
      }];
      
      const records = await this.sqliteHelper.query(
        LIVE_PLAY_HISTORY_TABLE.TABLE_NAME,
        ['*'],
        undefined,
        sortOptions,
        limit
      );
      
      return records;
    } catch (error) {
      Logger.error(TAG, `Failed to get play history`, error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 移除频道
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @returns 是否移除成功
   */
  public async removeChannel(siteId: string, channelId: string): Promise<boolean> {
    try {
      const conditions: QueryCondition[] = [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }, {
        column: LIVE_CHANNEL_TABLE.COLUMNS.ID,
        value: channelId
      }];
      
      const result = await this.sqliteHelper.delete(LIVE_CHANNEL_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 从内存缓存移�?
        if (this.channelCache.has(siteId)) {
          this.channelCache.get(siteId)!.delete(channelId);
        }
        
        // 同时删除相关的EPG数据
        await this.sqliteHelper.delete(EPG_TABLE.TABLE_NAME, [{
          column: EPG_TABLE.COLUMNS.SITE_ID,
          value: siteId
        }, {
          column: EPG_TABLE.COLUMNS.CHANNEL_ID,
          value: channelId
        }]);
        
        if (this.epgCache.has(siteId)) {
          this.epgCache.get(siteId)!.delete(channelId);
        }
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to remove channel ${channelId}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 清除过期缓存
   */
  public async clearExpiredCache(): Promise<void> {
    try {
      // 清除过期的频道缓�?
      await this.sqliteHelper.delete(LIVE_CHANNEL_TABLE.TABLE_NAME, [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '<'
      }]);
      
      // 清除过期的EPG缓存
      await this.sqliteHelper.delete(EPG_TABLE.TABLE_NAME, [{
        column: EPG_TABLE.COLUMNS.EXPIRY_TIME,
        value: Date.now(),
        operator: '<'
      }]);
      
      // 清除相关的内存缓�?
      this.invalidateMemoryCache();
      
      Logger.info(TAG, 'Expired live cache cleared');
    } catch (error) {
      Logger.error(TAG, `Failed to clear expired cache: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 清除站点的所有数�?
   * @param siteId 站点ID
   * @returns 是否清除成功
   */
  public async clearSiteData(siteId: string): Promise<boolean> {
    try {
      Logger.warning(TAG, `Clearing all data for site ${siteId}`);
      
      // 删除分组
      await this.sqliteHelper.delete(LIVE_GROUP_TABLE.TABLE_NAME, [{
        column: LIVE_GROUP_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }]);
      
      // 删除频道
      await this.sqliteHelper.delete(LIVE_CHANNEL_TABLE.TABLE_NAME, [{
        column: LIVE_CHANNEL_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }]);
      
      // 删除EPG数据
      await this.sqliteHelper.delete(EPG_TABLE.TABLE_NAME, [{
        column: EPG_TABLE.COLUMNS.SITE_ID,
        value: siteId
      }]);
      
      // 清除内存缓存
      this.groupCache.delete(siteId);
      this.channelCache.delete(siteId);
      this.epgCache.delete(siteId);
      
      Logger.info(TAG, `All data for site ${siteId} cleared`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to clear site data for ${siteId}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 清除所有缓存数�?
   * @returns 是否清除成功
   */
  public async clearAllCache(): Promise<boolean> {
    try {
      Logger.warning(TAG, 'Clearing all live cache data');
      
      // 删除所有相关表数据
      await this.sqliteHelper.delete(LIVE_GROUP_TABLE.TABLE_NAME);
      await this.sqliteHelper.delete(LIVE_CHANNEL_TABLE.TABLE_NAME);
      await this.sqliteHelper.delete(EPG_TABLE.TABLE_NAME);
      
      // 清除内存缓存
      this.invalidateMemoryCache();
      
      Logger.info(TAG, 'All live cache data cleared');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to clear all cache: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 清除播放历史
   * @returns 是否清除成功
   */
  public async clearPlayHistory(): Promise<boolean> {
    try {
      const result = await this.sqliteHelper.delete(LIVE_PLAY_HISTORY_TABLE.TABLE_NAME);
      
      Logger.info(TAG, `Play history cleared (${result.affectedRows} records)`);
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to clear play history: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 使内存缓存失�?
   */
  public invalidateMemoryCache(): void {
    this.channelCache.clear();
    this.groupCache.clear();
    this.epgCache.clear();
    
    Logger.debug(TAG, 'Live memory cache invalidated');
  }
  
  /**
   * 获取缓存统计信息
   */
  public async getCacheStats(): Promise<{
    totalChannels: number;
    totalGroups: number;
    totalEpgItems: number;
    totalSites: number;
  }> {
    try {
      // 获取站点数量
      const sitesResult = await this.sqliteHelper.query(
        LIVE_GROUP_TABLE.TABLE_NAME,
        ['DISTINCT ' + LIVE_GROUP_TABLE.COLUMNS.SITE_ID]
      );
      const totalSites = sitesResult.length;
      
      // 获取频道总数
      const channelsResult = await this.sqliteHelper.query(
        LIVE_CHANNEL_TABLE.TABLE_NAME,
        ['COUNT(*) as count']
      );
      const totalChannels = channelsResult && channelsResult.length > 0 ? Number(channelsResult[0].count) : 0;
      
      // 获取分组总数
      const groupsResult = await this.sqliteHelper.query(
        LIVE_GROUP_TABLE.TABLE_NAME,
        ['COUNT(*) as count']
      );
      const totalGroups = groupsResult && groupsResult.length > 0 ? Number(groupsResult[0].count) : 0;
      
      // 获取EPG条目总数
      const epgResult = await this.sqliteHelper.query(
        EPG_TABLE.TABLE_NAME,
        ['COUNT(*) as count']
      );
      const totalEpgItems = epgResult && epgResult.length > 0 ? Number(epgResult[0].count) : 0;
      
      return {
        totalChannels,
        totalGroups,
        totalEpgItems,
        totalSites
      };
    } catch (error) {
      Logger.error(TAG, `Failed to get cache stats: ${JSON.stringify(error)}`);
      return {
        totalChannels: 0,
        totalGroups: 0,
        totalEpgItems: 0,
        totalSites: 0
      };
    }
  }
}
