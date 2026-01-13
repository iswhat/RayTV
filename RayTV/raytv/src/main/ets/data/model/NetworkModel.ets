// NetworkModel - 网络相关类型定义 // Network-related type definitions
// 定义网络请求和响应相关的数据结构和枚举 // Define data structures and enums related to network requests and responses

/**
 * HTTP 请求方法枚举 // HTTP request method enum
 */
export enum RequestMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
  PATCH = 'PATCH',
  HEAD = 'HEAD',
  OPTIONS = 'OPTIONS'
}

/**
 * 响应类型枚举 // Response type enum
 */
export enum ResponseType {
  JSON = 'json',
  TEXT = 'text',
  ARRAY_BUFFER = 'arraybuffer',
  BLOB = 'blob'
}

/**
 * 请求选项接口 // Request options interface
 */
export interface RequestOptions {
  /**
   * 请求头 // Request headers
   */
  headers?: Map<string, string>;
  
  /**
   * 请求数据 // Request data
   */
  data?: Record<string, string | number | boolean | null>;
  
  /**
   * URL查询参数 // URL query parameters
   */
  params?: Record<string, unknown>;
  
  /**
   * 超时时间（秒） // Timeout in seconds
   */
  timeout?: number;
  
  /**
   * 响应类型 // Response type
   */
  responseType?: ResponseType;
  
  /**
   * 是否使用缓存 // Whether to use cache
   */
  useCache?: boolean;
  
  /**
   * 缓存时间（秒） // Cache time in seconds
   */
  cacheTime?: number;
  
  /**
   * 是否允许重定向 // Whether to allow redirects
   */
  allowRedirects?: boolean;
  
  /**
   * 是否携带凭证 // Whether to include credentials
   */
  withCredentials?: boolean;
  
  /**
   * 请求优先级 // Request priority
   */
  priority?: 'low' | 'normal' | 'high';
  
  /**
   * 重试次数 // Retry count
   */
  retryCount?: number;
  
  /**
   * 重试延迟（秒） // Retry delay in seconds
   */
  retryDelay?: number;
  
  /**
   * 请求标识（用于取消请求） // Request ID (for canceling requests)
   */
  requestId?: string;
}

/**
 * 网络状态枚举 // Network status enum
 */
export enum NetworkStatus {
  /**
   * 未连接 // Disconnected
   */
  DISCONNECTED = 'disconnected',
  
  /**
   * 已连接 // Connected
   */
  CONNECTED = 'connected',
  
  /**
   * 连接中 // Connecting
   */
  CONNECTING = 'connecting',
  
  /**
   * 连接错误 // Connection error
   */
  ERROR = 'error'
}

/**
 * 网络类型枚举 // Network type enum
 */
export enum NetworkType {
  /**
   * 未知网络 // Unknown network
   */
  UNKNOWN = 'unknown',
  
  /**
   * 有线网络 // Ethernet network
   */
  ETHERNET = 'ethernet',
  
  /**
   * WiFi网络 // WiFi network
   */
  WIFI = 'wifi',
  
  /**
   * 移动网络 - 2G // Mobile network - 2G
   */
  MOBILE_2G = 'mobile_2g',
  
  /**
   * 移动网络 - 3G // Mobile network - 3G
   */
  MOBILE_3G = 'mobile_3g',
  
  /**
   * 移动网络 - 4G // Mobile network - 4G
   */
  MOBILE_4G = 'mobile_4g',
  
  /**
   * 移动网络 - 5G // Mobile network - 5G
   */
  MOBILE_5G = 'mobile_5g',
  
  /**
   * 其他网络 // Other network
   */
  OTHER = 'other'
}

/**
 * 代理类型枚举 // Proxy type enum
 */
export enum ProxyType {
  /**
   * 不使用代理 // No proxy
   */
  NONE = 'none',
  
  /**
   * HTTP代理 // HTTP proxy
   */
  HTTP = 'http',
  
  /**
   * HTTPS代理 // HTTPS proxy
   */
  HTTPS = 'https',
  
  /**
   * SOCKS5代理 // SOCKS5 proxy
   */
  SOCKS5 = 'socks5'
}

/**
 * 代理配置接口 // Proxy configuration interface
 */
export interface ProxyConfig {
  /**
   * 代理类型 // Proxy type
   */
  type: ProxyType;
  
  /**
   * 代理服务器地址 // Proxy server host
   */
  host: string;
  
  /**
   * 代理服务器端口 // Proxy server port
   */
  port: number;
  
  /**
   * 用户名（可选） // Username (optional)
   */
  username?: string;
  
  /**
   * 密码（可选） // Password (optional)
   */
  password?: string;
  
  /**
   * 跳过代理的域名列表 // List of domains to bypass proxy
   */
  bypassList?: string[];
}

/**
 * 网络配置接口 // Network configuration interface
 */
export interface NetworkConfig {
  /**
   * 基础URL // Base URL
   */
  baseUrl: string;
  
  /**
   * 默认超时时间（秒） // Default timeout in seconds
   */
  timeout: number;
  
  /**
   * 默认重试次数 // Default retry count
   */
  retryCount: number;
  
  /**
   * 默认重试延迟（秒） // Default retry delay in seconds
   */
  retryDelay: number;
  
  /**
   * 是否使用缓存 // Whether to use cache
   */
  useCache: boolean;
  
  /**
   * 默认缓存时间（秒） // Default cache time in seconds
   */
  cacheTime: number;
  
  /**
   * 代理配置 // Proxy configuration
   */
  proxyConfig: ProxyConfig;
  
  /**
   * 最大并发连接数 // Maximum concurrent connections
   */
  maxConnections: number;
  
  /**
   * 是否在弱网下压缩数据 // Whether to compress data on weak network
   */
  compressDataOnWeakNetwork: boolean;
}

/**
 * 网络统计信息接口 // Network statistics interface
 */
export interface NetworkStats {
  /**
   * 总请求次数 // Total request count
   */
  totalRequests: number;
  
  /**
   * 成功请求次数 // Success request count
   */
  successRequests: number;
  
  /**
   * 失败请求次数 // Failed request count
   */
  failedRequests: number;
  
  /**
   * 平均响应时间（秒） // Average response time in seconds
   */
  averageResponseTime: number;
  
  /**
   * 总上传流量（字节） // Total upload bytes
   */
  totalUploadBytes: number;
  
  /**
   * 总下载流量（字节） // Total download bytes
   */
  totalDownloadBytes: number;
  
  /**
   * 当前网络类型 // Current network type
   */
  currentNetworkType: NetworkType;
  
  /**
   * 当前网络状态 // Current network status
   */
  currentNetworkStatus: NetworkStatus;
  
  /**
   * 最后网络变更时间戳 // Last network change timestamp
   */
  lastNetworkChangeTimestamp: number;
}

/**
 * 网络事件类型枚举 // Network event type enum
 */
export enum NetworkEventType {
  /**
   * 网络状态变更 // Network status changed
   */
  STATUS_CHANGED = 'status_changed',
  
  /**
   * 网络类型变更 // Network type changed
   */
  TYPE_CHANGED = 'type_changed',
  
  /**
   * 带宽变更 // Bandwidth changed
   */
  BANDWIDTH_CHANGED = 'bandwidth_changed',
  
  /**
   * 代理状态变更 // Proxy status changed
   */
  PROXY_STATUS_CHANGED = 'proxy_status_changed',
  
  /**
   * 网络错误 // Network error
   */
  ERROR = 'error'
}

/**
 * 网络监听器接口 // Network listener interface
 */
export interface NetworkListener {
  /**
   * 处理网络事件 // Handle network event
   * @param eventType 事件类型 // Event type
   * @param data 事件数据 // Event data
   */
  onNetworkEvent(eventType: NetworkEventType, data: Record<string, string | number | boolean | null>): void;
}

/**
 * 网络拦截器接口 // Network interceptor interface
 */
export interface NetworkInterceptor<T = unknown, R = unknown> {
  /**
   * 请求拦截 // Intercept request
   * @param request 请求配置 // Request configuration
   * @returns 处理后的请求配置 // Processed request configuration
   */
  interceptRequest(request: RequestOptions & { url: string; method: RequestMethod }): T;
  
  /**
   * 响应拦截 // Intercept response
   * @param response 响应数据 // Response data
   * @returns 处理后的响应数据 // Processed response data
   */
  interceptResponse(response: Record<string, string | number | boolean | null>): R;
}

/**
 * 网络测速结果接口 // Network speed test result interface
 */
export interface SpeedTestResult {
  /**
   * 下载速度（字节/秒） // Download speed (bytes/second)
   */
  downloadSpeed: number;
  
  /**
   * 上传速度（字节/秒） // Upload speed (bytes/second)
   */
  uploadSpeed: number;
  
  /**
   * 延迟（秒） // Latency (seconds)
   */
  latency: number;
  
  /**
   * 抖动（秒） // Jitter (seconds)
   */
  jitter: number;
  
  /**
   * 丢包率（百分比） // Packet loss (percentage)
   */
  packetLoss: number;
  
  /**
   * 测速时间戳 // Test timestamp
   */
  timestamp: number;
  
  /**
   * 测速服务器 // Test server
   */
  server?: string;
}

/**
 * 下载任务状态枚举 // Download task status enum
 */
export enum DownloadTaskStatus {
  /**
   * 等待中 // Waiting
   */
  WAITING = 'waiting',
  
  /**
   * 下载中 // Downloading
   */
  DOWNLOADING = 'downloading',
  
  /**
   * 暂停 // Paused
   */
  PAUSED = 'paused',
  
  /**
   * 完成 // Completed
   */
  COMPLETED = 'completed',
  
  /**
   * 失败 // Failed
   */
  FAILED = 'failed',
  
  /**
   * 取消 // Cancelled
   */
  CANCELLED = 'cancelled'
}

/**
 * 文件上传配置接口 // File upload configuration interface
 */
export interface UploadConfig {
  /**
   * 文件路径 // File path
   */
  filePath: string;
  
  /**
   * 文件类型 // File type
   */
  fileType?: string;
  
  /**
   * 上传字段名 // Upload field name
   */
  fieldName?: string;
  
  /**
   * 额外表单数据 // Extra form data
   */
  formData?: Record<string, string>;
  
  /**
   * 分块大小（字节） // Chunk size in bytes
   */
  chunkSize?: number;
  
  /**
   * 是否启用断点续传 // Whether to enable resume upload
   */
  enableResume?: boolean;
}

/**
 * 下载进度接口 // Download progress interface
 */
export interface DownloadProgress {
  /**
   * 已下载字节数 // Downloaded bytes
   */
  downloadedBytes: number;
  
  /**
   * 总字节数 // Total bytes
   */
  totalBytes: number;
  
  /**
   * 下载百分比 // Download progress percentage
   */
  progress: number;
  
  /**
   * 当前速度（字节/秒） // Current speed (bytes/second)
   */
  speed: number;
  
  /**
   * 剩余时间（秒） // Remaining time (seconds)
   */
  remainingTime?: number;
}

/**
 * WebSocket 状态枚举 // WebSocket status enum
 */
export enum WebSocketStatus {
  /**
   * 连接中 // Connecting
   */
  CONNECTING = 'connecting',
  
  /**
   * 已连接 // Connected
   */
  CONNECTED = 'connected',
  
  /**
   * 关闭中 // Closing
   */
  CLOSING = 'closing',
  
  /**
   * 已关闭 // Closed
   */
  CLOSED = 'closed',
  
  /**
   * 错误 // Error
   */
  ERROR = 'error'
}

/**
 * WebSocket 配置接口 // WebSocket configuration interface
 */
export interface WebSocketConfig {
  /**
   * WebSocket URL
   */
  url: string;
  
  /**
   * 协议 // Protocols
   */
  protocols?: string | string[];
  
  /**
   * 心跳间隔（秒） // Heartbeat interval (seconds)
   */
  heartbeatInterval?: number;
  
  /**
   * 重连次数 // Reconnect attempts
   */
  reconnectAttempts?: number;
  
  /**
   * 重连延迟（秒） // Reconnect delay (seconds)
   */
  reconnectDelay?: number;
  
  /**
   * 是否自动重连 // Whether to auto reconnect
   */
  autoReconnect?: boolean;
}




