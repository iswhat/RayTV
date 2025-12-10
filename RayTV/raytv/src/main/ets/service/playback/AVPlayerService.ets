// AVPlayerService.ets - AV播放器服�?// 实现基于HarmonyOS AVPlayer的媒体播放功�?
import media from '@ohos.multimedia.media';
import Logger from '../../common/util/Logger';
import { EventEmitter } from '../../common/util/EventEmitter';

// 播放状态枚�?export enum PlaybackStatus {
  IDLE = 'idle',
  INITIALIZED = 'initialized',
  PREPARING = 'preparing',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  SEEKING = 'seeking',
  ENDED = 'ended',
  ERROR = 'error'
}

/**
 * AV播放器服务类
 * 提供媒体播放的核心功�? */
export class AVPlayerService extends EventEmitter {
  private static instance: AVPlayerService;
  private avPlayer: media.AVPlayer | null = null;
  private status: PlaybackStatus = PlaybackStatus.IDLE;
  private sourceUrl: string = '';
  private isInitialized: boolean = false;
  private TAG: string = 'AVPlayerService';

  private constructor() {
    super();
  }

  /**
   * 获取播放器服务单例实�?   */
  public static getInstance(): AVPlayerService {
    if (!AVPlayerService.instance) {
      AVPlayerService.instance = new AVPlayerService();
    }
    return AVPlayerService.instance;
  }

  /**
   * 初始化播放器
   */
  private async initializePlayer(): Promise<void> {
    try {
      if (this.avPlayer) {
        await this.release();
      }

      this.avPlayer = await media.createAVPlayer();
      this.isInitialized = true;
      this.updateStatus(PlaybackStatus.IDLE);

      // 状态变化回�?      this.avPlayer.on('stateChange', (state, reason) => {
        Logger.info(this.TAG, `Player state changed: ${state}, reason: ${reason}`);
        this.updateStatus(this.mapAVPlayerState(state));
        this.emit('stateChange', this.status, reason);
      });

      // 错误回调
      this.avPlayer.on('error', (error: media.AVPlayerError) => {
        Logger.error(this.TAG, `Player error: ${error.code}, message: ${error.message}`);
        this.updateStatus(PlaybackStatus.ERROR);
        this.emit('error', error.code, error.message);
      });

      // 缓冲更新回调
      this.avPlayer.on('bufferingUpdate', (info: media.BufferingInfo) => {
        Logger.info(this.TAG, `Buffering update: ${info.bufferingPercentage}%`);
        this.emit('bufferingChange', info.bufferingPercentage);
      });

      // 播放完成回调
      this.avPlayer.on('playbackComplete', () => {
        Logger.info(this.TAG, 'Playback completed');
        this.updateStatus(PlaybackStatus.ENDED);
        this.emit('playbackComplete');
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize player: ${JSON.stringify(error)}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }

  /**
   * 映射AVPlayer状态到自定义状�?   */
  private mapAVPlayerState(state: number): PlaybackStatus {
    switch (state) {
      case media.AVPlayerState.IDLE:
        return PlaybackStatus.IDLE;
      case media.AVPlayerState.INITIALIZED:
        return PlaybackStatus.INITIALIZED;
      case media.AVPlayerState.PREPARING:
        return PlaybackStatus.PREPARING;
      case media.AVPlayerState.PREPARED:
        return PlaybackStatus.PREPARED;
      case media.AVPlayerState.PLAYING:
        return PlaybackStatus.PLAYING;
      case media.AVPlayerState.PAUSED:
        return PlaybackStatus.PAUSED;
      case media.AVPlayerState.SEEKING:
        return PlaybackStatus.SEEKING;
      case media.AVPlayerState.COMPLETED:
        return PlaybackStatus.ENDED;
      case media.AVPlayerState.ERROR:
        return PlaybackStatus.ERROR;
      default:
        return PlaybackStatus.IDLE;
    }
  }

  /**
   * 更新播放状�?   */
  private updateStatus(newStatus: PlaybackStatus): void {
    if (this.status !== newStatus) {
      this.status = newStatus;
      this.emit('statusChange', newStatus);
    }
  }

  /**
   * 设置播放�?   * @param source 播放源URL
   */
  public async setSource(source: string): Promise<void> {
    try {
      if (!this.avPlayer) {
        await this.initializePlayer();
      }
      
      this.sourceUrl = source;
      await this.avPlayer.setSource(source);
      this.updateStatus(PlaybackStatus.INITIALIZED);
      Logger.info(this.TAG, `Source set: ${source}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set source: ${JSON.stringify(error)}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }

  /**
   * 准备播放
   */
  public async prepare(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      this.updateStatus(PlaybackStatus.PREPARING);
      await this.avPlayer.prepare();
      this.updateStatus(PlaybackStatus.PREPARED);
    } catch (error) {
      Logger.error(this.TAG, `Failed to prepare: ${JSON.stringify(error)}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }

  /**
   * 开始播�?   */
  public async play(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.play();
      this.updateStatus(PlaybackStatus.PLAYING);
    } catch (error) {
      Logger.error(this.TAG, `Failed to play: ${JSON.stringify(error)}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }

  /**
   * 暂停播放
   */
  public async pause(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.pause();
      this.updateStatus(PlaybackStatus.PAUSED);
    } catch (error) {
      Logger.error(this.TAG, `Failed to pause: ${JSON.stringify(error)}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }

  /**
   * 停止播放
   */
  public async stop(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.stop();
      this.updateStatus(PlaybackStatus.IDLE);
    } catch (error) {
      Logger.error(this.TAG, `Failed to stop: ${JSON.stringify(error)}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }

  /**
   * 跳转到指定位�?   * @param position 位置（毫秒）
   */
  public async seekTo(position: number): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      this.updateStatus(PlaybackStatus.SEEKING);
      await this.avPlayer.seek(position);
      // 状态会在seek完成后通过stateChange回调更新
    } catch (error) {
      Logger.error(this.TAG, `Failed to seek: ${JSON.stringify(error)}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }

  /**
   * 设置播放速度
   * @param speed 播放速度�?.0为正常速度�?   */
  public async setSpeed(speed: number): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.setSpeed(speed);
      Logger.info(this.TAG, `Speed set to: ${speed}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set speed: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 设置音量
   * @param volume 音量值（0.0-1.0�?   */
  public async setVolume(volume: number): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.setVolume(volume);
      Logger.info(this.TAG, `Volume set to: ${volume}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set volume: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 获取当前播放位置
   * @returns 当前位置（毫秒）
   */
  public async getCurrentPosition(): Promise<number> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      return await this.avPlayer.getCurrentTime();
    } catch (error) {
      Logger.error(this.TAG, `Failed to get current position: ${JSON.stringify(error)}`);
      return 0;
    }
  }

  /**
   * 获取媒体总时�?   * @returns 总时长（毫秒�?   */
  public async getDuration(): Promise<number> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      return await this.avPlayer.getDuration();
    } catch (error) {
      Logger.error(this.TAG, `Failed to get duration: ${JSON.stringify(error)}`);
      return 0;
    }
  }

  /**
   * 获取当前播放状�?   * @returns 播放状�?   */
  public getStatus(): PlaybackStatus {
    return this.status;
  }

  /**
   * 获取当前播放源URL
   * @returns 播放源URL
   */
  public getSourceUrl(): string {
    return this.sourceUrl;
  }

  /**
   * 释放播放器资�?   */
  public async release(): Promise<void> {
    try {
      if (this.avPlayer) {
        await this.avPlayer.release();
        this.avPlayer = null;
        this.isInitialized = false;
        this.sourceUrl = '';
        this.updateStatus(PlaybackStatus.IDLE);
        Logger.info(this.TAG, 'Player released');
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to release player: ${JSON.stringify(error)}`);
      // 释放失败不影响其他操�?    }
  }

  /**
   * 重置播放�?   */
  public async reset(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.reset();
      this.updateStatus(PlaybackStatus.IDLE);
      Logger.info(this.TAG, 'Player reset');
    } catch (error) {
      Logger.error(this.TAG, `Failed to reset player: ${JSON.stringify(error)}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }

  /**
   * 检查播放器是否已初始化
   * @returns 是否已初始化
   */
  public isPlayerInitialized(): boolean {
    return this.isInitialized && this.avPlayer !== null;
  }

  /**
   * 获取播放器实�?   * @returns AVPlayer实例
   */
  public getPlayer(): media.AVPlayer | null {
    return this.avPlayer;
  }
}
