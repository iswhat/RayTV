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
import { LiveChannelWithSource, LiveCategory } from '../live/LiveChannelTypes';
import { ParsedConfig, ParserConfig, MediaSite, LiveSource } from '../interfaces/IConfigSourceService';

// ========================================
// 数据类型定义
// ========================================

/**
 * NAS设备配置接口
 */
export interface NasConfig {
  deviceId: string;            // NAS设备ID
  protocol: string;            // 协议类型 (smb, huawei, webdav, dlna)
  address: string;             // 设备地址
  port?: number;               // 端口
  username?: string;           // 用户名
  password?: string;           // 密码
  share?: string;              // SMB共享名称
  domain?: string;             // 域 (SMB)
}

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
  nasConfig?: NasConfig;
  
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
export { toLiveChannelWithSource, extendLiveChannel, isValidLiveChannel, createLiveChannelWithSource } from '../live/LiveChannelTypes';

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
 * 壁纸数据接口
 */
interface WallpaperData {
  id: string;
  name: string;
  url: string;
  thumbnail?: string;
  aspectRatio?: string;
}

/**
 * 广告过滤规则数据接口
 */
interface AdBlockRuleData {
  id?: string;
  pattern: string;
  type: 'domain' | 'url' | 'element';
  enabled?: boolean;
}

/**
 * 解码器配置数据接口
 */
interface DecoderConfigData {
  id?: string;
  name: string;
  type: string;
  config?: Record<string, string>;
}

/**
 * 分类统计数据接口
 */
interface CategoryStats {
  count: number;
  sources: Set<string>;
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
    
    // 更新 sourceMap
    const entries = this.sourceMap.entries();
    for (const entry of entries) {
      const siteKey: string = entry[0];
      const sid: string = entry[1];
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
    const categoryMap = new Map<string, CategoryStats>();
    
    this.channels.forEach(channel => {
      const existing = categoryMap.get(channel.group);
      if (existing) {
        existing.count++;
        existing.sources.add(channel.sourceId);
      } else {
        const newStats: CategoryStats = {
          count: 1,
          sources: new Set([channel.sourceId])
        };
        categoryMap.set(channel.group, newStats);
      }
    });
    
    const categoryEntries = Array.from(categoryMap.entries());
    const categories: LiveCategory[] = [];
    for (let index = 0; index < categoryEntries.length; index++) {
      const entry = categoryEntries[index];
      const name: string = entry[0];
      const data = entry[1];
      const category: LiveCategory = {
        id: `cat_${index}`,
        name,
        channelCount: data.count,
        sources: Array.from(data.sources)
      };
      categories.push(category);
    }
    this.categories = categories;
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
    const rulesWithSource: AdBlockRule[] = [];
    for (const rule of rules) {
      const ruleWithSource: AdBlockRule = {
        id: `${sourceId}_${rule.id}`,
        pattern: rule.pattern,
        type: rule.type,
        enabled: rule.enabled
      };
      rulesWithSource.push(ruleWithSource);
    }
    
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
    
    // 添加新配置 (添加来源标识)
    const configsWithSource: DecoderConfig[] = [];
    for (const config of configs) {
      const configWithSource: DecoderConfig = {
        id: `${sourceId}_${config.id}`,
        name: config.name,
        type: config.type,
        config: config.config
      };
      configsWithSource.push(configWithSource);
    }
    
    this.configs = this.configs.concat(configsWithSource);
    configsWithSource.forEach(config => {
      this.sources.set(config.id, sourceId);
    });
  }
  
  removeConfigsBySource(sourceId: string): void {
    this.configs = this.configs.filter(config => !config.id.startsWith(`${sourceId}_`));
    
    const entries = this.sources.entries();
    for (const entry of entries) {
      const configId: string = entry[0];
      const sid: string = entry[1];
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

const TAG: string = 'SourcePoolManager';

/**
 * 源池管理器
 *
 * 负责将各个网络源的内容提取到统一的使用池中
 */
export class SourcePoolManager {
  private static instance: SourcePoolManager | null = null;
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
      Logger.info(TAG, 'Initializing SourcePoolManager');
      
      // 加载所有启用的源
      const sources: ConfigSource[] = await this.configSourceService.getAllSources();
      const activeSources: ConfigSource[] = sources.filter((s: ConfigSource): boolean => s.isActive);
      
      Logger.info(TAG, `Found ${activeSources.length} active sources`);
      
      // 并行加载所有源，提高启动速度
      if (activeSources.length > 0) {
        const loadPromises: Promise<void>[] = activeSources.map((source: ConfigSource) =>
          this.loadFromSource(source as unknown as NetworkSourceConfig).catch((error: unknown) => {
            const err: Error = error instanceof Error ? error : new Error(String(error));
            Logger.error(TAG, `Failed to load source ${source.id}, continuing with other sources`, err);
            // 单个源失败不影响其他源的加载
          })
        );

        await Promise.all(loadPromises);
      }

      this.initialized = true;
      Logger.info(TAG, 'SourcePoolManager initialized successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to initialize SourcePoolManager', err);
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
      Logger.info(TAG, `Source ${source.id} is not active, skipping`);
      return;
    }
    
    try {
      Logger.info(TAG, `Loading content from source: ${source.name} (${source.id})`);
      
      const usage = source.contentUsage;
      
      // 根据内容开关选择性加载
      if (usage.vodSites) {
        const vodSites = await this.retryWithBackoff(() => this.loadVodSites(source));
        this.vodPool.addSites(vodSites);
        Logger.info(TAG, `Loaded ${vodSites.length} VOD sites from source ${source.id}`);
      }
      
      if (usage.liveChannels) {
        const liveChannels = await this.retryWithBackoff(() => this.loadLiveChannels(source));
        this.livePool.addChannels(liveChannels);
        Logger.info(TAG, `Loaded ${liveChannels.length} live channels from source ${source.id}`);
      }
      
      if (usage.wallpapers) {
        const wallpapers = await this.retryWithBackoff(() => this.loadWallpapers(source));
        this.wallpaperPool.addWallpapers(wallpapers);
        Logger.info(TAG, `Loaded ${wallpapers.length} wallpapers from source ${source.id}`);
      }
      
      if (usage.adBlockRules) {
        const rules = await this.retryWithBackoff(() => this.loadAdBlockRules(source));
        this.adBlockRules.addRules(rules, source.id);
        Logger.info(TAG, `Loaded ${rules.length} ad block rules from source ${source.id}`);
      }
      
      if (usage.decoderConfigs) {
        const configs = await this.retryWithBackoff(() => this.loadDecoderConfigs(source));
        this.decoderConfigs.addConfigs(configs, source.id);
        Logger.info(TAG, `Loaded ${configs.length} decoder configs from source ${source.id}`);
      }
      
      Logger.info(TAG, `Successfully loaded content from source: ${source.name}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to load content from source ${source.id}`, err);
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
    let lastError: Error = new Error('Unknown error');

    for (let i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));
        Logger.warn(TAG, `Attempt ${i + 1} failed, retrying...`, lastError);

        // 指数退避
        const delay = Math.pow(2, i) * 1000;
        await new Promise<void>((resolve: () => void) => {
          setTimeout(() => {
            resolve();
          }, delay);
        });
      }
    }

    throw lastError;
  }
  
  /**
   * 重新构建所有池
   * 
   * @param sources 网络源配置列表
   */
  public async rebuildAllPools(sources: NetworkSourceConfig[]): Promise<void> {
    Logger.info(TAG, 'Rebuilding all pools');
    
    try {
      // 清空所有池
      this.vodPool.clear();
      this.livePool.clear();
      this.wallpaperPool.clear();
      this.adBlockRules.clear();
      this.decoderConfigs.clear();
      
      // 从所有启用的源重新加载
      const activeSources = sources.filter(s => s.isActive);
      Logger.info(TAG, `Rebuilding from ${activeSources.length} active sources`);
      
      // 并行加载所有源，提高性能
      if (activeSources.length > 0) {
        const loadPromises: Promise<void>[] = activeSources.map((source: NetworkSourceConfig) =>
          this.loadFromSource(source).catch((error: unknown) => {
            const err: Error = error instanceof Error ? error : new Error(String(error));
            Logger.error(TAG, `Failed to load source ${source.id} during rebuild, continuing with other sources`, err);
            // 单个源失败不影响其他源的加载
          })
        );
        
        await Promise.all(loadPromises);
      }
      
      Logger.info(TAG, 'All pools rebuilt successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to rebuild pools', err);
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
    // 从配置源服务获取解析器配置
    // Get parser configs from config source service
    const allParsers: ParserConfig[] = [];
    
    // 遍历所有站点，收集解析器配置
    // Iterate all sites and collect parser configs
    this.vodPool.getAllSites().forEach((_site: VodSiteWithSource) => {
      // MediaSite 接口中没有 parsers 属性，这里需要从其他地方获取
      // MediaSite interface doesn't have parsers property, need to get from elsewhere
    });
    
    // 去重 | Deduplicate
    const uniqueParsers: Map<string, ParserConfig> = new Map<string, ParserConfig>();
    allParsers.forEach((parser: ParserConfig) => {
      const key: string = `${parser.name}_${parser.url}`;
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
    // 从 ConfigSourceService 加载解析后的配置
    const parsedConfig: ParsedConfig | null = await this.configSourceService.getParsedConfig(source.url);
    
    const hasNoSites: boolean = !parsedConfig || !parsedConfig.sites || parsedConfig.sites.length === 0;
    if (hasNoSites) {
      return [];
    }

    const vodSites: VodSiteWithSource[] = parsedConfig!.sites!.map((site: MediaSite): VodSiteWithSource => {
      const vodSite: VodSiteWithSource = {
        siteKey: site.key || site.name,
        name: site.name,
        url: site.api,
        sourceId: source.id,
        sourceName: source.name,
        sourcePriority: source.priority,
        sourceTags: source.tags,
        categories: [],
        flags: []
      };
      return vodSite;
    });
    
    return vodSites;
  }
  
  private async loadLiveChannels(source: NetworkSourceConfig): Promise<LiveChannelWithSource[]> {
    // 从 ConfigSourceService 加载解析后的配置
    const parsedConfig: ParsedConfig | null = await this.configSourceService.getParsedConfig(source.url);

    const hasNoChannels: boolean = !parsedConfig || !parsedConfig.lives || parsedConfig.lives.length === 0;
    if (hasNoChannels) {
      return [];
    }

    const channels: LiveChannelWithSource[] = [];

    // 直接使用 lives 数组中的每个 LiveSource 作为频道
    parsedConfig!.lives!.forEach((live: LiveSource) => {
      const channel: LiveChannelWithSource = {
        id: `${source.id}_${live.name}`,
        name: live.name,
        url: live.url,
        group: live.type?.toString() || '默认', // 使用 type 作为 group
        sourceId: source.id,
        sourceName: source.name,
        logo: live.logo,
        epgUrl: live.epg
      };
      channels.push(channel);
    });
    
    return channels;
  }
  
  private async loadWallpapers(source: NetworkSourceConfig): Promise<WallpaperWithSource[]> {
    // 从 ConfigSourceService 加载壁纸数据
    const parsedConfig: ParsedConfig | null = await this.configSourceService.getParsedConfig(source.url);
    
    const hasNoWallpapers: boolean = !parsedConfig || !parsedConfig.wallpapers || parsedConfig.wallpapers.length === 0;
    if (hasNoWallpapers) {
      return [];
    }

    return parsedConfig!.wallpapers!.map((wallpaperUrl: string): WallpaperWithSource => {
      const result: WallpaperWithSource = {
        id: `${source.id}_${wallpaperUrl}`,
        name: wallpaperUrl,
        url: wallpaperUrl,
        sourceId: source.id,
        sourceName: source.name
      };
      return result;
    });
  }
  
  private async loadAdBlockRules(_source: NetworkSourceConfig): Promise<AdBlockRule[]> {
    // AdBlockRules are not part of ParsedConfig interface; return empty by default
    return [];
  }

  private async loadDecoderConfigs(_source: NetworkSourceConfig): Promise<DecoderConfig[]> {
    // DecoderConfigs are not part of ParsedConfig interface; return empty by default
    return [];
  }
}

// 导出单例实例
export default SourcePoolManager.getInstance();
