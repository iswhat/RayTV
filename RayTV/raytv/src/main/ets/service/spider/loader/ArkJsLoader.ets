import Logger from '../../../common/util/Logger';
import { BaseLoader, LoaderType, Site } from './BaseLoader';
import { TaskPoolManager } from '../../../task/pool/TaskPoolManager';
import HttpService from '../../http/HttpService';
import MemoryManager from '../../../common/util/MemoryManager';
import TimeoutManager from '../../../common/util/TimeoutManager';

/**
 * JavaScript执行上下�? */
interface JsContext {
  contextData?: Record<string, unknown>;
}

/**
 * Ark JavaScript加载�? * 实现基于HarmonyOS的JavaScript代码加载和执行器
 */
export class ArkJsLoader extends BaseLoader {
  private readonly TAG: string = 'ArkJsLoader';
  private jsContext: JsContext = {};
  private scriptContent: string = '';
  private taskPoolManager: TaskPoolManager;
  private httpService: HttpService;
  private memoryManager: MemoryManager;
  private timeoutManager: TimeoutManager;
  private lastUsedTime: number = 0;
  private isInitialized: boolean = false;

  /**
   * 构造函�?   * @param site 站点配置
   */
  constructor(site: Site) {
    super(site);
    this.taskPoolManager = TaskPoolManager.getInstance();
    this.httpService = HttpService.getInstance();
    this.memoryManager = MemoryManager.getInstance();
    this.timeoutManager = TimeoutManager.getInstance();
  }

  /**
   * 初始化加载器
   * @protected
   */
  protected async onInit(): Promise<void> {
    try {
      // 检查内存使用情�?      if (!this.memoryManager.checkMemoryAvailability()) {
        throw new Error('Insufficient memory to initialize JS loader');
      }
      
      // 加载JavaScript代码
      await this.loadScript();
      
      // 创建安全沙箱环境
      this.createSandbox();
      
      // 注入基础API
      this.injectApis();
      
      // 执行初始化脚�?      await this.executeInitScript();
      
      this.isInitialized = true;
      this.lastUsedTime = Date.now();
      Logger.info(this.TAG, `JS loader initialized for site: ${this.site.name}`);
    } catch (error) {
      this.isInitialized = false;
      this.cleanupResources();
      Logger.error(this.TAG, `Failed to initialize JS loader: ${error}`);
      throw error;
    }
  }

  /**
   * 方法调用
   * @param method 方法名称
   * @param params 方法参数
   * @protected
   */
  protected async onInvoke(method: string, params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null>))))))): Promise<unknown> {
    if (!this.isInitialized) {
      await this.onInit();
    }
    
    this.lastUsedTime = Date.now();
    
    try {
      // 安全检�?      this.validateParams(params);
      
      // 设置执行超时
      const timeoutId = this.timeoutManager.setTimeout(() => {
        throw new Error(`Method ${method} execution timed out`);
      }, 30000); // 30秒超�?      
      try {
        // 在后台线程执行JavaScript方法
        const result = await this.taskPoolManager.execute(() => {
          return this.executeMethod(method, params);
        });
        
        return result;
      } finally {
        this.timeoutManager.clearTimeout(timeoutId);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to invoke JS method ${method}: ${error}`);
      // 错误计数增加
      this.errorCount++;
      
      // 如果错误过多，清理资�?      if (this.errorCount >= this.maxErrorCount) {
        Logger.warn(this.TAG, `Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources` instanceof Error ? `Too many errors, cleaning up resources` : new Error(String(`Too many errors, cleaning up resources`)))))));
        this.cleanupResources();
      }
      
      throw error;
    }
  }

  /**
   * 销毁方�?   * @protected
   */
  protected onDestroy(): void {
    this.cleanupResources();
    Logger.info(this.TAG, `JS loader destroyed for site: ${this.site.name}`);
  }
  
  /**
   * 清理资源
   * @private
   */
  private cleanupResources(): void {
    // 清理JavaScript上下�?    if (this.jsContext) {
      // 直接创建新对象替代delete操作
      this.jsContext = {};
    }
    
    this.scriptContent = '';
    this.isInitialized = false;
    
    // 释放内存
    this.memoryManager.forceGC();
    
    Logger.info(this.TAG, 'Resources cleaned up');
  }
  
  /**
   * 获取最后使用时�?   */
  public getLastUsedTime(): number {
    return this.lastUsedTime;
  }
  
  /**
   * 是否已初始化
   */
  public getIsInitialized(): boolean {
    return this.isInitialized;
  }

  /**
   * 加载JavaScript代码
   * @private
   */
  private async loadScript(): Promise<void> {
    const config = this.site;
    
    if (config.url && (config.url.startsWith('http://') || config.url.startsWith('https://'))) {
      // 从URL加载
      Logger.info(this.TAG, `Loading script from URL: ${config.url}`);
      try {
        const response = await this.httpService.get(config.url, { timeout: 10000 });
        this.scriptContent = response.data as string;
      } catch (error) {
        Logger.error(this.TAG, `Failed to load script from URL: ${error}`);
        // 如果URL加载失败，尝试使用备用代�?        if (config.content) {
          Logger.warn(this.TAG, 'Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content' instanceof Error ? 'Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content' : new Error(String('Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content' instanceof Error ? 'Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content' instanceof Error ? 'Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content' : new Error(String('Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content' : new Error(String('Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content' instanceof Error ? 'Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content' : new Error(String('Falling back to config content' instanceof Error ? 'Falling back to config content' : new Error(String('Falling back to config content')))))));
          this.scriptContent = config.content as string;
        } else {
          throw new Error(`Failed to load script: ${error}`);
        }
      }
    } else if (config.content) {
      // 直接使用配置中的代码
      Logger.info(this.TAG, 'Using script content from config');
      this.scriptContent = config.content as string;
    } else {
      throw new Error('No script source provided (url or content)');
    }
    
    // 安全过滤
    this.filterDangerousCode();
  }

  /**
   * 创建沙箱环境
   * @private
   */
  private createSandbox(): void {
    // 创建独立的执行上下文
    this.jsContext = {
      // 清空上下文，只包含必要的对象
    };
    
    Logger.info(this.TAG, 'Created JavaScript sandbox environment');
  }

  /**
   * 注入基础API
   * @private
   */
  private injectApis(): void {
    // 注入HTTP请求API
    this.jsContext.http = {
      get: async (url: string, options?: { headers?: Record<string, string>, timeout?: number }) => {
        // 验证URL安全�?        this.validateUrl(url);
        return this.httpService.get(url, options || {});
      },
      post: async (url: string, data?: Record<string, string | number | boolean | null>, options?: { headers?: Record<string, string>, timeout?: number }) => {
        // 验证URL安全�?        this.validateUrl(url);
        return this.httpService.post(url, data, options || {});
      }
    };
    
    // 注入加密API
    this.jsContext.crypto = {
      md5: (str: string) => {
        // 使用HarmonyOS提供的加密API
        try {
          // 在HarmonyOS中，可以使用@ohos.security.crypto提供的加密功�?          // 这里使用简单的字符串处理作为降级方�?          let hash = 0;
          for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // 转换�?2位整�?          }
          return Math.abs(hash).toString(16);
        } catch (error) {
          // 降级处理
          return `md5_${str}`;
        }
      },
      base64: {
        encode: (str: string) => {
          try {
            return btoa(unescape(encodeURIComponent(str)));
          } catch (error) {
            Logger.error(this.TAG, `Base64 encode error: ${error}`);
            return '';
          }
        }, decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string instanceof Error ? decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string : new Error(String(decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string instanceof Error ? decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string instanceof Error ? decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string : new Error(String(decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string : new Error(String(decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string instanceof Error ? decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string : new Error(String(decode: (str: string instanceof Error ? decode: (str: string : new Error(String(decode: (str: string))))))) => {
          try {
            return decodeURIComponent(escape(atob(str)));
          } catch (error) {
            Logger.error(this.TAG, `Base64 decode error: ${error}`);
            return '';
          }
        }
      }
    };
    
    // 注入字符串处理工具（替代正则表达式）
    this.jsContext.stringUtil = {
      // 使用简单的字符串方法替代正则表达式
      contains: (text: string, substring: string instanceof Error ? substring: string : new Error(String(substring: string instanceof Error ? substring: string instanceof Error ? substring: string : new Error(String(substring: string : new Error(String(substring: string instanceof Error ? substring: string : new Error(String(substring: string instanceof Error ? substring: string instanceof Error ? substring: string : new Error(String(substring: string instanceof Error ? substring: string instanceof Error ? substring: string : new Error(String(substring: string : new Error(String(substring: string instanceof Error ? substring: string : new Error(String(substring: string : new Error(String(substring: string instanceof Error ? substring: string : new Error(String(substring: string instanceof Error ? substring: string instanceof Error ? substring: string : new Error(String(substring: string : new Error(String(substring: string instanceof Error ? substring: string : new Error(String(substring: string))))))): boolean => {
        return text.indexOf(substring) !== -1;
      },
      startsWith: (text: string, prefix: string): boolean => {
        return text.indexOf(prefix) === 0;
      },
      endsWith: (text: string, suffix: string): boolean => {
        return text.lastIndexOf(suffix) === text.length - suffix.length;
      },
      split: (text: string, separator: string): string[] => {
        return text.split(separator);
      },
      replace: (text: string, search: string, replacement: string): string => {
        return text.replace(search, replacement);
      }
    };
    
    // 注入日志API
    this.jsContext.logger = {
      info: (message: string) => {
        Logger.info(`${this.TAG}[${this.site.name}]`, message);
      },
      warn: (message: string) => {
        Logger.warn(`${this.TAG}[${this.site.name}]`, message);
      },
      error: (message: string) => {
        Logger.error(`${this.TAG}[${this.site.name}]`, message);
      }
    };
    
    // 注入工具函数
    this.jsContext.util = {
      parseJson: (text: string) => {
        try {
          return JSON.parse(text);
        } catch (error) {
          Logger.error(this.TAG, `JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}` instanceof Error ? `JSON parse error: ${error}` : new Error(String(`JSON parse error: ${error}`)))))));
          return null;
        }
      },
      stringifyJson: (obj: Record<string, string | number | boolean | null>) => {
        try {
          return JSON.stringify(obj);
        } catch (error) {
          Logger.error(this.TAG, `JSON stringify error: ${error}`);
          return '{}';
        }
      }, // 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number instanceof Error ? // 添加延时函数
      sleep: (ms: number : new Error(String(// 添加延时函数
      sleep: (ms: number))))))) => {
        return new Promise(resolve => setTimeout(resolve, Math.min(ms, 5000))); // 限制最大延�?�?      }
    };
    
    Logger.info(this.TAG, 'Injected enhanced APIs into JS context');
  }
  
  /**
   * 验证URL安全�?   * @private
   */
  private validateUrl(url: string): void {
    // 检查URL是否为相对路径或白名单内的域�?    const allowedDomains = this.site.allowedDomains || [];
    
    try {
      const urlObj = new URL(url);
      const hostname = urlObj.hostname;
      
      // 检查是否在白名单内
      const isAllowed = allowedDomains.some(domain => {
        return hostname === domain || hostname.endsWith(`.${domain}`);
      });
      
      if (!isAllowed) {
        throw new Error(`URL domain not allowed: ${hostname}`);
      }
    } catch (error) {
      if (error instanceof TypeError) {
        // 可能是相对路径，忽略URL解析错误
      } else {
        throw error;
      }
    }
  }

  /**
   * 执行初始化脚�?   * @private
   */
  private async executeInitScript(): Promise<void> {
    try {
      // 使用安全的方式执行脚�?      const safeEval = new Function('context', `
        with(context) {
          ${this.scriptContent};
        }
        return { exports: module?.exports || {} };
      `);
      
      const result = safeEval(this.jsContext);
      
      // 合并导出对象到上下文
      if (result.exports) {
        Object.assign(this.jsContext, result.exports);
      }
      
      Logger.info(this.TAG, 'Initial script executed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to execute init script: ${error}`);
      throw error;
    }
  }

  /**
   * 执行方法
   * @param method 方法名称
   * @param params 方法参数
   * @private
   */
  private executeMethod(method: string, params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null>))))))): Record<string, string | number | boolean | null> {
    if (typeof this.jsContext[method] !== 'function') {
      throw new Error(`Method ${method} not found in script`);
    }
    
    // 限制方法执行内存使用
    const maxMemoryUsage = 50 * 1024 * 1024; // 50MB
    if (!this.memoryManager.checkMemoryLimit(maxMemoryUsage)) {
      throw new Error('Memory limit exceeded for method execution');
    }
    
    try {
      // 深度拷贝参数，避免引用问�?      const safeParams = this.deepClone(params);
      
      // 执行方法
      const result = this.jsContext[method](safeParams);
      
      // 序列化结果以检测循环引�?      const serializedResult = JSON.stringify(result);
      
      // 深度拷贝结果返回
      return this.deepClone(result);
    } catch (error) {
      Logger.error(this.TAG, `Error executing method ${method}: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }
  
  /**
   * 深度拷贝对象
   * @private
   */
  private deepClone<T>(obj: T): T {
    if (obj === null || typeof obj !== 'object') {
      return obj;
    }
    
    try {
      return JSON.parse(JSON.stringify(obj));
    } catch (error) {
      Logger.error(this.TAG, `Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}` instanceof Error ? `Deep clone error: ${error}` : new Error(String(`Deep clone error: ${error}`)))))));
      return obj;
    }
  }

  /**
   * 过滤危险代码
   * @private
   */
  private filterDangerousCode(): void {
    // 检测并过滤危险的JavaScript操作
    const dangerousPatterns = [
      /eval\s*\(/g,
      /new\s+Function\s*\(/g,
      /document\.write\s*\(/g,
      /window\.open\s*\(/g,
      /localStorage\s*\./g,
      /sessionStorage\s*\./g,
      /__proto__/g,
      /constructor\s*\(/g,
      /Object\.prototype/g,
      /Array\.prototype/g,
      /RegExp\.prototype/g,
      /Function\.prototype/g,
      /\.call\s*\(/g,
      /\.apply\s*\(/g,
      /\.bind\s*\(/g,
      /process\./g,
      /globalThis/g,
      /\$[\w_\$]+\(/g, // 检测可能的jQuery等库调用
      /require\s*\(/g,
      /import\s+(?:.*from\s+)?["']/g
    ];
    
    for (const pattern of dangerousPatterns) {
      if (pattern.test(this.scriptContent)) {
        Logger.warn(this.TAG, `Dangerous code pattern detected: ${pattern.toString()}`);
        // 增强的安全措施：抛出错误
        throw new Error(`Security violation: dangerous code pattern detected: ${pattern.toString()}`);
      }
    }
    
    // 检查代码复杂度，防止恶意循�?    const lineCount = this.scriptContent.split('\n').length;
    const braceCount = (this.scriptContent.match(/\{/g) || []).length;
    
    if (lineCount > 1000 || braceCount > 500) {
      throw new Error('Script too complex, potential security risk');
    }
  }

  /**
   * 验证参数
   * @param params 方法参数
   * @private
   */
  private validateParams(params: Record<string, string | number | boolean | null>): void {
    // 检查参数大小，防止过大的参数导致内存问�?    const paramsSize = JSON.stringify(params).length;
    if (paramsSize > 1024 * 1024) { // 1MB限制
      throw new Error('Parameters too large');
    }
    
    // 检查参数深度，防止深层嵌套对象
    const maxDepth = 10;
    if (this.checkObjectDepth(params) > maxDepth) {
      throw new Error('Parameters too deeply nested');
    }
    
    // 检查数组长度，防止过大的数�?    this.checkCollectionSize(params);
  }
  
  /**
   * 检查对象深�?   * @private
   */
  private checkObjectDepth(obj: Record<string, string | number | boolean | null>, currentDepth: number = 0): number {
    if (obj === null || typeof obj !== 'object') {
      return currentDepth;
    }
    
    const maxDepth = currentDepth;
    for (const key in obj) {
      if (Object.keys(obj).includes(key)) {
        const depth = this.checkObjectDepth(obj[key], currentDepth + 1);
        if (depth > maxDepth) {
          return depth;
        }
      }
    }
    
    return maxDepth;
  }
  
  /**
   * 获取对象的所有键
   * 替代Object.keys，兼容ArkTS语法
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    const keys: string[] = [];
    for (const key in obj) {
      if (Object.keys(obj).includes(key)) {
        keys.push(key);
      }
    }
    return keys;
  }

  /**
   * 检查集合大�?   * @private
   */
  private checkCollectionSize(obj: Record<string, string | number | boolean | null>): void {
    const maxArrayLength = 10000;
    
    if (Array.isArray(obj)) {
      if (obj.length > maxArrayLength) {
        throw new Error('Array too large');
      }
      
      // 递归检查数组元�?      for (const item of obj) {
        if (typeof item === 'object' && item !== null) {
          this.checkCollectionSize(item);
        }
      }
    } else if (typeof obj === 'object' && obj !== null) {
      const keys = this.getObjectKeys(obj);
      if (keys.length > 1000) {
        throw new Error('Object has too many properties');
      }
      
      // 递归检查对象属�?      for (const key of keys) {
        this.checkCollectionSize(obj[key]);
      }
    }
  }
}


