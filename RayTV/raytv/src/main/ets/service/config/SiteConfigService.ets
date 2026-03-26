import Logger from '../../common/util/Logger';
import { ErrorHandler, ErrorType, ErrorSeverity } from '../../common/util/ErrorHandler';

// 站点配置接口 | Site config interface
export interface SiteConfig {
  // 缓存配置 | Cache config
  cache: {
    allSitesExpiry: number;      // 所有站点缓存过期时间（毫秒）
    singleSiteExpiry: number;    // 单个站点缓存过期时间（毫秒）
    defaultExpiry: number;       // 默认缓存过期时间（毫秒）
  };
  // HTTP请求配置 | HTTP request config
  http: {
    defaultTimeout: number;      // 默认超时时间（毫秒）
    testTimeout: number;         // 测试连接超时时间（毫秒）
    maxRetries: number;          // 最大重试次数
    retryDelay: number;          // 重试延迟（毫秒）
  };
  // API路径配置 | API path config
  api: {
    homePath: string;            // 首页路径
    channelsPath: string;        // 频道列表路径
    searchPath: string;          // 搜索路径
    detailPath: string;          // 详情路径
  };
  // 站点测试配置 | Site test config
  test: {
    maxResponseTime: number;     // 最大响应时间（毫秒）
    warningResponseTime: number; // 警告响应时间（毫秒）
    testInterval: number;        // 测试间隔（毫秒）
  };
  // 健康检查配置 | Health check config
  healthCheck: {
    enabled: boolean;            // 是否启用健康检查
    interval: number;            // 检查间隔（毫秒）
    timeout: number;             // 检查超时时间（毫秒）
    failureThreshold: number;    // 失败阈值
    successThreshold: number;    // 成功阈值
  };
}

// 默认站点配置 | Default site config
const DEFAULT_SITE_CONFIG: SiteConfig = {
  cache: {
    allSitesExpiry: 5 * 60 * 1000,      // 5分钟
    singleSiteExpiry: 10 * 60 * 1000,   // 10分钟
    defaultExpiry: 30 * 60 * 1000       // 30分钟
  },
  http: {
    defaultTimeout: 30000,              // 30秒
    testTimeout: 10000,                 // 10秒
    maxRetries: 3,                      // 最大重试3次
    retryDelay: 1000                    // 重试延迟1秒
  },
  api: {
    homePath: '/home',
    channelsPath: '/channels',
    searchPath: '/search',
    detailPath: '/detail'
  },
  test: {
    maxResponseTime: 10000,             // 10秒
    warningResponseTime: 5000,          // 5秒
    testInterval: 60000                 // 1分钟
  },
  healthCheck: {
    enabled: true,
    interval: 5 * 60 * 1000,            // 5分钟
    timeout: 10000,                     // 10秒
    failureThreshold: 3,                // 连续失败3次标记为不健康
    successThreshold: 2                 // 连续成功2次恢复为健康
  }
};

/**
 * 站点配置服务 | Site config service
 * 管理站点相关的所有配置 | Manage all site-related configurations
 */
export class SiteConfigService {
  private static instance: SiteConfigService;
  private readonly TAG: string = 'SiteConfigService';

  private config: SiteConfig = DEFAULT_SITE_CONFIG;
  private errorHandler: ErrorHandler = ErrorHandler.getInstance();

  private constructor() {}

  public static getInstance(): SiteConfigService {
    if (!SiteConfigService.instance) {
      SiteConfigService.instance = new SiteConfigService();
    }
    return SiteConfigService.instance;
  }

  /**
   * 获取完整配置 | Get full config
   */
  public getConfig(): SiteConfig {
    return this.config;
  }

  /**
   * 获取缓存配置 | Get cache config
   */
  public getCacheConfig(): SiteConfig['cache'] {
    return this.config.cache;
  }

  /**
   * 获取HTTP配置 | Get HTTP config
   */
  public getHttpConfig(): SiteConfig['http'] {
    return this.config.http;
  }

  /**
   * 获取API配置 | Get API config
   */
  public getApiConfig(): SiteConfig['api'] {
    return this.config.api;
  }

  /**
   * 获取测试配置 | Get test config
   */
  public getTestConfig(): SiteConfig['test'] {
    return this.config.test;
  }

  /**
   * 获取健康检查配置 | Get health check config
   */
  public getHealthCheckConfig(): SiteConfig['healthCheck'] {
    return this.config.healthCheck;
  }

  /**
   * 更新配置 | Update config
   */
  public updateConfig(newConfig: Partial<SiteConfig>): void {
    try {
      this.config = {
        ...this.config,
        ...newConfig,
        cache: { ...this.config.cache, ...newConfig.cache },
        http: { ...this.config.http, ...newConfig.http },
        api: { ...this.config.api, ...newConfig.api },
        test: { ...this.config.test, ...newConfig.test },
        healthCheck: { ...this.config.healthCheck, ...newConfig.healthCheck }
      };
      Logger.info(this.TAG, 'Site config updated');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.CONFIG, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to update config: ${error}`);
    }
  }

  /**
   * 重置为默认配置 | Reset to default config
   */
  public resetToDefault(): void {
    this.config = DEFAULT_SITE_CONFIG;
    Logger.info(this.TAG, 'Site config reset to default');
  }

  /**
   * 从配置文件加载 | Load from config file
   */
  public async loadFromFile(filePath: string): Promise<void> {
    try {
      // 这里可以实现从文件加载配置的逻辑
      // 暂时使用默认配置
      Logger.info(this.TAG, `Loading config from ${filePath}`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.CONFIG, ErrorSeverity.MEDIUM, this.TAG);
      Logger.error(this.TAG, `Failed to load config from file: ${error}`);
    }
  }

  /**
   * 保存到配置文件 | Save to config file
   */
  public async saveToFile(filePath: string): Promise<void> {
    try {
      // 这里可以实现保存配置到文件的逻辑
      Logger.info(this.TAG, `Saving config to ${filePath}`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.CONFIG, ErrorSeverity.MEDIUM, this.TAG);
      Logger.error(this.TAG, `Failed to save config to file: ${error}`);
    }
  }
}

// 导出单例实例 | Export singleton instance
export function getSiteConfigService(): SiteConfigService {
  return SiteConfigService.getInstance();
}
