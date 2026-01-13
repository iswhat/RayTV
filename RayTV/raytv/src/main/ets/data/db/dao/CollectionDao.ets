// CollectionDao.ets - 收藏数据访问对象 | Collection data access object
// 实现收藏相关的数据库操作 | Implements collection-related database operations

import Logger from '../../../common/util/Logger';
import { DatabaseManager } from '../DatabaseManager';
import { TableSchema } from '../TableSchema';
import { Collection } from '../../bean/Collection';
import { ValuesBucket, RdbPredicates as RelationalPredicates, ResultSet } from '@ohos.data.relationalStore';

/**
 * 收藏数据访问对象 | Collection data access object
 * 实现收藏相关的数据库操作 | Implements collection-related database operations
 */
export class CollectionDao {
  private readonly TAG: string = 'CollectionDao';
  private databaseManager: DatabaseManager;

  constructor() {
    this.databaseManager = DatabaseManager.getInstance();
  }

  /**
   * 创建收藏表 | Create collection table
   */
  public async createTable(): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      // 表结构应该已经在DatabaseManager中创建 | Table structure should already be created in DatabaseManager
      Logger.info(this.TAG, 'Collection table check completed');
    } catch (error) {
      Logger.error(this.TAG, `Failed to create collection table: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 保存收藏 | Save collection
   * @param collection 收藏信息 | Collection information
   */
  public async save(collection: Collection): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.collectionToValuesBucket(collection);
      
      await db.insert(TableSchema.COLLECTION_TABLE, valuesBucket);
      Logger.info(this.TAG, `Collection saved: ${collection.title}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save collection: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 更新收藏 | Update collection
   * @param collection 收藏信息 | Collection information
   */
  public async update(collection: Collection): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.collectionToValuesBucket(collection);
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      predicates.equalTo(TableSchema.COLLECTION_ID, collection.id);
      
      const rowsAffected = await db.update(valuesBucket, predicates);
      Logger.info(this.TAG, `Collection updated: ${collection.title}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update collection: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 保存或更新收藏 | Save or update collection
   * @param collection 收藏信息 | Collection information
   */
  public async saveOrUpdate(collection: Collection): Promise<void> {
    try {
      const existingCollection = await this.getById(collection.id);
      if (existingCollection) {
        await this.update(collection);
      } else {
        await this.save(collection);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to save or update collection: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 删除收藏 | Delete collection
   * @param id 收藏ID | Collection ID
   */
  public async delete(id: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      predicates.equalTo(TableSchema.COLLECTION_ID, id);
      
      const rowsAffected = await db.delete(predicates);
      Logger.info(this.TAG, `Collection deleted: ${id}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete collection: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 根据ID获取收藏 | Get collection by ID
   * @param id 收藏ID | Collection ID
   * @returns 收藏信息或null | Collection information or null
   */
  public async getById(id: string): Promise<Collection | null> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      predicates.equalTo(TableSchema.COLLECTION_ID, id);
      
      const resultSet = await db.query(predicates);
      const collections = this.parseResultSet(resultSet);
      
      return collections.length > 0 ? collections[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collection by id: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }

  /**
   * 根据站点和内容ID获取收藏 | Get collection by site and content ID
   * @param siteKey 站点标识 | Site identifier
   * @param contentId 内容ID | Content ID
   * @returns 收藏信息或null | Collection information or null
   */
  public async getByContent(siteKey: string, contentId: string): Promise<Collection | null> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      predicates.equalTo(TableSchema.COLLECTION_SITE_KEY, siteKey);
      predicates.equalTo(TableSchema.COLLECTION_CONTENT_ID, contentId);
      
      const resultSet = await db.query(predicates);
      const collections = this.parseResultSet(resultSet);
      
      return collections.length > 0 ? collections[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collection by content: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }

  /**
   * 获取所有收藏 | Get all collections
   * @param limit 限制数量 | Limit count
   * @param offset 偏移量 | Offset
   * @returns 收藏列表 | Collection list
   */
  public async getAll(limit: number = 100, offset: number = 0): Promise<Collection[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      predicates.orderByDesc(TableSchema.COLLECTION_TIMESTAMP);
      predicates.limit(limit, offset);
      
      const resultSet = await db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all collections: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 根据站点获取收藏 | Get collections by site
   * @param siteKey 站点标识 | Site identifier
   * @param limit 限制数量 | Limit count
   * @returns 收藏列表 | Collection list
   */
  public async getBySite(siteKey: string, limit: number = 100): Promise<Collection[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      predicates.equalTo(TableSchema.COLLECTION_SITE_KEY, siteKey);
      predicates.orderByDesc(TableSchema.COLLECTION_TIMESTAMP);
      predicates.limit(limit);
      
      const resultSet = await db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collections by site: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 根据类型获取收藏 | Get collections by type
   * @param type 内容类型 | Content type
   * @param limit 限制数量 | Limit count
   * @returns 收藏列表 | Collection list
   */
  public async getByType(type: string, limit: number = 100): Promise<Collection[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      predicates.equalTo(TableSchema.COLLECTION_TYPE, type);
      predicates.orderByDesc(TableSchema.COLLECTION_TIMESTAMP);
      predicates.limit(limit);
      
      const resultSet = await db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collections by type: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 检查是否已收藏 | Check if already collected
   * @param siteKey 站点标识 | Site identifier
   * @param contentId 内容ID | Content ID
   * @returns 是否已收藏 | Whether it is collected
   */
  public async isCollected(siteKey: string, contentId: string): Promise<boolean> {
    try {
      const collection = await this.getByContent(siteKey, contentId);
      return collection !== null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to check if collected: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 批量保存收藏 | Batch save collections
   * @param collections 收藏列表 | Collection list
   */
  public async batchSave(collections: Collection[]): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      await db.beginTransaction();
      
      try {
        for (const collection of collections) {
          await this.saveOrUpdate(collection);
        }
        await db.commit();
        Logger.info(this.TAG, `Batch saved ${collections.length} collections`);
      } catch (error) {
        await db.rollback();
        throw error;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch save collections: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 删除站点相关的所有收藏 | Delete all collections for site
   * @param siteKey 站点标识 | Site identifier
   */
  public async deleteBySite(siteKey: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      predicates.equalTo(TableSchema.COLLECTION_SITE_KEY, siteKey);
      
      const rowsAffected = await db.delete(predicates);
      Logger.info(this.TAG, `Deleted ${rowsAffected} collections for site: ${siteKey}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete collections by site: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 清空所有收藏 | Clear all collections
   */
  public async clearAll(): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates(TableSchema.COLLECTION_TABLE);
      const rowsAffected = await db.delete(predicates);
      Logger.info(this.TAG, `All collections cleared, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all collections: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 获取收藏总数 | Get collection count
   * @returns 收藏总数 | Collection count
   */
  public async getCount(): Promise<number> {
    try {
      const db = await this.databaseManager.getDatabase();
      const sql = `SELECT COUNT(*) FROM ${TableSchema.COLLECTION_TABLE}`;
      const resultSet = await db.querySql(sql, []);
      
      let count = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = resultSet.getLong(0);
      }
      resultSet.close();
      
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collection count: ${error instanceof Error ? error.message : String(error)}`);
      return 0;
    }
  }

  /**
   * 将ResultSet解析为Collection数组 | Parse ResultSet to Collection array
   * @param resultSet 查询结果集 | Query result set
   * @returns Collection数组 | Collection array
   */
  private parseResultSet(resultSet: ResultSet): Collection[] {
    const collections: Collection[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const collection: Collection = {
            id: resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_ID)),
            contentId: resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_CONTENT_ID)),
            title: resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_TITLE)),
            cover: resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_COVER)),
            siteKey: resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_SITE_KEY)),
            siteName: resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_SITE_NAME)),
            url: resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_URL)),
            type: resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_TYPE)),
            timestamp: resultSet.getLong(resultSet.getColumnIndex(TableSchema.COLLECTION_TIMESTAMP)),
            extraInfo: this.parseJsonString(resultSet.getString(resultSet.getColumnIndex(TableSchema.COLLECTION_EXTRA_INFO)))
          };
          collections.push(collection);
        } while (resultSet.goToNextRow());
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse result set: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      resultSet.close();
    }
    
    return collections;
  }

  /**
   * 将Collection对象转换为ValuesBucket | Convert Collection object to ValuesBucket
   * @param collection 收藏信息 | Collection information
   * @returns ValuesBucket
   */
  private collectionToValuesBucket(collection: Collection): ValuesBucket {
    const values: ValuesBucket = {
      [TableSchema.COLLECTION_ID]: collection.id,
      [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now(),
      [TableSchema.COLLECTION_EXTRA_INFO]: this.stringifyJson(collection.extraInfo || {})
    };
    
    return values;
  }

  /**
   * 解析JSON字符串 | Parse JSON string
   * @param jsonString JSON字符串 | JSON string
   * @returns 解析后的对象 | Parsed object
   */
  private parseJsonString(jsonString?: string): Record<string, unknown> {
    if (!jsonString) return {};
    try {
      return JSON.parse(jsonString);
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse JSON string: ${error instanceof Error ? error.message : String(error)}`);
      return {};
    }
  }

  /**
   * 将对象转换为JSON字符串 | Convert object to JSON string
   * @param obj 要转换的对象 | Object to convert
   * @returns JSON字符串 | JSON string
   */
  private stringifyJson(obj: Record<string, unknown>): string {
    try {
      return JSON.stringify(obj);
    } catch (error) {
      Logger.error(this.TAG, `Failed to stringify JSON: ${error instanceof Error ? error.message : String(error)}`);
      return '{}';
    }
  }

  /**
   * 根据条件查询 | Query by conditions
   * @param conditions 查询条件 | Query conditions
   * @param params 参数数组 | Parameter array
   * @param orderBy 排序方式 | Order by
   * @param limit 限制数量 | Limit count
   * @param offset 偏移量 | Offset
   * @returns 查询结果 | Query result
   */
  public async query(conditions: string = '', params: Array<string | number | boolean> = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0): Promise<Collection[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      let sql = `SELECT * FROM ${TableSchema.COLLECTION_TABLE}`;
      
      if (conditions) {
        sql += ` WHERE ${conditions}`;
      }
      
      sql += ` ORDER BY ${orderBy}`;
      
      if (limit > 0) {
        sql += ` LIMIT ${limit} OFFSET ${offset}`;
      }
      
      const resultSet = await db.querySql(sql, params);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to query collections: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  /**
   * 查询单条记录 | Query single record
   * @param options 查询选项 | Query options
   * @returns 单条收藏记录或null | Single collection record or null
   */
  public async queryOne(options: {
    conditions?: string;
    params?: Array<string | number | boolean>;
    orderBy?: string;
  } = {}): Promise<Collection | null> {
    try {
      const { conditions = '', params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1);
      return collections.length > 0 ? collections[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to query one collection: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }
}

export default CollectionDao;