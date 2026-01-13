// PlayVodUseCase.ets - 播放点播用例 // Play VOD use case
import Logger from '../../common/util/Logger';
import { Vod, VideoSource } from '../../data/bean/Vod';
import { History } from '../../data/bean/History';
import { VodRepository } from '../../data/repository/VodRepository';
import { HistoryRepository } from '../../data/repository/HistoryRepository';
import { PlaybackRepository } from '../../data/repository/PlaybackRepository';
import { CollectionRepository } from '../../data/repository/CollectionRepository';

const TAG = 'PlayVodUseCase';

/**
 * 播放点播内容的业务用例 // Business use case for playing VOD content
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
   * 加载点播内容详情 // Load VOD content details
   * @param contentId 内容ID // Content ID
   * @param sourceKey 数据源标识 // Data source identifier
   * @returns 完整的Vod对象 // Complete Vod object
   */
  public async loadVodDetail(contentId: string, sourceKey: string): Promise<Vod> {
    try {
      Logger.info(TAG, `Loading vod detail for: ${contentId} from ${sourceKey}`);
      
      // 先尝试从缓存获取 // Try to get from cache first
      let vod = await this.vodRepository.getVodById(contentId, sourceKey);
      
      // 如果缓存中没有或需要更新，从网络获取 // If not in cache or needs update, fetch from network
      if (!vod || !vod.episodeList || vod.episodeList.length === 0) {
        vod = await this.vodRepository.fetchVodDetail(contentId, sourceKey);
        // 更新缓存 // Update cache
        await this.vodRepository.cacheVods([vod]);
      }
      
      // 检查是否已收藏 // Check if collected
      vod.isCollected = await this.collectionRepository.isCollected(contentId, sourceKey);
      
      return vod;
    } catch (error) {
      Logger.error(TAG, `Failed to load vod detail: ${error}`);
      throw error;
    }
  }
  
  /**
   * 准备播放 // Prepare playback
   * @param vod 点播内容 // VOD content
   * @param episodeIndex 剧集索引 // Episode index
   * @param sourceIndex 视频源索引 // Video source index
   * @returns 包含播放信息的对象 // Object containing playback information
   */
  public async preparePlayback(
    vod: Vod, 
    episodeIndex: number,
    sourceIndex: number = 0
  ): Promise<{
    videoSource: VideoSource;
    startPosition: number;
    isNewView: boolean;
  }> {
    try {
      Logger.info(TAG, `Preparing playback for ${vod.name}, episode ${episodeIndex}`);
      
      // 验证参数 // Validate parameters
      if (!vod.episodeList || !vod.episodeList[episodeIndex]) {
        throw new Error('无效的剧集索引 // Invalid episode index');
      }
      
      const episode = vod.episodeList[episodeIndex];
      if (!episode.sourceList || !episode.sourceList[sourceIndex]) {
        throw new Error('无效的视频源索引 // Invalid video source index');
      }
      
      // 获取视频源 // Get video source
      const videoSource = episode.sourceList[sourceIndex];
      
      // 检查是否有观看历史 // Check if there is viewing history
      const historyKey = `${vod.id}_${episodeIndex}`;
      const history = await this.historyRepository.getHistory(historyKey, vod.sourceKey);
      
      // 如果是剧集，创建或更新观看记录 // If it's an episode, create or update viewing record
      const isNewView = !history || history.position === 0;
      const startPosition = history?.position || 0;
      
      // 更新视频源信息（如果需要） // Update video source information (if needed)
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
   * 保存播放进度 // Save playback progress
   * @param vod 点播内容 // VOD content
   * @param episodeIndex 剧集索引 // Episode index
   * @param position 当前播放位置（毫秒） // Current playback position (milliseconds)
   * @param duration 总时长（秒） // Total duration (seconds)
   */
  public async savePlaybackProgress(
    vod: Vod, 
    episodeIndex: number,
    position: number,
    duration: number
  ): Promise<void> {
    try {
      // 构建历史记录对象 // Build history record object
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
      
      // 保存历史记录 // Save history record
      await this.historyRepository.saveHistory(history);
      
      Logger.info(TAG, `Saved playback progress for ${vod.name}, position: ${position}ms`);
    } catch (error) {
      Logger.error(TAG, `Failed to save playback progress: ${error}`);
    }
  }
  
  /**
   * 切换视频源 // Switch video source
   * @param vod 点播内容 // VOD content
   * @param episodeIndex 剧集索引 // Episode index
   * @param newSourceIndex 新的视频源索引 // New video source index
   * @returns 新的视频源 // New video source
   */
  public async switchVideoSource(
    vod: Vod, 
    episodeIndex: number,
    newSourceIndex: number
  ): Promise<VideoSource> {
    try {
      Logger.info(TAG, `Switching video source to index ${newSourceIndex}`);
      
      if (!vod.episodeList || !vod.episodeList[episodeIndex]) {
        throw new Error('无效的剧集 // Invalid episode');
      }
      
      const episode = vod.episodeList[episodeIndex];
      if (!episode.sourceList || !episode.sourceList[newSourceIndex]) {
        throw new Error('无效的视频源索引 // Invalid video source index');
      }
      
      const videoSource = episode.sourceList[newSourceIndex];
      
      // 解析视频源URL（如果需要） // Resolve video source URL (if needed)
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
   * 收藏/取消收藏 // Toggle collection
   * @param vod 点播内容 // VOD content
   * @returns 收藏状态 // Collection status
   */
  public async toggleCollection(vod: Vod): Promise<boolean> {
    try {
      const isCurrentlyCollected = await this.collectionRepository.isCollected(vod.id, vod.sourceKey);
      
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
