// PlayerService - 播放器服务类
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import DateUtil from '../../common/util/DateUtil';
import ConfigService from './ConfigService';
import HistoryService from './HistoryService';
import RepositoryFactory from '../repository/RepositoryFactory';
import { DatabaseRepository } from '../repository/DatabaseRepository';

// 导入模型和DTO
import ApiResponse, { ResponseCode } from '../dto/ApiResponse';
import Movie, { VideoSource, VideoType, VideoQuality } from '../model/Movie';

// 常量定义
const TAG = 'PlayerService';
const PLAYBACK_STATE_KEY = 'playback_state';
const PLAYER_SETTINGS_KEY = 'player_settings';

// 播放状态枚举
export enum PlaybackStatus {
  IDLE = 'idle',          // 空闲
  LOADING = 'loading',      // 加载中
  READY = 'ready',        // 准备就绪
  PLAYING = 'playing',      // 播放中
  PAUSED = 'paused',        // 暂停
  BUFFERING = 'buffering',    // 缓冲中
  COMPLETED = 'completed',    // 播放完成
  ERROR = 'error'         // 播放错误
}

// 播放错误类型枚举
export enum PlaybackErrorType {
  NETWORK_ERROR = 'network_error',
  DECODE_ERROR = 'decode_error',
  PERMISSION_ERROR = 'permission_error',
  NOT_FOUND_ERROR = 'not_found_error',
  DRM_ERROR = 'drm_error',
  UNSUPPORTED_FORMAT_ERROR = 'unsupported_format_error',
  TIMEOUT_ERROR = 'timeout_error',
  MEMORY_ERROR = 'memory_error',
  UNKNOWN_ERROR = 'unknown_error'
}

/**
 * 解码器类型
 */
export enum DecodeType {
  SOFT = 'soft', // 软件解码
  HARD = 'hard'  // 硬件解码
}

// 播放速度预设
export const PLAYBACK_SPEEDS = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

// 字幕样式接口
export interface SubtitleStyle {
  enabled: boolean;          // 是否启用字幕
  size: number;             // 字幕大小（px）
  color: string;            // 字幕颜色
  backgroundColor?: string;  // 背景颜色
  fontFamily: string;        // 字体
  bold: boolean;            // 是否粗体
  italic: boolean;          // 是否斜体
  opacity: number;          // 透明度（0-1）
  delay: number;            // 字幕延迟（秒）
  position: 'bottom' | 'middle' | 'top'; // 字幕位置
  edgeType?: 'none' | 'outline' | 'dropShadow' | 'raised' | 'depressed'; // 边缘样式
  edgeColor?: string;       // 边缘颜色
}

// 默认字幕样式
export const DEFAULT_SUBTITLE_STYLE: SubtitleStyle = {
  enabled: true,
  size: 16,
  color: '#FFFFFF',
  backgroundColor: 'rgba(0, 0, 0, 0.5)',
  fontFamily: 'Arial',
  bold: false,
  italic: false,
  opacity: 1.0,
  delay: 0,
  position: 'bottom',
  edgeType: 'dropShadow',
  edgeColor: '#000000'
};

// 播放器设置接口
export interface PlayerSettings {
  playbackSpeed: number;          // 播放速度
  autoPlay: boolean;             // 是否自动播放
  autoNextEpisode: boolean;       // 是否自动播放下一集
  rememberPosition: boolean;      // 是否记住播放位置
  videoQuality: VideoQuality;     // 视频质量
  hardwareAcceleration: boolean;   // 是否启用硬件加速
  subtitleStyle: SubtitleStyle;    // 字幕样式
  backgroundPlayEnabled: boolean;  // 是否允许后台播放
  aspectRatio: 'auto' | '16:9' | '4:3' | '1:1' | 'stretch'; // 画面比例
  audioVolume: number;            // 音量（0-100）
  muted: boolean;                // 是否静音
  brightness: number;            // 亮度（0-100）
  contrast: number;              // 对比度（0-100）
  saturation: number;            // 饱和度（0-100）
  sharpness: number;             // 锐度（0-100）
  equalizerPreset: string;        // 均衡器预设
  skipForwardDuration: number;    // 快进时长（秒）
  skipBackwardDuration: number;   // 快退时长（秒）
  doubleTapToSeek: boolean;       // 是否支持双击快进快退
  gestureControlEnabled: boolean; // 是否启用手势控制
  lockScreenEnabled: boolean;     // 是否启用锁屏
  alwaysShowControls: boolean;    // 是否始终显示控件
  controlsTimeout: number;        // 控件自动隐藏时间（毫秒）
  decodeType: DecodeType;         // 解码器类型
  customStartTime: number | null; // 自定义开始时间（毫秒）
  customEndTime: number | null;   // 自定义结束时间（毫秒）
}

// 默认播放器设置
export const DEFAULT_PLAYER_SETTINGS: PlayerSettings = {
  playbackSpeed: 1.0,
  autoPlay: true,
  autoNextEpisode: true,
  rememberPosition: true,
  videoQuality: VideoQuality.HIGH,
  hardwareAcceleration: true,
  subtitleStyle: DEFAULT_SUBTITLE_STYLE,
  backgroundPlayEnabled: false,
  aspectRatio: 'auto',
  audioVolume: 100,
  muted: false,
  brightness: 100,
  contrast: 100,
  saturation: 100,
  sharpness: 100,
  equalizerPreset: 'normal',
  skipForwardDuration: 10,
  skipBackwardDuration: 10,
  doubleTapToSeek: true,
  gestureControlEnabled: true,
  lockScreenEnabled: true,
  alwaysShowControls: false,
  controlsTimeout: 3000,
  decodeType: DecodeType.HARD, // 默认使用硬件解码
  customStartTime: null, // 默认无自定义开始时间
  customEndTime: null // 默认无自定义结束时间
};

// 播放状态接口
export interface PlaybackState {
  movieId: string;              // 当前播放的电影ID
  currentTime: number;           // 当前播放时间（秒）
  duration: number;             // 总时长（秒）
  buffered: number;             // 缓冲进度（0-100）
  status: PlaybackStatus;        // 播放状态
  speed: number;                // 当前播放速度
  volume: number;               // 当前音量
  muted: boolean;               // 是否静音
  videoQuality: VideoQuality;    // 当前视频质量
  isLive: boolean;              // 是否为直播
  sourceIndex: number;          // 当前使用的视频源索引
  error?: {
    type: PlaybackErrorType;
    message: string;
  };
  lastUpdated: number;           // 最后更新时间
}

// 手势类型枚举
export enum GestureType {
  TAP = 'tap',
  DOUBLE_TAP = 'double_tap',
  SWIPE_LEFT = 'swipe_left',
  SWIPE_RIGHT = 'swipe_right',
  SWIPE_UP = 'swipe_up',
  SWIPE_DOWN = 'swipe_down',
  PINCH_IN = 'pinch_in',
  PINCH_OUT = 'pinch_out',
  LONG_PRESS = 'long_press'
}

// 手势区域枚举
export enum GestureRegion {
  LEFT = 'left',
  RIGHT = 'right',
  CENTER = 'center',
  TOP = 'top',
  BOTTOM = 'bottom'
}

/**
 * 播放器服务类
 * 负责管理视频播放相关功能
 */
export default class PlayerService {
  private static instance: PlayerService;
  private databaseRepo: DatabaseRepository;
  private configService: ConfigService;
  private historyService: HistoryService;
  
  private currentState: PlaybackState | null = null;
  private settings: PlayerSettings = { ...DEFAULT_PLAYER_SETTINGS };
  private isInitialized: boolean = false;
  private isPlayingInBackground: boolean = false;
  private autoPlayNextEpisodeTimeout: number | null = null;
  private isPlaybackInCustomRange: boolean = false; // 是否在自定义播放范围内
  
  // 当前播放的媒体信息
  private currentMovie: Movie | null = null;
  private currentSource: VideoSource | null = null;
  private availableSources: VideoSource[] = [];
  
  // 监听器
  private stateListeners: Array<(state: PlaybackState) => void> = [];
  private statusListeners: Map<PlaybackStatus, Array<(state: PlaybackState) => void>> = new Map();
  private settingsListeners: Array<(settings: PlayerSettings) => void> = [];
  private errorListeners: Array<(error: { type: PlaybackErrorType; message: string }) => void> = [];
  private gestureListeners: Map<GestureType, Array<(region: GestureRegion) => void>> = [];

  /**
   * 构造函数（私有，防止外部实例化）
   */
  private constructor() {
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
    this.configService = ConfigService.getInstance();
    this.historyService = HistoryService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): PlayerService {
    if (!PlayerService.instance) {
      PlayerService.instance = new PlayerService();
    }
    return PlayerService.instance;
  }

  /**
   * 初始化播放器服务
   */
  private async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing player service...');
      
      // 加载播放器设置
      const savedSettings = await StorageUtil.getObject<PlayerSettings>(PLAYER_SETTINGS_KEY);
      if (savedSettings) {
        this.settings = { ...DEFAULT_PLAYER_SETTINGS, ...savedSettings };
      }
      
      // 从配置服务同步设置
      await this.syncSettingsWithConfig();
      
      // 尝试恢复上次的播放状态
      const savedState = await StorageUtil.getObject<PlaybackState>(PLAYBACK_STATE_KEY);
      if (savedState) {
        this.currentState = savedState;
        Logger.info(TAG, `Restored playback state for movie: ${savedState.movieId}`);
      }
      
      // 设置默认播放状态
      if (!this.currentState) {
        this.currentState = {
          movieId: '',
          currentTime: 0,
          duration: 0,
          buffered: 0,
          status: PlaybackStatus.IDLE,
          speed: this.settings.playbackSpeed,
          volume: this.settings.audioVolume,
          muted: this.settings.muted,
          videoQuality: this.settings.videoQuality,
          isLive: false,
          sourceIndex: 0,
          lastUpdated: Date.now()
        };
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'Player service initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize player service', error);
    }
  }

  /**
   * 从配置服务同步设置
   */
  private async syncSettingsWithConfig(): Promise<void> {
    try {
      // 同步播放速度
      const playbackSpeed = await this.configService.getConfig('playbackSpeed');
      if (playbackSpeed.isSuccess() && typeof playbackSpeed.data === 'number') {
        this.settings.playbackSpeed = playbackSpeed.data;
      }
      
      // 同步自动播放
      const autoPlay = await this.configService.getConfig('autoPlay');
      if (autoPlay.isSuccess() && typeof autoPlay.data === 'boolean') {
        this.settings.autoPlay = autoPlay.data;
      }
      
      // 同步自动播放下一集
      const autoNextEpisode = await this.configService.getConfig('autoNextEpisode');
      if (autoNextEpisode.isSuccess() && typeof autoNextEpisode.data === 'boolean') {
        this.settings.autoNextEpisode = autoNextEpisode.data;
      }
      
      // 同步视频质量
      const videoQuality = await this.configService.getConfig('videoQuality');
      if (videoQuality.isSuccess() && typeof videoQuality.data === 'string') {
        const qualityMap: Record<string, VideoQuality> = {
          'low': VideoQuality.LOW,
          'medium': VideoQuality.MEDIUM,
          'high': VideoQuality.HIGH,
          'ultra': VideoQuality.ULTRA,
          'auto': VideoQuality.AUTO
        };
        if (qualityMap[videoQuality.data]) {
          this.settings.videoQuality = qualityMap[videoQuality.data];
        }
      }
      
      // 同步字幕设置
      const subtitleEnabled = await this.configService.getConfig('subtitleEnabled');
      if (subtitleEnabled.isSuccess() && typeof subtitleEnabled.data === 'boolean') {
        this.settings.subtitleStyle.enabled = subtitleEnabled.data;
      }
      
      const subtitleSize = await this.configService.getConfig('subtitleSize');
      if (subtitleSize.isSuccess() && typeof subtitleSize.data === 'number') {
        this.settings.subtitleStyle.size = subtitleSize.data;
      }
      
      const subtitleColor = await this.configService.getConfig('subtitleColor');
      if (subtitleColor.isSuccess() && typeof subtitleColor.data === 'string') {
        this.settings.subtitleStyle.color = subtitleColor.data;
      }
      
      const subtitleDelay = await this.configService.getConfig('subtitleDelay');
      if (subtitleDelay.isSuccess() && typeof subtitleDelay.data === 'number') {
        this.settings.subtitleStyle.delay = subtitleDelay.data;
      }
      
      // 同步后台播放设置
      const backgroundPlayEnabled = await this.configService.getConfig('backgroundPlayEnabled');
      if (backgroundPlayEnabled.isSuccess() && typeof backgroundPlayEnabled.data === 'boolean') {
        this.settings.backgroundPlayEnabled = backgroundPlayEnabled.data;
      }
      
      // 同步解码器类型
      const decodeType = await this.configService.getConfig('decodeType');
      if (decodeType.isSuccess() && typeof decodeType.data === 'string') {
        const decodeTypeMap: Record<string, DecodeType> = {
          'soft': DecodeType.SOFT,
          'hard': DecodeType.HARD
        };
        if (decodeTypeMap[decodeType.data]) {
          this.settings.decodeType = decodeTypeMap[decodeType.data];
        }
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to sync settings with config', error);
    }
  }

  /**
   * 加载媒体
   */
  public async loadMedia(
    movie: Movie,
    options?: {
      sourceIndex?: number;
      startTime?: number;
      autoPlay?: boolean;
      rememberPosition?: boolean;
    }
  ): Promise<ApiResponse<PlaybackState>> {
    try {
      Logger.info(TAG, `Loading media: ${movie.title} (${movie.id})`);
      
      // 取消之前可能的自动播放下一集定时器
      this.cancelAutoPlayNextEpisode();
      
      // 保存当前播放状态
      if (this.currentMovie && this.currentState) {
        await this.savePlaybackState();
        
        // 保存观看历史
        await this.saveWatchHistory();
      }
      
      // 设置当前电影
      this.currentMovie = movie;
      this.availableSources = movie.sources || [];
      
      // 选择视频源
      const sourceIndex = options?.sourceIndex ?? 0;
      if (sourceIndex >= 0 && sourceIndex < this.availableSources.length) {
        this.currentSource = this.availableSources[sourceIndex];
      } else if (this.availableSources.length > 0) {
        this.currentSource = this.availableSources[0];
      } else {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '没有可用的视频源');
      }
      
      // 确定起始播放时间
      let startTime = options?.startTime ?? 0;
      
      // 如果需要记住播放位置
      const rememberPosition = options?.rememberPosition ?? this.settings.rememberPosition;
      if (rememberPosition && startTime === 0) {
        const historyResult = await this.historyService.getHistory(movie.id);
        if (historyResult.isSuccess() && historyResult.data) {
          startTime = historyResult.data.progress || 0;
          Logger.info(TAG, `Restoring playback position: ${startTime}s`);
        }
      }
      
      // 创建新的播放状态
      this.currentState = {
        movieId: movie.id,
        currentTime: startTime,
        duration: movie.duration || 0,
        buffered: 0,
        status: PlaybackStatus.LOADING,
        speed: this.settings.playbackSpeed,
        volume: this.settings.audioVolume,
        muted: this.settings.muted,
        videoQuality: this.settings.videoQuality,
        isLive: movie.isLive || false,
        sourceIndex: sourceIndex,
        lastUpdated: Date.now()
      };
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifyStatusChanged(PlaybackStatus.LOADING);
      
      // 模拟加载完成（实际应用中，这里应该是真实的媒体加载逻辑）
      setTimeout(() => {
        this.onMediaLoaded();
        
        // 自动播放
        const shouldAutoPlay = options?.autoPlay ?? this.settings.autoPlay;
        if (shouldAutoPlay) {
          this.play();
        }
      }, 1000);
      
      return ApiResponse.success(this.currentState, '加载媒体成功');
    } catch (error) {
      Logger.error(TAG, `Failed to load media: ${movie.id}`, error);
      
      // 更新错误状态
      this.updateErrorState(PlaybackErrorType.UNKNOWN_ERROR, String(error));
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '加载媒体失败');
    }
  }

  /**
   * 媒体加载完成回调
   */
  private onMediaLoaded(): void {
    if (!this.currentState) return;
    
    // 更新状态为就绪
    this.currentState.status = PlaybackStatus.READY;
    this.currentState.buffered = 5; // 模拟初始缓冲进度
    this.currentState.lastUpdated = Date.now();
    
    // 通知状态变更
    this.notifyStateChanged();
    this.notifyStatusChanged(PlaybackStatus.READY);
    
    Logger.info(TAG, 'Media loaded successfully');
  }

  /**
   * 播放
   */
  public async play(): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState || !this.currentMovie) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      if (this.currentState.status === PlaybackStatus.COMPLETED) {
        // 如果播放已完成，从头开始播放
        this.currentState.currentTime = 0;
      }
      
      // 检查自定义开始时间
      if (this.settings.customStartTime !== null && this.currentState.currentTime < this.settings.customStartTime) {
        this.currentState.currentTime = this.settings.customStartTime;
        this.isPlaybackInCustomRange = true;
      }
      
      // 更新播放状态
      this.currentState.status = PlaybackStatus.PLAYING;
      this.currentState.speed = this.settings.playbackSpeed;
      this.currentState.lastUpdated = Date.now();
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifyStatusChanged(PlaybackStatus.PLAYING);
      
      // 开始模拟播放进度更新（实际应用中，这部分由播放器SDK自动处理）
      this.startPlaybackProgress();
      
      Logger.info(TAG, `Started playing: ${this.currentMovie.title}`);
      return ApiResponse.success(this.currentState, '播放开始');
    } catch (error) {
      Logger.error(TAG, 'Failed to play', error);
      
      // 更新错误状态
      this.updateErrorState(PlaybackErrorType.UNKNOWN_ERROR, String(error));
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '播放失败');
    }
  }

  /**
   * 暂停
   */
  public async pause(): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState || !this.currentMovie) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      if (this.currentState.status !== PlaybackStatus.PLAYING) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '媒体未在播放中');
      }
      
      // 停止进度更新
      this.stopPlaybackProgress();
      
      // 更新播放状态
      this.currentState.status = PlaybackStatus.PAUSED;
      this.currentState.lastUpdated = Date.now();
      
      // 保存当前状态
      await this.savePlaybackState();
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifyStatusChanged(PlaybackStatus.PAUSED);
      
      Logger.info(TAG, `Paused playback: ${this.currentMovie.title}`);
      return ApiResponse.success(this.currentState, '播放暂停');
    } catch (error) {
      Logger.error(TAG, 'Failed to pause playback', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '暂停失败');
    }
  }

  /**
   * 停止播放
   */
  public async stop(): Promise<ApiResponse<boolean>> {
    try {
      if (!this.currentState || !this.currentMovie) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      // 停止进度更新
      this.stopPlaybackProgress();
      
      // 取消自动播放下一集定时器
      this.cancelAutoPlayNextEpisode();
      
      // 保存播放状态
      await this.savePlaybackState();
      
      // 保存观看历史
      await this.saveWatchHistory();
      
      // 更新播放状态
      const oldStatus = this.currentState.status;
      this.currentState.status = PlaybackStatus.IDLE;
      this.currentState.currentTime = 0;
      this.currentState.buffered = 0;
      this.currentState.lastUpdated = Date.now();
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifyStatusChanged(PlaybackStatus.IDLE);
      
      Logger.info(TAG, `Stopped playback: ${this.currentMovie.title}`);
      return ApiResponse.success(true, '播放停止');
    } catch (error) {
      Logger.error(TAG, 'Failed to stop playback', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '停止播放失败');
    }
  }

  /**
   * 跳转到指定时间
   */
  public async seekTo(time: number): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState || !this.currentMovie) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      // 验证时间范围
      if (time < 0 || (this.currentState.duration > 0 && time > this.currentState.duration)) {
        return ApiResponse.validationError([
          { field: 'time', message: '时间超出有效范围' }
        ]);
      }
      
      // 更新播放位置
      this.currentState.currentTime = time;
      this.currentState.lastUpdated = Date.now();
      
      // 短时间内的跳转可能会触发缓冲
      if (Math.abs(this.currentState.currentTime - time) > 5) {
        this.currentState.status = PlaybackStatus.BUFFERING;
        this.notifyStatusChanged(PlaybackStatus.BUFFERING);
        
        // 模拟缓冲完成
        setTimeout(() => {
          if (this.currentState && this.currentState.status === PlaybackStatus.BUFFERING) {
            this.currentState.status = PlaybackStatus.PLAYING;
            this.notifyStatusChanged(PlaybackStatus.PLAYING);
          }
        }, 500);
      }
      
      // 通知状态变更
      this.notifyStateChanged();
      
      Logger.info(TAG, `Seeked to ${time}s`);
      return ApiResponse.success(this.currentState, '跳转成功');
    } catch (error) {
      Logger.error(TAG, `Failed to seek to ${time}s`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '跳转失败');
    }
  }

  /**
   * 快进
   */
  public async skipForward(): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      const skipDuration = this.settings.skipForwardDuration;
      const newTime = Math.min(this.currentState.currentTime + skipDuration, this.currentState.duration);
      
      return this.seekTo(newTime);
    } catch (error) {
      Logger.error(TAG, 'Failed to skip forward', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '快进失败');
    }
  }

  /**
   * 快退
   */
  public async skipBackward(): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      const skipDuration = this.settings.skipBackwardDuration;
      const newTime = Math.max(this.currentState.currentTime - skipDuration, 0);
      
      return this.seekTo(newTime);
    } catch (error) {
      Logger.error(TAG, 'Failed to skip backward', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '快退失败');
    }
  }

  /**
   * 设置播放速度
   */
  public async setPlaybackSpeed(speed: number): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      // 验证速度范围
      if (speed < 0.25 || speed > 4.0) {
        return ApiResponse.validationError([
          { field: 'speed', message: '播放速度必须在0.25-4.0之间' }
        ]);
      }
      
      // 更新播放速度
      this.currentState.speed = speed;
      this.settings.playbackSpeed = speed;
      this.currentState.lastUpdated = Date.now();
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifySettingsChanged();
      
      // 同步到配置服务
      await this.configService.setConfig('playbackSpeed', speed);
      
      Logger.info(TAG, `Set playback speed to ${speed}x`);
      return ApiResponse.success(this.currentState, '播放速度设置成功');
    } catch (error) {
      Logger.error(TAG, `Failed to set playback speed to ${speed}x`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '设置播放速度失败');
    }
  }

  /**
   * 设置音量
   */
  public async setVolume(volume: number): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      // 验证音量范围
      if (volume < 0 || volume > 100) {
        return ApiResponse.validationError([
          { field: 'volume', message: '音量必须在0-100之间' }
        ]);
      }
      
      // 更新音量
      this.currentState.volume = volume;
      this.settings.audioVolume = volume;
      this.currentState.lastUpdated = Date.now();
      
      // 如果音量不为0，取消静音
      if (volume > 0) {
        this.currentState.muted = false;
        this.settings.muted = false;
      }
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifySettingsChanged();
      
      Logger.info(TAG, `Set volume to ${volume}%`);
      return ApiResponse.success(this.currentState, '音量设置成功');
    } catch (error) {
      Logger.error(TAG, `Failed to set volume to ${volume}%`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '设置音量失败');
    }
  }

  /**
   * 切换静音状态
   */
  public async toggleMute(): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      // 切换静音状态
      this.currentState.muted = !this.currentState.muted;
      this.settings.muted = this.currentState.muted;
      this.currentState.lastUpdated = Date.now();
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifySettingsChanged();
      
      Logger.info(TAG, `Toggled mute: ${this.currentState.muted}`);
      return ApiResponse.success(this.currentState, `静音已${this.currentState.muted ? '开启' : '关闭'}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to toggle mute', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '切换静音状态失败');
    }
  }

  /**
   * 设置视频质量
   */
  public async setVideoQuality(quality: VideoQuality): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState || !this.currentMovie) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      // 检查是否支持该质量
      const hasQuality = this.availableSources.some(source => 
        source.quality === quality || quality === VideoQuality.AUTO
      );
      
      if (!hasQuality && quality !== VideoQuality.AUTO) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, `不支持的视频质量: ${quality}`);
      }
      
      // 更新视频质量
      this.currentState.videoQuality = quality;
      this.settings.videoQuality = quality;
      this.currentState.lastUpdated = Date.now();
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 同步到配置服务
      const qualityMap: Record<VideoQuality, string> = {
        [VideoQuality.LOW]: 'low',
        [VideoQuality.MEDIUM]: 'medium',
        [VideoQuality.HIGH]: 'high',
        [VideoQuality.ULTRA]: 'ultra',
        [VideoQuality.AUTO]: 'auto'
      };
      await this.configService.setConfig('videoQuality', qualityMap[quality]);
      
      // 切换视频源可能需要缓冲
      const oldStatus = this.currentState.status;
      this.currentState.status = PlaybackStatus.BUFFERING;
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifyStatusChanged(PlaybackStatus.BUFFERING);
      this.notifySettingsChanged();
      
      // 模拟缓冲完成
      setTimeout(() => {
        if (this.currentState && this.currentState.status === PlaybackStatus.BUFFERING) {
          this.currentState.status = oldStatus === PlaybackStatus.PLAYING ? PlaybackStatus.PLAYING : oldStatus;
          this.notifyStatusChanged(this.currentState.status);
        }
      }, 1000);
      
      Logger.info(TAG, `Set video quality to ${quality}`);
      return ApiResponse.success(this.currentState, '视频质量设置成功');
    } catch (error) {
      Logger.error(TAG, `Failed to set video quality to ${quality}`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '设置视频质量失败');
    }
  }

  /**
   * 切换视频源
   */
  public async switchVideoSource(sourceIndex: number): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentState || !this.currentMovie) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      // 验证视频源索引
      if (sourceIndex < 0 || sourceIndex >= this.availableSources.length) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '无效的视频源索引');
      }
      
      // 更新视频源
      this.currentSource = this.availableSources[sourceIndex];
      this.currentState.sourceIndex = sourceIndex;
      this.currentState.lastUpdated = Date.now();
      
      // 切换视频源需要缓冲
      const oldStatus = this.currentState.status;
      this.currentState.status = PlaybackStatus.BUFFERING;
      
      // 通知状态变更
      this.notifyStateChanged();
      this.notifyStatusChanged(PlaybackStatus.BUFFERING);
      
      // 模拟缓冲完成
      setTimeout(() => {
        if (this.currentState && this.currentState.status === PlaybackStatus.BUFFERING) {
          this.currentState.status = oldStatus === PlaybackStatus.PLAYING ? PlaybackStatus.PLAYING : oldStatus;
          this.notifyStatusChanged(this.currentState.status);
        }
      }, 1000);
      
      Logger.info(TAG, `Switched to video source index: ${sourceIndex}`);
      return ApiResponse.success(this.currentState, '视频源切换成功');
    } catch (error) {
      Logger.error(TAG, `Failed to switch video source to index: ${sourceIndex}`, error);
      
      // 更新错误状态
      this.updateErrorState(PlaybackErrorType.NETWORK_ERROR, '切换视频源失败');
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '切换视频源失败');
    }
  }

  /**
   * 设置字幕样式
   */
  public async setSubtitleStyle(style: Partial<SubtitleStyle>): Promise<ApiResponse<PlayerSettings>> {
    try {
      // 更新字幕样式
      this.settings.subtitleStyle = {
        ...this.settings.subtitleStyle,
        ...style
      };
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 同步到配置服务
      if (style.enabled !== undefined) {
        await this.configService.setConfig('subtitleEnabled', style.enabled);
      }
      if (style.size !== undefined) {
        await this.configService.setConfig('subtitleSize', style.size);
      }
      if (style.color !== undefined) {
        await this.configService.setConfig('subtitleColor', style.color);
      }
      if (style.delay !== undefined) {
        await this.configService.setConfig('subtitleDelay', style.delay);
      }
      
      // 通知设置变更
      this.notifySettingsChanged();
      
      Logger.info(TAG, 'Updated subtitle style');
      return ApiResponse.success(this.settings, '字幕样式设置成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to update subtitle style', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '设置字幕样式失败');
    }
  }

  /**
   * 获取当前播放状态
   */
  public getCurrentState(): PlaybackState | null {
    return this.currentState ? { ...this.currentState } : null;
  }

  /**
   * 获取当前播放的电影
   */
  public getCurrentMovie(): Movie | null {
    return this.currentMovie;
  }

  /**
   * 获取可用的视频源
   */
  public getAvailableSources(): VideoSource[] {
    return [...this.availableSources];
  }

  /**
   * 获取播放器设置
   */
  public getPlayerSettings(): PlayerSettings {
    return { ...this.settings };
  }

  /**
   * 设置自定义开始时间
   */
  public async setCustomStartTime(startTime: number | null): Promise<ApiResponse<PlayerSettings>> {
    try {
      // 验证开始时间
      if (startTime !== null && startTime < 0) {
        return ApiResponse.validationError([
          { field: 'startTime', message: '开始时间必须大于或等于0' }
        ]);
      }
      
      // 如果有结束时间，开始时间必须小于结束时间
      if (startTime !== null && this.settings.customEndTime !== null && startTime >= this.settings.customEndTime) {
        return ApiResponse.validationError([
          { field: 'startTime', message: '开始时间必须小于结束时间' }
        ]);
      }
      
      // 更新设置
      this.settings.customStartTime = startTime;
      
      // 如果当前正在播放，且设置了新的开始时间，检查是否需要跳转
      if (startTime !== null && this.currentState && this.currentState.status === PlaybackStatus.PLAYING) {
        if (this.currentState.currentTime < startTime) {
          await this.seekTo(startTime);
        }
        this.isPlaybackInCustomRange = true;
      }
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 通知设置变更
      this.notifySettingsChanged();
      
      Logger.info(TAG, `Set custom start time to ${startTime}ms`);
      return ApiResponse.success(this.settings, '自定义开始时间设置成功');
    } catch (error) {
      Logger.error(TAG, `Failed to set custom start time to ${startTime}ms`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '设置自定义开始时间失败');
    }
  }
  
  /**
   * 设置自定义结束时间
   */
  public async setCustomEndTime(endTime: number | null): Promise<ApiResponse<PlayerSettings>> {
    try {
      // 验证结束时间
      if (endTime !== null && endTime <= 0) {
        return ApiResponse.validationError([
          { field: 'endTime', message: '结束时间必须大于0' }
        ]);
      }
      
      // 如果有开始时间，结束时间必须大于开始时间
      if (endTime !== null && this.settings.customStartTime !== null && endTime <= this.settings.customStartTime) {
        return ApiResponse.validationError([
          { field: 'endTime', message: '结束时间必须大于开始时间' }
        ]);
      }
      
      // 更新设置
      this.settings.customEndTime = endTime;
      
      // 如果当前正在播放，启用自定义范围检查
      if (this.currentState && this.currentState.status === PlaybackStatus.PLAYING) {
        this.isPlaybackInCustomRange = true;
      }
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 通知设置变更
      this.notifySettingsChanged();
      
      Logger.info(TAG, `Set custom end time to ${endTime}ms`);
      return ApiResponse.success(this.settings, '自定义结束时间设置成功');
    } catch (error) {
      Logger.error(TAG, `Failed to set custom end time to ${endTime}ms`, error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '设置自定义结束时间失败');
    }
  }
  
  /**
   * 清除自定义时间范围
   */
  public async clearCustomTimeRange(): Promise<ApiResponse<PlayerSettings>> {
    try {
      this.settings.customStartTime = null;
      this.settings.customEndTime = null;
      this.isPlaybackInCustomRange = false;
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 通知设置变更
      this.notifySettingsChanged();
      
      Logger.info(TAG, 'Cleared custom time range');
      return ApiResponse.success(this.settings, '已清除自定义时间范围');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear custom time range', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '清除自定义时间范围失败');
    }
  }
  
  /**
   * 更新播放器设置
   */
  public async updatePlayerSettings(newSettings: Partial<PlayerSettings>): Promise<ApiResponse<PlayerSettings>> {
    try {
      // 更新设置
      this.settings = { ...this.settings, ...newSettings };
      
      // 更新当前播放状态（如果有）
      if (this.currentState) {
        if (newSettings.playbackSpeed !== undefined) {
          this.currentState.speed = newSettings.playbackSpeed;
        }
        if (newSettings.audioVolume !== undefined) {
          this.currentState.volume = newSettings.audioVolume;
        }
        if (newSettings.muted !== undefined) {
          this.currentState.muted = newSettings.muted;
        }
        if (newSettings.videoQuality !== undefined) {
          this.currentState.videoQuality = newSettings.videoQuality;
        }
        this.currentState.lastUpdated = Date.now();
      }
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 通知状态和设置变更
      if (this.currentState) {
        this.notifyStateChanged();
      }
      this.notifySettingsChanged();
      
      Logger.info(TAG, 'Player settings updated', newSettings);
      return ApiResponse.success(this.settings, '播放器设置更新成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to update player settings', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新播放器设置失败');
    }
  }

  /**
   * 切换解码器类型
   */
  public async switchDecodeType(): Promise<ApiResponse<PlayerSettings>> {
    try {
      // 切换解码器类型
      const newDecodeType = this.settings.decodeType === DecodeType.HARD ? DecodeType.SOFT : DecodeType.HARD;
      this.settings.decodeType = newDecodeType;
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 同步到配置服务
      await this.configService.setConfig('decodeType', newDecodeType);
      
      // 通知设置变更
      this.notifySettingsChanged();
      
      // 如果当前正在播放，重新加载媒体以应用新的解码器
      if (this.currentMovie && this.currentState && 
          (this.currentState.status === PlaybackStatus.PLAYING || 
           this.currentState.status === PlaybackStatus.PAUSED || 
           this.currentState.status === PlaybackStatus.READY)) {
        
        const currentTime = this.currentState.currentTime;
        const currentStatus = this.currentState.status;
        
        // 保存当前播放状态
        const saveResult = await this.savePlaybackState();
        
        if (saveResult.isSuccess()) {
          // 停止当前播放
          await this.stop();
          
          // 重新加载媒体
          await this.loadMedia(this.currentMovie, {
            sourceIndex: this.currentState?.sourceIndex || 0,
            startTime: currentTime,
            autoPlay: currentStatus === PlaybackStatus.PLAYING
          });
        }
      }
      
      Logger.info(TAG, `Switched decode type to ${newDecodeType}`);
      return ApiResponse.success(this.settings, `解码器已切换为${newDecodeType === DecodeType.HARD ? '硬件解码' : '软件解码'}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to switch decode type', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '切换解码器失败');
    }
  }
  
  /**
   * 获取当前解码器类型
   */
  public getDecodeType(): DecodeType {
    return this.settings.decodeType;
  }
  
  /**
   * 设置播放速度
   * @param speed 播放速度（0.5x-2.0x）
   */
  public async setPlaybackSpeed(speed: number): Promise<void> {
    try {
      // 验证播放速度范围
      if (speed < 0.5 || speed > 2.0) {
        Logger.error(TAG, 'Invalid playback speed: ' + speed);
        return;
      }
      
      // 更新设置
      this.settings.playbackSpeed = speed;
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 通知设置变更
      this.notifySettingsChanged();
      
      Logger.info(TAG, 'Playback speed set to: ' + speed + 'x');
    } catch (error) {
      Logger.error(TAG, 'Failed to set playback speed', error);
    }
  }
  
  /**
   * 获取当前播放速度
   */
  public getPlaybackSpeed(): number {
    return this.settings.playbackSpeed;
  }
  
  /**
   * 切换到下一个预设播放速度
   */
  public async togglePlaybackSpeed(): Promise<void> {
    try {
      const currentSpeed = this.settings.playbackSpeed;
      const speedIndex = PLAYBACK_SPEEDS.indexOf(currentSpeed);
      
      // 计算下一个速度索引
      let nextIndex = speedIndex + 1;
      if (nextIndex >= PLAYBACK_SPEEDS.length) {
        nextIndex = 0; // 循环回到第一个速度
      }
      
      // 设置下一个速度
      await this.setPlaybackSpeed(PLAYBACK_SPEEDS[nextIndex]);
    } catch (error) {
      Logger.error(TAG, 'Failed to toggle playback speed', error);
    }
  }
  
  /**
   * 快进
   * @param seconds 快进的秒数，默认使用设置中的值
   */
  public async forward(seconds?: number): Promise<void> {
    try {
      if (!this.currentState) {
        Logger.error(TAG, 'No active playback state');
        return;
      }
      
      const duration = seconds || this.settings.skipForwardDuration;
      const newTime = Math.min(
        this.currentState.currentTime + duration,
        this.currentState.duration || Infinity
      );
      
      // 更新播放时间
      this.currentState.currentTime = newTime;
      this.currentState.lastUpdated = Date.now();
      
      // 保存状态
      await this.savePlaybackState();
      
      // 通知状态变更
      this.notifyStateChanged();
      
      Logger.info(TAG, `Forwarded ${duration} seconds, current time: ${newTime}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to forward playback', error);
    }
  }
  
  /**
   * 快退
   * @param seconds 快退的秒数，默认使用设置中的值
   */
  public async rewind(seconds?: number): Promise<void> {
    try {
      if (!this.currentState) {
        Logger.error(TAG, 'No active playback state');
        return;
      }
      
      const duration = seconds || this.settings.skipBackwardDuration;
      const newTime = Math.max(0, this.currentState.currentTime - duration);
      
      // 更新播放时间
      this.currentState.currentTime = newTime;
      this.currentState.lastUpdated = Date.now();
      
      // 保存状态
      await this.savePlaybackState();
      
      // 通知状态变更
      this.notifyStateChanged();
      
      Logger.info(TAG, `Rewinded ${duration} seconds, current time: ${newTime}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to rewind playback', error);
    }
  }

  /**
   * 重置播放器设置
   */
  public async resetPlayerSettings(): Promise<ApiResponse<PlayerSettings>> {
    try {
      this.settings = { ...DEFAULT_PLAYER_SETTINGS };
      
      // 保存设置
      await this.savePlayerSettings();
      
      // 更新当前播放状态（如果有）
      if (this.currentState) {
        this.currentState.speed = this.settings.playbackSpeed;
        this.currentState.volume = this.settings.audioVolume;
        this.currentState.muted = this.settings.muted;
        this.currentState.videoQuality = this.settings.videoQuality;
        this.currentState.lastUpdated = Date.now();
      }
      
      // 通知状态和设置变更
      if (this.currentState) {
        this.notifyStateChanged();
      }
      this.notifySettingsChanged();
      
      Logger.info(TAG, 'Player settings reset to default');
      return ApiResponse.success(this.settings, '重置播放器设置成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to reset player settings', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '重置播放器设置失败');
    }
  }

  /**
   * 处理手势操作
   */
  public handleGesture(type: GestureType, region: GestureRegion): void {
    try {
      Logger.debug(TAG, `Handling gesture: ${type} in region: ${region}`);
      
      // 通知手势监听器
      this.notifyGesture(type, region);
      
      // 根据手势类型执行相应操作
      switch (type) {
        case GestureType.TAP:
          // 点击屏幕中心：播放/暂停切换
          if (region === GestureRegion.CENTER && this.currentState) {
            if (this.currentState.status === PlaybackStatus.PLAYING) {
              this.pause();
            } else if (this.currentState.status === PlaybackStatus.PAUSED || 
                      this.currentState.status === PlaybackStatus.READY) {
              this.play();
            }
          }
          break;
          
        case GestureType.DOUBLE_TAP:
          if (this.settings.doubleTapToSeek) {
            // 双击左侧：快退
            if (region === GestureRegion.LEFT) {
              this.skipBackward();
            }
            // 双击右侧：快进
            else if (region === GestureRegion.RIGHT) {
              this.skipForward();
            }
          }
          break;
          
        case GestureType.SWIPE_UP:
          // 左侧上滑：增加亮度
          if (region === GestureRegion.LEFT) {
            this.settings.brightness = Math.min(100, this.settings.brightness + 10);
            this.notifySettingsChanged();
          }
          // 右侧上滑：增加音量
          else if (region === GestureRegion.RIGHT) {
            this.setVolume(Math.min(100, this.settings.audioVolume + 10));
          }
          break;
          
        case GestureType.SWIPE_DOWN:
          // 左侧下滑：减小亮度
          if (region === GestureRegion.LEFT) {
            this.settings.brightness = Math.max(0, this.settings.brightness - 10);
            this.notifySettingsChanged();
          }
          // 右侧下滑：减小音量
          else if (region === GestureRegion.RIGHT) {
            this.setVolume(Math.max(0, this.settings.audioVolume - 10));
          }
          break;
          
        case GestureType.SWIPE_LEFT:
          // 左右滑动：快进/快退
          if (region === GestureRegion.CENTER) {
            this.skipForward();
          }
          break;
          
        case GestureType.SWIPE_RIGHT:
          if (region === GestureRegion.CENTER) {
            this.skipBackward();
          }
          break;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to handle gesture: ${type}`, error);
    }
  }

  /**
   * 开始后台播放
   */
  public async startBackgroundPlay(): Promise<ApiResponse<boolean>> {
    try {
      if (!this.settings.backgroundPlayEnabled) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '后台播放功能未启用');
      }
      
      if (!this.currentMovie || !this.currentState) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      this.isPlayingInBackground = true;
      
      Logger.info(TAG, 'Started background playback');
      return ApiResponse.success(true, '开始后台播放');
    } catch (error) {
      Logger.error(TAG, 'Failed to start background playback', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '开始后台播放失败');
    }
  }

  /**
   * 刷新播放
   */
  public async refresh(): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentMovie || !this.currentState) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      const currentTime = this.currentState.currentTime;
      const currentStatus = this.currentState.status;
      const sourceIndex = this.currentState.sourceIndex;
      
      // 停止当前播放
      await this.stop();
      
      // 重新加载媒体
      const loadResult = await this.loadMedia(this.currentMovie, {
        sourceIndex: sourceIndex,
        startTime: currentTime,
        autoPlay: currentStatus === PlaybackStatus.PLAYING
      });
      
      if (loadResult.isSuccess()) {
        Logger.info(TAG, 'Playback refreshed');
        return ApiResponse.success(loadResult.data, '刷新成功');
      } else {
        return ApiResponse.error(loadResult.code, '刷新失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to refresh playback', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '刷新失败');
    }
  }
  
  /**
   * 重播当前媒体
   */
  public async replay(): Promise<ApiResponse<PlaybackState>> {
    try {
      if (!this.currentMovie) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '没有加载媒体');
      }
      
      // 停止当前播放
      await this.stop();
      
      // 重新加载媒体，从开始位置播放
      const loadResult = await this.loadMedia(this.currentMovie, {
        sourceIndex: 0,
        startTime: 0,
        autoPlay: true
      });
      
      if (loadResult.isSuccess()) {
        // 重置自定义时间范围状态
        this.isPlaybackInCustomRange = false;
        
        Logger.info(TAG, 'Replaying media');
        return ApiResponse.success(loadResult.data, '开始重播');
      } else {
        return ApiResponse.error(loadResult.code, '重播失败');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to replay media', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '重播失败');
    }
  }
  
  /**
   * 播放下一集
   */
  public async playNextEpisode(): Promise<void> {
    try {
      Logger.info(TAG, 'Attempting to play next episode');
      
      if (!this.currentMovie || this.currentMovie.type !== VideoType.SERIES) {
        Logger.error(TAG, 'Current video is not a series');
        return;
      }
      
      // 获取当前视频的索引
      const currentIndex = this.availableVideoSources.findIndex(
        source => source.id === this.currentVideoSource?.id
      );
      
      // 检查是否有下一集
      if (currentIndex >= 0 && currentIndex < this.availableVideoSources.length - 1) {
        // 清除自定义时间范围
        this.clearCustomTimeRange();
        
        // 停止当前播放进度更新
        this.stopPlaybackProgress();
        
        // 保存当前播放状态
        await this.savePlaybackState();
        
        // 设置下一集为当前视频源
        this.currentVideoSource = this.availableVideoSources[currentIndex + 1];
        
        // 重置播放状态
        this.currentState = {
          currentTime: 0,
          duration: 0,
          buffered: 0,
          status: PlaybackStatus.LOADING,
          lastUpdated: Date.now()
        };
        
        // 通知状态变更
        this.notifyStateChanged();
        this.notifyStatusChanged(PlaybackStatus.LOADING);
        
        // 开始播放下一集
        await this.play();
        
        Logger.info(TAG, 'Playing next episode: ' + this.currentVideoSource.name);
      } else {
        Logger.info(TAG, 'No more episodes available');
        // 如果没有下一集，则暂停
        this.currentState.status = PlaybackStatus.PAUSED;
        this.notifyStateChanged();
        this.notifyStatusChanged(PlaybackStatus.PAUSED);
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to play next episode: ' + error);
      this.handleError(PlaybackError.PLAYBACK_FAILED);
    }
  }
  
  /**
   * 播放上一集
   */
  public async playPreviousEpisode(): Promise<void> {
    try {
      Logger.info(TAG, 'Attempting to play previous episode');
      
      if (!this.currentMovie || this.currentMovie.type !== VideoType.SERIES) {
        Logger.error(TAG, 'Current video is not a series');
        return;
      }
      
      // 获取当前视频的索引
      const currentIndex = this.availableVideoSources.findIndex(
        source => source.id === this.currentVideoSource?.id
      );
      
      // 检查是否有上一集
      if (currentIndex > 0) {
        // 清除自定义时间范围
        this.clearCustomTimeRange();
        
        // 停止当前播放进度更新
        this.stopPlaybackProgress();
        
        // 保存当前播放状态
        await this.savePlaybackState();
        
        // 设置上一集为当前视频源
        this.currentVideoSource = this.availableVideoSources[currentIndex - 1];
        
        // 重置播放状态
        this.currentState = {
          currentTime: 0,
          duration: 0,
          buffered: 0,
          status: PlaybackStatus.LOADING,
          lastUpdated: Date.now()
        };
        
        // 通知状态变更
        this.notifyStateChanged();
        this.notifyStatusChanged(PlaybackStatus.LOADING);
        
        // 开始播放上一集
        await this.play();
        
        Logger.info(TAG, 'Playing previous episode: ' + this.currentVideoSource.name);
      } else {
        Logger.info(TAG, 'No previous episode available');
        // 从头开始播放当前集
        await this.replay();
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to play previous episode: ' + error);
      this.handleError(PlaybackError.PLAYBACK_FAILED);
    }
  }

  /**
   * 停止后台播放
   */
  public async stopBackgroundPlay(): Promise<ApiResponse<boolean>> {
    try {
      if (!this.isPlayingInBackground) {
        return ApiResponse.success(true, '未在后台播放');
      }
      
      this.isPlayingInBackground = false;
      
      // 如果不在前台播放，保存播放状态
      if (this.currentState && this.currentState.status === PlaybackStatus.PLAYING) {
        this.currentState.status = PlaybackStatus.PAUSED;
        await this.savePlaybackState();
        await this.saveWatchHistory();
      }
      
      Logger.info(TAG, 'Stopped background playback');
      return ApiResponse.success(true, '停止后台播放');
    } catch (error) {
      Logger.error(TAG, 'Failed to stop background playback', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '停止后台播放失败');
    }
  }

  /**
   * 播放完成处理
   */
  private async onPlaybackCompleted(): Promise<void> {
    if (!this.currentState || !this.currentMovie) return;
    
    Logger.info(TAG, `Playback completed: ${this.currentMovie.title}`);
    
    // 更新播放状态
    this.currentState.status = PlaybackStatus.COMPLETED;
    this.currentState.currentTime = this.currentState.duration;
    this.currentState.lastUpdated = Date.now();
    
    // 保存播放状态
    await this.savePlaybackState();
    
    // 保存观看历史（标记为已完成）
    await this.historyService.addOrUpdateHistory({
      userId: 'current', // 实际应用中应该使用真实的用户ID
      contentId: this.currentMovie.id,
      contentType: this.currentMovie.type,
      title: this.currentMovie.title,
      progress: this.currentState.duration,
      duration: this.currentState.duration,
      isCompleted: true,
      lastWatchedAt: Date.now()
    });
    
    // 通知状态变更
    this.notifyStateChanged();
    this.notifyStatusChanged(PlaybackStatus.COMPLETED);
    
    // 自动播放下一集
    if (this.settings.autoNextEpisode && this.currentMovie.type === VideoType.SERIES) {
      // 这里应该实现获取下一集的逻辑
      // 为了演示，我们简单地延迟一下
      this.autoPlayNextEpisodeTimeout = setTimeout(() => {
        Logger.info(TAG, 'Auto-playing next episode would happen here');
        // 实际应用中，这里应该调用loadMedia加载下一集
      }, 5000);
    }
  }

  /**
   * 取消自动播放下一集
   */
  private cancelAutoPlayNextEpisode(): void {
    if (this.autoPlayNextEpisodeTimeout !== null) {
      clearTimeout(this.autoPlayNextEpisodeTimeout);
      this.autoPlayNextEpisodeTimeout = null;
    }
  }

  /**
   * 更新错误状态
   */
  private updateErrorState(type: PlaybackErrorType, message: string): void {
    if (!this.currentState) return;
    
    this.currentState.status = PlaybackStatus.ERROR;
    this.currentState.error = { type, message };
    this.currentState.lastUpdated = Date.now();
    
    // 通知状态变更
    this.notifyStateChanged();
    this.notifyStatusChanged(PlaybackStatus.ERROR);
    this.notifyError({ type, message });
  }

  /**
   * 保存播放状态
   */
  private async savePlaybackState(): Promise<void> {
    try {
      if (this.currentState) {
        await StorageUtil.setObject(PLAYBACK_STATE_KEY, this.currentState);
        Logger.debug(TAG, `Saved playback state for movie: ${this.currentState.movieId}`);
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to save playback state', error);
    }
  }

  /**
   * 保存播放器设置
   */
  private async savePlayerSettings(): Promise<void> {
    try {
      await StorageUtil.setObject(PLAYER_SETTINGS_KEY, this.settings);
      Logger.debug(TAG, 'Saved player settings');
    } catch (error) {
      Logger.error(TAG, 'Failed to save player settings', error);
    }
  }

  /**
   * 保存观看历史
   */
  private async saveWatchHistory(): Promise<void> {
    try {
      if (this.currentMovie && this.currentState) {
        const progressPercentage = this.currentState.duration > 0 
          ? (this.currentState.currentTime / this.currentState.duration) * 100 
          : 0;
        
        // 只有观看超过1%才保存历史
        if (progressPercentage >= 1) {
          await this.historyService.addOrUpdateHistory({
            userId: 'current', // 实际应用中应该使用真实的用户ID
            contentId: this.currentMovie.id,
            contentType: this.currentMovie.type,
            title: this.currentMovie.title,
            progress: this.currentState.currentTime,
            duration: this.currentState.duration,
            isCompleted: progressPercentage >= 95, // 观看95%以上视为完成
            lastWatchedAt: Date.now()
          });
        }
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to save watch history', error);
    }
  }

  // ========== 播放进度模拟 ==========

  private playbackProgressInterval: number | null = null;

  /**
   * 开始播放进度更新
   */
  private startPlaybackProgress(): void {
    // 清除之前的定时器
    this.stopPlaybackProgress();
    
    // 每秒更新一次播放进度
    this.playbackProgressInterval = setInterval(async () => {
      if (!this.currentState || this.currentState.status !== PlaybackStatus.PLAYING) {
        this.stopPlaybackProgress();
        return;
      }
      
      // 更新播放时间
      this.currentState.currentTime += this.currentState.speed;
      this.currentState.lastUpdated = Date.now();
      
      // 模拟缓冲进度
      if (this.currentState.buffered < 100) {
        this.currentState.buffered = Math.min(100, this.currentState.buffered + 2);
      }
      
      // 检查是否到达自定义结束时间
      if (this.isPlaybackInCustomRange && this.settings.customEndTime !== null && 
          this.currentState.currentTime >= this.settings.customEndTime) {
        this.stopPlaybackProgress();
        this.currentState.currentTime = this.settings.customEndTime;
        this.currentState.lastUpdated = Date.now();
        
        // 保存当前状态
        await this.savePlaybackState();
        
        // 尝试自动播放下一集
        if (this.settings.autoNextEpisode && this.currentMovie && this.currentMovie.type === VideoType.SERIES) {
          await this.playNextEpisode();
        } else {
          // 如果不能自动播放下一集，则暂停
          this.currentState.status = PlaybackStatus.PAUSED;
          this.notifyStateChanged();
          this.notifyStatusChanged(PlaybackStatus.PAUSED);
        }
        
        Logger.info(TAG, 'Reached custom end time');
        return;
      }
      
      // 检查是否播放完成
      if (this.currentState.duration > 0 && this.currentState.currentTime >= this.currentState.duration) {
        this.stopPlaybackProgress();
        await this.onPlaybackCompleted();
        return;
      }
      
      // 每分钟保存一次播放状态和历史
      if (Math.floor(this.currentState.currentTime) % 60 === 0 && this.currentState.currentTime > 0) {
        await Promise.all([
          this.savePlaybackState(),
          this.saveWatchHistory()
        ]);
      }
      
      // 通知状态变更
      this.notifyStateChanged();
    }, 1000);
  }

  /**
   * 停止播放进度更新
   */
  private stopPlaybackProgress(): void {
    if (this.playbackProgressInterval !== null) {
      clearInterval(this.playbackProgressInterval);
      this.playbackProgressInterval = null;
    }
  }

  // ========== 事件监听相关 ==========

  /**
   * 添加播放状态监听器
   */
  public addStateListener(listener: (state: PlaybackState) => void): () => void {
    this.stateListeners.push(listener);
    
    // 立即回调当前状态
    if (this.currentState) {
      listener(this.currentState);
    }
    
    // 返回取消监听函数
    return () => {
      const index = this.stateListeners.indexOf(listener);
      if (index > -1) {
        this.stateListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加播放状态变更监听器
   */
  public addStatusListener(status: PlaybackStatus, listener: (state: PlaybackState) => void): () => void {
    if (!this.statusListeners.has(status)) {
      this.statusListeners.set(status, []);
    }
    
    const listeners = this.statusListeners.get(status)!;
    listeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加播放器设置监听器
   */
  public addSettingsListener(listener: (settings: PlayerSettings) => void): () => void {
    this.settingsListeners.push(listener);
    
    // 立即回调当前设置
    listener(this.settings);
    
    // 返回取消监听函数
    return () => {
      const index = this.settingsListeners.indexOf(listener);
      if (index > -1) {
        this.settingsListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加错误监听器
   */
  public addErrorListener(listener: (error: { type: PlaybackErrorType; message: string }) => void): () => void {
    this.errorListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.errorListeners.indexOf(listener);
      if (index > -1) {
        this.errorListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加手势监听器
   */
  public addGestureListener(type: GestureType, listener: (region: GestureRegion) => void): () => void {
    if (!this.gestureListeners.has(type)) {
      this.gestureListeners.set(type, []);
    }
    
    const listeners = this.gestureListeners.get(type)!;
    listeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知播放状态变更
   */
  private notifyStateChanged(): void {
    if (!this.currentState) return;
    
    for (const listener of this.stateListeners) {
      try {
        listener({ ...this.currentState });
      } catch (error) {
        Logger.error(TAG, 'Error in state listener', error);
      }
    }
  }

  /**
   * 通知播放状态特定变更
   */
  private notifyStatusChanged(status: PlaybackStatus): void {
    if (!this.currentState || !this.statusListeners.has(status)) return;
    
    const listeners = this.statusListeners.get(status)!;
    for (const listener of listeners) {
      try {
        listener({ ...this.currentState });
      } catch (error) {
        Logger.error(TAG, `Error in status listener for ${status}`, error);
      }
    }
  }

  /**
   * 通知设置变更
   */
  private notifySettingsChanged(): void {
    for (const listener of this.settingsListeners) {
      try {
        listener({ ...this.settings });
      } catch (error) {
        Logger.error(TAG, 'Error in settings listener', error);
      }
    }
  }

  /**
   * 通知错误
   */
  private notifyError(error: { type: PlaybackErrorType; message: string }): void {
    for (const listener of this.errorListeners) {
      try {
        listener(error);
      } catch (error) {
        Logger.error(TAG, 'Error in error listener', error);
      }
    }
  }

  /**
   * 通知手势
   */
  private notifyGesture(type: GestureType, region: GestureRegion): void {
    if (!this.gestureListeners.has(type)) return;
    
    const listeners = this.gestureListeners.get(type)!;
    for (const listener of listeners) {
      try {
        listener(region);
      } catch (error) {
        Logger.error(TAG, `Error in gesture listener for ${type}`, error);
      }
    }
  }

  /**
   * 销毁播放器服务
   */
  public async destroy(): Promise<void> {
    try {
      Logger.info(TAG, 'Destroying player service...');
      
      // 停止播放
      this.stopPlaybackProgress();
      this.cancelAutoPlayNextEpisode();
      
      // 保存状态
      if (this.currentState) {
        await this.savePlaybackState();
        await this.saveWatchHistory();
      }
      
      // 清除监听器
      this.stateListeners = [];
      this.statusListeners.clear();
      this.settingsListeners = [];
      this.errorListeners = [];
      this.gestureListeners.clear();
      
      // 重置状态
      this.currentState = null;
      this.currentMovie = null;
      this.currentSource = null;
      this.availableSources = [];
      this.isPlayingInBackground = false;
      
      Logger.info(TAG, 'Player service destroyed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to destroy player service', error);
    }
  }
}