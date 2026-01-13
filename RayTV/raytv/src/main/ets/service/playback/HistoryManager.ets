// HistoryManager.ets - 历史记录管理器 | History record manager
// 负责管理视频播放历史记录 | Responsible for managing video playback history records

import Logger from '../../common/util/Logger';
import HistoryDao from '../../data/db/dao/HistoryDao';
import ConfigService from '../config/ConfigService';

// 常量定义 | Constant definitions
const TAG = 'HistoryManager';
const DEFAULT_MAX_HISTORY_COUNT = 100; // 默认最大历史记录数量 | Default maximum history record count

// 历史记录项接口 | History item interface
export interface HistoryItem {
  id: string;           // 唯一标识 | Unique identifier
  title: string;        // 标题 | Title
  subtitle?: string;    // 副标题 | Subtitle
  url: string;          // 播放地址 | Playback address
  coverUrl?: string;    // 封面图片 | Cover image
  position: number;     // 播放位置（秒）| Playback position (seconds)
  duration: number;     // 总时长（毫秒）| Total duration (milliseconds)
  progress: number;     // 播放进度（0-1）| Playback progress (0-1)
  lastPlayed: number;   // 最后播放时间戳 | Last played timestamp
  siteKey?: string;     // 站点标识 | Site identifier
  videoId?: string;     // 视频ID | Video ID
  metadata?: Record<string, unknown>; // 额外参数 | Extra parameters
}

export default class HistoryManager {
  private static instance: HistoryManager;
  private historyDao: HistoryDao;
  private configService: ConfigService;
  private maxHistoryCount: number = DEFAULT_MAX_HISTORY_COUNT;
  private isInitialized: boolean = false;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): HistoryManager {
    if (!HistoryManager.instance) {
      HistoryManager.instance = new HistoryManager();
    }
    return HistoryManager.instance;
  }

  /**
   * 构造函数 | Constructor
   */
  private constructor() {
    this.historyDao = new HistoryDao();
    this.configService = ConfigService.getInstance();
  }

  /**
   * 初始化历史记录管理器 | Initialize history manager
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'History manager already initialized');
      return;
    }

    try {
      // 加载配置 | Load config
      await this.loadConfig();
      
      // 确保数据库表创建 | Ensure database table creation
      await this.historyDao.createTable();
      
      this.isInitialized = true;
      Logger.info(TAG, 'History manager initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize history manager: ${error}`);
      throw error;
    }
  }

  /**
   * 加载配置 | Load config
   */
  private async loadConfig(): Promise<void> {
    try {
      const maxCount = await this.configService.getConfig('maxHistoryCount');
      if (typeof maxCount === 'number' && maxCount > 0) {
        this.maxHistoryCount = maxCount;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}` instanceof Error ? `Failed to load history config: ${error}` : new Error(String(`Failed to load history config: ${error}`)))))));
    }
  }

  /**
   * 保存或更新历史记录 | Save or update history record
   * @param historyItem 历史记录项 | History item
   */
  public async saveHistory(historyItem: HistoryItem): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      // 生成唯一ID（如果没有）| Generate unique ID (if not exists)
      if (!historyItem.id) {
        historyItem.id = `${historyItem.siteKey || 'default'}:${historyItem.videoId || this.generateId()}`;
      }

      // 更新最后播放时间和进度 | Update last played time and progress
      historyItem.lastPlayed = Date.now();
      historyItem.progress = historyItem.duration > 0 ? 
        Math.min(1, Math.max(0, historyItem.position / historyItem.duration)) : 0;

      // 检查是否已存在该记录 | Check if the record already exists
      const existingItem = await this.historyDao.getById(historyItem.id);
      
      if (existingItem) {
        // 更新现有记录 | Update existing record
        await this.historyDao.update({
          ...existingItem,
          ...historyItem,
          lastPlayed: historyItem.lastPlayed,
          position: historyItem.position,
          duration: historyItem.duration,
          progress: historyItem.progress
        });
        Logger.debug(TAG, `Updated history: ${historyItem.title}`);
      } else {
        // 插入新记录 | Insert new record
        await this.historyDao.insert(historyItem);
        Logger.debug(TAG, `Added history: ${historyItem.title}`);
      }

      // 检查并清理超出限制的历史记录 | Check and cleanup excess history records
      await this.cleanupExcessHistory();
    } catch (error) {
      Logger.error(TAG, `Failed to save history: ${error}`);
      throw error;
    }
  }

  /**
   * 获取历史记录列表 | Get history record list
   * @param limit 限制数量 | Limit count
   * @param offset 偏移量 | Offset
   */
  public async getHistoryList(limit: number = 50, offset: number = 0): Promise<HistoryItem[]> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      const historyList = await this.historyDao.query({
        orderBy: 'lastPlayed DESC',
        limit,
        offset
      });
      return historyList;
    } catch (error) {
      Logger.error(TAG, `Failed to get history list: ${error}`);
      return [];
    }
  }

  /**
   * 根据ID获取历史记录 | Get history record by ID
   * @param id 历史记录ID | History record ID
   */
  public async getHistoryById(id: string): Promise<HistoryItem | null> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      return await this.historyDao.getById(id);
    } catch (error) {
      Logger.error(TAG, `Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}` instanceof Error ? `Failed to get history by id: ${error}` : new Error(String(`Failed to get history by id: ${error}`)))))));
      return null;
    }
  }

  /**
   * 根据站点和视频ID获取历史记录 | Get history record by site and video ID
   * @param siteKey 站点标识 | Site identifier
   * @param videoId 视频ID | Video ID
   */
  public async getHistoryByVideo(siteKey: string, videoId: string): Promise<HistoryItem | null> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      return await this.historyDao.queryOne({
        conditions: `siteKey = ? AND videoId = ?`,
        params: [siteKey, videoId]
      });
    } catch (error) {
      Logger.error(TAG, `Failed to get history by video: ${error}`);
      return null;
    }
  }

  /**
   * 删除历史记录 | Delete history record
   * @param id 历史记录ID | History record ID
   */
  public async deleteHistory(id: string): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      await this.historyDao.delete(id);
      Logger.debug(TAG, `Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` : new Error(String(`Deleted history: ${id}` instanceof Error ? `Deleted history: ${id}` : new Error(String(`Deleted history: ${id}`)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to delete history: ${error}`);
      throw error;
    }
  }

  /**
   * 清空所有历史记录 | Clear all history records
   */
  public async clearAllHistory(): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      await this.historyDao.clear();
      Logger.info(TAG, 'Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records' instanceof Error ? 'Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records' : new Error(String('Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records' instanceof Error ? 'Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records' instanceof Error ? 'Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records' : new Error(String('Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records' : new Error(String('Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records' instanceof Error ? 'Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records' : new Error(String('Cleared all history records' instanceof Error ? 'Cleared all history records' : new Error(String('Cleared all history records')))))));
    } catch (error) {
      Logger.error(TAG, `Failed to clear history: ${error}`);
      throw error;
    }
  }

  /**
   * 清理超出限制的历史记录 | Cleanup excess history records
   */
  private async cleanupExcessHistory(): Promise<void> {
    try {
      const count = await this.historyDao.count();
      if (count > this.maxHistoryCount) {
        const excessCount = count - this.maxHistoryCount;
        await this.historyDao.deleteOldest(excessCount);
        Logger.info(TAG, `Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records` instanceof Error ? `Cleaned up ${excessCount} excess history records` : new Error(String(`Cleaned up ${excessCount} excess history records`)))))));
      }
    } catch (error) {
      Logger.error(TAG, `Failed to cleanup excess history: ${error}`);
    }
  }

  /**
   * 生成唯一ID | Generate unique ID
   */
  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }
}





