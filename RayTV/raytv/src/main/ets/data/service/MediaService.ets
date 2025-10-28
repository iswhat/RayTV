// MediaService.ets - 媒体服务
// 负责视频内容管理、播放状态同步和多设备媒体控制

import Logger from '../../common/util/Logger';
import ConfigService from './ConfigService';
import DistributedDataService from './DistributedDataService';
import DeviceManager from './DeviceManager';
import PlayerService from './PlayerService';
import { SyncDataType } from './DistributedDataService';

// 常量定义
const TAG = 'MediaService';

// 媒体类型枚举
export enum MediaType {
  MOVIE = 'movie',
  TV_SERIES = 'tv_series',
  LIVE = 'live',
  ANIME = 'anime',
  DOCUMENTARY = 'documentary',
  VARIETY = 'variety',
  SPORTS = 'sports',
  OTHER = 'other'
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

// 播放记录接口
export interface PlaybackRecord {
  mediaId: string;          // 媒体ID
  episodeId?: string;       // 剧集ID
  position: number;         // 播放位置（秒）
  lastPlayTime: number;     // 最后播放时间
  playCount: number;        // 播放次数
  isFinished: boolean;      // 是否已播放完成
  deviceId?: string;        // 最后播放设备ID
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
  enablePlaybackStatistics: boolean;   // 启用播放统计
  enableRecommendations: boolean;      // 启用推荐
}

// 默认媒体服务配置
export const DEFAULT_MEDIA_SERVICE_CONFIG: MediaServiceConfig = {
  enableCrossDevicePlayback: true,
  syncPlaybackProgress: true,
  autoResumePlayback: true,
  maxPlaybackHistory: 100,
  enablePlaybackStatistics: true,
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
type MediaEventListener = (event: MediaEvent, data: any) => void;

export default class MediaService {
  private static instance: MediaService;
  private configService: ConfigService;
  private distributedDataService: DistributedDataService;
  private deviceManager: DeviceManager;
  private playerService: PlayerService;
  private config: MediaServiceConfig = DEFAULT_MEDIA_SERVICE_CONFIG;
  private mediaMetadataCache: Map<string, MediaMetadata> = new Map();
  private playbackRecords: Map<string, PlaybackRecord> = new Map();
  private collections: Map<string, MediaCollection> = new Map();
  private currentPlaybackProgress: PlaybackProgress | null = null;
  private eventListeners: Map<MediaEvent, MediaEventListener[]> = new Map();
  private progressSyncInterval: number | null = null;
  private isInitialized: boolean = false;

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
    this.configService = ConfigService.getInstance();
    this.distributedDataService = DistributedDataService.getInstance();
    this.deviceManager = DeviceManager.getInstance();
    this.playerService = PlayerService.getInstance();
  }

  /**
   * 初始化媒体服务
   * @param context 应用上下文
   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Media service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing media service...');

      // 加载配置
      await this.loadConfig();
      
      // 加载播放记录
      await this.loadPlaybackRecords();
      
      // 加载媒体集合
      await this.loadCollections();
      
      // 注册播放器事件监听
      this.registerPlayerEvents();
      
      // 注册分布式数据监听
      this.registerDistributedDataListeners();
      
      // 如果启用了播放进度同步，启动同步定时器
      if (this.config.syncPlaybackProgress) {
        this.startProgressSync();
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'Media service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize media service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('mediaServiceConfig', DEFAULT_MEDIA_SERVICE_CONFIG);
      if (savedConfig) {
        this.config = { ...DEFAULT_MEDIA_SERVICE_CONFIG, ...savedConfig };
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
   * 获取配置
   */
  public getConfig(): MediaServiceConfig {
    return { ...this.config };
  }

  /**
   * 加载播放记录
   */
  private async loadPlaybackRecords(): Promise<void> {
    try {
      const records = await this.configService.getConfig<Record<string, PlaybackRecord>>('playbackRecords', {});
      Object.entries(records).forEach(([key, record]) => {
        this.playbackRecords.set(key, record);
      });
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
      const collections = await this.configService.getConfig<Record<string, MediaCollection>>('mediaCollections', {});
      Object.entries(collections).forEach(([key, collection]) => {
        this.collections.set(key, collection);
      });
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
    this.distributedDataService.addDataChangeListener(
      SyncDataType.PLAYBACK_PROGRESS,
      (key, data, deviceId) => {
        if (data.deviceId !== this.deviceManager.getLocalDeviceId()) {
          // 接收到其他设备的播放进度
          this.handleRemotePlaybackProgress(data as PlaybackProgress);
        }
      }
    );
  }

  /**
   * 处理远程播放进度
   */
  private async handleRemotePlaybackProgress(progress: PlaybackProgress): Promise<void> {
    const localDeviceId = this.deviceManager.getLocalDeviceId();
    
    // 只处理其他设备的播放进度
    if (progress.deviceId === localDeviceId) {
      return;
    }

    Logger.debug(TAG, `Received remote playback progress from ${progress.deviceName}: ${progress.mediaId}`);
    
    // 更新本地缓存的进度
    const timeDiff = Date.now() - progress.timestamp;
    
    // 如果时间差较小，且是同一个媒体，考虑是否需要同步
    if (timeDiff < 5000) { // 5秒内的进度更新
      const currentMediaId = this.playerService.getCurrentMediaId();
      
      if (currentMediaId === progress.mediaId && !this.playerService.isPlaying()) {
        // 如果当前播放的是同一个媒体且未在播放，可以提示用户是否同步进度
        this.notifyEvent(MediaEvent.PLAYBACK_DEVICE_CHANGED, progress);
      }
    }
  }

  /**
   * 开始播放进度同步
   */
  private startProgressSync(): void {
    this.stopProgressSync();
    
    // 每5秒同步一次播放进度
    this.progressSyncInterval = setInterval(() => {
      this.syncCurrentPlaybackProgress().catch(error => {
        Logger.error(TAG, `Failed to sync playback progress: ${error}`);
      });
    }, 5000);
    
    Logger.info(TAG, 'Playback progress sync started');
  }

  /**
   * 停止播放进度同步
   */
  private stopProgressSync(): void {
    if (this.progressSyncInterval !== null) {
      clearInterval(this.progressSyncInterval);
      this.progressSyncInterval = null;
      Logger.info(TAG, 'Playback progress sync stopped');
    }
  }

  /**
   * 同步当前播放进度
   */
  private async syncCurrentPlaybackProgress(): Promise<void> {
    if (!this.playerService.isPlaying() || !this.config.syncPlaybackProgress) {
      return;
    }

    const mediaId = this.playerService.getCurrentMediaId();
    const position = this.playerService.getCurrentPosition();
    
    if (mediaId && position >= 0) {
      const deviceInfo = await this.deviceManager.getDevice(this.deviceManager.getLocalDeviceId());
      
      const progress: PlaybackProgress = {
        mediaId,
        episodeId: this.playerService.getCurrentEpisodeId(),
        position,
        timestamp: Date.now(),
        deviceId: this.deviceManager.getLocalDeviceId(),
        deviceName: deviceInfo?.deviceName || '本机',
        isPlaying: this.playerService.isPlaying()
      };
      
      this.currentPlaybackProgress = progress;
      
      // 通过分布式数据服务同步进度
      await this.distributedDataService.saveSyncData(
        SyncDataType.PLAYBACK_PROGRESS,
        `current_${Date.now()}`,
        progress
      );
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
        metadata = await this.configService.getConfig<MediaMetadata>(key, null);
        
        if (metadata) {
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
          isFinished: false,
          deviceId: localDeviceId
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
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    
    this.eventListeners.get(event)!.push(listener);
    Logger.debug(TAG, `Added media event listener for ${event}`);
  }

  /**
   * 移除媒体事件监听
   */
  public removeMediaEventListener(event: MediaEvent, listener: MediaEventListener): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
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
  private notifyEvent(event: MediaEvent, data: any): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
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
      const command = {
        action: 'SWITCH_PLAYBACK',
        mediaId,
        episodeId,
        position,
        isPlaying,
        timestamp: Date.now(),
        sourceDeviceId: this.deviceManager.getLocalDeviceId()
      };

      // 发送到目标设备
      const success = await this.deviceManager.sendMessage(deviceId, command);
      
      if (success && isPlaying) {
        // 暂停当前设备的播放
        await this.playerService.pause();
      }
      
      return success;
    } catch (error) {
      Logger.error(TAG, `Failed to switch playback to device ${deviceId}: ${error}`);
      return false;
    }
  }

  /**
   * 清空播放历史
   */
  public async clearPlaybackHistory(): Promise<void> {
    try {
      this.playbackRecords.clear();
      await this.savePlaybackRecords();
      Logger.info(TAG, 'Playback history cleared');
    } catch (error) {
      Logger.error(TAG, `Failed to clear playback history: ${error}`);
      throw error;
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