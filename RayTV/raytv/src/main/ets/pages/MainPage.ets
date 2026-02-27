import { AppNavigator, DetailParams } from '../navigation/AppNavigator';
// Logger import removed as AnalyticsService was deleted
import ConfigService from '../service/config/ConfigService';
import { MediaService, RecommendedContent } from '../service/media/MediaService';
import CacheService from '../service/cache/CacheService';
import { ImageLazyLoader } from '../components/ImageLazyLoader';

import ApiResponse from '../data/dto/ApiResponse';
import display from '@ohos.display';
import { Column, Row, Text, Button, Image, Scroll, ForEach, FlexAlign, TextAlign, VerticalAlign, ImageFit, BarState, HorizontalAlign, Alignment, Curve, List, ListItem, Axis } from '@ohos/arkui';


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
  @State currentDate: string = '';
  
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
    
    // 初始化日期 | Initialize date
    this.updateCurrentDate();
    
    // 每60秒更新一次日期 | Update date every 60 seconds
    setInterval(() => {
      this.updateCurrentDate();
    }, 60000);
    
    // 加载分类 | Load categories
    this.loadCategories();
    
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
      console.info('Screen info: width=' + this.screenWidth + ', height=' + this.screenHeight + ', landscape=' + this.isLandscape);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error('Failed to get screen info: ' + err.message);
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
      
      // 生成缓存键 | Generate cache key
      const cacheKey = `featured_${this.selectedTab}_${this.selectedCategory}_${this.currentSite}`;
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedData = await this.cacheService.get<FeaturedMediaItem[]>(cacheKey);
      if (cachedData && cachedData.length > 0) {
        this.featuredMedia = cachedData;
        this.isLoading = false;
        console.info('Loaded featured media from cache');
        return;
      }
      
      // 调用真实的API获取推荐内容 | Call real API to get recommended content
      const response = await this.mediaService.getPersonalizedRecommendations();
      
      if (response.isSuccess() && response.data && response.data.length > 0) {
        // 转换数据格式 | Convert data format
        this.featuredMedia = response.data.map(item => ({
          id: item.id,
          title: item.title,
          cover: item.cover,
          type: item.type,
          siteKey: item.siteKey,
          rating: item.rating
        }));
        
        // 缓存数据 | Cache data
        this.cacheService.set(cacheKey, this.featuredMedia, {
          expiry: 3600000, // 1小时缓存
          priority: 'high',
          tags: ['featured', 'media']
        }).catch(error => {
          console.error('Failed to cache featured media:', error);
        });
      } else {
        // 如果没有数据，使用空数组 | Use empty array if no data
        this.featuredMedia = [];
      }
      
      this.isLoading = false;
      
    } catch (error) {
      console.error('Failed to load featured media:', error);
      this.isError = true;
      this.errorMessage = '推荐内容加载失败';
      this.isLoading = false;
    }
  }
  
  // 加载分类 | Load categories
  private async loadCategories(): Promise<void> {
    try {
      // 生成缓存键 | Generate cache key
      const cacheKey = 'categories';
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedData = await this.cacheService.get<CategoryTab[]>(cacheKey);
      if (cachedData && cachedData.length > 0) {
        this.categories = cachedData;
        console.info('Loaded categories from cache');
        return;
      }
      
      // 从实际站点获取分类数据 | Get category data from actual sites
      // 这里我们使用固定的分类列表，因为分类通常是相对固定的
      // Use fixed category list since categories are usually relatively fixed
      this.categories = [
        { id: '全部', name: '全部' },
        { id: '电影', name: '电影' },
        { id: '电视剧', name: '电视剧' },
        { id: '综艺', name: '综艺' },
        { id: '动漫', name: '动漫' },
        { id: '纪录片', name: '纪录片' }
      ];
      
      // 缓存数据 | Cache data
      this.cacheService.set(cacheKey, this.categories, {
        expiry: 86400000, // 24小时缓存
        priority: 'high',
        tags: ['categories']
      }).catch(error => {
        console.error('Failed to cache categories:', error);
      });
      
    } catch (error) {
      console.error('Failed to load categories:', error);
      this.categories = [{ id: '全部', name: '全部' }];
    }
  }
  
  // 处理主菜单点击 | Handle main menu click
  private handleMainMenuClick(key: string): void {
    try {
      console.info('Main menu clicked: ' + key);

      // 验证菜单键值 | Validate menu key
      if (!key) {
        console.error('Invalid menu key');
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
        case 'config':
          AppNavigator.getInstance().navigateToLineManager();
          break;
        case 'settings':
          AppNavigator.getInstance().navigateToSettings();
          break;
        default:
          console.warn('Unknown menu key: ' + key);
          break;
      }
    } catch (error) {
      console.error('Failed to handle main menu click:', error);
    }
  }
  
  // 处理分类标签点击 | Handle category tab click
  private handleCategoryClick(categoryId: string): void {
    try {
      console.info('Category clicked: ' + categoryId);

      // 验证分类ID | Validate category ID
      if (!categoryId) {
        console.error('Invalid category ID');
        return;
      }

      this.selectedCategory = categoryId;

      // 这里可以根据分类加载对应内容
      this.loadFeaturedMedia();
    } catch (error) {
      console.error('Failed to handle category click:', error);
    }
  }
  
  // 处理片源切换 | Handle site switch
  private handleSiteSwitch(): void {
    try {
      console.info('Site switch requested');
      this.showSiteDialog = true;
    } catch (error) {
      console.error('Failed to handle site switch:', error);
    }
  }
  
  // 处理影视点击 | Handle media click
  private handleMediaClick(media: FeaturedMediaItem): void {
    try {
      console.info('Media clicked: ' + media.title);

      // 验证媒体数据完整性 | Validate media data integrity
      if (!media.id || !media.siteKey) {
        console.error('Invalid media data: missing required fields');
        return;
      }

      const params: DetailParams = {
        id: media.id,
        siteKey: media.siteKey || '',
        type: 'vod'
      };
      AppNavigator.getInstance().navigateToDetail(params);
    } catch (error) {
      console.error('Failed to handle media click:', error);
    }
  }
  

  
  // 渲染媒体项 | Render media item
  @Builder
  private renderMediaItem(media: FeaturedMediaItem): void {
    Column() {
      ImageLazyLoader({
        src: media.cover || 'https://via.placeholder.com/300x450?text=No+Image',
        placeholder: 'https://via.placeholder.com/300x450?text=Loading',
        errorPlaceholder: 'https://via.placeholder.com/300x450?text=Error',
        width: '100%',
        height: this.isLandscape ? 320 : 240,
        borderRadius: 8,
        onLoad: (src: string) => {
          console.info('Image loaded: ' + src);
        },
        onError: (error: Error) => {
          console.warn('Failed to load cover image: ' + media.cover);
        }
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
          Text(this.currentDate)
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
                .margin({ top: 30, bottom: 20 })
              
              // 骨架屏 | Skeleton screen
              Row() {
                ForEach([1, 2, 3, 4, 5], (item: number) => {
                  Column() {
                    // 图片骨架 | Image skeleton
                    Column()
                      .width(this.isLandscape ? 216 : 156)
                      .height(this.isLandscape ? 320 : 240)
                      .backgroundColor('#2C2C2C')
                      .borderRadius(8)
                      .animation({
                        duration: 1000,
                        tempo: 1,
                        curve: Curve.EaseInOut,
                        iterations: -1,
                        delay: item * 100
                      })
                    
                    // 标题骨架 | Title skeleton
                    Column()
                      .width(this.isLandscape ? 192 : 144)
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
                    
                    // 评分骨架 | Rating skeleton
                    Column()
                      .width(this.isLandscape ? 60 : 48)
                      .height(20)
                      .backgroundColor('#2C2C2C')
                      .borderRadius(4)
                      .margin({ top: 8 })
                      .animation({
                        duration: 1000,
                        tempo: 1,
                        curve: Curve.EaseInOut,
                        iterations: -1,
                        delay: item * 200
                      })
                  }
                  .padding(12)
                  .width(this.isLandscape ? 240 : 180)
                  .height(this.isLandscape ? 420 : 350)
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
            
            // 内容区域 | Content area - 使用List实现虚拟列表
            List({
              scroller: this.contentScroller,
              initialIndex: 0,
              space: 16
            }) {
              ForEach(this.featuredMedia, (item: FeaturedMediaItem) => {
                ListItem() {
                  this.renderMediaItem(item)
                }
                .width(this.isLandscape ? 240 : 180)
                .height(this.isLandscape ? 420 : 350)
              }, (item: FeaturedMediaItem) => item.id)
            }
            .listDirection(Axis.Horizontal)
            .scrollBar(BarState.Auto)
            .height(this.isLandscape ? 500 : 400)
            .padding({ left: 30, right: 30, bottom: 30 })
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
