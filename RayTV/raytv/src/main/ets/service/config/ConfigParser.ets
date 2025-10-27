// ConfigParser - 配置解析器
import Logger from '../../common/util/Logger';
import { Site } from '../../data/bean/Site';

const TAG = 'ConfigParser';

/**
 * 站点类型枚举
 */
export enum SiteType {
  VOD = 'vod',
  LIVE = 'live',
  ALL = 'all'
}

/**
 * 配置解析器，负责解析和验证站点配置
 */
export class ConfigParser {
  /**
   * 验证站点配置
   * @param site 站点配置
   */
  public validateSite(site: any): site is Site {
    try {
      // 基本字段验证
      if (!site || typeof site !== 'object') {
        return false;
      }
      
      if (!site.key || typeof site.key !== 'string') {
        Logger.warn(TAG, 'Site missing required field: key');
        return false;
      }
      
      if (!site.name || typeof site.name !== 'string') {
        Logger.warn(TAG, `Site ${site.key} missing required field: name`);
        return false;
      }
      
      if (!site.api || typeof site.api !== 'string') {
        Logger.warn(TAG, `Site ${site.name} missing required field: api`);
        return false;
      }
      
      // 验证API URL格式
      if (!this.isValidUrl(site.api)) {
        Logger.warn(TAG, `Site ${site.name} has invalid API URL: ${site.api}`);
        return false;
      }
      
      // 验证站点类型
      if (site.type && !Object.values(SiteType).includes(site.type)) {
        Logger.warn(TAG, `Site ${site.name} has invalid type: ${site.type}`);
        site.type = SiteType.ALL; // 默认值
      }
      
      // 验证解析规则
      if (site.search && typeof site.search !== 'object') {
        Logger.warn(TAG, `Site ${site.name} has invalid search config`);
        site.search = {};
      }
      
      if (site.detail && typeof site.detail !== 'object') {
        Logger.warn(TAG, `Site ${site.name} has invalid detail config`);
        site.detail = {};
      }
      
      // 确保必要的默认值
      this.ensureDefaultValues(site);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Error validating site: ${error}`);
      return false;
    }
  }
  
  /**
   * 转换Fongmi格式配置
   * @param fongmiConfig Fongmi格式配置
   */
  public convertFongmiFormat(fongmiConfig: any): Site[] {
    try {
      Logger.info(TAG, 'Converting Fongmi format config');
      
      const sites: Site[] = [];
      
      // Fongmi格式通常是一个包含多个站点配置的对象
      if (typeof fongmiConfig === 'object' && fongmiConfig !== null) {
        // 遍历配置中的每个站点
        for (const [key, value] of Object.entries(fongmiConfig)) {
          const siteData = value as any;
          
          // 转换为标准站点格式
          const site: Site = {
            key: key,
            name: siteData.name || key,
            type: this.detectSiteType(siteData),
            api: siteData.api || '',
            searchable: siteData.searchable !== false,
            categories: this.convertCategories(siteData.categories),
            headers: this.convertHeaders(siteData.headers || siteData.header),
            search: this.convertSearchRules(siteData.search),
            detail: this.convertDetailRules(siteData.detail),
            play: this.convertPlayRules(siteData.play),
            filterable: siteData.filterable || false,
            filters: siteData.filters || [],
            proxy: siteData.proxy || false,
            weight: siteData.weight || 0,
            enabled: siteData.enabled !== false,
            updateTime: Date.now(),
            lastCheckTime: 0
          };
          
          // 验证并添加到结果列表
          if (this.validateSite(site)) {
            sites.push(site);
          }
        }
      }
      
      Logger.info(TAG, `Converted ${sites.length} sites from Fongmi format`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to convert Fongmi format: ${error}`);
      return [];
    }
  }
  
  /**
   * 自动检测站点类型
   * @param siteData 站点数据
   */
  public detectSiteType(siteData: any): SiteType {
    // 根据站点配置特征自动判断类型
    if (siteData.type) {
      return siteData.type as SiteType;
    }
    
    // 通过关键词判断
    const name = (siteData.name || '').toLowerCase();
    const api = (siteData.api || '').toLowerCase();
    
    if (name.includes('live') || name.includes('直播') || 
        api.includes('live') || api.includes('zhibo')) {
      return SiteType.LIVE;
    }
    
    if (name.includes('vod') || name.includes('点播') || 
        name.includes('电影') || name.includes('tv') || 
        name.includes('电视剧')) {
      return SiteType.VOD;
    }
    
    // 默认类型
    return SiteType.ALL;
  }
  
  /**
   * 转换请求头
   * @param headers 原始请求头
   */
  public convertHeaders(headers: any): Record<string, string> {
    const result: Record<string, string> = {};
    
    if (!headers) {
      return result;
    }
    
    // 处理不同格式的请求头
    if (typeof headers === 'string') {
      // 字符串格式: "User-Agent: xxx; Referer: yyy"
      headers.split(';').forEach((header: string) => {
        const parts = header.split(':');
        if (parts.length >= 2) {
          const key = parts[0].trim();
          const value = parts.slice(1).join(':').trim();
          result[key] = value;
        }
      });
    } else if (typeof headers === 'object') {
      // 对象格式
      Object.assign(result, headers);
    }
    
    return result;
  }
  
  /**
   * 转换分类配置
   * @param categories 原始分类
   */
  public convertCategories(categories: any): Array<{ key: string; name: string }> {
    const result: Array<{ key: string; name: string }> = [];
    
    if (!categories) {
      return result;
    }
    
    if (Array.isArray(categories)) {
      categories.forEach((category: any) => {
        if (typeof category === 'string') {
          result.push({ key: category, name: category });
        } else if (typeof category === 'object' && category.key && category.name) {
          result.push({ key: category.key, name: category.name });
        }
      });
    } else if (typeof categories === 'object') {
      // 处理键值对格式
      Object.entries(categories).forEach(([key, value]) => {
        result.push({ key, name: value as string });
      });
    }
    
    return result;
  }
  
  /**
   * 转换搜索规则
   * @param searchRules 原始搜索规则
   */
  public convertSearchRules(searchRules: any): any {
    if (!searchRules || typeof searchRules !== 'object') {
      return {
        url: '',
        method: 'get',
        headers: {},
        data: {},
        parse: {
          items: '',
          title: '',
          cover: '',
          desc: '',
          url: ''
        }
      };
    }
    
    // 确保必要字段存在
    const result = { ...searchRules };
    result.parse = result.parse || {};
    
    return result;
  }
  
  /**
   * 转换详情规则
   * @param detailRules 原始详情规则
   */
  public convertDetailRules(detailRules: any): any {
    if (!detailRules || typeof detailRules !== 'object') {
      return {
        url: '',
        method: 'get',
        headers: {},
        data: {},
        parse: {
          title: '',
          cover: '',
          desc: '',
          info: [],
          list: []
        }
      };
    }
    
    // 确保必要字段存在
    const result = { ...detailRules };
    result.parse = result.parse || {};
    
    return result;
  }
  
  /**
   * 转换播放规则
   * @param playRules 原始播放规则
   */
  public convertPlayRules(playRules: any): any {
    if (!playRules || typeof playRules !== 'object') {
      return {
        url: '',
        method: 'get',
        headers: {},
        data: {},
        parse: {
          code: '',
          url: '',
          headers: {}
        }
      };
    }
    
    // 确保必要字段存在
    const result = { ...playRules };
    result.parse = result.parse || {};
    
    return result;
  }
  
  /**
   * 提取扩展信息
   * @param site 站点配置
   */
  public extractExtensionInfo(site: Site): Record<string, any> {
    const extensions: Record<string, any> = {};
    
    // 提取自定义字段
    const customFields = ['parser', 'encrypt', 'decrypt', 'transform', 'beforeRequest', 'afterResponse'];
    
    customFields.forEach(field => {
      if (site[field as keyof Site] !== undefined) {
        extensions[field] = site[field as keyof Site];
      }
    });
    
    // 提取特殊标记
    if (site.api.includes('http://') && !site.proxy) {
      extensions.needsHttpsUpgrade = true;
    }
    
    return extensions;
  }
  
  /**
   * 优化站点配置
   * @param site 原始站点配置
   */
  public optimizeSiteConfig(site: Site): Site {
    const optimized: Site = { ...site };
    
    // 优化API URL
    if (optimized.api) {
      // 移除末尾斜杠
      optimized.api = optimized.api.replace(/\/$/, '');
      
      // 规范化URL格式
      if (!optimized.api.startsWith('http://') && !optimized.api.startsWith('https://')) {
        optimized.api = 'http://' + optimized.api;
      }
    }
    
    // 优化请求头
    if (!optimized.headers) {
      optimized.headers = {};
    }
    
    // 添加默认User-Agent
    if (!optimized.headers['User-Agent']) {
      optimized.headers['User-Agent'] = 'RayTV-HarmonyOS/1.0';
    }
    
    // 优化分类列表
    if (!optimized.categories) {
      optimized.categories = [];
    }
    
    // 去重分类
    const categoryKeys = new Set<string>();
    optimized.categories = optimized.categories.filter(cat => {
      if (categoryKeys.has(cat.key)) {
        return false;
      }
      categoryKeys.add(cat.key);
      return true;
    });
    
    return optimized;
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
      // 尝试添加默认协议
      try {
        new URL('http://' + url);
        return true;
      } catch {
        return false;
      }
    }
  }
  
  /**
   * 确保必要的默认值
   * @param site 站点配置
   */
  private ensureDefaultValues(site: any): void {
    if (!site.type) {
      site.type = SiteType.ALL;
    }
    
    if (site.searchable === undefined) {
      site.searchable = true;
    }
    
    if (!site.headers) {
      site.headers = {};
    }
    
    if (!site.categories) {
      site.categories = [];
    }
    
    if (site.enabled === undefined) {
      site.enabled = true;
    }
    
    if (!site.weight && site.weight !== 0) {
      site.weight = 100;
    }
    
    if (!site.search) {
      site.search = {};
    }
    
    if (!site.detail) {
      site.detail = {};
    }
    
    if (!site.play) {
      site.play = {};
    }
    
    // 设置时间戳
    if (!site.updateTime) {
      site.updateTime = Date.now();
    }
    
    if (!site.lastCheckTime) {
      site.lastCheckTime = 0;
    }
  }
  
  /**
   * 批量验证站点列表
   * @param sites 站点列表
   */
  public validateSites(sites: any[]): Site[] {
    const validSites: Site[] = [];
    const invalidCount: Record<string, number> = { missingKey: 0, missingName: 0, missingApi: 0, invalidApi: 0, other: 0 };
    
    if (!Array.isArray(sites)) {
      Logger.error(TAG, 'Input sites is not an array');
      return [];
    }
    
    Logger.info(TAG, `Validating ${sites.length} sites`);
    
    sites.forEach((site, index) => {
      try {
        if (this.validateSite(site)) {
          // 优化配置并添加到有效列表
          const optimized = this.optimizeSiteConfig(site);
          validSites.push(optimized);
        } else {
          // 统计失败原因
          if (!site.key) invalidCount.missingKey++;
          else if (!site.name) invalidCount.missingName++;
          else if (!site.api) invalidCount.missingApi++;
          else if (!this.isValidUrl(site.api)) invalidCount.invalidApi++;
          else invalidCount.other++;
        }
      } catch (error) {
        Logger.error(TAG, `Error validating site at index ${index}: ${error}`);
        invalidCount.other++;
      }
    });
    
    // 打印验证统计
    Logger.info(TAG, `Validation result: ${validSites.length} valid, ${sites.length - validSites.length} invalid`);
    Logger.info(TAG, `Invalid reasons: ${JSON.stringify(invalidCount)}`);
    
    return validSites;
  }
  
  /**
   * 合并多个配置源
   * @param configSources 配置源列表
   */
  public mergeConfigs(configSources: Array<{ sites: Site[] }>): Site[] {
    const mergedSites: Site[] = [];
    const siteKeys = new Set<string>();
    
    Logger.info(TAG, `Merging ${configSources.length} config sources`);
    
    configSources.forEach((source, index) => {
      if (source.sites && Array.isArray(source.sites)) {
        source.sites.forEach(site => {
          if (site.key && !siteKeys.has(site.key)) {
            siteKeys.add(site.key);
            mergedSites.push(site);
          } else if (site.key) {
            Logger.warn(TAG, `Duplicate site key ${site.key} found in source ${index + 1}`);
          }
        });
      }
    });
    
    Logger.info(TAG, `Merged ${mergedSites.length} unique sites`);
    return mergedSites;
  }
}