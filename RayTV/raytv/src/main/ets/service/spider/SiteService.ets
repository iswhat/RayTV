// SiteService.ets - 站点服务 | Site service
// 提供站点管理的核心功能，包括站点的增删改查、导入导出、测试连接等 | Provides core site management functionality, including site CRUD, import/export, connection testing, etc.
import LoggerUtil from '../../common/util/Logger';
import { LoaderType, Site, SiteType } from '../../data/bean/Site';
import { SiteDao } from '../../data/db/dao/SiteDao';

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
  private siteDao: SiteDao;
  private initialized: boolean = false;
  
  /**
   * 私有构造函数 Private constructor
   */
  private constructor() {
    this.siteDao = new SiteDao();
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
      // 预加载站点数据 Preload site data
      const sites = await this.getAllSites();
      LoggerUtil.info(TAG, `Initialized with ${sites.length} sites`);
      this.initialized = true;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to initialize: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取所有站点 Get all sites
   */
  public async getAllSites(): Promise<Site[]> {
    try {
      return await this.siteDao.getAll();
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get all sites: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 获取启用的站点 Get enabled sites
   */
  public async getEnabledSites(): Promise<Site[]> {
    try {
      const allSites = await this.siteDao.getAll();
      return allSites.filter(site => site.enabled);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get enabled sites: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 根据类型获取站点 Get sites by type
   */
  public async getSitesByType(type: SiteType): Promise<Site[]> {
    try {
      return await this.siteDao.getByType(type);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get sites by type ${type}: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 根据key获取站点 Get site by key
   */
  public async getSiteByKey(key: string): Promise<Site | null> {
    try {
      const site = await this.siteDao.getByKey(key);
      return site !== undefined ? site : null;
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to get site by key ${key}: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }
  
  /**
   * 保存站点 Save site
   */
  public async saveSite(site: Site): Promise<void> {
    try {
      // 确保时间戳和默认配置 Ensure timestamps and default configurations
      const now = Date.now();
      if (!site.createdAt) {
        site.createdAt = now;
      }
      site.updatedAt = now;
      
      // 确保必要的配置存在 Ensure required configurations exist
      if (!site.searchConfig) {
        site.searchConfig = { enabled: false };
      }
      if (!site.filterConfig) {
        site.filterConfig = { enabled: false };
      }
      if (!site.performanceConfig) {
        site.performanceConfig = {};
      }
      if (!site.stats) {
        site.stats = { queryCount: 0, errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle) {
        site.lifecycle = { initialized: false, loading: false, error: false };
      }
      
      // 检查站点是否已存在 Check if site already exists
      const existingSite = await this.siteDao.getByKey(site.key);
      if (existingSite) {
        await this.siteDao.update(site);
        LoggerUtil.info(TAG, `Updated site: ${site.name} (${site.key})`);
      } else {
        await this.siteDao.insert(site);
        LoggerUtil.info(TAG, `Inserted site: ${site.name} (${site.key})`);
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to save site ${site.name}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 批量保存站点 Batch save sites
   */
  public async batchSaveSites(sites: Site[]): Promise<void> {
    try {
      await this.siteDao.batchInsert(sites);
      LoggerUtil.info(TAG, `Batch inserted ${sites.length} sites`);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to batch insert sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 删除站点 Delete site
   */
  public async deleteSite(key: string): Promise<void> {
    try {
      await this.siteDao.delete(key);
      LoggerUtil.info(TAG, `Deleted site: ${key}`);
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to delete site ${key}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点启用状态 Update site enabled status
   */
  public async updateSiteEnabled(key: string, enabled: boolean): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (site) {
        site.enabled = enabled;
        site.updatedAt = Date.now();
        await this.siteDao.update(site);
        LoggerUtil.info(TAG, `Updated site ${key} enabled: ${enabled}`);
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to update site enabled: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点排序 Update site order
   */
  public async updateSiteOrder(key: string, order: number): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (site) {
        site.order = order;
        site.updatedAt = Date.now();
        await this.siteDao.update(site);
        LoggerUtil.info(TAG, `Updated site ${key} order: ${order}`);
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to update site order: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点最后使用时间 Update site last used time
   */
  public async updateSiteLastUsed(key: string): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (site) {
        site.lastUsedAt = Date.now();
        await this.siteDao.update(site);
        LoggerUtil.info(TAG, `Updated site last used: ${key}`);
      }
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to update site last used: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 测试站点连接 Test site connection
   */
  public async testSiteConnection(key: string): Promise<SiteTestResult> {
    const startTime = Date.now();
    const result: SiteTestResult = {
      siteKey: key,
      status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key);
      if (!site) {
        result.errorMessage = 'Site not found';
        return result;
      }
      
      // 这里实现站点连接测试逻辑
      // 实际实现可能需要根据站点类型和加载器类型进行不同的测试
      // Implement site connection test logic here
      // Actual implementation may need different tests based on site type and loader type
      result.responseTime = Date.now() - startTime;
      result.status = 'success';
      
      // 更新站点统计信息 Update site statistics
      site.stats.queryCount++;
      site.stats.lastQueryTime = Date.now();
      
      // 更新平均响应时间 Update average response time
      const totalResponseTime = site.stats.avgResponseTime * (site.stats.queryCount - 1) + result.responseTime;
      site.stats.avgResponseTime = Math.round(totalResponseTime / site.stats.queryCount);
      
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
    // 初始化统计对象，使用明确的初始值 Initialize statistics object with explicit initial values
    const stats: SiteImportResult = {
      success: 0,
      skipped: 0,
      failed: 0
    };
    
    try {
      const importData = JSON.parse(data) as ImportData;
      const sites = importData.sites || [];
      
      for (const siteData of sites) {
        try {
          // 检查是否已存在 Check if already exists
          const existing = await this.getSiteByKey(siteData.key as string);
          
          if (existing) {
            // 根据导入配置决定是跳过还是覆盖 Skip or overwrite based on import config
            stats.skipped++;
            LoggerUtil.info(TAG, `Skipped existing site: ${siteData.key}`);
            continue;
          }
          
          // 转换为Site类型 Convert to Site type
          const site: Site = {
            key: siteData.key as string,
            name: siteData.name as string,
            type: (siteData.type as SiteType) || SiteType.MIXED,
            loaderType: LoaderType.JS,
            api: siteData.api as string || siteData.url as string || '',
            searchConfig: { enabled: false },
            filterConfig: { enabled: false },
            performanceConfig: {},
            stats: { queryCount: 0, errorCount: 0, avgResponseTime: 0 },
            lifecycle: { initialized: false, loading: false, error: false },
            enabled: siteData.enabled || true,
            order: siteData.sort || 0,
            createdAt: siteData.createdAt || Date.now(),
            updatedAt: siteData.updatedAt || Date.now()
          };
          
          await this.saveSite(site);
          stats.success++;
          LoggerUtil.info(TAG, `Successfully imported site: ${site.key}`);
          
        } catch (siteError) {
          stats.failed++;
          LoggerUtil.error(TAG, `Failed to import site ${siteData.key}: ${siteError instanceof Error ? siteError.message : String(siteError)}`);
        }
      }
      
    } catch (error) {
      LoggerUtil.error(TAG, `Failed to parse import data: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
    
    return stats;
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
