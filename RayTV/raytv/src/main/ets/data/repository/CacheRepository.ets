// CacheRepository - 缓存仓库�?// 负责管理应用程序的缓存数据，提供统一的缓存读写和管理接口

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
 * 缓存事件类型
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
 * 缓存变更事件数据
 */
export interface CacheChangeEvent<T = unknown> {
  key: string;          // 缓存�?  type: CacheType;      // 缓存类型
  value?: T;            // 缓存值（添加/更新时）
  metadata?: CacheMetadata; // 缓存元数�?}

/**
 * 缓存仓库�? */
export class CacheRepository {
  private static instance: CacheRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private fileUtil = FileUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private formatUtil = FormatUtil.getInstance();
  
  // 内存缓存
  private memoryCache: Map<string, CacheItem<unknown>> = new Map();
  
  // 缓存配置
  private cacheConfig: CacheConfig = {
    maxSize: 512 * 1024 * 1024, // 512MB
    defaultExpiry: 3600 * 1000, // 1小时
    cleanupInterval: 300000,    // 5分钟
    memoryLimit: 64 * 1024 * 1024, // 64MB
    diskLimit: 448 * 1024 * 1024,  // 448MB
    evictionPolicy: 'LRU'      // 最近最少使用策�?  };
  
  // 缓存统计信息
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
  
  // 缓存目录
  private cacheDirectory: string | null = null;
  
  // 定时清理�?  private cleanupTimer: number | null = null;
  
  // 是否已初始化
  private initialized: boolean = false;
  
  // 批量操作标志
  private batchOperation: boolean = false;
  private pendingEvents: CacheChangeEvent[] = [];

  /**
   * 私有构造函�?   */
  private constructor() {
    this.logger.info('CacheRepository initialized');
    this.setupEventListeners();
  }

  /**
   * 获取CacheRepository单例实例
   */
  public static getInstance(): CacheRepository {
    if (!CacheRepository.instance) {
      CacheRepository.instance = new CacheRepository();
    }
    return CacheRepository.instance;
  }

  /**
   * 初始化缓存仓�?   * @param config 缓存配置
   * @param cacheDir 缓存目录
   */
  public async initialize(config?: Partial<CacheConfig>, cacheDir?: string): Promise<void> {
    try {
      if (this.initialized) {
        this.logger.warn('CacheRepository already initialized');
        return;
      }
      
      // 更新配置
      if (config) {
        this.cacheConfig = { ...this.cacheConfig, ...config };
      }
      
      // 设置缓存目录
      if (cacheDir) {
        this.cacheDirectory = cacheDir;
        
        // 确保缓存目录存在
        await this.fileUtil.ensureDirectoryExists(cacheDir);
      }
      
      // 加载缓存统计信息
      await this.loadCacheStatistics();
      
      // 启动定时清理
      this.startPeriodicCleanup();
      
      this.initialized = true;
      this.logger.info('CacheRepository initialized successfully', {
        maxSize: this.formatUtil.formatFileSize(this.cacheConfig.maxSize),
        defaultExpiry: this.formatUtil.formatTime(this.cacheConfig.defaultExpiry),
        cacheDir: this.cacheDirectory
      });
    } catch (error) {
      this.Logger.error('Failed to initialize CacheRepository', error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error })))))));
    }
  }

  /**
   * 设置事件监听�?   */
  private setupEventListeners(): void {
    // 监听应用退出事件，保存统计信息
    this.eventBus.on('app:exit', async () => {
      await this.shutdown();
    });
  }

  /**
   * 添加或更新缓�?   * @param key 缓存�?   * @param value 缓存�?   * @param options 缓存选项
   */
  public async setCache<T>(key: string, value: T, options?: {
    expiry?: number;          // 过期时间（毫秒）
    type?: CacheType;         // 缓存类型
    priority?: CachePriority; // 优先�?    policy?: CachePolicy;     // 缓存策略
    tags?: string[];          // 缓存标签
  }): Promise<void> {
    // 检查是否初始化
    if (!this.initialized) {
      throw new Error('CacheRepository not initialized');
    }
    
    try {
      const now = Date.now();
      const expiry = options?.expiry || this.cacheConfig.defaultExpiry;
      const cacheType = options?.type || CacheType.MEMORY;
      const priority = options?.priority || CachePriority.NORMAL;
      const tags = options?.tags || [];
      
      // 创建缓存元数�?      const metadata: CacheMetadata = {
        key,
        type: cacheType,
        priority,
        policy: options?.policy || CachePolicy.STANDARD,
        createdAt: now,
        updatedAt: now,
        lastAccessedAt: now,
        expiry: expiry > 0 ? now + expiry : 0, // 0表示永不过期
        size: this.calculateSize(value),
        tags
      };
      
      // 创建缓存�?      const cacheItem: CacheItem<T> = {
        value,
        metadata
      };
      
      // 检查缓存大小限�?      if (!this.checkCacheSizeLimit(metadata.size)) {
        // 尝试清理空间
        await this.cleanupCache({
          targetSizeReduction: metadata.size,
          priorityThreshold: priority
        });
        
        // 再次检�?        if (!this.checkCacheSizeLimit(metadata.size)) {
          this.logger.warn(`Cache size limit exceeded, cannot store item: ${key}`);
          throw new Error('Cache size limit exceeded');
        }
      }
      
      // 存储到内�?      if (cacheType === CacheType.MEMORY || cacheType === CacheType.MEMORY_DISK) {
        // 移除旧缓存项（如果存在）
        const oldItem = this.memoryCache.get(key);
        if (oldItem) {
          this.updateCacheSizeStats(-oldItem.metadata.size, true);
        }
        
        this.memoryCache.set(key, cacheItem);
        this.updateCacheSizeStats(metadata.size, true);
        this.updateItemCountStats(true);
      }
      
      // 存储到磁�?      if (cacheType === CacheType.DISK || cacheType === CacheType.MEMORY_DISK) {
        await this.storeToDisk(key, cacheItem);
      }
      
      // 构建事件
      const event: CacheChangeEvent<T> = {
        key,
        type: cacheType,
        value,
        metadata
      };
      
      // 处理事件
      if (this.batchOperation) {
        this.pendingEvents.push(event);
      } else {
        // 发布缓存添加/更新事件
        const eventType = this.memoryCache.has(key) && !oldItem ? CacheEventType.CACHE_UPDATED : CacheEventType.CACHE_ADDED;
        this.eventBus.emit(eventType, event);
        
        // 更新统计信息
        this.updateStatistics();
      }
      
      this.logger.debug(`Cache set: ${key}`, {
        type: cacheType,
        size: this.formatUtil.formatFileSize(metadata.size),
        expiry: expiry > 0 ? this.formatUtil.formatTime(expiry) : 'never'
      });
    } catch (error) {
      this.Logger.error(`Failed to set cache: ${key}`, error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error })))))));
      
      throw error;
    }
  }

  /**
   * 获取缓存
   * @param key 缓存�?   * @param options 获取选项
   */
  public async getCache<T>(key: string, options?: {
    ignoreExpiry?: boolean;  // 是否忽略过期
    updateAccessTime?: boolean; // 是否更新访问时间
  }): Promise<T | null> {
    // 检查是否初始化
    if (!this.initialized) {
      throw new Error('CacheRepository not initialized');
    }
    
    try {
      this.cacheStatistics.requests++;
      
      // 优先从内存获�?      const memoryItem = this.memoryCache.get(key);
      if (memoryItem) {
        // 检查是否过�?        if (!options?.ignoreExpiry && this.isExpired(memoryItem.metadata)) {
          this.cacheStatistics.misses++;
          this.cacheStatistics.expirations++;
          
          // 移除过期缓存
          await this.removeCache(key);
          
          // 发布过期事件
          this.eventBus.emit(CacheEventType.CACHE_EXPIRED, {
            key,
            type: memoryItem.metadata.type,
            metadata: memoryItem.metadata
          });
          
          return null;
        }
        
        // 更新访问时间
        if (options?.updateAccessTime !== false) {
          memoryItem.metadata.lastAccessedAt = Date.now();
        }
        
        this.cacheStatistics.hits++;
        
        this.logger.debug(`Cache hit (memory): ${key}`);
        return memoryItem.value as T;
      }
      
      // 从磁盘获�?      const diskItem = await this.getFromDisk(key);
      if (diskItem) {
        // 检查是否过�?        if (!options?.ignoreExpiry && this.isExpired(diskItem.metadata)) {
          this.cacheStatistics.misses++;
          this.cacheStatistics.expirations++;
          
          // 移除过期缓存
          await this.removeCache(key);
          
          // 发布过期事件
          this.eventBus.emit(CacheEventType.CACHE_EXPIRED, {
            key,
            type: diskItem.metadata.type,
            metadata: diskItem.metadata
          });
          
          return null;
        }
        
        // 更新访问时间
        if (options?.updateAccessTime !== false) {
          diskItem.metadata.lastAccessedAt = Date.now();
          await this.storeToDisk(key, diskItem);
        }
        
        this.cacheStatistics.hits++;
        
        this.logger.debug(`Cache hit (disk): ${key}`);
        return diskItem.value as T;
      }
      
      // 缓存未命�?      this.cacheStatistics.misses++;
      this.logger.debug(`Cache miss: ${key}`);
      
      return null;
    } catch (error) {
      this.Logger.error(`Failed to get cache: ${key}`, error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error })))))));
      
      throw error;
    }
  }

  /**
   * 检查缓存是否存�?   * @param key 缓存�?   */
  public hasCache(key: string): boolean {
    if (!this.initialized) {
      return false;
    }
    
    return this.memoryCache.has(key) || this.fileUtil.fileExists(this.getDiskCachePath(key));
  }

  /**
   * 删除缓存
   * @param key 缓存�?   */
  public async removeCache(key: string): Promise<void> {
    if (!this.initialized) {
      return;
    }
    
    try {
      let removedItem: CacheItem<unknown> | null = null;
      
      // 从内存删�?      const memoryItem = this.memoryCache.get(key);
      if (memoryItem) {
        removedItem = memoryItem;
        this.memoryCache.delete(key);
        this.updateCacheSizeStats(-memoryItem.metadata.size, true);
        this.updateItemCountStats(false);
      }
      
      // 从磁盘删�?      const diskPath = this.getDiskCachePath(key);
      if (this.fileUtil.fileExists(diskPath)) {
        if (!removedItem) {
          removedItem = await this.getFromDisk(key);
        }
        await this.fileUtil.deleteFile(diskPath);
        this.updateCacheSizeStats(-(removedItem?.metadata.size || 0), false);
        this.updateItemCountStats(false);
      }
      
      if (removedItem) {
        // 构建事件
        const event: CacheChangeEvent = {
          key,
          type: removedItem.metadata.type,
          metadata: removedItem.metadata
        };
        
        // 处理事件
        if (this.batchOperation) {
          this.pendingEvents.push(event);
        } else {
          // 发布缓存删除事件
          this.eventBus.emit(CacheEventType.CACHE_REMOVED, event);
          
          // 更新统计信息
          this.updateStatistics();
        }
        
        this.logger.debug(`Cache removed: ${key}`);
      }
    } catch (error) {
      this.Logger.error(`Failed to remove cache: ${key}`, error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error } instanceof Error ? { key, error } instanceof Error ? { key, error } : new Error(String({ key, error } : new Error(String({ key, error } instanceof Error ? { key, error } : new Error(String({ key, error })))))));
      
      throw error;
    }
  }

  /**
   * 清空缓存
   * @param options 清空选项
   */
  public async clearCache(options?: {
    type?: CacheType;        // 缓存类型
    priority?: CachePriority; // 优先级阈�?    tags?: string[];         // 标签过滤
  }): Promise<void> {
    if (!this.initialized) {
      return;
    }
    
    try {
      const keysToRemove: string[] = [];
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries()) {
        if (this.shouldRemoveItem(item.metadata, options)) {
          keysToRemove.push(key);
        }
      }
      
      // 删除内存缓存
      for (const key of keysToRemove) {
        const item = this.memoryCache.get(key);
        if (item) {
          this.updateCacheSizeStats(-item.metadata.size, true);
          this.updateItemCountStats(false);
        }
        this.memoryCache.delete(key);
      }
      
      // 删除磁盘缓存
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
      
      // 发布缓存清空事件
      if (!this.batchOperation) {
        this.eventBus.emit(CacheEventType.CACHE_CLEARED, {
          type: options?.type,
          priority: options?.priority,
          tags: options?.tags
        });
        
        // 更新统计信息
        this.updateStatistics();
      }
      
      this.logger.info(`Cache cleared`, {
        memoryItemsRemoved: keysToRemove.length,
        options
      });
    } catch (error) {
      this.Logger.error('Failed to clear cache', error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error })))))));
      
      throw error;
    }
  }

  /**
   * 获取缓存统计信息
   */
  public getStatistics(): CacheStatistics {
    return { ...this.cacheStatistics };
  }

  /**
   * 开始批量操�?   */
  public startBatchOperation(): void {
    this.batchOperation = true;
    this.pendingEvents = [];
  }

  /**
   * 结束批量操作
   */
  public async endBatchOperation(): Promise<void> {
    this.batchOperation = false;
    
    // 发布所有待处理事件
    for (const event of this.pendingEvents) {
      // 根据事件类型发布相应事件
      // 这里简化处理，实际应根据事件类型区�?      this.eventBus.emit(CacheEventType.CACHE_UPDATED, event);
    }
    
    this.pendingEvents = [];
    
    // 更新统计信息
    this.updateStatistics();
  }

  /**
   * 搜索缓存
   * @param params 搜索参数
   */
  public async searchCache(params: CacheSearchParams): Promise<CacheItem<unknown>[]> {
    if (!this.initialized) {
      return [];
    }
    
    try {
      const results: CacheItem<unknown>[] = [];
      
      // 搜索内存缓存
      for (const item of this.memoryCache.values()) {
        if (this.matchesSearchCriteria(item.metadata, params)) {
          results.push(item);
        }
      }
      
      // 搜索磁盘缓存
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
      
      // 排序结果
      if (params.sortBy) {
        results.sort((a, b) => {
          const aValue = this.getSortValue(a.metadata, params.sortBy!);
          const bValue = this.getSortValue(b.metadata, params.sortBy!);
          
          if (aValue < bValue) return params.sortOrder === 'asc' ? -1 : 1;
          if (aValue > bValue) return params.sortOrder === 'asc' ? 1 : -1;
          return 0;
        });
      }
      
      // 限制结果数量
      if (params.limit && results.length > params.limit) {
        results.splice(params.limit);
      }
      
      return results;
    } catch (error) {
      this.Logger.error('Failed to search cache', error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error })))))));
      
      throw error;
    }
  }

  /**
   * 关闭缓存仓库
   */
  public async shutdown(): Promise<void> {
    if (!this.initialized) {
      return;
    }
    
    try {
      // 停止定时清理
      this.stopPeriodicCleanup();
      
      // 保存缓存统计信息
      await this.saveCacheStatistics();
      
      // 清空内存缓存
      this.memoryCache.clear();
      
      this.initialized = false;
      this.logger.info('CacheRepository shutdown');
    } catch (error) {
      this.Logger.error('Failed to shutdown CacheRepository', error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error } instanceof Error ? { error } instanceof Error ? { error } : new Error(String({ error } : new Error(String({ error } instanceof Error ? { error } : new Error(String({ error })))))));
      
      throw error;
    }
  }

  // 私有辅助方法

  /**
   * 加载缓存统计信息
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
   * 保存缓存统计信息
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
   * 启动定时清理
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
   * 停止定时清理
   */
  private stopPeriodicCleanup(): void {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
      this.cleanupTimer = null;
    }
  }

  /**
   * 检查缓存是否过�?   */
  private isExpired(metadata: CacheMetadata): boolean {
    return metadata.expiry > 0 && Date.now() > metadata.expiry;
  }

  /**
   * 计算对象大小
   */
  private calculateSize(value: Record<string, string | number | boolean | null>): number {
    try {
      const jsonString = JSON.stringify(value);
      return new Blob([jsonString]).size;
    } catch {
      return 1024; // 默认大小
    }
  }

  /**
   * 检查缓存大小限�?   */
  private checkCacheSizeLimit(newSize: number): boolean {
    const totalSize = this.cacheStatistics.memorySize + this.cacheStatistics.diskSize;
    return totalSize + newSize <= this.cacheConfig.maxSize;
  }

  /**
   * 更新缓存大小统计
   */
  private updateCacheSizeStats(sizeDelta: number, isMemory: boolean): void {
    if (isMemory) {
      this.cacheStatistics.memorySize += sizeDelta;
    } else {
      this.cacheStatistics.diskSize += sizeDelta;
    }
    
    // 发布大小变更事件
    if (!this.batchOperation) {
      this.eventBus.emit(CacheEventType.CACHE_SIZE_CHANGED, {
        memorySize: this.cacheStatistics.memorySize,
        diskSize: this.cacheStatistics.diskSize,
        totalSize: this.cacheStatistics.memorySize + this.cacheStatistics.diskSize
      });
    }
  }

  /**
   * 更新缓存项数量统�?   */
  private updateItemCountStats(isMemory: boolean): void {
    if (isMemory) {
      this.cacheStatistics.memoryItems = this.memoryCache.size;
    } else {
      // 磁盘项数量需要扫描文件系统，这里简化处�?      this.cacheStatistics.diskItems = Math.max(0, this.cacheStatistics.diskItems);
    }
  }

  /**
   * 更新统计信息
   */
  private updateStatistics(): void {
    if (!this.batchOperation) {
      this.eventBus.emit(CacheEventType.CACHE_STATISTICS_UPDATED, {
        ...this.cacheStatistics
      });
    }
  }

  /**
   * 获取磁盘缓存路径
   */
  private getDiskCachePath(key: string): string {
    if (!this.cacheDirectory) {
      throw new Error('Cache directory not set');
    }
    
    // 对key进行安全编码
    const safeKey = encodeURIComponent(key).replace(/%/g, '_');
    return `${this.cacheDirectory}/${safeKey}.json`;
  }

  /**
   * 存储到磁�?   */
  private async storeToDisk<T>(key: string, item: CacheItem<T>): Promise<void> {
    if (!this.cacheDirectory) {
      return;
    }
    
    const filePath = this.getDiskCachePath(key);
    const content = JSON.stringify(item, null, 2);
    
    await this.fileUtil.writeFile(filePath, content);
  }

  /**
   * 从磁盘获�?   */
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
      
      // 删除损坏的文�?      await this.fileUtil.deleteFile(filePath);
      
      return null;
    }
  }

  /**
   * 清理过期缓存
   */
  private async cleanupExpiredCache(): Promise<void> {
    try {
      const expiredKeys: string[] = [];
      
      // 检查内存缓�?      for (const [key, item] of this.memoryCache.entries()) {
        if (this.isExpired(item.metadata)) {
          expiredKeys.push(key);
        }
      }
      
      // 删除过期缓存
      for (const key of expiredKeys) {
        await this.removeCache(key);
      }
      
      // 检查磁盘缓�?      if (this.cacheDirectory) {
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
   * 根据大小清理缓存
   */
  private async cleanupCacheBySize(): Promise<void> {
    try {
      const totalSize = this.cacheStatistics.memorySize + this.cacheStatistics.diskSize;
      
      if (totalSize <= this.cacheConfig.maxSize) {
        return;
      }
      
      const targetReduction = totalSize - this.cacheConfig.maxSize * 0.9; // 清理�?0%容量
      
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
   * 清理缓存
   */
  private async cleanupCache(options: CacheCleanupOptions): Promise<void> {
    try {
      const itemsToRemove: Array<{key: string, metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( instanceof Error ? metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries( : new Error(String(metadata: CacheMetadata}> = [];
      let totalSizeToRemove = 0;
      
      // 收集要删除的缓存�?      for (const [key, item] of this.memoryCache.entries()))))))) {
        if (item.metadata.priority <= (options.priorityThreshold || CachePriority.LOW)) {
          itemsToRemove.push({ key, metadata: item.metadata });
          totalSizeToRemove += item.metadata.size;
          
          if (totalSizeToRemove >= options.targetSizeReduction) {
            break;
          }
        }
      }
      
      // 如果内存缓存不够，检查磁盘缓�?      if (totalSizeToRemove < options.targetSizeReduction && this.cacheDirectory) {
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
      
      // 删除缓存�?      for (const { key } of itemsToRemove) {
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
   * 检查是否应该删除缓存项
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
    // 检查类�?    if (options?.type && metadata.type !== options.type) {
      return false;
    }
    
    // 检查优先级
    if (options?.priority && metadata.priority > options.priority) {
      return false;
    }
    
    // 检查标�?    if (options?.tags && options.tags.length > 0) {
      const hasMatchingTag = options.tags.some(tag => metadata.tags.includes(tag));
      if (!hasMatchingTag) {
        return false;
      }
    }
    
    return true;
  }

  /**
   * 检查是否匹配搜索条�?   */
  private matchesSearchCriteria(metadata: CacheMetadata, params: CacheSearchParams): boolean {
    // 检查类�?    if (params.type && metadata.type !== params.type) {
      return false;
    }
    
    // 检查优先级
    if (params.priority && metadata.priority !== params.priority) {
      return false;
    }
    
    // 检查标�?    if (params.tags && params.tags.length > 0) {
      const hasMatchingTag = params.tags.some(tag => metadata.tags.includes(tag));
      if (!hasMatchingTag) {
        return false;
      }
    }
    
    // 检查创建时间范�?    if (params.createdAfter && metadata.createdAt < params.createdAfter) {
      return false;
    }
    
    if (params.createdBefore && metadata.createdAt > params.createdBefore) {
      return false;
    }
    
    // 检查访问时间范�?    if (params.accessedAfter && metadata.lastAccessedAt < params.accessedAfter) {
      return false;
    }
    
    if (params.accessedBefore && metadata.lastAccessedAt > params.accessedBefore) {
      return false;
    }
    
    // 检查过期状�?    if (params.expiredOnly && !this.isExpired(metadata)) {
      return false;
    }
    
    if (params.nonExpiredOnly && this.isExpired(metadata)) {
      return false;
    }
    
    return true;
  }

  /**
   * 获取排序�?   */
  private getSortValue(metadata: CacheMetadata, sortBy: keyof CacheMetadata): number | string {
    const value = metadata[sortBy];
    
    if (typeof value === 'number' || typeof value === 'string') {
      return value;
    }
    
    return 0;
  }
}


