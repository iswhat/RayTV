import Logger from '@ohos/base/Logger';
import { SiteManager } from './SiteManager';
import { LoaderFactory } from './LoaderFactory';
import { CacheManager } from './CacheManager';
import { BaseLoader } from './loader/BaseLoader';
import { SiteInfo, SiteStatus } from './SiteManager';
import { TaskPoolManager } from '@ohos/base/TaskPoolManager';
import { NetworkManager } from '@ohos/network/NetworkManager';

/**
 * 爬虫请求选项接口
 */
export interface CrawlerRequestOptions {
  timeout?: number; // 请求超时时间（毫秒）
  retryCount?: number; // 重试次数
  cacheExpiry?: number; // 缓存过期时间（毫秒）
  disableCache?: boolean; // 是否禁用缓存
  priority?: number; // 优先级
}

/**
 * 爬虫响应接口
 */
export interface CrawlerResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  fromCache?: boolean;
  siteInfo?: SiteInfo;
  executionTime?: number; // 执行时间（毫秒）
}

/**
 * 爬虫执行上下文
 */
export interface CrawlerContext {
  siteKey: string;
  method: string;
  params: any;
  options: CrawlerRequestOptions;
}

/**
 * 爬虫服务
 * 实现爬虫的核心功能，协调站点管理器、加载器工厂和缓存管理器
 */
export class CrawlerService {
  private readonly TAG: string = 'CrawlerService';
  private static instance: CrawlerService | null = null;
  private siteManager: SiteManager;
  private loaderFactory: LoaderFactory;
  private cacheManager: CacheManager;
  private networkManager: NetworkManager;
  private taskPoolManager: TaskPoolManager;
  private executingTasks: Map<string, Promise<any>> = new Map();

  /**
   * 默认请求选项
   */
  private static readonly DEFAULT_OPTIONS: CrawlerRequestOptions = {
    timeout: 30000, // 30秒
    retryCount: 2, // 2次重试
    cacheExpiry: 3600000, // 1小时
    disableCache: false,
    priority: 0
  };

  /**
   * 获取单例实例
   * @returns CrawlerService
   */
  public static getInstance(): CrawlerService {
    if (!CrawlerService.instance) {
      CrawlerService.instance = new CrawlerService();
    }
    return CrawlerService.instance;
  }

  /**
   * 构造函数
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.siteManager = SiteManager.getInstance();
    this.loaderFactory = LoaderFactory.getInstance();
    this.cacheManager = CacheManager.getInstance();
    this.networkManager = NetworkManager.getInstance();
    this.taskPoolManager = TaskPoolManager.getInstance();
    Logger.info(this.TAG, 'CrawlerService initialized');
  }

  /**
   * 调用站点方法
   * @param siteKey 站点唯一标识
   * @param method 方法名称
   * @param params 方法参数
   * @param options 请求选项
   * @returns Promise<CrawlerResponse<T>>
   */
  public async callSiteMethod<T = any>(
    siteKey: string,
    method: string,
    params: any = {},
    options?: CrawlerRequestOptions
  ): Promise<CrawlerResponse<T>> {
    const startTime = Date.now();
    const requestOptions = { ...CrawlerService.DEFAULT_OPTIONS, ...options };
    const context: CrawlerContext = {
      siteKey,
      method,
      params,
      options: requestOptions
    };
    
    // 生成请求ID
    const requestId = this.generateRequestId(context);
    
    try {
      // 检查站点是否存在
      const siteInfo = this.siteManager.getSite(siteKey);
      if (!siteInfo) {
        return this.createErrorResponse(`Site not found: ${siteKey}`, startTime);
      }
      
      // 检查站点状态
      if (siteInfo.status === SiteStatus.DISABLED) {
        return this.createErrorResponse(`Site ${siteKey} is disabled`, startTime);
      }
      
      if (siteInfo.status === SiteStatus.ERROR) {
        return this.createErrorResponse(`Site ${siteKey} is in error state`, startTime);
      }
      
      // 检查网络连接
      if (!this.networkManager.isConnected()) {
        Logger.warn(this.TAG, 'No network connection, trying to use cache');
        // 没有网络连接时，尝试使用缓存
        if (!requestOptions.disableCache) {
          const cachedData = await this.getFromCache(context);
          if (cachedData !== null) {
            return this.createSuccessResponse(cachedData, true, siteInfo, startTime);
          }
        }
        return this.createErrorResponse('No network connection and cache is disabled or miss', startTime);
      }
      
      // 尝试从缓存获取
      if (!requestOptions.disableCache) {
        const cachedData = await this.getFromCache(context);
        if (cachedData !== null) {
          return this.createSuccessResponse(cachedData, true, siteInfo, startTime);
        }
      }
      
      // 检查是否有相同的任务正在执行，如果有则等待其完成
      if (this.executingTasks.has(requestId)) {
        Logger.info(this.TAG, `Task ${requestId} is already executing, waiting for result`);
        const result = await this.executingTasks.get(requestId)!;
        return this.createSuccessResponse(result, false, siteInfo, startTime);
      }
      
      // 创建任务
      const taskPromise = this.executeTask(context, siteInfo, requestOptions);
      
      // 添加到执行中的任务列表
      this.executingTasks.set(requestId, taskPromise);
      
      try {
        // 执行任务
        const result = await taskPromise;
        
        // 更新站点性能统计
        this.updateSitePerformance(siteInfo, true, Date.now() - startTime);
        
        // 缓存结果（如果启用）
        if (!requestOptions.disableCache) {
          await this.cacheResult(context, result);
        }
        
        return this.createSuccessResponse(result, false, siteInfo, startTime);
      } finally {
        // 任务完成后从执行列表中移除
        this.executingTasks.delete(requestId);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to call site method ${siteKey}.${method}: ${error}`);
      
      // 更新站点性能统计
      const siteInfo = this.siteManager.getSite(siteKey);
      if (siteInfo) {
        this.updateSitePerformance(siteInfo, false, Date.now() - startTime);
      }
      
      return this.createErrorResponse(`Failed to execute: ${error}`, startTime);
    }
  }

  /**
   * 批量调用站点方法
   * @param requests 批量请求
   * @param concurrency 并发数
   * @returns Promise<CrawlerResponse<any>[]>
   */
  public async batchCall(
    requests: Array<{
      siteKey: string;
      method: string;
      params?: any;
      options?: CrawlerRequestOptions;
    }>,
    concurrency: number = 3
  ): Promise<CrawlerResponse<any>[]> {
    const results: CrawlerResponse<any>[] = [];
    const queue = [...requests];
    const inProgress = new Set<Promise<void>>();
    
    while (queue.length > 0 || inProgress.size > 0) {
      // 控制并发数
      while (inProgress.size < concurrency && queue.length > 0) {
        const request = queue.shift()!;
        const promise = this.callSiteMethod(
          request.siteKey,
          request.method,
          request.params,
          request.options
        ).then(result => {
          results.push(result);
        }).finally(() => {
          inProgress.delete(promise);
        });
        
        inProgress.add(promise);
      }
      
      if (inProgress.size > 0) {
        await Promise.race(inProgress);
      }
    }
    
    return results;
  }

  /**
   * 获取站点列表
   * @returns SiteInfo[]
   */
  public getSites(): SiteInfo[] {
    return this.siteManager.getSites();
  }

  /**
   * 获取站点信息
   * @param siteKey 站点唯一标识
   * @returns SiteInfo | undefined
   */
  public getSite(siteKey: string): SiteInfo | undefined {
    return this.siteManager.getSite(siteKey);
  }

  /**
   * 更新站点状态
   * @param siteKey 站点唯一标识
   * @param status 新状态
   * @returns boolean
   */
  public updateSiteStatus(siteKey: string, status: SiteStatus): boolean {
    return this.siteManager.updateSiteStatus(siteKey, status);
  }

  /**
   * 清空站点缓存
   * @param siteKey 站点唯一标识
   * @returns boolean
   */
  public clearSiteCache(siteKey: string): boolean {
    return this.cacheManager.clearSiteCache(siteKey);
  }

  /**
   * 清空所有缓存
   * @returns boolean
   */
  public clearAllCache(): boolean {
    return this.cacheManager.clear();
  }

  /**
   * 执行爬虫任务
   * @param context 爬虫上下文
   * @param siteInfo 站点信息
   * @param options 请求选项
   * @returns Promise<any>
   * @private
   */
  private async executeTask(
    context: CrawlerContext,
    siteInfo: SiteInfo,
    options: CrawlerRequestOptions
  ): Promise<any> {
    let attempts = 0;
    let lastError: Error | null = null;
    
    while (attempts <= options.retryCount!) {
      attempts++;
      
      try {
        // 获取或创建加载器
        const loader = await this.loaderFactory.getLoader(siteInfo);
        
        // 设置超时
        const timeoutPromise = new Promise<never>((_, reject) => {
          setTimeout(() => {
            reject(new Error(`Request timed out after ${options.timeout}ms`));
          }, options.timeout);
        });
        
        // 执行方法调用
        const executionPromise = loader.callMethod(
          context.method,
          context.params,
          {
            siteInfo,
            priority: options.priority
          }
        );
        
        // 使用Promise.race处理超时
        const result = await Promise.race([executionPromise, timeoutPromise]);
        
        // 验证结果
        if (result === undefined || result === null) {
          throw new Error('Empty or null result returned');
        }
        
        return result;
      } catch (error) {
        lastError = error as Error;
        Logger.warn(this.TAG, `Attempt ${attempts} failed for ${context.siteKey}.${context.method}: ${error}`);
        
        // 如果是最后一次尝试，则抛出错误
        if (attempts > options.retryCount!) {
          throw error;
        }
        
        // 指数退避重试
        const backoffTime = Math.pow(2, attempts - 1) * 1000 + Math.random() * 1000;
        Logger.info(this.TAG, `Retrying in ${backoffTime.toFixed(2)}ms...`);
        await new Promise(resolve => setTimeout(resolve, backoffTime));
      }
    }
    
    // 所有重试都失败
    throw lastError || new Error('Unknown error during task execution');
  }

  /**
   * 从缓存获取数据
   * @param context 爬虫上下文
   * @returns Promise<any | null>
   * @private
   */
  private async getFromCache(context: CrawlerContext): Promise<any | null> {
    const cacheKey = this.cacheManager.generateCacheKey(
      context.siteKey,
      context.method,
      context.params
    );
    
    return this.cacheManager.get(cacheKey);
  }

  /**
   * 缓存结果
   * @param context 爬虫上下文
   * @param result 执行结果
   * @returns Promise<boolean>
   * @private
   */
  private async cacheResult(context: CrawlerContext, result: any): Promise<boolean> {
    const cacheKey = this.cacheManager.generateCacheKey(
      context.siteKey,
      context.method,
      context.params
    );
    
    return this.cacheManager.set(cacheKey, result, context.options.cacheExpiry);
  }

  /**
   * 更新站点性能统计
   * @param siteInfo 站点信息
   * @param success 是否成功
   * @param executionTime 执行时间
   * @private
   */
  private updateSitePerformance(siteInfo: SiteInfo, success: boolean, executionTime: number): void {
    const now = Date.now();
    
    // 更新统计信息
    if (success) {
      siteInfo.successCount++;
      siteInfo.totalExecutionTime += executionTime;
      siteInfo.avgExecutionTime = siteInfo.totalExecutionTime / siteInfo.successCount;
      siteInfo.lastSuccessTime = now;
      
      // 如果连续失败计数大于0，重置
      if (siteInfo.consecutiveFailureCount > 0) {
        siteInfo.consecutiveFailureCount = 0;
      }
    } else {
      siteInfo.failureCount++;
      siteInfo.consecutiveFailureCount++;
      siteInfo.lastFailureTime = now;
      
      // 如果连续失败次数过多，禁用站点
      if (siteInfo.consecutiveFailureCount >= 5) {
        Logger.warn(this.TAG, `Site ${siteInfo.key} has ${siteInfo.consecutiveFailureCount} consecutive failures, disabling`);
        this.siteManager.updateSiteStatus(siteInfo.key, SiteStatus.ERROR);
      }
    }
    
    // 更新最后活动时间
    siteInfo.lastActiveTime = now;
    
    // 更新站点信息
    this.siteManager.updateSite(siteInfo);
  }

  /**
   * 生成请求ID
   * @param context 爬虫上下文
   * @returns string
   * @private
   */
  private generateRequestId(context: CrawlerContext): string {
    return `${context.siteKey}:${context.method}:${JSON.stringify(context.params)}`;
  }

  /**
   * 创建成功响应
   * @param data 响应数据
   * @param fromCache 是否来自缓存
   * @param siteInfo 站点信息
   * @param startTime 开始时间
   * @returns CrawlerResponse<T>
   * @private
   */
  private createSuccessResponse<T>(
    data: T,
    fromCache: boolean,
    siteInfo: SiteInfo,
    startTime: number
  ): CrawlerResponse<T> {
    return {
      success: true,
      data,
      fromCache,
      siteInfo,
      executionTime: Date.now() - startTime
    };
  }

  /**
   * 创建错误响应
   * @param errorMessage 错误信息
   * @param startTime 开始时间
   * @returns CrawlerResponse
   * @private
   */
  private createErrorResponse(errorMessage: string, startTime: number): CrawlerResponse {
    return {
      success: false,
      error: errorMessage,
      executionTime: Date.now() - startTime
    };
  }

  /**
   * 预加载站点
   * @param siteKeys 站点键列表
   * @returns Promise<void>
   */
  public async preloadSites(siteKeys: string[]): Promise<void> {
    const promises: Promise<void>[] = [];
    
    for (const siteKey of siteKeys) {
      const siteInfo = this.siteManager.getSite(siteKey);
      if (siteInfo) {
        const promise = this.loaderFactory.getLoader(siteInfo)
          .then(() => {
            Logger.info(this.TAG, `Preloaded site: ${siteKey}`);
          })
          .catch(error => {
            Logger.error(this.TAG, `Failed to preload site ${siteKey}: ${error}`);
          });
        
        promises.push(promise);
      }
    }
    
    await Promise.all(promises);
  }

  /**
   * 关闭所有加载器
   * @returns Promise<void>
   */
  public async shutdown(): Promise<void> {
    try {
      // 等待所有执行中的任务完成
      if (this.executingTasks.size > 0) {
        Logger.info(this.TAG, `Waiting for ${this.executingTasks.size} tasks to complete...`);
        await Promise.all(this.executingTasks.values());
      }
      
      // 清理加载器
      await this.loaderFactory.shutdown();
      
      Logger.info(this.TAG, 'CrawlerService shutdown completed');
    } catch (error) {
      Logger.error(this.TAG, `Failed to shutdown CrawlerService: ${error}`);
    }
  }
}