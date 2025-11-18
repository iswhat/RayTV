// History - 观看历史实体类
import Logger from '../../common/util/Logger';
import DateUtil from '../../common/util/DateUtil';
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
    return `${DateUtil.formatDuration(this.progress)} / ${DateUtil.formatDuration(this.totalDuration)}`;
  }

  /**
   * 获取相对最后观看时间描述
   * @returns 相对时间描述
   */
  public getRelativeWatchTime(): string {
    return DateUtil.getRelativeTime(this.lastWatchTime);
  }

  /**
   * 获取格式化的最后观看时间
   * @returns 格式化的时间字符串
   */
  public getFormattedLastWatchTime(): string {
    return DateUtil.format(this.lastWatchTime);
  }

  /**
   * 获取剧集信息描述（如果有）
   * @returns 剧集描述
   */
  public getEpisodeInfo(): string {
    if (this.episodeTitle) {
      return this.episodeTitle;
    }
    if (this.season !== undefined && this.episode !== undefined) {
      return `第${this.season}季 第${this.episode}集`;
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
        return '电视剧';
      case VideoType.ANIME:
        return '动漫';
      case VideoType.DOCUMENTARY:
        return '纪录片';
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
   * @returns 是否为最近观看
   */
  public isRecentlyWatched(): boolean {
    const lastWatchDate = new Date(this.lastWatchTime);
    const now = new Date();
    const diffHours = (now.getTime() - lastWatchDate.getTime()) / (1000 * 60 * 60);
    return diffHours <= 24;
  }

  /**
   * 获取观看状态文本
   * @returns 状态文本
   */
  public getWatchStatusText(): string {
    if (this.isFinished) {
      return '已完成';
    }
    const percentage = this.getProgressPercentage();
    if (percentage >= 70) {
      return '即将完成';
    } else if (percentage >= 30) {
      return '观看中';
    } else {
      return '开始观看';
    }
  }

  /**
   * 序列化对象（用于存储）
   * @returns 序列化后的对象
   */
  public toSerializable(): HistorySerializable {
    // 使用对象字面量直接初始化，避免空对象字面量
    const result: HistorySerializable = {
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
    
    // 仅在属性有值时添加可选字段
    if (this.coverUrl !== undefined) result.coverUrl = this.coverUrl;
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
    // 创建类型安全的部分对象
    const historyData: Partial<History> = {};
    
    // 手动检查并赋值每个属性，确保类型安全
    if (typeof data.id === 'string') historyData.id = data.id;
    if (typeof data.userId === 'string') historyData.userId = data.userId;
    if (typeof data.contentId === 'string') historyData.contentId = data.contentId;
    if (typeof data.contentTitle === 'string') historyData.contentTitle = data.contentTitle;
    // 修复类型不匹配问题，确保从number转换为VideoType
    if (typeof data.contentType === 'number') historyData.contentType = data.contentType as VideoType;
    if (typeof data.progress === 'number') historyData.progress = data.progress;
    if (typeof data.totalDuration === 'number') historyData.totalDuration = data.totalDuration;
    if (typeof data.lastWatchTime === 'string') historyData.lastWatchTime = data.lastWatchTime;
    if (typeof data.playCount === 'number') historyData.playCount = data.playCount;
    if (typeof data.isFinished === 'boolean') historyData.isFinished = data.isFinished;
    
    // 添加可选属性
    if (data.coverUrl !== undefined) historyData.coverUrl = data.coverUrl;
    if (data.episodeId !== undefined) historyData.episodeId = data.episodeId;
    if (data.episodeTitle !== undefined) historyData.episodeTitle = data.episodeTitle;
    if (data.season !== undefined) historyData.season = data.season;
    if (data.episode !== undefined) historyData.episode = data.episode;
    if (data.sourceId !== undefined) historyData.sourceId = data.sourceId;
    if (data.quality !== undefined) historyData.quality = data.quality;
    if (data.deviceId !== undefined) historyData.deviceId = data.deviceId;
    
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
   * 创建历史记录的比较函数（用于排序）
   * @param order 排序顺序 'desc'（默认）或 'asc'
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
   * 合并相同内容的历史记录
   * @param histories 历史记录数组
   * @returns 合并后的历史记录数组
   */
  public static mergeHistories(histories: History[]): History[] {
    const historyMap = new Map<string, History>();

    histories.forEach(history => {
      // 使用contentId和episodeId作为唯一键（如果有episodeId）
      const key = history.episodeId ? `${history.contentId}_${history.episodeId}` : history.contentId;
      
      const existingHistory = historyMap.get(key);
      if (existingHistory) {
        // 如果已有记录，保留最新的观看时间和最大的观看进度
        const lastWatchTime = new Date(history.lastWatchTime).getTime();
        const existingLastWatchTime = new Date(existingHistory.lastWatchTime).getTime();
        
        if (lastWatchTime > existingLastWatchTime) {
          // 新记录更新时间更新，替换为新记录
          historyMap.set(key, history);
        } else if (history.progress > existingHistory.progress) {
          // 进度更新，合并信息
          existingHistory.progress = history.progress;
          existingHistory.playCount += history.playCount;
          existingHistory.isFinished = existingHistory.progress >= existingHistory.totalDuration * 0.9;
        }
      } else {
        // 新记录
        historyMap.set(key, history);
      }
    });

    // 转换为数组并按最后观看时间排序
    return Array.from(historyMap.values()).sort(History.getSortComparator());
  }
}