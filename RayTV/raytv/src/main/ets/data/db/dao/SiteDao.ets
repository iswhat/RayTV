// SiteDao.ets - 站点数据访问对象
// 负责站点数据的增删改查操作

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { SITE_TABLE } from '../TableSchema';
import { Site, SiteConfigItem, SiteSearchConfig, SiteFilterConfig, SitePerformanceConfig, SiteStats, SiteLifecycle, SiteType, LoaderType } from '../../bean/Site';
import Logger from '../../../common/util/Logger';
import JsonUtil from '../../../common/util/JsonUtil';

/**
 * 头信息数据接口
 */
interface HeadersData {
  headers?: Record<string, string>;
}

/**
 * 站点数据访问对象
 */
export class SiteDao {
  private readonly TAG: string = 'SiteDao';
  private dbManager: DatabaseManager;
  
  /**
   * 构造函数
   */
  constructor() {
    this.dbManager = DatabaseManager.getInstance();
  }
  
  /**
   * 插入站点
   * @param site 站点信息
   * @returns Promise<void>
   */
  public async insert(site: Site): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = this.createValuesBucket(site);
      await this.dbManager.getDatabase().insert(SITE_TABLE.NAME, valuesBucket);
      Logger.info(this.TAG, `Inserted site: ${site.name} (${site.key})`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to insert site: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 批量插入站点
   * @param sites 站点列表
   * @returns Promise<void>
   */
  public async batchInsert(sites: Site[]): Promise<void> {
    try {
      await this.dbManager.executeTransaction(async (connection) => {
        for (const site of sites) {
          const valuesBucket = this.createValuesBucket(site);
          await connection.insert(SITE_TABLE.NAME, valuesBucket);
          Logger.debug(this.TAG, `Batch inserted site: ${site.name}`);
        }
      });
      Logger.info(this.TAG, `Successfully batch inserted ${sites.length} sites`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch insert sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点
   * @param site 站点信息
   * @returns Promise<void>
   */
  public async update(site: Site): Promise<void> {
    try {
      const headersStr = site.headers?.headers ? JSON.stringify(site.headers.headers) : null;
      
      const valuesBucket: relationalStore.ValuesBucket = {
        name: site.name,
        type: site.type,
        api: site.api,
        headers: headersStr,
        enabled: site.enabled ? 1 : 0,
        order: site.order,
        updated_at: Date.now()
      };
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, site.key);
      
      const count = await this.dbManager.getDatabase().update(valuesBucket, predicates);
      if (count > 0) {
        Logger.info(this.TAG, `Updated site: ${site.name} (${site.key})`);
      } else {
        Logger.warn(this.TAG, `Site not found for update: ${site.key}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to update site: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 删除站点
   * @param key 站点key
   * @returns Promise<void>
   */
  public async delete(key: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      const count = await this.dbManager.getDatabase().delete(predicates);
      if (count > 0) {
        Logger.info(this.TAG, `Deleted site: ${key}`);
      } else {
        Logger.warn(this.TAG, `Site not found for deletion: ${key}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete site: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 清空所有站点
   * @returns Promise<void>
   */
  public async clearAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      const count = await this.dbManager.getDatabase().delete(predicates);
      Logger.info(this.TAG, `Cleared all ${count} sites`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取所有站点
   * @returns Promise<Site[]> 站点列表
   */
  public async getAll(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.dbManager.getDatabase().query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取启用的站点
   * @returns Promise<Site[]> 启用的站点列表
   */
  public async getEnabled(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.dbManager.getDatabase().query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get enabled sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 根据类型获取站点
   * @param type 站点类型
   * @returns Promise<Site[]> 指定类型的站点列表
   */
  public async getByType(type: string): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.TYPE, type);
      predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.dbManager.getDatabase().query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get sites by type: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 根据key获取站点
   * @param key 站点key
   * @returns Promise<Site | null> 站点信息，不存在则返回null
   */
  public async getByKey(key: string): Promise<Site | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      const resultSet = await this.dbManager.getDatabase().query(predicates);
      const sites = this.parseResultSet(resultSet);
      return sites.length > 0 ? sites[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get site by key: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 批量更新站点启用状态
   * @param keys 站点key列表
   * @param enabled 是否启用
   * @returns Promise<void>
   */
  public async batchUpdateEnabled(keys: string[], enabled: boolean): Promise<void> {
    try {
      if (keys.length === 0) {
        return;
      }
      
      // 使用Record类型创建valuesBucket，避免使用计算属性名
      const valuesBucket: Record<string, number> = {};
      valuesBucket[SITE_TABLE.COLUMNS.ENABLED] = enabled ? 1 : 0;
      valuesBucket[SITE_TABLE.COLUMNS.UPDATED_AT] = Date.now();
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.in(SITE_TABLE.COLUMNS.KEY, keys);
      
      const count = await this.dbManager.getDatabase().update(valuesBucket, predicates);
      Logger.info(this.TAG, `Updated enabled status for ${count} sites`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch update enabled status: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点顺序
   * @param key 站点key
   * @param order 新的顺序
   * @returns Promise<void>
   */
  public async updateOrder(key: string, order: number): Promise<void> {
    try {
      // 使用Record类型创建valuesBucket，避免使用计算属性名
      const valuesBucket: Record<string, number> = {};
      valuesBucket[SITE_TABLE.COLUMNS.ORDER] = order;
      valuesBucket[SITE_TABLE.COLUMNS.UPDATED_AT] = Date.now();
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      await this.dbManager.getDatabase().update(valuesBucket, predicates);
      Logger.info(this.TAG, `Updated order for site ${key} to ${order}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update site order: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 更新站点最后使用时间
   * @param key 站点key
   * @returns Promise<void>
   */
  public async updateLastUsed(key: string): Promise<void> {
    try {
      // 使用Record类型创建valuesBucket，避免使用计算属性名
      const valuesBucket: Record<string, number> = {};
      valuesBucket[SITE_TABLE.COLUMNS.LAST_USED_AT] = Date.now();
      valuesBucket[SITE_TABLE.COLUMNS.UPDATED_AT] = Date.now();
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      await this.dbManager.getDatabase().update(valuesBucket, predicates);
      Logger.info(this.TAG, `Updated last used time for site ${key}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update site last used time: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 检查站点是否存在
   * @param key 站点key
   * @returns Promise<boolean> 是否存在
   */
  public async exists(key: string): Promise<boolean> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      predicates.limitAs(1);
      
      const resultSet = await this.dbManager.getDatabase().query(predicates);
      const exists = resultSet.rowCount > 0;
      resultSet.close();
      return exists;
    } catch (error) {
      Logger.error(this.TAG, `Failed to check if site exists: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }
  
  /**
   * 搜索站点
   * @param keyword 搜索关键词
   * @returns Promise<Site[]> 匹配的站点列表
   */
  public async search(keyword: string): Promise<Site[]> {
    try {
      const sql = `
        SELECT * FROM ${SITE_TABLE.NAME}
        WHERE ${SITE_TABLE.COLUMNS.NAME} LIKE ? OR ${SITE_TABLE.COLUMNS.KEY} LIKE ?
        ORDER BY ${SITE_TABLE.COLUMNS.ORDER} ASC
      `;
      
      const bindArgs: Array<string | number | boolean | null> = [`%${keyword}%`, `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase().querySql(sql, bindArgs);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to search sites: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 获取站点数量
   * @returns Promise<number> 站点数量
   */
  public async getCount(): Promise<number> {
    try {
      const sql = `SELECT COUNT(*) FROM ${SITE_TABLE.NAME}`;
      const resultSet = await this.dbManager.getDatabase().querySql(sql);
      
      let count = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = resultSet.getLong(0);
      }
      
      resultSet.close();
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get site count: ${error instanceof Error ? error.message : String(error)}`);
      return 0;
    }
  }
  
  /**
   * 解析结果集
   * @param resultSet 查询结果集
   * @returns Site[] 站点列表
   * @private
   */
  private parseResultSet(resultSet: relationalStore.ResultSet): Site[] {
    const sites: Site[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const headersStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.HEADERS));
          let headers: HeadersData | undefined;
          if (headersStr) {
            try {
              const parsedHeaders = JSON.parse(headersStr);
              let headersRecord: Record<string, string> = {};
              
              if (Array.isArray(parsedHeaders)) {
                // 处理数组格式: [["key", "value"], [...]]
                for (let i = 0; i < parsedHeaders.length; i++) {
                  const item = parsedHeaders[i];
                  if (Array.isArray(item) && item.length >= 2) {
                    const key = String(item[0]);
                    const value = String(item[1]);
                    headersRecord[key] = value;
                  }
                }
              } else if (typeof parsedHeaders === 'object' && parsedHeaders !== null) {
                // 处理对象格式: {"key": "value"}
                const keys = Object.keys(parsedHeaders);
                for (let i = 0; i < keys.length; i++) {
                  const key = keys[i];
                  const value = parsedHeaders[key];
                  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
                    headersRecord[key] = String(value);
                  }
                }
              }
              
              if (Object.keys(headersRecord).length > 0) {
                headers = { headers: headersRecord };
              } else {
                headers = undefined;
              }
            } catch (error) {
              // If all parsing fails, set headers to undefined
              headers = undefined;
            }
          } else {
            headers = undefined;
          }
          
          const configStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CONFIG));
          let config: Record<string, string | number | boolean> | undefined;
          if (configStr) {
            const parsedConfig = JSON.parse(configStr);
            if (parsedConfig && typeof parsedConfig === 'object') {
              config = parsedConfig as Record<string, string | number | boolean>;
            }
          }
          
          const siteAuthStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SITE_AUTH));
          let siteAuth: Record<string, string> | undefined;
          if (siteAuthStr) {
            const parsedAuth = JSON.parse(siteAuthStr);
            if (parsedAuth && typeof parsedAuth === 'object') {
              siteAuth = parsedAuth as Record<string, string>;
            }
          }
          
          const configItemsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CONFIG_ITEMS));
          let configItems: SiteConfigItem[] | undefined;
          if (configItemsStr) {
            const parsedConfigItems = JSON.parse(configItemsStr);
            if (Array.isArray(parsedConfigItems)) {
              configItems = parsedConfigItems as SiteConfigItem[];
            }
          }
          
          const searchConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SEARCH_CONFIG));
          let searchConfig: SiteSearchConfig;
          if (searchConfigStr) {
            const parsedSearchConfig = JSON.parse(searchConfigStr);
            if (parsedSearchConfig && typeof parsedSearchConfig === 'object') {
              searchConfig = parsedSearchConfig as SiteSearchConfig;
            } else {
              searchConfig = {
                enabled: false,
                searchDelay: 0,
                searchLimit: 0,
                supportAdvancedSearch: false,
                searchFilters: [],
                searchCategories: []
              };
            }
          } else {
            searchConfig = {
              enabled: false,
              searchDelay: 0,
              searchLimit: 0,
              supportAdvancedSearch: false,
              searchFilters: [],
              searchCategories: []
            };
          }
          
          const filterConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.FILTER_CONFIG));
          let filterConfig: SiteFilterConfig;
          if (filterConfigStr) {
            const parsedFilterConfig = JSON.parse(filterConfigStr);
            if (parsedFilterConfig && typeof parsedFilterConfig === 'object') {
              filterConfig = parsedFilterConfig as SiteFilterConfig;
            } else {
              filterConfig = {
                enabled: false,
                filterOptions: {},
                sortOptions: []
              };
            }
          } else {
            filterConfig = {
              enabled: false,
              filterOptions: {},
              sortOptions: []
            };
          }
          
          const performanceConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.PERFORMANCE_CONFIG));
          let performanceConfig: SitePerformanceConfig;
          if (performanceConfigStr) {
            const parsedPerformanceConfig = JSON.parse(performanceConfigStr);
            if (parsedPerformanceConfig && typeof parsedPerformanceConfig === 'object') {
              performanceConfig = parsedPerformanceConfig as SitePerformanceConfig;
            } else {
              performanceConfig = {
                timeout: 30000,
                retryCount: 3,
                cacheEnabled: true,
                cacheDuration: 60,
                concurrency: 5
              };
            }
          } else {
            performanceConfig = {
              timeout: 30000,
              retryCount: 3,
              cacheEnabled: true,
              cacheDuration: 60,
              concurrency: 5
            };
          }
          
          const statsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.STATS));
          let stats: SiteStats;
          if (statsStr) {
            const parsedStats = JSON.parse(statsStr);
            if (parsedStats && typeof parsedStats === 'object') {
              stats = parsedStats as SiteStats;
            } else {
              stats = {
                queryCount: 0,
                errorCount: 0,
                avgResponseTime: 0
              };
            }
          } else {
            stats = {
              queryCount: 0,
              errorCount: 0,
              avgResponseTime: 0
            };
          }
          
          const lifecycleStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LIFECYCLE));
          let lifecycle: SiteLifecycle;
          if (lifecycleStr) {
            const parsedLifecycle = JSON.parse(lifecycleStr);
            if (parsedLifecycle && typeof parsedLifecycle === 'object') {
              lifecycle = parsedLifecycle as SiteLifecycle;
            } else {
              lifecycle = {
                initialized: false,
                loading: false,
                error: false
              };
            }
          } else {
            lifecycle = {
              initialized: false,
              loading: false,
              error: false
            };
          }
          
          const tagsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TAGS));
          let tags: string[] | undefined;
          if (tagsStr) {
            const parsedTags = JSON.parse(tagsStr);
            if (Array.isArray(parsedTags)) {
              tags = parsedTags as string[];
            }
          }
          
          const site: Site = {
            key: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.KEY)) || '',
            name: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.NAME)) || '',
            type: (resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TYPE)) as SiteType) || SiteType.MIXED,
            loaderType: (resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LOADER_TYPE)) as LoaderType) || LoaderType.JS,
            api: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.API)) || '',
            logo: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LOGO)),
            description: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.DESCRIPTION)),
            siteAuth,
            headers,
            config,
            configItems,
            searchConfig,
            filterConfig,
            performanceConfig,
            stats,
            lifecycle,
            enabled: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENABLED)) === 1,
            order: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ORDER)) || 0,
            group: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.GROUP)),
            tags,
            customCode: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CUSTOM_CODE)),
            sandboxEnabled: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SANDBOX_ENABLED)) === 1,
            allowThirdParty: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ALLOW_THIRD_PARTY)) === 1,
            createdAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CREATED_AT)) || Date.now(),
            updatedAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.UPDATED_AT)) || Date.now(),
            lastUsedAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LAST_USED_AT)),
            userAgent: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.USER_AGENT)),
            referer: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.REFERER)),
            proxy: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.PROXY)),
            encoding: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENCODING)),
            charset: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CHARSET)),
            certificate: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CERTIFICATE))
          };
          sites.push(site);
        } while (resultSet.goToNextRow());
      }
    } finally {
      resultSet.close();
    }
    
    return sites;
  }
  
  /**
   * 创建值桶
   * @param site 站点信息
   * @returns relationalStore.ValuesBucket 值桶
   * @private
   */
  private createValuesBucket(site: Site): relationalStore.ValuesBucket {
    return {
      key: site.key ?? '',
      name: site.name ?? '',
      type: site.type ?? '',
      loader_type: site.loaderType ?? '',
      api: site.api ?? '',
      logo: site.logo ?? null,
      description: site.description ?? null,
      site_auth: site.siteAuth ? JSON.stringify(site.siteAuth) : null,
      headers: site.headers ? JSON.stringify(site.headers) : null,
      config: site.config ? JSON.stringify(site.config) : null,
      config_items: site.configItems ? JSON.stringify(site.configItems) : null,
      search_config: JSON.stringify(site.searchConfig),
      filter_config: JSON.stringify(site.filterConfig),
      performance_config: JSON.stringify(site.performanceConfig),
      version: site.version ? JSON.stringify(site.version) : null,
      stats: JSON.stringify(site.stats),
      lifecycle: JSON.stringify(site.lifecycle),
      enabled: site.enabled ? 1 : 0,
      order: site.order ?? 0,
      group: site.group ?? null,
      tags: site.tags ? JSON.stringify(site.tags) : null,
      custom_code: site.customCode ?? null,
      sandbox_enabled: site.sandboxEnabled ? 1 : 0,
      allow_third_party: site.allowThirdParty ? 1 : 0,
      created_at: site.createdAt ?? Date.now(),
      updated_at: site.updatedAt ?? Date.now(),
      last_used_at: site.lastUsedAt ?? null,
      user_agent: site.userAgent ?? null,
      referer: site.referer ?? null,
      proxy: site.proxy ?? null,
      encoding: site.encoding ?? null,
      charset: site.charset ?? null,
      certificate: site.certificate ?? null
    };
  }
}
