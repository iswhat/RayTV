/**
 * History - History record data types | 历史记录数据类型
 * Define data structure for user viewing history records | 定义用户观看历史记录的数据结构
 */

/**
 * History record type enum | 历史记录类型枚举
 */
export enum HistoryType {
  VOD = 'vod',          // VOD content | 点播内容
  LIVE = 'live',        // Live content | 直播内容
  COLLECTION = 'collection', // Collection content | 收藏内容
  SEARCH = 'search',    // Search history | 搜索历史
  RECENTLY_VIEWED = 'recently_viewed' // Recently viewed | 最近观看
}

/**
 * Content type enum | 内容类型枚举
 */
export enum ContentType {
  MOVIE = 'movie',      // Movie | 电影
  TV_SERIES = 'tv_series', // TV series | 电视剧
  ANIME = 'anime',      // Anime | 动画
  VARIETY = 'variety',  // Variety show | 综艺
  DOCUMENTARY = 'documentary', // Documentary | 纪录片
  LIVE_CHANNEL = 'live_channel', // Live channel | 直播频道
  LIVE_EVENT = 'live_event' // Live event | 直播事件
}

/**
 * Playback status enum | 播放状态枚举
 */
export enum PlaybackStatus {
  NOT_STARTED = 'not_started', // Not started | 未开始
  IN_PROGRESS = 'in_progress', // In progress | 进行中
  PAUSED = 'paused',     // Paused | 暂停
  COMPLETED = 'completed', // Completed | 已完成
  ERROR = 'error'        // Error | 错误
}

/**
 * History record data type | 历史记录数据类型
 */
export interface History {
  id: string;           // History record unique ID | 历史记录唯一ID
  contentId: string;    // Content ID | 内容ID
  contentName: string;  // Content name | 内容名称
  type: HistoryType;    // History record type | 历史记录类型
  contentType: ContentType; // Content type | 内容类型
  sourceKey: string;    // Data source identifier | 数据源标识
  cover: string;        // Cover URL | 封面URL
  poster?: string;      // Poster URL | 海报URL
  backdrop?: string;    // Backdrop URL | 背景图URL
  position: number;     // Playback position (milliseconds) | 播放位置（毫秒）
  duration: number;     // Total duration (seconds) | 总时长（秒）
  progress: number;     // Playback progress percentage (0-100) | 播放进度百分比（0-100）
  playbackStatus: PlaybackStatus; // Playback status | 播放状态
  episodeName?: string; // Episode name | 剧集名称
  episodeId?: string;   // Episode ID | 剧集ID
  seasonName?: string;  // Season name | 季名称
  seasonId?: string;    // Season ID | 季ID
  sourceName?: string;  // Video source name | 视频源名称
  sourceUrl?: string;   // Video source URL | 视频源URL
  playCount: number;    // Playback count | 播放次数
  totalWatchTime: number; // Total watch time (seconds) | 总观看时间（秒）
  lastPlayedAt: number; // Last played time | 最后播放时间
  firstPlayedAt: number; // First played time | 首次播放时间
  createdAt: number;    // Creation time | 创建时间
  updatedAt: number;    // Update time | 更新时间
  deviceId?: string;    // Device ID | 设备ID
  deviceName?: string;  // Device name | 设备名称
  userAgent?: string;   // User agent when watching | 观看时的用户代理
  resolution?: string;  // Viewing resolution | 观看分辨率
  bitrate?: number;     // Viewing bitrate | 观看码率
  language?: string;    // Language | 语言
  subtitles?: string[]; // Subtitle list | 字幕列表
  audioTracks?: string[]; // Audio track list | 音轨列表
  selectedAudioTrack?: string; // Selected audio track | 选中的音轨
  selectedSubtitle?: string; // Selected subtitle | 选中的字幕
  playbackSpeed?: number; // Playback speed | 播放速度
  volume?: number;      // Volume setting | 音量设置
  brightness?: number;  // Brightness setting | 亮度设置
  contrast?: number;    // Contrast setting | 对比度设置
  saturation?: number;  // Saturation setting | 饱和度设置
  hue?: number;         // Hue setting | 色调设置
  playbackNotes?: string; // Playback notes | 播放笔记
  watchTimeList?: WatchTimeRecord[]; // Watch time record list | 观看时间记录列表
}

/**
 * History record grouping interface | 历史记录分组接口
 */
export interface HistoryGroup {
  date: string;         // Date identifier (YYYY-MM-DD) | 日期标识（YYYY-MM-DD）
  label: string;        // Display label (Today, Yesterday, This week, etc.) | 显示标签（今天、昨天、本周等）
  histories: History[]; // History records list for this date | 该日期下的历史记录列表
  count: number;        // Record count | 记录数量
  totalWatchTime: number; // Total watch time | 总观看时间
}

/**
 * History record list response interface | 历史记录列表响应接口
 */
export interface HistoryListResponse {
  groups: HistoryGroup[]; // Grouped list | 分组列表
  totalCount: number;   // Total record count | 总记录数
  totalWatchTime: number; // Total watch time | 总观看时间
  hasMore: boolean;     // Whether has more | 是否有更多
  page?: number;        // Current page number | 当前页码
  pageSize?: number;    // Items per page | 每页数量
}

/**
 * History record statistics interface | 历史记录统计接口
 */
export interface HistoryStats {
  totalCount: number;   // Total record count | 总记录数
  totalWatchTime: number; // Total watch time (seconds) | 总观看时间（秒）
  averageWatchTime: number; // Average watch time | 平均观看时长
  recentDays: number;   // Data for recent days | 最近多少天的数据
  byType: Record<HistoryType, number>; // Statistics by type | 按类型统计
  byContentType: Record<ContentType, number>; // Statistics by content type | 按内容类型统计
  bySource: Record<string, number>; // Statistics by data source | 按数据源统计
  topContent: {
    contentId: string;
    contentName: string;
    watchCount: number;
    totalWatchTime: number;
  }[];
  lastWatchTime?: number; // Last watch time | 最后观看时间
  dailyAverage?: number; // Daily average watch count | 日均观看次数
}

/**
 * History record filter interface | 历史记录筛选条件接口
 */
export interface HistoryFilter {
  type?: HistoryType;   // History record type | 历史记录类型
  contentType?: ContentType; // Content type | 内容类型
  sourceKey?: string;   // Data source identifier | 数据源标识
  startDate?: number;   // Start date | 开始日期
  endDate?: number;     // End date | 结束日期
  minProgress?: number; // Minimum progress percentage | 最小进度百分比
  maxProgress?: number; // Maximum progress percentage | 最大进度百分比
  playCount?: number;   // Playback count filter | 播放次数筛选
  searchKeyword?: string; // Search keyword | 搜索关键词
}

/**
 * History record sort option enum | 历史记录排序选项枚举
 */
export enum HistorySortOption {
  LAST_PLAYED_AT_DESC = 'lastPlayedAt_desc', // Sort by last played time descending | 按最后播放时间降序
  LAST_PLAYED_AT_ASC = 'lastPlayedAt_asc',   // Sort by last played time ascending | 按最后播放时间升序
  CREATED_AT_DESC = 'createdAt_desc',        // Sort by creation time descending | 按创建时间降序
  CREATED_AT_ASC = 'createdAt_asc',          // Sort by creation time ascending | 按创建时间升序
  PLAY_COUNT_DESC = 'playCount_desc',        // Sort by play count descending | 按播放次数降序
  PLAY_COUNT_ASC = 'playCount_asc',          // Sort by play count ascending | 按播放次数升序
  PROGRESS_DESC = 'progress_desc',           // Sort by progress descending | 按播放进度降序
  PROGRESS_ASC = 'progress_asc',             // Sort by progress ascending | 按播放进度升序
  WATCH_TIME_DESC = 'watchTime_desc',        // Sort by watch time descending | 按观看时长降序
  WATCH_TIME_ASC = 'watchTime_asc'           // Sort by watch time ascending | 按观看时长升序
}

/**
 * History record clear options interface | 历史记录清除选项接口
 */
export interface HistoryClearOptions {
  beforeDate?: number;  // Clear records before specified date | 清除指定日期之前的记录
  minProgress?: number; // Clear records with progress less than specified | 清除小于指定进度的记录
  type?: HistoryType;   // Clear records of specified type | 清除指定类型的记录
  contentType?: ContentType; // Clear records of specified content type | 清除指定内容类型的记录
  sourceKey?: string;   // Clear records of specified data source | 清除指定数据源的记录
  selectedIds?: string[]; // Clear records with specified IDs | 清除指定ID的记录
  excludeCompleted?: boolean; // Exclude completed records | 排除已完成的记录
  excludeInProgress?: boolean; // Exclude in-progress records | 排除进行中的记录
}

/**
 * History record sync status interface | 历史记录同步状态接口
 */
export interface HistorySyncStatus {
  isEnabled: boolean;   // Whether sync is enabled | 是否启用同步
  lastSyncTime?: number; // Last sync time | 最后同步时间
  syncCount: number;    // Sync record count | 同步记录数
  status: 'idle' | 'syncing' | 'success' | 'failed'; // Sync status | 同步状态
  errorMessage?: string; // Error message | 错误信息
  syncDirection: 'upload' | 'download' | 'bidirectional'; // Sync direction | 同步方向
}

/**
 * History record export configuration interface | 历史记录导出配置接口
 */
export interface HistoryExportConfig {
  format: 'json' | 'csv' | 'pdf'; // Export format | 导出格式
  includeDetails?: boolean; // Whether to include details | 是否包含详细信息
  includeStats?: boolean;   // Whether to include statistics | 是否包含统计信息
  filter?: HistoryFilter;   // Export filter conditions | 导出筛选条件
  password?: string;        // Encryption password | 加密密码
  compress?: boolean;       // Whether to compress | 是否压缩
}

/**
 * Watch progress reminder interface | 观看进度提醒接口
 */
export interface ProgressReminder {
  historyId: string;    // History record ID | 历史记录ID
  contentId: string;    // Content ID | 内容ID
  contentName: string;  // Content name | 内容名称
  progress: number;     // Current progress | 当前进度
  remainingTime: number; // Remaining time | 剩余时间
  episodeName?: string; // Episode name | 剧集名称
  reminderTime: number; // Reminder time | 提醒时间
  isRead: boolean;      // Whether read | 是否已读
  createdAt: number;    // Creation time | 创建时间
}

/**
 * Device watch record interface | 设备观看记录接口
 */
export interface DeviceWatchRecord {
  deviceId: string;     // Device ID | 设备ID
  deviceName: string;   // Device name | 设备名称
  lastSyncTime: number; // Last sync time | 最后同步时间
  recordCount: number;  // Record count | 记录数量
  totalWatchTime: number; // Total watch time | 总观看时间
  lastContent?: {
    contentId: string;
    contentName: string;
    lastPlayedAt: number;
    progress: number;
  };
}

/**
 * Watch time record interface | 观看时间记录接口
 */
export interface WatchTimeRecord {
  startTime: number;  // Start time | 开始时间
  endTime: number;    // End time | 结束时间
  duration: number;   // Watch duration | 观看时长
}
