import Logger from '../../common/util/Logger';
import { BaseLoader, LoaderType } from './loader';
import { Site } from '../../data/bean/Site';
import { ArkJsLoader, ArkPyLoader, ArkJarLoader } from './loader';

/**
 * 加载器工�?
 * 根据站点配置创建对应的爬虫加载器
 */
export class LoaderFactory {
  private readonly TAG: string = 'LoaderFactory';
  private static instance: LoaderFactory | null = null;
  private loaderCache: Map<string, BaseLoader> = new Map();
  private maxCacheSize: number = 50; // 最大缓存加载器数量

  /**
   * 获取单例实例
   * @returns LoaderFactory
   */
  public static getInstance(): LoaderFactory {
    if (!LoaderFactory.instance) {
      LoaderFactory.instance = new LoaderFactory();
    }
    return LoaderFactory.instance;
  }

  /**
   * 构造函�?
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    Logger.info(this.TAG, 'LoaderFactory initialized');
  }

  /**
   * 根据站点信息创建加载�?
   * @param site 站点信息
   * @returns Promise<BaseLoader>
   */
  public async createLoader(site: Site): Promise<BaseLoader> {
    try {
      // 检查缓存中是否已有加载�?
      const cacheKey = this.getCacheKey(site);
      let loader = this.loaderCache.get(cacheKey);
      
      // 如果加载器存在但已销毁，则移除缓�?
      if (loader && loader.isDestroyed()) {
        this.loaderCache.delete(cacheKey);
        loader = null;
      }
      
      // 如果缓存中没有，则创建新的加载器
      if (!loader) {
        loader = this.createNewLoader(site);
        
        // 初始化加载器
        await loader.init();
        
        // 添加到缓�?
        this.addToCache(cacheKey, loader);
        
        Logger.info(this.TAG, `Created new ${loader.getLoaderType()} loader for site: ${site.name} (${site.key})`);
      } else {
        Logger.info(this.TAG, `Using cached loader for site: ${site.name} (${site.key})`);
      }
      
      return loader;
    } catch (error) {
      Logger.error(this.TAG, `Failed to create loader for site ${site.key}: ${error}`);
      throw error;
    }
  }

  /**
   * 获取站点的加载器
   * 如果缓存中存在已初始化的加载器则直接返回，否则创建新�?
   * @param site 站点信息
   * @returns Promise<BaseLoader>
   */
  public async getLoader(site: Site): Promise<BaseLoader> {
    // 生成缓存�?
    const cacheKey = this.getCacheKey(site);
    
    // 查找缓存中的加载�?
    let loader = this.loaderCache.get(cacheKey);
    
    // 如果加载器存在且未销毁且已初始化，则直接返回
    if (loader && !loader.isDestroyed() && loader.isInitialized()) {
      return loader;
    }
    
    // 否则创建新的加载�?
    return this.createLoader(site);
  }

  /**
   * 销毁指定站点的加载�?
   * @param siteKey 站点唯一标识
   * @returns boolean 是否成功销�?
   */
  public async destroyLoader(siteKey: string): Promise<boolean> {
    const cacheKeysToRemove: string[] = [];
    
    // 查找所有匹配的缓存�?
    for (const [key, loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries( instanceof Error ? loader] of this.loaderCache.entries( : new Error(String(loader] of this.loaderCache.entries()))))))) {
      if (key.startsWith(`${siteKey}:`)) {
        try {
          await loader.destroy();
          cacheKeysToRemove.push(key);
          Logger.info(this.TAG, `Destroyed loader for site: ${siteKey}`);
        } catch (error) {
          Logger.error(this.TAG, `Failed to destroy loader for site ${siteKey}: ${error}`);
        }
      }
    }
    
    // 从缓存中移除
    for (const key of cacheKeysToRemove) {
      this.loaderCache.delete(key);
    }
    
    return cacheKeysToRemove.length > 0;
  }

  /**
   * 销毁所有加载器
   */
  public async destroyAllLoaders(): Promise<void> {
    const loaders = Array.from(this.loaderCache.values());
    this.loaderCache.clear();
    
    // 并行销毁所有加载器
    await Promise.allSettled(
      loaders.map(loader => {
        return loader.destroy().catch(error => {
          Logger.error(this.TAG, `Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}` instanceof Error ? `Error destroying loader: ${error}` : new Error(String(`Error destroying loader: ${error}`)))))));
        });
      })
    );
    
    Logger.info(this.TAG, `Destroyed all ${loaders.length} loaders`);
  }

  /**
   * 清空缓存
   */
  public clearCache(): void {
    this.loaderCache.clear();
    Logger.info(this.TAG, 'Loader cache cleared');
  }

  /**
   * 获取缓存大小
   * @returns number 缓存中的加载器数�?
   */
  public getCacheSize(): number {
    return this.loaderCache.size;
  }

  /**
   * 设置最大缓存大�?
   * @param size 最大缓存大�?
   */
  public setMaxCacheSize(size: number): void {
    if (size > 0) {
      this.maxCacheSize = size;
      // 如果当前缓存超过新的最大值，清理多余的加载器
      this.cleanupCache();
      Logger.info(this.TAG, `Max cache size set to: ${size}`);
    }
  }

  /**
   * 关闭工厂，清理所有资�?
   */
  public async shutdown(): Promise<void> {
    await this.destroyAllLoaders();
    Logger.info(this.TAG, 'LoaderFactory shutdown completed');
  }

  /**
   * 创建新的加载器实�?
   * @param site 站点配置
   * @returns BaseLoader
   * @private
   */
  private createNewLoader(site: Site): BaseLoader {
    switch (site.type) {
      case LoaderType.JS:
        return new ArkJsLoader(site);
      case LoaderType.PY:
        return new ArkPyLoader(site);
      case LoaderType.JAR:
        return new ArkJarLoader(site);
      default:
        throw new Error(`Unsupported loader type: ${site.type}`);
    }
  }

  /**
   * 获取缓存�?
   * @param site 站点信息
   * @returns string 缓存�?
   * @private
   */
  private getCacheKey(site: Site): string {
    // 使用站点key和配置的哈希值作为缓存键
    const configHash = this.generateConfigHash(site);
    return `${site.key}:${configHash}`;
  }

  /**
   * 生成站点的哈希值，用于缓存�?
   * @param site 站点信息
   * @returns string 哈希�?
   * @private
   */
  private generateConfigHash(site: Site): string {
    // 使用站点的关键信息生成哈�?
    const configStr = JSON.stringify({
      key: site.key,
      api: site.api,
      ext: site.ext,
      jar: site.jar,
      type: site.type
    });
    
    // 简单的字符串哈希算�?
    let hash = 0;
    if (configStr.length === 0) return String(hash);
    
    for (let i = 0; i < configStr.length; i++) {
      const char = configStr.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换�?2位整�?
    }
    
    return String(hash);
  }

  /**
   * 添加到缓�?
   * @param key 缓存�?
   * @param loader 加载器实�?
   * @private
   */
  private addToCache(key: string, loader: BaseLoader): void {
    // 如果缓存已满，清理一些旧的加载器
    if (this.loaderCache.size >= this.maxCacheSize) {
      this.cleanupCache();
    }
    
    this.loaderCache.set(key, loader);
    Logger.debug(this.TAG, `Added loader to cache: ${key}, current cache size: ${this.loaderCache.size}`);
  }

  /**
   * 清理缓存，移除最旧的或已销毁的加载�?
   * @private
   */
  private cleanupCache(): void {
    const loadersToKeep: [string, BaseLoader][] = [];
    const loadersToRemove: [string, BaseLoader][] = [];
    
    // 分离已销毁的加载�?
    for (const [key, loader] of this.loaderCache.entries()) {
      if (loader.isDestroyed()) {
        loadersToRemove.push([key, loader]);
      } else {
        loadersToKeep.push([key, loader]);
      }
    }
    
    // 如果仍然需要移除更多加载器，按初始化时间排序并移除最旧的
    if (loadersToKeep.length > this.maxCacheSize * 0.8) {
      // 按初始化时间排序
      loadersToKeep.sort((a, b) => {
        const statusA = a[1].getStatus();
        const statusB = b[1].getStatus();
        return (statusA.initializedTime || 0) - (statusB.initializedTime || 0);
      });
      
      // 移除多余的加载器
      const excess = loadersToKeep.length - Math.floor(this.maxCacheSize * 0.8);
      for (let i = 0; i < excess && i < loadersToKeep.length; i++) {
        loadersToRemove.push(loadersToKeep[i]);
      }
    }
    
    // 移除选中的加载器
    for (const [key, loader] of loadersToRemove) {
      this.loaderCache.delete(key);
      try {
        loader.destroy();
        Logger.debug(this.TAG, `Removed and destroyed loader from cache: ${key}`);
      } catch (error) {
        Logger.error(this.TAG, `Error destroying loader during cache cleanup: ${error}`);
      }
    }
    
    Logger.debug(this.TAG, `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` instanceof Error ? `Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}` : new Error(String(`Cache cleanup completed, removed ${loadersToRemove.length} loaders, current cache size: ${this.loaderCache.size}`)))))));
  }
}


