/**
 * 增强版依赖注入容器 | Enhanced Dependency Injection Container
 * 提供更高级的依赖注入功能 | Provides more advanced dependency injection features
 */
import { DIContainer, ServiceDescriptor } from './Container';
import Logger from '../util/Logger';

/**
 * 服务生命周期 | Service lifetime
 */
export enum ServiceLifetime {
  SINGLETON = 'singleton',
  TRANSIENT = 'transient',
  SCOPED = 'scoped'
}

/**
 * 服务注册选项 | Service registration options
 */
export interface ServiceRegistrationOptions<T> {
  token: string;
  factory: () => T;
  lifetime?: ServiceLifetime;
  dependencies?: string[];
}

/**
 * 增强版依赖注入容器类 | Enhanced DI Container class
 */
export class EnhancedDIContainerClass extends DIContainer {
  private static enhancedInstance: EnhancedDIContainerClass | null = null;
  private scopedInstances: Map<string, Map<string, object>> = new Map();
  private currentScope: string | null = null;
  private enhancedLogger: Logger;

  /**
   * 获取增强版单例实例 | Get enhanced singleton instance
   */
  public static getEnhancedInstance(): EnhancedDIContainerClass {
    if (!EnhancedDIContainerClass.enhancedInstance) {
      EnhancedDIContainerClass.enhancedInstance = new EnhancedDIContainerClass();
    }
    return EnhancedDIContainerClass.enhancedInstance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    super();
    this.enhancedLogger = new Logger('EnhancedDIContainer');
  }

  /**
   * 注册服务（增强版） | Register service (enhanced)
   */
  public registerEnhanced<T extends object>(options: ServiceRegistrationOptions<T>): void {
    const lifetime = options.lifetime ?? ServiceLifetime.SINGLETON;
    const singleton = lifetime === ServiceLifetime.SINGLETON;
    
    this.register(options.token, options.factory, singleton, options.dependencies ?? []);
    this.enhancedLogger.info('Registered enhanced service: ' + options.token + ' (lifetime: ' + lifetime + ')');
  }

  /**
   * 开始作用域 | Begin scope
   */
  public beginScope(scopeId: string): void {
    if (this.scopedInstances.has(scopeId)) {
      this.enhancedLogger.warn('Scope ' + scopeId + ' already exists');
      return;
    }
    this.scopedInstances.set(scopeId, new Map());
    this.currentScope = scopeId;
    this.enhancedLogger.info('Began scope: ' + scopeId);
  }

  /**
   * 结束作用域 | End scope
   */
  public endScope(scopeId: string): void {
    const scope = this.scopedInstances.get(scopeId);
    if (scope) {
      scope.clear();
      this.scopedInstances.delete(scopeId);
      if (this.currentScope === scopeId) {
        this.currentScope = null;
      }
      this.enhancedLogger.info('Ended scope: ' + scopeId);
    }
  }

  /**
   * 在作用域内解析服务 | Resolve service within scope
   */
  public resolveScoped<T extends object>(token: string, scopeId?: string): T {
    const activeScope = scopeId ?? this.currentScope;
    if (!activeScope) {
      return this.resolve<T>(token);
    }

    const scope = this.scopedInstances.get(activeScope);
    if (!scope) {
      this.enhancedLogger.warn('Scope ' + activeScope + ' not found, resolving as normal');
      return this.resolve<T>(token);
    }

    if (scope.has(token)) {
      return scope.get(token) as T;
    }

    const instance = this.resolve<T>(token);
    scope.set(token, instance);
    return instance;
  }

  /**
   * 批量注册服务 | Batch register services
   */
  public registerBatch<T extends object>(registrations: ServiceRegistrationOptions<T>[]): void {
    for (const registration of registrations) {
      this.registerEnhanced(registration);
    }
    this.enhancedLogger.info('Batch registered ' + registrations.length + ' services');
  }

  /**
   * 尝试解析服务 | Try resolve service
   */
  public tryResolve<T extends object>(token: string): T | null {
    try {
      return this.resolve<T>(token);
    } catch (error) {
      this.enhancedLogger.warn('Failed to resolve service ' + token + ': ' + (error instanceof Error ? error.message : String(error)));
      return null;
    }
  }

  /**
   * 验证所有依赖 | Validate all dependencies
   */
  public validateDependencies(): boolean {
    const tokens = this.getAllTokens();
    let allValid = true;
    
    for (const token of tokens) {
      try {
        this.resolve(token);
      } catch (error) {
        this.enhancedLogger.error('Dependency validation failed for ' + token);
        allValid = false;
      }
    }
    
    return allValid;
  }

  /**
   * 获取容器统计信息 | Get container statistics
   */
  public getStatistics(): object {
    const tokens = this.getAllTokens();
    const stats = {
      totalServices: tokens.length,
      activeScopes: this.scopedInstances.size,
      currentScope: this.currentScope
    };
    return stats;
  }
}

// 导出单例实例 | Export singleton instance
const EnhancedDIContainer = EnhancedDIContainerClass.getEnhancedInstance();
export default EnhancedDIContainer;
