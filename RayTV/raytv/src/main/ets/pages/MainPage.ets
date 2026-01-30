import { AppNavigator, DetailParams } from '../navigation/AppNavigator';
// Logger import removed as AnalyticsService was deleted
import ConfigService from '../service/config/ConfigService';
import { MediaService, RecommendedContent } from '../service/media/MediaService';
import CacheService from '../service/cache/CacheService';

import ApiResponse from '../data/dto/ApiResponse';
import display from '@ohos.display';
import { Column, Row, Text, Button, Image, Scroll, ForEach, FlexAlign, TextAlign, VerticalAlign, ImageFit, BarState, HorizontalAlign, Alignment } from '@ohos/components';


/**
 * 应用主页面 | Application main page
 * 作为应用的入口页面，显示主要功能区域 | As the application's entry page, display main functional areas
 */
interface TabItem {
  key: string;
  name: string;
}

interface FeaturedMediaItem {
  id: string;
  title: string;
  cover: string;
  type: string;
  siteKey?: string;
  rating?: string;
}

interface MediaServiceItem {
  id: string;
  title: string;
  cover?: string;
  type?: string;
  siteKey?: string;
  rating?: string;
}

interface CategoryTab {
  id: string;
  name: string;
}

/**
 * 响应数据接口 | Response data interface
 */
interface SuccessMediaResponse {
  isSuccess: () => boolean;
  data: MediaServiceItem[];
  message?: string;
}

@Entry
@Component
struct MainPage {
  private readonly TAG: string = 'MainPage';
  private scroller: Scroller = new Scroller();
  private contentScroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State featuredMedia: FeaturedMediaItem[] = [];
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '推荐内容加载失败';
  @State selectedTab: string = 'vod';
  @State selectedCategory: string = '全部';
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State currentSite: string = '默认片源';
  @State showSiteDialog: boolean = false;
  @State categories: CategoryTab[] = [];
  
  // 导航标签数据 | Navigation tab data
  private mainMenuItems: TabItem[] = [
    { key: 'vod', name: '点播' },
    { key: 'live', name: '直播' },
    { key: 'search', name: '搜索' },
    { key: 'history', name: '历史' },
    { key: 'config', name: '配置源' },
    { key: 'settings', name: '设置' }
  ];
  
  // 服务实例 | Service instances
  private configService: ConfigService = ConfigService.getInstance();
  private mediaService: MediaService = MediaService.getInstance();
  private cacheService: CacheService = CacheService.getInstance();

  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    console.info('MainPage about to appear');
    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
    // 加载分类 | Load categories
    this.loadCategories();
    
    // 加载推荐内容 | Load recommended content
    this.loadFeaturedMedia();
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      console.info('Screen info: width=' + this.screenWidth + ', height=' + this.screenHeight + ', landscape=' + this.isLandscape);
    } catch (error: Error) {
      console.error('Failed to get screen info: ' + error.message);
      // 默认值 | Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
    }
  }
  
  /**
   * 加载分类 | Load categories
   */
  private async loadCategories(): Promise<void> {
    try {
      // 使用默认分类 | Use default categories
      this.categories = [
        { id: 'all', name: '全部' },
        { id: 'movie', name: '电影' },
        { id: 'tv', name: '电视剧' },
        { id: 'variety', name: '综艺' },
        { id: 'anime', name: '动画' },
        { id: 'korean', name: '韩剧' },
        { id: 'chinese', name: '国产剧' },
        { id: 'american', name: '美剧' },
        { id: 'hk', name: '港剧' }
      ];
    } catch (error: Error) {
      console.error('Failed to load categories: ' + error.message);
      // 使用默认分类 | Use default categories
      this.categories = [
        { id: 'all', name: '全部' },
        { id: 'movie', name: '电影' },
        { id: 'tv', name: '电视剧' },
        { id: 'variety', name: '综艺' },
        { id: 'anime', name: '动画' },
        { id: 'korean', name: '韩剧' },
        { id: 'chinese', name: '国产剧' },
        { id: 'american', name: '美剧' },
        { id: 'hk', name: '港剧' }
      ];
    }
  }
  
  /**
   * 简化条件判断的辅助方法 | Helper method to simplify condition checking
   */
  private isSuccessResponse(response: ApiResponse<RecommendedContent[]>): boolean {
    return typeof response === 'object' && 
           response !== null && 
           typeof response.isSuccess === 'function' && 
           response.isSuccess() && 
           response.data !== undefined && 
           Array.isArray(response.data) && 
           response.data.length > 0;
  }

  /**
   * 加载推荐内容 | Load recommended content
   */
  private async loadFeaturedMedia(): Promise<void> {
    try {
      this.isLoading = true;
      this.isError = false;
      console.info('Loading featured media...');
      
      // 生成缓存键 | Generate cache key
      const cacheKey = 'featured_media_' + this.selectedCategory + '_' + this.currentSite;
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedData: FeaturedMediaItem[] | null = await this.cacheService.get<FeaturedMediaItem[]>(cacheKey);
      
      if (cachedData && cachedData.length > 0) {
        this.featuredMedia = cachedData;
        console.info('Loaded ' + this.featuredMedia.length + ' featured media items from cache');
        this.isLoading = false;
        return;
      }
      
      // 使用MediaService获取实际的推荐内容 | Use MediaService to get actual recommended content
      const result = await this.mediaService.getRecommendedContent();
      
      if (this.isSuccessResponse(result)) {
        // 确保data不是undefined | Ensure data is not undefined
        const data = result.data as RecommendedContent[];
        this.featuredMedia = data.map((item: RecommendedContent) => {
          const mediaItem: FeaturedMediaItem = {
            id: item.id,
            title: item.title,
            cover: item.cover || '',
            type: item.type || 'vod',
            siteKey: item.siteKey,
            rating: item.rating
          };
          return mediaItem;
        });
        console.info('Loaded ' + this.featuredMedia.length + ' featured media items from service');
        
        // 缓存结果 | Cache result
        await this.cacheService.set(cacheKey, this.featuredMedia);
      } else {
        // 加载失败，设置错误状态 | Loading failed, set error state
        this.isError = true;
        // 确保message不是undefined | Ensure message is not undefined
        const message = result.message;
        this.errorMessage = typeof message === 'string' ? message : '推荐内容加载失败';
        this.featuredMedia = [];
        console.warn('Failed to load featured media: ' + this.errorMessage);
      }
    } catch (error: Error) {
      console.error('Failed to load featured media: ' + error.message);
      this.isError = true;
      this.errorMessage = error.message;
      this.featuredMedia = [];
    } finally {
      this.isLoading = false;
    }
  }
  
  // 处理主菜单点击 | Handle main menu click
  private handleMainMenuClick(key: string): void {
    console.info('Main menu clicked: ' + key);
    

    
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
      case 'config':
        AppNavigator.getInstance().navigateToLineManager();
        break;
      case 'settings':
        AppNavigator.getInstance().navigateToSettings();
        break;
    }
  }
  
  // 处理分类标签点击 | Handle category tab click
  private handleCategoryClick(categoryId: string): void {
    this.selectedCategory = categoryId;
    console.info('Category clicked: ' + categoryId);

    // 这里可以根据分类加载对应内容
    this.loadFeaturedMedia();
  }
  
  // 处理片源切换 | Handle site switch
  private handleSiteSwitch(): void {
    this.showSiteDialog = true;

  }
  
  // 处理影视点击 | Handle media click
  private handleMediaClick(media: FeaturedMediaItem): void {
    console.info('Media clicked: ' + media.title);

    const params: DetailParams = {
      id: media.id,
      siteKey: media.siteKey || '',
      type: 'vod'
    };
    AppNavigator.getInstance().navigateToDetail(params);
  }
  
  // 获取当前日期时间 | Get current date time
  private getCurrentDate(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    return year + '年' + month + '月' + day + '日 ' + hours + ':' + minutes;
  }
  
  // 渲染媒体项 | Render media item
  @Builder
  private renderMediaItem(media: FeaturedMediaItem): void {
    Column() {
      Image(media.cover || 'https://via.placeholder.com/300x450?text=No+Image')
        .width('100%')
        .aspectRatio(2/3)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .backgroundColor('#1E1E1E')
        .onError(() => {
          console.warn('Failed to load cover image: ' + media.cover);
        })
      
      Text(media.title)
        .fontSize(16)
        .maxLines(2)
        .margin({ top: 12, left: 8, right: 8 })
        .textAlign(TextAlign.Center)
        .fontColor('#FFFFFF')
      
      if (media.rating) {
        Text(media.rating)
          .fontSize(14)
          .fontColor('#FF9800')
          .margin({ top: 4, bottom: 12 })
      }
    }
    .padding(12)
    .backgroundColor('#2C2C2C')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.3)', offsetY: 4 })
    .onClick(() => this.handleMediaClick(media))
    .width(this.isLandscape ? 240 : 180)
    .height(this.isLandscape ? 420 : 350)
  }
  
  // 渲染片源选择弹窗 | Render site selection dialog
  @Builder
  private renderSiteDialog(): void {
    Stack({
      alignContent: Alignment.Center
    }) {
      // 半透明背景 | Semi-transparent background
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.8)')
        .onClick(() => this.showSiteDialog = false)
      
      // 弹窗内容 | Dialog content
      Column() {
        Text('选择片源')
          .fontSize(24)
          .fontWeight(700)
          .fontColor('#FFFFFF')
          .margin({ bottom: 24 })
        
        // 片源列表 | Site list
        Column() {
          Text('默认片源')
            .fontSize(18)
            .fontColor('#4CAF50')
            .padding(20)
            .backgroundColor('#2C2C2C')
            .borderRadius(12)
            .margin({ bottom: 12 })
            .onClick(() => {
              this.currentSite = '默认片源';
              this.showSiteDialog = false;
              this.loadFeaturedMedia();
            })
          
          Text('备用片源')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .padding(20)
            .backgroundColor('#1E1E1E')
            .borderRadius(12)
            .onClick(() => {
              this.currentSite = '备用片源';
              this.showSiteDialog = false;
              this.loadFeaturedMedia();
            })
        }
        .width('80%')
        
        // 取消按钮 | Cancel button
        Button('取消')
          .width('80%')
          .margin({ top: 24 })
          .backgroundColor('#444444')
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .padding(16)
          .onClick(() => this.showSiteDialog = false)
      }
      .width('60%')
      .padding(24)
      .backgroundColor('#1A1A1A')
      .borderRadius(16)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
  
  build() {
    Column() {
      // 顶部区域 | Top area
      Column() {
        // 顶部信息栏 | Top info bar
        Row() {
          // 片源名称 | Site name
          Text(this.currentSite)
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#FFFFFF')
            .margin({ left: 40 })
            .onClick(() => this.handleSiteSwitch())
          
          // 日期显示 | Date display
          Text(this.getCurrentDate())
            .fontSize(16)
            .fontColor('#E0E0E0')
            .margin({ right: 40 })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .height(70)
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
            }
            .onClick(() => this.handleMainMenuClick(item.key))
          }, (item: TabItem) => item.key)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#1E1E1E')
        .padding({ left: 30 })
        
        // 分类标签栏 | Category tab bar
        if (this.selectedTab === 'vod') {
          Scroll(this.scroller) {
            Row() {
              ForEach(this.categories, (category: CategoryTab) => {
                Text(category.name)
                  .fontSize(16)
                  .fontWeight(this.selectedCategory === category.id ? 700 : 400)
                  .fontColor(this.selectedCategory === category.id ? '#007AFF' : '#E0E0E0')
                  .padding({ left: 24, right: 24, top: 12, bottom: 12 })
                  .backgroundColor(this.selectedCategory === category.id ? 'rgba(0, 122, 255, 0.2)' : 'transparent')
                  .borderRadius(24)
                  .margin({ right: 16 })
                  .onClick(() => this.handleCategoryClick(category.id))
              }, (category: CategoryTab) => category.id)
            }
            .width('100%')
            .padding({ left: 30, right: 30, top: 16, bottom: 16 })
          }
          .scrollBar(BarState.Off)
          .backgroundColor('#121212')
        }
      }
      
      // 主内容区域 | Main content area
      if (this.selectedTab === 'vod') {
        Column() {
          if (this.isLoading) {
            Column() {
              Text('正在加载推荐内容...')
                .fontSize(18)
                .fontColor('#8E8E93')
                .margin(30)
            }
            .justifyContent(FlexAlign.Center)
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
              Row() {
                Button('重试')
                  .onClick(() => this.loadFeaturedMedia())
                  .backgroundColor('#007AFF')
                  .fontColor('white')
                  .borderRadius(18)
                  .padding({ left: 24, right: 24, top: 12, bottom: 12 })
                  .margin({ top: 20, right: 16 })
                  .fontSize(16)
                Button('切换源')
                  .onClick(() => this.handleSiteSwitch())
                  .backgroundColor('#34C759')
                  .fontColor('white')
                  .borderRadius(18)
                  .padding({ left: 24, right: 24, top: 12, bottom: 12 })
                  .margin({ top: 20, left: 16 })
                  .fontSize(16)
              }
            }
            .justifyContent(FlexAlign.Center)
            .height(this.isLandscape ? 500 : 400)
          } else if (this.featuredMedia.length > 0) {
            // 内容标题 | Content title
            Row() {
              Text('推荐内容')
                .fontSize(24)
                .fontWeight(700)
                .fontColor('#FFFFFF')
                .margin({ left: 30, top: 24, bottom: 16 })
            }
            
            // 内容区域 | Content area
            Scroll(this.contentScroller) {
              Row() {
                ForEach(this.featuredMedia, (item: FeaturedMediaItem) => {
                  this.renderMediaItem(item)
                }, (item: FeaturedMediaItem) => item.id)
              }
              .padding({ left: 30, right: 30, bottom: 30 })
            }
            .scrollBar(BarState.Auto)
            .height(this.isLandscape ? 500 : 400)
          } else {
            Column() {
              Text('无推荐内容')
                .fontSize(18)
                .fontColor('#8E8E93')
                .margin({ top: 20 })
              Text('请确保已配置视频源')
                .fontSize(16)
                .fontColor('#8E8E93')
                .margin({ top: 12 })
              Button('去配置')
                .onClick(() => AppNavigator.getInstance().navigateToSettings())
                .backgroundColor('#007AFF')
                .fontColor('white')
                .borderRadius(18)
                .padding({ left: 24, right: 24, top: 12, bottom: 12 })
                .margin({ top: 20 })
                .fontSize(16)
            }
            .justifyContent(FlexAlign.Center)
            .height(this.isLandscape ? 500 : 400)
          }
        }
        .flexGrow(1)
        .backgroundColor('#121212')
      }
      
      // 片源选择弹窗 | Site selection dialog
      if (this.showSiteDialog) {
        this.renderSiteDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }
}
