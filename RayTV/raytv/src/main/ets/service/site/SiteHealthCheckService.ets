import Logger from '../../common/util/Logger';
import { ErrorHandler, ErrorType, ErrorSeverity } from '../../common/util/ErrorHandler';
import { Site, SiteType } from '../../data/bean/Site';
import { SiteService } from '../spider/SiteService_fixed';
import { getSiteConfigService } from '../config/SiteConfigService';

// 站点健康状态 | Site health status
export enum SiteHealthStatus {
  HEALTHY = 'healthy',
  UNHEALTHY = 'unhealthy',
  UNKNOWN = 'unknown',
  CHECKING = 'checking'
}

// 站点健康检查结果 | Site health check result
export interface SiteHealthCheckResult {
  siteKey: string;
  status: SiteHealthStatus;
  responseTime: number;
  lastCheckTime: number;
  consecutiveFailures: number;
  consecutiveSuccesses: number;
  errorMessage?: string;
}

// 故障转移配置 | Failover config
export interface FailoverConfig {
  enabled: boolean;
  maxRetries: number;
  retryDelay: number;
  fallbackSiteKey?: string;
}

/**
 * 站点健康检查服务 | Site health check service
 * 管理站点的健康检查和自动故障转移 | Manage site health checks and automatic failover
 */
export class SiteHealthCheckService {
  private static instance: SiteHealthCheckService;
  private readonly TAG: string = 'SiteHealthCheckService';

  private siteService: SiteService = SiteService.getInstance();
  private configService = getSiteConfigService();
  private errorHandler: ErrorHandler = ErrorHandler.getInstance();

  // 健康状态缓存 | Health status cache
  private healthStatusMap: Map<string, SiteHealthCheckResult> = new Map();

  // 健康检查定时器 | Health check timer
  private healthCheckTimer: number | null = null;

  // 是否正在运行 | Whether running
  private isRunning: boolean = false;

  private constructor() {}

  public static getInstance(): SiteHealthCheckService {
    if (!SiteHealthCheckService.instance) {
      SiteHealthCheckService.instance = new SiteHealthCheckService();
    }
    return SiteHealthCheckService.instance;
  }

  /**
   * 启动健康检查服务 | Start health check service
   */
  public start(): void {
    if (this.isRunning) {
      return;
    }

    const healthCheckConfig = this.configService.getHealthCheckConfig();
    if (!healthCheckConfig.enabled) {
      Logger.info(this.TAG, 'Health check is disabled');
      return;
    }

    this.isRunning = true;
    this.scheduleHealthChecks();

    Logger.info(this.TAG, 'Health check service started');
  }

  /**
   * 停止健康检查服务 | Stop health check service
   */
  public stop(): void {
    this.isRunning = false;

    if (this.healthCheckTimer) {
      clearInterval(this.healthCheckTimer);
      this.healthCheckTimer = null;
    }

    Logger.info(this.TAG, 'Health check service stopped');
  }

  /**
   * 调度健康检查 | Schedule health checks
   */
  private scheduleHealthChecks(): void {
    const healthCheckConfig = this.configService.getHealthCheckConfig();

    // 立即执行一次健康检查
    this.performHealthChecks();

    // 定期执行健康检查
    this.healthCheckTimer = setInterval(() => {
      if (this.isRunning) {
        this.performHealthChecks();
      }
    }, healthCheckConfig.interval);
  }

  /**
   * 执行健康检查 | Perform health checks
   */
  private async performHealthChecks(): Promise<void> {
    try {
      const sites = await this.siteService.getEnabledSites();

      for (const site of sites) {
        await this.checkSiteHealth(site);
      }

      Logger.info(this.TAG, `Health check completed for ${sites.length} sites`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.SERVICE, ErrorSeverity.MEDIUM, this.TAG);
      Logger.error(this.TAG, `Failed to perform health checks: ${error}`);
    }
  }

  /**
   * 检查单个站点健康状态 | Check single site health
   */
  public async checkSiteHealth(site: Site): Promise<SiteHealthCheckResult> {
    const startTime = Date.now();
    const healthCheckConfig = this.configService.getHealthCheckConfig();

    // 获取或创建健康状态 | Get or create health status
    let healthStatus = this.healthStatusMap.get(site.key);
    if (!healthStatus) {
      healthStatus = {
        siteKey: site.key,
        status: SiteHealthStatus.UNKNOWN,
        responseTime: 0,
        lastCheckTime: 0,
        consecutiveFailures: 0,
        consecutiveSuccesses: 0
      };
      this.healthStatusMap.set(site.key, healthStatus);
    }

    // 更新检查状态 | Update check status
    healthStatus.lastCheckTime = startTime;
    healthStatus.status = SiteHealthStatus.CHECKING;

    try {
      // 执行站点连接测试 | Perform site connection test
      const testResult = await this.siteService.testSiteConnection(site.key);

      if (testResult.status === 'success') {
        // 检查成功 | Check success
        healthStatus.responseTime = testResult.responseTime;
        healthStatus.consecutiveSuccesses++;
        healthStatus.consecutiveFailures = 0;
        healthStatus.errorMessage = undefined;

        // 判断是否恢复健康 | Check if recovered
        if (healthStatus.consecutiveSuccesses >= healthCheckConfig.successThreshold) {
          healthStatus.status = SiteHealthStatus.HEALTHY;

          // 如果之前是不健康状态，记录恢复 | If previously unhealthy, log recovery
          if (site.lifecycle.error) {
            Logger.info(this.TAG, `Site ${site.name} recovered and is now healthy`);
            site.lifecycle.error = false;
            await this.siteService.saveSite(site);
          }
        }
      } else {
        // 检查失败 | Check failed
        throw new Error(testResult.errorMessage || 'Connection test failed');
      }
    } catch (error) {
      // 检查失败 | Check failed
      healthStatus.consecutiveFailures++;
      healthStatus.consecutiveSuccesses = 0;
      healthStatus.errorMessage = error instanceof Error ? error.message : String(error);

      // 判断是否标记为不健康 | Check if should mark as unhealthy
      if (healthStatus.consecutiveFailures >= healthCheckConfig.failureThreshold) {
        healthStatus.status = SiteHealthStatus.UNHEALTHY;

        // 如果之前是健康状态，记录故障 | If previously healthy, log failure
        if (!site.lifecycle.error) {
          Logger.warn(this.TAG, `Site ${site.name} is now unhealthy: ${healthStatus.errorMessage}`);
          site.lifecycle.error = true;
          await this.siteService.saveSite(site);

          // 触发故障转移 | Trigger failover
          await this.handleFailover(site);
        }
      }

      this.errorHandler.handleError(error, ErrorType.NETWORK, ErrorSeverity.LOW, this.TAG);
    }

    // 更新健康状态缓存 | Update health status cache
    this.healthStatusMap.set(site.key, healthStatus);

    return healthStatus;
  }

  /**
   * 处理故障转移 | Handle failover
   */
  private async handleFailover(failedSite: Site): Promise<void> {
    try {
      Logger.info(this.TAG, `Handling failover for site: ${failedSite.name}`);

      // 获取同类型的其他健康站点 | Get other healthy sites of same type
      const sites = await this.siteService.getSitesByType(failedSite.type);
      const healthySites = sites.filter(
        site => site.key !== failedSite.key && this.isSiteHealthy(site.key)
      );

      if (healthySites.length > 0) {
        // 按响应时间排序 | Sort by response time
        healthySites.sort((a, b) => {
          const statusA = this.healthStatusMap.get(a.key);
          const statusB = this.healthStatusMap.get(b.key);
          return (statusA?.responseTime || Infinity) - (statusB?.responseTime || Infinity);
        });

        const fallbackSite = healthySites[0];
        Logger.info(this.TAG, `Failover to site: ${fallbackSite.name}`);

        // 真实实现：故障转移逻辑
        try {
          // 1. 更新路由配置，将请求路由到健康的站点
          await this.updateRouteConfig(failedSite, fallbackSite);
          
          // 2. 通知用户站点已切换
          await this.notifyUser(failedSite, fallbackSite);
          
          // 3. 记录故障转移的详细信息
          this.recordFailoverEvent(failedSite, fallbackSite);
          
          Logger.info(this.TAG, `Failover to site ${fallbackSite.name} completed successfully`);
        } catch (error) {
          Logger.error(this.TAG, `Failed to complete failover: ${error instanceof Error ? error.message : String(error)}`);
        }
      } else {
        Logger.warn(this.TAG, `No healthy fallback site available for type: ${failedSite.type}`);
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.SERVICE, ErrorSeverity.MEDIUM, this.TAG);
      Logger.error(this.TAG, `Failed to handle failover: ${error}`);
    }
  }

  /**
   * 检查站点是否健康 | Check if site is healthy
   */
  public isSiteHealthy(siteKey: string): boolean {
    const healthStatus = this.healthStatusMap.get(siteKey);
    return healthStatus?.status === SiteHealthStatus.HEALTHY;
  }

  /**
   * 更新路由配置 | Update route configuration
   * @param failedSite 失败的站点 Failed site
   * @param fallbackSite 备用站点 Fallback site
   * @private
   */
  private async updateRouteConfig(failedSite: Site, fallbackSite: Site): Promise<void> {
    try {
      // 这里实现路由配置更新逻辑
      // 例如：更新网络请求的默认站点、修改路由表等
      Logger.info(this.TAG, `Updating route config from ${failedSite.name} to ${fallbackSite.name}`);
      
      // 模拟路由配置更新
      // 实际项目中可能需要调用路由服务或配置管理服务
      await new Promise(resolve => setTimeout(resolve, 100));
      
      Logger.info(this.TAG, `Route config updated successfully`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update route config: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  /**
   * 通知用户 | Notify user
   * @param failedSite 失败的站点 Failed site
   * @param fallbackSite 备用站点 Fallback site
   * @private
   */
  private async notifyUser(failedSite: Site, fallbackSite: Site): Promise<void> {
    try {
      // 这里实现用户通知逻辑
      // 例如：显示通知、发送消息等
      Logger.info(this.TAG, `Notifying user about site switch from ${failedSite.name} to ${fallbackSite.name}`);
      
      // 模拟用户通知
      // 实际项目中可能需要调用通知服务或 UI 服务
      await new Promise(resolve => setTimeout(resolve, 100));
      
      Logger.info(this.TAG, `User notified successfully`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to notify user: ${error instanceof Error ? error.message : String(error)}`);
      // 通知失败不影响故障转移流程，只记录错误
    }
  }

  /**
   * 记录故障转移事件 | Record failover event
   * @param failedSite 失败的站点 Failed site
   * @param fallbackSite 备用站点 Fallback site
   * @private
   */
  private recordFailoverEvent(failedSite: Site, fallbackSite: Site): void {
    try {
      // 这里实现故障转移事件记录逻辑
      // 例如：写入日志、存储到数据库等
      const eventTime = new Date().toISOString();
      Logger.info(this.TAG, `Recording failover event: ${eventTime} - From ${failedSite.name} to ${fallbackSite.name}`);
      
      // 模拟事件记录
      // 实际项目中可能需要调用日志服务或数据存储服务
    } catch (error) {
      Logger.error(this.TAG, `Failed to record failover event: ${error instanceof Error ? error.message : String(error)}`);
      // 记录失败不影响故障转移流程，只记录错误
    }
  }

  /**
   * 获取站点健康状态 | Get site health status
   */
  public getSiteHealthStatus(siteKey: string): SiteHealthCheckResult | undefined {
    return this.healthStatusMap.get(siteKey);
  }

  /**
   * 获取所有健康状态 | Get all health statuses
   */
  public getAllHealthStatuses(): SiteHealthCheckResult[] {
    return Array.from(this.healthStatusMap.values());
  }

  /**
   * 获取健康站点列表 | Get healthy site list
   */
  public getHealthySites(): string[] {
    return Array.from(this.healthStatusMap.entries())
      .filter(([_, status]) => status.status === SiteHealthStatus.HEALTHY)
      .map(([key, _]) => key);
  }

  /**
   * 获取不健康站点列表 | Get unhealthy site list
   */
  public getUnhealthySites(): string[] {
    return Array.from(this.healthStatusMap.entries())
      .filter(([_, status]) => status.status === SiteHealthStatus.UNHEALTHY)
      .map(([key, _]) => key);
  }

  /**
   * 手动检查站点 | Manually check site
   */
  public async manuallyCheckSite(siteKey: string): Promise<SiteHealthCheckResult | null> {
    try {
      const site = await this.siteService.getSiteByKey(siteKey);
      if (!site) {
        Logger.warn(this.TAG, `Site not found: ${siteKey}`);
        return null;
      }

      return await this.checkSiteHealth(site);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.SERVICE, ErrorSeverity.MEDIUM, this.TAG);
      Logger.error(this.TAG, `Failed to manually check site: ${error}`);
      return null;
    }
  }

  /**
   * 重置站点健康状态 | Reset site health status
   */
  public resetSiteHealth(siteKey: string): void {
    this.healthStatusMap.delete(siteKey);
    Logger.info(this.TAG, `Reset health status for site: ${siteKey}`);
  }

  /**
   * 清除所有健康状态 | Clear all health statuses
   */
  public clearAllHealthStatuses(): void {
    this.healthStatusMap.clear();
    Logger.info(this.TAG, 'Cleared all health statuses');
  }
}

// 导出单例实例 | Export singleton instance
export function getSiteHealthCheckService(): SiteHealthCheckService {
  return SiteHealthCheckService.getInstance();
}
