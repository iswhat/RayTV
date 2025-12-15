// CollectionRepository.ets - 收藏数据仓库
// 负责收藏内容相关数据的存储、读取和管理

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { COLLECTION_TABLE, COLLECTION_FOLDER_TABLE } from '../db/TableSchema';
import { CollectionItemType, CollectionVisibility, CollectionSortType } from '../model/LocalModel';
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';

const TAG = 'CollectionRepository';
const COLLECTION_CACHE_PREFIX = 'collection_item_';
const COLLECTION_LIST_CACHE = 'collection_list_cache';

export interface CollectionItem {
  id?: string;
  title: string;
  subtitle?: string;
  coverUrl?: string;
  itemType: CollectionItemType;
  contentType: string;
  siteId: string;
  contentId: string;
  folderId?: string;
  tags?: string[];
  sortOrder?: number;
  visibility?: CollectionVisibility;
  createTime?: number;
  updateTime?: number;
  extraData?: Record<string, unknown>;
}

export interface CollectionFolder {
  id?: string;
  name: string;
  description?: string;
  coverUrl?: string;
  sortOrder?: number;
  createTime?: number;
  updateTime?: number;
  itemCount?: number;
}

export class CollectionRepository {
  private static instance: CollectionRepository;
  private sqliteHelper: SQLiteHelper;
  private storageUtil: StorageUtil;
  
  private constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 获取收藏仓库单例实例
   */
  public static getInstance(): CollectionRepository {
    if (!CollectionRepository.instance) {
      CollectionRepository.instance = new CollectionRepository();
    }
    return CollectionRepository.instance;
  }
  
  /**
   * 添加收藏项
   * @param item 收藏项
   * @returns 是否添加成功
   */
  public async addCollection(item: CollectionItem): Promise<boolean> {
    try {
      Logger.debug(TAG, `Adding collection: ${item.title}`);
      
      // 检查是否已存在相同内容的收藏
      if (await this.isContentCollected(item.contentType, item.contentId)) {
        Logger.warn(TAG, `Content already collected: ${item.contentId}`);
        return false;
      }
      
      const collectionData = {
        [COLLECTION_TABLE.COLUMNS.TITLE]: item.title,
        [COLLECTION_TABLE.COLUMNS.SUBTITLE]: item.subtitle || '',
        [COLLECTION_TABLE.COLUMNS.COVER_URL]: item.coverUrl || '',
        [COLLECTION_TABLE.COLUMNS.ITEM_TYPE]: item.itemType,
        [COLLECTION_TABLE.COLUMNS.CONTENT_TYPE]: item.contentType,
        [COLLECTION_TABLE.COLUMNS.SITE_ID]: item.siteId,
        [COLLECTION_TABLE.COLUMNS.CONTENT_ID]: item.contentId,
        [COLLECTION_TABLE.COLUMNS.FOLDER_ID]: item.folderId || null,
        [COLLECTION_TABLE.COLUMNS.TAGS]: item.tags?.join(',') || '',
        [COLLECTION_TABLE.COLUMNS.SORT_ORDER]: item.sortOrder || 0,
        [COLLECTION_TABLE.COLUMNS.VISIBILITY]: item.visibility || CollectionVisibility.PUBLIC,
        [COLLECTION_TABLE.COLUMNS.CREATE_TIME]: Date.now(),
        [COLLECTION_TABLE.COLUMNS.UPDATE_TIME]: Date.now(),
        [COLLECTION_TABLE.COLUMNS.EXTRA_DATA]: JSON.stringify(item.extraData || {})
      };
      
      const insertResult = await this.sqliteHelper.insert(COLLECTION_TABLE.TABLE_NAME, collectionData);
      
      if (insertResult.success && insertResult.lastInsertRowId) {
        item.id = insertResult.lastInsertRowId.toString();
        
        // 更新缓存
        await this.cacheCollectionItem(item);
        await this.invalidateCollectionListCache();
        
        Logger.info(TAG, `Collection added successfully: ${item.title}`);
      }
      
      return insertResult.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to add collection: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 更新收藏项
   * @param item 收藏项
   * @returns 是否更新成功
   */
  public async updateCollection(item: CollectionItem): Promise<boolean> {
    try {
      if (!item.id) {
        Logger.error(TAG, 'Collection ID is required for update');
        return false;
      }
      
      Logger.debug(TAG, `Updating collection: ${item.id}`);
      
      const collectionData = {
        [COLLECTION_TABLE.COLUMNS.TITLE]: item.title,
        [COLLECTION_TABLE.COLUMNS.SUBTITLE]: item.subtitle || '',
        [COLLECTION_TABLE.COLUMNS.COVER_URL]: item.coverUrl || '',
        [COLLECTION_TABLE.COLUMNS.ITEM_TYPE]: item.itemType,
        [COLLECTION_TABLE.COLUMNS.CONTENT_TYPE]: item.contentType,
        [COLLECTION_TABLE.COLUMNS.SITE_ID]: item.siteId,
        [COLLECTION_TABLE.COLUMNS.FOLDER_ID]: item.folderId || null,
        [COLLECTION_TABLE.COLUMNS.TAGS]: item.tags?.join(',') || '',
        [COLLECTION_TABLE.COLUMNS.SORT_ORDER]: item.sortOrder || 0,
        [COLLECTION_TABLE.COLUMNS.VISIBILITY]: item.visibility || CollectionVisibility.PUBLIC,
        [COLLECTION_TABLE.COLUMNS.UPDATE_TIME]: Date.now(),
        [COLLECTION_TABLE.COLUMNS.EXTRA_DATA]: JSON.stringify(item.extraData || {})
      };
      
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.ID,
        value: item.id
      }];
      
      const updateResult = await this.sqliteHelper.update(COLLECTION_TABLE.TABLE_NAME, collectionData, conditions);
      
      if (updateResult.success) {
        // 更新缓存
        await this.cacheCollectionItem(item);
        await this.invalidateCollectionListCache();
        
        Logger.info(TAG, `Collection updated successfully: ${item.id}`);
      }
      
      return updateResult.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to update collection: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 删除收藏项
   * @param collectionId 收藏项ID
   * @returns 是否删除成功
   */
  public async removeCollection(collectionId: string): Promise<boolean> {
    try {
      Logger.debug(TAG, `Removing collection: ${collectionId}`);
      
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.ID,
        value: collectionId
      }];
      
      const deleteResult = await this.sqliteHelper.delete(COLLECTION_TABLE.TABLE_NAME, conditions);
      
      if (deleteResult.success) {
        // 清除缓存
        await this.removeCachedCollectionItem(collectionId);
        await this.invalidateCollectionListCache();
        
        Logger.info(TAG, `Collection removed successfully: ${collectionId}`);
      }
      
      return deleteResult.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to remove collection: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 批量删除收藏项
   * @param collectionIds 收藏项ID列表
   * @returns 删除成功的数量
   */
  public async batchRemoveCollections(collectionIds: string[]): Promise<number> {
    if (!collectionIds || collectionIds.length === 0) {
      return 0;
    }
    
    try {
      Logger.debug(TAG, `Batch removing ${collectionIds.length} collections`);
      
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.ID,
        operator: 'IN',
        value: collectionIds
      }];
      
      const deleteResult = await this.sqliteHelper.delete(COLLECTION_TABLE.TABLE_NAME, conditions);
      
      if (deleteResult.success) {
        // 清除缓存
        for (const id of collectionIds) {
          await this.removeCachedCollectionItem(id);
        }
        await this.invalidateCollectionListCache();
        
        Logger.info(TAG, `Batch removed ${deleteResult.affectedRows} collections`);
      }
      
      return deleteResult.affectedRows || 0;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to batch remove collections: ${errorMsg}`);
      return 0;
    }
  }
  
  /**
   * 获取所有收藏项
   * @param sortType 排序类型
   * @param limit 限制数量
   * @param offset 偏移量
   * @returns 收藏项列表
   */
  public async getAllCollections(
    sortType: CollectionSortType = CollectionSortType.CREATE_TIME_DESC,
    limit: number = 50,
    offset: number = 0
  ): Promise<CollectionItem[]> {
    try {
      // 构建排序选项
      const sortOptions = this.buildSortOptions(sortType);
      
      // 查询数据库
      const collectionRecords = await this.sqliteHelper.query(
        COLLECTION_TABLE.TABLE_NAME,
        ['*'],
        undefined,
        sortOptions,
        limit,
        offset
      );
      
      // 转换为CollectionItem对象
      const collections = this.convertToCollectionObjects(collectionRecords);
      
      Logger.info(TAG, `Retrieved ${collections.length} collections`);
      return collections;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get all collections: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 根据ID获取收藏项
   * @param collectionId 收藏项ID
   * @returns 收藏项或null
   */
  public async getCollectionById(collectionId: string): Promise<CollectionItem | null> {
    try {
      // 尝试从缓存获取
      const cachedItem = await this.getCachedCollectionItem(collectionId);
      if (cachedItem) {
        Logger.debug(TAG, `Returning collection ${collectionId} from cache`);
        return cachedItem;
      }
      
      // 查询数据库
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.ID,
        value: collectionId
      }];
      
      const collectionRecord = await this.sqliteHelper.getFirst(
        COLLECTION_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!collectionRecord) {
        return null;
      }
      
      // 转换为CollectionItem对象
      const collection = this.convertToCollectionObject(collectionRecord);
      
      // 更新缓存
      await this.cacheCollectionItem(collection);
      
      return collection;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get collection by ID: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 根据内容ID检查是否已收藏
   * @param contentType 内容类型
   * @param contentId 内容ID
   * @returns 是否已收藏
   */
  public async isContentCollected(contentType: string, contentId: string): Promise<boolean> {
    try {
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.CONTENT_TYPE,
        value: contentType
      }, {
        column: COLLECTION_TABLE.COLUMNS.CONTENT_ID,
        value: contentId
      }];
      
      return await this.sqliteHelper.exists(COLLECTION_TABLE.TABLE_NAME, conditions);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to check if content is collected: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 根据内容ID获取收藏项
   * @param contentType 内容类型
   * @param contentId 内容ID
   * @returns 收藏项或null
   */
  public async getCollectionByContent(contentType: string, contentId: string): Promise<CollectionItem | null> {
    try {
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.CONTENT_TYPE,
        value: contentType
      }, {
        column: COLLECTION_TABLE.COLUMNS.CONTENT_ID,
        value: contentId
      }];
      
      const collectionRecord = await this.sqliteHelper.getFirst(
        COLLECTION_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!collectionRecord) {
        return null;
      }
      
      return this.convertToCollectionObject(collectionRecord);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get collection by content: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 按文件夹获取收藏项
   * @param folderId 文件夹ID
   * @param sortType 排序类型
   * @returns 收藏项列表
   */
  public async getCollectionsByFolder(
    folderId: string, 
    sortType: CollectionSortType = CollectionSortType.TITLE_ASC
  ): Promise<CollectionItem[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.FOLDER_ID,
        value: folderId
      }];
      
      const sortOptions = this.buildSortOptions(sortType);
      
      const collectionRecords = await this.sqliteHelper.query(
        COLLECTION_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      const collections = this.convertToCollectionObjects(collectionRecords);
      Logger.info(TAG, `Retrieved ${collections.length} collections from folder ${folderId}`);
      return collections;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get collections by folder: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 按标签获取收藏项
   * @param tag 标签
   * @param sortType 排序类型
   * @returns 收藏项列表
   */
  public async getCollectionsByTag(
    tag: string, 
    sortType: CollectionSortType = CollectionSortType.CREATE_TIME_DESC
  ): Promise<CollectionItem[]> {
    try {
      // 使用LIKE查询包含指定标签的收藏项
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.TAGS,
        operator: 'LIKE',
        value: `%${tag}%`
      }];
      
      const sortOptions = this.buildSortOptions(sortType);
      
      const collectionRecords = await this.sqliteHelper.query(
        COLLECTION_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      // 过滤出确实包含指定标签的项（避免LIKE匹配不准确）
      const collections = this.convertToCollectionObjects(collectionRecords).filter(item => 
        item.tags?.includes(tag)
      );
      
      Logger.info(TAG, `Retrieved ${collections.length} collections with tag ${tag}`);
      return collections;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get collections by tag: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 按类型获取收藏项
   * @param contentType 内容类型
   * @param sortType 排序类型
   * @returns 收藏项列表
   */
  public async getCollectionsByContentType(
    contentType: string, 
    sortType: CollectionSortType = CollectionSortType.TITLE_ASC
  ): Promise<CollectionItem[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.CONTENT_TYPE,
        value: contentType
      }];
      
      const sortOptions = this.buildSortOptions(sortType);
      
      const collectionRecords = await this.sqliteHelper.query(
        COLLECTION_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      const collections = this.convertToCollectionObjects(collectionRecords);
      Logger.info(TAG, `Retrieved ${collections.length} collections of type ${contentType}`);
      return collections;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get collections by content type: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 获取收藏项总数
   * @returns 收藏项总数
   */
  public async getCollectionCount(): Promise<number> {
    try {
      return await this.sqliteHelper.count(COLLECTION_TABLE.TABLE_NAME);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get collection count: ${errorMsg}`);
      return 0;
    }
  }
  
  /**
   * 创建收藏文件夹
   * @param folder 文件夹信息
   * @returns 是否创建成功
   */
  public async createFolder(folder: CollectionFolder): Promise<boolean> {
    try {
      Logger.debug(TAG, `Creating collection folder: ${folder.name}`);
      
      const folderData: Record<string, string | number | boolean | null> = {
        [COLLECTION_FOLDER_TABLE.COLUMNS.NAME]: folder.name,
        [COLLECTION_FOLDER_TABLE.COLUMNS.DESCRIPTION]: folder.description || '',
        [COLLECTION_FOLDER_TABLE.COLUMNS.COVER_URL]: folder.coverUrl || '',
        [COLLECTION_FOLDER_TABLE.COLUMNS.SORT_ORDER]: folder.sortOrder || 0,
        [COLLECTION_FOLDER_TABLE.COLUMNS.CREATE_TIME]: Date.now(),
        [COLLECTION_FOLDER_TABLE.COLUMNS.UPDATE_TIME]: Date.now(),
        [COLLECTION_FOLDER_TABLE.COLUMNS.ITEM_COUNT]: 0
      };
      
      const insertResult = await this.sqliteHelper.insert(COLLECTION_FOLDER_TABLE.TABLE_NAME, folderData);
      
      if (insertResult.success && insertResult.lastInsertRowId) {
        folder.id = insertResult.lastInsertRowId.toString();
        Logger.info(TAG, `Collection folder created successfully: ${folder.name}`);
      }
      
      return insertResult.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to create collection folder: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 更新收藏文件夹
   * @param folder 文件夹信息
   * @returns 是否更新成功
   */
  public async updateFolder(folder: CollectionFolder): Promise<boolean> {
    try {
      if (!folder.id) {
        Logger.error(TAG, 'Folder ID is required for update');
        return false;
      }
      
      Logger.debug(TAG, `Updating collection folder: ${folder.id}`);
      
      const folderData: Record<string, string | number | boolean | null> = {
        [COLLECTION_FOLDER_TABLE.COLUMNS.NAME]: folder.name,
        [COLLECTION_FOLDER_TABLE.COLUMNS.DESCRIPTION]: folder.description || '',
        [COLLECTION_FOLDER_TABLE.COLUMNS.COVER_URL]: folder.coverUrl || '',
        [COLLECTION_FOLDER_TABLE.COLUMNS.SORT_ORDER]: folder.sortOrder || 0,
        [COLLECTION_FOLDER_TABLE.COLUMNS.UPDATE_TIME]: Date.now()
      };
      
      const conditions: QueryCondition[] = [{
        column: COLLECTION_FOLDER_TABLE.COLUMNS.ID,
        value: folder.id
      }];
      
      const updateResult = await this.sqliteHelper.update(COLLECTION_FOLDER_TABLE.TABLE_NAME, folderData, conditions);
      
      if (updateResult.success) {
        Logger.info(TAG, `Collection folder updated successfully: ${folder.id}`);
      }
      
      return updateResult.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to update collection folder: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 删除收藏文件夹
   * @param folderId 文件夹ID
   * @returns 是否删除成功
   */
  public async deleteFolder(folderId: string): Promise<boolean> {
    try {
      Logger.debug(TAG, `Deleting collection folder: ${folderId}`);
      
      // 首先将该文件夹下的收藏项移到根目录
      const updateResult = await this.sqliteHelper.update(
        COLLECTION_TABLE.TABLE_NAME,
        { [COLLECTION_TABLE.COLUMNS.FOLDER_ID]: null },
        [{ column: COLLECTION_TABLE.COLUMNS.FOLDER_ID, value: folderId }]
      );
      
      if (!updateResult.success) {
        Logger.error(TAG, 'Failed to update collections in folder before deletion');
        return false;
      }
      
      // 然后删除文件夹
      const conditions: QueryCondition[] = [{
        column: COLLECTION_FOLDER_TABLE.COLUMNS.ID,
        value: folderId
      }];
      
      const deleteResult = await this.sqliteHelper.delete(COLLECTION_FOLDER_TABLE.TABLE_NAME, conditions);
      
      if (deleteResult.success) {
        await this.invalidateCollectionListCache();
        Logger.info(TAG, `Collection folder deleted successfully: ${folderId}`);
      }
      
      return deleteResult.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to delete collection folder: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 获取所有收藏文件夹
   * @returns 文件夹列表
   */
  public async getAllFolders(): Promise<CollectionFolder[]> {
    try {
      const sortOptions = [{
        column: COLLECTION_FOLDER_TABLE.COLUMNS.SORT_ORDER,
        order: 'ASC'
      }, {
        column: COLLECTION_FOLDER_TABLE.COLUMNS.NAME,
        order: 'ASC'
      }];
      
      const folderRecords = await this.sqliteHelper.query(
        COLLECTION_FOLDER_TABLE.TABLE_NAME,
        ['*'],
        undefined,
        sortOptions
      );
      
      const folders: CollectionFolder[] = [];
      for (const record of folderRecords) {
        folders.push({
          id: record[COLLECTION_FOLDER_TABLE.COLUMNS.ID],
          name: record[COLLECTION_FOLDER_TABLE.COLUMNS.NAME],
          description: record[COLLECTION_FOLDER_TABLE.COLUMNS.DESCRIPTION],
          coverUrl: record[COLLECTION_FOLDER_TABLE.COLUMNS.COVER_URL],
          sortOrder: record[COLLECTION_FOLDER_TABLE.COLUMNS.SORT_ORDER],
          createTime: record[COLLECTION_FOLDER_TABLE.COLUMNS.CREATE_TIME],
          updateTime: record[COLLECTION_FOLDER_TABLE.COLUMNS.UPDATE_TIME],
          itemCount: record[COLLECTION_FOLDER_TABLE.COLUMNS.ITEM_COUNT]
        });
      }
      
      return folders;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get all folders: ${errorMsg}`);
      return [];
    }
  }
  
  /**
   * 获取文件夹中的收藏项数量
   * @param folderId 文件夹ID
   * @returns 收藏项数量
   */
  public async getFolderItemCount(folderId: string): Promise<number> {
    try {
      const conditions: QueryCondition[] = [{
        column: COLLECTION_TABLE.COLUMNS.FOLDER_ID,
        value: folderId
      }];
      
      return await this.sqliteHelper.count(COLLECTION_TABLE.TABLE_NAME, conditions);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get folder item count: ${errorMsg}`);
      return 0;
    }
  }
  
  /**
   * 构建排序选项
   * @param sortType 排序类型
   * @returns 排序选项数组
   */
  private buildSortOptions(sortType: CollectionSortType): Array<{ column: string; order: 'ASC' | 'DESC' }> {
    switch (sortType) {
      case CollectionSortType.TITLE_ASC:
        return [{ column: COLLECTION_TABLE.COLUMNS.TITLE, order: 'ASC' }];
      case CollectionSortType.TITLE_DESC:
        return [{ column: COLLECTION_TABLE.COLUMNS.TITLE, order: 'DESC' }];
      case CollectionSortType.CREATE_TIME_ASC:
        return [{ column: COLLECTION_TABLE.COLUMNS.CREATE_TIME, order: 'ASC' }];
      case CollectionSortType.CREATE_TIME_DESC:
        return [{ column: COLLECTION_TABLE.COLUMNS.CREATE_TIME, order: 'DESC' }];
      case CollectionSortType.UPDATE_TIME_ASC:
        return [{ column: COLLECTION_TABLE.COLUMNS.UPDATE_TIME, order: 'ASC' }];
      case CollectionSortType.UPDATE_TIME_DESC:
        return [{ column: COLLECTION_TABLE.COLUMNS.UPDATE_TIME, order: 'DESC' }];
      case CollectionSortType.SORT_ORDER_ASC:
        return [{ column: COLLECTION_TABLE.COLUMNS.SORT_ORDER, order: 'ASC' }];
      case CollectionSortType.SORT_ORDER_DESC:
        return [{ column: COLLECTION_TABLE.COLUMNS.SORT_ORDER, order: 'DESC' }];
      default:
        return [{ column: COLLECTION_TABLE.COLUMNS.CREATE_TIME, order: 'DESC' }];
    }
  }
  
  /**
   * 将数据库记录转换为CollectionItem对象
   * @param record 数据库记录
   * @returns CollectionItem对象
   */
  private convertToCollectionObject(record: Record<string, any>): CollectionItem {
    const tags = record[COLLECTION_TABLE.COLUMNS.TAGS] ? record[COLLECTION_TABLE.COLUMNS.TAGS].split(',') : [];
    const extraData = record[COLLECTION_TABLE.COLUMNS.EXTRA_DATA] ? JSON.parse(record[COLLECTION_TABLE.COLUMNS.EXTRA_DATA]) : {};
    
    return {
      id: record[COLLECTION_TABLE.COLUMNS.ID],
      title: record[COLLECTION_TABLE.COLUMNS.TITLE],
      subtitle: record[COLLECTION_TABLE.COLUMNS.SUBTITLE],
      coverUrl: record[COLLECTION_TABLE.COLUMNS.COVER_URL],
      itemType: record[COLLECTION_TABLE.COLUMNS.ITEM_TYPE],
      contentType: record[COLLECTION_TABLE.COLUMNS.CONTENT_TYPE],
      siteId: record[COLLECTION_TABLE.COLUMNS.SITE_ID],
      contentId: record[COLLECTION_TABLE.COLUMNS.CONTENT_ID],
      folderId: record[COLLECTION_TABLE.COLUMNS.FOLDER_ID],
      tags,
      sortOrder: record[COLLECTION_TABLE.COLUMNS.SORT_ORDER],
      visibility: record[COLLECTION_TABLE.COLUMNS.VISIBILITY],
      createTime: record[COLLECTION_TABLE.COLUMNS.CREATE_TIME],
      updateTime: record[COLLECTION_TABLE.COLUMNS.UPDATE_TIME],
      extraData
    };
  }
  
  /**
   * 将数据库记录数组转换为CollectionItem对象数组
   * @param records 数据库记录数组
   * @returns CollectionItem对象数组
   */
  private convertToCollectionObjects(records: Record<string, any>[]): CollectionItem[] {
    return records.map(record => this.convertToCollectionObject(record));
  }
  
  /**
   * 缓存收藏项
   * @param item 收藏项
   */
  private async cacheCollectionItem(item: CollectionItem): Promise<void> {
    if (!item.id) return;
    
    try {
      // 这里可以添加缓存逻辑，使用StorageUtil
      await StorageUtil.save(`${COLLECTION_CACHE_PREFIX}${item.id}`, item);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to cache collection item: ${errorMsg}`);
    }
  }
  
  /**
   * 获取缓存的收藏项
   * @param itemId 收藏项ID
   * @returns 收藏项或null
   */
  private async getCachedCollectionItem(itemId: string): Promise<CollectionItem | null> {
    try {
      // 这里可以添加获取缓存逻辑，使用StorageUtil
      return await StorageUtil.get<CollectionItem>(`${COLLECTION_CACHE_PREFIX}${itemId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get cached collection item: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 移除缓存的收藏项
   * @param itemId 收藏项ID
   */
  private async removeCachedCollectionItem(itemId: string): Promise<void> {
    try {
      // 这里可以添加移除缓存逻辑，使用StorageUtil
      await StorageUtil.remove(`${COLLECTION_CACHE_PREFIX}${itemId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to remove cached collection item: ${errorMsg}`);
    }
  }
  
  /**
   * 使收藏列表缓存失效
   */
  private async invalidateCollectionListCache(): Promise<void> {
    try {
      // 这里可以添加使列表缓存失效的逻辑，使用StorageUtil
      await StorageUtil.remove(COLLECTION_LIST_CACHE);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to invalidate collection list cache: ${errorMsg}`);
    }
  }
}