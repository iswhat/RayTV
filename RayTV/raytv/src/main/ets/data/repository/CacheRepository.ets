// CacheRepository - 缓存仓库类 | Cache repository class
// 负责管理应用程序的缓存数据，提供统一的缓存读写和管理接口 | Responsible for managing application cache data, providing unified cache read/write and management interface

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import FileUtil from '../../common/util/FileUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import FormatUtil from '../../common/util/FormatUtil';
import {
  CacheType,
  CachePolicy,
  CachePriority,
  CacheItem,
  CacheMetadata,
  CacheConfig,
  CacheStatistics,
  CacheCleanupOptions,
  CacheSearchParams
} from '../model/CacheModel';
import { LocalStorageType } from '../model/LocalModel';

/**
 * 缓存事件类型 | Cache event types
 */
export const CacheEventType = {
  CACHE_ADDED: 'cache:added',
  CACHE_UPDATED: 'cache:updated',
  CACHE_REMOVED: 'cache:removed',
  CACHE_CLEARED: 'cache:cleared',
  CACHE_EXPIRED: 'cache:expired',
  CACHE_SIZE_CHANGED: 'cache:sizeChanged',
  CACHE_STATISTICS_UPDATED: 'cache:statisticsUpdated',
  CACHE_ERROR: 'cache:error'
} as const;

/**
 * 缓存变更事件数据 | Cache change event data
 */
export interface CacheChangeEvent<T = unknown> {
  key: string;          // 缓存键 | Cache key
  type: CacheType;      // 缓存类型 | Cache type
  value?: T;            // 缓存值（添加/更新时） | Cache value (when adding/updating)
  metadata?: CacheMetadata; // 缓存元数据 | Cache metadata
}

/**
 * 缓存仓库类 | Cache repository class
 */
export class CacheRepository {
  private static instance: CacheRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private fileUtil = FileUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private formatUtil = FormatUtil.getInstance();
  
  // 内存缓存 | Memory cache
  private memoryCache: Map<string, CacheItem<unknown>> = new Map();
  
  // 缓存配置 | Cache configuration
  private cacheConfig: CacheConfig = {
    maxSize: 512 * 1024 * 1024, // 512MB
    defaultExpiry: 3600 * 1000, // 1小时 | 1 hour
    cleanupInterval: 300000,    // 5分钟 | 5 minutes
    memoryLimit: 64 * 1024 * 1024, // 64MB
    diskLimit: 448 * 1024 * 1024,  // 448MB
    evictionPolicy: 'LRU'      // 最近最少使用策略 | Least Recently Used policy
  };
  
  // 缓存统计信息 | Cache statistics
  private cacheStatistics: CacheStatistics = {
    hits: 0,
    misses: 0,
    requests: 0,
    memoryItems: 0,
    diskItems: 0,
    memorySize: 0,
    diskSize: 0,
    evictions: 0,
    expirations: 0
  };
  
  // 缓存目录 | Cache directory
  private cacheDirectory: string | null = null;
  
  // 定时清理器 | Periodic cleanup timer
  private cleanupTimer: number | null = null;
  
  // 是否已初始化 | Whether initialized
  private initialized: boolean = false;
  
  // 批量操作标志 | Batch operation flag
  private batchOperation: boolean = false;
  private pendingEvents: CacheChangeEvent[] = [];

  /**
 * 私有构造函数 | Private constructor
 */
  private constructor() {
    this.logger.info('CacheRepository initialized');
    this.setupEventListeners();
  }

  /**
 * 获取CacheRepository单例实例 | Get CacheRepository singleton instance
 */
  public static getInstance(): CacheRepository {
    if (!CacheRepository.instance) {
      CacheRepository.instance = new CacheRepository();
    }
    return CacheRepository.instance;
  }

  /**
 * 初始化缓存系统 | Initialize cache system
 * @param config 缓存配置 | Cache configuration
 * @param cacheDir 缓存目录 | Cache directory
 */
  public async initialize(config?: Partial<CacheConfig>, cacheDir?: string): Promise<void> {
    try {
      if (this.initialized) {
        this.logger.warn('CacheRepository already initialized');
        return;
      }
      
      // 更新配置 | Update configuration
      if (config) {
        this.cacheConfig = { ...this.cacheConfig, ...config };
      }
      
      // 设置缓存目录 | Set cache directory
      if (cacheDir) {
        this.cacheDirectory = cacheDir;
        
        // 确保缓存目录存在 | Ensure cache directory exists
        await this.fileUtil.ensureDirectoryExists(cacheDir);
      }
      
      // 加载缓存统计信息 | Load cache statistics
      await this.loadCacheStatistics();
      
      // 启动定时清理 | Start periodic cleanup
      this.startPeriodicCleanup();
      
      this.initialized = true;
      this.logger.info('CacheRepository initialized successfully', {
        maxSize: this.formatUtil.formatFileSize(this.cacheConfig.maxSize),
        defaultExpiry: this.formatUtil.formatTime(this.cacheConfig.defaultExpiry),
        cacheDir: this.cacheDirectory
      });
    } catch (error) {
      this.logger.error('Failed to initialize CacheRepository', error as Error);
      
      // 发布缓存错误事件 | Emit cache error event
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error });
    }
  }

  /**
 * 设置事件监听器 | Set up event listeners
 */
  private setupEventListeners(): void {
    // 监听应用退出事件，保存统计信息 | Listen for app exit event, save statistics
    this.eventBus.on('app:exit', async () => {
      await this.shutdown();
    });
  }

  /**
 * 添加或更新缓存 | Add or update cache
 * @param key 缓存键 | Cache key
 * @param value 缓存值 | Cache value
 * @param options 缓存选项 | Cache options
 */
  public async setCache<T>(key: string, value: T, options?: {
    expiry?: number;          // 过期时间（秒） | Expiry time (seconds)
    type?: CacheType;         // 缓存类型 | Cache type
    priority?: CachePriority; // 优先级 | Priority
    policy?: CachePolicy;     // 缓存策略 | Cache policy
    tags?: string[];          // 缓存标签 | Cache tags
  }): Promise<void> {
    // 检查是否初始化 | Check if initialized
    if (!this.initialized) {
      throw new Error('CacheRepository not initialized');
    }
    
    try {
      const now = Date.now();
      const expiry = options?.expiry || this.cacheConfig.defaultExpiry;
      const cacheType = options?.type || CacheType.MEMORY;
      const priority = options?.priority || CachePriority.NORMAL;
      const tags = options?.tags || [];
      
      // 创建缓存元数据 | Create cache metadata
      const metadata: CacheMetadata = {
        key,
        type: cacheType,
        priority,
        policy: options?.policy || CachePolicy.STANDARD,
        createdAt: now,
        updatedAt: now,
        lastAccessedAt: now,
        expiry: expiry > 0 ? now + expiry : 0, // 0表示永不过期 | 0 means never expire
        size: this.calculateSize(value),
        tags
      };
      
      // 创建缓存项 | Create cache item
      const cacheItem: CacheItem<T> = {
        value,
        metadata
      };
      
      // 检查缓存大小限制 | Check cache size limit
      if (!this.checkCacheSizeLimit(metadata.size)) {
        // 尝试清理空间 | Try to cleanup space
        await this.cleanupCache({
          targetSizeReduction: metadata.size,
          priorityThreshold: priority
        });
        
        // 再次检查 | Check again
        if (!this.checkCacheSizeLimit(metadata.size)) {
          this.logger.warn(`Cache size limit exceeded, cannot store item: ${key}`);
          throw new Error('Cache size limit exceeded');
        }
      }
      
      // 存储到内存 | Store to memory
      if (cacheType === CacheType.MEMORY || cacheType === CacheType.MEMORY_DISK) {
        // 删除旧缓存项（如果存在） | Remove old cache item (if exists)
        const oldItem = this.memoryCache.get(key);
        if (oldItem) {
          this.updateCacheSizeStats(-oldItem.metadata.size, true);
        }
        
        this.memoryCache.set(key, cacheItem);
        this.updateCacheSizeStats(metadata.size, true);
        this.updateItemCountStats(true);
      }
      
      // 存储到磁盘 | Store to disk
      if (cacheType === CacheType.DISK || cacheType === CacheType.MEMORY_DISK) {
        await this.storeToDisk(key, cacheItem);
      }
      
      // 构建事件 | Build event
      const event: CacheChangeEvent<T> = {
        key,
        type: cacheType,
        value,
        metadata
      };
      
      // 处理事件 | Handle event
      if (this.batchOperation) {
        this.pendingEvents.push(event);
      } else {
        // 发布缓存添加/更新事件 | Emit cache added/updated event
        const eventType = this.memoryCache.has(key) && !oldItem ? CacheEventType.CACHE_UPDATED : CacheEventType.CACHE_ADDED;
        this.eventBus.emit(eventType, event);
        
        // 更新统计信息 | Update statistics
        this.updateStatistics();
      }
      
      this.logger.debug(`Cache set: ${key}`, {
        type: cacheType,
        size: this.formatUtil.formatFileSize(metadata.size),
        expiry: expiry > 0 ? this.formatUtil.formatTime(expiry) : 'never'
      });
    } catch (error) {
      this.logger.error(`Failed to set cache: ${key}`, error as Error);
      
      // 发布缓存错误事件 | Emit cache error event
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error });
      
      throw error;
    }
  }

  /**
 * 获取缓存 | Get cache
 * @param key 缓存键 | Cache key
 * @param options 获取选项 | Get options
 */
  public async getCache<T>(key: string, options?: {
    ignoreExpiry?: boolean;  // 是否忽略过期 | Whether to ignore expiry
    updateAccessTime?: boolean; // 是否更新访问时间 | Whether to update access time
  }): Promise<T | null> {
    // 检查是否初始化 | Check if initialized
    if (!this.initialized) {
      throw new Error('CacheRepository not initialized');
    }
    
    try {
      this.cacheStatistics.requests++;
      
      // 优先从内存获取 | Priority get from memory
      const memoryItem = this.memoryCache.get(key);
      if (memoryItem) {
        // 检查是否过期 | Check if expired
        if (!options?.ignoreExpiry && this.isExpired(memoryItem.metadata)) {
          this.cacheStatistics.misses++;
          this.cacheStatistics.expirations++;
          
          // 删除过期缓存 | Remove expired cache
          await this.removeCache(key);
          
          // 发布过期事件 | Emit expired event
          this.eventBus.emit(CacheEventType.CACHE_EXPIRED, {
            key,
            type: memoryItem.metadata.type,
            metadata: memoryItem.metadata
          });
          
          return null;
        }
        
        // 更新访问时间 | Update access time
        if (options?.updateAccessTime !== false) {
          memoryItem.metadata.lastAccessedAt = Date.now();
        }
        
        this.cacheStatistics.hits++;
        
        this.logger.debug(`Cache hit (memory): ${key}`);
        return memoryItem.value as T;
      }
      
      // 从磁盘获取 | Get from disk
      const diskItem = await this.getFromDisk(key);
      if (diskItem) {
        // 检查是否过期 | Check if expired
        if (!options?.ignoreExpiry && this.isExpired(diskItem.metadata)) {
          this.cacheStatistics.misses++;
          this.cacheStatistics.expirations++;
          
          // 删除过期缓存 | Remove expired cache
          await this.removeCache(key);
          
          // 发布过期事件 | Emit expired event
          this.eventBus.emit(CacheEventType.CACHE_EXPIRED, {
            key,
            type: diskItem.metadata.type,
            metadata: diskItem.metadata
          });
          
          return null;
        }
        
        // 更新访问时间 | Update access time
        if (options?.updateAccessTime !== false) {
          diskItem.metadata.lastAccessedAt = Date.now();
          await this.storeToDisk(key, diskItem);
        }
        
        this.cacheStatistics.hits++;
        
        this.logger.debug(`Cache hit (disk): ${key}`);
        return diskItem.value as T;
      }
      
      // 缓存未命中 | Cache miss
      this.cacheStatistics.misses++;
      this.logger.debug(`Cache miss: ${key}`);
      
      return null;
    } catch (error) {
      this.logger.error(`Failed to get cache: ${key}`, error as Error);
      
      // 发布缓存错误事件 | Emit cache error event
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error });
      
      throw error;
    }
  }

  /**
 * 检查缓存是否存在 | Check if cache exists
 * @param key 缓存键 | Cache key
 */
  public hasCache(key: string): boolean {
    if (!this.initialized) {
      return false;
    }
    
    return this.memoryCache.has(key) || this.fileUtil.fileExists(this.getDiskCachePath(key));
  }

  /**
 * 删除缓存 | Remove cache
 * @param key 缓存键 | Cache key
 */
  public async removeCache(key: string): Promise<void> {
    if (!this.initialized) {
      return;
    }
    
    try {
      let removedItem: CacheItem<unknown> | null = null;
      
      // 从内存删除 | Remove from memory
      const memoryItem = this.memoryCache.get(key);
      if (memoryItem) {
        removedItem = memoryItem;
        this.memoryCache.delete(key);
        this.updateCacheSizeStats(-memoryItem.metadata.size, true);
        this.updateItemCountStats(false);
      }
      
      // 从磁盘删除 | Remove from disk
      const diskPath = this.getDiskCachePath(key);
      if (this.fileUtil.fileExists(diskPath)) {
        if (!removedItem) {
          removedItem = await this.getFromDisk(key);
        }
        await this.fileUtil.deleteFile(diskPath);
        this.updateCacheSizeStats(-(removedItem?.metadata.size || 0), false);
        this.updateItemCountStats(false);
      }
      
      if (removedItem) {
        // 构建事件 | Build event
        const event: CacheChangeEvent = {
          key,
          type: removedItem.metadata.type,
          metadata: removedItem.metadata
        };
        
        // 处理事件 | Handle event
        if (this.batchOperation) {
          this.pendingEvents.push(event);
        } else {
          // 发布缓存删除事件 | Emit cache removed event
          this.eventBus.emit(CacheEventType.CACHE_REMOVED, event);
          
          // 更新统计信息 | Update statistics
          this.updateStatistics();
        }
        
        this.logger.debug(`Cache removed: ${key}`);
      }
    } catch (error) {
      this.logger.error(`Failed to remove cache: ${key}`, error as Error);
      
      // 发布缓存错误事件 | Emit cache error event
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error });
      
      throw error;
    }
  }

  /**
 * 清除缓存 | Clear cache
 * @param options 清除选项 | Clear options
 */
  public async clearCache(options?: {
    type?: CacheType;        // 缓存类型 | Cache type
    priority?: CachePriority; // 优先级阈值 | Priority threshold
    tags?: string[];         // 标签过滤 | Tag filter
  }): Promise<void> {
    if (!this.initialized) {
      return;
    }
    
    try {
      const keysToRemove: string[] = [];
      
      // 收集要删除的缓存键 | Collect keys to remove
      for (const [key, item] of this.memoryCache.entries()) {
        if (this.shouldRemoveItem(item.metadata, options)) {
          keysToRemove.push(key);
        }
      }
      
      // 删除内存缓存 | Remove memory cache
      for (const key of keysToRemove) {
        const item = this.memoryCache.get(key);
        if (item) {
          this.updateCacheSizeStats(-item.metadata.size, true);
          this.updateItemCountStats(false);
        }
        this.memoryCache.delete(key);
      }
      
      // 删除磁盘缓存 | Remove disk cache
      if (this.cacheDirectory) {
        const files = await this.fileUtil.listFiles(this.cacheDirectory);
        for (const file of files) {
          if (file.endsWith('.json')) {
            const key = file.replace('.json', '');
            const item = await this.getFromDisk(key);
            if (item && this.shouldRemoveItem(item.metadata, options)) {
              await this.fileUtil.deleteFile(file);
              this.updateCacheSizeStats(-item.metadata.size, false);
              this.updateItemCountStats(false);
            }
          }
        }
      }
      
      // 发布缓存清除事件 | Emit cache cleared event
      if (!this.batchOperation) {
        this.eventBus.emit(CacheEventType.CACHE_CLEARED, {
          type: options?.type,
          priority: options?.priority,
          tags: options?.tags
        });
        
        // 更新统计信息 | Update statistics
        this.updateStatistics();
      }
      
      this.logger.info(`Cache cleared`, {
        memoryItemsRemoved: keysToRemove.length,
        options
      });
    } catch (error) {
      this.logger.error('Failed to clear cache', error as Error);
      
      // 发布缓存错误事件 | Emit cache error event
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error });
      
      throw error;
    }
  }

  /**
 * 获取缓存统计信息 | Get cache statistics
 */
  public getStatistics(): CacheStatistics {
    return { ...this.cacheStatistics };
  }

  /**
 * 开始批量操作 | Start batch operation
 */
  public startBatchOperation(): void {
    this.batchOperation = true;
    this.pendingEvents = [];
  }

  /**
 * 结束批量操作 | End batch operation
 */
  public async endBatchOperation(): Promise<void> {
    this.batchOperation = false;
    
    // 发布所有待处理事件 | Emit all pending events
    for (const event of this.pendingEvents) {
      // 根据事件类型发布对应事件
      // 这里简化处理，实际应根据事件类型区分
      this.eventBus.emit(CacheEventType.CACHE_UPDATED, event);
    }
    
    this.pendingEvents = [];
    
    // 更新统计信息 | Update statistics
    this.updateStatistics();
  }

  /**
 * 搜索缓存 | Search cache
 * @param params 搜索参数 | Search parameters
 */
  public async searchCache(params: CacheSearchParams): Promise<CacheItem<unknown>[]> {
    if (!this.initialized) {
      return [];
    }
    
    try {
      const results: CacheItem<unknown>[] = [];
      
      // 搜索内存缓存 | Search memory cache
      for (const item of this.memoryCache.values()) {
        if (this.matchesSearchCriteria(item.metadata, params)) {
          results.push(item);
        }
      }
      
      // 搜索磁盘缓存 | Search disk cache
      if (this.cacheDirectory && params.includeDisk) {
        const files = await this.fileUtil.listFiles(this.cacheDirectory);
        for (const file of files) {
          if (file.endsWith('.json')) {
            const item = await this.getFromDisk(file.replace('.json', ''));
            if (item && this.matchesSearchCriteria(item.metadata, params)) {
              results.push(item);
            }
          }
        }
      }
      
      // 排序结果 | Sort results
      if (params.sortBy) {
        results.sort((a, b) => {
          const aValue = this.getSortValue(a.metadata, params.sortBy!);
          const bValue = this.getSortValue(b.metadata, params.sortBy!);
          
          if (aValue < bValue) return params.sortOrder === 'asc' ? -1 : 1;
          if (aValue > bValue) return params.sortOrder === 'asc' ? 1 : -1;
          return 0;
        });
      }
      
      // 限制结果数量 | Limit results
      if (params.limit && results.length > params.limit) {
        results.splice(params.limit);
      }
      
      return results;
    } catch (error) {
      this.logger.error('Failed to search cache', error as Error);
      
      // 发布缓存错误事件 | Emit cache error event
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error });
      
      throw error;
    }
  }

  /**
 * 关闭缓存仓库 | Shutdown cache repository
 */
  public async shutdown(): Promise<void> {
    if (!this.initialized) {
      return;
    }
    
    try {
      // 停止定时清理 | Stop periodic cleanup
      this.stopPeriodicCleanup();
      
      // 保存缓存统计信息 | Save cache statistics
      await this.saveCacheStatistics();
      
      // 清空内存缓存 | Clear memory cache
      this.memoryCache.clear();
      
      this.initialized = false;
      this.logger.info('CacheRepository shutdown');
    } catch (error) {
      this.logger.error('Failed to shutdown CacheRepository', error as Error);
      
      // 发布缓存错误事件 | Emit cache error event
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error });
      
      throw error;
    }
  }

  // 绉佹湁杈呭姪鏂规硶

  /**
   * 鍔犺浇缂撳瓨缁熻淇℃伅
   */
  private async loadCacheStatistics(): Promise<void> {
    try {
      const stats = await this.storageUtil.get(LocalStorageType.CACHE_STATISTICS);
      if (stats) {
        this.cacheStatistics = { ...this.cacheStatistics, ...JSON.parse(stats) };
      }
    } catch (error) {
      this.logger.warn('Failed to load cache statistics, using defaults');
    }
  }

  /**
   * 淇濆瓨缂撳瓨缁熻淇℃伅
   */
  private async saveCacheStatistics(): Promise<void> {
    try {
      await this.storageUtil.set(
        LocalStorageType.CACHE_STATISTICS,
        JSON.stringify(this.cacheStatistics)
      );
    } catch (error) {
      this.logger.warn('Failed to save cache statistics');
    }
  }

  /**
   * 鍚姩瀹氭椂娓呯悊
   */
  private startPeriodicCleanup(): void {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
    }
    
    this.cleanupTimer = setInterval(async () => {
      try {
        await this.cleanupExpiredCache();
        await this.cleanupCacheBySize();
      } catch (error) {
        this.Logger.error('Periodic cleanup failed', error as Error);
      }
    }, this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval instanceof Error ? this.cacheConfig.cleanupInterval : new Error(String(this.cacheConfig.cleanupInterval))))))) as unknown as number;
  }

  /**
   * 鍋滄瀹氭椂娓呯悊
   */
  private stopPeriodicCleanup(): void {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
      this.cleanupTimer = null;
    }
  }

  /**
   * 妫€鏌ョ紦瀛樻槸鍚﹁繃鏈?   */
  private isExpired(metadata: CacheMetadata): boolean {
    return metadata.expiry > 0 && Date.now() > metadata.expiry;
  }

  /**
   * 璁＄畻瀵硅薄澶у皬
   */
  private calculateSize(value: Record<string, string | number | boolean | null>): number {
    try {
      const jsonString = JSON.stringify(value);
      return new Blob([jsonString]).size;
    } catch {
      return 1024; // 榛樿澶у皬
    }
  }

  /**
   * 妫€鏌ョ紦瀛樺ぇ灏忛檺鍒?   */
  private checkCacheSizeLimit(newSize: number): boolean {
    const totalSize = this.cacheStatistics.memorySize + this.cacheStatistics.diskSize;
    return totalSize + newSize <= this.cacheConfig.maxSize;
  }

  /**
   * 鏇存柊缂撳瓨澶у皬缁熻
   */
  private updateCacheSizeStats(sizeDelta: number, isMemory: boolean): void {
    if (isMemory) {
      this.cacheStatistics.memorySize += sizeDelta;
    } else {
      this.cacheStatistics.diskSize += sizeDelta;
    }
    
    // 鍙戝竷澶у皬鍙樻洿浜嬩欢
    if (!this.batchOperation) {
      this.eventBus.emit(CacheEventType.CACHE_SIZE_CHANGED, {
        memorySize: this.cacheStatistics.memorySize,
        diskSize: this.cacheStatistics.diskSize,
        totalSize: this.cacheStatistics.memorySize + this.cacheStatistics.diskSize
      });
    }
  }

  /**
   * 鏇存柊缂撳瓨椤规暟閲忕粺璁?   */
  private updateItemCountStats(isMemory: boolean): void {
    if (isMemory) {
      this.cacheStatistics.memoryItems = this.memoryCache.size;
    } else {
      // 纾佺洏椤规暟閲忛渶瑕佹壂鎻忔枃浠剁郴缁燂紝杩欓噷绠€鍖栧鐞?      this.cacheStatistics.diskItems = Math.max(0, this.cacheStatistics.diskItems);
    }
  }

  /**
   * 鏇存柊缁熻淇℃伅
   */
  private updateStatistics(): void {
    if (!this.batchOperation) {
      this.eventBus.emit(CacheEventType.CACHE_STATISTICS_UPDATED, {
        ...this.cacheStatistics
      });
    }
  }

  /**
   * 鑾峰彇纾佺洏缂撳瓨璺緞
   */
  private getDiskCachePath(key: string): string {
    if (!this.cacheDirectory) {
      throw new Error('Cache directory not set');
    }
    
    // 瀵筴ey杩涜瀹夊叏缂栫爜
    const safeKey = encodeURIComponent(key).replace(/%/g, '_');
    return `${this.cacheDirectory}/${safeKey}.json`;
  }

  /**
   * 瀛樺偍鍒扮鐩?   */
  private async storeToDisk<T>(key: string, item: CacheItem<T>): Promise<void> {
    if (!this.cacheDirectory) {
      return;
    }
    
    const filePath = this.getDiskCachePath(key);
    const content = JSON.stringify(item, null, 2);
    
    await this.fileUtil.writeFile(filePath, content);
  }

  /**
   * 浠庣鐩樿幏鍙?   */
  private async getFromDisk<T>(key: string): Promise<CacheItem<T> | null> {
    if (!this.cacheDirectory) {
      return null;
    }
    
    const filePath = this.getDiskCachePath(key);
    
    if (!this.fileUtil.fileExists(filePath)) {
      return null;
    }
    
    try {
      const content = await this.fileUtil.readFile(filePath);
      return JSON.parse(content) as CacheItem<T>;
    } catch (error) {
      this.logger.warn(`Failed to read cache from disk: ${key}`, error as Error);
      
      // 鍒犻櫎鎹熷潖鐨勬枃浠?      await this.fileUtil.deleteFile(filePath);
      
      return null;
    }
  }

  /**
   * 娓呯悊杩囨湡缂撳瓨
   */
  private async cleanupExpiredCache(): Promise<void> {
    try {
      const expiredKeys: string[] = [];
      
      // 妫€鏌ュ唴瀛樼紦瀛?      for (const [key, item] of this.memoryCache.entries()) {
        if (this.isExpired(item.metadata)) {
          expiredKeys.push(key);
        }
      }
      
      // 鍒犻櫎杩囨湡缂撳瓨
      for (const key of expiredKeys) {
        await this.removeCache(key);
      }
      
      // 妫€鏌ョ鐩樼紦瀛?      if (this.cacheDirectory) {
        const files = await this.fileUtil.listFiles(this.cacheDirectory);
        for (const file of files) {
          if (file.endsWith('.json')) {
            const key = file.replace('.json', '');
            const item = await this.getFromDisk(key);
            if (item && this.isExpired(item.metadata)) {
              await this.removeCache(key);
            }
          }
        }
      }
      
      if (expiredKeys.length > 0) {
        this.logger.info(`Cleaned up ${expiredKeys.length} expired cache items`);
      }
    } catch (error) {
      this.Logger.error('Failed to cleanup expired cache', error as Error);
      throw error;
    }
  }

  /**
   * 鏍规嵁澶у皬娓呯悊缂撳瓨
   */
  private async cleanupCacheBySize(): Promise<void> {
    try {
      const totalSize = this.cacheStatistics.memorySize + this.cacheStatistics.diskSize;
      
      if (totalSize <= this.cacheConfig.maxSize) {
        return;
      }
      
      const targetReduction = totalSize - this.cacheConfig.maxSize * 0.9; // 娓呯悊鍒?0%瀹归噺
      
      await this.cleanupCache({
        targetSizeReduction: targetReduction, priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      } instanceof Error ? priorityThreshold: CachePriority.LOW
      } : new Error(String(priorityThreshold: CachePriority.LOW
      })))))));
    } catch (error) {
      this.Logger.error('Failed to cleanup cache by size', error as Error);
      throw error;
    }
  }

  /**
   * 娓呯悊缂撳瓨
   */
  private async cleanupCache(options: CacheCleanupOptions): Promise<void> {
    try {
      const itemsToRemove: Array<{key: string, metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 鏀堕泦瑕佸垹闄ょ殑缂撳瓨椤?      for (const [key, item] of this.memoryCache.entries()))))))) {
        if (item.metadata.priority <= (options.priorityThreshold || CachePriority.LOW)) {
          itemsToRemove.push({ key, metadata: item.metadata });
          totalSizeToRemove += item.metadata.size;
          
          if (totalSizeToRemove >= options.targetSizeReduction) {
            break;
          }
        }
      }
      
      // 濡傛灉鍐呭瓨缂撳瓨涓嶅锛屾鏌ョ鐩樼紦瀛?      if (totalSizeToRemove < options.targetSizeReduction && this.cacheDirectory) {
        const files = await this.fileUtil.listFiles(this.cacheDirectory);
        
        for (const file of files) {
          if (file.endsWith('.json')) {
            const key = file.replace('.json', '');
            const item = await this.getFromDisk(key);
            
            if (item && item.metadata.priority <= (options.priorityThreshold || CachePriority.LOW)) {
              itemsToRemove.push({ key, metadata: item.metadata });
              totalSizeToRemove += item.metadata.size;
              
              if (totalSizeToRemove >= options.targetSizeReduction) {
                break;
              }
            }
          }
        }
      }
      
      // 鍒犻櫎缂撳瓨椤?      for (const { key } of itemsToRemove) {
        await this.removeCache(key);
      }
      
      this.cacheStatistics.evictions += itemsToRemove.length;
      
      if (itemsToRemove.length > 0) {
        this.logger.info(`Cleaned up ${itemsToRemove.length} cache items`, {
          totalSizeRemoved: this.formatUtil.formatFileSize(totalSizeToRemove),
          priorityThreshold: options.priorityThreshold
        });
      }
    } catch (error) {
      this.Logger.error('Failed to cleanup cache', error as Error);
      throw error;
    }
  }

  /**
   * 妫€鏌ユ槸鍚﹀簲璇ュ垹闄ょ紦瀛橀」
   */
  private shouldRemoveItem(metadata: CacheMetadata, options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } instanceof Error ? options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  } : new Error(String(options?: {
    type?: CacheType;
    priority?: CachePriority;
    tags?: string[];
  }))))))): boolean {
    // 妫€鏌ョ被鍨?    if (options?.type && metadata.type !== options.type) {
      return false;
    }
    
    // 妫€鏌ヤ紭鍏堢骇
    if (options?.priority && metadata.priority > options.priority) {
      return false;
    }
    
    // 妫€鏌ユ爣绛?    if (options?.tags && options.tags.length > 0) {
      const hasMatchingTag = options.tags.some(tag => metadata.tags.includes(tag));
      if (!hasMatchingTag) {
        return false;
      }
    }
    
    return true;
  }

  /**
   * 妫€鏌ユ槸鍚﹀尮閰嶆悳绱㈡潯浠?   */
  private matchesSearchCriteria(metadata: CacheMetadata, params: CacheSearchParams): boolean {
    // 妫€鏌ョ被鍨?    if (params.type && metadata.type !== params.type) {
      return false;
    }
    
    // 妫€鏌ヤ紭鍏堢骇
    if (params.priority && metadata.priority !== params.priority) {
      return false;
    }
    
    // 妫€鏌ユ爣绛?    if (params.tags && params.tags.length > 0) {
      const hasMatchingTag = params.tags.some(tag => metadata.tags.includes(tag));
      if (!hasMatchingTag) {
        return false;
      }
    }
    
    // 妫€鏌ュ垱寤烘椂闂磋寖鍥?    if (params.createdAfter && metadata.createdAt < params.createdAfter) {
      return false;
    }
    
    if (params.createdBefore && metadata.createdAt > params.createdBefore) {
      return false;
    }
    
    // 妫€鏌ヨ闂椂闂磋寖鍥?    if (params.accessedAfter && metadata.lastAccessedAt < params.accessedAfter) {
      return false;
    }
    
    if (params.accessedBefore && metadata.lastAccessedAt > params.accessedBefore) {
      return false;
    }
    
    // 妫€鏌ヨ繃鏈熺姸鎬?    if (params.expiredOnly && !this.isExpired(metadata)) {
      return false;
    }
    
    if (params.nonExpiredOnly && this.isExpired(metadata)) {
      return false;
    }
    
    return true;
  }

  /**
   * 鑾峰彇鎺掑簭鍊?   */
  private getSortValue(metadata: CacheMetadata, sortBy: keyof CacheMetadata): number | string {
    const value = metadata[sortBy];
    
    if (typeof value === 'number' || typeof value === 'string') {
      return value;
    }
    
    return 0;
  }
}





