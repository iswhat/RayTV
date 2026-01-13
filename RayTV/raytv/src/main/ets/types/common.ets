// common.ets - 通用类型定义 // Common type definitions

// 同步数据接口 // Sync data interface
export interface SyncData<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  data: T; // Sync data | 同步数据
  timestamp: number; // Timestamp | 时间戳
  deviceId: string; // Device ID | 设备ID
}

// 数据变更监听器类型 // Data change listener type
export type DataChangeListener<T = string | number | boolean | null | Record<string, string | number | boolean | null>> = (key: string, data: T, deviceId: string) => void;

// 通用事件监听器类型 // Common event listener type
export type EventListener<T = string | number | boolean | null | Record<string, string | number | boolean | null>> = (event: string, data?: T) => void;

// 通用API响应接口 // Common API response interface
export interface ApiResponse<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  success: boolean; // Whether the request succeeded | 请求是否成功
  data?: T; // Response data | 响应数据
  error?: string; // Error message if failed | 失败时的错误信息
  code?: number; // Response code | 响应代码
}

// 通用缓存项接口 // Common cache item interface
export interface CacheItem<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  data: T; // Cached data | 缓存数据
  expiry: number; // Expiry timestamp | 过期时间戳
  timestamp: number; // Creation timestamp | 创建时间戳
  metadata?: Record<string, string | number | boolean | null>; // Additional metadata | 附加元数据
}

// 通用配置项接口 // Common config item interface
export interface ConfigItem<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  key: string; // Config key | 配置键
  value: T; // Current value | 当前值
  defaultValue: T; // Default value | 默认值
  description?: string; // Config description | 配置描述
  type: string; // Value type | 值类型
  validate?: (value: T) => boolean; // Validation function | 验证函数
}

// 网络请求选项 // Network request options
export interface HttpOptions {
  headers?: Record<string, string>; // Request headers | 请求头
  timeout?: number; // Request timeout in milliseconds | 请求超时时间（毫秒）
  responseType?: 'json' | 'text' | 'arraybuffer'; // Response type | 响应类型
}

// 网络响应接口 // Network response interface
export interface HttpResponse<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  status: number; // HTTP status code | HTTP状态码
  data: T; // Response data | 响应数据
  headers?: Record<string, string>; // Response headers | 响应头
}

// 分页请求参数 // Pagination request params
export interface PaginationParams {
  page: number; // Page number | 页码
  pageSize: number; // Items per page | 每页项目数
}

// 分页响应 // Paginated response
export interface PaginatedResponse<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  items: T[]; // Items in current page | 当前页项目
  total: number; // Total number of items | 项目总数
  page: number; // Current page number | 当前页码
  pageSize: number; // Items per page | 每页项目数
  hasMore: boolean; // Whether there are more pages | 是否有更多页
}

// 错误响应接口 // Error response interface
export interface ErrorResponse {
  error: string; // Error message | 错误信息
  code?: number; // Error code | 错误代码
  details?: Record<string, string | number | boolean | null>; // Additional error details | 附加错误详情
}
