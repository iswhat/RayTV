// 服务注册文件 | Service registration file
// 将所有服务注册到依赖注入容器中 | Register all services to the dependency injection container
import { DIContainer } from './Container';
import { ConfigService } from '../../service/config/ConfigService';
import { HttpService } from '../../service/HttpService';
import { StorageUtil } from '../util/StorageUtil';
import { CrawlerService } from '../../service/spider/CrawlerService';
import { MediaService } from '../../service/media/MediaService';
import { SiteDao } from '../../data/db/dao/SiteDao';

/**
 * 注册所有服务 | Register all services
 */
export function registerServices(): void {
  const container = DIContainer.getInstance();
  
  // 注册工具类 | Register utility classes
  container.register('StorageUtil', () => StorageUtil, true);
  
  // 注册DAO类 | Register DAO classes
  container.register('SiteDao', () => new SiteDao(), true);
  
  // 注册服务类 | Register service classes
  container.register('ConfigService', () => new ConfigService(), true);
  container.register('HttpService', () => new HttpService(), true);
  container.register('CrawlerService', () => new CrawlerService(), true);
  container.register('MediaService', () => new MediaService(), true);
  
  console.info('All services registered successfully');
}

/**
 * 初始化依赖注入容器 | Initialize dependency injection container
 */
export function initializeDI(): void {
  registerServices();
  console.info('Dependency injection container initialized successfully');
}