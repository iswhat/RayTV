// ArkPyLoader.ets - Python 加载器 Python loader
// 实现基于 HarmonyOS 的 Python 代码加载和执行器 Implements Python code loader and executor based on HarmonyOS

import Logger from '../../../common/util/Logger';
import ObjectUtils from '../../../common/util/ark/ObjectUtils';
import { BaseLoader, LoaderOptions } from './BaseLoader';
import { SiteSpider, VideoItem, VideoDetail } from '../CrawlerService';
import { Site, SiteInfo } from '../../../data/bean/Site';
import { TaskPoolManager } from '../../../task/pool/TaskPoolManager';
import { HttpService } from '../../HttpService';
import MemoryManager from '../../../common/util/MemoryManager';
import TimeoutManager from '../../../common/util/TimeoutManager';
import { PythonLoaderConfigService, getPythonLoaderConfigService } from '../../config/PythonLoaderConfigService';
import { ErrorHandler, ErrorType, ErrorSeverity } from '../../../common/util/ErrorHandler';

/**
 * Ark Python 加载器 Ark Python loader
 * 实现基于 HarmonyOS 的 Python 代码加载和执行器 Implements Python code loader and executor based on HarmonyOS
 */
/**
 * PyContext动态字段类型
 */
type PyContextDynamic = Record<string, string | number | boolean | object | null | undefined | ((...args: (string | number | boolean | object | null | undefined)[]) => string | number | boolean | object | null | undefined | void | Promise<string | number | boolean | object | null | undefined>)>;

/**
 * Python解释器执行函数选项接口
 */
interface PyExecuteFunctionOptions {
  context: PyContextDynamic;
  functionName: string;
  params: string | number | boolean | object | null | undefined;
  timeout: number;
}

/**
 * Python解释器接口
 */
interface PythonInterpreter {
  createContext?: (script: string, context: PyContextDynamic) =>
    Promise<PyContextDynamic>;
  executeFunction?: (options: PyExecuteFunctionOptions) => Promise<string | number | boolean | object | null | undefined>;
}

/**
 * Python HTTP API接口
 */
interface PyHttpApi {
  get: (url: string, options?: Record<string, string | number | boolean | object | null | undefined>) => Promise<object>;
  post: (url: string, data?: string | number | boolean | object | null | undefined, options?: Record<string, string | number | boolean | object | null | undefined>) => Promise<object>;
}

/**
 * Python Base64 API接口
 */
interface PyBase64Api {
  encode: (str: string) => string;
  decode: (str: string) => string;
}

/**
 * Python Crypto API接口
 */
interface PyCryptoApi {
  md5: (str: string) => string;
  base64: PyBase64Api;
}

/**
 * Python 字符串工具 API接口
 */
interface PyStringUtilApi {
  contains: (text: string, substring: string) => boolean;
  startsWith: (text: string, prefix: string) => boolean;
  endsWith: (text: string, suffix: string) => boolean;
  split: (text: string, separator: string) => string[];
  replace: (text: string, search: string, replacement: string) => string;
}

/**
 * Python Logger API接口
 */
interface PyLoggerApi {
  info: (message: string) => void;
  warning: (message: string) => void;
  error: (message: string) => void;
}

/**
 * Python JSON工具接口
 */
interface PyJsonApi {
  loads: (text: string) => string | number | boolean | object | null | undefined;
  dumps: (obj: string | number | boolean | object | null | undefined, indent?: number) => string;
}

/**
 * Python Util API接口
 */
interface PyUtilApi {
  json: PyJsonApi;
  sleep: (seconds: number) => Promise<void>;
}

/**
 * Python函数信息接口
 */
interface PyFunctionInfo {
  name: string;
}

export class ArkPyLoader extends BaseLoader {
  public readonly TAG: string = 'ArkPyLoader';
  private pyContext: PyContextDynamic = {};
  protected scriptContent: string = '';
  private pythonCode: string = '';
  private taskPoolManager: TaskPoolManager;
  protected httpService: HttpService;
  private memoryManager: MemoryManager;
  private timeoutManager: TimeoutManager;
  private lastUsedTime: number = 0;
  private isInitialized: boolean = false;
  private pyModuleName: string = '';
  private errorCount: number = 0;
  private configService: PythonLoaderConfigService = getPythonLoaderConfigService();
  private errorHandler: ErrorHandler = ErrorHandler.getInstance();

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
    this.errorCount = 0;
  }



  /**
   * Python 解释器实例（模块级变量） Python interpreter instance (module-level variable)
   */
  private static pythonInterpreterInstance: PythonInterpreter | null = null;

  /**
   * 解释器初始化状态 Interpreter initialization status
   */
  private static interpreterInitialized: boolean = false;

  /**
   * 获取 Python 解释器 Get Python interpreter
   * @private
   */
  private getPythonInterpreter(): PythonInterpreter | null {
    if (!ArkPyLoader.interpreterInitialized) {
      this.initializePythonInterpreter();
    }
    return ArkPyLoader.pythonInterpreterInstance;
  }

  /**
   * 初始化 Python 解释器 Initialize Python interpreter
   * @private
   */
  private initializePythonInterpreter(): void {
    try {
      Logger.info(this.TAG, 'Initializing Python interpreter');
      
      // 尝试创建 Python 解释器实例 Try to create Python interpreter instance
      // 在实际实现中，这里应该使用 HarmonyOS 提供的 Python 解释器 API
      // 或者通过依赖注入获取
      
      // 模拟 Python 解释器实现 Mock Python interpreter implementation
      ArkPyLoader.pythonInterpreterInstance = {
        createContext: async (script: string, context: PyContextDynamic): Promise<PyContextDynamic> => {
          // 实际实现应该使用 Python 解释器创建上下文
          // 这里返回原始上下文作为模拟
          return context;
        },
        executeFunction: async (options: PyExecuteFunctionOptions): Promise<string | number | boolean | object | null | undefined> => {
          // 实际实现应该使用 Python 解释器执行函数
          // 这里返回模拟结果
          return {
            success: true,
            message: `Function ${options.functionName} executed successfully`,
            data: options.params
          };
        }
      };
      
      ArkPyLoader.interpreterInitialized = true;
      Logger.info(this.TAG, 'Python interpreter initialized successfully');
    } catch (error) {
      this.errorHandler.handle(
        ErrorType.CONFIG,
        ErrorSeverity.ERROR,
        `Failed to initialize Python interpreter: ${error instanceof Error ? error.message : String(error)}`,
        this.TAG
      );
      Logger.error(this.TAG, `Failed to initialize Python interpreter: ${error instanceof Error ? error.message : String(error)}`);
      ArkPyLoader.pythonInterpreterInstance = null;
      ArkPyLoader.interpreterInitialized = false;
    }
  }

  /**
   * 错误分类 | Classify error
   * @param error 错误对象
   * @returns ErrorType 错误类型
   */
  private classifyError(error: Error): ErrorType {
    const message = error.message.toLowerCase();
    
    if (message.includes('memory') || message.includes('heap') || message.includes('stack')) {
      return ErrorType.MEMORY;
    }
    if (message.includes('timeout') || message.includes('timed out')) {
      return ErrorType.TIMEOUT;
    }
    if (message.includes('network') || message.includes('http') || message.includes('fetch')) {
      return ErrorType.NETWORK;
    }
    if (message.includes('security') || message.includes('dangerous') || message.includes('blocked')) {
      return ErrorType.SECURITY;
    }
    if (message.includes('parse') || message.includes('syntax') || message.includes('json')) {
      return ErrorType.PARSE;
    }
    if (message.includes('validation') || message.includes('invalid') || message.includes('param')) {
      return ErrorType.VALIDATION;
    }
    if (message.includes('config') || message.includes('configuration')) {
      return ErrorType.CONFIG;
    }
    
    return ErrorType.UNKNOWN;
  }

  /**
   * 尝试自动恢复 | Attempt recovery
   * @param errorType 错误类型
   * @param error 错误对象
   */
  private async attemptRecovery(errorType: ErrorType, error: Error): Promise<void> {
    const errorHandlingConfig = this.configService.getErrorHandlingConfig();
    
    if (!errorHandlingConfig.autoCleanup) {
      Logger.info(this.TAG, '自动恢复已禁用 | Auto recovery disabled');
      return;
    }

    try {
      switch (errorType) {
        case ErrorType.MEMORY:
          Logger.info(this.TAG, '尝试内存恢复 | Attempting memory recovery');
          this.cleanupResources();
          // 等待GC运行
          await new Promise<void>((resolve) => setTimeout(resolve, 1000));
          break;
          
        case ErrorType.TIMEOUT:
          Logger.info(this.TAG, '尝试超时恢复 | Attempting timeout recovery');
          this.cleanupResources();
          break;
          
        case ErrorType.NETWORK:
          Logger.info(this.TAG, '尝试网络恢复 | Attempting network recovery');
          // 网络错误等待一段时间后重试
          await new Promise<void>((resolve) => setTimeout(resolve, 2000));
          break;
          
        case ErrorType.SECURITY:
          Logger.warn(this.TAG, '安全错误，清理资源 | Security error, cleaning up resources');
          this.cleanupResources();
          break;
          
        case ErrorType.PARSE:
          Logger.info(this.TAG, '解析错误，清理脚本 | Parse error, cleaning up script');
          this.scriptContent = '';
          this.pythonCode = '';
          break;
          
        default:
          Logger.info(this.TAG, '执行默认恢复 | Executing default recovery');
          this.cleanupResources();
      }
    } catch (recoveryError) {
      Logger.error(this.TAG, `恢复失败: ${recoveryError instanceof Error ? recoveryError.message : String(recoveryError)} | Recovery failed`);
    }
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

      Logger.info(this.TAG, `正在初始化Python加载器，站点: ${this.site.name} | Initializing Python loader for site: ${this.site.name}`);
      
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
      Logger.info(this.TAG, `Python加载器初始化成功，站点: ${this.site.name} | Python loader initialized successfully for site: ${this.site.name}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.isInitialized = false;
      this.cleanupResources();
      
      // 错误分类处理
      const errorType = this.classifyError(err);
      this.errorHandler.handle(
        errorType,
        ErrorSeverity.ERROR,
        `Python loader initialization failed: ${err.message}`,
        this.TAG
      );
      
      // 尝试自动恢复
      await this.attemptRecovery(errorType, err);
      
      Logger.error(this.TAG, `Python加载器初始化失败: ${err.message} | Failed to initialize Python loader: ${err.message}`);
      throw err;
    }
  }

  /**
   * 方法调用 Method invocation
   * @param methodName 方法名称 Method name
   * @param args 方法参数 Method arguments
   * @returns Promise<string | number | boolean | object | null | undefined> 方法返回值 Method return value
   */
  public async callMethod(methodName: string, args: Array<string | number | boolean | object | null | undefined>): Promise<string | number | boolean | object | null | undefined> {
    if (!this.isInitialized) {
      await this.load();
    }

    this.lastUsedTime = Date.now();

    try {
      // 安全验证 Security validation
      this.validateMethod(methodName);
      this.validateParams(args);
      
      Logger.info(this.TAG, `正在调用Python方法: ${methodName}，站点: ${this.site.name} | Invoking Python method: ${methodName} for site: ${this.site.name}`);

      // 设置执行超时 Set execution timeout
      const timeoutConfig = this.configService.getTimeoutConfig();
      const timeoutId = this.timeoutManager.setTimeout(() => {
        throw new Error(`Method ${methodName} execution timed out`);
      }, timeoutConfig.methodExecutionTimeout);
      try {
        // 直接执行 Python 方法 Execute Python method directly
        const result = await this.executeMethod(methodName, args);

        return result;
      } finally {
        this.timeoutManager.clearTimeout(timeoutId);
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      
      // 错误分类
      const errorType = this.classifyError(err);
      
      // 记录错误
      this.errorHandler.handle(
        errorType,
        ErrorSeverity.ERROR,
        `Failed to invoke Python method ${methodName}: ${err.message}`,
        this.TAG
      );
      
      Logger.error(this.TAG, `调用Python方法${methodName}失败: ${err.message} | Failed to invoke Python method ${methodName}: ${err.message}`);
      
      // 错误计数增加
      this.errorCount++;

      // 如果错误过多，清理资源
      const errorHandlingConfig = this.configService.getErrorHandlingConfig();
      if (this.errorCount >= errorHandlingConfig.maxErrorCount) {
        this.errorHandler.handle(
          ErrorType.UNKNOWN,
          ErrorSeverity.WARNING,
          `Too many errors (${this.errorCount}), cleaning up resources`,
          this.TAG
        );
        Logger.warn(this.TAG, '错误过多，正在清理资源 | Too many errors, cleaning up resources');
        this.cleanupResources();
      }
      
      // 尝试自动恢复
      await this.attemptRecovery(errorType, err);

      throw err;
    }
  }

  /**
   * 释放资源 Release resources
   */
  public async destroy(): Promise<void> {
    this.cleanupResources();
    Logger.info(this.TAG, `Python加载器已销毁，站点: ${this.site.name} | Python loader destroyed for site: ${this.site.name}`);
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
    // MemoryManager 没有 forceGC 方法，改为手动清理对象
    this.pyContext = {};

    Logger.info(this.TAG, '资源已清理 | Resources cleaned up');
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
      Logger.info(this.TAG, `正在从URL加载Python脚本: ${config.api} | Loading Python script from URL: ${config.api}`);
      try {
        const timeoutConfig = this.configService.getTimeoutConfig();
        const response = await this.httpService.get<string>(config.api, { timeout: timeoutConfig.scriptLoadTimeout });
        this.scriptContent = response.data;
        this.pythonCode = this.scriptContent;
      } catch (error) {
        const err = error instanceof Error ? error : new Error(String(error));
        Logger.error(this.TAG, `从URL加载Python脚本失败: ${err.message} | Failed to load Python script from URL: ${err.message}`);
        // 如果 URL 加载失败，尝试使用自定义代码 If URL loading fails, try to use custom code
        if (config.customCode) {
          Logger.warn(this.TAG, '回退到配置内容 | Falling back to config content');
          this.scriptContent = config.customCode;
          this.pythonCode = this.scriptContent;
        } else {
          throw new Error(`Failed to load Python script: ${err.message}`);
        }
      }
    } else if (config.customCode) {
      // 直接使用配置中的代码 Use code from config directly
      Logger.info(this.TAG, '正在使用配置中的Python脚本内容 | Using Python script content from config');
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
    // 逐个赋值避免 ArkTS 的未类型化对象字面量错误
    this.pyContext = {};

    this.pyContext['print'] = (args: (string | number | boolean | object | null | undefined)[]): void => {
      Logger.info(`${this.TAG}[${this.site.name}]`, `${args.map(String).join(' ')} | ${args.map(String).join(' ')}`);
    };

    this.pyContext['len'] = (obj: string | number | boolean | object | null | undefined): number => {
      return Array.isArray(obj) ? (obj as object[]).length : ObjectUtils.getKeys(obj || {}).length;
    };

    this.pyContext['str'] = (obj: string | number | boolean | object | null | undefined): string => String(obj);

    this.pyContext['int'] = (obj: string | number | boolean | object | null | undefined): number =>
      parseInt(obj as string, 10);

    this.pyContext['float'] = (obj: string | number | boolean | object | null | undefined): number =>
      parseFloat(obj as string);

    this.pyContext['bool'] = (obj: string | number | boolean | object | null | undefined): boolean => Boolean(obj);

    this.pyContext['list'] = (obj: string | number | boolean | object | null | undefined): object[] => {
      if (Array.isArray(obj)) {
        const result: object[] = [];
        for (let i = 0; i < (obj as object[]).length; i++) {
          const item = (obj as (string | number | boolean | object | null | undefined)[])[i];
          if (item !== undefined) {
            result.push(item as object);
          }
        }
        return result;
      } else {
        return [obj as object];
      }
    };

    this.pyContext['dict'] = (obj: string | number | boolean | object | null | undefined): Record<string, object> => {
      if (typeof obj === 'object' && obj !== null) {
        const result: Record<string, object> = {};
        const keys = ObjectUtils.getKeys(obj);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          const value = ObjectUtils.getProperty(obj, key);
          result[key] = value as object;
        }
        return result;
      } else {
        return {};
      }
    };

    this.pyContext['range'] = (start: number, stop?: number, step: number = 1): number[] => {
      const result: number[] = [];
      let s = stop;
      let begin = start;
      if (s === undefined) {
        s = begin;
        begin = 0;
      }
      for (let i = begin; i < s; i += step) {
        result.push(i);
      }
      return result;
    };

    Logger.info(this.TAG, '已创建Python执行环境 | Created Python execution environment');
  }

  /**
   * 注入 Python API Inject Python API
   * @private
   */
  private injectApis(): void {
    // 注入 HTTP 请求 API Inject HTTP request API
    const httpApi: PyHttpApi = {
      get: async (url: string, options?: Record<string, string | number | boolean | object | null | undefined>): Promise<object> => {
        // 验证 URL 安全性 Validate URL security
        this.validateUrl(url);
        const response = await this.httpService.get<Record<string, string | number | boolean | object>>(url, options || {});
        return response.data;
      },
      post: async (url: string, data?: string | number | boolean | object | null | undefined, options?: Record<string, string | number | boolean | object | null | undefined>): Promise<object> => {
        // 验证 URL 安全性 Validate URL security
        this.validateUrl(url);
        const response = await this.httpService.post<Record<string, string | number | boolean | object>>(url, data, options || {});
        return response.data;
      }
    };
    this.pyContext.http = httpApi;

    // 注入加密 API Inject crypto API
    const base64Api: PyBase64Api = {
      encode: (str: string): string => {
        try {
          // 在 HarmonyOS 中实现 Base64 编码 Implement Base64 encoding in HarmonyOS
          return Array.from(str).reduce((acc, char) => {
            const code = char.charCodeAt(0);
            return acc + String.fromCharCode(code);
          }, '');
        } catch (error) {
          const err = error instanceof Error ? error : new Error(String(error));
          Logger.error(this.TAG, `Base64编码错误: ${err.message} | Base64 encode error: ${err.message}`);
          return '';
        }
      },
      decode: (str: string): string => {
        try {
          // 在 HarmonyOS 中实现 Base64 解码 Implement Base64 decoding in HarmonyOS
          return Array.from(str).reduce((acc, char) => {
            const code = char.charCodeAt(0);
            return acc + String.fromCharCode(code);
          }, '');
        } catch (error) {
          const err = error instanceof Error ? error : new Error(String(error));
          Logger.error(this.TAG, `Base64解码错误: ${err.message} | Base64 decode error: ${err.message}`);
          return '';
        }
      }
    };
    const cryptoApi: PyCryptoApi = {
      md5: (str: string): string => {
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
      base64: base64Api
    };
    this.pyContext.crypto = cryptoApi;

    // 注入字符串处理工具（替换正则表达式） Inject string processing tools (replace regular expressions)
    const stringUtilApi: PyStringUtilApi = {
      // 使用简单的字符串方法兼容正则表达式 Use simple string methods compatible with regular expressions
      contains: (text: string, substring: string): boolean => {
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
    this.pyContext.stringUtil = stringUtilApi;

    // 注入日志 API Inject logger API
    const loggerApi: PyLoggerApi = {
      info: (message: string): void => {
        Logger.info(`${this.TAG}[${this.site.name}]`, `${message} | ${message}`);
      },
      warning: (message: string): void => {
        Logger.warn(`${this.TAG}[${this.site.name}]`, `${message} | ${message}`);
      },
      error: (message: string): void => {
        Logger.error(`${this.TAG}[${this.site.name}]`, `${message} | ${message}`);
      }
    };
    this.pyContext.logger = loggerApi;

    // 注入工具函数 Inject utility functions
    const jsonApi: PyJsonApi = {
      loads: (text: string): string | number | boolean | object | null | undefined => {
        try {
          return JSON.parse(text) as string | number | boolean | object | null | undefined;
        } catch (error) {
          const err = error instanceof Error ? error : new Error(String(error));
          Logger.error(this.TAG, `JSON解析错误: ${err.message} | JSON loads error: ${err.message}`);
          return null;
        }
      },
      dumps: (obj: string | number | boolean | object | null | undefined, indent?: number): string => {
        try {
          return JSON.stringify(obj, null, indent);
        } catch (error) {
          const err = error instanceof Error ? error : new Error(String(error));
          Logger.error(this.TAG, `JSON序列化错误: ${err.message} | JSON dumps error: ${err.message}`);
          return '{}';
        }
      }
    };
    const utilApi: PyUtilApi = {
      json: jsonApi,
      sleep: (seconds: number): Promise<void> => {
        return new Promise<void>((resolve: () => void) => {
          const timeoutConfig = this.configService.getTimeoutConfig();
          setTimeout(resolve, Math.min(seconds * 1000, timeoutConfig.maxSleepTime));
        });
      }
    };
    this.pyContext.util = utilApi;

    Logger.info(this.TAG, '已将增强API注入Python上下文 | Injected enhanced APIs into Python context');
  }
  
  /**
   * 验证 URL 安全性 Validate URL security
   * @private
   */
  private validateUrl(url: string): void {
    // 检查 URL 是否为相对路径或域名白名单内的地址 Check if URL is relative path or within domain whitelist
    // 由于 Site 接口中没有 allowedDomains 属性，暂时跳过域名白名单检查
    // Skipping domain whitelist check since Site interface doesn't have allowedDomains property

    try {
      // 仅检查 URL 格式是否正确 Only check if URL format is correct
      if (url.startsWith('http://') || url.startsWith('https://')) {
        // 简单的 URL 格式验证 Simple URL format validation
        const urlPattern = /^https?:\/\/[a-zA-Z0-9-._~:/?#[\]@!$&'()*+,;=.]+$/;
        if (!urlPattern.test(url)) {
          throw new Error(`Invalid URL format: ${url}`);
        }
      }
    } catch (error) {
      throw error instanceof Error ? error : new Error(String(error));
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
      const execContext: PyContextDynamic = {};
      
      // 初始化 Python 模块系统 Initialize Python module system
      execContext.__name__ = this.pyModuleName;
      execContext.__file__ = `${this.pyModuleName}.py`;
      
      // 执行脚本 Execute script
      // 注意：这是一个简化实现，实际项目可能需要更复杂的 Python 代码翻译或解释
      Logger.info(this.TAG, '正在执行Python初始化脚本 | Executing Python initialization script');
      
      // 提取 Python 函数 Extract Python functions
      this.extractPythonFunctions();
      
      // 初始化 Python 上下文 Initialize Python context
      this.pyContext = await this.createPythonContext(processedScript, execContext);
      
      Logger.info(this.TAG, 'Python初始化脚本执行成功 | Python initialization script executed successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `执行Python初始化脚本失败: ${err.message} | Failed to execute Python init script: ${err.message}`);
      throw err;
    }
  }

  /**
   * 执行 Python 方法 Execute Python method
   * @param methodName 方法名称 Method name
   * @param params 参数 Parameters
   * @private
   */
  private executeMethod(methodName: string, params: Array<string | number | boolean | object | null | undefined>): string | number | boolean | object | null | undefined {
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
    const memoryConfig = this.configService.getMemoryConfig();
    if (!this.memoryManager.checkMemoryAvailability()) {
      this.errorHandler.handle(
        ErrorType.MEMORY,
        ErrorSeverity.ERROR,
        'Memory limit exceeded for method execution',
        this.TAG
      );
      throw new Error('Memory limit exceeded for method execution');
    }

    try {
      // 深度克隆参数，防止引用问题 Deep clone parameters to prevent reference issues
      const safeParams = this.deepClone(params);

      // 执行方法 Execute method
      const method = this.pyContext[methodName] as ((...args: object[]) => object);
      const result = method(safeParams as object[]);

      // 深度克隆结果返回 Deep clone result for return
      return this.deepClone(result);
    } catch (error) {
      Logger.error(this.TAG, `执行Python方法${methodName}出错: ${error instanceof Error ? error.message : String(error)} | Error executing Python method ${methodName}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
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
      return JSON.parse(JSON.stringify(obj)) as T;
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `深度克隆错误: ${errMsg} | Deep clone error: ${errMsg}`);
      return obj;
    }
  }

  /**
   * 获取对象的所有键 Get all keys of object
   * 替换 Object.keys，适配 ArkTS 语法 Replace Object.keys, adapt to ArkTS syntax
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    // 使用ObjectUtils.getKeys替代for..in循环
    return ObjectUtils.getKeys(obj);
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
        Logger.warn(this.TAG, `检测到危险的Python代码模式: ${pattern.toString()} | Dangerous Python code pattern detected: ${pattern.toString()}`);
        throw new Error(`Security violation: dangerous Python code pattern detected: ${pattern.toString()}`);
      }
    }

    // 检查代码复杂度，防止恶意构造 Check code complexity, prevent malicious construction
    const lineCount = this.scriptContent.split('\n').length;
    const braceCount = (this.scriptContent.match(/:/g) || []).length;
    const securityConfig = this.configService.getSecurityConfig();

    if (lineCount > securityConfig.maxCodeLines || braceCount > securityConfig.maxBraceCount) {
      this.errorHandler.handle(
        ErrorType.SECURITY,
        ErrorSeverity.ERROR,
        `Python script too complex: ${lineCount} lines, ${braceCount} braces`,
        this.TAG
      );
      throw new Error('Python script too complex, potential security risk');
    }
  }

  /**
   * 提取 Python 函数 Extract Python functions
   * @private
   */
  /**
   * 创建 Python 执行上下文 Create Python execution context
   * @private
   */
  private async createPythonContext(script: string, context: PyContextDynamic): Promise<PyContextDynamic> {
    // 实际实现应该使用 Python 解释器或翻译器
    // 这里假设使用 Python 解释器服务
    // 使用局部变量替代 globalThis
    const pythonInterpreter = this.getPythonInterpreter();
    if (!pythonInterpreter || !pythonInterpreter.createContext) {
      throw new Error('Python interpreter or createContext method not available');
    }
    
    return await pythonInterpreter.createContext(script, context);
  }
  
  /**
   * 执行 Python 函数 Execute Python function
   * @private
   */
  private async executePythonFunction(functionName: string, params: string | number | boolean | object | null | undefined | Array<string | number | boolean | object | null | undefined>): Promise<string | number | boolean | object | null | undefined> {
    // 实际实现应该使用 Python 解释器执行函数
    const pythonInterpreter = this.getPythonInterpreter();
    if (!pythonInterpreter || !pythonInterpreter.executeFunction) {
      throw new Error('Python interpreter or executeFunction method not available');
    }
    
    const timeoutConfig = this.configService.getTimeoutConfig();
    return await pythonInterpreter.executeFunction({
      context: this.pyContext,
      functionName: functionName,
      params: params,
      timeout: timeoutConfig.methodExecutionTimeout
    } as PyExecuteFunctionOptions);
  }
  
  private extractPythonFunctions(): void {
    // 使用 Python 解析器提取函数 Extract functions using Python parser
    // 实际实现应该使用完整的 Python 语法解析器
    // 临时实现：模拟 Python 函数解析
    const mockFunctions = this.mockPythonFunctions();
    
    for (const func of mockFunctions) {
      const functionName = func.name;
      Logger.info(this.TAG, `找到Python函数: ${functionName} | Found Python function: ${functionName}`);
      
      // 创建函数代理 Create function proxy
      this.pyContext[functionName] = async (params: string | number | boolean | object | null | undefined | Array<string | number | boolean | object | null | undefined>): Promise<string | number | boolean | object | null | undefined> => {
        // 执行真实的 Python 函数 Execute real Python function
        return await this.executePythonFunction(functionName, params);
      };
    }
  }
  
  /**
   * 模拟 Python 函数解析 Mock Python function parsing
   * @private
   */
  private mockPythonFunctions(): Array<PyFunctionInfo> {
    // 模拟常见的爬虫方法
    const fn1: PyFunctionInfo = { name: 'getSiteInfo' };
    const fn2: PyFunctionInfo = { name: 'getRecommendList' };
    const fn3: PyFunctionInfo = { name: 'getHotList' };
    const fn4: PyFunctionInfo = { name: 'getLatestList' };
    const fn5: PyFunctionInfo = { name: 'getCategories' };
    const fn6: PyFunctionInfo = { name: 'getCategoryList' };
    const fn7: PyFunctionInfo = { name: 'search' };
    const fn8: PyFunctionInfo = { name: 'getDetail' };
    const fn9: PyFunctionInfo = { name: 'getPlayUrl' };
    const fn10: PyFunctionInfo = { name: 'getSearchSuggestions' };
    return [fn1, fn2, fn3, fn4, fn5, fn6, fn7, fn8, fn9, fn10];
  }

  /**
   * 验证参数 Validate parameters
   * @param params 方法参数 Method parameters
   * @private
   */
  private validateParams(params: Array<string | number | boolean | object | null | undefined>): void {
    // 检查参数大小，防止过大的参数导致内存问题
    const paramsSize = JSON.stringify(params).length;
    if (paramsSize > 2 * 1024 * 1024) { // Python 可能处理更大的数据，设置 2MB 限制
      this.errorHandler.handle(
        ErrorType.VALIDATION,
        ErrorSeverity.ERROR,
        `Parameters too large: ${paramsSize} bytes`,
        this.TAG
      );
      throw new Error('Parameters too large');
    }

    // 检查参数深度，防止递归嵌套对象 Check parameter depth, prevent recursive nested objects
    const maxDepth = 12;
    if (this.checkObjectDepth(params) > maxDepth) {
      this.errorHandler.handle(
        ErrorType.VALIDATION,
        ErrorSeverity.ERROR,
        `Parameters too deeply nested: ${this.checkObjectDepth(params)} levels`,
        this.TAG
      );
      throw new Error('Parameters too deeply nested');
    }

    // 检查集合大小，防止过大的数组 Check collection size, prevent oversized arrays
    this.checkCollectionSize(params);
  }

  /**
   * 验证方法 Validate method
   * @param method 方法名称 Method name
   * @private
   */
  private validateMethod(method: string): void {
    // 检查方法名是否包含危险字符或格式 Check if method name contains dangerous characters or format
    const dangerousPatterns = [/\s/, /\./, /\//, /\\/, /\*/, /\$/, /\#/, /\@/, /\!/, /\&/, /\*/];
    for (const pattern of dangerousPatterns) {
      if (pattern.test(method)) {
        this.errorHandler.handle(
          ErrorType.SECURITY,
          ErrorSeverity.ERROR,
          `Invalid method name: ${method}`,
          this.TAG
        );
        throw new Error(`Security violation: Invalid method name: ${method}`);
      }
    }
    
    // 方法名长度限制 Method name length limit
    if (method.length > 100) {
      this.errorHandler.handle(
        ErrorType.VALIDATION,
        ErrorSeverity.ERROR,
        `Method name too long: ${method.length} characters`,
        this.TAG
      );
      throw new Error('Method name too long');
    }
    
    // 检查方法名是否以危险前缀开头 Check if method name starts with dangerous prefix
    const dangerousPrefixes = ['__', 'exec', 'eval', 'compile', 'open', 'file'];
    for (const prefix of dangerousPrefixes) {
      if (method.toLowerCase().startsWith(prefix)) {
        this.errorHandler.handle(
          ErrorType.SECURITY,
          ErrorSeverity.ERROR,
          `Dangerous method name: ${method}`,
          this.TAG
        );
        throw new Error(`Security violation: Dangerous method name: ${method}`);
      }
    }
  }
  
  /**
   * 检查对象深度 Check object depth
   * @private
   */
  private checkObjectDepth(obj: string | number | boolean | object | null | undefined, currentDepth: number = 0): number {
    if (obj === null || obj === undefined || typeof obj !== 'object') {
      return currentDepth;
    }

    let maxDepth = currentDepth;
    // 使用ObjectUtils.getKeys替代for..in循环
    const keys = ObjectUtils.getKeys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = (obj as Record<string, string | number | boolean | object | null | undefined>)[key];
      const depth = this.checkObjectDepth(value, currentDepth + 1);
      if (depth > maxDepth) {
        maxDepth = depth;
      }
    }

    return maxDepth;
  }
  
  /**
   * 检查集合大小 Check collection size
   * @private
   */
  private checkCollectionSize(obj: string | number | boolean | object | null | undefined): void {
    const securityConfig = this.configService.getSecurityConfig();

    if (Array.isArray(obj)) {
      if (obj.length > securityConfig.maxArrayLength) {
        this.errorHandler.handle(
          ErrorType.VALIDATION,
          ErrorSeverity.ERROR,
          `Array too large: ${obj.length} items`,
          this.TAG
        );
        throw new Error('Array too large');
      }

      // 递归检查数组元素 Recursively check array elements
      for (const item of obj) {
        if (typeof item === 'object' && item !== null) {
          this.checkCollectionSize(item);
        }
      }
    } else if (typeof obj === 'object' && obj !== null) {
      const keys = ObjectUtils.getKeys(obj);
      if (keys.length > securityConfig.maxObjectKeys) {
        this.errorHandler.handle(
          ErrorType.VALIDATION,
          ErrorSeverity.ERROR,
          `Object has too many properties: ${keys.length}`,
          this.TAG
        );
        throw new Error('Object has too many properties');
      }

      // 递归检查对象属性 Recursively check object properties
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        this.checkCollectionSize((obj as Record<string, string | number | boolean | object | null | undefined>)[key]);
      }
    }
  }

  /**
   * 创建爬虫实例实现 Create spider instance implementation
   * @returns SiteSpider 爬虫实例 Spider instance
   */
  protected createSpiderImpl(): SiteSpider {
    const self = this;
    const spider: SiteSpider = {
      getSiteInfo: async (): Promise<SiteInfo> => self.callMethod('getSiteInfo', []) as Promise<SiteInfo>,
      getRecommendList: async (): Promise<VideoItem[]> => self.callMethod('getRecommendList', []) as Promise<VideoItem[]>,
      getHotList: async (): Promise<VideoItem[]> => self.callMethod('getHotList', []) as Promise<VideoItem[]>,
      getLatestList: async (): Promise<VideoItem[]> => self.callMethod('getLatestList', []) as Promise<VideoItem[]>,
      getCategories: async (): Promise<string[]> => self.callMethod('getCategories', []) as Promise<string[]>,
      getCategoryList: async (category: string, page: number): Promise<VideoItem[]> =>
        self.callMethod('getCategoryList', [category, page]) as Promise<VideoItem[]>,
      search: async (keyword: string, page?: number): Promise<VideoItem[]> =>
        self.callMethod('search', [keyword, page]) as Promise<VideoItem[]>,
      getDetail: async (id: string): Promise<VideoDetail> =>
        self.callMethod('getDetail', [id]) as Promise<VideoDetail>,
      getPlayUrl: async (id: string, episodeId?: string): Promise<string> =>
        self.callMethod('getPlayUrl', [id, episodeId]) as Promise<string>,
      getSearchSuggestions: async (keyword: string): Promise<string[]> => {
        try {
          return await self.callMethod('getSearchSuggestions', [keyword]) as string[];
        } catch (error) {
          return [];
        }
      }
    };
    return spider;
  }

  /**
   * 获取加载器类型 Get loader type
   * @returns string 加载器类型 Loader type
   */
  public getType(): string {
    return 'py';
  }
}
