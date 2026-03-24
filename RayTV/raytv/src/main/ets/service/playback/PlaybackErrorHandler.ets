import Logger from '../../common/util/Logger';
import media from '@ohos.multimedia.media';
import { BusinessError } from '@ohos.base';
import { PlaybackState, PlaybackErrorType, PlaybackError, PlaybackItem } from './PlaybackService';

// 常量定义 | Constants
const TAG = 'PlaybackErrorHandler';
const MAX_RETRY_COUNT = 3;
const MIN_RETRY_INTERVAL = 3000;

export default class PlaybackErrorHandler {
  private avPlayInstance: media.AVPlayer | null = null;
  private currentPlaybackItem: PlaybackItem | null = null;
  private retryCount: number = 0;
  private lastPosition: number = 0;
  private autoPlay: boolean = true;
  private enableHardwareDecoding: boolean = true;
  private errorListeners: ((error: PlaybackError) => void)[] = [];
  private stateUpdateCallback: ((state: PlaybackState) => void) | null = null;
  private createAVPlayInstanceCallback: (() => Promise<void>) | null = null;
  private savePlaybackPositionCallback: (() => Promise<void>) | null = null;

  constructor() {}

  /**
   * 设置依赖项
   */
  public setDependencies(
    avPlayInstance: media.AVPlayer | null,
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
   * 处理播放错误
   */
  public async handlePlaybackError(error: BusinessError): Promise<void> {
    Logger.error(TAG, `Playback error occurred: ${JSON.stringify(error)}`);

    const errorType = this.determineErrorType(error);
    const playbackError = this.buildPlaybackError(error, errorType);
    this.notifyErrorAndUpdateState(playbackError);
    await this.attemptErrorRecoveryWithFallback(errorType);
  }

  private buildPlaybackError(error: BusinessError, errorType: PlaybackErrorType): PlaybackError {
    return {
      code: error.code ?? -1,
      message: error.message ?? 'Unknown error',
      type: errorType,
      details: { code: error.code ?? -1, message: error.message ?? '' }
    };
  }

  private notifyErrorAndUpdateState(error: PlaybackError): void {
    this.notifyErrorListeners(error);
    this.updatePlaybackState(PlaybackState.ERROR);
  }

  private async attemptErrorRecoveryWithFallback(errorType: PlaybackErrorType): Promise<void> {
    if (await this.attemptErrorRecovery(errorType)) {
      Logger.info(TAG, 'Successfully recovered from playback error');
    } else {
      Logger.warn(TAG, 'Failed to recover from playback error, giving up');
      await this.savePlaybackPosition();
    }
  }

  private determineErrorType(error: BusinessError): PlaybackErrorType {
    const errorMessage = (error.message ?? '').toLowerCase();

    if (errorMessage.includes('network') || errorMessage.includes('connect')) {
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

  private async delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }

  private async attemptErrorRecovery(errorType: PlaybackErrorType): Promise<boolean> {
    if (this.retryCount >= MAX_RETRY_COUNT) {
      Logger.warn(TAG, `Max retry count (${MAX_RETRY_COUNT}) reached`);
      return false;
    }

    this.retryCount++;
    Logger.info(TAG, `Attempting to recover from error, retry ${this.retryCount}/${MAX_RETRY_COUNT}`);

    try {
      await this.delay(MIN_RETRY_INTERVAL * this.retryCount);

      if (errorType === PlaybackErrorType.NETWORK) {
        return await this.recoverFromNetworkError();
      } else if (errorType === PlaybackErrorType.DECODE) {
        return await this.recoverFromDecodeError();
      } else if (errorType === PlaybackErrorType.TIMEOUT) {
        return await this.recoverFromTimeoutError();
      } else {
        return await this.recoverFromGenericError();
      }
    } catch (err) {
      Logger.error(TAG, `Recovery attempt failed: ${err}`);
      return false;
    }
  }

  private async recoverFromNetworkError(): Promise<boolean> {
    if (!this.currentPlaybackItem) {
      return false;
    }
    try {
      Logger.info(TAG, 'Recovering from network error');
      if (!await this.recreatePlaybackInstance(this.currentPlaybackItem.url)) {
        return false;
      }
      await this.resumePlaybackState();
      return true;
    } catch (err) {
      Logger.error(TAG, `Failed to recover from network error: ${err}`);
      return false;
    }
  }

  private async recreatePlaybackInstance(url: string): Promise<boolean> {
    if (this.createAVPlayInstanceCallback) {
      await this.createAVPlayInstanceCallback();
    } else {
      return false;
    }
    if (!this.avPlayInstance) {
      return false;
    }
    // AVPlayer 通过直接赋值 url 属性设置媒体源，然后调用 prepare
    this.avPlayInstance.url = url;
    await this.avPlayInstance.prepare();
    return true;
  }

  private async resumePlaybackState(): Promise<void> {
    if (!this.avPlayInstance) {
      return;
    }
    if (this.lastPosition > 0) {
      this.avPlayInstance.seek(this.lastPosition);
    }
    if (this.autoPlay) {
      await this.avPlayInstance.play();
      this.updatePlaybackState(PlaybackState.PLAYING);
    }
  }

  private async recoverFromDecodeError(): Promise<boolean> {
    if (!this.currentPlaybackItem) {
      return false;
    }
    try {
      Logger.info(TAG, 'Recovering from decode error');
      if (this.enableHardwareDecoding) {
        Logger.info(TAG, 'Switching from hardware to software decoding');
        if (this.createAVPlayInstanceCallback) {
          await this.createAVPlayInstanceCallback();
        } else {
          return false;
        }
        if (!this.avPlayInstance) {
          return false;
        }
        this.avPlayInstance.url = this.currentPlaybackItem.url;
        await this.avPlayInstance.prepare();
        if (this.lastPosition > 0) {
          this.avPlayInstance.seek(this.lastPosition);
        }
        if (this.autoPlay) {
          await this.avPlayInstance.play();
          this.updatePlaybackState(PlaybackState.PLAYING);
        }
        return true;
      }
      return false;
    } catch (err) {
      Logger.error(TAG, `Failed to recover from decode error: ${err}`);
      return false;
    }
  }

  private async recoverFromTimeoutError(): Promise<boolean> {
    return this.recoverFromNetworkError();
  }

  private async recoverFromGenericError(): Promise<boolean> {
    if (!this.currentPlaybackItem) {
      return false;
    }
    try {
      Logger.info(TAG, 'Attempting generic error recovery');
      if (this.createAVPlayInstanceCallback) {
        await this.createAVPlayInstanceCallback();
      } else {
        return false;
      }
      if (!this.avPlayInstance) {
        return false;
      }
      this.avPlayInstance.url = this.currentPlaybackItem.url;
      await this.avPlayInstance.prepare();
      if (this.lastPosition > 0) {
        this.avPlayInstance.seek(this.lastPosition);
      }
      if (this.autoPlay) {
        await this.avPlayInstance.play();
        this.updatePlaybackState(PlaybackState.PLAYING);
      }
      return true;
    } catch (err) {
      Logger.error(TAG, `Generic error recovery failed: ${err}`);
      return false;
    }
  }

  private async savePlaybackPosition(): Promise<void> {
    try {
      if (this.savePlaybackPositionCallback) {
        await this.savePlaybackPositionCallback();
      }
    } catch (err) {
      Logger.error(TAG, `Failed to save playback position: ${err}`);
    }
  }

  private notifyErrorListeners(error: PlaybackError): void {
    for (const listener of this.errorListeners) {
      listener(error);
    }
  }

  private updatePlaybackState(state: PlaybackState): void {
    if (this.stateUpdateCallback) {
      this.stateUpdateCallback(state);
    }
  }

  public resetRetryCount(): void {
    this.retryCount = 0;
  }

  public getRetryCount(): number {
    return this.retryCount;
  }

  public setRetryCount(count: number): void {
    this.retryCount = count;
  }
}
