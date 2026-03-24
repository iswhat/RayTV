/**
 * 服务生命周期管理 | Service Lifecycle Management
 * 定义服务的生命周期接口和管理类
 */
import Logger from '../util/Logger';

// 服务生命周期接口 | Service lifecycle interface
export interface ServiceLifecycle {
  /**
   * 初始化服务 | Initialize service
   */
  onInitialize?(): Promise<void>;

  /**
   * 销毁服务 | Destroy service
   */
  onDestroy?(): Promise<void>;

  /**
   * 激活服务 | Activate service
   */
  onActivate?(): void;

  /**
   * 停用服务 | Deactivate service
   */
  onDeactivate?(): void;
}

// 生命周期管理类 | Lifecycle manager class
export class LifecycleManager {
  private static instance: LifecycleManager | null = null;
  private services: Map<string, ServiceLifecycle> = new Map();
  private logger: Logger;
  private initializedServices: Set<string> = new Set();
  private activeServices: Set<string> = new Set();

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): LifecycleManager {
    if (!LifecycleManager.instance) {
      LifecycleManager.instance = new LifecycleManager();
    }
    return LifecycleManager.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.logger = new Logger('LifecycleManager');
  }

  /**
   * 注册服务 | Register service
   * @param token 服务标识符 | Service token
   * @param service 服务实例 | Service instance
   */
  public registerService(token: string, service: ServiceLifecycle): void {
    if (this.services.has(token)) {
      this.logger.warn(`Service ${token} already registered in lifecycle manager, overriding...`);
    }

    this.services.set(token, service);
    this.logger.info(`Registered service for lifecycle management: ${token}`);
  }

  /**
   * 注册多个服务 | Register multiple services
   * @param services 服务配置数组 | Service configuration array
   */
  public registerServices(services: Array<{
    token: string;
    service: ServiceLifecycle;
  }>): void {
    services.forEach(({ token, service }) => {
      this.registerService(token, service);
    });
    this.logger.info(`Registered ${services.length} services for lifecycle management`);
  }

  /**
   * 初始化所有服务 | Initialize all services
   */
  public async initializeAll(): Promise<void> {
    const promises = Array.from(this.services.entries()).map(async ([token, service]) => {
      try {
        if (service.onInitialize) {
          await service.onInitialize();
          this.initializedServices.add(token);
          this.logger.info(`Initialized service: ${token}`);
        }
      } catch (error) {
        this.logger.error(`Failed to initialize service ${token}:`, error);
      }
    });

    await Promise.all(promises);
    this.logger.info(`Initialized ${this.initializedServices.size} out of ${this.services.size} services`);
  }

  /**
   * 初始化单个服务 | Initialize single service
   * @param token 服务标识符 | Service token
   */
  public async initializeService(token: string): Promise<boolean> {
    const service = this.services.get(token);
    if (!service) {
      this.logger.error(`Service ${token} not registered`);
      return false;
    }

    if (this.initializedServices.has(token)) {
      this.logger.warn(`Service ${token} already initialized`);
      return true;
    }

    try {
      if (service.onInitialize) {
        await service.onInitialize();
        this.initializedServices.add(token);
        this.logger.info(`Initialized service: ${token}`);
        return true;
      }
    } catch (error) {
      this.logger.error(`Failed to initialize service ${token}:`, error);
    }

    return false;
  }

  /**
   * 销毁所有服务 | Destroy all services
   */
  public async destroyAll(): Promise<void> {
    const promises = Array.from(this.services.entries()).map(async ([token, service]) => {
      try {
        if (service.onDestroy) {
          await service.onDestroy();
          this.logger.info(`Destroyed service: ${token}`);
        }
      } catch (error) {
        this.logger.error(`Failed to destroy service ${token}:`, error);
      }
    });

    await Promise.all(promises);
    this.initializedServices.clear();
    this.activeServices.clear();
    this.logger.info(`Destroyed all services`);
  }

  /**
   * 销毁单个服务 | Destroy single service
   * @param token 服务标识符 | Service token
   */
  public async destroyService(token: string): Promise<boolean> {
    const service = this.services.get(token);
    if (!service) {
      this.logger.error(`Service ${token} not registered`);
      return false;
    }

    try {
      if (service.onDestroy) {
        await service.onDestroy();
        this.initializedServices.delete(token);
        this.activeServices.delete(token);
        this.logger.info(`Destroyed service: ${token}`);
        return true;
      }
    } catch (error) {
      this.logger.error(`Failed to destroy service ${token}:`, error);
    }

    return false;
  }

  /**
   * 激活所有服务 | Activate all services
   */
  public activateAll(): void {
    this.services.forEach((service, token) => {
      try {
        if (service.onActivate) {
          service.onActivate();
          this.activeServices.add(token);
          this.logger.info(`Activated service: ${token}`);
        }
      } catch (error) {
        this.logger.error(`Failed to activate service ${token}:`, error);
      }
    });
    this.logger.info(`Activated ${this.activeServices.size} out of ${this.services.size} services`);
  }

  /**
   * 激活单个服务 | Activate single service
   * @param token 服务标识符 | Service token
   */
  public activateService(token: string): boolean {
    const service = this.services.get(token);
    if (!service) {
      this.logger.error(`Service ${token} not registered`);
      return false;
    }

    try {
      if (service.onActivate) {
        service.onActivate();
        this.activeServices.add(token);
        this.logger.info(`Activated service: ${token}`);
        return true;
      }
    } catch (error) {
      this.logger.error(`Failed to activate service ${token}:`, error);
    }

    return false;
  }

  /**
   * 停用所有服务 | Deactivate all services
   */
  public deactivateAll(): void {
    this.services.forEach((service, token) => {
      try {
        if (service.onDeactivate) {
          service.onDeactivate();
          this.activeServices.delete(token);
          this.logger.info(`Deactivated service: ${token}`);
        }
      } catch (error) {
        this.logger.error(`Failed to deactivate service ${token}:`, error);
      }
    });
    this.logger.info(`Deactivated all services`);
  }

  /**
   * 停用单个服务 | Deactivate single service
   * @param token 服务标识符 | Service token
   */
  public deactivateService(token: string): boolean {
    const service = this.services.get(token);
    if (!service) {
      this.logger.error(`Service ${token} not registered`);
      return false;
    }

    try {
      if (service.onDeactivate) {
        service.onDeactivate();
        this.activeServices.delete(token);
        this.logger.info(`Deactivated service: ${token}`);
        return true;
      }
    } catch (error) {
      this.logger.error(`Failed to deactivate service ${token}:`, error);
    }

    return false;
  }

  /**
   * 检查服务是否已初始化 | Check if service is initialized
   * @param token 服务标识符 | Service token
   */
  public isInitialized(token: string): boolean {
    return this.initializedServices.has(token);
  }

  /**
   * 检查服务是否激活 | Check if service is active
   * @param token 服务标识符 | Service token
   */
  public isActive(token: string): boolean {
    return this.activeServices.has(token);
  }

  /**
   * 获取所有已初始化的服务 | Get all initialized services
   */
  public getInitializedServices(): string[] {
    return Array.from(this.initializedServices);
  }

  /**
   * 获取所有激活的服务 | Get all active services
   */
  public getActiveServices(): string[] {
    return Array.from(this.activeServices);
  }

  /**
   * 移除服务 | Remove service
   * @param token 服务标识符 | Service token
   */
  public removeService(token: string): void {
    this.services.delete(token);
    this.initializedServices.delete(token);
    this.activeServices.delete(token);
    this.logger.info(`Removed service from lifecycle management: ${token}`);
  }

  /**
   * 清除所有服务 | Clear all services
   */
  public clear(): void {
    this.services.clear();
    this.initializedServices.clear();
    this.activeServices.clear();
    this.logger.info(`Cleared all services from lifecycle management`);
  }

  /**
   * 获取服务数量 | Get service count
   */
  public getServiceCount(): number {
    return this.services.size;
  }
}

// 导出单例实例 | Export singleton instance
export default LifecycleManager.getInstance();
