// CrawlerService.ets - 爬虫服务 Crawler service
// 管理多站点数据获取、解析和统一接口 Manage multi-site data acquisition, parsing and unified interfaces

import { Site, SiteInfo, SiteType, LoaderType, SiteSearchConfig, SiteFilterConfig, SitePerformanceConfig, SiteStats, SiteLifecycle } from '../../data/bean/Site';
import ConfigService from '../config/ConfigService';
import { HttpService, HttpResponse } from '../HttpService';
import StorageUtil from '../../common/util/StorageUtil';
import { ConfigParser } from '../config/ConfigParser';
import Logger from '../../common/util/Logger';
import { Inject } from '../../common/di/Container';
import { BaseLoader } from './loader/BaseLoader';

/**
 * 视频链接定义 Video link definition
 */
export interface VideoItem {
  id: string;
  title: string;
  cover?: string;
  url?: string;
  rating?: number;
  type?: string;
  updateInfo?: string;
  hot?: number;
  updateTime?: string;
}

/**
 * 脚本加载器接口定义 Script loader interface definition
 */
export interface ScriptLoader {
  loadScript: (scriptContent: string, options?: Record<string, string>) => Promise<object>;
  executeMethod: <T>(methodName: string, ...args: Array<string | number | boolean | object>) => Promise<T>;
  destroy: () => void;
}

// 视频详情接口定义 Video detail interface definition
export interface VideoDetail {
  id: string;
  title: string;
  cover?: string;
  description?: string;
  category?: string;
  tags?: string[];
  rating?: number;
  year?: string;
  region?: string;
  director?: string;
  actors?: string[];
  updateTime?: string;
  playSources?: PlaySourceInfo[];
  episodes?: EpisodeInfo[];
}

/**
 * 播放源信息接口
 */
export interface PlaySourceInfo {
  name: string;
  url: string;
}

/**
 * 剧集信息接口
 */
export interface EpisodeInfo {
  id: string;
  name: string;
}

/**
 * 性能统计接口
 */
export interface PerformanceStat {
  totalCalls: number;
  successfulCalls: number;
  failedCalls: number;
  totalTime: number;
  lastCallTime?: number;
}

/**
 * 性能统计结果接口
 */
export interface PerformanceStatsResult {
  totalCalls: number;
  successfulCalls: number;
  failedCalls: number;
  totalTime: number;
  averageTime: number;
  successRate: number;
  lastCallTime?: number;
}

/**
 * 站点爬虫实现类
 */
class SiteSpiderImpl implements SiteSpider {
  private config: SiteInfo;
  
  constructor(config: SiteInfo) {
    this.config = config;
  }
  
  async getSiteInfo(): Promise<SiteInfo> {
    return this.config;
  }
  
  async getRecommendList(): Promise<VideoItem[]> {
    return [];
  }
  
  async getHotList(): Promise<VideoItem[]> {
    return [];
  }
  
  async getLatestList(): Promise<VideoItem[]> {
    return [];
  }
  
  async getCategories(): Promise<string[]> {
    return [];
  }
  
  async getCategoryList(category: string, page: number): Promise<VideoItem[]> {
    return [];
  }
  
  async search(keyword: string, page?: number): Promise<VideoItem[]> {
    return [];
  }
  
  async getDetail(id: string): Promise<VideoDetail> {
    const detail: VideoDetail = {
      id,
      title: '',
      description: '',
      category: '',
      tags: [],
      rating: 0,
      year: '',
      region: '',
      director: '',
      actors: [],
      updateTime: '',
      playSources: [],
      episodes: []
    };
    return detail;
  }
  
  async getPlayUrl(id: string, episodeId?: string): Promise<string> {
    return '';
  }
}

/**
 * 爬虫服务接口定义 Crawler service interface definition
 */
export interface SiteSpider {
  // 获取站点信息 Get site information
  getSiteInfo(): Promise<SiteInfo>;
  
  // 获取推荐列表 Get recommended list
  getRecommendList(): Promise<VideoItem[]>;
  
  // 获取热门列表 Get hot list
  getHotList(): Promise<VideoItem[]>;
  
  // 获取最新更新 Get latest updates
  getLatestList(): Promise<VideoItem[]>;
  
  // 获取分类列表 Get category list
  getCategories(): Promise<string[]>;
  
  // 获取分类内容 Get category content
  getCategoryList(category: string, page: number): Promise<VideoItem[]>;
  
  // 搜索内容 Search content
  search(keyword: string, page?: number): Promise<VideoItem[]>;
  
  // 获取详情 Get details
  getDetail(id: string): Promise<VideoDetail>;
  
  // 获取播放链接 Get play URL
  getPlayUrl(id: string, episodeId?: string): Promise<string>;
  
  // 获取搜索建议（可选）Get search suggestions (optional)
  getSearchSuggestions?(keyword: string): Promise<string[]>;
}

/**
 * 调用站点方法选项接口 Call site method options interface
 */
export interface CallSiteMethodOptions {
  timeout?: number;
  retryCount?: number;
}

/**
 * 爬虫服务实现类 Crawler service implementation class
 * 管理所有站点爬虫，提供统一的数据获取接口 Manage all site crawlers, provide unified data acquisition interface
 */
export class CrawlerService {
  private static instance: CrawlerService;
  private siteSpiders: Map<string, SiteSpider> = new Map();
  private siteConfigs: Map<string, SiteInfo> = new Map();
  private initialized: boolean = false;
  private readonly TAG: string = 'CrawlerService';
  
  @Inject('ConfigService')
  private configService: ConfigService = ConfigService.getInstance();
  
  @Inject('HttpService')
  private httpService: HttpService = HttpService.getInstance();

  private configParser: ConfigParser = ConfigParser.getInstance();
  private scriptLoaders: Map<string, ScriptLoader> = new Map();
  
  private performanceStats: Map<string, PerformanceStat> = new Map();
  
  /**
   * 构造函数 Constructor
   */
  private constructor() {
    this.configParser = ConfigParser.getInstance();
  }
  
  /**
   * 获取单例实例 Get singleton instance
   */
  public static getInstance(): CrawlerService {
    if (!CrawlerService.instance) {
      CrawlerService.instance = new CrawlerService();
    }
    return CrawlerService.instance;
  }
  
  /**
   * 初始化爬虫服务 Initialize crawler service
   */
  public async initialize(): Promise<void> {
    if (this.initialized) return;
    
    try {
      Logger.info(this.TAG, '正在初始化爬虫服务... | Initializing crawler service...');
      // 加载存储的站点配置 Load stored site configurations
      await this.loadSiteConfigs();
      // 初始化默认站点 Initialize default sites
      await this.initDefaultSites();
      this.initialized = true;
      Logger.info(this.TAG, `爬虫服务已初始化，共${this.siteConfigs.size}个站点 | Crawler service initialized with ${this.siteConfigs.size} sites`);
    } catch (error) {
      Logger.error(this.TAG, '初始化爬虫服务失败: | Failed to initialize crawler service:', error instanceof Error ? error : new Error(String(error)));
      // 初始化失败时仍设置为已初始化，以保证应用继续运行
      // Set to initialized even if initialization fails to ensure app continues to run
      this.initialized = true;
    }
  }
  
  /**
   * 加载站点配置 Load site configurations
   */
  private async loadSiteConfigs(): Promise<void> {
    try {
      const configsJson: string = await StorageUtil.getString('sites_config', '');
      const configs: SiteInfo[] = configsJson ? JSON.parse(configsJson) as SiteInfo[] : [];
      if (configs && Array.isArray(configs)) {
        for (const config of configs as SiteInfo[]) {
          if (this.validateSiteConfig(config)) {
            this.siteConfigs.set(config.key, config);
          } else {
            Logger.warn(this.TAG, `无效的站点配置: ${config.key} | Invalid site config: ${config.key}`);
          }
        }
      }
    } catch (error) {
      Logger.error(this.TAG, '加载站点配置失败: | Failed to load site configs:', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  /**
   * 初始化默认站点 Initialize default sites
   */
  private async initDefaultSites(): Promise<void> {
    try {
      // 如果没有站点配置，添加默认的模拟站点
      // If no site configurations, add default mock sites
      if (this.siteConfigs.size === 0) {
        const defaultSites = await this.getDefaultSites();
        for (const site of defaultSites) {
          if (this.validateSiteConfig(site)) {
            this.siteConfigs.set(site.key, site);
            // 为每个默认站点创建对应的爬虫实例
            // Create corresponding crawler instance for each default site
            const spider = await this.createSpider(site.key, site);
            if (spider) {
              this.siteSpiders.set(site.key, spider);
            }
          }
        }
        
        // 保存默认站点配置 Save default site configurations
        await StorageUtil.putString('sites_config', JSON.stringify(Array.from(this.siteConfigs.values())));
      } else {
        // 为已有的站点配置创建爬虫实例
        // Create crawler instances for existing site configurations
        const entries = this.siteConfigs.entries();
        for (const entry of entries) {
          const key: string = entry[0];
          const config: SiteInfo = entry[1];
          if (!this.siteSpiders.has(key)) {
            const spider: SiteSpider | null = await this.createSpider(key, config);
            if (spider) {
              this.siteSpiders.set(key, spider);
            }
          }
        }
      }
    } catch (error) {
      Logger.error(this.TAG, '初始化默认站点失败: | Failed to init default sites:', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  /**
   * 验证站点配置 Validate site configuration
   */
  private validateSiteConfig(config: Site): boolean {
    try {
      // 验证必填字段 Validate required fields
      if (!config.key || !config.name || !config.type || !config.api) {
        Logger.error(this.TAG, '站点配置缺少必填字段 | Site config missing required fields');
        return false;
      }
      
      // 验证站点类型 Validate site type
      const validTypes = ['vod', 'live'];
      if (!validTypes.includes(config.type)) {
        Logger.error(this.TAG, `无效的站点类型: ${config.type} | Invalid site type: ${config.type}`);
        return false;
      }
      
      // 验证URL格式 Validate URL format
      if (!config.api.startsWith('http://') && !config.api.startsWith('https://')) {
        Logger.error(this.TAG, `无效的URL格式: ${config.api} | Invalid URL format: ${config.api}`);
        return false;
      }
      
      return true;
    } catch (error) {
      Logger.error(this.TAG, '验证站点配置失败: | Failed to validate site config:', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 创建爬虫实例 Create crawler instance
   */
  private async createSpider(key: string, config: SiteInfo): Promise<SiteSpider | null> {
    try {
      // 根据站点类型和配置创建对应的爬虫实例
      // Create corresponding crawler instance based on site type and configuration
      Logger.info(this.TAG, `正在为站点创建爬虫: ${key} | Creating spider for site: ${key}`);
      
      // 使用 LoaderFactory 创建加载器 Use LoaderFactory to create loader
      const loaderFactory = await import('./LoaderFactory');
      const factory = loaderFactory.LoaderFactory.getInstance();
      const loader: BaseLoader = factory.createLoader(config);
      
      // 使用加载器创建爬虫实例 Use loader to create crawler instance
      return await loader.createSpider();
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `为站点${key}创建爬虫失败： | Failed to create spider for site ${key}:`, err);
      return null;
    }
  }
  
  /**
   * 创建基础爬虫实例 Create base crawler instance
   */
  private createBaseSpider(config: SiteInfo): SiteSpider {
    // 实现基础的爬虫骨架，支持 HTTP 请求和简单的解析
    // Implement basic crawler skeleton, support HTTP requests and simple parsing
    return new SiteSpiderImpl(config);
  }
  
  /**
   * 获取默认站点配置 Get default site configurations
   */
  private async getDefaultSites(): Promise<SiteInfo[]> {
    try {
      const httpService: HttpService = HttpService.getInstance();
      const response: HttpResponse<SiteInfo[]> = await httpService.request<SiteInfo[]>('https://api.raytv.com/config/sites/default', {
        method: 'GET',
        timeout: 10000
      });
      
      if (response.status >= 200 && response.status < 300 && Array.isArray(response.data)) {
        const result: SiteInfo[] = [];
        const dataSites: SiteInfo[] = response.data as SiteInfo[];
        for (const site of dataSites) {
          const siteInfo: SiteInfo = {
            key: site.key,
            name: site.name,
            type: site.type,
            loaderType: site.loaderType,
            api: site.api,
            logo: site.logo,
            description: site.description,
            siteAuth: site.siteAuth,
            headers: site.headers,
            config: site.config,
            configItems: site.configItems,
            searchConfig: site.searchConfig,
            filterConfig: site.filterConfig,
            performanceConfig: site.performanceConfig,
            version: site.version,
            stats: site.stats,
            lifecycle: site.lifecycle,
            enabled: site.enabled !== false,
            order: site.order || 0,
            group: site.group,
            tags: site.tags,
            customCode: site.customCode,
            sandboxEnabled: site.sandboxEnabled,
            allowThirdParty: site.allowThirdParty,
            createdAt: site.createdAt || Date.now(),
            updatedAt: site.updatedAt || Date.now(),
            lastUsedAt: site.lastUsedAt,
            userAgent: site.userAgent || '',
            referer: site.referer,
            proxy: site.proxy,
            encoding: site.encoding,
            charset: site.charset,
            certificate: site.certificate
          };
          result.push(siteInfo);
        }
        return result;
      }
      
      // 如果API调用失败，返回空数组 | Return empty array if API call fails
      return [];
    } catch (error) {
      Logger.error(this.TAG, '从API获取默认站点失败: | Failed to get default sites from API:', error instanceof Error ? error : new Error(String(error)));
      // API调用失败时返回空数组，避免使用硬编码数据 | Return empty array when API call fails, avoid using hardcoded data
      return [];
    }
  }
  
  /**
   * 获取所有站点 Get all sites
   */
  public async getAllSites(): Promise<SiteInfo[]> {
    await this.initialize();
    const sites: SiteInfo[] = [];
    
    const entries = this.siteConfigs.entries();
    for (const entry of entries) {
      const key: string = entry[0];
      const config: SiteInfo = entry[1];
      sites.push(config);
    }
    
    return sites.sort((a: SiteInfo, b: SiteInfo): number => {
      // 按启用状态和名称排序 Sort by enabled status and name
      if (a.enabled !== b.enabled) {
        return a.enabled ? -1 : 1;
      }
      return a.name.localeCompare(b.name);
    });
  }
  
  /**
   * 获取已启用的站点 Get active sites
   */
  public async getActiveSites(): Promise<SiteInfo[]> {
    await this.initialize();
    const sites: SiteInfo[] = [];
    
    const entries = this.siteConfigs.entries();
    for (const entry of entries) {
      const key: string = entry[0];
      const config: SiteInfo = entry[1];
      if (config.enabled) {
        sites.push(config);
      }
    }
    
    return sites.sort((a: SiteInfo, b: SiteInfo): number => a.name.localeCompare(b.name));
  }
  
  /**
   * 设置站点状态 Set site status
   */
  public async setSiteStatus(siteKey: string, enabled: boolean): Promise<void> {
    await this.initialize();
    
    const config: SiteInfo | undefined = this.siteConfigs.get(siteKey);
    if (config) {
      config.enabled = enabled;
      this.siteConfigs.set(siteKey, config);
      
      // 保存更新后的配置 Save updated configuration
      const allSites = await this.getAllSites();
      await StorageUtil.putString('sites_config', JSON.stringify(allSites));
    }
  }
  
  /**
   * 导入站点配置 Import site configuration
   */
  public async importSiteConfig(configStr: string): Promise<SiteInfo | null> {
    await this.initialize();
    
    try {
      // 使用 ConfigParser 解析站点配置 Use ConfigParser to parse site configuration
      const sites: Site[] = this.configParser.parseSites(configStr);
      const siteConfig: Site | undefined = sites.length > 0 ? sites[0] : undefined;

      if (siteConfig && siteConfig.key) {
        // 验证站点配置 Validate site configuration
        if (!this.validateSiteConfig(siteConfig)) {
          throw new Error('Invalid site configuration');
        }

        // 检查是否已存在同名站点 Check if site with same name already exists
        if (this.siteConfigs.has(siteConfig.key)) {
          // 更新现有站点 Update existing site
          const existingConfig: Site | undefined = this.siteConfigs.get(siteConfig.key);
          if (existingConfig) {
            siteConfig.enabled = existingConfig.enabled;
          }
        }

        // 保存站点配置 Save site configuration
        this.siteConfigs.set(siteConfig.key, siteConfig);

        // 创建爬虫实例 Create crawler instance
        const spider = await this.createSpider(siteConfig.key, siteConfig);
        if (spider) {
          this.siteSpiders.set(siteConfig.key, spider);
        }

        // 保存到存储 Save to storage
        const allSites = await this.getAllSites();
        await StorageUtil.putString('sites_config', JSON.stringify(allSites));

        return siteConfig;
      }

      return null;
    } catch (error) {
      Logger.error(this.TAG, '导入站点配置失败: | Failed to import site config:', error instanceof Error ? error : new Error(String(error)));
      throw new Error('导入站点配置失败');
    }
  }
  
  /**
   * 删除站点 Remove site
   */
  public async removeSite(siteKey: string): Promise<void> {
    await this.initialize();
    
    if (this.siteConfigs.has(siteKey)) {
      this.siteConfigs.delete(siteKey);
      this.siteSpiders.delete(siteKey);
      this.performanceStats.delete(siteKey);
      
      // 更新存储 Update storage
      const allSites = await this.getAllSites();
      await StorageUtil.putString('sites_config', JSON.stringify(allSites));
    }
  }
  
  /**
   * 调用站点方法 Call site method
   */
  public async callSiteMethod<T>(
    siteKey: string,
    methodName: string,
    args: Array<string | number | boolean | object> = [],
    options: CallSiteMethodOptions = { timeout: 30000 }
  ): Promise<T> {
    await this.initialize();
    
    const spider = this.siteSpiders.get(siteKey);
    if (!spider) {
      Logger.error(this.TAG, `未找到站点的爬虫: ${siteKey} | No spider found for site: ${siteKey}`);
      // 返回空数据 Return empty data
      return this.getDefaultEmptyData<T>(methodName);
    }
    
    // 记录性能统计 Record performance statistics
    const startTime = Date.now();
    let result: T = this.getDefaultEmptyData<T>(methodName);
    
    try {
      result = await this.callSpiderMethod<T>(spider, methodName as keyof SiteSpider, args, options);
      this.updatePerformanceStats(siteKey, true, Date.now() - startTime);
    } catch (error) {
      this.updatePerformanceStats(siteKey, false, Date.now() - startTime);
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
    
    return result;
  }
  
  /**
   * 调用爬虫实例方法 Call spider instance method
   */
  private async callSpiderMethod<T>(
    spider: SiteSpider,
    methodName: keyof SiteSpider,
    args: Array<string | number | boolean | object>,
    options: CallSiteMethodOptions
  ): Promise<T> {
    try {
      // 使用类型守卫检查方法是否存在 Use type guard to check if method exists
      let result: T = this.getDefaultEmptyData<T>(String(methodName));
      
      // 根据方法名调用对应的方法 Call corresponding method based on method name
      switch (methodName) {
        case 'getSiteInfo':
          result = await spider.getSiteInfo() as T;
          break;
        case 'getRecommendList':
          result = await spider.getRecommendList() as T;
          break;
        case 'getHotList':
          result = await spider.getHotList() as T;
          break;
        case 'getLatestList':
          result = await spider.getLatestList() as T;
          break;
        case 'getCategories':
          result = await spider.getCategories() as T;
          break;
        case 'getCategoryList':
          result = await spider.getCategoryList(args[0] as string, args[1] as number) as T;
          break;
        case 'search':
          result = await spider.search(args[0] as string, args[1] as number | undefined) as T;
          break;
        case 'getDetail':
          result = await spider.getDetail(args[0] as string) as T;
          break;
        case 'getPlayUrl':
          result = await spider.getPlayUrl(args[0] as string, args[1] as string | undefined) as T;
          break;
        case 'getSearchSuggestions':
          if (typeof spider.getSearchSuggestions === 'function') {
            result = await spider.getSearchSuggestions(args[0] as string) as T;
          } else {
            throw new Error(`Method ${String(methodName)} not implemented`);
          }
          break;
        default:
          throw new Error(`Method ${String(methodName)} not supported`);
      }
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `调用爬虫的${String(methodName)}方法失败: | Failed to call ${String(methodName)} on spider:`, error instanceof Error ? error : new Error(String(error)));
      // 返回空数据 Return empty data
      return this.getDefaultEmptyData<T>(String(methodName));
    }
  }
  
  /**
   * 根据方法名返回默认空数据 Return default empty data based on method name
   */
  private getDefaultEmptyData<T>(methodName: string): T {
    Logger.warn(this.TAG, `为方法${methodName}返回默认空数据 | Returning default empty data for method: ${methodName}`);
    
    // 根据不同方法返回对应的空数据类型
    // Return corresponding empty data type based on different methods
    switch (methodName) {
      case 'getRecommendList':
      case 'getHotList':
      case 'getLatestList':
      case 'getCategoryList':
      case 'search':
      case 'getSearchSuggestions':
      case 'getCategories':
        return [] as T;
      case 'getDetail':
        const detail: VideoDetail = {
          id: '',
          title: '未知标题',
          cover: '',
          description: '暂无描述',
          playSources: [],
          episodes: []
        };
        return detail as T;
      case 'getPlayUrl':
        return '' as T;
      case 'getSiteInfo':
        const searchConfig: SiteSearchConfig = {
          enabled: true
        };
        const filterConfig: SiteFilterConfig = {
          enabled: false
        };
        const performanceConfig: SitePerformanceConfig = {
          timeout: 10000,
          retryCount: 3
        };
        const stats: SiteStats = {
          queryCount: 0,
          errorCount: 0,
          avgResponseTime: 0
        };
        const lifecycle: SiteLifecycle = {
          initialized: false,
          loading: false,
          error: false
        };
        const siteInfo: Site = {
          key: '',
          name: '',
          type: SiteType.VOD,
          loaderType: LoaderType.JS,
          api: '',
          searchConfig,
          filterConfig,
          performanceConfig,
          stats,
          lifecycle,
          enabled: false,
          order: 0,
          createdAt: Date.now(),
          updatedAt: Date.now()
        };
        return siteInfo as T;
      default:
        const empty: Record<string, string> = {};
        return empty as T;
    }
  }
  
  /**
   * 更新性能统计 Update performance statistics
   */
  private updatePerformanceStats(siteKey: string, success: boolean, duration: number): void {
    const stats = this.performanceStats.get(siteKey) || {
      totalCalls: 0,
      successfulCalls: 0,
      failedCalls: 0,
      totalTime: 0
    };
    
    stats.totalCalls++;
    if (success) {
      stats.successfulCalls++;
    } else {
      stats.failedCalls++;
    }
    stats.totalTime += duration;
    stats.lastCallTime = Date.now();
    
    this.performanceStats.set(siteKey, stats);
    
    Logger.debug(this.TAG, `站点${siteKey}性能数据: ${JSON.stringify(stats)} | Site ${siteKey} performance: ${JSON.stringify(stats)}`);
  }
  
  /**
   * 获取站点性能统计 Get site performance statistics
   */
  public getPerformanceStats(siteKey: string): PerformanceStatsResult | null {
    const stats = this.performanceStats.get(siteKey);
    if (!stats) {
      return null;
    }
    
    const result: PerformanceStatsResult = {
      totalCalls: stats.totalCalls,
      successfulCalls: stats.successfulCalls,
      failedCalls: stats.failedCalls,
      totalTime: stats.totalTime,
      lastCallTime: stats.lastCallTime,
      averageTime: stats.totalCalls > 0 ? stats.totalTime / stats.totalCalls : 0,
      successRate: stats.totalCalls > 0 ? stats.successfulCalls / stats.totalCalls : 0
    };
    return result;
  }
  
  /**
   * 获取所有站点性能统计 Get all sites performance statistics
   */
  public getAllPerformanceStats(): Map<string, PerformanceStatsResult> {
    const result = new Map<string, PerformanceStatsResult>();
    this.performanceStats.forEach((stats: PerformanceStat, siteKey: string) => {
      const resultStats: PerformanceStatsResult = {
        totalCalls: stats.totalCalls,
        successfulCalls: stats.successfulCalls,
        failedCalls: stats.failedCalls,
        totalTime: stats.totalTime,
        averageTime: stats.totalCalls > 0 ? stats.totalTime / stats.totalCalls : 0,
        successRate: stats.totalCalls > 0 ? stats.successfulCalls / stats.totalCalls : 0,
        lastCallTime: stats.lastCallTime
      };
      result.set(siteKey, resultStats);
    });
    return result;
  }
  
  /**
   * 清除性能统计 Clear performance statistics
   */
  public clearPerformanceStats(siteKey?: string): void {
    if (siteKey) {
      this.performanceStats.delete(siteKey);
    } else {
      this.performanceStats.clear();
    }
  }
}

// 导出一些额外的类型和工具函数 Export some additional types and utility functions
export interface CrawlerOptions {
  timeout?: number;
  retryCount?: number;
  userAgent?: string;
}

export class CrawlerError extends Error {
  public code?: string;
  
  constructor(message: string, code?: string) {
    super(message);
    this.name = 'CrawlerError';
    this.code = code;
  }
}
