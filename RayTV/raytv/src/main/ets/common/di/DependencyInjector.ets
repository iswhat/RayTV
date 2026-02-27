import Logger from '../util/Logger';

/**
 * 依赖注入容器
 * Dependency injection container
 */
export class DependencyInjector {
  private static instance: DependencyInjector;
  private services: Map<string, any> = new Map();
  private factories: Map<string, () => any> = new Map();
  private dependencies: Map<string, string[]> = new Map();
  private isInitialized: boolean = false;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   * Get singleton instance
   */
  public static getInstance(): DependencyInjector {
    if (!DependencyInjector.instance) {
      DependencyInjector.instance = new DependencyInjector();
    }
    return DependencyInjector.instance;
  }
  
  /**
   * 注册服务
   * Register service
   * @param name 服务名称
   * @param factory 服务工厂函数
   * @param deps 依赖的服务名称数组
   */
  public register<T>(name: string, factory: () => T, deps: string[] = []): void {
    this.factories.set(name, factory);
    this.dependencies.set(name, deps);
    Logger.debug('DependencyInjector', `Registered service: ${name} with dependencies: ${deps.join(', ')}`);
  }
  
  /**
   * 注册单例服务
   * Register singleton service
   * @param name 服务名称
   * @param instance 服务实例
   */
  public registerSingleton<T>(name: string, instance: T): void {
    this.services.set(name, instance);
    Logger.debug('DependencyInjector', `Registered singleton service: ${name}`);
  }
  
  /**
   * 解析服务
   * Resolve service
   * @param name 服务名称
   */
  public resolve<T>(name: string): T {
    // 检查服务是否已存在
    if (this.services.has(name)) {
      return this.services.get(name) as T;
    }
    
    // 检查服务是否已注册
    if (!this.factories.has(name)) {
      throw new Error(`Service not registered: ${name}`);
    }
    
    // 解析依赖
    const deps = this.dependencies.get(name) || [];
    const resolvedDeps = deps.map(dep => this.resolve(dep));
    
    // 创建服务实例
    const factory = this.factories.get(name)!;
    const instance = factory();
    
    // 保存服务实例
    this.services.set(name, instance);
    Logger.debug('DependencyInjector', `Resolved service: ${name}`);
    
    return instance as T;
  }
  
  /**
   * 检查服务是否已注册
   * Check if service is registered
   * @param name 服务名称
   */
  public isRegistered(name: string): boolean {
    return this.factories.has(name) || this.services.has(name);
  }
  
  /**
   * 检查服务是否已解析
   * Check if service is resolved
   * @param name 服务名称
   */
  public isResolved(name: string): boolean {
    return this.services.has(name);
  }
  
  /**
   * 获取所有注册的服务名称
   * Get all registered service names
   */
  public getRegisteredServices(): string[] {
    const serviceNames = Array.from(this.services.keys());
    const factoryNames = Array.from(this.factories.keys()).filter(name => !serviceNames.includes(name));
    return [...serviceNames, ...factoryNames];
  }
  
  /**
   * 清除所有服务
   * Clear all services
   */
  public clear(): void {
    this.services.clear();
    this.factories.clear();
    this.dependencies.clear();
    this.isInitialized = false;
    Logger.debug('DependencyInjector', 'Cleared all services');
  }
  
  /**
   * 初始化所有服务
   * Initialize all services
   */
  public initialize(): boolean {
    try {
      if (this.isInitialized) {
        Logger.debug('DependencyInjector', 'Already initialized');
        return true;
      }
      
      Logger.info('DependencyInjector', 'Initializing services...');
      
      // 解析所有注册的服务
      const factoryNames = Array.from(this.factories.keys());
      for (const name of factoryNames) {
        if (!this.services.has(name)) {
          this.resolve(name);
        }
      }
      
      this.isInitialized = true;
      Logger.info('DependencyInjector', `Initialized ${this.services.size} services`);
      return true;
    } catch (error) {
      Logger.error('DependencyInjector', `Failed to initialize services: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }
}

/**
 * 依赖注入装饰器
 * Dependency injection decorator
 */
export function Injectable() {
  return function(target: any) {
    // 标记类为可注入
    target.__injectable = true;
    return target;
  };
}

/**
 * 依赖注入令牌
 * Dependency injection tokens
 */
export const DI_TOKENS = {
  HTTP_SERVICE: 'httpService',
  CACHE_SERVICE: 'cacheService',
  CONFIG_SERVICE: 'configService',
  HISTORY_SERVICE: 'historyService',
  MEDIA_SERVICE: 'mediaService',
  SITE_SERVICE: 'siteService',
  PLAYBACK_SERVICE: 'playbackService',
  REPOSITORY_FACTORY: 'repositoryFactory'
};
