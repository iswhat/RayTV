import { AppNavigator, DetailParams } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ContentAccessServiceInstance, { ContentAccessService } from '../service/content/ContentAccessService';
import display from '@ohos.display';
import ContentSourceBadge from '../components/ContentSourceBadge';
import { ImageLazyLoader } from '../components/ImageLazyLoader';
import { LazyLoadStrategy } from '../types/LazyLoadTypes';
import Strings from '../common/resources/Strings';

/**
 * 应用主页面 | Application main page
 * 作为应用的入口页面，显示主要功能区域 | As the application's entry page, display main functional areas
 */
interface TabItem {
  key: string;
  name: string;
  icon?: string;
}

interface FeaturedMediaItem {
  id: string;
  title: string;
  cover: string;
  type: string;
  siteKey?: string;
  rating?: string;
  sourceId?: string;
  sourceName?: string;
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

  // 服务实例 | Service instances
  private contentService: ContentAccessService = ContentAccessServiceInstance;


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
    this.currentDate = year + '年' + month + '月' + day + '日 ' + hours + ':' + minutes;
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

      // 确保ContentAccessService已初始化 | Ensure ContentAccessService is initialized
      if (!this.contentService.isInitialized()) {
        await this.contentService.initialize();
      }

      // 从ContentAccessService获取真实的点播站点数据 | Get real VOD site data from ContentAccessService
      const allVodSites = this.contentService.getAllVodSites();

      if (allVodSites.length > 0) {
        // 将VodSiteWithSource转换为FeaturedMediaItem
        const toMediaItem = (site: import('../service/pool/SourcePoolManager').VodSiteWithSource, idx: number): FeaturedMediaItem => ({
          id: `${site.siteKey}_${idx}`,
          title: site.name,
          cover: '', // VodSiteWithSource 没有 logo 字段，使用空字符串
          type: 'vod',
          siteKey: site.siteKey,
          sourceId: site.sourceId,
          sourceName: site.sourceName
        });

        // 推荐内容：取前5个站点 | Featured: first 5 sites
        this.featuredMedia = allVodSites.slice(0, 5).map(toMediaItem);

        // 热门内容：取5-10个站点 | Popular: sites 5-10
        this.popularMedia = allVodSites.slice(5, 10).map(toMediaItem);

        // 最新内容：取最后一批站点（最多5个）| New: last batch of sites (up to 5)
        const newStart = Math.max(10, allVodSites.length - 5);
        this.newMedia = allVodSites.slice(newStart).map(toMediaItem);

        Logger.info(this.TAG, `Loaded ${allVodSites.length} VOD sites from ContentAccessService`);
      } else {
        // 无数据时提示用户配置源 | No data: prompt user to configure sources
        this.featuredMedia = [];
        this.popularMedia = [];
        this.newMedia = [];
        Logger.warn(this.TAG, 'No VOD sites available. Please configure network sources in Settings.');
      }

      this.isLoading = false;

    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load featured media: ${errorMsg}`);
      this.isError = true;
      this.errorMessage = `推荐内容加载失败: ${errorMsg}`;
      this.isLoading = false;
    }
  }
  
  // 处理主菜单点击 | Handle main menu click
  private handleMainMenuClick(key: string): void {
    try {
      Logger.info(this.TAG, `Main menu clicked: ${key}`);

      // 验证菜单键值 | Validate menu key
      if (!key) {
        Logger.error(this.TAG, 'Invalid menu key');
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
          Logger.warn(this.TAG, `Unknown menu key: ${key}`);
          break;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle main menu click: ${error}`);
    }
  }
  
  // 处理分类标签点击 | Handle category tab click
  private handleCategoryClick(categoryId: string): void {
    try {
      Logger.info(this.TAG, `Category clicked: ${categoryId}`);

      // 验证分类ID | Validate category ID
      if (!categoryId) {
        Logger.error(this.TAG, 'Invalid category ID');
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
      Logger.error(this.TAG, `Failed to handle category click: ${error}`);
    }
  }
  
  // 处理影视点击 | Handle media click
  private handleMediaClick(media: FeaturedMediaItem): void {
    try {
      Logger.info(this.TAG, `Media clicked: ${media.title}, Source: ${media.sourceName}`);

      // 验证媒体数据完整性 | Validate media data integrity
      if (!media.id || !media.siteKey) {
        Logger.error(this.TAG, 'Invalid media data: missing required fields');
        return;
      }

      const params: DetailParams = {
        id: media.id,
        siteKey: media.siteKey || '',
        type: 'vod'
      };
      AppNavigator.getInstance().navigateToDetail(params);
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle media click: ${error}`);
    }
  }
  
  // 渲染媒体项 | Render media item
  @Builder
  private renderMediaItem(media: FeaturedMediaItem): void {
    Column() {
      Stack() {
        ImageLazyLoader({
          src: media.cover || '',
          imgWidth: '100%',
          imgHeight: this.isLandscape ? 320 : 240,
          imgRadius: 12,
          placeholder: '',
          lazyStrategy: LazyLoadStrategy.VISIBLE
        })
        
        // 来源标识 | Source badge
        if (media.sourceName) {
          ContentSourceBadge({
            sourceName: media.sourceName
          })
          .position({ top: 8, right: 8 })
        }
        
        // 评分标识 | Rating badge
        if (media.rating) {
          Row() {
            Text(media.rating)
              .fontSize(14)
              .fontWeight(600)
              .fontColor('#FFFFFF')
          }
          .backgroundColor('#FF6B35')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
          .position({ bottom: 8, right: 8 })
        }
      }
      .margin({ bottom: 12 })
      
      Text(media.title)
        .fontSize(16)
        .fontWeight(600)
        .maxLines(2)
        .margin({ left: 8, right: 8 })
        .textAlign(TextAlign.Center)
        .fontColor('#FFFFFF')
    }
    .padding(12)
    .backgroundColor('#2C2C2C')
    .borderRadius(16)
    .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.4)', offsetY: 6 })
    .onClick(() => this.handleMediaClick(media))
    .width(this.isLandscape ? 260 : 200)
    .height(this.isLandscape ? 440 : 370)
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
    Column() {
      // 内容标题 | Content title
      Row() {
        Text(title)
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#FFFFFF')
          .margin({ left: 30, top: 24, bottom: 16 })
      }
      
      // 内容区域 | Content area - 使用List实现虚拟列表
      List({
        scroller: this.contentScroller,
        initialIndex: 0,
        space: 20
      }) {
        ForEach(mediaList, (item: FeaturedMediaItem) => {
          ListItem() {
            this.renderMediaItem(item)
          }
          .width(this.isLandscape ? 260 : 200)
          .height(this.isLandscape ? 440 : 370)
        }, (item: FeaturedMediaItem) => `${item.id}_${item.sourceId || 'default'}`)
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Auto)
      .height(this.isLandscape ? 500 : 400)
      .padding({ left: 30, right: 30, bottom: 30 })
    }
  }
  
  build() {
    Column() {
      // 顶部区域 | Top area
      Column() {
        // 顶部信息栏 | Top info bar
        Row() {
          // 应用标题 | App title
          Text('RayTV')
            .fontSize(24)
            .fontWeight(700)
            .fontColor('#FFFFFF')
            .margin({ left: 40 })
          
          // 日期显示 | Date display
          Text(this.currentDate)
            .fontSize(16)
            .fontColor('#E0E0E0')
            .margin({ right: 40 })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .height(80)
        .backgroundColor('#007AFF')
        
        // 主功能菜单 | Main function menu
        Row() {
          ForEach(this.mainMenuItems, (item: TabItem) => {
            Column() {
            Text(item.name)
              .fontSize(18)
              .fontWeight(this.selectedTab === item.key ? 700 : 400)
              .fontColor(this.selectedTab === item.key ? '#007AFF' : '#FFFFFF')
              .padding({ left: 30, right: 30, top: 16, bottom: 16 })
              .border(this.selectedTab === item.key ? { width: { bottom: 3 }, color: '#007AFF' } : { width: { bottom: 0 }, color: 'transparent' })
          }
          .onClick(() => this.handleMainMenuClick(item.key))
          .focusable(true)
          .backgroundColor(this.selectedTab === item.key ? 'rgba(255, 255, 255, 0.1)' : 'transparent')
          .animation({
            duration: 200,
            curve: Curve.EaseOut
          })
          }, (item: TabItem) => item.key)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#1E1E1E')
        .padding({ left: 30 })
      }
      
      // 主内容区域 | Main content area
      if (this.selectedTab === 'vod') {
        Scroll(this.contentScroller) {
          Column() {
            if (this.isLoading) {
          Column() {
            Text(Strings.mainPage.loadingContent)
              .fontSize(18)
              .fontColor('#8E8E93')
              .margin({ top: 30, bottom: 20 })
                
                // 骨架屏 | Skeleton screen
                Row() {
                  ForEach([1, 2, 3, 4, 5], (item: number) => {
                    Column() {
                      // 图片骨架 | Image skeleton
                      Column()
                        .width(this.isLandscape ? 234 : 176)
                        .height(this.isLandscape ? 320 : 240)
                        .backgroundColor('#2C2C2C')
                        .borderRadius(12)
                        .animation({
                          duration: 1000,
                          tempo: 1,
                          curve: Curve.EaseInOut,
                          iterations: -1,
                          delay: item * 100
                        })
                      
                      // 标题骨架 | Title skeleton
                      Column()
                        .width(this.isLandscape ? 216 : 168)
                        .height(40)
                        .backgroundColor('#2C2C2C')
                        .borderRadius(4)
                        .margin({ top: 12 })
                        .animation({
                          duration: 1000,
                          tempo: 1,
                          curve: Curve.EaseInOut,
                          iterations: -1,
                          delay: item * 150
                        })
                    }
                    .padding(12)
                    .width(this.isLandscape ? 260 : 200)
                    .height(this.isLandscape ? 440 : 370)
                  })
                }
                .padding({ left: 30, right: 30, bottom: 30 })
              }
              .justifyContent(FlexAlign.Start)
              .height(this.isLandscape ? 500 : 400)
            } else if (this.isError) {
              Column() {
                Text(Strings.mainPage.loadFailed)
                  .fontSize(18)
                  .fontColor('#FF5252')
                  .margin({ top: 20 })
                Text(this.errorMessage)
                  .fontSize(16)
                  .fontColor('#FF9800')
                  .margin({ top: 12 })
                Button(Strings.common.retry)
                  .onClick(() => this.loadFeaturedMedia())
                  .backgroundColor('#007AFF')
                  .fontColor('white')
                  .borderRadius(20)
                  .padding({ left: 30, right: 30, top: 14, bottom: 14 })
                  .margin({ top: 20 })
                  .fontSize(16)
                  .focusable(true)
              }
              .justifyContent(FlexAlign.Center)
              .height(this.isLandscape ? 500 : 400)
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
        .backgroundColor('#121212')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }
}
