// History - 观看历史实体类 | History entity class
import Logger from '../../common/util/Logger';
import DateUtil, { DateFormatType } from '../../common/util/DateUtil';
import { VideoType } from './Movie';

const TAG = 'History';

/**
 * 历史记录序列化接口 | History serializable interface
 * 定义历史记录对象序列化和反序列化时的结构 | Define structure for history object serialization and deserialization
 */
export interface HistorySerializable {
  id: string;
  userId: string;
  contentId: string;
  contentTitle: string;
  contentType: number;
  progress: number;
  totalDuration: number;
  lastWatchTime: string;
  playCount: number;
  isFinished: boolean;
  coverUrl?: string;
  episodeId?: string;
  episodeTitle?: string;
  season?: number;
  episode?: number;
  sourceId?: string;
  quality?: string;
  deviceId?: string;
}

/**
 * History构造函数参数接口 | History constructor params interface
 */
export interface HistoryConstructorParams {
  id?: string;
  userId?: string;
  contentId?: string;
  contentTitle?: string;
  contentType?: VideoType;
  coverUrl?: string;
  episodeId?: string;
  episodeTitle?: string;
  season?: number;
  episode?: number;
  progress?: number;
  totalDuration?: number;
  lastWatchTime?: string;
  playCount?: number;
  isFinished?: boolean;
  sourceId?: string;
  quality?: string;
  deviceId?: string;
}

/**
 * 观看历史实体类 | Watch history entity class
 * 记录用户的观看历史信息 | Record user's watch history information
 */
export default class History {
  id: string;              // 历史记录ID | History record ID
  userId: string;          // 用户ID | User ID
  contentId: string;       // 内容ID（Movie ID等） | Content ID (Movie ID, etc.)
  contentTitle: string;    // 内容标题 | Content title
  contentType: VideoType;  // 内容类型 | Content type
  coverUrl?: string;       // 封面图片URL | Cover image URL
  episodeId?: string;      // 剧集ID（如果是多集内容） | Episode ID (if multi-episode content)
  episodeTitle?: string;   // 剧集标题 | Episode title
  season?: number;         // 季数 | Season number
  episode?: number;        // 集数 | Episode number
  progress: number;        // 观看进度（秒） | Watch progress (seconds)
  totalDuration: number;   // 总时长（秒） | Total duration (seconds)
  lastWatchTime: string;   // 最后观看时间 | Last watch time
  playCount: number;       // 播放次数 | Play count
  isFinished: boolean;     // 是否已观看完成 | Is finished watching
  sourceId?: string;       // 播放源ID | Playback source ID
  quality?: string;        // 播放质量 | Playback quality
  deviceId?: string;       // 观看设备ID | Watching device ID

  /**
   * 构造函数 | Constructor
   */
  constructor(data: HistoryConstructorParams) {
    this.id = data.id || `history_${DateUtil.getTimestamp()}_${Math.random().toString(36).substr(2, 9)}`;
    this.userId = data.userId || '';
    this.contentId = data.contentId || '';
    this.contentTitle = data.contentTitle || '未知内容';
    this.contentType = data.contentType || VideoType.OTHER;
    this.coverUrl = data.coverUrl;
    this.episodeId = data.episodeId;
    this.episodeTitle = data.episodeTitle;
    this.season = data.season;
    this.episode = data.episode;
    this.progress = data.progress || 0;
    this.totalDuration = data.totalDuration || 0;
    this.lastWatchTime = data.lastWatchTime || DateUtil.format(new Date());
    this.playCount = data.playCount || 1;
    this.isFinished = data.isFinished || false;
    this.sourceId = data.sourceId;
    this.quality = data.quality;
    this.deviceId = data.deviceId;
  }

  /**
   * 更新观看进度 | Update watch progress
   * @param progress 新的进度（秒） | New progress (seconds)
   * @param duration 总时长（秒，可选） | Total duration (seconds, optional)
   */
  public updateProgress(progress: number, duration?: number): void {
    this.progress = progress;
    this.lastWatchTime = DateUtil.format(new Date());
    this.playCount += 1;

    if (duration !== undefined) {
      this.totalDuration = duration;
    }

    // 当观看进度超过总时长的90%时，视为已完成 | When watch progress exceeds 90% of total duration, consider as finished
    this.isFinished = this.totalDuration > 0 && progress >= this.totalDuration * 0.9;
  }

  /**
   * 获取观看进度百分比 | Get watch progress percentage
   * @returns 进度百分比 | Progress percentage
   */
  public getProgressPercentage(): number {
    if (this.totalDuration <= 0) {
      return 0;
    }
    return Math.min(100, Math.round((this.progress / this.totalDuration) * 100));
  }

  /**
   * 获取格式化的观看进度 | Get formatted watch progress
   * @returns 格式化的进度字符串 | Formatted progress string
   */
  public getFormattedProgress(): string {
    return this.formatTime(this.progress);
  }

  /**
   * 获取格式化的总时长 | Get formatted total duration
   * @returns 格式化的总时长字符串 | Formatted total duration string
   */
  public getFormattedTotalDuration(): string {
    return this.formatTime(this.totalDuration);
  }

  /**
   * 获取格式化的最后观看时间 | Get formatted last watch time
   * @returns 格式化的时间字符串 | Formatted time string
   */
  public getFormattedLastWatchTime(): string {
    return DateUtil.format(this.lastWatchTime, DateFormatType.DATE_CHINESE);
  }

  /**
   * 将秒数格式化为 HH:MM:SS 或 MM:SS 格式 | Format seconds to HH:MM:SS or MM:SS format
   * @param seconds 秒数 | Seconds
   * @returns 格式化的时间字符串 | Formatted time string
   */
  private formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);

    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  /**
   * 序列化对象（用于存储或传输） | Serialize object (for storage or transmission)
   * @returns 序列化的对象 | Serialized object
   */
  public toSerializable(): HistorySerializable {
    return {
      id: this.id,
      userId: this.userId,
      contentId: this.contentId,
      contentTitle: this.contentTitle,
      contentType: this.contentType,
      progress: this.progress,
      totalDuration: this.totalDuration,
      lastWatchTime: this.lastWatchTime,
      playCount: this.playCount,
      isFinished: this.isFinished,
      coverUrl: this.coverUrl,
      episodeId: this.episodeId,
      episodeTitle: this.episodeTitle,
      season: this.season,
      episode: this.episode,
      sourceId: this.sourceId,
      quality: this.quality,
      deviceId: this.deviceId
    };
  }

  /**
   * 从序列化对象创建 History 实例 | Create History instance from serialized object
   * @param data 序列化数据 | Serialized data
   * @returns History 实例 | History instance
   */
  public static fromSerializable(data: HistorySerializable): History {
    // 直接将对象字面量传递给构造函数
    return new History({
      id: data.id,
      userId: data.userId,
      contentId: data.contentId,
      contentTitle: data.contentTitle,
      contentType: data.contentType as VideoType,
      progress: data.progress,
      totalDuration: data.totalDuration,
      lastWatchTime: data.lastWatchTime,
      playCount: data.playCount,
      isFinished: data.isFinished,
      coverUrl: data.coverUrl,
      episodeId: data.episodeId,
      episodeTitle: data.episodeTitle,
      season: data.season,
      episode: data.episode,
      sourceId: data.sourceId,
      quality: data.quality,
      deviceId: data.deviceId
    });
  }

  /**
   * 克隆历史记录实例 | Clone history instance
   * @returns 克隆的实例 | Cloned instance
   */
  public clone(): History {
    // 直接将对象字面量传递给构造函数
    return new History({
      id: this.id,
      userId: this.userId,
      contentId: this.contentId,
      contentTitle: this.contentTitle,
      contentType: this.contentType,
      coverUrl: this.coverUrl,
      episodeId: this.episodeId,
      episodeTitle: this.episodeTitle,
      season: this.season,
      episode: this.episode,
      progress: this.progress,
      totalDuration: this.totalDuration,
      lastWatchTime: this.lastWatchTime,
      playCount: this.playCount,
      isFinished: this.isFinished,
      sourceId: this.sourceId,
      quality: this.quality,
      deviceId: this.deviceId
    });
  }

  /**
   * 创建历史记录的比较函数（用于排序） | Create history comparison function (for sorting)
   * @param order 排序顺序 'desc'（默认）或 'asc' | Sort order 'desc' (default) or 'asc'
   * @returns 比较函数 | Comparison function
   */
  public static getSortComparator(order: 'desc' | 'asc' = 'desc'): (a: History, b: History) => number {
    return (a: History, b: History) => {
      const timeA = new Date(a.lastWatchTime).getTime();
      const timeB = new Date(b.lastWatchTime).getTime();
      return order === 'desc' ? timeB - timeA : timeA - timeB;
    };
  }

  /**
   * 合并历史记录列表，去重并保留最新 | Merge history list, deduplicate and keep latest
   * @param histories 历史记录列表 | History list
   * @returns 合并后的历史记录列表 | Merged history list
   */
  public static mergeHistories(histories: History[]): History[] {
    const historyMap = new Map<string, History>();

    // 使用 Map 去重，保留最新的记录 | Use Map to deduplicate, keep latest record
    for (const history of histories) {
      const key = `${history.userId}_${history.contentId}_${history.episodeId || ''}`;
      const existingHistory = historyMap.get(key);
      if (!existingHistory || new Date(history.lastWatchTime) > new Date(existingHistory.lastWatchTime)) {
        historyMap.set(key, history);
      }
    }

    // 转换为数组并按最后观看时间排序 | Convert to array and sort by last watch time
    return Array.from(historyMap.values()).sort(History.getSortComparator());
  }
}

