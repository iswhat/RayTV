import { AppNavigator, DetailParams, CategoryInfo } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ConfigService from '../service/config/ConfigService';
import MediaService from '../service/media/MediaService';
import display from '@ohos.display';

/**
 * 应用主页面
 * 作为应用的入口页面，显示主要功能区域
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



@Entry
@Component
struct MainPage {
  private readonly TAG: string = 'MainPage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理
  @State featuredMedia: FeaturedMediaItem[] = [];
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '推荐内容加载失败';
  @State selectedTab: string = 'home';
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  
  // 导航标签数据
  private tabs: TabItem[] = [
    { key: 'home', name: '首页' },
    { key: 'movie', name: '电影' },
    { key: 'tv', name: '电视剧' },
    { key: 'variety', name: '综艺' },
    { key: 'anime', name: '动漫' },
    { key: 'korean', name: '日韩剧' },
    { key: 'chinese', name: '国产剧' },
    { key: 'american', name: '欧美剧' },
    { key: 'hk', name: '港台剧' }
  ];
  
  // 服务实例
  private configService: ConfigService = ConfigService.getInstance();
  private mediaService: MediaService = MediaService.getInstance();
  
  // 生命周期
  aboutToAppear() {
    Logger.info(this.TAG, 'MainPage about to appear');
    
    // 初始化屏幕信息
    this.initScreenInfo();
    // 监听屏幕方向变化
    this.registerScreenOrientationListener();
    
    // 跳过配置初始化，直接加载数据
    this.loadFeaturedMedia();
  }
  
  // 初始化屏幕信息
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get screen info: ${error}`);
      // 默认值
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
    }
  }
  
  // 注册屏幕方向监听器
  private registerScreenOrientationListener() {
    try {
      // 移除事件监听，简化实现
      this.updateScreenOrientation();
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to update screen orientation: ${errorMsg}`);
    }
  }
  
  // 更新屏幕方向
  private updateScreenOrientation() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      Logger.info(this.TAG, `Screen orientation updated: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to get display info: ${errorMsg}`);
    }
  }
  
  /**
   * 加载推荐内容
   */
  private async loadFeaturedMedia() {
    try {
      this.isLoading = true;
      this.isError = false;
      Logger.info(this.TAG, 'Loading featured media...');
      
      // 使用MediaService获取实际的推荐内容
      const result = await this.mediaService.getRecommendedContent();
      
      if (result.isSuccess() && result.data && result.data.length > 0) {
        this.featuredMedia = result.data.map(item => ({
          id: item.id,
          title: item.title,
          cover: item.cover || '',
          type: item.type,
          siteKey: item.siteKey,
          rating: item.rating
        } as FeaturedMediaItem));
        Logger.info(this.TAG, `Loaded ${this.featuredMedia.length} featured media items`);
      } else {
        // 加载失败，设置错误状态
        this.isError = true;
        this.errorMessage = result.message || '推荐内容加载失败';
        this.featuredMedia = [];
        Logger.warn(this.TAG, `Failed to load featured media: ${this.errorMessage}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load featured media: ${errorMsg}`);
      this.isError = true;
      this.errorMessage = errorMsg;
      this.featuredMedia = [];
    } finally {
      this.isLoading = false;
    }
  }
  
  // 跳转到分类页面
  private navigateToCategory(category: CategoryInfo) {
    AppNavigator.getInstance().navigateToCategory(category);
  }
  
  // 跳转到搜索页面
  private navigateToSearch() {
    AppNavigator.getInstance().navigateToSearch("");
  }
  
  // 跳转到设置页面
  private navigateToSettings() {
    AppNavigator.getInstance().navigateToSettings();
  }
  
  // 跳转到历史记录页面
  private navigateToHistory() {
    AppNavigator.getInstance().navigateToHistory();
  }
  
  // 跳转到直播页面
  private navigateToLive() {
    AppNavigator.getInstance().navigateToLive();
  }
  
  // 切换线路
  private switchLine() {
    AppNavigator.getInstance().navigateToLineManager();
  }
  
  // 获取当前日期时间
  private getCurrentDate(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    return `${year}年${month}月${day}日 ${hours}:${minutes}:${seconds}`;
  }
  
  // 根据屏幕方向获取Grid列数模板
  private getGridColumnsTemplate(): string {
    if (this.isLandscape) {
      // 横屏模式：更多列
      return '1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr';
    } else {
      // 竖屏模式：较少列
      return '1fr 1fr 1fr 1fr 1fr';
    }
  }
  
  // 渲染媒体项
  @Builder
  renderMediaItem(media: FeaturedMediaItem) {
    Column() {
      // 修复图片显示问题：添加错误处理和默认图片
      Image(media.cover)
        .width('100%')
        .aspectRatio(3/4)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .margin({ top: 10 })
        .backgroundColor('#F5F5F5')
        .onError(() => {
          Logger.warn(this.TAG, `Failed to load cover image: ${media.cover}`);
          // 图片加载失败时，使用占位图片
          // 这里使用系统默认占位图，也可以替换为实际的占位图片资源
        })
      Text(media.title)
        .fontSize(14)
        .maxLines(2)
        .margin({ top: 8, left: 4, right: 4 })
        .textAlign(TextAlign.Center)
      if (media.rating) {
        Text(media.rating)
          .fontSize(12)
          .fontColor('#FF9800')
          .margin({ top: 2, bottom: 8 })
      }
    }
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
    .onClick(() => {
      const params: DetailParams = {
        id: media.id,
        siteKey: media.siteKey || '',
        type: 'vod'
      };
      AppNavigator.getInstance().navigateToDetail(params);
    })
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Column() {
        Row() {
          // 应用标题
          Text("影视 | TV云播[js]")
            .fontSize(16)
            .fontWeight(600)
            .fontColor("#FFFFFF")
            .margin({ left: 20 })
          
          // 日期显示
        Text(this.getCurrentDate())
          .fontSize(14)
          .fontColor("#FFFFFF")
          .margin({ right: 20 })
        }
        .width("100%")
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .height(40)
        .backgroundColor("#4CAF50")
        
        // 导航标签栏
        Scroll() {
          Row() {
            ForEach(this.tabs, (tab: TabItem) => {
              Text(tab.name)
                .fontSize(14)
                .fontWeight(this.selectedTab === tab.key ? 700 : 400)
                .fontColor(this.selectedTab === tab.key ? "#4CAF50" : "#333333")
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .onClick(() => {
                  this.selectedTab = tab.key;
                })
            }, (tab: TabItem) => tab.key)
          }
          .width("100%")
        }
        .backgroundColor("#FFFFFF")
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      
      // 功能按钮栏
      Row() {
        Column() {
          Image("/resources/base/media/app_icon.svg")
            .width(20)
            .height(20)
            .margin({ bottom: 4 })
          Text("历史")
            .fontSize(14)
            .fontColor("#FFFFFF")
        }
        .backgroundColor("#4CAF50")
        .height(70)
        .padding({ left: 20, right: 20 })
        .borderRadius(8)
        .margin({ left: 10 })
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.navigateToHistory())
        
        Column() {
          Image("/resources/base/media/app_icon.svg")
            .width(20)
            .height(20)
            .margin({ bottom: 4 })
          Text("直播")
            .fontSize(14)
            .fontColor("#FFFFFF")
        }
        .backgroundColor("#4CAF50")
        .height(70)
        .padding({ left: 20, right: 20 })
        .borderRadius(8)
        .margin({ left: 10 })
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.navigateToLive())
        
        Column() {
          Image("/resources/base/media/app_icon.svg")
            .width(20)
            .height(20)
            .margin({ bottom: 4 })
          Text("搜索")
            .fontSize(14)
            .fontColor("#FFFFFF")
        }
        .backgroundColor("#4CAF50")
        .height(70)
        .padding({ left: 20, right: 20 })
        .borderRadius(8)
        .margin({ left: 10 })
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.navigateToSearch())
        
        Column() {
          Image("/resources/base/media/app_icon.svg")
            .width(20)
            .height(20)
            .margin({ bottom: 4 })
          Text("线路")
            .fontSize(14)
            .fontColor("#FFFFFF")
        }
        .backgroundColor("#4CAF50")
        .height(70)
        .padding({ left: 20, right: 20 })
        .borderRadius(8)
        .margin({ left: 10 })
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.switchLine())
        
        Column() {
          Image("/resources/base/media/app_icon.svg")
            .width(20)
            .height(20)
            .margin({ bottom: 4 })
          Text("设置")
            .fontSize(14)
            .fontColor("#FFFFFF")
        }
        .backgroundColor("#4CAF50")
        .height(70)
        .padding({ left: 20, right: 20 })
        .borderRadius(8)
        .margin({ left: 10, right: 10 })
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.navigateToSettings())
      }
      .width("100%")
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 10, bottom: 10 })
      .backgroundColor("#F5F5F5")
      
      // 主内容区域
      Scroll(this.scroller) {
        Column() {
          if (this.isLoading) {
            Column() {
              Progress({ value: 50, type: ProgressType.Linear })
                .width("90%")
                .height(4)
                .color("#4CAF50")
              Text("正在加载推荐内容...")
                .fontSize(16)
                .fontColor("#666666")
                .margin(20)
            }
            .justifyContent(FlexAlign.Center)
            .height(200)
          } else if (this.isError) {
            // 显示错误信息和操作按钮
            Column() {
              Image("/resources/base/media/app_icon.svg")
                .width(80)
                .height(80)
                .opacity(0.3)
              Text("推荐内容加载失败")
                .fontSize(16)
                .fontColor("#FF5252")
                .margin({ top: 15 })
              Text(this.errorMessage)
                .fontSize(14)
                .fontColor("#FF9800")
                .margin({ top: 8 })
              Row() {
                Button("重试")
                  .onClick(() => this.loadFeaturedMedia())
                  .backgroundColor("#4CAF50")
                  .fontColor("white")
                  .borderRadius(15)
                  .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                  .margin({ top: 15, right: 10 })
                  .fontSize(14)
                Button("切换片源")
                  .onClick(() => this.switchLine())
                  .backgroundColor("#2196F3")
                  .fontColor("white")
                  .borderRadius(15)
                  .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                  .margin({ top: 15, left: 10 })
                  .fontSize(14)
              }
            }
            .justifyContent(FlexAlign.Center)
            .height(250)
          } else if (this.featuredMedia.length > 0) {
            // 使用Grid布局显示内容，根据屏幕方向自动调整列数
            Grid() {
              ForEach(this.featuredMedia, (item: FeaturedMediaItem) => {
                GridItem() {
                  this.renderMediaItem(item)
                }
              }, (item: FeaturedMediaItem) => item.id)
            }
            .columnsTemplate(this.getGridColumnsTemplate())
            .columnsGap(10)
            .rowsGap(10)
            .padding({ left: 10, right: 10 })
            .height("auto")
            .backgroundColor("#F5F5F5")
          } else {
            Column() {
              Image("/resources/base/media/app_icon.svg")
                .width(80)
                .height(80)
                .opacity(0.3)
              Text("暂无推荐内容")
                .fontSize(16)
                .fontColor("#999999")
                .margin({ top: 15 })
              Text("请确保已配置视频源")
                .fontSize(14)
                .fontColor("#CCCCCC")
                .margin({ top: 8 })
              Button("去配置")
                .onClick(() => this.navigateToSettings())
                .backgroundColor("#4CAF50")
                .fontColor("white")
                .borderRadius(15)
                .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                .margin({ top: 15 })
                .fontSize(14)
            }
            .justifyContent(FlexAlign.Center)
            .height(250)
          }
        }
        .width("100%")
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .flexGrow(1)
      .backgroundColor("#F5F5F5")
    }
    .width('100%')
    .height('100%')
    .backgroundColor("#F5F5F5")
  }
}