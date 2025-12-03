// 推荐仓库�?- 管理内容推荐算法和数�?import Logger from '../utils/Logger';
import StorageUtil from '../utils/StorageUtil';
import NetworkUtil from '../utils/NetworkUtil';
import EventBusUtil from '../utils/EventBusUtil';
import CacheService from '../service/CacheService';
import UserRepository from './UserRepository';
import SearchHistoryRepository from './SearchHistoryRepository';
import { LocalStorageType, CacheType } from '../model/commonTypes';

// 推荐类型枚举
export enum RecommendationType {
  PERSONALIZED = 'personalized',
  TRENDING = 'trending',
  NEW_RELEASES = 'new_releases',
  SIMILAR = 'similar',
  CONTINUE_WATCHING = 'continue_watching',
  FEATURED = 'featured',
  POPULAR = 'popular',
  RECOMMENDED_FOR_YOU = 'recommended_for_you',
  BASED_ON_WATCH_HISTORY = 'based_on_watch_history',
  STAFF_PICKS = 'staff_picks',
  LIVE_NOW = 'live_now'
}

// 推荐项目接口
export interface RecommendationItem {
  id: string;
  type: 'video' | 'live' | 'playlist';
  data: Record<string, unknown>; // 使用通用类型替代具体类型
  reason?: string; // 推荐理由
  score: number; // 推荐分数
  tags: string[]; // 相关标签
  category?: string;
  viewCount?: number;
  isPremium?: boolean;
  duration?: number;
  releaseDate?: number;
}

// 推荐请求参数接口
export interface RecommendationRequest {
  type: RecommendationType;
  limit?: number;
  offset?: number;
  category?: string;
  tags?: string[];
  videoId?: string; // 用于相似推荐
  userId?: string;
  contentTypes?: ('video' | 'live' | 'playlist')[];
  excludeIds?: string[];
  includePremium?: boolean;
  minScore?: number;
  sortBy?: 'score' | 'date' | 'popularity';
}

// 推荐响应接口
export interface RecommendationResponse {
  items: RecommendationItem[];
  total: number;
  type: RecommendationType;
  generatedAt: number;
  metadata?: {
    requestId?: string;
    algorithmVersion?: string;
    cacheHit?: boolean;
  };
}

// 推荐配置接口
export interface RecommendationConfig {
  enablePersonalization: boolean;
  minWatchHistoryForPersonalization: number;
  cacheDuration: Record<string, number>; // 使用Record替代枚举映射
  pageSize: number;
  maxRecommendationsPerRequest: number;
  enableOfflineRecommendations: boolean;
  useLocalAlgorithm: boolean;
  algorithmWeights: {
    watchHistory: number;
    searchHistory: number;
    popularity: number;
    freshness: number;
    similarity: number;
    userPreferences: number;
  };
}

// 推荐事件类型常量
export const RecommendationEventType = {
  RECOMMENDATIONS_LOADED: 'recommendation:loaded',
  RECOMMENDATIONS_FAILED: 'recommendation:failed',
  PERSONALIZATION_UPDATED: 'recommendation:personalizationUpdated',
  CONTINUE_WATCHING_UPDATED: 'recommendation:continueWatchingUpdated',
  RECOMMENDATION_CONFIG_CHANGED: 'recommendation:configChanged',
  USER_PREFERENCES_UPDATED: 'recommendation:userPreferencesUpdated'
} as const;

// 推荐事件数据接口
export interface RecommendationEvent {
  type: string;
  timestamp: number;
  data?: string | number | boolean | null | Record<string, unknown> | unknown[];
  error?: Error;
}

// 用户偏好接口
export interface UserPreferences {
  preferredCategories: string[];
  preferredTags: string[];
  dislikedCategories: string[];
  dislikedTags: string[];
  preferredContentTypes: ('video' | 'live')[];
  preferredDuration?: {
    min: number;
    max: number;
  };
  languagePreferences?: string[];
  regionPreferences?: string[];
  excludePremiumContent: boolean;
  updatedAt: number;
}

// 推荐仓库�?export class RecommendationRepository {
  private static instance: RecommendationRepository;
  private readonly logger: Logger;
  private readonly storageUtil: StorageUtil;
  private readonly networkUtil: NetworkUtil;
  private readonly eventBus: EventBusUtil;
  private readonly cacheService: CacheService;
  private readonly userRepository: UserRepository;
  private readonly searchHistoryRepository: SearchHistoryRepository;
  
  // API端点配置
  private readonly apiEndpoints = {
    baseUrl: 'https://api.raytv.example.com',
    recommendations: '/recommendations',
    personalized: '/recommendations/personalized',
    similar: '/recommendations/similar/:id',
    trending: '/recommendations/trending',
    continueWatching: '/recommendations/continue-watching',
    userPreferences: '/user/preferences'
  };
  
  // 存储键配�?  private readonly storageKeys = {
    userPreferences: 'recommendation:userPreferences',
    recommendationCache: 'recommendation:cache:',
    watchHistory: 'recommendation:watchHistory',
    recommendationConfig: 'recommendation:config',
    offlineRecommendations: 'recommendation:offline',
    continueWatching: 'recommendation:continueWatching'
  };
  
  // 默认配置
  private readonly defaultConfig: RecommendationConfig = {
    enablePersonalization: true,
    minWatchHistoryForPersonalization: 5,
    cacheDuration: {
      personalized: 300,
      trending: 600,
      new_releases: 1800,
      similar: 900,
      continue_watching: 300,
      featured: 1800,
      popular: 900,
      recommended_for_you: 600,
      based_on_watch_history: 300,
      staff_picks: 3600,
      live_now: 60
    },
    pageSize: 20,
    maxRecommendationsPerRequest: 100,
    enableOfflineRecommendations: true,
    useLocalAlgorithm: false,
    algorithmWeights: {
      watchHistory: 0.35,
      searchHistory: 0.20,
      popularity: 0.15,
      freshness: 0.10,
      similarity: 0.15,
      userPreferences: 0.05
    }
  };
  
  // 缓存的配�?  private cachedConfig: RecommendationConfig | null = null;
  
  // 缓存的用户偏�?  private cachedUserPreferences: UserPreferences | null = null;

  /**
   * 私有构造函�?   */
  private constructor() {
    this.logger = Logger.getInstance();
    this.storageUtil = StorageUtil.getInstance();
    this.networkUtil = NetworkUtil.getInstance();
    this.eventBus = EventBusUtil.getInstance();
    this.cacheService = CacheService.getInstance();
    this.userRepository = UserRepository.getInstance();
    this.searchHistoryRepository = SearchHistoryRepository.getInstance();
    
    this.logger.info('RecommendationRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取RecommendationRepository单例实例
   */
  public static getInstance(): RecommendationRepository {
    if (!RecommendationRepository.instance) {
      RecommendationRepository.instance = new RecommendationRepository();
    }
    return RecommendationRepository.instance;
  }
  
  /**
   * 获取推荐类型枚举的所有�?   * 替代Object.values，兼容ArkTS语法
   */
  private getRecommendationTypeValues(): string[] {
    return [
      RecommendationType.PERSONALIZED,
      RecommendationType.TRENDING,
      RecommendationType.NEW_RELEASES,
      RecommendationType.SIMILAR,
      RecommendationType.CONTINUE_WATCHING,
      RecommendationType.FEATURED,
      RecommendationType.POPULAR,
      RecommendationType.RECOMMENDED_FOR_YOU,
      RecommendationType.BASED_ON_WATCH_HISTORY,
      RecommendationType.STAFF_PICKS,
      RecommendationType.LIVE_NOW
    ];
  }

  /**
   * 初始化推荐仓�?   */
  public async initialize(): Promise<void> {
    try {
      // 加载配置
      await this.loadConfig();
      
      // 加载用户偏好
      await this.loadUserPreferences();
      
      // 预加载一些基础推荐数据（异步）
      this.preloadRecommendations().catch(err => {
        this.logger.warn('Failed to preload recommendations', err);
      });
      
      this.logger.info('RecommendationRepository initialization completed');
    } catch (error) {
      this.Logger.error('Failed to initialize RecommendationRepository', error as Error);
    }
  }

  /**
   * 设置事件监听�?   */
  private setupEventListeners(): void {
    // 监听用户登录/登出事件
    this.eventBus.on('user:login', async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ())))))) => {
      // 登录后加载用户偏�?      await this.loadUserPreferences();
      
      // 清除个性化推荐缓存
      await this.clearCache(RecommendationType.PERSONALIZED);
    });
    
    this.eventBus.on('user:logout', async () => {
      // 登出时重置用户偏�?      this.cachedUserPreferences = null;
    });
    
    // 监听播放进度更新事件
    this.eventBus.on('playback:progressUpdated', async (data: Record<string, unknown>) => {
      if (data.videoId && data.progress) {
        await this.updateWatchHistory(data.videoId as string, data.progress as number, data.duration as number);
      }
    });
    
    // 监听搜索历史更新事件
    this.eventBus.on('search:historyUpdated', async () => {
      // 清除基于搜索历史的推荐缓�?      await this.clearCache(RecommendationType.BASED_ON_WATCH_HISTORY);
    });
  }
  
  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const config = await this.storageUtil.getObject<RecommendationConfig>(
        this.storageKeys.recommendationConfig,
        LocalStorageType.DEFAULT
      );
      
      if (config) {
        this.cachedConfig = { ...this.defaultConfig, ...config };
      } else {
        this.cachedConfig = this.defaultConfig;
        await this.saveConfig();
      }
    } catch (error) {
      this.Logger.error('Failed to load recommendation config', error as Error);
      this.cachedConfig = this.defaultConfig;
    }
  }
  
  /**
   * 保存配置
   */
  private async saveConfig(): Promise<void> {
    try {
      await this.storageUtil.setObject(
        this.storageKeys.recommendationConfig, this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
       instanceof Error ? this.cachedConfig,
        LocalStorageType.DEFAULT
       : new Error(String(this.cachedConfig,
        LocalStorageType.DEFAULT
      )))))));
    } catch (error) {
      this.Logger.error('Failed to save recommendation config', error as Error);
    }
  }
  
  /**
   * 加载用户偏好
   */
  private async loadUserPreferences(): Promise<void> {
    try {
      const preferences = await this.storageUtil.getObject<UserPreferences>(
        this.storageKeys.userPreferences, LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
      )))))));
      
      if (preferences) {
        this.cachedUserPreferences = preferences;
      }
    } catch (error) {
      this.Logger.error('Failed to load user preferences', error as Error);
    }
  }
  
  /**
   * 保存用户偏好
   */
  private async saveUserPreferences(): Promise<void> {
    try {
      if (this.cachedUserPreferences) {
        this.cachedUserPreferences.updatedAt = Date.now();
        await this.storageUtil.setObject(
          this.storageKeys.userPreferences, this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         instanceof Error ? this.cachedUserPreferences,
          LocalStorageType.DEFAULT
         : new Error(String(this.cachedUserPreferences,
          LocalStorageType.DEFAULT
        )))))));
      }
    } catch (error) {
      this.Logger.error('Failed to save user preferences', error as Error);
    }
  }
  
  /**
   * 更新观看历史
   */
  private async updateWatchHistory(videoId: string, progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number instanceof Error ? progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number : new Error(String(progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number instanceof Error ? progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number instanceof Error ? progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number : new Error(String(progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number : new Error(String(progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number instanceof Error ? progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number : new Error(String(progress: number, duration: number instanceof Error ? progress: number, duration: number : new Error(String(progress: number, duration: number))))))): Promise<void> {
    try {
      const watchHistory = await this.storageUtil.getObject<Record<string, { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
      ) || {};
      
      watchHistory[videoId] = {
        progress,
        duration,
        timestamp: Date.now()
      };
      
      await this.storageUtil.setObject(
        this.storageKeys.watchHistory,
        watchHistory,
        LocalStorageType.DEFAULT
      );
      
      // 发布观看历史更新事件
      this.eventBus.publish('recommendation:watchHistoryUpdated', {
        videoId,
        progress,
        duration
      });
    } catch (error) {
      this.Logger.error('Failed to update watch history', error as Error);
    }
  }
  
  /**
   * 预加载推荐数�?   */
  private async preloadRecommendations(): Promise<void> {
    try {
      // 预加载热门推�?      await this.getRecommendations({
        type: RecommendationType.TRENDING, limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      } instanceof Error ? limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      } : new Error(String(limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      } instanceof Error ? limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      } instanceof Error ? limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      } : new Error(String(limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      } : new Error(String(limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      } instanceof Error ? limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      } : new Error(String(limit: 10
      } instanceof Error ? limit: 10
      } : new Error(String(limit: 10
      })))))));
      
      // 预加载新发布内容
      await this.getRecommendations({
        type: RecommendationType.NEW_RELEASES,
        limit: 10
      });
      
      this.logger.debug('Recommendations preloaded successfully');
    } catch (error) {
      this.logger.warn('Failed to preload recommendations', error as Error);
    }
  }
  
  /**
   * 获取推荐内容
   */
  public async getRecommendations(request: RecommendationRequest): Promise<RecommendationResponse> {
    try {
      // 检查缓�?      const cacheKey = this.getCacheKey(request);
      const cachedResponse = await this.cacheService.get<RecommendationResponse>(cacheKey, CacheType.RECOMMENDATION);
      
      if (cachedResponse) {
        this.logger.debug(`Cache hit for recommendation type: ${request.type}`);
        return {
          ...cachedResponse,
          metadata: {
            ...cachedResponse.metadata,
            cacheHit: true
          }
        };
      }
      
      // 从服务器获取推荐
      const response = await this.fetchRecommendationsFromServer(request);
      
      // 缓存响应
      const cacheDuration = this.cachedConfig?.cacheDuration[request.type] || 300;
      await this.cacheService.set(cacheKey, response, CacheType.RECOMMENDATION, cacheDuration);
      
      // 发布推荐加载成功事件
      this.eventBus.publish(RecommendationEventType.RECOMMENDATIONS_LOADED, {
        type: request.type,
        count: response.items.length,
        cacheHit: false
      });
      
      return response;
    } catch (error) {
      // 发布推荐加载失败事件
      this.eventBus.publish(RecommendationEventType.RECOMMENDATIONS_FAILED, {
        type: request.type,
        error: error as Error
      });
      
      // 尝试从离线缓存获�?      return await this.getOfflineRecommendations(request);
    }
  }
  
  /**
   * 从服务器获取推荐
   */
  private async fetchRecommendationsFromServer(request: RecommendationRequest): Promise<RecommendationResponse> {
    const url = this.buildRecommendationUrl(request);
    const headers = this.buildRequestHeaders();
    
    const response = await this.networkUtil.request({
      url,
      method: 'GET',
      headers,
      timeout: 10000
    });
    
    if (!response.success) {
      throw new Error(`Failed to fetch recommendations: ${response.error}`);
    }
    
    return this.parseRecommendationResponse(response.data as Record<string, unknown>, request);
  }
  
  /**
   * 构建推荐URL
   */
  private buildRecommendationUrl(request: RecommendationRequest): string {
    const baseUrl = this.apiEndpoints.baseUrl;
    let endpoint = this.apiEndpoints.recommendations;
    
    switch (request.type) {
      case RecommendationType.PERSONALIZED:
        endpoint = this.apiEndpoints.personalized;
        break;
      case RecommendationType.SIMILAR:
        endpoint = this.apiEndpoints.similar.replace(':id', request.videoId || '');
        break;
      case RecommendationType.TRENDING:
        endpoint = this.apiEndpoints.trending;
        break;
      case RecommendationType.CONTINUE_WATCHING:
        endpoint = this.apiEndpoints.continueWatching;
        break;
      default:
        endpoint = this.apiEndpoints.recommendations;
    }
    
    const params = new URLSearchParams();
    if (request.limit) params.append('limit', request.limit.toString());
    if (request.offset) params.append('offset', request.offset.toString());
    if (request.category) params.append('category', request.category);
    if (request.tags) params.append('tags', request.tags.join(','));
    if (request.contentTypes) params.append('contentTypes', request.contentTypes.join(','));
    if (request.excludeIds) params.append('excludeIds', request.excludeIds.join(','));
    if (request.includePremium !== undefined) params.append('includePremium', request.includePremium.toString());
    if (request.minScore) params.append('minScore', request.minScore.toString());
    if (request.sortBy) params.append('sortBy', request.sortBy);
    
    return `${baseUrl}${endpoint}?${params.toString()}`;
  }
  
  /**
   * 构建请求�?   */
  private buildRequestHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    // 添加用户认证信息
    const currentUser = this.userRepository.getCurrentUser();
    if (currentUser && currentUser.token) {
      headers['Authorization'] = `Bearer ${currentUser.token}`;
    }
    
    return headers;
  }
  
  /**
   * 解析推荐响应
   */
  private parseRecommendationResponse(data: Record<string, unknown>, request: RecommendationRequest): RecommendationResponse {
    return {
      items: (data.items as RecommendationItem[]) || [],
      total: data.total as number || 0,
      type: request.type,
      generatedAt: Date.now(),
      metadata: {
        requestId: data.requestId as string,
        algorithmVersion: data.algorithmVersion as string,
        cacheHit: false
      }
    };
  }
  
  /**
   * 获取离线推荐
   */
  private async getOfflineRecommendations(request: RecommendationRequest): Promise<RecommendationResponse> {
    try {
      const offlineData = await this.storageUtil.getObject<RecommendationResponse>(
        this.storageKeys.offlineRecommendations,
        LocalStorageType.DEFAULT
      );
      
      if (offlineData) {
        // 过滤离线数据以匹配请求类�?        const filteredItems = offlineData.items.filter(item => {
          if (request.contentTypes && !request.contentTypes.includes(item.type)) {
            return false;
          }
          if (request.category && item.category !== request.category) {
            return false;
          }
          if (request.excludeIds && request.excludeIds.includes(item.id)) {
            return false;
          }
          if (request.minScore && item.score < request.minScore) {
            return false;
          }
          return true;
        });
        
        return {
          items: filteredItems.slice(0, request.limit || 20),
          total: filteredItems.length,
          type: request.type,
          generatedAt: offlineData.generatedAt,
          metadata: {
            cacheHit: true,
            offline: true
          }
        };
      }
    } catch (error) {
      this.logger.warn('Failed to get offline recommendations', error as Error);
    }
    
    // 返回空响应作为后�?    return {
      items: [],
      total: 0,
      type: request.type,
      generatedAt: Date.now(),
      metadata: {
        cacheHit: false,
        offline: true
      }
    };
  }
  
  /**
   * 获取缓存�?   */
  private getCacheKey(request: RecommendationRequest): string {
    const keyParts = [
      request.type,
      request.limit?.toString() || '20',
      request.offset?.toString() || '0',
      request.category || '',
      request.tags?.join(',') || '',
      request.videoId || '',
      request.userId || '',
      request.contentTypes?.join(',') || '',
      request.excludeIds?.join(',') || '',
      request.includePremium?.toString() || 'false',
      request.minScore?.toString() || '0',
      request.sortBy || 'score'
    ];
    
    return this.storageKeys.recommendationCache + keyParts.join(':');
  }
  
  /**
   * 清除缓存
   */
  public async clearCache(type?: RecommendationType): Promise<void> {
    try {
      if (type) {
        // 清除特定类型的缓�?        const cacheKey = this.getCacheKey({ type, limit: 0 });
        await this.cacheService.delete(cacheKey, CacheType.RECOMMENDATION);
      } else {
        // 清除所有推荐缓�?        const cacheKeys = this.getRecommendationTypeValues().map(t => 
          this.getCacheKey({ type: t as RecommendationType, limit: 0 })
        );
        
        for (const key of cacheKeys) {
          await this.cacheService.delete(key, CacheType.RECOMMENDATION);
        }
      }
      
      this.logger.info(`Recommendation cache cleared for type: ${type || 'all'}`);
    } catch (error) {
      this.Logger.error('Failed to clear recommendation cache', error as Error);
    }
  }
  
  /**
   * 获取用户偏好
   */
  public getUserPreferences(): UserPreferences | null {
    return this.cachedUserPreferences ? { ...this.cachedUserPreferences } : null;
  }
  
  /**
   * 更新用户偏好
   */
  public async updateUserPreferences(preferences: Partial<UserPreferences>): Promise<void> {
    if (!this.cachedUserPreferences) {
      this.cachedUserPreferences = {
        preferredCategories: [], preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( instanceof Error ? preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now( : new Error(String(preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now()))))))
      };
    }
    
    this.cachedUserPreferences = { ...this.cachedUserPreferences, ...preferences };
    
    await this.saveUserPreferences();
    
    // 发布用户偏好更新事件
    this.eventBus.publish(RecommendationEventType.USER_PREFERENCES_UPDATED, {
      preferences: this.cachedUserPreferences
    });
  }
  
  /**
   * 获取推荐配置
   */
  public getRecommendationConfig(): RecommendationConfig {
    return this.cachedConfig ? { ...this.cachedConfig } : this.defaultConfig;
  }
  
  /**
   * 更新推荐配置
   */
  public async updateRecommendationConfig(config: Partial<RecommendationConfig>): Promise<void> {
    if (!this.cachedConfig) {
      this.cachedConfig = this.defaultConfig;
    }
    
    this.cachedConfig = { ...this.cachedConfig, ...config };
    
    await this.saveConfig();
    
    // 发布配置更新事件
    this.eventBus.publish(RecommendationEventType.RECOMMENDATION_CONFIG_CHANGED, {
      config: this.cachedConfig
    });
  }
  
  /**
   * 获取继续观看推荐
   */
  public async getContinueWatching(): Promise<RecommendationItem[]> {
    try {
      const watchHistory = await this.storageUtil.getObject<Record<string, { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
      );
      
      if (!watchHistory) {
        return [];
      }
      
      // 过滤出未完成的观看记�?      const continueWatchingItems: RecommendationItem[] = [];
      
      for (const [videoId, history] of Object.entries(watchHistory)) {
        if (history.progress < history.duration * 0.9) { // 进度小于90%的视为未完成
          continueWatchingItems.push({
            id: videoId,
            type: 'video',
            data: { id: videoId, progress: history.progress, duration: history.duration },
            reason: '继续观看',
            score: 0.8,
            tags: ['continue-watching'],
            category: 'continue-watching'
          });
        }
      }
      
      // 按时间戳排序，最新的在前
      continueWatchingItems.sort((a, b) => {
        const aTime = watchHistory[a.id]?.timestamp || 0;
        const bTime = watchHistory[b.id]?.timestamp || 0;
        return bTime - aTime;
      });
      
      return continueWatchingItems.slice(0, 10); // 最多返�?0�?    } catch (error) {
      this.Logger.error('Failed to get continue watching items', error as Error);
      return [];
    }
  }
  
  /**
   * 获取相似内容推荐
   */
  public async getSimilarContent(videoId: string, limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10 instanceof Error ? limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10 : new Error(String(limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10 instanceof Error ? limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10 instanceof Error ? limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10 : new Error(String(limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10 : new Error(String(limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10 instanceof Error ? limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10 : new Error(String(limit: number = 10 instanceof Error ? limit: number = 10 : new Error(String(limit: number = 10))))))): Promise<RecommendationItem[]> {
    try {
      const response = await this.getRecommendations({
        type: RecommendationType.SIMILAR,
        videoId,
        limit
      });
      
      return response.items;
    } catch (error) {
      this.Logger.error('Failed to get similar content', error as Error);
      return [];
    }
  }
  
  /**
   * 获取热门推荐
   */
  public async getTrending(limit: number = 20): Promise<RecommendationItem[]> {
    try {
      const response = await this.getRecommendations({
        type: RecommendationType.TRENDING, limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } : new Error(String(limit
      })))))));
      
      return response.items;
    } catch (error) {
      this.Logger.error('Failed to get trending content', error as Error);
      return [];
    }
  }
  
  /**
   * 获取新发布内�?   */
  public async getNewReleases(limit: number = 20): Promise<RecommendationItem[]> {
    try {
      const response = await this.getRecommendations({
        type: RecommendationType.NEW_RELEASES, limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } instanceof Error ? limit
      } : new Error(String(limit
      } : new Error(String(limit
      } instanceof Error ? limit
      } : new Error(String(limit
      })))))));
      
      return response.items;
    } catch (error) {
      this.Logger.error('Failed to get new releases', error as Error);
      return [];
    }
  }
  
  /**
   * 保存离线推荐数据
   */
  public async saveOfflineRecommendations(recommendations: RecommendationItem[]): Promise<void> {
    try {
      const offlineData: RecommendationResponse = {
        items: recommendations, total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( instanceof Error ? total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now( : new Error(String(total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now()))))))
      };
      
      await this.storageUtil.setObject(
        this.storageKeys.offlineRecommendations,
        offlineData,
        LocalStorageType.DEFAULT
      );
      
      this.logger.info(`Saved ${recommendations.length} recommendations for offline use`);
    } catch (error) {
      this.Logger.error('Failed to save offline recommendations', error as Error);
    }
  }
  
  /**
   * 清理过期数据
   */
  public async cleanupExpiredData(): Promise<void> {
    try {
      // 清理过期的观看历史（30天前�?      const watchHistory = await this.storageUtil.getObject<Record<string, { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       instanceof Error ? { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
       : new Error(String({ progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
      )))))));
      
      if (watchHistory) {
        const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
        let cleanedCount = 0;
        
        for (const [videoId, history] of Object.entries(watchHistory)) {
          if (history.timestamp < thirtyDaysAgo) {
            delete watchHistory[videoId];
            cleanedCount++;
          }
        }
        
        if (cleanedCount > 0) {
          await this.storageUtil.setObject(
            this.storageKeys.watchHistory,
            watchHistory,
            LocalStorageType.DEFAULT
          );
          this.logger.info(`Cleaned ${cleanedCount} expired watch history items`);
        }
      }
      
      // 清理过期的推荐缓�?      await this.clearCache();
      
    } catch (error) {
      this.Logger.error('Failed to cleanup expired data', error as Error);
    }
  }
  
  /**
   * 关闭仓库
   */
  public async shutdown(): Promise<void> {
    try {
      // 保存当前状�?      await this.saveConfig();
      await this.saveUserPreferences();
      
      this.logger.info('RecommendationRepository shutdown completed');
    } catch (error) {
      this.logger.error('Failed to shutdown RecommendationRepository', error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error)))))));
    }
  }
}


