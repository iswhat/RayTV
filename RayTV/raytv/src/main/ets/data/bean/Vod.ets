/**
 * Vod - VOD content data types | 点播内容数据类型
 * Define basic information and structures for VOD content | 定义点播内容的基本信息和结构
 */

/**
 * Episode information interface | 剧集信息接口
 */
export interface Episode {
  id: string;          // Episode ID | 剧集ID
  name: string;        // Episode name | 剧集名称
  url: string;         // Episode playback URL | 剧集播放URL
  source?: string;     // Source identifier | 来源标识
  isNew?: boolean;     // Whether it's a new episode | 是否新剧
  isPlayed?: boolean;  // Whether it's played | 是否已播放
  progress?: number;   // Playback progress (percentage) | 播放进度(百分比)
  duration?: number;   // Total duration (seconds) | 总时长(秒)
}

/**
 * Actor information interface | 演员信息接口
 */
export interface Actor {
  id: string;          // Actor ID | 演员ID
  name: string;        // Actor name | 演员名称
  avatar?: string;     // Actor avatar URL | 演员头像URL
  role?: string;       // Role played | 饰演角色
}

/**
 * Director information interface | 导演信息接口
 */
export interface Director {
  id: string;          // Director ID | 导演ID
  name: string;        // Director name | 导演名称
  avatar?: string;     // Director avatar URL | 导演头像URL
}

/**
 * Recommendation reason interface | 推荐理由接口
 */
export interface RecommendReason {
  type: string;        // Recommendation type | 推荐类型
  content: string;     // Recommendation content | 推荐内容
  priority?: number;   // Priority level (higher number means higher priority) | 优先等级(数字越大越优先)
}

/**
 * VOD content data type | 点播内容数据类型
 */
export interface Vod {
  id: string;                   // Content unique ID | 内容唯一ID
  name: string;                 // Content name | 内容名称
  type: string;                 // Type (movie, TV series, etc.) | 类型(电影、电视剧等)
  area: string;                 // Area | 地区
  lang: string;                 // Language | 语言
  year: string;                 // Year | 年份
  score: string;                // Score | 评分
  status: string;               // Status (serializing, completed) | 状态(连载中、已完结)
  desc: string;                 // Brief description | 简要描述
  cover: string;                // Cover image URL | 封面图URL
  tag: string;                  // Tag | 标签
  url: string;                  // Content detail page URL | 内容详情页URL
  sourceKey: string;            // Data source identifier | 数据源标识
  episodeList?: Episode[];      // Episode list | 剧集列表
  selectedEpisode?: number;     // Currently selected episode | 当前选中剧集
  createdAt: number;            // Creation time | 创建时间
  updatedAt: number;            // Update time | 更新时间
  actors?: Actor[];             // Actor list | 演员列表
  directors?: Director[];       // Director list | 导演列表
  recommendReasons?: RecommendReason[]; // Recommendation reasons | 推荐理由
  isVip?: boolean;              // Whether it's VIP content | 是否VIP内容
  isPay?: boolean;              // Whether it's paid content | 是否付费内容
  originalPrice?: number;       // Original price | 原价
  currentPrice?: number;        // Current price | 当前价格
  isCollect?: boolean;          // Whether it's collected | 是否已收藏
  playCount?: number;           // Play count | 播放次数
  collectCount?: number;        // Collect count | 收藏次数
  commentCount?: number;        // Comment count | 评论次数
  sourceList?: Map<string, Episode[]>; // Multi-source episode list | 多来源剧集列表
  subTitleList?: string[];      // Subtitle list | 字幕列表
  videoQualityList?: string[];  // Video quality options | 画质选项
  isHdr?: boolean;              // Whether HDR is supported | 是否支持HDR
  isDolby?: boolean;            // Whether Dolby sound is supported | 是否支持杜比音效
  is3D?: boolean;               // Whether it's 3D content | 是否3D内容
  imdbId?: string;              // IMDB ID
  doubanId?: string;            // Douban ID | 豆瓣ID
  tmdbId?: string;              // TMDB ID
  backdrop?: string;            // Backdrop image URL | 背景图URL
  previewVideo?: string;        // Trailer URL | 预告片URL
  relatedVods?: string[];       // Related content ID list | 相关内容ID列表
  userRating?: number;          // User rating | 用户评分
  categoryIds?: string[];       // Category ID list | 分类ID列表
  seasonInfo?: SeasonInfo;            // Season information | 季数信息
  episodeInfo?: EpisodeInfo;          // Episode information | 集数信息
  playHistory?: PlayHistory;          // Play history information | 播放历史信息
}

/**
 * VOD content search result interface | 点播内容搜索结果接口
 */
export interface VodSearchResult {
  vods: Vod[];                  // Search result content list | 搜索到的内容列表
  total: number;                // Total count | 总数
  page: number;                 // Current page number | 当前页码
  pageSize: number;             // Page size | 每页数量
  hasMore: boolean;             // Whether there are more results | 是否有更多
  keyword?: string;             // Search keyword | 搜索关键词
  category?: string;            // Category filter | 分类筛选
  area?: string;                // Area filter | 地区筛选
  year?: string;                // Year filter | 年份筛选
  sortBy?: string;              // Sorting method | 排序方式
}

/**
 * VOD content recommendation interface | 点播内容推荐接口
 */
export interface VodRecommendation {
  id: string;                   // Recommendation ID | 推荐ID
  title: string;                // Recommendation title | 推荐标题
  subtitle?: string;            // Recommendation subtitle | 推荐副标题
  vods: Vod[];                  // Recommended content list | 推荐内容列表
  type: string;                 // Recommendation type | 推荐类型
  refreshInterval?: number;     // Refresh interval (milliseconds) | 更新间隔(毫秒)
  coverImage?: string;          // Cover image | 封面
  priority: number;             // Priority level | 优先等级
  createdAt: number;            // Creation time | 创建时间
  updatedAt: number;            // Update time | 更新时间
}

/**
 * Content tag interface | 内容标签接口
 */
export interface ContentTag {
  id: string;                   // Tag ID | 标签ID
  name: string;                 // Tag name | 标签名称
  count?: number;               // Usage count | 使用次数
  category?: string;            // Tag category | 标签分类
}

/**
 * Content filter condition interface | 内容筛选条件接口
 */
export interface VodFilter {
  category?: string;            // Category | 分类
  area?: string;                // Area | 地区
  year?: string;                // Year | 年份
  status?: string;              // Status | 状态
  tag?: string;                 // Tag | 标签
  sortBy?: string;              // Sorting method | 排序方式
  keyword?: string;             // Keyword | 关键词
  page?: number;                // Page number | 页码
  pageSize?: number;            // Page size | 每页数量
  sourceKey?: string;           // Data source identifier | 数据源标识
  isVip?: boolean;              // Whether it's VIP | 是否VIP
}

/**
 * Content detail request parameter interface | 内容详情请求参数接口
 */
export interface VodDetailRequest {
  id: string;                   // Content ID | 内容ID
  sourceKey: string;            // Data source identifier | 数据源标识
  includeEpisodes?: boolean;    // Whether to include episode list | 是否包含剧集列表
  includeRelated?: boolean;     // Whether to include related content | 是否包含相关内容
  includeComments?: boolean;    // Whether to include comments | 是否包含评论
  commentPage?: number;         // Comment page number | 评论页码
  commentPageSize?: number;     // Comment page size | 评论每页数量
}

/**
 * Content detail response interface | 内容详情响应接口
 */
export interface VodDetailResponse {
  vod: Vod;                     // Content detail | 内容详情
  seasonInfo?: SeasonInfo;      // Season information | 季数信息
  episodeInfo?: EpisodeInfo;    // Episode information | 集数信息
  playHistory?: PlayHistory;    // Play history information | 播放历史信息
  cast?: Actor[];               // Cast list | 演员表
  director?: string[];          // Directors | 导演
  writer?: string[];            // Writers | 编剧
  genre?: string[];             // Genres | 剧情
  relatedVods?: Vod[];          // Related content | 相关内容
  comments?: CommentList;       // Comment list | 评论列表
  refreshTime: number;          // Update time | 更新时间
}

/**
 * Comment interface | 评论接口
 */
export interface Comment {
  id: string;                   // Comment ID | 评论ID
  userId: string;               // User ID | 用户ID
  userName: string;             // User name | 用户名称
  userAvatar?: string;          // User avatar | 用户头像
  content: string;              // Comment content | 评论内容
  rating?: number;              // Rating | 评分
  likes: number;                // Like count | 点赞数
  replies?: Comment[];          // Reply list | 回复列表
  createdAt: number;            // Creation time | 创建时间
  updatedAt: number;            // Update time | 更新时间
  isLiked?: boolean;            // Whether current user liked | 当前用户是否点赞
}

/**
 * Comment list interface | 评论列表接口
 */
export interface CommentList {
  items: Comment[];             // Comment list | 评论列表
  total: number;                // Total comments | 评论总数
  page: number;                 // Current page number | 当前页码
  pageSize: number;             // Page size | 每页数量
  hasMore: boolean;             // Whether there are more comments | 是否有更多评论
}

/**
 * Season information interface | 季数信息接口
 */
export interface SeasonInfo {
  current: number;            // Current season | 当前季数
  total: number;              // Total seasons | 总季数
  watched: number;            // Watched seasons | 已看季数
  unwatched: number;          // Unwatched seasons | 未看季数
}

/**
 * Episode information interface | 集数信息接口
 */
export interface EpisodeInfo {
  total: number;              // Total episodes | 总集数
  watched: number;            // Watched episodes | 已看集数
  unwatched: number;          // Unwatched episodes | 未看集数
  current: number;            // Current episode | 当前集数
  totalDuration?: number;     // Total duration (seconds) | 总时长(秒)
  currentDuration?: number;    // Current episode duration (seconds) | 当前剧集时长(秒)
  progress?: number;           // Current episode progress (seconds) | 当前剧集进度(秒)
  watchedDuration?: number;    // Watched duration (seconds) | 已看时长(秒)
  unwatchedDuration?: number;  // Unwatched duration (seconds) | 未看时长(秒)
}

/**
 * Play history information interface | 播放历史信息接口
 */
export interface PlayHistory {
  episodeIndex: number;       // Last watched episode index | 上次观看剧集索引
  position: number;           // Last watched position | 上次观看位置
  lastPlayTime: number;       // Last watched time | 上次观看时间
  totalDuration?: number;     // Total duration (seconds) | 总时长(秒)
  currentDuration?: number;    // Current episode duration (seconds) | 当前剧集时长(秒)
  progress?: number;           // Current episode progress (seconds) | 当前剧集进度(秒)
  watchedDuration?: number;    // Watched duration (seconds) | 已看时长(秒)
  unwatchedDuration?: number;  // Unwatched duration (seconds) | 未看时长(秒)
}
