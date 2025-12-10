// MovieDetailDto - 电影/视频详情相关数据传输对象
import { VideoType, VideoQuality, RatingInfo, VideoSource, Episode } from '../model/Movie';
import ApiResponse from './ApiResponse';

/**
 * 演员信息接口
 */
export interface Actor {
  id: string;                     // 演员ID
  name: string;                   // 演员名称
  originalName?: string;          // 演员原名
  role?: string;                  // 角色名称
  avatarUrl?: string;             // 演员头像URL
  country?: string;               // 国家/地区
  birthYear?: number;             // 出生年份
  gender?: 'male' | 'female' | 'other'; // 性别
  description?: string;           // 演员简�?}

/**
 * 导演信息接口
 */
export interface Director {
  id: string;                     // 导演ID
  name: string;                   // 导演名称
  originalName?: string;          // 导演原名
  avatarUrl?: string;             // 导演头像URL
  country?: string;               // 国家/地区
  birthYear?: number;             // 出生年份
  description?: string;           // 导演简�?}

/**
 * 编剧信息接口
 */
export interface Writer {
  id: string;                     // 编剧ID
  name: string;                   // 编剧名称
  originalName?: string;          // 编剧原名
  avatarUrl?: string;             // 编剧头像URL
  country?: string;               // 国家/地区
  birthYear?: number;             // 出生年份
  description?: string;           // 编剧简�?}

/**
 * 影视制作公司接口
 */
export interface ProductionCompany {
  id: string;                     // 公司ID
  name: string;                   // 公司名称
  logoUrl?: string;               // 公司Logo URL
  country?: string;               // 公司所在国�?地区
}

/**
 * 影视制作国家/地区接口
 */
export interface ProductionCountry {
  id: string;                     // 国家/地区ID
  name: string;                   // 国家/地区名称
  code?: string;                  // 国家/地区代码
}

/**
 * 语言信息接口
 */
export interface LanguageInfo {
  id: string;                     // 语言ID
  name: string;                   // 语言名称
  code: string;                   // 语言代码
  isOriginal?: boolean;           // 是否为原�?}

/**
 * 图片资源接口
 */
export interface ImageAsset {
  id: string;                     // 图片ID
  url: string;                    // 图片URL
  type: 'poster' | 'backdrop' | 'still' | 'clip' | 'logo' | 'banner' | 'other'; // 图片类型
  width?: number;                 // 图片宽度
  height?: number;                // 图片高度
  aspectRatio?: number;           // 宽高�?  language?: string;              // 图片语言
  caption?: string;               // 图片说明
  fileSize?: number;              // 文件大小
}

/**
 * 视频资源接口
 */
export interface VideoAsset {
  id: string;                     // 视频ID
  url: string;                    // 视频URL
  type: 'trailer' | 'teaser' | 'clip' | 'featurette' | 'behind_the_scenes' | 'other'; // 视频类型
  name?: string;                  // 视频名称
  description?: string;           // 视频描述
  duration?: number;              // 视频时长（秒�?  thumbnailUrl?: string;          // 缩略图URL
  quality?: VideoQuality;         // 视频质量
  width?: number;                 // 视频宽度
  height?: number;                // 视频高度
  language?: string;              // 视频语言
  publishedAt?: number;           // 发布时间�?  viewCount?: number;             // 观看次数
}

/**
 * 评论信息接口
 */
export interface Review {
  id: string;                     // 评论ID
  userId: string;                 // 用户ID
  userName: string;               // 用户�?  userAvatar?: string;            // 用户头像
  rating: number;                 // 评分�?-10�?  content: string;                // 评论内容
  timestamp: number;              // 评论时间�?  likes: number;                  // 点赞�?  dislikes: number;               // 点踩�?  replyCount?: number;            // 回复�?  isSpoiler?: boolean;            // 是否包含剧�?  isVerified?: boolean;           // 是否已验�?}

/**
 * 相关推荐接口
 */
export interface RelatedItem {
  id: string;                     // 内容ID
  title: string;                  // 标题
  type: VideoType;                // 视频类型
  coverUrl: string;               // 封面URL
  rating?: number;                // 评分
  releaseYear?: number;           // 发行年份
  genres?: string[];              // 类型标签
  reason?: string;                // 推荐理由
  similarityScore?: number;       // 相似度分�?}

/**
 * 电影/视频详情数据接口
 */
export interface MovieDetailData {
  // 基本信息
  id: string;                     // 内容ID
  title: string;                  // 标题
  originalTitle?: string;         // 原始标题
  subtitle?: string;              // 副标�?  type: VideoType;                // 视频类型
  description: string;            // 简�?  longDescription?: string;       // 详细介绍
  
  // 时间信息
  releaseYear: number;            // 发行年份
  releaseDate?: string;           // 发行日期
  runtime: number;                // 时长（分钟）
  
  // 评分信息
  rating: RatingInfo;             // 评分信息
  votes?: number;                 // 评分人数
  
  // 分类信息
  genres: string[];               // 类型标签
  tags?: string[];                // 其他标签
  
  // 制作信息
  directors: Director[];          // 导演列表
  writers: Writer[];              // 编剧列表
  actors: Actor[];                // 演员列表
  productionCompanies: ProductionCompany[]; // 制作公司
  productionCountries: ProductionCountry[]; // 制作国家/地区
  
  // 语言信息
  languages: LanguageInfo[];      // 语言信息
  
  // 媒体资源
  posters: ImageAsset[];          // 海报图片
  backdrops: ImageAsset[];        // 背景图片
  stills?: ImageAsset[];          // 剧照
  videos: VideoAsset[];           // 视频资源（预告片等）
  
  // 内容可用�?  isVip?: boolean;                // 是否VIP内容
  isNew?: boolean;                // 是否新内�?  isHot?: boolean;                // 是否热门
  isExclusive?: boolean;          // 是否独家
  
  // 系列信息（电视剧、动漫等�?  totalEpisodes?: number;         // 总集�?  airedEpisodes?: number;         // 已更新集�?  status?: 'ongoing' | 'completed' | 'upcoming'; // 连载状�?  seasons?: number;               // 季数
  currentSeason?: number;         // 当前�?  
  // 技术信�?  aspectRatio?: number;           // 画面比例
  colorInfo?: string;             // 色彩信息
  soundMix?: string;              // 音效混音
  
  // 外部链接
  imdbId?: string;                // IMDB ID
  tmdbId?: string;                // TMDB ID
  doubanId?: string;              // 豆瓣 ID
  
  // 来源信息
  provider?: string;              // 内容提供�?  providerId?: string;            // 提供商ID
  sourceUpdatedAt?: number;       // 来源更新时间
  
  // 观看统计
  viewCount?: number;             // 观看次数
  favoriteCount?: number;         // 收藏次数
  commentCount?: number;          // 评论次数
  
  // 附加信息
  isFavorite?: boolean;           // 当前用户是否已收�?  watchProgress?: number;         // 观看进度
  lastWatchTime?: number;         // 最后观看时�?  
  // 播放源信�?  sources: VideoSource[];         // 播放源列�?  
  // 剧集信息（针对电视剧、动漫等�?  episodes?: Episode[];           // 剧集列表
  
  // 相关内容
  related?: RelatedItem[];        // 相关推荐
  recommendations?: RelatedItem[]; // 推荐内容
  similar?: RelatedItem[];        // 相似内容
  
  // 评论信息
  reviews?: Review[];             // 评论列表
  
  // 附加元数�?  metadata?: Record<string, string | number | boolean | null>; // 额外元数�?}

/**
 * 电影/视频详情API响应
 */
export type MovieDetailApiResponse = ApiResponse<MovieDetailData>;

/**
 * 剧集列表响应接口
 */
export interface EpisodesResponseData {
  id: string;                     // 内容ID
  title: string;                  // 标题
  season: number;                 // 季数
  totalEpisodes: number;          // 总集�?  airedEpisodes: number;          // 已更新集�?  episodes: Episode[];            // 剧集列表
  hasMore: boolean;               // 是否有更�?  nextPage?: number;              // 下一页页�?}

/**
 * 剧集列表API响应
 */
export type EpisodesApiResponse = ApiResponse<EpisodesResponseData>;

/**
 * 视频源请求参数接�? */
export interface VideoSourceRequest {
  contentId: string;              // 内容ID
  episodeId?: string;             // 剧集ID（可选，针对电视剧等�?  season?: number;                // 季数（可选）
  episode?: number;               // 集数（可选）
  preferredQuality?: VideoQuality; // 首选画�?  preferredLanguage?: string;     // 首选语言
  providerId?: string;            // 提供商ID
}

/**
 * 视频源响应接�? */
export interface VideoSourcesResponseData {
  contentId: string;              // 内容ID
  sources: VideoSource[];         // 视频源列�?  defaultSource?: string;         // 默认视频源ID
  fallbackSource?: string;        // 备用视频源ID
  availableQualities: VideoQuality[]; // 可用画质列表
  availableLanguages: string[];   // 可用语言列表
}

/**
 * 视频源API响应
 */
export type VideoSourcesApiResponse = ApiResponse<VideoSourcesResponseData>;

/**
 * 视频播放状态接�? */
export interface PlaybackState {
  contentId: string;              // 内容ID
  episodeId?: string;             // 剧集ID
  position: number;               // 播放位置（毫秒）
  duration: number;               // 总时长（毫秒�?  completed: boolean;             // 是否播放完成
  quality?: VideoQuality;         // 播放画质
  language?: string;              // 播放语言
  volume?: number;                // 音量
  muted?: boolean;                // 是否静音
  timestamp: number;              // 更新时间�?  sourceId?: string;              // 播放源ID
}

/**
 * 视频播放状态API响应
 */
export type PlaybackStateApiResponse = ApiResponse<PlaybackState>;

/**
 * 收藏状态接�? */
export interface FavoriteState {
  contentId: string;              // 内容ID
  isFavorite: boolean;            // 是否收藏
  favoriteAt?: number;            // 收藏时间�?  note?: string;                  // 收藏备注
  tags?: string[];                // 收藏标签
  rating?: number;                // 用户评分
}

/**
 * 收藏状态API响应
 */
export type FavoriteStateApiResponse = ApiResponse<FavoriteState>;

/**
 * 评论请求参数接口
 */
export interface ReviewsRequest {
  contentId: string;              // 内容ID
  page: number;                   // 页码
  pageSize: number;               // 每页大小
  sort?: 'newest' | 'highest' | 'lowest' | 'most_liked'; // 排序方式
  minRating?: number;             // 最低评�?  maxRating?: number;             // 最高评�?  includeSpoilers?: boolean;      // 是否包含剧�?}

/**
 * 评论列表响应接口
 */
export interface ReviewsResponseData {
  contentId: string;              // 内容ID
  reviews: Review[];              // 评论列表
  total: number;                  // 总评论数
  page: number;                   // 当前页码
  pageSize: number;               // 每页大小
  totalPages: number;             // 总页�?  hasMore: boolean;               // 是否有更�?  averageRating?: number;         // 平均评分
}

/**
 * 评论列表API响应
 */
export type ReviewsApiResponse = ApiResponse<ReviewsResponseData>;

/**
 * 电影详情相关的工具方�? */
export class MovieDetailUtils {
  /**
   * 获取电影/视频的显示标�?   */
  static getDisplayName(movie: Partial<MovieDetailData>): string {
    if (movie.title && movie.originalTitle && movie.title !== movie.originalTitle) {
      return `${movie.title} / ${movie.originalTitle}`;
    }
    return movie.title || movie.originalTitle || '未知标题';
  }

  /**
   * 获取发布年份的显示文�?   */
  static getReleaseYearText(movie: Partial<MovieDetailData>): string {
    if (movie.releaseDate) {
      const date = new Date(movie.releaseDate);
      return date.getFullYear().toString();
    }
    return movie.releaseYear?.toString() || '未知';
  }

  /**
   * 获取时长的显示文�?   */
  static getDurationText(movie: Partial<MovieDetailData>): string {
    if (movie.runtime) {
      const hours = Math.floor(movie.runtime / 60);
      const minutes = movie.runtime % 60;
      if (hours > 0) {
        return `${hours}小时${minutes > 0 ? minutes + '分钟' : ''}`;
      }
      return `${minutes}分钟`;
    }
    return '未知时长';
  }

  /**
   * 获取评分的显示文�?   */
  static getRatingText(rating: RatingInfo): string {
    if (rating.score !== null && rating.score !== undefined) {
      return rating.score.toFixed(1);
    }
    return '暂无评分';
  }

  /**
   * 获取演员列表的显示文�?   */
  static getActorsText(actors: Actor[], maxCount: number = 5): string {
    if (!actors || actors.length === 0) {
      return '未知';
    }
    const displayNames = actors.slice(0, maxCount).map(actor => actor.name);
    if (actors.length > maxCount) {
      displayNames.push('�?);
    }
    return displayNames.join('�?);
  }

  /**
   * 获取导演列表的显示文�?   */
  static getDirectorsText(directors: Director[]): string {
    if (!directors || directors.length === 0) {
      return '未知';
    }
    return directors.map(director => director.name).join('�?);
  }

  /**
   * 获取类型标签的显示文�?   */
  static getGenresText(genres: string[]): string {
    return genres?.join(' / ') || '未知类型';
  }

  /**
   * 获取第一张海报URL
   */
  static getFirstPosterUrl(posters: ImageAsset[]): string | undefined {
    return posters && posters.length > 0 ? posters[0].url : undefined;
  }

  /**
   * 获取第一张背景图片URL
   */
  static getFirstBackdropUrl(backdrops: ImageAsset[]): string | undefined {
    return backdrops && backdrops.length > 0 ? backdrops[0].url : undefined;
  }

  /**
   * 获取第一个预告片URL
   */
  static getFirstTrailerUrl(videos: VideoAsset[]): string | undefined {
    if (!videos || videos.length === 0) {
      return undefined;
    }
    const trailer = videos.find(video => video.type === 'trailer');
    return trailer?.url || videos[0].url;
  }

  /**
   * 获取观看进度百分�?   */
  static getWatchProgressPercentage(state: PlaybackState): number {
    if (!state || !state.duration || state.duration <= 0) {
      return 0;
    }
    return Math.min(100, Math.max(0, (state.position / state.duration) * 100));
  }

  /**
   * 检查是否有未观看完的进�?   */
  static hasUnwatchedProgress(state: PlaybackState | undefined): boolean {
    if (!state || state.completed) {
      return false;
    }
    // 进度超过5%且未完成视为有未观看完的进度
    const percentage = this.getWatchProgressPercentage(state);
    return percentage >= 5 && percentage < 95;
  }
}
