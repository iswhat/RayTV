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
 * 嵌套额外信息类型定义
 */
export interface NestedExtraInfo {
  nestedData?: Record<string, string | number | boolean | null>;
}

/**
 * 额外信息类型定义
 */
export interface ExtraInfo {
  extraData?: Record<string, string | number | boolean | null | NestedExtraInfo>;
}

/**
 * 搜索结果序列化数据接口
 */
export interface SearchResultSerializable {
  id: string;
  title: string;
  originalTitle?: string;
  type: ResultType;
  coverUrl?: string;
  backdropUrl?: string;
  description?: string;
  score?: number;
  year?: number;
  releaseDate?: string;
  genres?: string[];
  tags?: string[];
  duration?: number;
  totalEpisodes?: number;
  currentSeason?: number;
  actors?: string[];
  directors?: string[];
  popularity?: number;
  matchScore?: number;
  extraInfo?: ExtraInfo;
  link?: string;
  sourceId?: string;
  sourceName?: string;
}

/**
 * SearchResult构造函数参数接口
 */
export interface SearchResultConstructorParams {
  id?: string;
  title?: string;
  originalTitle?: string;
  type?: ResultType;
  coverUrl?: string;
  backdropUrl?: string;
  description?: string;
  score?: number;
  year?: number;
  releaseDate?: string;
  genres?: string[];
  tags?: string[];
  duration?: number;
  totalEpisodes?: number;
  currentSeason?: number;
  actors?: string[];
  directors?: string[];
  popularity?: number;
  matchScore?: number;
  extraInfo?: ExtraInfo;
  link?: string;
  sourceId?: string;
  sourceName?: string;
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
  extraInfo?: ExtraInfo;   // 额外信息
  link?: string;           // 关联链接
  sourceId?: string;       // 来源ID
  sourceName?: string;     // 来源名称

  /**
   * 构造函数
   */
  constructor(data: SearchResultConstructorParams) {
    this.id = data.id ?? `result_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    this.title = data.title ?? '';
    this.originalTitle = data.originalTitle;
    this.type = data.type ?? ResultType.OTHER;
    this.coverUrl = data.coverUrl;
    this.backdropUrl = data.backdropUrl;
    this.description = data.description;
    this.score = data.score;
    this.year = data.year;
    this.releaseDate = data.releaseDate;
    this.genres = data.genres ?? [];
    this.tags = data.tags ?? [];
    this.duration = data.duration;
    this.totalEpisodes = data.totalEpisodes;
    this.currentSeason = data.currentSeason;
    this.actors = data.actors ?? [];
    this.directors = data.directors ?? [];
    this.popularity = data.popularity;
    this.matchScore = data.matchScore;
    this.extraInfo = data.extraInfo;
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
    return '';
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
      return `${hours}小时${minutes}分钟`;
    }
    return `${minutes}分钟`;
  }

  /**
   * 检查是否为内容类型（电影、电视剧等）
   * @returns 是否为内容类型
   */
  public isContentType(): boolean {
    return this.type === ResultType.MOVIE || 
           this.type === ResultType.TV_SERIES || 
           this.type === ResultType.ANIME || 
           this.type === ResultType.DOCUMENTARY || 
           this.type === ResultType.VARIETY || 
           this.type === ResultType.LIVE;
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
    return this.type === ResultType.GENRE || 
           this.type === ResultType.TAG || 
           this.type === ResultType.CHANNEL;
  }

  /**
   * 获取显示优先级（用于搜索结果排序）
   * @returns 优先级数值
   */
  public getDisplayPriority(): number {
    // 定义类型优先级
    let basePriority = 0;
    switch (this.type) {
      case ResultType.MOVIE:
        basePriority = 10;
        break;
      case ResultType.TV_SERIES:
        basePriority = 9;
        break;
      case ResultType.ANIME:
        basePriority = 8;
        break;
      case ResultType.LIVE:
        basePriority = 7;
        break;
      case ResultType.DOCUMENTARY:
        basePriority = 6;
        break;
      case ResultType.VARIETY:
        basePriority = 5;
        break;
      case ResultType.ACTOR:
        basePriority = 4;
        break;
      case ResultType.DIRECTOR:
        basePriority = 3;
        break;
      case ResultType.COLLECTION:
        basePriority = 2;
        break;
      case ResultType.GENRE:
      case ResultType.TAG:
      case ResultType.CHANNEL:
        basePriority = 1;
        break;
      case ResultType.OTHER:
      default:
        basePriority = 0;
        break;
    }

    // 基础优先级
    let priority = basePriority;
    
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
   * 序列化对象（用于存储）
   * @returns 序列化后的对象
   */
  public toSerializable(): SearchResultSerializable {
    const serializable: SearchResultSerializable = {
      id: this.id,
      title: this.title,
      type: this.type
    };
    
    // 逐个赋值可选属性
    if (this.originalTitle !== undefined) {
      serializable.originalTitle = this.originalTitle;
    }
    if (this.coverUrl !== undefined) {
      serializable.coverUrl = this.coverUrl;
    }
    if (this.backdropUrl !== undefined) {
      serializable.backdropUrl = this.backdropUrl;
    }
    if (this.description !== undefined) {
      serializable.description = this.description;
    }
    if (this.score !== undefined) {
      serializable.score = this.score;
    }
    if (this.year !== undefined) {
      serializable.year = this.year;
    }
    if (this.releaseDate !== undefined) {
      serializable.releaseDate = this.releaseDate;
    }
    if (this.genres !== undefined) {
      serializable.genres = this.genres;
    }
    if (this.tags !== undefined) {
      serializable.tags = this.tags;
    }
    if (this.duration !== undefined) {
      serializable.duration = this.duration;
    }
    if (this.totalEpisodes !== undefined) {
      serializable.totalEpisodes = this.totalEpisodes;
    }
    if (this.currentSeason !== undefined) {
      serializable.currentSeason = this.currentSeason;
    }
    if (this.actors !== undefined) {
      serializable.actors = this.actors;
    }
    if (this.directors !== undefined) {
      serializable.directors = this.directors;
    }
    if (this.popularity !== undefined) {
      serializable.popularity = this.popularity;
    }
    if (this.matchScore !== undefined) {
      serializable.matchScore = this.matchScore;
    }
    if (this.extraInfo !== undefined) {
      serializable.extraInfo = this.extraInfo;
    }
    if (this.link !== undefined) {
      serializable.link = this.link;
    }
    if (this.sourceId !== undefined) {
      serializable.sourceId = this.sourceId;
    }
    if (this.sourceName !== undefined) {
      serializable.sourceName = this.sourceName;
    }
    
    return serializable;
  }

  /**
   * 从序列化对象创建SearchResult实例
   * @param data 序列化的数据
   * @returns SearchResult实例
   */
  public static fromSerializable(data: SearchResultSerializable): SearchResult {
    // 准备extraInfo
    let extraInfo: ExtraInfo | undefined;
    if (data.extraInfo && typeof data.extraInfo === 'object' && !Array.isArray(data.extraInfo)) {
      extraInfo = {
        extraData: {}
      };
      
      // 处理extraData
      if (data.extraInfo.extraData && typeof data.extraInfo.extraData === 'object' && !Array.isArray(data.extraInfo.extraData)) {
        const extraDataKeys = Object.keys(data.extraInfo.extraData);
        for (let i = 0; i < extraDataKeys.length; i++) {
          const key = extraDataKeys[i];
          const value = data.extraInfo.extraData![key];
          
          if (value && typeof value === 'object' && !Array.isArray(value)) {
            // 检查是否为NestedExtraInfo类型
            const potentialNested = value as NestedExtraInfo;
            if (potentialNested.nestedData && typeof potentialNested.nestedData === 'object' && !Array.isArray(potentialNested.nestedData)) {
              // 克隆NestedExtraInfo对象
              const nestedCloned: NestedExtraInfo = {
                nestedData: {}
              };
              
              // 手动复制nestedData中的每个属性
              const nestedKeys = Object.keys(potentialNested.nestedData);
              for (let j = 0; j < nestedKeys.length; j++) {
                const nestedKey = nestedKeys[j];
                const nestedValue = potentialNested.nestedData![nestedKey];
                // 只复制基本类型值
                if (typeof nestedValue === 'string' || typeof nestedValue === 'number' || typeof nestedValue === 'boolean' || nestedValue === null) {
                  nestedCloned.nestedData![nestedKey] = nestedValue;
                }
              }
              
              extraInfo.extraData![key] = nestedCloned;
            } else {
              // 直接复制基本类型值
              if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
                extraInfo.extraData![key] = value;
              }
            }
          } else {
            // 直接复制基本类型值
            if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
              extraInfo.extraData![key] = value;
            }
          }
        }
      }
    }
    
    // 直接将对象字面量传递给构造函数
    return new SearchResult({
      id: typeof data.id === 'string' ? data.id : `result_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
      title: typeof data.title === 'string' ? data.title : '',
      originalTitle: typeof data.originalTitle === 'string' ? data.originalTitle : undefined,
      type: typeof data.type === 'number' ? data.type as ResultType : ResultType.OTHER,
      coverUrl: typeof data.coverUrl === 'string' ? data.coverUrl : undefined,
      backdropUrl: typeof data.backdropUrl === 'string' ? data.backdropUrl : undefined,
      description: typeof data.description === 'string' ? data.description : undefined,
      score: typeof data.score === 'number' ? data.score : undefined,
      year: typeof data.year === 'number' ? data.year : undefined,
      releaseDate: typeof data.releaseDate === 'string' ? data.releaseDate : undefined,
      genres: Array.isArray(data.genres) ? data.genres.filter(item => typeof item === 'string') : undefined,
      tags: Array.isArray(data.tags) ? data.tags.filter(item => typeof item === 'string') : undefined,
      duration: typeof data.duration === 'number' ? data.duration : undefined,
      totalEpisodes: typeof data.totalEpisodes === 'number' ? data.totalEpisodes : undefined,
      currentSeason: typeof data.currentSeason === 'number' ? data.currentSeason : undefined,
      actors: Array.isArray(data.actors) ? data.actors.filter(item => typeof item === 'string') : undefined,
      directors: Array.isArray(data.directors) ? data.directors.filter(item => typeof item === 'string') : undefined,
      popularity: typeof data.popularity === 'number' ? data.popularity : undefined,
      matchScore: typeof data.matchScore === 'number' ? data.matchScore : undefined,
      extraInfo: extraInfo,
      link: typeof data.link === 'string' ? data.link : undefined,
      sourceId: typeof data.sourceId === 'string' ? data.sourceId : undefined,
      sourceName: typeof data.sourceName === 'string' ? data.sourceName : undefined
    });
  }

  /**
   * 克隆SearchResult实例
   * @returns 克隆后的实例
   */
  public clone(): SearchResult {
    // 克隆extraInfo
    let clonedExtraInfo: ExtraInfo | undefined;
    if (this.extraInfo) {
      clonedExtraInfo = {
        extraData: {}
      };
      
      // 确保extraInfo.extraData存在
      if (this.extraInfo.extraData) {
        // 手动复制extraData中的每个属性
        const keys = Object.keys(this.extraInfo.extraData);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          const value = this.extraInfo.extraData![key];
          
          if (value && typeof value === 'object' && !Array.isArray(value)) {
            // 检查是否为NestedExtraInfo类型
            const potentialNested = value as NestedExtraInfo;
            if (potentialNested.nestedData && typeof potentialNested.nestedData === 'object' && !Array.isArray(potentialNested.nestedData)) {
              // 克隆NestedExtraInfo对象
              const nestedCloned: NestedExtraInfo = {
                nestedData: {}
              };
              
              // 手动复制nestedData中的每个属性
              const nestedKeys = Object.keys(potentialNested.nestedData);
              for (let j = 0; j < nestedKeys.length; j++) {
                const nestedKey = nestedKeys[j];
                const nestedValue = potentialNested.nestedData![nestedKey];
                // 只复制基本类型值
                if (typeof nestedValue === 'string' || typeof nestedValue === 'number' || typeof nestedValue === 'boolean' || nestedValue === null) {
                  nestedCloned.nestedData![nestedKey] = nestedValue;
                }
              }
              
              clonedExtraInfo.extraData![key] = nestedCloned;
            } else {
              // 直接复制基本类型值
              if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
                clonedExtraInfo.extraData![key] = value;
              }
            }
          } else {
            // 直接复制基本类型值
            if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
              clonedExtraInfo.extraData![key] = value;
            }
          }
        }
      }
    }
    
    // 直接将对象字面量传递给构造函数
    return new SearchResult({
      id: this.id,
      title: this.title,
      originalTitle: this.originalTitle,
      type: this.type,
      coverUrl: this.coverUrl,
      backdropUrl: this.backdropUrl,
      description: this.description,
      score: this.score,
      year: this.year,
      releaseDate: this.releaseDate,
      genres: this.genres ? [...this.genres] : undefined,
      tags: this.tags ? [...this.tags] : undefined,
      duration: this.duration,
      totalEpisodes: this.totalEpisodes,
      currentSeason: this.currentSeason,
      actors: this.actors ? [...this.actors] : undefined,
      directors: this.directors ? [...this.directors] : undefined,
      popularity: this.popularity,
      matchScore: this.matchScore,
      link: this.link,
      sourceId: this.sourceId,
      sourceName: this.sourceName,
      extraInfo: clonedExtraInfo
    });
  }

  /**
   * 创建搜索结果的比较函数（用于排序）
   * @param order 排序顺序 'desc'（默认）或'asc'
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