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
      // 按顺序初始化服务，确保依赖关系正确
      // 1. 基础服务（无依赖）
      await this.initializeConfigService();
      await this.initializeHttpService();
      
      // 2. 数据服务（依赖基础服务）
      await this.initializeStorageUtil();
      await this.initializeSiteDao();
      await this.initializeMediaService();
      await this.initializeCrawlerService();
      
      // 3. 功能服务（依赖数据服务）
      await this.initializeVoiceAssistantManager();
      await this.initializeGestureService();
      await this.initializeDataSyncService(context);
      await this.initializeDeviceFlowManager(want);

      Logger.info(TAG, 'All services initialized successfully');
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_SERVICES');
      Logger.error(TAG, `Service initialization failed: ${errorInfo.message}`);
      // 即使部分服务初始化失败，应用仍继续运行
    }
  }

  /**
   * Initialize ConfigService | 初始化ConfigService
   */
  private async initializeConfigService(): Promise<void> {
    const serviceName = 'ConfigService';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const configService = this.container.resolve(serviceName);
      if (configService && typeof configService.initialize === 'function') {
        await configService.initialize();
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // ConfigService 是核心服务，尝试创建实例
        this.initializedServices.add(serviceName);
      }
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_CONFIG');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize HttpService | 初始化HttpService
   */
  private async initializeHttpService(): Promise<void> {
    const serviceName = 'HttpService';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const httpService = this.container.resolve(serviceName);
      if (httpService && typeof httpService.initialize === 'function') {
        await httpService.initialize();
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // HttpService 是核心服务，尝试创建实例
        this.initializedServices.add(serviceName);
      }
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_HTTP');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize StorageUtil | 初始化StorageUtil
   */
  private async initializeStorageUtil(): Promise<void> {
    const serviceName = 'StorageUtil';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const storageUtil = this.container.resolve(serviceName);
      if (storageUtil && typeof storageUtil.initialize === 'function') {
        await storageUtil.initialize();
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // StorageUtil 是工具类，尝试创建实例
        this.initializedServices.add(serviceName);
      }
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_STORAGE');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize SiteDao | 初始化SiteDao
   */
  private async initializeSiteDao(): Promise<void> {
    const serviceName = 'SiteDao';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const siteDao = this.container.resolve(serviceName);
      if (siteDao && typeof siteDao.initialize === 'function') {
        await siteDao.initialize();
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // SiteDao 是DAO类，尝试创建实例
        this.initializedServices.add(serviceName);
      }
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_SITE_DAO');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize MediaService | 初始化MediaService
   */
  private async initializeMediaService(): Promise<void> {
    const serviceName = 'MediaService';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const mediaService = this.container.resolve(serviceName);
      if (mediaService && typeof mediaService.initialize === 'function') {
        await mediaService.initialize();
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // MediaService 是核心服务，尝试创建实例
        this.initializedServices.add(serviceName);
      }
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_MEDIA');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize CrawlerService | 初始化CrawlerService
   */
  private async initializeCrawlerService(): Promise<void> {
    const serviceName = 'CrawlerService';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const crawlerService = this.container.resolve(serviceName);
      if (crawlerService && typeof crawlerService.initialize === 'function') {
        await crawlerService.initialize();
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
        // CrawlerService 是核心服务，尝试创建实例
        this.initializedServices.add(serviceName);
      }
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_CRAWLER');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize VoiceAssistantManager | 初始化VoiceAssistantManager
   */
  private async initializeVoiceAssistantManager(): Promise<void> {
    const serviceName = 'VoiceAssistantManager';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const voiceAssistantManager = this.container.resolve(serviceName);
      if (voiceAssistantManager && typeof voiceAssistantManager.initialize === 'function') {
        await voiceAssistantManager.initialize();
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
      }
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_VOICE_ASSISTANT');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize GestureService | 初始化GestureService
   */
  private async initializeGestureService(): Promise<void> {
    const serviceName = 'GestureService';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const gestureService = this.container.resolve(serviceName);
      void gestureService;
      this.initializedServices.add(serviceName);
      Logger.info(TAG, `${serviceName} already initialized`);
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_GESTURE_SERVICE');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize DataSyncService | 初始化DataSyncService
   * @param context Ability context | Ability上下文
   */
  private async initializeDataSyncService(context: any): Promise<void> {
    const serviceName = 'DataSyncService';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const dataSyncService = this.container.resolve(serviceName);
      if (dataSyncService && typeof dataSyncService.initialize === 'function') {
        await dataSyncService.initialize(context);
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);
      } else {
        Logger.warn(TAG, `${serviceName} not found or missing initialize method`);
      }
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_DATA_SYNC');
      Logger.warn(TAG, `${serviceName} initialization failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
  }

  /**
   * Initialize DeviceFlowManager | 初始化DeviceFlowManager
   * @param want Want object | Want对象
   */
  private async initializeDeviceFlowManager(want: any): Promise<void> {
    const serviceName = 'DeviceFlowManager';
    if (this.initializedServices.has(serviceName)) {
      Logger.info(TAG, `${serviceName} already initialized`);
      return;
    }

    try {
      const deviceFlowManager = this.container.resolve(serviceName);
      if (deviceFlowManager && typeof deviceFlowManager.initialize === 'function') {
        await deviceFlowManager.initialize();
        this.initializedServices.add(serviceName);
        Logger.info(TAG, `${serviceName} initialized successfully`);

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
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_DEVICE_FLOW');
      Logger.warn(TAG, `${serviceName} initialization or migration failed (degraded mode): ${errorInfo.message}`);
      // 服务初始化失败时记录错误但不崩溃，应用可降级运行
    }
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
