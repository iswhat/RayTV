// CacheService - 缓存服务�?import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import FileUtil from '../../common/util/FileUtil';
import JsonUtil from '../../common/util/JsonUtil';
import TypeSafetyHelper from '../../common/util/TypeSafetyHelper';
import ConfigService from '../config/ConfigService';
import FileService, { StorageLocation, FileType, FileConfig } from './FileService';

// 常量定义
const TAG = 'CacheService';
const CACHE_CONFIG_KEY = 'cache_config';
const MEMORY_CACHE_EXPIRY = 60000; // 1分钟
const MAX_MEMORY_CACHE_SIZE = 100 * 1024 * 1024; // 100MB
const DEFAULT_DISK_CACHE_SIZE = 256 * 1024 * 1024; // 256MB
const DEFAULT_CACHE_EXPIRY = 24 * 60 * 60 * 1000; // 24小时

// 缓存类型枚举
export enum CacheType {
  MEMORY = 'memory',
  DISK = 'disk',
  MEMORY_DISK = 'memory_disk'
}

// 缓存存储位置枚举
export enum CacheStorageLocation {
  INTERNAL = 'internal',
  EXTERNAL = 'external',
  TEMP = 'temp'
}

// 缓存策略枚举
export enum CacheStrategy {
  LRU = 'lru', // 最近最少使�?  LFU = 'lfu', // 最少使用频�?  FIFO = 'fifo', // 先进先出
  FILO = 'filo' // 后进先出
}

// 缓存优先级枚�?export enum CachePriority {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
  CRITICAL = 'critical'
}

// 缓存配置接口
export interface CacheConfig {
  enableMemoryCache: boolean;
  enableDiskCache: boolean;
  memoryCacheSize: number; // 字节
  diskCacheSize: number; // 字节
  defaultExpiry: number; // 毫秒
  cacheStrategy: CacheStrategy;
  storageLocation: CacheStorageLocation;
  maxCacheItems: number;
  enableAutoCleanup: boolean;
  cleanupInterval: number; // 毫秒
  cleanupThreshold: number; // 百分�?(0-100)
  cacheKeyPrefix: string;
  cacheVersion: string;
  compressCacheItems: boolean;
  encryptCacheItems: boolean;
  enableStatistics: boolean;
  logLevel: 'debug' | 'info' | 'warn' | 'error' | 'none';
  allowedCacheTypes: CacheType[];
  maxItemSize: number; // 单个缓存项最大大小（字节�?}

// 缓存项元数据接口
export interface CacheMetadata {
  key: string;
  type: string; // 数据类型
  size: number; // 字节
  createdAt: number;
  modifiedAt: number;
  accessedAt: number;
  expiry: number; // 毫秒
  priority: CachePriority;
  hits: number;
  tags: string[];
  version?: string;
  checksum?: string;
  compressed: boolean;
  encrypted: boolean;
  source?: string; // 缓存来源
}

// 缓存项接�?export interface CacheItem<T = unknown> {
  data: T;
  metadata: CacheMetadata;
}

// 缓存统计接口
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
  cacheRatio: number; // 缓存命中�?  averageGetTime: number; // 平均获取时间（毫秒）
  averageSetTime: number; // 平均设置时间（毫秒）
  largestItemSize: number;
  smallestItemSize: number;
  averageItemSize: number;
}

// 缓存搜索参数接口
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

// 缓存操作结果接口
export interface CacheOperationResult {
  success: boolean;
  key?: string;
  error?: string;
  details?: Record<string, unknown>;
}

// 缓存清理选项接口
export interface CacheCleanupOptions {
  force?: boolean;
  tags?: string[];
  olderThan?: number; // 毫秒
  priority?: CachePriority;
  sizeLimit?: number; // 字节
  itemLimit?: number;
  expiredOnly?: boolean;
  excludeKeys?: string[];
  includeKeys?: string[];
}

// 默认缓存配置
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
  cleanupInterval: 3600000, // 1小时
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
 * 缓存服务�? * 负责管理应用程序的缓存机制，提供缓存的设置、获取、清除等功能
 */
export default class CacheService {
  private static instance: CacheService;
  
  private cacheConfig: CacheConfig = { ...DEFAULT_CACHE_CONFIG };
  private memoryCache: Map<string, { data: Record<string, string | number | boolean | null>; expiry: number; timestamp: number }> = new Map();
  private cacheIndex: Map<string, CacheMetadata> = new Map();
  private cacheDir: string = '';
  private indexFile: string = '';
  
  // 统计信息
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
  
  // 操作时间记录
  private getTimes: number[] = [];
  private setTimes: number[] = [];
  
  // 监听�?  private cleanupListeners: Array<(deletedCount: number, freedSpace: number) => void> = [];
  private evictionListeners: Array<(key: string, metadata: CacheMetadata) => void> = [];
  private errorListeners: Array<(error: Error, operation: string, key?: string) => void> = [];
  
  private cleanupTimer?: number;
  private isInitialized: boolean = false;

  /**
   * 构造函数（私有，防止外部实例化�?   */
  private constructor() {
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): CacheService {
    if (!CacheService.instance) {
      CacheService.instance = new CacheService();
    }
    return CacheService.instance;
  }
  
  /**
   * 获取对象的所有键
   * 替代Object.keys，兼容ArkTS语法
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
   * 初始化缓存服�?   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing cache service...');
      
      // 加载缓存配置
      const savedConfig = await StorageUtil.getObject<CacheConfig>(CACHE_CONFIG_KEY);
      if (savedConfig) {
        this.cacheConfig = { ...DEFAULT_CACHE_CONFIG, ...savedConfig };
      }
      
      // 设置缓存目录
      await this.setCacheDirectory();
      
      // 加载缓存索引
      await this.loadCacheIndex();
      
      // 更新统计信息
      await this.updateStatistics();
      
      // 启动自动清理
      if (this.cacheConfig.enableAutoCleanup) {
        this.startAutoCleanup();
      }
      
      // 执行初始清理
      await this.performInitialCleanup();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Cache service initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize cache service', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'initialize');
    }
  }

  /**
   * 设置缓存目录
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
      
      // 创建缓存目录
      await FileUtil.ensureDirectory(this.cacheDir);
      
      // 设置索引文件路径
      this.indexFile = `${this.cacheDir}/cache_index.json`;
      
      Logger.debug(TAG, `Cache directory set to: ${this.cacheDir}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to set cache directory', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      throw error;
    }
  }

  /**
   * 加载缓存索引
   */
  private async loadCacheIndex(): Promise<void> {
    try {
      // 检查索引文件是否存�?      const indexExists = await FileUtil.fileExists(this.indexFile);
      if (!indexExists) {
        return;
      }
      
      // 读取索引文件
      const indexContent = await FileUtil.readFile(this.indexFile, 'utf-8');
      if (!indexContent) {
        return;
      }
      
      // 解析索引
      const indexData = JsonUtil.parse<Map<string, CacheMetadata>>(indexContent);
      if (!indexData || typeof indexData !== 'object') {
        return;
      }
      
      // 更新缓存索引
      for (const [key, metadata] of Object.entries(indexData)) {
        this.cacheIndex.set(key, metadata as CacheMetadata);
      }
      
      Logger.debug(TAG, `Loaded cache index with ${this.cacheIndex.size} entries`);
    } catch (error) {
      Logger.error(TAG, 'Failed to load cache index', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      // 索引文件损坏，重新创�?      await FileUtil.writeFile(this.indexFile, '{}', { create: true });
    }
  }

  /**
   * 保存缓存索引
   */
  private async saveCacheIndex(): Promise<void> {
    try {
      const indexData: Record<string, CacheMetadata> = {};
      
      // 过滤掉过期的缓存�?      const now = Date.now();
      for (const [key, metadata] of this.cacheIndex.entries()) {
        if (metadata.expiry === 0 || now < metadata.expiry) {
          indexData[key] = metadata;
        }
      }
      
      // 写入索引文件
      const indexContent = JsonUtil.stringify(indexData);
      await FileUtil.writeFile(this.indexFile, indexContent, { create: true });
      
      Logger.debug(TAG, `Saved cache index with ${this.getObjectKeys(indexData).length} entries`);
    } catch (error) {
      Logger.error(TAG, 'Failed to save cache index', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'saveCacheIndex');
    }
  }

  /**
   * 更新统计信息
   */
  private async updateStatistics(): Promise<void> {
    try {
      // 重置统计
      this.statistics.memoryCacheSize = 0;
      this.statistics.memoryCacheItems = 0;
      this.statistics.diskCacheSize = 0;
      this.statistics.diskCacheItems = 0;
      
      // 计算内存缓存统计
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
      
      // 计算磁盘缓存统计
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
      
      // 计算缓存命中�?      const total = this.statistics.hitCount + this.statistics.missCount;
      if (total > 0) {
        this.statistics.cacheRatio = this.statistics.hitCount / total;
      }
      
      // 计算平均操作时间
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
      Logger.error(TAG, 'Failed to update statistics', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'updateStatistics');
    }
  }

  /**
   * 计算对象大小（估算）
   */
  private calculateObjectSize(obj: Record<string, string | number | boolean | null>): number {
    try {
      // 简单估算，实际应用中可以使用更精确的方�?      const str = typeof obj === 'string' ? obj : JsonUtil.stringify(obj);
      return new Blob([str]).size;
    } catch (error) {
      Logger.error(TAG, 'Failed to calculate object size', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return 0;
    }
  }

  /**
   * 记录错误
   */
  private recordError(error: Error, operation: string, key?: string): void {
    this.statistics.errorCount++;
    
    // 通知错误监听�?    for (const listener of this.errorListeners) {
      try {
        listener(error, operation, key);
      } catch (listenerError) {
        Logger.error(TAG, 'Error in error listener', listenerError instanceof Error ? listenerError : new Error(String(listenerError instanceof Error ? listenerError instanceof Error ? listenerError : new Error(String(listenerError : new Error(String(listenerError instanceof Error ? listenerError : new Error(String(listenerError instanceof Error ? listenerError instanceof Error ? listenerError : new Error(String(listenerError instanceof Error ? listenerError instanceof Error ? listenerError : new Error(String(listenerError : new Error(String(listenerError instanceof Error ? listenerError : new Error(String(listenerError : new Error(String(listenerError  as Error)));
      }
    }
  }

  /**
   * 设置缓存配置
   */
  public async setCacheConfig(config: Partial<CacheConfig>): Promise<CacheConfig> {
    try {
      // 更新配置
      this.cacheConfig = {
        ...this.cacheConfig,
        ...config
      };
      
      // 保存配置
      await StorageUtil.setObject(CACHE_CONFIG_KEY, this.cacheConfig);
      
      // 如果存储位置变更，重新设置缓存目�?      if (config.storageLocation !== undefined) {
        await this.setCacheDirectory();
      }
      
      // 重启自动清理
      if (config.enableAutoCleanup !== undefined || config.cleanupInterval !== undefined) {
        this.stopAutoCleanup();
        if (this.cacheConfig.enableAutoCleanup) {
          this.startAutoCleanup();
        }
      }
      
      // 如果内存缓存大小变更，清理内存缓�?      if (config.memoryCacheSize !== undefined && this.cacheConfig.enableMemoryCache) {
        await this.evictMemoryCacheBySize();
      }
      
      // 更新统计信息
      await this.updateStatistics();
      
      Logger.info(TAG, 'Updated cache config');
      return { ...this.cacheConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to update cache config', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'setCacheConfig');
      return { ...this.cacheConfig };
    }
  }

  /**
   * 获取缓存配置
   */
  public getCacheConfig(): CacheConfig {
    return { ...this.cacheConfig };
  }

  /**
   * 重置缓存配置为默认�?   */
  public async resetCacheConfig(): Promise<CacheConfig> {
    try {
      this.cacheConfig = { ...DEFAULT_CACHE_CONFIG };
      
      // 保存配置
      await StorageUtil.setObject(CACHE_CONFIG_KEY, this.cacheConfig);
      
      // 重新设置缓存目录
      await this.setCacheDirectory();
      
      // 重启自动清理
      this.stopAutoCleanup();
      if (this.cacheConfig.enableAutoCleanup) {
        this.startAutoCleanup();
      }
      
      // 更新统计信息
      await this.updateStatistics();
      
      Logger.info(TAG, 'Reset cache config to default');
      return { ...this.cacheConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to reset cache config', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'resetCacheConfig');
      return { ...this.cacheConfig };
    }
  }

  /**
   * 开始自动清�?   */
  private startAutoCleanup(): void {
    try {
      this.stopAutoCleanup();
      
      this.cleanupTimer = setInterval(() => {
        this.performAutoCleanup();
      }, this.cacheConfig.cleanupInterval);
      
      Logger.debug(TAG, `Started auto cleanup, interval: ${this.cacheConfig.cleanupInterval}ms`);
    } catch (error) {
      Logger.error(TAG, 'Failed to start auto cleanup', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'startAutoCleanup');
    }
  }

  /**
   * 停止自动清理
   */
  private stopAutoCleanup(): void {
    try {
      if (this.cleanupTimer) {
        clearInterval(this.cleanupTimer);
        this.cleanupTimer = undefined;
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to stop auto cleanup', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'stopAutoCleanup');
    }
  }

  /**
   * 执行初始清理
   */
  private async performInitialCleanup(): Promise<void> {
    try {
      // 清理过期的缓存项
      await this.cleanupExpiredItems();
      
      // 检查缓存大小是否超过阈�?      const cachePercentage = (this.statistics.diskCacheSize / this.cacheConfig.diskCacheSize) * 100;
      if (cachePercentage > this.cacheConfig.cleanupThreshold) {
        await this.cleanupCacheBySize();
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to perform initial cleanup', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'performInitialCleanup');
    }
  }

  /**
   * 执行自动清理
   */
  private async performAutoCleanup(): Promise<void> {
    try {
      Logger.info(TAG, 'Performing auto cleanup...');
      const startTime = Date.now();
      
      let deletedCount = 0;
      let freedSpace = 0;
      
      // 清理过期的缓存项
      const expiredCleanup = await this.cleanupExpiredItems();
      deletedCount += expiredCleanup.deletedCount;
      freedSpace += expiredCleanup.freedSpace;
      
      // 检查缓存大小是否超过阈�?      const cachePercentage = (this.statistics.diskCacheSize / this.cacheConfig.diskCacheSize) * 100;
      if (cachePercentage > this.cacheConfig.cleanupThreshold) {
        const sizeCleanup = await this.cleanupCacheBySize();
        deletedCount += sizeCleanup.deletedCount;
        freedSpace += sizeCleanup.freedSpace;
      }
      
      // 检查缓存项数量是否超过限制
      if (this.statistics.diskCacheItems > this.cacheConfig.maxCacheItems) {
        const countCleanup = await this.cleanupCacheByCount();
        deletedCount += countCleanup.deletedCount;
        freedSpace += countCleanup.freedSpace;
      }
      
      // 清理内存缓存
      if (this.cacheConfig.enableMemoryCache) {
        await this.evictMemoryCacheByTime();
        await this.evictMemoryCacheBySize();
      }
      
      // 更新统计信息
      await this.updateStatistics();
      
      // 记录清理时间
      const duration = Date.now() - startTime;
      this.statistics.lastCleanupTime = startTime;
      this.statistics.totalCleanupTime += duration;
      
      // 通知清理完成
      if (deletedCount > 0) {
        this.notifyCleanupCompleted(deletedCount, freedSpace);
      }
      
      Logger.info(TAG, `Auto cleanup completed: ${deletedCount} items deleted, ${this.formatSize(freedSpace)} freed, took ${duration}ms`);
    } catch (error) {
      Logger.error(TAG, 'Failed to perform auto cleanup', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'performAutoCleanup');
    }
  }

  /**
   * 清理过期的缓存项
   */
  private async cleanupExpiredItems(): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      const now = Date.now();
      const expiredKeys: string[] = [];
      let deletedCount = 0;
      let freedSpace = 0;
      
      // 找出过期的缓存项
      for (const [key, metadata] of this.cacheIndex.entries()) {
        if (metadata.expiry > 0 && now > metadata.expiry) {
          expiredKeys.push(key);
          freedSpace += metadata.size;
        }
      }
      
      // 删除过期的缓存项
      for (const key of expiredKeys) {
        await this.removeItemFromDisk(key);
        deletedCount++;
      }
      
      // 更新统计信息
      this.statistics.expirationCount += deletedCount;
      
      // 保存索引
      await this.saveCacheIndex();
      
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, 'Failed to cleanup expired items', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'cleanupExpiredItems');
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 按大小清理缓�?   */
  private async cleanupCacheBySize(): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      // 计算需要释放的空间
      const targetSize = this.cacheConfig.diskCacheSize * (this.cacheConfig.cleanupThreshold / 100);
      const spaceToFree = this.statistics.diskCacheSize - targetSize;
      
      if (spaceToFree <= 0) {
        return { deletedCount: 0, freedSpace: 0 };
      }
      
      // 获取所有缓存项并根据策略排�?      const cacheItems = Array.from(this.cacheIndex.entries());
      let sortedItems: [string, CacheMetadata][];
      
      switch (this.cacheConfig.cacheStrategy) {
        case CacheStrategy.LRU:
          // 按最近访问时间排序（最旧的先删除）
          sortedItems = cacheItems.sort((a, b) => a[1].accessedAt - b[1].accessedAt);
          break;
        case CacheStrategy.LFU:
          // 按使用频率排序（最少使用的先删除）
          sortedItems = cacheItems.sort((a, b) => a[1].hits - b[1].hits);
          break;
        case CacheStrategy.FIFO:
          // 按创建时间排序（最早的先删除）
          sortedItems = cacheItems.sort((a, b) => a[1].createdAt - b[1].createdAt);
          break;
        case CacheStrategy.FILO:
          // 按创建时间排序（最晚的先删除）
          sortedItems = cacheItems.sort((a, b) => b[1].createdAt - a[1].createdAt);
          break;
        default:
          sortedItems = cacheItems.sort((a, b) => a[1].accessedAt - b[1].accessedAt);
      }
      
      // 按优先级排序
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
      
      // 删除缓存项直到释放足够的空间
      for (const [key, metadata] of sortedItems) {
        await this.removeItemFromDisk(key);
        deletedCount++;
        freedSpace += metadata.size;
        
        if (freedSpace >= spaceToFree) {
          break;
        }
      }
      
      // 更新统计信息
      this.statistics.evictionCount += deletedCount;
      
      // 保存索引
      await this.saveCacheIndex();
      
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, 'Failed to cleanup cache by size', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'cleanupCacheBySize');
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 按数量清理缓�?   */
  private async cleanupCacheByCount(): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      // 计算需要删除的项目�?      const itemsToDelete = this.statistics.diskCacheItems - this.cacheConfig.maxCacheItems;
      
      if (itemsToDelete <= 0) {
        return { deletedCount: 0, freedSpace: 0 };
      }
      
      // 获取所有缓存项并根据策略排�?      const cacheItems = Array.from(this.cacheIndex.entries());
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
      
      // 按优先级排序
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
      
      // 删除缓存�?      for (const [key, metadata] of sortedItems.slice(0, itemsToDelete)) {
        await this.removeItemFromDisk(key);
        deletedCount++;
        freedSpace += metadata.size;
      }
      
      // 更新统计信息
      this.statistics.evictionCount += deletedCount;
      
      // 保存索引
      await this.saveCacheIndex();
      
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, 'Failed to cleanup cache by count', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'cleanupCacheByCount');
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 根据时间驱逐内存缓�?   */
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
      Logger.error(TAG, 'Failed to evict memory cache by time', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'evictMemoryCacheByTime');
    }
  }

  /**
   * 根据大小驱逐内存缓�?   */
  private async evictMemoryCacheBySize(): Promise<void> {
    try {
      // 计算当前内存缓存大小
      let currentSize = 0;
      const cacheItems: Array<[string, { data: Record<string, string | number | boolean | null>; expiry: number; timestamp: number }]> = [];
      
      for (const [key, item] of this.memoryCache.entries()) {
        const itemSize = this.calculateObjectSize(item.data);
        currentSize += itemSize;
        cacheItems.push([key, item, itemSize]);
      }
      
      // 如果大小在限制范围内，不需要驱�?      if (currentSize <= this.cacheConfig.memoryCacheSize) {
        return;
      }
      
      // 按时间戳排序（最旧的先删除）
      cacheItems.sort((a, b) => a[1].timestamp - b[1].timestamp);
      
      // 驱逐项目直到大小在限制范围�?      let evictedCount = 0;
      
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
      Logger.error(TAG, 'Failed to evict memory cache by size', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'evictMemoryCacheBySize');
    }
  }

  /**
   * 从磁盘删除缓存项
   */
  private async removeItemFromDisk(key: string): Promise<void> {
    try {
      const metadata = this.cacheIndex.get(key);
      if (!metadata) {
        return;
      }
      
      // 删除缓存文件
      const filePath = this.getCacheFilePath(key);
      if (await FileUtil.fileExists(filePath)) {
        await FileUtil.deleteFile(filePath);
      }
      
      // 从索引中删除
      this.cacheIndex.delete(key);
      
      // 通知驱逐监听器
      this.notifyEviction(key, metadata);
      
      Logger.debug(TAG, `Removed cache item from disk: ${key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to remove cache item from disk: ${key}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'removeItemFromDisk', key);
    }
  }

  /**
   * 获取缓存文件路径
   */
  private getCacheFilePath(key: string): string {
    const encodedKey = encodeURIComponent(key);
    return `${this.cacheDir}/${encodedKey}.cache`;
  }

  /**
   * 设置缓存�?   */
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
      // 验证缓存类型
      const cacheType = options?.type || CacheType.MEMORY_DISK;
      if (!this.cacheConfig.allowedCacheTypes.includes(cacheType)) {
        throw new Error(`Cache type ${cacheType} not allowed`);
      }
      
      // 验证数据大小
      const dataSize = this.calculateObjectSize(data);
      if (dataSize > this.cacheConfig.maxItemSize) {
        throw new Error(`Data size ${this.formatSize(dataSize)} exceeds maximum allowed size ${this.formatSize(this.cacheConfig.maxItemSize)}`);
      }
      
      // 创建元数�?      const metadata: CacheMetadata = {
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
      
      // 保存到内存缓�?      if (this.cacheConfig.enableMemoryCache && 
          (cacheType === CacheType.MEMORY || cacheType === CacheType.MEMORY_DISK)) {
        this.memoryCache.set(fullKey, {
          data: TypeSafetyHelper.asObject(data) || {},
          expiry: metadata.expiry,
          timestamp: Date.now()
        });
        
        // 检查内存缓存大小限�?        await this.evictMemoryCacheBySize();
      }
      
      // 保存到磁盘缓�?      if (this.cacheConfig.enableDiskCache && 
          (cacheType === CacheType.DISK || cacheType === CacheType.MEMORY_DISK)) {
        // 序列化数�?        let serializedData: string | ArrayBuffer;
        
        try {
          serializedData = typeof data === 'string' ? data : JsonUtil.stringify(data);
        } catch (error) {
          throw new Error('Failed to serialize data for caching');
        }
        
        // 如果需要压缩或加密，在这里处理
        // ...
        
        // 写入文件
        const filePath = this.getCacheFilePath(fullKey);
        await FileUtil.writeFile(filePath, serializedData, { create: true });
        
        // 更新索引
        this.cacheIndex.set(fullKey, metadata);
        await this.saveCacheIndex();
        
        // 检查磁盘缓存大小限�?        await this.updateStatistics();
        const cachePercentage = (this.statistics.diskCacheSize / this.cacheConfig.diskCacheSize) * 100;
        if (cachePercentage > this.cacheConfig.cleanupThreshold) {
          await this.cleanupCacheBySize();
        }
      }
      
      // 更新统计信息
      await this.updateStatistics();
      
      // 记录操作时间
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
      Logger.error(TAG, `Failed to set cache item: ${key}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'set', key);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 获取缓存�?   */
  public async get<T>(key: string): Promise<T | null> {
    const startTime = Date.now();
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      let data: T | null = null;
      
      // 首先尝试从内存缓存获�?      if (this.cacheConfig.enableMemoryCache) {
        const cachedItem = this.memoryCache.get(fullKey);
        if (cachedItem) {
          // 检查是否过�?          if (cachedItem.expiry === 0 || Date.now() < cachedItem.expiry) {
            data = cachedItem.data;
            
            // 更新访问时间
            cachedItem.timestamp = Date.now();
            
            // 更新索引中的访问信息（如果存在）
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
            // 过期，删�?            this.memoryCache.delete(fullKey);
            Logger.debug(TAG, `Cache expired (memory): ${key}`);
          }
        }
      }
      
      // 如果内存缓存未命中，尝试从磁盘获�?      if (data === null && this.cacheConfig.enableDiskCache) {
        const metadata = this.cacheIndex.get(fullKey);
        if (metadata) {
          // 检查是否过�?          if (metadata.expiry === 0 || Date.now() < metadata.expiry) {
            const filePath = this.getCacheFilePath(fullKey);
            
            // 读取文件
            const fileContent = await FileUtil.readFile(filePath, 'utf-8');
            if (fileContent) {
              // 如果需要解密或解压缩，在这里处�?              // ...
              
              // 反序列化数据
              try {
                data = typeof fileContent === 'string' && 
                      (fileContent.startsWith('{') || fileContent.startsWith('[')) 
                  ? JsonUtil.parse<T>(fileContent)
                  : TypeSafetyHelper.asObject<T>(fileContent) as T;
              } catch (parseError) {
                throw new Error('Failed to parse cached data');
              }
              
              // 更新访问信息
              metadata.accessedAt = Date.now();
              metadata.hits++;
              this.cacheIndex.set(fullKey, metadata);
              await this.saveCacheIndex();
              
              // 更新统计信息
              this.statistics.hitCount++;
              Logger.debug(TAG, `Cache hit (disk): ${key}`);
            }
          } else {
            // 过期，删�?            await this.removeItemFromDisk(fullKey);
            Logger.debug(TAG, `Cache expired (disk): ${key}`);
          }
        }
      }
      
      // 如果未命中，更新统计信息
      if (data === null) {
        this.statistics.missCount++;
        Logger.debug(TAG, `Cache miss: ${key}`);
      }
      
      // 更新统计信息
      await this.updateStatistics();
      
      // 记录操作时间
      const duration = Date.now() - startTime;
      this.getTimes.push(duration);
      if (this.getTimes.length > 1000) {
        this.getTimes.shift();
      }
      
      return data;
    } catch (error) {
      Logger.error(TAG, `Failed to get cache item: ${key}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'get', key);
      return null;
    }
  }

  /**
   * 检查缓存项是否存在
   */
  public async exists(key: string): Promise<boolean> {
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      // 检查内存缓�?      if (this.cacheConfig.enableMemoryCache) {
        const cachedItem = this.memoryCache.get(fullKey);
        if (cachedItem && (cachedItem.expiry === 0 || Date.now() < cachedItem.expiry)) {
          return true;
        }
      }
      
      // 检查磁盘缓�?      if (this.cacheConfig.enableDiskCache) {
        const metadata = this.cacheIndex.get(fullKey);
        if (metadata && (metadata.expiry === 0 || Date.now() < metadata.expiry)) {
          const filePath = this.getCacheFilePath(fullKey);
          return await FileUtil.fileExists(filePath);
        }
      }
      
      return false;
    } catch (error) {
      Logger.error(TAG, `Failed to check cache existence: ${key}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'exists', key);
      return false;
    }
  }

  /**
   * 获取缓存项元数据
   */
  public async getMetadata(key: string): Promise<CacheMetadata | null> {
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      const metadata = this.cacheIndex.get(fullKey);
      if (!metadata) {
        return null;
      }
      
      // 检查是否过�?      if (metadata.expiry > 0 && Date.now() > metadata.expiry) {
        await this.removeItemFromDisk(fullKey);
        return null;
      }
      
      return { ...metadata };
    } catch (error) {
      Logger.error(TAG, `Failed to get cache metadata: ${key}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'getMetadata', key);
      return null;
    }
  }

  /**
   * 删除缓存�?   */
  public async remove(key: string): Promise<CacheOperationResult> {
    const fullKey = `${this.cacheConfig.cacheKeyPrefix}${key}`;
    
    try {
      // 从内存缓存删�?      if (this.cacheConfig.enableMemoryCache) {
        this.memoryCache.delete(fullKey);
      }
      
      // 从磁盘缓存删�?      if (this.cacheConfig.enableDiskCache) {
        await this.removeItemFromDisk(fullKey);
        await this.saveCacheIndex();
      }
      
      // 更新统计信息
      await this.updateStatistics();
      
      Logger.debug(TAG, `Removed cache item: ${key}`);
      return {
        success: true,
        key: fullKey
      };
    } catch (error) {
      Logger.error(TAG, `Failed to remove cache item: ${key}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'remove', key);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 批量设置缓存�?   */
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
      Logger.error(TAG, 'Failed to set multiple cache items', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'setMultiple');
      return results;
    }
  }

  /**
   * 批量获取缓存�?   */
  public async getMultiple<T>(keys: string[]): Promise<Map<string, T | null>> {
    const results = new Map<string, T | null>();
    
    try {
      for (const key of keys) {
        const value = await this.get<T>(key);
        results.set(key, value);
      }
      
      return results;
    } catch (error) {
      Logger.error(TAG, 'Failed to get multiple cache items', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'getMultiple');
      return results;
    }
  }

  /**
   * 批量删除缓存�?   */
  public async removeMultiple(keys: string[]): Promise<Array<CacheOperationResult>> {
    const results: Array<CacheOperationResult> = [];
    
    try {
      for (const key of keys) {
        const result = await this.remove(key);
        results.push(result);
      }
      
      return results;
    } catch (error) {
      Logger.error(TAG, 'Failed to remove multiple cache items', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'removeMultiple');
      return results;
    }
  }

  /**
   * 清理缓存
   */
  public async clear(options?: CacheCleanupOptions): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      let deletedCount = 0;
      let freedSpace = 0;
      
      // 如果强制清理，清空所有缓�?      if (options?.force) {
        // 清空内存缓存
        if (this.cacheConfig.enableMemoryCache) {
          deletedCount += this.memoryCache.size;
          this.memoryCache.clear();
        }
        
        // 清空磁盘缓存
        if (this.cacheConfig.enableDiskCache) {
          // 删除所有缓存文�?          for (const [key, metadata] of this.cacheIndex.entries()) {
            await this.removeItemFromDisk(key);
            deletedCount++;
            freedSpace += metadata.size;
          }
          
          // 清空索引
          this.cacheIndex.clear();
          await this.saveCacheIndex();
        }
      } else {
        // 根据选项清理
        const keysToDelete: string[] = [];
        const now = Date.now();
        
        // 收集需要删除的�?        for (const [key, metadata] of this.cacheIndex.entries()) {
          // 检查是否包含在排除列表�?          if (options?.excludeKeys?.includes(key)) {
            continue;
          }
          
          // 检查是否包含在包含列表�?          if (options?.includeKeys && !options.includeKeys.includes(key)) {
            continue;
          }
          
          // 检查是否只清理过期�?          if (options?.expiredOnly && (metadata.expiry === 0 || now < metadata.expiry)) {
            continue;
          }
          
          // 检查标�?          if (options?.tags && options.tags.length > 0) {
            const hasMatchingTag = options.tags.some(tag => metadata.tags.includes(tag));
            if (!hasMatchingTag) {
              continue;
            }
          }
          
          // 检查年�?          if (options?.olderThan) {
            const age = now - metadata.createdAt;
            if (age < options.olderThan) {
              continue;
            }
          }
          
          // 检查优先级
          if (options?.priority) {
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
            
            if (priorityValue(metadata.priority) > priorityValue(options.priority)) {
              continue;
            }
          }
          
          keysToDelete.push(key);
          freedSpace += metadata.size;
        }
        
        // 限制删除数量
        if (options?.itemLimit && keysToDelete.length > options.itemLimit) {
          keysToDelete.length = options.itemLimit;
        }
        
        // 限制释放空间
        if (options?.sizeLimit) {
          let accumulatedSize = 0;
          const limitedKeys: string[] = [];
          
          for (const key of keysToDelete) {
            const metadata = this.cacheIndex.get(key);
            if (metadata) {
              accumulatedSize += metadata.size;
              limitedKeys.push(key);
              
              if (accumulatedSize >= options.sizeLimit) {
                break;
              }
            }
          }
          
          keysToDelete.length = 0;
          keysToDelete.push(...limitedKeys);
        }
        
        // 删除选中的缓存项
        for (const key of keysToDelete) {
          // 从内存缓存删�?          if (this.cacheConfig.enableMemoryCache) {
            this.memoryCache.delete(key);
          }
          
          // 从磁盘缓存删�?          if (this.cacheConfig.enableDiskCache) {
            await this.removeItemFromDisk(key);
          }
          
          deletedCount++;
        }
        
        // 保存索引
        if (this.cacheConfig.enableDiskCache) {
          await this.saveCacheIndex();
        }
      }
      
      // 更新统计信息
      await this.updateStatistics();
      
      // 更新清理统计
      this.statistics.evictionCount += deletedCount;
      
      // 通知清理完成
      if (deletedCount > 0) {
        this.notifyCleanupCompleted(deletedCount, freedSpace);
      }
      
      Logger.info(TAG, `Cleared cache: ${deletedCount} items deleted, ${this.formatSize(freedSpace)} freed`);
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, 'Failed to clear cache', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'clear');
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 搜索缓存�?   */
  public async search(params: CacheSearchParams): Promise<Array<{ key: string; metadata: CacheMetadata }>> {
    try {
      const results: Array<{ key: string; metadata: CacheMetadata }> = [];
      const now = Date.now();
      
      // 遍历所有缓存项
      for (const [key, metadata] of this.cacheIndex.entries()) {
        // 检查是否过�?        const isExpired = metadata.expiry > 0 && now > metadata.expiry;
        if (params.expired !== undefined && params.expired !== isExpired) {
          continue;
        }
        
        // 检查标�?        if (params.tags && params.tags.length > 0) {
          const hasMatchingTag = params.tags.some(tag => metadata.tags.includes(tag));
          if (!hasMatchingTag) {
            continue;
          }
        }
        
        // 检查年�?        const age = now - metadata.createdAt;
        if (params.minAge !== undefined && age < params.minAge) {
          continue;
        }
        if (params.maxAge !== undefined && age > params.maxAge) {
          continue;
        }
        
        // 检查大�?        if (params.minSize !== undefined && metadata.size < params.minSize) {
          continue;
        }
        if (params.maxSize !== undefined && metadata.size > params.maxSize) {
          continue;
        }
        
        // 检查优先级
        if (params.priority && params.priority.length > 0 && !params.priority.includes(metadata.priority)) {
          continue;
        }
        
        // 检查类�?        if (params.type && params.type.length > 0 && !params.type.includes(metadata.type)) {
          continue;
        }
        
        // 检查键模式
        if (params.keyPattern) {
          // 不使用正则表达式，改用字符串方法实现大小写不敏感的匹�?          const searchPattern = params.keyPattern.toLowerCase();
          if (key.toLowerCase().indexOf(searchPattern) === -1) {
            continue;
          }
        }
        
        results.push({ key, metadata });
      }
      
      // 应用分页
      if (params.offset !== undefined) {
        results.splice(0, params.offset);
      }
      
      if (params.limit !== undefined) {
        results.length = Math.min(results.length, params.limit);
      }
      
      Logger.debug(TAG, `Search found ${results.length} cache items`);
      return results;
    } catch (error) {
      Logger.error(TAG, 'Failed to search cache items', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'search');
      return [];
    }
  }

  /**
   * 获取缓存统计信息
   */
  public getStatistics(): CacheStatistics {
    return { ...this.statistics };
  }

  /**
   * 清除统计信息
   */
  public async resetStatistics(): Promise<void> {
    try {
      this.statistics = {
        memoryCacheSize: this.statistics.memoryCacheSize,
        memoryCacheItems: this.statistics.memoryCacheItems,
        diskCacheSize: this.statistics.diskCacheSize,
        diskCacheItems: this.statistics.diskCacheItems,
        hitCount: 0,
        missCount: 0,
        evictionCount: 0,
        expirationCount: 0,
        errorCount: 0,
        lastCleanupTime: this.statistics.lastCleanupTime,
        totalCleanupTime: this.statistics.totalCleanupTime,
        cacheRatio: 0,
        averageGetTime: 0,
        averageSetTime: 0,
        largestItemSize: this.statistics.largestItemSize,
        smallestItemSize: this.statistics.smallestItemSize,
        averageItemSize: this.statistics.averageItemSize
      };
      
      // 清空操作时间记录
      this.getTimes = [];
      this.setTimes = [];
      
      Logger.debug(TAG, 'Statistics reset');
    } catch (error) {
      Logger.error(TAG, 'Failed to reset statistics', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'resetStatistics');
    }
  }

  /**
   * 添加清理监听�?   */
  public addCleanupListener(listener: (deletedCount: number, freedSpace: number) => void): () => void {
    this.cleanupListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.cleanupListeners.indexOf(listener);
      if (index > -1) {
        this.cleanupListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加驱逐监听器
   */
  public addEvictionListener(listener: (key: string, metadata: CacheMetadata) => void): () => void {
    this.evictionListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.evictionListeners.indexOf(listener);
      if (index > -1) {
        this.evictionListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加错误监听�?   */
  public addErrorListener(listener: (error: Error, operation: string, key?: string) => void): () => void {
    this.errorListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.errorListeners.indexOf(listener);
      if (index > -1) {
        this.errorListeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知清理完成
   */
  private notifyCleanupCompleted(deletedCount: number, freedSpace: number): void {
    for (const listener of this.cleanupListeners) {
      try {
        listener(deletedCount, freedSpace);
      } catch (error) {
        Logger.error(TAG, 'Error in cleanup listener', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      }
    }
  }

  /**
   * 通知缓存项被驱�?   */
  private notifyEviction(key: string, metadata: CacheMetadata): void {
    for (const listener of this.evictionListeners) {
      try {
        listener(key, { ...metadata });
      } catch (error) {
        Logger.error(TAG, 'Error in eviction listener', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      }
    }
  }

  /**
   * 格式化大小显�?   */
  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`;
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    }
  }

  /**
   * 销毁缓存服�?   */
  public async destroy(): Promise<void> {
    try {
      Logger.info(TAG, 'Destroying cache service...');
      
      // 停止自动清理
      this.stopAutoCleanup();
      
      // 保存索引
      if (this.cacheConfig.enableDiskCache) {
        await this.saveCacheIndex();
      }
      
      // 清除内存缓存
      this.memoryCache.clear();
      
      // 清除监听�?      this.cleanupListeners = [];
      this.evictionListeners = [];
      this.errorListeners = [];
      
      Logger.info(TAG, 'Cache service destroyed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to destroy cache service', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      this.recordError(error as Error, 'destroy');
    }
  }
}


