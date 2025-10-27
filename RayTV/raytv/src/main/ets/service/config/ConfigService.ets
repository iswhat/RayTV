// ConfigService - 配置服务
import Logger from '../../common/util/Logger';
import { Site } from '../../data/bean/Site';
import { ConfigLoader } from './ConfigLoader';
import { ConfigParser, SiteType } from './ConfigParser';
import { SiteDao } from '../../data/dao/SiteDao';
import { SiteRepository } from '../../data/repository/SiteRepository';
import { AppConfig } from '../../data/bean/Config';

const TAG = 'ConfigService';

/**
 * 配置导入结果
 */
export interface ImportResult {
  success: boolean;
  importedCount: number;
  failedCount: number;
  message: string;
}

/**
 * 配置服务，作为配置管理的核心服务
 */
export class ConfigService {
  private static instance: ConfigService;
  
  private configLoader: ConfigLoader;
  private configParser: ConfigParser;
  private siteDao: SiteDao;
  private siteRepository: SiteRepository;
  
  private constructor() {
    this.configLoader = ConfigLoader.getInstance();
    this.configParser = new ConfigParser();
    this.siteDao = new SiteDao();
    this.siteRepository = new SiteRepository();
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): ConfigService {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
    }
    return ConfigService.instance;
  }
  
  /**
   * 从URL导入配置
   * @param url 配置URL
   */
  public async importFromUrl(url: string): Promise<ImportResult> {
    try {
      Logger.info(TAG, `Importing config from URL: ${url}`);
      
      // 加载配置内容
      const content = await this.configLoader.loadFromUrl(url);
      
      // 解析配置
      const parsedConfig = this.configLoader.parseConfig(content);
      
      // 验证站点
      const validSites = this.configParser.validateSites(parsedConfig.sites);
      
      // 保存有效站点
      await this.saveSites(validSites);
      
      // 保存应用配置（如果有）
      if (parsedConfig.appConfig) {
        await this.saveAppConfig(parsedConfig.appConfig);
      }
      
      Logger.info(TAG, `Successfully imported ${validSites.length} sites from URL`);
      
      return {
        success: true,
        importedCount: validSites.length,
        failedCount: parsedConfig.sites.length - validSites.length,
        message: `成功导入 ${validSites.length} 个站点`
      };
    } catch (error) {
      Logger.error(TAG, `Failed to import config from URL: ${error}`);
      return {
        success: false,
        importedCount: 0,
        failedCount: 0,
        message: `导入失败: ${error instanceof Error ? error.message : '未知错误'}`
      };
    }
  }
  
  /**
   * 从文件导入配置
   * @param filePath 文件路径
   */
  public async importFromFile(filePath: string): Promise<ImportResult> {
    try {
      Logger.info(TAG, `Importing config from file: ${filePath}`);
      
      // 加载配置内容
      const content = await this.configLoader.loadFromFile(filePath);
      
      // 解析配置
      const parsedConfig = this.configLoader.parseConfig(content);
      
      // 验证站点
      const validSites = this.configParser.validateSites(parsedConfig.sites);
      
      // 保存有效站点
      await this.saveSites(validSites);
      
      // 保存应用配置（如果有）
      if (parsedConfig.appConfig) {
        await this.saveAppConfig(parsedConfig.appConfig);
      }
      
      Logger.info(TAG, `Successfully imported ${validSites.length} sites from file`);
      
      return {
        success: true,
        importedCount: validSites.length,
        failedCount: parsedConfig.sites.length - validSites.length,
        message: `成功导入 ${validSites.length} 个站点`
      };
    } catch (error) {
      Logger.error(TAG, `Failed to import config from file: ${error}`);
      return {
        success: false,
        importedCount: 0,
        failedCount: 0,
        message: `导入失败: ${error instanceof Error ? error.message : '未知错误'}`
      };
    }
  }
  
  /**
   * 导入Fongmi格式配置
   * @param content 配置内容
   */
  public async importFongmiConfig(content: string): Promise<ImportResult> {
    try {
      Logger.info(TAG, 'Importing Fongmi format config');
      
      // 解析JSON
      const fongmiConfig = JSON.parse(content);
      
      // 转换为标准格式
      const sites = this.configParser.convertFongmiFormat(fongmiConfig);
      
      // 验证站点
      const validSites = this.configParser.validateSites(sites);
      
      // 保存有效站点
      await this.saveSites(validSites);
      
      Logger.info(TAG, `Successfully imported ${validSites.length} sites from Fongmi format`);
      
      return {
        success: true,
        importedCount: validSites.length,
        failedCount: sites.length - validSites.length,
        message: `成功导入 ${validSites.length} 个站点`
      };
    } catch (error) {
      Logger.error(TAG, `Failed to import Fongmi config: ${error}`);
      return {
        success: false,
        importedCount: 0,
        failedCount: 0,
        message: `导入失败: ${error instanceof Error ? error.message : '未知错误'}`
      };
    }
  }
  
  /**
   * 保存站点配置到数据库
   * @param sites 站点列表
   */
  private async saveSites(sites: Site[]): Promise<void> {
    try {
      Logger.info(TAG, `Saving ${sites.length} sites to database`);
      
      // 批量保存站点
      for (const site of sites) {
        // 检查是否已存在
        const existing = await this.siteDao.getByKey(site.key);
        
        if (existing) {
          // 更新现有站点
          site.id = existing.id;
          await this.siteDao.update(site);
          Logger.debug(TAG, `Updated existing site: ${site.name}`);
        } else {
          // 添加新站点
          await this.siteDao.insert(site);
          Logger.debug(TAG, `Added new site: ${site.name}`);
        }
      }
      
    } catch (error) {
      Logger.error(TAG, `Failed to save sites: ${error}`);
      throw error;
    }
  }
  
  /**
   * 保存应用配置
   * @param config 应用配置
   */
  private async saveAppConfig(config: AppConfig): Promise<void> {
    try {
      Logger.info(TAG, 'Saving application config');
      
      // 这里可以实现应用配置的保存逻辑
      // 目前简化处理
      
    } catch (error) {
      Logger.error(TAG, `Failed to save app config: ${error}`);
    }
  }
  
  /**
   * 获取所有站点
   */
  public async getAllSites(): Promise<Site[]> {
    try {
      const sites = await this.siteDao.getAll();
      Logger.info(TAG, `Retrieved ${sites.length} sites`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to get all sites: ${error}`);
      return [];
    }
  }
  
  /**
   * 获取启用的站点
   */
  public async getEnabledSites(): Promise<Site[]> {
    try {
      const sites = await this.siteDao.getEnabled();
      Logger.info(TAG, `Retrieved ${sites.length} enabled sites`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to get enabled sites: ${error}`);
      return [];
    }
  }
  
  /**
   * 获取指定类型的站点
   * @param type 站点类型
   */
  public async getSitesByType(type: string): Promise<Site[]> {
    try {
      const sites = await this.siteDao.getByType(type);
      Logger.info(TAG, `Retrieved ${sites.length} ${type} sites`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to get sites by type: ${error}`);
      return [];
    }
  }
  
  /**
   * 根据关键字获取站点
   * @param key 站点关键字
   */
  public async getSiteByKey(key: string): Promise<Site | null> {
    try {
      const site = await this.siteDao.getByKey(key);
      Logger.info(TAG, `Retrieved site: ${site?.name || 'not found'}`);
      return site;
    } catch (error) {
      Logger.error(TAG, `Failed to get site by key: ${error}`);
      return null;
    }
  }
  
  /**
   * 更新站点
   * @param site 站点配置
   */
  public async updateSite(site: Site): Promise<void> {
    try {
      // 验证站点配置
      if (!this.configParser.validateSite(site)) {
        throw new Error('Invalid site configuration');
      }
      
      // 更新时间戳
      site.updatedAt = Date.now();
      
      // 保存到数据库
      await this.siteDao.update(site);
      Logger.info(TAG, `Updated site: ${site.name}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update site: ${error}`);
      throw error;
    }
  }
  
  /**
   * 删除站点
   * @param key 站点关键字
   */
  public async deleteSite(key: string): Promise<void> {
    try {
      await this.siteDao.delete(key);
      Logger.info(TAG, `Deleted site with key: ${key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete site: ${error}`);
      throw error;
    }
  }
  
  /**
   * 批量删除站点
   * @param keys 站点关键字列表
   */
  public async deleteSites(keys: string[]): Promise<void> {
    try {
      for (const key of keys) {
        await this.siteDao.delete(key);
      }
      Logger.info(TAG, `Deleted ${keys.length} sites`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete sites: ${error}`);
      throw error;
    }
  }
  
  /**
   * 启用/禁用站点
   * @param key 站点关键字
   * @param enabled 是否启用
   */
  public async setSiteEnabled(key: string, enabled: boolean): Promise<void> {
    try {
      const site = await this.siteDao.getByKey(key);
      if (!site) {
        throw new Error(`Site not found: ${key}`);
      }
      
      site.enabled = enabled;
      site.updatedAt = Date.now();
      
      await this.siteDao.update(site);
      Logger.info(TAG, `${enabled ? 'Enabled' : 'Disabled'} site: ${site.name}`);
    } catch (error) {
      Logger.error(TAG, `Failed to ${enabled ? 'enable' : 'disable'} site: ${error}`);
      throw error;
    }
  }
  
  /**
   * 调整站点顺序
   * @param siteKeys 站点关键字顺序列表
   */
  public async reorderSites(siteKeys: string[]): Promise<void> {
    try {
      // 更新每个站点的权重
      for (let i = 0; i < siteKeys.length; i++) {
        const key = siteKeys[i];
        const site = await this.siteDao.getByKey(key);
        
        if (site) {
          site.weight = (siteKeys.length - i) * 10; // 权重从高到低
          site.updatedAt = Date.now();
          await this.siteDao.update(site);
        }
      }
      
      Logger.info(TAG, `Reordered ${siteKeys.length} sites`);
    } catch (error) {
      Logger.error(TAG, `Failed to reorder sites: ${error}`);
      throw error;
    }
  }
  
  /**
   * 导出站点配置
   * @param filePath 导出文件路径
   */
  public async exportConfig(filePath: string): Promise<void> {
    try {
      // 获取所有站点
      const sites = await this.siteDao.getAll();
      
      // 导出到文件
      await this.configLoader.saveConfigToFile(sites, filePath);
      
      Logger.info(TAG, `Exported ${sites.length} sites to ${filePath}`);
    } catch (error) {
      Logger.error(TAG, `Failed to export config: ${error}`);
      throw error;
    }
  }
  
  /**
   * 清空所有站点
   */
  public async clearAllSites(): Promise<void> {
    try {
      await this.siteDao.clearAll();
      Logger.info(TAG, 'Cleared all sites');
    } catch (error) {
      Logger.error(TAG, `Failed to clear all sites: ${error}`);
      throw error;
    }
  }
  
  /**
   * 检查站点健康状态
   * @param site 站点配置
   */
  public async checkSiteHealth(site: Site): Promise<{
    healthy: boolean;
    responseTime?: number;
    error?: string;
  }> {
    try {
      Logger.info(TAG, `Checking health for site: ${site.name}`);
      
      // 记录开始时间
      const startTime = Date.now();
      
      // 这里可以实现站点健康检查逻辑
      // 例如发送一个简单的请求到API
      // 目前简化处理，假设站点都是健康的
      
      const responseTime = Date.now() - startTime;
      
      // 更新最后检查时间
      site.lastCheckTime = Date.now();
      await this.siteDao.update(site);
      
      return {
        healthy: true,
        responseTime
      };
    } catch (error) {
      Logger.error(TAG, `Failed to check site health: ${error}`);
      return {
        healthy: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
  
  /**
   * 批量检查站点健康状态
   */
  public async checkAllSitesHealth(): Promise<Array<{
    site: Site;
    healthy: boolean;
    responseTime?: number;
    error?: string;
  }>> {
    try {
      const sites = await this.siteDao.getAll();
      const results: Array<{
        site: Site;
        healthy: boolean;
        responseTime?: number;
        error?: string;
      }> = [];
      
      // 并行检查所有站点
      const healthChecks = sites.map(async (site) => {
        const result = await this.checkSiteHealth(site);
        results.push({ site, ...result });
      });
      
      await Promise.all(healthChecks);
      
      Logger.info(TAG, `Health check completed for ${sites.length} sites`);
      return results;
    } catch (error) {
      Logger.error(TAG, `Failed to check all sites health: ${error}`);
      return [];
    }
  }
  
  /**
   * 清除配置缓存
   */
  public async clearConfigCache(): Promise<void> {
    try {
      await this.configLoader.clearCache();
      Logger.info(TAG, 'Config cache cleared');
    } catch (error) {
      Logger.error(TAG, `Failed to clear config cache: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取缓存信息
   */
  public async getCacheInfo(): Promise<{
    cacheSize: number;
    cacheFiles: number;
    lastCacheTime: number;
  }> {
    return await this.configLoader.getCacheInfo();
  }
  
  /**
   * 创建新站点
   * @param site 站点配置
   */
  public async createSite(site: Omit<Site, 'id'>): Promise<Site> {
    try {
      // 验证站点配置
      if (!this.configParser.validateSite(site)) {
        throw new Error('Invalid site configuration');
      }
      
      // 设置创建时间
      const newSite = {
        ...site,
        createdAt: Date.now(),
        updatedAt: Date.now(),
        lastCheckTime: 0
      };
      
      // 保存到数据库
      await this.siteDao.insert(newSite);
      
      Logger.info(TAG, `Created new site: ${site.name}`);
      
      // 返回完整的站点对象（包含ID）
      const savedSite = await this.siteDao.getByKey(site.key);
      if (!savedSite) {
        throw new Error('Failed to retrieve newly created site');
      }
      
      return savedSite;
    } catch (error) {
      Logger.error(TAG, `Failed to create site: ${error}`);
      throw error;
    }
  }
  
  /**
   * 搜索站点
   * @param keyword 搜索关键词
   */
  public async searchSites(keyword: string): Promise<Site[]> {
    try {
      const allSites = await this.siteDao.getAll();
      const lowercaseKeyword = keyword.toLowerCase();
      
      const results = allSites.filter(site => 
        site.name.toLowerCase().includes(lowercaseKeyword) ||
        site.key.toLowerCase().includes(lowercaseKeyword) ||
        (site.api && site.api.toLowerCase().includes(lowercaseKeyword))
      );
      
      Logger.info(TAG, `Found ${results.length} sites matching keyword: ${keyword}`);
      return results;
    } catch (error) {
      Logger.error(TAG, `Failed to search sites: ${error}`);
      return [];
    }
  }
}