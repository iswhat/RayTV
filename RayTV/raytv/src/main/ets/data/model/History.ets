// History - 观看历史实体�?import Logger from '../../common/util/Logger';
import DateUtil from '../../common/util/DateUtil';
import { VideoType } from './Movie';

const TAG = 'History';

/**
 * 历史记录序列化接�? * 定义历史记录对象在序列化和反序列化时的结�? */
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
 * 观看历史实体�? * 记录用户的观看历史信�? */
export default class History {
  id: string;              // 历史记录ID
  userId: string;          // 用户ID
  contentId: string;       // 内容ID（Movie ID等）
  contentTitle: string;    // 内容标题
  contentType: VideoType;  // 内容类型
  coverUrl?: string;       // 封面图片URL
  episodeId?: string;      // 剧集ID（如果是多集内容�?  episodeTitle?: string;   // 剧集标题
  season?: number;         // 季数
  episode?: number;        // 集数
  progress: number;        // 观看进度（秒�?  totalDuration: number;   // 总时长（秒）
  lastWatchTime: string;   // 最后观看时�?  playCount: number;       // 播放次数
  isFinished: boolean;     // 是否观看完成
  sourceId?: string;       // 播放源ID
  quality?: string;        // 播放质量
  deviceId?: string;       // 观看设备ID

  /**
   * 构造函�?   */
  constructor(data: Partial<History>) {
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
   * @param progress 新的进度（秒�?   * @param duration 总时长（秒，可选）
   */
  public updateProgress(progress: number, duration?: number): void {
    this.progress = progress;
    this.lastWatchTime = DateUtil.format(new Date());
    this.playCount += 1;

    if (duration !== undefined) {
      this.totalDuration = duration;
    }

    // 如果观看进度超过总时长的90%，标记为已完�?    this.isFinished = this.totalDuration > 0 && progress >= this.totalDuration * 0.9;
  }

  /**
   * 获取观看进度百分�?   * @returns 进度百分�?   */
  public getProgressPercentage(): number {
    if (this.totalDuration <= 0) {
      return 0;
    }
    return Math.min(100, Math.round((this.progress / this.totalDuration) * 100));
  }

  /**
   * 获取格式化的观看进度
   * @returns 格式化的进度字符�?   */
  public getFormattedProgress(): string {
    return `${DateUtil.formatDuration(this.progress)} / ${DateUtil.formatDuration(this.totalDuration)}`;
  }

  /**
   * 获取相对最后观看时间描�?   * @returns 相对时间描述
   */
  public getRelativeWatchTime(): string {
    return DateUtil.getRelativeTime(this.lastWatchTime);
  }

  /**
   * 获取格式化的最后观看时�?   * @returns 格式化的时间字符�?   */
  public getFormattedLastWatchTime(): string {
    return DateUtil.format(this.lastWatchTime);
  }

  /**
   * 获取剧集信息描述（如果有�?   * @returns 剧集描述
   */
  public getEpisodeInfo(): string {
    if (this.episodeTitle) {
      return this.episodeTitle;
    }
    if (this.season !== undefined && this.episode !== undefined) {
      return `�?{this.season}�?�?{this.episode}集`;
    }
    return '';
  }

  /**
   * 获取内容类型描述
   * @returns 类型描述
   */
  public getContentTypeDescription(): string {
    switch (this.contentType) {
      case VideoType.MOVIE:
        return '电影';
      case VideoType.TV_SERIES:
        return '电视�?;
      case VideoType.ANIME:
        return '动漫';
      case VideoType.DOCUMENTARY:
        return '纪录�?;
      case VideoType.VARIETY:
        return '综艺';
      case VideoType.LIVE:
        return '直播';
      default:
        return '其他';
    }
  }

  /**
   * 重置观看进度
   */
  public resetProgress(): void {
    this.progress = 0;
    this.isFinished = false;
    this.lastWatchTime = DateUtil.format(new Date());
  }

  /**
   * 标记为已完成
   */
  public markAsFinished(): void {
    this.progress = this.totalDuration;
    this.isFinished = true;
    this.lastWatchTime = DateUtil.format(new Date());
  }

  /**
   * 检查是否为最近观看（24小时内）
   * @returns 是否为最近观�?   */
  public isRecentlyWatched(): boolean {
    const lastWatchDate = new Date(this.lastWatchTime);
    const now = new Date();
    const diffHours = (now.getTime() - lastWatchDate.getTime()) / (1000 * 60 * 60);
    return diffHours <= 24;
  }

  /**
   * 获取观看状态文�?   * @returns 状态文�?   */
  public getWatchStatusText(): string {
    if (this.isFinished) {
      return '已完�?;
    }
    const percentage = this.getProgressPercentage();
    if (percentage >= 70) {
      return '即将完成';
    } else if (percentage >= 30) {
      return '观看�?;
    } else {
      return '开始观�?;
    }
  }

  /**
   * 序列化对象（用于存储�?   * @returns 序列化后的对�?   */
  public toSerializable(): HistorySerializable {
    // 使用对象字面量直接初始化，避免空对象字面�?    const result: HistorySerializable = {
      id: this.id,
      userId: this.userId,
      contentId: this.contentId,
      contentTitle: this.contentTitle,
      contentType: this.contentType,
      progress: this.progress,
      totalDuration: this.totalDuration,
      lastWatchTime: this.lastWatchTime,
      playCount: this.playCount,
      isFinished: this.isFinished
    };
    
    // 仅在属性有值时添加可选字�?    if (this.coverUrl !== undefined) result.coverUrl = this.coverUrl;
    if (this.episodeId !== undefined) result.episodeId = this.episodeId;
    if (this.episodeTitle !== undefined) result.episodeTitle = this.episodeTitle;
    if (this.season !== undefined) result.season = this.season;
    if (this.episode !== undefined) result.episode = this.episode;
    if (this.sourceId !== undefined) result.sourceId = this.sourceId;
    if (this.quality !== undefined) result.quality = this.quality;
    if (this.deviceId !== undefined) result.deviceId = this.deviceId;
    
    return result;
  }

  /**
   * 从序列化对象创建History实例
   * @param data 序列化的数据
   * @returns History实例
   */
  public static fromSerializable(data: HistorySerializable): History {
    // 为对象字面量添加明确的类型注�?    const historyData: Partial<History> = {
      id: typeof data.id === 'string' ? data.id : `history_${DateUtil.getTimestamp()}_${Math.random().toString(36).substr(2, 9)}`,
      userId: typeof data.userId === 'string' ? data.userId : '',
      contentId: typeof data.contentId === 'string' ? data.contentId : '',
      contentTitle: typeof data.contentTitle === 'string' ? data.contentTitle : '未知内容',
      contentType: typeof data.contentType === 'number' ? data.contentType as VideoType : VideoType.OTHER,
      progress: typeof data.progress === 'number' ? data.progress : 0,
      totalDuration: typeof data.totalDuration === 'number' ? data.totalDuration : 0,
      lastWatchTime: typeof data.lastWatchTime === 'string' ? data.lastWatchTime : DateUtil.format(new Date()),
      playCount: typeof data.playCount === 'number' ? data.playCount : 1,
      isFinished: typeof data.isFinished === 'boolean' ? data.isFinished : false,
      coverUrl: data.coverUrl,
      episodeId: data.episodeId,
      episodeTitle: data.episodeTitle,
      season: data.season,
      episode: data.episode,
      sourceId: data.sourceId,
      quality: data.quality,
      deviceId: data.deviceId
    };
    return new History(historyData);
  }

  /**
   * 克隆History实例
   * @returns 克隆后的实例
   */
  public clone(): History {
    return new History(this.toSerializable());
  }

  /**
   * 创建历史记录的比较函数（用于排序�?   * @param order 排序顺序 'desc'（默认）�?'asc'
   * @returns 比较函数
   */
  public static getSortComparator(order: 'desc' | 'asc' = 'desc'): (a: History, b: History) => number {
    return (a: History, b: History) => {
      const dateA = new Date(a.lastWatchTime).getTime();
      const dateB = new Date(b.lastWatchTime).getTime();
      return order === 'desc' ? dateB - dateA : dateA - dateB;
    };
  }

  /**
   * 合并相同内容的历史记�?   * @param histories 历史记录数组
   * @returns 合并后的历史记录数组
   */
  public static mergeHistories(histories: History[]): History[] {
    const historyMap = new Map<string, History>();

    histories.forEach(history => {
      // 使用contentId和episodeId作为唯一键（如果有episodeId�?      const key = history.episodeId ? `${history.contentId}_${history.episodeId}` : history.contentId;
      
      const existingHistory = historyMap.get(key);
      if (existingHistory) {
        // 如果已有记录，保留最新的观看时间和最大的观看进度
        const lastWatchTime = new Date(history.lastWatchTime).getTime();
        const existingLastWatchTime = new Date(existingHistory.lastWatchTime).getTime();
        
        if (lastWatchTime > existingLastWatchTime) {
          // 新记录更新时间更新，替换为新记录
          historyMap.set(key, history);
        } else if (history.progress > existingHistory.progress) {
          // 进度更新，合并信�?          existingHistory.progress = history.progress;
          existingHistory.playCount += history.playCount;
          existingHistory.isFinished = existingHistory.progress >= existingHistory.totalDuration * 0.9;
        }
      } else {
        // 新记�?        historyMap.set(key, history);
      }
    });

    // 转换为数组并按最后观看时间排�?    return Array.from(historyMap.values()).sort(History.getSortComparator());
  }
}
