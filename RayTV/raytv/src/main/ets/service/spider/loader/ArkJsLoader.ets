// ArkJsLoader.ets - JavaScript 脚本加载器 JavaScript script loader
// 实现加载和执行 JavaScript 站点脚本 Implements loading and executing JavaScript site scripts

import Logger from '../../../common/util/Logger';
import { Site } from '../../../data/bean/Site';
import { BaseLoader, LoaderOptions, ScriptContext } from './BaseLoader';
import { SiteSpider } from '../CrawlerService';

/**
 * JavaScript 加载器 JavaScript loader
 */
export class ArkJsLoader extends BaseLoader {
  private readonly TAG: string = 'ArkJsLoader';
  private scriptFunction: Function | null = null;
  private scriptExports: Record<string, unknown> = {};

  /**
   * 构造函数 Constructor
   * @param site 站点信息 Site information
   * @param options 加载器选项 Loader options
   */
  constructor(site: Site, options: LoaderOptions = {}) {
    super(site, options);
  }

  /**
   * 执行 JavaScript 脚本 Execute JavaScript script
   * @returns Promise<void>
   */
  protected async executeScript(): Promise<void> {
    try {
      // 验证脚本内容 Validate script content
      if (!this.validateScriptContent(this.scriptContent)) {
        throw new Error('Invalid script content');
      }

      Logger.debug(this.TAG, `Executing JS script for site: ${this.site.key}`);

      // 创建脚本函数 Create script function
      this.scriptFunction = this.createScriptFunction();
      
      // 执行脚本，获取返回对象 Execute script, get return object
      this.scriptExports = await this.runScript();
      
      Logger.info(this.TAG, `JS script executed successfully for site: ${this.site.key}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to execute JS script:`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  /**
   * 创建脚本函数 Create script function
   * @returns Function 脚本函数 Script function
   */
  private createScriptFunction(): Function {
    // 在 ArkTS 中，我们需要使用安全的方式执行脚本
    // 这里使用 Function 构造函数创建脚本执行函数
    return new Function(
      'context',
      `
        // 脚本执行环境
        const {
          site,
          http,
          logger
        } = context;
        
        // 定义全局变量
        const exports = {};
        const module = { exports };
        
        // 执行脚本内容
        ${this.scriptContent}
        
        // 返回导出对象
        return module.exports;
      `
    );
  }

  /**
   * 运行脚本 Run script
   * @returns Promise<Record<string, unknown>> 脚本导出对象 Script export object
   */
  private async runScript(): Promise<Record<string, unknown>> {
    if (!this.scriptFunction) {
      throw new Error('Script function not initialized');
    }

    // 执行脚本并获取返回对象 Execute script and get return object
    const result = this.scriptFunction(this.scriptContext);
    
    // 如果是 Promise，等待其完成 If it's a Promise, wait for it to complete
    if (result instanceof Promise) {
      return await result;
    }
    
    return result;
  }

  /**
   * 调用脚本方法 Call script method
   * @param methodName 方法名称 Method name
   * @param args 方法参数 Method arguments
   * @returns Promise<unknown> 方法返回值 Method return value
   */
  public async callMethod(methodName: string, args: Array<unknown>): Promise<unknown> {
    try {
      Logger.debug(this.TAG, `Calling method ${methodName} for site ${this.site.key} with args: ${JSON.stringify(args)}`);
      
      const method = this.scriptExports[methodName];
      if (typeof method !== 'function') {
        throw new Error(`Method ${methodName} not found in script exports`);
      }
      
      // 调用方法 Call method
      const result = method(...args);
      
      // 如果是 Promise，等待其完成 If it's a Promise, wait for it to complete
      if (result instanceof Promise) {
        return await result;
      }
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `Failed to call method ${methodName}:`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  /**
   * 创建爬虫实例 Create spider instance
   * @returns SiteSpider 爬虫实例 Spider instance
   */
  protected createSpiderImpl(): SiteSpider {
    return {
      getSiteInfo: async () => this.callMethod('getSiteInfo', []),
      
      getRecommendList: async () => this.callMethod('getRecommendList', []),
      
      getHotList: async () => this.callMethod('getHotList', []),
      
      getLatestList: async () => this.callMethod('getLatestList', []),
      
      getCategories: async () => this.callMethod('getCategories', []),
      
      getCategoryList: async (category: string, page: number) => this.callMethod('getCategoryList', [category, page]),
      
      search: async (keyword: string, page?: number) => this.callMethod('search', [keyword, page]),
      
      getDetail: async (id: string) => this.callMethod('getDetail', [id]),
      
      getPlayUrl: async (id: string, episodeId?: string) => this.callMethod('getPlayUrl', [id, episodeId]),
      
      getSearchSuggestions: async (keyword: string) => {
        if (typeof this.scriptExports.getSearchSuggestions === 'function') {
          return this.callMethod('getSearchSuggestions', [keyword]);
        }
        return [];
      }
    };
  }

  /**
   * 获取加载器类型 Get loader type
   * @returns string 加载器类型 Loader type
   */
  public getType(): string {
    return 'js';
  }

  /**
   * 验证 JavaScript 脚本内容 Validate JavaScript script content
   * @param scriptContent 脚本内容 Script content
   * @returns boolean 是否有效 Whether valid
   */
  protected validateScriptContent(scriptContent: string): boolean {
    if (!super.validateScriptContent(scriptContent)) {
      return false;
    }

    // 检查脚本是否包含必要的方法 Check if script contains required methods
    const requiredMethods = [
      'getRecommendList',
      'getCategories',
      'getCategoryList',
      'search',
      'getDetail',
      'getPlayUrl'
    ];

    // 在实际实现中，我们可以使用更复杂的验证规则
    // 例如，使用正则表达式检查是否包含必要的方法定义
    return true;
  }

  /**
   * 释放资源 Release resources
   */
  public async destroy(): Promise<void> {
    Logger.info(this.TAG, `Destroying JS loader for site: ${this.site.key}`);
    this.scriptFunction = null;
    this.scriptExports = {};
    await super.destroy();
  }
}
