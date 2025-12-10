import Logger from '../../common/util/Logger';
import { DatabaseManager } from '../../data/db/DatabaseManager';
import { MediaType } from './MediaService';
import { MediaItem } from '../../data/bean/MediaItem';
import { ValuesBucket, RdbPredicates as RelationalPredicates, ResultSet } from '@ohos.data.relationalStore';

/**
 * 收藏项接�? */
export interface FavoriteItem {
  id: string;           // 收藏ID
  mediaId: string;      // 媒体ID
  siteKey: string;      // 站点标识
  title: string;        // 标题
  cover?: string;       // 封面�?  desc?: string;        // 描述
  type: MediaType;      // 媒体类型
  year?: string;        // 年份
  score?: number;       // 评分
  tags?: string[];      // 标签
  favoriteTime: number; // 收藏时间
  extra?: Record<string, unknown>; // 其他附加信息
}

/**
 * 收藏服务
 * 实现媒体收藏的添加、查询、更新和删除功能
 */
export class FavoriteService {
  private readonly TAG: string = 'FavoriteService';
  private static instance: FavoriteService | null = null;
  private dbManager: DatabaseManager;
  private favoriteTable: string = 'media_favorites';

  /**
   * 获取单例实例
   * @returns FavoriteService
   */
  public static getInstance(): FavoriteService {
    if (!FavoriteService.instance) {
      FavoriteService.instance = new FavoriteService();
    }
    return FavoriteService.instance;
  }

  /**
   * 构造函�?   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.dbManager = DatabaseManager.getInstance();
    this.initialize();
    Logger.info(this.TAG, 'FavoriteService initialized');
  }

  /**
   * 初始化收藏服�?   * @private
   */
  public async initialize(): Promise<void> {
    try {
      // 使用DatabaseManager创建表（表结构已在DatabaseManager中定义）
      // 这里只记录初始化日志
      Logger.info(this.TAG, 'FavoriteService initialized');
    } catch (error) {
      Logger.error(this.TAG, 'Failed to initialize favorite service', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
    }
  }

  /**
   * 添加收藏
   * @param media 媒体信息
   * @returns Promise<FavoriteItem>
   */
  public async addFavorite(media: MediaItem): Promise<FavoriteItem> {
    try {
      const now = Date.now();
      const favoriteId = this.generateFavoriteId(media.siteKey, media.id);

      // 构建收藏�?      const favoriteItem: FavoriteItem = {
        id: favoriteId,
        mediaId: media.id,
        siteKey: media.siteKey,
        title: media.title,
        cover: media.cover,
        desc: media.desc,
        type: media.type,
        year: media.year,
        score: media.score,
        tags: media.tags,
        favoriteTime: now,
        extra: media.extra || {}
      };

      try {
        const db = await this.dbManager.getDatabase();
        
        // 创建ValuesBucket对象
        const valuesBucket: ValuesBucket = {
          id: favoriteItem.id,
          mediaId: favoriteItem.mediaId,
          siteKey: favoriteItem.siteKey,
          title: favoriteItem.title,
          cover: favoriteItem.cover || '',
          desc: favoriteItem.desc || '',
          type: favoriteItem.type,
          year: favoriteItem.year || '',
          score: favoriteItem.score || 0,
          tags: favoriteItem.tags ? JSON.stringify(favoriteItem.tags) : '',
          favoriteTime: favoriteItem.favoriteTime,
          extra: JSON.stringify(favoriteItem.extra)
        };
        
        // 检查是否已存在
        const predicates = new RelationalPredicates(this.favoriteTable);
        predicates.equalTo('mediaId', favoriteItem.mediaId);
        predicates.equalTo('siteKey', favoriteItem.siteKey);
        
        const resultSet = await db.query(this.favoriteTable, predicates);
        const exists = resultSet.rowCount > 0;
        resultSet.close();
        
        if (exists) {
          // 更新现有记录
          await db.update(this.favoriteTable, valuesBucket, predicates);
        } else {
          // 插入新记�?          await db.insert(this.favoriteTable, valuesBucket);
        }

        Logger.info(this.TAG, `Added favorite: ${media.siteKey}:${media.id}`);
        return favoriteItem;
      } catch (error) {
        Logger.error(this.TAG, 'Failed to insert favorite', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
        throw error;
      }
    } catch (error) {
      Logger.error(this.TAG, 'Failed to add favorite', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      throw new Error(`Failed to add favorite: ${error}`);
    }
  }

  /**
   * 移除收藏
   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @returns Promise<boolean>
   */
  public async removeFavorite(mediaId: string, siteKey: string): Promise<boolean> {
    try {
      const favoriteId = this.generateFavoriteId(siteKey, mediaId);
      
      const result = await this.dbManager.executeSql(
        `DELETE FROM ${this.favoriteTable} WHERE id = ?`,
        [favoriteId]
      );

      const success = result.affectedRows > 0;
      if (success) {
        Logger.info(this.TAG, `Removed favorite: ${siteKey}:${mediaId}`);
      }
      return success;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to remove favorite', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return false;
    }
  }

  /**
   * 检查是否已收藏
   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @returns Promise<boolean>
   */
  public async isFavorite(mediaId: string, siteKey: string): Promise<boolean> {
    try {
      const favoriteId = this.generateFavoriteId(siteKey, mediaId);
      
      const result = await this.dbManager.executeSql(
        `SELECT 1 FROM ${this.favoriteTable} WHERE id = ?`,
        [favoriteId]
      );

      return (result.rows as Record<string, unknown>[]).length > 0;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to check favorite status', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return false;
    }
  }

  /**
   * 获取收藏列表
   * @param params 查询参数
   * @returns Promise<FavoriteItem[]>
   */
  public async getFavoriteList(params: {
    type?: MediaType;
    page?: number;
    pageSize?: number;
    sortBy?: 'time' | 'score' | 'title';
    sortOrder?: 'asc' | 'desc';
  } = {}): Promise<FavoriteItem[]> {
    try {
      const {
        type,
        page = 1,
        pageSize = 20,
        sortBy = 'time',
        sortOrder = 'desc'
      } = params;
      
      const offset = (page - 1) * pageSize;

      // 构建查询条件
      let whereClause = '';
      const whereParams: Record<string, string | number | boolean | null>[] = [];
      
      if (type) {
        whereClause = 'WHERE type = ?';
        whereParams.push(type);
      }

      // 构建排序子句
      let orderBy = 'favoriteTime';
      switch (sortBy) {
        case 'score':
          orderBy = 'score';
          break;
        case 'title':
          orderBy = 'title';
          break;
        default:
          orderBy = 'favoriteTime';
      }

      // 执行查询
      const result = await this.dbManager.executeSql(
        `SELECT * FROM ${this.favoriteTable} 
         ${whereClause} 
         ORDER BY ${orderBy} ${sortOrder.toUpperCase()} 
         LIMIT ? OFFSET ?`,
        [...whereParams, pageSize, offset]
      );

      // 解析结果
      return this.parseFavoriteRows(result.rows as Record<string, unknown>[]);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get favorite list', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return [];
    }
  }

  /**
   * 根据ID获取收藏�?   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @returns Promise<FavoriteItem | null>
   */
  public async getFavoriteById(mediaId: string, siteKey: string): Promise<FavoriteItem | null> {
    try {
      const favoriteId = this.generateFavoriteId(siteKey, mediaId);
      
      const result = await this.dbManager.executeSql(
        `SELECT * FROM ${this.favoriteTable} WHERE id = ?`,
        [favoriteId]
      );

      const rows = result.rows as Record<string, unknown>[];
      if (rows.length > 0) {
        return this.parseFavoriteRow(rows[0]);
      }
      return null;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get favorite by id', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return null;
    }
  }

  /**
   * 更新收藏信息
   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @param updateData 更新数据
   * @returns Promise<boolean>
   */
  public async updateFavorite(
    mediaId: string,
    siteKey: string,
    updateData: Partial<Omit<FavoriteItem, 'id' | 'mediaId' | 'siteKey' | 'favoriteTime'>>
  ): Promise<boolean> {
    try {
      const favoriteId = this.generateFavoriteId(siteKey, mediaId);
      
      // 检查是否存�?      const exists = await this.isFavorite(mediaId, siteKey);
      if (!exists) {
        return false;
      }

      // 构建更新语句
      const fields: string[] = [];
      const values: Record<string, string | number | boolean | null>[] = [];

      if (updateData.title !== undefined) {
        fields.push('title = ?');
        values.push(updateData.title);
      }
      if (updateData.cover !== undefined) {
        fields.push('cover = ?');
        values.push(updateData.cover || '');
      }
      if (updateData.desc !== undefined) {
        fields.push('desc = ?');
        values.push(updateData.desc || '');
      }
      if (updateData.type !== undefined) {
        fields.push('type = ?');
        values.push(updateData.type);
      }
      if (updateData.year !== undefined) {
        fields.push('year = ?');
        values.push(updateData.year || '');
      }
      if (updateData.score !== undefined) {
        fields.push('score = ?');
        values.push(updateData.score || 0);
      }
      if (updateData.tags !== undefined) {
        fields.push('tags = ?');
        values.push(updateData.tags ? JSON.stringify(updateData.tags) : '');
      }
      if (updateData.extra !== undefined) {
        fields.push('extra = ?');
        values.push(JSON.stringify(updateData.extra || {}));
      }

      if (fields.length === 0) {
        return true; // 没有需要更新的字段
      }

      // 执行更新
      const result = await this.dbManager.executeSql(
        `UPDATE ${this.favoriteTable} 
         SET ${fields.join(', ')} 
         WHERE id = ?`,
        [...values, favoriteId]
      );

      const success = result.affectedRows > 0;
      if (success) {
        Logger.info(this.TAG, `Updated favorite: ${siteKey}:${mediaId}`);
      }
      return success;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to update favorite', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return false;
    }
  }

  /**
   * 获取收藏数量
   * @param type 媒体类型（可选）
   * @returns Promise<number>
   */
  public async getFavoriteCount(type?: MediaType): Promise<number> {
    try {
      let query = `SELECT COUNT(*) as count FROM ${this.favoriteTable}`;
      const params: Record<string, string | number | boolean | null>[] = [];

      if (type) {
        query += ' WHERE type = ?';
        params.push(type);
      }

      const result = await this.dbManager.executeSql(query, params);
      return ((result.rows as Record<string, unknown>[])[0] as Record<string, unknown>).count as number || 0;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get favorite count', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return 0;
    }
  }

  /**
   * 清空所有收�?   * @returns Promise<boolean>
   */
  public async clearAllFavorites(): Promise<boolean> {
    try {
      await this.dbManager.executeSql(`DELETE FROM ${this.favoriteTable}`);
      Logger.info(this.TAG, 'Cleared all favorites');
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to clear all favorites', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return false;
    }
  }

  /**
   * 清空指定类型的收�?   * @param type 媒体类型
   * @returns Promise<boolean>
   */
  public async clearFavoritesByType(type: MediaType): Promise<boolean> {
    try {
      await this.dbManager.executeSql(
        `DELETE FROM ${this.favoriteTable} WHERE type = ?`,
        [type]
      );
      Logger.info(this.TAG, `Cleared favorites for type: ${type}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to clear favorites by type', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return false;
    }
  }

  /**
   * 批量添加收藏
   * @param mediaList 媒体列表
   * @returns Promise<number> 成功添加的数�?   */
  public async batchAddFavorites(mediaList: MediaItem[]): Promise<number> {
    let successCount = 0;

    for (const media of mediaList) {
      try {
        await this.addFavorite(media);
        successCount++;
      } catch (error) {
        Logger.warn(this.TAG, `Failed to add favorite: ${media.siteKey}:${media.id}, error: ${error}`);
      }
    }

    return successCount;
  }

  /**
   * 批量移除收藏
   * @param favorites 收藏信息列表
   * @returns Promise<number> 成功移除的数�?   */
  public async batchRemoveFavorites(
    favorites: Array<{ mediaId: string; siteKey: string }>
  ): Promise<number> {
    let successCount = 0;

    for (const fav of favorites) {
      try {
        const success = await this.removeFavorite(fav.mediaId, fav.siteKey);
        if (success) {
          successCount++;
        }
      } catch (error) {
        Logger.warn(this.TAG, `Failed to remove favorite: ${fav.siteKey}:${fav.mediaId}, error: ${error}`);
      }
    }

    return successCount;
  }

  /**
   * 搜索收藏
   * @param keyword 搜索关键�?   * @param type 媒体类型（可选）
   * @returns Promise<FavoriteItem[]>
   */
  public async searchFavorites(keyword: string, type?: MediaType): Promise<FavoriteItem[]> {
    try {
      let whereClause = 'WHERE title LIKE ?';
      const params: Record<string, string | number | boolean | null>[] = [`%${keyword}%`];

      if (type) {
        whereClause += ' AND type = ?';
        params.push(type);
      }

      const result = await this.dbManager.executeSql(
        `SELECT * FROM ${this.favoriteTable} 
         ${whereClause} 
         ORDER BY favoriteTime DESC`,
        params
      );

      return this.parseFavoriteRows(result.rows as Record<string, unknown>[]);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to search favorites', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)))));
      return [];
    }
  }

  /**
   * 生成收藏ID
   * @param siteKey 站点标识
   * @param mediaId 媒体ID
   * @returns string
   * @private
   */
  private generateFavoriteId(siteKey: string, mediaId: string): string {
    return `${siteKey}:${mediaId}`;
  }

  /**
   * 解析数据库行到收藏项
   * @param row 数据库行
   * @returns FavoriteItem
   * @private
   */
  private parseFavoriteRow(row: Record<string, unknown>): FavoriteItem {
    return {
      id: row.id,
      mediaId: row.mediaId,
      siteKey: row.siteKey,
      title: row.title,
      cover: row.cover || undefined,
      desc: row.desc || undefined,
      type: row.type,
      year: row.year || undefined,
      score: row.score || undefined,
      tags: row.tags ? JSON.parse(row.tags) : undefined,
      favoriteTime: row.favoriteTime,
      extra: row.extra ? JSON.parse(row.extra) : {}
    };
  }

  /**
   * 解析多行数据库记�?   * @param rows 数据库行数组
   * @returns FavoriteItem[]
   * @private
   */
  private parseFavoriteRows(rows: Record<string, unknown>[]): FavoriteItem[] {
    return rows.map(row => this.parseFavoriteRow(row));
  }
}

// 导出收藏服务单例
export const favoriteService = FavoriteService.getInstance();


