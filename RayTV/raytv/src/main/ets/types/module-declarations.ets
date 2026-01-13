// module-declarations.ets - 模块声明文件，用于解决复杂的模块类型声明问题 // Module declaration file for resolving complex module type declaration issues

// @ohos module declarations // @ohos模块声明
declare module '@ohos.net.http' {
  export interface HttpRequest {
    /**
     * Send HTTP request | 发送HTTP请求
     * @param url Request URL | 请求URL
     * @param options Request options | 请求选项
     * @returns Promise with HttpResponse | 包含HttpResponse的Promise
     */
    request(url: string, options?: RequestOptions): Promise<HttpResponse>;
    /**
     * Destroy HTTP request | 销毁HTTP请求
     */
    destroy(): void;
  }
  
  export interface RequestOptions {
    method?: string; // HTTP method | HTTP方法
    header?: Record<string, string>; // Request headers | 请求头
    extraData?: string | Record<string, string | number | boolean>; // Request body | 请求体
    connectTimeout?: number; // Connection timeout in milliseconds | 连接超时时间（毫秒）
    readTimeout?: number; // Read timeout in milliseconds | 读取超时时间（毫秒）
    responseType?: string; // Response type | 响应类型
    signal?: AbortSignal; // Abort signal | 中止信号
  }
  
  export interface HttpResponse {
    responseCode: number; // HTTP response code | HTTP响应代码
    result: string | ArrayBuffer | Record<string, Serializable>; // Response result | 响应结果
    header: Record<string, string>; // Response headers | 响应头
  }
  
  /**
   * Create HTTP request instance | 创建HTTP请求实例
   * @returns HttpRequest instance | HttpRequest实例
   */
  export const createHttp: () => HttpRequest;
}

declare module '@ohos.net.connection' {
  export interface NetCapabilities {
    isInternetAvailable: boolean; // Whether internet is available | 互联网是否可用
    networkType: string; // Network type | 网络类型
  }
  
  /**
   * Get network capabilities | 获取网络能力
   * @param callback Callback function | 回调函数
   */
  export const getNetCapabilities: (callback: (capabilities: NetCapabilities) => void) => void;
  
  /**
   * Get network status | 获取网络状态
   * @returns Promise with NetStatus | 包含NetStatus的Promise
   */
  export const getStatus: () => Promise<NetStatus>;
  
  /**
   * Register network status change event | 注册网络状态变更事件
   * @param event Event name | 事件名称
   * @param callback Callback function | 回调函数
   * @returns Promise | Promise
   */
  export const on: (event: string, callback: (data: NetStatus | null) => void) => Promise<void>;
  
  export interface NetStatus {
    isInternetAvailable: boolean; // Whether internet is available | 互联网是否可用
    networkType: string; // Network type | 网络类型
  }
}

declare module '@ohos.base' {
  export interface Result {
    code: number; // Result code | 结果代码
    message: string; // Result message | 结果消息
  }
}

declare module '@ohos.file.fs' {
  /**
   * Read text from file | 从文件读取文本
   * @param path File path | 文件路径
   * @returns Promise with file content | 包含文件内容的Promise
   */
  export const readText: (path: string) => Promise<string>;
  
  /**
   * Write text to file | 向文件写入文本
   * @param path File path | 文件路径
   * @param content Text content | 文本内容
   * @returns Promise | Promise
   */
  export const writeText: (path: string, content: string) => Promise<void>;
  
  /**
   * Check if file exists synchronously | 同步检查文件是否存在
   * @param path File path | 文件路径
   * @returns Whether file exists | 文件是否存在
   */
  export const existsSync: (path: string) => boolean;
  
  /**
   * Create directory | 创建目录
   * @param path Directory path | 目录路径
   * @returns Promise | Promise
   */
  export const mkdir: (path: string) => Promise<void>;
  
  /**
   * Remove directory | 删除目录
   * @param path Directory path | 目录路径
   * @param options Options | 选项
   * @returns Promise | Promise
   */
  export const rmdir: (path: string, options?: { recursive: boolean }) => Promise<void>;
  
  /**
   * Delete file | 删除文件
   * @param path File path | 文件路径
   * @returns Promise | Promise
   */
  export const unlink: (path: string) => Promise<void>;
  
  /**
   * Rename file or directory | 重命名文件或目录
   * @param oldPath Old path | 旧路径
   * @param newPath New path | 新路径
   * @returns Promise | Promise
   */
  export const rename: (oldPath: string, newPath: string) => Promise<void>;
}

declare module '@ohos.file.fileIO' {
  /**
   * Open file synchronously | 同步打开文件
   * @param path File path | 文件路径
   * @param mode Open mode | 打开模式
   * @returns File descriptor | 文件描述符
   */
  export const openSync: (path: string, mode: number) => number;
  
  /**
   * Read file synchronously | 同步读取文件
   * @param fd File descriptor | 文件描述符
   * @param buffer Buffer to read into | 读取缓冲区
   * @param offset Buffer offset | 缓冲区偏移量
   * @param length Number of bytes to read | 读取字节数
   * @param position File position | 文件位置
   * @returns Number of bytes read | 读取的字节数
   */
  export const readSync: (fd: number, buffer: ArrayBuffer, offset: number, length: number, position: number) => number;
  
  /**
   * Write file synchronously | 同步写入文件
   * @param fd File descriptor | 文件描述符
   * @param buffer Buffer to write from | 写入缓冲区
   * @param offset Buffer offset | 缓冲区偏移量
   * @param length Number of bytes to write | 写入字节数
   * @param position File position | 文件位置
   * @returns Number of bytes written | 写入的字节数
   */
  export const writeSync: (fd: number, buffer: ArrayBuffer, offset: number, length: number, position: number) => number;
  
  /**
   * Close file synchronously | 同步关闭文件
   * @param fd File descriptor | 文件描述符
   */
  export const closeSync: (fd: number) => void;
}

declare module '@ohos.abilityAccessCtrl' {
  /**
   * Verify access token | 验证访问令牌
   * @param tokenID Token ID | 令牌ID
   * @param permissionName Permission name | 权限名称
   * @returns Promise with verification result | 包含验证结果的Promise
   */
  export const verifyAccessToken: (tokenID: number, permissionName: string) => Promise<{ result: number }>;
}

declare module '@ohos.app.ability.common' {
  export interface ResourceManager {
    /**
     * Get media base path | 获取媒体基础路径
     * @param type Media type | 媒体类型
     * @returns Promise with base path | 包含基础路径的Promise
     */
    getMediaBasePath(type: string): Promise<string>;
    
    /**
     * Get raw file content | 获取原始文件内容
     * @param fileName File name | 文件名称
     * @returns Promise with file content | 包含文件内容的Promise
     */
    getRawFileContent(fileName: string): Promise<ArrayBuffer>;
  }
  
  export interface ApplicationContext {
    /**
     * Get bundle name | 获取包名
     * @returns Bundle name | 包名
     */
    getBundleName(): string;
    
    /**
     * Get process name | 获取进程名
     * @returns Process name | 进程名
     */
    getProcessName(): string;
  }
  
  export class Context {
    resourceManager: ResourceManager; // Resource manager | 资源管理器
    applicationContext: ApplicationContext; // Application context | 应用上下文
  }
}

declare module '@ohos.app.ability.UIAbilityContext' {
  import { Context } from '@ohos.app.ability.common';
  export class UIAbilityContext extends Context {
    readonly area: number; // Area | 区域
    readonly filesDir: string; // Files directory | 文件目录
    readonly cacheDir: string; // Cache directory | 缓存目录
    readonly tempDir: string; // Temporary directory | 临时目录
    readonly distributedFilesDir: string; // Distributed files directory | 分布式文件目录
  }
}

// Logger module declaration // Logger模块声明
declare module '../common/util/Logger' {
  export interface LoggerExtraData {
    [key: string]: Record<string, string | number | boolean | null>; // Extra data for logging | 日志附加数据
  }
  export default class Logger {
    /**
     * Debug log | 调试日志
     * @param tag Log tag | 日志标签
     * @param message Log message | 日志消息
     * @param extra Extra data | 附加数据
     */
    static d(tag: string, message: string, extra?: LoggerExtraData): void;
    
    /**
     * Info log | 信息日志
     * @param tag Log tag | 日志标签
     * @param message Log message | 日志消息
     * @param extra Extra data | 附加数据
     */
    static i(tag: string, message: string, extra?: LoggerExtraData): void;
    
    /**
     * Warning log | 警告日志
     * @param tag Log tag | 日志标签
     * @param message Log message | 日志消息
     * @param extra Extra data | 附加数据
     */
    static w(tag: string, message: string, extra?: LoggerExtraData): void;
    
    /**
     * Error log | 错误日志
     * @param tag Log tag | 日志标签
     * @param message Log message or error | 日志消息或错误
     * @param extra Extra data | 附加数据
     */
    static e(tag: string, message: string | Error, extra?: LoggerExtraData): void;
  }
}

// Hvigor module declaration // Hvigor模块声明
declare module '@ohos/hvigor-ohos-plugin' {
  export interface HvigorOhosPluginOptions {
    [key: string]: Record<string, string | number | boolean | null>; // Plugin options | 插件选项
  }
  
  export class HvigorOhosPlugin {
    /**
     * Constructor | 构造函数
     * @param options Plugin options | 插件选项
     */
    constructor(options?: HvigorOhosPluginOptions);
  }
  
  export const hapTasks: Record<string, string | number | boolean | null>; // HAP tasks | HAP任务
}

// Other common type declarations // 其他通用类型声明
declare interface Window {
  URL: typeof URL; // URL constructor | URL构造函数
}

declare class URL {
  /**
   * Constructor | 构造函数
   * @param url URL string | URL字符串
   * @param base Base URL | 基础URL
   */
  constructor(url: string, base?: string);
  searchParams: URLSearchParams; // URL search parameters | URL搜索参数
  /**
   * Convert to string | 转换为字符串
   * @returns URL string | URL字符串
   */
  toString(): string;
}

declare class URLSearchParams {
  /**
   * Append parameter | 添加参数
   * @param name Parameter name | 参数名称
   * @param value Parameter value | 参数值
   */
  append(name: string, value: string): void;
  /**
   * Convert to string | 转换为字符串
   * @returns Query string | 查询字符串
   */
  toString(): string;
}
