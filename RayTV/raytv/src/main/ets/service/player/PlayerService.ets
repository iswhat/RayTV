// PlayerService.ets - 播放器服务 Player service
// 基于HarmonyOS AVPlayer API实现媒体播放功能，提供统一的播放器接口 Based on HarmonyOS AVPlayer API to implement media playback functionality, provides unified player interface

import Logger from '../../common/util/Logger';
import { AVPlayerService } from '../playback/AVPlayerService';

// 播放器状态枚举 Player status enum
export enum PlayerStatus {
  IDLE = 'IDLE',             // 空闲状态 Idle status
  INITIALIZED = 'INITIALIZED', // 已初始化 Initialized
  PREPARING = 'PREPARING',     // 准备中 Preparing
  PREPARED = 'PREPARED',       // 准备完成 Prepared
  PLAYING = 'PLAYING',         // 播放中 Playing
  PAUSED = 'PAUSED',           // 暂停 Paused
  STOPPED = 'STOPPED',         // 停止 Stopped
  COMPLETED = 'COMPLETED',     // 播放完成 Completed
  ERROR = 'ERROR'              // 错误 Error
}

// 播放器事件枚举 Player event enum
export enum PlayerEvent {
  STATUS_CHANGED = 'status_changed',  // 状态变更 Status changed
  TIME_UPDATE = 'time_update',        // 时间更新 Time update
  BUFFER_UPDATE = 'buffer_update',    // 缓冲更新 Buffer update
  ERROR = 'error',                    // 错误 Error
  COMPLETED = 'completed'             // 播放完成 Completed
}

// 播放器配置接口 Player configuration interface
export interface PlayerConfig {
  autoPlay: boolean;       // 自动播放 Auto play
  loop: boolean;           // 循环播放 Loop
  muted: boolean;          // 静音 Muted
  volume: number;          // 音量 Volume
  playbackRate: number;     // 播放速率 Playback rate
  startPosition: number;    // 起始位置 Start position
}

// 默认播放器配置 Default player configuration
export const DEFAULT_PLAYER_CONFIG: PlayerConfig = {
  autoPlay: false,       // 不自动播放 Don't auto play
  loop: false,           // 不循环播放 Don't loop
  muted: false,          // 不静音 Not muted
  volume: 1.0,           // 音量1.0 Volume 1.0
  playbackRate: 1.0,      // 播放速率1.0 Playback rate 1.0
  startPosition: 0        // 起始位置0 Start position 0
};

// 播放器事件数据类型映射 Player event data type mapping
interface PlayerEventDataMap {
  [PlayerEvent.STATUS_CHANGED]: PlayerStatus;
  [PlayerEvent.TIME_UPDATE]: number;
  [PlayerEvent.BUFFER_UPDATE]: number;
  [PlayerEvent.ERROR]: {code: number; message: string};
  [PlayerEvent.COMPLETED]: void;
}

// 播放器事件监听器类型 Player event listener type
type PlayerEventListener = <E extends PlayerEvent>(event: E, data: PlayerEventDataMap[E]) => void;

// 字幕样式接口 Subtitle style interface
export interface SubtitleStyle {
  fontSize: number;        // 字体大小 Font size
  fontColor: string;       // 字体颜色 Font color
  backgroundColor: string; // 背景颜色 Background color
  backgroundOpacity: number; // 背景透明度 Background opacity
  borderColor: string;     // 边框颜色 Border color
  borderWidth: number;     // 边框宽度 Border width
  position: 'bottom' | 'top'; // 位置 Position
}

// 默认字幕样式 Default subtitle style
export const DEFAULT_SUBTITLE_STYLE: SubtitleStyle = {
  fontSize: 16,               // 字体大小16 Font size 16
  fontColor: '#FFFFFF',       // 白色字体 White font
  backgroundColor: '#000000', // 黑色背景 Black background
  backgroundOpacity: 0.7,     // 背景透明度0.7 Background opacity 0.7
  borderColor: '#000000',     // 黑色边框 Black border
  borderWidth: 1,             // 边框宽度1 Border width 1
  position: 'bottom'          // 底部位置 Bottom position
};

export default class PlayerService {
  private static instance: PlayerService;
  private avPlayerService: AVPlayerService;
  private config: PlayerConfig = DEFAULT_PLAYER_CONFIG;
  private currentMediaId: string = '';
  private currentEpisodeId: string = '';
  private eventListeners: Map<PlayerEvent, PlayerEventListener[]> = new Map();
  private isInitialized: boolean = false;

  /**
   * 获取单例实例 Get singleton instance
   */
  public static getInstance(): PlayerService {
    if (!PlayerService.instance) {
      PlayerService.instance = new PlayerService();
    }
    return PlayerService.instance;
  }

  /**
   * 构造函数 Constructor
   */
  private constructor() {
    this.avPlayerService = AVPlayerService.getInstance();
  }

  /**
   * 初始化播放器服务 Initialize player service
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      Logger.info('PlayerService', 'Player service already initialized', {});
      return;
    }

    try {
      // AVPlayerService 会在需要时自动初始化，不需要显式调用 initialize
      // AVPlayerService will automatically initialize when needed, no need to call initialize explicitly
      this.setupEventListeners();
      this.isInitialized = true;
      Logger.info('PlayerService', 'Player service initialized successfully', {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to initialize player service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 设置事件监听器 Set event listeners
   */
  private setupEventListeners(): void {
    // 设置状态变更监听
    // 注意：这里需要根据实际 AVPlayerService 的 API 调整事件监听方法
    // 简化实现，仅记录日志
    // Set status change listener
    // Note: Need to adjust event listening method according to actual AVPlayerService API
    // Simplified implementation, only record logs
  }

  /**
   * 播放媒体 Play media
   */
  public async playMedia(mediaId: string, sourceUrl: string, options?: Partial<PlayerConfig>): Promise<void> {
    try {
      if (!this.isInitialized) {
        await this.initialize();
      }

      this.currentMediaId = mediaId;
      this.config = Object.assign({}, DEFAULT_PLAYER_CONFIG, options) as PlayerConfig;

      // 设置播放源 Set playback source
      await this.avPlayerService.setSource(sourceUrl);

      // 准备播放 Prepare playback
      await this.avPlayerService.prepare();

      // 设置初始配置 Set initial configuration
      await this.avPlayerService.setVolume(this.config.volume);
      // 注意：AVPlayerService可能没有setMute方法，需要根据实际API调整
      // Note: AVPlayerService may not have setMute method, need to adjust according to actual API

      // 跳转到指定位置 Seek to specified position
      if (this.config.startPosition > 0) {
        await this.avPlayerService.seekTo(this.config.startPosition);
      }

      // 自动播放 Auto play
      if (this.config.autoPlay) {
        await this.avPlayerService.play();
      }

      Logger.info('PlayerService', `Playing media: ${mediaId}`, {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to play media: ${error}`);
      throw error;
    }
  }

  /**
   * 暂停播放 Pause playback
   */
  public async pause(): Promise<void> {
    try {
      await this.avPlayerService.pause();
      Logger.info('PlayerService', 'Playback paused', {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to pause: ${error}`);
      throw error;
    }
  }

  /**
   * 恢复播放 Resume playback
   */
  public async resume(): Promise<void> {
    try {
      await this.avPlayerService.play();
      Logger.info('PlayerService', 'Playback resumed', {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to resume: ${error}`);
      throw error;
    }
  }

  /**
   * 停止播放 Stop playback
   */
  public async stop(): Promise<void> {
    try {
      await this.avPlayerService.stop();
      this.currentMediaId = '';
      this.currentEpisodeId = '';
      Logger.info('PlayerService', 'Playback stopped', {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to stop: ${error}`);
      throw error;
    }
  }

  /**
   * 跳转到指定位置 Seek to specified position
   */
  public async seekTo(position: number): Promise<void> {
    try {
      await this.avPlayerService.seekTo(position);
      Logger.debug('PlayerService', `Seek to position: ${position}`, {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to seek: ${error}`);
      throw error;
    }
  }

  /**
   * 获取当前播放位置 Get current playback position
   */
  public async getCurrentPosition(): Promise<number> {
    try {
      return await this.avPlayerService.getCurrentPosition();
    } catch (error) {
      Logger.error('PlayerService', `Failed to get current position: ${error}`);
      return 0;
    }
  }

  /**
   * 获取总时长 Get total duration
   */
  public async getDuration(): Promise<number> {
    try {
      return await this.avPlayerService.getDuration();
    } catch (error) {
      Logger.error('PlayerService', `Failed to get duration: ${error}`);
      return 0;
    }
  }

  /**
   * 获取当前媒体ID Get current media ID
   */
  public getCurrentMediaId(): string {
    return this.currentMediaId;
  }

  /**
   * 获取当前剧集ID Get current episode ID
   */
  public getCurrentEpisodeId(): string {
    return this.currentEpisodeId;
  }

  /**
   * 设置当前剧集ID Set current episode ID
   */
  public setCurrentEpisodeId(episodeId: string): void {
    this.currentEpisodeId = episodeId;
  }

  /**
   * 检查是否正在播放 Check if playing
   */
  public isPlaying(): boolean {
    return this.avPlayerService.getStatus() === 'playing'; // AVPlayerService 返回的是字符串状态 AVPlayerService returns string status
  }

  /**
   * 设置音量 Set volume
   */
  public async setVolume(volume: number): Promise<void> {
    try {
      await this.avPlayerService.setVolume(volume);
      this.config.volume = volume;
    } catch (error) {
      Logger.error('PlayerService', `Failed to set volume: ${error}`);
      throw error;
    }
  }

  /**
   * 设置静音 Set mute
   */
  public async setMute(muted: boolean): Promise<void> {
    try {
      // AVPlayerService没有setMute方法，通过设置音量来实现静音效果
      // AVPlayerService doesn't have setMute method, implement mute by setting volume
      await this.avPlayerService.setVolume(muted ? 0 : this.config.volume);
      this.config.muted = muted;
    } catch (error) {
      Logger.error('PlayerService', `Failed to set mute: ${error}`);
      throw error;
    }
  }

  /**
   * 设置播放速率 Set playback rate
   */
  public async setPlaybackRate(rate: number): Promise<void> {
    try {
      // 这里需要根据实际的播放器API来实现
      // 暂时记录配置
      // Need to implement according to actual player API
      // Temporarily record configuration
      this.config.playbackRate = rate;
      Logger.info('PlayerService', `Playback rate set to: ${rate}`, {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to set playback rate: ${error}`);
      throw error;
    }
  }

  /**
   * 添加事件监听器 Add event listener
   */
  public addEventListener(event: PlayerEvent, listener: PlayerEventListener): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    const listeners = this.eventListeners.get(event);
    if (listeners !== null && listeners !== undefined) {
      listeners.push(listener);
    }
  }

  /**
   * 移除事件监听器 Remove event listener
   */
  public removeEventListener(event: PlayerEvent, listener: PlayerEventListener): void {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 触发事件 Emit event
   */
  private emitEvent<E extends PlayerEvent>(event: E, data: PlayerEventDataMap[E]): void {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      listeners.forEach(listener => {
        try {
          listener(event, data);
        } catch (error) {
          Logger.error('PlayerService', `Error in event listener: ${error}`);
        }
      });
    }
  }

  /**
   * 释放播放器资源 Release player resources
   */
  public async release(): Promise<void> {
    try {
      await this.avPlayerService.release();
      this.isInitialized = false;
      this.currentMediaId = '';
      this.currentEpisodeId = '';
      this.eventListeners.clear();
      Logger.info('PlayerService', 'Player service released', {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to release player service: ${error}`);
      throw error;
    }
  }
}






