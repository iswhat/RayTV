// SearchResult - 搜索结果实体类
import Logger from '../../common/util/Logger';
import { VideoType } from './Movie';

const TAG = 'SearchResult';

/**
 * 搜索结果类型枚举
 */
export enum ResultType {
  MOVIE,          // 电影
  TV_SERIES,      // 电视剧
  ANIME,          // 动漫
  DOCUMENTARY,    // 纪录片
  VARIETY,        // 综艺
  ACTOR,          // 演员
  DIRECTOR,       // 导演
  GENRE,          // 类型
  TAG,            // 标签
  CHANNEL,        // 频道
  COLLECTION,     // 合集
  LIVE,           // 直播
  OTHER           // 其他
}

/**
 * 搜索结果实体类
 * 定义搜索结果的数据结构和相关操作
 */
export default class SearchResult {
  id: string;              // 结果唯一标识
  title: string;           // 标题
  originalTitle?: string;  // 原始标题
  type: ResultType;        // 结果类型
  coverUrl?: string;       // 封面图片URL
  backdropUrl?: string;    // 背景图片URL
  description?: string;    // 描述/简介
  score?: number;          // 评分
  year?: number;           // 年份
  releaseDate?: string;    // 发布日期
  genres?: string[];       // 类型标签
  tags?: string[];         // 标签
  duration?: number;       // 时长（秒）
  totalEpisodes?: number;  // 总集数
  currentSeason?: number;  // 当前季数
  actors?: string[];       // 演员列表（针对内容类型）
  directors?: string[];    // 导演列表（针对内容类型）
  popularity?: number;     // 热度/流行度
  matchScore?: number;     // 匹配分数（搜索相关性）
  extraInfo?: Record<string, string | number | boolean | object | null>; // 额外信息，使用具体的类型联合
  link?: string;           // 关联链接
  sourceId?: string;       // 来源ID
  sourceName?: string;     // 来源名称

  /**
   * 构造函数
   */
  constructor(data: Partial<SearchResult>) {
    this.id = data.id || `result_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    this.title = data.title || '';
    this.originalTitle = data.originalTitle;
    this.type = data.type || ResultType.OTHER;
    this.coverUrl = data.coverUrl;
    this.backdropUrl = data.backdropUrl;
    this.description = data.description;
    this.score = data.score;
    this.year = data.year;
    this.releaseDate = data.releaseDate;
    this.genres = data.genres || [];
    this.tags = data.tags || [];
    this.duration = data.duration;
    this.totalEpisodes = data.totalEpisodes;
    this.currentSeason = data.currentSeason;
    this.actors = data.actors || [];
    this.directors = data.directors || [];
    this.popularity = data.popularity;
    this.matchScore = data.matchScore;
    // 确保extraInfo是有效的对象类型
    this.extraInfo = data.extraInfo && typeof data.extraInfo === 'object' && !Array.isArray(data.extraInfo) ? data.extraInfo : {};
    this.link = data.link;
    this.sourceId = data.sourceId;
    this.sourceName = data.sourceName;
  }

  /**
   * 获取类型的文本描述
   * @returns 类型描述
   */
  public getTypeDescription(): string {
    switch (this.type) {
      case ResultType.MOVIE:
        return '电影';
      case ResultType.TV_SERIES:
        return '电视剧';
      case ResultType.ANIME:
        return '动漫';
      case ResultType.DOCUMENTARY:
        return '纪录片';
      case ResultType.VARIETY:
        return '综艺';
      case ResultType.ACTOR:
        return '演员';
      case ResultType.DIRECTOR:
        return '导演';
      case ResultType.GENRE:
        return '类型';
      case ResultType.TAG:
        return '标签';
      case ResultType.CHANNEL:
        return '频道';
      case ResultType.COLLECTION:
        return '合集';
      case ResultType.LIVE:
        return '直播';
      default:
        return '其他';
    }
  }

  /**
   * 获取类型对应的VideoType（如果适用）
   * @returns VideoType或undefined
   */
  public getVideoType(): VideoType | undefined {
    switch (this.type) {
      case ResultType.MOVIE:
        return VideoType.MOVIE;
      case ResultType.TV_SERIES:
        return VideoType.TV_SERIES;
      case ResultType.ANIME:
        return VideoType.ANIME;
      case ResultType.DOCUMENTARY:
        return VideoType.DOCUMENTARY;
      case ResultType.VARIETY:
        return VideoType.VARIETY;
      case ResultType.LIVE:
        return VideoType.LIVE;
      default:
        return undefined;
    }
  }

  /**
   * 获取格式化的评分
   * @returns 格式化的评分字符串
   */
  public getFormattedScore(): string {
    if (this.score === undefined || this.score === null) {
      return '--';
    }
    return this.score.toFixed(1);
  }

  /**
   * 获取格式化的年份
   * @returns 年份字符串
   */
  public getFormattedYear(): string {
    if (this.year) {
      return this.year.toString();
    }
    if (this.releaseDate) {
      return this.releaseDate.substring(0, 4);
    }
    return '--';
  }

  /**
   * 获取格式化的时长
   * @returns 时长字符串
   */
  public getFormattedDuration(): string {
    if (!this.duration) {
      return '';
    }
    
    const hours = Math.floor(this.duration / 3600);
    const minutes = Math.floor((this.duration % 3600) / 60);
    
    if (hours > 0) {
      return `${hours}时${minutes > 0 ? `${minutes}分` : ''}`;
    }
    return `${minutes}分钟`;
  }

  /**
   * 获取类型标签字符串
   * @returns 类型标签字符串
   */
  public getGenresString(): string {
    return this.genres?.join(' / ') || '';
  }

  /**
   * 获取演员列表字符串
   * @param maxCount 最大显示数量
   * @returns 演员字符串
   */
  public getActorsString(maxCount: number = 3): string {
    if (!this.actors || this.actors.length === 0) {
      return '';
    }
    
    if (this.actors.length <= maxCount) {
      return this.actors.join('、');
    }
    
    return `${this.actors.slice(0, maxCount).join('、')}...`;
  }

  /**
   * 获取导演列表字符串
   * @param maxCount 最大显示数量
   * @returns 导演字符串
   */
  public getDirectorsString(maxCount: number = 2): string {
    if (!this.directors || this.directors.length === 0) {
      return '';
    }
    
    if (this.directors.length <= maxCount) {
      return this.directors.join('、');
    }
    
    return `${this.directors.slice(0, maxCount).join('、')}...`;
  }

  /**
   * 获取简洁的描述（限制长度）
   * @param maxLength 最大长度
   * @returns 简洁描述
   */
  public getShortDescription(maxLength: number = 100): string {
    if (!this.description) {
      return '';
    }
    
    if (this.description.length <= maxLength) {
      return this.description;
    }
    
    return `${this.description.substring(0, maxLength)}...`;
  }

  /**
   * 检查是否为媒体内容类型（电影、电视剧等）
   * @returns 是否为媒体内容
   */
  public isMediaContent(): boolean {
    const mediaTypes = [
      ResultType.MOVIE,
      ResultType.TV_SERIES,
      ResultType.ANIME,
      ResultType.DOCUMENTARY,
      ResultType.VARIETY,
      ResultType.LIVE
    ];
    return mediaTypes.includes(this.type);
  }

  /**
   * 检查是否为人物类型（演员、导演）
   * @returns 是否为人物
   */
  public isPersonType(): boolean {
    return this.type === ResultType.ACTOR || this.type === ResultType.DIRECTOR;
  }

  /**
   * 检查是否为分类类型（类型、标签）
   * @returns 是否为分类
   */
  public isCategoryType(): boolean {
    return this.type === ResultType.GENRE || this.type === ResultType.TAG || this.type === ResultType.CHANNEL;
  }

  /**
   * 获取显示优先级（用于搜索结果排序）
   * @returns 优先级数值
   */
  public getDisplayPriority(): number {
    // 定义类型优先级
    const typePriority: Record<ResultType, number> = {
      [ResultType.MOVIE]: 10,
      [ResultType.TV_SERIES]: 9,
      [ResultType.ANIME]: 8,
      [ResultType.LIVE]: 7,
      [ResultType.DOCUMENTARY]: 6,
      [ResultType.VARIETY]: 5,
      [ResultType.ACTOR]: 4,
      [ResultType.DIRECTOR]: 3,
      [ResultType.COLLECTION]: 2,
      [ResultType.GENRE]: 1,
      [ResultType.TAG]: 1,
      [ResultType.CHANNEL]: 1,
      [ResultType.OTHER]: 0
    };

    // 基础优先级
    let priority = typePriority[this.type] || 0;
    
    // 结合匹配分数
    if (this.matchScore) {
      priority += this.matchScore * 0.1;
    }
    
    // 结合热度
    if (this.popularity) {
      priority += Math.min(1, this.popularity / 100);
    }
    
    // 结合评分
    if (this.score) {
      priority += this.score / 10;
    }
    
    return priority;
  }

  /**
   * 序列化对象（用于存储或传输）
   * @returns 序列化后的对象
   */
  public toSerializable(): Record<string, string | number | boolean | object | null> {
    const result: Record<string, string | number | boolean | object | null> = {};
    
    result.id = this.id;
    result.title = this.title;
    if (this.originalTitle !== undefined) result.originalTitle = this.originalTitle;
    result.type = this.type;
    if (this.coverUrl !== undefined) result.coverUrl = this.coverUrl;
    if (this.backdropUrl !== undefined) result.backdropUrl = this.backdropUrl;
    if (this.description !== undefined) result.description = this.description;
    if (this.score !== undefined) result.score = this.score;
    if (this.year !== undefined) result.year = this.year;
    if (this.releaseDate !== undefined) result.releaseDate = this.releaseDate;
    if (this.genres !== undefined) result.genres = this.genres;
    if (this.tags !== undefined) result.tags = this.tags;
    if (this.duration !== undefined) result.duration = this.duration;
    if (this.totalEpisodes !== undefined) result.totalEpisodes = this.totalEpisodes;
    if (this.currentSeason !== undefined) result.currentSeason = this.currentSeason;
    if (this.actors !== undefined) result.actors = this.actors;
    if (this.directors !== undefined) result.directors = this.directors;
    if (this.popularity !== undefined) result.popularity = this.popularity;
    if (this.matchScore !== undefined) result.matchScore = this.matchScore;
    if (this.extraInfo !== undefined) result.extraInfo = this.extraInfo;
    if (this.link !== undefined) result.link = this.link;
    if (this.sourceId !== undefined) result.sourceId = this.sourceId;
    if (this.sourceName !== undefined) result.sourceName = this.sourceName;
    
    return result;
  }

  /**
   * 从序列化对象创建SearchResult实例
   * @param data 序列化的数据
   * @returns SearchResult实例
   */
  public static fromSerializable(data: Record<string, string | number | boolean | object | null>): SearchResult {
    // 将Record类型转换为Partial<SearchResult>类型
    const searchResultData: Partial<SearchResult> = {};
    
    // 手动赋值每个属性，确保类型安全
    if (typeof data.id === 'string') searchResultData.id = data.id;
    if (typeof data.title === 'string') searchResultData.title = data.title;
    if (typeof data.originalTitle === 'string') searchResultData.originalTitle = data.originalTitle;
    if (typeof data.type === 'number') searchResultData.type = data.type;
    if (typeof data.coverUrl === 'string') searchResultData.coverUrl = data.coverUrl;
    if (typeof data.backdropUrl === 'string') searchResultData.backdropUrl = data.backdropUrl;
    if (typeof data.description === 'string') searchResultData.description = data.description;
    if (typeof data.score === 'number') searchResultData.score = data.score;
    if (typeof data.year === 'number') searchResultData.year = data.year;
    if (typeof data.releaseDate === 'string') searchResultData.releaseDate = data.releaseDate;
    if (Array.isArray(data.genres)) searchResultData.genres = data.genres as string[];
    if (Array.isArray(data.tags)) searchResultData.tags = data.tags as string[];
    if (typeof data.duration === 'number') searchResultData.duration = data.duration;
    if (typeof data.totalEpisodes === 'number') searchResultData.totalEpisodes = data.totalEpisodes;
    if (typeof data.currentSeason === 'number') searchResultData.currentSeason = data.currentSeason;
    if (Array.isArray(data.actors)) searchResultData.actors = data.actors as string[];
    if (Array.isArray(data.directors)) searchResultData.directors = data.directors as string[];
    if (typeof data.popularity === 'number') searchResultData.popularity = data.popularity;
    if (typeof data.matchScore === 'number') searchResultData.matchScore = data.matchScore;
    if (data.extraInfo && typeof data.extraInfo === 'object' && !Array.isArray(data.extraInfo)) searchResultData.extraInfo = data.extraInfo as Record<string, string | number | boolean | object | null>;
    if (typeof data.link === 'string') searchResultData.link = data.link;
    if (typeof data.sourceId === 'string') searchResultData.sourceId = data.sourceId;
    if (typeof data.sourceName === 'string') searchResultData.sourceName = data.sourceName;
    
    return new SearchResult(searchResultData);
  }

  /**
   * 克隆SearchResult实例
   * @returns 克隆后的实例
   */
  public clone(): SearchResult {
    return new SearchResult(this.toSerializable());
  }

  /**
   * 创建搜索结果的比较函数（用于排序）
   * @param order 排序顺序 'desc'（默认）或 'asc'
   * @returns 比较函数
   */
  public static getSortComparator(order: 'desc' | 'asc' = 'desc'): (a: SearchResult, b: SearchResult) => number {
    return (a: SearchResult, b: SearchResult) => {
      const priorityA = a.getDisplayPriority();
      const priorityB = b.getDisplayPriority();
      return order === 'desc' ? priorityB - priorityA : priorityA - priorityB;
    };
  }
}