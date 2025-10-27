// LiveStreamService - 直播流服务类
// 负责处理直播流相关的业务逻辑，包括获取直播列表、直播流播放、直播状态管理等

import Logger from '../common/util/Logger';
import NetworkUtil from '../common/util/NetworkUtil';
import CacheService from '../common/util/CacheService';
import StorageUtil from '../common/util/StorageUtil';
import EventBusUtil, { GlobalEventType } from '../common/util/EventBusUtil';
import { LocalStorageType } from '../data/model/LocalModel';
import { CacheType, CachePriority } from '../data/model/CacheModel';
import { ApiResponse } from '../data/dto/ApiResponse';

/**
 * 直播流状态枚举
 */
export enum LiveStreamStatus {
  OFFLINE = 'OFFLINE',       // 离线
  ONLINE = 'ONLINE',         // 在线
  STARTING = 'STARTING',     // 启动中
  STOPPING = 'STOPPING',     // 停止中
  ERROR = 'ERROR',           // 错误
  MAINTENANCE = 'MAINTENANCE' // 维护中
}

/**
 * 直播流质量枚举
 */
export enum LiveStreamQuality {
  LOW = 'LOW',               // 低质量
  MEDIUM = 'MEDIUM',         // 中等质量
  HIGH = 'HIGH',             // 高质量
  HD = 'HD',                 // 高清
  FHD = 'FHD',               // 全高清
  UHD = 'UHD'                // 超高清
}

/**
 * 直播流类型枚举
 */
export enum LiveStreamType {
  TV = 'TV',                 // 电视直播
  SPORTS = 'SPORTS',         // 体育直播
  EVENT = 'EVENT',           // 活动直播
  GAME = 'GAME',             // 游戏直播
  NEWS = 'NEWS',             // 新闻直播
  ENTERTAINMENT = 'ENTERTAINMENT' // 娱乐直播
}

/**
 * 直播流接口
 */
export interface LiveStream {
  id: string;                // 直播流ID
  title: string;             // 标题
  description: string;       // 描述
  coverUrl: string;          // 封面图URL
  streamUrl: string;         // 直播流URL
  hlsUrl?: string;           // HLS流URL（可选）
  rtmpUrl?: string;          // RTMP流URL（可选）
  startTime: number;         // 开始时间
  endTime?: number;          // 结束时间（可选）
  status: LiveStreamStatus;  // 直播状态
  quality: LiveStreamQuality; // 直播质量
  type: LiveStreamType;      // 直播类型
  viewCount: number;         // 观看人数
  likes: number;             // 点赞数
  category: string;          // 分类
  tags: string[];            // 标签
  broadcaster: {
    id: string;              // 主播ID
    name: string;            // 主播名称
    avatarUrl: string;       // 主播头像
    followers: number;       // 粉丝数
  };
  resolution: {
    width: number;           // 宽度
    height: number;          // 高度
    frameRate: number;       // 帧率
  };
  statistics: {
    bandwidth: number;       // 带宽
    bufferHealth: number;    // 缓冲健康度
    latency: number;         // 延迟（毫秒）
  };
  isFavorite: boolean;       // 是否收藏
  lastWatchedTime?: number;  // 最后观看时间（可选）
  metadata?: Record<string, any>; // 额外元数据（可选）
}

/**
 * 直播流列表请求参数
 */
export interface LiveStreamListParams {
  page?: number;             // 页码
  pageSize?: number;         // 每页数量
  type?: LiveStreamType;     // 直播类型
  category?: string;         // 分类
  search?: string;           // 搜索关键词
  sortBy?: 'viewCount' | 'startTime' | 'likes'; // 排序字段
  sortOrder?: 'asc' | 'desc'; // 排序顺序
  onlyLive?: boolean;        // 仅显示在线直播
  tags?: string[];           // 标签筛选
}

/**
 * 直播流列表响应
 */
export interface LiveStreamListResponse {
  streams: LiveStream[];     // 直播流列表
  total: number;             // 总数
  page: number;              // 当前页码
  pageSize: number;          // 每页数量
  hasMore: boolean;          // 是否有更多
}

/**
 * 直播流统计数据
 */
export interface LiveStreamStatistics {
  totalStreams: number;      // 总直播流数
  onlineStreams: number;     // 在线直播流数
  offlineStreams: number;    // 离线直播流数
  totalViewers: number;      // 总观看人数
  peakViewers: number;       // 峰值观看人数
  bandwidthUsage: number;    // 带宽使用量
  topCategories: {
    name: string;
    count: number;
  }[];
  topBroadcasters: {
    id: string;
    name: string;
    streamCount: number;
    viewerCount: number;
  }[];
  uptimePercentage: number;  // 正常运行时间百分比
}

/**
 * 直播流播放历史
 */
export interface LiveStreamHistory {
  streamId: string;          // 直播流ID
  lastWatchedTime: number;   // 最后观看时间
  watchDuration: number;     // 观看时长（毫秒）
  quality: LiveStreamQuality; // 观看质量
  deviceInfo: {
    name: string;            // 设备名称
    type: string;            // 设备类型
  };
}

/**
 * 直播流监控数据
 */
export interface LiveStreamMonitoring {
  streamId: string;          // 直播流ID
  timestamp: number;         // 时间戳
  status: LiveStreamStatus;  // 状态
  latency: number;           // 延迟
  bufferLevel: number;       // 缓冲级别
  bitrate: number;           // 比特率
  resolution: {
    width: number;
    height: number;
  };
  errorCode?: string;        // 错误代码（可选）
  errorMessage?: string;     // 错误消息（可选）
}

/**
 * 直播流服务类
 */
export class LiveStreamService {
  private static instance: LiveStreamService;
  private logger = Logger.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private cacheService = CacheService.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  
  // 缓存键前缀
  private static readonly CACHE_PREFIX = 'live_stream_';
  // API端点
  private static readonly API_ENDPOINTS = {
    BASE_URL: '/api/v1/live',
    STREAMS: '/streams',
    DETAIL: '/streams/:id',
    STATISTICS: '/statistics',
    FAVORITES: '/favorites',
    HISTORY: '/history',
    MONITORING: '/monitoring/:id',
    RECOMMENDATIONS: '/recommendations',
    CATEGORIES: '/categories'
  };
  
  // 当前播放的直播流
  private currentStream: LiveStream | null = null;
  // 播放历史记录
  private watchHistory: Map<string, LiveStreamHistory> = new Map();
  // 收藏的直播流
  private favorites: Set<string> = new Set();
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('LiveStreamService initialized');
    this.initialize();
  }

  /**
   * 获取LiveStreamService单例实例
   */
  public static getInstance(): LiveStreamService {
    if (!LiveStreamService.instance) {
      LiveStreamService.instance = new LiveStreamService();
    }
    return LiveStreamService.instance;
  }

  /**
   * 初始化服务
   */
  private async initialize(): Promise<void> {
    try {
      // 加载收藏数据
      await this.loadFavorites();
      // 加载观看历史
      await this.loadWatchHistory();
      // 初始化事件监听
      this.setupEventListeners();
      
      this.logger.info('LiveStreamService initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize LiveStreamService', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听网络状态变化
    this.eventBus.on(GlobalEventType.NETWORK_STATUS_CHANGE, (status) => {
      this.handleNetworkStatusChange(status);
    });
    
    // 监听用户登录/登出
    this.eventBus.on(GlobalEventType.USER_LOGIN, () => {
      this.syncUserData();
    });
    
    this.eventBus.on(GlobalEventType.USER_LOGOUT, () => {
      this.clearUserData();
    });
  }

  /**
   * 获取直播流列表
   * @param params 请求参数
   */
  public async getLiveStreamList(params: LiveStreamListParams = {}): Promise<LiveStreamListResponse> {
    try {
      this.logger.debug('Getting live stream list with params:', params);
      
      // 构建缓存键
      const cacheKey = this.buildCacheKey('list', params);
      
      // 尝试从缓存获取
      const cachedResponse = await this.cacheService.get<LiveStreamListResponse>(cacheKey);
      if (cachedResponse) {
        this.logger.debug('Live stream list fetched from cache');
        return this.enrichLiveStreams(cachedResponse);
      }
      
      // 构建请求参数
      const requestParams = this.buildRequestParams(params);
      
      // 发送网络请求
      const response = await this.networkUtil.get<ApiResponse<LiveStreamListResponse>>(
        `${LiveStreamService.API_ENDPOINTS.BASE_URL}${LiveStreamService.API_ENDPOINTS.STREAMS}`,
        { params: requestParams }
      );
      
      if (response.success && response.data) {
        // 缓存结果
        await this.cacheService.set(cacheKey, response.data, {
          type: CacheType.MEMORY,
          ttl: 60000, // 1分钟缓存
          priority: CachePriority.HIGH
        });
        
        // 丰富直播流数据（添加收藏状态、历史记录等）
        const enrichedResponse = this.enrichLiveStreams(response.data);
        
        this.logger.info(`Retrieved ${response.data.streams.length} live streams`);
        return enrichedResponse;
      } else {
        throw new Error(response.message || 'Failed to get live stream list');
      }
    } catch (error) {
      this.logger.error('Error getting live stream list', error as Error);
      // 提供模拟数据作为后备
      return this.getMockLiveStreamList(params);
    }
  }

  /**
   * 获取直播流详情
   * @param streamId 直播流ID
   */
  public async getLiveStreamDetail(streamId: string): Promise<LiveStream> {
    try {
      this.logger.debug(`Getting live stream detail for ID: ${streamId}`);
      
      // 构建缓存键
      const cacheKey = `${LiveStreamService.CACHE_PREFIX}detail_${streamId}`;
      
      // 尝试从缓存获取
      const cachedStream = await this.cacheService.get<LiveStream>(cacheKey);
      if (cachedStream) {
        this.logger.debug('Live stream detail fetched from cache');
        return this.enrichLiveStream(cachedStream);
      }
      
      // 发送网络请求
      const endpoint = LiveStreamService.API_ENDPOINTS.DETAIL.replace(':id', streamId);
      const response = await this.networkUtil.get<ApiResponse<LiveStream>>(
        `${LiveStreamService.API_ENDPOINTS.BASE_URL}${endpoint}`
      );
      
      if (response.success && response.data) {
        // 缓存结果
        await this.cacheService.set(cacheKey, response.data, {
          type: CacheType.BOTH,
          ttl: 300000, // 5分钟缓存
          priority: CachePriority.HIGH
        });
        
        // 丰富直播流数据
        const enrichedStream = this.enrichLiveStream(response.data);
        
        this.logger.info(`Retrieved live stream detail for ID: ${streamId}`);
        return enrichedStream;
      } else {
        throw new Error(response.message || `Failed to get live stream detail for ID: ${streamId}`);
      }
    } catch (error) {
      this.logger.error(`Error getting live stream detail for ID: ${streamId}`, error as Error);
      // 提供模拟数据作为后备
      return this.getMockLiveStreamDetail(streamId);
    }
  }

  /**
   * 获取直播流统计数据
   */
  public async getLiveStreamStatistics(): Promise<LiveStreamStatistics> {
    try {
      this.logger.debug('Getting live stream statistics');
      
      // 构建缓存键
      const cacheKey = `${LiveStreamService.CACHE_PREFIX}statistics`;
      
      // 尝试从缓存获取
      const cachedStats = await this.cacheService.get<LiveStreamStatistics>(cacheKey);
      if (cachedStats) {
        this.logger.debug('Live stream statistics fetched from cache');
        return cachedStats;
      }
      
      // 发送网络请求
      const response = await this.networkUtil.get<ApiResponse<LiveStreamStatistics>>(
        `${LiveStreamService.API_ENDPOINTS.BASE_URL}${LiveStreamService.API_ENDPOINTS.STATISTICS}`
      );
      
      if (response.success && response.data) {
        // 缓存结果
        await this.cacheService.set(cacheKey, response.data, {
          type: CacheType.MEMORY,
          ttl: 120000, // 2分钟缓存
          priority: CachePriority.MEDIUM
        });
        
        this.logger.info('Retrieved live stream statistics');
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to get live stream statistics');
      }
    } catch (error) {
      this.logger.error('Error getting live stream statistics', error as Error);
      // 提供模拟数据作为后备
      return this.getMockLiveStreamStatistics();
    }
  }

  /**
   * 获取直播流分类列表
   */
  public async getLiveStreamCategories(): Promise<Array<{ id: string; name: string; count: number; icon?: string }>> {
    try {
      this.logger.debug('Getting live stream categories');
      
      // 构建缓存键
      const cacheKey = `${LiveStreamService.CACHE_PREFIX}categories`;
      
      // 尝试从缓存获取
      const cachedCategories = await this.cacheService.get<Array<{ id: string; name: string; count: number; icon?: string }>>(cacheKey);
      if (cachedCategories) {
        this.logger.debug('Live stream categories fetched from cache');
        return cachedCategories;
      }
      
      // 发送网络请求
      const response = await this.networkUtil.get<ApiResponse<Array<{ id: string; name: string; count: number; icon?: string }>>>(
        `${LiveStreamService.API_ENDPOINTS.BASE_URL}${LiveStreamService.API_ENDPOINTS.CATEGORIES}`
      );
      
      if (response.success && response.data) {
        // 缓存结果
        await this.cacheService.set(cacheKey, response.data, {
          type: CacheType.BOTH,
          ttl: 3600000, // 1小时缓存
          priority: CachePriority.LOW
        });
        
        this.logger.info(`Retrieved ${response.data.length} live stream categories`);
        return response.data;
      } else {
        throw new Error(response.message || 'Failed to get live stream categories');
      }
    } catch (error) {
      this.logger.error('Error getting live stream categories', error as Error);
      // 提供模拟数据作为后备
      return this.getMockLiveStreamCategories();
    }
  }

  /**
   * 获取推荐直播流
   * @param limit 限制数量
   */
  public async getRecommendedLiveStreams(limit: number = 10): Promise<LiveStream[]> {
    try {
      this.logger.debug(`Getting recommended live streams with limit: ${limit}`);
      
      // 构建缓存键
      const cacheKey = `${LiveStreamService.CACHE_PREFIX}recommendations_${limit}`;
      
      // 尝试从缓存获取
      const cachedRecommendations = await this.cacheService.get<LiveStream[]>(cacheKey);
      if (cachedRecommendations) {
        this.logger.debug('Recommended live streams fetched from cache');
        return cachedRecommendations.map(stream => this.enrichLiveStream(stream));
      }
      
      // 发送网络请求
      const response = await this.networkUtil.get<ApiResponse<LiveStream[]>>(
        `${LiveStreamService.API_ENDPOINTS.BASE_URL}${LiveStreamService.API_ENDPOINTS.RECOMMENDATIONS}`,
        { params: { limit } }
      );
      
      if (response.success && response.data) {
        // 缓存结果
        await this.cacheService.set(cacheKey, response.data, {
          type: CacheType.MEMORY,
          ttl: 300000, // 5分钟缓存
          priority: CachePriority.HIGH
        });
        
        // 丰富直播流数据
        const enrichedRecommendations = response.data.map(stream => this.enrichLiveStream(stream));
        
        this.logger.info(`Retrieved ${enrichedRecommendations.length} recommended live streams`);
        return enrichedRecommendations;
      } else {
        throw new Error(response.message || 'Failed to get recommended live streams');
      }
    } catch (error) {
      this.logger.error('Error getting recommended live streams', error as Error);
      // 提供模拟数据作为后备
      const mockList = await this.getMockLiveStreamList({ pageSize: limit });
      return mockList.streams;
    }
  }

  /**
   * 开始播放直播流
   * @param streamId 直播流ID
   * @param quality 播放质量
   */
  public async startPlayback(streamId: string, quality: LiveStreamQuality = LiveStreamQuality.HIGH): Promise<LiveStream> {
    try {
      this.logger.debug(`Starting playback for live stream ID: ${streamId}, quality: ${quality}`);
      
      // 获取直播流详情
      const stream = await this.getLiveStreamDetail(streamId);
      
      // 更新当前播放的直播流
      this.currentStream = stream;
      
      // 记录播放历史
      await this.updateWatchHistory(streamId, quality);
      
      // 发布播放开始事件
      this.eventBus.emit(GlobalEventType.PLAYER_PLAY, {
        streamId,
        stream,
        quality
      });
      
      this.logger.info(`Started playback for live stream ID: ${streamId}`);
      return stream;
    } catch (error) {
      this.logger.error(`Error starting playback for live stream ID: ${streamId}`, error as Error);
      
      // 发布播放错误事件
      this.eventBus.emit(GlobalEventType.PLAYER_ERROR, {
        streamId,
        error
      });
      
      throw error;
    }
  }

  /**
   * 停止播放直播流
   * @param streamId 直播流ID
   * @param watchDuration 观看时长（毫秒）
   */
  public async stopPlayback(streamId: string, watchDuration: number = 0): Promise<void> {
    try {
      this.logger.debug(`Stopping playback for live stream ID: ${streamId}`);
      
      // 更新观看时长
      if (this.watchHistory.has(streamId) && watchDuration > 0) {
        const history = this.watchHistory.get(streamId)!;
        history.watchDuration += watchDuration;
        await this.saveWatchHistory();
      }
      
      // 清除当前播放的直播流
      if (this.currentStream?.id === streamId) {
        this.currentStream = null;
      }
      
      // 发布播放停止事件
      this.eventBus.emit(GlobalEventType.PLAYER_STOP, {
        streamId,
        watchDuration
      });
      
      this.logger.info(`Stopped playback for live stream ID: ${streamId}`);
    } catch (error) {
      this.logger.error(`Error stopping playback for live stream ID: ${streamId}`, error as Error);
    }
  }

  /**
   * 添加收藏
   * @param streamId 直播流ID
   */
  public async addToFavorites(streamId: string): Promise<void> {
    try {
      this.logger.debug(`Adding live stream ID: ${streamId} to favorites`);
      
      // 添加到本地收藏集合
      this.favorites.add(streamId);
      
      // 保存到存储
      await this.saveFavorites();
      
      // 尝试同步到服务器
      try {
        await this.networkUtil.post(
          `${LiveStreamService.API_ENDPOINTS.BASE_URL}${LiveStreamService.API_ENDPOINTS.FAVORITES}`,
          { streamId }
        );
      } catch (error) {
        this.logger.warn('Failed to sync favorites with server', error as Error);
      }
      
      // 发布收藏添加事件
      this.eventBus.emit(GlobalEventType.FAVORITE_ADD, { streamId });
      
      // 清除相关缓存
      await this.invalidateStreamCache(streamId);
      
      this.logger.info(`Added live stream ID: ${streamId} to favorites`);
    } catch (error) {
      this.logger.error(`Error adding live stream ID: ${streamId} to favorites`, error as Error);
      throw error;
    }
  }

  /**
   * 移除收藏
   * @param streamId 直播流ID
   */
  public async removeFromFavorites(streamId: string): Promise<void> {
    try {
      this.logger.debug(`Removing live stream ID: ${streamId} from favorites`);
      
      // 从本地收藏集合移除
      this.favorites.delete(streamId);
      
      // 保存到存储
      await this.saveFavorites();
      
      // 尝试同步到服务器
      try {
        await this.networkUtil.delete(
          `${LiveStreamService.API_ENDPOINTS.BASE_URL}${LiveStreamService.API_ENDPOINTS.FAVORITES}/${streamId}`
        );
      } catch (error) {
        this.logger.warn('Failed to sync favorites with server', error as Error);
      }
      
      // 发布收藏移除事件
      this.eventBus.emit(GlobalEventType.FAVORITE_REMOVE, { streamId });
      
      // 清除相关缓存
      await this.invalidateStreamCache(streamId);
      
      this.logger.info(`Removed live stream ID: ${streamId} from favorites`);
    } catch (error) {
      this.logger.error(`Error removing live stream ID: ${streamId} from favorites`, error as Error);
      throw error;
    }
  }

  /**
   * 检查是否已收藏
   * @param streamId 直播流ID
   */
  public isFavorite(streamId: string): boolean {
    return this.favorites.has(streamId);
  }

  /**
   * 获取收藏的直播流列表
   */
  public async getFavoriteLiveStreams(): Promise<LiveStream[]> {
    try {
      this.logger.debug('Getting favorite live streams');
      
      const favoriteIds = Array.from(this.favorites);
      if (favoriteIds.length === 0) {
        return [];
      }
      
      const favoriteStreams: LiveStream[] = [];
      
      // 并行获取所有收藏的直播流详情
      await Promise.all(
        favoriteIds.map(async (streamId) => {
          try {
            const stream = await this.getLiveStreamDetail(streamId);
            favoriteStreams.push(stream);
          } catch (error) {
            this.logger.warn(`Failed to get favorite live stream ID: ${streamId}`, error as Error);
          }
        })
      );
      
      this.logger.info(`Retrieved ${favoriteStreams.length} favorite live streams`);
      return favoriteStreams;
    } catch (error) {
      this.logger.error('Error getting favorite live streams', error as Error);
      return [];
    }
  }

  /**
   * 获取观看历史记录
   * @param limit 限制数量
   */
  public async getWatchHistory(limit: number = 20): Promise<LiveStreamHistory[]> {
    try {
      this.logger.debug(`Getting watch history with limit: ${limit}`);
      
      // 转换为数组并按最后观看时间排序
      const historyArray = Array.from(this.watchHistory.values())
        .sort((a, b) => b.lastWatchedTime - a.lastWatchedTime)
        .slice(0, limit);
      
      this.logger.info(`Retrieved ${historyArray.length} watch history items`);
      return historyArray;
    } catch (error) {
      this.logger.error('Error getting watch history', error as Error);
      return [];
    }
  }

  /**
   * 清空观看历史记录
   */
  public async clearWatchHistory(): Promise<void> {
    try {
      this.logger.debug('Clearing watch history');
      
      // 清空本地历史记录
      this.watchHistory.clear();
      
      // 保存到存储
      await this.saveWatchHistory();
      
      // 发布历史记录清空事件
      this.eventBus.emit(GlobalEventType.HISTORY_CLEAR);
      
      this.logger.info('Cleared watch history');
    } catch (error) {
      this.logger.error('Error clearing watch history', error as Error);
      throw error;
    }
  }

  /**
   * 获取直播流监控数据
   * @param streamId 直播流ID
   */
  public async getLiveStreamMonitoring(streamId: string): Promise<LiveStreamMonitoring> {
    try {
      this.logger.debug(`Getting monitoring data for live stream ID: ${streamId}`);
      
      // 构建缓存键
      const cacheKey = `${LiveStreamService.CACHE_PREFIX}monitoring_${streamId}`;
      
      // 尝试从缓存获取（短暂缓存）
      const cachedMonitoring = await this.cacheService.get<LiveStreamMonitoring>(cacheKey);
      if (cachedMonitoring) {
        return cachedMonitoring;
      }
      
      // 发送网络请求
      const endpoint = LiveStreamService.API_ENDPOINTS.MONITORING.replace(':id', streamId);
      const response = await this.networkUtil.get<ApiResponse<LiveStreamMonitoring>>(
        `${LiveStreamService.API_ENDPOINTS.BASE_URL}${endpoint}`
      );
      
      if (response.success && response.data) {
        // 短暂缓存（5秒）
        await this.cacheService.set(cacheKey, response.data, {
          type: CacheType.MEMORY,
          ttl: 5000,
          priority: CachePriority.HIGH
        });
        
        return response.data;
      } else {
        throw new Error(response.message || `Failed to get monitoring data for live stream ID: ${streamId}`);
      }
    } catch (error) {
      this.logger.error(`Error getting monitoring data for live stream ID: ${streamId}`, error as Error);
      // 返回模拟监控数据
      return this.getMockLiveStreamMonitoring(streamId);
    }
  }

  /**
   * 获取当前播放的直播流
   */
  public getCurrentStream(): LiveStream | null {
    return this.currentStream;
  }

  /**
   * 刷新直播流列表缓存
   */
  public async refreshLiveStreamCache(): Promise<void> {
    try {
      this.logger.debug('Refreshing live stream cache');
      
      // 清除所有直播流相关缓存
      await this.cacheService.search({
        keyPattern: new RegExp(`^${LiveStreamService.CACHE_PREFIX}`)
      }).then(results => {
        return Promise.all(
          results.map(result => this.cacheService.remove(result.key))
        );
      });
      
      // 发布数据刷新事件
      this.eventBus.emit(GlobalEventType.DATA_REFRESH, { type: 'live_streams' });
      
      this.logger.info('Refreshed live stream cache');
    } catch (error) {
      this.logger.error('Error refreshing live stream cache', error as Error);
    }
  }

  // 私有辅助方法

  /**
   * 构建缓存键
   * @param prefix 前缀
   * @param params 参数
   */
  private buildCacheKey(prefix: string, params: Record<string, any>): string {
    const paramsStr = Object.keys(params)
      .sort()
      .map(key => `${key}=${params[key]}`)
      .join('_');
    return `${LiveStreamService.CACHE_PREFIX}${prefix}_${paramsStr}`;
  }

  /**
   * 构建请求参数
   * @param params 原始参数
   */
  private buildRequestParams(params: Record<string, any>): Record<string, any> {
    const requestParams: Record<string, any> = {};
    
    // 过滤掉undefined或null的参数
    Object.keys(params).forEach(key => {
      if (params[key] !== undefined && params[key] !== null) {
        requestParams[key] = params[key];
      }
    });
    
    return requestParams;
  }

  /**
   * 丰富直播流数据
   * @param stream 原始直播流数据
   */
  private enrichLiveStream(stream: LiveStream): LiveStream {
    return {
      ...stream,
      isFavorite: this.isFavorite(stream.id),
      lastWatchedTime: this.watchHistory.get(stream.id)?.lastWatchedTime
    };
  }

  /**
   * 丰富直播流列表数据
   * @param response 原始响应数据
   */
  private enrichLiveStreams(response: LiveStreamListResponse): LiveStreamListResponse {
    return {
      ...response,
      streams: response.streams.map(stream => this.enrichLiveStream(stream))
    };
  }

  /**
   * 使直播流缓存失效
   * @param streamId 直播流ID
   */
  private async invalidateStreamCache(streamId: string): Promise<void> {
    // 清除特定直播流的缓存
    await this.cacheService.remove(`${LiveStreamService.CACHE_PREFIX}detail_${streamId}`);
    // 清除列表缓存（可以根据需要实现更精细的缓存管理）
  }

  /**
   * 加载收藏数据
   */
  private async loadFavorites(): Promise<void> {
    try {
      const favorites = await this.storageUtil.get<string[]>('live_stream_favorites', LocalStorageType.PERSISTENT) || [];
      this.favorites = new Set(favorites);
      this.logger.info(`Loaded ${this.favorites.size} favorite live streams`);
    } catch (error) {
      this.logger.error('Failed to load favorites', error as Error);
      this.favorites = new Set();
    }
  }

  /**
   * 保存收藏数据
   */
  private async saveFavorites(): Promise<void> {
    try {
      const favoritesArray = Array.from(this.favorites);
      await this.storageUtil.set('live_stream_favorites', favoritesArray, LocalStorageType.PERSISTENT);
      this.logger.debug(`Saved ${favoritesArray.length} favorite live streams`);
    } catch (error) {
      this.logger.error('Failed to save favorites', error as Error);
    }
  }

  /**
   * 加载观看历史
   */
  private async loadWatchHistory(): Promise<void> {
    try {
      const history = await this.storageUtil.get<Record<string, LiveStreamHistory>>('live_stream_history', LocalStorageType.PERSISTENT) || {};
      this.watchHistory = new Map(Object.entries(history));
      this.logger.info(`Loaded ${this.watchHistory.size} watch history items`);
    } catch (error) {
      this.logger.error('Failed to load watch history', error as Error);
      this.watchHistory = new Map();
    }
  }

  /**
   * 保存观看历史
   */
  private async saveWatchHistory(): Promise<void> {
    try {
      const historyObj: Record<string, LiveStreamHistory> = {};
      this.watchHistory.forEach((value, key) => {
        historyObj[key] = value;
      });
      await this.storageUtil.set('live_stream_history', historyObj, LocalStorageType.PERSISTENT);
      this.logger.debug(`Saved ${this.watchHistory.size} watch history items`);
    } catch (error) {
      this.logger.error('Failed to save watch history', error as Error);
    }
  }

  /**
   * 更新观看历史
   * @param streamId 直播流ID
   * @param quality 播放质量
   */
  private async updateWatchHistory(streamId: string, quality: LiveStreamQuality): Promise<void> {
    const now = Date.now();
    const deviceInfo = this.getDeviceInfo();
    
    if (this.watchHistory.has(streamId)) {
      const history = this.watchHistory.get(streamId)!;
      history.lastWatchedTime = now;
      history.quality = quality;
      history.deviceInfo = deviceInfo;
    } else {
      this.watchHistory.set(streamId, {
        streamId,
        lastWatchedTime: now,
        watchDuration: 0,
        quality,
        deviceInfo
      });
    }
    
    // 限制历史记录数量
    this.limitWatchHistorySize();
    
    // 保存到存储
    await this.saveWatchHistory();
  }

  /**
   * 限制观看历史记录大小
   */
  private limitWatchHistorySize(maxSize: number = 100): void {
    if (this.watchHistory.size <= maxSize) {
      return;
    }
    
    // 按最后观看时间排序，保留最新的记录
    const sortedHistory = Array.from(this.watchHistory.entries())
      .sort((a, b) => b[1].lastWatchedTime - a[1].lastWatchedTime)
      .slice(0, maxSize);
    
    this.watchHistory = new Map(sortedHistory);
  }

  /**
   * 获取设备信息
   */
  private getDeviceInfo(): { name: string; type: string } {
    // 在实际应用中，这里应该获取真实的设备信息
    return {
      name: 'Unknown Device',
      type: 'tv'
    };
  }

  /**
   * 处理网络状态变化
   * @param status 网络状态
   */
  private handleNetworkStatusChange(status: any): void {
    this.logger.debug('Network status changed:', status);
    // 根据网络状态调整缓存策略等
  }

  /**
   * 同步用户数据
   */
  private async syncUserData(): Promise<void> {
    this.logger.debug('Syncing user data');
    // 同步收藏、观看历史等数据到服务器
  }

  /**
   * 清除用户数据
   */
  private clearUserData(): void {
    this.logger.debug('Clearing user data');
    // 清除用户相关数据
  }

  // 模拟数据生成方法

  /**
   * 获取模拟直播流列表
   */
  private getMockLiveStreamList(params: LiveStreamListParams): LiveStreamListResponse {
    const page = params.page || 1;
    const pageSize = params.pageSize || 20;
    const streams: LiveStream[] = [];
    
    for (let i = 0; i < pageSize; i++) {
      const index = (page - 1) * pageSize + i;
      streams.push({
        id: `mock_stream_${index + 1}`,
        title: `模拟直播 ${index + 1}`,
        description: `这是第 ${index + 1} 个模拟直播流的详细描述。`,
        coverUrl: `https://example.com/covers/stream_${index + 1}.jpg`,
        streamUrl: `https://example.com/streams/live_${index + 1}.m3u8`,
        hlsUrl: `https://example.com/streams/live_${index + 1}.m3u8`,
        startTime: Date.now() - 3600000,
        status: Math.random() > 0.2 ? LiveStreamStatus.ONLINE : LiveStreamStatus.OFFLINE,
        quality: LiveStreamQuality.HD,
        type: Object.values(LiveStreamType)[Math.floor(Math.random() * Object.values(LiveStreamType).length)],
        viewCount: Math.floor(Math.random() * 10000),
        likes: Math.floor(Math.random() * 5000),
        category: ['体育', '娱乐', '新闻', '游戏', '音乐'][Math.floor(Math.random() * 5)],
        tags: ['热门', '推荐', '精彩'][Math.floor(Math.random() * 3)].split(','),
        broadcaster: {
          id: `broadcaster_${Math.floor(Math.random() * 100)}`,
          name: `主播 ${Math.floor(Math.random() * 100)}`,
          avatarUrl: `https://example.com/avatars/${Math.floor(Math.random() * 100)}.jpg`,
          followers: Math.floor(Math.random() * 100000)
        },
        resolution: {
          width: 1920,
          height: 1080,
          frameRate: 30
        },
        statistics: {
          bandwidth: Math.floor(Math.random() * 1000),
          bufferHealth: Math.random() * 100,
          latency: Math.floor(Math.random() * 5000)
        },
        isFavorite: false
      });
    }
    
    return {
      streams: streams.map(stream => this.enrichLiveStream(stream)),
      total: 100,
      page,
      pageSize,
      hasMore: page * pageSize < 100
    };
  }

  /**
   * 获取模拟直播流详情
   */
  private getMockLiveStreamDetail(streamId: string): LiveStream {
    return this.enrichLiveStream({
      id: streamId,
      title: `模拟直播 ${streamId}`,
      description: `这是模拟直播流 ${streamId} 的详细描述。包含了直播的相关信息和内容简介。`,
      coverUrl: `https://example.com/covers/${streamId}.jpg`,
      streamUrl: `https://example.com/streams/${streamId}.m3u8`,
      hlsUrl: `https://example.com/streams/${streamId}.m3u8`,
      startTime: Date.now() - 7200000,
      status: LiveStreamStatus.ONLINE,
      quality: LiveStreamQuality.FHD,
      type: LiveStreamType.TV,
      viewCount: Math.floor(Math.random() * 20000),
      likes: Math.floor(Math.random() * 10000),
      category: '娱乐',
      tags: ['热门', '高清', '直播'],
      broadcaster: {
        id: 'broadcaster_1',
        name: '官方直播',
        avatarUrl: 'https://example.com/avatars/official.jpg',
        followers: 1000000
      },
      resolution: {
        width: 1920,
        height: 1080,
        frameRate: 60
      },
      statistics: {
        bandwidth: 500,
        bufferHealth: 95,
        latency: 2000
      },
      isFavorite: false
    });
  }

  /**
   * 获取模拟直播流统计数据
   */
  private getMockLiveStreamStatistics(): LiveStreamStatistics {
    return {
      totalStreams: 100,
      onlineStreams: 85,
      offlineStreams: 15,
      totalViewers: 125000,
      peakViewers: 150000,
      bandwidthUsage: 500000,
      topCategories: [
        { name: '娱乐', count: 35 },
        { name: '体育', count: 25 },
        { name: '游戏', count: 20 },
        { name: '新闻', count: 15 },
        { name: '音乐', count: 5 }
      ],
      topBroadcasters: [
        { id: 'b1', name: '主播1', streamCount: 10, viewerCount: 50000 },
        { id: 'b2', name: '主播2', streamCount: 8, viewerCount: 35000 },
        { id: 'b3', name: '主播3', streamCount: 12, viewerCount: 30000 }
      ],
      uptimePercentage: 99.5
    };
  }

  /**
   * 获取模拟直播流分类列表
   */
  private getMockLiveStreamCategories(): Array<{ id: string; name: string; count: number; icon?: string }> {
    return [
      { id: '1', name: '娱乐', count: 35, icon: '🎮' },
      { id: '2', name: '体育', count: 25, icon: '⚽' },
      { id: '3', name: '游戏', count: 20, icon: '🎮' },
      { id: '4', name: '新闻', count: 15, icon: '📰' },
      { id: '5', name: '音乐', count: 5, icon: '🎵' }
    ];
  }

  /**
   * 获取模拟直播流监控数据
   */
  private getMockLiveStreamMonitoring(streamId: string): LiveStreamMonitoring {
    return {
      streamId,
      timestamp: Date.now(),
      status: LiveStreamStatus.ONLINE,
      latency: 1500 + Math.random() * 3500,
      bufferLevel: 80 + Math.random() * 20,
      bitrate: 3000 + Math.random() * 2000,
      resolution: {
        width: 1920,
        height: 1080
      }
    };
  }
}

// 导出默认实例
export default LiveStreamService.getInstance();