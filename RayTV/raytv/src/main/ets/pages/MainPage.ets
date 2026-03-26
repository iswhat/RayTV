import { AppNavigator, DetailParams } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import display from '@ohos.display';
import ContentSourceBadge from '../components/ContentSourceBadge';
import { ImageLazyLoader } from '../components/ImageLazyLoader';
import { LazyLoadStrategy } from '../types/LazyLoadTypes';
import Strings from '../common/resources/Strings';
import { theme } from '../common/theme/ThemeConfig';
import { handleError, ErrorType } from '../common/util/ErrorHandler';
import { mainPageViewModel, FeaturedMediaItem } from './viewmodel/MainPageViewModel';

/**
 * 应用主页面 | Application main page
 * 作为应用的入口页面，显示主要功能区域 | As the application's entry page, display main functional areas
 */
interface TabItem {
  key: string;
  name: string;
  icon?: string;
}

interface CategoryTab {
  id: string;
  name: string;
}

@Entry
@Component
struct MainPage {
  private readonly TAG: string = 'MainPage';
  private scroller: Scroller = new Scroller();
  private contentScroller: Scroller = new Scroller();
  // 定时器ID，用于在组件销毁时清理 | Timer ID for cleanup on component destroy
  private dateUpdateTimer: number = -1;

  // 状态管理 | State management
  @State featuredMedia: FeaturedMediaItem[] = [];
  @State popularMedia: FeaturedMediaItem[] = [];
  @State newMedia: FeaturedMediaItem[] = [];
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = Strings.mainPage.loadFailed;
  @State selectedTab: string = 'vod';
  @State selectedCategory: string = Strings.mainPage.categories.all;
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State currentDate: string = '';
  
  // 日期更新优化 | Date update optimization
  private lastMinute: number | null = null;

  // 导航标签数据 | Navigation tab data
  private mainMenuItems: TabItem[] = [
    { key: 'vod', name: Strings.mainPage.tabs.vod },
    { key: 'live', name: Strings.mainPage.tabs.live },
    { key: 'search', name: Strings.mainPage.tabs.search },
    { key: 'history', name: Strings.mainPage.tabs.history },
    { key: 'settings', name: Strings.mainPage.tabs.settings }
  ];


  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'MainPage about to appear');

    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();

    // 初始化日期 | Initialize date
    this.updateCurrentDate();

    // 使用requestAnimationFrame实现更高效的日期更新
    // 只在分钟变化时更新，减少不必要的渲染
    this.updateDateEfficiently();

    // 加载推荐内容 | Load recommended content
    this.loadFeaturedMedia();
  }

  // 组件销毁时清理 | Clean up on component destroy
  aboutToDisappear() {
    if (this.dateUpdateTimer !== -1) {
      // 使用 setInterval 清理机制
      clearInterval(this.dateUpdateTimer);
      this.dateUpdateTimer = -1;
    }
  }

  // 高效的日期更新方法 | Efficient date update method
  private updateDateEfficiently(): void {
    // 使用 setInterval 每秒检查一次分钟变化
    this.dateUpdateTimer = setInterval(() => {
      const now = new Date();
      const currentMinute = now.getMinutes();

      // 只在分钟变化时更新，减少渲染次数
      if (!this.lastMinute || this.lastMinute !== currentMinute) {
        this.updateCurrentDate();
        this.lastMinute = currentMinute;
      }
    }, 1000) as number;
  }
  
  // 更新当前日期 | Update current date
  private updateCurrentDate(): void {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    
    const dateFormat = theme.getDateFormat().full;
    this.currentDate = dateFormat
      .replace('{year}', year.toString())
      .replace('{month}', month)
      .replace('{day}', day)
      .replace('{hours}', hours)
      .replace('{minutes}', minutes);
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to get screen info: ${err.message}`);
      // 默认值 | Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
    }
  }
  
  // 加载推荐内容 | Load featured media
  private async loadFeaturedMedia(): Promise<void> {
    try {
      this.isLoading = true;
      this.isError = false;

      // 使用ViewModel加载推荐内容 | Load featured media using ViewModel
      const result = await mainPageViewModel.loadFeaturedMedia();
      
      this.featuredMedia = result.featuredMedia;
      this.popularMedia = result.popularMedia;
      this.newMedia = result.newMedia;
      this.isError = result.hasError;
      
      if (result.hasError && result.errorMessage) {
        this.errorMessage = result.errorMessage;
      }

      this.isLoading = false;

    } catch (error) {
      const errorInfo = handleError(error, ErrorType.CONTENT_LOAD_ERROR);
      Logger.error(this.TAG, `Failed to load featured media: ${errorInfo.message}`);
      this.isError = true;
      this.errorMessage = errorInfo.friendlyMessage || Strings.mainPage.loadFailed;
      this.isLoading = false;
    }
  }
  
  // 处理主菜单点击 | Handle main menu click
  private handleMainMenuClick(key: string): void {
    try {
      Logger.info(this.TAG, `Main menu clicked: ${key}`);

      // 验证菜单键值 | Validate menu key
      if (!mainPageViewModel.validateMenuKey(key)) {
        const errorInfo = handleError(new Error('Invalid menu key'), ErrorType.VALIDATION_ERROR);
        Logger.error(this.TAG, errorInfo.message);
        return;
      }

      switch (key) {
        case 'vod':
          // 只在切换到 vod tab 时才加载（已在 vod tab 则不重复加载）| Only load when switching to vod tab
          if (this.selectedTab !== 'vod') {
            this.selectedTab = 'vod';
            this.loadFeaturedMedia();
          }
          break;
        case 'live':
          AppNavigator.getInstance().navigateToLive();
          break;
        case 'search':
          AppNavigator.getInstance().navigateToSearch('');
          break;
        case 'history':
          AppNavigator.getInstance().navigateToHistory();
          break;
        case 'settings':
          AppNavigator.getInstance().navigateToSettings();
          break;
        default:
          const warningInfo = handleError(new Error(`Unknown menu key: ${key}`), ErrorType.VALIDATION_ERROR);
          Logger.warn(this.TAG, warningInfo.message);
          break;
      }
    } catch (error) {
      const errorInfo = handleError(error, ErrorType.NAVIGATION_ERROR);
      Logger.error(this.TAG, `Failed to handle main menu click: ${errorInfo.message}`);
    }
  }
  
  // 处理分类标签点击 | Handle category tab click
  private handleCategoryClick(categoryId: string): void {
    try {
      Logger.info(this.TAG, `Category clicked: ${categoryId}`);

      // 验证分类ID | Validate category ID
      if (!mainPageViewModel.validateCategoryId(categoryId)) {
        const errorInfo = handleError(new Error('Invalid category ID'), ErrorType.VALIDATION_ERROR);
        Logger.error(this.TAG, errorInfo.message);
        return;
      }

      // 只在分类真正变化时才重新加载，避免重复请求 | Only reload when category actually changes
      if (this.selectedCategory === categoryId) {
        return;
      }

      this.selectedCategory = categoryId;

      // 根据分类筛选已加载的内容，无需重新请求全部数据 | Filter loaded content by category, no need to re-fetch all
      // 如果是"全部"分类则直接刷新 | If "全部" category, do a full refresh
      if (categoryId === '全部') {
        this.loadFeaturedMedia();
      }
      // 其他分类在 build 中通过 selectedCategory 状态自动过滤展示
    } catch (error) {
      const errorInfo = handleError(error, ErrorType.CATEGORY_ERROR);
      Logger.error(this.TAG, `Failed to handle category click: ${errorInfo.message}`);
    }
  }
  
  // 处理影视点击 | Handle media click
  private handleMediaClick(media: FeaturedMediaItem): void {
    try {
      Logger.info(this.TAG, `Media clicked: ${media.title}, Source: ${media.sourceName}`);

      // 验证媒体数据完整性 | Validate media data integrity
      if (!mainPageViewModel.validateMediaData(media)) {
        const errorInfo = handleError(new Error('Invalid media data: missing required fields'), ErrorType.VALIDATION_ERROR);
        Logger.error(this.TAG, errorInfo.message);
        return;
      }

      const params: DetailParams = {
        id: media.id,
        siteKey: media.siteKey || '',
        type: 'vod'
      };
      AppNavigator.getInstance().navigateToDetail(params);
    } catch (error) {
      const errorInfo = handleError(error, ErrorType.NAVIGATION_ERROR);
      Logger.error(this.TAG, `Failed to handle media click: ${errorInfo.message}`);
    }
  }
  
  // 渲染媒体项 | Render media item
  @Builder
  private renderMediaItem(media: FeaturedMediaItem): void {
    const colors = theme.getColors();
    const sizes = theme.getSizes();
    const shadows = theme.getShadows();
    const mediaSizes = this.isLandscape ? sizes.media.landscape : sizes.media.portrait;
    
    Column() {
      Stack() {
        ImageLazyLoader({
          src: media.cover || '',
          imgWidth: '100%',
          imgHeight: mediaSizes.imageHeight,
          imgRadius: sizes.borderRadius.lg,
          placeholder: '',
          lazyStrategy: LazyLoadStrategy.VISIBLE
        })
        
        // 来源标识 | Source badge
        if (media.sourceName) {
          ContentSourceBadge({
            sourceName: media.sourceName
          })
          .position({ top: sizes.spacing.sm, right: sizes.spacing.sm })
        }
        
        // 评分标识 | Rating badge
        if (media.rating) {
          Row() {
            Text(media.rating)
              .fontSize(sizes.font.sm)
              .fontWeight(600)
              .fontColor(colors.text.primary)
          }
          .backgroundColor(colors.warning)
          .padding({ left: sizes.spacing.sm, right: sizes.spacing.sm, top: sizes.spacing.xs, bottom: sizes.spacing.xs })
          .borderRadius(sizes.borderRadius.md)
          .position({ bottom: sizes.spacing.sm, right: sizes.spacing.sm })
        }
      }
      .margin({ bottom: sizes.spacing.md })
      
      Text(media.title)
        .fontSize(sizes.font.md)
        .fontWeight(600)
        .maxLines(2)
        .margin({ left: sizes.spacing.sm, right: sizes.spacing.sm })
        .textAlign(TextAlign.Center)
        .fontColor(colors.text.primary)
    }
    .padding(sizes.spacing.md)
    .backgroundColor(colors.background.card)
    .borderRadius(sizes.borderRadius.xl)
    .shadow({ 
      radius: shadows.card.radius, 
      color: shadows.card.color, 
      offsetY: shadows.card.offsetY 
    })
    .onClick(() => this.handleMediaClick(media))
    .width(mediaSizes.width)
    .height(mediaSizes.height)
    .focusable(true)
    // 添加点击反馈动画
    .gesture(
      TapGesture()
        .onAction(() => {
          console.info('Media item tapped: ' + media.title);
        })
    )
  }
  
  // 渲染内容区域 | Render content section
  @Builder
  private renderContentSection(title: string, mediaList: FeaturedMediaItem[]) {
    const colors = theme.getColors();
    const sizes = theme.getSizes();
    const mediaSizes = this.isLandscape ? sizes.media.landscape : sizes.media.portrait;
    const listHeight = this.isLandscape ? sizes.media.list.landscape : sizes.media.list.portrait;
    
    Column() {
      // 内容标题 | Content title
      Row() {
        Text(title)
          .fontSize(sizes.font.xl)
          .fontWeight(700)
          .fontColor(colors.text.primary)
          .margin({ left: sizes.spacing.xxl, top: sizes.spacing.xl, bottom: sizes.spacing.lg })
      }
      
      // 内容区域 | Content area - 使用List实现虚拟列表
      List({
        scroller: this.contentScroller,
        initialIndex: 0,
        space: sizes.spacing.xl
      }) {
        ForEach(mediaList, (item: FeaturedMediaItem) => {
          ListItem() {
            this.renderMediaItem(item)
          }
          .width(mediaSizes.width)
          .height(mediaSizes.height)
        }, (item: FeaturedMediaItem) => `${item.id}_${item.sourceId || 'default'}`)
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Auto)
      .height(listHeight)
      .padding({ left: sizes.spacing.xxl, right: sizes.spacing.xxl, bottom: sizes.spacing.xxl })
    }
  }
  
  build() {
    const colors = theme.getColors();
    const sizes = theme.getSizes();
    const animations = theme.getAnimations();
    const mediaSizes = this.isLandscape ? sizes.media.landscape : sizes.media.portrait;
    const listHeight = this.isLandscape ? sizes.media.list.landscape : sizes.media.list.portrait;
    
    Column() {
      // 顶部区域 | Top area
      Column() {
        // 顶部信息栏 | Top info bar
        Row() {
          // 应用标题 | App title
          Text('RayTV')
            .fontSize(sizes.font.xxl)
            .fontWeight(700)
            .fontColor(colors.text.primary)
            .margin({ left: sizes.spacing.xxxl })
          
          // 日期显示 | Date display
          Text(this.currentDate)
            .fontSize(sizes.font.md)
            .fontColor(colors.text.secondary)
            .margin({ right: sizes.spacing.xxxl })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .height(sizes.height.header)
        .backgroundColor(colors.primary)
        
        // 主功能菜单 | Main function menu
        Row() {
          ForEach(this.mainMenuItems, (item: TabItem) => {
            Column() {
            Text(item.name)
              .fontSize(sizes.font.lg)
              .fontWeight(this.selectedTab === item.key ? 700 : 400)
              .fontColor(this.selectedTab === item.key ? colors.primary : colors.text.primary)
              .padding({ left: sizes.spacing.xxl, right: sizes.spacing.xxl, top: sizes.spacing.lg, bottom: sizes.spacing.lg })
              .border(this.selectedTab === item.key ? { width: { bottom: 3 }, color: colors.primary } : { width: { bottom: 0 }, color: 'transparent' })
          }
          .onClick(() => this.handleMainMenuClick(item.key))
          .focusable(true)
          .backgroundColor(this.selectedTab === item.key ? colors.primaryLight : 'transparent')
          .animation({
            duration: animations.duration.short,
            curve: animations.curve.easeOut
          })
          }, (item: TabItem) => item.key)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(colors.background.secondary)
        .padding({ left: sizes.spacing.xxl })
      }
      
      // 主内容区域 | Main content area
      if (this.selectedTab === 'vod') {
        Scroll(this.contentScroller) {
          Column() {
            if (this.isLoading) {
          Column() {
            Text(Strings.mainPage.loadingContent)
              .fontSize(sizes.font.lg)
              .fontColor(colors.text.disabled)
              .margin({ top: sizes.spacing.xxl, bottom: sizes.spacing.xl })
                
                // 骨架屏 | Skeleton screen
                Row() {
                  ForEach([1, 2, 3, 4, 5], (item: number) => {
                    Column() {
                      // 图片骨架 | Image skeleton
                      Column()
                        .width(mediaSizes.skeleton.width)
                        .height(mediaSizes.skeleton.height)
                        .backgroundColor(colors.background.card)
                        .borderRadius(sizes.borderRadius.lg)
                        .animation({
                          duration: animations.duration.long,
                          tempo: 1,
                          curve: animations.curve.easeInOut,
                          iterations: -1,
                          delay: item * 100
                        })
                      
                      // 标题骨架 | Title skeleton
                      Column()
                        .width(mediaSizes.skeleton.titleWidth)
                        .height(40)
                        .backgroundColor(colors.background.card)
                        .borderRadius(sizes.borderRadius.sm)
                        .margin({ top: sizes.spacing.md })
                        .animation({
                          duration: animations.duration.long,
                          tempo: 1,
                          curve: animations.curve.easeInOut,
                          iterations: -1,
                          delay: item * 150
                        })
                    }
                    .padding(sizes.spacing.md)
                    .width(mediaSizes.width)
                    .height(mediaSizes.height)
                  })
                }
                .padding({ left: sizes.spacing.xxl, right: sizes.spacing.xxl, bottom: sizes.spacing.xxl })
              }
              .justifyContent(FlexAlign.Start)
              .height(listHeight)
            } else if (this.isError) {
              Column() {
                Text(Strings.mainPage.loadFailed)
                  .fontSize(sizes.font.lg)
                  .fontColor(colors.text.error)
                  .margin({ top: sizes.spacing.xl })
                Text(this.errorMessage)
                  .fontSize(sizes.font.md)
                  .fontColor(colors.text.warning)
                  .margin({ top: sizes.spacing.md })
                Button(Strings.common.retry)
                  .onClick(() => this.loadFeaturedMedia())
                  .backgroundColor(colors.primary)
                  .fontColor(colors.text.primary)
                  .borderRadius(sizes.borderRadius.xxl)
                  .padding({ left: sizes.spacing.xxl, right: sizes.spacing.xxl, top: 14, bottom: 14 })
                  .margin({ top: sizes.spacing.xl })
                  .fontSize(sizes.font.md)
                  .focusable(true)
              }
              .justifyContent(FlexAlign.Center)
              .height(listHeight)
            } else {
              // 推荐内容 | Recommended content
              if (this.featuredMedia.length > 0) {
                this.renderContentSection(Strings.mainPage.categories.featured, this.featuredMedia);
              }
              
              // 热门内容 | Popular content
              if (this.popularMedia.length > 0) {
                this.renderContentSection(Strings.mainPage.categories.popular, this.popularMedia);
              }
              
              // 最新内容 | New content
              if (this.newMedia.length > 0) {
                this.renderContentSection(Strings.mainPage.categories.new, this.newMedia);
              }
            }
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .flexGrow(1)
        .backgroundColor(colors.background.primary)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.background.primary)
  }
}
