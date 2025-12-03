// SiteDao.ets - 站点数据访问对象
// 负责站点数据的增删改查操�?
import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager, ValueType } from '../DatabaseManager';
import { SITE_TABLE } from '../TableSchema';
import { Site } from '../../bean/Site';
import Logger from '../../../common/util/Logger';
import JsonUtil from '../../../common/util/JsonUtil';

/**
 * 站点数据访问对象
 */
export class SiteDao {
  private readonly TAG: string = 'SiteDao';
  private dbManager: DatabaseManager;
  
  /**
   * 构造函�?   */
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
      await this.dbManager.insert(SITE_TABLE.TABLE_NAME, valuesBucket);
      Logger.info(this.TAG, `Inserted site: ${site.name} (${site.key})`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to insert site: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
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
          await connection.insert(SITE_TABLE.TABLE_NAME, valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket)))))));
          Logger.debug(this.TAG, `Batch inserted site: ${site.name}`);
        }
      });
      Logger.info(this.TAG, `Successfully batch inserted ${sites.length} sites`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch insert sites: ${error}`);
      throw error;
    }
  }
  
  /**
   * 更新站点
   * @param site 站点信息
   * @returns Promise<void>
   */
  public async update(site: Site): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [SITE_TABLE.COLUMNS.NAME]: site.name, [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( instanceof Error ? [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries( : new Error(String([SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.SEARCHABLE]: site.searchable ? 1 : 0,
        [SITE_TABLE.COLUMNS.FILTERABLE]: site.filterable ? 1 : 0,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries())))))))) : null,
        [SITE_TABLE.COLUMNS.COOKIE]: site.cookie || null,
        [SITE_TABLE.COLUMNS.EXT]: site.ext ? JsonUtil.stringify(site.ext) : null,
        [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.ORDER]: site.order,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: site.updatedAt
      };
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, site.key);
      
      const count = await this.dbManager.update(valuesBucket, predicates);
      if (count > 0) {
        Logger.info(this.TAG, `Updated site: ${site.name} (${site.key})`);
      } else {
        Logger.warn(this.TAG, `Site not found for update: ${site.key}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to update site: ${error}`);
      throw error;
    }
  }
  
  /**
   * 删除站点
   * @param key 站点key
   * @returns Promise<void>
   */
  public async delete(key: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key)))))));
      
      const count = await this.dbManager.delete(predicates);
      if (count > 0) {
        Logger.info(this.TAG, `Deleted site: ${key}`);
      } else {
        Logger.warn(this.TAG, `Site not found for deletion: ${key}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete site: ${error}`);
      throw error;
    }
  }
  
  /**
   * 清空所有站�?   * @returns Promise<void>
   */
  public async clearAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      const count = await this.dbManager.delete(predicates);
      Logger.info(this.TAG, `Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites` instanceof Error ? `Cleared all ${count} sites` : new Error(String(`Cleared all ${count} sites`)))))));
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all sites: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取所有站�?   * @returns Promise<Site[]> 站点列表
   */
  public async getAll(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.dbManager.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}` instanceof Error ? `Failed to get all sites: ${error}` : new Error(String(`Failed to get all sites: ${error}`)))))));
      throw error;
    }
  }
  
  /**
   * 获取启用的站�?   * @returns Promise<Site[]> 启用的站点列�?   */
  public async getEnabled(): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.dbManager.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get enabled sites: ${error}`);
      throw error;
    }
  }
  
  /**
   * 根据类型获取站点
   * @param type 站点类型
   * @returns Promise<Site[]> 指定类型的站点列�?   */
  public async getByType(type: string): Promise<Site[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.TYPE, type instanceof Error ? type : new Error(String(type instanceof Error ? type instanceof Error ? type : new Error(String(type : new Error(String(type instanceof Error ? type : new Error(String(type instanceof Error ? type instanceof Error ? type : new Error(String(type instanceof Error ? type instanceof Error ? type : new Error(String(type : new Error(String(type instanceof Error ? type : new Error(String(type : new Error(String(type instanceof Error ? type : new Error(String(type instanceof Error ? type instanceof Error ? type : new Error(String(type : new Error(String(type instanceof Error ? type : new Error(String(type)))))));
      predicates.equalTo(SITE_TABLE.COLUMNS.ENABLED, 1);
      predicates.orderByAsc(SITE_TABLE.COLUMNS.ORDER);
      
      const resultSet = await this.dbManager.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get sites by type: ${error}`);
      throw error;
    }
  }
  
  /**
   * 根据key获取站点
   * @param key 站点key
   * @returns Promise<Site | null> 站点信息，不存在则返回null
   */
  public async getByKey(key: string): Promise<Site | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key)))))));
      
      const resultSet = await this.dbManager.query(predicates);
      const sites = this.parseResultSet(resultSet);
      return sites.length > 0 ? sites[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get site by key: ${error}`);
      throw error;
    }
  }
  
  /**
   * 批量更新站点启用状�?   * @param keys 站点key列表
   * @param enabled 是否启用
   * @returns Promise<void>
   */
  public async batchUpdateEnabled(keys: string[], enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean : new Error(String(enabled: boolean instanceof Error ? enabled: boolean : new Error(String(enabled: boolean))))))): Promise<void> {
    try {
      if (keys.length === 0) {
        return;
      }
      
      const valuesBucket: relationalStore.ValuesBucket = {
        [SITE_TABLE.COLUMNS.ENABLED]: enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: Date.now()
      };
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.in(SITE_TABLE.COLUMNS.KEY, keys);
      
      const count = await this.dbManager.update(valuesBucket, predicates);
      Logger.info(this.TAG, `Updated enabled status for ${count} sites`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch update enabled status: ${error}`);
      throw error;
    }
  }
  
  /**
   * 更新站点顺序
   * @param key 站点key
   * @param order 新的顺序
   * @returns Promise<void>
   */
  public async updateOrder(key: string, order: number instanceof Error ? order: number : new Error(String(order: number instanceof Error ? order: number instanceof Error ? order: number : new Error(String(order: number : new Error(String(order: number instanceof Error ? order: number : new Error(String(order: number instanceof Error ? order: number instanceof Error ? order: number : new Error(String(order: number instanceof Error ? order: number instanceof Error ? order: number : new Error(String(order: number : new Error(String(order: number instanceof Error ? order: number : new Error(String(order: number : new Error(String(order: number instanceof Error ? order: number : new Error(String(order: number instanceof Error ? order: number instanceof Error ? order: number : new Error(String(order: number : new Error(String(order: number instanceof Error ? order: number : new Error(String(order: number))))))): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [SITE_TABLE.COLUMNS.ORDER]: order,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: Date.now()
      };
      
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      
      await this.dbManager.update(valuesBucket, predicates);
      Logger.info(this.TAG, `Updated order for site ${key} to ${order}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update site order: ${error}`);
      throw error;
    }
  }
  
  /**
   * 检查站点是否存�?   * @param key 站点key
   * @returns Promise<boolean> 是否存在
   */
  public async exists(key: string): Promise<boolean> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.TABLE_NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key instanceof Error ? key instanceof Error ? key : new Error(String(key : new Error(String(key instanceof Error ? key : new Error(String(key)))))));
      predicates.limit(1);
      
      const resultSet = await this.dbManager.query(predicates);
      const exists = resultSet.rowCount > 0;
      resultSet.close();
      return exists;
    } catch (error) {
      Logger.error(this.TAG, `Failed to check if site exists: ${error}`);
      return false;
    }
  }
  
  /**
   * 搜索站点
   * @param keyword 搜索关键�?   * @returns Promise<Site[]> 匹配的站点列�?   */
  public async search(keyword: string): Promise<Site[]> {
    try {
      const sql = `
        SELECT * FROM ${SITE_TABLE.TABLE_NAME}
        WHERE ${SITE_TABLE.COLUMNS.NAME} LIKE ? OR ${SITE_TABLE.COLUMNS.KEY} LIKE ?
        ORDER BY ${SITE_TABLE.COLUMNS.ORDER} ASC
      `;
      
      const bindArgs: ValueType[] = [`%${keyword}%`, `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( instanceof Error ? `%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase( : new Error(String(`%${keyword}%`];
      const resultSet = await this.dbManager.getDatabase())))))).querySql(sql, bindArgs);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to search sites: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取站点数量
   * @returns Promise<number> 站点数量
   */
  public async getCount(): Promise<number> {
    try {
      const sql = `SELECT COUNT(*) FROM ${SITE_TABLE.TABLE_NAME}`;
      const resultSet = await this.dbManager.getDatabase().querySql(sql);
      
      let count = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = resultSet.getLong(resultSet.getColumnIndex(0));
      }
      
      resultSet.close();
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}` instanceof Error ? `Failed to get site count: ${error}` : new Error(String(`Failed to get site count: ${error}`)))))));
      return 0;
    }
  }
  
  /**
   * 解析结果�?   * @param resultSet 查询结果�?   * @returns Site[] 站点列表
   * @private
   */
  private parseResultSet(resultSet: relationalStore.ResultSet): Site[] {
    const sites: Site[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const headersStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.HEADERS));
          const headers = headersStr ? new Map<string, string>(JSON.parse(headersStr)) : undefined;
          
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
  }
}


