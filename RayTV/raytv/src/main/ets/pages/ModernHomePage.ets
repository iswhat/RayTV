// ModernHomePage.ets
// 现代首页组件 - Modern home page component

import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ContentAccessService from '../service/content/ContentAccessService';
import { MediaItem } from '../data/bean/MediaItem';
import display from '@ohos.display';

import VirtualList from '../components/VirtualList';
import { VirtualListItem } from '../types/VirtualListTypes';
import { SkeletonScreen } from '../components/SkeletonScreen';
import ContentSourceBadge from '../components/ContentSourceBadge';
import ModernDesignSystem, { Theme } from '../design/ModernDesignSystem';

/**
 * 现代首页组件
 * 展示推荐媒体内容和功能入口
 */
@Entry
@Component
struct ModernHomePage {
  private readonly TAG: string = 'ModernHomePage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理
  @State isLoading: boolean = false;
  @State recommendedMedia: MediaItem[] = [];
  @State popularMedia: MediaItem[] = [];
  @State newMedia: MediaItem[] = [];
  @State errorMessage: string = '';
  @State currentTheme: Theme = ModernDesignSystem.getCurrentTheme();
  @State showQuickActions: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  
  // 服务实例
  private contentService: ContentAccessService = ContentAccessService.getInstance();

  // 初始化页面
  async aboutToAppear(): Promise<void> {
    Logger.info(this.TAG, 'ModernHomePage mounted');
    
    // 初始化屏幕信息
    this.initScreenInfo();
    
    // 初始化内容访问服务
    await this.contentService.initialize();
    
    // 加载首页数据
    await this.loadHomePageData();
  }

  // 清理资源
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'ModernHomePage unmounted');
  }
  
  /**
   * 初始化屏幕信息
   */
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to get screen info: ${err.message}`);
      // 默认值
      this.screenWidth = 1080;
      this.screenHeight = 1920;
    }
  }
  
  /**
   * 加载首页数据
   */
  private async loadHomePageData(): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';

      Logger.info(this.TAG, 'Loading home page data');

      // 从ContentAccessService获取数据
      const sites = this.contentService.getAllVodSites();
      
      if (sites.length > 0) {
        // 基于站点数据生成媒体列表
        this.recommendedMedia = this.generateMediaItems(sites.slice(0, 6), '推荐');
        this.popularMedia = this.generateMediaItems(sites.slice(6, 12), '热门');
        this.newMedia = this.generateMediaItems(sites.slice(12, 18), '最新');
      } else {
        // 无数据时显示提示
        this.errorMessage = '暂无内容，请在设置中添加网络源';
      }

      Logger.info(this.TAG, `Home page data loaded: recommended=${this.recommendedMedia.length}, popular=${this.popularMedia.length}, new=${this.newMedia.length}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to load home page data: ${err.message}`);
      this.errorMessage = '加载数据失败，请稍后重试';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 生成媒体项
   */
  private generateMediaItems(sites: string[], type: string): MediaItem[] {
    return sites.map((site, index) => ({
      id: `${type}_${index}_${site.sourceId}`,
      title: site.name,
      coverUrl: '',
      siteKey: site.siteKey,
      score: (8.0 + index * 0.3).toFixed(1),
      sourceId: site.sourceId,
      sourceName: site.sourceName
    }));
  }
  
  /**
   * 处理搜索
   */
  private handleSearch(): void {
    try {
      Logger.info(this.TAG, 'Search button clicked');
      // 跳转到搜索页面
      AppNavigator.getInstance().navigateToSearch('');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to search page: ${err.message}`);
    }
  }
  
  /**
   * 处理媒体项点击
   */
  private handleMediaItemClick(media: MediaItem): void {
    try {
      Logger.info(this.TAG, `Media item clicked: ${media.title}, Source: ${media.sourceName}`);

      // 验证媒体数据完整性
      if (!media.id || !media.siteKey) {
        Logger.error(this.TAG, 'Invalid media data: missing required fields');
        return;
      }

      // 跳转到详情页
      AppNavigator.getInstance().navigateToDetail({
        id: media.id,
        siteKey: media.siteKey || '',
        type: 'movie'
      });
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to detail page: ${err.message}`);
    }
  }
  
  /**
   * 处理直播入口点击
   */
  private handleLiveClick(): void {
    try {
      Logger.info(this.TAG, 'Live entry clicked');
      // 跳转到直播页面
      AppNavigator.getInstance().navigateToLive();
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to live page: ${err.message}`);
    }
  }
  
  /**
   * 处理设置入口点击
   */
  private handleSettingsClick(): void {
    try {
      Logger.info(this.TAG, 'Settings entry clicked');
      // 跳转到设置页面
      AppNavigator.getInstance().navigateToSettings();
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to settings page: ${err.message}`);
    }
  }
  
  /**
   * 处理分类入口点击
   */
  private handleCategoryClick(category: string): void {
    try {
      Logger.info(this.TAG, `Category clicked: ${category}`);
      // 跳转到分类页面
      AppNavigator.getInstance().navigateToCategory(category);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to category page: ${err.message}`);
    }
  }
  
  /**
   * 将MediaItem转换为VirtualListItem
   */
  private convertToVirtualItems(mediaList: MediaItem[]): VirtualListItem[] {
    const virtualItems: VirtualListItem[] = [];
    for (let i = 0; i < mediaList.length; i++) {
      const media = mediaList[i];
      const virtualItem: VirtualListItem = {
        id: `${media.id}_${media.sourceId || 'default'}`,
        index: i,
        data: media,
        top: 0,
        left: i * 220,
        height: 340,
        width: 200,
        visible: false
      };
      virtualItems.push(virtualItem);
    }
    return virtualItems;
  }
  
  /**
   * 构建页面UI
   */
  build() {
    const colors = this.currentTheme.colors;
    const spacing = ModernDesignSystem.Spacing;
    const borderRadius = ModernDesignSystem.BorderRadius;
    const typography = ModernDesignSystem.Typography;
    
    Scroll(this.scroller) {
      Column() {
        // 页面头部
        Stack() {
          // 背景渐变
          Column()
            .width('100%')
            .height(200)
            .backgroundColor(colors.primary)
          
          Row() {
            Column() {
              Text('RayTV')
                .fontSize(typography.h2.size)
                .fontWeight(typography.h2.fontWeight)
                .fontColor(colors.onPrimary)
                .animation(ModernDesignSystem.Animations.fadeIn)
              Text('发现精彩内容')
                .fontSize(typography.caption.size)
                .fontColor(colors.onPrimary)
                .opacity(0.9)
                .margin({ top: spacing.xs })
                .animation({
                  ...ModernDesignSystem.Animations.fadeIn,
                  delay: 200
                })
            }
            
            Blank()
            
            // 功能按钮
            Row() {
              Button() {
                Text('🔍')
                  .fontSize(20)
              }
              .width(56)
              .height(56)
              .backgroundColor('rgba(255, 255, 255, 0.2)')
              .borderRadius(borderRadius.full)
              .margin({ right: spacing.md })
              .onClick(() => this.handleSearch())
              .animation({
                ...ModernDesignSystem.Animations.fadeIn,
                delay: 300
              })
              
              Button() {
                Text('⚙️')
                  .fontSize(20)
              }
              .width(56)
              .height(56)
              .backgroundColor('rgba(255, 255, 255, 0.2)')
              .borderRadius(borderRadius.full)
              .onClick(() => this.handleSettingsClick())
              .animation({
                ...ModernDesignSystem.Animations.fadeIn,
                delay: 400
              })
            }
          }
          .width('100%')
          .padding({ left: spacing.lg, right: spacing.lg, top: spacing.lg, bottom: spacing.lg })
        }
        .height(200)
        
        // 快速入口
        Column() {
          Row() {
            this.renderQuickEntry('直播', '📺', colors.primary, () => this.handleLiveClick());
            this.renderQuickEntry('电影', '🎬', colors.success, () => this.handleCategoryClick('电影'));
            this.renderQuickEntry('电视剧', '📺', colors.warning, () => this.handleCategoryClick('电视剧'));
            this.renderQuickEntry('综艺', '🎵', colors.secondary, () => this.handleCategoryClick('综艺'));
          }
          .width('100%')
          .padding({ left: spacing.lg, right: spacing.lg, bottom: spacing.xl })
          .justifyContent(FlexAlign.SpaceAround)
          
          Row() {
            this.renderQuickEntry('动漫', '🐱', colors.info, () => this.handleCategoryClick('动漫'));
            this.renderQuickEntry('纪录片', '🎥', colors.error, () => this.handleCategoryClick('纪录片'));
            this.renderQuickEntry('体育', '⚽', colors.warning, () => this.handleCategoryClick('体育'));
            this.renderQuickEntry('更多', '➕', colors.secondary, () => this.handleCategoryClick('全部'));
          }
          .width('100%')
          .padding({ left: spacing.lg, right: spacing.lg, bottom: spacing.xl })
          .justifyContent(FlexAlign.SpaceAround)
        }
        .margin({ top: -spacing.xl })
        .padding({ top: spacing.xl })
        .backgroundColor(colors.background)
        .borderTopLeftRadius(borderRadius.xl)
        .borderTopRightRadius(borderRadius.xl)
        
        // 加载状态
        if (this.isLoading) {
          Column() {
            Progress({ value: 50, type: ProgressType.Ring })
              .color(colors.primary)
              .width(64)
              .height(64)
              .animation({ duration: 1000, iterations: -1 })
            Text('加载中...')
              .fontSize(typography.body.size)
              .fontColor(colors.textSecondary)
              .margin({ top: spacing.md })
          }
          .width('100%')
          .height(400)
          .justifyContent(FlexAlign.Center)
        } else if (this.errorMessage) {
          // 错误状态
          Column() {
            Text('😔')
              .fontSize(80)
              .margin({ bottom: spacing.lg })
              .animation(ModernDesignSystem.Animations.fadeIn)
            Text(this.errorMessage)
              .fontSize(typography.body.size)
              .fontColor(colors.textSecondary)
              .textAlign(TextAlign.Center)
              .margin({ bottom: spacing.lg })
              .width('80%')
            Button('重新加载')
              .fontSize(typography.button.size)
              .fontColor(colors.onPrimary)
              .backgroundColor(colors.primary)
              .borderRadius(borderRadius.full)
              .width(160)
              .height(56)
              .onClick(() => this.loadHomePageData())
              .animation({
                ...ModernDesignSystem.Animations.fadeIn,
                delay: 200
              })
          }
          .width('100%')
          .height(400)
          .justifyContent(FlexAlign.Center)
        } else {
          // 内容区域
          Column() {
            // 推荐内容
            if (this.recommendedMedia.length > 0) {
              this.renderMediaSection('为你推荐', this.recommendedMedia, colors, spacing, borderRadius, typography);
            }
            
            // 热门内容
            if (this.popularMedia.length > 0) {
              this.renderMediaSection('热门内容', this.popularMedia, colors, spacing, borderRadius, typography);
            }
            
            // 最新内容
            if (this.newMedia.length > 0) {
              this.renderMediaSection('最新上线', this.newMedia, colors, spacing, borderRadius, typography);
            }
          }
          .width('100%')
        }
        
        // 底部空间
        Blank()
          .height(spacing.xl)
      }
      .width('100%')
      .backgroundColor(colors.background)
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  /**
   * 渲染快速入口
   */
  @Builder
  private renderQuickEntry(title: string, icon: string, bgColor: string, onClick: () => void) {
    const colors = this.currentTheme.colors;
    const spacing = ModernDesignSystem.Spacing;
    const borderRadius = ModernDesignSystem.BorderRadius;
    const typography = ModernDesignSystem.Typography;
    
    Column() {
      Stack() {
        Column()
          .width(96)
          .height(96)
          .backgroundColor(`${bgColor}20`)
          .borderRadius(borderRadius.lg)
          .animation(ModernDesignSystem.Animations.fadeIn)
        Text(icon)
          .fontSize(40)
          .animation({
            ...ModernDesignSystem.Animations.fadeIn,
            delay: 100
          })
      }
      Text(title)
        .fontSize(typography.caption.size)
        .fontColor(colors.text)
        .margin({ top: spacing.sm })
        .animation({
          ...ModernDesignSystem.Animations.fadeIn,
          delay: 200
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
   * 渲染媒体区块
   */
  @Builder
  private renderMediaSection(
    title: string, 
    mediaList: MediaItem[],
    colors: string,
    spacing: string,
    borderRadius: string,
    typography: string
  ) {
    Column() {
      Row() {
        Text(title)
          .fontSize(typography.h3.size)
          .fontWeight(typography.h3.fontWeight)
          .fontColor(colors.text)
        
        Blank()
        
        Button('查看更多')
          .fontSize(typography.caption.size)
          .fontColor(colors.primary)
          .backgroundColor('transparent')
      }
      .width('100%')
      .padding({ left: spacing.lg, right: spacing.lg, bottom: spacing.md })
      
      // 使用虚拟列表渲染内容
      VirtualList({
        items: this.convertToVirtualItems(mediaList),
        estimatedItemHeight: 360,
        estimatedItemWidth: 200,
        bufferSize: 3,
        scrollDirection: ScrollDirection.Horizontal,
        renderItem: (item: VirtualListItem, index: number) => {
          const media = item.data as MediaItem;
          return this.renderMediaItem(media, colors, spacing, borderRadius, typography);
        },
        onItemClick: (item: VirtualListItem) => {
          const media = item.data as MediaItem;
          this.handleMediaItemClick(media);
        }
      })
      .width('100%')
      .height(400)
      .margin({ bottom: spacing.xl })
    }
  }

  /**
   * 渲染媒体项
   */
  @Builder
  private renderMediaItem(
    media: MediaItem, 
    colors: string,
    spacing: string,
    borderRadius: string,
    typography: string
  ): void {
    Column() {
      Stack() {
        // 封面图
        Image(media.coverUrl || '')
          .width(180)
          .height(270)
          .objectFit(ImageFit.Cover)
          .borderRadius(borderRadius.lg)
          .backgroundColor(colors.surfaceVariant)
          .animation(ModernDesignSystem.Animations.fadeIn)
        
        // 来源标识
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
              .fontSize(typography.caption.size)
              .fontWeight(600)
              .fontColor('#FFFFFF')
          }
          .width(36)
          .height(36)
          .backgroundColor('#FF6B35')
          .borderRadius(borderRadius.full)
          .position({ bottom: spacing.sm, left: spacing.sm })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .margin({ bottom: spacing.md })
      
      // 标题
      Text(media.title)
        .fontSize(typography.caption.size)
        .fontWeight(500)
        .fontColor(colors.text)
        .maxLines(2)
        .width(180)
        .textAlign(TextAlign.Center)
    }
    .width(200)
    .height(360)
    .padding(spacing.sm)
    .backgroundColor(colors.surface)
    .borderRadius(borderRadius.xl)
    .shadow({
      radius: 12,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 8
    })
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
}

export default ModernHomePage;