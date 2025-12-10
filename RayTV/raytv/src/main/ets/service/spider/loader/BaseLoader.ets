import Logger from '../../../common/util/Logger';
import { Site } from '../../../data/bean/Site';

/**
 * 爬虫加载器类型枚�? */
export enum LoaderType {
  JAR = 'jar',
  JS = 'js',
  PY = 'py'
}

/**
 * 爬虫结果通用接口
 */
export interface CrawlerResult<T> {
  code: number;
  message: string;
  data: T;
}

/**
 * 首页结果接口
 */
export interface HomeResult {
  banners?: Array<{
    id: string;
    imageUrl: string;
    link: string;
    title: string;
  }>;
  categories?: Array<{
    id: string;
    name: string;
    icon?: string;
  }>;
  lists?: Array<{
    title: string;
    moreUrl?: string;
    items: Array<{
      id: string;
      name: string;
      cover: string;
      url: string;
      type?: string;
      score?: string;
      updateInfo?: string;
    }>;
  }>;
}

/**
 * 分类结果接口
 */
export interface CategoryResult {
  page: number;
  pageSize: number;
  total: number;
  list: Array<{
    id: string;
    name: string;
    cover: string;
    url: string;
    type?: string;
    score?: string;
    updateInfo?: string;
  }>;
}

/**
 * 详情结果接口
 */
export interface DetailResult {
  id: string;
  name: string;
  cover: string;
  type?: string;
  score?: string;
  updateInfo?: string;
  description?: string;
  director?: string;
  actors?: string;
  releaseYear?: string;
  region?: string;
  language?: string;
  status?: string;
  playCount?: string;
  categories?: string[];
  episodes: Array<{
    title?: string;
    list: Array<{
      id: string;
      name: string;
      url: string;
    }>;
  }>;
  related?: Array<{
    id: string;
    name: string;
    cover: string;
    url: string;
  }>;
}

/**
 * 搜索结果接口
 */
export interface SearchResult {
  page: number;
  pageSize: number;
  total: number;
  list: Array<{
    id: string;
    name: string;
    cover: string;
    url: string;
    type?: string;
    score?: string;
    updateInfo?: string;
    description?: string;
  }>;
}

/**
 * 播放结果接口
 */
export interface PlayResult {
  playUrl: string;
  headers?: Record<string, string>;
  cookies?: string;
  format?: string;
  quality?: string;
  subtitles?: Array<{
    name: string;
    url: string;
    type?: string;
  }>;
  sources?: Array<{
    name: string;
    url: string;
    format?: string;
    quality?: string;
  }>;
}

/**
 * 直播结果接口
 */
export interface LiveResult {
  category: string;
  channels: Array<{
    id: string;
    name: string;
    logo: string;
    url: string;
    description?: string;
    tags?: string[];
  }>;
}

/**
 * 爬虫加载器基�? * 定义爬虫加载器的核心接口和抽象方�? */
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
   * 构造函�?   * @param site 站点信息
   */
  constructor(site: Site) {
    this.site = site;
    Logger.info(this.TAG, `Creating loader for site: ${site.name} (${site.key})`);
  }

  /**
   * 初始化加载器
   * @returns Promise<boolean> 初始化是否成�?   */
  public async init(): Promise<boolean> {
    if (this.isDestroyed) {
      Logger.error(this.TAG, 'Cannot initialize destroyed loader');
      return false;
    }
    
    if (!this.isInitialized) {
      try {
        Logger.info(this.TAG, `Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}` instanceof Error ? `Initializing loader for site: ${this.site.name}` : new Error(String(`Initializing loader for site: ${this.site.name}`)))))));
        await this.onInit();
        this.isInitialized = true;
        this.initializedTime = Date.now();
        this.errorCount = 0;
        Logger.info(this.TAG, `Loader initialized successfully for site: ${this.site.name}`);
        return true;
      } catch (error) {
        Logger.error(this.TAG, `Failed to initialize loader: ${error}`);
        this.handleError();
        return false;
      }
    }
    return true;
  }

  /**
   * 销毁加载器，释放资�?   */
  public async destroy(): Promise<void> {
    if (!this.isDestroyed) {
      try {
        Logger.info(this.TAG, `Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}` instanceof Error ? `Destroying loader for site: ${this.site.name}` : new Error(String(`Destroying loader for site: ${this.site.name}`)))))));
        await this.onDestroy();
        this.isDestroyed = true;
        this.isInitialized = false;
        Logger.info(this.TAG, `Loader destroyed successfully for site: ${this.site.name}`);
      } catch (error) {
        Logger.error(this.TAG, `Failed to destroy loader: ${error}`);
      }
    }
  }

  /**
   * 调用爬虫方法
   * @param method 方法名称
   * @param params 方法参数
   * @returns Promise<CrawlerResult<T>> 方法执行结果
   */
  public async invoke<T>(method: string, params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {} instanceof Error ? params: Record<string, string | number | boolean | null> = {} : new Error(String(params: Record<string, string | number | boolean | null> = {}))))))): Promise<CrawlerResult<T>> {
    try {
      // 检查状�?      if (this.isDestroyed) {
        return this.createErrorResult('Cannot invoke method on destroyed loader');
      }
      
      // 自动初始�?      if (!this.isInitialized) {
        const initialized = await this.init();
        if (!initialized) {
          return this.createErrorResult('Loader initialization failed');
        }
      }
      
      // 验证方法
      if (!this.validateMethod(method)) {
        return this.createErrorResult(`Method ${method} not supported`);
      }
      
      this.lastInvokeTime = Date.now();
      Logger.debug(this.TAG, `Invoking method: ${method} with params: ${JSON.stringify(params)}`);
      
      const result = await this.onInvoke<T>(method, params);
      this.errorCount = 0; // 重置错误计数
      
      Logger.debug(this.TAG, `Method ${method} executed successfully for site: ${this.site.name}`);
      return this.createSuccessResult(result);
    } catch (error) {
      Logger.error(this.TAG, `Failed to invoke method ${method}: ${error}`);
      this.handleError();
      return this.createErrorResult(error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 获取站点信息
   * @returns Site 站点信息
   */
  public getSite(): Site {
    return { ...this.site };
  }

  /**
   * 更新站点配置
   * @param config 新的配置
   */
  public updateConfig(config: Partial<Site>): void {
    this.site = { ...this.site, ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` instanceof Error ? ...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}` : new Error(String(...config };
    Logger.info(this.TAG, `Site config updated for ${this.site.name}`)))))));
  }

  /**
   * 获取加载器类�?   * @returns LoaderType 加载器类�?   */
  public getLoaderType(): LoaderType {
    return this.site.type as LoaderType;
  }

  /**
   * 检查是否已初始�?   * @returns boolean 是否已初始化
   */
  public isInitialized(): boolean {
    return this.isInitialized;
  }

  /**
   * 检查是否已销�?   * @returns boolean 是否已销�?   */
  public isDestroyed(): boolean {
    return this.isDestroyed;
  }

  /**
   * 检查是否可�?   * @returns boolean 是否可用
   */
  public isAvailable(): boolean {
    return !this.isDestroyed && this.errorCount < this.maxErrorCount;
  }

  /**
   * 获取加载器状�?   */
  public getStatus(): {
    initialized: boolean;
    destroyed: boolean;
    errorCount: number;
    maxErrorCount: number;
    initializedTime: number;
    lastInvokeTime: number;
    site: Site;
  } {
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
      Logger.error(this.TAG, `Site ${this.site.key} reached max error count, disabling...` instanceof Error ? disabling...` : new Error(String(disabling...` instanceof Error ? disabling...` instanceof Error ? disabling...` : new Error(String(disabling...` : new Error(String(disabling...` instanceof Error ? disabling...` : new Error(String(disabling...` instanceof Error ? disabling...` instanceof Error ? disabling...` : new Error(String(disabling...` instanceof Error ? disabling...` instanceof Error ? disabling...` : new Error(String(disabling...` : new Error(String(disabling...` instanceof Error ? disabling...` : new Error(String(disabling...` : new Error(String(disabling...`  as Error)));
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
  public async category(params: {
    url: string;
    page?: number;
    pageSize?: number;
    filters?: Record<string, string | number | boolean>;
  }): Promise<CrawlerResult<CategoryResult>> {
    return this.invoke<CategoryResult>('category', params);
  }

  /**
   * 执行详情方法
   */
  public async detail(params: {
    url: string;
  }): Promise<CrawlerResult<DetailResult>> {
    return this.invoke<DetailResult>('detail', params);
  }

  /**
   * 执行搜索方法
   */
  public async search(params: {
    keyword: string;
    page?: number;
    pageSize?: number;
  }): Promise<CrawlerResult<SearchResult>> {
    return this.invoke<SearchResult>('search', params);
  }

  /**
   * 执行播放方法
   */
  public async play(params: {
    url: string;
    source?: string;
    episode?: string;
  }): Promise<CrawlerResult<PlayResult>> {
    return this.invoke<PlayResult>('play', params);
  }

  /**
   * 执行直播方法
   */
  public async live(params?: {
    category?: string;
  }): Promise<CrawlerResult<LiveResult>> {
    return this.invoke<LiveResult>('live', params || {});
  }

  /**
   * 初始化方法（由子类实现）
   * @protected
   */
  protected abstract onInit(): Promise<void>;

  /**
   * 方法调用（由子类实现�?   * @param method 方法名称
   * @param params 方法参数
   * @protected
   */
  protected abstract onInvoke<T>(method: string, params: Record<string, string | number | boolean | object | null>): Promise<T>;

  /**
   * 销毁方法（由子类实现）
   * @protected
   */
  protected abstract onDestroy(): Promise<void>;
}


