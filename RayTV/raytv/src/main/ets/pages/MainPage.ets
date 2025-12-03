import { Button, Image, List } from '@ohos/arkui';
import { AppNavigator, PageRoute } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { mediaService } from '../service/media/MediaService';
import { configService } from '../service/config/ConfigService';
import { RecommendationRepository, RecommendationType, RecommendationItem } from '../data/repository/RecommendationRepository';

/**
 * 应用主页�?
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
  
  // 状态管�?
  @State featuredMedia: FeaturedMediaItem[] = [];
  @State isLoading: boolean = true;
  
  // 生命周期
  aboutToAppear() {
    Logger.info(`${this.TAG}: MainPage about to appear`);
    
    // 初始化并检查配�?
    this.initializeConfig();
  }
  
  /**
   * 初始化配置并加载数据
   */
  private async initializeConfig() {
    try {
      // 确保配置服务已初始化
      if (!configService.isInitialized) {
        await configService.initializeConfig();
        Logger.info(`${this.TAG}: ConfigService initialized successfully`);
      }
      
      // 检查是否应该显示推荐内�?
      const showRecommendations = configService.getConfig('showRecommendedContent') as boolean;
      
      if (showRecommendations) {
        // 加载推荐内容
        this.loadFeaturedMedia();
      } else {
        Logger.info(`${this.TAG}: Recommended content is disabled in config`);
        this.isLoading = false;
      }
    } catch (error) {
      Logger.error(this.TAG, 'Failed to initialize config', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      // 发生错误时仍尝试加载内容
      this.loadFeaturedMedia();
    }
  }
  
  /**
   * 加载推荐内容
   */
  private async loadFeaturedMedia() {
    try {
      this.isLoading = true;
      const recommendationRepo = RecommendationRepository.getInstance();
      
      // 获取精选推荐内�?
      const response = await recommendationRepo.getRecommendations({
        type: RecommendationType.FEATURED,
        limit: 10,
        contentTypes: ['video']
      });
      
      // 转换推荐项目为页面所需格式
      this.featuredMedia = response.items.map((item: RecommendationItem) => {
        // 提取数据中的必要信息
        const data = item.data || {};
        return {
          id: item.id,
          title: data.title as string || '未命名内�?,
          cover: data.coverUrl as string || data.imageUrl as string || '/resources/images/default_cover.jpg',
          type: data.type as string || item.type,
          siteKey: data.siteKey as string
        };
      });
      
      Logger.info(`${this.TAG}: Loaded ${this.featuredMedia.length} featured media items`);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to load featured media', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
      
      // 尝试从MediaService获取数据作为后备
      try {
        Logger.info(`${this.TAG}: Trying to load data from MediaService as fallback`);
        const fallbackData = await mediaService.getPopularContent();
        
        if (fallbackData && fallbackData.length > 0) {
          this.featuredMedia = fallbackData.map((item: { id?: string; title?: string; coverUrl?: string; imageUrl?: string; type?: string; siteKey?: string }) => ({
            id: item.id || String(Math.random()),
            title: item.title || '未命名内�?,
            cover: item.coverUrl || item.imageUrl || '/resources/images/default_cover.jpg',
            type: item.type || 'video',
            siteKey: item.siteKey
          }));
          Logger.info(`${this.TAG}: Successfully loaded ${this.featuredMedia.length} items from MediaService`);
        } else {
          // 如果所有数据来源都失败，使用空数组
          this.featuredMedia = [];
          Logger.warn(`${this.TAG}: No fallback content available`);
        }
      } catch (fallbackError) {
        Logger.error(this.TAG, 'Failed to load fallback data', fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError : new Error(String(fallbackError instanceof Error ? fallbackError : new Error(String(fallbackError)))))))));
        this.featuredMedia = [];
      }
    } finally {
      this.isLoading = false;
    }
  }
  
  // 跳转到分类页�?
  private navigateToCategory() {
    AppNavigator.getInstance().navigateToCategory({ id: "", name: "", type: "" });
  }
  
  // 跳转到搜索页�?
  private navigateToSearch() {
    AppNavigator.getInstance().navigateToSearch("");
  }
  
  // 跳转到设置页�?
  private navigateToSettings() {
    AppNavigator.getInstance().navigateToSettings();
  }
  
  // 渲染媒体�?
  @Builder
  renderMediaItem(media: FeaturedMediaItem) {
    ListItem() {
      Column({ padding: 10 }) {
        Image(media.cover)
          .width(150)
          .height(200)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
        Text(media.title)
          .fontSize(14)
          .maxLines(2)
          .marginTop(8)
      }
    }
    .onClick(() => AppNavigator.getInstance().navigateToDetail({ id: media.id, siteKey: media.siteKey || '', type: 'vod' }))
  }
  
  build() {
    Flex({
      direction: FlexDirection.Column,
      padding: 20
    }) {
      // 标题�?
      Row({
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center,
        marginBottom: 20
      }) {
        Text("RayTV")
          .fontSize(24)
          .fontWeight(700)
        Row() {
          Button("搜索")
            .onClick(() => this.navigateToSearch())
            .marginRight(10)
          Button("设置")
            .onClick(() => this.navigateToSettings())
        }
      }
      
      // 分类入口
      Button("浏览分类")
        .onClick(() => this.navigateToCategory())
        .backgroundColor("#007AFF")
        .fontColor("white")
        .width("100%")
        .padding(12)
        .fontSize(16)
        .marginBottom(20)
      
      // 推荐内容
      Text("推荐内容")
        .fontSize(20)
        .fontWeight(700)
        .marginBottom(15)
      
      if (this.isLoading) {
        Text("加载�?..")
      } else {
        List() {
          ForEach(this.featuredMedia, (item: FeaturedMediaItem) => {
            this.renderMediaItem(item)
          }, (item: FeaturedMediaItem) => item.id)
        }
        .scroller(this.scroller)
        .orientation("horizontal")
        .height(250)
      }
      
      // 底部提示
      Text("请确保已配置视频源以获得最佳体�?)
        .fontSize(12)
        .fontColor("#888888")
        .marginTop(20)
        .textAlign(TextAlign.Center)
    }
  }
}


