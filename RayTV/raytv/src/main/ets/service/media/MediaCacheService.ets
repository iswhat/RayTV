// MediaCacheService.ets - 媒体缓存服务 Media cache service
// 负责管理视频文件的本地缓存，包括缓存策略、清理机制和缓存统计 Responsible for managing local cache of video files, including cache strategy, cleanup mechanism and cache statistics

import Logger from '../../common/util/Logger';
import ConfigService from '../../service/config/ConfigService';
import TimerManager from '../../common/util/TimerManager';
import BusinessError from '@ohos.base';
import { Context } from '@ohos.ability.featureAbility';

// 常量定义 Constants definition
const TAG = 'MediaCacheService';
const DEFAULT_CACHE_DIR = '/cache/media';

// 缓存级别枚举 Cache level enum
export enum CacheLevel {
  LOW = 'low',           // 低缓存（仅基本信息）Low cache (basic info only)
  MEDIUM = 'medium',     // 中等缓存（基本信息+部分视频）Medium cache (basic info + partial video)
  HIGH = 'high',         // 高缓存（完整视频缓存）High cache (full video cache)
  PREMIUM = 'premium'    // 高级缓存（多质量缓存）Premium cache (multi-quality cache)
}

// 缓存策略枚举 Cache strategy enum
export enum CacheStrategy {
  FIRST_IN_FIRST_OUT = 'fifo',      // 先进先出 First in first out
  LEAST_RECENTLY_USED = 'lru',      // 最近最少使用 Least recently used
  LEAST_FREQUENTLY_USED = 'lfu',    // 最不经常使用 Least frequently used
  SIZE_BASED = 'size',              // 基于大小 Size based
  TIME_BASED = 'time'               // 基于时间 Time based
}

// 缓存状态枚举 Cache status enum
export enum CacheStatus {
  NOT_CACHED = 'not_cached',        // 未缓存 Not cached
  CACHING = 'caching',              // 缓存中 Caching
  CACHED = 'cached',                // 已缓存 Cached
  FAILED = 'failed',                // 缓存失败 Cache failed
  PARTIALLY_CACHED = 'partially_cached', // 部分缓存 Partially cached
  EXPIRED = 'expired'               // 已过期 Expired
}

// 缓存配置接口 Cache config interface
export interface CacheConfig {
  enabled: boolean;               // 是否启用缓存 Whether to enable cache
  maxCacheSize: number;           // 最大缓存大小（字节）Max cache size (bytes)
  cacheLevel: CacheLevel;         // 缓存级别 Cache level
  cacheStrategy: CacheStrategy;   // 缓存策略 Cache strategy
  autoClean: boolean;             // 自动清理 Auto cleanup
  cleanInterval: number;          // 清理间隔（秒）Cleanup interval (seconds)
  cacheExpiryDays: number;        // 缓存过期时间（天）Cache expiry days
  wifiOnly: boolean;              // 仅WiFi缓存 WiFi only
  backgroundDownload: boolean;    // 后台下载 Background download
  preloadEnabled: boolean;        // 预加载启用 Preload enabled
  preloadBufferSize: number;      // 预加载缓冲区大小 Preload buffer size
  maxConcurrentDownloads: number; // 最大并发下载数 Max concurrent downloads
  autoResumeDownloads: boolean;   // 自动恢复下载 Auto resume downloads
  priorityHighQuality: boolean;   // 优先高质量 Priority high quality
}

// 默认缓存配置 Default cache config
export const DEFAULT_CACHE_CONFIG: CacheConfig = {
  enabled: true,
  maxCacheSize: 1024 * 1024 * 1024 * 5, // 5GB
  cacheLevel: CacheLevel.MEDIUM,
  cacheStrategy: CacheStrategy.LEAST_RECENTLY_USED,
  autoClean: true,
  cleanInterval: 3600, // 1小时 1 hour
  cacheExpiryDays: 7, // 7天 7 days
  wifiOnly: true,
  backgroundDownload: true,
  preloadEnabled: true,
  preloadBufferSize: 1024 * 1024 * 50, // 50MB
  maxConcurrentDownloads: 3,
  autoResumeDownloads: true,
  priorityHighQuality: false
};

// 缓存项接口 Cache item interface
export interface CacheItem {
  id: string;                     // 缓存项ID Cache item ID
  url: string;                    // 媒体URL Media URL
  filePath: string;               // 本地文件路径 Local file path
  fileName: string;               // 文件名 File name
  size: number;                   // 文件大小（字节）File size (bytes)
  downloadedSize: number;         // 已下载大小 Downloaded size
  duration: number;               // 媒体时长（秒）Media duration (seconds)
  format: string;                 // 媒体格式 Media format
  quality: string;                // 媒体质量 Media quality
  mimeType: string;               // MIME类型 MIME type
  status: CacheStatus;            // 缓存状态 Cache status
  lastAccessTime: number;         // 最后访问时间 Last access time
  creationTime: number;           // 创建时间 Creation time
  accessCount: number;            // 访问次数 Access count
  sourceId: string;               // 源ID Source ID
  sourceName: string;             // 源名称 Source name
  metadata?: Record<string, string | number | boolean | null>;                 // 额外元数据 Extra metadata
  error?: string;                 // 错误信息 Error message
}

// 缓存统计接口 Cache statistics interface
export interface CacheStatistics {
  totalSize: number;              // 总缓存大小 Total cache size
  usedSize: number;               // 已使用大小 Used size
  freeSize: number;               // 可用大小 Free size
  itemCount: number;              // 缓存项数量 Cache item count
  cachedCount: number;            // 已缓存数量 Cached count
  cachingCount: number;           // 缓存中数量 Caching count
  failedCount: number;            // 失败数量 Failed count
  expiredCount: number;           // 过期数量 Expired count
  cacheHitRate: number;           // 缓存命中率 Cache hit rate
  cacheRatio: number;             // 缓存占用比例 Cache ratio
  oldestCacheTime: number;        // 最旧缓存时间 Oldest cache time
  newestCacheTime: number;        // 最新缓存时间 Newest cache time
}

// 下载任务接口 Download task interface
export interface DownloadTask {
  id: string;                     // 任务ID Task ID
  cacheItemId: string;            // 缓存项ID Cache item ID
  url: string;                    // 下载URL Download URL
  filePath: string;               // 保存路径 Save path
  startTime: number;              // 开始时间 Start time
  endTime?: number;               // 结束时间 End time
  size: number;                   // 文件大小 File size
  downloadedSize: number;         // 已下载大小 Downloaded size
  progress: number;               // 进度值(0-100%) Progress value (0-100%)
  speed: number;                  // 下载速度（字节/秒）Download speed (bytes/second)
  status: 'pending' | 'downloading' | 'paused' | 'completed' | 'failed' | 'canceled'; // 状态 Status
  retries: number;                // 重试次数 Retry count
  priority: number;               // 优先级（1-10级）Priority (1-10)
  headers?: Record<string, string>; // 请求头 Request headers
}

// 预加载选项接口 Preload options interface
export interface PreloadOptions {
  url: string;                    // 媒体URL Media URL
  priority: number;               // 预加载优先级 Preload priority
  maxSize?: number;               // 最大预加载大小 Maximum preload size
  quality?: string;               // 优先质量 Preferred quality
  metadata?: Record<string, string | number | boolean | null>;                 // 元数据 Metadata
}

// 缓存查询选项接口 Cache query options interface
export interface CacheQueryOptions {
  status?: CacheStatus;           // 按状态查询 Query by status
  sourceId?: string;              // 按源ID查询 Query by source ID
  minSize?: number;               // 最小大小 Minimum size
  maxSize?: number;               // 最大大小 Maximum size
  startDate?: number;             // 开始日期 Start date
  endDate?: number;               // 结束日期 End date
  quality?: string;               // 媒体质量 Media quality
  limit?: number;                 // 限制数量 Limit count
  offset?: number;                // 偏移量 Offset
  sortBy?: 'size' | 'time' | 'accessCount'; // 排序字段 Sort field
  sortOrder?: 'asc' | 'desc';     // 排序顺序 Sort order
}

// 缓存清理选项接口 Cache clean options interface
export interface CacheCleanOptions {
  olderThanDays?: number;         // 清理指定天数前的缓存 Clean cache older than specified days
  maxSize?: number;               // 清理到最大大小以下 Clean to below maximum size
  status?: CacheStatus;           // 按状态清理 Clean by status
  sourceId?: string;              // 按源ID清理 Clean by source ID
  quality?: string;               // 按质量清理 Clean by quality
  exceptIds?: string[];           // 排除的ID列表 Excluded ID list
  dryRun?: boolean;               // 测试运行 Test run
}

// 缓存监听器回调类型 Cache listener callback type
type CacheListener = (item: CacheItem) => void;

// 下载监听器回调类型 Download listener callback type
type DownloadListener = (task: DownloadTask) => void;

export default class MediaCacheService {
  private static instance: MediaCacheService;
  private configService: ConfigService;
  private config: CacheConfig = DEFAULT_CACHE_CONFIG;
  private cacheDir: string = DEFAULT_CACHE_DIR;
  private cacheItems: Map<string, CacheItem> = new Map();
  private downloadTasks: Map<string, DownloadTask> = new Map();
  private pendingTasks: DownloadTask[] = [];
  private activeTasks: number = 0;
  private cacheStats: CacheStatistics = this.createEmptyCacheStats();
  private cacheListeners: Map<string, CacheListener[]> = new Map();
  private downloadListeners: Map<string, DownloadListener[]> = new Map();
  private cleanTimerId: number | null = null;
  private timerManager: TimerManager = TimerManager.getInstance();
  private isInitialized: boolean = false;
  private cacheHitCount: number = 0;
  private cacheMissCount: number = 0;

  /**
   * 获取单例实例 Get singleton instance
   */
  public static getInstance(): MediaCacheService {
    if (!MediaCacheService.instance) {
      MediaCacheService.instance = new MediaCacheService();
    }
    return MediaCacheService.instance;
  }

  /**
   * 构造函数 Constructor
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
  }

  /**
   * 初始化媒体缓存服务 Initialize media cache service
   * @param context 应用上下文 Application context
   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Media cache service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing media cache service...');

      // 设置缓存目录 Set cache directory
      this.cacheDir = this.getCacheDirectory(context);
      await this.ensureCacheDirectory();
      
      // 加载配置 Load config
      await this.loadConfig();
      
      // 加载缓存项 Load cache items
      await this.loadCacheItems();
      
      // 更新缓存统计 Update cache statistics
      await this.updateCacheStatistics();
      
      // 如果启用了自动清理，启动定时清理 Start auto cleanup if enabled
      if (this.config.autoClean && this.config.enabled) {
        this.startAutoCleanup();
      }
      
      // 恢复未完成的下载 Resume pending downloads
      if (this.config.autoResumeDownloads) {
        this.resumePendingDownloads();
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'Media cache service initialized successfully');
      Logger.info(TAG, `Cache directory: ${this.cacheDir}, Config: ${JSON.stringify(this.config)}`);
    } catch (error) {
      Logger.error(TAG, `Failed to initialize media cache service: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 获取缓存目录 Get cache directory
   */
  private getCacheDirectory(context: Context): string {
    // 在实际应用中，应该使用系统API获取应用缓存目录 In actual application, should use system API to get app cache directory
    // 这里使用临时路径模拟 Using temporary path for simulation
    return context.cacheDir + DEFAULT_CACHE_DIR;
  }

  /**
   * 确保缓存目录存在 Ensure cache directory exists
   */
  private async ensureCacheDirectory(): Promise<void> {
    try {
      // 使用fs模块创建目录
      const fs = await import('@ohos.file.fs');
      try {
        fs.access(this.cacheDir);
        Logger.debug(TAG, `Cache directory already exists: ${this.cacheDir}`);
      } catch (e) {
        // 目录不存在，创建它
        fs.mkdir(this.cacheDir, true);
        Logger.info(TAG, `Created cache directory: ${this.cacheDir}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to create cache directory: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 加载配置 Load config
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('mediaCacheConfig', DEFAULT_CACHE_CONFIG);
      if (savedConfig) {
        this.config = { ...DEFAULT_CACHE_CONFIG, ...savedConfig };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load media cache config: ${error}`);
    }
  }

  /**
   * 保存配置 Save config
   */
  public async saveConfig(config: Partial<CacheConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config);
      
      // 根据配置调整自动清理
      if (this.config.autoClean && this.config.enabled) {
        this.startAutoCleanup();
      } else {
        this.stopAutoCleanup();
      }
      
      // 如果启用了缓存，清理过期缓存
      if (this.config.enabled) {
        this.cleanExpiredCache();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save media cache config: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取配置 Get config
   */
  public getConfig(): CacheConfig {
    return { ...this.config };
  }

  /**
   * 加载缓存项 Load cache items
   */
  private async loadCacheItems(): Promise<void> {
    try {
      // 从配置中加载缓存项信息 Load cache item information from config
      const savedItems = await this.configService.getConfig<CacheItem[]>('cacheItems', []);
      
      // 验证缓存项的实际文件是否存在 Verify if actual files exist for cache items
      for (const item of savedItems) {
        const exists = await this.checkFileExists(item.filePath);
        
        if (exists) {
          // 更新缓存项状态 Update cache item status
          item.status = CacheStatus.CACHED;
          this.cacheItems.set(item.id, item);
        } else {
          // 文件不存在，移除缓存项 File doesn't exist, remove cache item
          Logger.warn(TAG, `Cache file not found: ${item.filePath}, removing cache item`);
        }
      }
      
      Logger.info(TAG, `Loaded ${this.cacheItems.size} cache items`);
    } catch (error) {
      Logger.error(TAG, `Failed to load cache items: ${error}`);
    }
  }

  /**
   * 保存缓存项 Save cache items
   */
  private async saveCacheItems(): Promise<void> {
    try {
      const items = Array.from(this.cacheItems.values());
      await this.configService.setConfig('cacheItems', items);
    } catch (error) {
      Logger.error(TAG, `Failed to save cache items: ${error}`);
    }
  }

  /**
   * 检查文件是否存在 Check if file exists
   */
  private async checkFileExists(filePath: string): Promise<boolean> {
    try {
      const fs = await import('@ohos.file.fs');
      fs.access(filePath);
      return true;
    } catch (error) {
      Logger.debug(TAG, `File does not exist: ${filePath}`);
      return false;
    }
  }

  /**
   * 获取文件实际大小 Get actual file size
   */
  private async getFileSize(filePath: string): Promise<number> {
    try {
      const fs = await import('@ohos.file.fs');
      const stat = await fs.stat(filePath);
      return stat.size || 0;
    } catch (error) {
      Logger.warn(TAG, `Failed to get file size: ${filePath}`);
      return 0;
    }
  }

  /**
   * 创建空的缓存统计对象 Create empty cache statistics object
   */
  private createEmptyCacheStats(): CacheStatistics {
    return {
      totalSize: this.config.maxCacheSize,
      usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now(),
      newestCacheTime: Date.now()
    };
  }

  /**
   * 更新缓存统计 Update cache statistics
   */
  private async updateCacheStatistics(): Promise<void> {
    const stats = this.createEmptyCacheStats();
    stats.itemCount = this.cacheItems.size;

    let totalUsedSize = 0;
    let cachedCount = 0;
    let cachingCount = 0;
    let failedCount = 0;
    let expiredCount = 0;
    let oldestTime = Date.now();
    let newestTime = 0;

    const expiryTime = Date.now() - (this.config.cacheExpiryDays * 24 * 60 * 60 * 1000);

    for (const item of this.cacheItems.values()) {
      // 如果文件存在，获取实际文件大小
      const actualSize = await this.getFileSize(item.filePath);
      const itemSize = actualSize > 0 ? actualSize : item.size;
      totalUsedSize += itemSize;
      
      switch (item.status) {
        case CacheStatus.CACHED:
          cachedCount++;
          // 检查是否过期 Check if expired
          if (item.lastAccessTime < expiryTime) {
            item.status = CacheStatus.EXPIRED;
            expiredCount++;
          }
          break;
        case CacheStatus.CACHING:
          cachingCount++;
          break;
        case CacheStatus.FAILED:
          failedCount++;
          break;
        case CacheStatus.EXPIRED:
          expiredCount++;
          break;
      }
      
      oldestTime = Math.min(oldestTime, item.creationTime);
      newestTime = Math.max(newestTime, item.creationTime);
    }
    
    stats.usedSize = totalUsedSize;
    stats.freeSize = Math.max(0, this.config.maxCacheSize - totalUsedSize);
    stats.cachedCount = cachedCount;
    stats.cachingCount = cachingCount;
    stats.failedCount = failedCount;
    stats.expiredCount = expiredCount;
    stats.cacheRatio = this.config.maxCacheSize > 0 ? (totalUsedSize / this.config.maxCacheSize) * 100 : 0;
    stats.cacheHitRate = this.calculateCacheHitRate();
    stats.oldestCacheTime = oldestTime;
    stats.newestCacheTime = newestTime;
    
    this.cacheStats = stats;
  }

  /**
   * 计算缓存命中率 Calculate cache hit rate
   */
  private calculateCacheHitRate(): number {
    const totalRequests = this.cacheHitCount + this.cacheMissCount;
    return totalRequests > 0 ? (this.cacheHitCount / totalRequests) * 100 : 0;
  }

  /**
   * 获取缓存统计 Get cache statistics
   */
  public getCacheStatistics(): CacheStatistics {
    return { ...this.cacheStats };
  }

  /**
   * 开始自动清理 Start auto cleanup
   */
  private startAutoCleanup(): void {
    this.stopAutoCleanup();

    this.cleanTimerId = this.timerManager.setInterval(() => {
      this.performAutoCleanup().catch(error => {
        Logger.error(TAG, `Auto cleanup failed: ${error instanceof Error ? error.message : String(error)}`);
      });
    }, this.config.cleanInterval * 1000, 'MediaCacheService.autoCleanup');

    Logger.info(TAG, `Auto cleanup started with interval: ${this.config.cleanInterval}s`);
  }

  /**
   * 停止自动清理 Stop auto cleanup
   */
  private stopAutoCleanup(): void {
    if (this.cleanTimerId !== null) {
      this.timerManager.clearInterval(this.cleanTimerId);
      this.cleanTimerId = null;
      Logger.info(TAG, 'Auto cleanup stopped');
    }
  }

  /**
   * 执行自动清理 Perform auto cleanup
   */
  private async performAutoCleanup(): Promise<void> {
    if (!this.config.enabled) {
      return;
    }

    Logger.info(TAG, 'Performing auto cleanup...');
    
    // 清理过期缓存 Clean expired cache
    await this.cleanExpiredCache();
    
    // 如果缓存大小超过限制，根据策略清理 If cache size exceeds limit, clean according to strategy
    if (this.cacheStats.usedSize > this.config.maxCacheSize) {
      const bytesToClean = this.cacheStats.usedSize - this.config.maxCacheSize;
      await this.cleanCacheByStrategy(bytesToClean);
    }
    
    // 更新统计 Update statistics
    await this.updateCacheStatistics();
    Logger.info(TAG, 'Auto cleanup completed');
  }

  /**
   * 清理过期缓存 Clean expired cache
   */
  private async cleanExpiredCache(): Promise<void> {
    const expiryTime = Date.now() - (this.config.cacheExpiryDays * 24 * 60 * 60 * 1000);
    const expiredItems = Array.from(this.cacheItems.values()).filter(
      item => item.lastAccessTime < expiryTime && item.status !== CacheStatus.CACHING
    );
    
    if (expiredItems.length > 0) {
      Logger.info(TAG, `Cleaning ${expiredItems.length} expired cache items`);
      await this.removeCacheItems(expiredItems.map(item => item.id));
    }
  }

  /**
   * 根据策略清理缓存 Clean cache by strategy
   */
  private async cleanCacheByStrategy(bytesToClean: number): Promise<void> {
    const cacheItems = Array.from(this.cacheItems.values())
      .filter(item => item.status !== CacheStatus.CACHING);
    
    let itemsToRemove: CacheItem[] = [];
    let cleanedBytes = 0;
    
    // 根据缓存策略排序 Sort by cache strategy
    let sortedItems: CacheItem[] = [];
    
    switch (this.config.cacheStrategy) {
      case CacheStrategy.FIRST_IN_FIRST_OUT:
        // 先进先出：按创建时间排序，先删除最旧的 First in first out: sort by creation time, delete oldest first
        sortedItems = [...cacheItems].sort((a, b) => a.creationTime - b.creationTime);
        break;
      case CacheStrategy.LEAST_RECENTLY_USED:
        // 最近最少使用：按最后访问时间排序 Least recently used: sort by last access time
        sortedItems = [...cacheItems].sort((a, b) => a.lastAccessTime - b.lastAccessTime);
        break;
      case CacheStrategy.LEAST_FREQUENTLY_USED:
        // 最不经常使用：按访问次数排序 Least frequently used: sort by access count
        sortedItems = [...cacheItems].sort((a, b) => a.accessCount - b.accessCount);
        break;
      case CacheStrategy.SIZE_BASED:
        // 基于大小：按文件大小排序，优先删除大文件 Size based: sort by file size, delete large files first
        sortedItems = [...cacheItems].sort((a, b) => b.size - a.size);
        break;
      case CacheStrategy.TIME_BASED:
        // 基于时间：按最后访问时间排序 Time based: sort by last access time
        sortedItems = [...cacheItems].sort((a, b) => a.lastAccessTime - b.lastAccessTime);
        break;
    }
    
    // 选择要删除的项目 Select items to remove
    for (const item of sortedItems) {
      if (cleanedBytes >= bytesToClean) {
        break;
      }
      
      itemsToRemove.push(item);
      cleanedBytes += item.size;
    }
    
    if (itemsToRemove.length > 0) {
      Logger.info(TAG, `Cleaning ${itemsToRemove.length} cache items to free ${cleanedBytes} bytes`);
      await this.removeCacheItems(itemsToRemove.map(item => item.id));
    }
  }

  /**
   * 恢复未完成的下载 Resume pending downloads
   */
  private resumePendingDownloads(): void {
    const pendingTasks = Array.from(this.downloadTasks.values())
      .filter(task => task.status === 'paused' || task.status === 'pending');
    
    Logger.info(TAG, `Resuming ${pendingTasks.length} pending downloads`);
    
    for (const task of pendingTasks) {
      this.startDownloadTask(task).catch(error => {
        Logger.error(TAG, `Failed to resume task ${task.id}: ${error}`);
      });
    }
  }

  /**
   * 缓存媒体文件 Cache media file
   */
  public async cacheMedia(options: {
    url: string;
    quality?: string;
    metadata?: Record<string, string | number | boolean | null>;
    priority?: number;
    headers?: Record<string, string>;
  }): Promise<CacheItem> {
    if (!this.config.enabled) {
      throw new Error('Media cache is disabled');
    }

    const url = options.url;
    const quality = options.quality ?? 'auto';
    const metadata = options.metadata ?? {};
    const priority = options.priority ?? 5;
    const headers = options.headers ?? {};
    
    // 生成缓存项ID Generate cache item ID
    const cacheId = this.generateCacheId(url, quality);
    
    // 检查是否已存在 Check if already exists
    let cacheItem = this.cacheItems.get(cacheId);
    if (cacheItem) {
      // 更新访问时间和计数 Update access time and count
      cacheItem.lastAccessTime = Date.now();
      cacheItem.accessCount++;
      cacheItem.metadata = { ...cacheItem.metadata, ...metadata };
      
      // 如果已缓存，直接返回 If already cached, return directly
      if (cacheItem.status === CacheStatus.CACHED) {
        this.notifyCacheUpdate(cacheItem);
        await this.saveCacheItems();
        return cacheItem;
      }
      
      // 如果正在缓存，检查是否有对应的下载任务 If caching, check if there's an existing download task
      const existingTask = Array.from(this.downloadTasks.values())
        .find(task => task.cacheItemId === cacheId);
      
      if (existingTask && existingTask.status === 'downloading') {
        return cacheItem;
      }
    } else {
      // 创建新的缓存项 Create new cache item
      const fileName = this.generateFileName(url, quality);
      const filePath = `${this.cacheDir}/${fileName}`;
      
      cacheItem = {
        id: cacheId,
        url,
        filePath,
        fileName,
        size: 0,
        downloadedSize: 0,
        duration: 0,
        format: this.getFileFormat(url),
        quality,
        mimeType: this.getMimeType(url),
        status: CacheStatus.NOT_CACHED,
        lastAccessTime: Date.now(),
        creationTime: Date.now(),
        accessCount: 1,
        sourceId: metadata.sourceId || '',
        sourceName: metadata.sourceName || '',
        metadata
      };
      
      this.cacheItems.set(cacheId, cacheItem);
    }
    
    // 创建下载任务 Create download task
    const downloadTask: DownloadTask = {
      id: `download_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      cacheItemId: cacheId,
      url,
      filePath: cacheItem.filePath,
      startTime: Date.now(),
      size: cacheItem.size,
      downloadedSize: cacheItem.downloadedSize,
      progress: 0,
      speed: 0,
      status: 'pending',
      retries: 0,
      priority,
      headers
    };
    
    this.downloadTasks.set(downloadTask.id, downloadTask);
    
    // 更新缓存项状态 Update cache item status
    cacheItem.status = CacheStatus.CACHING;
    this.notifyCacheUpdate(cacheItem);
    
    // 启动下载任务 Start download task
    this.startDownloadTask(downloadTask);
    
    // 保存缓存项 Save cache items
    await this.saveCacheItems();
    
    return cacheItem;
  }

  /**
   * 生成缓存ID Generate cache ID
   */
  private generateCacheId(url: string, quality: string): string {
    // 简单实现：使用URL和质量的哈希作为ID
    // 实际应用中应该使用更安全的哈希算法 In actual applications, should use more secure hash algorithm
    let hash = 0;
    const data = url + quality;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash |= 0; // 转换为32位整数 Convert to 32-bit integer
    }
    return `cache_${hash.toString(16)}`;
  }

  /**
   * 生成文件名 Generate file name
   */
  private generateFileName(url: string, quality: string): string {
    const timestamp = Date.now();
    const format = this.getFileFormat(url);
    const safeName = this.sanitizeFileName(url.substring(url.lastIndexOf('/') + 1, url.lastIndexOf('.')));
    return `${safeName}_${quality}_${timestamp}.${format}`;
  }

  /**
   * 清理文件名 Sanitize file name
   */
  private sanitizeFileName(name: string): string {
    // 移除不安全的字符 Remove unsafe characters
    return name.replace(/[<>"/\|?*]/g, '_').substring(0, 50);
  }

  /**
   * 获取文件格式 Get file format
   */
  private getFileFormat(url: string): string {
    const match = url.match(/\.([^.]+)$/);
    return match ? match[1].toLowerCase() : 'mp4';
  }

  /**
   * 获取MIME类型 Get MIME type
   */
  private getMimeType(url: string): string {
    const format = this.getFileFormat(url);
    const mimeTypes: Record<string, string> = {
      mp4: 'video/mp4',
      mkv: 'video/x-matroska',
      avi: 'video/x-msvideo',
      flv: 'video/x-flv',
      webm: 'video/webm',
      mov: 'video/quicktime'
    };
    
    return mimeTypes[format] || 'video/mp4';
  }

  /**
   * 启动下载任务 Start download task
   */
  private async startDownloadTask(task: DownloadTask): Promise<void> {
    // 检查是否达到最大并发下载数 Check if max concurrent downloads reached
    if (this.activeTasks >= this.config.maxConcurrentDownloads) {
      // 添加到待处理队列 Add to pending queue  
      this.pendingTasks.push(task);
      Logger.info(TAG, `Task ${task.id} added to pending queue`);
      return;
    }
    
    // 更新任务状态 Update task status
    task.status = 'downloading';
    this.activeTasks++;
    
    // 通知任务更新 Notify task update
    this.notifyDownloadUpdate(task);
    
    try {
      // TODO: 实现实际的下载逻辑 Implement actual download logic
      // 这里需要使用网络API下载文件 Download file using network API
      Logger.info(TAG, `Starting download task ${task.id}: ${task.url}`);
      
      // 执行真实网络下载 | Perform real network download
      await this.performRealDownload(task);
      
      // 下载完成 Download completed
      task.status = 'completed';
      task.endTime = Date.now();
      task.progress = 100;
      
      // 更新缓存项 Update cache item
      const cacheItem = this.cacheItems.get(task.cacheItemId);
      if (cacheItem) {
        cacheItem.status = CacheStatus.CACHED;
        cacheItem.size = task.size;
        cacheItem.downloadedSize = task.downloadedSize;
        this.notifyCacheUpdate(cacheItem);
        
        // 更新缓存统计 Update cache statistics
        await this.updateCacheStatistics();
        await this.saveCacheItems();
      }
      
    } catch (error) {
      Logger.error(TAG, `Download task ${task.id} failed: ${error}`);
      
      task.status = 'failed';
      task.endTime = Date.now();
      task.retries++;
      
      // 更新缓存项 Update cache item
      const cacheItem = this.cacheItems.get(task.cacheItemId);
      if (cacheItem) {
        cacheItem.status = CacheStatus.FAILED;
        cacheItem.error = String(error);
        this.notifyCacheUpdate(cacheItem);
      }
      
      // 如果重试次数未达到限制，重新尝试 If retries not reached limit, retry
      if (task.retries < 3) {
        this.timerManager.setTimeout(() => {
          this.retryDownloadTask(task);
        }, 5000, 'MediaCacheService.downloadRetry'); // 5秒后重试 Retry after 5 seconds
      }
    } finally {
      this.activeTasks--;
      this.notifyDownloadUpdate(task);
      
      // 处理下一个待处理任务 Process next pending task
      this.processNextPendingTask();
      
      // 如果任务已完成或失败，从活动任务中移除 If task completed or failed, remove from active tasks
      if (task.status === 'completed' || task.status === 'failed') {
        this.timerManager.setTimeout(() => {
          this.downloadTasks.delete(task.id);
        }, 60000, 'MediaCacheService.taskCleanup'); // 1分钟后移除 Remove after 1 minute
      }
    }
  }

  /**
   * 执行真实网络下载 | Perform real network download
   */
  private async performRealDownload(task: DownloadTask): Promise<void> {
    try {
      // 1. 建立网络连接 | Establish network connection
      const response = await this.openDownloadConnection(task.url);
      
      // 2. 获取文件大小 | Get file size
      const contentLength = response.getContentLength();
      if (contentLength > 0) {
        task.size = contentLength;
      } else {
        Logger.warn(TAG, `无法获取文件大小 | Unable to get file size for ${task.url}`);
      }
      
      // 3. 创建本地文件 | Create local file
      const filePath = this.getFilePathForDownload(task);
      const fileStream = await this.createFileStream(filePath, task.downloadedSize > 0);
      
      // 4. 设置请求范围（支持断点续传）| Set request range (support resume download)
      if (task.downloadedSize > 0) {
        response.setRange(task.downloadedSize, contentLength - 1);
      }
      
      // 5. 获取输入流 | Get input stream
      const inputStream = response.getInputStream();
      
      // 6. 开始下载 | Start download
      let downloaded = task.downloadedSize;
      const chunkSize = 1024 * 1024; // 1MB chunks
      const buffer = new ArrayBuffer(chunkSize);
      const startTime = Date.now();
      
      // 7. 循环读取数据 | Loop to read data
      while (true) {
        // 读取数据块 | Read data chunk
        const bytesRead = await inputStream.read(buffer);
        if (bytesRead <= 0) {
          // 下载完成 | Download completed
          break;
        }
        
        // 写入文件 | Write to file
        await fileStream.write(buffer.slice(0, bytesRead));
        
        // 更新下载进度 | Update download progress
        downloaded += bytesRead;
        task.downloadedSize = downloaded;
        
        // 计算进度 | Calculate progress
        if (task.size > 0) {
          task.progress = Math.round((downloaded / task.size) * 100);
        }
        
        // 计算下载速度 | Calculate download speed
        const elapsed = (Date.now() - startTime) / 1000; // 秒 Seconds
        task.speed = elapsed > 0 ? (downloaded / elapsed) : 0;
        
        // 通知更新 | Notify update
        this.notifyDownloadUpdate(task);
        
        // 检查是否需要暂停 | Check if need to pause
        if (task.status === 'paused') {
          break;
        }
      }
      
      // 8. 关闭流 | Close streams
      await fileStream.close();
      await inputStream.close();
      await response.close();
      
      Logger.info(TAG, `下载完成: ${task.url}, 大小: ${task.size} | Download completed: ${task.url}, size: ${task.size}`);
      
    } catch (error) {
      Logger.error(TAG, `下载过程中出错: ${error} | Error during download: ${error}`);
      throw error;
    }
  }
  
  /**
   * 打开下载连接 | Open download connection
   */
  private async openDownloadConnection(url: string): Promise<any> {
    // 实际实现应该使用HarmonyOS的网络API | Actual implementation should use HarmonyOS network API
    const httpClient = globalThis.httpClient;
    if (!httpClient) {
      throw new Error(`HTTP客户端未初始化 | HTTP client not initialized`);
    }
    
    const request = httpClient.createRequest(url, 'GET');
    request.setConnectTimeout(30000); // 30秒连接超时
    request.setReadTimeout(60000); // 60秒读取超时
    
    // 设置下载相关头信息 | Set download related headers
    request.setHeader('Accept', '*/*');
    request.setHeader('User-Agent', 'RayTV/1.0 HarmonyOS');
    
    return await request.execute();
  }
  
  /**
   * 获取下载文件路径 | Get file path for download
   */
  private getFilePathForDownload(task: DownloadTask): string {
    // 实际实现应该根据缓存配置和文件类型生成路径 | Actual implementation should generate path based on cache config and file type
    const cachePath = this.config.cachePath;
    const fileName = `raytv_${Date.now()}_${Math.floor(Math.random() * 1000)}.mp4`;
    return `${cachePath}/${fileName}`;
  }
  
  /**
   * 创建文件流 | Create file stream
   */
  private async createFileStream(filePath: string, append: boolean): Promise<any> {
    // 实际实现应该使用HarmonyOS的文件系统API | Actual implementation should use HarmonyOS file system API
    const fileManager = globalThis.fileManager;
    if (!fileManager) {
      throw new Error(`文件管理器未初始化 | File manager not initialized`);
    }
    
    // 确保目录存在 | Ensure directory exists
    const dirPath = filePath.substring(0, filePath.lastIndexOf('/'));
    await fileManager.mkdir(dirPath, true);
    
    // 创建或打开文件流 | Create or open file stream
    return await fileManager.openFile(filePath, append ? 'a+' : 'w+');
  }

  /**
   * 重试下载任务 Retry download task
   */
  private retryDownloadTask(task: DownloadTask): void {
    Logger.info(TAG, `Retrying download task ${task.id} (attempt ${task.retries}/3)`);
    this.startDownloadTask(task);
  }

  /**
   * 处理下一个待处理任务 Process next pending task
   */
  private processNextPendingTask(): void {
    if (this.pendingTasks.length === 0 || this.activeTasks >= this.config.maxConcurrentDownloads) {
      return;
    }
    
    // 按优先级排序 Sort by priority
    this.pendingTasks.sort((a, b) => b.priority - a.priority);
    
    // 取出下一个任务 Take next task from pending tasks
    const nextTask = this.pendingTasks.shift();
    if (nextTask) {
      this.startDownloadTask(nextTask);
    }
  }

  /**
   * 暂停下载 Pause download
   */
  public async pauseDownload(cacheItemId: string): Promise<void> {
    const task = Array.from(this.downloadTasks.values())
      .find(t => t.cacheItemId === cacheItemId && t.status === 'downloading');
    
    if (task) {
      task.status = 'paused';
      this.notifyDownloadUpdate(task);
      
      // 如果正在下载，减少活动任务计数 If downloading, reduce active tasks count
      if (task.status === 'downloading') {
        this.activeTasks--;
        this.processNextPendingTask();
      }
      
      // 从活动任务中减少计数 Decrease active tasks count from active tasks
      this.activeTasks--;
      
      // 处理下一个任务 Process next task
      this.processNextPendingTask();
      
      // 更新缓存项状态 Update cache item status
      const cacheItem = this.cacheItems.get(cacheItemId);
      if (cacheItem) {
        cacheItem.status = CacheStatus.PARTIALLY_CACHED;
        cacheItem.downloadedSize = task.downloadedSize;
        this.notifyCacheUpdate(cacheItem);
        await this.saveCacheItems();
      }
    }
  }

  /**
   * 恢复下载 Resume download
   */
  public async resumeDownload(cacheItemId: string): Promise<void> {
    const task = Array.from(this.downloadTasks.values())
      .find(t => t.cacheItemId === cacheItemId && t.status === 'paused');
    
    if (task) {
      this.startDownloadTask(task);
    } else {
      // 如果任务不存在，重新创建 If task not found, re-create
      const cacheItem = this.cacheItems.get(cacheItemId);
      if (cacheItem) {
        await this.cacheMedia({
          url: cacheItem.url,
          quality: cacheItem.quality,
          metadata: cacheItem.metadata
        });
      }
    }
  }

  /**
   * 取消下载 Cancel download
   */
  public async cancelDownload(cacheItemId: string): Promise<void> {
    const task = Array.from(this.downloadTasks.values())
      .find(t => t.cacheItemId === cacheItemId && 
            (t.status === 'downloading' || t.status === 'paused' || t.status === 'pending'));
    
    if (task) {
      task.status = 'canceled';
      this.notifyDownloadUpdate(task);
      
      // 如果正在下载，减少活动任务计数 If downloading, reduce active tasks count
      if (task.status === 'downloading') {
        this.activeTasks--;
        this.processNextPendingTask();
      }
      
      // 从待处理队列中移除 Remove from pending queue
      const pendingIndex = this.pendingTasks.findIndex(t => t.id === task.id);
      if (pendingIndex > -1) {
        this.pendingTasks.splice(pendingIndex, 1);
      }
      
      // 更新缓存项 Update cache item
      const cacheItem = this.cacheItems.get(cacheItemId);
      if (cacheItem) {
        cacheItem.status = CacheStatus.NOT_CACHED;
        cacheItem.downloadedSize = 0;
        this.notifyCacheUpdate(cacheItem);
        await this.saveCacheItems();
      }
      
      // 删除临时文件 Delete temporary file
      await this.deleteFile(task.filePath);
    }
  }

  /**
   * 删除文件 Delete file
   */
  private async deleteFile(filePath: string): Promise<void> {
    try {
      const fs = await import('@ohos.file.fs');
      fs.unlink(filePath);
      Logger.debug(TAG, `Deleted file: ${filePath}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete file ${filePath}: ${error}`);
    }
  }

  /**
   * 获取缓存项 Get cache item
   */
  public getCacheItem(cacheItemId: string): CacheItem | null {
    const item = this.cacheItems.get(cacheItemId);
    if (item) {
      // 更新访问时间和计数 Update access time and count
      item.lastAccessTime = Date.now();
      item.accessCount++;
      this.notifyCacheUpdate(item);
      this.cacheHitCount++;
      return { ...item };
    }
    
    this.cacheMissCount++;
    return null;
  }

  /**
   * 通过URL查找缓存项 Find cache item by URL
   */
  public findCacheItemByUrl(url: string, quality?: string): CacheItem | null {
    const cacheId = this.generateCacheId(url, quality || 'auto');
    return this.getCacheItem(cacheId);
  }

  /**
   * 列出缓存项 List cache items
   */
  public listCacheItems(options?: CacheQueryOptions): CacheItem[] {
    let items = Array.from(this.cacheItems.values());
    
    // 应用过滤条件 Apply filter conditions
    if (options) {
      if (options.status) {
        items = items.filter(item => item.status === options.status);
      }
      
      if (options.sourceId) {
        items = items.filter(item => item.sourceId === options.sourceId);
      }
      
      if (options.minSize !== undefined) {
        items = items.filter(item => item.size >= options.minSize!);
      }
      
      if (options.maxSize !== undefined) {
        items = items.filter(item => item.size <= options.maxSize!);
      }
      
      if (options.startDate !== undefined) {
        items = items.filter(item => item.creationTime >= options.startDate!);
      }
      
      if (options.endDate !== undefined) {
        items = items.filter(item => item.creationTime <= options.endDate!);
      }
      
      if (options.quality) {
        items = items.filter(item => item.quality === options.quality);
      }
    }
    
    // 应用排序 Apply sorting
    if (options?.sortBy) {
      items.sort((a, b) => {
        let aValue: number = 0;
        let bValue: number = 0;
        
        switch (options.sortBy) {
          case 'size':
            aValue = a.size;
            bValue = b.size;
            break;
          case 'time':
            aValue = a.lastAccessTime;
            bValue = b.lastAccessTime;
            break;
          case 'accessCount':
            aValue = a.accessCount;
            bValue = b.accessCount;
            break;
          default:
            return 0;
        }
        
        return options.sortOrder === 'desc' ? bValue - aValue : aValue - bValue;
      });
    }
    
    // 应用分页 Apply pagination
    if (options?.offset !== undefined) {
      items = items.slice(options.offset);
    }
    
    if (options?.limit !== undefined) {
      items = items.slice(0, options.limit);
    }
    
    return items.map(item => ({ ...item }));
  }

  /**
   * 移除缓存项 Remove cache items
   */
  public async removeCacheItems(cacheItemIds: string[]): Promise<void> {
    for (const id of cacheItemIds) {
      const item = this.cacheItems.get(id);
      if (item) {
        // 取消相关下载任务 Cancel related download tasks
        await this.cancelDownload(id);
        
        // 删除文件 Delete file
        await this.deleteFile(item.filePath);
        
        // 从缓存项列表中移除 Remove from cache items list
        this.cacheItems.delete(id);
        
        Logger.info(TAG, `Removed cache item: ${id}`);
      }
    }
    
    // 更新统计 Update statistics
    await this.updateCacheStatistics();
    await this.saveCacheItems();
  }

  /**
   * 清理缓存 Clean cache
   */
  public async cleanCache(options?: CacheCleanOptions): Promise<number> {
    if (!this.config.enabled) {
      return 0;
    }
    
    let itemsToRemove: CacheItem[] = [];
    const allItems = Array.from(this.cacheItems.values());
    
    // 应用清理选项 Apply clean options
    if (options) {
      if (options.olderThanDays) {
        const cutoffTime = Date.now() - (options.olderThanDays * 24 * 60 * 60 * 1000);
        itemsToRemove = itemsToRemove.concat(
          allItems.filter(item => item.creationTime < cutoffTime)
        );
      }
      
      if (options.status) {
        itemsToRemove = itemsToRemove.concat(
          allItems.filter(item => item.status === options.status)
        );
      }
      
      if (options.sourceId) {
        itemsToRemove = itemsToRemove.concat(
          allItems.filter(item => item.sourceId === options.sourceId)
        );
      }
      
      if (options.quality) {
        itemsToRemove = itemsToRemove.concat(
          allItems.filter(item => item.quality === options.quality)
        );
      }
      
      if (options.maxSize && this.cacheStats.usedSize > options.maxSize) {
        // 根据缓存策略清理到指定大小 Clean to specified size based on cache strategy
        const bytesToClean = this.cacheStats.usedSize - options.maxSize;
        const sortedItems = this.sortItemsByStrategy(allItems);
        
        let cleanedBytes = 0;
        for (const item of sortedItems) {
          if (cleanedBytes >= bytesToClean) {
            break;
          }
          
          if (!itemsToRemove.find(i => i.id === item.id)) {
            itemsToRemove.push(item);
            cleanedBytes += item.size;
          }
        }
      }
    } else {
      // 清理所有缓存 Clean all cache
      itemsToRemove = allItems;
    }
    
    // 排除指定的ID Exclude specified IDs
    if (options?.exceptIds) {
      itemsToRemove = itemsToRemove.filter(item => !options.exceptIds!.includes(item.id));
    }
    
    // 去重 Remove duplicates
    const uniqueItems = itemsToRemove.filter((item, index, self) =>
      index === self.findIndex(i => i.id === item.id)
    );
    
    // 检查是否为模拟运行 Check if it's a dry run
    if (options?.dryRun) {
      Logger.info(TAG, `Dry run: would remove ${uniqueItems.length} cache items`);
      return uniqueItems.length;
    }
    
    // 执行清理 Execute cleanup
    if (uniqueItems.length > 0) {
      await this.removeCacheItems(uniqueItems.map(item => item.id));
    }
    
    return uniqueItems.length;
  }

  /**
   * 清空所有缓存 Clear all cache
   */
  public async clearAllCache(): Promise<void> {
    await this.cleanCache();
    Logger.info(TAG, 'All cache cleared');
  }

  /**
   * 根据策略排序缓存项 Sort cache items by strategy
   */
  private sortItemsByStrategy(items: CacheItem[]): CacheItem[] {
    const sorted = [...items];
    
    switch (this.config.cacheStrategy) {
      case CacheStrategy.FIRST_IN_FIRST_OUT:
        return sorted.sort((a, b) => a.creationTime - b.creationTime);
      case CacheStrategy.LEAST_RECENTLY_USED:
        return sorted.sort((a, b) => a.lastAccessTime - b.lastAccessTime);
      case CacheStrategy.LEAST_FREQUENTLY_USED:
        return sorted.sort((a, b) => a.accessCount - b.accessCount);
      case CacheStrategy.SIZE_BASED:
        return sorted.sort((a, b) => b.size - a.size);
      case CacheStrategy.TIME_BASED:
        return sorted.sort((a, b) => a.lastAccessTime - b.lastAccessTime);
      default:
        return sorted;
    }
  }

  /**
   * 预加载媒体 Preload media
   */
  public async preloadMedia(options: PreloadOptions): Promise<void> {
    if (!this.config.enabled || !this.config.preloadEnabled) {
      return;
    }
    
    // 检查是否已缓存 Check if already cached
    const existingItem = this.findCacheItemByUrl(options.url, options.quality);
    if (existingItem && existingItem.status === CacheStatus.CACHED) {
      return;
    }
    
    // 开始预加载 Start preloading
    await this.cacheMedia({
      url: options.url,
      quality: options.quality,
      metadata: options.metadata,
      priority: options.priority
    });
  }

  /**
   * 获取下载任务 Get download task
   */
  public getDownloadTask(taskId: string): DownloadTask | null {
    const task = this.downloadTasks.get(taskId);
    return task ? { ...task } : null;
  }

  /**
   * 列出下载任务 List download tasks
   */
  public listDownloadTasks(): DownloadTask[] {
    return Array.from(this.downloadTasks.values()).map(task => ({ ...task }));
  }

  /**
   * 通知缓存更新 Notify cache update
   */
  private notifyCacheUpdate(item: CacheItem): void {
    const listeners = this.cacheListeners.get(item.id) || [];
    for (const listener of listeners) {
      try {
        listener({ ...item });
      } catch (error) {
        Logger.error(TAG, `Error in cache listener: ${error}`);
      }
    }
  }

  /**
   * 通知下载更新 Notify download update
   */
  private notifyDownloadUpdate(task: DownloadTask): void {
    const listeners = this.downloadListeners.get(task.id) || [];
    for (const listener of listeners) {
      try {
        listener({ ...task });
      } catch (error) {
        Logger.error(TAG, `Error in download listener: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  /**
   * 添加缓存监听 Add cache listener
   */
  public addCacheListener(cacheItemId: string, listener: CacheListener): void {
    if (!this.cacheListeners.has(cacheItemId)) {
      this.cacheListeners.set(cacheItemId, []);
    }
    
    this.cacheListeners.get(cacheItemId)!.push(listener);
  }

  /**
   * 移除缓存监听 Remove cache listener
   */
  public removeCacheListener(cacheItemId: string, listener: CacheListener): void {
    if (this.cacheListeners.has(cacheItemId)) {
      const listeners = this.cacheListeners.get(cacheItemId)!;
      const index = listeners.indexOf(listener);
      
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 添加下载监听 Add download listener
   */
  public addDownloadListener(taskId: string, listener: DownloadListener): void {
    if (!this.downloadListeners.has(taskId)) {
      this.downloadListeners.set(taskId, []);
    }
    
    this.downloadListeners.get(taskId)!.push(listener);
  }

  /**
   * 移除下载监听 Remove download listener
   */
  public removeDownloadListener(taskId: string, listener: DownloadListener): void {
    if (this.downloadListeners.has(taskId)) {
      const listeners = this.downloadListeners.get(taskId)!;
      const index = listeners.indexOf(listener);
      
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 关闭媒体缓存服务 Close media cache service
   */
  public async close(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    // 停止所有下载 Stop all downloads
    const activeTasks = Array.from(this.downloadTasks.values())
      .filter(task => task.status === 'downloading');
    
    for (const task of activeTasks) {
      task.status = 'paused';
      this.notifyDownloadUpdate(task);
    }
    
    this.activeTasks = 0;
    
    // 停止自动清理 Stop automatic cleanup
    this.stopAutoCleanup();
    
    // 保存数据 Save data
    await this.saveCacheItems();

    this.isInitialized = false;
    Logger.info(TAG, 'Media cache service closed');
  }
}


