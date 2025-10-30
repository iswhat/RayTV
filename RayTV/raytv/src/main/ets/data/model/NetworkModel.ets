// NetworkModel - 网络相关模型定义
// 定义网络请求和响应相关的数据结构和枚举

/**
 * HTTP请求方法枚举
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
 * 响应类型枚举
 */
export enum ResponseType {
  JSON = 'json',
  TEXT = 'text',
  ARRAY_BUFFER = 'arraybuffer',
  BLOB = 'blob'
}

/**
 * 请求选项接口
 */
export interface RequestOptions {
  /**
   * 请求头
   */
  headers?: Map<string, string>;
  
  /**
   * 请求数据
   */
  data?: unknown;
  
  /**
   * URL查询参数
   */
  params?: Record<string, unknown>;
  
  /**
   * 超时时间（毫秒）
   */
  timeout?: number;
  
  /**
   * 响应类型
   */
  responseType?: ResponseType;
  
  /**
   * 是否使用缓存
   */
  useCache?: boolean;
  
  /**
   * 缓存时间（毫秒）
   */
  cacheTime?: number;
  
  /**
   * 是否允许重定向
   */
  allowRedirects?: boolean;
  
  /**
   * 是否发送凭证
   */
  withCredentials?: boolean;
  
  /**
   * 请求优先级
   */
  priority?: 'low' | 'normal' | 'high';
  
  /**
   * 重试次数
   */
  retryCount?: number;
  
  /**
   * 重试延迟（毫秒）
   */
  retryDelay?: number;
  
  /**
   * 请求标记（用于取消请求）
   */
  requestId?: string;
}

/**
 * 网络状态枚举
 */
export enum NetworkStatus {
  /**
   * 未连接
   */
  DISCONNECTED = 'disconnected',
  
  /**
   * 已连接
   */
  CONNECTED = 'connected',
  
  /**
   * 连接中
   */
  CONNECTING = 'connecting',
  
  /**
   * 连接错误
   */
  ERROR = 'error'
}

/**
 * 网络类型枚举
 */
export enum NetworkType {
  /**
   * 未知网络
   */
  UNKNOWN = 'unknown',
  
  /**
   * 有线网络
   */
  ETHERNET = 'ethernet',
  
  /**
   * WiFi网络
   */
  WIFI = 'wifi',
  
  /**
   * 移动网络 - 2G
   */
  MOBILE_2G = 'mobile_2g',
  
  /**
   * 移动网络 - 3G
   */
  MOBILE_3G = 'mobile_3g',
  
  /**
   * 移动网络 - 4G
   */
  MOBILE_4G = 'mobile_4g',
  
  /**
   * 移动网络 - 5G
   */
  MOBILE_5G = 'mobile_5g',
  
  /**
   * 其他网络
   */
  OTHER = 'other'
}

/**
 * 代理类型枚举
 */
export enum ProxyType {
  /**
   * 不使用代理
   */
  NONE = 'none',
  
  /**
   * HTTP代理
   */
  HTTP = 'http',
  
  /**
   * HTTPS代理
   */
  HTTPS = 'https',
  
  /**
   * SOCKS5代理
   */
  SOCKS5 = 'socks5'
}

/**
 * 代理配置接口
 */
export interface ProxyConfig {
  /**
   * 代理类型
   */
  type: ProxyType;
  
  /**
   * 代理服务器地址
   */
  host: string;
  
  /**
   * 代理服务器端口
   */
  port: number;
  
  /**
   * 用户名（可选）
   */
  username?: string;
  
  /**
   * 密码（可选）
   */
  password?: string;
  
  /**
   * 绕过代理的域名列表
   */
  bypassList?: string[];
}

/**
 * 网络配置接口
 */
export interface NetworkConfig {
  /**
   * 基础URL
   */
  baseUrl: string;
  
  /**
   * 默认超时时间（毫秒）
   */
  timeout: number;
  
  /**
   * 默认重试次数
   */
  retryCount: number;
  
  /**
   * 默认重试延迟（毫秒）
   */
  retryDelay: number;
  
  /**
   * 是否使用缓存
   */
  useCache: boolean;
  
  /**
   * 默认缓存时间（毫秒）
   */
  cacheTime: number;
  
  /**
   * 代理配置
   */
  proxyConfig: ProxyConfig;
  
  /**
   * 最大并发连接数
   */
  maxConnections: number;
  
  /**
   * 是否在弱网下压缩数据
   */
  compressDataOnWeakNetwork: boolean;
}

/**
 * 网络统计信息接口
 */
export interface NetworkStats {
  /**
   * 总请求次数
   */
  totalRequests: number;
  
  /**
   * 成功请求次数
   */
  successRequests: number;
  
  /**
   * 失败请求次数
   */
  failedRequests: number;
  
  /**
   * 平均响应时间（毫秒）
   */
  averageResponseTime: number;
  
  /**
   * 总上传流量（字节）
   */
  totalUploadBytes: number;
  
  /**
   * 总下载流量（字节）
   */
  totalDownloadBytes: number;
  
  /**
   * 当前网络类型
   */
  currentNetworkType: NetworkType;
  
  /**
   * 当前网络状态
   */
  currentNetworkStatus: NetworkStatus;
  
  /**
   * 最后网络变化时间戳
   */
  lastNetworkChangeTimestamp: number;
}

/**
 * 网络事件类型枚举
 */
export enum NetworkEventType {
  /**
   * 网络状态变化
   */
  STATUS_CHANGED = 'status_changed',
  
  /**
   * 网络类型变化
   */
  TYPE_CHANGED = 'type_changed',
  
  /**
   * 带宽变化
   */
  BANDWIDTH_CHANGED = 'bandwidth_changed',
  
  /**
   * 代理状态变化
   */
  PROXY_STATUS_CHANGED = 'proxy_status_changed',
  
  /**
   * 网络错误
   */
  ERROR = 'error'
}

/**
 * 网络监听器接口
 */
export interface NetworkListener {
  /**
   * 处理网络事件
   * @param eventType 事件类型
   * @param data 事件数据
   */
  onNetworkEvent(eventType: NetworkEventType, data: unknown): void;
}

/**
 * 网络拦截器接口
 */
export interface NetworkInterceptor<T = unknown, R = unknown> {
  /**
   * 请求拦截
   * @param request 请求配置
   * @returns 处理后的请求配置
   */
  interceptRequest(request: RequestOptions & { url: string; method: RequestMethod }): T;
  
  /**
   * 响应拦截
   * @param response 响应数据
   * @returns 处理后的响应数据
   */
  interceptResponse(response: unknown): R;
}

/**
 * 网络测速结果接口
 */
export interface SpeedTestResult {
  /**
   * 下载速度（字节/秒）
   */
  downloadSpeed: number;
  
  /**
   * 上传速度（字节/秒）
   */
  uploadSpeed: number;
  
  /**
   * 延迟（毫秒）
   */
  latency: number;
  
  /**
   * 抖动（毫秒）
   */
  jitter: number;
  
  /**
   * 丢包率（百分比）
   */
  packetLoss: number;
  
  /**
   * 测速时间戳
   */
  timestamp: number;
  
  /**
   * 测速服务器
   */
  server?: string;
}

/**
 * 下载任务状态枚举
 */
export enum DownloadTaskStatus {
  /**
   * 等待中
   */
  WAITING = 'waiting',
  
  /**
   * 下载中
   */
  DOWNLOADING = 'downloading',
  
  /**
   * 暂停
   */
  PAUSED = 'paused',
  
  /**
   * 完成
   */
  COMPLETED = 'completed',
  
  /**
   * 失败
   */
  FAILED = 'failed',
  
  /**
   * 取消
   */
  CANCELLED = 'cancelled'
}

/**
 * 文件上传配置接口
 */
export interface UploadConfig {
  /**
   * 文件路径
   */
  filePath: string;
  
  /**
   * 文件类型
   */
  fileType?: string;
  
  /**
   * 上传字段名
   */
  fieldName?: string;
  
  /**
   * 额外表单数据
   */
  formData?: Record<string, string>;
  
  /**
   * 分块大小（字节）
   */
  chunkSize?: number;
  
  /**
   * 是否启用断点续传
   */
  enableResume?: boolean;
}

/**
 * 下载进度接口
 */
export interface DownloadProgress {
  /**
   * 已下载字节数
   */
  downloadedBytes: number;
  
  /**
   * 总字节数
   */
  totalBytes: number;
  
  /**
   * 下载百分比
   */
  progress: number;
  
  /**
   * 当前速度（字节/秒）
   */
  speed: number;
  
  /**
   * 剩余时间（秒）
   */
  remainingTime?: number;
}

/**
 * WebSocket状态枚举
 */
export enum WebSocketStatus {
  /**
   * 连接中
   */
  CONNECTING = 'connecting',
  
  /**
   * 已连接
   */
  CONNECTED = 'connected',
  
  /**
   * 关闭中
   */
  CLOSING = 'closing',
  
  /**
   * 已关闭
   */
  CLOSED = 'closed',
  
  /**
   * 错误
   */
  ERROR = 'error'
}

/**
 * WebSocket配置接口
 */
export interface WebSocketConfig {
  /**
   * WebSocket URL
   */
  url: string;
  
  /**
   * 协议
   */
  protocols?: string | string[];
  
  /**
   * 心跳间隔（毫秒）
   */
  heartbeatInterval?: number;
  
  /**
   * 重连次数
   */
  reconnectAttempts?: number;
  
  /**
   * 重连延迟（毫秒）
   */
  reconnectDelay?: number;
  
  /**
   * 是否自动重连
   */
  autoReconnect?: boolean;
}
