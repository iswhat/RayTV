// ServiceUsageExample.ets - 服务使用示例
import Logger from '../common/util/Logger';
import ServiceFactory from '../service/ServiceFactory';
import { Site, SiteType, LoaderType } from '../data/bean/Site';

const TAG = 'ServiceUsageExample';

/**
 * 服务使用示例�? * 展示如何使用ServiceFactory和各种服�? */
export class ServiceUsageExample {
  /**
   * 初始化所有服�?   */
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
      Logger.error(TAG, `Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error instanceof Error ? `Error initializing services: ${error instanceof Error ? error.message : String(error : new Error(String(`Error initializing services: ${error instanceof Error ? error.message : String(error)))))))}`);
    }
  }
  
  /**
   * 使用配置服务的示�?   */
  public static async configServiceExample(): Promise<void> {
    try {
      const configService = ServiceFactory.getInstance().getConfigService();
      
      // 获取配置
      const theme = await configService.getConfig('theme');
      Logger.info(TAG, `Current theme: ${theme}`);
      
      // 设置配置
      await configService.setConfig('theme', 'dark');
      Logger.info(TAG, 'Theme set to dark');
      
    } catch (error) {
      Logger.error(TAG, `Config service example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用配置管理器的示例
   */
  public static async configManagerExample(): Promise<void> {
    try {
      const configManager = ServiceFactory.getInstance().getConfigManager();
      
      // 获取完整配置
      const appConfig = await configManager.getAppConfig();
      Logger.info(TAG, `App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}` instanceof Error ? `App config loaded, theme: ${appConfig.theme}` : new Error(String(`App config loaded, theme: ${appConfig.theme}`)))))));
      
      // 更新播放器配�?      await configManager.updatePlayerConfig({
        autoPlay: true,
        defaultQuality: 'high'
      });
      Logger.info(TAG, 'Player config updated');
      
    } catch (error) {
      Logger.error(TAG, `Config manager example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用历史服务的示�?   */
  public static async historyServiceExample(): Promise<void> {
    try {
      const historyService = ServiceFactory.getInstance().getHistoryService();
      
      // 获取历史记录列表
      const historyList = await historyService.getHistoryList(1, 20 instanceof Error ? 20 : new Error(String(20 instanceof Error ? 20 instanceof Error ? 20 : new Error(String(20 : new Error(String(20 instanceof Error ? 20 : new Error(String(20 instanceof Error ? 20 instanceof Error ? 20 : new Error(String(20 instanceof Error ? 20 instanceof Error ? 20 : new Error(String(20 : new Error(String(20 instanceof Error ? 20 : new Error(String(20 : new Error(String(20 instanceof Error ? 20 : new Error(String(20 instanceof Error ? 20 instanceof Error ? 20 : new Error(String(20 : new Error(String(20 instanceof Error ? 20 : new Error(String(20)))))));
      Logger.info(TAG, `History list count: ${historyList.length}`);
      
    } catch (error) {
      Logger.error(TAG, `History service example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用历史管理器的示例
   */
  public static async historyManagerExample(): Promise<void> {
    try {
      const historyManager = ServiceFactory.getInstance().getHistoryManager();
      
      // 获取观看统计
      const stats = await historyManager.getWatchStatistics();
      Logger.info(TAG, `Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}` instanceof Error ? `Total watched items: ${stats.totalItems}` : new Error(String(`Total watched items: ${stats.totalItems}`)))))));
      
    } catch (error) {
      Logger.error(TAG, `History manager example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 使用站点服务的示�?   */
  public static async siteServiceExample(): Promise<void> {
    try {
      const siteService = ServiceFactory.getInstance().getSiteService();
      
      // 获取启用的站�?      const enabledSites = await siteService.getEnabledSites();
      Logger.info(TAG, `Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}` instanceof Error ? `Enabled sites count: ${enabledSites.length}` : new Error(String(`Enabled sites count: ${enabledSites.length}`)))))));
      
      // 创建示例站点（仅用于演示�?      const exampleSite: Site = {
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
      
      // 保存站点
      await siteService.saveSite(exampleSite);
      Logger.info(TAG, `Example site saved: ${exampleSite.key}`);
      
    } catch (error) {
      Logger.error(TAG, `Site service example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 导出/导入示例
   */
  public static async exportImportExample(): Promise<void> {
    try {
      const siteService = ServiceFactory.getInstance().getSiteService();
      
      // 导出站点配置
      const exportData = await siteService.exportSites({
        includeCredentials: false, includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      } instanceof Error ? includeStats: true,
        description: 'Example export'
      } : new Error(String(includeStats: true,
        description: 'Example export'
      })))))));
      Logger.info(TAG, `Export data length: ${exportData.length} characters`);
      
      // 注意：实际导入会覆盖现有站点，这里只是演示代码结�?      // const importResult = await siteService.importSites(exportData);
      // Logger.info(TAG, `Import result: ${JSON.stringify(importResult)}`);
      
    } catch (error) {
      Logger.error(TAG, `Export/Import example error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 运行所有示�?   */
  public static async runAllExamples(): Promise<void> {
    Logger.info(TAG, 'Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...' instanceof Error ? 'Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...' : new Error(String('Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...' instanceof Error ? 'Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...' instanceof Error ? 'Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...' : new Error(String('Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...' : new Error(String('Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...' instanceof Error ? 'Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...' : new Error(String('Running all service examples...' instanceof Error ? 'Running all service examples...' : new Error(String('Running all service examples...')))))));
    
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

// 示例使用方法�?// ServiceUsageExample.runAllExamples().catch(error => {
//   Logger.error(TAG, `Failed to run examples: ${error}`);
// });


