/**
 * 爬虫加载器基类
 * 定义爬虫加载器的核心接口和抽象方法
 */

import Logger from '../../../common/util/Logger';
import { Site, LoaderType } from '../../data/bean/Site';

// 方法参数接口定义
export interface CategoryParams {
  url: string;
  page?: number;
  pageSize?: number;
  filters?: Record<string, string | number | boolean>;
}

export interface DetailParams {
  url: string;
}

export interface SearchParams {
  keyword: string;
  page?: number;
  pageSize?: number;
}

export interface PlayParams {
  url: string;
  source?: string;
  episode?: string;
}

export interface LiveParams {
  category?: string;
}

// 结果类型接口
export interface CrawlerResult<T> {
  code: number;
  message: string;
  data?: T;
}

export interface CategoryItem {
  id?: string;
  name?: string;
  url?: string;
  icon?: string;
}

export interface RecommendationItem {
  id?: string;
  title?: string;
  cover?: string;
  url?: string;
  type?: string;
}

export interface BannerItem {
  id?: string;
  title?: string;
  image?: string;
  url?: string;
  type?: string;
}

export interface HomeResult {
  categories?: CategoryItem[];
  recommendations?: RecommendationItem[];
  banners?: BannerItem[];
}

export interface MediaItem {
  id?: string;
  title?: string;
  cover?: string;
  url?: string;
  type?: string;
  source?: string;
  updateInfo?: string;
  playCount?: number;
}

export interface CategoryResult {
  items?: MediaItem[];
  total?: number;
  hasMore?: boolean;
  page?: number;
}

export interface SourceItem {
  id?: string;
  name?: string;
  url?: string;
}

export interface EpisodeItem {
  id?: string;
  title?: string;
  url?: string;
  episode?: string;
  isCurrent?: boolean;
}

export interface DetailResult {
  title?: string;
  cover?: string;
  description?: string;
  sources?: SourceItem[];
  episodes?: EpisodeItem[];
}

export interface SearchResult {
  items?: MediaItem[];
  total?: number;
  hasMore?: boolean;
  page?: number;
}

export interface PlayResult {
  urls?: string[];
  source?: string;
  episode?: string;
}

export interface LiveChannel {
  id?: string;
  title?: string;
  cover?: string;
  url?: string;
  category?: string;
  online?: boolean;
  siteKey?: string;
  siteName?: string;
}

export interface LiveResult {
  categories?: CategoryItem[];
  channels?: LiveChannel[];
}

// 加载器状态接口
export interface LoaderStatus {
  initialized: boolean;
  destroyed: boolean;
  errorCount: number;
  maxErrorCount: number;
  initializedTime: number;
  lastInvokeTime: number;
  site: Site;
}

// 站点更新配置接口
export interface SiteAuthConfig {
  username?: string;
  password?: string;
  token?: string;
}

export interface SiteConfigItem {
  key?: string;
  value?: string | number | boolean;
  type?: string;
  label?: string;
  required?: boolean;
}

export interface SitePerformanceConfig {
  timeout?: number;
  retryCount?: number;
  concurrency?: number;
}

export interface SiteLifecycleConfig {
  initDelay?: number;
  destroyDelay?: number;
}

export interface SiteCertificateConfig {
  cert?: string;
  key?: string;
  ca?: string;
}

export interface SiteUpdateConfig {
  key?: string;
  name?: string;
  url?: string;
  type?: string;
  loaderType?: string;
  api?: string;
  logo?: string;
  description?: string;
  siteAuth?: SiteAuthConfig;
  headers?: Record<string, string>;
  config?: Record<string, string | number | boolean>;
  configItems?: SiteConfigItem[];
  searchConfig?: Record<string, string | number | boolean>;       
  filterConfig?: Record<string, string | number | boolean>;       
  performanceConfig?: SitePerformanceConfig;
  version?: string;
  stats?: Record<string, string | number | boolean>;
  lifecycle?: SiteLifecycleConfig;
  enabled?: boolean;
  order?: number;
  group?: string;
  tags?: string[];
  customCode?: string;
  sandboxEnabled?: boolean;
  allowThirdParty?: boolean;
  createdAt?: number;
  updatedAt?: number;
  lastUsedAt?: number;
  userAgent?: string;
  referer?: string;
  proxy?: boolean;
  encoding?: string;
  charset?: string;
  certificate?: SiteCertificateConfig;
}

export abstract class BaseLoader {
  protected readonly TAG: string = `BaseLoader-${this.constructor.name}`;
  protected site: Site;
  protected isInitialized: boolean = false;
  protected isDestroyed: boolean = false;
  protected errorCount: number = 0;
  protected maxErrorCount: number = 5;
  protected initializedTime: number = 0;
  protected lastInvokeTime: number = 0;

  /**
   * 构造函数
   * @param site 站点信息
   */
  constructor(site: Site) {
    this.site = site;
    Logger.info(this.TAG, `Creating loader for site: ${site.name} (${site.key})`);
  }

  /**
   * 初始化加载器
   * @returns Promise<boolean> 初始化是否成功
   */
  public async init(): Promise<boolean> {
    if (this.isDestroyed) {
      Logger.error(this.TAG, 'Cannot initialize destroyed loader');
      return false;
    }
    
    if (!this.isInitialized) {
      try {
        Logger.info(this.TAG, `Initializing loader for site: ${this.site.name}`);
        await this.onInit();
        this.isInitialized = true;
        this.initializedTime = Date.now();
        this.errorCount = 0;
        Logger.info(this.TAG, `Loader initialized successfully for site: ${this.site.name}`);
        return true;
      } catch (error) {
        Logger.error(this.TAG, `Failed to initialize loader: ${(error as Error).message}`);
        this.handleError();
        return false;
      }
    }
    return true;
  }

  /**
   * 销毁加载器，释放资源
   */
  public async destroy(): Promise<void> {
    if (!this.isDestroyed) {
      try {
        Logger.info(this.TAG, `Destroying loader for site: ${this.site.name}`);
        await this.onDestroy();
        this.isDestroyed = true;
        this.isInitialized = false;
        Logger.info(this.TAG, `Loader destroyed successfully for site: ${this.site.name}`);
      } catch (error) {
        Logger.error(this.TAG, `Failed to destroy loader: ${(error as Error).message}`);
      }
    }
  }

  /**
   * 调用爬虫方法
   * @param method 方法名称
   * @param params 方法参数
   * @returns Promise<CrawlerResult<T>> 方法执行结果
   */
  public async invoke<T>(method: string, params: Record<string, string | number | boolean | null> = {}): Promise<CrawlerResult<T>> {
    try {
      // 检查状态
      if (this.isDestroyed) {
        return this.createErrorResult<T>('Cannot invoke method on destroyed loader');
      }
      
      // 自动初始化
      if (!this.isInitialized) {
        const initialized = await this.init();
        if (!initialized) {
          return this.createErrorResult<T>('Loader initialization failed');
        }
      }
      
      // 验证方法
      if (!this.validateMethod(method)) {
        return this.createErrorResult<T>(`Method ${method} not supported`);
      }
      
      this.lastInvokeTime = Date.now();
      Logger.debug(this.TAG, `Invoking method: ${method} with params: ${JSON.stringify(params)}`);
      
      const result = await this.onInvoke<T>(method, params);
      this.errorCount = 0; // 重置错误计数
      
      Logger.debug(this.TAG, `Method ${method} executed successfully for site: ${this.site.name}`);
      return this.createSuccessResult(result);
    } catch (error) {
      Logger.error(this.TAG, `Failed to invoke method ${method}: ${(error as Error).message}`);
      this.handleError();
      return this.createErrorResult<T>((error as Error).message);
    }
  }

  /**
   * 获取站点信息
   * @returns Site 站点信息
   */
  public getSite(): Site {
    // 使用手动属性复制代替Object.assign
    return {
      key: this.site.key,
      name: this.site.name,
      url: this.site.url,
      type: this.site.type,
      loaderType: this.site.loaderType,
      api: this.site.api,
      logo: this.site.logo,
      description: this.site.description,
      siteAuth: this.site.siteAuth,
      headers: this.site.headers,
      config: this.site.config,
      configItems: this.site.configItems,
      searchConfig: this.site.searchConfig,
      filterConfig: this.site.filterConfig,
      performanceConfig: this.site.performanceConfig,
      version: this.site.version,
      stats: this.site.stats,
      lifecycle: this.site.lifecycle,
      enabled: this.site.enabled,
      order: this.site.order,
      group: this.site.group,
      tags: this.site.tags,
      customCode: this.site.customCode,
      sandboxEnabled: this.site.sandboxEnabled,
      allowThirdParty: this.site.allowThirdParty,
      createdAt: this.site.createdAt,
      updatedAt: this.site.updatedAt,
      lastUsedAt: this.site.lastUsedAt,
      userAgent: this.site.userAgent,
      referer: this.site.referer,
      proxy: this.site.proxy,
      encoding: this.site.encoding,
      charset: this.site.charset,
      certificate: this.site.certificate
    };
  }

  /**
   * 更新站点配置
   * @param config 新的配置
   */
  public updateConfig(config: SiteUpdateConfig): void {
    // 使用手动属性复制
    this.site = {
      key: config.key ?? this.site.key,
      name: config.name ?? this.site.name,
      url: config.url ?? this.site.url,
      type: config.type ?? this.site.type,
      loaderType: config.loaderType ?? this.site.loaderType,
      api: config.api ?? this.site.api,
      logo: config.logo ?? this.site.logo,
      description: config.description ?? this.site.description,
      siteAuth: config.siteAuth ?? this.site.siteAuth,
      headers: config.headers ?? this.site.headers,
      config: config.config ?? this.site.config,
      configItems: config.configItems ?? this.site.configItems,
      searchConfig: config.searchConfig ?? this.site.searchConfig,
      filterConfig: config.filterConfig ?? this.site.filterConfig,
      performanceConfig: config.performanceConfig ?? this.site.performanceConfig,
      version: config.version ?? this.site.version,
      stats: config.stats ?? this.site.stats,
      lifecycle: config.lifecycle ?? this.site.lifecycle,
      enabled: config.enabled ?? this.site.enabled,
      order: config.order ?? this.site.order,
      group: config.group ?? this.site.group,
      tags: config.tags ?? this.site.tags,
      customCode: config.customCode ?? this.site.customCode,
      sandboxEnabled: config.sandboxEnabled ?? this.site.sandboxEnabled,
      allowThirdParty: config.allowThirdParty ?? this.site.allowThirdParty,
      createdAt: config.createdAt ?? this.site.createdAt,
      updatedAt: config.updatedAt ?? this.site.updatedAt,
      lastUsedAt: config.lastUsedAt ?? this.site.lastUsedAt,
      userAgent: config.userAgent ?? this.site.userAgent,
      referer: config.referer ?? this.site.referer,
      proxy: config.proxy ?? this.site.proxy,
      encoding: config.encoding ?? this.site.encoding,
      charset: config.charset ?? this.site.charset,
      certificate: config.certificate ?? this.site.certificate
    };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}`);
  }

  /**
   * 获取加载器类型
   * @returns LoaderType 加载器类型
   */
  public getLoaderType(): LoaderType {
    return this.site.loaderType as LoaderType;
  }

  /**
   * 检查是否已初始化
   * @returns boolean 是否已初始化
   */
  public getInitialized(): boolean {
    return this.isInitialized;
  }

  /**
   * 检查是否已销毁
   * @returns boolean 是否已销毁
   */
  public getDestroyed(): boolean {
    return this.isDestroyed;
  }

  /**
   * 检查是否可用
   * @returns boolean 是否可用
   */
  public isAvailable(): boolean {
    return !this.isDestroyed && this.errorCount < this.maxErrorCount;
  }

  /**
   * 获取加载器状态
   */
  public getStatus(): LoaderStatus {
    return {
      initialized: this.isInitialized,
      destroyed: this.isDestroyed,
      errorCount: this.errorCount,
      maxErrorCount: this.maxErrorCount,
      initializedTime: this.initializedTime,
      lastInvokeTime: this.lastInvokeTime,
      site: this.site
    };
  }

  /**
   * 重置错误计数
   */
  public resetErrorCount(): void {
    this.errorCount = 0;
  }

  /**
   * 验证方法名称
   * @param method 方法名称
   * @returns boolean 方法是否有效
   */
  protected validateMethod(method: string): boolean {
    const validMethods = ['home', 'category', 'detail', 'search', 'play', 'live'];
    return validMethods.includes(method);
  }

  /**
   * 处理错误
   */
  protected handleError(): void {
    this.errorCount++;
    Logger.warn(this.TAG, `Site ${this.site.key} error count: ${this.errorCount}/${this.maxErrorCount}`);
    
    if (this.errorCount >= this.maxErrorCount) {
      Logger.error(this.TAG, `Site ${this.site.key} reached max error count, disabling...`);
    }
  }

  /**
   * 创建成功结果
   */
  protected createSuccessResult<T>(data: T): CrawlerResult<T> {
    return {
      code: 200,
      message: 'success',
      data
    };
  }

  /**
   * 创建错误结果
   */
  protected createErrorResult<T>(message: string, data?: T): CrawlerResult<T> {
    return {
      code: 500,
      message,
      data: data as T
    };
  }

  /**
   * 执行首页方法
   */
  public async home(): Promise<CrawlerResult<HomeResult>> {
    return this.invoke<HomeResult>('home');
  }

  /**
   * 执行分类方法
   */
  public async category(params: CategoryParams): Promise<CrawlerResult<CategoryResult>> {
    return this.invoke<CategoryResult>('category', {...params} as Record<string, string | number | boolean>);
  }

  /**
   * 执行详情方法
   */
  public async detail(params: DetailParams): Promise<CrawlerResult<DetailResult>> {
    return this.invoke<DetailResult>('detail', {...params} as Record<string, string | number | boolean>);
  }

  /**
   * 执行搜索方法
   */
  public async search(params: SearchParams): Promise<CrawlerResult<SearchResult>> {
    return this.invoke<SearchResult>('search', {...params} as Record<string, string | number | boolean>);
  }

  /**
   * 执行播放方法
   */
  public async play(params: PlayParams): Promise<CrawlerResult<PlayResult>> {
    return this.invoke<PlayResult>('play', {...params} as Record<string, string | number | boolean>);
  }

  /**
   * 执行直播方法
   */
  public async live(params?: LiveParams): Promise<CrawlerResult<LiveResult>> {
    return this.invoke<LiveResult>('live', {...(params || {})} as Record<string, string | number | boolean>);
  }

  /**
   * 初始化方法（由子类实现）
   * @protected
   */
  protected abstract onInit(): Promise<void>;

  /**
   * 方法调用（由子类实现）
   * @param method 方法名称
   * @param params 方法参数
   * @protected
   */
  protected abstract onInvoke<T>(method: string, params: Record<string, string | number | boolean | null>): Promise<T>;

  /**
   * 销毁方法（由子类实现）
   * @protected
   */
  protected abstract onDestroy(): Promise<void>;
}
