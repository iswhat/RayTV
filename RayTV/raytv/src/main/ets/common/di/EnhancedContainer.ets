/**
 * 增强的依赖注入容器 | Enhanced Dependency Injection Container
 * 扩展基础DI容器，支持延迟解析、批量注册和更高级的生命周期管理
 */
import { DIContainer, ServiceFactory } from './Container';
import Logger from '../util/Logger';

// 增强的依赖注入容器类 | Enhanced dependency injection container class
export class EnhancedDIContainer extends DIContainer {
  private static instance: EnhancedDIContainer | null = null;
  private lazyResolvers: Map<string, ServiceFactory<any>> = new Map();
  private logger: Logger;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): EnhancedDIContainer {
    if (!EnhancedDIContainer.instance) {
      EnhancedDIContainer.instance = new EnhancedDIContainer();
    }
    return EnhancedDIContainer.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    super();
    this.logger = new Logger('EnhancedDIContainer');
  }

  /**
   * 注册延迟解析服务 | Register lazy resolution service
   * @param token 服务标识符 | Service token
   * @param resolver 服务解析器函数 | Service resolver function
   * @param singleton 是否单例 | Whether singleton
   */
  public registerLazy<T>(token: string, resolver: ServiceFactory<T>, singleton: boolean = true): void {
    if (this.lazyResolvers.has(token)) {
      this.logger.warn(`Lazy service ${token} already registered, overriding...`);
    }

    this.lazyResolvers.set(token, resolver);
    this.logger.info(`Registered lazy service: ${token} (singleton: ${singleton})`);
  }

  /**
   * 解析服务（支持延迟加载） | Resolve service (supports lazy loading)
   * @param token 服务标识符 | Service token
   * @param resolving 正在解析的服务链，用于检测循环依赖 | Resolving service chain for circular dependency detection
   * @returns 服务实例 | Service instance
   */
  public override resolve<T>(token: string, resolving: Set<string> = new Set()): T {
    // 先检查是否有延迟解析的服务 | First check if there's a lazy resolver
    if (this.lazyResolvers.has(token)) {
      // 检测循环依赖 | Detect circular dependency
      if (resolving.has(token)) {
        const chain = Array.from(resolving).join(' -> ') + ' -> ' + token;
        throw new Error(`Circular dependency detected: ${chain}`);
      }
      
      try {
        // 添加到正在解析的服务链 | Add to resolving chain
        resolving.add(token);
        
        const resolver = this.lazyResolvers.get(token)!;
        const instance = resolver();
        
        // 注册为常规服务 | Register as regular service
        super.register(token, () => instance, true);
        this.lazyResolvers.delete(token);
        
        // 从正在解析的服务链中移除 | Remove from resolving chain
        resolving.delete(token);
        
        this.logger.info(`Resolved and registered lazy service: ${token}`);
        return instance;
      } catch (error) {
        // 确保从解析链中移除 | Ensure removed from resolving chain
        resolving.delete(token);
        this.logger.error(`Failed to resolve lazy service ${token}`, error);
        throw error;
      }
    }

    // 调用父类的解析方法 | Call parent's resolve method
    return super.resolve<T>(token, resolving);
  }

  /**
   * 批量注册服务 | Batch register services
   * @param services 服务配置数组 | Service configuration array
   */
  public registerBatch(services: Array<{
    token: string;
    factory: ServiceFactory<any>;
    singleton?: boolean;
    dependencies?: string[];
  }>): void {
    services.forEach(({ token, factory, singleton = true, dependencies = [] }) => {
      super.register(token, factory, singleton, dependencies);
    });
    this.logger.info(`Batch registered ${services.length} services`);
  }

  /**
   * 批量注册延迟解析服务 | Batch register lazy services
   * @param services 延迟服务配置数组 | Lazy service configuration array
   */
  public registerBatchLazy(services: Array<{
    token: string;
    resolver: ServiceFactory<any>;
    singleton?: boolean;
  }>): void {
    services.forEach(({ token, resolver, singleton = true }) => {
      this.registerLazy(token, resolver, singleton);
    });
    this.logger.info(`Batch registered ${services.length} lazy services`);
  }

  /**
   * 检查服务是否为延迟解析 | Check if service is lazy resolved
   * @param token 服务标识符 | Service token
   * @returns 是否为延迟解析服务 | Whether it's a lazy service
   */
  public isLazyService(token: string): boolean {
    return this.lazyResolvers.has(token);
  }

  /**
   * 获取所有延迟解析服务 | Get all lazy services
   * @returns 延迟服务标识符数组 | Lazy service token array
   */
  public getAllLazyTokens(): string[] {
    return Array.from(this.lazyResolvers.keys());
  }

  /**
   * 清除延迟解析服务 | Clear lazy service
   * @param token 可选的服务标识符，如果不提供则清除所有 | Optional service token, clears all if not provided
   */
  public clearLazyService(token?: string): void {
    if (token) {
      if (this.lazyResolvers.has(token)) {
        this.lazyResolvers.delete(token);
        this.logger.info(`Cleared lazy service: ${token}`);
      }
    } else {
      // 清除所有延迟解析服务 | Clear all lazy services
      this.lazyResolvers.clear();
      this.logger.info('Cleared all lazy services');
    }
  }

  /**
   * 销毁容器 | Destroy container
   */
  public override destroy(): void {
    this.clearLazyService();
    super.destroy();
    this.logger.info('EnhancedDIContainer destroyed');
  }
}

// 导出单例实例 | Export singleton instance
export default EnhancedDIContainer.getInstance();
