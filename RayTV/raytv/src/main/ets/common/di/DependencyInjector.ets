/**
 * 依赖注入器 | Dependency Injector
 * 提供简化的依赖注入接口 | Provides simplified dependency injection interface
 */
import { DIContainer, Service, Inject, Factory } from './Container';
import Logger from '../util/Logger';

/**
 * 注入器配置 | Injector configuration
 */
export interface InjectorConfig {
  autoRegister?: boolean;
  strictMode?: boolean;
  enableLogging?: boolean;
}

/**
 * 服务元数据 | Service metadata
 */
export interface ServiceMetadata {
  token: string;
  registered: boolean;
  singleton: boolean;
  resolvedCount: number;
}

/**
 * 依赖注入器类 | Dependency Injector class
 */
export class DependencyInjector {
  private static instance: DependencyInjector | null = null;
  private container: DIContainer;
  private config: InjectorConfig;
  private logger: Logger;
  private resolvedCounts: Map<string, number> = new Map();

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): DependencyInjector {
    if (!DependencyInjector.instance) {
      DependencyInjector.instance = new DependencyInjector();
    }
    return DependencyInjector.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.container = DIContainer.getInstance();
    this.config = {
      autoRegister: true,
      strictMode: false,
      enableLogging: true
    };
    this.logger = new Logger('DependencyInjector');
  }

  /**
   * 配置注入器 | Configure injector
   */
  public configure(config: Partial<InjectorConfig>): void {
    if (config.autoRegister !== undefined) {
      this.config.autoRegister = config.autoRegister;
    }
    if (config.strictMode !== undefined) {
      this.config.strictMode = config.strictMode;
    }
    if (config.enableLogging !== undefined) {
      this.config.enableLogging = config.enableLogging;
    }
    this.logger.info('Injector configured');
  }

  /**
   * 注册服务 | Register service
   */
  public registerService<T extends object>(
    token: string,
    factory: () => T,
    singleton: boolean = true
  ): void {
    this.container.register(token, factory, singleton);
    this.logger.info('Service registered: ' + token);
  }

  /**
   * 获取服务 | Get service
   */
  public getService<T extends object>(token: string): T {
    try {
      const instance = this.container.resolve<T>(token);
      
      // 更新解析计数
      const count = this.resolvedCounts.get(token) ?? 0;
      this.resolvedCounts.set(token, count + 1);
      
      return instance;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logger.error('Failed to get service: ' + token + ' - ' + errorMessage);
      
      if (this.config.strictMode) {
        throw error;
      }
      
      throw new Error('Service not found: ' + token);
    }
  }

  /**
   * 尝试获取服务 | Try get service
   */
  public tryGetService<T extends object>(token: string): T | null {
    try {
      return this.getService<T>(token);
    } catch (error) {
      return null;
    }
  }

  /**
   * 检查服务是否已注册 | Check if service is registered
   */
  public hasService(token: string): boolean {
    return this.container.has(token);
  }

  /**
   * 获取所有服务元数据 | Get all service metadata
   */
  public getAllServicesMetadata(): ServiceMetadata[] {
    const tokens = this.container.getAllTokens();
    const metadata: ServiceMetadata[] = [];
    
    for (const token of tokens) {
      metadata.push({
        token: token,
        registered: true,
        singleton: true,
        resolvedCount: this.resolvedCounts.get(token) ?? 0
      });
    }
    
    return metadata;
  }

  /**
   * 清除所有单例实例 | Clear all singleton instances
   */
  public clearAll(): void {
    this.container.clearSingleton();
    this.resolvedCounts.clear();
    this.logger.info('All singleton instances cleared');
  }

  /**
   * 验证所有依赖 | Validate all dependencies
   */
  public validate(): boolean {
    const tokens = this.container.getAllTokens();
    let allValid = true;
    
    for (const token of tokens) {
      if (!this.container.has(token)) {
        this.logger.error('Missing dependency: ' + token);
        allValid = false;
      }
    }
    
    return allValid;
  }

  /**
   * 获取容器实例 | Get container instance
   */
  public getContainer(): DIContainer {
    return this.container;
  }

  /**
   * 销毁注入器 | Destroy injector
   */
  public destroy(): void {
    this.container.destroy();
    this.resolvedCounts.clear();
    this.logger.info('DependencyInjector destroyed');
  }
}

// 导出单例实例 | Export singleton instance
export default DependencyInjector.getInstance();
