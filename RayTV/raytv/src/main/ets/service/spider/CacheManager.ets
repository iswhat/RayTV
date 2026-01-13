import Logger from '../../common/util/Logger';
import fs from '@ohos.file.fs';

/**
 * 缓存项接口 | Cache item interface
 */
export interface CacheItem {
  data: Record<string, string | number | boolean | null> | string | number | boolean | null;
  timestamp: number;
  expiry: number;
  size: number;
}

/**
 * 缓存配置接口 | Cache config interface
 */
export interface CacheConfig {
  maxSize?: number; // 最大缓存大小（字节）| Max cache size (bytes)
  defaultExpiry?: number; // 默认过期时间（秒）| Default expiry time (seconds)
  cleanupInterval?: number; // 清理间隔（秒）| Cleanup interval (seconds)
  enabled?: boolean; // 是否启用缓存 | Whether to enable cache
}

/**
 * 缓存管理器 | Cache manager
 * 实现爬取结果的本地缓存，支持缓存过期判断和清理机制
 */
export class CacheManager {
  private readonly TAG: string = 'CacheManager';
  private static instance: CacheManager | null = null;
  private memoryCache: Map<string, CacheItem> = new Map();
  private fsManager: typeof fs;
  private cacheDir: string = '';
  private config: CacheConfig;
  private totalSize: number = 0;
  private cleanupTimer: number | null = null;

  /**
   * 默认缓存配置 | Default cache config
   */
  private static readonly DEFAULT_CONFIG: CacheConfig = {
    maxSize: 100 * 1024 * 1024, // 100MB
    defaultExpiry: 3600 * 1000, // 1小时 | 1 hour
    cleanupInterval: 300000, // 5分钟 | 5 minutes
    enabled: true
  };

  /**
   * 获取单例实例 | Get singleton instance
   * @returns CacheManager
   */
  public static getInstance(): CacheManager {
    if (!CacheManager.instance) {
      CacheManager.instance = new CacheManager();
    }
    return CacheManager.instance;
  }

  /**
   * 构造函数 | Constructor
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.fsManager = fs;
    // 避免对象展开操作符，显式构造配置确保类型安全
    this.config = {
      maxSize: CacheManager.DEFAULT_CONFIG.maxSize,
      defaultExpiry: CacheManager.DEFAULT_CONFIG.defaultExpiry,
      cleanupInterval: CacheManager.DEFAULT_CONFIG.cleanupInterval,
      enabled: CacheManager.DEFAULT_CONFIG.enabled
    };
    this.initialize();
    Logger.info(this.TAG, 'CacheManager initialized', {});
  }

  /**
   * 初始化缓存管理器 | Initialize cache manager
   * @private
   */
  private initialize(): void {
    try {
      // 设置缓存目录
      this.cacheDir = this.getCacheDirectory();
      
      // 确保缓存目录存在
    try {
      await this.fsManager.access(this.cacheDir);
    } catch {
      await this.fsManager.mkdir(this.cacheDir, true);
      Logger.info(this.TAG, `Created cache directory: ${this.cacheDir}`, {});
    }
      
      // 启动定期清理
      this.startCleanupTimer();
      
      // 初始清理
      this.cleanupExpiredCache();
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize cache manager`, error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 设置缓存配置 | Set cache config
   * @param config 缓存配置 | Cache config
   */
  public setConfig(config: CacheConfig): void {
    // 避免对象展开操作符，显式合并配置确保类型安全
    this.config = {
      maxSize: config.maxSize !== null && config.maxSize !== undefined ? config.maxSize : this.config.maxSize,
      defaultExpiry: config.defaultExpiry !== null && config.defaultExpiry !== undefined ? config.defaultExpiry : this.config.defaultExpiry,
      cleanupInterval: config.cleanupInterval !== null && config.cleanupInterval !== undefined ? config.cleanupInterval : this.config.cleanupInterval,
      enabled: config.enabled !== null && config.enabled !== undefined ? config.enabled : this.config.enabled
    };
    Logger.info(this.TAG, `Updated cache config`, { config: this.config });
    
    // 閲嶆柊鍚姩娓呯悊瀹氭椂鍣?
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
    }
    this.startCleanupTimer();
    
    // 濡傛灉缂撳瓨澶у皬瓒呴檺锛岀珛鍗虫竻鐞?
    this.cleanupExcessCache();
  }

  /**
   * 获取缓存 | Get cache
   * @param key 缓存键 | Cache key
   * @returns 缓存数据或null | Cache data or null
   */
  public get(key: string): Record<string, string | number | boolean | null> | string | number | boolean | null {
    if (!this.config.enabled) {
      return null;
    }

    try {
      // 棣栧厛浠庡唴瀛樼紦瀛樹腑鑾峰彇
      const cacheItem = this.memoryCache.get(key);
      
      if (cacheItem) {
        // 妫€鏌ユ槸鍚﹁繃鏈?
        if (!this.isExpired(cacheItem)) {
          Logger.debug(this.TAG, `Cache hit for key: ${key} (memory)`, { key });
          return cacheItem.data;
        } else {
          // 杩囨湡鍒欑Щ闄?
          this.remove(key);
        }
      }
      
      // 浠庢枃浠剁郴缁熻幏鍙?
      const filePath = this.getCacheFilePath(key);
      try {
        const fileContent = await this.fsManager.readText(filePath);
        const fileCacheItem: CacheItem = JSON.parse(fileContent);
        
        // 妫€鏌ユ槸鍚﹁繃鏈?
        if (!this.isExpired(fileCacheItem)) {
          // 鍔犺浇鍒板唴瀛樼紦瀛?
          this.memoryCache.set(key, fileCacheItem);
          Logger.debug(this.TAG, `Cache hit for key: ${key} (disk)`);
          return fileCacheItem.data;
        } else {
          // 杩囨湡鍒欏垹闄ゆ枃浠?
          this.fsManager.unlinkSync(filePath);
        }
      }
      
      Logger.debug(this.TAG, `Cache miss for key: ${key}`);
      return null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get cache for key ${key}: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 设置缓存 | Set cache
   * @param key 缓存键 | Cache key
   * @param data 缓存数据 | Cache data
   * @param expiry 过期时间（秒，可选）| Expiry time (seconds, optional)
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
      
      // 妫€鏌ユ暟鎹ぇ灏忔槸鍚﹁秴杩囬檺鍒?
      if (size > this.config.maxSize! * 0.1) { // 涓嶇紦瀛樿秴杩囨渶澶х紦瀛?0%鐨勬暟鎹?
        Logger.warn(this.TAG, `Data too large for caching: ${size} bytes`);
        return false;
      }
      
      const cacheItem: CacheItem = {
        data,
        timestamp: Date.now(),
        expiry: expiryTime,
        size
      };
      
      // 鏇存柊鎬诲ぇ灏?
      this.updateTotalSize(key, size);
      
      // 淇濆瓨鍒板唴瀛樼紦瀛?
      this.memoryCache.set(key, cacheItem);
      
      // 淇濆瓨鍒版枃浠剁郴缁?
      const filePath = this.getCacheFilePath(key);
      await this.fsManager.writeText(filePath, JSON.stringify(cacheItem));
      
      // 妫€鏌ュ苟娓呯悊瓒呭嚭澶у皬闄愬埗鐨勭紦瀛?
      this.cleanupExcessCache();
      
      Logger.debug(this.TAG, `Cached data for key: ${key}`, { key, size, expiry: expiryTime });
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to set cache for key ${key}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * 删除缓存 | Remove cache
   * @param key 缓存键 | Cache key
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
      try {
        await this.fsManager.access(filePath);
        await this.fsManager.unlink(filePath);
      } catch {
        // 文件不存在，忽略
      }
      
      Logger.debug(this.TAG, `Removed cache for key: ${key}`, { key });
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to remove cache for key ${key}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * 清空所有缓存 | Clear all cache
   * @returns boolean
   */
  public clear(): boolean {
    try {
      // 清空内存缓存
      this.memoryCache.clear();
      this.totalSize = 0;
      
      // 清空文件系统缓存
      try {
        await this.fsManager.access(this.cacheDir);
        // 使用readDir替代listSync
        const dir = await this.fsManager.readDir(this.cacheDir);
        const files = dir.files;
        if (files) {
          for (let i = 0; i < files.length; i++) {
            const file = files[i];
            if (file.isFile) {
              const filePath = `${this.cacheDir}/${file.name}`;
              try {
                // 直接删除文件，不检查文件类型
                await this.fsManager.unlink(filePath);
              } catch (error) {
                // 如果删除失败，忽略并继续
                Logger.warn(this.TAG, `Failed to delete cache file: ${filePath}`, error instanceof Error ? error : new Error(String(error)));
              }
            }
          }
        }
      }
      
      Logger.info(this.TAG, 'All cache cleared', {});
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear cache`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * 清空站点相关的所有缓存 | Clear all cache related to site
   * @param siteKey 站点唯一标识 | Site unique identifier
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
      
      // 删除内存缓存
      for (const key of keysToRemove) {
        this.remove(key);
      }
      
      // 删除文件系统中的缓存
      const files = this.fsManager.listSync(this.cacheDir).files as string[];
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
      Logger.error(this.TAG, `Failed to clear site cache for ${siteKey}: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 获取缓存大小 | Get cache size
   * @returns number 缓存大小（字节）| Cache size (bytes)
   */
  public getCacheSize(): number {
    return this.totalSize;
  }

  /**
   * 获取缓存项数量 | Get cache item count
   * @returns number
   */
  public getCacheCount(): number {
    return this.memoryCache.size;
  }

  /**
   * 检查缓存是否存在且未过期 | Check if cache exists and not expired
   * @param key 缓存键 | Cache key
   * @returns boolean
   */
  public has(key: string): boolean {
    return this.get(key) !== null;
  }

  /**
   * 生成爬取方法的缓存键 | Generate cache key for crawl method
   * @param siteKey 站点唯一标识 | Site unique identifier
   * @param method 方法名称 | Method name
   * @param params 方法参数 | Method parameters
   * @returns string
   */
  public generateCacheKey(siteKey: string, method: string, params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null): string {
    // 生成参数的哈希值
    const paramsHash = this.generateParamsHash(params);
    return `${siteKey}:${method}:${paramsHash}`;
  }

  /**
   * 启动清理定时器 | Start cleanup timer
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
   * 清理过期缓存 | Cleanup expired cache
   * @private
   */
  private cleanupExpiredCache(): void {
    try {
      const keysToRemove: string[] = [];
      const currentTime = Date.now();
      
      // 娓呯悊鍐呭瓨缂撳瓨 - 浣跨敤鏅€氬彉閲忓０鏄庢浛浠ｈВ鏋?
      const entries = this.memoryCache.entries();
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
        // 鍚屾椂鍒犻櫎鏂囦欢绯荤粺涓殑缂撳瓨
        const filePath = this.getCacheFilePath(key);
        if (this.fsManager.existsSync(filePath)) {
          this.fsManager.unlinkSync(filePath);
        }
      }
      
      if (keysToRemove.length > 0) {
        Logger.info(this.TAG, `Cleaned ${keysToRemove.length} expired cache items`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to cleanup expired cache: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 清理超出大小限制的缓存 | Cleanup excess cache
   * @private
   */
  private cleanupExcessCache(): void {
    if (this.totalSize > this.config.maxSize!) {
      try {
        // 按时间排序缓存项 - 使用标准方法解决问题
        const sortedItems = Array.from(this.memoryCache.entries())
          .sort((entryA, entryB) => {
            const a = entryA[1];
            const b = entryB[1];
            return a.timestamp - b.timestamp;
          });
        
        // 删除最早的缓存项，直到总大小在限制内
        let removedSize = 0;
        let removedCount = 0;
        
        // 使用标准变量明确解决问题
        for (const entry of sortedItems) {
          const key = entry[0];
          const item = entry[1];
          if (this.totalSize - removedSize <= this.config.maxSize! * 0.8) { // 预留20%的空间
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
        Logger.error(this.TAG, `Failed to cleanup excess cache: ${JSON.stringify(error)}`);
      }
    }
  }

  /**
   * 妫€鏌ョ紦瀛橀」鏄惁杩囨湡
   * @param item 缂撳瓨椤?
   * @returns boolean
   * @private
   */
  private isExpired(item: CacheItem): boolean {
    return Date.now() > item.timestamp + item.expiry;
  }

  /**
   * 鏇存柊鎬荤紦瀛樺ぇ灏?
   * @param key 缂撳瓨閿?
   * @param newSize 鏂扮殑澶у皬
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
   * 鑾峰彇缂撳瓨鐩綍
   * @returns string
   * @private
   */
  private getCacheDirectory(): string {
    // 浣跨敤搴旂敤缂撳瓨鐩綍
    return `/cache/raytv/spider`;
  }

  /**
   * 鑾峰彇缂撳瓨鏂囦欢璺緞
   * @param key 缂撳瓨閿?
   * @returns string
   * @private
   */
  private getCacheFilePath(key: string): string {
    const keyHash = this.getCacheKeyHash(key);
    return `${this.cacheDir}/${keyHash}_${Date.now()}.cache`;
  }

  /**
   * 鑾峰彇缂撳瓨閿殑鍝堝笇鍊?
   * @param key 缂撳瓨閿?
   * @returns string
   * @private
   */
  private getCacheKeyHash(key: string): string {
    return this.generateHash(key);
  }

  /**
   * 鐢熸垚鍙傛暟鐨勫搱甯屽€?
   * @param params 鏂规硶鍙傛暟
   * @returns string
   * @private
   */
  private generateParamsHash(params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null): string {
    try {
      const sortedParams = this.sortParams(params);
      return this.generateHash(JSON.stringify(sortedParams));
    } catch (error) {
      Logger.error(this.TAG, `Failed to generate params hash: ${JSON.stringify(error)}`);
      return 'error';
    }
  }
  
  /**
   * 绠€鍗曠殑瀛楃涓插搱甯岀敓鎴愬嚱鏁?
   * @param str 杈撳叆瀛楃涓?
   * @returns 鍝堝笇鍊煎瓧绗︿覆
   * @private
   */
  private generateHash(str: string): string {
    let hash = 0;
    if (str.length === 0) return hash.toString();
    
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 杞崲涓?2浣嶆暣鏁?
    }
    
    // 杞崲涓?6杩涘埗瀛楃涓?
    return Math.abs(hash).toString(16);
  }

  /**
   * 鑾峰彇瀵硅薄鐨勬墍鏈夐敭
   * @param obj 杈撳叆瀵硅薄
   * @returns 閿暟缁?
   * @private
   */
  private getObjectKeys(obj: Record<string, string | number | boolean | null>): string[] {
    // 鐩存帴浣跨敤Object.keys鑾峰彇閿紝閬垮厤for-in寰幆鍜屽師鍨嬮摼鎿嶄綔
    return Object.keys(obj);
  }

  /**
   * 鎺掑簭鍙傛暟瀵硅薄锛岀‘淇濈浉鍚屽唴瀹圭殑鍙傛暟鐢熸垚鐩稿悓鐨勫搱甯屽€?
   * @param params 鏂规硶鍙傛暟
   * @returns 鎺掑簭鍚庣殑鍙傛暟
   * @private
   */
  private sortParams(params: Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null): Record<string, string | number | boolean | null> | string[] | number[] | boolean[] | string | number | boolean | null {
    // 澶勭悊鍩烘湰绫诲瀷鍜宯ull
    if (typeof params !== 'object' || params === null) {
      return params;
    }
    
    // 澶勭悊鏁扮粍
    if (Array.isArray(params)) {
      // 纭繚绫诲瀷瀹夊叏锛岄伩鍏島nknown绫诲瀷鐨勯€掑綊
      const typedArray = params as (string | number | boolean | null)[];
      return typedArray.map(item => {
        // 浠呭瀵硅薄绫诲瀷杩涜閫掑綊鎺掑簭
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
    
    // 澶勭悊瀵硅薄
    const sorted: Record<string, string | number | boolean | null> = {};
    const paramObj = params as Record<string, string | number | boolean | null>;
    
    this.getObjectKeys(paramObj).sort().forEach(key => {
      const value = paramObj[key];
      // 浠呭瀵硅薄绫诲瀷杩涜閫掑綊鎺掑簭
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


