// commonTypes.ets - 通用类型定义文件 // Common type definition file
// 为项目中常见的数据结构提供明确的类型定义，尽量减少对any类型的依赖 // Provide clear type definitions for common data structures in the project, minimizing reliance on any type

/**
 * API response object type // API响应对象类型
 * @template T - Response data type | 响应数据类型
 */
export interface ApiResponse<T> {
  code: number; // Response code | 响应代码
  message: string; // Response message | 响应消息
  data?: T; // Response data | 响应数据
  success: boolean; // Whether the request succeeded | 请求是否成功
}

/**
 * Paginated response object type // 分页响应对象类型
 * @template T - Item type | 项目类型
 */
export interface PaginatedResponse<T> {
  data: T[]; // Paginated data | 分页数据
  total: number; // Total number of items | 项目总数
  page: number; // Current page number | 当前页码
  pageSize: number; // Items per page | 每页项目数
  totalPages: number; // Total number of pages | 总页数
}

/**
 * Media item base type // 媒体项目基础类型
 */
export interface MediaItem {
  id: string; // Media item ID | 媒体项目ID
  title: string; // Media item title | 媒体项目标题
  coverUrl?: string; // Cover image URL | 封面图片URL
  description?: string; // Media item description | 媒体项目描述
  duration?: number; // Duration in seconds | 时长（秒）
  releaseDate?: string; // Release date | 发布日期
  rating?: number; // Rating score | 评分
}

/**
 * Video info type // 视频信息类型
 */
export interface VideoInfo extends MediaItem {
  videoUrl?: string; // Video playback URL | 视频播放URL
  quality?: string; // Video quality | 视频质量
  subtitles?: SubtitleInfo[]; // Subtitle information | 字幕信息
  audioTracks?: AudioTrackInfo[]; // Audio track information | 音轨信息
}

/**
 * Subtitle info type // 字幕信息类型
 */
export interface SubtitleInfo {
  id: string; // Subtitle ID | 字幕ID
  language: string; // Subtitle language | 字幕语言
  name: string; // Subtitle name | 字幕名称
  url: string; // Subtitle file URL | 字幕文件URL
  isDefault?: boolean; // Whether this is the default subtitle | 是否为默认字幕
}

/**
 * Audio track info type // 音轨信息类型
 */
export interface AudioTrackInfo {
  id: string; // Audio track ID | 音轨ID
  language: string; // Audio track language | 音轨语言
  name: string; // Audio track name | 音轨名称
  codec?: string; // Audio codec | 音频编码
  isDefault?: boolean; // Whether this is the default audio track | 是否为默认音轨
}

/**
 * User info type // 用户信息类型
 */
export interface UserInfo {
  id: string; // User ID | 用户ID
  username: string; // Username | 用户名
  avatar?: string; // Avatar URL | 头像URL
  email?: string; // Email address | 邮箱地址
  phone?: string; // Phone number | 电话号码
  nickname?: string; // Nickname | 昵称
  level?: number; // User level | 用户等级
  createdAt?: string; // Account creation time | 账号创建时间
  updatedAt?: string; // Last update time | 最后更新时间
}

/**
 * User authentication info type // 用户认证信息类型
 */
export interface AuthInfo {
  token: string; // Access token | 访问令牌
  refreshToken?: string; // Refresh token | 刷新令牌
  expiresIn?: number; // Token expiration time in seconds | 令牌过期时间（秒）
  userInfo: UserInfo; // User information | 用户信息
}

/**
 * Config item type // 配置项类型
 */
export interface ConfigItem {
  key: string; // Config key | 配置键
  value: string | number | boolean; // Config value | 配置值
  type: 'string' | 'number' | 'boolean'; // Value type | 值类型
  description?: string; // Config description | 配置描述
  defaultValue?: string | number | boolean; // Default value | 默认值
}

/**
 * Cache options type // 缓存选项类型
 * @template T - Cache value type | 缓存值类型
 */
export interface CacheOptions<T> {
  key: string; // Cache key | 缓存键
  value: T; // Cache value | 缓存值
  ttl?: number; // Expiration time (milliseconds) | 过期时间（毫秒）
  tags?: string[]; // Tags for batch deletion | 标签，用于批量删除
}

/**
 * Search params type // 搜索参数类型
 */
export interface SearchParams {
  keyword?: string; // Search keyword | 搜索关键词
  page?: number; // Page number | 页码
  pageSize?: number; // Items per page | 每页项目数
  filters?: Record<string, string | number | boolean | string[]>; // Search filters | 搜索过滤器
  sortBy?: string; // Sort field | 排序字段
  sortOrder?: 'asc' | 'desc'; // Sort order | 排序顺序
}

/**
 * History item type // 历史记录类型
 */
export interface HistoryItem {
  id: string; // History item ID | 历史记录ID
  userId: string; // User ID | 用户ID
  mediaId: string; // Media item ID | 媒体项目ID
  mediaType: 'video' | 'audio' | 'image'; // Media type | 媒体类型
  progress: number; // Playback progress (seconds) | 播放进度（秒）
  lastPlayed: string; // Last played time | 最后播放时间
  totalDuration?: number; // Total duration (seconds) | 总时长（秒）
  extra?: Record<string, Serializable>; // Extra information | 附加信息
}

/**
 * Favorite item type // 收藏类型
 */
export interface FavoriteItem {
  id: string; // Favorite item ID | 收藏项ID
  userId: string; // User ID | 用户ID
  mediaId: string; // Media item ID | 媒体项目ID
  mediaType: 'video' | 'audio' | 'image' | 'playlist'; // Media type | 媒体类型
  addedAt: string; // Added time | 添加时间
  note?: string; // User note | 用户备注
  extra?: Record<string, Serializable>; // Extra information | 附加信息
}

/**
 * Device info type // 设备信息类型
 */
export interface DeviceInfo {
  deviceId: string; // Device ID | 设备ID
  deviceName: string; // Device name | 设备名称
  deviceType: string; // Device type | 设备类型
  osVersion: string; // Operating system version | 操作系统版本
  appVersion: string; // App version | 应用版本
  ipAddress?: string; // IP address | IP地址
  lastActive?: string; // Last active time | 最后活跃时间
}

/**
 * HTTP request options type // HTTP请求选项类型
 */
export interface HttpRequestOptions {
  url: string; // Request URL | 请求URL
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'; // HTTP method | HTTP方法
  headers?: Record<string, string>; // Request headers | 请求头
  params?: Record<string, string | number | boolean>; // URL parameters | URL参数
  data?: Record<string, string | number | boolean | null> | string; // Request body | 请求体
  timeout?: number; // Request timeout in milliseconds | 请求超时时间（毫秒）
  responseType?: 'json' | 'text'; // Response type | 响应类型
  withCredentials?: boolean; // Whether to include credentials | 是否包含凭证
}

/**
 * HTTP response type // HTTP响应类型
 * @template T - Response data type | 响应数据类型
 */
export interface HttpResponse<T> {
  status: number; // HTTP status code | HTTP状态码
  statusText: string; // HTTP status text | HTTP状态文本
  data: T; // Response data | 响应数据
  headers: Record<string, string>; // Response headers | 响应头
  config?: HttpRequestOptions; // Request configuration | 请求配置
}

/**
 * Error info type // 错误信息类型
 */
export interface ErrorInfo {
  code: string; // Error code | 错误代码
  message: string; // Error message | 错误信息
  details?: Record<string, Serializable>; // Error details | 错误详情
  timestamp?: number; // Error timestamp | 错误时间戳
}

/**
 * Event listener type // 事件监听器类型
 */
export interface EventListenerOptions {
  once?: boolean; // Whether to trigger only once | 是否只触发一次
  priority?: number; // Event listener priority | 事件监听器优先级
}

/**
 * 事件处理函数类型 // Event handler type
 */
export type EventHandler<T> = (event: T) => void | Promise<void>;

/**
 * 通用回调函数类型 // Common callback type
 */
export type Callback<T = void, E = Error> = (error?: E | null, result?: T) => void;

/**
 * 可取消的Promise类型 // Cancellable promise type
 */
export interface CancellablePromise<T> extends Promise<T> {
  cancel: () => void;
}

/**
 * 通用ID类型 // Common ID type
 */
export type ID = string | number;

/**
 * 空类型 // Empty type
 */
export type Empty = null | undefined | void;

/**
 * 可序列化的值类型 // Serializable value type
 */
export interface SerializableValue {
  type: 'string' | 'number' | 'boolean' | 'null' | 'undefined' | 'array' | 'object';
  value: Serializable | SerializableValue[] | Record<string, SerializableValue>;
}

export type Serializable = string | number | boolean | null | undefined;

/**
 * 深度只读类型 - 简化版 // Deep readonly type - simplified version
 */
export type DeepReadonly<T> = T;

/**
 * 非空对象类型（除null且非undefined的对象） // Non-empty object type (object except null and non-undefined)
 */
export type NonEmptyObject<T extends object> = T;

/**
 * 移除null和undefined的类型 // Type without null and undefined
 */
export type NonNullableValue<T> = T;

/**
 * 通用函数类型 // Common function type
 */
export type AnyFunction = (...args: Serializable[]) => Serializable;

/**
 * 异步函数类型 // Async function type
 */
export type AsyncFunction<T> = (...args: Serializable[]) => Promise<T>;

/**
 * Delay execution return type // 延迟执行的返回类型
 */
export interface DelayResult {
  clear: () => void; // Function to clear the delay | 清除延迟的函数
  promise: Promise<void>; // Promise that resolves after the delay | 延迟后解析的Promise
}
