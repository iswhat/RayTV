import Logger from '../../common/util/Logger';
import { BaseLoader, SiteConfig, LoaderType } from './loader/BaseLoader';
import { ArkJsLoader } from './loader/ArkJsLoader';
import { ArkPyLoader } from './loader/ArkPyLoader';
import { ArkJarLoader } from './loader/ArkJarLoader';

/**
 * 加载器工厂
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
   * 构造函数
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    Logger.info(this.TAG, 'LoaderFactory initialized');
  }

  /**
   * 根据站点配置创建加载器
   * @param siteConfig 站点配置
   * @returns Promise<BaseLoader>
   */
  public async createLoader(siteConfig: SiteConfig): Promise<BaseLoader> {
    try {
      // 检查缓存中是否已有加载器
      const cacheKey = this.getCacheKey(siteConfig);
      let loader = this.loaderCache.get(cacheKey);
      
      // 如果加载器存在但已销毁，则移除缓存
      if (loader && loader.isDestroyed()) {
        this.loaderCache.delete(cacheKey);
        loader = null;
      }
      
      // 如果缓存中没有，则创建新的加载器
      if (!loader) {
        loader = this.createNewLoader(siteConfig);
        
        // 初始化加载器
        await loader.init();
        
        // 添加到缓存
        this.addToCache(cacheKey, loader);
        
        Logger.info(this.TAG, `Created new ${loader.getLoaderType()} loader for site: ${siteConfig.name} (${siteConfig.key})`);
      } else {
        Logger.info(this.TAG, `Using cached loader for site: ${siteConfig.name} (${siteConfig.key})`);
      }
      
      return loader;
    } catch (error) {
      Logger.error(this.TAG, `Failed to create loader for site ${siteConfig.key}: ${error}`);
      throw error;
    }
  }

  /**
   * 获取站点的加载器
   * 如果缓存中存在已初始化的加载器则直接返回，否则创建新的
   * @param siteKey 站点唯一标识
   * @returns BaseLoader | undefined
   */
  public getLoader(siteKey: string): BaseLoader | undefined {
    // 遍历缓存查找站点加载器
    for (const [key, loader] of this.loaderCache.entries()) {
      if (key.startsWith(`${siteKey}:`) && !loader.isDestroyed()) {
        return loader;
      }
    }
    return undefined;
  }

  /**
   * 销毁站点的加载器
   * @param siteKey 站点唯一标识
   */
  public destroyLoader(siteKey: string): void {
    const keysToRemove: string[] = [];
    
    // 查找并销毁站点相关的加载器
    for (const [key, loader] of this.loaderCache.entries()) {
      if (key.startsWith(`${siteKey}:`)) {
        try {
          loader.destroy();
          keysToRemove.push(key);
          Logger.info(this.TAG, `Destroyed loader for site: ${siteKey}`);
        } catch (error) {
          Logger.error(this.TAG, `Failed to destroy loader for site ${siteKey}: ${error}`);
        }
      }
    }
    
    // 从缓存中移除
    for (const key of keysToRemove) {
      this.loaderCache.delete(key);
    }
  }

  /**
   * 销毁所有加载器
   */
  public destroyAllLoaders(): void {
    Logger.info(this.TAG, 'Destroying all loaders');
    
    for (const loader of this.loaderCache.values()) {
      try {
        loader.destroy();
      } catch (error) {
        Logger.error(this.TAG, `Failed to destroy loader: ${error}`);
      }
    }
    
    this.loaderCache.clear();
    Logger.info(this.TAG, 'All loaders destroyed');
  }

  /**
   * 获取缓存中的加载器数量
   * @returns number
   */
  public getCacheSize(): number {
    return this.loaderCache.size;
  }

  /**
   * 清理未使用的加载器缓存
   */
  public cleanCache(): void {
    // 如果缓存超过最大大小，清理最早的加载器
    const entries = Array.from(this.loaderCache.entries());
    while (entries.length > this.maxCacheSize) {
      const [key, loader] = entries.shift()!;
      try {
        loader.destroy();
        this.loaderCache.delete(key);
        Logger.info(this.TAG, `Cleaned cache: removed loader with key ${key}`);
      } catch (error) {
        Logger.error(this.TAG, `Failed to clean cache for key ${key}: ${error}`);
      }
    }
  }

  /**
   * 设置最大缓存大小
   * @param size 最大缓存大小
   */
  public setMaxCacheSize(size: number): void {
    if (size > 0) {
      this.maxCacheSize = size;
      // 清理超出的缓存
      this.cleanCache();
      Logger.info(this.TAG, `Max cache size set to: ${size}`);
    }
  }

  /**
   * 创建新的加载器实例
   * @param siteConfig 站点配置
   * @returns BaseLoader
   * @private
   */
  private createNewLoader(siteConfig: SiteConfig): BaseLoader {
    switch (siteConfig.type) {
      case LoaderType.JS:
        return new ArkJsLoader(siteConfig);
      case LoaderType.PY:
        return new ArkPyLoader(siteConfig);
      case LoaderType.JAR:
        return new ArkJarLoader(siteConfig);
      default:
        throw new Error(`Unsupported loader type: ${siteConfig.type}`);
    }
  }

  /**
   * 生成缓存键
   * @param siteConfig 站点配置
   * @returns string
   * @private
   */
  private getCacheKey(siteConfig: SiteConfig): string {
    // 使用站点key和配置的哈希值作为缓存键
    const configHash = this.generateConfigHash(siteConfig);
    return `${siteConfig.key}:${configHash}`;
  }

  /**
   * 生成配置哈希值
   * @param config 站点配置
   * @returns string
   * @private
   */
  private generateConfigHash(config: SiteConfig): string {
    // 简单的配置哈希生成
    const configString = JSON.stringify({
      type: config.type,
      url: config.url,
      content: config.content,
      enabled: config.enabled
    });
    
    // 生成简单的哈希值
    let hash = 0;
    for (let i = 0; i < configString.length; i++) {
      const char = configString.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    
    return Math.abs(hash).toString(16);
  }

  /**
   * 添加加载器到缓存
   * @param key 缓存键
   * @param loader 加载器实例
   * @private
   */
  private addToCache(key: string, loader: BaseLoader): void {
    // 清理缓存以保持大小限制
    this.cleanCache();
    
    // 添加新的加载器到缓存
    this.loaderCache.set(key, loader);
    
    Logger.debug(this.TAG, `Added loader to cache. Current cache size: ${this.loaderCache.size}`);
  }

  /**
   * 检查加载器类型是否支持
   * @param loaderType 加载器类型
   * @returns boolean
   */
  public static isSupportedLoaderType(loaderType: string): boolean {
    return Object.values(LoaderType).includes(loaderType as LoaderType);
  }

  /**
   * 获取支持的加载器类型列表
   * @returns string[]
   */
  public static getSupportedLoaderTypes(): string[] {
    return Object.values(LoaderType);
  }
}