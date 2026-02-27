/**
 * 解析器管理服务接口 | Parser Management Service Interface
 * 定义壳应用解析器插件管理的核心接口 | Defines core interfaces for shell app parser plugin management
 */
import ApiResponse from '../../data/dto/ApiResponse';

// 解析器插件 | Parser plugin
export interface ParserPlugin {
  id: string;
  name: string;
  version: string;
  description?: string;
  supportedFormats: string[];
  filePath: string;
  checksum: string;
  loadedAt: number;
  isActive: boolean;
  metadata?: ParserMetadata;
}

// 解析器元数据 | Parser metadata
export interface ParserMetadata {
  author?: string;
  website?: string;
  license?: string;
  dependencies?: string[];
  compatibleVersions?: string[];
}

// 解析结果 | Parse result
export interface ParseResult {
  success: boolean;
  urls: string[];
  headers?: Record<string, string>;
  userAgent?: string;
  referer?: string;
  cookies?: Record<string, string>;
  drmInfo?: DrmInfo;
  error?: string;
  parserId: string;
  parsedAt: number;
  executionTime: number;
}

// DRM信息 | DRM information
export interface DrmInfo {
  type: 'widevine' | 'playready' | 'fairplay' | 'clearkey';
  licenseUrl?: string;
  certificateUrl?: string;
  headers?: Record<string, string>;
}

// 解析器配置 | Parser configuration
export interface ParserConfig {
  id: string;
  name: string;
  enabled: boolean;
  priority: number;
  timeout: number;
  retryCount: number;
  fallbackParsers: string[];
  customHeaders?: Record<string, string>;
}

// 解析器管理服务接口 | Parser management service interface
export interface IParserManager {
  /**
   * 加载解析器插件 | Load parser plugin
   * @param filePath 插件文件路径 | Plugin file path
   * @returns 解析器插件 | Parser plugin
   */
  loadParser(filePath: string): Promise<ApiResponse<ParserPlugin>>;
  
  /**
   * 卸载解析器插件 | Unload parser plugin
   * @param parserId 解析器ID | Parser ID
   * @returns 卸载结果 | Unload result
   */
  unloadParser(parserId: string): Promise<ApiResponse<boolean>>;
  
  /**
   * 执行解析 | Execute parsing
   * @param url 待解析的URL | URL to parse
   * @param parserId 解析器ID | Parser ID
   * @returns 解析结果 | Parse result
   */
  executeParse(url: string, parserId: string): Promise<ApiResponse<ParseResult>>;
  
  /**
   * 执行智能解析 | Execute smart parsing
   * @param url 待解析的URL | URL to parse
   * @returns 解析结果 | Parse result
   */
  executeSmartParse(url: string): Promise<ApiResponse<ParseResult>>;
  
  /**
   * 获取所有解析器 | Get all parsers
   * @param includeInactive 是否包含非激活的解析器 | Whether to include inactive parsers
   * @returns 解析器列表 | Parser list
   */
  getParsers(includeInactive?: boolean): Promise<ApiResponse<ParserPlugin[]>>;
  
  /**
   * 获取解析器配置 | Get parser configuration
   * @param parserId 解析器ID | Parser ID
   * @returns 解析器配置 | Parser configuration
   */
  getParserConfig(parserId: string): Promise<ApiResponse<ParserConfig>>;
  
  /**
   * 更新解析器配置 | Update parser configuration
   * @param parserId 解析器ID | Parser ID
   * @param config 配置信息 | Configuration
   * @returns 更新结果 | Update result
   */
  updateParserConfig(parserId: string, config: ParserConfig): Promise<ApiResponse<boolean>>;
  
  /**
   * 验证解析器文件 | Validate parser file
   * @param filePath 文件路径 | File path
   * @returns 验证结果 | Validation result
   */
  validateParserFile(filePath: string): Promise<ApiResponse<boolean>>;
  
  /**
   * 获取解析器统计信息 | Get parser statistics
   * @returns 统计信息 | Statistics
   */
  getStatistics(): Promise<ApiResponse<ParserStatistics>>;
  
  /**
   * 清理缓存 | Clear cache
   * @returns 清理结果 | Clear result
   */
  clearCache(): Promise<ApiResponse<boolean>>;
}

// 解析器统计信息 | Parser statistics
export interface ParserStatistics {
  totalParsers: number;
  activeParsers: number;
  totalExecutions: number;
  successfulExecutions: number;
  failedExecutions: number;
  averageExecutionTime: number;
  successRate: number;
  cacheHitRate: number;
  lastCleanup: number;
}