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