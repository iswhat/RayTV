import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ConfigService from '../service/config/ConfigService';
import MediaService from '../service/media/MediaService';
import display from '@ohos.display';

/**
 * 应用主页面
 * 作为应用的入口页面，显示主要功能区域
 */
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
  @State selectedTab: string = 'home';
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  
  // 导航标签数据
  private tabs: Array<{ key: string, name: string }> = [
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
      const displayId = display.getDefaultDisplaySync().id;
      display.on('change', displayId, (info) => {
        Logger.info(this.TAG, `Display change: ${JSON.stringify(info)}`);
        this.screenWidth = info.width;
        this.screenHeight = info.height;
        this.isLandscape = this.screenWidth > this.screenHeight;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to register screen orientation listener: ${error}`);
    }
  }
  
  /**
   * 加载推荐内容
   */
  private async loadFeaturedMedia() {
    try {
      this.isLoading = true;
      // 简化实现，使用模拟数据
      this.featuredMedia = [
        { id: '1', title: '天剑心', cover: 'https://example.com/cover1.jpg', type: 'vod', rating: '7.2' },
        { id: '2', title: '毕正明的证明', cover: 'https://example.com/cover2.jpg', type: 'vod', rating: '7.6' },
        { id: '3', title: '命悬一生', cover: 'https://example.com/cover3.jpg', type: 'vod', rating: '7.4' },
        { id: '4', title: '花漾少女杀人事件', cover: 'https://example.com/cover4.jpg', type: 'vod', rating: '6.5' },
        { id: '5', title: '许你耀眼', cover: 'https://example.com/cover5.jpg', type: 'vod', rating: '8.1' },
        { id: '6', title: '沉默的荣耀', cover: 'https://example.com/cover6.jpg', type: 'vod', rating: '9.0' }
      ];
      Logger.info(this.TAG, 'Loaded featured media items');
    } catch (error) {
      Logger.error(this.TAG, `Failed to load featured media: ${error}`);
      this.featuredMedia = [];
    } finally {
      this.isLoading = false;
    }
  }
  
  // 跳转到分类页面
  private navigateToCategory(category: { id: string, name: string, type: string }) {
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
    // 实现线路切换逻辑
    Logger.info(this.TAG, 'Switching line');
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
      Image(media.cover)
        .width('100%')
        .aspectRatio(3/4)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .margin({ top: 10 })
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
    .onClick(() => AppNavigator.getInstance().navigateToDetail({ id: media.id, siteKey: media.siteKey || '', type: 'vod' }))
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
            ForEach(this.tabs, (tab) => {
              Text(tab.name)
                .fontSize(14)
                .fontWeight(this.selectedTab === tab.key ? 700 : 400)
                .fontColor(this.selectedTab === tab.key ? "#4CAF50" : "#333333")
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .borderBottomWidth(this.selectedTab === tab.key ? 3 : 0)
                .borderBottomColor("#4CAF50")
                .onClick(() => {
                  this.selectedTab = tab.key;
                })
            }, (tab) => tab.key)
          }
          .width("100%")
        }
        .backgroundColor("#FFFFFF")
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      
      // 功能按钮栏
      Row() {
        Button() {
          Row() {
            Image("/resources/base/media/app_icon.svg")
              .width(20)
              .height(20)
            Text("历史")
              .fontSize(14)
              .margin({ left: 4 })
          }
        }
        .backgroundColor("#FFFFFF")
        .fontColor("#333333")
        .height(40)
        .padding({ left: 15, right: 15 })
        .borderRadius(20)
        .margin({ left: 10 })
        .onClick(() => this.navigateToHistory())
        
        Button() {
          Row() {
            Image("/resources/base/media/app_icon.svg")
              .width(20)
              .height(20)
            Text("直播")
              .fontSize(14)
              .margin({ left: 4 })
          }
        }
        .backgroundColor("#FFFFFF")
        .fontColor("#333333")
        .height(40)
        .padding({ left: 15, right: 15 })
        .borderRadius(20)
        .margin({ left: 10 })
        .onClick(() => this.navigateToLive())
        
        Button() {
          Row() {
            Image("/resources/base/media/app_icon.svg")
              .width(20)
              .height(20)
            Text("搜索")
              .fontSize(14)
              .margin({ left: 4 })
          }
        }
        .backgroundColor("#FFFFFF")
        .fontColor("#333333")
        .height(40)
        .padding({ left: 15, right: 15 })
        .borderRadius(20)
        .margin({ left: 10 })
        .onClick(() => this.navigateToSearch())
        
        Button() {
          Row() {
            Image("/resources/base/media/app_icon.svg")
              .width(20)
              .height(20)
            Text("线路")
              .fontSize(14)
              .margin({ left: 4 })
          }
        }
        .backgroundColor("#FFFFFF")
        .fontColor("#333333")
        .height(40)
        .padding({ left: 15, right: 15 })
        .borderRadius(20)
        .margin({ left: 10 })
        .onClick(() => this.switchLine())
        
        Button() {
          Row() {
            Image("/resources/base/media/app_icon.svg")
              .width(20)
              .height(20)
            Text("设置")
              .fontSize(14)
              .margin({ left: 4 })
          }
        }
        .backgroundColor("#FFFFFF")
        .fontColor("#333333")
        .height(40)
        .padding({ left: 15, right: 15 })
        .borderRadius(20)
        .margin({ left: 10, right: 10 })
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
    .flexDirection(FlexDirection.Column)
  }
}