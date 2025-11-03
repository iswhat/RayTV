import Logger from '../../common/util/Logger';
import { Site } from '../../data/bean/Site';
import { SiteManager } from '../spider/SiteManager';
import { ConfigLoader } from './ConfigLoader';
import { ConfigParser } from './ConfigParser';
import { SiteDao } from '../../data/db/dao/SiteDao';
import { LineDao } from '../../data/dao/LineDao';
import http from '@ohos.net.http';

const TAG = 'LineManager';

/**
 * 线路项接口定义
 */
export interface LineItem {
  id: string;              // 唯一标识
  name: string;            // 线路名称
  url: string;             // 线路URL
  description?: string;    // 线路描述
  type?: 'all' | 'vod' | 'live'; // 线路类型
  updateTime: number;      // 最后更新时间
  createTime: number;      // 创建时间
  sourceCount: number;     // 包含片源数量
  enabled: boolean;        // 是否启用
  current: boolean;        // 是否为当前使用的线路
  cacheTime?: number;      // 缓存时间（小时）
  responseTime?: number;   // 响应时间（毫秒）
}

/**
 * 片源响应检测结果
 */
export interface SourceResponseResult {
  sourceId: string;
  sourceName: string;
  responseTime: number;    // 响应时间（毫秒）
  success: boolean;
  error?: string;
}

/**
 * 线路响应检测结果
 */
export interface LineResponseResult {
  lineId: string;
  lineName: string;
  responseTime: number;    // 响应时间（毫秒）
  success: boolean;
  error?: string;
  sourceResults?: SourceResponseResult[];
}

/**
 * 线路管理结果
 */
export interface LineResult {
  success: boolean;
  message?: string;
  data?: any;
}

/**
 * 线路管理器
 * 负责配置URL的线路管理、更新和切换
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
  private defaultCacheHours: number = 24; // 默认24小时
  private minCacheHours: number = 24;     // 最小24小时
  private maxCacheHours: number = 72;     // 最大72小时

  /**
   * 获取单例实例
   */
  public static getInstance(): LineManager {
    if (!LineManager.instance) {
      LineManager.instance = new LineManager();
    }
    return LineManager.instance;
  }

  /**
   * 构造函数
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
   * 设置缓存时间范围
   * @param minHours 最小缓存时间（小时）
   * @param maxHours 最大缓存时间（小时）
   */
  public setCacheTimeRange(minHours: number, maxHours: number): void {
    this.minCacheHours = Math.max(24, minHours);
    this.maxCacheHours = Math.min(72, Math.max(this.minCacheHours, maxHours));
    Logger.info(TAG, `Cache time range set to ${this.minCacheHours}-${this.maxCacheHours} hours`);
  }

  /**
   * 初始化线路管理器
   * @param context 应用上下文
   */
  public async initialize(context?: any): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 保存上下文（如果提供）
      if (context) {
        this.context = context;
      }
      
      Logger.info(TAG, 'Initializing line manager...');
      
      // 初始化线路表
      await this.lineDao.initTable(context);
      
      // 从持久化存储加载线路配置
      await this.loadLines();
      
      // 恢复当前线路的片源
      const currentLine = this.getCurrentLine();
      if (currentLine && currentLine.enabled) {
        Logger.info(TAG, `Restoring sources for current line: ${currentLine.name}`);
        try {
          // 加载配置并注册片源
          const configContent = await this.configLoader.loadFromUrl(currentLine.url);
          const sites = this.configParser.parseSites(configContent);
          await this.siteManager.registerSites(sites);
        } catch (error) {
          Logger.error(TAG, `Failed to restore current line sources: ${error}`);
        }
      }
      
      this.initialized = true;
      Logger.info(TAG, `Line manager initialized with ${this.lines.size} lines`);
    } catch (error) {
      Logger.error(TAG, `Failed to initialize line manager: ${error}`);
      throw error;
    }
  }

  /**
   * 添加线路
   * @param name 线路名称
   * @param url 线路URL
   * @param description 线路描述
   * @param cacheTime 缓存时间（小时）
   */
  public async addLine(name: string, url: string, description?: string, cacheTime?: number): Promise<LineResult> {
    try {
      // 验证URL格式
      if (!this.isValidUrl(url)) {
        return {
          success: false,
          message: '无效的URL格式'
        };
      }

      // 验证并规范化缓存时间
      const normalizedCacheTime = this.normalizeCacheTime(cacheTime);

      // 生成线路ID
      const id = this.generateLineId(url);
      
      // 检查是否已存在相同URL的线路
      if (this.lines.has(id)) {
        return {
          success: false,
          message: '线路URL已存在'
        };
      }

      // 测试线路URL是否可访问
      const testResult = await this.testLineUrl(url);
      if (!testResult.success) {
        return testResult;
      }

      // 创建线路项
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

      // 添加到线路列表
      this.lines.set(id, line);
      
      // 保存到持久化存储
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
   * 删除线路
   * @param lineId 线路ID
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

      // 如果是当前使用的线路，先停用
      if (line.current) {
        await this.disableCurrentLine();
      }

      // 从线路列表中移除
      this.lines.delete(lineId);
      
      // 保存到持久化存储
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
   * 更新线路
   * @param lineId 线路ID
   * @param data 更新数据
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

      // 验证并规范化缓存时间（如果提供）
      if (data.cacheTime !== undefined) {
        data.cacheTime = this.normalizeCacheTime(data.cacheTime);
      }

      // 更新线路信息
      const updatedLine = {
        ...line,
        ...data,
        updateTime: Date.now()
      };

      // 如果更新了URL，需要重新生成ID
      if (data.url && data.url !== line.url) {
        // 验证新URL
        if (!this.isValidUrl(data.url)) {
          return {
            success: false,
            message: '无效的URL格式'
          };
        }

        // 检查新URL是否已存在
        const newId = this.generateLineId(data.url);
        if (this.lines.has(newId) && newId !== lineId) {
          return {
            success: false,
            message: '新URL已存在线路'
          };
        }

        // 从旧ID移除
        this.lines.delete(lineId);
        
        // 用新ID添加
        updatedLine.id = newId;
        this.lines.set(newId, updatedLine);
      } else {
        this.lines.set(lineId, updatedLine);
      }

      // 保存到持久化存储
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
   * 刷新线路（强制刷新，忽略缓存）
   * @param lineId 线路ID
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

      // 强制从URL加载最新配置（忽略缓存）
      const startTime = Date.now();
      const configContent = await this.configLoader.loadFromUrl(line.url, line.cacheTime, true);
      const responseTime = Date.now() - startTime;
      
      // 解析片源配置
      const sites = this.configParser.parseSites(configContent);
      
      // 更新线路信息
      line.sourceCount = sites.length;
      line.updateTime = Date.now();
      line.responseTime = responseTime;
      
      // 如果是当前线路，更新片源
      if (line.current) {
        // 先禁用所有当前片源
        await this.disableCurrentSources();
        
        // 注册新片源
        await this.siteManager.registerSites(sites);
      }

      // 保存到持久化存储
      await this.saveLines();

      Logger.info(TAG, `Refreshed line: ${line.name}, loaded ${sites.length} sources`);
      return {
        success: true,
        message: `线路刷新成功，共${sites.length}个片源，响应时间${responseTime}ms`,
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
   * 切换到指定线路
   * @param lineId 线路ID
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

      // 停用当前线路
      await this.disableCurrentLine();

      // 设置新的当前线路
      line.current = true;
      
      // 加载线路配置，使用线路配置的缓存时间
      const configContent = await this.configLoader.loadFromUrl(line.url, line.cacheTime);
      const sites = this.configParser.parseSites(configContent);
      
      // 注册片源
      await this.siteManager.registerSites(sites);
      
      // 保存到持久化存储
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
   * 检测线路响应速度
   * @param lineId 线路ID
   * @param multiThread 是否使用多线程
   * @param timeout 超时时间（毫秒）
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
      
      // 测试线路响应速度
      const configContent = await this.configLoader.loadFromUrl(line.url);
      const responseTime = Date.now() - startTime;
      
      // 解析片源
      const sites = this.configParser.parseSites(configContent);
      
      // 更新线路响应时间
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
   * 检测线路下所有片源的响应速度
   * @param lineId 线路ID
   * @param multiThread 是否使用多线程
   * @param timeout 超时时间（毫秒）
   */
  public async testSourceResponses(lineId: string, multiThread: boolean = false, timeout: number = 15000): Promise<SourceResponseResult[]> {
    const line = this.lines.get(lineId);
    if (!line) {
      return [];
    }

    try {
      // 加载线路配置
      const configContent = await this.configLoader.loadFromUrl(line.url);
      const sites = this.configParser.parseSites(configContent);
      
      const results: SourceResponseResult[] = [];
      
      if (multiThread) {
        // 多线程模式
        const testPromises = sites.map(async (site) => {
          try {
            const startTime = Date.now();
            
            // 创建HTTP请求对象
            const httpRequest = http.createHttp();
            httpRequest.setTimeout({ connectTimeout: timeout });
            
            // 测试片源URL
            const response = await httpRequest.request(site.url, {
              method: http.RequestMethod.GET,
              header: {
                'User-Agent': 'RayTV-HarmonyOS',
                'Accept': '*/*'
              }
            });
            
            // 释放资源
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
        
        // 等待所有测试完成
        const threadResults = await Promise.all(testPromises);
        results.push(...threadResults);
      } else {
        // 单线程模式
        for (const site of sites) {
          try {
            const startTime = Date.now();
            
            // 创建HTTP请求对象
            const httpRequest = http.createHttp();
            httpRequest.setTimeout({ connectTimeout: timeout });
            
            // 测试片源URL
            const response = await httpRequest.request(site.url, {
              method: http.RequestMethod.GET,
              header: {
                'User-Agent': 'RayTV-HarmonyOS',
                'Accept': '*/*'
              }
            });
            
            // 释放资源
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
      Logger.error(TAG, `Failed to test source responses: ${error}`);
      return [];
    }
  }

  /**
   * 禁用当前线路
   */
  private async disableCurrentLine(): Promise<void> {
    // 禁用所有片源
    await this.disableCurrentSources();
    
    // 重置所有线路的current状态
    for (const line of this.lines.values()) {
      line.current = false;
    }
  }

  /**
   * 禁用当前所有片源
   */
  private async disableCurrentSources(): Promise<void> {
    const sites = this.siteManager.getAllSites();
    for (const site of sites) {
      await this.siteManager.setSiteEnabled(site.key, false);
    }
  }

  /**
   * 测试线路URL
   * @param url 线路URL
   */
  public async testLineUrl(url: string): Promise<LineResult> {
    try {
      Logger.info(TAG, `Testing line URL: ${url}`);
      
      const startTime = Date.now();
      // 加载配置，使用默认缓存时间，不强制刷新
      const configContent = await this.configLoader.loadFromUrl(url, this.defaultCacheHours);
      const responseTime = Date.now() - startTime;
      
      // 解析片源
      const sites = this.configParser.parseSites(configContent);
      
      // 验证片源数量
      if (sites.length === 0) {
        return {
          success: false,
          message: '配置文件中未找到有效片源'
        };
      }
      
      return {
        success: true,
        message: `URL访问成功，发现${sites.length}个片源，响应时间${responseTime}ms`,
        data: { sites, responseTime }
      };
    } catch (error) {
      Logger.error(TAG, `Failed to test line URL: ${error}`);
      return {
        success: false,
        message: `URL测试失败: ${error instanceof Error ? error.message : String(error)}`
      };
    }
  }

  /**
   * 获取所有线路
   */
  public getAllLines(): LineItem[] {
    return Array.from(this.lines.values());
  }

  /**
   * 获取线路详情
   * @param lineId 线路ID
   */
  public getLine(lineId: string): LineItem | undefined {
    return this.lines.get(lineId);
  }

  /**
   * 获取当前使用的线路
   */
  public getCurrentLine(): LineItem | undefined {
    return Array.from(this.lines.values()).find(line => line.current);
  }

  /**
   * 检查是否有可用线路
   */
  public hasAvailableLines(): boolean {
    return Array.from(this.lines.values()).some(line => line.enabled);
  }

  /**
   * 生成线路ID
   * @param url 线路URL
   */
  private generateLineId(url: string): string {
    // 简单的URL哈希作为线路ID
    let hash = 0;
    for (let i = 0; i < url.length; i++) {
      const char = url.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return `line_${Math.abs(hash).toString(36)}`;
  }

  /**
   * 验证URL格式
   * @param url URL字符串
   */
  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      // 简单的URL格式检查作为备用
      return /^https?:\/\/.+/.test(url);
    }
  }

  /**
   * 规范化缓存时间
   * @param hours 缓存时间（小时）
   */
  private normalizeCacheTime(hours?: number): number {
    if (hours === undefined) {
      return this.defaultCacheHours;
    }
    return Math.max(this.minCacheHours, Math.min(this.maxCacheHours, Math.floor(hours)));
  }

  /**
   * 保存线路列表到持久化存储
   */
  private async saveLines(): Promise<void> {
    try {
      const lines = Array.from(this.lines.values());
      Logger.info(TAG, `Saving ${lines.length} lines`);
      
      // 批量保存线路
      await this.lineDao.saveAll(lines);
    } catch (error) {
      Logger.error(TAG, `Failed to save lines: ${error}`);
      // 保存失败不影响主要功能
    }
  }

  /**
   * 从持久化存储加载线路列表
   */
  private async loadLines(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading lines from storage');
      
      // 从数据库加载线路
      const lines = await this.lineDao.getAll();
      
      // 清空现有线路
      this.lines.clear();
      
      // 添加到内存
      lines.forEach(line => {
        this.lines.set(line.id, line);
      });
      
      Logger.info(TAG, `Loaded ${lines.length} lines from storage`);
    } catch (error) {
      Logger.error(TAG, `Failed to load lines: ${error}`);
    }
  }
}

export const lineManager = LineManager.getInstance();
