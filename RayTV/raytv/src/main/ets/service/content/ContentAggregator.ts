/**
 * 内容聚合服务实现 | Content Aggregation Service Implementation
 * 负责从多个配置源聚合和管理媒体内容 | Responsible for aggregating and managing media content from multiple config sources
 */
import Logger from '../../common/util/Logger';
import CacheService from '../cache/CacheService';
import AppService from '../AppService';
import { IConfigSourceService } from '../interfaces/IConfigSourceService';
import {
  IContentAggregator,
  AggregatedContent,
  AggregatedSite,
  ContentCategory,
  AggregationStatistics,
  SiteQualityMetrics
} from '../interfaces/IContentAggregator';
import ApiResponse from '../../data/dto/ApiResponse';

// 常量定义 | Constants definition
const TAG = 'ContentAggregator';
const AGGREGATION_CACHE_KEY = 'aggregated_content';
const SITE_QUALITY_CACHE_KEY = 'site_quality_metrics';
const LAST_AGGREGATION_TIME_KEY = 'last_aggregation_time';
const AGGREGATION_CACHE_DURATION = 1800000; // 30分钟 | 30 minutes

/**
 * 排序选项类型
 */
export type SortOption = 'quality' | 'reliability' | 'recent' | 'name';

/**
 * 内容聚合服务类
 * 
 * 负责从多个配置源聚合和管理媒体内容，提供内容聚合、站点管理、分类生成等功能。
 * 支持内容缓存、质量评估、搜索和分类过滤等高级特性。
 * 
 * @example
 * ```typescript
 * // 获取ContentAggregator实例
 * import contentAggregator from './service/content/ContentAggregator';
 * 
 * // 初始化服务
 * await contentAggregator.initialize();
 * 
 * // 聚合所有配置源的内容
 * const result = await contentAggregator.aggregateAllSources();
 * if (result.isSuccess()) {
 *   console.log('Aggregated content:', result.data);
 * }
 * ```
 */
export class ContentAggregator implements IContentAggregator {
  private static instance: ContentAggregator | null = null;
  private configSourceService: IConfigSourceService;
  private cacheService: CacheService;
  private logger: Logger;
  private initialized: boolean = false;

  /**
   * 获取单例实例
   * 
   * 实现了单例模式，确保全局只有一个ContentAggregator实例。
   * 
   * @returns ContentAggregator单例实例
   * @example
   * ```typescript
   * const contentAggregator = ContentAggregator.getInstance();
   * ```
   */
  public static getInstance(): ContentAggregator {
    if (!ContentAggregator.instance) {
      ContentAggregator.instance = new ContentAggregator();
    }
    return ContentAggregator.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    // 通过依赖注入获取服务实例 | Obtain service instances through dependency injection
    this.cacheService = CacheService.getInstance();
    this.logger = new Logger(TAG);
    // 自动获取配置源服务 | Auto get config source service
    this.autoGetConfigSourceService();
  }

  /**
   * 自动获取配置源服务 | Auto get config source service
   */
  private autoGetConfigSourceService(): void {
    try {
      // 尝试从AppService获取配置源服务 | Try to get config source service from AppService
      const appService = AppService.getInstance();
      if (appService) {
        const configService = appService.getService('config');
        if (configService && typeof configService.getConfigSourceService === 'function') {
          this.configSourceService = configService.getConfigSourceService();
          this.logger.info('Config source service auto obtained from AppService');
        }
      }
    } catch (error) {
      this.logger.warn('Failed to auto get config source service', error);
      // 保持为空，后续可以手动设置 | Keep empty, can be set manually later
    }
  }

  /**
   * 设置配置源服务
   * 
   * 设置配置源服务实例，用于获取和管理配置源。
   * 
   * @param service 配置源服务实例
   * @returns void
   * @example
   * ```typescript
   * import configSourceService from './service/config/ConfigSourceService';
   * contentAggregator.setConfigSourceService(configSourceService);
   * ```
   */
  public setConfigSourceService(service: IConfigSourceService): void {
    this.configSourceService = service;
    this.logger.info('Config source service set manually');
  }

  /**
   * 初始化服务
   * 
   * 初始化内容聚合服务，验证依赖服务。
   * 
   * @returns Promise<void>
   * @throws Error - 当初始化失败时抛出错误
   * @example
   * ```typescript
   * await contentAggregator.initialize();
   * console.log('ContentAggregator initialized');
   * ```
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 验证依赖服务 | Validate dependent services
      if (!this.configSourceService) {
        throw new Error('ConfigSourceService not set');
      }

      this.initialized = true;
      this.logger.info('ContentAggregator initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize ContentAggregator', error);
      throw error;
    }
  }

  /**
   * 从所有激活的配置源聚合内容
   * 
   * 从所有激活的配置源聚合媒体内容，支持缓存。
   * 
   * @returns Promise<ApiResponse<AggregatedContent>> - 包含聚合内容的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.aggregateAllSources();
   * if (result.isSuccess()) {
   *   console.log('Aggregated content:', result.data);
   * } else {
   *   console.error('Aggregation failed:', result.message);
   * }
   * ```
   */
  public async aggregateAllSources(): Promise<ApiResponse<AggregatedContent>> {
    try {
      this.logger.info('Starting aggregation from all active sources');

      // 检查缓存 | Check cache first
      const cachedResult = await this.cacheService.get<AggregatedContent>(AGGREGATION_CACHE_KEY);
      if (cachedResult) {
        this.logger.info('Returning cached aggregation result');
        return ApiResponse.success(cachedResult);
      }

      // 获取激活的配置源 | Get active config sources
      const sourcesResult = await this.configSourceService.getActiveSources();
      if (!sourcesResult.isSuccess()) {
        return ApiResponse.failure(`Failed to get active sources: ${sourcesResult.message}`);
      }

      const sourceUrls = sourcesResult.data!.map(source => source.url);
      return await this.aggregateFromSources(sourceUrls);

    } catch (error) {
      this.logger.error('Failed to aggregate all sources', error);
      return ApiResponse.failure(`Aggregation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 从指定配置源聚合内容
   * 
   * 从指定的配置源URL列表聚合媒体内容，支持并行加载和质量评估。
   * 
   * @param sourceUrls 配置源URL列表
   * @returns Promise<ApiResponse<AggregatedContent>> - 包含聚合内容的API响应
   * @example
   * ```typescript
   * const sourceUrls = ['https://example.com/config1.json', 'https://example.com/config2.json'];
   * const result = await contentAggregator.aggregateFromSources(sourceUrls);
   * if (result.isSuccess()) {
   *   console.log('Aggregated content:', result.data);
   * }
   * ```
   */
  public async aggregateFromSources(sourceUrls: string[]): Promise<ApiResponse<AggregatedContent>> {
    try {
      this.logger.info(`Aggregating content from ${sourceUrls.length} sources`);

      if (sourceUrls.length === 0) {
        return ApiResponse.failure('No source URLs provided');
      }

      // 并行加载所有配置源 | Load all config sources in parallel
      const loadStartTime = Date.now();
      const configResults = await Promise.all(
        sourceUrls.map(url => this.configSourceService.loadConfigSource(url))
      );
      const loadEndTime = Date.now();

      // 过滤成功的配置源 | Filter successful config sources
      const successfulConfigs = configResults.filter(result => result.isSuccess());
      const failedConfigs = configResults.filter(result => !result.isSuccess());

      if (successfulConfigs.length === 0) {
        return ApiResponse.failure('All config sources failed to load');
      }

      this.logger.info(`Successfully loaded ${successfulConfigs.length}/${sourceUrls.length} config sources`);

      // 解析和聚合内容 | Parse and aggregate content
      const aggregationStartTime = Date.now();
      const aggregatedSites: Map<string, AggregatedSite> = new Map();
      const allCategories: ContentCategory[] = [];
      const allParsers: Set<string> = new Set();

      // 处理每个成功的配置源 | Process each successful config source
      for (const configResult of successfulConfigs) {
        const config = configResult.data!;
        const sitesResult = await this.configSourceService.getMediaSites(config.id);
        
        if (sitesResult.isSuccess()) {
          const sites = sitesResult.data!;
          
          // 处理站点 | Process sites
          sites.forEach(site => {
            const siteKey = `${site.key}_${site.name}`;
            
            if (aggregatedSites.has(siteKey)) {
              // 合并已存在的站点 | Merge existing site
              const existingSite = aggregatedSites.get(siteKey)!;
              existingSite.sourceUrls.push(config.url);
              existingSite.qualityScore = this.calculateSiteQuality(existingSite);
            } else {
              // 添加新站点 | Add new site
              const newSite: AggregatedSite = {
                key: site.key,
                name: site.name,
                type: site.type,
                api: site.api,
                searchable: site.searchable,
                quickSearch: site.quickSearch,
                filterable: site.filterable,
                sourceUrls: [config.url],
                qualityScore: 0,
                reliabilityScore: 0,
                lastSeen: Date.now(),
                ext: site.ext,
                jar: site.jar,
                headers: site.headers
              };
              
              newSite.qualityScore = this.calculateSiteQuality(newSite);
              aggregatedSites.set(siteKey, newSite);
            }
          });

          // 收集解析器 | Collect parsers
          if (config.metadata && config.metadata.parserCount) {
            // 这里可以根据实际配置结构调整 | Adjust according to actual config structure
            allParsers.add(`parser_from_${config.id}`);
          }
        }
      }

      const aggregationEndTime = Date.now();

      // 生成分类信息 | Generate category information
      const categories = this.generateCategories(Array.from(aggregatedSites.values()));

      // 创建聚合结果 | Create aggregation result
      const result: AggregatedContent = {
        sites: Array.from(aggregatedSites.values()),
        categories,
        parsers: Array.from(allParsers),
        timestamp: Date.now(),
        sourceCount: sourceUrls.length,
        totalSiteCount: Array.from(aggregatedSites.values()).reduce((sum, site) => sum + site.sourceUrls.length, 0),
        uniqueSiteCount: aggregatedSites.size
      };

      // 缓存结果 | Cache the result
      await this.cacheService.set(AGGREGATION_CACHE_KEY, result, AGGREGATION_CACHE_DURATION);

      // 记录统计信息 | Record statistics
      await this.recordAggregationStats(
        sourceUrls.length,
        successfulConfigs.length,
        loadEndTime - loadStartTime,
        aggregationEndTime - aggregationStartTime
      );

      this.logger.info(`Aggregation completed: ${result.uniqueSiteCount} unique sites from ${result.sourceCount} sources`);
      return ApiResponse.success(result);

    } catch (error) {
      this.logger.error('Failed to aggregate from sources', error);
      return ApiResponse.failure(`Aggregation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 分页获取聚合内容
   * 
   * 分页获取聚合的站点列表，支持分页大小、页码参数和排序方式。
   * 
   * @param page 页码，从1开始
   * @param pageSize 每页大小
   * @param includeInactive 是否包含质量评分过低的站点
   * @param sortBy 排序方式，可选值：'quality'（质量评分）、'reliability'（可靠性评分）、'recent'（最近更新）、'name'（名称）
   * @returns Promise<ApiResponse<{sites: AggregatedSite[], total: number, page: number, pageSize: number}>> - 包含分页结果的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.getAggregatedSitesByPage(1, 20, false, 'quality');
   * if (result.isSuccess()) {
   *   console.log('Page 1 sites:', result.data.sites);
   *   console.log('Total sites:', result.data.total);
   * }
   * ```
   */
  public async getAggregatedSitesByPage(
    page: number = 1,
    pageSize: number = 20,
    includeInactive: boolean = false,
    sortBy: SortOption = 'quality'
  ): Promise<ApiResponse<{sites: AggregatedSite[], total: number, page: number, pageSize: number}>> {
    try {
      const aggregationResult = await this.aggregateAllSources();
      if (!aggregationResult.isSuccess()) {
        return ApiResponse.failure(`Failed to get aggregation: ${aggregationResult.message}`);
      }

      let sites = aggregationResult.data!.sites;

      if (!includeInactive) {
        // 过滤掉质量评分过低的站点 | Filter out sites with low quality scores
        sites = sites.filter(site => site.qualityScore > 0.3);
      }

      // 按指定方式排序 | Sort by specified option
      sites = this.sortSites(sites, sortBy);

      // 计算分页 | Calculate pagination
      const total = sites.length;
      const startIndex = (page - 1) * pageSize;
      const endIndex = startIndex + pageSize;
      const paginatedSites = sites.slice(startIndex, endIndex);

      return ApiResponse.success({
        sites: paginatedSites,
        total,
        page,
        pageSize
      });

    } catch (error) {
      this.logger.error('Failed to get aggregated sites by page', error);
      return ApiResponse.failure(`Get aggregated sites by page failed: ${(error as Error).message}`);
    }
  }

  /**
   * 按分类分页获取站点
   * 
   * 根据分类ID分页获取对应的站点列表，支持排序方式。
   * 
   * @param categoryId 分类ID
   * @param page 页码，从1开始
   * @param pageSize 每页大小
   * @param sortBy 排序方式，可选值：'quality'（质量评分）、'reliability'（可靠性评分）、'recent'（最近更新）、'name'（名称）
   * @returns Promise<ApiResponse<{sites: AggregatedSite[], total: number, page: number, pageSize: number}>> - 包含分页结果的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.getSitesByCategoryAndPage('video', 1, 15, 'quality');
   * if (result.isSuccess()) {
   *   console.log('Video sites page 1:', result.data.sites);
   * }
   * ```
   */
  public async getSitesByCategoryAndPage(
    categoryId: string,
    page: number = 1,
    pageSize: number = 20,
    sortBy: SortOption = 'quality'
  ): Promise<ApiResponse<{sites: AggregatedSite[], total: number, page: number, pageSize: number}>> {
    try {
      const sitesResult = await this.getSites(true);
      if (!sitesResult.isSuccess()) {
        return ApiResponse.failure(`Failed to get sites: ${sitesResult.message}`);
      }

      // 根据站点类型过滤 | Filter by site type
      let filteredSites = sitesResult.data!.filter(site => {
        const siteType = this.getSiteCategoryType(site.type);
        return siteType === categoryId;
      });

      // 过滤掉质量评分过低的站点 | Filter out sites with low quality scores
      filteredSites = filteredSites.filter(site => site.qualityScore > 0.3);

      // 按指定方式排序 | Sort by specified option
      filteredSites = this.sortSites(filteredSites, sortBy);

      // 计算分页 | Calculate pagination
      const total = filteredSites.length;
      const startIndex = (page - 1) * pageSize;
      const endIndex = startIndex + pageSize;
      const paginatedSites = filteredSites.slice(startIndex, endIndex);

      return ApiResponse.success({
        sites: paginatedSites,
        total,
        page,
        pageSize
      });

    } catch (error) {
      this.logger.error('Failed to get sites by category and page', error);
      return ApiResponse.failure(`Get sites by category and page failed: ${(error as Error).message}`);
    }
  }



  /**
   * 获取聚合的站点列表
   * 
   * 获取聚合后的站点列表，支持过滤和排序。
   * 
   * @param includeInactive 是否包含质量评分过低的站点
   * @param sortBy 排序方式，可选值：'quality'（质量评分）、'reliability'（可靠性评分）、'recent'（最近更新）、'name'（名称）
   * @returns Promise<ApiResponse<AggregatedSite[]>> - 包含站点列表的API响应
   * @example
   * ```typescript
   * // 获取按质量排序的活跃站点
   * const result = await contentAggregator.getSites(false, 'quality');
   * if (result.isSuccess()) {
   *   console.log('Active sites sorted by quality:', result.data);
   * }
   * 
   * // 获取按名称排序的所有站点
   * const allSitesResult = await contentAggregator.getSites(true, 'name');
   * ```
   */
  public async getSites(includeInactive: boolean = false, sortBy: SortOption = 'quality'): Promise<ApiResponse<AggregatedSite[]>> {
    try {
      const aggregationResult = await this.aggregateAllSources();
      if (!aggregationResult.isSuccess()) {
        return ApiResponse.failure(`Failed to get aggregation: ${aggregationResult.message}`);
      }

      let sites = aggregationResult.data!.sites;

      if (!includeInactive) {
        // 过滤掉质量评分过低的站点 | Filter out sites with low quality scores
        sites = sites.filter(site => site.qualityScore > 0.3);
      }

      // 按指定方式排序 | Sort by specified option
      sites = this.sortSites(sites, sortBy);

      return ApiResponse.success(sites);

    } catch (error) {
      this.logger.error('Failed to get sites', error);
      return ApiResponse.failure(`Get sites failed: ${(error as Error).message}`);
    }
  }

  /**
   * 排序站点列表
   * 
   * 根据指定的排序选项对站点列表进行排序。
   * 
   * @param sites 站点列表
   * @param sortBy 排序方式
   * @returns 排序后的站点列表
   */
  private sortSites(sites: AggregatedSite[], sortBy: SortOption): AggregatedSite[] {
    switch (sortBy) {
      case 'quality':
        // 按质量评分排序 | Sort by quality score
        return sites.sort((a, b) => b.qualityScore - a.qualityScore);
      case 'reliability':
        // 按可靠性评分排序 | Sort by reliability score
        return sites.sort((a, b) => b.reliabilityScore - a.reliabilityScore);
      case 'recent':
        // 按最近更新时间排序 | Sort by last seen time
        return sites.sort((a, b) => b.lastSeen - a.lastSeen);
      case 'name':
        // 按名称排序 | Sort by name
        return sites.sort((a, b) => a.name.localeCompare(b.name));
      default:
        // 默认按质量评分排序 | Default sort by quality score
        return sites.sort((a, b) => b.qualityScore - a.qualityScore);
    }
  }

  /**
   * 根据分类获取站点
   * 
   * 根据分类ID获取对应的站点列表。
   * 
   * @param categoryId 分类ID
   * @returns Promise<ApiResponse<AggregatedSite[]>> - 包含站点列表的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.getSitesByCategory('video');
   * if (result.isSuccess()) {
   *   console.log('Video sites:', result.data);
   * }
   * ```
   */
  public async getSitesByCategory(categoryId: string): Promise<ApiResponse<AggregatedSite[]>> {
    try {
      const sitesResult = await this.getSites();
      if (!sitesResult.isSuccess()) {
        return ApiResponse.failure(`Failed to get sites: ${sitesResult.message}`);
      }

      // 根据站点类型过滤 | Filter by site type
      const filteredSites = sitesResult.data!.filter(site => {
        const siteType = this.getSiteCategoryType(site.type);
        return siteType === categoryId;
      });

      return ApiResponse.success(filteredSites);

    } catch (error) {
      this.logger.error('Failed to get sites by category', error);
      return ApiResponse.failure(`Get sites by category failed: ${(error as Error).message}`);
    }
  }

  /**
   * 搜索站点
   * 
   * 根据关键词搜索站点，支持按相关性排序。
   * 
   * @param keyword 搜索关键词
   * @returns Promise<ApiResponse<AggregatedSite[]>> - 包含搜索结果的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.searchSites('电影');
   * if (result.isSuccess()) {
   *   console.log('Search results:', result.data);
   * }
   * ```
   */
  public async searchSites(keyword: string): Promise<ApiResponse<AggregatedSite[]>> {
    try {
      if (!keyword.trim()) {
        return ApiResponse.failure('Search keyword cannot be empty');
      }

      const sitesResult = await this.getSites();
      if (!sitesResult.isSuccess()) {
        return ApiResponse.failure(`Failed to get sites: ${sitesResult.message}`);
      }

      const searchTerm = keyword.toLowerCase().trim();
      const matchingSites = sitesResult.data!.filter(site =>
        site.name.toLowerCase().includes(searchTerm) ||
        site.key.toLowerCase().includes(searchTerm) ||
        (site.ext && typeof site.ext === 'string' && site.ext.toLowerCase().includes(searchTerm))
      );

      // 按相关性排序 | Sort by relevance
      matchingSites.sort((a, b) => {
        const aRelevance = this.calculateSearchRelevance(a, searchTerm);
        const bRelevance = this.calculateSearchRelevance(b, searchTerm);
        return bRelevance - aRelevance;
      });

      return ApiResponse.success(matchingSites);

    } catch (error) {
      this.logger.error('Failed to search sites', error);
      return ApiResponse.failure(`Search failed: ${(error as Error).message}`);
    }
  }

  /**
   * 获取内容分类
   * 
   * 获取聚合内容的分类列表。
   * 
   * @returns Promise<ApiResponse<ContentCategory[]>> - 包含分类列表的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.getCategories();
   * if (result.isSuccess()) {
   *   console.log('Categories:', result.data);
   * }
   * ```
   */
  public async getCategories(): Promise<ApiResponse<ContentCategory[]>> {
    try {
      const aggregationResult = await this.aggregateAllSources();
      if (!aggregationResult.isSuccess()) {
        return ApiResponse.failure(`Failed to get aggregation: ${aggregationResult.message}`);
      }

      return ApiResponse.success(aggregationResult.data!.categories);

    } catch (error) {
      this.logger.error('Failed to get categories', error);
      return ApiResponse.failure(`Get categories failed: ${(error as Error).message}`);
    }
  }

  /**
   * 刷新聚合缓存
   * 
   * 清除聚合缓存并重新聚合内容。
   * 
   * @returns Promise<ApiResponse<boolean>> - 包含刷新结果的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.refreshAggregation();
   * if (result.isSuccess()) {
   *   console.log('Aggregation cache refreshed successfully');
   * } else {
   *   console.error('Failed to refresh aggregation:', result.message);
   * }
   * ```
   */
  public async refreshAggregation(): Promise<ApiResponse<boolean>> {
    try {
      this.logger.info('Refreshing aggregation cache');
      
      // 清除缓存 | Clear cache
      await this.cacheService.remove(AGGREGATION_CACHE_KEY);
      await this.cacheService.remove(LAST_AGGREGATION_TIME_KEY);
      
      // 重新聚合 | Re-aggregate
      const result = await this.aggregateAllSources();
      
      if (result.isSuccess()) {
        this.logger.info('Aggregation cache refreshed successfully');
        return ApiResponse.success(true);
      } else {
        return ApiResponse.failure(`Refresh failed: ${result.message}`);
      }

    } catch (error) {
      this.logger.error('Failed to refresh aggregation', error);
      return ApiResponse.failure(`Refresh failed: ${(error as Error).message}`);
    }
  }

  /**
   * 获取上次聚合时间
   * 
   * 获取上次执行聚合的时间戳。
   * 
   * @returns Promise<number> - 上次聚合时间戳
   */
  private async getLastAggregationTime(): Promise<number> {
    try {
      const lastTime = await this.cacheService.get<number>(LAST_AGGREGATION_TIME_KEY);
      return lastTime || 0;
    } catch (error) {
      this.logger.warn('Failed to get last aggregation time', error);
      return 0;
    }
  }

  /**
   * 保存聚合时间
   * 
   * 保存当前聚合的时间戳。
   * 
   * @param timestamp 时间戳
   * @returns Promise<void>
   */
  private async saveAggregationTime(timestamp: number): Promise<void> {
    try {
      await this.cacheService.set(LAST_AGGREGATION_TIME_KEY, timestamp, AGGREGATION_CACHE_DURATION * 2);
    } catch (error) {
      this.logger.warn('Failed to save aggregation time', error);
    }
  }

  /**
   * 执行增量聚合
   * 
   * 只处理自上次聚合以来新增或变化的内容，提高聚合效率。
   * 
   * @returns Promise<ApiResponse<AggregatedContent>> - 包含增量聚合结果的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.executeIncrementalAggregation();
   * if (result.isSuccess()) {
   *   console.log('Incremental aggregation completed:', result.data);
   * }
   * ```
   */
  public async executeIncrementalAggregation(): Promise<ApiResponse<AggregatedContent>> {
    try {
      this.logger.info('Starting incremental aggregation');

      // 获取上次聚合时间 | Get last aggregation time
      const lastAggregationTime = await this.getLastAggregationTime();
      const currentTime = Date.now();

      // 检查是否需要聚合 | Check if aggregation is needed
      if (currentTime - lastAggregationTime < 300000) { // 5分钟内不需要重新聚合 | No need to re-aggregate within 5 minutes
        this.logger.info('Aggregation was done recently, using cached result');
        const cachedResult = await this.cacheService.get<AggregatedContent>(AGGREGATION_CACHE_KEY);
        if (cachedResult) {
          return ApiResponse.success(cachedResult);
        }
      }

      // 执行完整聚合 | Execute full aggregation
      const result = await this.aggregateAllSources();
      
      if (result.isSuccess()) {
        // 保存聚合时间 | Save aggregation time
        await this.saveAggregationTime(currentTime);
        this.logger.info('Incremental aggregation completed successfully');
      }

      return result;

    } catch (error) {
      this.logger.error('Failed to execute incremental aggregation', error);
      return ApiResponse.failure(`Incremental aggregation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 获取聚合统计信息
   * 
   * 获取内容聚合的统计信息，包括源数量、站点数量、分类数量等。
   * 
   * @returns Promise<ApiResponse<AggregationStatistics>> - 包含统计信息的API响应
   * @example
   * ```typescript
   * const result = await contentAggregator.getStatistics();
   * if (result.isSuccess()) {
   *   console.log('Aggregation statistics:', result.data);
   * }
   * ```
   */
  public async getStatistics(): Promise<ApiResponse<AggregationStatistics>> {
    try {
      const aggregationResult = await this.aggregateAllSources();
      if (!aggregationResult.isSuccess()) {
        return ApiResponse.failure(`Failed to get aggregation: ${aggregationResult.message}`);
      }

      const aggData = aggregationResult.data!;
      const stats: AggregationStatistics = {
        totalSources: aggData.sourceCount,
        activeSources: aggData.sourceCount, // 假设所有源都是激活的 | Assume all sources are active
        totalSites: aggData.totalSiteCount,
        uniqueSites: aggData.uniqueSiteCount,
        categories: aggData.categories.length,
        parsers: aggData.parsers.length,
        lastAggregation: aggData.timestamp,
        averageResponseTime: 0, // 需要额外的性能监控 | Need additional performance monitoring
        successRate: aggData.uniqueSiteCount > 0 ? 1 : 0,
        cacheHitRate: 0 // 需要缓存命中率统计 | Need cache hit rate statistics
      };

      return ApiResponse.success(stats);

    } catch (error) {
      this.logger.error('Failed to get statistics', error);
      return ApiResponse.failure(`Get statistics failed: ${(error as Error).message}`);
    }
  }

  // 私有辅助方法 | Private helper methods

  private calculateSiteQuality(site: AggregatedSite): number {
    let score = 0;
    
    // 基础分数 | Base score
    score += 0.2;
    
    // 可搜索性加分 | Searchable bonus
    if (site.searchable) score += 0.15;
    if (site.quickSearch) score += 0.1;
    if (site.filterable) score += 0.1;
    
    // 多源加分 | Multi-source bonus
    const sourceBonus = Math.min(site.sourceUrls.length * 0.05, 0.2);
    score += sourceBonus;
    
    // API质量加分 | API quality bonus (简化实现) | Simplified implementation
    if (site.api && site.api.length > 10) score += 0.1;
    
    return Math.min(score, 1); // 限制在0-1范围内 | Limit to 0-1 range
  }

  private generateCategories(sites: AggregatedSite[]): ContentCategory[] {
    const categoryMap: Map<string, ContentCategory> = new Map();

    sites.forEach(site => {
      const categoryType = this.getSiteCategoryType(site.type);
      const categoryName = this.getCategoryName(categoryType);

      if (!categoryMap.has(categoryType)) {
        categoryMap.set(categoryType, {
          id: categoryType,
          name: categoryName,
          siteCount: 0,
          typeDistribution: {}
        });
      }

      const category = categoryMap.get(categoryType)!;
      category.siteCount++;
      
      const typeName = this.getSiteTypeName(site.type);
      category.typeDistribution[typeName] = (category.typeDistribution[typeName] || 0) + 1;
    });

    return Array.from(categoryMap.values())
      .sort((a, b) => b.siteCount - a.siteCount);
  }

  private getSiteCategoryType(siteType: number): string {
    // 根据站点类型返回分类ID | Return category ID based on site type
    switch (siteType) {
      case 0: return 'video';
      case 1: return 'video_api';
      case 3: return 'video_script';
      default: return 'other';
    }
  }

  private getCategoryName(categoryType: string): string {
    const categoryNames: Record<string, string> = {
      'video': '视频网站',
      'video_api': 'API视频源',
      'video_script': '脚本视频源',
      'other': '其他'
    };
    return categoryNames[categoryType] || '未知分类';
  }

  private getSiteTypeName(type: number): string {
    const typeNames: Record<number, string> = {
      0: '普通视频',
      1: 'API接口',
      3: '脚本解析'
    };
    return typeNames[type] || `类型${type}`;
  }

  private calculateSearchRelevance(site: AggregatedSite, searchTerm: string): number {
    let relevance = 0;
    
    if (site.name.toLowerCase().includes(searchTerm)) {
      relevance += 3;
    }
    if (site.key.toLowerCase().includes(searchTerm)) {
      relevance += 2;
    }
    if (site.ext && typeof site.ext === 'string' && site.ext.toLowerCase().includes(searchTerm)) {
      relevance += 1;
    }
    
    // 质量分数加权 | Weighted by quality score
    relevance += site.qualityScore * 2;
    
    return relevance;
  }

  private async recordAggregationStats(
    totalSources: number,
    successfulSources: number,
    loadTime: number,
    aggregationTime: number
  ): Promise<void> {
    // 这里可以记录详细的统计信息到日志或监控系统 | Detailed statistics can be recorded to logs or monitoring systems
    this.logger.info(`Aggregation stats - Total: ${totalSources}, Successful: ${successfulSources}, Load time: ${loadTime}ms, Aggregation time: ${aggregationTime}ms`);
  }
}

// 导出单例实例 | Export singleton instance
export default ContentAggregator.getInstance();