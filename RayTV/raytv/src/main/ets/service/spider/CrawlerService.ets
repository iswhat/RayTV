// CrawlerService.ets - 爬虫服务 Crawler service
// 管理多站点数据获取、解析和统一接口 Manage multi-site data acquisition, parsing and unified interfaces

import { Site, SiteInfo } from '../../data/bean/Site';
import { ConfigService } from '../config/ConfigService';
import { HttpService } from '../HttpService';
import { StorageUtil } from '../../common/util/StorageUtil';
import { ConfigParser } from '../config/ConfigParser';
import Logger from '../../common/util/Logger';

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
  playSources?: Array<{ name: string; url: string }>;
  episodes?: Array<{ id: string; name: string }>;
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
  
  private configService: ConfigService;
  private httpService: HttpService;
  private storageUtil: StorageUtil;
  private configParser: ConfigParser;
  private scriptLoaders: Map<string, ScriptLoader> = new Map();
  private performanceStats: Map<string, {
    totalCalls: number;
    successfulCalls: number;
    failedCalls: number;
    totalTime: number;
    lastCallTime?: number;
  }> = new Map();
  
  /**
   * 构造函数 Constructor
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.httpService = HttpService.getInstance();
    this.storageUtil = StorageUtil.getInstance();
    this.configParser = new ConfigParser();
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
      const configs = await this.storageUtil.getSitesConfig();
      if (configs && Array.isArray(configs)) {
        for (const config of configs) {
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
        await this.storageUtil.saveSitesConfig(Array.from(this.siteConfigs.values()));
      } else {
        // 为已有的站点配置创建爬虫实例
        // Create crawler instances for existing site configurations
        for (const [key, config] of this.siteConfigs.entries()) {
          if (!this.siteSpiders.has(key)) {
            const spider = await this.createSpider(key, config);
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
      if (!config.key || !config.name || !config.type || !config.url) {
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
      if (!config.url.startsWith('http://') && !config.url.startsWith('https://')) {
        Logger.error(this.TAG, `无效的URL格式: ${config.url} | Invalid URL format: ${config.url}`);
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
      
      // 使用LoaderFactory创建加载器 Use LoaderFactory to create loader
      const loaderFactory = await import('./LoaderFactory');
      const factory = loaderFactory.LoaderFactory.getInstance();
      const loader = factory.createLoader(config);
      
      // 使用加载器创建爬虫实例 Use loader to create crawler instance
      return await loader.createSpider();
    } catch (error) {
      Logger.error(this.TAG, `为站点${key}创建爬虫失败: | Failed to create spider for site ${key}:`, error instanceof Error ? error : new Error(String(error)));
      return null;
    }
  }
  
  /**
   * 创建基础爬虫实例 Create base crawler instance
   */
  private createBaseSpider(config: SiteInfo): SiteSpider {
    // 实现基础的爬虫骨架，支持HTTP请求和简单的解析
    // Implement basic crawler skeleton, support HTTP requests and simple parsing
    return {
      getSiteInfo: async () => config,
      
      getRecommendList: async () => {
        // 这里应该从站点API获取推荐列表
        // Here should get recommended list from site API
        // 暂时返回空数组，后续实现实际的API调用
        // Temporarily return empty array, implement actual API call later
        return [];
      },
      
      getHotList: async () => {
        // 这里应该从站点API获取热门列表
        // Here should get hot list from site API
        return [];
      },
      
      getLatestList: async () => {
        // 这里应该从站点API获取最新更新列表
        // Here should get latest updates list from site API
        return [];
      },
      
      getCategories: async () => {
        // 这里应该从站点API获取分类列表
        // Here should get categories list from site API
        return [];
      },
      
      getCategoryList: async (category: string, page: number) => {
        // 这里应该从站点API获取分类内容
        // Here should get category content from site API
        return [];
      },
      
      search: async (keyword: string, page?: number) => {
        // 这里应该从站点API搜索内容
        // Here should search content from site API
        return [];
      },
      
      getDetail: async (id: string) => {
        // 这里应该从站点API获取详情
        // Here should get details from site API
        return {
          id,
          title: '未知标题',
          cover: '',
          description: '暂无描述',
          playSources: [],
          episodes: []
        };
      },
      
      getPlayUrl: async (id: string, episodeId?: string) => {
        // 这里应该从站点API获取播放链接
        // Here should get play URL from site API
        return '';
      },
      
      getSearchSuggestions: async (keyword: string) => {
        // 这里应该从站点API获取搜索建议
        // Here should get search suggestions from site API
        return [];
      }
    };
  }
  
  /**
   * 获取默认站点配置 Get default site configurations
   */
  private async getDefaultSites(): Promise<SiteInfo[]> {
    // 从真实API获取默认站点配置 | Get default site configurations from real API
    try {
      const httpService = HttpService.getInstance();
      const response = await httpService.request<SiteInfo[]>('https://api.raytv.com/config/sites/default', {
        method: 'GET',
        timeout: 10000
      });
      
      if (response.status >= 200 && response.status < 300 && Array.isArray(response.data)) {
        return response.data.map((site: SiteInfo) => ({
          key: site.key,
          name: site.name,
          type: site.type,
          url: site.url,
          enabled: site.enabled !== false,
          updateTime: site.updateTime || new Date().toISOString(),
          version: site.version || '1.0.0',
          userAgent: site.userAgent || '',
          requestHeaders: site.requestHeaders || {},
          searchRule: site.searchRule || {},
          detailRule: site.detailRule || {},
          playRule: site.playRule || {}
        }));
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
    
    for (const [key, config] of this.siteConfigs.entries()) {
      sites.push(config);
    }
    
    return sites.sort((a, b) => {
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
    
    for (const [key, config] of this.siteConfigs.entries()) {
      if (config.enabled) {
        sites.push(config);
      }
    }
    
    return sites.sort((a, b) => a.name.localeCompare(b.name));
  }
  
  /**
   * 设置站点状态 Set site status
   */
  public async setSiteStatus(siteKey: string, enabled: boolean): Promise<void> {
    await this.initialize();
    
    const config = this.siteConfigs.get(siteKey);
    if (config) {
      config.enabled = enabled;
      this.siteConfigs.set(siteKey, config);
      
      // 保存更新后的配置 Save updated configuration
      const allSites = await this.getAllSites();
      await this.storageUtil.saveSitesConfig(allSites);
    }
  }
  
  /**
   * 导入站点配置 Import site configuration
   */
  public async importSiteConfig(configStr: string): Promise<SiteInfo | null> {
    await this.initialize();
    
    try {
      // 使用ConfigParser解析站点配置 Use ConfigParser to parse site configuration
      const siteConfig = this.configParser.parseSiteConfig(configStr);
      
      if (siteConfig && siteConfig.key) {
        // 验证站点配置 Validate site configuration
        if (!this.validateSiteConfig(siteConfig)) {
          throw new Error('Invalid site configuration');
        }
        
        // 检查是否已存在同名站点 Check if site with same name already exists
        if (this.siteConfigs.has(siteConfig.key)) {
          // 更新现有站点 Update existing site
          const existingConfig = this.siteConfigs.get(siteConfig.key);
          siteConfig.enabled = existingConfig.enabled;
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
        await this.storageUtil.saveSitesConfig(allSites);
        
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
      await this.storageUtil.saveSitesConfig(allSites);
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
      result = await this.callSpiderMethod<T>(spider, methodName, args, options);
      this.updatePerformanceStats(siteKey, true, Date.now() - startTime);
    } catch (error) {
      this.updatePerformanceStats(siteKey, false, Date.now() - startTime);
      throw error;
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
          result = await spider.getSiteInfo() as unknown as T;
          break;
        case 'getRecommendList':
          result = await spider.getRecommendList() as unknown as T;
          break;
        case 'getHotList':
          result = await spider.getHotList() as unknown as T;
          break;
        case 'getLatestList':
          result = await spider.getLatestList() as unknown as T;
          break;
        case 'getCategories':
          result = await spider.getCategories() as unknown as T;
          break;
        case 'getCategoryList':
          result = await spider.getCategoryList(args[0] as string, args[1] as number) as unknown as T;
          break;
        case 'search':
          result = await spider.search(args[0] as string, args[1] as number | undefined) as unknown as T;
          break;
        case 'getDetail':
          result = await spider.getDetail(args[0] as string) as unknown as T;
          break;
        case 'getPlayUrl':
          result = await spider.getPlayUrl(args[0] as string, args[1] as string | undefined) as unknown as T;
          break;
        case 'getSearchSuggestions':
          if (typeof spider.getSearchSuggestions === 'function') {
            result = await spider.getSearchSuggestions(args[0] as string) as unknown as T;
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
        return ([] as T);
      case 'getDetail':
        return ({ 
          id: '',
          title: '未知标题',
          cover: '',
          description: '暂无描述',
          playSources: [],
          episodes: []
        } as T);
      case 'getPlayUrl':
        return ('') as T;
      case 'getSiteInfo':
        return ({}) as T;
      default:
        return ({}) as T;
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
  public getPerformanceStats(siteKey: string): {
    totalCalls: number;
    successfulCalls: number;
    failedCalls: number;
    totalTime: number;
    averageTime: number;
    successRate: number;
    lastCallTime?: number;
  } | null {
    const stats = this.performanceStats.get(siteKey);
    if (!stats) {
      return null;
    }
    
    return {
      ...stats,
      averageTime: stats.totalCalls > 0 ? stats.totalTime / stats.totalCalls : 0,
      successRate: stats.totalCalls > 0 ? stats.successfulCalls / stats.totalCalls : 0
    };
  }
  
  /**
   * 获取所有站点性能统计 Get all sites performance statistics
   */
  public getAllPerformanceStats(): Map<string, {
    totalCalls: number;
    successfulCalls: number;
    failedCalls: number;
    totalTime: number;
    averageTime: number;
    successRate: number;
    lastCallTime?: number;
  }> {
    const result = new Map<string, {
      totalCalls: number;
      successfulCalls: number;
      failedCalls: number;
      totalTime: number;
      averageTime: number;
      successRate: number;
      lastCallTime?: number;
    }>();
    this.performanceStats.forEach((stats, siteKey) => {
      result.set(siteKey, {
        ...stats,
        averageTime: stats.totalCalls > 0 ? stats.totalTime / stats.totalCalls : 0,
        successRate: stats.totalCalls > 0 ? stats.successfulCalls / stats.totalCalls : 0
      });
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
  constructor(message: string, public code?: string) {
    super(message);
    this.name = 'CrawlerError';
  }
}
