/**
 * JsonCache - JSON缓存工具
 * 减少频繁的JSON序列化/反序列化操作
 */

export class JsonCache<T> {
  private cache: Map<string, { data: T, timestamp: number }> = new Map();
  private maxAge: number; // 缓存最大有效期（毫秒）
  private maxSize: number; // 最大缓存条目数

  constructor(maxAge: number = 5000, maxSize: number = 100) {
    this.maxAge = maxAge;
    this.maxSize = maxSize;
  }

  /**
   * 缓存JSON对象
   * @param key 缓存键
   * @param data 要缓存的数据
   */
  public set(key: string, data: T): void {
    // 清理过期和超出的缓存
    this.cleanup();

    // 添加新缓存
    this.cache.set(key, {
      data: data,
      timestamp: Date.now()
    });
  }

  /**
   * 获取缓存的数据
   * @param key 缓存键
   * @returns 缓存的数据，不存在或过期则返回null
   */
  public get(key: string): T | null {
    const entry = this.cache.get(key);

    if (!entry) {
      return null;
    }

    // 检查是否过期
    if (Date.now() - entry.timestamp > this.maxAge) {
      this.cache.delete(key);
      return null;
    }

    return entry.data;
  }

  /**
   * 缓存并序列化（如果缓存未命中则序列化）
   * @param key 缓存键
   * @param data 要序列化的数据
   * @param serializeFn 序列化函数
   * @returns 序列化后的字符串
   */
  public serialize(key: string, data: T, serializeFn: (data: T) => string): string {
    const cached = this.get(key);
    if (cached !== null) {
      return serializeFn(cached);
    }

    this.set(key, data);
    return serializeFn(data);
  }

  /**
   * 反序列化并缓存（如果缓存未命中则反序列化）
   * @param key 缓存键
   * @param serializedData 序列化的数据
   * @param deserializeFn 反序列化函数
   * @returns 反序列化后的对象
   */
  public deserialize<R>(key: string, serializedData: string, deserializeFn: (data: string) => R): R {
    // 检查缓存（使用序列化后的数据作为键的一部分）
    const cacheKey = `${key}:${serializedData}`;
    const cached = this.get(cacheKey as any) as R | null;
    if (cached !== null) {
      return cached;
    }

    const result = deserializeFn(serializedData);
    this.set(cacheKey as any, result as any);
    return result;
  }

  /**
   * 清理过期和超出的缓存
   */
  private cleanup(): void {
    const now = Date.now();
    const toDelete: string[] = [];

    // 清理过期缓存
    this.cache.forEach((entry, key) => {
      if (now - entry.timestamp > this.maxAge) {
        toDelete.push(key);
      }
    });

    // 清理超出数量限制的缓存（LRU：最老的先删除）
    if (this.cache.size > this.maxSize) {
      const sortedEntries = Array.from(this.cache.entries())
        .sort((a, b) => a[1].timestamp - b[1].timestamp);

      const deleteCount = this.cache.size - this.maxSize;
      for (let i = 0; i < deleteCount; i++) {
        toDelete.push(sortedEntries[i][0]);
      }
    }

    // 执行删除
    for (const key of toDelete) {
      this.cache.delete(key);
    }
  }

  /**
   * 清除所有缓存
   */
  public clear(): void {
    this.cache.clear();
  }

  /**
   * 获取缓存大小
   */
  public size(): number {
    return this.cache.size;
  }

  /**
   * 删除指定键的缓存
   * @param key 缓存键
   */
  public delete(key: string): boolean {
    return this.cache.delete(key);
  }
}

export default JsonCache;
