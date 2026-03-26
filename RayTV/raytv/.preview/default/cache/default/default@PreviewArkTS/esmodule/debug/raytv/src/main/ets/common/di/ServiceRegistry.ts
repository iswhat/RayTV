import { DIContainer } from "@bundle:com.raytv.app/raytv/ets/common/di/Container";
import Logger from "@bundle:com.raytv.app/raytv/ets/common/util/Logger";
import ConfigService from "@bundle:com.raytv.app/raytv/ets/service/config/ConfigService";
import { HttpService } from "@bundle:com.raytv.app/raytv/ets/service/HttpService";
import { StorageUtil } from "@bundle:com.raytv.app/raytv/ets/common/util/StorageUtil";
import { CrawlerService } from "@bundle:com.raytv.app/raytv/ets/service/spider/CrawlerService";
import MediaService from "@bundle:com.raytv.app/raytv/ets/service/media/MediaService";
import { SiteDao } from "@bundle:com.raytv.app/raytv/ets/data/db/dao/SiteDao";
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
    Logger.info(TAG, 'All services registered successfully');
}
/**
 * 初始化依赖注入容器 | Initialize dependency injection container
 */
export function initializeDI(): void {
    registerServices();
    Logger.info(TAG, 'Dependency injection container initialized successfully');
}
