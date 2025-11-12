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
  extraData?: Record<string, string | number | boolean | null>;
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
   * 添加收藏
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
      
      const result = await this.sqliteHelper.insert(COLLECTION_TABLE.TABLE_NAME, collectionData);
      
      if (result.success && result.lastInsertRowId) {
        item.id = result.lastInsertRowId.toString();
        
        // 更新缓存
        await this.cacheCollectionItem(item);
        await this.invalidateCollectionListCache();
        
        Logger.info(TAG, `Collection added successfully: ${item.title}`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to add collection: ${JSON.stringify(error)}`);
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
      
      const result = await this.sqliteHelper.update(COLLECTION_TABLE.TABLE_NAME, collectionData, conditions);
      
      if (result.success) {
        // 更新缓存
        await this.cacheCollectionItem(item);
        await this.invalidateCollectionListCache();
        
        Logger.info(TAG, `Collection updated successfully: ${item.id}`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to update collection: ${JSON.stringify(error)}`);
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
      
      const result = await this.sqliteHelper.delete(COLLECTION_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 清除缓存
        await this.removeCachedCollectionItem(collectionId);
        await this.invalidateCollectionListCache();
        
        Logger.info(TAG, `Collection removed successfully: ${collectionId}`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to remove collection: ${JSON.stringify(error)}`);
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
      
      const result = await this.sqliteHelper.delete(COLLECTION_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 清除缓存
        for (const id of collectionIds) {
          await this.removeCachedCollectionItem(id);
        }
        await this.invalidateCollectionListCache();
        
        Logger.info(TAG, `Batch removed ${result.affectedRows} collections`);
      }
      
      return result.affectedRows || 0;
    } catch (error) {
      Logger.error(TAG, `Failed to batch remove collections: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to get all collections: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to get collection by ID: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to check if content is collected: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to get collection by content: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to get collections by folder: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to get collections by tag: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to get collections by content type: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to get collection count: ${JSON.stringify(error)}`);
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
      
      const folderData = {
        [COLLECTION_FOLDER_TABLE.COLUMNS.NAME]: folder.name,
        [COLLECTION_FOLDER_TABLE.COLUMNS.DESCRIPTION]: folder.description || '',
        [COLLECTION_FOLDER_TABLE.COLUMNS.COVER_URL]: folder.coverUrl || '',
        [COLLECTION_FOLDER_TABLE.COLUMNS.SORT_ORDER]: folder.sortOrder || 0,
        [COLLECTION_FOLDER_TABLE.COLUMNS.CREATE_TIME]: Date.now(),
        [COLLECTION_FOLDER_TABLE.COLUMNS.UPDATE_TIME]: Date.now()
      };
      
      const result = await this.sqliteHelper.insert(COLLECTION_FOLDER_TABLE.TABLE_NAME, folderData);
      
      if (result.success && result.lastInsertRowId) {
        folder.id = result.lastInsertRowId.toString();
        Logger.info(TAG, `Collection folder created successfully: ${folder.name}`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to create collection folder: ${JSON.stringify(error)}`);
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
      
      const folderData = {
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
      
      const result = await this.sqliteHelper.update(COLLECTION_FOLDER_TABLE.TABLE_NAME, folderData, conditions);
      
      if (result.success) {
        Logger.info(TAG, `Collection folder updated successfully: ${folder.id}`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to update collection folder: ${JSON.stringify(error)}`);
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
      Logger.error(TAG, `Failed to delete collection folder: ${JSON.stringify(error)}`);
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
      
      // 获取每个文件夹的项目数量
      const folders: CollectionFolder[] = [];
      for (const record of folderRecords) {
        const folderId = record[COLLECTION_FOLDER_TABLE.COLUMNS.ID].toString();
        const itemCount = await this.getCollectionCountByFolder(folderId);
        
        folders.push({
          id: folderId,
          name: record[COLLECTION_FOLDER_TABLE.COLUMNS.NAME],
          description: record[COLLECTION_FOLDER_TABLE.COLUMNS.DESCRIPTION],
          coverUrl: record[COLLECTION_FOLDER_TABLE.COLUMNS.COVER_URL],
          sortOrder: record[COLLECTION_FOLDER_TABLE.COLUMNS.SORT_ORDER],
          createTime: record[COLLECTION_FOLDER_TABLE.COLUMNS.CREATE_TIME],
          updateTime: record[COLLECTION_FOLDER_TABLE.COLUMNS.UPDATE_TIME],
          itemCount
        });
      }
      
      Logger.info(TAG, `Retrieved ${folders.length} collection folders`);
      return folders;
    } catch (error) {
      Logger.error(TAG, `Failed to get all folders: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 获取文件夹中的收藏项数量
   * @param folderId 文件夹ID
   * @returns 收藏项数量
   */
  private async getCollectionCountByFolder(folderId: string): Promise<number> {
    const conditions: QueryCondition[] = [{
      column: COLLECTION_TABLE.COLUMNS.FOLDER_ID,
      value: folderId
    }];
    
    return await this.sqliteHelper.count(COLLECTION_TABLE.TABLE_NAME, conditions);
  }
  
  /**
   * 构建排序选项
   */
  private buildSortOptions(sortType: CollectionSortType): {column: string, order: string}[] {
    const sortOptions: {column: string, order: string}[] = [];
    
    switch (sortType) {
      case CollectionSortType.TITLE_ASC:
        sortOptions.push({ column: COLLECTION_TABLE.COLUMNS.TITLE, order: 'ASC' });
        break;
      case CollectionSortType.TITLE_DESC:
        sortOptions.push({ column: COLLECTION_TABLE.COLUMNS.TITLE, order: 'DESC' });
        break;
      case CollectionSortType.CREATE_TIME_ASC:
        sortOptions.push({ column: COLLECTION_TABLE.COLUMNS.CREATE_TIME, order: 'ASC' });
        break;
      case CollectionSortType.CREATE_TIME_DESC:
      default:
        sortOptions.push({ column: COLLECTION_TABLE.COLUMNS.CREATE_TIME, order: 'DESC' });
        break;
      case CollectionSortType.UPDATE_TIME_ASC:
        sortOptions.push({ column: COLLECTION_TABLE.COLUMNS.UPDATE_TIME, order: 'ASC' });
        break;
      case CollectionSortType.UPDATE_TIME_DESC:
        sortOptions.push({ column: COLLECTION_TABLE.COLUMNS.UPDATE_TIME, order: 'DESC' });
        break;
      case CollectionSortType.CUSTOM:
        sortOptions.push({ column: COLLECTION_TABLE.COLUMNS.SORT_ORDER, order: 'ASC' });
        sortOptions.push({ column: COLLECTION_TABLE.COLUMNS.TITLE, order: 'ASC' });
        break;
    }
    
    return sortOptions;
  }
  
  /**
   * 缓存收藏项
   */
  private async cacheCollectionItem(item: CollectionItem): Promise<void> {
    try {
      if (item.id) {
        await this.storageUtil.setObject(`${COLLECTION_CACHE_PREFIX}${item.id}`, item);
      }
    } catch (error) {
      Logger.warn(TAG, `Failed to cache collection item: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 获取缓存的收藏项
   */
  private async getCachedCollectionItem(collectionId: string): Promise<CollectionItem | null> {
    try {
      return await this.storageUtil.getObject<CollectionItem>(`${COLLECTION_CACHE_PREFIX}${collectionId}`);
    } catch (error) {
      return null;
    }
  }
  
  /**
   * 移除缓存的收藏项
   */
  private async removeCachedCollectionItem(collectionId: string): Promise<void> {
    try {
      await this.storageUtil.remove(`${COLLECTION_CACHE_PREFIX}${collectionId}`);
    } catch (error) {
      Logger.warn(TAG, `Failed to remove cached collection item: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 使收藏列表缓存失效
   */
  private async invalidateCollectionListCache(): Promise<void> {
    try {
      await this.storageUtil.remove(COLLECTION_LIST_CACHE);
    } catch (error) {
      Logger.warn(TAG, `Failed to invalidate collection list cache: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 将数据库记录转换为CollectionItem对象
   */
  private convertToCollectionObject(record: Record<string, string | number | boolean | null>): CollectionItem {
    return {
      id: record[COLLECTION_TABLE.COLUMNS.ID]?.toString(),
      title: record[COLLECTION_TABLE.COLUMNS.TITLE],
      subtitle: record[COLLECTION_TABLE.COLUMNS.SUBTITLE],
      coverUrl: record[COLLECTION_TABLE.COLUMNS.COVER_URL],
      itemType: record[COLLECTION_TABLE.COLUMNS.ITEM_TYPE],
      contentType: record[COLLECTION_TABLE.COLUMNS.CONTENT_TYPE],
      siteId: record[COLLECTION_TABLE.COLUMNS.SITE_ID],
      contentId: record[COLLECTION_TABLE.COLUMNS.CONTENT_ID],
      folderId: record[COLLECTION_TABLE.COLUMNS.FOLDER_ID]?.toString(),
      tags: record[COLLECTION_TABLE.COLUMNS.TAGS] ? record[COLLECTION_TABLE.COLUMNS.TAGS].split(',') : [],
      sortOrder: record[COLLECTION_TABLE.COLUMNS.SORT_ORDER],
      visibility: record[COLLECTION_TABLE.COLUMNS.VISIBILITY],
      createTime: record[COLLECTION_TABLE.COLUMNS.CREATE_TIME],
      updateTime: record[COLLECTION_TABLE.COLUMNS.UPDATE_TIME],
      extraData: record[COLLECTION_TABLE.COLUMNS.EXTRA_DATA] ? JSON.parse(record[COLLECTION_TABLE.COLUMNS.EXTRA_DATA]) : {}
    };
  }
  
  /**
   * 将数据库记录列表转换为CollectionItem对象列表
   */
  private convertToCollectionObjects(records: Record<string, string | number | boolean | null>[]): CollectionItem[] {
    return records.map(record => this.convertToCollectionObject(record));
  }
}