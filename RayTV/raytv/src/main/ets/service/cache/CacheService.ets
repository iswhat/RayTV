// 缓存服务 Cache service
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import FileUtil from '../../common/util/FileUtil';
import JsonUtil from '../../common/util/JsonUtil';
import TypeSafetyHelper from '../../common/util/TypeSafetyHelper';
import ConfigService from '../config/ConfigService';
import FileService, { StorageLocation, FileType, FileConfig } from './FileService';

// 常量定义 Constants definition
const TAG = 'CacheService';
const CACHE_CONFIG_KEY = 'cache_config';
const MEMORY_CACHE_EXPIRY = 60000; // 1分钟 1 minute
const MAX_MEMORY_CACHE_SIZE = 100 * 1024 * 1024; // 100MB
const DEFAULT_DISK_CACHE_SIZE = 256 * 1024 * 1024; // 256MB
const DEFAULT_CACHE_EXPIRY = 24 * 60 * 60 * 1000; // 24小时 24 hours

// 缓存类型枚举 Cache type enum
export enum CacheType {
  MEMORY = 'memory',
  DISK = 'disk',
  MEMORY_DISK = 'memory_disk'
}

// 缓存存储位置枚举 Cache storage location enum
export enum CacheStorageLocation {
  INTERNAL = 'internal',
  EXTERNAL = 'external',
  TEMP = 'temp'
}

// 缓存策略枚举 Cache strategy enum
export enum CacheStrategy {
  LRU = 'lru', // 最近最少使用 Least recently used
  LFU = 'lfu', // 最少使用频率 Least frequently used
  FIFO = 'fifo', // 先进先出 First in first out
  FILO = 'filo' // 后进先出 First in last out
}

// 缓存优先级枚举 Cache priority enum
export enum CachePriority {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
  CRITICAL = 'critical'
}

// 缓存配置接口 Cache config interface
export interface CacheConfig {
  enableMemoryCache: boolean;
  enableDiskCache: boolean;
  memoryCacheSize: number; // 字节 Bytes
  diskCacheSize: number; // 字节 Bytes
  defaultExpiry: number; // 毫秒 Milliseconds
  cacheStrategy: CacheStrategy;
  storageLocation: CacheStorageLocation;
  maxCacheItems: number;
  enableAutoCleanup: boolean;
  cleanupInterval: number; // 毫秒 Milliseconds
  cleanupThreshold: number; // 百分比(0-100) Percentage (0-100)
  cacheKeyPrefix: string;
  cacheVersion: string;
  compressCacheItems: boolean;
  encryptCacheItems: boolean;
  enableStatistics: boolean;
  logLevel: 'debug' | 'info' | 'warn' | 'error' | 'none';
  allowedCacheTypes: CacheType[];
  maxItemSize: number; // 单个缓存项最大大小（字节） Maximum size per cache item (bytes)
}

// 缓存项元数据接口 Cache metadata interface
export interface CacheMetadata {
  key: string;
  type: string; // 数据类型 Data type
  size: number; // 字节 Bytes
  createdAt: number;
  modifiedAt: number;
  accessedAt: number;
  expiry: number; // 毫秒 Milliseconds
  priority: CachePriority;
  hits: number;
  tags: string[];
  version?: string;
  checksum?: string;
  compressed: boolean;
  encrypted: boolean;
  source?: string; // 缓存来源 Cache source
}

// 缓存项接口 Cache item interface
export interface CacheItem<T = unknown> {
  data: T;
  metadata: CacheMetadata;
}

// 缓存统计接口 Cache statistics interface
export interface CacheStatistics {
  memoryCacheSize: number;
  memoryCacheItems: number;
  diskCacheSize: number;
  diskCacheItems: number;
  hitCount: number;
  missCount: number;
  evictionCount: number;
  expirationCount: number;
  errorCount: number;
  lastCleanupTime: number;
  totalCleanupTime: number;
  cacheRatio: number; // 缓存命中率 Cache hit ratio
  averageGetTime: number; // 平均获取时间（毫秒） Average get time (ms)
  averageSetTime: number; // 平均设置时间（毫秒） Average set time (ms)
  largestItemSize: number;
  smallestItemSize: number;
  averageItemSize: number;
}

// 缓存搜索参数接口 Cache search params interface
export interface CacheSearchParams {
  tags?: string[];
  minAge?: number;
  maxAge?: number;
  minSize?: number;
  maxSize?: number;
  priority?: CachePriority[];
  type?: string[];
  keyPattern?: string;
  expired?: boolean;
  limit?: number;
  offset?: number;
}

// 缓存操作结果接口 Cache operation result interface
export interface CacheOperationResult {
  success: boolean;
  key?: string;
  error?: string;
  details?: Record<string, unknown>;
}

// 缓存清理选项接口 Cache cleanup options interface
export interface CacheCleanupOptions {
  force?: boolean;
  tags?: string[];
  olderThan?: number; // 毫秒 Milliseconds
  priority?: CachePriority;
  sizeLimit?: number; // 字节 Bytes
  itemLimit?: number;
  expiredOnly?: boolean;
  excludeKeys?: string[];
  includeKeys?: string[];
}

// 默认缓存配置 Default cache config
const DEFAULT_CACHE_CONFIG: CacheConfig = {
  enableMemoryCache: true,
  enableDiskCache: true,
  memoryCacheSize: MAX_MEMORY_CACHE_SIZE,
  diskCacheSize: DEFAULT_DISK_CACHE_SIZE,
  defaultExpiry: DEFAULT_CACHE_EXPIRY,
  cacheStrategy: CacheStrategy.LRU,
  storageLocation: CacheStorageLocation.INTERNAL,
  maxCacheItems: 1000,
  enableAutoCleanup: true,
  cleanupInterval: 3600000, // 1小时 1 hour
  cleanupThreshold: 80, // 80%
  cacheKeyPrefix: 'cache_',
  cacheVersion: '1.0',
  compressCacheItems: false,
  encryptCacheItems: false,
  enableStatistics: true,
  logLevel: 'info',
  allowedCacheTypes: [CacheType.MEMORY, CacheType.DISK, CacheType.MEMORY_DISK],
  maxItemSize: 10 * 1024 * 1024 // 10MB
};

/**
 * 缓存服务 | Cache service
 * 负责管理应用程序的缓存系统，提供缓存的配置、获取、删除等功能 | Responsible for managing application cache system, providing cache configuration, retrieval, deletion and other functions
 */
export default class CacheService {
  private static instance: CacheService;
  
  private cacheConfig: CacheConfig = { ...DEFAULT_CACHE_CONFIG };
  private memoryCache: Map<string, { data: Record<string, string | number | boolean | null>; expiry: number; timestamp: number }> = new Map();
  private cacheIndex: Map<string, CacheMetadata> = new Map();
  private cacheDir: string = '';
  private indexFile: string = '';
  
  // 统计信息 | Statistics
  private statistics: CacheStatistics = {
    memoryCacheSize: 0,
    memoryCacheItems: 0,
    diskCacheSize: 0,
    diskCacheItems: 0,
    hitCount: 0,
    missCount: 0,
    evictionCount: 0,
    expirationCount: 0,
    errorCount: 0,
    lastCleanupTime: 0,
    totalCleanupTime: 0,
    cacheRatio: 0,
    averageGetTime: 0,
    averageSetTime: 0,
    largestItemSize: 0,
    smallestItemSize: Number.MAX_SAFE_INTEGER,
    averageItemSize: 0
  };
  
  // 操作时间记录 | Operation time records
  private getTimes: number[] = [];
  private setTimes: number[] = [];
  
  // 监听器 | Listeners
  private cleanupListeners: Array<(deletedCount: number, freedSpace: number) => void> = [];
  private evictionListeners: Array<(key: string, metadata: CacheMetadata) => void> = [];
  private errorListeners: Array<(error: Error, operation: string, key?: string) => void> = [];
  
  private cleanupTimer?: number;
  private isInitialized: boolean = false;

  /**
   * 构造函数（私有，防止外部实例化） | Constructor (private, prevent external instantiation)
   */
  private constructor() {
    this.initialize();
  }

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): CacheService {
    if (!CacheService.instance) {
      CacheService.instance = new CacheService();
    }
    return CacheService.instance;
  }
  
  /**
   * 获取对象的所有键 | Get all keys of object
   * 替代Object.keys，适配ArkTS语法 | Alternative to Object.keys, adapted for ArkTS syntax
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    const keys: string[] = [];
    for (const key in obj) {
      if (Object.keys(obj).includes(key)) {
        keys.push(key);
      }
    }
    return keys;
  }

  /**
   * 初始化缓存服务 | Initialize cache service
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing cache service...');
      
      // 加载缓存配置 | Load cache config
      const savedConfig = await StorageUtil.getObject<CacheConfig>(CACHE_CONFIG_KEY);
      if (savedConfig) {
        this.cacheConfig = { ...DEFAULT_CACHE_CONFIG, ...savedConfig };
      }
      
      // 设置缓存目录 | Set cache directory
      await this.setCacheDirectory();
      
      // 加载缓存索引 | Load cache index
      await this.loadCacheIndex();
      
      // 更新统计信息 | Update statistics
      await this.updateStatistics();
      
      // 启动自动清理 | Start auto cleanup
      if (this.cacheConfig.enableAutoCleanup) {
        this.startAutoCleanup();
      }
      
      // 执行初始清理 | Perform initial cleanup
      await this.performInitialCleanup();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Cache service initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize cache service', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'initialize');
    }
  }

  /**
   * 设置缓存目录 | Set cache directory
   */
  private async setCacheDirectory(): Promise<void> {
    try {
      const fileService = FileService.getInstance();
      const fileConfig = fileService.getFileConfig();
      
      switch (this.cacheConfig.storageLocation) {
        case CacheStorageLocation.INTERNAL:
          this.cacheDir = `${fileConfig.cacheDir}/cache`;
          break;
        case CacheStorageLocation.EXTERNAL:
          this.cacheDir = `${fileConfig.cacheDir}/external_cache`;
          break;
        case CacheStorageLocation.TEMP:
          this.cacheDir = `${fileConfig.tempDir}/temp_cache`;
          break;
      }
      
      // 创建缓存目录 | Create cache directory
      await FileUtil.ensureDirectory(this.cacheDir);
      
      // 设置索引文件路径 | Set index file path
      this.indexFile = `${this.cacheDir}/cache_index.json`;
      
      Logger.debug(TAG, `Cache directory set to: ${this.cacheDir}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to set cache directory', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  /**
   * 加载缓存索引 | Load cache index
   */
  private async loadCacheIndex(): Promise<void> {
    try {
      // 检查索引文件是否存在 | Check if index file exists
      const indexExists = await FileUtil.fileExists(this.indexFile);
      if (!indexExists) {
        return;
      }
      
      // 读取索引文件 | Read index file
      const indexContent = await FileUtil.readFile(this.indexFile, 'utf-8');
      if (!indexContent) {
        return;
      }
      
      // 解析索引 | Parse index
      const indexData = JsonUtil.parse<Map<string, CacheMetadata>>(indexContent);
      if (!indexData || typeof indexData !== 'object') {
        return;
      }
      
      // 更新缓存索引 | Update cache index
      for (const [key, metadata] of Object.entries(indexData)) {
        this.cacheIndex.set(key, metadata as CacheMetadata);
      }
      
      Logger.debug(TAG, `Loaded cache index with ${this.cacheIndex.size} entries`);
    } catch (error) {
      Logger.error(TAG, 'Failed to load cache index', error instanceof Error ? error : new Error(String(error)));
      // 索引文件损坏，重新创建 | Index file corrupted, recreate
      await FileUtil.writeFile(this.indexFile, '{}', { create: true });
    }
  }

  /**
   * 保存缓存索引 | Save cache index
   */
  private async saveCacheIndex(): Promise<void> {
    try {
      const indexData: Record<string, CacheMetadata> = {};
      
      // 过滤过期的缓存项 | Filter out expired cache items
      const now = Date.now();
      for (const [key, metadata] of this.cacheIndex.entries()) {
        if (metadata.expiry === 0 || now < metadata.expiry) {
          indexData[key] = metadata;
        }
      }
      
      // 写入索引文件 | Write to index file
      const indexContent = JsonUtil.stringify(indexData);
      await FileUtil.writeFile(this.indexFile, indexContent, { create: true });
      
      Logger.debug(TAG, `Saved cache index with ${this.getObjectKeys(indexData).length} entries`);
    } catch (error) {
      Logger.error(TAG, 'Failed to save cache index', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'saveCacheIndex');
    }
  }

  /**
   * 更新统计信息 | Update statistics
   */
  private async updateStatistics(): Promise<void> {
    try {
      // 重置统计 | Reset statistics
      this.statistics.memoryCacheSize = 0;
      this.statistics.memoryCacheItems = 0;
      this.statistics.diskCacheSize = 0;
      this.statistics.diskCacheItems = 0;
      
      // 计算内存缓存统计 | Calculate memory cache statistics
      if (this.cacheConfig.enableMemoryCache) {
        let totalSize: number = 0;
        let itemCount: number = 0;
        let largest: number = 0;
        let smallest: number = Number.MAX_SAFE_INTEGER;
        
        for (const [key, item] of this.memoryCache.entries()) {
          const itemSize = this.calculateObjectSize(item.data);
          totalSize += itemSize;
          itemCount++;
          largest = Math.max(largest, itemSize);
          smallest = Math.min(smallest, itemSize);
        }
        
        this.statistics.memoryCacheSize = totalSize;
        this.statistics.memoryCacheItems = itemCount;
        
        if (itemCount > 0) {
          this.statistics.largestItemSize = largest;
          this.statistics.smallestItemSize = smallest;
          this.statistics.averageItemSize = totalSize / itemCount;
        }
      }
      
      // 计算磁盘缓存统计 | Calculate disk cache statistics
      if (this.cacheConfig.enableDiskCache) {
        let totalSize: number = 0;
        let itemCount: number = 0;
        
        for (const [key, metadata] of this.cacheIndex.entries()) {
          totalSize += metadata.size;
          itemCount++;
        }
        
        this.statistics.diskCacheSize = totalSize;
        this.statistics.diskCacheItems = itemCount;
      }
      
      // 计算缓存命中率 | Calculate cache hit ratio
      const total = this.statistics.hitCount + this.statistics.missCount;
      if (total > 0) {
        this.statistics.cacheRatio = this.statistics.hitCount / total;
      }
      
      // 计算平均操作时间 | Calculate average operation time
      if (this.getTimes.length > 0) {
        const sum = this.getTimes.reduce((a, b) => a + b, 0);
        this.statistics.averageGetTime = sum / this.getTimes.length;
      }
      
      if (this.setTimes.length > 0) {
        const sum = this.setTimes.reduce((a, b) => a + b, 0);
        this.statistics.averageSetTime = sum / this.setTimes.length;
      }
      
      Logger.debug(TAG, 'Updated cache statistics');
    } catch (error) {
      Logger.error(TAG, 'Failed to update statistics', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'updateStatistics');
    }
  }

  /**
   * 计算对象大小（估算） | Calculate object size (estimate)
   */
  private calculateObjectSize(obj: Record<string, string | number | boolean | null>): number {
    try {
      // 简单估算，实际应用中可以使用更准确的方法 | Simple estimate, more accurate methods can be used in actual applications
      const str = typeof obj === 'string' ? obj : JsonUtil.stringify(obj);
      return new Blob([str]).size;
    } catch (error) {
      Logger.error(TAG, 'Failed to calculate object size', error instanceof Error ? error : new Error(String(error)));
      return 0;
    }
  }

  /**
   * 记录错误 | Record error
   */
  private recordError(error: Error, operation: string, key?: string): void {
    this.statistics.errorCount++;
    
    // 通知错误监听器 | Notify error listeners
    for (const listener of this.errorListeners) {
      try {
        listener(error, operation, key);
      } catch (listenerError) {
        Logger.error(TAG, 'Error in error listener', listenerError instanceof Error ? listenerError : new Error(String(listenerError)));
      }
    }
  }

  /**
   * 设置缓存配置 | Set cache config
   */
  public async setCacheConfig(config: Partial<CacheConfig>): Promise<CacheConfig> {
    try {
      // 更新配置 | Update config
      this.cacheConfig = {
        ...this.cacheConfig,
        ...config
      };
      
      // 保存配置 | Save config
      await StorageUtil.setObject(CACHE_CONFIG_KEY, this.cacheConfig);
      
      // 如果存储位置变更，重新设置缓存目录 | If storage location changed, reset cache directory
      if (config.storageLocation !== undefined) {
        await this.setCacheDirectory();
      }
      
      // 重启自动清理 | Restart auto cleanup
      if (config.enableAutoCleanup !== undefined || config.cleanupInterval !== undefined) {
        this.stopAutoCleanup();
        if (this.cacheConfig.enableAutoCleanup) {
          this.startAutoCleanup();
        }
      }
      
      // 如果内存缓存大小变更，清理内存缓存 | If memory cache size changed, evict memory cache
      if (config.memoryCacheSize !== undefined && this.cacheConfig.enableMemoryCache) {
        await this.evictMemoryCacheBySize();
      }
      
      // 更新统计信息 | Update statistics
      await this.updateStatistics();
      
      Logger.info(TAG, 'Updated cache config');
      return { ...this.cacheConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to update cache config', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'setCacheConfig');
      return { ...this.cacheConfig };
    }
  }

  /**
   * 获取缓存配置 | Get cache config
   */
  public getCacheConfig(): CacheConfig {
    return { ...this.cacheConfig };
  }

  /**
   * 重置缓存配置为默认值 | Reset cache config to default
   */
  public async resetCacheConfig(): Promise<CacheConfig> {
    try {
      this.cacheConfig = { ...DEFAULT_CACHE_CONFIG };
      
      // 保存配置 | Save config
      await StorageUtil.setObject(CACHE_CONFIG_KEY, this.cacheConfig);
      
      // 重新设置缓存目录 | Reset cache directory
      await this.setCacheDirectory();
      
      // 重启自动清理 | Restart auto cleanup
      this.stopAutoCleanup();
      if (this.cacheConfig.enableAutoCleanup) {
        this.startAutoCleanup();
      }
      
      // 更新统计信息 | Update statistics
      await this.updateStatistics();
      
      Logger.info(TAG, 'Reset cache config to default');
      return { ...this.cacheConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to reset cache config', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'resetCacheConfig');
      return { ...this.cacheConfig };
    }
  }

  /**
   * 开始自动清理 | Start auto cleanup
   */
  private startAutoCleanup(): void {
    try {
      this.stopAutoCleanup();
      
      this.cleanupTimer = setInterval(() => {
        this.performAutoCleanup();
      }, this.cacheConfig.cleanupInterval);
      
      Logger.debug(TAG, `Started auto cleanup, interval: ${this.cacheConfig.cleanupInterval}ms`);
    } catch (error) {
      Logger.error(TAG, 'Failed to start auto cleanup', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'startAutoCleanup');
    }
  }

  /**
   * 停止自动清理 | Stop auto cleanup
   */
  private stopAutoCleanup(): void {
    try {
      if (this.cleanupTimer) {
        clearInterval(this.cleanupTimer);
        this.cleanupTimer = undefined;
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to stop auto cleanup', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'stopAutoCleanup');
    }
  }

  /**
   * 执行初始清理 | Perform initial cleanup
   */
  private async performInitialCleanup(): Promise<void> {
    try {
      // 清理过期的缓存项 | Cleanup expired items
      await this.cleanupExpiredItems();
      
      // 检查缓存大小是否超过阈值 | Check if cache size exceeds threshold
      const cachePercentage = (this.statistics.diskCacheSize / this.cacheConfig.diskCacheSize) * 100;
      if (cachePercentage > this.cacheConfig.cleanupThreshold) {
        await this.cleanupCacheBySize();
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to perform initial cleanup', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'performInitialCleanup');
    }
  }

  /**
   * 执行自动清理 | Perform auto cleanup
   */
  private async performAutoCleanup(): Promise<void> {
    try {
      Logger.info(TAG, 'Performing auto cleanup...');
      const startTime = Date.now();
      
      let deletedCount = 0;
      let freedSpace = 0;
      
      // 清理过期的缓存项 | Cleanup expired items
      const expiredCleanup = await this.cleanupExpiredItems();
      deletedCount += expiredCleanup.deletedCount;
      freedSpace += expiredCleanup.freedSpace;
      
      // 检查缓存大小是否超过阈值 | Check if cache size exceeds threshold
      const cachePercentage = (this.statistics.diskCacheSize / this.cacheConfig.diskCacheSize) * 100;
      if (cachePercentage > this.cacheConfig.cleanupThreshold) {
        const sizeCleanup = await this.cleanupCacheBySize();
        deletedCount += sizeCleanup.deletedCount;
        freedSpace += sizeCleanup.freedSpace;
      }
      
      // 检查缓存项数量是否超过限制 | Check if cache item count exceeds limit
      if (this.statistics.diskCacheItems > this.cacheConfig.maxCacheItems) {
        const countCleanup = await this.cleanupCacheByCount();
        deletedCount += countCleanup.deletedCount;
        freedSpace += countCleanup.freedSpace;
      }
      
      // 清理内存缓存 | Cleanup memory cache
      if (this.cacheConfig.enableMemoryCache) {
        await this.evictMemoryCacheByTime();
        await this.evictMemoryCacheBySize();
      }
      
      // 更新统计信息 | Update statistics
      await this.updateStatistics();
      
      // 记录清理时间 | Record cleanup time
      const duration = Date.now() - startTime;
      this.statistics.lastCleanupTime = startTime;
      this.statistics.totalCleanupTime += duration;
      
      // 通知清理完成 | Notify cleanup completed
      if (deletedCount > 0) {
        this.notifyCleanupCompleted(deletedCount, freedSpace);
      }
      
      Logger.info(TAG, `Auto cleanup completed: ${deletedCount} items deleted, ${this.formatSize(freedSpace)} freed, took ${duration}ms`);
    } catch (error) {
      Logger.error(TAG, 'Failed to perform auto cleanup', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'performAutoCleanup');
    }
  }

  /**
   * 清理过期的缓存项 | Cleanup expired items
   */
  private async cleanupExpiredItems(): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      const now = Date.now();
      const expiredKeys: string[] = [];
      let deletedCount = 0;
      let freedSpace = 0;
      
      // 找出过期的缓存项 | Find expired cache items
      for (const [key, metadata] of this.cacheIndex.entries()) {
        if (metadata.expiry > 0 && now > metadata.expiry) {
          expiredKeys.push(key);
          freedSpace += metadata.size;
        }
      }
      
      // 删除过期的缓存项 | Delete expired cache items
      for (const key of expiredKeys) {
        await this.removeItemFromDisk(key);
        deletedCount++;
      }
      
      // 更新统计信息 | Update statistics
      this.statistics.expirationCount += deletedCount;
      
      // 保存索引 | Save index
      await this.saveCacheIndex();
      
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, 'Failed to cleanup expired items', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'cleanupExpiredItems');
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 按大小清理缓存 | Cleanup cache by size
   */
  private async cleanupCacheBySize(): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      // 计算需要释放的空间 | Calculate space to free
      const targetSize = this.cacheConfig.diskCacheSize * (this.cacheConfig.cleanupThreshold / 100);
      const spaceToFree = this.statistics.diskCacheSize - targetSize;
      
      if (spaceToFree <= 0) {
        return { deletedCount: 0, freedSpace: 0 };
      }
      
      // 获取所有缓存项并根据策略排序 | Get all cache items and sort by strategy
      const cacheItems = Array.from(this.cacheIndex.entries());
      let sortedItems: [string, CacheMetadata][];
      
      switch (this.cacheConfig.cacheStrategy) {
        case CacheStrategy.LRU:
          // 按最近访问时间排序（最早的先删除） | Sort by last access time (earliest first)
          sortedItems = cacheItems.sort((a, b) => a[1].accessedAt - b[1].accessedAt);
          break;
        case CacheStrategy.LFU:
          // 按使用频率排序（最少使用的先删除） | Sort by usage frequency (least used first)
          sortedItems = cacheItems.sort((a, b) => a[1].hits - b[1].hits);
          break;
        case CacheStrategy.FIFO:
          // 按创建时间排序（最早的先删除） | Sort by creation time (earliest first)
          sortedItems = cacheItems.sort((a, b) => a[1].createdAt - b[1].createdAt);
          break;
        case CacheStrategy.FILO:
          // 按创建时间排序（最晚的先删除） | Sort by creation time (latest first)
          sortedItems = cacheItems.sort((a, b) => b[1].createdAt - a[1].createdAt);
          break;
        default:
          sortedItems = cacheItems.sort((a, b) => a[1].accessedAt - b[1].accessedAt);
      }
      
      // 按优先级排序 | Sort by priority
      sortedItems.sort((a, b) => {
        const priorityValue = (p: CachePriority) => {
          switch (p) {
            case CachePriority.CRITICAL:
              return 4;
            case CachePriority.HIGH:
              return 3;
            case CachePriority.NORMAL:
              return 2;
            case CachePriority.LOW:
              return 1;
            default:
              return 0;
          }
        };
        return priorityValue(a[1].priority) - priorityValue(b[1].priority);
      });
      
      let deletedCount = 0;
      let freedSpace = 0;
      
      // 删除缓存项直到释放足够的空间 | Delete cache items until enough space is freed
      for (const [key, metadata] of sortedItems) {
        await this.removeItemFromDisk(key);
        deletedCount++;
        freedSpace += metadata.size;
        
        if (freedSpace >= spaceToFree) {
          break;
        }
      }
      
      // 更新统计信息 | Update statistics
      this.statistics.evictionCount += deletedCount;
      
      // 保存索引 | Save index
      await this.saveCacheIndex();
      
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, 'Failed to cleanup cache by size', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'cleanupCacheBySize');
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 按数量清理缓存 | Cleanup cache by count
   */
  private async cleanupCacheByCount(): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      // 计算需要删除的项目数 | Calculate number of items to delete
      const itemsToDelete = this.statistics.diskCacheItems - this.cacheConfig.maxCacheItems;
      
      if (itemsToDelete <= 0) {
        return { deletedCount: 0, freedSpace: 0 };
      }
      
      // 获取所有缓存项并根据策略排序 | Get all cache items and sort by strategy
      const cacheItems = Array.from(this.cacheIndex.entries());
      let sortedItems: [string, CacheMetadata][];
      
      switch (this.cacheConfig.cacheStrategy) {
        case CacheStrategy.LRU:
          sortedItems = cacheItems.sort((a, b) => a[1].accessedAt - b[1].accessedAt);
          break;
        case CacheStrategy.LFU:
          sortedItems = cacheItems.sort((a, b) => a[1].hits - b[1].hits);
          break;
        case CacheStrategy.FIFO:
          sortedItems = cacheItems.sort((a, b) => a[1].createdAt - b[1].createdAt);
          break;
        case CacheStrategy.FILO:
          sortedItems = cacheItems.sort((a, b) => b[1].createdAt - a[1].createdAt);
          break;
        default:
          sortedItems = cacheItems.sort((a, b) => a[1].accessedAt - b[1].accessedAt);
      }
      
      // 按优先级排序 | Sort by priority
      sortedItems.sort((a, b) => {
        const priorityValue = (p: CachePriority) => {
          switch (p) {
            case CachePriority.CRITICAL:
              return 4;
            case CachePriority.HIGH:
              return 3;
            case CachePriority.NORMAL:
              return 2;
            case CachePriority.LOW:
              return 1;
            default:
              return 0;
          }
        };
        return priorityValue(a[1].priority) - priorityValue(b[1].priority);
      });
      
      let deletedCount = 0;
      let freedSpace = 0;
      
      // 删除缓存项 | Delete cache items
      for (const [key, metadata] of sortedItems.slice(0, itemsToDelete)) {
        await this.removeItemFromDisk(key);
        deletedCount++;
        freedSpace += metadata.size;
      }
      
      // 更新统计信息 | Update statistics
      this.statistics.evictionCount += deletedCount;
      
      // 保存索引 | Save index
      await this.saveCacheIndex();
      
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, 'Failed to cleanup cache by count', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'cleanupCacheByCount');
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 根据时间清理内存缓存 | Evict memory cache by time
   */
  private async evictMemoryCacheByTime(): Promise<void> {
    try {
      const now = Date.now();
      const keysToDelete: string[] = [];
      
      for (const [key, item] of this.memoryCache.entries()) {
        if (item.expiry > 0 && now > item.expiry) {
          keysToDelete.push(key);
        }
      }
      
      for (const key of keysToDelete) {
        this.memoryCache.delete(key);
      }
      
      if (keysToDelete.length > 0) {
        Logger.debug(TAG, `Evicted ${keysToDelete.length} items from memory cache due to expiration`);
        await this.updateStatistics();
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to evict memory cache by time', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'evictMemoryCacheByTime');
    }
  }

  /**
   * 根据大小清理内存缓存 | Evict memory cache by size
   */
  private async evictMemoryCacheBySize(): Promise<void> {
    try {
      // 计算当前内存缓存大小 | Calculate current memory cache size
      let currentSize = 0;
      const cacheItems: Array<[string, { data: Record<string, string | number | boolean | null>; expiry: number; timestamp: number }, number]> = [];
      
      for (const [key, item] of this.memoryCache.entries()) {
        const itemSize = this.calculateObjectSize(item.data);
        currentSize += itemSize;
        cacheItems.push([key, item, itemSize]);
      }
      
      // 如果大小在限制范围内，不需要清理 | If size is within limit, no need to evict
      if (currentSize <= this.cacheConfig.memoryCacheSize) {
        return;
      }
      
      // 按时间戳排序（最早的先删除） | Sort by timestamp (earliest first)
      cacheItems.sort((a, b) => a[1].timestamp - b[1].timestamp);
      
      // 清理项目直到大小在限制范围内 | Evict items until size is within limit
      let evictedCount = 0;
      
      for (const [key, item, size] of cacheItems) {
        if (currentSize <= this.cacheConfig.memoryCacheSize) {
          break;
        }
        
        this.memoryCache.delete(key);
        currentSize -= size;
        evictedCount++;
      }
      
      if (evictedCount > 0) {
        Logger.debug(TAG, `Evicted ${evictedCount} items from memory cache due to size limit`);
        await this.updateStatistics();
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to evict memory cache by size', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'evictMemoryCacheBySize');
    }
  }

  /**
   * 从磁盘删除缓存项 | Remove cache item from disk
   */
  private async removeItemFromDisk(key: string): Promise<void> {
    try {
      const metadata = this.cacheIndex.get(key);
      if (!metadata) {
        return;
      }
      
      // 删除缓存文件 | Delete cache file
      const filePath = this.getCacheFilePath(key);
      if (await FileUtil.fileExists(filePath)) {
        await FileUtil.deleteFile(filePath);
      }
      
      // 从索引中删除 | Remove from index
      this.cacheIndex.delete(key);
      
      // 通知清理监听器 | Notify cleanup listeners
      this.notifyEviction(key, metadata);
      
      Logger.debug(TAG, `Removed cache item from disk: ${key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to remove cache item from disk: ${key}`, error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'removeItemFromDisk', key);
    }
  }

  /**
   * 获取缓存文件路径 | Get cache file path
   */
  private getCacheFilePath(key: string): string {
    const encodedKey = encodeURIComponent(key);
    return `${this.cacheDir}/${encodedKey}.cache`;
  }

  /**
   * 设置缓存项 | Set cache item
   */
  public async set<T>(
    key: string,
    data: T,
    options?: {
      expiry?: number;
      priority?: CachePriority;
      tags?: string[];
      type?: CacheType;
      source?: string;
    }
  ): Promise<CacheOperationResult> {
    const startTime = Date.now();
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      // 验证缓存类型 Validate cache type
      const cacheType = options?.type || CacheType.MEMORY_DISK;
      if (!this.cacheConfig.allowedCacheTypes.includes(cacheType)) {
        throw new Error(`Cache type ${cacheType} not allowed`);
      }
      
      // 验证数据大小 Validate data size
      const dataSize = this.calculateObjectSize(data);
      if (dataSize > this.cacheConfig.maxItemSize) {
        throw new Error(`Data size ${this.formatSize(dataSize)} exceeds maximum allowed size ${this.formatSize(this.cacheConfig.maxItemSize)}`);
      }
      
      // 创建元数据 Create metadata
      const metadata: CacheMetadata = {
        key: fullKey,
        type: typeof data,
        size: dataSize,
        createdAt: Date.now(),
        modifiedAt: Date.now(),
        accessedAt: Date.now(),
        expiry: options?.expiry || this.cacheConfig.defaultExpiry,
        priority: options?.priority || CachePriority.NORMAL,
        hits: 0,
        tags: options?.tags || [],
        version: this.cacheConfig.cacheVersion,
        compressed: this.cacheConfig.compressCacheItems,
        encrypted: this.cacheConfig.encryptCacheItems,
        source: options?.source
      };
      
      // 保存到内存缓存 Save to memory cache
      if (this.cacheConfig.enableMemoryCache && 
          (cacheType === CacheType.MEMORY || cacheType === CacheType.MEMORY_DISK)) {
        this.memoryCache.set(fullKey, {
          data: TypeSafetyHelper.asObject(data) || {},
          expiry: metadata.expiry,
          timestamp: Date.now()
        });
        
        // 检查内存缓存大小限制 Check memory cache size limit
        await this.evictMemoryCacheBySize();
      }
      
      // 保存到磁盘缓存 Save to disk cache
      if (this.cacheConfig.enableDiskCache && 
          (cacheType === CacheType.DISK || cacheType === CacheType.MEMORY_DISK)) {
        // 序列化数据 Serialize data
        let serializedData: string | ArrayBuffer;
        
        try {
          serializedData = typeof data === 'string' ? data : JsonUtil.stringify(data);
        } catch (error) {
          throw new Error('Failed to serialize data for caching');
        }
        
        // 如果需要压缩或加密，在这里处理 If compression or encryption is needed, handle here
        // ...
        
        // 写入文件 Write to file
        const filePath = this.getCacheFilePath(fullKey);
        await FileUtil.writeFile(filePath, serializedData, { create: true });
        
        // 更新索引 Update index
        this.cacheIndex.set(fullKey, metadata);
        await this.saveCacheIndex();
        
        // 检查磁盘缓存大小限制 Check disk cache size limit
        await this.updateStatistics();
        const cachePercentage = (this.statistics.diskCacheSize / this.cacheConfig.diskCacheSize) * 100;
        if (cachePercentage > this.cacheConfig.cleanupThreshold) {
          await this.cleanupCacheBySize();
        }
      }
      
      // 更新统计信息 Update statistics
      await this.updateStatistics();
      
      // 记录操作时间 Record operation time
      const duration = Date.now() - startTime;
      this.setTimes.push(duration);
      if (this.setTimes.length > 1000) {
        this.setTimes.shift();
      }
      
      Logger.debug(TAG, `Set cache item: ${key}, size: ${this.formatSize(dataSize)}, expiry: ${metadata.expiry > 0 ? new Date(metadata.expiry).toISOString() : 'never'}`);
      return {
        success: true,
        key: fullKey,
        details: {
          size: dataSize,
          expiry: metadata.expiry,
          type: cacheType
        }
      };
    } catch (error) {
      Logger.error(TAG, `Failed to set cache item: ${key}`, error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'set', key);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 获取缓存项 | Get cache item
   */
  public async get<T>(key: string): Promise<T | null> {
    const startTime = Date.now();
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      let data: T | null = null;
      
      // 首先尝试从内存缓存获取 First try to get from memory cache
      if (this.cacheConfig.enableMemoryCache) {
        const cachedItem = this.memoryCache.get(fullKey);
        if (cachedItem) {
          // 检查是否过期 Check if expired
          if (cachedItem.expiry === 0 || Date.now() < cachedItem.expiry) {
            data = cachedItem.data;
            
            // 更新访问时间 Update access time
            cachedItem.timestamp = Date.now();
            
            // 更新索引中的访问信息（如果存在）Update access info in index (if exists)
            const metadata = this.cacheIndex.get(fullKey);
            if (metadata) {
              metadata.accessedAt = Date.now();
              metadata.hits++;
              this.cacheIndex.set(fullKey, metadata);
              await this.saveCacheIndex();
            }
            
            this.statistics.hitCount++;
            Logger.debug(TAG, `Cache hit (memory): ${key}`);
          } else {
            // 过期，删除 Expired, delete
            this.memoryCache.delete(fullKey);
            Logger.debug(TAG, `Cache expired (memory): ${key}`);
          }
        }
      }
      
      // 如果内存缓存未命中，尝试从磁盘获取 If memory cache miss, try from disk
      if (data === null && this.cacheConfig.enableDiskCache) {
        const metadata = this.cacheIndex.get(fullKey);
        if (metadata) {
          // 检查是否过期 Check if expired
          if (metadata.expiry === 0 || Date.now() < metadata.expiry) {
            const filePath = this.getCacheFilePath(fullKey);
            
            // 读取文件 Read file
            const fileContent = await FileUtil.readFile(filePath, 'utf-8');
            if (fileContent) {
              // 如果需要解密或解压缩，在这里处理 If decryption or decompression is needed, handle here
              // ...
              
              // 反序列化数据 Deserialize data
              try {
                data = typeof fileContent === 'string' && 
                      (fileContent.startsWith('{') || fileContent.startsWith('[')) 
                  ? JsonUtil.parse<T>(fileContent)
                  : TypeSafetyHelper.asObject<T>(fileContent) as T;
              } catch (parseError) {
                throw new Error('Failed to parse cached data');
              }
              
              // 更新访问信息 Update access info
              metadata.accessedAt = Date.now();
              metadata.hits++;
              this.cacheIndex.set(fullKey, metadata);
              await this.saveCacheIndex();
              
              // 更新统计信息 Update statistics
              this.statistics.hitCount++;
              Logger.debug(TAG, `Cache hit (disk): ${key}`);
            }
          } else {
            // 过期，删除 Expired, delete
            await this.removeItemFromDisk(fullKey);
            Logger.debug(TAG, `Cache expired (disk): ${key}`);
          }
        }
      }
      
      // 如果未命中，更新统计信息 If miss, update statistics
      if (data === null) {
        this.statistics.missCount++;
        Logger.debug(TAG, `Cache miss: ${key}`);
      }
      
      // 更新统计信息 Update statistics
      await this.updateStatistics();
      
      // 记录操作时间 Record operation time
      const duration = Date.now() - startTime;
      this.getTimes.push(duration);
      if (this.getTimes.length > 1000) {
        this.getTimes.shift();
      }
      
      return data;
    } catch (error) {
      Logger.error(TAG, `Failed to get cache item: ${key}`, error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'get', key);
      return null;
    }
  }

  /**
   * 检查缓存项是否存在 | Check if cache item exists
   */
  public async exists(key: string): Promise<boolean> {
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      // 检查内存缓存 | Check memory cache
      if (this.cacheConfig.enableMemoryCache) {
        const cachedItem = this.memoryCache.get(fullKey);
        if (cachedItem && (cachedItem.expiry === 0 || Date.now() < cachedItem.expiry)) {
          return true;
        }
      }
      
      // 检查磁盘缓存 | Check disk cache
      if (this.cacheConfig.enableDiskCache) {
        const metadata = this.cacheIndex.get(fullKey);
        if (metadata && (metadata.expiry === 0 || Date.now() < metadata.expiry)) {
          const filePath = this.getCacheFilePath(fullKey);
          return await FileUtil.fileExists(filePath);
        }
      }
      
      return false;
    } catch (error) {
      Logger.error(TAG, `Failed to check cache existence: ${key}`, error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'exists', key);
      return false;
    }
  }

  /**
   * 获取缓存项元数据 | Get cache metadata
   */
  public async getMetadata(key: string): Promise<CacheMetadata | null> {
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      const metadata = this.cacheIndex.get(fullKey);
      if (!metadata) {
        return null;
      }
      
      // 检查是否过期 | Check if expired
      if (metadata.expiry > 0 && Date.now() > metadata.expiry) {
        await this.removeItemFromDisk(fullKey);
        return null;
      }
      
      return { ...metadata };
    } catch (error) {
      Logger.error(TAG, `Failed to get cache metadata: ${key}`, error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'getMetadata', key);
      return null;
    }
  }

  /**
   * 删除缓存项 | Remove cache item
   */
  public async remove(key: string): Promise<CacheOperationResult> {
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      // 从内存缓存删除 | Remove from memory cache
      if (this.cacheConfig.enableMemoryCache) {
        this.memoryCache.delete(fullKey);
      }
      
      // 从磁盘缓存删除 | Remove from disk cache
      if (this.cacheConfig.enableDiskCache) {
        await this.removeItemFromDisk(fullKey);
        await this.saveCacheIndex();
      }
      
      // 更新统计信息 | Update statistics
      await this.updateStatistics();
      
      Logger.debug(TAG, `Removed cache item: ${key}`);
      return {
        success: true,
        key: fullKey
      };
    } catch (error) {
      Logger.error(TAG, `Failed to remove cache item: ${key}`, error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'remove', key);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 批量设置缓存项 | Batch set cache items
   */
  public async setMultiple(
    items: Array<{
      key: string;
      data: Record<string, string | number | boolean | null>;
      options?: {
        expiry?: number;
        priority?: CachePriority;
        tags?: string[];
        type?: CacheType;
        source?: string;
      };
    }>
  ): Promise<Array<CacheOperationResult>> {
    const results: Array<CacheOperationResult> = [];
    
    try {
      for (const item of items) {
        const result = await this.set(item.key, item.data, item.options);
        results.push(result);
      }
      
      return results;
    } catch (error) {
      Logger.error(TAG, 'Failed to set multiple cache items', error instanceof Error ? error : new Error(String(error)));
      this.recordError(error as Error, 'setMultiple');
      return [];
    }
  }

  /**
   * 格式化大小 | Format size
   */
  private formatSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * 通知清理完成 | Notify cleanup completed
   */
  private notifyCleanupCompleted(deletedCount: number, freedSpace: number): void {
    for (const listener of this.cleanupListeners) {
      try {
        listener(deletedCount, freedSpace);
      } catch (error) {
        Logger.error(TAG, 'Error in cleanup listener', error instanceof Error ? error : new Error(String(error)));
      }
    }
  }

  /**
   * 通知缓存项被清理 | Notify cache item eviction
   */
  private notifyEviction(key: string, metadata: CacheMetadata): void {
    for (const listener of this.evictionListeners) {
      try {
        listener(key, metadata);
      } catch (error) {
        Logger.error(TAG, 'Error in eviction listener', error instanceof Error ? error : new Error(String(error)));
      }
    }
  }
}
