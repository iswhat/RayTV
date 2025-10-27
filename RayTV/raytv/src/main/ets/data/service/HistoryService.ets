// HistoryService - 历史记录服务类
import Logger from '../../common/util/Logger';
import DateUtil from '../../common/util/DateUtil';
import StorageUtil from '../../common/util/StorageUtil';
import RepositoryFactory from '../repository/RepositoryFactory';
import { DatabaseRepository } from '../repository/DatabaseRepository';

// 导入模型和DTO
import History from '../model/History';
import { VideoType } from '../model/Movie';
import ApiResponse, { ResponseCode } from '../dto/ApiResponse';
import { MovieDetailData } from '../dto/MovieDetailDto';

// 常量定义
const TAG = 'HistoryService';
const MAX_HISTORY_ITEMS = 500; // 最大历史记录数量限制
const CLEAR_BATCH_SIZE = 50;    // 清理批次大小

/**
 * 历史记录服务类
 * 负责处理用户观看历史相关的业务逻辑
 */
export default class HistoryService {
  private static instance: HistoryService;
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
  public static getInstance(): HistoryService {
    if (!HistoryService.instance) {
      HistoryService.instance = new HistoryService();
    }
    return HistoryService.instance;
  }

  /**
   * 添加或更新观看历史
   */
  public async addOrUpdateHistory(historyData: Partial<History>): Promise<ApiResponse<History>> {
    try {
      Logger.info(TAG, 'Adding or updating history...', { 
        contentId: historyData.contentId,
        episodeId: historyData.episodeId
      });

      // 验证必要字段
      if (!historyData.contentId) {
        return ApiResponse.validationError<History>([
          { field: 'contentId', message: '内容ID不能为空' }
        ]);
      }

      if (!historyData.userId) {
        // 默认为当前用户
        historyData.userId = 'current';
      }

      // 设置时间戳
      historyData.timestamp = Date.now();

      // 检查是否已存在该内容的历史记录
      const existingHistory = await this.databaseRepo.getHistoryByContentId(
        historyData.userId,
        historyData.contentId,
        historyData.episodeId
      );

      let history: History;

      if (existingHistory) {
        // 更新现有记录
        history = existingHistory;
        history.updateProgress(historyData.progress || 0);
        history.updateTimestamp(historyData.timestamp);
        history.updateWatchTime(historyData.watchTime || 0);
        
        if (historyData.duration) {
          history.setDuration(historyData.duration);
        }
        
        if (historyData.completed !== undefined) {
          history.setCompleted(historyData.completed);
        }
        
        await this.databaseRepo.updateHistory(history);
        Logger.info(TAG, 'History updated', { contentId: historyData.contentId });
      } else {
        // 创建新记录
        history = new History({
          userId: historyData.userId,
          contentId: historyData.contentId,
          contentTitle: historyData.contentTitle || '',
          contentType: historyData.contentType || VideoType.MOVIE,
          coverUrl: historyData.coverUrl || '',
          episodeId: historyData.episodeId,
          episodeTitle: historyData.episodeTitle || '',
          progress: historyData.progress || 0,
          duration: historyData.duration || 0,
          watchTime: historyData.watchTime || 0,
          timestamp: historyData.timestamp,
          completed: historyData.completed || false,
          lastPlaybackPosition: historyData.lastPlaybackPosition || 0
        });

        // 检查历史记录数量限制
        const totalCount = await this.databaseRepo.getHistoryCount(history.userId);
        if (totalCount >= MAX_HISTORY_ITEMS) {
          // 删除最旧的记录以保持数量限制
          await this.deleteOldestHistory(history.userId, CLEAR_BATCH_SIZE);
        }

        await this.databaseRepo.addToHistory(history);
        Logger.info(TAG, 'History added', { contentId: historyData.contentId });
      }

      // 异步更新观看统计
      this.updateWatchStats(historyData.userId, historyData.contentId, historyData.watchTime || 0);

      return ApiResponse.success(history, '历史记录更新成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to add or update history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新历史记录失败');
    }
  }

  /**
   * 获取历史记录列表
   */
  public async getHistoryList(params: {
    userId?: string;
    page?: number;
    pageSize?: number;
    type?: VideoType;
    sortBy?: 'timestamp' | 'title';
    sortOrder?: 'asc' | 'desc';
  } = {}): Promise<ApiResponse<{
    items: (History & { movieInfo?: Partial<MovieDetailData> })[];
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
  }>> {
    try {
      const {
        userId = 'current',
        page = 1,
        pageSize = 20,
        type,
        sortBy = 'timestamp',
        sortOrder = 'desc'
      } = params;

      Logger.info(TAG, 'Getting history list...', { userId, page, pageSize, type });

      // 获取历史记录
      const histories = await this.databaseRepo.getHistoryList({
        userId,
        page,
        pageSize,
        type,
        sortBy,
        sortOrder
      });

      // 获取总数
      const total = await this.databaseRepo.getHistoryCount(userId, type);
      const totalPages = Math.ceil(total / pageSize);

      // 增强历史记录数据（如果需要）
      const enhancedHistories = await this.enhanceHistoryWithMovieInfo(histories);

      return ApiResponse.success({
        items: enhancedHistories,
        total,
        page,
        pageSize,
        totalPages
      }, '获取历史记录成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get history list', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取历史记录失败');
    }
  }

  /**
   * 获取内容的历史记录
   */
  public async getContentHistory(contentId: string, userId: string = 'current'): Promise<ApiResponse<History | null>> {
    try {
      Logger.info(TAG, 'Getting content history...', { userId, contentId });

      const history = await this.databaseRepo.getHistoryByContentId(userId, contentId);
      return ApiResponse.success(history, '获取内容历史记录成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get content history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取内容历史记录失败');
    }
  }

  /**
   * 获取剧集历史记录
   */
  public async getEpisodeHistory(contentId: string, episodeId: string, userId: string = 'current'): Promise<ApiResponse<History | null>> {
    try {
      Logger.info(TAG, 'Getting episode history...', { userId, contentId, episodeId });

      const history = await this.databaseRepo.getHistoryByContentId(userId, contentId, episodeId);
      return ApiResponse.success(history, '获取剧集历史记录成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get episode history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取剧集历史记录失败');
    }
  }

  /**
   * 删除单条历史记录
   */
  public async deleteHistory(historyId: string, userId: string = 'current'): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Deleting history...', { userId, historyId });

      // 先获取历史记录以获取contentId
      const history = await this.databaseRepo.getHistoryById(historyId);
      if (history && history.userId === userId) {
        await this.databaseRepo.deleteHistory(historyId);
        Logger.info(TAG, 'History deleted', { historyId });
        return ApiResponse.success(true, '删除历史记录成功');
      } else {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '历史记录不存在或无权删除');
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to delete history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '删除历史记录失败');
    }
  }

  /**
   * 根据内容ID删除历史记录
   */
  public async deleteHistoryByContentId(contentId: string, userId: string = 'current'): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Deleting history by contentId...', { userId, contentId });

      const result = await this.databaseRepo.deleteHistoryByContentId(userId, contentId);
      Logger.info(TAG, 'History deleted by contentId', { contentId, deleted: result });
      
      return ApiResponse.success(result, result ? '删除历史记录成功' : '未找到匹配的历史记录');
    } catch (error) {
      Logger.error(TAG, 'Failed to delete history by contentId', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '删除历史记录失败');
    }
  }

  /**
   * 清空历史记录
   */
  public async clearAllHistory(userId: string = 'current', type?: VideoType): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Clearing all history...', { userId, type });

      await this.databaseRepo.clearAllHistory(userId, type);
      Logger.info(TAG, 'All history cleared', { userId, type });
      
      // 清空统计数据
      await this.clearWatchStats(userId, type);
      
      return ApiResponse.success(true, '清空历史记录成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear all history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '清空历史记录失败');
    }
  }

  /**
   * 清空未完成的历史记录
   */
  public async clearUnfinishedHistory(userId: string = 'current'): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Clearing unfinished history...', { userId });

      await this.databaseRepo.clearUnfinishedHistory(userId);
      Logger.info(TAG, 'Unfinished history cleared', { userId });
      
      return ApiResponse.success(true, '清空未完成历史记录成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear unfinished history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '清空未完成历史记录失败');
    }
  }

  /**
   * 清空已完成的历史记录
   */
  public async clearFinishedHistory(userId: string = 'current'): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Clearing finished history...', { userId });

      await this.databaseRepo.clearFinishedHistory(userId);
      Logger.info(TAG, 'Finished history cleared', { userId });
      
      return ApiResponse.success(true, '清空已完成历史记录成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear finished history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '清空已完成历史记录失败');
    }
  }

  /**
   * 获取观看统计信息
   */
  public async getWatchStats(userId: string = 'current'): Promise<ApiResponse<{
    totalWatchTime: number;
    totalMovies: number;
    totalEpisodes: number;
    totalCompleted: number;
    recentDays: {
      day: string;
      watchTime: number;
      count: number;
    }[];
    categoryDistribution: {
      category: string;
      count: number;
      percentage: number;
    }[];
    lastWatchTime?: number;
  }>> {
    try {
      Logger.info(TAG, 'Getting watch stats...', { userId });

      // 从缓存或数据库获取统计信息
      const statsKey = `watch_stats_${userId}`;
      const cachedStats = await StorageUtil.getObject<any>(statsKey);
      const cacheTime = 3600000; // 1小时缓存

      // 如果缓存有效，直接返回
      if (cachedStats && Date.now() - cachedStats.timestamp < cacheTime) {
        Logger.info(TAG, 'Returning cached watch stats');
        return ApiResponse.success(cachedStats.data);
      }

      // 计算总观看时间
      const totalWatchTime = await this.databaseRepo.getTotalWatchTime(userId);
      
      // 计算总内容数（去重）
      const totalMovies = await this.databaseRepo.getHistoryContentCount(userId, VideoType.MOVIE);
      const totalTvShows = await this.databaseRepo.getHistoryContentCount(userId, VideoType.TV_SERIES);
      const totalEpisodes = await this.databaseRepo.getHistoryEpisodeCount(userId);
      const totalCompleted = await this.databaseRepo.getCompletedHistoryCount(userId);
      
      // 获取最近7天的观看统计
      const recentDays = await this.getRecentWatchStats(userId, 7);
      
      // 获取分类分布
      const categoryDistribution = await this.getCategoryDistribution(userId);
      
      // 获取最后观看时间
      const lastHistory = await this.databaseRepo.getLatestHistory(userId);
      const lastWatchTime = lastHistory?.timestamp;

      const stats = {
        totalWatchTime,
        totalMovies: totalMovies + totalTvShows,
        totalEpisodes,
        totalCompleted,
        recentDays,
        categoryDistribution,
        lastWatchTime
      };

      // 缓存结果
      await StorageUtil.setObject(statsKey, {
        data: stats,
        timestamp: Date.now()
      });

      return ApiResponse.success(stats, '获取观看统计成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get watch stats', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取观看统计失败');
    }
  }

  /**
   * 检查是否有未看完的内容
   */
  public async hasUnfinishedContent(userId: string = 'current'): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Checking for unfinished content...', { userId });

      const hasUnfinished = await this.databaseRepo.hasUnfinishedHistory(userId);
      return ApiResponse.success(hasUnfinished, '检查完成');
    } catch (error) {
      Logger.error(TAG, 'Failed to check unfinished content', error);
      return ApiResponse.success(false, '检查失败，默认返回无未完成内容');
    }
  }

  /**
   * 获取未看完的内容列表
   */
  public async getUnfinishedContent(userId: string = 'current', limit: number = 20): Promise<ApiResponse<History[]>> {
    try {
      Logger.info(TAG, 'Getting unfinished content...', { userId, limit });

      const unfinished = await this.databaseRepo.getUnfinishedHistory(userId, limit);
      return ApiResponse.success(unfinished, '获取未完成内容成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get unfinished content', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取未完成内容失败');
    }
  }

  // ========== 内部辅助方法 ==========

  /**
   * 删除最旧的历史记录
   */
  private async deleteOldestHistory(userId: string, count: number): Promise<void> {
    try {
      const oldestHistories = await this.databaseRepo.getOldestHistory(userId, count);
      for (const history of oldestHistories) {
        await this.databaseRepo.deleteHistory(history.id);
      }
      Logger.info(TAG, `Deleted ${oldestHistories.length} oldest history records`, { userId });
    } catch (error) {
      Logger.error(TAG, 'Failed to delete oldest history', error);
    }
  }

  /**
   * 增强历史记录数据
   */
  private async enhanceHistoryWithMovieInfo(histories: History[]): Promise<(History & { movieInfo?: Partial<MovieDetailData> })[]> {
    try {
      // 这里可以根据需要增强历史记录，添加电影详细信息
      // 目前只返回原始历史记录
      return histories.map(history => ({ ...history }));
    } catch (error) {
      Logger.error(TAG, 'Failed to enhance history with movie info', error);
      return histories as any;
    }
  }

  /**
   * 更新观看统计
   */
  private async updateWatchStats(userId: string, contentId: string, watchTime: number): Promise<void> {
    try {
      // 异步更新，不阻塞主流程
      // 清除统计缓存
      const statsKey = `watch_stats_${userId}`;
      await StorageUtil.remove(statsKey);
    } catch (error) {
      Logger.error(TAG, 'Failed to update watch stats', error);
    }
  }

  /**
   * 清空观看统计
   */
  private async clearWatchStats(userId: string, type?: VideoType): Promise<void> {
    try {
      const statsKey = `watch_stats_${userId}`;
      await StorageUtil.remove(statsKey);
    } catch (error) {
      Logger.error(TAG, 'Failed to clear watch stats', error);
    }
  }

  /**
   * 获取最近几天的观看统计
   */
  private async getRecentWatchStats(userId: string, days: number): Promise<{
    day: string;
    watchTime: number;
    count: number;
  }[]> {
    try {
      const stats = [];
      const now = new Date();

      for (let i = days - 1; i >= 0; i--) {
        const date = new Date(now);
        date.setDate(date.getDate() - i);
        const dateStr = DateUtil.formatDate(date, 'yyyy-MM-dd');
        
        // 获取当天的开始和结束时间戳
        const startTime = DateUtil.getDayStart(date).getTime();
        const endTime = DateUtil.getDayEnd(date).getTime();
        
        // 查询当天的观看记录
        const dayStats = await this.databaseRepo.getDayWatchStats(userId, startTime, endTime);
        
        stats.push({
          day: dateStr,
          watchTime: dayStats.totalWatchTime,
          count: dayStats.totalCount
        });
      }

      return stats;
    } catch (error) {
      Logger.error(TAG, 'Failed to get recent watch stats', error);
      return [];
    }
  }

  /**
   * 获取分类分布统计
   */
  private async getCategoryDistribution(userId: string): Promise<{
    category: string;
    count: number;
    percentage: number;
  }[]> {
    try {
      // 获取分类统计
      const categories = await this.databaseRepo.getHistoryCategoryStats(userId);
      
      // 计算总数
      const total = categories.reduce((sum, cat) => sum + cat.count, 0);
      
      // 计算百分比并返回
      return categories.map(cat => ({
        category: cat.category || '未分类',
        count: cat.count,
        percentage: total > 0 ? Math.round((cat.count / total) * 100) : 0
      }));
    } catch (error) {
      Logger.error(TAG, 'Failed to get category distribution', error);
      return [];
    }
  }

  /**
   * 导出历史记录
   */
  public async exportHistory(userId: string = 'current'): Promise<ApiResponse<string>> {
    try {
      Logger.info(TAG, 'Exporting history...', { userId });

      // 获取所有历史记录
      const allHistories = await this.databaseRepo.getAllHistory(userId);
      
      // 转换为JSON
      const exportData = {
        exportDate: new Date().toISOString(),
        userId,
        totalRecords: allHistories.length,
        histories: allHistories.map(h => h.toObject())
      };
      
      const jsonStr = JSON.stringify(exportData, null, 2);
      
      return ApiResponse.success(jsonStr, '导出历史记录成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to export history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导出历史记录失败');
    }
  }

  /**
   * 导入历史记录
   */
  public async importHistory(jsonData: string, merge: boolean = true, userId: string = 'current'): Promise<ApiResponse<{ imported: number; skipped: number }>> {
    try {
      Logger.info(TAG, 'Importing history...', { userId, merge });

      // 解析JSON数据
      const importData = JSON.parse(jsonData);
      const histories = importData.histories || [];
      
      let imported = 0;
      let skipped = 0;
      
      for (const historyData of histories) {
        try {
          // 转换为History对象
          const history = new History({
            userId: historyData.userId || userId,
            contentId: historyData.contentId,
            contentTitle: historyData.contentTitle || '',
            contentType: historyData.contentType || VideoType.MOVIE,
            coverUrl: historyData.coverUrl || '',
            episodeId: historyData.episodeId,
            episodeTitle: historyData.episodeTitle || '',
            progress: historyData.progress || 0,
            duration: historyData.duration || 0,
            watchTime: historyData.watchTime || 0,
            timestamp: historyData.timestamp || Date.now(),
            completed: historyData.completed || false,
            lastPlaybackPosition: historyData.lastPlaybackPosition || 0
          });

          // 检查是否已存在
          const existing = await this.databaseRepo.getHistoryByContentId(
            history.userId,
            history.contentId,
            history.episodeId
          );

          if (existing) {
            if (merge) {
              // 合并策略：保留较新的记录
              if (history.timestamp > existing.timestamp) {
                await this.databaseRepo.updateHistory(history);
                imported++;
              } else {
                skipped++;
              }
            } else {
              skipped++;
            }
          } else {
            // 添加新记录
            await this.databaseRepo.addToHistory(history);
            imported++;
          }
        } catch (error) {
          Logger.warn(TAG, 'Failed to import single history record', error);
          skipped++;
        }
      }

      // 清理旧记录以保持数量限制
      const totalCount = await this.databaseRepo.getHistoryCount(userId);
      if (totalCount > MAX_HISTORY_ITEMS) {
        const toDelete = totalCount - MAX_HISTORY_ITEMS;
        await this.deleteOldestHistory(userId, toDelete);
      }

      // 清除统计缓存
      await this.clearWatchStats(userId);

      return ApiResponse.success({
        imported,
        skipped
      }, `导入成功，共导入${imported}条记录，跳过${skipped}条记录`);
    } catch (error) {
      Logger.error(TAG, 'Failed to import history', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '导入历史记录失败，请检查数据格式');
    }
  }
}