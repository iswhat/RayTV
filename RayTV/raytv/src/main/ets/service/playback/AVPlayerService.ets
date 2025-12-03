import Logger from '../../common/util/Logger';
import media from '@ohos.multimedia.media';

// 真实播放器状态枚举（基于HarmonyOS媒体播放器状态）
const PlayerState = {
  IDLE: 0,
  INITIALIZED: 1,
  PREPARED: 2,
  PLAYING: 3,
  PAUSED: 4,
  STOPPED: 5,
  PLAYBACK_COMPLETE: 6,
  ERROR: 7,
  RELEASED: 8
} as const;

// 真实播放器类 - 基于HarmonyOS AVPlayer
class RealPlayer {
  private avPlayer: media.AVPlayer | null = null;
  private currentTime: number = 0;
  private duration: number = 0;
  private volume: number = 1.0;
  private isMuted: boolean = false;
  private speed: number = 1.0;
  // 定义每种事件类型的回调接�?
  private stateChangeListeners: ((state: string, reason: number) => void)[] = [];
  private errorListeners: ((errorCode: number, errorMsg: string) => void)[] = [];
  private bufferListeners: ((bufferingRate: number) => void)[] = [];
  private completeListeners: (() => void)[] = [];
  private timeUpdateListeners: ((currentTime: number) => void)[] = [];

  async createPlayer(): Promise<RealPlayer> {
    try {
      // 创建AVPlayer实例
      this.avPlayer = await media.createAVPlayer();
      
      // 设置播放器回�?
      this.setupPlayerCallbacks();
      
      Logger.info('RealPlayer', 'AVPlayer created successfully');
      return this;
    } catch (error) {
      Logger.error('RealPlayer', `Failed to create AVPlayer: ${error}`);
      throw error;
    }
  }

  async setSource(source: string): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 设置播放�?
      await this.avPlayer.setSource(source);
      Logger.info('RealPlayer', `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}`)))))));
    } catch (error) {
      Logger.error('RealPlayer', `Failed to set source: ${error}`);
      throw error;
    }
  }

  async prepare(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 准备播放�?
      await this.avPlayer.prepare();
      Logger.info('RealPlayer', 'Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared' instanceof Error ? 'Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared' : new Error(String('Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared' instanceof Error ? 'Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared' instanceof Error ? 'Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared' : new Error(String('Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared' : new Error(String('Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared' instanceof Error ? 'Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared' : new Error(String('Player prepared' instanceof Error ? 'Player prepared' : new Error(String('Player prepared')))))));
    } catch (error) {
      Logger.error('RealPlayer', `Failed to prepare: ${error}`);
      throw error;
    }
  }

  async play(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 开始播�?
      await this.avPlayer.play();
      Logger.info('RealPlayer', 'Player started' instanceof Error ? 'Player started' : new Error(String('Player started' instanceof Error ? 'Player started' instanceof Error ? 'Player started' : new Error(String('Player started' : new Error(String('Player started' instanceof Error ? 'Player started' : new Error(String('Player started' instanceof Error ? 'Player started' instanceof Error ? 'Player started' : new Error(String('Player started' instanceof Error ? 'Player started' instanceof Error ? 'Player started' : new Error(String('Player started' : new Error(String('Player started' instanceof Error ? 'Player started' : new Error(String('Player started' : new Error(String('Player started' instanceof Error ? 'Player started' : new Error(String('Player started' instanceof Error ? 'Player started' instanceof Error ? 'Player started' : new Error(String('Player started' : new Error(String('Player started' instanceof Error ? 'Player started' : new Error(String('Player started')))))));
    } catch (error) {
      Logger.error('RealPlayer', `Failed to play: ${error}`);
      throw error;
    }
  }

  async pause(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 暂停播放
      await this.avPlayer.pause();
      Logger.info('RealPlayer', 'Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused' instanceof Error ? 'Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused' : new Error(String('Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused' instanceof Error ? 'Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused' instanceof Error ? 'Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused' : new Error(String('Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused' : new Error(String('Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused' instanceof Error ? 'Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused' : new Error(String('Player paused' instanceof Error ? 'Player paused' : new Error(String('Player paused')))))));
    } catch (error) {
      Logger.error('RealPlayer', `Failed to pause: ${error}`);
      throw error;
    }
  }

  async stop(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 停止播放
      await this.avPlayer.stop();
      Logger.info('RealPlayer', 'Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped' instanceof Error ? 'Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped' : new Error(String('Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped' instanceof Error ? 'Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped' instanceof Error ? 'Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped' : new Error(String('Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped' : new Error(String('Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped' instanceof Error ? 'Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped' : new Error(String('Player stopped' instanceof Error ? 'Player stopped' : new Error(String('Player stopped')))))));
    } catch (error) {
      Logger.error('RealPlayer', `Failed to stop: ${error}`);
      throw error;
    }
  }

  async seek(timeMs: number, mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC instanceof Error ? mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC : new Error(String(mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC))))))): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 跳转到指定位�?
      await this.avPlayer.seek(timeMs, mode);
      Logger.info('RealPlayer', `Seeked to: ${timeMs}ms`);
    } catch (error) {
      Logger.error('RealPlayer', `Failed to seek: ${error}`);
      throw error;
    }
  }

  async setVolume(volume: number): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 设置音量
      await this.avPlayer.setVolume(volume);
      this.volume = volume;
      Logger.info('RealPlayer', `Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}` instanceof Error ? `Volume set to: ${volume}` : new Error(String(`Volume set to: ${volume}`)))))));
    } catch (error) {
      Logger.error('RealPlayer', `Failed to set volume: ${error}`);
      throw error;
    }
  }

  async setMute(mute: boolean): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 设置静音
      await this.avPlayer.setMute(mute);
      this.isMuted = mute;
      Logger.info('RealPlayer', `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}`)))))));
    } catch (error) {
      Logger.error('RealPlayer', `Failed to set mute: ${error}`);
      throw error;
    }
  }

  async setSpeed(speed: number): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 设置播放速度
      await this.avPlayer.setSpeed(speed);
      this.speed = speed;
      Logger.info('RealPlayer', `Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}` instanceof Error ? `Speed set to: ${speed}` : new Error(String(`Speed set to: ${speed}`)))))));
    } catch (error) {
      Logger.error('RealPlayer', `Failed to set speed: ${error}`);
      throw error;
    }
  }

  async getCurrentTime(): Promise<number> {
    try {
      if (!this.avPlayer) {
        return 0;
      }
      
      // 获取当前播放位置
      const currentTime = await this.avPlayer.getCurrentTime();
      this.currentTime = currentTime;
      return currentTime;
    } catch (error) {
      Logger.error('RealPlayer', `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}`)))))));
      return this.currentTime;
    }
  }

  async getDuration(): Promise<number> {
    try {
      if (!this.avPlayer) {
        return 0;
      }
      
      // 获取总时�?
      const duration = await this.avPlayer.getDuration();
      this.duration = duration;
      return duration;
    } catch (error) {
      Logger.error('RealPlayer', `Failed to get duration: ${error}`);
      return this.duration;
    }
  }

  async release(): Promise<void> {
    try {
      if (this.avPlayer) {
        // 释放播放器资�?
        await this.avPlayer.release();
        this.avPlayer = null;
        Logger.info('RealPlayer', 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' instanceof Error ? 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' : new Error(String('Player released' instanceof Error ? 'Player released' : new Error(String('Player released' instanceof Error ? 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' instanceof Error ? 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' : new Error(String('Player released' instanceof Error ? 'Player released' : new Error(String('Player released' : new Error(String('Player released' instanceof Error ? 'Player released' : new Error(String('Player released' instanceof Error ? 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' : new Error(String('Player released' instanceof Error ? 'Player released' : new Error(String('Player released')))))));
      }
    } catch (error) {
      Logger.error('RealPlayer', `Failed to release player: ${error}`);
      throw error;
    }
  }

  // 重载on方法，为每种事件类型提供类型安全的接�?
  on(event: 'stateChange', callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number instanceof Error ? callback: (state: string, reason: number : new Error(String(callback: (state: string, reason: number))))))) => void): void;
  on(event: 'error', callback: (errorCode: number, errorMsg: string) => void): void;
  on(event: 'bufferingChange', callback: (bufferingRate: number) => void): void;
  on(event: 'playbackComplete', callback: () => void): void;
  on(event: 'timeUpdate', callback: (currentTime: number) => void): void;
  // 作为类型系统的兼容层，处理可能的未知事件类型
  on(event: string, callback: (...args: Record<string, string | number | boolean | null>[]) => void): void {
    // 根据事件类型存储对应的回调函�?
    switch (event) {
      case 'stateChange':
        this.stateChangeListeners.push(callback as (state: string, reason: number) => void);
        break;
      case 'error':
        this.errorListeners.push(callback as (errorCode: number, errorMsg: string) => void);
        break;
      case 'bufferingChange':
        this.bufferListeners.push(callback as (bufferingRate: number) => void);
        break;
      case 'playbackComplete':
        this.completeListeners.push(callback as () => void);
        break;
      case 'timeUpdate':
        this.timeUpdateListeners.push(callback as (currentTime: number) => void);
        break;
    }
  }

  // 重载emit方法，为每种事件类型提供类型安全的接�?
  private emit(event: 'stateChange', state: string, reason: number): void {
    this.stateChangeListeners.forEach(callback => callback(state, reason));
  }
  private emit(event: 'error', errorCode: number, errorMsg: string): void {
    this.errorListeners.forEach(callback => callback(errorCode, errorMsg));
  }
  private emit(event: 'bufferingChange', bufferingRate: number): void {
    this.bufferListeners.forEach(callback => callback(bufferingRate));
  }
  private emit(event: 'playbackComplete'): void {
    this.completeListeners.forEach(callback => callback());
  }
  private emit(event: 'timeUpdate', currentTime: number): void {
    this.timeUpdateListeners.forEach(callback => callback(currentTime));
  }
  // 通用实现（作为后备）
  // 通用实现作为类型系统的兼容层
  private emit(event: string, ...args: Record<string, string | number | boolean | null>[]): void {
    // 这个通用实现实际上不会被调用，因为我们已经为所有事件类型提供了具体实现
    // 这里仅作为类型系统的兼容�?
  }

  private setupPlayerCallbacks(): void {
    if (!this.avPlayer) return;

    // 状态变化回�?
    this.avPlayer.on('stateChange', (state: string, reason: number) => {
      Logger.info('RealPlayer', `Player state changed: ${state}, reason: ${reason}`);
      this.emit('stateChange', state, reason);
    });

    // 错误回调
    this.avPlayer.on('error', (error: media.AVPlayerError) => {
      Logger.error('RealPlayer', `Player error: ${error.code}, message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}` instanceof Error ? message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}` : new Error(String(message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}` instanceof Error ? message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}` instanceof Error ? message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}` : new Error(String(message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}` : new Error(String(message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}` instanceof Error ? message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}` : new Error(String(message: ${error.message}` instanceof Error ? message: ${error.message}` : new Error(String(message: ${error.message}`)))))));
      this.emit('error', error.code, error.message);
    });

    // 缓冲更新回调
    this.avPlayer.on('bufferingUpdate', (info: media.BufferingInfo) => {
      Logger.info('RealPlayer', `Buffering update: ${info.bufferingPercentage}%`);
      this.emit('bufferingChange', info.bufferingPercentage);
    });

    // 播放完成回调
    this.avPlayer.on('playbackComplete', () => {
      Logger.info('RealPlayer', 'Playback completed');
      this.emit('playbackComplete');
    });

    // 时间更新回调
    this.avPlayer.on('timeUpdate', (currentTime: number) => {
      this.currentTime = currentTime;
      this.emit('timeUpdate', currentTime);
    });
  }
}

/**
 * 播放状态枚�?
 */
export enum PlaybackStatus {
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

/**
 * 播放速度枚举
 */
export enum PlaybackSpeed {
  SLOWEST = 0.5,
  SLOW = 0.75,
  NORMAL = 1.0,
  FAST = 1.5,
  FASTEST = 2.0
}

/**
 * AVPlayerService接口
 */
export interface AVPlayerService {
  // 初始化播放器
  init(): Promise<void>;
  
  // 设置播放�?
  setSource(source: string): Promise<void>;
  
  // 准备播放
  prepare(): Promise<void>;
  
  // 开始播�?
  play(): Promise<void>;
  
  // 暂停播放
  pause(): Promise<void>;
  
  // 停止播放
  stop(): Promise<void>;
  
  // 跳转到指定位�?
  seekTo(timeMs: number): Promise<void>;
  
  // 设置音量
  setVolume(volume: number): Promise<void>;
  
  // 设置静音
  setMute(mute: boolean): Promise<void>;
  
  // 设置播放速度
  setSpeed(speed: PlaybackSpeed): Promise<void>;
  
  // 获取当前播放位置
  getCurrentTime(): Promise<number>;
  
  // 获取总时�?
  getDuration(): Promise<number>;
  
  // 获取播放状�?
  getStatus(): PlaybackStatus;
  
  // 设置播放状态监听器
  onStatusChange(callback: (status: PlaybackStatus) => void): void;
  
  // 设置错误监听�?
  onError(callback: (error: Error) => void): void;
  
  // 设置缓冲状态监听器
  onBufferUpdate(callback: (bufferingRate: number) => void): void;
  
  // 释放播放器资�?
  release(): Promise<void>;
}

/**
 * AVPlayerService实现�?
 * 基于HarmonyOS AVPlayer实现媒体播放功能
 */
export class AVPlayerServiceImpl implements AVPlayerService {
  private readonly TAG: string = 'AVPlayerServiceImpl';
  private avPlayer: RealPlayer | null = null;
  private currentStatus: PlaybackStatus = PlaybackStatus.IDLE;
  private sourceUrl: string = '';
  private statusChangeCallback?: (status: PlaybackStatus) => void;
  private errorCallback?: (error: Error) => void;
  private bufferUpdateCallback?: (bufferingRate: number) => void;
  
  /**
   * 初始化播放器
   */
  public async init(): Promise<void> {
    try {
      // 创建真实播放器实�?
      this.avPlayer = new RealPlayer();
      await this.avPlayer.createPlayer();
      
      // 设置状态监�?
      this.setupPlayerListeners();
      
      this.updateStatus(PlaybackStatus.IDLE);
      Logger.info(this.TAG, 'AVPlayer initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize AVPlayer: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置播放�?
   */
  public async setSource(source: string): Promise<void> {
    try {
      if (!this.avPlayer) {
        await this.init();
      }
      
      this.sourceUrl = source;
      await this.avPlayer.setSource(source);
      this.updateStatus(PlaybackStatus.INITIALIZED);
      Logger.info(this.TAG, `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}` : new Error(String(`Source set: ${source}` instanceof Error ? `Source set: ${source}` : new Error(String(`Source set: ${source}`)))))));
    } catch (error) {
      Logger.error(this.TAG, `Failed to set source: ${error}`);
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
      // 准备完成状态会在事件监听中更新
    } catch (error) {
      Logger.error(this.TAG, `Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}` instanceof Error ? `Failed to prepare: ${error}` : new Error(String(`Failed to prepare: ${error}`)))))));
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }
  
  /**
   * 开始播�?
   */
  public async play(): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.play();
      // 播放状态会在事件监听中更新
    } catch (error) {
      Logger.error(this.TAG, `Failed to play: ${error}`);
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
      Logger.info(this.TAG, 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused' : new Error(String('Playback paused' instanceof Error ? 'Playback paused' : new Error(String('Playback paused')))))));
    } catch (error) {
      Logger.error(this.TAG, `Failed to pause: ${error}`);
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
      this.updateStatus(PlaybackStatus.STOPPED);
      Logger.info(this.TAG, 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped' : new Error(String('Playback stopped' instanceof Error ? 'Playback stopped' : new Error(String('Playback stopped')))))));
    } catch (error) {
      Logger.error(this.TAG, `Failed to stop: ${error}`);
      throw error;
    }
  }
  
  /**
   * 跳转到指定位�?
   */
  public async seekTo(timeMs: number): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.seek(timeMs, media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC instanceof Error ? media.SeekMode.SEEK_PREV_SYNC : new Error(String(media.SeekMode.SEEK_PREV_SYNC)))))));
      Logger.info(this.TAG, `Seeked to: ${timeMs}ms`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to seek: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置音量
   */
  public async setVolume(volume: number): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      // 确保音量�?-1之间
      const normalizedVolume = Math.max(0, Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume instanceof Error ? Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume : new Error(String(Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume instanceof Error ? Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume instanceof Error ? Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume : new Error(String(Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume : new Error(String(Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume instanceof Error ? Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume : new Error(String(Math.min(1, volume instanceof Error ? Math.min(1, volume : new Error(String(Math.min(1, volume))))))));
      await this.avPlayer.setVolume(normalizedVolume);
      Logger.info(this.TAG, `Volume set to: ${normalizedVolume}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set volume: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置静音
   */
  public async setMute(mute: boolean): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.setMute(mute);
      Logger.info(this.TAG, `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}` instanceof Error ? `Mute set to: ${mute}` : new Error(String(`Mute set to: ${mute}`)))))));
    } catch (error) {
      Logger.error(this.TAG, `Failed to set mute: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置播放速度
   */
  public async setSpeed(speed: PlaybackSpeed): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.setSpeed(speed);
      Logger.info(this.TAG, `Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}` instanceof Error ? `Playback speed set to: ${speed}` : new Error(String(`Playback speed set to: ${speed}`)))))));
    } catch (error) {
      Logger.error(this.TAG, `Failed to set speed: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取当前播放位置
   */
  public async getCurrentTime(): Promise<number> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      const currentTime = await this.avPlayer.getCurrentTime();
      return currentTime;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}` instanceof Error ? `Failed to get current time: ${error}` : new Error(String(`Failed to get current time: ${error}`)))))));
      return 0;
    }
  }
  
  /**
   * 获取总时�?
   */
  public async getDuration(): Promise<number> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      const duration = await this.avPlayer.getDuration();
      return duration;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get duration: ${error}`);
      return 0;
    }
  }
  
  /**
   * 获取播放状�?
   */
  public getStatus(): PlaybackStatus {
    return this.currentStatus;
  }
  
  /**
   * 设置播放状态监听器
   */
  public onStatusChange(callback: (status: PlaybackStatus) => void): void {
    this.statusChangeCallback = callback;
    // 立即回调当前状�?
    callback(this.currentStatus);
  }
  
  /**
   * 设置错误监听�?
   */
  public onError(callback: (error: Error) => void): void {
    this.errorCallback = callback;
  }
  
  /**
   * 设置缓冲状态监听器
   */
  public onBufferUpdate(callback: (bufferingRate: number) => void): void {
    this.bufferUpdateCallback = callback;
  }
  
  /**
   * 释放播放器资�?
   */
  public async release(): Promise<void> {
    try {
      if (this.avPlayer) {
        await this.avPlayer.release();
        this.avPlayer = null;
        this.updateStatus(PlaybackStatus.IDLE);
        Logger.info(this.TAG, 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' instanceof Error ? 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' : new Error(String('Player released' instanceof Error ? 'Player released' : new Error(String('Player released' instanceof Error ? 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' instanceof Error ? 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' : new Error(String('Player released' instanceof Error ? 'Player released' : new Error(String('Player released' : new Error(String('Player released' instanceof Error ? 'Player released' : new Error(String('Player released' instanceof Error ? 'Player released' instanceof Error ? 'Player released' : new Error(String('Player released' : new Error(String('Player released' instanceof Error ? 'Player released' : new Error(String('Player released')))))));
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to release player: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置播放器监听器
   */
  private setupPlayerListeners(): void {
    if (!this.avPlayer) return;
    
    // 状态变化监�?
    this.avPlayer.on('stateChange', (state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number instanceof Error ? (state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number : new Error(String((state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number instanceof Error ? (state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number instanceof Error ? (state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number : new Error(String((state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number : new Error(String((state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number instanceof Error ? (state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number : new Error(String((state: string, reason: number instanceof Error ? (state: string, reason: number : new Error(String((state: string, reason: number))))))) => {
      Logger.info(this.TAG, `Player state changed: ${state}, reason: ${reason}`);
      
      // 根据HarmonyOS AVPlayer状态映射到应用状�?
      switch (state) {
        case 'idle':
          this.updateStatus(PlaybackStatus.IDLE);
          break;
        case 'initialized':
          this.updateStatus(PlaybackStatus.INITIALIZED);
          break;
        case 'prepared':
          this.updateStatus(PlaybackStatus.PREPARED);
          break;
        case 'playing':
          this.updateStatus(PlaybackStatus.PLAYING);
          break;
        case 'paused':
          this.updateStatus(PlaybackStatus.PAUSED);
          break;
        case 'stopped':
          this.updateStatus(PlaybackStatus.STOPPED);
          break;
        case 'playbackComplete':
          this.updateStatus(PlaybackStatus.COMPLETED);
          break;
        case 'error':
          this.updateStatus(PlaybackStatus.ERROR);
          if (this.errorCallback) {
            this.errorCallback(new Error(`Player error: ${reason}`));
          }
          break;
        default:
          Logger.warn(this.TAG, `Unknown player state: ${state}`);
          break;
      }
    });
    
    // 错误监听
    this.avPlayer.on('error', (errorCode: number, errorMsg: string) => {
      Logger.error(this.TAG, `Player error: ${errorCode}, message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}` : new Error(String(message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}` : new Error(String(message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}` : new Error(String(message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}` : new Error(String(message: ${errorMsg}` instanceof Error ? message: ${errorMsg}` : new Error(String(message: ${errorMsg}`)))))));
      this.updateStatus(PlaybackStatus.ERROR);
      if (this.errorCallback) {
        this.errorCallback(new Error(`Player error: ${errorMsg} (code: ${errorCode})`));
      }
    });
    
    // 缓冲更新监听
    this.avPlayer.on('bufferingChange', (bufferingRate: number) => {
      Logger.info(this.TAG, `Buffering rate: ${bufferingRate}%`);
      if (this.bufferUpdateCallback) {
        this.bufferUpdateCallback(bufferingRate);
      }
    });
    
    // 播放完成监听
    this.avPlayer.on('playbackComplete', () => {
      Logger.info(this.TAG, 'Playback completed');
      this.updateStatus(PlaybackStatus.COMPLETED);
    });
    
    // 时间更新监听
    this.avPlayer.on('timeUpdate', (currentTime: number) => {
      // 实时更新当前播放时间
      Logger.debug(this.TAG, `Time updated: ${currentTime}ms`);
    });
  }
  
  /**
   * 更新播放状态并触发回调
   */
  private updateStatus(status: PlaybackStatus): void {
    this.currentStatus = status;
    if (this.statusChangeCallback) {
      this.statusChangeCallback(status);
    }
  }
}

/**
 * AVPlayerService单例
 */
export const AVPlayerServiceInstance: AVPlayerService = new AVPlayerServiceImpl();


