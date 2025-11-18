// Movie - 电影/视频实体类
import Logger from '../../common/util/Logger';
import DateUtil from '../../common/util/DateUtil';

const TAG = 'Movie';

/**
 * 视频质量枚举
 */
export enum VideoQuality {
  SD,     // 标清
  HD,     // 高清
  FHD,    // 全高清
  UHD,    // 4K超高清
  HDR     // HDR
}

/**
 * 视频类型枚举
 */
export enum VideoType {
  MOVIE,      // 电影
  TV_SERIES,  // 电视剧
  ANIME,      // 动漫
  DOCUMENTARY,// 纪录片
  VARIETY,    // 综艺
  LIVE,       // 直播
  OTHER       // 其他
}

/**
 * Movie序列化接口
 */
export interface MovieSerializable {
  id?: string;
  title?: string;
  originalTitle?: string;
  type?: VideoType;
  coverUrl?: string;
  backdropUrl?: string;
  overview?: string;
  releaseDate?: string;
  genres?: string[];
  tags?: string[];
  ratings?: RatingInfo[];
  directors?: string[];
  actors?: string[];
  countries?: string[];
  languages?: string[];
  duration?: number;
  totalEpisodes?: number;
  currentSeason?: number;
  episodes?: Episode[];
  recommended?: boolean;
  favorite?: boolean;
  watchedProgress?: number;
  playCount?: number;
  updateTime?: string;
  sources?: VideoSource[];
  score?: number;
  year?: number;
}

/**
 * 评分信息接口
 */
export interface RatingInfo {
  score: number;     // 评分
  source: string;    // 评分来源
  count: number;     // 评分人数
}

/**
 * 音轨信息接口
 */
export interface AudioTrack {
  id: string;
  name: string;
  url: string;
}

/**
 * 字幕信息接口
 */
export interface SubtitleTrack {
  id: string;
  name: string;
  url: string;
  language: string;
}

/**
 * 视频播放源接口
 */
export interface VideoSource {
  id: string;          // 播放源ID
  name: string;        // 播放源名称
  url: string;         // 播放地址
  quality: VideoQuality; // 视频质量
  format: string;      // 视频格式
  size?: number;       // 文件大小（字节）
  duration?: number;   // 时长（秒）
  resolution?: string; // 分辨率
  audioTracks?: Array<AudioTrack>; // 音轨列表
  subtitleTracks?: Array<SubtitleTrack>; // 字幕列表
}

/**
 * 剧集信息接口
 */
export interface Episode {
  id: string;           // 剧集ID
  season: number;       // 季数
  episode: number;      // 集数
  title: string;        // 剧集标题
  duration?: number;    // 时长（秒）
  airDate?: string;     // 播出日期
  overview?: string;    // 剧集简介
  sources: VideoSource[]; // 播放源列表
  watchedProgress?: number; // 观看进度（秒）
  isWatched?: boolean;   // 是否已观看
}

/**
 * 电影/视频实体类
 * 定义视频内容的基本属性和相关操作
 */
export default class Movie {
  id: string;                  // 唯一标识符
  title: string;               // 标题
  originalTitle?: string;      // 原始标题
  type: VideoType;             // 视频类型
  coverUrl?: string;           // 封面图URL
  backdropUrl?: string;        // 背景图URL
  overview?: string;           // 简介
  releaseDate?: string;        // 上映日期
  genres?: string[];           // 类型标签
  tags?: string[];             // 标签
  ratings?: RatingInfo[];      // 评分信息
  directors?: string[];        // 导演
  actors?: string[];           // 演员
  countries?: string[];        // 制片国家/地区
  languages?: string[];        // 语言
  duration?: number;           // 总时长（秒）
  totalEpisodes?: number;      // 总集数
  currentSeason?: number;      // 当前季数
  episodes?: Episode[];        // 剧集列表
  recommended?: boolean;       // 是否推荐
  favorite?: boolean;          // 是否收藏
  watchedProgress?: number;    // 观看进度（秒）
  playCount?: number;          // 播放次数
  updateTime?: string;         // 更新时间
  sources?: VideoSource[];     // 播放源列表
  score?: number;              // 综合评分（用于排序）
  year?: number;               // 年份

  /**
   * 构造函数
   */
  constructor(data: Partial<Movie>) {
    this.id = data.id || `movie_${DateUtil.getTimestamp()}_${Math.random().toString(36).substring(2, 11)}`;
    this.title = data.title || '';
    this.originalTitle = data.originalTitle;
    this.type = data.type || VideoType.OTHER;
    this.coverUrl = data.coverUrl;
    this.backdropUrl = data.backdropUrl;
    this.overview = data.overview;
    this.releaseDate = data.releaseDate;
    this.genres = data.genres || [];
    this.tags = data.tags || [];
    this.ratings = data.ratings || [];
    this.directors = data.directors || [];
    this.actors = data.actors || [];
    this.countries = data.countries || [];
    this.languages = data.languages || [];
    this.duration = data.duration;
    this.totalEpisodes = data.totalEpisodes;
    this.currentSeason = data.currentSeason;
    this.episodes = data.episodes || [];
    // 明确初始化布尔值，避免undefined
    this.recommended = !!data.recommended;
    this.favorite = !!data.favorite;
    this.watchedProgress = data.watchedProgress || 0;
    this.playCount = data.playCount || 0;
    this.updateTime = data.updateTime || DateUtil.format(new Date());
    this.sources = data.sources || [];
    this.score = data.score;
    // 安全处理日期转换
    this.year = data.year || (data.releaseDate ? new Date(data.releaseDate).getFullYear() : undefined);
  }

  /**
   * 获取综合评分
   * @returns 综合评分
   */
  public getAverageRating(): number {
    if (!this.ratings || this.ratings.length === 0) {
      return this.score || 0;
    }

    const totalScore = this.ratings.reduce((sum, rating) => sum + rating.score, 0);
    return Number((totalScore / this.ratings.length).toFixed(1));
  }

  /**
   * 获取主要评分信息
   * @returns 主要评分
   */
  public getMainRating(): RatingInfo | null {
    if (!this.ratings || this.ratings.length === 0) {
      return null;
    }

    // 返回评分人数最多的评分来源
    return this.ratings.sort((a, b) => b.count - a.count)[0];
  }

  /**
   * 获取格式化的时长
   * @returns 格式化的时长字符串
   */
  public getFormattedDuration(): string {
    if (!this.duration) {
      return '未知';
    }
    return DateUtil.formatDuration(this.duration);
  }

  /**
   * 获取格式化的上映日期
   * @returns 格式化的日期字符串
   */
  public getFormattedReleaseDate(): string {
    if (!this.releaseDate) {
      return '未知';
    }
    return DateUtil.format(this.releaseDate, 'YYYY-MM-DD');
  }

  /**
   * 获取类型字符串
   * @returns 类型字符串
   */
  public getGenresString(): string {
    if (!this.genres || this.genres.length === 0) {
      return '未知';
    }
    return this.genres.join(' / ');
  }

  /**
   * 获取导演字符串
   * @returns 导演字符串
   */
  public getDirectorsString(): string {
    if (!this.directors || this.directors.length === 0) {
      return '未知';
    }
    return this.directors.join('、');
  }

  /**
   * 获取演员字符串（限制显示数量）
   * @param maxCount 最大显示数量
   * @returns 演员字符串
   */
  public getActorsString(maxCount: number = 5): string {
    if (!this.actors || this.actors.length === 0) {
      return '未知';
    }

    if (this.actors.length <= maxCount) {
      return this.actors.join('、');
    }

    return `${this.actors.slice(0, maxCount).join('、')}...等${this.actors.length}人`;
  }

  /**
   * 更新观看进度
   * @param progress 进度（秒）
   * @param episodeId 剧集ID（可选）
   */
  public updateWatchedProgress(progress: number, episodeId?: string): void {
    this.watchedProgress = progress;
    this.playCount = (this.playCount || 0) + 1;
    this.updateTime = DateUtil.format(new Date());

    // 更新对应剧集的进度
    if (episodeId && this.episodes && this.episodes.length > 0) {
      const episode = this.episodes.find(e => e.id === episodeId);
      if (episode != null) {
        episode.watchedProgress = progress;
        // 如果观看进度超过总时长的90%，标记为已观看
        if (episode.duration && progress >= episode.duration * 0.9) {
          episode.isWatched = true;
        }
      }
    }
  }

  /**
   * 切换收藏状态
   * @returns 新的收藏状态
   */
  public toggleFavorite(): boolean {
    this.favorite = !this.favorite;
    return this.favorite;
  }

  /**
   * 获取视频类型的文本描述
   * @returns 类型描述
   */
  public getTypeDescription(): string {
    switch (this.type) {
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
   * 获取观看进度百分比
   * @returns 进度百分比
   */
  public getProgressPercentage(): number {
    const watchedProgress = this.watchedProgress || 0;
    const duration = this.duration || 1;
    return Math.min(100, Math.round(watchedProgress / duration * 100));
  }

  /**
   * 检查是否为多集内容
   * @returns 是否为多集
   */
  public isMultiEpisode(): boolean {
    return this.type === VideoType.TV_SERIES || 
           this.type === VideoType.ANIME || 
           (this.episodes != null && this.episodes.length > 1);
  }

  /**
   * 获取已观看的集数
   * @returns 已观看集数
   */
  public getWatchedEpisodeCount(): number {
    if (!this.episodes || this.episodes.length === 0) {
      return 0;
    }
    // 确保isWatched是明确的布尔值，处理undefined情况
    return this.episodes.filter(episode => {
      // 确保episode对象存在且isWatched为true
      return episode != null && episode.isWatched === true;
    }).length;
  }

  /**
   * 序列化对象（用于存储）
   * @returns 序列化后的对象
   */
  public toSerializable(): MovieSerializable {
    // 使用专用的序列化接口，符合ArkTS规范
    const result: MovieSerializable = {
      id: this.id,
      title: this.title,
      originalTitle: this.originalTitle,
      type: this.type,
      coverUrl: this.coverUrl,
      backdropUrl: this.backdropUrl,
      overview: this.overview,
      releaseDate: this.releaseDate,
      genres: this.genres,
      tags: this.tags,
      ratings: this.ratings,
      directors: this.directors,
      actors: this.actors,
      countries: this.countries,
      languages: this.languages,
      duration: this.duration,
      totalEpisodes: this.totalEpisodes,
      currentSeason: this.currentSeason,
      episodes: this.episodes,
      recommended: this.recommended,
      favorite: this.favorite,
      watchedProgress: this.watchedProgress,
      playCount: this.playCount,
      updateTime: this.updateTime,
      sources: this.sources,
      score: this.score,
      year: this.year
    };
    return result;
  }

  /**
   * 从序列化对象创建Movie实例
   * @param data 序列化的数据
   * @returns Movie实例
   */
  public static fromSerializable(data: Partial<Movie>): Movie {
    return new Movie(data);
  }

  /**
   * 克隆Movie实例
   * @returns 克隆后的实例
   */
  public clone(): Movie {
    return new Movie(this.toSerializable());
  }
}