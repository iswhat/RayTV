// MediaCacheService.ets - 媒体缓存服务
// 负责管理视频文件的本地缓存，包括缓存策略、清理机制和缓存统计

import Logger from '../../common/util/Logger';
import ConfigService from '../../service/config/ConfigService';
import BusinessError from '@ohos.base';

// 常量定义
const TAG = 'MediaCacheService';
const DEFAULT_CACHE_DIR = '/cache/media';

// 缓存级别枚举
export enum CacheLevel {
  LOW = 'low',           // 低缓存（仅基本信息）
  MEDIUM = 'medium',     // 中等缓存（基本信�?部分视频�?  HIGH = 'high',         // 高缓存（完整视频缓存�?  PREMIUM = 'premium'    // 高级缓存（多质量缓存�?}

// 缓存策略枚举
export enum CacheStrategy {
  FIRST_IN_FIRST_OUT = 'fifo',      // 先进先出
  LEAST_RECENTLY_USED = 'lru',      // 最近最少使�?  LEAST_FREQUENTLY_USED = 'lfu',    // 最不经常使�?  SIZE_BASED = 'size',              // 基于大小
  TIME_BASED = 'time'               // 基于时间
}

// 缓存状态枚�?export enum CacheStatus {
  NOT_CACHED = 'not_cached',        // 未缓�?  CACHING = 'caching',              // 缓存�?  CACHED = 'cached',                // 已缓�?  FAILED = 'failed',                // 缓存失败
  PARTIALLY_CACHED = 'partially_cached', // 部分缓存
  EXPIRED = 'expired'               // 已过�?}

// 缓存配置接口
export interface CacheConfig {
  enabled: boolean;               // 是否启用缓存
  maxCacheSize: number;           // 最大缓存大小（字节�?  cacheLevel: CacheLevel;         // 缓存级别
  cacheStrategy: CacheStrategy;   // 缓存策略
  autoClean: boolean;             // 自动清理
  cleanInterval: number;          // 清理间隔（秒�?  cacheExpiryDays: number;        // 缓存过期时间（天�?  wifiOnly: boolean;              // 仅WiFi缓存
  backgroundDownload: boolean;    // 后台下载
  preloadEnabled: boolean;        // 预加载启�?  preloadBufferSize: number;      // 预加载缓冲区大小
  maxConcurrentDownloads: number; // 最大并发下载数
  autoResumeDownloads: boolean;   // 自动恢复下载
  priorityHighQuality: boolean;   // 优先高质�?}

// 默认缓存配置
export const DEFAULT_CACHE_CONFIG: CacheConfig = {
  enabled: true,
  maxCacheSize: 1024 * 1024 * 1024 * 5, // 5GB
  cacheLevel: CacheLevel.MEDIUM,
  cacheStrategy: CacheStrategy.LEAST_RECENTLY_USED,
  autoClean: true,
  cleanInterval: 3600, // 1小时
  cacheExpiryDays: 7, // 7�?  wifiOnly: true,
  backgroundDownload: true,
  preloadEnabled: true,
  preloadBufferSize: 1024 * 1024 * 50, // 50MB
  maxConcurrentDownloads: 3,
  autoResumeDownloads: true,
  priorityHighQuality: false
};

// 缓存项接�?export interface CacheItem {
  id: string;                     // 缓存项ID
  url: string;                    // 媒体URL
  filePath: string;               // 本地文件路径
  fileName: string;               // 文件�?  size: number;                   // 文件大小（字节）
  downloadedSize: number;         // 已下载大�?  duration: number;               // 媒体时长（秒�?  format: string;                 // 媒体格式
  quality: string;                // 媒体质量
  mimeType: string;               // MIME类型
  status: CacheStatus;            // 缓存状�?  lastAccessTime: number;         // 最后访问时�?  creationTime: number;           // 创建时间
  accessCount: number;            // 访问次数
  sourceId: string;               // 源ID
  sourceName: string;             // 源名�?  metadata?: Record<string, string | number | boolean | null>;                 // 额外元数�?  error?: string;                 // 错误信息
}

// 缓存统计接口
export interface CacheStatistics {
  totalSize: number;              // 总缓存大�?  usedSize: number;               // 已使用大�?  freeSize: number;               // 可用大小
  itemCount: number;              // 缓存项数�?  cachedCount: number;            // 已缓存数�?  cachingCount: number;           // 缓存中数�?  failedCount: number;            // 失败数量
  expiredCount: number;           // 过期数量
  cacheHitRate: number;           // 缓存命中�?  cacheRatio: number;             // 缓存占用比例
  oldestCacheTime: number;        // 最旧缓存时�?  newestCacheTime: number;        // 最新缓存时�?}

// 下载任务接口
export interface DownloadTask {
  id: string;                     // 任务ID
  cacheItemId: string;            // 缓存项ID
  url: string;                    // 下载URL
  filePath: string;               // 保存路径
  startTime: number;              // 开始时�?  endTime?: number;               // 结束时间
  size: number;                   // 文件大小
  downloadedSize: number;         // 已下载大�?  progress: number;               // 进度�?-100�?  speed: number;                  // 下载速度（字�?秒）
  status: 'pending' | 'downloading' | 'paused' | 'completed' | 'failed' | 'canceled'; // 状�?  retries: number;                // 重试次数
  priority: number;               // 优先级（1-10�?  headers?: Record<string, string>; // 请求�?}

// 预加载选项接口
export interface PreloadOptions {
  url: string;                    // 媒体URL
  priority: number;               // 预加载优先级
  maxSize?: number;               // 最大预加载大小
  quality?: string;               // 优先质量
  metadata?: Record<string, string | number | boolean | null>;                 // 元数�?}

// 缓存查询选项接口
export interface CacheQueryOptions {
  status?: CacheStatus;           // 按状态查�?  sourceId?: string;              // 按源ID查询
  minSize?: number;               // 最小大�?  maxSize?: number;               // 最大大�?  startDate?: number;             // 开始日�?  endDate?: number;               // 结束日期
  quality?: string;               // 媒体质量
  limit?: number;                 // 限制数量
  offset?: number;                // 偏移�?  sortBy?: 'size' | 'time' | 'accessCount'; // 排序字段
  sortOrder?: 'asc' | 'desc';     // 排序顺序
}

// 缓存清理选项接口
export interface CacheCleanOptions {
  olderThanDays?: number;         // 清理指定天数前的缓存
  maxSize?: number;               // 清理到最大大小以�?  status?: CacheStatus;           // 按状态清�?  sourceId?: string;              // 按源ID清理
  quality?: string;               // 按质量清�?  exceptIds?: string[];           // 排除的ID列表
  dryRun?: boolean;               // 模拟运行
}

// 缓存监听器回调类�?type CacheListener = (item: CacheItem) => void;

// 下载监听器回调类�?type DownloadListener = (task: DownloadTask) => void;

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
  private isInitialized: boolean = false;
  private cacheHitCount: number = 0;
  private cacheMissCount: number = 0;

  /**
   * 获取单例实例
   */
  public static getInstance(): MediaCacheService {
    if (!MediaCacheService.instance) {
      MediaCacheService.instance = new MediaCacheService();
    }
    return MediaCacheService.instance;
  }

  /**
   * 构造函�?   */
  private constructor() {
    this.configService = ConfigService.getInstance();
  }

  /**
   * 初始化媒体缓存服�?   * @param context 应用上下�?   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Media cache service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing media cache service...');

      // 设置缓存目录
      this.cacheDir = this.getCacheDirectory(context);
      await this.ensureCacheDirectory();
      
      // 加载配置
      await this.loadConfig();
      
      // 加载缓存�?      await this.loadCacheItems();
      
      // 更新缓存统计
      await this.updateCacheStatistics();
      
      // 如果启用了自动清理，启动定时清理
      if (this.config.autoClean && this.config.enabled) {
        this.startAutoCleanup();
      }
      
      // 恢复未完成的下载
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
   * 获取缓存目录
   */
  private getCacheDirectory(context: Context): string {
    // 在实际应用中，应该使用系统API获取应用缓存目录
    // 这里使用临时路径模拟
    return context.cacheDir + DEFAULT_CACHE_DIR;
  }

  /**
   * 确保缓存目录存在
   */
  private async ensureCacheDirectory(): Promise<void> {
    try {
      // TODO: 使用文件API创建目录
      Logger.debug(TAG, `Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}` instanceof Error ? `Ensuring cache directory exists: ${this.cacheDir}` : new Error(String(`Ensuring cache directory exists: ${this.cacheDir}`)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to create cache directory: ${error}`);
      throw error;
    }
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('mediaCacheConfig', DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG instanceof Error ? DEFAULT_CACHE_CONFIG : new Error(String(DEFAULT_CACHE_CONFIG)))))));
      if (savedConfig) {
        this.config = { ...DEFAULT_CACHE_CONFIG, ...savedConfig };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load media cache config: ${error}`);
    }
  }

  /**
   * 保存配置
   */
  public async saveConfig(config: Partial<CacheConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('mediaCacheConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('mediaCacheConfig', this.config)))))));
      
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
      Logger.error(TAG, `Failed to save media cache config: ${error}`);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public getConfig(): CacheConfig {
    return { ...this.config };
  }

  /**
   * 加载缓存�?   */
  private async loadCacheItems(): Promise<void> {
    try {
      // 从配置中加载缓存项信�?      const savedItems = await this.configService.getConfig<CacheItem[]>('cacheItems', [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([])))))));
      
      // 验证缓存项的实际文件是否存在
      for (const item of savedItems) {
        const exists = await this.checkFileExists(item.filePath);
        
        if (exists) {
          // 更新缓存项状�?          item.status = CacheStatus.CACHED;
          this.cacheItems.set(item.id, item);
        } else {
          // 文件不存在，移除缓存�?          Logger.warn(TAG, `Cache file not found: ${item.filePath}, removing cache item`);
        }
      }
      
      Logger.info(TAG, `Loaded ${this.cacheItems.size} cache items`);
    } catch (error) {
      Logger.error(TAG, `Failed to load cache items: ${error}`);
    }
  }

  /**
   * 保存缓存�?   */
  private async saveCacheItems(): Promise<void> {
    try {
      const items = Array.from(this.cacheItems.values());
      await this.configService.setConfig('cacheItems', items instanceof Error ? items : new Error(String(items instanceof Error ? items instanceof Error ? items : new Error(String(items : new Error(String(items instanceof Error ? items : new Error(String(items instanceof Error ? items instanceof Error ? items : new Error(String(items instanceof Error ? items instanceof Error ? items : new Error(String(items : new Error(String(items instanceof Error ? items : new Error(String(items : new Error(String(items instanceof Error ? items : new Error(String(items instanceof Error ? items instanceof Error ? items : new Error(String(items : new Error(String(items instanceof Error ? items : new Error(String(items)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to save cache items: ${error}`);
    }
  }

  /**
   * 检查文件是否存�?   */
  private async checkFileExists(filePath: string): Promise<boolean> {
    try {
      // TODO: 使用文件API检查文件是否存�?      Logger.debug(TAG, `Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}` instanceof Error ? `Checking if file exists: ${filePath}` : new Error(String(`Checking if file exists: ${filePath}`)))))));
      return false; // 临时返回false，实际需要实�?    } catch (error) {
      Logger.error(TAG, `Failed to check file existence: ${error}`);
      return false;
    }
  }

  /**
   * 创建空的缓存统计对象
   */
  private createEmptyCacheStats(): CacheStatistics {
    return {
      totalSize: this.config.maxCacheSize, usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( instanceof Error ? usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now( : new Error(String(usedSize: 0,
      freeSize: this.config.maxCacheSize,
      itemCount: 0,
      cachedCount: 0,
      cachingCount: 0,
      failedCount: 0,
      expiredCount: 0,
      cacheHitRate: 0,
      cacheRatio: 0,
      oldestCacheTime: Date.now())))))),
      newestCacheTime: Date.now()
    };
  }

  /**
   * 更新缓存统计
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
      totalUsedSize += item.size;
      
      switch (item.status) {
        case CacheStatus.CACHED:
          cachedCount++;
          // 检查是否过�?          if (item.lastAccessTime < expiryTime) {
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
   * 计算缓存命中�?   */
  private calculateCacheHitRate(): number {
    const totalRequests = this.cacheHitCount + this.cacheMissCount;
    return totalRequests > 0 ? (this.cacheHitCount / totalRequests) * 100 : 0;
  }

  /**
   * 获取缓存统计
   */
  public getCacheStatistics(): CacheStatistics {
    return { ...this.cacheStats };
  }

  /**
   * 开始自动清�?   */
  private startAutoCleanup(): void {
    this.stopAutoCleanup();
    
    this.cleanTimerId = setInterval(() => {
      this.performAutoCleanup().catch(error => {
        Logger.error(TAG, `Auto cleanup failed: ${error}`);
      });
    }, this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000 instanceof Error ? this.config.cleanInterval * 1000 : new Error(String(this.config.cleanInterval * 1000)))))));
    
    Logger.info(TAG, `Auto cleanup started with interval: ${this.config.cleanInterval}s`);
  }

  /**
   * 停止自动清理
   */
  private stopAutoCleanup(): void {
    if (this.cleanTimerId !== null) {
      clearInterval(this.cleanTimerId);
      this.cleanTimerId = null;
      Logger.info(TAG, 'Auto cleanup stopped');
    }
  }

  /**
   * 执行自动清理
   */
  private async performAutoCleanup(): Promise<void> {
    if (!this.config.enabled) {
      return;
    }

    Logger.info(TAG, 'Performing auto cleanup...');
    
    // 清理过期缓存
    await this.cleanExpiredCache();
    
    // 如果缓存大小超过限制，根据策略清�?    if (this.cacheStats.usedSize > this.config.maxCacheSize) {
      const bytesToClean = this.cacheStats.usedSize - this.config.maxCacheSize;
      await this.cleanCacheByStrategy(bytesToClean);
    }
    
    // 更新统计
    await this.updateCacheStatistics();
    Logger.info(TAG, 'Auto cleanup completed');
  }

  /**
   * 清理过期缓存
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
   * 根据策略清理缓存
   */
  private async cleanCacheByStrategy(bytesToClean: number): Promise<void> {
    const cacheItems = Array.from(this.cacheItems.values())
      .filter(item => item.status !== CacheStatus.CACHING);
    
    let itemsToRemove: CacheItem[] = [];
    let cleanedBytes = 0;
    
    // 根据缓存策略排序
    let sortedItems: CacheItem[] = [];
    
    switch (this.config.cacheStrategy) {
      case CacheStrategy.FIRST_IN_FIRST_OUT:
        // 先进先出：按创建时间排序，先删除最旧的
        sortedItems = [...cacheItems].sort((a, b) => a.creationTime - b.creationTime);
        break;
      case CacheStrategy.LEAST_RECENTLY_USED:
        // 最近最少使用：按最后访问时间排�?        sortedItems = [...cacheItems].sort((a, b) => a.lastAccessTime - b.lastAccessTime);
        break;
      case CacheStrategy.LEAST_FREQUENTLY_USED:
        // 最不经常使用：按访问次数排�?        sortedItems = [...cacheItems].sort((a, b) => a.accessCount - b.accessCount);
        break;
      case CacheStrategy.SIZE_BASED:
        // 基于大小：按文件大小排序，优先删除大文件
        sortedItems = [...cacheItems].sort((a, b) => b.size - a.size);
        break;
      case CacheStrategy.TIME_BASED:
        // 基于时间：按最后访问时间排�?        sortedItems = [...cacheItems].sort((a, b) => a.lastAccessTime - b.lastAccessTime);
        break;
    }
    
    // 选择要删除的项目
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
   * 恢复未完成的下载
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
   * 缓存媒体文件
   */
  public async cacheMedia(options: {
    url: string;
    quality?: string;
    metadata?: Record<string, string | number | boolean | null>;
    priority?: number;
    headers?: Record<string, string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  } instanceof Error ? string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  } : new Error(String(string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  } instanceof Error ? string | number | boolean | null>;
    priority?: number;
    headers?: Record<string, string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  } instanceof Error ? string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  } : new Error(String(string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  } : new Error(String(string | number | boolean | null>;
    priority?: number;
    headers?: Record<string, string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  } instanceof Error ? string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  } : new Error(String(string>;
  } instanceof Error ? string>;
  } : new Error(String(string>;
  }))))))): Promise<CacheItem> {
    if (!this.config.enabled) {
      throw new Error('Media cache is disabled');
    }

    const url = options.url;
    const quality = options.quality ?? 'auto';
    const metadata = options.metadata ?? {};
    const priority = options.priority ?? 5;
    const headers = options.headers ?? {};
    
    // 生成缓存项ID
    const cacheId = this.generateCacheId(url, quality);
    
    // 检查是否已存在
    let cacheItem = this.cacheItems.get(cacheId);
    if (cacheItem) {
      // 更新访问时间和计�?      cacheItem.lastAccessTime = Date.now();
      cacheItem.accessCount++;
      cacheItem.metadata = { ...cacheItem.metadata, ...metadata };
      
      // 如果已缓存，直接返回
      if (cacheItem.status === CacheStatus.CACHED) {
        this.notifyCacheUpdate(cacheItem);
        await this.saveCacheItems();
        return cacheItem;
      }
      
      // 如果正在缓存，检查是否有对应的下载任�?      const existingTask = Array.from(this.downloadTasks.values())
        .find(task => task.cacheItemId === cacheId);
      
      if (existingTask && existingTask.status === 'downloading') {
        return cacheItem;
      }
    } else {
      // 创建新的缓存�?      const fileName = this.generateFileName(url, quality);
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
    
    // 创建下载任务
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
    
    // 更新缓存项状�?    cacheItem.status = CacheStatus.CACHING;
    this.notifyCacheUpdate(cacheItem);
    
    // 启动下载任务
    this.startDownloadTask(downloadTask);
    
    // 保存缓存�?    await this.saveCacheItems();
    
    return cacheItem;
  }

  /**
   * 生成缓存ID
   */
  private generateCacheId(url: string, quality: string): string {
    // 简单实现：使用URL和质量的哈希作为ID
    // 实际应用中应该使用更安全的哈希算�?    let hash = 0;
    const data = url + quality;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash |= 0; // 转换�?2位整�?    }
    return `cache_${hash.toString(16)}`;
  }

  /**
   * 生成文件�?   */
  private generateFileName(url: string, quality: string): string {
    const timestamp = Date.now();
    const format = this.getFileFormat(url);
    const safeName = this.sanitizeFileName(url.substring(url.lastIndexOf('/') + 1, url.lastIndexOf('.')));
    return `${safeName}_${quality}_${timestamp}.${format}`;
  }

  /**
   * 清理文件�?   */
  private sanitizeFileName(name: string): string {
    // 移除不安全的字符
    return name.replace(/[<>"/\|?*]/g, '_').substring(0, 50);
  }

  /**
   * 获取文件格式
   */
  private getFileFormat(url: string): string {
    const match = url.match(/\.([^.]+)$/);
    return match ? match[1].toLowerCase() : 'mp4';
  }

  /**
   * 获取MIME类型
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
   * 启动下载任务
   */
  private async startDownloadTask(task: DownloadTask): Promise<void> {
    // 检查是否达到最大并发下载数
    if (this.activeTasks >= this.config.maxConcurrentDownloads) {
      // 添加到待处理队列
      this.pendingTasks.push(task);
      Logger.info(TAG, `Task ${task.id} added to pending queue`);
      return;
    }
    
    // 更新任务状�?    task.status = 'downloading';
    this.activeTasks++;
    
    // 通知任务更新
    this.notifyDownloadUpdate(task);
    
    try {
      // TODO: 实现实际的下载逻辑
      // 这里需要使用网络API下载文件
      Logger.info(TAG, `Starting download task ${task.id}: ${task.url}`);
      
      // 模拟下载过程
      await this.simulateDownload(task);
      
      // 下载完成
      task.status = 'completed';
      task.endTime = Date.now();
      task.progress = 100;
      
      // 更新缓存�?      const cacheItem = this.cacheItems.get(task.cacheItemId);
      if (cacheItem) {
        cacheItem.status = CacheStatus.CACHED;
        cacheItem.size = task.size;
        cacheItem.downloadedSize = task.downloadedSize;
        this.notifyCacheUpdate(cacheItem);
        
        // 更新统计
        await this.updateCacheStatistics();
        await this.saveCacheItems();
      }
      
    } catch (error) {
      Logger.error(TAG, `Download task ${task.id} failed: ${error}`);
      
      task.status = 'failed';
      task.endTime = Date.now();
      task.retries++;
      
      // 更新缓存�?      const cacheItem = this.cacheItems.get(task.cacheItemId);
      if (cacheItem) {
        cacheItem.status = CacheStatus.FAILED;
        cacheItem.error = String(error);
        this.notifyCacheUpdate(cacheItem);
      }
      
      // 如果重试次数未达到限制，重新尝试
      if (task.retries < 3) {
        setTimeout(() => {
          this.retryDownloadTask(task);
        }, 5000 instanceof Error ? 5000 : new Error(String(5000 instanceof Error ? 5000 instanceof Error ? 5000 : new Error(String(5000 : new Error(String(5000 instanceof Error ? 5000 : new Error(String(5000 instanceof Error ? 5000 instanceof Error ? 5000 : new Error(String(5000 instanceof Error ? 5000 instanceof Error ? 5000 : new Error(String(5000 : new Error(String(5000 instanceof Error ? 5000 : new Error(String(5000 : new Error(String(5000 instanceof Error ? 5000 : new Error(String(5000 instanceof Error ? 5000 instanceof Error ? 5000 : new Error(String(5000 : new Error(String(5000 instanceof Error ? 5000 : new Error(String(5000)))))));
      }
    } finally {
      this.activeTasks--;
      this.notifyDownloadUpdate(task);
      
      // 处理下一个待处理任务
      this.processNextPendingTask();
      
      // 如果任务已完成或失败，从活动任务中移�?      if (task.status === 'completed' || task.status === 'failed') {
        setTimeout(() => {
          this.downloadTasks.delete(task.id);
        }, 60000); // 1分钟后移�?      }
    }
  }

  /**
   * 模拟下载过程
   */
  private async simulateDownload(task: DownloadTask): Promise<void> {
    // 模拟随机文件大小�?0MB - 500MB�?    const fileSize = Math.floor(Math.random() * 490 * 1024 * 1024) + 10 * 1024 * 1024;
    task.size = fileSize;
    
    let downloaded = task.downloadedSize;
    const chunkSize = 1024 * 1024; // 1MB chunks
    const startTime = Date.now();
    
    while (downloaded < fileSize) {
      // 模拟下载进度
      const chunkDownloaded = Math.min(chunkSize, fileSize - downloaded);
      downloaded += chunkDownloaded;
      
      // 更新任务
      task.downloadedSize = downloaded;
      task.progress = Math.round((downloaded / fileSize) * 100);
      
      // 计算速度
      const elapsed = (Date.now() - startTime) / 1000; // �?      task.speed = elapsed > 0 ? (downloaded / elapsed) : 0;
      
      // 通知更新
      this.notifyDownloadUpdate(task);
      
      // 短暂延迟模拟网络下载
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }

  /**
   * 重试下载任务
   */
  private retryDownloadTask(task: DownloadTask): void {
    Logger.info(TAG, `Retrying download task ${task.id} (attempt ${task.retries}/3)`);
    this.startDownloadTask(task);
  }

  /**
   * 处理下一个待处理任务
   */
  private processNextPendingTask(): void {
    if (this.pendingTasks.length === 0 || this.activeTasks >= this.config.maxConcurrentDownloads) {
      return;
    }
    
    // 按优先级排序
    this.pendingTasks.sort((a, b) => b.priority - a.priority);
    
    // 取出下一个任�?    const nextTask = this.pendingTasks.shift();
    if (nextTask) {
      this.startDownloadTask(nextTask);
    }
  }

  /**
   * 暂停下载
   */
  public async pauseDownload(cacheItemId: string): Promise<void> {
    const task = Array.from(this.downloadTasks.values())
      .find(t => t.cacheItemId === cacheItemId && t.status === 'downloading');
    
    if (task) {
      task.status = 'paused';
      this.notifyDownloadUpdate(task);
      
      // 从活动任务中减少计数
      this.activeTasks--;
      
      // 处理下一个任�?      this.processNextPendingTask();
      
      // 更新缓存项状�?      const cacheItem = this.cacheItems.get(cacheItemId);
      if (cacheItem) {
        cacheItem.status = CacheStatus.PARTIALLY_CACHED;
        cacheItem.downloadedSize = task.downloadedSize;
        this.notifyCacheUpdate(cacheItem);
        await this.saveCacheItems();
      }
    }
  }

  /**
   * 恢复下载
   */
  public async resumeDownload(cacheItemId: string): Promise<void> {
    const task = Array.from(this.downloadTasks.values())
      .find(t => t.cacheItemId === cacheItemId && t.status === 'paused');
    
    if (task) {
      this.startDownloadTask(task);
    } else {
      // 如果任务不存在，重新创建
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
   * 取消下载
   */
  public async cancelDownload(cacheItemId: string): Promise<void> {
    const task = Array.from(this.downloadTasks.values())
      .find(t => t.cacheItemId === cacheItemId && 
            (t.status === 'downloading' || t.status === 'paused' || t.status === 'pending'));
    
    if (task) {
      task.status = 'canceled';
      this.notifyDownloadUpdate(task);
      
      // 如果正在下载，减少活动任务计�?      if (task.status === 'downloading') {
        this.activeTasks--;
        this.processNextPendingTask();
      }
      
      // 从待处理队列中移�?      const pendingIndex = this.pendingTasks.findIndex(t => t.id === task.id);
      if (pendingIndex > -1) {
        this.pendingTasks.splice(pendingIndex, 1);
      }
      
      // 更新缓存�?      const cacheItem = this.cacheItems.get(cacheItemId);
      if (cacheItem) {
        cacheItem.status = CacheStatus.NOT_CACHED;
        cacheItem.downloadedSize = 0;
        this.notifyCacheUpdate(cacheItem);
        await this.saveCacheItems();
      }
      
      // 删除临时文件
      await this.deleteFile(task.filePath);
    }
  }

  /**
   * 删除文件
   */
  private async deleteFile(filePath: string): Promise<void> {
    try {
      // TODO: 使用文件API删除文件
      Logger.debug(TAG, `Deleting file: ${filePath}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete file ${filePath}: ${error}`);
    }
  }

  /**
   * 获取缓存�?   */
  public getCacheItem(cacheItemId: string): CacheItem | null {
    const item = this.cacheItems.get(cacheItemId);
    if (item) {
      // 更新访问时间和计�?      item.lastAccessTime = Date.now();
      item.accessCount++;
      this.notifyCacheUpdate(item);
      this.cacheHitCount++;
      return { ...item };
    }
    
    this.cacheMissCount++;
    return null;
  }

  /**
   * 通过URL查找缓存�?   */
  public findCacheItemByUrl(url: string, quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string instanceof Error ? quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string : new Error(String(quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string instanceof Error ? quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string instanceof Error ? quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string : new Error(String(quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string : new Error(String(quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string instanceof Error ? quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string : new Error(String(quality?: string instanceof Error ? quality?: string : new Error(String(quality?: string))))))): CacheItem | null {
    const cacheId = this.generateCacheId(url, quality || 'auto');
    return this.getCacheItem(cacheId);
  }

  /**
   * 列出缓存�?   */
  public listCacheItems(options?: CacheQueryOptions): CacheItem[] {
    let items = Array.from(this.cacheItems.values());
    
    // 应用过滤条件
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
    
    // 应用排序
    if (options?.sortBy) {
      items.sort((a, b) => {
        let aValue: Record<string, string | number | boolean | null>;
  let bValue: Record<string, string | number | boolean | null>;
        
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
    
    // 应用分页
    if (options?.offset !== undefined) {
      items = items.slice(options.offset);
    }
    
    if (options?.limit !== undefined) {
      items = items.slice(0, options.limit);
    }
    
    return items.map(item => ({ ...item }));
  }

  /**
   * 移除缓存�?   */
  public async removeCacheItems(cacheItemIds: string[]): Promise<void> {
    for (const id of cacheItemIds) {
      const item = this.cacheItems.get(id);
      if (item) {
        // 取消相关下载任务
        await this.cancelDownload(id);
        
        // 删除文件
        await this.deleteFile(item.filePath);
        
        // 从缓存项列表中移�?        this.cacheItems.delete(id);
        
        Logger.info(TAG, `Removed cache item: ${id}`);
      }
    }
    
    // 更新统计
    await this.updateCacheStatistics();
    await this.saveCacheItems();
  }

  /**
   * 清理缓存
   */
  public async cleanCache(options?: CacheCleanOptions): Promise<number> {
    if (!this.config.enabled) {
      return 0;
    }
    
    let itemsToRemove: CacheItem[] = [];
    const allItems = Array.from(this.cacheItems.values());
    
    // 应用清理选项
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
        // 根据缓存策略清理到指定大�?        const bytesToClean = this.cacheStats.usedSize - options.maxSize;
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
      // 清理所有缓�?      itemsToRemove = allItems;
    }
    
    // 排除指定的ID
    if (options?.exceptIds) {
      itemsToRemove = itemsToRemove.filter(item => !options.exceptIds!.includes(item.id));
    }
    
    // 去重
    const uniqueItems = itemsToRemove.filter((item, index, self) =>
      index === self.findIndex(i => i.id === item.id)
    );
    
    // 检查是否为模拟运行
    if (options?.dryRun) {
      Logger.info(TAG, `Dry run: would remove ${uniqueItems.length} cache items`);
      return uniqueItems.length;
    }
    
    // 执行清理
    if (uniqueItems.length > 0) {
      await this.removeCacheItems(uniqueItems.map(item => item.id));
    }
    
    return uniqueItems.length;
  }

  /**
   * 清空所有缓�?   */
  public async clearAllCache(): Promise<void> {
    await this.cleanCache();
    Logger.info(TAG, 'All cache cleared');
  }

  /**
   * 根据策略排序缓存�?   */
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
   * 预加载媒�?   */
  public async preloadMedia(options: PreloadOptions): Promise<void> {
    if (!this.config.enabled || !this.config.preloadEnabled) {
      return;
    }
    
    // 检查是否已缓存
    const existingItem = this.findCacheItemByUrl(options.url, options.quality);
    if (existingItem && existingItem.status === CacheStatus.CACHED) {
      return;
    }
    
    // 开始预加载
    await this.cacheMedia({
      url: options.url,
      quality: options.quality,
      metadata: options.metadata,
      priority: options.priority
    });
  }

  /**
   * 获取下载任务
   */
  public getDownloadTask(taskId: string): DownloadTask | null {
    const task = this.downloadTasks.get(taskId);
    return task ? { ...task } : null;
  }

  /**
   * 列出下载任务
   */
  public listDownloadTasks(): DownloadTask[] {
    return Array.from(this.downloadTasks.values()).map(task => ({ ...task }));
  }

  /**
   * 通知缓存更新
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
   * 通知下载更新
   */
  private notifyDownloadUpdate(task: DownloadTask): void {
    const listeners = this.downloadListeners.get(task.id) || [];
    for (const listener of listeners) {
      try {
        listener({ ...task });
      } catch (error) {
        Logger.error(TAG, `Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}` instanceof Error ? `Error in download listener: ${error}` : new Error(String(`Error in download listener: ${error}`)))))));
      }
    }
  }

  /**
   * 添加缓存监听
   */
  public addCacheListener(cacheItemId: string, listener: CacheListener): void {
    if (!this.cacheListeners.has(cacheItemId)) {
      this.cacheListeners.set(cacheItemId, []);
    }
    
    this.cacheListeners.get(cacheItemId)!.push(listener);
  }

  /**
   * 移除缓存监听
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
   * 添加下载监听
   */
  public addDownloadListener(taskId: string, listener: DownloadListener): void {
    if (!this.downloadListeners.has(taskId)) {
      this.downloadListeners.set(taskId, []);
    }
    
    this.downloadListeners.get(taskId)!.push(listener);
  }

  /**
   * 移除下载监听
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
   * 关闭媒体缓存服务
   */
  public async close(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    // 停止所有下�?    const activeTasks = Array.from(this.downloadTasks.values())
      .filter(task => task.status === 'downloading');
    
    for (const task of activeTasks) {
      task.status = 'paused';
      this.notifyDownloadUpdate(task);
    }
    
    this.activeTasks = 0;
    
    // 停止自动清理
    this.stopAutoCleanup();
    
    // 保存数据
    await this.saveCacheItems();

    this.isInitialized = false;
    Logger.info(TAG, 'Media cache service closed');
  }
}


