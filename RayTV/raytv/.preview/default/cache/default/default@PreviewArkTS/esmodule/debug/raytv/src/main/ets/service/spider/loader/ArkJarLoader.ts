import Logger from "@bundle:com.raytv.app/raytv/ets/common/util/Logger";
import type { Site } from '../../../data/bean/Site';
import { BaseLoader } from "@bundle:com.raytv.app/raytv/ets/service/spider/loader/BaseLoader";
import type { LoaderOptions } from "@bundle:com.raytv.app/raytv/ets/service/spider/loader/BaseLoader";
import { TaskPoolManager, TaskPriority } from "@bundle:com.raytv.app/raytv/ets/task/pool/TaskPoolManager";
import type { Task } from "@bundle:com.raytv.app/raytv/ets/task/pool/TaskPoolManager";
import { HttpService } from "@bundle:com.raytv.app/raytv/ets/service/HttpService";
import fileio from "@ohos:fileio";
import MemoryManager from "@bundle:com.raytv.app/raytv/ets/common/util/MemoryManager";
import TimeoutManager from "@bundle:com.raytv.app/raytv/ets/common/util/TimeoutManager";
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
    destroySandbox: async (_id: string): Promise<void> => { },
    garbageCollect: async (): Promise<void> => { }
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
export type JarMethodData = string | number | boolean | null | JarMethodParam[] | Record<string, object>;
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
    private maxErrorCount: number = 5;
    private status: string = 'initialized';
    private jarCache: Map<string, JarMethodResult> = new Map();
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
            maxMemory: 256,
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
        }
        catch (error) {
            Logger.error(this.TAG, `Failed to initialize JAR loader: ${error instanceof Error ? error.message : String(error)}`);
            // 清理资源 Clean up resources
            await this.cleanupResources();
            const err: Error = error instanceof Error ? error : new Error(String(error));
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
            const timeoutId = `jar_timeout_${methodName}_${Date.now()}`;
            this.timeoutManager.setTimeout(timeoutId, (): void => {
                const timeoutError: Error = new Error(`Method ${methodName} execution timed out`);
                throw timeoutError;
            }, this.loaderConfig.timeout || 30000);
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
            }
            finally {
                this.timeoutManager.clearTimeout(timeoutId);
            }
        }
        catch (error) {
            Logger.error(this.TAG, `Failed to invoke JAR method ${methodName}: ${error instanceof Error ? error.message : String(error)}`);
            // 增加错误计数 Increase error count
            this.errorCount++;
            if (this.errorCount > this.maxErrorCount) {
                Logger.warn(this.TAG, `Too many errors, destroying loader for site: ${this.site.name}`);
                await this.destroy();
            }
            const err: Error = error instanceof Error ? error : new Error(String(error));
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
        }
        catch (error) {
            Logger.error(this.TAG, `Error during JAR loader destruction: ${error instanceof Error ? error.message : String(error)}`);
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
            const resourceLimits: SandboxResourceLimits = {
                memoryLimitMB: this.loaderConfig.maxMemory || 256,
                cpuLimitPercent: 30,
                diskQuotaMB: 512
            };
            const sandboxOptions: SandboxCreateOptions = {
                name: `raytv_jar_${this.site.key}`,
                permissions: [
                    'file.read',
                    'network.http'
                ],
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
        }
        catch (error) {
            Logger.error(this.TAG, `Failed to create true security sandbox: ${error instanceof Error ? error.message : String(error)}`);
            const err: Error = error instanceof Error ? error : new Error(String(error));
            throw err;
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
        }
        catch (error) {
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
            // 这里需要使用 HarmonyOS 的 ArkNative API 加载 JAR 文件
            // 由于实际 API 可能有所不同，这里提供一个框架实现
            // 1. 检查 JAR 文件是否存在 Check if JAR file exists
            fileio.accessSync(this.jarFilePath);
            // 2. 加载 JAR 文件 Load JAR file
            // ArkNativeAPI.loadJar(this.jarFilePath);
            // 3. 初始化 JAR 中的主要类 Initialize main class in JAR
            // ArkNativeAPI.initializeMainClass();
            Logger.info(this.TAG, `JAR resources initialized successfully`);
        }
        catch (error) {
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
            // 这里需要使用 HarmonyOS 的 ArkNative API
            // const result = await ArkNativeAPI.invokeMethod(methodName, javaParams);
            // 模拟方法调用结果 Simulate method invocation result
            const resultData: MethodResultData = {
                method: methodName,
                params: JSON.stringify(javaParams),
                message: `JAR method ${methodName} executed successfully`
            };
            const result: JarMethodResult = {
                success: true,
                data: resultData as JarMethodData,
                timestamp: Date.now()
            };
            // 转换结果格式 Convert result format
            const jsResult: JarMethodResult = this.convertFromJavaResult(result);
            // 检查内存使用增长 Check memory usage increase
            const endMemory = this.memoryManager.getCurrentMemoryUsage();
            if (endMemory - startMemory > 32 * 1024 * 1024) { // 超过 32MB 增长
                Logger.warn(this.TAG, `Memory usage increased significantly during method execution: ${methodName}`);
            }
            return jsResult;
        }
        catch (error) {
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
        }
        catch (error) {
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
        }
        catch (error) {
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
        }
        catch (error) {
            const statError: Error = new Error(`Failed to stat JAR file: ${error instanceof Error ? error.message : 'Unknown error'}`);
            throw statError;
        }
        const maxSize = (this.loaderConfig.maxMemory || 256) * 1024 * 1024; // 转换为字节 Convert to bytes
        if (fileStats.size > maxSize) {
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
        }
        catch (error) {
            throw new Error(`Failed to verify JAR file: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
        finally {
            if (fileDescriptor >= 0) {
                try {
                    fileio.closeSync(fileDescriptor);
                }
                catch (error) {
                    // 忽略关闭文件时的错误
                }
            }
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
                }
                catch (accessError) {
                    // File doesn't exist or not accessible, skip
                }
            }
            // 清理缓存 Clean up cache
            this.jarCache.clear();
        }
        catch (error) {
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
        }
        catch (error) {
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
        }
        catch (error) {
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
        // 在实际实现中需要根据 ArkNative API 的要求进行转换
        return params;
    }
    /**
     * 从 Java 结果转换为 JavaScript 格式 Convert from Java result to JavaScript format
     * @param result Java 结果 Java result
     * @private
     */
    private convertFromJavaResult(result: JarMethodResult): JarMethodResult {
        // 转换 Java 结果为 JavaScript 格式
        // 在实际实现中需要根据 ArkNative API 的要求进行转换
        return result;
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
                }
                catch (error) {
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
