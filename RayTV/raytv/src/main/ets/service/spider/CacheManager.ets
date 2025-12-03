import Logger from '../../common/util/Logger';
import FileSystemManager from '@ohos.file.fs';

/**
 * 缓存项接�? */
export interface CacheItem {
  data: Record<string, string | number | boolean | null> | string | number | boolean | null;
  timestamp: number;
  expiry: number;
  size: number;
}

/**
 * 缓存配置接口
 */
export interface CacheConfig {
  maxSize?: number; // 最大缓存大小（字节�?  defaultExpiry?: number; // 默认过期时间（毫秒）
  cleanupInterval?: number; // 清理间隔（毫秒）
  enabled?: boolean; // 是否启用缓存
}

/**
 * 缓存管理�? * 实现爬虫结果的本地缓存，支持缓存过期策略和清理机�? */
export class CacheManager {
  private readonly TAG: string = 'CacheManager';
  private static instance: CacheManager | null = null;
  private memoryCache: Map<string, CacheItem> = new Map();
  private fsManager: FileSystemManager;
  private cacheDir: string = '';
  private config: CacheConfig;
  private totalSize: number = 0;
  private cleanupTimer: number | null = null;

  /**
   * 默认缓存配置
   */
  private static readonly DEFAULT_CONFIG: CacheConfig = {
    maxSize: 100 * 1024 * 1024, // 100MB
    defaultExpiry: 3600 * 1000, // 1小时
    cleanupInterval: 300000, // 5分钟
    enabled: true
  };

  /**
   * 获取单例实例
   * @returns CacheManager
   */
  public static getInstance(): CacheManager {
    if (!CacheManager.instance) {
      CacheManager.instance = new CacheManager();
    }
    return CacheManager.instance;
  }

  /**
   * 构造函�?   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.fsManager = FileSystemManager.getFileSystemManager();
    // 避免对象展开操作符，显式赋值确保类型安�?    this.config = {
      maxSize: CacheManager.DEFAULT_CONFIG.maxSize,
      defaultExpiry: CacheManager.DEFAULT_CONFIG.defaultExpiry,
      cleanupInterval: CacheManager.DEFAULT_CONFIG.cleanupInterval,
      enabled: CacheManager.DEFAULT_CONFIG.enabled
    };
    this.initialize();
    Logger.info(this.TAG, 'CacheManager initialized');
  }

  /**
   * 初始化缓存管理器
   * @private
   */
  private initialize(): void {
    try {
      // 设置缓存目录
      this.cacheDir = this.getCacheDirectory();
      
      // 确保缓存目录存在
      if (!this.fsManager.existsSync(this.cacheDir)) {
        this.fsManager.mkdirSync(this.cacheDir, { recursive: true });
        Logger.info(this.TAG, `Created cache directory: ${this.cacheDir}`);
      }
      
      // 启动定期清理
      this.startCleanupTimer();
      
      // 初始清理
      this.cleanupExpiredCache();
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize cache manager: ${error}`);
    }
  }

  /**
   * 设置缓存配置
   * @param config 缓存配置
   */
  public setConfig(config: CacheConfig): void {
    // 避免对象展开操作符，显式合并配置确保类型安全
    this.config = {
      maxSize: config.maxSize !== null && config.maxSize !== undefined ? config.maxSize : this.config.maxSize, defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config instanceof Error ? defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config : new Error(String(defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config)))))))}`);
    
    // 重新启动清理定时�?    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
    }
    this.startCleanupTimer();
    
    // 如果缓存大小超限，立即清�?    this.cleanupExcessCache();
  }

  /**
   * 获取缓存
   * @param key 缓存�?   * @returns 缓存数据或null
   */
  public get(key: string): Record<string, string | number | boolean | null> | string | number | boolean | null {
    if (!this.config.enabled) {
      return null;
    }

    try {
      // 首先从内存缓存中获取
      const cacheItem = this.memoryCache.get(key);
      
      if (cacheItem) {
        // 检查是否过�?        if (!this.isExpired(cacheItem)) {
          Logger.debug(this.TAG, `Cache hit for key: ${key} (memory)`);
          return cacheItem.data;
        } else {
          // 过期则移�?          this.remove(key);
        }
      }
      
      // 从文件系统获�?      const filePath = this.getCacheFilePath(key);
      if (this.fsManager.existsSync(filePath)) {
        const fileContent = this.fsManager.readTextSync(filePath) as string;
        const fileCacheItem: CacheItem = JSON.parse(fileContent) as CacheItem;
        
        // 检查是否过�?        if (!this.isExpired(fileCacheItem)) {
          // 加载到内存缓�?          this.memoryCache.set(key, fileCacheItem);
          Logger.debug(this.TAG, `Cache hit for key: ${key} (disk)`);
          return fileCacheItem.data;
        } else {
          // 过期则删除文�?          this.fsManager.unlinkSync(filePath);
        }
      }
      
      Logger.debug(this.TAG, `Cache miss for key: ${key}`);
      return null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get cache for key ${key}: ${error}`);
      return null;
    }
  }

  /**
   * 设置缓存
   * @param key 缓存�?   * @param data 缓存数据
   * @param expiry 过期时间（毫秒，可选）
   * @returns boolean
   */
  public set(key: string, data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number instanceof Error ? data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number : new Error(String(data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number))))))): boolean {
    if (!this.config.enabled) {
      return false;
    }

    try {
      const expiryTime = expiry || this.config.defaultExpiry!;
      const dataString = JSON.stringify(data);
      const size = dataString.length;
      
      // 检查数据大小是否超过限�?      if (size > this.config.maxSize! * 0.1) { // 不缓存超过最大缓�?0%的数�?        Logger.warn(this.TAG, `Data too large for caching: ${size} bytes`);
        return false;
      }
      
      const cacheItem: CacheItem = {
        data,
        timestamp: Date.now(),
        expiry: expiryTime,
        size
      };
      
      // 更新总大�?      this.updateTotalSize(key, size);
      
      // 保存到内存缓�?      this.memoryCache.set(key, cacheItem);
      
      // 保存到文件系�?      const filePath = this.getCacheFilePath(key);
      this.fsManager.writeTextSync(filePath, JSON.stringify(cacheItem));
      
      // 检查并清理超出大小限制的缓�?      this.cleanupExcessCache();
      
      Logger.debug(this.TAG, `Cached data for key: ${key}, size: ${size} bytes, expiry: ${expiryTime}ms`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to set cache for key ${key}: ${error}`);
      return false;
    }
  }

  /**
   * 移除缓存
   * @param key 缓存�?   * @returns boolean
   */
  public remove(key: string): boolean {
    try {
      // 从内存缓存移�?      const cacheItem = this.memoryCache.get(key);
      if (cacheItem) {
        this.totalSize -= cacheItem.size;
        this.memoryCache.delete(key);
      }
      
      // 从文件系统移�?      const filePath = this.getCacheFilePath(key);
      if (this.fsManager.existsSync(filePath)) {
        this.fsManager.unlinkSync(filePath);
      }
      
      Logger.debug(this.TAG, `Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}` instanceof Error ? `Removed cache for key: ${key}` : new Error(String(`Removed cache for key: ${key}`)))))));
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to remove cache for key ${key}: ${error}`);
      return false;
    }
  }

  /**
   * 清空所有缓�?   * @returns boolean
   */
  public clear(): boolean {
    try {
      // 清空内存缓存
      this.memoryCache.clear();
      this.totalSize = 0;
      
      // 清空文件系统缓存
      if (this.fsManager.existsSync(this.cacheDir)) {
        const files = this.fsManager.listSync(this.cacheDir) as string[];
        if (files) {
          for (let i = 0; i < files.length; i++) {
            const file = files[i];
            const filePath = `${this.cacheDir}/${file}`;
            try {
              // 直接删除文件，不检查文件类�?              this.fsManager.unlinkSync(filePath);
            } catch (error) {
              // 如果删除失败，忽略并继续
              Logger.warn(this.TAG, `Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}` instanceof Error ? `Failed to delete cache file: ${filePath}, error: ${error}` : new Error(String(`Failed to delete cache file: ${filePath}, error: ${error}`)))))));
            }
          }
        }
      }
      
      Logger.info(this.TAG, 'All cache cleared');
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear cache: ${error}`);
      return false;
    }
  }

  /**
   * 清空站点相关的所有缓�?   * @param siteKey 站点唯一标识
   * @returns boolean
   */
  public clearSiteCache(siteKey: string): boolean {
    try {
      const keysToRemove: string[] = [];
      
      // 找出站点相关的缓存键
      for (const key of this.memoryCache.keys()) {
        if (key.startsWith(`${siteKey}:`)) {
          keysToRemove.push(key);
        }
      }
      
      // 移除内存缓存
      for (const key of keysToRemove) {
        this.remove(key);
      }
      
      // 移除文件系统中的缓存
      const files = this.fsManager.listSync(this.cacheDir) as string[];
      if (files) {
        for (const file of files) {
          if (file.startsWith(`${this.getCacheKeyHash(`${siteKey}:`)}_`)) {
            this.fsManager.unlinkSync(`${this.cacheDir}/${file}`);
          }
        }
      }
      
      Logger.info(this.TAG, `Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}` instanceof Error ? `Cleared cache for site: ${siteKey}` : new Error(String(`Cleared cache for site: ${siteKey}`)))))));
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear site cache for ${siteKey}: ${error}`);
      return false;
    }
  }

  /**
   * 获取缓存大小
   * @returns number 缓存大小（字节）
   */
  public getCacheSize(): number {
    return this.totalSize;
  }

  /**
   * 获取缓存项数�?   * @returns number
   */
  public getCacheCount(): number {
    return this.memoryCache.size;
  }

  /**
   * 检查缓存是否存在且未过�?   * @param key 缓存�?   * @returns boolean
   */
  public has(key: string): boolean {
    return this.get(key) !== null;
  }

  /**
   * 生成爬虫方法的缓存键
   * @param siteKey 站点唯一标识
   * @param method 方法名称
   * @param params 方法参数
   * @returns string
   */
  public generateCacheKey(siteKey: string, method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null instanceof Error ? method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null : new Error(String(method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null))))))): string {
    // 生成参数的哈希�?    const paramsHash = this.generateParamsHash(params);
    return `${siteKey}:${method}:${paramsHash}`;
  }

  /**
   * 启动清理定时�?   * @private
   */
  private startCleanupTimer(): void {
    if (this.config.enabled && this.config.cleanupInterval) {
      this.cleanupTimer = setInterval(() => {
        this.cleanupExpiredCache();
      }, this.config.cleanupInterval);
      
      Logger.info(this.TAG, `Cleanup timer started with interval: ${this.config.cleanupInterval}ms`);
    }
  }

  /**
   * 清理过期缓存
   * @private
   */
  private cleanupExpiredCache(): void {
    try {
      const keysToRemove: string[] = [];
      const currentTime = Date.now();
      
      // 清理内存缓存 - 使用普通变量声明替代解�?      const entries = this.memoryCache.entries();
      let entry = entries.next();
      while (!entry.done) {
        const key = entry.value[0];
        const item = entry.value[1];
        if (currentTime > item.timestamp + item.expiry) {
          keysToRemove.push(key);
          this.totalSize -= item.size;
        }
        entry = entries.next();
      }
      
      for (const key of keysToRemove) {
        this.memoryCache.delete(key);
        // 同时删除文件系统中的缓存
        const filePath = this.getCacheFilePath(key);
        if (this.fsManager.existsSync(filePath)) {
          this.fsManager.unlinkSync(filePath);
        }
      }
      
      if (keysToRemove.length > 0) {
        Logger.info(this.TAG, `Cleaned ${keysToRemove.length} expired cache items`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to cleanup expired cache: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 清理超出大小限制的缓�?   * @private
   */
  private cleanupExcessCache(): void {
    if (this.totalSize > this.config.maxSize!) {
      try {
        // 按时间排序缓存项 - 使用普通函数替代解�?        const sortedItems = Array.from(this.memoryCache.entries())
          .sort((entryA, entryB instanceof Error ? entryB : new Error(String(entryB instanceof Error ? entryB instanceof Error ? entryB : new Error(String(entryB : new Error(String(entryB instanceof Error ? entryB : new Error(String(entryB instanceof Error ? entryB instanceof Error ? entryB : new Error(String(entryB instanceof Error ? entryB instanceof Error ? entryB : new Error(String(entryB : new Error(String(entryB instanceof Error ? entryB : new Error(String(entryB : new Error(String(entryB instanceof Error ? entryB : new Error(String(entryB instanceof Error ? entryB instanceof Error ? entryB : new Error(String(entryB : new Error(String(entryB instanceof Error ? entryB : new Error(String(entryB))))))) => {
            const a = entryA[1];
            const b = entryB[1];
            return a.timestamp - b.timestamp;
          });
        
        // 移除最旧的缓存项，直到总大小在限制�?        let removedSize = 0;
        let removedCount = 0;
        
        // 使用普通变量声明替代解�?        for (const entry of sortedItems) {
          const key = entry[0];
          const item = entry[1];
          if (this.totalSize - removedSize <= this.config.maxSize! * 0.8) { // 保留20%的空�?            break;
          }
          
          this.memoryCache.delete(key);
          removedSize += item.size;
          removedCount++;
          
          // 删除文件系统中的缓存
          const filePath = this.getCacheFilePath(key);
          if (this.fsManager.existsSync(filePath)) {
            this.fsManager.unlinkSync(filePath);
          }
        }
        
        this.totalSize -= removedSize;
        Logger.info(this.TAG, `Cleaned ${removedCount} excess cache items, freed ${removedSize} bytes`);
      } catch (error) {
        Logger.error(this.TAG, `Failed to cleanup excess cache: ${error}`);
      }
    }
  }

  /**
   * 检查缓存项是否过期
   * @param item 缓存�?   * @returns boolean
   * @private
   */
  private isExpired(item: CacheItem): boolean {
    return Date.now() > item.timestamp + item.expiry;
  }

  /**
   * 更新总缓存大�?   * @param key 缓存�?   * @param newSize 新的大小
   * @private
   */
  private updateTotalSize(key: string, newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number instanceof Error ? newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number : new Error(String(newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number instanceof Error ? newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number instanceof Error ? newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number : new Error(String(newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number : new Error(String(newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number instanceof Error ? newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number : new Error(String(newSize: number instanceof Error ? newSize: number : new Error(String(newSize: number))))))): void {
    const existingItem = this.memoryCache.get(key);
    if (existingItem) {
      this.totalSize -= existingItem.size;
    }
    this.totalSize += newSize;
  }

  /**
   * 获取缓存目录
   * @returns string
   * @private
   */
  private getCacheDirectory(): string {
    // 使用应用缓存目录
    return `/cache/raytv/spider`;
  }

  /**
   * 获取缓存文件路径
   * @param key 缓存�?   * @returns string
   * @private
   */
  private getCacheFilePath(key: string): string {
    const keyHash = this.getCacheKeyHash(key);
    return `${this.cacheDir}/${keyHash}_${Date.now()}.cache`;
  }

  /**
   * 获取缓存键的哈希�?   * @param key 缓存�?   * @returns string
   * @private
   */
  private getCacheKeyHash(key: string): string {
    return this.generateHash(key);
  }

  /**
   * 生成参数的哈希�?   * @param params 方法参数
   * @returns string
   * @private
   */
  private generateParamsHash(params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null): string {
    try {
      const sortedParams = this.sortParams(params);
      return this.generateHash(JSON.stringify(sortedParams));
    } catch (error) {
      Logger.error(this.TAG, `Failed to generate params hash: ${error}`);
      return 'error';
    }
  }
  
  /**
   * 简单的字符串哈希生成函�?   * @param str 输入字符�?   * @returns 哈希值字符串
   * @private
   */
  private generateHash(str: string): string {
    let hash = 0;
    if (str.length === 0) return hash.toString();
    
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换�?2位整�?    }
    
    // 转换�?6进制字符�?    return Math.abs(hash).toString(16);
  }

  /**
   * 获取对象的所有键
   * @param obj 输入对象
   * @returns 键数�?   * @private
   */
  private getObjectKeys(obj: Record<string, string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null> instanceof Error ? string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null> : new Error(String(string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null> instanceof Error ? string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null> instanceof Error ? string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null> : new Error(String(string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null> : new Error(String(string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null> instanceof Error ? string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null> : new Error(String(string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null>))))))): string[] {
    // 直接使用Object.keys获取键，避免for-in循环和原型链操作
    return Object.keys(obj);
  }

  /**
   * 排序参数对象，确保相同内容的参数生成相同的哈希�?   * @param params 方法参数
   * @returns 排序后的参数
   * @private
   */
  private sortParams(params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null): Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null {
    // 处理基本类型和null
    if (typeof params !== 'object' || params === null) {
      return params;
    }
    
    // 处理数组
    if (Array.isArray(params)) {
      // 确保类型安全，避免unknown类型的递归
      const typedArray = params as (string | number | boolean | null)[];
      return typedArray.map(item => {
        // 仅对对象类型进行递归排序
        if (typeof item === 'object' && item !== null) {
          if (Array.isArray(item)) {
            return this.sortParams(item as string[] | number[] | boolean[]);
          } else {
            return this.sortParams(item as Record<string, string | number | boolean | null>);
          }
        }
        return item;
      }) as string[] | number[] | boolean[];
    }
    
    // 处理对象
    const sorted: Record<string, string | number | boolean | null> = {};
    const paramObj = params as Record<string, string | number | boolean | null>;
    
    this.getObjectKeys(paramObj).sort().forEach(key => {
      const value = paramObj[key];
      // 仅对对象类型进行递归排序
      if (typeof value === 'object' && value !== null) {
        if (Array.isArray(value)) {
          sorted[key] = this.sortParams(value as string[] | number[] | boolean[]);
        } else {
          sorted[key] = this.sortParams(value as Record<string, string | number | boolean | null>);
        }
      } else {
        sorted[key] = value;
      }
    });
    
    return sorted;
  }
}


