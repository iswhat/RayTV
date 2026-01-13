import Logger from '../../common/util/Logger';
import { Site } from '../../data/bean/Site';
import { SiteManager } from '../spider/SiteManager';
import { ConfigLoader } from './ConfigLoader';
import { ConfigParser } from './ConfigParser';
import { SiteDao } from '../../data/db/dao/SiteDao';
import { LineDao } from '../../data/db/dao/LineDao';
import http from '@ohos.net.http';

const TAG = 'LineManager';

/**
 * 线路配置接口 | Line configuration interface
 */
export interface LineItem {
  id: string;              // 唯一标识 | Unique identifier
  name: string;            // 线路名称 | Line name
  url: string;             // 线路URL | Line URL
  description?: string;    // 线路描述 | Line description
  type?: 'all' | 'vod' | 'live'; // 线路类型 | Line type
  updateTime: number;      // 最后更新时间 | Last update time
  createTime: number;      // 创建时间 | Create time
  sourceCount: number;     // 包含源数量 | Number of sources
  enabled: boolean;        // 是否启用 | Whether enabled
  current: boolean;        // 是否为当前使用的线路 | Whether it is the currently used line
  cacheTime?: number;      // 缓存时间（小时） | Cache time (hours)
  responseTime?: number;   // 响应时间（毫秒） | Response time (milliseconds)
}

/**
 * 源响应测试结果 | Source response test result
 */
export interface SourceResponseResult {
  sourceId: string;
  sourceName: string;
  responseTime: number;    // 响应时间（毫秒） | Response time (milliseconds)
  success: boolean;
  error?: string;
}

/**
 * 线路响应测试结果 | Line response test result
 */
export interface LineResponseResult {
  lineId: string;
  lineName: string;
  responseTime: number;    // 响应时间（毫秒） | Response time (milliseconds)
  success: boolean;
  error?: string;
  sourceResults?: SourceResponseResult[];
}

/**
 * 线路管理结果 | Line management result
 */
export interface LineResult {
  success: boolean;
  message?: string;
  data?: Record<string, unknown>;
}

/**
 * 线路管理器 | Line manager
 * 负责配置URL的线路管理、更新和切换 | Responsible for line management, update and switching of configuration URLs
 */
export class LineManager {
  private static instance: LineManager | null = null;
  private lines: Map<string, LineItem> = new Map();
  private siteManager: SiteManager;
  private configLoader: ConfigLoader;
  private configParser: ConfigParser;
  private siteDao: SiteDao;
  private lineDao: LineDao;
  private initialized: boolean = false;
  private context?: any;
  
  // 默认缓存时间配置
  private defaultCacheHours: number = 24; // 默认24小时 | Default 24 hours
  private minCacheHours: number = 24;     // 最小24小时 | Minimum 24 hours
  private maxCacheHours: number = 72;     // 最大72小时 | Maximum 72 hours

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): LineManager {
    if (!LineManager.instance) {
      LineManager.instance = new LineManager();
    }
    return LineManager.instance;
  }

  /**
   * 构造函数 | Constructor
   */
  private constructor() {
    this.siteManager = SiteManager.getInstance();
    this.configLoader = ConfigLoader.getInstance();
    this.configParser = ConfigParser.getInstance();
    this.siteDao = new SiteDao();
    this.lineDao = new LineDao();
    Logger.info(TAG, 'LineManager initialized');
  }

  /**
   * 设置缓存时间范围 | Set cache time range
   * @param minHours 最小缓存时间（小时） | Minimum cache time (hours)
   * @param maxHours 最大缓存时间（小时） | Maximum cache time (hours)
   */
  public setCacheTimeRange(minHours: number, maxHours: number): void {
    this.minCacheHours = Math.max(24, minHours);
    this.maxCacheHours = Math.min(72, Math.max(this.minCacheHours, maxHours));
    Logger.info(TAG, `Cache time range set to ${this.minCacheHours}-${this.maxCacheHours} hours`);
  }

  /**
   * 初始化线路管理器 | Initialize line manager
   * @param context 应用上下文 | Application context
   */
  public async initialize(context?: any): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 保存上下文（如果提供） | Save context (if provided)
      if (context) {
        this.context = context;
      }
      
      Logger.info(TAG, 'Initializing line manager...');
      
      // 初始化线路表 | Initialize line table
      await this.lineDao.initTable(context);
      
      // 从持久化存储加载线路配置 | Load line config from persistent storage
      await this.loadLines();
      
      // 恢复当前线路的源 | Restore sources for current line
      const currentLine = this.getCurrentLine();
      if (currentLine && currentLine.enabled) {
        Logger.info(TAG, `Restoring sources for current line: ${currentLine.name}`);
        try {
          // 加载配置并注册源 | Load config and register sources
          const configContent = await this.configLoader.loadFromUrl(currentLine.url);
          const sites = this.configParser.parseSites(configContent);
          await this.siteManager.registerSites(sites);
        } catch (error) {
          Logger.error(TAG, `Failed to restore current line sources`, error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      this.initialized = true;
      Logger.info(TAG, `Line manager initialized with ${this.lines.size} lines`);
    } catch (error) {
      Logger.error(TAG, `Failed to initialize line manager`, error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }

  /**
   * 添加线路 | Add line
   * @param name 线路名称 | Line name
   * @param url 线路URL | Line URL
   * @param description 线路描述 | Line description
   * @param cacheTime 缓存时间（小时） | Cache time (hours)
   */
  public async addLine(name: string, url: string, description?: string, cacheTime?: number): Promise<LineResult> {
    try {
      // 验证URL格式 | Validate URL format
      if (!this.isValidUrl(url)) {
        return {
          success: false,
          message: '无效的URL格式' 
        };
      }

      // 验证并规范化缓存时间 | Validate and normalize cache time
      const normalizedCacheTime = this.normalizeCacheTime(cacheTime);

      // 生成线路ID | Generate line ID
      const id = this.generateLineId(url);
      
      // 检查是否已存在相同URL的线路 | Check if line with same URL already exists
      if (this.lines.has(id)) {
        return {
          success: false,
          message: '线路URL已存在'
        };
      }

      // 测试线路URL是否可访问 | Test if line URL is accessible
      const testResult = await this.testLineUrl(url);
      if (!testResult.success) {
        return testResult;
      }

      // 创建线路项 | Create line item
      const line: LineItem = {
        id,
        name,
        url,
        description,
        updateTime: Date.now(),
        createTime: Date.now(),
        sourceCount: (testResult.data?.sites?.length || 0),
        enabled: true,
        current: false,
        cacheTime: normalizedCacheTime,
        responseTime: testResult.data?.responseTime
      };

      // 添加到线路列表 | Add to line list
      this.lines.set(id, line);
      
      // 保存到持久化存储 | Save to persistent storage
      await this.saveLines();

      Logger.info(TAG, `Added line: ${name} (${url})`);
      return {
        success: true,
        message: '线路添加成功',
        data: line
      };
    } catch (error) {
      Logger.error(TAG, `Failed to add line: ${error}`);
      return {
        success: false, 
        message: `添加线路失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 删除线路 | Delete line
   * @param lineId 线路ID | Line ID
   */
  public async deleteLine(lineId: string): Promise<LineResult> {
    try {
      const line = this.lines.get(lineId);
      if (!line) {
        return {
          success: false,
          message: '线路不存在'
        };
      }

      // 如果是当前使用的线路，先禁用 | If it is the current line, disable first
      if (line.current) {
        await this.disableCurrentLine();
      }

      // 从线路列表中删除 | Remove from line list
      this.lines.delete(lineId);
      
      // 保存到持久化存储 | Save to persistent storage
      await this.saveLines();

      Logger.info(TAG, `Deleted line: ${line.name}`);
      return {
        success: true,
        message: '线路删除成功'
      };
    } catch (error) {
      Logger.error(TAG, `Failed to delete line: ${error}`);
      return {
        success: false, 
        message: `删除线路失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 更新线路 | Update line
   * @param lineId 线路ID | Line ID
   * @param data 更新数据 | Update data
   */
  public async updateLine(lineId: string, data: Partial<LineItem>): Promise<LineResult> {
    try {
      const line = this.lines.get(lineId);
      if (!line) {
        return {
          success: false,
          message: '线路不存在'
        };
      }

      // 验证并规范化缓存时间（如果提供） | Validate and normalize cache time (if provided)
      if (data.cacheTime !== undefined) {
        data.cacheTime = this.normalizeCacheTime(data.cacheTime);
      }

      // 更新线路信息 | Update line information
      const updatedLine = { ...line, ...data };
      updatedLine.updateTime = Date.now();

      // 如果更新了URL，需要重新生成ID | If URL is updated, need to regenerate ID
      if (data.url && data.url !== line.url) {
        // 验证新URL | Validate new URL
        if (!this.isValidUrl(data.url)) {
          return {
            success: false,
            message: '无效的URL格式'
          };
        }

        // 检查新URL是否已存在 | Check if new URL already exists
        const newId = this.generateLineId(data.url);
        if (this.lines.has(newId) && newId !== lineId) {
          return {
            success: false,
            message: '新URL已存在线路'
          };
        }

        // 从旧ID删除 | Remove from old ID
        this.lines.delete(lineId);
        
        // 用新ID添加 | Add with new ID
        updatedLine.id = newId;
        this.lines.set(newId, updatedLine);
      } else {
        this.lines.set(lineId, updatedLine);
      }

      // 保存到持久化存储 | Save to persistent storage
      await this.saveLines();

      Logger.info(TAG, `Updated line: ${updatedLine.name}`);
      return {
        success: true,
        message: '线路更新成功',
        data: updatedLine
      };
    } catch (error) {
      Logger.error(TAG, `Failed to update line: ${error}`);
      return {
        success: false, 
        message: `更新线路失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 刷新线路（强制更新，跳过缓存） | Refresh line (force update, skip cache)
   * @param lineId 线路ID | Line ID
   */
  public async refreshLine(lineId: string): Promise<LineResult> {
    try {
      const line = this.lines.get(lineId);
      if (!line) {
        return {
          success: false,
          message: '线路不存在'
        };
      }

      // 强制从URL加载最新配置（跳过缓存） | Force load latest config from URL (skip cache)
      const startTime = Date.now();
      const configContent = await this.configLoader.loadFromUrl(line.url, line.cacheTime, true);
      const responseTime = Date.now() - startTime;
      
      // 解析源配置 | Parse source config
      const sites = this.configParser.parseSites(configContent);
      
      // 更新线路信息 | Update line information
      line.sourceCount = sites.length;
      line.updateTime = Date.now();
      line.responseTime = responseTime;
      
      // 如果是当前线路，更新源 | If it is current line, update sources
      if (line.current) {
        // 先禁用所有当前源 | First disable all current sources
        await this.disableCurrentSources();
        
        // 注册新源 | Register new sources
        await this.siteManager.registerSites(sites);
      }

      // 保存到持久化存储 | Save to persistent storage
      await this.saveLines();

      Logger.info(TAG, `Refreshed line: ${line.name}, loaded ${sites.length} sources`);
      return {
        success: true,
        message: `线路刷新成功，共${sites.length}个源，响应时间${responseTime}ms`,
        data: {
          line,
          sites,
          responseTime
        }
      };
    } catch (error) {
      Logger.error(TAG, `Failed to refresh line: ${error}`);
      return {
        success: false, 
        message: `刷新线路失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 切换到指定线路 | Switch to specified line
   * @param lineId 线路ID | Line ID
   */
  public async switchToLine(lineId: string): Promise<LineResult> {
    try {
      const line = this.lines.get(lineId);
      if (!line) {
        return {
          success: false,
          message: '线路不存在'
        };
      }

      if (!line.enabled) {
        return {
          success: false,
          message: '线路已禁用'
        };
      }

      // 禁用当前线路 | Disable current line
      await this.disableCurrentLine();

      // 设置新的当前线路 | Set new current line
      line.current = true;
      
      // 加载线路配置，使用线路配置的缓存时间 | Load line config, use line's cache time
      const configContent = await this.configLoader.loadFromUrl(line.url, line.cacheTime);
      const sites = this.configParser.parseSites(configContent);
      
      // 注册源 | Register sources
      await this.siteManager.registerSites(sites);
      
      // 保存到持久化存储 | Save to persistent storage
      await this.saveLines();

      Logger.info(TAG, `Switched to line: ${line.name}, loaded ${sites.length} sources`);
      return {
        success: true,
        message: `成功切换到线路"${line.name}"`,
        data: sites
      };
    } catch (error) {
      Logger.error(TAG, `Failed to switch line: ${error}`);
      return {
        success: false, 
        message: `切换线路失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 测试线路响应速度 | Test line response speed
   * @param lineId 线路ID | Line ID
   * @param multiThread 是否使用多线程 | Whether to use multi-thread
   * @param timeout 超时时间（毫秒） | Timeout time (milliseconds)
   */
  public async testLineResponse(lineId: string, multiThread: boolean = false, timeout: number = 20000): Promise<LineResponseResult> {
    const line = this.lines.get(lineId);
    if (!line) {
      return {
        lineId,
        lineName: '',
        responseTime: 0,
        success: false,
        error: '线路不存在'
      };
    }

    try {
      const startTime = Date.now();
      
      // 测试线路响应速度 | Test line response speed
      const configContent = await this.configLoader.loadFromUrl(line.url);
      const responseTime = Date.now() - startTime;
      
      // 解析源 | Parse sources
      const sites = this.configParser.parseSites(configContent);
      
      // 更新线路响应时间 | Update line response time
      line.responseTime = responseTime;
      await this.saveLines();
      
      return {
        lineId: line.id,
        lineName: line.name,
        responseTime,
        success: true
      };
    } catch (error) {
      Logger.error(TAG, `Failed to test line response: ${error}`);
      return {
        lineId: line.id, 
        lineName: line.name,
        responseTime: 0,
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 测试线路下所有源的响应速度 | Test response speed of all sources under line
   * @param lineId 线路ID | Line ID
   * @param multiThread 是否使用多线程 | Whether to use multi-thread
   * @param timeout 超时时间（毫秒） | Timeout time (milliseconds)
   */
  public async testSourceResponses(lineId: string, multiThread: boolean = false, timeout: number = 15000): Promise<SourceResponseResult[]> {
    const line = this.lines.get(lineId);
    if (!line) {
      return [];
    }

    try {
      // 加载线路配置 | Load line config
      const configContent = await this.configLoader.loadFromUrl(line.url);
      const sites = this.configParser.parseSites(configContent);
      
      const results: SourceResponseResult[] = [];
      
      if (multiThread) {
        // 多线程模式 | Multi-thread mode
        const testPromises = sites.map(async (site) => {
          try {
            const startTime = Date.now();
            
            // 创建HTTP请求对象 | Create HTTP request object
            const httpRequest = http.createHttp();
            httpRequest.setTimeout({ connectTimeout: timeout });
            
            // 测试源URL | Test source URL
            const response = await httpRequest.request(site.url, {
              method: http.RequestMethod.GET,
              header: {
                'User-Agent': 'RayTV-HarmonyOS',
                'Accept': '*/*'
              }
            });
            
            // 释放资源 | Release resources
            httpRequest.destroy();
            
            const responseTime = Date.now() - startTime;
            
            return {
              sourceId: site.key,
              sourceName: site.name,
              responseTime,
              success: response.ok
            };
          } catch (error) {
            return {
              sourceId: site.key,
              sourceName: site.name,
              responseTime: 0,
              success: false,
              error: String(error)
            };
          }
        });
        
        // 等待所有测试完成 | Wait for all tests to complete
        const threadResults = await Promise.all(testPromises);
        results.push(...threadResults);
      } else {
        // 单线程模式 | Single-thread mode
        for (const site of sites) {
          try {
            const startTime = Date.now();
            
            // 创建HTTP请求对象 | Create HTTP request object
            const httpRequest = http.createHttp();
            httpRequest.setTimeout({ connectTimeout: timeout });
            
            // 测试源URL | Test source URL
            const response = await httpRequest.request(site.url, {
              method: http.RequestMethod.GET,
              header: {
                'User-Agent': 'RayTV-HarmonyOS',
                'Accept': '*/*'
              }
            });
            
            // 释放资源 | Release resources
            httpRequest.destroy();
            
            const responseTime = Date.now() - startTime;
            
            results.push({
              sourceId: site.key,
              sourceName: site.name,
              responseTime,
              success: response.ok
            });
          } catch (error) {
            results.push({
              sourceId: site.key,
              sourceName: site.name,
              responseTime: 0,
              success: false,
              error: String(error)
            });
          }
        }
      }
      
      return results;
    } catch (error) {
      Logger.error(TAG, 'Failed to test source responses', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * 禁用当前线路 | Disable current line
   */
  private async disableCurrentLine(): Promise<void> {
    // 禁用所有源 | Disable all sources
    await this.disableCurrentSources();
    
    // 重置所有线路的current状态 | Reset current status of all lines
    for (const line of this.lines.values()) {
      line.current = false;
    }
  }

  /**
   * 禁用当前所有源 | Disable all current sources
   */
  private async disableCurrentSources(): Promise<void> {
    const sites = this.siteManager.getAllSites();
    for (const site of sites) {
      await this.siteManager.setSiteEnabled(site.key, false);
    }
  }

  /**
   * 测试线路URL | Test line URL
   * @param url 线路URL | Line URL
   */
  public async testLineUrl(url: string): Promise<LineResult> {
    try {
      Logger.info(TAG, `Testing line URL: ${url}`);
      
      const startTime = Date.now();
      // 加载配置，使用默认缓存时间，不强制更新 | Load config, use default cache time, not force update
      const configContent = await this.configLoader.loadFromUrl(url, this.defaultCacheHours);
      const responseTime = Date.now() - startTime;
      
      // 解析源 | Parse sources
      const sites = this.configParser.parseSites(configContent);
      
      // 验证源数量 | Validate source count
      if (sites.length === 0) {
        return {
          success: false,
          message: '配置文件中未找到有效源'
        };
      }
      
      return {
        success: true,
        message: `URL访问成功，发现${sites.length}个源，响应时间${responseTime}ms`,
        data: { sites, responseTime }
      };
    } catch (error) {
      Logger.error(TAG, 'Failed to test line URL', error instanceof Error ? error : new Error(String(error)));
      return {
        success: false,
        message: `URL测试失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 获取所有线路 | Get all lines
   */
  public getAllLines(): LineItem[] {
    return Array.from(this.lines.values());
  }

  /**
   * 获取线路详情 | Get line details
   * @param lineId 线路ID | Line ID
   */
  public getLine(lineId: string): LineItem | undefined {
    return this.lines.get(lineId);
  }

  /**
   * 获取当前使用的线路 | Get current line
   */
  public getCurrentLine(): LineItem | undefined {
    return Array.from(this.lines.values()).find(line => line.current);
  }

  /**
   * 检查是否有可用线路 | Check if there are available lines
   */
  public hasAvailableLines(): boolean {
    return Array.from(this.lines.values()).some(line => line.enabled);
  }

  /**
   * 生成线路ID | Generate line ID
   * @param url 线路URL | Line URL
   */
  private generateLineId(url: string): string {
    // 简单的URL哈希作为线路ID | Simple URL hash as line ID
    let hash = 0;
    for (let i = 0; i < url.length; i++) {
      const char = url.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return `line_${Math.abs(hash).toString(36)}`;
  }

  /**
   * 验证URL格式 | Validate URL format
   * @param url URL字符串 | URL string
   */
  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      // 简单的URL格式检查作为备用 | Simple URL format check as fallback
      return /^https?:\/\/.+/.test(url);
    }
  }

  /**
   * 规范化缓存时间 | Normalize cache time
   * @param hours 缓存时间（小时） | Cache time (hours)
   */
  private normalizeCacheTime(hours?: number): number {
    if (hours === undefined) {
      return this.defaultCacheHours;
    }
    return Math.max(this.minCacheHours, Math.min(this.maxCacheHours, Math.floor(hours)));
  }

  /**
   * 保存线路列表到持久化存储 | Save line list to persistent storage
   */
  private async saveLines(): Promise<void> {
    try {
      const lines = Array.from(this.lines.values());
      Logger.info(TAG, `Saving ${lines.length} lines`);
      
      // 批量保存线路 | Batch save lines
      await this.lineDao.saveAll(lines);
    } catch (error) {
      Logger.error(TAG, `Failed to save lines: ${error}`);
      // 保存失败不影响主要功能 | Save failure does not affect main functionality
    }
  }

  /**
   * 从持久化存储加载线路列表 | Load line list from persistent storage
   */
  private async loadLines(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading lines from storage');
      
      // 从数据库加载线路 | Load lines from database
      const lines = await this.lineDao.getAll();
      
      // 清空现有线路 | Clear existing lines
      this.lines.clear();
      
      // 添加到内存 | Add to memory
      lines.forEach(line => {
        this.lines.set(line.id, line);
      });
      
      Logger.info(TAG, `Loaded ${lines.length} lines from storage`);
    } catch (error) {
      Logger.error(TAG, `Failed to load lines: ${error}`);
    }
  }
}

export function getLineManager(): LineManager {
  return LineManager.getInstance();
}
