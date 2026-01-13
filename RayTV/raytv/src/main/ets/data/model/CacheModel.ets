// CacheModel - 缓存相关类型定义 | Cache-related type definitions
// 定义应用缓存、数据存储等相关的数据类型 | Define data types related to app caching and data storage

/**
 * 缓存值类型定义 - 支持的具体缓存数据类型 | Cache value type definition - supported concrete cache data types
 */
export type CacheValue =
  | string              // 字符串 | String
  | number              // 数字 | Number
  | boolean             // 布尔值 | Boolean
  | ArrayBuffer         // 二进制数据 | Binary data
  | Object              // 对象类型 (使用Object兼容Record<string, unknown>符合ArkTS规范) | Object type (using Object compatible with Record<string, unknown> to comply with ArkTS specifications)
  | string[]            // 字符串数组 | String array
  | number[]            // 数字数组 | Number array
  | boolean[];          // 布尔值数组 | Boolean array

/**
 * 缓存类型枚举 | Cache type enum
 */
export enum CacheType {
  /**
   * 内存缓存 | Memory cache
   */
  MEMORY = 'memory',
  
  /**
   * 磁盘缓存 | Disk cache
   */
  DISK = 'disk',
  
  /**
   * 网络缓存 | Network cache
   */
  NETWORK = 'network',
  
  /**
   * 图片缓存 | Image cache
   */
  IMAGE = 'image',
  
  /**
   * 视频缓存 | Video cache
   */
  VIDEO = 'video',
  
  /**
   * 音频缓存 | Audio cache
   */
  AUDIO = 'audio',
  
  /**
   * 文本缓存 | Text cache
   */
  TEXT = 'text',
  
  /**
   * JSON缓存 | JSON cache
   */
  JSON = 'json',
  
  /**
   * 字幕缓存 | Subtitle cache
   */
  SUBTITLE = 'subtitle',
  
  /**
   * 临时缓存 | Temporary cache
   */
  TEMPORARY = 'temporary',
  
  /**
   * 应用缓存 | App cache
   */
  APP = 'app'
}

/**
 * 缓存策略枚举 | Cache strategy enum
 */
export enum CacheStrategy {
  /**
   * 仅内存 | Memory only
   */
  MEMORY_ONLY = 'memory_only',
  
  /**
   * 仅磁盘 | Disk only
   */
  DISK_ONLY = 'disk_only',
  
  /**
   * 内存优先 | Memory first
   */
  MEMORY_FIRST = 'memory_first',
  
  /**
   * 磁盘优先 | Disk first
   */
  DISK_FIRST = 'disk_first',
  
  /**
   * 双重缓存 | Both caches
   */
  BOTH = 'both',
  
  /**
   * 自定义 | Custom
   */
  CUSTOM = 'custom'
}

/**
 * 缓存优先级枚举 | Cache priority enum
 */
export enum CachePriority {
  /**
   * 低优先级 | Low priority
   */
  LOW = 'low',
  
  /**
   * 中优先级 | Medium priority
   */
  MEDIUM = 'medium',
  
  /**
   * 高优先级 | High priority
   */
  HIGH = 'high',
  
  /**
   * 最高优先级 | Highest priority
   */
  HIGHEST = 'highest',
  
  /**
   * 持久化(永不自动清理) | Persistent (never automatically cleaned)
   */
  PERSISTENT = 'persistent'
}

/**
 * 缓存项接口 | Cache item interface
 */
export interface CacheItem {
  /**
   * 缓存键 | Cache key
   */
  key: string;
  
  /**
   * 缓存值 | Cache value
   */
  value: CacheValue;
  
  /**
   * 缓存类型 | Cache type
   */
  type: CacheType;
  
  /**
   * 创建时间 | Creation time
   */
  createdAt: number;
  
  /**
   * 最后访问时间 | Last access time
   */
  lastAccessedAt: number;
  
  /**
   * 过期时间 | Expiration time
   */
  expiresAt?: number;
  
  /**
   * 数据大小（字节） | Data size (bytes)
   */
  size: number;
  
  /**
   * 优先级 | Priority
   */
  priority: CachePriority;
  
  /**
   * 访问次数 | Access count
   */
  accessCount: number;
  
  /**
   * 缓存版本 | Cache version
   */
  version?: string;
  
  /**
   * 是否加密 | Whether encrypted
   */
  encrypted: boolean;
  
  /**
   * 标签 | Tags
   */
  tags?: string[];
}

/**
 * 缓存元数据接口 | Cache metadata interface
 */
export interface CacheMetadata {
  /**
   * 缓存键 | Cache key
   */
  key: string;
  
  /**
   * 缓存类型 | Cache type
   */
  type: CacheType;
  
  /**
   * 创建时间 | Creation time
   */
  createdAt: number;
  
  /**
   * 最后访问时间 | Last access time
   */
  lastAccessedAt: number;
  
  /**
   * 过期时间 | Expiration time
   */
  expiresAt?: number;
  
  /**
   * 数据大小（字节） | Data size (bytes)
   */
  size: number;
  
  /**
   * 优先级 | Priority
   */
  priority: CachePriority;
  
  /**
   * 访问次数 | Access count
   */
  accessCount: number;
  
  /**
   * 是否压缩 | Whether compressed
   */
  compressed: boolean;
  
  /**
   * 是否加密 | Whether encrypted
   */
  encrypted: boolean;
  
  /**
   * 缓存策略 | Cache strategy
   */
  strategy: CacheStrategy;
  
  /**
   * 来源 | Source
   */
  source?: string;
}

/**
 * 缓存配置接口 | Cache configuration interface
 */
export interface CacheConfig {
  /**
   * 缓存名称 | Cache name
   */
  name: string;
  
  /**
   * 缓存路径 | Cache path
   */
  path: string;
  
  /**
   * 最大存储大小（字节） | Maximum storage size (bytes)
   */
  maxSize: number;
  
  /**
   * 默认过期时间（秒） | Default expiration time (seconds)
   */
  defaultExpireTime: number;
  
  /**
   * 缓存策略 | Cache strategy
   */
  strategy: CacheStrategy;
  
  /**
   * 是否自动清理 | Whether auto cleanup
   */
  autoCleanup: boolean;
  
  /**
   * 清理间隔（秒） | Cleanup interval (seconds)
   */
  cleanupInterval: number;
  
  /**
   * 是否压缩数据 | Whether compress data
   */
  compressionEnabled: boolean;
  
  /**
   * 是否加密数据 | Whether encrypt data
   */
  encryptionEnabled: boolean;
  
  /**
   * 内存缓存最大条目数 | Maximum memory cache entries
   */
  maxMemoryEntries: number;
  
  /**
   * 是否使用LRU策略 | Whether use LRU strategy
   */
  useLru: boolean;
  
  /**
   * 存储模式 | Storage mode
   */
  storageMode: 'file' | 'database' | 'hybrid';
}

/**
 * 缓存统计接口 | Cache statistics interface
 */
export interface CacheStats {
  /**
   * 当前缓存大小（字节） | Current cache size (bytes)
   */
  currentSize: number;
  
  /**
   * 最大存储大小（字节） | Maximum storage size (bytes)
   */
  maxSize: number;
  
  /**
   * 缓存条目数 | Cache item count
   */
  itemCount: number;
  
  /**
   * 内存缓存大小 | Memory cache size
   */
  memoryCacheSize: number;
  
  /**
   * 磁盘缓存大小 | Disk cache size
   */
  diskCacheSize: number;
  
  /**
   * 命中率 | Hit rate
   */
  hitRate: number;
  
  /**
   * 未命中率 | Miss rate
   */
  missRate: number;
  
  /**
   * 过期条目数 | Expired item count
   */
  expiredCount: number;
  
  /**
   * 最后清理时间 | Last cleanup time
   */
  lastCleanupTime: number;
  
  /**
   * 按类型统计 | Statistics by type
   */
  byType: {
    [key in CacheType]: {
      count: number;
      size: number;
    }
  };
}

/**
 * 缓存清理选项接口 | Cache cleanup options interface
 */
export interface CacheCleanupOptions {
  /**
   * 清理类型 | Cleanup types
   */
  types?: CacheType[];
  
  /**
   * 清理过期项 | Cleanup expired items
   */
  expired?: boolean;
  
  /**
   * 清理最小优先级 | Minimum priority to cleanup
   */
  minPriority?: CachePriority;
  
  /**
   * 保留大小（字节） | Keep size (bytes)
   */
  keepSize?: number;
  
  /**
   * 保留时间（秒）内的缓存 | Keep cache within time (seconds)
   */
  keepTime?: number;
  
  /**
   * 排除的键 | Excluded keys
   */
  excludeKeys?: string[];
  
  /**
   * 排除的标签 | Excluded tags
   */
  excludeTags?: string[];
  
  /**
   * 是否执行模拟清理 | Whether to perform dry run
   */
  dryRun?: boolean;
  
  /**
   * 是否清理全部 | Whether to cleanup all
   */
  all?: boolean;
}

/**
 * 缓存清理结果接口 | Cache cleanup result interface
 */
export interface CacheCleanupResult {
  /**
   * 清理的条目数 | Removed item count
   */
  removedCount: number;
  
  /**
   * 释放的空间（字节） | Freed space (bytes)
   */
  freedSpace: number;
  
  /**
   * 清理时间（秒） | Cleanup time (seconds)
   */
  cleanupTime: number;
  
  /**
   * 是否为模拟运行 | Whether it's a dry run
   */
  isDryRun: boolean;
  
  /**
   * 按类型清理统计 | Cleanup statistics by type
   */
  byType: {
    [key in CacheType]?: {
      count: number;
      size: number;
    }
  };
}

/**
 * 缓存搜索参数接口 | Cache search parameters interface
 */
export interface CacheSearchParams {
  /**
   * 搜索键模式 | Search key pattern
   */
  keyPattern?: string;
  
  /**
   * 缓存类型 | Cache types
   */
  types?: CacheType[];
  
  /**
   * 最小优先级 | Minimum priority
   */
  minPriority?: CachePriority;
  
  /**
   * 创建时间范围（开始） | Creation time range (start)
   */
  createdAfter?: number;
  
  /**
   * 创建时间范围（结束） | Creation time range (end)
   */
  createdBefore?: number;
  
  /**
   * 是否包含过期项 | Whether to include expired items
   */
  includeExpired?: boolean;
  
  /**
   * 标签过滤 | Tag filtering
   */
  tags?: string[];
  
  /**
   * 排序字段 | Sort field
   */
  sortBy?: 'createdAt' | 'lastAccessedAt' | 'size' | 'accessCount' | 'priority';
  
  /**
   * 排序方向 | Sort order
   */
  sortOrder?: 'asc' | 'desc';
  
  /**
   * 分页大小 | Page size
   */
  limit?: number;
  
  /**
   * 分页偏移 | Page offset
   */
  offset?: number;
}

/**
 * 缓存搜索结果接口 | Cache search result interface
 */
export interface CacheSearchResult {
  /**
   * 缓存条目列表 | Cache item list
   */
  items: CacheMetadata[];
  
  /**
   * 总条目数 | Total item count
   */
  totalCount: number;
  
  /**
   * 是否还有更多 | Whether there are more
   */
  hasMore: boolean;
  
  /**
   * 搜索时间（秒） | Search time (seconds)
   */
  searchTime: number;
}

/**
 * 预加载缓存选项接口 | Preload cache options interface
 */
export interface PreloadCacheOptions {
  /**
   * 缓存键 | Cache keys
   */
  keys: string[];
  
  /**
   * 预加载类型 | Preload type
   */
  type: CacheType;
  
  /**
   * 优先级 | Priority
   */
  priority?: CachePriority;
  
  /**
   * 过期时间 | Expiration time
   */
  expireTime?: number;
  
  /**
   * 预加载回调 | Preload callback
   */
  onProgress?: (progress: number) => void;
}

/**
 * 缓存事件类型枚举 | Cache event type enum
 */
export enum CacheEventType {
  /**
   * 添加缓存 | Add cache
   */
  ADDED = 'added',
  
  /**
   * 获取缓存 | Get cache
   */
  GET = 'get',
  
  /**
   * 删除缓存 | Delete cache
   */
  DELETED = 'deleted',
  
  /**
   * 更新缓存 | Update cache
   */
  UPDATED = 'updated',
  
  /**
   * 清理缓存 | Clean cache
   */
  CLEANED = 'cleaned',
  
  /**
   * 过期 | Expired
   */
  EXPIRED = 'expired',
  
  /**
   * 大小变化 | Size changed
   */
  SIZE_CHANGED = 'size_changed',
  
  /**
   * 命中率变化 | Hit rate changed
   */
  HIT_RATE_CHANGED = 'hit_rate_changed'
}

/**
 * 缓存事件数据接口 | Cache event data interface
 */
export interface CacheEventData {
  /**
   * 清理统计（对应CLEANED事件） | Cleanup statistics (for CLEANED event)
   */
  cleanupStats?: {
    removedCount: number;
    freedSpace: number;
  };
  
  /**
   * 命中率数据（对应HIT_RATE_CHANGED事件） | Hit rate data (for HIT_RATE_CHANGED event)
   */
  hitRateData?: {
    hitRate: number;
    totalRequests: number;
    hits: number;
    misses: number;
  };
  
  /**
   * 大小变化数据（对应SIZE_CHANGED事件） | Size change data (for SIZE_CHANGED event)
   */
  sizeChangeData?: {
    previousSize: number;
    currentSize: number;
    changeAmount: number;
  };
  
  /**
   * 自定义数据 | Custom data
   */
  customData?: Record<string, string | number | boolean>;
}

/**
 * 缓存事件接口 | Cache event interface
 */
export interface CacheEvent {
  /**
   * 事件类型 | Event type
   */
  type: CacheEventType;
  
  /**
   * 缓存键 | Cache key
   */
  key?: string;
  
  /**
   * 缓存大小 | Cache size
   */
  size?: number;
  
  /**
   * 时间戳 | Timestamp
   */
  timestamp: number;
  
  /**
   * 事件数据 | Event data
   */
  data?: CacheEventData;
}

/**
 * 缓存压缩配置接口 | Cache compression configuration interface
 */
export interface CacheCompressionConfig {
  /**
   * 是否启用 | Whether enabled
   */
  enabled: boolean;
  
  /**
   * 压缩级别 | Compression level
   */
  level: number;
  
  /**
   * 压缩阈值（字节） | Compression threshold (bytes)
   */
  threshold: number;
  
  /**
   * 压缩算法 | Compression algorithm
   */
  algorithm: 'gzip' | 'deflate' | 'lz4' | 'zstd';
}

/**
 * 缓存加密配置接口 | Cache encryption configuration interface
 */
export interface CacheEncryptionConfig {
  /**
   * 是否启用 | Whether enabled
   */
  enabled: boolean;
  
  /**
   * 加密算法 | Encryption algorithm
   */
  algorithm: 'aes' | 'rsa' | '3des';
  
  /**
   * 密钥 | Encryption key
   */
  key?: string;
  
  /**
   * 密钥别名 | Key alias
   */
  keyAlias?: string;
  
  /**
   * 加密模式 | Encryption mode
   */
  mode?: 'cbc' | 'gcm' | 'ctr';
}

/**
 * 缓存版本控制接口 | Cache version control interface
 */
export interface CacheVersion {
  /**
   * 版本号 | Version number
   */
  version: string;
  
  /**
   * 上次更新时间 | Last updated time
   */
  lastUpdated: number;
  
  /**
   * 缓存条目数 | Cache item count
   */
  itemCount: number;
  
  /**
   * 缓存大小 | Total cache size
   */
  totalSize: number;
}

/**
 * 批量缓存操作结果接口 | Batch cache operation result interface
 */
export interface BatchCacheResult {
  /**
   * 成功的键 | Successful keys
   */
  successKeys: string[];
  
  /**
   * 失败的键 | Failed keys
   */
  failedKeys: string[];
  
  /**
   * 失败原因 | Failure reasons
   */
  failures: Record<string, string>;
  
  /**
   * 总操作时间 | Total operation time
   */
  operationTime: number;
  
  /**
   * 操作类型 | Operation type
   */
  operationType: 'get' | 'set' | 'delete' | 'update';
}
