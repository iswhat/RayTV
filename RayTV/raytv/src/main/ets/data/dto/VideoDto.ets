// VideoDto - 视频相关数据传输对象
// 定义视频、剧集、直播等相关的数据传输对象

/**
 * 视频类型枚举
 */
export enum VideoType {
  /**
   * 电影
   */
  MOVIE = 'movie',
  
  /**
   * 电视剧
   */
  TV_SHOW = 'tv_show',
  
  /**
   * 剧集
   */
  EPISODE = 'episode',
  
  /**
   * 纪录片
   */
  DOCUMENTARY = 'documentary',
  
  /**
   * 动漫
   */
  ANIME = 'anime',
  
  /**
   * 综艺
   */
  VARIETY = 'variety',
  
  /**
   * 短视频
   */
  SHORT_VIDEO = 'short_video',
  
  /**
   * 直播
   */
  LIVE = 'live',
  
  /**
   * 其他
   */
  OTHER = 'other'
}

/**
 * 视频质量枚举
 */
export enum VideoQuality {
  /**
   * 超低清 (144p)
   */
  QUALITY_144P = '144p',
  
  /**
   * 标清 (360p)
   */
  QUALITY_360P = '360p',
  
  /**
   * 流畅 (480p)
   */
  QUALITY_480P = '480p',
  
  /**
   * 高清 (720p)
   */
  QUALITY_720P = '720p',
  
  /**
   * 超清 (1080p)
   */
  QUALITY_1080P = '1080p',
  
  /**
   * 2K
   */
  QUALITY_2K = '2k',
  
  /**
   * 4K
   */
  QUALITY_4K = '4k',
  
  /**
   * 8K
   */
  QUALITY_8K = '8k',
  
  /**
   * 蓝光
   */
  BLURAY = 'bluray',
  
  /**
   * 未知
   */
  UNKNOWN = 'unknown'
}

/**
 * 视频格式枚举
 */
export enum VideoFormat {
  /**
   * MP4格式
   */
  MP4 = 'mp4',
  
  /**
   * MKV格式
   */
  MKV = 'mkv',
  
  /**
   * AVI格式
   */
  AVI = 'avi',
  
  /**
   * FLV格式
   */
  FLV = 'flv',
  
  /**
   * WMV格式
   */
  WMV = 'wmv',
  
  /**
   * WEBM格式
   */
  WEBM = 'webm',
  
  /**
   * TS格式
   */
  TS = 'ts',
  
  /**
   * M3U8格式
   */
  M3U8 = 'm3u8',
  
  /**
   * RMVB格式
   */
  RMVB = 'rmvb',
  
  /**
   * MOV格式
   */
  MOV = 'mov'
}

/**
 * 视频源接口
 */
export interface VideoSource {
  /**
   * 源ID
   */
  id: string;
  
  /**
   * 源名称
   */
  name: string;
  
  /**
   * 视频URL
   */
  url: string;
  
  /**
   * 视频质量
   */
  quality: VideoQuality;
  
  /**
   * 视频格式
   */
  format: VideoFormat;
  
  /**
   * 文件大小（字节）
   */
  size?: number;
  
  /**
   * 视频编码
   */
  videoCodec?: string;
  
  /**
   * 音频编码
   */
  audioCodec?: string;
  
  /**
   * 分辨率宽度
   */
  width?: number;
  
  /**
   * 分辨率高度
   */
  height?: number;
  
  /**
   * 帧率
   */
  frameRate?: number;
  
  /**
   * 码率（Kbps）
   */
  bitrate?: number;
  
  /**
   * 是否为本地文件
   */
  isLocal: boolean;
  
  /**
   * 是否为HLS流
   */
  isHls?: boolean;
  
  /**
   * 是否为DASH流
   */
  isDash?: boolean;
  
  /**
   * 来源平台
   */
  sourcePlatform?: string;
  
  /**
   * 是否需要VIP
   */
  requiresVip?: boolean;
  
  /**
   * 可用状态
   */
  available: boolean;
}

/**
 * 视频信息接口
 */
export interface VideoInfo {
  /**
   * 视频ID
   */
  id: string;
  
  /**
   * 视频标题
   */
  title: string;
  
  /**
   * 视频副标题
   */
  subtitle?: string;
  
  /**
   * 视频类型
   */
  type: VideoType;
  
  /**
   * 封面图片URL
   */
  coverUrl: string;
  
  /**
   * 背景图片URL
   */
  backdropUrl?: string;
  
  /**
   * 视频描述
   */
  description?: string;
  
  /**
   * 导演
   */
  directors?: string[];
  
  /**
   * 演员
   */
  actors?: string[];
  
  /**
   * 类型标签
   */
  genres?: string[];
  
  /**
   * 国家/地区
   */
  country?: string;
  
  /**
   * 语言
   */
  language?: string;
  
  /**
   * 上映年份
   */
  year: number;
  
  /**
   * 评分
   */
  rating?: number;
  
  /**
   * 评分人数
   */
  ratingCount?: number;
  
  /**
   * 总时长（秒）
   */
  duration?: number;
  
  /**
   * 视频来源列表
   */
  sources?: VideoSource[];
  
  /**
   * 字幕列表
   */
  subtitles?: SubtitleInfo[];
  
  /**
   * 播放次数
   */
  playCount?: number;
  
  /**
   * 收藏次数
   */
  favoriteCount?: number;
  
  /**
   * 评论次数
   */
  commentCount?: number;
  
  /**
   * 创建时间
   */
  createdAt?: number;
  
  /**
   * 更新时间
   */
  updatedAt?: number;
  
  /**
   * 相关视频ID列表
   */
  relatedVideos?: string[];
  
  /**
   * 是否已收藏
   */
  isFavorite?: boolean;
  
  /**
   * 播放进度（秒）
   */
  playProgress?: number;
}

/**
 * 字幕信息接口
 */
export interface SubtitleInfo {
  /**
   * 字幕ID
   */
  id: string;
  
  /**
   * 字幕名称
   */
  name: string;
  
  /**
   * 字幕语言
   */
  language: string;
  
  /**
   * 字幕URL
   */
  url: string;
  
  /**
   * 字幕格式
   */
  format: string;
  
  /**
   * 是否为强制字幕
   */
  forced?: boolean;
  
  /**
   * 编码格式
   */
  encoding?: string;
  
  /**
   * 是否为外部字幕
   */
  isExternal?: boolean;
  
  /**
   * 下载次数
   */
  downloadCount?: number;
}

/**
 * 播放记录接口
 */
export interface PlayHistory {
  /**
   * 记录ID
   */
  id?: string;
  
  /**
   * 视频ID
   */
  videoId: string;
  
  /**
   * 视频标题
   */
  videoTitle: string;
  
  /**
   * 播放进度（秒）
   */
  progress: number;
  
  /**
   * 总时长（秒）
   */
  totalDuration: number;
  
  /**
   * 最后播放时间
   */
  lastPlayedAt: number;
  
  /**
   * 播放次数
   */
  playCount: number;
  
  /**
   * 使用的播放器源ID
   */
  sourceId?: string;
  
  /**
   * 播放速度
   */
  playbackSpeed?: number;
  
  /**
   * 最后使用的音量
   */
  volume?: number;
  
  /**
   * 屏幕亮度
   */
  brightness?: number;
}

/**
 * 收藏信息接口
 */
export interface FavoriteInfo {
  /**
   * 收藏ID
   */
  id?: string;
  
  /**
   * 视频ID
   */
  videoId: string;
  
  /**
   * 视频标题
   */
  videoTitle: string;
  
  /**
   * 视频类型
   */
  videoType: VideoType;
  
  /**
   * 收藏时间
   */
  favoritedAt: number;
  
  /**
   * 收藏分类
   */
  category?: string;
  
  /**
   * 评分（1-5）
   */
  rating?: number;
  
  /**
   * 备注
   */
  note?: string;
  
  /**
   * 封面URL
   */
  coverUrl?: string;
}

/**
 * 电视剧信息接口
 */
export interface TvShowInfo extends VideoInfo {
  /**
   * 季数
   */
  seasons: TvSeasonInfo[];
  
  /**
   * 总季数
   */
  totalSeasons: number;
  
  /**
   * 总集数
   */
  totalEpisodes: number;
  
  /**
   * 是否已完结
   */
  ended: boolean;
  
  /**
   * 首播时间
   */
  firstAired?: string;
  
  /**
   * 完结时间
   */
  lastAired?: string;
}

/**
 * 季信息接口
 */
export interface TvSeasonInfo {
  /**
   * 季ID
   */
  id: string;
  
  /**
   * 季号
   */
  seasonNumber: number;
  
  /**
   * 季标题
   */
  title?: string;
  
  /**
   * 封面URL
   */
  coverUrl?: string;
  
  /**
   * 简介
   */
  description?: string;
  
  /**
   * 播出年份
   */
  year?: number;
  
  /**
   * 集数
   */
  episodes: TvEpisodeInfo[];
  
  /**
   * 总集数
   */
  totalEpisodes: number;
}

/**
 * 剧集信息接口
 */
export interface TvEpisodeInfo extends VideoInfo {
  /**
   * 剧集ID
   */
  id: string;
  
  /**
   * 集数编号
   */
  episodeNumber: number;
  
  /**
   * 季号
   */
  seasonNumber: number;
  
  /**
   * 剧集标题
   */
  title: string;
  
  /**
   * 播出日期
   */
  airedDate?: string;
  
  /**
   * 剧集评分
   */
  rating?: number;
  
  /**
   * 剧集序号
   */
  sequenceNumber?: number;
}

/**
 * 直播频道信息接口
 */
export interface LiveChannelInfo {
  /**
   * 频道ID
   */
  id: string;
  
  /**
   * 频道名称
   */
  name: string;
  
  /**
   * 频道编号
   */
  number?: string;
  
  /**
   * 频道图标
   */
  iconUrl: string;
  
  /**
   * 频道分组
   */
  group: string;
  
  /**
   * 直播流
   */
  streamUrl: string;
  
  /**
   * 备用直播流
   */
  backupUrls?: string[];
  
  /**
   * 当前节目
   */
  currentProgram?: LiveProgramInfo;
  
  /**
   * 下一个节目
   */
  nextProgram?: LiveProgramInfo;
  
  /**
   * 频道描述
   */
  description?: string;
  
  /**
   * 国家/地区
   */
  country?: string;
  
  /**
   * 语言
   */
  language?: string;
  
  /**
   * 是否已收藏
   */
  isFavorite?: boolean;
  
  /**
   * 排序权重
   */
  sortWeight: number;
  
  /**
   * 清晰度
   */
  quality?: VideoQuality;
}

/**
 * 直播节目信息接口
 */
export interface LiveProgramInfo {
  /**
   * 节目ID
   */
  id?: string;
  
  /**
   * 节目名称
   */
  title: string;
  
  /**
   * 节目描述
   */
  description?: string;
  
  /**
   * 开始时间
   */
  startTime: number;
  
  /**
   * 结束时间
   */
  endTime: number;
  
  /**
   * 节目类型
   */
  type?: string;
  
  /**
   * 封面图片
   */
  coverUrl?: string;
  
  /**
   * 是否为直播中
   */
  isLive?: boolean;
}

/**
 * 播放控制参数接口
 */
export interface PlaybackControlParams {
  /**
   * 视频ID
   */
  videoId: string;
  
  /**
   * 播放源ID
   */
  sourceId?: string;
  
  /**
   * 开始播放位置（秒）
   */
  startTime?: number;
  
  /**
   * 播放速度
   */
  playbackSpeed?: number;
  
  /**
   * 音量
   */
  volume?: number;
  
  /**
   * 是否静音
   */
  muted?: boolean;
  
  /**
   * 是否自动播放
   */
  autoPlay?: boolean;
  
  /**
   * 当前字幕ID
   */
  subtitleId?: string;
  
  /**
   * 字幕延迟（毫秒）
   */
  subtitleDelay?: number;
  
  /**
   * 音频延迟（毫秒）
   */
  audioDelay?: number;
}

/**
 * 播放状态接口
 */
export interface PlaybackState {
  /**
   * 播放状态
   */
  state: 'idle' | 'loading' | 'playing' | 'paused' | 'stopped' | 'error';
  
  /**
   * 当前播放位置（秒）
   */
  currentTime: number;
  
  /**
   * 总时长（秒）
   */
  duration: number;
  
  /**
   * 播放进度百分比
   */
  progress: number;
  
  /**
   * 播放速度
   */
  playbackSpeed: number;
  
  /**
   * 音量
   */
  volume: number;
  
  /**
   * 是否静音
   */
  muted: boolean;
  
  /**
   * 是否缓冲中
   */
  isBuffering: boolean;
  
  /**
   * 缓冲百分比
   */
  bufferPercentage: number;
  
  /**
   * 当前清晰度
   */
  currentQuality?: VideoQuality;
  
  /**
   * 当前字幕ID
   */
  currentSubtitleId?: string;
  
  /**
   * 错误信息
   */
  errorMessage?: string;
}

/**
 * 视频统计信息接口
 */
export interface VideoStats {
  /**
   * 视频ID
   */
  videoId: string;
  
  /**
   * 播放次数
   */
  playCount: number;
  
  /**
   * 完成观看次数
   */
  completeCount: number;
  
  /**
   * 平均观看时长（秒）
   */
  avgWatchTime: number;
  
  /**
   * 平均完成率
   */
  avgCompletionRate: number;
  
  /**
   * 收藏次数
   */
  favoriteCount: number;
  
  /**
   * 分享次数
   */
  shareCount: number;
  
  /**
   * 点赞次数
   */
  likeCount: number;
  
  /**
   * 踩次数
   */
  dislikeCount: number;
  
  /**
   * 最近观看人数
   */
  recentViewers: number;
}

/**
 * 视频评论接口
 */
export interface VideoComment {
  /**
   * 评论ID
   */
  id: string;
  
  /**
   * 视频ID
   */
  videoId: string;
  
  /**
   * 用户ID
   */
  userId: string;
  
  /**
   * 用户名称
   */
  userName: string;
  
  /**
   * 用户头像
   */
  userAvatar?: string;
  
  /**
   * 评论内容
   */
  content: string;
  
  /**
   * 评论时间
   */
  createdAt: number;
  
  /**
   * 点赞数
   */
  likeCount: number;
  
  /**
   * 回复数
   */
  replyCount: number;
  
  /**
   * 评分（1-5）
   */
  rating?: number;
  
  /**
   * 父评论ID
   */
  parentId?: string;
}
