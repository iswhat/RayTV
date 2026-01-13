// 鎾斁浠撳簱- 绠＄悊鎾斁鐩稿叧鐨勬暟鎹搷浣?import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/CacheService';
import UserRepository from './UserRepository';
import VideoRepository from './VideoRepository';
import { LocalStorageType, CacheType } from '../../types/commonTypes';

// 鎾斁鐘舵€佹灇涓?export enum PlaybackState {
  IDLE = 'idle',
  LOADING = 'loading',
  PLAYING = 'playing',
  PAUSED = 'paused',
  BUFFERING = 'buffering',
  ENDED = 'ended',
  ERROR = 'error'
}

// 瑙嗛璐ㄩ噺鏋氫妇
export enum VideoQuality {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  HD = 'hd',
  FHD = 'fhd',
  UHD = 'uhd'
}

// 鎾斁閫熷害鏋氫妇
export enum PlaybackSpeed {
  QUARTER = 0.25,
  HALF = 0.5,
  NORMAL = 1.0,
  ONE_QUARTER = 1.25,
  ONE_HALF = 1.5,
  DOUBLE = 2.0
}

// 鎾斁妯″紡鏋氫妇
export enum PlaybackMode {
  DEFAULT = 'default',
  LOOP = 'loop',
  SHUFFLE = 'shuffle'
}

// 闊抽杞ㄩ亾鎺ュ彛
export interface AudioTrack {
  id: string;
  language: string;
  label: string;
  isDefault: boolean;
}

// 瀛楀箷杞ㄩ亾鎺ュ彛
export interface SubtitleTrack {
  id: string;
  language: string;
  label: string;
  isDefault: boolean;
}

// 鎾斁浜嬩欢鎺ュ彛
export interface PlaybackEvent {
  type: string;
  timestamp: number;
  data?: Record<string, unknown>;
}

// 鎾斁鍘嗗彶椤规帴鍙?export interface PlaybackHistoryItem {
  contentId: string;
  contentType: 'video' | 'live';
  title: string;
  thumbnailUrl?: string;
  channelId?: string;
  channelName?: string;
  duration: number;
  position: number; // 鏈€鍚庤鐪嬩綅缃?  lastPlayedAt: number;
  playCount: number;
  isCompleted: boolean;
}

// 鎾斁璁剧疆鎺ュ彛
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

// 鎾斁缁熻鎺ュ彛
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

// 褰撳墠鎾斁鐘舵€佹帴鍙?export interface CurrentPlaybackState {
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
  currentTime: number; // 鐘舵€佽褰曟椂闂?}

// 鎾斁闃熷垪椤规帴鍙?export interface PlaybackQueueItem {
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
  
  // 瀛樺偍閿悕
  private readonly storageKeys = {
    playbackSettings: 'playback_settings',
    playbackHistory: 'playback_history',
    playbackStats: 'playback_stats',
    currentPlaybackState: 'current_playback_state',
    playbackQueue: 'playback_queue',
    lastWatchPosition: 'last_watch_position'
  };
  
  // 鏁版嵁缂撳瓨
  private playbackSettings: PlaybackSettings;
  private playbackHistory: Map<string, PlaybackHistoryItem>; // key: contentId
  private playbackStats: PlaybackStats;
  private currentPlaybackState: CurrentPlaybackState;
  private playbackQueue: PlaybackQueueItem[];
  
  // 杩囨护鍣ㄧ紦瀛?  private filterCache: Map<string, unknown[]>;
  
  // 鑷姩淇濆瓨闂撮殧锛堟绉掞級
  private readonly autoSaveInterval = 30000; // 30绉?  
  // 鑷姩淇濆瓨璁℃椂鍣?  private autoSaveTimer: number | null = null;
  
  // 鏈€澶у巻鍙茶褰曟暟閲?  private readonly maxHistoryItems = 100;
  
  // 鏈€澶ч槦鍒楅暱搴?  private readonly maxQueueLength = 50;
  
  private constructor() {
    this.logger = Logger.getInstance();
    this.storageUtil = StorageUtil.getInstance();
    this.networkUtil = NetworkUtil.getInstance();
    this.eventBus = EventBusUtil.getInstance();
    this.cacheService = CacheService.getInstance();
    this.userRepository = UserRepository.getInstance();
    this.videoRepository = VideoRepository.getInstance();
    
    // 鍒濆鍖栭粯璁ゆ暟鎹?    this.playbackSettings = this.getDefaultSettings();
    this.playbackHistory = new Map();
    this.playbackStats = this.getEmptyStats();
    this.currentPlaybackState = this.getEmptyPlaybackState();
    this.playbackQueue = [];
    this.filterCache = new Map();
    
    // 鍒濆鍖?    this.initialize();
  }
  
  /**
   * 鑾峰彇瀹炰緥
   */
  public static getInstance(): PlaybackRepository {
    if (!PlaybackRepository.instance) {
      PlaybackRepository.instance = new PlaybackRepository();
    }
    return PlaybackRepository.instance;
  }
  
  /**
   * 妫€鏌ュ璞℃槸鍚﹀寘鍚寚瀹氬睘鎬?   * 鏇夸唬Object.prototype.hasOwnProperty.call锛屽吋瀹笰rkTS璇硶
   */
  private hasOwnProperty<T extends object>(obj: T, key: string): boolean {
    return Object.getOwnPropertyNames(obj).includes(key);
  }

  /**
   * 鑾峰彇瀵硅薄鐨勬墍鏈夊€?   * 鏇夸唬Object.values锛屽吋瀹笰rkTS璇硶
   */
  private getObjectValues<T extends object>(obj: T): any[] {
    const values: any[] = [];
    for (const key in obj) {
      if (this.hasOwnProperty(obj, key)) {
        values.push(obj[key]);
      }
    }
    return values;
  }
  
  /**
   * 鍒濆鍖?   */
  public async initialize(): Promise<void> {
    try {
      // 鍔犺浇璁剧疆
      await this.loadSettings();
      
      // 鍔犺浇鍘嗗彶璁板綍
      await this.loadHistory();
      
      // 鍔犺浇缁熻
      await this.loadStats();
      
      // 鍔犺浇褰撳墠鎾斁鐘舵€?      await this.loadCurrentPlaybackState();
      
      // 鍔犺浇鎾斁闃熷垪
      await this.loadPlaybackQueue();
      
      // 鍚姩鑷姩淇濆瓨
      this.startAutoSave();
      
      this.logger.info(`PlaybackRepository initialized with ${this.playbackHistory.size} history items`);
    } catch (error) {
      this.logger.error('Failed to initialize PlaybackRepository', error as Error);
    }
  }
  
  /**
   * 鑾峰彇榛樿璁剧疆
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
   * 鑾峰彇绌虹殑缁熻鏁版嵁
   */
  private getEmptyStats(): PlaybackStats {
    const byQuality = new Map<VideoQuality, number>();
    const bySpeed = new Map<PlaybackSpeed, number>();
    const byContentType = new Map<'video' | 'live', number>();
    
    // 鍒濆鍖栫敾璐ㄧ粺璁?    this.getObjectValues(VideoQuality).forEach(quality => {
      byQuality.set(quality, 0);
    });
    
    // 鍒濆鍖栨挱鏀鹃€熷害缁熻
    this.getObjectValues(PlaybackSpeed).forEach(speed => {
      bySpeed.set(speed, 0);
    });
    
    // 鍒濆鍖栧唴瀹圭被鍨嬬粺璁?    byContentType.set('video', 0);
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
   * 鑾峰彇绌虹殑鎾斁鐘舵€?   */
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
   * 鍔犺浇璁剧疆
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
   * 淇濆瓨璁剧疆
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
   * 鍔犺浇鍘嗗彶璁板綍
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
   * 淇濆瓨鍘嗗彶璁板綍
   */
  private async saveHistory(): Promise<void> {
    try {
      // 杞崲涓烘暟缁勫苟鎸夋渶鍚庢挱鏀炬椂闂存帓搴?      const historyArray = Array.from(this.playbackHistory.values())
        .sort((a, b) => b.lastPlayedAt - a.lastPlayedAt)
        .slice(0, this.maxHistoryItems);
      
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
   * 鍔犺浇缁熻
   */
  private async loadStats(): Promise<void> {
    try {
      const stats = await this.storageUtil.getObject<PlaybackStats>(
        this.storageKeys.playbackStats,
        LocalStorageType.DEFAULT
      );
      
      if (stats) {
        this.playbackStats = { ...this.getEmptyStats(), ...stats };
      }
    } catch (error) {
      this.logger.error('Failed to load playback stats', error as Error);
      this.playbackStats = this.getEmptyStats();
    }
  }
  
  /**
   * 淇濆瓨缁熻
   */
  private async saveStats(): Promise<void> {
    try {
      this.playbackStats.lastUpdated = Date.now();
      await this.storageUtil.setObject(
        this.storageKeys.playbackStats,
        this.playbackStats,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.error('Failed to save playback stats', error as Error);
    }
  }
  
  /**
   * 鍔犺浇褰撳墠鎾斁鐘舵€?   */
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
   * 淇濆瓨褰撳墠鎾斁鐘舵€?   */
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
   * 鍔犺浇鎾斁闃熷垪
   */
  private async loadPlaybackQueue(): Promise<void> {
    try {
      const queue = await this.storageUtil.getObject<PlaybackQueueItem[]>(
        this.storageKeys.playbackQueue,
        LocalStorageType.DEFAULT
      );
      
      if (queue) {
        this.playbackQueue = queue.slice(0, this.maxQueueLength);
      }
    } catch (error) {
      this.logger.error('Failed to load playback queue', error as Error);
      this.playbackQueue = [];
    }
  }
  
  /**
   * 淇濆瓨鎾斁闃熷垪
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
   * 鍚姩鑷姩淇濆瓨
   */
  private startAutoSave(): void {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
    }
    
    this.autoSaveTimer = setInterval(() => {
      this.autoSave();
    }, this.autoSaveInterval);
  }
  
  /**
   * 鑷姩淇濆瓨
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
      this.logger.error('Failed to auto-save playback data', error as Error);
    }
  }
  
  /**
   * 鑾峰彇鎾斁璁剧疆
   */
  public getPlaybackSettings(): PlaybackSettings {
    return { ...this.playbackSettings };
  }
  
  /**
   * 鏇存柊鎾斁璁剧疆
   */
  public async updatePlaybackSettings(settings: Partial<PlaybackSettings>): Promise<void> {
    this.playbackSettings = { ...this.playbackSettings, ...settings };
    this.playbackSettings.lastUpdated = Date.now();
    
    await this.saveSettings();
    
    // 鍙戝竷璁剧疆鏇存柊浜嬩欢
    this.eventBus.publish('playback_settings_updated', {
      settings: this.playbackSettings
    });
  }
  
  /**
   * 鑾峰彇鎾斁鍘嗗彶
   */
  public getPlaybackHistory(): PlaybackHistoryItem[] {
    return Array.from(this.playbackHistory.values())
      .sort((a, b) => b.lastPlayedAt - a.lastPlayedAt);
  }
  
  /**
   * 娣诲姞鎾斁鍘嗗彶璁板綍
   */
  public async addPlaybackHistory(item: Omit<PlaybackHistoryItem, 'playCount' | 'lastPlayedAt' | 'isCompleted'>): Promise<void> {
    const existingItem = this.playbackHistory.get(item.contentId);
    const now = Date.now();
    
    const historyItem: PlaybackHistoryItem = {
      ...item,
      playCount: (existingItem?.playCount || 0) + 1,
      lastPlayedAt: now,
      isCompleted: item.position >= item.duration * 0.95 // 瑙傜湅杩涘害瓒呰繃95%瑙嗕负瀹屾垚
    };
    
    this.playbackHistory.set(item.contentId, historyItem);
    
    // 鏇存柊缁熻
    this.updateStats(historyItem);
    
    // 淇濆瓨鍘嗗彶璁板綍
    await this.saveHistory();
    
    // 鍙戝竷鍘嗗彶璁板綍鏇存柊浜嬩欢
    this.eventBus.publish('playback_history_updated', {
      item: historyItem,
      action: 'add'
    });
  }
  
  /**
   * 鏇存柊鎾斁鍘嗗彶璁板綍
   */
  public async updatePlaybackHistory(contentId: string, updates: Partial<PlaybackHistoryItem>): Promise<void> {
    const existingItem = this.playbackHistory.get(contentId);
    if (!existingItem) {
      return;
    }
    
    const updatedItem: PlaybackHistoryItem = { 
      ...existingItem, 
      ...updates 
    };
    this.playbackHistory.set(contentId, updatedItem);
    
    await this.saveHistory();
    
    // 鍙戝竷鍘嗗彶璁板綍鏇存柊浜嬩欢
    this.eventBus.publish('playback_history_updated', {
      item: updatedItem,
      action: 'update'
    });
  }
  
  /**
   * 鍒犻櫎鎾斁鍘嗗彶璁板綍
   */
  public async deletePlaybackHistory(contentId: string): Promise<void> {
    const deletedItem = this.playbackHistory.get(contentId);
    if (!deletedItem) {
      return;
    }
    
    this.playbackHistory.delete(contentId);
    
    await this.saveHistory();
    
    // 鍙戝竷鍘嗗彶璁板綍鏇存柊浜嬩欢
    this.eventBus.publish('playback_history_updated', {
      item: deletedItem,
      action: 'delete'
    });
  }
  
  /**
   * 娓呯┖鎾斁鍘嗗彶璁板綍
   */
  public async clearPlaybackHistory(): Promise<void> {
    const deletedItems = Array.from(this.playbackHistory.values());
    this.playbackHistory.clear();
    
    await this.saveHistory();
    
    // 鍙戝竷鍘嗗彶璁板綍鏇存柊浜嬩欢
    this.eventBus.publish('playback_history_cleared', {
      deletedCount: deletedItems.length
    });
  }
  
  /**
   * 鑾峰彇鎾斁缁熻
   */
  public getPlaybackStats(): PlaybackStats {
    return { ...this.playbackStats };
  }
  
  /**
   * 鏇存柊缁熻淇℃伅
   */
  private updateStats(historyItem: PlaybackHistoryItem): void {
    // 鏇存柊鎬绘挱鏀炬椂闂?    this.playbackStats.totalWatchTime += historyItem.duration;
    
    // 鏇存柊鎬绘挱鏀炬鏁?    this.playbackStats.totalPlayCount++;
    
    // 鏇存柊瑙傜湅瑙嗛鏁伴噺
    if (historyItem.contentType === 'video') {
      this.playbackStats.watchedVideos++;
      if (historyItem.isCompleted) {
        this.playbackStats.completedVideos++;
      }
    }
    
    // 鏇存柊鐢昏川缁熻
    const quality = this.currentPlaybackState.quality;
    this.playbackStats.byQuality.set(quality, (this.playbackStats.byQuality.get(quality) || 0) + 1);
    
    // 鏇存柊鎾斁閫熷害缁熻
    const speed = this.currentPlaybackState.speed;
    this.playbackStats.bySpeed.set(speed, (this.playbackStats.bySpeed.get(speed) || 0) + 1);
    
    // 鏇存柊鍐呭绫诲瀷缁熻
    this.playbackStats.byContentType.set(historyItem.contentType, 
      (this.playbackStats.byContentType.get(historyItem.contentType) || 0) + 1);
    
    // 鏇存柊鏈€鍠滄鐨勭敾璐ㄥ拰閫熷害
    this.updateFavoriteStats();
    
    this.playbackStats.lastUpdated = Date.now();
  }
  
  /**
   * 鏇存柊鏈€鍠滄鐨勭粺璁?   */
  private updateFavoriteStats(): void {
    // 鎵惧埌鏈€甯哥敤鐨勭敾璐?    let maxQualityCount = 0;
    let favoriteQuality = VideoQuality.HIGH;
    
    this.playbackStats.byQuality.forEach((count, quality) => {
      if (count > maxQualityCount) {
        maxQualityCount = count;
        favoriteQuality = quality;
      }
    });
    this.playbackStats.favoriteQuality = favoriteQuality;
    
    // 鎵惧埌鏈€甯哥敤鐨勬挱鏀鹃€熷害
    let maxSpeedCount = 0;
    let favoriteSpeed = PlaybackSpeed.NORMAL;
    
    this.playbackStats.bySpeed.forEach((count, speed) => {
      if (count > maxSpeedCount) {
        maxSpeedCount = count;
        favoriteSpeed = speed;
      }
    });
    this.playbackStats.favoriteSpeed = favoriteSpeed;
  }
  
  /**
   * 鑾峰彇褰撳墠鎾斁鐘舵€?   */
  public getCurrentPlaybackState(): CurrentPlaybackState {
    return { ...this.currentPlaybackState };
  }
  
  /**
   * 鏇存柊褰撳墠鎾斁鐘舵€?   */
  public async updateCurrentPlaybackState(state: Partial<CurrentPlaybackState>): Promise<void> {
    this.currentPlaybackState = { ...this.currentPlaybackState, ...state };
    this.currentPlaybackState.currentTime = Date.now();
    
    await this.saveCurrentPlaybackState();
    
    // 鍙戝竷鎾斁鐘舵€佹洿鏂颁簨浠?    this.eventBus.publish('playback_state_updated', {
      state: this.currentPlaybackState
    });
  }
  
  /**
   * 鑾峰彇鎾斁闃熷垪
   */
  public getPlaybackQueue(): PlaybackQueueItem[] {
    return [...this.playbackQueue];
  }
  
  /**
   * 娣诲姞鍒版挱鏀鹃槦鍒?   */
  public async addToPlaybackQueue(item: PlaybackQueueItem): Promise<void> {
    // 妫€鏌ラ槦鍒椾腑鏄惁宸插瓨鍦?    const existingIndex = this.playbackQueue.findIndex(queueItem => queueItem.contentId === item.contentId);
    if (existingIndex >= 0) {
      // 绉婚櫎宸插瓨鍦ㄧ殑椤?      this.playbackQueue.splice(existingIndex, 1);
    }
    
    // 娣诲姞鍒伴槦鍒楁湯灏?    this.playbackQueue.push(item);
    
    // 闄愬埗闃熷垪闀垮害
    if (this.playbackQueue.length > this.maxQueueLength) {
      this.playbackQueue.shift();
    }
    
    await this.savePlaybackQueue();
    
    // 鍙戝竷闃熷垪鏇存柊浜嬩欢
    this.eventBus.publish('playback_queue_updated', {
      queue: this.playbackQueue,
      action: 'add'
    });
  }
  
  /**
   * 浠庢挱鏀鹃槦鍒椾腑绉婚櫎
   */
  public async removeFromPlaybackQueue(contentId: string): Promise<void> {
    const index = this.playbackQueue.findIndex(item => item.contentId === contentId);
    if (index >= 0) {
      this.playbackQueue.splice(index, 1);
      
      await this.savePlaybackQueue();
      
      // 鍙戝竷闃熷垪鏇存柊浜嬩欢
      this.eventBus.publish('playback_queue_updated', {
        queue: this.playbackQueue,
        action: 'remove'
      });
    }
  }
  
  /**
   * 娓呯┖鎾斁闃熷垪
   */
  public async clearPlaybackQueue(): Promise<void> {
    this.playbackQueue = [];
    
    await this.savePlaybackQueue();
    
    // 鍙戝竷闃熷垪鏇存柊浜嬩欢
    this.eventBus.publish('playback_queue_cleared', {
      queue: this.playbackQueue
    });
  }
  
  /**
   * 娓呯┖鎵€鏈夋暟鎹?   */
  public async clearAllData(): Promise<void> {
    try {
      // 娓呯┖鍐呭瓨缂撳瓨
      this.playbackHistory.clear();
      this.playbackStats = this.getEmptyStats();
      this.currentPlaybackState = this.getEmptyPlaybackState();
      this.playbackQueue = [];
      
      // 淇濆瓨鍒板瓨鍌?      await Promise.all([
        this.saveHistory(),
        this.saveStats(),
        this.saveCurrentPlaybackState(),
        this.savePlaybackQueue()
      ]);
      
      this.logger.info('Cleared all playback data');
    } catch (error) {
      this.logger.error('Failed to clear all playback data', error as Error);
      throw error;
    }
  }
  
  /**
   * 閲婃斁璧勬簮
   */
  public release(): void {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = null;
    }
  }
}


