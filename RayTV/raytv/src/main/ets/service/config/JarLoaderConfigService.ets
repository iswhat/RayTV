import Logger from '../../common/util/Logger';
import { ErrorHandler, ErrorType, ErrorSeverity } from '../../common/util/ErrorHandler';

// JAR加载器配置接口 | JAR loader config interface
export interface JarLoaderConfig {
  // 内存限制配置 | Memory limit config
  memory: {
    maxHeapSize: number;         // 最大堆内存（MB）
    maxStackSize: number;        // 最大栈内存（MB）
    gcThreshold: number;         // 垃圾回收阈值（MB）
  };
  // 执行超时配置 | Execution timeout config
  timeout: {
    jarLoadTimeout: number;      // JAR加载超时（毫秒）
    methodExecutionTimeout: number; // 方法执行超时（毫秒）
    initTimeout: number;         // 初始化超时（毫秒）
    classLoadTimeout: number;    // 类加载超时（毫秒）
  };
  // 错误处理配置 | Error handling config
  errorHandling: {
    maxErrorCount: number;       // 最大错误次数
    autoCleanup: boolean;        // 是否自动清理
    retryAttempts: number;       // 重试次数
  };
  // 安全限制配置 | Security limit config
  security: {
    maxJarSize: number;          // 最大JAR文件大小（字节）
    maxExecutionTime: number;    // 最大执行时间（毫秒）
    allowedPackages: string[];   // 允许的包列表
    blockedClasses: string[];    // 禁止的类列表
    maxCodeLines: number;        // 最大代码行数
    maxMethodCount: number;      // 最大方法数量
  };
}

// 默认JAR加载器配置 | Default JAR loader config
const DEFAULT_JAR_LOADER_CONFIG: JarLoaderConfig = {
  memory: {
    maxHeapSize: 256,            // 256MB
    maxStackSize: 16,            // 16MB
    gcThreshold: 128             // 128MB
  },
  timeout: {
    jarLoadTimeout: 30000,       // 30秒
    methodExecutionTimeout: 60000, // 60秒
    initTimeout: 45000,          // 45秒
    classLoadTimeout: 20000      // 20秒
  },
  errorHandling: {
    maxErrorCount: 5,            // 最多5次错误
    autoCleanup: true,           // 自动清理
    retryAttempts: 3             // 重试3次
  },
  security: {
    maxJarSize: 50 * 1024 * 1024, // 最大50MB
    maxExecutionTime: 300000,    // 最大5分钟
    allowedPackages: ['java.lang', 'java.util', 'java.net', 'java.io', 'org.json'],
    blockedClasses: ['java.lang.Runtime', 'java.lang.ProcessBuilder', 'java.lang.System'],
    maxCodeLines: 5000,          // 最大5000行
    maxMethodCount: 500          // 最大500个方法
  }
};

/**
 * JAR加载器配置服务 | JAR loader config service
 * 管理JAR加载器的所有配置 | Manage all JAR loader configurations
 */
export class JarLoaderConfigService {
  private static instance: JarLoaderConfigService;
  private readonly TAG: string = 'JarLoaderConfigService';

  private config: JarLoaderConfig = DEFAULT_JAR_LOADER_CONFIG;
  private errorHandler: ErrorHandler = ErrorHandler.getInstance();

  private constructor() {}

  public static getInstance(): JarLoaderConfigService {
    if (!JarLoaderConfigService.instance) {
      JarLoaderConfigService.instance = new JarLoaderConfigService();
    }
    return JarLoaderConfigService.instance;
  }

  /**
   * 获取完整配置 | Get full config
   */
  public getConfig(): JarLoaderConfig {
    return this.config;
  }

  /**
   * 获取内存配置 | Get memory config
   */
  public getMemoryConfig(): JarLoaderConfig['memory'] {
    return this.config.memory;
  }

  /**
   * 获取超时配置 | Get timeout config
   */
  public getTimeoutConfig(): JarLoaderConfig['timeout'] {
    return this.config.timeout;
  }

  /**
   * 获取错误处理配置 | Get error handling config
   */
  public getErrorHandlingConfig(): JarLoaderConfig['errorHandling'] {
    return this.config.errorHandling;
  }

  /**
   * 获取安全配置 | Get security config
   */
  public getSecurityConfig(): JarLoaderConfig['security'] {
    return this.config.security;
  }

  /**
   * 更新配置 | Update config
   */
  public updateConfig(newConfig: Partial<JarLoaderConfig>): void {
    try {
      this.config = {
        ...this.config,
        ...newConfig,
        memory: { ...this.config.memory, ...newConfig.memory },
        timeout: { ...this.config.timeout, ...newConfig.timeout },
        errorHandling: { ...this.config.errorHandling, ...newConfig.errorHandling },
        security: { ...this.config.security, ...newConfig.security }
      };
      Logger.info(this.TAG, 'JAR loader config updated');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.CONFIG, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to update config: ${error}`);
    }
  }

  /**
   * 重置为默认配置 | Reset to default config
   */
  public resetToDefault(): void {
    this.config = DEFAULT_JAR_LOADER_CONFIG;
    Logger.info(this.TAG, 'JAR loader config reset to default');
  }

  /**
   * 检查JAR大小是否有效 | Check if JAR size is valid
   */
  public isJarSizeValid(size: number): boolean {
    return size <= this.config.security.maxJarSize;
  }

  /**
   * 检查包是否允许 | Check if package is allowed
   */
  public isPackageAllowed(packageName: string): boolean {
    return this.config.security.allowedPackages.some(pkg => 
      packageName.startsWith(pkg)
    );
  }

  /**
   * 检查类是否被禁止 | Check if class is blocked
   */
  public isClassBlocked(className: string): boolean {
    return this.config.security.blockedClasses.some(blocked => 
      className === blocked || className.startsWith(blocked + '.')
    );
  }
}

// 导出单例实例 | Export singleton instance
export function getJarLoaderConfigService(): JarLoaderConfigService {
  return JarLoaderConfigService.getInstance();
}
