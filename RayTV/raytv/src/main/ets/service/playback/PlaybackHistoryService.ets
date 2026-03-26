import Logger from '../../common/util/Logger';
import { ErrorHandler, ErrorType, ErrorSeverity } from '../../common/util/ErrorHandler';
import { PlaybackHistory, PlaybackProgress } from '../../pages/playback/types/PlaybackTypes';

// 播放历史记录服务 | Playback history service
export class PlaybackHistoryService {
  private static instance: PlaybackHistoryService;
  private readonly TAG: string = 'PlaybackHistoryService';
  private readonly STORAGE_KEY: string = 'playback_history';
  private readonly MAX_HISTORY_COUNT: number = 100;
  private readonly PROGRESS_THRESHOLD: number = 10; // 秒，小于这个值不记录进度
  private readonly PROGRESS_SAVE_INTERVAL: number = 5000; // 毫秒，保存进度间隔

  private errorHandler: ErrorHandler = ErrorHandler.getInstance();
  private historyCache: PlaybackHistory[] = [];
  private lastSaveTime: number = 0;

  private constructor() {
    this.loadHistoryFromStorage();
  }

  public static getInstance(): PlaybackHistoryService {
    if (!PlaybackHistoryService.instance) {
      PlaybackHistoryService.instance = new PlaybackHistoryService();
    }
    return PlaybackHistoryService.instance;
  }

  /**
   * 从存储加载历史记录 | Load history from storage
   */
  private async loadHistoryFromStorage(): Promise<void> {
    try {
      // 这里应该使用实际的存储API，如preferences
      // 暂时使用内存缓存
      Logger.info(this.TAG, 'Loading playback history from storage');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.warn(this.TAG, `Failed to load history from storage: ${error}`);
    }
  }

  /**
   * 保存历史记录到存储 | Save history to storage
   */
  private async saveHistoryToStorage(): Promise<void> {
    try {
      // 这里应该使用实际的存储API
      Logger.info(this.TAG, 'Saving playback history to storage');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.warn(this.TAG, `Failed to save history to storage: ${error}`);
    }
  }

  /**
   * 添加播放历史记录 | Add playback history
   */
  public async addHistory(history: PlaybackHistory): Promise<void> {
    try {
      // 检查是否已存在相同记录
      const existingIndex: number = this.historyCache.findIndex(
        (h: PlaybackHistory) => h.mediaId === history.mediaId && h.episodeId === history.episodeId
      );

      if (existingIndex !== -1) {
        // 更新现有记录
        this.historyCache[existingIndex] = {
          ...this.historyCache[existingIndex],
          ...history,
          lastPlayedAt: Date.now()
        };
      } else {
        // 添加新记录
        this.historyCache.unshift({
          ...history,
          lastPlayedAt: Date.now()
        });

        // 限制历史记录数量
        if (this.historyCache.length > this.MAX_HISTORY_COUNT) {
          this.historyCache = this.historyCache.slice(0, this.MAX_HISTORY_COUNT);
        }
      }

      // 保存到存储
      await this.saveHistoryToStorage();

      Logger.info(this.TAG, `Added playback history: ${history.title} - ${history.episodeTitle}`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to add playback history: ${error}`);
    }
  }

  /**
   * 获取播放历史记录 | Get playback history
   */
  public async getHistory(mediaId?: string, episodeId?: string): Promise<PlaybackHistory[]> {
    try {
      if (mediaId && episodeId) {
        // 返回特定记录
        const history: PlaybackHistory[] = this.historyCache.filter(
          (h: PlaybackHistory) => h.mediaId === mediaId && h.episodeId === episodeId
        );
        return history;
      } else if (mediaId) {
        // 返回该媒体的所有记录
        const history: PlaybackHistory[] = this.historyCache.filter(
          (h: PlaybackHistory) => h.mediaId === mediaId
        );
        return history;
      } else {
        // 返回所有历史记录
        return [...this.historyCache];
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to get playback history: ${error}`);
      return [];
    }
  }

  /**
   * 获取最近的播放历史记录 | Get recent playback history
   */
  public async getRecentHistory(count: number = 10): Promise<PlaybackHistory[]> {
    try {
      return this.historyCache.slice(0, Math.min(count, this.historyCache.length));
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to get recent playback history: ${error}`);
      return [];
    }
  }

  /**
   * 删除播放历史记录 | Delete playback history
   */
  public async deleteHistory(mediaId: string, episodeId?: string): Promise<void> {
    try {
      if (episodeId) {
        // 删除特定记录
        this.historyCache = this.historyCache.filter(
          (h: PlaybackHistory) => !(h.mediaId === mediaId && h.episodeId === episodeId)
        );
      } else {
        // 删除该媒体的所有记录
        this.historyCache = this.historyCache.filter(
          (h: PlaybackHistory) => h.mediaId !== mediaId
        );
      }

      // 保存到存储
      await this.saveHistoryToStorage();

      Logger.info(this.TAG, `Deleted playback history: ${mediaId}${episodeId ? ` - ${episodeId}` : ''}`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to delete playback history: ${error}`);
    }
  }

  /**
   * 清空播放历史记录 | Clear all playback history
   */
  public async clearHistory(): Promise<void> {
    try {
      this.historyCache = [];
      await this.saveHistoryToStorage();

      Logger.info(this.TAG, 'Cleared all playback history');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to clear playback history: ${error}`);
    }
  }

  /**
   * 保存播放进度 | Save playback progress
   */
  public async saveProgress(progress: PlaybackProgress): Promise<void> {
    try {
      // 检查是否需要保存（避免过于频繁的保存）
      const now: number = Date.now();
      if (now - this.lastSaveTime < this.PROGRESS_SAVE_INTERVAL) {
        return;
      }
      this.lastSaveTime = now;

      // 检查进度是否有效（避免保存开头或结尾的进度）
      if (progress.currentTime < this.PROGRESS_THRESHOLD) {
        return;
      }

      if (progress.duration > 0 && progress.currentTime > progress.duration - this.PROGRESS_THRESHOLD) {
        return;
      }

      // 查找并更新历史记录
      const existingIndex: number = this.historyCache.findIndex(
        (h: PlaybackHistory) => h.mediaId === progress.mediaId && h.episodeId === progress.episodeId
      );

      if (existingIndex !== -1) {
        this.historyCache[existingIndex].currentTime = progress.currentTime;
        this.historyCache[existingIndex].duration = progress.duration;
        this.historyCache[existingIndex].lastPlayedAt = now;
      }

      // 保存到存储
      await this.saveHistoryToStorage();

      Logger.info(this.TAG, `Saved playback progress: ${progress.mediaId} - ${progress.episodeId} at ${progress.currentTime}s`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to save playback progress: ${error}`);
    }
  }

  /**
   * 获取播放进度 | Get playback progress
   */
  public async getProgress(mediaId: string, episodeId: string): Promise<number> {
    try {
      const history: PlaybackHistory[] = this.historyCache.filter(
        (h: PlaybackHistory) => h.mediaId === mediaId && h.episodeId === episodeId
      );

      if (history.length > 0) {
        const progress: number = history[0].currentTime;
        Logger.info(this.TAG, `Got playback progress: ${mediaId} - ${episodeId} at ${progress}s`);
        return progress;
      }

      return 0;
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to get playback progress: ${error}`);
      return 0;
    }
  }

  /**
   * 检查是否有断点续播 | Check if has resume point
   */
  public async hasResumePoint(mediaId: string, episodeId: string): Promise<boolean> {
    try {
      const progress: number = await this.getProgress(mediaId, episodeId);
      return progress > this.PROGRESS_THRESHOLD;
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      return false;
    }
  }

  /**
   * 获取断点续播提示信息 | Get resume point message
   */
  public async getResumeMessage(mediaId: string, episodeId: string): Promise<string> {
    try {
      const progress: number = await this.getProgress(mediaId, episodeId);
      if (progress > 0) {
        const minutes: number = Math.floor(progress / 60);
        const seconds: number = Math.floor(progress % 60);
        return `上次观看到 ${minutes}:${seconds.toString().padStart(2, '0')}，是否继续观看？`;
      }
      return '';
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      return '';
    }
  }
}

// 导出单例实例
export function getPlaybackHistoryService(): PlaybackHistoryService {
  return PlaybackHistoryService.getInstance();
}
