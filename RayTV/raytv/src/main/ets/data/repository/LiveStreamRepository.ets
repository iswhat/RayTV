// LiveStreamRepository - 直播数据仓库�?// 负责管理直播流相关数据，包括直播列表、直播详情、关注、观看统计等

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import {
  VideoType,
  VideoQuality,
  VideoSource,
  VideoInfo
} from '../dto/VideoDto';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';
import { UserRepository } from './UserRepository';

/**
 * 直播状态枚�? */
export enum LiveStatus {
  OFFLINE = 'offline',
  LIVE = 'live',
  SCHEDULED = 'scheduled',
  ENDING = 'ending',
  ENDED = 'ended',
  ERROR = 'error'
}

/**
 * 直播类型枚举
 */
export enum LiveStreamType {
  GAME = 'game',
  ENTERTAINMENT = 'entertainment',
  EDUCATIONAL = 'educational',
  SPORTS = 'sports',
  NEWS = 'news',
  TALK = 'talk',
  OTHER = 'other'
}

/**
 * 直播流信息接�? */
export interface LiveStreamInfo extends VideoInfo {
  liveStatus: LiveStatus;
  streamType: LiveStreamType;
  streamUrl: string;
  hlsUrl: string;
  rtmpUrl?: string;
  viewerCount: number;
  peakViewers: number;
  startTime?: number;
  endTime?: number;
  scheduledStartTime?: number;
  streamKey?: string; // 仅对主播可见
  chatEnabled: boolean;
  isFollowing?: boolean;
  broadcasterInfo: {
    id: string;
    name: string;
    avatarUrl?: string;
    followerCount: number;
    isVerified: boolean;
  };
  donationEnabled: boolean;
  latestChats?: LiveChat[];
  liveTags: string[];
  isRestricted?: boolean;
  restrictionReason?: string;
}

/**
 * 直播聊天消息
 */
export interface LiveChat {
  id: string;
  userId: string;
  userName: string;
  userAvatar?: string;
  content: string;
  timestamp: number;
  isPinned?: boolean;
  isModerator?: boolean;
  isBroadcaster?: boolean;
  messageType: 'text' | 'emoji' | 'system' | 'donation' | 'subscription';
  metadata?: Record<string, unknown>;
}

/**
 * 直播列表请求参数
 */
export interface LiveStreamListRequest {
  status?: LiveStatus;
  type?: LiveStreamType;
  category?: string;
  tag?: string;
  page?: number;
  pageSize?: number;
  sortBy?: 'viewers' | 'newest' | 'trending' | 'following';
  featured?: boolean;
  searchQuery?: string;
}

/**
 * 直播列表响应
 */
export interface LiveStreamListResponse {
  streams: LiveStreamInfo[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

/**
 * 直播统计信息
 */
export interface LiveStreamStatistics {
  currentViewerCount: number;
  totalViewCount: number;
  followerCount: number;
  subscriptionCount: number;
  chatMessageCount: number;
  donationTotal: number;
  peakViewerCount: number;
  averageWatchTime: number;
  retentionRate: number;
}

/**
 * 直播公告
 */
export interface LiveAnnouncement {
  id: string;
  title: string;
  content: string;
  startTime: number;
  endTime?: number;
  isActive: boolean;
  priority: number;
}

/**
 * 直播事件类型
 */
export const LiveStreamEventType = {
  LIVE_STREAM_LOADED: 'livestream:loaded',
  LIVE_STREAM_LIST_LOADED: 'livestream:listLoaded',
  LIVE_STREAM_STATUS_CHANGED: 'livestream:statusChanged',
  LIVE_STREAM_FOLLOWED: 'livestream:followed',
  LIVE_STREAM_UNFOLLOWED: 'livestream:unfollowed',
  LIVE_CHAT_RECEIVED: 'livestream:chatReceived',
  LIVE_VIEWER_COUNT_UPDATED: 'livestream:viewerCountUpdated',
  LIVE_ERROR: 'livestream:error',
  LIVE_SCHEDULE_UPDATED: 'livestream:scheduleUpdated',
  FEATURED_LIVE_STREAMS_UPDATED: 'livestream:featuredUpdated'
} as const;

/**
 * 直播事件数据
 */
export interface LiveStreamEvent {
  streamId: string;
  type: string;
  timestamp: number;
  data?: Record<string, unknown>;
  error?: Error;
}

/**
 * 关注状态变更事件数�? */
export interface FollowChangeEvent extends LiveStreamEvent {
  followed: boolean;
  userId: string;
  broadcasterId: string;
}

/**
 * 直播聊天事件数据
 */
export interface ChatEvent extends LiveStreamEvent {
  chat: LiveChat;
}

/**
 * 直播数据仓库�? */
export class LiveStreamRepository {
  private static instance: LiveStreamRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  private userRepository = UserRepository.getInstance();
  
  // API端点配置
  private apiEndpoints = {
    baseUrl: 'https://api.raytv.example.com',
    liveStreams: '/live/streams',
    liveStreamDetail: '/live/streams/:id',
    liveStreamChat: '/live/streams/:id/chat',
    liveStreamStatistics: '/live/streams/:id/statistics',
    featuredStreams: '/live/featured',
    followedStreams: '/live/following',
    trendingStreams: '/live/trending',
    liveStreamFollow: '/live/streams/:id/follow',
    liveStreamCategories: '/live/categories',
    liveStreamAnnouncements: '/live/announcements'
  };
  
  // 存储和缓存键配置
  private storageKeys = {
    liveStreamCache: 'livestream:cache:',
    liveStreamListCache: 'livestream:list:',
    followedBroadcasters: 'livestream:followed',
    liveStreamChatCache: 'livestream:chat:',
    featuredStreams: 'livestream:featured',
    trendingStreams: 'livestream:trending',
    watchedStreams: 'livestream:watched'
  };
  
  // 直播配置
  private liveConfig = {
    liveStreamDetailCacheDuration: 60, // 直播详情缓存时间（秒�? 较短以保持实时�?    liveStreamListCacheDuration: 30, // 直播列表缓存时间（秒�?    liveChatCacheDuration: 3600, // 直播聊天缓存时间（秒�?    maxFollowedBroadcasters: 500, // 最大关注主播数
    viewerCountUpdateInterval: 5000, // 观看人数更新间隔（毫秒）
    chatMessageBatchSize: 50, // 聊天消息批量获取数量
    featuredStreamsCacheDuration: 300 // 精选直播缓存时间（秒）
  };
  
  // 当前活跃的直播观看会�?  private activeWatchSessions: Map<string, {
    startTime: number;
    lastHeartbeat: number;
  }> = new Map();

  /**
   * 私有构造函�?   */
  private constructor() {
    this.logger.info('LiveStreamRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取LiveStreamRepository单例实例
   */
  public static getInstance(): LiveStreamRepository {
    if (!LiveStreamRepository.instance) {
      LiveStreamRepository.instance = new LiveStreamRepository();
    }
    return LiveStreamRepository.instance;
  }

  /**
   * 初始化直播仓�?   */
  public async initialize(): Promise<void> {
    try {
      // 预加载精选直播（异步�?      this.loadFeaturedStreams().catch(err => {
        this.logger.warn('Failed to preload featured streams', err);
      });
      
      // 预加载热门直播（异步�?      this.loadTrendingStreams().catch(err => {
        this.logger.warn('Failed to preload trending streams', err);
      });
      
      // 启动心跳检�?      this.startHeartbeatCheck();
      
      this.logger.info('LiveStreamRepository initialization completed');
    } catch (error) {
      this.Logger.error('Failed to initialize LiveStreamRepository', error as Error);
    }
  }

  /**
   * 设置事件监听�?   */
  private setupEventListeners(): void {
    // 监听应用退出事件，清理观看会话
    this.eventBus.on('app:exit', async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ())))))) => {
      await this.cleanupWatchSessions();
    });
    
    // 监听网络状态变�?    this.eventBus.on('network:statusChanged', async (status?: { isOnline: boolean }) => {
      if (status?.isOnline) {
        // 在线时刷新精选和热门直播
        this.loadFeaturedStreams().catch(err => {
          this.logger.warn('Failed to refresh featured streams after network recovery', err);
        });
        this.loadTrendingStreams().catch(err => {
          this.logger.warn('Failed to refresh trending streams after network recovery', err);
        });
      }
    });
    
    // 监听用户登录状态变�?    this.eventBus.on('user:login', async () => {
      // 用户登录后加载关注的直播
      this.loadFollowedStreams().catch(err => {
        this.logger.warn('Failed to load followed streams after login', err);
      });
    });
    
    // 监听用户登出事件
    this.eventBus.on('user:logout', async () => {
      // 用户登出后清理关注的直播数据
      await this.clearFollowedStreams();
    });
  }

  /**
   * 启动心跳检�?   */
  private startHeartbeatCheck(): void {
    // �?0秒检查一次观看会话的心跳
    setInterval(() => {
      this.checkHeartbeats();
    }, 30000);
  }

  /**
   * 检查观看会话心�?   */
  private checkHeartbeats(): void {
    const now = Date.now();
    const timeoutThreshold = 60000; // 60秒超�?    
    for (const [streamId, session] of this.activeWatchSessions) {
      if (now - session.lastHeartbeat > timeoutThreshold) {
        // 心跳超时，清理会�?        this.activeWatchSessions.delete(streamId);
        this.logger.debug(`Watch session timeout for stream: ${streamId}`);
      }
    }
  }

  /**
   * 清理观看会话
   */
  private async cleanupWatchSessions(): Promise<void> {
    try {
      // 保存观看历史
      for (const [streamId, session] of this.activeWatchSessions) {
        await this.saveWatchHistory(streamId, session.startTime, Date.now());
      }
      
      // 清空活跃会话
      this.activeWatchSessions.clear();
      
      this.logger.info('Watch sessions cleaned up');
    } catch (error) {
      this.Logger.error('Failed to cleanup watch sessions', error as Error);
    }
  }

  /**
   * 保存观看历史
   */
  private async saveWatchHistory(streamId: string, startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number))))))): Promise<void> {
    try {
      const watchDuration = endTime - startTime;
      
      // 只保存观看时间超�?0秒的记录
      if (watchDuration < 30000) {
        return;
      }
      
      const watchHistory: Record<string, string | number | boolean | null> = { ... };
      
      // 保存到本地存�?      await this.storageUtil.setItem(
        LocalStorageType.WATCH_HISTORY,
        this.storageKeys.watchedStreams,
        watchHistory
      );
      
      this.logger.debug(`Watch history saved for stream: ${streamId}, duration: ${watchDuration}ms`);
    } catch (error) {
      this.Logger.error('Failed to save watch history', error as Error);
    }
  }

  /**
   * 获取直播列表
   */
  public async getLiveStreams(request: LiveStreamListRequest): Promise<LiveStreamListResponse> {
    try {
      // 生成缓存�?      const cacheKey = this.generateListCacheKey(request);
      
      // 尝试从缓存获�?      const cachedData = await this.cacheService.get<LiveStreamListResponse>(
        CacheType.LIVE_STREAM_LIST, cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
      )))))));
      
      if (cachedData && !this.isCacheExpired(cachedData.timestamp, this.liveConfig.liveStreamListCacheDuration)) {
        this.logger.debug('Live streams loaded from cache');
        return cachedData.data;
      }
      
      // 从API获取
      const response = await this.fetchLiveStreamsFromAPI(request);
      
      // 缓存结果
      await this.cacheService.set(
        CacheType.LIVE_STREAM_LIST,
        cacheKey,
        response,
        this.liveConfig.liveStreamListCacheDuration
      );
      
      // 发布事件
      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LIST_LOADED, {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now(),
        data: { request, response }
      });
      
      this.logger.info(`Live streams loaded: ${response.streams.length} streams`);
      
      return response;
    } catch (error) {
      this.Logger.error('Failed to get live streams', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 从API获取直播列表
   */
  private async fetchLiveStreamsFromAPI(request: LiveStreamListRequest): Promise<LiveStreamListResponse> {
    const params = new URLSearchParams();
    
    if (request.status) params.append('status', request.status);
    if (request.type) params.append('type', request.type);
    if (request.category) params.append('category', request.category);
    if (request.tag) params.append('tag', request.tag);
    if (request.page) params.append('page', request.page.toString());
    if (request.pageSize) params.append('pageSize', request.pageSize.toString());
    if (request.sortBy) params.append('sortBy', request.sortBy);
    if (request.featured !== undefined) params.append('featured', request.featured.toString());
    if (request.searchQuery) params.append('searchQuery', request.searchQuery);
    
    const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreams}?${params.toString()}`;
    
    const response = await this.networkUtil.get(url);
    
    if (!response.success) {
      throw new Error(`Failed to fetch live streams: ${response.error}`);
    }
    
    return response.data as LiveStreamListResponse;
  }

  /**
   * 生成列表缓存�?   */
  private generateListCacheKey(request: LiveStreamListRequest): string {
    const keyParts = [
      request.status || 'all',
      request.type || 'all',
      request.category || 'all',
      request.tag || 'all',
      request.page || 1,
      request.pageSize || 20,
      request.sortBy || 'viewers',
      request.featured || false,
      request.searchQuery || ''
    ];
    
    return `${this.storageKeys.liveStreamListCache}${keyParts.join(':')}`;
  }

  /**
   * 检查缓存是否过�?   */
  private isCacheExpired(timestamp: number, duration: number): boolean {
    return Date.now() - timestamp > duration * 1000;
  }

  /**
   * 获取直播详情
   */
  public async getLiveStreamDetail(streamId: string): Promise<LiveStreamInfo> {
    try {
      // 生成缓存�?      const cacheKey = `${this.storageKeys.liveStreamCache}${streamId}`;
      
      // 尝试从缓存获�?      const cachedData = await this.cacheService.get<LiveStreamInfo>(
        CacheType.LIVE_STREAM_DETAIL,
        cacheKey
      );
      
      if (cachedData && !this.isCacheExpired(cachedData.timestamp, this.liveConfig.liveStreamDetailCacheDuration)) {
        this.logger.debug(`Live stream detail loaded from cache: ${streamId}`);
        return cachedData.data;
      }
      
      // 从API获取
      const stream = await this.fetchLiveStreamDetailFromAPI(streamId);
      
      // 缓存结果
      await this.cacheService.set(
        CacheType.LIVE_STREAM_DETAIL,
        cacheKey,
        stream,
        this.liveConfig.liveStreamDetailCacheDuration
      );
      
      // 发布事件
      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LOADED, {
        type: LiveStreamEventType.LIVE_STREAM_LOADED,
        timestamp: Date.now(),
        data: { streamId, stream }
      });
      
      this.logger.info(`Live stream detail loaded: ${streamId}`);
      
      return stream;
    } catch (error) {
      this.Logger.error(`Failed to get live stream detail: ${streamId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 从API获取直播详情
   */
  private async fetchLiveStreamDetailFromAPI(streamId: string): Promise<LiveStreamInfo> {
    const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamDetail.replace(':id', streamId)}`;
    
    const response = await this.networkUtil.get(url);
    
    if (!response.success) {
      throw new Error(`Failed to fetch live stream detail: ${response.error}`);
    }
    
    return response.data as LiveStreamInfo;
  }

  /**
   * 关注/取消关注直播
   */
  public async followLiveStream(streamId: string, follow: boolean): Promise<void> {
    try {
      const user = this.userRepository.getCurrentUser();
      if (!user) {
        throw new Error('User not logged in');
      }
      
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamFollow.replace(':id', streamId)}`;
      
      const response = await this.networkUtil.post(url, { follow });
      
      if (!response.success) {
        throw new Error(`Failed to ${follow ? 'follow' : 'unfollow'} live stream: ${response.error}`);
      }
      
      // 更新本地关注状�?      await this.updateLocalFollowStatus(streamId, follow, user.id);
      
      // 发布事件
      this.eventBus.emit(follow ? LiveStreamEventType.LIVE_STREAM_FOLLOWED : LiveStreamEventType.LIVE_STREAM_UNFOLLOWED, {
        type: follow ? LiveStreamEventType.LIVE_STREAM_FOLLOWED : LiveStreamEventType.LIVE_STREAM_UNFOLLOWED,
        timestamp: Date.now(),
        data: {
          streamId,
          userId: user.id,
          followed: follow
        }
      });
      
      this.logger.info(`Live stream ${follow ? 'followed' : 'unfollowed'}: ${streamId}`);
    } catch (error) {
      this.Logger.error(`Failed to ${follow ? 'follow' : 'unfollow'} live stream: ${streamId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 更新本地关注状�?   */
  private async updateLocalFollowStatus(streamId: string, follow: boolean, userId: string): Promise<void> {
    try {
      // 获取当前关注的直播列�?      const followedStreams = await this.getFollowedStreams();
      
      if (follow) {
        // 添加关注
        if (!followedStreams.includes(streamId)) {
          followedStreams.push(streamId);
        }
      } else {
        // 取消关注
        const index = followedStreams.indexOf(streamId);
        if (index > -1) {
          followedStreams.splice(index, 1);
        }
      }
      
      // 保存到本地存�?      await this.storageUtil.setItem(
        LocalStorageType.FOLLOWED_STREAMS,
        this.storageKeys.followedBroadcasters,
        followedStreams
      );
      
      this.logger.debug(`Local follow status updated: ${streamId} -> ${follow}`);
    } catch (error) {
      this.Logger.error('Failed to update local follow status', error as Error);
      throw error;
    }
  }

  /**
   * 获取关注的直播列�?   */
  public async getFollowedStreams(): Promise<string[]> {
    try {
      const followedStreams = await this.storageUtil.getItem<string[]>(
        LocalStorageType.FOLLOWED_STREAMS, this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
      )))))));
      
      return followedStreams || [];
    } catch (error) {
      this.Logger.error('Failed to get followed streams', error as Error);
      return [];
    }
  }

  /**
   * 加载关注的直�?   */
  private async loadFollowedStreams(): Promise<void> {
    try {
      const followedStreams = await this.getFollowedStreams();
      
      // 发布事件
      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LIST_LOADED, {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now())))))),
        data: { followedStreams }
      });
      
      this.logger.info(`Followed streams loaded: ${followedStreams.length} streams`);
    } catch (error) {
      this.Logger.error('Failed to load followed streams', error as Error);
    }
  }

  /**
   * 清理关注的直播数�?   */
  private async clearFollowedStreams(): Promise<void> {
    try {
      await this.storageUtil.removeItem(
        LocalStorageType.FOLLOWED_STREAMS, this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
       instanceof Error ? this.storageKeys.followedBroadcasters
       : new Error(String(this.storageKeys.followedBroadcasters
      )))))));
      
      this.logger.info('Followed streams cleared');
    } catch (error) {
      this.Logger.error('Failed to clear followed streams', error as Error);
    }
  }

  /**
   * 加载精选直�?   */
  private async loadFeaturedStreams(): Promise<void> {
    try {
      const cacheKey = this.storageKeys.featuredStreams;
      
      // 尝试从缓存获�?      const cachedData = await this.cacheService.get<LiveStreamInfo[]>(
        CacheType.FEATURED_STREAMS, cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
       : new Error(String(cacheKey
       instanceof Error ? cacheKey
       : new Error(String(cacheKey
      )))))));
      
      if (cachedData && !this.isCacheExpired(cachedData.timestamp, this.liveConfig.featuredStreamsCacheDuration)) {
        this.logger.debug('Featured streams loaded from cache');
        return;
      }
      
      // 从API获取
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.featuredStreams}`;
      const response = await this.networkUtil.get(url);
      
      if (response.success) {
        const featuredStreams = response.data as LiveStreamInfo[];
        
        // 缓存结果
        await this.cacheService.set(
          CacheType.FEATURED_STREAMS,
          cacheKey,
          featuredStreams,
          this.liveConfig.featuredStreamsCacheDuration
        );
        
        // 发布事件
        this.eventBus.emit(LiveStreamEventType.FEATURED_LIVE_STREAMS_UPDATED, {
          type: LiveStreamEventType.FEATURED_LIVE_STREAMS_UPDATED,
          timestamp: Date.now(),
          data: { featuredStreams }
        });
        
        this.logger.info(`Featured streams loaded: ${featuredStreams.length} streams`);
      }
    } catch (error) {
      this.logger.warn('Failed to load featured streams', error as Error);
    }
  }

  /**
   * 加载热门直播
   */
  private async loadTrendingStreams(): Promise<void> {
    try {
      const cacheKey = this.storageKeys.trendingStreams;
      
      // 尝试从缓存获�?      const cachedData = await this.cacheService.get<LiveStreamInfo[]>(
        CacheType.TRENDING_STREAMS,
        cacheKey
      );
      
      if (cachedData && !this.isCacheExpired(cachedData.timestamp, this.liveConfig.featuredStreamsCacheDuration)) {
        this.logger.debug('Trending streams loaded from cache');
        return;
      }
      
      // 从API获取
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.trendingStreams}`;
      const response = await this.networkUtil.get(url);
      
      if (response.success) {
        const trendingStreams = response.data as LiveStreamInfo[];
        
        // 缓存结果
        await this.cacheService.set(
          CacheType.TRENDING_STREAMS,
          cacheKey,
          trendingStreams,
          this.liveConfig.featuredStreamsCacheDuration
        );
        
        // 发布事件
        this.eventBus.emit(LiveStreamEventType.FEATURED_LIVE_STREAMS_UPDATED, {
          type: LiveStreamEventType.FEATURED_LIVE_STREAMS_UPDATED,
          timestamp: Date.now(),
          data: { trendingStreams }
        });
        
        this.logger.info(`Trending streams loaded: ${trendingStreams.length} streams`);
      }
    } catch (error) {
      this.logger.warn('Failed to load trending streams', error as Error);
    }
  }

  /**
   * 获取直播聊天消息
   */
  public async getLiveChat(streamId: string, limit?: number): Promise<LiveChat[]> {
    try {
      const actualLimit = limit || this.liveConfig.chatMessageBatchSize;
      
      // 生成缓存�?      const cacheKey = `${this.storageKeys.liveStreamChatCache}${streamId}:${actualLimit}`;
      
      // 尝试从缓存获�?      const cachedData = await this.cacheService.get<LiveChat[]>(
        CacheType.LIVE_CHAT,
        cacheKey
      );
      
      if (cachedData && !this.isCacheExpired(cachedData.timestamp, this.liveConfig.liveChatCacheDuration)) {
        this.logger.debug(`Live chat loaded from cache: ${streamId}`);
        return cachedData.data;
      }
      
      // 从API获取
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamChat.replace(':id', streamId)}?limit=${actualLimit}`;
      const response = await this.networkUtil.get(url);
      
      if (!response.success) {
        throw new Error(`Failed to fetch live chat: ${response.error}`);
      }
      
      const chatMessages = response.data as LiveChat[];
      
      // 缓存结果
      await this.cacheService.set(
        CacheType.LIVE_CHAT,
        cacheKey,
        chatMessages,
        this.liveConfig.liveChatCacheDuration
      );
      
      // 发布事件
      this.eventBus.emit(LiveStreamEventType.LIVE_CHAT_RECEIVED, {
        type: LiveStreamEventType.LIVE_CHAT_RECEIVED,
        timestamp: Date.now(),
        data: { streamId, chatMessages }
      });
      
      this.logger.info(`Live chat loaded: ${streamId}, ${chatMessages.length} messages`);
      
      return chatMessages;
    } catch (error) {
      this.Logger.error(`Failed to get live chat: ${streamId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 发送聊天消�?   */
  public async sendChatMessage(streamId: string, message: string): Promise<void> {
    try {
      const user = this.userRepository.getCurrentUser();
      if (!user) {
        throw new Error('User not logged in');
      }
      
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamChat.replace(':id', streamId)}`;
      
      const response = await this.networkUtil.post(url, {
        message,
        userId: user.id,
        userName: user.name
      });
      
      if (!response.success) {
        throw new Error(`Failed to send chat message: ${response.error}`);
      }
      
      this.logger.info(`Chat message sent to stream: ${streamId}`);
    } catch (error) {
      this.Logger.error(`Failed to send chat message: ${streamId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 开始观看直�?   */
  public startWatching(streamId: string): void {
    const now = Date.now();
    this.activeWatchSessions.set(streamId, {
      startTime: now,
      lastHeartbeat: now
    });
    
    this.logger.debug(`Started watching stream: ${streamId}`);
  }

  /**
   * 更新观看心跳
   */
  public updateHeartbeat(streamId: string): void {
    const session = this.activeWatchSessions.get(streamId);
    if (session) {
      session.lastHeartbeat = Date.now();
      this.logger.debug(`Heartbeat updated for stream: ${streamId}`);
    }
  }

  /**
   * 停止观看直播
   */
  public async stopWatching(streamId: string): Promise<void> {
    const session = this.activeWatchSessions.get(streamId);
    if (session) {
      await this.saveWatchHistory(streamId, session.startTime, Date.now());
      this.activeWatchSessions.delete(streamId);
      this.logger.debug(`Stopped watching stream: ${streamId}`);
    }
  }

  /**
   * 获取直播统计信息
   */
  public async getLiveStreamStatistics(streamId: string): Promise<LiveStreamStatistics> {
    try {
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamStatistics.replace(':id', streamId)}`;
      
      const response = await this.networkUtil.get(url);
      
      if (!response.success) {
        throw new Error(`Failed to fetch live stream statistics: ${response.error}`);
      }
      
      return response.data as LiveStreamStatistics;
    } catch (error) {
      this.Logger.error(`Failed to get live stream statistics: ${streamId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 获取直播公告
   */
  public async getLiveAnnouncements(streamId: string): Promise<LiveAnnouncement[]> {
    try {
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamAnnouncements.replace(':id', streamId)}`;
      
      const response = await this.networkUtil.get(url);
      
      if (!response.success) {
        throw new Error(`Failed to fetch live announcements: ${response.error}`);
      }
      
      return response.data as LiveAnnouncement[];
    } catch (error) {
      this.Logger.error(`Failed to get live announcements: ${streamId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 搜索直播
   */
  public async searchLiveStreams(query: string, filters?: {
    type?: LiveStreamType;
    category?: string;
    status?: LiveStatus;
    featured?: boolean;
  }): Promise<LiveStreamInfo[]> {
    try {
      const params = new URLSearchParams();
      params.append('searchQuery', query);
      
      if (filters?.type) params.append('type', filters.type);
      if (filters?.category) params.append('category', filters.category);
      if (filters?.status) params.append('status', filters.status);
      if (filters?.featured !== undefined) params.append('featured', filters.featured.toString());
      
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreams}?${params.toString()}`;
      
      const response = await this.networkUtil.get(url);
      
      if (!response.success) {
        throw new Error(`Failed to search live streams: ${response.error}`);
      }
      
      const searchResult = response.data as LiveStreamListResponse;
      
      this.logger.info(`Live streams search completed: "${query}", ${searchResult.streams.length} results`);
      
      return searchResult.streams;
    } catch (error) {
      this.Logger.error(`Failed to search live streams: "${query}"`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 检查直播状�?   */
  public async checkLiveStreamStatus(streamId: string): Promise<LiveStatus> {
    try {
      const stream = await this.getLiveStreamDetail(streamId);
      
      // 发布状态更新事�?      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_STATUS_CHANGED, {
        type: LiveStreamEventType.LIVE_STREAM_STATUS_CHANGED,
        timestamp: Date.now(),
        data: { streamId, status: stream.liveStatus }
      });
      
      return stream.liveStatus;
    } catch (error) {
      this.Logger.error(`Failed to check live stream status: ${streamId}`, error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 获取直播分类
   */
  public async getLiveStreamCategories(): Promise<{ id: string; name: string; count: number }[]> {
    try {
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamCategories}`;
      
      const response = await this.networkUtil.get(url);
      
      if (!response.success) {
        throw new Error(`Failed to fetch live stream categories: ${response.error}`);
      }
      
      return response.data as { id: string; name: string; count: number }[];
    } catch (error) {
      this.Logger.error('Failed to get live stream categories', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 获取推荐的直�?   */
  public async getRecommendedLiveStreams(limit: number = 10): Promise<LiveStreamInfo[]> {
    try {
      // 基于用户观看历史和关注的主播推荐
      const user = this.userRepository.getCurrentUser();
      if (!user) {
        return [];
      }
      
      // 获取用户关注的直�?      const followedStreams = await this.getFollowedStreams();
      
      // 获取热门直播作为备�?      const trendingRequest: LiveStreamListRequest = {
        page: 1,
        pageSize: limit * 2,
        sortBy: 'trending'
      };
      
      const trendingResponse = await this.getLiveStreams(trendingRequest);
      
      // 优先推荐关注的直�?      const recommended: LiveStreamInfo[] = [];
      
      for (const streamId of followedStreams) {
        if (recommended.length >= limit) break;
        
        try {
          const stream = await this.getLiveStreamDetail(streamId);
          if (stream.liveStatus === LiveStatus.LIVE) {
            recommended.push(stream);
          }
        } catch (error) {
          // 忽略获取失败的直�?          this.logger.warn(`Failed to get recommended stream detail: ${streamId}`, error as Error);
        }
      }
      
      // 如果关注的不够，补充热门直播
      if (recommended.length < limit) {
        const remaining = limit - recommended.length;
        const trendingStreams = trendingResponse.streams.slice(0, remaining);
        recommended.push(...trendingStreams);
      }
      
      this.logger.info(`Recommended live streams loaded: ${recommended.length} streams`);
      
      return recommended;
    } catch (error) {
      this.Logger.error('Failed to get recommended live streams', error as Error);
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( instanceof Error ? {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now( : new Error(String({
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now())))))),
        error: error as Error
      });
      
      throw error;
    }
  }

  /**
   * 清理过期缓存
   */
  public async cleanupExpiredCache(): Promise<void> {
    try {
      await this.cacheService.cleanupExpired();
      this.logger.info('Live stream cache cleanup completed');
    } catch (error) {
      this.Logger.error('Failed to cleanup live stream cache', error as Error);
    }
  }

  /**
   * 关闭直播仓库
   */
  public async shutdown(): Promise<void> {
    try {
      // 清理观看会话
      await this.cleanupWatchSessions();
      
      // 清理缓存
      await this.cleanupExpiredCache();
      
      // 停止心跳检�?      // 注意：在ArkTS中，setInterval返回的timer需要手动清�?      // 这里需要根据实际实现来清理定时�?      
      this.logger.info('LiveStreamRepository shutdown');
    } catch (error) {
      this.logger.error('Failed to shutdown LiveStreamRepository', error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error)))))));
      
      // 发布错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
      
      throw error;
    }
  }
}



