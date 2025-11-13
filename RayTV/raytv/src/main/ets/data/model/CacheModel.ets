// CacheModel - 缓存相关模型定义
// 定义应用缓存、数据缓存等相关的数据模型

/**
 * 缓存值类型别名 - 支持的具体缓存数据类型
 */
export type CacheValue =
  | string              // 字符串
  | number              // 数字
  | boolean             // 布尔值
  | ArrayBuffer         // 二进制数据
  | Object              // 对象类型 (使用Object替代Record<string, unknown>符合ArkTS规范)
  | string[]            // 字符串数组
  | number[]            // 数字数组
  | boolean[];          // 布尔值数组

/**
 * 缓存类型枚举
 */
export enum CacheType {
  /**
   * 内存缓存
   */
  MEMORY = 'memory',
  
  /**
   * 磁盘缓存
   */
  DISK = 'disk',
  
  /**
   * 网络缓存
   */
  NETWORK = 'network',
  
  /**
   * 图片缓存
   */
  IMAGE = 'image',
  
  /**
   * 视频缓存
   */
  VIDEO = 'video',
  
  /**
   * 音频缓存
   */
  AUDIO = 'audio',
  
  /**
   * 文本缓存
   */
  TEXT = 'text',
  
  /**
   * JSON缓存
   */
  JSON = 'json',
  
  /**
   * 字幕缓存
   */
  SUBTITLE = 'subtitle',
  
  /**
   * 临时缓存
   */
  TEMPORARY = 'temporary',
  
  /**
   * 应用缓存
   */
  APP = 'app'
}

/**
 * 缓存策略枚举
 */
export enum CacheStrategy {
  /**
   * 仅内存
   */
  MEMORY_ONLY = 'memory_only',
  
  /**
   * 仅磁盘
   */
  DISK_ONLY = 'disk_only',
  
  /**
   * 内存优先
   */
  MEMORY_FIRST = 'memory_first',
  
  /**
   * 磁盘优先
   */
  DISK_FIRST = 'disk_first',
  
  /**
   * 双重缓存
   */
  BOTH = 'both',
  
  /**
   * 自定义
   */
  CUSTOM = 'custom'
}

/**
 * 缓存优先级枚举
 */
export enum CachePriority {
  /**
   * 低优先级
   */
  LOW = 'low',
  
  /**
   * 中优先级
   */
  MEDIUM = 'medium',
  
  /**
   * 高优先级
   */
  HIGH = 'high',
  
  /**
   * 最高优先级
   */
  HIGHEST = 'highest',
  
  /**
   * 持久化（永不自动清除）
   */
  PERSISTENT = 'persistent'
}

/**
 * 缓存项接口
 */
export interface CacheItem {
  /**
   * 缓存键
   */
  key: string;
  
  /**
   * 缓存值
   */
  value: CacheValue;
  
  /**
   * 缓存类型
   */
  type: CacheType;
  
  /**
   * 创建时间
   */
  createdAt: number;
  
  /**
   * 最后访问时间
   */
  lastAccessedAt: number;
  
  /**
   * 过期时间
   */
  expiresAt?: number;
  
  /**
   * 数据大小（字节）
   */
  size: number;
  
  /**
   * 优先级
   */
  priority: CachePriority;
  
  /**
   * 访问次数
   */
  accessCount: number;
  
  /**
   * 缓存版本
   */
  version?: string;
  
  /**
   * 是否加密
   */
  encrypted: boolean;
  
  /**
   * 标签
   */
  tags?: string[];
}

/**
 * 缓存元数据接口
 */
export interface CacheMetadata {
  /**
   * 缓存键
   */
  key: string;
  
  /**
   * 缓存类型
   */
  type: CacheType;
  
  /**
   * 创建时间
   */
  createdAt: number;
  
  /**
   * 最后访问时间
   */
  lastAccessedAt: number;
  
  /**
   * 过期时间
   */
  expiresAt?: number;
  
  /**
   * 数据大小（字节）
   */
  size: number;
  
  /**
   * 优先级
   */
  priority: CachePriority;
  
  /**
   * 访问次数
   */
  accessCount: number;
  
  /**
   * 是否压缩
   */
  compressed: boolean;
  
  /**
   * 是否加密
   */
  encrypted: boolean;
  
  /**
   * 缓存策略
   */
  strategy: CacheStrategy;
  
  /**
   * 来源
   */
  source?: string;
}

/**
 * 缓存配置接口
 */
export interface CacheConfig {
  /**
   * 缓存名称
   */
  name: string;
  
  /**
   * 缓存路径
   */
  path: string;
  
  /**
   * 最大缓存大小（字节）
   */
  maxSize: number;
  
  /**
   * 默认过期时间（毫秒）
   */
  defaultExpireTime: number;
  
  /**
   * 缓存策略
   */
  strategy: CacheStrategy;
  
  /**
   * 是否自动清理
   */
  autoCleanup: boolean;
  
  /**
   * 清理间隔（毫秒）
   */
  cleanupInterval: number;
  
  /**
   * 是否压缩数据
   */
  compressionEnabled: boolean;
  
  /**
   * 是否加密数据
   */
  encryptionEnabled: boolean;
  
  /**
   * 内存缓存最大条目数
   */
  maxMemoryEntries: number;
  
  /**
   * 是否使用LRU策略
   */
  useLru: boolean;
  
  /**
   * 存储模式
   */
  storageMode: 'file' | 'database' | 'hybrid';
}

/**
 * 缓存统计接口
 */
export interface CacheStats {
  /**
   * 当前缓存大小（字节）
   */
  currentSize: number;
  
  /**
   * 最大缓存大小（字节）
   */
  maxSize: number;
  
  /**
   * 缓存条目数
   */
  itemCount: number;
  
  /**
   * 内存缓存大小
   */
  memoryCacheSize: number;
  
  /**
   * 磁盘缓存大小
   */
  diskCacheSize: number;
  
  /**
   * 命中率
   */
  hitRate: number;
  
  /**
   * 未命中率
   */
  missRate: number;
  
  /**
   * 过期条目数
   */
  expiredCount: number;
  
  /**
   * 最后清理时间
   */
  lastCleanupTime: number;
  
  /**
   * 按类型统计
   */
  byType: {
    [key in CacheType]: {
      count: number;
      size: number;
    }
  };
}

/**
 * 缓存清理选项接口
 */
export interface CacheCleanupOptions {
  /**
   * 清理类型
   */
  types?: CacheType[];
  
  /**
   * 清理过期项
   */
  expired?: boolean;
  
  /**
   * 清理最小优先级
   */
  minPriority?: CachePriority;
  
  /**
   * 保留大小（字节）
   */
  keepSize?: number;
  
  /**
   * 保留时间（毫秒）内的缓存
   */
  keepTime?: number;
  
  /**
   * 排除的键
   */
  excludeKeys?: string[];
  
  /**
   * 排除的标签
   */
  excludeTags?: string[];
  
  /**
   * 是否执行实际清理
   */
  dryRun?: boolean;
  
  /**
   * 是否清理全部
   */
  all?: boolean;
}

/**
 * 缓存清理结果接口
 */
export interface CacheCleanupResult {
  /**
   * 清理的条目数
   */
  removedCount: number;
  
  /**
   * 释放的空间（字节）
   */
  freedSpace: number;
  
  /**
   * 清理时间（毫秒）
   */
  cleanupTime: number;
  
  /**
   * 是否为模拟运行
   */
  isDryRun: boolean;
  
  /**
   * 按类型清理统计
   */
  byType: {
    [key in CacheType]?: {
      count: number;
      size: number;
    }
  };
}

/**
 * 缓存搜索参数接口
 */
export interface CacheSearchParams {
  /**
   * 搜索键模式
   */
  keyPattern?: string;
  
  /**
   * 缓存类型
   */
  types?: CacheType[];
  
  /**
   * 最小优先级
   */
  minPriority?: CachePriority;
  
  /**
   * 创建时间范围（开始）
   */
  createdAfter?: number;
  
  /**
   * 创建时间范围（结束）
   */
  createdBefore?: number;
  
  /**
   * 是否包含过期项
   */
  includeExpired?: boolean;
  
  /**
   * 标签过滤
   */
  tags?: string[];
  
  /**
   * 排序字段
   */
  sortBy?: 'createdAt' | 'lastAccessedAt' | 'size' | 'accessCount' | 'priority';
  
  /**
   * 排序方向
   */
  sortOrder?: 'asc' | 'desc';
  
  /**
   * 分页大小
   */
  limit?: number;
  
  /**
   * 分页偏移
   */
  offset?: number;
}

/**
 * 缓存搜索结果接口
 */
export interface CacheSearchResult {
  /**
   * 缓存条目列表
   */
  items: CacheMetadata[];
  
  /**
   * 总条目数
   */
  totalCount: number;
  
  /**
   * 是否还有更多
   */
  hasMore: boolean;
  
  /**
   * 搜索时间（毫秒）
   */
  searchTime: number;
}

/**
 * 预加载缓存选项接口
 */
export interface PreloadCacheOptions {
  /**
   * 缓存键
   */
  keys: string[];
  
  /**
   * 预加载类型
   */
  type: CacheType;
  
  /**
   * 优先级
   */
  priority?: CachePriority;
  
  /**
   * 过期时间
   */
  expireTime?: number;
  
  /**
   * 预加载回调
   */
  onProgress?: (progress: number) => void;
}

/**
 * 缓存事件类型枚举
 */
export enum CacheEventType {
  /**
   * 添加缓存
   */
  ADDED = 'added',
  
  /**
   * 获取缓存
   */
  GET = 'get',
  
  /**
   * 删除缓存
   */
  DELETED = 'deleted',
  
  /**
   * 更新缓存
   */
  UPDATED = 'updated',
  
  /**
   * 清理缓存
   */
  CLEANED = 'cleaned',
  
  /**
   * 过期
   */
  EXPIRED = 'expired',
  
  /**
   * 大小变化
   */
  SIZE_CHANGED = 'size_changed',
  
  /**
   * 命中率变化
   */
  HIT_RATE_CHANGED = 'hit_rate_changed'
}

/**
 * 缓存事件数据接口
 */
export interface CacheEventData {
  /**
   * 清理统计（针对CLEANED事件）
   */
  cleanupStats?: {
    removedCount: number;
    freedSpace: number;
  };
  
  /**
   * 命中率数据（针对HIT_RATE_CHANGED事件）
   */
  hitRateData?: {
    hitRate: number;
    totalRequests: number;
    hits: number;
    misses: number;
  };
  
  /**
   * 大小变化数据（针对SIZE_CHANGED事件）
   */
  sizeChangeData?: {
    previousSize: number;
    currentSize: number;
    changeAmount: number;
  };
  
  /**
   * 自定义数据
   */
  customData?: Record<string, string | number | boolean>;
}

/**
 * 缓存事件接口
 */
export interface CacheEvent {
  /**
   * 事件类型
   */
  type: CacheEventType;
  
  /**
   * 缓存键
   */
  key?: string;
  
  /**
   * 缓存大小
   */
  size?: number;
  
  /**
   * 时间戳
   */
  timestamp: number;
  
  /**
   * 事件数据
   */
  data?: CacheEventData;
}

/**
 * 缓存压缩配置接口
 */
export interface CacheCompressionConfig {
  /**
   * 是否启用
   */
  enabled: boolean;
  
  /**
   * 压缩级别
   */
  level: number;
  
  /**
   * 压缩阈值（字节）
   */
  threshold: number;
  
  /**
   * 压缩算法
   */
  algorithm: 'gzip' | 'deflate' | 'lz4' | 'zstd';
}

/**
 * 缓存加密配置接口
 */
export interface CacheEncryptionConfig {
  /**
   * 是否启用
   */
  enabled: boolean;
  
  /**
   * 加密算法
   */
  algorithm: 'aes' | 'rsa' | '3des';
  
  /**
   * 密钥
   */
  key?: string;
  
  /**
   * 密钥别名
   */
  keyAlias?: string;
  
  /**
   * 加密模式
   */
  mode?: 'cbc' | 'gcm' | 'ctr';
}

/**
 * 缓存版本控制接口
 */
export interface CacheVersion {
  /**
   * 版本号
   */
  version: string;
  
  /**
   * 上次更新时间
   */
  lastUpdated: number;
  
  /**
   * 缓存条目数
   */
  itemCount: number;
  
  /**
   * 缓存大小
   */
  totalSize: number;
}

/**
 * 批量缓存操作结果接口
 */
export interface BatchCacheResult {
  /**
   * 成功的键
   */
  successKeys: string[];
  
  /**
   * 失败的键
   */
  failedKeys: string[];
  
  /**
   * 失败原因
   */
  failures: Record<string, string>;
  
  /**
   * 总操作时间
   */
  operationTime: number;
  
  /**
   * 操作类型
   */
  operationType: 'get' | 'set' | 'delete' | 'update';
}
