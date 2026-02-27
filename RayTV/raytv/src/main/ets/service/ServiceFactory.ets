import Logger from '../../../common/util/Logger';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import ConfigService from '../../service/config/ConfigService';
import HistoryService from '../../service/media/HistoryService';
import { SiteService } from './spider/SiteService';
import { ConfigManager } from './ConfigManager';
import { HistoryManager } from './HistoryManager';
import HttpService from './HttpService';
import PlaybackService from './playback/PlaybackService';
import MediaService from './media/MediaService';
import CacheService from './cache/CacheService';
import { FactoryBase } from '../../../common/base/FactoryBase';
import { DependencyInjector, DI_TOKENS } from '../../../common/di/DependencyInjector';

/**
 * 服务接口定义
 * Service interface definition
 */
export interface Service {
  /**
   * 初始化服务
   * Initialize service
   */
  initialize?: () => Promise<void>;
  
  /**
   * 销毁服务
   * Destroy service
   */
  destroy?: () => Promise<void>;
  
  /**
   * 健康检查
   * Health check
   */
  healthCheck?: () => Promise<boolean>;
  
  /**
   * 获取服务状态
   * Get service status
   */
  getStatus?: () => ServiceStatus;
}

/**
 * 服务状态枚举
 * Service status enum
 */
export enum ServiceStatus {
  UNINITIALIZED,
  INITIALIZING,
  READY,
  ERROR,
  DESTROYED
}

/**
 * 服务类型定义
 * Service type definition
 */
export enum ServiceType {
  CONFIG,
  HISTORY,
  SITE,
  HTTP,
  PLAYBACK,
  MEDIA,
  CACHE,
  CONFIG_MANAGER,
  HISTORY_MANAGER
}

/**
 * 服务实例类型联合
 * Service instance type union
 */
export type ServiceInstance = ConfigService | HistoryService | SiteService | HttpService | PlaybackService | MediaService | CacheService | ConfigManager | HistoryManager;

/**
 * 服务工厂类
 * 负责创建和管理各种服务的实例
 * Service factory class
 * Responsible for creating and managing instances of various services
 */
export default class ServiceFactory extends FactoryBase<ServiceType, ServiceInstance> {
  protected readonly TAG: string = 'ServiceFactory';
  
  /**
   * 服务状态映射
   * Service status map
   */
  private serviceStatusMap: Map<ServiceType, ServiceStatus> = new Map();

  private injector: DependencyInjector;

  /**
   * 私有构造函数
   * Private constructor
   */
  private constructor() {
    super();
    // 初始化服务状态
    this.initializeServiceStatus();
    // 初始化依赖注入容器
    this.injector = DependencyInjector.getInstance();
    // 注册服务到依赖注入容器
    this.registerServices();
  }
  
  /**
   * 注册服务到依赖注入容器
   * Register services to dependency injection container
   */
  private registerServices(): void {
    try {
      Logger.info(this.TAG, 'Registering services to dependency injector...');
      
      // 注册RepositoryFactory
      this.injector.registerSingleton(DI_TOKENS.REPOSITORY_FACTORY, RepositoryFactory.getInstance());
      
      // 注册基础服务
      this.injector.register(DI_TOKENS.HTTP_SERVICE, () => HttpService.getInstance(), []);
      this.injector.register(DI_TOKENS.CACHE_SERVICE, () => CacheService.getInstance(), []);
      
      // 注册核心服务
      this.injector.register(DI_TOKENS.CONFIG_SERVICE, () => ConfigService.getInstance(), [DI_TOKENS.HTTP_SERVICE, DI_TOKENS.CACHE_SERVICE]);
      this.injector.register(DI_TOKENS.HISTORY_SERVICE, () => HistoryService.getInstance(), []);
      
      // 注册业务服务
      this.injector.register(DI_TOKENS.MEDIA_SERVICE, () => MediaService.getInstance(), [DI_TOKENS.HTTP_SERVICE, DI_TOKENS.CACHE_SERVICE]);
      this.injector.register(DI_TOKENS.SITE_SERVICE, () => SiteService.getInstance(), [DI_TOKENS.HTTP_SERVICE, DI_TOKENS.CACHE_SERVICE]);
      this.injector.register(DI_TOKENS.PLAYBACK_SERVICE, () => PlaybackService.getInstance(), [DI_TOKENS.MEDIA_SERVICE]);
      
      Logger.info(this.TAG, 'Services registered to dependency injector successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to register services: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 初始化服务状态
   * Initialize service status
   */
  private initializeServiceStatus(): void {
    Object.values(ServiceType).forEach(type => {
      if (typeof type === 'number') {
        this.serviceStatusMap.set(type, ServiceStatus.UNINITIALIZED);
      }
    });
  }

  /**
   * 服务依赖关系定义
   * Service dependency definition
   */
  private static readonly SERVICE_DEPENDENCIES: Map<ServiceType, ServiceType[]> = new Map([
    [ServiceType.CONFIG, [ServiceType.CACHE, ServiceType.HTTP]],
    [ServiceType.MEDIA, [ServiceType.HTTP, ServiceType.CACHE]],
    [ServiceType.SITE, [ServiceType.HTTP, ServiceType.CACHE]],
    [ServiceType.PLAYBACK, [ServiceType.MEDIA]],
    [ServiceType.CONFIG_MANAGER, [ServiceType.CONFIG]],
    [ServiceType.HISTORY_MANAGER, [ServiceType.HISTORY]]
  ]);

  /**
   * 检查循环依赖
   * Check for circular dependencies
   * @param serviceType 服务类型
   * @param visited 已访问的服务类型
   * @returns 是否存在循环依赖
   */
  private checkCircularDependency(serviceType: ServiceType, visited: Set<ServiceType>): boolean {
    if (visited.has(serviceType)) {
      Logger.error(this.TAG, `Circular dependency detected for service: ${ServiceType[serviceType]}`);
      return true;
    }
    
    visited.add(serviceType);
    
    const dependencies = ServiceFactory.SERVICE_DEPENDENCIES.get(serviceType);
    if (dependencies) {
      for (const dep of dependencies) {
        if (this.checkCircularDependency(dep, new Set(visited))) {
          return true;
        }
      }
    }
    
    visited.delete(serviceType);
    return false;
  }

  /**
   * 拓扑排序服务依赖
   * Topological sort service dependencies
   * @returns 排序后的服务类型数组
   */
  private topologicalSort(): ServiceType[] {
    const result: ServiceType[] = [];
    const visited = new Set<ServiceType>();
    const temp = new Set<ServiceType>();
    
    const visit = (serviceType: ServiceType) => {
      if (temp.has(serviceType)) {
        throw new Error(`Circular dependency detected for service: ${ServiceType[serviceType]}`);
      }
      
      if (!visited.has(serviceType)) {
        temp.add(serviceType);
        
        const dependencies = ServiceFactory.SERVICE_DEPENDENCIES.get(serviceType);
        if (dependencies) {
          for (const dep of dependencies) {
            visit(dep);
          }
        }
        
        temp.delete(serviceType);
        visited.add(serviceType);
        result.push(serviceType);
      }
    };
    
    // 访问所有服务类型
    Object.values(ServiceType).forEach(type => {
      if (typeof type === 'number') {
        if (!visited.has(type)) {
          visit(type);
        }
      }
    });
    
    return result;
  }

  /**
   * 服务初始化分组
   * Service initialization groups
   */
  private static readonly INITIALIZATION_GROUPS: ServiceType[][] = [
    // 第1组：基础服务
    [ServiceType.CACHE, ServiceType.HTTP],
    // 第2组：核心服务
    [ServiceType.CONFIG, ServiceType.HISTORY],
    // 第3组：业务服务
    [ServiceType.MEDIA, ServiceType.SITE, ServiceType.PLAYBACK],
    // 第4组：管理器服务
    [ServiceType.CONFIG_MANAGER, ServiceType.HISTORY_MANAGER]
  ];

  /**
   * 初始化服务
   * Initialize service
   * @param serviceType 服务类型
   * @returns 是否初始化成功
   */
  private async initializeService(serviceType: ServiceType): Promise<boolean> {
    try {
      // 检查服务状态
      const currentStatus = this.serviceStatusMap.get(serviceType);
      if (currentStatus === ServiceStatus.INITIALIZING) {
        Logger.warn(this.TAG, `Service ${ServiceType[serviceType]} is already initializing`);
        return false;
      }
      
      if (currentStatus === ServiceStatus.READY) {
        Logger.info(this.TAG, `Service ${ServiceType[serviceType]} is already initialized`);
        return true;
      }
      
      // 更新服务状态为初始化中
      this.serviceStatusMap.set(serviceType, ServiceStatus.INITIALIZING);
      Logger.info(this.TAG, `Initializing service: ${ServiceType[serviceType]}`);

      // 检查依赖项
      const dependencies = ServiceFactory.SERVICE_DEPENDENCIES.get(serviceType);
      if (dependencies) {
        for (const dep of dependencies) {
          if (!this.isInstanceInitialized(dep)) {
            Logger.warn(this.TAG, `Dependency ${ServiceType[dep]} not initialized, initializing now`);
            const depResult = await this.initializeService(dep);
            if (!depResult) {
              Logger.error(this.TAG, `Failed to initialize dependency ${ServiceType[dep]} for ${ServiceType[serviceType]}`);
              this.serviceStatusMap.set(serviceType, ServiceStatus.ERROR);
              return false;
            }
          }
        }
      }

      // 根据服务类型初始化
      let service: ServiceInstance;
      try {
        switch (serviceType) {
          case ServiceType.CACHE:
            service = this.injector.resolve<CacheService>(DI_TOKENS.CACHE_SERVICE);
            await (service as CacheService).initialize();
            break;
          case ServiceType.HTTP:
            service = this.injector.resolve<HttpService>(DI_TOKENS.HTTP_SERVICE);
            await (service as HttpService).initialize();
            break;
          case ServiceType.CONFIG:
            service = this.injector.resolve<ConfigService>(DI_TOKENS.CONFIG_SERVICE);
            await (service as ConfigService).initializeConfig();
            break;
          case ServiceType.HISTORY:
            service = this.injector.resolve<HistoryService>(DI_TOKENS.HISTORY_SERVICE);
            break;
          case ServiceType.MEDIA:
            service = this.injector.resolve<MediaService>(DI_TOKENS.MEDIA_SERVICE);
            await (service as MediaService).initialize();
            break;
          case ServiceType.SITE:
            service = this.injector.resolve<SiteService>(DI_TOKENS.SITE_SERVICE);
            await (service as SiteService).initialize();
            break;
          case ServiceType.PLAYBACK:
            service = this.injector.resolve<PlaybackService>(DI_TOKENS.PLAYBACK_SERVICE);
            break;
          case ServiceType.CONFIG_MANAGER:
            service = ConfigManager.getInstance();
            await (service as ConfigManager).initialize();
            break;
          case ServiceType.HISTORY_MANAGER:
            service = HistoryManager.getInstance();
            await (service as HistoryManager).initialize();
            break;
          default:
            Logger.error(this.TAG, `Unknown service type: ${serviceType}`);
            this.serviceStatusMap.set(serviceType, ServiceStatus.ERROR);
            return false;
        }
      } catch (serviceError) {
        Logger.error(this.TAG, `Failed to create or initialize ${ServiceType[serviceType]}: ${serviceError instanceof Error ? serviceError.message : String(serviceError)}`);
        this.serviceStatusMap.set(serviceType, ServiceStatus.ERROR);
        return false;
      }

      this.instanceMap.set(serviceType, service);
      this.serviceStatusMap.set(serviceType, ServiceStatus.READY);
      Logger.info(this.TAG, `${ServiceType[serviceType]} initialized successfully`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize ${ServiceType[serviceType]}: ${error instanceof Error ? error.message : String(error)}`);
      this.serviceStatusMap.set(serviceType, ServiceStatus.ERROR);
      return false;
    }
  }

  /**
   * 健康检查服务
   * Health check service
   * @param serviceType 服务类型
   * @returns 是否健康
   */
  private async healthCheckService(serviceType: ServiceType): Promise<boolean> {
    try {
      const service = this.getInstance(serviceType);
      if (!service) {
        Logger.warn(this.TAG, `Service ${ServiceType[serviceType]} not found for health check`);
        return false;
      }
      
      // 检查服务状态
      const status = this.serviceStatusMap.get(serviceType);
      if (status !== ServiceStatus.READY) {
        Logger.warn(this.TAG, `Service ${ServiceType[serviceType]} is not ready, status: ${ServiceStatus[status || 0]}`);
        return false;
      }
      
      // 调用服务自身的健康检查方法（如果有的话）
      if (typeof (service as any).healthCheck === 'function') {
        try {
          const result = await (service as any).healthCheck();
          if (result) {
            Logger.debug(this.TAG, `Health check passed for ${ServiceType[serviceType]} (self-check)`);
            return true;
          } else {
            Logger.warn(this.TAG, `Health check failed for ${ServiceType[serviceType]} (self-check)`);
            return false;
          }
        } catch (selfCheckError) {
          Logger.warn(this.TAG, `Self-health check failed for ${ServiceType[serviceType]}: ${selfCheckError instanceof Error ? selfCheckError.message : String(selfCheckError)}`);
          // 继续执行默认健康检查
        }
      }
      
      // 默认健康检查逻辑
      switch (serviceType) {
        case ServiceType.HTTP:
          // 检查HTTP服务是否正常
          const httpService = service as HttpService;
          if (typeof httpService.testConnection === 'function') {
            try {
              const connectionOk = await httpService.testConnection();
              if (connectionOk) {
                Logger.debug(this.TAG, `Health check passed for ${ServiceType[serviceType]} (connection test)`);
                return true;
              } else {
                Logger.warn(this.TAG, `Health check failed for ${ServiceType[serviceType]} (connection test)`);
                return false;
              }
            } catch (connectionError) {
              Logger.warn(this.TAG, `Connection test failed for ${ServiceType[serviceType]}: ${connectionError instanceof Error ? connectionError.message : String(connectionError)}`);
              return false;
            }
          }
          break;
        case ServiceType.CACHE:
          // 检查缓存服务是否正常
          const cacheService = service as CacheService;
          if (typeof cacheService.getCacheSize === 'function') {
            try {
              await cacheService.getCacheSize();
              Logger.debug(this.TAG, `Health check passed for ${ServiceType[serviceType]} (cache size check)`);
              return true;
            } catch (cacheError) {
              Logger.warn(this.TAG, `Cache check failed for ${ServiceType[serviceType]}: ${cacheError instanceof Error ? cacheError.message : String(cacheError)}`);
              return false;
            }
          }
          break;
        case ServiceType.CONFIG:
          // 检查配置服务是否正常
          const configService = service as ConfigService;
          if (typeof configService.getFullConfig === 'function') {
            try {
              await configService.getFullConfig();
              Logger.debug(this.TAG, `Health check passed for ${ServiceType[serviceType]} (config check)`);
              return true;
            } catch (configError) {
              Logger.warn(this.TAG, `Config check failed for ${ServiceType[serviceType]}: ${configError instanceof Error ? configError.message : String(configError)}`);
              return false;
            }
          }
          break;
      }
      
      // 对于其他服务，默认返回健康
      Logger.debug(this.TAG, `Health check passed for ${ServiceType[serviceType]} (default)`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Health check failed for ${ServiceType[serviceType]}: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 初始化所有服务
   * Initialize all services
   * @returns 是否初始化成功
   */
  public async initialize(): Promise<boolean> {
    try {
      if (this.isInitialized) {
        Logger.info(this.TAG, 'Services already initialized');
        return true;
      }

      Logger.info(this.TAG, 'Initializing services...');

      // 1. 检测循环依赖
      Logger.info(this.TAG, 'Checking for circular dependencies...');
      let hasCircularDependency = false;
      Object.values(ServiceType).forEach(type => {
        if (typeof type === 'number') {
          if (this.checkCircularDependency(type, new Set())) {
            hasCircularDependency = true;
          }
        }
      });
      
      if (hasCircularDependency) {
        Logger.error(this.TAG, 'Circular dependencies detected, cannot initialize services');
        return false;
      }
      
      // 2. 拓扑排序服务依赖
      Logger.info(this.TAG, 'Topologically sorting service dependencies...');
      try {
        const sortedServices = this.topologicalSort();
        Logger.info(this.TAG, `Service initialization order: ${sortedServices.map(type => ServiceType[type]).join(', ')}`);
      } catch (sortError) {
        Logger.error(this.TAG, `Failed to sort services: ${sortError instanceof Error ? sortError.message : String(sortError)}`);
        return false;
      }

      // 3. 初始化依赖注入容器
      Logger.info(this.TAG, 'Initializing dependency injector...');
      const injectorInitResult = this.injector.initialize();
      if (!injectorInitResult) {
        Logger.error(this.TAG, 'Failed to initialize dependency injector');
        return false;
      }

      // 4. 初始化RepositoryFactory
      const repoInitResult = await RepositoryFactory.getInstance().initialize();
      if (!repoInitResult) {
        Logger.error(this.TAG, 'Failed to initialize repository factory');
        return false;
      }

      // 2. 按组并行初始化服务
      for (const group of ServiceFactory.INITIALIZATION_GROUPS) {
        Logger.info(this.TAG, `Initializing service group: ${group.map(type => ServiceType[type]).join(', ')}`);
        
        const initializationPromises = group.map(serviceType => 
          this.initializeService(serviceType)
        );
        
        const results = await Promise.all(initializationPromises);
        
        if (results.some(result => !result)) {
          Logger.error(this.TAG, `Failed to initialize services in group`);
          return false;
        }
      }

      // 3. 执行健康检查
      Logger.info(this.TAG, 'Performing health checks...');
      const healthCheckPromises = Array.from(this.instanceMap.keys()).map(serviceType => 
        this.healthCheckService(serviceType)
      );
      
      const healthCheckResults = await Promise.all(healthCheckPromises);
      if (healthCheckResults.some(result => !result)) {
        Logger.warn(this.TAG, 'Some services failed health check');
      }

      this.isInitialized = true;
      Logger.info(this.TAG, 'All services initialized successfully');
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize services: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 获取配置服务实例
   * Get config service instance
   * @returns ConfigService实例
   * @returns ConfigService instance
   */
  public getConfigService(): ConfigService {
    return this.getInstance(ServiceType.CONFIG) as ConfigService;
  }

  /**
   * 获取历史服务实例
   * Get history service instance
   * @returns HistoryService实例
   * @returns HistoryService instance
   */
  public getHistoryService(): HistoryService {
    return this.getInstance(ServiceType.HISTORY) as HistoryService;
  }

  /**
   * 获取站点服务实例
   * Get site service instance
   * @returns SiteService实例
   * @returns SiteService instance
   */
  public getSiteService(): SiteService {
    return this.getInstance(ServiceType.SITE) as SiteService;
  }

  /**
   * 获取配置管理器实例
   * Get config manager instance
   * @returns ConfigManager实例
   * @returns ConfigManager instance
   */
  public getConfigManager(): ConfigManager {
    return this.getInstance(ServiceType.CONFIG_MANAGER) as ConfigManager;
  }

  /**
   * 获取历史管理器实例
   * Get history manager instance
   * @returns HistoryManager实例
   * @returns HistoryManager instance
   */
  public getHistoryManager(): HistoryManager {
    return this.getInstance(ServiceType.HISTORY_MANAGER) as HistoryManager;
  }
  
  /**
   * 获取HTTP服务实例
   * Get HTTP service instance
   * @returns HttpService实例
   * @returns HttpService instance
   */
  public getHttpService(): HttpService {
    return this.getInstance(ServiceType.HTTP) as HttpService;
  }
  
  /**
   * 获取播放服务实例
   * Get playback service instance
   * @returns PlaybackService实例
   * @returns PlaybackService instance
   */
  public getPlaybackService(): PlaybackService {
    return this.getInstance(ServiceType.PLAYBACK) as PlaybackService;
  }
  
  /**
   * 获取媒体服务实例
   * Get media service instance
   * @returns MediaService实例
   * @returns MediaService instance
   */
  public getMediaService(): MediaService {
    return this.getInstance(ServiceType.MEDIA) as MediaService;
  }
  
  /**
   * 获取缓存服务实例
   * Get cache service instance
   * @returns CacheService实例
   * @returns CacheService instance
   */
  public getCacheService(): CacheService {
    return this.getInstance(ServiceType.CACHE) as CacheService;
  }

  /**
   * 获取指定类型的服务实例
   * Get service instance of specified type
   * @param type 服务类型
   * @param type Service type
   * @returns 服务实例
   * @returns Service instance
   */
  private getService<T>(type: ServiceType): T {
    return this.getInstance(type) as T;
  }

  /**
   * 设置自定义服务实例
   * Set custom service instance
   * @param type 服务类型
   * @param type Service type
   * @param service 服务实例
   * @param service Service instance
   */
  public setService(type: ServiceType, service: ServiceInstance): void {
    this.setInstance(type, service);
  }

  /**
   * 检查服务是否初始化
   * Check if service is initialized
   * @param type 服务类型
   * @param type Service type
   * @returns 是否已初始化
   * @returns Whether initialized
   */
  public isServiceInitialized(type: ServiceType): boolean {
    return this.isInstanceInitialized(type);
  }

  /**
   * 获取服务状态
   * Get service status
   * @param type 服务类型
   * @param type Service type
   * @returns 服务状态
   * @returns Service status
   */
  public getServiceStatus(type: ServiceType): ServiceStatus {
    return this.serviceStatusMap.get(type) || ServiceStatus.UNINITIALIZED;
  }

  /**
   * 重启服务
   * Restart service
   * @param type 服务类型
   * @param type Service type
   * @returns 是否重启成功
   * @returns Whether restart is successful
   */
  public async restartService(type: ServiceType): Promise<boolean> {
    try {
      Logger.info(this.TAG, `Restarting service: ${ServiceType[type]}`);
      
      // 销毁服务
      await this.destroyService(type);
      
      // 重新初始化服务
      const result = await this.initializeService(type);
      
      if (result) {
        Logger.info(this.TAG, `Service ${ServiceType[type]} restarted successfully`);
      } else {
        Logger.error(this.TAG, `Failed to restart service ${ServiceType[type]}`);
      }
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `Failed to restart service ${ServiceType[type]}: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 销毁服务
   * Destroy service
   * @param type 服务类型
   * @param type Service type
   * @returns 是否销毁成功
   * @returns Whether destroy is successful
   */
  public async destroyService(type: ServiceType): Promise<boolean> {
    try {
      const service = this.getInstance(type);
      if (!service) {
        Logger.warn(this.TAG, `Service ${ServiceType[type]} not found for destruction`);
        this.serviceStatusMap.set(type, ServiceStatus.DESTROYED);
        return true;
      }
      
      // 调用服务的销毁方法（如果有的话）
      if (typeof (service as any).destroy === 'function') {
        try {
          await (service as any).destroy();
          Logger.info(this.TAG, `Service ${ServiceType[type]} destroyed successfully`);
        } catch (destroyError) {
          Logger.warn(this.TAG, `Failed to destroy service ${ServiceType[type]}: ${destroyError instanceof Error ? destroyError.message : String(destroyError)}`);
        }
      }
      
      // 从实例映射中移除服务
      this.instanceMap.delete(type);
      this.serviceStatusMap.set(type, ServiceStatus.DESTROYED);
      
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to destroy service ${ServiceType[type]}: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 获取所有服务的状态
   * Get status of all services
   * @returns 服务状态映射
   * @returns Service status map
   */
  public getAllServiceStatus(): Map<ServiceType, ServiceStatus> {
    return new Map(this.serviceStatusMap);
  }

  /**
   * 关闭所有服务资源
   * Close all service resources
   */
  public async close(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Closing services...');

      // 调用父类的close方法关闭服务实例
      // Call parent class close method to close service instances
      await super.close();
      
      // 关闭数据库资源
      // Close database resources
      await RepositoryFactory.getInstance().close();
      
      Logger.info(this.TAG, 'All services closed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to close services: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}
