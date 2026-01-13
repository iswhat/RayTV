// ServiceUsageExample.ets - 服务使用示例  Service usage example
import Logger from '../common/util/Logger';
import ServiceFactory from '../service/ServiceFactory';
import { Site, SiteType, LoaderType } from '../data/bean/Site';

const TAG = 'ServiceUsageExample';

/**
 * 服务使用示例  Service usage example
 * 展示如何使用ServiceFactory和各种服务  Show how to use ServiceFactory and various services
 */
export class ServiceUsageExample {
  /**
   * 初始化所有服务  Initialize all services
   */
  public static async initializeServices(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing all services...');
      const result = await ServiceFactory.getInstance().initialize();
      if (result) {
        Logger.info(TAG, 'Services initialized successfully');
      } else {
        Logger.error(TAG, 'Failed to initialize services');
      }
    } catch (error) {
      Logger.error(TAG, `Error initializing services: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用配置服务的示例  Example of using config service
   */
  public static async configServiceExample(): Promise<void> {
    try {
      const configService = ServiceFactory.getInstance().getConfigService();
      
      // 获取配置  Get config
      const theme = await configService.getConfig('theme');
      Logger.info(TAG, `Current theme: ${theme}`);
      
      // 设置配置  Set config
      await configService.setConfig('theme', 'dark');
      Logger.info(TAG, 'Theme set to dark');
      
    } catch (error) {
      Logger.error(TAG, `Config service example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用配置管理器的示例  Example of using config manager
   */
  public static async configManagerExample(): Promise<void> {
    try {
      const configManager = ServiceFactory.getInstance().getConfigManager();
      
      // 获取完整配置  Get complete config
      const appConfig = await configManager.getAppConfig();
      Logger.info(TAG, `App config loaded, theme: ${appConfig.theme}`);
      
      // 更新播放器配置  Update player config
      await configManager.updatePlayerConfig({
        autoPlay: true,
        defaultQuality: 'high'
      });
      Logger.info(TAG, 'Player config updated');
      
    } catch (error) {
      Logger.error(TAG, `Config manager example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用历史服务的示例  Example of using history service
   */
  public static async historyServiceExample(): Promise<void> {
    try {
      const historyService = ServiceFactory.getInstance().getHistoryService();
      
      // 获取历史记录列表  Get history list
      const historyList = await historyService.getHistoryList(1, 20);
      Logger.info(TAG, `History list count: ${historyList.length}`);
      
    } catch (error) {
      Logger.error(TAG, `History service example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用历史管理器的示例  Example of using history manager
   */
  public static async historyManagerExample(): Promise<void> {
    try {
      const historyManager = ServiceFactory.getInstance().getHistoryManager();
      
      // 获取观看统计  Get watch statistics
      const stats = await historyManager.getWatchStatistics();
      Logger.info(TAG, `Total watched items: ${stats.totalItems}`);
      
    } catch (error) {
      Logger.error(TAG, `History manager example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用站点服务的示例  Example of using site service
   */
  public static async siteServiceExample(): Promise<void> {
    try {
      const siteService = ServiceFactory.getInstance().getSiteService();
      
      // 获取启用的站点  Get enabled sites
      const enabledSites = await siteService.getEnabledSites();
      Logger.info(TAG, `Enabled sites count: ${enabledSites.length}`);
      
      // 创建示例站点（仅用于展示）  Create example site (for demonstration only)
      const exampleSite: Site = {
        key: 'example-site-' + Date.now(),
        name: 'Example Site',
        type: SiteType.VOD,
        loaderType: LoaderType.JS,
        api: 'https://example.com/api',
        searchConfig: { enabled: true },
        filterConfig: { enabled: false },
        performanceConfig: { timeout: 30000 },
        stats: { queryCount: 0, errorCount: 0, avgResponseTime: 0 },
        lifecycle: { initialized: false, loading: false, error: false },
        enabled: true,
        order: 999,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      
      // 保存站点  Save site
      await siteService.saveSite(exampleSite);
      Logger.info(TAG, `Example site saved: ${exampleSite.key}`);
      
    } catch (error) {
      Logger.error(TAG, `Site service example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 导出/导入示例  Export/Import example
   */
  public static async exportImportExample(): Promise<void> {
    try {
      const siteService = ServiceFactory.getInstance().getSiteService();
      
      // 导出站点配置  Export site config
      const exportData = await siteService.exportSites({
        includeCredentials: false,
        includeStats: true,
        description: 'Example export'
      });
      Logger.info(TAG, `Export data length: ${exportData.length} characters`);
      
      // 注意：实际导入会覆盖现有站点，这里只是展示代码结构  Note: Actual import will overwrite existing sites, this is just code structure demonstration
      // const importResult = await siteService.importSites(exportData);
      // Logger.info(TAG, `Import result: ${JSON.stringify(importResult)}`);
      
    } catch (error) {
      Logger.error(TAG, `Export/Import example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 执行所有示例  Run all examples
   */
  public static async runAllExamples(): Promise<void> {
    Logger.info(TAG, 'Running all service examples...');
    
    await this.initializeServices();
    await this.configServiceExample();
    await this.configManagerExample();
    await this.historyServiceExample();
    await this.historyManagerExample();
    await this.siteServiceExample();
    await this.exportImportExample();
    
    Logger.info(TAG, 'All examples completed');
  }
}

// 示例使用方法  Example usage
// ServiceUsageExample.runAllExamples().catch(err => {
//   Logger.error(TAG, `Failed to run examples: ${err}`);
// });
