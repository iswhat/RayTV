import Logger from '../../common/util/Logger';
import HttpService from '../HttpService';
import { NetworkSourceConfig } from '../pool/SourcePoolManager';

const TAG = 'NetworkSourceHealthChecker';
const DEFAULT_TIMEOUT = 10000;
const CONCURRENT_LIMIT = 5;

export type HealthStatus = 'healthy' | 'degraded' | 'unreachable';

export default class NetworkSourceHealthChecker {
  private static instance: NetworkSourceHealthChecker | null = null;
  private httpService: HttpService;

  public static getInstance(): NetworkSourceHealthChecker {
    if (!NetworkSourceHealthChecker.instance) {
      NetworkSourceHealthChecker.instance = new NetworkSourceHealthChecker();
    }
    return NetworkSourceHealthChecker.instance;
  }

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  /**
   * 检查所有源的健康状态（并发分批）
   */
  public async checkAllSourcesHealth(sources: NetworkSourceConfig[]): Promise<Map<string, HealthStatus>> {
    const results: Map<string, HealthStatus> = new Map<string, HealthStatus>();
    await this.checkSourcesInBatches(sources, results);
    return results;
  }

  private async checkSourcesInBatches(
    sources: NetworkSourceConfig[],
    results: Map<string, HealthStatus>
  ): Promise<void> {
    const chunks: NetworkSourceConfig[][] = this.splitIntoChunks(sources, CONCURRENT_LIMIT);
    for (const chunk of chunks) {
      await this.checkSourceChunk(chunk, results);
    }
  }

  private splitIntoChunks(sources: NetworkSourceConfig[], size: number): NetworkSourceConfig[][] {
    const chunks: NetworkSourceConfig[][] = [];
    for (let i = 0; i < sources.length; i += size) {
      chunks.push(sources.slice(i, i + size));
    }
    return chunks;
  }

  private async checkSourceChunk(
    chunk: NetworkSourceConfig[],
    results: Map<string, HealthStatus>
  ): Promise<void> {
    const promises: Promise<void>[] = chunk.map((source: NetworkSourceConfig) => {
      return this.checkSingleSourceHealth(source, results);
    });
    await Promise.allSettled(promises);
  }

  private async checkSingleSourceHealth(
    source: NetworkSourceConfig,
    results: Map<string, HealthStatus>
  ): Promise<void> {
    try {
      const healthStatus: HealthStatus = await Promise.race([
        this.checkSourceHealthInternal(source.url),
        this.createTimeoutPromise()
      ]);
      source.healthStatus = healthStatus;
      source.lastUpdated = Date.now();
      results.set(source.id, healthStatus);
    } catch (err) {
      source.healthStatus = 'unreachable';
      source.lastUpdated = Date.now();
      results.set(source.id, 'unreachable');
    }
  }

  private createTimeoutPromise(): Promise<HealthStatus> {
    return new Promise<HealthStatus>((_, reject) => {
      setTimeout(() => {
        reject(new Error('Timeout'));
      }, DEFAULT_TIMEOUT);
    });
  }

  /**
   * 内部健康检查：发起 HTTP GET 并根据响应时间判断状态
   */
  public async checkSourceHealthInternal(url: string): Promise<HealthStatus> {
    try {
      const startTime: number = Date.now();
      const response = await this.httpService.get(url, { timeout: DEFAULT_TIMEOUT });
      const duration: number = Date.now() - startTime;
      if (response && response.status >= 200 && response.status < 300) {
        return duration > 5000 ? 'degraded' : 'healthy';
      }
      return 'degraded';
    } catch (err) {
      return 'unreachable';
    }
  }

  /**
   * 检查单个 URL 健康状态（对外接口）
   */
  public async checkSingleSource(url: string): Promise<HealthStatus> {
    try {
      return await this.checkSourceHealthInternal(url);
    } catch (err) {
      Logger.error(TAG, `Failed to check single source health: ${err}`);
      return 'unreachable';
    }
  }

  /**
   * 统计健康状态分布
   */
  public getHealthStats(sources: NetworkSourceConfig[]): {
    total: number;
    healthy: number;
    degraded: number;
    unreachable: number;
  } {
    return {
      total: sources.length,
      healthy: sources.filter((s: NetworkSourceConfig) => s.healthStatus === 'healthy').length,
      degraded: sources.filter((s: NetworkSourceConfig) => s.healthStatus === 'degraded').length,
      unreachable: sources.filter((s: NetworkSourceConfig) => s.healthStatus === 'unreachable').length
    };
  }

  /** 过滤健康源 */
  public getHealthySources(sources: NetworkSourceConfig[]): NetworkSourceConfig[] {
    return sources.filter((s: NetworkSourceConfig) => s.healthStatus === 'healthy');
  }

  /** 过滤可访问源（healthy + degraded） */
  public getAccessibleSources(sources: NetworkSourceConfig[]): NetworkSourceConfig[] {
    return sources.filter((s: NetworkSourceConfig) =>
      s.healthStatus === 'healthy' || s.healthStatus === 'degraded'
    );
  }
}
