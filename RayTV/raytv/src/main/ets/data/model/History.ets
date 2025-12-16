// History - 观看历史实体类
import Logger from '../../common/util/Logger';
import DateUtil, { DateFormatType } from '../../common/util/DateUtil';
import { VideoType } from './Movie';

const TAG = 'History';

/**
 * 历史记录序列化接口
 * 定义历史记录对象在序列化和反序列化时的结构
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
 * History构造函数参数接口
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
 * 观看历史实体类
 * 记录用户的观看历史信息
 */
export default class History {
  id: string;              // 历史记录ID
  userId: string;          // 用户ID
  contentId: string;       // 内容ID（Movie ID等）
  contentTitle: string;    // 内容标题
  contentType: VideoType;  // 内容类型
  coverUrl?: string;       // 封面图片URL
  episodeId?: string;      // 剧集ID（如果是多集内容）
  episodeTitle?: string;   // 剧集标题
  season?: number;         // 季数
  episode?: number;        // 集数
  progress: number;        // 观看进度（秒）
  totalDuration: number;   // 总时长（秒）
  lastWatchTime: string;   // 最后观看时间
  playCount: number;       // 播放次数
  isFinished: boolean;     // 是否观看完成
  sourceId?: string;       // 播放源ID
  quality?: string;        // 播放质量
  deviceId?: string;       // 观看设备ID

  /**
   * 构造函数
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
   * 更新观看进度
   * @param progress 新的进度（秒）
   * @param duration 总时长（秒，可选）
   */
  public updateProgress(progress: number, duration?: number): void {
    this.progress = progress;
    this.lastWatchTime = DateUtil.format(new Date());
    this.playCount += 1;

    if (duration !== undefined) {
      this.totalDuration = duration;
    }

    // 如果观看进度超过总时长的90%，标记为已完成
    this.isFinished = this.totalDuration > 0 && progress >= this.totalDuration * 0.9;
  }

  /**
   * 获取观看进度百分比
   * @returns 进度百分比
   */
  public getProgressPercentage(): number {
    if (this.totalDuration <= 0) {
      return 0;
    }
    return Math.min(100, Math.round((this.progress / this.totalDuration) * 100));
  }

  /**
   * 获取格式化的观看进度
   * @returns 格式化的进度字符串
   */
  public getFormattedProgress(): string {
    return this.formatTime(this.progress);
  }

  /**
   * 获取格式化的总时长
   * @returns 格式化的总时长字符串
   */
  public getFormattedTotalDuration(): string {
    return this.formatTime(this.totalDuration);
  }

  /**
   * 获取格式化的最后观看时间
   * @returns 格式化的时间字符串
   */
  public getFormattedLastWatchTime(): string {
    return DateUtil.format(this.lastWatchTime, DateFormatType.DATE_CHINESE);
  }

  /**
   * 将秒数格式化为 HH:MM:SS 或 MM:SS 格式
   * @param seconds 秒数
   * @returns 格式化的时间字符串
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
   * 序列化对象（用于存储或传输）
   * @returns 序列化后的对象
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
   * 从序列化对象创建 History 实例
   * @param data 序列化的数据
   * @returns History 实例
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
   * 克隆历史记录实例
   * @returns 克隆后的实例
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
   * 创建历史记录的比较函数（用于排序）
   * @param order 排序顺序 'desc'（默认）或 'asc'
   * @returns 比较函数
   */
  public static getSortComparator(order: 'desc' | 'asc' = 'desc'): (a: History, b: History) => number {
    return (a: History, b: History) => {
      const timeA = new Date(a.lastWatchTime).getTime();
      const timeB = new Date(b.lastWatchTime).getTime();
      return order === 'desc' ? timeB - timeA : timeA - timeB;
    };
  }

  /**
   * 合并历史记录列表，去重并保留最新记录
   * @param histories 历史记录列表
   * @returns 合并后的历史记录列表
   */
  public static mergeHistories(histories: History[]): History[] {
    const historyMap = new Map<string, History>();

    // 使用 Map 去重，保留最新的记录
    for (const history of histories) {
      const key = `${history.userId}_${history.contentId}_${history.episodeId || ''}`;
      const existingHistory = historyMap.get(key);
      if (!existingHistory || new Date(history.lastWatchTime) > new Date(existingHistory.lastWatchTime)) {
        historyMap.set(key, history);
      }
    }

    // 转换为数组并按最后观看时间排序
    return Array.from(historyMap.values()).sort(History.getSortComparator());
  }
}