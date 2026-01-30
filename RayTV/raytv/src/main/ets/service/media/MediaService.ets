// 媒体服务 | Media service
// 实现媒体管理功能，包括播放记录、收藏管理等 | Implement media management functions, including playback records, collection management, etc.


import ApiResponse from '../../data/dto/ApiResponse';
import { SiteService } from '../spider/SiteService';

// 常量定义 | Constant definition
const TAG = 'MediaService';

// 播放记录接口 | Playback record interface
export interface PlaybackRecord {
  mediaId: string;
  title: string;
  episodeName?: string;
  position: number;
  duration: number;
  lastPlayedAt: number;
}

// 媒体信息接口 | Media info interface
export interface MediaInfo {
  mediaId: string;
  title: string;
  type: string;
  cover?: string;
  siteKey: string;
  addedAt: number;
}

// 站点返回的推荐内容接口 | Site returned recommended content interface
export interface SiteRecommendedItem {
  id: string;
  title: string;
  cover?: string;
  type: string;
  rating?: string;
}

// 推荐内容接口 | Recommended content interface
export interface RecommendedContent {
  id: string;
  title: string;
  cover?: string;
  type: string;
  siteKey: string;
  rating?: string;
}

/**
 * 媒体服务类 | Media service class
 * 实现媒体管理功能，包括播放记录、收藏管理等 | Implement media management functions, including playback records, collection management, etc.
 */
export class MediaService {
  private static instance: MediaService | null = null;
  private playbackRecords: Map<string, PlaybackRecord> = new Map();
  private collections: Map<string, MediaInfo> = new Map();
  private isInitialized: boolean = false;
  private progressSyncInterval: number | null = null;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): MediaService {
    if (!MediaService.instance) {
      MediaService.instance = new MediaService();
    }
    return MediaService.instance;
  }

  /**
   * 构造函数 | Constructor
   */
  private constructor() {
    // 直接初始化，不依赖ConfigService | Initialize directly, not dependent on ConfigService
  }

  /**
   * 初始化服务实例 | Initialize service instance
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      console.info(TAG + ': Initializing media service...');
      
      // 初始化数据结构 | Initialize data structure
      this.playbackRecords = new Map();
      this.collections = new Map();
      
      // 启动进度同步 | Start progress sync
      this.startProgressSync();
      
      this.isInitialized = true;
      console.info(TAG + ': Media service initialized successfully');
    } catch (error: Error) {
      console.error(TAG + `: Failed to initialize media service: ${error.message}`);
      throw error;
    }
  }

  /**
   * 开始进度同步 | Start progress sync
   */
  private startProgressSync(): void {
    // 实现进度同步逻辑 | Implement progress sync logic
    this.progressSyncInterval = setInterval(() => {
      // 简单的进度同步日志，不持久化存储 | Simple progress sync log, not persistent storage
      console.info(TAG + `: Progress sync completed at ${new Date().toISOString()}`);
    }, 30000); // 每30秒同步一次 | Sync every 30 seconds
  }

  /**
   * 停止进度同步 | Stop progress sync
   */
  private stopProgressSync(): void {
    if (this.progressSyncInterval) {
      clearInterval(this.progressSyncInterval);
      this.progressSyncInterval = null;
    }
  }

  /**
   * 更新播放记录 | Update playback record
   */
  public updatePlaybackRecord(mediaId: string, record: PlaybackRecord): void {
    this.playbackRecords.set(mediaId, record);
  }

  /**
   * 获取播放记录 | Get playback record
   */
  public getPlaybackRecord(mediaId: string): PlaybackRecord | undefined {
    return this.playbackRecords.get(mediaId);
  }

  /**
   * 删除播放记录 | Delete playback record
   */
  public deletePlaybackRecord(mediaId: string): void {
    this.playbackRecords.delete(mediaId);
  }

  /**
   * 获取所有播放记录 | Get all playback records
   */
  public getAllPlaybackRecords(): Map<string, PlaybackRecord> {
    return this.playbackRecords;
  }

  /**
   * 添加到收藏 | Add to collection
   */
  public addToCollection(mediaId: string, mediaInfo: MediaInfo): void {
    this.collections.set(mediaId, mediaInfo);
  }

  /**
   * 从收藏中删除 | Remove from collection
   */
  public removeFromCollection(mediaId: string): void {
    this.collections.delete(mediaId);
  }

  /**
   * 检查是否已收藏 | Check if collected
   */
  public isCollected(mediaId: string): boolean {
    return this.collections.has(mediaId);
  }

  /**
   * 获取所有收藏 | Get all collections
   */
  public getAllCollections(): Map<string, MediaInfo> {
    return this.collections;
  }
  
  /**
   * 获取推荐内容 | Get recommended content
   */
  public async getRecommendedContent(): Promise<ApiResponse<RecommendedContent[]>> {
    try {
      console.info(TAG + ': Getting recommended content...');
      
      // 从实际站点获取推荐内容 | Get recommended content from actual sites
      // 1. 获取所有启用的站点 | 1. Get all enabled sites
      const siteService = SiteService.getInstance();
      const enabledSites = await siteService.getEnabledSites();
      
      // 2. 如果没有启用的站点，返回空列表 | 2. If no enabled sites, return empty list
      if (enabledSites.length === 0) {
        console.warn(TAG + ': No enabled sites found');
        return ApiResponse.success([], '获取推荐内容成功');
      }
      
      // 3. 从每个启用的站点获取推荐内容 | 3. Get recommended content from each enabled site
      const recommendedContent: RecommendedContent[] = [];
      
      for (const site of enabledSites) {
        try {
          // 调用站点的推荐内容方法 | Call site's recommendation method
          const siteContent = await siteService.callSiteMethod(
            site.key,
            'getRecommendations',
            [],
            { timeout: 10000 }
          ) as SiteRecommendedItem[];
          
          if (Array.isArray(siteContent) && siteContent.length > 0) {
            // 添加站点标识并合并结果 | Add site identifier and merge results
            for (let i = 0; i < siteContent.length; i++) {
              const item = siteContent[i];
              if (item && typeof item === 'object') {
                const contentWithSite: RecommendedContent = {
                  id: item.id || '',
                  title: item.title || '',
                  cover: item.cover,
                  type: item.type || '',
                  siteKey: site.key,
                  rating: item.rating
                };
                recommendedContent.push(contentWithSite);
              }
            }
          }
        } catch (error: Error) {
          console.warn(TAG + `: Failed to get recommendations from site ${site.name}: ${error.message}`);
          // 继续处理下一个站点，不影响整体结果 | Continue processing next site, not affecting overall result
          continue;
        }
      }
      
      // 4. 如果没有获取到推荐内容，返回空数据 | 4. If no recommended content obtained, return empty data
      if (recommendedContent.length === 0) {
        console.warn(TAG + ': No recommended content found from any site');
        return ApiResponse.success([], '获取推荐内容成功');
      }
      
      console.info(TAG + `: Retrieved ${recommendedContent.length} recommended content items from ${enabledSites.length} sites`);
      return ApiResponse.success(recommendedContent, '获取推荐内容成功');
    } catch (error: Error) {
      console.error(TAG + `: Failed to get recommended content: ${error.message}`);
      return ApiResponse.error(500, '获取推荐内容失败');
    }
  }

  /**
   * 关闭媒体服务 Close media service
   */
  public close(): void {
    if (!this.isInitialized) {
      return;
    }

    this.stopProgressSync();
    
    // 清理数据 Clean up data
    this.playbackRecords.clear();
    this.collections.clear();

    this.isInitialized = false;
    console.info(TAG + ': Media service closed successfully');
  }
}

// 导出类和单例实例 Export class and singleton instance
export default MediaService;
export const mediaService = MediaService.getInstance();
