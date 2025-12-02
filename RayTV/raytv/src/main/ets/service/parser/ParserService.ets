import Logger from '../../common/util/Logger';
import { ParserInfo } from '../../data/repository/NetworkRepository';
import { NetworkResult, VideoSourceInfo } from '../../data/bean/NetworkResult';
import { configService } from '../config/ConfigService';
import HttpService from '../HttpService';

/**
 * 解析器配置接口
 */
interface ParserConfig {
  enabled?: boolean;
  timeout?: number;
  retryCount?: number;
}

/**
 * 解析器执行上下文
 */
interface ParserContext {
  parserId: string;
  sourceUrl: string;
  config: ParserConfig;
}

/**
 * 解析器服务
 * 负责管理和执行视频源解析功能
 */
/**
 * 自定义解析器接口
 */
interface CustomParser extends ParserInfo {
  // 可能的额外属性
  version?: string;
  priority?: number;
}

export class ParserService {
  private static readonly TAG: string = 'ParserService';
  // 使用静态私有成员变量存储单例实例
  private static instance: ParserService | null = null;
  
  private parsers: Map<string, ParserInfo> = new Map();
  private defaultConfig: ParserConfig = {
    enabled: true,
    timeout: 30000,
    retryCount: 2
  };
  
  /**
   * 构造函数
   */
  private constructor() {
    // 初始化默认解析器
    this.initializeDefaultParsers();
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): ParserService {
    if (!ParserService.instance) {
      // 创建新实例并存储到静态变量
      ParserService.instance = new ParserService();
    }
    // 确保返回实例不为null
    return ParserService.instance!;
  }
  
  /**
   * 初始化服务
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(ParserService.TAG, 'Initializing ParserService...');
      
      // 加载解析器配置
      await this.loadParserConfig();
      
      // 加载自定义解析器
      await this.loadCustomParsers();
      
      Logger.info(ParserService.TAG, `ParserService initialized with ${this.parsers.size} parsers`);
    } catch (error) {
      Logger.error(ParserService.TAG, `Failed to initialize ParserService: ${error}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取视频源列表
   * @param contentId 内容ID
   * @param contentType 内容类型
   * @returns Promise<NetworkResult<VideoSourceInfo[]>>
   */
  public async getVideoSources(contentId: string, contentType: string): Promise<NetworkResult<VideoSourceInfo[]>> {
    try {
      Logger.info(ParserService.TAG, `Getting video sources for contentId: ${contentId}, contentType: ${contentType}`);
      
      // 这里可以根据contentId和contentType获取视频源列表
      // 目前返回一个模拟的空列表，可以根据实际需求实现
      return { success: true, data: [] };
    } catch (error) {
      Logger.error(ParserService.TAG, `Failed to get video sources: ${error}`);
      return { 
        success: false, 
        error: error instanceof Error ? error : new Error(String(error)),
        message: 'Failed to get video sources' 
      };
    }
  }

  /**
   * 解析视频源
   * @param sourceUrl 原始视频源URL
   * @param parserId 解析器ID（可选）
   * @returns Promise<NetworkResult<VideoSourceInfo>>
   */
  public async parseVideoSource(sourceUrl: string, parserId?: string): Promise<NetworkResult<VideoSourceInfo>> {
    try {
      Logger.info(ParserService.TAG, `Parsing video source: ${sourceUrl}, parserId: ${parserId}`);
      
      // 验证URL
      if (!sourceUrl || typeof sourceUrl !== 'string') {
        return { success: false, message: 'Invalid source URL' };
      }
      
      // 获取解析器
      const parser = this.getParser(parserId);
      if (!parser) {
        return { success: false, message: 'No suitable parser found' };
      }
      
      // 执行解析
      // 手动合并配置，避免对象展开操作
      const config: ParserConfig = {
        enabled: this.defaultConfig.enabled,
        timeout: this.defaultConfig.timeout,
        retryCount: this.defaultConfig.retryCount
      };
      
      const context: ParserContext = {
        parserId: parser.id,
        sourceUrl,
        config: config
      };
      
      const result = await this.executeParser(context);
      
      // 记录解析结果
      Logger.info(ParserService.TAG, `Parse result for ${sourceUrl}: ${result.success ? 'success' : 'failed'}`);
      
      return result;
    } catch (error) {
      Logger.error(ParserService.TAG, `Failed to parse video source: ${error}`);
      return { success: false, message: `Parse failed: ${error instanceof Error ? error.message : String(error)}` };
    }
  }
  
  /**
   * 获取所有可用解析器
   * @returns Promise<NetworkResult<ParserInfo[]>>
   */
  public async getParsers(): Promise<NetworkResult<ParserInfo[]>> {
    try {
      const parserList = Array.from(this.parsers.values()).filter(p => p.enabled !== false);
      return { success: true, data: parserList };
    } catch (error) {
      Logger.error(ParserService.TAG, `Failed to get parsers: ${error}`);
      return { success: false, message: `Get parsers failed: ${error}` };
    }
  }
  
  /**
   * 检查解析器是否可用
   * @param parserId 解析器ID
   * @returns Promise<NetworkResult<boolean>>
   */
  public async checkParserAvailability(parserId: string): Promise<NetworkResult<boolean>> {
    try {
      const parser = this.parsers.get(parserId);
      const available = !!parser && parser.enabled !== false;
      return { success: true, data: available };
    } catch (error) {
      Logger.error(ParserService.TAG, `Failed to check parser availability: ${error}`);
      return { success: false, message: `Check availability failed: ${error}` };
    }
  }
  
  /**
   * 添加自定义解析器
   * @param parser 解析器信息
   */
  public addParser(parser: ParserInfo): void {
    if (parser && parser.id) {
      this.parsers.set(parser.id, parser);
      Logger.info(ParserService.TAG, `Added custom parser: ${parser.name} (${parser.id})`);
    }
  }
  
  /**
   * 移除解析器
   * @param parserId 解析器ID
   */
  public removeParser(parserId: string): void {
    if (this.parsers.delete(parserId)) {
      Logger.info(ParserService.TAG, `Removed parser: ${parserId}`);
    }
  }
  
  /**
   * 更新解析器配置
   * @param parserId 解析器ID
   * @param config 新配置
   */
  public updateParserConfig(parserId: string, config: Partial<ParserInfo>): void {
    const parser = this.parsers.get(parserId);
    if (parser) {
      // 手动合并解析器配置，避免对象展开操作
      const updatedParser: ParserInfo = {
        id: parser.id,
        name: parser.name,
        description: config.description !== undefined ? config.description : parser.description,
        supports: config.supports !== undefined ? config.supports : parser.supports,
        version: config.version !== undefined ? config.version : parser.version,
        isEnabled: config.isEnabled !== undefined ? config.isEnabled : parser.isEnabled,
        config: config.config !== undefined ? config.config : parser.config
      };
      
      this.parsers.set(parserId, updatedParser);
      Logger.info(ParserService.TAG, 'Updated parser config', updatedParser as Error);
    }
  }
  
  /**
   * 初始化默认解析器
   */
  private initializeDefaultParsers(): void {
    // 添加默认解析器
    const defaultParsers: ParserInfo[] = [
      {
        id: 'direct',
        name: '直链解析',
        description: '直接使用原始URL，适用于HTTP/HTTPS视频流',
        supports: ['http', 'https'],
        version: '1.0',
        isEnabled: true
      },
      {
        id: 'hls',
        name: 'HLS解析',
        description: '解析HLS流(m3u8格式)',
        supports: ['m3u8', 'hls'],
        version: '1.0',
        isEnabled: true
      },
      {
        id: 'dash',
        name: 'DASH解析',
        description: '解析DASH流(mpd格式)',
        supports: ['mpd', 'dash'],
        version: '1.0',
        isEnabled: true
      },
      {
        id: 'mp4',
        name: 'MP4解析',
        description: 'MP4文件直接播放解析',
        supports: ['mp4'],
        version: '1.0',
        isEnabled: true
      },
      {
        id: 'flv',
        name: 'FLV解析',
        description: 'FLV文件直接播放解析',
        supports: ['flv'],
        version: '1.0',
        isEnabled: true
      }
    ];
    
    // 注册默认解析器
    defaultParsers.forEach(parser => {
      this.parsers.set(parser.id, parser);
    });
  }
  
  /**
   * 加载解析器配置
   */
  private async loadParserConfig(): Promise<void> {
    try {
      // 从配置服务加载解析器配置
      const parserConfig = await configService.getConfig<Record<string, boolean | number>>('parserConfig', {});
      
      if (parserConfig && typeof parserConfig === 'object') {
        // 手动合并默认配置，避免对象展开操作
        if (parserConfig.enabled !== undefined) {
          this.defaultConfig.enabled = parserConfig.enabled as boolean;
        }
        if (parserConfig.timeout !== undefined) {
          this.defaultConfig.timeout = parserConfig.timeout as number;
        }
        if (parserConfig.retryCount !== undefined) {
          this.defaultConfig.retryCount = parserConfig.retryCount as number;
        }
      }
    } catch (error) {
      Logger.warn(ParserService.TAG, `Failed to load parser config: ${error}`);
    }
  }
  
  /**
   * 加载自定义解析器
   */
  private async loadCustomParsers(): Promise<void> {
    try {
      // 从配置服务加载自定义解析器
      const customParsers: CustomParser[] = await configService.getConfig<CustomParser[]>('customParsers', []);
      
      if (Array.isArray(customParsers)) {
        for (let i = 0; i < customParsers.length; i++) {
          const parser = customParsers[i];
          try {
            if (parser && typeof parser === 'object' && parser.id && parser.name) {
              this.addParser({
                id: parser.id,
                name: parser.name,
                description: parser.description,
                type: parser.type,
                url: parser.url,
                enabled: parser.enabled !== undefined ? parser.enabled : true
              } as ParserInfo);
            }
          } catch (error) {
            Logger.warn(ParserService.TAG, `Failed to add custom parser: ${error}`);
          }
        }
      }
    } catch (error) {
      Logger.warn(ParserService.TAG, `Failed to load custom parsers: ${error}`);
    }
  }
  
  /**
   * 获取适合的解析器
   */
  private getParser(parserId?: string): ParserInfo | undefined {
    // 如果指定了解析器ID，优先使用
    if (parserId) {
      return this.parsers.get(parserId);
    }
    
    // 返回默认解析器
    return this.parsers.get('direct');
  }
  
  /**
   * 执行解析器
   */
  private async executeParser(context: ParserContext): Promise<NetworkResult<VideoSourceInfo>> {
    let attempts = 0;
    
    while (attempts <= context.config.retryCount!) {
      attempts++;
      
      try {
        // 根据解析器类型执行不同的解析逻辑
        let result: VideoSourceInfo;
        
        switch (context.parserId) {
          case 'direct':
            result = await this.directParse(context.sourceUrl);
            break;
          case 'hls':
            result = await this.hlsParse(context.sourceUrl);
            break;
          case 'dash':
            result = await this.dashParse(context.sourceUrl);
            break;
          case 'mp4':
          case 'flv':
            result = await this.directParse(context.sourceUrl);
            break;
          default:
            // 对于自定义解析器，这里可以扩展为调用外部API或其他解析逻辑
            result = await this.directParse(context.sourceUrl);
        }
        
        return { success: true, data: result };
      } catch (error) {
        Logger.warn(ParserService.TAG, `Parse attempt ${attempts} failed: ${error instanceof Error ? error.message : String(error)}`);
        
        if (attempts > context.config.retryCount!) {
          throw error instanceof Error ? error : new Error(String(error));
        }
        
        // 指数退避重试
        const backoffTime = Math.pow(2, attempts - 1) * 1000 + Math.random() * 500;
        // 等待一段时间后重试
        await new Promise(resolve => setTimeout(resolve, backoffTime));
      }
    }
    
    throw new Error('All parse attempts failed');
  }
  
  /**
   * 直接解析（不做处理）
   */
  private async directParse(url: string): Promise<VideoSourceInfo> {
    // 简单检测视频类型
    let format = 'unknown';
    let mimeType = 'video/mp4'; // 默认
    
    if (url.includes('.m3u8')) {
      format = 'hls';
      mimeType = 'application/x-mpegURL';
    } else if (url.includes('.mpd')) {
      format = 'dash';
      mimeType = 'application/dash+xml';
    } else if (url.includes('.mp4')) {
      format = 'mp4';
      mimeType = 'video/mp4';
    } else if (url.includes('.flv')) {
      format = 'flv';
      mimeType = 'video/x-flv';
    } else if (url.includes('.mkv')) {
      format = 'mkv';
      mimeType = 'video/x-matroska';
    }
    
    return {
      id: `source_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name: `Direct Source (${format})`,
      url,
      format,
      mimeType,
      quality: 'unknown',
      headers: {},
      duration: 0
    };
  }
  
  /**
   * HLS流解析
   */
  private async hlsParse(url: string): Promise<VideoSourceInfo> {
    try {
      // 验证URL是否为m3u8格式
      let m3u8Url = url;
      if (!url.includes('.m3u8')) {
        // 尝试获取重定向后的URL
        try {
          const response = await HttpService.getInstance().head(url, { timeout: 10000 });
          if (response.headers) {
            const contentType = response.headers['content-type'] || response.headers['Content-Type'];
            if (contentType && contentType.includes('application/x-mpegURL')) {
              m3u8Url = url;
            }
          }
        } catch (headError) {
          // HEAD请求失败，继续使用原始URL
          Logger.debug(ParserService.TAG, `HEAD request failed: ${headError instanceof Error ? headError.message : String(headError)}`);
        }
      }
      
      return {
        id: `source_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        name: `HLS Source`,
        url: m3u8Url,
        format: 'hls',
        mimeType: 'application/x-mpegURL',
        quality: this.detectQuality(m3u8Url),
        headers: {},
        duration: 0
      };
    } catch (error) {
      Logger.warn(ParserService.TAG, `Failed to parse HLS stream: ${error instanceof Error ? error.message : String(error)}`);
      // 降级为直接解析
      return this.directParse(url);
    }
  }
  
  /**
   * DASH流解析
   */
  private async dashParse(url: string): Promise<VideoSourceInfo> {
    try {
      // 验证URL是否为mpd格式
      let mpdUrl = url;
      if (!url.includes('.mpd')) {
        // 尝试获取重定向后的URL
        try {
          const response = await HttpService.getInstance().head(url, { timeout: 10000 });
          if (response.headers) {
            const contentType = response.headers['content-type'] || response.headers['Content-Type'];
            if (contentType && contentType.includes('application/dash+xml')) {
              mpdUrl = url;
            }
          }
        } catch (headError) {
          // HEAD请求失败，继续使用原始URL
          Logger.debug(ParserService.TAG, `HEAD request failed: ${headError instanceof Error ? headError.message : String(headError)}`);
        }
      }
      
      return {
        id: `source_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        name: `DASH Source`,
        url: mpdUrl,
        format: 'dash',
        mimeType: 'application/dash+xml',
        quality: this.detectQuality(mpdUrl),
        headers: {},
        duration: 0
      };
    } catch (error) {
      Logger.warn(ParserService.TAG, `Failed to parse DASH stream: ${error instanceof Error ? error.message : String(error)}`);
      // 降级为直接解析
      return this.directParse(url);
    }
  }
  
  /**
   * 从URL检测视频质量
   */
  private detectQuality(url: string): string {
    const lowercaseUrl = url.toLowerCase();
    
    if (lowercaseUrl.includes('4k') || lowercaseUrl.includes('2160')) {
      return '4K';
    } else if (lowercaseUrl.includes('1080') || lowercaseUrl.includes('fhd')) {
      return '1080P';
    } else if (lowercaseUrl.includes('720') || lowercaseUrl.includes('hd')) {
      return '720P';
    } else if (lowercaseUrl.includes('480') || lowercaseUrl.includes('sd')) {
      return '480P';
    } else if (lowercaseUrl.includes('360')) {
      return '360P';
    }
    
    return 'unknown';
  }
  
  /**
   * 清理资源
   */
  public destroy(): void {
    try {
      this.parsers.clear();
      Logger.info(ParserService.TAG, 'ParserService destroyed');
      // 重置单例实例
      ParserService.instance = null;
    } catch (error) {
      Logger.error(ParserService.TAG, `Failed to destroy ParserService: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

// 导出单例实例 - 使用函数调用方式
export function getParserService(): ParserService {
  return ParserService.getInstance();
}