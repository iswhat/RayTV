import { Button, Column, Row, Text, Image, ForEach, Scroller, Blank, ImageFit, BarState, TextOverflow } from '@ohos/arkui';
import { AppNavigator, PageRoute } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { configService } from '../service/config/ConfigService';
import { mediaService } from '../service/media/MediaService';
import { historyService } from '../service/media/HistoryService';
import { favoriteService } from '../service/media/FavoriteService';
import { playbackService } from '../service/playback/PlaybackService';
// 类型定义
export interface MediaItem {
  id: string;
  siteKey: string;
  title: string;
  coverUrl: string;
  type?: string;
  score?: string;
  year?: string;
  status?: string;
}

export interface MediaDetail {
  id: string;
  siteKey: string;
  title: string;
  coverUrl: string;
  description?: string;
  score?: string;
  year?: string;
  type?: string;
  status?: string;
  episodes?: Episode[];
  directors?: string[];
  actors?: string[];
  genres?: string[];
  regions?: string[];
}

export interface Episode {
  id: string;
  name: string;
  season?: number;
  episode?: number;
}

export interface PlaySource {
  id?: string;
  name?: string;
  quality?: string;
  url?: string;
  description?: string;
}

export interface FavoriteItem {
  id: string;
  mediaId: string;
  siteKey: string;
  title: string;
  coverUrl: string;
  type?: string;
  favoriteTime: number;
}

export interface HistoryItem {
  id: string;
  mediaId: string;
  siteKey: string;
  episodeId: string;
  title: string;
  coverUrl: string;
  episodeName: string;
  currentTime: number;
  duration: number;
  lastPlayTime: number;
}

export interface WatchHistory {
  mediaId: string;
  episodeId: string;
  position: number;
  lastWatchTime: number;
}

/**
 * 媒体详情页组�? * 展示媒体详细信息、集数列表和操作按钮
 */
@Entry
@Component
struct MediaDetailPage {
  private readonly TAG: string = 'MediaDetailPage';
  
  // 路由参数
  private mediaId: string = '';
  private siteKey: string = '';
  
  // 状态管�?  @State mediaDetail: MediaDetail | null = null;
  @State episodes: Episode[] = [];
  @State playSources: PlaySource[] = [];
  @State filteredSources: PlaySource[] = [];
  @State relatedMedia: MediaItem[] = [];
  @State isLoading: boolean = true;
  @State isFavorite: boolean = false;
  @State selectedTab: string = 'episodes'; // 'episodes' or 'sources'
  @State currentPage: number = 1;
  @State hasMoreEpisodes: boolean = true;
  @State errorMessage: string = '';
  @State selectedEpisodeIndex: number = 0;
  @State selectedSeason: number = 1;
  @State seasons: number[] = [1]; // 默认只有一�?  @State searchText: string = '';
  @State activeTab: string = 'episodes'; // 用于标签页切�? 
  // 每页显示的剧集数�?  private episodesPageSize: number = 50;
  
  // 初始�?  aboutToAppear(): void {
    Logger.info(this.TAG, 'MediaDetailPage mounted');
    
    // 获取路由参数
    const params = this.context.router.getParams();
    this.mediaId = (params?.mediaId as string) || '';
    this.siteKey = (params?.siteKey as string) || '';
    
    Logger.info(this.TAG, `Loading media detail for: ${this.siteKey}:${this.mediaId}`);
    
    // 检查是否有预加载的数据（从SearchPage传递过来的�?    const title = params?.title as string;
    const coverUrl = params?.coverUrl as string;
    const description = params?.description as string;
    
    // 如果有预加载的数据，先创建一个临时的媒体详情对象
    if (this.mediaId && title && coverUrl) {
      this.mediaDetail = {
        id: this.mediaId,
        siteKey: this.siteKey,
        title: title,
        coverUrl: coverUrl,
        description: description || '',
        year: params?.['year'] || '',
        type: params?.['type'] || '',
        score: params?.['score'] || '',
        directors: params?.['directors'] || [],
        actors: params?.['actors'] || [],
        episodes: [],
        genres: [],
        regions: []
      };
      this.isLoading = false;
    }
    
    // 加载完整的媒体详�?    this.loadMediaDetail();
  }
  
  // 清理资源
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'MediaDetailPage unmounted');
  }
  
  /**
   * 加载媒体详情
   */
  private loadMediaDetail(): void {
    if (!this.mediaId || !this.siteKey) {
      this.errorMessage = '缺少必要参数';
      this.isLoading = false;
      return;
    }
    
    this.isLoading = false; // 因为可能已有预加载数据，暂时不显示加载状�?    this.errorMessage = '';
    
    try {
      // 获取媒体详情
      this.fetchMediaDetail().then((detail) => {
        this.mediaDetail = detail;
        // 加载相关推荐
        this.loadRelatedMedia();
        // 加载播放�?        if (this.mediaDetail?.episodes?.length > 0) {
          this.loadPlaySources(this.mediaDetail?.episodes[0].id);
        }
      }).catch((error) => {
        Logger.error(this.TAG, 'Failed to load media detail', error instanceof Error ? error : new Error(String(error)));
        // 如果已经有预加载数据，则不显示错误信�?
        if (!this.mediaDetail) {
          this.errorMessage = '加载详情失败';
        }
      }).finally(() => {
        this.isLoading = false;
      });
      
      // 检查收藏状�?      this.checkIsFavorited();
    } catch (error) {
      Logger.error(this.TAG, 'Error in loadMediaDetail', error instanceof Error ? error : new Error(String(error)));
      this.isLoading = false;
    }
  }
  
  /**
   * 检查是否已收藏
   */
  private checkIsFavorited(): void {
    if (!this.mediaId || !this.siteKey) return;
    
    try {
      favoriteService.isFavorite(this.mediaId, this.siteKey).then((isFavorited) => {
        this.isFavorite = isFavorited;
      }).catch((error) => {
        Logger.error(this.TAG, 'Failed to check favorite status', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
        this.isFavorite = false;
      });
    } catch (error) {
      Logger.error(this.TAG, 'Failed to check favorite status', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      this.isFavorite = false;
    }
  }
  
  /**
   * 获取媒体详情
   */
  private fetchMediaDetail(): Promise<MediaDetail> {
    return new Promise((resolve, reject) => {
      if (!this.mediaId || !this.siteKey) {
        reject(new Error('Missing required parameters'));
        return;
      }
      
      try {
        mediaService.getMediaDetail(this.mediaId, this.siteKey).then((detail) => {
          // 初始化剧集列�?          if (detail.episodes && detail.episodes.length > 0) {
            this.episodes = detail.episodes;
            
            // 提取所有季�?            this.seasons = [...new Set(detail.episodes.map(ep => ep.season || 1))].map(num => Number(num)).sort((a, b) => a - b);
            
            // 检查是否有更多剧集
            this.hasMoreEpisodes = detail.episodes.length >= this.episodesPageSize;
          }
          
          resolve(detail);
        }).catch((error) => {
          Logger.error(this.TAG, 'Failed to fetch media detail', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
          reject(error);
        });
      } catch (error) {
        Logger.error(this.TAG, 'Failed to fetch media detail', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
        reject(error);
      }
    });
  }
  
  /**
   * 加载更多剧集
   */
  private loadMoreEpisodes(): void {
    if (!this.hasMoreEpisodes || !this.mediaId || !this.siteKey) return;
    
    try {
      this.currentPage++;
      mediaService.getEpisodes(
        this.mediaId, 
        this.siteKey, 
        this.currentPage, 
        this.episodesPageSize
      ).then((moreEpisodes) => {
        if (moreEpisodes && moreEpisodes.length > 0) {
          this.episodes = [...this.episodes, ...moreEpisodes];
          this.hasMoreEpisodes = moreEpisodes.length === this.episodesPageSize;
        } else {
          this.hasMoreEpisodes = false;
        }
      }).catch((error) => {
        Logger.error(this.TAG, 'Failed to load more episodes', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      });
    } catch (error) {
      Logger.error(this.TAG, 'Failed to load more episodes', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
    }
  }
  
  /**
   * 加载播放�?   */
  private loadPlaySources(episodeId?: string): void {
    if (!this.mediaId || !this.siteKey) return;
    
    try {
      mediaService.getPlaySources(this.mediaId, this.siteKey, episodeId).then((playSources) => {
        this.playSources = playSources;
        this.filteredSources = [...this.playSources]; // 初始化过滤后的列�?        this.isLoading = false;
        
        // 如果有播放源且选择了剧集，跳转到播放页�?        if (this.playSources && this.playSources.length > 0 && this.selectedEpisodeIndex !== undefined && this.selectedEpisodeIndex >= 0) {
          AppNavigator.getInstance().navigateToVideoPlay({
          videoId: this.mediaId,
          siteKey: this.siteKey,
          episodeName: this.episodes[this.selectedEpisodeIndex].name
        });
        }
      }).catch((error) => {
        Logger.error(this.TAG, 'Failed to load play sources', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
        this.errorMessage = '加载播放源失�?;
        this.isLoading = false;
      });
    } catch (error) {
      Logger.error(this.TAG, 'Failed to load play sources', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      this.errorMessage = '加载播放源失�?;
    }
  }
  
  /**
   * 处理搜索文本变化
   */
  private handleSearchChange(text: string) {
    this.searchText = text;
    
    // 根据搜索文本过滤片源
    if (text.trim()) {
      const searchLower = text.toLowerCase();
      this.filteredSources = this.playSources?.filter(source => 
        source?.name.toLowerCase().includes(searchLower) ||
        (source.description && source.description.toLowerCase().includes(searchLower))
      );
    } else {
      // 如果搜索文本为空，显示所有片�?      // 使用手动复制替代spread operator
      this.filteredSources = [];
      for (let i = 0; i < this.playSources.length; i++) {
        this.filteredSources.push(this.playSources[i]);
      }
    }
  }
  
  /**
   * 加载相关推荐
   */
  private loadRelatedMedia(): void {
    if (!this.mediaId || !this.siteKey) return;
    
    try {
      mediaService.getRelatedMedia(
        this.mediaId, 
        this.siteKey,
        10
      ).then((relatedMedia) => {
        this.relatedMedia = relatedMedia;
      }).catch((error) => {
        Logger.error(this.TAG, 'Failed to load related media', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      });
    } catch (error) {
      Logger.error(this.TAG, 'Failed to load related media', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }
  
  /**
   * 处理收藏/取消收藏
   */
  private async handleToggleFavorite(): Promise<void> {
    if (!this.mediaId || !this.siteKey || !this.mediaDetail) return;
    
    try {
      // 先记录当前状态，以便在操作失败时恢复
      const originalState = this.isFavorite;
      
      // 立即更新UI状态，提供即时反馈
      this.isFavorite = !this.isFavorite;
      
      // 创建收藏项对�?      const favoriteItem: FavoriteItem = {
        id: `${this.siteKey}_${this.mediaId}`,
        mediaId: this.mediaId,
        siteKey: this.siteKey,
        title: this.mediaDetail?.title,
        coverUrl: this.mediaDetail.coverUrl,
        type: this.mediaDetail?.type,
        favoriteTime: Date.now()
      };
      
      // 执行真实的收�?取消收藏操作
      if (this.isFavorite) {
        await favoriteService.addToFavorites(favoriteItem);
        Logger.info(this.TAG, 'Added to favorites successfully');
      } else {
        await favoriteService.removeFromFavorites(this.mediaId, this.siteKey);
        Logger.info(this.TAG, 'Removed from favorites successfully');
      }
    } catch (error) {
      Logger.error(this.TAG, 'Failed to toggle favorite', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      // 操作失败，恢复之前的状�?      this.isFavorite = !this.isFavorite;
    }
  }
  
  /**
   * 处理播放剧集
   */
  private handlePlayEpisode(episode: Episode): void {
    if (!this.mediaId || !this.siteKey || !this.mediaDetail) return;
    
    try {
      // 记录播放历史
      const historyItem: HistoryItem = {
        id: `${this.siteKey}_${this.mediaId}_${episode?.id}`,
        mediaId: this.mediaId,
        siteKey: this.siteKey,
        episodeId: episode?.id,
        title: this.mediaDetail?.title,
        coverUrl: this.mediaDetail.coverUrl,
        episodeName: episode?.name,
        currentTime: 0,
        duration: 0,
        lastPlayTime: Date.now()
      };
      historyService.addHistory(historyItem);
      
      // 加载播放源并播放
      this.loadPlaySources(episode?.id);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to play episode', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      this.errorMessage = '播放失败，请稍后重试';
    }
  }
  
  /**
   * 处理播放源点�?   */
  private async handlePlaySourceClick(source: PlaySource): Promise<void> {
    if (!this.mediaId || !this.siteKey || !this.mediaDetail) return;
    
    try {
      let episodeId: string | undefined;
      let episodeName: string | undefined;
      let currentPlayPosition = 0;
      
      // 如果没有选择剧集，默认选择第一�?      if (this.episodes?.length > 0) {
        const episodeIndex = this.selectedEpisodeIndex !== undefined && this.selectedEpisodeIndex >= 0 ? this.selectedEpisodeIndex : 0;
        episodeId = this.episodes?.[episodeIndex]?.id;
        episodeName = this.episodes?.[episodeIndex]?.name;
        
        // 尝试获取上次观看进度
        if (episodeId) {
          try {
            // 使用真实的historyService获取观看历史
            const watchHistory = await historyService.getWatchHistory(
              this.mediaId,
              this.siteKey,
              episodeId
            );
            
            if (watchHistory && watchHistory.position > 0) {
              currentPlayPosition = watchHistory.position;
            }
          } catch (e) {
            // 获取历史记录失败，使用默认进�?            Logger.error(this.TAG, 'Failed to get watch history', e instanceof Error ? e : new Error(String(e instanceof Error ? e instanceof Error ? e : new Error(String(e : new Error(String(e instanceof Error ? e : new Error(String(e instanceof Error ? e instanceof Error ? e : new Error(String(e instanceof Error ? e instanceof Error ? e : new Error(String(e : new Error(String(e instanceof Error ? e : new Error(String(e : new Error(String(e instanceof Error ? e : new Error(String(e instanceof Error ? e instanceof Error ? e : new Error(String(e : new Error(String(e instanceof Error ? e : new Error(String(e)))))));
          }
        }
      }
      
      // 跳转到播放页�?      this.navigateToPlayback(episodeId, episodeName, source, currentPlayPosition);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to handle play source click', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      this.errorMessage = '播放失败';
    }
  }
  
  /**
   * 导航到播放页�?   */
  private navigateToPlayback(
    episodeId: string | undefined,
    episodeName: string | undefined,
    playSource: PlaySource,
    startPosition: number
  ): void {
    AppNavigator.getInstance().navigateToVideoPlay({
      videoId: this.mediaId,
      siteKey: this.siteKey,
      episodeName: episodeName
    });
  }
  
  /**
   * 保存当前播放进度
   */
  private saveCurrentPlayProgress(episodeId: string): void {
    try {
      playbackService.getCurrentPosition()
        .then(position => {
          playbackService.getDuration()
            .then(duration => {
              if (position > 0 && this.mediaId && this.siteKey) {
                historyService.saveWatchProgress(
                  this.mediaId,
                  this.siteKey,
                  episodeId,
                  position,
                  duration
                ).catch(error => {
                  Logger.error(this.TAG, 'Failed to save watch progress', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
                });
              }
            })
            .catch(error => {
              Logger.error(this.TAG, 'Failed to get duration', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
            });
        })
        .catch(error => {
          Logger.error(this.TAG, 'Failed to get current position', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
        });
    } catch (error) {
      Logger.error(this.TAG, 'Failed to save play progress', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }
  
  /**
   * 处理相关媒体点击
   */
  private handleRelatedMediaClick(media: MediaItem): void {
      // 跳转到对应媒体详情页
      AppNavigator.getInstance().navigateToDetail({
        id: media?.id,
        siteKey: media?.siteKey,
        type: 'vod'
      });
  }
  
  /**
   * 处理季切�?   */
  private handleSeasonChange(season: number): void {
    this.selectedSeason = season;
    // 重置选中的集�?    this.selectedEpisodeIndex = -1;
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
      AppNavigator.getInstance().back();
    }
  
  /**
   * 渲染加载状�?   */
  @Builder
  private renderLoading(): void {
    Column({
      style: {
        width: '100%',
        height: '100%',
        backgroundColor: '#4CAF50',
        justifyContent: 'center',
        alignItems: 'center'
      }
    }) {
      // 加载指示�?- 使用简单的旋转动画
      Column({
        width: 50,
        height: 50,
        backgroundColor: '#FFFFFF',
        borderRadius: 25,
        justifyContent: 'center',
        alignItems: 'center'
      }) {
        Text("�?)
          .fontSize(20)
          .fontColor('#4CAF50')
      }
      Text("加载�?..")
        .fontSize(24)
        .fontColor('#FFFFFF')
        .margin({ top: 20 })
    }
  }
  
  /**
   * 渲染错误状�?   */
  @Builder
  private renderError(): void {
    Column({
      style: {
        width: '100%',
        height: '100%',
        backgroundColor: '#4CAF50',
        justifyContent: 'center',
        alignItems: 'center',
        padding: 20
      }
    }) {
      Text("⚠️")
        .fontSize(48)
        .margin({ bottom: 20 })
      Text(this.errorMessage)
        .fontSize(24)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 30 })
      Button({
        style: {
          backgroundColor: '#FFFFFF',
          paddingHorizontal: 40,
          paddingVertical: 15,
          borderRadius: 25
        },
        onClick: () => this.loadMediaDetail()
      }) {
        Text("重试")
          .fontSize(24)
          .fontColor('#4CAF50')
          .fontWeight(700)
      }
    }
  }
  
  /**
   * 渲染头部信息
   */
  @Builder
  private renderHeader(): void {
    Column({
      padding: 20
    }) {
      // 媒体封面和基本信�?      Row({
        alignItems: 'flex-start'
      }) {
        // 媒体封面
        // Image组件在ArkUI中可能不可用，使用占位符
        Column({
          width: 150,
          height: 200,
          backgroundColor: '#E0E0E0',
          borderRadius: 8,
          justifyContent: 'center',
          alignItems: 'center'
        }) {
          Text("封面")
            .fontSize(16)
            .fontColor('#666666')
        }
        
        Column({
          marginLeft: 20,
          flex: 1
        }) {
          Text(this.mediaDetail?.title)
            .fontSize(28)
            .fontColor('#FFFFFF')
            .fontWeight(700)
          
          if (this.mediaDetail?.year) {
            Text(`年份: ${this.mediaDetail?.year}`)
              .fontSize(20)
              .fontColor('#E0E0E0')
              .margin({ top: 10 })
          }
          
          if (this.mediaDetail?.score) {
            Text(`评分: ${this.mediaDetail?.score}`)
              .fontSize(20)
              .fontColor('#E0E0E0')
              .margin({ top: 5 })
          }
        }
      }
      
      // 剧情简�?      if (this.mediaDetail?.description) {
        Column({
          marginTop: 20
        }) {
          Text("剧情简�?)
            .fontSize(22)
            .fontColor('#FFFFFF')
            .fontWeight(600)
            .margin({ bottom: 10 })
          
          Text(this.mediaDetail?.description)
            .fontSize(18)
            .fontColor('#E0E0E0')
            .lineHeight(24)
        }
      }
    }
  }
  
  /**
   * 渲染剧情简�?   */
  @Builder
  private renderSynopsis(): void {
    // 此方法应返回UI组件，但当前实现不符合ArkTS规范
    // 需要在build方法中直接使用条件渲染来实现剧情简�?  }
  
  /**
   * 渲染标签页切换栏
   */
  @Builder
  private renderTabBar(): void {
    Flex({
      direction: FlexDirection.Row,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    , backgroundColor: '#4CAF50'}) {
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .gap(10)
      Button({
        type: ButtonType.Normal
      , backgroundColor: this.activeTab === 'episodes' ? '#FFFFFF' : '#66BB6A'}) {
        .padding({ left: 25, right: 25, top: 10, bottom: 10 })
        .borderRadius(20)
        .minWidth(100)
        .onClick(() => this.activeTab = 'episodes')
        Text("剧集列表")
          .fontSize(24)
          .fontColor(this.activeTab === 'episodes' ? '#4CAF50' : '#FFFFFF')
          .fontWeight(700)
      }
      
      Button({
        type: ButtonType.Normal
      , backgroundColor: this.activeTab === 'sources' ? '#FFFFFF' : '#66BB6A'}) {
        .padding({ left: 25, right: 25, top: 10, bottom: 10 })
        .borderRadius(20)
        .minWidth(100)
        .onClick(() => this.activeTab = 'sources')
        Text("播放�?)
          .fontSize(24)
          .fontColor(this.activeTab === 'sources' ? '#4CAF50' : '#FFFFFF')
          .fontWeight(700)
      }
    }
  }
  
  /**
   * 渲染季选择�?   */
  @Builder
  private renderSeasonSelector(): void {
    // 季选择�?    if (this.seasons?.length === 0) {
      Column({
        justifyContent: FlexAlign.Center,
        alignItems: ItemAlign.Center
      , backgroundColor: '#4CAF50'}) {
        .padding(20)
        Text("暂无季信�?)
          .fontSize(24)
          .fontColor('#FFFFFF')
      }
    } else {
      Row({
        width: '100%',
        padding: 20,
        alignItems: 'center',
        justifyContent: 'flex-start'
      }) {
        Text("选择�?")
          .fontSize(28)
          .fontColor('#FFFFFF')
          .fontWeight(600)
          .margin({ right: 15 })
        
        // 季选择按钮
        ForEach(this.seasons, (season: number) => {
          Button({
            key: season.toString(),
            type: ButtonType.Normal
          , backgroundColor: this.selectedSeason === season ? '#66BB6A' : '#E0E0E0'}) {
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .borderRadius(6)
            .margin({ right: 10 })
            .onClick(() => this.handleSeasonChange(season))
            Text(`�?{season}季`)
              .fontSize(24)
              .fontColor(this.selectedSeason === season ? '#FFFFFF' : '#666666')
              .fontWeight(600)
          }
        })
      }
    }
  }
  
  /**
   * 渲染剧集列表
   */
  @Builder
  private renderEpisodes(): void {
    // 剧集列表
    if (this.episodes?.length === 0) {
      Column({
        style: {
          backgroundColor: '#4CAF50',
          padding: 20,
          alignItems: 'center'
        }
      }) {
        Text("暂无剧集")
          .fontSize(24)
          .fontColor('#FFFFFF')
      }
    } else {
      // 使用Flex布局展示剧集
      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center
      , width: '100%'}) {
        .gap(15)
        ForEach(this.episodes, (episode: Episode, index: number) => {
          Flex({
            key: episode?.id,
            direction: FlexDirection.Row,
            justifyContent: FlexAlign.Center,
            alignItems: ItemAlign.Center
          , width: '15%'}) {
            .minWidth(80)
            Button({
              type: ButtonType.Normal
            , backgroundColor: '#66BB6A'}) {
              .padding(15)
              .borderRadius(8)
              .width('100%')
              .onClick(() => this.handlePlayEpisode(episode))
              Text(`${index + 1}`)
                .fontSize(24)
                .fontColor('#FFFFFF')
                .fontWeight(600)
            }
          }
        })
      }
    }
  }
  
  /**
   * 渲染播放源列�?   */
  @Builder
  private renderPlaySources(): void {
    Column({
      width: '100%',
      backgroundColor: '#4CAF50',
      padding: 20
    }) {
      // 搜索�?      Row({
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#FFFFFF',
        borderRadius: 25,
        paddingHorizontal: 20,
        marginBottom: 20,
        height: 50
      }) {
        Text('🔍')
          .fontSize(24)
          .fontColor('#999999')
          .margin({ right: 10 })
        
        TextInput()
          .placeholder('搜索播放�?..')
          .flexGrow(1)
          .fontSize(20)
          .onChange((value: string) => {
            this.searchText = value;
            this.filteredSources = this.playSources?.filter(source => 
              source?.name?.toLowerCase().includes(value.toLowerCase())
            );
          })
        
        if (this.searchText) {
          Button({
            type: ButtonType.Normal
          })
          .backgroundColor('transparent')
          .onClick(() => {
            this.searchText = '';
            this.filteredSources = [...this.playSources];
          }) {
            Text('�?)
              .fontSize(24)
              .fontColor('#999999')
          }
        }
      }
    
      if (this.filteredSources.length === 0) {
        Column({
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Center
        , backgroundColor: '#4CAF50'}) {
          .padding(40)
          Text("暂无播放源或没有匹配的片�?)
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
      } else {
        Column() {
          .width('100%')
          ForEach(this.filteredSources, (source: PlaySource, index: number) => {
            Row({
              key: index.toString(),
              alignItems: ItemAlign.Center
            , padding: { top: 10, bottom: 10 }}) {
              Button({
                type: ButtonType.Normal
              })
              .backgroundColor('#66BB6A')
              .padding(25)
              .borderRadius(10)
              .width('100%')
              .border({ width: 2, color: 'transparent' })
              .onClick(() => this.handlePlaySourceClick(source)) {
                Flex({
                  direction: FlexDirection.Row,
                  alignItems: ItemAlign.Center,
                  justifyContent: FlexAlign.SpaceBetween
                , width: '100%'}) {
                  Text(source?.name || `播放�?{index + 1}`)
                    .fontSize(28)
                    .fontColor('#FFFFFF')
                    .fontWeight(700)
                    .flexGrow(1)
                  
                  if (source?.quality) {
                    Flex({
                      direction: FlexDirection.Row,
                      justifyContent: FlexAlign.Center,
                      alignItems: ItemAlign.Center
                    , backgroundColor: '#FFEB3B'}) {
                      .padding({ left: 15, right: 15, top: 8, bottom: 8 })
                      .borderRadius(15)
                      Text(source?.quality)
                        .fontSize(22)
                        .fontColor('#000000')
                        .fontWeight(700)
                    }
                  }
                }
              }
            }
          })
        }
      }
    }
  }
  
  /**
   * 渲染相关推荐
   */
  @Builder
  private renderRelatedMedia(): void {
    // 相关推荐
    if (this.relatedMedia?.length === 0) {
      Column({
        backgroundColor: '#4CAF50',
        padding: 20,
        alignItems: 'center'
      }) {
        Text("暂无相关推荐")
          .fontSize(24)
          .fontColor('#FFFFFF')
      }
    } else {
      Column({
        width: '100%'
      }) {
        // 相关推荐标题
        Row({
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Start
        , width: '100%'}) {
          .padding(20)
          Text("相关推荐")
            .fontSize(32)
            .fontColor('#333333')
            .fontWeight(600)
        }
        
        // 相关推荐列表
        ScrollView() {
          Column() {
            ForEach(this.relatedMedia, (media: MediaItem) => {
              Row({
                width: '100%',
                padding: 15,
                alignItems: 'center',
                borderBottom: '1px solid #E0E0E0'
              })
              .key(media?.id) {
                // 媒体封面
                Column({
                  width: 80,
                  height: 120,
                  backgroundColor: '#E0E0E0',
                  borderRadius: 8,
                  justifyContent: 'center',
                  alignItems: 'center',
                  margin: { right: 15 }
                }) {
                  Text("封面")
                    .fontSize(12)
                    .fontColor('#666666')
                }
                
                // 媒体信息
                Column() {
                  .flexGrow(1)
                  Text(media?.title)
                    .fontSize(28)
                    .fontColor('#333333')
                    .fontWeight(600)
                  
                  Text(`${media?.year} · ${media.rating}分`)
                    .fontSize(24)
                    .fontColor('#666666')
                }
              }
            })
          }
        }
      }
    }
  }
  
  /**
   * 组件渲染
   */
  build() {
    Column({
      flex: 1,
      backgroundColor: '#4CAF50'
    }) {
      // 顶部导航�?      Row({
        backgroundColor: '#388E3C',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        paddingVertical: 15,
        width: '100%'
      }) {
        Button({
          backgroundColor: 'transparent'
        }) {
          Text("�?返回")
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .onClick(this.handleBack)
        
        Text("详情")
          .fontSize(26)
          .fontColor('#FFFFFF')
          .fontWeight(700)
        
        Blank()
          .width(80)
      }
      
      // 主内容区�?      if (this.isLoading) {
        // 加载状�?        Column({
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center'
        }) {
          Text("加载�?..")
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
      } else if (this.errorMessage) {
        // 错误状�?        Column({
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center'
        }) {
          Text(this.errorMessage)
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
      } else {
        ScrollView({
          flex: 1,
          backgroundColor: '#4CAF50'
        }) {
          // 添加顶部间距，避免被导航栏遮�?          Blank()
            .height(60)
          
          // 媒体头部信息
          if (this.mediaDetail) {
            this.renderHeader()
          }
          
          // 标签页切换栏
          this.renderTabBar()
          
          // 内容区域
          Column() {
            if (this.activeTab === 'episodes') {
              this.renderEpisodes()
            } else {
              this.renderPlaySources()
            }
          }
          .padding(20)
          
          // 相关推荐
          if (this.relatedMedia?.length > 0) {
            Column() {
              Text("相关推荐")
                .fontSize(22)
                .fontColor('#FFFFFF')
                .fontWeight(600)
                .margin({ bottom: 15 })
              
              Scroller() {
                Row() {
                  ForEach(this.relatedMedia, (media: MediaItem) => {
                    Column()
                    .key(`${media?.siteKey}-${media?.id}`)
                    .width(150)
                    .margin({ right: 15 })
                    .onClick(() => this.handleRelatedMediaClick(media)) {
                      Image(media?.coverUrl || "https://via.placeholder.com/150x200?text=No+Image")
                        .width(150)
                        .height(200)
                        .borderRadius(8)
                        .objectFit(ImageFit.Cover)
                      
                      Text(media?.title)
                        .fontSize(18)
                        .fontColor('#FFFFFF')
                        .margin({ top: 10 })
                        .maxLines(2)
                        .textOverflow(TextOverflow.Ellipsis)
                    }
                  })
                }
              }
              .height(250)
              .scrollBar(BarState.Off)
            }
          }
          
          Blank()
            .height(50)
        }
      }
    }
  }
}

export default MediaDetailPage;






