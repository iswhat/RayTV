// MediaService - 媒体业务逻辑服务
import Logger from '../../common/util/Logger';
import { Vod, Episode, VodCategory, VodTag } from '../../data/bean/Vod';
import { LiveChannel, LiveGroup, EpgItem } from '../../data/bean/Live';
import VodRepository from '../../data/repository/VodRepository';
import LiveRepository from '../../data/repository/LiveRepository';
import HistoryRepository from '../../data/repository/HistoryRepository';
import CollectionRepository from '../../data/repository/CollectionRepository';
import ConfigService from '../../service/config/ConfigService';
import DeviceService from '../../service/device/DeviceService';
import HttpService from '../../service/http/HttpService';

const TAG = 'MediaService';

// 媒体类型枚举
export enum MediaType {
  VOD = 'vod',
  LIVE = 'live',
  EPISODE = 'episode'
}

// 播放历史记录接口
interface PlayHistory {
  mediaId: string;
  mediaType: MediaType;
  title: string;
  coverUrl?: string;
  playTime: number;
  totalDuration: number;
  lastPlayTime: number;
  currentEpisode?: string;
  progress: number; // 0-100
}

// 搜索结果接口
export interface SearchResult {
  vodItems: Vod[];
  liveChannels: LiveChannel[];
  totalCount: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

// 推荐内容接口
export interface RecommendationResult {
  featured: Vod[];
  recentlyAdded: Vod[];
  popular: Vod[];
  continueWatching: PlayHistory[];
  related: Vod[];
}

// 播放选项接口
export interface PlayOptions {
  autoPlay?: boolean;
  startPosition?: number;
  selectedEpisode?: string;
  audioTrack?: string;
  subtitleTrack?: string;
  playbackRate?: number;
  volume?: number;
  muted?: boolean;
  quality?: string;
}

export default class MediaService {
  private static instance: MediaService;
  private vodRepository: VodRepository;
  private liveRepository: LiveRepository;
  private historyRepository: HistoryRepository;
  private collectionRepository: CollectionRepository;
  private configService: ConfigService;
  private deviceService: DeviceService;
  private httpService: HttpService;
  private currentPlayingMedia: { id: string; type: MediaType } | null = null;
  private playListeners: Array<(media: { id: string; type: MediaType }) => void> = [];

  private constructor() {
    this.vodRepository = VodRepository.getInstance();
    this.liveRepository = LiveRepository.getInstance();
    this.historyRepository = HistoryRepository.getInstance();
    this.collectionRepository = CollectionRepository.getInstance();
    this.configService = ConfigService.getInstance();
    this.deviceService = DeviceService.getInstance();
    this.httpService = HttpService.getInstance();
  }

  public static getInstance(): MediaService {
    if (!MediaService.instance) {
      MediaService.instance = new MediaService();
    }
    return MediaService.instance;
  }

  /**
   * 获取点播内容详情
   */
  public async getVodDetail(vodId: string): Promise<Vod | null> {
    try {
      const vod = await this.vodRepository.getVodById(vodId);
      if (vod) {
        // 记录访问
        await this.vodRepository.incrementVodViewCount(vodId);
        
        // 预加载相关信息
        await this.preloadVodRelatedContent(vodId);
      }
      return vod;
    } catch (error) {
      Logger.error(TAG, `Failed to get VOD detail for ID: ${vodId}`, error);
      return null;
    }
  }

  /**
   * 获取直播频道详情
   */
  public async getLiveChannelDetail(channelId: string): Promise<LiveChannel | null> {
    try {
      const channel = await this.liveRepository.getChannelById(channelId);
      if (channel) {
        // 记录访问
        await this.liveRepository.incrementChannelViewCount(channelId);
      }
      return channel;
    } catch (error) {
      Logger.error(TAG, `Failed to get live channel detail for ID: ${channelId}`, error);
      return null;
    }
  }

  /**
   * 播放点播内容
   */
  public async playVod(vodId: string, options: PlayOptions = {}): Promise<{ success: boolean; url?: string; error?: string }> {
    try {
      const vod = await this.getVodDetail(vodId);
      if (!vod) {
        return { success: false, error: 'Content not found' };
      }

      // 确定要播放的集数
      let episodeToPlay: Episode | undefined;
      if (options.selectedEpisode) {
        episodeToPlay = vod.episodes.find(ep => ep.id === options.selectedEpisode);
      } else if (options.currentEpisode) {
        episodeToPlay = vod.episodes.find(ep => ep.id === options.currentEpisode);
      } else {
        // 获取最后观看的集数或第一集
        const lastHistory = await this.historyRepository.getLastVodHistory(vodId);
        if (lastHistory && lastHistory.episodeId) {
          episodeToPlay = vod.episodes.find(ep => ep.id === lastHistory.episodeId);
        }
        if (!episodeToPlay && vod.episodes.length > 0) {
          episodeToPlay = vod.episodes[0];
        }
      }

      if (!episodeToPlay || !episodeToPlay.playUrl) {
        return { success: false, error: 'No playable episode found' };
      }

      // 更新播放状态
      this.currentPlayingMedia = { id: vodId, type: MediaType.VOD };
      
      // 通知播放开始
      this.notifyPlayStarted({ id: vodId, type: MediaType.VOD });
      
      return { success: true, url: episodeToPlay.playUrl };
    } catch (error) {
      Logger.error(TAG, `Failed to play VOD: ${vodId}`, error);
      return { success: false, error: 'Failed to start playback' };
    }
  }

  /**
   * 播放直播频道
   */
  public async playLiveChannel(channelId: string, options: PlayOptions = {}): Promise<{ success: boolean; url?: string; error?: string }> {
    try {
      const channel = await this.getLiveChannelDetail(channelId);
      if (!channel || !channel.playUrl) {
        return { success: false, error: 'Channel not found or no playback URL' };
      }

      // 更新播放状态
      this.currentPlayingMedia = { id: channelId, type: MediaType.LIVE };
      
      // 更新直播观看历史
      await this.historyRepository.saveLiveHistory({
        channelId: channel.id,
        channelName: channel.name,
        channelLogo: channel.logo,
        playUrl: channel.playUrl,
        groupId: channel.groupId,
        groupName: channel.groupName || '',
        watchTime: Date.now()
      });
      
      // 通知播放开始
      this.notifyPlayStarted({ id: channelId, type: MediaType.LIVE });
      
      return { success: true, url: channel.playUrl };
    } catch (error) {
      Logger.error(TAG, `Failed to play live channel: ${channelId}`, error);
      return { success: false, error: 'Failed to start playback' };
    }
  }

  /**
   * 暂停播放
   */
  public async pausePlayback(): Promise<void> {
    // 实际实现中，这里会调用播放器API暂停播放
    Logger.info(TAG, 'Playback paused');
  }

  /**
   * 恢复播放
   */
  public async resumePlayback(): Promise<void> {
    // 实际实现中，这里会调用播放器API恢复播放
    Logger.info(TAG, 'Playback resumed');
  }

  /**
   * 停止播放
   */
  public async stopPlayback(): Promise<void> {
    // 实际实现中，这里会调用播放器API停止播放
    this.currentPlayingMedia = null;
    Logger.info(TAG, 'Playback stopped');
  }

  /**
   * 保存播放进度
   */
  public async savePlayProgress(
    mediaId: string,
    mediaType: MediaType,
    currentTime: number,
    totalDuration: number,
    episodeId?: string
  ): Promise<void> {
    try {
      const progress = totalDuration > 0 ? (currentTime / totalDuration) * 100 : 0;
      
      if (mediaType === MediaType.VOD && episodeId) {
        // 保存点播进度
        await this.historyRepository.saveVodHistory({
          vodId: mediaId,
          episodeId,
          playTime: currentTime,
          totalDuration,
          progress,
          watchTime: Date.now()
        });
      }
      
      Logger.info(TAG, `Saved play progress for ${mediaType}: ${mediaId}, progress: ${progress.toFixed(2)}%`);
    } catch (error) {
      Logger.error(TAG, `Failed to save play progress for ${mediaId}`, error);
    }
  }

  /**
   * 获取播放进度
   */
  public async getPlayProgress(
    mediaId: string,
    mediaType: MediaType,
    episodeId?: string
  ): Promise<{ currentTime: number; totalDuration: number; progress: number } | null> {
    try {
      if (mediaType === MediaType.VOD && episodeId) {
        const history = await this.historyRepository.getVodHistory(mediaId, episodeId);
        if (history) {
          return {
            currentTime: history.playTime,
            totalDuration: history.totalDuration,
            progress: history.progress
          };
        }
      }
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get play progress for ${mediaId}`, error);
      return null;
    }
  }

  /**
   * 搜索媒体内容
   */
  public async searchMedia(
    keyword: string,
    page: number = 1,
    pageSize: number = 20,
    mediaType?: MediaType
  ): Promise<SearchResult> {
    try {
      const result: SearchResult = {
        vodItems: [],
        liveChannels: [],
        totalCount: 0,
        page,
        pageSize,
        hasMore: false
      };

      // 根据媒体类型搜索
      if (!mediaType || mediaType === MediaType.VOD) {
        const vodSearchResult = await this.vodRepository.searchVod(
          keyword,
          page,
          pageSize
        );
        result.vodItems = vodSearchResult.items;
        result.hasMore = vodSearchResult.hasMore;
      }

      if (!mediaType || mediaType === MediaType.LIVE) {
        const liveSearchResult = await this.liveRepository.searchChannels(
          keyword,
          page,
          pageSize
        );
        result.liveChannels = liveSearchResult.items;
        result.hasMore = result.hasMore || liveSearchResult.hasMore;
      }

      result.totalCount = result.vodItems.length + result.liveChannels.length;
      
      Logger.info(TAG, `Search completed for: ${keyword}, found ${result.totalCount} items`);
      return result;
    } catch (error) {
      Logger.error(TAG, `Search failed for keyword: ${keyword}`, error);
      return {
        vodItems: [],
        liveChannels: [],
        totalCount: 0,
        page,
        pageSize,
        hasMore: false
      };
    }
  }

  /**
   * 获取推荐内容
   */
  public async getRecommendations(vodId?: string): Promise<RecommendationResult> {
    try {
      const result: RecommendationResult = {
        featured: [],
        recentlyAdded: [],
        popular: [],
        continueWatching: [],
        related: []
      };

      // 获取推荐配置
      const vodConfig = await this.configService.getConfigValue('vod', {});
      const showRecommended = vodConfig.showRecommendedContent !== false;

      // 获取精选内容
      result.featured = await this.vodRepository.getFeaturedVod(10);
      
      // 获取最近添加
      result.recentlyAdded = await this.vodRepository.getRecentlyAddedVod(10);
      
      // 获取热门内容
      result.popular = await this.vodRepository.getPopularVod(10);
      
      // 获取继续观看
      const continueWatchingHistory = await this.historyRepository.getContinueWatching(10);
      result.continueWatching = await Promise.all(continueWatchingHistory.map(async history => {
        // 获取媒体详情
        if (history.type === 'vod') {
          const vod = await this.vodRepository.getVodById(history.vodId || '');
          return {
            mediaId: history.vodId || '',
            mediaType: MediaType.VOD,
            title: vod?.title || history.title,
            coverUrl: vod?.coverUrl,
            playTime: history.playTime,
            totalDuration: history.totalDuration,
            lastPlayTime: history.watchTime,
            currentEpisode: history.episodeId,
            progress: history.progress
          };
        }
        return null;
      }).filter(item => item !== null) as PlayHistory[]);

      // 获取相关内容（如果有指定的VOD ID）
      if (vodId && showRecommended) {
        const vod = await this.getVodDetail(vodId);
        if (vod) {
          // 基于分类和标签获取相关内容
          const related = await this.vodRepository.getRelatedVod(
            vodId,
            vod.categoryIds || [],
            vod.tagIds || [],
            10
          );
          result.related = related;
        }
      }

      return result;
    } catch (error) {
      Logger.error(TAG, 'Failed to get recommendations', error);
      return {
        featured: [],
        recentlyAdded: [],
        popular: [],
        continueWatching: [],
        related: []
      };
    }
  }

  /**
   * 收藏媒体内容
   */
  public async toggleFavorite(
    mediaId: string,
    mediaType: MediaType,
    title: string,
    coverUrl?: string,
    folderId?: string
  ): Promise<{ isFavorite: boolean; error?: string }> {
    try {
      // 检查是否已收藏
      const isFavorite = await this.collectionRepository.isItemCollected(mediaId, mediaType);
      
      if (isFavorite) {
        // 取消收藏
        await this.collectionRepository.removeCollectionItem(mediaId);
        return { isFavorite: false };
      } else {
        // 添加收藏
        await this.collectionRepository.addCollectionItem({
          id: mediaId,
          type: mediaType,
          title,
          coverUrl,
          folderId,
          addedTime: Date.now()
        });
        return { isFavorite: true };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to toggle favorite for ${mediaId}`, error);
      return { isFavorite: false, error: 'Operation failed' };
    }
  }

  /**
   * 检查是否已收藏
   */
  public async isFavorite(mediaId: string, mediaType: MediaType): Promise<boolean> {
    try {
      return await this.collectionRepository.isItemCollected(mediaId, mediaType);
    } catch (error) {
      Logger.error(TAG, `Failed to check favorite status for ${mediaId}`, error);
      return false;
    }
  }

  /**
   * 获取收藏列表
   */
  public async getFavorites(
    mediaType?: MediaType,
    page: number = 1,
    pageSize: number = 20
  ): Promise<Array<{ id: string; type: MediaType; title: string; coverUrl?: string; addedTime: number }>> {
    try {
      const favorites = await this.collectionRepository.getCollectionItems(
        page,
        pageSize,
        mediaType
      );
      return favorites.map(item => ({
        id: item.id,
        type: item.type,
        title: item.title,
        coverUrl: item.coverUrl,
        addedTime: item.addedTime
      }));
    } catch (error) {
      Logger.error(TAG, 'Failed to get favorites list', error);
      return [];
    }
  }

  /**
   * 预加载点播相关内容
   */
  private async preloadVodRelatedContent(vodId: string): Promise<void> {
    // 异步预加载相关内容，不阻塞主线程
    setTimeout(async () => {
      try {
        await this.vodRepository.getRelatedVod(vodId, [], [], 5);
      } catch (error) {
        // 预加载失败不影响主流程
        Logger.warn(TAG, `Failed to preload related content for ${vodId}`, error);
      }
    }, 0);
  }

  /**
   * 注册播放状态监听器
   */
  public addPlayListener(listener: (media: { id: string; type: MediaType }) => void): void {
    this.playListeners.push(listener);
  }

  /**
   * 移除播放状态监听器
   */
  public removePlayListener(listener: (media: { id: string; type: MediaType }) => void): void {
    this.playListeners = this.playListeners.filter(l => l !== listener);
  }

  /**
   * 通知播放开始
   */
  private notifyPlayStarted(media: { id: string; type: MediaType }): void {
    this.playListeners.forEach(listener => {
      try {
        listener(media);
      } catch (error) {
        Logger.error(TAG, 'Error in play listener', error);
      }
    });
  }

  /**
   * 获取当前播放的媒体
   */
  public getCurrentPlayingMedia(): { id: string; type: MediaType } | null {
    return this.currentPlayingMedia;
  }

  /**
   * 清理资源
   */
  public async cleanup(): Promise<void> {
    // 清理播放器资源、缓存等
    this.stopPlayback();
    Logger.info(TAG, 'Media service resources cleaned up');
  }
}