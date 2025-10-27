// History.ets - 历史记录数据模型
// 定义用户观看历史记录的数据结构

/**
 * 历史记录类型枚举
 */
export enum HistoryType {
  VOD = 'vod',          // 点播内容
  LIVE = 'live',        // 直播内容
  COLLECTION = 'collection', // 收藏内容
  SEARCH = 'search',    // 搜索历史
  RECENTLY_VIEWED = 'recently_viewed' // 最近浏览
}

/**
 * 内容类型枚举
 */
export enum ContentType {
  MOVIE = 'movie',      // 电影
  TV_SERIES = 'tv_series', // 电视剧
  ANIME = 'anime',      // 动漫
  VARIETY = 'variety',  // 综艺
  DOCUMENTARY = 'documentary', // 纪录片
  LIVE_CHANNEL = 'live_channel', // 直播频道
  LIVE_EVENT = 'live_event' // 直播事件
}

/**
 * 播放状态枚举
 */
export enum PlaybackStatus {
  NOT_STARTED = 'not_started', // 未开始
  IN_PROGRESS = 'in_progress', // 进行中
  PAUSED = 'paused',     // 暂停
  COMPLETED = 'completed', // 已完成
  ERROR = 'error'        // 错误
}

/**
 * 历史记录数据模型
 */
export interface History {
  id: string;           // 历史记录唯一ID
  contentId: string;    // 内容ID
  contentName: string;  // 内容名称
  type: HistoryType;    // 历史记录类型
  contentType: ContentType; // 内容类型
  sourceKey: string;    // 数据源标识
  cover: string;        // 封面URL
  poster?: string;      // 海报URL
  backdrop?: string;    // 背景图URL
  position: number;     // 播放位置（毫秒）
  duration: number;     // 总时长（毫秒）
  progress: number;     // 播放进度百分比（0-100）
  playbackStatus: PlaybackStatus; // 播放状态
  episodeName?: string; // 剧集名称
  episodeId?: string;   // 剧集ID
  seasonName?: string;  // 季名称
  seasonId?: string;    // 季ID
  sourceName?: string;  // 视频源名称
  sourceUrl?: string;   // 视频源URL
  playCount: number;    // 播放次数
  totalWatchTime: number; // 总观看时长（毫秒）
  lastPlayedAt: number; // 最后播放时间
  firstPlayedAt: number; // 首次播放时间
  createdAt: number;    // 创建时间
  updatedAt: number;    // 更新时间
  deviceId?: string;    // 设备ID
  deviceName?: string;  // 设备名称
  userAgent?: string;   // 观看时的用户代理
  resolution?: string;  // 观看分辨率
  bitrate?: number;     // 观看比特率
  language?: string;    // 语言
  subtitles?: string[]; // 字幕列表
  audioTracks?: string[]; // 音轨列表
  selectedAudioTrack?: string; // 选中的音轨
  selectedSubtitle?: string; // 选中的字幕
  playbackSpeed?: number; // 播放速度
  volume?: number;      // 音量设置
  brightness?: number;  // 亮度设置
  contrast?: number;    // 对比度设置
  saturation?: number;  // 饱和度设置
  hue?: number;         // 色调设置
  playbackNotes?: string; // 播放笔记
  watchTimeList?: {
    startTime: number;  // 开始时间
    endTime: number;    // 结束时间
    duration: number;   // 观看时长
  }[];
}

/**
 * 历史记录分组接口
 */
export interface HistoryGroup {
  date: string;         // 日期标识（YYYY-MM-DD）
  label: string;        // 显示标签（今天、昨天、本周等）
  histories: History[]; // 该日期下的历史记录列表
  count: number;        // 记录数量
  totalWatchTime: number; // 总观看时长
}

/**
 * 历史记录列表响应接口
 */
export interface HistoryListResponse {
  groups: HistoryGroup[]; // 分组列表
  totalCount: number;   // 总记录数
  totalWatchTime: number; // 总观看时长
  hasMore: boolean;     // 是否有更多
  page?: number;        // 当前页码
  pageSize?: number;    // 每页数量
}

/**
 * 历史记录统计接口
 */
export interface HistoryStats {
  totalCount: number;   // 总记录数
  totalWatchTime: number; // 总观看时长（毫秒）
  averageWatchTime: number; // 平均观看时长
  recentDays: number;   // 最近多少天的数据
  byType: Map<HistoryType, number>; // 按类型统计
  byContentType: Map<ContentType, number>; // 按内容类型统计
  bySource: Map<string, number>; // 按数据源统计
  topContent: {
    contentId: string;
    contentName: string;
    watchCount: number;
    totalWatchTime: number;
  }[];
  lastWatchTime?: number; // 最后观看时间
  dailyAverage?: number; // 日均观看次数
}

/**
 * 历史记录筛选条件接口
 */
export interface HistoryFilter {
  type?: HistoryType;   // 历史记录类型
  contentType?: ContentType; // 内容类型
  sourceKey?: string;   // 数据源标识
  startDate?: number;   // 开始日期
  endDate?: number;     // 结束日期
  minProgress?: number; // 最小进度百分比
  maxProgress?: number; // 最大进度百分比
  playCount?: number;   // 播放次数筛选
  searchKeyword?: string; // 搜索关键词
}

/**
 * 历史记录排序选项枚举
 */
export enum HistorySortOption {
  LAST_PLAYED_AT_DESC = 'lastPlayedAt_desc', // 按最后播放时间降序
  LAST_PLAYED_AT_ASC = 'lastPlayedAt_asc',   // 按最后播放时间升序
  CREATED_AT_DESC = 'createdAt_desc',        // 按创建时间降序
  CREATED_AT_ASC = 'createdAt_asc',          // 按创建时间升序
  PLAY_COUNT_DESC = 'playCount_desc',        // 按播放次数降序
  PLAY_COUNT_ASC = 'playCount_asc',          // 按播放次数升序
  PROGRESS_DESC = 'progress_desc',           // 按播放进度降序
  PROGRESS_ASC = 'progress_asc',             // 按播放进度升序
  WATCH_TIME_DESC = 'watchTime_desc',        // 按观看时长降序
  WATCH_TIME_ASC = 'watchTime_asc'           // 按观看时长升序
}

/**
 * 历史记录清除选项接口
 */
export interface HistoryClearOptions {
  beforeDate?: number;  // 清除指定日期之前的记录
  minProgress?: number; // 清除小于指定进度的记录
  type?: HistoryType;   // 清除指定类型的记录
  contentType?: ContentType; // 清除指定内容类型的记录
  sourceKey?: string;   // 清除指定数据源的记录
  selectedIds?: string[]; // 清除指定ID的记录
  excludeCompleted?: boolean; // 排除已完成的记录
  excludeInProgress?: boolean; // 排除进行中的记录
}

/**
 * 历史记录同步状态接口
 */
export interface HistorySyncStatus {
  isEnabled: boolean;   // 是否启用同步
  lastSyncTime?: number; // 最后同步时间
  syncCount: number;    // 同步记录数
  status: 'idle' | 'syncing' | 'success' | 'failed'; // 同步状态
  errorMessage?: string; // 错误信息
  syncDirection: 'upload' | 'download' | 'bidirectional'; // 同步方向
}

/**
 * 历史记录导出配置接口
 */
export interface HistoryExportConfig {
  format: 'json' | 'csv' | 'pdf'; // 导出格式
  includeDetails?: boolean; // 是否包含详细信息
  includeStats?: boolean;   // 是否包含统计信息
  filter?: HistoryFilter;   // 导出筛选条件
  password?: string;        // 加密密码
  compress?: boolean;       // 是否压缩
}

/**
 * 观看进度提醒接口
 */
export interface ProgressReminder {
  historyId: string;    // 历史记录ID
  contentId: string;    // 内容ID
  contentName: string;  // 内容名称
  progress: number;     // 当前进度
  remainingTime: number; // 剩余时间
  episodeName?: string; // 剧集名称
  reminderTime: number; // 提醒时间
  isRead: boolean;      // 是否已读
  createdAt: number;    // 创建时间
}

/**
 * 设备观看记录接口
 */
export interface DeviceWatchRecord {
  deviceId: string;     // 设备ID
  deviceName: string;   // 设备名称
  lastSyncTime: number; // 最后同步时间
  recordCount: number;  // 记录数量
  totalWatchTime: number; // 总观看时长
  lastContent?: {
    contentId: string;
    contentName: string;
    lastPlayedAt: number;
    progress: number;
  };
}