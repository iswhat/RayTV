import { AppNavigator, DetailParams } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ContentAccessService from '../service/content/ContentAccessService';
import display from '@ohos.display';
import { Column, Row, Text, Button, Scroll, ForEach, FlexAlign, TextAlign, VerticalAlign, BarState, HorizontalAlign, Alignment, Curve, List, ListItem, Axis, Stack } from '@ohos/arkui';
import ContentSourceBadge from '../components/ContentSourceBadge';
import ImageLazyLoader from '../components/ImageLazyLoader';

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
  
  // 状态管理 | State management
  @State featuredMedia: FeaturedMediaItem[] = [];
  @State popularMedia: FeaturedMediaItem[] = [];
  @State newMedia: FeaturedMediaItem[] = [];
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '推荐内容加载失败';
  @State selectedTab: string = 'vod';
  @State selectedCategory: string = '全部';
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State currentDate: string = '';
  
  // 导航标签数据 | Navigation tab data
  private mainMenuItems: TabItem[] = [
    { key: 'vod', name: '点播' },
    { key: 'live', name: '直播' },
    { key: 'search', name: '搜索' },
    { key: 'history', name: '历史' },
    { key: 'settings', name: '设置' }
  ];
  
  // 服务实例 | Service instances
  private contentService: ContentAccessService = ContentAccessService.getInstance();

  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'MainPage about to appear');
    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
    // 初始化日期 | Initialize date
    this.updateCurrentDate();
    
    // 每60秒更新一次日期 | Update date every 60 seconds
    setInterval(() => {
      this.updateCurrentDate();
    }, 60000);
    
    // 加载推荐内容 | Load recommended content
    this.loadFeaturedMedia();
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
      
      // 模拟数据 - 实际应该从ContentAccessService获取
      // 这里使用模拟数据以便展示
      this.featuredMedia = [
        {
          id: '1',
          title: '星际穿越',
          cover: 'https://example.com/cover1.jpg',
          type: 'movie',
          siteKey: 'site1',
          rating: '9.3',
          sourceId: 'source1',
          sourceName: '源A'
        },
        {
          id: '2',
          title: '盗梦空间',
          cover: 'https://example.com/cover2.jpg',
          type: 'movie',
          siteKey: 'site2',
          rating: '9.0',
          sourceId: 'source2',
          sourceName: '源B'
        },
        {
          id: '3',
          title: '流浪地球2',
          cover: 'https://example.com/cover3.jpg',
          type: 'movie',
          siteKey: 'site3',
          rating: '8.5',
          sourceId: 'source1',
          sourceName: '源A'
        },
        {
          id: '4',
          title: '阿凡达',
          cover: 'https://example.com/cover4.jpg',
          type: 'movie',
          siteKey: 'site4',
          rating: '8.8',
          sourceId: 'source3',
          sourceName: '源C'
        },
        {
          id: '5',
          title: '复仇者联盟4',
          cover: 'https://example.com/cover5.jpg',
          type: 'movie',
          siteKey: 'site1',
          rating: '8.7',
          sourceId: 'source1',
          sourceName: '源A'
        }
      ];

      this.popularMedia = [
        {
          id: '6',
          title: '泰坦尼克号',
          cover: 'https://example.com/cover6.jpg',
          type: 'movie',
          siteKey: 'site2',
          rating: '9.2',
          sourceId: 'source2',
          sourceName: '源B'
        },
        {
          id: '7',
          title: '肖申克的救赎',
          cover: 'https://example.com/cover7.jpg',
          type: 'movie',
          siteKey: 'site3',
          rating: '9.7',
          sourceId: 'source1',
          sourceName: '源A'
        },
        {
          id: '8',
          title: '霸王别姬',
          cover: 'https://example.com/cover8.jpg',
          type: 'movie',
          siteKey: 'site1',
          rating: '9.6',
          sourceId: 'source3',
          sourceName: '源C'
        }
      ];

      this.newMedia = [
        {
          id: '9',
          title: '沙丘2',
          cover: 'https://example.com/cover9.jpg',
          type: 'movie',
          siteKey: 'site1',
          rating: '8.6',
          sourceId: 'source3',
          sourceName: '源C'
        },
        {
          id: '10',
          title: '哥斯拉-1.0',
          cover: 'https://example.com/cover10.jpg',
          type: 'movie',
          siteKey: 'site2',
          rating: '8.3',
          sourceId: 'source2',
          sourceName: '源B'
        }
      ];
      
      this.isLoading = false;
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to load featured media: ${error}`);
      this.isError = true;
      this.errorMessage = '推荐内容加载失败';
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
          this.selectedTab = 'vod';
          this.loadFeaturedMedia();
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

      this.selectedCategory = categoryId;

      // 这里可以根据分类加载对应内容
      this.loadFeaturedMedia();
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
          imageUrl: media.cover || '',
          width: '100%',
          height: this.isLandscape ? 320 : 240,
          fit: 'cover',
          borderRadius: 12,
          placeholderColor: '#2C2C2C',
          priority: 'high'
        })
        
        // 来源标识 | Source badge
        if (media.sourceName) {
          ContentSourceBadge({
            sourceName: media.sourceName,
            sourceId: media.sourceId || ''
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
    .focusBorderWidth(2)
    .focusBorderColor('#007AFF')
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
              .borderBottom(this.selectedTab === item.key ? { width: 3, color: '#007AFF' } : { width: 0, color: 'transparent' })
          }
          .onClick(() => this.handleMainMenuClick(item.key))
          .focusable(true)
          .focusBorderWidth(2)
          .focusBorderColor('#007AFF')
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
                Text('正在加载推荐内容...')
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
                Text('推荐内容加载失败')
                  .fontSize(18)
                  .fontColor('#FF5252')
                  .margin({ top: 20 })
                Text(this.errorMessage)
                  .fontSize(16)
                  .fontColor('#FF9800')
                  .margin({ top: 12 })
                Button('重试')
                  .onClick(() => this.loadFeaturedMedia())
                  .backgroundColor('#007AFF')
                  .fontColor('white')
                  .borderRadius(20)
                  .padding({ left: 30, right: 30, top: 14, bottom: 14 })
                  .margin({ top: 20 })
                  .fontSize(16)
                  .focusable(true)
                  .focusBorderWidth(2)
                  .focusBorderColor('#007AFF')
              }
              .justifyContent(FlexAlign.Center)
              .height(this.isLandscape ? 500 : 400)
            } else {
              // 推荐内容 | Recommended content
              if (this.featuredMedia.length > 0) {
                this.renderContentSection('为你推荐', this.featuredMedia);
              }
              
              // 热门内容 | Popular content
              if (this.popularMedia.length > 0) {
                this.renderContentSection('热门内容', this.popularMedia);
              }
              
              // 最新内容 | New content
              if (this.newMedia.length > 0) {
                this.renderContentSection('最新上线', this.newMedia);
              }
            }
          }
          .width('100%')
        }
        .scrollable(Axis.Vertical)
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
