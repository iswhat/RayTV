// CollectionService - 收藏服务类
import Logger from '../../common/util/Logger';
import DateUtil from '../../common/util/DateUtil';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import DatabaseRepository from '../../data/repository/DatabaseRepository';

// 导入模型和DTO
import { VideoType } from '../../data/model/Movie';
import ApiResponse, { ResponseCode } from '../../data/dto/ApiResponse';
import { MovieDetailData } from '../../data/dto/MovieDetailDto';

// 常量定义
const TAG = 'CollectionService';
const MAX_COLLECTION_SIZE = 1000; // 最大收藏数量限制

// 收藏项接口定义
export interface CollectionItem {
  id: string;              // 内容ID
  title: string;           // 标题
  coverUrl: string;        // 封面URL
  type: VideoType;         // 类型
  rating?: number;         // 评分
  releaseYear?: number;    // 发布年份
  addedAt: number;         // 添加时间
  isFavorite: boolean;     // 是否收藏（始终为true）
  genres?: string[];       // 类型标签
  description?: string;    // 简介
  lastUpdate?: number;     // 最后更新时间
  watchProgress?: number;  // 观看进度
}

/**
 * 收藏服务类
 * 负责处理用户收藏相关的业务逻辑
 */
export default class CollectionService {
  private static instance: CollectionService;
  private databaseRepo: DatabaseRepository;

  /**
   * 构造函数（私有，防止外部实例化）
   */
  private constructor() {
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): CollectionService {
    if (!CollectionService.instance) {
      CollectionService.instance = new CollectionService();
    }
    return CollectionService.instance;
  }

  /**
   * 添加收藏
   */
  public async addToCollection(collectionData: Partial<CollectionItem>): Promise<ApiResponse<CollectionItem>> {
    try {
      Logger.info(TAG, 'Adding to collection...', { 
        id: collectionData.id,
        title: collectionData.title
      });

      // 验证必要字段
      if (!collectionData.id) {
        return ApiResponse.validationError<CollectionItem>([
          { field: 'id', message: '内容ID不能为空' }
        ]);
      }

      if (!collectionData.title) {
        return ApiResponse.validationError<CollectionItem>([
          { field: 'title', message: '标题不能为空' }
        ]);
      }

      // 检查是否已收藏
      const isFavorite = await this.databaseRepo.isMovieFavorite(collectionData.id);
      if (isFavorite) {
        return ApiResponse.error(ResponseCode.DUPLICATE_ERROR, '该内容已在收藏列表中');
      }

      // 检查收藏数量限制
      const collectionCount = await this.databaseRepo.getFavoriteCount();
      if (collectionCount >= MAX_COLLECTION_SIZE) {
        return ApiResponse.error(ResponseCode.LIMIT_EXCEEDED, `收藏数量已达上限(${MAX_COLLECTION_SIZE}个)`);
      }

      // 创建收藏项
      const collectionItem: CollectionItem = {
        id: collectionData.id,
        title: collectionData.title,
        coverUrl: collectionData.coverUrl || '',
        type: collectionData.type || VideoType.MOVIE,
        rating: collectionData.rating,
        releaseYear: collectionData.releaseYear,
        addedAt: Date.now(),
        isFavorite: true,
        genres: collectionData.genres,
        description: collectionData.description,
        lastUpdate: Date.now()
      };

      // 添加到收藏
      await this.databaseRepo.addToFavorites(collectionItem);
      Logger.info(TAG, 'Added to collection', { id: collectionItem.id });

      return ApiResponse.success(collectionItem, '添加收藏成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to add to collection', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '添加收藏失败');
    }
  }

  /**
   * 从收藏中移除
   */
  public async removeFromCollection(contentId: string): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Removing from collection...', { contentId });

      // 检查是否已收藏
      const isFavorite = await this.databaseRepo.isMovieFavorite(contentId);
      if (!isFavorite) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '该内容不在收藏列表中');
      }

      // 从收藏中移除
      await this.databaseRepo.removeFromFavorites(contentId);
      Logger.info(TAG, 'Removed from collection', { contentId });

      return ApiResponse.success(true, '移除收藏成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to remove from collection', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '移除收藏失败');
    }
  }

  /**
   * 切换收藏状态
   */
  public async toggleFavorite(collectionData: Partial<CollectionItem>): Promise<ApiResponse<{ item: CollectionItem | null; isFavorite: boolean }>> {
    try {
      Logger.info(TAG, 'Toggling favorite status...', { 
        id: collectionData.id,
        title: collectionData.title
      });

      const contentId = collectionData.id;
      if (!contentId) {
        return ApiResponse.validationError([
          { field: 'id', message: '内容ID不能为空' }
        ]);
      }

      // 检查当前收藏状态
      const isFavorite = await this.databaseRepo.isMovieFavorite(contentId);

      if (isFavorite) {
        // 移除收藏
        await this.databaseRepo.removeFromFavorites(contentId);
        Logger.info(TAG, 'Removed from collection', { contentId });
        return ApiResponse.success({ item: null, isFavorite: false }, '移除收藏成功');
      } else {
        // 检查收藏数量限制
        const collectionCount = await this.databaseRepo.getFavoriteCount();
        if (collectionCount >= MAX_COLLECTION_SIZE) {
          return ApiResponse.error(ResponseCode.LIMIT_EXCEEDED, `收藏数量已达上限(${MAX_COLLECTION_SIZE}个)`);
        }

        // 添加收藏
        const collectionItem: CollectionItem = {
          id: contentId,
          title: collectionData.title || '',
          coverUrl: collectionData.coverUrl || '',
          type: collectionData.type || VideoType.MOVIE,
          rating: collectionData.rating,
          releaseYear: collectionData.releaseYear,
          addedAt: Date.now(),
          isFavorite: true,
          genres: collectionData.genres,
          description: collectionData.description,
          lastUpdate: Date.now()
        };

        await this.databaseRepo.addToFavorites(collectionItem);
        Logger.info(TAG, 'Added to collection', { contentId });
        return ApiResponse.success({ item: collectionItem, isFavorite: true }, '添加收藏成功');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to toggle favorite status', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '切换收藏状态失败');
    }
  }

  /**
   * 获取收藏列表
   */
  public async getCollectionList(params: {
    page?: number;
    pageSize?: number;
    type?: VideoType;
    sortBy?: 'addedAt' | 'title' | 'rating' | 'releaseYear';
    sortOrder?: 'asc' | 'desc';
  } = {}): Promise<ApiResponse<{
    items: (CollectionItem & { movieInfo?: Partial<MovieDetailData> })[];
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
  }>> {
    try {
      const {
        page = 1,
        pageSize = 20,
        type,
        sortBy = 'addedAt',
        sortOrder = 'desc'
      } = params;

      Logger.info(TAG, 'Getting collection list...', { page, pageSize, type, sortBy, sortOrder });

      // 获取收藏列表
      const collectionItems = await this.databaseRepo.getFavoritesList({
        page,
        pageSize,
        type,
        sortBy,
        sortOrder
      });

      // 获取总数
      const total = await this.databaseRepo.getFavoriteCount(type);
      const totalPages = Math.ceil(total / pageSize);

      // 增强收藏数据
      const enhancedItems = await this.enhanceCollectionWithMovieInfo(collectionItems);

      return ApiResponse.success({
        items: enhancedItems,
        total,
        page,
        pageSize,
        totalPages
      }, '获取收藏列表成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get collection list', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取收藏列表失败');
    }
  }

  /**
   * 获取收藏详情
   */
  public async getCollectionItem(contentId: string): Promise<ApiResponse<CollectionItem | null>> {
    try {
      Logger.info(TAG, 'Getting collection item...', { contentId });

      const item = await this.databaseRepo.getFavoriteById(contentId);
      if (item) {
        return ApiResponse.success(item, '获取收藏详情成功');
      } else {
        return ApiResponse.success(null, '收藏项不存在');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to get collection item', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取收藏详情失败');
    }
  }

  /**
   * 检查是否已收藏
   */
  public async isFavorite(contentId: string): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Checking if favorite...', { contentId });

      const isFavorite = await this.databaseRepo.isMovieFavorite(contentId);
      return ApiResponse.success(isFavorite, '检查完成');
    } catch (error) {
      Logger.error(TAG, 'Failed to check favorite status', error);
      return ApiResponse.success(false, '检查失败，默认返回未收藏');
    }
  }

  /**
   * 批量添加收藏
   */
  public async batchAddToCollection(items: Partial<CollectionItem>[]): Promise<ApiResponse<{
    success: number;
    failed: number;
    failedItems: string[];
  }>> {
    try {
      Logger.info(TAG, 'Batch adding to collection...', { totalItems: items.length });

      let success = 0;
      let failed = 0;
      const failedItems: string[] = [];

      // 检查当前收藏数量
      const currentCount = await this.databaseRepo.getFavoriteCount();
      const availableSlots = MAX_COLLECTION_SIZE - currentCount;

      if (availableSlots <= 0) {
        return ApiResponse.error(ResponseCode.LIMIT_EXCEEDED, `收藏数量已达上限(${MAX_COLLECTION_SIZE}个)`);
      }

      // 限制批量添加的数量
      const itemsToAdd = items.slice(0, Math.min(items.length, availableSlots));

      for (const item of itemsToAdd) {
        try {
          // 检查是否已收藏
          const isFavorite = await this.databaseRepo.isMovieFavorite(item.id);
          if (isFavorite) {
            failed++;
            failedItems.push(item.id);
            continue;
          }

          const collectionItem: CollectionItem = {
            id: item.id,
            title: item.title || '',
            coverUrl: item.coverUrl || '',
            type: item.type || VideoType.MOVIE,
            rating: item.rating,
            releaseYear: item.releaseYear,
            addedAt: Date.now(),
            isFavorite: true,
            genres: item.genres,
            description: item.description,
            lastUpdate: Date.now()
          };

          await this.databaseRepo.addToFavorites(collectionItem);
          success++;
        } catch (error) {
          Logger.warn(TAG, `Failed to add item ${item.id} to collection`, error);
          failed++;
          if (item.id) {
            failedItems.push(item.id);
          }
        }
      }

      Logger.info(TAG, 'Batch add completed', { success, failed, totalProcessed: success + failed });
      return ApiResponse.success({
        success,
        failed,
        failedItems
      }, `批量添加完成，成功${success}个，失败${failed}个`);
    } catch (error) {
      Logger.error(TAG, 'Failed to batch add to collection', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '批量添加收藏失败');
    }
  }

  /**
   * 批量移除收藏
   */
  public async batchRemoveFromCollection(contentIds: string[]): Promise<ApiResponse<{
    success: number;
    failed: number;
  }>> {
    try {
      Logger.info(TAG, 'Batch removing from collection...', { totalItems: contentIds.length });

      let success = 0;
      let failed = 0;

      for (const contentId of contentIds) {
        try {
          await this.databaseRepo.removeFromFavorites(contentId);
          success++;
        } catch (error) {
          Logger.warn(TAG, `Failed to remove item ${contentId} from collection`, error);
          failed++;
        }
      }

      Logger.info(TAG, 'Batch remove completed', { success, failed });
      return ApiResponse.success({
        success,
        failed
      }, `批量移除完成，成功${success}个，失败${failed}个`);
    } catch (error) {
      Logger.error(TAG, 'Failed to batch remove from collection', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '批量移除收藏失败');
    }
  }

  /**
   * 清空收藏
   */
  public async clearAllCollection(type?: VideoType): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Clearing all collection...', { type });

      await this.databaseRepo.clearAllFavorites(type);
      Logger.info(TAG, 'All collection cleared', { type });

      return ApiResponse.success(true, '清空收藏成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear all collection', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '清空收藏失败');
    }
  }

  /**
   * 获取收藏统计
   */
  public async getCollectionStats(): Promise<ApiResponse<{
    totalCount: number;
    movieCount: number;
    tvCount: number;
    animeCount: number;
    recentAdded: CollectionItem[];
    ratingDistribution: {
      rating: number;
      count: number;
    }[];
    yearDistribution: {
      year: number;
      count: number;
    }[];
  }>> {
    try {
      Logger.info(TAG, 'Getting collection stats...');

      // 获取总数
      const totalCount = await this.databaseRepo.getFavoriteCount();
      const movieCount = await this.databaseRepo.getFavoriteCount(VideoType.MOVIE);
      const tvCount = await this.databaseRepo.getFavoriteCount(VideoType.TV_SERIES);
      const animeCount = await this.databaseRepo.getFavoriteCount(VideoType.ANIME);

      // 获取最近添加的收藏
      const recentAdded = await this.databaseRepo.getFavoritesList({
        page: 1,
        pageSize: 5,
        sortBy: 'addedAt',
        sortOrder: 'desc'
      });

      // 获取评分分布
      const ratingDistribution = await this.databaseRepo.getFavoriteRatingStats();

      // 获取年份分布
      const yearDistribution = await this.databaseRepo.getFavoriteYearStats();

      return ApiResponse.success({
        totalCount,
        movieCount,
        tvCount,
        animeCount,
        recentAdded,
        ratingDistribution,
        yearDistribution
      }, '获取收藏统计成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get collection stats', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取收藏统计失败');
    }
  }

  /**
   * 搜索收藏
   */
  public async searchCollection(keyword: string, type?: VideoType): Promise<ApiResponse<CollectionItem[]>> {
    try {
      Logger.info(TAG, 'Searching collection...', { keyword, type });

      if (!keyword || keyword.trim().length === 0) {
        return ApiResponse.validationError([
          { field: 'keyword', message: '搜索关键词不能为空' }
        ]);
      }

      const results = await this.databaseRepo.searchFavorites(keyword.trim(), type);
      return ApiResponse.success(results, `找到${results.length}个匹配的收藏项`);
    } catch (error) {
      Logger.error(TAG, 'Failed to search collection', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '搜索收藏失败');
    }
  }

  /**
   * 导出收藏
   */
  public async exportCollection(): Promise<ApiResponse<string>> {
    try {
      Logger.info(TAG, 'Exporting collection...');

      // 获取所有收藏
      const allItems = await this.databaseRepo.getAllFavorites();

      // 转换为导出格式
      const exportData = {
        exportDate: new Date().toISOString(),
        totalItems: allItems.length,
        items: allItems.map(item => ({
          id: item.id,
          title: item.title,
          coverUrl: item.coverUrl,
          type: item.type,
          rating: item.rating,
          releaseYear: item.releaseYear,
          addedAt: item.addedAt,
          genres: item.genres,
          description: item.description
        }))
      };

      const jsonStr = JSON.stringify(exportData, null, 2);
      return ApiResponse.success(jsonStr, '导出收藏成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to export collection', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导出收藏失败');
    }
  }

  /**
   * 导入收藏
   */
  public async importCollection(jsonData: string, merge: boolean = true): Promise<ApiResponse<{
    imported: number;
    skipped: number;
    existing: number;
  }>> {
    try {
      Logger.info(TAG, 'Importing collection...', { merge });

      // 解析JSON数据
      const importData = JSON.parse(jsonData);
      const items = importData.items || [];

      let imported = 0;
      let skipped = 0;
      let existing = 0;

      // 检查收藏数量限制
      const currentCount = await this.databaseRepo.getFavoriteCount();
      const availableSlots = MAX_COLLECTION_SIZE - currentCount;

      if (availableSlots <= 0 && !merge) {
        return ApiResponse.error(ResponseCode.LIMIT_EXCEEDED, `收藏数量已达上限(${MAX_COLLECTION_SIZE}个)`);
      }

      for (const itemData of items) {
        try {
          // 检查是否已存在
          const isFavorite = await this.databaseRepo.isMovieFavorite(itemData.id);

          if (isFavorite) {
            if (merge) {
              // 更新已存在的收藏
              const updatedItem: CollectionItem = {
                id: itemData.id,
                title: itemData.title || '',
                coverUrl: itemData.coverUrl || '',
                type: itemData.type || VideoType.MOVIE,
                rating: itemData.rating,
                releaseYear: itemData.releaseYear,
                addedAt: itemData.addedAt || Date.now(), // 保留原始添加时间
                isFavorite: true,
                genres: itemData.genres,
                description: itemData.description,
                lastUpdate: Date.now()
              };
              
              await this.databaseRepo.updateFavorite(updatedItem);
              imported++;
            } else {
              existing++;
            }
          } else {
            // 检查是否超出限制
            if (imported >= availableSlots && !merge) {
              skipped++;
              continue;
            }

            // 添加新收藏
            const collectionItem: CollectionItem = {
              id: itemData.id,
              title: itemData.title || '',
              coverUrl: itemData.coverUrl || '',
              type: itemData.type || VideoType.MOVIE,
              rating: itemData.rating,
              releaseYear: itemData.releaseYear,
              addedAt: itemData.addedAt || Date.now(),
              isFavorite: true,
              genres: itemData.genres,
              description: itemData.description,
              lastUpdate: Date.now()
            };

            await this.databaseRepo.addToFavorites(collectionItem);
            imported++;
          }
        } catch (error) {
          Logger.warn(TAG, `Failed to import collection item ${itemData.id}`, error);
          skipped++;
        }
      }

      Logger.info(TAG, 'Collection import completed', { imported, skipped, existing });
      return ApiResponse.success({
        imported,
        skipped,
        existing
      }, `导入完成，成功导入${imported}个，跳过${skipped}个，已存在${existing}个`);
    } catch (error) {
      Logger.error(TAG, 'Failed to import collection', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导入收藏失败，请检查数据格式');
    }
  }

  // ========== 内部辅助方法 ==========

  /**
   * 增强收藏数据
   */
  private async enhanceCollectionWithMovieInfo(items: CollectionItem[]): Promise<(CollectionItem & { movieInfo?: Partial<MovieDetailData> })[]> {
    try {
      // 这里可以根据需要增强收藏数据，添加电影详细信息
      // 目前只返回原始收藏数据
      return items.map(item => ({ ...item }));
    } catch (error) {
      Logger.error(TAG, 'Failed to enhance collection with movie info', error);
      return items as any;
    }
  }

  /**
   * 按标签获取收藏
   */
  public async getFavoritesByGenre(genre: string, page: number = 1, pageSize: number = 20): Promise<ApiResponse<CollectionItem[]>> {
    try {
      Logger.info(TAG, 'Getting favorites by genre...', { genre, page, pageSize });

      const results = await this.databaseRepo.getFavoritesByGenre(genre, page, pageSize);
      return ApiResponse.success(results, `找到${results.length}个匹配的收藏项`);
    } catch (error) {
      Logger.error(TAG, 'Failed to get favorites by genre', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '按标签获取收藏失败');
    }
  }

  /**
   * 获取所有收藏标签
   */
  public async getAllGenres(): Promise<ApiResponse<Array<{ genre: string; count: number }>>> {
    try {
      Logger.info(TAG, 'Getting all genres...');

      const genres = await this.databaseRepo.getFavoriteGenres();
      return ApiResponse.success(genres, '获取标签列表成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get all genres', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取标签列表失败');
    }
  }

  /**
   * 按年份获取收藏
   */
  public async getFavoritesByYear(year: number, page: number = 1, pageSize: number = 20): Promise<ApiResponse<CollectionItem[]>> {
    try {
      Logger.info(TAG, 'Getting favorites by year...', { year, page, pageSize });

      const results = await this.databaseRepo.getFavoritesByYear(year, page, pageSize);
      return ApiResponse.success(results, `找到${results.length}个匹配的收藏项`);
    } catch (error) {
      Logger.error(TAG, 'Failed to get favorites by year', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '按年份获取收藏失败');
    }
  }
}