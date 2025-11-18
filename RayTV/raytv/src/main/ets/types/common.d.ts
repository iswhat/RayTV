// 通用类型定义

// 同步数据接口
export interface SyncData<T = any> {
  data: T;
  timestamp: number;
  deviceId: string;
}

// 数据变更监听器类型
export type DataChangeListener<T = any> = (key: string, data: T, deviceId: string) => void;

// 通用事件监听器类型
export type EventListener<T = any> = (event: string, data?: T) => void;

// 通用API响应接口
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  code?: number;
}

// 通用缓存项接口
export interface CacheItem<T = any> {
  data: T;
  expiry: number;
  timestamp: number;
  metadata?: Record<string, any>;
}

// 通用配置项接口
export interface ConfigItem<T = any> {
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
export interface HttpResponse<T = any> {
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
export interface PaginatedResponse<T = any> {
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
  details?: Record<string, any>;
}
