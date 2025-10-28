import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { HISTORY_TABLE } from '../TableSchema';
import { History, HistoryType, ContentType, PlaybackStatus } from '../../bean/History';
import Logger from '../../../common/util/Logger';
import JsonUtil from '../../../common/util/JsonUtil';

const TAG = 'HistoryDao';

export class HistoryDao {
  private db: relationalStore.RdbStore;
  
  constructor() {
    this.db = DatabaseManager.getInstance().getDatabase();
  }
  
  // 插入或更新历史记录
  public async saveOrUpdate(history: History): Promise<void> {
    try {
      // 检查是否已存在
      const existing = await this.getByContentId(history.contentId, history.sourceKey);
      
      const valuesBucket: relationalStore.ValuesBucket = {
        [HISTORY_TABLE.COLUMNS.CONTENT_ID]: history.contentId,
        [HISTORY_TABLE.COLUMNS.CONTENT_NAME]: history.contentName,
        [HISTORY_TABLE.COLUMNS.TYPE]: history.type,
        [HISTORY_TABLE.COLUMNS.CONTENT_TYPE]: history.contentType,
        [HISTORY_TABLE.COLUMNS.COVER]: history.cover || null,
        [HISTORY_TABLE.COLUMNS.BACKDROP]: history.backdrop || null,
        [HISTORY_TABLE.COLUMNS.EPISODE_NAME]: history.episodeName || null,
        [HISTORY_TABLE.COLUMNS.SEASON_NAME]: history.seasonName || null,
        [HISTORY_TABLE.COLUMNS.EPISODE_INDEX]: history.episodeIndex || 0,
        [HISTORY_TABLE.COLUMNS.SOURCE_KEY]: history.sourceKey,
        [HISTORY_TABLE.COLUMNS.SOURCE_NAME]: history.sourceName || null,
        [HISTORY_TABLE.COLUMNS.POSITION]: history.position,
        [HISTORY_TABLE.COLUMNS.DURATION]: history.duration,
        [HISTORY_TABLE.COLUMNS.PROGRESS]: history.progress,
        [HISTORY_TABLE.COLUMNS.PLAYBACK_STATUS]: history.playbackStatus,
        [HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT]: history.lastPlayedAt,
        [HISTORY_TABLE.COLUMNS.CREATED_AT]: history.createdAt,
        [HISTORY_TABLE.COLUMNS.UPDATED_AT]: history.updatedAt,
        [HISTORY_TABLE.COLUMNS.USER_ID]: history.userId || null,
        [HISTORY_TABLE.COLUMNS.DEVICE_ID]: history.deviceId || null,
        [HISTORY_TABLE.COLUMNS.NETWORK_STATUS]: history.networkStatus || null,
        [HISTORY_TABLE.COLUMNS.RESOLUTION]: history.resolution || null,
        [HISTORY_TABLE.COLUMNS.BITRATE]: history.bitrate || 0,
        [HISTORY_TABLE.COLUMNS.BUFFERED_DURATION]: history.bufferedDuration || 0,
        [HISTORY_TABLE.COLUMNS.AUDIO_TRACK]: history.audioTrack || null,
        [HISTORY_TABLE.COLUMNS.SUBTITLE_TRACK]: history.subtitleTrack || null,
        [HISTORY_TABLE.COLUMNS.LANGUAGE]: history.language || null,
        [HISTORY_TABLE.COLUMNS.COUNTRY]: history.country || null,
        [HISTORY_TABLE.COLUMNS.GENRE]: history.genre || null,
        [HISTORY_TABLE.COLUMNS.RATING]: history.rating || 0,
        [HISTORY_TABLE.COLUMNS.ACTORS]: history.actors ? JsonUtil.stringify(history.actors) : null,
        [HISTORY_TABLE.COLUMNS.DIRECTOR]: history.director || null,
        [HISTORY_TABLE.COLUMNS.YEAR]: history.year || null,
        [HISTORY_TABLE.COLUMNS.EPISODE_COUNT]: history.episodeCount || 0,
        [HISTORY_TABLE.COLUMNS.SEASON_COUNT]: history.seasonCount || 0,
        [HISTORY_TABLE.COLUMNS.IS_FINISHED]: history.isFinished ? 1 : 0,
        [HISTORY_TABLE.COLUMNS.IS_FAVORITE]: history.isFavorite ? 1 : 0,
        [HISTORY_TABLE.COLUMNS.IS_ADULT]: history.isAdult ? 1 : 0,
        [HISTORY_TABLE.COLUMNS.TAGS]: history.tags ? JsonUtil.stringify(history.tags) : null,
        [HISTORY_TABLE.COLUMNS.CUSTOM_DATA]: history.customData ? JsonUtil.stringify(history.customData) : null,
        [HISTORY_TABLE.COLUMNS.WATCH_HISTORY]: history.watchHistory ? JsonUtil.stringify(history.watchHistory) : null,
        [HISTORY_TABLE.COLUMNS.TIME_WATCHED]: history.timeWatched || 0,
        [HISTORY_TABLE.COLUMNS.REWIND_COUNT]: history.rewindCount || 0,
        [HISTORY_TABLE.COLUMNS.FORWARD_COUNT]: history.forwardCount || 0,
        [HISTORY_TABLE.COLUMNS.PLAY_COUNT]: history.playCount || 0,
        [HISTORY_TABLE.COLUMNS.ERROR_COUNT]: history.errorCount || 0,
        [HISTORY_TABLE.COLUMNS.LAST_ERROR]: history.lastError || null,
        [HISTORY_TABLE.COLUMNS.NOTES]: history.notes || null,
        [HISTORY_TABLE.COLUMNS.RECOMMENDATIONS]: history.recommendations ? JsonUtil.stringify(history.recommendations) : null
      };
      
      if (existing) {
        // 更新
        valuesBucket[HISTORY_TABLE.COLUMNS.ID] = existing.id;
        const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
        predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, existing.id);
        await this.db.update(valuesBucket, predicates);
      } else {
        // 插入
        valuesBucket[HISTORY_TABLE.COLUMNS.ID] = history.id;
        await this.db.insert(HISTORY_TABLE.NAME, valuesBucket);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save or update history: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 获取历史记录列表
  public async getAll(page: number = 1, pageSize: number = 50): Promise<History[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.orderByDesc(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT);
      predicates.limit(pageSize);
      predicates.offset((page - 1) * pageSize);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get all history: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据内容ID和来源获取历史记录
  public async getByContentId(contentId: string, sourceKey: string): Promise<History | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.CONTENT_ID, contentId);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
      
      const resultSet = await this.db.query(predicates);
      const histories = this.parseResultSet(resultSet);
      return histories.length > 0 ? histories[0] : null;
    } catch (error) {
      Logger.error(TAG, `Failed to get history by contentId: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据类型获取历史记录
  public async getByType(type: HistoryType, page: number = 1, pageSize: number = 50): Promise<History[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.TYPE, type);
      predicates.orderByDesc(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT);
      predicates.limit(pageSize);
      predicates.offset((page - 1) * pageSize);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get history by type: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据来源获取历史记录
  public async getBySource(sourceKey: string, page: number = 1, pageSize: number = 50): Promise<History[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
      predicates.orderByDesc(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT);
      predicates.limit(pageSize);
      predicates.offset((page - 1) * pageSize);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get history by source: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据时间范围获取历史记录
  public async getByTimeRange(startTime: number, endTime: number, page: number = 1, pageSize: number = 50): Promise<History[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.greaterThanOrEqualTo(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT, startTime);
      predicates.lessThanOrEqualTo(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT, endTime);
      predicates.orderByDesc(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT);
      predicates.limit(pageSize);
      predicates.offset((page - 1) * pageSize);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get history by time range: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 删除历史记录
  public async delete(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, id);
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to delete history: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据内容ID删除历史记录
  public async deleteByContentId(contentId: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.CONTENT_ID, contentId);
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to delete history by contentId: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 根据来源删除历史记录
  public async deleteBySource(sourceKey: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.SOURCE_KEY, sourceKey);
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to delete history by source: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 删除旧的历史记录
  public async deleteOldHistory(beforeTime: number): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.lessThan(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT, beforeTime);
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to delete old history: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 清空所有历史记录
  public async clearAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      await this.db.delete(predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to clear all history: ${JSON.stringify(error)}`);
      throw error;
    }
  }
  
  // 获取历史记录总数
  public async getTotalCount(): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      const resultSet = await this.db.query(predicates);
      const count = resultSet.rowCount;
      resultSet.close();
      return count;
    } catch (error) {
      Logger.error(TAG, `Failed to get total count: ${JSON.stringify(error)}`);
      return 0;
    }
  }
  
  // 更新观看进度
  public async updateProgress(id: string, position: number, duration: number, progress: number): Promise<void> {
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        [HISTORY_TABLE.COLUMNS.POSITION]: position,
        [HISTORY_TABLE.COLUMNS.DURATION]: duration,
        [HISTORY_TABLE.COLUMNS.PROGRESS]: progress,
        [HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT]: Date.now(),
        [HISTORY_TABLE.COLUMNS.UPDATED_AT]: Date.now()
      };
      
      const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE.NAME);
      predicates.equalTo(HISTORY_TABLE.COLUMNS.ID, id);
      await this.db.update(valuesBucket, predicates);
    } catch (error) {
      Logger.error(TAG, `Failed to update progress: ${JSON.stringify(error)}`);
    }
  }
  
  // 解析结果集
  private parseResultSet(resultSet: relationalStore.ResultSet): History[] {
    const histories: History[] = [];
    
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      do {
        const actorsStr = resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.ACTORS));
        const actors = actorsStr ? JsonUtil.parse(actorsStr) : undefined;
        
        const tagsStr = resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.TAGS));
        const tags = tagsStr ? JsonUtil.parse(tagsStr) : undefined;
        
        const customDataStr = resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CUSTOM_DATA));
        const customData = customDataStr ? JsonUtil.parse(customDataStr) : undefined;
        
        const watchHistoryStr = resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.WATCH_HISTORY));
        const watchHistory = watchHistoryStr ? JsonUtil.parse(watchHistoryStr) : undefined;
        
        const recommendationsStr = resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.RECOMMENDATIONS));
        const recommendations = recommendationsStr ? JsonUtil.parse(recommendationsStr) : undefined;
        
        histories.push({
          id: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.ID)),
          contentId: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CONTENT_ID)),
          contentName: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CONTENT_NAME)),
          type: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.TYPE)) as HistoryType,
          contentType: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CONTENT_TYPE)) as ContentType,
          cover: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.COVER)),
          backdrop: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.BACKDROP)),
          episodeName: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.EPISODE_NAME)),
          seasonName: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.SEASON_NAME)),
          episodeIndex: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.EPISODE_INDEX)),
          sourceKey: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.SOURCE_KEY)),
          sourceName: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.SOURCE_NAME)),
          position: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.POSITION)),
          duration: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.DURATION)),
          progress: resultSet.getDouble(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.PROGRESS)),
          playbackStatus: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.PLAYBACK_STATUS)) as PlaybackStatus,
          lastPlayedAt: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.LAST_PLAYED_AT)),
          createdAt: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.CREATED_AT)),
          updatedAt: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.UPDATED_AT)),
          userId: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.USER_ID)),
          deviceId: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.DEVICE_ID)),
          networkStatus: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.NETWORK_STATUS)),
          resolution: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.RESOLUTION)),
          bitrate: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.BITRATE)),
          bufferedDuration: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.BUFFERED_DURATION)),
          audioTrack: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.AUDIO_TRACK)),
          subtitleTrack: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.SUBTITLE_TRACK)),
          language: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.LANGUAGE)),
          country: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.COUNTRY)),
          genre: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.GENRE)),
          rating: resultSet.getDouble(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.RATING)),
          actors,
          director: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.DIRECTOR)),
          year: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.YEAR)),
          episodeCount: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.EPISODE_COUNT)),
          seasonCount: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.SEASON_COUNT)),
          isFinished: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.IS_FINISHED)) === 1,
          isFavorite: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.IS_FAVORITE)) === 1,
          isAdult: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.IS_ADULT)) === 1,
          tags,
          customData,
          watchHistory,
          timeWatched: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.TIME_WATCHED)),
          rewindCount: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.REWIND_COUNT)),
          forwardCount: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.FORWARD_COUNT)),
          playCount: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.PLAY_COUNT)),
          errorCount: resultSet.getLong(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.ERROR_COUNT)),
          lastError: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.LAST_ERROR)),
          notes: resultSet.getString(resultSet.getColumnIndex(HISTORY_TABLE.COLUMNS.NOTES)),
          recommendations
        });
      } while (resultSet.goToNextRow());
    }
    
    resultSet.close();
    return histories;
  }
}