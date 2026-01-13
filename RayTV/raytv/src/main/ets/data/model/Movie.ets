// Movie - 电影/视频实体类 | Movie/Video entity class
import Logger from '../../common/util/Logger';
import DateUtil from '../../common/util/DateUtil';

const TAG = 'Movie';

/**
 * 视频质量枚举 | Video quality enum
 */
export enum VideoQuality {
  SD,     // 标清 | Standard definition
  HD,     // 高清 | High definition
  FHD,    // 全高清 | Full high definition
  UHD,    // 4K超高清 | 4K ultra high definition
  HDR     // HDR | High dynamic range
}

/**
 * 视频类型枚举 | Video type enum
 */
export enum VideoType {
  MOVIE,      // 电影 | Movie
  TV_SERIES,  // 电视剧 | TV series
  ANIME,      // 动画 | Anime
  DOCUMENTARY,// 纪录片 | Documentary
  VARIETY,    // 综艺 | Variety
  LIVE,       // 直播 | Live
  OTHER       // 其他 | Other
}

/**
 * 评分信息接口 | Rating info interface
 */
export interface RatingInfo {
  score: number;     // 评分 | Score
  source: string;    // 评分来源 | Source
  count: number;     // 评分人数 | Count
}

/**
 * 音轨信息接口 | Audio track info interface
 */
export interface AudioTrack {
  id: string;
  name: string;
  url: string;
}

/**
 * 字幕信息接口 | Subtitle track info interface
 */
export interface SubtitleTrack {
  id: string;
  name: string;
  url: string;
  language: string;
}

/**
 * 视频播放源接口 | Video source interface
 */
export interface VideoSource {
  id: string;          // 播放源ID | Source ID
  name: string;        // 播放源名称 | Source name
  url: string;         // 播放地址 | Playback URL
  quality: VideoQuality; // 视频质量 | Video quality
  format: string;      // 视频格式 | Video format
  size?: number;       // 文件大小（字节） | File size (bytes)
  duration?: number;   // 时长（秒） | Duration (seconds)
  resolution?: string;       // 分辨率 | Resolution
  audioTracks?: Array<AudioTrack>; // 音轨列表 | Audio tracks
  subtitleTracks?: Array<SubtitleTrack>; // 字幕列表 | Subtitle tracks
}

/**
 * 剧集信息接口 | Episode info interface
 */
export interface Episode {
  id: string;           // 剧集ID | Episode ID
  season: number;       // 季数 | Season
  episode: number;      // 集数 | Episode
  title: string;        // 剧集标题 | Episode title
  duration?: number;    // 时长（秒） | Duration (seconds)
  airDate?: string;     // 播出日期 | Air date
  overview?: string;    // 剧集简介 | Episode overview
  sources: VideoSource[];     // 播放源列表 | Source list
  watchedProgress?: number;    // 观看进度（秒） | Watched progress (seconds)
  isWatched?: boolean;         // 是否已观看 | Whether watched
}

/**
 * Movie序列化接口 | Movie serializable interface
 */
export interface MovieSerializable {
  id?: string;
  title?: string;
  originalTitle?: string;
  type?: VideoType;
  contentType?: VideoType; // 添加contentType属性，兼容旧代码 | Add contentType property for compatibility with old code
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
 * 电影数据构造参数接口 | Movie constructor params interface
 */
// 导出MovieConstructorParams接口，以便在其他文件中使用 | Export MovieConstructorParams interface for use in other files
export interface MovieConstructorParams {
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
  // 添加其他可能的属性 | Add other possible properties
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
 * 电影/视频实体类 | Movie/Video entity class
 * 定义视频内容的基本属性和相关操作 | Define basic properties and related operations for video content
 */
export default class Movie {
  // 确保所有必填属性都有初始化器或在构造函数中明确赋值 | Ensure all required properties have initializers or are explicitly assigned in constructor
  id: string = '';
  title: string = '';
  originalTitle?: string;
  type: VideoType = VideoType.OTHER;
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

  /**
   * 构造函数 | Constructor
   */
  constructor(data: MovieConstructorParams) {
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
   * 获取综合评分 | Get average rating
   * @returns 综合评分 | Average rating
   */
  public getAverageRating(): number {
    if (!this.ratings || this.ratings.length === 0) {
      return this.score || 0;
    }

    const totalScore = this.ratings.reduce((sum, rating) => sum + rating.score, 0);
    return Number((totalScore / this.ratings.length).toFixed(1));
  }

  /**
   * 获取主要评分信息 | Get main rating info
   * @returns 主要评分 | Main rating
   */
  public getMainRating(): RatingInfo | null {
    if (!this.ratings || this.ratings.length === 0) {
      return null;
    }

    // 返回评分人数最多的评分来源 | Return the rating source with the most ratings
    return this.ratings.sort((a, b) => b.count - a.count)[0];
  }

  /**
   * 获取格式化时长 | Get formatted duration
   * @returns 格式化的时长字符串 | Formatted duration string
   */
  public getFormattedDuration(): string {
    if (!this.duration) {
      return '未知';
    }
    return DateUtil.formatDuration(this.duration);
  }

  /**
   * 获取格式化发行日期 | Get formatted release date
   * @returns 格式化的日期字符串 | Formatted date string
   */
  public getFormattedReleaseDate(): string {
    if (!this.releaseDate) {
      return '未知';
    }
    return DateUtil.format(this.releaseDate, 'YYYY-MM-DD');
  }

  /**
   * 获取类型字符串 | Get genres string
   * @returns 类型字符串 | Genres string
   */
  public getGenresString(): string {
    if (!this.genres || this.genres.length === 0) {
      return '未知';
    }
    return this.genres.join(' / ');
  }

  /**
   * 获取导演字符串 | Get directors string
   * @returns 导演字符串 | Directors string
   */
  public getDirectorsString(): string {
    if (!this.directors || this.directors.length === 0) {
      return '未知';
    }
    return this.directors.join('、');
  }

  /**
   * 获取演员字符串（限制显示数量）| Get actors string (limit display count)
   * @param maxCount 最大显示数量 | Maximum display count
   * @returns 演员字符串 | Actors string
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
   * 更新观看进度 | Update watched progress
   * @param progress 进度（秒） | Progress (seconds)
   * @param episodeId 剧集ID（可选） | Episode ID (optional)
   */
  public updateWatchedProgress(progress: number, episodeId?: string): void {
    this.watchedProgress = progress;
    this.playCount = (this.playCount || 0) + 1;
    this.updateTime = DateUtil.format(new Date());

    // 更新对应的剧集的进度 | Update corresponding episode's progress
    if (episodeId && this.episodes && this.episodes.length > 0) {
      const episode = this.episodes.find(e => e.id === episodeId);
      if (episode != null) {
        episode.watchedProgress = progress;
        // 如果观看进度超过总时长的90%，标记为已观看 | If watched progress exceeds 90% of total duration, mark as watched
        if (episode.duration && progress >= episode.duration * 0.9) {
          episode.isWatched = true;
        }
      }
    }
  }

  /**
   * 切换收藏状态 | Toggle favorite status
   * @returns 新的收藏状态 | New favorite status
   */
  public toggleFavorite(): boolean {
    this.favorite = !this.favorite;
    return this.favorite;
  }

  /**
   * 获取视频类型的文字描述 | Get video type description
   * @returns 类型描述 | Type description
   */
  public getTypeDescription(): string {
    switch (this.type) {
      case VideoType.MOVIE:
        return '电影';
      case VideoType.TV_SERIES:
        return '电视剧';
      case VideoType.ANIME:
        return '动画';
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
   * 获取观看进度百分比 | Get watched progress percentage
   * @returns 进度百分比 | Progress percentage
   */
  public getProgressPercentage(): number {
    const watchedProgress = this.watchedProgress || 0;
    const duration = this.duration || 1;
    return Math.min(100, Math.round(watchedProgress / duration * 100));
  }

  /**
   * 检查是否为多集内容 | Check if it's multi-episode content
   * @returns Whether multi-episode | 是否为多集
   */
  public isMultiEpisode(): boolean {
    return this.type === VideoType.TV_SERIES || 
           this.type === VideoType.ANIME || 
           (this.episodes != null && this.episodes.length > 1);
  }

  /**
   * 获取已观看的集数 | Get watched episode count
   * @returns 已观看集数 | Watched episode count
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
   * 序列化对象（用于存储）| Serialize object (for storage)
   * @returns 序列化的对象 | Serialized object
   */
  public toSerializable(): MovieSerializable {
    // 使用统一的序列化接口，符合ArkTS规范
    return {
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
  }

  /**
   * 从序列化对象创建Movie实例 | Create Movie instance from serialized object
   * @param data 序列化数据 | Serialized data
   * @returns Movie实例 | Movie instance
   */
  public static fromSerializable(data: MovieSerializable): Movie {
    // 明确类型转换为MovieConstructorParams
    const constructorParams: MovieConstructorParams = {
      id: data.id,
      title: data.title,
      originalTitle: data.originalTitle,
      type: data.type || data.contentType as VideoType || VideoType.OTHER,
      coverUrl: data.coverUrl,
      backdropUrl: data.backdropUrl,
      overview: data.overview,
      releaseDate: data.releaseDate,
      genres: data.genres,
      tags: data.tags,
      ratings: data.ratings,
      directors: data.directors,
      actors: data.actors,
      countries: data.countries,
      languages: data.languages,
      duration: data.duration,
      totalEpisodes: data.totalEpisodes,
      currentSeason: data.currentSeason,
      episodes: data.episodes,
      recommended: data.recommended,
      favorite: data.favorite,
      watchedProgress: data.watchedProgress,
      playCount: data.playCount,
      updateTime: data.updateTime,
      sources: data.sources,
      score: data.score,
      year: data.year
    };
    return new Movie(constructorParams);
  }

  /**
   * 克隆Movie实例 | Clone Movie instance
   * @returns 克隆的实例 | Cloned instance
   */
  public clone(): Movie {
    const serializableData = this.toSerializable();
    return Movie.fromSerializable(serializableData);
  }
}



