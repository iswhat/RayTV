// 鎺ㄨ崘浠撳簱 - 绠＄悊鍐呭鎺ㄨ崘绠楁硶鍜屾暟鎹?import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import UserRepository from './UserRepository';
import SearchHistoryRepository from './SearchHistoryRepository';
import { LocalStorageType, CacheType } from '../model/commonTypes';
import { Serializable } from '../../types/commonTypes';

// 鎺ㄨ崘绫诲瀷鏋氫妇
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

// 鎺ㄨ崘椤圭洰鎺ュ彛
export interface RecommendationItem {
  id: string;
  type: 'video' | 'live' | 'playlist';
  data: Record<string, Serializable>; // 浣跨敤閫氱敤绫诲瀷鏇夸唬鍏蜂綋绫诲瀷
  reason?: string; // 鎺ㄨ崘鐞嗙敱
  score: number; // 鎺ㄨ崘鍒嗘暟
  tags: string[]; // 鐩稿叧鏍囩
  category?: string;
  viewCount?: number;
  isPremium?: boolean;
  duration?: number;
  releaseDate?: number;
}

// 鎺ㄨ崘璇锋眰鍙傛暟鎺ュ彛
export interface RecommendationRequest {
  type: RecommendationType;
  limit?: number;
  offset?: number;
  category?: string;
  tags?: string[];
  videoId?: string; // 鐢ㄤ簬鐩镐技鎺ㄨ崘
  userId?: string;
  contentTypes?: ('video' | 'live' | 'playlist')[];
  excludeIds?: string[];
  includePremium?: boolean;
  minScore?: number;
  sortBy?: 'score' | 'date' | 'popularity';
}

// 鎺ㄨ崘鍝嶅簲鎺ュ彛
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

// 鎺ㄨ崘閰嶇疆鎺ュ彛
export interface RecommendationConfig {
  enablePersonalization: boolean;
  minWatchHistoryForPersonalization: number;
  cacheDuration: Record<string, number>; // 浣跨敤Record鏇夸唬鏋氫妇鏄犲皠
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

// 鎺ㄨ崘浜嬩欢绫诲瀷甯搁噺
export const RecommendationEventType = {
  RECOMMENDATIONS_LOADED: 'recommendation:loaded',
  RECOMMENDATIONS_FAILED: 'recommendation:failed',
  PERSONALIZATION_UPDATED: 'recommendation:personalizationUpdated',
  CONTINUE_WATCHING_UPDATED: 'recommendation:continueWatchingUpdated',
  RECOMMENDATION_CONFIG_CHANGED: 'recommendation:configChanged',
  USER_PREFERENCES_UPDATED: 'recommendation:userPreferencesUpdated'
} as const;

// 鎺ㄨ崘浜嬩欢鏁版嵁鎺ュ彛
export interface RecommendationEvent {
  type: string;
  timestamp: number;
  data?: string | number | boolean | null | Record<string, Serializable> | Serializable[];
  error?: Error;
}

// 鐢ㄦ埛鍋忓ソ鎺ュ彛
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

export class RecommendationRepository {
  private static instance: RecommendationRepository;
  private readonly logger: Logger;
  private readonly storageUtil: StorageUtil;
  private readonly networkUtil: NetworkUtil;
  private readonly eventBus: EventBusUtil;
  private readonly cacheService: CacheService;
  private readonly userRepository: UserRepository;
  private readonly searchHistoryRepository: SearchHistoryRepository;
  
  // API绔偣閰嶇疆
  private readonly apiEndpoints = {
    baseUrl: 'https://api.raytv.example.com',
    recommendations: '/recommendations',
    personalized: '/recommendations/personalized',
    similar: '/recommendations/similar/:id',
    trending: '/recommendations/trending',
    continueWatching: '/recommendations/continue-watching',
    userPreferences: '/user/preferences'
  };
  
  // 瀛樺偍閿厤缃?  private readonly storageKeys = {
    userPreferences: 'recommendation:userPreferences',
    recommendationCache: 'recommendation:cache:',
    watchHistory: 'recommendation:watchHistory',
    recommendationConfig: 'recommendation:config',
    offlineRecommendations: 'recommendation:offline',
    continueWatching: 'recommendation:continueWatching'
  };
  
  // 榛樿閰嶇疆
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
  
  // 缂撳瓨鐨勯厤缃?  private cachedConfig: RecommendationConfig | null = null;
  
  // 缂撳瓨鐨勭敤鎴峰亸濂?  private cachedUserPreferences: UserPreferences | null = null;

  /**
   * 绉佹湁鏋勯€犲嚱鏁?   */
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
   * 鑾峰彇RecommendationRepository鍗曚緥瀹炰緥
   */
  public static getInstance(): RecommendationRepository {
    if (!RecommendationRepository.instance) {
      RecommendationRepository.instance = new RecommendationRepository();
    }
    return RecommendationRepository.instance;
  }
  
  /**
   * 鑾峰彇鎺ㄨ崘绫诲瀷鏋氫妇鐨勬墍鏈夊€?   * 鏇夸唬Object.values锛屽吋瀹笰rkTS璇硶
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
   * 鍒濆鍖栨帹鑽愪粨搴?   */
  public async initialize(): Promise<void> {
    try {
      // 鍔犺浇閰嶇疆
      await this.loadConfig();
      
      // 鍔犺浇鐢ㄦ埛鍋忓ソ
      await this.loadUserPreferences();
      
      // 棰勫姞杞戒竴浜涘熀纭€鎺ㄨ崘鏁版嵁锛堝紓姝ワ級
      this.preloadRecommendations().catch(err => {
        this.logger.warn('Failed to preload recommendations', err);
      });
      
      this.logger.info('RecommendationRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize RecommendationRepository', error as Error);
    }
  }

  /**
   * 璁剧疆浜嬩欢鐩戝惉鍣?   */
  private setupEventListeners(): void {
    // 鐩戝惉鐢ㄦ埛鐧诲綍/鐧诲嚭浜嬩欢
    this.eventBus.on('user:login', async () => {
      // 鐧诲綍鍚庡姞杞界敤鎴峰亸濂?      await this.loadUserPreferences();
      
      // 娓呴櫎涓€у寲鎺ㄨ崘缂撳瓨
      await this.clearCache(RecommendationType.PERSONALIZED);
    });
    
    this.eventBus.on('user:logout', async () => {
      // 鐧诲嚭鏃堕噸缃敤鎴峰亸濂?      this.cachedUserPreferences = null;
    });
    
    // 鐩戝惉鎾斁杩涘害鏇存柊浜嬩欢
    this.eventBus.on('playback:progressUpdated', async (data: Record<string, unknown>) => {
      if (data.videoId && data.progress) {
        await this.updateWatchHistory(data.videoId as string, data.progress as number, data.duration as number);
      }
    });
    
    // 鐩戝惉鎼滅储鍘嗗彶鏇存柊浜嬩欢
    this.eventBus.on('search:historyUpdated', async () => {
      // 娓呴櫎鍩轰簬鎼滅储鍘嗗彶鐨勬帹鑽愮紦瀛?      await this.clearCache(RecommendationType.BASED_ON_WATCH_HISTORY);
    });
  }
  
  /**
   * 鍔犺浇閰嶇疆
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
      this.logger.error('Failed to load recommendation config', error as Error);
      this.cachedConfig = this.defaultConfig;
    }
  }
  
  /**
   * 淇濆瓨閰嶇疆
   */
  private async saveConfig(): Promise<void> {
    try {
      await this.storageUtil.setObject(
        this.storageKeys.recommendationConfig, 
        this.cachedConfig,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save recommendation config', error as Error);
    }
  }
  
  /**
   * 鍔犺浇鐢ㄦ埛鍋忓ソ
   */
  private async loadUserPreferences(): Promise<void> {
    try {
      const preferences = await this.storageUtil.getObject<UserPreferences>(
        this.storageKeys.userPreferences, 
        LocalStorageType.DEFAULT
      );
      
      if (preferences) {
        this.cachedUserPreferences = preferences;
      }
    } catch (error) {
      this.logger.error('Failed to load user preferences', error as Error);
    }
  }
  
  /**
   * 淇濆瓨鐢ㄦ埛鍋忓ソ
   */
  private async saveUserPreferences(): Promise<void> {
    try {
      if (this.cachedUserPreferences) {
        this.cachedUserPreferences.updatedAt = Date.now();
        await this.storageUtil.setObject(
          this.storageKeys.userPreferences, 
          this.cachedUserPreferences,
          LocalStorageType.DEFAULT
        );
      }
    } catch (error) {
      this.logger.error('Failed to save user preferences', error as Error);
    }
  }
  
  /**
   * 鏇存柊瑙傜湅鍘嗗彶
   */
  private async updateWatchHistory(videoId: string, progress: number, duration: number): Promise<void> {
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
      
      // 鍙戝竷瑙傜湅鍘嗗彶鏇存柊浜嬩欢
      this.eventBus.publish('recommendation:watchHistoryUpdated', {
        videoId,
        progress,
        duration
      });
    } catch (error) {
      this.logger.error('Failed to update watch history', error as Error);
    }
  }
  
  /**
   * 棰勫姞杞芥帹鑽愭暟鎹?   */
  private async preloadRecommendations(): Promise<void> {
    try {
      // 棰勫姞杞界儹闂ㄦ帹鑽?      await this.getRecommendations({
        type: RecommendationType.TRENDING, 
        limit: 10
      });
      
      // 棰勫姞杞芥柊鍙戝竷鍐呭
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
   * 鑾峰彇鎺ㄨ崘鍐呭
   */
  public async getRecommendations(request: RecommendationRequest): Promise<RecommendationResponse> {
    try {
      // 妫€鏌ョ紦瀛?      const cacheKey = this.getCacheKey(request);
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
      
      // 浠庢湇鍔″櫒鑾峰彇鎺ㄨ崘
      const response = await this.fetchRecommendationsFromServer(request);
      
      // 缂撳瓨鍝嶅簲
      const cacheDuration = this.cachedConfig?.cacheDuration[request.type] || 300;
      await this.cacheService.set(cacheKey, response, CacheType.RECOMMENDATION, cacheDuration);
      
      // 鍙戝竷鎺ㄨ崘鍔犺浇鎴愬姛浜嬩欢
      this.eventBus.publish(RecommendationEventType.RECOMMENDATIONS_LOADED, {
        type: request.type,
        count: response.items.length,
        cacheHit: false
      });
      
      return response;
    } catch (error) {
      // 鍙戝竷鎺ㄨ崘鍔犺浇澶辫触浜嬩欢
      this.eventBus.publish(RecommendationEventType.RECOMMENDATIONS_FAILED, {
        type: request.type,
        error: error as Error
      });
      
      // 灏濊瘯浠庣绾跨紦瀛樿幏鍙?      return await this.getOfflineRecommendations(request);
    }
  }
  
  /**
   * 浠庢湇鍔″櫒鑾峰彇鎺ㄨ崘
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
    
    return this.parseRecommendationResponse(response.data as Record<string, Serializable>, request);
  }
  
  /**
   * 鏋勫缓鎺ㄨ崘URL
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
   * 鏋勫缓璇锋眰澶?   */
  private buildRequestHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    // 娣诲姞鐢ㄦ埛璁よ瘉淇℃伅
    const currentUser = this.userRepository.getCurrentUser();
    if (currentUser && currentUser.token) {
      headers['Authorization'] = `Bearer ${currentUser.token}`;
    }
    
    return headers;
  }
  
  /**
   * 瑙ｆ瀽鎺ㄨ崘鍝嶅簲
   */
  private parseRecommendationResponse(data: Record<string, Serializable>, request: RecommendationRequest): RecommendationResponse {
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
   * 鑾峰彇绂荤嚎鎺ㄨ崘
   */
  private async getOfflineRecommendations(request: RecommendationRequest): Promise<RecommendationResponse> {
    try {
      const offlineData = await this.storageUtil.getObject<RecommendationResponse>(
        this.storageKeys.offlineRecommendations,
        LocalStorageType.DEFAULT
      );
      
      if (offlineData) {
        // 杩囨护绂荤嚎鏁版嵁浠ュ尮閰嶈姹傜被鍨?        const filteredItems = offlineData.items.filter(item => {
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
    
    // 杩斿洖绌哄搷搴斾綔涓哄悗澶?    return {
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
   * 鑾峰彇缂撳瓨閿?   */
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
   * 娓呴櫎缂撳瓨
   */
  public async clearCache(type?: RecommendationType): Promise<void> {
    try {
      if (type) {
        // 娓呴櫎鐗瑰畾绫诲瀷鐨勭紦瀛?        const cacheKey = this.getCacheKey({ type, limit: 0 });
        await this.cacheService.delete(cacheKey, CacheType.RECOMMENDATION);
      } else {
        // 娓呴櫎鎵€鏈夋帹鑽愮紦瀛?        const cacheKeys = this.getRecommendationTypeValues().map(t => 
          this.getCacheKey({ type: t as RecommendationType, limit: 0 })
        );
        
        for (const key of cacheKeys) {
          await this.cacheService.delete(key, CacheType.RECOMMENDATION);
        }
      }
      
      this.logger.info(`Recommendation cache cleared for type: ${type || 'all'}`);
    } catch (error) {
      this.logger.error('Failed to clear recommendation cache', error as Error);
    }
  }
  
  /**
   * 鑾峰彇鐢ㄦ埛鍋忓ソ
   */
  public getUserPreferences(): UserPreferences | null {
    return this.cachedUserPreferences ? { ...this.cachedUserPreferences } : null;
  }
  
  /**
   * 鏇存柊鐢ㄦ埛鍋忓ソ
   */
  public async updateUserPreferences(preferences: Partial<UserPreferences>): Promise<void> {
    if (!this.cachedUserPreferences) {
      this.cachedUserPreferences = {
        preferredCategories: [], 
        preferredTags: [],
        dislikedCategories: [],
        dislikedTags: [],
        preferredContentTypes: ['video', 'live'],
        excludePremiumContent: false,
        updatedAt: Date.now()
      };
    }
    
    this.cachedUserPreferences = { ...this.cachedUserPreferences, ...preferences };
    
    await this.saveUserPreferences();
    
    // 鍙戝竷鐢ㄦ埛鍋忓ソ鏇存柊浜嬩欢
    this.eventBus.publish(RecommendationEventType.USER_PREFERENCES_UPDATED, {
      preferences: this.cachedUserPreferences
    });
  }
  
  /**
   * 鑾峰彇鎺ㄨ崘閰嶇疆
   */
  public getRecommendationConfig(): RecommendationConfig {
    return this.cachedConfig ? { ...this.cachedConfig } : this.defaultConfig;
  }
  
  /**
   * 鏇存柊鎺ㄨ崘閰嶇疆
   */
  public async updateRecommendationConfig(config: Partial<RecommendationConfig>): Promise<void> {
    if (!this.cachedConfig) {
      this.cachedConfig = this.defaultConfig;
    }
    
    this.cachedConfig = { ...this.cachedConfig, ...config };
    
    await this.saveConfig();
    
    // 鍙戝竷閰嶇疆鏇存柊浜嬩欢
    this.eventBus.publish(RecommendationEventType.RECOMMENDATION_CONFIG_CHANGED, {
      config: this.cachedConfig
    });
  }
  
  /**
   * 鑾峰彇缁х画瑙傜湅鎺ㄨ崘
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
      
      // 杩囨护鍑烘湭瀹屾垚鐨勮鐪嬭褰?      const continueWatchingItems: RecommendationItem[] = [];
      
      for (const [videoId, history] of Object.entries(watchHistory)) {
        if (history.progress < history.duration * 0.9) { // 杩涘害灏忎簬90%鐨勮涓烘湭瀹屾垚
          continueWatchingItems.push({
            id: videoId,
            type: 'video',
            data: { id: videoId, progress: history.progress, duration: history.duration },
            reason: '缁х画瑙傜湅',
            score: 0.8,
            tags: ['continue-watching'],
            category: 'continue-watching'
          });
        }
      }
      
      // 鎸夋椂闂存埑鎺掑簭锛屾渶鏂扮殑鍦ㄥ墠
      continueWatchingItems.sort((a, b) => {
        const aTime = watchHistory[a.id]?.timestamp || 0;
        const bTime = watchHistory[b.id]?.timestamp || 0;
        return bTime - aTime;
      });
      
      return continueWatchingItems.slice(0, 10); // 鏈€澶氳繑鍥?0涓?    } catch (error) {
      this.logger.error('Failed to get continue watching items', error as Error);
      return [];
    }
  }
  
  /**
   * 鑾峰彇鐩镐技鍐呭鎺ㄨ崘
   */
  public async getSimilarContent(videoId: string, limit: number = 10): Promise<RecommendationItem[]> {
    try {
      const response = await this.getRecommendations({
        type: RecommendationType.SIMILAR,
        videoId,
        limit
      });
      
      return response.items;
    } catch (error) {
      this.logger.error('Failed to get similar content', error as Error);
      return [];
    }
  }
  
  /**
   * 鑾峰彇鐑棬鎺ㄨ崘
   */
  public async getTrending(limit: number = 20): Promise<RecommendationItem[]> {
    try {
      const response = await this.getRecommendations({
        type: RecommendationType.TRENDING, 
        limit
      });
      
      return response.items;
    } catch (error) {
      this.logger.error('Failed to get trending content', error as Error);
      return [];
    }
  }
  
  /**
   * 鑾峰彇鏂板彂甯冨唴瀹?   */
  public async getNewReleases(limit: number = 20): Promise<RecommendationItem[]> {
    try {
      const response = await this.getRecommendations({
        type: RecommendationType.NEW_RELEASES, 
        limit
      });
      
      return response.items;
    } catch (error) {
      this.logger.error('Failed to get new releases', error as Error);
      return [];
    }
  }
  
  /**
   * 淇濆瓨绂荤嚎鎺ㄨ崘鏁版嵁
   */
  public async saveOfflineRecommendations(recommendations: RecommendationItem[]): Promise<void> {
    try {
      const offlineData: RecommendationResponse = {
        items: recommendations, 
        total: recommendations.length,
        type: RecommendationType.PERSONALIZED,
        generatedAt: Date.now()
      };
      
      await this.storageUtil.setObject(
        this.storageKeys.offlineRecommendations,
        offlineData,
        LocalStorageType.DEFAULT
      );
      
      this.logger.info(`Saved ${recommendations.length} recommendations for offline use`);
    } catch (error) {
      this.logger.error('Failed to save offline recommendations', error as Error);
    }
  }
  
  /**
   * 娓呯悊杩囨湡鏁版嵁
   */
  public async cleanupExpiredData(): Promise<void> {
    try {
      // 娓呯悊杩囨湡鐨勮鐪嬪巻鍙诧紙30澶╁墠锛?      const watchHistory = await this.storageUtil.getObject<Record<string, { progress: number; duration: number; timestamp: number }>>(
        this.storageKeys.watchHistory,
        LocalStorageType.DEFAULT
      );
      
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
      
      // 娓呯悊杩囨湡鐨勬帹鑽愮紦瀛?      await this.clearCache();
      
    } catch (error) {
      this.logger.error('Failed to cleanup expired data', error as Error);
    }
  }
  
  /**
   * 鍏抽棴浠撳簱
   */
  public async shutdown(): Promise<void> {
    try {
      // 淇濆瓨褰撳墠鐘舵€?      await this.saveConfig();
      await this.saveUserPreferences();
    } catch (error) {
      this.logger.error('Failed to shutdown RecommendationRepository', error as Error);
    }
  }
}


