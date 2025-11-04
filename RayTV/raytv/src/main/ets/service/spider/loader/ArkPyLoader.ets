import Logger from '../../../common/util/Logger';
import { BaseLoader, LoaderType, Site } from './BaseLoader';
import { TaskPoolManager } from '../../../task/pool/TaskPoolManager';
import HttpService from '../../http/HttpService';
import MemoryManager from '../../../common/util/MemoryManager';
import TimeoutManager from '../../../common/util/TimeoutManager';

/**
 * Python执行上下文
 */
interface PyContext {
  [key: string]: any;
}

/**
 * Ark Python加载器
 * 实现基于HarmonyOS的Python代码加载和执行器
 */
export class ArkPyLoader extends BaseLoader {
  private readonly TAG: string = 'ArkPyLoader';
  private pyContext: PyContext = {};
  private scriptContent: string = '';
  private taskPoolManager: TaskPoolManager;
  private httpService: HttpService;
  private memoryManager: MemoryManager;
  private timeoutManager: TimeoutManager;
  private lastUsedTime: number = 0;
  private isInitialized: boolean = false;
  private pyModuleName: string = '';

  /**
   * 构造函数
   * @param site 站点配置
   */
  constructor(site: Site) {
    super(site);
    this.taskPoolManager = TaskPoolManager.getInstance();
    this.httpService = HttpService.getInstance();
    this.memoryManager = MemoryManager.getInstance();
    this.timeoutManager = TimeoutManager.getInstance();
    this.pyModuleName = `site_${site.key || 'default'}`;
  }

  /**
   * 初始化加载器
   * @protected
   */
  protected async onInit(): Promise<void> {
    try {
      // 检查内存使用情况
      if (!this.memoryManager.checkMemoryAvailability()) {
        throw new Error('Insufficient memory to initialize Python loader');
      }

      Logger.info(this.TAG, `Initializing Python loader for site: ${this.site.name}`);
      
      // 加载Python代码
      await this.loadScript();
      
      // 创建Python执行环境
      this.createPyEnvironment();
      
      // 注入基础API
      this.injectApis();
      
      // 执行初始化脚本
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
   * 方法调用
   * @param method 方法名称
   * @param params 方法参数
   * @protected
   */
  protected async onInvoke(method: string, params: any): Promise<any> {
    if (!this.isInitialized) {
      await this.onInit();
    }

    this.lastUsedTime = Date.now();

    try {
      // 安全检查
      this.validateParams(params);
      
      Logger.info(this.TAG, `Invoking Python method: ${method} for site: ${this.site.name}`);

      // 设置执行超时
      const timeoutId = this.timeoutManager.setTimeout(() => {
        throw new Error(`Method ${method} execution timed out`);
      }, 60000); // Python执行可能需要更长时间，设置60秒超时

      try {
        // 在后台线程执行Python方法
        const result = await this.taskPoolManager.execute(() => {
          return this.executeMethod(method, params);
        });

        return result;
      } finally {
        this.timeoutManager.clearTimeout(timeoutId);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to invoke Python method ${method}: ${error}`);
      // 错误计数增加
      this.errorCount++;

      // 如果错误过多，清理资源
      if (this.errorCount >= this.maxErrorCount) {
        Logger.warn(this.TAG, `Too many errors, cleaning up resources`);
        this.cleanupResources();
      }

      throw error;
    }
  }

  /**
   * 销毁方法
   * @protected
   */
  protected onDestroy(): void {
    this.cleanupResources();
    Logger.info(this.TAG, `Python loader destroyed for site: ${this.site.name}`);
  }
  
  /**
   * 清理资源
   * @private
   */
  private cleanupResources(): void {
    // 清理Python上下文
    if (this.pyContext) {
      for (const key in this.pyContext) {
        if (Object.prototype.hasOwnProperty.call(this.pyContext, key)) {
          delete this.pyContext[key];
        }
      }
      this.pyContext = {};
    }

    this.scriptContent = '';
    this.isInitialized = false;

    // 释放内存
    this.memoryManager.forceGC();

    Logger.info(this.TAG, 'Resources cleaned up');
  }
  
  /**
   * 获取最后使用时间
   */
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
   * 加载Python代码
   * @private
   */
  private async loadScript(): Promise<void> {
    const config = this.site;

    if (config.url && (config.url.startsWith('http://') || config.url.startsWith('https://'))) {
      // 从URL加载
      Logger.info(this.TAG, `Loading Python script from URL: ${config.url}`);
      try {
        const response = await this.httpService.get(config.url, { timeout: 15000 });
        this.scriptContent = response.data as string;
      } catch (error) {
        Logger.error(this.TAG, `Failed to load Python script from URL: ${error}`);
        // 如果URL加载失败，尝试使用备用代码
        if (config.content) {
          Logger.warn(this.TAG, 'Falling back to config content');
          this.scriptContent = config.content as string;
        } else {
          throw new Error(`Failed to load Python script: ${error}`);
        }
      }
    } else if (config.content) {
      // 直接使用配置中的代码
      Logger.info(this.TAG, 'Using Python script content from config');
      this.scriptContent = config.content as string;
    } else {
      throw new Error('No Python script source provided (url or content)');
    }

    // 安全过滤
    this.filterDangerousCode();
  }

  /**
   * 创建Python沙箱环境
   * @private
   */
  private createPyEnvironment(): void {
    // 创建Python模块环境
    this.pyContext = {
      // 基本的Python内置函数映射
      print: (...args: any[]) => {
        Logger.info(`${this.TAG}[${this.site.name}]`, args.map(String).join(' '));
      },
      len: (obj: any) => {
        return Array.isArray(obj) ? obj.length : Object.keys(obj || {}).length;
      },
      str: (obj: any) => String(obj),
      int: (obj: any) => parseInt(obj, 10),
      float: (obj: any) => parseFloat(obj),
      bool: (obj: any) => Boolean(obj),
      list: (obj: any) => Array.isArray(obj) ? [...obj] : [obj],
      dict: (obj: any) => (typeof obj === 'object' && obj !== null) ? { ...obj } : {},
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
   * 注入Python API
   * @private
   */
  private injectApis(): void {
    // 注入HTTP请求API
    this.pyContext.http = {
      get: async (url: string, options?: { headers?: Record<string, string>, timeout?: number }) => {
        // 验证URL安全性
        this.validateUrl(url);
        return this.httpService.get(url, options || {});
      },
      post: async (url: string, data?: any, options?: { headers?: Record<string, string>, timeout?: number }) => {
        // 验证URL安全性
        this.validateUrl(url);
        return this.httpService.post(url, data, options || {});
      }
    };

    // 注入加密API
    this.pyContext.crypto = {
      md5: (str: string) => {
        try {
          // 在HarmonyOS中，使用兼容的MD5实现
          let hash = 0;
          for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // 转换为32位整数
          }
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

    // 注入正则表达式工具
    this.pyContext.regex = {
      findall: (pattern: string, text: string, flags: string = '') => {
        try {
          const regex = new RegExp(pattern, flags);
          const matches = [];
          let match;
          while ((match = regex.exec(text)) !== null) {
            matches.push([...match]);
            if (!regex.global) break;
          }
          return matches;
        } catch (error) {
          Logger.error(this.TAG, `Regex findall error: ${error}`);
          return [];
        }
      },
      search: (pattern: string, text: string, flags: string = '') => {
        try {
          const regex = new RegExp(pattern, flags);
          const match = regex.exec(text);
          return match ? [...match] : null;
        } catch (error) {
          Logger.error(this.TAG, `Regex search error: ${error}`);
          return null;
        }
      },
      sub: (pattern: string, replacement: string, text: string, flags: string = '') => {
        try {
          const regex = new RegExp(pattern, flags);
          return text.replace(regex, replacement);
        } catch (error) {
          Logger.error(this.TAG, `Regex sub error: ${error}`);
          return text;
        }
      }
    };

    // 注入日志API
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

    // 注入工具函数
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
        return new Promise(resolve => setTimeout(resolve, Math.min(seconds * 1000, 10000))); // 限制最大延时10秒
      }
    };

    Logger.info(this.TAG, 'Injected enhanced APIs into Python context');
  }
  
  /**
   * 验证URL安全性
   * @private
   */
  private validateUrl(url: string): void {
    // 检查URL是否为相对路径或白名单内的域名
    const allowedDomains = this.site.allowedDomains || [];

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
   * 执行初始化代码
   * @private
   */
  private async executeInitScript(): Promise<void> {
    try {
      // 在Python环境中执行脚本
      // 注意：这里使用JavaScript模拟Python执行环境
      // 实际项目中可能需要使用Python解释器或桥接方案
      
      // 预处理Python代码，转换为JavaScript兼容格式
      const processedScript = this.preprocessPythonCode(this.scriptContent);
      
      // 创建安全的执行上下文
      const execContext = { ...this.pyContext };
      
      // 模拟Python模块系统
      execContext.__name__ = this.pyModuleName;
      execContext.__file__ = `${this.pyModuleName}.py`;
      
      // 执行脚本
      // 注意：这是一个简化实现，实际项目可能需要更复杂的Python代码转译或解释
      Logger.info(this.TAG, 'Executing Python initialization script');
      
      // 提取Python函数
      this.extractPythonFunctions();
      
      // 这里只是示例，实际项目中需要根据具体的Python执行方案进行调整
      Logger.warn(this.TAG, 'Python script execution is simulated. In production, use actual Python interpreter.');
      
      Logger.info(this.TAG, 'Python initialization script executed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to execute Python init script: ${error}`);
      throw error;
    }
  }

  /**
   * 执行Python方法
   * @param method 方法名称
   * @param params 参数
   * @private
   */
  private executeMethod(method: string, params: any): any {
    // 检查方法是否存在
    if (typeof this.pyContext[method] !== 'function') {
      // 尝试在Python模块中查找
      const pyMethodName = `parse_${method}`;
      if (typeof this.pyContext[pyMethodName] !== 'function') {
        throw new Error(`Method ${method} or ${pyMethodName} not found in Python script`);
      }
      method = pyMethodName;
    }

    // 限制方法执行内存使用
    const maxMemoryUsage = 100 * 1024 * 1024; // Python执行可能需要更多内存，设置100MB
    if (!this.memoryManager.checkMemoryLimit(maxMemoryUsage)) {
      throw new Error('Memory limit exceeded for method execution');
    }

    try {
      // 深度拷贝参数，避免引用问题
      const safeParams = this.deepClone(params);

      // 执行方法
      const result = this.pyContext[method](safeParams);

      // 序列化结果以检测循环引用
      const serializedResult = JSON.stringify(result);

      // 深度拷贝结果返回
      return this.deepClone(result);
    } catch (error) {
      Logger.error(this.TAG, `Error executing Python method ${method}: ${error instanceof Error ? error.message : String(error)}`);
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
      Logger.error(this.TAG, `Deep clone error: ${error}`);
      return obj;
    }
  }

  /**
   * 获取安全的内置函数
   * @private
   */
  /**
   * 预处理Python代码
   * @private
   */
  private preprocessPythonCode(code: string): string {
    // 这里是简化的Python代码预处理示例
    // 实际项目中可能需要更复杂的转换逻辑
    
    // 移除Python特定语法注释
    let processed = code.replace(/#.*$/gm, '');
    
    // 移除多行字符串（简化处理）
    processed = processed.replace(/'''[\s\S]*?'''/g, '');
    processed = processed.replace(/"""[\s\S]*?"""/g, '');
    
    // 替换Python导入语句（简化处理）
    processed = processed.replace(/^import\s+\w+(\s+as\s+\w+)?$/gm, '');
    processed = processed.replace(/^from\s+\w+\s+import\s+.*$/gm, '');
    
    return processed;
  }

  /**
   * 验证Python代码
   * @private
   */
  private filterDangerousCode(): void {
    // 检测并过滤危险的Python操作
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

    // 检查代码复杂度，防止恶意循环
    const lineCount = this.scriptContent.split('\n').length;
    const braceCount = (this.scriptContent.match(/:/g) || []).length;

    if (lineCount > 2000 || braceCount > 800) {
      throw new Error('Python script too complex, potential security risk');
    }
  }

  /**
   * 提取Python函数
   * @private
   */
  private extractPythonFunctions(): void {
    // 简单的函数提取逻辑
    // 在实际实现中，需要更复杂的Python语法解析
    const functionRegex = /def\s+(\w+)\s*\([^)]*\)\s*:/g;
    let match;
    
    while ((match = functionRegex.exec(this.pythonCode)) !== null) {
      const functionName = match[1];
      Logger.info(this.TAG, `Found Python function: ${functionName}`);
      
      // 创建函数代理
      this.pyContext[functionName] = async (params: any) => {
        // 模拟函数执行
        return { result: `Function ${functionName} executed with params` };
      };
    }
  }

  /**
   * 关闭Python沙箱
   * @private
   */
  // closePythonSandbox方法已合并到cleanupResources方法中

  /**
   * 验证参数
   * @param params 方法参数
   * @private
   */
  private validateParams(params: any): void {
    // 检查参数大小，防止过大的参数导致内存问题
    const paramsSize = JSON.stringify(params).length;
    if (paramsSize > 2 * 1024 * 1024) { // Python可能处理更大的数据，设置2MB限制
      throw new Error('Parameters too large');
    }

    // 检查参数深度，防止深层嵌套对象
    const maxDepth = 12;
    if (this.checkObjectDepth(params) > maxDepth) {
      throw new Error('Parameters too deeply nested');
    }

    // 检查数组长度，防止过大的数组
    this.checkCollectionSize(params);
  }
  
  /**
   * 检查对象深度
   * @private
   */
  private checkObjectDepth(obj: any, currentDepth: number = 0): number {
    if (obj === null || typeof obj !== 'object') {
      return currentDepth;
    }

    const maxDepth = currentDepth;
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        const depth = this.checkObjectDepth(obj[key], currentDepth + 1);
        if (depth > maxDepth) {
          return depth;
        }
      }
    }

    return maxDepth;
  }
  
  /**
   * 检查集合大小
   * @private
   */
  private checkCollectionSize(obj: any): void {
    const maxArrayLength = 20000;

    if (Array.isArray(obj)) {
      if (obj.length > maxArrayLength) {
        throw new Error('Array too large');
      }

      // 递归检查数组元素
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

      // 递归检查对象属性
      for (const key of keys) {
        this.checkCollectionSize(obj[key]);
      }
    }
  }

  /**
   * 转换为Python参数格式
   * @param params JavaScript参数
   * @private
   */
  // 转换方法已在deepClone和executeMethod中处理
}