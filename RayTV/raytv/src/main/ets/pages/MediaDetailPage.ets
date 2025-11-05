import { ScrollView, Image, Text, Button, List, ListItem, Divider, LoadingProgress, Tag, SearchBar, Stack, Flex, Blank, TextInput, Grid, GridItem, Swiper, SwiperItem } from '@kit.ArkUI';
import { Router } from '@ohos.router';
import Logger from '../common/util/Logger';
import ConfigService from '../service/config/ConfigService';
import MediaService from '../service/media/MediaService';
import HistoryService from '../service/media/HistoryService';
import FavoriteService from '../service/media/FavoriteService';
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
 * 媒体详情页组件
 * 展示媒体详细信息、集数列表和操作按钮
 */
@Component
struct MediaDetailPage {
  private readonly TAG: string = 'MediaDetailPage';
  
  // 路由参数
  private mediaId: string = '';
  private siteKey: string = '';
  
  // 状态管理
  @State mediaDetail: MediaDetail | null = null;
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
  @State seasons: number[] = [1]; // 默认只有第1季
  @State searchText: string = '';
  
  // 每页显示的剧集数量
  private episodesPageSize: number = 50;
  
  // 初始化
  aboutToAppear(): void {
    Logger.info(this.TAG, 'MediaDetailPage mounted');
    
    // 获取路由参数
    const params = Router.getParams();
    this.mediaId = params?.['mediaId'] || '';
    this.siteKey = params?.['siteKey'] || '';
    
    Logger.info(this.TAG, `Loading media detail for: ${this.siteKey}:${this.mediaId}`);
    
    // 加载媒体详情
    this.loadMediaDetail();
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
    
    this.isLoading = true;
    this.errorMessage = '';
    
    // 获取媒体详情
    this.fetchMediaDetail().then((detail) => {
      this.mediaDetail = detail;
      // 加载相关推荐
      this.loadRelatedMedia();
    }).catch((error) => {
      Logger.error(this.TAG, `Failed to load media detail: ${error}`);
      this.errorMessage = '加载详情失败';
    }).finally(() => {
      this.isLoading = false;
    });
    
    // 检查收藏状态
    this.checkIsFavorited();
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
        Logger.error(this.TAG, `Failed to check favorite status: ${error}`);
        this.isFavorite = false;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to check favorite status: ${error}`);
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
          // 初始化剧集列表
          if (detail.episodes && detail.episodes.length > 0) {
            this.episodes = detail.episodes;
            
            // 提取所有季数
            this.seasons = [...new Set(detail.episodes.map(ep => ep.season || 1))].map(num => Number(num)).sort((a, b) => a - b);
            
            // 检查是否有更多剧集
            this.hasMoreEpisodes = detail.episodes.length >= this.episodesPageSize;
          }
          
          resolve(detail);
        }).catch((error) => {
          Logger.error(this.TAG, `Failed to fetch media detail: ${error}`);
          reject(error);
        });
      } catch (error) {
        Logger.error(this.TAG, `Failed to fetch media detail: ${error}`);
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
        Logger.error(this.TAG, `Failed to load more episodes: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load more episodes: ${error}`);
    }
  }
  
  /**
   * 加载播放源
   */
  private loadPlaySources(episodeId?: string): void {
    if (!this.mediaId || !this.siteKey) return;
    
    try {
      mediaService.getPlaySources(this.mediaId, this.siteKey, episodeId).then((playSources) => {
        this.playSources = playSources;
        this.filteredSources = [...this.playSources]; // 初始化过滤后的列表
        this.isLoading = false;
        
        // 如果有播放源且选择了剧集，跳转到播放页面
        if (this.playSources && this.playSources.length > 0 && this.selectedEpisodeIndex >= 0) {
          Router.push({
            url: 'pages/PlaybackPage',
            params: {
              mediaId: this.mediaId,
              siteKey: this.siteKey,
              episodeId: this.episodes[this.selectedEpisodeIndex].id,
              playSourceIndex: 0,
              mediaTitle: this.mediaDetail?.title || '',
              episodeName: this.episodes[this.selectedEpisodeIndex].name
            }
          });
        }
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to load play sources: ${error}`);
        this.errorMessage = '加载播放源失败';
        this.isLoading = false;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load play sources: ${error}`);
      this.errorMessage = '加载播放源失败';
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
      this.filteredSources = this.playSources.filter(source => 
        source.name.toLowerCase().includes(searchLower) ||
        (source.description && source.description.toLowerCase().includes(searchLower))
      );
    } else {
      // 如果搜索文本为空，显示所有片源
      this.filteredSources = [...this.playSources];
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
        Logger.error(this.TAG, `Failed to load related media: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load related media: ${error}`);
    }
  }
  
  /**
   * 处理收藏/取消收藏
   */
  private handleToggleFavorite(): void {
    if (!this.mediaId || !this.siteKey || !this.mediaDetail) return;
    
    try {
      if (this.isFavorite) {
        // 取消收藏
        favoriteService.removeFavorite(this.mediaId, this.siteKey).then(() => {
          Logger.info(this.TAG, `Removed from favorites: ${this.mediaId}`);
          this.isFavorite = false;
        }).catch((error) => {
          Logger.error(this.TAG, `Failed to remove favorite: ${error}`);
          this.errorMessage = '操作失败，请稍后重试';
        });
      } else {
        // 添加收藏
        const favoriteItem: FavoriteItem = {
          id: `${this.siteKey}_${this.mediaId}`,
          mediaId: this.mediaId,
          siteKey: this.siteKey,
          title: this.mediaDetail.title,
          coverUrl: this.mediaDetail.coverUrl,
          type: this.mediaDetail.type,
          favoriteTime: Date.now()
        };
        
        favoriteService.addFavorite(favoriteItem).then(() => {
          Logger.info(this.TAG, `Added to favorites: ${this.mediaId}`);
          this.isFavorite = true;
        }).catch((error) => {
          Logger.error(this.TAG, `Failed to add favorite: ${error}`);
          this.errorMessage = '操作失败，请稍后重试';
        });
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle favorite: ${error}`);
      this.errorMessage = '操作失败，请稍后重试';
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
        id: `${this.siteKey}_${this.mediaId}_${episode.id}`,
        mediaId: this.mediaId,
        siteKey: this.siteKey,
        episodeId: episode.id,
        title: this.mediaDetail.title,
        coverUrl: this.mediaDetail.coverUrl,
        episodeName: episode.name,
        currentTime: 0,
        duration: 0,
        lastPlayTime: Date.now()
      };
      historyService.addHistory(historyItem);
      
      // 加载播放源并播放
      this.loadPlaySources(episode.id);
    } catch (error) {
      Logger.error(this.TAG, `Failed to play episode: ${error}`);
      this.errorMessage = '播放失败，请稍后重试';
    }
  }
  
  /**
   * 处理播放源点击
   */
  private handlePlaySourceClick(source: PlaySource): void {
    if (!this.mediaId || !this.siteKey || !this.mediaDetail) return;
    
    try {
      let episodeId: string | undefined;
      let episodeName: string | undefined;
      let currentPlayPosition = 0;
      
      // 获取选中剧集信息
      if (this.selectedEpisodeIndex >= 0 && this.episodes[this.selectedEpisodeIndex]) {
        episodeId = this.episodes[this.selectedEpisodeIndex].id;
        episodeName = this.episodes[this.selectedEpisodeIndex].name;
        
        // 尝试获取上次观看进度
        if (episodeId) {
          historyService.getWatchHistory(
            this.mediaId,
            this.siteKey,
            episodeId
          ).then(watchHistory => {
            if (watchHistory && watchHistory.position > 0) {
              currentPlayPosition = watchHistory.position;
            }
            
            // 跳转到播放页面
            this.navigateToPlayback(episodeId, episodeName, source, currentPlayPosition);
          }).catch(() => {
            // 即使获取历史记录失败，仍继续跳转到播放页面
            this.navigateToPlayback(episodeId, episodeName, source, 0);
          });
        } else {
          this.navigateToPlayback(episodeId, episodeName, source, 0);
        }
      } else {
        this.navigateToPlayback(episodeId, episodeName, source, 0);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle play source click: ${error}`);
      this.errorMessage = '播放失败';
    }
  }
  
  /**
   * 导航到播放页面
   */
  private navigateToPlayback(
    episodeId: string | undefined,
    episodeName: string | undefined,
    playSource: PlaySource,
    startPosition: number
  ): void {
    Router.push({
      url: 'pages/PlaybackPage',
      params: {
        mediaId: this.mediaId,
        siteKey: this.siteKey,
        episodeId: episodeId,
        playSource: playSource,
        playSources: this.filteredSources,
        mediaTitle: this.mediaDetail?.title || '',
        episodeName: episodeName,
        startPosition: startPosition,
        autoSwitchSourceOnError: true
      }
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
                  Logger.error(this.TAG, `Failed to save watch progress: ${error}`);
                });
              }
            })
            .catch(error => {
              Logger.error(this.TAG, `Failed to get duration: ${error}`);
            });
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to get current position: ${error}`);
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to save play progress: ${error}`);
    }
  }
  
  /**
   * 处理相关媒体点击
   */
  private handleRelatedMediaClick(media: MediaItem): void {
    // 跳转到对应媒体详情页
    Router.push({
      url: 'pages/MediaDetailPage',
      params: {
        mediaId: media.id,
        siteKey: media.siteKey
      }
    });
  }
  
  /**
   * 处理季切换
   */
  private handleSeasonChange(season: number): void {
    this.selectedSeason = season;
    // 重置选中的集数
    this.selectedEpisodeIndex = -1;
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    Router.back();
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    Stack.create();
    Stack.className("loading-container");
    LoadingProgress.create();
    LoadingProgress.className("loading-progress");
    LoadingProgress.color("#FF4500");
    LoadingProgress.pop();
    Text.create();
    Text.className("loading-text");
    Text.content("加载中...");
    Text.pop();
    Stack.pop();
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    Stack.create();
    Stack.className("error-container");
    Text.create();
    Text.className("error-icon");
    Text.content("⚠️");
    Text.pop();
    Text.create();
    Text.className("error-message");
    Text.content(this.errorMessage);
    Text.pop();
    Button.create();
    Button.className("retry-button");
    Button.onClick(() => this.loadMediaDetail());
    Text.create();
    Text.content("重试");
    Text.pop();
    Button.pop();
    Stack.pop();
  }
  
  /**
   * 渲染媒体信息头部
   */
  @Builder
  private renderHeader(): void {
    if (!this.mediaDetail) return;
    
    Stack.create();
    Stack.className("media-header");
    Flex.create();
    Flex.className("media-info");
    Image.create();
    Image.src(this.mediaDetail.coverUrl || "https://via.placeholder.com/200x300?text=No+Image");
    Image.className("media-cover");
    Image.objectFit("cover");
    Image.pop();
    Flex.create();
    Flex.className("media-details");
    Flex.direction("column");
    Text.create();
    Text.className("media-title");
    Text.content(this.mediaDetail.title);
    Text.pop();
    Flex.create();
    Flex.className("media-meta");
    if (this.mediaDetail.year) {
      Tag.create();
      Tag.className("meta-tag");
      Text.create();
      Text.content(this.mediaDetail.year);
      Text.pop();
      Tag.pop();
    }
    if (this.mediaDetail.score) {
      Tag.create();
      Tag.className("meta-tag score");
      Text.create();
      Text.content(this.mediaDetail.score);
      Text.pop();
      Tag.pop();
    }
    if (this.mediaDetail.type) {
      Tag.create();
      Tag.className("meta-tag");
      Text.create();
      Text.content(this.mediaDetail.type);
      Text.pop();
      Tag.pop();
    }
    if (this.mediaDetail.status) {
      Tag.create();
      Tag.className("meta-tag");
      Text.create();
      Text.content(this.mediaDetail.status);
      Text.pop();
      Tag.pop();
    }
    Flex.pop();
    if (this.mediaDetail.directors && this.mediaDetail.directors.length > 0) {
      Text.create();
      Text.className("media-directors");
      Text.content(`导演: ${this.mediaDetail.directors.join(', ')}`);
      Text.pop();
    }
    if (this.mediaDetail.actors && this.mediaDetail.actors.length > 0) {
      Text.create();
      Text.className("media-actors");
      Text.content(`演员: ${this.mediaDetail.actors.slice(0, 5).join(', ')}${this.mediaDetail.actors.length > 5 ? '...' : ''}`);
      Text.pop();
    }
    if (this.mediaDetail.genres && this.mediaDetail.genres.length > 0) {
      Text.create();
      Text.className("media-genres");
      Text.content(`类型: ${this.mediaDetail.genres.join(', ')}`);
      Text.pop();
    }
    if (this.mediaDetail.regions && this.mediaDetail.regions.length > 0) {
      Text.create();
      Text.className("media-regions");
      Text.content(`地区: ${this.mediaDetail.regions.join(', ')}`);
      Text.pop();
    }
    Flex.pop();
    Flex.pop();
    
    Stack.create();
    Stack.className("action-buttons");
    Button.create();
    Button.className("primary-button");
    Button.onClick(() => {
      if (this.episodes.length > 0) {
        this.handlePlayEpisode(this.episodes[0]);
      }
    });
    Text.create();
    Text.content("立即播放");
    Text.pop();
    Button.pop();
    Button.create();
    Button.className(`secondary-button ${this.isFavorite ? 'favorite-active' : ''}`);
    Button.onClick(this.handleToggleFavorite);
    Text.create();
    Text.content(this.isFavorite ? '已收藏' : '收藏');
    Text.pop();
    Button.pop();
    Stack.pop();
    Stack.pop();
  }
  
  /**
   * 渲染剧情简介
   */
  @Builder
  private renderSynopsis(): void {
    if (!this.mediaDetail || !this.mediaDetail.synopsis) return;
    
    Stack.create();
    Stack.className("synopsis-section");
    Text.create();
    Text.className("section-title");
    Text.content("剧情简介");
    Text.pop();
    Text.create();
    Text.className("synopsis-content");
    Text.content(this.mediaDetail.synopsis);
    Text.pop();
    Stack.pop();
  }
  
  /**
   * 渲染标签页切换栏
   */
  @Builder
  private renderTabBar(): void {
    Flex.create();
    Flex.className("tab-bar");
    Button.create();
    Button.className(`tab-button ${this.activeTab === 'episodes' ? 'active' : ''}`);
    Button.onClick(() => this.activeTab = 'episodes');
    Text.create();
    Text.content("剧集列表");
    Text.pop();
    Button.pop();
    Button.create();
    Button.className(`tab-button ${this.activeTab === 'sources' ? 'active' : ''}`);
    Button.onClick(() => this.activeTab = 'sources');
    Text.create();
    Text.content("播放源");
    Text.pop();
    Button.pop();
    Flex.pop();
  }
  
  /**
   * 渲染季选择器
   */
  @Builder
  private renderSeasonSelector(): void {
    if (this.seasons.length <= 1) return;
    
    Flex.create();
    Flex.className("season-selector");
    Text.create();
    Text.className("selector-label");
    Text.content("选择季数:");
    Text.pop();
    Flex.create();
    Flex.className("season-buttons");
    this.seasons.forEach((season, index) => {
      Button.create();
      Button.key(season.id);
      Button.className(`season-button ${this.selectedSeasonIndex === index ? 'active' : ''}`);
      Button.onClick(() => this.selectedSeasonIndex = index);
      Text.create();
      Text.content(`第${season.seasonNumber}季`);
      Text.pop();
      Button.pop();
    });
    Flex.pop();
    Flex.pop();
  }
  
  /**
   * 渲染剧集列表
   */
  @Builder
  private renderEpisodes(): void {
    if (this.episodes.length === 0) {
      Text.create();
      Text.className("no-episodes");
      Text.content("暂无剧集");
      Text.pop();
      return;
    }
    
    List.create();
    List.className("episode-list");
    this.episodes.forEach((episode) => {
      ListItem.create();
      ListItem.key(episode.id);
      ListItem.className("episode-item");
      Flex.create();
      Flex.className("episode-info");
      Flex.onClick(() => this.handlePlayEpisode(episode));
      Text.create();
      Text.className("episode-title");
      Text.content(episode.title);
      Text.pop();
      Text.create();
      Text.className("episode-duration");
      Text.content(episode.duration);
      Text.pop();
      if (episode.isWatched) {
        Badge.create();
        Badge.className("watched-badge");
        Text.create();
        Text.content("已观看");
        Text.pop();
        Badge.pop();
      }
      Flex.pop();
      ListItem.pop();
    });
    List.pop();
  }
  
  /**
   * 渲染播放源列表
   */
  @Builder
  private renderSources(): void {
    if (this.sources.length === 0) {
      Text.create();
      Text.className("no-sources");
      Text.content("暂无播放源");
      Text.pop();
      return;
    }
    
    List.create();
    List.className("source-list");
    this.sources.forEach((source) => {
      ListItem.create();
      ListItem.key(source.id);
      ListItem.className("source-item");
      Flex.create();
      Flex.className("source-info");
      Flex.onClick(() => this.handlePlaySource(source));
      Text.create();
      Text.className("source-name");
      Text.content(source.name);
      Text.pop();
      Text.create();
      Text.className("source-quality");
      Text.content(source.quality);
      Text.pop();
      if (source.isDefault) {
        Badge.create();
        Badge.className("default-badge");
        Text.create();
        Text.content("默认");
        Text.pop();
        Badge.pop();
      }
      Flex.pop();
      ListItem.pop();
    });
    List.pop();
  }
  
  /**
   * 渲染相关推荐
   */
  @Builder
  private renderRelatedMedia(): void {
    if (this.relatedMedia.length === 0) return;
    
    <Stack className="related-section">
      <Text className="section-title">相关推荐</Text>
      <ScrollView scrollable="horizontal" className="related-scroll">
        <Flex>
          {this.relatedMedia.map((media) => (
            <Stack key={`${media.siteKey}-${media.id}`} className="related-item" onClick={() => this.handleRelatedMediaClick(media)}>
              <Image
                src={media.coverUrl || "https://via.placeholder.com/150x200?text=No+Image"}
                className="related-cover"
                objectFit="cover"
              ></Image>
              <Text className="related-title" numberOfLines={2}>{media.title}</Text>
            </Stack>
          ))}
        </Flex>
      </ScrollView>
    </Stack>
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack.create();
    Stack.className("media-detail-page");
    
    // 顶部导航栏
    Stack.create();
    Stack.className("nav-header");
    Button.create();
    Button.className("back-button");
    Button.onClick(this.handleBack);
    Text.create();
    Text.content("← 返回");
    Text.pop();
    Button.pop();
    Text.create();
    Text.className("page-title");
    Text.content("详情");
    Text.pop();
    Blank.create();
    Blank.pop();
    Stack.pop();
    
    // 主内容区域
    if (this.isLoading) {
      this.renderLoading();
    } else if (this.errorMessage) {
      this.renderError();
    } else {
      ScrollView.create();
      ScrollView.className("content-scroll");
      ScrollView.scrollBar("auto");
      this.renderHeader();
      this.renderSynopsis();
      this.renderTabBar();
      
      Stack.create();
      Stack.className("tab-content");
      if (this.selectedTab === 'episodes') {
        this.renderEpisodes();
      } else {
        this.renderPlaySources();
      }
      Stack.pop();
      
      this.renderRelatedMedia();
      Blank.create();
      Blank.className("bottom-space");
      Blank.pop();
      ScrollView.pop();
    }
    Stack.pop();
  }
}

export default MediaDetailPage;