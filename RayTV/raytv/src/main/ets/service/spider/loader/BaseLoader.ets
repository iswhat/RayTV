// BaseLoader.ets - 加载器基类 Loader base class
// 实现站点脚本的加载和执行 Implements loading and execution of site scripts
import Logger from '../../../common/util/Logger';
import { Site } from '../../../data/bean/Site';
import { HttpService } from '../../HttpService';
import { SiteSpider } from '../CrawlerService';

/**
 * 加载器类型枚举 Loader type enum
 */
export enum LoaderType {
  JS = 'js',
  PYTHON = 'py',
  JAR = 'jar'
}

/**
 * 脚本执行上下文 Script execution context
 */
export interface ScriptContext {
  site: Site;
  http: typeof HttpService.getInstance;
  logger: typeof Logger;
  [key: string]: any;
}

/**
 * 加载器选项接口 Loader options interface
 */
export interface LoaderOptions {
  timeout?: number;
  retryCount?: number;
  sandboxEnabled?: boolean;
  allowThirdParty?: boolean;
}

/**
 * 加载器基类 Loader base class
 */
export abstract class BaseLoader {
  protected readonly TAG: string = 'BaseLoader';
  protected site: Site;
  protected options: LoaderOptions;
  protected loaded: boolean = false;
  protected scriptContent: string = '';
  protected scriptContext: ScriptContext;
  protected httpService: HttpService;

  /**
   * 构造函数 Constructor
   * @param site 站点信息 Site information
   * @param options 加载器选项 Loader options
   */
  constructor(site: Site, options: LoaderOptions = {}) {
    this.site = site;
    this.options = {
      timeout: 30000,
      retryCount: 3,
      sandboxEnabled: true,
      allowThirdParty: false,
      ...options
    };
    this.httpService = HttpService.getInstance();
    this.scriptContext = {
      site: this.site,
      http: HttpService.getInstance,
      logger: Logger
    };
  }

  /**
   * 加载脚本 Load script
   * @returns Promise<boolean> 加载是否成功 Whether loading is successful
   */
  public async load(): Promise<boolean> {
    if (this.loaded) {
      Logger.info(this.TAG, `Script for site ${this.site.key} is already loaded`);
      return true;
    }

    try {
      Logger.info(this.TAG, `Loading script for site: ${this.site.key}`);
      
      // 下载脚本内容 Download script content
      await this.downloadScript();
      
      // 初始化脚本上下文 Initialize script context
      await this.initializeContext();
      
      // 执行脚本 Execute script
      await this.executeScript();
      
      this.loaded = true;
      Logger.info(this.TAG, `Script loaded successfully for site: ${this.site.key}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to load script for site ${this.site.key}:`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * 下载脚本内容 Download script content
   * @returns Promise<void>
   */
  protected async downloadScript(): Promise<void> {
    try {
      // 如果site.api是URL，下载脚本内容 If site.api is URL, download script content
      if (this.site.api && (this.site.api.startsWith('http://') || this.site.api.startsWith('https://'))) {
        Logger.info(this.TAG, `Downloading script from: ${this.site.api}`);
        const response = await this.httpService.get(this.site.api, {
          timeout: this.options.timeout
        });
        this.scriptContent = response.data as string;
      } else if (this.site.api) {
        // 如果site.api是脚本内容，直接使用 If site.api is script content, use it directly
        this.scriptContent = this.site.api;
      } else {
        throw new Error('No script content or URL provided');
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to download script:`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  /**
   * 初始化脚本上下文 Initialize script context
   * @returns Promise<void>
   */
  protected async initializeContext(): Promise<void> {
    // 初始化脚本上下文，子类可重写此方法添加更多上下文对象 Initialize script context, subclass can override this method to add more context objects
    Logger.debug(this.TAG, `Initializing script context for site: ${this.site.key}`);
  }

  /**
   * 执行脚本 Execute script
   * @returns Promise<void>
   */
  protected abstract executeScript(): Promise<void>;

  /**
   * 调用脚本方法 Call script method
   * @param methodName 方法名称 Method name
   * @param args 方法参数 Method arguments
   * @returns Promise<any> 方法返回值 Method return value
   */
  public abstract callMethod(methodName: string, args: Array<any>): Promise<any>;

  /**
   * 创建爬虫实例 Create spider instance
   * @returns Promise<SiteSpider> 爬虫实例 Spider instance
   */
  public async createSpider(): Promise<SiteSpider> {
    if (!this.loaded) {
      const success = await this.load();
      if (!success) {
        throw new Error(`Failed to load script for site: ${this.site.key}`);
      }
    }

    return this.createSpiderImpl();
  }

  /**
   * 创建爬虫实例实现 Create spider instance implementation
   * @returns SiteSpider 爬虫实例 Spider instance
   */
  protected abstract createSpiderImpl(): SiteSpider;

  /**
   * 释放资源 Release resources
   */
  public async destroy(): Promise<void> {
    Logger.info(this.TAG, `Destroying loader for site: ${this.site.key}`);
    this.loaded = false;
    this.scriptContent = '';
    // 子类可以重写此方法清理更多资源 Subclass can override this method to clean up more resources
  }

  /**
   * 检查加载器是否已加载 Check if loader is loaded
   * @returns boolean 是否已加载 Whether loaded
   */
  public isLoaded(): boolean {
    return this.loaded;
  }

  /**
   * 获取加载器类型 Get loader type
   * @returns string 加载器类型 Loader type
   */
  public abstract getType(): string;

  /**
   * 验证脚本内容 Validate script content
   * @param scriptContent 脚本内容 Script content
   * @returns boolean 是否有效 Whether valid
   */
  protected validateScriptContent(scriptContent: string): boolean {
    if (!scriptContent || scriptContent.trim().length === 0) {
      Logger.error(this.TAG, 'Empty script content');
      return false;
    }

    // 子类可以重写此方法添加更多验证规则 Subclass can override this method to add more validation rules
    return true;
  }

  /**
   * 获取脚本执行上下文 Get script execution context
   * @returns ScriptContext 脚本执行上下文 Script execution context
   */
  protected getScriptContext(): ScriptContext {
    return this.scriptContext;
  }
}

/**
 * 空加载器，用于处理不支持的加载器类型 Empty loader, used to handle unsupported loader types
 */
export class EmptyLoader extends BaseLoader {
  public executeScript(): Promise<void> {
    return Promise.resolve();
  }

  public callMethod(methodName: string, args: Array<any>): Promise<any> {
    Logger.warn(this.TAG, `EmptyLoader: Method ${methodName} called with args: ${JSON.stringify(args)}`);
    return Promise.resolve(null);
  }

  protected createSpiderImpl(): SiteSpider {
    return {
      getSiteInfo: async () => this.site,
      getRecommendList: async () => [],
      getHotList: async () => [],
      getLatestList: async () => [],
      getCategories: async () => [],
      getCategoryList: async () => [],
      search: async () => [],
      getDetail: async () => ({
        id: '',
        title: '未知标题',
        cover: '',
        description: '暂无描述',
        playSources: [],
        episodes: []
      }),
      getPlayUrl: async () => ''
    };
  }

  public getType(): string {
    return 'empty';
  }
}
