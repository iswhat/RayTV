// LiveStreamRepository - 直播数据仓库类
// 负责管理直播流相关数据，包括直播列表、直播详情、关注、观看统计等

import Logger from '../../common/util/Logger';
import { StorageUtil } from '../../utils/StorageUtil';
import { NetworkUtil } from '../../utils/NetworkUtil';
import { EventBusUtil } from '../../utils/EventBusUtil';
import { CacheService } from '../../utils/CacheService';
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
 * 直播状态枚举
 */
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
 * 直播流信息接口
 */
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
  metadata?: any;
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
  data?: any;
  error?: Error;
}

/**
 * 关注状态变更事件数据
 */
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
 * 直播数据仓库类
 */
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
    liveStreamDetailCacheDuration: 60, // 直播详情缓存时间（秒）- 较短以保持实时性
    liveStreamListCacheDuration: 30, // 直播列表缓存时间（秒）
    liveChatCacheDuration: 3600, // 直播聊天缓存时间（秒）
    maxFollowedBroadcasters: 500, // 最大关注主播数
    viewerCountUpdateInterval: 5000, // 观看人数更新间隔（毫秒）
    chatMessageBatchSize: 50, // 聊天消息批量获取数量
    featuredStreamsCacheDuration: 300 // 精选直播缓存时间（秒）
  };
  
  // 当前活跃的直播观看会话
  private activeWatchSessions: Map<string, {
    startTime: number;
    lastHeartbeat: number;
  }> = new Map();

  /**
   * 私有构造函数
   */
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
   * 初始化直播仓库
   */
  private async initialize(): Promise<void> {
    try {
      // 预加载精选直播（异步）
      this.loadFeaturedStreams().catch(err => {
        this.logger.warn('Failed to preload featured streams', err);
      });
      
      // 预加载热门直播（异步）
      this.loadTrendingStreams().catch(err => {
        this.logger.warn('Failed to preload trending streams', err);
      });
      
      // 启动心跳检测
      this.startHeartbeatCheck();
      
      this.logger.info('LiveStreamRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize LiveStreamRepository', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用退出事件，清理观看会话
    this.eventBus.on('app:exit', async () => {
      await this.cleanupWatchSessions();
    });
    
    // 监听网络状态变化
    this.eventBus.on('network:statusChanged', async (status?: { isOnline: boolean }) => {
      if (status?.isOnline) {
        // 在线时刷新精选和热门直播
        await Promise.all([
          this.loadFeaturedStreams(),
          this.loadTrendingStreams()
        ]);
      }
    });
    
    // 监听用户登录/登出事件
    this.eventBus.on('user:login', async () => {
      // 登录后刷新关注的直播
      await this.loadFollowedStreams();
    });
    
    this.eventBus.on('user:logout', async () => {
      // 登出前清理观看会话
      await this.cleanupWatchSessions();
    });
  }

  /**
   * 获取直播详情
   * @param streamId 直播ID
   * @param forceRefresh 是否强制刷新
   */
  public async getLiveStreamDetail(streamId: string, forceRefresh: boolean = false): Promise<LiveStreamInfo> {
    try {
      const cacheKey = `${this.storageKeys.liveStreamCache}${streamId}`;
      
      // 尝试从缓存获取（如果不是强制刷新且直播正在进行中，可以使用缓存）
      if (!forceRefresh) {
        const cachedStream = await this.cacheService.get<LiveStreamInfo>(cacheKey);
        if (cachedStream && cachedStream.liveStatus === LiveStatus.LIVE) {
          this.logger.debug(`Live stream detail loaded from cache: ${streamId}`);
          
          // 发布直播加载事件
          this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LOADED, {
            streamId,
            type: LiveStreamEventType.LIVE_STREAM_LOADED,
            timestamp: Date.now(),
            data: cachedStream
          } as LiveStreamEvent);
          
          return cachedStream;
        }
      }
      
      // 构建请求URL
      const url = this.apiEndpoints.liveStreamDetail.replace(':id', streamId);
      
      // 构建请求配置
      const config: any = {};
      
      // 如果用户已登录，添加认证头
      const authToken = this.userRepository.getAuthToken();
      if (authToken) {
        config.headers = {
          'Authorization': `Bearer ${authToken}`
        };
      }
      
      // 调用API获取直播详情
      const response = await this.networkUtil.get<LiveStreamInfo>(
        `${this.apiEndpoints.baseUrl}${url}`,
        config
      );
      
      const streamInfo = response.data;
      
      // 缓存直播详情（正在进行的直播缓存时间较短）
      const cacheDuration = streamInfo.liveStatus === LiveStatus.LIVE ? 
        this.liveConfig.liveStreamDetailCacheDuration * 1000 : 
        3600000; // 1小时
      
      await this.cacheService.put(
        cacheKey,
        streamInfo,
        {
          type: CacheType.MEMORY,
          expiry: cacheDuration
        }
      );
      
      // 发布直播加载事件
      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LOADED, {
        streamId,
        type: LiveStreamEventType.LIVE_STREAM_LOADED,
        timestamp: Date.now(),
        data: streamInfo
      } as LiveStreamEvent);
      
      this.logger.info(`Live stream detail loaded: ${streamInfo.title} (${streamId}) - Status: ${streamInfo.liveStatus}`);
      
      return streamInfo;
    } catch (error) {
      this.logger.error(`Failed to get live stream detail for ${streamId}`, error as Error);
      
      // 发布直播错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        streamId,
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as LiveStreamEvent);
      
      throw error;
    }
  }

  /**
   * 获取直播列表
   * @param request 直播列表请求参数
   */
  public async getLiveStreamList(request: LiveStreamListRequest): Promise<LiveStreamListResponse> {
    try {
      // 验证请求参数
      this.validateLiveStreamListRequest(request);
      
      // 生成缓存键
      const cacheKey = this.generateLiveStreamListCacheKey(request);
      
      // 尝试从缓存获取
      const cachedList = await this.cacheService.get<LiveStreamListResponse>(cacheKey);
      if (cachedList) {
        this.logger.debug(`Live stream list loaded from cache`);
        
        // 发布直播列表加载事件
        this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LIST_LOADED, {
          type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
          timestamp: Date.now(),
          data: cachedList
        } as LiveStreamEvent);
        
        return cachedList;
      }
      
      // 构建请求参数
      const params = this.buildLiveStreamListParams(request);
      
      // 确定API端点
      let endpoint = this.apiEndpoints.liveStreams;
      if (request.sortBy === 'following' && this.userRepository.isLoggedIn()) {
        endpoint = this.apiEndpoints.followedStreams;
      } else if (request.featured) {
        endpoint = this.apiEndpoints.featuredStreams;
      }
      
      // 构建请求配置
      const config: any = {
        params
      };
      
      // 如果用户已登录，添加认证头
      const authToken = this.userRepository.getAuthToken();
      if (authToken) {
        config.headers = {
          'Authorization': `Bearer ${authToken}`
        };
      }
      
      // 调用API获取直播列表
      const response = await this.networkUtil.get<LiveStreamListResponse>(
        `${this.apiEndpoints.baseUrl}${endpoint}`,
        config
      );
      
      const streamList = response.data;
      
      // 缓存直播列表
      await this.cacheService.put(
        cacheKey,
        streamList,
        {
          type: CacheType.MEMORY,
          expiry: this.liveConfig.liveStreamListCacheDuration * 1000
        }
      );
      
      // 发布直播列表加载事件
      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LIST_LOADED, {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now(),
        data: streamList
      } as LiveStreamEvent);
      
      this.logger.info(`Live stream list loaded: ${streamList.streams.length} streams, page ${streamList.page}`);
      
      return streamList;
    } catch (error) {
      this.logger.error('Failed to get live stream list', error as Error);
      
      // 发布直播错误事件
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as LiveStreamEvent);
      
      throw error;
    }
  }

  /**
   * 获取精选直播
   */
  public async getFeaturedStreams(): Promise<LiveStreamInfo[]> {
    // 首先尝试从缓存获取
    const cached = await this.cacheService.get<LiveStreamInfo[]>(this.storageKeys.featuredStreams);
    if (cached) {
      return cached;
    }
    
    // 缓存未命中，加载新数据
    return this.loadFeaturedStreams();
  }

  /**
   * 加载精选直播
   */
  private async loadFeaturedStreams(): Promise<LiveStreamInfo[]> {
    try {
      const response = await this.networkUtil.get<LiveStreamInfo[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.featuredStreams}`,
        {
          params: {
            limit: 20
          }
        }
      );
      
      const featuredStreams = response.data;
      
      // 缓存精选直播
      await this.cacheService.put(
        this.storageKeys.featuredStreams,
        featuredStreams,
        {
          type: CacheType.MEMORY,
          expiry: this.liveConfig.featuredStreamsCacheDuration * 1000
        }
      );
      
      // 发布精选直播更新事件
      this.eventBus.emit(LiveStreamEventType.FEATURED_LIVE_STREAMS_UPDATED, {
        type: LiveStreamEventType.FEATURED_LIVE_STREAMS_UPDATED,
        timestamp: Date.now(),
        data: featuredStreams
      } as LiveStreamEvent);
      
      return featuredStreams;
    } catch (error) {
      this.logger.warn('Failed to load featured streams', error as Error);
      
      // 尝试从缓存获取旧数据
      return await this.cacheService.get<LiveStreamInfo[]>(this.storageKeys.featuredStreams) || [];
    }
  }

  /**
   * 获取热门直播
   */
  public async getTrendingStreams(): Promise<LiveStreamInfo[]> {
    // 首先尝试从缓存获取
    const cached = await this.cacheService.get<LiveStreamInfo[]>(this.storageKeys.trendingStreams);
    if (cached) {
      return cached;
    }
    
    // 缓存未命中，加载新数据
    return this.loadTrendingStreams();
  }

  /**
   * 加载热门直播
   */
  private async loadTrendingStreams(): Promise<LiveStreamInfo[]> {
    try {
      const response = await this.networkUtil.get<LiveStreamInfo[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.trendingStreams}`,
        {
          params: {
            limit: 30,
            period: 'day'
          }
        }
      );
      
      const trendingStreams = response.data;
      
      // 缓存热门直播
      await this.cacheService.put(
        this.storageKeys.trendingStreams,
        trendingStreams,
        {
          type: CacheType.MEMORY,
          expiry: this.liveConfig.liveStreamListCacheDuration * 1000
        }
      );
      
      return trendingStreams;
    } catch (error) {
      this.logger.warn('Failed to load trending streams', error as Error);
      
      // 尝试从缓存获取旧数据
      return await this.cacheService.get<LiveStreamInfo[]>(this.storageKeys.trendingStreams) || [];
    }
  }

  /**
   * 获取关注的直播
   */
  public async getFollowedStreams(): Promise<LiveStreamListResponse> {
    return this.loadFollowedStreams();
  }

  /**
   * 加载关注的直播
   */
  private async loadFollowedStreams(): Promise<LiveStreamListResponse> {
    try {
      if (!this.userRepository.isLoggedIn()) {
        return {
          streams: [],
          total: 0,
          page: 1,
          pageSize: 20,
          hasMore: false
        };
      }
      
      const response = await this.networkUtil.get<LiveStreamListResponse>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.followedStreams}`,
        {
          params: {
            page: 1,
            pageSize: 50
          },
          headers: {
            'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
          }
        }
      );
      
      return response.data;
    } catch (error) {
      this.logger.warn('Failed to load followed streams', error as Error);
      
      return {
        streams: [],
        total: 0,
        page: 1,
        pageSize: 20,
        hasMore: false
      };
    }
  }

  /**
   * 获取直播聊天消息
   * @param streamId 直播ID
   * @param beforeMessageId 可选的起始消息ID（用于分页）
   * @param limit 消息数量限制
   */
  public async getLiveChatMessages(
    streamId: string, 
    beforeMessageId?: string, 
    limit: number = 50
  ): Promise<LiveChat[]> {
    try {
      // 构建请求URL
      const url = this.apiEndpoints.liveStreamChat.replace(':id', streamId);
      
      // 构建请求参数
      const params: any = {
        limit: Math.min(limit, this.liveConfig.chatMessageBatchSize)
      };
      
      if (beforeMessageId) {
        params.before = beforeMessageId;
      }
      
      // 构建请求配置
      const config: any = {
        params
      };
      
      // 如果用户已登录，添加认证头
      const authToken = this.userRepository.getAuthToken();
      if (authToken) {
        config.headers = {
          'Authorization': `Bearer ${authToken}`
        };
      }
      
      // 调用API获取聊天消息
      const response = await this.networkUtil.get<LiveChat[]>(
        `${this.apiEndpoints.baseUrl}${url}`,
        config
      );
      
      return response.data;
    } catch (error) {
      this.logger.error(`Failed to get chat messages for stream ${streamId}`, error as Error);
      return [];
    }
  }

  /**
   * 发送直播聊天消息
   * @param streamId 直播ID
   * @param content 消息内容
   */
  public async sendLiveChatMessage(streamId: string, content: string): Promise<LiveChat> {
    try {
      // 检查用户是否已登录
      if (!this.userRepository.isLoggedIn()) {
        throw new Error('User not logged in');
      }
      
      // 验证消息内容
      if (!content || content.trim().length < 1) {
        throw new Error('Message content cannot be empty');
      }
      
      if (content.length > 500) {
        throw new Error('Message content too long (maximum 500 characters)');
      }
      
      // 构建请求URL
      const url = this.apiEndpoints.liveStreamChat.replace(':id', streamId);
      
      // 调用API发送聊天消息
      const response = await this.networkUtil.post<LiveChat>(
        `${this.apiEndpoints.baseUrl}${url}`,
        { content },
        {
          headers: {
            'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
          }
        }
      );
      
      const chatMessage = response.data;
      
      // 发布聊天接收事件
      this.eventBus.emit(LiveStreamEventType.LIVE_CHAT_RECEIVED, {
        streamId,
        type: LiveStreamEventType.LIVE_CHAT_RECEIVED,
        timestamp: Date.now(),
        chat: chatMessage
      } as ChatEvent);
      
      return chatMessage;
    } catch (error) {
      this.logger.error(`Failed to send chat message to stream ${streamId}`, error as Error);
      throw error;
    }
  }

  /**
   * 获取直播统计信息
   * @param streamId 直播ID
   */
  public async getLiveStreamStatistics(streamId: string): Promise<LiveStreamStatistics> {
    try {
      // 构建请求URL
      const url = this.apiEndpoints.liveStreamStatistics.replace(':id', streamId);
      
      // 调用API获取统计信息
      const response = await this.networkUtil.get<LiveStreamStatistics>(
        `${this.apiEndpoints.baseUrl}${url}`
      );
      
      return response.data;
    } catch (error) {
      this.logger.error(`Failed to get statistics for live stream ${streamId}`, error as Error);
      
      // 返回默认统计信息
      return {
        currentViewerCount: 0,
        totalViewCount: 0,
        followerCount: 0,
        subscriptionCount: 0,
        chatMessageCount: 0,
        donationTotal: 0,
        peakViewerCount: 0,
        averageWatchTime: 0,
        retentionRate: 0
      };
    }
  }

  /**
   * 关注/取消关注主播
   * @param broadcasterId 主播ID
   * @param follow 是否关注
   */
  public async followBroadcaster(broadcasterId: string, follow: boolean): Promise<boolean> {
    try {
      // 检查用户是否已登录
      if (!this.userRepository.isLoggedIn()) {
        throw new Error('User not logged in');
      }
      
      const userId = this.userRepository.getCurrentUser()?.id;
      if (!userId) {
        throw new Error('User ID not available');
      }
      
      try {
        // 调用API更新关注状态
        await this.networkUtil.post(
          `${this.apiEndpoints.baseUrl}/live/broadcasters/${broadcasterId}/follow`,
          { follow },
          {
            headers: {
              'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
            }
          }
        );
      } catch (error) {
        // API调用失败时，仍然更新本地状态
        this.logger.warn(`Failed to update follow status on server for broadcaster ${broadcasterId}`, error as Error);
      }
      
      // 更新本地关注状态
      const followed = await this.getFollowedBroadcasters();
      
      if (follow) {
        // 添加关注
        if (!followed.includes(broadcasterId)) {
          // 检查关注数量限制
          if (followed.length >= this.liveConfig.maxFollowedBroadcasters) {
            throw new Error(`Maximum number of followed broadcasters (${this.liveConfig.maxFollowedBroadcasters}) reached`);
          }
          followed.push(broadcasterId);
        }
      } else {
        // 取消关注
        const index = followed.indexOf(broadcasterId);
        if (index > -1) {
          followed.splice(index, 1);
        }
      }
      
      // 保存更新后的关注列表
      await this.storageUtil.setObject(this.storageKeys.followedBroadcasters, followed, LocalStorageType.DEFAULT);
      
      // 发布关注状态变更事件
      this.eventBus.emit(follow ? LiveStreamEventType.LIVE_STREAM_FOLLOWED : LiveStreamEventType.LIVE_STREAM_UNFOLLOWED, {
        streamId: broadcasterId,
        type: follow ? LiveStreamEventType.LIVE_STREAM_FOLLOWED : LiveStreamEventType.LIVE_STREAM_UNFOLLOWED,
        timestamp: Date.now(),
        followed,
        userId,
        broadcasterId
      } as FollowChangeEvent);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to ${follow ? 'follow' : 'unfollow'} broadcaster ${broadcasterId}`, error as Error);
      throw error;
    }
  }

  /**
   * 获取关注的主播列表
   */
  public async getFollowedBroadcasters(): Promise<string[]> {
    try {
      return await this.storageUtil.getObject<string[]>(this.storageKeys.followedBroadcasters, LocalStorageType.DEFAULT) || [];
    } catch (error) {
      this.logger.error('Failed to get followed broadcasters', error as Error);
      return [];
    }
  }

  /**
   * 检查是否关注了某个主播
   * @param broadcasterId 主播ID
   */
  public async isFollowingBroadcaster(broadcasterId: string): Promise<boolean> {
    try {
      const followed = await this.getFollowedBroadcasters();
      return followed.includes(broadcasterId);
    } catch (error) {
      this.logger.warn(`Failed to check follow status for broadcaster ${broadcasterId}`, error as Error);
      return false;
    }
  }

  /**
   * 开始观看直播会话
   * @param streamId 直播ID
   */
  public async startWatchSession(streamId: string): Promise<void> {
    try {
      // 记录观看会话开始
      this.activeWatchSessions.set(streamId, {
        startTime: Date.now(),
        lastHeartbeat: Date.now()
      });
      
      // 发送观看开始事件到服务器
      this.sendWatchHeartbeat(streamId, 'start').catch(err => {
        this.logger.warn(`Failed to send watch start heartbeat for stream ${streamId}`, err);
      });
      
      // 更新观看历史
      await this.addToWatchedStreams(streamId);
      
      this.logger.debug(`Started watching stream: ${streamId}`);
    } catch (error) {
      this.logger.warn(`Failed to start watch session for stream ${streamId}`, error as Error);
    }
  }

  /**
   * 结束观看直播会话
   * @param streamId 直播ID
   */
  public async endWatchSession(streamId: string): Promise<void> {
    try {
      const session = this.activeWatchSessions.get(streamId);
      if (session) {
        // 计算观看时长
        const watchDuration = Date.now() - session.startTime;
        
        // 发送观看结束事件到服务器
        this.sendWatchHeartbeat(streamId, 'end', watchDuration).catch(err => {
          this.logger.warn(`Failed to send watch end heartbeat for stream ${streamId}`, err);
        });
        
        // 移除活跃会话
        this.activeWatchSessions.delete(streamId);
        
        this.logger.debug(`Ended watching stream: ${streamId}, duration: ${watchDuration}ms`);
      }
    } catch (error) {
      this.logger.warn(`Failed to end watch session for stream ${streamId}`, error as Error);
    }
  }

  /**
   * 发送观看心跳包
   * @param streamId 直播ID
   * @param event 事件类型
   * @param duration 观看时长
   */
  private async sendWatchHeartbeat(streamId: string, event: 'start' | 'heartbeat' | 'end', duration?: number): Promise<void> {
    try {
      const data: any = {
        event,
        timestamp: Date.now()
      };
      
      if (duration !== undefined) {
        data.duration = duration;
      }
      
      // 构建请求配置
      const config: any = {};
      
      // 如果用户已登录，添加认证头
      const authToken = this.userRepository.getAuthToken();
      if (authToken) {
        config.headers = {
          'Authorization': `Bearer ${authToken}`
        };
      }
      
      // 发送心跳包
      await this.networkUtil.post(
        `${this.apiEndpoints.baseUrl}/live/streams/${streamId}/watch-heartbeat`,
        data,
        config
      );
    } catch (error) {
      // 心跳包发送失败不影响用户体验，仅记录日志
      this.logger.debug(`Failed to send watch heartbeat for stream ${streamId}`, error as Error);
    }
  }

  /**
   * 添加到已观看直播列表
   * @param streamId 直播ID
   */
  private async addToWatchedStreams(streamId: string): Promise<void> {
    try {
      let watched = await this.storageUtil.getObject<string[]>(this.storageKeys.watchedStreams, LocalStorageType.DEFAULT) || [];
      
      // 移除重复项
      watched = watched.filter(id => id !== streamId);
      
      // 添加到开头
      watched.unshift(streamId);
      
      // 限制数量（保留最近50个）
      watched = watched.slice(0, 50);
      
      // 保存
      await this.storageUtil.setObject(this.storageKeys.watchedStreams, watched, LocalStorageType.DEFAULT);
    } catch (error) {
      this.logger.warn(`Failed to add stream ${streamId} to watched list`, error as Error);
    }
  }

  /**
   * 获取已观看直播列表
   */
  public async getWatchedStreams(): Promise<string[]> {
    try {
      return await this.storageUtil.getObject<string[]>(this.storageKeys.watchedStreams, LocalStorageType.DEFAULT) || [];
    } catch (error) {
      this.logger.error('Failed to get watched streams', error as Error);
      return [];
    }
  }

  /**
   * 获取直播分类
   */
  public async getLiveStreamCategories(): Promise<Array<{
    id: string;
    name: string;
    iconUrl?: string;
    streamCount: number;
  }>> {
    try {
      const response = await this.networkUtil.get<Array<{
        id: string;
        name: string;
        iconUrl?: string;
        streamCount: number;
      }>>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamCategories}`
      );
      
      return response.data;
    } catch (error) {
      this.logger.error('Failed to get live stream categories', error as Error);
      return [];
    }
  }

  /**
   * 获取直播公告
   */
  public async getLiveAnnouncements(): Promise<LiveAnnouncement[]> {
    try {
      const response = await this.networkUtil.get<LiveAnnouncement[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamAnnouncements}`,
        {
          params: {
            active: true
          }
        }
      );
      
      return response.data.filter(announcement => announcement.isActive);
    } catch (error) {
      this.logger.error('Failed to get live announcements', error as Error);
      return [];
    }
  }

  /**
   * 启动心跳检测
   */
  private startHeartbeatCheck(): void {
    // 每30秒检查一次活跃会话，发送心跳包
    setInterval(() => {
      this.checkActiveSessions().catch(err => {
        this.logger.warn('Failed to check active sessions', err);
      });
    }, 30000);
  }

  /**
   * 检查活跃会话
   */
  private async checkActiveSessions(): Promise<void> {
    const now = Date.now();
    const inactiveThreshold = 60000; // 60秒不活动视为非活跃
    
    for (const [streamId, session] of this.activeWatchSessions.entries()) {
      // 检查会话是否活跃
      if (now - session.lastHeartbeat > inactiveThreshold) {
        // 会话不活跃，结束会话
        await this.endWatchSession(streamId);
      } else {
        // 会话活跃，发送心跳包
        this.sendWatchHeartbeat(streamId, 'heartbeat').catch(err => {
          this.logger.debug(`Failed to send heartbeat for session ${streamId}`, err);
        });
        
        // 更新最后心跳时间
        session.lastHeartbeat = now;
      }
    }
  }

  /**
   * 清理所有观看会话
   */
  private async cleanupWatchSessions(): Promise<void> {
    try {
      // 结束所有活跃会话
      const streamIds = Array.from(this.activeWatchSessions.keys());
      for (const streamId of streamIds) {
        await this.endWatchSession(streamId);
      }
    } catch (error) {
      this.logger.warn('Failed to cleanup watch sessions', error as Error);
    }
  }

  /**
   * 验证直播列表请求参数
   */
  private validateLiveStreamListRequest(request: LiveStreamListRequest): void {
    const errors: string[] = [];
    
    if (request.page && request.page < 1) {
      errors.push('Page number must be at least 1');
    }
    
    if (request.pageSize && (request.pageSize < 1 || request.pageSize > 100)) {
      errors.push('Page size must be between 1 and 100');
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 构建直播列表请求参数
   */
  private buildLiveStreamListParams(request: LiveStreamListRequest): any {
    const params: any = {
      page: request.page || 1,
      pageSize: request.pageSize || 20,
      sortBy: request.sortBy || 'viewers'
    };
    
    if (request.status) {
      params.status = request.status;
    }
    
    if (request.type) {
      params.type = request.type;
    }
    
    if (request.category) {
      params.category = request.category;
    }
    
    if (request.tag) {
      params.tag = request.tag;
    }
    
    if (request.searchQuery) {
      params.q = request.searchQuery;
    }
    
    return params;
  }

  /**
   * 生成直播列表缓存键
   */
  private generateLiveStreamListCacheKey(request: LiveStreamListRequest): string {
    return `livestream:list:${request.status || 'all'}:${request.type || ''}:${request.category || ''}:${request.tag || ''}:${request.page || 1}:${request.pageSize || 20}:${request.sortBy || 'viewers'}:${request.featured || false}:${request.searchQuery || ''}`;
  }

  /**
   * 清除直播缓存
   * @param streamId 可选的直播ID，如果不提供则清除所有缓存
   */
  public async clearLiveStreamCache(streamId?: string): Promise<void> {
    try {
      if (streamId) {
        // 清除特定直播的缓存
        const cacheKey = `${this.storageKeys.liveStreamCache}${streamId}`;
        await this.cacheService.remove(cacheKey);
        
        // 清除聊天缓存
        await this.cacheService.remove(`${this.storageKeys.liveStreamChatCache}${streamId}`);
      } else {
        // 清除所有直播列表缓存
        const pattern = `${this.storageKeys.liveStreamListCache}*`;
        await this.cacheService.removeByPattern(pattern);
        
        // 清除所有直播详情缓存
        const detailPattern = `${this.storageKeys.liveStreamCache}*`;
        await this.cacheService.removeByPattern(detailPattern);
        
        // 清除精选和热门直播缓存
        await this.cacheService.remove(this.storageKeys.featuredStreams);
        await this.cacheService.remove(this.storageKeys.trendingStreams);
      }
      
      this.logger.info(`${streamId ? `Cache cleared for live stream ${streamId}` : 'All live stream caches cleared'}`);
    } catch (error) {
      this.logger.error(`Failed to clear live stream cache${streamId ? ` for ${streamId}` : ''}`, error as Error);
      throw error;
    }
  }
}

// 导出默认实例
export default LiveStreamRepository.getInstance();