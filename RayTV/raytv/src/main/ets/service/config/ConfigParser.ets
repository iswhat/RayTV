// ConfigParser - 配置解析�?// 实现Fongmi配置文件解析和适配功能
import Logger from '../../common/util/Logger';
import { TypeSafetyUtil } from '../../common/util/TypeSafetyUtil';
import { Site, SiteType } from '../../data/bean/Site';
import { AppConfig, HarmonyConfig } from '../../data/bean/Config';
import type { Record } from '../../types/commonTypes';

const TAG = 'ConfigParser';

// 接口定义
export interface CategoryItem {
  key: string;
  name: string;
}

// 搜索规则接口 - 替换any和unknown为具体类�?export interface SearchRuleItem {
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

// 详情规则接口 - 替换unknown为具体类�?export interface DetailRules {
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

// 播放规则接口 - 替换unknown为具体类�?export interface PlaySource {
  name: string;
  rules: Record<string, SearchRuleItem>;
}

export interface PlayRules {
  // ArkTS兼容：使用数组替代索引签�?  sources: Array<{
    key: string;
    source: PlaySource;
  }>;
}

/**
 * 配置解析器，负责解析和适配各种格式的配置文�? */
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
   * 获取对象的所有键
   * 使用TypeSafetyUtil确保类型安全
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    return TypeSafetyUtil.getObjectKeys(obj);
  }

  /**
   * 验证站点配置
   * @param site 站点配置
   */
  public validateSite(site: Record<string, string | number | boolean | null>): site is Site {
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
        TypeSafetyUtil.setProperty(siteObj, 'type', SiteType.ALL);
      }
      
      // 验证解析规则
      const search = TypeSafetyUtil.getProperty(siteObj, 'search', null);
      if (search && typeof search !== 'object') {
        Logger.warn(TAG, `Site ${name} has invalid search config`);
        TypeSafetyUtil.setProperty(siteObj, 'search', { 
          page: true, 
          searchKey: 'wd', 
          pageKey: 'page', 
          resultPath: '', 
          list: [] 
        });
      }
      
      const detail = TypeSafetyUtil.getProperty(siteObj, 'detail', null);
      if (detail && typeof detail !== 'object') {
        Logger.warn(TAG, `Site ${name} has invalid detail config`);
        TypeSafetyUtil.setProperty(siteObj, 'detail', {});
      }
      
      // 确保必要的默认�?      this.ensureDefaultValues(siteObj);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Error validating site: ${error}`);
      return false;
    }
  }
  
  /**
   * 检查是否为有效的站点类�?   */
  private isValidSiteType(type: string): boolean {
    const validTypes: SiteType[] = [SiteType.ALL, SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType instanceof Error ? SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType : new Error(String(SiteType.MOVIE, SiteType.SERIES, SiteType.ANIME, SiteType.VOD, SiteType.LIVE];
    return validTypes.includes(type as SiteType)))))));
  }
  private ensureDefaultValues(site: Record<string, string | number | boolean | object | null>): void {
    TypeSafetyUtil.setProperty(site, 'type', TypeSafetyUtil.getProperty(site, 'type', SiteType.ALL));
    TypeSafetyUtil.setProperty(site, 'searchable', TypeSafetyUtil.getProperty(site, 'searchable', true));
    TypeSafetyUtil.setProperty(site, 'categories', TypeSafetyUtil.asArray(TypeSafetyUtil.getProperty(site, 'categories', [])));
    TypeSafetyUtil.setProperty(site, 'headers', TypeSafetyUtil.asObject(TypeSafetyUtil.getProperty(site, 'headers', {})));
    
    const search = TypeSafetyUtil.getProperty(site, 'search', null);
    if (search !== null && typeof search === 'object') {
      site.search = search as Record<string, string | number | boolean | object | null>;
    } else {
      site.search = { page: true, searchKey: 'wd', pageKey: 'page', resultPath: '', list: [] };
    }
    
    TypeSafetyUtil.setProperty(site, 'detail', TypeSafetyUtil.asObject(TypeSafetyUtil.getProperty(site, 'detail', {})));
    TypeSafetyUtil.setProperty(site, 'play', TypeSafetyUtil.asObject(TypeSafetyUtil.getProperty(site, 'play', {})));
    TypeSafetyUtil.setProperty(site, 'filterable', TypeSafetyUtil.getProperty(site, 'filterable', false));
    TypeSafetyUtil.setProperty(site, 'filters', TypeSafetyUtil.asArray(TypeSafetyUtil.getProperty(site, 'filters', [])));
    TypeSafetyUtil.setProperty(site, 'proxy', TypeSafetyUtil.getProperty(site, 'proxy', false));
    TypeSafetyUtil.setProperty(site, 'weight', TypeSafetyUtil.asNumber(TypeSafetyUtil.getProperty(site, 'weight', 0)));
    TypeSafetyUtil.setProperty(site, 'enabled', TypeSafetyUtil.getProperty(site, 'enabled', true));
    TypeSafetyUtil.setProperty(site, 'updateTime', TypeSafetyUtil.asNumber(TypeSafetyUtil.getProperty(site, 'updateTime', Date.now())));
    TypeSafetyUtil.setProperty(site, 'lastCheckTime', TypeSafetyUtil.asNumber(TypeSafetyUtil.getProperty(site, 'lastCheckTime', 0)));
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
      
      // 支持不同格式的配置结�?      const sitesData = config.sites || config.subscriptions || config.data || config;
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
      
      Logger.info(TAG, `Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites` instanceof Error ? `Successfully parsed ${sites.length} sites` : new Error(String(`Successfully parsed ${sites.length} sites`)))))));
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to parse sites configuration: ${error}`);
      throw error;
    }
  }
  
  /**
   * 判断是否为Fongmi格式配置
   */
  private isFongmiFormat(config: Record<string, string | number | boolean | null> instanceof Error ? string | number | boolean | null> : new Error(String(string | number | boolean | null>))): boolean {
    if (!TypeSafetyUtil.isValidObject(config)) return false;
    
    // Fongmi格式通常是对象，每个键对应一个站�?    const configObj = TypeSafetyUtil.asObject(config);
    return !Array.isArray(config) && 
           this.getObjectKeys(configObj).length > 0 &&
           this.getObjectKeys(configObj).some(key => {
             // 先将configObj转换为更宽泛的类型，支持对象�?             const broadConfigObj = configObj as Record<string, string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null instanceof Error ? string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null : new Error(String(string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null instanceof Error ? string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null instanceof Error ? string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null : new Error(String(string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null : new Error(String(string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null instanceof Error ? string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null : new Error(String(string | number | boolean | object | null>;
             // 使用getNestedProperty获取嵌套对象
             const value = TypeSafetyUtil.getNestedProperty(broadConfigObj, key, null)))));
             return TypeSafetyUtil.isValidObject(value) && 
                    (TypeSafetyUtil.getNestedProperty(value as Record<string, string | number | boolean | object | null>, 'api', null) !== null || 
                     TypeSafetyUtil.getNestedProperty(value as Record<string, string | number | boolean | object | null>, 'name', null) !== null);
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
      
      // 遍历配置中的每个站点
      for (const [key, value] of TypeSafetyUtil.getObjectEntries(fongmiConfig)) {
        if (TypeSafetyUtil.isValidObject(value)) {
          const siteData = TypeSafetyUtil.asObject(value);
          
          // 转换为标准站点格�?          const site: Site = {
            key: key,
            name: TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'name', key)),
            type: this.detectSiteType(siteData),
            api: TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'api', '')),
            searchable: TypeSafetyUtil.getProperty(siteData, 'searchable', true),
            categories: this.convertCategories(TypeSafetyUtil.getProperty(siteData, 'categories', [])),
            headers: this.convertHeaders(TypeSafetyUtil.getProperty(siteData, 'headers', TypeSafetyUtil.getProperty(siteData, 'header', {}))),
            search: this.convertSearchRules(TypeSafetyUtil.getProperty(siteData, 'search', null)),
            detail: this.convertDetailRules(TypeSafetyUtil.getProperty(siteData, 'detail', null)),
            play: this.convertPlayRules(TypeSafetyUtil.getProperty(siteData, 'play', null)),
            filterable: TypeSafetyUtil.getProperty(siteData, 'filterable', false),
            filters: TypeSafetyUtil.asArray(TypeSafetyUtil.getProperty(siteData, 'filters', [])),
            proxy: TypeSafetyUtil.getProperty(siteData, 'proxy', false),
            weight: TypeSafetyUtil.asNumber(TypeSafetyUtil.getProperty(siteData, 'weight', 0)),
            enabled: TypeSafetyUtil.getProperty(siteData, 'enabled', true),
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
   * 自动检测站点类�?   * @param siteData 站点数据
   */
  public detectSiteType(siteData: Record<string, unknown> instanceof Error ? unknown> : new Error(String(unknown> instanceof Error ? unknown> instanceof Error ? unknown> : new Error(String(unknown> : new Error(String(unknown> instanceof Error ? unknown> : new Error(String(unknown> instanceof Error ? unknown> instanceof Error ? unknown> : new Error(String(unknown> instanceof Error ? unknown> instanceof Error ? unknown> : new Error(String(unknown> : new Error(String(unknown> instanceof Error ? unknown> : new Error(String(unknown> : new Error(String(unknown> instanceof Error ? unknown> : new Error(String(unknown> instanceof Error ? unknown> instanceof Error ? unknown> : new Error(String(unknown> : new Error(String(unknown> instanceof Error ? unknown> : new Error(String(unknown>))))))): SiteType {
    // 根据站点配置特征自动判断类型
    const type = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'type', ''));
    if (type) {
      return this.convertSiteType(type);
    }
    
    // 通过关键词判�?    const name = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'name', '')).toLowerCase();
    const api = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'api', '')).toLowerCase();
    
    if (name.includes('live') || name.includes('直播') || 
        api.includes('live') || api.includes('zhibo')) {
      return SiteType.LIVE;
    }
    
    if (name.includes('vod') || name.includes('点播') || 
        name.includes('电影') || name.includes('tv') || 
        name.includes('电视�?)) {
      return SiteType.VOD;
    }
    
    // 默认类型
    return SiteType.ALL;
  }

  /**
   * 安全解析JSON内容
   * @param content JSON字符串内�?   */
  public parseJsonContent(content: string): Record<string, unknown> {
    try {
      // 预处理，移除注释和多余空�?      const cleanContent = this.cleanJsonContent(content);
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
    let clean = content.replace(/\/\/.*$/gm, '' instanceof Error ? '' : new Error(String('' instanceof Error ? '' instanceof Error ? '' : new Error(String('' : new Error(String('' instanceof Error ? '' : new Error(String('' instanceof Error ? '' instanceof Error ? '' : new Error(String('' instanceof Error ? '' instanceof Error ? '' : new Error(String('' : new Error(String('' instanceof Error ? '' : new Error(String('' : new Error(String('' instanceof Error ? '' : new Error(String('' instanceof Error ? '' instanceof Error ? '' : new Error(String('' : new Error(String('' instanceof Error ? '' : new Error(String('')))))));
    // 移除多行注释
    clean = clean.replace(/\/\*[\s\S]*?\*\//g, '');
    // 移除多余空白字符
    clean = clean.trim();
    return clean;
  }
  
  /**
   * 解析单个站点配置�?   * @param siteData 站点数据
   */
  private parseSiteItem(siteData: Record<string, unknown>): Site {
    if (!TypeSafetyUtil.isValidObject(siteData)) {
      throw new Error('Invalid site data format');
    }
    
    const key = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'key', '')) || 
                this.generateSiteKey(TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'name', 'unknown')));
    const name = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'name', 'Unknown Site'));
    const api = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'api', '')) || 
                TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'url', ''));
    
    const site: Site = {
      key: key,
      name: name,
      type: this.convertSiteType(TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(siteData, 'type', ''))),
      api: api,
      searchable: TypeSafetyUtil.getProperty(siteData, 'searchable', true),
      categories: this.convertCategories(TypeSafetyUtil.getProperty(siteData, 'categories', null)),
      headers: this.convertHeaders(TypeSafetyUtil.getProperty(siteData, 'headers', TypeSafetyUtil.getProperty(siteData, 'header', null))),
      search: this.convertSearchRules(TypeSafetyUtil.getProperty(siteData, 'search', null)),
      detail: this.convertDetailRules(TypeSafetyUtil.getProperty(siteData, 'detail', null)),
      play: this.convertPlayRules(TypeSafetyUtil.getProperty(siteData, 'play', null)),
      filterable: TypeSafetyUtil.getProperty(siteData, 'filterable', false),
      filters: TypeSafetyUtil.asArray(TypeSafetyUtil.getProperty(siteData, 'filters', [])),
      proxy: TypeSafetyUtil.getProperty(siteData, 'proxy', false),
      weight: TypeSafetyUtil.asNumber(TypeSafetyUtil.getProperty(siteData, 'weight', 0)),
      enabled: TypeSafetyUtil.getProperty(siteData, 'enabled', true),
      updateTime: Date.now(),
      lastCheckTime: 0
    };
    
    if (!this.validateSite(site)) {
      throw new Error(`Invalid site configuration for: ${site.name}`);
    }
    
    return site;
  }
  
  /**
   * 生成站点唯一�?   * @param name 站点名称
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
   * 转换请求�?   * @param headers 原始请求�?   */
  public convertHeaders(headers: Record<string, string | number | boolean | null>): Record<string, string> {
    const result: Record<string, string> = {};
    
    if (!headers) {
      return result;
    }
    
    // 处理不同格式的请求头
    if (TypeSafetyUtil.isValidString(headers)) {
      // 字符串格�? "User-Agent: xxx; Referer: yyy"
      headers.split(';').forEach((header: string) => {
        const parts = header.split(':');
        if (parts.length >= 2) {
          const key = parts[0].trim();
          const value = parts.slice(1).join(':').trim();
          result[key] = value;
        }
      });
    } else if (TypeSafetyUtil.isValidObject(headers)) {
      // 对象格式，手动复制字符串�?      const headersObj = TypeSafetyUtil.asObject(headers);
      for (const [key, value] of TypeSafetyUtil.getObjectEntries(headersObj)) {
        result[key] = TypeSafetyUtil.asString(value, '');
      }
    }
    
    return result;
  }
  
  /**
   * 转换分类配置
   * @param categories 原始分类
   */
  public convertCategories(categories: Record<string, string | number | boolean | null>): CategoryItem[] {
    const result: CategoryItem[] = [];
    
    if (!categories) {
      return result;
    }
    
    // 处理数组格式分类
    if (Array.isArray(categories)) {
      categories.forEach((cat: Record<string, string | number | boolean | null>) => {
        if (TypeSafetyUtil.isValidString(cat)) {
            const category: CategoryItem = {
              key: cat,
              name: cat
            };
            result.push(category);
          } else if (TypeSafetyUtil.isValidObject(cat)) {
            const catObj = TypeSafetyUtil.asObject(cat);
            const key = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(catObj, 'key', ''));
            const name = TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(catObj, 'name', ''));
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
    else if (TypeSafetyUtil.isValidObject(categories)) {
      const categoriesObj = TypeSafetyUtil.asObject(categories);
      for (const [key, value] of TypeSafetyUtil.getObjectEntries(categoriesObj)) {
        const name = TypeSafetyUtil.asString(value, key);
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
  public convertSearchRules(searchData: Record<string, string | number | boolean | null>): SearchRules {
    if (!TypeSafetyUtil.isValidObject(searchData)) {
      return {
        page: true,
        searchKey: 'wd',
        pageKey: 'page',
        resultPath: '',
        list: []
      };
    }
    
    const searchObj = TypeSafetyUtil.asObject(searchData);
    // 标准化搜索规则格�?    const result: SearchRules = {
      // Fongmi格式搜索规则适配
      page: TypeSafetyUtil.getProperty(searchObj, 'page', true),
      searchKey: TypeSafetyUtil.asString(
        TypeSafetyUtil.getProperty(searchObj, 'key', 
          TypeSafetyUtil.getProperty(searchObj, 'searchKey', 'wd')
        )
      ),
      pageKey: TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(searchObj, 'pageKey', 'page')),
      resultPath: TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(searchObj, 'resultPath', '')),
      list: TypeSafetyUtil.asArray(TypeSafetyUtil.getProperty(searchObj, 'list', []))
    };
    
    // 手动合并其他属性（确保类型安全�?    for (const [key, value] of TypeSafetyUtil.getObjectEntries(searchObj)) {
      if (!['page', 'searchKey', 'pageKey', 'resultPath', 'list'].includes(key)) {
        TypeSafetyUtil.setProperty(result as Record<string, unknown>, key, value);
      }
    }
    
    return result;
  }
  
  /**
   * 转换详情页规�?   * @param detailData 原始详情配置
   */
  public convertDetailRules(detailData: Record<string, string | number | boolean | null>): DetailRules {
    if (!TypeSafetyUtil.isValidObject(detailData)) {
      return {};
    }
    
    const detailObj = TypeSafetyUtil.asObject(detailData);
    const result: DetailRules = {};
    
    // 手动复制所有属�?    for (const [key, value] of TypeSafetyUtil.getObjectEntries(detailObj)) {
      TypeSafetyUtil.setProperty(result as Record<string, unknown>, key, value);
    }
    
    return result;
  }
  
  /**
   * 转换播放规则
   * @param playData 原始播放配置
   */
  public convertPlayRules(playData: Record<string, string | number | boolean | null>): PlayRules {
    if (!TypeSafetyUtil.isValidObject(playData)) {
      return { sources: [] };
    }
    
    const playObj = TypeSafetyUtil.asObject(playData);
    const result: PlayRules = { sources: [] };
    
    // 手动复制所有属性到sources数组
    for (const [key, value] of TypeSafetyUtil.getObjectEntries(playObj)) {
      if (TypeSafetyUtil.isValidObject(value)) {
        const playSource: PlaySource = {
          name: TypeSafetyUtil.asString(TypeSafetyUtil.getProperty(value, 'name', key)),
          rules: TypeSafetyUtil.asObject(TypeSafetyUtil.getProperty(value, 'rules', {}))
        };
        result.sources.push({ key, source: playSource });
      }
    }
    
    return result;
  }
  
  /**
   * 验证URL是否有效
   * @param url 要验证的URL字符�?   */
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
      Logger.info(TAG, 'Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration' instanceof Error ? 'Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration' : new Error(String('Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration' instanceof Error ? 'Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration' instanceof Error ? 'Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration' : new Error(String('Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration' : new Error(String('Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration' instanceof Error ? 'Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration' : new Error(String('Parsing application configuration' instanceof Error ? 'Parsing application configuration' : new Error(String('Parsing application configuration')))))));
      
      const config = this.parseJsonContent(configContent);
      const harmonySection = TypeSafetyUtil.asObject(TypeSafetyUtil.getProperty(config, 'harmony', {}));
      
      // 创建HarmonyOS专用配置
      const harmonyConfig: HarmonyConfig = {
        enableVoiceAssistant: TypeSafetyUtil.getProperty(harmonySection, 'enableVoiceAssistant', false),
        enableDeviceFlow: TypeSafetyUtil.getProperty(harmonySection, 'enableDeviceFlow', false),
        enableGestureControl: TypeSafetyUtil.getProperty(harmonySection, 'enableGestureControl', false),
        enableWidget: TypeSafetyUtil.getProperty(harmonySection, 'enableWidget', false),
        enableNotification: TypeSafetyUtil.getProperty(harmonySection, 'enableNotification', false),
        enableAutoStart: TypeSafetyUtil.getProperty(harmonySection, 'enableAutoStart', false),
        enableBackgroundSync: TypeSafetyUtil.getProperty(harmonySection, 'enableBackgroundSync', false),
        enableMultiWindow: TypeSafetyUtil.getProperty(harmonySection, 'enableMultiWindow', false),
        enableHiAI: TypeSafetyUtil.getProperty(harmonySection, 'enableHiAI', false),
        enableSuperDevice: TypeSafetyUtil.getProperty(harmonySection, 'enableSuperDevice', false),
        deviceSharingEnabled: TypeSafetyUtil.getProperty(harmonySection, 'deviceSharingEnabled', false),
        notificationChannels: TypeSafetyUtil.asArray(TypeSafetyUtil.getProperty(harmonySection, 'notificationChannels', [])),
        quickActions: TypeSafetyUtil.asArray(TypeSafetyUtil.getProperty(harmonySection, 'quickActions', []))
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
        name: 'RayTV', version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now( instanceof Error ? version: '1.0.0',
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
      updateTime: Date.now( : new Error(String(version: '1.0.0',
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
      updateTime: Date.now()))))))
    };
  }

}



