// ConfigParser - 配置解析器
// 实现Fongmi配置文件解析和适配功能
import Logger from '../../common/util/Logger';
import { TypeSafetyUtil } from '../../common/util/TypeSafetyUtil';
import { Site, SiteType, LoaderType } from '../../data/bean/Site';
import { AppConfig, HarmonyConfig } from '../../data/bean/Config';


const TAG = 'ConfigParser';

// 接口定义
export interface CategoryItem {
  key: string;
  name: string;
}

// 搜索规则接口 - 替换any和unknown为具体类型
export interface SearchRuleItem {
  name: string;
  regex?: string;
  fixed?: string;
  type?: string;
  filter?: boolean;
}

export interface SearchRules {
  page: boolean;
  searchKey: string;
  pageKey: string;
  resultPath: string;
  list: SearchRuleItem[];
}

// 详情规则接口 - 替换unknown为具体类型
export interface DetailRules {
  title?: SearchRuleItem;
  cover?: SearchRuleItem;
  desc?: SearchRuleItem;
  director?: SearchRuleItem;
  actor?: SearchRuleItem;
  year?: SearchRuleItem;
  area?: SearchRuleItem;
  update?: SearchRuleItem;
  score?: SearchRuleItem;
  type?: SearchRuleItem;
  playlist?: SearchRuleItem;
  tags?: SearchRuleItem;
}

// 播放规则接口 - 替换unknown为具体类型
export interface PlaySource {
  name: string;
  rules: Record<string, SearchRuleItem>;
}

export interface PlayRules {
  // ArkTS兼容：使用数组替代索引签名
  sources: Array<{
    key: string;
    source: PlaySource;
  }>;
}

/**
 * 配置解析器，负责解析和适配各种格式的配置文件
 */
export class ConfigParser {
  private static instance: ConfigParser;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   * @returns ConfigParser实例
   */
  public static getInstance(): ConfigParser {
    if (!ConfigParser.instance) {
      ConfigParser.instance = new ConfigParser();
    }
    return ConfigParser.instance;
  }
  
  /**
   * 获取对象的所有键
   * 使用TypeSafetyUtil确保类型安全
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    return Object.keys(obj);
  }

  /**
   * 验证站点配置
   * @param site 站点配置
   */
  public validateSite(site: any): boolean {
    try {
      // 使用TypeSafetyUtil确保安全访问
      const siteObj = TypeSafetyUtil.asObject(site);
      
      // 基本字段验证
      const key = TypeSafetyUtil.getProperty(siteObj, 'key', '');
      if (typeof key !== 'string' || key.trim() === '') {
        Logger.warn(TAG, 'Site missing required field: key');
        return false;
      }
      
      const name = TypeSafetyUtil.getProperty(siteObj, 'name', '');
      if (typeof name !== 'string' || name.trim() === '') {
        Logger.warn(TAG, `Site ${key} missing required field: name`);
        return false;
      }
      
      const api = TypeSafetyUtil.getProperty(siteObj, 'api', '');
      if (typeof api !== 'string' || api.trim() === '') {
        Logger.warn(TAG, `Site ${name} missing required field: api`);
        return false;
      }
      
      // 验证API URL格式
      if (!this.isValidUrl(api)) {
        Logger.warn(TAG, `Site ${name} has invalid API URL: ${api}`);
        return false;
      }
      
      // 验证站点类型
      const type = TypeSafetyUtil.getProperty(siteObj, 'type', '') as string;
      if (type && !this.isValidSiteType(type)) {
        Logger.warn(TAG, `Site ${name} has invalid type: ${type}`);
        (siteObj as Record<string, any>).type = SiteType.VOD;
      }
      
      // 验证解析规则
      const search = TypeSafetyUtil.getProperty(siteObj, 'search', null);
      if (search && typeof search !== 'object') {
        Logger.warn(TAG, `Site ${name} has invalid search config`);
        (siteObj as Record<string, any>).search = { 
          page: true, 
          searchKey: 'wd', 
          pageKey: 'page', 
          resultPath: '', 
          list: [] 
        };
      }
      
      const detail = TypeSafetyUtil.getProperty(siteObj, 'detail', null);
      if (detail && typeof detail !== 'object') {
        Logger.warn(TAG, `Site ${name} has invalid detail config`);
        (siteObj as Record<string, any>).detail = {};
      }
      
      // 确保必要的默认值
      this.ensureDefaultValues(siteObj);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to validate site: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }
  
  /**
   * 检查是否为有效的站点类型
   */
  private isValidSiteType(type: string): boolean {
    const validTypes: SiteType[] = [SiteType.VOD, SiteType.LIVE, SiteType.MIXED];
    return validTypes.includes(type as SiteType);
  }
  
  private ensureDefaultValues(site: Record<string, any>): void {
    site.type = site.type || SiteType.VOD;
    site.searchable = typeof site.searchable === 'boolean' ? site.searchable : true;
    site.categories = Array.isArray(site.categories) ? site.categories : [];
    site.headers = typeof site.headers === 'object' && site.headers !== null ? site.headers : {};
    
    const search = site.search;
    if (search !== null && typeof search === 'object') {
      site.search = search;
    } else {
      site.search = { page: true, searchKey: 'wd', pageKey: 'page', resultPath: '', list: [] };
    }
    
    site.detail = typeof site.detail === 'object' && site.detail !== null ? site.detail : {};
    site.play = typeof site.play === 'object' && site.play !== null ? site.play : {};
    site.filterable = typeof site.filterable === 'boolean' ? site.filterable : false;
    site.filters = Array.isArray(site.filters) ? site.filters : [];
    site.proxy = typeof site.proxy === 'boolean' ? site.proxy : false;
    site.weight = typeof site.weight === 'number' ? site.weight : 0;
    site.enabled = typeof site.enabled === 'boolean' ? site.enabled : true;
    site.updateTime = typeof site.updateTime === 'number' ? site.updateTime : Date.now();
    site.lastCheckTime = typeof site.lastCheckTime === 'number' ? site.lastCheckTime : 0;
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
      if (sitesData !== null && typeof sitesData === 'object' && !Array.isArray(sitesData)) {
        if (this.isFongmiFormat(sitesData as Record<string, unknown>)) {
          return this.convertFongmiFormat(sitesData as Record<string, unknown>);
        }
      }
      
      // 标准数组格式
      const sites: Site[] = [];
      if (Array.isArray(sitesData)) {
        for (const siteData of sitesData) {
          try {
            const site = this.parseSiteItem(siteData as Record<string, unknown>);
            sites.push(site);
          } catch (error) {
            Logger.error(TAG, `Failed to parse site item: ${error instanceof Error ? error.message : String(error)}`);
          }
        }
      }
      
      Logger.info(TAG, `Successfully parsed ${sites.length} sites`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to parse sites configuration: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }
  
  /**
   * 判断是否为Fongmi格式配置
   */
  private isFongmiFormat(config: Record<string, unknown>): boolean {
    if (config === null || typeof config !== 'object' || Array.isArray(config)) return false;
    
    // Fongmi格式通常是对象，每个键对应一个站点
    const keys = Object.keys(config);
    return keys.length > 0 &&
           keys.some(key => {
             const value = config[key];
             return value !== null && typeof value === 'object' && !Array.isArray(value) && 
                    (typeof (value as any).api === 'string' || 
                     typeof (value as any).name === 'string');
           });
  }
  
  /**
   * 转换Fongmi格式配置
   * @param fongmiConfig Fongmi格式配置
   */
  public convertFongmiFormat(fongmiConfig: Record<string, unknown>): Site[] {
    try {
      Logger.info(TAG, 'Converting Fongmi format config');
      
      const sites: Site[] = [];
      const now = Date.now();
      
      // 遍历配置中的每个站点
      for (const [key, value] of Object.entries(fongmiConfig)) {
        if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
          const siteData = value as Record<string, unknown>;
          
          // 转换为标准站点格式，包含所有必需属性
          const site: Site = {
            key: key,
            name: typeof siteData.name === 'string' ? siteData.name : key,
            type: this.detectSiteType(siteData),
            loaderType: 'js' as LoaderType,
            api: typeof siteData.api === 'string' ? siteData.api : '',
            searchConfig: {
              enabled: true
            },
            filterConfig: {
              enabled: false
            },
            performanceConfig: {
              timeout: 30000,
              retryCount: 3,
              cacheEnabled: true,
              cacheDuration: 60
            },
            stats: {
              queryCount: 0,
              errorCount: 0,
              avgResponseTime: 0
            },
            lifecycle: {
              initialized: false,
              loading: false,
              error: false
            },
            enabled: typeof siteData.enabled === 'boolean' ? siteData.enabled : true,
            order: 0,
            createdAt: now,
            updatedAt: now
          };
          
          // 验证并添加到结果列表
          if (this.validateSite(site as any)) {
            sites.push(site);
          }
        }
      }
      
      Logger.info(TAG, `Converted ${sites.length} sites from Fongmi format`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to convert Fongmi format: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 自动检测站点类型
   * @param siteData 站点数据
   */
  public detectSiteType(siteData: Record<string, unknown>): SiteType {
    // 根据站点配置特征自动判断类型
    const siteObj = TypeSafetyUtil.asObject(siteData);
    const type = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteObj, 'type', ''));
    if (type) {
      return this.convertSiteType(type);
    }
    
    // 通过关键词判断
    const name = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteObj, 'name', '')).toLowerCase();
    const api = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteObj, 'api', '')).toLowerCase();
    
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
    return SiteType.MIXED;
  }

  /**
   * 安全解析JSON内容
   * @param content JSON字符串内容
   */
  public parseJsonContent(content: string): any {
    try {
      // 预处理，移除注释和多余空白
      const cleanContent = this.cleanJsonContent(content);
      return JSON.parse(cleanContent);
    } catch (error) {
      Logger.error(TAG, `Failed to parse JSON content: ${error instanceof Error ? error.message : String(error)}`);
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
  private parseSiteItem(siteData: Record<string, unknown>): Site {
    if (siteData === null || typeof siteData !== 'object' || Array.isArray(siteData)) {
      throw new Error('Invalid site data format');
    }
    
    const key = typeof siteData.key === 'string' ? siteData.key : 
                this.generateSiteKey(typeof siteData.name === 'string' ? siteData.name : 'unknown');
    const name = typeof siteData.name === 'string' ? siteData.name : 'Unknown Site';
    const api = typeof siteData.api === 'string' ? siteData.api : 
                typeof siteData.url === 'string' ? siteData.url : '';
    
    const now = Date.now();
    
    // 创建完整的Site对象，包含所有必需属性
    const site: Site = {
      key: key,
      name: name,
      type: this.convertSiteType(typeof siteData.type === 'string' ? siteData.type : ''),
      loaderType: 'js' as LoaderType,
      api: api,
      searchConfig: {
        enabled: true
      },
      filterConfig: {
        enabled: false
      },
      performanceConfig: {
        timeout: 30000,
        retryCount: 3,
        cacheEnabled: true,
        cacheDuration: 60
      },
      stats: {
        queryCount: 0,
        errorCount: 0,
        avgResponseTime: 0
      },
      lifecycle: {
        initialized: false,
        loading: false,
        error: false
      },
      enabled: typeof siteData.enabled === 'boolean' ? siteData.enabled : true,
      order: 0,
      createdAt: now,
      updatedAt: now
    };
    
    if (!this.validateSite(site as any)) {
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
    if (!type) return SiteType.MIXED;
    
    const lowerType = type.toLowerCase();
    if (lowerType === 'vod' || lowerType.includes('点播')) return SiteType.VOD;
    if (lowerType === 'live' || lowerType.includes('直播')) return SiteType.LIVE;
    return SiteType.MIXED;
  }

  /**
   * 转换请求头
   * @param headers 原始请求头
   */
  public convertHeaders(headers: string | Record<string, unknown>): Record<string, string> {
    const result: Record<string, string> = {};
    
    if (!headers) {
      return result;
    }
    
    // 处理不同格式的请求头
    if (typeof headers === 'string') {
      // 字符串格式 "User-Agent: xxx; Referer: yyy"
      headers.split(';').forEach((header: string) => {
        const parts = header.split(':');
        if (parts.length >= 2) {
          const key = parts[0].trim();
          const value = parts.slice(1).join(':').trim();
          result[key] = value;
        }
      });
    } else if (headers && typeof headers === 'object') {
      // 对象格式，手动复制字符串值
      for (const key in headers) {
        if (Object.prototype.hasOwnProperty.call(headers, key)) {
          const value = headers[key];
          result[key] = String(value);
        }
      }
    }
    
    return result;
  }
  
  /**
   * 转换分类配置
   * @param categories 原始分类
   */
  public convertCategories(categories: any): CategoryItem[] {
    const result: CategoryItem[] = [];
    
    if (!categories) {
      return result;
    }
    
    // 处理数组格式分类
    if (Array.isArray(categories)) {
      categories.forEach((cat: any) => {
        if (typeof cat === 'string') {
            const category: CategoryItem = {
              key: cat,
              name: cat
            };
            result.push(category);
          } else if (cat !== null && typeof cat === 'object' && !Array.isArray(cat)) {
            const catObj = cat as Record<string, any>;
            const key = typeof catObj.key === 'string' ? catObj.key : '';
            const name = typeof catObj.name === 'string' ? catObj.name : '';
            if (key && name) {
              const category: CategoryItem = {
                key: key,
                name: name
              };
              result.push(category);
            }
          }
      });
    } 
    // 处理Fongmi格式分类（对象格式）
    else if (categories !== null && typeof categories === 'object' && !Array.isArray(categories)) {
      for (const [key, value] of Object.entries(categories)) {
        const name = typeof value === 'string' ? value : key;
        const category: CategoryItem = {
          key: key,
          name: name
        };
        result.push(category);
      }
    }
    
    // 确保分类唯一
    const uniqueCategories = new Map<string, CategoryItem>();
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
  public convertSearchRules(searchData: Record<string, unknown>): SearchRules {
    if (searchData === null || typeof searchData !== 'object' || Array.isArray(searchData)) {
      return {
        page: true,
        searchKey: 'wd',
        pageKey: 'page',
        resultPath: '',
        list: []
      };
    }
    
    // 标准化搜索规则格式
    const result: SearchRules = {
      // Fongmi格式搜索规则适配
      page: typeof searchData.page === 'boolean' ? searchData.page : true,
      searchKey: typeof searchData.key === 'string' ? searchData.key : 
                typeof searchData.searchKey === 'string' ? searchData.searchKey : 'wd',
      pageKey: typeof searchData.pageKey === 'string' ? searchData.pageKey : 'page',
      resultPath: typeof searchData.resultPath === 'string' ? searchData.resultPath : '',
      list: Array.isArray(searchData.list) ? searchData.list : []
    };
    
    return result;
  }
  
  /**
   * 转换详情页规则
   * @param detailData 原始详情配置
   */
  public convertDetailRules(detailData: Record<string, unknown>): DetailRules {
    if (detailData === null || typeof detailData !== 'object' || Array.isArray(detailData)) {
      return {};
    }
    
    const result: DetailRules = {};
    
    // 手动复制所有属性
    for (const [key, value] of Object.entries(detailData)) {
      (result as any)[key] = value;
    }
    
    return result;
  }
  
  /**
   * 转换播放规则
   * @param playData 原始播放配置
   */
  public convertPlayRules(playData: Record<string, unknown>): PlayRules {
    if (playData === null || typeof playData !== 'object' || Array.isArray(playData)) {
      return { sources: [] };
    }
    
    const result: PlayRules = { sources: [] };
    
    // 手动复制所有属性到sources数组
    for (const [key, value] of Object.entries(playData)) {
      if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
        const valueObj = value as any;
        const playSource: PlaySource = {
          name: typeof valueObj.name === 'string' ? valueObj.name : key,
          rules: typeof valueObj.rules === 'object' && valueObj.rules !== null ? valueObj.rules : {}
        };
        result.sources.push({ key, source: playSource });
      }
    }
    
    return result;
  }
  
  /**
   * 验证URL是否有效
   * @param url 要验证的URL字符串
   */
  private isValidUrl(url: string): boolean {
    if (typeof url !== 'string' || url.trim() === '') {
      return false;
    }
    
    try {
      // 简单的URL验证逻辑
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (error) {
      Logger.error(TAG, `Error validating URL: ${error}`);
      return false;
    }
  }

  /**
   * 解析应用配置
   * @param configContent 配置文件内容
   */
  public parseAppConfig(configContent: string): HarmonyConfig {
    try {
      Logger.info(TAG, 'Parsing application configuration');
      
      const config = this.parseJsonContent(configContent);
      const harmonySection = typeof config.harmony === 'object' && config.harmony !== null ? config.harmony : {};
      const harmonySectionObj = harmonySection as Record<string, any>;
      
      // 创建HarmonyOS专用配置
      const harmonyConfig: HarmonyConfig = {
        enableVoiceAssistant: typeof harmonySectionObj.enableVoiceAssistant === 'boolean' ? harmonySectionObj.enableVoiceAssistant : false,
        enableDeviceFlow: typeof harmonySectionObj.enableDeviceFlow === 'boolean' ? harmonySectionObj.enableDeviceFlow : false,
        enableGestureControl: typeof harmonySectionObj.enableGestureControl === 'boolean' ? harmonySectionObj.enableGestureControl : false,
        enableWidget: typeof harmonySectionObj.enableWidget === 'boolean' ? harmonySectionObj.enableWidget : false,
        enableNotification: typeof harmonySectionObj.enableNotification === 'boolean' ? harmonySectionObj.enableNotification : false,
        enableAutoStart: typeof harmonySectionObj.enableAutoStart === 'boolean' ? harmonySectionObj.enableAutoStart : false,
        enableBackgroundSync: typeof harmonySectionObj.enableBackgroundSync === 'boolean' ? harmonySectionObj.enableBackgroundSync : false,
        enableMultiWindow: typeof harmonySectionObj.enableMultiWindow === 'boolean' ? harmonySectionObj.enableMultiWindow : false,
        enableHiAI: typeof harmonySectionObj.enableHiAI === 'boolean' ? harmonySectionObj.enableHiAI : false,
        deviceSharingEnabled: typeof harmonySectionObj.deviceSharingEnabled === 'boolean' ? harmonySectionObj.deviceSharingEnabled : false,
        notificationChannels: Array.isArray(harmonySectionObj.notificationChannels) ? harmonySectionObj.notificationChannels : [],
        quickActions: Array.isArray(harmonySectionObj.quickActions) ? harmonySectionObj.quickActions : []
      };
      
      return harmonyConfig;
    } catch (error) {
      Logger.error(TAG, `Failed to parse application configuration: ${error instanceof Error ? error.message : String(error)}`);
      // 返回默认配置
      return this.getDefaultConfig();
    }
  }
  
  /**
   * 获取默认配置
   */
  private getDefaultConfig(): HarmonyConfig {
    return {
      enableVoiceAssistant: false,
      enableDeviceFlow: false,
      enableGestureControl: false,
      enableWidget: false,
      enableNotification: false,
      enableAutoStart: false,
      enableBackgroundSync: false,
      enableMultiWindow: false,
      enableHiAI: false,
      deviceSharingEnabled: false,
      notificationChannels: [],
      quickActions: []
    };
  }

}
