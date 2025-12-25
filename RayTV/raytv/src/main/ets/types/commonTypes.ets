// 通用类型定义文件
// 为项目中常见的数据结构提供明确的类型定义，减少对any类型的依赖

/**
 * 基础响应对象类型
 */
export interface ApiResponse<T> {
  code: number;
  message: string;
  data?: T;
  success: boolean;
}

/**
 * 分页响应对象类型
 */
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

/**
 * 媒体项基础类型
 */
export interface MediaItem {
  id: string;
  title: string;
  coverUrl?: string;
  description?: string;
  duration?: number;
  releaseDate?: string;
  rating?: number;
}

/**
 * 视频信息类型
 */
export interface VideoInfo extends MediaItem {
  videoUrl?: string;
  quality?: string;
  subtitles?: SubtitleInfo[];
  audioTracks?: AudioTrackInfo[];
}

/**
 * 字幕信息类型
 */
export interface SubtitleInfo {
  id: string;
  language: string;
  name: string;
  url: string;
  isDefault?: boolean;
}

/**
 * 音频轨道信息类型
 */
export interface AudioTrackInfo {
  id: string;
  language: string;
  name: string;
  codec?: string;
  isDefault?: boolean;
}

/**
 * 用户信息类型
 */
export interface UserInfo {
  id: string;
  username: string;
  avatar?: string;
  email?: string;
  phone?: string;
  nickname?: string;
  level?: number;
  createdAt?: string;
  updatedAt?: string;
}

/**
 * 用户认证信息类型
 */
export interface AuthInfo {
  token: string;
  refreshToken?: string;
  expiresIn?: number;
  userInfo: UserInfo;
}

/**
 * 配置项类型
 */
export interface ConfigItem {
  key: string;
  value: string | number | boolean;
  type: 'string' | 'number' | 'boolean';
  description?: string;
  defaultValue?: string | number | boolean;
}

/**
 * 缓存选项类型
 */
export interface CacheOptions<T> {
  key: string;
  value: T;
  ttl?: number; // 过期时间（毫秒）
  tags?: string[]; // 标签，用于批量删除
}

/**
 * 搜索参数类型
 */
export interface SearchParams {
  keyword?: string;
  page?: number;
  pageSize?: number;
  filters?: Record<string, string | number | boolean | string[]>;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

/**
 * 历史记录项类型
 */
export interface HistoryItem {
  id: string;
  userId: string;
  mediaId: string;
  mediaType: 'video' | 'audio' | 'image';
  progress: number;
  lastPlayed: string;
  totalDuration?: number;
  extra?: Record<string, Serializable>;
}

/**
 * 收藏项类型
 */
export interface FavoriteItem {
  id: string;
  userId: string;
  mediaId: string;
  mediaType: 'video' | 'audio' | 'image' | 'playlist';
  addedAt: string;
  note?: string;
  extra?: Record<string, Serializable>;
}

/**
 * 设备信息类型
 */
export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  deviceType: string;
  osVersion: string;
  appVersion: string;
  ipAddress?: string;
  lastActive?: string;
}

/**
 * HTTP请求选项类型
 */
export interface HttpRequestOptions {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  params?: Record<string, string | number | boolean>;
  data?: Record<string, string | number | boolean | null> | string;
  timeout?: number;
  responseType?: 'json' | 'text';
  withCredentials?: boolean;
}

/**
 * HTTP响应类型
 */
export interface HttpResponse<T> {
  status: number;
  statusText: string;
  data: T;
  headers: Record<string, string>;
  config?: HttpRequestOptions;
}

/**
 * 错误信息类型
 */
export interface ErrorInfo {
  code: string;
  message: string;
  details?: Record<string, Serializable>;
  timestamp?: number;
}

/**
 * 事件监听器类型
 */
export interface EventListenerOptions {
  once?: boolean;
  priority?: number;
}

/**
 * 事件处理函数类型
 */
export type EventHandler<T> = (event: T) => void | Promise<void>;

/**
 * 通用回调函数类型
 */
export type Callback<T = void, E = Error> = (error?: E | null, result?: T) => void;

/**
 * 可取消的Promise类型
 */
export interface CancellablePromise<T> extends Promise<T> {
  cancel: () => void;
}

/**
 * 通用ID类型
 */
export type ID = string | number;

/**
 * 空值类型
 */
export type Empty = null | undefined | void;

/**
 * 可序列化的值类型
 */
export interface SerializableValue {
  type: 'string' | 'number' | 'boolean' | 'null' | 'undefined' | 'array' | 'object';
  value: Serializable | SerializableValue[] | Record<string, SerializableValue>;
}

export type Serializable = string | number | boolean | null | undefined;

/**
 * 深只读类型 - 简化版
 */
export type DeepReadonly<T> = T;

/**
 * 空对象类型（非null且非undefined的对象）
 */
export type NonEmptyObject<T extends object> = T;

/**
 * 排除null和undefined的类型
 */
export type NonNullableValue<T> = T;

/**
 * 通用函数类型
 */
export type AnyFunction = (...args: Serializable[]) => Serializable;

/**
 * 异步函数类型
 */
export type AsyncFunction<T> = (...args: Serializable[]) => Promise<T>;

/**
 * 延迟执行的返回类型
 */
export interface DelayResult {
  clear: () => void;
  promise: Promise<void>;
}