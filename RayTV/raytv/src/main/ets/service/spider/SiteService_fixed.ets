// 提供站点管理的核心功能，包括站点的增删改查、导入导出、测试连接等 | Provides core site management functionality, including site CRUD, import/export, connection testing, etc.
import LoggerUtil from '../../common/util/Logger';
import { LoaderType, Site, SiteType } from '../../data/bean/Site';
import { SiteDao } from '../../data/db/dao/SiteDao';
import { Inject } from '../../common/di/Container';
import CacheService from '../cache/CacheService';
import HttpService from '../HttpService';

// 站点测试结果接口 | Site test result interface
export interface SiteTestResult {
  siteKey: string;
  status: 'success' | 'failed';
  responseTime: number;
  testTime: number;
  errorMessage?: string;
}

// 站点导入导出配置接口 | Site import export config interface
export interface SiteImportExportConfig {
  includeCredentials?: boolean;
  includeStats?: boolean;
  includeCustomConfig?: boolean;
  description?: string;
}

// 导出配置接口 | Export config interface
export interface ExportConfig {
  version: string;
  exportDate: string;
  sites: ExportSite[];
}

// 导出站点接口 | Export site interface
export interface ExportSite {
  id: string | null;
  key: string | null;
  name: string | null;
  url: string | null;
  type: string | null;
  status: string | null;
  sort: number | null;
  parser: string | null;
  headers: string | number | boolean | null;
  siteAuth: string | number | boolean | null;
  customCode: string | null;
  stats: string | number | boolean | null;
}

// 导入站点数据接口 | Import site data interface
export interface ImportSite {
  key?: string;
  name?: string;
  type?: string;
  url?: string;
  api?: string;
  enabled?: boolean;
  sort?: number;
  headers?: string | number | boolean | null;
  siteAuth?: string | number | boolean | null;
  customCode?: string | null;
  stats?: string | number | boolean | null;
  createdAt?: number;
  updatedAt?: number;
}

// 导入数据接口 | Import data interface
export interface ImportData {
  sites?: ImportSite[];
}

// 站点内容项接口 | Site content item interface
export interface SiteContentItem {
  id: string;
  title: string;
  url: string;
  cover?: string;
  description?: string;
  duration?: number;
  views?: number;
  date?: string;
  category?: string;
}

const TAG = 'SiteService';

/**
 * 站点导入结果统计接口 Site import result statistics interface
 */
export interface SiteImportResult {
  success: number;
  skipped: number;
  failed: number;
}

/**
 * 站点服务接口 Site service interface
 */
export interface ISiteService {
  /**
   * 初始化站点服务 Initialize site service
   */
  initialize(): Promise<void>;
  
  /**
   * 获取所有站点 Get all sites
   * @returns 站点列表 Site list
   */
  getAllSites(): Promise<Site[]>;
  
  /**
   * 获取启用的站点 Get enabled sites
   * @returns 启用的站点列表 Enabled site list
   */
  getEnabledSites(): Promise<Site[]>;
  
  /**
   * 根据类型获取站点 Get sites by type
   * @param type 站点类型 Site type
   * @returns 站点列表 Site list
   */
  getSitesByType(type: SiteType): Promise<Site[]>;
  
  /**
   * 根据key获取站点 Get site by key
   * @param key 站点唯一标识 Site unique identifier
   * @returns 站点信息 Site information
   */
  getSiteByKey(key: string): Promise<Site | null>;
  
  /**
   * 保存站点（新增或更新）Save site (add or update)
   * @param site 站点信息 Site information
   */
  saveSite(site: Site): Promise<void>;
  
  /**
   * 批量保存站点 Batch save sites
   * @param sites 站点列表 Site list
   */
  batchSaveSites(sites: Site[]): Promise<void>;
  
  /**
   * 删除站点 Delete site
   * @param key 站点唯一标识 Site unique identifier
   */
  deleteSite(key: string): Promise<void>;
  
  /**
   * 更新站点启用状态 Update site enabled status
   * @param key 站点唯一标识 Site unique identifier
   * @param enabled 是否启用 Whether to enable
   */
  updateSiteEnabled(key: string, enabled: boolean): Promise<void>;
  
  /**
   * 更新站点排序 Update site order
   * @param key 站点唯一标识 Site unique identifier
   * @param order 排序权重 Order weight
   */
  updateSiteOrder(key: string, order: number): Promise<void>;
  
  /**
   * 更新站点最后使用时间 Update site last used time
   * @param key 站点唯一标识 Site unique identifier
   */
  updateSiteLastUsed(key: string): Promise<void>;
  
  /**
   * 测试站点连接 Test site connection
   * @param key 站点唯一标识 Site unique identifier
   * @returns 测试结果 Test result
   */
  testSiteConnection(key: string): Promise<SiteTestResult>;
  
  /**
   * 导出站点配置 Export site config
   * @param config 导出配置 Export config
   * @param siteKeys 可选的站点key列表，不提供则导出所有 Optional site key list, export all if not provided
   * @returns 导出的配置字符串 Exported config string
   */
  exportSites(config?: SiteImportExportConfig, siteKeys?: string[]): Promise<string>;
  
  /**
   * 导入站点配置 Import site config
   * @param data 配置数据 Config data
   * @param config 导入配置 Import config
   * @returns 导入结果统计 Import result statistics
   */
  importSites(data: string, config?: SiteImportExportConfig): Promise<SiteImportResult>;
  
  /**
   * 清空所有站点 Clear all sites
   */
  clearAllSites(): Promise<void>;
}

/**
 * 站点服务实现类 Site service implementation class
 */
export class SiteService implements ISiteService {
  private static instance: SiteService | null = null;
  
  @Inject('SiteDao')
  private siteDao: SiteDao;
  
  private cacheService: CacheService = CacheService.getInstance();
  private initialized: boolean = false;
  
  /**
   * 私有构造函数 Private constructor
   */
  private constructor() {
  }
  
  /**
   * 获取单例实例 Get singleton instance
   * @returns 站点服务实例 Site service instance
   */
  public static getInstance(): SiteService {
    if (!SiteService.instance) {
      SiteService.instance = new SiteService();
    }
    return SiteService.instance;
  }
  
  /**
   * 初始化站点服务 Initialize site service
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }
    
    try {
      // 初始化数据库 Initialize database
      await this.siteDao.initialize();
      
      // 初始化缓存 Initialize cache
      await this.cacheService.initialize();
      
      this.initialized = true;
      LoggerUtil.info(TAG, 'Site service initialized successfully');
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to initialize site service: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取所有站点 Get all sites
   * @returns 站点列表 Site list
   */
  public async getAllSites(): Promise<Site[]> {
    try {
      // 先从缓存获取 Try to get from cache first
      const cachedSites = await this.cacheService.get<Site[]>('sites:all');
      if (cachedSites) {
        return cachedSites;
      }
      
      // 从数据库获取 Get from database
      const sites = await this.siteDao.getAllSites();
      
      // 缓存结果 Cache the result
      await this.cacheService.set('sites:all', sites, 300); // 缓存5分钟 Cache for 5 minutes
      
      return sites;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get all sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取启用的站点 Get enabled sites
   * @returns 启用的站点列表 Enabled site list
   */
  public async getEnabledSites(): Promise<Site[]> {
    try {
      const allSites = await this.getAllSites();
      return allSites.filter(site => site.enabled);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get enabled sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 根据类型获取站点 Get sites by type
   * @param type 站点类型 Site type
   * @returns 站点列表 Site list
   */
  public async getSitesByType(type: SiteType): Promise<Site[]> {
    try {
      const allSites = await this.getAllSites();
      return allSites.filter(site => site.type === type);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get sites by type ${type}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 根据key获取站点 Get site by key
   * @param key 站点唯一标识 Site unique identifier
   * @returns 站点信息 Site information
   */
  public async getSiteByKey(key: string): Promise<Site | null> {
    try {
      // 先从缓存获取 Try to get from cache first
      const cacheKey = `site:${key}`;
      const cachedSite = await this.cacheService.get<Site>(cacheKey);
      if (cachedSite) {
        return cachedSite;
      }
      
      // 从数据库获取 Get from database
      const site = await this.siteDao.getSiteByKey(key);
      
      // 缓存结果 Cache the result
      if (site) {
        await this.cacheService.set(cacheKey, site, 600); // 缓存10分钟 Cache for 10 minutes
      }
      
      return site;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get site by key ${key}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 保存站点（新增或更新）Save site (add or update)
   * @param site 站点信息 Site information
   */
  public async saveSite(site: Site): Promise<void> {
    try {
      // 设置时间戳 Set timestamps
      const now = Date.now();
      if (!site.createdAt) {
        site.createdAt = now;
      }
      site.updatedAt = now;
      
      // 保存到数据库 Save to database
      await this.siteDao.saveSite(site);
      
      // 清除相关缓存 Clear related cache
      await this.cacheService.remove('sites:all');
      await this.cacheService.remove(`site:${site.key}`);
      
      LoggerUtil.info(TAG, `Site ${site.key} saved successfully`);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to save site ${site.key}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 批量保存站点 Batch save sites
   * @param sites 站点列表 Site list
   */
  public async batchSaveSites(sites: Site[]): Promise<void> {
    try {
      const now = Date.now();
      for (const site of sites) {
        if (!site.createdAt) {
          site.createdAt = now;
        }
        site.updatedAt = now;
      }
      
      await this.siteDao.batchSaveSites(sites);
      
      // 清除所有站点缓存 Clear all sites cache
      await this.cacheService.remove('sites:all');
      
      LoggerUtil.info(TAG, `Batch saved ${sites.length} sites successfully`);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to batch save sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 删除站点 Delete site
   * @param key 站点唯一标识 Site unique identifier
   */
  public async deleteSite(key: string): Promise<void> {
    try {
      await this.siteDao.deleteSite(key);
      
      // 清除相关缓存 Clear related cache
      await this.cacheService.remove('sites:all');
      await this.cacheService.remove(`site:${key}`);
      
      LoggerUtil.info(TAG, `Site ${key} deleted successfully`);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to delete site ${key}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点启用状态 Update site enabled status
   * @param key 站点唯一标识 Site unique identifier
   * @param enabled 是否启用 Whether to enable
   */
  public async updateSiteEnabled(key: string, enabled: boolean): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (!site) {
        throw new Error(`Site ${key} not found`);
      }
      
      site.enabled = enabled;
      site.updatedAt = Date.now();
      
      await this.saveSite(site);
      
      LoggerUtil.info(TAG, `Site ${key} enabled status updated to ${enabled}`);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to update site ${key} enabled status: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点排序 Update site order
   * @param key 站点唯一标识 Site unique identifier
   * @param order 排序权重 Order weight
   */
  public async updateSiteOrder(key: string, order: number): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (!site) {
        throw new Error(`Site ${key} not found`);
      }
      
      site.order = order;
      site.updatedAt = Date.now();
      
      await this.saveSite(site);
      
      LoggerUtil.info(TAG, `Site ${key} order updated to ${order}`);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to update site ${key} order: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点最后使用时间 Update site last used time
   * @param key 站点唯一标识 Site unique identifier
   */
  public async updateSiteLastUsed(key: string): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (!site) {
        throw new Error(`Site ${key} not found`);
      }
      
      site.lastUsed = Date.now();
      site.updatedAt = site.lastUsed;
      
      await this.saveSite(site);
      
      LoggerUtil.info(TAG, `Site ${key} last used time updated`);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to update site ${key} last used time: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 测试站点连接 Test site connection
   * @param key 站点唯一标识 Site unique identifier
   * @returns 测试结果 Test result
   */
  public async testSiteConnection(key: string): Promise<SiteTestResult> {
    const startTime = Date.now();
    const result: SiteTestResult = {
      siteKey: key,
      status: 'failed',
      responseTime: 0,
      testTime: startTime,
      errorMessage: ''
    };
    
    try {
      // 1. 获取站点信息 Get site information
      const site = await this.getSiteByKey(key);
      if (!site) {
        result.errorMessage = `Site ${key} not found`;
        return result;
      }
      
      // 2. 发送HTTP请求测试连接 Send HTTP request to test connection
      try {
        const httpService = HttpService.getInstance();
        
        // 发送实际的HTTP请求 Send actual HTTP request
        const response = await httpService.get(site.api, {
          timeout: 10000,
          cache: false
        });
        
        // 检查响应状态 Check response status
        if (response.status >= 200 && response.status < 300) {
          result.responseTime = Date.now() - startTime;
          result.status = 'success';
        } else {
          result.status = 'failed';
          result.errorMessage = `HTTP error: ${response.status}`;
          result.responseTime = Date.now() - startTime;
          
          // 更新站点错误统计 Update site error statistics
          site.stats.errorCount++;
          site.stats.lastErrorTime = Date.now();
          site.stats.lastErrorMessage = result.errorMessage;
          await this.saveSite(site);
          
          return result;
        }
        
      } catch (httpError) {
        result.status = 'failed';
        result.errorMessage = `Connection error: ${httpError instanceof Error ? httpError.message : 'Unknown error'}`;
        result.responseTime = Date.now() - startTime;
        
        // 更新站点错误统计 Update site error statistics
        site.stats.errorCount++;
        site.stats.lastErrorTime = Date.now();
        site.stats.lastErrorMessage = result.errorMessage;
        await this.saveSite(site);
        
        return result;
      }
      
      // 3. 测试站点API响应 Test site API response
      try {
        // 根据站点类型进行不同的API测试 Test API based on site type
        if (site.type === 'VIDEO' || site.type === 'MIXED') {
          // 测试视频站点API Test video site API
          const httpService = HttpService.getInstance();
          
          // 尝试获取首页数据 Try to get home page data
          const homeResponse = await httpService.get(`${site.api}/home`, {
            timeout: 10000,
            cache: false
          });
          
          if (homeResponse.status >= 200 && homeResponse.status < 300) {
            // API响应正常 API response normal
          } else {
            throw new Error(`API error: ${homeResponse.status}`);
          }
        } else if (site.type === 'LIVE') {
          // 测试直播站点API Test live site API
          const httpService = HttpService.getInstance();
          
          // 尝试获取频道列表 Try to get channel list
          const channelResponse = await httpService.get(`${site.api}/channels`, {
            timeout: 10000,
            cache: false
          });
          
          if (channelResponse.status >= 200 && channelResponse.status < 300) {
            // API响应正常 API response normal
          } else {
            throw new Error(`API error: ${channelResponse.status}`);
          }
        }
        
      } catch (apiError) {
        result.status = 'failed';
        result.errorMessage = `API error: ${apiError instanceof Error ? apiError.message : 'Unknown error'}`;
        result.responseTime = Date.now() - startTime;
        
        // 更新站点错误统计 Update site error statistics
        site.stats.errorCount++;
        site.stats.lastErrorTime = Date.now();
        site.stats.lastErrorMessage = result.errorMessage;
        await this.saveSite(site);
        
        return result;
      }
      
      // 4. 更新站点统计信息 Update site statistics
      site.stats.queryCount++;
      site.stats.lastQueryTime = Date.now();
      
      // 更新平均响应时间 Update average response time
      const totalResponseTime = site.stats.avgResponseTime * (site.stats.queryCount - 1) + result.responseTime;
      site.stats.avgResponseTime = Math.round(totalResponseTime / site.stats.queryCount);
      
      // 更新站点状态为正常 Update site status to normal
      site.lifecycle.error = false;
      site.lifecycle.initialized = true;
      
      await this.saveSite(site);
      
    } catch (error) {
      result.status = 'failed';
      result.errorMessage = error instanceof Error ? error.message : 'Unknown error';
      result.responseTime = Date.now() - startTime;
      
      // 更新站点错误统计 Update site error statistics
      try {
        const site = await this.getSiteByKey(key);
        if (site) {
          site.stats.errorCount++;
          site.stats.lastErrorTime = Date.now();
          site.stats.lastErrorMessage = result.errorMessage;
          site.lifecycle.error = true;
          await this.saveSite(site);
        }
      } catch (updateError) {
        LoggerUtil.error(TAG, `Failed to update error stats: ${updateError instanceof Error ? updateError.message : String(updateError)}`);
      }
    }
    
    return result;
  }
  
  /**
   * 导出站点配置 Export site config
   */
  public async exportSites(config?: SiteImportExportConfig, siteKeys?: string[]): Promise<string> {
    try {
      let sites: Site[];
      
      if (siteKeys && siteKeys.length > 0) {
        sites = [];
        for (const key of siteKeys) {
          const site = await this.getSiteByKey(key);
          if (site) {
            sites.push(site);
          }
        }
      } else {
        sites = await this.getAllSites();
      }
      
      // 根据配置处理导出数据 Process export data according to config
      const exportData = sites.map(site => {
        // 手动复制属性，不使用Object.assign
        // Manually copy properties, not using Object.assign
        const exportSite: ExportSite = {
          id: null, // Site接口没有id属性，使用key作为唯一标识 Site interface doesn't have id property, use key as unique identifier
          key: site.key || null,
          name: site.name || null,
          url: site.api || null, // Site接口使用api属性，而不是url Site interface uses api property, not url
          type: site.type || null,
          status: site.enabled ? 'enabled' : 'disabled', // Site接口使用enabled属性，而不是status Site interface uses enabled property, not status
          sort: site.order || null, // Site接口使用order属性，而不是sort Site interface uses order property, not sort
          parser: null, // Site接口没有parser属性 Site interface doesn't have parser property
          headers: null,
          siteAuth: null,
          customCode: site.customCode || null,
          stats: null
        };
        
        // 不输出敏感信息 Don't output sensitive information
        if (config?.includeCredentials) {
          exportSite.siteAuth = site.siteAuth ? JSON.stringify(site.siteAuth) : null;
          exportSite.headers = site.headers ? JSON.stringify(site.headers) : null;
        }
        
        // 是否导出统计信息 Whether to export statistics
        if (config?.includeStats) {
          exportSite.stats = site.stats ? JSON.stringify(site.stats) : null;
        }
        
        // 是否导出自定义配置 Whether to export custom config
        if (!config?.includeCustomConfig) {
          exportSite.customCode = null;
        }
        
        return exportSite;
      });
      
      // 使用已经在文件开头定义的ExportConfig接口
      // Use ExportConfig interface defined at the beginning of the file
      const exportConfig: ExportConfig = {
        version: '1.0',
        exportDate: new Date().toISOString(),
        sites: exportData
      };
      
      return JSON.stringify(exportConfig, null, 2);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to export sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 导入站点配置 Import site config
   */
  public async importSites(data: string, config?: SiteImportExportConfig): Promise<SiteImportResult> {
    const result: SiteImportResult = {
      success: 0,
      skipped: 0,
      failed: 0
    };
    
    try {
      const importData: ImportData = JSON.parse(data);
      
      if (!importData.sites || !Array.isArray(importData.sites)) {
        throw new Error('Invalid import data format');
      }
      
      for (const importSite of importData.sites) {
        try {
          // 检查站点是否已存在 Check if site already exists
          const existingSite = await this.getSiteByKey(importSite.key || '');
          
          if (existingSite && !config?.includeCustomConfig) {
            // 跳过已存在的站点 Skip existing sites
            result.skipped++;
            LoggerUtil.info(TAG, `Skipped existing site: ${importSite.key}`);
            continue;
          }
          
          // 创建或更新站点 Create or update site
          const site: Site = {
            key: importSite.key || '',
            name: importSite.name || '',
            type: (importSite.type as SiteType) || SiteType.VIDEO,
            api: importSite.api || importSite.url || '',
            enabled: importSite.enabled !== undefined ? importSite.enabled : true,
            order: importSite.sort || 0,
            headers: importSite.headers ? JSON.parse(importSite.headers as string) : {},
            siteAuth: importSite.siteAuth ? JSON.parse(importSite.siteAuth as string) : {},
            customCode: importSite.customCode || '',
            stats: importSite.stats ? JSON.parse(importSite.stats as string) : {
              queryCount: 0,
              errorCount: 0,
              avgResponseTime: 0,
              lastQueryTime: 0,
              lastErrorTime: 0,
              lastErrorMessage: ''
            },
            lastUsed: importSite.updatedAt || Date.now(),
            createdAt: importSite.createdAt || Date.now(),
            updatedAt: importSite.updatedAt || Date.now(),
            lifecycle: {
              initialized: false,
              error: false
            },
            loaderType: LoaderType.JS
          };
          
          await this.saveSite(site);
          result.success++;
          LoggerUtil.info(TAG, `Imported site: ${site.key}`);
          
        } catch (siteError) {
          result.failed++;
          LoggerUtil.error(TAG, `Failed to import site ${importSite.key}: ${siteError instanceof Error ? siteError.message : String(siteError)}`);
        }
      }
      
      LoggerUtil.info(TAG, `Import completed - Success: ${result.success}, Skipped: ${result.skipped}, Failed: ${result.failed}`);
      return result;
      
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to import sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取站点推荐内容 Get site recommendations
   */
  private async getSiteRecommendations(site: Site): Promise<SiteContentItem[]> {
    try {
      // 检查站点API是否配置 | Check if site API is configured
      if (!site.api) {
        throw new Error('Site API not configured');
      }
      
      const httpService = HttpService.getInstance();
      
      // 发送HTTP请求获取推荐内容 Send HTTP request to get recommendations
      const response = await httpService.get(`${site.api}/recommendations`, {
        timeout: 10000,
        cache: true
      });
      
      if (response.status >= 200 && response.status < 300) {
        // 解析响应数据 Parse response data
        const data = JSON.parse(response.data);
        if (Array.isArray(data)) {
          return data as SiteContentItem[];
        }
        return [];
      } else {
        throw new Error(`HTTP error: ${response.status}`);
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get recommendations from ${site.name}: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 获取站点热门内容 Get site popular content
   */
  private async getSitePopularContent(site: Site): Promise<SiteContentItem[]> {
    try {
      // 检查站点API是否配置 | Check if site API is configured
      if (!site.api) {
        throw new Error('Site API not configured');
      }
      
      const httpService = HttpService.getInstance();
      
      // 发送HTTP请求获取热门内容 Send HTTP request to get popular content
      const response = await httpService.get(`${site.api}/popular`, {
        timeout: 10000,
        cache: true
      });
      
      if (response.status >= 200 && response.status < 300) {
        // 解析响应数据 Parse response data
        const data = JSON.parse(response.data);
        if (Array.isArray(data)) {
          return data as SiteContentItem[];
        }
        return [];
      } else {
        throw new Error(`HTTP error: ${response.status}`);
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get popular content from ${site.name}: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 获取站点最新内容 Get site new content
   */
  private async getSiteNewContent(site: Site): Promise<SiteContentItem[]> {
    try {
      // 检查站点API是否配置 | Check if site API is configured
      if (!site.api) {
        throw new Error('Site API not configured');
      }
      
      const httpService = HttpService.getInstance();
      
      // 发送HTTP请求获取最新内容 Send HTTP request to get new content
      const response = await httpService.get(`${site.api}/new`, {
        timeout: 10000,
        cache: true
      });
      
      if (response.status >= 200 && response.status < 300) {
        // 解析响应数据 Parse response data
        const data = JSON.parse(response.data);
        if (Array.isArray(data)) {
          return data as SiteContentItem[];
        }
        return [];
      } else {
        throw new Error(`HTTP error: ${response.status}`);
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get new content from ${site.name}: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 清空所有站点 Clear all sites
   */
  public async clearAllSites(): Promise<void> {
    try {
      await this.siteDao.deleteAll();
      LoggerUtil.info(TAG, 'Cleared all sites');
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to clear all sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
}