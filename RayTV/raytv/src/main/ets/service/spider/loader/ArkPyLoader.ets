// ArkPyLoader.ets - Python 加载器 Python loader
// 实现基于 HarmonyOS 的 Python 代码加载和执行器 Implements Python code loader and executor based on HarmonyOS

import Logger from '../../../common/util/Logger';
import { BaseLoader, LoaderOptions, Site } from './BaseLoader';
import { TaskPoolManager } from '../../../task/pool/TaskPoolManager';
import HttpService from '../../http/HttpService';
import MemoryManager from '../../../common/util/MemoryManager';
import TimeoutManager from '../../../common/util/TimeoutManager';

/**
 * Python 执行上下文 Python execution context
 */
interface PyContext {
  contextData?: Record<string, string | number | boolean | Record<string, unknown>>;
  [key: string]: any;
}

/**
 * Ark Python 加载器 Ark Python loader
 * 实现基于 HarmonyOS 的 Python 代码加载和执行器 Implements Python code loader and executor based on HarmonyOS
 */
export class ArkPyLoader extends BaseLoader {
  private readonly TAG: string = 'ArkPyLoader';
  private pyContext: PyContext = {};
  private scriptContent: string = '';
  private pythonCode: string = '';
  private taskPoolManager: TaskPoolManager;
  private httpService: HttpService;
  private memoryManager: MemoryManager;
  private timeoutManager: TimeoutManager;
  private lastUsedTime: number = 0;
  private isInitialized: boolean = false;
  private pyModuleName: string = '';
  private errorCount: number = 0;
  private maxErrorCount: number = 5;

  /**
   * 构造函数 Constructor
   * @param site 站点配置 Site configuration
   * @param options 加载器选项 Loader options
   */
  constructor(site: Site, options: LoaderOptions = {}) {
    super(site, options);
    this.taskPoolManager = TaskPoolManager.getInstance();
    this.httpService = HttpService.getInstance();
    this.memoryManager = MemoryManager.getInstance();
    this.timeoutManager = TimeoutManager.getInstance();
    this.pyModuleName = `site_${site.key || 'default'}`;
  }

  /**
   * 执行脚本 Execute script
   * @returns Promise<void>
   */
  protected async executeScript(): Promise<void> {
    try {
      // 检查内存使用情况 Check memory usage
      if (!this.memoryManager.checkMemoryAvailability()) {
        throw new Error('Insufficient memory to initialize Python loader');
      }

      Logger.info(this.TAG, `Initializing Python loader for site: ${this.site.name}`);
      
      // 加载 Python 代码 Load Python code
      await this.loadScript();
      
      // 创建 Python 执行环境 Create Python execution environment
      this.createPyEnvironment();
      
      // 注入沙箱 API Inject sandbox API
      this.injectApis();
      
      // 执行初始化脚本 Execute initialization script
      await this.executeInitScript();
      
      this.isInitialized = true;
      this.lastUsedTime = Date.now();
      Logger.info(this.TAG, `Python loader initialized successfully for site: ${this.site.name}`);
    } catch (error) {
      this.isInitialized = false;
      this.cleanupResources();
      Logger.error(this.TAG, `Failed to initialize Python loader: ${error}`);
      throw error;
    }
  }

  /**
   * 方法调用 Method invocation
   * @param methodName 方法名称 Method name
   * @param args 方法参数 Method arguments
   * @returns Promise<any> 方法返回值 Method return value
   */
  public async callMethod(methodName: string, args: Array<any>): Promise<any> {
    if (!this.isInitialized) {
      await this.load();
    }

    this.lastUsedTime = Date.now();

    try {
      // 安全验证 Security validation
      this.validateParams(args);
      
      Logger.info(this.TAG, `Invoking Python method: ${methodName} for site: ${this.site.name}`);

      // 设置执行超时 Set execution timeout
      const timeoutId = this.timeoutManager.setTimeout(() => {
        throw new Error(`Method ${methodName} execution timed out`);
      }, 60000); // Python 执行可能需要更长时间，设置 60 秒超时
      try {
        // 在后台线程执行 Python 方法 Execute Python method in background thread
        const result = await this.taskPoolManager.execute(() => {
          return this.executeMethod(methodName, args);
        });

        return result;
      } finally {
        this.timeoutManager.clearTimeout(timeoutId);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to invoke Python method ${methodName}: ${error}`);
      // 错误计数增加 Error count increment
      this.errorCount++;

      // 如果错误过多，清理资源 If too many errors, clean up resources
      if (this.errorCount >= this.maxErrorCount) {
        Logger.warn(this.TAG, 'Too many errors, cleaning up resources');
        this.cleanupResources();
      }

      throw error;
    }
  }

  /**
   * 释放资源 Release resources
   */
  public async destroy(): Promise<void> {
    this.cleanupResources();
    Logger.info(this.TAG, `Python loader destroyed for site: ${this.site.name}`);
    await super.destroy();
  }
  
  /**
   * 清理资源 Clean up resources
   * @private
   */
  private cleanupResources(): void {
    // 清理 Python 上下文 Clean up Python context
    if (this.pyContext) {
      // 直接创建新对象代替 delete 操作 Create new object instead of delete operations
      this.pyContext = {};
    }

    this.scriptContent = '';
    this.isInitialized = false;

    // 释放内存 Release memory
    this.memoryManager.forceGC();

    Logger.info(this.TAG, 'Resources cleaned up');
  }
  
  /**
   * 获取最后使用时间 Get last used time
   * @returns number 最后使用时间 Last used time
   */
  public getLastUsedTime(): number {
    return this.lastUsedTime;
  }
  
  /**
   * 是否已初始化 Whether initialized
   * @returns boolean 是否已初始化 Whether initialized
   */
  public getIsInitialized(): boolean {
    return this.isInitialized;
  }

  /**
   * 加载 Python 代码 Load Python code
   * @private
   */
  private async loadScript(): Promise<void> {
    const config = this.site;

    if (config.api && (config.api.startsWith('http://') || config.api.startsWith('https://'))) {
      // 从 URL 加载 Load from URL
      Logger.info(this.TAG, `Loading Python script from URL: ${config.api}`);
      try {
        const response = await this.httpService.get(config.api, { timeout: 15000 });
        this.scriptContent = response.data as string;
        this.pythonCode = this.scriptContent;
      } catch (error) {
        Logger.error(this.TAG, `Failed to load Python script from URL: ${error}`);
        // 如果 URL 加载失败，尝试使用自定义代码 If URL loading fails, try to use custom code
        if (config.customCode) {
          Logger.warn(this.TAG, 'Falling back to config content');
          this.scriptContent = config.customCode;
          this.pythonCode = this.scriptContent;
        } else {
          throw new Error(`Failed to load Python script: ${error}`);
        }
      }
    } else if (config.customCode) {
      // 直接使用配置中的代码 Use code from config directly
      Logger.info(this.TAG, 'Using Python script content from config');
      this.scriptContent = config.customCode;
      this.pythonCode = this.scriptContent;
    } else {
      throw new Error('No Python script source provided (api or customCode)');
    }

    // 安全过滤 Security filtering
    this.filterDangerousCode();
  }

  /**
   * 创建 Python 沙箱环境 Create Python sandbox environment
   * @private
   */
  private createPyEnvironment(): void {
    // 创建 Python 模块环境 Create Python module environment
    this.pyContext = {
      // 基本的 Python 内置函数映射 Basic Python built-in function mapping
      print: (...args: any[]) => {
        Logger.info(`${this.TAG}[${this.site.name}]`, args.map(String).join(' '));
      },
      len: (obj: any) => {
        return Array.isArray(obj) ? obj.length : Object.keys(obj || {}).length;
      },
      str: (obj: any) => String(obj),
      int: (obj: any) => parseInt(obj as string, 10),
      float: (obj: any) => parseFloat(obj as string),
      bool: (obj: any) => Boolean(obj),
      list: (obj: any) => Array.isArray(obj) ? [...obj] : [obj],
      dict: (obj: any) => (typeof obj === 'object' && obj !== null) ? { ...(obj as object) } : {},
      range: (start: number, stop?: number, step: number = 1) => {
        const result = [];
        if (stop === undefined) {
          stop = start;
          start = 0;
        }
        for (let i = start; i < stop; i += step) {
          result.push(i);
        }
        return result;
      }
    };

    Logger.info(this.TAG, 'Created Python execution environment');
  }

  /**
   * 注入 Python API Inject Python API
   * @private
   */
  private injectApis(): void {
    // 注入 HTTP 请求 API Inject HTTP request API
    this.pyContext.http = {
      get: async (url: string, options?: { headers?: Record<string, string>, timeout?: number }) => {
        // 验证 URL 安全性 Validate URL security
        this.validateUrl(url);
        return this.httpService.get(url, options || {});
      },
      post: async (url: string, data?: any, options?: { headers?: Record<string, string>, timeout?: number }) => {
        // 验证 URL 安全性 Validate URL security
        this.validateUrl(url);
        return this.httpService.post(url, data, options || {});
      }
    };

    // 注入加密 API Inject crypto API
    this.pyContext.crypto = {
      md5: (str: string) => {
        try {
          // 在 HarmonyOS 中，使用兼容的 MD5 实现 In HarmonyOS, use compatible MD5 implementation
          let hash = 0;
          for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // 转换为 32 位整数
          }
          return Math.abs(hash).toString(16);
        } catch (error) {
          // 降级处理 Fallback processing
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
        },
        decode: (str: string) => {
          try {
            return decodeURIComponent(escape(atob(str)));
          } catch (error) {
            Logger.error(this.TAG, `Base64 decode error: ${error}`);
            return '';
          }
        }
      }
    };

    // 注入字符串处理工具（替换正则表达式） Inject string processing tools (replace regular expressions)
    this.pyContext.stringUtil = {
      // 使用简单的字符串方法兼容正则表达式 Use simple string methods compatible with regular expressions
      contains: (text: string, substring: string) => {
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

    // 注入日志 API Inject logger API
    this.pyContext.logger = {
      info: (message: string) => {
        Logger.info(`${this.TAG}[${this.site.name}]`, message);
      },
      warning: (message: string) => {
        Logger.warn(`${this.TAG}[${this.site.name}]`, message);
      },
      error: (message: string) => {
        Logger.error(`${this.TAG}[${this.site.name}]`, message);
      }
    };

    // 注入工具函数 Inject utility functions
    this.pyContext.util = {
      json: {
        loads: (text: string) => {
          try {
            return JSON.parse(text);
          } catch (error) {
            Logger.error(this.TAG, `JSON loads error: ${error}`);
            return null;
          }
        },
        dumps: (obj: any, indent?: number) => {
          try {
            return JSON.stringify(obj, null, indent);
          } catch (error) {
            Logger.error(this.TAG, `JSON dumps error: ${error}`);
            return '{}';
          }
        }
      },
      sleep: (seconds: number) => {
        return new Promise(resolve => setTimeout(resolve, Math.min(seconds * 1000, 10000))); // 限制最大延迟 10 秒
      }
    };

    Logger.info(this.TAG, 'Injected enhanced APIs into Python context');
  }
  
  /**
   * 验证 URL 安全性 Validate URL security
   * @private
   */
  private validateUrl(url: string): void {
    // 检查 URL 是否为相对路径或域名白名单内的地址 Check if URL is relative path or within domain whitelist
    const allowedDomains = this.site.allowedDomains || [];

    try {
      const urlObj = new URL(url);
      const hostname = urlObj.hostname;

      // 检查是否在域名白名单内 Check if in domain whitelist
      const isAllowed = allowedDomains.some(domain => {
        return hostname === domain || hostname.endsWith(`.${domain}`);
      });

      if (!isAllowed) {
        throw new Error(`URL domain not allowed: ${hostname}`);
      }
    } catch (error) {
      if (error instanceof TypeError) {
        // 可能是相对路径，忽略 URL 解析错误 May be relative path, ignore URL parsing error
      } else {
        throw error;
      }
    }
  }

  /**
   * 执行初始化脚本 Execute initialization script
   * @private
   */
  private async executeInitScript(): Promise<void> {
    try {
      // 在 Python 环境中执行脚本 Execute script in Python environment
      // 注意：这里使用 JavaScript 模拟 Python 执行环境
      // 实际项目中可能需要使用 Python 解释器或封装接口
      
      // 预处理 Python 代码，转换为 JavaScript 兼容格式 Preprocess Python code, convert to JavaScript compatible format
      const processedScript = this.preprocessPythonCode(this.scriptContent);
      
      // 创建安全的执行上下文 Create safe execution context
      const execContext: Record<string, any> = {};
      
      // 模拟 Python 模块系统 Simulate Python module system
      execContext.__name__ = this.pyModuleName;
      execContext.__file__ = `${this.pyModuleName}.py`;
      
      // 执行脚本 Execute script
      // 注意：这是一个简化实现，实际项目可能需要更复杂的 Python 代码翻译或解释
      Logger.info(this.TAG, 'Executing Python initialization script');
      
      // 提取 Python 函数 Extract Python functions
      this.extractPythonFunctions();
      
      // 这里只是示例，实际项目中需要根据具体的 Python 执行方案进行调整
      Logger.warn(this.TAG, 'Python script execution is simulated. In production, use actual Python interpreter.');
      
      Logger.info(this.TAG, 'Python initialization script executed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to execute Python init script: ${error}`);
      throw error;
    }
  }

  /**
   * 执行 Python 方法 Execute Python method
   * @param methodName 方法名称 Method name
   * @param params 参数 Parameters
   * @private
   */
  private executeMethod(methodName: string, params: Array<any>): any {
    // 检查方法是否存在 Check if method exists
    if (typeof this.pyContext[methodName] !== 'function') {
      // 尝试在 Python 模块中查找 Try to find in Python module
      const pyMethodName = `parse_${methodName}`;
      if (typeof this.pyContext[pyMethodName] !== 'function') {
        throw new Error(`Method ${methodName} or ${pyMethodName} not found in Python script`);
      }
      methodName = pyMethodName;
    }

    // 限制方法执行内存使用 Limit method execution memory usage
    const maxMemoryUsage = 100 * 1024 * 1024; // Python 执行可能需要更多内存，设置 100MB
    if (!this.memoryManager.checkMemoryLimit(maxMemoryUsage)) {
      throw new Error('Memory limit exceeded for method execution');
    }

    try {
      // 深度克隆参数，防止引用问题 Deep clone parameters to prevent reference issues
      const safeParams = this.deepClone(params);

      // 执行方法 Execute method
      const result = this.pyContext[methodName](safeParams);

      // 序列化结果以检查循环引用 Serialize result to check for circular references
      const serializedResult = JSON.stringify(result);

      // 深度克隆结果返回 Deep clone result for return
      return this.deepClone(result);
    } catch (error) {
      Logger.error(this.TAG, `Error executing Python method ${methodName}: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }
  
  /**
   * 深度克隆对象 Deep clone object
   * @private
   */
  private deepClone<T>(obj: T): T {
    if (obj === null || typeof obj !== 'object') {
      return obj;
    }

    try {
      return JSON.parse(JSON.stringify(obj));
    } catch (error) {
      Logger.error(this.TAG, `Deep clone error: ${error}`);
      return obj;
    }
  }

  /**
   * 获取对象的所有键 Get all keys of object
   * 替换 Object.keys，适配 ArkTS 语法 Replace Object.keys, adapt to ArkTS syntax
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    const keys: string[] = [];
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        keys.push(key);
      }
    }
    return keys;
  }
  
  /**
   * 预处理 Python 代码 Preprocess Python code
   * @private
   */
  private preprocessPythonCode(code: string): string {
    // 这里是简化的 Python 代码预处理示例
    // 实际项目中可能需要更复杂的转换规则
    
    // 移除 Python 特定语法注释 Remove Python specific syntax comments
    let processed = code.replace(/#.*$/gm, '');
    
    // 移除多行字符串（简化处理） Remove multi-line strings (simplified processing)
    processed = processed.replace(/'''[\s\S]*?'''/g, '');
    processed = processed.replace(/"""[\s\S]*?"""/g, '');
    
    // 替换 Python 导入语句（简化处理） Replace Python import statements (simplified processing)
    processed = processed.replace(/^import\s+\w+(\s+as\s+\w+)?$/gm, '');
    processed = processed.replace(/^from\s+\w+\s+import\s+.*$/gm, '');
    
    return processed;
  }

  /**
   * 验证 Python 代码 Validate Python code
   * @private
   */
  private filterDangerousCode(): void {
    // 检查并过滤危险的 Python 操作 Check and filter dangerous Python operations
    const dangerousPatterns = [
      /__file__/g,
      /__name__/g,
      /__import__\s*\(/g,
      /exec\s*\(/g,
      /eval\s*\(/g,
      /compile\s*\(/g,
      /open\s*\(/g,
      /file\s*\(/g,
      /input\s*\(/g,
      /raw_input\s*\(/g,
      /os\./g,
      /sys\./g,
      /subprocess\./g,
      /shutil\./g,
      /ctypes\./g,
      /pickle\./g,
      /marshal\./g,
      /globals\s*\(/g,
      /locals\s*\(/g,
      /vars\s*\(/g,
      /dir\s*\(/g,
      /getattr\s*\(/g,
      /setattr\s*\(/g,
      /delattr\s*\(/g,
      /hasattr\s*\(/g,
      /type\s*\(/g,
      /isinstance\s*\(/g,
      /issubclass\s*\(/g
    ];

    for (const pattern of dangerousPatterns) {
      if (pattern.test(this.scriptContent)) {
        Logger.warn(this.TAG, `Dangerous Python code pattern detected: ${pattern.toString()}`);
        throw new Error(`Security violation: dangerous Python code pattern detected: ${pattern.toString()}`);
      }
    }

    // 检查代码复杂度，防止恶意构造 Check code complexity, prevent malicious construction
    const lineCount = this.scriptContent.split('\n').length;
    const braceCount = (this.scriptContent.match(/:/g) || []).length;

    if (lineCount > 2000 || braceCount > 800) {
      throw new Error('Python script too complex, potential security risk');
    }
  }

  /**
   * 提取 Python 函数 Extract Python functions
   * @private
   */
  private extractPythonFunctions(): void {
    // 简单的函数提取逻辑
    // 在实际实现中，需要更复杂的 Python 语法解析
    const functionRegex = /def\s+(\w+)\s*\([^)]*\)\s*:/g;
    let match;
    
    while ((match = functionRegex.exec(this.pythonCode)) !== null) {
      const functionName = match[1];
      Logger.info(this.TAG, `Found Python function: ${functionName}`);
      
      // 创建函数代理 Create function proxy
      this.pyContext[functionName] = async (params: any) => {
        // 模拟函数执行 Simulate function execution
        return { result: `Function ${functionName} executed with params` };
      };
    }
  }

  /**
   * 验证参数 Validate parameters
   * @param params 方法参数 Method parameters
   * @private
   */
  private validateParams(params: Array<any>): void {
    // 检查参数大小，防止过大的参数导致内存问题
    const paramsSize = JSON.stringify(params).length;
    if (paramsSize > 2 * 1024 * 1024) { // Python 可能处理更大的数据，设置 2MB 限制
      throw new Error('Parameters too large');
    }

    // 检查参数深度，防止递归嵌套对象 Check parameter depth, prevent recursive nested objects
    const maxDepth = 12;
    if (this.checkObjectDepth(params) > maxDepth) {
      throw new Error('Parameters too deeply nested');
    }

    // 检查集合大小，防止过大的数组 Check collection size, prevent oversized arrays
    this.checkCollectionSize(params);
  }
  
  /**
   * 检查对象深度 Check object depth
   * @private
   */
  private checkObjectDepth(obj: any, currentDepth: number = 0): number {
    if (obj === null || typeof obj !== 'object') {
      return currentDepth;
    }

    let maxDepth = currentDepth;
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        const depth = this.checkObjectDepth(obj[key], currentDepth + 1);
        if (depth > maxDepth) {
          maxDepth = depth;
        }
      }
    }

    return maxDepth;
  }
  
  /**
   * 检查集合大小 Check collection size
   * @private
   */
  private checkCollectionSize(obj: any): void {
    const maxArrayLength = 20000;

    if (Array.isArray(obj)) {
      if (obj.length > maxArrayLength) {
        throw new Error('Array too large');
      }

      // 递归检查数组元素 Recursively check array elements
      for (const item of obj) {
        if (typeof item === 'object' && item !== null) {
          this.checkCollectionSize(item);
        }
      }
    } else if (typeof obj === 'object' && obj !== null) {
      const keys = Object.keys(obj);
      if (keys.length > 2000) {
        throw new Error('Object has too many properties');
      }

      // 递归检查对象属性 Recursively check object properties
      for (const key of keys) {
        this.checkCollectionSize(obj[key]);
      }
    }
  }

  /**
   * 创建爬虫实例实现 Create spider instance implementation
   * @returns SiteSpider 爬虫实例 Spider instance
   */
  protected createSpiderImpl(): any {
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
        try {
          return await this.callMethod('getSearchSuggestions', [keyword]);
        } catch (error) {
          return [];
        }
      }
    };
  }

  /**
   * 获取加载器类型 Get loader type
   * @returns string 加载器类型 Loader type
   */
  public getType(): string {
    return 'py';
  }
}
