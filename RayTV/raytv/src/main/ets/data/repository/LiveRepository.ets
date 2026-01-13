// LiveRepository.ets - 鐩存挱鍐呭鏁版嵁浠撳簱
// 璐熻矗鐩存挱鍐呭鐨勭紦瀛樸€佺鐞嗗拰鎾斁鍘嗗彶璁板綍

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

// 缂撳瓨杩囨湡鏃堕棿锛堟绉掞級
const CHANNEL_CACHE_EXPIRY = 7200000; // 2灏忔椂
const EPG_CACHE_EXPIRY = 3600000; // 1灏忔椂

// 鎵归噺鎿嶄綔鐨勬壒娆″ぇ灏?
const BATCH_SIZE = 200;

export class LiveRepository {
  private static instance: LiveRepository;
  private storageUtil: StorageUtil;
  
  // 鍐呭瓨缂撳瓨
  private channelCache: Map<string, Map<string, LiveChannel>> = new Map(); // siteId -> channelId -> LiveChannel
  private groupCache: Map<string, LiveGroup[]> = new Map(); // siteId -> LiveGroup[]
  private epgCache: Map<string, Map<string, EpgItem[]>> = new Map(); // siteId -> channelId -> EpgItem[]
  
  private constructor() {
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 鑾峰彇鐩存挱浠撳簱鍗曚緥瀹炰緥
   */
  public static getInstance(): LiveRepository {
    if (!LiveRepository.instance) {
      LiveRepository.instance = new LiveRepository();
    }
    return LiveRepository.instance;
  }
  
  /**
   * 鍒濆鍖栫洿鎾粨搴?
   */
  public async init(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing LiveRepository', {});
      // 绠€鍖栧疄鐜帮紝浠呰褰曟棩蹇?
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize LiveRepository', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  /**
   * 淇濆瓨鐩存挱棰戦亾鏁版嵁
   * @param siteId 绔欑偣ID
   * @param channels 棰戦亾鍒楄〃
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async saveChannels(siteId: string, channels: LiveChannel[]): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving ${channels.length} channels for site ${siteId}`, {});
      
      // 绠€鍖栧疄鐜帮紝浠呮洿鏂板唴瀛樼紦瀛?
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
   * 鑾峰彇鐩存挱棰戦亾鍒楄〃
   * @param siteId 绔欑偣ID
   * @returns 棰戦亾鍒楄〃
   */
  public async getChannels(siteId: string): Promise<LiveChannel[]> {
    try {
      // 浠庣湡瀹濧PI鑾峰彇棰戦亾鏁版嵁
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      const response = await httpService.get<LiveChannel[]>(
        `/api/live/channels/${siteId}`,
        { timeout: 5000 }
      );
      
      if (response.status === 200 && Array.isArray(response.data)) {
        // 鏇存柊鍐呭瓨缂撳瓨
        if (!this.channelCache.has(siteId)) {
          this.channelCache.set(siteId, new Map());
        }
        
        const channelMap = this.channelCache.get(siteId)!;
        response.data.forEach(channel => {
          channelMap.set(channel.id, channel);
        });
        
        return response.data;
      } else {
        // 濡傛灉API璋冪敤澶辫触锛屼粠鍐呭瓨缂撳瓨鑾峰彇
        if (this.channelCache.has(siteId)) {
          return Array.from(this.channelCache.get(siteId)!.values());
        }
        return [];
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get channels', error instanceof Error ? error : new Error(String(error)));
      // 濡傛灉API璋冪敤澶辫触锛屼粠鍐呭瓨缂撳瓨鑾峰彇
      if (this.channelCache.has(siteId)) {
        return Array.from(this.channelCache.get(siteId)!.values());
      }
      return [];
    }
  }
  
  /**
   * 鏍规嵁ID鑾峰彇鐩存挱棰戦亾
   * @param siteId 绔欑偣ID
   * @param channelId 棰戦亾ID
   * @returns 鐩存挱棰戦亾鎴杗ull
   */
  public async getChannelById(siteId: string, channelId: string): Promise<LiveChannel | null> {
    try {
      // 浠庡唴瀛樼紦瀛樿幏鍙?
      if (this.channelCache.has(siteId)) {
        return this.channelCache.get(siteId)!.get(channelId) || null;
      }
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get channel by ID ${channelId}`, error instanceof Error ? error : new Error(String(error)));
      return null;
    }
  }
  
  /**
   * 鎼滅储鐩存挱棰戦亾
   * @param keyword 鎼滅储鍏抽敭璇?
   * @param siteId 绔欑偣ID锛堝彲閫夛級
   * @returns 鎼滅储缁撴灉
   */
  public async searchChannels(keyword: string, siteId?: string): Promise<LiveChannel[]> {
    try {
      // 浠庣湡瀹濧PI鑾峰彇鎼滅储缁撴灉
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
        // 濡傛灉API璋冪敤澶辫触锛屼粠鍐呭瓨缂撳瓨鎼滅储
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
      // 濡傛灉API璋冪敤澶辫触锛屼粠鍐呭瓨缂撳瓨鎼滅储
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
   * 淇濆瓨EPG鏁版嵁
   * @param siteId 绔欑偣ID
   * @param channelId 棰戦亾ID
   * @param epgItems EPG鑺傜洰鍒楄〃
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async saveEpgData(siteId: string, channelId: string, epgItems: EpgItem[]): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving ${epgItems.length} EPG items for channel ${channelId}`, {});
      
      // 绠€鍖栧疄鐜帮紝浠呮洿鏂板唴瀛樼紦瀛?
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
   * 鑾峰彇EPG鏁版嵁
   * @param siteId 绔欑偣ID
   * @param channelId 棰戦亾ID
   * @returns EPG鑺傜洰鍒楄〃
   */
  public async getEpgData(siteId: string, channelId: string): Promise<EpgItem[]> {
    try {
      // 浠庣湡瀹濧PI鑾峰彇EPG鏁版嵁
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      const response = await httpService.get<EpgItem[]>(
        `/api/live/epg/${siteId}/${channelId}`,
        { timeout: 5000 }
      );
      
      if (response.status === 200 && Array.isArray(response.data)) {
        // 鏇存柊鍐呭瓨缂撳瓨
        if (!this.epgCache.has(siteId)) {
          this.epgCache.set(siteId, new Map());
        }
        this.epgCache.get(siteId)!.set(channelId, response.data);
        
        return response.data;
      } else {
        // 濡傛灉API璋冪敤澶辫触锛屼粠鍐呭瓨缂撳瓨鑾峰彇
        if (this.epgCache.has(siteId)) {
          return this.epgCache.get(siteId)!.get(channelId) || [];
        }
        return [];
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get EPG data', error instanceof Error ? error : new Error(String(error)));
      // 濡傛灉API璋冪敤澶辫触锛屼粠鍐呭瓨缂撳瓨鑾峰彇
      if (this.epgCache.has(siteId)) {
        return this.epgCache.get(siteId)!.get(channelId) || [];
      }
      return [];
    }
  }
  
  /**
   * 淇濆瓨鐩存挱鍒嗙粍
   * @param siteId 绔欑偣ID
   * @param groups 鍒嗙粍鍒楄〃
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async saveGroups(siteId: string, groups: LiveGroup[]): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving ${groups.length} groups for site ${siteId}`, {});
      
      // 绠€鍖栧疄鐜帮紝浠呮洿鏂板唴瀛樼紦瀛?
      this.groupCache.set(siteId, groups);
      
      return true;
    } catch (error) {
      Logger.error(TAG, 'Failed to save groups', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 鑾峰彇鐩存挱鍒嗙粍鍒楄〃
   * @param siteId 绔欑偣ID
   * @returns 鍒嗙粍鍒楄〃
   */
  public async getGroups(siteId: string): Promise<LiveGroup[]> {
    try {
      // 浠庣湡瀹濧PI鑾峰彇鍒嗙粍鏁版嵁
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      const response = await httpService.get<LiveGroup[]>(
        `/api/live/groups/${siteId}`,
        { timeout: 5000 }
      );
      
      if (response.status === 200 && Array.isArray(response.data)) {
        // 鏇存柊鍐呭瓨缂撳瓨
        this.groupCache.set(siteId, response.data);
        return response.data;
      } else {
        // 濡傛灉API璋冪敤澶辫触锛屼粠鍐呭瓨缂撳瓨鑾峰彇
        return this.groupCache.get(siteId) || [];
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get groups', error instanceof Error ? error : new Error(String(error)));
      // 濡傛灉API璋冪敤澶辫触锛屼粠鍐呭瓨缂撳瓨鑾峰彇
      return this.groupCache.get(siteId) || [];
    }
  }
  
  /**
   * 鏍规嵁ID鑾峰彇鐩存挱鍒嗙粍
   * @param siteId 绔欑偣ID
   * @param groupId 鍒嗙粍ID
   * @returns 鍒嗙粍鎴杗ull
   */
  public async getGroupById(siteId: string, groupId: string): Promise<LiveGroup | null> {
    try {
      // 浠庡唴瀛樼紦瀛樿幏鍙?
      const groups = this.groupCache.get(siteId);
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
   * 淇濆瓨棰戦亾鍒版敹钘?
   * @param siteId 绔欑偣ID
   * @param channelId 棰戦亾ID
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async addChannelToFavorites(siteId: string, channelId: string): Promise<boolean> {
    try {
      // 绠€鍖栧疄鐜帮紝浠呮洿鏂板唴瀛樼紦瀛?
      if (this.channelCache.has(siteId)) {
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
   * 浠庢敹钘忎腑绉婚櫎棰戦亾
   * @param siteId 绔欑偣ID
   * @param channelId 棰戦亾ID
   * @returns 鏄惁绉婚櫎鎴愬姛
   */
  public async removeChannelFromFavorites(siteId: string, channelId: string): Promise<boolean> {
    try {
      // 绠€鍖栧疄鐜帮紝浠呮洿鏂板唴瀛樼紦瀛?
      if (this.channelCache.has(siteId)) {
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
   * 鑾峰彇鏀惰棌鐨勯閬撳垪琛?
   * @param siteId 绔欑偣ID
   * @returns 鏀惰棌鐨勯閬撳垪琛?
   */
  public async getFavoriteChannels(siteId: string): Promise<LiveChannel[]> {
    try {
      // 浠庡唴瀛樼紦瀛樿幏鍙?
      if (this.channelCache.has(siteId)) {
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
   * 娓呴櫎鎸囧畾绔欑偣鐨勬墍鏈夋暟鎹?
   * @param siteId 绔欑偣ID
   * @returns 鏄惁娓呴櫎鎴愬姛
   */
  public async clearSiteData(siteId: string): Promise<boolean> {
    try {
      Logger.info(TAG, `Clearing all data for site ${siteId}`, {});
      
      // 娓呯┖鍐呭瓨缂撳瓨
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
   * 娓呴櫎鎵€鏈夋暟鎹?
   * @returns 鏄惁娓呴櫎鎴愬姛
   */
  public async clearAllData(): Promise<boolean> {
    try {
      Logger.info(TAG, 'Clearing all live data', {});
      
      // 娓呯┖鎵€鏈夊唴瀛樼紦瀛?
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
   * 鑾峰彇缂撳瓨缁熻淇℃伅
   */
  public getCacheStats(): {
    totalChannels: number;
    totalGroups: number;
    totalEpgEntries: number;
  } {
    let totalChannels = 0;
    let totalGroups = 0;
    let totalEpgEntries = 0;
    
    // 缁熻鍐呭瓨缂撳瓨
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



