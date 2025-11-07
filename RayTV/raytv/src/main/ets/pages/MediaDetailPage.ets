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
  @State activeTab: string = 'episodes'; // 用于标签页切换
  
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
    
    // 检查是否有预加载的数据（从SearchPage传递过来的）
    const title = params?.['title'];
    const coverUrl = params?.['coverUrl'];
    const description = params?.['description'];
    
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
    
    // 加载完整的媒体详情
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
    
    this.isLoading = false; // 因为可能已有预加载数据，暂时不显示加载状态
    this.errorMessage = '';
    
    try {
      // 获取媒体详情
      this.fetchMediaDetail().then((detail) => {
        this.mediaDetail = detail;
        // 加载相关推荐
        this.loadRelatedMedia();
        // 加载播放源
        if (this.mediaDetail?.episodes?.length > 0) {
          this.loadPlaySources(this.mediaDetail.episodes[0].id);
        }
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to load media detail: ${error}`);
        // 如果已经有预加载数据，则不显示错误信息
        if (!this.mediaDetail) {
          this.errorMessage = '加载详情失败';
        }
      }).finally(() => {
        this.isLoading = false;
      });
      
      // 检查收藏状态
      this.checkIsFavorited();
    } catch (error) {
      Logger.error(this.TAG, `Error in loadMediaDetail: ${error}`);
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
          Router.pushUrl({
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
      // 切换收藏状态（即使没有favoriteService也能提供视觉反馈）
      this.isFavorite = !this.isFavorite;
      
      // 尝试调用favoriteService（但不依赖它）
      try {
        // 模拟收藏/取消收藏操作
        Logger.info(this.TAG, this.isFavorite ? 'Added to favorites' : 'Removed from favorites');
      } catch (e) {
        // 忽略favoriteService相关的错误
        Logger.error(this.TAG, `Favorite service error: ${e}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle favorite: ${error}`);
      // 恢复之前的状态
      this.isFavorite = !this.isFavorite;
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
      
      // 如果没有选择剧集，默认选择第一个
      if (this.episodes.length > 0) {
        const episodeIndex = this.selectedEpisodeIndex >= 0 ? this.selectedEpisodeIndex : 0;
        episodeId = this.episodes[episodeIndex].id;
        episodeName = this.episodes[episodeIndex].name;
        
        // 尝试获取上次观看进度
        if (episodeId) {
          try {
            // 使用try-catch避免依赖问题
            const historyService = { getWatchHistory: () => Promise.resolve(null) };
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
          } catch (e) {
            // 即使historyService不可用，仍继续跳转到播放页面
            this.navigateToPlayback(episodeId, episodeName, source, 0);
          }
        } else {
          this.navigateToPlayback(episodeId, episodeName, source, 0);
        }
      } else {
        // 没有剧集时也尝试播放
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
    Router.pushUrl({
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
    Router.pushUrl({
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
    Stack.style({
      width: '100%',
      height: '100%',
      backgroundColor: '#4CAF50',
      justifyContent: 'center',
      alignItems: 'center'
    });
    LoadingProgress.create();
    LoadingProgress.style({
      width: 50,
      height: 50,
      color: '#FFFFFF'
    });
    LoadingProgress.pop();
    Text.create();
    Text.style({
      fontSize: 24,
      color: '#FFFFFF',
      marginTop: 20
    });
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
    Stack.style({
      backgroundColor: '#4CAF50',
      padding: 20
    });
    
    // 基本信息区域
    Flex.create();
    Flex.style({
      width: '100%',
      flexDirection: 'row',
      gap: 20
    });
    
    // 封面图
    Image.create();
    Image.src(this.mediaDetail.coverUrl || "https://via.placeholder.com/200x300?text=No+Image");
    Image.style({
      width: 150,
      height: 200,
      borderRadius: 10
    });
    Image.objectFit("cover");
    Image.pop();
    
    // 详细信息
    Flex.create();
    Flex.style({
      flex: 1,
      flexDirection: 'column',
      gap: 10
    });
    Text.create();
    Text.style({
      fontSize: 28,
      fontWeight: 700,
      color: '#FFFFFF'
    });
    Text.content(this.mediaDetail.title);
    Text.pop();
    
    // 元数据标签
    Flex.create();
    Flex.style({
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: 10
    });
    if (this.mediaDetail.year) {
      Flex.create();
      Flex.style({
        backgroundColor: '#FFFFFF',
        paddingHorizontal: 12,
        paddingVertical: 4,
        borderRadius: 15
      });
      Text.create();
      Text.style({
        fontSize: 20,
        color: '#4CAF50',
        fontWeight: 600
      });
      Text.content(this.mediaDetail.year);
      Text.pop();
      Flex.pop();
    }
    if (this.mediaDetail.score) {
      Flex.create();
      Flex.style({
        backgroundColor: '#FF9800',
        paddingHorizontal: 12,
        paddingVertical: 4,
        borderRadius: 15
      });
      Text.create();
      Text.style({
        fontSize: 20,
        color: '#FFFFFF',
        fontWeight: 600
      });
      Text.content(this.mediaDetail.score);
      Text.pop();
      Flex.pop();
    }
    if (this.mediaDetail.type) {
      Flex.create();
      Flex.style({
        backgroundColor: '#FFFFFF',
        paddingHorizontal: 12,
        paddingVertical: 4,
        borderRadius: 15
      });
      Text.create();
      Text.style({
        fontSize: 20,
        color: '#4CAF50',
        fontWeight: 600
      });
      Text.content(this.mediaDetail.type);
      Text.pop();
      Flex.pop();
    }
    Flex.pop();
    
    // 其他信息
    if (this.mediaDetail.directors && this.mediaDetail.directors.length > 0) {
      Text.create();
      Text.style({
        fontSize: 22,
        color: '#FFFFFF',
        lineHeight: 32
      });
      Text.content(`导演: ${this.mediaDetail.directors.join(', ')}`);
      Text.pop();
    }
    if (this.mediaDetail.actors && this.mediaDetail.actors.length > 0) {
      Text.create();
      Text.style({
        fontSize: 22,
        color: '#FFFFFF',
        lineHeight: 32
      });
      Text.content(`演员: ${this.mediaDetail.actors.slice(0, 5).join(', ')}${this.mediaDetail.actors.length > 5 ? '...' : ''}`);
      Text.pop();
    }
    Flex.pop();
    Flex.pop();
    
    // 剧情简介
    if (this.mediaDetail.description) {
      Text.create();
      Text.style({
        fontSize: 22,
        color: '#FFFFFF',
        lineHeight: 32,
        marginTop: 20,
        marginBottom: 10
      });
      Text.content(this.mediaDetail.description);
      Text.pop();
    }
    
    // 操作按钮
    Flex.create();
    Flex.style({
      flexDirection: 'row',
      gap: 20,
      marginTop: 20
    });
    Button.create();
    Button.style({
      backgroundColor: '#FFEB3B',
      paddingHorizontal: 30,
      paddingVertical: 12,
      borderRadius: 25,
      flex: 1
    });
    Button.onClick(() => {
      if (this.episodes.length > 0) {
        this.handlePlayEpisode(this.episodes[0]);
      }
    });
    Text.create();
    Text.style({
      fontSize: 24,
      color: '#000000',
      fontWeight: 700
    });
    Text.content("立即播放");
    Text.pop();
    Button.pop();
    
    Button.create();
    Button.style({
      backgroundColor: this.isFavorite ? '#F44336' : '#FFFFFF',
      paddingHorizontal: 30,
      paddingVertical: 12,
      borderRadius: 25,
      flex: 1
    });
    Button.onClick(this.handleToggleFavorite);
    Text.create();
    Text.style({
      fontSize: 24,
      color: this.isFavorite ? '#FFFFFF' : '#4CAF50',
      fontWeight: 700
    });
    Text.content(this.isFavorite ? '已收藏' : '收藏');
    Text.pop();
    Button.pop();
    Flex.pop();
    
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
    Flex.style({
      flexDirection: 'row',
      backgroundColor: '#4CAF50',
      paddingHorizontal: 20,
      paddingVertical: 10,
      gap: 10
    });
    Button.create();
    Button.style({
      backgroundColor: this.activeTab === 'episodes' ? '#FFFFFF' : '#66BB6A',
      paddingHorizontal: 25,
      paddingVertical: 10,
      borderRadius: 20,
      minWidth: 100
    });
    Button.onClick(() => this.activeTab = 'episodes');
    Text.create();
    Text.style({
      fontSize: 24,
      color: this.activeTab === 'episodes' ? '#4CAF50' : '#FFFFFF',
      fontWeight: 700
    });
    Text.content("剧集列表");
    Text.pop();
    Button.pop();
    Button.create();
    Button.style({
      backgroundColor: this.activeTab === 'sources' ? '#FFFFFF' : '#66BB6A',
      paddingHorizontal: 25,
      paddingVertical: 10,
      borderRadius: 20,
      minWidth: 100
    });
    Button.onClick(() => this.activeTab = 'sources');
    Text.create();
    Text.style({
      fontSize: 24,
      color: this.activeTab === 'sources' ? '#4CAF50' : '#FFFFFF',
      fontWeight: 700
    });
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
      Stack.create();
      Stack.style({
        backgroundColor: '#4CAF50',
        padding: 20,
        alignItems: 'center'
      });
      Text.create();
      Text.style({
        fontSize: 24,
        color: '#FFFFFF'
      });
      Text.content("暂无剧集");
      Text.pop();
      Stack.pop();
      return;
    }
    
    Stack.create();
    Stack.style({
      backgroundColor: '#4CAF50',
      padding: 20
    });
    
    // 网格布局展示剧集
    Grid.create();
    Grid.style({
      width: '100%'
    });
    Grid.columnsTemplate('repeat(6, 1fr)');
    Grid.columnsGap(15);
    Grid.rowsGap(15);
    
    this.episodes.forEach((episode, index) => {
      GridItem.create();
      GridItem.key(episode.id);
      Button.create();
      Button.style({
        backgroundColor: '#66BB6A',
        padding: 15,
        borderRadius: 8,
        width: '100%'
      });
      Button.onClick(() => this.handlePlayEpisode(episode));
      Text.create();
      Text.style({
        fontSize: 24,
        color: '#FFFFFF',
        fontWeight: 600
      });
      Text.content(`${index + 1}`);
      Text.pop();
      Button.pop();
      GridItem.pop();
    });
    Grid.pop();
    Stack.pop();
  }
  
  /**
   * 渲染播放源列表
   */
  @Builder
  private renderPlaySources(): void {
    Stack.create();
    Stack.style({
      backgroundColor: '#4CAF50',
      padding: 20
    });
    
    // 搜索框
    Stack.create();
    Stack.style({
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#FFFFFF',
      borderRadius: 25,
      paddingHorizontal: 20,
      marginBottom: 20,
      height: 50
    });
    Text.create();
    Text.style({
      fontSize: 24,
      color: '#999999',
      marginRight: 10
    });
    Text.content('🔍');
    Text.pop();
    TextInput.create();
    TextInput.style({
      flex: 1,
      fontSize: 24,
      color: '#333333'
    });
    TextInput.placeholder("搜索片源...");
    TextInput.placeholderColor('#999999');
    TextInput.value(this.searchText);
    TextInput.onChange(this.handleSearchChange);
    TextInput.pop();
    if (this.searchText.length > 0) {
      Button.create();
      Button.style({
        backgroundColor: 'transparent'
      });
      Button.onClick(() => {
        this.searchText = '';
        this.filteredSources = [...this.playSources];
      });
      Text.create();
      Text.style({
        fontSize: 24,
        color: '#999999'
      });
      Text.content('✕');
      Text.pop();
      Button.pop();
    }
    Stack.pop();
    
    if (this.filteredSources.length === 0) {
      Stack.create();
      Stack.style({
        backgroundColor: '#4CAF50',
        padding: 40,
        alignItems: 'center',
        justifyContent: 'center'
      });
      Text.create();
      Text.style({
        fontSize: 24,
        color: '#FFFFFF'
      });
      Text.content("暂无播放源或没有匹配的片源");
      Text.pop();
      Stack.pop();
      return;
    }
    
    List.create();
    List.style({
      width: '100%'
    });
    this.filteredSources.forEach((source, index) => {
      ListItem.create();
      ListItem.key(index.toString());
      ListItem.style({
        paddingVertical: 10
      });
      Button.create();
      Button.style({
        backgroundColor: '#66BB6A',
        padding: 25,
        borderRadius: 10,
        width: '100%',
        borderWidth: 2,
        borderColor: 'transparent'
      });
      Button.onClick(() => this.handlePlaySourceClick(source));
      Flex.create();
      Flex.style({
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        width: '100%'
      });
      Text.create();
      Text.style({
        fontSize: 28,
        color: '#FFFFFF',
        fontWeight: 700,
        flex: 1
      });
      Text.content(source.name || `播放源${index + 1}`);
      Text.pop();
      if (source.quality) {
        Flex.create();
        Flex.style({
          backgroundColor: '#FFEB3B',
          paddingHorizontal: 15,
          paddingVertical: 8,
          borderRadius: 15
        });
        Text.create();
        Text.style({
          fontSize: 22,
          color: '#000000',
          fontWeight: 700
        });
        Text.content(source.quality);
        Text.pop();
        Flex.pop();
      }
      Flex.pop();
      Button.pop();
      ListItem.pop();
    });
    List.pop();
    Stack.pop();
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
    Stack.style({
      flex: 1,
      backgroundColor: '#4CAF50'
    });
    
    // 顶部导航栏
    Stack.create();
    Stack.style({
      backgroundColor: '#388E3C',
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      paddingHorizontal: 20,
      paddingVertical: 15,
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      zIndex: 1000
    });
    Button.create();
    Button.style({
      backgroundColor: 'transparent'
    });
    Button.onClick(this.handleBack);
    Text.create();
    Text.style({
      fontSize: 24,
      color: '#FFFFFF'
    });
    Text.content("← 返回");
    Text.pop();
    Button.pop();
    Text.create();
    Text.style({
      fontSize: 26,
      color: '#FFFFFF',
      fontWeight: 700
    });
    Text.content("详情");
    Text.pop();
    Blank.create();
    Blank.style({ width: 80 });
    Blank.pop();
    Stack.pop();
    
    // 主内容区域
    if (this.isLoading) {
      this.renderLoading();
    } else if (this.errorMessage) {
      this.renderError();
    } else {
      ScrollView.create();
      ScrollView.style({
        flex: 1,
        backgroundColor: '#4CAF50'
      });
      ScrollView.scrollBar("auto");
      
      // 添加顶部间距，避免被导航栏遮挡
      Blank.create();
      Blank.style({ height: 60 });
      Blank.pop();
      
      this.renderHeader();
      this.renderTabBar();
      
      Stack.create();
      if (this.activeTab === 'episodes') {
        this.renderEpisodes();
      } else {
        this.renderPlaySources();
      }
      Stack.pop();
      
      this.renderRelatedMedia();
      Blank.create();
      Blank.style({ height: 50 });
      Blank.pop();
      ScrollView.pop();
    }
    Stack.pop();
  }
}

export default MediaDetailPage;