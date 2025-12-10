// SearchResult - 搜索结果实体�?import Logger from '../../common/util/Logger';
import { VideoType } from './Movie';

const TAG = 'SearchResult';

/**
 * 搜索结果类型枚举
 */
export enum ResultType {
  MOVIE,          // 电影
  TV_SERIES,      // 电视�?  ANIME,          // 动漫
  DOCUMENTARY,    // 纪录�?  VARIETY,        // 综艺
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
 * 额外信息类型定义
 */
export interface ExtraInfo {
  extraData?: Record<string, string | number | boolean | null | NestedExtraInfo>;
}

/**
 * 嵌套额外信息类型定义
 */
export interface NestedExtraInfo {
  nestedData?: Record<string, string | number | boolean | null>;
}

/**
 * 搜索结果实体�? * 定义搜索结果的数据结构和相关操作
 */
export default class SearchResult {
  id: string;              // 结果唯一标识
  title: string;           // 标题
  originalTitle?: string;  // 原始标题
  type: ResultType;        // 结果类型
  coverUrl?: string;       // 封面图片URL
  backdropUrl?: string;    // 背景图片URL
  description?: string;    // 描述/简�?  score?: number;          // 评分
  year?: number;           // 年份
  releaseDate?: string;    // 发布日期
  genres?: string[];       // 类型标签
  tags?: string[];         // 标签
  duration?: number;       // 时长（秒�?  totalEpisodes?: number;  // 总集�?  currentSeason?: number;  // 当前季数
  actors?: string[];       // 演员列表（针对内容类型）
  directors?: string[];    // 导演列表（针对内容类型）
  popularity?: number;     // 热度/流行�?  matchScore?: number;     // 匹配分数（搜索相关性）
  extraInfo?: ExtraInfo; // 额外信息，使用更明确的类型定�?  link?: string;           // 关联链接
  sourceId?: string;       // 来源ID
  sourceName?: string;     // 来源名称

  /**
   * 构造函�?   */
  constructor(data: Partial<SearchResult>) {
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
    // 确保extraInfo是有效的对象类型，使用明确的类型初始�?    if (data.extraInfo && typeof data.extraInfo === 'object' && !Array.isArray(data.extraInfo)) {
      this.extraInfo = data.extraInfo as ExtraInfo;
    } else {
      // 使用空对象字面量，明确类�?      this.extraInfo = this.createEmptyExtraInfo();
    }
    this.link = data.link;
    this.sourceId = data.sourceId;
    this.sourceName = data.sourceName;
  }

  /**
   * 创建空的ExtraInfo对象
   * @returns 空的ExtraInfo对象
   */
  private createEmptyExtraInfo(): ExtraInfo {
    return {
      extraData: undefined
    };
  }

  /**
   * 创建空的extraData记录
   * @returns 空的Record对象
   */
  private createEmptyExtraData(): Record<string, string | number | boolean | null | NestedExtraInfo> {
    return {};
  }

  /**
   * 获取类型的文本描�?   * @returns 类型描述
   */
  public getTypeDescription(): string {
    switch (this.type) {
      case ResultType.MOVIE:
        return '电影';
      case ResultType.TV_SERIES:
        return '电视�?;
      case ResultType.ANIME:
        return '动漫';
      case ResultType.DOCUMENTARY:
        return '纪录�?;
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
   * 获取类型对应的VideoType（如果适用�?   * @returns VideoType或undefined
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
   * @returns 格式化的评分字符�?   */
  public getFormattedScore(): string {
    if (this.score === undefined || this.score === null) {
      return '--';
    }
    return this.score.toFixed(1);
  }

  /**
   * 获取格式化的年份
   * @returns 年份字符�?   */
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
   * @returns 时长字符�?   */
  public getFormattedDuration(): string {
    if (!this.duration) {
      return '';
    }
    
    const hours = Math.floor(this.duration / 3600);
    const minutes = Math.floor((this.duration % 3600) / 60);
    
    if (hours > 0) {
      return `${hours}�?{minutes > 0 ? `${minutes}分` : ''}`;
    }
    return `${minutes}分钟`;
  }

  /**
   * 获取类型标签字符�?   * @returns 类型标签字符�?   */
  public getGenresString(): string {
    return this.genres?.join(' / ') || '';
  }

  /**
   * 获取演员列表字符�?   * @param maxCount 最大显示数�?   * @returns 演员字符�?   */
  public getActorsString(maxCount: number = 3): string {
    if (!this.actors || this.actors.length === 0) {
      return '';
    }
    
    if (this.actors.length <= maxCount) {
      return this.actors.join('�?);
    }
    
    return `${this.actors.slice(0, maxCount).join('�?)}...`;
  }

  /**
   * 获取导演列表字符�?   * @param maxCount 最大显示数�?   * @returns 导演字符�?   */
  public getDirectorsString(maxCount: number = 2): string {
    if (!this.directors || this.directors.length === 0) {
      return '';
    }
    
    if (this.directors.length <= maxCount) {
      return this.directors.join('�?);
    }
    
    return `${this.directors.slice(0, maxCount).join('�?)}...`;
  }

  /**
   * 获取简洁的描述（限制长度）
   * @param maxLength 最大长�?   * @returns 简洁描�?   */
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
   * @returns 是否为媒体内�?   */
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
   * @returns 是否为人�?   */
  public isPersonType(): boolean {
    return this.type === ResultType.ACTOR || this.type === ResultType.DIRECTOR;
  }

  /**
   * 检查是否为分类类型（类型、标签）
   * @returns 是否为分�?   */
  public isCategoryType(): boolean {
    return this.type === ResultType.GENRE || this.type === ResultType.TAG || this.type === ResultType.CHANNEL;
  }

  /**
   * 获取显示优先级（用于搜索结果排序�?   * @returns 优先级数�?   */
  public getDisplayPriority(): number {
    // 定义类型优先�?- 使用switch语句替代对象字面量，避免非标识符属性名
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

    // 基础优先�?    let priority = basePriority;
    
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

// 定义SearchResult序列化数据接�?export interface SearchResultSerializable {
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
   * 序列化对象（用于存储�?   * @returns 序列化后的对�?   */
  public toSerializable(): SearchResultSerializable {
    // 创建一个符合SearchResultSerializable接口的对象，避免使用对象字面�?    const result: SearchResultSerializable = {
      id: this.id,
      title: this.title,
      type: this.type
    };
    
    // 逐个赋值可选属�?    if (this.originalTitle !== undefined) {
      result.originalTitle = this.originalTitle;
    }
    if (this.coverUrl !== undefined) {
      result.coverUrl = this.coverUrl;
    }
    if (this.backdropUrl !== undefined) {
      result.backdropUrl = this.backdropUrl;
    }
    if (this.description !== undefined) {
      result.description = this.description;
    }
    if (this.score !== undefined) {
      result.score = this.score;
    }
    if (this.year !== undefined) {
      result.year = this.year;
    }
    if (this.releaseDate !== undefined) {
      result.releaseDate = this.releaseDate;
    }
    if (this.genres !== undefined) {
      result.genres = this.genres;
    }
    if (this.tags !== undefined) {
      result.tags = this.tags;
    }
    if (this.duration !== undefined) {
      result.duration = this.duration;
    }
    if (this.totalEpisodes !== undefined) {
      result.totalEpisodes = this.totalEpisodes;
    }
    if (this.currentSeason !== undefined) {
      result.currentSeason = this.currentSeason;
    }
    if (this.actors !== undefined) {
      result.actors = this.actors;
    }
    if (this.directors !== undefined) {
      result.directors = this.directors;
    }
    if (this.popularity !== undefined) {
      result.popularity = this.popularity;
    }
    if (this.matchScore !== undefined) {
      result.matchScore = this.matchScore;
    }
    if (this.extraInfo !== undefined) {
      result.extraInfo = this.extraInfo;
    }
    if (this.link !== undefined) {
      result.link = this.link;
    }
    if (this.sourceId !== undefined) {
      result.sourceId = this.sourceId;
    }
    if (this.sourceName !== undefined) {
      result.sourceName = this.sourceName;
    }
    
    return result;
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
      // 创建一个明确的ExtraInfo对象，使用接口初始化
      extraInfo = {
        extraData: {}
      };
      
      // 检查extraData属�?      const extraInfoData = data.extraInfo as Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>>;
      if (extraInfoData.extraData && typeof extraInfoData.extraData === 'object' && !Array.isArray(extraInfoData.extraData)) {
        const extraDataObj = extraInfoData.extraData as Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>>;
        
        // 处理extraData的每个属�?        const extraDataKeys = Object.keys(extraDataObj);
        for (let i = 0; i < extraDataKeys.length; i++) {
          const key = extraDataKeys[i];
          const value = extraDataObj[key];
          
          if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
            extraInfo.extraData[key] = value;
          } else if (value && typeof value === 'object' && !Array.isArray(value)) {
            // 处理嵌套对象
            const nestedInfo: NestedExtraInfo = {
              nestedData: {}
            };
            const nestedObj = value as Record<string, string | number | boolean | null>;
            
            const nestedKeys = Object.keys(nestedObj);
            for (let j = 0; j < nestedKeys.length; j++) {
              const nestedKey = nestedKeys[j];
              const nestedValue = nestedObj[nestedKey];
              
              if (typeof nestedValue === 'string' || typeof nestedValue === 'number' || 
                  typeof nestedValue === 'boolean' || nestedValue === null) {
                nestedInfo.nestedData[nestedKey] = nestedValue;
              }
            }
            
            extraInfo.extraData[key] = nestedInfo;
          }
        }
      }
    }
    
    // 直接使用构造函数创建实�?    const searchResultParams: Partial<SearchResult> = {
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
    };
    
    return new SearchResult(searchResultParams);
  }

  /**
   * 克隆SearchResult实例
   * @returns 克隆后的实例
   */
  public clone(): SearchResult {
    // 创建一个符合Partial<SearchResult>类型的对象，避免直接使用对象字面�?    const cloneData: Partial<SearchResult> = {};
    
    // 逐个赋值属性，确保类型安全
    cloneData.id = this.id;
    cloneData.title = this.title;
    cloneData.originalTitle = this.originalTitle;
    cloneData.type = this.type;
    cloneData.coverUrl = this.coverUrl;
    cloneData.backdropUrl = this.backdropUrl;
    cloneData.description = this.description;
    cloneData.score = this.score;
    cloneData.year = this.year;
    cloneData.releaseDate = this.releaseDate;
    cloneData.genres = this.genres ? Array.from(this.genres) : undefined;
    cloneData.tags = this.tags ? Array.from(this.tags) : undefined;
    cloneData.duration = this.duration;
    cloneData.totalEpisodes = this.totalEpisodes;
    cloneData.currentSeason = this.currentSeason;
    cloneData.actors = this.actors ? Array.from(this.actors) : undefined;
    cloneData.directors = this.directors ? Array.from(this.directors) : undefined;
    cloneData.popularity = this.popularity;
    cloneData.matchScore = this.matchScore;
    cloneData.extraInfo = this.extraInfo ? this.cloneExtraInfo(this.extraInfo) : undefined;
    cloneData.link = this.link;
    cloneData.sourceId = this.sourceId;
    cloneData.sourceName = this.sourceName;
    
    return new SearchResult(cloneData);
  }

  /**
   * 克隆ExtraInfo对象
   * @param extraInfo 要克隆的ExtraInfo对象
   * @returns 克隆后的ExtraInfo对象
   */
  private cloneExtraInfo(extraInfo: ExtraInfo): ExtraInfo {
    // 创建ExtraInfo对象，明确初始化extraData
    const cloned: ExtraInfo = {
      extraData: {}
    };
    
    // 确保extraInfo.extraData存在
    if (extraInfo.extraData) {
      // 手动复制extraData中的每个属�?      const keys = Object.keys(extraInfo.extraData);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = extraInfo.extraData[key];
        
        if (value && typeof value === 'object' && !Array.isArray(value)) {
          // 检查是否为NestedExtraInfo类型
          const potentialNested = value as Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>>;
          if (potentialNested.nestedData && typeof potentialNested.nestedData === 'object' && !Array.isArray(potentialNested.nestedData)) {
            // 克隆NestedExtraInfo对象
            const nestedCloned: NestedExtraInfo = {
              nestedData: {}
            };
            
            // 手动复制nestedData中的每个属�?            const nestedKeys = Object.keys(potentialNested.nestedData);
            for (let j = 0; j < nestedKeys.length; j++) {
              const nestedKey = nestedKeys[j];
              const nestedValue = potentialNested.nestedData![nestedKey];
              nestedCloned.nestedData[nestedKey] = nestedValue;
            }
            
            cloned.extraData[key] = nestedCloned;
          } else {
            // 直接复制基本类型�?            if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
              cloned.extraData[key] = value;
            }
          }
        } else {
          // 直接复制基本类型�?          cloned.extraData[key] = value;
        }
      }
    }
    
    return cloned;
  }

  /**
   * 创建搜索结果的比较函数（用于排序�?   * @param order 排序顺序 'desc'（默认）�?'asc'
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
