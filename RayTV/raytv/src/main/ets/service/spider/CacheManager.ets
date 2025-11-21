import Logger from '../../common/util/Logger';
import FileSystemManager from '@ohos.file.fs';

/**
 * 缓存项接口
 */
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
  maxSize?: number; // 最大缓存大小（字节）
  defaultExpiry?: number; // 默认过期时间（毫秒）
  cleanupInterval?: number; // 清理间隔（毫秒）
  enabled?: boolean; // 是否启用缓存
}

/**
 * 缓存管理器
 * 实现爬虫结果的本地缓存，支持缓存过期策略和清理机制
 */
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
   * 构造函数
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.fsManager = FileSystemManager.getFileSystemManager();
    // 避免对象展开操作符，显式赋值确保类型安全
    this.config = {
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
      maxSize: config.maxSize !== null && config.maxSize !== undefined ? config.maxSize : this.config.maxSize,
      defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config: ${JSON.stringify(this.config)}`);
    
    // 重新启动清理定时器
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
    }
    this.startCleanupTimer();
    
    // 如果缓存大小超限，立即清理
    this.cleanupExcessCache();
  }

  /**
   * 获取缓存
   * @param key 缓存键
   * @returns 缓存数据或null
   */
  public get(key: string): Record<string, string | number | boolean | null> | string | number | boolean | null {
    if (!this.config.enabled) {
      return null;
    }

    try {
      // 首先从内存缓存中获取
      const cacheItem = this.memoryCache.get(key);
      
      if (cacheItem) {
        // 检查是否过期
        if (!this.isExpired(cacheItem)) {
          Logger.debug(this.TAG, `Cache hit for key: ${key} (memory)`);
          return cacheItem.data;
        } else {
          // 过期则移除
          this.remove(key);
        }
      }
      
      // 从文件系统获取
      const filePath = this.getCacheFilePath(key);
      if (this.fsManager.existsSync(filePath)) {
        const fileContent = this.fsManager.readTextSync(filePath);
        const fileCacheItem: CacheItem = JSON.parse(fileContent);
        
        // 检查是否过期
        if (!this.isExpired(fileCacheItem)) {
          // 加载到内存缓存
          this.memoryCache.set(key, fileCacheItem);
          Logger.debug(this.TAG, `Cache hit for key: ${key} (disk)`);
          return fileCacheItem.data;
        } else {
          // 过期则删除文件
          this.fsManager.unlinkSync(filePath);
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
   * @param key 缓存键
   * @param data 缓存数据
   * @param expiry 过期时间（毫秒，可选）
   * @returns boolean
   */
  public set(key: string, data: Record<string, string | number | boolean | null> | string | number | boolean | null, expiry?: number): boolean {
    if (!this.config.enabled) {
      return false;
    }

    try {
      const expiryTime = expiry || this.config.defaultExpiry!;
      const dataString = JSON.stringify(data);
      const size = dataString.length;
      
      // 检查数据大小是否超过限制
      if (size > this.config.maxSize! * 0.1) { // 不缓存超过最大缓存10%的数据
        Logger.warn(this.TAG, `Data too large for caching: ${size} bytes`);
        return false;
      }
      
      const cacheItem: CacheItem = {
        data,
        timestamp: Date.now(),
        expiry: expiryTime,
        size
      };
      
      // 更新总大小
      this.updateTotalSize(key, size);
      
      // 保存到内存缓存
      this.memoryCache.set(key, cacheItem);
      
      // 保存到文件系统
      const filePath = this.getCacheFilePath(key);
      this.fsManager.writeTextSync(filePath, JSON.stringify(cacheItem));
      
      // 检查并清理超出大小限制的缓存
      this.cleanupExcessCache();
      
      Logger.debug(this.TAG, `Cached data for key: ${key}, size: ${size} bytes, expiry: ${expiryTime}ms`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to set cache for key ${key}: ${error}`);
      return false;
    }
  }

  /**
   * 移除缓存
   * @param key 缓存键
   * @returns boolean
   */
  public remove(key: string): boolean {
    try {
      // 从内存缓存移除
      const cacheItem = this.memoryCache.get(key);
      if (cacheItem) {
        this.totalSize -= cacheItem.size;
        this.memoryCache.delete(key);
      }
      
      // 从文件系统移除
      const filePath = this.getCacheFilePath(key);
      if (this.fsManager.existsSync(filePath)) {
        this.fsManager.unlinkSync(filePath);
      }
      
      Logger.debug(this.TAG, `Removed cache for key: ${key}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to remove cache for key ${key}: ${error}`);
      return false;
    }
  }

  /**
   * 清空所有缓存
   * @returns boolean
   */
  public clear(): boolean {
    try {
      // 清空内存缓存
      this.memoryCache.clear();
      this.totalSize = 0;
      
      // 清空文件系统缓存
      if (this.fsManager.existsSync(this.cacheDir)) {
        const files = this.fsManager.listSync(this.cacheDir);
        if (files) {
          for (const file of files) {
            const filePath = `${this.cacheDir}/${file}`;
            if (this.fsManager.statSync(filePath).isFile()) {
              this.fsManager.unlinkSync(filePath);
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
   * 清空站点相关的所有缓存
   * @param siteKey 站点唯一标识
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
      const files = this.fsManager.listSync(this.cacheDir);
      if (files) {
        for (const file of files) {
          if (file.startsWith(`${this.getCacheKeyHash(`${siteKey}:`)}_`)) {
            this.fsManager.unlinkSync(`${this.cacheDir}/${file}`);
          }
        }
      }
      
      Logger.info(this.TAG, `Cleared cache for site: ${siteKey}`);
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
   * 获取缓存项数量
   * @returns number
   */
  public getCacheCount(): number {
    return this.memoryCache.size;
  }

  /**
   * 检查缓存是否存在且未过期
   * @param key 缓存键
   * @returns boolean
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
  public generateCacheKey(siteKey: string, method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null): string {
    // 生成参数的哈希值
    const paramsHash = this.generateParamsHash(params);
    return `${siteKey}:${method}:${paramsHash}`;
  }

  /**
   * 启动清理定时器
   * @private
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
      
      // 清理内存缓存
      for (const [key, item] of this.memoryCache.entries()) {
        if (currentTime > item.timestamp + item.expiry) {
          keysToRemove.push(key);
          this.totalSize -= item.size;
        }
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
      Logger.error(this.TAG, `Failed to cleanup expired cache: ${error}`);
    }
  }

  /**
   * 清理超出大小限制的缓存
   * @private
   */
  private cleanupExcessCache(): void {
    if (this.totalSize > this.config.maxSize!) {
      try {
        // 按时间排序缓存项
        const sortedItems = Array.from(this.memoryCache.entries())
          .sort(([,a], [,b]) => a.timestamp - b.timestamp);
        
        // 移除最旧的缓存项，直到总大小在限制内
        let removedSize = 0;
        let removedCount = 0;
        
        for (const [key, item] of sortedItems) {
          if (this.totalSize - removedSize <= this.config.maxSize! * 0.8) { // 保留20%的空间
            break;
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
   * @param item 缓存项
   * @returns boolean
   * @private
   */
  private isExpired(item: CacheItem): boolean {
    return Date.now() > item.timestamp + item.expiry;
  }

  /**
   * 更新总缓存大小
   * @param key 缓存键
   * @param newSize 新的大小
   * @private
   */
  private updateTotalSize(key: string, newSize: number): void {
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
   * @param key 缓存键
   * @returns string
   * @private
   */
  private getCacheFilePath(key: string): string {
    const keyHash = this.getCacheKeyHash(key);
    return `${this.cacheDir}/${keyHash}_${Date.now()}.cache`;
  }

  /**
   * 获取缓存键的哈希值
   * @param key 缓存键
   * @returns string
   * @private
   */
  private getCacheKeyHash(key: string): string {
    return this.generateHash(key);
  }

  /**
   * 生成参数的哈希值
   * @param params 方法参数
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
   * 简单的字符串哈希生成函数
   * @param str 输入字符串
   * @returns 哈希值字符串
   * @private
   */
  private generateHash(str: string): string {
    let hash = 0;
    if (str.length === 0) return hash.toString();
    
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换为32位整数
    }
    
    // 转换为16进制字符串
    return Math.abs(hash).toString(16);
  }

  /**
   * 获取对象的所有键
   * @param obj 输入对象
   * @returns 键数组
   * @private
   */
  private getObjectKeys(obj: Record<string, Record<string, unknown>>): string[] {
    // 直接使用Object.keys获取键，避免for-in循环和原型链操作
    return Object.keys(obj);
  }

  /**
   * 排序参数对象，确保相同内容的参数生成相同的哈希值
   * @param params 方法参数
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