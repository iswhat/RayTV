// 播放仓库�?- 管理播放相关的数据操�?import Logger from '../utils/Logger';
import StorageUtil from '../utils/StorageUtil';
import NetworkUtil from '../utils/NetworkUtil';
import EventBusUtil from '../utils/EventBusUtil';
import CacheService from '../service/CacheService';
import UserRepository from './UserRepository';
import VideoRepository from './VideoRepository';
import { LocalStorageType, CacheType } from '../model/commonTypes';

// 播放状态枚�?export enum PlaybackState {
  IDLE = 'idle',
  LOADING = 'loading',
  PLAYING = 'playing',
  PAUSED = 'paused',
  BUFFERING = 'buffering',
  ENDED = 'ended',
  ERROR = 'error'
}

// 视频质量枚举
export enum VideoQuality {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  HD = 'hd',
  FHD = 'fhd',
  UHD = 'uhd'
}

// 播放速度枚举
export enum PlaybackSpeed {
  QUARTER = 0.25,
  HALF = 0.5,
  NORMAL = 1.0,
  ONE_QUARTER = 1.25,
  ONE_HALF = 1.5,
  DOUBLE = 2.0
}

// 播放模式枚举
export enum PlaybackMode {
  DEFAULT = 'default',
  LOOP = 'loop',
  SHUFFLE = 'shuffle'
}

// 音频轨道接口
export interface AudioTrack {
  id: string;
  language: string;
  label: string;
  isDefault: boolean;
}

// 字幕轨道接口
export interface SubtitleTrack {
  id: string;
  language: string;
  label: string;
  isDefault: boolean;
}

// 播放事件接口
export interface PlaybackEvent {
  type: string;
  timestamp: number;
  data?: Record<string, unknown>;
}

// 播放历史项接�?export interface PlaybackHistoryItem {
  contentId: string;
  contentType: 'video' | 'live';
  title: string;
  thumbnailUrl?: string;
  channelId?: string;
  channelName?: string;
  duration: number;
  position: number; // 最后观看位�?  lastPlayedAt: number;
  playCount: number;
  isCompleted: boolean;
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
  totalWatchTime: number;
  totalPlayCount: number;
  watchedVideos: number;
  completedVideos: number;
  favoriteQuality: VideoQuality;
  favoriteSpeed: PlaybackSpeed;
  byQuality: Map<VideoQuality, number>;
  bySpeed: Map<PlaybackSpeed, number>;
  byContentType: Map<'video' | 'live', number>;
  lastUpdated: number;
}

// 当前播放状态接�?export interface CurrentPlaybackState {
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
  currentTime: number; // 状态记录时�?}

// 播放队列项接�?export interface PlaybackQueueItem {
  contentId: string;
  contentType: 'video' | 'live';
  title: string;
  thumbnailUrl?: string;
  channelId?: string;
  channelName?: string;
  duration?: number;
}

export class PlaybackRepository {
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
  
  // 过滤器缓�?  private filterCache: Map<string, unknown[]>;
  
  // 自动保存间隔（毫秒）
  private readonly autoSaveInterval = 30000; // 30�?  
  // 自动保存计时�?  private autoSaveTimer: number | null = null;
  
  // 最大历史记录数�?  private readonly maxHistoryItems = 100;
  
  // 最大队列长�?  private readonly maxQueueLength = 50;
  
  private constructor() {
    this.logger = Logger.getInstance();
    this.storageUtil = StorageUtil.getInstance();
    this.networkUtil = NetworkUtil.getInstance();
    this.eventBus = EventBusUtil.getInstance();
    this.cacheService = CacheService.getInstance();
    this.userRepository = UserRepository.getInstance();
    this.videoRepository = VideoRepository.getInstance();
    
    // 初始化默认数�?    this.playbackSettings = this.getDefaultSettings();
    this.playbackHistory = new Map();
    this.playbackStats = this.getEmptyStats();
    this.currentPlaybackState = this.getEmptyPlaybackState();
    this.playbackQueue = [];
    this.filterCache = new Map();
    
    // 初始�?    this.initialize();
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
   * 检查对象是否包含指定属�?   * 替代Object.prototype.hasOwnProperty.call，兼容ArkTS语法
   */
  private hasOwnProperty<T extends object>(obj: T, key: string): boolean {
    return Object.getOwnPropertyNames(obj).includes(key);
  }

  /**
   * 获取对象的所有�?   * 替代Object.values，兼容ArkTS语法
   */
  private getObjectValues<T extends object>(obj: T): Record<string, string | number | boolean | null>[] {
    const values: Record<string, string | number | boolean | null>[] = [];
    for (const key in obj) {
      if (this.hasOwnProperty(obj, key)) {
        values.push(obj[key]);
      }
    }
    return values;
  }
  
  /**
   * 初始�?   */
  public async initialize(): Promise<void> {
    try {
      // 加载设置
      await this.loadSettings();
      
      // 加载历史记录
      await this.loadHistory();
      
      // 加载统计
      await this.loadStats();
      
      // 加载当前播放状�?      await this.loadCurrentPlaybackState();
      
      // 加载播放队列
      await this.loadPlaybackQueue();
      
      // 启动自动保存
      this.startAutoSave();
      
      this.logger.info(`PlaybackRepository initialized with ${this.playbackHistory.size} history items`);
    } catch (error) {
      this.Logger.error('Failed to initialize PlaybackRepository', error as Error);
    }
  }
  
  /**
   * 获取默认设置
   */
  private getDefaultSettings(): PlaybackSettings {
    return {
      defaultQuality: VideoQuality.HIGH, defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( instanceof Error ? defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now( : new Error(String(defaultSpeed: PlaybackSpeed.NORMAL,
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
      lastUpdated: Date.now()))))))
    };
  }
  
  /**
   * 获取空的统计数据
   */
  private getEmptyStats(): PlaybackStats {
    const byQuality = new Map<VideoQuality, number>();
    const bySpeed = new Map<PlaybackSpeed, number>();
    const byContentType = new Map<'video' | 'live', number>();
    
    // 初始化画质统�?    this.getObjectValues(VideoQuality).forEach(quality => {
      byQuality.set(quality, 0);
    });
    
    // 初始化播放速度统计
    this.getObjectValues(PlaybackSpeed).forEach(speed => {
      bySpeed.set(speed, 0);
    });
    
    // 初始化内容类型统�?    byContentType.set('video', 0);
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
   * 获取空的播放状�?   */
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
      this.Logger.error('Failed to load playback settings', error as Error);
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
        this.storageKeys.playbackSettings, this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackSettings,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackSettings,
        LocalStorageType.DEFAULT
      )))))));
    } catch (error) {
      this.Logger.error('Failed to save playback settings', error as Error);
    }
  }
  
  /**
   * 加载历史记录
   */
  private async loadHistory(): Promise<void> {
    try {
      const historyData = await this.storageUtil.getObject<PlaybackHistoryItem[]>(
        this.storageKeys.playbackHistory, LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
      )))))));
      
      if (historyData) {
        historyData.forEach(item => {
          this.playbackHistory.set(item.contentId, item);
        });
      }
    } catch (error) {
      this.Logger.error('Failed to load playback history', error as Error);
      this.playbackHistory.clear();
    }
  }
  
  /**
   * 保存历史记录
   */
  private async saveHistory(): Promise<void> {
    try {
      // 转换为数组并按最后播放时间排�?      const historyArray = Array.from(this.playbackHistory.values())
        .sort((a, b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b instanceof Error ? b instanceof Error ? b : new Error(String(b : new Error(String(b instanceof Error ? b : new Error(String(b))))))) => b.lastPlayedAt - a.lastPlayedAt)
        .slice(0, this.maxHistoryItems);
      
      await this.storageUtil.setObject(
        this.storageKeys.playbackHistory,
        historyArray,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.Logger.error('Failed to save playback history', error as Error);
    }
  }
  
  /**
   * 加载统计
   */
  private async loadStats(): Promise<void> {
    try {
      const stats = await this.storageUtil.getObject<PlaybackStats>(
        this.storageKeys.playbackStats, LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
      )))))));
      
      if (stats) {
        this.playbackStats = { ...this.getEmptyStats(), ...stats };
      }
    } catch (error) {
      this.Logger.error('Failed to load playback stats', error as Error);
      this.playbackStats = this.getEmptyStats();
    }
  }
  
  /**
   * 保存统计
   */
  private async saveStats(): Promise<void> {
    try {
      this.playbackStats.lastUpdated = Date.now();
      await this.storageUtil.setObject(
        this.storageKeys.playbackStats, this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackStats,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackStats,
        LocalStorageType.DEFAULT
      )))))));
    } catch (error) {
      this.Logger.error('Failed to save playback stats', error as Error);
    }
  }
  
  /**
   * 加载当前播放状�?   */
  private async loadCurrentPlaybackState(): Promise<void> {
    try {
      const state = await this.storageUtil.getObject<CurrentPlaybackState>(
        this.storageKeys.currentPlaybackState, LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
      )))))));
      
      if (state) {
        this.currentPlaybackState = { ...this.getEmptyPlaybackState(), ...state };
      }
    } catch (error) {
      this.Logger.error('Failed to load current playback state', error as Error);
      this.currentPlaybackState = this.getEmptyPlaybackState();
    }
  }
  
  /**
   * 保存当前播放状�?   */
  private async saveCurrentPlaybackState(): Promise<void> {
    try {
      this.currentPlaybackState.currentTime = Date.now();
      await this.storageUtil.setObject(
        this.storageKeys.currentPlaybackState, this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
       instanceof Error ? this.currentPlaybackState,
        LocalStorageType.DEFAULT
       : new Error(String(this.currentPlaybackState,
        LocalStorageType.DEFAULT
      )))))));
    } catch (error) {
      this.Logger.error('Failed to save current playback state', error as Error);
    }
  }
  
  /**
   * 加载播放队列
   */
  private async loadPlaybackQueue(): Promise<void> {
    try {
      const queue = await this.storageUtil.getObject<PlaybackQueueItem[]>(
        this.storageKeys.playbackQueue, LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
       instanceof Error ? LocalStorageType.DEFAULT
       : new Error(String(LocalStorageType.DEFAULT
      )))))));
      
      if (queue) {
        this.playbackQueue = queue.slice(0, this.maxQueueLength);
      }
    } catch (error) {
      this.Logger.error('Failed to load playback queue', error as Error);
      this.playbackQueue = [];
    }
  }
  
  /**
   * 保存播放队列
   */
  private async savePlaybackQueue(): Promise<void> {
    try {
      await this.storageUtil.setObject(
        this.storageKeys.playbackQueue, this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
       instanceof Error ? this.playbackQueue,
        LocalStorageType.DEFAULT
       : new Error(String(this.playbackQueue,
        LocalStorageType.DEFAULT
      )))))));
    } catch (error) {
      this.Logger.error('Failed to save playback queue', error as Error);
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
      this.autoSave();
    }, this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval instanceof Error ? this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval : new Error(String(this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval instanceof Error ? this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval instanceof Error ? this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval : new Error(String(this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval : new Error(String(this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval instanceof Error ? this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval : new Error(String(this.autoSaveInterval instanceof Error ? this.autoSaveInterval : new Error(String(this.autoSaveInterval))))))) as unknown as number;
  }
  
  /**
   * 自动保存
   */
  private async autoSave(): Promise<void> {
    try {
      await Promise.all([
        this.saveSettings(),
        this.saveHistory(),
        this.saveStats(),
        this.saveCurrentPlaybackState(),
        this.savePlaybackQueue()
      ]);
      
      this.logger.debug('Playback data auto-saved');
    } catch (error) {
      this.Logger.error('Failed to auto-save playback data', error as Error);
    }
  }
  
  /**
   * 获取播放设置
   */
  public getPlaybackSettings(): PlaybackSettings {
    return { ...this.playbackSettings };
  }
  
  /**
   * 更新播放设置
   */
  public async updatePlaybackSettings(settings: Partial<PlaybackSettings>): Promise<void> {
    this.playbackSettings = { ...this.playbackSettings, ...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now( instanceof Error ? ...settings };
    this.playbackSettings.lastUpdated = Date.now( : new Error(String(...settings };
    this.playbackSettings.lastUpdated = Date.now()))))));
    
    await this.saveSettings();
    
    // 发布设置更新事件
    this.eventBus.publish('playback_settings_updated', {
      settings: this.playbackSettings
    });
  }
  
  /**
   * 获取播放历史
   */
  public getPlaybackHistory(): PlaybackHistoryItem[] {
    return Array.from(this.playbackHistory.values())
      .sort((a, b) => b.lastPlayedAt - a.lastPlayedAt);
  }
  
  /**
   * 添加播放历史记录
   */
  public async addPlaybackHistory(item: Omit<PlaybackHistoryItem, 'playCount' | 'lastPlayedAt' | 'isCompleted'>): Promise<void> {
    const existingItem = this.playbackHistory.get(item.contentId);
    const now = Date.now();
    
    const historyItem: PlaybackHistoryItem = {
      ...item,
      playCount: (existingItem?.playCount || 0) + 1,
      lastPlayedAt: now,
      isCompleted: item.position >= item.duration * 0.95 // 观看进度超过95%视为完成
    };
    
    this.playbackHistory.set(item.contentId, historyItem);
    
    // 更新统计
    this.updateStats(historyItem);
    
    // 保存历史记录
    await this.saveHistory();
    
    // 发布历史记录更新事件
    this.eventBus.publish('playback_history_updated', {
      item: historyItem,
      action: 'add'
    });
  }
  
  /**
   * 更新播放历史记录
   */
  public async updatePlaybackHistory(contentId: string, updates: Partial<PlaybackHistoryItem>): Promise<void> {
    const existingItem = this.playbackHistory.get(contentId);
    if (!existingItem) {
      return;
    }
    
    const updatedItem: Record<string, string | number | boolean | null> = { ... };
    this.playbackHistory.set(contentId, updatedItem);
    
    await this.saveHistory();
    
    // 发布历史记录更新事件
    this.eventBus.publish('playback_history_updated', {
      item: updatedItem,
      action: 'update'
    });
  }
  
  /**
   * 删除播放历史记录
   */
  public async deletePlaybackHistory(contentId: string): Promise<void> {
    const deletedItem = this.playbackHistory.get(contentId);
    if (!deletedItem) {
      return;
    }
    
    this.playbackHistory.delete(contentId);
    
    await this.saveHistory();
    
    // 发布历史记录更新事件
    this.eventBus.publish('playback_history_updated', {
      item: deletedItem,
      action: 'delete'
    });
  }
  
  /**
   * 清空播放历史记录
   */
  public async clearPlaybackHistory(): Promise<void> {
    const deletedItems = Array.from(this.playbackHistory.values());
    this.playbackHistory.clear();
    
    await this.saveHistory();
    
    // 发布历史记录更新事件
    this.eventBus.publish('playback_history_cleared', {
      deletedCount: deletedItems.length
    });
  }
  
  /**
   * 获取播放统计
   */
  public getPlaybackStats(): PlaybackStats {
    return { ...this.playbackStats };
  }
  
  /**
   * 更新统计信息
   */
  private updateStats(historyItem: PlaybackHistoryItem): void {
    // 更新总播放时�?    this.playbackStats.totalWatchTime += historyItem.duration;
    
    // 更新总播放次�?    this.playbackStats.totalPlayCount++;
    
    // 更新观看视频数量
    if (historyItem.contentType === 'video') {
      this.playbackStats.watchedVideos++;
      if (historyItem.isCompleted) {
        this.playbackStats.completedVideos++;
      }
    }
    
    // 更新画质统计
    const quality = this.currentPlaybackState.quality;
    this.playbackStats.byQuality.set(quality, (this.playbackStats.byQuality.get(quality) || 0) + 1);
    
    // 更新播放速度统计
    const speed = this.currentPlaybackState.speed;
    this.playbackStats.bySpeed.set(speed, (this.playbackStats.bySpeed.get(speed) || 0) + 1);
    
    // 更新内容类型统计
    this.playbackStats.byContentType.set(historyItem.contentType, 
      (this.playbackStats.byContentType.get(historyItem.contentType) || 0) + 1);
    
    // 更新最喜欢的画质和速度
    this.updateFavoriteStats();
    
    this.playbackStats.lastUpdated = Date.now();
  }
  
  /**
   * 更新最喜欢的统�?   */
  private updateFavoriteStats(): void {
    // 找到最常用的画�?    let maxQualityCount = 0;
    let favoriteQuality = VideoQuality.HIGH;
    
    this.playbackStats.byQuality.forEach((count, quality) => {
      if (count > maxQualityCount) {
        maxQualityCount = count;
        favoriteQuality = quality;
      }
    });
    
    // 找到最常用的播放速度
    let maxSpeedCount = 0;
    let favoriteSpeed = PlaybackSpeed.NORMAL;
    
    this.playbackStats.bySpeed.forEach((count, speed) => {
      if (count > maxSpeedCount) {
        maxSpeedCount = count;
        favoriteSpeed = speed;
      }
    });
    
    this.playbackStats.favoriteQuality = favoriteQuality;
    this.playbackStats.favoriteSpeed = favoriteSpeed;
  }
  
  /**
   * 获取当前播放状�?   */
  public getCurrentPlaybackState(): CurrentPlaybackState {
    return { ...this.currentPlaybackState };
  }
  
  /**
   * 更新当前播放状�?   */
  public async updateCurrentPlaybackState(state: Partial<CurrentPlaybackState>): Promise<void> {
    this.currentPlaybackState = { ...this.currentPlaybackState, ...state };
    this.currentPlaybackState.currentTime = Date.now();
    
    await this.saveCurrentPlaybackState();
    
    // 发布播放状态更新事�?    this.eventBus.publish('playback_state_updated', {
      state: this.currentPlaybackState
    });
  }
  
  /**
   * 获取播放队列
   */
  public getPlaybackQueue(): PlaybackQueueItem[] {
    return [...this.playbackQueue];
  }
  
  /**
   * 添加项目到播放队�?   */
  public async addToPlaybackQueue(item: PlaybackQueueItem): Promise<void> {
    // 检查是否已在队列中
    const existingIndex = this.playbackQueue.findIndex(q => q.contentId === item.contentId);
    if (existingIndex >= 0) {
      // 如果已存在，移动到队列末�?      this.playbackQueue.splice(existingIndex, 1);
    }
    
    this.playbackQueue.push(item);
    
    // 限制队列长度
    if (this.playbackQueue.length > this.maxQueueLength) {
      this.playbackQueue = this.playbackQueue.slice(-this.maxQueueLength);
    }
    
    await this.savePlaybackQueue();
    
    // 发布队列更新事件
    this.eventBus.publish('playback_queue_updated', {
      action: 'add',
      item
    });
  }
  
  /**
   * 从播放队列中移除项目
   */
  public async removeFromPlaybackQueue(contentId: string): Promise<void> {
    const index = this.playbackQueue.findIndex(item => item.contentId === contentId);
    if (index >= 0) {
      const removedItem = this.playbackQueue.splice(index, 1)[0];
      
      await this.savePlaybackQueue();
      
      // 发布队列更新事件
      this.eventBus.publish('playback_queue_updated', {
        action: 'remove',
        item: removedItem
      });
    }
  }
  
  /**
   * 清空播放队列
   */
  public async clearPlaybackQueue(): Promise<void> {
    const clearedItems = [...this.playbackQueue];
    this.playbackQueue = [];
    
    await this.savePlaybackQueue();
    
    // 发布队列更新事件
    this.eventBus.publish('playback_queue_cleared', {
      clearedCount: clearedItems.length
    });
  }
  
  /**
   * 重新排序播放队列
   */
  public async reorderPlaybackQueue(contentIds: string[]): Promise<void> {
    const newQueue: PlaybackQueueItem[] = [];
    
    // 按照新的顺序重新构建队列
    contentIds.forEach(contentId => {
      const item = this.playbackQueue.find(q => q.contentId === contentId);
      if (item) {
        newQueue.push(item);
      }
    });
    
    // 添加不在新顺序中的项�?    this.playbackQueue.forEach(item => {
      if (!contentIds.includes(item.contentId)) {
        newQueue.push(item);
      }
    });
    
    this.playbackQueue = newQueue;
    
    await this.savePlaybackQueue();
    
    // 发布队列更新事件
    this.eventBus.publish('playback_queue_reordered', {
      newOrder: contentIds
    });
  }
  
  /**
   * 获取下一个播放项�?   */
  public getNextPlaybackItem(): PlaybackQueueItem | null {
    if (this.playbackQueue.length === 0) {
      return null;
    }
    
    // 根据播放模式返回下一个项�?    switch (this.currentPlaybackState.mode) {
      case PlaybackMode.LOOP:
        // 循环播放：返回队列中的第一个项�?        return this.playbackQueue[0];
        
      case PlaybackMode.SHUFFLE:
        // 随机播放：随机返回一个项�?        const randomIndex = Math.floor(Math.random() * this.playbackQueue.length);
        return this.playbackQueue[randomIndex];
        
      case PlaybackMode.DEFAULT:
      default:
        // 默认模式：返回队列中的第一个项�?        return this.playbackQueue[0];
    }
  }
  
  /**
   * 搜索播放历史
   */
  public searchPlaybackHistory(query: string): PlaybackHistoryItem[] {
    const searchTerm = query.toLowerCase();
    return this.getPlaybackHistory().filter(item => 
      item.title.toLowerCase().includes(searchTerm) ||
      (item.channelName && item.channelName.toLowerCase().includes(searchTerm))
    );
  }
  
  /**
   * 获取最近观看的项目
   */
  public getRecentPlaybackHistory(limit: number = 10): PlaybackHistoryItem[] {
    return this.getPlaybackHistory().slice(0, limit);
  }
  
  /**
   * 获取最常观看的项目
   */
  public getMostWatchedPlaybackHistory(limit: number = 10): PlaybackHistoryItem[] {
    return Array.from(this.playbackHistory.values())
      .sort((a, b) => b.playCount - a.playCount)
      .slice(0, limit);
  }
  
  /**
   * 获取完成的项�?   */
  public getCompletedPlaybackHistory(): PlaybackHistoryItem[] {
    return this.getPlaybackHistory().filter(item => item.isCompleted);
  }
  
  /**
   * 获取未完成的项目
   */
  public getIncompletePlaybackHistory(): PlaybackHistoryItem[] {
    return this.getPlaybackHistory().filter(item => !item.isCompleted);
  }
  
  /**
   * 清理过期数据
   */
  public async cleanupExpiredData(): Promise<void> {
    const now = Date.now();
    const thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000); // 30天前
    
    // 清理30天前的历史记�?    let cleanedCount = 0;
    this.playbackHistory.forEach((item, contentId) => {
      if (item.lastPlayedAt < thirtyDaysAgo) {
        this.playbackHistory.delete(contentId);
        cleanedCount++;
      }
    });
    
    if (cleanedCount > 0) {
      await this.saveHistory();
      this.logger.info(`Cleaned ${cleanedCount} expired playback history items`);
    }
    
    // 清理过滤器缓�?    this.filterCache.clear();
  }
  
  /**
   * 关闭仓库
   */
  public async shutdown(): Promise<void> {
    // 停止自动保存
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = null;
    }
    
    // 执行最后一次保�?    await this.autoSave();
    
    this.logger.info('PlaybackRepository shutdown completed');
  }
}


