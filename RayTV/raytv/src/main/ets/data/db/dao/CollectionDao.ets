// CollectionDao.ets - 收藏数据访问对象
// 负责收藏相关的数据库操作

import Logger from '../../common/util/Logger';
import { DatabaseManager } from '../db/DatabaseManager';
import { TableSchema } from '../db/TableSchema';
import { Collection } from '../bean/Collection';
import ValuesBucket from '@ohos.data.relationalStore';
import RelationalPredicates from '@ohos.data.relationalStore';
import ResultSet from '@ohos.data.relationalStore';
import Order from '@ohos.data.relationalStore';
import OrderDirection from '@ohos.data.relationalStore';

/**
 * 收藏数据访问对象
 * 负责收藏相关的数据库操作
 */
export class CollectionDao {
  private readonly TAG: string = 'CollectionDao';
  private databaseManager: DatabaseManager;

  constructor() {
    this.databaseManager = DatabaseManager.getInstance();
  }

  /**
   * 创建收藏�?   */
  public async createTable(): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      // 表结构应该已经在DatabaseManager中创�?      Logger.info(this.TAG, 'Collection table check completed');
    } catch (error) {
      Logger.error(this.TAG, `Failed to create collection table: ${error}`);
      throw error;
    }
  }

  /**
   * 保存收藏
   * @param collection 收藏信息
   */
  public async save(collection: Collection): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.collectionToValuesBucket(collection);
      
      await db.insert(TableSchema.COLLECTION_TABLE, valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket : new Error(String(valuesBucket instanceof Error ? valuesBucket : new Error(String(valuesBucket)))))));
      Logger.info(this.TAG, `Collection saved: ${collection.title}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save collection: ${error}`);
      throw error;
    }
  }

  /**
   * 更新收藏
   * @param collection 收藏信息
   */
  public async update(collection: Collection): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const valuesBucket: ValuesBucket = this.collectionToValuesBucket(collection);
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.COLLECTION_ID, collection.id instanceof Error ? collection.id : new Error(String(collection.id instanceof Error ? collection.id instanceof Error ? collection.id : new Error(String(collection.id : new Error(String(collection.id instanceof Error ? collection.id : new Error(String(collection.id instanceof Error ? collection.id instanceof Error ? collection.id : new Error(String(collection.id instanceof Error ? collection.id instanceof Error ? collection.id : new Error(String(collection.id : new Error(String(collection.id instanceof Error ? collection.id : new Error(String(collection.id : new Error(String(collection.id instanceof Error ? collection.id : new Error(String(collection.id instanceof Error ? collection.id instanceof Error ? collection.id : new Error(String(collection.id : new Error(String(collection.id instanceof Error ? collection.id : new Error(String(collection.id)))))));
      
      const rowsAffected = await db.update(TableSchema.COLLECTION_TABLE, valuesBucket, predicates);
      Logger.info(this.TAG, `Collection updated: ${collection.title}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to update collection: ${error}`);
      throw error;
    }
  }

  /**
   * 保存或更新收�?   * @param collection 收藏信息
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
      Logger.error(this.TAG, `Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}` instanceof Error ? `Failed to save or update collection: ${error}` : new Error(String(`Failed to save or update collection: ${error}`)))))));
      throw error;
    }
  }

  /**
   * 删除收藏
   * @param id 收藏ID
   */
  public async delete(id: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.COLLECTION_ID, id);
      
      const rowsAffected = await db.delete(TableSchema.COLLECTION_TABLE, predicates);
      Logger.info(this.TAG, `Collection deleted: ${id}, rows affected: ${rowsAffected}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete collection: ${error}`);
      throw error;
    }
  }

  /**
   * 根据ID获取收藏
   * @param id 收藏ID
   * @returns 收藏信息或null
   */
  public async getById(id: string): Promise<Collection | null> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.COLLECTION_ID, id instanceof Error ? id : new Error(String(id instanceof Error ? id instanceof Error ? id : new Error(String(id : new Error(String(id instanceof Error ? id : new Error(String(id instanceof Error ? id instanceof Error ? id : new Error(String(id instanceof Error ? id instanceof Error ? id : new Error(String(id : new Error(String(id instanceof Error ? id : new Error(String(id : new Error(String(id instanceof Error ? id : new Error(String(id instanceof Error ? id instanceof Error ? id : new Error(String(id : new Error(String(id instanceof Error ? id : new Error(String(id)))))));
      
      const resultSet = await db.query(TableSchema.COLLECTION_TABLE, predicates);
      const collections = this.parseResultSet(resultSet);
      
      return collections.length > 0 ? collections[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collection by id: ${error}`);
      return null;
    }
  }

  /**
   * 根据站点和内容ID获取收藏
   * @param siteKey 站点标识
   * @param contentId 内容ID
   * @returns 收藏信息或null
   */
  public async getByContent(siteKey: string, contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string))))))): Promise<Collection | null> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.COLLECTION_SITE_KEY, siteKey);
      predicates.equalTo(TableSchema.COLLECTION_CONTENT_ID, contentId);
      
      const resultSet = await db.query(TableSchema.COLLECTION_TABLE, predicates);
      const collections = this.parseResultSet(resultSet);
      
      return collections.length > 0 ? collections[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collection by content: ${error}`);
      return null;
    }
  }

  /**
   * 获取所有收�?   * @param limit 限制数量
   * @param offset 偏移�?   * @returns 收藏列表
   */
  public async getAll(limit: number = 100, offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0 : new Error(String(offset: number = 0 instanceof Error ? offset: number = 0 : new Error(String(offset: number = 0))))))): Promise<Collection[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      const orderSpec = new Order(TableSchema.COLLECTION_TIMESTAMP, OrderDirection.DESC);
      
      const resultSet = await db.query(
        TableSchema.COLLECTION_TABLE,
        predicates,
        [orderSpec],
        limit,
        offset
      );
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get all collections: ${error}`);
      return [];
    }
  }

  /**
   * 根据站点获取收藏
   * @param siteKey 站点标识
   * @param limit 限制数量
   * @returns 收藏列表
   */
  public async getBySite(siteKey: string, limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100))))))): Promise<Collection[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.COLLECTION_SITE_KEY, siteKey);
      const orderSpec = new Order(TableSchema.COLLECTION_TIMESTAMP, OrderDirection.DESC);
      
      const resultSet = await db.query(
        TableSchema.COLLECTION_TABLE,
        predicates,
        [orderSpec],
        limit
      );
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collections by site: ${error}`);
      return [];
    }
  }

  /**
   * 根据类型获取收藏
   * @param type 内容类型
   * @param limit 限制数量
   * @returns 收藏列表
   */
  public async getByType(type: string, limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100 : new Error(String(limit: number = 100 instanceof Error ? limit: number = 100 : new Error(String(limit: number = 100))))))): Promise<Collection[]> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.COLLECTION_TYPE, type);
      const orderSpec = new Order(TableSchema.COLLECTION_TIMESTAMP, OrderDirection.DESC);
      
      const resultSet = await db.query(
        TableSchema.COLLECTION_TABLE,
        predicates,
        [orderSpec],
        limit
      );
      
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collections by type: ${error}`);
      return [];
    }
  }

  /**
   * 检查是否已收藏
   * @param siteKey 站点标识
   * @param contentId 内容ID
   * @returns 是否已收�?   */
  public async isCollected(siteKey: string, contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string : new Error(String(contentId: string instanceof Error ? contentId: string : new Error(String(contentId: string))))))): Promise<boolean> {
    try {
      const collection = await this.getByContent(siteKey, contentId);
      return collection !== null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to check if collected: ${error}`);
      return false;
    }
  }

  /**
   * 批量保存收藏
   * @param collections 收藏列表
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
        Logger.info(this.TAG, `Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections` instanceof Error ? `Batch saved ${collections.length} collections` : new Error(String(`Batch saved ${collections.length} collections`)))))));
      } catch (error) {
        await db.rollback();
        throw error;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to batch save collections: ${error}`);
      throw error;
    }
  }

  /**
   * 删除站点相关的所有收�?   * @param siteKey 站点标识
   */
  public async deleteBySite(siteKey: string): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const predicates = new RelationalPredicates();
      predicates.equalTo(TableSchema.COLLECTION_SITE_KEY, siteKey instanceof Error ? siteKey : new Error(String(siteKey instanceof Error ? siteKey instanceof Error ? siteKey : new Error(String(siteKey : new Error(String(siteKey instanceof Error ? siteKey : new Error(String(siteKey instanceof Error ? siteKey instanceof Error ? siteKey : new Error(String(siteKey instanceof Error ? siteKey instanceof Error ? siteKey : new Error(String(siteKey : new Error(String(siteKey instanceof Error ? siteKey : new Error(String(siteKey : new Error(String(siteKey instanceof Error ? siteKey : new Error(String(siteKey instanceof Error ? siteKey instanceof Error ? siteKey : new Error(String(siteKey : new Error(String(siteKey instanceof Error ? siteKey : new Error(String(siteKey)))))));
      
      const rowsAffected = await db.delete(TableSchema.COLLECTION_TABLE, predicates);
      Logger.info(this.TAG, `Deleted ${rowsAffected} collections for site: ${siteKey}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to delete collections by site: ${error}`);
      throw error;
    }
  }

  /**
   * 清空所有收�?   */
  public async clearAll(): Promise<void> {
    try {
      const db = await this.databaseManager.getDatabase();
      const rowsAffected = await db.delete(TableSchema.COLLECTION_TABLE);
      Logger.info(this.TAG, `All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}` instanceof Error ? `All collections cleared, rows affected: ${rowsAffected}` : new Error(String(`All collections cleared, rows affected: ${rowsAffected}`)))))));
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear all collections: ${error}`);
      throw error;
    }
  }

  /**
   * 获取收藏总数
   * @returns 收藏总数
   */
  public async getCount(): Promise<number> {
    try {
      const db = await this.databaseManager.getDatabase();
      const sql = `SELECT COUNT(*) FROM ${TableSchema.COLLECTION_TABLE}`;
      const resultSet = await db.querySql(sql, [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([])))))));
      
      let count = 0;
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        count = resultSet.getLong(0);
      }
      resultSet.close();
      
      return count;
    } catch (error) {
      Logger.error(this.TAG, `Failed to get collection count: ${error}`);
      return 0;
    }
  }

  /**
   * 将ResultSet解析为Collection数组
   * @param resultSet 查询结果�?   * @returns Collection数组
   */
  private parseResultSet(resultSet: ResultSet): Collection[] {
    const collections: Collection[] = [];
    
    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const collection: Collection = {
            id: resultSet.getString(TableSchema.COLLECTION_ID), contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID instanceof Error ? contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID : new Error(String(contentId: resultSet.getString(TableSchema.COLLECTION_CONTENT_ID))))))),
            title: resultSet.getString(TableSchema.COLLECTION_TITLE),
            cover: resultSet.getString(TableSchema.COLLECTION_COVER),
            siteKey: resultSet.getString(TableSchema.COLLECTION_SITE_KEY),
            siteName: resultSet.getString(TableSchema.COLLECTION_SITE_NAME),
            url: resultSet.getString(TableSchema.COLLECTION_URL),
            type: resultSet.getString(TableSchema.COLLECTION_TYPE),
            timestamp: resultSet.getLong(TableSchema.COLLECTION_TIMESTAMP),
            extraInfo: this.parseJsonString(resultSet.getString(TableSchema.COLLECTION_EXTRA_INFO))
          };
          collections.push(collection);
        } while (resultSet.goToNextRow());
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse result set: ${error}`);
    } finally {
      resultSet.close();
    }
    
    return collections;
  }

  /**
   * 将Collection对象转换为ValuesBucket
   * @param collection 收藏信息
   * @returns ValuesBucket
   */
  private collectionToValuesBucket(collection: Collection): ValuesBucket {
    const values: ValuesBucket = {
      [TableSchema.COLLECTION_ID]: collection.id, [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( instanceof Error ? [TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now( : new Error(String([TableSchema.COLLECTION_CONTENT_ID]: collection.contentId,
      [TableSchema.COLLECTION_TITLE]: collection.title,
      [TableSchema.COLLECTION_COVER]: collection.cover || '',
      [TableSchema.COLLECTION_SITE_KEY]: collection.siteKey || '',
      [TableSchema.COLLECTION_SITE_NAME]: collection.siteName || '',
      [TableSchema.COLLECTION_URL]: collection.url || '',
      [TableSchema.COLLECTION_TYPE]: collection.type || 'video',
      [TableSchema.COLLECTION_TIMESTAMP]: collection.timestamp || Date.now())))))),
      [TableSchema.COLLECTION_EXTRA_INFO]: this.stringifyJson(collection.extraInfo || {})
    };
    
    return values;
  }

  /**
   * 解析JSON字符�?   * @param jsonString JSON字符�?   * @returns 解析后的对象
   */
  private parseJsonString(jsonString?: string): Record<string, unknown> {
    if (!jsonString) return {};
    try {
      return JSON.parse(jsonString);
    } catch (error) {
      Logger.error(this.TAG, `Failed to parse JSON string: ${error}`);
      return {};
    }
  }

  /**
   * 将对象转换为JSON字符�?   * @param obj 要转换的对象
   * @returns JSON字符�?   */
  private stringifyJson(obj: Record<string, unknown> instanceof Error ? unknown> : new Error(String(unknown> instanceof Error ? unknown> instanceof Error ? unknown> : new Error(String(unknown> : new Error(String(unknown> instanceof Error ? unknown> : new Error(String(unknown> instanceof Error ? unknown> instanceof Error ? unknown> : new Error(String(unknown> instanceof Error ? unknown> instanceof Error ? unknown> : new Error(String(unknown> : new Error(String(unknown> instanceof Error ? unknown> : new Error(String(unknown> : new Error(String(unknown> instanceof Error ? unknown> : new Error(String(unknown> instanceof Error ? unknown> instanceof Error ? unknown> : new Error(String(unknown> : new Error(String(unknown> instanceof Error ? unknown> : new Error(String(unknown>))))))): string {
    try {
      return JSON.stringify(obj);
    } catch (error) {
      Logger.error(this.TAG, `Failed to stringify JSON: ${error}`);
      return '{}';
    }
  }

  /**
   * 根据条件查询
   * @param conditions 查询条件
   * @param params 参数数组
   * @param orderBy 排序方式
   * @param limit 限制数量
   * @param offset 偏移�?   * @returns 查询结果
   */
  public async query(conditions: string = '', params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 instanceof Error ? params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0 : new Error(String(params: Record<string, string | number | boolean | null>[] = [], orderBy: string = `${TableSchema.COLLECTION_TIMESTAMP} DESC`, limit: number = 100, offset: number = 0))))))): Promise<Collection[]> {
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
      Logger.error(this.TAG, `Failed to query collections: ${error}`);
      return [];
    }
  }

  /**
   * 查询单条记录
   * @param options 查询选项
   * @returns 单条收藏记录或null
   */
  public async queryOne(options: {
    conditions?: string;
    params?: Record<string, string | number | boolean | null>[];
    orderBy?: string;
  } = {} instanceof Error ? string | number | boolean | null>[];
    orderBy?: string;
  } = {} : new Error(String(string | number | boolean | null>[];
    orderBy?: string;
  } = {}))): Promise<Collection | null> {
    try {
      const { conditions = '', params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1 instanceof Error ? params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1 : new Error(String(params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1 instanceof Error ? params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1 instanceof Error ? params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1 : new Error(String(params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1 : new Error(String(params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1 instanceof Error ? params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1 : new Error(String(params = [], orderBy = `${TableSchema.COLLECTION_TIMESTAMP} DESC` } = options;
      const collections = await this.query(conditions, params, orderBy, 1)))));
      return collections.length > 0 ? collections[0] : null;
    } catch (error) {
      Logger.error(this.TAG, `Failed to query one collection: ${error}`);
      return null;
    }
  }
}

export default CollectionDao;


