// PlaybackService - 播放服务类
// 负责管理视频播放相关的业务逻辑，包括播放控制、播放状态管理、音视频设置等

import { Logger } from '../utils/Logger';
import { EventBusUtil, GlobalEventType } from '../utils/EventBusUtil';
import { StorageUtil } from '../utils/StorageUtil';
import { ConfigRepository } from '../data/repository/ConfigRepository';
import { LocalStorageType } from '../data/model/LocalModel';
import { LiveStream, LiveStreamQuality } from './LiveStreamService';

/**
 * 播放状态枚举
 */
export enum PlaybackStatus {
  IDLE = 'IDLE',           // 空闲
  LOADING = 'LOADING',     // 加载中
  READY = 'READY',         // 准备就绪
  PLAYING = 'PLAYING',     // 播放中
  PAUSED = 'PAUSED',       // 暂停
  BUFFERING = 'BUFFERING', // 缓冲中
  SEEKING = 'SEEKING',     // 跳转中
  ENDED = 'ENDED',         // 播放结束
  ERROR = 'ERROR'          // 播放错误
}

/**
 * 播放模式枚举
 */
export enum PlaybackMode {
  NORMAL = 'NORMAL',       // 正常播放
  LOOP = 'LOOP',           // 循环播放
  RANDOM = 'RANDOM',       // 随机播放
  SEQUENTIAL = 'SEQUENTIAL' // 顺序播放
}

/**
 * 播放速度枚举
 */
export enum PlaybackSpeed {
  SLOWEST = 0.25,          // 最慢
  SLOW = 0.5,              // 慢
  NORMAL = 1.0,            // 正常
  FAST = 1.5,              // 快
  FASTER = 2.0,            // 更快
  FASTEST = 3.0            // 最快
}

/**
 * 音频轨道接口
 */
export interface AudioTrack {
  id: string;              // 轨道ID
  label: string;           // 轨道标签
  language: string;        // 语言代码
  codec: string;           // 音频编码
  bitrate?: number;        // 比特率（可选）
}

/**
 * 字幕轨道接口
 */
export interface SubtitleTrack {
  id: string;              // 轨道ID
  label: string;           // 轨道标签
  language: string;        // 语言代码
  src: string;             // 字幕文件URL
  type: 'vtt' | 'srt';     // 字幕类型
}

/**
 * 播放统计数据接口
 */
export interface PlaybackStatistics {
  totalPlaybackTime: number; // 总播放时长（毫秒）
  currentPlaybackTime: number; // 当前播放时长（毫秒）
  bufferedTime: number;    // 已缓冲时长（毫秒）
  seekCount: number;       // 跳转次数
  pauseCount: number;      // 暂停次数
  playbackErrors: number;  // 播放错误次数
  averageBitrate: number;  // 平均比特率
  resolution: string;      // 分辨率
  codecInfo: string;       // 编码信息
  droppedFrames: number;   // 丢帧数
  bufferUnderruns: number; // 缓冲区不足次数
}

/**
 * 播放配置接口
 */
export interface PlaybackConfig {
  autoPlay: boolean;       // 自动播放
  defaultQuality: LiveStreamQuality; // 默认画质
  volume: number;          // 音量（0-100）
  muted: boolean;          // 是否静音
  playbackSpeed: PlaybackSpeed; // 播放速度
  subtitlesEnabled: boolean; // 是否启用字幕
  selectedSubtitleId?: string; // 选中的字幕ID
  selectedAudioId?: string; // 选中的音频轨道ID
  rememberPosition: boolean; // 记住播放位置
  backgroundPlay: boolean; // 后台播放
  hardwareAcceleration: boolean; // 硬件加速
  maxBitrate?: number;     // 最大比特率（可选）
}

/**
 * 播放事件数据接口
 */
export interface PlaybackEventData {
  stream?: LiveStream;     // 直播流信息
  status: PlaybackStatus;  // 播放状态
  position?: number;       // 播放位置
  duration?: number;       // 总时长
  error?: Error;           // 错误信息（可选）
  quality?: LiveStreamQuality; // 画质（可选）
  volume?: number;         // 音量（可选）
}

/**
 * 播放服务类
 */
export class PlaybackService {
  private static instance: PlaybackService;
  private logger = Logger.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private configRepository = ConfigRepository.getInstance();
  
  // 播放状态
  private status: PlaybackStatus = PlaybackStatus.IDLE;
  // 当前播放的直播流
  private currentStream: LiveStream | null = null;
  // 播放配置
  private config: PlaybackConfig = {
    autoPlay: true,
    defaultQuality: LiveStreamQuality.HIGH,
    volume: 80,
    muted: false,
    playbackSpeed: PlaybackSpeed.NORMAL,
    subtitlesEnabled: true,
    rememberPosition: true,
    backgroundPlay: false,
    hardwareAcceleration: true
  };
  // 播放统计
  private statistics: PlaybackStatistics = {
    totalPlaybackTime: 0,
    currentPlaybackTime: 0,
    bufferedTime: 0,
    seekCount: 0,
    pauseCount: 0,
    playbackErrors: 0,
    averageBitrate: 0,
    resolution: '0x0',
    codecInfo: '',
    droppedFrames: 0,
    bufferUnderruns: 0
  };
  // 播放历史位置记录
  private playbackPositions: Map<string, number> = new Map();
  // 音频轨道列表
  private audioTracks: AudioTrack[] = [];
  // 字幕轨道列表
  private subtitleTracks: SubtitleTrack[] = [];
  // 播放模式
  private playbackMode: PlaybackMode = PlaybackMode.NORMAL;
  // 播放计时器
  private playbackTimer: number | null = null;
  // 上一次更新时间
  private lastUpdateTime: number = 0;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('PlaybackService initialized');
    this.initialize();
  }

  /**
   * 获取PlaybackService单例实例
   */
  public static getInstance(): PlaybackService {
    if (!PlaybackService.instance) {
      PlaybackService.instance = new PlaybackService();
    }
    return PlaybackService.instance;
  }

  /**
   * 初始化服务
   */
  private async initialize(): Promise<void> {
    try {
      // 加载播放配置
      await this.loadPlaybackConfig();
      // 加载播放位置历史
      await this.loadPlaybackPositions();
      // 初始化事件监听
      this.setupEventListeners();
      
      this.logger.info('PlaybackService initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize PlaybackService', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听网络状态变化
    this.eventBus.on(GlobalEventType.NETWORK_STATUS_CHANGE, (status) => {
      this.handleNetworkStatusChange(status);
    });
    
    // 监听配置变化
    this.eventBus.on(GlobalEventType.CONFIG_CHANGE, (config) => {
      if (config?.playback) {
        this.updateConfig(config.playback);
      }
    });
    
    // 监听应用暂停/恢复
    this.eventBus.on(GlobalEventType.APP_PAUSE, () => {
      this.handleAppPause();
    });
    
    this.eventBus.on(GlobalEventType.APP_RESUME, () => {
      this.handleAppResume();
    });
  }

  /**
   * 加载直播流进行播放
   * @param stream 直播流信息
   * @param position 起始播放位置（毫秒）
   */
  public async loadStream(stream: LiveStream, position: number = 0): Promise<void> {
    try {
      this.logger.debug(`Loading stream: ${stream.id}, position: ${position}`);
      
      // 更新状态为加载中
      this.updateStatus(PlaybackStatus.LOADING);
      
      // 保存当前流
      this.currentStream = stream;
      
      // 重置统计数据
      this.resetStatistics();
      
      // 清理之前的播放
      this.cleanupPlayback();
      
      // 模拟加载过程
      await this.simulateLoading();
      
      // 获取保存的播放位置（如果启用）
      if (this.config.rememberPosition && position === 0) {
        const savedPosition = this.playbackPositions.get(stream.id);
        if (savedPosition) {
          position = savedPosition;
          this.logger.debug(`Restoring saved position: ${position}ms for stream: ${stream.id}`);
        }
      }
      
      // 初始化播放组件
      await this.initializePlayer(stream, position);
      
      // 设置音量和静音状态
      this.setVolumeInternal(this.config.volume);
      this.setMutedInternal(this.config.muted);
      
      // 更新状态为准备就绪
      this.updateStatus(PlaybackStatus.READY);
      
      // 自动播放（如果启用）
      if (this.config.autoPlay) {
        await this.play();
      }
      
      this.logger.info(`Stream loaded successfully: ${stream.id}`);
    } catch (error) {
      this.logger.error(`Failed to load stream: ${stream.id}`, error as Error);
      this.updateStatus(PlaybackStatus.ERROR, { error: error as Error });
      throw error;
    }
  }

  /**
   * 开始播放
   */
  public async play(): Promise<void> {
    try {
      if (!this.currentStream) {
        throw new Error('No stream loaded');
      }
      
      this.logger.debug(`Starting playback for stream: ${this.currentStream.id}`);
      
      // 调用播放组件播放
      await this.playInternal();
      
      // 更新状态为播放中
      this.updateStatus(PlaybackStatus.PLAYING);
      
      // 开始计时
      this.startPlaybackTimer();
      
      // 发布播放事件
      this.eventBus.emit(GlobalEventType.PLAYER_PLAY, {
        stream: this.currentStream,
        position: this.statistics.currentPlaybackTime
      });
      
      this.logger.info(`Playback started for stream: ${this.currentStream.id}`);
    } catch (error) {
      this.logger.error('Failed to start playback', error as Error);
      this.updateStatus(PlaybackStatus.ERROR, { error: error as Error });
      throw error;
    }
  }

  /**
   * 暂停播放
   */
  public async pause(): Promise<void> {
    try {
      if (!this.currentStream) {
        return;
      }
      
      this.logger.debug(`Pausing playback for stream: ${this.currentStream.id}`);
      
      // 调用播放组件暂停
      await this.pauseInternal();
      
      // 更新状态为暂停
      this.updateStatus(PlaybackStatus.PAUSED);
      
      // 停止计时
      this.stopPlaybackTimer();
      
      // 增加暂停计数
      this.statistics.pauseCount++;
      
      // 保存播放位置
      await this.savePlaybackPosition();
      
      // 发布暂停事件
      this.eventBus.emit(GlobalEventType.PLAYER_PAUSE, {
        stream: this.currentStream,
        position: this.statistics.currentPlaybackTime
      });
      
      this.logger.info(`Playback paused for stream: ${this.currentStream.id}`);
    } catch (error) {
      this.logger.error('Failed to pause playback', error as Error);
    }
  }

  /**
   * 停止播放
   */
  public async stop(): Promise<void> {
    try {
      if (!this.currentStream) {
        return;
      }
      
      this.logger.debug(`Stopping playback for stream: ${this.currentStream.id}`);
      
      // 停止计时
      this.stopPlaybackTimer();
      
      // 保存播放位置
      await this.savePlaybackPosition();
      
      // 调用播放组件停止
      await this.stopInternal();
      
      // 更新状态为空闲
      this.updateStatus(PlaybackStatus.IDLE);
      
      // 发布停止事件
      this.eventBus.emit(GlobalEventType.PLAYER_STOP, {
        stream: this.currentStream,
        watchDuration: this.statistics.totalPlaybackTime
      });
      
      // 清理资源
      this.cleanupPlayback();
      
      this.logger.info(`Playback stopped for stream: ${this.currentStream.id}`);
    } catch (error) {
      this.logger.error('Failed to stop playback', error as Error);
    }
  }

  /**
   * 跳转到指定位置
   * @param position 目标位置（毫秒）
   */
  public async seekTo(position: number): Promise<void> {
    try {
      if (!this.currentStream) {
        throw new Error('No stream loaded');
      }
      
      this.logger.debug(`Seeking to position: ${position}ms for stream: ${this.currentStream.id}`);
      
      // 更新状态为跳转中
      this.updateStatus(PlaybackStatus.SEEKING);
      
      // 调用播放组件跳转
      await this.seekInternal(position);
      
      // 更新播放位置
      this.statistics.currentPlaybackTime = position;
      
      // 增加跳转计数
      this.statistics.seekCount++;
      
      // 如果是播放状态，恢复播放
      if (this.status === PlaybackStatus.SEEKING) {
        const previousStatus = this.getPreviousPlaybackStatus();
        if (previousStatus === PlaybackStatus.PLAYING) {
          this.updateStatus(PlaybackStatus.PLAYING);
        } else {
          this.updateStatus(PlaybackStatus.PAUSED);
        }
      }
      
      this.logger.info(`Seek completed to ${position}ms for stream: ${this.currentStream.id}`);
    } catch (error) {
      this.logger.error('Failed to seek', error as Error);
      this.updateStatus(this.getPreviousPlaybackStatus());
      throw error;
    }
  }

  /**
   * 设置音量
   * @param volume 音量值（0-100）
   */
  public setVolume(volume: number): void {
    try {
      // 确保音量在有效范围内
      const clampedVolume = Math.max(0, Math.min(100, volume));
      
      this.logger.debug(`Setting volume to: ${clampedVolume}`);
      
      // 更新配置
      this.config.volume = clampedVolume;
      
      // 如果音量不为0，取消静音
      if (clampedVolume > 0 && this.config.muted) {
        this.config.muted = false;
      }
      
      // 调用播放组件设置音量
      this.setVolumeInternal(clampedVolume);
      
      // 保存配置
      this.savePlaybackConfig();
      
      // 发布音量变化事件
      this.eventBus.emit('playback:volumeChange', { volume: clampedVolume });
      
      this.logger.info(`Volume set to: ${clampedVolume}`);
    } catch (error) {
      this.logger.error('Failed to set volume', error as Error);
    }
  }

  /**
   * 设置静音状态
   * @param muted 是否静音
   */
  public setMuted(muted: boolean): void {
    try {
      this.logger.debug(`Setting muted to: ${muted}`);
      
      // 更新配置
      this.config.muted = muted;
      
      // 调用播放组件设置静音
      this.setMutedInternal(muted);
      
      // 保存配置
      this.savePlaybackConfig();
      
      // 发布静音变化事件
      this.eventBus.emit('playback:mutedChange', { muted });
      
      this.logger.info(`Muted set to: ${muted}`);
    } catch (error) {
      this.logger.error('Failed to set muted', error as Error);
    }
  }

  /**
   * 设置播放速度
   * @param speed 播放速度
   */
  public setPlaybackSpeed(speed: PlaybackSpeed): void {
    try {
      this.logger.debug(`Setting playback speed to: ${speed}x`);
      
      // 更新配置
      this.config.playbackSpeed = speed;
      
      // 调用播放组件设置速度
      this.setPlaybackSpeedInternal(speed);
      
      // 保存配置
      this.savePlaybackConfig();
      
      // 发布播放速度变化事件
      this.eventBus.emit('playback:speedChange', { speed });
      
      this.logger.info(`Playback speed set to: ${speed}x`);
    } catch (error) {
      this.logger.error('Failed to set playback speed', error as Error);
    }
  }

  /**
   * 设置播放质量
   * @param quality 播放质量
   */
  public async setQuality(quality: LiveStreamQuality): Promise<void> {
    try {
      if (!this.currentStream) {
        throw new Error('No stream loaded');
      }
      
      this.logger.debug(`Setting playback quality to: ${quality} for stream: ${this.currentStream.id}`);
      
      // 更新状态为缓冲中
      this.updateStatus(PlaybackStatus.BUFFERING);
      
      // 调用播放组件设置质量
      await this.setQualityInternal(quality);
      
      // 更新当前流的质量
      this.currentStream.quality = quality;
      
      // 更新配置中的默认质量
      this.config.defaultQuality = quality;
      this.savePlaybackConfig();
      
      // 恢复之前的播放状态
      const previousStatus = this.getPreviousPlaybackStatus();
      this.updateStatus(previousStatus, { quality });
      
      // 发布质量变化事件
      this.eventBus.emit('playback:qualityChange', { quality });
      
      this.logger.info(`Playback quality set to: ${quality} for stream: ${this.currentStream.id}`);
    } catch (error) {
      this.logger.error('Failed to set quality', error as Error);
      this.updateStatus(this.getPreviousPlaybackStatus());
      throw error;
    }
  }

  /**
   * 设置字幕轨道
   * @param subtitleId 字幕轨道ID
   */
  public async setSubtitleTrack(subtitleId: string | null): Promise<void> {
    try {
      if (!this.currentStream) {
        throw new Error('No stream loaded');
      }
      
      this.logger.debug(`Setting subtitle track to: ${subtitleId || 'none'} for stream: ${this.currentStream.id}`);
      
      // 更新配置
      this.config.selectedSubtitleId = subtitleId || undefined;
      this.config.subtitlesEnabled = !!subtitleId;
      
      // 调用播放组件设置字幕轨道
      await this.setSubtitleTrackInternal(subtitleId);
      
      // 保存配置
      this.savePlaybackConfig();
      
      // 发布字幕变化事件
      this.eventBus.emit('playback:subtitleChange', { subtitleId });
      
      this.logger.info(`Subtitle track set to: ${subtitleId || 'none'}`);
    } catch (error) {
      this.logger.error('Failed to set subtitle track', error as Error);
      throw error;
    }
  }

  /**
   * 设置音频轨道
   * @param audioId 音频轨道ID
   */
  public async setAudioTrack(audioId: string): Promise<void> {
    try {
      if (!this.currentStream) {
        throw new Error('No stream loaded');
      }
      
      this.logger.debug(`Setting audio track to: ${audioId} for stream: ${this.currentStream.id}`);
      
      // 更新配置
      this.config.selectedAudioId = audioId;
      
      // 调用播放组件设置音频轨道
      await this.setAudioTrackInternal(audioId);
      
      // 保存配置
      this.savePlaybackConfig();
      
      // 发布音频轨道变化事件
      this.eventBus.emit('playback:audioChange', { audioId });
      
      this.logger.info(`Audio track set to: ${audioId}`);
    } catch (error) {
      this.logger.error('Failed to set audio track', error as Error);
      throw error;
    }
  }

  /**
   * 设置播放模式
   * @param mode 播放模式
   */
  public setPlaybackMode(mode: PlaybackMode): void {
    try {
      this.logger.debug(`Setting playback mode to: ${mode}`);
      
      // 更新播放模式
      this.playbackMode = mode;
      
      // 发布播放模式变化事件
      this.eventBus.emit('playback:modeChange', { mode });
      
      this.logger.info(`Playback mode set to: ${mode}`);
    } catch (error) {
      this.logger.error('Failed to set playback mode', error as Error);
    }
  }

  /**
   * 切换全屏状态
   * @param fullscreen 是否全屏
   */
  public async toggleFullscreen(fullscreen: boolean): Promise<void> {
    try {
      if (!this.currentStream) {
        return;
      }
      
      this.logger.debug(`Toggling fullscreen to: ${fullscreen} for stream: ${this.currentStream.id}`);
      
      // 调用播放组件切换全屏
      await this.toggleFullscreenInternal(fullscreen);
      
      // 发布全屏变化事件
      this.eventBus.emit(GlobalEventType.PLAYER_FULLSCREEN, { fullscreen });
      
      this.logger.info(`Fullscreen toggled to: ${fullscreen}`);
    } catch (error) {
      this.logger.error('Failed to toggle fullscreen', error as Error);
    }
  }

  /**
   * 获取当前播放状态
   */
  public getStatus(): PlaybackStatus {
    return this.status;
  }

  /**
   * 获取当前播放的直播流
   */
  public getCurrentStream(): LiveStream | null {
    return this.currentStream;
  }

  /**
   * 获取当前播放位置
   */
  public getCurrentPosition(): number {
    return this.statistics.currentPlaybackTime;
  }

  /**
   * 获取当前音量
   */
  public getVolume(): number {
    return this.config.volume;
  }

  /**
   * 获取静音状态
   */
  public isMuted(): boolean {
    return this.config.muted;
  }

  /**
   * 获取播放配置
   */
  public getConfig(): PlaybackConfig {
    return { ...this.config };
  }

  /**
   * 获取播放统计数据
   */
  public getStatistics(): PlaybackStatistics {
    return { ...this.statistics };
  }

  /**
   * 获取音频轨道列表
   */
  public getAudioTracks(): AudioTrack[] {
    return [...this.audioTracks];
  }

  /**
   * 获取字幕轨道列表
   */
  public getSubtitleTracks(): SubtitleTrack[] {
    return [...this.subtitleTracks];
  }

  /**
   * 获取播放模式
   */
  public getPlaybackMode(): PlaybackMode {
    return this.playbackMode;
  }

  /**
   * 更新播放配置
   * @param newConfig 新的配置
   */
  public async updateConfig(newConfig: Partial<PlaybackConfig>): Promise<void> {
    try {
      this.logger.debug('Updating playback config:', newConfig);
      
      // 合并配置
      this.config = { ...this.config, ...newConfig };
      
      // 应用配置变更
      this.applyConfigChanges();
      
      // 保存配置
      await this.savePlaybackConfig();
      
      this.logger.info('Playback config updated successfully');
    } catch (error) {
      this.logger.error('Failed to update playback config', error as Error);
    }
  }

  /**
   * 刷新播放统计数据
   */
  public refreshStatistics(statistics: Partial<PlaybackStatistics>): void {
    this.statistics = { ...this.statistics, ...statistics };
  }

  // 私有辅助方法

  /**
   * 更新播放状态
   * @param status 新状态
   * @param eventData 事件数据
   */
  private updateStatus(status: PlaybackStatus, eventData: Partial<PlaybackEventData> = {}): void {
    this.status = status;
    
    // 构建事件数据
    const data: PlaybackEventData = {
      stream: this.currentStream || undefined,
      status,
      position: this.statistics.currentPlaybackTime,
      ...eventData
    };
    
    // 发布状态变化事件
    this.eventBus.emit('playback:statusChange', data);
    
    this.logger.debug(`Playback status changed to: ${status}`);
  }

  /**
   * 获取上一个播放状态
   */
  private getPreviousPlaybackStatus(): PlaybackStatus {
    // 当跳转或缓冲完成后，恢复到播放或暂停状态
    if (this.statistics.currentPlaybackTime > 0 && 
        this.currentStream && 
        this.status !== PlaybackStatus.ERROR && 
        this.status !== PlaybackStatus.IDLE) {
      return PlaybackStatus.PLAYING;
    }
    return PlaybackStatus.PAUSED;
  }

  /**
   * 开始播放计时器
   */
  private startPlaybackTimer(): void {
    this.stopPlaybackTimer(); // 确保之前的计时器已停止
    this.lastUpdateTime = Date.now();
    
    this.playbackTimer = setInterval(() => {
      const now = Date.now();
      const deltaTime = now - this.lastUpdateTime;
      
      // 根据播放速度调整时间增量
      const adjustedDeltaTime = deltaTime * this.config.playbackSpeed;
      
      this.statistics.currentPlaybackTime += adjustedDeltaTime;
      this.statistics.totalPlaybackTime += adjustedDeltaTime;
      
      this.lastUpdateTime = now;
      
      // 定期保存播放位置
      if (this.statistics.currentPlaybackTime % 5000 < adjustedDeltaTime) { // 大约每5秒保存一次
        this.savePlaybackPosition().catch(error => {
          this.logger.error('Failed to save playback position', error as Error);
        });
      }
      
      // 发布播放进度事件
      this.eventBus.emit(GlobalEventType.PLAYER_PROGRESS, {
        stream: this.currentStream,
        position: this.statistics.currentPlaybackTime,
        duration: this.currentStream?.statistics?.bufferHealth || 0
      });
    }, 1000) as unknown as number; // 每秒更新一次
  }

  /**
   * 停止播放计时器
   */
  private stopPlaybackTimer(): void {
    if (this.playbackTimer) {
      clearInterval(this.playbackTimer);
      this.playbackTimer = null;
    }
  }

  /**
   * 保存播放位置
   */
  private async savePlaybackPosition(): Promise<void> {
    if (!this.currentStream || !this.config.rememberPosition) {
      return;
    }
    
    try {
      this.playbackPositions.set(this.currentStream.id, this.statistics.currentPlaybackTime);
      await this.storageUtil.set('playback_positions', Object.fromEntries(this.playbackPositions), LocalStorageType.PERSISTENT);
      this.logger.debug(`Saved playback position: ${this.statistics.currentPlaybackTime}ms for stream: ${this.currentStream.id}`);
    } catch (error) {
      this.logger.error('Failed to save playback position', error as Error);
    }
  }

  /**
   * 加载播放位置历史
   */
  private async loadPlaybackPositions(): Promise<void> {
    try {
      const positions = await this.storageUtil.get<Record<string, number>>('playback_positions', LocalStorageType.PERSISTENT) || {};
      this.playbackPositions = new Map(Object.entries(positions));
      this.logger.info(`Loaded ${this.playbackPositions.size} playback positions`);
    } catch (error) {
      this.logger.error('Failed to load playback positions', error as Error);
      this.playbackPositions = new Map();
    }
  }

  /**
   * 保存播放配置
   */
  private async savePlaybackConfig(): Promise<void> {
    try {
      await this.storageUtil.set('playback_config', this.config, LocalStorageType.PERSISTENT);
      // 同时保存到配置仓库
      await this.configRepository.setConfig('playback', this.config);
      this.logger.debug('Playback config saved');
    } catch (error) {
      this.logger.error('Failed to save playback config', error as Error);
    }
  }

  /**
   * 加载播放配置
   */
  private async loadPlaybackConfig(): Promise<void> {
    try {
      // 尝试从本地存储加载
      let config = await this.storageUtil.get<PlaybackConfig>('playback_config', LocalStorageType.PERSISTENT);
      
      // 如果本地存储没有，尝试从配置仓库加载
      if (!config) {
        config = await this.configRepository.getConfig<PlaybackConfig>('playback');
      }
      
      // 如果有配置，合并到当前配置
      if (config) {
        this.config = { ...this.config, ...config };
      }
      
      this.logger.info('Playback config loaded successfully');
    } catch (error) {
      this.logger.error('Failed to load playback config', error as Error);
      // 使用默认配置
    }
  }

  /**
   * 应用配置变更
   */
  private applyConfigChanges(): void {
    // 应用音量和静音设置
    this.setVolumeInternal(this.config.volume);
    this.setMutedInternal(this.config.muted);
    
    // 应用播放速度设置
    this.setPlaybackSpeedInternal(this.config.playbackSpeed);
    
    // 应用字幕设置
    if (this.currentStream && this.config.selectedSubtitleId) {
      this.setSubtitleTrackInternal(this.config.selectedSubtitleId).catch(error => {
        this.logger.error('Failed to apply subtitle config', error as Error);
      });
    }
    
    // 应用音频轨道设置
    if (this.currentStream && this.config.selectedAudioId) {
      this.setAudioTrackInternal(this.config.selectedAudioId).catch(error => {
        this.logger.error('Failed to apply audio track config', error as Error);
      });
    }
  }

  /**
   * 重置统计数据
   */
  private resetStatistics(): void {
    this.statistics = {
      totalPlaybackTime: 0,
      currentPlaybackTime: 0,
      bufferedTime: 0,
      seekCount: 0,
      pauseCount: 0,
      playbackErrors: 0,
      averageBitrate: 0,
      resolution: '0x0',
      codecInfo: '',
      droppedFrames: 0,
      bufferUnderruns: 0
    };
  }

  /**
   * 清理播放资源
   */
  private cleanupPlayback(): void {
    // 停止计时器
    this.stopPlaybackTimer();
    
    // 清理音视频轨道
    this.audioTracks = [];
    this.subtitleTracks = [];
    
    // 清理当前流
    // 注意：不清理currentStream，保留以便查询
  }

  /**
   * 处理网络状态变化
   * @param status 网络状态
   */
  private handleNetworkStatusChange(status: any): void {
    this.logger.debug('Network status changed during playback:', status);
    
    // 根据网络状态调整播放策略
    if (status === 'offline' && this.status === PlaybackStatus.PLAYING) {
      // 网络断开时暂停播放
      this.pause().catch(error => {
        this.logger.error('Failed to pause on network offline', error as Error);
      });
    }
  }

  /**
   * 处理应用暂停
   */
  private handleAppPause(): void {
    this.logger.debug('App paused during playback');
    
    // 如果启用了后台播放，降低质量或其他处理
    if (!this.config.backgroundPlay && this.status === PlaybackStatus.PLAYING) {
      // 暂停播放
      this.pause().catch(error => {
        this.logger.error('Failed to pause on app pause', error as Error);
      });
    }
  }

  /**
   * 处理应用恢复
   */
  private handleAppResume(): void {
    this.logger.debug('App resumed during playback');
    // 可以在这里添加恢复播放的逻辑
  }

  // 以下是模拟播放组件的方法
  // 在实际应用中，这些方法应该调用真实的播放器API

  /**
   * 模拟加载过程
   */
  private async simulateLoading(): Promise<void> {
    return new Promise(resolve => {
      setTimeout(resolve, 1000); // 模拟1秒加载时间
    });
  }

  /**
   * 初始化播放组件
   */
  private async initializePlayer(stream: LiveStream, position: number): Promise<void> {
    // 模拟初始化播放器
    this.logger.debug(`Initializing player for stream: ${stream.id} at position: ${position}`);
    
    // 模拟加载音视频轨道
    this.simulateTracks();
    
    return Promise.resolve();
  }

  /**
   * 模拟播放
   */
  private async playInternal(): Promise<void> {
    // 模拟调用播放器的播放方法
    return Promise.resolve();
  }

  /**
   * 模拟暂停
   */
  private async pauseInternal(): Promise<void> {
    // 模拟调用播放器的暂停方法
    return Promise.resolve();
  }

  /**
   * 模拟停止
   */
  private async stopInternal(): Promise<void> {
    // 模拟调用播放器的停止方法
    return Promise.resolve();
  }

  /**
   * 模拟跳转
   */
  private async seekInternal(position: number): Promise<void> {
    // 模拟调用播放器的跳转方法
    return new Promise(resolve => {
      setTimeout(resolve, 500); // 模拟跳转延迟
    });
  }

  /**
   * 模拟设置音量
   */
  private setVolumeInternal(volume: number): void {
    // 模拟设置播放器音量
  }

  /**
   * 模拟设置静音
   */
  private setMutedInternal(muted: boolean): void {
    // 模拟设置播放器静音
  }

  /**
   * 模拟设置播放速度
   */
  private setPlaybackSpeedInternal(speed: PlaybackSpeed): void {
    // 模拟设置播放器速度
  }

  /**
   * 模拟设置质量
   */
  private async setQualityInternal(quality: LiveStreamQuality): Promise<void> {
    // 模拟设置播放质量
    return new Promise(resolve => {
      setTimeout(resolve, 1500); // 模拟切换质量延迟
    });
  }

  /**
   * 模拟设置字幕轨道
   */
  private async setSubtitleTrackInternal(subtitleId: string | null): Promise<void> {
    // 模拟设置字幕轨道
    return Promise.resolve();
  }

  /**
   * 模拟设置音频轨道
   */
  private async setAudioTrackInternal(audioId: string): Promise<void> {
    // 模拟设置音频轨道
    return Promise.resolve();
  }

  /**
   * 模拟切换全屏
   */
  private async toggleFullscreenInternal(fullscreen: boolean): Promise<void> {
    // 模拟切换全屏
    return Promise.resolve();
  }

  /**
   * 模拟加载轨道信息
   */
  private simulateTracks(): void {
    // 模拟音频轨道
    this.audioTracks = [
      { id: 'audio_1', label: '默认', language: 'zh-CN', codec: 'AAC', bitrate: 192 },
      { id: 'audio_2', label: '英语', language: 'en-US', codec: 'AAC', bitrate: 192 },
      { id: 'audio_3', label: '日语', language: 'ja-JP', codec: 'AAC', bitrate: 192 }
    ];
    
    // 模拟字幕轨道
    this.subtitleTracks = [
      { id: 'sub_1', label: '简体中文', language: 'zh-CN', src: '/subtitles/chinese.vtt', type: 'vtt' },
      { id: 'sub_2', label: '英语', language: 'en-US', src: '/subtitles/english.vtt', type: 'vtt' },
      { id: 'sub_3', label: '双语', language: 'zh-CN,en-US', src: '/subtitles/bilingual.vtt', type: 'vtt' }
    ];
  }
}

// 导出默认实例
export default PlaybackService.getInstance();