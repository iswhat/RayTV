// 通用类型定义文件
// 为项目中常见的数据结构提供明确的类型定义，减少对any类型的依�?
// 引入ArkTS兼容的工具类�?import { ArkTSBaseTypes, ArkTSUtilityTypes } from '../common/util/ark/types/ArkTSBaseTypes';
import { ArkTSPartial, ArkTSRequired, ArkTSPick, ArkTSOmit, ArkTSRecord, ArkTSReadonly } from '../common/util/ark/types/ArkTSUtilityTypes';

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

// 重命名以避免与标准库冲突
export type Partial<T> = ArkTSPartial<T>;
export type Required<T> = ArkTSRequired<T>;
export type Pick<T, K extends keyof T> = ArkTSPick<T, K>;
export type Omit<T, K extends keyof T> = ArkTSOmit<T, K>;
export type Record<K extends string | number | symbol, T> = ArkTSRecord<K, T>;
export type Readonly<T> = ArkTSReadonly<T>;

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
 * 配置项类�? */
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
  tags?: string[]; // 标签，用于批量删�?}

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
 * 历史记录项类�? */
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
 * 收藏项类�? */
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
 * 事件监听器类�? */
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
export interface Callback<T = void, E = Error> {
  (error?: E | null, result?: T): void;
}

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
 * 空值类�? */
export type Empty = null | undefined | void;

/**
 * 可序列化的对象接�? */
export interface SerializableObject {
  // ArkTS兼容：不使用索引签名，使用明确的接口定义
  getSerializable(key: string): Serializable;
  setSerializable(key: string, value: Serializable): void;
  hasSerializable(key: string): boolean;
  toPlainObject(): Record<string, Serializable>;
}

/**
 * 可序列化的值类�? */
export type Serializable = 
  | string
  | number
  | boolean
  | null
  | undefined
  | Serializable[]
  | SerializableObject;

/**
 * 深只读类�? */
// ArkTS兼容的深只读实现 - 简化版�?export interface DeepReadonlyObject {
  // ArkTS兼容：不使用索引签名
  getReadonly(key: string): DeepReadonlyValue;
  hasReadonly(key: string): boolean;
}

// 简化版：直接返回对象类型，不使用条件类�?export type DeepReadonlyValue = 
  | string
  | number
  | boolean
  | null
  | undefined
  | ReadonlyArray<DeepReadonlyValue>
  | DeepReadonlyObject;

/**
 * 可选键类型
 */
// ArkTS兼容的可选属性实�?export interface OptionalBase<T> {
  // ArkTS兼容：不使用索引签名
  getOptional(key: string): T;
  hasOptional(key: string): boolean;
}

/**
 * 必需键类�? */
// ArkTS兼容的必需属性实�?export interface RequiredBase<T> {
  // ArkTS兼容：不使用索引签名
  getRequired(key: string): T;
  hasRequired(key: string): boolean;
}

/**
 * 空对象类型（非null且非undefined的对象）
 */
export type NonEmptyObject<T extends object> = T;

/**
 * 排除null和undefined的类�? */
// ArkTS兼容的非空类型实�?export type NonNullableValue<T> = T;

/**
 * 通用函数类型 - 接受任意参数，返回任意�? */
export interface AnyFunction {
  (...args: never[]): never;
}

/**
 * 异步函数类型 - 接受任意参数，返回Promise
 */
export interface AsyncFunction<T> {
  (...args: never[]): Promise<T>;
}

/**
 * 延迟执行的返回类�? */
export interface DelayResult {
  clear: () => void;
  promise: Promise<void>;
}
