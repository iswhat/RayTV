/**
 * 配置源服务实现 | Config Source Service Implementation
 * 壳应用的核心服务，负责配置源的加载、解析和管理 | Core service for shell app, responsible for config source loading, parsing and management
 */
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import HttpService from '../HttpService';
import CacheService from '../cache/CacheService';
import ApiResponse from '../../data/dto/ApiResponse';
import {
  IConfigSourceService,
  ConfigSource,
  ParsedConfig,
  MediaSite,
  ParserConfig,
  RuleConfig,
  LiveSource,
  SpiderConfig,
  StyleConfig
} from '../interfaces/IConfigSourceService';

// 常量定义 | Constants definition
const TAG = 'ConfigSourceService';
const CONFIG_SOURCE_STORAGE_KEY = 'config_sources';
const DEFAULT_CONFIG_SOURCES = [
  {
    id: 'default_a',
    name: '默认配置源A',
    url: 'https://list.eoeoo.com/base2/a.json',
    type: 'json' as const,
    version: '1.0.0',
    priority: 1,
    isActive: true
  },
  {
    id: 'default_b',
    name: '默认配置源B',
    url: 'https://q.uoouo.com/dianshi.json',
    type: 'json' as const,
    version: '1.0.0',
    priority: 2,
    isActive: true
  }
];

/**
 * 配置源服务类
 * 
 * 壳应用的核心服务，负责配置源的加载、解析和管理。
 * 提供配置源的添加、删除、更新、健康检查等功能，支持缓存和优先级管理。
 * 
 * @example
 * ```typescript
 * // 获取ConfigSourceService实例
 * import configSourceService from './service/config/ConfigSourceService';
 * 
 * // 初始化服务
 * await configSourceService.initialize();
 * 
 * // 加载配置源
 * const result = await configSourceService.loadConfigSource('https://example.com/config.json');
 * if (result.isSuccess()) {
 *   console.log('Config source loaded:', result.data);
 * }
 * ```
 */
export class ConfigSourceService implements IConfigSourceService {
  private static instance: ConfigSourceService | null = null;
  private httpService: HttpService;
  private cacheService: CacheService;
  private logger: Logger;
  private initialized: boolean = false;

  /**
   * 获取单例实例
   * 
   * 实现了单例模式，确保全局只有一个ConfigSourceService实例。
   * 
   * @returns ConfigSourceService单例实例
   * @example
   * ```typescript
   * const configSourceService = ConfigSourceService.getInstance();
   * ```
   */
  public static getInstance(): ConfigSourceService {
    if (!ConfigSourceService.instance) {
      ConfigSourceService.instance = new ConfigSourceService();
    }
    return ConfigSourceService.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.httpService = HttpService.getInstance();
    this.cacheService = CacheService.getInstance();
    this.logger = new Logger(TAG);
  }

  /**
   * 初始化服务
   * 
   * 初始化配置源服务，加载默认配置源。
   * 
   * @returns Promise<void>
   * @throws Error - 当初始化失败时抛出错误
   * @example
   * ```typescript
   * await configSourceService.initialize();
   * console.log('ConfigSourceService initialized');
   * ```
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 加载默认配置源 | Load default config sources
      await this.loadDefaultSources();
      this.initialized = true;
      this.logger.info('ConfigSourceService initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize ConfigSourceService', error);
      throw error;
    }
  }

  /**
   * 加载默认配置源 | Load default config sources
   */
  private async loadDefaultSources(): Promise<void> {
    try {
      const storedSources = await StorageUtil.getItem(CONFIG_SOURCE_STORAGE_KEY);
      if (!storedSources) {
        // 如果没有存储的配置源，则使用默认配置 | If no stored sources, use default config
        await StorageUtil.setItem(CONFIG_SOURCE_STORAGE_KEY, DEFAULT_CONFIG_SOURCES);
        this.logger.info('Default config sources loaded');
      }
    } catch (error) {
      this.logger.error('Failed to load default sources', error);
      throw error;
    }
  }

  /**
   * 加载远程配置源
   * 
   * 从指定URL加载配置源，支持缓存和格式验证。
   * 
   * @param url 配置源URL
   * @returns Promise<ApiResponse<ConfigSource>> - 包含配置源的API响应
   * @example
   * ```typescript
   * const result = await configSourceService.loadConfigSource('https://example.com/config.json');
   * if (result.isSuccess()) {
   *   console.log('Config source loaded:', result.data);
   * } else {
   *   console.error('Failed to load config source:', result.message);
   * }
   * ```
   */
  public async loadConfigSource(url: string): Promise<ApiResponse<ConfigSource>> {
    try {
      this.logger.info(`Loading config source from: ${url}`);
      
      // 检查缓存 | Check cache first
      const cacheKey = `config_${this.generateUrlHash(url)}`;
      const cachedResult = await this.cacheService.get<ConfigSource>(cacheKey);
      
      if (cachedResult) {
        this.logger.info(`Returning cached config for: ${url}`);
        return ApiResponse.success(cachedResult);
      }

      // 发送HTTP请求 | Send HTTP request
      const response = await this.httpService.get(url, {
        timeout: 15000,
        headers: {
          'User-Agent': 'RayTV/ShellApp ConfigLoader',
          'Accept': 'application/json,text/plain,*/*'
        }
      });

      if (!response || typeof response !== 'object') {
        return ApiResponse.failure('Invalid response from config source');
      }

      // 验证配置格式 | Validate config format
      if (!this.validateConfigFormat(response)) {
        return ApiResponse.failure('Invalid config format received');
      }

      // 解析配置内容 | Parse config content
      const parsedConfig = await this.parseConfigContent(JSON.stringify(response));
      if (!parsedConfig.isSuccess()) {
        return ApiResponse.failure(`Config parsing failed: ${parsedConfig.message}`);
      }

      // 创建配置源对象 | Create config source object
      const configSource: ConfigSource = {
        id: this.generateSourceId(url),
        name: this.extractSourceName(url, parsedConfig.data!),
        url,
        type: 'json',
        version: this.extractVersion(parsedConfig.data!),
        lastUpdated: Date.now(),
        isActive: true,
        priority: this.calculatePriority(url),
        metadata: {
          siteCount: parsedConfig.data!.sites.length,
          parserCount: parsedConfig.data!.parsers.length,
          lastChecked: Date.now(),
          healthStatus: 'healthy'
        }
      };

      // 缓存结果 | Cache the result
      await this.cacheService.set(cacheKey, configSource, 3600000); // 1小时缓存 | 1 hour cache

      this.logger.info(`Successfully loaded config source: ${configSource.name}`);
      return ApiResponse.success(configSource);

    } catch (error) {
      this.logger.error(`Failed to load config source from ${url}`, error);
      return ApiResponse.failure(`Network error: ${(error as Error).message}`);
    }
  }

  /**
   * 解析配置内容
   * 
   * 解析配置源的JSON内容，验证格式并提取各个部分。
   * 
   * @param content 配置内容字符串
   * @returns Promise<ApiResponse<ParsedConfig>> - 包含解析结果的API响应
   * @example
   * ```typescript
   * const configContent = '{"sites": [{"key": "site1", "name": "Site 1", "api": "https://example.com/api"}]}';
   * const result = await configSourceService.parseConfigContent(configContent);
   * if (result.isSuccess()) {
   *   console.log('Config parsed successfully:', result.data);
   * }
   * ```
   */
  public async parseConfigContent(content: string): Promise<ApiResponse<ParsedConfig>> {
    try {
      let configData: any;
      
      // 尝试解析JSON | Try to parse JSON
      try {
        configData = JSON.parse(content);
      } catch (jsonError) {
        this.logger.error('Failed to parse config as JSON', jsonError);
        return ApiResponse.failure('Invalid JSON format');
      }

      // 验证必需字段 | Validate required fields
      if (!this.validateRequiredFields(configData)) {
        return ApiResponse.failure('Missing required config fields');
      }

      // 解析各个部分 | Parse different parts
      const parsedConfig: ParsedConfig = {
        sites: this.parseSites(configData.sites || []),
        parsers: this.parseParsers(configData.parses || []),
        rules: this.parseRules(configData.rules || []),
        wallpapers: this.parseWallpapers(configData.wallpaper),
        lives: this.parseLiveSources(configData.lives || []),
        spider: this.parseSpider(configData.spider)
      };

      return ApiResponse.success(parsedConfig);

    } catch (error) {
      this.logger.error('Failed to parse config content', error);
      return ApiResponse.failure(`Parsing error: ${(error as Error).message}`);
    }
  }

  /**
   * 验证配置格式
   * 
   * 验证配置源的格式是否正确，检查必需字段。
   * 
   * @param config 配置对象
   * @returns boolean - 配置格式是否有效
   * @example
   * ```typescript
   * const config = { sites: [{ key: "site1", name: "Site 1", api: "https://example.com/api" }] };
   * const isValid = configSourceService.validateConfigFormat(config);
   * console.log('Config format is valid:', isValid);
   * ```
   */
  public validateConfigFormat(config: any): boolean {
    if (!config || typeof config !== 'object') {
      return false;
    }

    // 检查必需字段 | Check required fields
    const requiredFields = ['sites'];
    return requiredFields.every(field => field in config);
  }

  /**
   * 获取所有激活的配置源
   * 
   * 获取所有处于激活状态的配置源，并按优先级排序。
   * 
   * @returns Promise<ApiResponse<ConfigSource[]>> - 包含激活配置源列表的API响应
   * @example
   * ```typescript
   * const result = await configSourceService.getActiveSources();
   * if (result.isSuccess()) {
   *   console.log('Active config sources:', result.data);
   * }
   * ```
   */
  public async getActiveSources(): Promise<ApiResponse<ConfigSource[]>> {
    try {
      const allSources = await StorageUtil.getItem<ConfigSource[]>(CONFIG_SOURCE_STORAGE_KEY) || [];
      const activeSources = allSources.filter(source => source.isActive);
      
      // 按优先级排序 | Sort by priority
      activeSources.sort((a, b) => a.priority - b.priority);
      
      return ApiResponse.success(activeSources);
    } catch (error) {
      this.logger.error('Failed to get active sources', error);
      return ApiResponse.failure(`Storage error: ${(error as Error).message}`);
    }
  }

  /**
   * 添加新的配置源
   * 
   * 添加新的配置源到存储中，包括URL验证和重复检查。
   * 
   * @param url 配置源URL
   * @param name 配置源名称
   * @returns Promise<ApiResponse<ConfigSource>> - 包含新配置源的API响应
   * @example
   * ```typescript
   * const result = await configSourceService.addSource('https://example.com/config.json', 'Example Config');
   * if (result.isSuccess()) {
   *   console.log('Config source added:', result.data);
   * } else {
   *   console.error('Failed to add config source:', result.message);
   * }
   * ```
   */
  public async addSource(url: string, name: string): Promise<ApiResponse<ConfigSource>> {
    try {
      // 验证URL格式 | Validate URL format
      if (!this.isValidUrl(url)) {
        return ApiResponse.failure('Invalid URL format');
      }

      // 检查是否已存在 | Check if already exists
      const existingSources = await StorageUtil.getItem<ConfigSource[]>(CONFIG_SOURCE_STORAGE_KEY) || [];
      if (existingSources.some(source => source.url === url)) {
        return ApiResponse.failure('Config source already exists');
      }

      // 创建新的配置源 | Create new config source
      const newSource: ConfigSource = {
        id: this.generateSourceId(url),
        name,
        url,
        type: 'json',
        version: '1.0.0',
        lastUpdated: Date.now(),
        isActive: true,
        priority: existingSources.length + 1
      };

      // 保存到存储 | Save to storage
      existingSources.push(newSource);
      await StorageUtil.setItem(CONFIG_SOURCE_STORAGE_KEY, existingSources);

      this.logger.info(`Added new config source: ${name}`);
      return ApiResponse.success(newSource);

    } catch (error) {
      this.logger.error('Failed to add config source', error);
      return ApiResponse.failure(`Add failed: ${(error as Error).message}`);
    }
  }

  /**
   * 删除配置源
   * 
   * 根据ID删除指定的配置源。
   * 
   * @param id 配置源ID
   * @returns Promise<ApiResponse<boolean>> - 包含删除结果的API响应
   * @example
   * ```typescript
   * const result = await configSourceService.removeSource('src_abc123_1234567890');
   * if (result.isSuccess()) {
   *   console.log('Config source removed successfully');
   * } else {
   *   console.error('Failed to remove config source:', result.message);
   * }
   * ```
   */
  public async removeSource(id: string): Promise<ApiResponse<boolean>> {
    try {
      const sources = await StorageUtil.getItem<ConfigSource[]>(CONFIG_SOURCE_STORAGE_KEY) || [];
      const filteredSources = sources.filter(source => source.id !== id);
      
      if (filteredSources.length === sources.length) {
        return ApiResponse.failure('Config source not found');
      }

      await StorageUtil.setItem(CONFIG_SOURCE_STORAGE_KEY, filteredSources);
      this.logger.info(`Removed config source: ${id}`);
      return ApiResponse.success(true);

    } catch (error) {
      this.logger.error('Failed to remove config source', error);
      return ApiResponse.failure(`Remove failed: ${(error as Error).message}`);
    }
  }

  /**
   * 更新配置源状态
   * 
   * 更新指定配置源的激活状态。
   * 
   * @param id 配置源ID
   * @param isActive 是否激活
   * @returns Promise<ApiResponse<boolean>> - 包含更新结果的API响应
   * @example
   * ```typescript
   * const result = await configSourceService.updateSourceStatus('src_abc123_1234567890', true);
   * if (result.isSuccess()) {
   *   console.log('Config source status updated successfully');
   * } else {
   *   console.error('Failed to update config source status:', result.message);
   * }
   * ```
   */
  public async updateSourceStatus(id: string, isActive: boolean): Promise<ApiResponse<boolean>> {
    try {
      const sources = await StorageUtil.getItem<ConfigSource[]>(CONFIG_SOURCE_STORAGE_KEY) || [];
      const sourceIndex = sources.findIndex(source => source.id === id);
      
      if (sourceIndex === -1) {
        return ApiResponse.failure('Config source not found');
      }

      sources[sourceIndex].isActive = isActive;
      sources[sourceIndex].lastUpdated = Date.now();
      
      await StorageUtil.setItem(CONFIG_SOURCE_STORAGE_KEY, sources);
      this.logger.info(`Updated config source status: ${id} -> ${isActive}`);
      return ApiResponse.success(true);

    } catch (error) {
      this.logger.error('Failed to update config source status', error);
      return ApiResponse.failure(`Update failed: ${(error as Error).message}`);
    }
  }

  /**
   * 获取解析后的媒体站点
   * 
   * 获取指定配置源解析后的媒体站点列表，支持缓存。
   * 
   * @param sourceId 配置源ID
   * @returns Promise<ApiResponse<MediaSite[]>> - 包含媒体站点列表的API响应
   * @example
   * ```typescript
   * const result = await configSourceService.getMediaSites('src_abc123_1234567890');
   * if (result.isSuccess()) {
   *   console.log('Media sites:', result.data);
   * } else {
   *   console.error('Failed to get media sites:', result.message);
   * }
   * ```
   */
  public async getMediaSites(sourceId: string): Promise<ApiResponse<MediaSite[]>> {
    try {
      const sources = await StorageUtil.getItem<ConfigSource[]>(CONFIG_SOURCE_STORAGE_KEY) || [];
      const source = sources.find(s => s.id === sourceId);
      
      if (!source) {
        return ApiResponse.failure('Config source not found');
      }

      const result = await this.loadConfigSource(source.url);
      if (!result.isSuccess()) {
        return ApiResponse.failure(`Failed to load source: ${result.message}`);
      }

      const cacheKey = `parsed_sites_${sourceId}`;
      const cachedSites = await this.cacheService.get<MediaSite[]>(cacheKey);
      
      if (cachedSites) {
        return ApiResponse.success(cachedSites);
      }

      const parsedResult = await this.parseConfigContent(JSON.stringify(result.data));
      if (parsedResult.isSuccess()) {
        const sites = parsedResult.data!.sites;
        await this.cacheService.set(cacheKey, sites, 1800000); // 30分钟缓存 | 30 minutes cache
        return ApiResponse.success(sites);
      } else {
        return ApiResponse.failure(`Parse failed: ${parsedResult.message}`);
      }

    } catch (error) {
      this.logger.error('Failed to get media sites', error);
      return ApiResponse.failure(`Get sites failed: ${(error as Error).message}`);
    }
  }

  /**
   * 检查配置源健康状态
   * 
   * 检查指定配置源的健康状态，包括响应时间和可用性。
   * 
   * @param id 配置源ID
   * @returns Promise<ApiResponse<'healthy' | 'warning' | 'error'>> - 包含健康状态的API响应
   * @example
   * ```typescript
   * const result = await configSourceService.checkSourceHealth('src_abc123_1234567890');
   * if (result.isSuccess()) {
   *   console.log('Config source health status:', result.data);
   * } else {
   *   console.error('Failed to check config source health:', result.message);
   * }
   * ```
   */
  public async checkSourceHealth(id: string): Promise<ApiResponse<'healthy' | 'warning' | 'error'>> {
    try {
      const sources = await StorageUtil.getItem<ConfigSource[]>(CONFIG_SOURCE_STORAGE_KEY) || [];
      const source = sources.find(s => s.id === id);
      
      if (!source) {
        return ApiResponse.failure('Config source not found');
      }

      const startTime = Date.now();
      const result = await this.loadConfigSource(source.url);
      const responseTime = Date.now() - startTime;

      let healthStatus: 'healthy' | 'warning' | 'error' = 'healthy';

      if (!result.isSuccess()) {
        healthStatus = 'error';
      } else if (responseTime > 5000) {
        healthStatus = 'warning';
      }

      // 更新元数据 | Update metadata
      source.metadata = {
        ...source.metadata,
        lastChecked: Date.now(),
        healthStatus
      };

      await StorageUtil.setItem(CONFIG_SOURCE_STORAGE_KEY, sources);
      
      return ApiResponse.success(healthStatus);

    } catch (error) {
      this.logger.error('Failed to check source health', error);
      return ApiResponse.failure(`Health check failed: ${(error as Error).message}`);
    }
  }

  // 私有辅助方法 | Private helper methods

  private validateRequiredFields(config: any): boolean {
    return 'sites' in config;
  }

  private parseSites(sites: any[]): MediaSite[] {
    return sites.map(site => ({
      key: site.key || '',
      name: site.name || '',
      type: site.type || 0,
      api: site.api || '',
      searchable: site.searchable !== undefined ? Boolean(site.searchable) : false,
      quickSearch: site.quickSearch !== undefined ? Boolean(site.quickSearch) : false,
      filterable: site.filterable !== undefined ? Boolean(site.filterable) : false,
      ext: site.ext,
      jar: site.jar,
      playerType: site.playerType,
      headers: site.header || {},
      timeout: site.timeout,
      changeable: site.changeable !== undefined ? Boolean(site.changeable) : true,
      style: site.style ? {
        type: site.style.type || 'list',
        ratio: site.style.ratio
      } : undefined
    })).filter(site => site.key && site.name && site.api);
  }

  private parseParsers(parsers: any[]): ParserConfig[] {
    return parsers.map(parser => ({
      name: parser.name || '',
      type: parser.type || 0,
      url: parser.url || '',
      ext: parser.ext,
      flag: parser.flag,
      header: parser.header || {}
    })).filter(parser => parser.name && parser.url);
  }

  private parseRules(rules: any[]): RuleConfig[] {
    return rules.map(rule => ({
      name: rule.name || '',
      hosts: Array.isArray(rule.hosts) ? rule.hosts : [],
      regex: rule.regex,
      script: rule.script
    }));
  }

  private parseWallpapers(wallpaper: string | string[]): string[] {
    if (Array.isArray(wallpaper)) {
      return wallpaper.filter(url => typeof url === 'string' && url.trim());
    } else if (typeof wallpaper === 'string' && wallpaper.trim()) {
      return [wallpaper.trim()];
    }
    return [];
  }

  private parseLiveSources(lives: any[]): LiveSource[] {
    return lives.map(live => ({
      name: live.name || '',
      type: live.type || 0,
      url: live.url || '',
      playerType: live.playerType,
      ua: live.ua,
      timeout: live.timeout,
      epg: live.epg,
      logo: live.logo,
      boot: live.boot !== undefined ? Boolean(live.boot) : false
    })).filter(live => live.name && live.url);
  }

  private parseSpider(spider: string | undefined): SpiderConfig | undefined {
    if (!spider || typeof spider !== 'string') {
      return undefined;
    }

    const parts = spider.split(';');
    if (parts.length >= 3 && parts[0] && parts[2]) {
      return {
        path: parts[0],
        md5: parts[2]
      };
    }
    return undefined;
  }

  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }

  private generateUrlHash(url: string): string {
    return btoa(url).substring(0, 16);
  }

  private generateSourceId(url: string): string {
    return `src_${this.generateUrlHash(url)}_${Date.now()}`;
  }

  private extractSourceName(url: string, config: ParsedConfig): string {
    // 尝试从配置中提取名称 | Try to extract name from config
    if (config.sites && config.sites.length > 0) {
      return `${config.sites[0].name}等${config.sites.length}个源`;
    }
    // 从URL提取 | Extract from URL
    try {
      const urlObj = new URL(url);
      return urlObj.hostname.replace('www.', '');
    } catch {
      return '未知配置源';
    }
  }

  private extractVersion(config: ParsedConfig): string {
    // 简单的版本提取逻辑 | Simple version extraction logic
    return '1.0.' + (config.sites?.length || 0);
  }

  private calculatePriority(url: string): number {
    // 基于URL的简单优先级计算 | Simple priority calculation based on URL
    if (url.includes('eoeoo.com')) return 1;
    if (url.includes('uoouo.com')) return 2;
    return 10;
  }
}

// 导出单例实例 | Export singleton instance
export default ConfigSourceService.getInstance();