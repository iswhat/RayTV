// CacheService - 缓存服务工具类
// 提供统一的缓存管理功能，支持内存缓存、磁盘缓存等多种缓存方式

import { Logger } from './Logger';
import { StorageUtil } from './StorageUtil';
import { FileUtil } from './FileUtil';
import { FormatUtil } from './FormatUtil';
import { LocalStorageType } from '../data/model/LocalModel';
import { CacheType, CacheStrategy, CachePriority, CacheItem, CacheMetadata, CacheConfig, CacheStatistics, CacheCleanupOptions, CacheSearchParams } from '../data/model/CacheModel';

/**
 * 缓存条目类
 */
class CacheEntry<T = any> implements CacheItem<T> {
  key: string;
  value: T;
  type: CacheType;
  metadata: CacheMetadata;
  expiryTime?: number;
  priority: CachePriority;
  lastAccessTime: number;
  accessCount: number;

  /**
   * 构造函数
   * @param key 缓存键
   * @param value 缓存值
   * @param options 缓存选项
   */
  constructor(key: string, value: T, options: Partial<CacheItem<T>> = {}) {
    this.key = key;
    this.value = value;
    this.type = options.type || CacheType.MEMORY;
    this.metadata = {
      ...options.metadata,
      createdAt: options.metadata?.createdAt || Date.now(),
      updatedAt: Date.now(),
      size: options.metadata?.size || 0
    };
    this.expiryTime = options.expiryTime;
    this.priority = options.priority || CachePriority.NORMAL;
    this.lastAccessTime = Date.now();
    this.accessCount = 0;
  }

  /**
   * 获取条目的大小（字节）
   */
  getSize(): number {
    if (this.metadata.size > 0) {
      return this.metadata.size;
    }
    
    try {
      const serialized = JSON.stringify(this.value);
      // 估算字符串的字节大小
      return new Blob([serialized]).size;
    } catch (error) {
      return 0;
    }
  }

  /**
   * 检查是否已过期
   */
  isExpired(): boolean {
    if (this.expiryTime === undefined) {
      return false;
    }
    return Date.now() > this.expiryTime;
  }

  /**
   * 更新访问信息
   */
  updateAccess(): void {
    this.lastAccessTime = Date.now();
    this.accessCount++;
    this.metadata.updatedAt = Date.now();
  }

  /**
   * 序列化条目
   */
  serialize(): string {
    try {
      return JSON.stringify({
        key: this.key,
        value: this.value,
        type: this.type,
        metadata: this.metadata,
        expiryTime: this.expiryTime,
        priority: this.priority,
        lastAccessTime: this.lastAccessTime,
        accessCount: this.accessCount
      });
    } catch (error) {
      throw new Error(`Failed to serialize cache entry: ${error}`);
    }
  }

  /**
   * 反序列化条目
   * @param data 序列化的数据
   */
  static deserialize<T = any>(data: string): CacheEntry<T> {
    try {
      const parsed = JSON.parse(data);
      const entry = new CacheEntry<T>(parsed.key, parsed.value, {
        type: parsed.type,
        metadata: parsed.metadata,
        expiryTime: parsed.expiryTime,
        priority: parsed.priority
      });
      entry.lastAccessTime = parsed.lastAccessTime;
      entry.accessCount = parsed.accessCount;
      return entry;
    } catch (error) {
      throw new Error(`Failed to deserialize cache entry: ${error}`);
    }
  }
}

/**
 * 缓存服务类
 */
export class CacheService {
  private static instance: CacheService;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private fileUtil = FileUtil.getInstance();
  
  // 内存缓存
  private memoryCache: Map<string, CacheEntry> = new Map();
  // 缓存配置
  private config: CacheConfig = {
    memoryCacheSize: 1024 * 1024 * 50, // 50MB
    diskCacheSize: 1024 * 1024 * 500,  // 500MB
    defaultExpiry: 3600000,           // 1小时
    cleanInterval: 300000             // 5分钟
  };
  // 缓存统计信息
  private statistics: CacheStatistics = {
    totalItems: 0,
    memoryItems: 0,
    diskItems: 0,
    memorySize: 0,
    diskSize: 0,
    hitCount: 0,
    missCount: 0,
    errorCount: 0
  };
  // 清理定时器
  private cleanupTimer: number | null = null;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('CacheService initialized');
    this.startPeriodicCleanup();
  }

  /**
   * 获取CacheService单例实例
   */
  public static getInstance(): CacheService {
    if (!CacheService.instance) {
      CacheService.instance = new CacheService();
    }
    return CacheService.instance;
  }

  /**
   * 初始化缓存服务
   * @param config 缓存配置
   */
  public async initialize(config: Partial<CacheConfig> = {}): Promise<void> {
    try {
      this.logger.info('Initializing cache service with config:', config);
      
      // 更新配置
      this.config = { ...this.config, ...config };
      
      // 加载持久化缓存（如果有）
      await this.loadPersistedCache();
      
      this.logger.info('Cache service initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize cache service', error as Error);
      this.statistics.errorCount++;
    }
  }

  /**
   * 设置缓存
   * @param key 缓存键
   * @param value 缓存值
   * @param options 缓存选项
   */
  public async set<T = any>(key: string, value: T, options: Partial<CacheItem<T>> = {}): Promise<void> {
    try {
      this.logger.debug(`Setting cache: ${key}`);
      
      // 计算过期时间
      let expiryTime: number | undefined;
      if (options.expiryTime) {
        expiryTime = options.expiryTime;
      } else if (options.ttl) {
        expiryTime = Date.now() + options.ttl;
      } else if (this.config.defaultExpiry) {
        expiryTime = Date.now() + this.config.defaultExpiry;
      }

      // 创建缓存条目
      const entry = new CacheEntry<T>(key, value, {
        type: options.type || CacheType.MEMORY,
        metadata: options.metadata || {},
        expiryTime,
        priority: options.priority || CachePriority.NORMAL
      });

      // 根据缓存类型进行存储
      if (entry.type === CacheType.MEMORY || entry.type === CacheType.BOTH) {
        this.storeInMemory(entry);
      }
      
      if (entry.type === CacheType.DISK || entry.type === CacheType.BOTH) {
        await this.storeOnDisk(entry);
      }

      // 更新统计信息
      this.updateStatistics();
      
      this.logger.debug(`Cache set successfully: ${key}`);
    } catch (error) {
      this.logger.error(`Failed to set cache: ${key}`, error as Error);
      this.statistics.errorCount++;
      throw error;
    }
  }

  /**
   * 获取缓存
   * @param key 缓存键
   * @param defaultValue 默认值
   */
  public async get<T = any>(key: string, defaultValue?: T): Promise<T | undefined> {
    try {
      this.logger.debug(`Getting cache: ${key}`);
      
      // 首先从内存缓存获取
      let entry = this.memoryCache.get(key);
      
      // 如果内存中没有，尝试从磁盘获取
      if (!entry) {
        entry = await this.getFromDisk(key);
        
        // 如果从磁盘获取到了，加载到内存
        if (entry && !entry.isExpired()) {
          this.storeInMemory(entry);
        }
      }
      
      // 检查是否过期
      if (entry?.isExpired()) {
        this.logger.debug(`Cache expired: ${key}`);
        await this.remove(key);
        this.statistics.missCount++;
        return defaultValue;
      }
      
      if (entry) {
        entry.updateAccess();
        this.statistics.hitCount++;
        this.logger.debug(`Cache hit: ${key}`);
        return entry.value as T;
      } else {
        this.statistics.missCount++;
        this.logger.debug(`Cache miss: ${key}`);
        return defaultValue;
      }
    } catch (error) {
      this.logger.error(`Failed to get cache: ${key}`, error as Error);
      this.statistics.errorCount++;
      return defaultValue;
    }
  }

  /**
   * 检查缓存是否存在
   * @param key 缓存键
   */
  public async has(key: string): Promise<boolean> {
    try {
      // 先检查内存
      if (this.memoryCache.has(key)) {
        const entry = this.memoryCache.get(key)!;
        if (!entry.isExpired()) {
          return true;
        }
      }
      
      // 再检查磁盘
      const diskEntry = await this.getFromDisk(key);
      return !!diskEntry && !diskEntry.isExpired();
    } catch (error) {
      this.logger.error(`Failed to check cache existence: ${key}`, error as Error);
      this.statistics.errorCount++;
      return false;
    }
  }

  /**
   * 删除缓存
   * @param key 缓存键
   */
  public async remove(key: string): Promise<void> {
    try {
      this.logger.debug(`Removing cache: ${key}`);
      
      // 从内存中删除
      if (this.memoryCache.has(key)) {
        this.memoryCache.delete(key);
      }
      
      // 从磁盘中删除
      await this.storageUtil.remove(`cache_${key}`, LocalStorageType.TEMPORARY);
      
      // 更新统计信息
      this.updateStatistics();
      
      this.logger.debug(`Cache removed successfully: ${key}`);
    } catch (error) {
      this.logger.error(`Failed to remove cache: ${key}`, error as Error);
      this.statistics.errorCount++;
    }
  }

  /**
   * 清空所有缓存
   * @param type 缓存类型
   */
  public async clear(type?: CacheType): Promise<void> {
    try {
      this.logger.info(`Clearing cache${type ? ` of type ${type}` : ''}`);
      
      if (!type || type === CacheType.MEMORY || type === CacheType.BOTH) {
        this.memoryCache.clear();
      }
      
      if (!type || type === CacheType.DISK || type === CacheType.BOTH) {
        // 清空磁盘缓存
        await this.clearDiskCache();
      }
      
      // 重置统计信息
      this.resetStatistics();
      
      this.logger.info(`Cache cleared successfully${type ? ` for type ${type}` : ''}`);
    } catch (error) {
      this.logger.error(`Failed to clear cache`, error as Error);
      this.statistics.errorCount++;
    }
  }

  /**
   * 搜索缓存
   * @param params 搜索参数
   */
  public async search<T = any>(params: CacheSearchParams): Promise<CacheItem<T>[]> {
    try {
      this.logger.debug('Searching cache with params:', params);
      
      let results: CacheItem<T>[] = [];
      
      // 先从内存中搜索
      const memoryResults = this.searchInMemory(params);
      results = [...results, ...memoryResults];
      
      // 再从磁盘中搜索
      const diskResults = await this.searchOnDisk(params);
      results = [...results, ...diskResults];
      
      // 去重
      const uniqueResults = this.removeDuplicates(results);
      
      // 排序
      if (params.sortBy) {
        this.sortResults(uniqueResults, params.sortBy, params.sortOrder);
      }
      
      // 分页
      if (params.limit || params.offset) {
        const offset = params.offset || 0;
        const limit = params.limit || uniqueResults.length;
        return uniqueResults.slice(offset, offset + limit);
      }
      
      return uniqueResults;
    } catch (error) {
      this.logger.error('Failed to search cache', error as Error);
      this.statistics.errorCount++;
      return [];
    }
  }

  /**
   * 获取缓存统计信息
   */
  public getStatistics(): CacheStatistics {
    this.updateStatistics();
    return { ...this.statistics };
  }

  /**
   * 设置缓存配置
   * @param config 缓存配置
   */
  public setConfig(config: Partial<CacheConfig>): void {
    this.logger.info('Updating cache config:', config);
    this.config = { ...this.config, ...config };
  }

  /**
   * 获取缓存配置
   */
  public getConfig(): CacheConfig {
    return { ...this.config };
  }

  /**
   * 清理过期缓存
   * @param options 清理选项
   */
  public async cleanup(options?: CacheCleanupOptions): Promise<void> {
    try {
      this.logger.info('Performing cache cleanup', options);
      
      // 清理内存缓存
      this.cleanupMemoryCache(options);
      
      // 清理磁盘缓存
      await this.cleanupDiskCache(options);
      
      // 更新统计信息
      this.updateStatistics();
      
      this.logger.info('Cache cleanup completed');
    } catch (error) {
      this.logger.error('Failed to cleanup cache', error as Error);
      this.statistics.errorCount++;
    }
  }

  /**
   * 获取缓存键列表
   * @param type 缓存类型
   */
  public async getKeys(type?: CacheType): Promise<string[]> {
    try {
      let keys: string[] = [];
      
      if (!type || type === CacheType.MEMORY || type === CacheType.BOTH) {
        keys = [...keys, ...Array.from(this.memoryCache.keys())];
      }
      
      if (!type || type === CacheType.DISK || type === CacheType.BOTH) {
        // 从磁盘获取键列表
        const diskKeys = await this.getDiskKeys();
        keys = [...keys, ...diskKeys];
      }
      
      // 去重
      return Array.from(new Set(keys));
    } catch (error) {
      this.logger.error('Failed to get cache keys', error as Error);
      this.statistics.errorCount++;
      return [];
    }
  }

  /**
   * 批量设置缓存
   * @param items 缓存项数组
   */
  public async setBatch(items: Array<{ key: string; value: any; options?: Partial<CacheItem> }>): Promise<void> {
    try {
      this.logger.debug(`Setting batch cache with ${items.length} items`);
      
      await Promise.all(
        items.map(item => this.set(item.key, item.value, item.options))
      );
      
      this.logger.debug('Batch cache set successfully');
    } catch (error) {
      this.logger.error('Failed to set batch cache', error as Error);
      this.statistics.errorCount++;
      throw error;
    }
  }

  /**
   * 批量获取缓存
   * @param keys 缓存键数组
   */
  public async getBatch<T = any>(keys: string[]): Promise<Map<string, T | undefined>> {
    try {
      this.logger.debug(`Getting batch cache for ${keys.length} keys`);
      
      const results = new Map<string, T | undefined>();
      
      await Promise.all(
        keys.map(async (key) => {
          const value = await this.get<T>(key);
          results.set(key, value);
        })
      );
      
      return results;
    } catch (error) {
      this.logger.error('Failed to get batch cache', error as Error);
      this.statistics.errorCount++;
      return new Map();
    }
  }

  /**
   * 批量删除缓存
   * @param keys 缓存键数组
   */
  public async removeBatch(keys: string[]): Promise<void> {
    try {
      this.logger.debug(`Removing batch cache for ${keys.length} keys`);
      
      await Promise.all(
        keys.map(key => this.remove(key))
      );
      
      this.logger.debug('Batch cache removed successfully');
    } catch (error) {
      this.logger.error('Failed to remove batch cache', error as Error);
      this.statistics.errorCount++;
    }
  }

  // 私有辅助方法

  /**
   * 在内存中存储缓存
   * @param entry 缓存条目
   */
  private storeInMemory(entry: CacheEntry): void {
    this.memoryCache.set(entry.key, entry);
    
    // 检查内存大小限制
    this.enforceMemorySizeLimit();
  }

  /**
   * 从内存中获取缓存
   * @param key 缓存键
   */
  private getFromMemory(key: string): CacheEntry | undefined {
    return this.memoryCache.get(key);
  }

  /**
   * 在磁盘上存储缓存
   * @param entry 缓存条目
   */
  private async storeOnDisk(entry: CacheEntry): Promise<void> {
    try {
      const serialized = entry.serialize();
      await this.storageUtil.set(`cache_${entry.key}`, serialized, LocalStorageType.TEMPORARY);
    } catch (error) {
      throw new Error(`Failed to store cache on disk: ${error}`);
    }
  }

  /**
   * 从磁盘上获取缓存
   * @param key 缓存键
   */
  private async getFromDisk(key: string): Promise<CacheEntry | undefined> {
    try {
      const serialized = await this.storageUtil.get<string>(`cache_${key}`, LocalStorageType.TEMPORARY);
      if (serialized) {
        return CacheEntry.deserialize(serialized);
      }
      return undefined;
    } catch (error) {
      this.logger.warn(`Failed to get cache from disk: ${key}`, error as Error);
      return undefined;
    }
  }

  /**
   * 更新统计信息
   */
  private updateStatistics(): void {
    const memoryItems = Array.from(this.memoryCache.values()).filter(item => !item.isExpired());
    
    this.statistics.memoryItems = memoryItems.length;
    this.statistics.memorySize = memoryItems.reduce((size, item) => size + item.getSize(), 0);
    
    // 磁盘统计暂时使用估计值，实际应用中需要精确计算
    this.statistics.totalItems = this.statistics.memoryItems + this.statistics.diskItems;
    this.statistics.totalSize = this.statistics.memorySize + this.statistics.diskSize;
  }

  /**
   * 重置统计信息
   */
  private resetStatistics(): void {
    this.statistics.totalItems = 0;
    this.statistics.memoryItems = 0;
    this.statistics.diskItems = 0;
    this.statistics.memorySize = 0;
    this.statistics.diskSize = 0;
    // 保留 hitCount, missCount, errorCount
  }

  /**
   * 开始定期清理任务
   */
  private startPeriodicCleanup(): void {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
    }
    
    this.cleanupTimer = setInterval(() => {
      this.cleanup();
    }, this.config.cleanInterval);
  }

  /**
   * 强制内存大小限制
   */
  private enforceMemorySizeLimit(): void {
    if (!this.config.memoryCacheSize) {
      return;
    }
    
    let currentSize = this.statistics.memorySize;
    const maxSize = this.config.memoryCacheSize;
    
    if (currentSize > maxSize) {
      this.logger.info(`Memory cache size exceeded: ${FormatUtil.formatFileSize(currentSize)} > ${FormatUtil.formatFileSize(maxSize)}`);
      
      // 按访问时间和优先级排序，移除最不常用的条目
      const entries = Array.from(this.memoryCache.values())
        .sort((a, b) => {
          // 先按优先级排序
          if (a.priority !== b.priority) {
            return a.priority - b.priority;
          }
          // 再按最后访问时间排序
          return a.lastAccessTime - b.lastAccessTime;
        });
      
      // 移除条目直到达到限制
      for (const entry of entries) {
        if (currentSize <= maxSize * 0.8) { // 清理到80%的限制
          break;
        }
        
        this.memoryCache.delete(entry.key);
        currentSize -= entry.getSize();
      }
      
      this.logger.info(`Memory cache cleaned, new size: ${FormatUtil.formatFileSize(currentSize)}`);
      this.updateStatistics();
    }
  }

  /**
   * 清理内存缓存
   * @param options 清理选项
   */
  private cleanupMemoryCache(options?: CacheCleanupOptions): void {
    const entries = Array.from(this.memoryCache.entries());
    
    for (const [key, entry] of entries) {
      // 清理过期条目
      if (entry.isExpired()) {
        this.memoryCache.delete(key);
        continue;
      }
      
      // 如果设置了最大年龄，清理超过最大年龄的条目
      if (options?.maxAge) {
        const age = Date.now() - entry.metadata.createdAt;
        if (age > options.maxAge) {
          this.memoryCache.delete(key);
          continue;
        }
      }
      
      // 如果设置了最小访问间隔，清理长时间未访问的条目
      if (options?.minAccessInterval) {
        const lastAccess = Date.now() - entry.lastAccessTime;
        if (lastAccess > options.minAccessInterval) {
          this.memoryCache.delete(key);
        }
      }
    }
  }

  /**
   * 清理磁盘缓存
   * @param options 清理选项
   */
  private async cleanupDiskCache(options?: CacheCleanupOptions): Promise<void> {
    // 实现磁盘缓存清理逻辑
    // 这里简化处理，实际应用中需要更复杂的逻辑
    const keys = await this.getDiskKeys();
    
    for (const key of keys) {
      const entry = await this.getFromDisk(key);
      if (!entry) {
        continue;
      }
      
      if (entry.isExpired()) {
        await this.remove(key);
        continue;
      }
      
      // 其他清理逻辑...
    }
  }

  /**
   * 搜索内存缓存
   * @param params 搜索参数
   */
  private searchInMemory<T = any>(params: CacheSearchParams): CacheItem<T>[] {
    let results: CacheItem<T>[] = [];
    
    for (const [key, entry] of this.memoryCache.entries()) {
      if (entry.isExpired()) {
        continue;
      }
      
      // 按键过滤
      if (params.keyPattern && !key.match(params.keyPattern)) {
        continue;
      }
      
      // 按类型过滤
      if (params.type && entry.type !== params.type) {
        continue;
      }
      
      // 按优先级过滤
      if (params.minPriority && entry.priority < params.minPriority) {
        continue;
      }
      
      results.push(entry);
    }
    
    return results;
  }

  /**
   * 搜索磁盘缓存
   * @param params 搜索参数
   */
  private async searchOnDisk<T = any>(params: CacheSearchParams): Promise<CacheItem<T>[]> {
    // 简化实现，实际应用中需要更复杂的逻辑
    const keys = await this.getDiskKeys();
    const results: CacheItem<T>[] = [];
    
    for (const key of keys) {
      const entry = await this.getFromDisk(key);
      if (!entry || entry.isExpired()) {
        continue;
      }
      
      // 按键过滤
      if (params.keyPattern && !key.match(params.keyPattern)) {
        continue;
      }
      
      // 按类型过滤
      if (params.type && entry.type !== params.type) {
        continue;
      }
      
      // 按优先级过滤
      if (params.minPriority && entry.priority < params.minPriority) {
        continue;
      }
      
      results.push(entry);
    }
    
    return results;
  }

  /**
   * 获取磁盘缓存键列表
   */
  private async getDiskKeys(): Promise<string[]> {
    // 简化实现，实际应用中需要遍历所有缓存键
    // 这里只是示例，具体实现依赖于存储机制
    return [];
  }

  /**
   * 清空磁盘缓存
   */
  private async clearDiskCache(): Promise<void> {
    // 简化实现，实际应用中需要清空所有磁盘缓存
    const keys = await this.getDiskKeys();
    await Promise.all(
      keys.map(key => this.remove(key))
    );
  }

  /**
   * 去重搜索结果
   * @param results 搜索结果
   */
  private removeDuplicates<T>(results: CacheItem<T>[]): CacheItem<T>[] {
    const uniqueKeys = new Set<string>();
    const uniqueResults: CacheItem<T>[] = [];
    
    for (const result of results) {
      if (!uniqueKeys.has(result.key)) {
        uniqueKeys.add(result.key);
        uniqueResults.push(result);
      }
    }
    
    return uniqueResults;
  }

  /**
   * 排序搜索结果
   * @param results 搜索结果
   * @param sortBy 排序字段
   * @param sortOrder 排序顺序
   */
  private sortResults<T>(results: CacheItem<T>[], sortBy: string, sortOrder: 'asc' | 'desc' = 'asc'): void {
    results.sort((a, b) => {
      let compareValue = 0;
      
      switch (sortBy) {
        case 'createdAt':
          compareValue = a.metadata.createdAt - b.metadata.createdAt;
          break;
        case 'updatedAt':
          compareValue = a.metadata.updatedAt - b.metadata.updatedAt;
          break;
        case 'accessTime':
          compareValue = (a as any).lastAccessTime - (b as any).lastAccessTime;
          break;
        case 'priority':
          compareValue = a.priority - b.priority;
          break;
        case 'accessCount':
          compareValue = (a as any).accessCount - (b as any).accessCount;
          break;
        default:
          break;
      }
      
      return sortOrder === 'asc' ? compareValue : -compareValue;
    });
  }

  /**
   * 加载持久化缓存
   */
  private async loadPersistedCache(): Promise<void> {
    // 实现持久化缓存的加载逻辑
    // 这里简化处理，实际应用中需要从持久化存储加载
    this.logger.info('Loading persisted cache');
  }
}

// 导出默认实例
export default CacheService.getInstance();