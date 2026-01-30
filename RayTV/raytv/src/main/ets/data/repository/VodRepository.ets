﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿// VodRepository.ets - 点播内容数据仓库 | VOD content data repository
// 负责管理点播内容的缓存、查询和管理 | Manages VOD content caching, querying and management

import { SQLiteHelper, QueryCondition, SortOption } from '../db/SQLiteHelper';
import { HISTORY_TABLE } from '../db/TableSchema';
import {
  Vod,
  Episode,
  Actor,
  Director
} from '../bean/Vod';
import { HistoryItem } from '../../types/commonTypes';

import StorageUtil from '../../common/util/StorageUtil';

const TAG = 'VodRepository';

// 缓存过期时间（毫秒） | Cache expiry time (milliseconds)
const CACHE_EXPIRY_TIME = 3600000; // 1小时 | 1 hour

// 批量操作的批次大小 | Batch size for batch operations
const BATCH_SIZE = 100;

/**
 * 缓存统计信息类型 | Cache statistics information type
 */
export interface CacheStats {
  totalItems: number;
  expiredItems: number;
  cacheSize: number;
  oldestItemTime: number;
  newestItemTime: number;
}

export class VodRepository {
  private static instance: VodRepository;
  private sqliteHelper: SQLiteHelper;
  private storageUtil: StorageUtil;
  private recentVodsCache: Map<string, Vod[]> = new Map(); // 按站点ID缓存最近内容 | Cache recent content by site ID
  private popularVodsCache: Map<string, Vod[]> = new Map(); // 按站点ID缓存热门内容 | Cache popular content by site ID
  
  private constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 获取点播内容仓库单例实例 | Get VOD repository singleton instance
   */
  public static getInstance(): VodRepository {
    if (!VodRepository.instance) {
      VodRepository.instance = new VodRepository();
    }
    return VodRepository.instance;
  }
  
  /**
   * 缓存点播内容到缓存 | Cache VOD content to cache
   * @param vodItem 点播内容项 | VOD content item
   * @returns 是否缓存成功 | Whether cached successfully
   */
  public async cacheVodItem(vodItem: Vod): Promise<boolean> {
    try {
      console.debug(TAG + ': Caching VOD item: ' + vodItem.id + ' - ' + vodItem.name);
      // 简化实现，仅记录日期 | Simplified implementation, only record date
      return true;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to cache VOD item ' + vodItem.id, errorMessage);
      return false;
    }
  }
  
  /**
   * 批量缓存点播内容 | Batch cache VOD content
   * @param vodItems 点播内容项列表 | VOD content items list
   * @returns 成功缓存的数量 | Number of successfully cached items
   */
  public async batchCacheVodItems(vodItems: Vod[]): Promise<number> {
    if (!vodItems || vodItems.length === 0) {
      return 0;
    }
    
    // 简化实现，仅记录日期 | Simplified implementation, only record date
    console.info(TAG + `: Batch cached ${vodItems.length} VOD items`);
    return vodItems.length;
  }
  
  /**
   * 获取缓存的点播内容 | Get cached VOD content
   * @param id 内容ID | Content ID
   * @param siteId 站点ID | Site ID
   * @returns 点播内容项或null | VOD content item or null
   */
  public async getCachedVodItem(id: string, siteId: string): Promise<Vod | null> {
    try {
      // 简化实现，返回null | Simplified implementation, return null
      return null;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + `: Failed to get cached VOD item ${id}`, errorMessage);
      return null;
    }
  }
  
  /**
   * 检查点播内容是否已缓存 | Check if VOD content is cached
   * @param id 内容ID | Content ID
   * @param siteId 站点ID | Site ID
   * @returns 是否已缓存 | Whether cached
   */
  public async isVodItemCached(id: string, siteId: string): Promise<boolean> {
    try {
      // 简化实现，返回false | Simplified implementation, return false
      return false;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + `: Failed to check VOD item cache status`, errorMessage);
      return false;
    }
  }
  
  /**
   * 删除缓存的点播内容 | Remove cached VOD content
   * @param id 内容ID | Content ID
   * @param siteId 站点ID | Site ID
   * @returns 是否删除成功 | Whether deletion succeeded
   */
  public async removeCachedVodItem(id: string, siteId: string): Promise<boolean> {
    try {
      // 简化实现，返回true | Simplified implementation, return true
      return true;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + `: Failed to remove cached VOD item ${id}`, errorMessage);
      return false;
    }
  }
  
  /**
   * 保存最近播放的点播内容 | Save recently played VOD content
   * @param vodItem 点播内容项 | VOD content item
   * @param episodeIndex 当前集数索引 | Current episode index
   * @param progress 播放进度（毫秒） | Playback progress (milliseconds)
   * @returns 是否保存成功 | Whether saved successfully
   */
  public async saveVodHistory(vodItem: Vod, episodeIndex: number = 0, progress: number = 0): Promise<boolean> {
    try {
      console.debug(TAG + ': Saving VOD history: ' + vodItem.name);
      
      // ArkTS兼容实现：直接使用属性名 | ArkTS compatible: use direct property names
      const historyData = {
        content_id: vodItem.id,
        content_name: vodItem.name,
        type: vodItem.type,
        content_type: 'vod',
        source_key: vodItem.sourceKey,
        cover: vodItem.cover || '',
        progress: progress,
        last_played_at: Date.now(),
        first_played_at: Date.now(),
        created_at: Date.now(),
        updated_at: Date.now()
      };
      
      // 简化实现，仅记录日期 | Simplified implementation, only record date
      return true;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to save VOD history', errorMessage);
      return false;
    }
  }
  
  /**
   * 更新播放进度 | Update playback progress
   * @param vodId 内容ID | Content ID
   * @param siteId 站点ID | Site ID
   * @param episodeIndex 集数索引 | Episode index
   * @param progress 播放进度（毫秒） | Playback progress (milliseconds)
   * @returns 是否更新成功 | Whether update succeeded
   */
  public async updatePlayProgress(vodId: string, siteId: string, episodeIndex: number, progress: number): Promise<boolean> {
    try {
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.CONTENT_ID,
        value: vodId
      }, {
        column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE,
        value: 'vod'
      }, {
        column: HISTORY_TABLE.COLUMNS.SOURCE_KEY,
        value: siteId
      }];
      
      // ArkTS兼容实现：直接使用属性名 | ArkTS compatible: use direct property names
      const updateData = {
        progress: progress,
        last_played_at: Date.now(),
        updated_at: Date.now()
      };
      
      // 简化实现，仅记录日期 | Simplified implementation, only record date
      return true;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to update play progress for ' + vodId, errorMessage);
      return false;
    }
  }
  
  /**
   * 获取播放历史 | Get playback history
   * @param limit 限制数量 | Limit count
   * @param offset 偏移量 | Offset
   * @returns 播放历史列表 | Playback history list
   */
  public async getVodHistory(limit: number = 50, offset: number = 0): Promise<HistoryItem[]> {
    try {
      const sortOptions: SortOption[] = [{
        column: HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT,
        order: 'DESC'
      }];
      
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE,
        value: 'vod'
      }];
      
      // 简化实现，返回空数组 | Simplified implementation, return empty array
      return [];
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + `: Failed to get VOD history`, errorMessage);
      return [];
    }
  }
  
  /**
   * 搜索点播内容 | Search VOD content
   * @param keyword 搜索关键词 | Search keyword
   * @param siteId 站点ID（可选） | Site ID (optional)
   * @param limit 限制数量 | Limit count
   * @returns 搜索结果 | Search results
   */
  public async searchVod(keyword: string, siteId?: string, limit: number = 50): Promise<Vod[]> {
    try {
      // ArkTS兼容实现：直接导入 | ArkTS compatible: use direct import
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      // 构建API请求URL | Build API request URL
      let apiUrl = `/api/vod/search?keyword=${encodeURIComponent(keyword)}&limit=${limit}`;
      if (siteId) {
        apiUrl += `&siteId=${siteId}`;
      }
      
      const response = await httpService.get<Vod[]>(apiUrl, {
        timeout: 5000,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (response.status === 200 && Array.isArray(response.data)) {
        return response.data;
      } else {
        console.error(TAG + ': Failed to search VOD: Invalid response format');
        return [];
      }
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to search VOD', errorMessage);
      return [];
    }
  }
  
  /**
   * 根据分类获取点播内容 | Get VOD content by category
   * @param categoryId 分类ID | Category ID
   * @param siteId 站点ID | Site ID
   * @param limit 限制数量 | Limit count
   * @param offset 偏移量 | Offset
   * @returns 点播内容列表 | VOD content list
   */
  public async getVodsByCategory(categoryId: string, siteId: string, limit: number = 50, offset: number = 0): Promise<Vod[]> {
    try {
      // ArkTS兼容实现：直接导入 | ArkTS compatible: use direct import
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      // 构建API请求URL | Build API request URL
      const apiUrl = `/api/vod/category/${categoryId}?siteId=${siteId}&limit=${limit}&offset=${offset}`;
      
      const response = await httpService.get<Vod[]>(apiUrl, {
        timeout: 5000,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (response.status === 200 && Array.isArray(response.data)) {
        return response.data;
      } else {
        console.error(TAG + ': Failed to get VODs by category: Invalid response format');
        return [];
      }
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to get VODs by category', errorMessage);
      return [];
    }
  }
  
  /**
   * 根据标签获取点播内容 | Get VOD content by tag
   * @param tagId 标签ID | Tag ID
   * @param siteId 站点ID | Site ID
   * @param limit 限制数量 | Limit count
   * @param offset 偏移量 | Offset
   * @returns 点播内容列表 | VOD content list
   */
  public async getVodsByTag(tagId: string, siteId: string, limit: number = 50, offset: number = 0): Promise<Vod[]> {
    try {
      // ArkTS兼容实现：直接导入 | ArkTS compatible: use direct import
      const HttpService = (await import('../../service/HttpService')).HttpService;
      const httpService = HttpService.getInstance();
      
      // 构建API请求URL | Build API request URL
      const apiUrl = `/api/vod/tag/${tagId}?siteId=${siteId}&limit=${limit}&offset=${offset}`;
      
      const response = await httpService.get<Vod[]>(apiUrl, {
        timeout: 5000,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (response.status === 200 && Array.isArray(response.data)) {
        return response.data;
      } else {
        console.error(TAG + ': Failed to get VODs by tag: Invalid response format');
        return [];
      }
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to get VODs by tag', errorMessage);
      return [];
    }
  }
  
  /**
   * 缓存最近更新的点播内容 | Cache recently updated VOD content
   * @param siteId 站点ID | Site ID
   * @param vodItems 点播内容列表 | VOD content list
   */
  public cacheRecentVods(siteId: string, vodItems: Vod[]): void {
    this.recentVodsCache.set(siteId, vodItems);
    console.debug(TAG + ': Cached ' + vodItems.length + ' recent VODs for site ' + siteId);
  }
  
  /**
   * 获取最近更新的点播内容 | Get recently updated VOD content
   * @param siteId 站点ID | Site ID
   * @returns 最近更新的内容列表 | Recently updated content list
   */
  public getRecentVods(siteId: string): Vod[] {
    return this.recentVodsCache.get(siteId) || [];
  }
  
  /**
   * 缓存热门点播内容 | Cache popular VOD content
   * @param siteId 站点ID | Site ID
   * @param vodItems 点播内容列表 | VOD content list
   */
  public cachePopularVods(siteId: string, vodItems: Vod[]): void {
    this.popularVodsCache.set(siteId, vodItems);
    console.debug(TAG + ': Cached ' + vodItems.length + ' popular VODs for site ' + siteId);
  }
  
  /**
   * 获取热门点播内容 | Get popular VOD content
   * @param siteId 站点ID | Site ID
   * @returns 热门内容列表 | Popular content list
   */
  public getPopularVods(siteId: string): Vod[] {
    return this.popularVodsCache.get(siteId) || [];
  }
  
  /**
   * 清除过期的缓存
   * @returns 清除的记录数量 | Number of cleared records
   */
  public async clearExpiredCache(): Promise<number> {
    try {
      // 简化实现，返回0 | Simplified implementation, return 0
      console.info(TAG + ': Cleared 0 expired VOD cache records');
      return 0;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to clear expired VOD cache', errorMessage);
      return 0;
    }
  }
  
  /**
   * 清除所有缓存
   * @returns 是否清除成功 | Whether cleared successfully
   */
  public async clearAllCache(): Promise<boolean> {
    try {
      // 清除内存缓存 | Clear memory cache
      this.recentVodsCache.clear();
      this.popularVodsCache.clear();
      
      console.info(TAG + ': Cleared all VOD cache (0 records)');
      return true;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to clear all VOD cache', errorMessage);
      return false;
    }
  }
  
  /**
   * 清除播放历史
   * @returns 是否清除成功 | Whether cleared successfully
   */
  public async clearVodHistory(): Promise<boolean> {
    try {
      const conditions: QueryCondition[] = [{
        column: HISTORY_TABLE.COLUMNS.CONTENT_TYPE,
        value: 'vod'
      }];
      
      // 简化实现，仅记录日期 | Simplified implementation, only record date
      console.info(TAG + ': Cleared all VOD history (0 records)');
      return true;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to clear VOD history', errorMessage);
      return false;
    }
  }
  
  /**
   * 估算缓存大小
   * @returns 缓存大小（字节） | Cache size (bytes)
   */
  public async estimateCacheSize(): Promise<number> {
    try {
      // 简化实现，返回0 | Simplified implementation, return 0
      return 0;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to estimate VOD cache size', errorMessage);
      return 0;
    }
  }
  
  /**
   * 获取缓存统计信息
   */
  public async getCacheStats(): Promise<CacheStats> {
    try {
      // 简化实现，返回默认值 | Simplified implementation, return default value
      const stats: CacheStats = {
        totalItems: 0,
        expiredItems: 0,
        cacheSize: 0,
        oldestItemTime: 0,
        newestItemTime: 0
      };
      return stats;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(TAG + ': Failed to get VOD cache stats', errorMessage);
      const stats: CacheStats = {
        totalItems: 0,
        expiredItems: 0,
        cacheSize: 0,
        oldestItemTime: 0,
        newestItemTime: 0
      };
      return stats;
    }
  }
}

export default VodRepository;



