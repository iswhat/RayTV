// VideoRepository - 视频数据仓库类
// 负责管理视频相关数据，包括视频列表、详情、收藏、观看历史等

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import FileUtil from '../../common/util/FileUtil';
import {
  VideoType,
  VideoQuality,
  VideoSource,
  VideoInfo,
  VideoMetadata,
  VideoStatistics,
  VideoChapter,
  VideoComment,
  RelatedVideo,
  PlaybackProgress,
  VideoRating,
  VideoCategory,
  VideoTag
} from '../dto/VideoDto';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';
import { UserRepository } from './UserRepository';

/**
 * 视频事件类型
 */
export const VideoEventType = {
  VIDEO_LOADED: 'video:loaded',
  VIDEO_LIST_LOADED: 'video:listLoaded',
  VIDEO_UPDATED: 'video:updated',
  VIDEO_FAVORITED: 'video:favorited',
  VIDEO_UNFAVORITED: 'video:unfavorited',
  VIDEO_PROGRESS_UPDATED: 'video:progressUpdated',
  VIDEO_WATCHED: 'video:watched',
  VIDEO_RATED: 'video:rated',
  VIDEO_COMMENT_ADDED: 'video:commentAdded',
  VIDEO_ERROR: 'video:error',
  VIDEO_CACHE_UPDATED: 'video:cacheUpdated'
} as const;

/**
 * 视频事件数据
 */
export interface VideoEvent {
  videoId: string;
  type: string;
  timestamp: number;
  data?: unknown;
  error?: Error;
}

/**
 * 视频列表请求参数
 */
export interface VideoListRequest {
  type?: VideoType;
  category?: string;
  tag?: string;
  page?: number;
  pageSize?: number;
  sortBy?: 'latest' | 'popular' | 'rating' | 'viewCount';
  filters?: {
    quality?: VideoQuality;
    duration?: { min?: number; max?: number };
    dateRange?: { start?: number; end?: number };
  };
}

/**
 * 视频列表响应
 */
export interface VideoListResponse {
  videos: VideoInfo[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

/**
 * 收藏状态变更事件数据
 */
export interface FavoriteChangeEvent extends VideoEvent {
  favorited: boolean;
  userId: string;
}

/**
 * 播放进度更新事件数据
 */
export interface ProgressUpdateEvent extends VideoEvent {
  progress: PlaybackProgress;
}

/**
 * 视频数据仓库类
 */
export class VideoRepository {
  private static instance: VideoRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  private fileUtil = FileUtil.getInstance();
  private userRepository = UserRepository.getInstance();
  
  // API端点配置
  private apiEndpoints = {
    baseUrl: 'https://api.raytv.example.com',
    videos: '/videos',
    videoDetail: '/videos/:id',
    videoCategories: '/categories',
    videoTags: '/tags',
    videoStatistics: '/videos/:id/statistics',
    videoComments: '/videos/:id/comments',
    videoFavorites: '/videos/:id/favorite',
    videoRating: '/videos/:id/rating',
    relatedVideos: '/videos/:id/related',
    videoSearch: '/search/videos',
    watchHistory: '/user/history'
  };
  
  // 存储和缓存键配置
  private storageKeys = {
    videoCache: 'video:cache:',
    videoListCache: 'video:list:',
    favorites: 'video:favorites',
    watchHistory: 'video:watchHistory',
    playbackProgress: 'video:progress:',
    categories: 'video:categories',
    tags: 'video:tags',
    lastWatched: 'video:lastWatched'
  };
  
  // 视频配置
  private videoConfig = {
    videoDetailCacheDuration: 3600, // 视频详情缓存时间（秒）
    videoListCacheDuration: 1800, // 视频列表缓存时间（秒）
    maxWatchHistoryItems: 100, // 最大观看历史记录数
    progressSaveInterval: 10, // 播放进度保存间隔（秒）
    maxFavorites: 1000, // 最大收藏数
    thumbnailCacheDuration: 86400 // 缩略图缓存时间（秒）
  };
  
  // 本地播放进度缓存
  private progressCache: Map<string, PlaybackProgress> = new Map();

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('VideoRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取VideoRepository单例实例
   */
  public static getInstance(): VideoRepository {
    if (!VideoRepository.instance) {
      VideoRepository.instance = new VideoRepository();
    }
    return VideoRepository.instance;
  }

  /**
   * 初始化视频仓库
   */
  private async initialize(): Promise<void> {
    try {
      // 加载本地播放进度缓存
      await this.loadProgressCache();
      
      // 预加载视频分类（异步）
      this.loadCategories().catch(err => {
        this.logger.warn('Failed to preload video categories', err);
      });
      
      this.logger.info('VideoRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize VideoRepository', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用退出事件，保存所有进度
    this.eventBus.on('app:exit', async () => {
      await this.saveAllProgress();
    });
    
    // 监听网络状态变化
    this.eventBus.on('network:statusChanged', async (status: { isOnline: boolean }) => {
      if (status.isOnline) {
        // 在线时同步播放进度
        await this.syncPlaybackProgress();
      }
    });
    
    // 监听用户登录/登出事件
    this.eventBus.on('user:login', async () => {
      // 登录后同步播放进度和收藏
      await this.syncPlaybackProgress();
      await this.syncFavorites();
    });
    
    this.eventBus.on('user:logout', async () => {
      // 登出前保存所有进度
      await this.saveAllProgress();
    });
  }

  /**
   * 获取视频详情
   * @param videoId 视频ID
   * @param forceRefresh 是否强制刷新
   */
  public async getVideoDetail(videoId: string, forceRefresh: boolean = false): Promise<VideoInfo> {
    try {
      const cacheKey = `${this.storageKeys.videoCache}${videoId}`;
      
      // 尝试从缓存获取
      if (!forceRefresh) {
        const cachedVideo = await this.cacheService.getCache<VideoInfo>(cacheKey);
        if (cachedVideo) {
          this.logger.debug(`Video detail loaded from cache: ${videoId}`);
          
          // 发布视频加载事件
          this.eventBus.emit(VideoEventType.VIDEO_LOADED, {
            videoId,
            type: VideoEventType.VIDEO_LOADED,
            timestamp: Date.now(),
            data: cachedVideo
          } as VideoEvent);
          
          return cachedVideo;
        }
      }
      
      // 构建请求URL
      const url = this.apiEndpoints.videoDetail.replace(':id', videoId);
      
      // 构建请求配置
      const config: Record<string, unknown> = {};
      
      // 如果用户已登录，添加认证头
      const authToken = this.userRepository.getAuthToken();
      if (authToken) {
        config.headers = {
          'Authorization': `Bearer ${authToken}`
        };
      }
      
      // 调用API获取视频详情
      const response = await this.networkUtil.get<VideoInfo>(
        `${this.apiEndpoints.baseUrl}${url}`,
        config
      );
      
      const videoInfo = response.data;
      
      // 缓存视频详情
      await this.cacheService.setCache(
        cacheKey,
        videoInfo,
        {
          type: CacheType.MEMORY_DISK,
          expiry: this.videoConfig.videoDetailCacheDuration * 1000
        }
      );
      
      // 发布视频加载事件
      this.eventBus.emit(VideoEventType.VIDEO_LOADED, {
        videoId,
        type: VideoEventType.VIDEO_LOADED,
        timestamp: Date.now(),
        data: videoInfo
      } as VideoEvent);
      
      this.logger.info(`Video detail loaded: ${videoInfo.title} (${videoId})`);
      
      return videoInfo;
    } catch (error) {
      this.logger.error(`Failed to get video detail for ${videoId}`, error as Error);
      
      // 发布视频错误事件
      this.eventBus.emit(VideoEventType.VIDEO_ERROR, {
        videoId,
        type: VideoEventType.VIDEO_ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as VideoEvent);
      
      throw error;
    }
  }

  /**
   * 获取视频列表
   * @param request 视频列表请求参数
   */
  public async getVideoList(request: VideoListRequest): Promise<VideoListResponse> {
    try {
      // 验证请求参数
      this.validateVideoListRequest(request);
      
      // 生成缓存键
      const cacheKey = this.generateVideoListCacheKey(request);
      
      // 尝试从缓存获取
      const cachedList = await this.cacheService.getCache<VideoListResponse>(cacheKey);
      if (cachedList) {
        this.logger.debug(`Video list loaded from cache`);
        
        // 发布视频列表加载事件
        this.eventBus.emit(VideoEventType.VIDEO_LIST_LOADED, {
          type: VideoEventType.VIDEO_LIST_LOADED,
          timestamp: Date.now(),
          data: cachedList
        } as VideoEvent);
        
        return cachedList;
      }
      
      // 构建请求参数
      const params = this.buildVideoListParams(request);
      
      // 构建请求配置
      const config: Record<string, unknown> = {
        params
      };
      
      // 如果用户已登录，添加认证头
      const authToken = this.userRepository.getAuthToken();
      if (authToken) {
        config.headers = {
          'Authorization': `Bearer ${authToken}`
        };
      }
      
      // 调用API获取视频列表
      const response = await this.networkUtil.get<VideoListResponse>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.videos}`,
        config
      );
      
      const videoList = response.data;
      
      // 缓存视频列表
      await this.cacheService.setCache(
        cacheKey,
        videoList,
        {
          type: CacheType.MEMORY_DISK,
          expiry: this.videoConfig.videoListCacheDuration * 1000
        }
      );
      
      // 发布视频列表加载事件
      this.eventBus.emit(VideoEventType.VIDEO_LIST_LOADED, {
        type: VideoEventType.VIDEO_LIST_LOADED,
        timestamp: Date.now(),
        data: videoList
      } as VideoEvent);
      
      this.logger.info(`Video list loaded: ${videoList.videos.length} videos, page ${videoList.page}`);
      
      return videoList;
    } catch (error) {
      this.logger.error('Failed to get video list', error as Error);
      
      // 发布视频错误事件
      this.eventBus.emit(VideoEventType.VIDEO_ERROR, {
        type: VideoEventType.VIDEO_ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as VideoEvent);
      
      throw error;
    }
  }

  /**
   * 获取视频分类
   */
  public async getCategories(): Promise<VideoCategory[]> {
    try {
      // 尝试从缓存获取
      const cachedCategories = await this.cacheService.getCache<VideoCategory[]>(this.storageKeys.categories);
      if (cachedCategories) {
        return cachedCategories;
      }
      
      // 调用API获取分类
      const response = await this.networkUtil.get<VideoCategory[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.videoCategories}`
      );
      
      const categories = response.data;
      
      // 缓存分类
      await this.cacheService.setCache(
        this.storageKeys.categories,
        categories,
        {
          type: CacheType.MEMORY_DISK,
          expiry: 86400 * 1000 // 24小时
        }
      );
      
      return categories;
    } catch (error) {
      this.logger.error('Failed to get video categories', error as Error);
      return [];
    }
  }

  /**
   * 获取热门标签
   */
  public async getPopularTags(limit: number = 50): Promise<VideoTag[]> {
    try {
      // 生成缓存键
      const cacheKey = `${this.storageKeys.tags}:${limit}`;
      
      // 尝试从缓存获取
      const cachedTags = await this.cacheService.getCache<VideoTag[]>(cacheKey);
      if (cachedTags) {
        return cachedTags;
      }
      
      // 调用API获取标签
      const response = await this.networkUtil.get<VideoTag[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.videoTags}`,
        {
          params: { limit }
        }
      );
      
      const tags = response.data;
      
      // 缓存标签
      await this.cacheService.setCache(
        cacheKey,
        tags,
        {
          type: CacheType.MEMORY_DISK,
          expiry: 3600 * 1000 // 1小时
        }
      );
      
      return tags;
    } catch (error) {
      this.logger.error('Failed to get popular tags', error as Error);
      return [];
    }
  }

  /**
   * 获取视频统计信息
   * @param videoId 视频ID
   */
  public async getVideoStatistics(videoId: string): Promise<VideoStatistics> {
    try {
      // 构建请求URL
      const url = this.apiEndpoints.videoStatistics.replace(':id', videoId);
      
      // 调用API获取统计信息
      const response = await this.networkUtil.get<VideoStatistics>(
        `${this.apiEndpoints.baseUrl}${url}`
      );
      
      return response.data;
    } catch (error) {
      this.logger.error(`Failed to get statistics for video ${videoId}`, error as Error);
      
      // 返回默认统计信息
      return {
        viewCount: 0,
        likeCount: 0,
        dislikeCount: 0,
        favoriteCount: 0,
        commentCount: 0,
        averageRating: 0
      };
    }
  }

  /**
   * 获取相关视频
   * @param videoId 视频ID
   * @param limit 限制数量
   */
  public async getRelatedVideos(videoId: string, limit: number = 10): Promise<RelatedVideo[]> {
    try {
      // 生成缓存键
      const cacheKey = `video:related:${videoId}:${limit}`;
      
      // 尝试从缓存获取
      const cachedRelated = await this.cacheService.getCache<RelatedVideo[]>(cacheKey);
      if (cachedRelated) {
        return cachedRelated;
      }
      
      // 构建请求URL
      const url = this.apiEndpoints.relatedVideos.replace(':id', videoId);
      
      // 调用API获取相关视频
      const response = await this.networkUtil.get<RelatedVideo[]>(
        `${this.apiEndpoints.baseUrl}${url}`,
        {
          params: { limit }
        }
      );
      
      const relatedVideos = response.data;
      
      // 缓存相关视频
      await this.cacheService.setCache(
        cacheKey,
        relatedVideos,
        {
          type: CacheType.MEMORY,
          expiry: 3600 * 1000 // 1小时
        }
      );
      
      return relatedVideos;
    } catch (error) {
      this.logger.error(`Failed to get related videos for ${videoId}`, error as Error);
      return [];
    }
  }

  /**
   * 获取视频评论
   * @param videoId 视频ID
   * @param page 页码
   * @param pageSize 每页数量
   */
  public async getVideoComments(videoId: string, page: number = 1, pageSize: number = 20): Promise<{
    comments: VideoComment[];
    total: number;
    page: number;
    pageSize: number;
  }> {
    try {
      // 构建请求URL
      const url = this.apiEndpoints.videoComments.replace(':id', videoId);
      
      // 调用API获取评论
      const response = await this.networkUtil.get<{
        comments: VideoComment[];
        total: number;
        page: number;
        pageSize: number;
      }>(
        `${this.apiEndpoints.baseUrl}${url}`,
        {
          params: { page, pageSize }
        }
      );
      
      return response.data;
    } catch (error) {
      this.logger.error(`Failed to get comments for video ${videoId}`, error as Error);
      
      // 返回空评论列表
      return {
        comments: [],
        total: 0,
        page,
        pageSize
      };
    }
  }

  /**
   * 添加视频评论
   * @param videoId 视频ID
   * @param content 评论内容
   */
  public async addVideoComment(videoId: string, content: string): Promise<VideoComment> {
    try {
      // 检查用户是否已登录
      if (!this.userRepository.isLoggedIn()) {
        throw new Error('User not logged in');
      }
      
      // 验证评论内容
      if (!content || content.trim().length < 1) {
        throw new Error('Comment content cannot be empty');
      }
      
      // 构建请求URL
      const url = this.apiEndpoints.videoComments.replace(':id', videoId);
      
      // 调用API添加评论
      const response = await this.networkUtil.post<VideoComment>(
        `${this.apiEndpoints.baseUrl}${url}`,
        { content },
        {
          headers: {
            'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
          }
        }
      );
      
      const comment = response.data;
      
      // 发布评论添加事件
      this.eventBus.emit(VideoEventType.VIDEO_COMMENT_ADDED, {
        videoId,
        type: VideoEventType.VIDEO_COMMENT_ADDED,
        timestamp: Date.now(),
        data: comment
      } as VideoEvent);
      
      return comment;
    } catch (error) {
      this.logger.error(`Failed to add comment to video ${videoId}`, error as Error);
      throw error;
    }
  }

  /**
   * 收藏/取消收藏视频
   * @param videoId 视频ID
   * @param favorited 是否收藏
   */
  public async setFavoriteStatus(videoId: string, favorited: boolean): Promise<boolean> {
    try {
      // 检查用户是否已登录
      if (!this.userRepository.isLoggedIn()) {
        throw new Error('User not logged in');
      }
      
      const userId = this.userRepository.getCurrentUser()?.id;
      if (!userId) {
        throw new Error('User ID not available');
      }
      
      // 构建请求URL
      const url = this.apiEndpoints.videoFavorites.replace(':id', videoId);
      
      try {
        // 调用API更新收藏状态
        await this.networkUtil.post(
          `${this.apiEndpoints.baseUrl}${url}`,
          { favorited },
          {
            headers: {
              'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
            }
          }
        );
      } catch (error) {
        // API调用失败时，仍然更新本地状态
        this.logger.warn(`Failed to update favorite status on server for video ${videoId}`, error as Error);
      }
      
      // 更新本地收藏状态
      const favorites = await this.getFavorites();
      
      if (favorited) {
        // 添加收藏
        if (!favorites.includes(videoId)) {
          // 检查收藏数量限制
          if (favorites.length >= this.videoConfig.maxFavorites) {
            throw new Error(`Maximum number of favorites (${this.videoConfig.maxFavorites}) reached`);
          }
          favorites.push(videoId);
        }
      } else {
        // 取消收藏
        const index = favorites.indexOf(videoId);
        if (index > -1) {
          favorites.splice(index, 1);
        }
      }
      
      // 保存更新后的收藏列表
      await this.storageUtil.setObject(this.storageKeys.favorites, favorites, LocalStorageType.DEFAULT);
      
      // 发布收藏状态变更事件
      this.eventBus.emit(favorited ? VideoEventType.VIDEO_FAVORITED : VideoEventType.VIDEO_UNFAVORITED, {
        videoId,
        type: favorited ? VideoEventType.VIDEO_FAVORITED : VideoEventType.VIDEO_UNFAVORITED,
        timestamp: Date.now(),
        favorited,
        userId
      } as FavoriteChangeEvent);
      
      // 更新视频缓存中的收藏状态
      await this.updateVideoFavoriteStatus(videoId, favorited);
      
      return true;
    } catch (error) {
      this.logger.error(`Failed to ${favorited ? 'favorite' : 'unfavorite'} video ${videoId}`, error as Error);
      throw error;
    }
  }

  /**
   * 获取收藏视频列表
   */
  public async getFavorites(): Promise<string[]> {
    try {
      return await this.storageUtil.getObject<string[]>(this.storageKeys.favorites, LocalStorageType.DEFAULT) || [];
    } catch (error) {
      this.logger.error('Failed to get favorites', error as Error);
      return [];
    }
  }

  /**
   * 检查视频是否已收藏
   * @param videoId 视频ID
   */
  public async isFavorite(videoId: string): Promise<boolean> {
    try {
      const favorites = await this.getFavorites();
      return favorites.includes(videoId);
    } catch (error) {
      this.logger.warn(`Failed to check favorite status for video ${videoId}`, error as Error);
      return false;
    }
  }

  /**
   * 对视频进行评分
   * @param videoId 视频ID
   * @param rating 评分（1-5）
   */
  public async rateVideo(videoId: string, rating: number): Promise<VideoRating> {
    try {
      // 检查用户是否已登录
      if (!this.userRepository.isLoggedIn()) {
        throw new Error('User not logged in');
      }
      
      // 验证评分
      if (rating < 1 || rating > 5) {
        throw new Error('Rating must be between 1 and 5');
      }
      
      // 构建请求URL
      const url = this.apiEndpoints.videoRating.replace(':id', videoId);
      
      // 调用API提交评分
      const response = await this.networkUtil.post<VideoRating>(
        `${this.apiEndpoints.baseUrl}${url}`,
        { rating },
        {
          headers: {
            'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
          }
        }
      );
      
      const videoRating = response.data;
      
      // 发布评分事件
      this.eventBus.emit(VideoEventType.VIDEO_RATED, {
        videoId,
        type: VideoEventType.VIDEO_RATED,
        timestamp: Date.now(),
        data: videoRating
      } as VideoEvent);
      
      return videoRating;
    } catch (error) {
      this.logger.error(`Failed to rate video ${videoId}`, error as Error);
      throw error;
    }
  }

  /**
   * 更新播放进度
   * @param videoId 视频ID
   * @param progress 播放进度
   * @param saveToStorage 是否保存到持久化存储
   */
  public async updatePlaybackProgress(
    videoId: string, 
    progress: PlaybackProgress, 
    saveToStorage: boolean = true
  ): Promise<void> {
    try {
      // 更新内存缓存
      this.progressCache.set(videoId, progress);
      
      // 如果需要，保存到持久化存储
      if (saveToStorage) {
        const key = `${this.storageKeys.playbackProgress}${videoId}`;
        await this.storageUtil.setObject(key, progress, LocalStorageType.DEFAULT);
      }
      
      // 更新最后观看记录
      await this.updateLastWatched(videoId, progress.currentTime);
      
      // 发布进度更新事件
      this.eventBus.emit(VideoEventType.VIDEO_PROGRESS_UPDATED, {
        videoId,
        type: VideoEventType.VIDEO_PROGRESS_UPDATED,
        timestamp: Date.now(),
        progress
      } as ProgressUpdateEvent);
      
      // 如果视频接近完成，记录为已观看
      if (progress.duration > 0 && progress.currentTime / progress.duration > 0.9) {
        await this.markAsWatched(videoId);
      }
    } catch (error) {
      this.logger.warn(`Failed to update playback progress for video ${videoId}`, error as Error);
    }
  }

  /**
   * 获取播放进度
   * @param videoId 视频ID
   */
  public async getPlaybackProgress(videoId: string): Promise<PlaybackProgress | null> {
    try {
      // 首先检查内存缓存
      const cachedProgress = this.progressCache.get(videoId);
      if (cachedProgress) {
        return cachedProgress;
      }
      
      // 从持久化存储获取
      const key = `${this.storageKeys.playbackProgress}${videoId}`;
      return await this.storageUtil.getObject<PlaybackProgress>(key, LocalStorageType.DEFAULT);
    } catch (error) {
      this.logger.warn(`Failed to get playback progress for video ${videoId}`, error as Error);
      return null;
    }
  }

  /**
   * 添加到观看历史
   * @param videoId 视频ID
   * @param videoInfo 视频信息
   */
  public async addToWatchHistory(videoId: string, videoInfo?: VideoInfo): Promise<void> {
    try {
      // 获取现有观看历史
      const history = await this.getWatchHistory();
      
      // 移除重复项
      const filteredHistory = history.filter(item => item.videoId !== videoId);
      
      // 获取视频信息（如果未提供）
      let video = videoInfo;
      if (!video) {
        try {
          video = await this.getVideoDetail(videoId, false);
        } catch (error) {
          this.logger.warn(`Failed to get video info for watch history: ${videoId}`, error as Error);
          return;
        }
      }
      
      // 创建历史记录项
      const historyItem = {
        videoId,
        title: video.title,
        thumbnailUrl: video.coverUrl,
        duration: video.duration,
        watchedAt: Date.now()
      };
      
      // 添加到历史记录开头
      filteredHistory.unshift(historyItem);
      
      // 限制历史记录数量
      const limitedHistory = filteredHistory.slice(0, this.videoConfig.maxWatchHistoryItems);
      
      // 保存历史记录
      await this.storageUtil.setObject(
        this.storageKeys.watchHistory,
        limitedHistory,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.warn(`Failed to add video ${videoId} to watch history`, error as Error);
    }
  }

  /**
   * 获取观看历史
   * @param limit 限制数量
   */
  public async getWatchHistory(limit?: number): Promise<Array<{
    videoId: string;
    title: string;
    thumbnailUrl: string;
    duration: number;
    watchedAt: number;
  }>> {
    try {
      const history = await this.storageUtil.getObject<Array<{
        videoId: string;
        title: string;
        thumbnailUrl: string;
        duration: number;
        watchedAt: number;
      }>>(this.storageKeys.watchHistory, LocalStorageType.DEFAULT) || [];
      
      // 限制数量
      if (limit && limit > 0) {
        return history.slice(0, limit);
      }
      
      return history;
    } catch (error) {
      this.logger.error('Failed to get watch history', error as Error);
      return [];
    }
  }

  /**
   * 清除观看历史
   */
  public async clearWatchHistory(): Promise<void> {
    try {
      await this.storageUtil.remove(this.storageKeys.watchHistory, LocalStorageType.DEFAULT);
      this.logger.info('Watch history cleared');
    } catch (error) {
      this.logger.error('Failed to clear watch history', error as Error);
      throw error;
    }
  }

  /**
   * 标记视频为已观看
   * @param videoId 视频ID
   */
  private async markAsWatched(videoId: string): Promise<void> {
    try {
      // 发布视频已观看事件
      this.eventBus.emit(VideoEventType.VIDEO_WATCHED, {
        videoId,
        type: VideoEventType.VIDEO_WATCHED,
        timestamp: Date.now()
      } as VideoEvent);
      
      // 异步发送观看记录到服务器
      if (this.userRepository.isLoggedIn()) {
        this.networkUtil.post(
          `${this.apiEndpoints.baseUrl}${this.apiEndpoints.watchHistory}`,
          {
            videoId,
            watchedAt: Date.now()
          },
          {
            headers: {
              'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
            }
          }
        ).catch(error => {
          this.logger.warn(`Failed to sync watch status to server for video ${videoId}`, error as Error);
        });
      }
    } catch (error) {
      this.logger.warn(`Failed to mark video ${videoId} as watched`, error as Error);
    }
  }

  /**
   * 更新最后观看记录
   * @param videoId 视频ID
   * @param currentTime 当前播放时间
   */
  private async updateLastWatched(videoId: string, currentTime: number): Promise<void> {
    try {
      await this.storageUtil.setObject(
        this.storageKeys.lastWatched,
        {
          videoId,
          currentTime,
          timestamp: Date.now()
        },
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.warn('Failed to update last watched', error as Error);
    }
  }

  /**
   * 加载本地播放进度缓存
   */
  private async loadProgressCache(): Promise<void> {
    try {
      // 获取所有存储的进度记录键
      const keys = await this.storageUtil.getAllKeys(LocalStorageType.DEFAULT);
      const progressKeys = keys.filter(key => key.startsWith(this.storageKeys.playbackProgress));
      
      // 加载所有进度记录到内存缓存
      for (const key of progressKeys) {
        const videoId = key.replace(this.storageKeys.playbackProgress, '');
        const progress = await this.storageUtil.getObject<PlaybackProgress>(key, LocalStorageType.DEFAULT);
        if (progress) {
          this.progressCache.set(videoId, progress);
        }
      }
      
      this.logger.debug(`Loaded ${this.progressCache.size} playback progress records into cache`);
    } catch (error) {
      this.logger.warn('Failed to load progress cache', error as Error);
    }
  }

  /**
   * 保存所有播放进度
   */
  private async saveAllProgress(): Promise<void> {
    try {
      // 将内存缓存中的所有进度保存到持久化存储
      for (const [videoId, progress] of this.progressCache.entries()) {
        const key = `${this.storageKeys.playbackProgress}${videoId}`;
        await this.storageUtil.setObject(key, progress, LocalStorageType.DEFAULT);
      }
      
      this.logger.debug(`Saved ${this.progressCache.size} playback progress records`);
    } catch (error) {
      this.logger.warn('Failed to save all progress records', error as Error);
    }
  }

  /**
   * 同步播放进度到服务器
   */
  private async syncPlaybackProgress(): Promise<void> {
    try {
      if (!this.userRepository.isLoggedIn()) {
        return;
      }
      
      // 获取需要同步的进度记录（例如最近更新的）
      const recentProgress = Array.from(this.progressCache.entries())
        .filter(([_, progress]) => progress.lastUpdated > Date.now() - 3600000) // 最近1小时更新的
        .slice(0, 50); // 限制同步数量
      
      if (recentProgress.length === 0) {
        return;
      }
      
      // 构建同步数据
      const syncData = recentProgress.map(([videoId, progress]) => ({
        videoId,
        progress
      }));
      
      // 调用API同步进度
      await this.networkUtil.post(
        `${this.apiEndpoints.baseUrl}/user/progress/sync`,
        { progresses: syncData },
        {
          headers: {
            'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
          }
        }
      );
      
      this.logger.debug(`Synced ${syncData.length} playback progress records to server`);
    } catch (error) {
      this.logger.warn('Failed to sync playback progress to server', error as Error);
    }
  }

  /**
   * 同步收藏列表
   */
  private async syncFavorites(): Promise<void> {
    try {
      if (!this.userRepository.isLoggedIn()) {
        return;
      }
      
      // 调用API获取服务器端收藏列表
      const response = await this.networkUtil.get<string[]>(
        `${this.apiEndpoints.baseUrl}/user/favorites`,
        {
          headers: {
            'Authorization': `Bearer ${this.userRepository.getAuthToken()}`
          }
        }
      );
      
      const serverFavorites = response.data;
      
      // 获取本地收藏列表
      const localFavorites = await this.getFavorites();
      
      // 合并收藏列表（保留并集）
      const mergedFavorites = [...new Set([...serverFavorites, ...localFavorites])];
      
      // 保存合并后的收藏列表
      if (mergedFavorites.length > 0) {
        await this.storageUtil.setObject(
          this.storageKeys.favorites,
          mergedFavorites,
          LocalStorageType.DEFAULT
        );
      }
      
      this.logger.debug(`Synced favorites with server, total: ${mergedFavorites.length}`);
    } catch (error) {
      this.logger.warn('Failed to sync favorites with server', error as Error);
    }
  }

  /**
   * 更新视频缓存中的收藏状态
   * @param videoId 视频ID
   * @param favorited 是否收藏
   */
  private async updateVideoFavoriteStatus(videoId: string, favorited: boolean): Promise<void> {
    try {
      const cacheKey = `${this.storageKeys.videoCache}${videoId}`;
      const videoInfo = await this.cacheService.getCache<VideoInfo>(cacheKey);
      
      if (videoInfo) {
        videoInfo.isFavorite = favorited;
        
        // 更新缓存
        await this.cacheService.setCache(
          cacheKey,
          videoInfo,
          {
            type: CacheType.MEMORY_DISK,
            expiry: this.videoConfig.videoDetailCacheDuration * 1000
          }
        );
      }
    } catch (error) {
      this.logger.warn(`Failed to update favorite status in video cache for ${videoId}`, error as Error);
    }
  }

  /**
   * 验证视频列表请求参数
   */
  private validateVideoListRequest(request: VideoListRequest): void {
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
   * 构建视频列表请求参数
   */
  private buildVideoListParams(request: VideoListRequest): Record<string, string | number> {
    const params: Record<string, string | number> = {
      page: request.page || 1,
      pageSize: request.pageSize || 20,
      sortBy: request.sortBy || 'latest'
    };
    
    if (request.type) {
      params.type = request.type;
    }
    
    if (request.category) {
      params.category = request.category;
    }
    
    if (request.tag) {
      params.tag = request.tag;
    }
    
    // 添加过滤条件
    if (request.filters) {
      if (request.filters.quality) {
        params['filter[quality]'] = request.filters.quality;
      }
      
      if (request.filters.duration) {
        if (request.filters.duration.min !== undefined) {
          params['filter[duration][min]'] = request.filters.duration.min;
        }
        if (request.filters.duration.max !== undefined) {
          params['filter[duration][max]'] = request.filters.duration.max;
        }
      }
      
      if (request.filters.dateRange) {
        if (request.filters.dateRange.start !== undefined) {
          params['filter[dateRange][start]'] = request.filters.dateRange.start;
        }
        if (request.filters.dateRange.end !== undefined) {
          params['filter[dateRange][end]'] = request.filters.dateRange.end;
        }
      }
    }
    
    return params;
  }

  /**
   * 生成视频列表缓存键
   */
  private generateVideoListCacheKey(request: VideoListRequest): string {
    const filtersString = request.filters ? 
      JSON.stringify(request.filters) : '';
    
    return `video:list:${request.type || 'all'}:${request.category || ''}:${request.tag || ''}:${request.page || 1}:${request.pageSize || 20}:${request.sortBy || 'latest'}:${filtersString}`;
  }

  /**
   * 加载视频分类
   */
  private async loadCategories(): Promise<VideoCategory[]> {
    return this.getCategories();
  }

  /**
   * 清除视频缓存
   * @param videoId 可选的视频ID，如果不提供则清除所有缓存
   */
  public async clearVideoCache(videoId?: string): Promise<void> {
    try {
      if (videoId) {
        // 清除特定视频的缓存
        const cacheKey = `${this.storageKeys.videoCache}${videoId}`;
        await this.cacheService.removeCache(cacheKey);
        
        // 清除相关缓存
        await this.cacheService.removeCache(`video:related:${videoId}:*`);
        await this.cacheService.removeCache(`search:item:*:${videoId}`);
      } else {
        // 清除所有视频列表缓存
        const pattern = `${this.storageKeys.videoListCache}*`;
        await this.cacheService.removeCacheByPattern(pattern);
        
        // 清除所有视频详情缓存
        const detailPattern = `${this.storageKeys.videoCache}*`;
        await this.cacheService.removeCacheByPattern(detailPattern);
      }
      
      // 发布缓存更新事件
      this.eventBus.emit(VideoEventType.VIDEO_CACHE_UPDATED, {
        type: VideoEventType.VIDEO_CACHE_UPDATED,
        timestamp: Date.now(),
        data: { videoId }
      } as VideoEvent);
      
      this.logger.info(`${videoId ? `Cache cleared for video ${videoId}` : 'All video caches cleared'}`);
    } catch (error) {
      this.logger.error(`Failed to clear video cache${videoId ? ` for ${videoId}` : ''}`, error as Error);
      throw error;
    }
  }
}

// 导出默认实例
export default VideoRepository.getInstance();