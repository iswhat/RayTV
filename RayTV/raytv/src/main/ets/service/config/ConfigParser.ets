// ConfigParser - 配置解析器 | Config parser
// 实现Fongmi配置文件解析和适配功能 | Implement Fongmi config file parsing and adaptation functionality

import TypeSafetyHelper from '../../common/util/TypeSafetyHelper';
import { Site, SiteType, LoaderType } from '../../data/bean/Site';
import { AppConfig, HarmonyConfig, LiveCollection, LiveConfigItem, LiveGroup, LiveChannel } from '../../data/bean/Config';


const TAG = 'ConfigParser';

// 接口定义 | Interface definitions
export interface CategoryItem {
  key: string;
  name: string;
}

// 搜索规则接口 - 替换any和unknown为具体类型 | Search rule interface - replace any and unknown with specific types
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

// Live配置解析中间接口 | Live config parsing intermediate interfaces
export interface LiveGroupConfig {
  group?: string;
  channels?: LiveChannelConfig[];
}

export interface LiveChannelConfig {
  name?: string;
  url?: string;
  urls?: string[];
  epg?: string;
  logo?: string;
}

export interface LiveItemConfig {
  name?: string;
  type?: number;
  playerType?: number;
  url?: string;
  epg?: string;
  logo?: string;
}

// 详情规则接口 - 替换unknown为具体类型 | Detail rule interface - replace unknown with specific types
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

// 播放规则接口 - 替换unknown为具体类型 | Play rule interface - replace unknown with specific types
export interface PlaySource {
  name: string;
  rules: Record<string, SearchRuleItem>;
}

// 站点配置值接口| Site config value interface
export interface SiteConfigValue {
  api?: string;
  name?: string;
}

// 播放源项目接口| Play source item interface
export interface PlaySourceItem {
  key: string;
  source: PlaySource;
}

export interface PlayRules {
  // ArkTS兼容：使用数组存储键值对 | ArkTS compatible: use array to store key-value pairs
  sources: PlaySourceItem[];
}

// 站点配置接口 | Site config interface
export interface SiteConfig {
  type?: SiteType;
  searchable?: boolean;
  categories?: Array<Record<string, string | number | boolean>>;
  headers?: Record<string, string>;
  search?: SearchRules;
  detail?: Record<string, string | number | boolean | Record<string, string | number | boolean>>;
  play?: Record<string, string | number | boolean | Record<string, string | number | boolean>>;
  filterable?: boolean;
  filters?: Array<Record<string, string | number | boolean>>;
  proxy?: boolean;
  weight?: number;
  enabled?: boolean;
  updateTime?: number;
  lastCheckTime?: number;
}

/**
 * 配置解析器，负责解析和适配各种格式的配置文件| Config parser, responsible for parsing and adapting various format config files
 */
export class ConfigParser {
  private static instance: ConfigParser | null = null;
  
  private constructor() {}
  
  /**
   * 获取单例实例 | Get singleton instance
   * @returns ConfigParser实例 | ConfigParser instance
   */
  public static getInstance(): ConfigParser {
    if (!ConfigParser.instance) {
      ConfigParser.instance = new ConfigParser();
    }
    return ConfigParser.instance;
  }
  
  /**
   * 获取对象的所有键 | Get all keys of object
   * 使用TypeSafetyUtil确保类型安全 | Use TypeSafetyUtil to ensure type safety
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    if (obj === null || typeof obj !== 'object') {
      return [];
    }
    // 使用Object.keys替代for...in循环
    return Object.keys(obj);
  }

  /**
   * 验证站点配置 | Validate site config
   * @param site 站点配置 | Site config
   */
  public validateSite(site: SiteConfig | Site): boolean {
    try {
      // 使用TypeSafetyUtil确保安全访问 | Use TypeSafetyUtil to ensure safe access
      const siteObj = TypeSafetyHelper.safeObject(site);
      
      // 基本字段验证 | Basic field validation
      const key = TypeSafetyHelper.safeGet(siteObj, 'key', '');
      if (typeof key !== 'string' || key.trim() === '') {
        console.warn(TAG + ': Site missing required field: key');
        return false;
      }
      
      const name = TypeSafetyHelper.safeGet(siteObj, 'name', '');
      if (typeof name !== 'string' || name.trim() === '') {
        console.warn(TAG + `: Site ${key} missing required field: name`);
        return false;
      }
      
      const api = TypeSafetyHelper.safeGet(siteObj, 'api', '');
      if (typeof api !== 'string' || api.trim() === '') {
        console.warn(TAG + `: Site ${name} missing required field: api`);
        return false;
      }
      
      // 验证API URL格式 | Validate API URL format
      if (!this.isValidUrl(api)) {
        console.warn(TAG + `: Site ${name} has invalid API URL: ${api}`);
        return false;
      }
      
      // 验证站点类型 | Validate site type
      const type = TypeSafetyHelper.safeGet(siteObj, 'type', '') as string;
      if (type && !this.isValidSiteType(type)) {
        console.warn(TAG + `: Site ${name} has invalid type: ${type}`);
        (siteObj as SiteConfig).type = SiteType.VOD;
      }
      
      // 验证解析规则 | Validate parsing rules
      const search = TypeSafetyHelper.safeGet(siteObj, 'search', null);
      if (search && typeof search !== 'object') {
        console.warn(TAG + `: Site ${name} has invalid search config`);
        const defaultSearchRules: SearchRules = { 
          page: true, 
          searchKey: 'wd', 
          pageKey: 'page', 
          resultPath: '', 
          list: [] 
        };
        (siteObj as SiteConfig).search = defaultSearchRules;
      }
      
      const detail = TypeSafetyHelper.safeGet(siteObj, 'detail', null);
      if (detail && typeof detail !== 'object') {
        console.warn(TAG + `: Site ${name} has invalid detail config`);
        (siteObj as SiteConfig).detail = {};
      }
      
      // 确保必需的默认值| Ensure required default values
      this.ensureDefaultValues(siteObj as SiteConfig);

      return true;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to validate site: ${err.message}`);
      return false;
    }
  }
  
  /**
   * 检查是否为有效的站点类型| Check if it's valid site type
   */
  private isValidSiteType(type: string): boolean {
    const validTypes: SiteType[] = [SiteType.VOD, SiteType.LIVE, SiteType.MIXED];
    return validTypes.includes(type as SiteType);
  }
  
  private ensureDefaultValues(site: SiteConfig): void {
    site.type = site.type || SiteType.VOD;
    site.searchable = typeof site.searchable === 'boolean' ? site.searchable : true;
    site.categories = Array.isArray(site.categories) ? site.categories : [];
    site.headers = typeof site.headers === 'object' && site.headers !== null ? site.headers : {};
    
    const search = site.search;
    if (search !== null && typeof search === 'object') {
      site.search = search;
    } else {
      // 使用SearchRules接口确保类型安全 | Use SearchRules interface to ensure type safety
      const defaultSearchRules: SearchRules = { 
        page: true, 
        searchKey: 'wd', 
        pageKey: 'page', 
        resultPath: '', 
        list: [] 
      };
      site.search = defaultSearchRules;
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
   * 解析站点配置 | Parse site config
   * @param configContent 配置文件内容 | Config file content
   * @returns 站点列表 | Site list
   */
  public parseSites(configContent: string): Site[] {
    try {
      console.info(TAG + ': Parsing sites configuration');
      
      // 尝试解析为JSON | Try to parse as JSON
      const config = this.parseJsonContent(configContent);
      
      // 支持不同格式的配置结构| Support different format config structures
      const sitesData = config.sites || config.subscriptions || config.data || config;
      if (!sitesData) {
        throw new Error('Invalid sites configuration format');
      }
      
      // 检查是否为Fongmi格式 | Check if it's Fongmi format
      if (sitesData !== null && typeof sitesData === 'object' && !Array.isArray(sitesData)) {
        if (this.isFongmiFormat(sitesData as Record<string, SiteConfigValue>)) {
          return this.convertFongmiFormat(sitesData as Record<string, SiteConfigValue>);
        }
      }
      
      // 标准数组格式 | Standard array format
      const sites: Site[] = [];
      if (Array.isArray(sitesData)) {
        for (const siteData of sitesData as Array<Record<string, string | number | boolean | Record<string, string | number | boolean>>>) {
          try {
            const site = this.parseSiteItem(siteData);
            sites.push(site);
          } catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            console.error(TAG + `: Failed to parse site item: ${err.message}`);
          }
        }
      }

      console.info(TAG + `: Successfully parsed ${sites.length} sites`);
      return sites;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to parse sites configuration: ${err.message}`);
      throw err;
    }
  }
  
  /**
   * 判断是否为Fongmi格式配置 | Determine if it's Fongmi format config
   */
  private isFongmiFormat(config: Record<string, SiteConfigValue>): boolean {
    if (config === null || typeof config !== 'object' || Array.isArray(config)) return false;
    
    // Fongmi格式通常是对象，每个键对应一个站点 | Fongmi format is usually object, each key corresponds to a site
    const keys = this.getObjectKeys(config);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = config[key];
      if (value !== null && typeof value === 'object' && !Array.isArray(value) && 
          (typeof value.api === 'string' || 
           typeof value.name === 'string')) {
        return true;
      }
    }
    return false;
  }
  
  /**
   * 转换Fongmi格式配置 | Convert Fongmi format config
   * @param fongmiConfig Fongmi格式配置 | Fongmi format config
   */
  public convertFongmiFormat(fongmiConfig: Record<string, SiteConfigValue>): Site[] {
    try {
      console.info(TAG + ': Converting Fongmi format config');
      
      const sites: Site[] = [];
      const now = Date.now();
      
      // 遍历配置中的每个站点 | Iterate each site in config
      const configKeys = this.getObjectKeys(fongmiConfig);
      for (let i = 0; i < configKeys.length; i++) {
        const key = configKeys[i];
        const value = fongmiConfig[key];
        if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
          const siteData = value as Record<string, string | number | boolean>;
          
          // 转换为标准站点格式，包含所有必需属性 | Convert to standard site format, include all required properties
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
          
          // 验证并添加到结果列表 | Validate and add to result list
          if (this.validateSite(site)) {
            sites.push(site);
          }
        }
      }

      console.info(TAG + `: Converted ${sites.length} sites from Fongmi format`);
      return sites;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to convert Fongmi format: ${err.message}`);
      return [];
    }
  }
  
  /**
   * 自动检测站点类型 | Auto detect site type
   * @param siteData 站点数据 | Site data
   */
  public detectSiteType(siteData: Record<string, string | number | boolean | Record<string, string | number | boolean>>): SiteType {
    // 根据站点配置特征自动判断类型 | Auto detect type based on site config features
    const siteObj = TypeSafetyHelper.safeObject(siteData);
    const type = TypeSafetyHelper.safeString(TypeSafetyHelper.safeGet(siteObj, 'type', ''));
    if (type) {
      return this.convertSiteType(type);
    }
    
    // 通过关键词判断| Determine by keywords
    const name = TypeSafetyHelper.safeString(TypeSafetyHelper.safeGet(siteObj, 'name', '')).toLowerCase();
    const api = TypeSafetyHelper.safeString(TypeSafetyHelper.safeGet(siteObj, 'api', '')).toLowerCase();
    
    if (name.includes('live') || name.includes('直播') || 
        api.includes('live') || api.includes('zhibo')) {
      return SiteType.LIVE;
    }
    
    if (name.includes('vod') || name.includes('点播') || 
        name.includes('影视') || name.includes('tv') || 
        name.includes('电影')) {
      return SiteType.VOD;
    }
    
    // 默认类型 | Default type
    return SiteType.MIXED;
  }

  /**
   * 安全解析JSON内容 | Safe parse JSON content
   * @param content JSON字符串内容| JSON string content
   */
  public parseJsonContent(content: string): Record<string, string | number | boolean | Record<string, string | number | boolean | string[]>> {
    try {
      // 预处理，去除注释和多余空格| Preprocess, remove comments and extra whitespace
      const cleanContent = this.cleanJsonContent(content);
      return JSON.parse(cleanContent) as Record<string, string | number | boolean | Record<string, string | number | boolean | string[]>>;
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to parse JSON content: ${err.message}`);
      throw new Error('Invalid JSON format');
    }
  }
  
  /**
   * 清理JSON内容，去除注释和无效字符 | Clean JSON content, remove comments and invalid characters
   * @param content 原始JSON内容 | Original JSON content
   */
  private cleanJsonContent(content: string): string {
    // 去除单行注释 | Remove single line comments
    let clean = content.replace(/\/\/.*$/gm, '');
    // 去除多行注释 | Remove multi-line comments
    clean = clean.replace(/\/\*[\s\S]*?\*\//g, '');
    // 去除多余空白字符 | Remove extra whitespace
    clean = clean.trim();
    return clean;
  }
  
  /**
 * 解析单个站点配置项| Parse single site config item
 * @param siteData 站点数据 | Site data
 */
  private parseSiteItem(siteData: Record<string, string | number | boolean | Record<string, string | number | boolean>>): Site {
    if (siteData === null || typeof siteData !== 'object' || Array.isArray(siteData)) {
      throw new Error('Invalid site data format');
    }
    
    const key = typeof siteData.key === 'string' ? siteData.key : 
                this.generateSiteKey(typeof siteData.name === 'string' ? siteData.name : 'unknown');
    const name = typeof siteData.name === 'string' ? siteData.name : 'Unknown Site';
    const api = typeof siteData.api === 'string' ? siteData.api : 
                typeof siteData.url === 'string' ? siteData.url : '';
    
    const now = Date.now();
    
    // 创建完整的Site对象，包含所有必需属性| Create complete Site object, include all required properties
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
    
    if (!this.validateSite(site)) {
      throw new Error(`Invalid site configuration for: ${site.name}`);
    }
    
    return site;
  }
  
  /**
 * 生成站点唯一键| Generate site unique key
 * @param name 站点名称 | Site name
 */
  private generateSiteKey(name: string): string {
    return name.toLowerCase().replace(/[^a-z0-9]/g, '_');
  }
  
  /**
   * 转换站点类型 | Convert site type
   * @param type 原始类型 | Original type
   */
  private convertSiteType(type?: string): SiteType {
    if (!type) return SiteType.MIXED;
    
    const lowerType = type.toLowerCase();
    if (lowerType === 'vod' || lowerType.includes('点播')) return SiteType.VOD;
    if (lowerType === 'live' || lowerType.includes('直播')) return SiteType.LIVE;
    return SiteType.MIXED;
  }

  /**
   * 转换请求头 | Convert request headers
   * @param headers 原始请求头 | Original request headers
   */
  public convertHeaders(headers: string | Record<string, string | number | boolean>): Record<string, string> {
    const result: Record<string, string> = {};
    
    if (!headers) {
      return result;
    }
    
    // 处理不同格式的请求头 | Process different format request headers
    if (typeof headers === 'string') {
      // 字符串格式 "User-Agent: xxx; Referer: yyy" | String format "User-Agent: xxx; Referer: yyy"
      headers.split(';').forEach((header: string) => {
        const parts = header.split(':');
        if (parts.length >= 2) {
          const key = parts[0].trim();
          const value = parts.slice(1).join(':').trim();
          result[key] = value;
        }
      });
    } else if (headers && typeof headers === 'object') {
      // 对象格式，手动复制为字符串值 | Object format, manually copy to string values
      const keys = this.getObjectKeys(headers);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = headers[key];
        result[key] = String(value);
      }
    }
    
    return result;
  }
  
  /**
   * 转换分类配置 | Convert category config
   * @param categories 原始分类 | Original categories
   */
  public convertCategories(categories: string[] | Record<string, string | number | boolean | Record<string, string | number | boolean>>): CategoryItem[] {
    const result: CategoryItem[] = [];
    
    if (!categories) {
      return result;
    }
    
    // 处理数组格式分类 | Process array format categories
    if (Array.isArray(categories)) {
      categories.forEach((cat) => {
        if (typeof cat === 'string') {
            const category: CategoryItem = {
              key: cat,
              name: cat
            };
            result.push(category);
          } else if (cat !== null && typeof cat === 'object' && !Array.isArray(cat)) {
            const catObj = cat as Record<string, string>;
            const key = catObj.key || '';
            const name = catObj.name || '';
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
    // 处理Fongmi格式分类（对象格式） | Process Fongmi format categories (object format)
    else if (categories !== null && typeof categories === 'object' && !Array.isArray(categories)) {
      const categoryKeys = this.getObjectKeys(categories);
      for (let i = 0; i < categoryKeys.length; i++) {
        const key = categoryKeys[i];
        const value = categories[key];
        const name = typeof value === 'string' ? value : key;
        const category: CategoryItem = {
          key: key,
          name: name
        };
        result.push(category);
      }
    }
    
    // 确保分类唯一 | Ensure categories unique
    const uniqueCategories = new Map<string, CategoryItem>();
    result.forEach(cat => {
      if (!uniqueCategories.has(cat.key)) {
        uniqueCategories.set(cat.key, cat);
      }
    });
    
    return Array.from(uniqueCategories.values());
  }

  /**
   * 转换搜索规则 | Convert search rules
   * @param searchData 原始搜索配置 | Original search config
   */
  public convertSearchRules(searchData: Record<string, string | number | boolean | Record<string, string | number | boolean>>): SearchRules {
    if (searchData === null || typeof searchData !== 'object' || Array.isArray(searchData)) {
      return {
        page: true,
        searchKey: 'wd',
        pageKey: 'page',
        resultPath: '',
        list: []
      };
    }
    
    // 标准化搜索规则格式| Standardize search rule format
    const result: SearchRules = {
      // Fongmi格式搜索规则适配 | Fongmi format search rule adaptation
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
   * 转换详情规则 | Convert detail rules
   * @param detailData 原始详情配置 | Original detail config
   */
  public convertDetailRules(detailData: Record<string, string | number | boolean | Record<string, string | number | boolean>>): DetailRules {
    if (detailData === null || typeof detailData !== 'object' || Array.isArray(detailData)) {
      return {};
    }
    
    const result: DetailRules = {};
    
    // 手动复制所有属性，确保类型安全 | Manually copy all properties, ensure type safety
    const keys = this.getObjectKeys(detailData);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = detailData[key];
      if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
        // 直接使用Record类型，无需转换 | Directly use Record type, no need to convert
        const recordValue = value as Record<string, string | number | boolean>;
        const searchRuleItem: SearchRuleItem = {
          name: (recordValue.name as string) || '',
          regex: recordValue.regex as string,
          fixed: recordValue.fixed as string,
          type: recordValue.type as string,
          filter: (recordValue.filter as boolean) || false
        };
        // 使用switch语句替代索引访问，确保类型安全 | Use switch statement instead of index access, ensure type safety
        switch (key) {
          case 'title':
            result.title = searchRuleItem;
            break;
          case 'cover':
            result.cover = searchRuleItem;
            break;
          case 'desc':
            result.desc = searchRuleItem;
            break;
          case 'director':
            result.director = searchRuleItem;
            break;
          case 'actor':
            result.actor = searchRuleItem;
            break;
          case 'year':
            result.year = searchRuleItem;
            break;
          case 'area':
            result.area = searchRuleItem;
            break;
          case 'update':
            result.update = searchRuleItem;
            break;
          case 'score':
            result.score = searchRuleItem;
            break;
          case 'type':
            result.type = searchRuleItem;
            break;
          case 'playlist':
            result.playlist = searchRuleItem;
            break;
          case 'tags':
            result.tags = searchRuleItem;
            break;
        }
      }
    }
    
    return result;
  }
  
  /**
   * 转换播放规则 | Convert play rules
   * @param playData 原始播放配置 | Original play config
   */
  public convertPlayRules(playData: Record<string, string | number | boolean | Record<string, string | number | boolean>>): PlayRules {
    if (playData === null || typeof playData !== 'object' || Array.isArray(playData)) {
      return {
        sources: []
      };
    }
    
    const result: PlayRules = {
      sources: []
    };
    
    // 手动复制所有属性到sources数组 | Manually copy all properties to sources array
    const playDataKeys = this.getObjectKeys(playData);
    for (let i = 0; i < playDataKeys.length; i++) {
      const key = playDataKeys[i];
      const value = playData[key];
      if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
        const valueObj = value as Record<string, string | number | boolean | Record<string, string | number | boolean>>;
        // 处理rules对象 | Process rules object
        const rules: Record<string, SearchRuleItem> = {};
        const sourceRules = valueObj.rules;
        if (sourceRules !== null && typeof sourceRules === 'object' && !Array.isArray(sourceRules)) {
          const sourceRulesObj = sourceRules as Record<string, string | number | boolean | SearchRuleItem>;
          const sourceRulesKeys = this.getObjectKeys(sourceRulesObj);
          for (let j = 0; j < sourceRulesKeys.length; j++) {
            const ruleKey = sourceRulesKeys[j];
            const ruleValue = sourceRulesObj[ruleKey];
            if (ruleValue !== null && typeof ruleValue === 'object' && !Array.isArray(ruleValue)) {
              // 直接使用SearchRuleItem类型 | Directly use SearchRuleItem type
              const searchRuleItem = ruleValue as SearchRuleItem;
              // 确保SearchRuleItem有name属性 | Ensure SearchRuleItem has name property
              rules[ruleKey] = {
                name: searchRuleItem.name || ruleKey,
                regex: searchRuleItem.regex,
                fixed: searchRuleItem.fixed,
                type: searchRuleItem.type,
                filter: searchRuleItem.filter || false
              };
            }
          }
        }
        const playSource: PlaySource = {
          name: typeof valueObj.name === 'string' ? valueObj.name : key,
          rules: rules
        };
        result.sources.push({ key: key, source: playSource });
      }
    }
    
    return result;
  }
  
  /**
   * 验证URL是否有效 | Validate if URL is valid
   * @param url 要验证的URL字符串 | URL string to validate
   */
  private isValidUrl(url: string): boolean {
    if (typeof url !== 'string' || url.trim() === '') {
      return false;
    }
    
    try {
      // 简单的URL验证逻辑 | Simple URL validation logic
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Error validating URL: ${err.message}`);
      return false;
    }
  }

  /**
   * 解析应用配置 | Parse application config
   * @param configContent 配置文件内容 | Config file content
   */
  public parseAppConfig(configContent: string): HarmonyConfig {
    try {
      console.info(TAG + ': Parsing application configuration');
      
      const config = this.parseJsonContent(configContent);
      const harmonySection = typeof config.harmony === 'object' && config.harmony !== null ? config.harmony : {} as Record<string, string | number | boolean | string[]>;
      const harmonySectionObj = harmonySection as Record<string, string | number | boolean | string[]>;
      
      // 创建HarmonyOS专用配置 | Create HarmonyOS specific config
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
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to parse application configuration: ${err.message}`);
      // 返回默认配置 | Return default config
      return this.getDefaultConfig();
    }
  }
  
  /**
   * 解析直播配置 | Parse live config
   * @param configContent 配置文件内容 | Config file content
   */
  public parseLives(configContent: string): LiveCollection {
    try {
      console.info(TAG + ': Parsing live configuration');
      
      const config = this.parseJsonContent(configContent);
      const livesData = config.lives || [];
      
      if (!Array.isArray(livesData)) {
        console.warn(TAG + ': Invalid lives configuration format, expected array');
        return { lives: [] };
      }
      
      const lives: (LiveConfigItem | LiveGroup)[] = [];
      
      for (const item of livesData) {
        if (typeof item === 'object' && item !== null) {
          // 检查是否为分组格式：检查是否有 group 属性且 channels 是数组| Check if it's group format: check if there's group property and channels is array
          const groupObj = item as LiveGroupConfig;
          if (typeof groupObj.group === 'string' && Array.isArray(groupObj.channels)) {
            // 分组格式 | Group format
            const group: LiveGroup = {
              group: groupObj.group,
              channels: []
            };
            
            // 解析频道列表 | Parse channel list
            const channels = groupObj.channels as LiveChannelConfig[];
            for (const channel of channels) {
              if (typeof channel === 'object' && channel !== null) {
                const liveChannel: LiveChannel = {
                  name: typeof channel.name === 'string' ? channel.name : '未知频道',
                  url: typeof channel.url === 'string' ? channel.url : undefined,
                  urls: Array.isArray(channel.urls) ? channel.urls : undefined,
                  epg: typeof channel.epg === 'string' ? channel.epg : undefined,
                  logo: typeof channel.logo === 'string' ? channel.logo : undefined
                };
                group.channels.push(liveChannel);
              }
            }
            lives.push(group);
          } else {
            // 直接直播项目格式 | Direct live item format
            const itemObj = item as LiveItemConfig;
            const liveConfig: LiveConfigItem = {
              name: typeof itemObj.name === 'string' ? itemObj.name : '未知直播',
              type: typeof itemObj.type === 'number' ? itemObj.type : 0,
              playerType: typeof itemObj.playerType === 'number' ? itemObj.playerType : undefined,
              url: typeof itemObj.url === 'string' ? itemObj.url : undefined,
              epg: typeof itemObj.epg === 'string' ? itemObj.epg : undefined,
              logo: typeof itemObj.logo === 'string' ? itemObj.logo : undefined
            };
            lives.push(liveConfig);
          }
        }
      }
      
      console.info(TAG + `: Successfully parsed ${lives.length} live configurations`);
      return {
        lives,
        version: typeof config.version === 'string' ? config.version : undefined,
        updatedAt: typeof config.updatedAt === 'number' ? config.updatedAt : Date.now()
      };
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: Failed to parse live configuration: ${err.message}`);
      return { lives: [] };
    }
  }
  
  /**
   * 获取默认配置 | Get default config
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

export default ConfigParser;

