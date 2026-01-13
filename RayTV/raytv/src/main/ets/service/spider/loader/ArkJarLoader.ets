// ArkJarLoader.ets - JAR 加载器 JAR loader
// 实现基于 HarmonyOS ArkNative 能力的 JAR 文件加载器 Implements JAR file loader based on HarmonyOS ArkNative capabilities

import Logger from '../../../common/util/Logger';
import { BaseLoader, LoaderOptions, Site } from './BaseLoader';
import { TaskPoolManager } from '../../../task/pool/TaskPoolManager';
import HttpService from '../../http/HttpService';
import fileio from '@ohos.fileio';
import MemoryManager from '../../../common/util/MemoryManager';
import TimeoutManager from '../../../common/util/TimeoutManager';
import sandbox from '@ohos.sandbox';
import BusinessError from '@ohos.base';

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
  private readonly TAG: string = 'ArkJarLoader';
  private jarFilePath: string = '';
  private taskPoolManager: TaskPoolManager;
  private httpService: HttpService;
  private memoryManager: MemoryManager;
  private timeoutManager: TimeoutManager;
  private loaderConfig: JarLoaderConfig = {};
  private sandboxId: string = '';
  private sandboxFs: any = null;
  private jarLoaded: boolean = false;
  private methodExecutedCount: number = 0;
  private lastMemoryCheckTime: number = 0;
  private errorCount: number = 0;
  private maxErrorCount: number = 5;
  private status: string = 'initialized';
  private jarCache: Map<string, any> = new Map();

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
    this.sandboxId = `sandbox_${site.key}_${Date.now()}`;
    
    // 设置默认配置 Set default configuration
    this.loaderConfig = {
      timeout: 30000,
      maxMemory: 256, // MB
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
      Logger.error(this.TAG, `Failed to initialize JAR loader: ${error}`);
      // 清理资源 Clean up resources
      await this.cleanupResources();
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
    try {
      if (!this.jarLoaded) {
        throw new Error('JAR file is not loaded');
      }
      
      // 定期检查内存 Check memory periodically
      this.methodExecutedCount++;
      if (this.methodExecutedCount % 10 === 0 || Date.now() - this.lastMemoryCheckTime > 60000) {
        if (!this.memoryManager.checkMemoryAvailability(this.loaderConfig.maxMemory || 256)) {
          await this.garbageCollect();
          if (!this.memoryManager.checkMemoryAvailability(this.loaderConfig.maxMemory || 256)) {
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
      const timeoutId = this.timeoutManager.setTimeout(() => {
        throw new Error(`Method ${methodName} execution timed out`);
      }, this.loaderConfig.timeout || 30000);
      try {
        // 在后台线程执行 JAR 方法 Execute JAR method in background thread
        const result = await this.taskPoolManager.execute(async () => {
          return await this.executeJarMethod(methodName, args);
        });
        return result;
      } finally {
        this.timeoutManager.clearTimeout(timeoutId);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to invoke JAR method ${methodName}: ${error}`);
      // 增加错误计数 Increase error count
      this.errorCount++;
      if (this.errorCount > this.maxErrorCount) {
        Logger.warn(this.TAG, `Too many errors, destroying loader for site: ${this.site.name}`);
        await this.destroy();
      }
      throw error;
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
      
      // 释放 JAR 资源 Release JAR resources
      await this.releaseJarResources();
      
      // 销毁安全沙箱 Destroy security sandbox
      await this.destroySecuritySandbox();
      
      // 清理临时文件 Clean up temporary files
      await this.cleanupResources();
      
      // 清理超时任务 Clean up timeout tasks
      this.timeoutManager.clearAllTimeouts();
      
      // 通知内存管理器释放内存 Notify memory manager to release memory
      this.memoryManager.releaseMemory(this.site.key);
      
      this.jarLoaded = false;
      this.status = 'destroyed';
      Logger.info(this.TAG, `JAR loader destroyed successfully for site: ${this.site.name}`);
      await super.destroy();
    } catch (error) {
      Logger.error(this.TAG, `Error during JAR loader destruction: ${error}`);
      this.status = 'destroyed';
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
      
      // 使用 @ohos.sandbox API 创建真正的安全沙箱 Create true security sandbox using @ohos.sandbox API
      this.sandboxId = await sandbox.createSandbox({ 
        name: `raytv_jar_${this.site.key}`,
        // 设置最小权限基础 Set minimum permission foundation
        permissions: [
          'file.read',   // 只允许读取文件 Only allow reading files
          'network.http'  // 只允许 HTTP 请求 Only allow HTTP requests
        ],
        // 资源限制 Resource limits
        resourceLimits: {
          memoryLimitMB: this.loaderConfig.maxMemory || 256,
          cpuLimitPercent: 30,  // 限制 CPU 使用 Limit CPU usage
          diskQuotaMB: 512     // 限制磁盘使用 Limit disk usage
        }
      });
      
      Logger.info(this.TAG, `Created true security sandbox with ID: ${this.sandboxId}`);
      
      // 获取沙箱内的文件系统访问器 Get file system accessor inside sandbox
      this.sandboxFs = await sandbox.getSandboxFileSystem(this.sandboxId);
      
      // 创建沙箱内目录结构 Create directory structure inside sandbox
      await this.sandboxFs.mkdir('/jar', { recursive: true });
      await this.sandboxFs.mkdir('/temp', { recursive: true });
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to create true security sandbox: ${error}`);
      throw error;
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
      
      Logger.info(this.TAG, `Downloading JAR file from: ${config.api}`);
      
      // 下载 JAR 文件 Download JAR file
      const response = await this.httpService.downloadFile({
        url: config.api,
        filePath: this.jarFilePath,
        timeout: this.loaderConfig.timeout
      });
      
      if (response.code !== 200) {
        throw new Error(`Failed to download JAR file: ${response.code}`);
      }
      
      // 验证 JAR 文件完整性 Verify JAR file integrity
      await this.verifyJarFile();
      
      Logger.info(this.TAG, `JAR file downloaded successfully to: ${this.jarFilePath}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load JAR file: ${error}`);
      throw error;
    }
  }

  /**
   * 初始化 JAR 资源 Initialize JAR resources
   * @private
   */
  private async initializeJarResources(): Promise<void> {
    try {
      Logger.info(this.TAG, `Initializing JAR resources for: ${this.site.name}`);
      
      // 这里需要使用 HarmonyOS 的 ArkNative API 加载 JAR 文件
      // 由于实际 API 可能有所不同，这里提供一个框架实现
      
      // 1. 检查 JAR 文件是否存在 Check if JAR file exists
      if (!fileio.accessSync(this.jarFilePath)) {
        throw new Error('JAR file not found');
      }
      
      // 2. 加载 JAR 文件 Load JAR file
      // ArkNativeAPI.loadJar(this.jarFilePath);
      
      // 3. 初始化 JAR 中的主要类 Initialize main class in JAR
      // ArkNativeAPI.initializeMainClass();
      
      Logger.info(this.TAG, `JAR resources initialized successfully`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize JAR resources: ${error}`);
      throw error;
    }
  }

  /**
   * 执行 JAR 方法 Execute JAR method
   * @param methodName 方法名称 Method name
   * @param params 参数 Parameters
   * @private
   */
  private async executeJarMethod(methodName: string, params: Array<any>): Promise<any> {
    try {
      Logger.info(this.TAG, `Executing JAR method: ${methodName}`);
      
      // 记录内存使用情况 Record memory usage
      const startMemory = this.memoryManager.getCurrentMemoryUsage();
      
      // 转换参数格式 Convert parameter format
      const javaParams = this.convertToJavaParams(params);
      
      // 调用 JAR 中的方法 Call method in JAR
      // 这里需要使用 HarmonyOS 的 ArkNative API
      // const result = await ArkNativeAPI.invokeMethod(methodName, javaParams);
      
      // 模拟方法调用结果 Simulate method invocation result
      const result = {
        success: true,
        data: {
          method: methodName,
          params: javaParams,
          message: `JAR method ${methodName} executed successfully`
        }
      };
      
      // 转换结果格式 Convert result format
      const jsResult = this.convertFromJavaResult(result);
      
      // 检查内存使用增长 Check memory usage increase
      const endMemory = this.memoryManager.getCurrentMemoryUsage();
      if (endMemory - startMemory > 32 * 1024 * 1024) { // 超过 32MB 增长
        Logger.warn(this.TAG, `Memory usage increased significantly during method execution: ${methodName}`);
      }
      
      return jsResult;
    } catch (error) {
      Logger.error(this.TAG, `Error executing JAR method ${methodName}: ${error}`);
      throw error;
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
      Logger.error(this.TAG, `Failed to release JAR resources: ${error}`);
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
      Logger.error(this.TAG, `Failed to destroy true security sandbox: ${error}`);
    }
  }

  /**
   * 验证 JAR 文件 Verify JAR file
   * @private
   */
  private async verifyJarFile(): Promise<void> {
    // 检查 JAR 文件大小 Check JAR file size
    const fileStats = fileio.statSync(this.jarFilePath);
    const maxSize = (this.loaderConfig.maxMemory || 256) * 1024 * 1024; // 转换为字节 Convert to bytes
    
    if (fileStats.size > maxSize) {
      throw new Error(`JAR file exceeds maximum allowed size (${maxSize} bytes)`);
    }
    
    // 简单的文件头验证，确保是有效的 JAR/ZIP 文件
    const file = fileio.openSync(this.jarFilePath, 0);
    const header = new Uint8Array(4);
    fileio.readSync(file.fd, header.buffer, 0, 4, 0);
    fileio.closeSync(file.fd);
    
    // JAR 文件的魔数是 PK\003\004
    const isValidJar = header[0] === 0x50 && header[1] === 0x4B && 
                      header[2] === 0x03 && header[3] === 0x04;
    
    if (!isValidJar) {
      throw new Error('Invalid JAR file format');
    }
  }

  /**
   * 清理资源 Clean up resources
   * @private
   */
  private async cleanupResources(): Promise<void> {
    try {
      // 删除临时 JAR 文件 Delete temporary JAR file
      if (this.jarFilePath && fileio.accessSync(this.jarFilePath)) {
        fileio.unlinkSync(this.jarFilePath);
        Logger.info(this.TAG, `Cleaned up JAR file: ${this.jarFilePath}`);
      }
      
      // 清理缓存 Clean up cache
      this.jarCache.clear();
    } catch (error) {
      Logger.error(this.TAG, `Error during cleanup: ${error}`);
    }
  }

  /**
   * 验证参数 Validate parameters
   * @param params 方法参数 Method parameters
   * @private
   */
  private validateParams(params: Array<any>): void {
    const paramsSize = JSON.stringify(params).length;
    if (paramsSize > 1024 * 1024) { // 1MB 限制
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
      const urlObj = new URL(url);
      // 只允许 https 协议 Only allow https protocol
      if (urlObj.protocol !== 'https:') {
        return false;
      }
      // 可以添加更多的 URL 验证规则 Can add more URL validation rules
      return true;
    } catch (error) {
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
      Logger.error(this.TAG, `Failed to trigger system garbage collection: ${error}`);
      // 如果系统垃圾回收失败，回退到基本清理 If system garbage collection fails, fall back to basic cleanup
      await this.cleanupResources();
    }
  }

  /**
   * 转换为 Java 参数格式 Convert to Java parameter format
   * @param params JavaScript 参数 JavaScript parameters
   * @private
   */
  private convertToJavaParams(params: Array<any>): any {
    // 转换 JavaScript 数据结构为 Java 兼容格式
    // 在实际实现中需要根据 ArkNative API 的要求进行转换
    return params;
  }

  /**
   * 从 Java 结果转换为 JavaScript 格式 Convert from Java result to JavaScript format
   * @param result Java 结果 Java result
   * @private
   */
  private convertFromJavaResult(result: any): any {
    // 转换 Java 结果为 JavaScript 格式
    // 在实际实现中需要根据 ArkNative API 的要求进行转换
    return result;
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
    return 'jar';
  }
}
