/**
 * 解析器管理服务实现 | Parser Management Service Implementation
 * 负责解析器插件的加载、管理和执行 | Responsible for loading, managing and executing parser plugins
 */
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import CacheService, { CachePriority, CacheType } from '../cache/CacheService';
import HttpService from '../HttpService';
import ApiResponse from '../../data/dto/ApiResponse';
import {
  IParserManager,
  ParserPlugin,
  ParseResult,
  ParserConfig,
  ParserStatistics,
  DrmInfo
} from '../interfaces/IParserManager';

// 常量定义 | Constants definition
const TAG = 'ParserManager';
const PARSER_STORAGE_KEY = 'parser_plugins';
const PARSER_CONFIG_KEY = 'parser_configs';
const STATS_STORAGE_KEY = 'parser_statistics';

/**
 * 解析器管理服务类
 * 
 * 负责解析器插件的加载、管理和执行，提供解析器的注册、卸载、配置和执行等功能。
 * 支持智能解析、缓存管理和统计信息收集等高级特性。
 * 
 * @example
 * ```typescript
 * // 获取ParserManager实例
 * import parserManager from './service/parser/ParserManager';
 * 
 * // 初始化服务
 * await parserManager.initialize();
 * 
 * // 加载解析器
 * const result = await parserManager.loadParser('/path/to/parser.js');
 * if (result.isSuccess()) {
 *   console.log('Parser loaded:', result.data);
 * }
 * 
 * // 执行解析
 * const parseResult = await parserManager.executeParse('https://example.com/video', result.data.id);
 * ```
 */
export class ParserManager implements IParserManager {
  private static instance: ParserManager | null = null;
  private httpService: HttpService;
  private cacheService: CacheService;
  private logger: Logger;
  private parsers: Map<string, ParserPlugin> = new Map();
  private configs: Map<string, ParserConfig> = new Map();
  private statistics: ParserStatistics = this.getDefaultStatistics();
  private initialized: boolean = false;
  private maxParsers: number = 50; // 最大解析器数量限制

  /**
   * 获取单例实例
   * 
   * 实现了单例模式，确保全局只有一个ParserManager实例。
   * 
   * @returns ParserManager单例实例
   * @example
   * ```typescript
   * const parserManager = ParserManager.getInstance();
   * ```
   */
  public static getInstance(): ParserManager {
    if (!ParserManager.instance) {
      ParserManager.instance = new ParserManager();
    }
    return ParserManager.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.httpService = HttpService.getInstance();
    this.cacheService = CacheService.getInstance();
    this.logger = new Logger(TAG);
  }

  /**
   * 初始化服务
   * 
   * 初始化解析器管理服务，加载已保存的解析器、配置和统计信息。
   * 
   * @returns Promise<void>
   * @throws Error - 当初始化失败时抛出错误
   * @example
   * ```typescript
   * await parserManager.initialize();
   * console.log('ParserManager initialized');
   * ```
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 加载已保存的解析器和配置 | Load saved parsers and configurations
      await this.loadStoredParsers();
      await this.loadStoredConfigs();
      await this.loadStatistics();
      
      this.initialized = true;
      this.logger.info('ParserManager initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize ParserManager', error);
      throw error;
    }
  }

  /**
   * 加载解析器插件
   * 
   * 从指定文件路径加载解析器插件，包括验证、注册和保存。
   * 
   * @param filePath 解析器文件路径
   * @returns Promise<ApiResponse<ParserPlugin>> - 包含加载结果的API响应
   * @example
   * ```typescript
   * const result = await parserManager.loadParser('/path/to/parser.js');
   * if (result.isSuccess()) {
   *   console.log('Parser loaded:', result.data);
   * } else {
   *   console.error('Failed to load parser:', result.message);
   * }
   * ```
   */
  public async loadParser(filePath: string): Promise<ApiResponse<ParserPlugin>> {
    try {
      this.logger.info(`Loading parser from: ${filePath}`);
      
      // 验证文件路径 | Validate file path
      if (!this.isValidFilePath(filePath)) {
        return ApiResponse.failure('Invalid file path');
      }

      // 检查是否已加载 | Check if already loaded
      const existingParser = this.findParserByPath(filePath);
      if (existingParser) {
        return ApiResponse.success(existingParser);
      }

      // 验证解析器文件 | Validate parser file
      const validation = await this.validateParserFile(filePath);
      if (!validation.isSuccess()) {
        return ApiResponse.failure(`Validation failed: ${validation.message}`);
      }

      // 计算文件校验和 | Calculate file checksum
      const checksum = await this.calculateFileChecksum(filePath);
      
      // 加载解析器元数据 | Load parser metadata
      const metadata = await this.loadParserMetadata(filePath);
      
      // 创建解析器对象 | Create parser object
      const parser: ParserPlugin = {
        id: this.generateParserId(filePath),
        name: metadata.name || this.extractFileName(filePath),
        version: metadata.version || '1.0.0',
        description: metadata.description,
        supportedFormats: metadata.supportedFormats || ['mp4', 'm3u8', 'flv'],
        filePath,
        checksum,
        loadedAt: Date.now(),
        isActive: true,
        metadata
      };

      // 检查解析器数量限制 | Check parser count limit
      if (this.parsers.size >= this.maxParsers) {
        // 删除最旧的解析器 | Remove oldest parser
        const oldestParser = Array.from(this.parsers.values()).sort((a, b) => a.loadedAt - b.loadedAt)[0];
        if (oldestParser) {
          this.parsers.delete(oldestParser.id);
          await this.removeStoredParser(oldestParser.id);
          this.logger.info(`Removed oldest parser ${oldestParser.name} to stay within limit`);
        }
      }

      // 注册解析器 | Register parser
      this.parsers.set(parser.id, parser);
      
      // 保存到存储 | Save to storage
      await this.saveParser(parser);
      
      this.logger.info(`Successfully loaded parser: ${parser.name} (${parser.id})`);
      return ApiResponse.success(parser);

    } catch (error) {
      this.logger.error(`Failed to load parser from ${filePath}`, error);
      return ApiResponse.failure(`Load failed: ${(error as Error).message}`);
    }
  }

  /**
   * 卸载解析器插件
   * 
   * 根据解析器ID卸载解析器插件，从内存和存储中移除。
   * 
   * @param parserId 解析器ID
   * @returns Promise<ApiResponse<boolean>> - 包含卸载结果的API响应
   * @example
   * ```typescript
   * const result = await parserManager.unloadParser('parser_abc123_1234567890');
   * if (result.isSuccess()) {
   *   console.log('Parser unloaded successfully');
   * } else {
   *   console.error('Failed to unload parser:', result.message);
   * }
   * ```
   */
  public async unloadParser(parserId: string): Promise<ApiResponse<boolean>> {
    try {
      const parser = this.parsers.get(parserId);
      if (!parser) {
        return ApiResponse.failure('Parser not found');
      }

      // 从内存中移除 | Remove from memory
      this.parsers.delete(parserId);
      
      // 从存储中移除 | Remove from storage
      await this.removeStoredParser(parserId);
      
      // 更新统计信息 | Update statistics
      this.statistics.activeParsers = this.parsers.size;
      
      this.logger.info(`Successfully unloaded parser: ${parser.name}`);
      return ApiResponse.success(true);

    } catch (error) {
      this.logger.error(`Failed to unload parser ${parserId}`, error);
      return ApiResponse.failure(`Unload failed: ${(error as Error).message}`);
    }
  }

  /**
   * 执行解析
   * 
   * 使用指定的解析器解析URL，执行解析逻辑并返回结果。
   * 
   * @param url 要解析的URL
   * @param parserId 解析器ID
   * @returns Promise<ApiResponse<ParseResult>> - 包含解析结果的API响应
   * @example
   * ```typescript
   * const result = await parserManager.executeParse('https://example.com/video', 'parser_abc123_1234567890');
   * if (result.isSuccess()) {
   *   console.log('Parse result:', result.data);
   * } else {
   *   console.error('Parse failed:', result.message);
   * }
   * ```
   */
  public async executeParse(url: string, parserId: string): Promise<ApiResponse<ParseResult>> {
    try {
      this.logger.info(`Executing parse for URL: ${url} with parser: ${parserId}`);
      
      const startTime = Date.now();
      
      // 获取解析器 | Get parser
      const parser = this.parsers.get(parserId);
      if (!parser) {
        return ApiResponse.failure('Parser not found');
      }

      if (!parser.isActive) {
        return ApiResponse.failure('Parser is not active');
      }

      // 检查配置 | Check configuration
      const config = this.configs.get(parserId) || this.getDefaultParserConfig(parserId);
      
      // 执行解析逻辑 | Execute parsing logic
      const result = await this.performParsing(url, parser, config);
      
      const executionTime = Date.now() - startTime;
      
      // 更新统计信息 | Update statistics
      this.updateParseStatistics(result.success, executionTime);
      
      // 缓存成功结果 | Cache successful results
      if (result.success) {
        const cacheKey = this.generateCacheKey(url, parserId);
        await this.cacheService.set(cacheKey, result, {
          expiry: config.cacheExpiry || 3600000, // 1小时缓存，可通过配置覆盖
          priority: CachePriority.NORMAL,
          tags: ['parser', 'parse_result', parserId],
          type: CacheType.MEMORY_DISK,
          source: 'ParserManager'
        });
      }
      
      this.logger.info(`Parse execution completed in ${executionTime}ms - Success: ${result.success}`);
      return ApiResponse.success(result);

    } catch (error) {
      this.logger.error(`Parse execution failed for ${url}`, error);
      this.updateParseStatistics(false, 0);
      return ApiResponse.failure(`Parse failed: ${(error as Error).message}`);
    }
  }

  /**
   * 执行智能解析
   * 
   * 智能选择合适的解析器解析URL，依次尝试活跃的解析器直到成功。
   * 
   * @param url 要解析的URL
   * @returns Promise<ApiResponse<ParseResult>> - 包含解析结果的API响应
   * @example
   * ```typescript
   * const result = await parserManager.executeSmartParse('https://example.com/video');
   * if (result.isSuccess()) {
   *   console.log('Smart parse result:', result.data);
   * } else {
   *   console.error('Smart parse failed:', result.message);
   * }
   * ```
   */
  public async executeSmartParse(url: string): Promise<ApiResponse<ParseResult>> {
    try {
      this.logger.info(`Executing smart parse for URL: ${url}`);
      
      // 检查缓存 | Check cache first
      const cacheKey = this.generateCacheKey(url);
      const cachedResult = await this.cacheService.get<ParseResult>(cacheKey);
      if (cachedResult) {
        this.logger.info('Returning cached parse result');
        return ApiResponse.success(cachedResult);
      }

      // 获取活跃的解析器 | Get active parsers
      const activeParsers = Array.from(this.parsers.values()).filter(p => p.isActive);
      if (activeParsers.length === 0) {
        return ApiResponse.failure('No active parsers available');
      }

      // 按优先级排序 | Sort by priority
      const sortedParsers = activeParsers.sort((a, b) => {
        const configA = this.configs.get(a.id) || this.getDefaultParserConfig(a.id);
        const configB = this.configs.get(b.id) || this.getDefaultParserConfig(b.id);
        return configB.priority - configA.priority;
      });

      // 依次尝试解析器 | Try parsers in order
      for (const parser of sortedParsers) {
        try {
          const result = await this.executeParse(url, parser.id);
          if (result.isSuccess() && result.data!.success) {
            this.logger.info(`Smart parse succeeded with parser: ${parser.name}`);
            return result;
          }
        } catch (error) {
          this.logger.warn(`Parser ${parser.name} failed: ${(error as Error).message}`);
          continue;
        }
      }

      return ApiResponse.failure('All parsers failed to parse the URL');

    } catch (error) {
      this.logger.error('Smart parse execution failed', error);
      return ApiResponse.failure(`Smart parse failed: ${(error as Error).message}`);
    }
  }

  /**
   * 执行并行解析
   * 
   * 并行使用多个解析器解析URL，提高解析成功率和速度。
   * 
   * @param url 要解析的URL
   * @param maxConcurrent 最大并发数，默认5
   * @returns Promise<ApiResponse<ParseResult>> - 包含解析结果的API响应
   * @example
   * ```typescript
   * const result = await parserManager.executeParallelParse('https://example.com/video');
   * if (result.isSuccess()) {
   *   console.log('Parallel parse result:', result.data);
   * } else {
   *   console.error('Parallel parse failed:', result.message);
   * }
   * ```
   */
  public async executeParallelParse(url: string, maxConcurrent: number = 5): Promise<ApiResponse<ParseResult>> {
    try {
      this.logger.info(`Executing parallel parse for URL: ${url}`);
      
      // 检查缓存 | Check cache first
      const cacheKey = this.generateCacheKey(url);
      const cachedResult = await this.cacheService.get<ParseResult>(cacheKey);
      if (cachedResult) {
        this.logger.info('Returning cached parse result');
        return ApiResponse.success(cachedResult);
      }

      // 获取活跃的解析器 | Get active parsers
      const activeParsers = Array.from(this.parsers.values()).filter(p => p.isActive);
      if (activeParsers.length === 0) {
        return ApiResponse.failure('No active parsers available');
      }

      // 按优先级排序并限制并发数 | Sort by priority and limit concurrent count
      const sortedParsers = activeParsers.sort((a, b) => {
        const configA = this.configs.get(a.id) || this.getDefaultParserConfig(a.id);
        const configB = this.configs.get(b.id) || this.getDefaultParserConfig(b.id);
        return configB.priority - configA.priority;
      }).slice(0, maxConcurrent);

      if (sortedParsers.length === 0) {
        return ApiResponse.failure('No parsers available for parallel execution');
      }

      // 并行执行解析 | Execute parse in parallel
      const startTime = Date.now();
      const parsePromises = sortedParsers.map(parser => {
        return this.executeParse(url, parser.id).then(result => ({
          parser: parser.name,
          result
        }));
      });

      const results = await Promise.all(parsePromises);
      const executionTime = Date.now() - startTime;

      // 查找成功的结果 | Find successful result
      for (const { parser, result } of results) {
        if (result.isSuccess() && result.data!.success) {
          this.logger.info(`Parallel parse succeeded with parser: ${parser} in ${executionTime}ms`);
          return result;
        }
      }

      // 所有解析器都失败 | All parsers failed
      this.logger.warn('All parallel parsers failed');
      return ApiResponse.failure('All parsers failed to parse the URL');

    } catch (error) {
      this.logger.error('Parallel parse execution failed', error);
      return ApiResponse.failure(`Parallel parse failed: ${(error as Error).message}`);
    }
  }

  /**
   * 批量执行解析
   * 
   * 批量解析多个URL，支持并行处理。
   * 
   * @param urls 要解析的URL列表
   * @param parserId 解析器ID，不指定则使用智能解析
   * @param maxConcurrent 最大并发数，默认3
   * @returns Promise<ApiResponse<Map<string, ParseResult>>> - 包含解析结果映射的API响应
   * @example
   * ```typescript
   * const urls = ['https://example.com/video1', 'https://example.com/video2'];
   * const result = await parserManager.executeBatchParse(urls);
   * if (result.isSuccess()) {
   *   console.log('Batch parse results:', result.data);
   * }
   * ```
   */
  public async executeBatchParse(
    urls: string[],
    parserId?: string,
    maxConcurrent: number = 3
  ): Promise<ApiResponse<Map<string, ParseResult>>> {
    try {
      this.logger.info(`Executing batch parse for ${urls.length} URLs`);

      if (urls.length === 0) {
        return ApiResponse.success(new Map());
      }

      // 限制并发数 | Limit concurrent count
      const batchSize = Math.min(maxConcurrent, urls.length);
      const results = new Map<string, ParseResult>();

      // 分批处理 | Process in batches
      for (let i = 0; i < urls.length; i += batchSize) {
        const batchUrls = urls.slice(i, i + batchSize);
        const batchPromises = batchUrls.map(url => {
          return (parserId ? this.executeParse(url, parserId) : this.executeSmartParse(url))
            .then(response => ({
              url,
              response
            }));
        });

        const batchResults = await Promise.all(batchPromises);
        batchResults.forEach(({ url, response }) => {
          if (response.isSuccess()) {
            results.set(url, response.data!);
          }
        });
      }

      this.logger.info(`Batch parse completed: ${results.size}/${urls.length} successful`);
      return ApiResponse.success(results);

    } catch (error) {
      this.logger.error('Batch parse execution failed', error);
      return ApiResponse.failure(`Batch parse failed: ${(error as Error).message}`);
    }
  }

  /**
   * 获取所有解析器
   * 
   * 获取所有解析器插件，支持过滤不活跃的解析器。
   * 
   * @param includeInactive 是否包含不活跃的解析器
   * @returns Promise<ApiResponse<ParserPlugin[]>> - 包含解析器列表的API响应
   * @example
   * ```typescript
   * // 获取活跃解析器
   * const result = await parserManager.getParsers();
   * if (result.isSuccess()) {
   *   console.log('Active parsers:', result.data);
   * }
   * 
   * // 获取所有解析器（包括不活跃的）
   * const allParsersResult = await parserManager.getParsers(true);
   * ```
   */
  public async getParsers(includeInactive: boolean = false): Promise<ApiResponse<ParserPlugin[]>> {
    try {
      let parsers = Array.from(this.parsers.values());
      
      if (!includeInactive) {
        parsers = parsers.filter(parser => parser.isActive);
      }
      
      // 按加载时间排序 | Sort by load time
      parsers.sort((a, b) => b.loadedAt - a.loadedAt);
      
      return ApiResponse.success(parsers);

    } catch (error) {
      this.logger.error('Failed to get parsers', error);
      return ApiResponse.failure(`Get parsers failed: ${(error as Error).message}`);
    }
  }

  /**
   * 获取解析器配置
   * 
   * 获取指定解析器的配置，如果不存在则返回默认配置。
   * 
   * @param parserId 解析器ID
   * @returns Promise<ApiResponse<ParserConfig>> - 包含解析器配置的API响应
   * @example
   * ```typescript
   * const result = await parserManager.getParserConfig('parser_abc123_1234567890');
   * if (result.isSuccess()) {
   *   console.log('Parser config:', result.data);
   * }
   * ```
   */
  public async getParserConfig(parserId: string): Promise<ApiResponse<ParserConfig>> {
    try {
      const config = this.configs.get(parserId) || this.getDefaultParserConfig(parserId);
      return ApiResponse.success(config);

    } catch (error) {
      this.logger.error(`Failed to get config for parser ${parserId}`, error);
      return ApiResponse.failure(`Get config failed: ${(error as Error).message}`);
    }
  }

  /**
   * 更新解析器配置
   * 
   * 更新指定解析器的配置并保存到存储。
   * 
   * @param parserId 解析器ID
   * @param config 新的解析器配置
   * @returns Promise<ApiResponse<boolean>> - 包含更新结果的API响应
   * @example
   * ```typescript
   * const newConfig = {
   *   id: 'parser_abc123_1234567890',
   *   name: 'Updated Parser',
   *   enabled: true,
   *   priority: 2,
   *   timeout: 15000,
   *   retryCount: 5,
   *   fallbackParsers: []
   * };
   * 
   * const result = await parserManager.updateParserConfig('parser_abc123_1234567890', newConfig);
   * if (result.isSuccess()) {
   *   console.log('Parser config updated successfully');
   * } else {
   *   console.error('Failed to update parser config:', result.message);
   * }
   * ```
   */
  public async updateParserConfig(parserId: string, config: ParserConfig): Promise<ApiResponse<boolean>> {
    try {
      // 验证解析器存在 | Validate parser exists
      if (!this.parsers.has(parserId)) {
        return ApiResponse.failure('Parser not found');
      }

      // 更新配置 | Update configuration
      this.configs.set(parserId, config);
      
      // 保存到存储 | Save to storage
      await this.saveConfigs();
      
      this.logger.info(`Updated configuration for parser: ${parserId}`);
      return ApiResponse.success(true);

    } catch (error) {
      this.logger.error(`Failed to update config for parser ${parserId}`, error);
      return ApiResponse.failure(`Update config failed: ${(error as Error).message}`);
    }
  }

  /**
   * 验证解析器文件
   * 
   * 验证解析器文件的有效性，包括文件存在性、扩展名和大小等。
   * 
   * @param filePath 解析器文件路径
   * @returns Promise<ApiResponse<boolean>> - 包含验证结果的API响应
   * @example
   * ```typescript
   * const result = await parserManager.validateParserFile('/path/to/parser.js');
   * if (result.isSuccess()) {
   *   console.log('Parser file is valid');
   * } else {
   *   console.error('Parser file validation failed:', result.message);
   * }
   * ```
   */
  public async validateParserFile(filePath: string): Promise<ApiResponse<boolean>> {
    try {
      // 检查文件存在性 | Check file existence
      // 这里需要根据实际的文件系统API进行调整 | This needs to be adjusted according to actual file system API
      const fileExists = await this.checkFileExists(filePath);
      if (!fileExists) {
        return ApiResponse.failure('File does not exist');
      }

      // 检查文件扩展名 | Check file extension
      if (!this.isValidParserExtension(filePath)) {
        return ApiResponse.failure('Invalid file extension');
      }

      // 检查文件大小 | Check file size
      const fileSize = await this.getFileSize(filePath);
      if (fileSize > 10 * 1024 * 1024) { // 10MB限制 | 10MB limit
        return ApiResponse.failure('File too large');
      }

      return ApiResponse.success(true);

    } catch (error) {
      this.logger.error(`Failed to validate parser file ${filePath}`, error);
      return ApiResponse.failure(`Validation failed: ${(error as Error).message}`);
    }
  }

  /**
   * 获取解析器统计信息
   * 
   * 获取解析器的统计信息，包括解析器数量、执行次数、成功率等。
   * 
   * @returns Promise<ApiResponse<ParserStatistics>> - 包含统计信息的API响应
   * @example
   * ```typescript
   * const result = await parserManager.getStatistics();
   * if (result.isSuccess()) {
   *   console.log('Parser statistics:', result.data);
   * }
   * ```
   */
  public async getStatistics(): Promise<ApiResponse<ParserStatistics>> {
    try {
      // 更新实时统计 | Update real-time statistics
      this.statistics.activeParsers = Array.from(this.parsers.values()).filter(p => p.isActive).length;
      this.statistics.totalParsers = this.parsers.size;
      
      if (this.statistics.totalExecutions > 0) {
        this.statistics.successRate = this.statistics.successfulExecutions / this.statistics.totalExecutions;
      }
      
      return ApiResponse.success(this.statistics);

    } catch (error) {
      this.logger.error('Failed to get statistics', error);
      return ApiResponse.failure(`Get statistics failed: ${(error as Error).message}`);
    }
  }

  /**
   * 清理缓存
   * 
   * 清理解析缓存并重置统计信息。
   * 
   * @returns Promise<ApiResponse<boolean>> - 包含清理结果的API响应
   * @example
   * ```typescript
   * const result = await parserManager.clearCache();
   * if (result.isSuccess()) {
   *   console.log('Parser cache cleared successfully');
   * } else {
   *   console.error('Failed to clear cache:', result.message);
   * }
   * ```
   */
  public async clearCache(): Promise<ApiResponse<boolean>> {
    try {
      // 清理解析缓存 | Clear parse cache
      await this.cacheService.clear();
      
      // 重置统计信息 | Reset statistics
      this.statistics = this.getDefaultStatistics();
      await this.saveStatistics();
      
      this.logger.info('Parser cache cleared successfully');
      return ApiResponse.success(true);

    } catch (error) {
      this.logger.error('Failed to clear cache', error);
      return ApiResponse.failure(`Clear cache failed: ${(error as Error).message}`);
    }
  }

  // 私有辅助方法 | Private helper methods

  private getDefaultStatistics(): ParserStatistics {
    return {
      totalParsers: 0,
      activeParsers: 0,
      totalExecutions: 0,
      successfulExecutions: 0,
      failedExecutions: 0,
      averageExecutionTime: 0,
      successRate: 0,
      cacheHitRate: 0,
      lastCleanup: Date.now()
    };
  }

  private getDefaultParserConfig(parserId: string): ParserConfig {
    return {
      id: parserId,
      name: `Parser_${parserId}`,
      enabled: true,
      priority: 1,
      timeout: 10000,
      retryCount: 3,
      fallbackParsers: [],
      cacheExpiry: 3600000 // 默认1小时缓存
    };
  }

  private async loadStoredParsers(): Promise<void> {
    try {
      const storedParsers = await StorageUtil.getItem<ParserPlugin[]>(PARSER_STORAGE_KEY);
      if (storedParsers) {
        storedParsers.forEach(parser => {
          this.parsers.set(parser.id, parser);
        });
        this.logger.info(`Loaded ${storedParsers.length} stored parsers`);
      }
    } catch (error) {
      this.logger.warn('Failed to load stored parsers', error);
    }
  }

  private async loadStoredConfigs(): Promise<void> {
    try {
      const storedConfigs = await StorageUtil.getItem<ParserConfig[]>(PARSER_CONFIG_KEY);
      if (storedConfigs) {
        storedConfigs.forEach(config => {
          this.configs.set(config.id, config);
        });
        this.logger.info(`Loaded ${storedConfigs.length} stored configurations`);
      }
    } catch (error) {
      this.logger.warn('Failed to load stored configurations', error);
    }
  }

  private async loadStatistics(): Promise<void> {
    try {
      const storedStats = await StorageUtil.getItem<ParserStatistics>(STATS_STORAGE_KEY);
      if (storedStats) {
        this.statistics = storedStats;
        this.logger.info('Loaded stored statistics');
      }
    } catch (error) {
      this.logger.warn('Failed to load stored statistics', error);
    }
  }

  private async saveParser(parser: ParserPlugin): Promise<void> {
    const parsers = Array.from(this.parsers.values());
    await StorageUtil.setItem(PARSER_STORAGE_KEY, parsers);
  }

  private async removeStoredParser(parserId: string): Promise<void> {
    const parsers = Array.from(this.parsers.values());
    await StorageUtil.setItem(PARSER_STORAGE_KEY, parsers);
  }

  private async saveConfigs(): Promise<void> {
    const configs = Array.from(this.configs.values());
    await StorageUtil.setItem(PARSER_CONFIG_KEY, configs);
  }

  private async saveStatistics(): Promise<void> {
    await StorageUtil.setItem(STATS_STORAGE_KEY, this.statistics);
  }

  private isValidFilePath(filePath: string): boolean {
    // 简单的文件路径验证 | Simple file path validation
    return typeof filePath === 'string' && filePath.length > 0;
  }

  private findParserByPath(filePath: string): ParserPlugin | undefined {
    return Array.from(this.parsers.values()).find(parser => parser.filePath === filePath);
  }

  private async calculateFileChecksum(filePath: string): Promise<string> {
    // 简化的校验和计算 | Simplified checksum calculation
    // 实际实现需要根据文件内容计算MD5或其他哈希值 | Actual implementation needs to calculate MD5 or other hash based on file content
    return `checksum_${filePath}_${Date.now()}`;
  }

  private async loadParserMetadata(filePath: string): Promise<any> {
    // 简化的元数据加载 | Simplified metadata loading
    // 实际实现需要解析文件头部或配置文件 | Actual implementation needs to parse file header or config file
    return {
      name: this.extractFileName(filePath),
      version: '1.0.0',
      supportedFormats: ['mp4', 'm3u8']
    };
  }

  private extractFileName(filePath: string): string {
    return filePath.split(/[\/\\]/).pop()?.replace(/\.[^/.]+$/, '') || 'Unknown Parser';
  }

  private generateParserId(filePath: string): string {
    return `parser_${btoa(filePath).substring(0, 16)}_${Date.now()}`;
  }

  private async checkFileExists(filePath: string): Promise<boolean> {
    // 模拟文件存在检查 | Simulate file existence check
    // 实际实现需要使用文件系统API | Actual implementation needs to use file system API
    return true;
  }

  private isValidParserExtension(filePath: string): boolean {
    const validExtensions = ['.js', '.ts', '.jar'];
    return validExtensions.some(ext => filePath.endsWith(ext));
  }

  private async getFileSize(filePath: string): Promise<number> {
    // 模拟文件大小获取 | Simulate file size retrieval
    // 实际实现需要使用文件系统API | Actual implementation needs to use file system API
    return 1024 * 1024; // 1MB模拟 | 1MB simulation
  }

  /**
   * 生成缓存键 | Generate cache key
   * @param url 要解析的URL
   * @param parserId 解析器ID（可选）
   * @returns 生成的缓存键
   */
  private generateCacheKey(url: string, parserId?: string): string {
    // 对URL进行哈希处理，避免过长的缓存键
    const urlHash = btoa(url).substring(0, 32);
    if (parserId) {
      return `parse_result_${parserId}_${urlHash}`;
    }
    return `parse_result_${urlHash}`;
  }

  private async performParsing(url: string, parser: ParserPlugin, config: ParserConfig): Promise<ParseResult> {
    // 模拟解析执行 | Simulate parsing execution
    // 实际实现需要调用具体的解析器逻辑 | Actual implementation needs to call specific parser logic
    
    const success = Math.random() > 0.3; // 70%成功率模拟 | 70% success rate simulation
    
    const result: ParseResult = {
      success,
      urls: success ? [`${url}?parsed=true`] : [],
      headers: success ? { 'User-Agent': 'RayTV Parser' } : undefined,
      parserId: parser.id,
      parsedAt: Date.now(),
      executionTime: Math.floor(Math.random() * 1000) + 100 // 100-1100ms随机时间 | 100-1100ms random time
    };

    if (!success) {
      result.error = 'Parsing failed due to unsupported format';
    }

    return result;
  }

  private updateParseStatistics(success: boolean, executionTime: number): void {
    this.statistics.totalExecutions++;
    
    if (success) {
      this.statistics.successfulExecutions++;
      this.statistics.averageExecutionTime = (
        (this.statistics.averageExecutionTime * (this.statistics.successfulExecutions - 1) + executionTime) /
        this.statistics.successfulExecutions
      );
    } else {
      this.statistics.failedExecutions++;
    }
    
    // 保存统计信息 | Save statistics
    this.saveStatistics().catch(error => {
      this.logger.warn('Failed to save statistics', error);
    });
  }
}

// 导出单例实例 | Export singleton instance
export default ParserManager.getInstance();