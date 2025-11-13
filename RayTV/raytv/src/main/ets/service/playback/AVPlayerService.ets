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
  // 定义每种事件类型的回调接口
  private stateChangeListeners: ((state: string, reason: number) => void)[] = [];
  private errorListeners: ((errorCode: number, errorMsg: string) => void)[] = [];
  private bufferListeners: ((bufferingRate: number) => void)[] = [];
  private completeListeners: (() => void)[] = [];
  private timeUpdateListeners: ((currentTime: number) => void)[] = [];

  async createPlayer(): Promise<RealPlayer> {
    try {
      // 创建AVPlayer实例
      this.avPlayer = await media.createAVPlayer();
      
      // 设置播放器回调
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
      
      // 设置播放源
      await this.avPlayer.setSource(source);
      Logger.info('RealPlayer', `Source set: ${source}`);
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
      
      // 准备播放器
      await this.avPlayer.prepare();
      Logger.info('RealPlayer', 'Player prepared');
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
      
      // 开始播放
      await this.avPlayer.play();
      Logger.info('RealPlayer', 'Player started');
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
      Logger.info('RealPlayer', 'Player paused');
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
      Logger.info('RealPlayer', 'Player stopped');
    } catch (error) {
      Logger.error('RealPlayer', `Failed to stop: ${error}`);
      throw error;
    }
  }

  async seek(timeMs: number, mode: media.SeekMode = media.SeekMode.SEEK_PREV_SYNC): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not created');
      }
      
      // 跳转到指定位置
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
      Logger.info('RealPlayer', `Volume set to: ${volume}`);
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
      Logger.info('RealPlayer', `Mute set to: ${mute}`);
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
      Logger.info('RealPlayer', `Speed set to: ${speed}`);
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
      Logger.error('RealPlayer', `Failed to get current time: ${error}`);
      return this.currentTime;
    }
  }

  async getDuration(): Promise<number> {
    try {
      if (!this.avPlayer) {
        return 0;
      }
      
      // 获取总时长
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
        // 释放播放器资源
        await this.avPlayer.release();
        this.avPlayer = null;
        Logger.info('RealPlayer', 'Player released');
      }
    } catch (error) {
      Logger.error('RealPlayer', `Failed to release player: ${error}`);
      throw error;
    }
  }

  // 重载on方法，为每种事件类型提供类型安全的接口
  on(event: 'stateChange', callback: (state: string, reason: number) => void): void;
  on(event: 'error', callback: (errorCode: number, errorMsg: string) => void): void;
  on(event: 'bufferingChange', callback: (bufferingRate: number) => void): void;
  on(event: 'playbackComplete', callback: () => void): void;
  on(event: 'timeUpdate', callback: (currentTime: number) => void): void;
  // 作为类型系统的兼容层，处理可能的未知事件类型
  on(event: string, callback: (...args: unknown[]) => void): void {
    // 根据事件类型存储对应的回调函数
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

  // 重载emit方法，为每种事件类型提供类型安全的接口
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
  private emit(event: string, ...args: unknown[]): void {
    // 这个通用实现实际上不会被调用，因为我们已经为所有事件类型提供了具体实现
    // 这里仅作为类型系统的兼容层
  }

  private setupPlayerCallbacks(): void {
    if (!this.avPlayer) return;

    // 状态变化回调
    this.avPlayer.on('stateChange', (state: string, reason: number) => {
      Logger.info('RealPlayer', `Player state changed: ${state}, reason: ${reason}`);
      this.emit('stateChange', state, reason);
    });

    // 错误回调
    this.avPlayer.on('error', (error: media.AVPlayerError) => {
      Logger.error('RealPlayer', `Player error: ${error.code}, message: ${error.message}`);
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
 * 播放状态枚举
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
  
  // 设置播放源
  setSource(source: string): Promise<void>;
  
  // 准备播放
  prepare(): Promise<void>;
  
  // 开始播放
  play(): Promise<void>;
  
  // 暂停播放
  pause(): Promise<void>;
  
  // 停止播放
  stop(): Promise<void>;
  
  // 跳转到指定位置
  seekTo(timeMs: number): Promise<void>;
  
  // 设置音量
  setVolume(volume: number): Promise<void>;
  
  // 设置静音
  setMute(mute: boolean): Promise<void>;
  
  // 设置播放速度
  setSpeed(speed: PlaybackSpeed): Promise<void>;
  
  // 获取当前播放位置
  getCurrentTime(): Promise<number>;
  
  // 获取总时长
  getDuration(): Promise<number>;
  
  // 获取播放状态
  getStatus(): PlaybackStatus;
  
  // 设置播放状态监听器
  onStatusChange(callback: (status: PlaybackStatus) => void): void;
  
  // 设置错误监听器
  onError(callback: (error: Error) => void): void;
  
  // 设置缓冲状态监听器
  onBufferUpdate(callback: (bufferingRate: number) => void): void;
  
  // 释放播放器资源
  release(): Promise<void>;
}

/**
 * AVPlayerService实现类
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
      // 创建真实播放器实例
      this.avPlayer = new RealPlayer();
      await this.avPlayer.createPlayer();
      
      // 设置状态监听
      this.setupPlayerListeners();
      
      this.updateStatus(PlaybackStatus.IDLE);
      Logger.info(this.TAG, 'AVPlayer initialized');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize AVPlayer: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置播放源
   */
  public async setSource(source: string): Promise<void> {
    try {
      if (!this.avPlayer) {
        await this.init();
      }
      
      this.sourceUrl = source;
      await this.avPlayer.setSource(source);
      this.updateStatus(PlaybackStatus.INITIALIZED);
      Logger.info(this.TAG, `Source set: ${source}`);
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
      Logger.error(this.TAG, `Failed to prepare: ${error}`);
      this.updateStatus(PlaybackStatus.ERROR);
      throw error;
    }
  }
  
  /**
   * 开始播放
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
      Logger.info(this.TAG, 'Playback paused');
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
      Logger.info(this.TAG, 'Playback stopped');
    } catch (error) {
      Logger.error(this.TAG, `Failed to stop: ${error}`);
      throw error;
    }
  }
  
  /**
   * 跳转到指定位置
   */
  public async seekTo(timeMs: number): Promise<void> {
    try {
      if (!this.avPlayer) {
        throw new Error('Player not initialized');
      }
      
      await this.avPlayer.seek(timeMs, media.SeekMode.SEEK_PREV_SYNC);
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
      
      // 确保音量在0-1之间
      const normalizedVolume = Math.max(0, Math.min(1, volume));
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
      Logger.info(this.TAG, `Mute set to: ${mute}`);
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
      Logger.info(this.TAG, `Playback speed set to: ${speed}`);
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
      Logger.error(this.TAG, `Failed to get current time: ${error}`);
      return 0;
    }
  }
  
  /**
   * 获取总时长
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
   * 获取播放状态
   */
  public getStatus(): PlaybackStatus {
    return this.currentStatus;
  }
  
  /**
   * 设置播放状态监听器
   */
  public onStatusChange(callback: (status: PlaybackStatus) => void): void {
    this.statusChangeCallback = callback;
    // 立即回调当前状态
    callback(this.currentStatus);
  }
  
  /**
   * 设置错误监听器
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
   * 释放播放器资源
   */
  public async release(): Promise<void> {
    try {
      if (this.avPlayer) {
        await this.avPlayer.release();
        this.avPlayer = null;
        this.updateStatus(PlaybackStatus.IDLE);
        Logger.info(this.TAG, 'Player released');
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
    
    // 状态变化监听
    this.avPlayer.on('stateChange', (state: string, reason: number) => {
      Logger.info(this.TAG, `Player state changed: ${state}, reason: ${reason}`);
      
      // 根据HarmonyOS AVPlayer状态映射到应用状态
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
      Logger.error(this.TAG, `Player error: ${errorCode}, message: ${errorMsg}`);
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