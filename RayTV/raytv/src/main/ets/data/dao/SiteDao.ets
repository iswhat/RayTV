import Logger from '../../common/util/Logger';
import { Site } from '../bean/Site';
import { DatabaseManager } from '../db/DatabaseManager';
import { TableSchema } from '../db/TableSchema';

/**
 * 站点数据访问对象
 * 负责站点相关的数据库操作
 */
export class SiteDao {
  private readonly TAG: string = 'SiteDao';
  private databaseManager: DatabaseManager;

  constructor() {
    this.databaseManager = DatabaseManager.getInstance();
  }

  /**
   * 保存站点信息
   * @param site 站点信息
   */
  public async save(site: Site): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.siteToValuesBucket(site);
      
      await db.insert(TableSchema.SITE_TABLE, valuesBucket);
      Logger.info(this.TAG, `Site saved: ${site.name}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save site: ${error}`);
      throw error;
    }
  }

  /**
   * 更新站点信息
   * @param site 站点信息
   */
  public async update(site: Site): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.siteToValuesBucket(site);
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SITE_KEY, site.key);
      
      const rowsAffected = await db.update(TableSchema.SITE_TABLE, valuesBucket, predicates);
      Logger.info(this.TAG, `Site updated: ${site.name}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update site: ${error}`);
      throw error;
    }
  }

  /**
   * 保存或更新站点信息
   * @param site 站点信息
   */
  public async saveOrUpdate(site: Site): Promise<void> {
    try {
      const existingSite = await this.getByKey(site.key);
      if (existingSite) {
        await this.update(site);
      } else {
        await this.save(site);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to save or update site: ${error}`);
      throw error;
    }
  }

  /**
   * 删除站点
   * @param siteKey 站点唯一标识
   */
  public async delete(siteKey: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SITE_KEY, siteKey);
      
      const rowsAffected = await db.delete(TableSchema.SITE_TABLE, predicates);
      Logger.info(this.TAG, `Site deleted: ${siteKey}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete site: ${error}`);
      throw error;
    }
  }

  /**
   * 获取所有站点
   * @returns 站点列表
   */
  public async getAll(): Promise<Site[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      const resultSet = await db.query(TableSchema.SITE_TABLE, predicates);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all sites: ${error}`);
      return [];
    }
  }

  /**
   * 获取已启用的站点
   * @returns 已启用的站点列表
   */
  public async getEnabled(): Promise<Site[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SITE_ENABLED, true);
      const resultSet = await db.query(TableSchema.SITE_TABLE, predicates);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get enabled sites: ${error}`);
      return [];
    }
  }

  /**
   * 根据类型获取站点
   * @param type 站点类型
   * @returns 站点列表
   */
  public async getByType(type: string): Promise<Site[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SITE_TYPE, type);
      const resultSet = await db.query(TableSchema.SITE_TABLE, predicates);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get sites by type: ${error}`);
      return [];
    }
  }

  /**
   * 根据类型获取已启用的站点
   * @param type 站点类型
   * @returns 已启用的站点列表
   */
  public async getEnabledByType(type: string): Promise<Site[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SITE_TYPE, type);
      predicates.equalTo(TableSchema.SITE_ENABLED, true);
      const resultSet = await db.query(TableSchema.SITE_TABLE, predicates);
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get enabled sites by type: ${error}`);
      return [];
    }
  }

  /**
   * 根据站点唯一标识获取站点
   * @param siteKey 站点唯一标识
   * @returns 站点信息或undefined
   */
  public async getByKey(siteKey: string): Promise<Site | undefined> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.SITE_KEY, siteKey);
      const resultSet = await db.query(TableSchema.SITE_TABLE, predicates);
      
      const sites = this.parseResultSet(resultSet);
      return sites.length > 0 ? sites[0] : undefined;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get site by key: ${error}`);
      return undefined;
    }
  }

  /**
   * 批量保存站点
   * @param sites 站点列表
   */
  public async batchSave(sites: Site[]): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      
      // 使用事务批量保存
      await db.beginTransaction();
      
      try {
        for (const site of sites) {
          await this.saveOrUpdate(site);
        }
        await db.commit();
        Logger.info(this.TAG, `Batch saved ${sites.length} sites`);
      } catch (error) {
        await db.rollback();
        throw error;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch save sites: ${error}`);
      throw error;
    }
  }

  /**
   * 清空所有站点
   */
  public async clearAll(): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      await db.delete(TableSchema.SITE_TABLE);
      Logger.info(this.TAG, 'All sites cleared');
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all sites: ${error}`);
      throw error;
    }
  }

  /**
   * 将ResultSet解析为Site数组
   * @param resultSet 查询结果集
   * @returns Site数组
   */
  private parseResultSet(resultSet: ResultSet): Site[] {
    const sites: Site[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const site: Site = {
            key: resultSet.getString(TableSchema.SITE_KEY),
            name: resultSet.getString(TableSchema.SITE_NAME),
            type: resultSet.getString(TableSchema.SITE_TYPE),
            url: resultSet.getString(TableSchema.SITE_URL),
            content: resultSet.getString(TableSchema.SITE_CONTENT),
            enabled: resultSet.getBoolean(TableSchema.SITE_ENABLED),
            userAgent: resultSet.getString(TableSchema.SITE_USER_AGENT),
            requestHeaders: this.parseJsonString(resultSet.getString(TableSchema.SITE_REQUEST_HEADERS)),
            updateTime: resultSet.getString(TableSchema.SITE_UPDATE_TIME),
            version: resultSet.getString(TableSchema.SITE_VERSION),
            allowedDomains: this.parseJsonArrayString(resultSet.getString(TableSchema.SITE_ALLOWED_DOMAINS)),
            searchRule: this.parseJsonString(resultSet.getString(TableSchema.SITE_SEARCH_RULE)),
            detailRule: this.parseJsonString(resultSet.getString(TableSchema.SITE_DETAIL_RULE)),
            playRule: this.parseJsonString(resultSet.getString(TableSchema.SITE_PLAY_RULE))
          };
          sites.push(site);
        } while (resultSet.goToNextRow());
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse result set: ${error}`);
    } finally {
      resultSet.close();
    }
    
    return sites;
  }

  /**
   * 将Site对象转换为ValuesBucket
   * @param site 站点信息
   * @returns ValuesBucket
   */
  private siteToValuesBucket(site: Site): ValuesBucket {
    const values: ValuesBucket = {
      [TableSchema.SITE_KEY]: site.key,
      [TableSchema.SITE_NAME]: site.name,
      [TableSchema.SITE_TYPE]: site.type,
      [TableSchema.SITE_URL]: site.url || '',
      [TableSchema.SITE_CONTENT]: site.content || '',
      [TableSchema.SITE_ENABLED]: site.enabled || true,
      [TableSchema.SITE_USER_AGENT]: site.userAgent || '',
      [TableSchema.SITE_REQUEST_HEADERS]: this.stringifyJson(site.requestHeaders || {}),
      [TableSchema.SITE_UPDATE_TIME]: site.updateTime || new Date().toISOString(),
      [TableSchema.SITE_VERSION]: site.version || '1.0.0',
      [TableSchema.SITE_ALLOWED_DOMAINS]: this.stringifyJson(site.allowedDomains || []),
      [TableSchema.SITE_SEARCH_RULE]: this.stringifyJson(site.searchRule || {}),
      [TableSchema.SITE_DETAIL_RULE]: this.stringifyJson(site.detailRule || {}),
      [TableSchema.SITE_PLAY_RULE]: this.stringifyJson(site.playRule || {})
    };
    
    return values;
  }

  /**
   * 解析JSON字符串
   * @param jsonString JSON字符串
   * @returns 解析后的对象
   */
  private parseJsonString(jsonString?: string): any {
    if (!jsonString) return {};
    try {
      return JSON.parse(jsonString);
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse JSON string: ${error}`);
      return {};
    }
  }

  /**
   * 解析JSON数组字符串
   * @param jsonString JSON字符串
   * @returns 解析后的数组
   */
  private parseJsonArrayString(jsonString?: string): string[] {
    if (!jsonString) return [];
    try {
      const parsed = JSON.parse(jsonString);
      return Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse JSON array string: ${error}`);
      return [];
    }
  }

  /**
   * 将对象转换为JSON字符串
   * @param obj 要转换的对象
   * @returns JSON字符串
   */
  private stringifyJson(obj: any): string {
    try {
      return JSON.stringify(obj);
    } catch (error) {
      Logger.error(this.TAG, `Failed to stringify JSON: ${error}`);
      return '{}';
    }
  }
}

// 导入必要的鸿蒙数据库相关类
import {
  ValuesBucket,
  RelationalPredicates,
  ResultSet
} from '@ohos/data.relationalStore';