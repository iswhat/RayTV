// MovieDetailDto - 电影/视频详情相关数据传输对象 | Movie/video detail related data transfer objects
import { VideoType, VideoQuality, RatingInfo, VideoSource, Episode } from '../model/Movie';
import ApiResponse from './ApiResponse';

/**
 * 演员信息接口 | Actor information interface
 */
export interface Actor {
  id: string;                     // 演员ID | Actor ID
  name: string;                   // 演员名称 | Actor name
  originalName?: string;          // 演员原名 | Actor original name
  role?: string;                  // 扮演角色 | Role name
  avatarUrl?: string;             // 演员头像URL | Actor avatar URL
  country?: string;               // 国家/地区 | Country/region
  birthYear?: number;             // 出生年份 | Birth year
  gender?: 'male' | 'female' | 'other'; // 性别 | Gender
  description?: string;           // 演员简介 | Actor description
}

/**
 * 导演信息接口 | Director information interface
 */
export interface Director {
  id: string;                     // 导演ID | Director ID
  name: string;                   // 导演名称 | Director name
  originalName?: string;          // 导演原名 | Director original name
  avatarUrl?: string;             // 导演头像URL | Director avatar URL
  country?: string;               // 国家/地区 | Country/region
  birthYear?: number;             // 出生年份 | Birth year
  description?: string;           // 导演简介 | Director description
}

/**
 * 编剧信息接口 | Writer information interface
 */
export interface Writer {
  id: string;                     // 编剧ID | Writer ID
  name: string;                   // 编剧名称 | Writer name
  originalName?: string;          // 编剧原名 | Writer original name
  avatarUrl?: string;             // 编剧头像URL | Writer avatar URL
  country?: string;               // 国家/地区 | Country/region
  birthYear?: number;             // 出生年份 | Birth year
  description?: string;           // 编剧简介 | Writer description
}

/**
 * 影视作品公司接口 | Production company interface
 */
export interface ProductionCompany {
  id: string;                     // 公司ID | Company ID
  name: string;                   // 公司名称 | Company name
  logoUrl?: string;               // 公司Logo URL | Company logo URL
  country?: string;               // 公司所在国家/地区 | Company country/region
}

/**
 * 影视作品国家/地区接口 | Production country/region interface
 */
export interface ProductionCountry {
  id: string;                     // 国家/地区ID | Country/region ID
  name: string;                   // 国家/地区名称 | Country/region name
  code?: string;                  // 国家/地区代码 | Country/region code
}

/**
 * 语言信息接口 | Language information interface
 */
export interface LanguageInfo {
  id: string;                     // 语言ID | Language ID
  name: string;                   // 语言名称 | Language name
  code: string;                   // 语言代码 | Language code
  isOriginal?: boolean;           // 是否为原语 | Whether original language
}

/**
 * 图片资源接口 | Image asset interface
 */
export interface ImageAsset {
  id: string;                     // 图片ID | Image ID
  url: string;                    // 图片URL | Image URL
  type: 'poster' | 'backdrop' | 'still' | 'clip' | 'logo' | 'banner' | 'other'; // 图片类型 | Image type
  width?: number;                 // 图片宽度 | Image width
  height?: number;                // 图片高度 | Image height
  aspectRatio?: number;           // 宽高比 | Aspect ratio
  language?: string;              // 图片语言 | Image language
  caption?: string;               // 图片说明 | Image caption
  fileSize?: number;              // 文件大小 | File size
}

/**
 * 视频资源接口 | Video asset interface
 */
export interface VideoAsset {
  id: string;                     // 视频ID | Video ID
  url: string;                    // 视频URL | Video URL
  type: 'trailer' | 'teaser' | 'clip' | 'featurette' | 'behind_the_scenes' | 'other'; // 视频类型 | Video type
  name?: string;                  // 视频名称 | Video name
  description?: string;           // 视频描述 | Video description
  duration?: number;              // 视频时长（秒） | Video duration (seconds)
  thumbnailUrl?: string;          // 缩略图URL | Thumbnail URL
  quality?: VideoQuality;         // 视频质量 | Video quality
  width?: number;                 // 视频宽度 | Video width
  height?: number;                // 视频高度 | Video height
  language?: string;              // 视频语言 | Video language
  publishedAt?: number;           // 发布时间戳 | Published timestamp
  viewCount?: number;             // 观看次数 | View count
}

/**
 * 评论信息接口 | Review information interface
 */
export interface Review {
  id: string;                     // 评论ID | Review ID
  userId: string;                 // 用户ID | User ID
  userName: string;               // 用户名 | User name
  userAvatar?: string;            // 用户头像 | User avatar
  rating: number;                 // 评分（0-10） | Rating (0-10)
  content: string;                // 评论内容 | Review content
  timestamp: number;              // 评论时间戳 | Review timestamp
  likes: number;                  // 点赞数 | Like count
  dislikes: number;               // 点踩数 | Dislike count
  replyCount?: number;            // 回复数 | Reply count
  isSpoiler?: boolean;            // 是否包含剧透 | Whether contains spoiler
  isVerified?: boolean;           // 是否已验证 | Whether verified
}

/**
 * 相关推荐接口 | Related recommendation interface
 */
export interface RelatedItem {
  id: string;                     // 内容ID | Content ID
  title: string;                  // 标题 | Title
  type: VideoType;                // 视频类型 | Video type
  coverUrl: string;               // 封面URL | Cover URL
  rating?: number;                // 评分 | Rating
  releaseYear?: number;           // 发布年份 | Release year
  genres?: string[];              // 类型标签 | Genre tags
  reason?: string;                // 推荐理由 | Recommendation reason
  similarityScore?: number;       // 相似度分数 | Similarity score
}

/**
 * 电影/视频详情数据接口 | Movie/video detail data interface
 */
export interface MovieDetailData {
  // 基本信息 | Basic information
  id: string;                     // 内容ID | Content ID
  title: string;                  // 标题 | Title
  originalTitle?: string;         // 原始标题 | Original title
  subtitle?: string;              // 副标题 | Subtitle
  type: VideoType;                // 视频类型 | Video type
  description: string;            // 简介 | Description
  longDescription?: string;       // 详细介绍 | Detailed description
  
  // 时间信息 | Time information
  releaseYear: number;            // 发布年份 | Release year
  releaseDate?: string;           // 发布日期 | Release date
  runtime: number;                // 时长（分钟） | Runtime (minutes)
  
  // 评分信息 | Rating information
  rating: RatingInfo;             // 评分信息 | Rating information
  votes?: number;                 // 评分人数 | Vote count
  
  // 分类信息 | Category information
  genres: string[];               // 类型标签 | Genre tags
  tags?: string[];                // 其他标签 | Other tags
  
  // 制作信息 | Production information
  directors: Director[];          // 导演列表 | Director list
  writers: Writer[];              // 编剧列表 | Writer list
  actors: Actor[];                // 演员列表 | Actor list
  productionCompanies: ProductionCompany[]; // 制作公司 | Production companies
  productionCountries: ProductionCountry[]; // 制作国家/地区 | Production countries/regions
  
  // 语言信息 | Language information
  languages: LanguageInfo[];      // 语言信息 | Language information
  
  // 媒体资源 | Media assets
  posters: ImageAsset[];          // 海报图片 | Poster images
  backdrops: ImageAsset[];        // 背景图片 | Backdrop images
  stills?: ImageAsset[];          // 剧照 | Still images
  videos: VideoAsset[];           // 视频资源（预告片等） | Video assets (trailers, etc.)
  
  // 内容可用性 | Content availability
  isVip?: boolean;                // 是否VIP内容 | Whether VIP content
  isNew?: boolean;                // 是否新内容 | Whether new content
  isHot?: boolean;                // 是否热门 | Whether hot
  isExclusive?: boolean;          // 是否独家 | Whether exclusive
  
  // 剧集信息（电视剧、动漫等） | Series information (TV shows, anime, etc.)
  totalEpisodes?: number;         // 总集数 | Total episodes
  airedEpisodes?: number;         // 已更新集数 | Aired episodes
  status?: 'ongoing' | 'completed' | 'upcoming'; // 连载状态 | Series status
  seasons?: number;               // 季数 | Season count
  currentSeason?: number;         // 当前季 | Current season
  
  // 技术信息 | Technical information
  aspectRatio?: number;           // 画面比例 | Aspect ratio
  colorInfo?: string;             // 色彩信息 | Color information
  soundMix?: string;              // 音效混音 | Sound mix
  
  // 外部链接 | External links
  imdbId?: string;                // IMDB ID
  tmdbId?: string;                // TMDB ID
  doubanId?: string;              // 豆瓣 ID
  
  // 来源信息 | Source information
  provider?: string;              // 内容提供商 | Content provider
  providerId?: string;            // 提供商ID | Provider ID
  sourceUpdatedAt?: number;       // 来源更新时间 | Source update time
  
  // 观看统计 | Viewing statistics
  viewCount?: number;             // 观看次数 | View count
  favoriteCount?: number;         // 收藏次数 | Favorite count
  commentCount?: number;          // 评论次数 | Comment count
  
  // 附加信息 | Additional information
  isFavorite?: boolean;           // 当前用户是否已收藏 | Whether current user has favorited
  watchProgress?: number;         // 观看进度 | Watch progress
  lastWatchTime?: number;         // 最后观看时间 | Last watch time
  
  // 播放源信息 | Playback source information
  sources: VideoSource[];         // 播放源列表 | Playback source list
  
  // 剧集信息（电视剧、动漫等） | Episode information (TV shows, anime, etc.)
  episodes?: Episode[];           // 剧集列表 | Episode list
  
  // 相关内容 | Related content
  related?: RelatedItem[];        // 相关推荐 | Related recommendations
  recommendations?: RelatedItem[]; // 推荐内容 | Recommended content
  similar?: RelatedItem[];        // 相似内容 | Similar content
  
  // 评论信息 | Review information
  reviews?: Review[];             // 评论列表 | Review list
  
  // 附加参数 | Additional parameters
  metadata?: Record<string, string | number | boolean | null>; // 额外参数 | Extra parameters
}

/**
 * 电影/视频详情API响应 | Movie/video detail API response
 */
export type MovieDetailApiResponse = ApiResponse<MovieDetailData>;

/**
 * 剧集列表响应接口 | Episode list response interface
 */
export interface EpisodesResponseData {
  id: string;                     // 内容ID | Content ID
  title: string;                  // 标题 | Title
  season: number;                 // 季数 | Season number
  totalEpisodes: number;          // 总集数 | Total episodes
  airedEpisodes: number;          // 已更新集数 | Aired episodes
  episodes: Episode[];            // 剧集列表 | Episode list
  hasMore: boolean;               // 是否有更多 | Whether has more
  nextPage?: number;              // 下一页页码 | Next page number
}

/**
 * 剧集列表API响应 | Episode list API response
 */
export type EpisodesApiResponse = ApiResponse<EpisodesResponseData>;

/**
 * 视频源请求参数接口 | Video source request parameters interface
 */
export interface VideoSourceRequest {
  contentId: string;              // 内容ID | Content ID
  episodeId?: string;             // 剧集ID（可选，针对电视剧等） | Episode ID (optional, for TV shows, etc.)
  season?: number;                // 季数（可选） | Season number (optional)
  episode?: number;               // 集数（可选） | Episode number (optional)
  preferredQuality?: VideoQuality; // 首选画质 | Preferred quality
  preferredLanguage?: string;     // 首选语言 | Preferred language
  providerId?: string;            // 提供商ID | Provider ID
}

/**
 * 视频源响应数据接口 | Video source response data interface
 */
export interface VideoSourcesResponseData {
  contentId: string;              // 内容ID | Content ID
  sources: VideoSource[];         // 视频源列表 | Video source list
  defaultSource?: string;         // 默认视频源ID | Default video source ID
  fallbackSource?: string;        // 备用视频源ID | Fallback video source ID
  availableQualities: VideoQuality[]; // 可用画质列表 | Available quality list
  availableLanguages: string[];   // 可用语言列表 | Available language list
}

/**
 * 视频源API响应 | Video source API response
 */
export type VideoSourcesApiResponse = ApiResponse<VideoSourcesResponseData>;

/**
 * 视频播放状态接口 | Video playback state interface
 */
export interface PlaybackState {
  contentId: string;              // 内容ID | Content ID
  episodeId?: string;             // 剧集ID | Episode ID
  position: number;               // 播放位置（毫秒） | Playback position (milliseconds)
  duration: number;               // 总时长（秒） | Total duration (seconds)
  completed: boolean;             // 是否已播放完成 | Whether playback completed
  quality?: VideoQuality;         // 播放画质 | Playback quality
  language?: string;              // 播放语言 | Playback language
  volume?: number;                // 音量 | Volume
  muted?: boolean;                // 是否静音 | Whether muted
  timestamp: number;              // 更新时间戳 | Update timestamp
  sourceId?: string;              // 播放源ID | Playback source ID
}

/**
 * 视频播放状态API响应 | Video playback state API response
 */
export type PlaybackStateApiResponse = ApiResponse<PlaybackState>;

/**
 * 收藏状态接口 | Favorite state interface
 */
export interface FavoriteState {
  contentId: string;              // 内容ID | Content ID
  isFavorite: boolean;            // 是否收藏 | Whether favorited
  favoriteAt?: number;            // 收藏时间戳 | Favorite timestamp
  note?: string;                  // 收藏备注 | Favorite note
  tags?: string[];                // 收藏标签 | Favorite tags
  rating?: number;                // 用户评分 | User rating
}

/**
 * 收藏状态API响应 | Favorite state API response
 */
export type FavoriteStateApiResponse = ApiResponse<FavoriteState>;

/**
 * 评论请求参数接口 | Reviews request parameters interface
 */
export interface ReviewsRequest {
  contentId: string;              // 内容ID | Content ID
  page: number;                   // 页码 | Page number
  pageSize: number;               // 每页大小 | Page size
  sort?: 'newest' | 'highest' | 'lowest' | 'most_liked'; // 排序方式 | Sorting method
  minRating?: number;             // 最低评分 | Minimum rating
  maxRating?: number;             // 最高评分 | Maximum rating
  includeSpoilers?: boolean;      // 是否包含剧透 | Whether include spoilers
}

/**
 * 评论列表响应接口 | Reviews list response interface
 */
export interface ReviewsResponseData {
  contentId: string;              // 内容ID | Content ID
  reviews: Review[];              // 评论列表 | Review list
  total: number;                  // 总评论数 | Total review count
  page: number;                   // 当前页码 | Current page number
  pageSize: number;               // 每页大小 | Page size
  totalPages: number;             // 总页数 | Total page count
  hasMore: boolean;               // 是否有更多 | Whether has more
  averageRating?: number;         // 平均评分 | Average rating
}

/**
 * 评论列表API响应 | Reviews list API response
 */
export type ReviewsApiResponse = ApiResponse<ReviewsResponseData>;

/**
 * 电影详情相关的工具方法 | Movie detail related utility methods
 */
export class MovieDetailUtils {
  /**
   * 获取电影/视频的显示标题 | Get display title of movie/video
   */
  static getDisplayName(movie: Partial<MovieDetailData>): string {
    if (movie.title && movie.originalTitle && movie.title !== movie.originalTitle) {
      return `${movie.title} / ${movie.originalTitle}`;
    }
    return movie.title || movie.originalTitle || '未知标题';
  }

  /**
   * 获取发布年份的显示文本 | Get display text for release year
   */
  static getReleaseYearText(movie: Partial<MovieDetailData>): string {
    if (movie.releaseDate) {
      const date = new Date(movie.releaseDate);
      return date.getFullYear().toString();
    }
    return movie.releaseYear?.toString() || '未知';
  }

  /**
   * 获取时长的显示文本 | Get display text for duration
   */
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
   * 获取评分的显示文本 | Get display text for rating
   */
  static getRatingText(rating: RatingInfo): string {
    if (rating.score !== null && rating.score !== undefined) {
      return rating.score.toFixed(1);
    }
    return '暂无评分';
  }

  /**
   * 获取演员列表的显示文本 | Get display text for actor list
   */
  static getActorsText(actors: Actor[], maxCount: number = 5): string {
    if (!actors || actors.length === 0) {
      return '未知';
    }
    const displayNames = actors.slice(0, maxCount).map(actor => actor.name);
    if (actors.length > maxCount) {
      displayNames.push('等');
    }
    return displayNames.join('、');
  }

  /**
   * 获取导演列表的显示文本 | Get display text for director list
   */
  static getDirectorsText(directors: Director[]): string {
    if (!directors || directors.length === 0) {
      return '未知';
    }
    return directors.map(director => director.name).join('、');
  }

  /**
   * 获取类型标签的显示文本 | Get display text for genre tags
   */
  static getGenresText(genres: string[]): string {
    return genres?.join(' / ') || '未知类型';
  }

  /**
   * 获取第一张海报URL | Get first poster URL
   */
  static getFirstPosterUrl(posters: ImageAsset[]): string | undefined {
    return posters && posters.length > 0 ? posters[0].url : undefined;
  }

  /**
   * 获取第一张背景图URL | Get first backdrop URL
   */
  static getFirstBackdropUrl(backdrops: ImageAsset[]): string | undefined {
    return backdrops && backdrops.length > 0 ? backdrops[0].url : undefined;
  }

  /**
   * 获取第一个预告片URL | Get first trailer URL
   */
  static getFirstTrailerUrl(videos: VideoAsset[]): string | undefined {
    if (!videos || videos.length === 0) {
      return undefined;
    }
    const trailer = videos.find(video => video.type === 'trailer');
    return trailer?.url || videos[0].url;
  }

  /**
   * 获取观看进度百分比 | Get watch progress percentage
   */
  static getWatchProgressPercentage(state: PlaybackState): number {
    if (!state || !state.duration || state.duration <= 0) {
      return 0;
    }
    return Math.min(100, Math.max(0, (state.position / state.duration) * 100));
  }

  /**
   * 检查是否有未观看完的进度 | Check if has unwatched progress
   */
  static hasUnwatchedProgress(state: PlaybackState | undefined): boolean {
    if (!state || state.completed) {
      return false;
    }
    // 进度超过5%且未完成视为有未观看完的进度
    const percentage = this.getWatchProgressPercentage(state);
    return percentage >= 5 && percentage < 95;
  }
}
