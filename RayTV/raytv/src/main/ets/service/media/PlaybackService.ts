import Logger from '@ohos/base/Logger';
import { Player } from '@ohos.multimedia.media';
import { HistoryService, historyService } from './HistoryService';
import { PlaySource } from './MediaService';

/**
 * 播放状态枚举
 */
export enum PlaybackState {
  IDLE = 0,        // 空闲状态
  INITIALIZING = 1, // 初始化中
  PREPARING = 2,   // 准备中
  READY = 3,       // 准备就绪
  PLAYING = 4,     // 播放中
  PAUSED = 5,      // 暂停
  COMPLETED = 6,   // 播放完成
  ERROR = 7,       // 错误
  STOPPED = 8      // 已停止
}

/**
 * 播放速度枚举
 */
export enum PlaybackSpeed {
  SLOW_0_5 = 0.5,
  NORMAL = 1.0,
  FAST_1_5 = 1.5,
  FAST_2_0 = 2.0,
  FAST_3_0 = 3.0
}

/**
 * 播放配置接口
 */
export interface PlaybackConfig {
  autoPlay?: boolean;       // 是否自动播放
  startPosition?: number;   // 开始播放位置（秒）
  volume?: number;          // 音量（0-1）
  isMuted?: boolean;        // 是否静音
  playbackSpeed?: PlaybackSpeed; // 播放速度
  enableBackgroundPlay?: boolean; // 是否启用后台播放
  headers?: Record<string, string>; // 请求头
}

/**
 * 播放信息接口
 */
export interface PlaybackInfo {
  state: PlaybackState;     // 播放状态
  currentTime: number;      // 当前播放时间（秒）
  duration: number;         // 总时长（秒）
  isPlaying: boolean;       // 是否正在播放
  volume: number;           // 当前音量
  isMuted: boolean;         // 是否静音
  playbackSpeed: PlaybackSpeed; // 当前播放速度
  isBuffering: boolean;     // 是否缓冲中
  bufferPercentage: number; // 缓冲百分比
  source?: PlaySource;      // 当前播放源
}

/**
 * 播放事件监听器接口
 */
export interface PlaybackListener {
  onStateChanged?: (state: PlaybackState) => void;
  onTimeUpdate?: (currentTime: number, duration: number) => void;
  onError?: (error: Error) => void;
  onCompleted?: () => void;
  onBufferUpdate?: (bufferPercentage: number) => void;
  onSeekCompleted?: (seekTime: number) => void;
}

/**
 * 播放服务
 * 实现视频播放控制和状态管理
 */
export class PlaybackService {
  private readonly TAG: string = 'PlaybackService';
  private static instance: PlaybackService | null = null;
  private player: Player | null = null;
  private currentState: PlaybackState = PlaybackState.IDLE;
  private currentSource: PlaySource | null = null;
  private config: PlaybackConfig = {};
  private listeners: PlaybackListener[] = [];
  private isBuffering: boolean = false;
  private bufferPercentage: number = 0;
  private updateTimer: NodeJS.Timeout | null = null;
  private historyService: HistoryService;
  private savePositionInterval: number = 5000; // 每5秒保存一次播放进度
  private lastSaveTime: number = 0;

  /**
   * 默认播放配置
   */
  private static readonly DEFAULT_CONFIG: PlaybackConfig = {
    autoPlay: true,
    startPosition: 0,
    volume: 1.0,
    isMuted: false,
    playbackSpeed: PlaybackSpeed.NORMAL,
    enableBackgroundPlay: false
  };

  /**
   * 获取单例实例
   * @returns PlaybackService
   */
  public static getInstance(): PlaybackService {
    if (!PlaybackService.instance) {
      PlaybackService.instance = new PlaybackService();
    }
    return PlaybackService.instance;
  }

  /**
   * 构造函数
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.historyService = historyService;
    Logger.info(this.TAG, 'PlaybackService initialized');
  }

  /**
   * 设置播放源
   * @param source 播放源
   * @param config 播放配置
   * @returns Promise<void>
   */
  public async setSource(source: PlaySource, config?: PlaybackConfig): Promise<void> {
    try {
      // 释放之前的播放资源
      await this.release();

      // 更新配置和源信息
      this.config = { ...PlaybackService.DEFAULT_CONFIG, ...config };
      this.currentSource = source;
      this.currentState = PlaybackState.INITIALIZING;
      this.notifyStateChanged();

      Logger.info(this.TAG, `Setting playback source: ${source.name || 'Unknown'} with URL: ${source.url}`);

      // 创建播放器实例
      this.player = await Player.create();
      this.setupPlayerListeners();

      // 设置播放器属性
      await this.player.setSource(source.url);
      await this.player.setVolume(this.config.isMuted ? 0 : this.config.volume!);
      await this.player.setPlaybackSpeed(this.config.playbackSpeed!);
      
      // 设置请求头（如果有）
      if (source.headers && Object.keys(source.headers).length > 0) {
        // HarmonyOS Player API 可能不直接支持设置请求头，这里需要根据实际API进行调整
        Logger.info(this.TAG, `Setting custom headers for playback: ${JSON.stringify(source.headers)}`);
      }

      // 准备播放
      this.currentState = PlaybackState.PREPARING;
      this.notifyStateChanged();
      await this.player.prepare();

      // 准备就绪后，设置开始位置
      this.currentState = PlaybackState.READY;
      this.notifyStateChanged();

      // 如果配置了开始位置，进行跳转
      if (this.config.startPosition! > 0) {
        await this.seekTo(this.config.startPosition!);
      }

      // 如果配置了自动播放，则开始播放
      if (this.config.autoPlay) {
        await this.play();
      }

      // 启动进度更新定时器
      this.startUpdateTimer();
    } catch (error) {
      Logger.error(this.TAG, `Failed to set source: ${error}`);
      this.currentState = PlaybackState.ERROR;
      this.notifyStateChanged();
      this.notifyError(error as Error);
      throw error;
    }
  }

  /**
   * 开始播放
   * @returns Promise<void>
   */
  public async play(): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('Player not initialized');
      }

      await this.player.play();
      this.currentState = PlaybackState.PLAYING;
      this.notifyStateChanged();
      Logger.info(this.TAG, 'Playback started');
    } catch (error) {
      Logger.error(this.TAG, `Failed to play: ${error}`);
      throw error;
    }
  }

  /**
   * 暂停播放
   * @returns Promise<void>
   */
  public async pause(): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('Player not initialized');
      }

      await this.player.pause();
      this.currentState = PlaybackState.PAUSED;
      this.notifyStateChanged();
      Logger.info(this.TAG, 'Playback paused');
    } catch (error) {
      Logger.error(this.TAG, `Failed to pause: ${error}`);
      throw error;
    }
  }

  /**
   * 停止播放
   * @returns Promise<void>
   */
  public async stop(): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('Player not initialized');
      }

      await this.player.stop();
      this.currentState = PlaybackState.STOPPED;
      this.notifyStateChanged();
      this.stopUpdateTimer();
      Logger.info(this.TAG, 'Playback stopped');
    } catch (error) {
      Logger.error(this.TAG, `Failed to stop: ${error}`);
      throw error;
    }
  }

  /**
   * 释放播放器资源
   * @returns Promise<void>
   */
  public async release(): Promise<void> {
    try {
      // 先保存播放进度
      await this.savePlaybackPosition();

      // 停止定时器
      this.stopUpdateTimer();

      // 释放播放器资源
      if (this.player) {
        await this.player.release();
        this.player = null;
      }

      this.currentState = PlaybackState.IDLE;
      this.currentSource = null;
      this.isBuffering = false;
      this.bufferPercentage = 0;
      this.notifyStateChanged();
      Logger.info(this.TAG, 'Player released');
    } catch (error) {
      Logger.error(this.TAG, `Failed to release player: ${error}`);
    }
  }

  /**
   * 跳转到指定位置
   * @param time 时间位置（秒）
   * @returns Promise<void>
   */
  public async seekTo(time: number): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('Player not initialized');
      }

      const duration = await this.player.getDuration();
      const seekTime = Math.max(0, Math.min(time, duration));
      
      await this.player.seek(seekTime * 1000); // 转换为毫秒
      Logger.info(this.TAG, `Seeked to ${seekTime} seconds`);
      
      // 通知跳转完成
      this.notifySeekCompleted(seekTime);
    } catch (error) {
      Logger.error(this.TAG, `Failed to seek: ${error}`);
      throw error;
    }
  }

  /**
   * 设置音量
   * @param volume 音量值（0-1）
   * @returns Promise<void>
   */
  public async setVolume(volume: number): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('Player not initialized');
      }

      const clampedVolume = Math.max(0, Math.min(1, volume));
      this.config.volume = clampedVolume;
      
      if (!this.config.isMuted) {
        await this.player.setVolume(clampedVolume);
      }
      
      Logger.info(this.TAG, `Volume set to ${clampedVolume}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set volume: ${error}`);
      throw error;
    }
  }

  /**
   * 设置静音状态
   * @param muted 是否静音
   * @returns Promise<void>
   */
  public async setMuted(muted: boolean): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('Player not initialized');
      }

      this.config.isMuted = muted;
      await this.player.setVolume(muted ? 0 : this.config.volume!);
      Logger.info(this.TAG, `Muted: ${muted}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set muted: ${error}`);
      throw error;
    }
  }

  /**
   * 设置播放速度
   * @param speed 播放速度
   * @returns Promise<void>
   */
  public async setPlaybackSpeed(speed: PlaybackSpeed): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('Player not initialized');
      }

      this.config.playbackSpeed = speed;
      await this.player.setPlaybackSpeed(speed);
      Logger.info(this.TAG, `Playback speed set to ${speed}x`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set playback speed: ${error}`);
      throw error;
    }
  }

  /**
   * 获取当前播放信息
   * @returns Promise<PlaybackInfo>
   */
  public async getPlaybackInfo(): Promise<PlaybackInfo> {
    try {
      let currentTime = 0;
      let duration = 0;
      
      if (this.player) {
        currentTime = await this.player.getCurrentTime() / 1000; // 转换为秒
        duration = await this.player.getDuration() / 1000; // 转换为秒
      }

      return {
        state: this.currentState,
        currentTime,
        duration,
        isPlaying: this.currentState === PlaybackState.PLAYING,
        volume: this.config.volume!,
        isMuted: this.config.isMuted!,
        playbackSpeed: this.config.playbackSpeed!,
        isBuffering: this.isBuffering,
        bufferPercentage: this.bufferPercentage,
        source: this.currentSource || undefined
      };
    } catch (error) {
      Logger.error(this.TAG, `Failed to get playback info: ${error}`);
      throw error;
    }
  }

  /**
   * 添加播放监听器
   * @param listener 监听器
   */
  public addListener(listener: PlaybackListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /**
   * 移除播放监听器
   * @param listener 监听器
   */
  public removeListener(listener: PlaybackListener): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 保存播放进度到历史记录
   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @param episodeId 剧集ID（可选）
   * @returns Promise<boolean>
   */
  public async savePlaybackPosition(
    mediaId?: string,
    siteKey?: string,
    episodeId?: string
  ): Promise<boolean> {
    try {
      if (!this.player || !this.currentSource || this.currentState === PlaybackState.IDLE) {
        return false;
      }

      // 检查是否需要保存（避免过于频繁）
      const now = Date.now();
      if (now - this.lastSaveTime < this.savePositionInterval) {
        return false;
      }

      const currentTime = await this.player.getCurrentTime() / 1000;
      const duration = await this.player.getDuration() / 1000;

      // 只有播放了一段时间才保存
      if (currentTime > 5 || duration > 0) {
        // 如果没有提供参数，尝试从源信息中获取
        if (!mediaId || !siteKey) {
          // 这里需要根据实际的PlaySource结构进行调整
          // 假设PlaySource中有相关信息
          return false;
        }

        await this.historyService.updateProgress(mediaId, siteKey, currentTime, episodeId);
        this.lastSaveTime = now;
        Logger.debug(this.TAG, `Saved playback position: ${currentTime}s for ${siteKey}:${mediaId}`);
        return true;
      }
      return false;
    } catch (error) {
      Logger.error(this.TAG, `Failed to save playback position: ${error}`);
      return false;
    }
  }

  /**
   * 设置播放器监听器
   * @private
   */
  private setupPlayerListeners(): void {
    if (!this.player) return;

    // 这里需要根据HarmonyOS Player API的实际事件进行调整
    // 以下是示例，实际API可能有所不同
    
    // 播放完成事件
    this.player.on('playbackComplete', () => {
      Logger.info(this.TAG, 'Playback completed');
      this.currentState = PlaybackState.COMPLETED;
      this.notifyStateChanged();
      this.notifyCompleted();
      this.stopUpdateTimer();
    });

    // 错误事件
    this.player.on('error', (error) => {
      Logger.error(this.TAG, `Playback error: ${error}`);
      this.currentState = PlaybackState.ERROR;
      this.notifyStateChanged();
      this.notifyError(new Error(String(error)));
      this.stopUpdateTimer();
    });

    // 缓冲更新事件
    this.player.on('bufferUpdate', (bufferProgress) => {
      this.bufferPercentage = bufferProgress;
      this.notifyBufferUpdate(bufferProgress);
    });

    // 缓冲开始事件
    this.player.on('bufferingStart', () => {
      this.isBuffering = true;
    });

    // 缓冲结束事件
    this.player.on('bufferingEnd', () => {
      this.isBuffering = false;
    });
  }

  /**
   * 启动进度更新定时器
   * @private
   */
  private startUpdateTimer(): void {
    this.stopUpdateTimer(); // 先停止之前的定时器
    
    this.updateTimer = setInterval(async () => {
      try {
        if (this.player && (this.currentState === PlaybackState.PLAYING || this.currentState === PlaybackState.PAUSED)) {
          const currentTime = await this.player.getCurrentTime() / 1000;
          const duration = await this.player.getDuration() / 1000;
          this.notifyTimeUpdate(currentTime, duration);
        }
      } catch (error) {
        Logger.warn(this.TAG, `Failed to update playback time: ${error}`);
      }
    }, 1000); // 每秒更新一次
  }

  /**
   * 停止进度更新定时器
   * @private
   */
  private stopUpdateTimer(): void {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
    }
  }

  /**
   * 通知状态变更
   * @private
   */
  private notifyStateChanged(): void {
    this.listeners.forEach(listener => {
      listener.onStateChanged?.(this.currentState);
    });
  }

  /**
   * 通知时间更新
   * @param currentTime 当前时间
   * @param duration 总时长
   * @private
   */
  private notifyTimeUpdate(currentTime: number, duration: number): void {
    this.listeners.forEach(listener => {
      listener.onTimeUpdate?.(currentTime, duration);
    });
  }

  /**
   * 通知错误
   * @param error 错误对象
   * @private
   */
  private notifyError(error: Error): void {
    this.listeners.forEach(listener => {
      listener.onError?.(error);
    });
  }

  /**
   * 通知播放完成
   * @private
   */
  private notifyCompleted(): void {
    this.listeners.forEach(listener => {
      listener.onCompleted?.();
    });
  }

  /**
   * 通知缓冲更新
   * @param bufferPercentage 缓冲百分比
   * @private
   */
  private notifyBufferUpdate(bufferPercentage: number): void {
    this.listeners.forEach(listener => {
      listener.onBufferUpdate?.(bufferPercentage);
    });
  }

  /**
   * 通知跳转完成
   * @param seekTime 跳转时间
   * @private
   */
  private notifySeekCompleted(seekTime: number): void {
    this.listeners.forEach(listener => {
      listener.onSeekCompleted?.(seekTime);
    });
  }

  /**
   * 获取支持的播放速度列表
   * @returns PlaybackSpeed[]
   */
  public getSupportedPlaybackSpeeds(): PlaybackSpeed[] {
    return [
      PlaybackSpeed.SLOW_0_5,
      PlaybackSpeed.NORMAL,
      PlaybackSpeed.FAST_1_5,
      PlaybackSpeed.FAST_2_0,
      PlaybackSpeed.FAST_3_0
    ];
  }

  /**
   * 获取播放速度的显示文本
   * @param speed 播放速度
   * @returns string
   */
  public getPlaybackSpeedText(speed: PlaybackSpeed): string {
    if (speed === 1) return '正常';
    return `${speed}x`;
  }
}

// 导出播放服务单例
export const playbackService = PlaybackService.getInstance();