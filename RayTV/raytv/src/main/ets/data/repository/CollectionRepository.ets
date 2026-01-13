// CollectionRepository.ets - 鏀惰棌鏁版嵁浠撳簱
// 璐熻矗鏀惰棌鍐呭鐩稿叧鏁版嵁鐨勫瓨鍌ㄣ€佽鍙栧拰绠＄悊

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { COLLECTION_TABLE, COLLECTION_FOLDER_TABLE } from '../db/TableSchema';
import { CollectionItemType, CollectionVisibility, CollectionSortType } from '../model/LocalModel';
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import { Serializable } from '../../types/commonTypes';

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
  extraData?: Record<string, Serializable>;
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
   * 鑾峰彇鏀惰棌浠撳簱鍗曚緥瀹炰緥
   */
  public static getInstance(): CollectionRepository {
    if (!CollectionRepository.instance) {
      CollectionRepository.instance = new CollectionRepository();
    }
    return CollectionRepository.instance;
  }
  
  /**
   * 娣诲姞鏀惰棌椤?   * @param item 鏀惰棌椤?   * @returns 鏄惁娣诲姞鎴愬姛
   */
  public async addCollection(item: CollectionItem): Promise<boolean> {
    try {
      Logger.debug(TAG, `Adding collection: ${item.title}`);
      
      // 妫€鏌ユ槸鍚﹀凡瀛樺湪鐩稿悓鍐呭鐨勬敹钘?      if (await this.isContentCollected(item.contentType, item.contentId)) {
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
        
        // 鏇存柊缂撳瓨
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
   * 鏇存柊鏀惰棌椤?   * @param item 鏀惰棌椤?   * @returns 鏄惁鏇存柊鎴愬姛
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
        // 鏇存柊缂撳瓨
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
   * 鍒犻櫎鏀惰棌椤?   * @param collectionId 鏀惰棌椤笽D
   * @returns 鏄惁鍒犻櫎鎴愬姛
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
        // 娓呴櫎缂撳瓨
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
   * 鎵归噺鍒犻櫎鏀惰棌椤?   * @param collectionIds 鏀惰棌椤笽D鍒楄〃
   * @returns 鍒犻櫎鎴愬姛鐨勬暟閲?   */
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
        // 娓呴櫎缂撳瓨
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
   * 鑾峰彇鎵€鏈夋敹钘忛」
   * @param sortType 鎺掑簭绫诲瀷
   * @param limit 闄愬埗鏁伴噺
   * @param offset 鍋忕Щ閲?   * @returns 鏀惰棌椤瑰垪琛?   */
  public async getAllCollections(
    sortType: CollectionSortType = CollectionSortType.CREATE_TIME_DESC,
    limit: number = 50,
    offset: number = 0
  ): Promise<CollectionItem[]> {
    try {
      // 鏋勫缓鎺掑簭閫夐」
      const sortOptions = this.buildSortOptions(sortType);
      
      // 鏌ヨ鏁版嵁搴?      const collectionRecords = await this.sqliteHelper.query(
        COLLECTION_TABLE.TABLE_NAME,
        ['*'],
        undefined,
        sortOptions,
        limit,
        offset
      );
      
      // 杞崲涓篊ollectionItem瀵硅薄
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
   * 鏍规嵁ID鑾峰彇鏀惰棌椤?   * @param collectionId 鏀惰棌椤笽D
   * @returns 鏀惰棌椤规垨null
   */
  public async getCollectionById(collectionId: string): Promise<CollectionItem | null> {
    try {
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedItem = await this.getCachedCollectionItem(collectionId);
      if (cachedItem) {
        Logger.debug(TAG, `Returning collection ${collectionId} from cache`);
        return cachedItem;
      }
      
      // 鏌ヨ鏁版嵁搴?      const conditions: QueryCondition[] = [{
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
      
      // 杞崲涓篊ollectionItem瀵硅薄
      const collection = this.convertToCollectionObject(collectionRecord);
      
      // 鏇存柊缂撳瓨
      await this.cacheCollectionItem(collection);
      
      return collection;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get collection by ID: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 鏍规嵁鍐呭ID妫€鏌ユ槸鍚﹀凡鏀惰棌
   * @param contentType 鍐呭绫诲瀷
   * @param contentId 鍐呭ID
   * @returns 鏄惁宸叉敹钘?   */
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
   * 鏍规嵁鍐呭ID鑾峰彇鏀惰棌椤?   * @param contentType 鍐呭绫诲瀷
   * @param contentId 鍐呭ID
   * @returns 鏀惰棌椤规垨null
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
   * 鎸夋枃浠跺す鑾峰彇鏀惰棌椤?   * @param folderId 鏂囦欢澶笽D
   * @param sortType 鎺掑簭绫诲瀷
   * @returns 鏀惰棌椤瑰垪琛?   */
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
   * 鎸夋爣绛捐幏鍙栨敹钘忛」
   * @param tag 鏍囩
   * @param sortType 鎺掑簭绫诲瀷
   * @returns 鏀惰棌椤瑰垪琛?   */
  public async getCollectionsByTag(
    tag: string, 
    sortType: CollectionSortType = CollectionSortType.CREATE_TIME_DESC
  ): Promise<CollectionItem[]> {
    try {
      // 浣跨敤LIKE鏌ヨ鍖呭惈鎸囧畾鏍囩鐨勬敹钘忛」
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
      
      // 杩囨护鍑虹‘瀹炲寘鍚寚瀹氭爣绛剧殑椤癸紙閬垮厤LIKE鍖归厤涓嶅噯纭級
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
   * 鎸夌被鍨嬭幏鍙栨敹钘忛」
   * @param contentType 鍐呭绫诲瀷
   * @param sortType 鎺掑簭绫诲瀷
   * @returns 鏀惰棌椤瑰垪琛?   */
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
   * 鑾峰彇鏀惰棌椤规€绘暟
   * @returns 鏀惰棌椤规€绘暟
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
   * 鍒涘缓鏀惰棌鏂囦欢澶?   * @param folder 鏂囦欢澶逛俊鎭?   * @returns 鏄惁鍒涘缓鎴愬姛
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
   * 鏇存柊鏀惰棌鏂囦欢澶?   * @param folder 鏂囦欢澶逛俊鎭?   * @returns 鏄惁鏇存柊鎴愬姛
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
   * 鍒犻櫎鏀惰棌鏂囦欢澶?   * @param folderId 鏂囦欢澶笽D
   * @returns 鏄惁鍒犻櫎鎴愬姛
   */
  public async deleteFolder(folderId: string): Promise<boolean> {
    try {
      Logger.debug(TAG, `Deleting collection folder: ${folderId}`);
      
      // 棣栧厛灏嗚鏂囦欢澶逛笅鐨勬敹钘忛」绉诲埌鏍圭洰褰?      const updateResult = await this.sqliteHelper.update(
        COLLECTION_TABLE.TABLE_NAME,
        { [COLLECTION_TABLE.COLUMNS.FOLDER_ID]: null },
        [{ column: COLLECTION_TABLE.COLUMNS.FOLDER_ID, value: folderId }]
      );
      
      if (!updateResult.success) {
        Logger.error(TAG, 'Failed to update collections in folder before deletion');
        return false;
      }
      
      // 鐒跺悗鍒犻櫎鏂囦欢澶?      const conditions: QueryCondition[] = [{
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
   * 鑾峰彇鎵€鏈夋敹钘忔枃浠跺す
   * @returns 鏂囦欢澶瑰垪琛?   */
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
   * 鑾峰彇鏂囦欢澶逛腑鐨勬敹钘忛」鏁伴噺
   * @param folderId 鏂囦欢澶笽D
   * @returns 鏀惰棌椤规暟閲?   */
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
   * 鏋勫缓鎺掑簭閫夐」
   * @param sortType 鎺掑簭绫诲瀷
   * @returns 鎺掑簭閫夐」鏁扮粍
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
   * 灏嗘暟鎹簱璁板綍杞崲涓篊ollectionItem瀵硅薄
   * @param record 鏁版嵁搴撹褰?   * @returns CollectionItem瀵硅薄
   */
  private convertToCollectionObject(record: Record<string, Serializable>): CollectionItem {
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
   * 灏嗘暟鎹簱璁板綍鏁扮粍杞崲涓篊ollectionItem瀵硅薄鏁扮粍
   * @param records 鏁版嵁搴撹褰曟暟缁?   * @returns CollectionItem瀵硅薄鏁扮粍
   */
  private convertToCollectionObjects(records: Record<string, Serializable>[]): CollectionItem[] {
    return records.map(record => this.convertToCollectionObject(record));
  }
  
  /**
   * 缂撳瓨鏀惰棌椤?   * @param item 鏀惰棌椤?   */
  private async cacheCollectionItem(item: CollectionItem): Promise<void> {
    if (!item.id) return;
    
    try {
      // 杩欓噷鍙互娣诲姞缂撳瓨閫昏緫锛屼娇鐢⊿torageUtil
      await StorageUtil.save(`${COLLECTION_CACHE_PREFIX}${item.id}`, item);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to cache collection item: ${errorMsg}`);
    }
  }
  
  /**
   * 鑾峰彇缂撳瓨鐨勬敹钘忛」
   * @param itemId 鏀惰棌椤笽D
   * @returns 鏀惰棌椤规垨null
   */
  private async getCachedCollectionItem(itemId: string): Promise<CollectionItem | null> {
    try {
      // 杩欓噷鍙互娣诲姞鑾峰彇缂撳瓨閫昏緫锛屼娇鐢⊿torageUtil
      return await StorageUtil.get<CollectionItem>(`${COLLECTION_CACHE_PREFIX}${itemId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get cached collection item: ${errorMsg}`);
      return null;
    }
  }
  
  /**
   * 绉婚櫎缂撳瓨鐨勬敹钘忛」
   * @param itemId 鏀惰棌椤笽D
   */
  private async removeCachedCollectionItem(itemId: string): Promise<void> {
    try {
      // 杩欓噷鍙互娣诲姞绉婚櫎缂撳瓨閫昏緫锛屼娇鐢⊿torageUtil
      await StorageUtil.remove(`${COLLECTION_CACHE_PREFIX}${itemId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to remove cached collection item: ${errorMsg}`);
    }
  }
  
  /**
   * 浣挎敹钘忓垪琛ㄧ紦瀛樺け鏁?   */
  private async invalidateCollectionListCache(): Promise<void> {
    try {
      // 杩欓噷鍙互娣诲姞浣垮垪琛ㄧ紦瀛樺け鏁堢殑閫昏緫锛屼娇鐢⊿torageUtil
      await StorageUtil.remove(COLLECTION_LIST_CACHE);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to invalidate collection list cache: ${errorMsg}`);
    }
  }
}


