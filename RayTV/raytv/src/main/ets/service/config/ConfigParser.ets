// ConfigParser - 配置解析器
// 实现Fongmi配置文件解析和适配功能
import Logger from '../../common/util/Logger';
import { Site, SiteType } from '../../data/bean/Site';
import { AppConfig, HarmonyConfig } from '../../data/bean/Config';

const TAG = 'ConfigParser';

/**
 * 配置解析器，负责解析和适配各种格式的配置文件
 */
export class ConfigParser {
  private static instance: ConfigParser;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  public static getInstance(): ConfigParser {
    if (!ConfigParser.instance) {
      ConfigParser.instance = new ConfigParser();
    }
    return ConfigParser.instance;
  }

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
   * 确保站点配置的默认值
   */
  private ensureDefaultValues(site: any): void {
    site.type = site.type || SiteType.ALL;
    site.searchable = site.searchable !== false;
    site.categories = site.categories || [];
    site.headers = site.headers || {};
    site.search = site.search || {};
    site.detail = site.detail || {};
    site.play = site.play || {};
    site.filterable = site.filterable || false;
    site.filters = site.filters || [];
    site.proxy = site.proxy || false;
    site.weight = site.weight || 0;
    site.enabled = site.enabled !== false;
    site.updateTime = site.updateTime || Date.now();
    site.lastCheckTime = site.lastCheckTime || 0;
  }

  /**
   * 解析站点配置
   * @param configContent 配置文件内容
   * @returns 站点列表
   */
  public parseSites(configContent: string): Site[] {
    try {
      Logger.info(TAG, 'Parsing sites configuration');
      
      // 尝试解析为JSON
      const config = this.parseJsonContent(configContent);
      
      // 支持不同格式的配置结构
      const sitesData = config.sites || config.subscriptions || config.data || config;
      if (!sitesData) {
        throw new Error('Invalid sites configuration format');
      }
      
      // 检查是否为Fongmi格式
      if (this.isFongmiFormat(sitesData)) {
        return this.convertFongmiFormat(sitesData);
      }
      
      // 标准数组格式
      const sites: Site[] = [];
      if (Array.isArray(sitesData)) {
        for (const siteData of sitesData) {
          try {
            const site = this.parseSiteItem(siteData);
            sites.push(site);
          } catch (error) {
            Logger.error(TAG, `Failed to parse site item: ${error}`);
          }
        }
      }
      
      Logger.info(TAG, `Successfully parsed ${sites.length} sites`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to parse sites configuration: ${error}`);
      throw error;
    }
  }
  
  /**
   * 判断是否为Fongmi格式配置
   */
  private isFongmiFormat(config: any): boolean {
    if (typeof config !== 'object' || config === null) return false;
    
    // Fongmi格式通常是对象，每个键对应一个站点
    return !Array.isArray(config) && 
           Object.keys(config).length > 0 &&
           Object.entries(config).some(([_, value]) => 
             typeof value === 'object' && 
             value !== null && 
             ('api' in value || 'name' in value)
           );
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
   * 安全解析JSON内容
   * @param content JSON字符串内容
   */
  public parseJsonContent(content: string): any {
    try {
      // 预处理，移除注释和多余空格
      const cleanContent = this.cleanJsonContent(content);
      return JSON.parse(cleanContent);
    } catch (error) {
      Logger.error(TAG, `Failed to parse JSON content: ${error}`);
      throw new Error(`Invalid JSON format: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 清理JSON内容，移除注释和无效字符
   * @param content 原始JSON内容
   */
  private cleanJsonContent(content: string): string {
    // 移除单行注释
    let clean = content.replace(/\/\/.*$/gm, '');
    // 移除多行注释
    clean = clean.replace(/\/\*[\s\S]*?\*\//g, '');
    // 移除多余空白字符
    clean = clean.trim();
    return clean;
  }
  
  /**
   * 解析单个站点配置项
   * @param siteData 站点数据
   */
  private parseSiteItem(siteData: any): Site {
    if (!siteData || typeof siteData !== 'object') {
      throw new Error('Invalid site data format');
    }
    
    const site: Site = {
      key: siteData.key || this.generateSiteKey(siteData.name || 'unknown'),
      name: siteData.name || 'Unknown Site',
      type: this.convertSiteType(siteData.type),
      api: siteData.api || siteData.url || '',
      searchable: siteData.searchable !== false,
      categories: this.convertCategories(siteData.categories),
      headers: this.convertHeaders(siteData.headers || siteData.header),
      search: siteData.search || {},
      detail: siteData.detail || {},
      play: siteData.play || {},
      filterable: siteData.filterable || false,
      filters: siteData.filters || [],
      proxy: siteData.proxy || false,
      weight: siteData.weight || 0,
      enabled: siteData.enabled !== false,
      updateTime: Date.now(),
      lastCheckTime: 0
    };
    
    if (!this.validateSite(site)) {
      throw new Error(`Invalid site configuration for: ${site.name}`);
    }
    
    return site;
  }
  
  /**
   * 生成站点唯一键
   * @param name 站点名称
   */
  private generateSiteKey(name: string): string {
    return name.toLowerCase().replace(/[^a-z0-9]/g, '_');
  }
  
  /**
   * 转换站点类型
   * @param type 原始类型
   */
  private convertSiteType(type?: string): SiteType {
    if (!type) return SiteType.ALL;
    
    const lowerType = type.toLowerCase();
    if (lowerType === 'vod' || lowerType.includes('点播')) return SiteType.VOD;
    if (lowerType === 'live' || lowerType.includes('直播')) return SiteType.LIVE;
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
    
    // 处理数组格式分类
    if (Array.isArray(categories)) {
      categories.forEach((cat: any) => {
        if (typeof cat === 'string') {
          result.push({ key: cat, name: cat });
        } else if (typeof cat === 'object' && cat.key && cat.name) {
          result.push({ key: cat.key, name: cat.name });
        }
      });
    } 
    // 处理Fongmi格式分类（对象格式）
    else if (typeof categories === 'object' && categories !== null) {
      Object.entries(categories).forEach(([key, value]) => {
        result.push({ 
          key: key, 
          name: typeof value === 'string' ? value : String(value || key)
        });
      });
    }
    
    // 确保分类唯一
    const uniqueCategories = new Map<string, { key: string; name: string }>();
    result.forEach(cat => {
      if (!uniqueCategories.has(cat.key)) {
        uniqueCategories.set(cat.key, cat);
      }
    });
    
    return Array.from(uniqueCategories.values());
  }

  /**
   * 转换搜索规则
   * @param searchData 原始搜索配置
   */
  public convertSearchRules(searchData: any): any {
    if (!searchData) return {};
    
    // 标准化搜索规则格式
    return {
      // Fongmi格式搜索规则适配
      page: searchData.page !== undefined ? searchData.page : true,
      searchKey: searchData.key || searchData.searchKey || 'wd',
      pageKey: searchData.pageKey || 'page',
      resultPath: searchData.resultPath || '',
      list: searchData.list || [],
      ...searchData
    };
  }
  
  /**
   * 转换详情页规则
   * @param detailData 原始详情配置
   */
  public convertDetailRules(detailData: any): any {
    if (!detailData) return {};
    
    // 标准化详情页规则格式
    return {
      // Fongmi格式详情页规则适配
      video: detailData.video || {},
      parse: detailData.parse || [],
      ...detailData
    };
  }
  
  /**
   * 转换播放规则
   * @param playData 原始播放配置
   */
  public convertPlayRules(playData: any): any {
    if (!playData) return {};
    
    // 标准化播放规则格式
    const play = {
      // Fongmi格式播放规则适配
      parse: playData.parse || [],
      proxy: playData.proxy !== undefined ? playData.proxy : false,
      ...playData
    };
    
    // 处理多格式播放规则
    if (typeof playData !== 'object') {
      // 处理字符串格式播放规则
      play.url = playData;
    }
    
    return play;
  }

  /**
   * 解析应用配置
   * @param configContent 配置文件内容
   */
  public parseAppConfig(configContent: string): HarmonyConfig {
    try {
      Logger.info(TAG, 'Parsing application configuration');
      
      const config = this.parseJsonContent(configContent);
      
      // 创建HarmonyOS专用配置
      const harmonyConfig: HarmonyConfig = {
        app: {
          name: config.app?.name || 'RayTV',
          version: config.app?.version || '1.0.0',
          debug: config.app?.debug || false
        },
        services: {
          autoStart: config.services?.autoStart || false,
          backgroundRefresh: config.services?.backgroundRefresh || false,
          dataSync: config.services?.dataSync || false
        },
        player: {
          defaultEngine: config.player?.defaultEngine || 'system',
          autoPlayNext: config.player?.autoPlayNext || true,
          rememberPosition: config.player?.rememberPosition || true,
          subtitles: config.player?.subtitles || { enabled: true }
        },
        ui: {
          theme: config.ui?.theme || 'system',
          fontSize: config.ui?.fontSize || 'medium',
          layout: config.ui?.layout || 'default'
        },
        security: {
          enableScreenLock: config.security?.enableScreenLock || false,
          allowScreenshots: config.security?.allowScreenshots || true,
          dataEncryption: config.security?.dataEncryption || false
        },
        // 兼容Fongmi配置
        sites: this.parseSites(configContent),
        updateTime: Date.now()
      };
      
      return harmonyConfig;
    } catch (error) {
      Logger.error(TAG, `Failed to parse application configuration: ${error}`);
      // 返回默认配置
      return this.getDefaultConfig();
    }
  }
  
  /**
   * 获取默认配置
   */
  private getDefaultConfig(): HarmonyConfig {
    return {
      app: {
        name: 'RayTV',
        version: '1.0.0',
        debug: false
      },
      services: {
        autoStart: false,
        backgroundRefresh: false,
        dataSync: false
      },
      player: {
        defaultEngine: 'system',
        autoPlayNext: true,
        rememberPosition: true,
        subtitles: { enabled: true }
      },
      ui: {
        theme: 'system',
        fontSize: 'medium',
        layout: 'default'
      },
      security: {
        enableScreenLock: false,
        allowScreenshots: true,
        dataEncryption: false
      },
      sites: [],
      updateTime: Date.now()
    };
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
}
