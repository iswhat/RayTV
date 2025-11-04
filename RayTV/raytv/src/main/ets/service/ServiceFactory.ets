import Logger from '../../../common/util/Logger';
import RepositoryFactory from '../repository/RepositoryFactory';
import ConfigService from '../../service/config/ConfigService';
import HistoryService from '../../service/media/HistoryService';
import { SiteService } from './spider/SiteService';
import { ConfigManager } from './ConfigManager';
import { HistoryManager } from './HistoryManager';

const TAG = 'ServiceFactory';

/**
 * 服务类型枚举
 */
export enum ServiceType {
  CONFIG,
  HISTORY,
  SITE,
  CONFIG_MANAGER,
  HISTORY_MANAGER
}

/**
 * 服务工厂类
 * 负责创建和管理各种服务的实例
 */
export default class ServiceFactory {
  private static instance: ServiceFactory | null = null;
  private serviceMap: Map<ServiceType, any> = new Map();
  private isInitialized: boolean = false;

  /**
   * 私有构造函数
   */
  private constructor() {}

  /**
   * 获取单例实例
   * @returns ServiceFactory实例
   */
  public static getInstance(): ServiceFactory {
    if (!ServiceFactory.instance) {
      ServiceFactory.instance = new ServiceFactory();
    }
    return ServiceFactory.instance;
  }

  /**
   * 初始化所有服务
   * @returns 是否初始化成功
   */
  public async initialize(): Promise<boolean> {
    try {
      if (this.isInitialized) {
        Logger.info(TAG, 'Services already initialized');
        return true;
      }

      Logger.info(TAG, 'Initializing services...');

      const repoInitResult = await RepositoryFactory.getInstance().initialize();

      if (!repoInitResult) {
        Logger.error(TAG, 'Failed to initialize repository factory');
        return false;
      }

      // 初始化配置服务
      const configService = ConfigService.getInstance();
      await configService.initializeConfig();
      this.serviceMap.set(ServiceType.CONFIG, configService);
      Logger.info(TAG, 'ConfigService initialized successfully');

      // 初始化历史服务
      const historyService = HistoryService.getInstance();
      this.serviceMap.set(ServiceType.HISTORY, historyService);
      Logger.info(TAG, 'HistoryService initialized successfully');

      // 初始化站点服务
      const siteService = SiteService.getInstance();
      await siteService.initialize();
      this.serviceMap.set(ServiceType.SITE, siteService);
      Logger.info(TAG, 'SiteService initialized successfully');

      // 初始化配置管理器（适配器）
      const configManager = ConfigManager.getInstance();
      await configManager.initialize();
      this.serviceMap.set(ServiceType.CONFIG_MANAGER, configManager);
      Logger.info(TAG, 'ConfigManager initialized successfully');

      // 初始化历史管理器（适配器）
      const historyManager = HistoryManager.getInstance();
      await historyManager.initialize();
      this.serviceMap.set(ServiceType.HISTORY_MANAGER, historyManager);
      Logger.info(TAG, 'HistoryManager initialized successfully');

      this.isInitialized = true;
      Logger.info(TAG, 'All services initialized successfully');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to initialize services: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 获取配置服务实例
   * @returns ConfigService实例
   */
  public getConfigService(): ConfigService {
    return this.getService(ServiceType.CONFIG);
  }

  /**
   * 获取历史服务实例
   * @returns HistoryService实例
   */
  public getHistoryService(): HistoryService {
    return this.getService(ServiceType.HISTORY);
  }

  /**
   * 获取站点服务实例
   * @returns SiteService实例
   */
  public getSiteService(): SiteService {
    return this.getService(ServiceType.SITE);
  }

  /**
   * 获取配置管理器实例
   * @returns ConfigManager实例
   */
  public getConfigManager(): ConfigManager {
    return this.getService(ServiceType.CONFIG_MANAGER);
  }

  /**
   * 获取历史管理器实例
   * @returns HistoryManager实例
   */
  public getHistoryManager(): HistoryManager {
    return this.getService(ServiceType.HISTORY_MANAGER);
  }

  /**
   * 获取指定类型的服务实例
   * @param type 服务类型
   * @returns 服务实例
   */
  private getService<T>(type: ServiceType): T {
    const service = this.serviceMap.get(type);
    if (!service) {
      throw new Error(`Service of type ${type} not initialized. Call initialize() first.`);
    }
    return service as T;
  }

  /**
   * 设置自定义服务实例
   * @param type 服务类型
   * @param service 服务实例
   */
  public setService(type: ServiceType, service: any): void {
    this.serviceMap.set(type, service);
    Logger.info(TAG, `Custom service set for type: ${type}`);
  }

  /**
   * 检查服务是否初始化
   * @param type 服务类型
   * @returns 是否初始化
   */
  public isServiceInitialized(type: ServiceType): boolean {
    return this.serviceMap.has(type);
  }

  /**
   * 关闭所有服务资源
   */
  public async close(): Promise<void> {
    try {
      Logger.info(TAG, 'Closing services...');

      // 清理服务映射
      this.serviceMap.clear();
      this.isInitialized = false;
      
      // 关闭仓库资源
      await RepositoryFactory.getInstance().close();
      
      Logger.info(TAG, 'All services closed successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to close services: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 重置工厂（主要用于测试）
   */
  public static reset(): void {
    if (ServiceFactory.instance) {
      ServiceFactory.instance.close().catch(error => {
        Logger.error(TAG, `Error during factory reset: ${error instanceof Error ? error.message : String(error)}`);
      });
      ServiceFactory.instance = null;
    }
    Logger.info(TAG, 'Service factory reset');
  }
}