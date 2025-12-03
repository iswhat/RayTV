// PlaybackService.ets - 播放服务
// 负责视频播放控制、播放状态管理和播放队列管理

import Logger from '../../common/util/Logger';
import ConfigService from '../config/ConfigService';
import HistoryManager from './HistoryManager';
import AVPlay from '@ohos.multimedia.media';
import AudioManager from '@ohos.multimedia.audio';
import AudioRendererInfo from '@ohos.multimedia.audio';
import BusinessError from '@ohos.base';
import { DeviceInfoRepository } from '../../data/repository/DeviceInfoRepository';

// 常量定义
const TAG = 'PlaybackService';
const MAX_PLAYBACK_QUEUE_SIZE = 100;
const PLAYBACK_BUFFER_SIZE = 8 * 1024 * 1024; // 8MB
const MIN_RETRY_INTERVAL = 3000; // 最小重试间�?const MAX_RETRY_COUNT = 3; // 最大重试次�?
// 播放状态枚�?export enum PlaybackState {
  IDLE = 0,           // 空闲状�?  INITIALIZING = 1,   // 初始化中
  PREPARING = 2,      // 准备�?  READY = 3,          // 准备就绪
  PLAYING = 4,        // 播放�?  PAUSED = 5,         // 暂停
  SEEKING = 6,        // 跳转�?  BUFFERING = 7,      // 缓冲�?  COMPLETED = 8,      // 播放完成
  ERROR = 9           // 错误状�?}

// 播放错误类型枚举
export enum PlaybackErrorType {
  NETWORK = 0,        // 网络错误
  DECODE = 1,         // 解码错误
  PERMISSION = 2,     // 权限错误
  RESOURCE = 3,       // 资源错误
  TIMEOUT = 4,        // 超时错误
  DRM = 5,            // DRM错误
  UNKNOWN = 6         // 未知错误
}

// 音频路由类型枚举
export enum AudioRoute {
  SPEAKER = 0,        // 扬声�?  EARPIECE = 1,       // 听筒
  WIRED_HEADSET = 2,  // 有线耳机
  BLUETOOTH = 3       // 蓝牙耳机
}

// 播放速度枚举
export enum PlaybackSpeed {
  SPEED_0_5X = 0.5,
  SPEED_0_75X = 0.75,
  SPEED_1_0X = 1.0,
  SPEED_1_25X = 1.25,
  SPEED_1_5X = 1.5,
  SPEED_2_0X = 2.0
}

// 字幕风格接口
export interface SubtitleStyle {
  fontSize: number;      // 字体大小
  fontColor: string;     // 字体颜色
  backgroundColor: string; // 背景颜色
  edgeType: 'none' | 'dropShadow' | 'raised' | 'depressed' | 'uniform'; // 边缘类型
  edgeColor: string;     // 边缘颜色
  fontFamily: string;    // 字体
  bold: boolean;         // 是否粗体
  italic: boolean;       // 是否斜体
  opacity: number;       // 透明�?  position: 'bottom' | 'top' | 'custom'; // 位置
  customPosition?: number; // 自定义位置百分比
}

// 默认字幕风格
export const DEFAULT_SUBTITLE_STYLE: SubtitleStyle = {
  fontSize: 20,
  fontColor: '#FFFFFF',
  backgroundColor: 'rgba(0, 0, 0, 0.5)',
  edgeType: 'dropShadow',
  edgeColor: '#000000',
  fontFamily: 'default',
  bold: false,
  italic: false,
  opacity: 1.0,
  position: 'bottom'
};

// 视频元数据接�?export interface VideoMetadata {
  // 基础信息
  width?: number;           // 视频宽度
  height?: number;          // 视频高度
  aspectRatio?: number;     // 宽高�?  resolution?: string;      // 分辨率描述（�?080p, 4K�?  
  // 编码信息
  videoCodec?: string;      // 视频编码格式
  audioCodec?: string;      // 音频编码格式
  bitrate?: number;         // 比特�?  
  // 内容信息
  author?: string;          // 作�?上传�?  channelName?: string;     // 频道名称
  publishDate?: string;     // 发布日期
  description?: string;     // 描述
  
  // 分类信息
  category?: string;        // 分类
  tags?: string[];          // 标签
  
  // 统计信息
  viewCount?: number;       // 观看次数
  likeCount?: number;       // 点赞�?  commentCount?: number;    // 评论�?  
  // 其他自定义字�?  customData?: Record<string, string | number | boolean>; // 其他自定义数�?}

// 播放项接�?export interface PlaybackItem {
  id: string;               // 播放项ID
  title: string;            // 标题
  subtitle?: string;        // 副标�?  url: string;              // 播放地址
  type: 'video' | 'audio' | 'live'; // 类型
  duration: number;         // 总时长（毫秒�?  position?: number;        // 当前播放位置（毫秒）
  coverUrl?: string;        // 封面图片
  posterUrl?: string;       // 海报图片
  metadata?: VideoMetadata; // 额外元数�?  subtitles?: SubtitleItem[]; // 字幕列表
  currentSubtitleIndex?: number; // 当前字幕索引
}

// 字幕项接�?export interface SubtitleItem {
  id: string;               // 字幕ID
  title: string;            // 字幕标题
  language: string;         // 语言代码
  url: string;              // 字幕文件URL
  format: 'srt' | 'vtt' | 'ass' | 'ssa'; // 字幕格式
  isDefault?: boolean;      // 是否默认字幕
  isExternal?: boolean;     // 是否外部字幕
  encoding?: string;        // 编码格式
}

// 播放配置接口
export interface PlaybackConfig {
  autoPlay: boolean;        // 自动播放
  rememberPosition: boolean; // 记住播放位置
  defaultPlaybackSpeed: number; // 默认播放速度
  enableHardwareDecoding: boolean; // 启用硬件解码
  enableBackgroundPlayback: boolean; // 启用后台播放
  enableAutoPause: boolean; // 启用自动暂停
  autoPauseOnCall: boolean; // 通话时自动暂�?  enableAudioFocus: boolean; // 启用音频焦点
  audioRoute: AudioRoute;   // 音频路由
  bufferSize: number;       // 缓冲区大�?  bufferTime: number;       // 缓冲时间
  maxRetryCount: number;    // 最大重试次�?  subtitleStyle: SubtitleStyle; // 字幕样式
  volume: number;           // 音量
  mute: boolean;            // 是否静音
}

// 默认播放配置
export const DEFAULT_PLAYBACK_CONFIG: PlaybackConfig = {
  autoPlay: true,
  rememberPosition: true,
  defaultPlaybackSpeed: 1.0,
  enableHardwareDecoding: true,
  enableBackgroundPlayback: true,
  enableAutoPause: true,
  autoPauseOnCall: true,
  enableAudioFocus: true,
  audioRoute: AudioRoute.SPEAKER,
  bufferSize: PLAYBACK_BUFFER_SIZE,
  bufferTime: 5000,
  maxRetryCount: MAX_RETRY_COUNT,
  subtitleStyle: DEFAULT_SUBTITLE_STYLE,
  volume: 1.0,
  mute: false
};

// 播放错误接口
export interface PlaybackError {
  code: number;             // 错误�?  message: string;          // 错误信息
  type: PlaybackErrorType;  // 错误类型
  details?: Record<string, string | number | boolean | null>;            // 错误详情
}

// 缓冲信息接口
export interface BufferingInfo {
  percent: number;          // 缓冲百分�?  currentRange: { start: number; end: number }; // 当前缓冲范围
  loadedRanges: Array<{ start: number; end: number }>; // 已加载缓冲范�?  totalBytesLoaded: number; // 已加载字节数
  totalBytes: number;       // 总字节数
}

// 播放状态变化监听器类型
type PlaybackStateListener = (state: PlaybackState) => void;

// 播放错误监听器类�?type PlaybackErrorListener = (error: PlaybackError) => void;

// 播放进度监听器类�?type PlaybackProgressListener = (position: number, duration: number, percent: number) => void;

// 缓冲状态监听器类型
type BufferingStateListener = (info: BufferingInfo) => void;

// 播放队列变化监听器类�?type PlaybackQueueListener = (queue: PlaybackItem[], currentIndex: number) => void;

export default class PlaybackService {
  private static instance: PlaybackService;
  private configService: ConfigService;
  private historyManager: HistoryManager;
  private deviceInfoRepository: DeviceInfoRepository;
  private config: PlaybackConfig = DEFAULT_PLAYBACK_CONFIG;
  private retryCount: number = 0; // 错误重试计数
  private avPlayInstance: AVPlay | null = null;
  private currentPlaybackItem: PlaybackItem | null = null;
  private playbackQueue: PlaybackItem[] = [];
  private currentQueueIndex: number = -1;
  private currentState: PlaybackState = PlaybackState.IDLE;
  private playbackSpeed: number = 1.0;
  private volume: number = 1.0;
  private isMuted: boolean = false;
  private subtitleVisible: boolean = true;
  private retryCount: number = 0;
  private lastRetryTime: number = 0;
  private isInitialized: boolean = false;
  private audioManager: AudioManager | null = null;
  private isBackgroundPlaybackEnabled: boolean = false;
  private lastPosition: number = 0;
  private lastPositionUpdateTime: number = 0;
  private positionUpdateTimerId: number | null = null;
  
  // 监听器列�?  private stateListeners: PlaybackStateListener[] = [];
  private errorListeners: PlaybackErrorListener[] = [];
  private progressListeners: PlaybackProgressListener[] = [];
  private bufferingListeners: BufferingStateListener[] = [];
  private queueListeners: PlaybackQueueListener[] = [];

  /**
   * 获取单例实例
   */
  public static getInstance(): PlaybackService {
    if (!PlaybackService.instance) {
      PlaybackService.instance = new PlaybackService();
    }
    return PlaybackService.instance;
  }

  /**
   * 构造函�?   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.historyManager = HistoryManager.getInstance();
    this.deviceInfoRepository = DeviceInfoRepository.getInstance();
  }

  /**
   * 初始化播放服�?   * @param context 应用上下�?   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Playback service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing playback service...');

      // 加载配置
      await this.loadConfig();
      
      // 初始化音频管理器
      this.audioManager = AudioManager.getInstance(context);
      
      // 设置默认音量
      this.volume = this.config.volume;
      this.isMuted = this.config.mute;
      
      // 设置播放速度
      this.playbackSpeed = this.config.defaultPlaybackSpeed;
      
      this.isInitialized = true;
      Logger.info(TAG, 'Playback service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize playback service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('playbackConfig', DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG instanceof Error ? DEFAULT_PLAYBACK_CONFIG : new Error(String(DEFAULT_PLAYBACK_CONFIG)))))));
      if (savedConfig) {
        this.config = { ...DEFAULT_PLAYBACK_CONFIG, ...savedConfig };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load playback config: ${error}`);
    }
  }

  /**
   * 保存配置
   */
  public async saveConfig(config: Partial<PlaybackConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined instanceof Error ? ...config };
      
      // 更新运行时配�?      if (config.volume !== undefined : new Error(String(...config };
      
      // 更新运行时配�?      if (config.volume !== undefined))))))) {
        this.volume = config.volume;
        if (this.avPlayInstance) {
          this.avPlayInstance.setVolume(this.volume);
        }
      }
      
      if (config.mute !== undefined) {
        this.isMuted = config.mute;
        if (this.avPlayInstance) {
          this.avPlayInstance.setMute(this.isMuted);
        }
      }
      
      if (config.audioRoute !== undefined) {
        await this.setAudioRoute(config.audioRoute);
      }
      
      await this.configService.setConfig('playbackConfig', this.config);
    } catch (error) {
      Logger.error(TAG, `Failed to save playback config: ${error}`);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public getConfig(): PlaybackConfig {
    return { ...this.config };
  }

  /**
   * 创建AVPlay实例
   */
  private async createAVPlayInstance(): Promise<void> {
    try {
      // 如果已有实例，先释放
      if (this.avPlayInstance) {
        await this.releaseAVPlayInstance();
      }

      // 创建新实�?      this.avPlayInstance = await AVPlay.create();
      
      // 设置播放模式
      await this.avPlayInstance.setAutoPlay(this.config.autoPlay);
      await this.avPlayInstance.setLoop(false);
      
      // 根据设备能力设置最佳解码模�?      await this.setupOptimalDecodingMode();
      
      // 设置缓冲大小
      await this.avPlayInstance.setParameter('cacheSize', this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString( instanceof Error ? this.config.bufferSize.toString( : new Error(String(this.config.bufferSize.toString())))))));
      
      // 设置音量和静�?      await this.avPlayInstance.setVolume(this.isMuted ? 0 : this.volume);
      await this.avPlayInstance.setMute(this.isMuted);
      
      // 设置播放速度
      await this.avPlayInstance.setSpeed(this.playbackSpeed);
      
      // 注册事件监听
      this.setupEventListeners();
      
      Logger.info(TAG, 'AVPlay instance created successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to create AVPlay instance: ${error}`);
      throw error;
    }
  }
  
  /**
   * 根据设备能力设置最佳解码模�?   */
  private async setupOptimalDecodingMode(): Promise<void> {
    if (!this.avPlayInstance) return;
    
    try {
      // 检查设备是否支持硬件解�?      if (this.config.enableHardwareDecoding) {
        try {
          // 先尝试硬件解�?          await this.avPlayInstance.setParameter('videoDecodingMode', 'hardware' instanceof Error ? 'hardware' : new Error(String('hardware' instanceof Error ? 'hardware' instanceof Error ? 'hardware' : new Error(String('hardware' : new Error(String('hardware' instanceof Error ? 'hardware' : new Error(String('hardware' instanceof Error ? 'hardware' instanceof Error ? 'hardware' : new Error(String('hardware' instanceof Error ? 'hardware' instanceof Error ? 'hardware' : new Error(String('hardware' : new Error(String('hardware' instanceof Error ? 'hardware' : new Error(String('hardware' : new Error(String('hardware' instanceof Error ? 'hardware' : new Error(String('hardware' instanceof Error ? 'hardware' instanceof Error ? 'hardware' : new Error(String('hardware' : new Error(String('hardware' instanceof Error ? 'hardware' : new Error(String('hardware')))))));
          Logger.info(TAG, 'Hardware decoding enabled');
        } catch (error) {
          // 硬件解码失败，回退到软件解�?          Logger.warn(TAG, 'Hardware decoding not supported, falling back to software decoding');
          await this.avPlayInstance.setParameter('videoDecodingMode', 'software');
          // 更新配置，避免下次再次尝试失败的解码模式
          this.config.enableHardwareDecoding = false;
        }
      } else {
        // 直接使用软件解码
        await this.avPlayInstance.setParameter('videoDecodingMode', 'software');
        Logger.info(TAG, 'Software decoding enabled');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to setup decoding mode: ${error}`);
      // 确保至少设置为软件解�?      try {
        await this.avPlayInstance.setParameter('videoDecodingMode', 'software' instanceof Error ? 'software' : new Error(String('software' instanceof Error ? 'software' instanceof Error ? 'software' : new Error(String('software' : new Error(String('software' instanceof Error ? 'software' : new Error(String('software' instanceof Error ? 'software' instanceof Error ? 'software' : new Error(String('software' instanceof Error ? 'software' instanceof Error ? 'software' : new Error(String('software' : new Error(String('software' instanceof Error ? 'software' : new Error(String('software' : new Error(String('software' instanceof Error ? 'software' : new Error(String('software' instanceof Error ? 'software' instanceof Error ? 'software' : new Error(String('software' : new Error(String('software' instanceof Error ? 'software' : new Error(String('software')))))));
      } catch (fallbackError) {
        Logger.error(TAG, `Failed to fallback to software decoding: ${fallbackError}`);
      }
    }
  }

  /**
   * 设置事件监听�?   */
  private setupEventListeners(): void {
    if (!this.avPlayInstance) {
      return;
    }

    // 状态变化事�?    this.avPlayInstance.on('stateChange', (state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number instanceof Error ? (state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number : new Error(String((state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number instanceof Error ? (state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number instanceof Error ? (state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number : new Error(String((state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number : new Error(String((state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number instanceof Error ? (state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number : new Error(String((state: number, reason: number instanceof Error ? (state: number, reason: number : new Error(String((state: number, reason: number))))))) => {
      this.handleStateChange(state, reason);
    });

    // 错误事件
    this.avPlayInstance.on('error', async (error: BusinessError) => {
      await this.handlePlaybackError(error);
    });

    // 缓冲进度事件
    this.avPlayInstance.on('bufferingChange', (bufferingStatus: number, startBufferBytes: number, bufferingBytes: number, totalBytes: number) => {
      this.handleBufferingChange(bufferingStatus, startBufferBytes, bufferingBytes, totalBytes);
    });

    // 播放完成事件
    this.avPlayInstance.on('playbackComplete', () => {
      this.handlePlaybackComplete();
    });
  }

  /**
   * 处理状态变�?   */
  private handleStateChange(state: number, reason: number): void {
    let newState: PlaybackState;
    
    switch (state) {
      case 0: // AVPlayState.IDLE
        newState = PlaybackState.IDLE;
        break;
      case 1: // AVPlayState.INITIALIZED
        newState = PlaybackState.INITIALIZING;
        break;
      case 2: // AVPlayState.PREPARED
        newState = PlaybackState.READY;
        break;
      case 3: // AVPlayState.PLAYING
        newState = PlaybackState.PLAYING;
        this.startPositionUpdates();
        break;
      case 4: // AVPlayState.PAUSED
        newState = PlaybackState.PAUSED;
        this.stopPositionUpdates();
        break;
      case 5: // AVPlayState.COMPLETED
        newState = PlaybackState.COMPLETED;
        this.stopPositionUpdates();
        break;
      case 6: // AVPlayState.STOPPED
        newState = PlaybackState.IDLE;
        this.stopPositionUpdates();
        break;
      default:
        newState = PlaybackState.UNKNOWN;
        break;
    }
    
    this.updatePlaybackState(newState);
    Logger.info(TAG, `Playback state changed to: ${newState}, reason: ${reason}`);
  }

  /**
   * 处理播放错误
   */
  private async handlePlaybackError(error: BusinessError): Promise<void> {
    Logger.error(TAG, `Playback error occurred: ${JSON.stringify(error)}`);
    
    // 识别错误类型
    const errorType = this.determineErrorType(error);
    
    const playbackError: PlaybackError = {
      code: error.code || -1, message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError instanceof Error ? message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError : new Error(String(message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
    
    // 通知错误监听�?    this.notifyErrorListeners(playbackError)))))));
    
    // 更新播放状�?    this.updatePlaybackState(PlaybackState.ERROR);
    
    // 尝试自动恢复
    if (await this.attemptErrorRecovery(errorType)) {
      Logger.info(TAG, 'Successfully recovered from playback error');
    } else {
      Logger.warn(TAG, 'Failed to recover from playback error, giving up');
      // 保存播放位置以便后续恢复
      await this.savePlaybackPosition();
    }
  }
  
  /**
   * 确定错误类型
   */
  private determineErrorType(error: BusinessError): PlaybackErrorType {
    const errorCode = error.code || 0;
    const errorMessage = (error.message || '').toLowerCase();
    
    // 基于错误码和错误信息确定错误类型
    if (errorMessage.includes('network') || errorMessage.includes('connect') || errorMessage.includes('timeout')) {
      return PlaybackErrorType.NETWORK;
    } else if (errorMessage.includes('decode') || errorMessage.includes('codec') || errorMessage.includes('format')) {
      return PlaybackErrorType.DECODE;
    } else if (errorMessage.includes('permission') || errorMessage.includes('denied')) {
      return PlaybackErrorType.PERMISSION;
    } else if (errorMessage.includes('resource') || errorMessage.includes('not found')) {
      return PlaybackErrorType.RESOURCE;
    } else if (errorMessage.includes('timeout')) {
      return PlaybackErrorType.TIMEOUT;
    } else if (errorMessage.includes('drm')) {
      return PlaybackErrorType.DRM;
    } else {
      return PlaybackErrorType.UNKNOWN;
    }
  }
  
  /**
   * 尝试错误恢复
   */
  private async attemptErrorRecovery(errorType: PlaybackErrorType): Promise<boolean> {
    // 检查重试次数是否超�?    if (this.retryCount >= MAX_RETRY_COUNT) {
      Logger.warn(TAG, `Max retry count (${MAX_RETRY_COUNT}) reached`);
      return false;
    }
    
    // 增加重试计数
    this.retryCount++;
    Logger.info(TAG, `Attempting to recover from error, retry ${this.retryCount}/${MAX_RETRY_COUNT}`);
    
    try {
      // 等待一段时间再重试
      await new Promise(resolve => setTimeout(resolve, MIN_RETRY_INTERVAL * this.retryCount));
      
      switch (errorType) {
        case PlaybackErrorType.NETWORK:
          // 网络错误：重新加载媒�?          return await this.recoverFromNetworkError();
          
        case PlaybackErrorType.DECODE:
          // 解码错误：切换解码模式后重新加载
          return await this.recoverFromDecodeError();
          
        case PlaybackErrorType.TIMEOUT:
          // 超时错误：重新连�?          return await this.recoverFromTimeoutError();
          
        default:
          // 其他错误：尝试重新加�?          return await this.recoverFromGenericError();
      }
    } catch (error) {
      Logger.error(TAG, `Recovery attempt failed: ${error}`);
      return false;
    }
  }
  
  /**
   * 从网络错误恢�?   */
  private async recoverFromNetworkError(): Promise<boolean> {
    if (!this.currentPlaybackItem) return false;
    
    try {
      Logger.info(TAG, 'Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error' instanceof Error ? 'Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error' : new Error(String('Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error' instanceof Error ? 'Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error' instanceof Error ? 'Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error' : new Error(String('Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error' : new Error(String('Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error' instanceof Error ? 'Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error' : new Error(String('Recovering from network error' instanceof Error ? 'Recovering from network error' : new Error(String('Recovering from network error')))))));
      // 重新创建播放实例
      await this.createAVPlayInstance();
      if (!this.avPlayInstance) return false;
      
      // 重新设置数据�?      await this.avPlayInstance.setSource(this.currentPlaybackItem.url);
      await this.avPlayInstance.prepare();
      
      // 恢复到上次播放位�?      if (this.lastPosition > 0) {
        await this.avPlayInstance.seekTo(this.lastPosition);
      }
      
      // 恢复播放
      if (this.config.autoPlay) {
        await this.avPlayInstance.play();
        this.updatePlaybackState(PlaybackState.PLAYING);
      }
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to recover from network error: ${error}`);
      return false;
    }
  }
  
  /**
   * 从解码错误恢�?   */
  private async recoverFromDecodeError(): Promise<boolean> {
    if (!this.currentPlaybackItem) return false;
    
    try {
      Logger.info(TAG, 'Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error' instanceof Error ? 'Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error' : new Error(String('Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error' instanceof Error ? 'Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error' instanceof Error ? 'Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error' : new Error(String('Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error' : new Error(String('Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error' instanceof Error ? 'Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error' : new Error(String('Recovering from decode error' instanceof Error ? 'Recovering from decode error' : new Error(String('Recovering from decode error')))))));
      
      // 如果当前使用硬件解码，尝试切换到软件解码
      if (this.config.enableHardwareDecoding) {
        Logger.info(TAG, 'Switching from hardware to software decoding');
        this.config.enableHardwareDecoding = false;
        
        // 重新创建播放实例
        await this.createAVPlayInstance();
        if (!this.avPlayInstance) return false;
        
        // 重新设置数据�?        await this.avPlayInstance.setSource(this.currentPlaybackItem.url);
        await this.avPlayInstance.prepare();
        
        // 恢复到上次播放位�?        if (this.lastPosition > 0) {
          await this.avPlayInstance.seekTo(this.lastPosition);
        }
        
        // 恢复播放
        if (this.config.autoPlay) {
          await this.avPlayInstance.play();
          this.updatePlaybackState(PlaybackState.PLAYING);
        }
        
        return true;
      }
      
      return false;
    } catch (error) {
      Logger.error(TAG, `Failed to recover from decode error: ${error}`);
      return false;
    }
  }
  
  /**
   * 从超时错误恢�?   */
  private async recoverFromTimeoutError(): Promise<boolean> {
    // 超时错误处理，类似于网络错误
    return await this.recoverFromNetworkError();
  }
  
  /**
   * 从一般错误恢�?   */
  private async recoverFromGenericError(): Promise<boolean> {
    if (!this.currentPlaybackItem) return false;
    
    try {
      Logger.info(TAG, 'Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery' : new Error(String('Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery' : new Error(String('Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery' : new Error(String('Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery' : new Error(String('Attempting generic error recovery' instanceof Error ? 'Attempting generic error recovery' : new Error(String('Attempting generic error recovery')))))));
      // 释放并重新创建播放实�?      await this.releaseAVPlayInstance();
      await this.createAVPlayInstance();
      
      if (!this.avPlayInstance) return false;
      
      // 重新加载当前播放�?      await this.load(this.currentPlaybackItem, this.lastPosition);
      return true;
    } catch (error) {
      Logger.error(TAG, `Generic error recovery failed: ${error}`);
      return false;
    }
  }
  
  /**
   * 优化播放质量
   */
  public async optimizePlaybackQuality(): Promise<void> {
    try {
      // 获取设备能力
      const capabilities = await this.deviceInfoRepository.getDeviceCapabilities();
      
      if (!capabilities || !this.avPlayInstance) return;
      
      // 根据设备能力调整播放参数
      Logger.info(TAG, 'Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities' instanceof Error ? 'Optimizing playback quality based on device capabilities' : new Error(String('Optimizing playback quality based on device capabilities')))))));
      
      // 可以在这里添加更多的质量优化逻辑
      // 例如根据网络状况调整缓冲大小
      // 根据设备性能调整解码参数�?    } catch (error) {
      Logger.error(TAG, `Failed to optimize playback quality: ${error}`);
    }
  }
  
  /**
   * 保存播放位置
   */
  private async savePlaybackPosition(): Promise<void> {
    try {
      if (!this.currentPlaybackItem || !this.avPlayInstance) return;
      
      // 获取当前播放位置
      const position = await this.avPlayInstance.getCurrentTime();
      this.lastPosition = position;
      
      // 更新当前播放项的位置
      this.currentPlaybackItem.position = position;
      
      // 保存到历史记�?      if (this.historyManager) {
        await this.historyManager.savePlaybackHistory({
          id: this.currentPlaybackItem.id, title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( instanceof Error ? title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date( : new Error(String(title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date())))))).getTime()
        });
        Logger.info(TAG, `Saved playback position for ${this.currentPlaybackItem.id}: ${position}ms`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save playback position: ${error}`);
    }
  }

  /**
   * 处理缓冲变化
   */
  private handleBufferingChange(bufferingStatus: number, startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number instanceof Error ? startBufferBytes: number, bufferingBytes: number, totalBytes: number : new Error(String(startBufferBytes: number, bufferingBytes: number, totalBytes: number))))))): void {
    const percent = totalBytes > 0 ? Math.round((bufferingBytes / totalBytes) * 100) : 0;
    
    const bufferingInfo: BufferingInfo = {
      percent,
      currentRange: { start: startBufferBytes, end: startBufferBytes + bufferingBytes },
      loadedRanges: [{ start: startBufferBytes, end: startBufferBytes + bufferingBytes }],
      totalBytesLoaded: bufferingBytes,
      totalBytes
    };
    
    this.notifyBufferingListeners(bufferingInfo);
    
    // 更新状�?    if (bufferingStatus === 1) { // 缓冲�?      this.updatePlaybackState(PlaybackState.BUFFERING);
    } else if (bufferingStatus === 2 && this.currentState === PlaybackState.BUFFERING) { // 缓冲完成
      this.updatePlaybackState(PlaybackState.PLAYING);
    }
  }

  /**
   * 处理播放完成
   */
  private async handlePlaybackComplete(): Promise<void> {
    Logger.info(TAG, 'Playback completed');
    
    if (this.currentPlaybackItem) {
      // 更新历史记录
      await this.savePlaybackHistory(this.currentPlaybackItem.id, this.currentPlaybackItem.duration, true);
      
      // 尝试播放下一�?      if (this.playbackQueue.length > 0 && this.currentQueueIndex < this.playbackQueue.length - 1) {
        await this.playNext();
        return;
      }
    }
    
    this.updatePlaybackState(PlaybackState.COMPLETED);
  }

  /**
   * 确定错误类型
   */
  private determineErrorType(errorCode: number): PlaybackErrorType {
    // 根据错误码判断错误类�?    switch (errorCode) {
      case -2147483648: // 网络错误
        return PlaybackErrorType.NETWORK;
      case -2147483647: // 解码错误
        return PlaybackErrorType.DECODE;
      case -2147483646: // 权限错误
        return PlaybackErrorType.PERMISSION;
      case -2147483645: // 资源错误
        return PlaybackErrorType.RESOURCE;
      case -2147483644: // 超时错误
        return PlaybackErrorType.TIMEOUT;
      case -2147483643: // DRM错误
        return PlaybackErrorType.DRM;
      default:
        return PlaybackErrorType.UNKNOWN;
    }
  }

  /**
   * 处理播放重试
   */
  private async handlePlaybackRetry(error: PlaybackError): Promise<void> {
    const now = Date.now();
    
    // 检查是否满足重试条�?    if (
      this.retryCount < this.config.maxRetryCount && 
      (now - this.lastRetryTime > MIN_RETRY_INTERVAL) &&
      (error.type === PlaybackErrorType.NETWORK || error.type === PlaybackErrorType.TIMEOUT)
    ) {
      this.retryCount++;
      this.lastRetryTime = now;
      
      Logger.info(TAG, `Retrying playback, attempt ${this.retryCount} of ${this.config.maxRetryCount}`);
      
      try {
        // 重新加载当前播放�?        await this.load(this.currentPlaybackItem!, this.lastPosition);
      } catch (retryError) {
        Logger.error(TAG, `Playback retry failed: ${retryError}`);
      }
    } else {
      Logger.error(TAG, `Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type` instanceof Error ? `Maximum retry attempts reached or retry not allowed for error type` : new Error(String(`Maximum retry attempts reached or retry not allowed for error type`)))))));
    }
  }

  /**
   * 开始播放位置更�?   */
  private startPositionUpdates(): void {
    // 停止之前的定时器
    this.stopPositionUpdates();
    
    // 设置新的定时器，每秒更新一次进�?    this.positionUpdateTimerId = setInterval(async () => {
      await this.updatePlaybackProgress();
    }, 1000);
  }

  /**
   * 停止播放位置更新
   */
  private stopPositionUpdates(): void {
    if (this.positionUpdateTimerId !== null) {
      clearInterval(this.positionUpdateTimerId);
      this.positionUpdateTimerId = null;
    }
  }

  /**
   * 更新播放进度
   */
  private async updatePlaybackProgress(): Promise<void> {
    if (!this.avPlayInstance || !this.currentPlaybackItem) {
      return;
    }

    try {
      const position = await this.avPlayInstance.getCurrentTime();
      const duration = this.currentPlaybackItem.duration;
      const percent = duration > 0 ? Math.round((position / duration) * 100) : 0;
      
      this.lastPosition = position;
      this.lastPositionUpdateTime = Date.now();
      
      this.notifyProgressListeners(position, duration, percent);
      
      // 定期保存播放位置
      if (this.config.rememberPosition && (Date.now() - this.lastPositionUpdateTime > 10000)) { // �?0秒保存一�?        await this.savePlaybackPosition();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to update playback progress: ${error}`);
    }
  }

  /**
   * 加载播放�?   */
  public async load(playbackItem: PlaybackItem, position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0 instanceof Error ? position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0 : new Error(String(position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0 instanceof Error ? position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0 instanceof Error ? position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0 : new Error(String(position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0 : new Error(String(position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0 instanceof Error ? position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0 : new Error(String(position: number = 0 instanceof Error ? position: number = 0 : new Error(String(position: number = 0))))))): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Playback service not initialized');
    }

    try {
      // 重置状�?      this.retryCount = 0;
      this.updatePlaybackState(PlaybackState.INITIALIZING);
      
      // 保存当前播放�?      this.currentPlaybackItem = { ...playbackItem };
      this.lastPosition = position;
      
      // 创建或重置播放实�?      await this.createAVPlayInstance();
      
      if (!this.avPlayInstance) {
        throw new Error('Failed to create AVPlay instance');
      }
      
      // 初始化播放器
      await this.avPlayInstance.init();
      
      // 设置数据�?      await this.avPlayInstance.setSource(playbackItem.url);
      
      // 准备播放
      await this.avPlayInstance.prepare();
      
      // 恢复播放位置
      if (position > 0 && this.config.rememberPosition) {
        await this.avPlayInstance.seekTo(position);
      }
      
      // 自动播放
      if (this.config.autoPlay) {
        await this.play();
      }
      
    } catch (error) {
      Logger.error(TAG, `Failed to load playback item: ${error}`);
      this.updatePlaybackState(PlaybackState.ERROR);
      throw error;
    }
  }

  /**
   * 播放
   */
  public async play(): Promise<void> {
    if (!this.avPlayInstance || !this.currentPlaybackItem) {
      throw new Error('No playback item loaded');
    }

    try {
      await this.avPlayInstance.play();
      this.updatePlaybackState(PlaybackState.PLAYING);
    } catch (error) {
      Logger.error(TAG, `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}`)))))));
      this.updatePlaybackState(PlaybackState.ERROR);
      throw error;
    }
  }

  /**
   * 暂停
   */
  public async pause(): Promise<void> {
    if (!this.avPlayInstance) {
      throw new Error('No playback item loaded');
    }

    try {
      await this.avPlayInstance.pause();
      this.updatePlaybackState(PlaybackState.PAUSED);
      
      // 保存播放位置
      await this.savePlaybackPosition();
    } catch (error) {
      Logger.error(TAG, `Failed to pause: ${error}`);
      throw error;
    }
  }

  /**
   * 停止
   */
  public async stop(): Promise<void> {
    if (!this.avPlayInstance) {
      return;
    }

    try {
      // 保存播放位置
      await this.savePlaybackPosition();
      
      await this.avPlayInstance.stop();
      await this.avPlayInstance.release();
      
      this.avPlayInstance = null;
      this.updatePlaybackState(PlaybackState.IDLE);
      
      // 清除队列索引
      this.currentQueueIndex = -1;
    } catch (error) {
      Logger.error(TAG, `Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}` instanceof Error ? `Failed to stop: ${error}` : new Error(String(`Failed to stop: ${error}`)))))));
      throw error;
    }
  }

  /**
   * 跳转
   */
  public async seekTo(position: number): Promise<void> {
    if (!this.avPlayInstance || !this.currentPlaybackItem) {
      throw new Error('No playback item loaded');
    }

    try {
      // 验证位置
      const validPosition = Math.max(0, Math.min(position, this.currentPlaybackItem.duration));
      
      this.updatePlaybackState(PlaybackState.SEEKING);
      await this.avPlayInstance.seekTo(validPosition);
      
      this.lastPosition = validPosition;
      
      // 恢复之前的状�?      if (this.currentState === PlaybackState.PLAYING) {
        this.updatePlaybackState(PlaybackState.PLAYING);
      } else {
        this.updatePlaybackState(PlaybackState.PAUSED);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to seek to position ${position}: ${error}`);
      throw error;
    }
  }

  /**
   * 快进
   */
  public async fastForward(seconds: number = 10): Promise<void> {
    if (!this.avPlayInstance || !this.currentPlaybackItem) {
      throw new Error('No playback item loaded');
    }

    try {
      const currentPosition = await this.avPlayInstance.getCurrentTime();
      const newPosition = Math.min(currentPosition + (seconds * 1000), this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration instanceof Error ? this.currentPlaybackItem.duration : new Error(String(this.currentPlaybackItem.duration)))))));
      await this.seekTo(newPosition);
    } catch (error) {
      Logger.error(TAG, `Failed to fast forward: ${error}`);
      throw error;
    }
  }

  /**
   * 快退
   */
  public async fastRewind(seconds: number = 10): Promise<void> {
    if (!this.avPlayInstance || !this.currentPlaybackItem) {
      throw new Error('No playback item loaded');
    }

    try {
      const currentPosition = await this.avPlayInstance.getCurrentTime();
      const newPosition = Math.max(0, currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000 instanceof Error ? currentPosition - (seconds * 1000 : new Error(String(currentPosition - (seconds * 1000))))))));
      await this.seekTo(newPosition);
    } catch (error) {
      Logger.error(TAG, `Failed to fast rewind: ${error}`);
      throw error;
    }
  }

  /**
   * 设置播放速度
   */
  public async setPlaybackSpeed(speed: PlaybackSpeed | number): Promise<void> {
    if (!this.avPlayInstance) {
      throw new Error('No playback item loaded');
    }

    try {
      this.playbackSpeed = speed;
      await this.avPlayInstance.setSpeed(speed);
      Logger.info(TAG, `Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x` instanceof Error ? `Playback speed set to: ${speed}x` : new Error(String(`Playback speed set to: ${speed}x`)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to set playback speed: ${error}`);
      throw error;
    }
  }

  /**
   * 设置音量
   */
  public async setVolume(volume: number): Promise<void> {
    // 验证音量范围
    const validVolume = Math.max(0, Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1 : new Error(String(Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1 : new Error(String(Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1 : new Error(String(Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1 : new Error(String(Math.min(volume, 1 instanceof Error ? Math.min(volume, 1 : new Error(String(Math.min(volume, 1))))))));
    this.volume = validVolume;
    
    if (this.avPlayInstance) {
      try {
        await this.avPlayInstance.setVolume(this.isMuted ? 0 : validVolume);
      } catch (error) {
        Logger.error(TAG, `Failed to set volume: ${error}`);
      }
    }
    
    // 保存配置
    await this.saveConfig({ volume: validVolume });
  }

  /**
   * 设置静音
   */
  public async setMute(mute: boolean): Promise<void> {
    this.isMuted = mute;
    
    if (this.avPlayInstance) {
      try {
        await this.avPlayInstance.setMute(mute);
        if (!mute) {
          await this.avPlayInstance.setVolume(this.volume);
        }
      } catch (error) {
        Logger.error(TAG, `Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}` instanceof Error ? `Failed to set mute: ${error}` : new Error(String(`Failed to set mute: ${error}`)))))));
      }
    }
    
    // 保存配置
    await this.saveConfig({ mute });
  }

  /**
   * 设置音频路由
   */
  public async setAudioRoute(route: AudioRoute): Promise<void> {
    if (!this.audioManager) {
      return;
    }

    try {
      // 根据路由类型设置音频模式
      switch (route) {
        case AudioRoute.SPEAKER:
          await this.audioManager.setAudioScene(AudioManager.AudioSceneType.MEDIA);
          break;
        case AudioRoute.EARPIECE:
          await this.audioManager.setAudioScene(AudioManager.AudioSceneType.CALL);
          break;
        case AudioRoute.WIRED_HEADSET:
          // 有线耳机路由通常由系统自动处�?          await this.audioManager.setAudioScene(AudioManager.AudioSceneType.MEDIA);
          break;
        case AudioRoute.BLUETOOTH:
          // 蓝牙耳机路由通常由系统自动处�?          await this.audioManager.setAudioScene(AudioManager.AudioSceneType.MEDIA);
          break;
      }
      
      this.config.audioRoute = route;
      Logger.info(TAG, `Audio route set to: ${route}`);
    } catch (error) {
      Logger.error(TAG, `Failed to set audio route: ${error}`);
    }
  }

  /**
   * 保存播放位置
   */
  private async savePlaybackPosition(): Promise<void> {
    if (!this.currentPlaybackItem || !this.config.rememberPosition) {
      return;
    }

    try {
      if (this.avPlayInstance) {
        const currentTime = await this.avPlayInstance.getCurrentTime();
        this.lastPosition = currentTime;
      }
      
      // 只保存非完成状态的播放位置
      const isCompleted = this.lastPosition >= this.currentPlaybackItem.duration - 5000;
      if (!isCompleted) {
        await this.historyManager.savePlaybackPosition(
          this.currentPlaybackItem.id, this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
         instanceof Error ? this.lastPosition,
          this.currentPlaybackItem.duration
         : new Error(String(this.lastPosition,
          this.currentPlaybackItem.duration
        )))))));
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save playback position: ${error}`);
    }
  }

  /**
   * 保存播放历史
   */
  private async savePlaybackHistory(id: string, position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean instanceof Error ? position: number, isCompleted: boolean : new Error(String(position: number, isCompleted: boolean))))))): Promise<void> {
    if (!this.currentPlaybackItem) {
      return;
    }

    try {
      await this.historyManager.addToHistory({
        id,
        title: this.currentPlaybackItem.title,
        subtitle: this.currentPlaybackItem.subtitle,
        coverUrl: this.currentPlaybackItem.coverUrl,
        duration: this.currentPlaybackItem.duration,
        position,
        isCompleted,
        timestamp: Date.now(),
        type: this.currentPlaybackItem.type,
        metadata: this.currentPlaybackItem.metadata
      });
    } catch (error) {
      Logger.error(TAG, `Failed to save playback history: ${error}`);
    }
  }

  /**
   * 设置播放队列
   */
  public setPlaybackQueue(queue: PlaybackItem[], startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0 instanceof Error ? startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0 : new Error(String(startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0 instanceof Error ? startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0 instanceof Error ? startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0 : new Error(String(startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0 : new Error(String(startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0 instanceof Error ? startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0 : new Error(String(startIndex: number = 0 instanceof Error ? startIndex: number = 0 : new Error(String(startIndex: number = 0))))))): void {
    // 验证队列
    if (!Array.isArray(queue) || queue.length === 0) {
      throw new Error('Invalid playback queue');
    }
    
    // 限制队列大小
    this.playbackQueue = queue.slice(0, MAX_PLAYBACK_QUEUE_SIZE);
    
    // 验证起始索引
    this.currentQueueIndex = Math.max(0, Math.min(startIndex, this.playbackQueue.length - 1));
    
    this.notifyQueueListeners();
    Logger.info(TAG, `Playback queue set with ${this.playbackQueue.length} items, current index: ${this.currentQueueIndex}`);
  }

  /**
   * 添加到播放队�?   */
  public addToPlaybackQueue(item: PlaybackItem): void {
    if (this.playbackQueue.length >= MAX_PLAYBACK_QUEUE_SIZE) {
      throw new Error('Playback queue is full');
    }
    
    this.playbackQueue.push(item);
    this.notifyQueueListeners();
  }

  /**
   * 从播放队列移�?   */
  public removeFromPlaybackQueue(index: number): void {
    if (index < 0 || index >= this.playbackQueue.length) {
      throw new Error('Invalid queue index');
    }
    
    this.playbackQueue.splice(index, 1);
    
    // 更新当前索引
    if (index === this.currentQueueIndex) {
      if (this.currentQueueIndex >= this.playbackQueue.length) {
        this.currentQueueIndex = this.playbackQueue.length - 1;
      }
    } else if (index < this.currentQueueIndex) {
      this.currentQueueIndex--;
    }
    
    this.notifyQueueListeners();
  }

  /**
   * 播放上一�?   */
  public async playPrevious(): Promise<void> {
    if (this.playbackQueue.length === 0) {
      throw new Error('Playback queue is empty');
    }
    
    const newIndex = this.currentQueueIndex > 0 ? this.currentQueueIndex - 1 : this.playbackQueue.length - 1;
    await this.playQueueItem(newIndex);
  }

  /**
   * 播放下一�?   */
  public async playNext(): Promise<void> {
    if (this.playbackQueue.length === 0) {
      throw new Error('Playback queue is empty');
    }
    
    const newIndex = this.currentQueueIndex < this.playbackQueue.length - 1 ? this.currentQueueIndex + 1 : 0;
    await this.playQueueItem(newIndex);
  }

  /**
   * 播放队列中的指定�?   */
  public async playQueueItem(index: number): Promise<void> {
    if (index < 0 || index >= this.playbackQueue.length) {
      throw new Error('Invalid queue index');
    }
    
    const item = this.playbackQueue[index];
    
    // 保存当前播放位置
    await this.savePlaybackPosition();
    
    // 更新队列索引
    this.currentQueueIndex = index;
    
    // 加载并播放新�?    await this.load(item);
    
    this.notifyQueueListeners();
  }

  /**
   * 切换字幕显示
   */
  public toggleSubtitleVisibility(): boolean {
    this.subtitleVisible = !this.subtitleVisible;
    // TODO: 实现字幕显示控制
    Logger.info(TAG, `Subtitle visibility toggled to: ${this.subtitleVisible}`);
    return this.subtitleVisible;
  }

  /**
   * 设置字幕样式
   */
  public async setSubtitleStyle(style: Partial<SubtitleStyle>): Promise<void> {
    this.config.subtitleStyle = { ...this.config.subtitleStyle, ...style };
    // TODO: 实现字幕样式设置
    
    // 保存配置
    await this.saveConfig({ subtitleStyle: this.config.subtitleStyle });
  }

  /**
   * 选择字幕
   */
  public async selectSubtitle(index: number): Promise<void> {
    if (!this.currentPlaybackItem || !this.currentPlaybackItem.subtitles) {
      throw new Error('No subtitles available');
    }
    
    if (index < -1 || index >= this.currentPlaybackItem.subtitles.length) {
      throw new Error('Invalid subtitle index');
    }
    
    this.currentPlaybackItem.currentSubtitleIndex = index;
    // TODO: 实现字幕选择逻辑
    
    Logger.info(TAG, `Subtitle selected: ${index === -1 ? 'none' : this.currentPlaybackItem.subtitles[index]?.title}`);
  }

  /**
   * 启用后台播放
   */
  public setBackgroundPlaybackEnabled(enabled: boolean): void {
    this.isBackgroundPlaybackEnabled = enabled;
    // TODO: 实现后台播放逻辑
    Logger.info(TAG, `Background playback ${enabled ? 'enabled' : 'disabled'}`);
  }

  /**
   * 更新播放状�?   */
  private updatePlaybackState(state: PlaybackState): void {
    this.currentState = state;
    this.notifyStateListeners(state);
  }

  /**
   * 通知状态监听器
   */
  private notifyStateListeners(state: PlaybackState): void {
    for (const listener of this.stateListeners) {
      try {
        listener(state);
      } catch (error) {
        Logger.error(TAG, `Error in state listener: ${error}`);
      }
    }
  }

  /**
   * 通知错误监听�?   */
  private notifyErrorListeners(error: PlaybackError): void {
    for (const listener of this.errorListeners) {
      try {
        listener(error);
      } catch (error) {
        Logger.error(TAG, `Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}` instanceof Error ? `Error in error listener: ${error}` : new Error(String(`Error in error listener: ${error}`)))))));
      }
    }
  }

  /**
   * 通知进度监听�?   */
  private notifyProgressListeners(position: number, duration: number, percent: number): void {
    for (const listener of this.progressListeners) {
      try {
        listener(position, duration, percent);
      } catch (error) {
        Logger.error(TAG, `Error in progress listener: ${error}`);
      }
    }
  }

  /**
   * 通知缓冲监听�?   */
  private notifyBufferingListeners(info: BufferingInfo): void {
    for (const listener of this.bufferingListeners) {
      try {
        listener(info);
      } catch (error) {
        Logger.error(TAG, `Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}` instanceof Error ? `Error in buffering listener: ${error}` : new Error(String(`Error in buffering listener: ${error}`)))))));
      }
    }
  }

  /**
   * 通知队列监听�?   */
  private notifyQueueListeners(): void {
    for (const listener of this.queueListeners) {
      try {
        listener([...this.playbackQueue], this.currentQueueIndex);
      } catch (error) {
        Logger.error(TAG, `Error in queue listener: ${error}`);
      }
    }
  }

  /**
   * 添加状态监听器
   */
  public addStateListener(listener: PlaybackStateListener): void {
    this.stateListeners.push(listener);
  }

  /**
   * 移除状态监听器
   */
  public removeStateListener(listener: PlaybackStateListener): void {
    const index = this.stateListeners.indexOf(listener);
    if (index > -1) {
      this.stateListeners.splice(index, 1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1)))))));
    }
  }

  /**
   * 添加错误监听�?   */
  public addErrorListener(listener: PlaybackErrorListener): void {
    this.errorListeners.push(listener);
  }

  /**
   * 移除错误监听�?   */
  public removeErrorListener(listener: PlaybackErrorListener): void {
    const index = this.errorListeners.indexOf(listener);
    if (index > -1) {
      this.errorListeners.splice(index, 1);
    }
  }

  /**
   * 添加进度监听�?   */
  public addProgressListener(listener: PlaybackProgressListener): void {
    this.progressListeners.push(listener);
  }

  /**
   * 移除进度监听�?   */
  public removeProgressListener(listener: PlaybackProgressListener): void {
    const index = this.progressListeners.indexOf(listener);
    if (index > -1) {
      this.progressListeners.splice(index, 1);
    }
  }

  /**
   * 添加缓冲监听�?   */
  public addBufferingListener(listener: BufferingStateListener): void {
    this.bufferingListeners.push(listener);
  }

  /**
   * 移除缓冲监听�?   */
  public removeBufferingListener(listener: BufferingStateListener): void {
    const index = this.bufferingListeners.indexOf(listener);
    if (index > -1) {
      this.bufferingListeners.splice(index, 1);
    }
  }

  /**
   * 添加队列监听�?   */
  public addQueueListener(listener: PlaybackQueueListener): void {
    this.queueListeners.push(listener);
  }

  /**
   * 移除队列监听�?   */
  public removeQueueListener(listener: PlaybackQueueListener): void {
    const index = this.queueListeners.indexOf(listener);
    if (index > -1) {
      this.queueListeners.splice(index, 1);
    }
  }

  /**
   * 获取当前播放状�?   */
  public getPlaybackState(): PlaybackState {
    return this.currentState;
  }

  /**
   * 获取当前播放�?   */
  public getCurrentPlaybackItem(): PlaybackItem | null {
    return this.currentPlaybackItem ? { ...this.currentPlaybackItem } : null;
  }

  /**
   * 获取播放队列
   */
  public getPlaybackQueue(): PlaybackItem[] {
    return [...this.playbackQueue];
  }

  /**
   * 获取当前队列索引
   */
  public getCurrentQueueIndex(): number {
    return this.currentQueueIndex;
  }

  /**
   * 获取播放速度
   */
  public getPlaybackSpeed(): number {
    return this.playbackSpeed;
  }

  /**
   * 获取音量
   */
  public getVolume(): number {
    return this.volume;
  }

  /**
   * 获取静音状�?   */
  public isMuted(): boolean {
    return this.isMuted;
  }

  /**
   * 获取字幕可见状�?   */
  public isSubtitleVisible(): boolean {
    return this.subtitleVisible;
  }

  /**
   * 获取后台播放状�?   */
  public isBackgroundPlaybackEnabled(): boolean {
    return this.isBackgroundPlaybackEnabled;
  }

  /**
   * 释放AVPlay实例
   */
  private async releaseAVPlayInstance(): Promise<void> {
    if (!this.avPlayInstance) {
      return;
    }

    try {
      // 移除事件监听
      this.avPlayInstance.off('stateChange');
      this.avPlayInstance.off('error');
      this.avPlayInstance.off('bufferingChange');
      this.avPlayInstance.off('playbackComplete');
      
      // 停止和释�?      await this.avPlayInstance.stop();
      await this.avPlayInstance.release();
      
      this.avPlayInstance = null;
    } catch (error) {
      Logger.error(TAG, `Failed to release AVPlay instance: ${error}`);
    }
  }

  /**
   * 关闭播放服务
   */
  public async close(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    try {
      // 保存播放位置
      await this.savePlaybackPosition();
      
      // 保存播放历史
      if (this.currentPlaybackItem) {
        await this.savePlaybackHistory(
          this.currentPlaybackItem.id, this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         instanceof Error ? this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
         : new Error(String(this.lastPosition,
          this.currentState === PlaybackState.COMPLETED
        )))))));
      }
      
      // 释放播放实例
      await this.releaseAVPlayInstance();
      
      // 停止定时�?      this.stopPositionUpdates();
      
      // 重置状�?      this.currentState = PlaybackState.IDLE;
      this.currentPlaybackItem = null;
      this.playbackQueue = [];
      this.currentQueueIndex = -1;
      
      this.isInitialized = false;
      Logger.info(TAG, 'Playback service closed');
    } catch (error) {
      Logger.error(TAG, `Error closing playback service: ${error}`);
    }
  }
}


