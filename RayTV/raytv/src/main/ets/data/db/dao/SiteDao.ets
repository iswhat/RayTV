// SiteDao.ets - 站点数据访问对象
// 负责站点数据的增删改查操作

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
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
      const valuesBucket: relationalStore.ValuesBucket = {
        name: site.name,
        type: site.type,
        api: site.api,
        headers: site.headers ? JsonUtil.stringify(Array.from<[string, string]>(site.headers.entries())) : null,
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
   * 检查站点是否存在
   * @param key 站点key
   * @returns Promise<boolean> 是否存在
   */
  public async exists(key: string): Promise<boolean> {
    try {
      const predicates = new relationalStore.RdbPredicates(SITE_TABLE.NAME);
      predicates.equalTo(SITE_TABLE.COLUMNS.KEY, key);
      predicates.limit(1);
      
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
          let headers: { headers?: Record<string, string> } | undefined;
          if (headersStr) {
            try {
              const headersArray = JSON.parse(headersStr) as [string, string][];
              const headersRecord: Record<string, string> = {};
              // 使用传统for循环替代解构变量声明
              for (let i = 0; i < headersArray.length; i++) {
                const key = headersArray[i][0];
                const value = headersArray[i][1];
                headersRecord[key] = value;
              }
              headers = { headers: headersRecord };
            } catch (error) {
              // If parsing as array fails, try parsing as record
              const headersRecord = JSON.parse(headersStr) as Record<string, string>;
              headers = { headers: headersRecord };
            }
          } else {
            headers = undefined;
          }
          
          const extStr = resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CONFIG));
          const ext: Record<string, any> | undefined = extStr ? JSON.parse(extStr) : undefined;
          
          sites.push({
            key: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.KEY)),
            name: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.NAME)),
            type: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.TYPE)),
            api: resultSet.getString(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.API)),
            enabled: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ENABLED)) === 1,
            order: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.ORDER)),
            createdAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.CREATED_AT)),
            updatedAt: resultSet.getLong(resultSet.getColumnIndex(SITE_TABLE.COLUMNS.UPDATED_AT)),
            headers,
            ext
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
      key: site.key,
      name: site.name,
      type: site.type,
      api: site.api,
      enabled: site.enabled ? 1 : 0,
      order: site.order,
      headers: site.headers ? JsonUtil.stringify(Array.from(site.headers.entries())) : null,
      config: site.ext ? JsonUtil.stringify(site.ext) : null,
      created_at: site.createdAt || Date.now(),
      updated_at: site.updatedAt || Date.now()
    };
  }
}
