/**
 * 图片缓存管理器
 * 提供LRU缓存策略和内存管理
 */
export class ImageCacheManager {
  private static instance: ImageCacheManager;
  private cache: Map<string, CacheEntry>;
  private maxSize: number;
  private currentSize: number;
  private memoryManager: any;
  private cacheHits: number = 0;
  private cacheMisses: number = 0;
  private maxLargeImageSize: number = 5; // 最大大型图片大小(MB)

  private constructor(maxSize: number = 50) {
    this.cache = new Map();
    this.maxSize = maxSize;
    this.currentSize = 0;
    // 延迟初始化MemoryManager，避免循环依赖
    setTimeout(() => {
      try {
        const MemoryManagerModule = require('../common/util/MemoryManager');
        this.memoryManager = MemoryManagerModule.default.getInstance();
      } catch (error) {
        console.warn('Failed to initialize MemoryManager:', error);
      }
    }, 0);
  }

  static getInstance(): ImageCacheManager {
    if (!ImageCacheManager.instance) {
      ImageCacheManager.instance = new ImageCacheManager();
    }
    return ImageCacheManager.instance;
  }

  /**
   * 获取缓存项
   */
  get(key: string): CacheEntry | null {
    const entry = this.cache.get(key);
    if (entry) {
      // 更新访问时间
      entry.lastAccessed = Date.now();
      this.cacheHits++;
      return entry;
    }
    this.cacheMisses++;
    return null;
  }

  /**
   * 设置缓存项
   */
  set(key: string, data: string, ttl: number = 300000): void { // 5分钟默认TTL
    try {
      // 检查内存可用性
      const dataSizeMB = this.getSize(data) / 1024; // 转换为MB
      if (this.memoryManager && dataSizeMB > 1) { // 大于1MB的图片检查内存
        if (!this.memoryManager.checkMemoryAvailability(dataSizeMB * 2)) { // 预留两倍空间
          console.warn('Insufficient memory for image cache:', dataSizeMB, 'MB');
          this.clearOldCache();
          // 如果仍然内存不足，不缓存
          if (!this.memoryManager.checkMemoryAvailability(dataSizeMB * 2)) {
            return;
          }
        }
      }

      // 如果已存在，先删除旧条目
      if (this.cache.has(key)) {
        const oldEntry = this.cache.get(key)!;
        this.currentSize -= this.getSize(oldEntry.data);
        this.cache.delete(key);
      }

      // 检查是否需要清理空间
      const dataSize = this.getSize(data);
      while (this.currentSize + dataSize > this.maxSize && this.cache.size > 0) {
        this.evictLRU();
      }

      // 添加新条目
      const entry: CacheEntry = {
        data,
        timestamp: Date.now(),
        lastAccessed: Date.now(),
        ttl,
        size: dataSize,
        error: false
      };

      this.cache.set(key, entry);
      this.currentSize += dataSize;

      // 记录大型对象
      if (this.memoryManager && dataSizeMB > 1) {
        this.memoryManager.recordLargeObject(`image_${key}`, dataSizeMB);
      }
    } catch (error) {
      console.error('Error setting image cache:', error);
    }
  }

  /**
   * 设置错误缓存
   */
  setError(key: string, error: any, ttl: number = 60000): void { // 1分钟错误缓存
    const entry: CacheEntry = {
      data: '',
      timestamp: Date.now(),
      lastAccessed: Date.now(),
      ttl,
      size: 1,
      error: true,
      errorMessage: error.message || 'Unknown error'
    };

    this.cache.set(key, entry);
    this.currentSize += 1;
  }

  /**
   * 检查是否存在有效缓存
   */
  has(key: string): boolean {
    const entry = this.cache.get(key);
    if (!entry) return false;

    // 检查是否过期
    if (Date.now() - entry.timestamp > entry.ttl) {
      this.remove(key);
      return false;
    }

    return true;
  }

  /**
   * 移除缓存项
   */
  remove(key: string): boolean {
    const entry = this.cache.get(key);
    if (entry) {
      this.currentSize -= entry.size;
      this.cache.delete(key);
      return true;
    }
    return false;
  }

  /**
   * 清空所有缓存
   */
  clear(): void {
    this.cache.clear();
    this.currentSize = 0;
    console.log('Image cache cleared');
  }

  /**
   * 清空旧缓存
   */
  clearOldCache(): void {
    const now = Date.now();
    const oneHourAgo = now - 60 * 60 * 1000;
    let clearedCount = 0;

    for (const [key, entry] of this.cache.entries()) {
      if (entry.lastAccessed < oneHourAgo) {
        this.currentSize -= entry.size;
        this.cache.delete(key);
        clearedCount++;
      }
    }

    if (clearedCount > 0) {
      console.log(`Cleared ${clearedCount} old cache entries`);
    }
  }

  /**
   * 获取缓存统计信息
   */
  getStats(): CacheStats {
    return {
      size: this.cache.size,
      maxSize: this.maxSize,
      currentSize: this.currentSize,
      hitRate: this.calculateHitRate()
    };
  }

  /**
   * 预加载图片
   */
  async preload(urls: string[]): Promise<void> {
    // 限制并发预加载数量
    const maxConcurrent = 3;
    const batches: string[][] = [];

    // 分批处理
    for (let i = 0; i < urls.length; i += maxConcurrent) {
      batches.push(urls.slice(i, i + maxConcurrent));
    }

    // 逐个批次预加载
    for (const batch of batches) {
      await Promise.all(
        batch.map(async (url) => {
          try {
            if (!this.has(url)) {
              // 这里应该实际加载图片，简化实现
              await this.simulatePreload(url);
            }
          } catch (error) {
            console.warn('Preload failed for:', url, error);
          }
        })
      );
      // 批次之间延迟，避免内存峰值
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }

  /**
   * 压缩图片数据（如果过大）
   */
  compressImageData(data: string, maxSizeMB: number = 2): string {
    const currentSizeMB = this.getSize(data) / 1024;
    if (currentSizeMB <= maxSizeMB) {
      return data;
    }

    // 这里可以实现实际的图片压缩逻辑
    // 简化实现：返回原始数据，但记录警告
    console.warn('Image too large, consider implementing compression:', currentSizeMB, 'MB');
    return data;
  }

  private evictLRU(): void {
    let oldestKey: string | null = null;
    let oldestTime = Infinity;

    for (const [key, entry] of this.cache.entries()) {
      if (entry.lastAccessed < oldestTime) {
        oldestTime = entry.lastAccessed;
        oldestKey = key;
      }
    }

    if (oldestKey) {
      this.remove(oldestKey);
    }
  }

  private getSize(data: string): number {
    // 简化的大小计算
    return Math.ceil(data.length / 1024); // KB
  }

  private calculateHitRate(): number {
    const total = this.cacheHits + this.cacheMisses;
    return total > 0 ? this.cacheHits / total : 0;
  }

  private async simulatePreload(url: string): Promise<void> {
    return new Promise(resolve => {
      setTimeout(() => {
        // 模拟预加载成功
        this.set(url, `preloaded_data_${url}`);
        resolve();
      }, 100);
    });
  }
}

/**
 * 缓存条目接口
 */
interface CacheEntry {
  data: string;
  timestamp: number;
  lastAccessed: number;
  ttl: number;
  size: number;
  error: boolean;
  errorMessage?: string;
}

/**
 * 缓存统计信息接口
 */
interface CacheStats {
  size: number;
  maxSize: number;
  currentSize: number;
  hitRate: number;
}
