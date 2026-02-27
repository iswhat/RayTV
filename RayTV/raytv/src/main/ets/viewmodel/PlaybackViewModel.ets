/**
 * PlaybackViewModel.ts
 * 播放页面ViewModel - 实现复杂的播放状态管理和多媒体控制
 */

import { MediaInfo, Episode, ParseLine } from '../data/bean/MediaItem';
import { PlaybackService } from '../service/playback/PlaybackService';
import { MediaService } from '../service/media/MediaService';
import { CacheService } from '../service/cache/CacheService';
import { SubtitleService } from '../service/subtitle/SubtitleService';
import Logger from '../common/util/Logger';

// ==================== 类型定义 ====================

export interface PlaybackMediaState {
  info: MediaInfo | null;
  episodes: Episode[];
  parseLines: ParseLine[];
  selectedEpisode: Episode | null;
  selectedLine: ParseLine | null;
}

export interface PlaybackControlState {
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  progress: number;
  playbackSpeed: number;
  volume: number;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  isBuffering: boolean;
  isSeeking: boolean;
}

export interface PlaybackUIState {
  isLandscape: boolean;
  screenWidth: number;
  screenHeight: number;
  showControls: boolean;
  showEpisodeList: boolean;
  showMoreOptions: boolean;
  showSubtitleOptions: boolean;
  showAudioTrackOptions: boolean;
  showSkipOptions: boolean;
  videoPlayerHeight: number;
  controlHideTimer: number | null;
  currentFocusElement: string;
}

export interface SubtitleState {
  tracks: any[]; // 字幕轨道
  selectedTrack: any | null;
  languages: any[]; // 字幕语言
  isSearching: boolean;
  isEnabled: boolean;
}

export interface AudioState {
  tracks: any[]; // 音轨
  selectedTrack: any | null;
}

export interface SkipState {
  skipOpeningTime: number;
  skipEndingTime: number;
  isSkipOpeningEnabled: boolean;
  isSkipEndingEnabled: boolean;
}

export interface LiveState {
  isLiveMode: boolean;
  showChannelList: boolean;
  showSettings: boolean;
}

// ==================== 响应式属性类 ====================

class ReactiveProperty<T> {
  private _value: T;
  private subscribers: ((newValue: T, oldValue: T) => void)[] = [];
  
  constructor(initialValue: T) {
    this._value = initialValue;
  }
  
  get value(): T {
    return this._value;
  }
  
  set value(newValue: T) {
    const oldValue = this._value;
    if (newValue !== oldValue) {
      this._value = newValue;
      this.notifySubscribers(newValue, oldValue);
    }
  }
  
  subscribe(callback: (newValue: T, oldValue: T) => void): () => void {
    this.subscribers.push(callback);
    callback(this._value, this._value);
    
    return () => {
      const index = this.subscribers.indexOf(callback);
      if (index > -1) {
        this.subscribers.splice(index, 1);
      }
    };
  }
  
  private notifySubscribers(newValue: T, oldValue: T): void {
    this.subscribers.forEach(callback => {
      try {
        callback(newValue, oldValue);
      } catch (error) {
        Logger.error('PlaybackViewModel', `Subscriber callback error: ${error}`);
      }
    });
  }
}

// ==================== PlaybackViewModel实现 ====================

export class PlaybackViewModel {
  private readonly TAG: string = 'PlaybackViewModel';
  
  // 服务实例
  private playbackService: PlaybackService;
  private mediaService: MediaService;
  private cacheService: CacheService;
  private subtitleService: SubtitleService;
  
  // 响应式状态属性
  public readonly mediaState = new ReactiveProperty<PlaybackMediaState>({
    info: null,
    episodes: [],
    parseLines: [],
    selectedEpisode: null,
    selectedLine: null
  });
  
  public readonly controlState = new ReactiveProperty<PlaybackControlState>({
    isPlaying: true,
    currentTime: 0,
    duration: 0,
    progress: 0,
    playbackSpeed: 1.0,
    volume: 100,
    isLoading: true,
    isError: false,
    errorMessage: '',
    isBuffering: false,
    isSeeking: false
  });
  
  public readonly uiState = new ReactiveProperty<PlaybackUIState>({
    isLandscape: false,
    screenWidth: 0,
    screenHeight: 0,
    showControls: true,
    showEpisodeList: false,
    showMoreOptions: false,
    showSubtitleOptions: false,
    showAudioTrackOptions: false,
    showSkipOptions: false,
    videoPlayerHeight: 400,
    controlHideTimer: null,
    currentFocusElement: ''
  });
  
  public readonly subtitleState = new ReactiveProperty<SubtitleState>({
    tracks: [],
    selectedTrack: null,
    languages: [],
    isSearching: false,
    isEnabled: true
  });
  
  public readonly audioState = new ReactiveProperty<AudioState>({
    tracks: [],
    selectedTrack: null
  });
  
  public readonly skipState = new ReactiveProperty<SkipState>({
    skipOpeningTime: 90,
    skipEndingTime: 300,
    isSkipOpeningEnabled: true,
    isSkipEndingEnabled: true
  });
  
  public readonly liveState = new ReactiveProperty<LiveState>({
    isLiveMode: false,
    showChannelList: false,
    showSettings: false
  });
  
  // 计算属性
  public readonly formattedCurrentTime = new ReactiveProperty<string>('00:00');
  public readonly formattedDuration = new ReactiveProperty<string>('00:00');
  public readonly remainingTime = new ReactiveProperty<string>('00:00');
  public readonly isAtBeginning = new ReactiveProperty<boolean>(true);
  public readonly isNearEnd = new ReactiveProperty<boolean>(false);
  
  constructor() {
    this.playbackService = PlaybackService.getInstance();
    this.mediaService = MediaService.getInstance();
    this.cacheService = CacheService.getInstance();
    this.subtitleService = SubtitleService.getInstance();
    
    // 初始化计算属性
    this.setupComputedProperties();
    
    Logger.info(this.TAG, 'PlaybackViewModel initialized');
  }
  
  // ==================== 计算属性设置 ====================
  
  private setupComputedProperties(): void {
    // 时间格式化计算
    this.controlState.subscribe((state) => {
      this.formattedCurrentTime.value = this.formatTime(state.currentTime);
      this.formattedDuration.value = this.formatTime(state.duration);
      this.remainingTime.value = this.formatRemainingTime(state.currentTime, state.duration);
      
      this.isAtBeginning.value = state.currentTime < 5;
      this.isNearEnd.value = state.duration > 0 && 
        (state.duration - state.currentTime) < (this.skipState.value.skipEndingTime + 30);
    });
    
    // 进度计算
    this.controlState.subscribe((state) => {
      const progress = state.duration > 0 ? (state.currentTime / state.duration) * 100 : 0;
      const newState = { ...state, progress };
      this.controlState.value = newState;
    });
    
    // UI适配计算
    this.uiState.subscribe((uiState) => {
      if (uiState.isLandscape) {
        uiState.videoPlayerHeight = uiState.screenHeight * 0.6;
      } else {
        uiState.videoPlayerHeight = 400;
      }
    });
  }
  
  private formatTime(seconds: number): string {
    if (isNaN(seconds) || seconds < 0) return '00:00';
    
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  
  private formatRemainingTime(currentTime: number, duration: number): string {
    if (duration <= 0) return '00:00';
    const remaining = duration - currentTime;
    return '-' + this.formatTime(remaining);
  }
  
  // ==================== 核心功能方法 ====================
  
  /**
   * 初始化播放器
   */
  public async initialize(params: { id: string; siteKey: string; type: string }): Promise<void> {
    Logger.info(this.TAG, `Initializing playback for: ${params.id}`);
    
    try {
      this.controlState.value = { ...this.controlState.value, isLoading: true, isError: false };
      
      // 加载媒体信息
      await this.loadMediaInfo(params);
      
      // 初始化播放
      await this.initPlayback();
      
      // 加载字幕
      await this.loadSubtitles();
      
      Logger.info(this.TAG, 'Playback initialized successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize playback: ${error}`);
      this.handleError('播放初始化失败', error);
    } finally {
      this.controlState.value = { ...this.controlState.value, isLoading: false };
    }
  }
  
  /**
   * 加载媒体信息
   */
  private async loadMediaInfo(params: { id: string; siteKey: string; type: string }): Promise<void> {
    const cacheKey = `media_info_${params.id}_${params.siteKey}_${params.type}`;
    let mediaInfo = await this.cacheService.get<MediaInfo>(cacheKey);
    
    if (!mediaInfo) {
      const result = await this.mediaService.getMediaDetail(params.id, params.siteKey, params.type);
      if (result.isSuccess() && result.data) {
        mediaInfo = result.data;
        await this.cacheService.set(cacheKey, mediaInfo, 86400000); // 24小时缓存
      } else {
        throw new Error(result.message || '加载媒体信息失败');
      }
    }
    
    // 更新媒体状态
    const currentMediaState = this.mediaState.value;
    this.mediaState.value = {
      ...currentMediaState,
      info: mediaInfo,
      episodes: mediaInfo.episodes || [],
      parseLines: mediaInfo.parseLines || []
    };
    
    // 加载剧集和解析线路
    await Promise.all([
      this.loadEpisodes(),
      this.loadParseLines()
    ]);
  }
  
  /**
   * 加载剧集列表
   */
  private async loadEpisodes(): Promise<void> {
    const mediaInfo = this.mediaState.value.info;
    if (!mediaInfo) return;
    
    // 这里可以从服务获取剧集数据
    const episodes = mediaInfo.episodes || [];
    const currentMediaState = this.mediaState.value;
    this.mediaState.value = { ...currentMediaState, episodes };
  }
  
  /**
   * 加载解析线路
   */
  private async loadParseLines(): Promise<void> {
    const mediaInfo = this.mediaState.value.info;
    if (!mediaInfo) return;
    
    const parseLines = mediaInfo.parseLines || [];
    const currentMediaState = this.mediaState.value;
    this.mediaState.value = { ...currentMediaState, parseLines };
  }
  
  /**
   * 初始化播放
   */
  private async initPlayback(): Promise<void> {
    const mediaInfo = this.mediaState.value.info;
    if (!mediaInfo) return;
    
    try {
      // 初始化播放服务
      await this.playbackService.initialize({
        mediaId: mediaInfo.id,
        title: mediaInfo.title,
        url: mediaInfo.url
      });
      
      // 获取播放状态
      const playbackState = await this.playbackService.getPlaybackState();
      if (playbackState) {
        this.controlState.value = {
          ...this.controlState.value,
          isPlaying: playbackState.isPlaying,
          currentTime: playbackState.currentTime,
          duration: playbackState.duration,
          volume: playbackState.volume * 100
        };
      }
      
      // 加载音轨信息
      const audioTracks = await this.playbackService.getAudioTracks();
      if (audioTracks && audioTracks.length > 0) {
        this.audioState.value = {
          tracks: audioTracks,
          selectedTrack: audioTracks[0]
        };
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize playback: ${error}`);
      throw error;
    }
  }
  
  /**
   * 加载字幕
   */
  private async loadSubtitles(): Promise<void> {
    const mediaInfo = this.mediaState.value.info;
    if (!mediaInfo) return;
    
    try {
      this.subtitleState.value = { ...this.subtitleState.value, isSearching: true };
      
      const subtitles = await this.subtitleService.searchSubtitles({
        title: mediaInfo.title,
        year: mediaInfo.year,
        language: 'zh-CN'
      });
      
      this.subtitleState.value = {
        ...this.subtitleState.value,
        tracks: subtitles,
        isSearching: false,
        isEnabled: subtitles.length > 0
      };
      
      Logger.info(this.TAG, `Found ${subtitles.length} subtitle tracks`);
    } catch (error) {
      Logger.warn(this.TAG, `Failed to load subtitles: ${error}`);
      this.subtitleState.value = { ...this.subtitleState.value, isSearching: false };
    }
  }
  
  // ==================== 播放控制方法 ====================
  
  /**
   * 播放/暂停切换
   */
  public async togglePlayPause(): Promise<void> {
    try {
      const isCurrentlyPlaying = this.controlState.value.isPlaying;
      let result: { isSuccess: () => boolean };
      
      if (isCurrentlyPlaying) {
        result = await this.playbackService.pause();
      } else {
        result = await this.playbackService.play();
      }
      
      if (result.isSuccess()) {
        this.controlState.value = {
          ...this.controlState.value,
          isPlaying: !isCurrentlyPlaying
        };
        Logger.info(this.TAG, `Playback ${!isCurrentlyPlaying ? 'started' : 'paused'}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle playback: ${error}`);
    }
  }
  
  /**
   * 调整播放进度
   */
  public async seekTo(time: number): Promise<void> {
    try {
      this.controlState.value = { ...this.controlState.value, isSeeking: true };
      
      const result = await this.playbackService.seek(time);
      if (result.isSuccess()) {
        this.controlState.value = {
          ...this.controlState.value,
          currentTime: time,
          isSeeking: false
        };
        Logger.info(this.TAG, `Seeked to ${this.formatTime(time)}`);
      } else {
        this.controlState.value = { ...this.controlState.value, isSeeking: false };
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to seek: ${error}`);
      this.controlState.value = { ...this.controlState.value, isSeeking: false };
    }
  }
  
  /**
   * 快进
   */
  public async fastForward(seconds: number = 30): Promise<void> {
    const currentTime = this.controlState.value.currentTime;
    const duration = this.controlState.value.duration;
    const targetTime = Math.min(duration, currentTime + seconds);
    await this.seekTo(targetTime);
  }
  
  /**
   * 快退
   */
  public async rewind(seconds: number = 10): Promise<void> {
    const currentTime = this.controlState.value.currentTime;
    const targetTime = Math.max(0, currentTime - seconds);
    await this.seekTo(targetTime);
  }
  
  /**
   * 调整音量
   */
  public async setVolume(volume: number): Promise<void> {
    try {
      const normalizedVolume = Math.max(0, Math.min(100, volume));
      const result = await this.playbackService.setVolume(normalizedVolume / 100);
      
      if (result.isSuccess()) {
        this.controlState.value = { ...this.controlState.value, volume: normalizedVolume };
        Logger.info(this.TAG, `Volume set to ${normalizedVolume}%`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to set volume: ${error}`);
    }
  }
  
  /**
   * 调整播放速度
   */
  public async setPlaybackSpeed(speed: number): Promise<void> {
    try {
      const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
      const normalizedSpeed = speeds.reduce((prev, curr) => 
        Math.abs(curr - speed) < Math.abs(prev - speed) ? curr : prev
      );
      
      const result = await this.playbackService.setPlaybackSpeed(normalizedSpeed);
      if (result.isSuccess()) {
        this.controlState.value = { ...this.controlState.value, playbackSpeed: normalizedSpeed };
        Logger.info(this.TAG, `Playback speed set to ${normalizedSpeed}x`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to set playback speed: ${error}`);
    }
  }
  
  // ==================== 剧集和线路切换 ====================
  
  /**
   * 切换剧集
   */
  public async switchEpisode(episode: Episode): Promise<void> {
    try {
      this.controlState.value = { ...this.controlState.value, isLoading: true };
      
      const result = await this.playbackService.switchEpisode(episode);
      if (result.isSuccess()) {
        // 更新剧集状态
        const episodes = this.mediaState.value.episodes.map(ep => ({
          ...ep,
          current: ep.id === episode.id
        }));
        
        this.mediaState.value = {
          ...this.mediaState.value,
          episodes,
          selectedEpisode: episode
        };
        
        Logger.info(this.TAG, `Switched to episode: ${episode.title}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to switch episode: ${error}`);
      this.handleError('剧集切换失败', error);
    } finally {
      this.controlState.value = { ...this.controlState.value, isLoading: false };
    }
  }
  
  /**
   * 切换解析线路
   */
  public async switchParseLine(line: ParseLine): Promise<void> {
    try {
      this.controlState.value = { ...this.controlState.value, isLoading: true };
      
      const result = await this.playbackService.switchParseLine(line);
      if (result.isSuccess()) {
        const parseLines = this.mediaState.value.parseLines.map(pl => ({
          ...pl,
          isCurrent: pl.id === line.id
        }));
        
        this.mediaState.value = {
          ...this.mediaState.value,
          parseLines,
          selectedLine: line
        };
        
        Logger.info(this.TAG, `Switched to parse line: ${line.name}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to switch parse line: ${error}`);
      this.handleError('线路切换失败', error);
    } finally {
      this.controlState.value = { ...this.controlState.value, isLoading: false };
    }
  }
  
  // ==================== UI控制方法 ====================
  
  /**
   * 显示/隐藏控制栏
   */
  public toggleControls(): void {
    const showControls = !this.uiState.value.showControls;
    this.uiState.value = { ...this.uiState.value, showControls };
    
    if (showControls) {
      this.startControlAutoHide();
    } else {
      this.clearControlAutoHideTimer();
    }
  }
  
  /**
   * 开始控制栏自动隐藏计时
   */
  private startControlAutoHide(): void {
    this.clearControlAutoHideTimer();
    
    const timerId = setTimeout(() => {
      this.uiState.value = { ...this.uiState.value, showControls: false };
    }, 3000); // 3秒后自动隐藏
    
    this.uiState.value = { ...this.uiState.value, controlHideTimer: timerId as unknown as number };
  }
  
  /**
   * 清除控制栏自动隐藏计时器
   */
  private clearControlAutoHideTimer(): void {
    const timerId = this.uiState.value.controlHideTimer;
    if (timerId) {
      clearTimeout(timerId);
      this.uiState.value = { ...this.uiState.value, controlHideTimer: null };
    }
  }
  
  /**
   * 更新屏幕信息
   */
  public updateScreenInfo(width: number, height: number): void {
    const isLandscape = width > height;
    this.uiState.value = {
      ...this.uiState.value,
      screenWidth: width,
      screenHeight: height,
      isLandscape
    };
    Logger.info(this.TAG, `Screen updated: ${width}x${height}, landscape: ${isLandscape}`);
  }
  
  // ==================== 错误处理 ====================
  
  private handleError(message: string, error: any): void {
    this.controlState.value = {
      ...this.controlState.value,
      isError: true,
      errorMessage: message,
      isLoading: false
    };
    Logger.error(this.TAG, `${message}: ${error}`);
  }
  
  // ==================== 清理方法 ====================
  
  public destroy(): void {
    this.clearControlAutoHideTimer();
    Logger.info(this.TAG, 'PlaybackViewModel destroyed');
  }
  
  // ==================== 状态快照 ====================
  
  public getStateSnapshot(): any {
    return {
      mediaState: this.mediaState.value,
      controlState: this.controlState.value,
      uiState: this.uiState.value,
      subtitleState: this.subtitleState.value,
      audioState: this.audioState.value,
      skipState: this.skipState.value,
      liveState: this.liveState.value
    };
  }
}

// ==================== 单例导出 ====================

let playbackViewModelInstance: PlaybackViewModel | null = null;

export function getPlaybackViewModel(): PlaybackViewModel {
  if (!playbackViewModelInstance) {
    playbackViewModelInstance = new PlaybackViewModel();
  }
  return playbackViewModelInstance;
}

export function destroyPlaybackViewModel(): void {
  if (playbackViewModelInstance) {
    playbackViewModelInstance.destroy();
    playbackViewModelInstance = null;
  }
}