import Logger from '../../../common/util/Logger';
import { Site, SiteType, LoaderType } from '../../data/bean/Site';
import { SiteDao } from '../../data/db/dao/SiteDao';
import JsonUtil from '../../../common/util/JsonUtil';

// 站点测试结果接口
export interface SiteTestResult {
  siteKey: string;
  status: 'success' | 'failed';
  responseTime: number;
  testTime: number;
  errorMessage?: string;
}

// 站点导入导出配置接口
export interface SiteImportExportConfig {
  includeCredentials?: boolean;
  includeStats?: boolean;
  includeCustomConfig?: boolean;
  description?: string;
}

// 导出配置接口
export interface ExportConfig {
  version: string;
  exportDate: string;
  sites: ExportSite[];
}

// 导出站点接口
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

const TAG = 'SiteService';

/**
 * 站点导入结果统计接口
 */
export interface SiteImportResult {
  success: number;
  skipped: number;
  failed: number;
}

/**
 * 站点服务接口
 */
export interface ISiteService {
  /**
   * 初始化站点服务
   */
  initialize(): Promise<void>;
  
  /**
   * 获取所有站点
   * @returns 站点列表
   */
  getAllSites(): Promise<Site[]>;
  
  /**
   * 获取启用的站点
   * @returns 启用的站点列表
   */
  getEnabledSites(): Promise<Site[]>;
  
  /**
   * 根据类型获取站点
   * @param type 站点类型
   * @returns 站点列表
   */
  getSitesByType(type: SiteType): Promise<Site[]>;
  
  /**
   * 根据key获取站点
   * @param key 站点唯一标识
   * @returns 站点信息
   */
  getSiteByKey(key: string): Promise<Site | null>;
  
  /**
   * 保存站点（新增或更新）
   * @param site 站点信息
   */
  saveSite(site: Site): Promise<void>;
  
  /**
   * 批量保存站点
   * @param sites 站点列表
   */
  batchSaveSites(sites: Site[]): Promise<void>;
  
  /**
   * 删除站点
   * @param key 站点唯一标识
   */
  deleteSite(key: string): Promise<void>;
  
  /**
   * 更新站点启用状态
   * @param key 站点唯一标识
   * @param enabled 是否启用
   */
  updateSiteEnabled(key: string, enabled: boolean): Promise<void>;
  
  /**
   * 更新站点排序
   * @param key 站点唯一标识
   * @param order 排序权重
   */
  updateSiteOrder(key: string, order: number): Promise<void>;
  
  /**
   * 更新站点最后使用时间
   * @param key 站点唯一标识
   */
  updateSiteLastUsed(key: string): Promise<void>;
  
  /**
   * 测试站点连接
   * @param key 站点唯一标识
   * @returns 测试结果
   */
  testSiteConnection(key: string): Promise<SiteTestResult>;
  
  /**
   * 导出站点配置
   * @param config 导出配置
   * @param siteKeys 可选的站点key列表，不提供则导出所有
   * @returns 导出的配置字符串
   */
  exportSites(config?: SiteImportExportConfig, siteKeys?: string[]): Promise<string>;
  
  /**
   * 导入站点配置
   * @param data 配置数据
   * @param config 导入配置
   * @returns 导入结果统计
   */
  importSites(data: string, config?: SiteImportExportConfig): Promise<SiteImportResult>;
  
  /**
   * 清空所有站点
   */
  clearAllSites(): Promise<void>;
}

/**
 * 站点服务实现类
 */
export class SiteService implements ISiteService {
  private static instance: SiteService | null = null;
  private siteDao: SiteDao;
  private initialized: boolean = false;
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.siteDao = new SiteDao();
  }
  
  /**
   * 获取单例实例
   * @returns 站点服务实例
   */
  public static getInstance(): SiteService {
    if (!SiteService.instance) {
      SiteService.instance = new SiteService();
    }
    return SiteService.instance;
  }
  
  /**
   * 初始化站点服务
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }
    
    try {
      // 预加载站点数据
      const sites = await this.getAllSites();
      Logger.info(TAG, `Initialized with ${sites.length} sites`);
      this.initialized = true;
    } catch (error) {
      Logger.error(TAG, `Failed to initialize: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取所有站点
   */
  public async getAllSites(): Promise<Site[]> {
    try {
      return await this.siteDao.getAll();
    } catch (error) {
      Logger.error(TAG, `Failed to get all sites: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 获取启用的站点
   */
  public async getEnabledSites(): Promise<Site[]> {
    try {
      return await this.siteDao.getEnabled();
    } catch (error) {
      Logger.error(TAG, `Failed to get enabled sites: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 根据类型获取站点
   */
  public async getSitesByType(type: SiteType): Promise<Site[]> {
    try {
      return await this.siteDao.getByType(type);
    } catch (error) {
      Logger.error(TAG, `Failed to get sites by type ${type}: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 根据key获取站点
   */
  public async getSiteByKey(key: string): Promise<Site | null> {
    try {
      return await this.siteDao.getByKey(key);
    } catch (error) {
      Logger.error(TAG, `Failed to get site by key ${key}: ${JSON.stringify(error)}`);
      return null;
    }
  }
  
  /**
   * 保存站点
   */
  public async saveSite(site: Site): Promise<void> {
    try {
      // 确保时间戳正确设置
      const now = Date.now();
      if (!site.createdAt) {
        site.createdAt = now;
      }
      site.updatedAt = now;
      
      // 确保必要的配置存在
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
      
      // 检查站点是否已存在
      const exists = await this.siteDao.exists(site.key);
      if (exists) {
        await this.siteDao.update(site);
        Logger.info(TAG, `Updated site: ${site.name} (${site.key})`);
      } else {
        await this.siteDao.insert(site);
        Logger.info(TAG, `Inserted site: ${site.name} (${site.key})`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save site ${site.name}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 批量保存站点
   */
  public async batchSaveSites(sites: Site[]): Promise<void> {
    try {
      await this.siteDao.batchInsert(sites);
      Logger.info(TAG, `Batch inserted ${sites.length} sites`);
    } catch (error) {
      Logger.error(TAG, `Failed to batch insert sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 删除站点
   */
  public async deleteSite(key: string): Promise<void> {
    try {
      await this.siteDao.delete(key);
      Logger.info(TAG, `Deleted site: ${key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete site ${key}: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点启用状态
   */
  public async updateSiteEnabled(key: string, enabled: boolean): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (site) {
        site.enabled = enabled;
        site.updatedAt = Date.now();
        await this.siteDao.save(site);
        Logger.info(TAG, `Updated site ${key} enabled: ${enabled}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to update site enabled: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点排序
   */
  public async updateSiteOrder(key: string, order: number): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (site) {
        site.order = order;
        site.updatedAt = Date.now();
        await this.siteDao.save(site);
        Logger.info(TAG, `Updated site ${key} order: ${order}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to update site order: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点最后使用时间
   */
  public async updateSiteLastUsed(key: string): Promise<void> {
    try {
      await this.siteDao.updateLastUsed(key);
      Logger.info(TAG, `Updated site last used: ${key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update site last used: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 测试站点连接
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
      result.responseTime = Date.now() - startTime;
      result.status = 'success';
      
      // 更新站点统计信息
      site.stats.queryCount++;
      site.stats.lastQueryTime = Date.now();
      
      // 更新平均响应时间
      const totalResponseTime = site.stats.avgResponseTime * (site.stats.queryCount - 1) + result.responseTime;
      site.stats.avgResponseTime = Math.round(totalResponseTime / site.stats.queryCount);
      
      await this.saveSite(site);
      
    } catch (error) {
      result.status = 'failed';
      result.errorMessage = error instanceof Error ? error.message : 'Unknown error';
      result.responseTime = Date.now() - startTime;
      
      // 更新站点错误统计
      try {
        const site = await this.getSiteByKey(key);
        if (site) {
          site.stats.errorCount++;
          site.stats.lastErrorTime = Date.now();
          site.stats.lastErrorMessage = result.errorMessage;
          await this.saveSite(site);
        }
      } catch (updateError) {
        Logger.error(TAG, `Failed to update error stats: ${JSON.stringify(updateError)}`);
      }
    }
    
    return result;
  }
  
  /**
   * 导出站点配置
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
      
      // 根据配置处理导出数据
      const exportData = sites.map(site => {
        // 手动复制属性，不使用Object.assign
        const exportSite: ExportSite = {
          id: null, // Site接口没有id属性，使用key作为唯一标识
          key: site.key || null,
          name: site.name || null,
          url: site.api || null, // Site接口使用api属性，而不是url
          type: site.type || null,
          status: site.enabled ? 'enabled' : 'disabled', // Site接口使用enabled属性，而不是status
          sort: site.order || null, // Site接口使用order属性，而不是sort
          parser: null, // Site接口没有parser属性
          headers: null,
          siteAuth: null,
          customCode: site.customCode || null,
          stats: null
        };
        
        // 不导出敏感信息
        if (config?.includeCredentials) {
          exportSite.siteAuth = site.siteAuth ? JSON.stringify(site.siteAuth) : null;
          exportSite.headers = site.headers ? JSON.stringify(site.headers) : null;
        }
        
        // 是否导出统计信息
        if (config?.includeStats) {
          exportSite.stats = site.stats ? JSON.stringify(site.stats) : null;
        }
        
        // 是否导出自定义配置
        if (!config?.includeCustomConfig) {
          exportSite.customCode = null;
        }
        
        return exportSite;
      });
      
      // 使用已在文件开头定义的ExportConfig接口
      const exportConfig: ExportConfig = {
        version: '1.0',
        exportDate: new Date().toISOString(),
        sites: exportData
      };
      
      return JsonUtil.stringify(exportConfig, null, 2);
    } catch (error) {
      Logger.error(TAG, `Failed to export sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 导入站点配置
   */
  public async importSites(data: string, config?: SiteImportExportConfig): Promise<SiteImportResult> {
    // 初始化统计对象，使用明确的初始值
    const stats: SiteImportResult = {
      success: 0,
      skipped: 0,
      failed: 0
    };
    
    try {
      /**
       * 导入站点数据接口
       */
      interface ImportSite {
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

      interface ImportData {
        sites?: ImportSite[];
      }
      
      const importData = JsonUtil.parse(data) as ImportData;
      const sites = importData.sites || [];
      
      for (const siteData of sites) {
        try {
          // 检查是否已存在
          const existing = await this.getSiteByKey(siteData.key as string);
          
          if (existing) {
            // 根据导入配置决定是跳过还是覆盖
            stats.skipped++;
            Logger.info(TAG, `Skipped existing site: ${siteData.key}`);
            continue;
          }
          
          // 转换为Site类型
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
          Logger.info(TAG, `Successfully imported site: ${site.key}`);
          
        } catch (siteError) {
          stats.failed++;
          Logger.error(TAG, `Failed to import site ${siteData.key}: ${JSON.stringify(siteError)}`);
        }
      }
      
    } catch (error) {
      Logger.error(TAG, `Failed to parse import data: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
    
    return stats;
  }
  
  /**
   * 清空所有站点
   */
  public async clearAllSites(): Promise<void> {
    try {
      await this.siteDao.clearAll();
      Logger.info(TAG, 'Cleared all sites');
    } catch (error) {
      Logger.error(TAG, `Failed to clear all sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
}