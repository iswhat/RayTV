// Vod.ets - 点播内容数据模型
// 定义点播内容的基本信息和结构

/**
 * 剧集信息接口
 */
export interface Episode {
  id: string;          // 剧集ID
  name: string;        // 剧集名称
  url: string;         // 剧集播放URL
  source?: string;     // 来源标识
  isNew?: boolean;     // 是否新剧�?  isPlayed?: boolean;  // 是否已播�?  progress?: number;   // 播放进度（百分比�?  duration?: number;   // 总时长（毫秒�?}

/**
 * 演员信息接口
 */
export interface Actor {
  id: string;          // 演员ID
  name: string;        // 演员名称
  avatar?: string;     // 演员头像URL
  role?: string;       // 扮演角色
}

/**
 * 导演信息接口
 */
export interface Director {
  id: string;          // 导演ID
  name: string;        // 导演名称
  avatar?: string;     // 导演头像URL
}

/**
 * 推荐理由接口
 */
export interface RecommendReason {
  type: string;        // 推荐类型
  content: string;     // 推荐内容
  priority?: number;   // 优先�?}

/**
 * 点播内容数据模型
 */
export interface Vod {
  id: string;                   // 内容唯一ID
  name: string;                 // 内容名称
  type: string;                 // 类型（电影、电视剧等）
  area: string;                 // 地区
  lang: string;                 // 语言
  year: string;                 // 年份
  score: string;                // 评分
  status: string;               // 状态（连载中、已完结�?  desc: string;                 // 简�?  cover: string;                // 封面图URL
  tag: string;                  // 标签
  url: string;                  // 内容详情页URL
  sourceKey: string;            // 数据源标�?  episodeList?: Episode[];      // 剧集列表
  selectedEpisode?: number;     // 当前选中剧集
  createdAt: number;            // 创建时间
  updatedAt: number;            // 更新时间
  actors?: Actor[];             // 演员列表
  directors?: Director[];       // 导演列表
  recommendReasons?: RecommendReason[]; // 推荐理由
  isVip?: boolean;              // 是否VIP内容
  isPay?: boolean;              // 是否付费内容
  originalPrice?: number;       // 原价
  currentPrice?: number;        // 当前价格
  isCollect?: boolean;          // 是否已收�?  playCount?: number;           // 播放次数
  collectCount?: number;        // 收藏次数
  commentCount?: number;        // 评论次数
  sourceList?: Map<string, Episode[]>; // 多来源剧集列�?  subTitleList?: string[];      // 字幕列表
  videoQualityList?: string[];  // 画质选项
  isHdr?: boolean;              // 是否支持HDR
  isDolby?: boolean;            // 是否支持杜比音效
  is3D?: boolean;               // 是否3D内容
  imdbId?: string;              // IMDB ID
  doubanId?: string;            // 豆瓣ID
  tmdbId?: string;              // TMDB ID
  backdrop?: string;            // 背景图URL
  previewVideo?: string;        // 预告片URL
  relatedVods?: string[];       // 相关内容ID列表
  userRating?: number;          // 用户评分
  categoryIds?: string[];       // 分类ID列表
  seasonInfo?: SeasonInfo;            // 季数信息
  episodeInfo?: EpisodeInfo;          // 集数信息
  playHistory?: PlayHistory;          // 播放历史信息
}

/**
 * 点播内容搜索结果接口
 */
export interface VodSearchResult {
  vods: Vod[];                  // 搜索到的内容列表
  total: number;                // 总数
  page: number;                 // 当前页码
  pageSize: number;             // 每页数量
  hasMore: boolean;             // 是否有更�?  keyword?: string;             // 搜索关键�?  category?: string;            // 分类筛�?  area?: string;                // 地区筛�?  year?: string;                // 年份筛�?  sortBy?: string;              // 排序方式
}

/**
 * 点播内容推荐接口
 */
export interface VodRecommendation {
  id: string;                   // 推荐ID
  title: string;                // 推荐标题
  subtitle?: string;            // 推荐副标�?  vods: Vod[];                  // 推荐内容列表
  type: string;                 // 推荐类型
  refreshInterval?: number;     // 刷新间隔（毫秒）
  coverImage?: string;          // 封面�?  priority: number;             // 优先�?  createdAt: number;            // 创建时间
  updatedAt: number;            // 更新时间
}

/**
 * 内容标签接口
 */
export interface ContentTag {
  id: string;                   // 标签ID
  name: string;                 // 标签名称
  count?: number;               // 使用次数
  category?: string;            // 标签分类
}

/**
 * 内容筛选条件接�? */
export interface VodFilter {
  category?: string;            // 分类
  area?: string;                // 地区
  year?: string;                // 年份
  status?: string;              // 状�?  tag?: string;                 // 标签
  sortBy?: string;              // 排序方式
  keyword?: string;             // 关键�?  page?: number;                // 页码
  pageSize?: number;            // 每页数量
  sourceKey?: string;           // 数据�?  isVip?: boolean;              // 是否VIP
}

/**
 * 内容详情请求参数接口
 */
export interface VodDetailRequest {
  id: string;                   // 内容ID
  sourceKey: string;            // 数据源标�?  includeEpisodes?: boolean;    // 是否包含剧集列表
  includeRelated?: boolean;     // 是否包含相关内容
  includeComments?: boolean;    // 是否包含评论
  commentPage?: number;         // 评论页码
  commentPageSize?: number;     // 评论每页数量
}

/**
 * 内容详情响应接口
 */
export interface VodDetailResponse {
  vod: Vod;                     // 内容详情
  relatedVods?: Vod[];          // 相关内容
  comments?: {
    items: Comment[];           // 评论列表
    total: number;              // 评论总数
    page: number;               // 当前页码
    pageSize: number;           // 每页数量
    hasMore: boolean;           // 是否有更多评�?  };
  refreshTime: number;          // 刷新时间
}

/**
 * 评论接口
 */
export interface Comment {
  id: string;                   // 评论ID
  userId: string;               // 用户ID
  userName: string;             // 用户名称
  userAvatar?: string;          // 用户头像
  content: string;              // 评论内容
  rating?: number;              // 评分
  likes: number;                // 点赞�?  replies?: Comment[];          // 回复列表
  createdAt: number;            // 创建时间
  updatedAt: number;            // 更新时间
  isLiked?: boolean;            // 当前用户是否点赞
}

/**
 * 季数信息接口
 */
export interface SeasonInfo {
  current: number;            // 当前季数
  total: number;              // 总季�?}

/**
 * 集数信息接口
 */
export interface EpisodeInfo {
  total: number;              // 总集�?  watched: number;            // 已看集数
}

/**
 * 播放历史信息接口
 */
export interface PlayHistory {
  episodeIndex: number;       // 上次观看剧集索引
  position: number;           // 上次观看位置
  lastPlayTime: number;       // 上次观看时间
}
