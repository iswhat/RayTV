import Logger from '../../common/util/Logger';
import AVPlay from '@ohos.multimedia.media';
import BusinessError from '@ohos.base';
import { PlaybackState, PlaybackErrorType, PlaybackError, PlaybackItem } from './PlaybackService';

// 常量定义 | Constants
const TAG = 'PlaybackErrorHandler';
const MAX_RETRY_COUNT = 3; // 最大重试次数 | Maximum retry count
const MIN_RETRY_INTERVAL = 3000; // 最小重试间隔 | Minimum retry interval

export default class PlaybackErrorHandler {
  private avPlayInstance: AVPlay | null = null;
  private currentPlaybackItem: PlaybackItem | null = null;
  private retryCount: number = 0;
  private lastPosition: number = 0;
  private autoPlay: boolean = true;
  private enableHardwareDecoding: boolean = true;
  private errorListeners: ((error: PlaybackError) => void)[] = [];
  private stateUpdateCallback: ((state: PlaybackState) => void) | null = null;
  private createAVPlayInstanceCallback: (() => Promise<void>) | null = null;
  private savePlaybackPositionCallback: (() => Promise<void>) | null = null;

  /**
   * 构造函数 | Constructor
   */
  constructor() {
    // 初始化错误处理器
  }

  /**
   * 设置依赖项 | Set dependencies
   */
  public setDependencies(
    avPlayInstance: AVPlay | null,
    currentPlaybackItem: PlaybackItem | null,
    lastPosition: number,
    autoPlay: boolean,
    enableHardwareDecoding: boolean,
    errorListeners: ((error: PlaybackError) => void)[],
    stateUpdateCallback: ((state: PlaybackState) => void) | null,
    createAVPlayInstanceCallback: (() => Promise<void>) | null,
    savePlaybackPositionCallback: (() => Promise<void>) | null
  ): void {
    this.avPlayInstance = avPlayInstance;
    this.currentPlaybackItem = currentPlaybackItem;
    this.lastPosition = lastPosition;
    this.autoPlay = autoPlay;
    this.enableHardwareDecoding = enableHardwareDecoding;
    this.errorListeners = errorListeners;
    this.stateUpdateCallback = stateUpdateCallback;
    this.createAVPlayInstanceCallback = createAVPlayInstanceCallback;
    this.savePlaybackPositionCallback = savePlaybackPositionCallback;
  }

  /**
   * 处理播放错误 | Handles playback error
   */
  public async handlePlaybackError(error: BusinessError): Promise<void> {
    Logger.error(TAG, `Playback error occurred: ${JSON.stringify(error)}`);
    
    // 识别错误类型 | Identify error type
    const errorType = this.determineErrorType(error);
    
    // 构建错误对象 | Build error object
    const playbackError = this.buildPlaybackError(error, errorType);
    
    // 通知错误监听器并更新状态 | Notify error listeners and update state
    this.notifyErrorAndUpdateState(playbackError);
    
    // 尝试自动恢复 | Attempt auto recovery
    await this.attemptErrorRecoveryWithFallback(errorType);
  }

  /**
   * 构建播放错误对象 | Builds playback error object
   */
  private buildPlaybackError(error: BusinessError, errorType: PlaybackErrorType): PlaybackError {
    return {
      code: error.code || -1, 
      message: error.message || 'Unknown error',
      type: errorType,
      details: error
    };
  }

  /**
   * 通知错误监听器并更新状态 | Notifies error listeners and updates state
   */
  private notifyErrorAndUpdateState(error: PlaybackError): void {
    // 通知错误监听器 | Notify error listeners
    this.notifyErrorListeners(error);
    
    // 更新播放状态 | Update playback state
    this.updatePlaybackState(PlaybackState.ERROR);
  }

  /**
   * 尝试错误恢复并处理失败情况 | Attempts error recovery and handles fallback
   */
  private async attemptErrorRecoveryWithFallback(errorType: PlaybackErrorType): Promise<void> {
    if (await this.attemptErrorRecovery(errorType)) {
      Logger.info(TAG, 'Successfully recovered from playback error');
    } else {
      Logger.warn(TAG, 'Failed to recover from playback error, giving up');
      // 保存播放位置以便后续恢复 | Save playback position for later recovery
      await this.savePlaybackPosition();
    }
  }

  /**
   * 确定错误类型 | Determines error type
   */
  private determineErrorType(error: BusinessError): PlaybackErrorType {
    const errorCode = error.code || 0;
    const errorMessage = (error.message || '').toLowerCase();
    
    // 基于错误码和错误信息确定错误类型 | Determine error type based on error code and message
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
   * 尝试错误恢复 | Attempts error recovery
   */
  private async attemptErrorRecovery(errorType: PlaybackErrorType): Promise<boolean> {
    // 检查重试次数是否超过 | Check if retry count exceeded
    if (this.retryCount >= MAX_RETRY_COUNT) {
      Logger.warn(TAG, `Max retry count (${MAX_RETRY_COUNT}) reached`);
      return false;
    }
    
    // 增加重试次数 | Increase retry count
    this.retryCount++;
    Logger.info(TAG, `Attempting to recover from error, retry ${this.retryCount}/${MAX_RETRY_COUNT}`);
    
    try {
      // 等待一段时间再重试 | Wait for some time before retry
      await new Promise(resolve => setTimeout(resolve, MIN_RETRY_INTERVAL * this.retryCount));
      
      switch (errorType) {
        case PlaybackErrorType.NETWORK:
          // 网络错误：重新加载资源 | Network error: reload resource
          return await this.recoverFromNetworkError();
          
        case PlaybackErrorType.DECODE:
          // 解码错误：切换解码模式后重新加载 | Decode error: switch decoding mode and reload
          return await this.recoverFromDecodeError();
          
        case PlaybackErrorType.TIMEOUT:
          // 超时错误：重新连接 | Timeout error: reconnect
          return await this.recoverFromTimeoutError();
          
        default:
          // 其他错误：尝试重新加载 | Other errors: try to reload
          return await this.recoverFromGenericError();
      }
    } catch (error) {
      Logger.error(TAG, `Recovery attempt failed: ${error}`);
      return false;
    }
  }

  /**
   * 从网络错误恢复 | Recovers from network error
   */
  private async recoverFromNetworkError(): Promise<boolean> {
    if (!this.currentPlaybackItem) return false;
    
    try {
      Logger.info(TAG, 'Recovering from network error');
      
      // 重新创建播放实例并设置数据源 | Recreate playback instance and set data source
      if (!await this.recreatePlaybackInstance(this.currentPlaybackItem.url)) {
        return false;
      }
      
      // 恢复播放状态和位置 | Resume playback state and position
      await this.resumePlaybackState();
      
      return true;
    } catch (error: unknown) {
      Logger.error(TAG, `Failed to recover from network error: ${error}`);
      return false;
    }
  }

  /**
   * 重新创建播放实例并设置数据源 | Recreates playback instance and sets data source
   */
  private async recreatePlaybackInstance(url: string): Promise<boolean> {
    // 重新创建播放实例 | Recreate playback instance
    if (this.createAVPlayInstanceCallback) {
      await this.createAVPlayInstanceCallback();
    } else {
      return false;
    }
    
    if (!this.avPlayInstance) return false;
    
    // 重新设置数据源 | Reset data source
    await this.avPlayInstance.setSource(url);
    await this.avPlayInstance.prepare();
    
    return true;
  }

  /**
   * 恢复播放状态和位置 | Resumes playback state and position
   */
  private async resumePlaybackState(): Promise<void> {
    if (!this.avPlayInstance) return;
    
    // 恢复到上次播放位置 | Resume to last playback position
    if (this.lastPosition > 0) {
      await this.avPlayInstance.seekTo(this.lastPosition);
    }
    
    // 恢复播放 | Resume playback
    if (this.autoPlay) {
      await this.avPlayInstance.play();
      this.updatePlaybackState(PlaybackState.PLAYING);
    }
  }

  /**
   * 从解码错误恢复 | Recovers from decode error
   */
  private async recoverFromDecodeError(): Promise<boolean> {
    if (!this.currentPlaybackItem) return false;
    
    try {
      Logger.info(TAG, 'Recovering from decode error');
      
      // 如果当前使用硬件解码，尝试切换到软件解码 | If current using hardware decoding, try switching to software decoding
      if (this.enableHardwareDecoding) {
        Logger.info(TAG, 'Switching from hardware to software decoding');
        // 注意：这里需要通过回调更新外部的enableHardwareDecoding值
        
        // 重新创建播放实例 | Recreate playback instance
        if (this.createAVPlayInstanceCallback) {
          await this.createAVPlayInstanceCallback();
        } else {
          return false;
        }
        
        if (!this.avPlayInstance) return false;
        
        // 重新设置数据源 | Reset data source
        await this.avPlayInstance.setSource(this.currentPlaybackItem.url);
        await this.avPlayInstance.prepare();
        
        // 恢复到上次播放位置 | Resume to last playback position
        if (this.lastPosition > 0) {
          await this.avPlayInstance.seekTo(this.lastPosition);
        }
        
        // 恢复播放 | Resume playback
        if (this.autoPlay) {
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
   * 从超时错误恢复 | Recovers from timeout error
   */
  private async recoverFromTimeoutError(): Promise<boolean> {
    // 超时错误处理，类似于网络错误 | Timeout error handling, similar to network error
    return await this.recoverFromNetworkError();
  }

  /**
   * 从一般错误恢复 | Recovers from generic error
   */
  private async recoverFromGenericError(): Promise<boolean> {
    if (!this.currentPlaybackItem) return false;
    
    try {
      Logger.info(TAG, 'Attempting generic error recovery');
      // 重新创建播放实例 | Recreate playback instance
      if (this.createAVPlayInstanceCallback) {
        await this.createAVPlayInstanceCallback();
      } else {
        return false;
      }
      
      if (!this.avPlayInstance) return false;
      
      // 重新设置数据源 | Reset data source
      await this.avPlayInstance.setSource(this.currentPlaybackItem.url);
      await this.avPlayInstance.prepare();
      
      // 恢复到上次播放位置 | Resume to last playback position
      if (this.lastPosition > 0) {
        await this.avPlayInstance.seekTo(this.lastPosition);
      }
      
      // 恢复播放 | Resume playback
      if (this.autoPlay) {
        await this.avPlayInstance.play();
        this.updatePlaybackState(PlaybackState.PLAYING);
      }
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Generic error recovery failed: ${error}`);
      return false;
    }
  }

  /**
   * 保存播放位置 | Saves playback position
   */
  private async savePlaybackPosition(): Promise<void> {
    try {
      if (this.savePlaybackPositionCallback) {
        await this.savePlaybackPositionCallback();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save playback position: ${error}`);
    }
  }

  /**
   * 通知错误监听器 | Notifies error listeners
   */
  private notifyErrorListeners(error: PlaybackError): void {
    this.errorListeners.forEach(listener => listener(error));
  }

  /**
   * 更新播放状态 | Updates playback state
   */
  private updatePlaybackState(state: PlaybackState): void {
    if (this.stateUpdateCallback) {
      this.stateUpdateCallback(state);
    }
  }

  /**
   * 重置重试计数 | Resets retry count
   */
  public resetRetryCount(): void {
    this.retryCount = 0;
  }

  /**
   * 获取当前重试计数 | Gets current retry count
   */
  public getRetryCount(): number {
    return this.retryCount;
  }

  /**
   * 设置重试计数 | Sets retry count
   */
  public setRetryCount(count: number): void {
    this.retryCount = count;
  }
}
