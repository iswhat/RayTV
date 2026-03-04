/**
 * 统一媒体内容数据模型 | Unified Media Content Data Model
 * 壳应用的核心数据结构定义 | Core data structure definitions for shell applications
 */

// 媒体类型枚举 | Media type enum
export enum MediaType {
  MOVIE = 'movie',
  TV_SHOW = 'tv_show',
  ANIME = 'anime',
  VARIETY = 'variety',
  DOCUMENTARY = 'documentary',
  LIVE = 'live'
}

// 视频质量枚举 | Video quality enum
export enum VideoQuality {
  SD = 'sd',      // 480p
  HD = 'hd',      // 720p
  FHD = 'fhd',    // 1080p
  QHD = 'qhd',    // 1440p
  UHD = 'uhd',    // 4K
  AUTO = 'auto'   // 自动选择 | Auto select
}

// 可用性状态枚举 | Availability status enum
export enum AvailabilityStatus {
  AVAILABLE = 'available',
  UNAVAILABLE = 'unavailable',
  TEMPORARY_UNAVAILABLE = 'temporary_unavailable',
  REGION_LOCKED = 'region_locked'
}

// 统一媒体内容接口 | Unified media content interface
export interface UnifiedMediaContent {
  // 基础信息 | Basic information
  id: string;
  title: string;
  originalTitle?: string;
  cover: string;
  description?: string;
  
  // 分类信息 | Classification information
  type: MediaType;
  genres: string[];
  categories: string[];
  
  // 时间信息 | Time information
  year?: number;
  releaseDate?: string;
  lastUpdated: number;
  
  // 评分信息 | Rating information
  rating?: number;
  ratingCount?: number;
  popularityScore: number;
  recommendationScore: number;
  
  // 技术信息 | Technical information
  duration?: number; // 分钟 | Minutes
  quality: VideoQuality;
  languages: string[];
  regions: string[];
  
  // 人员信息 | Personnel information
  actors?: string[];
  directors?: string[];
  writers?: string[];
  producers?: string[];
  
  // 来源信息 | Source information
  sourceInfo: SourceInfo;
  availability: AvailabilityStatus;
  
  // 扩展信息 | Extended information
  tags?: string[];
  awards?: string[];
  plotSummary?: string;
  trailerUrl?: string;
}

// 来源信息接口 | Source information interface
export interface SourceInfo {
  sourceIds: string[]; // 来自多个配置源的ID | IDs from multiple config sources
  sourceUrls: string[]; // 配置源URL | Config source URLs
  sourceNames: string[]; // 配置源名称 | Config source names
  primarySource: string; // 主要来源 | Primary source
  confidenceScore: number; // 置信度评分 | Confidence score
  lastSynced: number; // 最后同步时间 | Last sync time
}

// 剧集信息接口 | Episode information interface
export interface EpisodeInfo {
  id: string;
  title: string;
  episodeNumber: number;
  seasonNumber?: number;
  airDate?: string;
  description?: string;
  duration?: number;
  cover?: string;
  quality: VideoQuality;
  availability: AvailabilityStatus;
  sourceEpisodeId: string; // 原始剧集ID | Original episode ID
}

// 季信息接口 | Season information interface
export interface SeasonInfo {
  id: string;
  title: string;
  seasonNumber: number;
  episodeCount: number;
  episodes: EpisodeInfo[];
  cover?: string;
  description?: string;
  airDate?: string;
}

// 搜索结果接口 | Search result interface
export interface SearchResult {
  contents: UnifiedMediaContent[];
  totalCount: number;
  currentPage: number;
  totalPages: number;
  hasNextPage: boolean;
  query: string;
  searchTime: number;
  filtersApplied: SearchFilters;
}

// 搜索过滤器接口 | Search filters interface
export interface SearchFilters {
  type?: MediaType[];
  genre?: string[];
  year?: { min: number; max: number };
  rating?: { min: number; max: number };
  quality?: VideoQuality[];
  language?: string[];
  region?: string[];
  availability?: AvailabilityStatus[];
}

// 用户偏好接口 | User preferences interface
export interface UserPreferences {
  favoriteGenres: string[];
  favoriteActors: string[];
  favoriteDirectors: string[];
  preferredQuality: VideoQuality;
  preferredLanguages: string[];
  excludeGenres: string[];
  excludeActors: string[];
  maxRatingThreshold?: number;
  minRatingThreshold?: number;
}

// 播放历史记录接口 | Playback history interface
export interface PlaybackHistory {
  id: string;
  contentId: string;
  title: string;
  cover: string;
  type: MediaType;
  lastPosition: number; // 秒 | Seconds
  duration: number; // 秒 | Seconds
  progress: number; // 百分比 | Percentage
  watchedAt: number;
  completed: boolean;
  quality: VideoQuality;
  sourceUrl: string;
}

// 收藏内容接口 | Favorite content interface
export interface FavoriteContent {
  id: string;
  contentId: string;
  title: string;
  cover: string;
  type: MediaType;
  addedAt: number;
  notes?: string;
  tags?: string[];
}

// 推荐内容接口 | Recommended content interface
export interface RecommendedContent {
  content: UnifiedMediaContent;
  recommendationReason: string;
  similarityScore: number;
  recommendationType: 'popular' | 'similar' | 'personalized' | 'trending';
  sourceAlgorithm: string;
}

// 内容统计接口 | Content statistics interface
export interface ContentStatistics {
  totalContents: number;
  contentsByType: Record<MediaType, number>;
  contentsByQuality: Record<VideoQuality, number>;
  contentsByAvailability: Record<AvailabilityStatus, number>;
  averageRating: number;
  totalViews: number;
  totalWatchTime: number; // 小时 | Hours
  lastUpdated: number;
}