// PlayerService.ets - 播放器服�?// 基于HarmonyOS AVPlayer API实现媒体播放功能，提供统一的播放器接口

import Logger from '../../common/util/Logger';
import { AVPlayerService, AVPlayerServiceInstance } from '../playback/AVPlayerService';

// 播放器状态枚�?export enum PlayerStatus {
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

// 播放器事件枚�?export enum PlayerEvent {
  STATUS_CHANGED = 'status_changed',
  TIME_UPDATE = 'time_update',
  BUFFER_UPDATE = 'buffer_update',
  ERROR = 'error',
  COMPLETED = 'completed'
}

// 播放器配置接�?export interface PlayerConfig {
  autoPlay: boolean;
  loop: boolean;
  muted: boolean;
  volume: number;
  playbackRate: number;
  startPosition: number;
}

// 默认播放器配�?export const DEFAULT_PLAYER_CONFIG: PlayerConfig = {
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
   * 构造函�?   */
  private constructor() {
    this.avPlayerService = AVPlayerServiceInstance;
  }

  /**
   * 初始化播放器服务
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      Logger.info('PlayerService', 'Player service already initialized');
      return;
    }

    try {
      await this.avPlayerService.init();
      this.setupEventListeners();
      this.isInitialized = true;
      Logger.info('PlayerService', 'Player service initialized successfully');
    } catch (error) {
      Logger.error('PlayerService', `Failed to initialize player service: ${error}`);
      throw error;
    }
  }

  /**
   * 设置事件监听�?   */
  private setupEventListeners(): void {
    // 设置状态变化监�?    this.avPlayerService.onStatusChange((status) => {
      this.emitEvent(PlayerEvent.STATUS_CHANGED, status instanceof Error ? status : new Error(String(status instanceof Error ? status instanceof Error ? status : new Error(String(status : new Error(String(status instanceof Error ? status : new Error(String(status instanceof Error ? status instanceof Error ? status : new Error(String(status instanceof Error ? status instanceof Error ? status : new Error(String(status : new Error(String(status instanceof Error ? status : new Error(String(status : new Error(String(status instanceof Error ? status : new Error(String(status instanceof Error ? status instanceof Error ? status : new Error(String(status : new Error(String(status instanceof Error ? status : new Error(String(status)))))));
    });

    // 设置错误监听
    this.avPlayerService.onError((error) => {
      this.emitEvent(PlayerEvent.ERROR, error);
    });

    // 设置缓冲更新监听
    this.avPlayerService.onBufferUpdate((bufferingRate) => {
      this.emitEvent(PlayerEvent.BUFFER_UPDATE, bufferingRate);
    });
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
      this.config = { ...DEFAULT_PLAYER_CONFIG, ...options };

      // 设置播放�?      await this.avPlayerService.setSource(sourceUrl);

      // 准备播放
      await this.avPlayerService.prepare();

      // 设置初始配置
      await this.avPlayerService.setVolume(this.config.volume);
      await this.avPlayerService.setMute(this.config.muted);

      // 跳转到指定位�?      if (this.config.startPosition > 0) {
        await this.avPlayerService.seekTo(this.config.startPosition);
      }

      // 自动播放
      if (this.config.autoPlay) {
        await this.avPlayerService.play();
      }

      Logger.info('PlayerService', `Playing media: ${mediaId}`);
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
      Logger.info('PlayerService', 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused')))))));
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
      Logger.info('PlayerService', 'Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed' instanceof Error ? 'Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed' : new Error(String('Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed' instanceof Error ? 'Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed' instanceof Error ? 'Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed' : new Error(String('Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed' : new Error(String('Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed' instanceof Error ? 'Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed' : new Error(String('Playback resumed' instanceof Error ? 'Playback resumed' : new Error(String('Playback resumed')))))));
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
      Logger.info('PlayerService', 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped')))))));
    } catch (error) {
      Logger.error('PlayerService', `Failed to stop: ${error}`);
      throw error;
    }
  }

  /**
   * 跳转到指定位�?   */
  public async seekTo(position: number): Promise<void> {
    try {
      await this.avPlayerService.seekTo(position);
      Logger.debug('PlayerService', `Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` : new Error(String(`Seek to position: ${position}` instanceof Error ? `Seek to position: ${position}` : new Error(String(`Seek to position: ${position}`)))))));
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
      return await this.avPlayerService.getCurrentTime();
    } catch (error) {
      Logger.error('PlayerService', `Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}` instanceof Error ? `Failed to get current position: ${error}` : new Error(String(`Failed to get current position: ${error}`)))))));
      return 0;
    }
  }

  /**
   * 获取总时�?   */
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
   * 检查是否正在播�?   */
  public isPlaying(): boolean {
    return this.avPlayerService.getStatus() === PlayerStatus.PLAYING;
  }

  /**
   * 设置音量
   */
  public async setVolume(volume: number): Promise<void> {
    try {
      await this.avPlayerService.setVolume(volume);
      this.config.volume = volume;
    } catch (error) {
      Logger.error('PlayerService', `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}`)))))));
      throw error;
    }
  }

  /**
   * 设置静音
   */
  public async setMute(muted: boolean): Promise<void> {
    try {
      await this.avPlayerService.setMute(muted);
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
      // 这里需要根据实际的播放器API来实�?      // 暂时记录配置
      this.config.playbackRate = rate;
      Logger.info('PlayerService', `Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}` instanceof Error ? `Playback rate set to: ${rate}` : new Error(String(`Playback rate set to: ${rate}`)))))));
    } catch (error) {
      Logger.error('PlayerService', `Failed to set playback rate: ${error}`);
      throw error;
    }
  }

  /**
   * 添加事件监听�?   */
  public addEventListener(event: PlayerEvent, listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener : new Error(String(listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener : new Error(String(listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener : new Error(String(listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener : new Error(String(listener: PlayerEventListener instanceof Error ? listener: PlayerEventListener : new Error(String(listener: PlayerEventListener))))))): void {
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
   * 释放播放器资�?   */
  public async release(): Promise<void> {
    try {
      await this.avPlayerService.release();
      this.isInitialized = false;
      this.currentMediaId = '';
      this.currentEpisodeId = '';
      this.eventListeners.clear();
      Logger.info('PlayerService', 'Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released' instanceof Error ? 'Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released' : new Error(String('Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released' instanceof Error ? 'Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released' instanceof Error ? 'Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released' : new Error(String('Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released' : new Error(String('Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released' instanceof Error ? 'Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released' : new Error(String('Player service released' instanceof Error ? 'Player service released' : new Error(String('Player service released')))))));
    } catch (error) {
      Logger.error('PlayerService', `Failed to release player service: ${error}`);
      throw error;
    }
  }
}



