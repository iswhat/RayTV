// MediaDetailPage.ets
// 媒体详情页面组件 - Media detail page component

import { AppNavigator } from '../navigation/AppNavigator';
import { Vod } from '../data/bean/Vod';
import ContentAccessService from '../service/content/ContentAccessService';
import MediaDataFetcherService, { MediaDetail, EpisodeInfo, PlaySource, RelatedMedia } from '../service/media/MediaDataFetcherService';
import EventBusUtil from '../common/util/EventBusUtil';
import { Column, Row, Text, Button, ForEach, FlexAlign, HorizontalAlign, VerticalAlign, TextAlign, Scroll, BarState, ScrollDirection, EdgeEffect, Stack, Position, Image, ImageFit, GestureDirection, GestureEvent, PanGesture, GestureInfo } from '@ohos.arkui';
import DesignSystem from '../design/DesignSystem';
import AnimationSystem from '../design/AnimationSystem';
import ThemeProvider, { Theme } from '../design/ThemeProvider';
import Logger from '../common/util/Logger';

// Vod接口定义 - 用于向后兼容
interface Vod {
  id: string;
  name: string;
  type: string;
  area: string;
  lang: string;
  year: string;
  score: string;
  status: string;
  desc: string;
  cover: string;
  tag: string;
  url: string;
  sourceKey: string;
  createdAt: number;
  updatedAt: number;
}

// 播放源接口 - Play source interface
export interface PlaySource {
  name: string;
  quality?: string;
}

// 剧集接口 - Episode interface
export interface Episode {
  id: string;
  name: string;
  url: string;
}

// 相关媒体链接接口 - Related media link interface
export interface MediaItem {
  title: string;
  cover: string;
  url: string;
  sourceId?: string;
  sourceName?: string;
}

@Entry
@Component
struct MediaDetailPage {
  private readonly TAG: string = 'MediaDetailPage';
  private contentService: ContentAccessService = ContentAccessService.getInstance();
  private mediaDataFetcher: MediaDataFetcherService = MediaDataFetcherService.getInstance();
  private eventBus: EventBusUtil = EventBusUtil.getInstance();
  private mediaId: string = '';
  private scroller: Scroller = new Scroller();
  
  @State mediaDetailData: MediaDetail | null = null;
  @State currentEpisodeId: string = '';
  @State playSources: PlaySource[] = [];
  @State selectedPlaySource: PlaySource | null = null;
  @State isParsing: boolean = false;
  @State parseError: string = '';
  @State activeTab: string = 'info';
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '';
  @State currentTheme: Theme = ThemeProvider.getCurrentTheme();
  
  // 临时属性，用于向后兼容 - Temporary properties for backward compatibility
  private media: Vod = {
    id: '',
    name: '',
    type: '',
    area: '',
    lang: '',
    year: '',
    score: '',
    status: '',
    desc: '',
    cover: '',
    tag: '',
    url: '',
    sourceKey: '',
    createdAt: 0,
    updatedAt: 0
  };
  private episodes: Episode[] = [];
  private filteredSources: PlaySource[] = [];
  private relatedMedia: MediaItem[] = [];
  private isFavorite: boolean = false;
  
  // 资源管理相关 - Resource management related
  private mediaPlayer: Object | null = null;
  private progressUpdateTimer: number = 0;
  private themeChangeListener: (theme: Theme) => void = (theme: Theme) => {
    this.currentTheme = theme;
  };
  
  // 释放资源 - Release resources
  private releaseResources(): void {
    this.media = {
      id: '',
      name: '',
      type: '',
      area: '',
      lang: '',
      year: '',
      score: '',
      status: '',
      desc: '',
      cover: '',
      tag: '',
      url: '',
      sourceKey: '',
      createdAt: 0,
      updatedAt: 0
    };
    this.episodes = [];
    this.filteredSources = [];
    this.relatedMedia = [];
    this.mediaDetailData = null;
  }

  aboutToAppear(): void {
    this.mediaId = this.getMediaIdFromParams() || '';
    
    // 添加主题变更监听器
    ThemeProvider.addThemeChangeListener(this.themeChangeListener);
    
    // 监听播放进度更新
    this.eventBus.on('playback:progressUpdated', (data: Record<string, unknown>) => {
      // 记录播放进度
      if (data.videoId && data.progress) {
        this.recordPlaybackProgress(data.videoId as string, data.progress as number);
      }
    });
    
    this.loadMediaDetail();
    this.loadEpisodes();
    this.loadSources();
    this.loadRelatedMedia();
  }
  
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'MediaDetailPage about to disappear');
    
    // 移除事件监听器
    this.eventBus.off('playback:progressUpdated');
    this.eventBus.off('playback:error');
    this.eventBus.off('playback:complete');
    
    // 清除定时器
    if (this.progressUpdateTimer !== 0) {
      clearInterval(this.progressUpdateTimer);
      this.progressUpdateTimer = 0;
    }
    
    // 释放媒体播放器
    if (this.mediaPlayer != null) {
      try {
        // 停止和释放播放器资源
        this.mediaPlayer = null;
      } catch (error) {
        const err = error instanceof Error ? error : new Error(String(error));
        Logger.error(this.TAG, 'Failed to release media player', err);
      }
    }
    
    // 移除主题监听器
    ThemeProvider.removeThemeChangeListener(this.themeChangeListener);
    
    // 释放资源
    this.releaseResources();
  }

  /**
   * 加载媒体详情 - Load media details
   */
  private async loadMediaDetail(): Promise<void> {
    try {
      this.isLoading = true;
      this.isError = false;
      
      if (!this.mediaId) {
        throw new Error('Media ID not found');
      }
      
      // 使用MediaDataFetcherService获取媒体详情
      const detail = await this.mediaDataFetcher.getMediaDetail(this.mediaId);
      
      if (!detail) {
        throw new Error('Failed to fetch media detail');
      }
      
      // 保存媒体详情
      this.mediaDetailData = detail;
      
      // 转换为Vod格式（用于显示）
      this.media = {
        id: detail.id,
        name: detail.title,
        type: detail.type,
        area: detail.area,
        lang: detail.lang,
        year: detail.year,
        score: detail.score,
        status: detail.status,
        desc: detail.desc,
        cover: detail.cover,
        tag: detail.tags.join(','),
        url: '',
        sourceKey: '',
        createdAt: detail.releaseDate || Date.now(),
        updatedAt: Date.now()
      };
      
      // 发布媒体加载事件
      this.eventBus.publish('media:detailLoaded', {
        mediaId: detail.id,
        title: detail.title,
        type: detail.type
      });
      
      console.info(`Media detail loaded: ${detail.title}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.isError = true;
      this.errorMessage = err.message;
      console.error(`加载媒体详情失败: ${err.message}`);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 加载剧集列表 - Load episode list
   */
  private async loadEpisodes(): Promise<void> {
    try {
      if (!this.mediaId) {
        this.episodes = [];
        return;
      }
      
      const sites = this.contentService.getAllVodSites();
      if (sites.length === 0) {
        this.episodes = [];
        return;
      }
      
      // 生成剧集列表
      this.episodes = Array.from({ length: 12 }, (_, i) => ({
        id: `ep${i + 1}`,
        name: `第${i + 1}集`,
        url: `episode_${i + 1}`
      }));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(`加载剧集列表失败: ${err.message}`);
      this.episodes = [];
    }
  }

  /**
   * 加载播放源 - Load play sources
   */
  private async loadSources(): Promise<void> {
    try {
      if (!this.mediaId) {
        this.filteredSources = [];
        return;
      }
      
      const sites = this.contentService.getAllVodSites();
      if (sites.length === 0) {
        this.filteredSources = [];
        return;
      }
      
      // 从站点生成播放源
      this.filteredSources = sites.map(site => ({
        name: site.name,
        quality: '高清'
      }));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(`加载播放源失败: ${err.message}`);
      this.filteredSources = [];
    }
  }

  /**
   * 加载相关推荐 - Load related recommendations
   */
  private async loadRelatedMedia(): Promise<void> {
    try {
      const sites = this.contentService.getAllVodSites();
      if (sites.length === 0) {
        this.relatedMedia = [];
        return;
      }
      
      // 基于站点数据生成相关推荐
      this.relatedMedia = sites.slice(0, 6).map((site) => ({
        title: `${site.name} - 相关推荐`,
        cover: '',
        url: `related_${site.siteKey}`,
        sourceId: site.sourceId,
        sourceName: site.sourceName
      }));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(`加载相关推荐失败: ${err.message}`);
      this.relatedMedia = [];
    }
  }
  
  /**
   * 从路由参数获取媒体ID - Get media ID from route params
   */
  private getMediaIdFromParams(): string | null {
    // 实际实现应该从路由参数获取媒体ID - Actual implementation should get media ID from route params
    // 由于router模块不可用，返回默认值 - Return default value since router module is not available
    return '1'; // 默认值用于演示 - Default value for demonstration
  }
  
  /**
   * 记录播放进度 - Record playback progress
   */
  private recordPlaybackProgress(videoId: string, progress: number): void {
    try {
      Logger.info(this.TAG, `Recording progress for ${videoId}: ${progress}%`);
      // 实际实现应该将播放进度保存到本地存储 - Actual implementation should save progress to local storage
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, 'Failed to record playback progress', err);
    }
  }

  /**
   * 渲染剧集列表 - Render episode list
   */
  @Builder
  private renderEpisodes() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    // 剧集网格布局 - Episode grid layout
    Column() {
      // 使用ForEach渲染剧集列表 - Use ForEach to render episode list
      ForEach(this.episodes, (episode: Episode, index: number) => {
        if (index % 6 === 0) {
          // 每6个剧集开始一个新行 - Start a new row every 6 episodes
          Row() {
            ForEach(this.episodes.slice(index, index + 6), (ep: Episode, idx: number) => {
              Button(ep.name || (index + idx + 1).toString())
                .backgroundColor(colors.primary)
                .fontColor(colors.surface)
                .padding(spacing.md)
                .borderRadius(borderRadius.md)
                .fontSize(16)
                .flexGrow(1)
                .margin({ right: idx < 5 ? spacing.sm : 0 })
                .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
                .onClick(() => {
                  this.handleEpisodeClick(ep);
                })
                .animation({
                  duration: 300,
                  timingFunction: 'ease-out'
                })
            }, (ep: Episode) => ep.id)
          }
          .margin({ bottom: spacing.sm })
        }
      }, (episode: Episode) => episode.id)
    }
    .width('100%')
    .height('auto');
  }

  /**
   * 渲染播放源 - Render play sources
   */
  @Builder
  private renderPlaySources() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Column() {
      ForEach(this.filteredSources, (source: PlaySource) => {
        Button() {
          Row() {
            Column() {
              Text(source.name || "")
                .fontSize(20)
                .fontColor(colors.surface);
              Text(source.quality || "")
                .fontSize(16)
                .fontColor(colors.surface);
            }
            .alignItems(HorizontalAlign.Start);

            Text('▶')
              .fontSize(24)
              .fontColor(colors.surface);
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .width('100%');
        }
        .backgroundColor(colors.primary)
        .padding(spacing.md)
        .borderRadius(borderRadius.lg)
        .margin({ bottom: spacing.md })
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
        .onClick(() => {
          const episode = this.episodes.length > 0 ? this.episodes[0] : { id: '', name: '', url: '' };
          this.handlePlayClick(episode, source);
        })
        .animation({
          duration: 300,
          timingFunction: 'ease-out'
        })
      }, (source: PlaySource) => source.name);
    }
  }
  
  /**
   * 渲染空播放源提示 - Render empty play sources hint
   */
  @Builder
  private renderEmptyPlaySources() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    
    Column() {
      Text('😔')
        .fontSize(64)
        .margin({ bottom: spacing.md })
      Text('暂无播放源或没有匹配的片源')
        .fontSize(18)
        .fontColor(colors.textSecondary)
        .textAlign(TextAlign.Center)
        .width('80%')
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(20)
    .height(300)
  }

  /**
   * 渲染相关推荐 - Render related recommendations
   */
  @Builder
  private renderRelatedMedia() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Column() {
      Text('相关推荐')
        .fontSize(22)
        .fontColor(colors.text)
        .fontWeight(600)
        .margin({ bottom: spacing.md });
      
      // 横向滚动的相关推荐列表 - Horizontal scrolling related recommendation list
      Scroll({
        scroller: new Scroller(),
        scrollDirection: ScrollDirection.Horizontal
      }) {
        Row() {
          ForEach(this.relatedMedia, (media: MediaItem) => {
            Column() {
              // 相关推荐封面 - Related recommendation cover
              Column() {
                Text('🎬')
                  .fontSize(32)
                  .fontColor(colors.textSecondary);
              }
              .width(160)
              .height(220)
              .backgroundColor(colors.surface)
              .borderRadius(borderRadius.md)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 4 })
              
              // 相关推荐标题 - Related recommendation title
              Text(media.title || "")
                .fontSize(14)
                .fontColor(colors.text)
                .maxLines(2)
                .width(160)
                .margin({ top: spacing.sm })
                .textAlign(TextAlign.Center)
            }
            .width(180)
            .margin({ right: spacing.md })
            .onClick(() => this.handleRelatedMediaClick(media))
            .animation({
              duration: 300,
              timingFunction: 'ease-out'
            })
          });
        }
        .width('100%');
      }
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  /**
   * 处理剧集点击 - Handle episode click
   */
  private handleEpisodeClick(episode: Episode): void {
    console.info(`点击剧集: ${episode.name} | Clicked episode: ${episode.name}`);
    // 处理剧集点击逻辑 - Handle episode click logic
  }

  /**
   * 处理播放点击 - Handle play click
   */
  private handlePlayClick(episode: Episode, source: PlaySource): void {
    console.info(`正在播放剧集 ${episode.name} 来自 ${source.name} | Playing episode ${episode.name} from ${source.name}`);
    // 处理播放点击逻辑 - Handle play click logic
  }

  /**
   * 处理相关媒体点击 - Handle related media click
   */
  private handleRelatedMediaClick(media: MediaItem): void {
    console.info(`点击相关媒体: ${media.title} | Clicked related media: ${media.title}`);
    // 处理相关媒体点击逻辑 - Handle related media click logic
  }

  /**
   * 处理返回 - Handle back
   */
  private handleBack(): void {
    AppNavigator.getInstance().navigateToBack();
  }

  /**
   * 处理收藏 - Handle favorite
   */
  private handleFavorite(): void {
    this.isFavorite = !this.isFavorite;
    console.info(`Media ${this.isFavorite ? 'added to' : 'removed from'} favorites`);
  }

  build() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Column() {
      // 顶部导航栏 | Top navigation bar
      Row() {
        // 返回按钮 | Back button
        Button() {
          Text('←')
            .fontSize(24)
            .fontColor(colors.surface)
        }
        .width(56)
        .height(56)
        .backgroundColor(colors.primary)
        .borderRadius(borderRadius.full)
        .margin({ left: spacing.lg })
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
        .onClick(() => this.handleBack())
        .animation({
          duration: 300,
          timingFunction: 'ease-out'
        })
        
        // 标题 | Title
        Text('媒体详情')
          .fontSize(24)
          .fontWeight(700)
          .fontColor(colors.text)
          .flexGrow(1)
          .margin({ left: spacing.lg })
          .textAlign(TextAlign.Start)
        
        // 收藏按钮 | Favorite button
        Button() {
          Text(this.isFavorite ? '❤️' : '🤍')
            .fontSize(24)
        }
        .width(56)
        .height(56)
        .backgroundColor(colors.surface)
        .borderRadius(borderRadius.full)
        .margin({ right: spacing.lg })
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
        .onClick(() => this.handleFavorite())
        .animation({
          duration: 300,
          timingFunction: 'ease-out'
        })
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(colors.surface)
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 4 })
      
      // 内容区域 | Content area
      Scroll(this.scroller) {
        Column() {
          if (this.isLoading) {
            Column() {
              Text('加载中...')
                .fontSize(20)
                .fontColor(colors.textSecondary)
                .margin(20)
            }
            .justifyContent(FlexAlign.Center)
            .height(500)
          } else if (this.isError) {
            Column() {
              Text('加载失败')
                .fontSize(20)
                .fontColor(colors.error)
                .margin({ top: 15 })
              Text(this.errorMessage)
                .fontSize(16)
                .fontColor(colors.textSecondary)
                .margin({ top: 8, left: 30, right: 30 })
                .textAlign(TextAlign.Center)
              Button('重试')
                .onClick(() => {
                  this.loadMediaDetail();
                  this.loadEpisodes();
                  this.loadSources();
                  this.loadRelatedMedia();
                })
                .backgroundColor(colors.primary)
                .fontColor(colors.surface)
                .borderRadius(borderRadius.md)
                .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                .margin({ top: 20 })
                .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
            }
            .justifyContent(FlexAlign.Center)
            .height(500)
          } else {
            // 媒体信息 | Media info
            Column() {
              // 封面和基本信息 | Cover and basic info
              Row() {
                // 封面 | Cover
                Column()
                  .width(180)
                  .height(240)
                  .backgroundColor(colors.surface)
                  .borderRadius(borderRadius.lg)
                  .margin({ right: spacing.lg })
                  .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 8 })
                
                // 基本信息 | Basic info
                Column() {
                  Text(this.media.name)
                    .fontSize(28)
                    .fontWeight(700)
                    .fontColor(colors.text)
                    .margin({ bottom: spacing.sm })
                    .animation({
                      duration: 500,
                      timingFunction: 'ease-out'
                    })
                  
                  Row() {
                    Stack() {
                      Text(`评分: ${this.media.score}`)
                        .fontSize(16)
                        .fontColor(colors.textSecondary)
                    }
                    .backgroundColor(`${colors.primary}20`)
                    .padding({ left: spacing.sm, right: spacing.sm, top: spacing.xs, bottom: spacing.xs })
                    .borderRadius(borderRadius.sm)
                    .margin({ right: spacing.md })
                    .animation({
                      duration: 500,
                      delay: 100,
                      timingFunction: 'ease-out'
                    })
                    
                    Stack() {
                      Text(`年份: ${this.media.year}`)
                        .fontSize(16)
                        .fontColor(colors.textSecondary)
                    }
                    .backgroundColor(`${colors.primary}20`)
                    .padding({ left: spacing.sm, right: spacing.sm, top: spacing.xs, bottom: spacing.xs })
                    .borderRadius(borderRadius.sm)
                    .margin({ right: spacing.md })
                    .animation({
                      duration: 500,
                      delay: 150,
                      timingFunction: 'ease-out'
                    })
                    
                    Stack() {
                      Text(`地区: ${this.media.area}`)
                        .fontSize(16)
                        .fontColor(colors.textSecondary)
                    }
                    .backgroundColor(`${colors.primary}20`)
                    .padding({ left: spacing.sm, right: spacing.sm, top: spacing.xs, bottom: spacing.xs })
                    .borderRadius(borderRadius.sm)
                    .animation({
                      duration: 500,
                      delay: 200,
                      timingFunction: 'ease-out'
                    })
                  }
                  .margin({ bottom: spacing.md })
                  
                  Row() {
                    Stack() {
                      Text(`类型: ${this.media.type}`)
                        .fontSize(16)
                        .fontColor(colors.textSecondary)
                    }
                    .backgroundColor(`${colors.primary}20`)
                    .padding({ left: spacing.sm, right: spacing.sm, top: spacing.xs, bottom: spacing.xs })
                    .borderRadius(borderRadius.sm)
                    .margin({ right: spacing.md })
                    .animation({
                      duration: 500,
                      delay: 250,
                      timingFunction: 'ease-out'
                    })
                    
                    Stack() {
                      Text(`状态: ${this.media.status}`)
                        .fontSize(16)
                        .fontColor(colors.textSecondary)
                    }
                    .backgroundColor(`${colors.primary}20`)
                    .padding({ left: spacing.sm, right: spacing.sm, top: spacing.xs, bottom: spacing.xs })
                    .borderRadius(borderRadius.sm)
                    .animation({
                      duration: 500,
                      delay: 300,
                      timingFunction: 'ease-out'
                    })
                  }
                  .margin({ bottom: spacing.md })
                  
                  // 立即播放按钮
                  Button('立即播放')
                    .fontSize(18)
                    .fontColor(colors.surface)
                    .backgroundColor(colors.primary)
                    .borderRadius(borderRadius.full)
                    .padding({ left: spacing.xl, right: spacing.xl, top: spacing.md, bottom: spacing.md })
                    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
                    .onClick(() => {
                      const episode = this.episodes.length > 0 ? this.episodes[0] : { id: '', name: '', url: '' };
                      const source = this.filteredSources.length > 0 ? this.filteredSources[0] : { name: '默认源' };
                      this.handlePlayClick(episode, source);
                    })
                    .animation({
                      duration: 500,
                      delay: 350,
                      timingFunction: 'ease-out'
                    })
                }
                .flexGrow(1)
              }
              .width('100%')
              .padding({ left: spacing.lg, right: spacing.lg, top: spacing.lg })
              
              // 剧情简介 | Synopsis
              Column() {
                Text('剧情简介')
                  .fontSize(20)
                  .fontWeight(600)
                  .fontColor(colors.text)
                  .margin({ bottom: spacing.sm })
                  .animation({
                    duration: 500,
                    timingFunction: 'ease-out'
                  })
                
                Text(this.media.desc)
                  .fontSize(16)
                  .fontColor(colors.text)
                  .lineHeight(24)
                  .animation({
                    duration: 500,
                    delay: 100,
                    timingFunction: 'ease-out'
                  })
              }
              .width('100%')
              .padding({ left: spacing.lg, right: spacing.lg, top: spacing.lg })
              
              // 标签栏 | Tab bar
              Row() {
                Button() {
                  Text('剧集')
                    .fontSize(18)
                    .fontColor(this.activeTab === 'episodes' ? colors.surface : colors.text);
                }
                .backgroundColor(this.activeTab === 'episodes' ? colors.primary : colors.surface)
                .borderRadius(borderRadius.md)
                .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
                .margin({ right: spacing.md })
                .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
                .onClick(() => {
                  this.activeTab = 'episodes';
                })
                .animation({
                  duration: 300,
                  timingFunction: 'ease-out'
                })
                
                Button() {
                  Text('播放源')
                    .fontSize(18)
                    .fontColor(this.activeTab === 'sources' ? colors.surface : colors.text);
                }
                .backgroundColor(this.activeTab === 'sources' ? colors.primary : colors.surface)
                .borderRadius(borderRadius.md)
                .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
                .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
                .onClick(() => {
                  this.activeTab = 'sources';
                })
                .animation({
                  duration: 300,
                  timingFunction: 'ease-out'
                })
              }
              .width('100%')
              .padding({ left: spacing.lg, right: spacing.lg, top: spacing.lg })
              
              // 内容区域 | Content area
              Column() {
                if (this.activeTab === 'episodes') {
                  this.renderEpisodes();
                } else if (this.activeTab === 'sources') {
                  if (this.filteredSources.length === 0) {
                    this.renderEmptyPlaySources();
                  } else {
                    this.renderPlaySources();
                  }
                }
              }
              .width('100%')
              .padding({ left: spacing.lg, right: spacing.lg, top: spacing.lg })
              
              // 相关推荐 - Related recommendations
              this.renderRelatedMedia()
              .width('100%')
              .padding({ left: spacing.lg, right: spacing.lg, top: spacing.lg, bottom: spacing.xl })
            }
          }
        }
        .width('100%')
      }
      .scrollBar(BarState.Auto)
      .flexGrow(1)
      .backgroundColor(colors.background)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.background)
  }
}

export default MediaDetailPage;