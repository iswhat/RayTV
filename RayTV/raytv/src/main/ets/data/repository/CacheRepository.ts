// CacheRepository - 缓存仓库类
// 负责管理应用程序的缓存数据，提供统一的缓存读写和管理接口

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
export interface CacheChangeEvent<T = any> {
  key: string;          // 缓存键
  type: CacheType;      // 缓存类型
  value?: T;            // 缓存值（添加/更新时）
  metadata?: CacheMetadata; // 缓存元数据
}

/**
 * 缓存仓库类
 */
export class CacheRepository {
  private static instance: CacheRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private fileUtil = FileUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private formatUtil = FormatUtil.getInstance();
  
  // 内存缓存
  private memoryCache: Map<string, CacheItem<any>> = new Map();
  
  // 缓存配置
  private cacheConfig: CacheConfig = {
    maxSize: 512 * 1024 * 1024, // 512MB
    defaultExpiry: 3600 * 1000, // 1小时
    cleanupInterval: 300000,    // 5分钟
    memoryLimit: 64 * 1024 * 1024, // 64MB
    diskLimit: 448 * 1024 * 1024,  // 448MB
    evictionPolicy: 'LRU'      // 最近最少使用策略
  };
  
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
  
  // 定时清理器
  private cleanupTimer: number | null = null;
  
  // 是否已初始化
  private initialized: boolean = false;
  
  // 批量操作标志
  private batchOperation: boolean = false;
  private pendingEvents: CacheChangeEvent[] = [];

  /**
   * 私有构造函数
   */
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
   * 初始化缓存仓库
   * @param config 缓存配置
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
      this.logger.error('Failed to initialize CacheRepository', error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error });
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用退出事件，保存统计信息
    this.eventBus.on('app:exit', async () => {
      await this.shutdown();
    });
  }

  /**
   * 添加或更新缓存
   * @param key 缓存键
   * @param value 缓存值
   * @param options 缓存选项
   */
  public async setCache<T>(key: string, value: T, options?: {
    expiry?: number;          // 过期时间（毫秒）
    type?: CacheType;         // 缓存类型
    priority?: CachePriority; // 优先级
    policy?: CachePolicy;     // 缓存策略
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
      
      // 创建缓存元数据
      const metadata: CacheMetadata = {
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
      
      // 创建缓存项
      const cacheItem: CacheItem<T> = {
        value,
        metadata
      };
      
      // 检查缓存大小限制
      if (!this.checkCacheSizeLimit(metadata.size)) {
        // 尝试清理空间
        await this.cleanupCache({
          targetSizeReduction: metadata.size,
          priorityThreshold: priority
        });
        
        // 再次检查
        if (!this.checkCacheSizeLimit(metadata.size)) {
          this.logger.warn(`Cache size limit exceeded, cannot store item: ${key}`);
          throw new Error('Cache size limit exceeded');
        }
      }
      
      // 存储到内存
      if (cacheType === CacheType.MEMORY || cacheType === CacheType.MEMORY_DISK) {
        // 移除旧缓存项（如果存在）
        const oldItem = this.memoryCache.get(key);
        if (oldItem) {
          this.updateCacheSizeStats(-oldItem.metadata.size, true);
        }
        
        this.memoryCache.set(key, cacheItem);
        this.updateCacheSizeStats(metadata.size, true);
        this.updateItemCountStats(true);
      }
      
      // 存储到磁盘
      if (cacheType === CacheType.DISK || cacheType === CacheType.MEMORY_DISK) {
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
      this.logger.error(`Failed to set cache: ${key}`, error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error });
      
      throw error;
    }
  }

  /**
   * 获取缓存
   * @param key 缓存键
   * @param options 获取选项
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
      
      // 优先从内存获取
      let cacheItem = this.memoryCache.get(key);
      let isFromMemory = true;
      
      // 如果内存中没有，从磁盘获取
      if (!cacheItem && this.cacheDirectory) {
        cacheItem = await this.retrieveFromDisk<T>(key);
        isFromMemory = false;
      }
      
      // 缓存未命中
      if (!cacheItem) {
        this.cacheStatistics.misses++;
        this.logger.debug(`Cache miss: ${key}`);
        return null;
      }
      
      // 检查是否过期
      const now = Date.now();
      if (!options?.ignoreExpiry && cacheItem.metadata.expiry > 0 && now > cacheItem.metadata.expiry) {
        // 缓存已过期
        this.cacheStatistics.expirations++;
        this.cacheStatistics.misses++;
        
        // 异步删除过期缓存
        this.removeCache(key).catch(err => {
          this.logger.warn(`Failed to remove expired cache: ${key}`, err);
        });
        
        // 发布缓存过期事件
        this.eventBus.emit(CacheEventType.CACHE_EXPIRED, {
          key,
          type: cacheItem.metadata.type,
          metadata: cacheItem.metadata
        });
        
        this.logger.debug(`Cache expired: ${key}`);
        return null;
      }
      
      // 缓存命中
      this.cacheStatistics.hits++;
      
      // 更新访问时间
      if (options?.updateAccessTime !== false) {
        cacheItem.metadata.lastAccessedAt = now;
        
        // 如果是内存缓存，更新内存中的访问时间
        if (isFromMemory && 
            (cacheItem.metadata.type === CacheType.MEMORY || 
             cacheItem.metadata.type === CacheType.MEMORY_DISK)) {
          this.memoryCache.set(key, cacheItem);
        }
        
        // 如果是磁盘缓存，异步更新访问时间
        if (cacheItem.metadata.type === CacheType.DISK || 
            cacheItem.metadata.type === CacheType.MEMORY_DISK) {
          this.updateAccessTimeOnDisk(key, now).catch(err => {
            this.logger.warn(`Failed to update access time on disk: ${key}`, err);
          });
        }
      }
      
      this.logger.debug(`Cache hit: ${key}`);
      return cacheItem.value;
    } catch (error) {
      this.logger.error(`Failed to get cache: ${key}`, error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error });
      
      return null;
    }
  }

  /**
   * 移除缓存
   * @param key 缓存键
   */
  public async removeCache(key: string): Promise<void> {
    try {
      let removed = false;
      
      // 从内存移除
      const memoryItem = this.memoryCache.get(key);
      if (memoryItem) {
        this.memoryCache.delete(key);
        this.updateCacheSizeStats(-memoryItem.metadata.size, true);
        this.updateItemCountStats(false);
        removed = true;
      }
      
      // 从磁盘移除
      if (this.cacheDirectory) {
        const diskRemoved = await this.removeFromDisk(key);
        removed = removed || diskRemoved;
      }
      
      if (removed) {
        // 发布缓存移除事件
        this.eventBus.emit(CacheEventType.CACHE_REMOVED, {
          key,
          type: memoryItem?.metadata.type || CacheType.MEMORY
        });
        
        this.logger.debug(`Cache removed: ${key}`);
      }
    } catch (error) {
      this.logger.error(`Failed to remove cache: ${key}`, error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { key, error });
    }
  }

  /**
   * 批量移除缓存
   * @param keys 缓存键列表
   */
  public async batchRemoveCaches(keys: string[]): Promise<void> {
    try {
      this.beginBatchOperation();
      
      // 批量移除
      for (const key of keys) {
        await this.removeCache(key);
      }
      
      this.commitBatchOperation();
      
      this.logger.debug(`Batch removed ${keys.length} cache items`);
    } catch (error) {
      this.logger.error('Failed to batch remove caches', error as Error);
      throw error;
    } finally {
      this.endBatchOperation();
    }
  }

  /**
   * 清空所有缓存
   * @param options 清空选项
   */
  public async clearCache(options?: {
    type?: CacheType;    // 缓存类型
    olderThan?: number;  // 只清空指定时间之前的缓存（毫秒）
    tags?: string[];     // 只清空指定标签的缓存
  }): Promise<void> {
    try {
      // 清空内存缓存
      if (!options?.type || options.type === CacheType.MEMORY || options.type === CacheType.MEMORY_DISK) {
        const keysToRemove: string[] = [];
        
        this.memoryCache.forEach((item, key) => {
          if (this.shouldClearItem(item, options)) {
            keysToRemove.push(key);
          }
        });
        
        for (const key of keysToRemove) {
          const item = this.memoryCache.get(key);
          if (item) {
            this.memoryCache.delete(key);
            this.updateCacheSizeStats(-item.metadata.size, true);
          }
        }
        
        this.updateItemCountStats(false, keysToRemove.length);
      }
      
      // 清空磁盘缓存
      if (this.cacheDirectory && (!options?.type || options.type === CacheType.DISK || options.type === CacheType.MEMORY_DISK)) {
        await this.clearDiskCache(options);
      }
      
      // 发布缓存清空事件
      this.eventBus.emit(CacheEventType.CACHE_CLEARED, { options });
      
      // 更新统计信息
      await this.saveCacheStatistics();
      
      this.logger.info('Cache cleared', options);
    } catch (error) {
      this.logger.error('Failed to clear cache', error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error });
      
      throw error;
    }
  }

  /**
   * 检查缓存是否存在
   * @param key 缓存键
   * @param ignoreExpiry 是否忽略过期
   */
  public async hasCache(key: string, ignoreExpiry: boolean = false): Promise<boolean> {
    // 优先检查内存
    const memoryItem = this.memoryCache.get(key);
    if (memoryItem) {
      if (ignoreExpiry || memoryItem.metadata.expiry === 0 || Date.now() < memoryItem.metadata.expiry) {
        return true;
      }
    }
    
    // 检查磁盘
    if (this.cacheDirectory) {
      const exists = await this.diskCacheExists(key);
      if (exists) {
        if (ignoreExpiry) {
          return true;
        }
        
        // 读取元数据检查过期
        try {
          const metadata = await this.readMetadataFromDisk(key);
          if (metadata && (metadata.expiry === 0 || Date.now() < metadata.expiry)) {
            return true;
          }
        } catch (error) {
          this.logger.warn(`Failed to read cache metadata from disk: ${key}`, error as Error);
        }
      }
    }
    
    return false;
  }

  /**
   * 获取缓存元数据
   * @param key 缓存键
   */
  public async getCacheMetadata(key: string): Promise<CacheMetadata | null> {
    // 优先从内存获取
    const memoryItem = this.memoryCache.get(key);
    if (memoryItem) {
      return memoryItem.metadata;
    }
    
    // 从磁盘获取
    if (this.cacheDirectory) {
      try {
        return await this.readMetadataFromDisk(key);
      } catch (error) {
        this.logger.warn(`Failed to read cache metadata from disk: ${key}`, error as Error);
      }
    }
    
    return null;
  }

  /**
   * 搜索缓存
   * @param params 搜索参数
   */
  public async searchCache(params: CacheSearchParams): Promise<Array<{key: string; metadata: CacheMetadata}>> {
    const results: Array<{key: string; metadata: CacheMetadata}> = [];
    
    // 搜索内存缓存
    this.memoryCache.forEach((item, key) => {
      if (this.matchesSearchCriteria(key, item.metadata, params)) {
        results.push({ key, metadata: item.metadata });
      }
    });
    
    // 搜索磁盘缓存
    if (this.cacheDirectory) {
      const diskResults = await this.searchDiskCache(params);
      results.push(...diskResults);
    }
    
    // 排序结果
    if (params.sortBy) {
      results.sort((a, b) => {
        const aValue = a.metadata[params.sortBy as keyof CacheMetadata];
        const bValue = b.metadata[params.sortBy as keyof CacheMetadata];
        
        if (aValue < bValue) return params.sortOrder === 'desc' ? 1 : -1;
        if (aValue > bValue) return params.sortOrder === 'desc' ? -1 : 1;
        return 0;
      });
    }
    
    // 限制结果数量
    if (params.limit && params.limit > 0) {
      return results.slice(0, params.limit);
    }
    
    return results;
  }

  /**
   * 清理过期缓存
   * @param options 清理选项
   */
  public async cleanupCache(options?: CacheCleanupOptions): Promise<void> {
    try {
      const now = Date.now();
      const statsBefore = { ...this.cacheStatistics };
      
      // 清理内存缓存中的过期项
      const expiredKeys: string[] = [];
      
      this.memoryCache.forEach((item, key) => {
        // 检查是否过期
        if (item.metadata.expiry > 0 && now > item.metadata.expiry) {
          expiredKeys.push(key);
        }
      });
      
      for (const key of expiredKeys) {
        const item = this.memoryCache.get(key);
        if (item) {
          this.memoryCache.delete(key);
          this.updateCacheSizeStats(-item.metadata.size, true);
          this.cacheStatistics.expirations++;
        }
      }
      
      this.updateItemCountStats(false, expiredKeys.length);
      
      // 清理磁盘缓存中的过期项
      if (this.cacheDirectory) {
        await this.cleanupDiskCache(options);
      }
      
      // 如果需要减少缓存大小
      if (options?.targetSizeReduction) {
        await this.reduceCacheSize(options.targetSizeReduction, options.priorityThreshold);
      }
      
      // 保存统计信息
      await this.saveCacheStatistics();
      
      const statsAfter = { ...this.cacheStatistics };
      const sizeReduced = statsBefore.memorySize + statsBefore.diskSize - 
                         (statsAfter.memorySize + statsAfter.diskSize);
      
      this.logger.info('Cache cleanup completed', {
        expiredItems: expiredKeys.length,
        sizeReduced: this.formatUtil.formatFileSize(sizeReduced),
        currentSize: this.formatUtil.formatFileSize(statsAfter.memorySize + statsAfter.diskSize)
      });
    } catch (error) {
      this.logger.error('Failed to cleanup cache', error as Error);
      
      // 发布缓存错误事件
      this.eventBus.emit(CacheEventType.CACHE_ERROR, { error });
    }
  }

  /**
   * 获取缓存统计信息
   */
  public getCacheStatistics(): CacheStatistics {
    return { ...this.cacheStatistics };
  }

  /**
   * 更新缓存配置
   * @param config 新配置
   */
  public updateConfig(config: Partial<CacheConfig>): void {
    this.cacheConfig = { ...this.cacheConfig, ...config };
    
    // 重启定时清理
    this.restartPeriodicCleanup();
    
    this.logger.info('Cache config updated', {
      maxSize: this.formatUtil.formatFileSize(this.cacheConfig.maxSize),
      defaultExpiry: this.formatUtil.formatTime(this.cacheConfig.defaultExpiry),
      cleanupInterval: this.formatUtil.formatTime(this.cacheConfig.cleanupInterval)
    });
  }

  /**
   * 获取缓存配置
   */
  public getConfig(): CacheConfig {
    return { ...this.cacheConfig };
  }

  /**
   * 关闭缓存仓库
   */
  public async shutdown(): Promise<void> {
    try {
      // 停止定时清理
      this.stopPeriodicCleanup();
      
      // 保存统计信息
      await this.saveCacheStatistics();
      
      this.logger.info('CacheRepository shutdown');
    } catch (error) {
      this.logger.error('Failed to shutdown CacheRepository', error as Error);
    }
  }

  // 批量操作方法

  /**
   * 开始批量操作
   */
  public beginBatchOperation(): void {
    this.batchOperation = true;
    this.pendingEvents = [];
  }

  /**
   * 提交批量操作
   */
  public commitBatchOperation(): void {
    // 处理所有待处理的事件
    for (const event of this.pendingEvents) {
      const eventType = this.memoryCache.has(event.key) ? CacheEventType.CACHE_UPDATED : CacheEventType.CACHE_ADDED;
      this.eventBus.emit(eventType, event);
    }
    
    // 更新统计信息
    this.updateStatistics();
    
    this.logger.debug(`Batch operation committed: ${this.pendingEvents.length} events`);
  }

  /**
   * 结束批量操作
   */
  public endBatchOperation(): void {
    this.batchOperation = false;
    this.pendingEvents = [];
  }

  // 私有辅助方法

  /**
   * 计算值的大小（字节）
   * @param value 要计算大小的值
   */
  private calculateSize(value: unknown): number {
    try {
      const jsonString = JSON.stringify(value);
      // 简单估算，实际大小可能有所不同
      return new Blob([jsonString]).size;
    } catch (error) {
      this.logger.warn('Failed to calculate cache item size', error as Error);
      return 0;
    }
  }

  /**
   * 检查缓存大小限制
   * @param additionalSize 要添加的额外大小
   */
  private checkCacheSizeLimit(additionalSize: number): boolean {
    const currentSize = this.cacheStatistics.memorySize + this.cacheStatistics.diskSize;
    return currentSize + additionalSize <= this.cacheConfig.maxSize;
  }

  /**
   * 检查内存缓存大小限制
   * @param additionalSize 要添加的额外大小
   */
  private checkMemoryCacheLimit(additionalSize: number): boolean {
    return this.cacheStatistics.memorySize + additionalSize <= this.cacheConfig.memoryLimit;
  }

  /**
   * 检查磁盘缓存大小限制
   * @param additionalSize 要添加的额外大小
   */
  private checkDiskCacheLimit(additionalSize: number): boolean {
    return this.cacheStatistics.diskSize + additionalSize <= this.cacheConfig.diskLimit;
  }

  /**
   * 更新缓存大小统计
   * @param sizeDelta 大小变化量
   * @param isMemory 是否为内存缓存
   */
  private updateCacheSizeStats(sizeDelta: number, isMemory: boolean): void {
    if (isMemory) {
      this.cacheStatistics.memorySize = Math.max(0, this.cacheStatistics.memorySize + sizeDelta);
    } else {
      this.cacheStatistics.diskSize = Math.max(0, this.cacheStatistics.diskSize + sizeDelta);
    }
    
    // 发布缓存大小变更事件
    this.eventBus.emit(CacheEventType.CACHE_SIZE_CHANGED, {
      memorySize: this.cacheStatistics.memorySize,
      diskSize: this.cacheStatistics.diskSize,
      totalSize: this.cacheStatistics.memorySize + this.cacheStatistics.diskSize
    });
  }

  /**
   * 更新缓存项数量统计
   * @param added 是否添加（true）或移除（false）
   * @param count 数量
   */
  private updateItemCountStats(added: boolean, count: number = 1): void {
    const delta = added ? count : -count;
    this.cacheStatistics.memoryItems = Math.max(0, this.cacheStatistics.memoryItems + delta);
    
    // 注意：磁盘项的数量更新在磁盘操作中单独处理
  }

  /**
   * 更新缓存统计信息
   */
  private updateStatistics(): void {
    // 发布统计信息更新事件
    this.eventBus.emit(CacheEventType.CACHE_STATISTICS_UPDATED, this.getCacheStatistics());
  }

  /**
   * 加载缓存统计信息
   */
  private async loadCacheStatistics(): Promise<void> {
    try {
      if (this.cacheDirectory) {
        const statsPath = this.getStatisticsFilePath();
        if (await this.fileUtil.exists(statsPath)) {
          const statsContent = await this.fileUtil.readTextFile(statsPath);
          const savedStats = JSON.parse(statsContent);
          
          // 只更新特定字段，保留其他字段的当前值
          if (savedStats) {
            this.cacheStatistics.diskItems = savedStats.diskItems || 0;
            this.cacheStatistics.diskSize = savedStats.diskSize || 0;
          }
        }
      }
    } catch (error) {
      this.logger.warn('Failed to load cache statistics', error as Error);
    }
  }

  /**
   * 保存缓存统计信息
   */
  private async saveCacheStatistics(): Promise<void> {
    try {
      if (this.cacheDirectory) {
        const statsPath = this.getStatisticsFilePath();
        const statsToSave = {
          diskItems: this.cacheStatistics.diskItems,
          diskSize: this.cacheStatistics.diskSize,
          updatedAt: Date.now()
        };
        
        await this.fileUtil.writeTextFile(statsPath, JSON.stringify(statsToSave, null, 2));
      }
    } catch (error) {
      this.logger.warn('Failed to save cache statistics', error as Error);
    }
  }

  /**
   * 减少缓存大小
   * @param targetReduction 目标减少大小
   * @param priorityThreshold 优先级阈值
   */
  private async reduceCacheSize(targetReduction: number, priorityThreshold?: CachePriority): Promise<void> {
    let reducedSize = 0;
    
    // 先按优先级和最后访问时间排序内存缓存项
    const memoryItems = Array.from(this.memoryCache.entries())
      .filter(([_, item]) => !priorityThreshold || item.metadata.priority <= priorityThreshold)
      .sort((a, b) => {
        // 先按优先级排序
        if (a[1].metadata.priority !== b[1].metadata.priority) {
          return a[1].metadata.priority - b[1].metadata.priority;
        }
        // 再按最后访问时间排序（LRU策略）
        return a[1].metadata.lastAccessedAt - b[1].metadata.lastAccessedAt;
      });
    
    // 移除内存缓存项
    for (const [key, item] of memoryItems) {
      if (reducedSize >= targetReduction) {
        break;
      }
      
      this.memoryCache.delete(key);
      this.updateCacheSizeStats(-item.metadata.size, true);
      this.updateItemCountStats(false);
      this.cacheStatistics.evictions++;
      reducedSize += item.metadata.size;
      
      // 发布缓存移除事件
      this.eventBus.emit(CacheEventType.CACHE_REMOVED, {
        key,
        type: item.metadata.type,
        metadata: item.metadata
      });
    }
    
    // 如果还需要减少，清理磁盘缓存
    if (reducedSize < targetReduction && this.cacheDirectory) {
      const remainingReduction = targetReduction - reducedSize;
      const diskReduced = await this.reduceDiskCacheSize(remainingReduction, priorityThreshold);
      reducedSize += diskReduced;
    }
    
    this.logger.debug(`Cache size reduced by ${this.formatUtil.formatFileSize(reducedSize)}`);
  }

  /**
   * 减少磁盘缓存大小
   * @param targetReduction 目标减少大小
   * @param priorityThreshold 优先级阈值
   */
  private async reduceDiskCacheSize(targetReduction: number, priorityThreshold?: CachePriority): Promise<number> {
    // 这里应该实现磁盘缓存清理逻辑
    // 由于简化实现，这里只返回0
    return 0;
  }

  /**
   * 启动定时清理
   */
  private startPeriodicCleanup(): void {
    this.stopPeriodicCleanup();
    
    this.cleanupTimer = setInterval(() => {
      this.cleanupCache().catch(error => {
        this.logger.error('Periodic cache cleanup failed', error as Error);
      });
    }, this.cacheConfig.cleanupInterval);
    
    this.logger.debug(`Started periodic cache cleanup (interval: ${this.formatUtil.formatTime(this.cacheConfig.cleanupInterval)})`);
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
   * 重启定时清理
   */
  private restartPeriodicCleanup(): void {
    this.startPeriodicCleanup();
  }

  /**
   * 检查项是否应该被清空
   */
  private shouldClearItem(item: CacheItem<any>, options?: {olderThan?: number; tags?: string[]}): boolean {
    // 检查时间
    if (options?.olderThan) {
      const cutoffTime = Date.now() - options.olderThan;
      if (item.metadata.createdAt >= cutoffTime) {
        return false;
      }
    }
    
    // 检查标签
    if (options?.tags && options.tags.length > 0) {
      if (!item.metadata.tags || !item.metadata.tags.some(tag => options.tags?.includes(tag))) {
        return false;
      }
    }
    
    return true;
  }

  /**
   * 检查项是否匹配搜索条件
   */
  private matchesSearchCriteria(key: string, metadata: CacheMetadata, params: CacheSearchParams): boolean {
    // 检查键匹配
    if (params.keyPattern && !new RegExp(params.keyPattern).test(key)) {
      return false;
    }
    
    // 检查类型
    if (params.type && metadata.type !== params.type) {
      return false;
    }
    
    // 检查优先级
    if (params.minPriority && metadata.priority < params.minPriority) {
      return false;
    }
    
    // 检查时间范围
    if (params.createdAfter && metadata.createdAt < params.createdAfter) {
      return false;
    }
    if (params.createdBefore && metadata.createdAt > params.createdBefore) {
      return false;
    }
    if (params.accessedAfter && metadata.lastAccessedAt < params.accessedAfter) {
      return false;
    }
    if (params.accessedBefore && metadata.lastAccessedAt > params.accessedBefore) {
      return false;
    }
    
    // 检查标签
    if (params.tags && params.tags.length > 0) {
      if (!metadata.tags || !params.tags.every(tag => metadata.tags!.includes(tag))) {
        return false;
      }
    }
    
    // 检查过期状态
    if (params.onlyExpired) {
      const now = Date.now();
      if (metadata.expiry === 0 || now <= metadata.expiry) {
        return false;
      }
    }
    
    return true;
  }

  // 磁盘缓存相关方法

  /**
   * 获取缓存文件路径
   * @param key 缓存键
   */
  private getCacheFilePath(key: string): string {
    if (!this.cacheDirectory) {
      throw new Error('Cache directory not set');
    }
    
    // 简单的键转换为文件名
    const safeKey = key.replace(/[^a-zA-Z0-9._-]/g, '_');
    return `${this.cacheDirectory}/${safeKey}.cache`;
  }

  /**
   * 获取元数据文件路径
   * @param key 缓存键
   */
  private getMetadataFilePath(key: string): string {
    if (!this.cacheDirectory) {
      throw new Error('Cache directory not set');
    }
    
    const safeKey = key.replace(/[^a-zA-Z0-9._-]/g, '_');
    return `${this.cacheDirectory}/${safeKey}.meta`;
  }

  /**
   * 获取统计信息文件路径
   */
  private getStatisticsFilePath(): string {
    if (!this.cacheDirectory) {
      throw new Error('Cache directory not set');
    }
    
    return `${this.cacheDirectory}/cache_stats.json`;
  }

  /**
   * 存储到磁盘
   * @param key 缓存键
   * @param item 缓存项
   */
  private async storeToDisk<T>(key: string, item: CacheItem<T>): Promise<void> {
    if (!this.cacheDirectory) {
      throw new Error('Cache directory not set');
    }
    
    try {
      // 检查磁盘大小限制
      if (!this.checkDiskCacheLimit(item.metadata.size)) {
        await this.cleanupCache({
          targetSizeReduction: item.metadata.size,
          priorityThreshold: item.metadata.priority
        });
        
        if (!this.checkDiskCacheLimit(item.metadata.size)) {
          throw new Error('Disk cache size limit exceeded');
        }
      }
      
      const cachePath = this.getCacheFilePath(key);
      const metadataPath = this.getMetadataFilePath(key);
      
      // 存储缓存数据
      await this.fileUtil.writeTextFile(cachePath, JSON.stringify(item.value));
      
      // 存储元数据
      await this.fileUtil.writeTextFile(metadataPath, JSON.stringify(item.metadata));
      
      // 更新统计信息
      this.updateCacheSizeStats(item.metadata.size, false);
      this.cacheStatistics.diskItems++;
    } catch (error) {
      this.logger.error(`Failed to store cache to disk: ${key}`, error as Error);
      throw error;
    }
  }

  /**
   * 从磁盘检索
   * @param key 缓存键
   */
  private async retrieveFromDisk<T>(key: string): Promise<CacheItem<T> | null> {
    if (!this.cacheDirectory) {
      return null;
    }
    
    try {
      const cachePath = this.getCacheFilePath(key);
      const metadataPath = this.getMetadataFilePath(key);
      
      if (await this.fileUtil.exists(cachePath) && await this.fileUtil.exists(metadataPath)) {
        // 读取缓存数据
        const dataContent = await this.fileUtil.readTextFile(cachePath);
        const value = JSON.parse(dataContent) as T;
        
        // 读取元数据
        const metadataContent = await this.fileUtil.readTextFile(metadataPath);
        const metadata = JSON.parse(metadataContent) as CacheMetadata;
        
        return {
          value,
          metadata
        };
      }
      
      return null;
    } catch (error) {
      this.logger.warn(`Failed to retrieve cache from disk: ${key}`, error as Error);
      
      // 如果读取失败，尝试清理损坏的缓存文件
      await this.removeFromDisk(key).catch(err => {
        this.logger.warn(`Failed to remove corrupted cache files: ${key}`, err);
      });
      
      return null;
    }
  }

  /**
   * 从磁盘移除
   * @param key 缓存键
   */
  private async removeFromDisk(key: string): Promise<boolean> {
    if (!this.cacheDirectory) {
      return false;
    }
    
    try {
      const cachePath = this.getCacheFilePath(key);
      const metadataPath = this.getMetadataFilePath(key);
      
      let removed = false;
      
      // 尝试读取元数据以获取大小
      let metadataSize = 0;
      try {
        if (await this.fileUtil.exists(metadataPath)) {
          const metadataContent = await this.fileUtil.readTextFile(metadataPath);
          const metadata = JSON.parse(metadataContent) as CacheMetadata;
          metadataSize = metadata.size;
        }
      } catch (error) {
        this.logger.warn(`Failed to read metadata for removal: ${key}`, error as Error);
      }
      
      // 删除缓存文件
      if (await this.fileUtil.exists(cachePath)) {
        await this.fileUtil.deleteFile(cachePath);
        removed = true;
      }
      
      // 删除元数据文件
      if (await this.fileUtil.exists(metadataPath)) {
        await this.fileUtil.deleteFile(metadataPath);
        removed = true;
      }
      
      if (removed && metadataSize > 0) {
        this.updateCacheSizeStats(-metadataSize, false);
        this.cacheStatistics.diskItems = Math.max(0, this.cacheStatistics.diskItems - 1);
      }
      
      return removed;
    } catch (error) {
      this.logger.warn(`Failed to remove cache from disk: ${key}`, error as Error);
      return false;
    }
  }

  /**
   * 读取磁盘元数据
   * @param key 缓存键
   */
  private async readMetadataFromDisk(key: string): Promise<CacheMetadata | null> {
    if (!this.cacheDirectory) {
      return null;
    }
    
    try {
      const metadataPath = this.getMetadataFilePath(key);
      
      if (await this.fileUtil.exists(metadataPath)) {
        const metadataContent = await this.fileUtil.readTextFile(metadataPath);
        return JSON.parse(metadataContent) as CacheMetadata;
      }
      
      return null;
    } catch (error) {
      this.logger.warn(`Failed to read metadata from disk: ${key}`, error as Error);
      return null;
    }
  }

  /**
   * 更新磁盘访问时间
   * @param key 缓存键
   * @param timestamp 时间戳
   */
  private async updateAccessTimeOnDisk(key: string, timestamp: number): Promise<void> {
    if (!this.cacheDirectory) {
      return;
    }
    
    try {
      const metadataPath = this.getMetadataFilePath(key);
      
      if (await this.fileUtil.exists(metadataPath)) {
        const metadataContent = await this.fileUtil.readTextFile(metadataPath);
        const metadata = JSON.parse(metadataContent) as CacheMetadata;
        
        metadata.lastAccessedAt = timestamp;
        
        await this.fileUtil.writeTextFile(metadataPath, JSON.stringify(metadata));
      }
    } catch (error) {
      this.logger.warn(`Failed to update access time on disk: ${key}`, error as Error);
    }
  }

  /**
   * 检查磁盘缓存是否存在
   * @param key 缓存键
   */
  private async diskCacheExists(key: string): Promise<boolean> {
    if (!this.cacheDirectory) {
      return false;
    }
    
    const cachePath = this.getCacheFilePath(key);
    return await this.fileUtil.exists(cachePath);
  }

  /**
   * 清空磁盘缓存
   * @param options 清空选项
   */
  private async clearDiskCache(options?: {olderThan?: number; tags?: string[]}): Promise<void> {
    // 简化实现，实际应该遍历所有磁盘缓存文件并清理符合条件的
  }

  /**
   * 清理磁盘缓存
   * @param options 清理选项
   */
  private async cleanupDiskCache(options?: CacheCleanupOptions): Promise<void> {
    // 简化实现，实际应该实现详细的磁盘缓存清理逻辑
  }

  /**
   * 搜索磁盘缓存
   * @param params 搜索参数
   */
  private async searchDiskCache(params: CacheSearchParams): Promise<Array<{key: string; metadata: CacheMetadata}>> {
    // 简化实现，返回空数组
    return [];
  }
}

// 导出默认实例
export default CacheRepository.getInstance();