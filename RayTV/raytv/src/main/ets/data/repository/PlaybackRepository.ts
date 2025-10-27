import Logger from '../../common/util/Logger';
import StorageUtil, { LocalStorageType } from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../common/util/CacheService';
import UserRepository from './UserRepository';
import VideoRepository from './VideoRepository';
import { PlaybackState, VideoQuality, PlaybackSpeed, PlaybackMode, AudioTrack, SubtitleTrack } from '../model/LocalModel';

// 事件类型枚举
export enum PlaybackEventType {
  PLAYBACK_STARTED = 'playback_started',
  PLAYBACK_PAUSED = 'playback_paused',
  PLAYBACK_RESUMED = 'playback_resumed',
  PLAYBACK_ENDED = 'playback_ended',
  PLAYBACK_SEEKED = 'playback_seeked',
  PLAYBACK_SPEED_CHANGED = 'playback_speed_changed',
  PLAYBACK_QUALITY_CHANGED = 'playback_quality_changed',
  PLAYBACK_MODE_CHANGED = 'playback_mode_changed',
  AUDIO_TRACK_CHANGED = 'audio_track_changed',
  SUBTITLE_TRACK_CHANGED = 'subtitle_track_changed',
  PLAYBACK_ERROR = 'playback_error',
  PLAYBACK_BUFFERING = 'playback_buffering',
  PLAYBACK_SETTINGS_UPDATED = 'playback_settings_updated',
  PLAYBACK_HISTORY_ADDED = 'playback_history_added',
  PLAYBACK_HISTORY_UPDATED = 'playback_history_updated',
  PLAYBACK_HISTORY_CLEARED = 'playback_history_cleared'
}

// 播放事件数据接口
export interface PlaybackEvent {
  type: PlaybackEventType;
  timestamp: number;
  contentId?: string;
  contentTitle?: string;
  position?: number;
  duration?: number;
  speed?: number;
  quality?: VideoQuality;
  mode?: PlaybackMode;
  audioTrack?: AudioTrack;
  subtitleTrack?: SubtitleTrack;
  error?: Error;
  bufferPercent?: number;
}

// 播放历史项接口
export interface PlaybackHistoryItem {
  id: string; // 唯一标识
  contentId: string; // 视频或直播ID
  contentTitle: string;
  contentType: 'video' | 'live';
  thumbnailUrl?: string;
  position: number; // 当前播放位置（毫秒）
  duration: number; // 总时长（毫秒）
  channelId?: string;
  channelName?: string;
  startedAt: number; // 首次开始播放时间
  lastPlayedAt: number; // 最后播放时间
  totalWatchTime: number; // 总观看时间（毫秒）
  isCompleted: boolean; // 是否已完成观看
  playCount: number; // 播放次数
  quality?: VideoQuality;
  speed?: PlaybackSpeed;
  tags?: string[];
}

// 播放设置接口
export interface PlaybackSettings {
  defaultQuality: VideoQuality;
  defaultSpeed: PlaybackSpeed;
  autoPlay: boolean;
  autoResume: boolean;
  rememberPosition: boolean;
  playNextAutomatically: boolean;
  enableHardwareAcceleration: boolean;
  enableBackgroundPlayback: boolean;
  enableDataSaving: boolean;
  preferredAudioLanguage: string;
  preferredSubtitleLanguage: string;
  subtitleEnabled: boolean;
  subtitleSize: number;
  subtitleColor: string;
  subtitleBackgroundColor: string;
  subtitleFont: string;
  lastUpdated: number;
}

// 播放统计接口
export interface PlaybackStats {
  totalWatchTime: number; // 总观看时长（毫秒）
  totalPlayCount: number; // 总播放次数
  watchedVideos: number; // 已观看的视频数量
  completedVideos: number; // 已完成的视频数量
  favoriteQuality: VideoQuality; // 最常用的画质
  favoriteSpeed: PlaybackSpeed; // 最常用的播放速度
  byQuality: Map<VideoQuality, number>; // 按画质统计观看时间
  bySpeed: Map<PlaybackSpeed, number>; // 按播放速度统计观看时间
  byContentType: Map<'video' | 'live', number>; // 按内容类型统计观看时间
  lastUpdated: number;
}

// 播放状态接口
export interface CurrentPlaybackState {
  contentId?: string;
  contentTitle?: string;
  contentType?: 'video' | 'live';
  state: PlaybackState;
  position: number;
  duration: number;
  speed: number;
  quality: VideoQuality;
  mode: PlaybackMode;
  audioTrack?: AudioTrack;
  subtitleTrack?: SubtitleTrack;
  bufferPercent: number;
  isMuted: boolean;
  volume: number;
  currentTime: number; // 状态记录时间
}

// 播放队列项接口
export interface PlaybackQueueItem {
  contentId: string;
  contentType: 'video' | 'live';
  title: string;
  thumbnailUrl?: string;
  channelId?: string;
  channelName?: string;
  duration?: number;
}

class PlaybackRepository {
  private static instance: PlaybackRepository;
  private readonly logger: Logger;
  private readonly storageUtil: StorageUtil;
  private readonly networkUtil: NetworkUtil;
  private readonly eventBus: EventBusUtil;
  private readonly cacheService: CacheService;
  private readonly userRepository: UserRepository;
  private readonly videoRepository: VideoRepository;
  
  // 存储键名
  private readonly storageKeys = {
    playbackSettings: 'playback_settings',
    playbackHistory: 'playback_history',
    playbackStats: 'playback_stats',
    currentPlaybackState: 'current_playback_state',
    playbackQueue: 'playback_queue',
    lastWatchPosition: 'last_watch_position'
  };
  
  // 数据缓存
  private playbackSettings: PlaybackSettings;
  private playbackHistory: Map<string, PlaybackHistoryItem>; // key: contentId
  private playbackStats: PlaybackStats;
  private currentPlaybackState: CurrentPlaybackState;
  private playbackQueue: PlaybackQueueItem[];
  
  // 过滤器缓存
  private filterCache: Map<string, any[]>;
  
  // 自动保存间隔（毫秒）
  private readonly autoSaveInterval = 30000; // 30秒
  
  // 自动保存计时器
  private autoSaveTimer: number | null = null;
  
  // 最大历史记录数量
  private readonly maxHistoryItems = 100;
  
  // 最大队列长度
  private readonly maxQueueLength = 50;
  
  private constructor() {
    this.logger = Logger.getInstance();
    this.storageUtil = StorageUtil.getInstance();
    this.networkUtil = NetworkUtil.getInstance();
    this.eventBus = EventBusUtil.getInstance();
    this.cacheService = CacheService.getInstance();
    this.userRepository = UserRepository.getInstance();
    this.videoRepository = VideoRepository.getInstance();
    
    // 初始化默认数据
    this.playbackSettings = this.getDefaultSettings();
    this.playbackHistory = new Map();
    this.playbackStats = this.getEmptyStats();
    this.currentPlaybackState = this.getEmptyPlaybackState();
    this.playbackQueue = [];
    this.filterCache = new Map();
    
    // 初始化
    this.initialize();
  }
  
  /**
   * 获取实例
   */
  public static getInstance(): PlaybackRepository {
    if (!PlaybackRepository.instance) {
      PlaybackRepository.instance = new PlaybackRepository();
    }
    return PlaybackRepository.instance;
  }
  
  /**
   * 初始化
   */
  private async initialize(): Promise<void> {
    try {
      // 加载设置
      await this.loadSettings();
      
      // 加载历史记录
      await this.loadHistory();
      
      // 加载统计
      await this.loadStats();
      
      // 加载当前播放状态
      await this.loadCurrentPlaybackState();
      
      // 加载播放队列
      await this.loadPlaybackQueue();
      
      // 启动自动保存
      this.startAutoSave();
      
      this.logger.info(`PlaybackRepository initialized with ${this.playbackHistory.size} history items`);
    } catch (error) {
      this.logger.error('Failed to initialize PlaybackRepository', error as Error);
    }
  }
  
  /**
   * 获取默认设置
   */
  private getDefaultSettings(): PlaybackSettings {
    return {
      defaultQuality: VideoQuality.HIGH,
      defaultSpeed: PlaybackSpeed.NORMAL,
      autoPlay: true,
      autoResume: true,
      rememberPosition: true,
      playNextAutomatically: true,
      enableHardwareAcceleration: true,
      enableBackgroundPlayback: true,
      enableDataSaving: false,
      preferredAudioLanguage: 'en',
      preferredSubtitleLanguage: 'en',
      subtitleEnabled: false,
      subtitleSize: 16,
      subtitleColor: '#FFFFFF',
      subtitleBackgroundColor: 'transparent',
      subtitleFont: 'default',
      lastUpdated: Date.now()
    };
  }
  
  /**
   * 获取空的统计数据
   */
  private getEmptyStats(): PlaybackStats {
    const byQuality = new Map<VideoQuality, number>();
    const bySpeed = new Map<PlaybackSpeed, number>();
    const byContentType = new Map<'video' | 'live', number>();
    
    // 初始化画质统计
    Object.values(VideoQuality).forEach(quality => {
      byQuality.set(quality, 0);
    });
    
    // 初始化播放速度统计
    Object.values(PlaybackSpeed).forEach(speed => {
      bySpeed.set(speed, 0);
    });
    
    // 初始化内容类型统计
    byContentType.set('video', 0);
    byContentType.set('live', 0);
    
    return {
      totalWatchTime: 0,
      totalPlayCount: 0,
      watchedVideos: 0,
      completedVideos: 0,
      favoriteQuality: VideoQuality.HIGH,
      favoriteSpeed: PlaybackSpeed.NORMAL,
      byQuality,
      bySpeed,
      byContentType,
      lastUpdated: Date.now()
    };
  }
  
  /**
   * 获取空的播放状态
   */
  private getEmptyPlaybackState(): CurrentPlaybackState {
    return {
      state: PlaybackState.IDLE,
      position: 0,
      duration: 0,
      speed: this.playbackSettings.defaultSpeed,
      quality: this.playbackSettings.defaultQuality,
      mode: PlaybackMode.DEFAULT,
      bufferPercent: 0,
      isMuted: false,
      volume: 1.0,
      currentTime: Date.now()
    };
  }
  
  /**
   * 加载设置
   */
  private async loadSettings(): Promise<void> {
    try {
      const settings = await this.storageUtil.getObject<PlaybackSettings>(
        this.storageKeys.playbackSettings,
        LocalStorageType.DEFAULT
      );
      
      if (settings) {
        this.playbackSettings = { ...this.getDefaultSettings(), ...settings };
      }
    } catch (error) {
      this.logger.error('Failed to load playback settings', error as Error);
      this.playbackSettings = this.getDefaultSettings();
    }
  }
  
  /**
   * 保存设置
   */
  private async saveSettings(): Promise<void> {
    try {
      this.playbackSettings.lastUpdated = Date.now();
      await this.storageUtil.setObject(
        this.storageKeys.playbackSettings,
        this.playbackSettings,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save playback settings', error as Error);
    }
  }
  
  /**
   * 加载历史记录
   */
  private async loadHistory(): Promise<void> {
    try {
      const historyData = await this.storageUtil.getObject<PlaybackHistoryItem[]>(
        this.storageKeys.playbackHistory,
        LocalStorageType.DEFAULT
      );
      
      if (historyData) {
        historyData.forEach(item => {
          this.playbackHistory.set(item.contentId, item);
        });
      }
    } catch (error) {
      this.logger.error('Failed to load playback history', error as Error);
      this.playbackHistory.clear();
    }
  }
  
  /**
   * 保存历史记录
   */
  private async saveHistory(): Promise<void> {
    try {
      // 转换为数组并按最后播放时间排序
      const historyArray = Array.from(this.playbackHistory.values())
        .sort((a, b) => b.lastPlayedAt - a.lastPlayedAt)
        .slice(0, this.maxHistoryItems); // 限制数量
      
      await this.storageUtil.setObject(
        this.storageKeys.playbackHistory,
        historyArray,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save playback history', error as Error);
    }
  }
  
  /**
   * 加载统计
   */
  private async loadStats(): Promise<void> {
    try {
      const statsData = await this.storageUtil.getObject<any>(
        this.storageKeys.playbackStats,
        LocalStorageType.DEFAULT
      );
      
      if (statsData) {
        // 还原Map数据
        const byQuality = new Map<VideoQuality, number>(statsData.byQuality || []);
        const bySpeed = new Map<PlaybackSpeed, number>(statsData.bySpeed || []);
        const byContentType = new Map<'video' | 'live', number>(statsData.byContentType || []);
        
        this.playbackStats = {
          ...this.getEmptyStats(),
          ...statsData,
          byQuality,
          bySpeed,
          byContentType
        };
      }
    } catch (error) {
      this.logger.error('Failed to load playback stats', error as Error);
      this.playbackStats = this.getEmptyStats();
    }
  }
  
  /**
   * 保存统计
   */
  private async saveStats(): Promise<void> {
    try {
      // 转换Map为数组以便存储
      const statsToSave = {
        ...this.playbackStats,
        byQuality: Array.from(this.playbackStats.byQuality.entries()),
        bySpeed: Array.from(this.playbackStats.bySpeed.entries()),
        byContentType: Array.from(this.playbackStats.byContentType.entries()),
        lastUpdated: Date.now()
      };
      
      await this.storageUtil.setObject(
        this.storageKeys.playbackStats,
        statsToSave,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save playback stats', error as Error);
    }
  }
  
  /**
   * 加载当前播放状态
   */
  private async loadCurrentPlaybackState(): Promise<void> {
    try {
      const state = await this.storageUtil.getObject<CurrentPlaybackState>(
        this.storageKeys.currentPlaybackState,
        LocalStorageType.DEFAULT
      );
      
      if (state) {
        this.currentPlaybackState = { ...this.getEmptyPlaybackState(), ...state };
      }
    } catch (error) {
      this.logger.error('Failed to load current playback state', error as Error);
      this.currentPlaybackState = this.getEmptyPlaybackState();
    }
  }
  
  /**
   * 保存当前播放状态
   */
  private async saveCurrentPlaybackState(): Promise<void> {
    try {
      this.currentPlaybackState.currentTime = Date.now();
      await this.storageUtil.setObject(
        this.storageKeys.currentPlaybackState,
        this.currentPlaybackState,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save current playback state', error as Error);
    }
  }
  
  /**
   * 加载播放队列
   */
  private async loadPlaybackQueue(): Promise<void> {
    try {
      const queue = await this.storageUtil.getObject<PlaybackQueueItem[]>(
        this.storageKeys.playbackQueue,
        LocalStorageType.DEFAULT
      );
      
      if (queue) {
        this.playbackQueue = queue;
      }
    } catch (error) {
      this.logger.error('Failed to load playback queue', error as Error);
      this.playbackQueue = [];
    }
  }
  
  /**
   * 保存播放队列
   */
  private async savePlaybackQueue(): Promise<void> {
    try {
      await this.storageUtil.setObject(
        this.storageKeys.playbackQueue,
        this.playbackQueue,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save playback queue', error as Error);
    }
  }
  
  /**
   * 启动自动保存
   */
  private startAutoSave(): void {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
    }
    
    this.autoSaveTimer = setInterval(() => {
      this.saveAllData();
    }, this.autoSaveInterval);
  }
  
  /**
   * 停止自动保存
   */
  private stopAutoSave(): void {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = null;
    }
  }
  
  /**
   * 保存所有数据
   */
  private async saveAllData(): Promise<void> {
    try {
      await Promise.all([
        this.saveSettings(),
        this.saveHistory(),
        this.saveStats(),
        this.saveCurrentPlaybackState(),
        this.savePlaybackQueue()
      ]);
    } catch (error) {
      this.logger.error('Failed to save all playback data', error as Error);
    }
  }
  
  /**
   * 清除过滤器缓存
   */
  private clearFilterCache(): void {
    this.filterCache.clear();
  }
  
  /**
   * 获取播放设置
   */
  public async getPlaybackSettings(): Promise<PlaybackSettings> {
    try {
      // 返回深拷贝
      return JSON.parse(JSON.stringify(this.playbackSettings));
    } catch (error) {
      this.logger.error('Failed to get playback settings', error as Error);
      return this.getDefaultSettings();
    }
  }
  
  /**
   * 更新播放设置
   */
  public async updatePlaybackSettings(
    settings: Partial<PlaybackSettings>
  ): Promise<boolean> {
    try {
      // 更新设置
      this.playbackSettings = {
        ...this.playbackSettings,
        ...settings,
        lastUpdated: Date.now()
      };
      
      // 保存设置
      await this.saveSettings();
      
      // 发布设置更新事件
      this.eventBus.emit(PlaybackEventType.PLAYBACK_SETTINGS_UPDATED, {
        type: PlaybackEventType.PLAYBACK_SETTINGS_UPDATED,
        timestamp: Date.now()
      } as PlaybackEvent);
      
      this.logger.info('Playback settings updated');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to update playback settings', error as Error);
      return false;
    }
  }
  
  /**
   * 重置播放设置
   */
  public async resetPlaybackSettings(): Promise<boolean> {
    try {
      this.playbackSettings = this.getDefaultSettings();
      await this.saveSettings();
      
      // 发布设置更新事件
      this.eventBus.emit(PlaybackEventType.PLAYBACK_SETTINGS_UPDATED, {
        type: PlaybackEventType.PLAYBACK_SETTINGS_UPDATED,
        timestamp: Date.now()
      } as PlaybackEvent);
      
      this.logger.info('Playback settings reset to default');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to reset playback settings', error as Error);
      return false;
    }
  }
  
  /**
   * 更新播放状态
   */
  public async updatePlaybackState(
    state: Partial<CurrentPlaybackState>
  ): Promise<boolean> {
    try {
      // 更新状态
      const oldState = { ...this.currentPlaybackState };
      this.currentPlaybackState = {
        ...this.currentPlaybackState,
        ...state,
        currentTime: Date.now()
      };
      
      // 保存状态
      await this.saveCurrentPlaybackState();
      
      // 处理特定状态变更
      if (state.state !== undefined && state.state !== oldState.state) {
        switch (state.state) {
          case PlaybackState.PLAYING:
            this.handlePlaybackStarted();
            break;
          case PlaybackState.PAUSED:
            this.handlePlaybackPaused();
            break;
          case PlaybackState.ENDED:
            this.handlePlaybackEnded();
            break;
          case PlaybackState.BUFFERING:
            this.handlePlaybackBuffering(state.bufferPercent || 0);
            break;
        }
      }
      
      // 处理播放位置更新
      if (state.position !== undefined && 
          state.contentId && 
          Math.abs(state.position - oldState.position) > 1000) { // 超过1秒的变化才处理
        
        // 检查是否是跳转
        if (Math.abs(state.position - (oldState.position + (Date.now() - oldState.currentTime))) > 5000) {
          this.handlePlaybackSeeked(state.position);
        } else {
          // 正常播放进度更新，更新历史记录
          if (this.playbackSettings.rememberPosition) {
            await this.updateWatchPosition(
              state.contentId,
              state.position,
              state.duration || oldState.duration
            );
          }
        }
      }
      
      // 处理播放速度变更
      if (state.speed !== undefined && state.speed !== oldState.speed) {
        this.handlePlaybackSpeedChanged(state.speed);
      }
      
      // 处理画质变更
      if (state.quality !== undefined && state.quality !== oldState.quality) {
        this.handlePlaybackQualityChanged(state.quality);
      }
      
      // 处理播放模式变更
      if (state.mode !== undefined && state.mode !== oldState.mode) {
        this.handlePlaybackModeChanged(state.mode);
      }
      
      // 处理音轨变更
      if (state.audioTrack && JSON.stringify(state.audioTrack) !== JSON.stringify(oldState.audioTrack)) {
        this.handleAudioTrackChanged(state.audioTrack);
      }
      
      // 处理字幕变更
      if (state.subtitleTrack && JSON.stringify(state.subtitleTrack) !== JSON.stringify(oldState.subtitleTrack)) {
        this.handleSubtitleTrackChanged(state.subtitleTrack);
      }
      
      return true;
    } catch (error) {
      this.logger.error('Failed to update playback state', error as Error);
      
      // 发布播放错误事件
      this.eventBus.emit(PlaybackEventType.PLAYBACK_ERROR, {
        type: PlaybackEventType.PLAYBACK_ERROR,
        timestamp: Date.now(),
        error: error as Error
      } as PlaybackEvent);
      
      return false;
    }
  }
  
  /**
   * 处理播放开始
   */
  private handlePlaybackStarted(): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布播放开始事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_STARTED, {
      type: PlaybackEventType.PLAYBACK_STARTED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      position: this.currentPlaybackState.position,
      duration: this.currentPlaybackState.duration,
      speed: this.currentPlaybackState.speed,
      quality: this.currentPlaybackState.quality
    } as PlaybackEvent);
    
    // 添加或更新历史记录
    this.addToPlaybackHistory(
      this.currentPlaybackState.contentId,
      this.currentPlaybackState.contentTitle || 'Unknown',
      this.currentPlaybackState.contentType || 'video',
      this.currentPlaybackState.position,
      this.currentPlaybackState.duration
    );
  }
  
  /**
   * 处理播放暂停
   */
  private handlePlaybackPaused(): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布播放暂停事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_PAUSED, {
      type: PlaybackEventType.PLAYBACK_PAUSED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      position: this.currentPlaybackState.position,
      duration: this.currentPlaybackState.duration
    } as PlaybackEvent);
  }
  
  /**
   * 处理播放恢复
   */
  private handlePlaybackResumed(): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布播放恢复事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_RESUMED, {
      type: PlaybackEventType.PLAYBACK_RESUMED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      position: this.currentPlaybackState.position,
      duration: this.currentPlaybackState.duration
    } as PlaybackEvent);
  }
  
  /**
   * 处理播放结束
   */
  private handlePlaybackEnded(): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 更新历史记录标记为已完成
    const historyItem = this.playbackHistory.get(this.currentPlaybackState.contentId);
    if (historyItem) {
      historyItem.isCompleted = true;
      historyItem.position = historyItem.duration;
      historyItem.lastPlayedAt = Date.now();
      
      // 保存历史记录
      this.saveHistory();
      
      // 更新统计
      this.playbackStats.completedVideos++;
      this.saveStats();
    }
    
    // 发布播放结束事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_ENDED, {
      type: PlaybackEventType.PLAYBACK_ENDED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      duration: this.currentPlaybackState.duration
    } as PlaybackEvent);
    
    // 自动播放下一个
    if (this.playbackSettings.playNextAutomatically) {
      this.playNextInQueue();
    }
  }
  
  /**
   * 处理播放跳转
   */
  private handlePlaybackSeeked(position: number): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布播放跳转事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_SEEKED, {
      type: PlaybackEventType.PLAYBACK_SEEKED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      position
    } as PlaybackEvent);
  }
  
  /**
   * 处理播放速度变更
   */
  private handlePlaybackSpeedChanged(speed: number): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布播放速度变更事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_SPEED_CHANGED, {
      type: PlaybackEventType.PLAYBACK_SPEED_CHANGED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      speed
    } as PlaybackEvent);
  }
  
  /**
   * 处理画质变更
   */
  private handlePlaybackQualityChanged(quality: VideoQuality): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布画质变更事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_QUALITY_CHANGED, {
      type: PlaybackEventType.PLAYBACK_QUALITY_CHANGED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      quality
    } as PlaybackEvent);
  }
  
  /**
   * 处理播放模式变更
   */
  private handlePlaybackModeChanged(mode: PlaybackMode): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布播放模式变更事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_MODE_CHANGED, {
      type: PlaybackEventType.PLAYBACK_MODE_CHANGED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      mode
    } as PlaybackEvent);
  }
  
  /**
   * 处理音轨变更
   */
  private handleAudioTrackChanged(audioTrack: AudioTrack): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布音轨变更事件
    this.eventBus.emit(PlaybackEventType.AUDIO_TRACK_CHANGED, {
      type: PlaybackEventType.AUDIO_TRACK_CHANGED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      audioTrack
    } as PlaybackEvent);
  }
  
  /**
   * 处理字幕变更
   */
  private handleSubtitleTrackChanged(subtitleTrack: SubtitleTrack): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布字幕变更事件
    this.eventBus.emit(PlaybackEventType.SUBTITLE_TRACK_CHANGED, {
      type: PlaybackEventType.SUBTITLE_TRACK_CHANGED,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      subtitleTrack
    } as PlaybackEvent);
  }
  
  /**
   * 处理播放缓冲
   */
  private handlePlaybackBuffering(bufferPercent: number): void {
    if (!this.currentPlaybackState.contentId) return;
    
    // 发布播放缓冲事件
    this.eventBus.emit(PlaybackEventType.PLAYBACK_BUFFERING, {
      type: PlaybackEventType.PLAYBACK_BUFFERING,
      timestamp: Date.now(),
      contentId: this.currentPlaybackState.contentId,
      contentTitle: this.currentPlaybackState.contentTitle,
      bufferPercent
    } as PlaybackEvent);
  }
  
  /**
   * 添加到播放历史
   */
  private async addToPlaybackHistory(
    contentId: string,
    contentTitle: string,
    contentType: 'video' | 'live',
    position: number,
    duration: number
  ): Promise<void> {
    try {
      let historyItem = this.playbackHistory.get(contentId);
      
      if (historyItem) {
        // 更新现有历史记录
        historyItem.lastPlayedAt = Date.now();
        historyItem.position = position;
        historyItem.duration = duration;
        historyItem.playCount++;
        historyItem.isCompleted = position >= duration * 0.95; // 观看95%以上视为完成
        
        // 更新统计
        this.playbackStats.totalPlayCount++;
        
        // 发布历史更新事件
        this.eventBus.emit(PlaybackEventType.PLAYBACK_HISTORY_UPDATED, {
          type: PlaybackEventType.PLAYBACK_HISTORY_UPDATED,
          timestamp: Date.now(),
          contentId,
          contentTitle
        } as PlaybackEvent);
      } else {
        // 创建新的历史记录
        historyItem = {
          id: `playback_history_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          contentId,
          contentTitle,
          contentType,
          position,
          duration,
          startedAt: Date.now(),
          lastPlayedAt: Date.now(),
          totalWatchTime: 0,
          isCompleted: position >= duration * 0.95,
          playCount: 1,
          quality: this.currentPlaybackState.quality,
          speed: this.currentPlaybackState.speed
        };
        
        this.playbackHistory.set(contentId, historyItem);
        
        // 更新统计
        this.playbackStats.totalPlayCount++;
        this.playbackStats.watchedVideos++;
        if (historyItem.isCompleted) {
          this.playbackStats.completedVideos++;
        }
        
        // 发布历史添加事件
        this.eventBus.emit(PlaybackEventType.PLAYBACK_HISTORY_ADDED, {
          type: PlaybackEventType.PLAYBACK_HISTORY_ADDED,
          timestamp: Date.now(),
          contentId,
          contentTitle
        } as PlaybackEvent);
      }
      
      // 保存历史记录
      await this.saveHistory();
      await this.saveStats();
      
      // 清理过期历史记录
      if (this.playbackHistory.size > this.maxHistoryItems) {
        this.cleanupOldHistory();
      }
    } catch (error) {
      this.logger.error('Failed to add to playback history', error as Error);
    }
  }
  
  /**
   * 更新观看位置
   */
  public async updateWatchPosition(
    contentId: string,
    position: number,
    duration: number
  ): Promise<boolean> {
    try {
      const historyItem = this.playbackHistory.get(contentId);
      
      if (historyItem) {
        // 更新观看位置
        historyItem.position = position;
        historyItem.duration = duration;
        historyItem.lastPlayedAt = Date.now();
        
        // 计算新增的观看时间（简化计算）
        const watchTimeDiff = Math.min(
          Math.abs(position - historyItem.position),
          10000 // 最大计算10秒的增量，避免跳转导致的异常值
        );
        
        if (watchTimeDiff > 0) {
          historyItem.totalWatchTime += watchTimeDiff;
          
          // 更新统计
          this.playbackStats.totalWatchTime += watchTimeDiff;
          
          // 更新内容类型统计
          const contentType = historyItem.contentType || 'video';
          const currentTypeTime = this.playbackStats.byContentType.get(contentType) || 0;
          this.playbackStats.byContentType.set(contentType, currentTypeTime + watchTimeDiff);
          
          // 更新画质统计
          if (historyItem.quality) {
            const currentQualityTime = this.playbackStats.byQuality.get(historyItem.quality) || 0;
            this.playbackStats.byQuality.set(historyItem.quality, currentQualityTime + watchTimeDiff);
          }
          
          // 更新播放速度统计
          if (historyItem.speed) {
            const currentSpeedTime = this.playbackStats.bySpeed.get(historyItem.speed) || 0;
            this.playbackStats.bySpeed.set(historyItem.speed, currentSpeedTime + watchTimeDiff);
          }
        }
        
        // 保存数据
        await this.saveHistory();
        await this.saveStats();
        
        return true;
      }
      
      return false;
    } catch (error) {
      this.logger.error(`Failed to update watch position for ${contentId}`, error as Error);
      return false;
    }
  }
  
  /**
   * 获取观看历史
   */
  public async getPlaybackHistory(options?: {
    limit?: number;
    offset?: number;
    contentType?: 'video' | 'live';
    includeCompleted?: boolean;
    includeUncompleted?: boolean;
  }): Promise<PlaybackHistoryItem[]> {
    try {
      const { 
        limit = 20,
        offset = 0,
        contentType,
        includeCompleted = true,
        includeUncompleted = true
      } = options || {};
      
      // 生成缓存键
      const cacheKey = `history_${limit}_${offset}_${contentType || 'all'}_${includeCompleted}_${includeUncompleted}`;
      
      // 检查缓存
      if (this.filterCache.has(cacheKey)) {
        return this.filterCache.get(cacheKey)!;
      }
      
      // 过滤历史记录
      let historyItems = Array.from(this.playbackHistory.values()).filter(item => {
        // 内容类型过滤
        if (contentType && item.contentType !== contentType) {
          return false;
        }
        
        // 完成状态过滤
        if (!includeCompleted && item.isCompleted) {
          return false;
        }
        
        if (!includeUncompleted && !item.isCompleted) {
          return false;
        }
        
        return true;
      });
      
      // 按最后播放时间排序
      historyItems = historyItems.sort((a, b) => b.lastPlayedAt - a.lastPlayedAt);
      
      // 分页
      const result = historyItems.slice(offset, offset + limit);
      
      // 缓存结果
      this.filterCache.set(cacheKey, result);
      
      // 返回深拷贝
      return JSON.parse(JSON.stringify(result));
    } catch (error) {
      this.logger.error('Failed to get playback history', error as Error);
      return [];
    }
  }
  
  /**
   * 获取历史记录项
   */
  public async getPlaybackHistoryItem(contentId: string): Promise<PlaybackHistoryItem | null> {
    try {
      const item = this.playbackHistory.get(contentId);
      return item ? JSON.parse(JSON.stringify(item)) : null;
    } catch (error) {
      this.logger.error(`Failed to get playback history item for ${contentId}`, error as Error);
      return null;
    }
  }
  
  /**
   * 删除历史记录项
   */
  public async removePlaybackHistoryItem(contentId: string): Promise<boolean> {
    try {
      const removed = this.playbackHistory.delete(contentId);
      
      if (removed) {
        // 清除缓存
        this.clearFilterCache();
        
        // 保存历史记录
        await this.saveHistory();
        
        this.logger.info(`Removed playback history item: ${contentId}`);
      }
      
      return removed;
    } catch (error) {
      this.logger.error(`Failed to remove playback history item for ${contentId}`, error as Error);
      return false;
    }
  }
  
  /**
   * 清空播放历史
   */
  public async clearPlaybackHistory(): Promise<boolean> {
    try {
      this.playbackHistory.clear();
      
      // 清除缓存
      this.clearFilterCache();
      
      // 保存历史记录
      await this.saveHistory();
      
      // 重置相关统计
      this.playbackStats.watchedVideos = 0;
      this.playbackStats.completedVideos = 0;
      await this.saveStats();
      
      // 发布历史清空事件
      this.eventBus.emit(PlaybackEventType.PLAYBACK_HISTORY_CLEARED, {
        type: PlaybackEventType.PLAYBACK_HISTORY_CLEARED,
        timestamp: Date.now()
      } as PlaybackEvent);
      
      this.logger.info('Playback history cleared');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to clear playback history', error as Error);
      return false;
    }
  }
  
  /**
   * 清理旧历史记录
   */
  private async cleanupOldHistory(): Promise<void> {
    try {
      // 按最后播放时间排序，保留最新的N条
      const sortedHistory = Array.from(this.playbackHistory.values())
        .sort((a, b) => b.lastPlayedAt - a.lastPlayedAt);
      
      // 获取需要保留的内容ID
      const keepContentIds = new Set(
        sortedHistory.slice(0, this.maxHistoryItems).map(item => item.contentId)
      );
      
      // 删除过期的历史记录
      for (const contentId of this.playbackHistory.keys()) {
        if (!keepContentIds.has(contentId)) {
          this.playbackHistory.delete(contentId);
        }
      }
      
      // 清除缓存
      this.clearFilterCache();
      
      // 保存历史记录
      await this.saveHistory();
      
      this.logger.info(`Cleaned up old playback history, keeping ${this.maxHistoryItems} items`);
    } catch (error) {
      this.logger.error('Failed to cleanup old playback history', error as Error);
    }
  }
  
  /**
   * 获取播放队列
   */
  public async getPlaybackQueue(): Promise<PlaybackQueueItem[]> {
    try {
      // 返回深拷贝
      return JSON.parse(JSON.stringify(this.playbackQueue));
    } catch (error) {
      this.logger.error('Failed to get playback queue', error as Error);
      return [];
    }
  }
  
  /**
   * 添加到播放队列
   */
  public async addToPlaybackQueue(item: PlaybackQueueItem): Promise<boolean> {
    try {
      // 检查是否已存在
      const exists = this.playbackQueue.some(q => q.contentId === item.contentId);
      if (!exists) {
        // 添加到队列
        this.playbackQueue.push(item);
        
        // 限制队列长度
        if (this.playbackQueue.length > this.maxQueueLength) {
          this.playbackQueue.shift(); // 移除最前面的项
        }
        
        // 保存队列
        await this.savePlaybackQueue();
        
        return true;
      }
      
      return false;
    } catch (error) {
      this.logger.error('Failed to add to playback queue', error as Error);
      return false;
    }
  }
  
  /**
   * 批量添加到播放队列
   */
  public async addMultipleToPlaybackQueue(items: PlaybackQueueItem[]): Promise<number> {
    try {
      let addedCount = 0;
      
      for (const item of items) {
        const added = await this.addToPlaybackQueue(item);
        if (added) {
          addedCount++;
        }
      }
      
      return addedCount;
    } catch (error) {
      this.logger.error('Failed to add multiple items to playback queue', error as Error);
      return 0;
    }
  }
  
  /**
   * 从播放队列中移除
   */
  public async removeFromPlaybackQueue(contentId: string): Promise<boolean> {
    try {
      const initialLength = this.playbackQueue.length;
      this.playbackQueue = this.playbackQueue.filter(item => item.contentId !== contentId);
      
      const removed = initialLength !== this.playbackQueue.length;
      
      if (removed) {
        // 保存队列
        await this.savePlaybackQueue();
      }
      
      return removed;
    } catch (error) {
      this.logger.error(`Failed to remove from playback queue: ${contentId}`, error as Error);
      return false;
    }
  }
  
  /**
   * 清空播放队列
   */
  public async clearPlaybackQueue(): Promise<boolean> {
    try {
      this.playbackQueue = [];
      
      // 保存队列
      await this.savePlaybackQueue();
      
      return true;
    } catch (error) {
      this.logger.error('Failed to clear playback queue', error as Error);
      return false;
    }
  }
  
  /**
   * 播放队列中的下一个
   */
  public async playNextInQueue(): Promise<PlaybackQueueItem | null> {
    try {
      if (this.playbackQueue.length === 0) {
        return null;
      }
      
      // 获取并移除队列中的第一个项
      const nextItem = this.playbackQueue.shift();
      
      if (nextItem) {
        // 保存队列
        await this.savePlaybackQueue();
        
        // 更新当前播放状态
        await this.updatePlaybackState({
          contentId: nextItem.contentId,
          contentTitle: nextItem.title,
          contentType: nextItem.contentType,
          state: PlaybackState.PLAYING,
          position: 0,
          duration: nextItem.duration || 0
        });
      }
      
      return nextItem || null;
    } catch (error) {
      this.logger.error('Failed to play next item in queue', error as Error);
      return null;
    }
  }
  
  /**
   * 获取播放统计
   */
  public async getPlaybackStats(): Promise<PlaybackStats> {
    try {
      // 返回深拷贝
      return JSON.parse(JSON.stringify(this.playbackStats));
    } catch (error) {
      this.logger.error('Failed to get playback stats', error as Error);
      return this.getEmptyStats();
    }
  }
  
  /**
   * 重置播放统计
   */
  public async resetPlaybackStats(): Promise<boolean> {
    try {
      this.playbackStats = this.getEmptyStats();
      
      // 保存统计
      await this.saveStats();
      
      return true;
    } catch (error) {
      this.logger.error('Failed to reset playback stats', error as Error);
      return false;
    }
  }
  
  /**
   * 计算下一个推荐的视频质量
   */
  public getRecommendedQuality(): VideoQuality {
    try {
      // 检查网络状态
      const networkType = this.networkUtil.getNetworkType();
      const isDataSavingEnabled = this.playbackSettings.enableDataSaving;
      
      // 根据网络类型和数据节省设置推荐质量
      if (networkType === 'wifi') {
        if (isDataSavingEnabled) {
          return VideoQuality.MEDIUM;
        }
        return VideoQuality.HIGH;
      } else if (networkType === '4g') {
        if (isDataSavingEnabled) {
          return VideoQuality.LOW;
        }
        return VideoQuality.MEDIUM;
      } else if (networkType === '3g') {
        return VideoQuality.LOW;
      } else {
        return VideoQuality.LOWEST;
      }
    } catch (error) {
      this.logger.error('Failed to get recommended quality', error as Error);
      return this.playbackSettings.defaultQuality;
    }
  }
  
  /**
   * 导出播放数据
   */
  public async exportPlaybackData(): Promise<Record<string, any>> {
    try {
      const exportData = {
        version: '1.0.0',
        exportedAt: Date.now(),
        settings: this.playbackSettings,
        history: Array.from(this.playbackHistory.values()),
        stats: this.playbackStats,
        queue: this.playbackQueue
      };
      
      this.logger.info('Exported playback data');
      
      return exportData;
    } catch (error) {
      this.logger.error('Failed to export playback data', error as Error);
      throw error;
    }
  }
  
  /**
   * 导入播放数据
   */
  public async importPlaybackData(
    data: Record<string, any>,
    options?: {
      importSettings?: boolean;
      importHistory?: boolean;
      importStats?: boolean;
      importQueue?: boolean;
      overwrite?: boolean;
    }
  ): Promise<{ 
    importedSettings?: boolean;
    importedHistory: number;
    importedStats?: boolean;
    importedQueue: number;
    errors: string[];
  }> {
    try {
      const { 
        importSettings = true,
        importHistory = true,
        importStats = true,
        importQueue = true,
        overwrite = false
      } = options || {};
      
      const errors: string[] = [];
      let result = {
        importedSettings: false,
        importedHistory: 0,
        importedStats: false,
        importedQueue: 0,
        errors
      };
      
      // 导入设置
      if (importSettings && data.settings) {
        try {
          if (overwrite) {
            this.playbackSettings = { ...this.getDefaultSettings(), ...data.settings };
          } else {
            this.playbackSettings = { ...this.playbackSettings, ...data.settings };
          }
          this.playbackSettings.lastUpdated = Date.now();
          await this.saveSettings();
          result.importedSettings = true;
        } catch (err) {
          errors.push(`Failed to import settings: ${err.message}`);
        }
      }
      
      // 导入历史记录
      if (importHistory && data.history && Array.isArray(data.history)) {
        try {
          if (overwrite) {
            this.playbackHistory.clear();
          }
          
          data.history.forEach(item => {
            this.playbackHistory.set(item.contentId, item);
          });
          
          result.importedHistory = data.history.length;
          
          // 清理旧历史记录
          await this.cleanupOldHistory();
        } catch (err) {
          errors.push(`Failed to import history: ${err.message}`);
        }
      }
      
      // 导入统计
      if (importStats && data.stats) {
        try {
          if (overwrite) {
            this.playbackStats = this.getEmptyStats();
          }
          
          // 合并统计数据
          this.playbackStats.totalWatchTime += data.stats.totalWatchTime || 0;
          this.playbackStats.totalPlayCount += data.stats.totalPlayCount || 0;
          this.playbackStats.watchedVideos += data.stats.watchedVideos || 0;
          this.playbackStats.completedVideos += data.stats.completedVideos || 0;
          
          this.playbackStats.lastUpdated = Date.now();
          await this.saveStats();
          result.importedStats = true;
        } catch (err) {
          errors.push(`Failed to import stats: ${err.message}`);
        }
      }
      
      // 导入播放队列
      if (importQueue && data.queue && Array.isArray(data.queue)) {
        try {
          if (overwrite) {
            this.playbackQueue = [];
          }
          
          data.queue.forEach(item => {
            // 检查是否已存在
            if (!this.playbackQueue.some(q => q.contentId === item.contentId)) {
              this.playbackQueue.push(item);
            }
          });
          
          // 限制队列长度
          if (this.playbackQueue.length > this.maxQueueLength) {
            this.playbackQueue = this.playbackQueue.slice(-this.maxQueueLength);
          }
          
          result.importedQueue = data.queue.length;
          await this.savePlaybackQueue();
        } catch (err) {
          errors.push(`Failed to import queue: ${err.message}`);
        }
      }
      
      // 清除缓存
      this.clearFilterCache();
      
      this.logger.info('Imported playback data');
      
      return result;
    } catch (error) {
      this.logger.error('Failed to import playback data', error as Error);
      throw error;
    }
  }
  
  /**
   * 清空所有数据
   */
  public async clearAllData(): Promise<boolean> {
    try {
      // 清空所有数据
      this.playbackSettings = this.getDefaultSettings();
      this.playbackHistory.clear();
      this.playbackStats = this.getEmptyStats();
      this.currentPlaybackState = this.getEmptyPlaybackState();
      this.playbackQueue = [];
      
      // 清除缓存
      this.clearFilterCache();
      
      // 清除存储
      await Promise.all([
        this.storageUtil.remove(this.storageKeys.playbackSettings, LocalStorageType.DEFAULT),
        this.storageUtil.remove(this.storageKeys.playbackHistory, LocalStorageType.DEFAULT),
        this.storageUtil.remove(this.storageKeys.playbackStats, LocalStorageType.DEFAULT),
        this.storageUtil.remove(this.storageKeys.currentPlaybackState, LocalStorageType.DEFAULT),
        this.storageUtil.remove(this.storageKeys.playbackQueue, LocalStorageType.DEFAULT)
      ]);
      
      this.logger.info('All playback data cleared');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to clear all playback data', error as Error);
      return false;
    }
  }
  
  /**
   * 销毁播放仓库
   */
  public async destroy(): Promise<void> {
    try {
      // 停止自动保存
      this.stopAutoSave();
      
      // 保存数据
      await this.saveAllData();
      
      // 清除缓存
      this.filterCache.clear();
      
      // 移除事件监听器
      // 注意：在实际应用中，需要移除所有添加的事件监听器
      
      this.logger.info('PlaybackRepository destroyed');
    } catch (error) {
      this.logger.error('Failed to destroy PlaybackRepository', error as Error);
    }
  }
}

// 导出PlaybackEventType常量
export { PlaybackEventType };

export default PlaybackRepository;