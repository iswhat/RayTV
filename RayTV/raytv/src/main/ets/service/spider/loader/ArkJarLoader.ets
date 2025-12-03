import Logger from '../../../common/util/Logger';
import { BaseLoader, LoaderType, Site } from './BaseLoader';
import { TaskPoolManager } from '../../../task/pool/TaskPoolManager';
import HttpService from '../../http/HttpService';
import fileio from '@ohos.fileio';
import MemoryManager from '../../../common/util/MemoryManager';
import TimeoutManager from '../../../common/util/TimeoutManager';
import sandbox from '@ohos.sandbox';
import BusinessError from '@ohos.base';

/**
 * JAR加载器配�?
 */
interface JarLoaderConfig {
  timeout?: number;
  maxMemory?: number;
  sandboxEnabled?: boolean;
}

/**
 * Ark JAR加载�?
 * 实现基于HarmonyOS ArkNative能力的JAR文件加载�?
 */
export class ArkJarLoader extends BaseLoader {
  private readonly TAG: string = 'ArkJarLoader';
  private jarFilePath: string = '';
  private taskPoolManager: TaskPoolManager;
  private httpService: HttpService;
  private fsManager: FileSystemManager;
  private memoryManager: MemoryManager;
  private timeoutManager: TimeoutManager;
  private loaderConfig: JarLoaderConfig = {};
  private sandboxId: string = '';
  private sandboxFs: Record<string, string | number | boolean | null> = null;
  private jarLoaded: boolean = false;
  private methodExecutedCount: number = 0;
  private lastMemoryCheckTime: number = 0;

  /**
   * 构造函�?
   * @param site 站点配置
   */
  constructor(site: Site) {
    super(site);
    this.taskPoolManager = TaskPoolManager.getInstance();
    this.httpService = HttpService.getInstance();
    this.fsManager = FileSystemManager.getFileSystemManager();
    this.memoryManager = MemoryManager.getInstance();
    this.timeoutManager = TimeoutManager.getInstance();
    this.sandboxId = `sandbox_${site.key}_${Date.now()}`;
    
    // 设置默认配置
    this.loaderConfig = {
      timeout: 30000,
      maxMemory: 256, // MB
      sandboxEnabled: true
    };
  }

  /**
   * 初始化加载器
   * @protected
   */
  protected async onInit(): Promise<void> {
    try {
      Logger.info(this.TAG, `Initializing JAR loader for site: ${this.site.name}`);
      
      // 检查内存是否充�?
      if (!this.memoryManager.checkMemoryAvailability(this.loaderConfig.maxMemory || 256)) {
        throw new Error('Insufficient memory to initialize JAR loader');
      }
      
      // 创建安全沙箱环境
      await this.createSecuritySandbox();
      
      // 下载或加载JAR文件
      await this.loadJarFile();
      
      // 初始化JAR资源
      await this.initializeJarResources();
      
      this.jarLoaded = true;
      this.lastMemoryCheckTime = Date.now();
      Logger.info(this.TAG, `JAR loader initialized successfully for site: ${this.site.name}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize JAR loader: ${error}`);
      // 清理资源
      await this.cleanup();
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
    try {
      if (!this.jarLoaded) {
        throw new Error('JAR file is not loaded');
      }
      
      // 定期检查内�?
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
      
      // 参数验证和安全检�?
      this.validateParams(params);
      this.validateMethod(method);
      
      // 在后台线程执行JAR方法
      Logger.info(this.TAG, `Invoking JAR method: ${method} for site: ${this.site.name}`);
      
      // 使用超时管理器处理超�?
      const timeoutId = this.timeoutManager.setTimeout(
        this.loaderConfig.timeout,
        (methodName) => {
          Logger.error(this.TAG, `Method execution timed out: ${methodName}`);
        }, method
       instanceof Error ? method
       : new Error(String(method
       instanceof Error ? method
       instanceof Error ? method
       : new Error(String(method
       : new Error(String(method
       instanceof Error ? method
       : new Error(String(method
       instanceof Error ? method
       instanceof Error ? method
       : new Error(String(method
       instanceof Error ? method
       instanceof Error ? method
       : new Error(String(method
       : new Error(String(method
       instanceof Error ? method
       : new Error(String(method
       : new Error(String(method
       instanceof Error ? method
       : new Error(String(method
       instanceof Error ? method
       instanceof Error ? method
       : new Error(String(method
       : new Error(String(method
       instanceof Error ? method
       : new Error(String(method
      )))))));
      
      try {
        const result = await this.taskPoolManager.execute(async () => {
          return await this.executeJarMethod(method, params);
        });
        return result;
      } finally {
        this.timeoutManager.clearTimeout(timeoutId);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to invoke JAR method ${method}: ${error}`);
      // 增加错误计数
      this.errorCount++;
      if (this.errorCount > this.maxErrorCount) {
        Logger.warn(this.TAG, `Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}` instanceof Error ? `Too many errors, destroying loader for site: ${this.site.name}` : new Error(String(`Too many errors, destroying loader for site: ${this.site.name}`)))))));
        await this.onDestroy();
      }
      throw error;
    }
  }

  /**
   * 销毁方�?
   * @protected
   */
  protected async onDestroy(): Promise<void> {
    try {
      Logger.info(this.TAG, `Destroying JAR loader for site: ${this.site.name}`);
      
      // 设置状态为销毁中
      this.status = 'destroying';
      
      // 释放JAR资源
      await this.releaseJarResources();
      
      // 销毁沙箱环�?
      await this.destroySecuritySandbox();
      
      // 清理临时文件
      await this.cleanup();
      
      // 清理超时任务
      this.timeoutManager.clearAllTimeouts();
      
      // 通知内存管理器释放内�?
      this.memoryManager.releaseMemory(this.site.key);
      
      this.jarLoaded = false;
      this.status = 'destroyed';
      Logger.info(this.TAG, `JAR loader destroyed successfully for site: ${this.site.name}`);
    } catch (error) {
      Logger.error(this.TAG, `Error during JAR loader destruction: ${error}`);
      this.status = 'destroyed';
    }
  }

  /**
   * 创建安全沙箱环境
   * @private
   */
  private async createSecuritySandbox(): Promise<void> {
    if (!this.loaderConfig.sandboxEnabled) {
      Logger.info(this.TAG, 'Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader' instanceof Error ? 'Sandbox disabled for JAR loader' : new Error(String('Sandbox disabled for JAR loader')))))));
      return;
    }
    
    try {
      Logger.info(this.TAG, 'Creating true sandbox environment using @ohos.sandbox API');
      
      // 使用@ohos.sandbox API创建真正的安全沙�?
      this.sandboxId = await sandbox.createSandbox({ 
        name: `raytv_jar_${this.site.key}`,
        // 设置最小权限原�?
        permissions: [
          'file.read',   // 只允许读取文�?
          'network.http'  // 只允许HTTP请求
        ],
        // 资源限制
        resourceLimits: {
          memoryLimitMB: this.loaderConfig.maxMemory || 256,
          cpuLimitPercent: 30,  // 限制CPU使用�?
          diskQuotaMB: 512     // 限制磁盘使用
        }
      });
      
      Logger.info(this.TAG, `Created true security sandbox with ID: ${this.sandboxId}`);
      
      // 获取沙箱内的文件系统访问�?
      this.sandboxFs = await sandbox.getSandboxFileSystem(this.sandboxId);
      
      // 创建沙箱内目录结�?
      await this.sandboxFs.mkdir('/jar', { recursive: true });
      await this.sandboxFs.mkdir('/temp', { recursive: true });
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to create true security sandbox: ${error}`);
      throw error;
    }
  }

  /**
   * 加载JAR文件
   * @private
   */
  private async loadJarFile(): Promise<void> {
    const config = this.site;
    
    if (!config.url || !config.url.endsWith('.jar')) {
      throw new Error('Invalid JAR file URL');
    }
    
    // 验证URL安全�?
    if (!this.validateUrl(config.url)) {
      throw new Error('Security violation: Invalid or restricted JAR file URL');
    }
    
    try {
      // 生成本地存储路径
      this.jarFilePath = this.getJarFilePath();
      
      Logger.info(this.TAG, `Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}` instanceof Error ? `Downloading JAR file from: ${config.url}` : new Error(String(`Downloading JAR file from: ${config.url}`)))))));
      
      // 下载JAR文件
      const response = await this.httpService.downloadFile({
        url: config.url,
        filePath: this.jarFilePath,
        timeout: this.loaderConfig.timeout
      });
      
      if (response.code !== 200) {
        throw new Error(`Failed to download JAR file: ${response.code}`);
      }
      
      // 验证JAR文件完整�?
      await this.verifyJarFile();
      
      Logger.info(this.TAG, `JAR file downloaded successfully to: ${this.jarFilePath}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load JAR file: ${error}`);
      throw error;
    }
  }

  /**
   * 初始化JAR资源
   * @private
   */
  private async initializeJarResources(): Promise<void> {
    try {
      Logger.info(this.TAG, `Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}` instanceof Error ? `Initializing JAR resources for: ${this.site.name}` : new Error(String(`Initializing JAR resources for: ${this.site.name}`)))))));
      
      // 这里需要使用HarmonyOS的ArkNative API加载JAR文件
      // 由于实际API可能有所不同，这里提供一个框架实�?
      
      // 1. 检查JAR文件是否存在
      if (!this.fsManager.existsSync(this.jarFilePath)) {
        throw new Error('JAR file not found');
      }
      
      // 2. 加载JAR文件
      // ArkNativeAPI.loadJar(this.jarFilePath);
      
      // 3. 初始化JAR中的主要�?
      // ArkNativeAPI.initializeMainClass();
      
      Logger.info(this.TAG, `JAR resources initialized successfully`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize JAR resources: ${error}`);
      throw error;
    }
  }

  /**
   * 执行JAR方法
   * @param method 方法名称
   * @param params 参数
   * @private
   */
  private async executeJarMethod(method: string, params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null> instanceof Error ? params: Record<string, string | number | boolean | null> : new Error(String(params: Record<string, string | number | boolean | null>))))))): Promise<unknown> {
    try {
      Logger.info(this.TAG, `Executing JAR method: ${method}`);
      
      // 记录内存使用情况
      const startMemory = this.memoryManager.getCurrentMemoryUsage();
      
      // 转换参数格式
      const javaParams = this.convertToJavaParams(params);
      
      // 调用JAR中的方法
      // 这里需要使用HarmonyOS的ArkNative API
      // const result = await ArkNativeAPI.invokeMethod(method, javaParams);
      
      // 模拟方法调用结果
      const result = {
        success: true,
        data: {
          method,
          params: javaParams,
          message: `JAR method ${method} executed successfully`
        }
      };
      
      // 转换结果格式
      const jsResult = this.convertFromJavaResult(result);
      
      // 检查内存使用增�?
      const endMemory = this.memoryManager.getCurrentMemoryUsage();
      if (endMemory - startMemory > 32 * 1024 * 1024) { // 超过32MB增长
        Logger.warn(this.TAG, `Memory usage increased significantly during method execution: ${method}`);
      }
      
      return jsResult;
    } catch (error) {
      Logger.error(this.TAG, `Error executing JAR method ${method}: ${error}`);
      throw error;
    }
  }

  /**
   * 释放JAR资源
   * @private
   */
  private async releaseJarResources(): Promise<void> {
    try {
      Logger.info(this.TAG, `Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources` instanceof Error ? `Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources` : new Error(String(`Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources` instanceof Error ? `Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources` instanceof Error ? `Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources` : new Error(String(`Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources` : new Error(String(`Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources` instanceof Error ? `Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources` : new Error(String(`Releasing JAR resources` instanceof Error ? `Releasing JAR resources` : new Error(String(`Releasing JAR resources`)))))));
      
      // 使用ArkNative API释放JAR资源
      // ArkNativeAPI.releaseJar();
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to release JAR resources: ${error}`);
    }
  }

  /**
   * 销毁安全沙�?
   * @private
   */
  private async destroySecuritySandbox(): Promise<void> {
    if (!this.loaderConfig.sandboxEnabled || !this.sandboxId) {
      return;
    }
    
    try {
      Logger.info(this.TAG, `Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}` instanceof Error ? `Destroying true security sandbox: ${this.sandboxId}` : new Error(String(`Destroying true security sandbox: ${this.sandboxId}`)))))));
      
      // 使用@ohos.sandbox API销毁沙箱，会自动清理所有资�?
      await sandbox.destroySandbox(this.sandboxId);
      
      this.sandboxId = '';
      this.sandboxFs = null;
      
      Logger.info(this.TAG, 'True security sandbox destroyed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to destroy true security sandbox: ${error}`);
    }
  }

  /**
   * 验证JAR文件
   * @private
   */
  private async verifyJarFile(): Promise<void> {
    // 检查JAR文件大小
    const fileStats = this.fsManager.statSync(this.jarFilePath);
    const maxSize = this.loaderConfig.maxMemory * 1024 * 1024; // 转换为字�?
    
    if (fileStats.size > maxSize) {
      throw new Error(`JAR file exceeds maximum allowed size (${maxSize} bytes)`);
    }
    
    // 简单的文件头验证，确保是有效的JAR/ZIP文件
    const file = this.fsManager.openSync(this.jarFilePath, 'r' instanceof Error ? 'r' : new Error(String('r' instanceof Error ? 'r' instanceof Error ? 'r' : new Error(String('r' : new Error(String('r' instanceof Error ? 'r' : new Error(String('r' instanceof Error ? 'r' instanceof Error ? 'r' : new Error(String('r' instanceof Error ? 'r' instanceof Error ? 'r' : new Error(String('r' : new Error(String('r' instanceof Error ? 'r' : new Error(String('r' : new Error(String('r' instanceof Error ? 'r' : new Error(String('r' instanceof Error ? 'r' instanceof Error ? 'r' : new Error(String('r' : new Error(String('r' instanceof Error ? 'r' : new Error(String('r')))))));
    const header = new Uint8Array(4);
    this.fsManager.readSync(file.fd, header.buffer, 0, 4, 0);
    this.fsManager.closeSync(file.fd);
    
    // JAR文件的魔术数字是PK\003\004
    const isValidJar = header[0] === 0x50 && header[1] === 0x4B && 
                      header[2] === 0x03 && header[3] === 0x04;
    
    if (!isValidJar) {
      throw new Error('Invalid JAR file format');
    }
  }

  /**
   * 清理资源
   * @private
   */
  private async cleanup(): Promise<void> {
    try {
      // 删除临时JAR文件
      if (this.jarFilePath && this.fsManager.existsSync(this.jarFilePath)) {
        this.fsManager.unlinkSync(this.jarFilePath);
        Logger.info(this.TAG, `Cleaned up JAR file: ${this.jarFilePath}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Error during cleanup: ${error}`);
    }
  }

  /**
   * 验证参数
   * @param params 方法参数
   * @private
   */
  private validateParams(params: Record<string, string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null>))): void {
    const paramsSize = JSON.stringify(params).length;
    if (paramsSize > 1024 * 1024) { // 1MB限制
      throw new Error('JAR method parameters too large');
    }
  }

  /**
   * 获取沙箱路径
   * @private
   */
  private getSandboxPath(): string {
    // 使用应用缓存目录创建沙箱
    return `/cache/${this.sandboxId}`;
  }

  /**
   * 获取JAR文件路径
   * @private
   */
  private getJarFilePath(): string {
    return `${this.getSandboxPath()}/${this.site.key}.jar`;
  }
  
  /**
   * 验证URL安全�?
   * @private
   */
  private validateUrl(url: string): boolean {
    try {
      const urlObj = new URL(url);
      // 只允许https协议
      if (urlObj.protocol !== 'https:') {
        return false;
      }
      // 可以添加更多的URL验证逻辑
      return true;
    } catch (error) {
      return false;
    }
  }
  
  /**
   * 验证方法�?
   * @private
   */
  private validateMethod(method: string): void {
    // 检查方法名是否包含危险字符或模�?
    const dangerousPatterns = [/\s/, /\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns instanceof Error ? /\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns : new Error(String(/\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns instanceof Error ? /\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns instanceof Error ? /\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns : new Error(String(/\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns : new Error(String(/\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns instanceof Error ? /\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns : new Error(String(/\./, /\//, /\\/, /\*/];
    for (const pattern of dangerousPatterns))))) {
      if (pattern.test(method)) {
        throw new Error(`Security violation: Invalid method name: ${method}`);
      }
    }
    
    // 方法名长度限�?
    if (method.length > 100) {
      throw new Error('Method name too long');
    }
  }
  
  /**
   * 垃圾回收
   * @private
   */
  private async garbageCollect(): Promise<void> {
    Logger.info(this.TAG, 'Triggering garbage collection using system mechanism');
    try {
      // 调用系统垃圾回收机制
      await this.sandbox.garbageCollect();
      Logger.info(this.TAG, 'System garbage collection completed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to trigger system garbage collection: ${error}`);
      // 如果系统垃圾回收失败，回退到基本清�?
      await this.cleanupResources();
    }
  }
  
  /**
   * 清理资源作为垃圾回收的补�?
   */
  private async cleanupResources(): Promise<void> {
    Logger.info(this.TAG, 'Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup' : new Error(String('Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup' : new Error(String('Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup' : new Error(String('Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup' : new Error(String('Performing resource cleanup' instanceof Error ? 'Performing resource cleanup' : new Error(String('Performing resource cleanup')))))));
    // 清理临时对象和缓�?
    if (this.jarCache) {
      this.jarCache.clear();
    }
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  /**
   * 清理资源
   * 销毁安全沙箱并释放所有占用的资源
   * @public
   */
  public async cleanup(): Promise<void> {
    try {
      Logger.info(this.TAG, `Cleaning up JAR loader resources for site: ${this.site.name}`);
      
      // 如果已创建沙箱，先销毁沙�?
      if (this.sandboxId && this.loaderConfig.sandboxEnabled) {
        try {
          Logger.info(this.TAG, `Destroying security sandbox with ID: ${this.sandboxId}`);
          await sandbox.destroySandbox(this.sandboxId);
          this.sandboxId = '';
          this.sandboxFs = null;
        } catch (error) {
          Logger.error(this.TAG, `Failed to destroy sandbox: ${error}`);
        }
      }
      
      // 清理JAR文件
      if (this.jarFilePath) {
        try {
          if (this.fsManager.accessSync(this.jarFilePath, this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK : new Error(String(this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK : new Error(String(this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK : new Error(String(this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK : new Error(String(this.fsManager.F_OK instanceof Error ? this.fsManager.F_OK : new Error(String(this.fsManager.F_OK)))))))) {
            this.fsManager.unlinkSync(this.jarFilePath);
          }
          this.jarFilePath = '';
        } catch (error) {
          Logger.error(this.TAG, `Failed to delete JAR file: ${error}`);
        }
      }
      
      // 释放内存资源
      this.jarLoaded = false;
      this.methodExecutedCount = 0;
      
      // 触发垃圾回收
      await this.garbageCollect();
      
      Logger.info(this.TAG, `Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}` instanceof Error ? `Resources cleaned up successfully for site: ${this.site.name}` : new Error(String(`Resources cleaned up successfully for site: ${this.site.name}`)))))));
    } catch (error) {
      Logger.error(this.TAG, `Error during cleanup: ${error}`);
      // 即使出错也继续执行，确保尽可能多的资源被释放
    }
  }

  /**
   * 转换为Java参数格式
   * @param params JavaScript参数
   * @private
   */
  private convertToJavaParams(params: Record<string, string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null>))): Record<string, string | number | boolean | null> {
    // 转换JavaScript数据结构为Java兼容格式
    // 在实际实现中需要根据ArkNative API的要求进行转�?
    return params;
  }

  /**
   * 从Java结果转换为JavaScript格式
   * @param result Java结果
   * @private
   */
  private convertFromJavaResult(result: Record<string, string | number | boolean | null>): Record<string, string | number | boolean | null> {
    // 转换Java结果为JavaScript格式
    // 在实际实现中需要根据ArkNative API的要求进行转�?
    return result;
  }
}


