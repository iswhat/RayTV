// SiteRepository.ets - 绔欑偣鏁版嵁浠撳簱
// 璐熻矗绔欑偣鐩稿叧鏁版嵁鐨勫瓨鍌ㄣ€佽鍙栧拰绠＄悊

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { Site, SiteGroup, SiteType, LoaderType, SiteSearchConfig } from '../bean/Site';
import { SITE_TABLE, SITE_GROUP_TABLE } from '../db/TableSchema';
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';

const TAG = 'SiteRepository';
const SITE_CACHE_PREFIX = 'site_data_';
const SITE_LIST_CACHE = 'site_list_cache';

export class SiteRepository {
  private static instance: SiteRepository;
  private sqliteHelper: SQLiteHelper;
  private storageUtil: StorageUtil;
  
  private constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 鑾峰彇绔欑偣浠撳簱鍗曚緥瀹炰緥
   */
  public static getInstance(): SiteRepository {
    if (!SiteRepository.instance) {
      SiteRepository.instance = new SiteRepository();
    }
    return SiteRepository.instance;
  }
  
  /**
   * 淇濆瓨绔欑偣淇℃伅
   * @param site 绔欑偣淇℃伅
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async saveSite(site: Site): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving site: ${site.name}`);
      
      const siteData = {
        [SITE_TABLE.COLUMNS.ID]: site.id || null,
        [SITE_TABLE.COLUMNS.NAME]: site.name,
        [SITE_TABLE.COLUMNS.URL]: site.url,
        [SITE_TABLE.COLUMNS.ICON]: site.icon,
        [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.LOADER_TYPE]: site.loaderType,
        [SITE_TABLE.COLUMNS.GROUP_ID]: site.groupId || null,
        [SITE_TABLE.COLUMNS.DESCRIPTION]: site.description || '',
        [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.SORT_ORDER]: site.sortOrder || 0,
        [SITE_TABLE.COLUMNS.CREATE_TIME]: site.createTime || Date.now(),
        [SITE_TABLE.COLUMNS.UPDATE_TIME]: Date.now(),
        [SITE_TABLE.COLUMNS.CONFIG]: JSON.stringify(site.config || {}),
        [SITE_TABLE.COLUMNS.EXTRA_DATA]: JSON.stringify(site.extraData || {})
      };
      
      let result;
      if (site.id) {
        // 鏇存柊鐜版湁绔欑偣
        const conditions: QueryCondition[] = [{
          column: SITE_TABLE.COLUMNS.ID,
          value: site.id
        }];
        result = await this.sqliteHelper.update(SITE_TABLE.TABLE_NAME, siteData, conditions);
      } else {
        // 鎻掑叆鏂扮珯鐐?        result = await this.sqliteHelper.insert(SITE_TABLE.TABLE_NAME, siteData);
        if (result.success && result.lastInsertRowId) {
          site.id = result.lastInsertRowId.toString();
        }
      }
      
      if (result.success) {
        // 鏇存柊缂撳瓨
        await this.cacheSiteData(site);
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Site ${site.name} saved successfully`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to save site ${site.name}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 鎵归噺淇濆瓨绔欑偣
   * @param sites 绔欑偣鍒楄〃
   * @returns 淇濆瓨鎴愬姛鐨勭珯鐐规暟閲?   */
  public async saveSites(sites: Site[]): Promise<number> {
    if (!sites || sites.length === 0) {
      return 0;
    }
    
    let successCount = 0;
    
    try {
      for (const site of sites) {
        const success = await this.saveSite(site);
        if (success) {
          successCount++;
        }
      }
      
      await this.invalidateSiteListCache();
      Logger.info(TAG, `Batch saved ${successCount}/${sites.length} sites`);
      return successCount;
    } catch (error) {
      Logger.error(TAG, `Failed to batch save sites: ${JSON.stringify(error)}`);
      return successCount;
    }
  }
  
  /**
   * 鑾峰彇鎵€鏈夌珯鐐?   * @param includeDisabled 鏄惁鍖呭惈绂佺敤鐨勭珯鐐?   * @returns 绔欑偣鍒楄〃
   */
  public async getAllSites(includeDisabled: boolean = false): Promise<Site[]> {
    try {
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedList = await this.getCachedSiteList();
      if (cachedList && cachedList.length > 0 && includeDisabled === false) {
        Logger.debug(TAG, 'Returning sites from cache');
        return cachedList;
      }
      
      // 鏋勫缓鏌ヨ鏉′欢
      const conditions: QueryCondition[] = [];
      if (!includeDisabled) {
        conditions.push({
          column: SITE_TABLE.COLUMNS.ENABLED,
          value: 1
        });
      }
      
      // 鏋勫缓鎺掑簭閫夐」
      const sortOptions = [{
        column: SITE_TABLE.COLUMNS.SORT_ORDER,
        order: 'ASC'
      }, {
        column: SITE_TABLE.COLUMNS.NAME,
        order: 'ASC'
      }];
      
      // 鏌ヨ鏁版嵁搴?      const siteRecords = await this.sqliteHelper.query(
        SITE_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      // 杞崲涓篠ite瀵硅薄
      const sites = this.convertToSiteObjects(siteRecords);
      
      // 缂撳瓨鍚敤鐨勭珯鐐瑰垪琛?      if (!includeDisabled && sites.length > 0) {
        await this.cacheSiteList(sites);
      }
      
      Logger.info(TAG, `Retrieved ${sites.length} sites from database`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to get all sites: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 鏍规嵁ID鑾峰彇绔欑偣
   * @param siteId 绔欑偣ID
   * @returns 绔欑偣淇℃伅鎴杗ull
   */
  public async getSiteById(siteId: string): Promise<Site | null> {
    try {
      // 灏濊瘯浠庣紦瀛樿幏鍙?      const cachedSite = await this.getCachedSite(siteId);
      if (cachedSite) {
        Logger.debug(TAG, `Returning site ${siteId} from cache`);
        return cachedSite;
      }
      
      // 鏌ヨ鏁版嵁搴?      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.ID,
        value: siteId
      }];
      
      const siteRecord = await this.sqliteHelper.getFirst(
        SITE_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!siteRecord) {
        return null;
      }
      
      // 杞崲涓篠ite瀵硅薄
      const site = this.convertToSiteObject(siteRecord);
      
      // 鏇存柊缂撳瓨
      await this.cacheSiteData(site);
      
      Logger.info(TAG, `Retrieved site ${site.name} by ID ${siteId}`);
      return site;
    } catch (error) {
      Logger.error(TAG, `Failed to get site by ID ${siteId}: ${JSON.stringify(error)}`);
      return null;
    }
  }
  
  /**
   * 鏍规嵁绫诲瀷鑾峰彇绔欑偣
   * @param type 绔欑偣绫诲瀷
   * @param includeDisabled 鏄惁鍖呭惈绂佺敤鐨勭珯鐐?   * @returns 绔欑偣鍒楄〃
   */
  public async getSitesByType(type: SiteType, includeDisabled: boolean = false): Promise<Site[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.TYPE,
        value: type
      }];
      
      if (!includeDisabled) {
        conditions.push({
          column: SITE_TABLE.COLUMNS.ENABLED,
          value: 1
        });
      }
      
      const sortOptions = [{
        column: SITE_TABLE.COLUMNS.SORT_ORDER,
        order: 'ASC'
      }, {
        column: SITE_TABLE.COLUMNS.NAME,
        order: 'ASC'
      }];
      
      const siteRecords = await this.sqliteHelper.query(
        SITE_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      const sites = this.convertToSiteObjects(siteRecords);
      Logger.info(TAG, `Retrieved ${sites.length} sites of type ${type}`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to get sites by type ${type}: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 鏍规嵁鍒嗙粍鑾峰彇绔欑偣
   * @param groupId 鍒嗙粍ID
   * @param includeDisabled 鏄惁鍖呭惈绂佺敤鐨勭珯鐐?   * @returns 绔欑偣鍒楄〃
   */
  public async getSitesByGroup(groupId: string, includeDisabled: boolean = false): Promise<Site[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.GROUP_ID,
        value: groupId
      }];
      
      if (!includeDisabled) {
        conditions.push({
          column: SITE_TABLE.COLUMNS.ENABLED,
          value: 1
        });
      }
      
      const sortOptions = [{
        column: SITE_TABLE.COLUMNS.SORT_ORDER,
        order: 'ASC'
      }, {
        column: SITE_TABLE.COLUMNS.NAME,
        order: 'ASC'
      }];
      
      const siteRecords = await this.sqliteHelper.query(
        SITE_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      const sites = this.convertToSiteObjects(siteRecords);
      Logger.info(TAG, `Retrieved ${sites.length} sites from group ${groupId}`);
      return sites;
    } catch (error) {
      Logger.error(TAG, `Failed to get sites by group ${groupId}: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 鍒犻櫎绔欑偣
   * @param siteId 绔欑偣ID
   * @returns 鏄惁鍒犻櫎鎴愬姛
   */
  public async deleteSite(siteId: string): Promise<boolean> {
    try {
      Logger.debug(TAG, `Deleting site with ID: ${siteId}`);
      
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.ID,
        value: siteId
      }];
      
      const result = await this.sqliteHelper.delete(SITE_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 娓呴櫎缂撳瓨
        await this.removeCachedSite(siteId);
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Site ${siteId} deleted successfully`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to delete site ${siteId}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 鎵归噺鍒犻櫎绔欑偣
   * @param siteIds 绔欑偣ID鍒楄〃
   * @returns 鍒犻櫎鎴愬姛鐨勭珯鐐规暟閲?   */
  public async deleteSites(siteIds: string[]): Promise<number> {
    if (!siteIds || siteIds.length === 0) {
      return 0;
    }
    
    try {
      Logger.debug(TAG, `Deleting ${siteIds.length} sites`);
      
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.ID,
        operator: 'IN',
        value: siteIds
      }];
      
      const result = await this.sqliteHelper.delete(SITE_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 娓呴櫎缂撳瓨
        for (const siteId of siteIds) {
          await this.removeCachedSite(siteId);
        }
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Deleted ${result.affectedRows} sites`);
      }
      
      return result.affectedRows || 0;
    } catch (error) {
      Logger.error(TAG, `Failed to batch delete sites: ${JSON.stringify(error)}`);
      return 0;
    }
  }
  
  /**
   * 鏇存柊绔欑偣鍚敤鐘舵€?   * @param siteId 绔欑偣ID
   * @param enabled 鏄惁鍚敤
   * @returns 鏄惁鏇存柊鎴愬姛
   */
  public async updateSiteEnabled(siteId: string, enabled: boolean): Promise<boolean> {
    try {
      const data = {
        [SITE_TABLE.COLUMNS.ENABLED]: enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.UPDATE_TIME]: Date.now()
      };
      
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.ID,
        value: siteId
      }];
      
      const result = await this.sqliteHelper.update(SITE_TABLE.TABLE_NAME, data, conditions);
      
      if (result.success) {
        // 娓呴櫎缂撳瓨
        await this.removeCachedSite(siteId);
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Site ${siteId} enabled status updated to ${enabled}`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to update site ${siteId} enabled status: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 鏇存柊绔欑偣鎺掑簭
   * @param siteId 绔欑偣ID
   * @param sortOrder 鎺掑簭椤哄簭
   * @returns 鏄惁鏇存柊鎴愬姛
   */
  public async updateSiteSortOrder(siteId: string, sortOrder: number): Promise<boolean> {
    try {
      const data = {
        [SITE_TABLE.COLUMNS.SORT_ORDER]: sortOrder,
        [SITE_TABLE.COLUMNS.UPDATE_TIME]: Date.now()
      };
      
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.ID,
        value: siteId
      }];
      
      const result = await this.sqliteHelper.update(SITE_TABLE.TABLE_NAME, data, conditions);
      
      if (result.success) {
        // 娓呴櫎缂撳瓨
        await this.removeCachedSite(siteId);
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Site ${siteId} sort order updated to ${sortOrder}`);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to update site ${siteId} sort order: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 淇濆瓨绔欑偣鍒嗙粍
   * @param group 绔欑偣鍒嗙粍
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async saveSiteGroup(group: SiteGroup): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving site group: ${group.name}`);
      
      const groupData = {
        [SITE_GROUP_TABLE.COLUMNS.ID]: group.id || null,
        [SITE_GROUP_TABLE.COLUMNS.NAME]: group.name,
        [SITE_GROUP_TABLE.COLUMNS.DESCRIPTION]: group.description || '',
        [SITE_GROUP_TABLE.COLUMNS.SORT_ORDER]: group.sortOrder || 0,
        [SITE_GROUP_TABLE.COLUMNS.CREATE_TIME]: group.createTime || Date.now(),
        [SITE_GROUP_TABLE.COLUMNS.UPDATE_TIME]: Date.now()
      };
      
      let result;
      if (group.id) {
        // 鏇存柊鐜版湁鍒嗙粍
        const conditions: QueryCondition[] = [{
          column: SITE_GROUP_TABLE.COLUMNS.ID,
          value: group.id
        }];
        result = await this.sqliteHelper.update(SITE_GROUP_TABLE.TABLE_NAME, groupData, conditions);
      } else {
        // 鎻掑叆鏂板垎缁?        result = await this.sqliteHelper.insert(SITE_GROUP_TABLE.TABLE_NAME, groupData);
        if (result.success && result.lastInsertRowId) {
          group.id = result.lastInsertRowId.toString();
        }
      }
      
      Logger.info(TAG, `Site group ${group.name} saved successfully`);
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to save site group ${group.name}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 鑾峰彇鎵€鏈夌珯鐐瑰垎缁?   * @returns 绔欑偣鍒嗙粍鍒楄〃
   */
  public async getAllSiteGroups(): Promise<SiteGroup[]> {
    try {
      const sortOptions = [{
        column: SITE_GROUP_TABLE.COLUMNS.SORT_ORDER,
        order: 'ASC'
      }, {
        column: SITE_GROUP_TABLE.COLUMNS.NAME,
        order: 'ASC'
      }];
      
      const groupRecords = await this.sqliteHelper.query(
        SITE_GROUP_TABLE.TABLE_NAME,
        ['*'],
        undefined,
        sortOptions
      );
      
      const groups: SiteGroup[] = groupRecords.map(record => ({
        id: record[SITE_GROUP_TABLE.COLUMNS.ID]?.toString(),
        name: record[SITE_GROUP_TABLE.COLUMNS.NAME],
        description: record[SITE_GROUP_TABLE.COLUMNS.DESCRIPTION],
        sortOrder: record[SITE_GROUP_TABLE.COLUMNS.SORT_ORDER],
        createTime: record[SITE_GROUP_TABLE.COLUMNS.CREATE_TIME],
        updateTime: record[SITE_GROUP_TABLE.COLUMNS.UPDATE_TIME]
      }));
      
      Logger.info(TAG, `Retrieved ${groups.length} site groups`);
      return groups;
    } catch (error) {
      Logger.error(TAG, `Failed to get all site groups: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 缂撳瓨绔欑偣鏁版嵁
   */
  private async cacheSiteData(site: Site): Promise<void> {
    try {
      await this.storageUtil.setObject(`${SITE_CACHE_PREFIX}${site.id}`, site);
    } catch (error) {
      Logger.warn(TAG, `Failed to cache site ${site.id}: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 鑾峰彇缂撳瓨鐨勭珯鐐规暟鎹?   */
  private async getCachedSite(siteId: string): Promise<Site | null> {
    try {
      return await this.storageUtil.getObject<Site>(`${SITE_CACHE_PREFIX}${siteId}`);
    } catch (error) {
      return null;
    }
  }
  
  /**
   * 绉婚櫎缂撳瓨鐨勭珯鐐规暟鎹?   */
  private async removeCachedSite(siteId: string): Promise<void> {
    try {
      await this.storageUtil.remove(`${SITE_CACHE_PREFIX}${siteId}`);
    } catch (error) {
      Logger.warn(TAG, `Failed to remove cached site ${siteId}: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 缂撳瓨绔欑偣鍒楄〃
   */
  private async cacheSiteList(sites: Site[]): Promise<void> {
    try {
      await this.storageUtil.setObject(SITE_LIST_CACHE, sites);
    } catch (error) {
      Logger.warn(TAG, `Failed to cache site list: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 鑾峰彇缂撳瓨鐨勭珯鐐瑰垪琛?   */
  private async getCachedSiteList(): Promise<Site[] | null> {
    try {
      return await this.storageUtil.getObject<Site[]>(SITE_LIST_CACHE);
    } catch (error) {
      return null;
    }
  }
  
  /**
   * 浣跨珯鐐瑰垪琛ㄧ紦瀛樺け鏁?   */
  private async invalidateSiteListCache(): Promise<void> {
    try {
      await this.storageUtil.remove(SITE_LIST_CACHE);
    } catch (error) {
      Logger.warn(TAG, `Failed to invalidate site list cache: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 灏嗘暟鎹簱璁板綍杞崲涓篠ite瀵硅薄
   */
  private convertToSiteObject(record: any): Site {
    return {
      id: record[SITE_TABLE.COLUMNS.ID]?.toString(),
      name: record[SITE_TABLE.COLUMNS.NAME],
      url: record[SITE_TABLE.COLUMNS.URL],
      icon: record[SITE_TABLE.COLUMNS.ICON],
      type: record[SITE_TABLE.COLUMNS.TYPE],
      loaderType: record[SITE_TABLE.COLUMNS.LOADER_TYPE],
      groupId: record[SITE_TABLE.COLUMNS.GROUP_ID]?.toString(),
      description: record[SITE_TABLE.COLUMNS.DESCRIPTION],
      enabled: record[SITE_TABLE.COLUMNS.ENABLED] === 1,
      sortOrder: record[SITE_TABLE.COLUMNS.SORT_ORDER],
      createTime: record[SITE_TABLE.COLUMNS.CREATE_TIME],
      updateTime: record[SITE_TABLE.COLUMNS.UPDATE_TIME],
      config: record[SITE_TABLE.COLUMNS.CONFIG] ? JSON.parse(record[SITE_TABLE.COLUMNS.CONFIG]) : {},
      extraData: record[SITE_TABLE.COLUMNS.EXTRA_DATA] ? JSON.parse(record[SITE_TABLE.COLUMNS.EXTRA_DATA]) : {}
    };
  }
  
  /**
   * 灏嗘暟鎹簱璁板綍鍒楄〃杞崲涓篠ite瀵硅薄鍒楄〃
   */
  private convertToSiteObjects(records: any[]): Site[] {
    return records.map(record => this.convertToSiteObject(record));
  }
}


