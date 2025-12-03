import Logger from '../../common/util/Logger';
import { DatabaseManager } from '../../data/db/DatabaseManager';
import { MediaType } from './MediaService';
import { MediaItem } from '../../data/bean/MediaItem';
import { TypeSafetyUtil } from '../../common/util/TypeSafetyUtil';

/**
 * 历史记录项接�? */
/**
 * 历史记录附加信息接口
 */
export interface HistoryExtraData {
  [key: string]: string | number | boolean | undefined;
}

/**
 * 播放源信息接�? */
export interface PlaySource {
  sourceId: string;     // 播放源ID
  sourceName: string;   // 播放源名�?  url?: string;         // 播放URL
  quality?: string;     // 视频质量
  format?: string;      // 视频格式
}

/**
 * 历史记录项接�? */
export interface HistoryItem {
  id: string;           // 历史记录ID
  mediaId: string;      // 媒体ID
  siteKey: string;      // 站点标识
  title: string;        // 标题
  cover?: string;       // 封面�?  type: MediaType;      // 媒体类型
  episodeId?: string;   // 剧集ID
  episodeTitle?: string; // 剧集标题
  progress: number;     // 播放进度（秒�?  duration?: number;    // 总时长（秒）
  lastPlayTime: number; // 最后播放时�?  playCount: number;    // 播放次数
  playSource?: PlaySource; // 播放源信�?  extra?: HistoryExtraData; // 其他附加信息
}

/**
 * 历史记录服务
 * 实现播放历史的记录、查询、更新和删除功能
 */
export class HistoryService {
  private readonly TAG: string = 'HistoryService';
  private static instance: HistoryService | null = null;
  private dbManager: DatabaseManager;
  private historyTable: string = 'media_history';

  /**
   * 获取单例实例
   * @returns HistoryService
   */
  public static getInstance(): HistoryService {
    if (!HistoryService.instance) {
      HistoryService.instance = new HistoryService();
    }
    return HistoryService.instance;
  }

  /**
   * 构造函�?   * 私有构造函数防止外部实例化
   */
  private constructor() {
    this.dbManager = DatabaseManager.getInstance();
    this.initialize();
    Logger.info(this.TAG, 'HistoryService initialized');
  }

  /**
   * 初始化历史记录服�?   */
  public async initialize(): Promise<void> {
    try {
      // 创建历史记录�?      await this.dbManager.executeSql(`
        CREATE TABLE IF NOT EXISTS ${this.historyTable} (
          id TEXT PRIMARY KEY,
          mediaId TEXT NOT NULL,
          siteKey TEXT NOT NULL,
          title TEXT NOT NULL,
          cover TEXT,
          type TEXT NOT NULL,
          episodeId TEXT,
          episodeTitle TEXT,
          progress INTEGER DEFAULT 0,
          duration INTEGER DEFAULT 0,
          lastPlayTime INTEGER NOT NULL,
          playCount INTEGER DEFAULT 1,
          playSource TEXT,
          extra TEXT,
          UNIQUE(mediaId, siteKey, episodeId)
        );
      `);

      // 创建索引
      await this.dbManager.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_history_last_play_time 
        ON ${this.historyTable} (lastPlayTime DESC);
      `);
      
      await this.dbManager.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_history_media_site 
        ON ${this.historyTable} (mediaId, siteKey);
      `);

      Logger.info(this.TAG, 'History table initialized');
    } catch (error) {
      Logger.error(this.TAG, 'Failed to initialize history table', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
    }
  }

  /**
   * 添加或更新历史记�?   * @param media 媒体信息
   * @param progress 播放进度（秒�?   * @param duration 总时长（秒）
   * @param episodeId 剧集ID（可选）
   * @param episodeTitle 剧集标题（可选）
   * @param playSource 播放源（可选）
   * @returns Promise<HistoryItem>
   */
  public async addHistory(
    media: Pick<MediaItem, 'id' | 'siteKey' | 'title' | 'cover' | 'type'>,
    progress: number,
    duration: number,
    episodeId?: string,
    episodeTitle?: string,
    playSource?: PlaySource
  ): Promise<HistoryItem> {
    try {
      const now = Date.now();
      const historyId = this.generateHistoryId(media.id, media.siteKey, episodeId);
      const progressValue = Math.max(0, Math.min(progress, duration));

      // 构建历史记录�?      const historyItem: HistoryItem = {
        id: historyId,
        mediaId: media.id,
        siteKey: media.siteKey,
        title: media.title,
        cover: media.cover,
        type: media.type,
        episodeId,
        episodeTitle,
        progress: progressValue,
        duration,
        lastPlayTime: now,
        playCount: 1,
        playSource,
        extra: {} as HistoryExtraData
      };

      // 检查是否已存在
      const existing = await this.getHistoryById(historyId);
      
      const db = this.dbManager.getDatabase();
      
      if (existing) {
        // 更新现有记录
        historyItem.playCount = existing.playCount + 1;
        
        await this.dbManager.executeSql(
          `UPDATE ${this.historyTable} 
           SET title = ?, cover = ?, type = ?, episodeTitle = ?, 
               progress = ?, duration = ?, lastPlayTime = ?, 
               playCount = ?, playSource = ?, extra = ? 
           WHERE id = ?`,
          [
            historyItem.title,
            historyItem.cover || '',
            historyItem.type,
            historyItem.episodeTitle || '',
            historyItem.progress,
            historyItem.duration,
            historyItem.lastPlayTime,
            historyItem.playCount,
            playSource ? JSON.stringify(playSource) : '',
            JSON.stringify(historyItem.extra),
            historyItem.id
          ]
        );
      } else {
        // 插入新记�?        await this.dbManager.executeSql(
          `INSERT INTO ${this.historyTable} 
           (id, mediaId, siteKey, title, cover, type, episodeId, episodeTitle, 
            progress, duration, lastPlayTime, playCount, playSource, extra) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            historyItem.id,
            historyItem.mediaId,
            historyItem.siteKey,
            historyItem.title,
            historyItem.cover || '',
            historyItem.type,
            historyItem.episodeId || '',
            historyItem.episodeTitle || '',
            historyItem.progress,
            historyItem.duration,
            historyItem.lastPlayTime,
            historyItem.playCount,
            playSource ? JSON.stringify(playSource) : '',
            JSON.stringify(historyItem.extra)
          ]
        );
      }

      Logger.info(this.TAG, `Added/updated history: ${media.siteKey}:${media.id}${episodeId ? `:${episodeId}` : ''}`);
      return historyItem;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to add history', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      throw new Error(`Failed to add history: ${error}`);
    }
  }

  /**
   * 更新播放进度
   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @param progress 播放进度（秒�?   * @param episodeId 剧集ID（可选）
   * @returns Promise<boolean>
   */
  public async updateProgress(
    mediaId: string,
    siteKey: string,
    progress: number,
    episodeId?: string
  ): Promise<boolean> {
    try {
      const historyId = this.generateHistoryId(mediaId, siteKey, episodeId);
      const now = Date.now();

      // 先检查记录是否存�?      const exists = await this.getHistoryById(historyId);
      if (!exists) {
        return false;
      }

      await this.dbManager.executeSql(
        `UPDATE ${this.historyTable} 
         SET progress = ?, lastPlayTime = ? 
         WHERE id = ?`,
        [progress, now, historyId]
      );

      Logger.info(this.TAG, `Updated progress for ${siteKey}:${mediaId}${episodeId ? `:${episodeId}` : ''}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to update progress', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return false;
    }
  }

  /**
   * 获取历史记录列表
   * @param params 查询参数
   * @returns Promise<HistoryItem[]>
   */
  public async getHistoryList(params: {
    type?: MediaType;
    page?: number;
    pageSize?: number;
    limit?: number;
  } = {}): Promise<HistoryItem[]> {
    try {
      const type = params.type;
      const page = params.page ?? 1;
      const pageSize = params.pageSize ?? 20;
      const limit = params.limit;
      const offset = (page - 1) * pageSize;
      const limitValue = limit || pageSize;

      // 构建查询条件
      let whereClause = '';
      const whereParams: Record<string, string | number | boolean | null>[] = [];
      
      if (type) {
        whereClause = 'WHERE type = ?';
        whereParams.push(type);
      }

      // 执行查询
      const result = await this.dbManager.getDatabase().querySql(
        `SELECT * FROM ${this.historyTable} 
         ${whereClause} 
         ORDER BY lastPlayTime DESC 
         LIMIT ? OFFSET ?`,
        [...whereParams, limitValue, offset]
      );

      // 解析结果
      const historyItems: HistoryItem[] = [];
      
      if (result !== null) {
        while (result.goToNextRow()) {
          const item: Record<string, any> = {};
          for (let i = 0; i < result.rowCount; i++) {
            const columnName = result.getColumnName(i);
            const value = result.getLong(i) ?? result.getString(i);
            item[columnName] = value;
          }
          historyItems.push(this.parseHistoryRow(item));
        }
        result.close();
      }
      
      return historyItems;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get history list', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return [];
    }
  }

  /**
   * 根据ID获取历史记录
   * @param historyId 历史记录ID
   * @returns Promise<HistoryItem | null>
   */
  public async getHistoryById(historyId: string): Promise<HistoryItem | null> {
    try {
      const result = await this.dbManager.getDatabase().querySql(
        `SELECT * FROM ${this.historyTable} WHERE id = ?`,
        [historyId]
      );

      if (result !== null) {
        if (result.goToFirstRow()) {
          const item: Record<string, any> = {};
          for (let i = 0; i < result.columnCount; i++) {
            const columnName = result.getColumnName(i);
            const value = result.getLong(i) ?? result.getString(i);
            item[columnName] = value;
          }
          result.close();
          return this.parseHistoryRow(item);
        }
        result.close();
      }
      return null;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get history by id', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return null;
    }
  }

  /**
   * 获取媒体的历史记�?   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @returns Promise<HistoryItem | null>
   */
  public async getMediaHistory(mediaId: string, siteKey: string): Promise<HistoryItem | null> {
    try {
      const result = await this.dbManager.getDatabase().querySql(
        `SELECT * FROM ${this.historyTable} 
         WHERE mediaId = ? AND siteKey = ? AND episodeId IS NULL 
         ORDER BY lastPlayTime DESC LIMIT 1`,
        [mediaId, siteKey]
      );

      if (result !== null) {
        if (result.goToFirstRow()) {
          const item: Record<string, any> = {};
          for (let i = 0; i < result.columnCount; i++) {
            const columnName = result.getColumnName(i);
            const value = result.getLong(i) ?? result.getString(i);
            item[columnName] = value;
          }
          result.close();
          return this.parseHistoryRow(item);
        }
        result.close();
      }
      return null;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get media history', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return null;
    }
  }

  /**
   * 获取媒体剧集的历史记�?   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @param episodeId 剧集ID
   * @returns Promise<HistoryItem | null>
   */
  public async getEpisodeHistory(
    mediaId: string,
    siteKey: string,
    episodeId: string
  ): Promise<HistoryItem | null> {
    try {
      const result = await this.dbManager.getDatabase().querySql(
        `SELECT * FROM ${this.historyTable} 
         WHERE mediaId = ? AND siteKey = ? AND episodeId = ?`,
        [mediaId, siteKey, episodeId]
      );

      if (result !== null) {
        if (result.goToFirstRow()) {
          const item: Record<string, any> = {};
          for (let i = 0; i < result.columnCount; i++) {
            const columnName = result.getColumnName(i);
            const value = result.getLong(i) ?? result.getString(i);
            item[columnName] = value;
          }
          result.close();
          return this.parseHistoryRow(item);
        }
        result.close();
      }
      return null;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get episode history', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return null;
    }
  }

  /**
   * 删除历史记录
   * @param historyId 历史记录ID
   * @returns Promise<boolean>
   */
  public async deleteHistory(historyId: string): Promise<boolean> {
    try {
      const db = this.dbManager.getDatabase();
      const result = await db.executeSql(
        `DELETE FROM ${this.historyTable} WHERE id = ?`,
        [historyId]
      );

      const success = result.affectedRows > 0;
      if (success) {
        Logger.info(this.TAG, `Deleted history: ${historyId}`);
      }
      return success;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to delete history', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return false;
    }
  }

  /**
   * 删除媒体的所有历史记�?   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @returns Promise<boolean>
   */
  public async deleteMediaHistory(mediaId: string, siteKey: string): Promise<boolean> {
    try {
      const db = this.dbManager.getDatabase();
      const result = await db.executeSql(
        `DELETE FROM ${this.historyTable} WHERE mediaId = ? AND siteKey = ?`,
        [mediaId, siteKey]
      );

      const success = result.affectedRows > 0;
      if (success) {
        Logger.info(this.TAG, `Deleted all history for media: ${siteKey}:${mediaId}`);
      }
      return success;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to delete media history', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return false;
    }
  }

  /**
   * 清空所有历史记�?   * @returns Promise<boolean>
   */
  public async clearAllHistory(): Promise<boolean> {
    try {
      const db = this.dbManager.getDatabase();
      await db.executeSql(`DELETE FROM ${this.historyTable}`);
      Logger.info(this.TAG, 'Cleared all history');
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to clear all history', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return false;
    }
  }

  /**
   * 清空指定类型的历史记�?   * @param type 媒体类型
   * @returns Promise<boolean>
   */
  public async clearHistoryByType(type: MediaType): Promise<boolean> {
    try {
      const db = this.dbManager.getDatabase();
      await db.executeSql(
        `DELETE FROM ${this.historyTable} WHERE type = ?`,
        [type]
      );
      Logger.info(this.TAG, `Cleared history for type: ${type}`);
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to clear history by type', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return false;
    }
  }

  /**
   * 获取历史记录数量
   * @param type 媒体类型（可选）
   * @returns Promise<number>
   */
  public async getHistoryCount(type?: MediaType): Promise<number> {
    try {
      let query = `SELECT COUNT(*) as count FROM ${this.historyTable}`;
      const params: Record<string, string | number | boolean | null>[] = [];

      if (type) {
        query += ' WHERE type = ?';
        params.push(type);
      }

      // 使用querySql方法查询而不是executeSql
      const result = await this.dbManager.getDatabase().querySql(query, params);
      let count = 0;
      
      if (result !== null) {
        if (result.goToFirstRow()) {
          count = result.getLong(0) || 0;
        }
        result.close();
      }
      
      return count;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get history count', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return 0;
    }
  }

  /**
   * 检查是否存在历史记�?   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @param episodeId 剧集ID（可选）
   * @returns Promise<boolean>
   */
  public async hasHistory(
    mediaId: string,
    siteKey: string,
    episodeId?: string
  ): Promise<boolean> {
    try {
      let sql = `SELECT COUNT(*) as count FROM ${this.historyTable} WHERE mediaId = ? AND siteKey = ?`;
      const params: string[] = [mediaId, siteKey];

      if (episodeId !== undefined) {
        sql += episodeId === null ? ' AND episodeId IS NULL' : ' AND episodeId = ?';
        if (episodeId !== null) {
          params.push(episodeId);
        }
      } else {
        sql += ' AND episodeId IS NULL';
      }

      const db = this.dbManager.getDatabase();
      const result = await db.querySql(sql, params);
      let count = 0;
      if (result !== null) {
        if (result.goToFirstRow()) {
          count = result.getLong(0);
        }
        result.close();
      }
      return count > 0;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to check history existence', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return false;
    }
  }

  /**
   * 生成历史记录ID
   * @param mediaId 媒体ID
   * @param siteKey 站点标识
   * @param episodeId 剧集ID（可选）
   * @returns string
   * @private
   */
  private generateHistoryId(mediaId: string, siteKey: string, episodeId?: string): string {
    return episodeId 
      ? `${siteKey}:${mediaId}:${episodeId}`
      : `${siteKey}:${mediaId}`;
  }

  /**
   * 解析数据库行到历史记录项
   * @param row 数据库行
   * @returns HistoryItem
   * @private
   */
  private parseHistoryRow(row: Record<string, any>): HistoryItem {
    try {
      const typedRow = row as Record<keyof HistoryItem, any>;
      return {
        id: TypeSafetyUtil.asString(typedRow.id, ''),
        mediaId: TypeSafetyUtil.asString(typedRow.mediaId, ''),
        siteKey: TypeSafetyUtil.asString(typedRow.siteKey, ''),
        title: TypeSafetyUtil.asString(typedRow.title, ''),
        cover: typedRow.cover ? TypeSafetyUtil.asString(typedRow.cover) : undefined,
        type: TypeSafetyUtil.asString(typedRow.type, 'video') as MediaType,
        episodeId: typedRow.episodeId ? TypeSafetyUtil.asString(typedRow.episodeId) : undefined,
        episodeTitle: typedRow.episodeTitle ? TypeSafetyUtil.asString(typedRow.episodeTitle) : undefined,
        progress: TypeSafetyUtil.asNumber(typedRow.progress, 0),
        duration: TypeSafetyUtil.asNumber(typedRow.duration, 0),
        lastPlayTime: TypeSafetyUtil.asNumber(typedRow.lastPlayTime, Date.now()),
        playCount: TypeSafetyUtil.asNumber(typedRow.playCount, 1),
        playSource: typedRow.playSource ? this.safeParseJson<PlaySource>(typedRow.playSource) : undefined,
        extra: typedRow.extra ? this.safeParseJson<HistoryExtraData>(typedRow.extra) : {} as HistoryExtraData
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to parse history row', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      throw new Error(`Invalid history data format`);
    }
  }

  /**
   * 安全地解析JSON字符�?   * @param jsonString JSON字符�?   * @returns 解析后的对象或默认�?   */
  private safeParseJson<T>(jsonString: Record<string, string | number | boolean | null>, defaultValue?: T): T {
    try {
      if (!jsonString || typeof jsonString !== 'string') {
        return defaultValue as T;
      }
      return JSON.parse(jsonString) as T;
    } catch (error) {
      Logger.warn(this.TAG, 'Failed to parse JSON', error instanceof Error ? error : new Error(String(error)));
      return defaultValue as T;
    }
  }

  /**
   * 解析多行数据库记�?   * @param rows 数据库行数组
   * @returns HistoryItem[]
   * @private
   */
  private parseHistoryRows(rows: Record<string, any>[]): HistoryItem[] {
    return rows.map(row => this.parseHistoryRow(row));
  }

  /**
   * 清理过期的历史记�?   * @param keepDays 保留天数
   * @returns Promise<number>
   */
  public async cleanupOldHistory(keepDays: number = 30): Promise<number> {
    try {
      const cutoffTime = Date.now() - (keepDays * 24 * 60 * 60 * 1000);
      const db = this.dbManager.getDatabase();
      
      const result = await db.executeSql(
        `DELETE FROM ${this.historyTable} WHERE lastPlayTime < ?`,
        [cutoffTime]
      );
      
      const deletedCount = result.affectedRows;
      if (deletedCount > 0) {
        Logger.info(this.TAG, `Cleaned up ${deletedCount} old history records older than ${keepDays} days`);
      }
      
      return deletedCount;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to cleanup old history', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      return 0;
    }
  }
}

// 导出历史记录服务单例
export const historyService = HistoryService.getInstance();


