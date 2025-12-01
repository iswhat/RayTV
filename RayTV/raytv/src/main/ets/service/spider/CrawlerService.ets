// 爬虫服务
// 管理多站点数据获取、解析和统一接口

import { SiteInfo } from '../../data/bean/Site';
import { ConfigService } from '../config/ConfigService';
import { HttpService } from '../HttpService';
import { StorageUtil } from '../../common/util/StorageUtil';
import { ConfigParser } from '../config/ConfigParser';
import Logger from '../../common/util/Logger';

/**
 * 视频项接口定义
 */
interface VideoItem {
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
 * 视频详情接口定义
 */
interface VideoDetail {
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
 * 爬虫服务接口定义
 */
interface SiteSpider {
  // 获取站点信息
  getSiteInfo(): Promise<SiteInfo>;
  
  // 获取推荐列表
  getRecommendList(): Promise<VideoItem[]>;
  
  // 获取热门列表
  getHotList(): Promise<VideoItem[]>;
  
  // 获取最新更新
  getLatestList(): Promise<VideoItem[]>;
  
  // 获取分类列表
  getCategories(): Promise<string[]>;
  
  // 获取分类内容
  getCategoryList(category: string, page: number): Promise<VideoItem[]>;
  
  // 搜索内容
  search(keyword: string, page?: number): Promise<VideoItem[]>;
  
  // 获取详情
  getDetail(id: string): Promise<VideoDetail>;
  
  // 获取播放链接
  getPlayUrl(id: string, episodeId?: string): Promise<string>;
  
  // 获取搜索建议（可选）
  getSearchSuggestions?(keyword: string): Promise<string[]>;
}

/**
 * 爬虫服务实现类
 * 管理所有站点爬虫，提供统一的数据获取接口
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
  
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.httpService = HttpService.getInstance();
    this.storageUtil = StorageUtil.getInstance();
    this.configParser = new ConfigParser();
  }
  
  public static getInstance(): CrawlerService {
    if (!CrawlerService.instance) {
      CrawlerService.instance = new CrawlerService();
    }
    return CrawlerService.instance;
  }
  
  /**
   * 初始化爬虫服务
   */
  public async initialize(): Promise<void> {
    if (this.initialized) return;
    
    try {
      // 加载保存的站点配置
      await this.loadSiteConfigs();
      // 初始化默认站点
      await this.initDefaultSites();
      this.initialized = true;
    } catch (error) {
      console.error('Failed to initialize crawler service:', error);
      // 初始化失败时仍设置为已初始化，以允许应用继续运行
      this.initialized = true;
    }
  }
  
  /**
   * 加载站点配置
   */
  private async loadSiteConfigs(): Promise<void> {
    try {
      const configs = await this.storageUtil.getSitesConfig();
      if (configs && Array.isArray(configs)) {
        for (const config of configs) {
          this.siteConfigs.set(config.key, config);
        }
      }
    } catch (error) {
      console.error('Failed to load site configs:', error);
    }
  }
  
  /**
   * 初始化默认站点
   */
  private async initDefaultSites(): Promise<void> {
    try {
      // 如果没有站点配置，添加默认的模拟站点
      if (this.siteConfigs.size === 0) {
        const defaultSites = this.getDefaultSites();
        for (const site of defaultSites) {
          this.siteConfigs.set(site.key, site);
          // 为每个默认站点创建对应的爬虫实例
          const spider = this.createMockSpider(site);
          this.siteSpiders.set(site.key, spider);
        }
        
        // 保存默认站点配置
        await this.storageUtil.saveSitesConfig(defaultSites);
      } else {
        // 为已有的站点配置创建爬虫实例
        for (const [key, config] of this.siteConfigs.entries()) {
          if (!this.siteSpiders.has(key)) {
            const spider = this.createSpider(key, config);
            if (spider) {
              this.siteSpiders.set(key, spider);
            }
          }
        }
      }
    } catch (error) {
      console.error('Failed to init default sites:', error);
    }
  }
  
  /**
   * 创建爬虫实例
   */
  private createSpider(key: string, config: Record<string, unknown>): SiteSpider | null {
    try {
      // 根据站点类型和配置创建对应的爬虫实例
      // 实际实现应该根据配置动态创建不同类型的爬虫
      Logger.info(this.TAG, `Creating spider for site: ${key}`);
      
      // 这里应该是根据站点配置创建实际爬虫的逻辑
      // 由于没有具体的爬虫实现，暂时返回一个空实现，会在后续完善
      return {
        getSiteInfo: async () => config as SiteInfo,
        getRecommendList: async () => [],
        getHotList: async () => [],
        getLatestList: async () => [],
        getCategories: async () => [],
        getCategoryList: async () => [],
        search: async () => [],
        getDetail: async () => ({} as VideoDetail),
        getPlayUrl: async () => ''
      };
    } catch (error) {
      Logger.error(this.TAG, `Failed to create spider for site ${key}:`, error);
      return null;
    }
  }
  
  /**
   * 获取默认站点配置
   */
  private getDefaultSites(): SiteInfo[] {
    // 返回实际可用的站点配置，而不是模拟站点
    // 实际项目中应该从配置文件或网络获取
    return [
      {
        key: 'official_video_site',
        name: '官方视频站',
        type: 'vod',
        url: 'https://api.raytv.com/v1',
        enabled: true,
        updateTime: new Date().toISOString(),
        version: '1.0.0',
        userAgent: '',
        requestHeaders: {},
        searchRule: {},
        detailRule: {},
        playRule: {}
      }
    ];
  }
  
  /**
   * 获取所有站点
   */
  public async getAllSites(): Promise<SiteInfo[]> {
    await this.initialize();
    const sites: SiteInfo[] = [];
    
    for (const [key, config] of this.siteConfigs.entries()) {
      sites.push(config);
    }
    
    return sites.sort((a, b) => {
      // 按启用状态和名称排序
      if (a.enabled !== b.enabled) {
        return a.enabled ? -1 : 1;
      }
      return a.name.localeCompare(b.name);
    });
  }
  
  /**
   * 获取已启用的站点
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
   * 设置站点状态
   */
  public async setSiteStatus(siteKey: string, enabled: boolean): Promise<void> {
    await this.initialize();
    
    const config = this.siteConfigs.get(siteKey);
    if (config) {
      config.enabled = enabled;
      this.siteConfigs.set(siteKey, config);
      
      // 保存更新后的配置
      const allSites = await this.getAllSites();
      await this.storageUtil.saveSitesConfig(allSites);
    }
  }
  
  /**
   * 导入站点配置
   */
  public async importSiteConfig(configStr: string): Promise<SiteInfo | null> {
    await this.initialize();
    
    try {
      // 使用ConfigParser解析站点配置
      const siteConfig = this.configParser.parseSiteConfig(configStr);
      
      if (siteConfig && siteConfig.key) {
        // 检查是否已存在同名站点
        if (this.siteConfigs.has(siteConfig.key)) {
          // 更新现有站点
          const existingConfig = this.siteConfigs.get(siteConfig.key);
          siteConfig.enabled = existingConfig.enabled;
        }
        
        // 保存站点配置
        this.siteConfigs.set(siteConfig.key, siteConfig);
        
        // 创建爬虫实例
        const spider = this.createSpider(siteConfig.key, siteConfig);
        if (spider) {
          this.siteSpiders.set(siteConfig.key, spider);
        }
        
        // 保存到存储
        const allSites = await this.getAllSites();
        await this.storageUtil.saveSitesConfig(allSites);
        
        return siteConfig;
      }
      
      return null;
    } catch (error) {
      console.error('Failed to import site config:', error);
      throw new Error('导入站点配置失败');
    }
  }
  
  /**
   * 删除站点
   */
  public async removeSite(siteKey: string): Promise<void> {
    await this.initialize();
    
    if (this.siteConfigs.has(siteKey)) {
      this.siteConfigs.delete(siteKey);
      this.siteSpiders.delete(siteKey);
      
      // 更新存储
      const allSites = await this.getAllSites();
      await this.storageUtil.saveSitesConfig(allSites);
    }
  }
  
  /**
   * 调用站点方法
   */
  public async callSiteMethod<T>(siteKey: string, methodName: string, args: unknown[]): Promise<T> {
    await this.initialize();
    
    const spider = this.siteSpiders.get(siteKey);
    if (!spider) {
      Logger.error(this.TAG, `No spider found for site: ${siteKey}`);
      // 返回空数据而不是使用模拟数据
      return this.getDefaultEmptyData<T>(methodName);
    }
    
    return this.callSpiderMethod<T>(spider, methodName, args);
  }
  
  /**
   * 调用爬虫实例方法
   */
  private async callSpiderMethod<T>(spider: SiteSpider, methodName: string, args: unknown[]): Promise<T> {
    try {
      const method = (spider as Record<string, unknown>)[methodName];
      if (typeof method === 'function') {
        // ArkTS兼容：使用直接调用替代apply
        return await (spider as Record<string, Function>)[methodName](...args) as T;
      } else {
        throw new Error(`Method ${methodName} not found in spider`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to call ${methodName} on spider:`, error);
      // 返回空数据而不是模拟数据
      return this.getDefaultEmptyData<T>(methodName);
    }
  }
  
  /**
   * 根据方法名返回默认空数据
   */
  private getDefaultEmptyData<T>(methodName: string): T {
    Logger.warn(this.TAG, `Returning default empty data for method: ${methodName}`);
    
    // 根据不同方法返回相应的空数据类型
    switch (methodName) {
      case 'getRecommendList':
      case 'getHotList':
      case 'getLatestList':
      case 'getCategoryList':
      case 'search':
      case 'getSearchSuggestions':
        return [] as unknown as T;
      case 'getCategories':
        return [] as unknown as T;
      case 'getDetail':
        return {} as unknown as T;
      case 'getPlayUrl':
        return '' as unknown as T;
      case 'getSiteInfo':
        return {} as unknown as T;
      default:
        return {} as unknown as T;
    }
  }
}

// 移除了模拟数据生成器和相关类定义

// 导出一些额外的类型和工具函数
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