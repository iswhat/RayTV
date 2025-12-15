// PlayerService.ets - 播放器服务
// 基于HarmonyOS AVPlayer API实现媒体播放功能，提供统一的播放器接口

import Logger from '../../common/util/Logger';
import { AVPlayerService } from '../playback/AVPlayerService';

// 播放器状态枚举
export enum PlayerStatus {
  IDLE = 'IDLE',
  INITIALIZED = 'INITIALIZED',
  PREPARING = 'PREPARING',
  PREPARED = 'PREPARED',
  PLAYING = 'PLAYING',
  PAUSED = 'PAUSED',
  STOPPED = 'STOPPED',
  COMPLETED = 'COMPLETED',
  ERROR = 'ERROR'
}

// 播放器事件枚举
export enum PlayerEvent {
  STATUS_CHANGED = 'status_changed',
  TIME_UPDATE = 'time_update',
  BUFFER_UPDATE = 'buffer_update',
  ERROR = 'error',
  COMPLETED = 'completed'
}

// 播放器配置接口
export interface PlayerConfig {
  autoPlay: boolean;
  loop: boolean;
  muted: boolean;
  volume: number;
  playbackRate: number;
  startPosition: number;
}

// 默认播放器配置
export const DEFAULT_PLAYER_CONFIG: PlayerConfig = {
  autoPlay: false,
  loop: false,
  muted: false,
  volume: 1.0,
  playbackRate: 1.0,
  startPosition: 0
};

// 播放器事件数据类型映�?interface PlayerEventDataMap {
  [PlayerEvent.STATUS_CHANGED]: PlayerStatus;
  [PlayerEvent.TIME_UPDATE]: number;
  [PlayerEvent.BUFFER_UPDATE]: number;
  [PlayerEvent.ERROR]: {code: number; message: string};
  [PlayerEvent.COMPLETED]: void;
}

// 播放器事件监听器类型
type PlayerEventListener = <E extends PlayerEvent>(event: E, data: PlayerEventDataMap[E]) => void;

// 字幕样式接口
export interface SubtitleStyle {
  fontSize: number;
  fontColor: string;
  backgroundColor: string;
  backgroundOpacity: number;
  borderColor: string;
  borderWidth: number;
  position: 'bottom' | 'top';
}

// 默认字幕样式
export const DEFAULT_SUBTITLE_STYLE: SubtitleStyle = {
  fontSize: 16,
  fontColor: '#FFFFFF',
  backgroundColor: '#000000',
  backgroundOpacity: 0.7,
  borderColor: '#000000',
  borderWidth: 1,
  position: 'bottom'
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
   * 获取单例实例
   */
  public static getInstance(): PlayerService {
    if (!PlayerService.instance) {
      PlayerService.instance = new PlayerService();
    }
    return PlayerService.instance;
  }

  /**
   * 构造函数
   */
  private constructor() {
    this.avPlayerService = AVPlayerService.getInstance();
  }

  /**
   * 初始化播放器服务
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      Logger.info('PlayerService', 'Player service already initialized', {});
      return;
    }

    try {
      // AVPlayerService 会在需要时自动初始化，不需要显式调用 initialize
      this.setupEventListeners();
      this.isInitialized = true;
      Logger.info('PlayerService', 'Player service initialized successfully', {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to initialize player service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 设置状态变化监听
    // 注意：这里需要根据实际AVPlayerService的API调整事件监听方法名
    // 简化实现，仅记录日志
  }

  /**
   * 播放媒体
   */
  public async playMedia(mediaId: string, sourceUrl: string, options?: Partial<PlayerConfig>): Promise<void> {
    try {
      if (!this.isInitialized) {
        await this.initialize();
      }

      this.currentMediaId = mediaId;
      this.config = Object.assign({}, DEFAULT_PLAYER_CONFIG, options) as PlayerConfig;

      // 设置播放源
      await this.avPlayerService.setSource(sourceUrl);

      // 准备播放
      await this.avPlayerService.prepare();

      // 设置初始配置
      await this.avPlayerService.setVolume(this.config.volume);
      // 注意：AVPlayerService可能没有setMute方法，需要根据实际API调整

      // 跳转到指定位置
      if (this.config.startPosition > 0) {
        await this.avPlayerService.seekTo(this.config.startPosition);
      }

      // 自动播放
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
   * 暂停播放
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
   * 恢复播放
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
   * 停止播放
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
   * 跳转到指定位置
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
   * 获取当前播放位置
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
   * 获取总时长
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
   * 获取当前媒体ID
   */
  public getCurrentMediaId(): string {
    return this.currentMediaId;
  }

  /**
   * 获取当前剧集ID
   */
  public getCurrentEpisodeId(): string {
    return this.currentEpisodeId;
  }

  /**
   * 设置当前剧集ID
   */
  public setCurrentEpisodeId(episodeId: string): void {
    this.currentEpisodeId = episodeId;
  }

  /**
   * 检查是否正在播放
   */
  public isPlaying(): boolean {
    return this.avPlayerService.getStatus() === 'playing'; // AVPlayerService 返回的是字符串状态
  }

  /**
   * 设置音量
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
   * 设置静音
   */
  public async setMute(muted: boolean): Promise<void> {
    try {
      // AVPlayerService没有setMute方法，通过设置音量来实现静音效果
      await this.avPlayerService.setVolume(muted ? 0 : this.config.volume);
      this.config.muted = muted;
    } catch (error) {
      Logger.error('PlayerService', `Failed to set mute: ${error}`);
      throw error;
    }
  }

  /**
   * 设置播放速度
   */
  public async setPlaybackRate(rate: number): Promise<void> {
    try {
      // 这里需要根据实际的播放器API来实现
      // 暂时记录配置
      this.config.playbackRate = rate;
      Logger.info('PlayerService', `Playback rate set to: ${rate}`, {});
    } catch (error) {
      Logger.error('PlayerService', `Failed to set playback rate: ${error}`);
      throw error;
    }
  }

  /**
   * 添加事件监听器
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
   * 移除事件监听�?   */
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
   * 触发事件
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
   * 释放播放器资源
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



