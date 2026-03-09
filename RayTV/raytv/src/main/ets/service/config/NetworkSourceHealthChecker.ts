import Logger from '../../common/util/Logger';
import HttpService from '../HttpService';
import { NetworkSourceConfig } from '../pool/SourcePoolManager';

const TAG = 'NetworkSourceHealthChecker';
const DEFAULT_TIMEOUT = 10000; // 默认超时时间(毫秒)
const CONCURRENT_LIMIT = 5; // 并发检查限制

export type HealthStatus = 'healthy' | 'degraded' | 'unreachable';

export default class NetworkSourceHealthChecker {
  private static instance: NetworkSourceHealthChecker | null = null;
  private logger: Logger;
  private httpService: HttpService;

  /**
   * 获取单例实例
   */
  public static getInstance(): NetworkSourceHealthChecker {
    if (!NetworkSourceHealthChecker.instance) {
      NetworkSourceHealthChecker.instance = new NetworkSourceHealthChecker();
    }
    return NetworkSourceHealthChecker.instance;
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger = Logger.getInstance(TAG);
    this.httpService = HttpService.getInstance();
  }

  /**
   * 检查所有源的健康状态
   * 使用并发控制，避免大量同时请求
   */
  public async checkAllSourcesHealth(sources: NetworkSourceConfig[]): Promise<Map<string, HealthStatus>> {
    const results: Map<string, HealthStatus> = new Map<string, HealthStatus>();
    
    // 分批次检查源健康状态
    await this.checkSourcesInBatches(sources, results);
    
    return results;
  }

  /**
   * 分批次检查源健康状态
   */
  private async checkSourcesInBatches(sources: NetworkSourceConfig[], results: Map<string, HealthStatus>): Promise<void> {
    // 使用并发控制，最多同时检查指定数量的源
    const chunks: NetworkSourceConfig[][] = this.splitSourcesIntoChunks(sources, CONCURRENT_LIMIT);
    
    for (const chunk of chunks) {
      await this.checkSourceChunk(chunk, results);
    }
  }

  /**
   * 将源列表拆分为批次
   */
  private splitSourcesIntoChunks(sources: NetworkSourceConfig[], chunkSize: number): NetworkSourceConfig[][] {
    const chunks: NetworkSourceConfig[][] = [];
    for (let i = 0; i < sources.length; i += chunkSize) {
      chunks.push(sources.slice(i, i + chunkSize));
    }
    return chunks;
  }

  /**
   * 检查单个批次的源健康状态
   */
  private async checkSourceChunk(chunk: NetworkSourceConfig[], results: Map<string, HealthStatus>): Promise<void> {
    const checkPromises = chunk.map(async (source: NetworkSourceConfig) => {
      await this.checkSingleSourceHealth(source, results);
    });
    
    // 等待当前批次完成
    await Promise.allSettled(checkPromises);
  }

  /**
   * 检查单个源的健康状态
   */
  private async checkSingleSourceHealth(source: NetworkSourceConfig, results: Map<string, HealthStatus>): Promise<void> {
    try {
      // 添加超时控制
      const healthStatus: HealthStatus = await Promise.race([
        this.checkSourceHealthInternal(source.url),
        this.createTimeoutPromise()
      ]);
      
      source.healthStatus = healthStatus;
      source.lastUpdated = Date.now();
      results.set(source.id, healthStatus);
    } catch (error: unknown) {
      source.healthStatus = 'unreachable';
      source.lastUpdated = Date.now();
      results.set(source.id, 'unreachable');
    }
  }

  /**
   * 创建超时Promise
   */
  private createTimeoutPromise(): Promise<HealthStatus> {
    return new Promise<HealthStatus>((_, reject) => {
      setTimeout(() => {
        reject(new Error('Timeout'));
      }, DEFAULT_TIMEOUT); // 10秒超时
    });
  }

  /**
   * 内部健康检查方法
   */
  public async checkSourceHealthInternal(url: string): Promise<HealthStatus> {
    try {
      const startTime: number = Date.now();
      const response = await this.httpService.get(url, { timeout: DEFAULT_TIMEOUT });
      const duration: number = Date.now() - startTime;
      
      if (response && response.statusCode >= 200 && response.statusCode < 300) {
        // 响应时间超过5秒视为降级
        return duration > 5000 ? 'degraded' : 'healthy';
      }
      
      return 'degraded';
    } catch (error: unknown) {
      return 'unreachable';
    }
  }

  /**
   * 检查单个源的健康状态（外部调用）
   */
  public async checkSingleSource(url: string): Promise<HealthStatus> {
    try {
      return await this.checkSourceHealthInternal(url);
    } catch (error: unknown) {
      this.logger.error('Failed to check single source health', error);
      return 'unreachable';
    }
  }

  /**
   * 计算健康状态统计
   */
  public getHealthStats(sources: NetworkSourceConfig[]): {
    total: number;
    healthy: number;
    degraded: number;
    unreachable: number;
  } {
    const stats = {
      total: sources.length,
      healthy: sources.filter((s: NetworkSourceConfig) => s.healthStatus === 'healthy').length,
      degraded: sources.filter((s: NetworkSourceConfig) => s.healthStatus === 'degraded').length,
      unreachable: sources.filter((s: NetworkSourceConfig) => s.healthStatus === 'unreachable').length
    };
    
    return stats;
  }

  /**
   * 过滤出健康的源
   */
  public getHealthySources(sources: NetworkSourceConfig[]): NetworkSourceConfig[] {
    return sources.filter((s: NetworkSourceConfig) => s.healthStatus === 'healthy');
  }

  /**
   * 过滤出可访问的源（包括健康和降级）
   */
  public getAccessibleSources(sources: NetworkSourceConfig[]): NetworkSourceConfig[] {
    return sources.filter((s: NetworkSourceConfig) => 
      s.healthStatus === 'healthy' || s.healthStatus === 'degraded'
    );
  }
}
