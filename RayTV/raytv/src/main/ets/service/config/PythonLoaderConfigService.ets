import Logger from '../../common/util/Logger';
import { ErrorHandler, ErrorType, ErrorSeverity } from '../../common/util/ErrorHandler';

// Python加载器配置接口 | Python loader config interface
export interface PythonLoaderConfig {
  // 内存限制配置 | Memory limit config
  memory: {
    maxHeapSize: number;         // 最大堆内存（MB）
    maxStackSize: number;        // 最大栈内存（MB）
    gcThreshold: number;         // 垃圾回收阈值（MB）
  };
  // 执行超时配置 | Execution timeout config
  timeout: {
    scriptLoadTimeout: number;   // 脚本加载超时（毫秒）
    methodExecutionTimeout: number; // 方法执行超时（毫秒）
    initTimeout: number;         // 初始化超时（毫秒）
    maxSleepTime: number;        // 最大休眠时间（毫秒）
  };
  // 错误处理配置 | Error handling config
  errorHandling: {
    maxErrorCount: number;       // 最大错误次数
    autoCleanup: boolean;        // 是否自动清理
    retryAttempts: number;       // 重试次数
  };
  // 安全限制配置 | Security limit config
  security: {
    maxCodeLength: number;       // 最大代码长度（字符）
    maxExecutionTime: number;    // 最大执行时间（毫秒）
    allowedModules: string[];    // 允许的模块列表
    blockedKeywords: string[];   // 禁止的关键词列表
    maxCodeLines: number;        // 最大代码行数
    maxBraceCount: number;       // 最大冒号数量（控制复杂度）
    maxArrayLength: number;      // 最大数组长度
    maxObjectKeys: number;       // 最大对象键数量
  };
}

// 默认Python加载器配置 | Default Python loader config
const DEFAULT_PYTHON_LOADER_CONFIG: PythonLoaderConfig = {
  memory: {
    maxHeapSize: 128,            // 128MB
    maxStackSize: 8,             // 8MB
    gcThreshold: 64              // 64MB
  },
  timeout: {
    scriptLoadTimeout: 15000,    // 15秒
    methodExecutionTimeout: 60000, // 60秒
    initTimeout: 30000,          // 30秒
    maxSleepTime: 10000          // 10秒
  },
  errorHandling: {
    maxErrorCount: 5,            // 最多5次错误
    autoCleanup: true,           // 自动清理
    retryAttempts: 3             // 重试3次
  },
  security: {
    maxCodeLength: 100000,       // 最大10万字符
    maxExecutionTime: 300000,    // 最大5分钟
    allowedModules: ['json', 'math', 're', 'datetime', 'urllib', 'http'],
    blockedKeywords: ['eval', 'exec', '__import__', 'open', 'file', 'subprocess', 'os.system'],
    maxCodeLines: 2000,          // 最大2000行
    maxBraceCount: 800,          // 最大800个冒号
    maxArrayLength: 20000,       // 最大数组长度20000
    maxObjectKeys: 2000          // 最大对象键数量2000
  }
};

/**
 * Python加载器配置服务 | Python loader config service
 * 管理Python加载器的所有配置 | Manage all Python loader configurations
 */
export class PythonLoaderConfigService {
  private static instance: PythonLoaderConfigService;
  private readonly TAG: string = 'PythonLoaderConfigService';

  private config: PythonLoaderConfig = DEFAULT_PYTHON_LOADER_CONFIG;
  private errorHandler: ErrorHandler = ErrorHandler.getInstance();

  private constructor() {}

  public static getInstance(): PythonLoaderConfigService {
    if (!PythonLoaderConfigService.instance) {
      PythonLoaderConfigService.instance = new PythonLoaderConfigService();
    }
    return PythonLoaderConfigService.instance;
  }

  /**
   * 获取完整配置 | Get full config
   */
  public getConfig(): PythonLoaderConfig {
    return this.config;
  }

  /**
   * 获取内存配置 | Get memory config
   */
  public getMemoryConfig(): PythonLoaderConfig['memory'] {
    return this.config.memory;
  }

  /**
   * 获取超时配置 | Get timeout config
   */
  public getTimeoutConfig(): PythonLoaderConfig['timeout'] {
    return this.config.timeout;
  }

  /**
   * 获取错误处理配置 | Get error handling config
   */
  public getErrorHandlingConfig(): PythonLoaderConfig['errorHandling'] {
    return this.config.errorHandling;
  }

  /**
   * 获取安全配置 | Get security config
   */
  public getSecurityConfig(): PythonLoaderConfig['security'] {
    return this.config.security;
  }

  /**
   * 更新配置 | Update config
   */
  public updateConfig(newConfig: Partial<PythonLoaderConfig>): void {
    try {
      this.config = {
        ...this.config,
        ...newConfig,
        memory: { ...this.config.memory, ...newConfig.memory },
        timeout: { ...this.config.timeout, ...newConfig.timeout },
        errorHandling: { ...this.config.errorHandling, ...newConfig.errorHandling },
        security: { ...this.config.security, ...newConfig.security }
      };
      Logger.info(this.TAG, 'Python loader config updated');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.CONFIG, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to update config: ${error}`);
    }
  }

  /**
   * 重置为默认配置 | Reset to default config
   */
  public resetToDefault(): void {
    this.config = DEFAULT_PYTHON_LOADER_CONFIG;
    Logger.info(this.TAG, 'Python loader config reset to default');
  }

  /**
   * 检查代码长度是否超出限制 | Check if code length exceeds limit
   */
  public isCodeLengthValid(codeLength: number): boolean {
    return codeLength <= this.config.security.maxCodeLength;
  }

  /**
   * 检查代码是否包含禁止的关键词 | Check if code contains blocked keywords
   */
  public containsBlockedKeywords(code: string): boolean {
    return this.config.security.blockedKeywords.some(keyword => 
      code.toLowerCase().includes(keyword.toLowerCase())
    );
  }

  /**
   * 检查模块是否允许 | Check if module is allowed
   */
  public isModuleAllowed(moduleName: string): boolean {
    return this.config.security.allowedModules.includes(moduleName);
  }
}

// 导出单例实例 | Export singleton instance
export function getPythonLoaderConfigService(): PythonLoaderConfigService {
  return PythonLoaderConfigService.getInstance();
}
