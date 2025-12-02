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
  extraInfo?: ExtraInfo; // 额外信息，使用更明确的类型定义
  link?: string;           // 关联链接
  sourceId?: string;       // 来源ID
  sourceName?: string;     // 来源名称

  /**
   * 构造函数
   */
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
    // 确保extraInfo是有效的对象类型，使用明确的类型初始化
    if (data.extraInfo && typeof data.extraInfo === 'object' && !Array.isArray(data.extraInfo)) {
      this.extraInfo = data.extraInfo as ExtraInfo;
    } else {
      // 使用空对象字面量，明确类型
      this.extraInfo = {};
    }
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
    // 定义类型优先级 - 使用switch语句替代对象字面量，避免非标识符属性名
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
// 定义SearchResult序列化数据接口
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

  public toSerializable(): SearchResultSerializable {
    // 使用构造函数和逐个属性赋值，避免对象字面量错误
    // 由于SearchResultSerializable是接口，我们创建一个实现该接口的类实例
    class SearchResultSerializableImpl implements SearchResultSerializable {
      id: string = '';
      title: string = '';
      originalTitle?: string;
      type: ResultType = ResultType.OTHER;
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
    
    const result = new SearchResultSerializableImpl();
    result.id = this.id;
    result.title = this.title;
    result.originalTitle = this.originalTitle;
    result.type = this.type;
    result.coverUrl = this.coverUrl;
    result.backdropUrl = this.backdropUrl;
    result.description = this.description;
    result.score = this.score;
    result.year = this.year;
    result.releaseDate = this.releaseDate;
    result.genres = this.genres;
    result.tags = this.tags;
    result.duration = this.duration;
    result.totalEpisodes = this.totalEpisodes;
    result.currentSeason = this.currentSeason;
    result.actors = this.actors;
    result.directors = this.directors;
    result.popularity = this.popularity;
    result.matchScore = this.matchScore;
    result.extraInfo = this.extraInfo;
    result.link = this.link;
    result.sourceId = this.sourceId;
    result.sourceName = this.sourceName;
    
    return result;
  }

  /**
   * 从序列化对象创建SearchResult实例
   * @param data 序列化的数据
   * @returns SearchResult实例
   */
  public static fromSerializable(data: SearchResultSerializable): SearchResult {
    // 直接创建SearchResult实例，手动赋值所有属性
    const instance = new SearchResult({});
    
    // 手动赋值每个属性，确保类型安全
    if (typeof data.id === 'string') instance.id = data.id;
    if (typeof data.title === 'string') instance.title = data.title;
    if (typeof data.originalTitle === 'string') instance.originalTitle = data.originalTitle;
    if (typeof data.type === 'number') instance.type = data.type as ResultType;
    if (typeof data.coverUrl === 'string') instance.coverUrl = data.coverUrl;
    if (typeof data.backdropUrl === 'string') instance.backdropUrl = data.backdropUrl;
    if (typeof data.description === 'string') instance.description = data.description;
    if (typeof data.score === 'number') instance.score = data.score;
    if (typeof data.year === 'number') instance.year = data.year;
    if (typeof data.releaseDate === 'string') instance.releaseDate = data.releaseDate;
    if (Array.isArray(data.genres)) instance.genres = data.genres.filter(item => typeof item === 'string') as string[];
    if (Array.isArray(data.tags)) instance.tags = data.tags.filter(item => typeof item === 'string') as string[];
    if (typeof data.duration === 'number') instance.duration = data.duration;
    if (typeof data.totalEpisodes === 'number') instance.totalEpisodes = data.totalEpisodes;
    if (typeof data.currentSeason === 'number') instance.currentSeason = data.currentSeason;
    if (Array.isArray(data.actors)) instance.actors = data.actors.filter(item => typeof item === 'string') as string[];
    if (Array.isArray(data.directors)) instance.directors = data.directors.filter(item => typeof item === 'string') as string[];
    if (typeof data.popularity === 'number') instance.popularity = data.popularity;
    if (typeof data.matchScore === 'number') instance.matchScore = data.matchScore;
    // 安全处理extraInfo，确保类型正确
    if (data.extraInfo && typeof data.extraInfo === 'object' && !Array.isArray(data.extraInfo)) {
      // 创建一个明确的ExtraInfo对象
      instance.extraInfo = {};
      
      // 检查extraData属性
      const extraInfoData = data.extraInfo as Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>>;
      if (extraInfoData.extraData && typeof extraInfoData.extraData === 'object' && !Array.isArray(extraInfoData.extraData)) {
        instance.extraInfo.extraData = {};
        const extraDataObj = extraInfoData.extraData as Record<string, string | number | boolean | null | Record<string, string | number | boolean | null>>;
        
        // 处理extraData的每个属性
        const extraDataKeys = Object.keys(extraDataObj);
        for (let i = 0; i < extraDataKeys.length; i++) {
          const key = extraDataKeys[i];
          const value = extraDataObj[key];
          
          if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
            instance.extraInfo.extraData![key] = value;
          } else if (value && typeof value === 'object' && !Array.isArray(value)) {
            // 处理嵌套对象
            const nestedInfo: NestedExtraInfo = { nestedData: {} };
            const nestedObj = value as Record<string, string | number | boolean | null>;
            
            const nestedKeys = Object.keys(nestedObj);
            for (let j = 0; j < nestedKeys.length; j++) {
              const nestedKey = nestedKeys[j];
              const nestedValue = nestedObj[nestedKey];
              
              if (typeof nestedValue === 'string' || typeof nestedValue === 'number' || 
                  typeof nestedValue === 'boolean' || nestedValue === null) {
                nestedInfo.nestedData![nestedKey] = nestedValue;
              }
            }
            
            instance.extraInfo.extraData![key] = nestedInfo;
          }
        }
      }
    }
    if (typeof data.link === 'string') instance.link = data.link;
    if (typeof data.sourceId === 'string') instance.sourceId = data.sourceId;
    if (typeof data.sourceName === 'string') instance.sourceName = data.sourceName;
    
    return instance;
  }

  /**
   * 克隆SearchResult实例
   * @returns 克隆后的实例
   */
  public clone(): SearchResult {
    // 手动创建克隆，避免类作为对象使用
    const cloneData: Partial<SearchResult> = {
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
      genres: this.genres ? Array.from(this.genres) : undefined,
      tags: this.tags ? Array.from(this.tags) : undefined,
      duration: this.duration,
      totalEpisodes: this.totalEpisodes,
      currentSeason: this.currentSeason,
      actors: this.actors ? Array.from(this.actors) : undefined,
      directors: this.directors ? Array.from(this.directors) : undefined,
      popularity: this.popularity,
      matchScore: this.matchScore,
      extraInfo: this.extraInfo ? this.cloneExtraInfo(this.extraInfo) : undefined,
      link: this.link,
      sourceId: this.sourceId,
      sourceName: this.sourceName
    };
    return new SearchResult(cloneData);
  }

  /**
   * 克隆ExtraInfo对象
   * @param extraInfo 要克隆的ExtraInfo对象
   * @returns 克隆后的ExtraInfo对象
   */
  private cloneExtraInfo(extraInfo: ExtraInfo): ExtraInfo {
    const cloned: ExtraInfo = {};
    
    if (extraInfo.extraData) {
      cloned.extraData = {};
      // 手动复制extraData中的每个属性
      const keys = Object.keys(extraInfo.extraData);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = extraInfo.extraData[key];
        
        if (value && typeof value === 'object' && !Array.isArray(value)) {
          // 检查是否为NestedExtraInfo类型，通过检查是否有nestedData属性且该属性是对象
          const potentialNested = value as NestedExtraInfo;
          if (potentialNested.nestedData && typeof potentialNested.nestedData === 'object' && !Array.isArray(potentialNested.nestedData)) {
            // 克隆NestedExtraInfo对象
            const nestedCloned: NestedExtraInfo = {};
            nestedCloned.nestedData = {};
            const nestedKeys = Object.keys(potentialNested.nestedData);
            for (let j = 0; j < nestedKeys.length; j++) {
              const nestedKey = nestedKeys[j];
              nestedCloned.nestedData![nestedKey] = potentialNested.nestedData![nestedKey];
            }
            cloned.extraData![key] = nestedCloned;
          } else {
            // 直接复制基本类型值或非NestedExtraInfo对象
            cloned.extraData![key] = value as string | number | boolean | null;
          }
        } else {
          // 直接复制基本类型值
          cloned.extraData![key] = value;
        }
      }
    }
    
    return cloned;
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