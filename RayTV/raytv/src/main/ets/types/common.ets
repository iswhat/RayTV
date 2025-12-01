// 通用类型定义

// 同步数据接口
export interface SyncData<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  data: T;
  timestamp: number;
  deviceId: string;
}

// 数据变更监听器类型
export type DataChangeListener<T = string | number | boolean | null | Record<string, string | number | boolean | null>> = (key: string, data: T, deviceId: string) => void;

// 通用事件监听器类型
export type EventListener<T = string | number | boolean | null | Record<string, string | number | boolean | null>> = (event: string, data?: T) => void;

// 通用API响应接口
export interface ApiResponse<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  success: boolean;
  data?: T;
  error?: string;
  code?: number;
}

// 通用缓存项接口
export interface CacheItem<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  data: T;
  expiry: number;
  timestamp: number;
  metadata?: Record<string, string | number | boolean | null>;
}

// 通用配置项接口
export interface ConfigItem<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  key: string;
  value: T;
  defaultValue: T;
  description?: string;
  type: string;
  validate?: (value: T) => boolean;
}

// 网络请求选项
export interface HttpOptions {
  headers?: Record<string, string>;
  timeout?: number;
  responseType?: 'json' | 'text' | 'arraybuffer';
}

// 网络响应接口
export interface HttpResponse<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  status: number;
  data: T;
  headers?: Record<string, string>;
}

// 分页请求参数
export interface PaginationParams {
  page: number;
  pageSize: number;
}

// 分页响应
export interface PaginatedResponse<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

// 错误响应接口
export interface ErrorResponse {
  error: string;
  code?: number;
  details?: Record<string, string | number | boolean | null>;
}