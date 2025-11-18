// MediaService.ets - 媒体服务
// 负责视频内容管理、播放状态同步和多设备媒体控制，整合了业务逻辑层媒体服务功能

import Logger from '../../common/util/Logger';
import ConfigService from '../../service/config/ConfigService';
import ModernDistributedDataService from '../sync/ModernDistributedDataService';
import DeviceManager from '../device/DeviceManager';
import PlayerService from '../player/PlayerService';
import { SyncDataType } from '../sync/ModernDistributedDataService';
import { Vod, Episode, VodCategory, VodTag } from '../../data/bean/Vod';
import { LiveChannel, LiveGroup, EpgItem } from '../../data/bean/Live';
import { VodRepository } from '../../data/repository/VodRepository';
import { LiveRepository } from '../../data/repository/LiveRepository';
import { HistoryRepository } from '../../data/repository/HistoryRepository';
import { CollectionRepository } from '../../data/repository/CollectionRepository';
import DeviceService from '../../service/device/DeviceService';
import HttpService from '../HttpService';
import { TypeSafetyUtil } from '../../common/util/TypeSafetyUtil';

// 常量定义
const TAG = 'MediaService';

// 媒体类型枚举 - 整合业务层和服务层的媒体类型定义
export enum MediaType {
  // 服务层媒体类型
  MOVIE = 'movie',
  TV_SERIES = 'tv_series',
  LIVE = 'live',
  ANIME = 'anime',
  DOCUMENTARY = 'documentary',
  VARIETY = 'variety',
  SPORTS = 'sports',
  OTHER = 'other',
  
  // 业务层媒体类型别名
  VOD = 'vod',
  EPISODE = 'episode'
}

// 媒体元数据接口
export interface MediaMetadata {
  id: string;               // 媒体唯一标识
  title: string;            // 标题
  subtitle?: string;        // 副标题
  description?: string;     // 描述
  coverUrl?: string;        // 封面图片URL
  bannerUrl?: string;       // 横幅图片URL
  type: MediaType;          // 媒体类型
  category?: string[];      // 分类标签
  tags?: string[];          // 标签
  year?: number;            // 年份
  duration?: number;        // 时长（秒）
  episodeCount?: number;    // 集数（电视剧）
  director?: string[];      // 导演
  actors?: string[];        // 演员
  rating?: number;          // 评分
  region?: string[];        // 地区
  language?: string[];      // 语言
  releaseDate?: string;     // 发布日期
  updateStatus?: string;    // 更新状态
  isFavorite?: boolean;     // 是否收藏
  isWatchLater?: boolean;   // 是否稍后观看
  sourceSite?: string;      // 来源站点
  sourceUrl?: string;       // 来源URL
  createTime: number;       // 创建时间
  updateTime: number;       // 更新时间
}

// 播放记录接口 - 整合服务层和业务层的播放记录定义
export interface PlaybackRecord {
  mediaId: string;          // 媒体ID
  episodeId?: string;       // 剧集ID
  position: number;         // 播放位置（秒）
  lastPlayTime: number;     // 最后播放时间
  playCount: number;        // 播放次数
  isFinished: boolean;      // 是否已播放完成
  deviceId?: string;        // 最后播放设备ID
  totalDuration?: number;   // 总时长（业务层需要）
  title?: string;           // 标题（业务层需要）
  coverUrl?: string;        // 封面URL（业务层需要）
  currentEpisode?: string;  // 当前剧集（业务层需要）
  progress?: number;        // 进度百分比 0-100（业务层需要）
}

// 媒体播放进度接口
export interface PlaybackProgress {
  mediaId: string;          // 媒体ID
  episodeId?: string;       // 剧集ID
  position: number;         // 播放位置（秒）
  timestamp: number;        // 时间戳
  deviceId: string;         // 设备ID
  deviceName: string;       // 设备名称
  isPlaying: boolean;       // 是否正在播放
}

// 媒体集合接口
export interface MediaCollection {
  id: string;               // 集合ID
  name: string;             // 集合名称
  description?: string;     // 集合描述
  coverUrl?: string;        // 集合封面
  mediaIds: string[];       // 媒体ID列表
  createTime: number;       // 创建时间
  updateTime: number;       // 更新时间
}

// 媒体服务配置接口
export interface MediaServiceConfig {
  enableCrossDevicePlayback: boolean;  // 启用跨设备播放
  syncPlaybackProgress: boolean;       // 同步播放进度
  autoResumePlayback: boolean;         // 自动恢复播放
  maxPlaybackHistory: number;          // 最大播放历史数量
  enableRecommendations: boolean;      // 启用推荐
}

// 默认媒体服务配置
export const DEFAULT_MEDIA_SERVICE_CONFIG: MediaServiceConfig = {
  enableCrossDevicePlayback: true,
  syncPlaybackProgress: true,
  autoResumePlayback: true,
  maxPlaybackHistory: 100,
  enableRecommendations: true
};

// 媒体事件枚举
export enum MediaEvent {
  PLAYBACK_STARTED = 'playback_started',
  PLAYBACK_PAUSED = 'playback_paused',
  PLAYBACK_RESUMED = 'playback_resumed',
  PLAYBACK_STOPPED = 'playback_stopped',
  PLAYBACK_COMPLETED = 'playback_completed',
  PLAYBACK_PROGRESS_CHANGED = 'playback_progress_changed',
  PLAYBACK_DEVICE_CHANGED = 'playback_device_changed',
  MEDIA_ADDED = 'media_added',
  MEDIA_UPDATED = 'media_updated',
  MEDIA_DELETED = 'media_deleted',
  COLLECTION_CREATED = 'collection_created',
  COLLECTION_UPDATED = 'collection_updated',
  COLLECTION_DELETED = 'collection_deleted'
}

// 媒体事件监听回调类型
type MediaEventListener = (event: MediaEvent, data: MediaMetadata | PlaybackRecord | MediaCollection | PlaybackProgress) => void;

// 播放选项接口（业务层需要）
export interface PlayOptions {
  autoPlay?: boolean;
  startPosition?: number;
  selectedEpisode?: string;
  audioTrack?: string;
  subtitleTrack?: string;
  playbackRate?: number;
  volume?: number;
  muted?: boolean;
  quality?: string;
}

// 搜索结果接口（业务层需要）
export interface SearchResult {
  vodItems: Vod[];
  totalCount: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

// 推荐内容接口（业务层需要）
export interface RecommendationResult {
  featured: Vod[];
  recentlyAdded: Vod[];
  popular: Vod[];
  continueWatching: PlaybackRecord[];
  related: Vod[];
}

export default class MediaService {
  private static instance: MediaService;
  // 服务层依赖
  private configService: ConfigService;
  private distributedDataService: ModernDistributedDataService;
  private deviceManager: DeviceManager;
  private playerService: PlayerService;
  
  // 业务层依赖
  private vodRepository: VodRepository;
  private liveRepository: LiveRepository;
  private historyRepository: HistoryRepository;
  private collectionRepository: CollectionRepository;
  private deviceService: DeviceService;
  private httpService: HttpService;
  
  // 服务层状态
  private config: MediaServiceConfig = DEFAULT_MEDIA_SERVICE_CONFIG;
  private mediaMetadataCache: Map<string, MediaMetadata> = new Map();
  private playbackRecords: Map<string, PlaybackRecord> = new Map();
  private collections: Map<string, MediaCollection> = new Map();
  private currentPlaybackProgress: PlaybackProgress | null = null;
  private eventListeners: Record<MediaEvent, MediaEventListener[]> = {
    [MediaEvent.PLAYBACK_STARTED]: [],
    [MediaEvent.PLAYBACK_PAUSED]: [],
    [MediaEvent.PLAYBACK_RESUMED]: [],
    [MediaEvent.PLAYBACK_STOPPED]: [],
    [MediaEvent.PLAYBACK_PROGRESS_CHANGED]: [],
    [MediaEvent.PLAYBACK_DEVICE_CHANGED]: [],
    [MediaEvent.MEDIA_ADDED]: [],
    [MediaEvent.MEDIA_UPDATED]: [],
    [MediaEvent.MEDIA_DELETED]: [],
    [MediaEvent.COLLECTION_CREATED]: [],
    [MediaEvent.COLLECTION_UPDATED]: [],
    [MediaEvent.COLLECTION_DELETED]: []
  };
  private progressSyncInterval: number | null = null;
  private isInitialized: boolean = false;
  
  // 业务层状态
  private currentPlayingMedia: { id: string; type: MediaType } | null = null;
  private playListeners: Array<(media: { id: string; type: MediaType }) => void> = [];

  /**
   * 获取单例实例
   */
  public static getInstance(): MediaService {
    if (!MediaService.instance) {
      MediaService.instance = new MediaService();
    }
    return MediaService.instance;
  }

  /**
   * 构造函数
   */
  private constructor() {
    // 初始化服务层依赖
    this.configService = ConfigService.getInstance();
    this.distributedDataService = ModernDistributedDataService.getInstance();
    this.deviceManager = DeviceManager.getInstance();
    this.playerService = PlayerService.getInstance();
    
    // 初始化业务层依赖
    this.vodRepository = VodRepository.getInstance();
    this.liveRepository = LiveRepository.getInstance();
    this.historyRepository = HistoryRepository.getInstance();
    this.collectionRepository = CollectionRepository.getInstance();
    this.deviceService = DeviceService.getInstance();
    this.httpService = HttpService.getInstance();
    
    // 初始化
    this.initialize();
  }

  /**
   * 初始化媒体服务
   */
  private async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    
    try {
      // 加载配置
      await this.loadConfig();
      
      // 加载播放记录
      await this.loadPlaybackRecords();
      
      // 加载媒体集合
      await this.loadCollections();
      
      // 注册事件监听
      this.registerPlayerEvents();
      this.registerDistributedDataListeners();
      
      // 初始化业务层
      await this.initializeBusinessLayer();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Media service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize media service: ${error}`);
    }
  }

  /**
   * 初始化业务逻辑层
   */
  private async initializeBusinessLayer(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing business layer...');
      
      // 预加载常用数据
      await this.preloadCommonData();
      
      Logger.info(TAG, 'Business layer initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize business layer: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 预加载常用数据
   */
  private async preloadCommonData(): Promise<void> {
    try {
      // 预加载热门点播内容
      await this.vodRepository.preloadPopularVods();
      
      // 预加载直播频道列表
      await this.liveRepository.preloadLiveGroups();
    } catch (error) {
      Logger.warn(TAG, `Failed to preload common data: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 获取点播内容详情
   */
  public async getVodDetail(vodId: string): Promise<Vod | null> {
    try {
      const vod = await this.vodRepository.getVodById(vodId);
      if (vod) {
        // 记录访问
        await this.vodRepository.incrementVodViewCount(vodId);
        
        // 预加载相关信息
        await this.preloadVodRelatedContent(vodId);
      }
      return vod;
    } catch (error) {
      Logger.error(TAG, `Failed to get VOD detail for ID: ${vodId}`, error);
      return null;
    }
  }
  
  /**
   * 获取直播频道详情
   */
  public async getLiveChannelDetail(channelId: string): Promise<LiveChannel | null> {
    try {
      const channel = await this.liveRepository.getChannelById(channelId);
      if (channel) {
        // 记录访问
        await this.liveRepository.incrementChannelViewCount(channelId);
      }
      return channel;
    } catch (error) {
      Logger.error(TAG, `Failed to get live channel detail for ID: ${channelId}`, error);
      return null;
    }
  }

  /**
   * 播放媒体
   */
  public async playMedia(mediaId: string, type: MediaType, options: PlayOptions = {}): Promise<boolean> {
    try {
      Logger.info(TAG, `Playing media: ${mediaId}, type: ${type}`);
      
      // 更新当前播放的媒体
      this.currentPlayingMedia = { id: mediaId, type };
      
      // 通知监听器
      for (const listener of this.playListeners) {
        listener(this.currentPlayingMedia);
      }
      
      // 调用播放器服务进行实际播放
      const success = await this.playerService.play(mediaId, type, options);
      
      if (success) {
        // 记录播放开始事件
        this.notifyEvent(MediaEvent.PLAYBACK_STARTED, {
          mediaId,
          episodeId: options.selectedEpisode,
          position: options.startPosition || 0,
          lastPlayTime: Date.now(),
          playCount: 1
        } as PlaybackRecord);
      }
      
      return success;
    } catch (error) {
      Logger.error(TAG, `Failed to play media ${mediaId}: ${error}`);
      return false;
    }
  }

  /**
   * 添加播放监听器
   */
  public addPlayListener(listener: (media: { id: string; type: MediaType }) => void): void {
    this.playListeners.push(listener);
  }
  
  /**
   * 移除播放监听器
   */
  public removePlayListener(listener: (media: { id: string; type: MediaType }) => void): void {
    const index = this.playListeners.indexOf(listener);
    if (index > -1) {
      this.playListeners.splice(index, 1);
    }
  }
  
  /**
   * 获取当前播放的媒体
   */
  public getCurrentPlayingMedia(): { id: string; type: MediaType } | null {
    return this.currentPlayingMedia;
  }
  
  /**
   * 停止播放
   */
  public stopPlayback(): void {
    this.currentPlayingMedia = null;
    // 可以在这里调用playerService停止播放
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig<unknown>('mediaServiceConfig', DEFAULT_MEDIA_SERVICE_CONFIG);
      if (savedConfig && TypeSafetyUtil.isObject(savedConfig)) {
        this.config = {
          ...DEFAULT_MEDIA_SERVICE_CONFIG,
          enableCrossDevicePlayback: TypeSafetyUtil.getProperty(savedConfig, 'enableCrossDevicePlayback', true),
          syncPlaybackProgress: TypeSafetyUtil.getProperty(savedConfig, 'syncPlaybackProgress', true),
          autoResumePlayback: TypeSafetyUtil.getProperty(savedConfig, 'autoResumePlayback', true),
          maxPlaybackHistory: TypeSafetyUtil.getProperty(savedConfig, 'maxPlaybackHistory', 100),
          enableRecommendations: TypeSafetyUtil.getProperty(savedConfig, 'enableRecommendations', true)
        };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load media service config: ${error}`);
    }
  }

  /**
   * 保存配置
   */
  public async saveConfig(config: Partial<MediaServiceConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('mediaServiceConfig', this.config);
      
      // 根据配置调整进度同步
      if (this.config.syncPlaybackProgress) {
        this.startProgressSync();
      } else {
        this.stopProgressSync();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save media service config: ${error}`);
      throw error;
    }
  }

  /**
   * 加载播放记录
   */
  private async loadPlaybackRecords(): Promise<void> {
    try {
      const records = await this.configService.getConfig<Record<string, unknown>>('playbackRecords', {});
      
      if (records && TypeSafetyUtil.isObject(records)) {
        Object.entries(records).forEach(([key, value]) => {
          if (TypeSafetyUtil.isObject(value)) {
            const record: PlaybackRecord = {
              mediaId: TypeSafetyUtil.getProperty(value, 'mediaId', ''),
              episodeId: TypeSafetyUtil.getProperty(value, 'episodeId', undefined),
              position: TypeSafetyUtil.getProperty(value, 'position', 0),
              lastPlayTime: TypeSafetyUtil.getProperty(value, 'lastPlayTime', 0),
              playCount: TypeSafetyUtil.getProperty(value, 'playCount', 0),
              deviceId: TypeSafetyUtil.getProperty(value, 'deviceId', undefined),
              totalDuration: TypeSafetyUtil.getProperty(value, 'totalDuration', undefined),
              title: TypeSafetyUtil.getProperty(value, 'title', undefined),
              coverUrl: TypeSafetyUtil.getProperty(value, 'coverUrl', undefined),
              currentEpisode: TypeSafetyUtil.getProperty(value, 'currentEpisode', undefined),
              progress: TypeSafetyUtil.getProperty(value, 'progress', undefined),
              isFinished: TypeSafetyUtil.getProperty(value, 'isFinished', false)
            };
            this.playbackRecords.set(key, record);
          }
        });
      }
      
      Logger.info(TAG, `Loaded ${this.playbackRecords.size} playback records`);
    } catch (error) {
      Logger.error(TAG, `Failed to load playback records: ${error}`);
    }
  }

  /**
   * 保存播放记录
   */
  private async savePlaybackRecords(): Promise<void> {
    try {
      const recordsObj: Record<string, PlaybackRecord> = {};
      this.playbackRecords.forEach((record, key) => {
        recordsObj[key] = record;
      });
      await this.configService.setConfig('playbackRecords', recordsObj);
    } catch (error) {
      Logger.error(TAG, `Failed to save playback records: ${error}`);
    }
  }

  /**
   * 加载媒体集合
   */
  private async loadCollections(): Promise<void> {
    try {
      const collections = await this.configService.getConfig<Record<string, unknown>>('mediaCollections', {});
      
      if (collections && TypeSafetyUtil.isObject(collections)) {
        Object.entries(collections).forEach(([key, value]) => {
          if (TypeSafetyUtil.isObject(value)) {
            const collection: MediaCollection = {
              id: TypeSafetyUtil.getProperty(value, 'id', ''),
              name: TypeSafetyUtil.getProperty(value, 'name', ''),
              description: TypeSafetyUtil.getProperty(value, 'description', undefined),
              coverUrl: TypeSafetyUtil.getProperty(value, 'coverUrl', undefined),
              mediaIds: TypeSafetyUtil.getArray(value, 'mediaIds', []),
              createTime: TypeSafetyUtil.getProperty(value, 'createTime', 0),
              updateTime: TypeSafetyUtil.getProperty(value, 'updateTime', 0)
            };
            this.collections.set(key, collection);
          }
        });
      }
      Logger.info(TAG, `Loaded ${this.collections.size} media collections`);
    } catch (error) {
      Logger.error(TAG, `Failed to load media collections: ${error}`);
    }
  }

  /**
   * 保存媒体集合
   */
  private async saveCollections(): Promise<void> {
    try {
      const collectionsObj: Record<string, MediaCollection> = {};
      this.collections.forEach((collection, key) => {
        collectionsObj[key] = collection;
      });
      await this.configService.setConfig('mediaCollections', collectionsObj);
    } catch (error) {
      Logger.error(TAG, `Failed to save media collections: ${error}`);
    }
  }

  /**
   * 注册播放器事件监听
   */
  private registerPlayerEvents(): void {
    // 这里应该注册PlayerService的事件监听
    // 例如播放开始、暂停、停止、进度变化等
    // 由于PlayerService的具体实现可能尚未完成，这里先保留接口
    Logger.debug(TAG, 'Player events registered');
  }

  /**
   * 注册分布式数据监听
   */
  private registerDistributedDataListeners(): void {
    // 监听播放进度同步
    this.distributedDataService.addDataChangeListener<PlaybackProgress>(
      SyncDataType.PLAYBACK_PROGRESS,
      (key, data, deviceId) => {
        if (data && data.deviceId !== this.deviceManager.getLocalDeviceId()) {
          // 接收到其他设备的播放进度
          this.handleRemotePlaybackProgress(data);
        }
      }
    );
  }

  /**
   * 处理远程播放进度
   */
  private handleRemotePlaybackProgress(progress: PlaybackProgress): void {
    // 处理来自其他设备的播放进度同步
    Logger.debug(TAG, `Received remote playback progress from device ${progress.deviceId}`);
    
    // 更新当前播放进度
    this.currentPlaybackProgress = progress;
    
    // 通知事件监听器
    this.notifyEvent(MediaEvent.PLAYBACK_PROGRESS_CHANGED, progress);
  }

  /**
   * 开始进度同步
   */
  private startProgressSync(): void {
    if (this.progressSyncInterval) {
      this.stopProgressSync();
    }
    
    // 每5秒同步一次进度
    this.progressSyncInterval = setInterval(async () => {
      await this.syncPlaybackProgress();
    }, 5000);
  }

  /**
   * 停止进度同步
   */
  private stopProgressSync(): void {
    if (this.progressSyncInterval) {
      clearInterval(this.progressSyncInterval);
      this.progressSyncInterval = null;
    }
  }

  /**
   * 同步播放进度
   */
  private async syncPlaybackProgress(): Promise<void> {
    if (!this.currentPlaybackProgress) {
      return;
    }
    
    try {
      const key = `playback_progress_${this.currentPlaybackProgress.mediaId}`;
      await this.distributedDataService.syncData(
        SyncDataType.PLAYBACK_PROGRESS,
        key,
        this.currentPlaybackProgress
      );
    } catch (error) {
      Logger.error(TAG, `Failed to sync playback progress: ${error}`);
    }
  }

  /**
   * 预加载相关内容
   */
  private async preloadVodRelatedContent(vodId: string): Promise<void> {
    try {
      // 预加载相关视频
      await this.vodRepository.preloadRelatedVods(vodId);
    } catch (error) {
      Logger.warn(TAG, `Failed to preload related content for VOD ${vodId}: ${error}`);
    }
  }

  /**
   * 获取媒体元数据
   */
  public async getMediaMetadata(mediaId: string): Promise<MediaMetadata | null> {
    // 先从缓存中查找
    let metadata = this.mediaMetadataCache.get(mediaId);
    
    if (!metadata) {
      // 缓存中没有，从配置中加载
      try {
        const key = `media_metadata_${mediaId}`;
        const configData = await this.configService.getConfig<unknown>(key, null);
        
        // 使用TypeSafetyUtil进行类型安全转换
        if (configData && TypeSafetyUtil.isObject(configData)) {
          metadata = {
            id: TypeSafetyUtil.getProperty(configData, 'id', ''),
            title: TypeSafetyUtil.getProperty(configData, 'title', ''),
            subtitle: TypeSafetyUtil.getProperty(configData, 'subtitle', ''),
            description: TypeSafetyUtil.getProperty(configData, 'description', ''),
            coverUrl: TypeSafetyUtil.getProperty(configData, 'coverUrl', ''),
            bannerUrl: TypeSafetyUtil.getProperty(configData, 'bannerUrl', ''),
            type: TypeSafetyUtil.getProperty(configData, 'type', MediaType.OTHER),
            category: TypeSafetyUtil.getArray(configData, 'category', []),
            tags: TypeSafetyUtil.getArray(configData, 'tags', []),
            year: TypeSafetyUtil.getProperty(configData, 'year', 0),
            duration: TypeSafetyUtil.getProperty(configData, 'duration', 0),
            episodeCount: TypeSafetyUtil.getProperty(configData, 'episodeCount', 0),
            director: TypeSafetyUtil.getArray(configData, 'director', []),
            actors: TypeSafetyUtil.getArray(configData, 'actors', []),
            rating: TypeSafetyUtil.getProperty(configData, 'rating', 0),
            region: TypeSafetyUtil.getArray(configData, 'region', []),
            language: TypeSafetyUtil.getArray(configData, 'language', []),
            releaseDate: TypeSafetyUtil.getProperty(configData, 'releaseDate', ''),
            updateStatus: TypeSafetyUtil.getProperty(configData, 'updateStatus', ''),
            isFavorite: TypeSafetyUtil.getProperty(configData, 'isFavorite', false),
            isWatchLater: TypeSafetyUtil.getProperty(configData, 'isWatchLater', false),
            sourceSite: TypeSafetyUtil.getProperty(configData, 'sourceSite', ''),
            sourceUrl: TypeSafetyUtil.getProperty(configData, 'sourceUrl', ''),
            createTime: TypeSafetyUtil.getProperty(configData, 'createTime', Date.now()),
            updateTime: TypeSafetyUtil.getProperty(configData, 'updateTime', Date.now())
          };
          
          this.mediaMetadataCache.set(mediaId, metadata);
        }
      } catch (error) {
        Logger.error(TAG, `Failed to get media metadata for ${mediaId}: ${error}`);
      }
    }
    
    return metadata;
  }

  /**
   * 保存媒体元数据
   */
  public async saveMediaMetadata(metadata: MediaMetadata): Promise<void> {
    try {
      const key = `media_metadata_${metadata.id}`;
      const now = Date.now();
      
      // 确保时间戳正确
      const updatedMetadata: MediaMetadata = {
        ...metadata,
        createTime: metadata.createTime || now,
        updateTime: now
      };
      
      // 保存到配置和缓存
      await this.configService.setConfig(key, updatedMetadata);
      this.mediaMetadataCache.set(metadata.id, updatedMetadata);
      
      this.notifyEvent(MediaEvent.MEDIA_ADDED, updatedMetadata);
    } catch (error) {
      Logger.error(TAG, `Failed to save media metadata for ${metadata.id}: ${error}`);
      throw error;
    }
  }

  /**
   * 更新媒体元数据
   */
  public async updateMediaMetadata(mediaId: string, updates: Partial<MediaMetadata>): Promise<void> {
    try {
      const metadata = await this.getMediaMetadata(mediaId);
      if (!metadata) {
        throw new Error(`Media ${mediaId} not found`);
      }
      
      const updatedMetadata = {
        ...metadata,
        ...updates,
        updateTime: Date.now()
      };
      
      await this.saveMediaMetadata(updatedMetadata);
      this.notifyEvent(MediaEvent.MEDIA_UPDATED, updatedMetadata);
    } catch (error) {
      Logger.error(TAG, `Failed to update media metadata for ${mediaId}: ${error}`);
      throw error;
    }
  }

  /**
   * 获取播放记录
   */
  public getPlaybackRecord(mediaId: string, episodeId?: string): PlaybackRecord | null {
    const key = episodeId ? `${mediaId}_${episodeId}` : mediaId;
    return this.playbackRecords.get(key) || null;
  }

  /**
   * 更新播放记录
   */
  public async updatePlaybackRecord(mediaId: string, episodeId: string | undefined, position: number, isFinished: boolean = false): Promise<void> {
    try {
      const key = episodeId ? `${mediaId}_${episodeId}` : mediaId;
      const now = Date.now();
      const localDeviceId = this.deviceManager.getLocalDeviceId();
      
      let record = this.playbackRecords.get(key);
      if (!record) {
        record = {
          mediaId,
          episodeId,
          position: 0,
          lastPlayTime: 0,
          playCount: 0,
          isFinished: false
        };
      }
      
      // 更新记录
      record.position = position;
      record.lastPlayTime = now;
      record.playCount += 1;
      record.isFinished = isFinished || record.isFinished;
      record.deviceId = localDeviceId;
      
      this.playbackRecords.set(key, record);
      
      // 保存到配置
      await this.savePlaybackRecords();
      
      // 如果启用了跨设备播放，同步播放记录
      if (this.config.enableCrossDevicePlayback) {
        await this.distributedDataService.saveSyncData(
          SyncDataType.HISTORY,
          key,
          record
        );
      }
      
      // 通知进度变化
      this.notifyEvent(MediaEvent.PLAYBACK_PROGRESS_CHANGED, record);
    } catch (error) {
      Logger.error(TAG, `Failed to update playback record: ${error}`);
    }
  }

  /**
   * 获取播放历史列表
   */
  public getPlaybackHistory(limit: number = 20): PlaybackRecord[] {
    return Array.from(this.playbackRecords.values())
      .sort((a, b) => b.lastPlayTime - a.lastPlayTime)
      .slice(0, limit);
  }

  /**
   * 创建媒体集合
   */
  public async createCollection(name: string, description?: string): Promise<MediaCollection> {
    try {
      const collection: MediaCollection = {
        id: `collection_${Date.now()}`,
        name,
        description,
        mediaIds: [],
        createTime: Date.now(),
        updateTime: Date.now()
      };
      
      this.collections.set(collection.id, collection);
      await this.saveCollections();
      
      this.notifyEvent(MediaEvent.COLLECTION_CREATED, collection);
      return collection;
    } catch (error) {
      Logger.error(TAG, `Failed to create collection: ${error}`);
      throw error;
    }
  }

  /**
   * 添加媒体到集合
   */
  public async addMediaToCollection(collectionId: string, mediaId: string): Promise<void> {
    try {
      const collection = this.collections.get(collectionId);
      if (!collection) {
        throw new Error(`Collection ${collectionId} not found`);
      }
      
      if (!collection.mediaIds.includes(mediaId)) {
        collection.mediaIds.push(mediaId);
        collection.updateTime = Date.now();
        
        await this.saveCollections();
        this.notifyEvent(MediaEvent.COLLECTION_UPDATED, collection);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to add media to collection: ${error}`);
      throw error;
    }
  }

  /**
   * 从集合中移除媒体
   */
  public async removeMediaFromCollection(collectionId: string, mediaId: string): Promise<void> {
    try {
      const collection = this.collections.get(collectionId);
      if (!collection) {
        throw new Error(`Collection ${collectionId} not found`);
      }
      
      const index = collection.mediaIds.indexOf(mediaId);
      if (index > -1) {
        collection.mediaIds.splice(index, 1);
        collection.updateTime = Date.now();
        
        await this.saveCollections();
        this.notifyEvent(MediaEvent.COLLECTION_UPDATED, collection);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to remove media from collection: ${error}`);
      throw error;
    }
  }

  /**
   * 获取所有媒体集合
   */
  public getCollections(): MediaCollection[] {
    return Array.from(this.collections.values())
      .sort((a, b) => b.updateTime - a.updateTime);
  }

  /**
   * 添加媒体事件监听
   */
  public addMediaEventListener(event: MediaEvent, listener: MediaEventListener): void {
    this.ensureEventExists(event);
    
    const listeners = this.getEventListeners(event);
    listeners.push(listener);
    Logger.debug(TAG, `Added media event listener for ${event}`);
  }

  /**
   * 移除媒体事件监听
   */
  public removeMediaEventListener(event: MediaEvent, listener: MediaEventListener): void {
    if (this.hasEvent(event)) {
      const listeners = this.getEventListeners(event);
      const index = listeners.indexOf(listener);
      
      if (index > -1) {
        listeners.splice(index, 1);
        Logger.debug(TAG, `Removed media event listener for ${event}`);
      }
    }
  }

  /**
   * 通知事件
   */
  private notifyEvent(event: MediaEvent, data: MediaMetadata | PlaybackRecord | MediaCollection | PlaybackProgress): void {
    if (this.hasEvent(event)) {
      const listeners = this.getEventListeners(event);
      for (const listener of listeners) {
        try {
          listener(event, data);
        } catch (error) {
          Logger.error(TAG, `Error in media event listener: ${error}`);
        }
      }
    }
  }

  /**
   * 确保事件存在于监听器映射中
   */
  private ensureEventExists(event: MediaEvent): void {
    if (!this.hasEvent(event)) {
      this.eventListeners[event] = [];
    }
  }
  
  /**
   * 检查事件是否存在
   */
  private hasEvent(event: MediaEvent): boolean {
    return this.eventListeners[event] !== undefined;
  }
  
  /**
   * 获取事件监听器
   */
  private getEventListeners(event: MediaEvent): MediaEventListener[] {
    this.ensureEventExists(event);
    return this.eventListeners[event];
  }
  
  /**
   * 跨设备切换播放
   */
  public async switchPlaybackToDevice(deviceId: string): Promise<boolean> {
    try {
      if (!this.config.enableCrossDevicePlayback) {
        throw new Error('Cross-device playback is disabled');
      }

      const device = await this.deviceManager.getDevice(deviceId);
      if (!device || device.status !== 'online') {
        throw new Error('Target device is not online');
      }

      // 获取当前播放信息
      const mediaId = this.playerService.getCurrentMediaId();
      const position = this.playerService.getCurrentPosition();
      const episodeId = this.playerService.getCurrentEpisodeId();
      const isPlaying = this.playerService.isPlaying();
      
      if (!mediaId) {
        throw new Error('No media is currently playing');
      }

      // 构建切换播放命令
      const playbackCommand = {
        action: 'switch_playback',
        mediaId,
        episodeId,
        position,
        isPlaying
      };

      // 发送到目标设备
      const success = await this.deviceManager.sendCommandToDevice(deviceId, playbackCommand);
      
      if (success) {
        // 本地停止播放
        this.playerService.stop();
        this.stopPlayback();
        this.notifyEvent(MediaEvent.PLAYBACK_DEVICE_CHANGED, {
          deviceId,
          deviceName: device.name
        } as PlaybackProgress);
      }
      
      return success;
    } catch (error) {
      Logger.error(TAG, `Failed to switch playback to device ${deviceId}: ${error}`);
      return false;
    }
  }

  /**
   * 关闭媒体服务
   */
  public close(): void {
    if (!this.isInitialized) {
      return;
    }

    this.stopProgressSync();
    
    // 保存所有数据
    this.savePlaybackRecords().catch(error => {
      Logger.error(TAG, `Error saving playback records on close: ${error}`);
    });
    
    this.saveCollections().catch(error => {
      Logger.error(TAG, `Error saving collections on close: ${error}`);
    });

    this.isInitialized = false;
    Logger.info(TAG, 'Media service closed');
  }
}