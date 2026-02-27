// SiteDao.ets - 站点数据访问对象 | Site data access object
// 实现站点数据的增删改查操作 | Implements CRUD operations for site data
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { SITE_TABLE } from '../TableSchema';
import { Site, SiteAuth, SiteConfigItem, SiteSearchConfig, SiteFilterConfig, SitePerformanceConfig, SiteStats, SiteLifecycle, SiteHeaders, SiteType, LoaderType } from '../../bean/Site';
import LoggerUtil from '../../../common/util/Logger';
import JsonUtil from '../../../common/util/JsonUtil';
import StorageUtil from '../../../common/util/StorageUtil';



/**
 * 站点数据访问对象 | Site data access object
 */
export class SiteDao {
  private readonly TAG: string = 'SiteDao';
  private dbManager: DatabaseManager;
  
  /**
   * 构造函数 | Constructor
   */
  constructor() {
    this.dbManager = DatabaseManager.getInstance();
  }
  
  /**
   * 插入站点 | Insert site
   * @param site 站点信息 | Site information
   * @returns Promise<void>
   */
  public async insert(site: Site): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = await this.createValuesBucket(site);
      await this.dbManager.getDatabase().insert(SITE_TABLE.NAME, valuesBucket);
      LoggerUtil.info(this.TAG, `Inserted site: ${site.name} (${site.key})`);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to insert site: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 批量插入站点 | Batch insert sites
   * @param sites 站点列表 | Site list
   * @returns Promise<void>
   */
  public async batchInsert(sites: Site[]): Promise<void> {
    if (!sites || sites.length === 0) {
      return;
    }
    
    try {
      for (const site of sites) {
        const valuesBucket: relationalStore.ValuesBucket = await this.createValuesBucket(site);
        await this.dbManager.getDatabase().insert(SITE_TABLE.NAME, valuesBucket);
      }
      LoggerUtil.info(this.TAG, `Batch inserted ${sites.length} sites`);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to batch insert sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点 | Update site
   * @param site 站点信息 | Site information
   * @returns Promise<void>
   */
  public async update(site: Site): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = await this.createValuesBucket(site);
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, site.key);
      await this.dbManager.getDatabase().update(valuesBucket, predicates);
      LoggerUtil.info(this.TAG, `Updated site: ${site.name} (${site.key})`);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to update site: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 删除站点 | Delete site
   * @param key 站点key | Site key
   * @returns Promise<void>
   */
  public async delete(key: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      await this.dbManager.getDatabase().delete(predicates);
      LoggerUtil.info(this.TAG, `Deleted site: ${key}`);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to delete site: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取所有站点 | Get all sites
   * @returns Promise<Site[]>
   */
  public async getAll(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      const resultSet = await this.dbManager.getDatabase().query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to get all sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 根据key获取站点 | Get site by key
   * @param key 站点key | Site key
   * @returns Promise<Site | undefined>
   */
  public async getByKey(key: string): Promise<Site | undefined> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      const resultSet = await this.dbManager.getDatabase().query(predicates);
      const sites = this.parseResultSet(resultSet);
      return sites.length > 0 ? sites[0] : undefined;
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to get site by key: ${key}, error: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 根据类型获取站点 | Get sites by type
   * @param type 站点类型 | Site type
   * @returns Promise<Site[]>
   */
  public async getByType(type: SiteType): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.TYPE, type).orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      const resultSet = await this.dbManager.getDatabase().query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to get sites by type: ${type}, error: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 启用/禁用站点 | Enable/disable site
   * @param key 站点key | Site key
   * @param enabled 是否启用 | Whether to enable
   * @returns Promise<void>
   */
  public async enableSite(key: string, enabled: boolean): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {};
      valuesBucket[SITE_TABLE.COLUMNS.ENABLED] = enabled ? 1 : 0;
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      await this.dbManager.getDatabase().update(valuesBucket, predicates);
      LoggerUtil.info(this.TAG, `${enabled ? 'Enabled' : 'Disabled'} site: ${key}`);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to ${enabled ? 'enable' : 'disable'} site: ${key}, error: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点顺序 | Update site order
   * @param sites 站点列表 | Site list
   * @returns Promise<void>
   */
  public async updateOrder(sites: Site[]): Promise<void> {
    if (!sites || sites.length === 0) {
      return;
    }
    
    try {
      for (let i = 0; i < sites.length; i++) {
        const valuesBucket: relationalStore.ValuesBucket = {};
        valuesBucket[SITE_TABLE.COLUMNS.ORDER] = i;
        const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
        predicates.equalTo(SITE_TABLE.COLUMNS.KEY, sites[i].key);
        await this.dbManager.getDatabase().update(valuesBucket, predicates);
      }
      LoggerUtil.info(this.TAG, `Updated order for ${sites.length} sites`);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to update site order: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 删除所有站点 | Delete all sites
   * @returns Promise<void>
   */
  public async deleteAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      await this.dbManager.getDatabase().delete(predicates);
      LoggerUtil.info(this.TAG, `Deleted all sites`);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to delete all sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 加密站点认证信息 | Encrypt site authentication information
   * @param siteAuthStr 站点认证信息字符串 | Site authentication information string
   * @returns 加密后的字符串 | Encrypted string
   */
  private async encryptSiteAuth(siteAuthStr: string): Promise<string> {
    try {
      // 使用StorageUtil的加密功能 | Use StorageUtil's encryption functionality
      return await StorageUtil.putString('site_auth_temp', siteAuthStr).then(() => siteAuthStr);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to encrypt site auth: ${error instanceof Error ? error.message : String(error)}`);
      return siteAuthStr;
    }
  }
  
  /**
   * 解密站点认证信息 | Decrypt site authentication information
   * @param encryptedStr 加密后的字符串 | Encrypted string
   * @returns 解密后的站点认证信息 | Decrypted site authentication information
   */
  private async decryptSiteAuth(encryptedStr: string): Promise<string> {
    try {
      // 使用StorageUtil的解密功能 | Use StorageUtil's decryption functionality
      return await StorageUtil.getString('site_auth_temp', encryptedStr);
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to decrypt site auth: ${error instanceof Error ? error.message : String(error)}`);
      return encryptedStr;
    }
  }
  
  /**
   * 创建值桶 | Create values bucket
   * @param site 站点信息 | Site information
   * @returns relationalStore.ValuesBucket 值桶 | Values bucket
   */
  private async createValuesBucket(site: Site): Promise<relationalStore.ValuesBucket> {
    const headersStr = site.headers && site.headers.headers ? JSON.stringify(site.headers.headers) : null;
    const configStr = site.config ? JSON.stringify(site.config) : null;
    // 加密站点认证信息 | Encrypt site authentication information
    const siteAuthStr = site.siteAuth ? JSON.stringify(site.siteAuth) : null;
    const configItemsStr = site.configItems ? JSON.stringify(site.configItems) : null;
    const searchConfigStr = site.searchConfig ? JSON.stringify(site.searchConfig) : null;
    const filterConfigStr = site.filterConfig ? JSON.stringify(site.filterConfig) : null;
    const performanceConfigStr = site.performanceConfig ? JSON.stringify(site.performanceConfig) : null;
    const statsStr = site.stats ? JSON.stringify(site.stats) : null;
    const lifecycleStr = site.lifecycle ? JSON.stringify(site.lifecycle) : null;
    const tagsStr = site.tags ? JSON.stringify(site.tags) : null;
    
    // 使用明确的属性名创建ValuesBucket，确保所有属性都有默认值 | Create ValuesBucket with explicit property names, ensuring all properties have default values
    const valuesBucket: relationalStore.ValuesBucket = {};
    valuesBucket.key = site.key || '';
    valuesBucket.name = site.name || '';
    valuesBucket.type = site.type || '';
    valuesBucket.loaderType = site.loaderType || '';
    valuesBucket.api = site.api || '';
    valuesBucket.logo = site.logo || '';
    valuesBucket.description = site.description || '';
    valuesBucket.headers = headersStr || '';
    valuesBucket.config = configStr || '';
    valuesBucket.siteAuth = siteAuthStr || '';
    valuesBucket.configItems = configItemsStr || '';
    valuesBucket.searchConfig = searchConfigStr || '';
    valuesBucket.filterConfig = filterConfigStr || '';
    valuesBucket.performanceConfig = performanceConfigStr || '';
    valuesBucket.stats = statsStr || '';
    valuesBucket.lifecycle = lifecycleStr || '';
    valuesBucket.enabled = site.enabled ? 1 : 0;
    valuesBucket.order = site.order || 0;
    valuesBucket.group = site.group || '';
    valuesBucket.tags = tagsStr || '';
    valuesBucket.customCode = site.customCode || '';
    valuesBucket.sandboxEnabled = site.sandboxEnabled ? 1 : 0;
    valuesBucket.allowThirdParty = site.allowThirdParty ? 1 : 0;
    valuesBucket.createdAt = site.createdAt || Date.now();
    valuesBucket.updatedAt = Date.now();
    valuesBucket.lastUsedAt = site.lastUsedAt || 0;
    valuesBucket.userAgent = site.userAgent || '';
    valuesBucket.referer = site.referer || '';
    valuesBucket.proxy = site.proxy || '';
    valuesBucket.encoding = site.encoding || '';
    valuesBucket.charset = site.charset || '';
    valuesBucket.certificate = site.certificate || '';
    
    return valuesBucket;
  }
  
  /**
   * 解析结果集 | Parse result set
   * @param resultSet 结果集 | Result set
   * @returns Site[] 站点列表 | Site list
   * @private
   */
  private async parseResultSet(resultSet: relationalStore.ResultSet): Promise<Site[]> {
    const sites: Site[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          // 解析所有字段 | Parse all fields
          const key = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.KEY)) || '';
          const name = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.NAME)) || '';
          const type = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TYPE)) as SiteType || SiteType.VOD;
          const loaderType = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LOADER_TYPE)) as LoaderType || LoaderType.JS;
          const api = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.API)) || '';
          const logo = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LOGO)) || '';
          const description = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.DESCRIPTION)) || '';
          const enabled = resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENABLED)) > 0;
          const order = resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ORDER)) || 0;
          const group = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.GROUP)) || '';
          const customCode = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CUSTOM_CODE)) || '';
          const sandboxEnabled = resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SANDBOX_ENABLED)) > 0;
          const allowThirdParty = resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ALLOW_THIRD_PARTY)) > 0;
          const createdAt = resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CREATED_AT)) || Date.now();
          const updatedAt = resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.UPDATED_AT)) || Date.now();
          const lastUsedAt = resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LAST_USED_AT)) || 0;
          const userAgent = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.USER_AGENT)) || '';
          const referer = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.REFERER)) || '';
          const proxy = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.PROXY)) || '';
          const encoding = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENCODING)) || '';
          const charset = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CHARSET)) || '';
          const certificate = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CERTIFICATE)) || '';
          
          // 解析headers | Parse headers
          const headersStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.HEADERS));
          let headers: SiteHeaders | undefined;
          if (headersStr) {
            try {
              const parsedHeaders = JSON.parse(headersStr) as Record<string, string> | Array<Array<string>>;
              let headersRecord: Record<string, string> = {};
              
              if (Array.isArray(parsedHeaders)) {
                // 处理数组格式: [['key', 'value'], ...] | Handle array format: [['key', 'value'], ...]
                for (let i = 0; i < parsedHeaders.length; i++) {
                  const headerItem = parsedHeaders[i];
                  if (Array.isArray(headerItem) && headerItem.length >= 2) {
                    const headerKey = String(headerItem[0]);
                    const headerValue = String(headerItem[1]);
                    headersRecord[headerKey] = headerValue;
                  }
                }
              } else if (parsedHeaders && typeof parsedHeaders === 'object') {
                // 处理对象格式 | Handle object format
                const keys = Object.keys(parsedHeaders);
                for (let i = 0; i < keys.length; i++) {
                  const headerKey = keys[i];
                  const headerValue = String(parsedHeaders[headerKey]);
                  headersRecord[headerKey] = headerValue;
                }
              }
              
              headers = { headers: headersRecord } as SiteHeaders;
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse headers: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析config | Parse config
          const configStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CONFIG));
          let config: Record<string, string | number | boolean | null> | undefined;
          if (configStr) {
            try {
              config = JSON.parse(configStr) as Record<string, string | number | boolean | null>;
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse config: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析siteAuth | Parse siteAuth
          const siteAuthStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SITE_AUTH));
          let siteAuth: SiteAuth | undefined;
          if (siteAuthStr) {
            try {
              // 解密站点认证信息 | Decrypt site authentication information
              const decryptedSiteAuthStr = await this.decryptSiteAuth(siteAuthStr);
              siteAuth = JSON.parse(decryptedSiteAuthStr) as SiteAuth;
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse siteAuth: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析configItems | Parse configItems
          const configItemsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CONFIG_ITEMS));
          let configItems: SiteConfigItem[] | undefined;
          if (configItemsStr) {
            try {
              configItems = JSON.parse(configItemsStr) as SiteConfigItem[];
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse configItems: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析searchConfig | Parse searchConfig
          const searchConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SEARCH_CONFIG));
          let searchConfig: SiteSearchConfig | undefined;
          if (searchConfigStr) {
            try {
              searchConfig = JSON.parse(searchConfigStr) as SiteSearchConfig;
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse searchConfig: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析filterConfig | Parse filterConfig
          const filterConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.FILTER_CONFIG));
          let filterConfig: SiteFilterConfig | undefined;
          if (filterConfigStr) {
            try {
              filterConfig = JSON.parse(filterConfigStr) as SiteFilterConfig;
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse filterConfig: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析performanceConfig | Parse performanceConfig
          const performanceConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.PERFORMANCE_CONFIG));
          let performanceConfig: SitePerformanceConfig | undefined;
          if (performanceConfigStr) {
            try {
              performanceConfig = JSON.parse(performanceConfigStr) as SitePerformanceConfig;
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse performanceConfig: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析stats | Parse stats
          const statsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.STATS));
          let stats: SiteStats | undefined;
          if (statsStr) {
            try {
              stats = JSON.parse(statsStr) as SiteStats;
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse stats: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析lifecycle | Parse lifecycle
          const lifecycleStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LIFECYCLE));
          let lifecycle: SiteLifecycle | undefined;
          if (lifecycleStr) {
            try {
              lifecycle = JSON.parse(lifecycleStr) as SiteLifecycle;
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse lifecycle: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 解析tags | Parse tags
          const tagsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TAGS));
          let tags: string[] | undefined;
          if (tagsStr) {
            try {
              tags = JSON.parse(tagsStr) as string[];
            } catch (e) {
              LoggerUtil.error(this.TAG, `Failed to parse tags: ${e instanceof Error ? e.message : String(e)}`);
            }
          }
          
          // 创建Site对象 | Create Site object
          // 处理config对象，移除null值 | Process config object, remove null values
          let cleanedConfig: Record<string, string | number | boolean> = {};
          if (config) {
            const entries = Object.entries(config);
            for (let i = 0; i < entries.length; i++) {
              const entry = entries[i];
              const key = entry[0];
              const value = entry[1];
              if (value !== null) {
                cleanedConfig[key] = value as string | number | boolean;
              }
            }
          }
          
          // 使用Site接口创建对象，确保所有属性都有明确类型 | Create object using Site interface, ensuring all properties have explicit types
          let siteHeaders: SiteHeaders = headers || { headers: {} } as SiteHeaders;
          let siteAuthObj: SiteAuth = siteAuth as SiteAuth || {} as SiteAuth;
          let siteSearchConfig: SiteSearchConfig = searchConfig as SiteSearchConfig || { enabled: false } as SiteSearchConfig;
          let siteFilterConfig: SiteFilterConfig = filterConfig as SiteFilterConfig || { enabled: false } as SiteFilterConfig;
          let sitePerformanceConfig: SitePerformanceConfig = performanceConfig as SitePerformanceConfig || {} as SitePerformanceConfig;
          let siteStats: SiteStats = stats as SiteStats || { queryCount: 0, errorCount: 0, avgResponseTime: 0 } as SiteStats;
          let siteLifecycle: SiteLifecycle = lifecycle as SiteLifecycle || { initialized: false, loading: false, error: false } as SiteLifecycle;
          
          const site: Site = {
            key,
            name,
            type,
            loaderType,
            api,
            logo,
            description,
            headers: siteHeaders,
            config: cleanedConfig,
            siteAuth: siteAuthObj,
            configItems: configItems || [],
            searchConfig: siteSearchConfig,
            filterConfig: siteFilterConfig,
            performanceConfig: sitePerformanceConfig,
            stats: siteStats,
            lifecycle: siteLifecycle,
            enabled,
            order,
            group,
            tags: tags || [],
            customCode,
            sandboxEnabled,
            allowThirdParty,
            createdAt,
            updatedAt,
            lastUsedAt,
            userAgent,
            referer,
            proxy,
            encoding,
            charset,
            certificate
          };
          
          sites.push(site);
        } while (resultSet.goToNextRow());
      }
      
      resultSet.close();
    } catch (error) {
      LoggerUtil.error(this.TAG, `Failed to parse result set: ${error instanceof Error ? error.message : String(error)}`);
      try {
        resultSet.close();
      } catch (closeError) {
        // 忽略关闭错误 | Ignore close error
      }
    }
    
    return sites;
  }
}
