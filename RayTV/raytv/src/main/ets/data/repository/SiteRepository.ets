/**
 * SiteRepository.ets - 站点数据仓库
 * 负责站点相关数据的存储、获取和管理
 */

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { Site, SiteGroup, SiteType, LoaderType, SiteSearchConfig } from '../bean/Site';
import { SITE_TABLE, SITE_GROUP_TABLE } from '../db/TableSchema';
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import { DatabaseError, SiteError, handleError } from '../../common/util/AppError';

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
   * 获取站点仓库单例实例 | Get site repository singleton instance
   */
  public static getInstance(): SiteRepository {
    if (!SiteRepository.instance) {
      SiteRepository.instance = new SiteRepository();
    }
    return SiteRepository.instance;
  }
  
  /**
   * 保存站点信息 | Save site information
   * @param site 站点信息 | Site information
   * @returns 是否保存成功 | Whether saved successfully
   */
  public async saveSite(site: Site): Promise<boolean> {
    try {
      Logger.debug(TAG, `Saving site: ${site.name}`);
      
      const siteData = {
        [SITE_TABLE.COLUMNS.KEY]: site.key || null,
        [SITE_TABLE.COLUMNS.NAME]: site.name,
        [SITE_TABLE.COLUMNS.TYPE]: site.type,
        [SITE_TABLE.COLUMNS.LOADER_TYPE]: site.loaderType,
        [SITE_TABLE.COLUMNS.API]: site.api,
        [SITE_TABLE.COLUMNS.LOGO]: site.logo,
        [SITE_TABLE.COLUMNS.DESCRIPTION]: site.description || '',
        [SITE_TABLE.COLUMNS.SITE_AUTH]: site.siteAuth ? JSON.stringify(site.siteAuth) : null,
        [SITE_TABLE.COLUMNS.HEADERS]: site.headers ? JSON.stringify(site.headers) : null,
        [SITE_TABLE.COLUMNS.CONFIG]: site.config ? JSON.stringify(site.config) : '{}',
        [SITE_TABLE.COLUMNS.CONFIG_ITEMS]: site.configItems ? JSON.stringify(site.configItems) : null,
        [SITE_TABLE.COLUMNS.SEARCH_CONFIG]: JSON.stringify(site.searchConfig),
        [SITE_TABLE.COLUMNS.FILTER_CONFIG]: JSON.stringify(site.filterConfig),
        [SITE_TABLE.COLUMNS.PERFORMANCE_CONFIG]: JSON.stringify(site.performanceConfig),
        [SITE_TABLE.COLUMNS.VERSION]: site.version ? JSON.stringify(site.version) : null,
        [SITE_TABLE.COLUMNS.STATS]: JSON.stringify(site.stats),
        [SITE_TABLE.COLUMNS.LIFECYCLE]: JSON.stringify(site.lifecycle),
        [SITE_TABLE.COLUMNS.ENABLED]: site.enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.ORDER]: site.order || 0,
        [SITE_TABLE.COLUMNS.GROUP]: site.group || null,
        [SITE_TABLE.COLUMNS.TAGS]: site.tags ? JSON.stringify(site.tags) : null,
        [SITE_TABLE.COLUMNS.CUSTOM_CODE]: site.customCode || null,
        [SITE_TABLE.COLUMNS.SANDBOX_ENABLED]: site.sandboxEnabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.ALLOW_THIRD_PARTY]: site.allowThirdParty ? 1 : 0,
        [SITE_TABLE.COLUMNS.CREATED_AT]: site.createdAt || Date.now(),
        [SITE_TABLE.COLUMNS.UPDATED_AT]: Date.now(),
        [SITE_TABLE.COLUMNS.LAST_USED_AT]: site.lastUsedAt || null,
        [SITE_TABLE.COLUMNS.USER_AGENT]: site.userAgent || null,
        [SITE_TABLE.COLUMNS.REFERER]: site.referer || null,
        [SITE_TABLE.COLUMNS.PROXY]: site.proxy || null,
        [SITE_TABLE.COLUMNS.ENCODING]: site.encoding || null,
        [SITE_TABLE.COLUMNS.CHARSET]: site.charset || null,
        [SITE_TABLE.COLUMNS.CERTIFICATE]: site.certificate || null
      };
      
      let result = { success: false, lastInsertRowId: null };
      if (site.key) {
        // 更新现有站点 | Update existing site
        const conditions: QueryCondition[] = [{
          column: SITE_TABLE.COLUMNS.KEY,
          value: site.key
        }];
        result = await this.sqliteHelper.update(SITE_TABLE.TABLE_NAME, siteData, conditions);
      } else {
        // 插入新站点 | Insert new site
        result = await this.sqliteHelper.insert(SITE_TABLE.TABLE_NAME, siteData);
        if (result.success && result.lastInsertRowId) {
          site.key = result.lastInsertRowId.toString();
        }
      }
      
      if (result.success) {
        // 更新缓存 | Update cache
        await this.cacheSiteData(site);
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Site ${site.name} saved successfully`);
      }
      
      return result.success;
    } catch (error) {
      const appError = handleError(error, `Failed to save site ${site.name}`);
      Logger.error(TAG, appError.toString());
      return false;
    }
  }
  
  /**
   * 批量保存站点 | Batch save sites
   * @param sites 站点列表 | Site list
   * @returns 保存成功的站点数量 | Number of successfully saved sites
   */
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
      const appError = handleError(error, 'Failed to batch save sites');
      Logger.error(TAG, appError.toString());
      return successCount;
    }
  }
  
  /**
   * 获取所有站点 | Get all sites
   * @param includeDisabled 是否包含禁用的站点 | Whether to include disabled sites
   * @returns 站点列表 | Site list
   */
  public async getAllSites(includeDisabled: boolean = false): Promise<Site[]> {
    try {
      // 尝试从缓存获取 | Try to get from cache
      const cachedList = await this.getCachedSiteList();
      if (cachedList && cachedList.length > 0 && includeDisabled === false) {
        Logger.debug(TAG, 'Returning sites from cache');
        return cachedList;
      }
      
      // 构建查询条件 | Build query conditions
      const conditions: QueryCondition[] = [];
      if (!includeDisabled) {
        conditions.push({
          column: SITE_TABLE.COLUMNS.ENABLED,
          value: 1
        });
      }
      
      // 构建排序选项 | Build sort options
      const sortOptions = [{
        column: SITE_TABLE.COLUMNS.ORDER,
        order: 'ASC'
      }, {
        column: SITE_TABLE.COLUMNS.NAME,
        order: 'ASC'
      }];
      
      // 查询数据库 | Query database
      const siteRecords = await this.sqliteHelper.query(
        SITE_TABLE.TABLE_NAME,
        ['*'],
        conditions,
        sortOptions
      );
      
      // 转换为Site对象 | Convert to Site objects
      const sites = this.convertToSiteObjects(siteRecords);
      
      // 缓存启用的站点列表 | Cache enabled site list
      if (!includeDisabled && sites.length > 0) {
        await this.cacheSiteList(sites);
      }
      
      Logger.info(TAG, `Retrieved ${sites.length} sites from database`);
      return sites;
    } catch (error) {
      const appError = handleError(error, 'Failed to get all sites');
      Logger.error(TAG, appError.toString());
      return [];
    }
  }
  
  /**
   * 根据key获取站点 | Get site by key
   * @param siteKey 站点key | Site key
   * @returns 站点信息或null | Site information or null
   */
  public async getSiteByKey(siteKey: string): Promise<Site | null> {
    try {
      // 尝试从缓存获取 | Try to get from cache
      const cachedSite = await this.getCachedSite(siteKey);
      if (cachedSite) {
        Logger.debug(TAG, `Returning site ${siteKey} from cache`);
        return cachedSite;
      }
      
      // 查询数据库 | Query database
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.KEY,
        value: siteKey
      }];
      
      const siteRecord = await this.sqliteHelper.getFirst(
        SITE_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!siteRecord) {
        return null;
      }
      
      // 转换为Site对象 | Convert to Site object
      const site = this.convertToSiteObject(siteRecord);
      
      // 更新缓存 | Update cache
      await this.cacheSiteData(site);
      
      Logger.info(TAG, `Retrieved site ${site.name} by key ${siteKey}`);
      return site;
    } catch (error) {
      const appError = handleError(error, `Failed to get site by key ${siteKey}`);
      Logger.error(TAG, appError.toString());
      return null;
    }
  }
  
  /**
   * 根据类型获取站点 | Get sites by type
   * @param type 站点类型 | Site type
   * @param includeDisabled 是否包含禁用的站点 | Whether to include disabled sites
   * @returns 站点列表 | Site list
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
        column: SITE_TABLE.COLUMNS.ORDER,
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
      const appError = handleError(error, `Failed to get sites by type ${type}`);
      Logger.error(TAG, appError.toString());
      return [];
    }
  }
  
  /**
   * 根据分组获取站点 | Get sites by group
   * @param groupId 分组ID | Group ID
   * @param includeDisabled 是否包含禁用的站点 | Whether to include disabled sites
   * @returns 站点列表 | Site list
   */
  public async getSitesByGroup(groupId: string, includeDisabled: boolean = false): Promise<Site[]> {
    try {
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.GROUP,
        value: groupId
      }];
      
      if (!includeDisabled) {
        conditions.push({
          column: SITE_TABLE.COLUMNS.ENABLED,
          value: 1
        });
      }
      
      const sortOptions = [{
        column: SITE_TABLE.COLUMNS.ORDER,
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
      const appError = handleError(error, `Failed to get sites by group ${groupId}`);
      Logger.error(TAG, appError.toString());
      return [];
    }
  }
  
  /**
   * 删除站点 | Delete site
   * @param siteKey 站点key | Site key
   * @returns 是否删除成功 | Whether deleted successfully
   */
  public async deleteSite(siteKey: string): Promise<boolean> {
    try {
      Logger.debug(TAG, `Deleting site with key: ${siteKey}`);
      
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.KEY,
        value: siteKey
      }];
      
      const result = await this.sqliteHelper.delete(SITE_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 清除缓存 | Clear cache
        await this.removeCachedSite(siteKey);
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Site ${siteKey} deleted successfully`);
      }
      
      return result.success;
    } catch (error) {
      const appError = handleError(error, `Failed to delete site ${siteKey}`);
      Logger.error(TAG, appError.toString());
      return false;
    }
  }
  
  /**
   * 批量删除站点 | Batch delete sites
   * @param siteKeys 站点key列表 | Site key list
   * @returns 删除成功的站点数量 | Number of successfully deleted sites
   */
  public async deleteSites(siteKeys: string[]): Promise<number> {
    if (!siteKeys || siteKeys.length === 0) {
      return 0;
    }
    
    try {
      Logger.debug(TAG, `Deleting ${siteKeys.length} sites`);
      
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.KEY,
        operator: 'IN',
        value: siteKeys
      }];
      
      const result = await this.sqliteHelper.delete(SITE_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        // 清除缓存 | Clear cache
        for (const siteKey of siteKeys) {
          await this.removeCachedSite(siteKey);
        }
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Deleted ${result.affectedRows} sites`);
      }
      
      return result.affectedRows || 0;
    } catch (error) {
      const appError = handleError(error, 'Failed to batch delete sites');
      Logger.error(TAG, appError.toString());
      return 0;
    }
  }
  
  /**
   * 更新站点启用状态 | Update site enabled status
   * @param siteKey 站点key | Site key
   * @param enabled 是否启用 | Whether enabled
   * @returns 是否更新成功 | Whether updated successfully
   */
  public async updateSiteEnabled(siteKey: string, enabled: boolean): Promise<boolean> {
    try {
      const data = {
        [SITE_TABLE.COLUMNS.ENABLED]: enabled ? 1 : 0,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: Date.now()
      };
      
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.KEY,
        value: siteKey
      }];
      
      const result = await this.sqliteHelper.update(SITE_TABLE.TABLE_NAME, data, conditions);
      
      if (result.success) {
        // 清除缓存 | Clear cache
        await this.removeCachedSite(siteKey);
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Site ${siteKey} enabled status updated to ${enabled}`);
      }
      
      return result.success;
    } catch (error) {
      const appError = handleError(error, `Failed to update site ${siteKey} enabled status`);
      Logger.error(TAG, appError.toString());
      return false;
    }
  }
  
  /**
   * 更新站点排序 | Update site sort order
   * @param siteKey 站点key | Site key
   * @param sortOrder 排序顺序 | Sort order
   * @returns 是否更新成功 | Whether updated successfully
   */
  public async updateSiteSortOrder(siteKey: string, sortOrder: number): Promise<boolean> {
    try {
      const data = {
        [SITE_TABLE.COLUMNS.ORDER]: sortOrder,
        [SITE_TABLE.COLUMNS.UPDATED_AT]: Date.now()
      };
      
      const conditions: QueryCondition[] = [{
        column: SITE_TABLE.COLUMNS.KEY,
        value: siteKey
      }];
      
      const result = await this.sqliteHelper.update(SITE_TABLE.TABLE_NAME, data, conditions);
      
      if (result.success) {
        // 清除缓存 | Clear cache
        await this.removeCachedSite(siteKey);
        await this.invalidateSiteListCache();
        Logger.info(TAG, `Site ${siteKey} sort order updated to ${sortOrder}`);
      }
      
      return result.success;
    } catch (error) {
      const appError = handleError(error, `Failed to update site ${siteKey} sort order`);
      Logger.error(TAG, appError.toString());
      return false;
    }
  }
  
  /**
   * 保存站点分组 | Save site group
   * @param group 站点分组 | Site group
   * @returns 是否保存成功 | Whether saved successfully
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
      
      let result: boolean | { success: boolean; lastInsertRowId?: number };
      if (group.id) {
        // 更新现有分组 | Update existing group
        const conditions: QueryCondition[] = [{
          column: SITE_GROUP_TABLE.COLUMNS.ID,
          value: group.id
        }];
        result = await this.sqliteHelper.update(SITE_GROUP_TABLE.TABLE_NAME, groupData, conditions);
      } else {
        // 插入新分组 | Insert new group
        result = await this.sqliteHelper.insert(SITE_GROUP_TABLE.TABLE_NAME, groupData);
        if (result.success && result.lastInsertRowId) {
          group.id = result.lastInsertRowId.toString();
        }
      }
      
      Logger.info(TAG, `Site group ${group.name} saved successfully`);
      return result.success;
    } catch (error) {
      const appError = handleError(error, `Failed to save site group ${group.name}`);
      Logger.error(TAG, appError.toString());
      return false;
    }
  }
  
  /**
   * 获取所有站点分组 | Get all site groups
   * @returns 站点分组列表 | Site group list
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
      const appError = handleError(error, 'Failed to get all site groups');
      Logger.error(TAG, appError.toString());
      return [];
    }
  }
  
  /**
   * 缓存站点数据 | Cache site data
   */
  private async cacheSiteData(site: Site): Promise<void> {
    try {
      await this.storageUtil.setObject(`${SITE_CACHE_PREFIX}${site.key}`, site);
    } catch (error) {
      Logger.warn(TAG, `Failed to cache site ${site.key}: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 获取缓存的站点数据 | Get cached site data
   */
  private async getCachedSite(siteKey: string): Promise<Site | null> {
    try {
      return await this.storageUtil.getObject<Site>(`${SITE_CACHE_PREFIX}${siteKey}`);
    } catch (error) {
      return null;
    }
  }
  
  /**
   * 移除缓存的站点数据 | Remove cached site data
   */
  private async removeCachedSite(siteKey: string): Promise<void> {
    try {
      await this.storageUtil.remove(`${SITE_CACHE_PREFIX}${siteKey}`);
    } catch (error) {
      Logger.warn(TAG, `Failed to remove cached site ${siteKey}: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 缓存站点列表 | Cache site list
   */
  private async cacheSiteList(sites: Site[]): Promise<void> {
    try {
      await this.storageUtil.setObject(SITE_LIST_CACHE, sites);
    } catch (error) {
      Logger.warn(TAG, `Failed to cache site list: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 获取缓存的站点列表 | Get cached site list
   */
  private async getCachedSiteList(): Promise<Site[] | null> {
    try {
      return await this.storageUtil.getObject<Site[]>(SITE_LIST_CACHE);
    } catch (error) {
      return null;
    }
  }
  
  /**
   * 使站点列表缓存失效 | Invalidate site list cache
   */
  private async invalidateSiteListCache(): Promise<void> {
    try {
      await this.storageUtil.remove(SITE_LIST_CACHE);
    } catch (error) {
      Logger.warn(TAG, `Failed to invalidate site list cache: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 将数据库记录转换为Site对象 | Convert database record to Site object
   */
  private convertToSiteObject(record: any): Site {
    return {
      key: record[SITE_TABLE.COLUMNS.KEY]?.toString(),
      name: record[SITE_TABLE.COLUMNS.NAME],
      type: record[SITE_TABLE.COLUMNS.TYPE],
      loaderType: record[SITE_TABLE.COLUMNS.LOADER_TYPE],
      api: record[SITE_TABLE.COLUMNS.API],
      logo: record[SITE_TABLE.COLUMNS.LOGO],
      description: record[SITE_TABLE.COLUMNS.DESCRIPTION],
      siteAuth: record[SITE_TABLE.COLUMNS.SITE_AUTH] ? JSON.parse(record[SITE_TABLE.COLUMNS.SITE_AUTH]) : undefined,
      headers: record[SITE_TABLE.COLUMNS.HEADERS] ? JSON.parse(record[SITE_TABLE.COLUMNS.HEADERS]) : undefined,
      config: record[SITE_TABLE.COLUMNS.CONFIG] ? JSON.parse(record[SITE_TABLE.COLUMNS.CONFIG]) : {},
      configItems: record[SITE_TABLE.COLUMNS.CONFIG_ITEMS] ? JSON.parse(record[SITE_TABLE.COLUMNS.CONFIG_ITEMS]) : undefined,
      searchConfig: JSON.parse(record[SITE_TABLE.COLUMNS.SEARCH_CONFIG]),
      filterConfig: JSON.parse(record[SITE_TABLE.COLUMNS.FILTER_CONFIG]),
      performanceConfig: JSON.parse(record[SITE_TABLE.COLUMNS.PERFORMANCE_CONFIG]),
      version: record[SITE_TABLE.COLUMNS.VERSION] ? JSON.parse(record[SITE_TABLE.COLUMNS.VERSION]) : undefined,
      stats: JSON.parse(record[SITE_TABLE.COLUMNS.STATS]),
      lifecycle: JSON.parse(record[SITE_TABLE.COLUMNS.LIFECYCLE]),
      enabled: record[SITE_TABLE.COLUMNS.ENABLED] === 1,
      order: record[SITE_TABLE.COLUMNS.ORDER],
      group: record[SITE_TABLE.COLUMNS.GROUP],
      tags: record[SITE_TABLE.COLUMNS.TAGS] ? JSON.parse(record[SITE_TABLE.COLUMNS.TAGS]) : undefined,
      customCode: record[SITE_TABLE.COLUMNS.CUSTOM_CODE],
      sandboxEnabled: record[SITE_TABLE.COLUMNS.SANDBOX_ENABLED] === 1,
      allowThirdParty: record[SITE_TABLE.COLUMNS.ALLOW_THIRD_PARTY] === 1,
      createdAt: record[SITE_TABLE.COLUMNS.CREATED_AT],
      updatedAt: record[SITE_TABLE.COLUMNS.UPDATED_AT],
      lastUsedAt: record[SITE_TABLE.COLUMNS.LAST_USED_AT],
      userAgent: record[SITE_TABLE.COLUMNS.USER_AGENT],
      referer: record[SITE_TABLE.COLUMNS.REFERER],
      proxy: record[SITE_TABLE.COLUMNS.PROXY],
      encoding: record[SITE_TABLE.COLUMNS.ENCODING],
      charset: record[SITE_TABLE.COLUMNS.CHARSET],
      certificate: record[SITE_TABLE.COLUMNS.CERTIFICATE]
    };
  }
  
  /**
   * 将数据库记录列表转换为Site对象列表 | Convert database record list to Site object list
   */
  private convertToSiteObjects(records: any[]): Site[] {
    return records.map(record => this.convertToSiteObject(record));
  }
}


