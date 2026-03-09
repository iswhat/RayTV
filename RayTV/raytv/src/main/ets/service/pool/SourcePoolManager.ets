/**
 * Source Pool Manager - 统一内容池管理器
 * 
 * 负责将各个网络源的内容提取到统一的使用池中,
 * 支持点播、直播、壁纸、广告过滤规则、解码配置等内容的管理
 * 
 * 核心特性:
 * - 按源选择性加载内容
 * - 合并多个源的配置(广告过滤、解码等)
 * - 为每个内容项标记来源
 * - 支持按源筛选和查询
 */

import Logger from '../../common/util/Logger';
import ConfigSourceService, { ConfigSource } from '../config/ConfigSourceService';

// ========================================
// 数据类型定义
// ========================================

/**
 * 网络源配置
 */
export interface NetworkSourceConfig {
  id: string;                    // 唯一标识
  name: string;                  // 显示名称
  url: string;                   // 配置源URL
  type: 'json' | 'yaml' | 'txt' | 'nas';
  version: string;               // 版本号
  isActive: boolean;             // 是否启用
  
  // 内容开关 - 控制哪些内容被提取到使用池
  contentUsage: ContentUsage;
  
  // 优先级配置 (1-10, 数字越大优先级越高)
  priority: number;
  
  // 使用池中的标签/标记 (用于UI显示来源)
  tags?: string[];
  
  // NAS设备配置 (仅当type为'nas'时使用)
  nasConfig?: {
    deviceId: string;            // NAS设备ID
    protocol: string;            // 协议类型 (smb, huawei, webdav, dlna)
    address: string;             // 设备地址
    port?: number;               // 端口
    username?: string;           // 用户名
    password?: string;           // 密码
    share?: string;              // SMB共享名称
    domain?: string;             // 域 (SMB)
  };
  
  lastUpdated: number;           // 最后更新时间
  healthStatus: 'healthy' | 'degraded' | 'unreachable';
}

/**
 * 内容使用配置
 */
export interface ContentUsage {
  vodSites: boolean;           // 是否使用点播站点
  liveChannels: boolean;       // 是否使用直播频道
  wallpapers: boolean;         // 是否使用壁纸
  adBlockRules: boolean;       // 是否使用广告过滤规则
  decoderConfigs: boolean;     // 是否使用解码配置
  parserConfigs: boolean;      // 是否使用解析器配置
}

/**
 * 带来源标识的点播站点
 */
export interface VodSiteWithSource {
  siteKey: string;
  name: string;
  url: string;
  
  // 来源标识
  sourceId: string;
  sourceName: string;
  sourcePriority: number;
  sourceTags?: string[];
  
  // 站点元数据
  categories?: string[];
  flags?: string[];
}

/**
 * 带来源标识的直播频道
 * Live channel with source identifier
 * 
 * 从LiveChannelTypes导入统一定义
 * Import unified definition from LiveChannelTypes
 */
export { LiveChannelWithSource, LiveCategory, ExtendedLiveChannelWithSource, LiveProgramInfo } from '../live/LiveChannelTypes';
export { toLiveChannelWithSource, toExtendedLiveChannel, isValidLiveChannel, createLiveChannelWithSource } from '../live/LiveChannelTypes';

/**
 * 带来源标识的壁纸
 */
export interface WallpaperWithSource {
  id: string;
  name: string;
  url: string;
  
  // 来源标识
  sourceId: string;
  sourceName: string;
  
  // 元数据
  thumbnail?: string;
  aspectRatio?: string;
}

/**
 * 直播分类
 */
export interface LiveCategory {
  id: string;
  name: string;
  channelCount: number;
  sources: string[]; // 来源源ID列表
}

/**
 * 广告过滤规则
 */
export interface AdBlockRule {
  id: string;
  pattern: string;
  type: 'domain' | 'url' | 'element';
  enabled: boolean;
}

/**
 * 解码配置
 */
export interface DecoderConfig {
  id: string;
  name: string;
  type: string;
  config: Record<string, string>;
}

// ========================================
// 池接口定义
// ========================================

/**
 * 点播站点池接口
 */
interface IVodSitePool {
  sites: VodSiteWithSource[];
  sourceMap: Map<string, string>;
  
  addSites(sites: VodSiteWithSource[]): void;
  removeSitesBySource(sourceId: string): void;
  getSite(siteKey: string): VodSiteWithSource | null;
  getSiteBySource(sourceId: string): VodSiteWithSource[];
  getAllSites(): VodSiteWithSource[];
  clear(): void;
}

/**
 * 直播频道池接口
 */
interface ILiveChannelPool {
  channels: LiveChannelWithSource[];
  categories: LiveCategory[];
  
  addChannels(channels: LiveChannelWithSource[]): void;
  removeChannelsBySource(sourceId: string): void;
  getChannelsByCategory(category: string): LiveChannelWithSource[];
  getChannelsBySource(sourceId: string): LiveChannelWithSource[];
  getAllChannels(): LiveChannelWithSource[];
  clear(): void;
}

/**
 * 壁纸池接口
 */
interface IWallpaperPool {
  wallpapers: WallpaperWithSource[];
  
  addWallpapers(wallpapers: WallpaperWithSource[]): void;
  removeWallpapersBySource(sourceId: string): void;
  getRandomWallpaper(): WallpaperWithSource | null;
  getWallpapersBySource(sourceId: string): WallpaperWithSource[];
  getAllWallpapers(): WallpaperWithSource[];
  clear(): void;
}

/**
 * 全局广告过滤规则接口
 */
interface IGlobalAdBlockRules {
  rules: AdBlockRule[];
  sources: Set<string>; // 来源源ID集合
  
  addRules(rules: AdBlockRule[], sourceId: string): void;
  removeRulesBySource(sourceId: string): void;
  getRules(): AdBlockRule[];
  clear(): void;
}

/**
 * 全局解码配置接口
 */
interface IGlobalDecoderConfigs {
  configs: DecoderConfig[];
  sources: Map<string, string>; // configKey -> sourceId
  
  addConfigs(configs: DecoderConfig[], sourceId: string): void;
  removeConfigsBySource(sourceId: string): void;
  getConfigs(type?: string): DecoderConfig[];
  clear(): void;
}

// ========================================
// 池实现类
// ========================================

class VodSitePool implements IVodSitePool {
  sites: VodSiteWithSource[] = [];
  sourceMap: Map<string, string> = new Map();
  
  addSites(sites: VodSiteWithSource[]): void {
    // 先移除该源的旧数据
    if (sites.length > 0) {
      this.removeSitesBySource(sites[0].sourceId);
    }
    
    // 添加新数据
    this.sites = this.sites.concat(sites);
    sites.forEach(site => {
      this.sourceMap.set(site.siteKey, site.sourceId);
    });
  }
  
  removeSitesBySource(sourceId: string): void {
    this.sites = this.sites.filter(site => site.sourceId !== sourceId);
    
    // 更新sourceMap
    for (const [siteKey, sid] of this.sourceMap.entries()) {
      if (sid === sourceId) {
        this.sourceMap.delete(siteKey);
      }
    }
  }
  
  getSite(siteKey: string): VodSiteWithSource | null {
    return this.sites.find(site => site.siteKey === siteKey) || null;
  }
  
  getSiteBySource(sourceId: string): VodSiteWithSource[] {
    return this.sites.filter(site => site.sourceId === sourceId);
  }
  
  getAllSites(): VodSiteWithSource[] {
    return this.sites;
  }
  
  clear(): void {
    this.sites = [];
    this.sourceMap.clear();
  }
}

class LiveChannelPool implements ILiveChannelPool {
  channels: LiveChannelWithSource[] = [];
  categories: LiveCategory[] = [];
  
  addChannels(channels: LiveChannelWithSource[]): void {
    // 先移除该源的旧数据
    if (channels.length > 0) {
      this.removeChannelsBySource(channels[0].sourceId);
    }
    
    // 添加新数据
    this.channels = this.channels.concat(channels);
    
    // 更新分类
    this.updateCategories();
  }
  
  removeChannelsBySource(sourceId: string): void {
    this.channels = this.channels.filter(ch => ch.sourceId !== sourceId);
    this.updateCategories();
  }
  
  private updateCategories(): void {
    const categoryMap = new Map<string, { count: number; sources: Set<string> }>();
    
    this.channels.forEach(channel => {
      const existing = categoryMap.get(channel.group);
      if (existing) {
        existing.count++;
        existing.sources.add(channel.sourceId);
      } else {
        categoryMap.set(channel.group, {
          count: 1,
          sources: new Set([channel.sourceId])
        });
      }
    });
    
    this.categories = Array.from(categoryMap.entries()).map(([name, data], index) => ({
      id: `cat_${index}`,
      name,
      channelCount: data.count,
      sources: Array.from(data.sources)
    }));
  }
  
  getChannelsByCategory(category: string): LiveChannelWithSource[] {
    return this.channels.filter(ch => ch.group === category);
  }
  
  getChannelsBySource(sourceId: string): LiveChannelWithSource[] {
    return this.channels.filter(ch => ch.sourceId === sourceId);
  }
  
  getAllChannels(): LiveChannelWithSource[] {
    return this.channels;
  }
  
  clear(): void {
    this.channels = [];
    this.categories = [];
  }
}

class WallpaperPool implements IWallpaperPool {
  wallpapers: WallpaperWithSource[] = [];
  
  addWallpapers(wallpapers: WallpaperWithSource[]): void {
    // 先移除该源的旧数据
    if (wallpapers.length > 0) {
      this.removeWallpapersBySource(wallpapers[0].sourceId);
    }
    
    // 添加新数据
    this.wallpapers = this.wallpapers.concat(wallpapers);
  }
  
  removeWallpapersBySource(sourceId: string): void {
    this.wallpapers = this.wallpapers.filter(wp => wp.sourceId !== sourceId);
  }
  
  getRandomWallpaper(): WallpaperWithSource | null {
    if (this.wallpapers.length === 0) {
      return null;
    }
    const index = Math.floor(Math.random() * this.wallpapers.length);
    return this.wallpapers[index];
  }
  
  getWallpapersBySource(sourceId: string): WallpaperWithSource[] {
    return this.wallpapers.filter(wp => wp.sourceId === sourceId);
  }
  
  getAllWallpapers(): WallpaperWithSource[] {
    return this.wallpapers;
  }
  
  clear(): void {
    this.wallpapers = [];
  }
}

class GlobalAdBlockRules implements IGlobalAdBlockRules {
  rules: AdBlockRule[] = [];
  sources: Set<string> = new Set();
  
  addRules(rules: AdBlockRule[], sourceId: string): void {
    // 移除该源的旧规则
    this.removeRulesBySource(sourceId);
    
    // 添加新规则(添加来源标识)
    const rulesWithSource = rules.map(rule => ({
      ...rule,
      id: `${sourceId}_${rule.id}`
    }));
    
    this.rules = this.rules.concat(rulesWithSource);
    this.sources.add(sourceId);
  }
  
  removeRulesBySource(sourceId: string): void {
    this.rules = this.rules.filter(rule => !rule.id.startsWith(`${sourceId}_`));
    this.sources.delete(sourceId);
  }
  
  getRules(): AdBlockRule[] {
    return this.rules;
  }
  
  clear(): void {
    this.rules = [];
    this.sources.clear();
  }
}

class GlobalDecoderConfigs implements IGlobalDecoderConfigs {
  configs: DecoderConfig[] = [];
  sources: Map<string, string> = new Map();
  
  addConfigs(configs: DecoderConfig[], sourceId: string): void {
    // 移除该源的旧配置
    this.removeConfigsBySource(sourceId);
    
    // 添加新配置(添加来源标识)
    const configsWithSource = configs.map(config => ({
      ...config,
      id: `${sourceId}_${config.id}`
    }));
    
    this.configs = this.configs.concat(configsWithSource);
    configsWithSource.forEach(config => {
      this.sources.set(config.id, sourceId);
    });
  }
  
  removeConfigsBySource(sourceId: string): void {
    this.configs = this.configs.filter(config => !config.id.startsWith(`${sourceId}_`));
    
    for (const [configId, sid] of this.sources.entries()) {
      if (sid === sourceId) {
        this.sources.delete(configId);
      }
    }
  }
  
  getConfigs(type?: string): DecoderConfig[] {
    if (type) {
      return this.configs.filter(config => config.type === type);
    }
    return this.configs;
  }
  
  clear(): void {
    this.configs = [];
    this.sources.clear();
  }
}

// ========================================
// Source Pool Manager 主类
// ========================================

/**
 * 源池管理器
 * 
 * 负责将各个网络源的内容提取到统一的使用池中
 */
export class SourcePoolManager {
  private static instance: SourcePoolManager | null = null;
  private logger: Logger;
  private configSourceService: ConfigSourceService;
  
  // 统一使用池
  private vodPool: IVodSitePool;
  private livePool: ILiveChannelPool;
  private wallpaperPool: IWallpaperPool;
  private adBlockRules: IGlobalAdBlockRules;
  private decoderConfigs: IGlobalDecoderConfigs;
  
  private initialized: boolean = false;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): SourcePoolManager {
    if (!SourcePoolManager.instance) {
      SourcePoolManager.instance = new SourcePoolManager();
    }
    return SourcePoolManager.instance;
  }
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger = Logger.getInstance('SourcePoolManager');
    this.configSourceService = ConfigSourceService.getInstance();
    
    // 初始化池
    this.vodPool = new VodSitePool();
    this.livePool = new LiveChannelPool();
    this.wallpaperPool = new WallpaperPool();
    this.adBlockRules = new GlobalAdBlockRules();
    this.decoderConfigs = new GlobalDecoderConfigs();
  }
  
  /**
   * 初始化管理器
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }
    
    try {
      this.logger.info('Initializing SourcePoolManager');
      
      // 加载所有启用的源
      const sources = await this.configSourceService.getAllSources();
      const activeSources = sources.filter(s => s.isActive);
      
      this.logger.info(`Found ${activeSources.length} active sources`);
      
      // 并行加载所有源，提高启动速度
      if (activeSources.length > 0) {
        const loadPromises = activeSources.map(source => 
          this.loadFromSource(source).catch(error => {
            const err = error instanceof Error ? error : new Error(String(error));
            this.logger.error(`Failed to load source ${source.id}, continuing with other sources`, err);
            // 单个源失败不影响其他源的加载
          })
        );
        
        await Promise.all(loadPromises);
      }
      
      this.initialized = true;
      this.logger.info('SourcePoolManager initialized successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error('Failed to initialize SourcePoolManager', err);
      throw err;
    }
  }
  
  /**
   * 从单个源加载内容到池中
   * 
   * @param source 网络源配置
   */
  public async loadFromSource(source: NetworkSourceConfig): Promise<void> {
    if (!source.isActive) {
      this.logger.info(`Source ${source.id} is not active, skipping`);
      return;
    }
    
    try {
      this.logger.info(`Loading content from source: ${source.name} (${source.id})`);
      
      const usage = source.contentUsage;
      
      // 根据内容开关选择性加载
      if (usage.vodSites) {
        const vodSites = await this.retryWithBackoff(() => this.loadVodSites(source));
        this.vodPool.addSites(vodSites);
        this.logger.info(`Loaded ${vodSites.length} VOD sites from source ${source.id}`);
      }
      
      if (usage.liveChannels) {
        const liveChannels = await this.retryWithBackoff(() => this.loadLiveChannels(source));
        this.livePool.addChannels(liveChannels);
        this.logger.info(`Loaded ${liveChannels.length} live channels from source ${source.id}`);
      }
      
      if (usage.wallpapers) {
        const wallpapers = await this.retryWithBackoff(() => this.loadWallpapers(source));
        this.wallpaperPool.addWallpapers(wallpapers);
        this.logger.info(`Loaded ${wallpapers.length} wallpapers from source ${source.id}`);
      }
      
      if (usage.adBlockRules) {
        const rules = await this.retryWithBackoff(() => this.loadAdBlockRules(source));
        this.adBlockRules.addRules(rules, source.id);
        this.logger.info(`Loaded ${rules.length} ad block rules from source ${source.id}`);
      }
      
      if (usage.decoderConfigs) {
        const configs = await this.retryWithBackoff(() => this.loadDecoderConfigs(source));
        this.decoderConfigs.addConfigs(configs, source.id);
        this.logger.info(`Loaded ${configs.length} decoder configs from source ${source.id}`);
      }
      
      this.logger.info(`Successfully loaded content from source: ${source.name}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error(`Failed to load content from source ${source.id}`, err);
      throw err;
    }
  }
  
  /**
   * 带退避的重试机制
   * 
   * @param fn 要执行的异步函数
   * @param maxRetries 最大重试次数
   * @returns 函数执行结果
   */
  private async retryWithBackoff<T>(fn: () => Promise<T>, maxRetries: number = 3): Promise<T> {
    let lastError: Error;
    
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));
        this.logger.warn(`Attempt ${i + 1} failed, retrying...`, lastError);
        
        // 指数退避
        const delay = Math.pow(2, i) * 1000;
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
    
    throw lastError!;
  }
  
  /**
   * 重新构建所有池
   * 
   * @param sources 网络源配置列表
   */
  public async rebuildAllPools(sources: NetworkSourceConfig[]): Promise<void> {
    this.logger.info('Rebuilding all pools');
    
    try {
      // 清空所有池
      this.vodPool.clear();
      this.livePool.clear();
      this.wallpaperPool.clear();
      this.adBlockRules.clear();
      this.decoderConfigs.clear();
      
      // 从所有启用的源重新加载
      const activeSources = sources.filter(s => s.isActive);
      this.logger.info(`Rebuilding from ${activeSources.length} active sources`);
      
      // 并行加载所有源，提高性能
      if (activeSources.length > 0) {
        const loadPromises = activeSources.map(source => 
          this.loadFromSource(source).catch(error => {
            const err = error instanceof Error ? error : new Error(String(error));
            this.logger.error(`Failed to load source ${source.id} during rebuild, continuing with other sources`, err);
            // 单个源失败不影响其他源的加载
          })
        );
        
        await Promise.all(loadPromises);
      }
      
      this.logger.info('All pools rebuilt successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.logger.error('Failed to rebuild pools', err);
      throw err;
    }
  }
  
  // ========================================
  // 池访问方法
  // ========================================
  
  /**
   * 获取点播站点池
   */
  public getVodPool(): IVodSitePool {
    return this.vodPool;
  }
  
  /**
   * 获取直播频道池
   */
  public getLivePool(): ILiveChannelPool {
    return this.livePool;
  }
  
  /**
   * 获取壁纸池
   */
  public getWallpaperPool(): IWallpaperPool {
    return this.wallpaperPool;
  }
  
  /**
   * 获取广告过滤规则
   */
  public getAdBlockRules(): IGlobalAdBlockRules {
    return this.adBlockRules;
  }
  
  /**
   * 获取解码配置
   */
  public getDecoderConfigs(): IGlobalDecoderConfigs {
    return this.decoderConfigs;
  }

  /**
   * 获取解析器配置
   */
  public getParserConfigs(): ParserConfig[] {
    const allParsers: ParserConfig[] = [];
    this.vodPool.getSites().forEach(site => {
      if (site.parsers) {
        allParsers.push(...site.parsers);
      }
    });
    // 去重
    const uniqueParsers = new Map<string, ParserConfig>();
    allParsers.forEach(parser => {
      const key = `${parser.name}_${parser.url}`;
      if (!uniqueParsers.has(key)) {
        uniqueParsers.set(key, parser);
      }
    });
    return Array.from(uniqueParsers.values());
  }
  
  // ========================================
  // 私有加载方法 (从ConfigSourceService加载)
  // ========================================
  
  private async loadVodSites(source: NetworkSourceConfig): Promise<VodSiteWithSource[]> {
    // 从ConfigSourceService加载解析后的配置
    const parsedConfig = await this.configSourceService.getParsedConfig(source.url);
    
    if (!parsedConfig || !parsedConfig.sites || parsedConfig.sites.length === 0) {
      return [];
    }
    
    return parsedConfig.sites.map(site => ({
      siteKey: site.key || site.name,
      name: site.name,
      url: site.url,
      sourceId: source.id,
      sourceName: source.name,
      sourcePriority: source.priority,
      sourceTags: source.tags,
      categories: site.groups || site.categories,
      flags: site.flags
    }));
  }
  
  private async loadLiveChannels(source: NetworkSourceConfig): Promise<LiveChannelWithSource[]> {
    // 从ConfigSourceService加载解析后的配置
    const parsedConfig = await this.configSourceService.getParsedConfig(source.url);

    if (!parsedConfig || !parsedConfig.lives || parsedConfig.lives.length === 0) {
      return [];
    }

    const channels: LiveChannelWithSource[] = [];

    // 直接使用 lives 数组中的每个 LiveSource 作为频道
    parsedConfig.lives.forEach(live => {
      channels.push({
        id: `${source.id}_${live.name}`,
        name: live.name,
        url: live.url,
        group: live.type?.toString() || '默认', // 使用 type 作为 group
        sourceId: source.id,
        sourceName: source.name,
        logo: live.logo,
        epgUrl: live.epg
      });
    });
    
    return channels;
  }
  
  private async loadWallpapers(source: NetworkSourceConfig): Promise<WallpaperWithSource[]> {
    // 从ConfigSourceService加载壁纸数据
    const parsedConfig = await this.configSourceService.getParsedConfig(source.url);
    
    if (!parsedConfig || !parsedConfig.wallpapers || parsedConfig.wallpapers.length === 0) {
      return [];
    }
    
    return parsedConfig.wallpapers.map(wallpaper => ({
      id: `${source.id}_${wallpaper.id}`,
      name: wallpaper.name,
      url: wallpaper.url,
      sourceId: source.id,
      sourceName: source.name,
      thumbnail: wallpaper.thumbnail,
      aspectRatio: wallpaper.aspectRatio
    }));
  }
  
  private async loadAdBlockRules(source: NetworkSourceConfig): Promise<AdBlockRule[]> {
    // 从ConfigSourceService加载广告过滤规则
    const parsedConfig = await this.configSourceService.getParsedConfig(source.url);
    
    if (!parsedConfig || !parsedConfig.adBlockRules || parsedConfig.adBlockRules.length === 0) {
      return [];
    }
    
    return parsedConfig.adBlockRules.map(rule => ({
      id: rule.id || `${Date.now()}_${Math.random()}`,
      pattern: rule.pattern,
      type: rule.type || 'domain',
      enabled: rule.enabled !== false
    }));
  }
  
  private async loadDecoderConfigs(source: NetworkSourceConfig): Promise<DecoderConfig[]> {
    // 从ConfigSourceService加载解码配置
    const parsedConfig = await this.configSourceService.getParsedConfig(source.url);
    
    if (!parsedConfig || !parsedConfig.decoderConfigs || parsedConfig.decoderConfigs.length === 0) {
      return [];
    }
    
    return parsedConfig.decoderConfigs.map(config => ({
      id: config.id || `${Date.now()}_${Math.random()}`,
      name: config.name,
      type: config.type,
      config: config.config || {}
    }));
  }
}

// 导出单例实例
export default SourcePoolManager.getInstance();
