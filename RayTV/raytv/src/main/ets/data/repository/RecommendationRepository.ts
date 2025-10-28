// RecommendationRepository - 内容推荐仓库类
// 负责管理视频和直播的推荐算法和数据

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import { VideoInfo } from '../dto/VideoDto';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';
import { UserRepository } from './UserRepository';
import { SearchHistoryRepository } from './SearchHistoryRepository';
import { LiveStreamInfo, LiveStatus } from './LiveStreamRepository';

/**
 * 推荐类型枚举
 */
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

/**
 * 推荐项目接口
 */
export interface RecommendationItem {
  id: string;
  type: 'video' | 'live' | 'playlist';
  data: VideoInfo | LiveStreamInfo;
  reason?: string; // 推荐理由
  score: number; // 推荐分数
  tags: string[]; // 相关标签
  category?: string;
  viewCount?: number;
  isPremium?: boolean;
  duration?: number;
  releaseDate?: number;
}

/**
 * 推荐请求参数接口
 */
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

/**
 * 推荐响应接口
 */
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

/**
 * 推荐配置接口
 */
export interface RecommendationConfig {
  enablePersonalization: boolean;
  minWatchHistoryForPersonalization: number;
  cacheDuration: {
    [key in RecommendationType]?: number; // 秒
  };
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

/**
 * 推荐事件类型
 */
export const RecommendationEventType = {
  RECOMMENDATIONS_LOADED: 'recommendation:loaded',
  RECOMMENDATIONS_FAILED: 'recommendation:failed',
  PERSONALIZATION_UPDATED: 'recommendation:personalizationUpdated',
  CONTINUE_WATCHING_UPDATED: 'recommendation:continueWatchingUpdated',
  RECOMMENDATION_CONFIG_CHANGED: 'recommendation:configChanged',
  USER_PREFERENCES_UPDATED: 'recommendation:userPreferencesUpdated'
} as const;

/**
 * 推荐事件数据
 */
export interface RecommendationEvent {
  type: string;
  timestamp: number;
  data?: any;
  error?: Error;
}

/**
 * 用户偏好接口
 */
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

/**
 * 推荐仓库类
 */
export class RecommendationRepository {
  private static instance: RecommendationRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  private userRepository = UserRepository.getInstance();
  private searchHistoryRepository = SearchHistoryRepository.getInstance();
  
  // API端点配置
  private apiEndpoints = {
    baseUrl: 'https://api.raytv.example.com',
    recommendations: '/recommendations',
    personalized: '/recommendations/personalized',
    similar: '/recommendations/similar/:id',
    trending: '/recommendations/trending',
    continueWatching: '/recommendations/continue-watching',
    userPreferences: '/user/preferences'
  };
  
  // 存储键配置
  private storageKeys = {
    userPreferences: 'recommendation:userPreferences',
    recommendationCache: 'recommendation:cache:',
    watchHistory: 'recommendation:watchHistory',
    recommendationConfig: 'recommendation:config',
    offlineRecommendations: 'recommendation:offline',
    continueWatching: 'recommendation:continueWatching'
  };
  
  // 默认配置
  private defaultConfig: RecommendationConfig = {
    enablePersonalization: true,
    minWatchHistoryForPersonalization: 5,
    cacheDuration: {
      [RecommendationType.PERSONALIZED]: 300,
      [RecommendationType.TRENDING]: 600,
      [RecommendationType.NEW_RELEASES]: 1800,
      [RecommendationType.SIMILAR]: 900,
      [RecommendationType.CONTINUE_WATCHING]: 300,
      [RecommendationType.FEATURED]: 1800,
      [RecommendationType.POPULAR]: 900,
      [RecommendationType.RECOMMENDED_FOR_YOU]: 600,
      [RecommendationType.BASED_ON_WATCH_HISTORY]: 300,
      [RecommendationType.STAFF_PICKS]: 3600,
      [RecommendationType.LIVE_NOW]: 60
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
  
  // 缓存的配置
  private cachedConfig: RecommendationConfig | null = null;
  
  // 缓存的用户偏好
  private cachedUserPreferences: UserPreferences | null = null;

  /**
   * 私有构造函数
   */
  private constructor() {
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
   * 初始化推荐仓库
   */
  private async initialize(): Promise<void> {
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
      this.logger.error('Failed to initialize RecommendationRepository', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听用户登录/登出事件
    this.eventBus.on('user:login', async () => {
      // 登录后加载用户偏好
      await this.loadUserPreferences();
      
      // 清除个性化推荐缓存
      await this.clearCache(RecommendationType.PERSONALIZED);
    });
    
    this.eventBus.on('user:logout', async () => {
      // 登出时重置用户偏好
      this.cachedUserPreferences = null;
    });
    
    // 监听播放进度更新事件
    this.eventBus.on('playback:progressUpdated', async (data: any) => {
      if (data.videoId && data.progress) {
        // 更新继续观看数据
        await this.updateContinueWatching(data.videoId, data.progress, data.duration, data.type);
      }
    });
    
    // 监听搜索事件
    this.eventBus.on('search:completed', async (data: any) => {
      // 搜索完成后可以更新搜索历史相关的推荐
      await this.clearCache(RecommendationType.BASED_ON_WATCH_HISTORY);
    });
    
    // 监听网络状态变化
    this.eventBus.on('network:statusChanged', async (status: { isOnline: boolean }) => {
      if (status.isOnline) {
        // 在线时刷新热门和精选推荐
        await Promise.all([
          this.getRecommendations({ type: RecommendationType.TRENDING, limit: 50 }),
          this.getRecommendations({ type: RecommendationType.FEATURED, limit: 20 })
        ]);
      }
    });
  }

  /**
   * 获取推荐内容
   * @param request 推荐请求参数
   */
  public async getRecommendations(request: RecommendationRequest): Promise<RecommendationResponse> {
    try {
      // 验证请求参数
      this.validateRecommendationRequest(request);
      
      // 生成缓存键
      const cacheKey = this.generateRecommendationCacheKey(request);
      
      // 尝试从缓存获取
      const config = await this.getConfig();
      const cacheDuration = config.cacheDuration[request.type] || 300; // 默认5分钟
      
      const cachedResponse = await this.cacheService.getCache<RecommendationResponse>(cacheKey);
      if (cachedResponse) {
        this.logger.debug(`Recommendations loaded from cache: ${request.type}`);
        
        // 发布推荐加载事件
        this.eventBus.emit(RecommendationEventType.RECOMMENDATIONS_LOADED, {
          type: RecommendationEventType.RECOMMENDATIONS_LOADED,
          timestamp: Date.now(),
          data: cachedResponse
        } as RecommendationEvent);
        
        return cachedResponse;
      }
      
      // 检查是否可以使用本地推荐算法
      if (config.useLocalAlgorithm && this.canUseLocalAlgorithm(request.type)) {
        const localRecommendations = await this.generateLocalRecommendations(request);
        
        // 缓存本地推荐结果
        await this.cacheService.setCache(
          cacheKey,
          localRecommendations,
          {
            type: CacheType.MEMORY,
            expiry: cacheDuration * 1000
          }
        );
        
        return localRecommendations;
      }
      
      // 根据推荐类型构建API请求
      let recommendations: RecommendationResponse;
      
      try {
        // 尝试从服务器获取推荐
        recommendations = await this.fetchRecommendationsFromServer(request, config);
      } catch (serverError) {
        // 服务器请求失败，尝试使用本地推荐或离线推荐
        this.logger.warn(`Failed to fetch recommendations from server (${request.type}), falling back to local recommendations`, serverError as Error);
        
        if (config.enableOfflineRecommendations) {
          recommendations = await this.getOfflineRecommendations(request);
        } else {
          throw serverError;
        }
      }
      
      // 缓存推荐结果
      await this.cacheService.setCache(
        cacheKey,
        recommendations,
        {
          type: CacheType.MEMORY,
          expiry: cacheDuration * 1000
        }
      );
      
      // 对于热门和精选推荐，同时保存到离线推荐
      if (config.enableOfflineRecommendations && 
          [RecommendationType.TRENDING, RecommendationType.FEATURED, RecommendationType.POPULAR].includes(request.type)) {
        await this.saveOfflineRecommendations(request.type, recommendations);
      }
      
      // 发布推荐加载事件
      this.eventBus.emit(RecommendationEventType.RECOMMENDATIONS_LOADED, {
        type: RecommendationEventType.RECOMMENDATIONS_LOADED,
        timestamp: Date.now(),
        data: recommendations
      } as RecommendationEvent);
      
      this.logger.info(`Recommendations loaded: ${recommendations.items.length} items (${request.type})`);
      
      return recommendations;
    } catch (error) {
      this.logger.error(`Failed to get recommendations for type ${request.type}`, error as Error);
      
      // 发布推荐失败事件
      this.eventBus.emit(RecommendationEventType.RECOMMENDATIONS_FAILED, {
        type: RecommendationEventType.RECOMMENDATIONS_FAILED,
        timestamp: Date.now(),
        error: error as Error,
        data: { request }
      } as RecommendationEvent);
      
      // 返回空推荐
      return {
        items: [],
        total: 0,
        type: request.type,
        generatedAt: Date.now()
      };
    }
  }

  /**
   * 从服务器获取推荐
   */
  private async fetchRecommendationsFromServer(
    request: RecommendationRequest,
    config: RecommendationConfig
  ): Promise<RecommendationResponse> {
    // 确定API端点
    let endpoint = this.apiEndpoints.recommendations;
    let params: any = { ...request };
    
    // 特殊处理不同类型的推荐
    switch (request.type) {
      case RecommendationType.PERSONALIZED:
      case RecommendationType.RECOMMENDED_FOR_YOU:
        endpoint = this.apiEndpoints.personalized;
        break;
      
      case RecommendationType.SIMILAR:
        if (request.videoId) {
          endpoint = this.apiEndpoints.similar.replace(':id', request.videoId);
          delete params.videoId;
        }
        break;
      
      case RecommendationType.TRENDING:
        endpoint = this.apiEndpoints.trending;
        break;
      
      case RecommendationType.CONTINUE_WATCHING:
        endpoint = this.apiEndpoints.continueWatching;
        break;
    }
    
    // 构建请求配置
    const requestConfig: any = {
      params: {
        limit: Math.min(request.limit || config.pageSize, config.maxRecommendationsPerRequest),
        offset: request.offset || 0,
        ...params
      }
    };
    
    // 如果用户已登录，添加认证头
    const authToken = this.userRepository.getAuthToken();
    if (authToken) {
      requestConfig.headers = {
        'Authorization': `Bearer ${authToken}`
      };
    }
    
    // 调用API获取推荐
    const response = await this.networkUtil.get<RecommendationResponse>(
      `${this.apiEndpoints.baseUrl}${endpoint}`,
      requestConfig
    );
    
    return response.data;
  }

  /**
   * 生成本地推荐
   */
  private async generateLocalRecommendations(request: RecommendationRequest): Promise<RecommendationResponse> {
    this.logger.debug(`Generating local recommendations for type: ${request.type}`);
    
    const items: RecommendationItem[] = [];
    const config = await this.getConfig();
    const preferences = await this.getUserPreferences();
    
    switch (request.type) {
      case RecommendationType.CONTINUE_WATCHING:
        // 从本地存储获取继续观看数据
        return await this.getContinueWatchingRecommendations(request);
      
      case RecommendationType.BASED_ON_WATCH_HISTORY:
        // 基于观看历史生成推荐
        return await this.generateRecommendationsFromWatchHistory(request, preferences, config);
      
      case RecommendationType.RECOMMENDED_FOR_YOU:
      case RecommendationType.PERSONALIZED:
        // 个性化推荐，结合多种数据源
        return await this.generatePersonalizedRecommendations(request, preferences, config);
      
      default:
        // 其他类型返回空结果
        return {
          items: [],
          total: 0,
          type: request.type,
          generatedAt: Date.now()
        };
    }
  }

  /**
   * 获取离线推荐
   */
  private async getOfflineRecommendations(request: RecommendationRequest): Promise<RecommendationResponse> {
    try {
      const offlineData = await this.storageUtil.getObject<Map<RecommendationType, RecommendationResponse>>(
        this.storageKeys.offlineRecommendations,
        LocalStorageType.DEFAULT
      );
      
      if (offlineData && offlineData[request.type]) {
        const offlineRecommendations = { ...offlineData[request.type]! };
        
        // 过滤排除的ID
        if (request.excludeIds && request.excludeIds.length > 0) {
          offlineRecommendations.items = offlineRecommendations.items.filter(
            item => !request.excludeIds!.includes(item.id)
          );
        }
        
        // 应用限制
        if (request.limit) {
          offlineRecommendations.items = offlineRecommendations.items.slice(0, request.limit);
        }
        
        return offlineRecommendations;
      }
      
      // 没有离线推荐数据，返回空结果
      return {
        items: [],
        total: 0,
        type: request.type,
        generatedAt: Date.now()
      };
    } catch (error) {
      this.logger.warn('Failed to get offline recommendations', error as Error);
      
      return {
        items: [],
        total: 0,
        type: request.type,
        generatedAt: Date.now()
      };
    }
  }

  /**
   * 保存离线推荐
   */
  private async saveOfflineRecommendations(type: RecommendationType, recommendations: RecommendationResponse): Promise<void> {
    try {
      const offlineData = await this.storageUtil.getObject<Map<RecommendationType, RecommendationResponse>>(
        this.storageKeys.offlineRecommendations,
        LocalStorageType.DEFAULT
      ) || {};
      
      // 更新特定类型的离线推荐
      offlineData[type] = {
        ...recommendations,
        metadata: {
          ...recommendations.metadata,
          offlineSavedAt: Date.now()
        }
      };
      
      // 保存更新后的离线数据
      await this.storageUtil.setObject(
        this.storageKeys.offlineRecommendations,
        offlineData,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.warn(`Failed to save offline recommendations for type ${type}`, error as Error);
    }
  }

  /**
   * 获取继续观看推荐
   */
  private async getContinueWatchingRecommendations(request: RecommendationRequest): Promise<RecommendationResponse> {
    try {
      const continueWatchingData = await this.storageUtil.getObject<Array<{
        id: string;
        type: 'video' | 'live';
        data: VideoInfo | LiveStreamInfo;
        progress: number;
        lastWatchTime: number;
        duration: number;
      }>>(
        this.storageKeys.continueWatching,
        LocalStorageType.DEFAULT
      ) || [];
      
      // 过滤和排序
      let filteredData = continueWatchingData
        .filter(item => {
          // 只保留有足够观看进度的项目
          return item.progress > 0.05 && item.progress < 0.95;
        })
        .sort((a, b) => b.lastWatchTime - a.lastWatchTime);
      
      // 应用排除ID过滤
      if (request.excludeIds && request.excludeIds.length > 0) {
        filteredData = filteredData.filter(item => !request.excludeIds!.includes(item.id));
      }
      
      // 转换为推荐项目
      const items: RecommendationItem[] = filteredData.map(item => ({
        id: item.id,
        type: item.type,
        data: item.data,
        reason: `继续观看 (${Math.round(item.progress * 100)}%)`,
        score: 1.0 - item.progress, // 进度越小，推荐分数越高
        tags: ['continue_watching', 'recent'],
        category: 'continue_watching',
        duration: item.duration
      }));
      
      // 应用限制
      const limit = request.limit || 20;
      const paginatedItems = items.slice(request.offset || 0, (request.offset || 0) + limit);
      
      return {
        items: paginatedItems,
        total: items.length,
        type: request.type,
        generatedAt: Date.now()
      };
    } catch (error) {
      this.logger.error('Failed to get continue watching recommendations', error as Error);
      
      return {
        items: [],
        total: 0,
        type: request.type,
        generatedAt: Date.now()
      };
    }
  }

  /**
   * 更新继续观看数据
   */
  public async updateContinueWatching(
    id: string,
    progress: number,
    duration: number,
    type: 'video' | 'live' = 'video'
  ): Promise<void> {
    try {
      // 只记录有效进度（大于5%且小于95%）
      if (progress < 0.05 || progress >= 0.95 || duration <= 0) {
        return;
      }
      
      const continueWatchingData = await this.storageUtil.getObject<Array<{
        id: string;
        type: 'video' | 'live';
        data: any;
        progress: number;
        lastWatchTime: number;
        duration: number;
      }>>(
        this.storageKeys.continueWatching,
        LocalStorageType.DEFAULT
      ) || [];
      
      // 查找是否已存在该项目
      const existingIndex = continueWatchingData.findIndex(item => item.id === id);
      const continueWatchingItem = {
        id,
        type,
        data: {}, // 这里应该包含完整的视频/直播信息，但暂时留空
        progress,
        lastWatchTime: Date.now(),
        duration
      };
      
      if (existingIndex >= 0) {
        // 更新现有项目
        continueWatchingData[existingIndex] = continueWatchingItem;
      } else {
        // 添加新项目
        continueWatchingData.unshift(continueWatchingItem);
        
        // 限制数量为50
        if (continueWatchingData.length > 50) {
          continueWatchingData.pop();
        }
      }
      
      // 保存更新后的数据
      await this.storageUtil.setObject(
        this.storageKeys.continueWatching,
        continueWatchingData,
        LocalStorageType.DEFAULT
      );
      
      // 清除继续观看推荐缓存
      await this.clearCache(RecommendationType.CONTINUE_WATCHING);
      
      // 发布继续观看更新事件
      this.eventBus.emit(RecommendationEventType.CONTINUE_WATCHING_UPDATED, {
        type: RecommendationEventType.CONTINUE_WATCHING_UPDATED,
        timestamp: Date.now(),
        data: { id, progress, type }
      } as RecommendationEvent);
      
    } catch (error) {
      this.logger.warn(`Failed to update continue watching for ${id}`, error as Error);
    }
  }

  /**
   * 移除继续观看项目
   */
  public async removeContinueWatching(id: string): Promise<boolean> {
    try {
      const continueWatchingData = await this.storageUtil.getObject<Array<{ id: string }>>(
        this.storageKeys.continueWatching,
        LocalStorageType.DEFAULT
      ) || [];
      
      const initialLength = continueWatchingData.length;
      const filteredData = continueWatchingData.filter(item => item.id !== id);
      
      if (filteredData.length !== initialLength) {
        await this.storageUtil.setObject(
          this.storageKeys.continueWatching,
          filteredData,
          LocalStorageType.DEFAULT
        );
        
        // 清除缓存
        await this.clearCache(RecommendationType.CONTINUE_WATCHING);
        
        return true;
      }
      
      return false;
    } catch (error) {
      this.logger.warn(`Failed to remove continue watching item ${id}`, error as Error);
      return false;
    }
  }

  /**
   * 清除所有继续观看项目
   */
  public async clearContinueWatching(): Promise<boolean> {
    try {
      await this.storageUtil.remove(this.storageKeys.continueWatching, LocalStorageType.DEFAULT);
      
      // 清除缓存
      await this.clearCache(RecommendationType.CONTINUE_WATCHING);
      
      return true;
    } catch (error) {
      this.logger.warn('Failed to clear continue watching', error as Error);
      return false;
    }
  }

  /**
   * 获取用户偏好
   */
  public async getUserPreferences(): Promise<UserPreferences> {
    try {
      // 如果缓存为空，加载数据
      if (!this.cachedUserPreferences) {
        await this.loadUserPreferences();
      }
      
      return { ...this.cachedUserPreferences! };
    } catch (error) {
      this.logger.error('Failed to get user preferences', error as Error);
      
      // 返回默认偏好
      return this.getDefaultUserPreferences();
    }
  }

  /**
   * 更新用户偏好
   */
  public async updateUserPreferences(preferences: Partial<UserPreferences>): Promise<UserPreferences> {
    try {
      // 获取当前偏好
      const currentPreferences = await this.getUserPreferences();
      
      // 合并新偏好
      const updatedPreferences: UserPreferences = {
        ...currentPreferences,
        ...preferences,
        updatedAt: Date.now()
      };
      
      // 验证偏好
      this.validateUserPreferences(updatedPreferences);
      
      // 保存更新后的偏好
      this.cachedUserPreferences = updatedPreferences;
      await this.storageUtil.setObject(
        this.storageKeys.userPreferences,
        updatedPreferences,
        LocalStorageType.DEFAULT
      );
      
      // 如果用户已登录，尝试同步到服务器
      if (this.userRepository.isLoggedIn()) {
        this.syncUserPreferencesToServer(updatedPreferences).catch(err => {
          this.logger.warn('Failed to sync user preferences to server', err);
        });
      }
      
      // 清除个性化推荐缓存
      await this.clearCache(RecommendationType.PERSONALIZED);
      await this.clearCache(RecommendationType.RECOMMENDED_FOR_YOU);
      
      // 发布用户偏好更新事件
      this.eventBus.emit(RecommendationEventType.USER_PREFERENCES_UPDATED, {
        type: RecommendationEventType.USER_PREFERENCES_UPDATED,
        timestamp: Date.now(),
        data: updatedPreferences
      } as RecommendationEvent);
      
      this.logger.info('User preferences updated');
      
      return updatedPreferences;
    } catch (error) {
      this.logger.error('Failed to update user preferences', error as Error);
      throw error;
    }
  }

  /**
   * 加载用户偏好
   */
  private async loadUserPreferences(): Promise<void> {
    try {
      // 如果用户已登录，尝试从服务器获取
      if (this.userRepository.isLoggedIn()) {
        try {
          const serverPreferences = await this.fetchUserPreferencesFromServer();
          this.cachedUserPreferences = serverPreferences;
          
          // 保存到本地
          await this.storageUtil.setObject(
            this.storageKeys.userPreferences,
            serverPreferences,
            LocalStorageType.DEFAULT
          );
          
          this.logger.debug('User preferences loaded from server');
          return;
        } catch (serverError) {
          this.logger.warn('Failed to load user preferences from server, falling back to local', serverError as Error);
        }
      }
      
      // 从本地加载
      const localPreferences = await this.storageUtil.getObject<UserPreferences>(
        this.storageKeys.userPreferences,
        LocalStorageType.DEFAULT
      );
      
      this.cachedUserPreferences = localPreferences || this.getDefaultUserPreferences();
      
      this.logger.debug('User preferences loaded from local storage');
    } catch (error) {
      this.logger.error('Failed to load user preferences', error as Error);
      this.cachedUserPreferences = this.getDefaultUserPreferences();
    }
  }

  /**
   * 从服务器获取用户偏好
   */
  private async fetchUserPreferencesFromServer(): Promise<UserPreferences> {
    const response = await this.networkUtil.get<UserPreferences>(
      `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userPreferences}`,
      {
        headers: {
          'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
        }
      }
    );
    
    return response.data;
  }

  /**
   * 同步用户偏好到服务器
   */
  private async syncUserPreferencesToServer(preferences: UserPreferences): Promise<void> {
    await this.networkUtil.put(
      `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userPreferences}`,
      preferences,
      {
        headers: {
          'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
        }
      }
    );
  }

  /**
   * 获取默认用户偏好
   */
  private getDefaultUserPreferences(): UserPreferences {
    return {
      preferredCategories: [],
      preferredTags: [],
      dislikedCategories: [],
      dislikedTags: [],
      preferredContentTypes: ['video', 'live'],
      excludePremiumContent: false,
      updatedAt: Date.now()
    };
  }

  /**
   * 预加载推荐数据
   */
  private async preloadRecommendations(): Promise<void> {
    try {
      await Promise.all([
        // 预加载热门推荐
        this.getRecommendations({ type: RecommendationType.TRENDING, limit: 50 }),
        // 预加载精选推荐
        this.getRecommendations({ type: RecommendationType.FEATURED, limit: 20 }),
        // 预加载继续观看
        this.getRecommendations({ type: RecommendationType.CONTINUE_WATCHING, limit: 10 })
      ]);
    } catch (error) {
      this.logger.warn('Failed to preload recommendations', error as Error);
    }
  }

  /**
   * 生成基于观看历史的推荐
   */
  private async generateRecommendationsFromWatchHistory(
    request: RecommendationRequest,
    preferences: UserPreferences,
    config: RecommendationConfig
  ): Promise<RecommendationResponse> {
    // 这里是一个简化的实现，实际应该基于更复杂的算法
    // 在真实应用中，这里应该使用机器学习模型或更复杂的相似度计算
    
    // 获取观看历史
    const watchHistory = await this.storageUtil.getObject<any[]>(
      this.storageKeys.watchHistory,
      LocalStorageType.DEFAULT
    ) || [];
    
    // 检查是否有足够的观看历史
    if (watchHistory.length < config.minWatchHistoryForPersonalization) {
      // 没有足够的观看历史，返回空结果
      return {
        items: [],
        total: 0,
        type: request.type,
        generatedAt: Date.now()
      };
    }
    
    // 这里应该基于观看历史计算相关的类别、标签等
    // 然后生成推荐
    // 由于是示例实现，返回空结果
    return {
      items: [],
      total: 0,
      type: request.type,
      generatedAt: Date.now()
    };
  }

  /**
   * 生成个性化推荐
   */
  private async generatePersonalizedRecommendations(
    request: RecommendationRequest,
    preferences: UserPreferences,
    config: RecommendationConfig
  ): Promise<RecommendationResponse> {
    // 个性化推荐应该结合多种数据源：
    // 1. 观看历史
    // 2. 搜索历史
    // 3. 用户明确的偏好设置
    // 4. 内容相似度
    // 5. 热门度
    
    // 获取搜索历史
    const searchHistory = await this.searchHistoryRepository.getRecentSearches(20);
    
    // 这里是简化实现，实际应该使用更复杂的算法
    // 由于是示例实现，返回空结果
    return {
      items: [],
      total: 0,
      type: request.type,
      generatedAt: Date.now()
    };
  }

  /**
   * 设置推荐配置
   */
  public async setConfig(config: Partial<RecommendationConfig>): Promise<RecommendationConfig> {
    try {
      // 获取当前配置
      const currentConfig = await this.getConfig();
      
      // 合并新配置
      const updatedConfig: RecommendationConfig = {
        ...currentConfig,
        ...config,
        algorithmWeights: {
          ...currentConfig.algorithmWeights,
          ...(config.algorithmWeights || {})
        },
        cacheDuration: {
          ...currentConfig.cacheDuration,
          ...(config.cacheDuration || {})
        }
      };
      
      // 验证配置
      this.validateConfig(updatedConfig);
      
      // 保存配置
      this.cachedConfig = updatedConfig;
      await this.storageUtil.setObject(
        this.storageKeys.recommendationConfig,
        updatedConfig,
        LocalStorageType.DEFAULT
      );
      
      // 清除所有缓存
      await this.clearAllCache();
      
      // 发布配置变更事件
      this.eventBus.emit(RecommendationEventType.RECOMMENDATION_CONFIG_CHANGED, {
        type: RecommendationEventType.RECOMMENDATION_CONFIG_CHANGED,
        timestamp: Date.now(),
        data: updatedConfig
      } as RecommendationEvent);
      
      this.logger.info('Recommendation configuration updated');
      
      return updatedConfig;
    } catch (error) {
      this.logger.error('Failed to set recommendation config', error as Error);
      throw error;
    }
  }

  /**
   * 获取推荐配置
   */
  public async getConfig(): Promise<RecommendationConfig> {
    try {
      // 如果缓存为空，加载配置
      if (!this.cachedConfig) {
        await this.loadConfig();
      }
      
      return { ...this.cachedConfig! };
    } catch (error) {
      this.logger.error('Failed to get recommendation config', error as Error);
      return { ...this.defaultConfig };
    }
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
      
      this.cachedConfig = config ? {
        ...this.defaultConfig,
        ...config,
        algorithmWeights: {
          ...this.defaultConfig.algorithmWeights,
          ...(config.algorithmWeights || {})
        },
        cacheDuration: {
          ...this.defaultConfig.cacheDuration,
          ...(config.cacheDuration || {})
        }
      } : { ...this.defaultConfig };
      
      // 验证配置
      this.validateConfig(this.cachedConfig);
      
      this.logger.debug('Recommendation configuration loaded');
    } catch (error) {
      this.logger.error('Failed to load recommendation config', error as Error);
      this.cachedConfig = { ...this.defaultConfig };
    }
  }

  /**
   * 清除推荐缓存
   */
  public async clearCache(type?: RecommendationType): Promise<void> {
    try {
      if (type) {
        // 清除特定类型的缓存
        const pattern = `${this.storageKeys.recommendationCache}${type}:*`;
        await this.cacheService.removeCacheByPattern(pattern);
      } else {
        // 清除所有推荐缓存
        const pattern = `${this.storageKeys.recommendationCache}*`;
        await this.cacheService.removeCacheByPattern(pattern);
      }
      
      this.logger.info(`${type ? `Cache cleared for recommendation type: ${type}` : 'All recommendation caches cleared'}`);
    } catch (error) {
      this.logger.warn(`Failed to clear recommendation cache${type ? ` for type ${type}` : ''}`, error as Error);
    }
  }

  /**
   * 清除所有缓存
   */
  private async clearAllCache(): Promise<void> {
    await this.clearCache();
  }

  /**
   * 生成推荐缓存键
   */
  private generateRecommendationCacheKey(request: RecommendationRequest): string {
    const baseKey = `${this.storageKeys.recommendationCache}${request.type}`;
    
    // 添加关键参数到缓存键
    const params = [];
    
    if (request.limit) params.push(`limit:${request.limit}`);
    if (request.offset) params.push(`offset:${request.offset}`);
    if (request.category) params.push(`cat:${request.category}`);
    if (request.videoId) params.push(`vid:${request.videoId}`);
    if (request.userId) params.push(`uid:${request.userId}`);
    if (request.contentTypes) params.push(`types:${request.contentTypes.join(',')}`);
    
    // 添加用户ID到个性化推荐的缓存键
    if ([RecommendationType.PERSONALIZED, RecommendationType.RECOMMENDED_FOR_YOU, RecommendationType.BASED_ON_WATCH_HISTORY].includes(request.type)) {
      const userId = this.userRepository.getCurrentUser()?.id || 'anonymous';
      params.push(`user:${userId}`);
    }
    
    return params.length > 0 ? `${baseKey}:${params.join('_')}` : baseKey;
  }

  /**
   * 验证推荐请求参数
   */
  private validateRecommendationRequest(request: RecommendationRequest): void {
    const errors: string[] = [];
    
    if (!request.type || !Object.values(RecommendationType).includes(request.type)) {
      errors.push('Invalid recommendation type');
    }
    
    if (request.limit !== undefined && (request.limit < 1 || request.limit > 100)) {
      errors.push('Limit must be between 1 and 100');
    }
    
    if (request.offset !== undefined && request.offset < 0) {
      errors.push('Offset cannot be negative');
    }
    
    if (request.videoId && request.type === RecommendationType.SIMILAR) {
      if (!request.videoId || request.videoId.trim().length === 0) {
        errors.push('Video ID is required for similar recommendations');
      }
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 验证用户偏好
   */
  private validateUserPreferences(preferences: UserPreferences): void {
    // 验证数组类型
    if (!Array.isArray(preferences.preferredCategories)) {
      throw new Error('preferredCategories must be an array');
    }
    
    if (!Array.isArray(preferences.preferredTags)) {
      throw new Error('preferredTags must be an array');
    }
    
    if (!Array.isArray(preferences.dislikedCategories)) {
      throw new Error('dislikedCategories must be an array');
    }
    
    if (!Array.isArray(preferences.dislikedTags)) {
      throw new Error('dislikedTags must be an array');
    }
    
    if (!Array.isArray(preferences.preferredContentTypes)) {
      throw new Error('preferredContentTypes must be an array');
    }
    
    // 验证内容类型
    preferences.preferredContentTypes.forEach(type => {
      if (!['video', 'live'].includes(type)) {
        throw new Error(`Invalid content type: ${type}`);
      }
    });
    
    // 验证更新时间
    if (!preferences.updatedAt || typeof preferences.updatedAt !== 'number') {
      throw new Error('updatedAt must be a valid timestamp');
    }
  }

  /**
   * 验证配置
   */
  private validateConfig(config: RecommendationConfig): void {
    const errors: string[] = [];
    
    if (config.minWatchHistoryForPersonalization < 0) {
      errors.push('minWatchHistoryForPersonalization must be non-negative');
    }
    
    if (config.pageSize < 1 || config.pageSize > 100) {
      errors.push('pageSize must be between 1 and 100');
    }
    
    if (config.maxRecommendationsPerRequest < 1 || config.maxRecommendationsPerRequest > 500) {
      errors.push('maxRecommendationsPerRequest must be between 1 and 500');
    }
    
    // 验证权重和为1
    const weights = config.algorithmWeights;
    const weightSum = weights.watchHistory + 
                      weights.searchHistory + 
                      weights.popularity + 
                      weights.freshness + 
                      weights.similarity + 
                      weights.userPreferences;
    
    if (Math.abs(weightSum - 1.0) > 0.001) {
      errors.push('Algorithm weights must sum to 1.0');
    }
    
    // 验证每个权重在合理范围内
    Object.entries(weights).forEach(([key, value]) => {
      if (value < 0 || value > 1) {
        errors.push(`${key} weight must be between 0 and 1`);
      }
    });
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 检查是否可以使用本地推荐算法
   */
  private canUseLocalAlgorithm(type: RecommendationType): boolean {
    // 只有特定类型的推荐可以使用本地算法
    return [
      RecommendationType.CONTINUE_WATCHING,
      RecommendationType.BASED_ON_WATCH_HISTORY
    ].includes(type);
  }

  /**
   * 记录用户与推荐内容的交互
   */
  public async recordRecommendationInteraction(
    recommendationId: string,
    interactionType: 'click' | 'play' | 'watch' | 'like' | 'dislike' | 'share',
    duration?: number
  ): Promise<void> {
    try {
      // 构建交互数据
      const interactionData = {
        recommendationId,
        interactionType,
        timestamp: Date.now(),
        duration,
        userId: this.userRepository.getCurrentUser()?.id || 'anonymous'
      };
      
      // 在实际应用中，这里应该发送到服务器进行分析
      // 这里只是记录日志
      this.logger.debug(`Recommendation interaction recorded: ${interactionType} for ${recommendationId}`);
      
      // 对于不喜欢的交互，可以更新用户偏好
      if (interactionType === 'dislike') {
        // 这里应该获取推荐内容的详细信息，然后更新用户不喜欢的类别/标签
        // 由于没有实际的内容信息，暂时省略
      }
    } catch (error) {
      this.logger.warn(`Failed to record recommendation interaction for ${recommendationId}`, error as Error);
    }
  }

  /**
   * 导出推荐数据（用于备份或分析）
   */
  public async exportData(): Promise<{
    userPreferences: UserPreferences;
    continueWatching: any[];
    watchHistory: any[];
    config: RecommendationConfig;
    exportTime: number;
  }> {
    try {
      const data = {
        userPreferences: await this.getUserPreferences(),
        continueWatching: await this.storageUtil.getObject<any[]>(
          this.storageKeys.continueWatching,
          LocalStorageType.DEFAULT
        ) || [],
        watchHistory: await this.storageUtil.getObject<any[]>(
          this.storageKeys.watchHistory,
          LocalStorageType.DEFAULT
        ) || [],
        config: await this.getConfig(),
        exportTime: Date.now()
      };
      
      this.logger.info('Recommendation data exported');
      
      return data;
    } catch (error) {
      this.logger.error('Failed to export recommendation data', error as Error);
      throw error;
    }
  }
}

// 导出默认实例
export default RecommendationRepository.getInstance();