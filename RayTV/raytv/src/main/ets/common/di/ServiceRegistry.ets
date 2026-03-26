// 服务注册文件 | Service registration file
// 将所有服务注册到依赖注入容器中 | Register all services to the dependency injection container
import { DIContainer } from './Container';
import Logger from '../util/Logger';
import ConfigService from '../../service/config/ConfigService';
import { HttpService } from '../../service/HttpService';
import { StorageUtil } from '../util/StorageUtil';
import { CrawlerService } from '../../service/spider/CrawlerService';
import MediaService from '../../service/media/MediaService';
import { SiteDao } from '../../data/db/dao/SiteDao';
import { VoiceAssistantManager } from '../../service/voice/VoiceAssistantManager';
import { GestureServiceInstance } from '../../service/input/GestureService';
import DataSyncService from '../../service/sync/DataSyncService';
import { DeviceFlowManager } from '../../service/device/DeviceFlowManager';

const TAG: string = 'ServiceRegistry';

/**
 * 注册所有服务 | Register all services
 */
export function registerServices(): void {
  const container = DIContainer.getInstance();

  // 注册工具类 | Register utility classes
  container.register('StorageUtil', () => StorageUtil, true);

  // 注册 DAO 类 | Register DAO classes
  container.register('SiteDao', (): SiteDao => new SiteDao(), true);

  // 注册服务类 | Register service classes
  container.register('ConfigService', (): ConfigService => ConfigService.getInstance(), true);
  container.register('HttpService', (): HttpService => HttpService.getInstance(), true);
  container.register('CrawlerService', (): CrawlerService => CrawlerService.getInstance(), true);
  container.register('MediaService', (): MediaService => MediaService.getInstance(), true);
  container.register('VoiceAssistantManager', (): VoiceAssistantManager => VoiceAssistantManager.getInstance(), true);
  container.register('GestureService', (): any => GestureServiceInstance, true);
  container.register('DataSyncService', (): DataSyncService => DataSyncService.getInstance(), true);
  container.register('DeviceFlowManager', (): DeviceFlowManager => DeviceFlowManager.getInstance(), true);

  Logger.info(TAG, 'All services registered successfully');
}

/**
 * 初始化依赖注入容器 | Initialize dependency injection container
 */
export function initializeDI(): void {
  registerServices();
  Logger.info(TAG, 'Dependency injection container initialized successfully');
}