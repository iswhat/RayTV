// Live.ets - 直播内容数据模型
// 定义直播频道、分组和节目单等相关数据结构

/**
 * 直播流信息接�? */
export interface LiveStream {
  id: string;            // 流ID
  name: string;          // 流名�?  url: string;           // 流地址
  type?: string;         // 流类型（m3u8、flv、rtmp等）
  format?: string;       // 视频格式
  resolution?: string;   // 分辨�?  bitrate?: number;      // 比特�?  codec?: string;        // 编码格式
  language?: string;     // 语言
  subtitles?: string[];  // 字幕列表
  isDefault?: boolean;   // 是否默认�?  isFallback?: boolean;  // 是否备用�?  pingUrl?: string;      // 心跳检测URL
  status?: 'online' | 'offline' | 'unknown'; // 流状�?  lastCheckTime?: number; // 最后检查时�?}

/**
 * 直播分组接口
 */
export interface LiveGroup {
  id: string;            // 分组ID
  name: string;          // 分组名称
  order: number;         // 排序权重
  icon?: string;         // 分组图标
  channelCount?: number; // 频道数量
  isExpanded?: boolean;  // 是否展开
  isDefault?: boolean;   // 是否默认分组
  createdAt?: number;    // 创建时间
  updatedAt?: number;    // 更新时间
}

/**
 * 节目单信息接�? */
export interface EpgItem {
  id: string;            // 节目单ID
  title: string;         // 节目名称
  description?: string;  // 节目描述
  startTime: number;     // 开始时间（毫秒时间戳）
  endTime: number;       // 结束时间（毫秒时间戳�?  cover?: string;        // 节目封面
  category?: string;     // 节目类别
  isLiveNow?: boolean;   // 是否正在播放
  isFavorite?: boolean;  // 是否收藏
  tags?: string[];       // 标签
}

/**
 * 直播频道数据模型
 */
export interface LiveChannel {
  id: string;            // 频道ID
  name: string;          // 频道名称
  groupId: string;       // 所属分组ID
  logo?: string;         // 频道Logo
  epgId?: string;        // 节目单ID
  streams: LiveStream[]; // 直播流列�?  order: number;         // 排序权重
  isFavorite?: boolean;  // 是否收藏
  isLocked?: boolean;    // 是否锁定
  password?: string;     // 解锁密码（加密存储）
  playCount?: number;    // 播放次数
  lastPlayTime?: number; // 最后播放时�?  lastCheckTime?: number; // 最后检查时�?  status?: 'online' | 'offline' | 'unknown'; // 频道状�?  country?: string;      // 所属国�?  language?: string;     // 语言
  category?: string;     // 频道类别
  description?: string;  // 频道描述
  currentEpg?: EpgItem;  // 当前节目信息
  nextEpg?: EpgItem;     // 下一个节目信�?  sourceKey?: string;    // 数据源标�?  customUrl?: string;    // 自定义URL
  tags?: string[];       // 标签
  createdAt?: number;    // 创建时间
  updatedAt?: number;    // 更新时间
  userConfig?: LiveChannelUserConfig; // 用户配置信息
}

/**
 * 直播列表响应接口
 */
export interface LiveListResponse {
  groups: LiveGroup[];   // 分组列表
  channels: LiveChannel[]; // 频道列表
  totalGroups: number;   // 分组总数
  totalChannels: number; // 频道总数
  sourceKey?: string;    // 数据源标�?  refreshTime: number;   // 刷新时间
  version?: string;      // 版本�?}

/**
 * 直播分组详情接口
 */
export interface LiveGroupDetail {
  group: LiveGroup;      // 分组信息
  channels: LiveChannel[]; // 该分组下的频道列�?  totalChannels: number; // 频道总数
}

/**
 * 直播搜索结果接口
 */
export interface LiveSearchResult {
  channels: LiveChannel[]; // 搜索到的频道列表
  total: number;         // 总数
  keyword?: string;      // 搜索关键�?  groupId?: string;      // 分组筛�?  category?: string;     // 分类筛�?  country?: string;      // 国家筛�?}

/**
 * 频道筛选条件接�? */
export interface LiveFilter {
  groupId?: string;      // 分组ID
  keyword?: string;      // 关键�?  country?: string;      // 国家
  language?: string;     // 语言
  category?: string;     // 分类
  status?: string;       // 状态（在线/离线�?  isFavorite?: boolean;  // 是否收藏
}

/**
 * 节目单查询请求接�? */
export interface EpgRequest {
  channelIds?: string[]; // 频道ID列表
  startTime?: number;    // 开始时�?  endTime?: number;      // 结束时间
  days?: number;         // 查询天数
}

/**
 * 节目单响应接�? */
export interface EpgResponse {
  epgData: Map<string, EpgItem[]>; // 频道ID到节目单的映�?  totalChannels: number; // 包含节目单的频道数量
  totalPrograms: number; // 节目单总数
  updateTime: number;    // 更新时间
}

/**
 * 直播源检测结果接�? */
export interface LiveStreamCheckResult {
  streamId: string;      // 流ID
  channelId: string;     // 频道ID
  url: string;           // 流地址
  status: 'online' | 'offline' | 'timeout' | 'error'; // 检测状�?  responseTime?: number; // 响应时间（毫秒）
  bitrate?: number;      // 检测到的比特率
  resolution?: string;   // 检测到的分辨率
  errorMessage?: string; // 错误信息
  checkTime: number;     // 检测时�?}

/**
 * 直播收藏夹接�? */
export interface LiveFavoriteFolder {
  id: string;            // 收藏夹ID
  name: string;          // 收藏夹名�?  channelIds: string[];  // 频道ID列表
  createTime: number;    // 创建时间
  updateTime: number;    // 更新时间
  icon?: string;         // 收藏夹图�?  description?: string;  // 收藏夹描�?}

/**
 * 直播观看历史接口
 */
export interface LiveWatchHistory {
  channelId: string;     // 频道ID
  channelName: string;   // 频道名称
  streamId?: string;     // 观看的流ID
  lastPlayTime: number;  // 最后观看时�?  playCount: number;     // 观看次数
  totalWatchTime?: number; // 总观看时长（毫秒�?}

/**
 * 直播频道用户配置接口
 */
export interface LiveChannelUserConfig {
  selectedStream?: string; // 用户选择的流ID
  volume?: number;         // 用户设置的音�?  brightness?: number;     // 用户设置的亮�?  contrast?: number;       // 用户设置的对比度
}

/**
 * 直播源统计信息接�? */
export interface LiveStreamStats {
  totalStreams: number;  // 总流�?  onlineStreams: number; // 在线流数
  offlineStreams: number; // 离线流数
  averageResponseTime: number; // 平均响应时间
  lastCheckTime: number; // 最后检查时�?}

/**
 * 直播源更新信息接�? */
export interface LiveStreamUpdateInfo {
  channelId: string;     // 频道ID
  channelName: string;   // 频道名称
  oldStreams: LiveStream[]; // 旧流列表
  newStreams: LiveStream[]; // 新流列表
  updateTime: number;    // 更新时间
  sourceKey: string;     // 数据源标�?}

/**
 * 直播错误报告接口
 */
export interface LiveErrorReport {
  channelId: string;     // 频道ID
  channelName: string;   // 频道名称
  streamId?: string;     // 流ID
  errorType: string;     // 错误类型
  errorMessage: string;  // 错误信息
  timestamp: number;     // 错误发生时间
  deviceInfo?: string;   // 设备信息
  appVersion?: string;   // 应用版本
