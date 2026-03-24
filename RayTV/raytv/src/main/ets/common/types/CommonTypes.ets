/**
 * CommonTypes.ets
 * 通用类型定义 - 用于减少any/unknown类型的使用
 */

// ==================== 媒体相关类型 ====================

export interface MediaTrack {
  id: string;
  language: string;
  type: string;
  url: string;
}

export interface MediaItemBase {
  id: string;
  title: string;
  cover: string;
  type: string;
}

// ==================== 配置相关类型 ====================

export interface ConfigValue {
  [key: string]: string | number | boolean | null;
}

export interface ConfigData {
  [key: string]: ConfigValue | ConfigData;
}

// ==================== 网络相关类型 ====================

export interface NetworkRequest {
  url: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  data?: Record<string, string | number>;
  headers?: Record<string, string>;
}

export interface NetworkResponse<T> {
  data: T;
  status: number;
  headers: Record<string, string>;
}

// ==================== 缓存相关类型 ====================

export interface CacheItem<T> {
  data: T;
  timestamp: number;
  expiry: number;
}

// ==================== 事件相关类型 ====================

export interface EventListener {
  (event: string, ...args: string[]): void;
}

// ==================== UI相关类型 ====================

export interface UIComponent {
  id: string;
  visible: boolean;
  enabled: boolean;
}

// ==================== 数据相关类型 ====================

export interface DataItem {
  id: string;
  data: Record<string, Object>;
}

export interface DataCollection<T extends DataItem> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

// ==================== 工具类型 ====================

export type Nullable<T> = T | null;
export type Optional<T> = T | undefined;
export type Result<T, E = Error> = {
  success: true;
  data: T;
} | {
  success: false;
  error: E;
};
