import Logger from '../../../common/util/Logger';
import { Site, SiteType } from '../../data/bean/Site';
import { SiteDao } from '../db/dao/SiteDao';
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

const TAG = 'SiteService';

/**
 * 站点服务接口
 */
export interface ISiteService {
  /**
   * 初始化站点服�?
   */
  initialize(): Promise<void>;
  
  /**
   * 获取所有站�?
   * @returns 站点列表
   */
  getAllSites(): Promise<Site[]>;
  
  /**
   * 获取启用的站�?
   * @returns 启用的站点列�?
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
   * 保存站点（新增或更新�?
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
   * 更新站点启用状�?
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
   * 更新站点最后使用时�?
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
   * @param siteKeys 可选的站点key列表，不提供则导出所�?
   * @returns 导出的配置字符串
   */
  exportSites(config?: SiteImportExportConfig, siteKeys?: string[]): Promise<string>;
  
  /**
   * 导入站点配置
   * @param data 配置数据
   * @param config 导入配置
   * @returns 导入结果统计
   */
  importSites(data: string, config?: SiteImportExportConfig): Promise<{success: number, skipped: number, failed: number}>;
  
  /**
   * 清空所有站�?
   */
  clearAllSites(): Promise<void>;
}

/**
 * 站点服务实现�?
 */
export class SiteService implements ISiteService {
  private static instance: SiteService | null = null;
  private siteDao: SiteDao;
  private initialized: boolean = false;
  
  /**
   * 私有构造函�?
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
   * 初始化站点服�?
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }
    
    try {
      // 预加载站点数�?
      const sites = await this.getAllSites();
      Logger.info(TAG, `Initialized with ${sites.length} sites`);
      this.initialized = true;
    } catch (error) {
      Logger.error(TAG, `Failed to initialize: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 获取所有站�?
   */
  public async getAllSites(): Promise<Site[]> {
    try {
      return await this.siteDao.getAll();
    } catch (error) {
      Logger.error(TAG, `Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error instanceof Error ? `Failed to get all sites: ${JSON.stringify(error : new Error(String(`Failed to get all sites: ${JSON.stringify(error)))))))}`);
      return [];
    }
  }
  
  /**
   * 获取启用的站�?
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
      Logger.error(TAG, `Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error instanceof Error ? `Failed to get sites by type ${type}: ${JSON.stringify(error : new Error(String(`Failed to get sites by type ${type}: ${JSON.stringify(error)))))))}`);
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
      // 确保时间戳正确设�?
      const now = Date.now();
      if (!site.createdAt) {
        site.createdAt = now;
      }
      site.updatedAt = now;
      
      // 确保必要的配置存�?
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
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle instanceof Error ? errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle : new Error(String(errorCount: 0, avgResponseTime: 0 };
      }
      if (!site.lifecycle))))))) {
        site.lifecycle = { initialized: false, loading: false, error: false };
      }
      
      await this.siteDao.save(site);
      Logger.info(TAG, `Saved site: ${site.name} (${site.key})`);
    } catch (error) {
      Logger.error(TAG, `Failed to save site ${site.name}: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 批量保存站点
   */
  public async batchSaveSites(sites: Site[]): Promise<void> {
    try {
      await this.siteDao.batchSave(sites);
      Logger.info(TAG, `Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites` instanceof Error ? `Batch saved ${sites.length} sites` : new Error(String(`Batch saved ${sites.length} sites`)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to batch save sites: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 删除站点
   */
  public async deleteSite(key: string): Promise<void> {
    try {
      await this.siteDao.delete(key);
      Logger.info(TAG, `Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` : new Error(String(`Deleted site: ${key}` instanceof Error ? `Deleted site: ${key}` : new Error(String(`Deleted site: ${key}`)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to delete site ${key}: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 更新站点启用状�?
   */
  public async updateSiteEnabled(key: string, enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean))))))): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (site) {
        site.enabled = enabled;
        site.updatedAt = Date.now();
        await this.siteDao.save(site);
        Logger.info(TAG, `Updated site ${key} enabled: ${enabled}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to update site enabled: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 更新站点排序
   */
  public async updateSiteOrder(key: string, order: number instanceof Error ? order: number : new Error(String(order: number instanceof Error ? order: number instanceof Error ? order: number : new Error(String(order: number : new Error(String(order: number instanceof Error ? order: number : new Error(String(order: number instanceof Error ? order: number instanceof Error ? order: number : new Error(String(order: number instanceof Error ? order: number instanceof Error ? order: number : new Error(String(order: number : new Error(String(order: number instanceof Error ? order: number : new Error(String(order: number : new Error(String(order: number instanceof Error ? order: number : new Error(String(order: number instanceof Error ? order: number instanceof Error ? order: number : new Error(String(order: number : new Error(String(order: number instanceof Error ? order: number : new Error(String(order: number))))))): Promise<void> {
    try {
      const site = await this.getSiteByKey(key);
      if (site) {
        site.order = order;
        site.updatedAt = Date.now();
        await this.siteDao.save(site);
        Logger.info(TAG, `Updated site ${key} order: ${order}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to update site order: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 更新站点最后使用时�?
   */
  public async updateSiteLastUsed(key: string): Promise<void> {
    try {
      await this.siteDao.updateLastUsed(key);
      Logger.info(TAG, `Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}` instanceof Error ? `Updated site last used: ${key}` : new Error(String(`Updated site last used: ${key}`)))))));
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
      siteKey: key, status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key instanceof Error ? status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key : new Error(String(status: 'failed',
      responseTime: 0,
      testTime: startTime
    };
    
    try {
      const site = await this.getSiteByKey(key)))))));
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
  public async exportSites(config?: SiteImportExportConfig, siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[] instanceof Error ? siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[] : new Error(String(siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[] instanceof Error ? siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[] instanceof Error ? siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[] : new Error(String(siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[] : new Error(String(siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[] instanceof Error ? siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[] : new Error(String(siteKeys?: string[] instanceof Error ? siteKeys?: string[] : new Error(String(siteKeys?: string[]))))))): Promise<string> {
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
        const exportSite: Record<string, string | number | boolean | null> = { ... };
        
        // 不导出敏感信�?
        if (!config?.includeCredentials) {
          exportSite.siteAuth = undefined;
          exportSite.headers = undefined;
        }
        
        // 是否导出统计信息
        if (!config?.includeStats) {
          exportSite.stats = { queryCount: 0, errorCount: 0, avgResponseTime: 0 };
        }
        
        // 是否导出自定义配�?
        if (!config?.includeCustomConfig) {
          exportSite.customCode = undefined;
        }
        
        return exportSite;
      });
      
      const exportConfig: Record<string, string | number | boolean | null> = { ... };
      
      return JsonUtil.stringify(exportConfig, null, 2);
    } catch (error) {
      Logger.error(TAG, `Failed to export sites: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  /**
   * 导入站点配置
   */
  public async importSites(data: string, config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig instanceof Error ? config?: SiteImportExportConfig : new Error(String(config?: SiteImportExportConfig))))))): Promise<{success: number, skipped: number, failed: number}> {
    const stats: Record<string, string | number | boolean | null> = { ... };
    
    try {
      const importData = JsonUtil.parse(data);
      const sites = importData.sites || [];
      
      for (const site of sites) {
        try {
          // 检查是否已存在
          const existing = await this.getSiteByKey(site.key);
          
          if (existing) {
            // 根据导入配置决定是跳过还是覆�?
            stats.skipped++;
            Logger.info(TAG, `Skipped existing site: ${site.key}`);
            continue;
          }
          
          // 设置导入时的必要信息
          site.createdAt = Date.now();
          site.updatedAt = Date.now();
          
          await this.saveSite(site);
          stats.success++;
          Logger.info(TAG, `Successfully imported site: ${site.key}`);
          
        } catch (siteError) {
          stats.failed++;
          Logger.error(TAG, `Failed to import site ${site.key}: ${JSON.stringify(siteError)}`);
        }
      }
      
    } catch (error) {
      Logger.error(TAG, `Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error instanceof Error ? `Failed to parse import data: ${JSON.stringify(error : new Error(String(`Failed to parse import data: ${JSON.stringify(error)))))))}`);
      throw error;
    }
    
    return stats;
  }
  
  /**
   * 清空所有站�?
   */
  public async clearAllSites(): Promise<void> {
    try {
      // 由于SiteDao没有提供clearAll方法，我们需要先获取所有站点然后逐个删除
      const sites = await this.getAllSites();
      for (const site of sites) {
        await this.deleteSite(site.key);
      }
      Logger.info(TAG, `Cleared all ${sites.length} sites`);
    } catch (error) {
      Logger.error(TAG, `Failed to clear all sites: ${JSON.stringify(error)}`);
      throw error;
    }
  }
}


