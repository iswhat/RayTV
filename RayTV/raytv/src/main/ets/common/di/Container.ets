/**
 * 依赖注入容器 | Dependency Injection Container
 * 为壳应用提供服务注册、解析和生命周期管理 | Provides service registration, resolution and lifecycle management for shell applications
 */
import Logger from '../util/Logger';

// 服务工厂类型 | Service factory type
export type ServiceFactory<T> = () => T;

// 服务描述符 | Service descriptor
export interface ServiceDescriptor<T> {
  token: string;
  factory: ServiceFactory<T>;
  singleton: boolean;
  instance?: T;
  dependencies: string[];
}

const TAG: string = 'DIContainer';

// 依赖注入容器类 | Dependency injection container class
export class DIContainer {
  private static instance: DIContainer | null = null;
  private services: Map<string, ServiceDescriptor<object>> = new Map();
  private resolvedInstances: Map<string, object> = new Map();

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): DIContainer {
    if (!DIContainer.instance) {
      DIContainer.instance = new DIContainer();
    }
    return DIContainer.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
  }

  /**
   * 注册服务 | Register service
   * @param token 服务标识符 | Service token
   * @param factory 服务工厂函数 | Service factory function
   * @param singleton 是否单例 | Whether singleton
   * @param dependencies 依赖的服务标识符 | Dependent service tokens
   */
  public register<T extends object>(
    token: string,
    factory: ServiceFactory<T>,
    singleton: boolean = true,
    dependencies: string[] = []
  ): void {
    if (this.services.has(token)) {
      Logger.warn(TAG, `Service ${token} already registered, overriding...`);
    }

    const descriptor: ServiceDescriptor<T> = {
      token,
      factory,
      singleton,
      dependencies,
      instance: undefined
    };

    this.services.set(token, descriptor as ServiceDescriptor<object>);
    Logger.info(TAG, `Registered service: ${token} (singleton: ${singleton})`);
  }

  /**
   * 解析服务 | Resolve service
   * @param token 服务标识符 | Service token
   * @param resolving 正在解析的服务链，用于检测循环依赖 | Resolving service chain for circular dependency detection
   * @returns 服务实例 | Service instance
   */
  public resolve<T extends object>(token: string, resolving: Set<string> = new Set()): T {
    const descriptor = this.services.get(token) as ServiceDescriptor<T> | undefined;
    if (!descriptor) {
      throw new Error(`Service ${token} not registered`);
    }

    // 如果是单例且已有实例，直接返回 | If singleton and instance exists, return directly
    if (descriptor.singleton && descriptor.instance !== undefined) {
      return descriptor.instance;
    }

    // 检测循环依赖 | Detect circular dependency
    if (resolving.has(token)) {
      const chain = Array.from(resolving).join(' -> ') + ' -> ' + token;
      throw new Error(`Circular dependency detected: ${chain}`);
    }

    try {
      // 添加到正在解析的服务链 | Add to resolving chain
      resolving.add(token);
      
      // 解析依赖 | Resolve dependencies
      const dependencies = this.resolveDependencies(descriptor.dependencies, resolving);
      
      // 创建实例 | Create instance
      // ServiceFactory 是无参数函数，直接调用
      const instance = descriptor.factory();
      
      // 如果是单例，缓存实例 | If singleton, cache instance
      if (descriptor.singleton) {
        descriptor.instance = instance;
        this.resolvedInstances.set(token, instance);
      }

      // 从正在解析的服务链中移除 | Remove from resolving chain
      resolving.delete(token);
      
      Logger.info(TAG, `Resolved service: ${token}`);
      return instance;

    } catch (error) {
      // 确保从解析链中移除 | Ensure removed from resolving chain
      resolving.delete(token);
      Logger.error(TAG, `Failed to resolve service ${token}`, error instanceof Error ? error : new Error(String(error)));
      throw new Error(`Failed to resolve service ${token}: ${(error as Error).message}`);
    }
  }

  /**
   * 解析多个服务 | Resolve multiple services
   * @param tokens 服务标识符数组 | Service token array
   * @returns 服务实例数组 | Service instance array
   */
  public resolveAll<T extends object>(tokens: string[]): T[] {
    return tokens.map(token => this.resolve<T>(token));
  }

  /**
   * 检查服务是否存在 | Check if service exists
   * @param token 服务标识符 | Service token
   * @returns 是否存在 | Whether exists
   */
  public has(token: string): boolean {
    return this.services.has(token);
  }

  /**
   * 获取所有已注册的服务标识符 | Get all registered service tokens
   * @returns 服务标识符数组 | Service token array
   */
  public getAllTokens(): string[] {
    return Array.from(this.services.keys());
  }

  /**
   * 清除单例实例 | Clear singleton instances
   * @param token 可选的服务标识符，如果不提供则清除所有 | Optional service token, clears all if not provided
   */
  public clearSingleton(token?: string): void {
    if (token) {
      const descriptor = this.services.get(token);
      if (descriptor && descriptor.singleton) {
        descriptor.instance = undefined;
        this.resolvedInstances.delete(token);
        Logger.info(TAG, `Cleared singleton instance for: ${token}`);
      }
    } else {
      // 清除所有单例实例 | Clear all singleton instances
      this.services.forEach((descriptor: ServiceDescriptor<object>, token: string) => {
        if (descriptor.singleton) {
          descriptor.instance = undefined;
        }
      });
      this.resolvedInstances.clear();
      Logger.info(TAG, 'Cleared all singleton instances');
    }
  }

  /**
   * 销毁容器 | Destroy container
   */
  public destroy(): void {
    this.clearSingleton();
    this.services.clear();
    Logger.info(TAG, 'DIContainer destroyed');
  }

  /**
   * 解析依赖 | Resolve dependencies
   * @param dependencies 依赖的服务标识符 | Dependent service tokens
   * @param resolving 正在解析的服务链，用于检测循环依赖 | Resolving service chain for circular dependency detection
   * @returns 依赖实例数组 | Dependency instance array
   */
  private resolveDependencies(dependencies: string[], resolving: Set<string>): object[] {
    return dependencies.map((depToken: string): object => {
      try {
        return this.resolve<object>(depToken, resolving);
      } catch (error) {
        Logger.error(TAG, `Failed to resolve dependency: ${depToken}`, error instanceof Error ? error : new Error(String(error)));
        throw new Error(`Missing dependency: ${depToken}`);
      }
    });
  }
}

// 便捷的装饰器和工具函数 | Convenient decorators and utility functions

/**
 * 属性描述符类型 | Property descriptor type
 */
interface PropertyDescriptorType {
  value?: object;
  writable?: boolean;
  enumerable?: boolean;
  configurable?: boolean;
  get?: () => object;
  set?: (value: object) => void;
}

/**
 * 服务装饰器 | Service decorator
 * @param token 服务标识符 | Service token
 * @param singleton 是否单例 | Whether singleton
 */
export function Service(token: string, singleton: boolean = true): void {
  // ArkTS 装饰器限制，简化实现
  // Service 装饰器需要在类定义时手动调用 register 方法
}

/**
 * 注入装饰器 | Inject decorator
 * @param token 服务标识符 | Service token
 */
export function Inject(token: string) {
  return (target: object, propertyKey: string): void => {
    // 简化实现，避免使用Object.defineProperty
    // 在使用时通过容器手动解析
  };
}

/**
 * 工厂装饰器 | Factory decorator
 * @param token 服务标识符 | Service token
 * @param singleton 是否单例 | Whether singleton
 */
export function Factory(token: string, singleton: boolean = true) {
  return (target: object, propertyKey: string, descriptor: PropertyDescriptorType): void => {
    const container = DIContainer.getInstance();
    const factory = descriptor.value as ServiceFactory<object>;
    container.register(token, factory, singleton);
  };
}

// 导出单例实例 | Export singleton instance
export default DIContainer.getInstance();