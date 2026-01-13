﻿// LiveStreamRepository - 鐩存挱鏁版嵁浠撳簱绫?// 璐熻矗绠＄悊鐩存挱娴佺浉鍏虫暟鎹紝鍖呮嫭鐩存挱鍒楄〃銆佺洿鎾鎯呫€佸叧娉ㄣ€佽鐪嬬粺璁＄瓑

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
 * 鐩存挱鐘舵€佹灇涓? */
export enum LiveStatus {
  OFFLINE = 'offline',
  LIVE = 'live',
  SCHEDULED = 'scheduled',
  ENDING = 'ending',
  ENDED = 'ended',
  ERROR = 'error'
}

/**
 * 鐩存挱绫诲瀷鏋氫妇
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
 * 鐩存挱娴佷俊鎭帴鍙? */
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
  streamKey?: string; // 浠呭涓绘挱鍙
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
 * 鐩存挱鑱婂ぉ娑堟伅
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
 * 鐩存挱鍒楄〃璇锋眰鍙傛暟
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
 * 鐩存挱鍒楄〃鍝嶅簲
 */
export interface LiveStreamListResponse {
  streams: LiveStreamInfo[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

/**
 * 鐩存挱缁熻淇℃伅
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
 * 鐩存挱鍏憡
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
 * 鐩存挱浜嬩欢绫诲瀷
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
 * 鐩存挱浜嬩欢鏁版嵁
 */
export interface LiveStreamEvent {
  streamId: string;
  type: string;
  timestamp: number;
  data?: Record<string, unknown>;
  error?: Error;
}

/**
 * 鍏虫敞鐘舵€佸彉鏇翠簨浠舵暟鎹? */
export interface FollowChangeEvent extends LiveStreamEvent {
  followed: boolean;
  userId: string;
  broadcasterId: string;
}

/**
 * 鐩存挱鑱婂ぉ浜嬩欢鏁版嵁
 */
export interface ChatEvent extends LiveStreamEvent {
  chat: LiveChat;
}

/**
 * 鐩存挱鏁版嵁浠撳簱绫? */
export class LiveStreamRepository {
  private static instance: LiveStreamRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  private userRepository = UserRepository.getInstance();
  
  // API绔偣閰嶇疆
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
  
  // 瀛樺偍鍜岀紦瀛橀敭閰嶇疆
  private storageKeys = {
    liveStreamCache: 'livestream:cache:',
    liveStreamListCache: 'livestream:list:',
    followedBroadcasters: 'livestream:followed',
    liveStreamChatCache: 'livestream:chat:',
    featuredStreams: 'livestream:featured',
    trendingStreams: 'livestream:trending',
    watchedStreams: 'livestream:watched'
  };
  
  // 鐩存挱閰嶇疆
  private liveConfig = {
    liveStreamDetailCacheDuration: 60, // 鐩存挱璇︽儏缂撳瓨鏃堕棿锛堢锛? 杈冪煭浠ヤ繚鎸佸疄鏃舵€?    liveStreamListCacheDuration: 30, // 鐩存挱鍒楄〃缂撳瓨鏃堕棿锛堢锛?    liveChatCacheDuration: 3600, // 鐩存挱鑱婂ぉ缂撳瓨鏃堕棿锛堢锛?    maxFollowedBroadcasters: 500, // 鏈€澶у叧娉ㄤ富鎾暟
    viewerCountUpdateInterval: 5000, // 瑙傜湅浜烘暟鏇存柊闂撮殧锛堟绉掞級
    chatMessageBatchSize: 50, // 鑱婂ぉ娑堟伅鎵归噺鑾峰彇鏁伴噺
    featuredStreamsCacheDuration: 300 // 绮鹃€夌洿鎾紦瀛樻椂闂达紙绉掞級
  };
  
  // 褰撳墠娲昏穬鐨勭洿鎾鐪嬩細璇?  private activeWatchSessions: Map<string, {
    startTime: number;
    lastHeartbeat: number;
  }> = new Map();

  /**
   * 绉佹湁鏋勯€犲嚱鏁?   */
  private constructor() {
    this.logger.info('LiveStreamRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 鑾峰彇LiveStreamRepository鍗曚緥瀹炰緥
   */
  public static getInstance(): LiveStreamRepository {
    if (!LiveStreamRepository.instance) {
      LiveStreamRepository.instance = new LiveStreamRepository();
    }
    return LiveStreamRepository.instance;
  }

  /**
   * 鍒濆鍖栫洿鎾粨搴?   */
  public async initialize(): Promise<void> {
    try {
      // 棰勫姞杞界簿閫夌洿鎾紙寮傛锛?      this.loadFeaturedStreams().catch(err => {
        this.logger.warn('Failed to preload featured streams', err);
      });
      
      // 棰勫姞杞界儹闂ㄧ洿鎾紙寮傛锛?      this.loadTrendingStreams().catch(err => {
        this.logger.warn('Failed to preload trending streams', err);
      });
      
      // 鍚姩蹇冭烦妫€娴?      this.startHeartbeatCheck();
      
      this.logger.info('LiveStreamRepository initialization completed');
    } catch (error) {
      this.Logger.error('Failed to initialize LiveStreamRepository', error as Error);
    }
  }

  /**
   * 璁剧疆浜嬩欢鐩戝惉鍣?   */
  private setupEventListeners(): void {
    // 鐩戝惉搴旂敤閫€鍑轰簨浠讹紝娓呯悊瑙傜湅浼氳瘽
    this.eventBus.on('app:exit', async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ( instanceof Error ? async ( instanceof Error ? async ( : new Error(String(async ( : new Error(String(async ( instanceof Error ? async ( : new Error(String(async ())))))) => {
      await this.cleanupWatchSessions();
    });
    
    // 鐩戝惉缃戠粶鐘舵€佸彉鍖?    this.eventBus.on('network:statusChanged', async (status?: { isOnline: boolean }) => {
      if (status?.isOnline) {
        // 鍦ㄧ嚎鏃跺埛鏂扮簿閫夊拰鐑棬鐩存挱
        this.loadFeaturedStreams().catch(err => {
          this.logger.warn('Failed to refresh featured streams after network recovery', err);
        });
        this.loadTrendingStreams().catch(err => {
          this.logger.warn('Failed to refresh trending streams after network recovery', err);
        });
      }
    });
    
    // 鐩戝惉鐢ㄦ埛鐧诲綍鐘舵€佸彉鍖?    this.eventBus.on('user:login', async () => {
      // 鐢ㄦ埛鐧诲綍鍚庡姞杞藉叧娉ㄧ殑鐩存挱
      this.loadFollowedStreams().catch(err => {
        this.logger.warn('Failed to load followed streams after login', err);
      });
    });
    
    // 鐩戝惉鐢ㄦ埛鐧诲嚭浜嬩欢
    this.eventBus.on('user:logout', async () => {
      // 鐢ㄦ埛鐧诲嚭鍚庢竻鐞嗗叧娉ㄧ殑鐩存挱鏁版嵁
      await this.clearFollowedStreams();
    });
  }

  /**
   * 鍚姩蹇冭烦妫€娴?   */
  private startHeartbeatCheck(): void {
    // 姣?0绉掓鏌ヤ竴娆¤鐪嬩細璇濈殑蹇冭烦
    setInterval(() => {
      this.checkHeartbeats();
    }, 30000);
  }

  /**
   * 妫€鏌ヨ鐪嬩細璇濆績璺?   */
  private checkHeartbeats(): void {
    const now = Date.now();
    const timeoutThreshold = 60000; // 60绉掕秴鏃?    
    for (const [streamId, session] of this.activeWatchSessions) {
      if (now - session.lastHeartbeat > timeoutThreshold) {
        // 蹇冭烦瓒呮椂锛屾竻鐞嗕細璇?        this.activeWatchSessions.delete(streamId);
        this.logger.debug(`Watch session timeout for stream: ${streamId}`);
      }
    }
  }

  /**
   * 娓呯悊瑙傜湅浼氳瘽
   */
  private async cleanupWatchSessions(): Promise<void> {
    try {
      // 淇濆瓨瑙傜湅鍘嗗彶
      for (const [streamId, session] of this.activeWatchSessions) {
        await this.saveWatchHistory(streamId, session.startTime, Date.now());
      }
      
      // 娓呯┖娲昏穬浼氳瘽
      this.activeWatchSessions.clear();
      
      this.logger.info('Watch sessions cleaned up');
    } catch (error) {
      this.Logger.error('Failed to cleanup watch sessions', error as Error);
    }
  }

  /**
   * 淇濆瓨瑙傜湅鍘嗗彶
   */
  private async saveWatchHistory(streamId: string, startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number : new Error(String(startTime: number, endTime: number instanceof Error ? startTime: number, endTime: number : new Error(String(startTime: number, endTime: number))))))): Promise<void> {
    try {
      const watchDuration = endTime - startTime;
      
      // 鍙繚瀛樿鐪嬫椂闂磋秴杩?0绉掔殑璁板綍
      if (watchDuration < 30000) {
        return;
      }
      
      const watchHistory: Record<string, string | number | boolean | null> = { ... };
      
      // 淇濆瓨鍒版湰鍦板瓨鍌?      await this.storageUtil.setItem(
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
   * 鑾峰彇鐩存挱鍒楄〃
   */
  public async getLiveStreams(request: LiveStreamListRequest): Promise<LiveStreamListResponse> {
    try {
      // 鐢熸垚缂撳瓨閿?      const cacheKey = this.generateListCacheKey(request);
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.cacheService.get<LiveStreamListResponse>(
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
      
      // 浠嶢PI鑾峰彇
      const response = await this.fetchLiveStreamsFromAPI(request);
      
      // 缂撳瓨缁撴灉
      await this.cacheService.set(
        CacheType.LIVE_STREAM_LIST,
        cacheKey,
        response,
        this.liveConfig.liveStreamListCacheDuration
      );
      
      // 鍙戝竷浜嬩欢
      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LIST_LOADED, {
        type: LiveStreamEventType.LIVE_STREAM_LIST_LOADED,
        timestamp: Date.now(),
        data: { request, response }
      });
      
      this.logger.info(`Live streams loaded: ${response.streams.length} streams`);
      
      return response;
    } catch (error) {
      this.Logger.error('Failed to get live streams', error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 浠嶢PI鑾峰彇鐩存挱鍒楄〃
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
   * 鐢熸垚鍒楄〃缂撳瓨閿?   */
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
   * 妫€鏌ョ紦瀛樻槸鍚﹁繃鏈?   */
  private isCacheExpired(timestamp: number, duration: number): boolean {
    return Date.now() - timestamp > duration * 1000;
  }

  /**
   * 鑾峰彇鐩存挱璇︽儏
   */
  public async getLiveStreamDetail(streamId: string): Promise<LiveStreamInfo> {
    try {
      // 鐢熸垚缂撳瓨閿?      const cacheKey = `${this.storageKeys.liveStreamCache}${streamId}`;
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.cacheService.get<LiveStreamInfo>(
        CacheType.LIVE_STREAM_DETAIL,
        cacheKey
      );
      
      if (cachedData && !this.isCacheExpired(cachedData.timestamp, this.liveConfig.liveStreamDetailCacheDuration)) {
        this.logger.debug(`Live stream detail loaded from cache: ${streamId}`);
        return cachedData.data;
      }
      
      // 浠嶢PI鑾峰彇
      const stream = await this.fetchLiveStreamDetailFromAPI(streamId);
      
      // 缂撳瓨缁撴灉
      await this.cacheService.set(
        CacheType.LIVE_STREAM_DETAIL,
        cacheKey,
        stream,
        this.liveConfig.liveStreamDetailCacheDuration
      );
      
      // 鍙戝竷浜嬩欢
      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_LOADED, {
        type: LiveStreamEventType.LIVE_STREAM_LOADED,
        timestamp: Date.now(),
        data: { streamId, stream }
      });
      
      this.logger.info(`Live stream detail loaded: ${streamId}`);
      
      return stream;
    } catch (error) {
      this.Logger.error(`Failed to get live stream detail: ${streamId}`, error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 浠嶢PI鑾峰彇鐩存挱璇︽儏
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
   * 鍏虫敞/鍙栨秷鍏虫敞鐩存挱
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
      
      // 鏇存柊鏈湴鍏虫敞鐘舵€?      await this.updateLocalFollowStatus(streamId, follow, user.id);
      
      // 鍙戝竷浜嬩欢
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
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 鏇存柊鏈湴鍏虫敞鐘舵€?   */
  private async updateLocalFollowStatus(streamId: string, follow: boolean, userId: string): Promise<void> {
    try {
      // 鑾峰彇褰撳墠鍏虫敞鐨勭洿鎾垪琛?      const followedStreams = await this.getFollowedStreams();
      
      if (follow) {
        // 娣诲姞鍏虫敞
        if (!followedStreams.includes(streamId)) {
          followedStreams.push(streamId);
        }
      } else {
        // 鍙栨秷鍏虫敞
        const index = followedStreams.indexOf(streamId);
        if (index > -1) {
          followedStreams.splice(index, 1);
        }
      }
      
      // 淇濆瓨鍒版湰鍦板瓨鍌?      await this.storageUtil.setItem(
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
   * 鑾峰彇鍏虫敞鐨勭洿鎾垪琛?   */
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
   * 鍔犺浇鍏虫敞鐨勭洿鎾?   */
  private async loadFollowedStreams(): Promise<void> {
    try {
      const followedStreams = await this.getFollowedStreams();
      
      // 鍙戝竷浜嬩欢
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
   * 娓呯悊鍏虫敞鐨勭洿鎾暟鎹?   */
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
   * 鍔犺浇绮鹃€夌洿鎾?   */
  private async loadFeaturedStreams(): Promise<void> {
    try {
      const cacheKey = this.storageKeys.featuredStreams;
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.cacheService.get<LiveStreamInfo[]>(
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
      
      // 浠嶢PI鑾峰彇
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.featuredStreams}`;
      const response = await this.networkUtil.get(url);
      
      if (response.success) {
        const featuredStreams = response.data as LiveStreamInfo[];
        
        // 缂撳瓨缁撴灉
        await this.cacheService.set(
          CacheType.FEATURED_STREAMS,
          cacheKey,
          featuredStreams,
          this.liveConfig.featuredStreamsCacheDuration
        );
        
        // 鍙戝竷浜嬩欢
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
   * 鍔犺浇鐑棬鐩存挱
   */
  private async loadTrendingStreams(): Promise<void> {
    try {
      const cacheKey = this.storageKeys.trendingStreams;
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.cacheService.get<LiveStreamInfo[]>(
        CacheType.TRENDING_STREAMS,
        cacheKey
      );
      
      if (cachedData && !this.isCacheExpired(cachedData.timestamp, this.liveConfig.featuredStreamsCacheDuration)) {
        this.logger.debug('Trending streams loaded from cache');
        return;
      }
      
      // 浠嶢PI鑾峰彇
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.trendingStreams}`;
      const response = await this.networkUtil.get(url);
      
      if (response.success) {
        const trendingStreams = response.data as LiveStreamInfo[];
        
        // 缂撳瓨缁撴灉
        await this.cacheService.set(
          CacheType.TRENDING_STREAMS,
          cacheKey,
          trendingStreams,
          this.liveConfig.featuredStreamsCacheDuration
        );
        
        // 鍙戝竷浜嬩欢
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
   * 鑾峰彇鐩存挱鑱婂ぉ娑堟伅
   */
  public async getLiveChat(streamId: string, limit?: number): Promise<LiveChat[]> {
    try {
      const actualLimit = limit || this.liveConfig.chatMessageBatchSize;
      
      // 鐢熸垚缂撳瓨閿?      const cacheKey = `${this.storageKeys.liveStreamChatCache}${streamId}:${actualLimit}`;
      
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedData = await this.cacheService.get<LiveChat[]>(
        CacheType.LIVE_CHAT,
        cacheKey
      );
      
      if (cachedData && !this.isCacheExpired(cachedData.timestamp, this.liveConfig.liveChatCacheDuration)) {
        this.logger.debug(`Live chat loaded from cache: ${streamId}`);
        return cachedData.data;
      }
      
      // 浠嶢PI鑾峰彇
      const url = `${this.apiEndpoints.baseUrl}${this.apiEndpoints.liveStreamChat.replace(':id', streamId)}?limit=${actualLimit}`;
      const response = await this.networkUtil.get(url);
      
      if (!response.success) {
        throw new Error(`Failed to fetch live chat: ${response.error}`);
      }
      
      const chatMessages = response.data as LiveChat[];
      
      // 缂撳瓨缁撴灉
      await this.cacheService.set(
        CacheType.LIVE_CHAT,
        cacheKey,
        chatMessages,
        this.liveConfig.liveChatCacheDuration
      );
      
      // 鍙戝竷浜嬩欢
      this.eventBus.emit(LiveStreamEventType.LIVE_CHAT_RECEIVED, {
        type: LiveStreamEventType.LIVE_CHAT_RECEIVED,
        timestamp: Date.now(),
        data: { streamId, chatMessages }
      });
      
      this.logger.info(`Live chat loaded: ${streamId}, ${chatMessages.length} messages`);
      
      return chatMessages;
    } catch (error) {
      this.Logger.error(`Failed to get live chat: ${streamId}`, error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 鍙戦€佽亰澶╂秷鎭?   */
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
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 寮€濮嬭鐪嬬洿鎾?   */
  public startWatching(streamId: string): void {
    const now = Date.now();
    this.activeWatchSessions.set(streamId, {
      startTime: now,
      lastHeartbeat: now
    });
    
    this.logger.debug(`Started watching stream: ${streamId}`);
  }

  /**
   * 鏇存柊瑙傜湅蹇冭烦
   */
  public updateHeartbeat(streamId: string): void {
    const session = this.activeWatchSessions.get(streamId);
    if (session) {
      session.lastHeartbeat = Date.now();
      this.logger.debug(`Heartbeat updated for stream: ${streamId}`);
    }
  }

  /**
   * 鍋滄瑙傜湅鐩存挱
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
   * 鑾峰彇鐩存挱缁熻淇℃伅
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
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 鑾峰彇鐩存挱鍏憡
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
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 鎼滅储鐩存挱
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
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 妫€鏌ョ洿鎾姸鎬?   */
  public async checkLiveStreamStatus(streamId: string): Promise<LiveStatus> {
    try {
      const stream = await this.getLiveStreamDetail(streamId);
      
      // 鍙戝竷鐘舵€佹洿鏂颁簨浠?      this.eventBus.emit(LiveStreamEventType.LIVE_STREAM_STATUS_CHANGED, {
        type: LiveStreamEventType.LIVE_STREAM_STATUS_CHANGED,
        timestamp: Date.now(),
        data: { streamId, status: stream.liveStatus }
      });
      
      return stream.liveStatus;
    } catch (error) {
      this.Logger.error(`Failed to check live stream status: ${streamId}`, error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 鑾峰彇鐩存挱鍒嗙被
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
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 鑾峰彇鎺ㄨ崘鐨勭洿鎾?   */
  public async getRecommendedLiveStreams(limit: number = 10): Promise<LiveStreamInfo[]> {
    try {
      // 鍩轰簬鐢ㄦ埛瑙傜湅鍘嗗彶鍜屽叧娉ㄧ殑涓绘挱鎺ㄨ崘
      const user = this.userRepository.getCurrentUser();
      if (!user) {
        return [];
      }
      
      // 鑾峰彇鐢ㄦ埛鍏虫敞鐨勭洿鎾?      const followedStreams = await this.getFollowedStreams();
      
      // 鑾峰彇鐑棬鐩存挱浣滀负澶囬€?      const trendingRequest: LiveStreamListRequest = {
        page: 1,
        pageSize: limit * 2,
        sortBy: 'trending'
      };
      
      const trendingResponse = await this.getLiveStreams(trendingRequest);
      
      // 浼樺厛鎺ㄨ崘鍏虫敞鐨勭洿鎾?      const recommended: LiveStreamInfo[] = [];
      
      for (const streamId of followedStreams) {
        if (recommended.length >= limit) break;
        
        try {
          const stream = await this.getLiveStreamDetail(streamId);
          if (stream.liveStatus === LiveStatus.LIVE) {
            recommended.push(stream);
          }
        } catch (error) {
          // 蹇界暐鑾峰彇澶辫触鐨勭洿鎾?          this.logger.warn(`Failed to get recommended stream detail: ${streamId}`, error as Error);
        }
      }
      
      // 濡傛灉鍏虫敞鐨勪笉澶燂紝琛ュ厖鐑棬鐩存挱
      if (recommended.length < limit) {
        const remaining = limit - recommended.length;
        const trendingStreams = trendingResponse.streams.slice(0, remaining);
        recommended.push(...trendingStreams);
      }
      
      this.logger.info(`Recommended live streams loaded: ${recommended.length} streams`);
      
      return recommended;
    } catch (error) {
      this.Logger.error('Failed to get recommended live streams', error as Error);
      
      // 鍙戝竷閿欒浜嬩欢
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
   * 娓呯悊杩囨湡缂撳瓨
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
   * 鍏抽棴鐩存挱浠撳簱
   */
  public async shutdown(): Promise<void> {
    try {
      // 娓呯悊瑙傜湅浼氳瘽
      await this.cleanupWatchSessions();
      
      // 娓呯悊缂撳瓨
      await this.cleanupExpiredCache();
      
      // 鍋滄蹇冭烦妫€娴?      // 娉ㄦ剰锛氬湪ArkTS涓紝setInterval杩斿洖鐨則imer闇€瑕佹墜鍔ㄦ竻鐞?      // 杩欓噷闇€瑕佹牴鎹疄闄呭疄鐜版潵娓呯悊瀹氭椂鍣?      
      this.logger.info('LiveStreamRepository shutdown');
    } catch (error) {
      this.logger.error('Failed to shutdown LiveStreamRepository', error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error instanceof Error ? error as Error instanceof Error ? error as Error : new Error(String(error as Error : new Error(String(error as Error instanceof Error ? error as Error : new Error(String(error as Error)))))));
      
      // 鍙戝竷閿欒浜嬩欢
      this.eventBus.emit(LiveStreamEventType.LIVE_ERROR, {
        type: LiveStreamEventType.LIVE_ERROR,
        timestamp: Date.now(),
        error: error as Error
      });
      
      throw error;
    }
  }
}






