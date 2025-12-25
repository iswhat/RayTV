// LiveRepository.ets - 直播内容数据仓库
// 负责直播内容的缓存、管理和播放历史记录

import { SQLiteHelper, QueryCondition, SortOption } from '../db/SQLiteHelper';
import { LIVE_CHANNEL_TABLE, LIVE_GROUP_TABLE } from '../db/TableSchema';
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

// 批量操作的批次大�?const BATCH_SIZE = 200;

export class LiveRepository {
  private static instance: LiveRepository;
  private storageUtil: StorageUtil;
  
  // 内存缓存
  private channelCache: Map<string, Map<string, LiveChannel>> = new Map(); // siteId -> channelId -> LiveChannel
  private groupCache: Map<string, LiveGroup[]> = new Map(); // siteId -> LiveGroup[]
  private epgCache: Map<string, Map<string, EpgItem[]>> = new Map(); // siteId -> channelId -> EpgItem[]
  
  private constructor() {
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
   * 初始化直播仓�?   */
  public async init(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing LiveRepository', {});
      // 简化实现，仅记录日志
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize LiveRepository', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  /**
   * 保存直播频道数据
   * @param siteId 站点ID
   * @param channels 频道列表
   * @returns 是否保存成功
   */
  public async saveChannels(siteId: string, channels: LiveChannel[]): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving ${channels.length} channels for site ${siteId}`, {});
      
      // 简化实现，仅更新内存缓存
      if (!this.channelCache.has(siteId)) {
        this.channelCache.set(siteId, new Map());
      }
      
      const channelMap = this.channelCache.get(siteId)!;
      channels.forEach(channel => {
        channelMap.set(channel.id, channel);
      });
      
      return true;
    } catch (error) {
      Logger.error(TAG, 'Failed to save channels', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 获取直播频道列表
   * @param siteId 站点ID
   * @returns 频道列表
   */
  public async getChannels(siteId: string): Promise<LiveChannel[]> {
    try {
      // 从真实API获取频道数据
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      const response = await httpService.get<LiveChannel[]>(
        `/api/live/channels/${siteId}`,
        { timeout: 5000 }
      );
      
      if (response.status === 200 && Array.isArray(response.data)) {
        // 更新内存缓存
        if (!this.channelCache.has(siteId)) {
          this.channelCache.set(siteId, new Map());
        }
        
        const channelMap = this.channelCache.get(siteId)!;
        response.data.forEach(channel => {
          channelMap.set(channel.id, channel);
        });
        
        return response.data;
      } else {
        // 如果API调用失败，从内存缓存获取
        if (this.channelCache.has(siteId)) {
          return Array.from(this.channelCache.get(siteId)!.values());
        }
        return [];
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get channels', error instanceof Error ? error : new Error(String(error)));
      // 如果API调用失败，从内存缓存获取
      if (this.channelCache.has(siteId)) {
        return Array.from(this.channelCache.get(siteId)!.values());
      }
      return [];
    }
  }
  
  /**
   * 根据ID获取直播频道
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @returns 直播频道或null
   */
  public async getChannelById(siteId: string, channelId: string): Promise<LiveChannel | null> {
    try {
      // 从内存缓存获�?      if (this.channelCache.has(siteId)) {
        return this.channelCache.get(siteId)!.get(channelId) || null;
      }
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get channel by ID ${channelId}`, error instanceof Error ? error : new Error(String(error)));
      return null;
    }
  }
  
  /**
   * 搜索直播频道
   * @param keyword 搜索关键�?   * @param siteId 站点ID（可选）
   * @returns 搜索结果
   */
  public async searchChannels(keyword: string, siteId?: string): Promise<LiveChannel[]> {
    try {
      // 从真实API获取搜索结果
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      let apiUrl = `/api/live/search?keyword=${encodeURIComponent(keyword)}`;
      if (siteId) {
        apiUrl += `&siteId=${siteId}`;
      }
      
      const response = await httpService.get<LiveChannel[]>(
        apiUrl,
        { timeout: 5000 }
      );
      
      if (response.status === 200 && Array.isArray(response.data)) {
        return response.data;
      } else {
        // 如果API调用失败，从内存缓存搜索
        const results: LiveChannel[] = [];
        
        const siteIds = siteId ? [siteId] : Array.from(this.channelCache.keys());
        
        for (const sid of siteIds) {
          if (this.channelCache.has(sid)) {
            const channels = Array.from(this.channelCache.get(sid)!.values());
            const matchedChannels = channels.filter(channel => 
              channel.name.includes(keyword)
            );
            results.push(...matchedChannels);
          }
        }
        
        return results;
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to search channels', error instanceof Error ? error : new Error(String(error)));
      // 如果API调用失败，从内存缓存搜索
      const results: LiveChannel[] = [];
      
      const siteIds = siteId ? [siteId] : Array.from(this.channelCache.keys());
      
      for (const sid of siteIds) {
        if (this.channelCache.has(sid)) {
          const channels = Array.from(this.channelCache.get(sid)!.values());
          const matchedChannels = channels.filter(channel => 
            channel.name.includes(keyword)
          );
          results.push(...matchedChannels);
        }
      }
      
      return results;
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
      Logger.debug(TAG, `Saving ${epgItems.length} EPG items for channel ${channelId}`, {});
      
      // 简化实现，仅更新内存缓存
      if (!this.epgCache.has(siteId)) {
        this.epgCache.set(siteId, new Map());
      }
      this.epgCache.get(siteId)!.set(channelId, epgItems);
      
      return true;
    } catch (error) {
      Logger.error(TAG, 'Failed to save EPG data', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 获取EPG数据
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @returns EPG节目列表
   */
  public async getEpgData(siteId: string, channelId: string): Promise<EpgItem[]> {
    try {
      // 从真实API获取EPG数据
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      const response = await httpService.get<EpgItem[]>(
        `/api/live/epg/${siteId}/${channelId}`,
        { timeout: 5000 }
      );
      
      if (response.status === 200 && Array.isArray(response.data)) {
        // 更新内存缓存
        if (!this.epgCache.has(siteId)) {
          this.epgCache.set(siteId, new Map());
        }
        this.epgCache.get(siteId)!.set(channelId, response.data);
        
        return response.data;
      } else {
        // 如果API调用失败，从内存缓存获取
        if (this.epgCache.has(siteId)) {
          return this.epgCache.get(siteId)!.get(channelId) || [];
        }
        return [];
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get EPG data', error instanceof Error ? error : new Error(String(error)));
      // 如果API调用失败，从内存缓存获取
      if (this.epgCache.has(siteId)) {
        return this.epgCache.get(siteId)!.get(channelId) || [];
      }
      return [];
    }
  }
  
  /**
   * 保存直播分组
   * @param siteId 站点ID
   * @param groups 分组列表
   * @returns 是否保存成功
   */
  public async saveGroups(siteId: string, groups: LiveGroup[]): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving ${groups.length} groups for site ${siteId}`, {});
      
      // 简化实现，仅更新内存缓存
      this.groupCache.set(siteId, groups);
      
      return true;
    } catch (error) {
      Logger.error(TAG, 'Failed to save groups', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 获取直播分组列表
   * @param siteId 站点ID
   * @returns 分组列表
   */
  public async getGroups(siteId: string): Promise<LiveGroup[]> {
    try {
      // 从真实API获取分组数据
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      const response = await httpService.get<LiveGroup[]>(
        `/api/live/groups/${siteId}`,
        { timeout: 5000 }
      );
      
      if (response.status === 200 && Array.isArray(response.data)) {
        // 更新内存缓存
        this.groupCache.set(siteId, response.data);
        return response.data;
      } else {
        // 如果API调用失败，从内存缓存获取
        return this.groupCache.get(siteId) || [];
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get groups', error instanceof Error ? error : new Error(String(error)));
      // 如果API调用失败，从内存缓存获取
      return this.groupCache.get(siteId) || [];
    }
  }
  
  /**
   * 根据ID获取直播分组
   * @param siteId 站点ID
   * @param groupId 分组ID
   * @returns 分组或null
   */
  public async getGroupById(siteId: string, groupId: string): Promise<LiveGroup | null> {
    try {
      // 从内存缓存获�?      const groups = this.groupCache.get(siteId);
      if (groups) {
        return groups.find(group => group.id === groupId) || null;
      }
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get group by ID ${groupId}`, error instanceof Error ? error : new Error(String(error)));
      return null;
    }
  }
  
  /**
   * 保存频道到收�?   * @param siteId 站点ID
   * @param channelId 频道ID
   * @returns 是否保存成功
   */
  public async addChannelToFavorites(siteId: string, channelId: string): Promise<boolean> {
    try {
      // 简化实现，仅更新内存缓�?      if (this.channelCache.has(siteId)) {
        const channel = this.channelCache.get(siteId)!.get(channelId);
        if (channel) {
          channel.isFavorite = true;
          return true;
        }
      }
      return false;
    } catch (error) {
      Logger.error(TAG, 'Failed to add channel to favorites', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 从收藏中移除频道
   * @param siteId 站点ID
   * @param channelId 频道ID
   * @returns 是否移除成功
   */
  public async removeChannelFromFavorites(siteId: string, channelId: string): Promise<boolean> {
    try {
      // 简化实现，仅更新内存缓�?      if (this.channelCache.has(siteId)) {
        const channel = this.channelCache.get(siteId)!.get(channelId);
        if (channel) {
          channel.isFavorite = false;
          return true;
        }
      }
      return false;
    } catch (error) {
      Logger.error(TAG, 'Failed to remove channel from favorites', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 获取收藏的频道列�?   * @param siteId 站点ID
   * @returns 收藏的频道列�?   */
  public async getFavoriteChannels(siteId: string): Promise<LiveChannel[]> {
    try {
      // 从内存缓存获�?      if (this.channelCache.has(siteId)) {
        return Array.from(this.channelCache.get(siteId)!.values())
          .filter(channel => channel.isFavorite);
      }
      return [];
    } catch (error) {
      Logger.error(TAG, 'Failed to get favorite channels', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }
  
  /**
   * 清除指定站点的所有数�?   * @param siteId 站点ID
   * @returns 是否清除成功
   */
  public async clearSiteData(siteId: string): Promise<boolean> {
    try {
      Logger.info(TAG, `Clearing all data for site ${siteId}`, {});
      
      // 清空内存缓存
      this.channelCache.delete(siteId);
      this.groupCache.delete(siteId);
      this.epgCache.delete(siteId);
      
      return true;
    } catch (error) {
      Logger.error(TAG, 'Failed to clear site data', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 清除所有数�?   * @returns 是否清除成功
   */
  public async clearAllData(): Promise<boolean> {
    try {
      Logger.info(TAG, 'Clearing all live data', {});
      
      // 清空所有内存缓存
      this.channelCache.clear();
      this.groupCache.clear();
      this.epgCache.clear();
      
      return true;
    } catch (error) {
      Logger.error(TAG, 'Failed to clear all data', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 获取缓存统计信息
   */
  public getCacheStats(): {
    totalChannels: number;
    totalGroups: number;
    totalEpgEntries: number;
  } {
    let totalChannels = 0;
    let totalGroups = 0;
    let totalEpgEntries = 0;
    
    // 统计内存缓存
    for (const channelMap of this.channelCache.values()) {
      totalChannels += channelMap.size;
    }
    
    for (const groups of this.groupCache.values()) {
      totalGroups += groups.length;
    }
    
    for (const epgMap of this.epgCache.values()) {
      for (const epgItems of epgMap.values()) {
        totalEpgEntries += epgItems.length;
      }
    }
    
    return {
      totalChannels,
      totalGroups,
      totalEpgEntries
    };
  }
}
