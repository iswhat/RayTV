import Logger from '../../common/util/Logger';
import { LoaderType } from './loader/BaseLoader';
import { Site } from '../../data/bean/Site';
import { SiteDao } from '../../data/dao/SiteDao';

/**
 * 站点状态枚举
 */
export enum SiteStatus {
  NORMAL = 'normal',
  ERROR = 'error',
  LOADING = 'loading',
  DISABLED = 'disabled'
}

/**
 * 站点信息扩展接口
 */
export interface SiteInfo extends Site {
  status: SiteStatus;
  errorCount: number;
  lastError?: string;
  lastSuccessTime?: number;
  performanceScore?: number;
}

/**
 * 站点管理器
 * 负责站点信息的注册、更新、删除和查询
 */
export class SiteManager {
  private readonly TAG: string = 'SiteManager';
  private static instance: SiteManager | null = null;
  private sites: Map<string, SiteInfo> = new Map();
  private siteDao: SiteDao;
  private initialized: boolean = false;

  /**
   * 获取单例实例
   * @returns SiteManager
   */
  public static getInstance(): SiteManager {
    if (!SiteManager.instance) {
      SiteManager.instance = new SiteManager();
    }
    return SiteManager.instance;
  }

  /**
   * 构造函数
   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.siteDao = new SiteDao();
    Logger.info(this.TAG, 'SiteManager initialized');
  }

  /**
   * 初始化站点管理器
   * 从数据库加载站点配置
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      Logger.info(this.TAG, 'Initializing site manager...');
      
      // 从数据库加载站点信息
      const sites = await this.siteDao.getAll();
      
      // 初始化站点信息
      for (const site of sites) {
        const siteInfo: SiteInfo = {
          ...site,
          status: site.enabled ? SiteStatus.NORMAL : SiteStatus.DISABLED,
          errorCount: 0,
          performanceScore: 100
        };
        this.sites.set(site.key, siteInfo);
      }
      
      this.initialized = true;
      Logger.info(this.TAG, `Site manager initialized with ${this.sites.size} sites`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize site manager: ${error}`);
      throw error;
    }
  }

  /**
   * 注册站点
   * @param site 站点信息
   * @returns Promise<void>
   */
  public async registerSite(site: Site): Promise<void> {
    try {
      // 验证站点信息
      this.validateSite(site);
      
      // 检查站点是否已存在
      if (this.sites.has(site.key)) {
        throw new Error(`Site already exists: ${site.key}`);
      }
      
      // 创建站点信息
      const siteInfo: SiteInfo = {
        ...site,
        status: site.enabled !== false ? SiteStatus.NORMAL : SiteStatus.DISABLED,
        errorCount: 0,
        performanceScore: 100
      };
      
      // 添加到内存并保存到数据库
      this.sites.set(site.key, siteInfo);
      await this.siteDao.save(site);
      
      Logger.info(this.TAG, `Registered site: ${site.name} (${site.key})`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to register site: ${error}`);
      throw error;
    }
  }

  /**
   * 更新站点
   * @param site 站点信息
   * @returns Promise<void>
   */
  public async updateSite(site: Site): Promise<void> {
    try {
      // 验证站点信息
      this.validateSite(site);
      
      // 检查站点是否存在
      const existingSite = this.sites.get(site.key);
      if (!existingSite) {
        throw new Error(`Site not found: ${site.key}`);
      }
      
      // 更新站点信息
      const updatedSiteInfo: SiteInfo = {
        ...site,
        status: site.enabled !== false ? existingSite.status : SiteStatus.DISABLED,
        errorCount: existingSite.errorCount,
        lastError: existingSite.lastError,
        lastSuccessTime: existingSite.lastSuccessTime,
        performanceScore: existingSite.performanceScore
      };
      
      // 更新内存并保存到数据库
      this.sites.set(site.key, updatedSiteInfo);
      await this.siteDao.update(site);
      
      Logger.info(this.TAG, `Updated site: ${site.name} (${site.key})`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update site: ${error}`);
      throw error;
    }
  }

  /**
   * 删除站点
   * @param siteKey 站点唯一标识
   * @returns Promise<void>
   */
  public async deleteSite(siteKey: string): Promise<void> {
    try {
      // 检查站点是否存在
      if (!this.sites.has(siteKey)) {
        throw new Error(`Site not found: ${siteKey}`);
      }
      
      // 从内存和数据库中删除
      this.sites.delete(siteKey);
      await this.siteDao.delete(siteKey);
      
      Logger.info(this.TAG, `Deleted site: ${siteKey}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete site: ${error}`);
      throw error;
    }
  }

  /**
   * 获取站点信息
   * @param siteKey 站点唯一标识
   * @returns SiteInfo | undefined
   */
  public getSite(siteKey: string): SiteInfo | undefined {
    return this.sites.get(siteKey);
  }

  /**
   * 获取所有站点
   * @returns SiteInfo[]
   */
  public getAllSites(): SiteInfo[] {
    return Array.from(this.sites.values());
  }

  /**
   * 获取启用的站点
   * @returns SiteInfo[]
   */
  public getEnabledSites(): SiteInfo[] {
    return Array.from(this.sites.values()).filter(site => 
      site.enabled !== false && site.status !== SiteStatus.DISABLED
    );
  }

  /**
   * 获取指定类型的站点
   * @param loaderType 加载器类型
   * @returns SiteInfo[]
   */
  public getSitesByType(loaderType: LoaderType): SiteInfo[] {
    return Array.from(this.sites.values()).filter(site => site.type === loaderType);
  }

  /**
   * 获取支持搜索的站点
   * @returns SiteInfo[]
   */
  public getSearchableSites(): SiteInfo[] {
    return Array.from(this.sites.values()).filter(site => 
      site.enabled !== false && site.searchable !== false && site.status !== SiteStatus.DISABLED
    );
  }

  /**
   * 获取支持点播的站点
   * @returns SiteInfo[]
   */
  public getVodSites(): SiteInfo[] {
    return Array.from(this.sites.values()).filter(site => 
      site.enabled !== false && site.tvod !== false && site.status !== SiteStatus.DISABLED
    );
  }

  /**
   * 获取支持直播的站点
   * @returns SiteInfo[]
   */
  public getLiveSites(): SiteInfo[] {
    return Array.from(this.sites.values()).filter(site => 
      site.enabled !== false && site.live !== false && site.status !== SiteStatus.DISABLED
    );
  }

  /**
   * 更新站点状态
   * @param siteKey 站点唯一标识
   * @param status 站点状态
   * @param errorMessage 错误信息（可选）
   */
  public updateSiteStatus(siteKey: string, status: SiteStatus, errorMessage?: string): void {
    const site = this.sites.get(siteKey);
    if (site) {
      site.status = status;
      
      if (status === SiteStatus.ERROR) {
        site.errorCount++;
        site.lastError = errorMessage;
        // 降低性能评分
        site.performanceScore = Math.max(0, site.performanceScore! - 10);
      } else if (status === SiteStatus.NORMAL) {
        site.lastSuccessTime = Date.now();
        // 重置错误计数并提高性能评分
        site.errorCount = 0;
        site.performanceScore = Math.min(100, site.performanceScore! + 5);
      }
      
      Logger.info(this.TAG, `Updated site status: ${siteKey} -> ${status}`);
    }
  }

  /**
   * 设置站点启用状态
   * @param siteKey 站点唯一标识
   * @param enabled 是否启用
   */
  public async setSiteEnabled(siteKey: string, enabled: boolean): Promise<void> {
    const site = this.sites.get(siteKey);
    if (site) {
      site.enabled = enabled;
      site.status = enabled ? SiteStatus.NORMAL : SiteStatus.DISABLED;
      
      // 更新数据库
      await this.siteDao.update(site);
      
      Logger.info(this.TAG, `Set site ${siteKey} enabled: ${enabled}`);
    }
  }

  /**
   * 批量注册站点
   * @param sites 站点信息列表
   * @returns Promise<void>
   */
  public async registerSites(sites: Site[]): Promise<void> {
    try {
      for (const site of sites) {
        try {
          await this.registerSite(site);
        } catch (error) {
          Logger.warn(this.TAG, `Failed to register site ${site.key}: ${error}`);
          // 继续处理其他站点
        }
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to register sites: ${error}`);
      throw error;
    }
  }

  /**
   * 清除所有站点
   * @returns Promise<void>
   */
  public async clearAllSites(): Promise<void> {
    try {
      this.sites.clear();
      await this.siteDao.clearAll();
      Logger.info(this.TAG, 'Cleared all sites');
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear sites: ${error}`);
      throw error;
    }
  }

  /**
   * 获取站点数量
   * @returns number
   */
  public getSiteCount(): number {
    return this.sites.size;
  }

  /**
   * 获取启用站点数量
   * @returns number
   */
  public getEnabledSiteCount(): number {
    return this.getEnabledSites().length;
  }

  /**
   * 验证站点信息
   * @param site 站点信息
   * @private
   */
  private validateSite(site: Site): void {
    if (!site.key || !site.name || !site.type) {
      throw new Error('Invalid site: key, name and type are required');
    }
    
    if (!Object.values(LoaderType).includes(site.type)) {
      throw new Error(`Invalid loader type: ${site.type}`);
    }
    
    if (site.url && !site.url.startsWith('http://') && !site.url.startsWith('https://')) {
      throw new Error(`Invalid URL: ${site.url}`);
    }
  }
}