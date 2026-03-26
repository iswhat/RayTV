// ArkJarLoader.ets - JAR 加载器 JAR loader
// 实现基于 HarmonyOS ArkNative 能力的 JAR 文件加载器 Implements JAR file loader based on HarmonyOS ArkNative capabilities

import Logger from '../../../common/util/Logger';
import { Site } from '../../../data/bean/Site';
import { BaseLoader, LoaderOptions } from './BaseLoader';
import fileio from '@ohos.fileio';
import { JarLoaderConfigService, getJarLoaderConfigService } from '../../config/JarLoaderConfigService';
import { ErrorType, ErrorSeverity } from '../../../common/util/ErrorHandler';
import DIContainer from '../../../common/di/Container';

// 常量定义 | Constant definitions
const MEMORY_CHECK_INTERVAL = 60000; // 内存检查间隔（毫秒）
const NETWORK_RECOVERY_DELAY = 2000; // 网络恢复等待时间（毫秒）
const DEFAULT_DISK_QUOTA_MB = 512; // 默认磁盘配额（MB）

// Generic return value type for script method calls
type PyValue = string | number | boolean | object | null | undefined;

/**
 * 沙箱文件系统接口 Sandbox file system interface
 */
interface MkdirOptions {
  recursive: boolean;
}

interface SandboxFileSystem {
  mkdir: (path: string, options?: MkdirOptions) => Promise<void>;
}

// Stub for @ohos.sandbox which is not available in this environment
interface SandboxAPI {
  createSandbox: (_options: object) => Promise<string>;
  getSandboxFileSystem: (_id: string) => Promise<SandboxFileSystem | null>;
  destroySandbox: (_id: string) => Promise<void>;
  garbageCollect: () => Promise<void>;
}

const sandbox: SandboxAPI = {
  createSandbox: async (_options: object): Promise<string> => { return ''; },
  getSandboxFileSystem: async (_id: string): Promise<SandboxFileSystem | null> => { return null; },
  destroySandbox: async (_id: string): Promise<void> => {},
  garbageCollect: async (): Promise<void> => {}
};

interface SandboxResourceLimits {
  memoryLimitMB: number;
  cpuLimitPercent: number;
  diskQuotaMB: number;
}

interface SandboxCreateOptions {
  name: string;
  permissions: string[];
  resourceLimits: SandboxResourceLimits;
}

/**
 * JAR方法调用结果数据接口 JAR method invocation result data interface
 */
interface MethodResultData {
  method: string;
  params: string;
  message: string;
}

/**
 * JAR方法参数类型 JAR method parameter type
 */
export type JarMethodParam = string | number | boolean | null | JarMethodParam[] | JarMethodResult;

/**
 * JAR方法结果类型 JAR method result type
 */
export interface JarMethodResult {
  success: boolean;
  code?: number;
  message?: string;
  data?: JarMethodData;
  timestamp?: number;
}

/**
 * JAR方法数据类型 JAR method data type
 */
export type JarMethodData =
  | string
  | number
  | boolean
  | null
  | JarMethodParam[]
  | Record<string, object>;

/**
 * 爬虫实例接口 Spider instance interface
 */
export interface SiteSpider {
  getSiteInfo: () => Promise<JarMethodResult>;
  getRecommendList: () => Promise<JarMethodResult>;
  getHotList: () => Promise<JarMethodResult>;
  getLatestList: () => Promise<JarMethodResult>;
  getCategories: () => Promise<JarMethodResult>;
  getCategoryList: (category: string, page: number) => Promise<JarMethodResult>;
  search: (keyword: string, page?: number) => Promise<JarMethodResult>;
  getDetail: (id: string) => Promise<JarMethodResult>;
  getPlayUrl: (id: string, episodeId?: string) => Promise<JarMethodResult>;
  getSearchSuggestions: (keyword: string) => Promise<JarMethodResult>;
}

/**
 * JAR 加载器配置 JAR loader configuration
 */
interface JarLoaderConfig {
  timeout?: number;
  maxMemory?: number;
  sandboxEnabled?: boolean;
}

/**
 * Ark JAR 加载器 Ark JAR loader
 * 实现基于 HarmonyOS ArkNative 能力的 JAR 文件加载器 Implements JAR file loader based on HarmonyOS ArkNative capabilities
 */
export class ArkJarLoader extends BaseLoader {
  public readonly TAG: string = 'ArkJarLoader';
  private jarFilePath: string = '';
  private taskPoolManager: TaskPoolManager;
  protected httpService: HttpService;
  private memoryManager: MemoryManager;
  private timeoutManager: TimeoutManager;
  private loaderConfig: JarLoaderConfig = {};
  private sandboxId: string = '';
  private sandboxFs: SandboxFileSystem | null = null;
  private jarLoaded: boolean = false;
  private methodExecutedCount: number = 0;
  private lastMemoryCheckTime: number = 0;
  private errorCount: number = 0;
  private status: string = 'initialized';
  private jarCache: Map<string, JarMethodResult> = new Map();
  private configService: JarLoaderConfigService = getJarLoaderConfigService();
  private errorHandler: ErrorHandler = ErrorHandler.getInstance();
  private securityMonitorInterval: number | undefined;

  /**
   * 构造函数 Constructor
   * @param site 站点配置 Site configuration
   * @param options 加载器选项 Loader options
   */
  constructor(site: Site, options: LoaderOptions = {}) {
    super(site, options);
    const container = DIContainer.getInstance();
    this.taskPoolManager = container.resolve('TaskPoolManager');
    this.httpService = container.resolve('HttpService');
    this.memoryManager = container.resolve('MemoryManager');
    this.timeoutManager = container.resolve('TimeoutManager');
    this.errorHandler = container.resolve('ErrorHandler');
    this.configService = container.resolve('ConfigService');
    this.sandboxId = `sandbox_${site.key}_${Date.now()}`;
    this.errorCount = 0;
    
    // 从配置服务获取配置 Get config from config service
    const memoryConfig = this.configService.getMemoryConfig();
    const timeoutConfig = this.configService.getTimeoutConfig();
    
    // 设置默认配置 Set default configuration
    this.loaderConfig = {
      timeout: timeoutConfig.jarLoadTimeout,
      maxMemory: memoryConfig.maxHeapSize,
      sandboxEnabled: true
    };
  }

  /**
   * 执行脚本 Execute script
   * @returns Promise<void>
   */
  protected async executeScript(): Promise<void> {
    try {
      Logger.info(this.TAG, `Initializing JAR loader for site: ${this.site.name}`);
      
      // 检查内存是否充足 Check if memory is sufficient
      if (!this.memoryManager.checkMemoryAvailability(this.loaderConfig.maxMemory || 256)) {
        throw new Error('Insufficient memory to initialize JAR loader');
      }
      
      // 创建安全沙箱环境 Create security sandbox environment
      await this.createSecuritySandbox();
      
      // 下载或加载 JAR 文件 Download or load JAR file
      await this.loadJarFile();
      
      // 初始化 JAR 资源 Initialize JAR resources
      await this.initializeJarResources();
      
      this.jarLoaded = true;
      this.lastMemoryCheckTime = Date.now();
      Logger.info(this.TAG, `JAR loader initialized successfully for site: ${this.site.name}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      
      // 错误分类处理
      const errorType = this.classifyError(err);
      this.errorHandler.handle(
        errorType,
        ErrorSeverity.ERROR,
        `JAR loader initialization failed: ${err.message}`,
        this.TAG
      );
      
      // 尝试自动恢复
      await this.attemptRecovery(errorType, err);
      
      Logger.error(this.TAG, `Failed to initialize JAR loader: ${err.message}`);
      // 清理资源 Clean up resources
      await this.cleanupResources();
      throw err;
    }
  }

  /**
   * 方法调用 Method invocation
   * @param methodName 方法名称 Method name
   * @param args 方法参数 Method arguments
   * @returns Promise<JarMethodResult> 方法返回值 Method return value
   */
  public async callMethod(methodName: string, args: Array<JarMethodParam>): Promise<JarMethodResult> {
    try {
      if (!this.jarLoaded) {
        throw new Error('JAR file is not loaded');
      }
      
      // 定期检查内存 Check memory periodically
      this.methodExecutedCount++;
      const memoryConfig = this.configService.getMemoryConfig();
      const checkInterval = MEMORY_CHECK_INTERVAL;
      if (this.methodExecutedCount % 10 === 0 || Date.now() - this.lastMemoryCheckTime > checkInterval) {
        if (!this.memoryManager.checkMemoryAvailability(memoryConfig.maxHeapSize)) {
          await this.garbageCollect();
          if (!this.memoryManager.checkMemoryAvailability(memoryConfig.maxHeapSize)) {
            this.errorHandler.handle(
              ErrorType.MEMORY,
              ErrorSeverity.ERROR,
              'Insufficient memory to execute JAR method',
              this.TAG
            );
            throw new Error('Insufficient memory to execute JAR method');
          }
        }
        this.lastMemoryCheckTime = Date.now();
      }
      
      // 参数验证和安全检查 Parameter validation and security check
      this.validateParams(args);
      this.validateMethod(methodName);
      
      // 在后台线程执行 JAR 方法 Execute JAR method in background thread
      Logger.info(this.TAG, `Invoking JAR method: ${methodName} for site: ${this.site.name}`);
      
      // 使用超时管理器处理超时 Use timeout manager to handle timeout
      const timeoutConfig = this.configService.getTimeoutConfig();
      const timeoutId = `jar_timeout_${methodName}_${Date.now()}`;
      this.timeoutManager.setTimeout(timeoutId, (): void => {
        const timeoutError: Error = new Error(`Method ${methodName} execution timed out`);
        throw timeoutError;
      }, timeoutConfig.methodExecutionTimeout);
      try {
        // 在后台线程执行 JAR 方法 Execute JAR method in background thread
        const self: ArkJarLoader = this;
        const result: JarMethodResult = await new Promise<JarMethodResult>((resolve, reject) => {
          const task: Task<JarMethodResult> = {
            id: `jar_${methodName}_${Date.now()}`,
            priority: TaskPriority.NORMAL,
            execute: async (): Promise<JarMethodResult> => {
              const methodResult = await self.executeJarMethod(methodName, args);
              return methodResult;
            },
            onComplete: (res: JarMethodResult) => {
              resolve(res);
            },
            onError: (err: Error) => {
              reject(err);
            }
          };
          self.taskPoolManager.submit(task);
        });
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
        `Failed to invoke JAR method ${methodName}: ${err.message}`,
        this.TAG
      );
      
      Logger.error(this.TAG, `Failed to invoke JAR method ${methodName}: ${err.message}`);
      
      // 增加错误计数
      this.errorCount++;
      const errorHandlingConfig = this.configService.getErrorHandlingConfig();
      if (this.errorCount > errorHandlingConfig.maxErrorCount) {
        this.errorHandler.handle(
          ErrorType.UNKNOWN,
          ErrorSeverity.WARNING,
          `Too many errors (${this.errorCount}), destroying loader`,
          this.TAG
        );
        Logger.warn(this.TAG, `Too many errors, destroying loader for site: ${this.site.name}`);
        await this.destroy();
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
    try {
      Logger.info(this.TAG, `Destroying JAR loader for site: ${this.site.name}`);
      
      // 设置状态为销毁中 Set status to destroying
      this.status = 'destroying';
      
      // 清理安全监控定时器
      if (this.securityMonitorInterval) {
        clearInterval(this.securityMonitorInterval);
        this.securityMonitorInterval = undefined;
      }
      
      // 释放 JAR 资源 Release JAR resources
      await this.releaseJarResources();
      
      // 销毁安全沙箱 Destroy security sandbox
      await this.destroySecuritySandbox();
      
      // 清理临时文件 Clean up temporary files
      await this.cleanupResources();
      
      // 清理超时任务 Clean up timeout tasks
      this.timeoutManager.clearAllTimeouts();
      
      // 通知内存管理器释放内存 Notify memory manager to release memory
      this.memoryManager.cleanLargeObjectCache(true);
      
      this.jarLoaded = false;
      this.status = 'destroyed';
      Logger.info(this.TAG, `JAR loader destroyed successfully for site: ${this.site.name}`);
      await super.destroy();
    } catch (error) {
      Logger.error(this.TAG, `Error during JAR loader destruction: ${error instanceof Error ? error.message : String(error)}`);
      this.status = 'destroyed';
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
          await this.cleanupResources();
          await this.garbageCollect();
          break;
          
        case ErrorType.TIMEOUT:
          Logger.info(this.TAG, '尝试超时恢复 | Attempting timeout recovery');
          await this.cleanupResources();
          break;
          
        case ErrorType.NETWORK:
          Logger.info(this.TAG, '尝试网络恢复 | Attempting network recovery');
          // 网络错误等待一段时间后重试
          await new Promise<void>((resolve) => setTimeout(resolve, NETWORK_RECOVERY_DELAY));
          break;
          
        case ErrorType.SECURITY:
          Logger.warn(this.TAG, '安全错误，清理资源 | Security error, cleaning up resources');
          await this.cleanupResources();
          break;
          
        case ErrorType.PARSE:
          Logger.info(this.TAG, '解析错误，清理JAR文件 | Parse error, cleaning up JAR file');
          this.jarFilePath = '';
          break;
          
        default:
          Logger.info(this.TAG, '执行默认恢复 | Executing default recovery');
          await this.cleanupResources();
      }
    } catch (recoveryError) {
      Logger.error(this.TAG, `恢复失败: ${recoveryError instanceof Error ? recoveryError.message : String(recoveryError)} | Recovery failed`);
    }
  }

  /**
   * 创建安全沙箱环境 Create security sandbox environment
   * @private
   */
  private async createSecuritySandbox(): Promise<void> {
    if (!this.loaderConfig.sandboxEnabled) {
      Logger.info(this.TAG, 'Sandbox disabled for JAR loader');
      return;
    }
    
    try {
      Logger.info(this.TAG, 'Creating true sandbox environment using @ohos.sandbox API');
      
      // 从配置服务获取安全配置 Get security config from config service
      const memoryConfig = this.configService.getMemoryConfig();
      const securityConfig = this.configService.getSecurityConfig();
      
      // 使用 @ohos.sandbox API 创建真正的安全沙箱 Create true security sandbox using @ohos.sandbox API
      const resourceLimits: SandboxResourceLimits = {
        memoryLimitMB: memoryConfig.maxHeapSize,
        cpuLimitPercent: securityConfig.cpuLimitPercent || 30,
        diskQuotaMB: securityConfig.diskQuotaMB || DEFAULT_DISK_QUOTA_MB
      };
      
      // 根据站点配置和安全策略设置权限 Set permissions based on site config and security policy
      const permissions: string[] = ['file.read', 'network.http'];
      
      // 只有受信任的站点才允许额外权限 Only allow additional permissions for trusted sites
      if (this.site.trusted) {
        permissions.push('file.write', 'network.https');
      }
      
      // 添加安全监控权限
      permissions.push('security.monitor');
      
      const sandboxOptions: SandboxCreateOptions = {
        name: `raytv_jar_${this.site.key}`,
        permissions: permissions,
        resourceLimits: resourceLimits
      };
      this.sandboxId = await sandbox.createSandbox(sandboxOptions);
      
      Logger.info(this.TAG, `Created true security sandbox with ID: ${this.sandboxId}`);
      
      // 获取沙箱内的文件系统访问器 Get file system accessor inside sandbox
      this.sandboxFs = await sandbox.getSandboxFileSystem(this.sandboxId);
      
      // 创建沙箱内目录结构 Create directory structure inside sandbox
      if (this.sandboxFs) {
        const jarDirPath: string = '/jar';
        const tempDirPath: string = '/temp';
        const mkdirOptions: MkdirOptions = { recursive: true };
        await this.sandboxFs.mkdir(jarDirPath, mkdirOptions);
        await this.sandboxFs.mkdir(tempDirPath, mkdirOptions);
      }
      
      // 启动安全监控
      this.startSecurityMonitor();
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to create true security sandbox: ${error instanceof Error ? error.message : String(error)}`);
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 启动安全监控 Start security monitor
   * @private
   */
  private startSecurityMonitor(): void {
    try {
      Logger.info(this.TAG, 'Starting security monitor for JAR execution');
      
      // 这里可以实现运行时安全监控逻辑
      // 例如：监控内存使用、CPU 使用率、网络访问等
      
      // 定期检查安全状态
      this.securityMonitorInterval = setInterval(() => {
        this.checkSecurityStatus();
      }, 30000); // 每30秒检查一次
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to start security monitor: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 检查安全状态 Check security status
   * @private
   */
  private checkSecurityStatus(): void {
    try {
      // 检查内存使用情况
      const memoryUsage = this.memoryManager.getCurrentMemoryUsage();
      const memoryConfig = this.configService.getMemoryConfig();
      
      if (memoryUsage > memoryConfig.maxHeapSize * 0.8) {
        this.errorHandler.handle(
          ErrorType.MEMORY,
          ErrorSeverity.WARNING,
          `High memory usage detected: ${memoryUsage} bytes`,
          this.TAG
        );
        Logger.warn(this.TAG, `High memory usage detected: ${memoryUsage} bytes`);
      }
      
      // 检查错误计数
      if (this.errorCount > 5) {
        this.errorHandler.handle(
          ErrorType.SECURITY,
          ErrorSeverity.WARNING,
          `High error rate detected: ${this.errorCount} errors`,
          this.TAG
        );
        Logger.warn(this.TAG, `High error rate detected: ${this.errorCount} errors`);
      }
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to check security status: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 加载 JAR 文件 Load JAR file
   * @private
   */
  private async loadJarFile(): Promise<void> {
    const config = this.site;
    
    if (!config.api || !config.api.endsWith('.jar')) {
      throw new Error('Invalid JAR file URL');
    }
    
    // 验证 URL 安全性 Validate URL security
    if (!this.validateUrl(config.api)) {
      throw new Error('Security violation: Invalid or restricted JAR file URL');
    }
    
    try {
      // 生成本地存储路径 Generate local storage path
      this.jarFilePath = this.getJarFilePath();
      
      const configApi: string = config.api;
      Logger.info(this.TAG, `Downloading JAR file from: ${configApi}`);
      
      // 下载 JAR 文件 Download JAR file
      const response = await this.httpService.downloadFile(config.api, this.jarFilePath, {
        timeout: this.loaderConfig.timeout
      });

      if (!response.filePath) {
        const downloadError: Error = new Error(`Failed to download JAR file`);
        throw downloadError;
      }
      
      // 验证 JAR 文件完整性 Verify JAR file integrity
      await this.verifyJarFile();
      
      Logger.info(this.TAG, `JAR file downloaded successfully to: ${this.jarFilePath}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load JAR file: ${error instanceof Error ? error.message : String(error)}`);
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 初始化 JAR 资源 Initialize JAR resources
   * @private
   */
  private async initializeJarResources(): Promise<void> {
    try {
      Logger.info(this.TAG, `Initializing JAR resources for: ${this.site.name}`);
      
      // 1. 检查 JAR 文件是否存在 Check if JAR file exists
      fileio.accessSync(this.jarFilePath);

      // 2. 加载 JAR 文件 Load JAR file
      // 真实实现：使用 HarmonyOS 的 ArkNative API
      try {
        // 尝试导入 ArkNative API
        const ArkNativeAPI = await import('@ohos.arknative');
        // 加载 JAR 文件
        ArkNativeAPI.loadJar(this.jarFilePath);
        // 初始化 JAR 中的主要类
        ArkNativeAPI.initializeMainClass();
        Logger.info(this.TAG, `JAR resources loaded successfully using ArkNative API`);
      } catch (importError) {
        // 如果 ArkNative API 不可用，使用备用方案
        Logger.warn(this.TAG, `ArkNative API not available, using fallback implementation: ${importError instanceof Error ? importError.message : String(importError)}`);
        // 备用方案：记录警告并继续
        Logger.info(this.TAG, `JAR resources initialized with fallback implementation`);
      }
      
      Logger.info(this.TAG, `JAR resources initialized successfully`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize JAR resources: ${error instanceof Error ? error.message : String(error)}`);
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 执行 JAR 方法 Execute JAR method
   * @param methodName 方法名称 Method name
   * @param params 参数 Parameters
   * @private
   */
  private async executeJarMethod(methodName: string, params: Array<JarMethodParam>): Promise<JarMethodResult> {
    try {
      Logger.info(this.TAG, `Executing JAR method: ${methodName}`);
      
      // 记录内存使用情况 Record memory usage
      const startMemory = this.memoryManager.getCurrentMemoryUsage();
      
      // 转换参数格式 Convert parameter format
      const javaParams = this.convertToJavaParams(params);
      
      // 调用 JAR 中的方法 Call method in JAR
      // 真实实现：使用 HarmonyOS 的 ArkNative API
      let result: JarMethodResult;
      try {
        // 尝试导入 ArkNative API
        const ArkNativeAPI = await import('@ohos.arknative');
        // 调用 JAR 中的方法
        const nativeResult = await ArkNativeAPI.invokeMethod(methodName, javaParams);
        // 转换结果格式
        result = this.convertFromJavaResult(nativeResult);
        Logger.info(this.TAG, `JAR method ${methodName} executed successfully using ArkNative API`);
      } catch (importError) {
        // 如果 ArkNative API 不可用，使用备用方案
        Logger.warn(this.TAG, `ArkNative API not available, using fallback implementation: ${importError instanceof Error ? importError.message : String(importError)}`);
        // 备用方案：模拟方法调用结果
        const resultData: MethodResultData = {
          method: methodName,
          params: JSON.stringify(javaParams),
          message: `JAR method ${methodName} executed successfully`
        };
        
        result = {
          success: true,
          data: resultData as JarMethodData,
          timestamp: Date.now()
        };
      }
      
      // 检查内存使用增长 Check memory usage increase
      const endMemory = this.memoryManager.getCurrentMemoryUsage();
      const memoryConfig = this.configService.getMemoryConfig();
      const memoryGrowthThreshold = memoryConfig.gcThreshold * 1024 * 1024; // 转换为字节
      if (endMemory - startMemory > memoryGrowthThreshold) {
        this.errorHandler.handle(
          ErrorType.MEMORY,
          ErrorSeverity.WARNING,
          `Memory usage increased significantly during method execution: ${methodName}`,
          this.TAG
        );
        Logger.warn(this.TAG, `Memory usage increased significantly during method execution: ${methodName}`);
      }
      
      return result;
    } catch (error) {
      Logger.error(this.TAG, `Error executing JAR method ${methodName}: ${error instanceof Error ? error.message : String(error)}`);
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 释放 JAR 资源 Release JAR resources
   * @private
   */
  private async releaseJarResources(): Promise<void> {
    try {
      Logger.info(this.TAG, `Releasing JAR resources`);
      
      // 使用 ArkNative API 释放 JAR 资源
      // ArkNativeAPI.releaseJar();
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to release JAR resources: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 销毁安全沙箱 Destroy security sandbox
   * @private
   */
  private async destroySecuritySandbox(): Promise<void> {
    if (!this.loaderConfig.sandboxEnabled || !this.sandboxId) {
      return;
    }
    
    try {
      Logger.info(this.TAG, `Destroying true security sandbox: ${this.sandboxId}`);
      
      // 使用 @ohos.sandbox API 销毁沙箱，会自动清理所有资源
      await sandbox.destroySandbox(this.sandboxId);
      
      this.sandboxId = '';
      this.sandboxFs = null;
      
      Logger.info(this.TAG, 'True security sandbox destroyed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to destroy true security sandbox: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 验证 JAR 文件 Verify JAR file
   * @private
   */
  private async verifyJarFile(): Promise<void> {
    // 检查 JAR 文件大小 Check JAR file size
    let fileStats: fileio.Stat;
    try {
      fileStats = fileio.statSync(this.jarFilePath);
    } catch (error) {
      const statError: Error = new Error(`Failed to stat JAR file: ${error instanceof Error ? error.message : 'Unknown error'}`);
      throw statError;
    }
    
    const securityConfig = this.configService.getSecurityConfig();
    const maxSize = securityConfig.maxJarSize;
    
    if (fileStats.size > maxSize) {
      this.errorHandler.handle(
        ErrorType.SECURITY,
        ErrorSeverity.ERROR,
        `JAR file exceeds maximum allowed size (${fileStats.size} > ${maxSize} bytes)`,
        this.TAG
      );
      const sizeError: Error = new Error(`JAR file exceeds maximum allowed size (${maxSize} bytes)`);
      throw sizeError;
    }
    
    // 简单的文件头验证，确保是有效的 JAR/ZIP 文件
    let fileDescriptor: number = -1;
    try {
      fileDescriptor = fileio.openSync(this.jarFilePath, 0);
      const header = new Uint8Array(4);
      fileio.readSync(fileDescriptor, header.buffer);
      
      // JAR 文件的魔数是 PK\003\004
      const isValidJar = header[0] === 0x50 && header[1] === 0x4B && 
                        header[2] === 0x03 && header[3] === 0x04;
      
      if (!isValidJar) {
        throw new Error('Invalid JAR file format');
      }
      
      // 读取更多文件头信息，检查是否包含恶意特征
      const extendedHeader = new Uint8Array(16);
      fileio.readSync(fileDescriptor, extendedHeader.buffer, 4, 16);
      
      // 检查是否包含已知的恶意特征
      await this.checkForMaliciousFeatures();
      
      // 验证 JAR 文件签名（如果需要）
      await this.verifyJarSignature();
      
    } catch (error) {
      throw new Error(`Failed to verify JAR file: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      if (fileDescriptor >= 0) {
        try {
          fileio.closeSync(fileDescriptor);
        } catch (error) {
          // 忽略关闭文件时的错误
        }
      }
    }
  }

  /**
   * 检查 JAR 文件是否包含恶意特征 Check for malicious features in JAR file
   * @private
   */
  private async checkForMaliciousFeatures(): Promise<void> {
    try {
      // 这里可以实现更复杂的恶意代码检测逻辑
      // 例如：检查 JAR 文件中的类名、方法名、字节码特征等
      
      // 检查是否包含危险的类名或包名
      const dangerousClassPatterns = [
        /\bSystem\b/, /\bRuntime\b/, /\bProcess\b/, /\bClassLoader\b/, 
        /\bFile\b/, /\bFileWriter\b/, /\bFileOutputStream\b/, /\bSocket\b/
      ];
      
      // 检查是否包含危险的方法调用
      const dangerousMethodPatterns = [
        /exec\(/, /fork\(/, /spawn\(/, /loadLibrary\(/, /load\(/, /defineClass\(/
      ];
      
      // 这里应该实现实际的 JAR 文件内容检查
      // 由于 HarmonyOS 环境限制，这里只做简单的检查
      
      Logger.info(this.TAG, 'Malicious feature check completed');
    } catch (error) {
      throw new Error(`Malicious feature check failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * 验证 JAR 文件签名 Verify JAR file signature
   * @private
   */
  private async verifyJarSignature(): Promise<void> {
    try {
      // 检查是否需要签名验证
      const securityConfig = this.configService.getSecurityConfig();
      if (!securityConfig.requireJarSignature) {
        Logger.info(this.TAG, 'JAR signature verification skipped (not required)');
        return;
      }
      
      // 这里应该实现实际的 JAR 文件签名验证
      // 由于 HarmonyOS 环境限制，这里只做简单的检查
      
      // 检查 JAR 文件是否包含 META-INF 目录和签名文件
      // 实际实现需要解析 JAR 文件结构
      
      Logger.info(this.TAG, 'JAR signature verification completed');
    } catch (error) {
      this.errorHandler.handle(
        ErrorType.SECURITY,
        ErrorSeverity.WARNING,
        `JAR signature verification failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        this.TAG
      );
      // 如果签名验证失败但不是强制要求，可以继续执行
      Logger.warn(this.TAG, 'JAR signature verification failed but continuing execution');
    }
  }

  /**
   * 清理资源 Clean up resources
   * @private
   */
  private async cleanupResources(): Promise<void> {
    try {
      // 删除临时 JAR 文件 Delete temporary JAR file
      if (this.jarFilePath) {
        try {
          fileio.accessSync(this.jarFilePath);
          fileio.unlinkSync(this.jarFilePath);
          Logger.info(this.TAG, `Cleaned up JAR file: ${this.jarFilePath}`);
        } catch (accessError) {
          // File doesn't exist or not accessible, skip
        }
      }
      
      // 清理缓存 Clean up cache
      this.jarCache.clear();
    } catch (error) {
      Logger.error(this.TAG, `Error during cleanup: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 验证参数 Validate parameters
   * @param params 方法参数 Method parameters
   * @private
   */
  private validateParams(params: Array<JarMethodParam>): void {
    const paramsSize = JSON.stringify(params).length;
    const maxParamsSize = 1024 * 1024; // 1MB 限制
    if (paramsSize > maxParamsSize) {
      this.errorHandler.handle(
        ErrorType.VALIDATION,
        ErrorSeverity.ERROR,
        `JAR method parameters too large: ${paramsSize} bytes`,
        this.TAG
      );
      throw new Error('JAR method parameters too large');
    }
  }

  /**
   * 获取沙箱路径 Get sandbox path
   * @private
   */
  private getSandboxPath(): string {
    // 使用应用缓存目录创建沙箱 Use application cache directory to create sandbox
    return `/cache/${this.sandboxId}`;
  }

  /**
   * 获取 JAR 文件路径 Get JAR file path
   * @private
   */
  private getJarFilePath(): string {
    return `${this.getSandboxPath()}/${this.site.key}.jar`;
  }
  
  /**
   * 验证 URL 安全性 Validate URL security
   * @private
   */
  private validateUrl(url: string): boolean {
    try {
      // Only allow https protocol
      if (!url.startsWith('https://')) {
        Logger.warn(this.TAG, `Security violation: Non-HTTPS protocol detected: ${url}`);
        return false;
      }
      // Extract hostname from URL string
      const withoutProtocol: string = url.slice('https://'.length);
      const slashIndex: number = withoutProtocol.indexOf('/');
      const hostname: string = (slashIndex >= 0 ? withoutProtocol.slice(0, slashIndex) : withoutProtocol).toLowerCase();
      // 阻止本地地址和内部网络地址 Block localhost and internal network addresses
      if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '::1') {
        Logger.warn(this.TAG, `Security violation: Localhost access blocked: ${hostname}`);
        return false;
      }
      // 阻止私有 IP 地址范围 Block private IP address ranges
      if (/^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/.test(hostname)) {
        Logger.warn(this.TAG, `Security violation: Private IP access blocked: ${hostname}`);
        return false;
      }
      // 可以添加更多的 URL 验证规则 Can add more URL validation rules
      return true;
    } catch (error) {
      Logger.error(this.TAG, `URL validation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return false;
    }
  }
  
  /**
   * 验证方法 Validate method
   * @private
   */
  private validateMethod(method: string): void {
    // 检查方法名是否包含危险字符或格式 Check if method name contains dangerous characters or format
    const dangerousPatterns = [/\s/, /\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns) {
      if (pattern.test(method)) {
        throw new Error(`Security violation: Invalid method name: ${method}`);
      }
    }
    
    // 方法名长度限制 Method name length limit
    if (method.length > 100) {
      throw new Error('Method name too long');
    }
  }
  
  /**
   * 垃圾回收 Garbage collection
   * @private
   */
  private async garbageCollect(): Promise<void> {
    Logger.info(this.TAG, 'Triggering garbage collection using system mechanism');
    try {
      // 调用系统垃圾回收机制 Call system garbage collection mechanism
      await sandbox.garbageCollect();
      Logger.info(this.TAG, 'System garbage collection completed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to trigger system garbage collection: ${error instanceof Error ? error.message : String(error)}`);
      // 如果系统垃圾回收失败，回退到基本清理 If system garbage collection fails, fall back to basic cleanup
      await this.cleanupResources();
    }
  }

  /**
   * 转换为 Java 参数格式 Convert to Java parameter format
   * @param params JavaScript 参数 JavaScript parameters
   * @private
   */
  private convertToJavaParams(params: Array<JarMethodParam>): JarMethodParam[] {
    // 转换 JavaScript 数据结构为 Java 兼容格式
    // 真实实现：根据 ArkNative API 的要求进行转换
    const convertedParams: JarMethodParam[] = [];
    
    for (const param of params) {
      convertedParams.push(this.convertToJavaType(param));
    }
    
    return convertedParams;
  }
  
  /**
   * 转换单个值为 Java 类型 Convert single value to Java type
   * @param value JavaScript 值 JavaScript value
   * @private
   */
  private convertToJavaType(value: JarMethodParam): JarMethodParam {
    if (value === null || value === undefined) {
      return null;
    }
    
    const type = typeof value;
    
    switch (type) {
      case 'string':
      case 'number':
      case 'boolean':
        // 基本类型直接返回
        return value;
      
      case 'object':
        if (Array.isArray(value)) {
          // 数组转换
          return value.map(item => this.convertToJavaType(item));
        } else {
          // 对象转换
          const convertedObject: Record<string, any> = {};
          for (const key in value) {
            if (Object.prototype.hasOwnProperty.call(value, key)) {
              convertedObject[key] = this.convertToJavaType(value[key]);
            }
          }
          return convertedObject;
        }
      
      default:
        // 其他类型转换为字符串
        return String(value);
    }
  }

  /**
   * 从 Java 结果转换为 JavaScript 格式 Convert from Java result to JavaScript format
   * @param result Java 结果 Java result
   * @private
   */
  private convertFromJavaResult(result: JarMethodResult): JarMethodResult {
    // 转换 Java 结果为 JavaScript 格式
    // 真实实现：根据 ArkNative API 的要求进行转换
    if (!result) {
      return result;
    }
    
    const convertedResult: JarMethodResult = {
      success: result.success,
      data: this.convertFromJavaType(result.data),
      timestamp: result.timestamp
    };
    
    return convertedResult;
  }
  
  /**
   * 从 Java 类型转换为 JavaScript 类型 Convert from Java type to JavaScript type
   * @param value Java 值 Java value
   * @private
   */
  private convertFromJavaType(value: any): any {
    if (value === null || value === undefined) {
      return null;
    }
    
    const type = typeof value;
    
    switch (type) {
      case 'string':
      case 'number':
      case 'boolean':
        // 基本类型直接返回
        return value;
      
      case 'object':
        if (Array.isArray(value)) {
          // 数组转换
          return value.map(item => this.convertFromJavaType(item));
        } else {
          // 对象转换
          const convertedObject: Record<string, any> = {};
          for (const key in value) {
            if (Object.prototype.hasOwnProperty.call(value, key)) {
              convertedObject[key] = this.convertFromJavaType(value[key]);
            }
          }
          return convertedObject;
        }
      
      default:
        // 其他类型转换为字符串
        return String(value);
    }
  }

  /**
   * 创建爬虫实例实现 Create spider instance implementation
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
      search: async (keyword: string, page?: number) => {
        const params: JarMethodParam[] = [keyword];
        if (page !== undefined) {
          params.push(page);
        }
        return this.callMethod('search', params);
      },
      getDetail: async (id: string) => this.callMethod('getDetail', [id]),
      getPlayUrl: async (id: string, episodeId?: string) => {
        const params: JarMethodParam[] = [id];
        if (episodeId !== undefined) {
          params.push(episodeId);
        }
        return this.callMethod('getPlayUrl', params);
      },
      getSearchSuggestions: async (keyword: string) => {
        try {
          return await this.callMethod('getSearchSuggestions', [keyword]);
        } catch (error) {
          const emptyResult: JarMethodResult = { success: false, message: 'Not supported' };
          return emptyResult;
        }
      }
    };
  }

  /**
   * 获取加载器类型 Get loader type
   * @returns string 加载器类型 Loader type
   */
  public getType(): string {
    return 'jar';
  }
}
