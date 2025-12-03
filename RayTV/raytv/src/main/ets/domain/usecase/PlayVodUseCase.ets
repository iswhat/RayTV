// PlayVodUseCase - 播放点播用例
import Logger from '../../common/util/Logger';
import { Vod } from '../../data/bean/Vod';
import { History } from '../../data/bean/History';
import { VideoSource } from '../../data/bean/Vod';
import { VodRepository } from '../../data/repository/VodRepository';
import { HistoryRepository } from '../../data/repository/HistoryRepository';
import { PlaybackRepository } from '../../data/repository/PlaybackRepository';
import { CollectionRepository } from '../../data/repository/CollectionRepository';

const TAG = 'PlayVodUseCase';

/**
 * 播放点播内容的业务用�?
 */
export class PlayVodUseCase {
  private vodRepository: VodRepository;
  private historyRepository: HistoryRepository;
  private playbackRepository: PlaybackRepository;
  private collectionRepository: CollectionRepository;
  
  constructor(
    vodRepository: VodRepository,
    historyRepository: HistoryRepository,
    playbackRepository: PlaybackRepository,
    collectionRepository: CollectionRepository
  ) {
    this.vodRepository = vodRepository;
    this.historyRepository = historyRepository;
    this.playbackRepository = playbackRepository;
    this.collectionRepository = collectionRepository;
  }
  
  /**
   * 加载点播内容详情
   * @param contentId 内容ID
   * @param sourceKey 数据源标�?
   * @returns 完整的Vod对象
   */
  public async loadVodDetail(contentId: string, sourceKey: string): Promise<Vod> {
    try {
      Logger.info(TAG, `Loading vod detail for: ${contentId} from ${sourceKey}`);
      
      // 先尝试从缓存获取
      let vod = await this.vodRepository.getVodById(contentId, sourceKey);
      
      // 如果缓存中没有或需要更新，从网络获�?
      if (!vod || !vod.episodeList || vod.episodeList.length === 0) {
        vod = await this.vodRepository.fetchVodDetail(contentId, sourceKey);
        // 更新缓存
        await this.vodRepository.cacheVods([vod]);
      }
      
      // 检查是否已收藏
      vod.isCollected = await this.collectionRepository.isCollected(contentId, sourceKey);
      
      return vod;
    } catch (error) {
      Logger.error(TAG, `Failed to load vod detail: ${error}`);
      throw error;
    }
  }
  
  /**
   * 准备播放
   * @param vod 点播内容
   * @param episodeIndex 剧集索引
   * @param sourceIndex 视频源索�?
   * @returns 包含播放信息的对�?
   */
  public async preparePlayback(
    vod: Vod, episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
   instanceof Error ? episodeIndex: number,
    sourceIndex: number = 0
   : new Error(String(episodeIndex: number,
    sourceIndex: number = 0
  ))))))): Promise<{
    videoSource: VideoSource;
    startPosition: number;
    isNewView: boolean;
  }> {
    try {
      Logger.info(TAG, `Preparing playback for ${vod.name}, episode ${episodeIndex}`);
      
      // 验证参数
      if (!vod.episodeList || !vod.episodeList[episodeIndex]) {
        throw new Error('无效的剧集索�?);
      }
      
      const episode = vod.episodeList[episodeIndex];
      if (!episode.sourceList || !episode.sourceList[sourceIndex]) {
        throw new Error('无效的视频源索引');
      }
      
      // 获取视频�?
      const videoSource = episode.sourceList[sourceIndex];
      
      // 检查是否有观看历史
      const historyKey = `${vod.id}_${episodeIndex}`;
      const history = await this.historyRepository.getHistory(historyKey, vod.sourceKey);
      
      // 如果是剧集，创建或更新观看记�?
      const isNewView = !history || history.position === 0;
      const startPosition = history?.position || 0;
      
      // 更新视频源信息（如果需要）
      if (!videoSource.url || videoSource.url.startsWith('http://placeholder')) {
        const realUrl = await this.playbackRepository.resolveVideoUrl(videoSource.url);
        videoSource.url = realUrl;
      }
      
      Logger.info(TAG, `Playback prepared, start at ${startPosition}ms, isNewView: ${isNewView}`);
      
      return {
        videoSource,
        startPosition,
        isNewView
      };
    } catch (error) {
      Logger.error(TAG, `Failed to prepare playback: ${error}`);
      throw error;
    }
  }
  
  /**
   * 保存播放进度
   * @param vod 点播内容
   * @param episodeIndex 剧集索引
   * @param position 当前播放位置（毫秒）
   * @param duration 总时长（毫秒�?
   */
  public async savePlaybackProgress(
    vod: Vod, episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
   instanceof Error ? episodeIndex: number,
    position: number,
    duration: number
   : new Error(String(episodeIndex: number,
    position: number,
    duration: number
  ))))))): Promise<void> {
    try {
      // 构建历史记录对象
      const history: History = {
        id: `${vod.id}_${episodeIndex}`,
        contentId: vod.id,
        contentName: vod.name,
        type: 'vod',
        cover: vod.cover,
        episodeName: vod.episodeList?.[episodeIndex]?.name,
        sourceKey: vod.sourceKey,
        position,
        duration,
        lastPlayedAt: Date.now(),
        createdAt: Date.now()
      };
      
      // 保存历史记录
      await this.historyRepository.saveHistory(history);
      
      Logger.info(TAG, `Saved playback progress for ${vod.name}, position: ${position}ms`);
    } catch (error) {
      Logger.error(TAG, `Failed to save playback progress: ${error}`);
    }
  }
  
  /**
   * 切换视频�?
   * @param vod 点播内容
   * @param episodeIndex 剧集索引
   * @param newSourceIndex 新的视频源索�?
   * @returns 新的视频�?
   */
  public async switchVideoSource(
    vod: Vod, episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
   instanceof Error ? episodeIndex: number,
    newSourceIndex: number
   : new Error(String(episodeIndex: number,
    newSourceIndex: number
  ))))))): Promise<VideoSource> {
    try {
      Logger.info(TAG, `Switching video source to index ${newSourceIndex}`);
      
      if (!vod.episodeList || !vod.episodeList[episodeIndex]) {
        throw new Error('无效的剧�?);
      }
      
      const episode = vod.episodeList[episodeIndex];
      if (!episode.sourceList || !episode.sourceList[newSourceIndex]) {
        throw new Error('无效的视频源索引');
      }
      
      const videoSource = episode.sourceList[newSourceIndex];
      
      // 解析视频源URL（如果需要）
      if (!videoSource.url || videoSource.url.startsWith('http://placeholder')) {
        const realUrl = await this.playbackRepository.resolveVideoUrl(videoSource.url);
        videoSource.url = realUrl;
      }
      
      return videoSource;
    } catch (error) {
      Logger.error(TAG, `Failed to switch video source: ${error}`);
      throw error;
    }
  }
  
  /**
   * 收藏/取消收藏
   * @param vod 点播内容
   * @returns 收藏状�?
   */
  public async toggleCollection(vod: Vod): Promise<boolean> {
    try {
      const isCurrentlyCollected = await this.collectionRepository.isCollected(vod.id, vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey instanceof Error ? vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey : new Error(String(vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey instanceof Error ? vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey instanceof Error ? vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey : new Error(String(vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey : new Error(String(vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey instanceof Error ? vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey : new Error(String(vod.sourceKey instanceof Error ? vod.sourceKey : new Error(String(vod.sourceKey)))))));
      
      if (isCurrentlyCollected) {
        await this.collectionRepository.removeCollection(vod.id, vod.sourceKey);
        Logger.info(TAG, `Uncollected ${vod.name}`);
        return false;
      } else {
        await this.collectionRepository.addCollection({
          id: vod.id,
          name: vod.name,
          type: 'vod',
          cover: vod.cover,
          sourceKey: vod.sourceKey,
          addedAt: Date.now()
        });
        Logger.info(TAG, `Collected ${vod.name}`);
        return true;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to toggle collection: ${error}`);
      throw error;
    }
  }
}


