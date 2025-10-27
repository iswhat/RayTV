import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { SITE_TABLE } from '../TableSchema';
import { Site } from '../../bean/Site';
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
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries())) : null,
        [SITE_TABLE.COLUMNS.COOKIE]: site.cookie || null,
        [SITE_TABLE.COLUMNS.EXT]: site.ext ? JsonUtil.stringify(site.ext) : null,
        [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.ORDER]: site.order,
        [SITE_TABLE.COLUMNS.CREATED_AT]: site.createdAt,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: site.updatedAt
      };
      
      await this.db.insert(SITE_TABLE.TABLE_NAME, valuesBucket);
    } catch (error) {
      Logger.error(TAG, `Failed to insert site: ${error}`);
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
      Logger.error(TAG, `Failed to save site: ${error}`);
      throw error;
    }
  }
  
  // 更新站点
  public async update(site: Site): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [SITE_TABLE.COLUMNS.NAME]: site.name,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries())) : null,
        [SITE_TABLE.COLUMNS.COOKIE]: site.cookie || null,
        [SITE_TABLE.COLUMNS.EXT]: site.ext ? JsonUtil.stringify(site.ext) : null,
        [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.ORDER]: site.order,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: site.updatedAt
      };
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, site.key);
      
      await this.db.update(valuesBucket, predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to update site: ${error}`);
      throw error;
    }
  }
  
  // 删除站点
  public async delete(key: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to delete site: ${error}`);
      throw error;
    }
  }
  
  // 获取所有站点
  public async getAll(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get all sites: ${error}`);
      throw error;
    }
  }
  
  // 获取启用的站点
  public async getEnabled(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get enabled sites: ${error}`);
      throw error;
    }
  }
  
  // 获取指定类型的站点
  public async getByType(type: string): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.TYPE, type);
      predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get sites by type: ${error}`);
      throw error;
    }
  }
  
  // 根据key获取站点
  public async getByKey(key: string): Promise<Site | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      const resultSet = await this.db.query(predicates);
      const sites = this.parseResultSet(resultSet);
      return sites.length > 0 ? sites[0] : null;
    } catch (error) {
      Logger.error(TAG, `Failed to get site by key: ${error}`);
      throw error;
    }
  }
  
  // 解析结果集
  private parseResultSet(resultSet: relationalStore.ResultSet): Site[] {
    const sites: Site[] = [];
    
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      do {
        const headersStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.HEADERS));
        const headers = headersStr ? new Map(JSON.parse(headersStr)) : undefined;
        
        const extStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.EXT));
        const ext = extStr ? JSON.parse(extStr) : undefined;
        
        sites.push({
          key: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.KEY)),
          name: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.NAME)),
          type: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TYPE)),
          api: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.API)),
          searchable: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.SEARCHABLE)) === 1,
          filterable: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.FILTERABLE)) === 1,
          headers,
          cookie: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.COOKIE)),
          ext,
          enabled: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENABLED)) === 1,
          order: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ORDER)),
          createdAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CREATED_AT)),
          updatedAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.UPDATED_AT))
        });
      } while (resultSet.goToNextRow());
    }
    
    resultSet.close();
    return sites;
  }
}