import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { SITE_TABLE } from '../TableSchema';
import { Site, SiteType, LoaderType } from '../../bean/Site';
import Logger from '../../../common/util/Logger';
import JsonUtil from '../../../common/util/JsonUtil';

const TAG = 'SiteDao';

export class SiteDao {
  private db: relationalStore.RdbStore;
  
  constructor() {
    this.db = DatabaseManager.getInstance().getDatabase();
  }
  
  // 插入站点
  public async insert(site: Site): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [SITE_TABLE.COLUMNS.KEY]: site.key,
        [SITE_TABLE.COLUMNS.NAME]: site.name,
        [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.LOADER_TYPE]: site.loaderType,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.LOGO]: site.logo || null,
        [SITE_TABLE.COLUMNS.DESCRIPTION]: site.description || null,
        [SITE_TABLE.COLUMNS.SITE_AUTH]: site.siteAuth ? JsonUtil.stringify(site.siteAuth) : null,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries())) : null,
        [SITE_TABLE.COLUMNS.CONFIG]: site.config ? JsonUtil.stringify(Array.from(site.config.entries())) : null,
        [SITE_TABLE.COLUMNS.CONFIG_ITEMS]: site.configItems ? JsonUtil.stringify(site.configItems) : null,
        [SITE_TABLE.COLUMNS.SEARCH_CONFIG]: JsonUtil.stringify(site.searchConfig),
        [SITE_TABLE.COLUMNS.FILTER_CONFIG]: JsonUtil.stringify(site.filterConfig),
        [SITE_TABLE.COLUMNS.PERFORMANCE_CONFIG]: JsonUtil.stringify(site.performanceConfig),
        [SITE_TABLE.COLUMNS.VERSION]: site.version ? JsonUtil.stringify(site.version) : null,
        [SITE_TABLE.COLUMNS.STATS]: JsonUtil.stringify(site.stats),
        [SITE_TABLE.COLUMNS.LIFECYCLE]: JsonUtil.stringify(site.lifecycle),
        [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.ORDER]: site.order,
        [SITE_TABLE.COLUMNS.GROUP]: site.group || null,
        [SITE_TABLE.COLUMNS.TAGS]: site.tags ? JsonUtil.stringify(site.tags) : null,
        [SITE_TABLE.COLUMNS.CUSTOM_CODE]: site.customCode || null,
        [SITE_TABLE.COLUMNS.SANDBOX_ENABLED]: site.sandboxEnabled !== undefined ? (site.sandboxEnabled ? 1 : 0) : 1,
        [SITE_TABLE.COLUMNS.ALLOW_THIRD_PARTY]: site.allowThirdParty !== undefined ? (site.allowThirdParty ? 1 : 0) : 0,
        [SITE_TABLE.COLUMNS.CREATED_AT]: site.createdAt,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: site.updatedAt,
        [SITE_TABLE.COLUMNS.LAST_USED_AT]: site.lastUsedAt || null,
        [SITE_TABLE.COLUMNS.USER_AGENT]: site.userAgent || null,
        [SITE_TABLE.COLUMNS.REFERER]: site.referer || null,
        [SITE_TABLE.COLUMNS.PROXY]: site.proxy || null,
        [SITE_TABLE.COLUMNS.ENCODING]: site.encoding || null,
        [SITE_TABLE.COLUMNS.CHARSET]: site.charset || null,
        [SITE_TABLE.COLUMNS.CERTIFICATE]: site.certificate || null
      };
      
      await this.db.insert(SITE_TABLE.NAME, valuesBucket);
    } catch (error) {
      Logger.error(TAG, `Failed to insert site: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 保存站点（插入或更新）
  public async save(site: Site): Promise<void> {
    try {
      // 检查是否已存在
      const existing = await this.getByKey(site.key);
      if (existing) {
        await this.update(site);
      } else {
        await this.insert(site);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save site: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 更新站点
  public async update(site: Site): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [SITE_TABLE.COLUMNS.NAME]: site.name,
        [SITE_TABLE.COLUMNS.LOADER_TYPE]: site.loaderType,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.LOGO]: site.logo || null,
        [SITE_TABLE.COLUMNS.DESCRIPTION]: site.description || null,
        [SITE_TABLE.COLUMNS.SITE_AUTH]: site.siteAuth ? JsonUtil.stringify(site.siteAuth) : null,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries())) : null,
        [SITE_TABLE.COLUMNS.CONFIG]: site.config ? JsonUtil.stringify(Array.from(site.config.entries())) : null,
        [SITE_TABLE.COLUMNS.CONFIG_ITEMS]: site.configItems ? JsonUtil.stringify(site.configItems) : null,
        [SITE_TABLE.COLUMNS.SEARCH_CONFIG]: JsonUtil.stringify(site.searchConfig),
        [SITE_TABLE.COLUMNS.FILTER_CONFIG]: JsonUtil.stringify(site.filterConfig),
        [SITE_TABLE.COLUMNS.PERFORMANCE_CONFIG]: JsonUtil.stringify(site.performanceConfig),
        [SITE_TABLE.COLUMNS.VERSION]: site.version ? JsonUtil.stringify(site.version) : null,
        [SITE_TABLE.COLUMNS.STATS]: JsonUtil.stringify(site.stats),
        [SITE_TABLE.COLUMNS.LIFECYCLE]: JsonUtil.stringify(site.lifecycle),
        [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.ORDER]: site.order,
        [SITE_TABLE.COLUMNS.GROUP]: site.group || null,
        [SITE_TABLE.COLUMNS.TAGS]: site.tags ? JsonUtil.stringify(site.tags) : null,
        [SITE_TABLE.COLUMNS.CUSTOM_CODE]: site.customCode || null,
        [SITE_TABLE.COLUMNS.SANDBOX_ENABLED]: site.sandboxEnabled !== undefined ? (site.sandboxEnabled ? 1 : 0) : 1,
        [SITE_TABLE.COLUMNS.ALLOW_THIRD_PARTY]: site.allowThirdParty !== undefined ? (site.allowThirdParty ? 1 : 0) : 0,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: site.updatedAt,
        [SITE_TABLE.COLUMNS.LAST_USED_AT]: site.lastUsedAt || null,
        [SITE_TABLE.COLUMNS.USER_AGENT]: site.userAgent || null,
        [SITE_TABLE.COLUMNS.REFERER]: site.referer || null,
        [SITE_TABLE.COLUMNS.PROXY]: site.proxy || null,
        [SITE_TABLE.COLUMNS.ENCODING]: site.encoding || null,
        [SITE_TABLE.COLUMNS.CHARSET]: site.charset || null,
        [SITE_TABLE.COLUMNS.CERTIFICATE]: site.certificate || null
      };
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, site.key);
      
      await this.db.update(valuesBucket, predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to update site: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 删除站点
  public async delete(key: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to delete site: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 获取所有站点
  public async getAll(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get all sites: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 获取启用的站点
  public async getEnabled(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get enabled sites: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 获取指定类型的站点
  public async getByType(type: SiteType): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.TYPE, type);
      predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get sites by type: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据key获取站点
  public async getByKey(key: string): Promise<Site | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      const resultSet = await this.db.query(predicates);
      const sites = this.parseResultSet(resultSet);
      return sites.length > 0 ? sites[0] : null;
    } catch (error) {
      Logger.error(TAG, `Failed to get site by key: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据分组获取站点
  public async getByGroup(group: string): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.GROUP, group);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get sites by group: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 更新站点使用时间
  public async updateLastUsed(key: string): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [SITE_TABLE.COLUMNS.LAST_USED_AT]: Date.now(),
        [SITE_TABLE.COLUMNS.UPDATED_AT]: Date.now()
      };
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      await this.db.update(valuesBucket, predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to update last used time: ${JSON.stringify(error)}`);
    }
  }
  
  // 批量保存站点
  public async batchSave(sites: Site[]): Promise<void> {
    try {
      for (const site of sites) {
        await this.save(site);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to batch save sites: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 解析结果集
  private parseResultSet(resultSet: relationalStore.ResultSet): Site[] {
    const sites: Site[] = [];
    
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      do {
        const siteAuthStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SITE_AUTH));
        const siteAuth = siteAuthStr ? JsonUtil.parse(siteAuthStr) : undefined;
        
        const headersStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.HEADERS));
        const headers = headersStr ? new Map(JsonUtil.parse(headersStr)) : undefined;
        
        const configStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CONFIG));
        const config = configStr ? new Map(JsonUtil.parse(configStr)) : undefined;
        
        const configItemsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CONFIG_ITEMS));
        const configItems = configItemsStr ? JsonUtil.parse(configItemsStr) : undefined;
        
        const searchConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SEARCH_CONFIG));
        const searchConfig = searchConfigStr ? JsonUtil.parse(searchConfigStr) : { enabled: false };
        
        const filterConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.FILTER_CONFIG));
        const filterConfig = filterConfigStr ? JsonUtil.parse(filterConfigStr) : { enabled: false };
        
        const performanceConfigStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.PERFORMANCE_CONFIG));
        const performanceConfig = performanceConfigStr ? JsonUtil.parse(performanceConfigStr) : {};
        
        const versionStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.VERSION));
        const version = versionStr ? JsonUtil.parse(versionStr) : undefined;
        
        const statsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.STATS));
        const stats = statsStr ? JsonUtil.parse(statsStr) : { queryCount: 0, errorCount: 0, avgResponseTime: 0 };
        
        const lifecycleStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LIFECYCLE));
        const lifecycle = lifecycleStr ? JsonUtil.parse(lifecycleStr) : { initialized: false, loading: false, error: false };
        
        const tagsStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TAGS));
        const tags = tagsStr ? JsonUtil.parse(tagsStr) : undefined;
        
        sites.push({
          key: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.KEY)),
          name: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.NAME)),
          type: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TYPE)) as SiteType,
          loaderType: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LOADER_TYPE)) as LoaderType,
          api: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.API)),
          logo: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LOGO)),
          description: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.DESCRIPTION)),
          siteAuth,
          headers,
          config,
          configItems,
          searchConfig,
          filterConfig,
          performanceConfig,
          version,
          stats,
          lifecycle,
          enabled: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENABLED)) === 1,
          order: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ORDER)),
          group: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.GROUP)),
          tags,
          customCode: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CUSTOM_CODE)),
          sandboxEnabled: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SANDBOX_ENABLED)) === 1,
          allowThirdParty: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ALLOW_THIRD_PARTY)) === 1,
          createdAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CREATED_AT)),
          updatedAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.UPDATED_AT)),
          lastUsedAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.LAST_USED_AT)),
          userAgent: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.USER_AGENT)),
          referer: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.REFERER)),
          proxy: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.PROXY)),
          encoding: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENCODING)),
          charset: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CHARSET)),
          certificate: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CERTIFICATE))
        });
      } while (resultSet.goToNextRow());
    }
    
    resultSet.close();
    return sites;
  }
}