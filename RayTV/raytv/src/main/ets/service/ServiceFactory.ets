import Logger from '../../../common/util/Logger';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import ConfigService from '../../service/config/ConfigService';
import HistoryService from '../../service/media/HistoryService';
import { SiteService } from './spider/SiteService';
import { ConfigManager } from './ConfigManager';
import { HistoryManager } from './HistoryManager';
import { FactoryBase } from '../../../common/base/FactoryBase';

/**
 * 服务类型定义
 * Service type definition
 */
export enum ServiceType {
  CONFIG,
  HISTORY,
  SITE,
  CONFIG_MANAGER,
  HISTORY_MANAGER
}

/**
 * 服务实例类型联合
 * Service instance type union
 */
export type ServiceInstance = ConfigService | HistoryService | SiteService | ConfigManager | HistoryManager;

/**
 * 服务工厂类
 * 负责创建和管理各种服务的实例
 * Service factory class
 * Responsible for creating and managing instances of various services
 */
export default class ServiceFactory extends FactoryBase<ServiceType, ServiceInstance> {
  protected readonly TAG: string = 'ServiceFactory';

  /**
   * 私有构造函数
   * Private constructor
   */
  private constructor() {
    super();
  }

  /**
   * 初始化所有服务
   * 初始化所有服务
   * @returns 是否初始化成功
   * @returns Whether initialization is successful
   */
  public async initialize(): Promise<boolean> {
    try {
      if (this.isInitialized) {
        Logger.info(this.TAG, 'Services already initialized');
        return true;
      }

      Logger.info(this.TAG, 'Initializing services...');

      const repoInitResult = await RepositoryFactory.getInstance().initialize();

      if (!repoInitResult) {
        Logger.error(this.TAG, 'Failed to initialize repository factory');
        return false;
      }

      // 初始化配置服务
      // Initialize config service
      const configService = ConfigService.getInstance();
      await configService.initializeConfig();
      this.instanceMap.set(ServiceType.CONFIG, configService);
      Logger.info(this.TAG, 'ConfigService initialized successfully');

      // 初始化历史服务
      // Initialize history service
      const historyService = HistoryService.getInstance();
      this.instanceMap.set(ServiceType.HISTORY, historyService);
      Logger.info(this.TAG, 'HistoryService initialized successfully');

      // 初始化站点服务
      // Initialize site service
      const siteService = SiteService.getInstance();
      await siteService.initialize();
      this.instanceMap.set(ServiceType.SITE, siteService);
      Logger.info(this.TAG, 'SiteService initialized successfully');

      // 初始化配置管理器（依赖项）
      // Initialize config manager (dependency)
      const configManager = ConfigManager.getInstance();
      await configManager.initialize();
      this.instanceMap.set(ServiceType.CONFIG_MANAGER, configManager);
      Logger.info(this.TAG, 'ConfigManager initialized successfully');

      // 初始化历史管理器（依赖项）
      // Initialize history manager (dependency)
      const historyManager = HistoryManager.getInstance();
      await historyManager.initialize();
      this.instanceMap.set(ServiceType.HISTORY_MANAGER, historyManager);
      Logger.info(this.TAG, 'HistoryManager initialized successfully');

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
