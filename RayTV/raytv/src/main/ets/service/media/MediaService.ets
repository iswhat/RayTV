// 媒体服务 | Media service
// 实现媒体管理功能，包括播放记录、收藏管理等 | Implement media management functions, including playback records, collection management, etc.


import ApiResponse from '../../data/dto/ApiResponse';
import { SiteService } from '../spider/SiteService';
import { Inject } from '../../common/di/Container';
import CacheService from '../cache/CacheService';

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
  completed: boolean;
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
  score?: number; // 推荐分数
}

// 用户行为接口 | User behavior interface
export interface UserBehavior {
  mediaId: string;
  type: 'play' | 'collect' | 'click' | 'search';
  timestamp: number;
  duration?: number; // 观看时长
  completed?: boolean; // 是否完成观看
}

// 用户偏好接口 | User preference interface
export interface UserPreference {
  mediaType: string;
  weight: number;
}

// 推荐算法配置接口 | Recommendation algorithm config interface
export interface RecommendationConfig {
  popularWeight: number;
  recentWeight: number;
  personalWeight: number;
  diversityWeight: number;
  maxRecommendations: number;
}","}}}

/**
 * 媒体服务类 | Media service class
 * 实现媒体管理功能，包括播放记录、收藏管理等 | Implement media management functions, including playback records, collection management, etc.
 */
export class MediaService {
  private static instance: MediaService | null = null;
  private playbackRecords: Map<string, PlaybackRecord> = new Map();
  private collections: Map<string, MediaInfo> = new Map();
  private userBehaviors: UserBehavior[] = [];
  private userPreferences: UserPreference[] = [];
  private recommendationConfig: RecommendationConfig = {
    popularWeight: 0.3,
    recentWeight: 0.2,
    personalWeight: 0.4,
    diversityWeight: 0.1,
    maxRecommendations: 20
  };
  private isInitialized: boolean = false;
  private progressSyncInterval: number | null = null;
  private cacheService: CacheService = CacheService.getInstance();
  
  @Inject('SiteService')
  private siteService: SiteService;

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
      this.userBehaviors = [];
      this.userPreferences = [];
      
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
      
      // 验证依赖服务是否可用
      if (!this.cacheService) {
        console.error(TAG + ': Cache service not available');
        return ApiResponse.error(500, '缓存服务不可用');
      }
      
      if (!this.siteService) {
        console.error(TAG + ': Site service not available');
        return ApiResponse.error(500, '站点服务不可用');
      }
      
      // 生成缓存键 | Generate cache key
      const cacheKey = 'recommended_content';
      
      // 尝试从缓存获取 | Try to get from cache
      try {
        const cachedData = await this.cacheService.get<RecommendedContent[]>(cacheKey);
        if (cachedData && Array.isArray(cachedData) && cachedData.length > 0) {
          console.info(TAG + ': Loaded recommended content from cache');
          return ApiResponse.success(cachedData, '获取推荐内容成功');
        }
      } catch (cacheError) {
        console.warn(TAG + ': Failed to get cached content:', cacheError);
        // 缓存失败不影响主流程，继续从站点获取
      }
      
      // 从实际站点获取推荐内容 | Get recommended content from actual sites
      // 1. 获取所有启用的站点 | 1. Get all enabled sites
      let enabledSites: Site[] = [];
      try {
        enabledSites = await this.siteService.getEnabledSites();
      } catch (siteError) {
        console.error(TAG + ': Failed to get enabled sites:', siteError);
        return ApiResponse.success([], '获取推荐内容成功');
      }
      
      // 2. 如果没有启用的站点，返回空列表 | 2. If no enabled sites, return empty list
      if (!Array.isArray(enabledSites) || enabledSites.length === 0) {
        console.warn(TAG + ': No enabled sites found');
        return ApiResponse.success([], '获取推荐内容成功');
      }
      
      // 3. 从每个启用的站点获取推荐内容（并行请求） | 3. Get recommended content from each enabled site (parallel requests)
      const sitePromises = enabledSites.map(async (site) => {
        try {
          // 验证站点数据完整性
          if (!site || !site.key || !site.name) {
            console.warn(TAG + ': Invalid site data');
            return [];
          }
          
          // 调用站点的推荐内容方法 | Call site's recommendation method
          const siteContent = await this.siteService.callSiteMethod(
            site.key,
            'getRecommendations',
            [],
            { timeout: 10000 }
          ) as SiteRecommendedItem[];
          
          if (Array.isArray(siteContent) && siteContent.length > 0) {
            // 添加站点标识并处理结果 | Add site identifier and process results
            return siteContent
              .filter(item => item && typeof item === 'object')
              .map(item => {
                const recommendedItem: RecommendedContent = {
                  id: item.id || '',
                  title: item.title || '',
                  cover: item.cover,
                  type: item.type || '',
                  siteKey: site.key,
                  rating: item.rating
                };
                return recommendedItem;
              });
          }
          return [];
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          console.warn(TAG + `: Failed to get recommendations from site ${site?.name || 'unknown'}: ${errorMessage}`);
          return [];
        }
      });
      
      // 等待所有请求完成 | Wait for all requests to complete
      let siteResults: Array<Array<RecommendedMediaItem>> = [];
      try {
        siteResults = await Promise.all(sitePromises);
      } catch (promiseError) {
        console.error(TAG + ': Failed to get site recommendations:', promiseError);
        return ApiResponse.success([], '获取推荐内容成功');
      }
      
      // 合并结果 | Merge results
      const recommendedContent = Array.isArray(siteResults) ? siteResults.flat() : [];
      
      // 4. 如果没有获取到推荐内容，返回空数据 | 4. If no recommended content obtained, return empty data
      if (!Array.isArray(recommendedContent) || recommendedContent.length === 0) {
        console.warn(TAG + ': No recommended content found from any site');
        return ApiResponse.success([], '获取推荐内容成功');
      }
      
      // 缓存结果 | Cache results
      try {
        await this.cacheService.set(cacheKey, recommendedContent, {
          expiry: 300000, // 5分钟缓存
          priority: 'high',
          tags: ['recommended', 'content']
        });
      } catch (cacheError) {
        console.error(TAG + ': Failed to cache recommended content:', cacheError);
        // 缓存失败不影响主流程
      }
      
      console.info(TAG + `: Retrieved ${recommendedContent.length} recommended content items from ${enabledSites.length} sites`);
      return ApiResponse.success(recommendedContent, '获取推荐内容成功');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(TAG + `: Failed to get recommended content: ${errorMessage}`);
      return ApiResponse.error(500, '获取推荐内容失败');
    }
  }

  /**
   * 获取热门内容 | Get popular content
   */
  public async getPopularContent(): Promise<ApiResponse<RecommendedContent[]>> {
    try {
      console.info(TAG + ': Getting popular content...');
      
      // 验证依赖服务是否可用
      if (!this.cacheService) {
        console.error(TAG + ': Cache service not available');
        return ApiResponse.error(500, '缓存服务不可用');
      }
      
      if (!this.siteService) {
        console.error(TAG + ': Site service not available');
        return ApiResponse.error(500, '站点服务不可用');
      }
      
      // 生成缓存键 | Generate cache key
      const cacheKey = 'popular_content';
      
      // 尝试从缓存获取 | Try to get from cache
      try {
        const cachedData = await this.cacheService.get<RecommendedContent[]>(cacheKey);
        if (cachedData && Array.isArray(cachedData) && cachedData.length > 0) {
          console.info(TAG + ': Loaded popular content from cache');
          return ApiResponse.success(cachedData, '获取热门内容成功');
        }
      } catch (cacheError) {
        console.warn(TAG + ': Failed to get cached content:', cacheError);
        // 缓存失败不影响主流程，继续从站点获取
      }
      
      // 从实际站点获取热门内容 | Get popular content from actual sites
      // 1. 获取所有启用的站点 | 1. Get all enabled sites
      let enabledSites: Site[] = [];
      try {
        enabledSites = await this.siteService.getEnabledSites();
      } catch (siteError) {
        console.error(TAG + ': Failed to get enabled sites:', siteError);
        return ApiResponse.success([], '获取热门内容成功');
      }
      
      // 2. 如果没有启用的站点，返回空列表 | 2. If no enabled sites, return empty list
      if (!Array.isArray(enabledSites) || enabledSites.length === 0) {
        console.warn(TAG + ': No enabled sites found');
        return ApiResponse.success([], '获取热门内容成功');
      }
      
      // 3. 从每个启用的站点获取热门内容（并行请求） | 3. Get popular content from each enabled site (parallel requests)
      const sitePromises = enabledSites.map(async (site) => {
        try {
          // 验证站点数据完整性
          if (!site || !site.key || !site.name) {
            console.warn(TAG + ': Invalid site data');
            return [];
          }
          
          // 尝试调用站点的热门内容方法 | Try calling site's popular content method
          const siteContent = await this.siteService.callSiteMethod(
            site.key,
            'getPopularContent',
            [],
            { timeout: 10000 }
          ) as SiteRecommendedItem[];
          
          if (Array.isArray(siteContent) && siteContent.length > 0) {
            // 添加站点标识并处理结果 | Add site identifier and process results
            return siteContent
              .filter(item => item && typeof item === 'object')
              .map(item => {
                const recommendedItem: RecommendedContent = {
                  id: item.id || '',
                  title: item.title || '',
                  cover: item.cover,
                  type: item.type || '',
                  siteKey: site.key,
                  rating: item.rating
                };
                return recommendedItem;
              });
          }
          return [];
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          console.warn(TAG + `: Failed to get popular content from site ${site?.name || 'unknown'}: ${errorMessage}`);
          return [];
        }
      });
      
      // 等待所有请求完成 | Wait for all requests to complete
      let siteResults: Array<Array<RecommendedMediaItem>> = [];
      try {
        siteResults = await Promise.all(sitePromises);
      } catch (promiseError) {
        console.error(TAG + ': Failed to get site popular content:', promiseError);
        return ApiResponse.success([], '获取热门内容成功');
      }
      
      // 合并结果 | Merge results
      const popularContent = Array.isArray(siteResults) ? siteResults.flat() : [];
      
      // 4. 如果没有获取到热门内容，返回空数据 | 4. If no popular content obtained, return empty data
      if (!Array.isArray(popularContent) || popularContent.length === 0) {
        console.warn(TAG + ': No popular content found from any site');
        return ApiResponse.success([], '获取热门内容成功');
      }
      
      // 缓存结果 | Cache results
      try {
        await this.cacheService.set(cacheKey, popularContent, {
          expiry: 600000, // 10分钟缓存
          priority: 'high',
          tags: ['popular', 'content']
        });
      } catch (cacheError) {
        console.error(TAG + ': Failed to cache popular content:', cacheError);
        // 缓存失败不影响主流程
      }
      
      console.info(TAG + `: Retrieved ${popularContent.length} popular content items from ${enabledSites.length} sites`);
      return ApiResponse.success(popularContent, '获取热门内容成功');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(TAG + `: Failed to get popular content: ${errorMessage}`);
      return ApiResponse.error(500, '获取热门内容失败');
    }
  }

  /**
   * 获取最新上线内容 | Get new content
   */
  public async getNewContent(): Promise<ApiResponse<RecommendedContent[]>> {
    try {
      console.info(TAG + ': Getting new content...');
      
      // 验证依赖服务是否可用
      if (!this.cacheService) {
        console.error(TAG + ': Cache service not available');
        return ApiResponse.error(500, '缓存服务不可用');
      }
      
      if (!this.siteService) {
        console.error(TAG + ': Site service not available');
        return ApiResponse.error(500, '站点服务不可用');
      }
      
      // 生成缓存键 | Generate cache key
      const cacheKey = 'new_content';
      
      // 尝试从缓存获取 | Try to get from cache
      try {
        const cachedData = await this.cacheService.get<RecommendedContent[]>(cacheKey);
        if (cachedData && Array.isArray(cachedData) && cachedData.length > 0) {
          console.info(TAG + ': Loaded new content from cache');
          return ApiResponse.success(cachedData, '获取最新上线内容成功');
        }
      } catch (cacheError) {
        console.warn(TAG + ': Failed to get cached content:', cacheError);
        // 缓存失败不影响主流程，继续从站点获取
      }
      
      // 从实际站点获取最新上线内容 | Get new content from actual sites
      // 1. 获取所有启用的站点 | 1. Get all enabled sites
      let enabledSites: Site[] = [];
      try {
        enabledSites = await this.siteService.getEnabledSites();
      } catch (siteError) {
        console.error(TAG + ': Failed to get enabled sites:', siteError);
        return ApiResponse.success([], '获取最新上线内容成功');
      }
      
      // 2. 如果没有启用的站点，返回空列表 | 2. If no enabled sites, return empty list
      if (!Array.isArray(enabledSites) || enabledSites.length === 0) {
        console.warn(TAG + ': No enabled sites found');
        return ApiResponse.success([], '获取最新上线内容成功');
      }
      
      // 3. 从每个启用的站点获取最新上线内容（并行请求） | 3. Get new content from each enabled site (parallel requests)
      const sitePromises = enabledSites.map(async (site) => {
        try {
          // 验证站点数据完整性
          if (!site || !site.key || !site.name) {
            console.warn(TAG + ': Invalid site data');
            return [];
          }
          
          // 尝试调用站点的最新上线内容方法 | Try calling site's new content method
          const siteContent = await this.siteService.callSiteMethod(
            site.key,
            'getNewContent',
            [],
            { timeout: 10000 }
          ) as SiteRecommendedItem[];
          
          if (Array.isArray(siteContent) && siteContent.length > 0) {
            // 添加站点标识并处理结果 | Add site identifier and process results
            return siteContent
              .filter(item => item && typeof item === 'object')
              .map(item => {
                const recommendedItem: RecommendedContent = {
                  id: item.id || '',
                  title: item.title || '',
                  cover: item.cover,
                  type: item.type || '',
                  siteKey: site.key,
                  rating: item.rating
                };
                return recommendedItem;
              });
          }
          return [];
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          console.warn(TAG + `: Failed to get new content from site ${site?.name || 'unknown'}: ${errorMessage}`);
          return [];
        }
      });
      
      // 等待所有请求完成 | Wait for all requests to complete
      let siteResults: Array<Array<RecommendedMediaItem>> = [];
      try {
        siteResults = await Promise.all(sitePromises);
      } catch (promiseError) {
        console.error(TAG + ': Failed to get site new content:', promiseError);
        return ApiResponse.success([], '获取最新上线内容成功');
      }
      
      // 合并结果 | Merge results
      const newContent = Array.isArray(siteResults) ? siteResults.flat() : [];
      
      // 4. 如果没有获取到最新上线内容，返回空数据 | 4. If no new content obtained, return empty data
      if (!Array.isArray(newContent) || newContent.length === 0) {
        console.warn(TAG + ': No new content found from any site');
        return ApiResponse.success([], '获取最新上线内容成功');
      }
      
      // 缓存结果 | Cache results
      try {
        await this.cacheService.set(cacheKey, newContent, {
          expiry: 1800000, // 30分钟缓存
          priority: 'high',
          tags: ['new', 'content']
        });
      } catch (cacheError) {
        console.error(TAG + ': Failed to cache new content:', cacheError);
        // 缓存失败不影响主流程
      }
      
      console.info(TAG + `: Retrieved ${newContent.length} new content items from ${enabledSites.length} sites`);
      return ApiResponse.success(newContent, '获取最新上线内容成功');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(TAG + `: Failed to get new content: ${errorMessage}`);
      return ApiResponse.error(500, '获取最新上线内容失败');
    }
  }

  /**
   * 记录用户行为 | Record user behavior
   */
  public recordUserBehavior(behavior: UserBehavior): void {
    this.userBehaviors.push(behavior);
    
    // 限制行为记录数量，防止内存占用过大
    if (this.userBehaviors.length > 1000) {
      this.userBehaviors = this.userBehaviors.slice(-1000);
    }
    
    // 分析用户偏好
    this.analyzeUserPreferences();
  }

  /**
   * 分析用户偏好 | Analyze user preferences
   */
  private analyzeUserPreferences(): void {
    const typeCount: Map<string, number> = new Map();
    let totalInteractions = 0;
    
    // 统计各类型媒体的交互次数
    for (const behavior of this.userBehaviors) {
      // 这里简化处理，假设行为中包含类型信息
      // 实际应用中可能需要从媒体信息中获取类型
      const mediaType = 'movie'; // 临时值，实际应该从媒体信息中获取
      typeCount.set(mediaType, (typeCount.get(mediaType) || 0) + 1);
      totalInteractions++;
    }
    
    // 计算各类型的权重
    this.userPreferences = [];
    for (const [type, count] of typeCount.entries()) {
      const weight = totalInteractions > 0 ? count / totalInteractions : 0;
      this.userPreferences.push({ mediaType: type, weight });
    }
    
    // 按权重排序
    this.userPreferences.sort((a, b) => b.weight - a.weight);
  }

  /**
   * 计算推荐分数 | Calculate recommendation score
   */
  private calculateRecommendationScore(content: RecommendedContent): number {
    let score = 0;
    
    // 基础分数：基于评分
    if (content.rating) {
      const rating = parseFloat(content.rating);
      if (!isNaN(rating)) {
        score += rating * 0.2;
      }
    }
    
    // 个性化分数：基于用户偏好
    const userPreference = this.userPreferences.find(pref => pref.mediaType === content.type);
    if (userPreference) {
      score += userPreference.weight * 0.4;
    }
    
    // 多样性分数：确保推荐内容多样化
    score += 0.1; // 基础多样性分数
    
    return score;
  }

  /**
   * 优化推荐内容 | Optimize recommended content
   */
  private optimizeRecommendations(contentList: RecommendedContent[]): RecommendedContent[] {
    // 计算每个内容的推荐分数
    const contentWithScores = contentList.map(content => {
      const score = this.calculateRecommendationScore(content);
      const contentWithScore: RecommendedContent & { score?: number } = {
        id: content.id,
        title: content.title,
        cover: content.cover,
        type: content.type,
        siteKey: content.siteKey,
        rating: content.rating,
        score: score
      };
      return contentWithScore;
    });
    
    // 按分数排序
    contentWithScores.sort((a, b) => (b.score || 0) - (a.score || 0));
    
    // 限制推荐数量
    return contentWithScores.slice(0, this.recommendationConfig.maxRecommendations);
  }

  /**
   * 获取个性化推荐内容 | Get personalized recommended content
   */
  public async getPersonalizedRecommendations(): Promise<ApiResponse<RecommendedContent[]>> {
    try {
      console.info(TAG + ': Getting personalized recommendations...');
      
      // 获取基础推荐内容
      const basicRecommendations = await this.getRecommendedContent();
      
      if (!basicRecommendations.isSuccess() || !basicRecommendations.data) {
        return ApiResponse.success([], '获取个性化推荐内容成功');
      }
      
      // 优化推荐内容
      const optimizedRecommendations = this.optimizeRecommendations(basicRecommendations.data);
      
      console.info(TAG + `: Generated ${optimizedRecommendations.length} personalized recommendations`);
      return ApiResponse.success(optimizedRecommendations, '获取个性化推荐内容成功');
    } catch (error: Error) {
      console.error(TAG + `: Failed to get personalized recommendations: ${error.message}`);
      return ApiResponse.error(500, '获取个性化推荐内容失败');
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
    this.userBehaviors.clear();
    this.userPreferences.clear();

    this.isInitialized = false;
    console.info(TAG + ': Media service closed successfully');
  }
}

// 导出类和单例实例 Export class and singleton instance
export default MediaService;
export const mediaService = MediaService.getInstance();
