// 爬虫服务
// 管理多站点数据获取、解析和统一接口

import { SiteInfo } from '../../data/bean/Site';
import { ConfigService } from '../config/ConfigService';
import { HttpService } from '../HttpService';
import { StorageUtil } from '../../common/util/StorageUtil';
import { ConfigParser } from '../config/ConfigParser';

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
      // 目前只支持创建模拟爬虫
      return this.createMockSpider(config);
    } catch (error) {
      console.error(`Failed to create spider for site ${key}:`, error);
      return null;
    }
  }
  
  /**
   * 创建模拟爬虫实例
   */
  private createMockSpider(siteConfig: SiteInfo): SiteSpider {
    return new MockSiteSpider(siteConfig);
  }
  
  /**
   * 获取默认站点配置
   */
  private getDefaultSites(): SiteInfo[] {
    return [
      {
        key: 'demo_vod_site',
        name: '示例点播站',
        type: 'vod',
        url: 'https://example.com/vod',
        enabled: true,
        updateTime: new Date().toISOString(),
        version: '1.0.0',
        userAgent: '',
        requestHeaders: {},
        searchRule: {},
        detailRule: {},
        playRule: {}
      },
      {
        key: 'demo_live_site',
        name: '示例直播站',
        type: 'live',
        url: 'https://example.com/live',
        enabled: true,
        updateTime: new Date().toISOString(),
        version: '1.0.0',
        userAgent: '',
        requestHeaders: {},
        searchRule: {},
        detailRule: {},
        playRule: {}
      },
      {
        key: 'demo_mixed_site',
        name: '示例混合站',
        type: 'mixed',
        url: 'https://example.com/mixed',
        enabled: false,
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
      // 如果找不到对应的爬虫，使用默认的模拟爬虫
      const mockSpider = new MockSiteSpider({
        key: siteKey,
        name: '默认站点',
        type: 'mixed',
        url: '',
        enabled: true,
        updateTime: new Date().toISOString(),
        version: '1.0'
      });
      
      return this.callSpiderMethod<T>(mockSpider, methodName, args);
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
      console.error(`Failed to call ${methodName} on spider:`, error);
      // 返回模拟数据
      return this.getMockDataByMethod<T>(methodName, args);
    }
  }
  
  /**
   * 根据方法名返回模拟数据
   */
  private getMockDataByMethod(methodName: string, args: Object[]): Object {
    const mockDataGenerator = new MockDataGenerator();
    
    switch (methodName) {
      case 'getRecommendList':
        return mockDataGenerator.generateRecommendList() as Object;
      case 'getHotList':
        return mockDataGenerator.generateHotList() as Object;
      case 'getLatestList':
        return mockDataGenerator.generateLatestList() as Object;
      case 'getCategories':
        return mockDataGenerator.generateCategories() as Object;
      case 'getCategoryList':
        return mockDataGenerator.generateCategoryList(args[0], args[1]) as Object;
      case 'search':
        return mockDataGenerator.generateSearchResults(args[0]) as Object;
      case 'getDetail':
        return mockDataGenerator.generateDetail(args[0]) as Object;
      case 'getPlayUrl':
        return mockDataGenerator.generatePlayUrl(args[0], args[1]) as Object;
      case 'getSearchSuggestions':
        return mockDataGenerator.generateSearchSuggestions(args[0]) as Object;
      case 'getSiteInfo':
        return mockDataGenerator.generateSiteInfo() as Object;
      default:
        Logger.warn(this.TAG, `Unsupported mock method: ${methodName}`);
        return {}; // 返回空对象而不是null
    }
  }
}

/**
 * 模拟站点爬虫实现
 */
class MockSiteSpider implements SiteSpider {
  private siteInfo: SiteInfo;
  private dataGenerator: MockDataGenerator;
  
  constructor(siteInfo: SiteInfo) {
    this.siteInfo = siteInfo;
    this.dataGenerator = new MockDataGenerator(siteInfo.key);
  }
  
  async getSiteInfo(): Promise<SiteInfo> {
    return this.siteInfo;
  }
  
  async getRecommendList(): Promise<VideoItem[]> {
    return this.dataGenerator.generateRecommendList();
  }
  
  async getHotList(): Promise<VideoItem[]> {
    return this.dataGenerator.generateHotList();
  }
  
  async getLatestList(): Promise<VideoItem[]> {
    return this.dataGenerator.generateLatestList();
  }
  
  async getCategories(): Promise<string[]> {
    return this.dataGenerator.generateCategories();
  }
  
  async getCategoryList(category: string, page: number = 1): Promise<VideoItem[]> {
    return this.dataGenerator.generateCategoryList(category, page);
  }
  
  async search(keyword: string, page: number = 1): Promise<VideoItem[]> {
    return this.dataGenerator.generateSearchResults(keyword, page);
  }
  
  async getDetail(id: string): Promise<VideoDetail> {
    return this.dataGenerator.generateDetail(id);
  }
  
  async getPlayUrl(id: string, episodeId?: string): Promise<string> {
    return this.dataGenerator.generatePlayUrl(id, episodeId);
  }
  
  async getSearchSuggestions(keyword: string): Promise<string[]> {
    return this.dataGenerator.generateSearchSuggestions(keyword);
  }
}

/**
 * 模拟数据生成器
 */
class MockDataGenerator {
  private siteKey: string;
  
  constructor(siteKey: string = 'default') {
    this.siteKey = siteKey;
  }
  
  generateRecommendList(): VideoItem[] {
    return [
      { id: '1', title: '流浪地球2', cover: '', url: '', rating: 9.2, type: 'movie' },
      { id: '2', title: '满江红', cover: '', url: '', rating: 8.7, type: 'movie' },
      { id: '3', title: '三体', cover: '', url: '', rating: 8.5, updateInfo: '全30集', type: 'tv' },
      { id: '4', title: '狂飙', cover: '', url: '', rating: 9.0, updateInfo: '全39集', type: 'tv' },
      { id: '5', title: '中国奇谭', cover: '', url: '', rating: 9.3, updateInfo: '更新至8集', type: 'anime' }
    ];
  }
  
  generateHotList(): VideoItem[] {
    return [
      { id: '101', title: '狂飙', cover: '', url: '', updateInfo: '全39集', type: 'tv', hot: 123456 },
      { id: '102', title: '三体', cover: '', url: '', updateInfo: '全30集', type: 'tv', hot: 98765 },
      { id: '103', title: '流浪地球2', cover: '', url: '', type: 'movie', hot: 87654 },
      { id: '104', title: '满江红', cover: '', url: '', type: 'movie', hot: 76543 },
      { id: '105', title: '去有风的地方', cover: '', url: '', updateInfo: '全40集', type: 'tv', hot: 65432 },
      { id: '106', title: '显微镜下的大明之丝绢案', cover: '', url: '', updateInfo: '全36集', type: 'tv', hot: 54321 },
      { id: '107', title: '无名', cover: '', url: '', type: 'movie', hot: 43210 },
      { id: '108', title: '中国奇谭', cover: '', url: '', updateInfo: '更新至8集', type: 'anime', hot: 32100 },
      { id: '109', title: '熊出没·伴我熊芯', cover: '', url: '', type: 'movie', hot: 21000 },
      { id: '110', title: '今生也是第一次', cover: '', url: '', updateInfo: '全30集', type: 'tv', hot: 10000 }
    ];
  }
  
  generateLatestList(): VideoItem[] {
    return [
      { id: '201', title: '新神榜：杨戬', cover: '', url: '', updateInfo: 'HD国语', type: 'movie', updateTime: new Date().toISOString() },
      { id: '202', title: '阿凡达：水之道', cover: '', url: '', updateInfo: 'HD英语', type: 'movie', updateTime: new Date().toISOString() },
      { id: '203', title: '深海', cover: '', url: '', updateInfo: 'HD国语', type: 'movie', updateTime: new Date().toISOString() },
      { id: '204', title: '消失的她', cover: '', url: '', updateInfo: 'HD国语', type: 'movie', updateTime: new Date().toISOString() },
      { id: '205', title: '星落凝成糖', cover: '', url: '', updateInfo: '更新至20集', type: 'tv', updateTime: new Date().toISOString() },
      { id: '206', title: '重紫', cover: '', url: '', updateInfo: '全40集', type: 'tv', updateTime: new Date().toISOString() },
      { id: '207', title: '我的人间烟火', cover: '', url: '', updateInfo: '更新至12集', type: 'tv', updateTime: new Date().toISOString() },
      { id: '208', title: '铃芽之旅', cover: '', url: '', updateInfo: 'HD日语', type: 'movie', updateTime: new Date().toISOString() },
      { id: '209', title: '听说你喜欢我', cover: '', url: '', updateInfo: '全36集', type: 'tv', updateTime: new Date().toISOString() },
      { id: '210', title: '君子盟', cover: '', url: '', updateInfo: '全36集', type: 'tv', updateTime: new Date().toISOString() }
    ];
  }
  
  generateCategories(): string[] {
    return [
      '电影', '电视剧', '动漫', '综艺', '纪录片', '少儿',
      '动作', '喜剧', '爱情', '科幻', '悬疑', '惊悚',
      '恐怖', '奇幻', '冒险', '武侠', '古装', '历史'
    ];
  }
  
  generateCategoryList(category: string, page: number = 1): VideoItem[] {
    const results: VideoItem[] = [];
    const startId = (page - 1) * 20 + 1;
    
    for (let i = 0; i < 20; i++) {
      const id = `${startId + i}`;
      results.push({
        id,
        title: `${category}相关内容 ${id}`,
        cover: '',
        url: '',
        rating: 7 + Math.random() * 2,
        updateInfo: Math.random() > 0.5 ? '全40集' : `更新至${i + 1}集`,
        type: category === '电影' ? 'movie' : 'tv'
      });
    }
    
    return results;
  }
  
  generateSearchResults(keyword: string, page: number = 1): VideoItem[] {
    const results: VideoItem[] = [];
    const startId = (page - 1) * 20 + 1000;
    
    for (let i = 0; i < 20; i++) {
      const id = `${startId + i}`;
      results.push({
        id,
        title: `${keyword}相关内容 ${i + 1}`,
        cover: '',
        url: '',
        rating: 7 + Math.random() * 2,
        updateInfo: Math.random() > 0.5 ? '全40集' : `更新至${i + 1}集`,
        type: Math.random() > 0.5 ? 'movie' : 'tv'
      });
    }
    
    return results;
  }
  
  generateDetail(id: string): VideoDetail {
    return {
      id,
      title: `模拟视频详情 ${id}`,
      cover: '',
      description: '这是一段模拟的视频详细描述，在实际应用中会显示真实的视频详情信息。这部作品讲述了一个精彩的故事，情节跌宕起伏，扣人心弦。主演的表演非常出色，画面精美，值得一看。',
      category: '电影',
      tags: ['动作', '冒险', '科幻'],
      rating: 9.2,
      year: '2023',
      region: '中国大陆',
      director: '张艺谋',
      actors: ['演员1', '演员2', '演员3', '演员4'],
      updateTime: new Date().toISOString(),
      playSources: [
        { name: '线路1', url: `https://example.com/play/${id}/1` },
        { name: '线路2', url: `https://example.com/play/${id}/2` },
        { name: '线路3', url: `https://example.com/play/${id}/3` }
      ],
      episodes: this.generateEpisodes(40)
    };
  }
  
  private generateEpisodes(count: number): Array<{ id: string; name: string }> {
    const episodes: Array<{ id: string; name: string }> = [];
    
    for (let i = 1; i <= count; i++) {
      episodes.push({
        id: `ep${i}`,
        name: `第${i}集`
      });
    }
    
    return episodes;
  }
  
  generatePlayUrl(id: string, episodeId?: string): string {
    return `https://example.com/vod/${id}/${episodeId || '1'}.m3u8`;
  }
  
  generateSearchSuggestions(keyword: string): string[] {
    return [
      `${keyword}电影`,
      `${keyword}电视剧`,
      `${keyword}最新`,
      `${keyword}高清`,
      ` ${keyword}`,
      `${keyword} 在线观看`,
      `${keyword}完整版`,
      `最新${keyword}`
    ];
  }
  
  generateSiteInfo(): SiteInfo {
    return {
      key: this.siteKey,
      name: '模拟站点',
      type: 'mixed',
      url: 'https://example.com',
      enabled: true,
      updateTime: new Date().toISOString(),
      version: '1.0.0',
      userAgent: '',
      requestHeaders: {},
      searchRule: {},
      detailRule: {},
      playRule: {}
    };
  }
}

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