/**
 * ServiceInitManager - Service initialization manager | 服务初始化管理器
 * Manages the initialization order and dependencies of application services | 管理应用服务的初始化顺序和依赖关系
 */

import Logger from '../util/Logger';
import { DIContainer } from '../di/Container';
import { handleError } from '../util/ErrorHandler';
import { FlowData, RestoreFlowParams } from '../../service/device/DeviceFlowManager';

const TAG: string = 'ServiceInitManager';

/**
 * Service initialization manager class | 服务初始化管理器类
 */
export class ServiceInitManager {
  private static instance: ServiceInitManager | null = null;
  private container: DIContainer;
  private initializedServices: Set<string> = new Set();
  private initializationPromises: Map<string, Promise<void>> = new Map();

  /**
   * Get service initialization manager instance | 获取服务初始化管理器实例
   * @returns ServiceInitManager instance | ServiceInitManager实例
   */
  public static getInstance(): ServiceInitManager {
    if (!ServiceInitManager.instance) {
      ServiceInitManager.instance = new ServiceInitManager();
    }
    return ServiceInitManager.instance;
  }

  /**
   * Constructor | 构造函数
   */
  private constructor() {
    this.container = DIContainer.getInstance();
  }

  /**
   * Initialize all services | 初始化所有服务
   * @param want Want object | Want对象
   * @param context Ability context | Ability上下文
   */
  public async initializeServices(want: any, context: any): Promise<void> {
    Logger.info(TAG, 'Starting service initialization');

    try {
      // 优化：并行初始化无依赖的服务，提高启动速度
      
      // 1. 基础服务（无依赖）- 并行初始化
      const baseServices = [
        this.initializeConfigService(),
        this.initializeHttpService()
      ];
      await Promise.all(baseServices);
      
      // 2. 数据服务（依赖基础服务）- 并行初始化
      const dataServices = [
        this.initializeStorageUtil(),
        this.initializeSiteDao(),
        this.initializeMediaService(),
        this.initializeCrawlerService()
      ];
      await Promise.all(dataServices);
      
      // 3. 功能服务（依赖数据服务）- 并行初始化
      const featureServices = [
        this.initializeVoiceAssistantManager(),
        this.initializeGestureService(),
        this.initializeDataSyncService(context),
        this.initializeDeviceFlowManager(want)
      ];
      await Promise.all(featureServices);

      Logger.info(TAG, 'All services initialized successfully');
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_SERVICES');
      Logger.error(TAG, `Service initialization failed: ${errorInfo.message}`);
      // 即使部分服务初始化失败，应用仍继续运行
    }
  }
  
  /**
   * Initialize service with caching | 带缓存的服务初始化
   * @param serviceName Service name | 服务名称
   * @param initializer Initialization function | 初始化函数
   */
  private async initializeServiceWithCache(serviceName: string, initializer: () => Promise<void>): Promise<void> {
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }
    
    // 检查是否已有初始化 promise
    if (this.initializationPromises.has(serviceName)) {
      await this.initializationPromises.get(serviceName);
      return;
    }
    
    // 创建初始化 promise 并缓存
    const initPromise = initializer();
    this.initializationPromises.set(serviceName, initPromise);
    
    try {
      await initPromise;
      this.initializedServices.add(serviceName);
      Logger.info(TAG, `${serviceName} initialized successfully`);
    } catch (error) {
      const errorInfo = handleError(error, `INITIALIZE_${serviceName.toUpperCase()}`);
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    } finally {
      this.initializationPromises.delete(serviceName);
    }
  }

  /**
   * Initialize ConfigService | 初始化ConfigService
   */
  private async initializeConfigService(): Promise<void> {
    const serviceName = 'ConfigService';
    await this.initializeServiceWithCache(serviceName, async () => {
      const configService = this.container.resolve(serviceName);
      if (configService && typeof configService.initialize === 'function') {
        await configService.initialize();
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // ConfigService 是核心服务，尝试创建实例
      }
    });
  }

  /**
   * Initialize HttpService | 初始化HttpService
   */
  private async initializeHttpService(): Promise<void> {
    const serviceName = 'HttpService';
    await this.initializeServiceWithCache(serviceName, async () => {
      const httpService = this.container.resolve(serviceName);
      if (httpService && typeof httpService.initialize === 'function') {
        await httpService.initialize();
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // HttpService 是核心服务，尝试创建实例
      }
    });
  }

  /**
   * Initialize StorageUtil | 初始化StorageUtil
   */
  private async initializeStorageUtil(): Promise<void> {
    const serviceName = 'StorageUtil';
    await this.initializeServiceWithCache(serviceName, async () => {
      const storageUtil = this.container.resolve(serviceName);
      if (storageUtil && typeof storageUtil.initialize === 'function') {
        await storageUtil.initialize();
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // StorageUtil 是工具类，尝试创建实例
      }
    });
  }

  /**
   * Initialize SiteDao | 初始化SiteDao
   */
  private async initializeSiteDao(): Promise<void> {
    const serviceName = 'SiteDao';
    await this.initializeServiceWithCache(serviceName, async () => {
      const siteDao = this.container.resolve(serviceName);
      if (siteDao && typeof siteDao.initialize === 'function') {
        await siteDao.initialize();
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // SiteDao 是DAO类，尝试创建实例
      }
    });
  }

  /**
   * Initialize MediaService | 初始化MediaService
   */
  private async initializeMediaService(): Promise<void> {
    const serviceName = 'MediaService';
    await this.initializeServiceWithCache(serviceName, async () => {
      const mediaService = this.container.resolve(serviceName);
      if (mediaService && typeof mediaService.initialize === 'function') {
        await mediaService.initialize();
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // MediaService 是核心服务，尝试创建实例
      }
    });
  }

  /**
   * Initialize CrawlerService | 初始化CrawlerService
   */
  private async initializeCrawlerService(): Promise<void> {
    const serviceName = 'CrawlerService';
    await this.initializeServiceWithCache(serviceName, async () => {
      const crawlerService = this.container.resolve(serviceName);
      if (crawlerService && typeof crawlerService.initialize === 'function') {
        await crawlerService.initialize();
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // CrawlerService 是核心服务，尝试创建实例
      }
    });
  }

  /**
   * Initialize VoiceAssistantManager | 初始化VoiceAssistantManager
   */
  private async initializeVoiceAssistantManager(): Promise<void> {
    const serviceName = 'VoiceAssistantManager';
    await this.initializeServiceWithCache(serviceName, async () => {
      const voiceAssistantManager = this.container.resolve(serviceName);
      if (voiceAssistantManager && typeof voiceAssistantManager.initialize === 'function') {
        await voiceAssistantManager.initialize();
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
      }
    });
  }

  /**
   * Initialize GestureService | 初始化GestureService
   */
  private async initializeGestureService(): Promise<void> {
    const serviceName = 'GestureService';
    await this.initializeServiceWithCache(serviceName, async () => {
      const gestureService = this.container.resolve(serviceName);
      void gestureService;
      // GestureService 是静态实例，不需要初始化
    });
  }

  /**
   * Initialize DataSyncService | 初始化DataSyncService
   * @param context Ability context | Ability上下文
   */
  private async initializeDataSyncService(context: any): Promise<void> {
    const serviceName = 'DataSyncService';
    await this.initializeServiceWithCache(serviceName, async () => {
      const dataSyncService = this.container.resolve(serviceName);
      if (dataSyncService && typeof dataSyncService.initialize === 'function') {
        await dataSyncService.initialize(context);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
      }
    });
  }

  /**
   * Initialize DeviceFlowManager | 初始化DeviceFlowManager
   * @param want Want object | Want对象
   */
  private async initializeDeviceFlowManager(want: any): Promise<void> {
    const serviceName = 'DeviceFlowManager';
    await this.initializeServiceWithCache(serviceName, async () => {
      const deviceFlowManager = this.container.resolve(serviceName);
      if (deviceFlowManager && typeof deviceFlowManager.initialize === 'function') {
        await deviceFlowManager.initialize();

        // 处理跨设备迁移参数（如果有）
        if (want?.parameters) {
          Logger.info(TAG, 'Received cross-device migration params');
          const flowParams = want.parameters['flowParams'] as FlowData;
          if (flowParams && typeof deviceFlowManager.restoreFromFlowParams === 'function') {
            const restoreParams: RestoreFlowParams = {
              data: flowParams
            };
            await deviceFlowManager.restoreFromFlowParams(restoreParams);
          }
        }
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
      }
    });
  }

  /**
   * Check if a service is initialized | 检查服务是否已初始化
   * @param serviceName Service name | 服务名称
   * @returns Whether the service is initialized | 服务是否已初始化
   */
  public isServiceInitialized(serviceName: string): boolean {
    return this.initializedServices.has(serviceName);
  }

  /**
   * Get initialized services | 获取已初始化的服务
   * @returns Set of initialized service names | 已初始化的服务名称集合
   */
  public getInitializedServices(): Set<string> {
    return new Set(this.initializedServices);
  }

  /**
   * Reset initialization state | 重置初始化状态
   */
  public reset(): void {
    this.initializedServices.clear();
    this.initializationPromises.clear();
    Logger.info(TAG, 'Service initialization state reset');
  }
}

// 导出单例实例 | Export singleton instance
export default ServiceInitManager.getInstance();
