/**
 * Live content data types | 直播内容数据类型
 * Define data structures for live streams, groups and program guides | 定义直播流、分组和节目单等相关数据结构
 */

/**
 * Live stream information interface | 直播流信息接口
 */
export interface LiveStream {
  id: string;            // Stream ID | 流ID
  name: string;          // Stream name | 流名称
  url: string;           // Stream URL | 流地址
  type?: string;         // Stream type (hls, rtmp, flv, etc.) | 流类型(hls、rtmp、flv等)
  format?: string;       // Video format | 视频格式
  resolution?: string;   // Resolution | 分辨率
  bitrate?: number;      // Bitrate | 比特率
  codec?: string;        // Codec format | 编码格式
  language?: string;     // Language | 语言
  subtitles?: string[];  // Subtitle list | 字幕列表
  isDefault?: boolean;   // Whether it's the default stream | 是否默认流
  isFallback?: boolean;  // Whether it's a fallback stream | 是否备用流
  pingUrl?: string;      // Heartbeat detection URL | 心跳检测URL
  status?: 'online' | 'offline' | 'unknown'; // Stream status | 流状态
  lastCheckTime?: number; // Last check time | 最后检查时间
}

/**
 * Live group interface | 直播分组接口
 */
export interface LiveGroup {
  id: string;            // Group ID | 分组ID
  name: string;          // Group name | 分组名称
  order: number;         // Sorting weight | 排序权重
  icon?: string;         // Group icon | 分组图标
  channelCount?: number; // Channel count | 频道数量
  isExpanded?: boolean;  // Whether it's expanded | 是否展开
  isDefault?: boolean;   // Whether it's the default group | 是否默认分组
  createdAt?: number;    // Creation time | 创建时间
  updatedAt?: number;    // Update time | 更新时间
}

/**
 * Program guide item information interface | 节目单信息接口
 */
export interface EpgItem {
  id: string;            // Program guide ID | 节目单ID
  title: string;         // Program name | 节目名称
  description?: string;  // Program description | 节目描述
  startTime: number;     // Start time (millisecond timestamp) | 开始时间(毫秒时间戳)
  endTime: number;       // End time (millisecond timestamp) | 结束时间(毫秒时间戳)
  cover?: string;        // Program cover | 节目封面
  category?: string;     // Program category | 节目类别
  isLiveNow?: boolean;   // Whether it's playing now | 是否正在播放
  isFavorite?: boolean;  // Whether it's favorite | 是否收藏
  tags?: string[];       // Tags | 标签
}

/**
 * Live channel data type | 直播频道数据类型
 */
export interface LiveChannel {
  id: string;            // Channel ID | 频道ID
  name: string;          // Channel name | 频道名称
  groupId: string;       // Belonging group ID | 所属分组ID
  logo?: string;         // Channel logo | 频道Logo
  epgId?: string;        // Program guide ID | 节目单ID
  streams: LiveStream[]; // Live stream list | 直播流列表
  order: number;         // Sorting weight | 排序权重
  isFavorite?: boolean;  // Whether it's favorite | 是否收藏
  isLocked?: boolean;    // Whether it's locked | 是否锁定
  password?: string;     // Unlock password (encrypted storage) | 解锁密码(加密存储)
  playCount?: number;    // Play count | 播放次数
  lastPlayTime?: number; // Last play time | 最后播放时间
  lastCheckTime?: number; // Last check time | 最后检查时间
  status?: 'online' | 'offline' | 'unknown'; // Channel status | 频道状态
  country?: string;      // Country | 所属国家
  language?: string;     // Language | 语言
  category?: string;     // Channel category | 频道类别
  description?: string;  // Channel description | 频道描述
  currentEpg?: EpgItem;  // Current program information | 当前节目信息
  nextEpg?: EpgItem;     // Next program information | 下一个节目信息
  sourceKey?: string;    // Data source identifier | 数据源标识
  customUrl?: string;    // Custom URL | 自定义URL
  tags?: string[];       // Tags | 标签
  createdAt?: number;    // Creation time | 创建时间
  updatedAt?: number;    // Update time | 更新时间
  userConfig?: LiveChannelUserConfig; // User configuration information | 用户配置信息
}

/**
 * Live list response interface | 直播列表响应接口
 */
export interface LiveListResponse {
  groups: LiveGroup[];   // Group list | 分组列表
  channels: LiveChannel[]; // Channel list | 频道列表
  totalGroups: number;   // Total groups | 分组总数
  totalChannels: number; // Total channels | 频道总数
  sourceKey?: string;    // Data source identifier | 数据源标识
  refreshTime: number;   // Refresh time | 刷新时间
  version?: string;      // Version number | 版本号
}

/**
 * Live group detail interface | 直播分组详情接口
 */
export interface LiveGroupDetail {
  group: LiveGroup;      // Group information | 分组信息
  channels: LiveChannel[]; // Channel list under this group | 该分组下的频道列表
  totalChannels: number; // Total channels | 频道总数
}

/**
 * Live search result interface | 直播搜索结果接口
 */
export interface LiveSearchResult {
  channels: LiveChannel[]; // Search result channel list | 搜索到的频道列表
  total: number;         // Total count | 总数
  keyword?: string;      // Search keyword | 搜索关键词
  groupId?: string;      // Group filter | 分组筛选
}

/**
 * Channel filter condition interface | 频道筛选条件接口
 */
export interface LiveFilter {
  groupId?: string;      // Group ID | 分组ID
  keyword?: string;      // Keyword | 关键词
  country?: string;      // Country | 国家
  language?: string;     // Language | 语言
  category?: string;     // Category | 类别
  status?: string;       // Status (online/offline) | 状态(在线/离线)
  isFavorite?: boolean;  // Whether it's favorite | 是否收藏
}

/**
 * Program guide query request interface | 节目单查询请求接口
 */
export interface EpgRequest {
  channelIds?: string[]; // Channel ID list | 频道ID列表
  startTime?: number;    // Start time | 开始时间
  endTime?: number;      // End time | 结束时间
  days?: number;         // Query days | 查询天数
}

/**
 * Program guide response interface | 节目单响应接口
 */
export interface EpgResponse {
  epgData: Map<string, EpgItem[]>; // Mapping of channel ID to program guide | 频道ID到节目单的映射
  totalChannels: number; // Number of channels with program guide | 包含节目单的频道数量
  totalPrograms: number; // Total programs | 节目单总数
  updateTime: number;    // Update time | 更新时间
}

/**
 * Live stream check result interface | 直播流检测结果接口
 */
export interface LiveStreamCheckResult {
  streamId: string;      // Stream ID | 流ID
  channelId: string;     // Channel ID | 频道ID
  url: string;           // Stream URL | 流地址
  status: 'online' | 'offline' | 'timeout' | 'error'; // Check status | 检测状态
  responseTime?: number; // Response time (milliseconds) | 响应时间(毫秒)
  bitrate?: number;      // Detected bitrate | 检测到的比特率
  resolution?: string;   // Detected resolution | 检测到的分辨率
  errorMessage?: string; // Error message | 错误信息
  checkTime: number;     // Check time | 检测时间
}

/**
 * Live favorite folder interface | 直播收藏夹接口
 */
export interface LiveFavoriteFolder {
  id: string;            // Favorite folder ID | 收藏夹ID
  name: string;          // Favorite folder name | 收藏夹名称
  channelIds: string[];  // Channel ID list | 频道ID列表
  createTime: number;    // Creation time | 创建时间
  updateTime: number;    // Update time | 更新时间
  icon?: string;         // Favorite folder icon | 收藏夹图标
  description?: string;  // Favorite folder description | 收藏夹描述
}

/**
 * Live watch history interface | 直播观看历史接口
 */
export interface LiveWatchHistory {
  channelId: string;     // Channel ID | 频道ID
  channelName: string;   // Channel name | 频道名称
  streamId?: string;     // Watched stream ID | 观看的流ID
  lastPlayTime: number;  // Last watch time | 最后观看时间
  playCount: number;     // Watch count | 观看次数
  totalWatchTime?: number; // Total watch time (seconds) | 总观看时长(秒)
}

/**
 * Live channel user configuration interface | 直播频道用户配置接口
 */
export interface LiveChannelUserConfig {
  selectedStream?: string; // User selected stream ID | 用户选择的流ID
  volume?: number;         // User set volume | 用户设置的音量
  brightness?: number;     // User set brightness | 用户设置的亮度
  contrast?: number;       // User set contrast | 用户设置的对比度
}

/**
 * Live stream statistics interface | 直播流统计信息接口
 */
export interface LiveStreamStats {
  totalStreams: number;  // Total streams | 总流数
  onlineStreams: number; // Online streams | 在线流数
  offlineStreams: number; // Offline streams | 离线流数
  averageResponseTime: number; // Average response time | 平均响应时间
  lastCheckTime: number; // Last check time | 最后检查时间
}

/**
 * Live stream update information interface | 直播流更新信息接口
 */
export interface LiveStreamUpdateInfo {
  channelId: string;     // Channel ID | 频道ID
  channelName: string;   // Channel name | 频道名称
  oldStreams: LiveStream[]; // Old stream list | 旧流列表
  newStreams: LiveStream[]; // New stream list | 新流列表
  updateTime: number;    // Update time | 更新时间
  sourceKey: string;     // Data source identifier | 数据源标识
}

/**
 * Live error report interface | 直播错误报告接口
 */
export interface LiveErrorReport {
  channelId: string;     // Channel ID | 频道ID
  channelName: string;   // Channel name | 频道名称
  streamId?: string;     // Stream ID | 流ID
  errorType: string;     // Error type | 错误类型
  errorMessage: string;  // Error message | 错误信息
  timestamp: number;     // Error occurrence time | 错误发生时间
  deviceInfo?: string;   // Device information | 设备信息
  appVersion?: string;   // App version | 应用版本
}
