/**
 * 依赖管理器
 * 统一管理应用内的依赖注入和服务注册
 */

import { ServiceRegistry } from './ServiceRegistry';
import { DependencyInjector } from './DependencyInjector';

/**
 * 依赖类型枚举
 */
export enum DependencyType {
  SERVICE = 'service',
  REPOSITORY = 'repository',
  UTIL = 'util',
  COMPONENT = 'component',
  MANAGER = 'manager'
}

/**
 * 依赖元数据接口
 */
export interface DependencyMetadata {
  id: string;
  type: DependencyType;
  singleton: boolean;
  lazy: boolean;
  dependencies?: string[];
  version?: string;
}

export class DependencyManager {
  private static instance: DependencyManager;
  private serviceRegistry: ServiceRegistry = ServiceRegistry.getInstance();
  private dependencyInjector: DependencyInjector = DependencyInjector.getInstance();
  private dependencies: Map<string, { metadata: DependencyMetadata; factory: () => any }> = new Map();
  private instantiatedDependencies: Map<string, any> = new Map();

  private constructor() {}

  static getInstance(): DependencyManager {
    if (!DependencyManager.instance) {
      DependencyManager.instance = new DependencyManager();
    }
    return DependencyManager.instance;
  }

  /**
   * 注册依赖
   */
  register<T>(id: string, factory: () => T, metadata: Partial<DependencyMetadata> = {}): void {
    const defaultMetadata: DependencyMetadata = {
      id,
      type: DependencyType.SERVICE,
      singleton: true,
      lazy: true,
      dependencies: [],
      version: '1.0.0'
    };

    this.dependencies.set(id, {
      metadata: { ...defaultMetadata, ...metadata },
      factory
    });

    console.log(`Dependency registered: ${id}`);
  }

  /**
   * 获取依赖
   */
  get<T>(id: string): T | null {
    if (!this.dependencies.has(id)) {
      console.error(`Dependency not found: ${id}`);
      return null;
    }

    const { metadata, factory } = this.dependencies.get(id)!;

    // 如果是单例且已实例化，直接返回
    if (metadata.singleton && this.instantiatedDependencies.has(id)) {
      return this.instantiatedDependencies.get(id) as T;
    }

    // 解析依赖
    if (metadata.dependencies && metadata.dependencies.length > 0) {
      for (const depId of metadata.dependencies) {
        if (!this.instantiatedDependencies.has(depId) && this.dependencies.has(depId)) {
          this.get(depId);
        }
      }
    }

    // 实例化依赖
    try {
      const instance = factory();
      
      if (metadata.singleton) {
        this.instantiatedDependencies.set(id, instance);
      }

      return instance as T;
    } catch (error) {
      console.error(`Failed to instantiate dependency ${id}:`, error);
      return null;
    }
  }

  /**
   * 注册服务
   */
  registerService<T>(id: string, service: T, lazy: boolean = true): void {
    this.serviceRegistry.registerService(id, service, lazy);
  }

  /**
   * 获取服务
   */
  getService<T>(id: string): T | null {
    return this.serviceRegistry.getService<T>(id);
  }

  /**
   * 注销服务
   */
  unregisterService(id: string): void {
    this.serviceRegistry.unregisterService(id);
  }

  /**
   * 注入依赖到目标对象
   */
  inject(target: any): void {
    this.dependencyInjector.inject(target);
  }

  /**
   * 初始化所有非延迟加载的依赖
   */
  initializeEagerDependencies(): void {
    for (const [id, { metadata }] of this.dependencies.entries()) {
      if (!metadata.lazy && metadata.singleton) {
        this.get(id);
      }
    }
  }

  /**
   * 获取所有依赖
   */
  getAllDependencies(): string[] {
    return Array.from(this.dependencies.keys());
  }

  /**
   * 获取依赖元数据
   */
  getDependencyMetadata(id: string): DependencyMetadata | null {
    return this.dependencies.get(id)?.metadata || null;
  }

  /**
   * 清理依赖
   */
  clear(): void {
    this.instantiatedDependencies.clear();
    this.serviceRegistry.clear();
    console.log('Dependency manager cleared');
  }

  /**
   * 检查依赖是否存在
   */
  hasDependency(id: string): boolean {
    return this.dependencies.has(id);
  }

  /**
   * 检查服务是否存在
   */
  hasService(id: string): boolean {
    return this.serviceRegistry.hasService(id);
  }
}

/**
 * 依赖管理工具函数
 */
export const DependencyUtils = {
  /**
   * 安全获取依赖
   */
  safeGet<T>(id: string, fallback?: T): T | null {
    try {
      const manager = DependencyManager.getInstance();
      const dependency = manager.get<T>(id);
      return dependency || fallback || null;
    } catch (error) {
      console.error(`Failed to get dependency ${id}:`, error);
      return fallback || null;
    }
  },

  /**
   * 安全获取服务
   */
  safeGetService<T>(id: string, fallback?: T): T | null {
    try {
      const manager = DependencyManager.getInstance();
      const service = manager.getService<T>(id);
      return service || fallback || null;
    } catch (error) {
      console.error(`Failed to get service ${id}:`, error);
      return fallback || null;
    }
  },

  /**
   * 批量注册依赖
   */
  registerBatch(dependencies: Array<{
    id: string;
    factory: () => any;
    metadata?: Partial<DependencyMetadata>;
  }>): void {
    const manager = DependencyManager.getInstance();
    dependencies.forEach(dep => {
      manager.register(dep.id, dep.factory, dep.metadata);
    });
  },

  /**
   * 批量注册服务
   */
  registerServices(services: Array<{
    id: string;
    service: any;
    lazy?: boolean;
  }>): void {
    const manager = DependencyManager.getInstance();
    services.forEach(service => {
      manager.registerService(service.id, service.service, service.lazy);
    });
  }
};