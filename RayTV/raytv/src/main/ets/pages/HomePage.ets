// HomePage组件 - Home page component
import { AppNavigator, PageRoute } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { MediaService } from '../service/media/MediaService';
import { MediaItem } from '../data/bean/MediaItem';

import ApiResponse from '../data/dto/ApiResponse';
import { Column, Row, Text, Button, Image, Scroll, ForEach, FlexAlign, TextAlign, VerticalAlign, BarState, ImageFit } from '@ohos/arkui';
import VirtualList from '../components/VirtualList';
import { VirtualListItem } from '../types/VirtualListTypes';
import { SkeletonScreen } from '../components/SkeletonScreen';

// 媒体推荐结果项类型 | Media recommended result item type
interface RecommendedMediaItem {
  id: string;
  title: string;
  cover?: string;
  siteKey: string;
  rating?: string;
}

// 响应数据接口 | Response data interface
interface SuccessResponse<T> {
  isSuccess: () => boolean;
  data: T[];
}

// 简化条件判断的辅助方法 | Helper method to simplify condition checking
function isSuccessResponse<T>(response: ApiResponse<T[]>): boolean {
  return typeof response === 'object' && 
         response !== null && 
         typeof response.isSuccess === 'function' && 
         response.isSuccess() && 
         response.data !== undefined && 
         Array.isArray(response.data);
}

/**
 * 首页组件 | Home page component
 * 展示推荐媒体内容和功能入口 | Display recommended media content and feature entries
 */
@Component
struct HomePage {
  private readonly TAG: string = 'HomePage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State isLoading: boolean = false;
  @State recommendedMedia: MediaItem[] = [];
  @State popularMedia: MediaItem[] = [];
  @State newMedia: MediaItem[] = [];
  @State errorMessage: string = '';
  
  // 服务实例 | Service instances
  private mediaService: MediaService = MediaService.getInstance();

  
  // 初始化页面 | Initialize page
  async aboutToAppear(): Promise<void> {
    Logger.info(this.TAG, 'HomePage mounted');

    await this.loadHomePageData();
  }

  // 清理资源 | Clean up resources
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'HomePage unmounted');
  }
  
  /**
   * 加载首页数据 | Load home page data
   */
  private async loadHomePageData(): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';

      Logger.info(this.TAG, 'Loading home page data');

      // 并行加载所有内容 | Load all content in parallel
      const [recommendedResult, popularResult, newResult] = await Promise.all([
        this.mediaService.getPersonalizedRecommendations(),
        this.mediaService.getPopularContent(),
        this.mediaService.getNewContent()
      ]);

      // 处理推荐内容 | Handle recommended content
      if (isSuccessResponse<RecommendedMediaItem>(recommendedResult)) {
        // 确保data不是undefined | Ensure data is not undefined
        const data = recommendedResult.data as RecommendedMediaItem[];
        this.recommendedMedia = data.map((item: RecommendedMediaItem) => {
          const mediaItem: MediaItem = {
            id: item.id,
            title: item.title,
            coverUrl: item.cover || '',
            siteKey: item.siteKey,
            score: item.rating || ''
          };
          return mediaItem;
        });
      }

      // 处理热门内容 | Handle popular content
      if (isSuccessResponse<RecommendedMediaItem>(popularResult)) {
        // 确保data不是undefined | Ensure data is not undefined
        const data = popularResult.data as RecommendedMediaItem[];
        this.popularMedia = data.map((item: RecommendedMediaItem) => {
          const mediaItem: MediaItem = {
            id: item.id,
            title: item.title,
            coverUrl: item.cover || '',
            siteKey: item.siteKey,
            score: item.rating || ''
          };
          return mediaItem;
        });
      }

      // 处理最新上线内容 | Handle new content
      if (isSuccessResponse<RecommendedMediaItem>(newResult)) {
        // 确保data不是undefined | Ensure data is not undefined
        const data = newResult.data as RecommendedMediaItem[];
        this.newMedia = data.map((item: RecommendedMediaItem) => {
          const mediaItem: MediaItem = {
            id: item.id,
            title: item.title,
            coverUrl: item.cover || '',
            siteKey: item.siteKey,
            score: item.rating || ''
          };
          return mediaItem;
        });
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
   * 处理搜索 | Handle search
   */
  private handleSearch(): void {
    try {
      Logger.info(this.TAG, 'Search button clicked');

      // 跳转到搜索页面 | Navigate to search page
      AppNavigator.getInstance().navigateToSearch('');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to navigate to search page: ${err.message}`);
    }
  }
  
  /**
   * 处理媒体项点击 | Handle media item click
   */
  private handleMediaItemClick(media: MediaItem): void {
    try {
      Logger.info(this.TAG, `Media item clicked: ${media.title}`);

      // 验证媒体数据完整性 | Validate media data integrity
      if (!media.id || !media.siteKey) {
        Logger.error(this.TAG, 'Invalid media data: missing required fields');
        return;
      }

      // 记录用户行为 | Record user behavior
      this.mediaService.recordUserBehavior({
        mediaId: media.id,
        type: 'click',
        timestamp: Date.now()
      });

      // 跳转到详情页 | Navigate to detail page
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
   * 将MediaItem转换为VirtualListItem | Convert MediaItem to VirtualListItem
   */
  private convertToVirtualItems(mediaList: MediaItem[]): VirtualListItem[] {
    const virtualItems: VirtualListItem[] = [];
    for (let i = 0; i < mediaList.length; i++) {
      const media = mediaList[i];
      const virtualItem: VirtualListItem = {
        id: media.id,
        index: i,
        data: media,
        top: i * 320, // 估算的项目高度
        height: 320,
        visible: false
      };
      virtualItems.push(virtualItem);
    }
    return virtualItems;
  }
  }
  
  /**
   * 渲染媒体项 | Render media item
   */
  @Builder
  private renderMediaItem(media: MediaItem) {
    Column() {
      Image(media.coverUrl || 'https://via.placeholder.com/200x300?text=No+Image')
        .width(180)
        .height(270)
        .objectFit(ImageFit.Cover)
        .borderRadius(12)
        .backgroundColor('#F5F5F5')
        .margin({ bottom: 12 })
      
      Text(media.title)
        .fontSize(16)
        .fontWeight(600)
        .fontColor('#333333')
        .maxLines(2)
        .width(180)
        .textAlign(TextAlign.Center)
      
      if (media.score) {
        Text(`评分: ${media.score}`)
          .fontSize(14)
          .fontColor('#FF6B35')
          .margin({ top: 4 })
      }
    }
    .width(180)
    .padding(10)
    .onClick(() => this.handleMediaItemClick(media))
  }
  
  /**
   * 渲染媒体列表 | Render media list
   */
  @Builder
  private renderMediaSection(title: string, mediaList: MediaItem[]) {
    Column() {
      Row() {
        Text(title)
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#333333')
          .margin({ left: 30 })
        
        Button('查看更多')
          .fontSize(14)
          .fontColor('#4CAF50')
          .backgroundColor('transparent')
          .margin({ right: 30 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 20 })
      
      // 使用虚拟列表提高性能 | Use virtual list for better performance
      Column() {
        Scroll(this.scroller) {
          Row() {
            ForEach(mediaList, (media: MediaItem) => {
              this.renderMediaItem(media)
            }, (media: MediaItem) => media.id)
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .height(320)
        .margin({ bottom: 30 })
      }
    }
    .width('100%')
  }
  
  /**
   * 渲染媒体列表（虚拟列表版本）| Render media list (virtual list version)
   */
  @Builder
  private renderMediaSectionWithVirtualList(title: string, mediaList: MediaItem[]) {
    Column() {
      Row() {
        Text(title)
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#333333')
          .margin({ left: 30 })
        
        Button('查看更多')
          .fontSize(14)
          .fontColor('#4CAF50')
          .backgroundColor('transparent')
          .margin({ right: 30 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 20 })
      
      // 使用虚拟列表提高性能 | Use virtual list for better performance
      const virtualItems = this.convertToVirtualItems(mediaList);
      
      VirtualList({
        items: virtualItems,
        estimatedItemHeight: 320,
        bufferSize: 3,
        renderItem: (item: VirtualListItem) => {
          const media = item.data as MediaItem;
          return this.renderMediaItem(media);
        }
      })
      .height(320)
      .margin({ bottom: 30 })
    }
    .width('100%')
  }
  
  /**
   * 渲染加载状态 | Render loading state
   */
  @Builder
  private renderLoading() {
    Column() {
      SkeletonScreen({
        type: 'card',
        count: 10,
        animated: true,
        animationDuration: 1500
      })
    }
    .justifyContent(FlexAlign.Center)
    .height('80%')
  }
  
  /**
   * 渲染错误状态 | Render error state
   */
  @Builder
  private renderError() {
    Column() {
      Text('😔')
        .fontSize(48)
        .margin({ bottom: 20 })
      Text(this.errorMessage)
        .fontSize(18)
        .fontColor('#333333')
        .margin({ bottom: 30 })
      Button('重试')
        .onClick(() => this.loadHomePageData())
        .backgroundColor('#4CAF50')
        .fontColor('white')
        .borderRadius(8)
        .padding({ left: 30, right: 30, top: 12, bottom: 12 })
    }
    .justifyContent(FlexAlign.Center)
    .height('80%')
  }
  
  /**
   * 组件渲染 | Component render
   */
  build() {
    Column() {
      // 顶部栏 | Top bar
      Row() {
        Text('RayTV首页')
          .fontSize(24)
          .fontWeight(700)
          .fontColor('#333333')
          .flexGrow(1)
          .margin({ left: 30 })
        
        Button('搜索')
          .onClick(() => this.handleSearch())
          .width(100)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .margin({ right: 30 })
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      
      // 内容区域 | Content area
      if (this.isLoading) {
        this.renderLoading()
      } else if (this.errorMessage) {
        this.renderError()
      } else {
        Scroll(this.scroller) {
          Column() {
            // 推荐内容 | Recommended content
            if (this.recommendedMedia.length > 0) {
              this.renderMediaSectionWithVirtualList('推荐内容', this.recommendedMedia)
            }
            
            // 热门内容 | Popular content
            if (this.popularMedia.length > 0) {
              this.renderMediaSectionWithVirtualList('热门内容', this.popularMedia)
            }
            
            // 最新上线 | New releases
            if (this.newMedia.length > 0) {
              this.renderMediaSectionWithVirtualList('最新上线', this.newMedia)
            }
            
            // 空状态 | Empty state
            if (this.recommendedMedia.length === 0 && this.popularMedia.length === 0 && this.newMedia.length === 0) {
              Column() {
                Text('暂无内容')
                  .fontSize(18)
                  .fontColor('#666666')
                  .margin(40)
              }
              .justifyContent(FlexAlign.Center)
              .height(400)
            }
          }
          .width('100%')
          .padding({ top: 20, bottom: 40 })
        }
        .scrollBar(BarState.Auto)
        .flexGrow(1)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}

export default HomePage;
