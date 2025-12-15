import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ConfigService from '../service/config/ConfigService';
import MediaService from '../service/media/MediaService';

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
}

@Entry
@Component
struct MainPage {
  private readonly TAG: string = 'MainPage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理
  @State featuredMedia: FeaturedMediaItem[] = [];
  @State isLoading: boolean = true;
  
  // 服务实例
  private configService: ConfigService = ConfigService.getInstance();
  private mediaService: MediaService = MediaService.getInstance();
  
  // 生命周期
  aboutToAppear() {
    Logger.info(this.TAG, 'MainPage about to appear');
    
    // 跳过配置初始化，直接加载数据
    this.loadFeaturedMedia();
  }
  
  /**
   * 加载推荐内容
   */
  private async loadFeaturedMedia() {
    try {
      this.isLoading = true;
      // 简化实现，直接使用模拟数据
      this.featuredMedia = [];
      Logger.info(this.TAG, 'Loaded featured media items');
    } catch (error) {
      Logger.error(this.TAG, `Failed to load featured media: ${error}`);
      this.featuredMedia = [];
    } finally {
      this.isLoading = false;
    }
  }
  
  // 跳转到分类页面
  private navigateToCategory() {
    AppNavigator.getInstance().navigateToCategory({ id: "", name: "", type: "" });
  }
  
  // 跳转到搜索页面
  private navigateToSearch() {
    AppNavigator.getInstance().navigateToSearch("");
  }
  
  // 跳转到设置页面
  private navigateToSettings() {
    AppNavigator.getInstance().navigateToSettings();
  }
  
  // 渲染媒体项
  @Builder
  renderMediaItem(media: FeaturedMediaItem) {
    ListItem() {
      Column() {
        Image(media.cover)
          .width(150)
          .height(200)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
        Text(media.title)
          .fontSize(14)
          .maxLines(2)
          .margin(8)
      }
      .padding(10)
    }
    .onClick(() => AppNavigator.getInstance().navigateToDetail({ id: media.id, siteKey: media.siteKey || '', type: 'vod' }))
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text("RayTV")
          .fontSize(24)
          .fontWeight(700)
        Row() {
          Button("搜索")
            .onClick(() => this.navigateToSearch())
            .margin(10)
          Button("设置")
            .onClick(() => this.navigateToSettings())
        }
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(20)
      
      // 分类入口
      Button("浏览分类")
        .onClick(() => this.navigateToCategory())
        .backgroundColor("#007AFF")
        .fontColor("white")
        .width("100%")
        .padding(12)
        .fontSize(16)
        .margin(20)
      
      // 推荐内容
      Text("推荐内容")
        .fontSize(20)
        .fontWeight(700)
        .margin(20)
      
      if (this.isLoading) {
        Text("加载中..")
          .fontSize(16)
          .margin(20)
      } else {
        List() {
          ForEach(this.featuredMedia, (item: FeaturedMediaItem) => {
            this.renderMediaItem(item)
          }, (item: FeaturedMediaItem) => item.id)
        }
        .height(250)
        .margin(20)
      }
      
      // 底部提示
      Text("请确保已配置视频源以获得最佳体验")
        .fontSize(12)
        .fontColor("#888888")
        .margin(20)
        .textAlign(TextAlign.Center)
    }
    .padding(20)
  }
}
