/**
 * PlaybackService - 播放服务
 * 
 * 实现视频播放控制、状态管理、播放队列管理等功能，
 * 支持错误处理、网络质量监控、自动恢复等高级特性。
 * 
 * @example
 * ```typescript
 * // 获取PlaybackService实例
 * const playbackService = PlaybackService.getInstance();
 * 
 * // 初始化播放服务
 * await playbackService.initialize(context);
 * 
 * // 加载并播放视频
 * await playbackService.load({
 *   id: '1',
 *   title: '示例视频',
 *   url: 'https://example.com/video.mp4',
 *   type: 'video',
 *   duration: 3600
 * }, 0);
 * 
 * // 播放/暂停
 * await playbackService.play();
 * await playbackService.pause();
 * ```
 */

import Logger from '../../common/util/Logger';
import ConfigService from '../config/ConfigService';
import HistoryManager from './HistoryManager';
import PlaybackErrorHandler from './PlaybackErrorHandler';
import HttpService from '../HttpService';
import AVPlay from '@ohos.multimedia.media';
import AudioManager from '@ohos.multimedia.audio';
import AudioRendererInfo from '@ohos.multimedia.audio';
import BusinessError from '@ohos.base';
import common from '@ohos.app.ability.common';
import { DeviceInfoRepository } from '../../data/repository/DeviceInfoRepository';

// 类型别名定义
const Context = common.Context;

// 常量定义 | Constants
const TAG = 'PlaybackService';
const MAX_PLAYBACK_QUEUE_SIZE = 100;
const PLAYBACK_BUFFER_SIZE = 8 * 1024 * 1024; // 8MB
const MIN_BUFFER_SIZE = 4 * 1024 * 1024; // 4MB
const MAX_BUFFER_SIZE = 32 * 1024 * 1024; // 32MB
const MIN_RETRY_INTERVAL = 3000; // 最小重试间隔 | Minimum retry interval
const MAX_RETRY_COUNT = 3; // 最大重试次数 | Maximum retry count
const PRE_BUFFER_DURATION = 30; // 预缓冲时间（秒）| Pre-buffer duration (seconds)
const NETWORK_CHECK_INTERVAL = 5000; // 网络检查间隔 | Network check interval

// 播放状态枚举 | Playback state enum
export enum PlaybackState {
  IDLE = 0,           // 空闲状态 | Idle state
  INITIALIZING = 1,   // 初始化中 | Initializing
  PREPARING = 2,      // 准备中 | Preparing
  READY = 3,          // 准备就绪 | Ready
  PLAYING = 4,        // 播放中 | Playing
  PAUSED = 5,         // 暂停 | Paused
  SEEKING = 6,        // 跳转中 | Seeking
  BUFFERING = 7,      // 缓冲中 | Buffering
  COMPLETED = 8,      // 播放完成 | Completed
  ERROR = 9           // 错误状态 | Error state
}

// 播放错误类型枚举 | Playback error type enum
export enum PlaybackErrorType {
  NETWORK = 0,        // 网络错误 | Network error
  DECODE = 1,         // 解码错误 | Decode error
  PERMISSION = 2,     // 权限错误 | Permission error
  RESOURCE = 3,       // 资源错误 | Resource error
  TIMEOUT = 4,        // 超时错误 | Timeout error
  DRM = 5,            // DRM错误 | DRM error
  UNKNOWN = 6         // 未知错误 | Unknown error
}

// 音频路由类型枚举 | Audio route type enum
export enum AudioRoute {
  SPEAKER = 0,        // 扬声器 | Speaker
  EARPIECE = 1,       // 听筒 | Earpiece
  WIRED_HEADSET = 2,  // 有线耳机 | Wired headset
  BLUETOOTH = 3       // 蓝牙耳机 | Bluetooth
}

// 播放速度枚举 | Playback speed enum
export enum PlaybackSpeed {
  SPEED_0_5X = 0.5,
  SPEED_0_75X = 0.75,
  SPEED_1_0X = 1.0,
  SPEED_1_25X = 1.25,
  SPEED_1_5X = 1.5,
  SPEED_2_0X = 2.0
}

// 字幕样式接口 | Subtitle style interface
export interface SubtitleStyle {
  fontSize: number;      // 字体大小 | Font size
  fontColor: string;     // 字体颜色 | Font color
  backgroundColor: string; // 背景颜色 | Background color
  edgeType: 'none' | 'dropShadow' | 'raised' | 'depressed' | 'uniform'; // 边缘类型 | Edge type
  edgeColor: string;     // 边缘颜色 | Edge color
  fontFamily: string;    // 字体 | Font family
  bold: boolean;         // 是否粗体 | Bold
  italic: boolean;       // 是否斜体 | Italic
  opacity: number;       // 透明度 | Opacity
  position: 'bottom' | 'top' | 'custom'; // 位置 | Position
  customPosition?: number; // 自定义位置百分比 | Custom position percentage
}

// 默认字幕样式 | Default subtitle style
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

// 视频参数信息接口 | Video metadata interface
export interface VideoMetadata {
  // 基本信息 | Basic info
  width?: number;           // 视频宽度 | Video width
  height?: number;          // 视频高度 | Video height
  aspectRatio?: number;     // 宽高比 | Aspect ratio
  resolution?: string;      // 分辨率 | Resolution (e.g., 1080p, 4K)
  // 编码信息 | Encoding info
  videoCodec?: string;      // 视频编码格式 | Video codec
  audioCodec?: string;      // 音频编码格式 | Audio codec
  bitrate?: number;         // 比特率 | Bitrate
  // 内容信息 | Content info
  author?: string;          // 作者 | Author
  channelName?: string;     // 频道名称 | Channel name
  publishDate?: string;     // 发布日期 | Publish date
  description?: string;     // 描述 | Description
  
  // 分类信息 | Category info
  category?: string;        // 分类 | Category
  tags?: string[];          // 标签 | Tags
  
  // 统计信息 | Statistics info
  viewCount?: number;       // 观看次数 | View count
  likeCount?: number;       // 点赞数 | Like count
  commentCount?: number;    // 评论数 | Comment count
  // 其他自定义字段 | Other custom fields
  customData?: Record<string, string | number | boolean>; // 其他自定义数据 | Other custom data
}

// 播放项接口 | Playback item interface
export interface PlaybackItem {
  id: string;               // 播放项ID | Playback item ID
  title: string;            // 标题 | Title
  subtitle?: string;        // 副标题 | Subtitle
  url: string;              // 播放地址 | Playback URL
  type: 'video' | 'audio' | 'live'; // 类型 | Type
  duration: number;         // 总时长（秒）| Total duration (seconds)
  position?: number;        // 当前播放位置（毫秒）| Current playback position (milliseconds)
  coverUrl?: string;        // 封面图片 | Cover image
  posterUrl?: string;       // 预览图片 | Poster image
  metadata?: VideoMetadata; // 附加参数 | Metadata
  subtitles?: SubtitleItem[]; // 字幕列表 | Subtitle list
  currentSubtitleIndex?: number; // 当前字幕索引 | Current subtitle index
}

// 字幕项接口 | Subtitle item interface
export interface SubtitleItem {
  id: string;               // 字幕ID | Subtitle ID
  title: string;            // 字幕标题 | Subtitle title
  language: string;         // 语言代码 | Language code
  url: string;              // 字幕文件URL | Subtitle file URL
  format: 'srt' | 'vtt' | 'ass' | 'ssa'; // 字幕格式 | Subtitle format
  isDefault?: boolean;      // 是否默认字幕 | Default subtitle
  isExternal?: boolean;     // 是否外部字幕 | External subtitle
  encoding?: string;        // 编码格式 | Encoding
}

// 视频质量枚举 | Video quality enum
export enum VideoQuality {
  LOW = 'low',       // 低质量
  MEDIUM = 'medium', // 中质量
  HIGH = 'high',     // 高质量
  AUTO = 'auto'      // 自动
}

// 播放配置接口 | Playback config interface
export interface PlaybackConfig {
  autoPlay: boolean;        // 自动播放 | Auto play
  rememberPosition: boolean; // 记住播放位置 | Remember playback position
  defaultPlaybackSpeed: number; // 默认播放速度 | Default playback speed
  enableHardwareDecoding: boolean; // 启用硬件解码 | Enable hardware decoding
  enableBackgroundPlayback: boolean; // 启用后台播放 | Enable background playback
  enableAutoPause: boolean; // 启用自动暂停 | Enable auto pause
  autoPauseOnCall: boolean; // 通话时自动暂停 | Auto pause on call
  enableAudioFocus: boolean; // 启用音频焦点 | Enable audio focus
  audioRoute: AudioRoute;   // 音频路由 | Audio route
  bufferSize: number;       // 缓冲大小 | Buffer size
  bufferTime: number;       // 缓冲时间 | Buffer time
  maxRetryCount: number;    // 最大重试次数 | Max retry count
  subtitleStyle: SubtitleStyle; // 字幕样式 | Subtitle style
  volume: number;           // 音量 | Volume
  mute: boolean;            // 是否静音 | Mute
  enableAutoSkipIntro: boolean; // 启用自动跳过片头 | Enable auto skip intro
  enableAutoSkipOutro: boolean; // 启用自动跳过片尾 | Enable auto skip outro
  introDuration: number;    // 片头时长（秒）| Intro duration (seconds)
  outroDuration: number;    // 片尾时长（秒）| Outro duration (seconds)
  enableAdaptiveQuality: boolean; // 启用自适应画质 | Enable adaptive quality
  defaultVideoQuality: VideoQuality; // 默认视频质量 | Default video quality
  qualitySwitchThresholds: {
    excellent: VideoQuality; // 优秀网络质量对应的视频质量
    good: VideoQuality;      // 良好网络质量对应的视频质量
    fair: VideoQuality;      // 一般网络质量对应的视频质量
    poor: VideoQuality;      // 较差网络质量对应的视频质量
  };
  enablePictureInPicture: boolean; // 启用画中画模式 | Enable picture-in-picture mode
  pipPosition: {
    x: number; // 画中画位置X坐标 | PIP position X coordinate
    y: number; // 画中画位置Y坐标 | PIP position Y coordinate
    width: number; // 画中画宽度 | PIP width
    height: number; // 画中画高度 | PIP height
  };
}

// 默认播放配置 | Default playback config
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
  mute: false,
  enableAutoSkipIntro: false,
  enableAutoSkipOutro: false,
  introDuration: 0, // 片头时长（秒）| Intro duration (seconds)
  outroDuration: 0, // 片尾时长（秒）| Outro duration (seconds)
  enableAdaptiveQuality: true,
  defaultVideoQuality: VideoQuality.AUTO,
  qualitySwitchThresholds: {
    excellent: VideoQuality.HIGH,
    good: VideoQuality.HIGH,
    fair: VideoQuality.MEDIUM,
    poor: VideoQuality.LOW
  },
  enablePictureInPicture: true,
  pipPosition: {
    x: 20, // 默认位置：左上角20px
    y: 20,
    width: 320, // 默认宽度320px
    height: 180 // 默认高度180px
  }
};

// 播放错误接口 | Playback error interface
export interface PlaybackError {
  code: number;             // 错误码 | Error code
  message: string;          // 错误信息 | Error message
  type: PlaybackErrorType;  // 错误类型 | Error type
  details?: Record<string, string | number | boolean | null>;            // 错误详情 | Error details
}

// 缓冲信息接口 | Buffering info interface
export interface BufferingInfo {
  percent: number;          // 缓冲百分比 | Buffering percentage
  currentRange: { start: number; end: number }; // 当前缓冲范围 | Current buffer range
  loadedRanges: Array<{ start: number; end: number }>; // 已加载缓冲范围 | Loaded buffer ranges
  totalBytesLoaded: number; // 已加载字节数 | Total bytes loaded
  totalBytes: number;       // 总字节数 | Total bytes
}

// 播放状态变化监听器类型 | Playback state change listener type
type PlaybackStateListener = (state: PlaybackState) => void;

// 播放错误监听器类型 | Playback error listener type
type PlaybackErrorListener = (error: PlaybackError) => void;

// 播放进度监听器类型 | Playback progress listener type
type PlaybackProgressListener = (position: number, duration: number, percent: number) => void;

// 缓冲状态监听器类型 | Buffering state listener type
type BufferingStateListener = (info: BufferingInfo) => void;

// 播放队列变化监听器类型 | Playback queue change listener type
type PlaybackQueueListener = (queue: PlaybackItem[], currentIndex: number) => void;

// 画中画状态监听器类型 | Picture-in-picture state listener type
type PipStateListener = (isPip: boolean, position?: { x: number; y: number; width: number; height: number }) => void;

export default class PlaybackService {
  private static instance: PlaybackService;
  private configService: ConfigService;
  private historyManager: HistoryManager;
  private deviceInfoRepository: DeviceInfoRepository;
  private config: PlaybackConfig = DEFAULT_PLAYBACK_CONFIG;
  private retryCount: number = 0; // 错误重试次数 Error retry count
  private avPlayInstance: AVPlay | null = null;
  private currentPlaybackItem: PlaybackItem | null = null;
  private playbackQueue: PlaybackItem[] = [];
  private currentQueueIndex: number = -1;
  private currentState: PlaybackState = PlaybackState.IDLE;
  private playbackSpeed: number = 1.0;
  private volume: number = 1.0;
  private isMuted: boolean = false;
  private subtitleVisible: boolean = true;
  private lastRetryTime: number = 0;
  private isInitialized: boolean = false;
  private audioManager: AudioManager | null = null;
  private isBackgroundPlaybackEnabled: boolean = false;
  private lastPosition: number = 0;
  private lastPositionUpdateTime: number = 0;
  private positionUpdateTimerId: number | null = null;
  private networkCheckTimerId: number | null = null;
  private currentNetworkQuality: 'excellent' | 'good' | 'fair' | 'poor' = 'good';
  private adaptiveBufferSize: number = PLAYBACK_BUFFER_SIZE;
  private errorHandler: PlaybackErrorHandler = new PlaybackErrorHandler();
  private hasSkippedIntro: boolean = false; // 是否已跳过片头
  private hasSkippedOutro: boolean = false; // 是否已跳片尾
  private currentVideoQuality: VideoQuality = VideoQuality.HIGH; // 当前视频质量
  private isPictureInPicture: boolean = false; // 是否处于画中画模式
  private currentPipPosition: { x: number; y: number; width: number; height: number } = { ...DEFAULT_PLAYBACK_CONFIG.pipPosition };
  
  // 监听器列表 Listener list
  private stateListeners: PlaybackStateListener[] = [];
  private errorListeners: PlaybackErrorListener[] = [];
  private progressListeners: PlaybackProgressListener[] = [];
  private bufferingListeners: BufferingStateListener[] = [];
  private queueListeners: PlaybackQueueListener[] = [];
  
  private pipStateListeners: PipStateListener[] = [];

  /**
   * 获取单例实例
   * 
   * 获取PlaybackService的单例实例，确保整个应用中只有一个播放服务实例。
   * 
   * @returns {PlaybackService} PlaybackService的单例实例
   * 
   * @example
   * ```typescript
   * const playbackService = PlaybackService.getInstance();
   * ```
   */
  public static getInstance(): PlaybackService {
    if (!PlaybackService.instance) {
      PlaybackService.instance = new PlaybackService();
    }
    return PlaybackService.instance;
  }

  /**
   * 构造函数 | Constructor
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.historyManager = HistoryManager.getInstance();
    this.deviceInfoRepository = DeviceInfoRepository.getInstance();
  }

  /**
   * 初始化播放服务
   * 
   * 初始化播放服务，加载配置，初始化音频管理器，设置默认参数。
   * 
   * @param {Context} context - 应用上下文
   * 
   * @example
   * ```typescript
   * await playbackService.initialize(context);
   * console.log('Playback service initialized');
   * ```
   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Playback service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing playback service...');

      // 加载配置 | Load config
      await this.loadConfig();
      
      // 初始化音频管理器 | Initialize audio manager
      this.audioManager = AudioManager.getInstance(context);
      
      // 设置默认音量 | Set default volume
      this.volume = this.config.volume;
      this.isMuted = this.config.mute;
      
      // 设置播放速度 | Set playback speed
      this.playbackSpeed = this.config.defaultPlaybackSpeed;
      
      // 初始化网络状态检测 | Initialize network status detection
      this.startNetworkQualityMonitoring();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Playback service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize playback service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 加载配置 | Loads config
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('playbackConfig', DEFAULT_PLAYBACK_CONFIG);
      if (savedConfig) {
        this.config = { ...DEFAULT_PLAYBACK_CONFIG, ...savedConfig };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load playback config: ${error}`);
    }
  }

  /**
   * 保存配置
   * 
   * 保存播放配置，更新运行时参数，并持久化到存储中。
   * 
   * @param {Partial<PlaybackConfig>} config - 要保存的配置
   * 
   * @example
   * ```typescript
   * await playbackService.saveConfig({
   *   autoPlay: true,
   *   volume: 0.8,
   *   enableHardwareDecoding: true
   * });
   * ```
   */
  public async saveConfig(config: Partial<PlaybackConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      
      // 更新运行时配置 Update runtime config
      if (config.volume !== undefined) {
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
   * 
   * 获取当前的播放配置。
   * 
   * @returns {PlaybackConfig} 当前的播放配置
   * 
   * @example
   * ```typescript
   * const config = playbackService.getConfig();
   * console.log('Auto play:', config.autoPlay);
   * console.log('Volume:', config.volume);
   * ```
   */
  public getConfig(): PlaybackConfig {
    return { ...this.config };
  }

  /**
   * 创建AVPlay实例 | Creates AVPlay instance
   */
  private async createAVPlayInstance(): Promise<void> {
    try {
      // 如果已有实例，先释放 | If instance exists, release first
      if (this.avPlayInstance) {
        await this.releaseAVPlayInstance();
      }

      // 创建新实例 | Create new instance
      this.avPlayInstance = await AVPlay.create();
      
      // 设置播放模式 | Set playback mode
      await this.avPlayInstance.setAutoPlay(this.config.autoPlay);
      await this.avPlayInstance.setLoop(false);
      
      // 根据设备能力设置最佳解码模式 | Set optimal decoding mode based on device capability
      await this.setupOptimalDecodingMode();
      
      // 设置缓冲大小 | Set buffer size
      await this.avPlayInstance.setParameter('cacheSize', this.adaptiveBufferSize.toString());
      
      // 启用预缓冲 | Enable pre-buffering
      await this.enablePreBuffering();
      
      // 设置音量和静音 | Set volume and mute
      await this.avPlayInstance.setVolume(this.isMuted ? 0 : this.volume);
      await this.avPlayInstance.setMute(this.isMuted);
      
      // 设置播放速度 | Set playback speed
      await this.avPlayInstance.setSpeed(this.playbackSpeed);
      
      // 注册事件监听 | Register event listeners
      this.setupEventListeners();
      
      Logger.info(TAG, 'AVPlay instance created successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to create AVPlay instance: ${error}`);
      throw error;
    }
  }
  
  /**
   * 根据设备能力设置最佳解码模式 | Sets optimal decoding mode based on device capability
   */
  private async setupOptimalDecodingMode(): Promise<void> {
    if (!this.avPlayInstance) return;
    
    try {
      // 检查配置是否支持硬件解码 Check if config supports hardware decoding
      if (this.config.enableHardwareDecoding) {
        try {
          // 获取设备能力 Get device capabilities
          const capabilities = await this.deviceInfoRepository.getDeviceCapabilities();
          
          // 根据设备能力选择最佳解码模式 Select optimal decoding mode based on device capabilities
          if (capabilities && capabilities.gpu && capabilities.gpu.supportsHardwareDecoding) {
            // 尝试硬件解码 Try hardware decoding
            await this.avPlayInstance.setParameter('videoDecodingMode', 'hardware');
            Logger.info(TAG, 'Hardware decoding enabled based on device capability');
            
            // 启用硬件加速相关参数 Enable hardware acceleration related parameters
            await this.enableHardwareAccelerationFeatures();
          } else {
            // 设备不支持硬件解码，使用软件解码 Device doesn't support hardware decoding, use software decoding
            Logger.warn(TAG, 'Device does not support hardware decoding, using software decoding');
            await this.avPlayInstance.setParameter('videoDecodingMode', 'software');
            this.config.enableHardwareDecoding = false;
          }
        } catch (error) {
          // 硬件解码失败，回退到软件解码 Hardware decoding failed, fallback to software decoding
          Logger.warn(TAG, 'Hardware decoding not supported, falling back to software decoding', error);
          await this.avPlayInstance.setParameter('videoDecodingMode', 'software');
          // 更新配置，避免下次再尝试失败的解码模式 Update config to avoid trying failed decoding mode next time
          this.config.enableHardwareDecoding = false;
        }
      } else {
        // 直接使用软件解码 Use software decoding directly
        await this.avPlayInstance.setParameter('videoDecodingMode', 'software');
        Logger.info(TAG, 'Software decoding enabled');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to setup decoding mode: ${error}`);
      // 确保至少设置为软件解码 Ensure at least software decoding is set
      try {
        await this.avPlayInstance.setParameter('videoDecodingMode', 'software');
      } catch (fallbackError) {
        Logger.error(TAG, `Failed to fallback to software decoding: ${fallbackError}`);
      }
    }
  }

  /**
   * 启用硬件加速特性 | Enables hardware acceleration features
   */
  private async enableHardwareAccelerationFeatures(): Promise<void> {
    if (!this.avPlayInstance) return;
    
    try {
      // 启用硬件解码相关参数 Enable hardware decoding related parameters
      await this.avPlayInstance.setParameter('hardwareDecodingEnabled', 'true');
      await this.avPlayInstance.setParameter('hardwareDecodingMode', 'auto');
      
      // 启用GPU渲染 Enable GPU rendering
      await this.avPlayInstance.setParameter('useGpuRendering', 'true');
      
      // 启用硬件缩放 Enable hardware scaling
      await this.avPlayInstance.setParameter('useHardwareScaling', 'true');
      
      // 启用硬件色彩处理 Enable hardware color processing
      await this.avPlayInstance.setParameter('useHardwareColorProcessing', 'true');
      
      Logger.info(TAG, 'Hardware acceleration features enabled');
    } catch (error) {
      Logger.warn(TAG, 'Failed to enable hardware acceleration features', error);
      // 硬件加速特性启用失败，继续使用基本硬件解码
    }
  }

  /**
   * 设置事件监听器 Sets event listeners
   */
  private setupEventListeners(): void {
    if (!this.avPlayInstance) {
      return;
    }

    // 状态变化事件 State change event
    this.avPlayInstance.on('stateChange', (state: number, reason: number) => {
      this.handleStateChange(state, reason);
    });

    // 错误事件 Error event
    this.avPlayInstance.on('error', async (error: BusinessError) => {
      await this.handlePlaybackError(error);
    });

    // 缓冲进度事件 Buffering progress event
    this.avPlayInstance.on('bufferingChange', (bufferingStatus: number, startBufferBytes: number, bufferingBytes: number, totalBytes: number) => {
      this.handleBufferingChange(bufferingStatus, startBufferBytes, bufferingBytes, totalBytes);
    });

    // 播放完成事件 Playback complete event
    this.avPlayInstance.on('playbackComplete', () => {
      this.handlePlaybackComplete();
    });
  }

  /**
   * 处理状态变化 Handles state change
   */
  private handleStateChange(state: number, reason: number): void {
    let newState: PlaybackState = PlaybackState.IDLE;
    
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
        newState = PlaybackState.ERROR;
        break;
    }
    
    this.updatePlaybackState(newState);
    Logger.info(TAG, `Playback state changed to: ${newState}, reason: ${reason}`);
  }

  /**
   * 处理播放错误 Handles playback error
   */
  private async handlePlaybackError(error: BusinessError): Promise<void> {
    // 更新错误处理器的依赖项
    this.errorHandler.setDependencies(
      this.avPlayInstance,
      this.currentPlaybackItem,
      this.lastPosition,
      this.config.autoPlay,
      this.config.enableHardwareDecoding,
      this.errorListeners,
      (state) => this.updatePlaybackState(state),
      () => this.createAVPlayInstance(),
      () => this.savePlaybackPosition()
    );
    
    // 使用错误处理器处理错误
    await this.errorHandler.handlePlaybackError(error);
    
    // 同步重试计数
    this.retryCount = this.errorHandler.getRetryCount();
  }

  /**
   * 重新创建播放实例并设置数据源 Recreates playback instance and sets data source
   */
  private async recreatePlaybackInstance(url: string): Promise<boolean> {
    // 重新创建播放实例 Recreate playback instance
    await this.createAVPlayInstance();
    if (!this.avPlayInstance) return false;
    
    // 重新设置数据源 Reset data source
    await this.avPlayInstance.setSource(url);
    await this.avPlayInstance.prepare();
    
    return true;
  }

  /**
   * 恢复播放状态和位置 Resumes playback state and position
   */
  private async resumePlaybackState(): Promise<void> {
    if (!this.avPlayInstance) return;
    
    // 恢复到上次播放位置 Resume to last playback position
    if (this.lastPosition > 0) {
      await this.avPlayInstance.seekTo(this.lastPosition);
    }
    
    // 恢复播放 Resume playback
    if (this.config.autoPlay) {
      await this.avPlayInstance.play();
      this.updatePlaybackState(PlaybackState.PLAYING);
    }
  }
  
  /**
   * 优化播放质量
   * 
   * 根据设备能力和网络状况优化播放质量，调整播放参数。
   * 
   * @example
   * ```typescript
   * await playbackService.optimizePlaybackQuality();
   * console.log('Playback quality optimized');
   * ```
   */
  public async optimizePlaybackQuality(): Promise<void> {
    try {
      // 获取设备能力 Get device capabilities
      const capabilities = await this.deviceInfoRepository.getDeviceCapabilities();
      
      if (!capabilities || !this.avPlayInstance) return;
      
      // 根据设备能力调整播放参数 Adjust playback parameters based on device capabilities
      Logger.info(TAG, 'Optimizing playback quality based on device capabilities');
      
      // 可以在这里添加更多的质量优化逻辑
      // 例如根据网络状况调整缓冲大小
      // 根据设备性能调整解码参数等
      // More quality optimization logic can be added here
      // Like adjusting buffer size based on network condition
      // Adjusting decoding parameters based on device performance, etc.
    } catch (error) {
      Logger.error(TAG, `Failed to optimize playback quality: ${error}`);
    }
  }
  
  /**
   * 保存播放位置 Saves playback position
   */
  private async savePlaybackPosition(): Promise<void> {
    try {
      if (!this.currentPlaybackItem || !this.avPlayInstance) return;
      
      // 获取当前播放位置 Get current playback position
      const position = await this.avPlayInstance.getCurrentTime();
      this.lastPosition = position;
      
      // 更新当前播放项的位置 Update current playback item position
      this.currentPlaybackItem.position = position;
      
      // 保存到历史记录 Save to history
      if (this.historyManager) {
        await this.historyManager.savePlaybackHistory({
          id: this.currentPlaybackItem.id, 
          title: this.currentPlaybackItem.title,
          url: this.currentPlaybackItem.url,
          duration: this.currentPlaybackItem.duration,
          position: position,
          lastPlayed: new Date().getTime()
        });
        Logger.info(TAG, `Saved playback position for ${this.currentPlaybackItem.id}: ${position}ms`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save playback position: ${error}`);
    }
  }

  /**
   * 处理缓冲变化 Handles buffering change
   */
  private handleBufferingChange(bufferingStatus: number, startBufferBytes: number, bufferingBytes: number, totalBytes: number): void {
    // 实现缓冲变化处理逻辑 Implement buffering change handling logic
    Logger.info(TAG, `Buffering changed: status=${bufferingStatus}, start=${startBufferBytes}, buffering=${bufferingBytes}, total=${totalBytes}`);
    
    // 计算缓冲百分比 Calculate buffering percentage
    const percent: number = totalBytes > 0 ? Math.round((bufferingBytes / totalBytes) * 100) : 0;
    
    // 构建缓冲信息 Build buffering info
    const bufferingInfo: BufferingInfo = {
      percent: percent,
      currentRange: { start: startBufferBytes, end: startBufferBytes + bufferingBytes },
      loadedRanges: [{ start: startBufferBytes, end: startBufferBytes + bufferingBytes }],
      totalBytesLoaded: bufferingBytes,
      totalBytes: totalBytes
    };
    
    // 通知缓冲监听器 Notify buffering listeners
    this.bufferingListeners.forEach((listener: BufferingStateListener) => listener(bufferingInfo));
    
    // 更新播放状态 Update playback state
    if (bufferingStatus === 1) {
      this.updatePlaybackState(PlaybackState.BUFFERING);
    } else if (bufferingStatus === 0 && this.currentState === PlaybackState.BUFFERING) {
      this.updatePlaybackState(PlaybackState.PLAYING);
    }
  }

  /**
   * 处理播放完成 Handles playback complete
   */
  private handlePlaybackComplete(): void {
    // 实现播放完成处理逻辑 Implement playback complete handling logic
    Logger.info(TAG, 'Playback completed');
    
    // 更新播放状态 Update playback state
    this.updatePlaybackState(PlaybackState.COMPLETED);
    
    // 保存播放历史 Save playback history
    this.savePlaybackPosition().catch((error: string) => {
      Logger.error(TAG, `Failed to save playback history on complete: ${error}`);
    });
    
    // 检查是否有下一个播放项 Check if there's a next item in queue
    if (this.currentQueueIndex < this.playbackQueue.length - 1) {
      // 自动播放下一个 Auto play next
      this.playNext().catch((error: string) => {
        Logger.error(TAG, `Failed to play next item: ${error}`);
      });
    }
  }

  /**
   * 更新播放状态 Updates playback state
   */
  private updatePlaybackState(state: PlaybackState): void {
    // 实现播放状态更新逻辑 Implement playback state update logic
    if (this.currentState !== state) {
      const oldState: PlaybackState = this.currentState;
      this.currentState = state;
      
      // 通知状态监听器 Notify state listeners
      this.stateListeners.forEach((listener: PlaybackStateListener) => listener(state));
      
      Logger.info(TAG, `Playback state changed from ${oldState} to ${state}`);
    }
  }

  /**
   * 通知错误监听器 Notifies error listeners
   */
  private notifyErrorListeners(error: PlaybackError): void {
    // 实现错误通知逻辑 Implement error notification logic
    this.errorListeners.forEach((listener: PlaybackErrorListener) => listener(error));
  }

  /**
   * 释放AVPlay实例 Releases AVPlay instance
   */
  private async releaseAVPlayInstance(): Promise<void> {
    // 实现释放逻辑 Implement release logic
    if (this.avPlayInstance) {
      try {
        // 移除所有事件监听器 Remove all event listeners to prevent memory leaks
        try {
          this.avPlayInstance.off('stateChange');
          this.avPlayInstance.off('error');
          this.avPlayInstance.off('bufferingChange');
          this.avPlayInstance.off('playbackComplete');
        } catch (error) {
          Logger.warn(TAG, `Failed to remove event listeners: ${error}`);
        }
        
        await this.avPlayInstance.release();
        this.avPlayInstance = null;
        Logger.info(TAG, 'AVPlay instance released successfully');
      } catch (error) {
        Logger.error(TAG, `Failed to release AVPlay instance: ${error}`);
        this.avPlayInstance = null;
      }
    }
  }

  /**
   * 开始位置更新 Starts position updates
   */
  private startPositionUpdates(): void {
    // 实现位置更新逻辑 Implement position update logic
    if (this.positionUpdateTimerId) {
      clearInterval(this.positionUpdateTimerId);
    }
    
    // 每1秒更新一次位置 Update position every 1 second
    this.positionUpdateTimerId = setInterval(async () => {
      if (this.avPlayInstance && this.currentState === PlaybackState.PLAYING) {
        try {
          const currentTime: number = await this.avPlayInstance.getCurrentTime();
          const duration: number = await this.avPlayInstance.getDuration();
          const percent: number = duration > 0 ? Math.round((currentTime / duration) * 100) : 0;
          
          // 自动跳过片头 | Auto skip intro
          if (this.config.introDuration > 0 && !this.hasSkippedIntro) {
            if (currentTime >= this.config.introDuration * 1000) {
              await this.avPlayInstance.seekTo(this.config.introDuration * 1000);
              this.hasSkippedIntro = true;
              Logger.info(TAG, `Auto skipped intro at ${this.config.introDuration} seconds`);
            }
          }
          
          // 自动跳过片尾 | Auto skip outro
          if (this.config.outroDuration > 0 && !this.hasSkippedOutro && duration > 0) {
            const outroStart = (duration / 1000) - this.config.outroDuration;
            if (currentTime >= outroStart * 1000) {
              await this.avPlayInstance.seekTo(duration);
              this.hasSkippedOutro = true;
              Logger.info(TAG, `Auto skipped outro at ${outroStart} seconds`);
            }
          }
          
          // 更新最后位置 Update last position
          this.lastPosition = currentTime;
          this.lastPositionUpdateTime = Date.now();
          
          // 通知进度监听器 Notify progress listeners
          this.progressListeners.forEach((listener: PlaybackProgressListener) => listener(currentTime, duration, percent));
          
          // 每30秒保存一次播放位置 Save position every 30 seconds
          if (Date.now() - this.lastPositionUpdateTime > 30000) {
            this.savePlaybackPosition().catch((error: string) => {
              Logger.error(TAG, `Failed to save playback position: ${error}`);
            });
          }
        } catch (error) {
          Logger.error(TAG, `Failed to get playback position: ${error}`);
        }
      }
    }, 1000);
  }

  /**
   * 停止位置更新 Stops position updates
   */
  private stopPositionUpdates(): void {
    // 实现停止位置更新逻辑 Implement stop position update logic
    if (this.positionUpdateTimerId) {
      clearInterval(this.positionUpdateTimerId);
      this.positionUpdateTimerId = null;
    }
    
    // 保存当前位置 Save current position
    this.savePlaybackPosition().catch((error: string) => {
      Logger.error(TAG, `Failed to save playback position on stop: ${error}`);
    });
  }

  /**
   * 加载播放项 Loads playback item
   */
  private async load(item: PlaybackItem, position: number): Promise<void> {
    // 实现加载播放项逻辑 Implement load playback item logic
    try {
      Logger.info(TAG, `Loading playback item: ${item.title}, position: ${position}`);
      
      // 重置跳过标志 Reset skip flags
      this.hasSkippedIntro = false;
      this.hasSkippedOutro = false;
      
      // 更新当前播放项 Update current playback item
      this.currentPlaybackItem = item;
      
      // 创建AVPlay实例 Create AVPlay instance
      await this.createAVPlayInstance();
      if (!this.avPlayInstance) {
        throw new Error('Failed to create AVPlay instance');
      }
      
      // 设置数据源 Set data source
      await this.avPlayInstance.setSource(item.url);
      await this.avPlayInstance.prepare();
      
      // 设置初始位置 Set initial position
      if (position > 0) {
        await this.avPlayInstance.seekTo(position);
        this.lastPosition = position;
      }
      
      // 更新播放状态 Update playback state
      this.updatePlaybackState(PlaybackState.READY);
      
      // 自动播放 Auto play if enabled
      if (this.config.autoPlay) {
        await this.avPlayInstance.play();
        this.updatePlaybackState(PlaybackState.PLAYING);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load playback item: ${error}`);
      this.updatePlaybackState(PlaybackState.ERROR);
      throw error;
    }
  }

  /**
   * 设置音频路由 Sets audio route
   */
  private async setAudioRoute(route: AudioRoute): Promise<void> {
    // 实现设置音频路由逻辑 Implement set audio route logic
    try {
      Logger.info(TAG, `Setting audio route to: ${route}`);
      
      // 更新配置 Update config
      this.config.audioRoute = route;
      
      // 使用音频管理器设置路由 Set route using audio manager
      if (this.audioManager) {
        // 根据路由类型设置音频设备 Set audio device based on route type
        switch (route) {
          case AudioRoute.SPEAKER:
            // 设置为扬声器 Set to speaker
            await this.audioManager.setAudioScene(AudioManager.AudioSceneType.MEDIA);
            break;
          case AudioRoute.EARPIECE:
            // 设置为听筒 Set to earpiece
            await this.audioManager.setAudioScene(AudioManager.AudioSceneType.VOICE_COMMUNICATION);
            break;
          case AudioRoute.WIRED_HEADSET:
          case AudioRoute.BLUETOOTH:
            // 音频管理器会自动检测并使用外部设备 Audio manager will automatically detect and use external devices
            await this.audioManager.setAudioScene(AudioManager.AudioSceneType.MEDIA);
            break;
        }
      }
      
      Logger.info(TAG, `Audio route set to: ${route}`);
    } catch (error) {
      Logger.error(TAG, `Failed to set audio route: ${error}`);
    }
  }
  
  /**
   * 播放下一个播放项 Plays next item in queue
   */
  private async playNext(): Promise<void> {
    if (this.currentQueueIndex < this.playbackQueue.length - 1) {
      this.currentQueueIndex++;
      const nextItem: PlaybackItem = this.playbackQueue[this.currentQueueIndex];
      await this.load(nextItem, 0);
      
      // 通知队列监听器 Notify queue listeners
      for (let i = 0; i < this.queueListeners.length; i++) {
        const listener: PlaybackQueueListener = this.queueListeners[i];
        listener(this.playbackQueue, this.currentQueueIndex);
      }
    }
  }
  
  /**
   * 开始网络质量监控 | Starts network quality monitoring
   */
  private startNetworkQualityMonitoring(): void {
    // 清理之前的定时器 | Clear previous timer
    if (this.networkCheckTimerId) {
      clearInterval(this.networkCheckTimerId);
    }
    
    // 每 5 秒检查一次网络质量 | Check network quality every 5 seconds
    this.networkCheckTimerId = setInterval(async () => {
      await this.checkNetworkQuality();
      this.adjustBufferSizeBasedOnNetwork();
    }, NETWORK_CHECK_INTERVAL);
    
    Logger.info(TAG, 'Network quality monitoring started');
  }
  
  /**
   * 检查网络质量 | Checks network quality
   */
  private async checkNetworkQuality(): Promise<void> {
    try {
      // 实际的网络质量检测实现 | Actual network quality detection implementation
      // 可以通过以下方式实现 | Can be implemented through the following methods:
      // 1. 测量网络延迟 | 1. Measure network latency
      // 2. 测试下载速度 | 2. Test download speed
      // 3. 监控丢包率 | 3. Monitor packet loss rate
      // 4. 检测带宽 | 4. Detect bandwidth
      
      // 测量网络延迟 | Measure network latency
      const latency: number = await this.measureNetworkLatency();
      
      // 根据延迟判断网络质量 | Determine network quality based on latency
      if (latency < 50) {
        this.currentNetworkQuality = 'excellent';
      } else if (latency < 100) {
        this.currentNetworkQuality = 'good';
      } else if (latency < 200) {
        this.currentNetworkQuality = 'fair';
      } else {
        this.currentNetworkQuality = 'poor';
      }
      
      Logger.info(TAG, `Network quality: ${this.currentNetworkQuality}, Latency: ${latency}ms`);
      
    } catch (error) {
      Logger.error(TAG, `Failed to check network quality: ${error}`);
      // 网络检测失败时使用保守设置 | Use conservative settings when network detection fails
      this.currentNetworkQuality = 'fair';
    }
  }
  
  /**
   * 测量网络延迟 | Measure network latency
   */
  private async measureNetworkLatency(): Promise<number> {
    try {
      const httpService = HttpService.getInstance();
      
      // 选择几个可靠的服务器进行测试
      const testEndpoints: string[] = [
        'https://www.google.com/generate_204', // Google的204响应
        'https://www.cloudflare.com/cdn-cgi/trace', // Cloudflare的trace端点
        'https://www.baidu.com/favicon.ico' // 百度的favicon
      ];
      
      // 随机选择一个端点进行测试
      const endpoint: string = testEndpoints[Math.floor(Math.random() * testEndpoints.length)];
      
      // 测量开始时间
      const startTime: number = Date.now();
      
      // 发送HEAD请求（比GET更轻量）
      await httpService.get(endpoint, {
        timeout: 5000, // 5秒超时
        headers: {
          'User-Agent': 'RayTV/1.0'
        }
      });
      
      // 计算往返时间
      const endTime: number = Date.now();
      const latency: number = endTime - startTime;
      
      Logger.info(TAG, `Network latency to ${endpoint}: ${latency}ms`);
      return Math.round(latency);
    } catch (error) {
      Logger.warn(TAG, `Failed to measure network latency: ${error instanceof Error ? error.message : String(error)}`);
      return 100; // 返回默认延迟值 | Return default latency value
    }
  }
  

  
  /**
   * 根据网络质量获取视频质量 | Gets video quality based on network quality
   */
  private getVideoQualityForNetwork(networkQuality: 'excellent' | 'good' | 'fair' | 'poor'): VideoQuality {
    if (!this.config.enableAdaptiveQuality) {
      return this.config.defaultVideoQuality;
    }
    
    switch (networkQuality) {
      case 'excellent':
        return this.config.qualitySwitchThresholds.excellent;
      case 'good':
        return this.config.qualitySwitchThresholds.good;
      case 'fair':
        return this.config.qualitySwitchThresholds.fair;
      case 'poor':
        return this.config.qualitySwitchThresholds.poor;
      default:
        return this.config.defaultVideoQuality;
    }
  }

  /**
   * 应用视频质量设置 | Applies video quality setting
   */
  private async applyVideoQuality(quality: VideoQuality): Promise<void> {
    if (!this.avPlayInstance) return;
    
    try {
      // 根据视频质量设置不同的参数
      switch (quality) {
        case VideoQuality.HIGH:
          // 高质量：较高的码率和分辨率
          await this.avPlayInstance.setParameter('videoBitrate', 'high');
          await this.avPlayInstance.setParameter('videoResolution', 'high');
          break;
        case VideoQuality.MEDIUM:
          // 中质量：中等的码率和分辨率
          await this.avPlayInstance.setParameter('videoBitrate', 'medium');
          await this.avPlayInstance.setParameter('videoResolution', 'medium');
          break;
        case VideoQuality.LOW:
          // 低质量：较低的码率和分辨率
          await this.avPlayInstance.setParameter('videoBitrate', 'low');
          await this.avPlayInstance.setParameter('videoResolution', 'low');
          break;
      }
      
      this.currentVideoQuality = quality;
      Logger.info(TAG, `Applied video quality: ${quality}`);
    } catch (error) {
      Logger.error(TAG, `Failed to apply video quality: ${error}`);
    }
  }

  /**
   * 根据网络质量调整缓冲大小和视频质量 | Adjusts buffer size and video quality based on network quality
   */
  private async adjustBufferSizeBasedOnNetwork(): Promise<void> {
    let newBufferSize: number;
    
    switch (this.currentNetworkQuality) {
      case 'excellent':
        newBufferSize = MAX_BUFFER_SIZE; // 优秀网络使用最大缓冲
        break;
      case 'good':
        newBufferSize = PLAYBACK_BUFFER_SIZE; // 良好网络使用默认缓冲
        break;
      case 'fair':
        newBufferSize = Math.floor((PLAYBACK_BUFFER_SIZE + MIN_BUFFER_SIZE) / 2); // 一般网络使用中等缓冲
        break;
      case 'poor':
        newBufferSize = MIN_BUFFER_SIZE; // 较差网络使用最小缓冲
        break;
      default:
        newBufferSize = PLAYBACK_BUFFER_SIZE;
    }
    
    if (newBufferSize !== this.adaptiveBufferSize) {
      this.adaptiveBufferSize = newBufferSize;
      Logger.info(TAG, `Adjusted buffer size to ${newBufferSize / (1024 * 1024)}MB based on network quality: ${this.currentNetworkQuality}`);
      
      // 如果AVPlay实例已创建，更新缓冲大小 | Update buffer size if AVPlay instance exists
      if (this.avPlayInstance) {
        this.avPlayInstance.setParameter('cacheSize', newBufferSize.toString()).catch((error: string) => {
          Logger.error(TAG, `Failed to update buffer size: ${error}`);
        });
      }
    }
    
    // 调整视频质量 | Adjust video quality
    const newQuality = this.getVideoQualityForNetwork(this.currentNetworkQuality);
    if (newQuality !== this.currentVideoQuality) {
      await this.applyVideoQuality(newQuality);
    }
  }
  
  /**
   * 启用预缓冲 | Enables pre-buffering
   */
  private async enablePreBuffering(): Promise<void> {
    if (!this.avPlayInstance || !this.currentPlaybackItem) return;
    
    try {
      // 设置预缓冲时间 | Set pre-buffer duration
      await this.avPlayInstance.setParameter('preBufferDuration', PRE_BUFFER_DURATION.toString());
      Logger.info(TAG, `Pre-buffering enabled with duration: ${PRE_BUFFER_DURATION}s`);
    } catch (error) {
      Logger.error(TAG, `Failed to enable pre-buffering: ${error}`);
    }
  }
  
  /**
   * 清理资源和监听器
   * 
   * 清理播放服务的资源和监听器，防止内存泄漏。
   * 
   * @example
   * ```typescript
   * await playbackService.cleanup();
   * console.log('Playback service resources cleaned up');
   * ```
   */
  public async cleanup(): Promise<void> {
    try {
      Logger.info(TAG, 'Cleaning up playback service resources...');
      
      // 停止位置更新 Stop position updates
      this.stopPositionUpdates();
      
      // 停止网络质量监控 | Stop network quality monitoring
      if (this.networkCheckTimerId) {
        clearInterval(this.networkCheckTimerId);
        this.networkCheckTimerId = null;
      }
      
      // 释放AVPlay实例 Release AVPlay instance
      await this.releaseAVPlayInstance();
      
      // 清理监听器列表 Clear listener lists
      this.stateListeners = [];
      this.errorListeners = [];
      this.progressListeners = [];
      this.bufferingListeners = [];
      this.queueListeners = [];
      this.pipStateListeners = [];
      
      // 清理播放队列 Clear playback queue
      this.playbackQueue = [];
      this.currentQueueIndex = -1;
      
      // 清理当前播放项 Clear current playback item
      this.currentPlaybackItem = null;
      
      // 重置状态 Reset state
      this.currentState = PlaybackState.IDLE;
      this.retryCount = 0;
      this.errorHandler.resetRetryCount();
      this.lastRetryTime = 0;
      this.lastPosition = 0;
      this.lastPositionUpdateTime = 0;
      this.currentNetworkQuality = 'good';
      this.adaptiveBufferSize = PLAYBACK_BUFFER_SIZE;
      this.isPictureInPicture = false;
      this.currentPipPosition = { ...DEFAULT_PLAYBACK_CONFIG.pipPosition };
      
      // 重置初始化状态 Reset initialized state
      this.isInitialized = false;
      
      Logger.info(TAG, 'Playback service resources cleaned up successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to cleanup playback service: ${error}`);
    }
  }
  
  /**
   * 进入画中画模式
   * 
   * 进入画中画模式，将视频缩小为小窗口播放，允许用户在浏览其他内容的同时继续观看视频。
   * 
   * @param position - 可选的画中画位置和大小
   * @returns Promise<boolean> - 是否成功进入画中画模式
   * 
   * @example
   * ```typescript
   * const success = await playbackService.enterPictureInPicture();
   * if (success) {
   *   console.log('Entered picture-in-picture mode');
   * }
   * ```
   */
  public async enterPictureInPicture(position?: { x: number; y: number; width: number; height: number }): Promise<boolean> {
    try {
      if (!this.avPlayInstance || !this.config.enablePictureInPicture) {
        Logger.warn(TAG, 'Picture-in-picture not enabled or AVPlay instance not available');
        return false;
      }
      
      // 设置画中画位置和大小
      if (position) {
        this.currentPipPosition = position;
      } else {
        this.currentPipPosition = { ...this.config.pipPosition };
      }
      
      // 启用画中画模式
      await this.avPlayInstance.setParameter('pictureInPictureEnabled', 'true');
      await this.avPlayInstance.setParameter('pictureInPicturePosition', JSON.stringify(this.currentPipPosition));
      
      this.isPictureInPicture = true;
      Logger.info(TAG, 'Entered picture-in-picture mode', this.currentPipPosition);
      
      // 通知监听器
      this.notifyPipStateListeners(true, this.currentPipPosition);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to enter picture-in-picture mode: ${error}`);
      return false;
    }
  }

  /**
   * 退出画中画模式
   * 
   * 退出画中画模式，将视频恢复为全屏播放。
   * 
   * @returns Promise<boolean> - 是否成功退出画中画模式
   * 
   * @example
   * ```typescript
   * const success = await playbackService.exitPictureInPicture();
   * if (success) {
   *   console.log('Exited picture-in-picture mode');
   * }
   * ```
   */
  public async exitPictureInPicture(): Promise<boolean> {
    try {
      if (!this.avPlayInstance || !this.isPictureInPicture) {
        Logger.warn(TAG, 'Not in picture-in-picture mode or AVPlay instance not available');
        return false;
      }
      
      // 禁用画中画模式
      await this.avPlayInstance.setParameter('pictureInPictureEnabled', 'false');
      
      this.isPictureInPicture = false;
      Logger.info(TAG, 'Exited picture-in-picture mode');
      
      // 通知监听器
      this.notifyPipStateListeners(false);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to exit picture-in-picture mode: ${error}`);
      return false;
    }
  }

  /**
   * 移动画中画窗口
   * 
   * 移动画中画窗口到指定位置。
   * 
   * @param x - 新的X坐标
   * @param y - 新的Y坐标
   * @returns Promise<boolean> - 是否成功移动
   * 
   * @example
   * ```typescript
   * const success = await playbackService.movePictureInPicture(100, 100);
   * if (success) {
   *   console.log('Moved picture-in-picture window');
   * }
   * ```
   */
  public async movePictureInPicture(x: number, y: number): Promise<boolean> {
    try {
      if (!this.avPlayInstance || !this.isPictureInPicture) {
        Logger.warn(TAG, 'Not in picture-in-picture mode or AVPlay instance not available');
        return false;
      }
      
      // 更新位置
      this.currentPipPosition.x = x;
      this.currentPipPosition.y = y;
      
      // 应用新位置
      await this.avPlayInstance.setParameter('pictureInPicturePosition', JSON.stringify(this.currentPipPosition));
      
      Logger.info(TAG, 'Moved picture-in-picture window to', { x, y });
      
      // 通知监听器
      this.notifyPipStateListeners(true, this.currentPipPosition);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to move picture-in-picture window: ${error}`);
      return false;
    }
  }

  /**
   * 设置片头时长
   * 
   * 设置片头时长，并自动开启跳过片头功能。
   * 
   * @param seconds - 片头时长（秒）
   * @returns Promise<void>
   * 
   * @example
   * ```typescript
   * await playbackService.setIntroDuration(90); // 设置片头时长为90秒
   * console.log('Intro duration set to 90 seconds');
   * ```
   */
  public async setIntroDuration(seconds: number): Promise<void> {
    try {
      this.config.introDuration = seconds;
      // 如果设置了片头时长，自动开启跳过片头功能
      if (seconds > 0) {
        this.config.enableAutoSkipIntro = true;
      } else {
        this.config.enableAutoSkipIntro = false;
      }
      await this.configService.setConfig('playbackConfig', this.config);
      Logger.info(TAG, `Set intro duration to ${seconds} seconds`);
    } catch (error) {
      Logger.error(TAG, `Failed to set intro duration: ${error}`);
      throw error;
    }
  }

  /**
   * 设置片尾时长
   * 
   * 设置片尾时长，并自动开启跳过片尾功能。
   * 
   * @param seconds - 片尾时长（秒）
   * @returns Promise<void>
   * 
   * @example
   * ```typescript
   * await playbackService.setOutroDuration(120); // 设置片尾时长为120秒
   * console.log('Outro duration set to 120 seconds');
   * ```
   */
  public async setOutroDuration(seconds: number): Promise<void> {
    try {
      this.config.outroDuration = seconds;
      // 如果设置了片尾时长，自动开启跳过片尾功能
      if (seconds > 0) {
        this.config.enableAutoSkipOutro = true;
      } else {
        this.config.enableAutoSkipOutro = false;
      }
      await this.configService.setConfig('playbackConfig', this.config);
      Logger.info(TAG, `Set outro duration to ${seconds} seconds`);
    } catch (error) {
      Logger.error(TAG, `Failed to set outro duration: ${error}`);
      throw error;
    }
  }

  /**
   * 调整画中画窗口大小
   * 
   * 调整画中画窗口的大小。
   * 
   * @param width - 新的宽度
   * @param height - 新的高度
   * @returns Promise<boolean> - 是否成功调整大小
   * 
   * @example
   * ```typescript
   * const success = await playbackService.resizePictureInPicture(400, 225);
   * if (success) {
   *   console.log('Resized picture-in-picture window');
   * }
   * ```
   */
  public async resizePictureInPicture(width: number, height: number): Promise<boolean> {
    try {
      if (!this.avPlayInstance || !this.isPictureInPicture) {
        Logger.warn(TAG, 'Not in picture-in-picture mode or AVPlay instance not available');
        return false;
      }
      
      // 更新大小
      this.currentPipPosition.width = width;
      this.currentPipPosition.height = height;
      
      // 应用新大小
      await this.avPlayInstance.setParameter('pictureInPicturePosition', JSON.stringify(this.currentPipPosition));
      
      Logger.info(TAG, 'Resized picture-in-picture window to', { width, height });
      
      // 通知监听器
      this.notifyPipStateListeners(true, this.currentPipPosition);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to resize picture-in-picture window: ${error}`);
      return false;
    }
  }

  /**
   * 获取画中画状态
   * 
   * 获取当前是否处于画中画模式。
   * 
   * @returns boolean - 是否处于画中画模式
   * 
   * @example
   * ```typescript
   * const isPip = playbackService.isInPictureInPicture();
   * console.log('Is in picture-in-picture mode:', isPip);
   * ```
   */
  public isInPictureInPicture(): boolean {
    return this.isPictureInPicture;
  }

  /**
   * 获取画中画位置
   * 
   * 获取当前画中画窗口的位置和大小。
   * 
   * @returns { x: number; y: number; width: number; height: number } - 画中画位置和大小
   * 
   * @example
   * ```typescript
   * const position = playbackService.getPictureInPicturePosition();
   * console.log('Picture-in-picture position:', position);
   * ```
   */
  public getPictureInPicturePosition(): { x: number; y: number; width: number; height: number } {
    return { ...this.currentPipPosition };
  }

  /**
   * 注册画中画状态监听器
   * 
   * 注册一个监听器，当画中画状态发生变化时被调用。
   * 
   * @param listener - 画中画状态监听器
   * 
   * @example
   * ```typescript
   * playbackService.addPipStateListener((isPip, position) => {
   *   console.log('PIP state changed:', isPip, position);
   * });
   * ```
   */
  public addPipStateListener(listener: PipStateListener): void {
    this.pipStateListeners.push(listener);
  }

  /**
   * 移除画中画状态监听器
   * 
   * 移除之前注册的画中画状态监听器。
   * 
   * @param listener - 要移除的监听器
   * 
   * @example
   * ```typescript
   * const listener = (isPip, position) => {
   *   console.log('PIP state changed:', isPip, position);
   * };
   * playbackService.addPipStateListener(listener);
   * // 之后移除
   * playbackService.removePipStateListener(listener);
   * ```
   */
  public removePipStateListener(listener: PipStateListener): void {
    const index = this.pipStateListeners.indexOf(listener);
    if (index > -1) {
      this.pipStateListeners.splice(index, 1);
    }
  }

  /**
   * 通知画中画状态监听器
   * 
   * 通知所有注册的画中画状态监听器状态变化。
   */
  private notifyPipStateListeners(isPip: boolean, position?: { x: number; y: number; width: number; height: number }): void {
    this.pipStateListeners.forEach(listener => listener(isPip, position));
  }

  /**
   * 销毁播放服务
   * 
   * 销毁播放服务，释放所有资源。
   * 
   * @example
   * ```typescript
   * await playbackService.destroy();
   * console.log('Playback service destroyed');
   * ```
   */
  public async destroy(): Promise<void> {
    try {
      await this.cleanup();
      Logger.info(TAG, 'Playback service destroyed successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to destroy playback service: ${error}`);
    }
  }
}
