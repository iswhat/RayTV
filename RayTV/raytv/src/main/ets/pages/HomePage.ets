// HomePage组件 - Home page component
import { AppNavigator, PageRoute } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ContentAccessService from '../service/content/ContentAccessService';
import { MediaItem } from '../data/bean/MediaItem';
import NASDiscoveryService from '../service/nas/NASDiscoveryService';
import router from '@ohos.router';
import display from '@ohos.display';

import { Column, Row, Text, Button, Image, Scroll, ForEach, FlexAlign, TextAlign, VerticalAlign, BarState, ImageFit, Progress, ProgressType, ItemAlign, ScrollDirection, EdgeEffect, Stack, Position, HorizontalAlign, Alignment, GestureDirection, GestureType, GestureEvent, PanGesture, GestureInfo, Grid, GridItem, View, WindowStage } from '@ohos.arkui';
import VirtualList from '../components/VirtualList';
import { VirtualListItem } from '../types/VirtualListTypes';
import { SkeletonScreen } from '../components/SkeletonScreen';
import ContentSourceBadge from '../components/ContentSourceBadge';
import DesignSystem from '../design/DesignSystem';
import AnimationSystem from '../design/AnimationSystem';
import ThemeProvider, { Theme } from '../design/ThemeProvider';
import { ResponsiveLayoutSystem, Breakpoint, ResponsiveContainer, ResponsiveGrid, ResponsiveGridItem } from '../common/layout/ResponsiveLayoutSystem';

// 媒体推荐结果项类型 | Media recommended result item type
interface RecommendedMediaItem {
  id: string;
  title: string;
  cover?: string;
  siteKey: string;
  rating?: string;
  sourceId?: string;
  sourceName?: string;
}

/**
 * 首页组件 | Home page component
 * 展示推荐媒体内容和功能入口 | Display recommended media content and feature entries
 */
@Entry
@Component
struct HomePage {
  private readonly TAG: string = 'HomePage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State isLoading: boolean = false;
  @State recommendedMedia: MediaItem[] = [];
  @State popularMedia: MediaItem[] = [];
  @State newMedia: MediaItem[] = [];
  @State errorMessage: string = '';
  @State currentTheme: Theme = ThemeProvider.getCurrentTheme();
  @State showQuickActions: boolean = false;
  @State currentBreakpoint: Breakpoint = 'md';
  
  // 监听器 | Listeners
  private themeChangeListener: ((theme: Theme) => void) | null = null;
  
  // 服务实例 | Service instances
  private contentService: ContentAccessService = ContentAccessService.getInstance();
  private layoutSystem: ResponsiveLayoutSystem = ResponsiveLayoutSystem.getInstance();

  // 初始化页面 | Initialize page
  async aboutToAppear(): Promise<void> {
    Logger.info(this.TAG, 'HomePage mounted');
    
    // 添加主题变更监听器 | Add theme change listener
    this.themeChangeListener = (theme) => {
      this.currentTheme = theme;
    };
    ThemeProvider.addThemeChangeListener(this.themeChangeListener);
    
    // 添加断点变化监听器 | Add breakpoint listener
    this.layoutSystem.addBreakpointListener(this.handleBreakpointChange);
    // 获取当前断点 | Get current breakpoint
    this.currentBreakpoint = this.layoutSystem.getCurrentBreakpoint();
    // 获取屏幕宽度 | Get screen width
    this.updateScreenWidth();
    await this.loadHomePageData();
  }
  
  // 清理资源 | Clean up resources
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'HomePage unmounted');
    
    // 移除主题监听器 | Remove theme listener
    if (this.themeChangeListener) {
      ThemeProvider.removeThemeChangeListener(this.themeChangeListener);
      this.themeChangeListener = null;
    }
    
    // 移除断点变化监听器 | Remove breakpoint listener
    this.layoutSystem.removeBreakpointListener(this.handleBreakpointChange);
  }
  
  // 处理断点变化 | Handle breakpoint change
  private handleBreakpointChange = (breakpoint: Breakpoint): void => {
    this.currentBreakpoint = breakpoint;
    Logger.info(this.TAG, `Breakpoint changed to: ${breakpoint}`);
  };
  
  // 更新屏幕宽度 | Update screen width
  private updateScreenWidth(): void {
    try {
      // 在HarmonyOS中，尝试从display模块获取屏幕宽度
      const displayInfo = display.getDefaultDisplaySync();
      const screenWidth: number = displayInfo.width;
      this.layoutSystem.updateScreenWidth(screenWidth);
      Logger.info(this.TAG, `Screen width updated to: ${screenWidth}`);
    } catch (error: unknown) {
      Logger.error(this.TAG, `Failed to get screen width: ${error instanceof Error ? error.message : String(error)}`);
      // 失败时使用默认值 | Use default value on failure
      const defaultWidth: number = 1080; // 默认宽度
      this.layoutSystem.updateScreenWidth(defaultWidth);
    }
  }
  
  /**
   * 加载首页数据 | Load home page data
   */
  private async loadHomePageData(): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';

      Logger.info(this.TAG, 'Loading home page data');

      await this.fetchMediaData();
      
      // 检查是否有数据
      const hasData: boolean = this.recommendedMedia.length > 0 || 
                     this.popularMedia.length > 0 || 
                     this.newMedia.length > 0;

      if (!hasData) {
        await this.loadFallbackData();
      }

      Logger.info(this.TAG, `Home page data loaded: recommended=${this.recommendedMedia.length}, popular=${this.popularMedia.length}, new=${this.newMedia.length}`);
    } catch (error: unknown) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to load home page data: ${err.message}`);
      this.errorMessage = '加载数据失败，请稍后重试';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 获取媒体数据 | Fetch media data
   */
  private async fetchMediaData(): Promise<void> {
    // 导入MovieService
    const MovieService = await import('../service/media/MovieService');
    const movieService = MovieService.default.getInstance();

    // 并行获取不同类型的内容
    const [trendingResponse, popularResponse, newResponse] = await Promise.all([
      movieService.getTrending('all', 6),
      movieService.getPopular('all', 6),
      movieService.getNewReleases('all', 6)
    ]);

    // 处理热门内容
    this.processTrendingData(trendingResponse);
    // 处理热播内容
    this.processPopularData(popularResponse);
    // 处理最新内容
    this.processNewReleasesData(newResponse);
  }
  
  /**
   * 处理热门内容 | Process trending content
   */
  private processTrendingData(response: any): void {
    if (response.isSuccess() && response.data) {
      this.recommendedMedia = response.data.map((item: any) => ({
        id: item.id,
        title: item.title,
        coverUrl: item.posters?.[0]?.url || '',
        score: item.rating?.score?.toString() || '0',
        sourceId: 'api',
        sourceName: 'API'
      }));
    }
  }
  
  /**
   * 处理热播内容 | Process popular content
   */
  private processPopularData(response: any): void {
    if (response.isSuccess() && response.data) {
      this.popularMedia = response.data.map((item: any) => ({
        id: item.id,
        title: item.title,
        coverUrl: item.posters?.[0]?.url || '',
        score: item.rating?.score?.toString() || '0',
        sourceId: 'api',
        sourceName: 'API'
      }));
    }
  }
  
  /**
   * 处理最新内容 | Process new releases content
   */
  private processNewReleasesData(response: any): void {
    if (response.isSuccess() && response.data) {
      this.newMedia = response.data.map((item: any) => ({
        id: item.id,
        title: item.title,
        coverUrl: item.posters?.[0]?.url || '',
        score: item.rating?.score?.toString() || '0',
        sourceId: 'api',
        sourceName: 'API'
      }));
    }
  }
  
  /**
   * 加载备用数据 | Load fallback data
   */
  private async loadFallbackData(): Promise<void> {
    // 尝试从站点获取备用数据
    const sites = this.contentService.getAllVodSites();
    if (sites.length > 0) {
      const allMediaItems: MediaItem[] = await this.processSiteMedia(sites);
      
      if (allMediaItems.length > 0) {
        this.distributeFallbackMedia(allMediaItems);
      } else {
        this.errorMessage = '暂无内容，请在设置中添加网络源';
      }
    } else {
      this.errorMessage = '暂无内容，请在设置中添加网络源';
    }
  }
  
  /**
   * 处理站点媒体数据 | Process site media data
   */
  private async processSiteMedia(sites: any[]): Promise<MediaItem[]> {
    const allMediaItems: MediaItem[] = [];
    for (const site of sites) {
      try {
        const mediaItems: MediaItem[] = this.getMediaItemsFromSite(site);
        allMediaItems.push(...mediaItems);
      } catch (error: unknown) {
        Logger.warn(this.TAG, `Failed to load media from site ${site.name}`);
      }
    }
    return allMediaItems;
  }
  
  /**
   * 分发备用媒体数据 | Distribute fallback media data
   */
  private distributeFallbackMedia(mediaItems: MediaItem[]): void {
    // 按评分排序
    mediaItems.sort((a: MediaItem, b: MediaItem) => {
      const scoreA: number = parseFloat(a.score || '0');
      const scoreB: number = parseFloat(b.score || '0');
      return scoreB - scoreA;
    });
    
    // 分配到不同的媒体列表
    this.recommendedMedia = mediaItems.slice(0, 6);
    this.popularMedia = mediaItems.slice(6, 12);
    this.newMedia = mediaItems.slice(12, 18);
  }
  
  /**
   * 从站点获取媒体项（兼容方法）
   */
  private getMediaItemsFromSite(site: any): MediaItem[] {
    try {
      // 基于站点数据生成模拟媒体项
      // 在实际实现中，应该调用真实的API获取媒体内容
      const mediaCount: number = Math.max(1, Math.floor(Math.random() * 5));
      const mediaItems: MediaItem[] = [];
      
      for (let i = 0; i < mediaCount; i++) {
        mediaItems.push({
          id: `${site.siteKey}_${site.sourceId}_${i}`,
          title: `${site.name} - 内容${i + 1}`,
          coverUrl: '',
          siteKey: site.siteKey,
          score: (7.5 + Math.random() * 2).toFixed(1),
          sourceId: site.sourceId,
          sourceName: site.sourceName
        });
      }
      
      return mediaItems;
    } catch (error: unknown) {
      Logger.warn(this.TAG, `Failed to get media items from site: ${site.name}`);
      return [];
    }
  }
  
  /**
   * 处理搜索 | Handle search
   */
  private handleSearch(): void {
    try {
      Logger.info(this.TAG, 'Search button clicked');
      // 跳转到搜索页面 | Navigate to search page
      AppNavigator.getInstance().navigateToSearch('');
    } catch (error: unknown) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to search page: ${err.message}`);
    }
  }
  
  /**
   * 处理媒体项点击 | Handle media item click
   */
  private handleMediaItemClick(media: MediaItem): void {
    try {
      Logger.info(this.TAG, `Media item clicked: ${media.title}, Source: ${media.sourceName}`);

      // 验证媒体数据完整性 | Validate media data integrity
      if (!media.id || !media.siteKey) {
        Logger.error(this.TAG, 'Invalid media data: missing required fields');
        return;
      }

      // 跳转到详情页 | Navigate to detail page
      AppNavigator.getInstance().navigateToDetail({
        id: media.id,
        siteKey: media.siteKey || '',
        type: 'movie'
      });
    } catch (error: unknown) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to detail page: ${err.message}`);
    }
  }
  
  /**
   * 处理直播入口点击 | Handle live entry click
   */
  private handleLiveClick(): void {
    try {
      Logger.info(this.TAG, 'Live entry clicked');
      // 跳转到直播页面 | Navigate to live page
      AppNavigator.getInstance().navigateToLive();
    } catch (error: unknown) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to live page: ${err.message}`);
    }
  }
  
  /**
   * 处理设置入口点击 | Handle settings entry click
   */
  private handleSettingsClick(): void {
    try {
      Logger.info(this.TAG, 'Settings entry clicked');
      // 跳转到设置页面 | Navigate to settings page
      AppNavigator.getInstance().navigateToSettings();
    } catch (error: unknown) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to settings page: ${err.message}`);
    }
  }
  
  /**
   * 处理分类入口点击 | Handle category entry click
   */
  private handleCategoryClick(category: string): void {
    try {
      Logger.info(this.TAG, `Category clicked: ${category}`);
      // 跳转到分类页面 | Navigate to category page
      AppNavigator.getInstance().navigateToCategory(category);
    } catch (error: unknown) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to category page: ${err.message}`);
    }
  }
  
  /**
   * 处理NAS设备管理入口点击 | Handle NAS management entry click
   */
  private handleNASManagementClick(): void {
    try {
      Logger.info(this.TAG, 'NAS management entry clicked');
      // 跳转到NAS管理页面 | Navigate to NAS management page
      router.push({
        url: '/pages/NASManagementPage'
      });
    } catch (error: unknown) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to NAS management page: ${err.message}`);
    }
  }
  
  /**
   * 将MediaItem转换为VirtualListItem | Convert MediaItem to VirtualListItem
   */
  private convertToVirtualItems(mediaList: MediaItem[]): VirtualListItem[] {
    const virtualItems: VirtualListItem[] = [];
    const itemWidth: number = this.getMediaItemWidth();
    const itemHeight: number = this.getMediaItemHeight();
    
    for (let i = 0; i < mediaList.length; i++) {
      const media: MediaItem = mediaList[i];
      const virtualItem: VirtualListItem = {
        id: `${media.id}_${media.sourceId || 'default'}`,
        index: i,
        data: media,
        top: 0,
        left: i * (itemWidth + 20), // 项目宽度加上间距
        height: itemHeight,
        width: itemWidth,
        visible: false
      };
      virtualItems.push(virtualItem);
    }
    return virtualItems;
  }
  
  /**
   * 构建页面UI | Build page UI
   */
  build() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    const shadows = this.currentTheme.shadows;
    
    Scroll(this.scroller) {
      ResponsiveContainer({
        type: 'fixed',
        fluidBreakpoint: 'lg'
      }) {
        Column() {
          // 页面头部 | Page header
          Stack() {
            Row() {
              Column() {
                Text('RayTV')
                  .fontSize(this.getHeaderFontSize())
                  .fontWeight(700)
                  .fontColor(colors.primary)
                  .animation({
                    duration: 800,
                    timingFunction: 'ease-out'
                  })
                Text('发现精彩内容')
                  .fontSize(14)
                  .fontColor(colors.textSecondary)
                  .margin({ top: spacing.xs })
                  .animation({
                    duration: 800,
                    delay: 200,
                    timingFunction: 'ease-out'
                  })
              }
              
              Blank()
              
              // 功能按钮 | Function buttons
              Row() {
                Button() {
                  Text('🔍')
                    .fontSize(20)
                }
                .width(this.getButtonSize())
                .height(this.getButtonSize())
                .backgroundColor(colors.surface)
                .borderRadius(borderRadius.full)
                .margin({ right: spacing.md })
                .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
                .onClick(() => this.handleSearch())
                .animation({
                  duration: 800,
                  delay: 300,
                  timingFunction: 'ease-out'
                })
                
                Button() {
                  Text('⚙️')
                    .fontSize(20)
                }
                .width(this.getButtonSize())
                .height(this.getButtonSize())
                .backgroundColor(colors.surface)
                .borderRadius(borderRadius.full)
                .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
                .onClick(() => this.handleSettingsClick())
                .animation({
                  duration: 800,
                  delay: 400,
                  timingFunction: 'ease-out'
                })
              }
            }
            .width('100%')
            .padding({ left: spacing.lg, right: spacing.lg, top: spacing.lg, bottom: spacing.lg })
          }
          
          // 快速入口 | Quick entries
          Column() {
            ResponsiveGrid({
              columns: {
                xs: 2,
                sm: 2,
                md: 4,
                lg: 4,
                xl: 4,
                xxl: 4
              },
              gap: {
                xs: 16,
                sm: 20,
                md: 24,
                lg: 32,
                xl: 40,
                xxl: 48
              }
            }) {
              GridItem() {
                this.renderQuickEntry('直播', '📺', '#E3F2FD', () => this.handleLiveClick());
              }
              GridItem() {
                this.renderQuickEntry('电影', '🎬', '#E8F5E9', () => this.handleCategoryClick('电影'));
              }
              GridItem() {
                this.renderQuickEntry('电视剧', '📺', '#FFF3E0', () => this.handleCategoryClick('电视剧'));
              }
              GridItem() {
                this.renderQuickEntry('综艺', '🎵', '#F3E5F5', () => this.handleCategoryClick('综艺'));
              }
              GridItem() {
                this.renderQuickEntry('动漫', '🐱', '#E0F7FA', () => this.handleCategoryClick('动漫'));
              }
              GridItem() {
                this.renderQuickEntry('纪录片', '🎥', '#EDE7F6', () => this.handleCategoryClick('纪录片'));
              }
              GridItem() {
                this.renderQuickEntry('体育', '⚽', '#FFF8E1', () => this.handleCategoryClick('体育'));
              }
              GridItem() {
                this.renderQuickEntry('NAS管理', '🗄️', '#E8F5E9', () => this.handleNASManagementClick());
              }
            }
            .width('100%')
            .padding({ left: spacing.lg, right: spacing.lg, bottom: spacing.xl })
          }
          
          // 加载状态 | Loading state
          if (this.isLoading) {
            Column() {
              Progress({ value: 50, type: ProgressType.Ring })
                .color(colors.primary)
                .width(64)
                .height(64)
                .animation({ duration: 1000, iterations: -1 })
              Text('加载中...')
                .fontSize(16)
                .fontColor(colors.textSecondary)
                .margin({ top: spacing.md })
            }
            .width('100%')
            .height(400)
            .justifyContent(FlexAlign.Center)
          } else if (this.errorMessage) {
            // 错误状态 | Error state
            Column() {
              Text('😔')
                .fontSize(80)
                .margin({ bottom: spacing.lg })
                .animation({ duration: 500, timingFunction: 'ease-out' })
              Text(this.errorMessage)
                .fontSize(16)
                .fontColor(colors.textSecondary)
                .textAlign(TextAlign.Center)
                .margin({ bottom: spacing.lg })
                .width('80%')
              Button('重新加载')
                .fontSize(16)
                .fontColor(colors.surface)
                .backgroundColor(colors.primary)
                .borderRadius(borderRadius.full)
                .width(160)
                .height(56)
                .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
                .onClick(() => this.loadHomePageData())
                .animation({
                  duration: 500,
                  delay: 200,
                  timingFunction: 'ease-out'
                })
            }
            .width('100%')
            .height(400)
            .justifyContent(FlexAlign.Center)
          } else {
            // 内容区域 | Content area
            Column() {
              // 推荐内容 | Recommended content
              if (this.recommendedMedia.length > 0) {
                this.renderMediaSection('为你推荐', this.recommendedMedia, colors, spacing, borderRadius, shadows);
              }
              
              // 热门内容 | Popular content
              if (this.popularMedia.length > 0) {
                this.renderMediaSection('热门内容', this.popularMedia, colors, spacing, borderRadius, shadows);
              }
              
              // 最新内容 | New content
              if (this.newMedia.length > 0) {
                this.renderMediaSection('最新上线', this.newMedia, colors, spacing, borderRadius, shadows);
              }
            }
            .width('100%')
          }
          
          // 底部空间 | Bottom space
          Blank()
            .height(spacing.xl)
        }
        .width('100%')
        .backgroundColor(colors.background)
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
  
  /**
   * 根据断点获取头部字体大小 | Get header font size based on breakpoint
   */
  private getHeaderFontSize(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 24;
      case 'sm':
        return 28;
      case 'md':
        return 32;
      case 'lg':
        return 36;
      case 'xl':
        return 40;
      case 'xxl':
        return 44;
      default:
        return 32;
    }
  }
  
  /**
   * 根据断点获取按钮大小 | Get button size based on breakpoint
   */
  private getButtonSize(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 48;
      case 'sm':
        return 52;
      case 'md':
        return 56;
      case 'lg':
        return 60;
      case 'xl':
        return 64;
      case 'xxl':
        return 68;
      default:
        return 56;
    }
  }

  /**
   * 渲染快速入口 | Render quick entry
   */
  @Builder
  private renderQuickEntry(title: string, icon: string, bgColor: string, onClick: () => void) {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Column() {
      Stack() {
        Column()
          .width(96)
          .height(96)
          .backgroundColor(bgColor)
          .borderRadius(borderRadius.lg)
          .animation({
            duration: 500,
            timingFunction: 'ease-out'
          })
        Text(icon)
          .fontSize(40)
          .animation({
            duration: 500,
            delay: 100,
            timingFunction: 'ease-out'
          })
      }
      Text(title)
        .fontSize(14)
        .fontColor(colors.text)
        .margin({ top: spacing.sm })
        .animation({
          duration: 500,
          delay: 200,
          timingFunction: 'ease-out'
        })
    }
    .onClick(onClick)
    .flexGrow(1)
    .gesture(
      PanGesture({
        fingers: 1,
        direction: GestureDirection.All
      })
      .onActionStart((event: GestureEvent) => {
        // 可以添加触摸反馈
      })
      .onActionEnd(() => {
        // 可以添加点击动画
      })
    )
  }

  /**
   * 渲染媒体区块 | Render media section
   */
  @Builder
  private renderMediaSection(
    title: string, 
    mediaList: MediaItem[],
    colors: any,
    spacing: any,
    borderRadius: any,
    shadows: any
  ) {
    Column() {
      Row() {
        Text(title)
          .fontSize(this.getSectionTitleFontSize())
          .fontWeight(600)
          .fontColor(colors.text)
        
        Blank()
        
        Button('查看更多')
          .fontSize(14)
          .fontColor(colors.primary)
          .backgroundColor('transparent')
      }
      .width('100%')
      .padding({ left: spacing.lg, right: spacing.lg, bottom: spacing.md })
      
      // 使用虚拟列表渲染内容
      VirtualList({
        items: this.convertToVirtualItems(mediaList),
        estimatedItemHeight: this.getMediaItemHeight(),
        estimatedItemWidth: this.getMediaItemWidth(),
        bufferSize: 3,
        scrollDirection: ScrollDirection.Horizontal,
        renderItem: (item: VirtualListItem, index: number) => {
          const media: MediaItem = item.data as MediaItem;
          return this.renderMediaItem(media, colors, spacing, borderRadius, shadows);
        },
        onItemClick: (item: VirtualListItem) => {
          const media: MediaItem = item.data as MediaItem;
          this.handleMediaItemClick(media);
        }
      })
      .width('100%')
      .height(this.getMediaSectionHeight())
      .margin({ bottom: spacing.xl })
    }
  }
  
  /**
   * 根据断点获取区块标题字体大小 | Get section title font size based on breakpoint
   */
  private getSectionTitleFontSize(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 18;
      case 'sm':
        return 20;
      case 'md':
        return 22;
      case 'lg':
        return 24;
      case 'xl':
        return 26;
      case 'xxl':
        return 28;
      default:
        return 22;
    }
  }
  
  /**
   * 根据断点获取媒体项宽度 | Get media item width based on breakpoint
   */
  private getMediaItemWidth(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 160;
      case 'sm':
        return 180;
      case 'md':
        return 200;
      case 'lg':
        return 220;
      case 'xl':
        return 240;
      case 'xxl':
        return 260;
      default:
        return 200;
    }
  }
  
  /**
   * 根据断点获取媒体项高度 | Get media item height based on breakpoint
   */
  private getMediaItemHeight(): number {
    return this.getMediaItemWidth() * 1.8; // 保持 2:3 的宽高比
  }
  
  /**
   * 根据断点获取媒体区块高度 | Get media section height based on breakpoint
   */
  private getMediaSectionHeight(): number {
    return this.getMediaItemHeight() + 40; // 额外空间用于标题和间距
  }

  /**
   * 渲染媒体项 | Render media item
   */
  @Builder
  private renderMediaItem(
    media: MediaItem, 
    colors: any,
    spacing: any,
    borderRadius: any,
    shadows: any
  ): void {
    const itemWidth: number = this.getMediaItemWidth();
    const itemHeight: number = this.getMediaItemHeight();
    const coverWidth: number = itemWidth - 20; // 减去padding
    const coverHeight: number = coverWidth * 1.5; // 保持 2:3 的宽高比
    const fontSize: number = this.getMediaItemFontSize();
    
    Column() {
      Stack() {
        // 封面图
        Image(media.coverUrl || '')
          .width(coverWidth)
          .height(coverHeight)
          .objectFit(ImageFit.Cover)
          .borderRadius(borderRadius.lg)
          .backgroundColor(colors.surface)
          .animation({
            duration: 300,
            timingFunction: 'ease-out'
          })
        
        // 来源标识 | Source badge
        if (media.sourceName) {
          ContentSourceBadge({
            sourceName: media.sourceName,
            sourceId: media.sourceId || ''
          })
          .position({ top: spacing.sm, right: spacing.sm })
        }
        
        // 评分标识
        if (media.score) {
          Stack() {
            Text(media.score)
              .fontSize(this.getScoreFontSize())
              .fontWeight(600)
              .fontColor('#FFFFFF')
          }
          .width(this.getScoreBadgeSize())
          .height(this.getScoreBadgeSize())
          .backgroundColor('#FF6B35')
          .borderRadius(borderRadius.full)
          .position({ bottom: spacing.sm, left: spacing.sm })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.2)', offsetX: 0, offsetY: 2 })
        }
      }
      .margin({ bottom: spacing.md })
      
      // 标题
      Text(media.title)
        .fontSize(fontSize)
        .fontWeight(500)
        .fontColor(colors.text)
        .maxLines(2)
        .width(coverWidth)
        .textAlign(TextAlign.Center)
    }
    .width(itemWidth)
    .height(itemHeight)
    .padding(spacing.sm)
    .backgroundColor(colors.surface)
    .borderRadius(borderRadius.xl)
    .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 8 })
    .onClick(() => this.handleMediaItemClick(media))
    .gesture(
      PanGesture({
        fingers: 1,
        direction: GestureDirection.All
      })
      .onActionStart(() => {
        // 可以添加触摸反馈
      })
      .onActionEnd(() => {
        // 可以添加点击动画
      })
    )
  }
  
  /**
   * 根据断点获取媒体项字体大小 | Get media item font size based on breakpoint
   */
  private getMediaItemFontSize(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 12;
      case 'sm':
        return 13;
      case 'md':
        return 14;
      case 'lg':
        return 15;
      case 'xl':
        return 16;
      case 'xxl':
        return 17;
      default:
        return 14;
    }
  }
  
  /**
   * 根据断点获取评分字体大小 | Get score font size based on breakpoint
   */
  private getScoreFontSize(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 12;
      case 'sm':
        return 13;
      case 'md':
        return 14;
      case 'lg':
        return 15;
      case 'xl':
        return 16;
      case 'xxl':
        return 17;
      default:
        return 14;
    }
  }
  
  /**
   * 根据断点获取评分徽章大小 | Get score badge size based on breakpoint
   */
  private getScoreBadgeSize(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 32;
      case 'sm':
        return 34;
      case 'md':
        return 36;
      case 'lg':
        return 38;
      case 'xl':
        return 40;
      case 'xxl':
        return 42;
      default:
        return 36;
    }
  }
}

export default HomePage;